## OpenStudio-HPXML v1.11.0

__New Features__
- Updates to HPXML v4.2-rc3.

## OpenStudio-HPXML v1.10.0

__New Features__
- Updates to OpenStudio 3.10/EnergyPlus 25.1/HPXML v4.2-rc2.
- HVAC modeling updates per RESNET HERS Addendum 82:
  - **Breaking change**: `CompressorType` required for central and mini-split air conditioners and heat pumps as well as ground-to-air heat pumps.
  - **Breaking change**: Replaces `HeatingCapacityRetention[Fraction | Temperature]` with `HeatingCapacityFraction17F`.
  - Allows optional pan heater inputs (`extension/PanHeaterPowerWatts` and `extension/PanHeaterControlType`) for central and mini-split heat pumps; defaults to assuming a pan heater is present.
  - Allows optional EER2/EER inputs (`AnnualCoolingEfficiency[Units="EER2" or Units="EER"]/Value`) for central and mini-split air conditioners and heat pumps.
  - Deprecates SHR inputs (e.g., `CoolingSensibleHeatFraction`); they are no longer used.
  - Allows optional `extension/FanMotorType` input for central equipment; updates `FanPowerWattsPerCFM` defaults to be based on fan motor type.
  - Allows optional `extension/EquipmentType` inputs for central air conditioners and heat pumps; only used for SEER/SEER2, EER/EER2, and HSPF/HSPF2 conversions.
  - Allows optional design airflow rate inputs (`extension/HeatingDesignAirflowCFM` and `extension/CoolingDesignAirflowCFM`).
  - Updates default compressor lockout temperature for dual-fuel heat pumps from 25F to 40F.
  - Updates default design airflow rates to use cfm/ton assumptions rather than Manual S-based approach.
  - Updates defrost model to better account for load and energy use during defrost:
    - Allows optional defrost supplemental heat input (`extension/BackupHeatingActiveDuringDefrost`) for air-source heat pumps with integrated backup.
    - Deprecates `SimulationControl/AdvancedResearchFeatures/DefrostModelType` input.
  - Updates to detailed performance datapoints:
    - **Breaking change**: Updated requirements for allowed combinations of `CapacityDescription` and `OutdoorTemperature`; see the [documentation](https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#hpxml-hvac-detailed-perf-data) for more details.
    - Detailed performance datapoints can now be specified for single stage and two stage equipment too.
    - Adds more error-checking to ensure appropriate data inputs.
- Optional GSHP input `SimulationControl/AdvancedResearchFeatures/GroundToAirHeatPumpModelType` to choose "standard" (default) or "experimental"; "experimental" model better accounts for coil staging.
- Updates asset calculations for dishwashers, clothes washers, fixtures, and hot water waste per RESNET HERS Addenda 81 and 90f.
- Allows optional `ClothesDryer/DryingMethod` input to inform whether the appliance is vented or ventless.
- Infiltration improvements:
  - Improves defaults for `InfiltrationVolume`, `InfiltrationHeight`, and `AverageCeilingHeight`.
  - Allows optional `WithinInfiltrationVolume` input for conditioned basements; defaults to true.
- Electric vehicle enhancements:
  - Allows detailed modeling of electric vehicles (batteries and charging/discharging) using `Vehicles` as an alternative to the simple EV charging `PlugLoad`.
  - Adds EV driving unmet hours output.
  - Updates the default schedule for the EV charging `PlugLoad` to better reflect real-world hourly/monthly variation.
- Electric panel NEC load calculations (experimental research feature):
  - Allows optional `ElectricPanel` inputs for describing branch circuits and service feeders
  - Optionally reports breaker spaces and calculated loads for specified NEC calculation types (`SoftwareInfo/extension/ElectricPanelCalculations/ServiceFeeders/Type`)
- Allows requesting timeseries EnergyPlus output meters (e.g., `--hourly "MainsWater:Facility"`), similar to requesting EnergyPlus output variables.
- BuildResidentialScheduleFile measure:
  - Adds stochastic schedule generation for electric vehicle charging (using `Vehicles`).
  - Removes generation of stochastic schedules for building components not present in the HPXML file.
- Output updates:
  - **Breaking change**: Adds generator electricity produced to *total* fuel/energy use; previously it was only included in *net* values.
  - Adds optional new outputs for timeseries zone conditions (humidity ratio and relative humidity and dewpoint, radiant, and operative temperatures).
  - Adds new outputs for *net* peak electricity (summer/winter/annual); same as *total* peak electricity outputs but subtracts power produced by PV.
  - Avoids writing the E+ eplustbl.htm by default; use the debug flag to get it.
  - Deletes eplusout\*.msgpack files by default (run_simulation.rb only); use the debug flag to preserve them.
- Allows arbitrary columns to be present in a detailed schedule csv file with warning.

__Bugfixes__
- Fixes EPvalidator schematron file extension (.sch, not .xml).
- Fixes zero occupants specified for one unit in a whole MF building from being treated like zero occupants for every unit.
- Fixes using detailed schedules with higher resolution (e.g., 10-min data) than the simulation timestep (e.g., 60-min).
- Fixes possible heating/cooling spikes when using maximum power ratio detailed schedule for variable-speed HVAC systems.
- Fixes unavailable periods for two consecutive, but partial, days.
- Fixes error when specifying a glass block window without interior shading coefficients.
- Fixes battery charging/discharging not being included in peak electricity outputs.
- Fixes possible error if there's a surface w/ interior unconditioned space and exterior "other housing unit".
- Fixes default shading coefficients for window solar screens and solar film.
- Fixes `SolarFraction` documentation/error-checking for solar thermal systems; must now be <= 0.99.
- Fixes whole house fans so that they are unavailable during vacancies.
- Fixes error if there's a vented attic with zero roof pitch.
- Fixes tank loss coefficient when TankModelType=stratified for a conventional storage water heater.
- Fixes possibility of incorrect design duct load for really bad ducts (e.g., ducts with high surface area in a cold attic).
- Fixes duplicate emission end use rows for electricity in results_annual.csv.
- Adds error-checking to ensure TankModelType=stratified is not used with a non-electric water heater.
- BuildResidentialHPXML measure: Improves default duct areas/locations for 1-story buildings with a conditioned basement and ducts located in the attic.
- BuildResidentialHPXML measure: Fixes error when specifying a combi boiler as the water heater type and a *shared* boiler as the heating system type.
- BuildResidentialScheduleFile measure: Fixes out-of-sync shifting of occupancy and end use schedule resulting in activities even when there is no occupancy.
- BuildResidentialScheduleFile measure: Fixes a small bug in sink schedule generation resulting in more concentrated schedule.
- ReportUtilityBills measure: Apply fixed charges for fuels that are referenced by the HPXML file but consume no energy (e.g., gas heating system in Florida).

## OpenStudio-HPXML v1.9.1

__New Features__
- Now can be used to obtain ACCA Manual J approval; see the [OpenStudio-HPXML documentation](https://openstudio-hpxml.readthedocs.io/en/latest/intro.html#capabilities).

__Bugfixes__
- Fixes Manual J design load calculations for radiant floors.

## OpenStudio-HPXML v1.9.0

__New Features__
- Updates to OpenStudio 3.9/EnergyPlus 24.2/HPXML v4.1-rc1.
- Allows `Site/Address/ZipCode` to be provided instead of `ClimateandRiskZones/WeatherStation/extension/EPWFilePath`, in which case the closest TMY3 weather station will be automatically selected.
- Allows optional inputs for modeling skylight curbs and/or shafts.
- Allows modeling exterior horizontal insulation for a slab-on-grade foundation (or basement/crawlspace floor).
- Allows alternative infiltration input `AirInfiltrationMeasurement/LeakinessDescription`, in which the infiltration level is estimated using age of home, climate zone, foundation type, etc.
- Window shading enhancements:
  - Allows optional `InteriorShading/Type` input (blinds, shades, curtains) as a way to default summer/winter shading coefficients.
  - Allows optional `ExteriorShading/Type` input (trees, solar screens/films, etc.) as a way to default summer/winter shading coefficients.
  - Allows optional `InsectScreen` input.
- Adds optional `BuildingConstruction/UnitHeightAboveGrade` input for, e.g., apartment units of upper levels where the wind speed, and thus infiltration rate, is higher.
- Updates operational calculations (i.e., when `NumberofResidents` provided):
  - Updates hot water usage based on FSEC study.
  - Updates misc/tv plug load usage based on RECS 2020 data.
  - Updates relationship between number of bedrooms and number of occupants to use RECS 2020 instead of RECS 2015.
- Allows optional `HeatingCapacity` and `BackupHeatingCapacity` inputs for heat pump water heaters (HPWHs).
- Central Fan Integrated Supply (CFIS) mechanical ventilation enhancements:
  - Allows CFIS systems without automatic flow control of outdoor air (`CFISControls/HasOutdoorAirControl=false`).
  - Allows CFIS systems with no strategy to meet remainder of ventilation target (`CFISControls/AdditionalRuntimeOperatingMode="none"`).
  - Allows CFIS systems with supplemental fans that run simultaneously with the air handler (`CFISControls/extension/SupplementalFanRunsWithAirHandlerFan=true`).
  - Allows CFIS systems with timer control, in which ventilation operation occurs at a fixed interval (`CFISControls/extension/ControlType="timer"`).
  - Allows CFIS systems to be attached to ductless HVAC systems like PTHPs (requires using a DSE=1 distribution system, see documentation).
- HVAC Manual J design load and sizing calculations:
  - Adds optional `DistributionSystemType/AirDistribution/extension/ManualJInputs/BlowerFanHeatBtuh` input for HVAC equipment whose performance data has not been adjusted for blower heat.
  - Adds optional `DistributionSystemType/AirDistribution/extension/ManualJInputs/DefaultTableDuctLoad` input to use Manual J default duct factor tables instead of ASHRAE 152.
  - Adds optional `DistributionSystemType/HydronicDistribution/extension/ManualJInputs/HotWaterPipingBtuh` input to include hydronic distribution piping losses through unconditioned spaces.
  - Adds optional `HVACSizingControl/ManualJInputs/InfiltrationShieldingClass` input to specify wind shielding class for infiltration design load calculations.
  - Adds optional `HVACSizingControl/ManualJInputs/InfiltrationMethod` input to specify which method to use for infiltration design load calculations.
  - Updates heat pump HERS sizing methodology to better prevent unmet hours in warmer climates.
  - Misc Manual J design load calculation improvements.
  - **Breaking change**: Disaggregates "Walls" into "Above Grade Walls" and "Below Grade Walls" in results_design_load_details.csv output file.
  - Significant speed improvements when using optional space-level design load calculations.
- Advanced research features:
  - Optional input `SimulationControl/AdvancedResearchFeatures/OnOffThermostatDeadbandTemperature` to model on/off thermostat deadband with start-up degradation for single and two speed AC/ASHP systems and time-based realistic staging for two speed AC/ASHP systems.
  - Optional input `SimulationControl/AdvancedResearchFeatures/HeatPumpBackupCapacityIncrement` to model multi-stage electric backup coils with time-based staging.
  - Maximum power ratio detailed schedule for variable-speed HVAC systems can now be used with `NumberofUnits` dwelling unit multiplier.
- BuildResidentialHPXML measure:
  - **Breaking change**: Replaced `slab_under_width` and `slab_perimeter_depth` arguments with `slab_under_insulation_width` and `slab_perimeter_insulation_depth`
  - **Breaking change**: Replaced `schedules_vacancy_periods`, `schedules_power_outage_periods`, and `schedules_power_outage_periods_window_natvent_availability` arguments with `schedules_unavailable_period_types`, `schedules_unavailable_period_dates`, and `schedules_unavailable_period_window_natvent_availabilities`; this improves flexibility for handling more unavailable period types.
- Utility bill calculations:
  - Allows OpenEI URDB tariffs that have $/day fixed charges.
  - Updates `openei_rates.zip` with the latest residential utility rates from the [OpenEI U.S. Utility Rate database](https://apps.openei.org/USURDB/).
- Adds a warning if the sum of supply/return duct leakage to outside values is very high.

__Bugfixes__
- Prevents possible error if only one of FracSensible/FracLatent are provided for a PlugLoad or FuelLoad; **Breaking change**: FracSensible and FracLatent must now be both be provided or omitted.
- Prevents possible error when using multiple `Attic`/`Foundation` elements for the same attic/foundation type.
- Adds error-checking for `NumberofConditionedFloorsAboveGrade`=0, which is not allowed per the documentation.
- Fixes utility bill calculations if there is battery storage or a generator.
- BuildResidentialScheduleFile measure: Fixes possible divide by zero error during generation of stochastic clothes washer and dishwasher schedules.
- Allows negative values for `Building/Site/Elevation`.
- Fixes lower element height for a water heater using the advanced `WaterHeatingSystem/extension/TankModelType=stratified`.
- Fixes possible error for a combi boiler system.
- Fixes error if modeling a ground-to-air heat pump with a separate backup heating system.
- Fixes default CFIS fan power during ventilation only mode.
- Fixes a bug that potentially oversizes heat pumps when detailed performance capacity fractions are provided.
- For a CFIS system with a supplemental fan, fixes supplemental fan runtime when using sub-hourly timesteps.
- Fixes GSHP rated fan/pump powers in net to gross calculations and improves default modeled pump power (W/ton).

## OpenStudio-HPXML v1.8.1

__Bugfixes__
- Fixes cfm/ton restriction from incorrectly applying to furnace heating airflow rate.

## OpenStudio-HPXML v1.8.0

__New Features__
- Updates to OpenStudio 3.8/EnergyPlus 24.1/HPXML v4.0-rc4.
- Adds BPI-2400 HPXML test files and results; see [Testing Framework](https://openstudio-hpxml.readthedocs.io/en/latest/testing_framework.html) for more information.
- Updates per ANSI/RESNET/ICC 301-2022 w/ Addendum C:
  - **Breaking change**: For shared water heaters, `NumberofUnitsServed` is replaced by `extension/NumberofBedroomsServed`.
  - **Breaking change**: For shared hot water recirculation systems, `NumberofUnitsServed` is replaced by `NumberofBedroomsServed`.
  - Allows shared batteries (batteries serving multiple dwelling units).
  - Updated default CFIS fan power to 0.58 W/cfm.
  - Removed natural ventilation availability RH constraint; HR constraint remains.
  - Refrigerator and freezer schedules may now be based on ambient temperature using new `TemperatureScheduleCoefficients` and `ConstantScheduleCoefficients` inputs; the refrigerator default schedule uses these new inputs.
  - Default schedules updated for cooking ranges, lighting, plug loads, televisions, hot water recirculation pumps, and occupant heat gains.
  - Adds schedule inputs for hot water recirculation pumps and general water use internal gains.
  - Updated water heater installation default location.
  - Updated calculation of hot water piping length for buildings with both conditioned and unconditioned basements to avoid double counting.
  - Updated how imbalanced infiltration and mechanical ventilation are combined on an hourly basis.
  - Updated handling of duct leakage imbalance induced infiltration.
  - Small change to default flow rate for imbalanced mechanical ventilation systems.
  - Updated window default interior shade coefficients to be calculated based on SHGC.
  - `AverageCeilingHeight` now used in natural ACH/CFM infiltration calculations.
- **Breaking change**: Replaces `BuildingSummary/Site/extension/GroundConductivity` with `BuildingSummary/Site/Soil/Conductivity`.
- **Breaking change**: Modeling whole SFA/MF buildings is now specified using a `SoftwareInfo/extension/WholeSFAorMFBuildingSimulation=true` element instead of `building-id=ALL` argument.
- **Breaking change**: Skylights attached to roofs of attics (e.g., with shafts or sun tunnels) must include the `Skylight/AttachedToFloor` element.
- Air source heat pump/air conditioner enhancements:
  - Adds heat pump backup autosizing methodology input (`HeatPumpBackupSizingMethodology`) with choices of "emergency" and "supplemental".
  - Allows autosizing with detailed performance data inputs for variable-speed HVAC systems using `CapacityFractionOfNominal`.
  - Now defaults to -20F for `CompressorLockoutTemperature` for variable-speed heat pump systems.
- Ground source heat pump enhancements:
  - Allows optional detailed inputs related to geothermal loop (`HVACPlant/GeothermalLoop`).
  - Allows optional ground diffusivity input.
  - Updates to using G-Functions from the [G-Function Library for Modeling Vertical Bore Ground Heat Exchanger](https://gdr.openei.org/submissions/1325).
  - Updated heating/cooling performance curves to reflect newer equipment.
  - Adds geothermal loop outputs (number/length of boreholes) to annual results output file.
- HVAC Manual J design load and sizing calculations:
  - **Breaking change**: Outputs for "Infiltration/Ventilation" category disaggregated into "Infiltration" and "Ventilation".
  - **Breaking change**: Outputs for "Windows" category no longer includes AED excursion; now a separate "AED Excursion" category.
  - Allows optional `HeatingAutosizingFactor`, `CoolingAutosizingFactor`, `BackupHeatingAutosizingFactor` inputs to scale HVAC capacities for autosized equipment.
  - Allows optional `HeatingAutosizingLimit`, `CoolingAutosizingLimit`, `BackupHeatingAutosizingLimit` inputs to set maximum HVAC capacities ceiling for autosized equipment.
  - Allows optional zone-level and space-level design load calculations using HPXML `Zones/Zone[ZoneType="conditioned"]/Spaces/Space` elements.
  - Allows additional outdoor design condition inputs: `DailyTemperatureRange` and `HumidityDifference`.
  - Adds a new detailed output file with block/space load details by surface, AED curves, etc.
  - Miscellaneous improvements.
- Allows optional `Ducts/DuctShape` and `Ducts/DuctFractionRectangular` inputs, which affect duct effective R-value used for modeling.
- Adds optional `Slab/extension/GapInsulationRValue` input for cases where a slab has horizontal (under slab) insulation.
- Allows radiant barriers for additional locations (attic gable walls and floor); reduced emissivity due to dust assumed for radiant barriers on attic floor.
- Adds window and skylight `GlassType` options of "low-e, high-solar-gain" and "low-e, low-solar-gain"; updates U-factor/SHGC lookup tables.
- Updates default temperature capacitance multiplier from 1 to 7, an average value found in the literature when calibrating timeseries EnergyPlus indoor temperatures to field data.
- Allows optional building site inputs (`GeoLocation/Latitude`, `GeoLocation/Longitude`, `Elevation`); useful when located far from, or at a very different elevation than, the EPW weather station.
- Updates default `ShieldingofHome` to be "well-shielded" for single-family attached and multifamily dwelling units.
- Improves heating/cooling component loads; for timesteps where there is no heating/cooling load, assigns heat transfer to heating or cooling by comparing indoor temperature to the average of heating/cooling setpoints.
- Adds net energy and net electricity timeseries output columns even when there is no PV or generator.
- Allow alternative label energy use (W) input for ceiling fans.
- Replaced state-average default fuel prices with EIA State Energy Data System (SEDS) prices.
- Adds more error-checking for inappropriate inputs (e.g., HVAC SHR=0 or clothes washer IMEF=0).
- Updates to run_simulation.rb script:
  - Allows requesting timeseries outputs with different frequencies (e.g., `--hourly enduses --monthly temperatures`).
  - **Breaking change**: Deprecates `--add-timeseries-output-variable`; EnergyPlus output variables can now be requested like other timeseries categories (using e.g. `--hourly 'Zone People Occupant Count'`).
  - Adds an optional `--skip-simulation` argument that allows skipping the EnergyPlus simulation.
- BuildResidentialHPXML measure:
  - **Breaking change**: Replaces `roof_radiant_barrier`/`roof_radiant_barrier_grade` arguments with `radiant_barrier_attic_location`/`radiant_barrier_grade`.
  - Allows specifying number of bedrooms served by the water heater which is used for apportioning tank losses; **Breaking change**: Replaces `water_heater_num_units_served` with `water_heater_num_bedrooms_served`.
  - Allows defining multiple unavailable periods; **Breaking change**: arguments renamed to `schedules_vacancy_periods`, `schedules_power_outage_periods`, and `schedules_power_outage_periods_window_natvent_availability`.
  - Adds detailed performance data inputs for variable-speed air source HVAC systems.
  - Adds heat pump backup sizing methodology input.
  - Add soil and moisture type arguments (for determining ground conductivity and diffusivity) and optional geothermal loop arguments for ground source heat pumps.
  - The "Geometry: Building Number of Units" input is now written to the HPXML `NumberofUnitsInBuilding` element.
  - Adds a blower fan efficiency input for specifying fan power W/cfm at maximum speed.
- BuildResidentialScheduleFile measure:
  - Allows appending columns to an existing CSV file rather than overwriting.
  - Other plug load schedules now use Other schedule fractions per ANSI/RESNET/ICC 301-2022 Addendum C.
  - TV plug load schedules now use TV schedule fractions from the American Time Use Survey and monthly multipliers from the 2010 Building America Analysis Spreadsheets.
  - Ceiling fan schedules now use ceiling fan schedule fractions and monthly multipliers from ANSI/RESNET/ICC 301-2022 Addendum C.
- ReportUtilityBills measure:
  - Adds new optional arguments for registering (with the OpenStudio runner) annual or monthly utility bills.
- Advanced research features:
  - **Breaking change**: Replaces `SimulationControl/TemperatureCapacitanceMultiplier` with `SimulationControl/AdvancedResearchFeatures/TemperatureCapacitanceMultiplier`.
  - Allows an optional input `SimulationControl/AdvancedResearchFeatures/DefrostModelType` for heat pump advanced defrost model.
  - Adds maximum power ratio detailed schedule for variable-speed HVAC systems to model shedding controls per [AHRI 1380](https://www.ahrinet.org/search-standards/ahri-1380-i-p-demand-response-through-variable-capacity-hvac-systems-residential-and-small).

__Bugfixes__
- Fixes error if using AllowIncreasedFixedCapacities=true w/ HP detailed performance data.
- Prevents mains water temperature from going below freezing (0 C).
- Fixes error if HPXML has emissions scenario and abbreviated run period.
- Fixes detailed schedule error-checking where schedules with MAX < 1 were incorrectly allowed.
- Fixes error if using MF space types (e.g., "other heated space") and the building has no HVAC equipment.
- Fixes `ManualJInputs/HumiditySetpoint` not being used in the design load calculation.
- Fixes possible EnergyPlus error when a `Slab` representing a crawlspace dirt floor has perimeter or under slab insulation.
- Prevents errors due to incorrect `Floor/FloorOrCeiling` input; issues a warning when detected.
- Apportion shared water heater tank losses for HPWHs and combi systems.
- Fixes buried duct effective R-values.
- Fixes shared boiler default location (which could result in assuming there's a flue in conditioned space impacting infiltration).
- Fixes timeseries hot water energy consumption adjustment lag (associated with hot water distribution).
- Fixes possibility of negative timeseries delivered loads when there is a dehumidifier.

## OpenStudio-HPXML v1.7.0

__New Features__
- Updates to OpenStudio 3.7.0/EnergyPlus 23.2.
- **Breaking change**: Updates to HPXML v4.0-rc2:
  - HPXML namespace changed from http://hpxmlonline.com/2019/10 to http://hpxmlonline.com/2023/09.
  - Replaces "living space" with "conditioned space", which better represents what is modeled.
  - Replaces `HotTubs/HotTub` with `Spas/PermanentSpa`.
  - Replaces `PortableHeater` and `FixedHeater` with `SpaceHeater`.
- Allows simulating whole multifamily (MF) buildings in a single combined simulation:
  - **Breaking change**: Multiple elements move from `SoftwareInfo/extension` to `BuildingDetails/BuildingSummary/extension` to allow variation across units:
    - `HVACSizingControl`
    - `ShadingControl`
    - `SchedulesFilePath`
    - `NaturalVentilationAvailabilityDaysperWeek`
  - Allows `NumberofUnits` to be used as a multiplier on dwelling unit simulation results to reduce simulation runtime.
  - See the [OpenStudio-HPXML documentation](https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#whole-sfa-mf-buildings) for more detail.
- HVAC modeling updates:
  - Updated assumptions for variable-speed air conditioners, heat pumps, and mini-splits based on NEEP data. Expect results to change, potentially significantly so depending on the scenario.
  - Allows detailed heating and cooling performance data (min/max COPs and capacities at different outdoor temperatures) for variable-speed systems.
  - Updates deep ground temperatures (used for modeling ground-source heat pumps) using L. Xing's simplified design model (2014).
  - Replaces inverse calculations, used to calculate COPs from rated efficiencies, with regressions for single/two-speed central ACs and ASHPs.
- Output updates:
  - **Breaking change**: "Hot Tub" outputs renamed to "Permanent Spa".
  - Adds "Peak Electricity: Annual Total (W)" output.
  - Adds battery resilience hours output; allows requesting timeseries output.
  - ReportUtilityBills measure: Allows reporting monthly utility bills in addition to (or instead of) annual bills.
- BuildResidentialHPXML measure:
  - Allow duct area fractions (as an alternative to duct areas in ft^2).
  - Allow duct locations to be provided while defaulting duct areas (i.e., without providing duct area/fraction inputs).
  - Add generic "attic" and "crawlspace" location choices for supply/return ducts, water heater, and battery.
  - Always validate the HPXML file before applying defaults and only optionally validate the final HPXML file.
- Adds manufactured home belly as a foundation type and allows modeling ducts in a manufactured home belly.
- Battery losses now split between charging and discharging.
- Interior/exterior window shading multipliers are now modeled using the EnergyPlus incident solar multiplier.
- Allows `WaterFixture/FlowRate` as an alternative to `LowFlow`; hot water credit is now calculated based on fraction of low flow fixtures.
- Allows above-grade basements/crawlspaces defined solely with Wall (not FoundationWall) elements.
- Updates to 2022 EIA energy costs.
- Added README.md documentation for all OpenStudio measures.

__Bugfixes__
- Fixes battery resilience output to properly incorporate battery losses.
- Fixes lighting multipliers not being applied when kWh/yr inputs are used.
- Fixes running detailed schedules with mixed timesteps (e.g., hourly heating/cooling setpoints and 15-minutely miscellaneous plug load schedules).
- Fixes calculation of utility bill fixed costs for simulations with abbreviated run periods.
- Fixes error if heat pump `CompressorLockoutTemperature` == `BackupHeatingLockoutTemperature`.
- Fixes possible "Electricity category end uses do not sum to total" error for a heat pump w/o backup.
- Fixes ground source heat pump fan/pump adjustment to rated efficiency.
- Fixes error if conditioned basement has `InsulationSpansEntireSlab=true`.
- Fixes ReportSimulationOutput outputs for the Parametric Analysis Tool (PAT).
- Fixes missing radiation exchange between window and sky when an interior/exterior window shading multiplier less than 1 exists.
- Fixes monthly shallow ground temperatures (used primarily in HVAC autosizing) for the southern hemisphere.
- Various HVAC sizing bugfixes and improvements.
- Fixes low-speed heating COPs for some two-speed ASHPs and cooling COPs for some single-speed ACs/HPs.
- BuildResidentialHPXML measure: Fixes air distribution CFA served when there is not a central system that meets 100% of the load.

## OpenStudio-HPXML v1.6.0

__New Features__
- Updates to OpenStudio 3.6.1/EnergyPlus 23.1.
- **Breaking change**: Updates to newer proposed HPXML v4.0:
  - Replaces `VentilationFan/Quantity` and `CeilingFan/Quantity` with `Count`.
  - Replaces `PVSystem/InverterEfficiency` with `PVSystem/AttachedToInverter` and `Inverter/InverterEfficiency`.
  - Replaces `WaterHeatingSystem/extension/OperatingMode` with `WaterHeatingSystem/HPWHOperatingMode` for heat pump water heaters.
- Output updates:
  - **Breaking change**: Adds `End Use: Heating Heat Pump Backup Fans/Pumps` (disaggregated from `End Use: Heating Fans/Pumps`).
  - **Breaking change**: Replaces `Component Load: Windows` with `Component Load: Windows Conduction` and `Component Load: Windows Solar`.
  - **Breaking change**: Replaces `Component Load: Skylights` with `Component Load: Skylights Conduction` and `Component Load: Skylights Solar`.
  - **Breaking change**: Adds `Component Load: Lighting` (disaggregated from `Component Load: Internal Gains`).
  - **Breaking change**: Adds "net" values for emissions; "total" values now exclude generation (e.g., PV).
  - Adds `Load: Heating: Heat Pump Backup` (heating load delivered by heat pump backup systems).
  - Adds `System Use` outputs (end use outputs for each heating, cooling, and water heating system); allows requesting timeseries output.
  - All annual load outputs are now provided as timeseries outputs; previously only "Delivered" loads were available.
  - Peak summer/winter electricity outputs are now based on Jun/July/Aug and Dec/Jan/Feb months, not HVAC heating/cooling operation.
  - Allows specifying the number of decimal places for timeseries output.
  - Msgpack outputs are no longer rounded (since there is no file size penalty to storing full precision).
  - Annual emissions and utility bills now include all fuel/end uses, even if zero.
  - ReportSimulationOutput measure: Allows disabling individual annual output sections.
- **Breaking change**: Deprecates `OccupancyCalculationType` ("asset" or "operational").
   - If `NumberofResidents` not provided, an *asset* calculation is performed assuming standard occupancy per ANSI/RESNET/ICC 301.
   - If `NumberofResidents` is provided, an *operational* calculation is performed using a relationship between #Bedrooms and #Occupants from RECS 2015.
- Heat pump enhancements:
  - Allows `HeatingCapacityRetention[Fraction | Temperature]` inputs to define cold-climate performance; like `HeatingCapacity17F` but can apply to autosized systems and can use a user-specified temperature.
  - Default mini-split heating capacity retention updated from 0.4 to 0.5 (at 5 deg-F).
  - Allows `CompressorLockoutTemperature` as an optional input to control the minimum temperature the compressor can operate at.
  - Defaults for `CompressorLockoutTemperature`: 25F for dual-fuel, -20F for mini-split, 0F for all other heat pumps.
  - Defaults for `BackupHeatingLockoutTemperature`: 50F for dual-fuel, 40F for all other heat pumps.
  - Provides a warning if `BackupHeatingSwitchoverTemperature` or `BackupHeatingLockoutTemperature` are low and may cause unmet hours.
  - Autosizing is no longer all-or-none; backup heating can be autosized (defaulted) while specifying the heat pump capacities, or vice versa.
  - Allows `extension/CrankcaseHeaterPowerWatts` as an optional input; defaults to 50 W for central HPs/ACs and mini-splits.
  - Increased consistency between variable-speed central HP and mini-split HP models for degradation coefficients, gross SHR calculations, etc.
- Infiltration changes:
  - **Breaking change**: Infiltration for SFA/MF dwelling units must include `TypeOfInfiltrationLeakage` ("unit total" or "unit exterior only").
  - **Breaking change**: Replaces `BuildingConstruction/extension/HasFlueOrChimney` with `AirInfiltration/extension/HasFlueOrChimneyInConditionedSpace`; defaults now incorporate HVAC/water heater location.
  - Allows infiltration to be specified using `CFMnatural` or `EffectiveLeakageArea`.
- Lighting changes:
  - LightingGroups can now be specified using kWh/year annual consumption values as an alternative to fractions of different lighting types.
  - LightingGroups for interior, exterior, and garage are no longer required; if not provided, these lighting uses will not be modeled.
- HVAC sizing enhancements:
  - Allows optional inputs under `HVACSizingControl/ManualJInputs` to override Manual J defaults for HVAC autosizing calculations.
  - Updates to better align various default values and algorithms with Manual J.
  - Updates design load calculations to handle conditioned basements with insulated slabs.
- Duct enhancements:
  - Allows modeling ducts buried in attic loose-fill insulation using `Ducts/DuctBuriedInsulationLevel`.
  - Allows specifying `Ducts/DuctEffectiveRValue`, the value that will be used in the model, though its use is not recommended.
- Allows modeling a pilot light for non-electric heating systems (furnaces, stoves, boilers, and fireplaces).
- Allows summer vs winter shading seasons to be specified for windows and skylights.
- Allows defining one or more `UnavailablePeriods` (e.g., occupant vacancies or power outage periods).
- Stochastic schedules for garage lighting and TV plug loads now use interior lighting and miscellaneous plug load schedules, respectively.
- Performance improvement for HPXML files w/ large numbers of `Building` elements.
- Weather cache files (\*foo-cache.csv) are no longer used/needed.

__Bugfixes__
- Fixes `BackupHeatingSwitchoverTemperature` for a heat pump w/ *separate* backup system; now correctly ceases backup operation above this temperature.
- Fixes error if calculating utility bills for an all-electric home with a detailed JSON utility rate.
- Stochastic schedules now excludes columns for end uses that are not stochastically generated.
- Fixes operational calculation when the number of residents is set to zero.
- Fixes possible utility bill calculation error for a home with PV using a detailed electric utility rate.
- Fixes defaulted mechanical ventilation flow rate for SFA/MF buildings, with respect to infiltration credit.
- HPXML files w/ multiple `Building` elements now only show warnings for the single `Building` being simulated.
- Adds a warning for SFA/MF dwelling units without at least one attached wall/ceiling/floor surface.
- Various fixes for window/skylight/duct design loads for Manual J HVAC autosizing calculations.
- Ensure that ductless HVAC systems do not have a non-zero airflow defect ratio specified.
- Fixes possible "A neighbor building has an azimuth (XX) not equal to the azimuth of any wall" for SFA/MF units with neighboring buildings for shade.
- Fixes reported loads when no/partial HVAC system (e.g., room air conditioner that meets 30% of the cooling load).

## OpenStudio-HPXML v1.5.1

__New Features__
- When `Battery/Location` not provided, now defaults to garage if present, otherwise outside.
- BuildResidentialScheduleFile measure:
  - Allows requesting a subset of end uses (columns) to be generated.

__Bugfixes__
- Fixes total/net electricity timeseries outputs to include battery charging/discharging energy.
- Fixes error when a non-electric water heater has jacket insulation and the UEF metric is used.

## OpenStudio-HPXML v1.5.0

__New Features__
- Updates to OpenStudio 3.5.0/EnergyPlus 22.2.
- **Breaking change**: Updates to newer proposed HPXML v4.0:
  - Replaces `FrameFloors/FrameFloor` with `Floors/Floor`.
  - `Floor/FloorType` (WoodFrame, StructuralInsulatedPanel, SteelFrame, or SolidConcrete) is a required input.
  - All `Ducts` must now have a `SystemIdentifier`.
  - Replaces `WallType/StructurallyInsulatedPanel` with `WallType/StructuralInsulatedPanel`.
  - Replaces `SoftwareInfo/extension/SimulationControl/DaylightSaving/Enabled` with `Building/Site/TimeZone/DSTObserved`.
  - Replaces `StandbyLoss` with `StandbyLoss[Units="F/hr"]/Value` for an indirect water heater.
  - Replaces `BranchPipingLoopLength` with `BranchPipingLength` for a hot water recirculation system.
  - Replaces `Floor/extension/OtherSpaceAboveOrBelow` with `Floor/FloorOrCeiling`.
  - For PTAC with heating, replaces `HeatingSystem` of type PackagedTerminalAirConditionerHeating with `CoolingSystem/IntegratedHeating*` elements.
- **Breaking change**: Now performs full HPXML XSD schema validation (previously just limited checks); yields runtime speed improvements.
- **Breaking change**: HVAC/DHW equipment efficiencies can no longer be defaulted (e.g., based on age of equipment); they are now required.
- **Breaking change**: Deprecates ReportHPXMLOutput measure; HVAC autosized capacities & design loads moved to `results_annual.csv`.
- **Breaking change**: BuildResidentialHPXML measure: Replaces arguments using 'auto' for defaults with optional arguments of the appropriate data type.
- Utility bill calculations:
  - **Breaking change**: Removes utility rate and PV related arguments from the ReportUtilityBills measure in lieu of HPXML file inputs.
  - Allows calculating one or more utility bill scenarios (e.g., net metering vs feed-in tariff compensation types for a simulation with PV).
  - Adds detailed calculations for tiered, time-of-use, or real-time pricing electric rates using OpenEI tariff files.
- Lithium ion battery:
  - Allows detailed charging/discharging schedules via CSV files.
  - Allows setting round trip efficiency.
  - **Breaking change**: Lifetime model is temporarily disabled; `Battery/extension/LifetimeModel` is not allowed.
- Allows SEER2/HSPF2 efficiency types for central air conditioners and heat pumps.
- Allows setting the natural ventilation availability (days/week that operable windows can be opened); default changed from 7 to 3 (M/W/F).
- Allows specifying duct surface area multipliers.
- Allows modeling CFIS ventilation systems with supplemental fans.
- Allows shared dishwasher/clothes washer to be attached to a hot water distribution system instead of a single water heater.
- Allows heating/cooling seasons that don't span the entire year.
- Allows modeling room air conditioners with heating or reverse cycle.
- Allows setting the ground soil conductivity used for foundation heat transfer and ground source heat pumps.
- Allows setting the EnergyPlus temperature capacitance multiplier.
- EnergyPlus modeling changes:
  - Switches Kiva foundation model timestep from 'Hourly' to 'Timestep'; small increase in runtime for sub-hourly simulations.
  - Improves Kiva foundation model heat transfer by providing better initial temperature assumptions based on foundation type and insulation levels.
- Annual/timeseries outputs:
  - Allows timeseries timestamps to be start or end of timestep convention; **Breaking change**: now defaults to start of timestep.
  - Adds annual emission outputs disaggregated by end use; timeseries emission outputs disaggregated by end use can be requested.
  - Allows generating timeseries unmet hours for heating and cooling.
  - Allows CSV timeseries output to be formatted for use with the DView application.
  - Adds heating/cooling setpoints to timeseries outputs when requesting zone temperatures.
  - Disaggregates Battery outputs from PV outputs.
  - Design temperatures, used to calculate design loads for HVAC equipment autosizing, are now output in `in.xml` and `results_annual.csv`.

__Bugfixes__
- Fixes possible incorrect autosizing of heat pump *separate* backup systems with respect to duct loads.
- Fixes incorrect autosizing of heat pump *integrated* backup systems if using MaxLoad/HERS sizing methodology and cooling design load exceeds heating design load.
- Fixes heating (or cooling) setpoints affecting the conditioned space temperature outside the heating (or cooling) season.
- Fixes handling non-integer number of occupants when using the stochastic occupancy schedule generator.
- Fixes units for Peak Loads (kBtu/hr, not kBtu) in annual results file.
- Fixes possible output error for ground source heat pumps with a shared hydronic circulation loop.
- Provides an error message if the EnergyPlus simulation used infinite energy.
- Fixes zero energy use for a ventilation fan w/ non-zero fan power and zero airflow rate.
- Fixes excessive heat transfer when foundation wall interior insulation does not start from the top of the wall.
- Fixes how relative paths are treated when using an OpenStudio Workflow.
- Fixes possible simulation error if a slab has an ExposedPerimeter near zero.
- Fixes possible "Could not identify surface type for surface" error.
- Fixes possible ruby error when defaulting water heater location.
- Battery round trip efficiency now correctly affects results.
- BuildResidentialHPXML measure:
  - Fixes aspect ratio convention for single-family attached and multifamily dwelling units.

## OpenStudio-HPXML v1.4.0

__New Features__
- Updates to OpenStudio 3.4.0/EnergyPlus 22.1.
- High-level optional `OccupancyCalculationType` input to specify operational vs asset calculation. Defaults to asset. If operational, `NumberofResidents` is required.
- Allows calculating one or more emissions scenarios (e.g., high renewable penetration vs business as usual) for different emissions types (e.g., CO2e).
- New ReportUtilityBills reporting measure: adds a new results_bills.csv output file to summarize calculated utility bills.
- Switches from EnergyPlus SQL output to MessagePack output for faster performance and reduced file sizes when requesting timeseries outputs.
- New heat pump capabilities:
  - **Breaking change**: Replaces the `UseMaxLoadForHeatPumps` sizing option with `HeatPumpSizingMethodology`, which has three choices:
    - `ACCA`: nominal capacity sized per ACCA Manual J/S based on cooling design loads, with some oversizing allowances for larger heating design loads.
    - `HERS` (default): nominal capacity sized equal to the larger of heating/cooling design loads.
    - `MaxLoad`: nominal capacity sized based on the larger of heating/cooling design loads, while taking into account the heat pump's capacity retention at the design temperature.
  - Allows the separate backup system to be a central system (e.g., central furnace w/ ducts). Previously only non-central system types were allowed.
  - Heat pumps with switchover temperatures are now autosized by taking into account the switchover temperature, if higher than the heating design temperature.
  - Allows `BackupHeatingLockoutTemperature` as an optional input to control integrated backup heating availability during, e.g., a thermostat heating setback recovery event; defaults to 40F.
- New water heating capabilities:
  - Allows conventional storage tank water heaters to use a stratified (rather than mixed) tank model via `extension/TankModelType`; higher precision but runtime penalty. Defaults to mixed.
  - Allows operating mode (standard vs heat pump only) for heat pump water heaters (HPWHs) via `extension/OperatingMode`. Defaults to standard.
  - Updates combi boiler model to be simpler, faster, and more robust by using separate space/water heating plant loops and boilers.
- New capabilities for hourly/sub-hourly scheduling via schedule CSV files:
  - Detailed HVAC and water heater setpoints.
  - Detailed heat pump water heater operating modes.
- EnergyPlus modeling changes:
  - Switches from ScriptF to CarrollMRT radiant exchange algorithm.
  - Updates HVAC fans to use fan power law (cubic relationship between fan speed and power).
  - Updates HVAC rated fan power assumption per ASHRAE 1449-RP.
- Allows specifying a `StormWindow` element for windows/skylights; U-factors and SHGCs are automatically adjusted.
- Allows an optional `AirInfiltrationMeasurement/InfiltrationHeight` input.
- Allows an optional `Battery/UsableCapacity` input; now defaults to 0.9 x NominalCapacity (previously 0.8).
- For CFIS systems, allows an optional `extension/VentilationOnlyModeAirflowFraction` input to address duct losses during ventilation only mode.
- **Breaking change**: Each `VentilationFan` must have one (and only one) `UsedFor...` element set to true.
- BuildResidentialHPXML measure:
  - **Breaking change**: Changes the zip code argument name to `site_zip_code`.
  - Adds optional arguments for schedule CSV files, HPWH operating mode, water heater tank model, storm windows, heat pump lockout temperature, battery usable capacity, and emissions scenarios.
  - Adds support for ambient foundations for single-family attached and apartment units.
  - Adds support for unconditioned attics for apartment units.
  - Adds an optional argument to store additional custom properties in the HPXML file.
  - Adds an optional argument for whether the HPXML file is written with default values applied; defaults to false.
  - Adds an optional argument for whether the HPXML file is validated; defaults to false.
- ReportSimulationOutput measure:
  - **Breaking change**: New "End Use: \<Fuel\>: Heating Heat Pump Backup" output, disaggregated from "End Use: \<Fuel\>: Heating".
  - Adds "Energy Use: Total" and "Energy Use: Net" columns to the annual results output file; allows timeseries outputs.
  - Adds a "Fuel Use: Electricity: Net" timeseries output column for homes with electricity generation.
  - Adds optional argument for requesting timeseries EnergyPlus output variables.
  - Adds ability to include `TimeDST` and/or `TimeUTC` timestamp column(s) in results_timeseries.csv.
  - Timestamps in results_timeseries.csv are output in ISO 8601 standard format.
  - Allows user-specified annual/timeseries output file names.
- ReportHPXMLOutput measure:
  - Adds "Enclosure: Floor Area Foundation" output row in results_hpxml.csv.
- Adds support for shared hot water recirculation systems controlled by temperature.
- Relaxes requirement for `ConditionedFloorAreaServed` for air distribution systems; now only needed if duct surface areas not provided.
- Allows MessagePack annual/timeseries output files to be generated instead of CSV/JSON.

__Bugfixes__
- Adds more stringent limits for `AirflowDefectRatio` and `ChargeDefectRatio` (now allows values from 1/10th to 10x the design value).
- Catches case where leap year is specified but weather file does not contain 8784 hours.
- Fixes possible HVAC sizing error if design temperature difference (TD) is negative.
- Fixes an error if there is a pool or hot tub, but the pump `Type` is set to "none".
- Adds more decimal places in output files as needed for simulations with shorter timesteps and/or abbreviated run periods.
- Timeseries output fixes: some outputs off by 1 hour; possible negative combi boiler values.
- Fixes range hood ventilation interaction with infiltration to take into account the location of the cooking range.
- Fixes possible EMS error for ventilation systems with low (but non-zero) flow rates.
- Fixes documentation for `Overhangs/Depth` inputs; units should be ft and not inches.
- The `WaterFixturesUsageMultiplier` input now also applies to general water use internal gains and recirculation pump energy (for some control types).
- BuildResidentialHPXML measure:
  - Fixes units for "Cooling System: Cooling Capacity" argument (Btu/hr, not tons).
  - Fixes incorrect outside boundary condition for shared gable walls of cathedral ceilings, now set to adiabatic.

## OpenStudio-HPXML v1.3.0

__New Features__
- Updates to OpenStudio 3.3.0/EnergyPlus 9.6.0.
- **Breaking change**: Replaces "Unmet Load" outputs with "Unmet Hours".
- **Breaking change**: Renames "Load: Heating" and "Peak Load: Heating" (and Cooling) outputs to include "Delivered".
- **Breaking change**: Any heat pump backup heating requires `HeatPump/BackupType` ("integrated" or "separate") to be specified.
- **Breaking change**: For homes with multiple PV arrays, all inverter efficiencies must have the same value.
- **Breaking change**: HPXML schema version must now be '4.0' (proposed).
  - Moves `ClothesDryer/extension/IsVented` to `ClothesDryer/Vented`.
  - Moves `ClothesDryer/extension/VentedFlowRate` to `ClothesDryer/VentedFlowRate`.
  - Moves `FoundationWall/Insulation/Layer/extension/DistanceToTopOfInsulation` to `FoundationWall/Insulation/Layer/DistanceToTopOfInsulation`.
  - Moves `FoundationWall/Insulation/Layer/extension/DistanceToBottomOfInsulation` to `FoundationWall/Insulation/Layer/DistanceToBottomOfInsulation`.
  - Moves `Slab/PerimeterInsulationDepth` to `Slab/PerimeterInsulation/Layer/InsulationDepth`.
  - Moves `Slab/UnderSlabInsulationWidth` to `Slab/UnderSlabInsulation/Layer/InsulationWidth`.
  - Moves `Slab/UnderSlabInsulationSpansEntireSlab` to `Slab/UnderSlabInsulation/Layer/InsulationSpansEntireSlab`.
- Initial release of BuildResidentialHPXML measure, which generates an HPXML file from a set of building description inputs.
- Expanded capabilities for scheduling:
  - Allows modeling detailed occupancy via a schedule CSV file.
  - Introduces a measure for automatically generating detailed smooth/stochastic schedule CSV files.
  - Expands simplified weekday/weekend/monthly schedule inputs to additional building features.
  - Allows `HeatingSeason` & `CoolingSeason` to be specified for defining heating and cooling equipment availability.
- Adds a new results_hpxml.csv output file to summarize HPXML values (e.g., surface areas, HVAC capacities).
- Allows modeling lithium ion batteries.
- Allows use of `HeatPump/BackupSystem` for modeling a standalone (i.e., not integrated) backup heating system.
- Allows conditioned crawlspaces to be specified; modeled as crawlspaces that are actively maintained at setpoint.
- Allows non-zero refrigerant charge defect ratios for ground source heat pumps.
- Expands choices allowed for `Siding` (Wall/RimJoist) and `RoofType` (Roof) elements.
- Allows "none" for wall/rim joist siding.
- Allows interior finish inputs (e.g., 0.5" drywall) for walls, ceilings, and roofs.
- Allows specifying the foundation wall type (e.g., solid concrete, concrete block, wood, etc.).
- Allows additional fuel types for generators.
- Switches to the EnergyPlus Fan:SystemModel object for all HVAC systems.
- Introduces a small amount of infiltration for unvented spaces.
- Updates the assumption of flue losses vs tank losses for higher efficiency non-electric storage water heaters.
- Revises shared mechanical ventilation preconditioning control logic to operate less often.
- Adds alternative inputs:
  - Window/skylight physical properties (`GlassLayers`, `FrameType`, etc.) instead of `UFactor` & `SHGC`.
  - `Ducts/FractionDuctArea` instead of `Ducts/DuctSurfaceArea`.
  - `Length` instead of `Area` for foundation walls.
  - `Orientation` instead of `Azimuth` for all applicable surfaces, PV systems, and solar thermal systems.
  - CEER (Combined Energy Efficiency Ratio) instead of EER for room ACs.
  - `UsageBin` instead of `FirstHourRating` (for water heaters w/ UEF metric).
  - `CFM50` instead of `CFM25` or `Percent` for duct leakage.
- Allows more defaulting (optional inputs):
  - Mechanical ventilation airflow rate per ASHRAE 62.2-2019.
  - HVAC/DHW system efficiency (by age).
  - Mechanical ventilation fan power (by type).
  - Color (solar absorptance) for walls, roofs, and rim joists.
  - Foundation wall distance to top/bottom of insulation.
  - Door azimuth.
  - Radiant barrier grade.
  - Whole house fan airflow rate and fan power.
- Adds more warnings of inputs based on ANSI/BPI 2400 Standard.
- Removes error-check for number of bedrooms based on conditioned floor area, per RESNET guidance.
- Updates the reporting measure to register all outputs from the annual CSV with the OS runner (for use in, e.g., PAT).
- Removes timeseries CSV output columns that are all zeroes to reduce file size and processing time.
- Improves consistency of installation quality calculations for two/variable-speed air source heat pumps and ground source heat pumps.
- Relaxes requirement for heating (or cooling) setpoints so that they are only needed if heating (or cooling) equipment is present.
- Adds an `--ep-input-format` argument to run_simulation.rb to choose epJSON as the EnergyPlus input file format instead of IDF.
- Eliminates EnergyPlus warnings related to unused objects or invalid output meters/variables.
- Allows modeling PTAC and PTHP HVAC systems.
- Allows user inputs for partition wall mass and furniture mass.

__Bugfixes__
- Improves ground reflectance when there is shading of windows/skylights.
- Improves HVAC fan power for central forced air systems.
- Fixes mechanical ventilation compartmentalization area calculation for SFA/MF homes with surfaces with InteriorAdjacentTo==ExteriorAdjacentTo.
- Negative `DistanceToTopOfInsulation` values are now disallowed.
- Fixes workflow errors if a `VentilationFan` has zero airflow rate or zero hours of operation.
- Fixes duct design load calculations for HPXML files with multiple ducted HVAC systems.
- Fixes ground source heat pump rated airflow.
- Relaxes `Overhangs` DistanceToBottomOfWindow vs DistanceToBottomOfWindow validation when Depth is zero.
- Fixes possibility of double-counting HVAC distribution losses if an `HVACDistribution` element has both AirDistribution properties and DSE values
- Fixes possibility of incorrect "Peak Electricity: Winter Total (W)" and "Peak Electricity: Summer Total (W)" outputs for homes with duct losses.
- Fixes heating/cooling seasons (used for e.g. summer vs winter window shading) for the southern hemisphere.
- Fixes possibility of EnergyPlus simulation failure for homes with ground-source heat pumps and airflow and/or charge defects.
- Fixes peak load/electricity outputs for homes with ground-source heat pumps and airflow and/or charge defects.

## OpenStudio-HPXML v1.2.0

__New Features__
- **Breaking change**: Heating/cooling component loads no longer calculated by default for faster performance; use `--add-component-loads` argument if desired.
- **Breaking change**: Replaces `Site/extension/ShelterCoefficient` with `Site/ShieldingofHome`.
- Allows `DuctLeakageMeasurement` & `ConditionedFloorAreaServed` to not be specified for ductless fan coil systems; **Breaking change**: `AirDistributionType` is now required for all air distribution systems.
- Allows `Slab/ExposedPerimeter` to be zero.
- Removes `ClothesDryer/ControlType` from being a required input, it is not used.
- Switches room air conditioner model to use Cutler performance curves.
- Relaxes tolerance for duct leakage to outside warning when ducts solely in conditioned space.
- Removes limitation that a shared water heater serving a shared laundry room can't also serve dwelling unit fixtures (i.e., FractionDHWLoadServed is no longer required to be zero).
- Adds IDs to schematron validation errors/warnings when possible.
- Moves additional error-checking from the ruby measure to the schematron validator.

__Bugfixes__
- Fixes room air conditioner performance curve.
- Fixes ruby error if elements (e.g., `SystemIdentifier`) exist without the proper 'id'/'idref' attribute.
- Fixes error if boiler/GSHP pump power is zero
- Fixes possible "Electricity category end uses do not sum to total" error due to boiler pump energy.
- Fixes possible "Construction R-value ... does not match Assembly R-value" error for highly insulated enclosure elements.
- Adds error-checking for negative SEEReq results for shared cooling systems.
- Adds more detail to error messages regarding the wrong data type in the HPXML file.
- Prevents a solar hot water system w/ SolarFraction=1.

## OpenStudio-HPXML v1.1.0

__New Features__
- **Breaking change**: `Type` is now a required input for dehumidifiers; can be "portable" or "whole-home".
- **Breaking change**: `Location` is now a required input for dehumidifiers; must be "living space" as dehumidifiers are currently modeled as located in living space.
- **Breaking change**: `Type` is now a required input for Pool, PoolPump, HotTub, and HotTubPump.
- **Breaking change**: Both supply and return duct leakage to outside are now required inputs for AirDistribution systems.
- **Breaking change**: Simplifies inputs for fan coils and water loop heat pumps by A) removing HydronicAndAirDistribution element and B) moving WLHP inputs from extension elements to HeatPump element.
- Allows modeling airflow/charge defects for air conditioners, heat pumps, and furnaces (RESNET Standard 310).
- Allows modeling *multiple* dehumidifiers (previously only one allowed).
- Allows modeling generators (generic on-site power production).
- Allows detailed heating/cooling setpoints to be specified: 24-hour weekday & weekend values.
- Allows modeling window/skylight *exterior* shading via summer/winter shading coefficients.
- Allows JSON annual/timeseries output files to be generated instead of CSV. **Breaking change**: For CSV outputs, the first two sections in the results_annual.csv file are now prefixed with "Fuel Use:" and "End Use:", respectively.
- Allows more defaulting (optional inputs) for a variety of HPXML elements.
- Allows requesting timeseries unmet heating/cooling loads.
- Allows skipping schema/schematron validation (for speed); should only be used if the HPXML was already validated upstream.
- Allows HPXML files w/ multiple `Building` elements; requires providing the ID of the single building to be simulated.
- Includes hot water loads (in addition to heating/cooling loads) when timeseries total loads are requested.
- The `in.xml` HPXML file is now always produced for inspection of default values (e.g., autosized HVAC capacities). **Breaking change**: The `output_dir` HPXMLtoOpenStudio measure argument is now required.
- Overhauls documentation to be more comprehensive and standardized.
- `run_simulation.rb` now returns exit code 1 if not successful (i.e., either invalid inputs or simulation fails).

__Bugfixes__
- Improved modeling of window/skylight interior shading -- better reflects shading coefficient inputs.
- Adds error-checking on the HPXML schemaVersion.
- Adds various error-checking to the schematron validator.
- Adds error-checking for empty IDs in the HPXML file.
- Fixes heat pump water heater fan energy not included in SimulationOutputReport outputs.
- Fixes possibility of incorrect "A neighbor building has an azimuth (XXX) not equal to the azimuth of any wall" error.
- Fixes possibility of errors encountered before schematron validation has occurred.
- Small bugfixes related to basement interior surface solar absorptances.
- Allows NumberofConditionedFloors/NumberofConditionedFloorsAboveGrade to be non-integer values per the HPXML schema.
- HVAC sizing design load improvements for floors above crawlspaces/basements, walls, ducts, and heat pumps.
- Now recognizes Type="none" to prevent modeling of pools and hot tubs (pumps and heaters).
- Fixes error for overhangs with zero depth.
- Fixes possible error where the normalized flue height for the AIM-2 infiltration model is negative.
- Slight adjustment of default water heater recovery efficiency equation to prevent errors from values being too high.
- Fixes schematron file not being valid per ISO Schematron standard.

## OpenStudio-HPXML v1.0.0

__New Features__
- Updates to OpenStudio 3.1.0/EnergyPlus 9.4.0.
- **Breaking change**: Deprecates `WeatherStation/WMO` HPXML input, use `WeatherStation/extension/EPWFilePath` instead; also removes `weather_dir` argument from HPXMLtoOpenStudio measure.
- Implements water heater Uniform Energy Factor (UEF) model; replaces RESNET UEF->EF regression. **Breaking change**: `FirstHourRating` is now a required input for storage water heaters when UEF is provided.
- Adds optional HPXML fan power inputs for most HVAC system types. **Breaking change**: Removes ElectricAuxiliaryEnergy input for non-boiler heating systems.
- Uses air-source heat pump cooling performance curves for central air conditioners.
- Updates rated fan power assumption for mini-split heat pump models.
- Allows coal fuel type for non-boiler heating systems.
- Accommodates common walls adjacent to unconditioned space by using HPXML surfaces where InteriorAdjacentTo == ExteriorAdjacentTo.
- Adds optional HPXML inputs to define whether a clothes dryer is vented and its ventilation rate.
- Adds optional HPXML input for `SimulationControl/CalendarYear` for TMY weather files.
- Schematron validation improvements.
- Adds some HPXML XSD schema validation and additional error-checking.
- Various small updates to ASHRAE 140 test files.
- Reduces number of EnergyPlus output files produced by using new OutputControlFiles object.
- Release packages now include ASHRAE 140 test files/results.

__Bugfixes__
- EnergyPlus 9.4.0 fix for negative window solar absorptances at certain hours.
- Fixes airflow timeseries outputs to be averaged instead of summed.
- Updates HVAC sizing methodology for slab-on-grade foundation types.
- Fixes an error that could prevent schematron validation errors from being produced.
- Skips weather caching if filesystem is read only.

## OpenStudio-HPXML v0.11.0 Beta

__New Features__
- New [Schematron](http://schematron.com) validation (EPvalidator.xml) replaces custom ruby validation (EPvalidator.rb)
- **[Breaking change]** `BuildingConstruction/ResidentialFacilityType` ("single-family detached", "single-family attached", "apartment unit", or "manufactured home") is a required input
- Ability to model shared systems for Attached/Multifamily dwelling units
  - Shared HVAC systems (cooling towers, chillers, central boilers, water loop heat pumps, fan coils, ground source heat pumps on shared hydronic circulation loops)
  - Shared water heaters serving either A) multiple dwelling units' service hot water or B) a shared laundry/equipment room, as well as hot water recirculation systems
  - Shared appliances (e.g., clothes dryer in a shared laundry room)
  - Shared hot water recirculation systems
  - Shared ventilation systems (optionally with preconditioning equipment and recirculation)
  - Shared PV systems
  - **[Breaking change]** Appliances located in MF spaces (i.e., "other") must now be specified in more detail (i.e., "other heated space", "other non-freezing space", "other multifamily buffer space", or "other housing unit")
- Enclosure
  - New optional inputs: `Roof/RoofType`, `Wall/Siding`, and `RimJoist/Siding`
  - New optional inputs: `Skylight/InteriorShading/SummerShadingCoefficient` and `Skylight/InteriorShading/SummerShadingCoefficient`
  - New optional inputs: `Roof/RoofColor`, `Wall/Color`, and `RimJoist/Color` can be provided instead of `SolarAbsorptance`
  - New optional input to specify presence of flue/chimney, which results in increased infiltration
  - Allows adobe wall type
  - Allows `AirInfiltrationMeasurement/HousePressure` to be any value (previously required to be 50 Pa)
  - **[Breaking change]** `Roof/RadiantBarrierGrade` input now required when there is a radiant barrier
- HVAC
  - Adds optional high-level HVAC autosizing controls
    - `AllowIncreasedFixedCapacities`: Describes how HVAC equipment with fixed capacities are handled. If true, the maximum of the user-specified fixed capacity and the heating/cooling design load will be used to reduce potential for unmet loads. Defaults to false.
    - `UseMaxLoadForHeatPumps`: Describes how autosized heat pumps are handled. If true, heat pumps are sized based on the maximum of heating and cooling design loads. If false, heat pumps are sized per ACCA Manual J/S based on cooling design loads with some oversizing allowances for heating design loads. Defaults to true.
  - Additional HVAC types: mini-split air conditioners and fixed (non-portable) space heaters
  - Adds optional inputs for ground-to-air heat pumps: `extension/PumpPowerWattsPerTon` and `extension/FanPowerWattsPerCFM`
- Ventilation
  - Allows _multiple_ whole-home ventilation, spot ventilation, and/or whole house fans
- Appliances & Plug Loads
  - Allows _multiple_ `Refrigerator` and `Freezer`
  - Allows `Pool`, `HotTub`, `PlugLoad` of type "electric vehicle charging" and "well pump", and `FuelLoad` of type "grill", "lighting", and "fireplace"
  - **[Breaking change]** "other" and "TV other" plug loads now required
- Lighting
  - Allows lighting schedules and holiday lighting
- **[Breaking change]** For hydronic distributions, `HydronicDistributionType` is now required
- **[Breaking change]** For DSE distributions, `AnnualHeatingDistributionSystemEfficiency` and `AnnualCoolingDistributionSystemEfficiency` are both always required
- Allows more HPXML fuel types to be used for HVAC, water heating, appliances, etc.
- New inputs to define Daylight Saving period; defaults to enabled
- Adds more reporting of warnings/errors to run.log

__Bugfixes__
- Fixes pump energy for boilers and ground source heat pumps
- Fixes incorrect gallons of hot water use reported when there are multiple water heaters
- No longer report unmet load for buildings where the HVAC system only meets part of the load (e.g., room AC serving 33% of the load)
- Schedule bugfix for leap years

## OpenStudio-HPXML v0.10.0 Beta

__New Features__
- Dwelling units of single-family attached/multifamily buildings:
  - Adds new generic space types "other heated space", "other multifamily buffer space", and "other non-freezing space" for surface `ExteriorAdjacentTo` elements. "other housing unit", i.e. adiabatic surfaces, was already supported.
  - **[Breaking change]** For `FrameFloors`, replaces "other housing unit above" and "other housing unit below" enumerations with "other housing unit". All four "other ..." spaces must have an `extension/OtherSpaceAboveOrBelow` property set to either "above" or "below".
  - Allows ducts and water heaters to be located in all "other ..." spaces.
  - Allows all appliances to be located in "other", in which internal gains are neglected.
- Allows `Fireplace` and `FloorFurnace` for heating system types.
- Allows "exterior wall", "under slab", and "roof deck" for `DuctLocation`.
- Allows "wood" and "wood pellets" as fuel types for additional HVAC systems, water heaters, and appliances.
- Allows `Location` to be provided for `Dishwasher` and `CookingRange`.
- Allows `BuildingSummary/Site/SiteType` ("urban", "suburban", or "rural") to be provided.
- Allows user-specified `Refrigerator` and `CookingRange` schedules to be provided.
- HVAC capacity elements are no longer required; if not provided, ACCA Manual J autosizing calculations will be used (-1 can continue to be used for capacity elements but is discouraged).
- Duct locations/areas can be defaulted by specifying supply/return `Duct` elements without `DuctSurfaceArea` and `DuctLocation`. `HVACDistribution/DistributionSystemType/AirDistribution/NumberofReturnRegisters` can be optionally provided to inform the default duct area calculations.
- **[Breaking change]** Lighting inputs now use `LightingType[LightEmittingDiode | CompactFluorescent | FluorescentTube]` instead of `ThirdPartyCertification="ERI Tier I" or ThirdPartyCertification="ERI Tier II"`.
- **[Breaking change]** `HVACDistribution/ConditionedFloorAreaServed` is now required for air distribution systems.
- **[Breaking change]** Infiltration and attic ventilation specified using natural air changes per hour now uses `ACHnatural` instead of `extension/ConstantACHnatural`.
- **[Breaking change]** The optional `PerformanceAdjustment` input for instantaneous water heaters is now treated as a performance multiplier (e.g., 0.92) instead of derate (e.g., 0.08).
- Adds ASHRAE 140 Class II test files.
- SimulationOutputReport reporting measure:
  - New optional timeseries outputs:  airflows (e.g., infiltration, mechanical ventilation, natural ventilation, whole house fan) and weather (e.g., temperatures, wind speed, solar).
  - Timeseries frequency can now be set to 'none' as an alternative to setting all include_timeseries_foo variables to false.
  - **[Breaking change]** Renames "Wood" to "Wood Cord" to better distinguish from "Wood Pellets".
- Modeling improvements:
  - Improved calculation for infiltration height
  - Infiltration & mechanical ventilation now combined using ASHRAE 62.2 Normative Appendix C.
- Runtime improvements:
  - Optimized ruby require calls.
  - Skip ViewFactor calculations when not needed (i.e., no conditioned basement).
- Error-checking:
  - Adds more space type-specific error checking of adjacent surfaces.
  - Adds additional HPXML datatype checks.
  - Adds a warning if a `HVACDistribution` system has ducts entirely within conditioned space and non-zero leakage to the outside.
  - Adds warnings if appliance inputs may be inappropriate and result in negative energy or hot water use.

__Bugfixes__
- Fixes error if there's a `FoundationWall` whose height is less than 0.5 ft.
- Fixes HVAC defrost control in EnergyPlus model to use "Timed" instead of "OnDemand".
- Fixes exterior air film and wind exposure for a `FrameFloor` over ambient conditions.
- Fixes air films for a `FrameFloor` ceiling.
- Fixes error if there are additional `LightingGroup` elements beyond the ones required.
- Fixes vented attic ventilation rate.
- Reported unmet heating/cooling load now correctly excludes latent energy.
- Ground-source heat pump backup fuel is now correctly honored instead of always using electricity.

## OpenStudio-HPXML v0.9.0 Beta

__New Features__
- **[Breaking change]** Updates to OpenStudio v3.0.0 and EnergyPlus 9.3
- Numerous HPXML inputs are now optional with built-in defaulting, particularly for water heating, appliances, and PV. Set the `debug` argument to true to output a in.xml HPXML file with defaults applied for inspection. See the documentation for defaulting equations/assumptions/references.
- **[Breaking change]** If clothes washer efficiency inputs are provided, `LabelUsage` is now required.
- **[Breaking change]** If dishwasher efficiency inputs are provided, `LabelElectricRate`, `LabelGasRate`, `LabelAnnualGasCost`, and `LabelUsage` are now required.
- Adds optional specification of simulation controls including timestep and begin/end dates.
- Adds optional `extension/UsageMultiplier` inputs for appliances, plug loads, lighting, and water fixtures. Can be used to, e.g., reflect high/low usage occupants.
- Adds ability to model a dehumidifier.
- Adds ability to model kitchen/bath fans (spot ventilation).
- Improved desuperheater model; desuperheater can now be connected to heat pump water heaters.
- Updated clothes washer/dryer and dishwasher models per ANSI/RESNET/ICC 301-2019 Addendum A.
- Solar thermal systems modeled with `SolarFraction` can now be connected to combi water heating systems.
- **[Breaking change]** Replaces optional `epw_output_path` and `osm_output_path` arguments with a single optional `output_dir` argument; adds an optional `debug` argument.
- **[Breaking change]** Replaces optional `BuildingConstruction/extension/FractionofOperableWindowArea` with optional `Window/FractionOperable`.
- **[Breaking change]** Replaces optional `extension/EPWFileName` with optional `extension/EPWFilePath` to allow absolute paths to be provided as an alternative to just the file name.
- Replaces REXML xml library with Oga for better runtime performance.
- Additional error-checking.
- SimulationOutputReport reporting measure:
  - Now reports wood and wood pellets
  - Can report monthly timeseries values if requested
  - Adds hot water outputs (gallons) for clothes washer, dishwasher, fixtures, and distribution waste.
  - Small improvement to calculation of component loads

__Bugfixes__
- Fixes possible simulation error for buildings with complex HVAC/duct systems.
- Fixes handling of infiltration induced by duct leakage imbalance (i.e., supply leakage != return leakage). Only affects ducts located in a vented crawlspace or vented attic.
- Fixes an unsuccessful simulation for buildings where the sum of multiple HVAC systems' fraction load served was slightly above 1 due to rounding.
- Small fix for interior partition wall thermal mass model.
- Skip building surfaces with areas that are extremely small.

## OpenStudio-HPXML v0.8.0 Beta

__Breaking changes__
- Weather cache files are now in .csv instead of .cache format.
- `extension/StandbyLoss` changed to `StandbyLoss` for indirect water heaters.
- `Site/extension/DisableNaturalVentilation` changed to `BuildingConstruction/extension/FractionofOperableWindowArea` for more granularity.

__New Features__
- Adds a SimulationOutputReport reporting measure that provides a variety of annual/timeseries outputs in CSV format.
- Allows modeling of whole-house fans to address cooling.
- Improved natural ventilation algorithm that reduces the potential for incurring additional heating energy.
- Optional `HotWaterTemperature` input for water heaters.
- Optional `CompressorType` input for air conditioners and air-source heat pumps.
- Allows specifying the EnergyPlus simulation timestep.
- Runtime performance improvements.
- Additional HPXML error-checking.

__Bugfixes__
- Fix for central fan integrated supply (CFIS) fan energy.
- Fix simulation error when `FractionHeatLoadServed` (or `FractionCoolLoadServed`) sums to slightly greater than 1.
- Fix for running simulations on a different drive (either local or remote network).
- Fix for HVAC sizing error when latitude is exactly 64 (Big Delta, Alaska).
- Fixes running simulations when there is no weather cache file.
- Fixes view factors when conditioned basement foundation walls have a window/door.
- Fixes weather file download.
- Allow a building with ceiling fans and without lighting.

## OpenStudio-HPXML v0.7.0 Beta

- Initial beta release
