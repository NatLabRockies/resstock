<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch='http://purl.oclc.org/dsdl/schematron'>
  <sch:title>HPXML Schematron Validator: EnergyPlus Simulation</sch:title>
  <sch:ns uri='http://hpxmlonline.com/2025/12' prefix='h'/>

  <sch:pattern>
    <sch:title>[Root]</sch:title>
    <sch:rule context='/h:HPXML'>
      <sch:assert role='ERROR' test='count(h:Building) &gt;= 1'>Expected at least one Building</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SoftwareInfo]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo'>
      <sch:assert role='ERROR' test='count(h:extension/h:SimulationControl) &lt;= 1'>Expected at most one extension/SimulationControl</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ElectricPanelLoadCalculations) &lt;= 1'>Expected at most one extension/ElectricPanelLoadCalculations</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WholeSFAorMFBuildingSimulation) &lt;= 1'>Expected at most one extension/WholeSFAorMFBuildingSimulation</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:WholeSFAorMFBuildingSimulation[text()="true" or text()="false"] or not(h:extension/h:WholeSFAorMFBuildingSimulation)'>Expected extension/WholeSFAorMFBuildingSimulation to be 'true' or 'false'</sch:assert>
      <!-- Moved multiple inputs to allow variation across MF dwelling units; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/1478 -->
      <sch:assert role='ERROR' test='count(h:extension/h:SchedulesFilePath) = 0'>extension/SchedulesFilePath has been replaced by /HPXML/Building/BuildingDetails/BuildingSummary/extension/SchedulesFilePath</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HVACSizingControl) = 0'>extension/HVACSizingControl has been replaced by /HPXML/Building/BuildingDetails/BuildingSummary/extension/HVACSizingControl</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ShadingControl) = 0'>extension/ShadingControl has been replaced by /HPXML/Building/BuildingDetails/BuildingSummary/extension/ShadingControl</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:NaturalVentilationAvailabilityDaysperWeek) = 0'>extension/NaturalVentilationAvailabilityDaysperWeek has been replaced by /HPXML/Building/BuildingDetails/BuildingSummary/extension/NaturalVentilationAvailabilityDaysperWeek</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SimulationControl]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:SimulationControl'>
      <sch:assert role='ERROR' test='count(h:Timestep) &lt;= 1'>Expected at most one Timestep</sch:assert>
      <sch:assert role='ERROR' test='60 mod number(h:Timestep) = 0 or not(h:Timestep)'>Expected Timestep to be 60, 30, 20, 15, 12, 10, 6, 5, 4, 3, 2, or 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:CalendarYear) &lt;= 1'>Expected at most one CalendarYear</sch:assert>
      <sch:assert role='ERROR' test='number(h:CalendarYear) &gt;= 1600 or not(h:CalendarYear)'>Expected CalendarYear to be greater than or equal to 1600</sch:assert>
      <sch:assert role='ERROR' test='number(h:CalendarYear) &lt;= 9999 or not(h:CalendarYear)'>Expected CalendarYear to be less than or equal to 9999</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdvancedResearchFeatures) &lt;= 1'>Expected at most one AdvancedResearchFeatures</sch:assert>
      <!-- Moved/deprecated DaylightSaving input; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/1165 -->
      <sch:assert role='ERROR' test='count(h:DaylightSaving/h:Enabled) = 0'>DaylightSaving/Enabled has been replaced by /HPXML/Building/Site/TimeZone/DSTObserved</sch:assert>
      <sch:assert role='ERROR' test='count(h:DaylightSaving/h:BeginMonth) = 0'>DaylightSaving/BeginMonth has been replaced by /HPXML/Building/Site/TimeZone/extension/DSTBeginMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:DaylightSaving/h:BeginDayOfMonth) = 0'>DaylightSaving/BeginDayOfMonth has been replaced by /HPXML/Building/Site/TimeZone/extension/DSTBeginDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:DaylightSaving/h:EndMonth) = 0'>DaylightSaving/EndMonth has been replaced by /HPXML/Building/Site/TimeZone/extension/DSTEndMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:DaylightSaving/h:EndDayOfMonth) = 0'>DaylightSaving/EndDayOfMonth has been replaced by /HPXML/Building/Site/TimeZone/extension/DSTEndDayOfMonth</sch:assert>
      <!-- Moved/deprecated TemperatureCapacitanceMultiplier input; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/1674 -->
      <sch:assert role='ERROR' test='count(h:TemperatureCapacitanceMultiplier) = 0'>TemperatureCapacitanceMultiplier has been replaced by AdvancedResearchFeatures/TemperatureCapacitanceMultiplier</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SimulationControl=BeginPeriod]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:SimulationControl[h:BeginMonth | h:BeginDayOfMonth]'>
      <sch:assert role='ERROR' test='count(h:BeginMonth) = 1'>Expected BeginMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:BeginDayOfMonth) = 1'>Expected BeginDayOfMonth</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SimulationControl=EndPeriod]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:SimulationControl[h:EndMonth | h:EndDayOfMonth]'>
      <sch:assert role='ERROR' test='count(h:EndMonth) = 1'>Expected EndMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndDayOfMonth) = 1'>Expected EndDayOfMonth</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AdvancedResearchFeatures]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:SimulationControl/h:AdvancedResearchFeatures'>
      <sch:assert role='ERROR' test='count(h:TemperatureCapacitanceMultiplier) &lt;= 1'>Expected at most one TemperatureCapacitanceMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:TemperatureCapacitanceMultiplier) &gt; 0 or not (h:TemperatureCapacitanceMultiplier)'>Expected TemperatureCapacitanceMultiplier to be greater than 0</sch:assert>
      <!-- Deprecated DefrostModelType input; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/2015 -->
      <sch:assert role='ERROR' test='count(h:DefrostModelType) = 0'>DefrostModelType has been deprecated</sch:assert>
      <sch:assert role='ERROR' test='count(h:OnOffThermostatDeadbandTemperature) &lt;= 1'>Expected at most one OnOffThermostatDeadbandTemperature</sch:assert>
      <sch:assert role='ERROR' test='number(h:OnOffThermostatDeadbandTemperature) &gt; 0 or not(h:OnOffThermostatDeadbandTemperature)'>Expected OnOffThermostatDeadbandTemperature to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:LatentDegradationModel/h:Enabled) &lt;= 1'>Expected at most one LatentDegradationModel/Enabled</sch:assert>
      <sch:assert role='ERROR' test='h:LatentDegradationModel/h:Enabled[text()="true" or text()="false"] or not(h:LatentDegradationModel/h:Enabled)'>Expected LatentDegradationModel/Enabled to be 'true' or 'false'</sch:assert>
      <sch:assert role='ERROR' test='count(h:LatentDegradationModel/h:HVACBlowerOffDelay) &lt;= 1'>Expected at most one LatentDegradationModel/HVACBlowerOffDelay</sch:assert>
      <sch:assert role='ERROR' test='number(h:LatentDegradationModel/h:HVACBlowerOffDelay) &gt;= 0 or not(h:LatentDegradationModel/h:HVACBlowerOffDelay)'>Expected LatentDegradationModel/HVACBlowerOffDelay to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatPumpBackupCapacityIncrement) &lt;= 1'>Expected at most one HeatPumpBackupCapacityIncrement</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatPumpBackupCapacityIncrement) &gt; 0 or not (h:HeatPumpBackupCapacityIncrement)'>Expected HeatPumpBackupCapacityIncrement to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:GroundToAirHeatPumpModelType) &lt;= 1'>Expected at most one GroundToAirHeatPumpModelType</sch:assert>
      <sch:assert role='ERROR' test='h:GroundToAirHeatPumpModelType[text()="standard" or text()="experimental"] or not(h:GroundToAirHeatPumpModelType)'>Expected GroundToAirHeatPumpModelType to be 'standard' or 'experimental'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[OnOffThermostatDeadbandTemperature]</sch:title>
    <sch:rule context='/h:HPXML[h:SoftwareInfo/h:extension/h:SimulationControl/h:AdvancedResearchFeatures/h:OnOffThermostatDeadbandTemperature]/h:Building/h:BuildingDetails'>
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:FractionCoolLoadServed > 0]) + count(h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:FractionCoolLoadServed > 0]) &lt;= 1'>Expected at most one cooling system for each Building if OnOffThermostatDeadbandTemperature is specified</sch:assert>
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:FractionHeatLoadServed > 0]) + count(h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:FractionHeatLoadServed > 0]) &lt;= 1'>Expected at most one heating system for each Building if OnOffThermostatDeadbandTemperature is specified</sch:assert>
      <sch:assert role='ERROR' test='sum(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionHeatLoadServed) &gt;= 0.99 or count(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionHeatLoadServed) = 0'>Expected sum(FractionHeatLoadServed) to be equal to 1 if OnOffThermostatDeadbandTemperature is specified</sch:assert>
      <sch:assert role='ERROR' test='sum(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionCoolLoadServed) &gt;= 0.99 or count(h:Systems/h:HVAC/h:HVACPlant/*/h:FractionCoolLoadServed) = 0'>Expected sum(FractionCoolLoadServed) to be equal to 1 if OnOffThermostatDeadbandTemperature is specified</sch:assert>
      <sch:assert role='ERROR' test='number(../../h:SoftwareInfo/h:extension/h:SimulationControl/h:Timestep) = 1'>Expected Timestep to be 1 if OnOffThermostatDeadbandTemperature is specified</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(../../h:SoftwareInfo/h:extension/h:SimulationControl/h:AdvancedResearchFeatures/h:TemperatureCapacitanceMultiplier) &lt;= 1'>TemperatureCapacitanceMultiplier should typically be greater than 1 if OnOffThermostatDeadbandTemperature is specified.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpBackupCapacityIncrement]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:SimulationControl[h:AdvancedResearchFeatures/h:HeatPumpBackupCapacityIncrement]'>
      <sch:assert role='ERROR' test='number(h:Timestep) = 1'>Expected Timestep to be 1 if HeatPumpBackupCapacityIncrement is specified</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[EmissionsScenario]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EmissionsScenarios/h:EmissionsScenario'>
      <sch:assert role='ERROR' test='count(h:Name) = 1'>Expected Name</sch:assert>
      <sch:assert role='ERROR' test='count(h:EmissionsType) = 1'>Expected EmissionsType</sch:assert>
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="electricity"]) = 1'>Expected EmissionsFactor[FuelType="electricity"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="natural gas"]) &lt;= 1'>Expected at most one EmissionsFactor[FuelType="natural gas"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="propane"]) &lt;= 1'>Expected at most one EmissionsFactor[FuelType="propane"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="fuel oil"]) &lt;= 1'>Expected at most one EmissionsFactor[FuelType="fuel oil"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="coal"]) &lt;= 1'>Expected at most one EmissionsFactor[FuelType="coal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="wood"]) &lt;= 1'>Expected at most one EmissionsFactor[FuelType="wood"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:EmissionsFactor[h:FuelType="wood pellets"]) &lt;= 1'>Expected at most one EmissionsFactor[FuelType="wood pellets"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[EmissionsFactor=Electricity]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EmissionsScenarios/h:EmissionsScenario/h:EmissionsFactor[h:FuelType="electricity"]'>
      <sch:assert role='ERROR' test='count(h:Units[text()="lb/MWh" or text()="kg/MWh"]) = 1'>Expected Units to be 'lb/MWh' or 'kg/MWh'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ScheduleFilePath) + count(h:Value) = 1'>Expected ScheduleFilePath or Value but not both</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[EmissionsFactor=ElectricitySchedule]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EmissionsScenarios/h:EmissionsScenario/h:EmissionsFactor[h:FuelType="electricity" and h:ScheduleFilePath]'>
      <sch:assert role='ERROR' test='count(h:NumberofHeaderRows) &lt;= 1'>Expected at most one NumberofHeaderRows</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofHeaderRows) &gt;= 0 or not(h:NumberofHeaderRows)'>Expected NumberofHeaderRows to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:ColumnNumber) &lt;= 1'>Expected at most one ColumnNumber</sch:assert>
      <sch:assert role='ERROR' test='number(h:ColumnNumber) &gt;= 1 or not(h:ColumnNumber)'>Expected ColumnNumber to be greater than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[EmissionsFactor=Fuel]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:EmissionsScenarios/h:EmissionsScenario/h:EmissionsFactor[h:FuelType!="electricity"]'>
      <sch:assert role='ERROR' test='count(h:Units[text()="lb/MBtu" or text()="kg/MBtu"]) = 1'>Expected Units to be 'lb/MBtu' or 'kg/MBtu'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Value) = 1'>Expected Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[UtilityBillScenario]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario'>
      <sch:assert role='ERROR' test='count(h:Name) = 1'>Expected Name</sch:assert>
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="electricity"]) &lt;= 1'>Expected at most one UtilityRate[FuelType="electricity"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="natural gas"]) &lt;= 1'>Expected at most one UtilityRate[FuelType="natural gas"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="propane"]) &lt;= 1'>Expected at most one UtilityRate[FuelType="propane"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="fuel oil"]) &lt;= 1'>Expected at most one UtilityRate[FuelType="fuel oil"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="coal"]) &lt;= 1'>Expected at most one UtilityRate[FuelType="coal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="wood"]) &lt;= 1'>Expected at most one UtilityRate[FuelType="wood"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:UtilityRate[h:FuelType="wood pellets"]) &lt;= 1'>Expected at most one UtilityRate[FuelType="wood pellets"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PVCompensation) &lt;= 1'>Expected at most one PVCompensation</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[UtilityRate]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario/h:UtilityRate'>
      <sch:assert role='ERROR' test='count(h:FixedCharge) &lt;= 1'>Expected at most one FixedCharge</sch:assert>
      <sch:assert role='ERROR' test='number(h:FixedCharge) &gt;= 0 or not(h:FixedCharge)'>Expected FixedCharge to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:MarginalRate) &lt;= 1'>Expected at most one MarginalRate</sch:assert>
      <sch:assert role='ERROR' test='number(h:MarginalRate) &gt;= 0 or not(h:MarginalRate)'>Expected MarginalRate to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[UtilityRate=Electricity]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario/h:UtilityRate[h:FuelType="electricity"]'>
      <sch:assert role='ERROR' test='count(h:FixedCharge) + count(h:TariffFilePath) &lt;= 1'>Expected not both FixedCharge and TariffFilePath</sch:assert>
      <sch:assert role='ERROR' test='count(h:MarginalRate) + count(h:TariffFilePath) &lt;= 1'>Expected not both MarginalRate and TariffFilePath</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVCompensation]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario/h:PVCompensation'>
      <sch:assert role='ERROR' test='count(h:CompensationType[h:NetMetering | h:FeedInTariff]) = 1'>Expected CompensationType[NetMetering | FeedInTariff]</sch:assert>
      <sch:assert role='ERROR' test='count(h:MonthlyGridConnectionFee[h:Units="$/kW" or h:Units="$"]/h:Value) &lt;= 1'>Expected not both MonthlyGridConnectionFee[Units="$/kW"]/Value and MonthlyGridConnectionFee[Units="$"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVCompensationType=NetMetering]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario/h:PVCompensation/h:CompensationType/h:NetMetering'>
      <sch:assert role='ERROR' test='count(h:AnnualExcessSellbackRateType) &lt;= 1'>Expected at most one AnnualExcessSellbackRateType</sch:assert>
      <sch:assert role='ERROR' test='h:AnnualExcessSellbackRateType[text()="User-Specified" or text()="Retail Electricity Cost"] or not(h:AnnualExcessSellbackRateType)'>Expected AnnualExcessSellbackRateType to be 'User-Specified' or 'Retail Electricity Cost'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVCompensationType=NetMeteringWithUserExcessSellbackRate]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario/h:PVCompensation/h:CompensationType/h:NetMetering[h:AnnualExcessSellbackRateType="User-Specified"]'>
      <sch:assert role='ERROR' test='count(h:AnnualExcessSellbackRate) &lt;= 1'>Expected at most one AnnualExcessSellbackRate</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualExcessSellbackRate) &gt;= 0 or not(h:AnnualExcessSellbackRate)'>Expected AnnualExcessSellbackRate to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVCompensationType=FeedInTariff]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UtilityBillScenarios/h:UtilityBillScenario/h:PVCompensation/h:CompensationType/h:FeedInTariff'>
      <sch:assert role='ERROR' test='count(h:FeedInTariffRate) &lt;= 1'>Expected at most one FeedInTariffRate</sch:assert>
      <sch:assert role='ERROR' test='number(h:FeedInTariffRate) &gt;= 0 or not(h:FeedInTariffRate)'>Expected FeedInTariffRate to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[UnavailablePeriod]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:UnavailablePeriods/h:UnavailablePeriod'>
      <sch:assert role='ERROR' test='count(h:ColumnName) = 1'>Expected ColumnName</sch:assert>
      <sch:assert role='ERROR' test='count(h:BeginMonth) = 1'>Expected BeginMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:BeginDayOfMonth) = 1'>Expected BeginDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:BeginHourOfDay) &lt;= 1'>Expected at most one BeginHourOfDay</sch:assert>
      <sch:assert role='ERROR' test='number(h:BeginHourOfDay) &gt;= 0 or not(h:BeginHourOfDay)'>Expected BeginHourOfDay to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:BeginHourOfDay) &lt;= 23 or not(h:BeginHourOfDay)'>Expected BeginHourOfDay to be less than or equal to 23</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndMonth) = 1'>Expected EndMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndDayOfMonth) = 1'>Expected EndDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndHourOfDay) &lt;= 1'>Expected at most one EndHourOfDay</sch:assert>
      <sch:assert role='ERROR' test='number(h:EndHourOfDay) &gt;= 1 or not(h:EndHourOfDay)'>Expected EndHourOfDay to be greater than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:EndHourOfDay) &lt;= 24 or not(h:EndHourOfDay)'>Expected EndHourOfDay to be less than or equal to 24</sch:assert>
      <sch:assert role='ERROR' test='count(h:NaturalVentilation) &lt;= 1'>Expected at most one NaturalVentilation</sch:assert>
      <sch:assert role='ERROR' test='h:NaturalVentilation[text()="regular schedule" or text()="always available" or text()="always unavailable"] or not(h:NaturalVentilation)'>Expected NaturalVentilation to be 'regular schedule' or 'always available' or 'always unavailable'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ElectricPanelLoadCalculations]</sch:title>
    <sch:rule context='/h:HPXML/h:SoftwareInfo/h:extension/h:ElectricPanelLoadCalculations'>
      <sch:assert role='ERROR' test='count(h:ServiceFeeders/h:Type) &gt;= 1'>Expected ServiceFeeders/Type</sch:assert>
      <sch:assert role='ERROR' test='h:ServiceFeeders/h:Type[text()="2023 Existing Dwelling Load-Based" or text()="2023 Existing Dwelling Meter-Based"]'>Expected ServiceFeeders/Type to be '2023 Existing Dwelling Load-Based' or '2023 Existing Dwelling Meter-Based'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Building]</sch:title>
    <sch:rule context='/h:HPXML/h:Building'>
      <sch:assert role='ERROR' test='count(h:Site/h:Address/h:ZipCode) + count(h:BuildingDetails/h:ClimateandRiskZones/h:WeatherStation/h:extension/h:EPWFilePath) &gt;= 1'>Expected Site/Address/ZipCode or BuildingDetails/ClimateandRiskZones/WeatherStation/extension/EPWFilePath</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DaylightSaving]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:Site/h:TimeZone[h:DSTObserved="true"][h:extension/h:DSTBeginMonth | h:extension/h:DSTBeginDayOfMonth | h:extension/h:DSTEndMonth | h:extension/h:DSTEndDayOfMonth]'>
      <sch:assert role='ERROR' test='count(h:extension/h:DSTBeginMonth) = 1'>Expected extension/DSTBeginMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:DSTBeginDayOfMonth) = 1'>Expected extension/DSTBeginDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:DSTEndMonth) = 1'>Expected extension/DSTEndMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:DSTEndDayOfMonth) = 1'>Expected extension/DSTEndDayOfMonth</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingDetails]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails'>
      <sch:assert role='ERROR' test='count(h:BuildingSummary/h:BuildingConstruction) = 1'>Expected BuildingSummary/BuildingConstruction</sch:assert>
      <sch:assert role='ERROR' test='count(h:ClimateandRiskZones/h:ClimateZoneIECC) &lt;= 1'>Expected at most one ClimateandRiskZones/ClimateZoneIECC</sch:assert>
      <sch:assert role='ERROR' test='count(h:Enclosure/h:AirInfiltration/h:extension/h:HasFlueOrChimneyInConditionedSpace) &lt;= 1'>Expected at most one Enclosure/AirInfiltration/extension/HasFlueOrChimneyInConditionedSpace</sch:assert>
      <sch:assert role='ERROR' test='h:Enclosure/h:AirInfiltration/h:extension/h:HasFlueOrChimneyInConditionedSpace[text()="true" or text()="false"] or not(h:Enclosure/h:AirInfiltration/h:extension/h:HasFlueOrChimneyInConditionedSpace)'>Expected Enclosure/AirInfiltration/extension/HasFlueOrChimneyInConditionedSpace to be 'true' or 'false'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:BuildingAirLeakage/h:AirLeakage | h:EffectiveLeakageArea | h:SpecificLeakageArea | h:LeakinessDescription]) = 1'>Expected one Enclosure/AirInfiltration/AirInfiltrationMeasurement[BuildingAirLeakage/AirLeakage | EffectiveLeakageArea | SpecificLeakageArea | LeakinessDescription]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Enclosure/h:Walls/h:Wall) + count(h:Enclosure/h:FoundationWalls/h:FoundationWall) &gt;= 1'>Expected Enclosure/Walls/Wall or Enclosure/FoundationWalls/FoundationWall</sch:assert>
      <sch:assert role='ERROR' test='count(h:Enclosure/h:extension/h:PartitionWallMass) &lt;= 1'>Expected at most one Enclosure/extension/PartitionWallMass</sch:assert>
      <sch:assert role='ERROR' test='count(h:Enclosure/h:extension/h:FurnitureMass) &lt;= 1'>Expected at most one Enclosure/extension/FurnitureMass</sch:assert>
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACPlant/h:HeatPump/h:BackupSystem) &lt;= 1'>Expected at most one HeatPump/BackupSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:Systems/h:HVAC/h:HVACControl) &lt;= 1'>Expected at most one Systems/HVAC/HVACControl</sch:assert>
      <sch:assert role='ERROR' test='count(h:Systems/h:WaterHeating/h:HotWaterDistribution) &lt;= 1'>Expected at most one Systems/WaterHeating/HotWaterDistribution</sch:assert>
      <sch:assert role='ERROR' test='count(h:Systems/h:SolarThermal/h:SolarThermalSystem) &lt;= 1'>Expected at most one Systems/SolarThermal/SolarThermalSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:Systems/h:ElectricPanels/h:ElectricPanel) &lt;= 1'>Expected at most one Systems/ElectricPanels/ElectricPanel</sch:assert>
      <sch:assert role='ERROR' test='count(h:Systems/h:Batteries/h:Battery) &lt;= 1'>Expected at most one Systems/Batteries/Battery</sch:assert>
      <sch:assert role='ERROR' test='count(h:Appliances/h:ClothesWasher) &lt;= 1'>Expected at most one Appliances/ClothesWasher</sch:assert>
      <sch:assert role='ERROR' test='count(h:Appliances/h:ClothesDryer) &lt;= 1'>Expected at most one Appliances/ClothesDryer</sch:assert>
      <sch:assert role='ERROR' test='count(h:Appliances/h:Dishwasher) &lt;= 1'>Expected at most one Appliances/Dishwasher</sch:assert>
      <sch:assert role='ERROR' test='count(h:Appliances/h:CookingRange) &lt;= 1'>Expected at most one Appliances/CookingRange</sch:assert>
      <sch:assert role='ERROR' test='count(h:Appliances/h:Oven) &lt;= 1'>Expected at most one Appliances/Oven</sch:assert>
      <sch:assert role='ERROR' test='count(h:Lighting/h:CeilingFan) &lt;= 1'>Expected at most one Lighting/CeilingFan</sch:assert>
      <sch:assert role='ERROR' test='count(h:Pools/h:Pool) &lt;= 1'>Expected at most one Pools/Pool</sch:assert>
      <sch:assert role='ERROR' test='count(h:Spas/h:PermanentSpa) &lt;= 1'>Expected at most one Spas/PermanentSpa</sch:assert>
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType="other"]) = 1'>Expected one MiscLoads/PlugLoad[PlugLoadType="other"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType="TV other"]) &lt;= 1'>Expected at most one MiscLoads/PlugLoad[PlugLoadType="TV other"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType="electric vehicle charging"]) &lt;= 1'>Expected at most one MiscLoads/PlugLoad[PlugLoadType="electric vehicle charging"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:PlugLoad[h:PlugLoadType="well pump"]) &lt;= 1'>Expected at most one MiscLoads/PlugLoad[PlugLoadType="well pump"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:FuelLoad[h:FuelLoadType="grill"]) &lt;= 1'>Expected at most one MiscLoads/FuelLoad[FuelLoadType="grill"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:FuelLoad[h:FuelLoadType="lighting"]) &lt;= 1'>Expected at most one MiscLoads/FuelLoad[FuelLoadType="lighting"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:MiscLoads/h:FuelLoad[h:FuelLoadType="fireplace"]) &lt;= 1'>Expected at most one MiscLoads/FuelLoad[FuelLoadType="fireplace"]</sch:assert>
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
      <sch:assert role='ERROR' test='count(h:extension/h:HVACSizingControl) &lt;= 1'>Expected at most one extension/HVACSizingControl</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ShadingControl) &lt;= 1'>Expected at most one extension/ShadingControl</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:NaturalVentilationAvailabilityDaysperWeek) &lt;= 1'>Expected at most one extension/NaturalVentilationAvailabilityDaysperWeek</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:NaturalVentilationAvailabilityDaysperWeek) &gt;= 0 or not(h:extension/h:NaturalVentilationAvailabilityDaysperWeek)'>Expected extension/NaturalVentilationAvailabilityDaysperWeek to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:NaturalVentilationAvailabilityDaysperWeek) &lt;= 7 or not(h:extension/h:NaturalVentilationAvailabilityDaysperWeek)'>Expected extension/NaturalVentilationAvailabilityDaysperWeek to be less than or equal to 7</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ElectricPanelBaselinePeakPower) &lt;= 1'>Expected at most one extension/ElectricPanelBaselinePeakPower</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ElectricPanelBaselinePeakPower) &gt; 0 or not(h:extension/h:ElectricPanelBaselinePeakPower)'>Expected extension/ElectricPanelBaselinePeakPower to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACSizingControl]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:extension/h:HVACSizingControl'>
      <sch:assert role='ERROR' test='count(h:HeatPumpSizingMethodology) &lt;= 1'>Expected at most one HeatPumpSizingMethodology</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpSizingMethodology[text()="ACCA" or text()="HERS" or text()="MaxLoad"] or not(h:HeatPumpSizingMethodology)'>Expected HeatPumpSizingMethodology to be 'ACCA' or 'HERS' or 'MaxLoad'</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatPumpBackupSizingMethodology) &lt;= 1'>Expected at most one HeatPumpBackupSizingMethodology</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpBackupSizingMethodology[text()="emergency" or text()="supplemental"] or not(h:HeatPumpBackupSizingMethodology)'>Expected HeatPumpBackupSizingMethodology to be 'emergency' or 'supplemental'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AllowIncreasedFixedCapacities) &lt;= 1'>Expected at most one AllowIncreasedFixedCapacities</sch:assert>
      <sch:assert role='ERROR' test='h:AllowIncreasedFixedCapacities[text()="true" or text()="false"] or not(h:AllowIncreasedFixedCapacities)'>Expected AllowIncreasedFixedCapacities to be 'true' or 'false'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:HeatingDesignTemperature) &lt;= 1'>Expected at most one ManualJInputs/WinterDesignTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:CoolingDesignTemperature) &lt;= 1'>Expected at most one ManualJInputs/SummerDesignTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:DailyTemperatureRange) &lt;= 1'>Expected at most one ManualJInputs/DailyTemperatureRange</sch:assert>
      <sch:assert role='ERROR' test='h:ManualJInputs/h:DailyTemperatureRange[text()="low" or text()="medium" or text()="high"] or not(h:ManualJInputs/h:DailyTemperatureRange)'>Expected ManualJInputs/DailyTemperatureRange to be 'low' or 'medium' or 'high'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:HumidityDifference) &lt;= 1'>Expected at most one ManualJInputs/HumidityDifference</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:HeatingSetpoint) &lt;= 1'>Expected at most one ManualJInputs/HeatingSetpoint</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:CoolingSetpoint) &lt;= 1'>Expected at most one ManualJInputs/CoolingSetpoint</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:HumiditySetpoint) &lt;= 1'>Expected at most one ManualJInputs/HumiditySetpoint</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:HumiditySetpoint) &gt; 0 or not(h:ManualJInputs/h:HumiditySetpoint)'>Expected ManualJInputs/HumiditySetpoint to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:HumiditySetpoint) &lt; 1 or not(h:ManualJInputs/h:HumiditySetpoint)'>Expected ManualJInputs/HumiditySetpoint to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:InternalLoadsSensible) &lt;= 1'>Expected at most one ManualJInputs/InternalLoadsSensible</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:InternalLoadsSensible) &gt;= 0 or not(h:ManualJInputs/h:InternalLoadsSensible)'>Expected ManualJInputs/InternalLoadsSensible to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:InternalLoadsLatent) &lt;= 1'>Expected at most one ManualJInputs/InternalLoadsLatent</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:InternalLoadsLatent) &gt;= 0 or not(h:ManualJInputs/h:InternalLoadsLatent)'>Expected ManualJInputs/InternalLoadsLatent to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:NumberofOccupants) &lt;= 1'>Expected at most one ManualJInputs/NumberofOccupants</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:NumberofOccupants) &gt;= 0 or not(h:ManualJInputs/h:NumberofOccupants)'>Expected ManualJInputs/NumberofOccupants to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:InfiltrationShieldingClass) &lt;= 1'>Expected at most one ManualJInputs/InfiltrationShieldingClass</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:InfiltrationShieldingClass) &gt;= 1 or not(h:ManualJInputs/h:InfiltrationShieldingClass)'>Expected ManualJInputs/InfiltrationShieldingClass to be greater than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:ManualJInputs/h:InfiltrationShieldingClass) &lt;= 5 or not(h:ManualJInputs/h:InfiltrationShieldingClass)'>Expected ManualJInputs/InfiltrationShieldingClass to be less than or equal to 5</sch:assert>
      <sch:assert role='ERROR' test='count(h:ManualJInputs/h:InfiltrationMethod) &lt;= 1'>Expected at most one ManualJInputs/InfiltrationMethod</sch:assert>
      <sch:assert role='ERROR' test='h:ManualJInputs/h:InfiltrationMethod[text()="default infiltration table" or text()="blower door"] or not(h:ManualJInputs/h:InfiltrationMethod)'>Expected InfiltrationMethod/DailyTemperatureRange to be 'default infiltration table' or 'blower door'</sch:assert>
      <!-- Moved/deprecated UseMaxLoadForHeatPumps input; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/1039 -->
      <sch:assert role='ERROR' test='count(h:UseMaxLoadForHeatPumps) = 0'>UseMaxLoadForHeatPumps has been replaced by HeatPumpSizingMethodology</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ManualJInfiltrationMethod=DefaultInfiltrationTable]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:BuildingSummary/h:extension/h:HVACSizingControl/h:ManualJInputs/h:InfiltrationMethod="default infiltration table"]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:LeakinessDescription]) = 1'>Expected Enclosure/AirInfiltration/AirInfiltrationMeasurement[LeakinessDescription] if ManualJInputs/InfiltrationMethod="default infiltration table"</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ManualJInfiltrationMethod=BlowerDoor]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:BuildingSummary/h:extension/h:HVACSizingControl/h:ManualJInputs/h:InfiltrationMethod="blower door"]'>
      <sch:assert role='ERROR' test='count(h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:BuildingAirLeakage/h:AirLeakage | h:EffectiveLeakageArea | h:SpecificLeakageArea]) = 1'>Expected Enclosure/AirInfiltration/AirInfiltrationMeasurement[BuildingAirLeakage/AirLeakage | EffectiveLeakageArea | SpecificLeakageArea] if ManualJInputs/InfiltrationMethod="blower door"</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ShadingControl]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:extension/h:ShadingControl'>
      <sch:assert role='ERROR' test='count(h:SummerBeginMonth) = 1'>Expected SummerBeginMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:SummerBeginDayOfMonth) = 1'>Expected SummerBeginDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:SummerEndMonth) = 1'>Expected SummerEndMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:SummerEndDayOfMonth) = 1'>Expected SummerEndDayOfMonth</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Site]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:Site'>
      <sch:assert role='ERROR' test='count(h:extension/h:Neighbors) &lt;= 1'>Expected at most one extension/Neighbors</sch:assert>
      <!-- Moved/deprecated ShelterCoefficient input; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/653 -->
      <sch:assert role='ERROR' test='count(h:extension/h:ShelterCoefficient) = 0'>extension/ShelterCoefficient has been replaced by ShieldingofHome</sch:assert>
      <!-- Moved/deprecated extension/GroundConductivity input; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/1391 -->
      <sch:assert role='ERROR' test='count(h:extension/h:GroundConductivity) = 0'>extension/GroundConductivity has been replaced by Soil/Conductivity</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Soil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:Site/h:Soil'>
      <sch:assert role='ERROR' test='count(h:extension/h:Diffusivity) &lt;= 1'>Expected at most one extension/Diffusivity</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:Diffusivity) &gt; 0 or not(h:extension/h:Diffusivity)'>Expected extension/Diffusivity to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Neighbors]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:Site/h:extension/h:Neighbors'>
      <sch:assert role='ERROR' test='count(h:NeighborBuilding) &gt;= 1'>Expected NeighborBuilding</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[NeighborBuilding]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:Site/h:extension/h:Neighbors/h:NeighborBuilding'>
      <sch:assert role='ERROR' test='count(h:Azimuth) + count(h:Orientation) &gt;= 1'>Expected Azimuth or Orientation</sch:assert>
      <sch:assert role='ERROR' test='number(h:Azimuth) &gt;= 0 or not(h:Azimuth)'>Expected Azimuth to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:Azimuth) &lt; 360 or not(h:Azimuth)'>Expected Azimuth to be less than 360</sch:assert>
      <sch:assert role='ERROR' test='h:Orientation[text()="northeast" or text()="east" or text()="southeast" or text()="south" or text()="southwest" or text()="west" or text()="northwest" or text()="north"] or not(h:Orientation)'>Expected Orientation to be 'northeast' or 'east' or 'southeast' or 'south' or 'southwest' or 'west' or 'northwest' or 'north'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Distance) = 1'>Expected Distance</sch:assert>
      <sch:assert role='ERROR' test='number(h:Distance) &gt; 0 or not(h:Distance)'>Expected Distance to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:Height) &lt;= 1'>Expected at most one Height</sch:assert>
      <sch:assert role='ERROR' test='number(h:Height) &gt; 0 or not(h:Height)'>Expected Height to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingOccupancy]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingOccupancy'>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GeneralWaterUseUsageMultiplier) &lt;= 1'>Expected at most one extension/GeneralWaterUseUsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:GeneralWaterUseUsageMultiplier) &gt;= 0 or not(h:extension/h:GeneralWaterUseUsageMultiplier)'>Expected extension/GeneralWaterUseUsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GeneralWaterUseWeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/GeneralWaterUseWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GeneralWaterUseWeekendScheduleFractions) &lt;= 1'>Expected at most one extension/GeneralWaterUseWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GeneralWaterUseMonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/GeneralWaterUseMonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingConstruction]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingConstruction'>
      <sch:assert role='ERROR' test='h:ResidentialFacilityType[text()="single-family detached" or text()="single-family attached" or text()="apartment unit" or text()="manufactured home"]'>Expected ResidentialFacilityType to be 'single-family detached' or 'single-family attached' or 'apartment unit' or 'manufactured home'</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofConditionedFloors) = 1'>Expected NumberofConditionedFloors</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofConditionedFloorsAboveGrade) = 1'>Expected NumberofConditionedFloorsAboveGrade</sch:assert>
      <!-- We are more strict than HPXML schema for NumberofConditionedFloorsAboveGrade; see https://github.com/NatLabRockies/OpenStudio-HPXML/issues/1755 -->
      <sch:assert role='ERROR' test='number(h:NumberofConditionedFloorsAboveGrade) &gt; 0 or not(h:NumberofConditionedFloorsAboveGrade)'>Expected NumberofConditionedFloorsAboveGrade to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofConditionedFloors) &gt;= number(h:NumberofConditionedFloorsAboveGrade) or not(h:NumberofConditionedFloors) or not(h:NumberofConditionedFloorsAboveGrade)'>Expected NumberofConditionedFloors to be greater than or equal to NumberofConditionedFloorsAboveGrade</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofBedrooms) = 1'>Expected NumberofBedrooms</sch:assert>
      <sch:assert role='ERROR' test='count(h:ConditionedFloorArea) = 1'>Expected ConditionedFloorArea</sch:assert>
      <sch:assert role='ERROR' test='number(h:ConditionedFloorArea) &gt;= (sum(../../h:Enclosure/h:Slabs/h:Slab[h:InteriorAdjacentTo="conditioned space" or h:InteriorAdjacentTo="basement - conditioned"]/h:Area) + sum(../../h:Enclosure/h:Floors/h:Floor[h:InteriorAdjacentTo="conditioned space" and not(h:ExteriorAdjacentTo="attic - vented" or h:ExteriorAdjacentTo="attic - unvented" or ((h:ExteriorAdjacentTo="other housing unit" or h:ExteriorAdjacentTo="other heated space" or h:ExteriorAdjacentTo="other multifamily buffer space" or h:ExteriorAdjacentTo="other non-freezing space") and h:FloorOrCeiling="ceiling"))]/h:Area) - 1) or not(h:ConditionedFloorArea)'>Expected ConditionedFloorArea to be greater than or equal to the sum of conditioned slab/floor areas.</sch:assert>
      <!-- Moved/deprecated HasFlueOrChimney input; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/1379 -->
      <sch:assert role='ERROR' test='count(h:extension/h:HasFlueOrChimney) = 0'>extension/HasFlueOrChimney has been replaced by /HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/extension/HasFlueOrChimneyInConditionedSpace</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:NumberofUnits) &gt; 1'>NumberofUnits is greater than 1, indicating that the HPXML Building represents multiple dwelling units; simulation outputs will reflect this unit multiplier.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingType=SFAorMF]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]'>
      <!-- Warnings -->
      <sch:report role='WARN' test='count(//h:ExteriorAdjacentTo[text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]) = 0'>ResidentialFacilityType is "single-family attached" or "apartment unit", but no attached surfaces were found. This may result in erroneous results (e.g., for infiltration).</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BuildingType=SFDorMH]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family detached" or text()="manufactured home"]'>
      <sch:assert role='ERROR' test='count(../../../../../h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"]) = 0'>Expected WholeSFAorMFBuildingSimulation to not be "true" if ResidentialFacilityType is "single-family detached" or "manufactured home"</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClimateZoneIECC]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:ClimateandRiskZones/h:ClimateZoneIECC'>
      <sch:assert role='ERROR' test='count(h:Year) = 1'>Expected Year</sch:assert>
      <sch:assert role='ERROR' test='count(h:ClimateZone) = 1'>Expected ClimateZone</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Zone]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Zones/h:Zone'>
      <sch:assert role='ERROR' test='count(h:ZoneType) = 1'>Expected ZoneType</sch:assert>
      <sch:assert role='ERROR' test='count(h:Spaces) = 1'>Expected Spaces</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HasCondZones=HeatingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Zones/h:Zone[h:ZoneType="conditioned"]]/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem'>
      <sch:assert role='ERROR' test='count(h:AttachedToZone) = 1'>Expected AttachedToZone for each HVAC system if there is a Zone[ZoneType="conditioned"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HasCondZones=CoolingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Zones/h:Zone[h:ZoneType="conditioned"]]/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem'>
      <sch:assert role='ERROR' test='count(h:AttachedToZone) = 1'>Expected AttachedToZone for each HVAC system if there is a Zone[ZoneType="conditioned"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HasCondZones=HeatPump]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Zones/h:Zone[h:ZoneType="conditioned"]]/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump'>
      <sch:assert role='ERROR' test='count(h:AttachedToZone) = 1'>Expected AttachedToZone for each HVAC system if there is a Zone[ZoneType="conditioned"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HasCondZones=Surface]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Zones/h:Zone[h:ZoneType="conditioned"]]/h:Enclosure/*/*[contains(h:InteriorAdjacentTo, "conditioned") and (not(h:ExteriorAdjacentTo) or h:ExteriorAdjacentTo!="other housing unit")]'>
      <sch:assert role='ERROR' test='count(h:AttachedToSpace) = 1'>Expected AttachedToSpace for a surface adjacent to conditioned space if there is a Zone[ZoneType="conditioned"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Space=Conditioned]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Zones/h:Zone[h:ZoneType="conditioned"]/h:Spaces/h:Space'>
      <sch:assert role='ERROR' test='count(h:FloorArea) = 1'>Expected FloorArea</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ManualJInputs/h:InternalLoadsSensible) &lt;= 1'>Expected at most one extension/ManualJInputs/InternalLoadsSensible</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ManualJInputs/h:InternalLoadsSensible) &gt;= 0 or not(h:extension/h:ManualJInputs/h:InternalLoadsSensible)'>Expected extension/ManualJInputs/InternalLoadsSensible to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(../*/h:extension/h:ManualJInputs/h:InternalLoadsSensible) = count(../h:Space) or count(../*/h:extension/h:ManualJInputs/h:InternalLoadsSensible) = 0'>Expected extension/ManualJInputs/InternalLoadsSensible for all Spaces or no Spaces</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ManualJInputs/h:InternalLoadsLatent) &lt;= 1'>Expected at most one extension/ManualJInputs/InternalLoadsLatent</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ManualJInputs/h:InternalLoadsLatent) &gt;= 0 or not(h:extension/h:ManualJInputs/h:InternalLoadsLatent)'>Expected extension/ManualJInputs/InternalLoadsLatent to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(../*/h:extension/h:ManualJInputs/h:InternalLoadsLatent) = count(../h:Space) or count(../*/h:extension/h:ManualJInputs/h:InternalLoadsLatent) = 0'>Expected extension/ManualJInputs/InternalLoadsLatent for all Spaces or no Spaces</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ManualJInputs/h:NumberofOccupants) &lt;= 1'>Expected at most one extension/ManualJInputs/NumberofOccupants</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ManualJInputs/h:NumberofOccupants) &gt;= 0 or not(h:extension/h:ManualJInputs/h:NumberofOccupants)'>Expected extension/ManualJInputs/NumberofOccupants to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(../*/h:extension/h:ManualJInputs/h:NumberofOccupants) = count(../h:Space) or count(../*/h:extension/h:ManualJInputs/h:NumberofOccupants) = 0'>Expected extension/ManualJInputs/NumberofOccupants for all Spaces or no Spaces</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ManualJInputs/h:FenestrationLoadProcedure) &lt;= 1'>Expected at most one extension/ManualJInputs/FenestrationLoadProcedure</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:ManualJInputs/h:FenestrationLoadProcedure[text()="standard" or text()="peak"] or not(h:extension/h:ManualJInputs/h:FenestrationLoadProcedure)'>Expected extension/ManualJInputs/FenestrationLoadProcedure to be 'standard' or 'peak'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirInfiltrationMeasurement=SFAorMultifamily]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:BuildingSummary/h:BuildingConstruction/h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]/h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:BuildingAirLeakage/h:AirLeakage | h:EffectiveLeakageArea | h:SpecificLeakageArea]'>
      <sch:assert role='ERROR' test='h:TypeOfInfiltrationLeakage[text()="unit total" or text()="unit exterior only"]'>Expected TypeOfInfiltrationLeakage to be 'unit total' or 'unit exterior only' if ResidentialFacilityType is "single-family attached" or "apartment unit"</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:Aext) &lt;= 1'>Expected at most one extension/Aext</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:Aext) &gt; 0 or not(h:extension/h:Aext)'>Expected extension/Aext to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirInfiltrationMeasurement=ACHorCFM]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement[h:BuildingAirLeakage/h:UnitofMeasure[text()="ACH" or text()="CFM"]]'>
      <sch:assert role='ERROR' test='count(h:HousePressure) = 1'>Expected HousePressure if UnitofMeasure=("ACH" or "CFM")</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirInfiltrationMeasurement=LeakinessDescription]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails[h:Enclosure/h:AirInfiltration/h:AirInfiltrationMeasurement/h:LeakinessDescription]'>
      <sch:assert role='ERROR' test='count(h:BuildingSummary/h:BuildingConstruction/h:YearBuilt) = 1'>Expected BuildingSummary/BuildingConstruction/YearBuilt if AirInfiltrationMeasurement/LeakinessDescription is specified</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[VentedAttic=VentilationRate]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Attics/h:Attic[h:Vented="true"]/h:VentilationRate'>
      <sch:assert role='ERROR' test='h:UnitofMeasure[text()="SLA" or text()="ACHnatural"]'>Expected UnitofMeasure to be 'SLA' or 'ACHnatural'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Value) = 1'>Expected Value</sch:assert> <!-- Can remove this when https://github.com/hpxmlwg/hpxml/pull/467 is available -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[VentedCrawl=VentilationRate]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Foundations/h:Foundation[h:FoundationType/h:Crawlspace[h:Vented="true"]]/h:VentilationRate'>
      <sch:assert role='ERROR' test='h:UnitofMeasure[text()="SLA"]'>Expected UnitofMeasure to be 'SLA'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Value) = 1'>Expected Value</sch:assert> <!-- Can remove this when https://github.com/hpxmlwg/hpxml/pull/467 is available -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SameasSurfaces]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/*/*[h:SystemIdentifier/@sameas and /h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"]]'>
      <sch:assert role='ERROR' test='count(*) = 1'>Expected only SystemIdentifier to be specified when sameas attribute used</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Roof]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Roofs/h:Roof'>
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="attic - vented" or text()="attic - unvented" or text()="conditioned space" or text()="garage"]'>Expected InteriorAdjacentTo to be 'attic - vented' or 'attic - unvented' or 'conditioned space' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected Area</sch:assert>
      <sch:assert role='ERROR' test='h:RoofType[text()="asphalt or fiberglass shingles" or text()="wood shingles or shakes" or text()="shingles" or text()="slate or tile shingles" or text()="metal surfacing" or text()="plastic/rubber/synthetic sheeting" or text()="expanded polystyrene sheathing" or text()="concrete" or text()="cool roof"] or not(h:RoofType)'>Expected RoofType to be 'asphalt or fiberglass shingles' or 'wood shingles or shakes' or 'shingles' or 'slate or tile shingles' or 'metal surfacing' or 'plastic/rubber/synthetic sheeting' or 'expanded polystyrene sheathing' or 'concrete' or 'cool roof'</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorFinish/h:Type[text()="gypsum board" or text()="gypsum composite board" or text()="plaster" or text()="wood" or text()="not present"] or not(h:InteriorFinish/h:Type)'>Expected InteriorFinish/Type to be 'gypsum board' or 'gypsum composite board' or 'plaster' or 'wood' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Pitch) = 1'>Expected Pitch</sch:assert>
      <sch:assert role='ERROR' test='count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected Insulation/AssemblyEffectiveRValue</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[RimJoist]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:RimJoists/h:RimJoist[not(h:SystemIdentifier/@sameas and /h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"])]'>
      <sch:assert role='ERROR' test='h:ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]'>Expected ExteriorAdjacentTo to be 'outside' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="conditioned space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage"]'>Expected InteriorAdjacentTo to be 'conditioned space' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected Area</sch:assert>
      <sch:assert role='ERROR' test='h:Siding[text()="wood siding" or text()="vinyl siding" or text()="stucco" or text()="fiber cement siding" or text()="brick veneer" or text()="stone veneer" or text()="aluminum siding" or text()="masonite siding" or text()="composite shingle siding" or text()="asbestos siding" or text()="synthetic stucco" or text()="not present"] or not(h:Siding)'>Expected Siding to be 'wood siding' or 'vinyl siding' or 'stucco' or 'fiber cement siding' or 'brick veneer' or 'stone veneer' or 'aluminum siding' or 'masonite siding' or 'composite shingle siding' or 'asbestos siding' or 'synthetic stucco' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected Insulation/AssemblyEffectiveRValue</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Wall]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Walls/h:Wall[not(h:SystemIdentifier/@sameas and /h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"])]'>
      <sch:assert role='ERROR' test='h:ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]'>Expected ExteriorAdjacentTo to be 'outside' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="conditioned space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage"]'>Expected InteriorAdjacentTo to be 'conditioned space' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:WallType[h:WoodStud | h:DoubleWoodStud | h:ConcreteMasonryUnit | h:StructuralInsulatedPanel | h:InsulatedConcreteForms | h:SteelFrame | h:SolidConcrete | h:StructuralBrick | h:StrawBale | h:Stone | h:LogWall | h:Adobe]) = 1'>Expected WallType[WoodStud | DoubleWoodStud | ConcreteMasonryUnit | StructuralInsulatedPanel | InsulatedConcreteForms | SteelFrame | SolidConcrete | StructuralBrick | StrawBale | Stone | LogWall | Adobe]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected Area</sch:assert>
      <sch:assert role='ERROR' test='h:Siding[text()="wood siding" or text()="vinyl siding" or text()="stucco" or text()="fiber cement siding" or text()="brick veneer" or text()="stone veneer" or text()="aluminum siding" or text()="masonite siding" or text()="composite shingle siding" or text()="asbestos siding" or text()="synthetic stucco" or text()="not present"] or not(h:Siding)'>Expected Siding to be 'wood siding' or 'vinyl siding' or 'stucco' or 'fiber cement siding' or 'brick veneer' or 'stone veneer' or 'aluminum siding' or 'masonite siding' or 'composite shingle siding' or 'asbestos siding' or 'synthetic stucco' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorFinish/h:Type[text()="gypsum board" or text()="gypsum composite board" or text()="plaster" or text()="wood" or text()="not present"] or not(h:InteriorFinish/h:Type)'>Expected InteriorFinish/Type to be 'gypsum board' or 'gypsum composite board' or 'plaster' or 'wood' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected Insulation/AssemblyEffectiveRValue</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FoundationWall]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:FoundationWalls/h:FoundationWall[not(h:SystemIdentifier/@sameas and /h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"])]'>
      <sch:assert role='ERROR' test='h:ExteriorAdjacentTo[text()="ground" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]'>Expected ExteriorAdjacentTo to be 'ground' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage"]'>Expected InteriorAdjacentTo to be 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Height) = 1'>Expected Height</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) + count(h:Length) &gt;= 1'>Expected Area or Length</sch:assert>
      <sch:assert role='ERROR' test='number(h:Thickness) &gt; 0 or not(h:Thickness)'>Expected Thickness to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorFinish/h:Type[text()="gypsum board" or text()="gypsum composite board" or text()="plaster" or text()="wood" or text()="not present"] or not(h:InteriorFinish/h:Type)'>Expected InteriorFinish/Type to be 'gypsum board' or 'gypsum composite board' or 'plaster' or 'wood' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DepthBelowGrade) = 1'>Expected DepthBelowGrade</sch:assert>
      <sch:assert role='ERROR' test='number(h:DepthBelowGrade) &lt;= number(h:Height) or not(h:DepthBelowGrade) or not(h:Height)'>Expected DepthBelowGrade to be less than or equal to Height</sch:assert>
      <!-- Insulation: either specify interior and exterior layers OR assembly R-value: -->
      <sch:assert role='ERROR' test='count(h:Insulation/h:Layer[h:InstallationType[text()="continuous - interior"]]) + count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected Insulation/Layer[InstallationType="continuous - interior"] or Insulation/AssemblyEffectiveRValue but not both</sch:assert>
      <sch:assert role='ERROR' test='count(h:Insulation/h:Layer[h:InstallationType[text()="continuous - exterior"]]) + count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected Insulation/Layer[InstallationType="continuous - exterior"] or Insulation/AssemblyEffectiveRValue but not both</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:Thickness) &lt; 1 and number(h:Thickness) &gt; 0'>Thickness is less than 1 inch; this may indicate incorrect units.</sch:report>
      <sch:report role='WARN' test='number(h:Thickness) &gt; 12'>Thickness is greater than 12 inches; this may indicate incorrect units.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FoundationWallInsulationLayer]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:FoundationWalls/h:FoundationWall/h:Insulation/h:Layer[h:InstallationType="continuous - exterior" or h:InstallationType="continuous - interior"]'>
      <sch:assert role='ERROR' test='count(h:NominalRValue) = 1'>Expected NominalRValue</sch:assert>
      <sch:assert role='ERROR' test='number(h:DistanceToBottomOfInsulation) &gt;= number(h:DistanceToTopOfInsulation) or not(h:DistanceToBottomOfInsulation) or not(h:DistanceToTopOfInsulation)'>Expected DistanceToBottomOfInsulation to be greater than or equal to DistanceToTopOfInsulation</sch:assert>
      <sch:assert role='ERROR' test='number(h:DistanceToBottomOfInsulation) &lt;= number(../../h:Height) or not(h:DistanceToBottomOfInsulation) or not(../../h:Height)'>Expected DistanceToBottomOfInsulation to be less than or equal to ../../Height</sch:assert>
      <!-- Moved/deprecated extension/DistanceToTopOfInsulation & extension/DistanceToBottomOfInsulation inputs; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/894 -->
      <sch:assert role='ERROR' test='count(h:extension/h:DistanceToTopOfInsulation) = 0'>extension/DistanceToTopOfInsulation has been replaced by DistanceToTopOfInsulation</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:DistanceToBottomOfInsulation) = 0'>extension/DistanceToBottomOfInsulation has been replaced by DistanceToBottomOfInsulation</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Floor]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Floors/h:Floor[not(h:SystemIdentifier/@sameas and /h:HPXML/h:SoftwareInfo/h:extension/h:WholeSFAorMFBuildingSimulation[text()="true"])]'>
      <sch:assert role='ERROR' test='h:ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="manufactured home underbelly"]'>Expected ExteriorAdjacentTo to be 'outside' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'manufactured home underbelly'</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="conditioned space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage"]'>Expected InteriorAdjacentTo to be 'conditioned space' or 'attic - vented' or 'attic - unvented' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FloorType[h:WoodFrame | h:StructuralInsulatedPanel | h:SteelFrame | h:SolidConcrete]) = 1'>Expected FloorType[WoodFrame | StructuralInsulatedPanel | SteelFrame | SolidConcrete]</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected Area</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorFinish/h:Type[text()="gypsum board" or text()="gypsum composite board" or text()="plaster" or text()="wood" or text()="not present"] or not(h:InteriorFinish/h:Type)'>Expected InteriorFinish/Type to be 'gypsum board' or 'gypsum composite board' or 'plaster' or 'wood' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Insulation/h:AssemblyEffectiveRValue) = 1'>Expected Insulation/AssemblyEffectiveRValue</sch:assert>
      <!-- Moved/deprecated extension/OtherSpaceAboveOrBelow input; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/1203 -->
      <sch:assert role='ERROR' test='count(h:extension/h:OtherSpaceAboveOrBelow) = 0'>extension/OtherSpaceAboveOrBelow has been replaced by FloorOrCeiling</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FloorType=AdjacentToOther]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Floors/h:Floor[h:ExteriorAdjacentTo[text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]]'>
      <sch:assert role='ERROR' test='count(h:FloorOrCeiling) = 1'>Expected FloorOrCeiling</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Slab]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Slabs/h:Slab'>
      <sch:assert role='ERROR' test='h:InteriorAdjacentTo[text()="conditioned space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="garage"]'>Expected InteriorAdjacentTo to be 'conditioned space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'garage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExposedPerimeter) = 1'>Expected ExposedPerimeter</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerimeterInsulation/h:Layer/h:NominalRValue) = 1'>Expected PerimeterInsulation/Layer/NominalRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerimeterInsulation/h:Layer/h:InsulationDepth) = 1'>Expected PerimeterInsulation/Layer/InsulationDepth</sch:assert>
      <sch:assert role='ERROR' test='count(h:UnderSlabInsulation/h:Layer/h:NominalRValue) = 1'>Expected UnderSlabInsulation/Layer/NominalRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:UnderSlabInsulation/h:Layer/h:InsulationWidth) + count(h:UnderSlabInsulation/h:Layer/h:InsulationSpansEntireSlab[text()="true"]) = 1'>Expected UnderSlabInsulation/Layer/InsulationWidth or UnderSlabInsulation/Layer/InsulationSpansEntireSlab="true" but not both</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CarpetFraction) &lt;= 1'>Expected at most one extension/CarpetFraction</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CarpetFraction) &gt;= 0 or not(h:extension/h:CarpetFraction)'>Expected extension/CarpetFraction to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CarpetFraction) &lt;= 1 or not(h:extension/h:CarpetFraction)'>Expected extension/CarpetFraction to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CarpetRValue) &lt;= 1'>Expected at most one extension/CarpetRValue</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CarpetRValue) &gt;= 0 or not(h:extension/h:CarpetRValue)'>Expected extension/CarpetRValue to be greater than or equal to 0</sch:assert>
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
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) + count(h:Orientation) &gt;= 1'>Expected Azimuth or Orientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:UFactor) + count(h:GlassLayers) &gt;= 1'>Expected UFactor or GlassLayers</sch:assert>
      <sch:assert role='ERROR' test='count(h:SHGC) + count(h:GlassLayers) &gt;= 1'>Expected SHGC or GlassLayers</sch:assert>
      <sch:assert role='ERROR' test='h:GlassLayers[text()="single-pane" or text()="double-pane" or text()="triple-pane" or text()="glass block"] or not(h:GlassLayers) or h:UFactor'>Expected GlassLayers to be 'single-pane' or 'double-pane' or 'triple-pane' or 'glass block'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorShading) &lt;= 1'>Expected at most one ExteriorShading</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorShading) &lt;= 1'>Expected at most one InteriorShading</sch:assert>
      <sch:assert role='ERROR' test='h:StormWindow/h:GlassType[text()="clear" or text()="low-e"] or not(h:StormWindow/h:GlassType)'>Expected StormWindow/GlassType to be 'clear' or 'low-e'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToWall) = 1'>Expected AttachedToWall</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='h:ExteriorShading/h:Type[text()="external overhangs"] and count(h:Overhangs) &gt; 0'>Exterior shading type is 'external overhangs', but overhangs are explicitly defined; exterior shading type will be ignored.</sch:report>
      <sch:report role='WARN' test='h:ExteriorShading/h:Type[text()="awnings"] and count(h:Overhangs) &gt; 0'>Exterior shading type is 'external overhangs', but overhangs are explicitly defined; exterior shading type will be ignored.</sch:report>
      <sch:report role='WARN' test='h:ExteriorShading/h:Type[text()="building"] and count(../../../h:BuildingSummary/h:Site/h:extension/h:Neighbors/h:NeighborBuilding) &gt; 0'>Exterior shading type is 'building', but neighbor buildings are explicitly defined; exterior shading type will be ignored.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Window=PhysicalProperties]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window[not(h:UFactor) and h:GlassLayers[text()="single-pane" or text()="double-pane" or text()="triple-pane"]]'>
      <sch:assert role='ERROR' test='count(h:FrameType[h:Aluminum | h:Fiberglass | h:Metal | h:Vinyl | h:Wood]) = 1'>Expected FrameType[Aluminum | Fiberglass | Metal | Vinyl | Wood]</sch:assert>
      <sch:assert role='ERROR' test='h:GlassType[text()="clear" or text()="low-e" or text()="low-e, high-solar-gain" or text()="low-e, low-solar-gain" or text()="tinted" or text()="tinted/reflective" or text()="reflective"] or not(h:GlassType)'>Expected GlassType to be 'clear' or 'low-e' or 'low-e, high-solar-gain' or 'low-e, low-solar-gain' or 'tinted' or 'tinted/reflective' or 'reflective'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WindowOverhangs]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window/h:Overhangs'>
      <sch:assert role='ERROR' test='count(h:Depth) = 1'>Expected Depth</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:Depth) &gt; 72'>Depth is greater than 72 feet; this may indicate incorrect units.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WindowOverhangs=Present]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Windows/h:Window/h:Overhangs[number(h:Depth) > 0]'>
      <sch:assert role='ERROR' test='count(h:DistanceToTopOfWindow) = 1'>Expected DistanceToTopOfWindow</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistanceToBottomOfWindow) = 1'>Expected DistanceToBottomOfWindow</sch:assert>
      <sch:assert role='ERROR' test='number(h:DistanceToBottomOfWindow) &gt; number(h:DistanceToTopOfWindow) or not(h:DistanceToBottomOfWindow) or not(h:DistanceToTopOfWindow)'>Expected DistanceToBottomOfWindow to be greater than DistanceToTopOfWindow</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:DistanceToTopOfWindow) &gt; 12'>DistanceToTopOfWindow is greater than 12 feet; this may indicate incorrect units.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Skylight]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight'>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:Azimuth) + count(h:Orientation) &gt;= 1'>Expected Azimuth or Orientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:UFactor) + count(h:GlassLayers) &gt;= 1'>Expected UFactor or GlassLayers</sch:assert>
      <sch:assert role='ERROR' test='count(h:SHGC) + count(h:GlassLayers) &gt;= 1'>Expected SHGC or GlassLayers</sch:assert>
      <sch:assert role='ERROR' test='h:GlassLayers[text()="single-pane" or text()="double-pane" or text()="triple-pane" or text()="glass block"] or not(h:GlassLayers) or h:UFactor'>Expected GlassLayers to be 'single-pane' or 'double-pane' or 'triple-pane' or 'glass block'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ExteriorShading) &lt;= 1'>Expected at most one ExteriorShading</sch:assert>
      <sch:assert role='ERROR' test='h:StormWindow/h:GlassType[text()="clear" or text()="low-e"] or not(h:StormWindow/h:GlassType)'>Expected StormWindow/GlassType to be 'clear' or 'low-e'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToRoof) = 1'>Expected AttachedToRoof</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:Curb) &lt;= 1'>Expected at most one Curb</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:Shaft) &lt;= 1'>Expected at most one Shaft</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Skylight=PhysicalProperties]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight[not(h:UFactor) and h:GlassLayers[text()="single-pane" or text()="double-pane" or text()="triple-pane"]]'>
      <sch:assert role='ERROR' test='count(h:FrameType[h:Aluminum | h:Fiberglass | h:Metal | h:Vinyl | h:Wood]) = 1'>Expected FrameType[Aluminum | Fiberglass | Metal | Vinyl | Wood]</sch:assert>
      <sch:assert role='ERROR' test='h:GlassType[text()="clear" or text()="low-e" or text()="low-e, high-solar-gain" or text()="low-e, low-solar-gain" or text()="tinted" or text()="tinted/reflective" or text()="reflective"] or not(h:GlassType)'>Expected GlassType to be 'clear' or 'low-e' or 'low-e, high-solar-gain' or 'low-e, low-solar-gain' or 'tinted' or 'tinted/reflective' or 'reflective'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SkylightCurb]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight/h:extension/h:Curb'>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected Area</sch:assert>
      <sch:assert role='ERROR' test='number(h:Area) &gt; 0 or not(h:Area)'>Expected Area to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:AssemblyEffectiveRValue) = 1'>Expected AssemblyEffectiveRValue</sch:assert>
      <sch:assert role='ERROR' test='number(h:AssemblyEffectiveRValue) &gt; 0 or not(h:AssemblyEffectiveRValue)'>Expected AssemblyEffectiveRValue to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SkylightShaft]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Skylights/h:Skylight/h:extension/h:Shaft'>
      <sch:assert role='ERROR' test='count(../../h:AttachedToFloor) = 1'>Expected ../../AttachedToFloor</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected Area</sch:assert>
      <sch:assert role='ERROR' test='number(h:Area) &gt; 0 or not(h:Area)'>Expected Area to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:AssemblyEffectiveRValue) = 1'>Expected AssemblyEffectiveRValue</sch:assert>
      <sch:assert role='ERROR' test='number(h:AssemblyEffectiveRValue) &gt; 0 or not(h:AssemblyEffectiveRValue)'>Expected AssemblyEffectiveRValue to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Door]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:Doors/h:Door'>
      <sch:assert role='ERROR' test='count(h:AttachedToWall) = 1'>Expected AttachedToWall</sch:assert>
      <sch:assert role='ERROR' test='count(h:Area) = 1'>Expected Area</sch:assert>
      <sch:assert role='ERROR' test='count(h:RValue) = 1'>Expected RValue</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PartitionWallMass]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:extension/h:PartitionWallMass'>
      <sch:assert role='ERROR' test='count(h:AreaFraction) &lt;= 1'>Expected at most one AreaFraction</sch:assert>
      <sch:assert role='ERROR' test='number(h:AreaFraction) &gt;= 0 or not(h:AreaFraction)'>Expected AreaFraction to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorFinish/h:Type) &lt;= 1'>Expected at most one InteriorFinish/Type</sch:assert>
      <sch:assert role='ERROR' test='h:InteriorFinish/h:Type[text()="gypsum board" or text()="gypsum composite board" or text()="plaster" or text()="wood" or text()="not present"] or not(h:InteriorFinish/h:Type)'>Expected InteriorFinish/Type to be 'gypsum board' or 'gypsum composite board' or 'plaster' or 'wood' or 'not present'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InteriorFinish/h:Thickness) &lt;= 1'>Expected at most one InteriorFinish/Thickness</sch:assert>
      <sch:assert role='ERROR' test='number(h:InteriorFinish/h:Thickness) &gt;= 0 or not(h:InteriorFinish/h:Thickness)'>Expected InteriorFinish/Thickness to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FurnitureMass]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Enclosure/h:extension/h:FurnitureMass'>
      <sch:assert role='ERROR' test='count(h:AreaFraction) &lt;= 1'>Expected at most one AreaFraction</sch:assert>
      <sch:assert role='ERROR' test='number(h:AreaFraction) &gt;= 0 or not(h:AreaFraction)'>Expected AreaFraction to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:Type) &lt;= 1'>Expected at most one Type</sch:assert>
      <sch:assert role='ERROR' test='h:Type[text()="light-weight" or text()="heavy-weight"] or not(h:Type)'>Expected Type to be 'light-weight' or 'heavy-weight'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem'>
      <sch:assert role='ERROR' test='count(../../h:HVACControl) = 1'>Expected ../../HVACControl</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemType[h:ElectricResistance | h:Furnace | h:WallFurnace | h:FloorFurnace | h:Boiler | h:Stove | h:SpaceHeater | h:Fireplace]) = 1'>Expected HeatingSystemType[ElectricResistance | Furnace | WallFurnace | FloorFurnace | Boiler | Stove | SpaceHeater | Fireplace]</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingAutosizingFactor) &lt;= 1'>Expected at most one extension/HeatingAutosizingFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingAutosizingFactor) &gt; 0 or not (h:extension/h:HeatingAutosizingFactor)'>Expected HeatingAutosizingFactor to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingAutosizingLimit) &lt;= 1'>Expected at most one extension/HeatingAutosizingLimit</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingAutosizingLimit) &gt; 0 or not (h:extension/h:HeatingAutosizingLimit)'>Expected HeatingAutosizingLimit to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=Resistance]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:ElectricResistance]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected no DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity"]'>Expected HeatingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected FractionHeatLoadServed</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt; 0.95'>Percent efficiency should typically be greater than or equal to 0.95.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt; 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=Furnace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Furnace]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity" or text()="gravity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType=("regular velocity" or "gravity") or ../../HVACDistribution/DistributionSystemType/Other="DSE"</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"]'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) &lt;= 1'>Expected at most one extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected at most one extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingDesignAirflowCFM) &lt;= 1'>Expected at most one extension/HeatingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:HeatingDesignAirflowCFM)'>Expected extension/HeatingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) &lt;= 1'>Expected at most one extension/AirflowDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt; 0.5'>AFUE should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt; 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=WallFurnace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:WallFurnace]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected no DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"]'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected at most one extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt; 0.5'>AFUE should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt; 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=FloorFurnace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:FloorFurnace]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected no DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"]'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected at most one extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt; 0.5'>AFUE should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt; 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=InUnitBoiler]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Boiler and (not(h:IsSharedSystem) or h:IsSharedSystem="false")]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected ../../HVACDistribution/DistributionSystemType/HydronicDistribution/HydronicDistributionType=("radiator" or "baseboard" or "radiant floor" or "radiant ceiling") or ../../HVACDistribution/DistributionSystemType/Other="DSE"</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"]'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected FractionHeatLoadServed</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt; 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt; 0.5'>AFUE should typically be greater than or equal to 0.5.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=SharedBoiler]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Boiler and h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected ../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType=("single-family attached" or "apartment unit")]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling" or text()="water loop"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="fan coil"]) &gt;= 1'>Expected ../../HVACDistribution/DistributionSystemType/HydronicDistribution/HydronicDistributionType=("radiator" or "baseboard" or "radiant floor" or "radiant ceiling" or "water loop") or ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType="fan coil"</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected NumberofUnitsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofUnitsServed) &gt; 1 or not(h:NumberofUnitsServed)'>Expected NumberofUnitsServed to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"]'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:ElectricAuxiliaryEnergy) + count(h:extension/h:SharedLoopWatts) &lt;= 1'>Expected not both ElectricAuxiliaryEnergy and extension/SharedLoopWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopWatts) &gt;= 0 or not(h:extension/h:SharedLoopWatts)'>Expected extension/SharedLoopWatts to be greater than or equal to 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt; 0.5'>AFUE should typically be greater than or equal to 0.5.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=SharedBoilerWthFanCoil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Boiler and h:IsSharedSystem="true" and ../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="fan coil"]]'>
      <sch:assert role='ERROR' test='count(h:ElectricAuxiliaryEnergy) + count(h:extension/h:FanCoilWatts) &lt;= 1'>Expected not both ElectricAuxiliaryEnergy and extension/FanCoilWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanCoilWatts) &gt;= 0 or not(h:extension/h:FanCoilWatts)'>Expected extension/FanCoilWatts to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=SharedBoilerWithWLHP]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Boiler and h:IsSharedSystem="true" and ../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="water loop"]]'>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:HeatingCapacity) &lt;= 1'>Expected at most one ../HeatPump[HeatPumpType="water-loop-to-air"]/HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected ../HeatPump[HeatPumpType="water-loop-to-air"]/AnnualHeatingEfficiency[Units="COP"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=Stove]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Stove]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected no DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"]'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected at most one extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt; 0.5'>Percent efficiency should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt; 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=SpaceHeater]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:SpaceHeater]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected no DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"]'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected at most one extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt; 0.5'>Percent efficiency should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt; 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystemType=Fireplace]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem[h:HeatingSystemType/h:Fireplace]'>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 0'>Expected no DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingSystemFuel) = 1'>Expected HeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='h:HeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"] or not(h:HeatingSystemFuel)'>Expected HeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:AnnualHeatingEfficiency[h:Units="Percent"]/h:Value)'>Expected AnnualHeatingEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1 or count(../h:HeatPump/h:BackupSystem) &gt;= 1'>Expected FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWatts) &lt;= 1'>Expected at most one extension/FanPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWatts) &gt;= 0 or not(h:extension/h:FanPowerWatts)'>Expected extension/FanPowerWatts to be greater than or equal to 0</sch:assert>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt; 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingSystem=HasPilotLight]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatingSystem/h:HeatingSystemType/*[h:PilotLight="true"]'>
      <sch:assert role='ERROR' test='count(../../h:HeatingSystemFuel[text()!="electricity"]) = 1'>Expected ../../HeatingSystemFuel to not be "electricity"</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PilotLightBtuh) &lt;= 1'>Expected at most one extension/PilotLightBtuh</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:PilotLightBtuh) &gt;= 0 or not (h:extension/h:PilotLightBtuh)'>Expected PilotLightBtuh to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem'>
      <sch:assert role='ERROR' test='count(../../h:HVACControl) = 1'>Expected ../../HVACControl</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemType[text()="central air conditioner" or text()="room air conditioner" or text()="evaporative cooler" or text()="mini-split" or text()="chiller" or text()="cooling tower" or text()="packaged terminal air conditioner"]'>Expected CoolingSystemType to be 'central air conditioner' or 'room air conditioner' or 'evaporative cooler' or 'mini-split' or 'chiller' or 'cooling tower' or 'packaged terminal air conditioner'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingAutosizingFactor) &lt;= 1'>Expected at most one extension/CoolingAutosizingFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingAutosizingFactor) &gt; 0 or not (h:extension/h:CoolingAutosizingFactor)'>Expected CoolingAutosizingFactor to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingAutosizingLimit) &lt;= 1'>Expected at most one extension/CoolingAutosizingLimit</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingAutosizingLimit) &gt; 0 or not (h:extension/h:CoolingAutosizingLimit)'>Expected CoolingAutosizingLimit to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=CentralAC]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="central air conditioner"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType="regular velocity" or ../../HVACDistribution/DistributionSystemType/Other="DSE"</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"]'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorType) = 1'>Expected CompressorType</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="SEER" or h:Units="SEER2"]/h:Value) = 1'>Expected AnnualCoolingEfficiency[Units="SEER"]/Value or AnnualCoolingEfficiency[Units="SEER2"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="EER2"]/h:Value) &lt;= 1'>Expected not both AnnualCoolingEfficiency[Units="EER"]/Value and AnnualCoolingEfficiency[Units="EER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value)'>Expected EER to be less than SEER.</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt;= number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value)'>Expected EER2 to be less than or equal to SEER2.</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected no IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) &lt;= 1'>Expected at most one extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected at most one extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected at most one extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) &lt;= 1'>Expected at most one extension/AirflowDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) &lt;= 1'>Expected at most one extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &gt;= -0.9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &lt;= 9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CrankcaseHeaterPowerWatts) &lt;= 1'>Expected at most one extension/CrankcaseHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CrankcaseHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:CrankcaseHeaterPowerWatts)'>Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:EquipmentType) &lt;= 1'>Expected at most one extension/EquipmentType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:EquipmentType[text()="split system" or text()="packaged system" or text()="small duct high velocity system" or text()="space constrained system"] or not(h:extension/h:EquipmentType)'>Expected extension/EquipmentType to be 'split system', 'packaged system', 'small duct high velocity system', or 'space constrained system'</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) &lt; 8'>SEER should typically be greater than or equal to 8.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) &lt; 7.6'>SEER2 should typically be greater than or equal to 7.6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; 6'>EER should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt; 5.7'>EER2 should typically be greater than or equal to 5.7.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt; 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=PTACorRoomAC]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="room air conditioner" or h:CoolingSystemType="packaged terminal air conditioner"]'>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"]'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="CEER"]/h:Value) = 1'>Expected AnnualCoolingEfficiency[Units="EER"]/Value or AnnualCoolingEfficiency[Units="CEER"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='h:IntegratedHeatingSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"] or not(h:IntegratedHeatingSystemFuel)'>Expected IntegratedHeatingSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CrankcaseHeaterPowerWatts) &lt;= 1'>Expected at most one extension/CrankcaseHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CrankcaseHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:CrankcaseHeaterPowerWatts)'>Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; 6'>EER should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="CEER"]/h:Value) &lt; 5.9'>CEER should typically be greater than or equal to 5.9.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt; 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=EvapCooler]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="evaporative cooler"]'>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"]'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected no IntegratedHeatingSystemFuel</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt; 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=MiniSplitAC]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="mini-split"]'>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"]'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='h:CompressorType[text()="variable speed"]'>Expected CompressorType to be 'variable speed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="SEER" or h:Units="SEER2"]/h:Value) = 1'>Expected AnnualCoolingEfficiency[Units="SEER"]/Value or AnnualCoolingEfficiency[Units="SEER2"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="EER2"]/h:Value) &lt;= 1'>Expected not both AnnualCoolingEfficiency[Units="EER"]/Value and AnnualCoolingEfficiency[Units="EER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value)'>Expected EER to be less than SEER.</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt;= number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value)'>Expected EER2 to be less than or equal to SEER2.</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected no IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) &lt;= 1'>Expected at most one extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected at most one extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected at most one extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) &lt;= 1'>Expected at most one extension/AirflowDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) &lt;= 1'>Expected at most one extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &gt;= -0.9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &lt;= 9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CrankcaseHeaterPowerWatts) &lt;= 1'>Expected at most one extension/CrankcaseHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CrankcaseHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:CrankcaseHeaterPowerWatts)'>Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) &lt; 8'>SEER should typically be greater than or equal to 8.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) &lt; 7.6'>SEER2 should typically be greater than or equal to 7.6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; 6'>EER should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt; 5.7'>EER2 should typically be greater than or equal to 5.7.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt; 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=SharedChiller]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="chiller"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected ../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType=("single-family attached" or "apartment unit")]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling" or text()="water loop"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="fan coil"]) &gt;= 1'>Expected ../../HVACDistribution/DistributionSystemType/HydronicDistribution/HydronicDistributionType=("radiator" or "baseboard" or "radiant floor" or "radiant ceiling" or "water loop") or ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType="fan coil"</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='h:IsSharedSystem[text()="true"]'>Expected IsSharedSystem to be 'true'</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected NumberofUnitsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofUnitsServed) &gt; 1 or not(h:NumberofUnitsServed)'>Expected NumberofUnitsServed to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"]'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CoolingCapacity) = 1'>Expected CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="kW/ton"]/h:Value) = 1'>Expected AnnualCoolingEfficiency[Units="kW/ton"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected no IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopWatts) = 1'>Expected extension/SharedLoopWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopWatts) &gt;= 0 or not(h:extension/h:SharedLoopWatts)'>Expected extension/SharedLoopWatts to be greater than or equal to 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt; 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=SharedChillerWithFanCoil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="chiller" and ../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="fan coil"]]'>
      <sch:assert role='ERROR' test='count(h:extension/h:FanCoilWatts) = 1'>Expected extension/FanCoilWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanCoilWatts) &gt;= 0 or not(h:extension/h:FanCoilWatts)'>Expected extension/FanCoilWatts to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=SharedChillerWithWLHP]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="chiller" and ../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="water loop"]]'>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:CoolingCapacity) = 1'>Expected ../HeatPump[HeatPumpType="water-loop-to-air"]/CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) = 1'>Expected ../HeatPump[HeatPumpType="water-loop-to-air"]/AnnualCoolingEfficiency[Units="EER"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystemType=SharedCoolingTowerWLHP]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:CoolingSystemType="cooling tower"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected ../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType=("single-family attached" or "apartment unit")]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="water loop"]) &gt;= 1'>Expected ../../HVACDistribution/DistributionSystemType/HydronicDistribution/HydronicDistributionType="water loop"</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='h:IsSharedSystem[text()="true"]'>Expected IsSharedSystem to be 'true'</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected NumberofUnitsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofUnitsServed) &gt; 1 or not(h:NumberofUnitsServed)'>Expected NumberofUnitsServed to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='h:CoolingSystemFuel[text()="electricity"]'>Expected CoolingSystemFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFuel) = 0'>Expected no IntegratedHeatingSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopWatts) = 1'>Expected extension/SharedLoopWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopWatts) &gt;= 0 or not(h:extension/h:SharedLoopWatts)'>Expected extension/SharedLoopWatts to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:CoolingCapacity) = 1'>Expected ../HeatPump[HeatPumpType="water-loop-to-air"]/CoolingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(../h:HeatPump[h:HeatPumpType="water-loop-to-air"]/h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) = 1'>Expected ../HeatPump[HeatPumpType="water-loop-to-air"]/AnnualCoolingEfficiency[Units="EER"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingSystem=HasIntegratedHeatingSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:CoolingSystem[h:IntegratedHeatingSystemFuel]'>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemFractionHeatLoadServed) = 1'>Expected IntegratedHeatingSystemFractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedHeatingSystemAnnualEfficiency[h:Units="Percent"]/h:Value) = 1'>Expected IntegratedHeatingSystemAnnualEfficiency[Units="Percent"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:IntegratedHeatingSystemAnnualEfficiency[h:Units="Percent"]/h:Value) &lt;= 1 or not(h:IntegratedHeatingSystemAnnualEfficiency[h:Units="Percent"]/h:Value)'>Expected IntegratedHeatingSystemAnnualEfficiency[Units="Percent"]/Value to be less than or equal to 1</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:IntegratedHeatingSystemAnnualEfficiency[h:Units="Percent"]/h:Value) &lt; 0.5'>Percent efficiency should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:IntegratedHeatingSystemCapacity) &lt; 1000 and number(h:IntegratedHeatingSystemCapacity) &gt; 0 and h:IntegratedHeatingSystemCapacity'>Integrated Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPump]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump'>
      <sch:assert role='ERROR' test='count(../../h:HVACControl) = 1'>Expected ../../HVACControl</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpType[text()="air-to-air" or text()="mini-split" or text()="ground-to-air" or text()="water-loop-to-air" or text()="packaged terminal heat pump" or text()="room air conditioner with reverse cycle"]'>Expected HeatPumpType to be 'air-to-air' or 'mini-split' or 'ground-to-air' or 'water-loop-to-air' or 'packaged terminal heat pump' or 'room air conditioner with reverse cycle'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingAutosizingFactor) &lt;= 1'>Expected at most one extension/CoolingAutosizingFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingAutosizingFactor) &lt;= 1'>Expected at most one extension/HeatingAutosizingFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingAutosizingFactor) &gt; 0 or not (h:extension/h:CoolingAutosizingFactor)'>Expected CoolingAutosizingFactor to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingAutosizingFactor) &gt; 0 or not (h:extension/h:HeatingAutosizingFactor)'>Expected HeatingAutosizingFactor to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingAutosizingLimit) &lt;= 1'>Expected at most one extension/CoolingAutosizingLimit</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingAutosizingLimit) &lt;= 1'>Expected at most one extension/HeatingAutosizingLimit</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingAutosizingLimit) &gt; 0 or not (h:extension/h:CoolingAutosizingLimit)'>Expected CoolingAutosizingLimit to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingAutosizingLimit) &gt; 0 or not (h:extension/h:HeatingAutosizingLimit)'>Expected HeatingAutosizingLimit to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=AirSource]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="air-to-air"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType="regular velocity" or ../../HVACDistribution/DistributionSystemType/Other="DSE"</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"]'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <!-- Moved/deprecated HeatingCapacityRetention input; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/1931 -->
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingCapacityRetention) = 0'>extension/HeatingCapacityRetention has been replaced by extension/HeatingCapacityFraction17F</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingCapacityFraction17F) + count(h:HeatingCapacity17F) &lt;= 1'>Expected not both extension/HeatingCapacityFraction17F and HeatingCapacity17F</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingCapacityFraction17F) &lt; 1 or not(h:extension/h:HeatingCapacityFraction17F)'>Expected extension/HeatingCapacityFraction17F to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingCapacityFraction17F) &gt;= 0 or not(h:extension/h:HeatingCapacityFraction17F)'>Expected extension/HeatingCapacityFraction17F to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatingCapacity17F) &lt;= number(h:HeatingCapacity) or not(h:HeatingCapacity17F) or not(h:HeatingCapacity)'>Expected HeatingCapacity17F to be less than or equal to HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity17F) &lt;= count(h:HeatingCapacity)'>Expected HeatingCapacity if HeatingCapacity17F is specified</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorType) = 1'>Expected CompressorType</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="SEER" or h:Units="SEER2"]/h:Value) = 1'>Expected AnnualCoolingEfficiency[Units="SEER"]/Value or AnnualCoolingEfficiency[Units="SEER2"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="EER2"]/h:Value) &lt;= 1'>Expected not both AnnualCoolingEfficiency[Units="EER"]/Value and AnnualCoolingEfficiency[Units="EER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value)'>Expected EER to be less than SEER.</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt;= number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value)'>Expected EER2 to be less than or equal to SEER2.</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="HSPF" or h:Units="HSPF2"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="HSPF"]/Value or AnnualHeatingEfficiency[Units="HSPF2"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) &lt;= 1'>Expected at most one extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected at most one extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingDesignAirflowCFM) &lt;= 1'>Expected at most one extension/HeatingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:HeatingDesignAirflowCFM)'>Expected extension/HeatingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected at most one extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) &lt;= 1'>Expected at most one extension/AirflowDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) &lt;= 1'>Expected at most one extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &gt;= -0.9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &lt;= 9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CrankcaseHeaterPowerWatts) &lt;= 1'>Expected at most one extension/CrankcaseHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CrankcaseHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:CrankcaseHeaterPowerWatts)'>Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PanHeaterPowerWatts) &lt;= 1'>Expected at most one extension/PanHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:PanHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:PanHeaterPowerWatts)'>Expected extension/PanHeaterPowerWatts to be greater than or equal to 0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PanHeaterControlType) &lt;= 1'>Expected at most one extension/PanHeaterControlType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:PanHeaterControlType[text()="continuous" or text()="heat pump mode" or text()="defrost mode"] or not(h:extension/h:PanHeaterControlType)'>Expected extension/PanHeaterControlType to be 'continuous' or 'heat pump mode' or 'defrost mode'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingActiveDuringDefrost) &lt;= 1'>Expected at most one extension/BackupHeatingActiveDuringDefrost</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:BackupHeatingActiveDuringDefrost[text()="true" or text()="false"] or not(h:extension/h:BackupHeatingActiveDuringDefrost)'>Expected extension/BackupHeatingActiveDuringDefrost to be 'true' or 'false'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:EquipmentType) &lt;= 1'>Expected at most one extension/EquipmentType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:EquipmentType[text()="split system" or text()="packaged system" or text()="small duct high velocity system" or text()="space constrained system"] or not(h:extension/h:EquipmentType)'>Expected extension/EquipmentType to be 'split system', 'packaged system', 'small duct high velocity system', or 'space constrained system'</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) &lt; 8'>SEER should typically be greater than or equal to 8.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) &lt; 7.6'>SEER2 should typically be greater than or equal to 7.6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; 6'>EER should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt; 5.7'>EER2 should typically be greater than or equal to 5.7.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="HSPF"]/h:Value) &lt; 6'>HSPF should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="HSPF2"]/h:Value) &lt; 5.1'>HSPF2 should typically be greater than or equal to 5.1.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt; 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt; 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=MiniSplit]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="mini-split"]'>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"]'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <!-- Moved/deprecated HeatingCapacityRetention input; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/1931 -->
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingCapacityRetention) = 0'>extension/HeatingCapacityRetention has been replaced by extension/HeatingCapacityFraction17F</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingCapacityFraction17F) + count(h:HeatingCapacity17F) &lt;= 1'>Expected not both extension/HeatingCapacityFraction17F and HeatingCapacity17F</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingCapacityFraction17F) &lt; 1 or not(h:extension/h:HeatingCapacityFraction17F)'>Expected extension/HeatingCapacityFraction17F to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingCapacityFraction17F) &gt;= 0 or not(h:extension/h:HeatingCapacityFraction17F)'>Expected extension/HeatingCapacityFraction17F to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatingCapacity17F) &lt;= number(h:HeatingCapacity) or not(h:HeatingCapacity17F) or not(h:HeatingCapacity)'>Expected HeatingCapacity17F to be less than or equal to HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity17F) &lt;= count(h:HeatingCapacity)'>Expected HeatingCapacity if HeatingCapacity17F is specified</sch:assert>
      <sch:assert role='ERROR' test='h:CompressorType[text()="variable speed"]'>Expected CompressorType to be 'variable speed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="SEER" or h:Units="SEER2"]/h:Value) = 1'>Expected AnnualCoolingEfficiency[Units="SEER"]/Value or AnnualCoolingEfficiency[Units="SEER2"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="EER2"]/h:Value) &lt;= 1'>Expected not both AnnualCoolingEfficiency[Units="EER"]/Value and AnnualCoolingEfficiency[Units="EER2"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value)'>Expected EER to be less than SEER.</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) &lt;= number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="EER2"]/h:Value) or not(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value)'>Expected EER2 to be less than or equal to SEER2.</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="HSPF" or h:Units="HSPF2"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="HSPF"]/Value or AnnualHeatingEfficiency[Units="HSPF2"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) &lt;= 1'>Expected at most one extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected at most one extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingDesignAirflowCFM) &lt;= 1'>Expected at most one extension/HeatingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:HeatingDesignAirflowCFM)'>Expected extension/HeatingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected at most one extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) &lt;= 1'>Expected at most one extension/AirflowDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) &lt;= 1'>Expected at most one extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &gt;= -0.9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &lt;= 9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CrankcaseHeaterPowerWatts) &lt;= 1'>Expected at most one extension/CrankcaseHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CrankcaseHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:CrankcaseHeaterPowerWatts)'>Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PanHeaterPowerWatts) &lt;= 1'>Expected at most one extension/PanHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:PanHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:PanHeaterPowerWatts)'>Expected extension/PanHeaterPowerWatts to be greater than or equal to 0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PanHeaterControlType) &lt;= 1'>Expected at most one extension/PanHeaterControlType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:PanHeaterControlType[text()="continuous" or text()="heat pump mode" or text()="defrost mode"] or not(h:extension/h:PanHeaterControlType)'>Expected extension/PanHeaterControlType to be 'continuous' or 'heat pump mode' or 'defrost mode'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingActiveDuringDefrost) &lt;= 1'>Expected at most one extension/BackupHeatingActiveDuringDefrost</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:BackupHeatingActiveDuringDefrost[text()="true" or text()="false"] or not(h:extension/h:BackupHeatingActiveDuringDefrost)'>Expected extension/BackupHeatingActiveDuringDefrost to be 'true' or 'false'</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER"]/h:Value) &lt; 8'>SEER should typically be greater than or equal to 8.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="SEER2"]/h:Value) &lt; 7.6'>SEER2 should typically be greater than or equal to 7.6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="HSPF"]/h:Value) &lt; 6'>HSPF should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="HSPF2"]/h:Value) &lt; 5.1'>HSPF2 should typically be greater than or equal to 5.1.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt; 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt; 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=GroundSource]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="ground-to-air"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType="regular velocity" or ../../HVACDistribution/DistributionSystemType/Other="DSE"</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='count(h:DistributionSystem) = 1'>Expected DistributionSystem</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"]'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CompressorType) = 1'>Expected CompressorType</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupHeatingSwitchoverTemperature) = 0'>Expected no BackupHeatingSwitchoverTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) = 1'>Expected AnnualCoolingEfficiency[Units="EER"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="COP"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PumpPowerWattsPerTon) &lt;= 1'>Expected at most one extension/PumpPowerWattsPerTon</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:PumpPowerWattsPerTon) &gt;= 0 or not(h:extension/h:PumpPowerWattsPerTon)'>Expected extension/PumpPowerWattsPerTon to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanPowerWattsPerCFM) &lt;= 1'>Expected at most one extension/FanPowerWattsPerCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FanPowerWattsPerCFM) &gt;= 0 or not(h:extension/h:FanPowerWattsPerCFM)'>Expected extension/FanPowerWattsPerCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FanMotorType) &lt;= 1'>Expected at most one extension/FanMotorType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:FanMotorType[text()="PSC" or text()="BPM"] or not(h:extension/h:FanMotorType)'>Expected extension/FanMotorType to be 'PSC' or 'BPM'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingDesignAirflowCFM) &lt;= 1'>Expected at most one extension/HeatingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:HeatingDesignAirflowCFM)'>Expected extension/HeatingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CoolingDesignAirflowCFM) &lt;= 1'>Expected at most one extension/CoolingDesignAirflowCFM</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CoolingDesignAirflowCFM) &gt;= 0 or not(h:extension/h:CoolingDesignAirflowCFM)'>Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:AirflowDefectRatio) &lt;= 1'>Expected at most one extension/AirflowDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &gt;= -0.9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:AirflowDefectRatio) &lt;= 9 or not(h:extension/h:AirflowDefectRatio)'>Expected extension/AirflowDefectRatio to be less than or equal to 9</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ChargeDefectRatio) &lt;= 1'>Expected at most one extension/ChargeDefectRatio</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &gt;= -0.9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be greater than or equal to -0.9</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ChargeDefectRatio) &lt;= 9 or not(h:extension/h:ChargeDefectRatio)'>Expected extension/ChargeDefectRatio to be less than or equal to 9</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualCoolingEfficiency[h:Units="EER"]/h:Value) &lt; 6'>EER should typically be greater than or equal to 6.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) &lt; 2'>COP should typically be greater than or equal to 2.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt; 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt; 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=GroundSourceWithSharedLoop]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="ground-to-air" and h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected ../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType=("single-family attached" or "apartment unit")]</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofUnitsServed) = 1'>Expected NumberofUnitsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofUnitsServed) &gt; 1 or not(h:NumberofUnitsServed)'>Expected NumberofUnitsServed to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedLoopWatts) = 1'>Expected extension/SharedLoopWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SharedLoopWatts) &gt;= 0 or not(h:extension/h:SharedLoopWatts)'>Expected extension/SharedLoopWatts to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=WaterLoop]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="water-loop-to-air"]'>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:AirDistributionType[text()="regular velocity"]) + count(../../h:HVACDistribution/h:DistributionSystemType/h:Other[text()="DSE"]) &gt;= 1'>Expected ../../HVACDistribution/DistributionSystemType/AirDistribution/AirDistributionType="regular velocity" or ../../HVACDistribution/DistributionSystemType/Other="DSE"</sch:assert>
      <sch:assert role='ERROR' test='count(../h:HeatingSystem[h:HeatingSystemType/h:Boiler and h:IsSharedSystem="true"]) + count(../h:CoolingSystem[(h:CoolingSystemType="chiller" or h:CoolingSystemType="cooling tower") and h:IsSharedSystem="true"]) &gt;= 1'>Expected ../HeatingSystem[HeatingSystemType/Boiler and IsSharedSystem="true"] or ../CoolingSystem[CoolingSystemType=("chiller" or "cooling tower") and IsSharedSystem="true"]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution/h:HydronicDistributionType[text()="water loop"]) &gt;= 1'>Expected ../../HVACDistribution/DistributionSystemType/HydronicDistribution/HydronicDistributionType="water loop"</sch:assert>
      <sch:assert role='ERROR' test='h:UnitLocation[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="roof deck" or text()="unconditioned space" or text()="manufactured home belly"] or not(h:UnitLocation)'>Expected UnitLocation to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'roof deck' or 'unconditioned space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"]'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpType=PTHPorRoomACwithReverseCycle]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:HeatPumpType="packaged terminal heat pump" or h:HeatPumpType="room air conditioner with reverse cycle"]'>
      <sch:assert role='ERROR' test='h:HeatPumpFuel[text()="electricity"]'>Expected HeatPumpFuel to be 'electricity'</sch:assert>
      <!-- Moved/deprecated HeatingCapacityRetention input; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/1931 -->
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingCapacityRetention) = 0'>extension/HeatingCapacityRetention has been replaced by extension/HeatingCapacityFraction17F</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HeatingCapacityFraction17F) + count(h:HeatingCapacity17F) &lt;= 1'>Expected not both extension/HeatingCapacityFraction17F and HeatingCapacity17F</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingCapacityFraction17F) &lt; 1 or not(h:extension/h:HeatingCapacityFraction17F)'>Expected extension/HeatingCapacityFraction17F to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:HeatingCapacityFraction17F) &gt;= 0 or not(h:extension/h:HeatingCapacityFraction17F)'>Expected extension/HeatingCapacityFraction17F to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatingCapacity17F) &lt;= number(h:HeatingCapacity) or not(h:HeatingCapacity17F) or not(h:HeatingCapacity)'>Expected HeatingCapacity17F to be less than or equal to HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity17F) &lt;= count(h:HeatingCapacity)'>Expected HeatingCapacity if HeatingCapacity17F is specified</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="EER" or h:Units="CEER"]/h:Value) = 1'>Expected AnnualCoolingEfficiency[Units="EER"]/Value or AnnualCoolingEfficiency[Units="CEER"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="COP"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionHeatLoadServed) = 1'>Expected FractionHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionCoolLoadServed) = 1'>Expected FractionCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CrankcaseHeaterPowerWatts) &lt;= 1'>Expected at most one extension/CrankcaseHeaterPowerWatts</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CrankcaseHeaterPowerWatts) &gt;= 0.0 or not(h:extension/h:CrankcaseHeaterPowerWatts)'>Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingActiveDuringDefrost) &lt;= 1'>Expected at most one extension/BackupHeatingActiveDuringDefrost</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:BackupHeatingActiveDuringDefrost[text()="true" or text()="false"] or not(h:extension/h:BackupHeatingActiveDuringDefrost)'>Expected extension/BackupHeatingActiveDuringDefrost to be 'true' or 'false'</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt; 1000 and number(h:HeatingCapacity) &gt; 0 and h:HeatingCapacity'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='number(h:CoolingCapacity) &lt; 1000 and number(h:CoolingCapacity) &gt; 0 and h:CoolingCapacity'>Cooling capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpBackup]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:BackupType]'>
      <sch:assert role='ERROR' test='count(h:BackupHeatingSwitchoverTemperature) + count(h:CompressorLockoutTemperature) &lt;= 1'>Expected not both BackupHeatingSwitchoverTemperature and CompressorLockoutTemperature</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupHeatingSwitchoverTemperature) + count(h:BackupHeatingLockoutTemperature) &lt;= 1'>Expected not both BackupHeatingSwitchoverTemperature and BackupHeatingLockoutTemperature</sch:assert>
      <sch:assert role='ERROR' test='number(h:CompressorLockoutTemperature) &lt;= number(h:BackupHeatingLockoutTemperature) or not(h:CompressorLockoutTemperature) or not (h:BackupHeatingLockoutTemperature)'>Expected CompressorLockoutTemperature to be less than or equal to BackupHeatingLockoutTemperature</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:BackupHeatingSwitchoverTemperature) &lt; 30'>BackupHeatingSwitchoverTemperature is below 30 deg-F; this may result in significant unmet hours if the heat pump does not have sufficient capacity.</sch:report>
      <sch:report role='WARN' test='number(h:BackupHeatingLockoutTemperature) &lt; 30'>BackupHeatingLockoutTemperature is below 30 deg-F; this may result in significant unmet hours if the heat pump does not have sufficient capacity.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpBackup=Integrated]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:BackupType="integrated" or h:BackupSystemFuel]'>
      <sch:assert role='ERROR' test='h:BackupType[text()="integrated"]'>Expected BackupType to be 'integrated'</sch:assert>
      <sch:assert role='ERROR' test='h:BackupSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="wood" or text()="wood pellets"]'>Expected BackupSystemFuel to be 'electricity' or 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupAnnualHeatingEfficiency[h:Units="Percent" or h:Units="AFUE"]/h:Value) = 1'>Expected BackupAnnualHeatingEfficiency[Units="Percent"]/Value or BackupAnnualHeatingEfficiency[Units="AFUE"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='number(h:BackupAnnualHeatingEfficiency[h:Units="Percent" or h:Units="AFUE"]/h:Value) &lt;= 1 or not(h:BackupAnnualHeatingEfficiency[h:Units="Percent" or h:Units="AFUE"]/h:Value)'>Expected BackupAnnualHeatingEfficiency[Units="Percent" or Units="AFUE"]/Value to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingAutosizingFactor) &lt;= 1'>Expected at most one extension/BackupHeatingAutosizingFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:BackupHeatingAutosizingFactor) &gt; 0 or not (h:extension/h:BackupHeatingAutosizingFactor)'>Expected BackupHeatingAutosizingFactor to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingAutosizingLimit) &lt;= 1'>Expected at most one extension/BackupHeatingAutosizingLimit</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:BackupHeatingAutosizingLimit) &gt; 0 or not (h:extension/h:BackupHeatingAutosizingLimit)'>Expected BackupHeatingAutosizingLimit to be greater than 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:BackupAnnualHeatingEfficiency[h:Units="Percent"]/h:Value) &lt; 0.5'>Percent efficiency should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:BackupAnnualHeatingEfficiency[h:Units="AFUE"]/h:Value) &lt; 0.5'>AFUE should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:BackupHeatingCapacity) &lt; 1000 and number(h:BackupHeatingCapacity) &gt; 0 and h:BackupHeatingCapacity'>Backup heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatPumpBackup=Separate]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:HeatPump[h:BackupType="separate" or h:BackupSystem]'>
      <sch:assert role='ERROR' test='sum(../*/h:FractionHeatLoadServed) &lt;= 1.01 and sum(../*/h:FractionHeatLoadServed) &gt;= 0.99'>Expected sum(FractionHeatLoadServed) to be 1</sch:assert>
      <sch:assert role='ERROR' test='h:BackupType[text()="separate"]'>Expected BackupType to be 'separate'</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupSystem) = 1'>Expected BackupSystem</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupSystemFuel) = 0'>Expected no BackupSystemFuel</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupAnnualHeatingEfficiency) = 0'>Expected no BackupAnnualHeatingEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:BackupHeatingCapacity) = 0'>Expected no BackupHeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingAutosizingFactor) = 0'>Expected no extension/BackupHeatingAutosizingFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:BackupHeatingAutosizingLimit) = 0'>Expected no extension/BackupHeatingAutosizingLimit</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='count(h:extension/h:BackupHeatingActiveDuringDefrost[text()="true"]) &gt; 0'>BackupHeatingActiveDuringDefrost does not apply when system has separate backup heating.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingDetailedPerformanceData=SingleStage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:HeatingDetailedPerformanceData[../h:CompressorType="single stage"]'>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=47 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=17 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature=5 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature&lt;5 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[(h:OutdoorTemperature &gt; 47) or (h:OutdoorTemperature &lt; 47 and h:OutdoorTemperature &gt; 17) or (h:OutdoorTemperature &lt; 17 and h:OutdoorTemperature &gt; 5)]) = 0'>Expected PerformanceDataPoint/OutdoorTemperature to be 47, 17, 5, or &lt;5</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HeatingDetailedPerformanceData=TwoStage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:HeatingDetailedPerformanceData[../h:CompressorType="two stage"]'>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=47 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=47 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=17 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=17 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=5 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature=5 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature&lt;5 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature&lt;5 and CapacityDescription="nominal"]</sch:assert>
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
    <sch:title>[HeatingDetailedPerformanceData=VariableSpeed]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:HeatingDetailedPerformanceData[../h:CompressorType="variable speed"]'>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="minimum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=47 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="nominal"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=47 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=47 and h:CapacityDescription="maximum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=47 and CapacityDescription="maximum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="minimum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=17 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="nominal"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=17 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=17 and h:CapacityDescription="maximum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=17 and CapacityDescription="maximum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="minimum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=5 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature=5 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=5 and h:CapacityDescription="maximum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=5 and CapacityDescription="maximum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="minimum"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature&lt;5 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature&lt;5 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &lt; 5 and h:CapacityDescription="maximum"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature&lt;5 and CapacityDescription="maximum"]</sch:assert>
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
    <sch:title>[CoolingDetailedPerformanceData=SingleStage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:CoolingDetailedPerformanceData[../h:CompressorType="single stage"]'>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature&gt;95 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=95 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=82 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[(h:OutdoorTemperature &lt; 82) or (h:OutdoorTemperature &gt; 82 and h:OutdoorTemperature &lt; 95)]) = 0'>Expected PerformanceDataPoint/OutdoorTemperature to be 82, 95, or &gt;95</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CoolingDetailedPerformanceData=TwoStage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:CoolingDetailedPerformanceData[../h:CompressorType="two stage"]'>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature&gt;95 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature&gt;95 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=95 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=95 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=82 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=82 and CapacityDescription="nominal"]</sch:assert>
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
    <sch:title>[CoolingDetailedPerformanceData=VariableSpeed]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:CoolingDetailedPerformanceData[../h:CompressorType="variable speed"]'>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="minimum"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature&gt;95 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature&gt;95 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature &gt; 95 and h:CapacityDescription="maximum"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature&gt;95 and CapacityDescription="maximum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="minimum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=95 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="nominal"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=95 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=95 and h:CapacityDescription="maximum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=95 and CapacityDescription="maximum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="minimum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=82 and CapacityDescription="minimum"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="nominal"]) &lt;= 1'>Expected at most one PerformanceDataPoint[OutdoorTemperature=82 and CapacityDescription="nominal"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:PerformanceDataPoint[h:OutdoorTemperature=82 and h:CapacityDescription="maximum"]) = 1'>Expected PerformanceDataPoint[OutdoorTemperature=82 and CapacityDescription="maximum"]</sch:assert>
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
    <sch:title>[PerformanceDataPoint]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/*/h:PerformanceDataPoint'>
      <sch:assert role='ERROR' test='count(h:Capacity) + count(h:CapacityFractionOfNominal) &gt;= 1'>Expected Capacity or CapacityFractionOfNominal</sch:assert>
      <sch:assert role='ERROR' test='number(h:Capacity) &gt;= 0 or not(h:Capacity)'>Expected Capacity to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:CapacityFractionOfNominal) &gt;= 0 or not(h:CapacityFractionOfNominal)'>Expected CapacityFractionOfNominal to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:Efficiency[h:Units="COP"]/h:Value) = 1'>Expected Efficiency[Units="COP"]/Value</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PerformanceDataPoint=HeatingCapacity]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:HeatingDetailedPerformanceData/h:PerformanceDataPoint[number(h:OutdoorTemperature)=47 and h:CapacityDescription="nominal"]'>
      <sch:assert role='ERROR' test='(number(../../h:HeatingCapacity) &gt;= 0.99 * number(h:Capacity) or not (../../h:HeatingCapacity)) or not (h:Capacity)'>Expected ../../HeatingCapacity to be equal to Capacity</sch:assert>
      <sch:assert role='ERROR' test='(number(../../h:HeatingCapacity) &lt;= 1.01 * number(h:Capacity) or not (../../h:HeatingCapacity)) or not (h:Capacity)'>Expected ../../HeatingCapacity to be equal to Capacity</sch:assert>
      <sch:assert role='ERROR' test='number(h:CapacityFractionOfNominal) &gt;= 0.99 or not (h:CapacityFractionOfNominal)'>Expected CapacityFractionOfNominal to be 1.0</sch:assert>
      <sch:assert role='ERROR' test='number(h:CapacityFractionOfNominal) &lt;= 1.01 or not (h:CapacityFractionOfNominal)'>Expected CapacityFractionOfNominal to be 1.0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PerformanceDataPoint=HeatingCapacity17F]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:HeatingDetailedPerformanceData/h:PerformanceDataPoint[number(h:OutdoorTemperature)=17 and h:CapacityDescription="nominal"]'>
      <sch:assert role='ERROR' test='(number(../../h:HeatingCapacity17F) &gt;= 0.99 * number(h:Capacity) or not (../../h:HeatingCapacity17F)) or not (h:Capacity)'>Expected ../../HeatingCapacity17F to be equal to Capacity</sch:assert>
      <sch:assert role='ERROR' test='(number(../../h:HeatingCapacity17F) &lt;= 1.01 * number(h:Capacity) or not (../../h:HeatingCapacity17F)) or not (h:Capacity)'>Expected ../../HeatingCapacity17F to be equal to Capacity</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PerformanceDataPoint=CoolingCapacity]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/*/h:CoolingDetailedPerformanceData/h:PerformanceDataPoint[number(h:OutdoorTemperature)=95 and h:CapacityDescription="nominal"]'>
      <sch:assert role='ERROR' test='(number(../../h:CoolingCapacity) &gt;= 0.99 * number(h:Capacity) or not (../../h:CoolingCapacity)) or not (h:Capacity)'>Expected ../../CoolingCapacity to be equal to Capacity</sch:assert>
      <sch:assert role='ERROR' test='(number(../../h:CoolingCapacity) &lt;= 1.01 * number(h:Capacity) or not (../../h:CoolingCapacity)) or not (h:Capacity)'>Expected ../../CoolingCapacity to be equal to Capacity</sch:assert>
      <sch:assert role='ERROR' test='number(h:CapacityFractionOfNominal) &gt;= 0.99 or not (h:CapacityFractionOfNominal)'>Expected CapacityFractionOfNominal to be 1.0</sch:assert>
      <sch:assert role='ERROR' test='number(h:CapacityFractionOfNominal) &lt;= 1.01 or not (h:CapacityFractionOfNominal)'>Expected CapacityFractionOfNominal to be 1.0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[GeothermalLoop]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACPlant/h:GeothermalLoop'>
      <sch:assert role='ERROR' test='h:LoopConfiguration[text()="vertical"]'>Expected LoopConfiguration to be 'vertical'</sch:assert>
      <sch:assert role='ERROR' test='number(h:BoreholesOrTrenches/h:Count) &gt;= 1 or not(h:BoreholesOrTrenches/h:Count)'>Expected BoreholesOrTrenches/Count to be greater than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:BoreholesOrTrenches/h:Count) &lt;= 15 or not(h:BoreholesOrTrenches/h:Count)'>Expected BoreholesOrTrenches/Count to be less than or equal to 15</sch:assert>
      <sch:assert role='ERROR' test='number(h:BoreholesOrTrenches/h:Length) &gt;= 80 or not(h:BoreholesOrTrenches/h:Length)'>Expected BoreholesOrTrenches/Length to be greater than or equal to 80</sch:assert>
      <sch:assert role='ERROR' test='number(h:BoreholesOrTrenches/h:Length) &lt;= 500 or not(h:BoreholesOrTrenches/h:Length)'>Expected BoreholesOrTrenches/Length to be less than or equal to 500</sch:assert>
      <sch:assert role='ERROR' test='number(h:Pipe/h:Diameter) = 0.75 or number(h:Pipe/h:Diameter) = 1.0 or number(h:Pipe/h:Diameter) = 1.25 or not(h:Pipe/h:Diameter)'>Expected Pipe/Diameter to be 0.75, 1.0, or 1.25</sch:assert>
      <sch:assert role='ERROR' test='count(h:BoreholesOrTrenches/h:Count) + count(h:extension/h:BorefieldConfiguration[text()!="Rectangle"]) = 2 or not(h:extension/h:BorefieldConfiguration[text()!="Rectangle"])'>Expected BoreholesOrTrenches/Count if extension/BorefieldConfiguration is not 'Rectangle'</sch:assert>
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
      <sch:assert role='ERROR' test='count(h:SetpointTempHeatingSeason) + count(h:extension/h:WeekdaySetpointTempsHeatingSeason) &lt;= 1'>Expected not both SetpointTempHeatingSeason and extension/WeekdaySetpointTempsHeatingSeason</sch:assert>
      <sch:assert role='ERROR' test='count(h:SetpointTempHeatingSeason) + count(h:extension/h:WeekendSetpointTempsHeatingSeason) &lt;= 1'>Expected not both SetpointTempHeatingSeason and extension/WeekendSetpointTempsHeatingSeason</sch:assert>
      <sch:assert role='ERROR' test='count(h:SetbackTempHeatingSeason) + count(h:extension/h:WeekdaySetpointTempsHeatingSeason) &lt;= 1'>Expected not both SetbackTempHeatingSeason and extension/WeekdaySetpointTempsHeatingSeason</sch:assert>
      <sch:assert role='ERROR' test='count(h:SetbackTempHeatingSeason) + count(h:extension/h:WeekendSetpointTempsHeatingSeason) &lt;= 1'>Expected not both SetbackTempHeatingSeason and extension/WeekendSetpointTempsHeatingSeason</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:SetpointTempHeatingSeason) &lt; 58'>Heating setpoint should typically be greater than or equal to 58 deg-F.</sch:report>
      <sch:report role='WARN' test='number(h:SetpointTempHeatingSeason) &gt; 76'>Heating setpoint should typically be less than or equal to 76 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACControl=HeatingSetback]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACControl[h:SetbackTempHeatingSeason]'>
      <sch:assert role='ERROR' test='count(h:TotalSetbackHoursperWeekHeating) = 1'>Expected TotalSetbackHoursperWeekHeating if SetbackTempHeatingSeason is specified</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SetbackStartHourHeating) &lt;= 1'>Expected at most one extension/SetbackStartHourHeating</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SetbackStartHourHeating) &gt;= 0 or not(h:extension/h:SetbackStartHourHeating)'>Expected extension/SetbackStartHourHeating to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SetbackStartHourHeating) &lt;= 23 or not(h:extension/h:SetbackStartHourHeating)'>Expected extension/SetbackStartHourHeating to be less than or equal to 23</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACControl=HeatingSeason]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACControl/h:HeatingSeason'>
      <sch:assert role='ERROR' test='count(h:BeginMonth) = 1'>Expected BeginMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:BeginDayOfMonth) = 1'>Expected BeginDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndMonth) = 1'>Expected EndMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndDayOfMonth) = 1'>Expected EndDayOfMonth</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACControl=Cooling]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACControl[sum(../h:HVACPlant/*/h:FractionCoolLoadServed) > 0]'>
      <sch:assert role='ERROR' test='count(h:SetpointTempCoolingSeason) + count(h:extension/h:WeekdaySetpointTempsCoolingSeason) &lt;= 1'>Expected not both SetpointTempCoolingSeason and extension/WeekdaySetpointTempsCoolingSeason</sch:assert>
      <sch:assert role='ERROR' test='count(h:SetpointTempCoolingSeason) + count(h:extension/h:WeekendSetpointTempsCoolingSeason) &lt;= 1'>Expected not both SetpointTempCoolingSeason and extension/WeekendSetpointTempsCoolingSeason</sch:assert>
      <sch:assert role='ERROR' test='count(h:SetupTempCoolingSeason) + count(h:extension/h:WeekdaySetpointTempsCoolingSeason) &lt;= 1'>Expected not both SetupTempCoolingSeason and extension/WeekdaySetpointTempsCoolingSeason</sch:assert>
      <sch:assert role='ERROR' test='count(h:SetupTempCoolingSeason) + count(h:extension/h:WeekendSetpointTempsCoolingSeason) &lt;= 1'>Expected not both SetupTempCoolingSeason and extension/WeekendSetpointTempsCoolingSeason</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:CeilingFanSetpointTempCoolingSeasonOffset) &lt;= 1'>Expected at most one extension/CeilingFanSetpointTempCoolingSeasonOffset</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:CeilingFanSetpointTempCoolingSeasonOffset) &gt;= 0 or not(h:extension/h:CeilingFanSetpointTempCoolingSeasonOffset)'>Expected extension/CeilingFanSetpointTempCoolingSeasonOffset to be greater than or equal to 0</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:SetpointTempCoolingSeason) &lt; 68'>Cooling setpoint should typically be greater than or equal to 68 deg-F.</sch:report>
      <sch:report role='WARN' test='number(h:SetpointTempCoolingSeason) &gt; 86'>Cooling setpoint should typically be less than or equal to 86 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACControl=CoolingSetup]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACControl[h:SetupTempCoolingSeason]'>
      <sch:assert role='ERROR' test='count(h:TotalSetupHoursperWeekCooling) = 1'>Expected TotalSetupHoursperWeekCooling if SetupTempCoolingSeason is specified</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SetupStartHourCooling) &lt;= 1'>Expected at most one extension/SetupStartHourCooling</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SetupStartHourCooling) &gt;= 0 or not(h:extension/h:SetupStartHourCooling)'>Expected extension/SetupStartHourCooling to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:SetupStartHourCooling) &lt;= 23 or not(h:extension/h:SetupStartHourCooling)'>Expected extension/SetupStartHourCooling to be less than or equal to 23</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACControl=CoolingSeason]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACControl/h:CoolingSeason'>
      <sch:assert role='ERROR' test='count(h:BeginMonth) = 1'>Expected BeginMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:BeginDayOfMonth) = 1'>Expected BeginDayOfMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndMonth) = 1'>Expected EndMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:EndDayOfMonth) = 1'>Expected EndDayOfMonth</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDistribution]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution'>
      <sch:assert role='ERROR' test='count(h:DistributionSystemType[h:AirDistribution | h:HydronicDistribution | h:Other[text()="DSE"]]) = 1'>Expected DistributionSystemType[AirDistribution | HydronicDistribution | Other="DSE"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDistributionType=Air]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution'>
      <sch:assert role='ERROR' test='h:AirDistributionType[text()="regular velocity" or text()="gravity" or text()="fan coil"]'>Expected AirDistributionType to be 'regular velocity' or 'gravity' or 'fan coil'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ManualJInputs/h:BlowerFanHeatBtuh) &lt;= 1'>Expected at most one extension/ManualJInputs/BlowerFanHeatBtuh</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ManualJInputs/h:BlowerFanHeatBtuh) &gt;= 0 or not(h:extension/h:ManualJInputs/h:BlowerFanHeatBtuh)'>Expected extension/ManualJInputs/BlowerFanHeatBtuh to be greater than or equal to 0</sch:assert>
      <!-- Sum Checks -->
      <sch:assert role='ERROR' test='(sum(h:Ducts[h:DuctType="supply"]/h:FractionDuctArea) &gt;= 0.99 and sum(h:Ducts[h:DuctType="supply"]/h:FractionDuctArea) &lt;= 1.01) or count(h:Ducts[h:DuctType="supply"]/h:FractionDuctArea) = 0'>Expected sum(Ducts/FractionDuctArea) for DuctType="supply" to be 1</sch:assert>
      <sch:assert role='ERROR' test='(sum(h:Ducts[h:DuctType="return"]/h:FractionDuctArea) &gt;= 0.99 and sum(h:Ducts[h:DuctType="return"]/h:FractionDuctArea) &lt;= 1.01) or count(h:Ducts[h:DuctType="return"]/h:FractionDuctArea) = 0'>Expected sum(Ducts/FractionDuctArea) for DuctType="return" to be 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ManualJInputs=DefaultTableDuctLoad]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:extension/h:ManualJInputs/h:DefaultTableDuctLoad'>
      <sch:assert role='ERROR' test='count(h:TableNumber) = 1'>Expected TableNumber</sch:assert>
      <sch:assert role='ERROR' test='h:TableNumber[text()="7A-R" or text()="7A-T" or text()="7B-R" or text()="7B-T" or text()="7A-AE" or text()="7B-AE" or text()="7C-AE" or text()="7C-R" or text()="7C-T" or text()="7D-R" or text()="7D-T" or text()="7E-R" or text()="7E-T" or text()="7F-R" or text()="7F-T" or text()="7G-R" or text()="7G-T" or text()="7H" or text()="7I" or text()="7D-AE" or text()="7J-1" or text()="7J-2" or text()="7K" or text()="7L" or text()="7M" or text()="7N" or text()="7O-1" or text()="7O-2" or text()="7O-3" or text()="7O-4" or text()="7P-1" or text()="7P-2" or text()="7P-3" or text()="7P-4"] or not(h:TableNumber)'>Expected TableNumber to be '7A-R' or '7A-T' or '7B-R' or '7B-T' or '7A-AE' or '7B-AE' or '7C-AE' or '7C-R' or '7C-T' or '7D-R' or '7D-T' or '7E-R' or '7E-T' or '7F-R' or '7F-T' or '7G-R' or '7G-T' or '7H' or '7I' or '7D-AE' or '7J-1' or '7J-2' or '7K' or '7L' or '7M' or '7N' or '7O-1' or '7O-2' or '7O-3' or '7O-4' or '7P-1' or '7P-2' or '7P-3' or '7P-4'</sch:assert>
      <sch:assert role='ERROR' test='count(h:LookupFloorArea) = 1'>Expected LookupFloorArea</sch:assert>
      <sch:assert role='ERROR' test='number(h:LookupFloorArea) &gt; 0 or not(h:LookupFloorArea)'>Expected LookupFloorArea to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:LeakageLevel) = 1'>Expected LeakageLevel</sch:assert>
      <sch:assert role='ERROR' test='h:LeakageLevel[text()="default not sealed" or text()="partially sealed" or text()="default sealed" or text()="notably sealed" or text()="extremely sealed"] or not(h:LeakageLevel)'>Expected LeakageLevel to be 'default not sealed' or 'partially sealed' or 'default sealed' or 'notably sealed' or 'extremely sealed'</sch:assert>
      <sch:assert role='ERROR' test='count(h:InsulationRValue) = 1'>Expected InsulationRValue</sch:assert>
      <sch:assert role='ERROR' test='number(h:InsulationRValue) &gt;= 2 or not(h:InsulationRValue)'>Expected InsulationRValue to be greater than 2</sch:assert>
      <sch:assert role='ERROR' test='count(h:SupplySurfaceArea) + count(h:DSF) &lt;= 1'>Expected not both SupplySurfaceArea and DSF</sch:assert>
      <sch:assert role='ERROR' test='number(h:SupplySurfaceArea) &gt;= 0 or not(h:SupplySurfaceArea)'>Expected SupplySurfaceArea to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:ReturnSurfaceArea) + count(h:DSF) &lt;= 1'>Expected not both ReturnSurfaceArea and DSF</sch:assert>
      <sch:assert role='ERROR' test='number(h:ReturnSurfaceArea) &gt;= 0 or not(h:ReturnSurfaceArea)'>Expected ReturnSurfaceArea to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:DSF) &gt;= 0 or not(h:DSF)'>Expected DSF to be greater than 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirDistributionType=RegularVelocityOrGravity]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution[h:AirDistributionType[text()="regular velocity" or text()="gravity"]]'>
      <sch:assert role='ERROR' test='count(h:DuctLeakageMeasurement[h:DuctType="supply"]/h:DuctLeakage[(h:Units="CFM25" or h:Units="CFM50" or h:Units="Percent") and h:TotalOrToOutside="to outside"]) = 1'>Expected DuctLeakageMeasurement[DuctType="supply"]/DuctLeakage[(Units="CFM25" or Units="CFM50" or Units="Percent") and TotalOrToOutside="to outside"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:DuctLeakageMeasurement[h:DuctType="return"]/h:DuctLeakage[(h:Units="CFM25" or h:Units="CFM50" or h:Units="Percent") and h:TotalOrToOutside="to outside"]) = 1'>Expected DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[(Units="CFM25" or Units="CFM50" or Units="Percent") and TotalOrToOutside="to outside"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[AirDistributionType=FanCoil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution[h:AirDistributionType[text()="fan coil"]]'>
      <sch:assert role='ERROR' test='count(h:DuctLeakageMeasurement[h:DuctType="supply"]/h:DuctLeakage[(h:Units="CFM25" or h:Units="CFM50" or h:Units="Percent") and h:TotalOrToOutside="to outside"]) &lt;= 1'>Expected at most one DuctLeakageMeasurement[DuctType="supply"]/DuctLeakage[(Units="CFM25" or Units="CFM50" or Units="Percent") and TotalOrToOutside="to outside"]</sch:assert>
      <sch:assert role='ERROR' test='count(h:DuctLeakageMeasurement[h:DuctType="return"]/h:DuctLeakage[(h:Units="CFM25" or h:Units="CFM50" or h:Units="Percent") and h:TotalOrToOutside="to outside"]) &lt;= 1'>Expected at most one DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[(Units="CFM25" or Units="CFM50" or Units="Percent") and TotalOrToOutside="to outside"]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DuctLeakage=CFM]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:DuctLeakageMeasurement/h:DuctLeakage[h:Units="CFM25" or h:Units="CFM50"]'>
      <sch:assert role='ERROR' test='count(h:Value) = 1'>Expected Value</sch:assert> <!-- Can remove this when https://github.com/hpxmlwg/hpxml/pull/467 is available -->
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DuctLeakage=Percent]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:DuctLeakageMeasurement/h:DuctLeakage[h:Units="Percent"]'>
      <sch:assert role='ERROR' test='count(h:Value) = 1'>Expected Value</sch:assert> <!-- Can remove this when https://github.com/hpxmlwg/hpxml/pull/467 is available -->
      <sch:assert role='ERROR' test='number(h:Value) &lt; 1 or not(h:Value)'>Expected Value to be less than 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDistributionType=Hydronic]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:HydronicDistribution'>
      <sch:assert role='ERROR' test='h:HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling" or text()="water loop"]'>Expected HydronicDistributionType to be 'radiator' or 'baseboard' or 'radiant floor' or 'radiant ceiling' or 'water loop'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ManualJInputs/h:HotWaterPipingBtuh) &lt;= 1'>Expected at most one extension/ManualJInputs/HotWaterPipingBtuh</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ManualJInputs/h:HotWaterPipingBtuh) &gt;= 0 or not(h:extension/h:ManualJInputs/h:HotWaterPipingBtuh)'>Expected extension/ManualJInputs/HotWaterPipingBtuh to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDistributionType=DSE]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution[h:DistributionSystemType[h:Other="DSE"]]'>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingDistributionSystemEfficiency) = 1'>Expected AnnualHeatingDistributionSystemEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingDistributionSystemEfficiency) = 1'>Expected AnnualCoolingDistributionSystemEfficiency</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AnnualHeatingDistributionSystemEfficiency) &lt; 0.5'>Heating DSE should typically be greater than or equal to 0.5.</sch:report>
      <sch:report role='WARN' test='number(h:AnnualCoolingDistributionSystemEfficiency) &lt; 0.5'>Cooling DSE should typically be greater than or equal to 0.5.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDuct]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:Ducts'>
      <sch:assert role='ERROR' test='count(h:DuctType) = 1'>Expected DuctType</sch:assert>
      <sch:assert role='ERROR' test='count(h:DuctInsulationRValue) + count(h:DuctEffectiveRValue) &gt;= 1'>Expected DuctInsulationRValue or DuctEffectiveRValue</sch:assert>
      <sch:assert role='ERROR' test='h:DuctLocation[text()="conditioned space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="attic - vented" or text()="attic - unvented" or text()="garage" or text()="exterior wall" or text()="under slab" or text()="roof deck" or text()="outside" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space" or text()="manufactured home belly"] or not(h:DuctLocation)'>Expected DuctLocation to be 'conditioned space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'attic - vented' or 'attic - unvented' or 'garage' or 'exterior wall' or 'under slab' or 'roof deck' or 'outside' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'manufactured home belly'</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:DuctFractionRectangular) &gt;= 0 or not(h:extension/h:DuctFractionRectangular)'>Expected extension/DuctFractionRectangular to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:DuctFractionRectangular) &lt;= 1 or not(h:extension/h:DuctFractionRectangular)'>Expected extension/DuctFractionRectangular to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:DuctSurfaceAreaMultiplier) &lt;= 1'>Expected at most one extension/DuctSurfaceAreaMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:DuctSurfaceAreaMultiplier) &gt;= 0 or not(h:extension/h:DuctSurfaceAreaMultiplier)'>Expected extension/DuctSurfaceAreaMultiplier to be greater than or equal to 0</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDuct=WithLocation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:Ducts[h:DuctLocation]'>
      <sch:assert role='ERROR' test='count(h:FractionDuctArea) + count(h:DuctSurfaceArea) &gt;= 1'>Expected FractionDuctArea or DuctSurfaceArea if Ducts with DuctLocation are specified</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDuct=WithoutLocation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:Ducts[not(h:DuctLocation)]'>
      <sch:assert role='ERROR' test='count(h:FractionDuctArea) = 0'>Expected no FractionDuctArea if Ducts without DuctLocation are specified</sch:assert>
      <sch:assert role='ERROR' test='count(h:DuctSurfaceArea) = 0'>Expected no DuctSurfaceArea if Ducts without DuctLocation are specified</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HVACDuct=WithoutSurfaceArea]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:HVAC/h:HVACDistribution/h:DistributionSystemType/h:AirDistribution/h:Ducts[not(h:DuctSurfaceArea)]'>
      <sch:assert role='ERROR' test='count(../../../h:ConditionedFloorAreaServed) = 1'>Expected ../../../ConditionedFloorAreaServed if Ducts without DuctSurfaceArea are specified</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[VentilationFan]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan'>
      <sch:assert role='ERROR' test='count(h:UsedForWholeBuildingVentilation[text()="true"]) + count(h:UsedForLocalVentilation[text()="true"]) + count(h:UsedForSeasonalCoolingLoadReduction[text()="true"]) + count(h:UsedForGarageVentilation[text()="true"]) = 1'>Expected UsedForWholeBuildingVentilation="true" or UsedForLocalVentilation="true" or UsedForSeasonalCoolingLoadReduction="true" or UsedForGarageVentilation="true" but not multiple</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true"]'>
      <sch:assert role='ERROR' test='count(h:FanType) = 1'>Expected FanType</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=ExhaustSupplyOrBalanced]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType[text()="exhaust only" or text()="supply only" or text()="balanced"]]'>
      <sch:assert role='ERROR' test='count(h:CFISControls) = 0'>Expected no CFISControls</sch:assert>
      <sch:assert role='ERROR' test='count(h:TotalRecoveryEfficiency) = 0'>Expected no TotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdjustedTotalRecoveryEfficiency) = 0'>Expected no AdjustedTotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleRecoveryEfficiency) = 0'>Expected no SensibleRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdjustedSensibleRecoveryEfficiency) = 0'>Expected no AdjustedSensibleRecoveryEfficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=HRV]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="heat recovery ventilator"]'>
      <sch:assert role='ERROR' test='count(h:CFISControls) = 0'>Expected no CFISControls</sch:assert>
      <sch:assert role='ERROR' test='count(h:TotalRecoveryEfficiency) = 0'>Expected no TotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdjustedTotalRecoveryEfficiency) = 0'>Expected no AdjustedTotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdjustedSensibleRecoveryEfficiency) + count(h:SensibleRecoveryEfficiency) = 1'>Expected AdjustedSensibleRecoveryEfficiency or SensibleRecoveryEfficiency but not both</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=ERV]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="energy recovery ventilator"]'>
      <sch:assert role='ERROR' test='count(h:CFISControls) = 0'>Expected no CFISControls</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdjustedTotalRecoveryEfficiency) + count(h:TotalRecoveryEfficiency) = 1'>Expected AdjustedTotalRecoveryEfficiency or TotalRecoveryEfficiency but not both</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdjustedSensibleRecoveryEfficiency) + count(h:SensibleRecoveryEfficiency) = 1'>Expected AdjustedSensibleRecoveryEfficiency or SensibleRecoveryEfficiency but not both</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:AdjustedTotalRecoveryEfficiency) &lt; 0.5*number(h:AdjustedSensibleRecoveryEfficiency)'>Adjusted total recovery efficiency should typically be at least half of the adjusted sensible recovery efficiency.</sch:report>
      <sch:report role='WARN' test='number(h:TotalRecoveryEfficiency) &lt; 0.5*number(h:SensibleRecoveryEfficiency)'>Total recovery efficiency should typically be at least half of the sensible recovery efficiency.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=CFIS]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply"]'>
      <sch:assert role='ERROR' test='count(h:IsSharedSystem[text()="true"]) = 0'>Expected no IsSharedSystem="true"</sch:assert>
      <sch:assert role='ERROR' test='h:CFISControls/h:AdditionalRuntimeOperatingMode[text()="air handler fan" or text()="supplemental fan" or text()="none"] or not(h:CFISControls/h:AdditionalRuntimeOperatingMode)'>Expected CFISControls/AdditionalRuntimeOperatingMode to be 'air handler fan' or 'supplemental fan' or 'none'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:extension/h:ControlType) &lt;= 1'>Expected at most one CFISControls/extension/ControlType</sch:assert>
      <sch:assert role='ERROR' test='h:CFISControls/h:extension/h:ControlType[text()="optimized" or text()="timer"] or not(h:CFISControls/h:extension/h:ControlType)'>Expected CFISControls/extension/ControlType to be 'optimized' or 'timer'</sch:assert>
      <sch:assert role='ERROR' test='count(h:TotalRecoveryEfficiency) = 0'>Expected no TotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdjustedTotalRecoveryEfficiency) = 0'>Expected no AdjustedTotalRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:SensibleRecoveryEfficiency) = 0'>Expected no SensibleRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:AdjustedSensibleRecoveryEfficiency) = 0'>Expected no AdjustedSensibleRecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToHVACDistributionSystem) = 1'>Expected AttachedToHVACDistributionSystem</sch:assert>
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
      <sch:assert role='ERROR' test='count(h:CFISControls/h:SupplementalFan) = 0'>Expected no CFISControls/SupplementalFan if CFISControls/AdditionalRuntimeOperatingMode="air handler fan"</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:extension/h:SupplementalFanRunsWithAirHandlerFan) = 0'>Expected no CFISControls/extension/SupplementalFanRunsWithAirHandlerFan if CFISControls/AdditionalRuntimeOperatingMode="air handler fan"</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:VentilationOnlyModeAirflowFraction) &lt;= 1'>Expected at most one extension/VentilationOnlyModeAirflowFraction</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:VentilationOnlyModeAirflowFraction) &gt;= 0 or not(h:extension/h:VentilationOnlyModeAirflowFraction)'>Expected extension/VentilationOnlyModeAirflowFraction to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:VentilationOnlyModeAirflowFraction) &lt;= 1 or not(h:extension/h:VentilationOnlyModeAirflowFraction)'>Expected extension/VentilationOnlyModeAirflowFraction to be less than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CFISAdditionalRuntimeMode=SupplementalFan]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply" and h:CFISControls/h:AdditionalRuntimeOperatingMode="supplemental fan"]'>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:SupplementalFan) = 1'>Expected CFISControls/SupplementalFan if CFISControls/AdditionalRuntimeOperatingMode="supplemental fan"</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:extension/h:SupplementalFanRunsWithAirHandlerFan) &lt;= 1'>Expected at most one CFISControls/extension/SupplementalFanRunsWithAirHandlerFan</sch:assert>
      <sch:assert role='ERROR' test='h:CFISControls/h:extension/h:SupplementalFanRunsWithAirHandlerFan[text()="true" or text()="false"] or not(h:CFISControls/h:extension/h:SupplementalFanRunsWithAirHandlerFan)'>Expected CFISControls/extension/SupplementalFanRunsWithAirHandlerFan to be 'true' or 'false'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) = 0'>Expected no FanPower if CFISControls/AdditionalRuntimeOperatingMode="supplemental fan"</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:VentilationOnlyModeAirflowFraction) = 0'>Expected no extension/VentilationOnlyModeAirflowFraction if CFISControls/AdditionalRuntimeOperatingMode="supplemental fan"</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CFISAdditionalRuntimeMode=None]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:FanType="central fan integrated supply" and h:CFISControls/h:AdditionalRuntimeOperatingMode="none"]'>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:SupplementalFan) = 0'>Expected no CFISControls/SupplementalFan if CFISControls/AdditionalRuntimeOperatingMode="none"</sch:assert>
      <sch:assert role='ERROR' test='count(h:CFISControls/h:extension/h:SupplementalFanRunsWithAirHandlerFan) = 0'>Expected no CFISControls/extension/SupplementalFanRunsWithAirHandlerFan if CFISControls/AdditionalRuntimeOperatingMode="none"</sch:assert>
      <sch:assert role='ERROR' test='count(h:FanPower) = 0'>Expected no FanPower if CFISControls/AdditionalRuntimeOperatingMode="none"</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:VentilationOnlyModeAirflowFraction) = 0'>Expected no extension/VentilationOnlyModeAirflowFraction if CFISControls/AdditionalRuntimeOperatingMode="none"</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(h:FractionRecirculation) = 1'>Expected FractionRecirculation</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:InUnitFlowRate) = 1'>Expected extension/InUnitFlowRate</sch:assert>
      <sch:assert role='ERROR' test='number(h:RatedFlowRate) &gt; number(h:extension/h:InUnitFlowRate) or not(h:RatedFlowRate) or not(h:extension/h:InUnitFlowRate)'>Expected RatedFlowRate to be greater than extension/InUnitFlowRate</sch:assert>
      <sch:assert role='ERROR' test='number(h:CalculatedFlowRate) &gt; number(h:extension/h:InUnitFlowRate) or not(h:CalculatedFlowRate) or not(h:extension/h:InUnitFlowRate)'>Expected CalculatedFlowRate to be greater than extension/InUnitFlowRate</sch:assert>
      <sch:assert role='ERROR' test='number(h:TestedFlowRate) &gt; number(h:extension/h:InUnitFlowRate) or not(h:TestedFlowRate) or not(h:extension/h:InUnitFlowRate)'>Expected TestedFlowRate to be greater than extension/InUnitFlowRate</sch:assert>
      <sch:assert role='ERROR' test='number(h:DeliveredVentilation) &gt; number(h:extension/h:InUnitFlowRate) or not(h:DeliveredVentilation) or not(h:extension/h:InUnitFlowRate)'>Expected DeliveredVentilation to be greater than extension/InUnitFlowRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PreHeating) &lt;= 1'>Expected at most one extension/PreHeating</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:PreCooling) &lt;= 1'>Expected at most one extension/PreCooling</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=SharedWithPreHeating]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:IsSharedSystem="true"]/h:extension/h:PreHeating'>
      <sch:assert role='ERROR' test='count(../../h:FanType[text()="exhaust only"]) = 0'>Expected ../../FanType not to be 'exhaust only' if there is pre-heating</sch:assert>
      <sch:assert role='ERROR' test='h:Fuel[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"]'>Expected Fuel to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualHeatingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected AnnualHeatingEfficiency[Units="COP"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionVentilationHeatLoadServed) = 1'>Expected FractionVentilationHeatLoadServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:FractionVentilationHeatLoadServed) &gt;= 0 or not(h:FractionVentilationHeatLoadServed)'>Expected FractionVentilationHeatLoadServed to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:FractionVentilationHeatLoadServed) &lt;= 1 or not(h:FractionVentilationHeatLoadServed)'>Expected FractionVentilationHeatLoadServed to be less than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[MechanicalVentilationType=SharedWithPreCooling]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForWholeBuildingVentilation="true" and h:IsSharedSystem="true"]/h:extension/h:PreCooling'>
      <sch:assert role='ERROR' test='count(../../h:FanType[text()="exhaust only"]) = 0'>Expected ../../FanType not to be 'exhaust only' if there is pre-cooling</sch:assert>
      <sch:assert role='ERROR' test='h:Fuel[text()="electricity"]'>Expected Fuel to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualCoolingEfficiency[h:Units="COP"]/h:Value) = 1'>Expected AnnualCoolingEfficiency[Units="COP"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionVentilationCoolLoadServed) = 1'>Expected FractionVentilationCoolLoadServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:FractionVentilationCoolLoadServed) &gt;= 0 or not(h:FractionVentilationCoolLoadServed)'>Expected FractionVentilationCoolLoadServed to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:FractionVentilationCoolLoadServed) &lt;= 1 or not(h:FractionVentilationCoolLoadServed)'>Expected FractionVentilationCoolLoadServed to be less than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LocalVentilation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:MechanicalVentilation/h:VentilationFans/h:VentilationFan[h:UsedForLocalVentilation="true"]'>
      <sch:assert role='ERROR' test='h:FanLocation[text()="kitchen" or text()="bath"]'>Expected FanLocation to be 'kitchen' or 'bath' if UsedForLocalVentilation="true"</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:StartHour) &lt;= 1'>Expected at most one extension/StartHour</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:StartHour) &gt;= 0 or not(h:extension/h:StartHour)'>Expected extension/StartHour to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:StartHour) &lt;= 23 or not(h:extension/h:StartHour)'>Expected extension/StartHour to be less than or equal to 23</sch:assert>
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
      <sch:assert role='ERROR' test='count(../h:HotWaterDistribution) = 1'>Expected ../HotWaterDistribution</sch:assert>
      <sch:assert role='ERROR' test='count(../h:WaterFixture) &gt;= 1'>Expected ../WaterFixture</sch:assert>
      <sch:assert role='ERROR' test='h:WaterHeaterType[text()="storage water heater" or text()="instantaneous water heater" or text()="heat pump water heater" or text()="space-heating boiler with storage tank" or text()="space-heating boiler with tankless coil"]'>Expected WaterHeaterType to be 'storage water heater' or 'instantaneous water heater' or 'heat pump water heater' or 'space-heating boiler with storage tank' or 'space-heating boiler with tankless coil'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=Tank]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="storage water heater"]'>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"]'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatingCapacity) &gt; 0 or not(h:HeatingCapacity)'>Expected HeatingCapacity to be greater than 0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:UniformEnergyFactor) + count(h:EnergyFactor) = 1'>Expected UniformEnergyFactor or EnergyFactor but not both</sch:assert>
      <sch:assert role='ERROR' test='number(h:UniformEnergyFactor) &lt; 1 or not(h:UniformEnergyFactor)'>Expected UniformEnergyFactor to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:EnergyFactor) &lt; 1 or not(h:EnergyFactor)'>Expected EnergyFactor to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:RecoveryEfficiency) &gt; number(h:EnergyFactor) or not(h:RecoveryEfficiency) or not (h:EnergyFactor)'>Expected RecoveryEfficiency to be greater than EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='number(h:RecoveryEfficiency) &gt; number(h:UniformEnergyFactor) or not(h:RecoveryEfficiency) or not (h:UniformEnergyFactor)'>Expected RecoveryEfficiency to be greater than UniformEnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:TankModelType) &lt;= 1'>Expected at most one extension/TankModelType</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:TankModelType[text()="mixed" or text()="stratified"] or not(h:extension/h:TankModelType)'>Expected extension/TankModelType to be 'mixed' or 'stratified'</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:UniformEnergyFactor) &lt; 0.4'>UniformEnergyFactor should typically be greater than or equal to 0.4.</sch:report>
      <sch:report role='WARN' test='number(h:EnergyFactor) &lt; 0.4'>EnergyFactor should typically be greater than or equal to 0.4.</sch:report>
      <sch:report role='WARN' test='number(h:HeatingCapacity) &lt; 1000 and number(h:HeatingCapacity) &gt; 0'>Heating capacity should typically be greater than or equal to 1000 Btu/hr.</sch:report>
      <sch:report role='WARN' test='number(h:HotWaterTemperature) &lt; 110'>Hot water setpoint should typically be greater than or equal to 110 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=NonElectricTank]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="storage water heater" and h:FuelType!="electricity"]'>
      <sch:assert role='ERROR' test='count(h:extension/h:TankModelType[text()="stratified"]) = 0'>Expected no extension/TankModelType</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=Tankless]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="instantaneous water heater"]'>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"]'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:UniformEnergyFactor) + count(h:EnergyFactor) = 1'>Expected UniformEnergyFactor or EnergyFactor but not both</sch:assert>
      <sch:assert role='ERROR' test='number(h:UniformEnergyFactor) &lt; 1 or not(h:UniformEnergyFactor)'>Expected UniformEnergyFactor to be less than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:EnergyFactor) &lt; 1 or not(h:EnergyFactor)'>Expected EnergyFactor to be less than 1</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:UniformEnergyFactor) &lt; 0.4'>UniformEnergyFactor should typically be greater than or equal to 0.4.</sch:report>
      <sch:report role='WARN' test='number(h:EnergyFactor) &lt; 0.4'>EnergyFactor should typically be greater than or equal to 0.4.</sch:report>
      <sch:report role='WARN' test='number(h:HotWaterTemperature) &lt; 110'>Hot water setpoint should typically be greater than or equal to 110 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=HPWH]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="heat pump water heater"]'>
      <sch:assert role='ERROR' test='h:FuelType[text()="electricity"]'>Expected FuelType to be 'electricity'</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:HeatingCapacity) &gt; 0 or not(h:HeatingCapacity)'>Expected HeatingCapacity to be greater than 0.</sch:assert>
      <sch:assert role='ERROR' test='count(h:UniformEnergyFactor) + count(h:EnergyFactor) = 1'>Expected UniformEnergyFactor or EnergyFactor but not both</sch:assert>
      <sch:assert role='ERROR' test='number(h:UniformEnergyFactor) &gt; 1 or not(h:UniformEnergyFactor)'>Expected UniformEnergyFactor to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='number(h:EnergyFactor) &gt; 1 or not(h:EnergyFactor)'>Expected EnergyFactor to be greater than 1</sch:assert>
      <sch:assert role='ERROR' test='h:HPWHOperatingMode[text()="hybrid/auto" or text()="heat pump only"] or not(h:HPWHOperatingMode)'>Expected HPWHOperatingMode to be 'hybrid/auto' or 'heat pump only'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:HPWHInConfinedSpaceWithoutMitigation) &lt;= 1'>Expected at most one extension/HPWHInConfinedSpaceWithoutMitigation</sch:assert>
      <sch:assert role='ERROR' test='h:extension/h:HPWHInConfinedSpaceWithoutMitigation[text()="true" or text()="false"] or not(h:extension/h:HPWHInConfinedSpaceWithoutMitigation)'>Expected extension/HPWHInConfinedSpaceWithoutMitigation to be 'true' or 'false'</sch:assert>
      <!-- Moved/deprecated extension/OperatingMode input; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/1289 -->
      <sch:assert role='ERROR' test='count(h:extension/h:OperatingMode) = 0'>extension/OperatingMode has been replaced by HPWHOperatingMode</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:HotWaterTemperature) &lt; 110'>Hot water setpoint should typically be greater than or equal to 110 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=HPWHInConfinedSpaceWithoutMitigation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem/h:extension[h:HPWHInConfinedSpaceWithoutMitigation="true"]'>
      <sch:assert role='ERROR' test='count(h:HPWHContainmentVolume) = 1'>Expected HPWHContainmentVolume if HPWHInConfinedSpaceWithoutMitigation="true"</sch:assert>
      <sch:assert role='ERROR' test='number(h:HPWHContainmentVolume) &gt; 0 or not(h:HPWHContainmentVolume)'>Expected HPWHContainmentVolume to be greater than 0.</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:HPWHContainmentVolume) &gt; 1500'>HPWHContainmentVolume should typically be less than 1500 cuft when the HPWH is in confined space.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=CombiIndirect]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="space-heating boiler with storage tank"]'>
      <sch:assert role='ERROR' test='count(h:FuelType) = 0'>Expected no FuelType</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 0'>Expected no HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:UniformEnergyFactor) = 0'>Expected no UniformEnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:EnergyFactor) = 0'>Expected no EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:RecoveryEfficiency) = 0'>Expected no RecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsesDesuperheater[text()="true"]) = 0'>Expected no UsesDesuperheater=true</sch:assert>
      <sch:assert role='ERROR' test='count(h:RelatedHVACSystem) = 1'>Expected RelatedHVACSystem</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:HotWaterTemperature) &lt; 110'>Hot water setpoint should typically be greater than or equal to 110 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystemType=CombiTanklessCoil]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:WaterHeaterType="space-heating boiler with tankless coil"]'>
      <sch:assert role='ERROR' test='count(h:FuelType) = 0'>Expected no FuelType</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:TankVolume) = 0'>Expected no TankVolume</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDHWLoadServed) = 1'>Expected FractionDHWLoadServed</sch:assert>
      <sch:assert role='ERROR' test='count(h:HeatingCapacity) = 0'>Expected no HeatingCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:UniformEnergyFactor) = 0'>Expected no UniformEnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:EnergyFactor) = 0'>Expected no EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:RecoveryEfficiency) = 0'>Expected no RecoveryEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:WaterHeaterInsulation/h:Jacket/h:JacketRValue) = 0'>Expected no WaterHeaterInsulation/Jacket/JacketRValue</sch:assert>
      <sch:assert role='ERROR' test='count(h:StandbyLoss[h:Units="F/hr"]/h:Value) = 0'>Expected no StandbyLoss[Units="F/hr"]/Value</sch:assert>
      <sch:assert role='ERROR' test='count(h:UsesDesuperheater[text()="true"]) = 0'>Expected no UsesDesuperheater=true</sch:assert>
      <sch:assert role='ERROR' test='count(h:RelatedHVACSystem) = 1'>Expected RelatedHVACSystem</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:HotWaterTemperature) &lt; 110'>Hot water setpoint should typically be greater than or equal to 110 deg-F.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterHeatingSystem=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType=("single-family attached" or "apartment unit")]</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:NumberofBedroomsServed) = 1'>Expected extension/NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:NumberofBedroomsServed) &gt; number(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:extension/h:NumberofBedroomsServed) or not(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected extension/NumberofBedroomsServed to be greater than ../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Desuperheater]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterHeatingSystem[h:UsesDesuperheater="true"]'>
      <sch:assert role='ERROR' test='count(h:RelatedHVACSystem) = 1'>Expected RelatedHVACSystem if UsesDesuperheater="true"</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HotWaterDistribution]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution'>
      <sch:assert role='ERROR' test='count(h:SystemType) = 1'>Expected SystemType</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:SharedRecirculation) &lt;= 1'>Expected at most one extension/SharedRecirculation</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HotWaterDistributionType=Recirculation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution/h:SystemType/h:Recirculation'>
      <sch:assert role='ERROR' test='count(h:ControlType) = 1'>Expected ControlType</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:extension/h:RecirculationPumpWeekdayScheduleFractions) &lt;= 1'>Expected at most one ../../extension/RecirculationPumpWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:extension/h:RecirculationPumpWeekendScheduleFractions) &lt;= 1'>Expected at most one ../../extension/RecirculationPumpWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:extension/h:RecirculationPumpMonthlyScheduleMultipliers) &lt;= 1'>Expected at most one ../../extension/RecirculationPumpMonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[HotWaterDistributionType=SharedRecirculation]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution/h:extension/h:SharedRecirculation'>
      <sch:assert role='ERROR' test='count(../../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected ../../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType=("single-family attached" or "apartment unit")]</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:SystemType/h:Standard) = 1'>Expected ../../SystemType/Standard</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofBedroomsServed) = 1'>Expected NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofBedroomsServed) &gt; number(../../../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:NumberofBedroomsServed) or not(../../../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected NumberofBedroomsServed to be greater than ../../../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
      <sch:assert role='ERROR' test='count(h:PumpPower) &lt;= 1'>Expected at most one PumpPower</sch:assert>
      <sch:assert role='ERROR' test='number(h:PumpPower) &gt;= 0 or not(h:PumpPower)'>Expected PumpPower to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='h:ControlType[text()="manual demand control" or text()="presence sensor demand control" or text()="temperature" or text()="timer" or text()="no control"]'>Expected ControlType to be 'manual demand control' or 'presence sensor demand control' or 'temperature' or 'timer' or 'no control'</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:extension/h:RecirculationPumpWeekdayScheduleFractions) &lt;= 1'>Expected at most one ../../extension/RecirculationPumpWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:extension/h:RecirculationPumpWeekendScheduleFractions) &lt;= 1'>Expected at most one ../../extension/RecirculationPumpWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(../../h:extension/h:RecirculationPumpMonthlyScheduleMultipliers) &lt;= 1'>Expected at most one ../../extension/RecirculationPumpMonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DrainWaterHeatRecovery]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:HotWaterDistribution/h:DrainWaterHeatRecovery'>
      <sch:assert role='ERROR' test='count(h:FacilitiesConnected) = 1'>Expected FacilitiesConnected</sch:assert>
      <sch:assert role='ERROR' test='count(h:EqualFlow) = 1'>Expected EqualFlow</sch:assert>
      <sch:assert role='ERROR' test='count(h:Efficiency) = 1'>Expected Efficiency</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[WaterFixture]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:WaterHeating/h:WaterFixture'>
      <sch:assert role='ERROR' test='count(../h:HotWaterDistribution) = 1'>Expected ../HotWaterDistribution</sch:assert>
      <sch:assert role='ERROR' test='h:WaterFixtureType[text()="shower head" or text()="faucet"]'>Expected WaterFixtureType to be 'shower head' or 'faucet'</sch:assert>
      <sch:assert role='ERROR' test='count(h:LowFlow | h:FlowRate) &gt;= 1'>Expected LowFlow or FlowRate</sch:assert>
      <sch:assert role='ERROR' test='count(../h:extension/h:WaterFixturesUsageMultiplier) &lt;= 1'>Expected at most one ../extension/WaterFixturesUsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(../h:extension/h:WaterFixturesUsageMultiplier) &gt;= 0 or not(../h:extension/h:WaterFixturesUsageMultiplier)'>Expected ../extension/WaterFixturesUsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(../h:extension/h:WaterFixturesWeekdayScheduleFractions) &lt;= 1'>Expected at most one ../extension/WaterFixturesWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(../h:extension/h:WaterFixturesWeekendScheduleFractions) &lt;= 1'>Expected at most one ../extension/WaterFixturesWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(../h:extension/h:WaterFixturesMonthlyScheduleMultipliers) &lt;= 1'>Expected at most one ../extension/WaterFixturesMonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SolarThermalSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:SolarThermal/h:SolarThermalSystem'>
      <sch:assert role='ERROR' test='h:SystemType[text()="hot water"]'>Expected SystemType to be 'hot water'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorArea) + count(h:SolarFraction) = 1'>Expected CollectorArea or SolarFraction but not both</sch:assert>
      <sch:assert role='ERROR' test='number(h:SolarFraction) &lt;= 0.99 or not(h:SolarFraction)'>Expected SolarFraction to be less than or equal to 0.99</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[SolarThermalSystemType=Detailed]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:SolarThermal/h:SolarThermalSystem[not(h:SolarFraction)]'>
      <sch:assert role='ERROR' test='h:CollectorLoopType[text()="liquid indirect" or text()="liquid direct" or text()="passive thermosyphon"]'>Expected CollectorLoopType to be 'liquid indirect' or 'liquid direct' or 'passive thermosyphon'</sch:assert>
      <sch:assert role='ERROR' test='h:CollectorType[text()="single glazing black" or text()="double glazing black" or text()="evacuated tube" or text()="integrated collector storage"]'>Expected CollectorType to be 'single glazing black' or 'double glazing black' or 'evacuated tube' or 'integrated collector storage'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorAzimuth) + count(h:CollectorOrientation) &gt;= 1'>Expected CollectorAzimuth or CollectorOrientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorTilt) = 1'>Expected CollectorTilt</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorRatedOpticalEfficiency) = 1'>Expected CollectorRatedOpticalEfficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:CollectorRatedThermalLosses) = 1'>Expected CollectorRatedThermalLosses</sch:assert>
      <sch:assert role='ERROR' test='count(h:ConnectedTo) = 1'>Expected ConnectedTo</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVSystem]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Photovoltaics/h:PVSystem'>
      <sch:assert role='ERROR' test='h:Location[text()="ground" or text()="roof"] or not(h:Location)'>Expected Location to be 'ground' or 'roof'</sch:assert>
      <sch:assert role='ERROR' test='count(h:ArrayAzimuth) + count(h:ArrayOrientation) &gt;= 1'>Expected ArrayAzimuth or ArrayOrientation</sch:assert>
      <sch:assert role='ERROR' test='count(h:ArrayTilt) = 1'>Expected ArrayTilt</sch:assert>
      <sch:assert role='ERROR' test='count(h:MaxPowerOutput) = 1'>Expected MaxPowerOutput</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:MaxPowerOutput) &lt;= 500 and number(h:MaxPowerOutput) &gt; 0'>Max power output should typically be greater than or equal to 500 W.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVSystemType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Photovoltaics/h:PVSystem[h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType=("single-family attached" or "apartment unit")]</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:NumberofBedroomsServed) = 1'>Expected extension/NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:NumberofBedroomsServed) &gt; number(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:extension/h:NumberofBedroomsServed) or not(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected extension/NumberofBedroomsServed to be greater than ../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PVSystemWithMultipleInverters]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Photovoltaics/h:PVSystem[count(../h:Inverter) &gt; 1]'>
      <sch:assert role='ERROR' test='count(h:AttachedToInverter) = 1'>Expected AttachedToInverter if multiple Inverters are specified</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ElectricPanel]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:ElectricPanels/h:ElectricPanel'>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:MaxCurrentRating) &gt; 400'>MaxCurrentRating should typically be less than or equal to 400.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BranchCircuit]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:ElectricPanels/h:ElectricPanel/h:BranchCircuits/h:BranchCircuit'>
      <sch:assert role='ERROR' test='count(h:Voltage[text()="240"]) + count(../../../h:ElectricPanel[h:Voltage[text()="120"]]) &lt; 2'>Expected ../../../ElectricPanel/Voltage to be '240'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ServiceFeeder]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:ElectricPanels/h:ElectricPanel/h:ServiceFeeders/h:ServiceFeeder'>
      <sch:assert role='ERROR' test='h:LoadType[text()="heating" or text()="cooling" or text()="hot water" or text()="clothes dryer" or text()="dishwasher" or text()="range/oven" or text()="mech vent" or text()="permanent spa heater" or text()="permanent spa pump" or text()="pool heater" or text()="pool pump" or text()="well pump" or text()="electric vehicle charging" or text()="lighting" or text()="kitchen" or text()="laundry" or text()="other"]'>Expected LoadType to be 'heating' or 'cooling' or 'hot water' or 'clothes dryer' or 'dishwasher' or 'range/oven' or 'mech vent' or 'permanent spa heater' or 'permanent spa pump' or 'pool heater' or 'pool pump' or 'well pump' or 'electric vehicle charging' or 'lighting' or 'kitchen' or 'laundry' or 'other'</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ServiceFeeder=AttachedToComponent]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:ElectricPanels/h:ElectricPanel/h:ServiceFeeders/h:ServiceFeeder[h:LoadType[text()="heating" or text()="cooling" or text()="hot water" or text()="clothes dryer" or text()="dishwasher" or text()="range/oven" or text()="mech vent" or text()="permanent spa heater" or text()="permanent spa pump" or text()="pool heater" or text()="pool pump" or text()="well pump" or text()="electric vehicle charging"]]'>
      <sch:assert role='ERROR' test='count(h:AttachedToComponent) = 1'>Expected AttachedToComponent</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ServiceFeeder=NotAttachedToComponent]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:ElectricPanels/h:ElectricPanel/h:ServiceFeeders/h:ServiceFeeder[h:LoadType[text()="lighting" or text()="kitchen" or text()="laundry" or text()="other"]]'>
      <sch:assert role='ERROR' test='count(h:AttachedToComponent) = 0'>Expected no AttachedToComponent</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Battery]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Batteries/h:Battery'>
      <sch:assert role='ERROR' test='h:BatteryType[text()="Li-ion"]'>Expected BatteryType to be 'Li-ion'</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="crawlspace - conditioned" or text()="attic - vented" or text()="attic - unvented" or text()="garage" or text()="outside"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'attic - vented' or 'attic - unvented' or 'garage' or 'outside'</sch:assert>
      <sch:assert role='ERROR' test='number(h:UsableCapacity[h:Units="kWh"]/h:Value) &lt; number(h:NominalCapacity[h:Units="kWh"]/h:Value) or not(h:UsableCapacity[h:Units="kWh"]/h:Value) or not(h:NominalCapacity[h:Units="kWh"]/h:Value)'>Expected UsableCapacity to be less than NominalCapacity</sch:assert>
      <sch:assert role='ERROR' test='number(h:UsableCapacity[h:Units="Ah"]/h:Value) &lt; number(h:NominalCapacity[h:Units="Ah"]/h:Value) or not(h:UsableCapacity[h:Units="Ah"]/h:Value) or not(h:NominalCapacity[h:Units="Ah"]/h:Value)'>Expected UsableCapacity to be less than NominalCapacity</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='number(h:RatedPowerOutput) &lt; 1000 and number(h:RatedPowerOutput) &gt; 0'>Rated power output should typically be greater than or equal to 1000 W.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[BatteryType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Batteries/h:Battery[h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType=("single-family attached" or "apartment unit")]</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:NumberofBedroomsServed) = 1'>Expected extension/NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:NumberofBedroomsServed) &gt; number(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:extension/h:NumberofBedroomsServed) or not(../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected extension/NumberofBedroomsServed to be greater than ../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Vehicles]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Vehicles'>
     <sch:assert role='ERROR' test='count(h:Vehicle/h:VehicleType/h:BatteryElectricVehicle) &lt;= 1'>Expected at most one Vehicle/VehicleType/BatteryElectricVehicle</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Vehicle]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Vehicles/h:Vehicle'>
      <sch:assert role='ERROR' test='count(h:VehicleType) = 1'>Expected VehicleType</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[VehicleType=BEV]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:Vehicles/h:Vehicle/h:VehicleType/h:BatteryElectricVehicle'>
      <sch:assert role='ERROR' test='h:Battery/h:BatteryType[text()="Li-ion"] or not(h:Battery/h:BatteryType)'>Expected Battery/BatteryType to be 'Li-ion'</sch:assert>
      <sch:assert role='ERROR' test='number(h:Battery/h:UsableCapacity[h:Units="kWh"]/h:Value) &lt; number(h:Battery/h:NominalCapacity[h:Units="kWh"]/h:Value) or not(h:Battery/h:UsableCapacity[h:Units="kWh"]/h:Value) or not(h:Battery/h:NominalCapacity[h:Units="kWh"]/h:Value)'>Expected UsableCapacity to be less than NominalCapacity</sch:assert>
      <sch:assert role='ERROR' test='number(h:Battery/h:UsableCapacity[h:Units="Ah"]/h:Value) &lt; number(h:Battery/h:NominalCapacity[h:Units="Ah"]/h:Value) or not(h:Battery/h:UsableCapacity[h:Units="Ah"]/h:Value) or not(h:Battery/h:NominalCapacity[h:Units="Ah"]/h:Value)'>Expected UsableCapacity to be less than NominalCapacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionChargedLocation[h:Location="Home"]/h:Percentage) &lt;= 1'>Expected at most one FractionChargedLocation[Location="Home"]/Percentage</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected at most one extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='../../h:FuelEconomyCombined[h:Units="kWh/mile" or h:Units="mile/kWh" or h:Units="mpge"] or not(../../h:FuelEconomyCombined/h:Units)'>Expected ../../FuelEconomyCombined/Units to be 'kWh/mile' or 'mile/kWh' or 'mpge'</sch:assert>
      <!-- Warnings -->
      <sch:report role='WARN' test='count(../../../../../h:MiscLoads/h:PlugLoad[h:PlugLoadType[text()="electric vehicle charging"]]) &gt;= 1'>Electric vehicle charging was specified as both a PlugLoad and a Vehicle, the latter will be ignored.</sch:report>
      <sch:report role='WARN' test='count(h:ConnectedCharger) = 0'>Electric vehicle specified with no charger provided; home EV charging will not be modeled.</sch:report>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Generator]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:extension/h:Generators/h:Generator'>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="wood" or text()="wood pellets"]'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualConsumptionkBtu) = 1'>Expected AnnualConsumptionkBtu</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualConsumptionkBtu) &gt; 0 or not(h:AnnualConsumptionkBtu)'>Expected AnnualConsumptionkBtu to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:AnnualOutputkWh) = 1'>Expected AnnualOutputkWh</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualOutputkWh) &gt; 0 or not(h:AnnualOutputkWh)'>Expected AnnualOutputkWh to be greater than 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:AnnualConsumptionkBtu) &gt; (number(h:AnnualOutputkWh) * 3.412) or not(h:AnnualConsumptionkBtu) or not(h:AnnualOutputkWh)'>Expected AnnualConsumptionkBtu to be greater than AnnualOutputkWh*3412</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[GeneratorType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Systems/h:extension/h:Generators/h:Generator[h:IsSharedSystem="true"]'>
      <sch:assert role='ERROR' test='count(../../../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType=("single-family attached" or "apartment unit")]</sch:assert>
      <sch:assert role='ERROR' test='count(h:NumberofBedroomsServed) = 1'>Expected NumberofBedroomsServed</sch:assert>
      <sch:assert role='ERROR' test='number(h:NumberofBedroomsServed) &gt; number(../../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms) or not(h:NumberofBedroomsServed) or not(../../../../h:BuildingSummary/h:BuildingConstruction/h:NumberofBedrooms)'>Expected NumberofBedroomsServed to be greater than ../../../../BuildingSummary/BuildingConstruction/NumberofBedrooms</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesWasher]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesWasher'>
      <sch:assert role='ERROR' test='count(../../h:Systems/h:WaterHeating/h:HotWaterDistribution) = 1'>Expected ../../Systems/WaterHeating/HotWaterDistribution</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedModifiedEnergyFactor) + count(h:ModifiedEnergyFactor) &lt;= 1'>Expected not both IntegratedModifiedEnergyFactor and ModifiedEnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected at most one extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesWasherType=Detailed]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesWasher[h:IntegratedModifiedEnergyFactor | h:ModifiedEnergyFactor]'>
      <sch:assert role='ERROR' test='count(h:RatedAnnualkWh) = 1'>Expected RatedAnnualkWh</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelElectricRate) = 1'>Expected LabelElectricRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelGasRate) = 1'>Expected LabelGasRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelAnnualGasCost) = 1'>Expected LabelAnnualGasCost</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelUsage) = 1'>Expected LabelUsage</sch:assert>
      <sch:assert role='ERROR' test='count(h:Capacity) = 1'>Expected Capacity</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesWasherType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesWasher[h:IsSharedAppliance="true"]'>
      <sch:assert role='ERROR' test='count(../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType=("single-family attached" or "apartment unit")]</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToWaterHeatingSystem) + count(h:AttachedToHotWaterDistribution) = 1'>Expected AttachedToWaterHeatingSystem or AttachedToHotWaterDistribution but not both</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesDryer]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesDryer'>
      <sch:assert role='ERROR' test='count(../h:ClothesWasher) = 1'>Expected ../ClothesWasher</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"]'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:CombinedEnergyFactor) + count(h:EnergyFactor) &lt;= 1'>Expected not both CombinedEnergyFactor and EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected at most one extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
      <!-- Moved/deprecated extension/IsVented and extension/VentedFlowRate inputs; see https://github.com/NatLabRockies/OpenStudio-HPXML/pull/751 -->
      <sch:assert role='ERROR' test='count(h:extension/h:IsVented) = 0'>extension/IsVented has been replaced by Vented</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:VentedFlowRate) = 0'>extension/VentedFlowRate has been replaced by VentedFlowRate</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ClothesDryerType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:ClothesDryer[h:IsSharedAppliance="true"]'>
      <sch:assert role='ERROR' test='count(../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType=("single-family attached" or "apartment unit")]</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Dishwasher]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Dishwasher'>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:RatedAnnualkWh) + count(h:EnergyFactor) &lt;= 1'>Expected not both RatedAnnualkWh and EnergyFactor</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected at most one extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DishwasherType=Detailed]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Dishwasher[h:RatedAnnualkWh | h:EnergyFactor]'>
      <sch:assert role='ERROR' test='count(h:LabelElectricRate) = 1'>Expected LabelElectricRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelGasRate) = 1'>Expected LabelGasRate</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelAnnualGasCost) = 1'>Expected LabelAnnualGasCost</sch:assert>
      <sch:assert role='ERROR' test='count(h:LabelUsage) = 1'>Expected LabelUsage</sch:assert>
      <sch:assert role='ERROR' test='count(h:PlaceSettingCapacity) = 1'>Expected PlaceSettingCapacity</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[DishwasherType=Shared]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Dishwasher[h:IsSharedAppliance="true"]'>
      <sch:assert role='ERROR' test='count(../../h:BuildingSummary/h:BuildingConstruction[h:ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]) = 1'>Expected ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType=("single-family attached" or "apartment unit")]</sch:assert>
      <sch:assert role='ERROR' test='count(h:AttachedToWaterHeatingSystem) + count(h:AttachedToHotWaterDistribution) = 1'>Expected AttachedToWaterHeatingSystem or AttachedToHotWaterDistribution but not both</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Refrigerator]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Refrigerator'>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected at most one extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ConstantScheduleCoefficients) &lt;= 1'>Expected at most one extension/ConstantScheduleCoefficients</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:TemperatureScheduleCoefficients) &lt;= 1'>Expected at most one extension/TemperatureScheduleCoefficients</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension[h:WeekdayScheduleFractions | h:WeekendScheduleFractions | h:MonthlyScheduleMultipliers]) + count(h:extension[h:ConstantScheduleCoefficients | h:TemperatureScheduleCoefficients]) &lt;= 1'>Expected not both schedule fractions/multipliers and schedule coefficients</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Freezer]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Freezer'>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected at most one extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ConstantScheduleCoefficients) &lt;= 1'>Expected at most one extension/ConstantScheduleCoefficients</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:TemperatureScheduleCoefficients) &lt;= 1'>Expected at most one extension/TemperatureScheduleCoefficients</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension[h:WeekdayScheduleFractions | h:WeekendScheduleFractions | h:MonthlyScheduleMultipliers]) + count(h:extension[h:ConstantScheduleCoefficients | h:TemperatureScheduleCoefficients]) &lt;= 1'>Expected not both schedule fractions/multipliers and schedule coefficients</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Dehumidifier]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Dehumidifier'>
      <sch:assert role='ERROR' test='count(h:Type) = 1'>Expected Type</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space"]'>Expected Location to be 'conditioned space'</sch:assert>
      <sch:assert role='ERROR' test='count(h:Capacity) = 1'>Expected Capacity</sch:assert>
      <sch:assert role='ERROR' test='count(h:IntegratedEnergyFactor) + count(h:EnergyFactor) = 1'>Expected IntegratedEnergyFactor or EnergyFactor but not both</sch:assert>
      <sch:assert role='ERROR' test='count(h:DehumidistatSetpoint) = 1'>Expected DehumidistatSetpoint</sch:assert>
      <sch:assert role='ERROR' test='count(h:FractionDehumidificationLoadServed) = 1'>Expected FractionDehumidificationLoadServed</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CookingRange]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:CookingRange'>
      <sch:assert role='ERROR' test='count(../h:Oven) = 1'>Expected ../Oven</sch:assert>
      <sch:assert role='ERROR' test='h:Location[text()="conditioned space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="crawlspace - conditioned" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"] or not(h:Location)'>Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'</sch:assert>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="electricity" or text()="wood" or text()="wood pellets"]'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'electricity' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected at most one extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Oven]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Appliances/h:Oven'>
      <sch:assert role='ERROR' test='count(../h:CookingRange) = 1'>Expected ../CookingRange</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Lighting]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting'>
      <sch:assert role='ERROR' test='count(h:extension/h:InteriorUsageMultiplier) &lt;= 1'>Expected at most one extension/InteriorUsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:InteriorUsageMultiplier) &gt;= 0 or not(h:extension/h:InteriorUsageMultiplier)'>Expected extension/InteriorUsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GarageUsageMultiplier) &lt;= 1'>Expected at most one extension/GarageUsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:GarageUsageMultiplier) &gt;= 0 or not(h:extension/h:GarageUsageMultiplier)'>Expected extension/GarageUsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ExteriorUsageMultiplier) &lt;= 1'>Expected at most one extension/ExteriorUsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:ExteriorUsageMultiplier) &gt;= 0 or not(h:extension/h:ExteriorUsageMultiplier)'>Expected extension/ExteriorUsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:InteriorWeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/InteriorWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:InteriorWeekendScheduleFractions) &lt;= 1'>Expected at most one extension/InteriorWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:InteriorMonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/InteriorMonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GarageWeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/GarageWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GarageWeekendScheduleFractions) &lt;= 1'>Expected at most one extension/GarageWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:GarageMonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/GarageMonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ExteriorWeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/ExteriorWeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ExteriorWeekendScheduleFractions) &lt;= 1'>Expected at most one extension/ExteriorWeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ExteriorMonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/ExteriorMonthlyScheduleMultipliers</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:ExteriorHolidayLighting) &lt;= 1'>Expected at most one extension/ExteriorHolidayLighting</sch:assert>
      <!-- Sum Checks -->
      <sch:assert role='ERROR' test='sum(h:LightingGroup[h:Location="interior"]/h:FractionofUnitsInLocation) &lt;= 1.01'>Expected sum(LightingGroup/FractionofUnitsInLocation) for Location="interior" to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='sum(h:LightingGroup[h:Location="exterior"]/h:FractionofUnitsInLocation) &lt;= 1.01'>Expected sum(LightingGroup/FractionofUnitsInLocation) for Location="exterior" to be less than or equal to 1</sch:assert>
      <sch:assert role='ERROR' test='sum(h:LightingGroup[h:Location="garage"]/h:FractionofUnitsInLocation) &lt;= 1.01'>Expected sum(LightingGroup/FractionofUnitsInLocation) for Location="garage" to be less than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LightingGroup=Interior]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:LightingGroup[h:Location="interior"]'>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:LightEmittingDiode] and h:Location="interior"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected ../LightingGroup[LightingType[LightEmittingDiode] and Location="interior"]/FractionofUnitsInLocation or Load[Units="kWh/year"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:CompactFluorescent] and h:Location="interior"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation or Load[Units="kWh/year"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:FluorescentTube] and h:Location="interior"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected ../LightingGroup[LightingType[FluorescentTube] and Location="interior"]/FractionofUnitsInLocation or Load[Units="kWh/year"]/Value but not both</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LightingGroup=Exterior]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:LightingGroup[h:Location="exterior"]'>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:LightEmittingDiode] and h:Location="exterior"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected ../LightingGroup[LightingType[LightEmittingDiode] and Location="exterior"]/FractionofUnitsInLocation or Load[Units="kWh/year"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:CompactFluorescent] and h:Location="exterior"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation or Load[Units="kWh/year"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:FluorescentTube] and h:Location="exterior"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected ../LightingGroup[LightingType[FluorescentTube] and Location="exterior"]/FractionofUnitsInLocation or Load[Units="kWh/year"]/Value but not both</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[LightingGroup=Garage]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:LightingGroup[h:Location="garage"]'>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:LightEmittingDiode] and h:Location="garage"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected ../LightingGroup[LightingType[LightEmittingDiode] and Location="garage"]/FractionofUnitsInLocation or Load[Units="kWh/year"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:CompactFluorescent] and h:Location="garage"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation or Load[Units="kWh/year"]/Value but not both</sch:assert>
      <sch:assert role='ERROR' test='count(../h:LightingGroup[h:LightingType[h:FluorescentTube] and h:Location="garage"]/h:FractionofUnitsInLocation) + count(h:Load[h:Units="kWh/year"]/h:Value) = 1'>Expected ../LightingGroup[LightingType[FluorescentTube] and Location="garage"]/FractionofUnitsInLocation or Load[Units="kWh/year"]/Value but not both</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ExteriorHolidayLighting]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:extension/h:ExteriorHolidayLighting'>
      <sch:assert role='ERROR' test='count(h:Load[h:Units="kWh/day"]/h:Value) &lt;= 1'>Expected at most one Load[Units="kWh/day"]/Value</sch:assert>
      <sch:assert role='ERROR' test='number(h:Load[h:Units="kWh/day"]/h:Value) &gt;= 0 or not(h:Load[h:Units="kWh/day"]/h:Value)'>Expected Load[Units="kWh/day"]/Value to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:WeekendScheduleFractions) &lt;= 1'>Expected at most one WeekendScheduleFractions</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ExteriorHolidayLighting=BeginPeriod]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:extension/h:ExteriorHolidayLighting[h:PeriodBeginMonth | h:PeriodBeginDayOfMonth]'>
      <sch:assert role='ERROR' test='count(h:PeriodBeginMonth) = 1'>Expected PeriodBeginMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:PeriodBeginDayOfMonth) = 1'>Expected PeriodBeginDayOfMonth</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[ExteriorHolidayLighting=EndPeriod]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:extension/h:ExteriorHolidayLighting[h:PeriodEndMonth | h:PeriodEndDayOfMonth]'>
      <sch:assert role='ERROR' test='count(h:PeriodEndMonth) = 1'>Expected PeriodEndMonth</sch:assert>
      <sch:assert role='ERROR' test='count(h:PeriodEndDayOfMonth) = 1'>Expected PeriodEndDayOfMonth</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[CeilingFan]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Lighting/h:CeilingFan'>
      <sch:assert role='ERROR' test='count(h:Airflow[h:FanSpeed="medium"]/h:Efficiency) &lt;= 1'>Expected at most one Airflow[FanSpeed="medium"]/Efficiency</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Pool]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Pools/h:Pool'>
      <sch:assert role='ERROR' test='count(h:Type) = 1'>Expected Type</sch:assert>
      <sch:assert role='ERROR' test='count(h:Pumps/h:Pump) &lt;= 1'>Expected at most one Pumps/Pump</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Pool=Pump]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Pools/h:Pool/h:Pumps/h:Pump'>
      <sch:assert role='ERROR' test='count(h:Type) = 1'>Expected Type</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected at most one extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[Pool=Heater]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Pools/h:Pool/h:Heater'>
      <sch:assert role='ERROR' test='h:Type[text()="not present" or text()="gas fired" or text()="electric resistance" or text()="heat pump"]'>Expected Type to be 'not present' or 'gas fired' or 'electric resistance' or 'heat pump'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected at most one extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PermanentSpa]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Spas/h:PermanentSpa'>
      <sch:assert role='ERROR' test='count(h:Type) = 1'>Expected Type</sch:assert>
      <sch:assert role='ERROR' test='count(h:Pumps/h:Pump) &lt;= 1'>Expected at most one Pumps/Pump</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PermanentSpa=Pump]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Spas/h:PermanentSpa/h:Pumps/h:Pump'>
      <sch:assert role='ERROR' test='count(h:Type) = 1'>Expected Type</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected at most one extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PermanentSpa=Heater]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:Spas/h:PermanentSpa/h:Heater'>
      <sch:assert role='ERROR' test='h:Type[text()="not present" or text()="gas fired" or text()="electric resistance" or text()="heat pump"]'>Expected Type to be 'not present' or 'gas fired' or 'electric resistance' or 'heat pump'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected at most one extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PlugLoad]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:MiscLoads/h:PlugLoad[h:PlugLoadType="other" or h:PlugLoadType="TV other" or h:PlugLoadType="electric vehicle charging" or h:PlugLoadType="well pump"]'>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected at most one extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[PlugLoad=SensibleLatentFractions]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:MiscLoads/h:PlugLoad[h:extension/h:FracSensible | h:extension/h:FracLatent]'>
      <sch:assert role='ERROR' test='count(h:extension/h:FracSensible) = 1'>Expected extension/FracSensible</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FracLatent) = 1'>Expected extension/FracLatent</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FracSensible) &gt;= 0 or not(h:extension/h:FracSensible)'>Expected extension/FracSensible to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FracLatent) &gt;= 0 or not(h:extension/h:FracLatent)'>Expected extension/FracLatent to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='(number(h:extension/h:FracSensible) + number(h:extension/h:FracLatent)) &lt;= 1 or not(h:extension/h:FracSensible) or not(h:extension/h:FracLatent)'>Expected sum of extension/FracSensible and extension/FracLatent to be less than or equal to 1</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FuelLoad]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:MiscLoads/h:FuelLoad[h:FuelLoadType="grill" or h:FuelLoadType="lighting" or h:FuelLoadType="fireplace"]'>
      <sch:assert role='ERROR' test='h:FuelType[text()="natural gas" or text()="fuel oil" or text()="fuel oil 1" or text()="fuel oil 2" or text()="fuel oil 4" or text()="fuel oil 5/6" or text()="diesel" or text()="propane" or text()="kerosene" or text()="coal" or text()="coke" or text()="bituminous coal" or text()="anthracite coal" or text()="wood" or text()="wood pellets"]'>Expected FuelType to be 'natural gas' or 'fuel oil' or 'fuel oil 1' or 'fuel oil 2' or 'fuel oil 4' or 'fuel oil 5/6' or 'diesel' or 'propane' or 'kerosene' or 'coal' or 'coke' or 'bituminous coal' or 'anthracite coal' or 'wood' or 'wood pellets'</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:UsageMultiplier) &lt;= 1'>Expected at most one extension/UsageMultiplier</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:UsageMultiplier) &gt;= 0 or not(h:extension/h:UsageMultiplier)'>Expected extension/UsageMultiplier to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekdayScheduleFractions) &lt;= 1'>Expected at most one extension/WeekdayScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:WeekendScheduleFractions) &lt;= 1'>Expected at most one extension/WeekendScheduleFractions</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:MonthlyScheduleMultipliers) &lt;= 1'>Expected at most one extension/MonthlyScheduleMultipliers</sch:assert>
    </sch:rule>
  </sch:pattern>

  <sch:pattern>
    <sch:title>[FuelLoad=SensibleLatentFractions]</sch:title>
    <sch:rule context='/h:HPXML/h:Building/h:BuildingDetails/h:MiscLoads/h:FuelLoad[h:extension/h:FracSensible | h:extension/h:FracLatent]'>
      <sch:assert role='ERROR' test='count(h:extension/h:FracSensible) = 1'>Expected extension/FracSensible</sch:assert>
      <sch:assert role='ERROR' test='count(h:extension/h:FracLatent) = 1'>Expected extension/FracLatent</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FracSensible) &gt;= 0 or not(h:extension/h:FracSensible)'>Expected extension/FracSensible to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='number(h:extension/h:FracLatent) &gt;= 0 or not(h:extension/h:FracLatent)'>Expected extension/FracLatent to be greater than or equal to 0</sch:assert>
      <sch:assert role='ERROR' test='(number(h:extension/h:FracSensible) + number(h:extension/h:FracLatent)) &lt;= 1 or not(h:extension/h:FracSensible) or not(h:extension/h:FracLatent)'>Expected sum of extension/FracSensible and extension/FracLatent to be less than or equal to 1</sch:assert>
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