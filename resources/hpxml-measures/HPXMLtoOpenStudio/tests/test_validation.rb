# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require_relative '../measure.rb'
require 'csv'
require_relative '../resources/xmlhelper.rb'
require_relative '../resources/xmlvalidator.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioValidationTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    schema_path = File.absolute_path(File.join(@root_path, 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd'))
    @schema_validator = XMLValidator.get_xml_validator(schema_path)
    @schematron_path = File.join(@root_path, 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.sch')
    @schematron_validator = XMLValidator.get_xml_validator(@schematron_path)

    @tmp_hpxml_path = File.join(File.dirname(__FILE__), 'tmp.xml')
    @tmp_csv_path = File.join(@sample_files_path, 'tmp.csv')

    @default_schedules_csv_data = Defaults.get_schedules_csv_data()
  end

  def teardown
    cleanup_output_files([@tmp_hpxml_path, @tmp_csv_path])
  end

  def test_validation_of_schematron_doc
    # Check that the schematron file is valid
    schematron_schema_path = File.absolute_path(File.join(@root_path, 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'iso-schematron.xsd'))
    schematron_schema_validator = XMLValidator.get_xml_validator(schematron_schema_path)
    _test_schema_validation(@schematron_path, schematron_schema_validator)
  end

  # Test for consistent use of errors/warnings
  def test_role_attributes_in_schematron_doc
    puts
    puts 'Checking for correct role attributes...'

    schematron_doc = XMLHelper.parse_file(@schematron_path)

    # check that every assert element has a role attribute
    XMLHelper.get_elements(schematron_doc, '/sch:schema/sch:pattern/sch:rule/sch:assert').each do |assert_element|
      assert_test = XMLHelper.get_attribute_value(assert_element, 'test').gsub('h:', '')
      role_attribute = XMLHelper.get_attribute_value(assert_element, 'role')
      if role_attribute.nil?
        fail "No attribute \"role='ERROR'\" found for assertion test: #{assert_test}"
      end

      assert_equal('ERROR', role_attribute)
    end

    # check that every report element has a role attribute
    XMLHelper.get_elements(schematron_doc, '/sch:schema/sch:pattern/sch:rule/sch:report').each do |report_element|
      report_test = XMLHelper.get_attribute_value(report_element, 'test').gsub('h:', '')
      role_attribute = XMLHelper.get_attribute_value(report_element, 'role')
      if role_attribute.nil?
        fail "No attribute \"role='WARN'\" found for report test: #{report_test}"
      end

      assert_equal('WARN', role_attribute)
    end
  end

  # Test errors are correctly triggered during the XSD schema or Schematron validation
  def test_schema_schematron_error_messages
    # Test case => Error message(s)
    all_expected_errors = { 'boiler-invalid-afue' => ['Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1'],
                            'clothes-dryer-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'clothes-washer-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'cooking-range-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'dehumidifier-fraction-served' => ['Expected sum(FractionDehumidificationLoadServed) to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]'],
                            'dhw-frac-load-served' => ['Expected sum(FractionDHWLoadServed) to be 1 [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]'],
                            'dhw-invalid-ef-tank' => ['Expected EnergyFactor to be less than 1 [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater"], id: "WaterHeatingSystem1"]'],
                            'dhw-invalid-uef-tank-heat-pump' => ['Expected UniformEnergyFactor to be greater than 1 [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="heat pump water heater"], id: "WaterHeatingSystem1"]'],
                            'dishwasher-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'duct-leakage-cfm25' => ["The value '-2.0' is less than the minimum value allowed",
                                                     "The value '-3.0' is less than the minimum value allowed"],
                            'duct-leakage-cfm50' => ["The value '-2.0' is less than the minimum value allowed",
                                                     "The value '-3.0' is less than the minimum value allowed"],
                            'duct-leakage-percent' => ['Expected Value to be less than 1 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/DuctLeakageMeasurement/DuctLeakage[Units="Percent"], id: "HVACDistribution1"]'],
                            'duct-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'duct-location-unconditioned-space' => ["Expected DuctLocation to be 'conditioned space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'attic - vented' or 'attic - unvented' or 'garage' or 'exterior wall' or 'under slab' or 'roof deck' or 'outside' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'manufactured home belly' [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts, id: \"Ducts1\"]",
                                                                    "Expected DuctLocation to be 'conditioned space' or 'basement - conditioned' or 'basement - unconditioned' or 'crawlspace - vented' or 'crawlspace - unvented' or 'crawlspace - conditioned' or 'attic - vented' or 'attic - unvented' or 'garage' or 'exterior wall' or 'under slab' or 'roof deck' or 'outside' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space' or 'manufactured home belly' [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts, id: \"Ducts2\"]"],
                            'emissions-electricity-schedule' => ['Expected NumberofHeaderRows to be greater than or equal to 0',
                                                                 'Expected ColumnNumber to be greater than or equal to 1'],
                            'enclosure-attic-missing-roof' => ['There must be at least one roof adjacent to "attic - unvented". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="attic - unvented" or ExteriorAdjacentTo="attic - unvented"]], id: "MyBuilding"]'],
                            'enclosure-basement-missing-exterior-foundation-wall' => ['There must be at least one exterior wall or foundation wall adjacent to "basement - unconditioned". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="basement - unconditioned" or ExteriorAdjacentTo="basement - unconditioned"]], id: "MyBuilding"]'],
                            'enclosure-basement-missing-slab' => ['There must be at least one slab adjacent to "basement - unconditioned". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="basement - unconditioned" or ExteriorAdjacentTo="basement - unconditioned"]], id: "MyBuilding"]'],
                            'enclosure-floor-area-exceeds-cfa' => ['Expected ConditionedFloorArea to be greater than or equal to the sum of conditioned slab/floor areas. [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction, id: "MyBuilding"]'],
                            'enclosure-floor-area-exceeds-cfa2' => ['Expected ConditionedFloorArea to be greater than or equal to the sum of conditioned slab/floor areas. [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction, id: "MyBuilding"]'],
                            'enclosure-garage-missing-exterior-wall' => ['There must be at least one exterior wall or foundation wall adjacent to "garage". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="garage" or ExteriorAdjacentTo="garage"]], id: "MyBuilding"]'],
                            'enclosure-garage-missing-roof-ceiling' => ['There must be at least one roof or ceiling adjacent to "garage". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="garage" or ExteriorAdjacentTo="garage"]], id: "MyBuilding"]'],
                            'enclosure-garage-missing-slab' => ['There must be at least one slab adjacent to "garage". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="garage" or ExteriorAdjacentTo="garage"]], id: "MyBuilding"]'],
                            'enclosure-conditioned-missing-ceiling-roof' => ['There must be at least one ceiling or roof adjacent to conditioned space. [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="conditioned space"]], id: "MyBuilding"]',
                                                                             'There must be at least one floor adjacent to "attic - unvented". [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="attic - unvented" or ExteriorAdjacentTo="attic - unvented"]], id: "MyBuilding"]'],
                            'enclosure-conditioned-missing-exterior-wall' => ['There must be at least one exterior wall adjacent to conditioned space. [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="conditioned space"]], id: "MyBuilding"]'],
                            'enclosure-conditioned-missing-floor-slab' => ['There must be at least one floor or slab adjacent to conditioned space. [context: /HPXML/Building/BuildingDetails/Enclosure[*/*[InteriorAdjacentTo="conditioned space"]], id: "MyBuilding"]'],
                            'frac-sensible-latent-fuel-load-values' => ['Expected extension/FracSensible to be greater than or equal to 0 [context: /HPXML/Building/BuildingDetails/MiscLoads/FuelLoad[FuelLoadType="grill" or FuelLoadType="lighting" or FuelLoadType="fireplace"], id: "FuelLoad1"]',
                                                                        'Expected extension/FracLatent to be greater than or equal to 0 [context: /HPXML/Building/BuildingDetails/MiscLoads/FuelLoad[FuelLoadType="grill" or FuelLoadType="lighting" or FuelLoadType="fireplace"], id: "FuelLoad1"]'],
                            'frac-sensible-latent-fuel-load-presence' => ['Expected 0 or 2 element(s) for xpath: extension/FracSensible | extension/FracLatent'],
                            'frac-sensible-latent-plug-load-values' => ['Expected extension/FracSensible to be greater than or equal to 0 [context: /HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other" or PlugLoadType="TV other" or PlugLoadType="electric vehicle charging" or PlugLoadType="well pump"], id: "PlugLoad1"]',
                                                                        'Expected extension/FracLatent to be greater than or equal to 0 [context: /HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other" or PlugLoadType="TV other" or PlugLoadType="electric vehicle charging" or PlugLoadType="well pump"], id: "PlugLoad1"]'],
                            'frac-sensible-latent-plug-load-presence' => ['Expected 0 or 2 element(s) for xpath: extension/FracSensible | extension/FracLatent'],
                            'frac-total-fuel-load' => ['Expected sum of extension/FracSensible and extension/FracLatent to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails/MiscLoads/FuelLoad[FuelLoadType="grill" or FuelLoadType="lighting" or FuelLoadType="fireplace"], id: "FuelLoad1"]'],
                            'frac-total-plug-load' => ['Expected sum of extension/FracSensible and extension/FracLatent to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails/MiscLoads/PlugLoad[PlugLoadType="other" or PlugLoadType="TV other" or PlugLoadType="electric vehicle charging" or PlugLoadType="well pump"], id: "PlugLoad2"]'],
                            'furnace-invalid-afue' => ['Expected AnnualHeatingEfficiency[Units="AFUE"]/Value to be less than or equal to 1'],
                            'generator-number-of-bedrooms-served' => ['Expected NumberofBedroomsServed to be greater than ../../../../BuildingSummary/BuildingConstruction/NumberofBedrooms [context: /HPXML/Building/BuildingDetails/Systems/extension/Generators/Generator[IsSharedSystem="true"], id: "Generator1"]'],
                            'generator-output-greater-than-consumption' => ['Expected AnnualConsumptionkBtu to be greater than AnnualOutputkWh*3412 [context: /HPXML/Building/BuildingDetails/Systems/extension/Generators/Generator, id: "Generator1"]'],
                            'heat-pump-backup-sizing' => ["Expected HeatPumpBackupSizingMethodology to be 'emergency' or 'supplemental'"],
                            'heat-pump-separate-backup-inputs' => ['Expected 0 element(s) for xpath: BackupAnnualHeatingEfficiency',
                                                                   'Expected 0 element(s) for xpath: BackupHeatingCapacity',
                                                                   'Expected 0 element(s) for xpath: extension/BackupHeatingAutosizingFactor'],
                            'heat-pump-capacity-17f-value' => ['Expected HeatingCapacity17F to be less than or equal to HeatingCapacity'],
                            'heat-pump-capacity-17f-presence' => ['Expected HeatingCapacity when HeatingCapacity17F is provided'],
                            'heat-pump-lockout-temperatures' => ['Expected CompressorLockoutTemperature to be less than or equal to BackupHeatingLockoutTemperature'],
                            'heat-pump-multiple-backup-systems' => ['Expected 0 or 1 element(s) for xpath: HeatPump/BackupSystem [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]'],
                            'hvac-detailed-performance-bad-odbs' => ['Expected PerformanceDataPoint/OutdoorTemperature to be 47, 17, 5, or <5',
                                                                     'Expected PerformanceDataPoint/OutdoorTemperature to be 82, 95, or >95'],
                            'hvac-detailed-performance-inconsistent-capacities' => ['Expected ../../HeatingCapacity to be equal to Capacity',
                                                                                    'Expected ../../HeatingCapacity17F to be equal to Capacity',
                                                                                    'Expected ../../CoolingCapacity to be equal to Capacity'],
                            'hvac-detailed-performance-inconsistent-capacity-fractions' => ['Expected CapacityFractionOfNominal to be 1.0',
                                                                                            'Expected CapacityFractionOfNominal to be 1.0'],
                            'hvac-detailed-performance-incomplete-pair' => ['Cooling detailed performance data for outdoor temperature > 95.0 is incomplete; there must be exactly one minimum and one maximum capacity datapoint.',
                                                                            'Heating detailed performance data for outdoor temperature < 5.0 is incomplete; there must be exactly one minimum and one maximum capacity datapoint.'],
                            'hvac-detailed-performance-invalid-data' => ['Cooling detailed performance data for outdoor temperature = 82.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.',
                                                                         'Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Minimum capacity must be less than maximum capacity.',
                                                                         'Cooling detailed performance data for outdoor temperature = 95.0 is invalid; Minimum capacity must be less than or equal to nominal capacity.',
                                                                         'Heating detailed performance data for outdoor temperature = 47.0 is invalid; Power (capacity / COP) at minimum capacity must be less than power at maximum capacity.',
                                                                         'Heating detailed performance data for outdoor temperature = 47.0 is invalid; Power (capacity / COP) at minimum capacity must be less than or equal to power at nominal capacity.',
                                                                         'Heating detailed performance data for outdoor temperature = 5.0 is invalid; Minimum capacity must be less than maximum capacity.'],
                            'hvac-distribution-return-duct-leakage-missing' => ['Expected 1 element(s) for xpath: DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[(Units="CFM25" or Units="CFM50" or Units="Percent") and TotalOrToOutside="to outside"] [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution[AirDistributionType[text()="regular velocity" or text()="gravity"]], id: "HVACDistribution1"]'],
                            'hvac-frac-load-served' => ['Expected sum(FractionHeatLoadServed) to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]',
                                                        'Expected sum(FractionCoolLoadServed) to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]'],
                            'hvac-gshp-invalid-bore-config' => ["Expected BorefieldConfiguration to be 'Rectangle' or 'Open Rectangle' or 'C' or 'L' or 'U' or 'Lopsided U' [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/GeothermalLoop, id: \"GeothermalLoop1\"]"],
                            'hvac-gshp-invalid-bore-depth-low' => ['Expected BoreholesOrTrenches/Length to be greater than or equal to 80 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/GeothermalLoop, id: "GeothermalLoop1"]'],
                            'hvac-gshp-invalid-bore-depth-high' => ['Expected BoreholesOrTrenches/Length to be less than or equal to 500 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/GeothermalLoop, id: "GeothermalLoop1"]'],
                            'hvac-gshp-autosized-count-not-rectangle' => ["Expected BoreholesOrTrenches/Count when extension/BorefieldConfiguration is not 'Rectangle' [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/GeothermalLoop, id: \"GeothermalLoop1\"]"],
                            'hvac-invalid-fan-model-type' => ["Expected extension/FanMotorType to be 'PSC' or 'BPM'"],
                            'hvac-invalid-eer' => ['Expected EER to be less than SEER.'],
                            'hvac-invalid-eer2' => ['Expected EER2 to be less than or equal to SEER2.'],
                            'hvac-location-heating-system' => ['A location is specified as "basement - unconditioned" but no surfaces were found adjacent to this space type.'],
                            'hvac-location-cooling-system' => ['A location is specified as "basement - unconditioned" but no surfaces were found adjacent to this space type.'],
                            'hvac-location-heat-pump' => ['A location is specified as "basement - unconditioned" but no surfaces were found adjacent to this space type.'],
                            'hvac-msac-not-var-speed' => ["Expected CompressorType to be 'variable speed'"],
                            'hvac-mshp-not-var-speed' => ["Expected CompressorType to be 'variable speed'"],
                            'hvac-research-features-timestep-ten-mins' => ['Expected /HPXML/SoftwareInfo/extension/SimulationControl/Timestep to be 1.0',
                                                                           'Expected Timestep to be 1.0'],
                            'hvac-research-features-timestep-missing' => ['Expected /HPXML/SoftwareInfo/extension/SimulationControl/Timestep to be 1.0',
                                                                          'Expected Timestep to be 1.0'],
                            'hvac-research-features-onoff-thermostat-heat-load-fraction-partial' => ['Expected sum(FractionHeatLoadServed) to be equal to 1'],
                            'hvac-research-features-onoff-thermostat-cool-load-fraction-partial' => ['Expected sum(FractionCoolLoadServed) to be equal to 1'],
                            'hvac-research-features-onoff-thermostat-negative-value' => ['Expected OnOffThermostatDeadbandTemperature to be greater than 0'],
                            'hvac-research-features-onoff-thermostat-two-heat-pumps' => ['Expected at maximum one cooling system for each Building',
                                                                                         'Expected at maximum one heating system for each Building'],
                            'hvac-sizing-humidity-setpoint' => ['Expected ManualJInputs/HumiditySetpoint to be less than 1'],
                            'hvac-sizing-daily-temp-range' => ["Expected ManualJInputs/DailyTemperatureRange to be 'low' or 'medium' or 'high'"],
                            'hvac-negative-crankcase-heater-watts' => ['Expected extension/CrankcaseHeaterPowerWatts to be greater than or equal to 0.0.'],
                            'incomplete-integrated-heating' => ['Expected 1 element(s) for xpath: IntegratedHeatingSystemFractionHeatLoadServed'],
                            'invalid-airflow-defect-ratio' => ['Expected extension/AirflowDefectRatio to be 0'],
                            'invalid-airflow-rates' => ['Expected extension/HeatingDesignAirflowCFM to be greater than or equal to 0',
                                                        'Expected extension/CoolingDesignAirflowCFM to be greater than or equal to 0'],
                            'invalid-assembly-effective-rvalue' => ["Element 'AssemblyEffectiveRValue': [facet 'minExclusive'] The value '0.0' must be greater than '0'."],
                            'invalid-battery-capacities-ah' => ['Expected UsableCapacity to be less than NominalCapacity'],
                            'invalid-battery-capacities-kwh' => ['Expected UsableCapacity to be less than NominalCapacity'],
                            'invalid-calendar-year-low' => ['Expected CalendarYear to be greater than or equal to 1600'],
                            'invalid-calendar-year-high' => ['Expected CalendarYear to be less than or equal to 9999'],
                            'invalid-clothes-dryer-cef' => ["Element 'CombinedEnergyFactor': [facet 'minExclusive'] The value '0.0' must be greater than '0'."],
                            'invalid-clothes-washer-imef' => ["Element 'IntegratedModifiedEnergyFactor': [facet 'minExclusive'] The value '0.0' must be greater than '0'."],
                            'invalid-cfis-addtl-runtime-mode' => ["Expected CFISControls/AdditionalRuntimeOperatingMode to be 'air handler fan'"],
                            'invalid-dishwasher-ler' => ["Element 'LabelElectricRate': [facet 'minExclusive'] The value '0.0' must be greater than '0'."],
                            'invalid-duct-area-fractions' => ['Expected sum(Ducts/FractionDuctArea) for DuctType="supply" to be 1 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution, id: "HVACDistribution1"]',
                                                              'Expected sum(Ducts/FractionDuctArea) for DuctType="return" to be 1 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution, id: "HVACDistribution1"]'],
                            'invalid-facility-type' => ['Expected 1 element(s) for xpath: ../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[IsSharedSystem="true"], id: "WaterHeatingSystem1"]',
                                                        'Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Appliances/ClothesWasher[IsSharedAppliance="true"], id: "ClothesWasher1"]',
                                                        'Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Appliances/ClothesDryer[IsSharedAppliance="true"], id: "ClothesDryer1"]',
                                                        'Expected 1 element(s) for xpath: ../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]] [context: /HPXML/Building/BuildingDetails/Appliances/Dishwasher[IsSharedAppliance="true"], id: "Dishwasher1"]',
                                                        'There are references to "other housing unit" but ResidentialFacilityType is not "single-family attached" or "apartment unit".',
                                                        'There are references to "other heated space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".'],
                            'invalid-foundation-wall-properties' => ['Expected DepthBelowGrade to be less than or equal to Height [context: /HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall[not(SystemIdentifier/@sameas and /HPXML/SoftwareInfo/extension/WholeSFAorMFBuildingSimulation[text()="true"])], id: "FoundationWall1"]',
                                                                     'Expected DistanceToBottomOfInsulation to be greater than or equal to DistanceToTopOfInsulation [context: /HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall/Insulation/Layer[InstallationType="continuous - exterior" or InstallationType="continuous - interior"], id: "FoundationWall1Insulation"]',
                                                                     'Expected DistanceToBottomOfInsulation to be less than or equal to ../../Height [context: /HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall/Insulation/Layer[InstallationType="continuous - exterior" or InstallationType="continuous - interior"], id: "FoundationWall1Insulation"]'],
                            'invalid-ground-conductivity' => ["The value '0.0' must be greater than '0'"],
                            'invalid-ground-diffusivity' => ['Expected extension/Diffusivity to be greater than 0'],
                            'invalid-heat-pump-capacity-fraction-17F' => ['Expected extension/HeatingCapacityFraction17F to be less than 1'],
                            'invalid-heat-pump-capacity-fraction-17F-2' => ['Expected extension/HeatingCapacityFraction17F to be greater than or equal to 0'],
                            'invalid-hvac-installation-quality' => ['Expected extension/AirflowDefectRatio to be greater than or equal to -0.9 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"], id: "HeatPump1"]',
                                                                    'Expected extension/ChargeDefectRatio to be greater than or equal to -0.9 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"], id: "HeatPump1"]'],
                            'invalid-hvac-installation-quality2' => ['Expected extension/AirflowDefectRatio to be less than or equal to 9 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"], id: "HeatPump1"]',
                                                                     'Expected extension/ChargeDefectRatio to be less than or equal to 9 [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"], id: "HeatPump1"]'],
                            'invalid-id2' => ["Element 'SystemIdentifier': The attribute 'id' is required but missing."],
                            'invalid-input-parameters' => ["Element 'Transaction': [facet 'enumeration'] The value 'modify' is not an element of the set {'create', 'update'}.",
                                                           "Element 'SiteType': [facet 'enumeration'] The value 'mountain' is not an element of the set {'rural', 'suburban', 'urban'}.",
                                                           "Element 'Year': [facet 'enumeration'] The value '2020' is not an element of the set {'2024', '2021', '2018', '2015', '2012', '2009', '2006', '2003'}.",
                                                           "Element 'Azimuth': [facet 'maxExclusive'] The value '365' must be less than '360'.",
                                                           "Element 'RadiantBarrierGrade': [facet 'maxInclusive'] The value '4' is greater than the maximum value allowed ('3').",
                                                           "Element 'EnergyFactor': [facet 'maxInclusive'] The value '5.1' is greater than the maximum value allowed ('5')."],
                            'invalid-insulation-top' => ["Element 'DistanceToTopOfInsulation': [facet 'minInclusive'] The value '-0.5' is less than the minimum value allowed ('0')."],
                            'invalid-integrated-heating' => ['Expected 0 element(s) for xpath: IntegratedHeatingSystemFuel'],
                            'invalid-lighting-groups' => ['Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                          'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                          'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                          'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                          'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                          'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value'],
                            'invalid-lighting-groups2' => ['Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="interior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="exterior"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value',
                                                           'Expected 1 element(s) for xpath: ../LightingGroup[LightingType[CompactFluorescent] and Location="garage"]/FractionofUnitsInLocation | Load[Units="kWh/year"]/Value'],
                            'invalid-natvent-availability' => ['Expected extension/NaturalVentilationAvailabilityDaysperWeek to be less than or equal to 7'],
                            'invalid-natvent-availability2' => ['Expected extension/NaturalVentilationAvailabilityDaysperWeek to be greater than or equal to 0'],
                            'invalid-number-of-bedrooms-served-pv' => ['Expected extension/NumberofBedroomsServed to be greater than ../../../BuildingSummary/BuildingConstruction/NumberofBedrooms [context: /HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem[IsSharedSystem="true"], id: "PVSystem1"]'],
                            'invalid-number-of-bedrooms-served-recirc' => ['Expected NumberofBedroomsServed to be greater than ../../../../../BuildingSummary/BuildingConstruction/NumberofBedrooms [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/extension/SharedRecirculation, id: "HotWaterDistribution1"]'],
                            'invalid-number-of-bedrooms-served-water-heater' => ['Expected extension/NumberofBedroomsServed to be greater than ../../../BuildingSummary/BuildingConstruction/NumberofBedrooms [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[IsSharedSystem="true"], id: "WaterHeatingSystem1"]'],
                            'invalid-number-of-conditioned-floors' => ['Expected NumberofConditionedFloors to be greater than or equal to NumberofConditionedFloorsAboveGrade [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction, id: "MyBuilding"]'],
                            'invalid-number-of-conditioned-floors-above-grade' => ['Expected NumberofConditionedFloorsAboveGrade to be greater than 0 [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction, id: "MyBuilding"]'],
                            'invalid-pilot-light-heating-system' => ['Expected 1 element(s) for xpath: ../../HeatingSystemFuel[text()!="electricity"]'],
                            'invalid-soil-type' => ["Expected SoilType to be 'sand' or 'silt' or 'clay' or 'loam' or 'gravel' or 'unknown' [context: /HPXML/Building/BuildingDetails/BuildingSummary/Site/Soil, id: \"MyBuilding\"]"],
                            'invalid-shared-vent-in-unit-flowrate' => ['Expected RatedFlowRate to be greater than extension/InUnitFlowRate [context: /HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true" and IsSharedSystem="true"], id: "VentilationFan1"]'],
                            'invalid-timestep' => ['Expected Timestep to be 60, 30, 20, 15, 12, 10, 6, 5, 4, 3, 2, or 1'],
                            'invalid-timezone-utcoffset-low' => ["Element 'UTCOffset': [facet 'minInclusive'] The value '-13.0' is less than the minimum value allowed ('-12')."],
                            'invalid-timezone-utcoffset-high' => ["Element 'UTCOffset': [facet 'maxInclusive'] The value '15.0' is greater than the maximum value allowed ('14')."],
                            'invalid-ventilation-fan' => ['Expected 1 element(s) for xpath: UsedForWholeBuildingVentilation[text()="true"] | UsedForLocalVentilation[text()="true"] | UsedForSeasonalCoolingLoadReduction[text()="true"] | UsedForGarageVentilation[text()="true"]'],
                            'invalid-ventilation-recovery' => ['Expected 0 element(s) for xpath: TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency',
                                                               'Expected 0 element(s) for xpath: SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency'],
                            'invalid-water-heater-heating-capacity' => ['Expected HeatingCapacity to be greater than 0.'],
                            'invalid-water-heater-heating-capacity2' => ['Expected HeatingCapacity to be greater than 0.'],
                            'invalid-water-heater-stratified-tank-model' => ['Expected 0 element(s) for xpath: extension/TankModelType'],
                            'invalid-whole-sfa-or-mf-building-sim' => ['WholeSFAorMFBuildingSimulation must be false or omitted for single-family detached/manufactured homes.'],
                            'invalid-window-height' => ['Expected DistanceToBottomOfWindow to be greater than DistanceToTopOfWindow [context: /HPXML/Building/BuildingDetails/Enclosure/Windows/Window/Overhangs[number(Depth) > 0], id: "Window2"]'],
                            'leakiness-description-missing-year-built' => ['Expected 1 element(s) for xpath: BuildingSummary/BuildingConstruction/YearBuilt'],
                            'lighting-fractions' => ['Expected sum(LightingGroup/FractionofUnitsInLocation) for Location="interior" to be less than or equal to 1 [context: /HPXML/Building/BuildingDetails/Lighting, id: "MyBuilding"]'],
                            'manufactured-home-reference-duct' => ['There are references to "manufactured home belly" or "manufactured home underbelly" but ResidentialFacilityType is not "manufactured home".',
                                                                   'A location is specified as "manufactured home belly" but no surfaces were found adjacent to the "manufactured home underbelly" space type.'],
                            'manufactured-home-reference-water-heater' => ['There are references to "manufactured home belly" or "manufactured home underbelly" but ResidentialFacilityType is not "manufactured home".',
                                                                           'A location is specified as "manufactured home belly" but no surfaces were found adjacent to the "manufactured home underbelly" space type.',
                                                                           "Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'"],
                            'manufactured-home-reference-floor' => ['There are references to "manufactured home belly" or "manufactured home underbelly" but ResidentialFacilityType is not "manufactured home".',
                                                                    'There must be at least one ceiling adjacent to "crawlspace - vented".'],
                            'missing-attached-to-space-wall' => ['Expected 1 element(s) for xpath: AttachedToSpace'],
                            'missing-attached-to-space-slab' => ['Expected 1 element(s) for xpath: AttachedToSpace'],
                            'missing-attached-to-zone' => ['Expected 1 element(s) for xpath: AttachedToZone'],
                            'missing-cfis-supplemental-fan' => ['Expected 1 element(s) for xpath: CFISControls/SupplementalFan'],
                            'missing-distribution-cfa-served' => ['Expected 1 element(s) for xpath: ../../../ConditionedFloorAreaServed [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[not(DuctSurfaceArea)], id: "Ducts1"]',
                                                                  'Expected 1 element(s) for xpath: ../../../ConditionedFloorAreaServed [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[not(DuctSurfaceArea)], id: "Ducts2"]',
                                                                  'Expected 1 element(s) for xpath: ../../../ConditionedFloorAreaServed [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[not(DuctSurfaceArea)], id: "Ducts3"]',
                                                                  'Expected 1 element(s) for xpath: ../../../ConditionedFloorAreaServed [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[not(DuctSurfaceArea)], id: "Ducts4"]'],
                            'missing-duct-area' => ['Expected 1 or more element(s) for xpath: FractionDuctArea | DuctSurfaceArea [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[DuctLocation], id: "Ducts2"]'],
                            'missing-duct-location' => ['Expected 0 element(s) for xpath: FractionDuctArea | DuctSurfaceArea [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[not(DuctLocation)], id: "Ducts2"]'],
                            'missing-elements' => ['Expected 1 element(s) for xpath: NumberofConditionedFloors [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction, id: "MyBuilding"]',
                                                   'Expected 1 element(s) for xpath: ConditionedFloorArea [context: /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction, id: "MyBuilding"]'],
                            'missing-epw-filepath-and-zipcode' => ['Expected 1 or more element(s) for xpath: Address/ZipCode | ../BuildingDetails/ClimateandRiskZones/WeatherStation/extension/EPWFilePath'],
                            'missing-hpwh-containment-volume' => ['Expected 1 element(s) for xpath: HPWHContainmentVolume [context: /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem/extension[HPWHInConfinedSpaceWithoutMitigation="true"], id: "WaterHeatingSystem1"]'],
                            'missing-inverter-idref' => ['Expected 1 element(s) for xpath: AttachedToInverter [context: /HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem[count(../Inverter) > 1], id: "PVSystem1"]',
                                                         'Expected 1 element(s) for xpath: AttachedToInverter [context: /HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem[count(../Inverter) > 1], id: "PVSystem2"]'],
                            'missing-skylight-floor' => ['Expected 1 element(s) for xpath: ../../AttachedToFloor'],
                            'multifamily-common-space-extra-inputs' => ['Expected only SystemIdentifier to be specified when sameas attribute used',
                                                                        'Expected only SystemIdentifier to be specified when sameas attribute used',
                                                                        'Expected only SystemIdentifier to be specified when sameas attribute used',
                                                                        'Expected only SystemIdentifier to be specified when sameas attribute used'],
                            'multifamily-common-space-whole-sfa-or-mf-building-sim-false' => ['Expected 1 element(s) for xpath: ExteriorAdjacentTo [context: /HPXML/Building/BuildingDetails/Enclosure/RimJoists/RimJoist[not(SystemIdentifier/@sameas and /HPXML/SoftwareInfo/extension/WholeSFAorMFBuildingSimulation[text()="true"])], id: "RimJoist2_2"]',
                                                                                              'Expected 1 element(s) for xpath: ExteriorAdjacentTo [context: /HPXML/Building/BuildingDetails/Enclosure/Walls/Wall[not(SystemIdentifier/@sameas and /HPXML/SoftwareInfo/extension/WholeSFAorMFBuildingSimulation[text()="true"])], id: "Wall2_3"]',
                                                                                              'Expected 1 element(s) for xpath: ExteriorAdjacentTo [context: /HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall[not(SystemIdentifier/@sameas and /HPXML/SoftwareInfo/extension/WholeSFAorMFBuildingSimulation[text()="true"])], id: "FoundationWall2_2"]',
                                                                                              'Expected 1 element(s) for xpath: ExteriorAdjacentTo [context: /HPXML/Building/BuildingDetails/Enclosure/Floors/Floor[not(SystemIdentifier/@sameas and /HPXML/SoftwareInfo/extension/WholeSFAorMFBuildingSimulation[text()="true"])], id: "Floor1_1"]'],
                            'multifamily-reference-appliance' => ['There are references to "other housing unit" but ResidentialFacilityType is not "single-family attached" or "apartment unit".'],
                            'multifamily-reference-duct' => ['There are references to "other multifamily buffer space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".'],
                            'multifamily-reference-surface' => ['There are references to "other heated space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".'],
                            'multifamily-reference-water-heater' => ['There are references to "other non-freezing space" but ResidentialFacilityType is not "single-family attached" or "apartment unit".'],
                            'negative-autosizing-factors' => ['CoolingAutosizingFactor should be greater than 0.0',
                                                              'HeatingAutosizingFactor should be greater than 0.0',
                                                              'BackupHeatingAutosizingFactor should be greater than 0.0'],
                            'negative-hpwh-containment-volume' => ['Expected HPWHContainmentVolume to be greater than 0.'],
                            'panel-zero-total-breaker-spaces' => ["Element 'RatedTotalSpaces': [facet 'minExclusive'] The value '0' must be greater than '0'."],
                            'panel-without-required-system' => ['Expected 1 or more element(s) for xpath: AttachedToComponent [context: /HPXML/Building/BuildingDetails/Systems/ElectricPanels/ElectricPanel/ServiceFeeders/ServiceFeeder, id: "ServiceFeeder1"]'],
                            'panel-with-unrequired-system' => ['Expected 0 element(s) for xpath: AttachedToComponent [context: /HPXML/Building/BuildingDetails/Systems/ElectricPanels/ElectricPanel/ServiceFeeders/ServiceFeeder, id: "ServiceFeeder1"]'],
                            'panel-without-load-type' => ['Expected 1 element(s) for xpath: LoadType [context: /HPXML/Building/BuildingDetails/Systems/ElectricPanels/ElectricPanel/ServiceFeeders/ServiceFeeder, id: "ServiceFeeder1"]'],
                            'panel-insufficient-voltage' => ["Expected ../../../ElectricPanel/Voltage to be '240' [context: /HPXML/Building/BuildingDetails/Systems/ElectricPanels/ElectricPanel/BranchCircuits/BranchCircuit, id: \"BranchCircuit1\"]"],
                            'panel-zero-meter-based' => ['Expected extension/ElectricPanelBaselinePeakPower to be greater than 0 [context: /HPXML/Building/BuildingDetails/BuildingSummary, id: "MyBuilding"]'],
                            'refrigerator-location' => ['A location is specified as "garage" but no surfaces were found adjacent to this space type.'],
                            'refrigerator-schedule' => ['Expected either schedule fractions/multipliers or schedule coefficients but not both.'],
                            'solar-fraction-one' => ['Expected SolarFraction to be less than or equal to 0.99 [context: /HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem[SolarFraction], id: "SolarThermalSystem1"]'],
                            'sum-space-floor-area' => ['Expected sum(Zones/Zone[ZoneType="conditioned"]/Spaces/Space/FloorArea) to be equal to BuildingSummary/BuildingConstruction/ConditionedFloorArea'],
                            'sum-space-floor-area2' => ['Expected sum(Zones/Zone[ZoneType="conditioned"]/Spaces/Space/FloorArea) to be equal to BuildingSummary/BuildingConstruction/ConditionedFloorArea'],
                            'vehicle-ev-multiple-BEV' => ['Expected 0 or 1 element(s) for xpath: Vehicle/VehicleType/BatteryElectricVehicle [context: /HPXML/Building/BuildingDetails/Systems/Vehicles, id: "MyBuilding"]'],
                            'vehicle-ev-invalid-fuel-economy-units' => ['Expected ../../FuelEconomyCombined/Units to be "kWh/mile" or "mile/kWh" or "mpge" [context: /HPXML/Building/BuildingDetails/Systems/Vehicles/Vehicle/VehicleType/BatteryElectricVehicle, id: "Vehicle1"]'],
                            'water-heater-location' => ['A location is specified as "crawlspace - vented" but no surfaces were found adjacent to this space type.'],
                            'water-heater-location-other' => ["Expected Location to be 'conditioned space' or 'basement - unconditioned' or 'basement - conditioned' or 'attic - unvented' or 'attic - vented' or 'garage' or 'crawlspace - unvented' or 'crawlspace - vented' or 'crawlspace - conditioned' or 'other exterior' or 'other housing unit' or 'other heated space' or 'other multifamily buffer space' or 'other non-freezing space'"],
                            'water-heater-recovery-efficiency' => ['Expected RecoveryEfficiency to be greater than EnergyFactor'],
                            'wrong-infiltration-method-blower-door' => ['Expected 1 element(s) for xpath: Enclosure/AirInfiltration/AirInfiltrationMeasurement[BuildingAirLeakage/h:AirLeakage | EffectiveLeakageArea | SpecificLeakageArea]'],
                            'wrong-infiltration-method-default-table' => ['Expected 1 element(s) for xpath: Enclosure/AirInfiltration/AirInfiltrationMeasurement[LeakinessDescription]'] }

    all_expected_errors.each_with_index do |(error_case, expected_errors), i|
      puts "[#{i + 1}/#{all_expected_errors.size}] Testing #{error_case}..."
      # Create HPXML object
      case error_case
      when 'boiler-invalid-afue'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-boiler-oil-only.xml')
        hpxml_bldg.heating_systems[0].heating_efficiency_afue *= 100.0
      when 'clothes-dryer-location'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.clothes_dryers[0].location = HPXML::LocationGarage
      when 'clothes-washer-location'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.clothes_washers[0].location = HPXML::LocationGarage
      when 'cooking-range-location'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.cooking_ranges[0].location = HPXML::LocationGarage
      when 'dehumidifier-fraction-served'
        hpxml, hpxml_bldg = _create_hpxml('base-appliances-dehumidifier-multiple.xml')
        hpxml_bldg.dehumidifiers[-1].fraction_served = 0.6
      when 'dhw-frac-load-served'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-multiple.xml')
        hpxml_bldg.water_heating_systems[0].fraction_dhw_load_served = 0.35
      when 'dhw-invalid-ef-tank'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-gas-ef.xml')
        hpxml_bldg.water_heating_systems[0].energy_factor = 1.0
        hpxml_bldg.water_heating_systems[0].recovery_efficiency = nil
      when 'dhw-invalid-uef-tank-heat-pump'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump.xml')
        hpxml_bldg.water_heating_systems[0].uniform_energy_factor = 1.0
      when 'dishwasher-location'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.dishwashers[0].location = HPXML::LocationGarage
      when 'duct-leakage-cfm25'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[0].duct_leakage_value = -2
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_value = -3
      when 'duct-leakage-cfm50'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ducts-leakage-cfm50.xml')
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[0].duct_leakage_value = -2
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_value = -3
      when 'duct-leakage-percent'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[0].duct_leakage_units = HPXML::UnitsPercent
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_units = HPXML::UnitsPercent
      when 'duct-location'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationGarage
        hpxml_bldg.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationGarage
      when 'duct-location-unconditioned-space'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationUnconditionedSpace
        hpxml_bldg.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationUnconditionedSpace
      when 'emissions-electricity-schedule'
        hpxml, hpxml_bldg = _create_hpxml('base-misc-emissions.xml')
        hpxml.header.emissions_scenarios[0].elec_schedule_number_of_header_rows = -1
        hpxml.header.emissions_scenarios[0].elec_schedule_column_number = 0
      when 'enclosure-attic-missing-roof'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.roofs.reverse_each do |roof|
          roof.delete
        end
      when 'enclosure-basement-missing-exterior-foundation-wall'
        hpxml, hpxml_bldg = _create_hpxml('base-foundation-unconditioned-basement.xml')
        hpxml_bldg.foundation_walls.reverse_each do |foundation_wall|
          foundation_wall.delete
        end
      when 'enclosure-basement-missing-slab'
        hpxml, hpxml_bldg = _create_hpxml('base-foundation-unconditioned-basement.xml')
        hpxml_bldg.slabs.reverse_each do |slab|
          slab.delete
        end
      when 'enclosure-floor-area-exceeds-cfa'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.building_construction.conditioned_floor_area = 1348.8
      when 'enclosure-floor-area-exceeds-cfa2'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit.xml')
        hpxml_bldg.building_construction.conditioned_floor_area = 898.8
      when 'enclosure-garage-missing-exterior-wall'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-garage.xml')
        hpxml_bldg.walls.select { |w|
          w.interior_adjacent_to == HPXML::LocationGarage &&
            w.exterior_adjacent_to == HPXML::LocationOutside
        }.reverse_each do |wall|
          wall.delete
        end
      when 'enclosure-garage-missing-roof-ceiling'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-garage.xml')
        hpxml_bldg.floors.select { |w|
          w.interior_adjacent_to == HPXML::LocationGarage &&
            w.exterior_adjacent_to == HPXML::LocationAtticUnvented
        }.reverse_each do |floor|
          floor.delete
        end
      when 'enclosure-garage-missing-slab'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-garage.xml')
        hpxml_bldg.slabs.select { |w| w.interior_adjacent_to == HPXML::LocationGarage }.reverse_each do |slab|
          slab.delete
        end
      when 'enclosure-conditioned-missing-ceiling-roof'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.floors.reverse_each do |floor|
          floor.delete
        end
      when 'enclosure-conditioned-missing-exterior-wall'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.walls.reverse_each do |wall|
          next unless wall.interior_adjacent_to == HPXML::LocationConditionedSpace

          wall.delete
        end
      when 'enclosure-conditioned-missing-floor-slab'
        hpxml, hpxml_bldg = _create_hpxml('base-foundation-slab.xml')
        hpxml_bldg.slabs[0].delete
      when 'frac-sensible-latent-fuel-load-values'
        hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
        hpxml_bldg.fuel_loads[0].frac_sensible = -0.1
        hpxml_bldg.fuel_loads[0].frac_latent = -0.1
      when 'frac-sensible-latent-fuel-load-presence'
        hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
        hpxml_bldg.fuel_loads[0].frac_sensible = 1.0
        hpxml_bldg.fuel_loads[0].frac_latent = nil
      when 'frac-sensible-latent-plug-load-values'
        hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
        hpxml_bldg.plug_loads[0].frac_sensible = -0.1
        hpxml_bldg.plug_loads[0].frac_latent = -0.1
      when 'frac-sensible-latent-plug-load-presence'
        hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
        hpxml_bldg.plug_loads[0].frac_latent = 1.0
        hpxml_bldg.plug_loads[0].frac_sensible = nil
      when 'frac-total-fuel-load'
        hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
        hpxml_bldg.fuel_loads[0].frac_sensible = 0.8
        hpxml_bldg.fuel_loads[0].frac_latent = 0.3
      when 'frac-total-plug-load'
        hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
        hpxml_bldg.plug_loads[1].frac_sensible = 0.855
        hpxml_bldg.plug_loads[1].frac_latent = 0.245
      when 'furnace-invalid-afue'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.heating_systems[0].heating_efficiency_afue *= 100.0
      when 'generator-number-of-bedrooms-served'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-generator.xml')
        hpxml_bldg.generators[0].number_of_bedrooms_served = 3
      when 'generator-output-greater-than-consumption'
        hpxml, hpxml_bldg = _create_hpxml('base-misc-generators.xml')
        hpxml_bldg.generators[0].annual_consumption_kbtu = 1500
      when 'heat-pump-backup-sizing'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.header.heat_pump_backup_sizing_methodology = 'foobar'
      when 'heat-pump-separate-backup-inputs'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-furnace.xml')
        hpxml_bldg.heat_pumps[0].backup_heating_capacity = 12345
        hpxml_bldg.heat_pumps[0].backup_heating_efficiency_afue = 0.8
        hpxml_bldg.heat_pumps[0].backup_heating_autosizing_factor = 1.2
      when 'heat-pump-capacity-17f-value'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].heating_capacity_17F = hpxml_bldg.heat_pumps[0].heating_capacity + 1000.0
        hpxml_bldg.heat_pumps[0].heating_capacity_fraction_17F = nil
      when 'heat-pump-capacity-17f-presence'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].heating_capacity_17F = 0.5 * hpxml_bldg.heat_pumps[0].heating_capacity
        hpxml_bldg.heat_pumps[0].heating_capacity = nil
        hpxml_bldg.heat_pumps[0].heating_capacity_fraction_17F = nil
      when 'heat-pump-lockout-temperatures'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-lockout-temperatures.xml')
        hpxml_bldg.heat_pumps[0].compressor_lockout_temp = hpxml_bldg.heat_pumps[0].backup_heating_lockout_temp + 1
      when 'heat-pump-multiple-backup-systems'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml')
        hpxml_bldg.heating_systems << hpxml_bldg.heating_systems[0].dup
        hpxml_bldg.heating_systems[-1].id = 'HeatingSystem2'
        hpxml_bldg.heat_pumps[0].fraction_heat_load_served = 0.5
        hpxml_bldg.heat_pumps[0].fraction_cool_load_served = 0.5
        hpxml_bldg.heat_pumps << hpxml_bldg.heat_pumps[0].dup
        hpxml_bldg.heat_pumps[-1].id = 'HeatPump2'
        hpxml_bldg.heat_pumps[-1].primary_heating_system = false
        hpxml_bldg.heat_pumps[-1].primary_cooling_system = false
      when 'hvac-detailed-performance-bad-odbs'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-detailed-performance.xml')
        # For heating, test invalid ODB
        hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.add(
          outdoor_temperature: 7.0,
          capacity_description: HPXML::CapacityDescriptionMinimum,
          capacity: 1000.0,
          efficiency_cop: 0.7
        )
        hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.add(
          outdoor_temperature: 7.0,
          capacity_description: HPXML::CapacityDescriptionMaximum,
          capacity: 10000.0,
          efficiency_cop: 2.1
        )
        # For cooling, test invalid ODB
        hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.add(
          outdoor_temperature: 60.0,
          capacity_description: HPXML::CapacityDescriptionMinimum,
          capacity: 10000.0,
          efficiency_cop: 6.0
        )
        hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.add(
          outdoor_temperature: 60.0,
          capacity_description: HPXML::CapacityDescriptionMaximum,
          capacity: 20000.0,
          efficiency_cop: 7.0
        )
      when 'hvac-detailed-performance-inconsistent-capacities'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-detailed-performance.xml')
        hpxml_bldg.heat_pumps[0].heating_capacity = 10000
        hpxml_bldg.heat_pumps[0].cooling_capacity = 10000
        hpxml_bldg.heat_pumps[0].heating_capacity_17F = 1000
      when 'hvac-detailed-performance-inconsistent-capacity-fractions'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-detailed-performance-normalized-capacities.xml')
        hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data[1].capacity_fraction_of_nominal = 0.98
        hpxml_bldg.heat_pumps[0].heating_detailed_performance_data[1].capacity_fraction_of_nominal = 0.98
      when 'hvac-detailed-performance-incomplete-pair'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-detailed-performance.xml')
        hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.add(
          outdoor_temperature: 105.0,
          capacity_description: HPXML::CapacityDescriptionMinimum,
          capacity: 15000.0,
          efficiency_cop: 7
        )
        hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.add(
          outdoor_temperature: -2.0,
          capacity_description: HPXML::CapacityDescriptionMinimum,
          capacity: 1500.0,
          efficiency_cop: 0.7
        )
      when 'hvac-detailed-performance-invalid-data'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-detailed-performance.xml')
        min_dp_82F = hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMinimum && dp.outdoor_temperature == 82.0 }
        max_dp_82F = hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMaximum && dp.outdoor_temperature == 82.0 }
        min_dp_82F.efficiency_cop = 0.1 * max_dp_82F.efficiency_cop
        min_dp_95F = hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMinimum && dp.outdoor_temperature == 95.0 }
        max_dp_95F = hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMaximum && dp.outdoor_temperature == 95.0 }
        min_dp_95F.capacity = 1.1 * max_dp_95F.capacity
        min_dp_47F = hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMinimum && dp.outdoor_temperature == 47.0 }
        max_dp_47F = hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMaximum && dp.outdoor_temperature == 47.0 }
        min_dp_47F.efficiency_cop = 0.1 * max_dp_47F.efficiency_cop
        min_dp_5F = hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMinimum && dp.outdoor_temperature == 5.0 }
        max_dp_5F = hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionMaximum && dp.outdoor_temperature == 5.0 }
        min_dp_5F.capacity = 1.1 * max_dp_5F.capacity
        min_dp_5F.efficiency_cop = 2 * max_dp_5F.efficiency_cop
      when 'hvac-distribution-return-duct-leakage-missing'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-evap-cooler-only-ducted.xml')
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements[-1].delete
      when 'hvac-frac-load-served'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-multiple.xml')
        hpxml_bldg.heating_systems[0].fraction_heat_load_served += 0.1
        hpxml_bldg.cooling_systems[0].fraction_cool_load_served += 0.2
        hpxml_bldg.heating_systems[0].primary_system = true
        hpxml_bldg.cooling_systems[0].primary_system = true
        hpxml_bldg.heat_pumps[-1].primary_heating_system = false
        hpxml_bldg.heat_pumps[-1].primary_cooling_system = false
      when 'hvac-research-features-timestep-ten-mins'
        hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-research-features.xml')
        hpxml.header.timestep = 10
      when 'hvac-research-features-timestep-missing'
        hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-research-features.xml')
        hpxml.header.timestep = nil
      when 'hvac-research-features-onoff-thermostat-heat-load-fraction-partial'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-research-features.xml')
        hpxml_bldg.heat_pumps[0].fraction_heat_load_served = 0.5
      when 'hvac-research-features-onoff-thermostat-cool-load-fraction-partial'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-research-features.xml')
        hpxml_bldg.heat_pumps[0].fraction_cool_load_served = 0.5
      when 'hvac-research-features-onoff-thermostat-negative-value'
        hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-research-features.xml')
        hpxml.header.hvac_onoff_thermostat_deadband = -1.0
      when 'hvac-research-features-onoff-thermostat-two-heat-pumps'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-research-features.xml')
        hpxml_bldg.heat_pumps[0].fraction_cool_load_served = 0.5
        hpxml_bldg.heat_pumps[0].fraction_heat_load_served = 0.5
        hpxml_bldg.heat_pumps << hpxml_bldg.heat_pumps[0].dup
        hpxml_bldg.heat_pumps[-1].id = 'HeatPump2'
        hpxml_bldg.heat_pumps[-1].primary_heating_system = false
        hpxml_bldg.heat_pumps[-1].primary_cooling_system = false
      when 'hvac-gshp-invalid-bore-config'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-detailed-geothermal-loop.xml')
        hpxml_bldg.geothermal_loops[0].bore_config = 'Invalid'
      when 'hvac-gshp-invalid-bore-depth-low'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-detailed-geothermal-loop.xml')
        hpxml_bldg.geothermal_loops[0].bore_length = 78
      when 'hvac-gshp-invalid-bore-depth-high'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-detailed-geothermal-loop.xml')
        hpxml_bldg.geothermal_loops[0].bore_length = 501
      when 'hvac-gshp-autosized-count-not-rectangle'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-detailed-geothermal-loop.xml')
        hpxml_bldg.geothermal_loops[0].num_bore_holes = nil
      when 'hvac-invalid-fan-model-type'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].fan_motor_type = 'foo'
      when 'hvac-invalid-eer'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-seer-hspf.xml')
        hpxml_bldg.heat_pumps[0].cooling_efficiency_eer = hpxml_bldg.heat_pumps[0].cooling_efficiency_seer + 1
      when 'hvac-invalid-eer2'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].cooling_efficiency_eer2 = hpxml_bldg.heat_pumps[0].cooling_efficiency_seer2 + 1
      when 'hvac-location-heating-system'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-boiler-oil-only.xml')
        hpxml_bldg.heating_systems[0].location = HPXML::LocationBasementUnconditioned
      when 'hvac-location-cooling-system'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-central-ac-only-1-speed.xml')
        hpxml_bldg.cooling_systems[0].location = HPXML::LocationBasementUnconditioned
      when 'hvac-location-heat-pump'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].location = HPXML::LocationBasementUnconditioned
      when 'hvac-msac-not-var-speed'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-mini-split-air-conditioner-only-ductless.xml')
        hpxml_bldg.cooling_systems[0].compressor_type = HPXML::HVACCompressorTypeTwoStage
      when 'hvac-mshp-not-var-speed'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ductless.xml')
        hpxml_bldg.heat_pumps[0].compressor_type = HPXML::HVACCompressorTypeSingleStage
      when 'hvac-sizing-humidity-setpoint'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.header.manualj_humidity_setpoint = 50
      when 'hvac-sizing-daily-temp-range'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.header.manualj_daily_temp_range = 'foobar'
      when 'hvac-negative-crankcase-heater-watts'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.cooling_systems[0].crankcase_heater_watts = -10
      when 'incomplete-integrated-heating'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ptac-with-heating-electricity.xml')
        hpxml_bldg.cooling_systems[0].integrated_heating_system_fraction_heat_load_served = nil
      when 'invalid-airflow-defect-ratio'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ductless.xml')
        hpxml_bldg.heat_pumps[0].airflow_defect_ratio = -0.25
      when 'invalid-airflow-rates'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.heating_systems[0].heating_design_airflow_cfm = -1
        hpxml_bldg.cooling_systems[0].cooling_design_airflow_cfm = -1
      when 'invalid-assembly-effective-rvalue'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.walls[0].insulation_assembly_r_value = 0.0
      when 'invalid-battery-capacities-ah'
        hpxml, hpxml_bldg = _create_hpxml('base-pv-battery-ah.xml')
        hpxml_bldg.batteries[0].usable_capacity_ah = hpxml_bldg.batteries[0].nominal_capacity_ah
      when 'invalid-battery-capacities-kwh'
        hpxml, hpxml_bldg = _create_hpxml('base-pv-battery.xml')
        hpxml_bldg.batteries[0].usable_capacity_kwh = hpxml_bldg.batteries[0].nominal_capacity_kwh
      when 'invalid-calendar-year-low'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml.header.sim_calendar_year = 1575
      when 'invalid-calendar-year-high'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml.header.sim_calendar_year = 20000
      when 'invalid-clothes-dryer-cef'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.clothes_dryers[0].combined_energy_factor = 0
      when 'invalid-clothes-washer-imef'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.clothes_washers[0].integrated_modified_energy_factor = 0
      when 'invalid-cfis-addtl-runtime-mode'
        hpxml, hpxml_bldg = _create_hpxml('base-mechvent-cfis-control-type-timer.xml')
        hpxml_bldg.ventilation_fans[0].cfis_addtl_runtime_operating_mode = HPXML::CFISModeNone
        hpxml_bldg.ventilation_fans[0].fan_power = nil
      when 'invalid-dishwasher-ler'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.dishwashers[0].label_electric_rate = 0
      when 'invalid-duct-area-fractions'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-2stories.xml')
        hpxml_bldg.hvac_distributions[0].ducts[0].duct_fraction_area = 0.65
        hpxml_bldg.hvac_distributions[0].ducts[1].duct_fraction_area = 0.65
        hpxml_bldg.hvac_distributions[0].ducts[2].duct_fraction_area = 0.15
        hpxml_bldg.hvac_distributions[0].ducts[3].duct_fraction_area = 0.15
      when 'invalid-facility-type'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-laundry-room.xml')
        hpxml_bldg.building_construction.residential_facility_type = HPXML::ResidentialTypeSFD
      when 'invalid-foundation-wall-properties'
        hpxml, hpxml_bldg = _create_hpxml('base-foundation-unconditioned-basement-wall-insulation.xml')
        hpxml_bldg.foundation_walls[0].depth_below_grade = 9.0
        hpxml_bldg.foundation_walls[0].insulation_interior_distance_to_top = 12.0
        hpxml_bldg.foundation_walls[0].insulation_interior_distance_to_bottom = 10.0
      when 'invalid-ground-conductivity'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.site.ground_conductivity = 0.0
      when 'invalid-ground-diffusivity'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.site.ground_diffusivity = 0.0
      when 'invalid-heat-pump-capacity-fraction-17F'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].heating_capacity_17F = nil
        hpxml_bldg.heat_pumps[0].heating_capacity_fraction_17F = 1.5
      when 'invalid-heat-pump-capacity-fraction-17F-2'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].heating_capacity_17F = nil
        hpxml_bldg.heat_pumps[0].heating_capacity_fraction_17F = -1
      when 'invalid-hvac-installation-quality'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].airflow_defect_ratio = -99
        hpxml_bldg.heat_pumps[0].charge_defect_ratio = -99
      when 'invalid-hvac-installation-quality2'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].airflow_defect_ratio = 99
        hpxml_bldg.heat_pumps[0].charge_defect_ratio = 99
      when 'invalid-id2'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights.xml')
      when 'invalid-input-parameters'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml.header.transaction = 'modify'
        hpxml_bldg.site.site_type = 'mountain'
        hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].year = 2020
        hpxml_bldg.roofs.each do |roof|
          roof.radiant_barrier_grade = 4
        end
        hpxml_bldg.roofs[0].azimuth = 365
        hpxml_bldg.dishwashers[0].rated_annual_kwh = nil
        hpxml_bldg.dishwashers[0].energy_factor = 5.1
      when 'invalid-insulation-top'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.foundation_walls[0].insulation_interior_distance_to_top = -0.5
      when 'invalid-integrated-heating'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-central-ac-only-1-speed.xml')
        hpxml_bldg.cooling_systems[0].integrated_heating_system_fuel = HPXML::FuelTypeElectricity
        hpxml_bldg.cooling_systems[0].integrated_heating_system_efficiency_percent = 0.98
        hpxml_bldg.cooling_systems[0].integrated_heating_system_fraction_heat_load_served = 1.0
      when 'invalid-lighting-groups'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-garage.xml')
        [HPXML::LocationInterior, HPXML::LocationExterior, HPXML::LocationGarage].each do |ltg_loc|
          hpxml_bldg.lighting_groups.each do |lg|
            next unless lg.location == ltg_loc

            lg.delete
            break
          end
        end
      when 'invalid-lighting-groups2'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-garage.xml')
        [HPXML::LocationInterior, HPXML::LocationExterior, HPXML::LocationGarage].each do |ltg_loc|
          hpxml_bldg.lighting_groups.each do |lg|
            next unless lg.location == ltg_loc

            hpxml_bldg.lighting_groups << lg.dup
            hpxml_bldg.lighting_groups[-1].id = "LightingGroup#{hpxml_bldg.lighting_groups.size}"
            hpxml_bldg.lighting_groups[-1].fraction_of_units_in_location = 0.0
            break
          end
        end
      when 'invalid-natvent-availability'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.header.natvent_days_per_week = 8
      when 'invalid-natvent-availability2'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.header.natvent_days_per_week = -1
      when 'invalid-number-of-bedrooms-served-pv'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-pv.xml')
        hpxml_bldg.pv_systems[0].number_of_bedrooms_served = 3
      when 'invalid-number-of-bedrooms-served-recirc'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-water-heater-recirc.xml')
        hpxml_bldg.hot_water_distributions[0].shared_recirculation_number_of_bedrooms_served = 3
      when 'invalid-number-of-bedrooms-served-water-heater'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-water-heater.xml')
        hpxml_bldg.water_heating_systems[0].number_of_bedrooms_served = 3
      when 'invalid-number-of-conditioned-floors'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade = 3
      when 'invalid-number-of-conditioned-floors-above-grade'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade = 0
      when 'invalid-pilot-light-heating-system'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-floor-furnace-propane-only.xml')
        hpxml_bldg.heating_systems[0].heating_system_fuel = HPXML::FuelTypeElectricity
      when 'invalid-soil-type'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.site.soil_type = HPXML::SiteSoilTypeOther
      when 'invalid-shared-vent-in-unit-flowrate'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-mechvent.xml')
        hpxml_bldg.ventilation_fans[0].rated_flow_rate = 80
      when 'invalid-timestep'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml.header.timestep = 45
      when 'invalid-timezone-utcoffset-low'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.time_zone_utc_offset = -13
      when 'invalid-timezone-utcoffset-high'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.time_zone_utc_offset = 15
      when 'invalid-ventilation-fan'
        hpxml, hpxml_bldg = _create_hpxml('base-mechvent-exhaust.xml')
        hpxml_bldg.ventilation_fans[0].used_for_garage_ventilation = true
      when 'invalid-ventilation-recovery'
        hpxml, hpxml_bldg = _create_hpxml('base-mechvent-exhaust.xml')
        hpxml_bldg.ventilation_fans[0].sensible_recovery_efficiency = 0.72
        hpxml_bldg.ventilation_fans[0].total_recovery_efficiency = 0.48
      when 'invalid-water-heater-heating-capacity'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-gas.xml')
        hpxml_bldg.water_heating_systems[0].heating_capacity = 0
      when 'invalid-water-heater-heating-capacity2'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump.xml')
        hpxml_bldg.water_heating_systems[0].heating_capacity = 0
      when 'invalid-water-heater-stratified-tank-model'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-gas.xml')
        hpxml_bldg.water_heating_systems[0].tank_model_type = HPXML::WaterHeaterTankModelTypeStratified
      when 'invalid-whole-sfa-or-mf-building-sim'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml.header.whole_sfa_or_mf_building_sim = true
      when 'invalid-window-height'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-overhangs.xml')
        hpxml_bldg.windows[1].overhangs_distance_to_bottom_of_window = 1.0
      when 'leakiness-description-missing-year-built'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-infil-leakiness-description.xml')
        hpxml_bldg.building_construction.year_built = nil
      when 'lighting-fractions'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        int_cfl = hpxml_bldg.lighting_groups.find { |lg| lg.location == HPXML::LocationInterior && lg.lighting_type == HPXML::LightingTypeCFL }
        int_cfl.fraction_of_units_in_location = 0.8
      when 'manufactured-home-reference-duct'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationManufacturedHomeBelly
      when 'manufactured-home-reference-water-heater'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.water_heating_systems[0].location = HPXML::LocationManufacturedHomeBelly
      when 'manufactured-home-reference-floor'
        hpxml, hpxml_bldg = _create_hpxml('base-foundation-vented-crawlspace.xml')
        hpxml_bldg.floors.each do |floor|
          if floor.exterior_adjacent_to == HPXML::LocationCrawlspaceVented
            floor.exterior_adjacent_to = HPXML::LocationManufacturedHomeUnderBelly
            break
          end
        end
      when 'missing-attached-to-space-wall'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        hpxml_bldg.walls.find { |s| s.interior_adjacent_to == HPXML::LocationConditionedSpace }.attached_to_space_idref = nil
      when 'missing-attached-to-space-slab'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        hpxml_bldg.slabs.find { |s| s.interior_adjacent_to == HPXML::LocationBasementConditioned }.attached_to_space_idref = nil
      when 'missing-attached-to-zone'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        hpxml_bldg.hvac_systems[0].attached_to_zone_idref = nil
      when 'missing-cfis-supplemental-fan'
        hpxml, hpxml_bldg = _create_hpxml('base-mechvent-cfis-supplemental-fan-exhaust.xml')
        hpxml_bldg.ventilation_fans[1].delete
      when 'missing-distribution-cfa-served'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = nil
      when 'missing-duct-area'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = hpxml_bldg.building_construction.conditioned_floor_area
        hpxml_bldg.hvac_distributions[0].ducts[1].duct_fraction_area = nil
        hpxml_bldg.hvac_distributions[0].ducts[3].duct_fraction_area = 1.0
      when 'missing-duct-location'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_distributions[0].ducts[1].duct_location = nil
      when 'missing-elements'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.building_construction.number_of_conditioned_floors = nil
        hpxml_bldg.building_construction.conditioned_floor_area = nil
      when 'missing-epw-filepath-and-zipcode'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = nil
      when 'missing-hpwh-containment-volume'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump-confined-space.xml')
        hpxml_bldg.water_heating_systems[0].hpwh_containment_volume = nil
      when 'missing-inverter-idref'
        hpxml, hpxml_bldg = _create_hpxml('base-pv.xml')
        hpxml_bldg.inverters.add(id: 'Inverter1')
        hpxml_bldg.inverters.add(id: 'Inverter2')
      when 'missing-skylight-floor'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights.xml')
        hpxml_bldg.skylights[0].attached_to_floor_idref = nil
      when 'multifamily-common-space-extra-inputs'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-whole-building-common-spaces.xml')
        hpxml.buildings[1].foundation_walls[1].height = 8
        hpxml.buildings[1].floors[0].area = 20
        hpxml.buildings[1].rim_joists[1].area = 10
        hpxml.buildings[2].walls[1].area = 20
      when 'multifamily-common-space-whole-sfa-or-mf-building-sim-false'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-whole-building-common-spaces.xml')
        hpxml.header.whole_sfa_or_mf_building_sim = false
      when 'multifamily-reference-appliance'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.clothes_washers[0].location = HPXML::LocationOtherHousingUnit
      when 'multifamily-reference-duct'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationOtherMultifamilyBufferSpace
      when 'multifamily-reference-surface'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.floors << hpxml_bldg.floors[0].dup
        hpxml_bldg.floors[1].id = "Floor#{hpxml_bldg.floors.size}"
        hpxml_bldg.floors[1].insulation_id = "FloorInsulation#{hpxml_bldg.floors.size}"
        hpxml_bldg.floors[1].exterior_adjacent_to = HPXML::LocationOtherHeatedSpace
        hpxml_bldg.floors[1].floor_or_ceiling = HPXML::FloorOrCeilingCeiling
      when 'multifamily-reference-water-heater'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.water_heating_systems[0].location = HPXML::LocationOtherNonFreezingSpace
      when 'negative-autosizing-factors'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-autosize-factor.xml')
        hpxml_bldg.heat_pumps[0].heating_autosizing_factor = -0.5
        hpxml_bldg.heat_pumps[0].cooling_autosizing_factor = -1.2
        hpxml_bldg.heat_pumps[0].backup_heating_autosizing_factor = -0.1
      when 'negative-hpwh-containment-volume'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump-confined-space.xml')
        hpxml_bldg.water_heating_systems[0].hpwh_containment_volume = -10.0
      when 'panel-zero-total-breaker-spaces'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.electric_panels.add(id: 'ElectricPanel1',
                                       rated_total_spaces: 0)
      when 'panel-without-required-system'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.electric_panels.add(id: 'ElectricPanel1')
        hpxml_bldg.electric_panels[0].service_feeders.add(id: 'ServiceFeeder1',
                                                          type: HPXML::ElectricPanelLoadTypeHeating)
      when 'panel-with-unrequired-system'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.electric_panels.add(id: 'ElectricPanel1')
        hpxml_bldg.electric_panels[0].service_feeders.add(id: 'ServiceFeeder1',
                                                          type: HPXML::ElectricPanelLoadTypeLighting,
                                                          component_idrefs: [hpxml_bldg.lighting_groups[0].id])
      when 'panel-without-load-type'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.electric_panels.add(id: 'ElectricPanel1')
        hpxml_bldg.electric_panels[0].service_feeders.add(id: 'ServiceFeeder1')
      when 'panel-insufficient-voltage'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.electric_panels.add(id: 'ElectricPanel1',
                                       voltage: HPXML::ElectricPanelVoltage120)
        hpxml_bldg.electric_panels[0].branch_circuits.add(id: 'BranchCircuit1',
                                                          voltage: HPXML::ElectricPanelVoltage240)
      when 'panel-zero-meter-based'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.electric_panels.add(id: 'ElectricPanel1')
        hpxml.header.service_feeders_load_calculation_types = [HPXML::ElectricPanelLoadCalculationType2023ExistingDwellingMeterBased]
        hpxml_bldg.header.electric_panel_baseline_peak_power = 0
      when 'refrigerator-location'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.refrigerators[0].location = HPXML::LocationGarage
      when 'refrigerator-schedule'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.refrigerators[0].weekday_fractions = '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
        hpxml_bldg.refrigerators[0].constant_coefficients = '-0.487, -0.340, -0.370, -0.361, -0.515, -0.684, -0.471, -0.159, -0.079, -0.417, -0.411, -0.386, -0.240, -0.314, -0.160, -0.121, -0.469, -0.412, -0.091, 0.077, -0.118, -0.247, -0.445, -0.544'
      when 'solar-fraction-one'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-solar-fraction.xml')
        hpxml_bldg.solar_thermal_systems[0].solar_fraction = 1.0
      when 'sum-space-floor-area'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        hpxml_bldg.conditioned_spaces.each do |space|
          space.floor_area /= 2.0
        end
      when 'sum-space-floor-area2'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        hpxml_bldg.conditioned_spaces.each do |space|
          space.floor_area *= 2.0
        end
      when 'vehicle-ev-multiple-BEV'
        hpxml, hpxml_bldg = _create_hpxml('base-vehicle-ev-charger-scheduled.xml')
        hpxml_bldg.vehicles.add(id: 'ElectricVehicle2',
                                vehicle_type: HPXML::VehicleTypeBEV)
      when 'vehicle-ev-invalid-fuel-economy-units'
        hpxml, hpxml_bldg = _create_hpxml('base-vehicle-ev-charger-scheduled.xml')
        hpxml_bldg.vehicles[0].fuel_economy_units = 'mpg'
      when 'water-heater-location'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.water_heating_systems[0].location = HPXML::LocationCrawlspaceVented
      when 'water-heater-location-other'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.water_heating_systems[0].location = HPXML::LocationUnconditionedSpace
      when 'water-heater-recovery-efficiency'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-gas-ef.xml')
        hpxml_bldg.water_heating_systems[0].recovery_efficiency = hpxml_bldg.water_heating_systems[0].energy_factor
      when 'wrong-infiltration-method-blower-door'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-infil-leakiness-description.xml')
        hpxml_bldg.header.manualj_infiltration_method = HPXML::ManualJInfiltrationMethodBlowerDoor
      when 'wrong-infiltration-method-default-table'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.header.manualj_infiltration_method = HPXML::ManualJInfiltrationMethodDefaultTable
      else
        fail "Unhandled case: #{error_case}."
      end

      hpxml_doc = hpxml.to_doc()

      # Perform additional raw XML manipulation
      if error_case == 'invalid-id2'
        element = XMLHelper.get_element(hpxml_doc, '/HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight/SystemIdentifier')
        XMLHelper.delete_attribute(element, 'id')
      end

      # Test against schematron
      XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)
      _test_schema_and_schematron_validation(@tmp_hpxml_path, hpxml_doc, expected_errors: expected_errors, test_name: error_case)
    end
  end

  # Test warnings are correctly triggered during the XSD schema or Schematron validation
  def test_schema_schematron_warning_messages
    # Test case => Warning message(s)
    all_expected_warnings = { 'battery-pv-output-power-low' => ['Max power output should typically be greater than or equal to 500 W.',
                                                                'Max power output should typically be greater than or equal to 500 W.',
                                                                'Rated power output should typically be greater than or equal to 1000 W.'],
                              'dhw-capacities-low' => ['Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                       'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                       'No space cooling specified, the model will not include space cooling energy use.'],
                              'dhw-efficiencies-low' => ['EnergyFactor should typically be greater than or equal to 0.45.',
                                                         'EnergyFactor should typically be greater than or equal to 0.45.',
                                                         'EnergyFactor should typically be greater than or equal to 0.45.',
                                                         'EnergyFactor should typically be greater than or equal to 0.45.',
                                                         'No space cooling specified, the model will not include space cooling energy use.'],
                              'dhw-setpoint-low' => ['Hot water setpoint should typically be greater than or equal to 110 deg-F.'],
                              'erv-atre-low' => ['Adjusted total recovery efficiency should typically be at least half of the adjusted sensible recovery efficiency.'],
                              'erv-tre-low' => ['Total recovery efficiency should typically be at least half of the sensible recovery efficiency.'],
                              'ev-charging-methods' => ['Electric vehicle charging was specified as both a PlugLoad and a Vehicle, the latter will be ignored.'],
                              'fuel-load-type-other' => ["Fuel load type 'other' is not currently handled, the fuel load will not be modeled."],
                              'garage-ventilation' => ['Ventilation fans for the garage are not currently modeled.'],
                              'heat-pump-defrost-backup' => ['BackupHeatingActiveDuringDefrost does not apply when system has separate backup heating'],
                              'heat-pump-low-backup-switchover-temp' => ['BackupHeatingSwitchoverTemperature is below 30 deg-F; this may result in significant unmet hours if the heat pump does not have sufficient capacity.'],
                              'heat-pump-low-backup-lockout-temp' => ['BackupHeatingLockoutTemperature is below 30 deg-F; this may result in significant unmet hours if the heat pump does not have sufficient capacity.'],
                              'hvac-dse-low' => ['Heating DSE should typically be greater than or equal to 0.5.',
                                                 'Cooling DSE should typically be greater than or equal to 0.5.'],
                              'hvac-capacities-low' => ['Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Cooling capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Cooling capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Cooling capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Cooling capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Cooling capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Cooling capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Backup heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Backup heating capacity should typically be greater than or equal to 1000 Btu/hr.',
                                                        'Backup heating capacity should typically be greater than or equal to 1000 Btu/hr.'],
                              'hvac-efficiencies-low' => ['Percent efficiency should typically be greater than or equal to 0.95.',
                                                          'AFUE should typically be greater than or equal to 0.5.',
                                                          'AFUE should typically be greater than or equal to 0.5.',
                                                          'AFUE should typically be greater than or equal to 0.5.',
                                                          'AFUE should typically be greater than or equal to 0.5.',
                                                          'AFUE should typically be greater than or equal to 0.5.',
                                                          'Percent efficiency should typically be greater than or equal to 0.5.',
                                                          'SEER should typically be greater than or equal to 8.',
                                                          'EER should typically be greater than or equal to 6.',
                                                          'EER should typically be greater than or equal to 6.',
                                                          'SEER should typically be greater than or equal to 8.',
                                                          'HSPF should typically be greater than or equal to 6.',
                                                          'SEER should typically be greater than or equal to 8.',
                                                          'EER should typically be greater than or equal to 6.',
                                                          'HSPF should typically be greater than or equal to 6.',
                                                          'EER should typically be greater than or equal to 6.',
                                                          'COP should typically be greater than or equal to 2.'],
                              'hvac-fan-inputs-ignored' => ['Fan power watts per cfm or fan motor type is not used for simulation of this HVAC system type.'],
                              'hvac-research-features-onoff-thermostat-temperature-capacitance-multiplier-one' => ['TemperatureCapacitanceMultiplier should typically be greater than 1.'],
                              'hvac-setpoints-high' => ['Heating setpoint should typically be less than or equal to 76 deg-F.',
                                                        'Cooling setpoint should typically be less than or equal to 86 deg-F.'],
                              'hvac-setpoints-low' => ['Heating setpoint should typically be greater than or equal to 58 deg-F.',
                                                       'Cooling setpoint should typically be greater than or equal to 68 deg-F.'],
                              'integrated-heating-efficiency-low' => ['Percent efficiency should typically be greater than or equal to 0.5.'],
                              'large-hpwh-containment-volume' => ['HPWHContainmentVolume should typically be less than 1500 cuft when the HPWH is in confined space'],
                              'lighting-groups-missing' => ['No interior lighting specified, the model will not include interior lighting energy use.',
                                                            'No exterior lighting specified, the model will not include exterior lighting energy use.',
                                                            'No garage lighting specified, the model will not include garage lighting energy use.'],
                              'missing-attached-surfaces' => ['ResidentialFacilityType is single-family attached or apartment unit, but no attached surfaces were found. This may result in erroneous results (e.g., for infiltration).'],
                              'panel-max-current-rating-high' => ['MaxCurrentRating should typically be less than or equal to 400.'],
                              'plug-load-type-sauna' => ["Plug load type 'sauna' is not currently handled, the plug load will not be modeled."],
                              'plug-load-type-aquarium' => ["Plug load type 'aquarium' is not currently handled, the plug load will not be modeled."],
                              'plug-load-type-water-bed' => ["Plug load type 'water bed' is not currently handled, the plug load will not be modeled."],
                              'plug-load-type-space-heater' => ["Plug load type 'space heater' is not currently handled, the plug load will not be modeled."],
                              'plug-load-type-computer' => ["Plug load type 'computer' is not currently handled, the plug load will not be modeled."],
                              'plug-load-type-tv-crt' => ["Plug load type 'TV CRT' is not currently handled, the plug load will not be modeled."],
                              'plug-load-type-tv-plasma' => ["Plug load type 'TV plasma' is not currently handled, the plug load will not be modeled."],
                              'portable-spa' => ['Portable spa is not currently handled, the portable spa will not be modeled.'],
                              'slab-ext-horiz-insul-without-perim-insul' => ['There is ExteriorHorizontalInsulation but no PerimeterInsulation, this may indicate an input error.'],
                              'slab-large-exposed-perimeter' => ['Slab exposed perimeter is more than twice the slab area, this may indicate an input error.'],
                              'slab-zero-exposed-perimeter' => ['Slab has zero exposed perimeter, this may indicate an input error.'],
                              'unit-multiplier' => ['NumberofUnits is greater than 1, indicating that the HPXML Building represents multiple dwelling units; simulation outputs will reflect this unit multiplier.'],
                              'vehicle-phev' => ["Vehicle type 'PlugInHybridElectricVehicle' is not currently handled, the vehicle will not be modeled."],
                              'window-exterior-shading-types' => ["Exterior shading type is 'external overhangs', but overhangs are explicitly defined; exterior shading type will be ignored.",
                                                                  "Exterior shading type is 'building', but neighbor buildings are explicitly defined; exterior shading type will be ignored."],
                              'wrong-units' => ['Thickness is greater than 12 inches; this may indicate incorrect units.',
                                                'Thickness is less than 1 inch; this may indicate incorrect units.',
                                                'Depth is greater than 72 feet; this may indicate incorrect units.',
                                                'DistanceToTopOfWindow is greater than 12 feet; this may indicate incorrect units.'] }

    all_expected_warnings.each_with_index do |(warning_case, expected_warnings), i|
      puts "[#{i + 1}/#{all_expected_warnings.size}] Testing #{warning_case}..."
      # Create HPXML object
      case warning_case
      when 'battery-pv-output-power-low'
        hpxml, hpxml_bldg = _create_hpxml('base-pv-battery.xml')
        hpxml_bldg.batteries[0].rated_power_output = 0.1
        hpxml_bldg.pv_systems[0].max_power_output = 0.1
        hpxml_bldg.pv_systems[1].max_power_output = 0.1
      when 'dhw-capacities-low'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-multiple.xml')
        hpxml_bldg.water_heating_systems.each do |water_heating_system|
          if [HPXML::WaterHeaterTypeStorage].include? water_heating_system.water_heater_type
            water_heating_system.heating_capacity = 0.1
          end
        end
      when 'dhw-efficiencies-low'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-multiple.xml')
        hpxml_bldg.water_heating_systems.each do |water_heating_system|
          if [HPXML::WaterHeaterTypeStorage,
              HPXML::WaterHeaterTypeTankless].include? water_heating_system.water_heater_type
            water_heating_system.energy_factor = 0.1
          end
        end
      when 'dhw-setpoint-low'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.water_heating_systems[0].temperature = 100
      when 'erv-atre-low'
        hpxml, hpxml_bldg = _create_hpxml('base-mechvent-erv-atre-asre.xml')
        hpxml_bldg.ventilation_fans[0].total_recovery_efficiency_adjusted = 0.1
      when 'fuel-load-type-other'
        hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
        hpxml_bldg.fuel_loads[0].fuel_load_type = HPXML::FuelLoadTypeOther
      when 'erv-tre-low'
        hpxml, hpxml_bldg = _create_hpxml('base-mechvent-erv.xml')
        hpxml_bldg.ventilation_fans[0].total_recovery_efficiency = 0.1
      when 'ev-charging-methods'
        hpxml, _hpxml_bldg = _create_hpxml('base-vehicle-ev-charger-plug-load-ev.xml')
      when 'garage-ventilation'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.ventilation_fans.add(id: 'VentilationFan1',
                                        used_for_garage_ventilation: true)
      when 'heat-pump-defrost-backup'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ductless-backup-furnace.xml')
        hpxml_bldg.heat_pumps[0].backup_heating_active_during_defrost = true
      when 'heat-pump-low-backup-switchover-temp'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].backup_heating_switchover_temp = 25.0
      when 'heat-pump-low-backup-lockout-temp'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-lockout-temperatures.xml')
        hpxml_bldg.heat_pumps[0].backup_heating_lockout_temp = 25.0
      when 'hvac-dse-low'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-dse.xml')
        hpxml_bldg.hvac_distributions[0].annual_heating_dse = 0.1
        hpxml_bldg.hvac_distributions[0].annual_cooling_dse = 0.1
      when 'hvac-capacities-low'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-multiple.xml')
        hpxml_bldg.hvac_systems.each do |hvac_system|
          if hvac_system.is_a? HPXML::HeatingSystem
            hvac_system.heating_capacity = 0.1
          elsif hvac_system.is_a? HPXML::CoolingSystem
            hvac_system.cooling_capacity = 0.1
          elsif hvac_system.is_a? HPXML::HeatPump
            hvac_system.heating_capacity = 0.1
            hvac_system.cooling_capacity = 0.1
            hvac_system.backup_heating_capacity = 0.1
          end
        end
      when 'hvac-efficiencies-low'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-multiple.xml')
        hpxml_bldg.hvac_systems.each do |hvac_system|
          if hvac_system.is_a? HPXML::HeatingSystem
            case hvac_system.heating_system_type
            when HPXML::HVACTypeElectricResistance,
                 HPXML::HVACTypeStove
              hvac_system.heating_efficiency_percent = 0.1
            when HPXML::HVACTypeFurnace,
                   HPXML::HVACTypeWallFurnace,
                   HPXML::HVACTypeBoiler
              hvac_system.heating_efficiency_afue = 0.1
            end
          elsif hvac_system.is_a? HPXML::CoolingSystem
            case hvac_system.cooling_system_type
            when HPXML::HVACTypeCentralAirConditioner
              hvac_system.cooling_efficiency_seer = 0.1
              hvac_system.cooling_efficiency_eer = 0.1
            when HPXML::HVACTypeRoomAirConditioner
              hvac_system.cooling_efficiency_eer = 0.1
            end
          elsif hvac_system.is_a? HPXML::HeatPump
            case hvac_system.heat_pump_type
            when HPXML::HVACTypeHeatPumpAirToAir,
                HPXML::HVACTypeHeatPumpMiniSplit
              hvac_system.cooling_efficiency_seer = 0.1
              hvac_system.cooling_efficiency_eer = 0.1
              hvac_system.heating_efficiency_hspf = 0.1
            when HPXML::HVACTypeHeatPumpGroundToAir
              hvac_system.cooling_efficiency_eer = 0.1
              hvac_system.heating_efficiency_cop = 0.1
            end
          end
        end
      when 'hvac-fan-inputs-ignored'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-pthp.xml')
        hpxml_bldg.heat_pumps[0].fan_watts_per_cfm = 0.45
        hpxml_bldg.heat_pumps[0].fan_motor_type = HPXML::HVACFanMotorTypePSC
      when 'hvac-setpoints-high'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_controls[0].heating_setpoint_temp = 100
        hpxml_bldg.hvac_controls[0].cooling_setpoint_temp = 100
      when 'hvac-setpoints-low'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_controls[0].heating_setpoint_temp = 0
        hpxml_bldg.hvac_controls[0].cooling_setpoint_temp = 0
      when 'integrated-heating-efficiency-low'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ptac-with-heating-electricity.xml')
        hpxml_bldg.cooling_systems[0].integrated_heating_system_efficiency_percent = 0.4
      when 'large-hpwh-containment-volume'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump-confined-space.xml')
        hpxml_bldg.water_heating_systems[0].hpwh_containment_volume = 2000.0
      when 'lighting-groups-missing'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-garage.xml')
        hpxml_bldg.lighting_groups.reverse_each do |lg|
          lg.delete
        end
      when 'missing-attached-surfaces'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.building_construction.residential_facility_type = HPXML::ResidentialTypeSFA
        hpxml_bldg.air_infiltration_measurements[0].infiltration_type = HPXML::InfiltrationTypeUnitExterior
      when 'hvac-research-features-onoff-thermostat-temperature-capacitance-multiplier-one'
        hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-research-features.xml')
        hpxml.header.temperature_capacitance_multiplier = 1
      when 'panel-max-current-rating-high'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.electric_panels.add(id: 'ElectricPanel1',
                                       max_current_rating: 450.0)
      when 'plug-load-type-sauna'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.plug_loads[0].plug_load_type = HPXML::PlugLoadTypeSauna
      when 'plug-load-type-aquarium'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.plug_loads[0].plug_load_type = HPXML::PlugLoadTypeAquarium
      when 'plug-load-type-water-bed'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.plug_loads[0].plug_load_type = HPXML::PlugLoadTypeWaterBed
      when 'plug-load-type-space-heater'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.plug_loads[0].plug_load_type = HPXML::PlugLoadTypeSpaceHeater
      when 'plug-load-type-computer'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.plug_loads[0].plug_load_type = HPXML::PlugLoadTypeComputer
      when 'plug-load-type-tv-crt'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.plug_loads[0].plug_load_type = HPXML::PlugLoadTypeTelevisionCRT
      when 'plug-load-type-tv-plasma'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.plug_loads[0].plug_load_type = HPXML::PlugLoadTypeTelevisionPlasma
      when 'portable-spa'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.portable_spas.add(id: 'PorableSpa')
      when 'slab-zero-exposed-perimeter'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.slabs[0].exposed_perimeter = 0
      when 'slab-ext-horiz-insul-without-perim-insul'
        hpxml, hpxml_bldg = _create_hpxml('base-foundation-slab-exterior-horizontal-insulation.xml')
        hpxml_bldg.slabs[0].perimeter_insulation_r_value = 0
      when 'slab-large-exposed-perimeter'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.slabs[0].exposed_perimeter = hpxml_bldg.slabs[0].area * 2 + 1
      when 'unit-multiplier'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.building_construction.number_of_units = 5
      when 'vehicle-phev'
        hpxml, hpxml_bldg = _create_hpxml('base-vehicle-ev-charger-scheduled.xml')
        hpxml_bldg.vehicles[0].vehicle_type = 'PlugInHybridElectricVehicle'
      when 'window-exterior-shading-types'
        hpxml, _hpxml_bldg = _create_hpxml('base-enclosure-windows-shading-types-detailed.xml')
      when 'wrong-units'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-overhangs.xml')
        hpxml_bldg.slabs[0].thickness = 0.5
        hpxml_bldg.foundation_walls[0].thickness = 72.0
        hpxml_bldg.windows[0].overhangs_depth = 120.0
        hpxml_bldg.windows[0].overhangs_distance_to_top_of_window = 24.0
        hpxml_bldg.windows[0].overhangs_distance_to_bottom_of_window = 48.0
      else
        fail "Unhandled case: #{warning_case}."
      end

      hpxml_doc = hpxml.to_doc()

      # Test against schematron
      XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)
      _test_schema_and_schematron_validation(@tmp_hpxml_path, hpxml_doc, expected_warnings: expected_warnings)
    end
  end

  # Test errors are correctly triggered in the HPXMLtoOpenStudio ruby code
  def test_ruby_error_messages
    # Test case => Error message(s)
    all_expected_errors = { 'battery-bad-values-max-greater-than-one' => ["Schedule value for column 'battery' must be less than or equal to 1."],
                            'battery-bad-values-min-less-than-neg-one' => ["Schedule value for column 'battery' must be greater than or equal to -1."],
                            'cfis-with-hydronic-distribution' => ["Attached HVAC distribution system 'HVACDistribution1' cannot be hydronic for ventilation fan 'VentilationFan1'."],
                            'cfis-invalid-supplemental-fan' => ["CFIS supplemental fan 'VentilationFan2' must be of type 'supply only' or 'exhaust only'."],
                            'cfis-invalid-supplemental-fan2' => ["CFIS supplemental fan 'VentilationFan2' must be set as used for whole building ventilation."],
                            'cfis-invalid-supplemental-fan3' => ["CFIS supplemental fan 'VentilationFan2' cannot be a shared system."],
                            'cfis-invalid-supplemental-fan4' => ["CFIS supplemental fan 'VentilationFan2' cannot have HoursInOperation specified."],
                            'dehumidifier-setpoints' => ['All dehumidifiers must have the same setpoint but multiple setpoints were specified.'],
                            'desuperheater-with-detailed-setpoints' => ["Detailed setpoints for water heating system 'WaterHeatingSystem1' is not currently supported for desuperheaters."],
                            'duct-lto-cfm25-cond-space' => ['Duct leakage to outside is too high; double-check inputs.'],
                            'duct-lto-cfm25-uncond-space' => ['Duct leakage to outside is too high; double-check inputs.'],
                            'duct-lto-cfm50-cond-space' => ['Duct leakage to outside is too high; double-check inputs.'],
                            'duct-lto-cfm50-uncond-space' => ['Duct leakage to outside is too high; double-check inputs.'],
                            'duct-lto-percent-cond-space' => ['Duct leakage to outside is too high; double-check inputs.'],
                            'duct-lto-percent-uncond-space' => ['Duct leakage to outside is too high; double-check inputs.'],
                            'duplicate-id' => ["Element 'SystemIdentifier', attribute 'id': 'PlugLoad1' is not a valid value of the atomic type 'xs:ID'."],
                            'emissions-duplicate-names' => ['Found multiple Emissions Scenarios with the Scenario Name='],
                            'emissions-wrong-columns' => ['Emissions File has too few columns. Cannot find column number'],
                            'emissions-wrong-filename' => ["Emissions File file path 'invalid-wrong-filename.csv' does not exist."],
                            'emissions-wrong-rows' => ['Emissions File has invalid number of rows'],
                            'geothermal-loop-multiple-attached-hps' => ["Multiple heat pumps found attached to geothermal loop 'GeothermalLoop1'."],
                            'heat-pump-backup-system-load-fraction' => ['Heat pump backup system cannot have a fraction heat load served specified.'],
                            'heat-pump-switchover-temp-elec-backup' => ['Switchover temperature should only be used for a heat pump with fossil fuel backup; use compressor lockout temperature instead.'],
                            'heat-pump-lockout-temps-elec-backup' => ['Similar compressor/backup lockout temperatures should only be used for a heat pump with fossil fuel backup.'],
                            'hvac-attached-to-uncond-zone' => ["HVAC system 'HeatingSystem1' is attached to an unconditioned zone."],
                            'hvac-distribution-different-zones' => ["HVAC distribution system 'HVACDistribution1' has HVAC systems attached to different zones."],
                            'hvac-distribution-multiple-attached-cooling' => ["Multiple cooling systems found attached to distribution system 'HVACDistribution2'."],
                            'hvac-distribution-multiple-attached-heating' => ["Multiple heating systems found attached to distribution system 'HVACDistribution1'."],
                            'hvac-dse-multiple-attached-cooling' => ["Multiple cooling systems found attached to distribution system 'HVACDistribution1'."],
                            'hvac-dse-multiple-attached-heating' => ["Multiple heating systems found attached to distribution system 'HVACDistribution1'."],
                            'hvac-research-features-onoff-thermostat-num-speeds-greater-than-two' => ['On-off thermostat deadband currently is only supported for single speed or two speed air source systems.'],
                            'hvac-research-features-num-unit-greater-than-one' => ['NumberofUnits greater than 1 is not supported for on-off thermostat deadband.',
                                                                                   'NumberofUnits greater than 1 is not supported for multi-staging backup coil.'],
                            'hvac-gshp-invalid-num-bore-holes' => ["Number of bore holes (5) with borefield configuration 'Lopsided U' not supported."],
                            'hvac-inconsistent-fan-powers' => ["Fan powers for heating system 'HeatingSystem1' (0.45 W/cfm) and cooling system 'CoolingSystem1' (0.55 W/cfm) are attached to a single distribution system and therefore must be the same."],
                            'hvac-inconsistent-fan-motor types' => ["Fan motor types for heating system 'HeatingSystem1' (PSC) and cooling system 'CoolingSystem1' (BPM) are attached to a single distribution system and therefore must be the same."],
                            'hvac-invalid-distribution-system-type' => ["Incorrect HVAC distribution system type for HVAC type: 'Furnace'. Should be one of: ["],
                            'hvac-shared-boiler-multiple' => ['More than one shared heating system found.'],
                            'hvac-shared-chiller-multiple' => ['More than one shared cooling system found.'],
                            'hvac-shared-chiller-negative-seer-eq' => ["Negative SEER equivalent calculated for cooling system 'CoolingSystem1', double-check inputs."],
                            'inconsistent-belly-wing-skirt-present' => ['All belly-and-wing foundations must have the same SkirtPresent.'],
                            'inconsistent-cond-zone-assignment' => ["Surface 'Floor1' is not adjacent to conditioned space but was assigned to conditioned Zone 'ConditionedZone'."],
                            'inconsistent-cond-basement-within-infiltration-volume' => ['All conditioned basements must have the same WithinInfiltrationVolume value.'],
                            'inconsistent-uncond-basement-within-infiltration-volume' => ['All unconditioned basements must have the same WithinInfiltrationVolume value.'],
                            'inconsistent-unvented-attic-within-infiltration-volume' => ['All unvented attics must have the same WithinInfiltrationVolume value.'],
                            'inconsistent-unvented-crawl-within-infiltration-volume' => ['All unvented crawlspaces must have the same WithinInfiltrationVolume value.'],
                            'inconsistent-cond-crawl-within-infiltration-volume' => ['All conditioned crawlspaces must have the same WithinInfiltrationVolume value.'],
                            'inconsistent-vented-attic-ventilation-rate' => ['All vented attics must have the same VentilationRate.'],
                            'inconsistent-vented-attic-ventilation-rate2' => ['All vented attics must have the same VentilationRate.'],
                            'inconsistent-vented-crawl-ventilation-rate' => ['All vented crawlspaces must have the same VentilationRate.'],
                            'invalid-battery-capacity-units' => ["UsableCapacity and NominalCapacity for Battery 'Battery1' must be in the same units."],
                            'invalid-battery-capacity-units2' => ["UsableCapacity and NominalCapacity for Battery 'Battery1' must be in the same units."],
                            'invalid-datatype-boolean' => ["Element 'RadiantBarrier': 'FOOBAR' is not a valid value of the atomic type 'xs:boolean'"],
                            'invalid-datatype-integer' => ["Element 'NumberofBedrooms': '2.5' is not a valid value of the atomic type 'IntegerGreaterThanOrEqualToZero_simple'."],
                            'invalid-datatype-float' => ["Cannot convert 'FOOBAR' to float for EmissionsScenario/EmissionsFactor[FuelType='electricity']/Value."],
                            'invalid-daylight-saving' => ['Daylight Saving End Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'invalid-distribution-cfa-served' => ['The total conditioned floor area served by the HVAC distribution system(s) for heating is larger than the conditioned floor area of the building.',
                                                                  'The total conditioned floor area served by the HVAC distribution system(s) for cooling is larger than the conditioned floor area of the building.'],
                            'invalid-epw-filepath' => ["foo.epw' could not be found."],
                            'invalid-holiday-lighting-dates' => ['Exterior Holiday Lighting Begin Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'invalid-id' => ["Element 'SystemIdentifier', attribute 'id': '' is not a valid value of the atomic type 'xs:ID'."],
                            'invalid-neighbor-shading-azimuth' => ['A neighbor building has an azimuth (145) not equal to the azimuth of any wall.'],
                            'invalid-ptac-dse' => ["HVAC type 'packaged terminal air conditioner' must have a heating and/or cooling DSE of 1."],
                            'invalid-pthp-dse' => ["HVAC type 'packaged terminal heat pump' must have a heating and/or cooling DSE of 1."],
                            'invalid-relatedhvac-dhw-indirect' => ["RelatedHVACSystem 'HeatingSystem_bad' not found for water heating system 'WaterHeatingSystem1'"],
                            'invalid-relatedhvac-desuperheater' => ["RelatedHVACSystem 'CoolingSystem_bad' not found for water heating system 'WaterHeatingSystem1'."],
                            'invalid-schema-version' => ["Element 'HPXML', attribute 'schemaVersion'"],
                            'invalid-skylights-physical-properties' => ["Could not lookup UFactor and SHGC for skylight 'Skylight2'."],
                            'invalid-runperiod' => ['Run Period End Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'invalid-shading-season' => ['Shading Summer Season End Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'invalid-unavailable-period' => ['Unavailable Period End Day of Month (31) must be one of: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30.'],
                            'invalid-windows-physical-properties' => ["Could not lookup UFactor and SHGC for window 'Window3'."],
                            'leap-year-TMY' => ['Specified a leap year (2008) but weather data has 8760 hours.'],
                            'multifamily-common-space-wrong-sameas-id' => ["Sameas object 'Foo' not found."],
                            'multifamily-inter-unit-heat-transfer-wrong-sameas-object-floor' => ["'Floor4_1' reference the wrong object type with sameas id 'Wall1_2'."],
                            'multifamily-inter-unit-heat-transfer-wrong-sameas-object-rim-joist' => ["'RimJoist3' reference the wrong object type with sameas id 'Wall1_2'."],
                            'multifamily-inter-unit-heat-transfer-wrong-sameas-object-foundation-wall' => ["'FoundationWall3' reference the wrong object type with sameas id 'Wall1_2'."],
                            'multifamily-inter-unit-heat-transfer-wrong-sameas-object-wall' => ["'Wall3' reference the wrong object type with sameas id 'Floor1_2'."],
                            'multifamily-inter-unit-heat-transfer-same-building' => ["'Wall3' sameas references the object in the same building 'UnitWithUnonditionedBasement'."],
                            'multifamily-inter-unit-heat-transfer-multiple-reference' => ["'Wall2_3' is referenced by multiple objects."],
                            'net-area-negative-wall' => ["Calculated a negative net surface area for surface 'Wall1'."],
                            'net-area-negative-roof-floor' => ["Calculated a negative net surface area for surface 'Roof1'.",
                                                               "Calculated a negative net surface area for surface 'Floor1'."],
                            'orphaned-geothermal-loop' => ["Geothermal loop 'GeothermalLoop1' found but no heat pump attached to it."],
                            'orphaned-hvac-distribution' => ["Distribution system 'HVACDistribution1' found but no HVAC system attached to it."],
                            'panel-wrong-system-type' => ["One or more referenced components 'WaterHeatingSystem1' not valid for service feeder 'ServiceFeeder1' with LoadType 'heating'."],
                            'refrigerators-multiple-primary' => ['More than one refrigerator designated as the primary.'],
                            'refrigerators-no-primary' => ['Could not find a primary refrigerator.'],
                            'repeated-relatedhvac-dhw-indirect' => ["RelatedHVACSystem 'HeatingSystem1' is attached to multiple water heating systems."],
                            'repeated-relatedhvac-desuperheater' => ["RelatedHVACSystem 'CoolingSystem1' is attached to multiple water heating systems."],
                            'schedule-detailed-bad-values-max-not-one' => ["Schedule max value for column 'lighting_interior' must be 1."],
                            'schedule-detailed-bad-values-negative' => ["Schedule min value for column 'lighting_interior' must be non-negative."],
                            'schedule-detailed-bad-values-non-numeric' => ["Schedule value must be numeric for column 'lighting_interior'."],
                            'schedule-detailed-bad-values-mode-negative' => ["Schedule value for column 'water_heater_operating_mode' must be either 0 or 1."],
                            'schedule-detailed-duplicate-columns' => ["Schedule column name 'occupants' is duplicated."],
                            'schedule-detailed-wrong-filename' => ["Schedules file path 'invalid-wrong-filename.csv' does not exist."],
                            'schedule-detailed-wrong-rows' => ["Schedule has invalid number of rows (8759) for column 'occupants'. Must be one of: 8760, 17520, 26280, 35040, 43800, 52560, 87600, 105120, 131400, 175200, 262800, 525600."],
                            'skylight-not-connected-to-cond-space' => ["Skylight 'Skylight1' not connected to conditioned space; if it's a skylight with a shaft, use AttachedToFloor to connect it to conditioned space."],
                            'solar-thermal-system-with-combi-tankless' => ["Water heating system 'WaterHeatingSystem1' connected to solar thermal system 'SolarThermalSystem1' cannot be a space-heating boiler."],
                            'solar-thermal-system-with-desuperheater' => ["Water heating system 'WaterHeatingSystem1' connected to solar thermal system 'SolarThermalSystem1' cannot be attached to a desuperheater."],
                            'solar-thermal-system-with-dhw-indirect' => ["Water heating system 'WaterHeatingSystem1' connected to solar thermal system 'SolarThermalSystem1' cannot be a space-heating boiler."],
                            'surface-attached-to-uncond-space' => ["Surface 'Wall2Space2' is attached to the space of an unconditioned zone."],
                            'surface-attached-to-uncond-space2' => ["Surface 'Slab2Space4' is attached to the space of an unconditioned zone."],
                            'unattached-cfis' => ["Attached HVAC distribution system 'foobar' not found for ventilation fan 'VentilationFan1'."],
                            'unattached-door' => ["Attached wall 'foobar' not found for door 'Door1'."],
                            'unattached-gshp' => ["Attached geothermal loop 'foobar' not found for heat pump 'HeatPump1'."],
                            'unattached-hvac-distribution' => ["Attached HVAC distribution system 'foobar' not found for HVAC system 'HeatingSystem1'."],
                            'unattached-pv-system' => ["Attached inverter 'foobar' not found for pv system 'PVSystem1'."],
                            'unattached-skylight' => ["Attached roof 'foobar' not found for skylight 'Skylight1'.",
                                                      "Attached floor 'foobar' not found for skylight 'Skylight1'."],
                            'unattached-solar-thermal-system' => ["Attached water heating system 'foobar' not found for solar thermal system 'SolarThermalSystem1'."],
                            'unattached-shared-clothes-washer-dhw-distribution' => ["Attached hot water distribution 'foobar' not found for clothes washer"],
                            'unattached-shared-clothes-washer-water-heater' => ["Attached water heating system 'foobar' not found for clothes washer"],
                            'unattached-shared-dishwasher-dhw-distribution' => ["Attached hot water distribution 'foobar' not found for dishwasher"],
                            'unattached-shared-dishwasher-water-heater' => ["Attached water heating system 'foobar' not found for dishwasher"],
                            'unattached-window' => ["Attached wall 'foobar' not found for window 'Window1'."],
                            'unattached-zone' => ["Attached zone 'foobar' not found for heating system 'HeatingSystem1'.",
                                                  "Attached zone 'foobar' not found for cooling system 'CoolingSystem1'."],
                            'unavailable-period-missing-column' => ["Could not find column='foobar' in unavailable_periods.csv."],
                            'unique-objects-vary-across-units-epw' => ['Weather station EPW filepath has different values across dwelling units.'],
                            'unique-objects-vary-across-units-dst' => ['Unique object (OS:RunPeriodControl:DaylightSavingTime) has different values across dwelling units.'],
                            'unique-objects-vary-across-units-tmains' => ['Unique object (OS:Site:WaterMainsTemperature) has different values across dwelling units.'],
                            'whole-mf-building-batteries' => ['Modeling batteries for whole SFA/MF buildings is not currently supported.'],
                            'whole-mf-building-dehumidifiers-unit-multiplier' => ['NumberofUnits greater than 1 is not supported for dehumidifiers.'],
                            'whole-mf-building-gshps-unit-multiplier' => ['NumberofUnits greater than 1 is not supported for ground-to-air heat pumps.'] }

    all_expected_errors.each_with_index do |(error_case, expected_errors), i|
      puts "[#{i + 1}/#{all_expected_errors.size}] Testing #{error_case}..."
      building_id = nil
      # Create HPXML object
      case error_case
      when 'battery-bad-values-max-greater-than-one'
        hpxml, hpxml_bldg = _create_hpxml('base-battery-scheduled.xml')
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml_bldg.header.schedules_filepaths[0]))
        csv_data[1][csv_data[0].index('battery')] = 1.1
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml_bldg.header.schedules_filepaths = [@tmp_csv_path]
      when 'battery-bad-values-min-less-than-neg-one'
        hpxml, hpxml_bldg = _create_hpxml('base-battery-scheduled.xml')
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml_bldg.header.schedules_filepaths[0]))
        csv_data[1][csv_data[0].index('battery')] = -1.1
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml_bldg.header.schedules_filepaths = [@tmp_csv_path]
      when 'cfis-with-hydronic-distribution'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-boiler-gas-only.xml')
        hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                        fan_type: HPXML::MechVentTypeCFIS,
                                        used_for_whole_building_ventilation: true,
                                        distribution_system_idref: hpxml_bldg.hvac_distributions[0].id)
      when 'cfis-invalid-supplemental-fan'
        hpxml, hpxml_bldg = _create_hpxml('base-mechvent-cfis-supplemental-fan-exhaust.xml')
        suppl_fan = hpxml_bldg.ventilation_fans.find { |f| f.is_cfis_supplemental_fan }
        suppl_fan.fan_type = HPXML::MechVentTypeBalanced
      when 'cfis-invalid-supplemental-fan2'
        hpxml, hpxml_bldg = _create_hpxml('base-mechvent-cfis-supplemental-fan-exhaust.xml')
        suppl_fan = hpxml_bldg.ventilation_fans.find { |f| f.is_cfis_supplemental_fan }
        suppl_fan.used_for_whole_building_ventilation = false
        suppl_fan.used_for_garage_ventilation = true
      when 'cfis-invalid-supplemental-fan3'
        hpxml, hpxml_bldg = _create_hpxml('base-mechvent-cfis-supplemental-fan-exhaust.xml')
        suppl_fan = hpxml_bldg.ventilation_fans.find { |f| f.is_cfis_supplemental_fan }
        suppl_fan.is_shared_system = true
        suppl_fan.fraction_recirculation = 0.0
        suppl_fan.in_unit_flow_rate = suppl_fan.tested_flow_rate / 2.0
      when 'cfis-invalid-supplemental-fan4'
        hpxml, hpxml_bldg = _create_hpxml('base-mechvent-cfis-supplemental-fan-exhaust.xml')
        suppl_fan = hpxml_bldg.ventilation_fans.find { |f| f.is_cfis_supplemental_fan }
        suppl_fan.hours_in_operation = 12.0
      when 'dehumidifier-setpoints'
        hpxml, hpxml_bldg = _create_hpxml('base-appliances-dehumidifier-multiple.xml')
        hpxml_bldg.dehumidifiers[-1].rh_setpoint = 0.55
      when 'desuperheater-with-detailed-setpoints'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-detailed-setpoints.xml')
        hpxml_bldg.water_heating_systems[0].uses_desuperheater = true
        hpxml_bldg.water_heating_systems[0].related_hvac_idref = hpxml_bldg.cooling_systems[0].id
      when 'duct-lto-cfm25-cond-space'
        hpxml, hpxml_bldg = _create_hpxml('base-atticroof-conditioned.xml')
        hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = hpxml_bldg.building_construction.conditioned_floor_area
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.each do |dlm|
          dlm.duct_leakage_units = HPXML::UnitsCFM25
          dlm.duct_leakage_value = 250.0
        end
        hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
          duct.duct_fraction_area = nil
          duct.duct_location = nil
        end
      when 'duct-lto-cfm25-uncond-space'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.each do |dlm|
          dlm.duct_leakage_value = 2000.0
        end
      when 'duct-lto-cfm50-cond-space'
        hpxml, hpxml_bldg = _create_hpxml('base-atticroof-conditioned.xml')
        hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = hpxml_bldg.building_construction.conditioned_floor_area
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.each do |dlm|
          dlm.duct_leakage_units = HPXML::UnitsCFM50
          dlm.duct_leakage_value = 500.0
        end
        hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
          duct.duct_fraction_area = nil
          duct.duct_location = nil
        end
      when 'duct-lto-cfm50-uncond-space'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ducts-leakage-cfm50.xml')
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.each do |dlm|
          dlm.duct_leakage_value = 4000.0
        end
      when 'duct-lto-percent-cond-space'
        hpxml, hpxml_bldg = _create_hpxml('base-atticroof-conditioned.xml')
        hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = hpxml_bldg.building_construction.conditioned_floor_area
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.each do |dlm|
          dlm.duct_leakage_units = HPXML::UnitsPercent
          dlm.duct_leakage_value = 0.0875
        end
        hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
          duct.duct_fraction_area = nil
          duct.duct_location = nil
        end
      when 'duct-lto-percent-uncond-space'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ducts-leakage-percent.xml')
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.each do |dlm|
          dlm.duct_leakage_value = 0.625
        end
      when 'duplicate-id'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.plug_loads[-1].id = hpxml_bldg.plug_loads[0].id
      when 'emissions-duplicate-names'
        hpxml, _hpxml_bldg = _create_hpxml('base-misc-emissions.xml')
        hpxml.header.emissions_scenarios << hpxml.header.emissions_scenarios[0].dup
      when 'emissions-wrong-columns'
        hpxml, _hpxml_bldg = _create_hpxml('base-misc-emissions.xml')
        scenario = hpxml.header.emissions_scenarios[1]
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), scenario.elec_schedule_filepath))
        csv_data[10] = [431.0] * (scenario.elec_schedule_column_number - 1)
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml.header.emissions_scenarios[1].elec_schedule_filepath = @tmp_csv_path
      when 'emissions-wrong-filename'
        hpxml, _hpxml_bldg = _create_hpxml('base-misc-emissions.xml')
        hpxml.header.emissions_scenarios[1].elec_schedule_filepath = 'invalid-wrong-filename.csv'
      when 'emissions-wrong-rows'
        hpxml, _hpxml_bldg = _create_hpxml('base-misc-emissions.xml')
        scenario = hpxml.header.emissions_scenarios[1]
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), scenario.elec_schedule_filepath))
        File.write(@tmp_csv_path, csv_data[0..-2].map(&:to_csv).join)
        hpxml.header.emissions_scenarios[1].elec_schedule_filepath = @tmp_csv_path
      when 'geothermal-loop-multiple-attached-hps'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-detailed-geothermal-loop.xml')
        hpxml_bldg.heat_pumps[0].fraction_cool_load_served = 0.5
        hpxml_bldg.heat_pumps[0].fraction_heat_load_served = 0.5
        hpxml_bldg.heat_pumps << hpxml_bldg.heat_pumps[0].dup
        hpxml_bldg.heat_pumps[1].id = "HeatPump#{hpxml_bldg.heat_pumps.size}"
        hpxml_bldg.heat_pumps[0].primary_heating_system = false
        hpxml_bldg.heat_pumps[0].primary_cooling_system = false
        hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                          distribution_system_type: HPXML::HVACDistributionTypeDSE,
                                          annual_cooling_dse: 1.0,
                                          annual_heating_dse: 1.0)
        hpxml_bldg.heat_pumps[1].distribution_system_idref = hpxml_bldg.hvac_distributions[1].id
      when 'heat-pump-backup-system-load-fraction'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml')
        hpxml_bldg.heating_systems[0].fraction_heat_load_served = 0.5
        hpxml_bldg.heat_pumps[0].fraction_heat_load_served = 0.5
      when 'heat-pump-switchover-temp-elec-backup'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].backup_heating_switchover_temp = 35.0
      when 'heat-pump-lockout-temps-elec-backup'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].compressor_lockout_temp = 35.0
        hpxml_bldg.heat_pumps[0].backup_heating_lockout_temp = 35.0
      when 'hvac-invalid-distribution-system-type'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                          distribution_system_type: HPXML::HVACDistributionTypeHydronic,
                                          hydronic_type: HPXML::HydronicTypeBaseboard)
        hpxml_bldg.heating_systems[-1].distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
      when 'hvac-attached-to-uncond-zone'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        hpxml_bldg.hvac_systems.each do |hvac_system|
          hvac_system.attached_to_zone_idref = hpxml_bldg.zones.find { |zone| zone.zone_type != HPXML::ZoneTypeConditioned }.id
        end
      when 'hvac-distribution-different-zones'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        hpxml_bldg.zones.add(id: 'ConditionedZoneDup',
                             zone_type: HPXML::ZoneTypeConditioned)
        hpxml_bldg.zones[0].spaces[0].floor_area /= 2.0
        hpxml_bldg.zones[-1].spaces.add(id: 'ConditionedSpaceDup',
                                        floor_area: hpxml_bldg.zones[0].spaces[0].floor_area)
        hpxml_bldg.heating_systems[0].attached_to_zone_idref = hpxml_bldg.conditioned_zones[0].id
        hpxml_bldg.cooling_systems[0].attached_to_zone_idref = hpxml_bldg.conditioned_zones[-1].id
      when 'hvac-distribution-multiple-attached-cooling'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-multiple.xml')
        hpxml_bldg.heat_pumps[0].distribution_system_idref = 'HVACDistribution2'
      when 'hvac-distribution-multiple-attached-heating'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-multiple.xml')
        hpxml_bldg.heat_pumps[0].distribution_system_idref = 'HVACDistribution1'
      when 'hvac-dse-multiple-attached-cooling'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-dse.xml')
        hpxml_bldg.cooling_systems[0].fraction_cool_load_served = 0.5
        hpxml_bldg.cooling_systems << hpxml_bldg.cooling_systems[0].dup
        hpxml_bldg.cooling_systems[1].id = "CoolingSystem#{hpxml_bldg.cooling_systems.size}"
        hpxml_bldg.cooling_systems[0].primary_system = false
      when 'hvac-dse-multiple-attached-heating'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-dse.xml')
        hpxml_bldg.heating_systems[0].fraction_heat_load_served = 0.5
        hpxml_bldg.heating_systems << hpxml_bldg.heating_systems[0].dup
        hpxml_bldg.heating_systems[1].id = "HeatingSystem#{hpxml_bldg.heating_systems.size}"
        hpxml_bldg.heating_systems[0].primary_system = false
      when 'hvac-research-features-onoff-thermostat-num-speeds-greater-than-two'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-research-features.xml')
        hpxml_bldg.heat_pumps[0].compressor_type = HPXML::HVACCompressorTypeVariableSpeed
      when 'hvac-research-features-num-unit-greater-than-one'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-research-features.xml')
        hpxml_bldg.building_construction.number_of_units = 2
      when 'hvac-gshp-invalid-bore-depth-autosized'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.site.ground_conductivity = 0.1
      when 'hvac-gshp-invalid-num-bore-holes'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-detailed-geothermal-loop.xml')
        hpxml_bldg.geothermal_loops[0].num_bore_holes = 5
      when 'hvac-gshp-invalid-num-bore-holes-autosized'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].cooling_capacity *= 2
        hpxml_bldg.site.ground_conductivity = 0.08
      when 'hvac-inconsistent-fan-powers'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.cooling_systems[0].fan_watts_per_cfm = 0.55
        hpxml_bldg.heating_systems[0].fan_watts_per_cfm = 0.45
      when 'hvac-inconsistent-fan-motor types'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.heating_systems[0].fan_motor_type = HPXML::HVACFanMotorTypePSC
        hpxml_bldg.cooling_systems[0].fan_motor_type = HPXML::HVACFanMotorTypeBPM
      when 'hvac-shared-boiler-multiple'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-boiler-only-baseboard.xml')
        hpxml_bldg.hvac_distributions << hpxml_bldg.hvac_distributions[0].dup
        hpxml_bldg.hvac_distributions[-1].id = "HVACDistribution#{hpxml_bldg.hvac_distributions.size}"
        hpxml_bldg.heating_systems[0].fraction_heat_load_served = 0.5
        hpxml_bldg.heating_systems[0].primary_system = false
        hpxml_bldg.heating_systems << hpxml_bldg.heating_systems[0].dup
        hpxml_bldg.heating_systems[1].id = "HeatingSystem#{hpxml_bldg.heating_systems.size}"
        hpxml_bldg.heating_systems[1].distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
        hpxml_bldg.heating_systems[1].primary_system = true
      when 'hvac-shared-chiller-multiple'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-chiller-only-baseboard.xml')
        hpxml_bldg.hvac_distributions << hpxml_bldg.hvac_distributions[0].dup
        hpxml_bldg.hvac_distributions[-1].id = "HVACDistribution#{hpxml_bldg.hvac_distributions.size}"
        hpxml_bldg.cooling_systems[0].fraction_cool_load_served = 0.5
        hpxml_bldg.cooling_systems[0].primary_system = false
        hpxml_bldg.cooling_systems << hpxml_bldg.cooling_systems[0].dup
        hpxml_bldg.cooling_systems[1].id = "CoolingSystem#{hpxml_bldg.cooling_systems.size}"
        hpxml_bldg.cooling_systems[1].distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
        hpxml_bldg.cooling_systems[1].primary_system = true
      when 'hvac-shared-chiller-negative-seer-eq'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-chiller-only-baseboard.xml')
        hpxml_bldg.cooling_systems[0].shared_loop_watts *= 100.0
      when 'inconsistent-belly-wing-skirt-present'
        hpxml, hpxml_bldg = _create_hpxml('base-foundation-belly-wing-skirt.xml')
        fnd = hpxml_bldg.foundations.find { |f| f.foundation_type == HPXML::FoundationTypeBellyAndWing }
        hpxml_bldg.foundations << fnd.dup
        hpxml_bldg.foundations[-1].id = 'Duplicate'
        hpxml_bldg.foundations[-1].belly_wing_skirt_present = false
      when 'inconsistent-cond-zone-assignment'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        grg_ceiling = hpxml_bldg.floors.find { |f| f.interior_adjacent_to == HPXML::LocationGarage && f.exterior_adjacent_to == HPXML::LocationAtticUnvented }
        grg_ceiling.attached_to_space_idref = hpxml_bldg.conditioned_spaces[0].id
      when 'inconsistent-cond-basement-within-infiltration-volume'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        fnd = hpxml_bldg.foundations.find { |f| f.foundation_type == HPXML::FoundationTypeBasementConditioned }
        hpxml_bldg.foundations << fnd.dup
        hpxml_bldg.foundations[-1].id = 'Duplicate'
        hpxml_bldg.foundations[-1].within_infiltration_volume = false
      when 'inconsistent-uncond-basement-within-infiltration-volume'
        hpxml, hpxml_bldg = _create_hpxml('base-foundation-unconditioned-basement.xml')
        fnd = hpxml_bldg.foundations.find { |f| f.foundation_type == HPXML::FoundationTypeBasementUnconditioned }
        hpxml_bldg.foundations << fnd.dup
        hpxml_bldg.foundations[-1].id = 'Duplicate'
        hpxml_bldg.foundations[-1].within_infiltration_volume = true
      when 'inconsistent-unvented-attic-within-infiltration-volume'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        attic = hpxml_bldg.attics.find { |a| a.attic_type == HPXML::AtticTypeUnvented }
        hpxml_bldg.attics << attic.dup
        hpxml_bldg.attics[-1].id = 'Duplicate'
        hpxml_bldg.attics[-1].within_infiltration_volume = true
      when 'inconsistent-unvented-crawl-within-infiltration-volume'
        hpxml, hpxml_bldg = _create_hpxml('base-foundation-unvented-crawlspace.xml')
        fnd = hpxml_bldg.foundations.find { |f| f.foundation_type == HPXML::FoundationTypeCrawlspaceUnvented }
        hpxml_bldg.foundations << fnd.dup
        hpxml_bldg.foundations[-1].id = 'Duplicate'
        hpxml_bldg.foundations[-1].within_infiltration_volume = true
      when 'inconsistent-cond-crawl-within-infiltration-volume'
        hpxml, hpxml_bldg = _create_hpxml('base-foundation-conditioned-crawlspace.xml')
        fnd = hpxml_bldg.foundations.find { |f| f.foundation_type == HPXML::FoundationTypeCrawlspaceConditioned }
        hpxml_bldg.foundations << fnd.dup
        hpxml_bldg.foundations[-1].id = 'Duplicate'
        hpxml_bldg.foundations[-1].within_infiltration_volume = false
      when 'inconsistent-vented-attic-ventilation-rate'
        hpxml, hpxml_bldg = _create_hpxml('base-atticroof-vented.xml')
        attic = hpxml_bldg.attics.find { |a| a.attic_type == HPXML::AtticTypeVented }
        hpxml_bldg.attics[0].vented_attic_sla = 0.003
        hpxml_bldg.attics << attic.dup
        hpxml_bldg.attics[-1].id = 'Duplicate'
        hpxml_bldg.attics[-1].vented_attic_sla *= 2
      when 'inconsistent-vented-attic-ventilation-rate2'
        hpxml, hpxml_bldg = _create_hpxml('base-atticroof-vented.xml')
        attic = hpxml_bldg.attics.find { |a| a.attic_type == HPXML::AtticTypeVented }
        hpxml_bldg.attics[0].vented_attic_sla = 0.003
        hpxml_bldg.attics << attic.dup
        hpxml_bldg.attics[-1].id = 'Duplicate'
        hpxml_bldg.attics[-1].vented_attic_sla = nil
        hpxml_bldg.attics[-1].vented_attic_ach = 5.0
      when 'inconsistent-vented-crawl-ventilation-rate'
        hpxml, hpxml_bldg = _create_hpxml('base-foundation-vented-crawlspace.xml')
        fnd = hpxml_bldg.foundations.find { |f| f.foundation_type == HPXML::FoundationTypeCrawlspaceVented }
        hpxml_bldg.foundations[0].vented_crawlspace_sla = 0.003
        hpxml_bldg.foundations << fnd.dup
        hpxml_bldg.foundations[-1].id = 'Duplicate'
        hpxml_bldg.foundations[-1].vented_crawlspace_sla *= 2
      when 'invalid-battery-capacity-units'
        hpxml, hpxml_bldg = _create_hpxml('base-pv-battery.xml')
        hpxml_bldg.batteries[0].usable_capacity_kwh = nil
        hpxml_bldg.batteries[0].usable_capacity_ah = 200.0
      when 'invalid-battery-capacity-units2'
        hpxml, hpxml_bldg = _create_hpxml('base-pv-battery-ah.xml')
        hpxml_bldg.batteries[0].usable_capacity_kwh = 10.0
        hpxml_bldg.batteries[0].usable_capacity_ah = nil
      when 'invalid-datatype-boolean'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.roofs[0].radiant_barrier = false
      when 'invalid-datatype-integer'
        hpxml, _hpxml_bldg = _create_hpxml('base.xml')
      when 'invalid-datatype-float'
        hpxml, _hpxml_bldg = _create_hpxml('base-misc-emissions.xml')
      when 'invalid-daylight-saving'
        hpxml, hpxml_bldg = _create_hpxml('base-simcontrol-daylight-saving-custom.xml')
        hpxml_bldg.dst_begin_month = 3
        hpxml_bldg.dst_begin_day = 10
        hpxml_bldg.dst_end_month = 4
        hpxml_bldg.dst_end_day = 31
      when 'invalid-distribution-cfa-served'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_distributions[-1].conditioned_floor_area_served = 2701.1
      when 'invalid-epw-filepath'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'foo.epw'
      when 'invalid-holiday-lighting-dates'
        hpxml, hpxml_bldg = _create_hpxml('base-lighting-holiday.xml')
        hpxml_bldg.lighting.holiday_period_begin_month = 11
        hpxml_bldg.lighting.holiday_period_begin_day = 31
        hpxml_bldg.lighting.holiday_period_end_month = 1
        hpxml_bldg.lighting.holiday_period_end_day = 15
      when 'invalid-id'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights.xml')
        hpxml_bldg.skylights[0].id = ''
      when 'invalid-neighbor-shading-azimuth'
        hpxml, hpxml_bldg = _create_hpxml('base-misc-neighbor-shading.xml')
        hpxml_bldg.neighbor_buildings[0].azimuth = 145
      when 'invalid-ptac-dse'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ptac-cfis.xml')
        hpxml_bldg.hvac_distributions[0].annual_cooling_dse = 0.9
      when 'invalid-pthp-dse'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-pthp-cfis.xml')
        hpxml_bldg.hvac_distributions[0].annual_heating_dse = 0.9
      when 'invalid-relatedhvac-dhw-indirect'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-indirect.xml')
        hpxml_bldg.water_heating_systems[0].related_hvac_idref = 'HeatingSystem_bad'
      when 'invalid-relatedhvac-desuperheater'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-central-ac-only-1-speed.xml')
        hpxml_bldg.water_heating_systems[0].uses_desuperheater = true
        hpxml_bldg.water_heating_systems[0].related_hvac_idref = 'CoolingSystem_bad'
      when 'invalid-runperiod'
        hpxml, _hpxml_bldg = _create_hpxml('base.xml')
        hpxml.header.sim_begin_month = 3
        hpxml.header.sim_begin_day = 10
        hpxml.header.sim_end_month = 4
        hpxml.header.sim_end_day = 31
      when 'invalid-shading-season'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.header.shading_summer_begin_month = 3
        hpxml_bldg.header.shading_summer_begin_day = 10
        hpxml_bldg.header.shading_summer_end_month = 4
        hpxml_bldg.header.shading_summer_end_day = 31
      when 'invalid-unavailable-period'
        hpxml, _hpxml_bldg = _create_hpxml('base.xml')
        hpxml.header.unavailable_periods.add(column_name: 'Power Outage',
                                             begin_month: 3,
                                             begin_day: 10,
                                             end_month: 4,
                                             end_day: 31)
      when 'invalid-schema-version'
        hpxml, _hpxml_bldg = _create_hpxml('base.xml')
      when 'invalid-skylights-physical-properties'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights-physical-properties.xml')
        hpxml_bldg.skylights[1].thermal_break = false
      when 'invalid-windows-physical-properties'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-windows-physical-properties.xml')
        hpxml_bldg.windows[2].thermal_break = false
      when 'leap-year-TMY'
        hpxml, _hpxml_bldg = _create_hpxml('base-simcontrol-calendar-year-custom.xml')
        hpxml.header.sim_calendar_year = 2008
      when 'multifamily-common-space-wrong-sameas-id'
        hpxml, _hpxml_bldg = _create_hpxml('base-bldgtype-mf-whole-building-common-spaces.xml')
        hpxml.buildings[1].floors[0].sameas_id = 'Foo'
      when 'net-area-negative-roof-floor'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights.xml')
        hpxml_bldg.skylights[0].area = 4000
      when 'net-area-negative-wall'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.windows[0].area = 1000
      when 'orphaned-geothermal-loop'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-detailed-geothermal-loop.xml')
        hpxml_bldg.heat_pumps[0].geothermal_loop_idref = nil
      when 'orphaned-hvac-distribution'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-furnace-gas-room-ac.xml')
        hpxml_bldg.heating_systems[0].delete
        hpxml_bldg.hvac_controls[0].heating_setpoint_temp = nil
      when 'panel-wrong-system-type'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.electric_panels.add(id: 'ElectricPanel1')
        hpxml_bldg.electric_panels[0].service_feeders.add(id: 'ServiceFeeder1',
                                                          type: HPXML::ElectricPanelLoadTypeHeating,
                                                          component_idrefs: [hpxml_bldg.water_heating_systems[0].id])
      when 'refrigerators-multiple-primary'
        hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
        hpxml_bldg.refrigerators[1].primary_indicator = true
      when 'refrigerators-no-primary'
        hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
        hpxml_bldg.refrigerators[0].primary_indicator = false
      when 'repeated-relatedhvac-dhw-indirect'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-indirect.xml')
        hpxml_bldg.water_heating_systems[0].fraction_dhw_load_served = 0.5
        hpxml_bldg.water_heating_systems << hpxml_bldg.water_heating_systems[0].dup
        hpxml_bldg.water_heating_systems[1].id = "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size}"
      when 'repeated-relatedhvac-desuperheater'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-central-ac-only-1-speed.xml')
        hpxml_bldg.water_heating_systems[0].fraction_dhw_load_served = 0.5
        hpxml_bldg.water_heating_systems[0].uses_desuperheater = true
        hpxml_bldg.water_heating_systems[0].related_hvac_idref = 'CoolingSystem1'
        hpxml_bldg.water_heating_systems << hpxml_bldg.water_heating_systems[0].dup
        hpxml_bldg.water_heating_systems[1].id = "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size}"
      when 'schedule-detailed-bad-values-max-not-one'
        hpxml, hpxml_bldg = _create_hpxml('base-schedules-detailed-occupancy-stochastic.xml')
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml_bldg.header.schedules_filepaths[0]))
        csv_data[1][csv_data[0].index('lighting_interior')] = 1.1
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml_bldg.header.schedules_filepaths = [@tmp_csv_path]
      when 'schedule-detailed-bad-values-negative'
        hpxml, hpxml_bldg = _create_hpxml('base-schedules-detailed-occupancy-stochastic.xml')
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml_bldg.header.schedules_filepaths[0]))
        csv_data[1][csv_data[0].index('lighting_interior')] = -0.5
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml_bldg.header.schedules_filepaths = [@tmp_csv_path]
      when 'schedule-detailed-bad-values-non-numeric'
        hpxml, hpxml_bldg = _create_hpxml('base-schedules-detailed-occupancy-stochastic.xml')
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml_bldg.header.schedules_filepaths[0]))
        csv_data[1][csv_data[0].index('lighting_interior')] = 'NA'
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml_bldg.header.schedules_filepaths = [@tmp_csv_path]
      when 'schedule-detailed-bad-values-mode-negative'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump-detailed-schedules.xml')
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml_bldg.header.schedules_filepaths[1]))
        csv_data[1][0] = -0.5
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml_bldg.header.schedules_filepaths = [@tmp_csv_path]
      when 'schedule-detailed-duplicate-columns'
        hpxml, hpxml_bldg = _create_hpxml('base-schedules-detailed-occupancy-stochastic.xml')
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml_bldg.header.schedules_filepaths[0]))
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml_bldg.header.schedules_filepaths = []
        hpxml_bldg.header.schedules_filepaths << @tmp_csv_path
        hpxml_bldg.header.schedules_filepaths << @tmp_csv_path
      when 'schedule-detailed-wrong-filename'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.header.schedules_filepaths << 'invalid-wrong-filename.csv'
      when 'schedule-detailed-wrong-rows'
        hpxml, hpxml_bldg = _create_hpxml('base-schedules-detailed-occupancy-stochastic.xml')
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml_bldg.header.schedules_filepaths[0]))
        File.write(@tmp_csv_path, csv_data[0..-2].map(&:to_csv).join)
        hpxml_bldg.header.schedules_filepaths = [@tmp_csv_path]
      when 'skylight-not-connected-to-cond-space'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-garage.xml')
        hpxml_bldg.skylights.add(id: 'Skylight1',
                                 area: 15.0,
                                 azimuth: 0,
                                 ufactor: 0.33,
                                 shgc: 0.45,
                                 shaft_area: 60,
                                 shaft_assembly_r_value: 6.25,
                                 attached_to_roof_idref: 'Roof1',
                                 attached_to_floor_idref: 'Floor1')
      when 'solar-thermal-system-with-combi-tankless'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-combi-tankless.xml')
        hpxml_bldg.solar_thermal_systems.add(id: "SolarThermalSystem#{hpxml_bldg.solar_thermal_systems.size + 1}",
                                             system_type: HPXML::SolarThermalSystemTypeHotWater,
                                             collector_area: 40,
                                             collector_type: HPXML::SolarThermalCollectorTypeSingleGlazing,
                                             collector_loop_type: HPXML::SolarThermalLoopTypeIndirect,
                                             collector_azimuth: 180,
                                             collector_tilt: 20,
                                             collector_rated_optical_efficiency: 0.77,
                                             collector_rated_thermal_losses: 0.793,
                                             water_heating_system_idref: 'WaterHeatingSystem1')
      when 'solar-thermal-system-with-desuperheater'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-desuperheater.xml')
        hpxml_bldg.solar_thermal_systems.add(id: "SolarThermalSystem#{hpxml_bldg.solar_thermal_systems.size + 1}",
                                             system_type: HPXML::SolarThermalSystemTypeHotWater,
                                             collector_area: 40,
                                             collector_type: HPXML::SolarThermalCollectorTypeSingleGlazing,
                                             collector_loop_type: HPXML::SolarThermalLoopTypeIndirect,
                                             collector_azimuth: 180,
                                             collector_tilt: 20,
                                             collector_rated_optical_efficiency: 0.77,
                                             collector_rated_thermal_losses: 0.793,
                                             water_heating_system_idref: 'WaterHeatingSystem1')
      when 'solar-thermal-system-with-dhw-indirect'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-combi-tankless.xml')
        hpxml_bldg.solar_thermal_systems.add(id: "SolarThermalSystem#{hpxml_bldg.solar_thermal_systems.size + 1}",
                                             system_type: HPXML::SolarThermalSystemTypeHotWater,
                                             collector_area: 40,
                                             collector_type: HPXML::SolarThermalCollectorTypeSingleGlazing,
                                             collector_loop_type: HPXML::SolarThermalLoopTypeIndirect,
                                             collector_azimuth: 180,
                                             collector_tilt: 20,
                                             collector_rated_optical_efficiency: 0.77,
                                             collector_rated_thermal_losses: 0.793,
                                             water_heating_system_idref: 'WaterHeatingSystem1')
      when 'surface-attached-to-uncond-space'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        hpxml_bldg.walls[-1].attached_to_space_idref = hpxml_bldg.zones.find { |zone| zone.zone_type != HPXML::ZoneTypeConditioned }.spaces[0].id
      when 'surface-attached-to-uncond-space2'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        hpxml_bldg.slabs[-1].attached_to_space_idref = hpxml_bldg.zones.find { |zone| zone.zone_type != HPXML::ZoneTypeConditioned }.spaces[0].id
      when 'unattached-cfis'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                        fan_type: HPXML::MechVentTypeCFIS,
                                        used_for_whole_building_ventilation: true,
                                        distribution_system_idref: hpxml_bldg.hvac_distributions[0].id)
        hpxml_bldg.ventilation_fans[0].distribution_system_idref = 'foobar'
      when 'unattached-door'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.doors[0].attached_to_wall_idref = 'foobar'
      when 'unattached-gshp'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-detailed-geothermal-loop.xml')
        hpxml_bldg.heat_pumps[0].geothermal_loop_idref = 'foobar'
        hpxml_bldg.geothermal_loops[0].delete
      when 'unattached-hvac-distribution'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.heating_systems[0].distribution_system_idref = 'foobar'
      when 'unattached-pv-system'
        hpxml, hpxml_bldg = _create_hpxml('base-pv.xml')
        hpxml_bldg.pv_systems[0].inverter_idref = 'foobar'
      when 'unattached-skylight'
        hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights.xml')
        hpxml_bldg.skylights[0].attached_to_roof_idref = 'foobar'
        hpxml_bldg.skylights[0].attached_to_floor_idref = 'foobar'
      when 'unattached-solar-thermal-system'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-solar-indirect-flat-plate.xml')
        hpxml_bldg.solar_thermal_systems[0].water_heating_system_idref = 'foobar'
      when 'unattached-shared-clothes-washer-dhw-distribution'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-laundry-room.xml')
        hpxml_bldg.clothes_washers[0].water_heating_system_idref = nil
        hpxml_bldg.clothes_washers[0].hot_water_distribution_idref = 'foobar'
      when 'unattached-shared-clothes-washer-water-heater'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-laundry-room.xml')
        hpxml_bldg.clothes_washers[0].water_heating_system_idref = 'foobar'
      when 'unattached-shared-dishwasher-dhw-distribution'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-laundry-room.xml')
        hpxml_bldg.dishwashers[0].water_heating_system_idref = nil
        hpxml_bldg.dishwashers[0].hot_water_distribution_idref = 'foobar'
      when 'unattached-shared-dishwasher-water-heater'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit-shared-laundry-room.xml')
        hpxml_bldg.dishwashers[0].water_heating_system_idref = 'foobar'
      when 'unattached-window'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.windows[0].attached_to_wall_idref = 'foobar'
      when 'unattached-zone'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        hpxml_bldg.heating_systems[0].attached_to_zone_idref = 'foobar'
        hpxml_bldg.cooling_systems[0].attached_to_zone_idref = 'foobar'
      when 'unavailable-period-missing-column'
        hpxml, _hpxml_bldg = _create_hpxml('base-schedules-simple-vacancy.xml')
        hpxml.header.unavailable_periods[0].column_name = 'foobar'
      when 'unique-objects-vary-across-units-epw'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-whole-building.xml', building_id: building_id)
        hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw'
      when 'unique-objects-vary-across-units-dst'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-whole-building.xml', building_id: building_id)
        hpxml_bldg.dst_observed = true
        hpxml_bldg.dst_begin_month = 3
        hpxml_bldg.dst_begin_day = 15
        hpxml_bldg.dst_end_month = 10
        hpxml_bldg.dst_end_day = 15
      when 'unique-objects-vary-across-units-tmains'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-whole-building.xml', building_id: building_id)
        hpxml_bldg.hot_water_distributions[0].dwhr_facilities_connected = HPXML::DWHRFacilitiesConnectedOne
        hpxml_bldg.hot_water_distributions[0].dwhr_equal_flow = true
        hpxml_bldg.hot_water_distributions[0].dwhr_efficiency = 0.55
      when 'whole-mf-building-batteries'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-whole-building.xml', building_id: building_id)
        hpxml_bldg.batteries.add(id: 'Battery1',
                                 type: HPXML::BatteryTypeLithiumIon)
      when 'whole-mf-building-dehumidifiers-unit-multiplier'
        hpxml, hpxml_bldg = _create_hpxml('base-appliances-dehumidifier.xml')
        hpxml_bldg.building_construction.number_of_units = 2
      when 'whole-mf-building-gshps-unit-multiplier'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.building_construction.number_of_units = 2
      when 'multifamily-inter-unit-heat-transfer-wrong-sameas-object-floor'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-whole-building-inter-unit-heat-transfer.xml')
        hpxml_bldg.floors.add(id: 'Floor4_1', sameas_id: 'Wall1_2')
      when 'multifamily-inter-unit-heat-transfer-wrong-sameas-object-rim-joist'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-whole-building-inter-unit-heat-transfer.xml')
        hpxml_bldg.rim_joists.add(id: 'RimJoist3', sameas_id: 'Wall1_2')
      when 'multifamily-inter-unit-heat-transfer-wrong-sameas-object-foundation-wall'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-whole-building-inter-unit-heat-transfer.xml')
        hpxml_bldg.foundation_walls.add(id: 'FoundationWall3', sameas_id: 'Wall1_2')
      when 'multifamily-inter-unit-heat-transfer-wrong-sameas-object-wall'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-whole-building-inter-unit-heat-transfer.xml')
        hpxml_bldg.walls.add(id: 'Wall3', sameas_id: 'Floor1_2')
      when 'multifamily-inter-unit-heat-transfer-same-building'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-whole-building-inter-unit-heat-transfer.xml')
        hpxml_bldg.walls.add(id: 'Wall3', sameas_id: 'Wall1')
      when 'multifamily-inter-unit-heat-transfer-multiple-reference'
        hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-whole-building-inter-unit-heat-transfer.xml')
        hpxml_bldg.walls.add(id: 'Wall3', sameas_id: 'Wall2_3')
      else
        fail "Unhandled case: #{error_case}."
      end

      hpxml_doc = hpxml.to_doc()

      # Perform additional raw XML manipulation
      case error_case
      when 'invalid-datatype-boolean'
        XMLHelper.get_element(hpxml_doc, '/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof/RadiantBarrier').inner_text = 'FOOBAR'
      when 'invalid-datatype-integer'
        XMLHelper.get_element(hpxml_doc, '/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms').inner_text = '2.5'
      when 'invalid-datatype-float'
        XMLHelper.get_element(hpxml_doc, '/HPXML/SoftwareInfo/extension/EmissionsScenarios/EmissionsScenario/EmissionsFactor/Value').inner_text = 'FOOBAR'
      when 'invalid-schema-version'
        root = XMLHelper.get_element(hpxml_doc, '/HPXML')
        XMLHelper.add_attribute(root, 'schemaVersion', '2.3')
      end

      XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)
      _test_measure('error', expected_errors, building_id: building_id)
    end
  end

  # Test warnings are correctly triggered in the HPXMLtoOpenStudio ruby code
  def test_ruby_warning_messages
    # Test case => Error message(s)
    all_expected_warnings = { 'cfis-undersized-supplemental-fan' => ["CFIS supplemental fan 'VentilationFan2' is undersized (90.0 cfm) compared to the target hourly ventilation rate (110.0 cfm)."],
                              'duct-lto-cfm25-cond-space' => ['Ducts are entirely within conditioned space but there is moderate leakage to the outside. Leakage to the outside is typically zero or near-zero in these situations, consider revising leakage values. Leakage will be modeled as heat lost to the ambient environment.'],
                              'duct-lto-cfm25-uncond-space' => ['Very high sum of supply + return duct leakage to the outside; double-check inputs.'],
                              'duct-lto-cfm50-cond-space' => ['Ducts are entirely within conditioned space but there is moderate leakage to the outside. Leakage to the outside is typically zero or near-zero in these situations, consider revising leakage values. Leakage will be modeled as heat lost to the ambient environment.'],
                              'duct-lto-cfm50-uncond-space' => ['Very high sum of supply + return duct leakage to the outside; double-check inputs.'],
                              'duct-lto-percent-cond-space' => ['Ducts are entirely within conditioned space but there is moderate leakage to the outside. Leakage to the outside is typically zero or near-zero in these situations, consider revising leakage values. Leakage will be modeled as heat lost to the ambient environment.'],
                              'duct-lto-percent-uncond-space' => ['Very high sum of supply + return duct leakage to the outside; double-check inputs.'],
                              'floor-or-ceiling1' => ["Floor 'Floor1' has FloorOrCeiling=floor but it should be ceiling. The input will be overridden."],
                              'floor-or-ceiling2' => ["Floor 'Floor1' has FloorOrCeiling=ceiling but it should be floor. The input will be overridden."],
                              'hpwh-confined-space-without-mitigation-false' => ["HPWH COP adjustment based on HPWHContainmentVolume will not be applied to WaterHeatingSystem1 because HPWHInConfinedSpaceWithoutMitigation is not 'true'."],
                              'hpwh-ducting' => ['HPWH exhaust air ducted to a location other than outside is not currently supported; exhaust ducting will not be modeled.',
                                                 'HPWH exhaust air ducting for a water heater located outside conditioned space is not currently supported; exhaust ducting will not be modeled.',
                                                 'HPWH supply air ducted from another location is not currently supported; supply ducting will not be modeled.'],
                              'hpwh-small-containment-volume-without-backup-element' => ['Heat pump water heater: WaterHeatingSystem1 has no backup electric resistance element, COP adjustment for confined space may not be accurate when the containment space volume is below 450 cubic feet.'],
                              'hvac-gshp-bore-depth-autosized-high' => ['Reached a maximum of 10 boreholes; setting bore depth to the maximum (500 ft).'],
                              'hvac-seasons' => ['It is not possible to eliminate all HVAC energy use (e.g. crankcase/defrost energy) in EnergyPlus outside of an HVAC season.'],
                              'hvac-setpoint-adjustments' => ['HVAC setpoints have been automatically adjusted to prevent periods where the heating setpoint is greater than the cooling setpoint.'],
                              'hvac-setpoint-adjustments-daily-setbacks' => ['HVAC setpoints have been automatically adjusted to prevent periods where the heating setpoint is greater than the cooling setpoint.'],
                              'hvac-setpoint-adjustments-daily-schedules' => ['HVAC setpoints have been automatically adjusted to prevent periods where the heating setpoint is greater than the cooling setpoint.'],
                              'multistage-backup-more-than-4-stages' => ['EnergyPlus only supports 4 stages for multi-stage electric backup coil. Combined the remaining capacities in the last stage.',
                                                                         'Calculated multi-stage backup coil capacity increment for last stage is not equal to user input, actual capacity increment is'],
                              'manualj-sum-space-num-occupants' => ['ManualJInputs/NumberofOccupants (4.8) does not match sum of conditioned spaces (5.0).'],
                              'manualj-sum-space-internal-loads-sensible' => ['ManualJInputs/InternalLoadsSensible (1000.0) does not match sum of conditioned spaces (1200.0).'],
                              'manualj-sum-space-internal-loads-latent' => ['ManualJInputs/InternalLoadsLatent (200.0) does not match sum of conditioned spaces (100.0).'],
                              'multiple-conditioned-zone' => ['While multiple conditioned zones are specified, the EnergyPlus model will only include a single conditioned thermal zone.'],
                              'multiple-inverter-efficiencies' => ['Inverters with varying efficiencies found; using a single PV size weighted-average in the model.'],
                              'panel-missing-default' => ["Voltage (240) for 'dishwasher' is not specified in default_panels.csv; PowerRating will be assigned according to Voltage=120.",
                                                          "Voltage (240) for 'dishwasher' is not specified in default_panels.csv; BreakerSpaces will be recalculated using Voltage=240."],
                              'power-outage' => ['It is not possible to eliminate all HVAC energy use (e.g. crankcase/defrost energy) in EnergyPlus during an unavailable period.',
                                                 'It is not possible to eliminate all DHW energy use (e.g. water heater parasitics) in EnergyPlus during an unavailable period.'],
                              'schedule-file-and-weekday-weekend-multipliers' => ["Both 'occupants' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'occupants' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'occupants' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'clothes_washer' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'clothes_washer' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'clothes_washer' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'clothes_dryer' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'clothes_dryer' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'clothes_dryer' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'dishwasher' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'dishwasher' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'dishwasher' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'refrigerator' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'refrigerator' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'refrigerator' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'extra_refrigerator' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'extra_refrigerator' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'extra_refrigerator' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'freezer' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'freezer' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'freezer' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'cooking_range' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'cooking_range' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'cooking_range' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'hot_water_fixtures' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'hot_water_fixtures' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'hot_water_fixtures' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'general_water_use' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'general_water_use' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'general_water_use' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'hot_water_recirculation_pump' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'hot_water_recirculation_pump' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'hot_water_recirculation_pump' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_tv' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_tv' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_tv' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_other' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_other' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_other' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_well_pump' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_well_pump' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'plug_loads_well_pump' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_grill' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_grill' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_grill' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_lighting' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_lighting' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_lighting' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_fireplace' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_fireplace' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'fuel_loads_fireplace' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'lighting_interior' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'lighting_interior' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'lighting_interior' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'lighting_exterior' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'lighting_exterior' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'lighting_exterior' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'pool_pump' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'pool_pump' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'pool_pump' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'pool_heater' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'pool_heater' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'pool_heater' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'permanent_spa_pump' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'permanent_spa_pump' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'permanent_spa_pump' schedule file and monthly multipliers provided; the latter will be ignored.",
                                                                                  "Both 'permanent_spa_heater' schedule file and weekday fractions provided; the latter will be ignored.",
                                                                                  "Both 'permanent_spa_heater' schedule file and weekend fractions provided; the latter will be ignored.",
                                                                                  "Both 'permanent_spa_heater' schedule file and monthly multipliers provided; the latter will be ignored."],
                              'schedule-file-and-weekday-weekend-multipliers-ev' => ["Both schedule file and weekday fractions provided for 'electric_vehicle'; weekday fractions will be ignored.",
                                                                                     "Both schedule file and weekend fractions provided for 'electric_vehicle'; weekend fractions will be ignored.",
                                                                                     "Both schedule file and monthly multipliers provided for 'electric_vehicle'; monthly multipliers will be ignored.",],
                              'schedule-file-and-refrigerators-freezer-coefficients' => ["Both 'refrigerator' schedule file and constant coefficients provided; the latter will be ignored.",
                                                                                         "Both 'refrigerator' schedule file and temperature coefficients provided; the latter will be ignored.",
                                                                                         "Both 'extra_refrigerator' schedule file and constant coefficients provided; the latter will be ignored.",
                                                                                         "Both 'extra_refrigerator' schedule file and temperature coefficients provided; the latter will be ignored.",
                                                                                         "Both 'freezer' schedule file and constant coefficients provided; the latter will be ignored.",
                                                                                         "Both 'freezer' schedule file and temperature coefficients provided; the latter will be ignored."],
                              'schedule-file-and-setpoints' => ["Both 'heating_setpoint' schedule file and heating setpoint temperature provided; the latter will be ignored.",
                                                                "Both 'cooling_setpoint' schedule file and cooling setpoint temperature provided; the latter will be ignored.",
                                                                "Both 'water_heater_setpoint' schedule file and setpoint temperature provided; the latter will be ignored."],
                              'schedule-file-and-operating-mode' => ["Both 'water_heater_operating_mode' schedule file and operating mode provided; the latter will be ignored."],
                              'schedule-file-max-power-ratio-with-single-speed-system' => ['Maximum power ratio schedule is only supported for variable speed systems.'],
                              'schedule-file-max-power-ratio-with-two-speed-system' => ['Maximum power ratio schedule is only supported for variable speed systems.'],
                              'schedule-file-max-power-ratio-with-separate-backup-system' => ['Maximum power ratio schedule is only supported for integrated backup system. Schedule is ignored for heating.'],
                              'schedule-file-unknown-columns' => ['Unknown column found in schedule file: unknown_column'],
                              'storm-windows-low-window-ufactor' => ['Storm windows may not be modeled accurately when window U-factor is lower than 0.3, while base window U-Factor was 0.25.'] }

    all_expected_warnings.each_with_index do |(warning_case, expected_warnings), i|
      puts "[#{i + 1}/#{all_expected_warnings.size}] Testing #{warning_case}..."
      building_id = nil
      # Create HPXML object
      case warning_case
      when 'cfis-undersized-supplemental-fan'
        hpxml, hpxml_bldg = _create_hpxml('base-mechvent-cfis-supplemental-fan-exhaust.xml')
        suppl_fan = hpxml_bldg.ventilation_fans.find { |f| f.is_cfis_supplemental_fan }
        suppl_fan.tested_flow_rate = 90.0
      when 'duct-lto-cfm25-cond-space'
        hpxml, hpxml_bldg = _create_hpxml('base-atticroof-conditioned.xml')
        hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = hpxml_bldg.building_construction.conditioned_floor_area
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.each do |dlm|
          dlm.duct_leakage_units = HPXML::UnitsCFM25
          dlm.duct_leakage_value = 100.0
        end
        hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
          duct.duct_fraction_area = nil
          duct.duct_location = nil
        end
      when 'duct-lto-cfm25-uncond-space'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.each do |dlm|
          dlm.duct_leakage_value = 800.0
        end
      when 'duct-lto-cfm50-cond-space'
        hpxml, hpxml_bldg = _create_hpxml('base-atticroof-conditioned.xml')
        hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = hpxml_bldg.building_construction.conditioned_floor_area
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.each do |dlm|
          dlm.duct_leakage_units = HPXML::UnitsCFM50
          dlm.duct_leakage_value = 200.0
        end
        hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
          duct.duct_fraction_area = nil
          duct.duct_location = nil
        end
      when 'duct-lto-cfm50-uncond-space'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ducts-leakage-cfm50.xml')
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.each do |dlm|
          dlm.duct_leakage_value = 1600.0
        end
      when 'duct-lto-percent-cond-space'
        hpxml, hpxml_bldg = _create_hpxml('base-atticroof-conditioned.xml')
        hpxml_bldg.hvac_distributions[0].conditioned_floor_area_served = hpxml_bldg.building_construction.conditioned_floor_area
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.each do |dlm|
          dlm.duct_leakage_units = HPXML::UnitsPercent
          dlm.duct_leakage_value = 0.035
        end
        hpxml_bldg.hvac_distributions[0].ducts.each do |duct|
          duct.duct_fraction_area = nil
          duct.duct_location = nil
        end
      when 'duct-lto-percent-uncond-space'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ducts-leakage-percent.xml')
        hpxml_bldg.hvac_distributions[0].duct_leakage_measurements.each do |dlm|
          dlm.duct_leakage_value = 0.25
        end
      when 'floor-or-ceiling1'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.floors[0].floor_or_ceiling = HPXML::FloorOrCeilingFloor
      when 'floor-or-ceiling2'
        hpxml, hpxml_bldg = _create_hpxml('base-foundation-unvented-crawlspace.xml')
        hpxml_bldg.floors[0].floor_or_ceiling = HPXML::FloorOrCeilingCeiling
      when 'hpwh-confined-space-without-mitigation-false'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump-confined-space.xml')
        hpxml_bldg.water_heating_systems[0].hpwh_confined_space_without_mitigation = false
      when 'hpwh-ducting'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump.xml')
        hpxml_bldg.water_heating_systems[0].location = HPXML::LocationAtticUnvented
        hpxml_bldg.water_heating_systems[0].hpwh_ducting_supply = HPXML::LocationGarage
        hpxml_bldg.water_heating_systems[0].hpwh_ducting_exhaust = HPXML::LocationGarage
      when 'hpwh-small-containment-volume-without-backup-element'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump-confined-space.xml')
        hpxml_bldg.water_heating_systems[0].backup_heating_capacity = 0.0
        hpxml_bldg.water_heating_systems[0].hpwh_containment_volume = 250.0
      when 'hvac-gshp-bore-depth-autosized-high'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.site.ground_conductivity = 0.07
      when 'hvac-seasons'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-seasons.xml')
      when 'hvac-setpoint-adjustments'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.hvac_controls[0].heating_setpoint_temp = 76.0
        hpxml_bldg.hvac_controls[0].cooling_setpoint_temp = 75.0
      when 'hvac-setpoint-adjustments-daily-setbacks'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-setpoints-daily-setbacks.xml')
        hpxml_bldg.hvac_controls[0].heating_setback_temp = 76.0
        hpxml_bldg.hvac_controls[0].cooling_setpoint_temp = 75.0
      when 'hvac-setpoint-adjustments-daily-schedules'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-setpoints-daily-schedules.xml')
        hpxml_bldg.hvac_controls[0].weekday_heating_setpoints = '64, 64, 64, 64, 64, 64, 64, 76, 70, 66, 66, 66, 66, 66, 66, 66, 66, 68, 68, 68, 68, 68, 64, 64'
      when 'manualj-sum-space-num-occupants'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        hpxml_bldg.header.manualj_num_occupants = 4.8
        hpxml_bldg.conditioned_spaces.each_with_index do |space, i|
          space.manualj_num_occupants = (i == 0 ? hpxml_bldg.header.manualj_num_occupants.round : 0)
        end
      when 'manualj-sum-space-internal-loads-sensible'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        hpxml_bldg.header.manualj_internal_loads_sensible = 1000.0
        hpxml_bldg.conditioned_spaces.each_with_index do |space, i|
          space.manualj_internal_loads_sensible = (i == 0 ? 1200.0 : 0)
        end
      when 'manualj-sum-space-internal-loads-latent'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces.xml')
        hpxml_bldg.header.manualj_internal_loads_latent = 200.0
        hpxml_bldg.conditioned_spaces.each_with_index do |space, i|
          space.manualj_internal_loads_latent = (i == 0 ? 100.0 : 0)
        end
      when 'multiple-conditioned-zone'
        hpxml, hpxml_bldg = _create_hpxml('base-zones-spaces-multiple.xml')
      when 'multiple-inverter-efficiencies'
        hpxml, _hpxml_bldg = _create_hpxml('base-pv-inverters.xml')
      when 'panel-missing-default'
        hpxml, hpxml_bldg = _create_hpxml('base-detailed-electric-panel.xml')
        hpxml_bldg.dishwashers.add(id: 'Dishwasher')
        service_feeders = hpxml_bldg.electric_panels[0].service_feeders
        service_feeders.add(id: 'NewServiceFeeder',
                            type: HPXML::ElectricPanelLoadTypeDishwasher,
                            component_idrefs: [hpxml_bldg.dishwashers[0].id])
        branch_circuits = hpxml_bldg.electric_panels[0].branch_circuits
        branch_circuits.add(id: 'NewBranchCircuit',
                            voltage: HPXML::ElectricPanelVoltage240,
                            component_idrefs: [hpxml_bldg.dishwashers[0].id])
      when 'power-outage'
        hpxml, _hpxml_bldg = _create_hpxml('base-schedules-simple-power-outage.xml')
      when 'multistage-backup-more-than-4-stages'
        hpxml, _hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-research-features.xml')
        hpxml.header.heat_pump_backup_heating_capacity_increment = 5000
      when 'schedule-file-and-weekday-weekend-multipliers'
        hpxml, hpxml_bldg = _create_hpxml('base-misc-loads-large-uncommon.xml')
        hpxml.header.utility_bill_scenarios.clear # we don't want the propane warning
        hpxml_bldg.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/occupancy-stochastic.csv')
        hpxml_bldg.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/occupancy-non-stochastic.csv')
        hpxml_bldg.hot_water_distributions[0].system_type = HPXML::DHWDistTypeRecirc
        hpxml_bldg.hot_water_distributions[0].recirculation_control_type = HPXML::DHWRecircControlTypeNone
        hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekday_fractions = @default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_no_control"]['RecirculationPumpWeekdayScheduleFractions']
        hpxml_bldg.hot_water_distributions[0].recirculation_pump_weekend_fractions = @default_schedules_csv_data["#{SchedulesFile::Columns[:HotWaterRecirculationPump].name}_no_control"]['RecirculationPumpWeekendScheduleFractions']
        hpxml_bldg.hot_water_distributions[0].recirculation_pump_monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:HotWaterRecirculationPump].name]['RecirculationPumpMonthlyScheduleMultipliers']
      when 'schedule-file-and-weekday-weekend-multipliers-ev'
        hpxml, hpxml_bldg = _create_hpxml('base-vehicle-ev-charger.xml')
        hpxml_bldg.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/vehicle-ev.csv')
        hpxml_bldg.vehicles[0].nominal_capacity_kwh = 500
        hpxml_bldg.vehicles[0].ev_weekday_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:ElectricVehicle].name]['WeekdayScheduleFractions']
        hpxml_bldg.vehicles[0].ev_weekend_fractions = @default_schedules_csv_data[SchedulesFile::Columns[:ElectricVehicle].name]['WeekendScheduleFractions']
        hpxml_bldg.vehicles[0].ev_monthly_multipliers = @default_schedules_csv_data[SchedulesFile::Columns[:ElectricVehicle].name]['MonthlyScheduleMultipliers']
      when 'schedule-file-and-refrigerators-freezer-coefficients'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/occupancy-stochastic.csv')
        hpxml_bldg.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/occupancy-non-stochastic.csv')
        hpxml_bldg.refrigerators[0].primary_indicator = true
        hpxml_bldg.refrigerators[0].constant_coefficients = '-0.487, -0.340, -0.370, -0.361, -0.515, -0.684, -0.471, -0.159, -0.079, -0.417, -0.411, -0.386, -0.240, -0.314, -0.160, -0.121, -0.469, -0.412, -0.091, 0.077, -0.118, -0.247, -0.445, -0.544'
        hpxml_bldg.refrigerators[0].temperature_coefficients = '0.019, 0.016, 0.017, 0.016, 0.018, 0.021, 0.019, 0.015, 0.015, 0.019, 0.018, 0.018, 0.016, 0.017, 0.015, 0.015, 0.020, 0.020, 0.017, 0.014, 0.016, 0.017, 0.019, 0.020'
        hpxml_bldg.refrigerators.add(id: "Refrigerator#{hpxml_bldg.refrigerators.size + 1}",
                                     constant_coefficients: '-0.487, -0.340, -0.370, -0.361, -0.515, -0.684, -0.471, -0.159, -0.079, -0.417, -0.411, -0.386, -0.240, -0.314, -0.160, -0.121, -0.469, -0.412, -0.091, 0.077, -0.118, -0.247, -0.445, -0.544',
                                     temperature_coefficients: '0.019, 0.016, 0.017, 0.016, 0.018, 0.021, 0.019, 0.015, 0.015, 0.019, 0.018, 0.018, 0.016, 0.017, 0.015, 0.015, 0.020, 0.020, 0.017, 0.014, 0.016, 0.017, 0.019, 0.020')
        hpxml_bldg.freezers.add(id: "Freezer#{hpxml_bldg.freezers.size + 1}",
                                constant_coefficients: '-0.487, -0.340, -0.370, -0.361, -0.515, -0.684, -0.471, -0.159, -0.079, -0.417, -0.411, -0.386, -0.240, -0.314, -0.160, -0.121, -0.469, -0.412, -0.091, 0.077, -0.118, -0.247, -0.445, -0.544',
                                temperature_coefficients: '0.019, 0.016, 0.017, 0.016, 0.018, 0.021, 0.019, 0.015, 0.015, 0.019, 0.018, 0.018, 0.016, 0.017, 0.015, 0.015, 0.020, 0.020, 0.017, 0.014, 0.016, 0.017, 0.019, 0.020')
      when 'schedule-file-and-setpoints'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.water_heating_systems[0].temperature = 125
        hpxml_bldg.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/setpoints.csv')
        hpxml_bldg.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/water-heater-setpoints.csv')
      when 'schedule-file-and-operating-mode'
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump-operating-mode-heat-pump-only.xml')
        hpxml_bldg.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/water-heater-operating-modes.csv')
      when 'schedule-file-max-power-ratio-with-single-speed-system'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/hvac-variable-system-maximum-power-ratios-varied.csv')
      when 'schedule-file-max-power-ratio-with-two-speed-system'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-2-speed.xml')
        hpxml_bldg.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/hvac-variable-system-maximum-power-ratios-varied.csv')
      when 'schedule-file-max-power-ratio-with-separate-backup-system'
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml')
        hpxml_bldg.header.schedules_filepaths << File.join(File.dirname(__FILE__), '../resources/schedule_files/hvac-variable-system-maximum-power-ratios-varied.csv')
      when 'schedule-file-unknown-columns'
        hpxml, hpxml_bldg = _create_hpxml('base-schedules-detailed-occupancy-stochastic.xml')
        csv_data = CSV.read(File.join(File.dirname(hpxml.hpxml_path), hpxml_bldg.header.schedules_filepaths[0]))
        csv_data[0][csv_data[0].find_index('lighting_interior')] = 'unknown_column'
        File.write(@tmp_csv_path, csv_data.map(&:to_csv).join)
        hpxml_bldg.header.schedules_filepaths = [@tmp_csv_path]
      when 'storm-windows-low-window-ufactor'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.windows[0].ufactor = 0.25
        hpxml_bldg.windows[0].storm_type = 'clear'
      else
        fail "Unhandled case: #{warning_case}."
      end

      hpxml_doc = hpxml.to_doc()

      XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)
      _test_measure('warning', expected_warnings, building_id: building_id)
    end
  end

  private

  def _test_schema_validation(hpxml_path, schematron_schema_validator)
    errors, _warnings = XMLValidator.validate_against_schema(hpxml_path, schematron_schema_validator)
    if errors.size > 0
      flunk "#{hpxml_path}: #{errors}"
    end
  end

  def _test_schema_and_schematron_validation(hpxml_path, hpxml_doc, expected_errors: nil, expected_warnings: nil, test_name: nil)
    sct_errors, sct_warnings = XMLValidator.validate_against_schematron(hpxml_path, @schematron_validator, hpxml_doc)
    xsd_errors, xsd_warnings = XMLValidator.validate_against_schema(hpxml_path, @schema_validator)
    if not expected_errors.nil?
      _compare_errors_or_warnings('error', sct_errors + xsd_errors, expected_errors, test_name: test_name)
    end
    if not expected_warnings.nil?
      _compare_errors_or_warnings('warning', sct_warnings + xsd_warnings, expected_warnings, test_name: test_name)
    end
  end

  def _test_measure(error_or_warning, expected_errors_or_warnings, building_id: nil)
    # create an instance of the measure
    measure = HPXMLtoOpenStudio.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    args_hash['debug'] = true
    args_hash['output_dir'] = File.dirname(__FILE__)
    args_hash['building_id'] = building_id unless building_id.nil?
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    actual_errors_or_warnings = []
    if error_or_warning == 'error'
      assert_equal('Fail', result.value.valueName)

      result.stepErrors.each do |s|
        actual_errors_or_warnings << s
      end
    elsif error_or_warning == 'warning'
      # show the output
      result.showOutput() unless result.value.valueName == 'Success'

      assert_equal('Success', result.value.valueName)

      result.stepWarnings.each do |s|
        actual_errors_or_warnings << s
      end
    end

    _compare_errors_or_warnings(error_or_warning, actual_errors_or_warnings, expected_errors_or_warnings)
  end

  def _compare_errors_or_warnings(type, actual_msgs, expected_msgs, test_name: nil)
    if expected_msgs.empty?
      if actual_msgs.size > 0
        flunk "Found unexpected #{type} messages:\n#{actual_msgs}"
      end
    else
      expected_msgs.each do |expected_msg|
        found_msg = false
        actual_msgs.each do |actual_msg|
          next unless actual_msg.include? expected_msg

          found_msg = true
          actual_msgs.delete(actual_msg)
          break
        end

        if not found_msg
          flunk "Did not find expected #{type} message\n'#{expected_msg}'\nin\n#{actual_msgs}"
        end
      end
      if actual_msgs.size > 0
        # Only test an incomplete set of error messages for this test case due to the large size of similar error messages
        if test_name != 'multifamily-common-space-whole-sfa-or-mf-building-sim-false'
          flunk "Found extra #{type} messages:\n#{actual_msgs}"
        end
      end
    end
  end

  def _create_hpxml(hpxml_name, building_id: nil)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name), building_id: building_id)
    if not hpxml.errors.empty?
      hpxml.errors.each do |error|
        puts error
      end
      flunk "Did not successfully create HPXML file: #{hpxml_name}"
    end
    return hpxml, hpxml.buildings[0]
  end
end
