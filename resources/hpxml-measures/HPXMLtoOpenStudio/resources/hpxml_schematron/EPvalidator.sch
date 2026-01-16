<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch='http://purl.oclc.org/dsdl/schematron'>
  <sch:title>HPXML Schematron Validator: EnergyPlus Simulation</sch:title>
  <sch:ns uri='http://hpxmlonline.com/2025/12' prefix='h'/>

  <sch:pattern>
    <sch:title>[Root]</sch:title>
    <sch:rule context='/h:HPXML'>
      <sch:assert role='ERROR' test='count(h:SoftwareInfo) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SoftwareInfo</sch:assert> <!-- See [SoftwareInfo] -->
      <sch:assert role='ERROR' test='count(h:Building) &gt;= 1'>Expected 1 or more element(s) for xpath: Building</sch:assert> <!-- See [Building] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SoftwareInfo]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo'>
      <sch:assert role='ERROR' test='count(h:extension/h:SimulationControl) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/SimulationControl</sch:assert> <!-- See [SimulationControl] -->
      <sch:assert role='ERROR' test='count(h:extension/h:EmissionsScenarios/h:EmissionsScenario) &gt;= 0'>Expected 0 or more element(s) for xpath: extension/EmissionsScenarios/EmissionsScenario</sch:assert> <!-- See [EmissionsScenario] -->
      <sch:assert role='ERROR' test='count(h:extension/h:UtilityBillScenarios/h:UtilityBillScenario) &gt;= 0'>Expected 0 or more element(s) for xpath: extension/UtilityBillScenarios/UtilityBillScenario</sch:assert> <!-- See [UtilityBillScenario] -->
      <sch:assert role='ERROR' test='count(h:extension/h:UnavailablePeriods/h:UnavailablePeriod) &gt;= 0'>Expected 0 or more element(s) for xpath: extension/UnavailablePeriods/UnavailablePeriod</sch:assert> <!-- See [UnavailablePeriod] -->
      <sch:assert role='ERROR' test='count(h:extension/h:ElectricPanelLoadCalculations) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ElectricPanelLoadCalculations</sch:assert> <!-- See [ElectricPanelLoadCalculations] -->
      <sch:assert role='ERROR' test='count(h:extension/h:WholeSFAorMFBuildingSimulation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WholeSFAorMFBuildingSimulation</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:WholeSFAorMFBuildingSimulation[text()="true" or text()="false"] or not(h:extension/h:WholeSFAorMFBuildingSimulation)'>Expected extension/WholeSFAorMFBuildingSimulation to be 'true' or 'false'</sch:assert>
      <!-- Moved multiple inputs to allow variation across MF dwelling units; see https://github.com/NREL/OpenStudio-HPXML/pull/1478 -->
      <sch:assert role='ERROR' test='count(h:extension/h:SchedulesFilePath) = 0'>extension/SchedulesFilePath has been replaced by /HPXML/Building/BuildingDetails/BuildingSummary/extension/SchedulesFilePath</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HVACSizingControl) = 0'>extension/HVACSizingControl has been replaced by /HPXML/Building/BuildingDetails/BuildingSummary/extension/HVACSizingControl</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ShadingControl) = 0'>extension/ShadingControl has been replaced by /HPXML/Building/BuildingDetails/BuildingSummary/extension/ShadingControl</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:NaturalVentilationAvailabilityDaysperWeek) = 0'>extension/NaturalVentilationAvailabilityDaysperWeek has been replaced by /HPXML/Building/BuildingDetails/BuildingSummary/extension/NaturalVentilationAvailabilityDaysperWeek</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SimulationControl]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:SimulationControl'>
      <sch:assert role='ERROR' test='count(h:Timestep) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Timestep</sch:assert>
      <sch:assert role='ERROR' test='60 mod number(h:Timestep) = 0 or not(h:Timestep)'>Expected Timestep to be 60, 30, 20, 15, 12, 10, 6, 5, 4, 3, 2, or 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:BeginMonth) + count(h:BeginDayOfMonth) = 0 or count(h:BeginMonth) + count(h:BeginDayOfMonth) = 2'>Expected 0 or 2 element(s) for xpath: BeginMonth | BeginDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndMonth) + count(h:EndDayOfMonth) = 0 or count(h:EndMonth) + count(h:EndDayOfMonth) = 2'>Expected 0 or 2 element(s) for xpath: EndMonth | EndDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:CalendarYear) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CalendarYear</sch:assert>
      <sch:assert role='ERROR' test='number(h:CalendarYear) &gt;= 1600 or not(h:CalendarYear)'>Expected CalendarYear to be greater than or equal to 1600</sch:assert>
      <sch:assert role='ERROR' test='number(h:CalendarYear) &lt;= 9999 or not(h:CalendarYear)'>Expected CalendarYear to be less than or equal to 9999</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdvancedResearchFeatures) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AdvancedResearchFeatures</sch:assert> <!-- See [AdvancedResearchFeatures] -->
      <!-- Moved/deprecated DaylightSaving input; see https://github.com/NREL/OpenStudio-HPXML/pull/1165 -->
      <sch:assert role='ERROR' test='count(h:DaylightSaving/h:Enabled) = 0'>DaylightSaving/Enabled has been replaced by /HPXML/Building/Site/TimeZone/DSTObserved</sch:assert>
      <sch:assert role='ERROR' test='count(h:DaylightSaving/h:BeginMonth) = 0'>DaylightSaving/BeginMonth has been replaced by /HPXML/Building/Site/TimeZone/extension/DSTBeginMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:DaylightSaving/h:BeginDayOfMonth) = 0'>DaylightSaving/BeginDayOfMonth has been replaced by /HPXML/Building/Site/TimeZone/extension/DSTBeginDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:DaylightSaving/h:EndMonth) = 0'>DaylightSaving/EndMonth has been replaced by /HPXML/Building/Site/TimeZone/extension/DSTEndMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:DaylightSaving/h:EndDayOfMonth) = 0'>DaylightSaving/EndDayOfMonth has been replaced by /HPXML/Building/Site/TimeZone/extension/DSTEndDayOfMonth</sch:assert>
      <!-- Moved/deprecated TemperatureCapacitanceMultiplier input; see https://github.com/NREL/OpenStudio-HPXML/pull/1674 -->
      <sch:assert role='ERROR' test='count(h:TemperatureCapacitanceMultiplier) = 0'>TemperatureCapacitanceMultiplier has been replaced by AdvancedResearchFeatures/TemperatureCapacitanceMultiplier</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdvancedResearchFeatures]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:SimulationControl/h:AdvancedResearchFeatures'>
      <sch:assert role='ERROR' test='count(h:TemperatureCapacitanceMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: TemperatureCapacitanceMultiplier</sch:assert>
      <!-- Deprecated DefrostModelType input; see https://github.com/NREL/OpenStudio-HPXML/pull/2015 -->
      <sch:assert role='ERROR' test='count(h:DefrostModelType) = 0'>DefrostModelType has been deprecated</sch:assert>
      <sch:assert role='ERROR' test='count(h:OnOffThermostatDeadbandTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: OnOffThermostatDeadbandTemperature</sch:assert> <!-- See [OnOffThermostatDeadbandTemperature] -->
      <sch:assert role='ERROR' test='number(h:OnOffThermostatDeadbandTemperature) &gt; 0 or not(h:OnOffThermostatDeadbandTemperature)'>Expected OnOffThermostatDeadbandTemperature to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatPumpBackupCapacityIncrement) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatPumpBackupCapacityIncrement</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatPumpBackupCapacityIncrement) &gt; 0 or not (h:HeatPumpBackupCapacityIncrement)'>HeatPumpBackupCapacityIncrement should be greater than 0.0</sch:assert>
      <sch:assert role='ERROR' test='count(h:GroundToAirHeatPumpModelType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: GroundToAirHeatPumpModelType</sch:assert>
      <sch:assert role='ERROR' test='h:GroundToAirHeatPumpModelType[text()="standard" or text()="experimental"] or not(h:GroundToAirHeatPumpModelType)'>Expected GroundToAirHeatPumpModelType to be 'standard' or 'experimental'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[OnOffThermostatDeadbandTemperature]</sch:title>
    <sch:rule context='/h:HPXML[h:SoftwareInfo/h:extension/h:SimulationControl/h:AdvancedResearchFeatures/h:OnOffThermostatDeadbandTemperature]/h:Building/h:BuildingDetails'>
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:FractionCoolLoadServed > 0]) + count(h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:FractionCoolLoadServed > 0]) &lt;= 1'>Expected at maximum one cooling system for each Building</sch:assert>
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:FractionHeatLoadServed > 0]) + count(h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:FractionHeatLoadServed > 0]) &lt;= 1'>Expected at maximum one heating system for each Building</sch:assert>
      <sch:assert role='ERROR' test='sum(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionHeatLoadServed) &gt;= 0.99 or count(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionHeatLoadServed) = 0'>Expected sum(FractionHeatLoadServed) to be equal to 1</sch:assert>
      <sch:assert role='ERROR' test='sum(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionCoolLoadServed) &gt;= 0.99 or count(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionCoolLoadServed) = 0'>Expected sum(FractionCoolLoadServed) to be equal to 1</sch:assert>
      <sch:assert role='ERROR' test='number(/h:HPXML/h:SoftwareInfo/h:extension/h:SimulationControl/h:Timestep) = 1'>Expected /HPXML/SoftwareInfo/extension/SimulationControl/Timestep to be 1.0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(/h:HPXML/h:SoftwareInfo/h:extension/h:SimulationControl/h:AdvancedResearchFeatures/h:TemperatureCapacitanceMultiplier) &lt;= 1'>TemperatureCapacitanceMultiplier should typically be greater than 1.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpBackupCapacityIncrement]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:SimulationControl[h:AdvancedResearchFeatures/h:HeatPumpBackupCapacityIncrement]'>
      <sch:assert role='ERROR' test='number(h:Timestep) = 1'>Expected Timestep to be 1.0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[EmissionsScenario]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EmissionsScenarios/h:EmissionsScenario'>
      <sch:assert role='ERROR' test='count(h:Name) = 1'>Expected 1 element(s) for xpath: Name</sch:assert>
      <sch:assert role='ERROR' test='count(h:EmissionsType) = 1'>Expected 1 element(s) for xpath: EmissionsType</sch:assert>
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="electricity"]) = 1'>Expected 1 element(s) for xpath: EmissionsFactor[FuelType="electricity"]</sch:assert> <!-- See [EmissionsFactor=Electricity] -->
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="natural gas"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: EmissionsFactor[FuelType="natural gas"]</sch:assert> <!-- See [EmissionsFactor=Fuel] -->
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="propane"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: EmissionsFactor[FuelType="propane"]</sch:assert> <!-- See [EmissionsFactor=Fuel] -->
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="fuel oil"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: EmissionsFactor[FuelType="fuel oil"]</sch:assert> <!-- See [EmissionsFactor=Fuel] -->
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="coal"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: EmissionsFactor[FuelType="coal"]</sch:assert> <!-- See [EmissionsFactor=Fuel] -->
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="wood"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: EmissionsFactor[FuelType="wood"]</sch:assert> <!-- See [EmissionsFactor=Fuel] -->
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="wood pellets"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: EmissionsFactor[FuelType="wood pellets"]</sch:assert> <!-- See [EmissionsFactor=Fuel] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[EmissionsFactor=Electricity]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EmissionsScenarios/h:EmissionsScenario/h:EmissionsFactor[h:FuelType="electricity"]'>
      <sch:assert role='ERROR' test='count(h:Units[text()="lb/MWh" or text()="kg/MWh"]) = 1'>Expected 1 element(s) for xpath: Units[text()="lb/MWh" or text()="kg/MWh"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:ScheduleFilePath) + count(h:Value) = 1'>Expected 1 element(s) for xpath: ScheduleFilePath | Value</sch:assert> <!-- See [EmissionsFactor=ElectricitySchedule] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[EmissionsFactor=ElectricitySchedule]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EmissionsScenarios/h:EmissionsScenario/h:EmissionsFactor[h:FuelType="electricity" and h:ScheduleFilePath]'>
      <sch:assert role='ERROR' test='count(h:NumberofHeaderRows) &lt;= 1'>Expected 0 or 1 element(s) for xpath: NumberofHeaderRows</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofHeaderRows) &gt;= 0 or not(h:NumberofHeaderRows)'>Expected NumberofHeaderRows to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:ColumnNumber) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ColumnNumber</sch:assert>
      <sch:assert role='ERROR' test='number(h:ColumnNumber) &gt;= 1 or not(h:ColumnNumber)'>Expected ColumnNumber to be greater than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[EmissionsFactor=Fuel]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EmissionsScenarios/h:EmissionsScenario/h:EmissionsFactor[h:FuelType!="electricity"]'>
      <sch:assert role='ERROR' test='count(h:Units[text()="lb/MBtu" or text()="kg/MBtu"]) = 1'>Expected 1 element(s) for xpath: Units[text()="lb/MBtu" or text()="kg/MBtu"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Value) = 1'>Expected 1 element(s) for xpath: Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[UtilityBillScenario]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario'>
      <sch:assert role='ERROR' test='count(h:Name) = 1'>Expected 1 element(s) for xpath: Name</sch:assert>
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="electricity"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UtilityRate[FuelType="electricity"]</sch:assert> <!-- See [UtilityRate=Electricity] -->
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="natural gas"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UtilityRate[FuelType="natural gas"]</sch:assert> <!-- See [UtilityRate=OtherFuel] -->
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="propane"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UtilityRate[FuelType="propane"]</sch:assert> <!-- See [UtilityRate=OtherFuel] -->
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="fuel oil"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UtilityRate[FuelType="fuel oil"]</sch:assert> <!-- See [UtilityRate=OtherFuel] -->
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="coal"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UtilityRate[FuelType="coal"]</sch:assert> <!-- See [UtilityRate=OtherFuel] -->
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="wood"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UtilityRate[FuelType="wood"]</sch:assert> <!-- See [UtilityRate=OtherFuel] -->
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="wood pellets"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UtilityRate[FuelType="wood pellets"]</sch:assert> <!-- See [UtilityRate=OtherFuel] -->
      <sch:assert role='ERROR' test='count(h:PVCompensation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PVCompensation</sch:assert> <!-- See [PVCompensation] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[UtilityRate=Electricity]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario/h:UtilityRate[h:FuelType="electricity"]'>
      <sch:assert role='ERROR' test='count(h:FixedCharge) + count(h:TariffFilePath) &lt;= 1'>Expected 0 or 1 element(s) for xpath: FixedCharge | TariffFilePath</sch:assert>
      <sch:assert role='ERROR' test='count(h:MarginalRate) + count(h:TariffFilePath) &lt;= 1'>Expected 0 or 1 element(s) for xpath: MarginalRate | TariffFilePath</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[UtilityRate=Fuel]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario/h:UtilityRate[h:FuelType!="electricity"]'>
      <sch:assert role='ERROR' test='count(h:FixedCharge) &lt;= 1'>Expected 0 or 1 element(s) for xpath: FixedCharge</sch:assert>
      <sch:assert role='ERROR' test='count(h:MarginalRate) &lt;= 1'>Expected 0 or 1 element(s) for xpath: MarginalRate</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVCompensation]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario/h:PVCompensation'>
      <sch:assert role='ERROR' test='count(h:CompensationType[h:NetMetering | h:FeedInTariff]) = 1'>Expected 1 element(s) for xpath: CompensationType[NetMetering | FeedInTariff]</sch:assert> <!-- See [PVCompensationType=NetMetering] or [PVCompensationType=FeedInTariff] -->
      <sch:assert role='ERROR' test='count(h:MonthlyGridConnectionFee[h:Units="$/kW" or h:Units="$"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: MonthlyGridConnectionFee[Units="$/kW" or Units="$"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVCompensationType=NetMetering]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario/h:PVCompensation/h:CompensationType/h:NetMetering'>
      <sch:assert role='ERROR' test='count(h:AnnualExcessSellbackRateType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AnnualExcessSellbackRateType</sch:assert> <!-- See [PVCompensationType=NetMeteringWithUserExcessSellbackRate] -->
      <sch:assert role='ERROR' test='h:AnnualExcessSellbackRateType[text()="User-Specified" or text()="Retail Electricity Cost"] or not(h:AnnualExcessSellbackRateType)'>Expected AnnualExcessSellbackRateType to be 'User-Specified' or 'Retail Electricity Cost'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVCompensationType=NetMeteringWithUserExcessSellbackRate]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario/h:PVCompensation/h:CompensationType/h:NetMetering[h:AnnualExcessSellbackRateType="User-Specified"]'>
      <sch:assert role='ERROR' test='count(h:AnnualExcessSellbackRate) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AnnualExcessSellbackRate</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVCompensationType=FeedInTariff]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario/h:PVCompensation/h:CompensationType/h:FeedInTariff'>
      <sch:assert role='ERROR' test='count(h:FeedInTariffRate) &lt;= 1'>Expected 0 or 1 element(s) for xpath: FeedInTariffRate</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[UnavailablePeriod]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UnavailablePeriods/h:UnavailablePeriod'>
      <sch:assert role='ERROR' test='count(h:ColumnName) = 1'>Expected 1 element(s) for xpath: ColumnName</sch:assert>
      <sch:assert role='ERROR' test='count(h:BeginMonth) = 1'>Expected 1 element(s) for xpath: BeginMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:BeginDayOfMonth) = 1'>Expected 1 element(s) for xpath: BeginDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:BeginHourOfDay) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BeginHourOfDay</sch:assert>
      <sch:assert role='ERROR' test='number(h:BeginHourOfDay) &gt;= 0 or not(h:BeginHourOfDay)'>Expected BeginHourOfDay to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:BeginHourOfDay) &lt;= 23 or not(h:BeginHourOfDay)'>Expected BeginHourOfDay to be less than or equal to 23</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndMonth) = 1'>Expected 1 element(s) for xpath: EndMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndDayOfMonth) = 1'>Expected 1 element(s) for xpath: EndDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndHourOfDay) &lt;= 1'>Expected 0 or 1 element(s) for xpath: EndHourOfDay</sch:assert>
      <sch:assert role='ERROR' test='number(h:EndHourOfDay) &gt;= 1 or not(h:EndHourOfDay)'>Expected EndHourOfDay to be greater than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:EndHourOfDay) &lt;= 24 or not(h:EndHourOfDay)'>Expected EndHourOfDay to be less than or equal to 24</sch:assert>
      <sch:assert role='ERROR' test='count(h:NaturalVentilation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: NaturalVentilation</sch:assert>
      <sch:assert role='ERROR' test='h:NaturalVentilation[text()="regular schedule" or text()="always available" or text()="always unavailable"] or not(h:NaturalVentilation)'>Expected NaturalVentilation to be 'regular schedule' or 'always available' or 'always unavailable'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ElectricPanelLoadCalculations]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:ElectricPanelLoadCalculations'>
      <sch:assert role='ERROR' test='count(h:ServiceFeeders/h:Type) &gt;= 1'>Expected 1 or more element(s) for xpath: ServiceFeeders/Type</sch:assert>
      <sch:assert role='ERROR' test='h:ServiceFeeders/h:Type[text()="2023 Existing Dwelling Load-Based" or text()="2023 Existing Dwelling Meter-Based"]'>Expected ServiceFeeders/Type to be '2023 Existing Dwelling Load-Based' or '2023 Existing Dwelling Meter-Based'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Building]</sch:title>
    <sch:rule context='/h:HPXML/h:Building'>
      <sch:assert role='ERROR' test='count(h:Site) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Site</sch:assert> <!-- See [BuildingSite] -->
      <sch:assert role='ERROR' test='count(h:BuildingDetails) = 1'>Expected 1 element(s) for xpath: BuildingDetails</sch:assert> <!-- See [BuildingDetails] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingSite]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:Site'>
      <sch:assert role='ERROR' test='count(h:Address/h:CityMunicipality) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Address/CityMunicipality</sch:assert>
      <sch:assert role='ERROR' test='count(h:Address/h:StateCode) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Address/StateCode</sch:assert>
      <sch:assert role='ERROR' test='count(h:Address/h:ZipCode) + count(../h:BuildingDetails/h:ClimateandRiskZones/h:WeatherStation/h:extension/h:EPWFilePath) &gt;= 1'>Expected 1 or more element(s) for xpath: Address/ZipCode | ../BuildingDetails/ClimateandRiskZones/WeatherStation/extension/EPWFilePath</sch:assert>
      <sch:assert role='ERROR' test='count(h:GeoLocation/h:Latitude) &lt;= 1'>Expected 0 or 1 element(s) for xpath: GeoLocation/Latitude</sch:assert>
      <sch:assert role='ERROR' test='count(h:GeoLocation/h:Longitude) &lt;= 1'>Expected 0 or 1 element(s) for xpath: GeoLocation/Longitude</sch:assert>
      <sch:assert role='ERROR' test='count(h:Elevation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Elevation</sch:assert>
      <sch:assert role='ERROR' test='count(h:TimeZone/h:UTCOffset) &lt;= 1'>Expected 0 or 1 element(s) for xpath: TimeZone/UTCOffset</sch:assert>
      <sch:assert role='ERROR' test='count(h:TimeZone/h:DSTObserved) &lt;= 1'>Expected 0 or 1 element(s) for xpath: TimeZone/DSTObserved</sch:assert> <!-- See [DaylightSaving] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DaylightSaving]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:Site/h:TimeZone[h:DSTObserved="true"]'>
      <sch:assert role='ERROR' test='count(h:extension/h:DSTBeginMonth) + count(h:extension/h:DSTBeginDayOfMonth) + count(h:extension/h:DSTEndMonth) + count(h:extension/h:DSTEndDayOfMonth) = 0 or count(h:extension/h:DSTBeginMonth) + count(h:extension/h:DSTBeginDayOfMonth) + count(h:extension/h:DSTEndMonth) + count(h:extension/h:DSTEndDayOfMonth) = 4'>Expected 0 or 4 element(s) for xpath: extension/DSTBeginMonth | extension/DSTBeginDayOfMonth | extension/DSTEndMonth | extension/DSTEndDayOfMonth</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingDetails]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails'>
      <sch:assert role='ERROR' test='count(h:BuildingSummary/h:Site) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BuildingSummary/Site</sch:assert> <!-- See [Site] -->
      <sch:assert role='ERROR' test='count(h:BuildingSummary/h:BuildingOccupancy) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BuildingSummary/BuildingOccupancy</sch:assert> <!-- See [BuildingOccupancy]-->
      <sch:assert role='ERROR' test='count(h:BuildingSummary/h:BuildingConstruction) = 1'>Expected 1 element(s) for xpath: BuildingSummary/BuildingConstruction</sch:assert> <!-- See [BuildingConstruction] -->
      <sch:assert role='ERROR' test='count(h:ClimateandRiskZones/h:ClimateZoneIECC) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ClimateandRiskZones/ClimateZoneIECC</sch:assert> <!-- See [ClimateZoneIECC] -->
      <sch:assert role='ERROR' test='count(h:Zones) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Zones</sch:assert> <!-- See [Zones] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Attics/h:Attic) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Attics/Attic</sch:assert> <!-- See [VentedAttic] or [UnventedAttic] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Foundations/h:Foundation) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Foundations/Foundation</sch:assert> <!-- See [VentedCrawl] or [UnventedCrawl] or [UncondBasement] or [CondBasement] or [ManufacturedHomeBelly] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:AirInfiltration/h:extension/h:HasFlueOrChimneyInConditionedSpace) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Enclosure/AirInfiltration/extension/HasFlueOrChimneyInConditionedSpace</sch:assert>
      <sch:assert role='ERROR' test='count(h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:BuildingAirLeakage/h:AirLeakage | h:EffectiveLeakageArea | h:SpecificLeakageArea | h:LeakinessDescription]) = 1'>Expected 1 element(s) for xpath: Enclosure/AirInfiltration/AirInfiltrationMeasurement[BuildingAirLeakage/AirLeakage | EffectiveLeakageArea | SpecificLeakageArea | LeakinessDescription]</sch:assert> <!-- See [AirInfiltrationMeasurement] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Roofs/h:Roof) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Roofs/Roof</sch:assert> <!-- See [Roof] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:RimJoists/h:RimJoist) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/RimJoists/RimJoist</sch:assert> <!-- See [RimJoist] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Walls/h:Wall) + count(h:Enclosure/h:FoundationWalls/h:FoundationWall) &gt;= 1'>Expected 1 or more element(s) for xpath: Enclosure/Walls/Wall | Enclosure/FoundationWalls/FoundationWall</sch:assert> <!-- See [Wall] or [FoundationWall] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Floors/h:Floor) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Floors/Floor</sch:assert> <!-- See [Floor] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Slabs/h:Slab) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Slabs/Slab</sch:assert> <!-- See [Slab] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Windows/h:Window) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Windows/Window</sch:assert> <!-- See [Window] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Skylights/h:Skylight) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Skylights/Skylight</sch:assert> <!-- See [Skylight] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Doors/h:Door) &gt;= 0'>Expected 0 or more element(s) for xpath: Enclosure/Doors/Door</sch:assert> <!-- See [Door] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:extension/h:PartitionWallMass) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Enclosure/extension/PartitionWallMass</sch:assert> <!-- See [PartitionWallMass] -->
      <sch:assert role='ERROR' test='count(h:Enclosure/h:extension/h:FurnitureMass) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Enclosure/extension/FurnitureMass</sch:assert> <!-- See [FurnitureMass] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/HVAC/HVACPlant/HeatingSystem</sch:assert> <!-- See [HeatingSystem] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/HVAC/HVACPlant/CoolingSystem</sch:assert> <!-- See [CoolingSystem] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACPlant/h:HeatPump) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/HVAC/HVACPlant/HeatPump</sch:assert> <!-- See [HeatPump] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACControl) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Systems/HVAC/HVACControl</sch:assert> <!-- See [HVACControl=Heating] and/or [HVACControl=Cooling] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACDistribution) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/HVAC/HVACDistribution</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/MechanicalVentilation/VentilationFans/VentilationFan</sch:assert> <!-- See [VentilationFan] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:WaterHeating/h:WaterHeatingSystem) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/WaterHeating/WaterHeatingSystem</sch:assert> <!-- See [WaterHeatingSystem] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:WaterHeating/h:HotWaterDistribution) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Systems/WaterHeating/HotWaterDistribution</sch:assert> <!-- See [HotWaterDistribution] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:WaterHeating/h:WaterFixture) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/WaterHeating/WaterFixture</sch:assert> <!-- See [WaterFixture] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:SolarThermal/h:SolarThermalSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Systems/SolarThermal/SolarThermalSystem</sch:assert> <!-- See [SolarThermalSystem] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:Photovoltaics/h:PVSystem) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/Photovoltaics/PVSystem</sch:assert> <!-- See [PVSystem] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:ElectricPanels/h:ElectricPanel) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Systems/ElectricPanels/ElectricPanel</sch:assert> <!-- See [ElectricPanel] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:Batteries/h:Battery) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Systems/Batteries/Battery</sch:assert> <!-- See [Battery] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:Vehicles/h:Vehicle) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/Vehicles/Vehicle</sch:assert> <!-- See [Vehicle] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:ElectricVehicleChargers/h:ElectricVehicleCharger) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/ElectricVehicleChargers/ElectricVehicleCharger</sch:assert> <!-- See [ElectricVehicleCharger] -->
      <sch:assert role='ERROR' test='count(h:Systems/h:extension/h:Generators/h:Generator) &gt;= 0'>Expected 0 or more element(s) for xpath: Systems/extension/Generators/Generator</sch:assert> <!-- See [Generator] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:ClothesWasher) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Appliances/ClothesWasher</sch:assert> <!-- See [ClothesWasher] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:ClothesDryer) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Appliances/ClothesDryer</sch:assert> <!-- See [ClothesDryer] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:Dishwasher) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Appliances/Dishwasher</sch:assert> <!-- See [Dishwasher] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:Refrigerator) &gt;= 0'>Expected 0 or more element(s) for xpath: Appliances/Refrigerator</sch:assert> <!-- See [Refrigerator] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:Freezer) &gt;= 0'>Expected 0 or more element(s) for xpath: Appliances/Freezer</sch:assert> <!-- See [Freezer] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:Dehumidifier) &gt;= 0'>Expected 0 or more element(s) for xpath: Appliances/Dehumidifier</sch:assert> <!-- See [Dehumidifier] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:CookingRange) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Appliances/CookingRange</sch:assert> <!-- See [CookingRange] -->
      <sch:assert role='ERROR' test='count(h:Appliances/h:Oven) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Appliances/Oven</sch:assert> <!-- See [Oven] -->
      <sch:assert role='ERROR' test='count(h:Lighting) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Lighting</sch:assert> <!-- See [Lighting] -->
      <sch:assert role='ERROR' test='count(h:Lighting/h:CeilingFan) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Lighting/CeilingFan</sch:assert> <!-- See [CeilingFan] -->
      <sch:assert role='ERROR' test='count(h:Pools/h:Pool) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Pools/Pool</sch:assert> <!-- See [Pool] -->
      <sch:assert role='ERROR' test='count(h:Spas/h:PermanentSpa) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Spas/PermanentSpa</sch:assert> <!-- See [PermanentSpa] -->
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType[text()="other"]]) = 1'>Expected 1 element(s) for xpath: MiscLoads/PlugLoad[PlugLoadType[text()="other"]]</sch:assert> <!-- See [PlugLoad] -->
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType[text()="TV other"]]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: MiscLoads/PlugLoad[PlugLoadType[text()="TV other"]]</sch:assert> <!-- See [PlugLoad] -->
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType[text()="electric vehicle charging"]]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: MiscLoads/PlugLoad[PlugLoadType[text()="electric vehicle charging"]]</sch:assert> <!-- See [PlugLoad] -->
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType[text()="well pump"]]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: MiscLoads/PlugLoad[PlugLoadType[text()="well pump"]]</sch:assert> <!-- See [PlugLoad] -->
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:FuelLoad[h:FuelLoadType[text()="grill"]]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: MiscLoads/FuelLoad[FuelLoadType[text()="grill"]]</sch:assert> <!-- See [FuelLoad] -->
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:FuelLoad[h:FuelLoadType[text()="lighting"]]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: MiscLoads/FuelLoad[FuelLoadType[text()="lighting"]]</sch:assert> <!-- See [FuelLoad] -->
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:FuelLoad[h:FuelLoadType[text()="fireplace"]]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: MiscLoads/FuelLoad[FuelLoadType[text()="fireplace"]]</sch:assert> <!-- See [FuelLoad] -->
      <!-- Count Checks -->
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACPlant/h:HeatPump/h:BackupSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatPump/BackupSystem</sch:assert>
      <!-- Sum Checks -->
      <sch:assert role='ERROR' test='sum(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionHeatLoadServed) &lt;= 1.01'>Expected sum(FractionHeatLoadServed) to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='sum(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionCoolLoadServed) &lt;= 1.01'>Expected sum(FractionCoolLoadServed) to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='sum(h:Appliances/h:Dehumidifier/h:FractionDehumidificationLoadServed) &lt;= 1.01'>Expected sum(FractionDehumidificationLoadServed) to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='(sum(h:Systems/h:WaterHeating/h:WaterHeatingSystem/h:FractionDHWLoadServed) &lt;= 1.01 and sum(h:Systems/h:WaterHeating/h:WaterHeatingSystem/h:FractionDHWLoadServed) &gt;= 0.99) or count(h:Systems/h:WaterHeating/h:WaterHeatingSystem/h:FractionDHWLoadServed) = 0'>Expected sum(FractionDHWLoadServed) to be 1</sch:assert>
      <sch:assert role='ERROR' test='sum(h:Zones/h:Zone[h:ZoneType="conditioned"]/h:Spaces/h:Space/h:FloorArea) &gt;= 0.99 * number(h:BuildingSummary/h:BuildingConstruction/h:ConditionedFloorArea) or not(h:Zones/h:Zone[h:ZoneType="conditioned"]/h:Spaces/h:Space/h:FloorArea) or not(h:BuildingSummary/h:BuildingConstruction/h:ConditionedFloorArea)'>Expected sum(Zones/Zone[ZoneType="conditioned"]/Spaces/Space/FloorArea) to be equal to BuildingSummary/BuildingConstruction/ConditionedFloorArea</sch:assert>
      <sch:assert role='ERROR' test='sum(h:Zones/h:Zone[h:ZoneType="conditioned"]/h:Spaces/h:Space/h:FloorArea) &lt;= 1.01 * number(h:BuildingSummary/h:BuildingConstruction/h:ConditionedFloorArea) or not(h:Zones/h:Zone[h:ZoneType="conditioned"]/h:Spaces/h:Space/h:FloorArea) or not(h:BuildingSummary/h:BuildingConstruction/h:ConditionedFloorArea)'>Expected sum(Zones/Zone[ZoneType="conditioned"]/Spaces/Space/FloorArea) to be equal to BuildingSummary/BuildingConstruction/ConditionedFloorArea</sch:assert>

      <!-- Warnings -->
      <sch:report role='WARN' test='count(h:Zones/h:Zone[h:ZoneType="conditioned"]) &gt; 1'>While multiple conditioned zones are specified, the EnergyPlus model will only include a single conditioned thermal zone.</sch:report>
      <sch:report role='WARN' test='count(h:Enclosure/h:Windows/h:Window) = 0'>No windows specified, the model will not include window heat transfer.</sch:report>
      <sch:report role='WARN' test='sum(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionHeatLoadServed) + sum(h:Systems/h:HVAC/h:HVACPlant/*/h:IntegratedHeatingSystemFractionHeatLoadServed) = 0'>No space heating specified, the model will not include space heating energy use.</sch:report>
      <sch:report role='WARN' test='sum(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionCoolLoadServed) = 0'>No space cooling specified, the model will not include space cooling energy use.</sch:report>
      <sch:report role='WARN' test='sum(h:Systems/h:WaterHeating/h:WaterHeatingSystem/h:FractionDHWLoadServed) = 0'>No water heating specified, the model will not include water heating energy use.</sch:report>
      <sch:report role='WARN' test='count(h:Systems/h:Vehicles/h:Vehicle[h:VehicleType/h:PlugInHybridElectricVehicle]) &gt; 0'>Vehicle type 'PlugInHybridElectricVehicle' is not currently handled, the vehicle will not be modeled.</sch:report>
      <sch:report role='WARN' test='count(h:Systems/h:Vehicles/h:Vehicle[h:VehicleType/h:HybridElectricVehicle]) &gt; 0'>Vehicle type 'HybridElectricVehicle' is not currently handled, the vehicle will not be modeled.</sch:report>
      <sch:report role='WARN' test='count(h:Systems/h:Vehicles/h:Vehicle[h:VehicleType/h:InternalCombustionEngine]) &gt; 0'>Vehicle type 'InternalCombustionEngine' is not currently handled, the vehicle will not be modeled.</sch:report>
      <sch:report role='WARN' test='count(h:Systems/h:Vehicles/h:Vehicle[h:VehicleType/h:FuelCellElectricVehicle]) &gt; 0'>Vehicle type 'FuelCellElectricVehicle' is not currently handled, the vehicle will not be modeled.</sch:report>
      <sch:report role='WARN' test='count(h:Systems/h:Vehicles/h:Vehicle[h:VehicleType/h:Other]) &gt; 0'>Vehicle type 'Other' is not currently handled, the vehicle will not be modeled.</sch:report>
      <sch:report role='WARN' test='count(h:Appliances/h:ClothesWasher) = 0'>No clothes washer specified, the model will not include clothes washer energy use.</sch:report>
      <sch:report role='WARN' test='count(h:Appliances/h:ClothesDryer) = 0'>No clothes dryer specified, the model will not include clothes dryer energy use.</sch:report>
      <sch:report role='WARN' test='count(h:Appliances/h:Dishwasher) = 0'>No dishwasher specified, the model will not include dishwasher energy use.</sch:report>
      <sch:report role='WARN' test='count(h:Appliances/h:Refrigerator) = 0'>No refrigerator specified, the model will not include refrigerator energy use.</sch:report>
      <sch:report role='WARN' test='count(h:Appliances/h:CookingRange) = 0'>No cooking range specified, the model will not include cooking range/oven energy use.</sch:report>
      <sch:report role='WARN' test='count(h:Lighting/h:LightingGroup[h:Location="interior"]) = 0'>No interior lighting specified, the model will not include interior lighting energy use.</sch:report>
      <sch:report role='WARN' test='count(h:Lighting/h:LightingGroup[h:Location="exterior"]) = 0'>No exterior lighting specified, the model will not include exterior lighting energy use.</sch:report>
      <sch:report role='WARN' test='count(h:Lighting/h:LightingGroup[h:Location="garage"]) = 0 and count(h:Enclosure/h:Walls/h:Wall[h:InteriorAdjacentTo="garage" or h:ExteriorAdjacentTo="garage"]) &gt; 0'>No garage lighting specified, the model will not include garage lighting energy use.</sch:report>
      <sch:report role='WARN' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType[text()="sauna"]]) &gt; 0'>Plug load type 'sauna' is not currently handled, the plug load will not be modeled.</sch:report>
      <sch:report role='WARN' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType[text()="aquarium"]]) &gt; 0'>Plug load type 'aquarium' is not currently handled, the plug load will not be modeled.</sch:report>
      <sch:report role='WARN' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType[text()="water bed"]]) &gt; 0'>Plug load type 'water bed' is not currently handled, the plug load will not be modeled.</sch:report>
      <sch:report role='WARN' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType[text()="space heater"]]) &gt; 0'>Plug load type 'space heater' is not currently handled, the plug load will not be modeled.</sch:report>
      <sch:report role='WARN' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType[text()="computer"]]) &gt; 0'>Plug load type 'computer' is not currently handled, the plug load will not be modeled.</sch:report>
      <sch:report role='WARN' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType[text()="TV CRT"]]) &gt; 0'>Plug load type 'TV CRT' is not currently handled, the plug load will not be modeled.</sch:report>
      <sch:report role='WARN' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType[text()="TV plasma"]]) &gt; 0'>Plug load type 'TV plasma' is not currently handled, the plug load will not be modeled.</sch:report>
      <sch:report role='WARN' test='count(h:MiscLoads/h:FuelLoad[h:FuelLoadType[text()="other"]]) &gt; 0'>Fuel load type 'other' is not currently handled, the fuel load will not be modeled.</sch:report>
      <sch:report role='WARN' test='count(h:Spas/h:PortableSpa) &gt; 0'>Portable spa is not currently handled, the portable spa will not be modeled.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingSummary]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary'>
      <sch:assert role='ERROR' test='count(h:extension/h:SchedulesFilePath) &gt;= 0'>Expected 0 or more element(s) for xpath: extension/SchedulesFilePath</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HVACSizingControl) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HVACSizingControl</sch:assert> <!-- See [HVACSizingControl] -->
      <sch:assert role='ERROR' test='count(h:extension/h:ShadingControl) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ShadingControl</sch:assert> <!-- See [ShadingControl] -->
      <sch:assert role='ERROR' test='count(h:extension/h:NaturalVentilationAvailabilityDaysperWeek) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/NaturalVentilationAvailabilityDaysperWeek</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:NaturalVentilationAvailabilityDaysperWeek) &gt;= 0 or not(h:extension/h:NaturalVentilationAvailabilityDaysperWeek)'>Expected extension/NaturalVentilationAvailabilityDaysperWeek to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:NaturalVentilationAvailabilityDaysperWeek) &lt;= 7 or not(h:extension/h:NaturalVentilationAvailabilityDaysperWeek)'>Expected extension/NaturalVentilationAvailabilityDaysperWeek to be less than or equal to 7</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ElectricPanelBaselinePeakPower) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ElectricPanelBaselinePeakPower</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ElectricPanelBaselinePeakPower) &gt; 0 or not(h:extension/h:ElectricPanelBaselinePeakPower)'>Expected extension/ElectricPanelBaselinePeakPower to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACSizingControl]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:extension/h:HVACSizingControl'>
      <sch:assert role='ERROR' test='count(h:HeatPumpSizingMethodology) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatPumpSizingMethodology</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpSizingMethodology[text()="ACCA" or text()="HERS" or text()="MaxLoad"] or not(h:HeatPumpSizingMethodology)'>Expected HeatPumpSizingMethodology to be 'ACCA' or 'HERS' or 'MaxLoad'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatPumpBackupSizingMethodology) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatPumpBackupSizingMethodology</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpBackupSizingMethodology[text()="emergency" or text()="supplemental"] or not(h:HeatPumpBackupSizingMethodology)'>Expected HeatPumpBackupSizingMethodology to be 'emergency' or 'supplemental'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AllowIncreasedFixedCapacities) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AllowIncreasedFixedCapacities</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:HeatingDesignTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ManualJInputs/WinterDesignTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:CoolingDesignTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ManualJInputs/SummerDesignTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:DailyTemperatureRange) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ManualJInputs/DailyTemperatureRange</sch:assert>
      <sch:assert role='ERROR' test='h:ManualJInputs/h:DailyTemperatureRange[text()="low" or text()="medium" or text()="high"] or not(h:ManualJInputs/h:DailyTemperatureRange)'>Expected ManualJInputs/DailyTemperatureRange to be 'low' or 'medium' or 'high'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:HumidityDifference) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ManualJInputs/HumidityDifference</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:HeatingSetpoint) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ManualJInputs/HeatingSetpoint</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:CoolingSetpoint) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ManualJInputs/CoolingSetpoint</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:HumiditySetpoint) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ManualJInputs/HumiditySetpoint</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:HumiditySetpoint) &gt; 0 or not(h:ManualJInputs/h:HumiditySetpoint)'>Expected ManualJInputs/HumiditySetpoint to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:HumiditySetpoint) &lt; 1 or not(h:ManualJInputs/h:HumiditySetpoint)'>Expected ManualJInputs/HumiditySetpoint to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:InternalLoadsSensible) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ManualJInputs/InternalLoadsSensible</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:InternalLoadsSensible) &gt;= 0 or not(h:ManualJInputs/h:InternalLoadsSensible)'>Expected ManualJInputs/InternalLoadsSensible to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:InternalLoadsLatent) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ManualJInputs/InternalLoadsLatent</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:InternalLoadsLatent) &gt;= 0 or not(h:ManualJInputs/h:InternalLoadsLatent)'>Expected ManualJInputs/InternalLoadsLatent to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:NumberofOccupants) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ManualJInputs/NumberofOccupants</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:NumberofOccupants) &gt;= 0 or not(h:ManualJInputs/h:NumberofOccupants)'>Expected ManualJInputs/NumberofOccupants to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:InfiltrationShieldingClass) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ManualJInputs/InfiltrationShieldingClass</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:InfiltrationShieldingClass) &gt;= 1 or not(h:ManualJInputs/h:InfiltrationShieldingClass)'>Expected ManualJInputs/InfiltrationShieldingClass to be greater than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:InfiltrationShieldingClass) &lt;= 5 or not(h:ManualJInputs/h:InfiltrationShieldingClass)'>Expected ManualJInputs/InfiltrationShieldingClass to be less than or equal to 5</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:InfiltrationMethod) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ManualJInputs/InfiltrationMethod</sch:assert> <!-- See [ManualJInfiltrationMethod=DefaultInfiltrationTable] or [ManualJInfiltrationMethod=BlowerDoor] -->
      <sch:assert role='ERROR' test='h:ManualJInputs/h:InfiltrationMethod[text()="default infiltration table" or text()="blower door"] or not(h:ManualJInputs/h:InfiltrationMethod)'>Expected InfiltrationMethod/DailyTemperatureRange to be 'default infiltration table' or 'blower door'</sch:assert>
      <!-- Moved/deprecated UseMaxLoadForHeatPumps input; see https://github.com/NREL/OpenStudio-HPXML/pull/1039 -->
      <sch:assert role='ERROR' test='count(h:UseMaxLoadForHeatPumps) = 0'>UseMaxLoadForHeatPumps has been replaced by HeatPumpSizingMethodology</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ManualJInfiltrationMethod=DefaultInfiltrationTable]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:BuildingSummary/h:extension/h:HVACSizingControl/h:ManualJInputs/h:InfiltrationMethod="default infiltration table"]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:LeakinessDescription]) = 1'>Expected 1 element(s) for xpath: Enclosure/AirInfiltration/AirInfiltrationMeasurement[LeakinessDescription]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ManualJInfiltrationMethod=BlowerDoor]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:BuildingSummary/h:extension/h:HVACSizingControl/h:ManualJInputs/h:InfiltrationMethod="blower door"]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:BuildingAirLeakage/h:AirLeakage | h:EffectiveLeakageArea | h:SpecificLeakageArea]) = 1'>Expected 1 element(s) for xpath: Enclosure/AirInfiltration/AirInfiltrationMeasurement[BuildingAirLeakage/h:AirLeakage | EffectiveLeakageArea | SpecificLeakageArea]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ShadingControl]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:extension/h:ShadingControl'>
      <sch:assert role='ERROR' test='count(h:SummerBeginMonth) = 1'>Expected 1 element(s) for xpath: SummerBeginMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:SummerBeginDayOfMonth) = 1'>Expected 1 element(s) for xpath: SummerBeginDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:SummerEndMonth) = 1'>Expected 1 element(s) for xpath: SummerEndMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:SummerEndDayOfMonth) = 1'>Expected 1 element(s) for xpath: SummerEndDayOfMonth</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Site]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:Site'>
      <sch:assert role='ERROR' test='count(h:SiteType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SiteType</sch:assert>
      <sch:assert role='ERROR' test='count(h:ShieldingofHome) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ShieldingofHome</sch:assert>
      <sch:assert role='ERROR' test='h:ShieldingofHome[text()="well-shielded" or text()="normal" or text()="exposed"] or not(h:ShieldingofHome)'>Expected ShieldingofHome to be 'well-shielded' or 'normal' or 'exposed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Soil) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Soil</sch:assert> <!-- See [Soil] -->
      <sch:assert role='ERROR' test='count(h:extension/h:Neighbors) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/Neighbors</sch:assert> <!-- See [Neighbors] -->
      <!-- Moved/deprecated ShelterCoefficient input; see https://github.com/NREL/OpenStudio-HPXML/pull/653 -->
      <sch:assert role='ERROR' test='count(h:extension/h:ShelterCoefficient) = 0'>extension/ShelterCoefficient has been replaced by ShieldingofHome</sch:assert>
      <!-- Moved/deprecated extension/GroundConductivity input; see https://github.com/NREL/OpenStudio-HPXML/pull/1391 -->
      <sch:assert role='ERROR' test='count(h:extension/h:GroundConductivity) = 0'>extension/GroundConductivity has been replaced by Soil/Conductivity</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Soil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:Site/h:Soil'>
      <sch:assert role='ERROR' test='count(h:SoilType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SoilType</sch:assert>
      <sch:assert role='ERROR' test='h:SoilType[text()="sand" or text()="silt" or text()="clay" or text()="loam" or text()="gravel" or text()="unknown"] or not(h:SoilType)'>Expected SoilType to be 'sand' or 'silt' or 'clay' or 'loam' or 'gravel' or 'unknown'</sch:assert>
      <sch:assert role='ERROR' test='count(h:MoistureType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: MoistureType</sch:assert>
      <sch:assert role='ERROR' test='h:MoistureType[text()="dry" or text()="wet" or text()="mixed"] or not(h:MoistureType)'>Expected MoistureType to be 'dry' or 'wet' or 'mixed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Conductivity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Conductivity</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:Diffusivity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/Diffusivity</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:Diffusivity) &gt; 0 or not(h:extension/h:Diffusivity)'>Expected extension/Diffusivity to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Neighbors]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:Site/h:extension/h:Neighbors'>
      <sch:assert role='ERROR' test='count(h:NeighborBuilding) &gt;= 1'>Expected 1 or more element(s) for xpath: NeighborBuilding</sch:assert> <!-- See [NeighborBuilding] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[NeighborBuilding]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:Site/h:extension/h:Neighbors/h:NeighborBuilding'>
      <sch:assert role='ERROR' test='count(h:Azimuth) + count(h:Orientation) &gt;= 1'>Expected 1 or more element(s) for xpath: Azimuth | Orientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:Distance) = 1'>Expected 1 element(s) for xpath: Distance</sch:assert>
      <sch:assert role='ERROR' test='count(h:Height) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Height</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingOccupancy]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingOccupancy'>
      <sch:assert role='ERROR' test='count(h:NumberofResidents) &lt;= 1'>Expected 0 or 1 element(s) for xpath: NumberofResidents</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GeneralWaterUseUsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/GeneralWaterUseUsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:GeneralWaterUseUsageMultiplier) &gt;= 0 or not(h:extension/h:GeneralWaterUseUsageMultiplier)'>Expected extension/GeneralWaterUseUsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GeneralWaterUseWeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/GeneralWaterUseWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GeneralWaterUseWeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/GeneralWaterUseWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GeneralWaterUseMonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/GeneralWaterUseMonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingConstruction]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingConstruction'>
      <sch:assert role='ERROR' test='count(h:YearBuilt) &lt;= 1'>Expected 0 or 1 element(s) for xpath: YearBuilt</sch:assert>
      <sch:assert role='ERROR' test='count(h:ResidentialFacilityType) = 1'>Expected 1 element(s) for xpath: ResidentialFacilityType</sch:assert> <!-- See [BuildingType=SFAorMF] or [BuildingType=SFDorMH] -->
      <sch:assert role='ERROR' test='h:ResidentialFacilityType[text()="single-family detached" or text()="single-family attached" or text()="apartment unit" or text()="manufactured home"] or not(h:ResidentialFacilityType)'>Expected ResidentialFacilityType to be 'single-family detached' or 'single-family attached' or 'apartment unit' or 'manufactured home'</sch:assert>
      <sch:assert role='ERROR' test='count(h:UnitHeightAboveGrade) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UnitHeightAboveGrade</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnits) &lt;= 1'>Expected 0 or 1 element(s) for xpath: NumberofUnits</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofConditionedFloors) = 1'>Expected 1 element(s) for xpath: NumberofConditionedFloors</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofConditionedFloorsAboveGrade) = 1'>Expected 1 element(s) for xpath: NumberofConditionedFloorsAboveGrade</sch:assert>
      <!-- We are more strict than HPXML schema for NumberofConditionedFloorsAboveGrade; see https://github.com/NREL/OpenStudio-HPXML/issues/1755 -->
      <sch:assert role='ERROR' test='number(h:NumberofConditionedFloorsAboveGrade) &gt; 0 or not(h:NumberofConditionedFloorsAboveGrade)'>Expected NumberofConditionedFloorsAboveGrade to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofConditionedFloors) &gt;= number(h:NumberofConditionedFloorsAboveGrade) or not(h:NumberofConditionedFloors) or not(h:NumberofConditionedFloorsAboveGrade)'>Expected NumberofConditionedFloors to be greater than or equal to NumberofConditionedFloorsAboveGrade</sch:assert>
      <sch:assert role='ERROR' test='count(h:AverageCeilingHeight) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AverageCeilingHeight</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofBedrooms) = 1'>Expected 1 element(s) for xpath: NumberofBedrooms</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofBathrooms) &lt;= 1'>Expected 0 or 1 element(s) for xpath: NumberofBathrooms</sch:assert>
      <sch:assert role='ERROR' test='count(h:ConditionedFloorArea) = 1'>Expected 1 element(s) for xpath: ConditionedFloorArea</sch:assert>
      <sch:assert role='ERROR' test='number(h:ConditionedFloorArea) &gt;= (sum(../../h:Enclosure/h:Slabs/h:Slab[h:InteriorAdjacentTo="conditioned space" or h:InteriorAdjacentTo="basement - conditioned"]/h:Area) + sum(../../h:Enclosure/h:Floors/h:Floor[h:InteriorAdjacentTo="conditioned space" and not(h:ExteriorAdjacentTo="attic - vented" or h:ExteriorAdjacentTo="attic - unvented" or ((h:ExteriorAdjacentTo="other housing unit" or h:ExteriorAdjacentTo="other heated space" or h:ExteriorAdjacentTo="other multifamily buffer space" or h:ExteriorAdjacentTo="other non-freezing space") and h:FloorOrCeiling="ceiling"))]/h:Area) - 1) or not(h:ConditionedFloorArea)'>Expected ConditionedFloorArea to be greater than or equal to the sum of conditioned slab/floor areas.</sch:assert>
      <sch:assert role='ERROR' test='count(h:ConditionedBuildingVolume) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ConditionedBuildingVolume</sch:assert>
      <!-- Moved/deprecated HasFlueOrChimney input; see https://github.com/NREL/OpenStudio-HPXML/pull/1379 -->
      <sch:assert role='ERROR' test='count(h:extension/h:HasFlueOrChimney) = 0'>extension/HasFlueOrChimney has been replaced by /HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/extension/HasFlueOrChimneyInConditionedSpace</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:NumberofUnits) &gt; 1'>NumberofUnits is greater than 1, indicating that the HPXML Building represents multiple dwelling units; simulation outputs will reflect this unit multiplier.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingType=SFAorMF]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]'>
      <!-- Warnings -->
      <sch:report role='WARN' test='count(//h:ExteriorAdjacentTo[text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]) = 0'>ResidentialFacilityType is single-family attached or apartment unit, but no attached surfaces were found. This may result in erroneous results (e.g., for infiltration).</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingType=SFDorMH]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family detached" or text()="manufactured home"]'>
      <sch:assert role='ERROR' test='count(/h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"]) = 0'>WholeSFAorMFBuildingSimulation must be false or omitted for single-family detached/manufactured homes.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClimateZoneIECC]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:ClimateandRiskZones/h:ClimateZoneIECC'>
      <sch:assert role='ERROR' test='count(h:Year) = 1'>Expected 1 element(s) for xpath: Year</sch:assert>
      <sch:assert role='ERROR' test='count(h:ClimateZone) = 1'>Expected 1 element(s) for xpath: ClimateZone</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Zones]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Zones'>
      <sch:assert role='ERROR' test='count(h:Zone) &gt;= 1'>Expected 1 or more element(s) for xpath: Zone</sch:assert> <!-- See [Zone] and [HasCondZones=HeatingSystem] and and [HasCondZones=CoolingSystem] and [HasCondZones=HeatPump] and [HasCondZones=Surface] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Zone]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Zones/h:Zone'>
      <sch:assert role='ERROR' test='count(h:ZoneType) = 1'>Expected 1 element(s) for xpath: ZoneType</sch:assert>
      <sch:assert role='ERROR' test='count(h:Spaces/h:Space) &gt;= 1'>Expected 1 or more element(s) for xpath: Spaces/Space</sch:assert> <!-- See [Space=Conditioned] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HasCondZones=HeatingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Zones/h:Zone[h:ZoneType="conditioned"]]/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem'>
      <sch:assert role='ERROR' test='count(h:AttachedToZone) = 1'>Expected 1 element(s) for xpath: AttachedToZone</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HasCondZones=CoolingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Zones/h:Zone[h:ZoneType="conditioned"]]/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem'>
      <sch:assert role='ERROR' test='count(h:AttachedToZone) = 1'>Expected 1 element(s) for xpath: AttachedToZone</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HasCondZones=HeatPump]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Zones/h:Zone[h:ZoneType="conditioned"]]/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump'>
      <sch:assert role='ERROR' test='count(h:AttachedToZone) = 1'>Expected 1 element(s) for xpath: AttachedToZone</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HasCondZones=Surface]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Zones/h:Zone[h:ZoneType="conditioned"]]/h:Enclosure/*/*[contains(h:InteriorAdjacentTo, "conditioned") and (not(h:ExteriorAdjacentTo) or h:ExteriorAdjacentTo!="other housing unit")]'>
      <sch:assert role='ERROR' test='count(h:AttachedToSpace) = 1'>Expected 1 element(s) for xpath: AttachedToSpace</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Space=Conditioned]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Zones/h:Zone[h:ZoneType="conditioned"]/h:Spaces/h:Space'>
      <sch:assert role='ERROR' test='count(h:FloorArea) = 1'>Expected 1 element(s) for xpath: FloorArea</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ManualJInputs/h:InternalLoadsSensible) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ManualJInputs/InternalLoadsSensible</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ManualJInputs/h:InternalLoadsSensible) &gt;= 0 or not(h:extension/h:ManualJInputs/h:InternalLoadsSensible)'>Expected extension/ManualJInputs/InternalLoadsSensible to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(../*/h:extension/h:ManualJInputs/h:InternalLoadsSensible) = count(../h:Space) or count(../*/h:extension/h:ManualJInputs/h:InternalLoadsSensible) = 0'>Expected extension/ManualJInputs/InternalLoadsSensible for all Spaces or no Spaces</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ManualJInputs/h:InternalLoadsLatent) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ManualJInputs/InternalLoadsLatent</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ManualJInputs/h:InternalLoadsLatent) &gt;= 0 or not(h:extension/h:ManualJInputs/h:InternalLoadsLatent)'>Expected extension/ManualJInputs/InternalLoadsLatent to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(../*/h:extension/h:ManualJInputs/h:InternalLoadsLatent) = count(../h:Space) or count(../*/h:extension/h:ManualJInputs/h:InternalLoadsLatent) = 0'>Expected extension/ManualJInputs/InternalLoadsLatent for all Spaces or no Spaces</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ManualJInputs/h:NumberofOccupants) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ManualJInputs/NumberofOccupants</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ManualJInputs/h:NumberofOccupants) &gt;= 0 or not(h:extension/h:ManualJInputs/h:NumberofOccupants)'>Expected extension/ManualJInputs/NumberofOccupants to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(../*/h:extension/h:ManualJInputs/h:NumberofOccupants) = count(../h:Space) or count(../*/h:extension/h:ManualJInputs/h:NumberofOccupants) = 0'>Expected extension/ManualJInputs/NumberofOccupants for all Spaces or no Spaces</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ManualJInputs/h:FenestrationLoadProcedure) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ManualJInputs/FenestrationLoadProcedure</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:ManualJInputs/h:FenestrationLoadProcedure[text()="standard" or text()="peak"] or not(h:extension/h:ManualJInputs/h:FenestrationLoadProcedure)'>Expected extension/ManualJInputs/FenestrationLoadProcedure to be 'standard' or 'peak'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirInfiltrationMeasurement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:BuildingAirLeakage/h:AirLeakage | h:EffectiveLeakageArea | h:SpecificLeakageArea | h:LeakinessDescription]'>
      <sch:assert role='ERROR' test='h:BuildingAirLeakage/h:UnitofMeasure[text()="ACH" or text()="ACHnatural" or text()="CFM" or text()="CFMnatural"] or not(h:BuildingAirLeakage/h:UnitofMeasure)'>Expected BuildingAirLeakage/UnitofMeasure to be 'ACH' or 'ACHnatural' or 'CFM' or 'CFMnatural'</sch:assert>
      <sch:assert role='ERROR' test='h:LeakinessDescription[text()="very tight" or text()="tight" or text()="average" or text()="leaky" or text()="very leaky"] or not(h:LeakinessDescription)'>Expected LeakinessDescription to be 'very tight' or 'tight' or 'average' or 'leaky' or 'very leaky'</sch:assert> <!-- See [LeakinessDescription] -->
      <sch:assert role='ERROR' test='count(h:InfiltrationVolume) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InfiltrationVolume</sch:assert>
      <sch:assert role='ERROR' test='count(h:InfiltrationHeight) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InfiltrationHeight</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirInfiltrationMeasurement=SFAorMultifamily]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]/h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:BuildingAirLeakage/h:AirLeakage | h:EffectiveLeakageArea | h:SpecificLeakageArea]'>
      <sch:assert role='ERROR' test='count(h:TypeOfInfiltrationLeakage) = 1'>Expected 1 element(s) for xpath: TypeOfInfiltrationLeakage</sch:assert>
      <sch:assert role='ERROR' test='h:TypeOfInfiltrationLeakage[text()="unit total" or text()="unit exterior only"] or not(h:TypeOfInfiltrationLeakage)'>Expected TypeOfInfiltrationLeakage to be 'unit total' or 'unit exterior only'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:Aext) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/Aext</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:Aext) &gt; 0 or not(h:extension/h:Aext)'>Expected extension/Aext to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirInfiltrationMeasurement=ACHorCFM]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:BuildingAirLeakage/h:UnitofMeasure[text()="ACH" or text()="CFM"]]'>
      <sch:assert role='ERROR' test='count(h:HousePressure) = 1'>Expected 1 element(s) for xpath: HousePressure</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LeakinessDescription]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement/h:LeakinessDescription]'>
      <sch:assert role='ERROR' test='count(h:BuildingSummary/h:BuildingConstruction/h:YearBuilt) = 1'>Expected 1 element(s) for xpath: BuildingSummary/BuildingConstruction/YearBuilt</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[VentedAttic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Attics/h:Attic[h:Vented="true"]'>
      <sch:assert role='ERROR' test='count(h:VentilationRate) &lt;= 1'>Expected 0 or 1 element(s) for xpath: VentilationRate</sch:assert> <!-- See [VentedAttic=VentilationRate] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[VentedAttic=VentilationRate]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Attics/h:Attic[h:Vented="true"]/h:VentilationRate'>
      <sch:assert role='ERROR' test='count(h:UnitofMeasure) = 1'>Expected 1 element(s) for xpath: UnitofMeasure</sch:assert>
      <sch:assert role='ERROR' test='h:UnitofMeasure[text()="SLA" or text()="ACHnatural"] or not (h:UnitofMeasure)'>Expected UnitofMeasure to be 'SLA' or 'ACHnatural'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Value) = 1'>Expected 1 element(s) for xpath: Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[UnventedAttic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Attics/h:Attic[h:Vented="false"]'>
      <sch:assert role='ERROR' test='count(h:WithinInfiltrationVolume) &lt;= 1'>Expected 0 or 1 element(s) for xpath: WithinInfiltrationVolume</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[VentedCrawl]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Foundations/h:Foundation[h:FoundationType/h:Crawlspace[h:Vented="true"]]'>
      <sch:assert role='ERROR' test='count(h:VentilationRate) &lt;= 1'>Expected 0 or 1 element(s) for xpath: VentilationRate</sch:assert> <!-- See [VentedCrawl=VentilationRate] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[VentedCrawl=VentilationRate]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Foundations/h:Foundation[h:FoundationType/h:Crawlspace[h:Vented="true"]]/h:VentilationRate'>
      <sch:assert role='ERROR' test='count(h:UnitofMeasure) = 1'>Expected 1 element(s) for xpath: UnitofMeasure</sch:assert>
      <sch:assert role='ERROR' test='h:UnitofMeasure[text()="SLA"] or not (h:UnitofMeasure)'>Expected UnitofMeasure to be 'SLA'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Value) = 1'>Expected 1 element(s) for xpath: Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[UnventedCrawl]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Foundations/h:Foundation[h:FoundationType/h:Crawlspace[h:Vented="false"]]'>
      <sch:assert role='ERROR' test='count(h:WithinInfiltrationVolume) &lt;= 1'>Expected 0 or 1 element(s) for xpath: WithinInfiltrationVolume</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[UncondBasement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Foundations/h:Foundation[h:FoundationType/h:Basement[h:Conditioned="false"]]'>
      <sch:assert role='ERROR' test='count(h:WithinInfiltrationVolume) &lt;= 1'>Expected 0 or 1 element(s) for xpath: WithinInfiltrationVolume</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CondBasement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Foundations/h:Foundation[h:FoundationType/h:Basement[h:Conditioned="true"]]'>
      <sch:assert role='ERROR' test='count(h:WithinInfiltrationVolume) &lt;= 1'>Expected 0 or 1 element(s) for xpath: WithinInfiltrationVolume</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ManufacturedHomeBelly]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Foundations/h:Foundation/h:FoundationType/h:BellyAndWing'>
      <sch:assert role='ERROR' test='count(h:SkirtPresent) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SkirtPresent</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Roof]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Roofs/h:Roof'>
      <sch:assert role='ERROR' test='count(h:AttachedToSpace) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AttachedToSpace</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: InteriorAdjacentTo</sch:assert> <!-- See [RoofType=AdjacentToVentedAttic] or [RoofType=AdjacentToUnventedAttic] -->
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="attic - vented" or text()="attic - unvented" or text()="conditioned space" or text()="garage"] or not(h:InteriorAdjacentTo)'>Expected InteriorAdjacentTo to be 'attic - vented' or 'attic - unvented' or 'conditioned space' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) + count(h:Orientation) &gt;= 0'>Expected 0 or more element(s) for xpath: Azimuth | Orientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:RoofType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RoofType</sch:assert>
      <sch:assert role='ERROR' test='h:RoofType[text()="asphalt or fiberglass shingles" or text()="wood shingles or shakes" or text()="shingles" or text()="slate or tile shingles" or text()="metal surfacing" or text()="plastic/rubber/synthetic sheeting" or text()="expanded polystyrene sheathing" or text()="concrete" or text()="cool roof"] or not(h:RoofType)'>Expected RoofType to be 'asphalt or fiberglass shingles' or 'wood shingles or shakes' or 'shingles' or 'slate or tile shingles' or 'metal surfacing' or 'plastic/rubber/synthetic sheeting' or 'expanded polystyrene sheathing' or 'concrete' or 'cool roof'</sch:assert>
      <sch:assert role='ERROR' test='count(h:RoofColor) + count(h:SolarAbsorptance) &gt;= 0'>Expected 0 or more element(s) for xpath: RoofColor | SolarAbsorptance</sch:assert>
      <sch:assert role='ERROR' test='h:RoofColor[text()="dark" or text()="medium dark" or text()="medium" or text()="medium light" or text()="light" or text()="reflective"] or not(h:RoofColor)'>Expected RoofColor to be 'dark' or 'medium dark' or 'medium' or 'medium light' or 'light' or 'reflective'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Emittance) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Emittance</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorFinish/h:Type) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorFinish/Type</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorFinish/h:Type[text()="gypsum board" or text()="gypsum composite board" or text()="plaster" or text()="wood" or text()="not present"] or not(h:InteriorFinish/h:Type)'>Expected InteriorFinish/Type to be 'gypsum board' or 'gypsum composite board' or 'plaster' or 'wood' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorFinish/h:Thickness) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorFinish/Thickness</sch:assert>
      <sch:assert role='ERROR' test='count(h:Pitch) = 1'>Expected 1 element(s) for xpath: Pitch</sch:assert>
      <sch:assert role='ERROR' test='count(h:RadiantBarrier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RadiantBarrier</sch:assert> <!-- See [Roof_RadiantBarrier] -->
      <sch:assert role='ERROR' test='count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: Insulation/AssemblyEffectiveRValue</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Roof_RadiantBarrier]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Roofs/h:Roof[h:RadiantBarrier="true"]'>
      <sch:assert role='ERROR' test='count(h:RadiantBarrierGrade) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RadiantBarrierGrade</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[RimJoist]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:RimJoists/h:RimJoist[not(h:SystemIdentifier/@sameas and /h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"])]'>
      <sch:assert role='ERROR' test='count(h:AttachedToSpace) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AttachedToSpace</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: ExteriorAdjacentTo</sch:assert>
      <sch:assert role='ERROR' test='h:ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:ExteriorAdjacentTo)'>Expected ExteriorAdjacentTo to be 'outside' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: InteriorAdjacentTo</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="conditioned space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage"] or not(h:InteriorAdjacentTo)'>Expected InteriorAdjacentTo to be 'conditioned space' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) + count(h:Orientation) &gt;= 0'>Expected 0 or more element(s) for xpath: Azimuth | Orientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:Siding) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Siding</sch:assert> <!-- See [Siding] -->
      <sch:assert role='ERROR' test='h:Siding[text()="wood siding" or text()="vinyl siding" or text()="stucco" or text()="fiber cement siding" or text()="brick veneer" or text()="stone veneer" or text()="aluminum siding" or text()="masonite siding" or text()="composite shingle siding" or text()="asbestos siding" or text()="synthetic stucco" or text()="not present"] or not(h:Siding)'>Expected Siding to be 'wood siding' or 'vinyl siding' or 'stucco' or 'fiber cement siding' or 'brick veneer' or 'stone veneer' or 'aluminum siding' or 'masonite siding' or 'composite shingle siding' or 'asbestos siding' or 'synthetic stucco' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Color) + count(h:SolarAbsorptance) &gt;= 0'>Expected 0 or more element(s) for xpath: Color | SolarAbsorptance</sch:assert>
      <sch:assert role='ERROR' test='h:Color[text()="dark" or text()="medium dark" or text()="medium" or text()="medium light" or text()="light" or text()="reflective"] or not(h:Color)'>Expected Color to be 'dark' or 'medium dark' or 'medium' or 'medium light' or 'light' or 'reflective'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Emittance) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Emittance</sch:assert>
      <sch:assert role='ERROR' test='count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: Insulation/AssemblyEffectiveRValue</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Wall]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Walls/h:Wall[not(h:SystemIdentifier/@sameas and /h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"])]'>
      <sch:assert role='ERROR' test='count(h:AttachedToSpace) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AttachedToSpace</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: ExteriorAdjacentTo</sch:assert>
      <sch:assert role='ERROR' test='h:ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:ExteriorAdjacentTo)'>Expected ExteriorAdjacentTo to be 'outside' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: InteriorAdjacentTo</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="conditioned space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage"] or not(h:InteriorAdjacentTo)'>Expected InteriorAdjacentTo to be 'conditioned space' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:WallType[h:WoodStud | h:DoubleWoodStud | h:ConcreteMasonryUnit | h:StructuralInsulatedPanel | h:InsulatedConcreteForms | h:SteelFrame | h:SolidConcrete | h:StructuralBrick | h:StrawBale | h:Stone | h:LogWall | h:Adobe]) = 1'>Expected 1 element(s) for xpath: WallType[WoodStud | DoubleWoodStud | ConcreteMasonryUnit | StructuralInsulatedPanel | InsulatedConcreteForms | SteelFrame | SolidConcrete | StructuralBrick | StrawBale | Stone | LogWall | Adobe]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) + count(h:Orientation) &gt;= 0'>Expected 0 or more element(s) for xpath: Azimuth | Orientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:Siding) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Siding</sch:assert>
      <sch:assert role='ERROR' test='h:Siding[text()="wood siding" or text()="vinyl siding" or text()="stucco" or text()="fiber cement siding" or text()="brick veneer" or text()="stone veneer" or text()="aluminum siding" or text()="masonite siding" or text()="composite shingle siding" or text()="asbestos siding" or text()="synthetic stucco" or text()="not present"] or not(h:Siding)'>Expected Siding to be 'wood siding' or 'vinyl siding' or 'stucco' or 'fiber cement siding' or 'brick veneer' or 'stone veneer' or 'aluminum siding' or 'masonite siding' or 'composite shingle siding' or 'asbestos siding' or 'synthetic stucco' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Color) + count(h:SolarAbsorptance) &gt;= 0'>Expected 0 or more element(s) for xpath: Color | SolarAbsorptance</sch:assert>
      <sch:assert role='ERROR' test='h:Color[text()="dark" or text()="medium dark" or text()="medium" or text()="medium light" or text()="light" or text()="reflective"] or not(h:Color)'>Expected Color to be 'dark' or 'medium dark' or 'medium' or 'medium light' or 'light' or 'reflective'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Emittance) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Emittance</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorFinish/h:Type) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorFinish/Type</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorFinish/h:Type[text()="gypsum board" or text()="gypsum composite board" or text()="plaster" or text()="wood" or text()="not present"] or not(h:InteriorFinish/h:Type)'>Expected InteriorFinish/Type to be 'gypsum board' or 'gypsum composite board' or 'plaster' or 'wood' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorFinish/h:Thickness) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorFinish/Thickness</sch:assert>
      <sch:assert role='ERROR' test='count(h:RadiantBarrier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RadiantBarrier</sch:assert> <!-- See [Wall_RadiantBarrier] -->
      <sch:assert role='ERROR' test='count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: Insulation/AssemblyEffectiveRValue</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Wall_RadiantBarrier]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Walls/h:Wall[h:RadiantBarrier="true"]'>
      <sch:assert role='ERROR' test='count(h:RadiantBarrierGrade) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RadiantBarrierGrade</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FoundationWall]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:FoundationWalls/h:FoundationWall[not(h:SystemIdentifier/@sameas and /h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"])]'>
      <sch:assert role='ERROR' test='count(h:AttachedToSpace) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AttachedToSpace</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: ExteriorAdjacentTo</sch:assert>
      <sch:assert role='ERROR' test='h:ExteriorAdjacentTo[text()="ground" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:ExteriorAdjacentTo)'>Expected ExteriorAdjacentTo to be 'ground' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: InteriorAdjacentTo</sch:assert> <!-- See [FoundationWallType=AdjacentToVentedCrawl] or [FoundationWallType=AdjacentToUnventedCrawl] or [FoundationWallType=AdjacentToUncondBasement] -->
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage"] or not(h:InteriorAdjacentTo)'>Expected InteriorAdjacentTo to be 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Type) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Type</sch:assert>
      <sch:assert role='ERROR' test='h:Type[text()="solid concrete" or text()="concrete block" or text()="concrete block foam core" or text()="concrete block vermiculite core" or text()="concrete block perlite core" or text()="concrete block solid core" or text()="double brick" or text()="wood"] or not(h:Type)'>Expected Type to be 'solid concrete' or 'concrete block' or 'concrete block foam core' or 'concrete block vermiculite core' or 'concrete block perlite core' or 'concrete block solid core' or 'double brick' or 'wood'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Height) = 1'>Expected 1 element(s) for xpath: Height</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) + count(h:Length) &gt;= 1'>Expected 1 or more element(s) for xpath: Area | Length</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) + count(h:Orientation) &gt;= 0'>Expected 0 or more element(s) for xpath: Azimuth | Orientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:Thickness) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Thickness</sch:assert>
      <sch:assert role='ERROR' test='number(h:Thickness) &gt; 0 or not(h:Thickness)'>Expected Thickness to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorFinish/h:Type) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorFinish/Type</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorFinish/h:Type[text()="gypsum board" or text()="gypsum composite board" or text()="plaster" or text()="wood" or text()="not present"] or not(h:InteriorFinish/h:Type)'>Expected InteriorFinish/Type to be 'gypsum board' or 'gypsum composite board' or 'plaster' or 'wood' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorFinish/h:Thickness) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorFinish/Thickness</sch:assert>
      <sch:assert role='ERROR' test='count(h:DepthBelowGrade) = 1'>Expected 1 element(s) for xpath: DepthBelowGrade</sch:assert>
      <sch:assert role='ERROR' test='number(h:DepthBelowGrade) &lt;= number(h:Height) or not(h:DepthBelowGrade) or not(h:Height)'>Expected DepthBelowGrade to be less than or equal to Height</sch:assert>
      <!-- Insulation: either specify interior and exterior layers OR assembly R-value: -->
      <sch:assert role='ERROR' test='count(h:Insulation/h:Layer[h:InstallationType[text()="continuous - interior"]]) + count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: Insulation/Layer[InstallationType[text()="continuous - interior"]] | Insulation/AssemblyEffectiveRValue</sch:assert> <!-- See [FoundationWallInsulationLayer] -->
      <sch:assert role='ERROR' test='count(h:Insulation/h:Layer[h:InstallationType[text()="continuous - exterior"]]) + count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: Insulation/Layer[InstallationType[text()="continuous - exterior"]] | Insulation/AssemblyEffectiveRValue</sch:assert> <!-- See [FoundationWallInsulationLayer] -->
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:Thickness) &lt; 1 and number(h:Thickness) &gt; 0'>Thickness is less than 1 inch; this may indicate incorrect units.</sch:report>
      <sch:report role='WARN' test='number(h:Thickness) &gt; 12'>Thickness is greater than 12 inches; this may indicate incorrect units.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FoundationWallInsulationLayer]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:FoundationWalls/h:FoundationWall/h:Insulation/h:Layer[h:InstallationType="continuous - exterior" or h:InstallationType="continuous - interior"]'>
      <sch:assert role='ERROR' test='count(h:NominalRValue) = 1'>Expected 1 element(s) for xpath: NominalRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistanceToTopOfInsulation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DistanceToTopOfInsulation</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistanceToBottomOfInsulation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DistanceToBottomOfInsulation</sch:assert>
      <sch:assert role='ERROR' test='number(h:DistanceToBottomOfInsulation) &gt;= number(h:DistanceToTopOfInsulation) or not(h:DistanceToBottomOfInsulation) or not(h:DistanceToTopOfInsulation)'>Expected DistanceToBottomOfInsulation to be greater than or equal to DistanceToTopOfInsulation</sch:assert>
      <sch:assert role='ERROR' test='number(h:DistanceToBottomOfInsulation) &lt;= number(../../h:Height) or not(h:DistanceToBottomOfInsulation) or not(../../h:Height)'>Expected DistanceToBottomOfInsulation to be less than or equal to ../../Height</sch:assert>
      <!-- Moved/deprecated extension/DistanceToTopOfInsulation & extension/DistanceToBottomOfInsulation inputs; see https://github.com/NREL/OpenStudio-HPXML/pull/894 -->
      <sch:assert role='ERROR' test='count(h:extension/h:DistanceToTopOfInsulation) = 0'>extension/DistanceToTopOfInsulation has been replaced by DistanceToTopOfInsulation</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:DistanceToBottomOfInsulation) = 0'>extension/DistanceToBottomOfInsulation has been replaced by DistanceToBottomOfInsulation</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Floor]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Floors/h:Floor[not(h:SystemIdentifier/@sameas and /h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"])]'>
      <sch:assert role='ERROR' test='count(h:AttachedToSpace) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AttachedToSpace</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: ExteriorAdjacentTo</sch:assert> <!-- See [FloorType=AdjacentToOther] -->
      <sch:assert role='ERROR' test='h:ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="manufactured home underbelly"] or not(h:ExteriorAdjacentTo)'>Expected ExteriorAdjacentTo to be 'outside' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'manufactured home underbelly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: InteriorAdjacentTo</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="conditioned space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage"] or not(h:InteriorAdjacentTo)'>Expected InteriorAdjacentTo to be 'conditioned space' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FloorType[h:WoodFrame | h:StructuralInsulatedPanel | h:SteelFrame | h:SolidConcrete]) = 1'>Expected 1 element(s) for xpath: FloorType[WoodFrame | StructuralInsulatedPanel | SteelFrame | SolidConcrete]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorFinish/h:Type) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorFinish/Type</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorFinish/h:Type[text()="gypsum board" or text()="gypsum composite board" or text()="plaster" or text()="wood" or text()="not present"] or not(h:InteriorFinish/h:Type)'>Expected InteriorFinish/Type to be 'gypsum board' or 'gypsum composite board' or 'plaster' or 'wood' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorFinish/h:Thickness) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorFinish/Thickness</sch:assert>
      <sch:assert role='ERROR' test='count(h:RadiantBarrier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RadiantBarrier</sch:assert> <!-- See [Floor_RadiantBarrier] -->
      <sch:assert role='ERROR' test='count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: Insulation/AssemblyEffectiveRValue</sch:assert>
      <!-- Moved/deprecated extension/OtherSpaceAboveOrBelow input; see https://github.com/NREL/OpenStudio-HPXML/pull/1203 -->
      <sch:assert role='ERROR' test='count(h:extension/h:OtherSpaceAboveOrBelow) = 0'>extension/OtherSpaceAboveOrBelow has been replaced by FloorOrCeiling</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Floor_RadiantBarrier]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Floors/h:Floor[h:RadiantBarrier="true"]'>
      <sch:assert role='ERROR' test='count(h:RadiantBarrierGrade) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RadiantBarrierGrade</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FloorType=AdjacentToOther]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Floors/h:Floor[h:ExteriorAdjacentTo[text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]]'>
      <sch:assert role='ERROR' test='count(h:FloorOrCeiling[text()="floor" or text()="ceiling"]) = 1'>Expected 1 element(s) for xpath: FloorOrCeiling[text()="floor" or text()="ceiling"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SameasSurfaces]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/*/*[h:SystemIdentifier/@sameas and /h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"]]'>
      <sch:assert role='ERROR' test='count(*) = 1'>Expected only SystemIdentifier to be specified when sameas attribute used</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Slab]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Slabs/h:Slab'>
      <sch:assert role='ERROR' test='count(h:AttachedToSpace) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AttachedToSpace</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorAdjacentTo) = 1'>Expected 1 element(s) for xpath: InteriorAdjacentTo</sch:assert> <!-- See [SlabInteriorAdjacentTo] -->
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="conditioned space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage"] or not(h:InteriorAdjacentTo)'>Expected InteriorAdjacentTo to be 'conditioned space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Thickness) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Thickness</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExposedPerimeter) = 1'>Expected 1 element(s) for xpath: ExposedPerimeter</sch:assert>
      <sch:assert role='ERROR' test='count(h:DepthBelowGrade) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DepthBelowGrade</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerimeterInsulation/h:Layer/h:NominalRValue) = 1'>Expected 1 element(s) for xpath: PerimeterInsulation/Layer/NominalRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerimeterInsulation/h:Layer/h:InsulationDepth) = 1'>Expected 1 element(s) for xpath: PerimeterInsulation/Layer/InsulationDepth</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorHorizontalInsulation/h:Layer/h:NominalRValue) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ExteriorHorizontalInsulation/Layer/NominalRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorHorizontalInsulation/h:Layer/h:InsulationWidth) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ExteriorHorizontalInsulation/Layer/InsulationWidth</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorHorizontalInsulation/h:Layer/h:InsulationDepthBelowGrade) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ExteriorHorizontalInsulation/Layer/InsulationDepthBelowGrade</sch:assert>
      <sch:assert role='ERROR' test='count(h:UnderSlabInsulation/h:Layer/h:NominalRValue) = 1'>Expected 1 element(s) for xpath: UnderSlabInsulation/Layer/NominalRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:UnderSlabInsulation/h:Layer/h:InsulationWidth) + count(h:UnderSlabInsulation/h:Layer/h:InsulationSpansEntireSlab[text()="true"]) = 1'>Expected 1 element(s) for xpath: UnderSlabInsulation/Layer/InsulationWidth | UnderSlabInsulation/Layer/InsulationSpansEntireSlab[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GapInsulationRValue) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/GapInsulationRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CarpetFraction) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CarpetFraction</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CarpetFraction) &gt;= 0 or not(h:extension/h:CarpetFraction)'>Expected extension/CarpetFraction to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CarpetFraction) &lt;= 1 or not(h:extension/h:CarpetFraction)'>Expected extension/CarpetFraction to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CarpetRValue) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CarpetRValue</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:ExposedPerimeter) = 0'>Slab has zero exposed perimeter, this may indicate an input error.</sch:report>
      <sch:report role='WARN' test='number(h:ExposedPerimeter) &gt; 2*number(h:Area)'>Slab exposed perimeter is more than twice the slab area, this may indicate an input error.</sch:report>
      <sch:report role='WARN' test='number(h:Thickness) &lt; 1 and number(h:Thickness) &gt; 0'>Thickness is less than 1 inch; this may indicate incorrect units.</sch:report>
      <sch:report role='WARN' test='number(h:Thickness) &gt; 12'>Thickness is greater than 12 inches; this may indicate incorrect units.</sch:report>
      <sch:report role='WARN' test='number(h:ExteriorHorizontalInsulation/h:Layer/h:NominalRValue) &gt; 0 and number(h:PerimeterInsulation/h:Layer/h:NominalRValue)=0'> There is ExteriorHorizontalInsulation but no PerimeterInsulation, this may indicate an input error.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Window]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window'>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) + count(h:Orientation) &gt;= 1'>Expected 1 or more element(s) for xpath: Azimuth | Orientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:UFactor) + count(h:GlassLayers) &gt;= 1'>Expected 1 or more element(s) for xpath: UFactor | GlassLayers</sch:assert> <!-- See [Window=PhysicalProperties] -->
      <sch:assert role='ERROR' test='count(h:SHGC) + count(h:GlassLayers) &gt;= 1'>Expected 1 or more element(s) for xpath: SHGC | GlassLayers</sch:assert> <!-- See [Window=PhysicalProperties] -->
      <sch:assert role='ERROR' test='h:GlassLayers[text()="single-pane" or text()="double-pane" or text()="triple-pane" or text()="glass block"] or not(h:GlassLayers) or h:UFactor'>Expected GlassLayers to be 'single-pane' or 'double-pane' or 'triple-pane' or 'glass block'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorShading/h:Type) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ExteriorShading/Type</sch:assert>
      <sch:assert role='ERROR' test='h:ExteriorShading/h:Type[text()="external overhangs" or text()="awnings" or text()="solar screens" or text()="solar film" or text()="deciduous tree" or text()="evergreen tree" or text()="building" or text()="other" or text()="not present"] or not(h:ExteriorShading/h:Type)'>Expected ExteriorShading/Type to be 'external overhangs' or 'awnings' or 'solar screens' or 'solar film' or 'deciduous tree' or 'evergreen tree' or 'building' or 'other' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorShading/h:SummerFractionCovered) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ExteriorShading/SummerFractionCovered</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorShading/h:WinterFractionCovered) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ExteriorShading/WinterFractionCovered</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorShading/h:SummerShadingCoefficient) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ExteriorShading/SummerShadingCoefficient</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorShading/h:WinterShadingCoefficient) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ExteriorShading/WinterShadingCoefficient</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorShading/h:Type) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorShading/Type</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorShading/h:Type[text()="light blinds" or text()="medium blinds" or text()="dark blinds" or text()="light shades" or text()="medium shades" or text()="dark shades" or text()="light curtains" or text()="medium curtains" or text()="dark curtains" or text()="other" or text()="not present"] or not(h:InteriorShading/h:Type)'>Expected InteriorShading/Type to be 'light blinds' or 'medium blinds' or 'dark blinds' or 'light shades' or 'medium shades' or 'dark shades' or 'light curtains' or 'medium curtains' or 'dark curtains' or 'other' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorShading/h:BlindsSummerClosedOrOpen) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorShading/BlindsSummerClosedOrOpen</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorShading/h:BlindsSummerClosedOrOpen[text()="closed" or text()="open" or text()="half open"] or not(h:InteriorShading/h:BlindsSummerClosedOrOpen)'>Expected InteriorShading/BlindsSummerClosedOrOpen to be 'closed' or 'open' or 'half open'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorShading/h:BlindsWinterClosedOrOpen) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorShading/BlindsWinterClosedOrOpen</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorShading/h:BlindsWinterClosedOrOpen[text()="closed" or text()="open" or text()="half open"] or not(h:InteriorShading/h:BlindsWinterClosedOrOpen)'>Expected InteriorShading/BlindsWinterClosedOrOpen to be 'closed' or 'open' or 'half open'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorShading/h:SummerFractionCovered) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorShading/SummerFractionCovered</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorShading/h:WinterFractionCovered) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorShading/WinterFractionCovered</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorShading/h:SummerShadingCoefficient) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorShading/SummerShadingCoefficient</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorShading/h:WinterShadingCoefficient) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorShading/WinterShadingCoefficient</sch:assert>
      <sch:assert role='ERROR' test='count(h:InsectScreen) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InsectScreen</sch:assert> <!-- See [WindowInsectScreen] -->
      <sch:assert role='ERROR' test='count(h:StormWindow) &lt;= 1'>Expected 0 or 1 element(s) for xpath: StormWindow</sch:assert> <!-- See [WindowStorm] -->
      <sch:assert role='ERROR' test='count(h:Overhangs) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Overhangs</sch:assert> <!-- See [WindowOverhangs] -->
      <sch:assert role='ERROR' test='count(h:FractionOperable) &lt;= 1'>Expected 0 or 1 element(s) for xpath: FractionOperable</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToWall) = 1'>Expected 1 element(s) for xpath: AttachedToWall</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='h:ExteriorShading/h:Type[text()="external overhangs"] and count(h:Overhangs) &gt; 0'>Exterior shading type is 'external overhangs', but overhangs are explicitly defined; exterior shading type will be ignored.</sch:report>
      <sch:report role='WARN' test='h:ExteriorShading/h:Type[text()="awnings"] and count(h:Overhangs) &gt; 0'>Exterior shading type is 'external overhangs', but overhangs are explicitly defined; exterior shading type will be ignored.</sch:report>
      <sch:report role='WARN' test='h:ExteriorShading/h:Type[text()="building"] and count(../../../h:BuildingSummary/h:Site/h:extension/h:Neighbors/h:NeighborBuilding) &gt; 0'>Exterior shading type is 'building', but neighbor buildings are explicitly defined; exterior shading type will be ignored.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Window=PhysicalProperties]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window[not(h:UFactor) and h:GlassLayers[text()="single-pane" or text()="double-pane" or text()="triple-pane"]]'>
      <sch:assert role='ERROR' test='count(h:FrameType[h:Aluminum | h:Fiberglass | h:Metal | h:Vinyl | h:Wood]) = 1'>Expected 1 element(s) for xpath: FrameType[Aluminum | Fiberglass | Metal | Vinyl | Wood]</sch:assert> <!-- See [Window=MetalFrame] -->
      <sch:assert role='ERROR' test='count(h:GlassType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: GlassType</sch:assert>
      <sch:assert role='ERROR' test='h:GlassType[text()="clear" or text()="low-e" or text()="low-e, high-solar-gain" or text()="low-e, low-solar-gain" or text()="tinted" or text()="tinted/reflective" or text()="reflective"] or not(h:GlassType)'>Expected GlassType to be 'clear' or 'low-e' or 'low-e, high-solar-gain' or 'low-e, low-solar-gain' or 'tinted' or 'tinted/reflective' or 'reflective'</sch:assert>
      <sch:assert role='ERROR' test='count(h:GasFill) &lt;= 1'>Expected 0 or 1 element(s) for xpath: GasFill</sch:assert>
      <sch:assert role='ERROR' test='h:GasFill[text()="air" or text()="argon" or text()="krypton" or text()="xenon" or text()="nitrogen" or text()="other"] or not(h:GasFill)'>Expected GasFill to be 'air' or 'argon' or 'krypton' or 'xenon' or 'nitrogen' or 'other'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Window=MetalFrame]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window/h:FrameType/h:Metal | /h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window/h:FrameType/h:Aluminum'>
      <sch:assert role='ERROR' test='count(h:ThermalBreak) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ThermalBreak</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WindowInsectScreen]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window/h:InsectScreen'>
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="interior" or text()="exterior"] or not(h:Location)'>Expected Location to be 'interior' or 'exterior'</sch:assert>
      <sch:assert role='ERROR' test='count(h:SummerFractionCovered) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SummerFractionCovered</sch:assert>
      <sch:assert role='ERROR' test='count(h:WinterFractionCovered) &lt;= 1'>Expected 0 or 1 element(s) for xpath: WinterFractionCovered</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WindowStorm]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window/h:StormWindow'>
      <sch:assert role='ERROR' test='count(h:GlassType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: GlassType</sch:assert>
      <sch:assert role='ERROR' test='h:GlassType[text()="clear" or text()="low-e"] or not(h:GlassType)'>Expected GlassType to be 'clear' or 'low-e'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WindowOverhangs]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window/h:Overhangs'>
      <sch:assert role='ERROR' test='count(h:Depth) = 1'>Expected 1 element(s) for xpath: Depth</sch:assert> <!-- See [WindowOverhangs=Present] -->
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:Depth) &gt; 72'>Depth is greater than 72 feet; this may indicate incorrect units.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WindowOverhangs=Present]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window/h:Overhangs[number(h:Depth) > 0]'>
      <sch:assert role='ERROR' test='count(h:DistanceToTopOfWindow) = 1'>Expected 1 element(s) for xpath: DistanceToTopOfWindow</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistanceToBottomOfWindow) = 1'>Expected 1 element(s) for xpath: DistanceToBottomOfWindow</sch:assert>
      <sch:assert role='ERROR' test='number(h:DistanceToBottomOfWindow) &gt; number(h:DistanceToTopOfWindow) or not(h:DistanceToBottomOfWindow) or not(h:DistanceToTopOfWindow)'>Expected DistanceToBottomOfWindow to be greater than DistanceToTopOfWindow</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:DistanceToTopOfWindow) &gt; 12'>DistanceToTopOfWindow is greater than 12 feet; this may indicate incorrect units.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Skylight]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight'>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) + count(h:Orientation) &gt;= 1'>Expected 1 or more element(s) for xpath: Azimuth | Orientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:UFactor) + count(h:GlassLayers) &gt;= 1'>Expected 1 or more element(s) for xpath: UFactor | GlassLayers</sch:assert> <!-- See [Skylight=PhysicalProperties] -->
      <sch:assert role='ERROR' test='count(h:SHGC) + count(h:GlassLayers) &gt;= 1'>Expected 1 or more element(s) for xpath: SHGC | GlassLayers</sch:assert> <!-- See [Skylight=PhysicalProperties] -->
      <sch:assert role='ERROR' test='h:GlassLayers[text()="single-pane" or text()="double-pane" or text()="triple-pane" or text()="glass block"] or not(h:GlassLayers) or h:UFactor'>Expected GlassLayers to be 'single-pane' or 'double-pane' or 'triple-pane' or 'glass block'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorShading/h:SummerShadingCoefficient) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ExteriorShading/SummerShadingCoefficient</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorShading/h:WinterShadingCoefficient) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ExteriorShading/WinterShadingCoefficient</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorShading/h:SummerShadingCoefficient) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorShading/SummerShadingCoefficient</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorShading/h:WinterShadingCoefficient) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorShading/WinterShadingCoefficient</sch:assert>
      <sch:assert role='ERROR' test='count(h:StormWindow) &lt;= 1'>Expected 0 or 1 element(s) for xpath: StormWindow</sch:assert> <!-- See [SkylightStorm] -->
      <sch:assert role='ERROR' test='count(h:AttachedToRoof) = 1'>Expected 1 element(s) for xpath: AttachedToRoof</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToFloor) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AttachedToFloor</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:Curb) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Curb</sch:assert> <!-- See [SkylightCurb] -->
      <sch:assert role='ERROR' test='count(h:extension/h:Shaft) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Shaft</sch:assert> <!-- See [SkylightShaft] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Skylight=PhysicalProperties]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight[not(h:UFactor) and h:GlassLayers[text()="single-pane" or text()="double-pane" or text()="triple-pane"]]'>
      <sch:assert role='ERROR' test='count(h:FrameType[h:Aluminum | h:Fiberglass | h:Metal | h:Vinyl | h:Wood]) = 1'>Expected 1 element(s) for xpath: FrameType[Aluminum | Fiberglass | Metal | Vinyl | Wood]</sch:assert> <!-- See [Skylight=MetalFrame] -->
      <sch:assert role='ERROR' test='count(h:GlassType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: GlassType</sch:assert>
      <sch:assert role='ERROR' test='h:GlassType[text()="clear" or text()="low-e" or text()="low-e, high-solar-gain" or text()="low-e, low-solar-gain" or text()="tinted" or text()="tinted/reflective" or text()="reflective"] or not(h:GlassType)'>Expected GlassType to be 'clear' or 'low-e' or 'low-e, high-solar-gain' or 'low-e, low-solar-gain' or 'tinted' or 'tinted/reflective' or 'reflective'</sch:assert>
      <sch:assert role='ERROR' test='count(h:GasFill) &lt;= 1'>Expected 0 or 1 element(s) for xpath: GasFill</sch:assert>
      <sch:assert role='ERROR' test='h:GasFill[text()="air" or text()="argon" or text()="krypton" or text()="xenon" or text()="nitrogen" or text()="other"] or not(h:GasFill)'>Expected GasFill to be 'air' or 'argon' or 'krypton' or 'xenon' or 'nitrogen' or 'other'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Skylight=MetalFrame]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight/h:FrameType/h:Metal | /h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight/h:FrameType/h:Aluminum'>
      <sch:assert role='ERROR' test='count(h:ThermalBreak) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ThermalBreak</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SkylightStorm]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight/h:StormWindow'>
      <sch:assert role='ERROR' test='count(h:GlassType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: GlassType</sch:assert>
      <sch:assert role='ERROR' test='h:GlassType[text()="clear" or text()="low-e"] or not(h:GlassType)'>Expected GlassType to be 'clear' or 'low-e'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SkylightCurb]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight/h:extension/h:Curb'>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='number(h:Area) &gt; 0 or not(h:Area)'>Expected Area to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: AssemblyEffectiveRValue</sch:assert>
      <sch:assert role='ERROR' test='number(h:AssemblyEffectiveRValue) &gt; 0 or not(h:AssemblyEffectiveRValue)'>Expected AssemblyEffectiveRValue to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SkylightShaft]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight/h:extension/h:Shaft'>
      <sch:assert role='ERROR' test='count(../../h:AttachedToFloor) = 1'>Expected 1 element(s) for xpath: ../../AttachedToFloor</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='number(h:Area) &gt; 0 or not(h:Area)'>Expected Area to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:AssemblyEffectiveRValue) = 1'>Expected 1 element(s) for xpath: AssemblyEffectiveRValue</sch:assert>
      <sch:assert role='ERROR' test='number(h:AssemblyEffectiveRValue) &gt; 0 or not(h:AssemblyEffectiveRValue)'>Expected AssemblyEffectiveRValue to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Door]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Doors/h:Door'>
      <sch:assert role='ERROR' test='count(h:AttachedToWall) = 1'>Expected 1 element(s) for xpath: AttachedToWall</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected 1 element(s) for xpath: Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) + count(h:Orientation) &gt;= 0'>Expected 0 or more element(s) for xpath: Azimuth | Orientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:RValue) = 1'>Expected 1 element(s) for xpath: RValue</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PartitionWallMass]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:extension/h:PartitionWallMass'>
      <sch:assert role='ERROR' test='count(h:AreaFraction) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AreaFraction</sch:assert>
      <sch:assert role='ERROR' test='number(h:AreaFraction) &gt;= 0 or not(h:AreaFraction)'>Expected AreaFraction to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorFinish/h:Type) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorFinish/Type</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorFinish/h:Type[text()="gypsum board" or text()="gypsum composite board" or text()="plaster" or text()="wood" or text()="not present"] or not(h:InteriorFinish/h:Type)'>Expected InteriorFinish/Type to be 'gypsum board' or 'gypsum composite board' or 'plaster' or 'wood' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorFinish/h:Thickness) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InteriorFinish/Thickness</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FurnitureMass]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:extension/h:FurnitureMass'>
      <sch:assert role='ERROR' test='count(h:AreaFraction) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AreaFraction</sch:assert>
      <sch:assert role='ERROR' test='number(h:AreaFraction) &gt;= 0 or not(h:AreaFraction)'>Expected AreaFraction to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:Type) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Type</sch:assert>
      <sch:assert role='ERROR' test='h:Type[text()="light-weight" or text()="heavy-weight"] or not(h:Type)'>Expected Type to be 'light-weight' or 'heavy-weight'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem'>
      <sch:assert role='ERROR' test='count(h:AttachedToZone) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AttachedToZone</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACControl) = 1'>Expected 1 element(s) for xpath: ../../HVACControl</sch:assert> <!-- See [HVACControl=Heating] -->
      <sch:assert role='ERROR' test='count(h:HeatingSystemType[h:ElectricResistance | h:Furnace | h:WallFurnace | h:FloorFurnace | h:Boiler | h:Stove | h:SpaceHeater | h:Fireplace]) = 1'>Expected 1 element(s) for xpath: HeatingSystemType[ElectricResistance | Furnace | WallFurnace | FloorFurnace | Boiler | Stove | SpaceHeater | Fireplace]</sch:assert> <!-- See [HeatingSystemType=Resistance] or [HeatingSystemType=Furnace] or [HeatingSystemType=WallFurnace] or [HeatingSystemType=FloorFurnace] or [HeatingSystemType=InUnitBoiler] or [HeatingSystemType=SharedBoiler] or [HeatingSystemType=Stove] or [HeatingSystemType=SpaceHeater] or [HeatingSystemType=Fireplace] -->
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingAutosizingFactor) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingAutosizingFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingAutosizingFactor) &gt; 0 or not (h:extension/h:HeatingAutosizingFactor)'>HeatingAutosizingFactor should be greater than 0.0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingAutosizingLimit) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingAutosizingLimit</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingAutosizingLimit) &gt; 0 or not (h:extension/h:HeatingAutosizingLimit)'>HeatingAutosizingLimit should be greater than 0.0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=Resistance]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:ElectricResistance]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemType/h:ElectricResistance/h:ElectricDistribution) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingSystemType/ElectricResistance/ElectricDistribution</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemType/h:ElectricResistance/h:ElectricDistribution[text()="baseboard" or text()="radiant floor" or text()="radiant ceiling"] or not(h:HeatingSystemType/h:ElectricResistance/h:ElectricDistribution)'>Expected HeatingSystemType/ElectricResistance/ElectricDistribution to be 'baseboard' or 'radiant floor' or 'radiant ceiling'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="Percent"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert> <!-- See [HeatingSystem=HeatPumpBackup] -->
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt; 0.95'>Percent efficiency should typically be greater than or equal to 0.95.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt;= 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=Furnace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Furnace]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity" or text()="gravity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity" or text()="gravity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:UnitLocation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UnitLocation</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemType/h:Furnace/h:PilotLight) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingSystemType/Furnace/PilotLight</sch:assert> <!-- See [HeatingSystem=HasPilotLight] -->
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert> <!-- See [HeatingSystem=HeatPumpBackup] -->
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:HeatingDesignAirflowCFM)'>Expected extension/HeatingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/AirflowDefectRatio</sch:assert> <!-- See [AirflowDefectRatio] -->
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt; 0.5'>AFUE should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt;= 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=WallFurnace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:WallFurnace]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemType/h:WallFurnace/h:PilotLight) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingSystemType/WallFurnace/PilotLight</sch:assert> <!-- See [HeatingSystem=HasPilotLight] -->
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert> <!-- See [HeatingSystem=HeatPumpBackup] -->
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt; 0.5'>AFUE should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt;= 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=FloorFurnace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:FloorFurnace]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemType/h:FloorFurnace/h:PilotLight) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingSystemType/FloorFurnace/PilotLight</sch:assert> <!-- See [HeatingSystem=HasPilotLight] -->
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert> <!-- See [HeatingSystem=HeatPumpBackup] -->
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt; 0.5'>AFUE should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt;= 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=InUnitBoiler]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Boiler and (not(h:IsSharedSystem) or h:IsSharedSystem="false")]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/HydronicDistribution/HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:UnitLocation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UnitLocation</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemType/h:Boiler/h:PilotLight) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingSystemType/Boiler/PilotLight</sch:assert> <!-- See [HeatingSystem=HasPilotLight] -->
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert> <!-- See [HeatingSystem=HeatPumpBackup] -->
      <sch:assert role='ERROR' test='count(h:ElectricAuxiliaryEnergy) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ElectricAuxiliaryEnergy</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt;= 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt; 0.5'>AFUE should typically be greater than or equal to 0.5.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=SharedBoiler]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Boiler and h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling" or text()="water loop"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="fan coil"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/HydronicDistribution/HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling" or text()="water loop"] | ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="fan coil"]</sch:assert> <!-- See [HVACDistribution] or [HeatingSystemType=SharedBoilerWthFanCoil] or [HeatingSystemType=SharedBoilerWithWLHP] -->
      <sch:assert role='ERROR' test='count(h:UnitLocation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UnitLocation</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected 1 element(s) for xpath: NumberofUnitsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofUnitsServed) &gt; 1 or not(h:NumberofUnitsServed)'>Expected NumberofUnitsServed to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemType/h:Boiler/h:PilotLight) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingSystemType/Boiler/PilotLight</sch:assert> <!-- See [HeatingSystem=HasPilotLight] -->
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert> <!-- See [HeatingSystem=HeatPumpBackup] -->
      <sch:assert role='ERROR' test='count(h:ElectricAuxiliaryEnergy) + count(h:extension/h:SharedLoopWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ElectricAuxiliaryEnergy | extension/SharedLoopWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopWatts) &gt;= 0 or not(h:extension/h:SharedLoopWatts)'>Expected extension/SharedLoopWatts to be greater than or equal to 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt; 0.5'>AFUE should typically be greater than or equal to 0.5.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=SharedBoilerWthFanCoil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Boiler and h:IsSharedSystem="true" and ../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="fan coil"]]'>
      <sch:assert role='ERROR' test='count(h:ElectricAuxiliaryEnergy) + count(h:extension/h:FanCoilWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ElectricAuxiliaryEnergy | extension/FanCoilWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanCoilWatts) &gt;= 0 or not(h:extension/h:FanCoilWatts)'>Expected extension/FanCoilWatts to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=SharedBoilerWithWLHP]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Boiler and h:IsSharedSystem="true" and ../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="water loop"]]'>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../HeatPump[HeatPumpType="water-loop-to-air"]/HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../HeatPump[HeatPumpType="water-loop-to-air"]/AnnualHeatingEfficiency[Units="COP"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=Stove]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Stove]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemType/h:Stove/h:PilotLight) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingSystemType/Stove/PilotLight</sch:assert> <!-- See [HeatingSystem=HasPilotLight] -->
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="Percent"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert> <!-- See [HeatingSystem=HeatPumpBackup] -->
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt; 0.5'>Percent efficiency should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt;= 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=SpaceHeater]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:SpaceHeater]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="Percent"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert> <!-- See [HeatingSystem=HeatPumpBackup] -->
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt; 0.5'>Percent efficiency should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt;= 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=Fireplace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Fireplace]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected 0 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemType/h:Fireplace/h:PilotLight) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingSystemType/Fireplace/PilotLight</sch:assert> <!-- See [HeatingSystem=HasPilotLight] -->
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected 1 element(s) for xpath: HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="Percent"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert> <!-- See [HeatingSystem=HeatPumpBackup] -->
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt;= 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystem=HasPilotLight]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem/h:HeatingSystemType/*[h:PilotLight="true"]'>
      <sch:assert role='ERROR' test='count(../../h:HeatingSystemFuel[text()!="electricity"]) = 1'>Expected 1 element(s) for xpath: ../../HeatingSystemFuel[text()!="electricity"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PilotLightBtuh) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/PilotLightBtuh</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem'>
      <sch:assert role='ERROR' test='count(h:AttachedToZone) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AttachedToZone</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACControl) = 1'>Expected 1 element(s) for xpath: ../../HVACControl</sch:assert> <!-- See [HVACControl=Cooling] -->
      <sch:assert role='ERROR' test='count(h:CoolingSystemType) = 1'>Expected 1 element(s) for xpath: CoolingSystemType</sch:assert> <!-- See [CoolingSystemType=CentralAC] or [CoolingSystemType=PTACorRoomAC] or [CoolingSystemType=EvapCooler] or [CoolingSystemType=MiniSplitAC] or [CoolingSystemType=SharedChiller] or [CoolingSystemType=SharedCoolingTowerWLHP] -->
      <sch:assert role='ERROR' test='h:CoolingSystemType[text()="central air conditioner" or text()="room air conditioner" or text()="evaporative cooler" or text()="mini-split" or text()="chiller" or text()="cooling tower" or text()="packaged terminal air conditioner"] or not(h:CoolingSystemType)'>Expected CoolingSystemType to be 'central air conditioner' or 'room air conditioner' or 'evaporative cooler' or 'mini-split' or 'chiller' or 'cooling tower' or 'packaged terminal air conditioner'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingAutosizingFactor) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingAutosizingFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingAutosizingFactor) &gt; 0 or not (h:extension/h:CoolingAutosizingFactor)'>CoolingAutosizingFactor should be greater than 0.0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingAutosizingLimit) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingAutosizingLimit</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingAutosizingLimit) &gt; 0 or not (h:extension/h:CoolingAutosizingLimit)'>CoolingAutosizingLimit should be greater than 0.0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=CentralAC]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="central air conditioner"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:UnitLocation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UnitLocation</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSystemFuel) = 1'>Expected 1 element(s) for xpath: CoolingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"] or not(h:CoolingSystemFuel)'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorType) = 1'>Expected 1 element(s) for xpath: CompressorType</sch:assert>
      <sch:assert role='ERROR' test='h:CompressorType[text()="single stage" or text()="two stage" or text()="variable speed"] or not(h:CompressorType)'>Expected CompressorType to be 'single stage' or 'two stage' or 'variable speed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="SEER" or h:Units="SEER2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="SEER" or Units="SEER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="EER2"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER" or Units="EER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value)'>Expected EER to be less than SEER.</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt;= number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value)'>Expected EER2 to be less than or equal to SEER2.</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingDetailedPerformanceData) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CoolingDetailedPerformanceData</sch:assert> <!-- See [CoolingDetailedPerformanceData]-->
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected 0 element(s) for xpath: IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/AirflowDefectRatio</sch:assert> <!-- See [AirflowDefectRatio] -->
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &gt;= -0.9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &lt;= 9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CrankcaseHeaterPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CrankcaseHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CrankcaseHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:CrankcaseHeaterPowerWatts)'>Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:EquipmentType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/EquipmentType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:EquipmentType[text()="split system" or text()="packaged system" or text()="small duct high velocity system" or text()="space constrained system"] or not(h:extension/h:EquipmentType)'>Expected extension/EquipmentType to be 'split system', 'packaged system', 'small duct high velocity system', or 'space constrained system'</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) &lt; 8'>SEER should typically be greater than or equal to 8.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) &lt; 7.6'>SEER2 should typically be greater than or equal to 7.6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; 6'>EER should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt; 5.7'>EER2 should typically be greater than or equal to 5.7.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt;= 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=PTACorRoomAC]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="room air conditioner" or h:CoolingSystemType="packaged terminal air conditioner"]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSystemFuel) = 1'>Expected 1 element(s) for xpath: CoolingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"] or not(h:CoolingSystemFuel)'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="CEER"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER" or Units="CEER"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:IntegratedHeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"] or not(h:IntegratedHeatingSystemFuel)'>Expected IntegratedHeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CrankcaseHeaterPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CrankcaseHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CrankcaseHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:CrankcaseHeaterPowerWatts)'>Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.0.</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; 6'>EER should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="CEER"]/h:Value) &lt; 5.9'>CEER should typically be greater than or equal to 5.9.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt;= 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='count(h:extension/h:FanPowerWattsPerCFM) + count(h:extension/h:FanMotorType) &gt; 0'>Fan power watts per cfm or fan motor type is not used for simulation of this HVAC system type.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=EvapCooler]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="evaporative cooler"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 0'>Expected 0 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:DistributionSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSystemFuel) = 1'>Expected 1 element(s) for xpath: CoolingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"] or not(h:CoolingSystemFuel)'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected 0 element(s) for xpath: IntegratedHeatingSystemFuel</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt;= 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='count(h:extension/h:FanPowerWattsPerCFM) + count(h:extension/h:FanMotorType) &gt; 0'>Fan power watts per cfm or fan motor type is not used for simulation of this HVAC system type.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=MiniSplitAC]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="mini-split"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 0'>Expected 0 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:UnitLocation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UnitLocation</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSystemFuel) = 1'>Expected 1 element(s) for xpath: CoolingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"] or not(h:CoolingSystemFuel)'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorType) = 1'>Expected 1 element(s) for xpath: CompressorType</sch:assert>
      <sch:assert role='ERROR' test='h:CompressorType[text()="variable speed"] or not(h:CompressorType)'>Expected CompressorType to be 'variable speed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="SEER" or h:Units="SEER2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="SEER" or Units="SEER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="EER2"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER" or Units="EER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value)'>Expected EER to be less than SEER.</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt;= number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value)'>Expected EER2 to be less than or equal to SEER2.</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingDetailedPerformanceData) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CoolingDetailedPerformanceData</sch:assert> <!-- See [CoolingDetailedPerformanceData]-->
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected 0 element(s) for xpath: IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/AirflowDefectRatio</sch:assert> <!-- See [AirflowDefectRatio] -->
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &gt;= -0.9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &lt;= 9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CrankcaseHeaterPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CrankcaseHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CrankcaseHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:CrankcaseHeaterPowerWatts)'>Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.0.</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) &lt; 8'>SEER should typically be greater than or equal to 8.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) &lt; 7.6'>SEER2 should typically be greater than or equal to 7.6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; 6'>EER should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt; 5.7'>EER2 should typically be greater than or equal to 5.7.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt;= 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=SharedChiller]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="chiller"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling" or text()="water loop"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="fan coil"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/HydronicDistribution/HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling" or text()="water loop"] | ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="fan coil"]</sch:assert> <!-- See [HVACDistribution] or [CoolingSystemType=SharedChillerWithFanCoil] or [CoolingSystemType=SharedChillerWithWLHP] -->
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem[text()="true"]) = 1'>Expected 1 element(s) for xpath: IsSharedSystem[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected 1 element(s) for xpath: NumberofUnitsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofUnitsServed) &gt; 1 or not(h:NumberofUnitsServed)'>Expected NumberofUnitsServed to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSystemFuel) = 1'>Expected 1 element(s) for xpath: CoolingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"] or not(h:CoolingSystemFuel)'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="kW/ton"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="kW/ton"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected 0 element(s) for xpath: IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopWatts) = 1'>Expected 1 element(s) for xpath: extension/SharedLoopWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopWatts) &gt;= 0 or not(h:extension/h:SharedLoopWatts)'>Expected extension/SharedLoopWatts to be greater than or equal to 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt;= 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=SharedChillerWithFanCoil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="chiller" and ../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="fan coil"]]'>
      <sch:assert role='ERROR' test='count(h:extension/h:FanCoilWatts) = 1'>Expected 1 element(s) for xpath: extension/FanCoilWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanCoilWatts) &gt;= 0 or not(h:extension/h:FanCoilWatts)'>Expected extension/FanCoilWatts to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=SharedChillerWithWLHP]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="chiller" and ../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="water loop"]]'>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: ../HeatPump[HeatPumpType="water-loop-to-air"]/CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../HeatPump[HeatPumpType="water-loop-to-air"]/AnnualCoolingEfficiency[Units="EER"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=SharedCoolingTowerWLHP]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="cooling tower"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="water loop"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/HydronicDistribution/HydronicDistributionType[text()="water loop"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem[text()="true"]) = 1'>Expected 1 element(s) for xpath: IsSharedSystem[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected 1 element(s) for xpath: NumberofUnitsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofUnitsServed) &gt; 1 or not(h:NumberofUnitsServed)'>Expected NumberofUnitsServed to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSystemFuel) = 1'>Expected 1 element(s) for xpath: CoolingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"] or not(h:CoolingSystemFuel)'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected 0 element(s) for xpath: IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopWatts) = 1'>Expected 1 element(s) for xpath: extension/SharedLoopWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopWatts) &gt;= 0 or not(h:extension/h:SharedLoopWatts)'>Expected extension/SharedLoopWatts to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:CoolingCapacity) = 1'>Expected 1 element(s) for xpath: ../HeatPump[HeatPumpType="water-loop-to-air"]/CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../HeatPump[HeatPumpType="water-loop-to-air"]/AnnualCoolingEfficiency[Units="EER"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystem=HasIntegratedHeatingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:IntegratedHeatingSystemFuel]'>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: IntegratedHeatingSystemFractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IntegratedHeatingSystemCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemAnnualEfficiency[h:Units="Percent"]) = 1'>Expected 1 element(s) for xpath: IntegratedHeatingSystemAnnualEfficiency[Units="Percent"]</sch:assert>
      <sch:assert role='ERROR' test='number(h:IntegratedHeatingSystemAnnualEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:IntegratedHeatingSystemAnnualEfficiency[h:Units="Percent"]/h:Value)'>Expected IntegratedHeatingSystemAnnualEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:IntegratedHeatingSystemAnnualEfficiency[h:Units="Percent"]/h:Value) &lt; 0.5'>Percent efficiency should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:IntegratedHeatingSystemCapacity) &lt;= 1000 and number(h:IntegratedHeatingSystemCapacity) &gt; 0 and h:IntegratedHeatingSystemCapacity'>Integrated Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPump]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump'>
      <sch:assert role='ERROR' test='count(h:AttachedToZone) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AttachedToZone</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACControl) = 1'>Expected 1 element(s) for xpath: ../../HVACControl</sch:assert> <!-- See [HVACControl=Heating] and/or [HVACControl=Cooling] -->
      <sch:assert role='ERROR' test='count(h:HeatPumpType) = 1'>Expected 1 element(s) for xpath: HeatPumpType</sch:assert> <!-- See [HeatPumpType=AirSource] or [HeatPumpType=MiniSplit] or [HeatPumpType=GroundSource] or [HeatPumpType=WaterLoop] or [HeatPumpType=PTHPorRoomACwithReverseCycle] -->
      <sch:assert role='ERROR' test='h:HeatPumpType[text()="air-to-air" or text()="mini-split" or text()="ground-to-air" or text()="water-loop-to-air" or text()="packaged terminal heat pump" or text()="room air conditioner with reverse cycle"] or not(h:HeatPumpType)'>Expected HeatPumpType to be 'air-to-air' or 'mini-split' or 'ground-to-air' or 'water-loop-to-air' or 'packaged terminal heat pump' or 'room air conditioner with reverse cycle'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingAutosizingFactor) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingAutosizingFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingAutosizingFactor) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingAutosizingFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingAutosizingFactor) &gt; 0 or not (h:extension/h:CoolingAutosizingFactor)'>CoolingAutosizingFactor should be greater than 0.0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingAutosizingFactor) &gt; 0 or not (h:extension/h:HeatingAutosizingFactor)'>HeatingAutosizingFactor should be greater than 0.0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingAutosizingLimit) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingAutosizingLimit</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingAutosizingLimit) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingAutosizingLimit</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingAutosizingLimit) &gt; 0 or not (h:extension/h:CoolingAutosizingLimit)'>CoolingAutosizingLimit should be greater than 0.0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingAutosizingLimit) &gt; 0 or not (h:extension/h:HeatingAutosizingLimit)'>HeatingAutosizingLimit should be greater than 0.0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=AirSource]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="air-to-air"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:UnitLocation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UnitLocation</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatPumpFuel) = 1'>Expected 1 element(s) for xpath: HeatPumpFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"] or not(h:HeatPumpFuel)'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <!-- Moved/deprecated HeatingCapacityRetention input; see https://github.com/NREL/OpenStudio-HPXML/pull/1931 -->
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingCapacityRetention) = 0'>extension/HeatingCapacityRetention has been replaced by extension/HeatingCapacityFraction17F</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingCapacityFraction17F) + count(h:HeatingCapacity17F) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingCapacityFraction17F | HeatingCapacity17F</sch:assert> <!-- See [HeatPumpCapacityRetention] -->
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingCapacityFraction17F) &lt; 1 or not(h:extension/h:HeatingCapacityFraction17F)'>Expected extension/HeatingCapacityFraction17F to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingCapacityFraction17F) &gt;= 0 or not(h:extension/h:HeatingCapacityFraction17F)'>Expected extension/HeatingCapacityFraction17F to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatingCapacity17F) &lt;= number(h:HeatingCapacity) or not(h:HeatingCapacity17F) or not(h:HeatingCapacity)'>Expected HeatingCapacity17F to be less than or equal to HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity17F) &lt;= count(h:HeatingCapacity)'>Expected HeatingCapacity when HeatingCapacity17F is provided</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorType) = 1'>Expected 1 element(s) for xpath: CompressorType</sch:assert>
      <sch:assert role='ERROR' test='h:CompressorType[text()="single stage" or text()="two stage" or text()="variable speed"] or not(h:CompressorType)'>Expected CompressorType to be 'single stage' or 'two stage' or 'variable speed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorLockoutTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CompressorLockoutTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupType</sch:assert> <!-- See [HeatPumpBackup] or [HeatPumpBackup=Integrated] or [HeatPumpBackup=Separate] -->
      <sch:assert role='ERROR' test='h:BackupType[text()="integrated" or text()="separate"] or not(h:BackupType)'>Expected BackupType to be 'integrated' or 'separate'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="SEER" or h:Units="SEER2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="SEER" or Units="SEER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="EER2"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER" or Units="EER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value)'>Expected EER to be less than SEER.</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt;= number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value)'>Expected EER2 to be less than or equal to SEER2.</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="HSPF" or h:Units="HSPF2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="HSPF" or Units="HSPF2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingDetailedPerformanceData) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CoolingDetailedPerformanceData</sch:assert> <!-- See [CoolingDetailedPerformanceData] -->
      <sch:assert role='ERROR' test='count(h:HeatingDetailedPerformanceData) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingDetailedPerformanceData</sch:assert> <!-- See [HeatingDetailedPerformanceData] -->
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:HeatingDesignAirflowCFM)'>Expected extension/HeatingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/AirflowDefectRatio</sch:assert> <!-- See [AirflowDefectRatio] -->
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &gt;= -0.9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &lt;= 9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CrankcaseHeaterPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CrankcaseHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CrankcaseHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:CrankcaseHeaterPowerWatts)'>Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PanHeaterPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/PanHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:PanHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:PanHeaterPowerWatts)'>Expected extension/PanHeaterPowerWatts to be greater than or equal to 0.0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PanHeaterControlType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/PanHeaterControlType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:PanHeaterControlType[text()="continuous" or text()="heat pump mode" or text()="defrost mode"] or not(h:extension/h:PanHeaterControlType)'>Expected extension/PanHeaterControlType to be 'continuous' or 'heat pump mode' or 'defrost mode'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingActiveDuringDefrost) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/BackupHeatingActiveDuringDefrost</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:BackupHeatingActiveDuringDefrost[text()="true" or text()="false"] or not(h:extension/h:BackupHeatingActiveDuringDefrost)'>Expected extension/BackupHeatingActiveDuringDefrost to be 'true' or 'false'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:EquipmentType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/EquipmentType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:EquipmentType[text()="split system" or text()="packaged system" or text()="small duct high velocity system" or text()="space constrained system"] or not(h:extension/h:EquipmentType)'>Expected extension/EquipmentType to be 'split system', 'packaged system', 'small duct high velocity system', or 'space constrained system'</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) &lt; 8'>SEER should typically be greater than or equal to 8.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) &lt; 7.6'>SEER2 should typically be greater than or equal to 7.6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; 6'>EER should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt; 5.7'>EER2 should typically be greater than or equal to 5.7.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="HSPF"]/h:Value) &lt; 6'>HSPF should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="HSPF2"]/h:Value) &lt; 5.1'>HSPF2 should typically be greater than or equal to 5.1.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt;= 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt;= 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=MiniSplit]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="mini-split"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 0'>Expected 0 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:UnitLocation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UnitLocation</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatPumpFuel) = 1'>Expected 1 element(s) for xpath: HeatPumpFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"] or not(h:HeatPumpFuel)'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <!-- Moved/deprecated HeatingCapacityRetention input; see https://github.com/NREL/OpenStudio-HPXML/pull/1931 -->
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingCapacityRetention) = 0'>extension/HeatingCapacityRetention has been replaced by extension/HeatingCapacityFraction17F</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingCapacityFraction17F) + count(h:HeatingCapacity17F) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingCapacityFraction17F | HeatingCapacity17F</sch:assert> <!-- See [HeatPumpCapacityRetention] -->
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingCapacityFraction17F) &lt; 1 or not(h:extension/h:HeatingCapacityFraction17F)'>Expected extension/HeatingCapacityFraction17F to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingCapacityFraction17F) &gt;= 0 or not(h:extension/h:HeatingCapacityFraction17F)'>Expected extension/HeatingCapacityFraction17F to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatingCapacity17F) &lt;= number(h:HeatingCapacity) or not(h:HeatingCapacity17F) or not(h:HeatingCapacity)'>Expected HeatingCapacity17F to be less than or equal to HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity17F) &lt;= count(h:HeatingCapacity)'>Expected HeatingCapacity when HeatingCapacity17F is provided</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorType) = 1'>Expected 1 element(s) for xpath: CompressorType</sch:assert>
      <sch:assert role='ERROR' test='h:CompressorType[text()="variable speed"] or not(h:CompressorType)'>Expected CompressorType to be 'variable speed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorLockoutTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CompressorLockoutTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupType</sch:assert> <!-- See [HeatPumpBackup] or [HeatPumpBackup=Integrated] or [HeatPumpBackup=Separate] -->
      <sch:assert role='ERROR' test='h:BackupType[text()="integrated" or text()="separate"] or not(h:BackupType)'>Expected BackupType to be 'integrated' or 'separate'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="SEER" or h:Units="SEER2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="SEER" or Units="SEER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="EER2"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER" or Units="EER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value)'>Expected EER to be less than SEER.</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt;= number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value)'>Expected EER2 to be less than or equal to SEER2.</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="HSPF" or h:Units="HSPF2"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="HSPF" or Units="HSPF2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingDetailedPerformanceData) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CoolingDetailedPerformanceData</sch:assert> <!-- See [CoolingDetailedPerformanceData] -->
      <sch:assert role='ERROR' test='count(h:HeatingDetailedPerformanceData) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingDetailedPerformanceData</sch:assert> <!-- See [HeatingDetailedPerformanceData] -->
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:HeatingDesignAirflowCFM)'>Expected extension/HeatingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/AirflowDefectRatio</sch:assert> <!-- See [AirflowDefectRatio] -->
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &gt;= -0.9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &lt;= 9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CrankcaseHeaterPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CrankcaseHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CrankcaseHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:CrankcaseHeaterPowerWatts)'>Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PanHeaterPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/PanHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:PanHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:PanHeaterPowerWatts)'>Expected extension/PanHeaterPowerWatts to be greater than or equal to 0.0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PanHeaterControlType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/PanHeaterControlType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:PanHeaterControlType[text()="continuous" or text()="defrost mode"] or not(h:extension/h:PanHeaterControlType)'>Expected extension/PanHeaterControlType to be 'continuous' or 'defrost mode'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingActiveDuringDefrost) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/BackupHeatingActiveDuringDefrost</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:BackupHeatingActiveDuringDefrost[text()="true" or text()="false"] or not(h:extension/h:BackupHeatingActiveDuringDefrost)'>Expected extension/BackupHeatingActiveDuringDefrost to be 'true' or 'false'</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) &lt; 8'>SEER should typically be greater than or equal to 8.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) &lt; 7.6'>SEER2 should typically be greater than or equal to 7.6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="HSPF"]/h:Value) &lt; 6'>HSPF should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="HSPF2"]/h:Value) &lt; 5.1'>HSPF2 should typically be greater than or equal to 5.1.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt;= 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt;= 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=GroundSource]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="ground-to-air"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(h:UnitLocation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UnitLocation</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [HeatPumpType=GroundSourceWithSharedLoop] -->
      <sch:assert role='ERROR' test='count(h:HeatPumpFuel) = 1'>Expected 1 element(s) for xpath: HeatPumpFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"] or not(h:HeatPumpFuel)'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorType) = 1'>Expected 1 element(s) for xpath: CompressorType</sch:assert>
      <sch:assert role='ERROR' test='h:CompressorType[text()="single stage" or text()="two stage" or text()="variable speed"] or not(h:CompressorType)'>Expected CompressorType to be 'single stage' or 'two stage' or 'variable speed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupType</sch:assert> <!-- See [HeatPumpBackup] or [HeatPumpBackup=Integrated] or [HeatPumpBackup=Separate] -->
      <sch:assert role='ERROR' test='h:BackupType[text()="integrated" or text()="separate"] or not(h:BackupType)'>Expected BackupType to be 'integrated' or 'separate'</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupHeatingSwitchoverTemperature) = 0'>Expected 0 element(s) for xpath: BackupHeatingSwitchoverTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="COP"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToGeothermalLoop) &lt;= 1'>Expected 0 or 1 element(s) for xpath: AttachedToGeothermalLoop</sch:assert> <!-- See [GeothermalLoop] -->
      <sch:assert role='ERROR' test='count(h:extension/h:PumpPowerWattsPerTon) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/PumpPowerWattsPerTon</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:PumpPowerWattsPerTon) &gt;= 0 or not(h:extension/h:PumpPowerWattsPerTon)'>Expected extension/PumpPowerWattsPerTon to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:HeatingDesignAirflowCFM)'>Expected extension/HeatingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/AirflowDefectRatio</sch:assert> <!-- See [AirflowDefectRatio] -->
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &gt;= -0.9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &lt;= 9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be less than or equal to 9</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; 6'>EER should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) &lt; 2'>COP should typically be greater than or equal to 2.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt;= 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt;= 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=GroundSourceWithSharedLoop]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="ground-to-air" and h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected 1 element(s) for xpath: NumberofUnitsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofUnitsServed) &gt; 1 or not(h:NumberofUnitsServed)'>Expected NumberofUnitsServed to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopWatts) = 1'>Expected 1 element(s) for xpath: extension/SharedLoopWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopWatts) &gt;= 0 or not(h:extension/h:SharedLoopWatts)'>Expected extension/SharedLoopWatts to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=WaterLoop]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="water-loop-to-air"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType[text()="regular velocity"] | ../../HVACDistribution/DistributionSystemType/Other[text()="DSE"]</sch:assert> <!-- See [HVACDistribution] -->
      <sch:assert role='ERROR' test='count(../h:HeatingSystem[h:HeatingSystemType/h:Boiler and h:IsSharedSystem="true"]) + count(../h:CoolingSystem[(h:CoolingSystemType="chiller" or h:CoolingSystemType="cooling tower") and h:IsSharedSystem="true"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../HeatingSystem[HeatingSystemType/Boiler and IsSharedSystem="true"] | ../CoolingSystem[(CoolingSystemType="chiller" or CoolingSystemType="cooling tower") and IsSharedSystem="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="water loop"]) &gt;= 1'>Expected 1 or more element(s) for xpath: ../../HVACDistribution/DistributionSystemType/HydronicDistribution[HydronicDistributionType="water loop"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:UnitLocation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UnitLocation</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatPumpFuel) = 1'>Expected 1 element(s) for xpath: HeatPumpFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"] or not(h:HeatPumpFuel)'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupType</sch:assert> <!-- See [HeatPumpBackup] or [HeatPumpBackup=Integrated] or [HeatPumpBackup=Separate] -->
      <sch:assert role='ERROR' test='h:BackupType[text()="integrated" or text()="separate"] or not(h:BackupType)'>Expected BackupType to be 'integrated' or 'separate'</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='count(h:extension/h:FanPowerWattsPerCFM) + count(h:extension/h:FanMotorType) &gt; 0'>Fan power watts per cfm or fan motor type is not used for simulation of this HVAC system type.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=PTHPorRoomACwithReverseCycle]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="packaged terminal heat pump" or h:HeatPumpType="room air conditioner with reverse cycle"]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatPumpFuel) = 1'>Expected 1 element(s) for xpath: HeatPumpFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"] or not(h:HeatPumpFuel)'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <!-- Moved/deprecated HeatingCapacityRetention input; see https://github.com/NREL/OpenStudio-HPXML/pull/1931 -->
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingCapacityRetention) = 0'>extension/HeatingCapacityRetention has been replaced by extension/HeatingCapacityFraction17F</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingCapacityFraction17F) + count(h:HeatingCapacity17F) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HeatingCapacityFraction17F | HeatingCapacity17F</sch:assert> <!-- See [HeatPumpCapacityRetention] -->
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingCapacityFraction17F) &lt; 1 or not(h:extension/h:HeatingCapacityFraction17F)'>Expected extension/HeatingCapacityFraction17F to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingCapacityFraction17F) &gt;= 0 or not(h:extension/h:HeatingCapacityFraction17F)'>Expected extension/HeatingCapacityFraction17F to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatingCapacity17F) &lt;= number(h:HeatingCapacity) or not(h:HeatingCapacity17F) or not(h:HeatingCapacity)'>Expected HeatingCapacity17F to be less than or equal to HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity17F) &lt;= count(h:HeatingCapacity)'>Expected HeatingCapacity when HeatingCapacity17F is provided</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorLockoutTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CompressorLockoutTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="CEER"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="EER" or Units="CEER"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="COP"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupType</sch:assert> <!-- See [HeatPumpBackup] or [HeatPumpBackup=Integrated] or [HeatPumpBackup=Separate] -->
      <sch:assert role='ERROR' test='h:BackupType[text()="integrated" or text()="separate"] or not(h:BackupType)'>Expected BackupType to be 'integrated' or 'separate'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CrankcaseHeaterPowerWatts) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CrankcaseHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CrankcaseHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:CrankcaseHeaterPowerWatts)'>Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingActiveDuringDefrost) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/BackupHeatingActiveDuringDefrost</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:BackupHeatingActiveDuringDefrost[text()="true" or text()="false"] or not(h:extension/h:BackupHeatingActiveDuringDefrost)'>Expected extension/BackupHeatingActiveDuringDefrost to be 'true' or 'false'</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt;= 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt;= 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='count(h:extension/h:FanPowerWattsPerCFM) + count(h:extension/h:FanMotorType) &gt; 0'>Fan power watts per cfm or fan motor type is not used for simulation of this HVAC system type.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpBackup]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:BackupType]'>
      <sch:assert role='ERROR' test='count(h:BackupHeatingSwitchoverTemperature) + count(h:CompressorLockoutTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupHeatingSwitchoverTemperature | CompressorLockoutTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupHeatingSwitchoverTemperature) + count(h:BackupHeatingLockoutTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupHeatingSwitchoverTemperature | BackupHeatingLockoutTemperature</sch:assert>
      <sch:assert role='ERROR' test='number(h:CompressorLockoutTemperature) &lt;= number(h:BackupHeatingLockoutTemperature) or not(h:CompressorLockoutTemperature) or not (h:BackupHeatingLockoutTemperature)'>Expected CompressorLockoutTemperature to be less than or equal to BackupHeatingLockoutTemperature</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:BackupHeatingSwitchoverTemperature) &lt; 30'>BackupHeatingSwitchoverTemperature is below 30 deg-F; this may result in significant unmet hours if the heat pump does not have sufficient capacity.</sch:report>
      <sch:report role='WARN' test='number(h:BackupHeatingLockoutTemperature) &lt; 30'>BackupHeatingLockoutTemperature is below 30 deg-F; this may result in significant unmet hours if the heat pump does not have sufficient capacity.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpBackup=Integrated]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:BackupType="integrated" or h:BackupSystemFuel]'>
      <sch:assert role='ERROR' test='count(h:BackupType[text()="integrated"]) = 1'>Expected 1 element(s) for xpath: BackupType[text()="integrated"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupSystemFuel) = 1'>Expected 1 element(s) for xpath: BackupSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:BackupSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"] or not(h:BackupSystemFuel)'>Expected BackupSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupAnnualHeatingEfficiency[h:Units="Percent" or h:Units="AFUE"]/h:Value) = 1'>Expected 1 element(s) for xpath: BackupAnnualHeatingEfficiency[Units="Percent" or Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:BackupAnnualHeatingEfficiency[h:Units="Percent" or h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:BackupAnnualHeatingEfficiency[h:Units="Percent" or h:Units="AFUE"]/h:Value)'>Expected BackupAnnualHeatingEfficiency[Units="Percent" or Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupHeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupHeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingAutosizingFactor) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/BackupHeatingAutosizingFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:BackupHeatingAutosizingFactor) &gt; 0 or not (h:extension/h:BackupHeatingAutosizingFactor)'>BackupHeatingAutosizingFactor should be greater than 0.0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingAutosizingLimit) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/BackupHeatingAutosizingLimit</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:BackupHeatingAutosizingLimit) &gt; 0 or not (h:extension/h:BackupHeatingAutosizingLimit)'>BackupHeatingAutosizingLimit should be greater than 0.0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:BackupAnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt; 0.5'>Percent efficiency should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:BackupAnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt; 0.5'>AFUE should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:BackupHeatingCapacity) &lt;= 1000 and number(h:BackupHeatingCapacity) &gt; 0 and h:BackupHeatingCapacity'>Backup heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpBackup=Separate]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:BackupType="separate" or h:BackupSystem]'>
      <sch:assert role='ERROR' test='sum(../*/h:FractionHeatLoadServed) &lt;= 1.01 and sum(../*/h:FractionHeatLoadServed) &gt;= 0.99'>Expected sum(FractionHeatLoadServed) to be 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupType[text()="separate"]) = 1'>Expected 1 element(s) for xpath: BackupType[text()="separate"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupSystem) = 1'>Expected 1 element(s) for xpath: BackupSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupSystemFuel) = 0'>Expected 0 element(s) for xpath: BackupSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupAnnualHeatingEfficiency) = 0'>Expected 0 element(s) for xpath: BackupAnnualHeatingEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupHeatingCapacity) = 0'>Expected 0 element(s) for xpath: BackupHeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingAutosizingFactor) = 0'>Expected 0 element(s) for xpath: extension/BackupHeatingAutosizingFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingAutosizingLimit) = 0'>Expected 0 element(s) for xpath: extension/BackupHeatingAutosizingLimit</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='count(h:extension/h:BackupHeatingActiveDuringDefrost[text()="true"]) &gt; 0'>BackupHeatingActiveDuringDefrost does not apply when system has separate backup heating.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingDetailedPerformanceDataSingleStage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:HeatingDetailedPerformanceData[../h:CompressorType="single stage"]'>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=47 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=17 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=5 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature&lt;5 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[(h:OutdoorTemperature &gt; 47) or (h:OutdoorTemperature &lt; 47 and h:OutdoorTemperature &gt; 17) or (h:OutdoorTemperature &lt; 17 and h:OutdoorTemperature &gt; 5)]) = 0'>Expected PerformanceDataPoint/OutdoorTemperature to be 47, 17, 5, or &lt;5</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingDetailedPerformanceDataTwoStage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:HeatingDetailedPerformanceData[../h:CompressorType="two stage"]'>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=47 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=47 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=17 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=17 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=5 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=5 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature&lt;5 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature&lt;5 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[(h:OutdoorTemperature &gt; 47) or (h:OutdoorTemperature &lt; 47 and h:OutdoorTemperature &gt; 17) or (h:OutdoorTemperature &lt; 17 and h:OutdoorTemperature &gt; 5)]) = 0'>Expected PerformanceDataPoint/OutdoorTemperature to be 47, 17, 5, or &lt;5</sch:assert>
      <!-- Check for ordered capacities -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <!-- Check for ordered powers (based on capacities) -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <!-- Check for ordered capacity fractions -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <!-- Check for ordered powers (based on capacity fractions) -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingDetailedPerformanceDataVariableSpeed]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:HeatingDetailedPerformanceData[../h:CompressorType="variable speed"]'>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=47 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=47 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=47 and CapacityDescription="maximum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=17 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=17 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=17 and CapacityDescription="maximum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=5 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=5 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=5 and CapacityDescription="maximum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature&lt;5 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature&lt;5 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature&lt;5 and CapacityDescription="maximum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[(h:OutdoorTemperature &gt; 47) or (h:OutdoorTemperature &lt; 47 and h:OutdoorTemperature &gt; 17) or (h:OutdoorTemperature &lt; 17 and h:OutdoorTemperature &gt; 5)]) = 0'>Expected PerformanceDataPoint/OutdoorTemperature to be 47, 17, 5, or &lt;5</sch:assert>
      <!-- Check for min/max consistency -->
      <sch:assert role='ERROR' test='(count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]) = 1 and count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]) = 1) or (count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]) = 0 and count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]) = 0)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is incomplete; there must be exactly one minimum and one maximum capacity datapoint.</sch:assert>
      <!-- Check for ordered capacities -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Capacity) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Capacity) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Capacity) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Capacity) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <!-- Check for ordered powers (based on capacities) -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Capacity)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:Capacity)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
      <!-- Check for ordered capacity fractions -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <!-- Check for ordered powers (based on capacity fractions) -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 47.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 17.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature = 5.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Heating detailed performance data for outdoor temperature &lt; 5.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingDetailedPerformanceDataSingleStage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:CoolingDetailedPerformanceData[../h:CompressorType="single stage"]'>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature&gt;95 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=95 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=82 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[(h:OutdoorTemperature &lt; 82) or (h:OutdoorTemperature &gt; 82 and h:OutdoorTemperature &lt; 95)]) = 0'>Expected PerformanceDataPoint/OutdoorTemperature to be 82, 95, or &gt;95</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingDetailedPerformanceDataTwoStage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:CoolingDetailedPerformanceData[../h:CompressorType="two stage"]'>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature&gt;95 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature&gt;95 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=95 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=95 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=82 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=82 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[(h:OutdoorTemperature &lt; 82) or (h:OutdoorTemperature &gt; 82 and h:OutdoorTemperature &lt; 95)]) = 0'>Expected PerformanceDataPoint/OutdoorTemperature to be 82, 95, or &gt;95</sch:assert>
      <!-- Check for ordered capacities -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <!-- Check for ordered powers (based on capacities) -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <!-- Check for ordered capacity fractions -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <!-- Check for ordered powers (based on capacity fractions) -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingDetailedPerformanceDataVariableSpeed]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:CoolingDetailedPerformanceData[../h:CompressorType="variable speed"]'>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature&gt;95 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature&gt;95 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature&gt;95 and CapacityDescription="maximum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=95 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=95 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=95 and CapacityDescription="maximum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=82 and CapacityDescription="minimum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=82 and CapacityDescription="nominal"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]) = 1'>Expected 1 element(s) for xpath: PerformanceDataPoint[OutdoorTemperature=82 and CapacityDescription="maximum"]</sch:assert> <!-- See [PerformanceDataPoint] -->
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[(h:OutdoorTemperature &lt; 82) or (h:OutdoorTemperature &gt; 82 and h:OutdoorTemperature &lt; 95)]) = 0'>Expected PerformanceDataPoint/OutdoorTemperature to be 82, 95, or &gt;95</sch:assert>
      <!-- Check for min/max consistency -->
      <sch:assert role='ERROR' test='(count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]) = 1 and count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]) = 1) or (count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]) = 0 and count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]) = 0)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is incomplete; there must be exactly one minimum and one maximum capacity datapoint.</sch:assert>
      <!-- Check for ordered capacities -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Capacity) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Capacity) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Capacity) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Capacity) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:Capacity) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <!-- Check for ordered powers (based on capacities) -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:Capacity) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Capacity) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:Capacity)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
      <!-- Check for ordered capacity fractions -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Nominal capacity must be less than or equal to maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Minimum capacity must be less than maximum capacity.</sch:assert>
      <!-- Check for ordered powers (based on capacity fractions) -->
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:Efficiency[h:Units="COP"]/h:Value) &lt;= number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Power (capacity / COP) at nominal capacity must be less than or equal to power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature &gt; 95.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
      <sch:assert role='ERROR' test='(number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:Efficiency[h:Units="COP"]/h:Value) &lt; number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal) div number(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:Efficiency[h:Units="COP"]/h:Value) + 0.001) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]/h:CapacityFractionOfNominal) or not(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]/h:CapacityFractionOfNominal)'>Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingDetailedPerformanceDataPointCapacity]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:HeatingDetailedPerformanceData/h:PerformanceDataPoint[number(h:OutdoorTemperature)=47 and h:CapacityDescription="nominal"]'>
      <sch:assert role='ERROR' test='(number(../../h:HeatingCapacity) &gt;= 0.99 * number(h:Capacity) or not (../../h:HeatingCapacity)) or not (h:Capacity)'>Expected ../../HeatingCapacity to be equal to Capacity</sch:assert>
      <sch:assert role='ERROR' test='(number(../../h:HeatingCapacity) &lt;= 1.01 * number(h:Capacity) or not (../../h:HeatingCapacity)) or not (h:Capacity)'>Expected ../../HeatingCapacity to be equal to Capacity</sch:assert>
      <sch:assert role='ERROR' test='number(h:CapacityFractionOfNominal) &gt;= 0.99 or not (h:CapacityFractionOfNominal)'>Expected CapacityFractionOfNominal to be 1.0</sch:assert>
      <sch:assert role='ERROR' test='number(h:CapacityFractionOfNominal) &lt;= 1.01 or not (h:CapacityFractionOfNominal)'>Expected CapacityFractionOfNominal to be 1.0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingDetailedPerformanceDataPointCapacity17F]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:HeatingDetailedPerformanceData/h:PerformanceDataPoint[number(h:OutdoorTemperature)=17 and h:CapacityDescription="nominal"]'>
      <sch:assert role='ERROR' test='(number(../../h:HeatingCapacity17F) &gt;= 0.99 * number(h:Capacity) or not (../../h:HeatingCapacity17F)) or not (h:Capacity)'>Expected ../../HeatingCapacity17F to be equal to Capacity</sch:assert>
      <sch:assert role='ERROR' test='(number(../../h:HeatingCapacity17F) &lt;= 1.01 * number(h:Capacity) or not (../../h:HeatingCapacity17F)) or not (h:Capacity)'>Expected ../../HeatingCapacity17F to be equal to Capacity</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingDetailedPerformanceDataPointCapacity]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:CoolingDetailedPerformanceData/h:PerformanceDataPoint[number(h:OutdoorTemperature)=95 and h:CapacityDescription="nominal"]'>
      <sch:assert role='ERROR' test='(number(../../h:CoolingCapacity) &gt;= 0.99 * number(h:Capacity) or not (../../h:CoolingCapacity)) or not (h:Capacity)'>Expected ../../CoolingCapacity to be equal to Capacity</sch:assert>
      <sch:assert role='ERROR' test='(number(../../h:CoolingCapacity) &lt;= 1.01 * number(h:Capacity) or not (../../h:CoolingCapacity)) or not (h:Capacity)'>Expected ../../CoolingCapacity to be equal to Capacity</sch:assert>
      <sch:assert role='ERROR' test='number(h:CapacityFractionOfNominal) &gt;= 0.99 or not (h:CapacityFractionOfNominal)'>Expected CapacityFractionOfNominal to be 1.0</sch:assert>
      <sch:assert role='ERROR' test='number(h:CapacityFractionOfNominal) &lt;= 1.01 or not (h:CapacityFractionOfNominal)'>Expected CapacityFractionOfNominal to be 1.0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PerformanceDataPoint]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/*/h:PerformanceDataPoint'>
      <sch:assert role='ERROR' test='count(h:Capacity) + count(h:CapacityFractionOfNominal) &gt;= 1'>Expected 1 or more element(s) for xpath: Capacity | CapacityFractionOfNominal</sch:assert>
      <sch:assert role='ERROR' test='number(h:Capacity) &gt;= 0 or not(h:Capacity)'>Expected Capacity to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:CapacityFractionOfNominal) &gt;= 0 or not(h:CapacityFractionOfNominal)'>Expected CapacityFractionOfNominal to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:Efficiency[h:Units="COP"]/h:Value) = 1'>Expected 1 element(s) for xpath: Efficiency[Units="COP"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[GeothermalLoop]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:GeothermalLoop'>
      <sch:assert role='ERROR' test='count(h:LoopConfiguration) = 1'>Expected 1 element(s) for xpath: LoopConfiguration</sch:assert>
      <sch:assert role='ERROR' test='h:LoopConfiguration[text()="vertical"] or not(h:LoopConfiguration)'>Expected LoopConfiguration to be 'vertical'</sch:assert>
      <sch:assert role='ERROR' test='count(h:LoopFlow) &lt;= 1'>Expected 0 or 1 element(s) for xpath: LoopFlow</sch:assert>
      <sch:assert role='ERROR' test='count(h:BoreholesOrTrenches/h:Count) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BoreholesOrTrenches/Count</sch:assert>
      <sch:assert role='ERROR' test='number(h:BoreholesOrTrenches/h:Count) &gt;= 1 or not(h:BoreholesOrTrenches/h:Count)'>Expected BoreholesOrTrenches/Count to be greater than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:BoreholesOrTrenches/h:Count) &lt;= 10 or not(h:BoreholesOrTrenches/h:Count)'>Expected BoreholesOrTrenches/Count to be less than or equal to 10</sch:assert>
      <sch:assert role='ERROR' test='count(h:BoreholesOrTrenches/h:Length) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BoreholesOrTrenches/Length</sch:assert>
      <sch:assert role='ERROR' test='number(h:BoreholesOrTrenches/h:Length) &gt;= 80 or not(h:BoreholesOrTrenches/h:Length)'>Expected BoreholesOrTrenches/Length to be greater than or equal to 80</sch:assert>
      <sch:assert role='ERROR' test='number(h:BoreholesOrTrenches/h:Length) &lt;= 500 or not(h:BoreholesOrTrenches/h:Length)'>Expected BoreholesOrTrenches/Length to be less than or equal to 500</sch:assert>
      <sch:assert role='ERROR' test='count(h:BoreholesOrTrenches/h:Spacing) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BoreholesOrTrenches/Spacing</sch:assert>
      <sch:assert role='ERROR' test='count(h:BoreholesOrTrenches/h:Diameter) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BoreholesOrTrenches/Diameter</sch:assert>
      <sch:assert role='ERROR' test='count(h:Grout/h:Type) + count(h:Grout/h:Conductivity) &gt;= 0'>Expected 0 or more element(s) for xpath: Grout/Type | Grout/Conductivity</sch:assert>
      <sch:assert role='ERROR' test='count(h:Pipe/h:Type) + count(h:Pipe/h:Conductivity) &gt;= 0'>Expected 0 or more element(s) for xpath: Pipe/Type | Pipe/Conductivity</sch:assert>
      <sch:assert role='ERROR' test='count(h:Pipe/h:Diameter) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Pipe/Diameter</sch:assert>
      <sch:assert role='ERROR' test='number(h:Pipe/h:Diameter) = 0.75 or number(h:Pipe/h:Diameter) = 1.0 or number(h:Pipe/h:Diameter) = 1.25 or not(h:Pipe/h:Diameter)'>Expected Pipe/Diameter to be 0.75, 1.0, or 1.25</sch:assert>
      <sch:assert role='ERROR' test='count(h:Pipe/h:ShankSpacing) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Pipe/ShankSpacing</sch:assert>
      <sch:assert role='ERROR' test='count(h:BoreholesOrTrenches/h:Count) + count(h:extension/h:BorefieldConfiguration[text()!="Rectangle"]) = 2 or not(h:extension/h:BorefieldConfiguration[text()!="Rectangle"])'>Expected BoreholesOrTrenches/Count when extension/BorefieldConfiguration is not 'Rectangle'</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:BorefieldConfiguration[text()="Rectangle" or text()="Open Rectangle" or text()="C" or text()="L" or text()="U" or text()="Lopsided U"] or not(h:extension/h:BorefieldConfiguration)'>Expected BorefieldConfiguration to be 'Rectangle' or 'Open Rectangle' or 'C' or 'L' or 'U' or 'Lopsided U'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirflowDefectRatio]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*[not(h:DistributionSystem)]'>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) = 0 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACControl=Heating]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACControl[sum(../h:HVACPlant/*/h:FractionHeatLoadServed) > 0]'>
      <sch:assert role='ERROR' test='count(h:SetpointTempHeatingSeason) + count(h:extension/h:WeekdaySetpointTempsHeatingSeason) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SetpointTempHeatingSeason | extension/WeekdaySetpointTempsHeatingSeason</sch:assert>
      <sch:assert role='ERROR' test='count(h:SetpointTempHeatingSeason) + count(h:extension/h:WeekendSetpointTempsHeatingSeason) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SetpointTempHeatingSeason | extension/WeekendSetpointTempsHeatingSeason</sch:assert>
      <sch:assert role='ERROR' test='count(h:SetbackTempHeatingSeason) + count(h:extension/h:WeekdaySetpointTempsHeatingSeason) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SetbackTempHeatingSeason | extension/WeekdaySetpointTempsHeatingSeason</sch:assert> <!-- See [HVACControl=HeatingSetback] -->
      <sch:assert role='ERROR' test='count(h:SetbackTempHeatingSeason) + count(h:extension/h:WeekendSetpointTempsHeatingSeason) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SetbackTempHeatingSeason | extension/WeekendSetpointTempsHeatingSeason</sch:assert> <!-- See [HVACControl=HeatingSetback] -->
      <sch:assert role='ERROR' test='count(h:HeatingSeason) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Heating</sch:assert> <!-- See [HVACControl=HeatingSeason] -->
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:SetpointTempHeatingSeason) &lt; 58'>Heating setpoint should typically be greater than or equal to 58 deg-F.</sch:report>
      <sch:report role='WARN' test='number(h:SetpointTempHeatingSeason) &gt; 76'>Heating setpoint should typically be less than or equal to 76 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACControl=HeatingSetback]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACControl[h:SetbackTempHeatingSeason]'>
      <sch:assert role='ERROR' test='count(h:TotalSetbackHoursperWeekHeating) = 1'>Expected 1 element(s) for xpath: TotalSetbackHoursperWeekHeating</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SetbackStartHourHeating) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/SetbackStartHourHeating</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SetbackStartHourHeating) &gt;= 0 or not(h:extension/h:SetbackStartHourHeating)'>Expected extension/SetbackStartHourHeating to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SetbackStartHourHeating) &lt;= 23 or not(h:extension/h:SetbackStartHourHeating)'>Expected extension/SetbackStartHourHeating to be less than or equal to 23</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACControl=HeatingSeason]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACControl/h:HeatingSeason'>
      <sch:assert role='ERROR' test='count(h:BeginMonth) = 1'>Expected 1 element(s) for xpath: BeginMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:BeginDayOfMonth) = 1'>Expected 1 element(s) for xpath: BeginDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndMonth) = 1'>Expected 1 element(s) for xpath: EndMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndDayOfMonth) = 1'>Expected 1 element(s) for xpath: EndDayOfMonth</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACControl=Cooling]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACControl[sum(../h:HVACPlant/*/h:FractionCoolLoadServed) > 0]'>
      <sch:assert role='ERROR' test='count(h:SetpointTempCoolingSeason) + count(h:extension/h:WeekdaySetpointTempsCoolingSeason) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SetpointTempCoolingSeason | extension/WeekdaySetpointTempsCoolingSeason</sch:assert>
      <sch:assert role='ERROR' test='count(h:SetpointTempCoolingSeason) + count(h:extension/h:WeekendSetpointTempsCoolingSeason) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SetpointTempCoolingSeason | extension/WeekendSetpointTempsCoolingSeason</sch:assert>
      <sch:assert role='ERROR' test='count(h:SetupTempCoolingSeason) + count(h:extension/h:WeekdaySetpointTempsCoolingSeason) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SetupTempCoolingSeason | extension/WeekdaySetpointTempsCoolingSeason</sch:assert> <!-- See [HVACControl=CoolingSetup] -->
      <sch:assert role='ERROR' test='count(h:SetupTempCoolingSeason) + count(h:extension/h:WeekendSetpointTempsCoolingSeason) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SetupTempCoolingSeason | extension/WeekendSetpointTempsCoolingSeason</sch:assert> <!-- See [HVACControl=CoolingSetup] -->
      <sch:assert role='ERROR' test='count(h:extension/h:CeilingFanSetpointTempCoolingSeasonOffset) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/CeilingFanSetpointTempCoolingSeasonOffset</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingSeason) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Cooling</sch:assert> <!-- See [HVACControl=CoolingSeason] -->
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:SetpointTempCoolingSeason) &lt; 68'>Cooling setpoint should typically be greater than or equal to 68 deg-F.</sch:report>
      <sch:report role='WARN' test='number(h:SetpointTempCoolingSeason) &gt; 86'>Cooling setpoint should typically be less than or equal to 86 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACControl=CoolingSetup]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACControl[h:SetupTempCoolingSeason]'>
      <sch:assert role='ERROR' test='count(h:TotalSetupHoursperWeekCooling) = 1'>Expected 1 element(s) for xpath: TotalSetupHoursperWeekCooling</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SetupStartHourCooling) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/SetupStartHourCooling</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SetupStartHourCooling) &gt;= 0 or not(h:extension/h:SetupStartHourCooling)'>Expected extension/SetupStartHourCooling to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SetupStartHourCooling) &lt;= 23 or not(h:extension/h:SetupStartHourCooling)'>Expected extension/SetupStartHourCooling to be less than or equal to 23</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACControl=CoolingSeason]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACControl/h:CoolingSeason'>
      <sch:assert role='ERROR' test='count(h:BeginMonth) = 1'>Expected 1 element(s) for xpath: BeginMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:BeginDayOfMonth) = 1'>Expected 1 element(s) for xpath: BeginDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndMonth) = 1'>Expected 1 element(s) for xpath: EndMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndDayOfMonth) = 1'>Expected 1 element(s) for xpath: EndDayOfMonth</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDistribution]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution'>
      <sch:assert role='ERROR' test='count(h:DistributionSystemType[h:AirDistribution | h:HydronicDistribution | h:Other[text()="DSE"]]) = 1'>Expected 1 element(s) for xpath: DistributionSystemType[AirDistribution | HydronicDistribution | Other[text()="DSE"]]</sch:assert> <!-- See [HVACDistributionType=Air] or [HVACDistributionType=Hydronic] or [HVACDistributionType=DSE] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDistributionType=Air]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution'>
      <sch:assert role='ERROR' test='count(h:AirDistributionType) = 1'>Expected 1 element(s) for xpath: AirDistributionType</sch:assert>
      <sch:assert role='ERROR' test='h:AirDistributionType[text()="regular velocity" or text()="gravity" or text()="fan coil"] or not(h:AirDistributionType)'>Expected AirDistributionType to be 'regular velocity' or 'gravity' or 'fan coil'</sch:assert> <!-- See [AirDistributionType=RegularVelocityOrGravity] or [AirDistributionType=FanCoil] -->
      <sch:assert role='ERROR' test='count(h:Ducts) &gt;= 0'>Expected 0 or more element(s) for xpath: Ducts</sch:assert> <!-- See [HVACDuct] -->
      <sch:assert role='ERROR' test='count(h:extension/h:ManualJInputs/h:BlowerFanHeatBtuh) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ManualJInputs/BlowerFanHeatBtuh</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ManualJInputs/h:BlowerFanHeatBtuh) &gt;= 0 or not(h:extension/h:ManualJInputs/h:BlowerFanHeatBtuh)'>Expected extension/ManualJInputs/BlowerFanHeatBtuh to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ManualJInputs/h:DefaultTableDuctLoad) &gt;= 0'>Expected 0 or more element(s) for xpath: extension/ManualJInputs/DefaultTableDuctLoad</sch:assert> <!-- See ManualJInputs=DefaultTableDuctLoad -->
      <!-- Sum Checks -->
      <sch:assert role='ERROR' test='(sum(h:Ducts[h:DuctType="supply"]/h:FractionDuctArea) &gt;= 0.99 and sum(h:Ducts[h:DuctType="supply"]/h:FractionDuctArea) &lt;= 1.01) or count(h:Ducts[h:DuctType="supply"]/h:FractionDuctArea) = 0'>Expected sum(Ducts/FractionDuctArea) for DuctType="supply" to be 1</sch:assert>
      <sch:assert role='ERROR' test='(sum(h:Ducts[h:DuctType="return"]/h:FractionDuctArea) &gt;= 0.99 and sum(h:Ducts[h:DuctType="return"]/h:FractionDuctArea) &lt;= 1.01) or count(h:Ducts[h:DuctType="return"]/h:FractionDuctArea) = 0'>Expected sum(Ducts/FractionDuctArea) for DuctType="return" to be 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ManualJInputs=DefaultTableDuctLoad]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:extension/h:ManualJInputs/h:DefaultTableDuctLoad'>
      <sch:assert role='ERROR' test='count(h:TableNumber) = 1'>Expected 1 element(s) for xpath: TableNumber</sch:assert>
      <sch:assert role='ERROR' test='h:TableNumber[text()="7A-R" or text()="7A-T" or text()="7B-R" or text()="7B-T" or text()="7A-AE" or text()="7B-AE" or text()="7C-AE" or text()="7C-R" or text()="7C-T" or text()="7D-R" or text()="7D-T" or text()="7E-R" or text()="7E-T" or text()="7F-R" or text()="7F-T" or text()="7G-R" or text()="7G-T" or text()="7H" or text()="7I" or text()="7D-AE" or text()="7J-1" or text()="7J-2" or text()="7K" or text()="7L" or text()="7M" or text()="7N" or text()="7O-1" or text()="7O-2" or text()="7O-3" or text()="7O-4" or text()="7P-1" or text()="7P-2" or text()="7P-3" or text()="7P-4"] or not(h:TableNumber)'>Expected TableNumber to be '7A-R' or '7A-T' or '7B-R' or '7B-T' or '7A-AE' or '7B-AE' or '7C-AE' or '7C-R' or '7C-T' or '7D-R' or '7D-T' or '7E-R' or '7E-T' or '7F-R' or '7F-T' or '7G-R' or '7G-T' or '7H' or '7I' or '7D-AE' or '7J-1' or '7J-2' or '7K' or '7L' or '7M' or '7N' or '7O-1' or '7O-2' or '7O-3' or '7O-4' or '7P-1' or '7P-2' or '7P-3' or '7P-4'</sch:assert>
      <sch:assert role='ERROR' test='count(h:LookupFloorArea) = 1'>Expected 1 element(s) for xpath: LookupFloorArea</sch:assert>
      <sch:assert role='ERROR' test='number(h:LookupFloorArea) &gt; 0 or not(h:LookupFloorArea)'>Expected LookupFloorArea to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:LeakageLevel) = 1'>Expected 1 element(s) for xpath: LeakageLevel</sch:assert>
      <sch:assert role='ERROR' test='h:LeakageLevel[text()="default not sealed" or text()="partially sealed" or text()="default sealed" or text()="notably sealed" or text()="extremely sealed"] or not(h:LeakageLevel)'>Expected LeakageLevel to be 'default not sealed' or 'partially sealed' or 'default sealed' or 'notably sealed' or 'extremely sealed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InsulationRValue) = 1'>Expected 1 element(s) for xpath: InsulationRValue</sch:assert>
      <sch:assert role='ERROR' test='number(h:InsulationRValue) &gt;= 2 or not(h:InsulationRValue)'>Expected InsulationRValue to be greater than 2</sch:assert>
      <sch:assert role='ERROR' test='count(h:SupplySurfaceArea) + count(h:DSF) &lt;= 1'>Expected 0 or 1 element(s) for xpath: SupplySurfaceArea | DSF</sch:assert>
      <sch:assert role='ERROR' test='number(h:SupplySurfaceArea) &gt;= 0 or not(h:SupplySurfaceArea)'>Expected SupplySurfaceArea to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:ReturnSurfaceArea) + count(h:DSF) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ReturnSurfaceArea | DSF</sch:assert>
      <sch:assert role='ERROR' test='number(h:ReturnSurfaceArea) &gt;= 0 or not(h:ReturnSurfaceArea)'>Expected ReturnSurfaceArea to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:DSF) &gt;= 0 or not(h:DSF)'>Expected DSF to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirDistributionType=RegularVelocityOrGravity]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution[h:AirDistributionType[text()="regular velocity" or text()="gravity"]]'>
      <sch:assert role='ERROR' test='count(h:DuctLeakageMeasurement[h:DuctType="supply"]/h:DuctLeakage[(h:Units="CFM25" or h:Units="CFM50" or h:Units="Percent") and h:TotalOrToOutside="to outside"]) = 1'>Expected 1 element(s) for xpath: DuctLeakageMeasurement[DuctType="supply"]/DuctLeakage[(Units="CFM25" or Units="CFM50" or Units="Percent") and TotalOrToOutside="to outside"]</sch:assert> <!-- See [DuctLeakage=CFM] or [DuctLeakage=Percent] -->
      <sch:assert role='ERROR' test='count(h:DuctLeakageMeasurement[h:DuctType="return"]/h:DuctLeakage[(h:Units="CFM25" or h:Units="CFM50" or h:Units="Percent") and h:TotalOrToOutside="to outside"]) = 1'>Expected 1 element(s) for xpath: DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[(Units="CFM25" or Units="CFM50" or Units="Percent") and TotalOrToOutside="to outside"]</sch:assert> <!-- See [DuctLeakage=CFM] or [DuctLeakage=Percent] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirDistributionType=FanCoil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution[h:AirDistributionType[text()="fan coil"]]'>
      <sch:assert role='ERROR' test='count(h:DuctLeakageMeasurement[h:DuctType="supply"]/h:DuctLeakage[(h:Units="CFM25" or h:Units="CFM50" or h:Units="Percent") and h:TotalOrToOutside="to outside"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DuctLeakageMeasurement[DuctType="supply"]/DuctLeakage[(Units="CFM25" or Units="CFM50" or Units="Percent") and TotalOrToOutside="to outside"]</sch:assert> <!-- See [DuctLeakage=CFM] or [DuctLeakage=Percent] -->
      <sch:assert role='ERROR' test='count(h:DuctLeakageMeasurement[h:DuctType="return"]/h:DuctLeakage[(h:Units="CFM25" or h:Units="CFM50" or h:Units="Percent") and h:TotalOrToOutside="to outside"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[(Units="CFM25" or Units="CFM50" or Units="Percent") and TotalOrToOutside="to outside"]</sch:assert> <!-- See [DuctLeakage=CFM] or [DuctLeakage=Percent] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DuctLeakage=CFM]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:DuctLeakageMeasurement/h:DuctLeakage[h:Units="CFM25" or h:Units="CFM50"]'>
      <sch:assert role='ERROR' test='count(h:Value) = 1'>Expected 1 element(s) for xpath: Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DuctLeakage=Percent]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:DuctLeakageMeasurement/h:DuctLeakage[h:Units="Percent"]'>
      <sch:assert role='ERROR' test='count(h:Value) = 1'>Expected 1 element(s) for xpath: Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:Value) &lt; 1 or not(h:Value)'>Expected Value to be less than 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDistributionType=Hydronic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution'>
      <sch:assert role='ERROR' test='count(h:HydronicDistributionType) = 1'>Expected 1 element(s) for xpath: HydronicDistributionType</sch:assert>
      <sch:assert role='ERROR' test='h:HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling" or text()="water loop"] or not(h:HydronicDistributionType)'>Expected HydronicDistributionType to be 'radiator' or 'baseboard' or 'radiant floor' or 'radiant ceiling' or 'water loop'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ManualJInputs/h:HotWaterPipingBtuh) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ManualJInputs/HotWaterPipingBtuh</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ManualJInputs/h:HotWaterPipingBtuh) &gt;= 0 or not(h:extension/h:ManualJInputs/h:HotWaterPipingBtuh)'>Expected extension/ManualJInputs/HotWaterPipingBtuh to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDistributionType=DSE]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution[h:DistributionSystemType[h:Other[text()="DSE"]]]'>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingDistributionSystemEfficiency) = 1'>Expected 1 element(s) for xpath: AnnualHeatingDistributionSystemEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingDistributionSystemEfficiency) = 1'>Expected 1 element(s) for xpath: AnnualCoolingDistributionSystemEfficiency</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingDistributionSystemEfficiency) &lt; 0.5'>Heating DSE should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingDistributionSystemEfficiency) &lt; 0.5'>Cooling DSE should typically be greater than or equal to 0.5.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDuct]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:Ducts'>
      <sch:assert role='ERROR' test='count(h:DuctType) = 1'>Expected 1 element(s) for xpath: DuctType</sch:assert>
      <sch:assert role='ERROR' test='h:DuctType[text()="supply" or text()="return"] or not(h:DuctType)'>Expected DuctType to be 'supply' or 'return'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DuctInsulationRValue) + count(h:DuctEffectiveRValue) &gt;= 1'>Expected 1 or more element(s) for xpath: DuctInsulationRValue | DuctEffectiveRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:DuctBuriedInsulationLevel) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DuctBuriedInsulationLevel</sch:assert>
      <sch:assert role='ERROR' test='h:DuctBuriedInsulationLevel[text()="not buried" or text()="partially buried" or text()="fully buried" or text()="deeply buried"] or not(h:DuctBuriedInsulationLevel)'>Expected DuctBuriedInsulationLevel to be 'not buried' or 'partially buried' or 'fully buried' or 'deeply buried'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DuctLocation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DuctLocation</sch:assert> <!-- See [HVACDuct=WithLocation] or [HVACDuct=WithoutLocation] -->
      <sch:assert role='ERROR' test='h:DuctLocation[text()="conditioned space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="attic - vented" or text()="attic - unvented" or text()="garage" or text()="exterior wall" or text()="under slab" or text()="roof deck" or text()="outside" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="manufactured home belly"] or not(h:DuctLocation)'>Expected DuctLocation to be 'conditioned space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'attic - vented' or 'attic - unvented' or 'garage' or 'exterior wall' or 'under slab' or 'roof deck' or 'outside' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DuctShape) + count(h:extension/DuctFractionRectangular) &gt;= 0'>Expected 0 or more element(s) for xpath: DuctShape | DuctFractionRectangular</sch:assert>
      <sch:assert role='ERROR' test='h:DuctShape[text()="rectangular" or text()="round" or text()="oval" or text()="other"] or not(h:DuctShape)'>Expected DuctShape to be 'rectangular' or 'round' or 'oval' or 'other'</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:DuctFractionRectangular) &gt;= 0 or not(h:extension/h:DuctFractionRectangular)'>Expected extension/DuctFractionRectangular to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:DuctFractionRectangular) &lt;= 1 or not(h:extension/h:DuctFractionRectangular)'>Expected extension/DuctFractionRectangular to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:DuctSurfaceAreaMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/DuctSurfaceAreaMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:DuctSurfaceAreaMultiplier) &gt;= 0 or not(h:extension/h:DuctSurfaceAreaMultiplier)'>Expected extension/DuctSurfaceAreaMultiplier to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDuct=WithLocation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:Ducts[h:DuctLocation]'>
      <sch:assert role='ERROR' test='count(h:FractionDuctArea) + count(h:DuctSurfaceArea) &gt;= 1'>Expected 1 or more element(s) for xpath: FractionDuctArea | DuctSurfaceArea</sch:assert> <!-- See [HVACDuct=SurfaceAreaDefaulted] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDuct=WithoutLocation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:Ducts[not(h:DuctLocation)]'>
      <sch:assert role='ERROR' test='count(h:FractionDuctArea) + count(h:DuctSurfaceArea) = 0'>Expected 0 element(s) for xpath: FractionDuctArea | DuctSurfaceArea</sch:assert> <!-- See [HVACDuct=SurfaceAreaDefaulted] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDuct=SurfaceAreaDefaulted]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:Ducts[not(h:DuctSurfaceArea)]'>
      <sch:assert role='ERROR' test='count(../h:NumberofReturnRegisters) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../NumberofReturnRegisters</sch:assert>
      <sch:assert role='ERROR' test='count(../../../h:ConditionedFloorAreaServed) = 1'>Expected 1 element(s) for xpath: ../../../ConditionedFloorAreaServed</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[VentilationFan]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan'>
      <sch:assert role='ERROR' test='count(h:UsedForWholeBuildingVentilation[text()="true"]) + count(h:UsedForLocalVentilation[text()="true"]) + count(h:UsedForSeasonalCoolingLoadReduction[text()="true"]) + count(h:UsedForGarageVentilation[text()="true"]) = 1'>Expected 1 element(s) for xpath: UsedForWholeBuildingVentilation[text()="true"] | UsedForLocalVentilation[text()="true"] | UsedForSeasonalCoolingLoadReduction[text()="true"] | UsedForGarageVentilation[text()="true"]</sch:assert> <!-- See [MechanicalVentilation] or [LocalVentilation] or [WholeHouseFan] or [GarageVentilation] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true"]'>
      <sch:assert role='ERROR' test='count(h:FanType) = 1'>Expected 1 element(s) for xpath: FanType</sch:assert> <!-- See [MechanicalVentilationType=ExhaustOnly] or [MechanicalVentilationType=SupplyOnly] or [MechanicalVentilationType=Balanced] or [MechanicalVentilationType=HRV] or [MechanicalVentilationType=ERV] or [MechanicalVentilationType=CFIS] -->
      <sch:assert role='ERROR' test='h:FanType[text()="energy recovery ventilator" or text()="heat recovery ventilator" or text()="exhaust only" or text()="supply only" or text()="balanced" or text()="central fan integrated supply"] or not(h:FanType)'>Expected FanType to be 'energy recovery ventilator' or 'heat recovery ventilator' or 'exhaust only' or 'supply only' or 'balanced' or 'central fan integrated supply'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=ExhaustOnly]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="exhaust only"]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [MechanicalVentilationType=Shared] -->
      <sch:assert role='ERROR' test='count(h:CFISControls) = 0'>Expected 0 element(s) for xpath: CFISControls</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedFlowRate) + count(h:CalculatedFlowRate) + count(h:TestedFlowRate) + count(h:DeliveredVentilation) &gt;= 0'>Expected 0 or more element(s) for xpath: RatedFlowRate | CalculatedFlowRate | TestedFlowRate | DeliveredVentilation</sch:assert>
      <sch:assert role='ERROR' test='count(h:HoursInOperation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HoursInOperation</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) &lt;= 1'>Expected 0 or 1 element(s) for xpath: FanPower</sch:assert>
      <sch:assert role='ERROR' test='count(h:TotalRecoveryEfficiency) + count(h:AdjustedTotalRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleRecoveryEfficiency) + count(h:AdjustedSensibleRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=SupplyOnly]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="supply only"]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [MechanicalVentilationType=Shared] -->
      <sch:assert role='ERROR' test='count(h:CFISControls) = 0'>Expected 0 element(s) for xpath: CFISControls</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedFlowRate) + count(h:CalculatedFlowRate) + count(h:TestedFlowRate) + count(h:DeliveredVentilation) &gt;= 0'>Expected 0 or more element(s) for xpath: RatedFlowRate | CalculatedFlowRate | TestedFlowRate | DeliveredVentilation</sch:assert>
      <sch:assert role='ERROR' test='count(h:HoursInOperation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HoursInOperation</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) &lt;= 1'>Expected 0 or 1 element(s) for xpath: FanPower</sch:assert>
      <sch:assert role='ERROR' test='count(h:TotalRecoveryEfficiency) + count(h:AdjustedTotalRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleRecoveryEfficiency) + count(h:AdjustedSensibleRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=Balanced]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="balanced"]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [MechanicalVentilationType=Shared] -->
      <sch:assert role='ERROR' test='count(h:CFISControls) = 0'>Expected 0 element(s) for xpath: CFISControls</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedFlowRate) + count(h:CalculatedFlowRate) + count(h:TestedFlowRate) + count(h:DeliveredVentilation) &gt;= 0'>Expected 0 or more element(s) for xpath: RatedFlowRate | CalculatedFlowRate | TestedFlowRate | DeliveredVentilation</sch:assert>
      <sch:assert role='ERROR' test='count(h:HoursInOperation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HoursInOperation</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) &lt;= 1'>Expected 0 or 1 element(s) for xpath: FanPower</sch:assert>
      <sch:assert role='ERROR' test='count(h:TotalRecoveryEfficiency) + count(h:AdjustedTotalRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleRecoveryEfficiency) + count(h:AdjustedSensibleRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=HRV]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="heat recovery ventilator"]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [MechanicalVentilationType=Shared] -->
      <sch:assert role='ERROR' test='count(h:CFISControls) = 0'>Expected 0 element(s) for xpath: CFISControls</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedFlowRate) + count(h:CalculatedFlowRate) + count(h:TestedFlowRate) + count(h:DeliveredVentilation) &gt;= 0'>Expected 0 or more element(s) for xpath: RatedFlowRate | CalculatedFlowRate | TestedFlowRate | DeliveredVentilation</sch:assert>
      <sch:assert role='ERROR' test='count(h:HoursInOperation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HoursInOperation</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdjustedTotalRecoveryEfficiency) + count(h:TotalRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: AdjustedTotalRecoveryEfficiency | TotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdjustedSensibleRecoveryEfficiency) + count(h:SensibleRecoveryEfficiency) = 1'>Expected 1 element(s) for xpath: AdjustedSensibleRecoveryEfficiency | SensibleRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) &lt;= 1'>Expected 0 or 1 element(s) for xpath: FanPower</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=ERV]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="energy recovery ventilator"]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [MechanicalVentilationType=Shared] -->
      <sch:assert role='ERROR' test='count(h:CFISControls) = 0'>Expected 0 element(s) for xpath: CFISControls</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedFlowRate) + count(h:CalculatedFlowRate) + count(h:TestedFlowRate) + count(h:DeliveredVentilation) &gt;= 0'>Expected 0 or more element(s) for xpath: RatedFlowRate | CalculatedFlowRate | TestedFlowRate | DeliveredVentilation</sch:assert>
      <sch:assert role='ERROR' test='count(h:HoursInOperation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HoursInOperation</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdjustedTotalRecoveryEfficiency) + count(h:TotalRecoveryEfficiency) = 1'>Expected 1 element(s) for xpath: AdjustedTotalRecoveryEfficiency | TotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdjustedSensibleRecoveryEfficiency) + count(h:SensibleRecoveryEfficiency) = 1'>Expected 1 element(s) for xpath: AdjustedSensibleRecoveryEfficiency | SensibleRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) &lt;= 1'>Expected 0 or 1 element(s) for xpath: FanPower</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AdjustedTotalRecoveryEfficiency) &lt; 0.5*number(h:AdjustedSensibleRecoveryEfficiency)'>Adjusted total recovery efficiency should typically be at least half of the adjusted sensible recovery efficiency.</sch:report>
      <sch:report role='WARN' test='number(h:TotalRecoveryEfficiency) &lt; 0.5*number(h:SensibleRecoveryEfficiency)'>Total recovery efficiency should typically be at least half of the sensible recovery efficiency.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=CFIS]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply"]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem[text()="true"]) = 0'>Expected 0 element(s) for xpath: IsSharedSystem[text()="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:HasOutdoorAirControl) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CFISControls/HasOutdoorAirControl</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:AdditionalRuntimeOperatingMode) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CFISControls/AdditionalRuntimeOperatingMode</sch:assert>
      <sch:assert role='ERROR' test='h:CFISControls/h:AdditionalRuntimeOperatingMode[text()="air handler fan" or text()="supplemental fan" or text()="none"] or not(h:CFISControls/h:AdditionalRuntimeOperatingMode)'>Expected CFISControls/AdditionalRuntimeOperatingMode to be 'air handler fan' or 'supplemental fan' or 'none'</sch:assert> <!-- See [CFISAdditionalRuntimeMode=AirHandlerFan] or [CFISAdditionalRuntimeMode=SupplementalFan] or [CFISAdditionalRuntimeMode=None] -->
      <sch:assert role='ERROR' test='count(h:CFISControls/h:extension/h:ControlType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CFISControls/extension/ControlType</sch:assert>
      <sch:assert role='ERROR' test='h:CFISControls/h:extension/h:ControlType[text()="optimized" or text()="timer"] or not(h:CFISControls/h:extension/h:ControlType)'>Expected CFISControls/extension/ControlType to be 'optimized' or 'timer'</sch:assert> <!-- See CFISControlType=Timer -->
      <sch:assert role='ERROR' test='count(h:RatedFlowRate) + count(h:CalculatedFlowRate) + count(h:TestedFlowRate) + count(h:DeliveredVentilation) &gt;= 0'>Expected 0 or more element(s) for xpath: RatedFlowRate | CalculatedFlowRate | TestedFlowRate | DeliveredVentilation</sch:assert>
      <sch:assert role='ERROR' test='count(h:HoursInOperation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HoursInOperation</sch:assert>
      <sch:assert role='ERROR' test='count(h:TotalRecoveryEfficiency) + count(h:AdjustedTotalRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleRecoveryEfficiency) + count(h:AdjustedSensibleRecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToHVACDistributionSystem) = 1'>Expected 1 element(s) for xpath: AttachedToHVACDistributionSystem</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CFISControlType=Timer]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply" and h:CFISControls/h:extension/h:ControlType="timer"]'>
      <sch:assert role='ERROR' test='h:CFISControls/h:AdditionalRuntimeOperatingMode[text()="air handler fan"]'>Expected CFISControls/AdditionalRuntimeOperatingMode to be 'air handler fan'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CFISAdditionalRuntimeMode=AirHandlerFan]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply" and h:CFISControls/h:AdditionalRuntimeOperatingMode="air handler fan"]'>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:SupplementalFan) = 0'>Expected 0 element(s) for xpath: CFISControls/SupplementalFan</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:extension/h:SupplementalFanRunsWithAirHandlerFan) = 0'>Expected 0 element(s) for xpath: CFISControls/extension/SupplementalFanRunsWithAirHandlerFan</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) &lt;= 1'>Expected 0 or 1 element(s) for xpath: FanPower</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:VentilationOnlyModeAirflowFraction) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/VentilationOnlyModeAirflowFraction</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:VentilationOnlyModeAirflowFraction) &gt;= 0 or not(h:extension/h:VentilationOnlyModeAirflowFraction)'>Expected extension/VentilationOnlyModeAirflowFraction to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:VentilationOnlyModeAirflowFraction) &lt;= 1 or not(h:extension/h:VentilationOnlyModeAirflowFraction)'>Expected extension/VentilationOnlyModeAirflowFraction to be less than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CFISAdditionalRuntimeMode=SupplementalFan]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply" and h:CFISControls/h:AdditionalRuntimeOperatingMode="supplemental fan"]'>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:SupplementalFan) = 1'>Expected 1 element(s) for xpath: CFISControls/SupplementalFan</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:extension/h:SupplementalFanRunsWithAirHandlerFan) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CFISControls/extension/SupplementalFanRunsWithAirHandlerFan</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) = 0'>Expected 0 element(s) for xpath: FanPower</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:VentilationOnlyModeAirflowFraction) = 0'>Expected 0 element(s) for xpath: extension/VentilationOnlyModeAirflowFraction</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CFISAdditionalRuntimeMode=None]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply" and h:CFISControls/h:AdditionalRuntimeOperatingMode="none"]'>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:SupplementalFan) = 0'>Expected 0 element(s) for xpath: CFISControls/SupplementalFan</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:extension/h:SupplementalFanRunsWithAirHandlerFan) = 0'>Expected 0 element(s) for xpath: CFISControls/extension/SupplementalFanRunsWithAirHandlerFan</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) = 0'>Expected 0 element(s) for xpath: FanPower</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:VentilationOnlyModeAirflowFraction) = 0'>Expected 0 element(s) for xpath: extension/VentilationOnlyModeAirflowFraction</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(h:FractionRecirculation) = 1'>Expected 1 element(s) for xpath: FractionRecirculation</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:InUnitFlowRate) = 1'>Expected 1 element(s) for xpath: extension/InUnitFlowRate</sch:assert>
      <sch:assert role='ERROR' test='number(h:RatedFlowRate) &gt; number(h:extension/h:InUnitFlowRate) or not(h:RatedFlowRate) or not(h:extension/h:InUnitFlowRate)'>Expected RatedFlowRate to be greater than extension/InUnitFlowRate</sch:assert>
      <sch:assert role='ERROR' test='number(h:CalculatedFlowRate) &gt; number(h:extension/h:InUnitFlowRate) or not(h:CalculatedFlowRate) or not(h:extension/h:InUnitFlowRate)'>Expected CalculatedFlowRate to be greater than extension/InUnitFlowRate</sch:assert>
      <sch:assert role='ERROR' test='number(h:TestedFlowRate) &gt; number(h:extension/h:InUnitFlowRate) or not(h:TestedFlowRate) or not(h:extension/h:InUnitFlowRate)'>Expected TestedFlowRate to be greater than extension/InUnitFlowRate</sch:assert>
      <sch:assert role='ERROR' test='number(h:DeliveredVentilation) &gt; number(h:extension/h:InUnitFlowRate) or not(h:DeliveredVentilation) or not(h:extension/h:InUnitFlowRate)'>Expected DeliveredVentilation to be greater than extension/InUnitFlowRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PreHeating) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/PreHeating</sch:assert> <!-- See [MechanicalVentilationType=SharedWithPreHeating] -->
      <sch:assert role='ERROR' test='count(h:extension/h:PreCooling) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/PreCooling</sch:assert> <!-- See [MechanicalVentilationType=SharedWithPreCooling] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=SharedWithPreHeating]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:IsSharedSystem="true"]/h:extension/h:PreHeating'>
      <sch:assert role='ERROR' test='count(../../h:FanType[text()="exhaust only"]) = 0'>Expected 0 element(s) for xpath: ../../FanType[text()="exhaust only"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Fuel) = 1'>Expected 1 element(s) for xpath: Fuel</sch:assert>
      <sch:assert role='ERROR' test='h:Fuel[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"] or not(h:Fuel)'>Expected Fuel to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualHeatingEfficiency[Units="COP"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionVentilationHeatLoadServed) = 1'>Expected 1 element(s) for xpath: FractionVentilationHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:FractionVentilationHeatLoadServed) &gt;= 0 or not(h:FractionVentilationHeatLoadServed)'>Expected FractionVentilationHeatLoadServed to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:FractionVentilationHeatLoadServed) &lt;= 1 or not(h:FractionVentilationHeatLoadServed)'>Expected FractionVentilationHeatLoadServed to be less than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=SharedWithPreCooling]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:IsSharedSystem="true"]/h:extension/h:PreCooling'>
      <sch:assert role='ERROR' test='count(../../h:FanType[text()="exhaust only"]) = 0'>Expected 0 element(s) for xpath: ../../FanType[text()="exhaust only"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Fuel) = 1'>Expected 1 element(s) for xpath: Fuel</sch:assert>
      <sch:assert role='ERROR' test='h:Fuel[text()="electricity"] or not(h:Fuel)'>Expected Fuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected 1 element(s) for xpath: AnnualCoolingEfficiency[Units="COP"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionVentilationCoolLoadServed) = 1'>Expected 1 element(s) for xpath: FractionVentilationCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:FractionVentilationCoolLoadServed) &gt;= 0 or not(h:FractionVentilationCoolLoadServed)'>Expected FractionVentilationCoolLoadServed to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:FractionVentilationCoolLoadServed) &lt;= 1 or not(h:FractionVentilationCoolLoadServed)'>Expected FractionVentilationCoolLoadServed to be less than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocalVentilation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForLocalVentilation="true"]'>
      <sch:assert role='ERROR' test='count(h:Count) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Count</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedFlowRate) + count(h:CalculatedFlowRate) + count(h:TestedFlowRate) + count(h:DeliveredVentilation) &gt;= 0'>Expected 0 or more element(s) for xpath: RatedFlowRate | CalculatedFlowRate | TestedFlowRate | DeliveredVentilation</sch:assert>
      <sch:assert role='ERROR' test='count(h:HoursInOperation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HoursInOperation</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanLocation) = 1'>Expected 1 element(s) for xpath: FanLocation</sch:assert>
      <sch:assert role='ERROR' test='h:FanLocation[text()="kitchen" or text()="bath"] or not(h:FanLocation)'>Expected FanLocation to be 'kitchen' or 'bath'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) &lt;= 1'>Expected 0 or 1 element(s) for xpath: FanPower</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:StartHour) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/StartHour</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:StartHour) &gt;= 0 or not(h:extension/h:StartHour)'>Expected extension/StartHour to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:StartHour) &lt;= 23 or not(h:extension/h:StartHour)'>Expected extension/StartHour to be less than or equal to 23</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WholeHouseFan]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForSeasonalCoolingLoadReduction="true"]'>
      <sch:assert role='ERROR' test='count(h:RatedFlowRate) + count(h:CalculatedFlowRate) + count(h:TestedFlowRate) + count(h:DeliveredVentilation) &gt;= 0'>Expected 0 or more element(s) for xpath: RatedFlowRate | CalculatedFlowRate | TestedFlowRate | DeliveredVentilation</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) &lt;= 1'>Expected 0 or 1 element(s) for xpath: FanPower</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[GarageVentilation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForGarageVentilation="true"]'>
      <!-- Warnings -->
      <sch:report role='WARN' test='true()'>Ventilation fans for the garage are not currently modeled.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem'>
      <sch:assert role='ERROR' test='count(../h:HotWaterDistribution) = 1'>Expected 1 element(s) for xpath: ../HotWaterDistribution</sch:assert> <!-- See [HotWaterDistribution] -->
      <sch:assert role='ERROR' test='count(../h:WaterFixture) &gt;= 1'>Expected 1 or more element(s) for xpath: ../WaterFixture</sch:assert> <!-- See [WaterFixture] -->
      <sch:assert role='ERROR' test='count(h:WaterHeaterType) = 1'>Expected 1 element(s) for xpath: WaterHeaterType</sch:assert> <!-- See [WaterHeatingSystemType=Tank] or [WaterHeatingSystemType=Tankless] or [WaterHeatingSystemType=HeatPump] or [WaterHeatingSystemType=CombiIndirect] or [WaterHeatingSystemType=CombiTanklessCoil] -->
      <sch:assert role='ERROR' test='h:WaterHeaterType[text()="storage water heater" or text()="instantaneous water heater" or text()="heat pump water heater" or text()="space-heating boiler with storage tank" or text()="space-heating boiler with tankless coil"] or not(h:WaterHeaterType)'>Expected WaterHeaterType to be 'storage water heater' or 'instantaneous water heater' or 'heat pump water heater' or 'space-heating boiler with storage tank' or 'space-heating boiler with tankless coil'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=Tank]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="storage water heater"]'>
      <sch:assert role='ERROR' test='count(h:FuelType) = 1'>Expected 1 element(s) for xpath: FuelType</sch:assert>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"] or not(h:FuelType)'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [WaterHeatingSystem=Shared] -->
      <sch:assert role='ERROR' test='count(h:TankVolume) &lt;= 1'>Expected 0 or 1 element(s) for xpath: TankVolume</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected 1 element(s) for xpath: FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatingCapacity) &gt; 0 or not(h:HeatingCapacity)'>Expected HeatingCapacity to be greater than 0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:UniformEnergyFactor) + count(h:EnergyFactor) = 1'>Expected 1 element(s) for xpath: UniformEnergyFactor | EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:UniformEnergyFactor) &lt; 1 or not(h:UniformEnergyFactor)'>Expected UniformEnergyFactor to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:EnergyFactor) &lt; 1 or not(h:EnergyFactor)'>Expected EnergyFactor to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsageBin) + count(h:FirstHourRating) &gt;= 0'>Expected 0 or more element(s) for xpath: UsageBin | FirstHourRating</sch:assert>
      <sch:assert role='ERROR' test='count(h:RecoveryEfficiency) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='number(h:RecoveryEfficiency) &gt; number(h:EnergyFactor) or not(h:RecoveryEfficiency) or not (h:EnergyFactor)'>Expected RecoveryEfficiency to be greater than EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:RecoveryEfficiency) &gt; number(h:UniformEnergyFactor) or not(h:RecoveryEfficiency) or not (h:UniformEnergyFactor)'>Expected RecoveryEfficiency to be greater than UniformEnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:WaterHeaterInsulation/h:Jacket/h:JacketRValue) &lt;= 1'>Expected 0 or 1 element(s) for xpath: WaterHeaterInsulation/Jacket/JacketRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:HotWaterTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HotWaterTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsesDesuperheater) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UsesDesuperheater</sch:assert> <!-- See [Desuperheater] -->
      <sch:assert role='ERROR' test='count(h:extension/h:TankModelType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/TankModelType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:TankModelType[text()="mixed" or text()="stratified"] or not(h:extension/h:TankModelType)'>Expected extension/TankModelType to be 'mixed' or 'stratified'</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:UniformEnergyFactor) &lt; 0.45'>UniformEnergyFactor should typically be greater than or equal to 0.45.</sch:report>
      <sch:report role='WARN' test='number(h:EnergyFactor) &lt; 0.45'>EnergyFactor should typically be greater than or equal to 0.45.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt;= 1000 and number(h:HeatingCapacity) &gt; 0'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='number(h:HotWaterTemperature) &lt; 110'>Hot water setpoint should typically be greater than or equal to 110 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=NonElectricTank]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="storage water heater" and h:FuelType!="electricity"]'>
      <sch:assert role='ERROR' test='count(h:extension/h:TankModelType[text()="stratified"]) = 0'>Expected 0 element(s) for xpath: extension/TankModelType</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=Tankless]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="instantaneous water heater"]'>
      <sch:assert role='ERROR' test='count(h:FuelType) = 1'>Expected 1 element(s) for xpath: FuelType</sch:assert>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"] or not(h:FuelType)'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [WaterHeatingSystem=Shared] -->
      <sch:assert role='ERROR' test='count(h:PerformanceAdjustment) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PerformanceAdjustment</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected 1 element(s) for xpath: FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:UniformEnergyFactor) + count(h:EnergyFactor) = 1'>Expected 1 element(s) for xpath: UniformEnergyFactor | EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:UniformEnergyFactor) &lt; 1 or not(h:UniformEnergyFactor)'>Expected UniformEnergyFactor to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:EnergyFactor) &lt; 1 or not(h:EnergyFactor)'>Expected EnergyFactor to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:HotWaterTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HotWaterTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsesDesuperheater) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UsesDesuperheater</sch:assert> <!-- See [Desuperheater] -->
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:UniformEnergyFactor) &lt; 0.45'>UniformEnergyFactor should typically be greater than or equal to 0.45.</sch:report>
      <sch:report role='WARN' test='number(h:EnergyFactor) &lt; 0.45'>EnergyFactor should typically be greater than or equal to 0.45.</sch:report>
      <sch:report role='WARN' test='number(h:HotWaterTemperature) &lt; 110'>Hot water setpoint should typically be greater than or equal to 110 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=HeatPump]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="heat pump water heater"]'>
      <sch:assert role='ERROR' test='count(h:FuelType[text()="electricity"]) = 1'>Expected 1 element(s) for xpath: FuelType[text()="electricity"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [WaterHeatingSystem=Shared] -->
      <sch:assert role='ERROR' test='count(h:TankVolume) &lt;= 1'>Expected 0 or 1 element(s) for xpath: TankVolume</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected 1 element(s) for xpath: FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatingCapacity) &gt; 0 or not(h:HeatingCapacity)'>Expected HeatingCapacity to be greater than 0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupHeatingCapacity) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BackupHeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:UniformEnergyFactor) + count(h:EnergyFactor) = 1'>Expected 1 element(s) for xpath: UniformEnergyFactor | EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:UniformEnergyFactor) &gt; 1 or not(h:UniformEnergyFactor)'>Expected UniformEnergyFactor to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:EnergyFactor) &gt; 1 or not(h:EnergyFactor)'>Expected EnergyFactor to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:HPWHOperatingMode) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HPWHOperatingMode</sch:assert>
      <sch:assert role='ERROR' test='h:HPWHOperatingMode[text()="hybrid/auto" or text()="heat pump only"] or not(h:HPWHOperatingMode)'>Expected HPWHOperatingMode to be 'hybrid/auto' or 'heat pump only'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HPWHDucting/h:ExhaustAirTermination) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HPWHDucting/ExhaustAirTermination</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsageBin) + count(h:FirstHourRating) &gt;= 0'>Expected 0 or more element(s) for xpath: UsageBin | FirstHourRating</sch:assert>
      <sch:assert role='ERROR' test='count(h:WaterHeaterInsulation/h:Jacket/h:JacketRValue) &lt;= 1'>Expected 0 or 1 element(s) for xpath: WaterHeaterInsulation/Jacket/JacketRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:HotWaterTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HotWaterTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsesDesuperheater) &lt;= 1'>Expected 0 or 1 element(s) for xpath: UsesDesuperheater</sch:assert> <!-- See [Desuperheater] -->
      <sch:assert role='ERROR' test='count(h:extension/h:HPWHInConfinedSpaceWithoutMitigation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/HPWHInConfinedSpaceWithoutMitigation</sch:assert> <!-- See [HPWHInConfinedSpaceWithoutMitigation] -->
      <sch:assert role='ERROR' test='h:extension/h:HPWHInConfinedSpaceWithoutMitigation[text()="true" or text()="false"] or not(h:extension/h:HPWHInConfinedSpaceWithoutMitigation)'>Expected extension/HPWHInConfinedSpaceWithoutMitigation to be 'true' or 'false'</sch:assert>
      <!-- Moved/deprecated extension/OperatingMode input; see https://github.com/NREL/OpenStudio-HPXML/pull/1289 -->
      <sch:assert role='ERROR' test='count(h:extension/h:OperatingMode) = 0'>extension/OperatingMode has been replaced by HPWHOperatingMode</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:HotWaterTemperature) &lt; 110'>Hot water setpoint should typically be greater than or equal to 110 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HPWHInConfinedSpaceWithoutMitigation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem/h:extension[h:HPWHInConfinedSpaceWithoutMitigation="true"]'>
      <sch:assert role='ERROR' test='count(h:HPWHContainmentVolume) = 1'>Expected 1 element(s) for xpath: HPWHContainmentVolume</sch:assert>
      <sch:assert role='ERROR' test='number(h:HPWHContainmentVolume) &gt; 0 or not(h:HPWHContainmentVolume)'>Expected HPWHContainmentVolume to be greater than 0.</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:HPWHContainmentVolume) &gt; 1500'>HPWHContainmentVolume should typically be less than 1500 cuft when the HPWH is in confined space.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=CombiIndirect]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="space-heating boiler with storage tank"]'>
      <sch:assert role='ERROR' test='count(h:FuelType) = 0'>Expected 0 element(s) for xpath: FuelType</sch:assert>
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [WaterHeatingSystem=Shared] -->
      <sch:assert role='ERROR' test='count(h:TankVolume) &lt;= 1'>Expected 0 or 1 element(s) for xpath: TankVolume</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected 1 element(s) for xpath: FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 0'>Expected 0 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:UniformEnergyFactor) = 0'>Expected 0 element(s) for xpath: UniformEnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:EnergyFactor) = 0'>Expected 0 element(s) for xpath: EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:RecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: RecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:WaterHeaterInsulation/h:Jacket/h:JacketRValue) &lt;= 1'>Expected 0 or 1 element(s) for xpath: WaterHeaterInsulation/Jacket/JacketRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:StandbyLoss[h:Units="F/hr"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: StandbyLoss[Units="F/hr"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:HotWaterTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HotWaterTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsesDesuperheater[text()="true"]) = 0'>Expected 0 element(s) for xpath: UsesDesuperheater=true</sch:assert>
      <sch:assert role='ERROR' test='count(h:RelatedHVACSystem) = 1'>Expected 1 element(s) for xpath: RelatedHVACSystem</sch:assert> <!-- See [HeatingSystem] (boiler) -->
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:HotWaterTemperature) &lt; 110'>Hot water setpoint should typically be greater than or equal to 110 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=CombiTanklessCoil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="space-heating boiler with tankless coil"]'>
      <sch:assert role='ERROR' test='count(h:FuelType) = 0'>Expected 0 element(s) for xpath: FuelType</sch:assert>
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [WaterHeatingSystem=Shared] -->
      <sch:assert role='ERROR' test='count(h:TankVolume) = 0'>Expected 0 element(s) for xpath: TankVolume</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected 1 element(s) for xpath: FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 0'>Expected 0 element(s) for xpath: HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:UniformEnergyFactor) = 0'>Expected 0 element(s) for xpath: UniformEnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:EnergyFactor) = 0'>Expected 0 element(s) for xpath: EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:RecoveryEfficiency) = 0'>Expected 0 element(s) for xpath: RecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:WaterHeaterInsulation/h:Jacket/h:JacketRValue) = 0'>Expected 0 element(s) for xpath: WaterHeaterInsulation/Jacket/JacketRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:StandbyLoss[h:Units="F/hr"]/h:Value) = 0'>Expected 0 element(s) for xpath: StandbyLoss[Units="F/hr"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:HotWaterTemperature) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HotWaterTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsesDesuperheater[text()="true"]) = 0'>Expected 0 element(s) for xpath: UsesDesuperheater=true</sch:assert>
      <sch:assert role='ERROR' test='count(h:RelatedHVACSystem) = 1'>Expected 1 element(s) for xpath: RelatedHVACSystem</sch:assert> <!-- See [HeatingSystem] (boiler) -->
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:HotWaterTemperature) &lt; 110'>Hot water setpoint should typically be greater than or equal to 110 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystem=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:NumberofBedroomsServed) = 1'>Expected 1 element(s) for xpath: extension/NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:NumberofBedroomsServed) &gt; number(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:extension/h:NumberofBedroomsServed) or not(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected extension/NumberofBedroomsServed to be greater than ../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Desuperheater]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:UsesDesuperheater="true"]'>
      <sch:assert role='ERROR' test='count(h:RelatedHVACSystem) = 1'>Expected 1 element(s) for xpath: RelatedHVACSystem</sch:assert> <!-- See [HeatPump] or [CoolingSystem] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HotWaterDistribution]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution'>
      <sch:assert role='ERROR' test='count(h:SystemType/h:Standard) + count(h:SystemType/h:Recirculation) = 1'>Expected 1 element(s) for xpath: SystemType/Standard | SystemType/Recirculation</sch:assert> <!-- See [HotWaterDistributionType=Standard] or [HotWaterDistributionType=Recirculation] -->
      <sch:assert role='ERROR' test='count(h:PipeInsulation/h:PipeRValue) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PipeInsulation/PipeRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:DrainWaterHeatRecovery) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DrainWaterHeatRecovery</sch:assert> <!-- See [DrainWaterHeatRecovery] -->
      <sch:assert role='ERROR' test='count(h:extension/h:SharedRecirculation) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/SharedRecirculation</sch:assert> <!-- See [HotWaterDistributionType=SharedRecirculation] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HotWaterDistributionType=Standard]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution/h:SystemType/h:Standard'>
      <sch:assert role='ERROR' test='count(h:PipingLength) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PipingLength</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HotWaterDistributionType=Recirculation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution/h:SystemType/h:Recirculation'>
      <sch:assert role='ERROR' test='count(h:ControlType) = 1'>Expected 1 element(s) for xpath: ControlType</sch:assert>
      <sch:assert role='ERROR' test='h:ControlType[text()="manual demand control" or text()="presence sensor demand control" or text()="temperature" or text()="timer" or text()="no control"] or not(h:ControlType)'>Expected ControlType to be 'manual demand control' or 'presence sensor demand control' or 'temperature' or 'timer' or 'no control'</sch:assert>
      <sch:assert role='ERROR' test='count(h:RecirculationPipingLoopLength) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RecirculationPipingLoopLength</sch:assert>
      <sch:assert role='ERROR' test='count(h:BranchPipingLength) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BranchPipingLength</sch:assert>
      <sch:assert role='ERROR' test='count(h:PumpPower) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PumpPower</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:extension/h:RecirculationPumpWeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../../extension/RecirculationPumpWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:extension/h:RecirculationPumpWeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../../extension/RecirculationPumpWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:extension/h:RecirculationPumpMonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../../extension/RecirculationPumpMonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HotWaterDistributionType=SharedRecirculation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution/h:extension/h:SharedRecirculation'>
      <sch:assert role='ERROR' test='count(../../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:SystemType/h:Standard) = 1'>Expected 1 element(s) for xpath: ../../SystemType/Standard</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofBedroomsServed) = 1'>Expected 1 element(s) for xpath: NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofBedroomsServed) &gt; number(../../../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:NumberofBedroomsServed) or not(../../../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected NumberofBedroomsServed to be greater than ../../../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
      <sch:assert role='ERROR' test='count(h:PumpPower) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PumpPower</sch:assert>
      <sch:assert role='ERROR' test='count(h:ControlType) = 1'>Expected 1 element(s) for xpath: ControlType</sch:assert>
      <sch:assert role='ERROR' test='h:ControlType[text()="manual demand control" or text()="presence sensor demand control" or text()="temperature" or text()="timer" or text()="no control"] or not(h:ControlType)'>Expected ControlType to be 'manual demand control' or 'presence sensor demand control' or 'temperature' or 'timer' or 'no control'</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:extension/h:RecirculationPumpWeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../../extension/RecirculationPumpWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:extension/h:RecirculationPumpWeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../../extension/RecirculationPumpWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:extension/h:RecirculationPumpMonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../../extension/RecirculationPumpMonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DrainWaterHeatRecovery]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution/h:DrainWaterHeatRecovery'>
      <sch:assert role='ERROR' test='count(h:FacilitiesConnected) = 1'>Expected 1 element(s) for xpath: FacilitiesConnected</sch:assert>
      <sch:assert role='ERROR' test='count(h:EqualFlow) = 1'>Expected 1 element(s) for xpath: EqualFlow</sch:assert>
      <sch:assert role='ERROR' test='count(h:Efficiency) = 1'>Expected 1 element(s) for xpath: Efficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterFixture]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterFixture'>
      <sch:assert role='ERROR' test='count(../h:HotWaterDistribution) = 1'>Expected 1 element(s) for xpath: ../HotWaterDistribution</sch:assert> <!-- See [HotWaterDistribution] -->
      <sch:assert role='ERROR' test='count(h:WaterFixtureType) = 1'>Expected 1 element(s) for xpath: WaterFixtureType</sch:assert>
      <sch:assert role='ERROR' test='h:WaterFixtureType[text()="shower head" or text()="faucet"] or not(h:WaterFixtureType)'>Expected WaterFixtureType to be 'shower head' or 'faucet'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Count) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Count</sch:assert>
      <sch:assert role='ERROR' test='count(h:LowFlow | h:FlowRate) &gt;= 1'>Expected 1 or more element(s) for xpath: LowFlow | FlowRate</sch:assert>
      <sch:assert role='ERROR' test='count(../h:extension/h:WaterFixturesUsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../extension/WaterFixturesUsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(../h:extension/h:WaterFixturesUsageMultiplier) &gt;= 0 or not(../h:extension/h:WaterFixturesUsageMultiplier)'>Expected ../extension/WaterFixturesUsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(../h:extension/h:WaterFixturesWeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../extension/WaterFixturesWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(../h:extension/h:WaterFixturesWeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../extension/WaterFixturesWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(../h:extension/h:WaterFixturesMonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../extension/WaterFixturesMonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SolarThermalSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:SolarThermal/h:SolarThermalSystem'>
      <sch:assert role='ERROR' test='count(h:CollectorArea) + count(h:SolarFraction) = 1'>Expected 1 element(s) for xpath: CollectorArea | SolarFraction</sch:assert> <!-- See [SolarThermalSystemType=Detailed] or [SolarThermalSystemType=Simple] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SolarThermalSystemType=Detailed]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:SolarThermal/h:SolarThermalSystem[h:CollectorArea]'>
      <sch:assert role='ERROR' test='count(h:SystemType) = 1'>Expected 1 element(s) for xpath: SystemType</sch:assert>
      <sch:assert role='ERROR' test='h:SystemType[text()="hot water"] or not(h:SystemType)'>Expected SystemType to be 'hot water'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorLoopType) = 1'>Expected 1 element(s) for xpath: CollectorLoopType</sch:assert>
      <sch:assert role='ERROR' test='h:CollectorLoopType[text()="liquid indirect" or text()="liquid direct" or text()="passive thermosyphon"] or not(h:CollectorLoopType)'>Expected CollectorLoopType to be 'liquid indirect' or 'liquid direct' or 'passive thermosyphon'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorType) = 1'>Expected 1 element(s) for xpath: CollectorType</sch:assert>
      <sch:assert role='ERROR' test='h:CollectorType[text()="single glazing black" or text()="double glazing black" or text()="evacuated tube" or text()="integrated collector storage"] or not(h:CollectorType)'>Expected CollectorType to be 'single glazing black' or 'double glazing black' or 'evacuated tube' or 'integrated collector storage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorAzimuth) + count(h:CollectorOrientation) &gt;= 1'>Expected 1 or more element(s) for xpath: CollectorAzimuth | CollectorOrientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorTilt) = 1'>Expected 1 element(s) for xpath: CollectorTilt</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorRatedOpticalEfficiency) = 1'>Expected 1 element(s) for xpath: CollectorRatedOpticalEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorRatedThermalLosses) = 1'>Expected 1 element(s) for xpath: CollectorRatedThermalLosses</sch:assert>
      <sch:assert role='ERROR' test='count(h:StorageVolume) &lt;= 1'>Expected 0 or 1 element(s) for xpath: StorageVolume</sch:assert>
      <sch:assert role='ERROR' test='count(h:ConnectedTo) = 1'>Expected 1 element(s) for xpath: ConnectedTo</sch:assert> <!-- See [WaterHeatingSystem] (any type but space-heating boiler) -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SolarThermalSystemType=Simple]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:SolarThermal/h:SolarThermalSystem[h:SolarFraction]'>
      <sch:assert role='ERROR' test='count(h:SystemType) = 1'>Expected 1 element(s) for xpath: SystemType</sch:assert>
      <sch:assert role='ERROR' test='h:SystemType[text()="hot water"] or not(h:SystemType)'>Expected SystemType to be 'hot water'</sch:assert>
      <sch:assert role='ERROR' test='number(h:SolarFraction) &lt;= 0.99 or not(h:SolarFraction)'>Expected SolarFraction to be less than or equal to 0.99</sch:assert>
      <sch:assert role='ERROR' test='count(h:ConnectedTo) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ConnectedTo</sch:assert> <!-- See [WaterHeatingSystem] (any type) -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Photovoltaics/h:PVSystem'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [PVSystemType=Shared] -->
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="ground" or text()="roof"] or not(h:Location)'>Expected Location to be 'ground' or 'roof'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ModuleType) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ModuleType</sch:assert>
      <sch:assert role='ERROR' test='h:ModuleType[text()="standard" or text()="premium" or text()="thin film"] or not(h:ModuleType)'>Expected ModuleType to be 'standard' or 'premium' or 'thin film'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Tracking) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Tracking</sch:assert>
      <sch:assert role='ERROR' test='h:Tracking[text()="fixed" or text()="1-axis" or text()="1-axis backtracked" or text()="2-axis"] or not(h:Tracking)'>Expected Tracking to be 'fixed' or '1-axis' or '1-axis backtracked' or '2-axis'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ArrayAzimuth) + count(h:ArrayOrientation) &gt;= 1'>Expected 1 or more element(s) for xpath: ArrayAzimuth | ArrayOrientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:ArrayTilt) = 1'>Expected 1 element(s) for xpath: ArrayTilt</sch:assert>
      <sch:assert role='ERROR' test='count(h:MaxPowerOutput) = 1'>Expected 1 element(s) for xpath: MaxPowerOutput</sch:assert>
      <sch:assert role='ERROR' test='count(h:SystemLossesFraction) + count(h:YearModulesManufactured) &gt;= 0'>Expected 0 or more element(s) for xpath: SystemLossesFraction | YearModulesManufactured</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:MaxPowerOutput) &lt;= 500 and number(h:MaxPowerOutput) &gt; 0'>Max power output should typically be greater than or equal to 500 W.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVSystemType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Photovoltaics/h:PVSystem[h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:NumberofBedroomsServed) = 1'>Expected 1 element(s) for xpath: extension/NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:NumberofBedroomsServed) &gt; number(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:extension/h:NumberofBedroomsServed) or not(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected extension/NumberofBedroomsServed to be greater than ../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVSystemWithMultipleInverters]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Photovoltaics/h:PVSystem[count(../h:Inverter) &gt; 1]'>
      <sch:assert role='ERROR' test='count(h:AttachedToInverter) = 1'>Expected 1 element(s) for xpath: AttachedToInverter</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Inverter]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Photovoltaics/h:Inverter'>
      <sch:assert role='ERROR' test='count(h:InverterEfficiency) &lt;= 1'>Expected 0 or 1 element(s) for xpath: InverterEfficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ElectricPanel]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:ElectricPanels/h:ElectricPanel'>
      <sch:assert role='ERROR' test='count(h:Voltage) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Voltage</sch:assert>
      <sch:assert role='ERROR' test='h:Voltage[text()="120" or text()="240"] or not(h:Voltage)'>Expected Voltage to be '120' or '240'</sch:assert>
      <sch:assert role='ERROR' test='count(h:MaxCurrentRating) &lt;= 1'>Expected 0 or 1 element(s) for xpath: MaxCurrentRating</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeadroomSpaces) &lt;= 1'>Expected 0 or 1 element(s) for xpath: HeadroomSpaces</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedTotalSpaces) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RatedTotalSpaces</sch:assert>
      <sch:assert role='ERROR' test='count(h:BranchCircuits) &lt;= 1'>Expected 0 or 1 element(s) for xpath: BranchCircuits</sch:assert> <!-- See [BranchCircuit]-->
      <sch:assert role='ERROR' test='count(h:ServiceFeeders) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ServiceFeeders</sch:assert> <!-- See [ServiceFeeder]-->
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:MaxCurrentRating) &gt; 400'>MaxCurrentRating should typically be less than or equal to 400.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BranchCircuit]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:ElectricPanels/h:ElectricPanel/h:BranchCircuits/h:BranchCircuit'>
      <sch:assert role='ERROR' test='count(h:Voltage) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Voltage</sch:assert>
      <sch:assert role='ERROR' test='h:Voltage[text()="120" or text()="240"] or not(h:Voltage)'>Expected Voltage to be '120' or '240'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Voltage[text()="240"]) + count(../../../h:ElectricPanel[h:Voltage[text()="120"]]) &lt; 2'>Expected ../../../ElectricPanel/Voltage to be '240'</sch:assert>
      <sch:assert role='ERROR' test='count(h:MaxCurrentRating) &lt;= 1'>Expected 0 or 1 element(s) for xpath: MaxCurrentRating</sch:assert>
      <sch:assert role='ERROR' test='count(h:OccupiedSpaces) &lt;= 1'>Expected 0 or 1 element(s) for xpath: OccupiedSpaces</sch:assert>
      <sch:assert role='ERROR' test='h:OccupiedSpaces[text()="0.0" or text()="0.5" or text()="1.0" or text()="2.0"] or not(h:OccupiedSpaces)'>Expected OccupiedSpaces to be '0.0' or '0.5' or '1.0' or '2.0'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToComponent) &gt;= 0'>Expected 0 or more element(s) for xpath: AttachedToComponent</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ServiceFeeder]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:ElectricPanels/h:ElectricPanel/h:ServiceFeeders/h:ServiceFeeder'>
      <sch:assert role='ERROR' test='count(h:LoadType) = 1'>Expected 1 element(s) for xpath: LoadType</sch:assert>
      <sch:assert role='ERROR' test='count(h:LoadType[text()="heating" or text()="cooling" or text()="hot water" or text()="clothes dryer" or text()="dishwasher" or text()="range/oven" or text()="mech vent" or text()="permanent spa heater" or text()="permanent spa pump" or text()="pool heater" or text()="pool pump" or text()="well pump" or text()="electric vehicle charging" or text()="lighting" or text()="kitchen" or text()="laundry" or text()="other"]) = 1 or not(h:LoadType)'>Expected LoadType to be 'heating' or 'cooling' or 'hot water' or 'clothes dryer' or 'dishwasher' or 'range/oven' or 'mech vent' or 'permanent spa heater' or 'permanent spa pump' or 'pool heater' or 'pool pump' or 'well pump' or 'electric vehicle charging' or 'lighting' or 'kitchen' or 'laundry' or 'other'</sch:assert>
      <sch:assert role='ERROR' test='count(h:PowerRating) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PowerRating</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsNewLoad) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsNewLoad</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToComponent) &gt;= 0'>Expected 0 or more element(s) for xpath: AttachedToComponent</sch:assert>
      <sch:assert role='ERROR' test='count(h:LoadType[text()="heating" or text()="cooling" or text()="hot water" or text()="clothes dryer" or text()="dishwasher" or text()="range/oven" or text()="mech vent" or text()="permanent spa heater" or text()="permanent spa pump" or text()="pool heater" or text()="pool pump" or text()="well pump" or text()="electric vehicle charging"]) + count(h:AttachedToComponent) &gt;= 2 or count(h:LoadType[text()="lighting" or text()="kitchen" or text()="laundry" or text()="other"]) = 1 or not(h:LoadType)'>Expected 1 or more element(s) for xpath: AttachedToComponent</sch:assert>
      <sch:assert role='ERROR' test='count(h:LoadType[text()="lighting" or text()="kitchen" or text()="laundry" or text()="other"]) + count(h:AttachedToComponent) = 1 or count(h:LoadType[text()="heating" or text()="cooling" or text()="hot water" or text()="clothes dryer" or text()="dishwasher" or text()="range/oven" or text()="mech vent" or text()="permanent spa heater" or text()="permanent spa pump" or text()="pool heater" or text()="pool pump" or text()="well pump" or text()="electric vehicle charging"]) = 1 or not(h:LoadType)'>Expected 0 element(s) for xpath: AttachedToComponent</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Battery]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Batteries/h:Battery'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [BatteryType=Shared] -->
      <sch:assert role='ERROR' test='count(h:BatteryType[text()="Li-ion"]) = 1'>Expected 1 element(s) for xpath: BatteryType[text()="Li-ion"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="attic - vented" or text()="attic - unvented" or text()="garage" or text()="outside"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'attic - vented' or 'attic - unvented' or 'garage' or 'outside'</sch:assert>
      <sch:assert role='ERROR' test='count(h:NominalCapacity[h:Units="kWh" or h:Units="Ah"]/h:Value) &gt;= 0'>Expected 0 or more element(s) for xpath: NominalCapacity[Units="kWh" or Units="Ah"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsableCapacity[h:Units="kWh" or h:Units="Ah"]/h:Value) &gt;= 0'>Expected 0 or more element(s) for xpath: UsableCapacity[Units="kWh" or Units="Ah"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:UsableCapacity[h:Units="kWh"]/h:Value) &lt; number(h:NominalCapacity[h:Units="kWh"]/h:Value) or not(h:UsableCapacity[h:Units="kWh"]/h:Value) or not(h:NominalCapacity[h:Units="kWh"]/h:Value)'>Expected UsableCapacity to be less than NominalCapacity</sch:assert>
      <sch:assert role='ERROR' test='number(h:UsableCapacity[h:Units="Ah"]/h:Value) &lt; number(h:NominalCapacity[h:Units="Ah"]/h:Value) or not(h:UsableCapacity[h:Units="Ah"]/h:Value) or not(h:NominalCapacity[h:Units="Ah"]/h:Value)'>Expected UsableCapacity to be less than NominalCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedPowerOutput) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RatedPowerOutput</sch:assert>
      <sch:assert role='ERROR' test='count(h:NominalVoltage) &lt;= 1'>Expected 0 or 1 element(s) for xpath: NominalVoltage</sch:assert>
      <sch:assert role='ERROR' test='count(h:RoundTripEfficiency) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RoundTripEfficiency</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:RatedPowerOutput) &lt;= 1000 and number(h:RatedPowerOutput) &gt; 0'>Rated power output should typically be greater than or equal to 1000 W.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BatteryType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Batteries/h:Battery[h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:NumberofBedroomsServed) = 1'>Expected 1 element(s) for xpath: extension/NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:NumberofBedroomsServed) &gt; number(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:extension/h:NumberofBedroomsServed) or not(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected extension/NumberofBedroomsServed to be greater than ../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Vehicles]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Vehicles'>
     <sch:assert role='ERROR' test='count(h:Vehicle/h:VehicleType/h:BatteryElectricVehicle) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Vehicle/VehicleType/BatteryElectricVehicle</sch:assert> <!-- Only 1 BEV allowed currently -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Vehicle]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Vehicles/h:Vehicle'>
      <sch:assert role='ERROR' test='count(h:VehicleType) = 1'>Expected 1 element(s) for xpath: VehicleType</sch:assert> <!-- See [VehicleType=BEV] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[VehicleType=BEV]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Vehicles/h:Vehicle/h:VehicleType/h:BatteryElectricVehicle'>
      <sch:assert role='ERROR' test='count(h:Battery/h:BatteryType[text()="Li-ion"]) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Battery/BatteryType[text()="Li-ion"]</sch:assert>
      <sch:assert role='ERROR' test='h:Battery/h:BatteryType[text()="Li-ion"] or not(h:Battery/h:BatteryType)'>Expected Battery/BatteryType to be "Li-ion"</sch:assert>
      <sch:assert role='ERROR' test='count(h:Battery/h:NominalCapacity[h:Units="kWh" or h:Units="Ah"]/h:Value) &gt;= 0'>Expected 0 or more element(s) for xpath: Battery/NominalCapacity[Units="kWh" or Units="Ah"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:Battery/h:UsableCapacity[h:Units="kWh" or h:Units="Ah"]/h:Value) &gt;= 0'>Expected 0 or more element(s) for xpath: Battery/UsableCapacity[Units="kWh" or Units="Ah"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:Battery/h:UsableCapacity[h:Units="kWh"]/h:Value) &lt; number(h:Battery/h:NominalCapacity[h:Units="kWh"]/h:Value) or not(h:Battery/h:UsableCapacity[h:Units="kWh"]/h:Value) or not(h:Battery/h:NominalCapacity[h:Units="kWh"]/h:Value)'>Expected UsableCapacity to be less than NominalCapacity</sch:assert>
      <sch:assert role='ERROR' test='number(h:Battery/h:UsableCapacity[h:Units="Ah"]/h:Value) &lt; number(h:Battery/h:NominalCapacity[h:Units="Ah"]/h:Value) or not(h:Battery/h:UsableCapacity[h:Units="Ah"]/h:Value) or not(h:Battery/h:NominalCapacity[h:Units="Ah"]/h:Value)'>Expected UsableCapacity to be less than NominalCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:Battery/h:NominalVoltage) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Battery/NominalVoltage</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionChargedLocation[h:Location="Home"]/h:Percentage) &lt;= 1'>Expected 0 or 1 element(s) for xpath: FractionChargedLocation[Location="Home"]/Percentage</sch:assert>
      <sch:assert role='ERROR' test='count(h:ConnectedCharger) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ConnectedCharger</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:MilesDrivenPerYear) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../../MilesDrivenPerYear</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HoursDrivenPerWeek) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../../HoursDrivenPerWeek</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:FuelEconomyCombined/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ../../FuelEconomyCombined/Value</sch:assert>
      <sch:assert role='ERROR' test='../../h:FuelEconomyCombined[h:Units="kWh/mile" or h:Units="mile/kWh" or h:Units="mpge"] or not(../../h:FuelEconomyCombined/h:Units)'>Expected ../../FuelEconomyCombined/Units to be "kWh/mile" or "mile/kWh" or "mpge"</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='count(../../../../../h:MiscLoads/h:PlugLoad[h:PlugLoadType[text()="electric vehicle charging"]]) &gt;= 1'>Electric vehicle charging was specified as both a PlugLoad and a Vehicle, the latter will be ignored.</sch:report>
      <sch:report role='WARN' test='count(h:ConnectedCharger) = 0'>Electric vehicle specified with no charger provided; home EV charging will not be modeled.</sch:report>
    </sch:rule>
  </sch:pattern>

    <sch:pattern>
    <sch:title>[ElectricVehicleCharger]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:ElectricVehicleChargers/h:ElectricVehicleCharger'>
      <sch:assert role='ERROR' test='count(h:ChargingLevel) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ChargingLevel</sch:assert>
      <sch:assert role='ERROR' test='count(h:ChargingPower) &lt;= 1'>Expected 0 or 1 element(s) for xpath: ChargingPower</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Generator]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:extension/h:Generators/h:Generator'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedSystem</sch:assert> <!-- See [GeneratorType=Shared] -->
      <sch:assert role='ERROR' test='count(h:FuelType) = 1'>Expected 1 element(s) for xpath: FuelType</sch:assert>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="wood" or text()="wood pellets"] or not(h:FuelType)'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualConsumptionkBtu) = 1'>Expected 1 element(s) for xpath: AnnualConsumptionkBtu</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualConsumptionkBtu) &gt; 0 or not(h:AnnualConsumptionkBtu)'>Expected AnnualConsumptionkBtu to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualOutputkWh) = 1'>Expected 1 element(s) for xpath: AnnualOutputkWh</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualOutputkWh) &gt; 0 or not(h:AnnualOutputkWh)'>Expected AnnualOutputkWh to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualConsumptionkBtu) &gt; (number(h:AnnualOutputkWh) * 3.412) or not(h:AnnualConsumptionkBtu) or not(h:AnnualOutputkWh)'>Expected AnnualConsumptionkBtu to be greater than AnnualOutputkWh*3412</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[GeneratorType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:extension/h:Generators/h:Generator[h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofBedroomsServed) = 1'>Expected 1 element(s) for xpath: NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofBedroomsServed) &gt; number(../../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:NumberofBedroomsServed) or not(../../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected NumberofBedroomsServed to be greater than ../../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesWasher]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesWasher'>
      <sch:assert role='ERROR' test='count(../../h:Systems/h:WaterHeating/h:HotWaterDistribution) = 1'>Expected 1 element(s) for xpath: ../../Systems/WaterHeating/HotWaterDistribution</sch:assert> <!-- See [HotWaterDistribution] -->
      <sch:assert role='ERROR' test='count(h:IsSharedAppliance) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedAppliance</sch:assert> <!-- See [ClothesWasherType=Shared] -->
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedModifiedEnergyFactor) + count(h:ModifiedEnergyFactor) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IntegratedModifiedEnergyFactor | ModifiedEnergyFactor</sch:assert> <!-- See [ClothesWasherType=Detailed] -->
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesWasherType=Detailed]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesWasher[h:IntegratedModifiedEnergyFactor | h:ModifiedEnergyFactor]'>
      <sch:assert role='ERROR' test='count(h:RatedAnnualkWh) = 1'>Expected 1 element(s) for xpath: RatedAnnualkWh</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelElectricRate) = 1'>Expected 1 element(s) for xpath: LabelElectricRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelGasRate) = 1'>Expected 1 element(s) for xpath: LabelGasRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelAnnualGasCost) = 1'>Expected 1 element(s) for xpath: LabelAnnualGasCost</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelUsage) = 1'>Expected 1 element(s) for xpath: LabelUsage</sch:assert>
      <sch:assert role='ERROR' test='count(h:Capacity) = 1'>Expected 1 element(s) for xpath: Capacity</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesWasherType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesWasher[h:IsSharedAppliance="true"]'>
      <sch:assert role='ERROR' test='count(../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToWaterHeatingSystem) + count(h:AttachedToHotWaterDistribution) = 1'>Expected 1 element(s) for xpath: AttachedToWaterHeatingSystem | AttachedToHotWaterDistribution</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesDryer]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesDryer'>
      <sch:assert role='ERROR' test='count(../h:ClothesWasher) = 1'>Expected 1 element(s) for xpath: ../ClothesWasher</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsSharedAppliance) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedAppliance</sch:assert> <!-- See [ClothesDryerType=Shared] -->
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FuelType) = 1'>Expected 1 element(s) for xpath: FuelType</sch:assert>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"] or not(h:FuelType)'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DryingMethod) &lt;= 1'>Expected 0 or 1 element(s) for xpath: DryingMethod</sch:assert>
      <sch:assert role='ERROR' test='h:DryingMethod[text()="conventional" or text()="condensing" or text()="heat pump" or text()="other"] or not(h:DryingMethod)'>Expected DryingMethod to be 'conventional' or 'condensing' or 'heat pump' or 'other'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CombinedEnergyFactor) + count(h:EnergyFactor) &lt;= 1'>Expected 0 or 1 element(s) for xpath: CombinedEnergyFactor | EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:Vented) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Vented</sch:assert> <!-- See [ClothesDryerType=Vented] -->
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
      <!-- Moved/deprecated extension/IsVented and extension/VentedFlowRate inputs; see https://github.com/NREL/OpenStudio-HPXML/pull/751 -->
      <sch:assert role='ERROR' test='count(h:extension/h:IsVented) = 0'>extension/IsVented has been replaced by Vented</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:VentedFlowRate) = 0'>extension/VentedFlowRate has been replaced by VentedFlowRate</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesDryerType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesDryer[h:IsSharedAppliance="true"]'>
      <sch:assert role='ERROR' test='count(../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesDryerType=Vented]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesDryer[h:Vented="true"]'>
      <sch:assert role='ERROR' test='count(h:VentedFlowRate) &lt;= 1'>Expected 0 or 1 element(s) for xpath: VentedFlowRate</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Dishwasher]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Dishwasher'>
      <sch:assert role='ERROR' test='count(h:IsSharedAppliance) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsSharedAppliance</sch:assert> <!-- See [DishwasherType=Shared] -->
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedAnnualkWh) + count(h:EnergyFactor) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RatedAnnualkWh | EnergyFactor</sch:assert> <!-- See [DishwasherType=Detailed] -->
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DishwasherType=Detailed]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Dishwasher[h:RatedAnnualkWh | h:EnergyFactor]'>
      <sch:assert role='ERROR' test='count(h:LabelElectricRate) = 1'>Expected 1 element(s) for xpath: LabelElectricRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelGasRate) = 1'>Expected 1 element(s) for xpath: LabelGasRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelAnnualGasCost) = 1'>Expected 1 element(s) for xpath: LabelAnnualGasCost</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelUsage) = 1'>Expected 1 element(s) for xpath: LabelUsage</sch:assert>
      <sch:assert role='ERROR' test='count(h:PlaceSettingCapacity) = 1'>Expected 1 element(s) for xpath: PlaceSettingCapacity</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DishwasherType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Dishwasher[h:IsSharedAppliance="true"]'>
      <sch:assert role='ERROR' test='count(../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToWaterHeatingSystem) + count(h:AttachedToHotWaterDistribution) = 1'>Expected 1 element(s) for xpath: AttachedToWaterHeatingSystem | AttachedToHotWaterDistribution</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Refrigerator]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Refrigerator'>
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedAnnualkWh) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RatedAnnualkWh</sch:assert>
      <sch:assert role='ERROR' test='count(h:PrimaryIndicator) &lt;= 1'>Expected 0 or 1 element(s) for xpath: PrimaryIndicator</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ConstantScheduleCoefficients) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ConstantScheduleCoefficients</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:TemperatureScheduleCoefficients) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/TemperatureScheduleCoefficients</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension[h:WeekdayScheduleFractions | h:WeekendScheduleFractions | h:MonthlyScheduleMultipliers]) + count(h:extension[h:ConstantScheduleCoefficients | h:TemperatureScheduleCoefficients]) &lt;= 1'>Expected either schedule fractions/multipliers or schedule coefficients but not both.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Freezer]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Freezer'>
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedAnnualkWh) &lt;= 1'>Expected 0 or 1 element(s) for xpath: RatedAnnualkWh</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ConstantScheduleCoefficients) + count(h:extension/h:TemperatureScheduleCoefficients) = 0 or count(h:extension/h:ConstantScheduleCoefficients) + count(h:extension/h:TemperatureScheduleCoefficients) = 2'>Expected 0 or 2 element(s) for xpath: extension/ConstantScheduleCoefficients | extension/TemperatureScheduleCoefficients</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension[h:WeekdayScheduleFractions | h:WeekendScheduleFractions | h:MonthlyScheduleMultipliers]) + count(h:extension[h:ConstantScheduleCoefficients | h:TemperatureScheduleCoefficients]) &lt;= 1'>Expected either schedule fractions/multipliers or schedule coefficients but not both.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Dehumidifier]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Dehumidifier'>
      <sch:assert role='ERROR' test='count(h:Type) = 1'>Expected 1 element(s) for xpath: Type</sch:assert>
      <sch:assert role='ERROR' test='h:Type[text()="portable" or text()="whole-home"] or not(h:Type)'>Expected Type to be 'portable' or 'whole-home'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Location) = 1'>Expected 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space"] or not(h:Location)'>Expected Location to be 'conditioned space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Capacity) = 1'>Expected 1 element(s) for xpath: Capacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedEnergyFactor) + count(h:EnergyFactor) = 1'>Expected 1 element(s) for xpath: IntegratedEnergyFactor | EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:DehumidistatSetpoint) = 1'>Expected 1 element(s) for xpath: DehumidistatSetpoint</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDehumidificationLoadServed) = 1'>Expected 1 element(s) for xpath: FractionDehumidificationLoadServed</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CookingRange]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:CookingRange'>
      <sch:assert role='ERROR' test='count(../h:Oven) = 1'>Expected 1 element(s) for xpath: ../Oven</sch:assert> <!-- See [Oven] -->
      <sch:assert role='ERROR' test='count(h:Location) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Location</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FuelType) = 1'>Expected 1 element(s) for xpath: FuelType</sch:assert>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"] or not(h:FuelType)'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IsInduction) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsInduction</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Oven]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Oven'>
      <sch:assert role='ERROR' test='count(../h:CookingRange) = 1'>Expected 1 element(s) for xpath: ../CookingRange</sch:assert> <!-- See [CookingRange] -->
      <sch:assert role='ERROR' test='count(h:IsConvection) &lt;= 1'>Expected 0 or 1 element(s) for xpath: IsConvection</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Lighting]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting'>
      <sch:assert role='ERROR' test='count(h:LightingGroup[h:Location="interior"]) &gt;= 0'>Expected 0 or more element(s) for xpath: LightingGroup[Location="interior"]</sch:assert> <!-- See [LightingGroup=Interior] -->
      <sch:assert role='ERROR' test='count(h:LightingGroup[h:Location="exterior"]) &gt;= 0'>Expected 0 or more element(s) for xpath: LightingGroup[Location="exterior"]</sch:assert> <!-- See [LightingGroup=Exterior] -->
      <sch:assert role='ERROR' test='count(h:LightingGroup[h:Location="garage"]) &gt;= 0'>Expected 0 or more element(s) for xpath: LightingGroup[Location="garage"]</sch:assert> <!-- See [LightingGroup=Garage] -->
      <sch:assert role='ERROR' test='count(h:extension/h:InteriorUsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/InteriorUsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:InteriorUsageMultiplier) &gt;= 0 or not(h:extension/h:InteriorUsageMultiplier)'>Expected extension/InteriorUsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GarageUsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/GarageUsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:GarageUsageMultiplier) &gt;= 0 or not(h:extension/h:GarageUsageMultiplier)'>Expected extension/GarageUsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ExteriorUsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ExteriorUsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ExteriorUsageMultiplier) &gt;= 0 or not(h:extension/h:ExteriorUsageMultiplier)'>Expected extension/ExteriorUsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:InteriorWeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/InteriorWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:InteriorWeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/InteriorWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:InteriorMonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/InteriorMonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GarageWeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/GarageWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GarageWeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/GarageWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GarageMonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/GarageMonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ExteriorWeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ExteriorWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ExteriorWeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ExteriorWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ExteriorMonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ExteriorMonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ExteriorHolidayLighting) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/ExteriorHolidayLighting</sch:assert> <!-- See [ExteriorHolidayLighting] -->
      <!-- Sum Checks -->
      <sch:assert role='ERROR' test='sum(h:LightingGroup[h:Location="interior"]/h:FractionofUnitsInLocation) &lt;= 1.01'>Expected sum(LightingGroup/FractionofUnitsInLocation) for Location="interior" to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='sum(h:LightingGroup[h:Location="exterior"]/h:FractionofUnitsInLocation) &lt;= 1.01'>Expected sum(LightingGroup/FractionofUnitsInLocation) for Location="exterior" to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='sum(h:LightingGroup[h:Location="garage"]/h:FractionofUnitsInLocation) &lt;= 1.01'>Expected sum(LightingGroup/FractionofUnitsInLocation) for Location="garage" to be less than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LightingGroup=Interior]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:LightingGroup[h:Location="interior"]'>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:LightEmittingDiode] and h:Location="interior"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../LightingGroup[LightingType[LightEmittingDiode] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:CompactFluorescent] and h:Location="interior"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:FluorescentTube] and h:Location="interior"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../LightingGroup[LightingType[FluorescentTube] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LightingGroup=Exterior]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:LightingGroup[h:Location="exterior"]'>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:LightEmittingDiode] and h:Location="exterior"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../LightingGroup[LightingType[LightEmittingDiode] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:CompactFluorescent] and h:Location="exterior"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:FluorescentTube] and h:Location="exterior"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../LightingGroup[LightingType[FluorescentTube] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LightingGroup=Garage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:LightingGroup[h:Location="garage"]'>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:LightEmittingDiode] and h:Location="garage"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../LightingGroup[LightingType[LightEmittingDiode] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:CompactFluorescent] and h:Location="garage"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:FluorescentTube] and h:Location="garage"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected 1 element(s) for xpath: ../LightingGroup[LightingType[FluorescentTube] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ExteriorHolidayLighting]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:extension/h:ExteriorHolidayLighting'>
      <sch:assert role='ERROR' test='count(h:Load[h:Units="kWh/day"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Load[Units="kWh/day"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:PeriodBeginMonth) + count(h:PeriodBeginDayOfMonth) = 0 or count(h:PeriodBeginMonth) + count(h:PeriodBeginDayOfMonth) = 2'>Expected 0 or 2 element(s) for xpath: PeriodBeginMonth | PeriodBeginDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:PeriodEndMonth) + count(h:PeriodEndDayOfMonth) = 0 or count(h:PeriodEndMonth) + count(h:PeriodEndDayOfMonth) = 2'>Expected 0 or 2 element(s) for xpath: PeriodEndMonth | PeriodEndDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: WeekendScheduleFractions</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CeilingFan]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:CeilingFan'>
      <sch:assert role='ERROR' test='count(h:Airflow[h:FanSpeed="medium"]/h:Efficiency) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Airflow[FanSpeed="medium"]/Efficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:Count) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Count</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelEnergyUse) &lt;= 1'>Expected 0 or 1 element(s) for xpath: LabelEnergyUse</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Pool]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Pools/h:Pool'>
      <sch:assert role='ERROR' test='count(h:Type) = 1'>Expected 1 element(s) for xpath: Type</sch:assert>
      <sch:assert role='ERROR' test='count(h:Pumps/h:Pump) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Pumps/Pump</sch:assert> <!-- See [PoolPump] -->
      <sch:assert role='ERROR' test='count(h:Heater) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Heater</sch:assert> <!-- See [PoolHeater] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PoolPump]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Pools/h:Pool/h:Pumps/h:Pump'>
      <sch:assert role='ERROR' test='count(h:Type) = 1'>Expected 1 element(s) for xpath: Type</sch:assert>
      <sch:assert role='ERROR' test='count(h:Load[h:Units="kWh/year"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Load[Units="kWh/year"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PoolHeater]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Pools/h:Pool/h:Heater'>
      <sch:assert role='ERROR' test='count(h:Type) = 1'>Expected 1 element(s) for xpath: Type</sch:assert>
      <sch:assert role='ERROR' test='h:Type[text()="not present" or text()="gas fired" or text()="electric resistance" or text()="heat pump"] or not(h:Type)'>Expected Type to be 'not present' or 'gas fired' or 'electric resistance' or 'heat pump'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Load[h:Units="kWh/year" or h:Units="therm/year"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Load[Units="kWh/year" or Units="therm/year"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PermanentSpa]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Spas/h:PermanentSpa'>
      <sch:assert role='ERROR' test='count(h:Type) = 1'>Expected 1 element(s) for xpath: Type</sch:assert>
      <sch:assert role='ERROR' test='count(h:Pumps/h:Pump) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Pumps/Pump</sch:assert> <!-- See [PermanentSpaPump] -->
      <sch:assert role='ERROR' test='count(h:Heater) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Heater</sch:assert> <!-- See [PermanentSpaHeater] -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PermanentSpaPump]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Spas/h:PermanentSpa/h:Pumps/h:Pump'>
      <sch:assert role='ERROR' test='count(h:Type) = 1'>Expected 1 element(s) for xpath: Type</sch:assert>
      <sch:assert role='ERROR' test='count(h:Load[h:Units="kWh/year"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Load[Units="kWh/year"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PermanentSpaHeater]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Spas/h:PermanentSpa/h:Heater'>
      <sch:assert role='ERROR' test='count(h:Type) = 1'>Expected 1 element(s) for xpath: Type</sch:assert>
      <sch:assert role='ERROR' test='h:Type[text()="not present" or text()="gas fired" or text()="electric resistance" or text()="heat pump"] or not(h:Type)'>Expected Type to be 'not present' or 'gas fired' or 'electric resistance' or 'heat pump'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Load[h:Units="kWh/year" or h:Units="therm/year"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Load[Units="kWh/year" or Units="therm/year"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PlugLoad]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:MiscLoads/h:PlugLoad[h:PlugLoadType="other" or h:PlugLoadType="TV other" or h:PlugLoadType="electric vehicle charging" or h:PlugLoadType="well pump"]'>
      <sch:assert role='ERROR' test='count(h:Load[h:Units="kWh/year"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Load[Units="kWh/year"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FracSensible) + count(h:extension/h:FracLatent) = 0 or count(h:extension/h:FracSensible) + count(h:extension/h:FracLatent) = 2'>Expected 0 or 2 element(s) for xpath: extension/FracSensible | extension/FracLatent</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FracSensible) &gt;= 0 or not(h:extension/h:FracSensible)'>Expected extension/FracSensible to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FracLatent) &gt;= 0 or not(h:extension/h:FracLatent)'>Expected extension/FracLatent to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='(number(h:extension/h:FracSensible) + number(h:extension/h:FracLatent)) &lt;= 1 or not(h:extension/h:FracSensible) or not(h:extension/h:FracLatent)'>Expected sum of extension/FracSensible and extension/FracLatent to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FuelLoad]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:MiscLoads/h:FuelLoad[h:FuelLoadType="grill" or h:FuelLoadType="lighting" or h:FuelLoadType="fireplace"]'>
      <sch:assert role='ERROR' test='count(h:Load[h:Units="therm/year"]/h:Value) &lt;= 1'>Expected 0 or 1 element(s) for xpath: Load[Units="therm/year"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:FuelType) = 1'>Expected 1 element(s) for xpath: FuelType</sch:assert>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="wood" or text()="wood pellets"] or not(h:FuelType)'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FracSensible) + count(h:extension/h:FracLatent) = 0 or count(h:extension/h:FracSensible) + count(h:extension/h:FracLatent) = 2'>Expected 0 or 2 element(s) for xpath: extension/FracSensible | extension/FracLatent</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FracSensible) &gt;= 0 or not(h:extension/h:FracSensible)'>Expected extension/FracSensible to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FracLatent) &gt;= 0 or not(h:extension/h:FracLatent)'>Expected extension/FracLatent to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='(number(h:extension/h:FracSensible) + number(h:extension/h:FracLatent)) &lt;= 1 or not(h:extension/h:FracSensible) or not(h:extension/h:FracLatent)'>Expected sum of extension/FracSensible and extension/FracLatent to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected 0 or 1 element(s) for xpath: extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rules below check that the different space types are appropriately enclosed by surfaces -->

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=ConditionedSpace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="conditioned space"]]'>
      <sch:assert role='ERROR' test='count(h:Roofs/h:Roof[h:InteriorAdjacentTo="conditioned space"]) + count(h:Floors/h:Floor[h:InteriorAdjacentTo="conditioned space" and (h:ExteriorAdjacentTo="attic - vented" or h:ExteriorAdjacentTo="attic - unvented" or ((h:ExteriorAdjacentTo="other housing unit" or h:ExteriorAdjacentTo="other heated space" or h:ExteriorAdjacentTo="other multifamily buffer space" or h:ExteriorAdjacentTo="other non-freezing space") and h:FloorOrCeiling="ceiling"))]) + count(h:Floors[/h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"]]/h:Floor[h:SystemIdentifier/@sameas]) &gt;= 1'>There must be at least one ceiling or roof adjacent to conditioned space.</sch:assert>
      <sch:assert role='ERROR' test='count(h:Walls/h:Wall[h:InteriorAdjacentTo="conditioned space" and h:ExteriorAdjacentTo="outside"]) + count(h:Walls[/h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"]]/h:Wall[h:SystemIdentifier/@sameas]) &gt;= 1'>There must be at least one exterior wall adjacent to conditioned space.</sch:assert>
      <sch:assert role='ERROR' test='count(h:Slabs/h:Slab[contains(h:InteriorAdjacentTo, "conditioned")]) + count(h:Floors/h:Floor[h:InteriorAdjacentTo="conditioned space" and not(h:ExteriorAdjacentTo="attic - vented" or h:ExteriorAdjacentTo="attic - unvented" or ((h:ExteriorAdjacentTo="other housing unit" or h:ExteriorAdjacentTo="other heated space" or h:ExteriorAdjacentTo="other multifamily buffer space" or h:ExteriorAdjacentTo="other non-freezing space") and h:FloorOrCeiling="ceiling"))]) + count(h:Floors[/h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"]]/h:Floor[h:SystemIdentifier/@sameas]) &gt;= 1'>There must be at least one floor or slab adjacent to conditioned space.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=ConditionedBasement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="basement - conditioned" or h:ExteriorAdjacentTo="basement - conditioned"]]'>
      <sch:assert role='ERROR' test='count(h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="basement - conditioned" and h:ExteriorAdjacentTo="ground"]) + count(h:Walls/h:Wall[h:InteriorAdjacentTo="basement - conditioned" and h:ExteriorAdjacentTo="outside"]) &gt;= 1'>There must be at least one exterior wall or foundation wall adjacent to "basement - conditioned".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Slabs/h:Slab[h:InteriorAdjacentTo="basement - conditioned"]) &gt;= 1'>There must be at least one slab adjacent to "basement - conditioned".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=UnconditionedBasement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="basement - unconditioned" or h:ExteriorAdjacentTo="basement - unconditioned"]]'>
      <sch:assert role='ERROR' test='count(h:Floors/h:Floor[h:InteriorAdjacentTo="conditioned space" and h:ExteriorAdjacentTo="basement - unconditioned"]) &gt;= 1'>There must be at least one ceiling adjacent to "basement - unconditioned".</sch:assert>
      <sch:assert role='ERROR' test='count(h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="basement - unconditioned" and h:ExteriorAdjacentTo="ground"]) + count(h:Walls/h:Wall[h:InteriorAdjacentTo="basement - unconditioned" and h:ExteriorAdjacentTo="outside"]) &gt;= 1'>There must be at least one exterior wall or foundation wall adjacent to "basement - unconditioned".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Slabs/h:Slab[h:InteriorAdjacentTo="basement - unconditioned"]) &gt;= 1'>There must be at least one slab adjacent to "basement - unconditioned".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=VentedCrawlspace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="crawlspace - vented" or h:ExteriorAdjacentTo="crawlspace - vented"]]'>
      <sch:assert role='ERROR' test='count(h:Floors/h:Floor[h:InteriorAdjacentTo="conditioned space" and h:ExteriorAdjacentTo="crawlspace - vented"]) &gt;= 1'>There must be at least one ceiling adjacent to "crawlspace - vented".</sch:assert>
      <sch:assert role='ERROR' test='count(h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="crawlspace - vented" and h:ExteriorAdjacentTo="ground"]) + count(h:Walls/h:Wall[h:InteriorAdjacentTo="crawlspace - vented" and h:ExteriorAdjacentTo="outside"]) &gt;= 1'>There must be at least one exterior wall or foundation wall adjacent to "crawlspace - vented".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Slabs/h:Slab[h:InteriorAdjacentTo="crawlspace - vented"]) &gt;= 1'>There must be at least one slab adjacent to "crawlspace - vented".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=UnventedCrawlspace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="crawlspace - unvented" or h:ExteriorAdjacentTo="crawlspace - unvented"]]'>
      <sch:assert role='ERROR' test='count(h:Floors/h:Floor[h:InteriorAdjacentTo="conditioned space" and h:ExteriorAdjacentTo="crawlspace - unvented"]) &gt;= 1'>There must be at least one ceiling adjacent to "crawlspace - unvented".</sch:assert>
      <sch:assert role='ERROR' test='count(h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="crawlspace - unvented" and h:ExteriorAdjacentTo="ground"]) + count(h:Walls/h:Wall[h:InteriorAdjacentTo="crawlspace - unvented" and h:ExteriorAdjacentTo="outside"]) &gt;= 1'>There must be at least one exterior wall or foundation wall adjacent to "crawlspace - unvented".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Slabs/h:Slab[h:InteriorAdjacentTo="crawlspace - unvented"]) &gt;= 1'>There must be at least one slab adjacent to "crawlspace - unvented".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=ConditionedCrawlspace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="crawlspace - conditioned" or h:ExteriorAdjacentTo="crawlspace - conditioned"]]'>
      <sch:assert role='ERROR' test='count(h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="crawlspace - conditioned" and h:ExteriorAdjacentTo="ground"]) + count(h:Walls/h:Wall[h:InteriorAdjacentTo="crawlspace - conditioned" and h:ExteriorAdjacentTo="outside"]) &gt;= 1'>There must be at least one exterior wall or foundation wall adjacent to "crawlspace - conditioned".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Slabs/h:Slab[h:InteriorAdjacentTo="crawlspace - conditioned"]) &gt;= 1'>There must be at least one slab adjacent to "crawlspace - conditioned".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=Garage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="garage" or h:ExteriorAdjacentTo="garage"]]'>
      <sch:assert role='ERROR' test='count(h:Roofs/h:Roof[h:InteriorAdjacentTo="garage"]) + count(h:Floors/h:Floor[h:InteriorAdjacentTo="garage" or h:ExteriorAdjacentTo="garage"]) &gt;= 1'>There must be at least one roof or ceiling adjacent to "garage".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Walls/h:Wall[h:InteriorAdjacentTo="garage" and h:ExteriorAdjacentTo="outside"]) + count(h:FoundationWalls/h:FoundationWall[h:InteriorAdjacentTo="garage" and h:ExteriorAdjacentTo="ground"]) &gt;= 1'>There must be at least one exterior wall or foundation wall adjacent to "garage".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Slabs/h:Slab[h:InteriorAdjacentTo="garage"]) &gt;= 1'>There must be at least one slab adjacent to "garage".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=VentedAttic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="attic - vented" or h:ExteriorAdjacentTo="attic - vented"]]'>
      <sch:assert role='ERROR' test='count(h:Roofs/h:Roof[h:InteriorAdjacentTo="attic - vented"]) &gt;= 1'>There must be at least one roof adjacent to "attic - vented".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Floors/h:Floor[h:InteriorAdjacentTo="attic - vented" or h:ExteriorAdjacentTo="attic - vented"]) &gt;= 1'>There must be at least one floor adjacent to "attic - vented".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdjacentSurfaces=UnventedAttic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure[*/*[h:InteriorAdjacentTo="attic - unvented" or h:ExteriorAdjacentTo="attic - unvented"]]'>
      <sch:assert role='ERROR' test='count(h:Roofs/h:Roof[h:InteriorAdjacentTo="attic - unvented"]) &gt;= 1'>There must be at least one roof adjacent to "attic - unvented".</sch:assert>
      <sch:assert role='ERROR' test='count(h:Floors/h:Floor[h:InteriorAdjacentTo="attic - unvented" or h:ExteriorAdjacentTo="attic - unvented"]) &gt;= 1'>There must be at least one floor adjacent to "attic - unvented".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rules below check that the specified appliance, water heater, HVAC, or duct location exists in the building -->

  <sch:pattern>
    <sch:title>[LocationCheck=ConditionedBasement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="basement - conditioned"] | h:Systems/*/*[h:Location="basement - conditioned"] | h:Systems/*/*/*[h:UnitLocation="basement - conditioned"] | h:Systems/*/*/*/*/*[h:DuctLocation="basement - conditioned"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="basement - conditioned" or h:ExteriorAdjacentTo="basement - conditioned"]) &gt;= 1'>A location is specified as "basement - conditioned" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=UnconditionedBasement]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="basement - unconditioned"] | h:Systems/*/*[h:Location="basement - unconditioned"] | h:Systems/*/*/*[h:UnitLocation="basement - unconditioned"] | h:Systems/*/*/*/*/*[h:DuctLocation="basement - unconditioned"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="basement - unconditioned" or h:ExteriorAdjacentTo="basement - unconditioned"]) &gt;= 1'>A location is specified as "basement - unconditioned" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=VentedCrawlspace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="crawlspace - vented"] | h:Systems/*/*[h:Location="crawlspace - vented"] | h:Systems/*/*/*[h:UnitLocation="crawlspace - vented"] | h:Systems/*/*/*/*/*[h:DuctLocation="crawlspace - vented"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="crawlspace - vented" or h:ExteriorAdjacentTo="crawlspace - vented"]) &gt;= 1'>A location is specified as "crawlspace - vented" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=UnventedCrawlspace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="crawlspace - unvented"] | h:Systems/*/*[h:Location="crawlspace - unvented"] | h:Systems/*/*/*[h:UnitLocation="crawlspace - unvented"] | h:Systems/*/*/*/*/*[h:DuctLocation="crawlspace - unvented"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="crawlspace - unvented" or h:ExteriorAdjacentTo="crawlspace - unvented"]) &gt;= 1'>A location is specified as "crawlspace - unvented" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=ConditionedCrawlspace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="crawlspace - conditioned"] | h:Systems/*/*[h:Location="crawlspace - conditioned"] | h:Systems/*/*/*[h:UnitLocation="crawlspace - conditioned"] | h:Systems/*/*/*/*/*[h:DuctLocation="crawlspace - conditioned"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="crawlspace - conditioned" or h:ExteriorAdjacentTo="crawlspace - conditioned"]) &gt;= 1'>A location is specified as "crawlspace - conditioned" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=Garage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="garage"] | h:Systems/*/*[h:Location="garage"] | h:Systems/*/*/*[h:UnitLocation="garage"] | h:Systems/*/*/*/*/*[h:DuctLocation="garage"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="garage" or h:ExteriorAdjacentTo="garage"]) &gt;= 1'>A location is specified as "garage" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=VentedAttic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="attic - vented"] | h:Systems/*/*[h:Location="attic - vented"] | h:Systems/*/*/*[h:UnitLocation="attic - vented"] | h:Systems/*/*/*/*/*[h:DuctLocation="attic - vented"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="attic - vented" or h:ExteriorAdjacentTo="attic - vented"]) &gt;= 1'>A location is specified as "attic - vented" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=UnventedAttic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="attic - unvented"] | h:Systems/*/*[h:Location="attic - unvented"] | h:Systems/*/*/*[h:UnitLocation="attic - unvented"] | h:Systems/*/*/*/*/*[h:DuctLocation="attic - unvented"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="attic - unvented" or h:ExteriorAdjacentTo="attic - unvented"]) &gt;= 1'>A location is specified as "attic - unvented" but no surfaces were found adjacent to this space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocationCheck=ManufacturedHomeBelly]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="manufactured home belly"] | h:Systems/*/*[h:Location="manufactured home belly"] | h:Systems/*/*/*[h:UnitLocation="manufactured home belly"] | h:Systems/*/*/*/*/*[h:DuctLocation="manufactured home belly"]]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/*/*[h:InteriorAdjacentTo="manufactured home underbelly" or h:ExteriorAdjacentTo="manufactured home underbelly"]) &gt;= 1'>A location is specified as "manufactured home belly" but no surfaces were found adjacent to the "manufactured home underbelly" space type.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rules below check for the appropriate building type when there are objects referencing SFA/MF locations -->

  <sch:pattern>
    <sch:title>[BuildingTypeCheck=OtherHousingUnit]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="other housing unit"] | h:Systems/*/*[h:Location="other housing unit"] | h:Systems/*/*/*/*/*[h:DuctLocation="other housing unit"] | h:Enclosure[*/*[h:InteriorAdjacentTo="other housing unit" or h:ExteriorAdjacentTo="other housing unit"]]]'>
      <sch:assert role='ERROR' test='h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"] or not(h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType)'>There are references to "other housing unit" but ResidentialFacilityType is not "single-family attached" or "apartment unit".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingTypeCheck=OtherHeatedSpace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="other heated space"] | h:Systems/*/*[h:Location="other heated space"] | h:Systems/*/*/*/*/*[h:DuctLocation="other heated space"] | h:Enclosure[*/*[h:InteriorAdjacentTo="other heated space" or h:ExteriorAdjacentTo="other heated space"]]]'>
      <sch:assert role='ERROR' test='h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"] or not(h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType)'>There are references to "other heated space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingTypeCheck=OtherMultifamilyBufferSpace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="other multifamily buffer space"] | h:Systems/*/*[h:Location="other multifamily buffer space"] | h:Systems/*/*/*/*/*[h:DuctLocation="other multifamily buffer space"] | h:Enclosure[*/*[h:InteriorAdjacentTo="other multifamily buffer space" or h:ExteriorAdjacentTo="other multifamily buffer space"]]]'>
      <sch:assert role='ERROR' test='h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"] or not(h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType)'>There are references to "other multifamily buffer space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingTypeCheck=OtherNonFreezingSpace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Appliances/*[h:Location="other non-freezing space"] | h:Systems/*/*[h:Location="other non-freezing space"] | h:Systems/*/*/*/*/*[h:DuctLocation="other non-freezing space"] | h:Enclosure[*/*[h:InteriorAdjacentTo="other non-freezing space" or h:ExteriorAdjacentTo="other non-freezing space"]]]'>
      <sch:assert role='ERROR' test='h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"] or not(h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType)'>There are references to "other non-freezing space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingTypeCheck=ManufacturedHomeBelly]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Systems/*/*[h:Location="manufactured home belly"] | h:Systems/*/*/*/*/*[h:DuctLocation="manufactured home belly"] | h:Enclosure[*/*[h:InteriorAdjacentTo="manufactured home underbelly" or h:ExteriorAdjacentTo="manufactured home underbelly"]]]'>
      <sch:assert role='ERROR' test='h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="manufactured home"] or not(h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType)'>There are references to "manufactured home belly" or "manufactured home underbelly" but ResidentialFacilityType is not "manufactured home".</sch:assert>
    </sch:rule>
  </sch:pattern>

</sch:schema>