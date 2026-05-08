# frozen_string_literal: true

# Collection of constants used across the code.
module Constants
  # Strings/Numbers
  AirFilm = 'AirFilm'
  AutomaticallyAdded = 'AutomaticallyAdded'
  Small = 1e-9

  # Object types
  ObjectTypeAirSourceHeatPump = 'ashp'
  ObjectTypeBattery = 'battery'
  ObjectTypeBatteryLossesAdjustment = 'battery losses adjustment'
  ObjectTypeBlowerOffDelayFanPower = 'bod fan power'
  ObjectTypeBoiler = 'boiler'
  ObjectTypeCeilingFan = 'ceiling fan'
  ObjectTypeCentralAirConditioner = 'central ac'
  ObjectTypeCentralAirConditionerFurnace = 'central ac furnace'
  ObjectTypeClothesWasher = 'clothes washer'
  ObjectTypeClothesDryer = 'clothes dryer'
  ObjectTypeComponentLoadsProgram = 'component loads program'
  ObjectTypeCookingRange = 'cooking range'
  ObjectTypeDehumidifier = 'dehumidifier'
  ObjectTypeDishwasher = 'dishwasher'
  ObjectTypeDistributionWaste = 'dhw distribution waste'
  ObjectTypeDSECooling = 'dse cooling'
  ObjectTypeDSECoolingFanPump = 'dse fan pump cooling'
  ObjectTypeDSEHeating = 'dse heating'
  ObjectTypeDSEHeatingHeatPumpBackup = 'dse hp backup heating'
  ObjectTypeDSEHeatingFanPump = 'dse fan pump heating'
  ObjectTypeDSEHeatingHeatPumpBackupFanPump = 'dse hp backup fan pump heating'
  ObjectTypeDuctLoad = 'duct load'
  ObjectTypeElectricBaseboard = 'elec baseboard'
  ObjectTypeEvaporativeCooler = 'evap cooler'
  ObjectTypeFanPumpDisaggregateCool = 'disaggregate clg'
  ObjectTypeFanPumpDisaggregatePrimaryHeat = 'disaggregate htg primary'
  ObjectTypeFanPumpDisaggregateBackupHeat = 'disaggregate htg backup'
  ObjectTypeFixtures = 'dhw fixtures'
  ObjectTypeFreezer = 'freezer'
  ObjectTypeFurnace = 'furnace'
  ObjectTypeGeneralWaterUse = 'general water'
  ObjectTypeGeneralWaterUseLatent = 'general water latent'
  ObjectTypeGeneralWaterUseSensible = 'general water sensible'
  ObjectTypeGenerator = 'generator'
  ObjectTypeGroundSourceHeatPump = 'gshp'
  ObjectTypeHotWaterRecircPump = 'dhw recirc pump'
  ObjectTypeHPDefrostSupplHeat = 'ashp defrost suppl heat'
  ObjectTypeHPDefrostHeatLoad = 'ashp defrost heat load'
  ObjectTypeIdealAirSystem = 'ideal air system'
  ObjectTypeInfiltration = 'infil'
  ObjectTypeLightingExterior = 'ext lighting'
  ObjectTypeLightingExteriorHoliday = 'ext holiday lighting'
  ObjectTypeLightingGarage = 'grg lighting'
  ObjectTypeLightingInterior = 'int lighting'
  ObjectTypeMechVent = 'mech vent'
  ObjectTypeMechVentPrecool = 'mech vent precool'
  ObjectTypeMechVentPreheat = 'mech vent preheat'
  ObjectTypeMechVentHouseFan = 'mech vent house fan'
  ObjectTypeMechVentHouseFanCFIS = 'mech vent cfis'
  ObjectTypeMechVentHouseFanCFISSupplFan = 'mech vent cfis suppl'
  ObjectTypeMechVentBathFan = 'mech vent bath fan'
  ObjectTypeMechVentRangeFan = 'mech vent range fan'
  ObjectTypeMiniSplitAirConditioner = 'msac'
  ObjectTypeMiniSplitHeatPump = 'mshp'
  ObjectTypeMiscGrill = 'misc grill'
  ObjectTypeMiscLighting = 'misc lighting'
  ObjectTypeMiscFireplace = 'misc fireplace'
  ObjectTypeMiscPoolHeater = 'misc pool heater'
  ObjectTypeMiscPoolPump = 'misc pool pump'
  ObjectTypeMiscPermanentSpaHeater = 'misc spa heater'
  ObjectTypeMiscPermanentSpaPump = 'misc spa pump'
  ObjectTypeMiscPlugLoads = 'misc plug loads'
  ObjectTypeMiscTelevision = 'misc tv'
  ObjectTypeMiscElectricVehicleCharging = 'misc ev charging'
  ObjectTypeMiscWellPump = 'misc well pump'
  ObjectTypeNaturalVentilation = 'natural vent'
  ObjectTypeNeighbors = 'neighbors'
  ObjectTypeOccupants = 'occupants'
  ObjectTypeCrankcaseHeater = 'crankcase heater'
  ObjectTypePanHeater = 'pan heater'
  ObjectTypePhotovoltaics = 'pv'
  ObjectTypePTAC = 'ptac'
  ObjectTypePTHP = 'pthp'
  ObjectTypeRefrigerator = 'fridge'
  ObjectTypeRoomAC = 'room ac'
  ObjectTypeRoomHP = 'room hp'
  ObjectTypeSensorIndoorAirDBTemp = 'indoor air db temp sensor'
  ObjectTypeSensorIndoorAirHR = 'indoor air humidity ratio sensor'
  ObjectTypeSensorIndoorAirRH = 'indoor air rel humidity sensor'
  ObjectTypeSensorIndoorCoolingSetpointTemp = 'indoor cooling setpoint temp sensor'
  ObjectTypeSensorIndoorHeatingSetpointTemp = 'indoor heating setpoint temp sensor'
  ObjectTypeSensorScheduleBAHSPCoolingSeason = 'bahsp cooling season sensor'
  ObjectTypeSensorScheduleCoolingAvailability = 'cooling availability sensor'
  ObjectTypeSensorScheduleHeatingAvailability = 'heating availability sensor'
  ObjectTypeSensorScheduleVehicleDischarge = 'vehicle discharge schedule sensor'
  ObjectTypeSensorSiteGroundTemp = 'site ground temp sensor'
  ObjectTypeSensorSiteMainsWaterTemp = 'site mains water temp sensor'
  ObjectTypeSensorSiteOutdoorAirBarPressure = 'site outdoor air bar pressure sensor'
  ObjectTypeSensorSiteOutdoorAirDBTemp = 'site outdoor air db temp sensor'
  ObjectTypeSensorSiteOutdoorAirHR = 'site outdoor air humidity ratio sensor'
  ObjectTypeSensorSiteOutdoorAirRH = 'site outdoor air rel humidity sensor'
  ObjectTypeSensorSiteWindSpeed = 'site wind speed sensor'
  ObjectTypeSolarHotWater = 'solar hot water'
  ObjectTypeTotalAirflowsProgram = 'total airflows program'
  ObjectTypeTotalLoadsProgram = 'total loads program'
  ObjectTypeUnitHeater = 'unit heater'
  ObjectTypeUnmetHoursProgram = 'unmet hours program'
  ObjectTypeVehicle = 'vehicle'
  ObjectTypeVehicleUnmetHoursProgram = 'vehicle unmet hours program'
  ObjectTypeWaterHeater = 'water heater'
  ObjectTypeWaterHeaterSetpoint = 'water heater setpoint'
  ObjectTypeWaterHeaterAdjustment = 'water heater energy adjustment'
  ObjectTypeWaterLoopHeatPump = 'wlhp'
  ObjectTypeWholeHouseFan = 'whole house fan'

  # Arrays/Maps
  ERIVersions = ['2014', '2014A', '2014AE', '2014AEG', '2019', '2019A',
                 '2019AB', '2019ABC', '2019ABCD', '2022', '2022C', '2022CE',
                 'latest']
  IECCZones = ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C',
               '4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8']
  StateCodesMap = { 'AK' => 'Alaska',
                    'AL' => 'Alabama',
                    'AR' => 'Arkansas',
                    'AZ' => 'Arizona',
                    'CA' => 'California',
                    'CO' => 'Colorado',
                    'CT' => 'Connecticut',
                    'DC' => 'District of Columbia',
                    'DE' => 'Delaware',
                    'FL' => 'Florida',
                    'GA' => 'Georgia',
                    'HI' => 'Hawaii',
                    'IA' => 'Iowa',
                    'ID' => 'Idaho',
                    'IL' => 'Illinois',
                    'IN' => 'Indiana',
                    'KS' => 'Kansas',
                    'KY' => 'Kentucky',
                    'LA' => 'Louisiana',
                    'MA' => 'Massachusetts',
                    'MD' => 'Maryland',
                    'ME' => 'Maine',
                    'MI' => 'Michigan',
                    'MN' => 'Minnesota',
                    'MO' => 'Missouri',
                    'MS' => 'Mississippi',
                    'MT' => 'Montana',
                    'NC' => 'North Carolina',
                    'ND' => 'North Dakota',
                    'NE' => 'Nebraska',
                    'NH' => 'New Hampshire',
                    'NJ' => 'New Jersey',
                    'NM' => 'New Mexico',
                    'NV' => 'Nevada',
                    'NY' => 'New York',
                    'OH' => 'Ohio',
                    'OK' => 'Oklahoma',
                    'OR' => 'Oregon',
                    'PA' => 'Pennsylvania',
                    'RI' => 'Rhode Island',
                    'SC' => 'South Carolina',
                    'SD' => 'South Dakota',
                    'TN' => 'Tennessee',
                    'TX' => 'Texas',
                    'UT' => 'Utah',
                    'VA' => 'Virginia',
                    'VT' => 'Vermont',
                    'WA' => 'Washington',
                    'WI' => 'Wisconsin',
                    'WV' => 'West Virginia',
                    'WY' => 'Wyoming' }
end

# Total Energy (Constants for output reporting)
module TE
  Total = 'Total'
  Net = 'Net'
end

# Fuel Types (Constants for output reporting)
module FT
  Elec = 'Electricity'
  Gas = 'Natural Gas'
  Oil = 'Fuel Oil'
  Propane = 'Propane'
  WoodCord = 'Wood Cord'
  WoodPellets = 'Wood Pellets'
  Coal = 'Coal'
end

# End Use Types (Constants for output reporting)
module EUT
  Heating = 'Heating'
  HeatingFanPump = 'Heating Fans/Pumps'
  HeatingHeatPumpBackup = 'Heating Heat Pump Backup'
  HeatingHeatPumpBackupFanPump = 'Heating Heat Pump Backup Fans/Pumps'
  Cooling = 'Cooling'
  CoolingFanPump = 'Cooling Fans/Pumps'
  HotWater = 'Hot Water'
  HotWaterRecircPump = 'Hot Water Recirc Pump'
  HotWaterSolarThermalPump = 'Hot Water Solar Thermal Pump'
  LightsInterior = 'Lighting Interior'
  LightsGarage = 'Lighting Garage'
  LightsExterior = 'Lighting Exterior'
  MechVent = 'Mech Vent'
  MechVentPreheat = 'Mech Vent Preheating'
  MechVentPrecool = 'Mech Vent Precooling'
  WholeHouseFan = 'Whole House Fan'
  Refrigerator = 'Refrigerator'
  Freezer = 'Freezer'
  Dehumidifier = 'Dehumidifier'
  Dishwasher = 'Dishwasher'
  ClothesWasher = 'Clothes Washer'
  ClothesDryer = 'Clothes Dryer'
  RangeOven = 'Range/Oven'
  CeilingFan = 'Ceiling Fan'
  Television = 'Television'
  PlugLoads = 'Plug Loads'
  Vehicle = 'Electric Vehicle Charging'
  WellPump = 'Well Pump'
  PoolHeater = 'Pool Heater'
  PoolPump = 'Pool Pump'
  PermanentSpaHeater = 'Permanent Spa Heater'
  PermanentSpaPump = 'Permanent Spa Pump'
  Grill = 'Grill'
  Lighting = 'Lighting'
  Fireplace = 'Fireplace'
  PV = 'PV'
  Generator = 'Generator'
  Battery = 'Battery'
end

# Hot Water Types (Constants for output reporting)
module HWT
  ClothesWasher = 'Clothes Washer'
  Dishwasher = 'Dishwasher'
  Fixtures = 'Fixtures'
  DistributionWaste = 'Distribution Waste'
end

# Load Types (Constants for output reporting)
module LT
  Heating = 'Heating: Delivered'
  HeatingHeatPumpBackup = 'Heating: Heat Pump Backup' # Needed for ERI calculation for dual-fuel heat pumps
  Cooling = 'Cooling: Delivered'
  HotWaterDelivered = 'Hot Water: Delivered'
  HotWaterTankLosses = 'Hot Water: Tank Losses'
  HotWaterDesuperheater = 'Hot Water: Desuperheater'
  HotWaterSolarThermal = 'Hot Water: Solar Thermal'
end

# Component Load Types (Constants for output reporting)
module CLT
  Roofs = 'Roofs'
  Ceilings = 'Ceilings'
  Walls = 'Walls'
  RimJoists = 'Rim Joists'
  FoundationWalls = 'Foundation Walls'
  Doors = 'Doors'
  WindowsConduction = 'Windows Conduction'
  WindowsSolar = 'Windows Solar'
  SkylightsConduction = 'Skylights Conduction'
  SkylightsSolar = 'Skylights Solar'
  Floors = 'Floors'
  Slabs = 'Slabs'
  InternalMass = 'Internal Mass'
  Infiltration = 'Infiltration'
  NaturalVentilation = 'Natural Ventilation'
  MechanicalVentilation = 'Mechanical Ventilation'
  WholeHouseFan = 'Whole House Fan'
  Ducts = 'Ducts'
  InternalGains = 'Internal Gains'
  Lighting = 'Lighting'
end

# Unmet Hours Types (Constants for output reporting)
module UHT
  Heating = 'Heating'
  Cooling = 'Cooling'
  Driving = 'EV Driving'
end

# Resilience Types (Constants for output reporting)
module RT
  Battery = 'Battery'
end

# Peak Load Types (Constants for output reporting)
module PLT
  Heating = 'Heating: Delivered'
  Cooling = 'Cooling: Delivered'
end

# Peak Fuel Types (Constants for output reporting)
module PFT
  Summer = 'Summer'
  Winter = 'Winter'
  Annual = 'Annual'
end

# Airflow Types (Constants for output reporting)
module AFT
  Infiltration = 'Infiltration'
  MechanicalVentilation = 'Mechanical Ventilation'
  NaturalVentilation = 'Natural Ventilation'
  WholeHouseFan = 'Whole House Fan'
end

# Weather Types (Constants for output reporting)
module WT
  DrybulbTemp = 'Drybulb Temperature'
  WetbulbTemp = 'Wetbulb Temperature'
  RelativeHumidity = 'Relative Humidity'
  WindSpeed = 'Wind Speed'
  DiffuseSolar = 'Diffuse Solar Radiation'
  DirectSolar = 'Direct Solar Radiation'
end
