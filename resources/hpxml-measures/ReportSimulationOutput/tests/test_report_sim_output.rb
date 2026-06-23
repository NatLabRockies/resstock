# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require 'csv'
require_relative '../measure.rb'
require_relative '../../HPXMLtoOpenStudio/resources/xmlhelper.rb'
require_relative '../../HPXMLtoOpenStudio/resources/constants.rb'
require_relative '../../HPXMLtoOpenStudio/resources/version.rb'
require_relative '../../HPXMLtoOpenStudio/resources/calendar.rb'
require 'oga'
require 'json'

class ReportSimulationOutputTest < Minitest::Test
  def setup
    @tmp_hpxml_path = File.join(File.dirname(__FILE__), 'tmp.xml')

    # Obtain measure.xml outputs once
    measure_xml_path = File.join(File.dirname(__FILE__), '..', 'measure.xml')
    doc = XMLHelper.parse_file(measure_xml_path)
    @measure_xml_outputs = []
    XMLHelper.get_elements(doc, '//measure/outputs/output').each do |el|
      @measure_xml_outputs << XMLHelper.get_value(el, 'display_name', :string)
    end
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  AnnualRows = [
    "Energy Use: #{TE::Total} (MBtu)",
    "Energy Use: #{TE::Net} (MBtu)",
    "Fuel Use: #{FT::Elec}: #{TE::Total} (MBtu)",
    "Fuel Use: #{FT::Elec}: #{TE::Net} (MBtu)",
    "Fuel Use: #{FT::Gas}: #{TE::Total} (MBtu)",
    "Fuel Use: #{FT::Oil}: #{TE::Total} (MBtu)",
    "Fuel Use: #{FT::Propane}: #{TE::Total} (MBtu)",
    "Fuel Use: #{FT::WoodCord}: #{TE::Total} (MBtu)",
    "Fuel Use: #{FT::WoodPellets}: #{TE::Total} (MBtu)",
    "Fuel Use: #{FT::Coal}: #{TE::Total} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::Heating} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::HeatingFanPump} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::HeatingHeatPumpBackup} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::HeatingHeatPumpBackupFanPump} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::Cooling} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::CoolingFanPump} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::HotWater} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::HotWaterRecircPump} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::HotWaterSolarThermalPump} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::LightsInterior} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::LightsGarage} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::LightsExterior} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::MechVent} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::MechVentPreheat} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::MechVentPrecool} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::WholeHouseFan} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::Refrigerator} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::Freezer} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::Dehumidifier} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::Dishwasher} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::ClothesWasher} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::ClothesDryer} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::RangeOven} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::CeilingFan} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::Television} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::PlugLoads} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::WellPump} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::PoolHeater} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::PoolPump} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::PermanentSpaHeater} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::PermanentSpaPump} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::PV} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::Generator} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::Battery} (MBtu)",
    "End Use: #{FT::Elec}: #{EUT::Vehicle} (MBtu)",
    "End Use: #{FT::Gas}: #{EUT::Heating} (MBtu)",
    "End Use: #{FT::Gas}: #{EUT::HeatingHeatPumpBackup} (MBtu)",
    "End Use: #{FT::Gas}: #{EUT::HotWater} (MBtu)",
    "End Use: #{FT::Gas}: #{EUT::MechVentPreheat} (MBtu)",
    "End Use: #{FT::Gas}: #{EUT::ClothesDryer} (MBtu)",
    "End Use: #{FT::Gas}: #{EUT::RangeOven} (MBtu)",
    "End Use: #{FT::Gas}: #{EUT::PoolHeater} (MBtu)",
    "End Use: #{FT::Gas}: #{EUT::PermanentSpaHeater} (MBtu)",
    "End Use: #{FT::Gas}: #{EUT::Grill} (MBtu)",
    "End Use: #{FT::Gas}: #{EUT::Lighting} (MBtu)",
    "End Use: #{FT::Gas}: #{EUT::Fireplace} (MBtu)",
    "End Use: #{FT::Gas}: #{EUT::Generator} (MBtu)",
    "End Use: #{FT::Oil}: #{EUT::Heating} (MBtu)",
    "End Use: #{FT::Oil}: #{EUT::HeatingHeatPumpBackup} (MBtu)",
    "End Use: #{FT::Oil}: #{EUT::HotWater} (MBtu)",
    "End Use: #{FT::Oil}: #{EUT::MechVentPreheat} (MBtu)",
    "End Use: #{FT::Oil}: #{EUT::ClothesDryer} (MBtu)",
    "End Use: #{FT::Oil}: #{EUT::RangeOven} (MBtu)",
    "End Use: #{FT::Oil}: #{EUT::Grill} (MBtu)",
    "End Use: #{FT::Oil}: #{EUT::Lighting} (MBtu)",
    "End Use: #{FT::Oil}: #{EUT::Fireplace} (MBtu)",
    "End Use: #{FT::Oil}: #{EUT::Generator} (MBtu)",
    "End Use: #{FT::Propane}: #{EUT::Heating} (MBtu)",
    "End Use: #{FT::Propane}: #{EUT::HeatingHeatPumpBackup} (MBtu)",
    "End Use: #{FT::Propane}: #{EUT::HotWater} (MBtu)",
    "End Use: #{FT::Propane}: #{EUT::MechVentPreheat} (MBtu)",
    "End Use: #{FT::Propane}: #{EUT::ClothesDryer} (MBtu)",
    "End Use: #{FT::Propane}: #{EUT::RangeOven} (MBtu)",
    "End Use: #{FT::Propane}: #{EUT::Grill} (MBtu)",
    "End Use: #{FT::Propane}: #{EUT::Lighting} (MBtu)",
    "End Use: #{FT::Propane}: #{EUT::Fireplace} (MBtu)",
    "End Use: #{FT::Propane}: #{EUT::Generator} (MBtu)",
    "End Use: #{FT::WoodCord}: #{EUT::Heating} (MBtu)",
    "End Use: #{FT::WoodCord}: #{EUT::HeatingHeatPumpBackup} (MBtu)",
    "End Use: #{FT::WoodCord}: #{EUT::HotWater} (MBtu)",
    "End Use: #{FT::WoodCord}: #{EUT::MechVentPreheat} (MBtu)",
    "End Use: #{FT::WoodCord}: #{EUT::ClothesDryer} (MBtu)",
    "End Use: #{FT::WoodCord}: #{EUT::RangeOven} (MBtu)",
    "End Use: #{FT::WoodCord}: #{EUT::Grill} (MBtu)",
    "End Use: #{FT::WoodCord}: #{EUT::Lighting} (MBtu)",
    "End Use: #{FT::WoodCord}: #{EUT::Fireplace} (MBtu)",
    "End Use: #{FT::WoodCord}: #{EUT::Generator} (MBtu)",
    "End Use: #{FT::WoodPellets}: #{EUT::Heating} (MBtu)",
    "End Use: #{FT::WoodPellets}: #{EUT::HeatingHeatPumpBackup} (MBtu)",
    "End Use: #{FT::WoodPellets}: #{EUT::HotWater} (MBtu)",
    "End Use: #{FT::WoodPellets}: #{EUT::MechVentPreheat} (MBtu)",
    "End Use: #{FT::WoodPellets}: #{EUT::ClothesDryer} (MBtu)",
    "End Use: #{FT::WoodPellets}: #{EUT::RangeOven} (MBtu)",
    "End Use: #{FT::WoodPellets}: #{EUT::Grill} (MBtu)",
    "End Use: #{FT::WoodPellets}: #{EUT::Lighting} (MBtu)",
    "End Use: #{FT::WoodPellets}: #{EUT::Fireplace} (MBtu)",
    "End Use: #{FT::WoodPellets}: #{EUT::Generator} (MBtu)",
    "End Use: #{FT::Coal}: #{EUT::Heating} (MBtu)",
    "End Use: #{FT::Coal}: #{EUT::HeatingHeatPumpBackup} (MBtu)",
    "End Use: #{FT::Coal}: #{EUT::HotWater} (MBtu)",
    "End Use: #{FT::Coal}: #{EUT::MechVentPreheat} (MBtu)",
    "End Use: #{FT::Coal}: #{EUT::ClothesDryer} (MBtu)",
    "End Use: #{FT::Coal}: #{EUT::RangeOven} (MBtu)",
    "End Use: #{FT::Coal}: #{EUT::Grill} (MBtu)",
    "End Use: #{FT::Coal}: #{EUT::Lighting} (MBtu)",
    "End Use: #{FT::Coal}: #{EUT::Fireplace} (MBtu)",
    "End Use: #{FT::Coal}: #{EUT::Generator} (MBtu)",
    "System Use: HeatingSystem1: #{FT::Elec}: #{EUT::HeatingFanPump} (MBtu)",
    "System Use: HeatingSystem1: #{FT::Gas}: #{EUT::Heating} (MBtu)",
    "System Use: CoolingSystem1: #{FT::Elec}: #{EUT::Cooling} (MBtu)",
    "System Use: CoolingSystem1: #{FT::Elec}: #{EUT::CoolingFanPump} (MBtu)",
    "System Use: WaterHeatingSystem1: #{FT::Elec}: #{EUT::HotWater} (MBtu)",
    "Load: #{LT::Heating} (MBtu)",
    "Load: #{LT::HeatingHeatPumpBackup} (MBtu)",
    "Load: #{LT::Cooling} (MBtu)",
    "Load: #{LT::HotWaterDelivered} (MBtu)",
    "Load: #{LT::HotWaterTankLosses} (MBtu)",
    "Load: #{LT::HotWaterDesuperheater} (MBtu)",
    "Load: #{LT::HotWaterSolarThermal} (MBtu)",
    "Unmet Hours: #{UHT::Heating} (hr)",
    "Unmet Hours: #{UHT::Cooling} (hr)",
    "Unmet Hours: #{UHT::Driving} (hr)",
    "Peak Electricity: #{PFT::Winter} #{TE::Total} (W)",
    "Peak Electricity: #{PFT::Summer} #{TE::Total} (W)",
    "Peak Electricity: #{PFT::Annual} #{TE::Total} (W)",
    "Peak Electricity: #{PFT::Winter} #{TE::Net} (W)",
    "Peak Electricity: #{PFT::Summer} #{TE::Net} (W)",
    "Peak Electricity: #{PFT::Annual} #{TE::Net} (W)",
    "Peak Load: #{PLT::Heating} (kBtu/hr)",
    "Peak Load: #{PLT::Cooling} (kBtu/hr)",
    "Component Load: Heating: #{CLT::Roofs} (MBtu)",
    "Component Load: Heating: #{CLT::Ceilings} (MBtu)",
    "Component Load: Heating: #{CLT::Walls} (MBtu)",
    "Component Load: Heating: #{CLT::RimJoists} (MBtu)",
    "Component Load: Heating: #{CLT::FoundationWalls} (MBtu)",
    "Component Load: Heating: #{CLT::Doors} (MBtu)",
    "Component Load: Heating: #{CLT::WindowsConduction} (MBtu)",
    "Component Load: Heating: #{CLT::WindowsSolar} (MBtu)",
    "Component Load: Heating: #{CLT::SkylightsConduction} (MBtu)",
    "Component Load: Heating: #{CLT::SkylightsSolar} (MBtu)",
    "Component Load: Heating: #{CLT::Floors} (MBtu)",
    "Component Load: Heating: #{CLT::Slabs} (MBtu)",
    "Component Load: Heating: #{CLT::InternalMass} (MBtu)",
    "Component Load: Heating: #{CLT::Infiltration} (MBtu)",
    "Component Load: Heating: #{CLT::NaturalVentilation} (MBtu)",
    "Component Load: Heating: #{CLT::MechanicalVentilation} (MBtu)",
    "Component Load: Heating: #{CLT::WholeHouseFan} (MBtu)",
    "Component Load: Heating: #{CLT::Ducts} (MBtu)",
    "Component Load: Heating: #{CLT::InternalGains} (MBtu)",
    "Component Load: Heating: #{CLT::Lighting} (MBtu)",
    "Component Load: Cooling: #{CLT::Roofs} (MBtu)",
    "Component Load: Cooling: #{CLT::Ceilings} (MBtu)",
    "Component Load: Cooling: #{CLT::Walls} (MBtu)",
    "Component Load: Cooling: #{CLT::RimJoists} (MBtu)",
    "Component Load: Cooling: #{CLT::FoundationWalls} (MBtu)",
    "Component Load: Cooling: #{CLT::Doors} (MBtu)",
    "Component Load: Cooling: #{CLT::WindowsConduction} (MBtu)",
    "Component Load: Cooling: #{CLT::WindowsSolar} (MBtu)",
    "Component Load: Cooling: #{CLT::SkylightsConduction} (MBtu)",
    "Component Load: Cooling: #{CLT::SkylightsSolar} (MBtu)",
    "Component Load: Cooling: #{CLT::Floors} (MBtu)",
    "Component Load: Cooling: #{CLT::Slabs} (MBtu)",
    "Component Load: Cooling: #{CLT::InternalMass} (MBtu)",
    "Component Load: Cooling: #{CLT::Infiltration} (MBtu)",
    "Component Load: Cooling: #{CLT::NaturalVentilation} (MBtu)",
    "Component Load: Cooling: #{CLT::MechanicalVentilation} (MBtu)",
    "Component Load: Cooling: #{CLT::WholeHouseFan} (MBtu)",
    "Component Load: Cooling: #{CLT::Ducts} (MBtu)",
    "Component Load: Cooling: #{CLT::InternalGains} (MBtu)",
    "Component Load: Cooling: #{CLT::Lighting} (MBtu)",
    "Hot Water: #{HWT::ClothesWasher} (gal)",
    "Hot Water: #{HWT::Dishwasher} (gal)",
    "Hot Water: #{HWT::Fixtures} (gal)",
    "Hot Water: #{HWT::DistributionWaste} (gal)",
    'Resilience: Battery (hr)',
    'HVAC Capacity: Cooling (Btu/h)',
    'HVAC Capacity: Heating (Btu/h)',
    'HVAC Capacity: Heat Pump Backup (Btu/h)',
    'HVAC Design Temperature: Heating (F)',
    'HVAC Design Temperature: Cooling (F)',
    'HVAC Design Load: Heating: Total (Btu/h)',
    'HVAC Design Load: Heating: Ducts (Btu/h)',
    'HVAC Design Load: Heating: Windows (Btu/h)',
    'HVAC Design Load: Heating: Skylights (Btu/h)',
    'HVAC Design Load: Heating: Doors (Btu/h)',
    'HVAC Design Load: Heating: Walls (Btu/h)',
    'HVAC Design Load: Heating: Roofs (Btu/h)',
    'HVAC Design Load: Heating: Floors (Btu/h)',
    'HVAC Design Load: Heating: Slabs (Btu/h)',
    'HVAC Design Load: Heating: Ceilings (Btu/h)',
    'HVAC Design Load: Heating: Infiltration (Btu/h)',
    'HVAC Design Load: Heating: Ventilation (Btu/h)',
    'HVAC Design Load: Heating: Piping (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Total (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Ducts (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Windows (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Skylights (Btu/h)',
    'HVAC Design Load: Cooling Sensible: AED Excursion (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Doors (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Walls (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Roofs (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Floors (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Slabs (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Ceilings (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Infiltration (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Ventilation (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Internal Gains (Btu/h)',
    'HVAC Design Load: Cooling Sensible: Blower Heat (Btu/h)',
    'HVAC Design Load: Cooling Latent: Total (Btu/h)',
    'HVAC Design Load: Cooling Latent: Ducts (Btu/h)',
    'HVAC Design Load: Cooling Latent: Infiltration (Btu/h)',
    'HVAC Design Load: Cooling Latent: Ventilation (Btu/h)',
    'HVAC Design Load: Cooling Latent: Internal Gains (Btu/h)',
    'HVAC Geothermal Loop: Borehole/Trench Count',
    'HVAC Geothermal Loop: Borehole/Trench Length (ft)'
  ]

  BaseHPXMLTimeseriesColsEnergy = [
    "Energy Use: #{TE::Total}",
    "Energy Use: #{TE::Net}",
  ]

  BaseHPXMLTimeseriesColsFuels = [
    "Fuel Use: #{FT::Elec}: #{TE::Total}",
    "Fuel Use: #{FT::Elec}: #{TE::Net}",
    "Fuel Use: #{FT::Gas}: #{TE::Total}",
  ]

  BaseHPXMLTimeseriesColsEndUses = [
    "End Use: #{FT::Elec}: #{EUT::ClothesDryer}",
    "End Use: #{FT::Elec}: #{EUT::ClothesWasher}",
    "End Use: #{FT::Elec}: #{EUT::Cooling}",
    "End Use: #{FT::Elec}: #{EUT::CoolingFanPump}",
    "End Use: #{FT::Elec}: #{EUT::Dishwasher}",
    "End Use: #{FT::Elec}: #{EUT::HeatingFanPump}",
    "End Use: #{FT::Elec}: #{EUT::HotWater}",
    "End Use: #{FT::Elec}: #{EUT::LightsExterior}",
    "End Use: #{FT::Elec}: #{EUT::LightsInterior}",
    "End Use: #{FT::Elec}: #{EUT::PlugLoads}",
    "End Use: #{FT::Elec}: #{EUT::RangeOven}",
    "End Use: #{FT::Elec}: #{EUT::Refrigerator}",
    "End Use: #{FT::Elec}: #{EUT::Television}",
    "End Use: #{FT::Gas}: #{EUT::Heating}",
  ]

  BaseHPXMLTimeseriesColsSystemUses = [
    "System Use: HeatingSystem1: #{FT::Elec}: #{EUT::HeatingFanPump}",
    "System Use: HeatingSystem1: #{FT::Gas}: #{EUT::Heating}",
    "System Use: CoolingSystem1: #{FT::Elec}: #{EUT::Cooling}",
    "System Use: CoolingSystem1: #{FT::Elec}: #{EUT::CoolingFanPump}",
    "System Use: WaterHeatingSystem1: #{FT::Elec}: #{EUT::HotWater}",
  ]

  BaseHPXMLTimeseriesColsWaterUses = [
    "Hot Water: #{HWT::ClothesWasher}",
    "Hot Water: #{HWT::Dishwasher}",
    "Hot Water: #{HWT::Fixtures}",
    "Hot Water: #{HWT::DistributionWaste}",
  ]

  BaseHPXMLTimeseriesColsResilience = [
    'Resilience: Battery'
  ]

  BaseHPXMLTimeseriesColsTotalLoads = [
    "Load: #{LT::Heating}",
    "Load: #{LT::Cooling}",
    "Load: #{LT::HotWaterDelivered}",
    "Load: #{LT::HotWaterTankLosses}"
  ]

  BaseHPXMLTimeseriesColsComponentLoads = [
    "Component Load: Cooling: #{CLT::Ceilings}",
    "Component Load: Cooling: #{CLT::Doors}",
    "Component Load: Cooling: #{CLT::Ducts}",
    "Component Load: Cooling: #{CLT::FoundationWalls}",
    "Component Load: Cooling: #{CLT::Infiltration}",
    "Component Load: Cooling: #{CLT::Lighting}",
    "Component Load: Cooling: #{CLT::InternalGains}",
    "Component Load: Cooling: #{CLT::InternalMass}",
    "Component Load: Cooling: #{CLT::MechanicalVentilation}",
    "Component Load: Cooling: #{CLT::NaturalVentilation}",
    "Component Load: Cooling: #{CLT::RimJoists}",
    "Component Load: Cooling: #{CLT::Slabs}",
    "Component Load: Cooling: #{CLT::Walls}",
    "Component Load: Cooling: #{CLT::WindowsConduction}",
    "Component Load: Cooling: #{CLT::WindowsSolar}",
    "Component Load: Heating: #{CLT::Ceilings}",
    "Component Load: Heating: #{CLT::Doors}",
    "Component Load: Heating: #{CLT::Ducts}",
    "Component Load: Heating: #{CLT::FoundationWalls}",
    "Component Load: Heating: #{CLT::Infiltration}",
    "Component Load: Heating: #{CLT::Lighting}",
    "Component Load: Heating: #{CLT::InternalGains}",
    "Component Load: Heating: #{CLT::InternalMass}",
    "Component Load: Heating: #{CLT::MechanicalVentilation}",
    "Component Load: Heating: #{CLT::RimJoists}",
    "Component Load: Heating: #{CLT::Slabs}",
    "Component Load: Heating: #{CLT::Walls}",
    "Component Load: Heating: #{CLT::WindowsConduction}",
    "Component Load: Heating: #{CLT::WindowsSolar}",
  ]

  BaseHPXMLTimeseriesColsUnmetHours = [
    "Unmet Hours: #{UHT::Heating}",
    "Unmet Hours: #{UHT::Cooling}",
    "Unmet Hours: #{UHT::Driving}",
  ]

  BaseHPXMLTimeseriesColsZoneTemps = [
    'Temperature: Attic - Unvented',
    'Temperature: Conditioned Space',
    'Temperature: Heating Setpoint',
    'Temperature: Cooling Setpoint',
  ]

  BaseHPXMLTimeseriesColsZoneConds = [
    'Humidity Ratio: Attic - Unvented',
    'Humidity Ratio: Conditioned Space',
    'Relative Humidity: Attic - Unvented',
    'Relative Humidity: Conditioned Space',
    'Dewpoint Temperature: Attic - Unvented',
    'Dewpoint Temperature: Conditioned Space',
    'Radiant Temperature: Attic - Unvented',
    'Radiant Temperature: Conditioned Space',
    'Operative Temperature: Attic - Unvented',
    'Operative Temperature: Conditioned Space',
  ]

  BaseHPXMLTimeseriesColsAirflows = [
    "Airflow: #{AFT::Infiltration}",
    "Airflow: #{AFT::MechanicalVentilation}",
    "Airflow: #{AFT::NaturalVentilation}",
  ]

  BaseHPXMLTimeseriesColsWeather = [
    "Weather: #{WT::DrybulbTemp}",
    "Weather: #{WT::WetbulbTemp}",
    "Weather: #{WT::RelativeHumidity}",
    "Weather: #{WT::WindSpeed}",
    "Weather: #{WT::DiffuseSolar}",
    "Weather: #{WT::DirectSolar}",
  ]

  BaseHPXMLTimeseriesColsEnergyPlusOutputVariables = [
    'Zone People Occupant Count: Conditioned Space',
    'Zone People Total Heating Energy: Conditioned Space',
    'Surface Construction Index: Door1',
    'Surface Construction Index: Foundationwall1',
    'Surface Construction Index: Floor1',
    'Surface Construction Index: Furniture Mass Conditioned Space 1',
    'Surface Construction Index: Inferred Conditioned Ceiling',
    'Surface Construction Index: Inferred Conditioned Floor',
    'Surface Construction Index: Partition Wall Mass',
    'Surface Construction Index: Rimjoist1:0',
    'Surface Construction Index: Rimjoist1:90',
    'Surface Construction Index: Rimjoist1:180',
    'Surface Construction Index: Rimjoist1:270',
    'Surface Construction Index: Roof1:0',
    'Surface Construction Index: Roof1:90',
    'Surface Construction Index: Roof1:180',
    'Surface Construction Index: Roof1:270',
    'Surface Construction Index: Slab1',
    'Surface Construction Index: Surface 1',
    'Surface Construction Index: Surface 1 Reversed',
    'Surface Construction Index: Surface 2',
    'Surface Construction Index: Surface 3',
    'Surface Construction Index: Surface 4',
    'Surface Construction Index: Surface 5',
    'Surface Construction Index: Surface 6',
    'Surface Construction Index: Surface Door1',
    'Surface Construction Index: Surface Window1',
    'Surface Construction Index: Surface Window2',
    'Surface Construction Index: Surface Window3',
    'Surface Construction Index: Surface Window4',
    'Surface Construction Index: Wall1:0',
    'Surface Construction Index: Wall1:90',
    'Surface Construction Index: Wall1:180',
    'Surface Construction Index: Wall1:270',
    'Surface Construction Index: Wall2:0',
    'Surface Construction Index: Wall2:90',
    'Surface Construction Index: Wall2:180',
    'Surface Construction Index: Wall2:270',
    'Surface Construction Index: Window1',
    'Surface Construction Index: Window2',
    'Surface Construction Index: Window3',
    'Surface Construction Index: Window4'
  ]

  BaseHPXMLTimeseriesColsEnergyPlusOutputMeters = [
    'MainsWater:Facility',
    'HeatingCoils:EnergyTransfer'
  ]

  def all_base_hpxml_timeseries_cols
    return (BaseHPXMLTimeseriesColsEnergy +
            BaseHPXMLTimeseriesColsFuels +
            BaseHPXMLTimeseriesColsEndUses +
            BaseHPXMLTimeseriesColsSystemUses +
            BaseHPXMLTimeseriesColsWaterUses +
            BaseHPXMLTimeseriesColsTotalLoads +
            BaseHPXMLTimeseriesColsUnmetHours +
            BaseHPXMLTimeseriesColsZoneTemps +
            BaseHPXMLTimeseriesColsZoneConds +
            BaseHPXMLTimeseriesColsAirflows +
            BaseHPXMLTimeseriesColsWeather)
  end

  def emission_scenarios
    return ['CO2e: Cambium Hourly MidCase LRMER RMPA',
            'CO2e: Cambium Hourly LowRECosts LRMER RMPA',
            'CO2e: Cambium Annual MidCase AER National',
            'SO2: eGRID RMPA',
            'NOx: eGRID RMPA']
  end

  def emission_annual_cols
    cols = []
    emission_scenarios.each do |scenario|
      cols.concat(["Emissions: #{scenario}: #{TE::Total} (lb)",
                   "Emissions: #{scenario}: #{TE::Net} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{TE::Total} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{TE::Net} (lb)",
                   "Emissions: #{scenario}: #{FT::Gas}: #{TE::Total} (lb)",
                   "Emissions: #{scenario}: #{FT::Oil}: #{TE::Total} (lb)",
                   "Emissions: #{scenario}: #{FT::Propane}: #{TE::Total} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodCord}: #{TE::Total} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodPellets}: #{TE::Total} (lb)",
                   "Emissions: #{scenario}: #{FT::Coal}: #{TE::Total} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Heating} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::HeatingFanPump} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::HeatingHeatPumpBackup} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::HeatingHeatPumpBackupFanPump} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Cooling} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::CoolingFanPump} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::HotWater} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::HotWaterRecircPump} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::HotWaterSolarThermalPump} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::LightsInterior} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::LightsGarage} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::LightsExterior} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::MechVent} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::MechVentPreheat} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::MechVentPrecool} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::WholeHouseFan} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Refrigerator} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Freezer} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Dehumidifier} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Dishwasher} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::ClothesWasher} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::ClothesDryer} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::RangeOven} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::CeilingFan} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Television} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::PlugLoads} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::WellPump} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::PoolHeater} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::PoolPump} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::PermanentSpaHeater} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::PermanentSpaPump} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::PV} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Generator} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Battery} (lb)",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Vehicle} (lb)",
                   "Emissions: #{scenario}: #{FT::Gas}: #{EUT::Heating} (lb)",
                   "Emissions: #{scenario}: #{FT::Gas}: #{EUT::HeatingHeatPumpBackup} (lb)",
                   "Emissions: #{scenario}: #{FT::Gas}: #{EUT::HotWater} (lb)",
                   "Emissions: #{scenario}: #{FT::Gas}: #{EUT::ClothesDryer} (lb)",
                   "Emissions: #{scenario}: #{FT::Gas}: #{EUT::RangeOven} (lb)",
                   "Emissions: #{scenario}: #{FT::Gas}: #{EUT::PoolHeater} (lb)",
                   "Emissions: #{scenario}: #{FT::Gas}: #{EUT::PermanentSpaHeater} (lb)",
                   "Emissions: #{scenario}: #{FT::Gas}: #{EUT::Grill} (lb)",
                   "Emissions: #{scenario}: #{FT::Gas}: #{EUT::Lighting} (lb)",
                   "Emissions: #{scenario}: #{FT::Gas}: #{EUT::Fireplace} (lb)",
                   "Emissions: #{scenario}: #{FT::Gas}: #{EUT::MechVentPreheat} (lb)",
                   "Emissions: #{scenario}: #{FT::Gas}: #{EUT::Generator} (lb)",
                   "Emissions: #{scenario}: #{FT::Oil}: #{EUT::Heating} (lb)",
                   "Emissions: #{scenario}: #{FT::Oil}: #{EUT::HeatingHeatPumpBackup} (lb)",
                   "Emissions: #{scenario}: #{FT::Oil}: #{EUT::HotWater} (lb)",
                   "Emissions: #{scenario}: #{FT::Oil}: #{EUT::ClothesDryer} (lb)",
                   "Emissions: #{scenario}: #{FT::Oil}: #{EUT::RangeOven} (lb)",
                   "Emissions: #{scenario}: #{FT::Oil}: #{EUT::Grill} (lb)",
                   "Emissions: #{scenario}: #{FT::Oil}: #{EUT::Lighting} (lb)",
                   "Emissions: #{scenario}: #{FT::Oil}: #{EUT::Fireplace} (lb)",
                   "Emissions: #{scenario}: #{FT::Oil}: #{EUT::MechVentPreheat} (lb)",
                   "Emissions: #{scenario}: #{FT::Oil}: #{EUT::Generator} (lb)",
                   "Emissions: #{scenario}: #{FT::Propane}: #{EUT::Heating} (lb)",
                   "Emissions: #{scenario}: #{FT::Propane}: #{EUT::HeatingHeatPumpBackup} (lb)",
                   "Emissions: #{scenario}: #{FT::Propane}: #{EUT::HotWater} (lb)",
                   "Emissions: #{scenario}: #{FT::Propane}: #{EUT::ClothesDryer} (lb)",
                   "Emissions: #{scenario}: #{FT::Propane}: #{EUT::RangeOven} (lb)",
                   "Emissions: #{scenario}: #{FT::Propane}: #{EUT::Grill} (lb)",
                   "Emissions: #{scenario}: #{FT::Propane}: #{EUT::Lighting} (lb)",
                   "Emissions: #{scenario}: #{FT::Propane}: #{EUT::Fireplace} (lb)",
                   "Emissions: #{scenario}: #{FT::Propane}: #{EUT::MechVentPreheat} (lb)",
                   "Emissions: #{scenario}: #{FT::Propane}: #{EUT::Generator} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodCord}: #{EUT::Heating} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodCord}: #{EUT::HeatingHeatPumpBackup} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodCord}: #{EUT::HotWater} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodCord}: #{EUT::ClothesDryer} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodCord}: #{EUT::RangeOven} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodCord}: #{EUT::Grill} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodCord}: #{EUT::Lighting} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodCord}: #{EUT::Fireplace} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodCord}: #{EUT::MechVentPreheat} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodCord}: #{EUT::Generator} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodPellets}: #{EUT::Heating} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodPellets}: #{EUT::HeatingHeatPumpBackup} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodPellets}: #{EUT::HotWater} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodPellets}: #{EUT::ClothesDryer} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodPellets}: #{EUT::RangeOven} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodPellets}: #{EUT::Grill} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodPellets}: #{EUT::Lighting} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodPellets}: #{EUT::Fireplace} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodPellets}: #{EUT::MechVentPreheat} (lb)",
                   "Emissions: #{scenario}: #{FT::WoodPellets}: #{EUT::Generator} (lb)",
                   "Emissions: #{scenario}: #{FT::Coal}: #{EUT::Heating} (lb)",
                   "Emissions: #{scenario}: #{FT::Coal}: #{EUT::HeatingHeatPumpBackup} (lb)",
                   "Emissions: #{scenario}: #{FT::Coal}: #{EUT::HotWater} (lb)",
                   "Emissions: #{scenario}: #{FT::Coal}: #{EUT::ClothesDryer} (lb)",
                   "Emissions: #{scenario}: #{FT::Coal}: #{EUT::RangeOven} (lb)",
                   "Emissions: #{scenario}: #{FT::Coal}: #{EUT::Grill} (lb)",
                   "Emissions: #{scenario}: #{FT::Coal}: #{EUT::Lighting} (lb)",
                   "Emissions: #{scenario}: #{FT::Coal}: #{EUT::Fireplace} (lb)",
                   "Emissions: #{scenario}: #{FT::Coal}: #{EUT::MechVentPreheat} (lb)",
                   "Emissions: #{scenario}: #{FT::Coal}: #{EUT::Generator} (lb)"])
    end
    return cols
  end

  def emissions_timeseries_cols
    cols = []
    emission_scenarios.each do |scenario|
      cols.concat(["Emissions: #{scenario}: #{TE::Total}",
                   "Emissions: #{scenario}: #{TE::Net}"])
    end
    return cols
  end

  def emission_fuels_timeseries_cols
    cols = []
    emission_scenarios.each do |scenario|
      cols.concat(["Emissions: #{scenario}: #{FT::Elec}: #{TE::Total}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{TE::Net}",
                   "Emissions: #{scenario}: #{FT::Gas}: #{TE::Total}"])
    end
    return cols
  end

  def emission_end_uses_timeseries_cols
    cols = []
    emission_scenarios.each do |scenario|
      cols.concat(["Emissions: #{scenario}: #{FT::Elec}: #{EUT::Cooling}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::CoolingFanPump}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::HeatingFanPump}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::HotWater}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::LightsInterior}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::LightsExterior}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Refrigerator}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Dishwasher}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::ClothesWasher}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::ClothesDryer}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::RangeOven}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Television}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::PlugLoads}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::PV}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Battery}",
                   "Emissions: #{scenario}: #{FT::Elec}: #{EUT::Vehicle}",
                   "Emissions: #{scenario}: #{FT::Gas}: #{EUT::Heating}"])
    end
    return cols
  end

  def pv_battery_timeseries_cols
    return ["End Use: #{FT::Elec}: #{EUT::PV}",
            "End Use: #{FT::Elec}: #{EUT::Battery}",
            "End Use: #{FT::Elec}: #{EUT::Vehicle}"]
  end

  def test_annual_only
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'skip_validation' => true,
                  'add_component_loads' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_total_consumptions' => false,
                  'include_timeseries_fuel_consumptions' => false,
                  'include_timeseries_end_use_consumptions' => false,
                  'include_timeseries_system_use_consumptions' => false,
                  'include_timeseries_emissions' => false,
                  'include_timeseries_emission_fuels' => false,
                  'include_timeseries_emission_end_uses' => false,
                  'include_timeseries_hot_water_uses' => false,
                  'include_timeseries_total_loads' => false,
                  'include_timeseries_unmet_hours' => false,
                  'include_timeseries_component_loads' => false,
                  'include_timeseries_zone_temperatures' => false,
                  'include_timeseries_zone_conditions' => false,
                  'include_timeseries_airflows' => false,
                  'include_timeseries_weather' => false,
                  'include_timeseries_resilience' => false }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(!File.exist?(timeseries_csv))
    expected_annual_rows = AnnualRows
    actual_annual_rows = _get_annual_values(annual_csv)
    assert_equal(expected_annual_rows.sort, actual_annual_rows.keys.sort)
    _check_runner_registered_values_and_measure_xml_outputs(actual_annual_rows)

    # Verify refrigerator energy use correctly impacted by ambient temperature
    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])
    actual_fridge_energy_use = actual_annual_rows["End Use: #{FT::Elec}: #{EUT::Refrigerator} (MBtu)"]
    rated_fridge_energy_use = UnitConversions.convert(hpxml.buildings[0].refrigerators[0].rated_annual_kwh, 'kWh', 'MBtu')
    assert_in_epsilon(0.93, actual_fridge_energy_use / rated_fridge_energy_use, 0.1)

    # Verify Total/Net outputs when no PV
    actual_annual_rows = _get_annual_values(annual_csv)
    assert_equal(actual_annual_rows["Energy Use: #{TE::Total} (MBtu)"], actual_annual_rows["Energy Use: #{TE::Net} (MBtu)"])
    assert_equal(actual_annual_rows["Fuel Use: #{FT::Elec}: #{TE::Total} (MBtu)"], actual_annual_rows["Fuel Use: #{FT::Elec}: #{TE::Net} (MBtu)"])
  end

  def test_annual_only2
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'skip_validation' => true,
                  'add_component_loads' => true,
                  'timeseries_frequency' => 'none',
                  'include_timeseries_total_consumptions' => true,
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_system_use_consumptions' => true,
                  'include_timeseries_emissions' => true,
                  'include_timeseries_emission_fuels' => true,
                  'include_timeseries_emission_end_uses' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_unmet_hours' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_zone_conditions' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true,
                  'include_timeseries_resilience' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(!File.exist?(timeseries_csv))
    expected_annual_rows = AnnualRows + emission_annual_cols
    actual_annual_rows = _get_annual_values(annual_csv)
    assert_equal(expected_annual_rows.sort, actual_annual_rows.keys.sort)
    _check_runner_registered_values_and_measure_xml_outputs(actual_annual_rows)
  end

  def test_annual_disabled_outputs
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'skip_validation' => true,
                  'include_annual_total_consumptions' => false,
                  'include_annual_fuel_consumptions' => false,
                  'include_annual_end_use_consumptions' => false,
                  'include_annual_system_use_consumptions' => false,
                  'include_annual_emissions' => false,
                  'include_annual_emission_fuels' => false,
                  'include_annual_emission_end_uses' => false,
                  'include_annual_total_loads' => false,
                  'include_annual_unmet_hours' => false,
                  'include_annual_peak_fuels' => false,
                  'include_annual_peak_loads' => false,
                  'include_annual_component_loads' => false,
                  'include_annual_hot_water_uses' => false,
                  'include_annual_hvac_summary' => false,
                  'include_annual_resilience' => false }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(!File.exist?(timeseries_csv))
    actual_annual_rows = _get_annual_values(annual_csv)
    assert(actual_annual_rows.keys.empty?)
  end

  def test_timeseries_hourly_total_energy
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-pv.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_total_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsEnergy
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, ["Energy Use: #{TE::Total}",
                                                             "Energy Use: #{TE::Net}"])
    # Verify Total/Net outputs when PV
    actual_annual_rows = _get_annual_values(annual_csv)
    assert_operator(actual_annual_rows["Energy Use: #{TE::Total} (MBtu)"], :>, actual_annual_rows["Energy Use: #{TE::Net} (MBtu)"])
    assert_operator(actual_annual_rows["Fuel Use: #{FT::Elec}: #{TE::Total} (MBtu)"], :>, actual_annual_rows["Fuel Use: #{FT::Elec}: #{TE::Net} (MBtu)"])
  end

  def test_timeseries_hourly_fuels
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-pv.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsFuels
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, ["Fuel Use: #{FT::Elec}: #{TE::Total}",
                                                             "Fuel Use: #{FT::Elec}: #{TE::Net}"])
  end

  def test_timeseries_hourly_emissions
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_emissions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + emissions_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    _check_for_constant_timeseries_step(timeseries_cols[0])
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, emissions_timeseries_cols[0..2])
  end

  def test_timeseries_hourly_emission_end_uses
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_emission_end_uses' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + emission_end_uses_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    _check_for_constant_timeseries_step(timeseries_cols[0])
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, emission_end_uses_timeseries_cols[0..2])
  end

  def test_timeseries_hourly_emission_fuels
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_emission_fuels' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + emission_fuels_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    _check_for_constant_timeseries_step(timeseries_cols[0])
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, emission_fuels_timeseries_cols[0..2])
  end

  def test_timeseries_hourly_enduses
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_end_use_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsEndUses
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, ["End Use: #{FT::Elec}: #{EUT::PlugLoads}"])
  end

  def test_timeseries_hourly_enduses_vacancy
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-schedules-simple-vacancy.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_end_use_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsEndUses + ["End Use: #{FT::Elec}: #{EUT::HotWaterRecircPump}"]
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_zero_timeseries_values(timeseries_csv, ["End Use: #{FT::Elec}: #{EUT::PlugLoads}"], 0, 31 * 24 - 1) # Jan
    _check_for_zero_timeseries_values(timeseries_csv, ["End Use: #{FT::Elec}: #{EUT::PlugLoads}"], (31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30) * 24 + 1, -1) # Dec
    _check_for_nonzero_timeseries_values(timeseries_csv, ["End Use: #{FT::Elec}: #{EUT::Refrigerator}"])
    positive_cols = actual_timeseries_cols.select { |col| col.start_with?('End Use:') }
    _check_for_positive_timeseries_values(timeseries_csv, positive_cols)
  end

  def test_timeseries_hourly_system_uses
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_system_use_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsSystemUses
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, ["System Use: HeatingSystem1: #{FT::Gas}: #{EUT::Heating}"])
  end

  def test_timeseries_hourly_hotwater_uses
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_hot_water_uses' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsWaterUses
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsWaterUses)
  end

  def test_timeseries_hourly_total_loads
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_total_loads' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsTotalLoads
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsTotalLoads)
  end

  def test_timeseries_hourly_component_loads
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'skip_validation' => true,
                  'add_component_loads' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_component_loads' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsComponentLoads
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, ["Component Load: Heating: #{CLT::InternalGains}",
                                                             "Component Load: Cooling: #{CLT::InternalGains}"])
  end

  def test_timeseries_hourly_unmet_hours
    { 'base-hvac-undersized.xml' => ["Unmet Hours: #{UHT::Heating}", "Unmet Hours: #{UHT::Cooling}"],
      'base-vehicle-ev-charger-undercharged.xml' => ["Unmet Hours: #{UHT::Driving}"] }.each do |xml_file, unmet_hours_cols|
      args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), "../../workflow/sample_files/#{xml_file}"),
                    'skip_validation' => true,
                    'add_component_loads' => true,
                    'timeseries_frequency' => 'hourly',
                    'include_timeseries_unmet_hours' => true }
      annual_csv, timeseries_csv, run_log = _test_measure(args_hash)
      assert(File.exist?(annual_csv))
      assert(File.exist?(timeseries_csv))
      expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsUnmetHours
      actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
      assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
      timeseries_rows = CSV.read(timeseries_csv)
      assert_equal(8760, timeseries_rows.size - 2)
      timeseries_cols = timeseries_rows.transpose
      assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
      _check_for_nonzero_avg_timeseries_value(timeseries_csv, unmet_hours_cols)
      if xml_file == 'base-vehicle-ev-charger-undercharged.xml'
        assert(File.readlines(run_log).any? { |line| line.include?('driving hours could not be met') })
      end
    end
  end

  def test_timeseries_hourly_zone_temperatures
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-hvac-furnace-gas-only.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_temperatures' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsZoneTemps - ['Temperature: Cooling Setpoint']
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsZoneTemps - ['Temperature: Cooling Setpoint'])
  end

  def test_timeseries_hourly_zone_temperatures_mf_spaces
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-bldgtype-mf-unit-adjacent-to-multiple.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_temperatures' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    cols_temps = BaseHPXMLTimeseriesColsZoneTemps - ['Temperature: Attic - Unvented']
    cols_temps_other_side = ['Temperature: Other Multifamily Buffer Space',
                             'Temperature: Other Non-freezing Space',
                             'Temperature: Other Housing Unit',
                             'Temperature: Other Heated Space']
    expected_timeseries_cols = ['Time'] + cols_temps + cols_temps_other_side
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, cols_temps + cols_temps_other_side)
  end

  def test_timeseries_hourly_zone_temperatures_whole_mf_building
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-bldgtype-mf-whole-building.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_temperatures' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    expected_timeseries_cols = ['Time']
    for i in 1..6
      expected_timeseries_cols << "Temperature: Unit#{i} Conditioned Space"
      if i <= 2
        expected_timeseries_cols << "Temperature: Unit#{i} Basement Unconditioned"
      elsif i >= 5
        expected_timeseries_cols << "Temperature: Unit#{i} Attic Vented"
      end
      expected_timeseries_cols << "Temperature: Unit#{i} Heating Setpoint"
      expected_timeseries_cols << "Temperature: Unit#{i} Cooling Setpoint"
    end
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
  end

  def test_timeseries_hourly_zone_conditions
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-hvac-furnace-gas-only.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_zone_conditions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsZoneConds
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsZoneConds)
  end

  def test_timeseries_hourly_airflows_with_mechvent
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-mechvent-multiple.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_airflows' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsAirflows - ['Airflow: Natural Ventilation'] + ['Airflow: Whole House Fan']
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsAirflows - ['Airflow: Natural Ventilation'] + ['Airflow: Whole House Fan'])
  end

  def test_timeseries_hourly_airflows_with_clothes_dryer_exhaust
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-appliances-gas.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_airflows' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsAirflows
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, ["Airflow: #{AFT::MechanicalVentilation}"])
  end

  def test_timeseries_hourly_weather
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsWeather
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsWeather)
  end

  def test_timeseries_hourly_ALL
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_total_consumptions' => true,
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_system_use_consumptions' => true,
                  'include_timeseries_emissions' => true,
                  'include_timeseries_emission_fuels' => true,
                  'include_timeseries_emission_end_uses' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_unmet_hours' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_zone_conditions' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true,
                  'include_timeseries_resilience' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] +
                               all_base_hpxml_timeseries_cols +
                               emissions_timeseries_cols +
                               emission_fuels_timeseries_cols +
                               emission_end_uses_timeseries_cols +
                               pv_battery_timeseries_cols +
                               BaseHPXMLTimeseriesColsResilience
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, emissions_timeseries_cols[0..2])
    _check_for_nonzero_timeseries_values(timeseries_csv, ["End Use: #{FT::Elec}: #{EUT::Refrigerator}"])
    negative_cols = ["End Use: #{FT::Elec}: #{EUT::PV}"]
    positive_cols = actual_timeseries_cols.select { |col| col.start_with?('End Use:') } - negative_cols - ["End Use: #{FT::Elec}: #{EUT::Battery}"]
    _check_for_negative_timeseries_values(timeseries_csv, negative_cols)
    _check_for_positive_timeseries_values(timeseries_csv, positive_cols)
  end

  def test_timeseries_daily_ALL
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'daily',
                  'include_timeseries_total_consumptions' => true,
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_system_use_consumptions' => true,
                  'include_timeseries_emissions' => true,
                  'include_timeseries_emission_fuels' => true,
                  'include_timeseries_emission_end_uses' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_unmet_hours' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_zone_conditions' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true,
                  'include_timeseries_resilience' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] +
                               all_base_hpxml_timeseries_cols +
                               emissions_timeseries_cols +
                               emission_fuels_timeseries_cols +
                               emission_end_uses_timeseries_cols +
                               pv_battery_timeseries_cols +
                               BaseHPXMLTimeseriesColsResilience
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(365, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, emissions_timeseries_cols[0..2])
    _check_for_nonzero_timeseries_values(timeseries_csv, ["End Use: #{FT::Elec}: #{EUT::Refrigerator}"])
  end

  def test_timeseries_monthly_ALL
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'monthly',
                  'include_timeseries_total_consumptions' => true,
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_end_use_consumptions' => true,
                  'include_timeseries_system_use_consumptions' => true,
                  'include_timeseries_emissions' => true,
                  'include_timeseries_emission_fuels' => true,
                  'include_timeseries_emission_end_uses' => true,
                  'include_timeseries_hot_water_uses' => true,
                  'include_timeseries_total_loads' => true,
                  'include_timeseries_unmet_hours' => true,
                  'include_timeseries_component_loads' => true,
                  'include_timeseries_zone_temperatures' => true,
                  'include_timeseries_zone_conditions' => true,
                  'include_timeseries_airflows' => true,
                  'include_timeseries_weather' => true,
                  'include_timeseries_resilience' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] +
                               all_base_hpxml_timeseries_cols +
                               emissions_timeseries_cols +
                               emission_fuels_timeseries_cols +
                               emission_end_uses_timeseries_cols +
                               pv_battery_timeseries_cols +
                               BaseHPXMLTimeseriesColsResilience
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(12, timeseries_rows.size - 2)
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, emissions_timeseries_cols[0..2])
    _check_for_nonzero_timeseries_values(timeseries_csv, ["End Use: #{FT::Elec}: #{EUT::Refrigerator}"])
  end

  def test_timeseries_monthly_resilience
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-pv-battery-scheduled.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'monthly',
                  'include_timeseries_resilience' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] +
                               BaseHPXMLTimeseriesColsResilience
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(12, timeseries_rows.size - 2)
  end

  def test_timeseries_timestep
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true,
                  'add_timeseries_dst_column' => true,
                  'add_timeseries_utc_column' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, timeseries_rows[0].count { |r| r == 'Time' })
    assert_equal(1, timeseries_rows[0].count { |r| r == 'TimeDST' })
    assert_equal(1, timeseries_rows[0].count { |r| r == 'TimeUTC' })
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    assert_equal(3, _check_for_constant_timeseries_step(timeseries_cols[1]))
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[2]))
  end

  def test_timeseries_json_timedst_timeutc
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'output_format' => 'json',
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => true,
                  'add_timeseries_dst_column' => true,
                  'add_timeseries_utc_column' => true }
    annual_json, timeseries_json = _test_measure(args_hash)
    assert(File.exist?(annual_json))
    assert(File.exist?(timeseries_json))
    timeseries_data = JSON.load(File.open(timeseries_json))
    assert(timeseries_data.keys.include? 'Time')
    assert(timeseries_data.keys.include? 'TimeDST')
    assert(timeseries_data.keys.include? 'TimeUTC')
    assert_equal(8760, timeseries_data['Time'].size)
    assert_equal(8760, timeseries_data['TimeDST'].size)
    assert_equal(8760, timeseries_data['TimeUTC'].size)
    assert_equal(1, _check_for_constant_timeseries_step(['Time', nil] + timeseries_data['Time']))
    assert_equal(3, _check_for_constant_timeseries_step(['TimeDST', nil] + timeseries_data['TimeDST']))
    assert_equal(1, _check_for_constant_timeseries_step(['TimeUTC', nil] + timeseries_data['TimeUTC']))
  end

  def test_timeseries_timestep_emissions
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-misc-emissions.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_emissions' => true,
                  'include_timeseries_emission_fuels' => true,
                  'include_timeseries_emission_end_uses' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] +
                               emissions_timeseries_cols +
                               emission_fuels_timeseries_cols +
                               emission_end_uses_timeseries_cols
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    _check_for_constant_timeseries_step(timeseries_cols[0])
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, emissions_timeseries_cols[0..2])
  end

  def test_timeseries_timestep_10min
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-simcontrol-timestep-10-mins.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(52560, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
  end

  def test_timeseries_hourly_runperiod_1month
    expected_values = { 'hourly' => 30 * 24, # Feb 15 - Mar 15, w/ leap day
                        'monthly' => 2 } # Feb, Mar

    expected_values.each do |timeseries_frequency, expected_value|
      args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-simcontrol-runperiod-1-month.xml'),
                    'skip_validation' => true,
                    'timeseries_frequency' => timeseries_frequency,
                    'include_timeseries_fuel_consumptions' => true,
                    'include_timeseries_emission_fuels' => true }
      annual_csv, timeseries_csv = _test_measure(args_hash)
      assert(File.exist?(annual_csv))
      assert(File.exist?(timeseries_csv))
      timeseries_rows = CSV.read(timeseries_csv)
      assert_equal(expected_value, timeseries_rows.size - 2)
      if timeseries_frequency != 'monthly'
        timeseries_cols = timeseries_rows.transpose
        assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
      end
    end
  end

  def test_timeseries_hourly_AMY_2012
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-location-AMY-2012.xml'),
                  'skip_validation' => true,
                  'timeseries_frequency' => 'hourly',
                  'include_timeseries_fuel_consumptions' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8784, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
  end

  def test_timeseries_timestamp_convention
    # Expected values are arrays of time offsets (in seconds) for each reported row of output
    expected_values_array = { 'timestep' => [30 * 60] * 17520,
                              'monthly' => Calendar.num_days_in_months(1999).map { |n_days| n_days * 60 * 60 * 24 } }

    expected_values_array.each do |timeseries_frequency, expected_values|
      args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-simcontrol-timestep-30-mins.xml'),
                    'skip_validation' => true,
                    'timeseries_frequency' => timeseries_frequency,
                    'include_timeseries_fuel_consumptions' => true,
                    'timeseries_timestamp_convention' => 'end' }
      annual_csv, timeseries_csv = _test_measure(args_hash)
      assert(File.exist?(annual_csv))
      assert(File.exist?(timeseries_csv))
      timeseries_csv = CSV.readlines(timeseries_csv)

      args_hash['timeseries_timestamp_convention'] = 'start'
      annual_csv, timeseries_csv2 = _test_measure(args_hash)
      assert(File.exist?(annual_csv))
      assert(File.exist?(timeseries_csv2))
      timeseries_csv2 = CSV.readlines(timeseries_csv2)

      for rownum in 2..timeseries_csv.size - 1
        timestamp_offset = _parse_time(timeseries_csv[rownum][0]) - _parse_time(timeseries_csv2[rownum][0])
        assert_equal(expected_values[rownum - 2], timestamp_offset)
      end
    end
  end

  def test_timeseries_for_dview
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'skip_validation' => true,
                  'output_format' => 'csv_dview',
                  'timeseries_frequency' => 'timestep',
                  'include_timeseries_fuel_consumptions' => true,
                  'include_timeseries_weather' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    timeseries_csv = CSV.readlines(timeseries_csv)
    assert_equal('wxDVFileHeaderVer.1', timeseries_csv[0][0].strip)

    args_hash['hpxml_path'] = File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-simcontrol-daylight-saving-disabled.xml')
    annual_csv, timeseries_csv2 = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv2))
    timeseries_csv2 = CSV.readlines(timeseries_csv2)
    assert_equal('wxDVFileHeaderVer.1', timeseries_csv2[0][0].strip)

    col_ix = timeseries_csv[1].find_index('Weather| Drybulb Temperature')
    assert_equal(Float(timeseries_csv[5][col_ix].strip), Float(timeseries_csv2[5][col_ix].strip)) # not in dst period, values line up
    assert_equal(Float(timeseries_csv[5000 + 1][col_ix].strip), Float(timeseries_csv2[5000][col_ix].strip)) # in dst period, values are shifted forward
  end

  def test_timeseries_energyplus_output_variables
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'skip_validation' => true,
                  'add_component_loads' => true,
                  'timeseries_frequency' => 'hourly',
                  'user_output_variables' => 'Zone People Occupant Count, Zone People Total Heating Energy, Foo, Surface Construction Index' }
    annual_csv, timeseries_csv, run_log = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsEnergyPlusOutputVariables
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsEnergyPlusOutputVariables)
    assert(File.readlines(run_log).any? { |line| line.include?("Request for output variable 'Foo'") })
  end

  def test_timeseries_energyplus_output_variables_freq_none
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'skip_validation' => true,
                  'add_component_loads' => true,
                  'timeseries_frequency' => 'none',
                  'user_output_variables' => 'Zone People Occupant Count, Zone People Total Heating Energy, Foo, Surface Construction Index' }
    annual_csv, timeseries_csv, run_log = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(!File.exist?(timeseries_csv))
    assert(!File.readlines(run_log).any? { |line| line.include?("Request for output variable 'Foo'") })
  end

  def test_timeseries_energyplus_output_meters
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml'),
                  'skip_validation' => true,
                  'add_component_loads' => true,
                  'timeseries_frequency' => 'hourly',
                  'user_output_meters' => 'MainsWater:Facility, Foo:Meter, HeatingCoils:EnergyTransfer' }
    annual_csv, timeseries_csv, run_log = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(File.exist?(timeseries_csv))
    expected_timeseries_cols = ['Time'] + BaseHPXMLTimeseriesColsEnergyPlusOutputMeters
    actual_timeseries_cols = File.readlines(timeseries_csv)[0].strip.split(',')
    assert_equal(expected_timeseries_cols.sort, actual_timeseries_cols.sort)
    timeseries_rows = CSV.read(timeseries_csv)
    assert_equal(8760, timeseries_rows.size - 2)
    timeseries_cols = timeseries_rows.transpose
    assert_equal(1, _check_for_constant_timeseries_step(timeseries_cols[0]))
    _check_for_nonzero_avg_timeseries_value(timeseries_csv, BaseHPXMLTimeseriesColsEnergyPlusOutputMeters)
    assert(File.readlines(run_log).any? { |line| line.include?("Request for output meter 'Foo:Meter'") })
  end

  def test_for_unsuccessful_simulation_infinity
    # Create HPXML w/ AFUE=0 to generate Infinity result
    hpxml_path = File.join(File.dirname(__FILE__), '../../workflow/sample_files/base.xml')
    hpxml = HPXML.new(hpxml_path: hpxml_path)
    hpxml.buildings[0].heating_systems[0].heating_efficiency_afue = 10.0**-315
    XMLHelper.write_file(hpxml.to_doc(), @tmp_hpxml_path)

    args_hash = { 'hpxml_path' => @tmp_hpxml_path,
                  'skip_validation' => true, }
    _annual_csv, timeseries_csv, run_log = _test_measure(args_hash, expect_success: false)
    assert(!File.exist?(timeseries_csv))
    assert(File.readlines(run_log).any? { |line| line.include?('Simulation used infinite energy; double-check inputs.') })
  end

  def test_geothermal_loop
    args_hash = { 'hpxml_path' => File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-hvac-ground-to-air-heat-pump-detailed-geothermal-loop.xml'),
                  'skip_validation' => true }
    annual_csv, timeseries_csv = _test_measure(args_hash)
    assert(File.exist?(annual_csv))
    assert(!File.exist?(timeseries_csv))
    actual_annual_rows = _get_annual_values(annual_csv)
    assert_equal(9.0, actual_annual_rows['HVAC Geothermal Loop: Borehole/Trench Count'])
    assert_equal(315.0, actual_annual_rows['HVAC Geothermal Loop: Borehole/Trench Length (ft)'])
  end

  private

  def _test_measure(args_hash, expect_success: true)
    # Run measure via OSW
    require 'json'
    template_osw = File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'template-run-hpxml.osw')
    workflow = OpenStudio::WorkflowJSON.new(template_osw)
    json = JSON.parse(workflow.to_s)

    # Update measure args
    steps = OpenStudio::WorkflowStepVector.new
    found_args = []
    json['steps'].each do |json_step|
      next unless ['HPXMLtoOpenStudio', 'ReportSimulationOutput'].include? json_step['measure_dir_name']

      step = OpenStudio::MeasureStep.new(json_step['measure_dir_name'])
      json_step['arguments'].each do |json_arg_name, json_arg_val|
        if args_hash.keys.include? json_arg_name
          # Override value
          found_args << json_arg_name
          json_arg_val = args_hash[json_arg_name]
        end
        step.setArgument(json_arg_name, json_arg_val)
      end
      steps.push(step)
    end
    workflow.setWorkflowSteps(steps)
    osw_path = File.join(File.dirname(template_osw), 'test.osw')
    workflow.saveAs(osw_path)
    if args_hash.size != found_args.size
      puts "ERROR: Did not find an argument (#{(args_hash.keys - found_args)[0]}) in #{File.basename(template_osw)}."
    end
    assert_equal(args_hash.size, found_args.size)

    # Run OSW
    success = system("#{OpenStudio.getOpenStudioCLI} run -w \"#{osw_path}\"")
    assert_equal(expect_success, success)

    # Cleanup
    File.delete(osw_path)

    if File.exist? File.join(File.dirname(template_osw), 'run', 'results_annual.json')
      annual_results = File.join(File.dirname(template_osw), 'run', 'results_annual.json')
    else
      annual_results = File.join(File.dirname(template_osw), 'run', 'results_annual.csv')
    end
    if File.exist? File.join(File.dirname(template_osw), 'run', 'results_timeseries.json')
      timeseries_results = File.join(File.dirname(template_osw), 'run', 'results_timeseries.json')
    else
      timeseries_results = File.join(File.dirname(template_osw), 'run', 'results_timeseries.csv')
    end
    run_log = File.join(File.dirname(template_osw), 'run', 'run.log')
    return annual_results, timeseries_results, run_log
  end

  def _parse_time(ts)
    date, time = ts.split('T')
    year, month, day = date.split('-')
    hour, minute, _second = time.split(':')
    return Time.utc(year, month, day, hour, minute)
  end

  def _check_for_constant_timeseries_step(time_col)
    steps = []
    time_col.each_with_index do |_ts, i|
      next if i < 3

      t0 = _parse_time(time_col[i - 1])
      t1 = _parse_time(time_col[i])

      steps << t1 - t0
    end
    return steps.uniq.size
  end

  def _get_timeseries_values(timeseries_csv, timeseries_cols)
    values = {}
    timeseries_cols.each do |col|
      values[col] = []
    end
    CSV.foreach(timeseries_csv, headers: true) do |row|
      next if row['Time'].nil?

      timeseries_cols.each do |col|
        fail "Unexpected column: #{col}." if row[col].nil?

        values[col] << Float(row[col])
      end
    end
    return values
  end

  def _check_for_nonzero_avg_timeseries_value(timeseries_csv, timeseries_cols)
    values = _get_timeseries_values(timeseries_csv, timeseries_cols)

    timeseries_cols.each do |col|
      avg_value = values[col].sum(0.0) / values[col].size
      assert_operator(avg_value, :!=, 0)
    end
  end

  def _check_for_zero_timeseries_values(timeseries_csv, timeseries_cols, start_ix, end_ix)
    values = _get_timeseries_values(timeseries_csv, timeseries_cols)

    timeseries_cols.each do |col|
      has_only_zero_timeseries_values = values[col][start_ix..end_ix].all? { |x| x == 0 }
      assert(has_only_zero_timeseries_values)
    end
  end

  def _check_for_nonzero_timeseries_values(timeseries_csv, timeseries_cols)
    values = _get_timeseries_values(timeseries_csv, timeseries_cols)

    timeseries_cols.each do |col|
      refute(values[col].include?(0.0))
    end
  end

  def _check_for_positive_timeseries_values(timeseries_csv, timeseries_cols)
    values = _get_timeseries_values(timeseries_csv, timeseries_cols)

    timeseries_cols.each do |col|
      assert_operator(values[col].min, :>=, 0)
    end
  end

  def _check_for_negative_timeseries_values(timeseries_csv, timeseries_cols)
    values = _get_timeseries_values(timeseries_csv, timeseries_cols)

    timeseries_cols.each do |col|
      assert_operator(values[col].max, :<=, 0)
    end
  end

  def _get_annual_values(annual_csv)
    actual_annual_rows = {}
    File.readlines(annual_csv).each do |line|
      next if line.strip.empty?

      key, value = line.split(',').map { |x| x.strip }
      actual_annual_rows[key] = Float(value)
    end
    return actual_annual_rows
  end

  def _check_runner_registered_values_and_measure_xml_outputs(actual_annual_rows)
    # Check for runner registered values
    results_json_path = File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'run', 'results.json')
    runner_annual_rows = JSON.parse(File.read(results_json_path))['ReportSimulationOutput']

    actual_annual_rows.each do |name, value|
      name = OpenStudio::toUnderscoreCase(name).chomp('_')

      assert_includes(runner_annual_rows.keys, name)
      assert_equal(value, runner_annual_rows[name])
    end

    # Check that all the "outputs" in the measure.xml, which are used by PAT,
    # are found in the results.json file.
    refute(@measure_xml_outputs.empty?)

    @measure_xml_outputs.each do |measure_xml_output|
      assert_includes(runner_annual_rows.keys, measure_xml_output)
    end
  end
end
