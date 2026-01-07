# frozen_string_literal: true

require 'ostruct'
require 'tempfile'

# Object that reflects the inputs/elements of a given HPXML file.
class HPXML < Object
  '''
  Example Usage:

  -----------------
  Reading from file
  -----------------

  hpxml = HPXML.new(hpxml_path: ...)

  # Singleton elements
  puts hpxml.building_construction.number_of_bedrooms

  # Array elements
  hpxml.walls.each do |wall|
    wall.windows.each do |window|
      puts window.area
    end
  end

  ---------------------
  Creating from scratch
  ---------------------

  hpxml = HPXML.new()

  # Singleton elements
  hpxml.building_construction.number_of_bedrooms = 3
  hpxml.building_construction.conditioned_floor_area = 2400

  # Array elements
  hpxml.walls.clear
  hpxml.walls.add(id: "WallNorth", area: 500)
  hpxml.walls.add(id: "WallSouth", area: 500)
  hpxml.walls.add
  hpxml.walls[-1].id = "WallEastWest"
  hpxml.walls[-1].area = 1000

  # Write file
  XMLHelper.write_file(hpxml.to_doc, "out.xml")

  '''

  HPXML_ATTRS = [:header, :buildings]
  attr_reader(*HPXML_ATTRS, :doc, :errors, :warnings, :hpxml_path)

  NameSpace = 'http://hpxmlonline.com/2025/12'

  # Constants
  AirTypeFanCoil = 'fan coil'
  AirTypeGravity = 'gravity'
  AirTypeHighVelocity = 'high velocity'
  AirTypeRegularVelocity = 'regular velocity'
  AtticTypeBelowApartment = 'BelowApartment'
  AtticTypeCathedral = 'CathedralCeiling'
  AtticTypeConditioned = 'ConditionedAttic'
  AtticTypeFlatRoof = 'FlatRoof'
  AtticTypeOther = 'Other'
  AtticTypeUnknown = 'UnknownAttic'
  AtticTypeUnvented = 'UnventedAttic'
  AtticTypeVented = 'VentedAttic'
  AtticWallTypeGable = 'gable'
  AtticWallTypeKneeWall = 'knee wall'
  BatteryTypeLithiumIon = 'Li-ion'
  BlindsClosed = 'closed'
  BlindsOpen = 'open'
  BlindsHalfOpen = 'half open'
  CapacityDescriptionMinimum = 'minimum'
  CapacityDescriptionNominal = 'nominal'
  CapacityDescriptionMaximum = 'maximum'
  ClothesDryerControlTypeMoisture = 'moisture'
  ClothesDryerControlTypeTimer = 'timer'
  CFISControlTypeOptimized = 'optimized'
  CFISControlTypeTimer = 'timer'
  CFISModeAirHandler = 'air handler fan'
  CFISModeNone = 'none'
  CFISModeSupplementalFan = 'supplemental fan'
  ColorDark = 'dark'
  ColorLight = 'light'
  ColorMedium = 'medium'
  ColorMediumDark = 'medium dark'
  ColorMediumLight = 'medium light'
  ColorReflective = 'reflective'
  DehumidifierTypePortable = 'portable'
  DehumidifierTypeWholeHome = 'whole-home'
  DryingMethodConventional = 'conventional'
  DryingMethodCondensing = 'condensing'
  DryingMethodHeatPump = 'heat pump'
  DryingMethodOther = 'other'
  DuctBuriedInsulationNone = 'not buried'
  DuctBuriedInsulationPartial = 'partially buried'
  DuctBuriedInsulationFull = 'fully buried'
  DuctBuriedInsulationDeep = 'deeply buried'
  DHWRecircControlTypeManual = 'manual demand control'
  DHWRecircControlTypeNone = 'no control'
  DHWRecircControlTypeSensor = 'presence sensor demand control'
  DHWRecircControlTypeTemperature = 'temperature'
  DHWRecircControlTypeTimer = 'timer'
  DHWDistTypeRecirc = 'Recirculation'
  DHWDistTypeStandard = 'Standard'
  DuctLeakageTotal = 'total'
  DuctLeakageToOutside = 'to outside'
  DuctShapeRectangular = 'rectangular'
  DuctShapeRound = 'round'
  DuctShapeOval = 'oval'
  DuctShapeOther = 'other'
  DuctTypeReturn = 'return'
  DuctTypeSupply = 'supply'
  DWHRFacilitiesConnectedAll = 'all'
  DWHRFacilitiesConnectedOne = 'one'
  ElectricPanelLoadCalculationType2023ExistingDwellingLoadBased = '2023 Existing Dwelling Load-Based'
  ElectricPanelLoadCalculationType2023ExistingDwellingMeterBased = '2023 Existing Dwelling Meter-Based'
  ElectricPanelLoadTypeHeating = 'heating'
  ElectricPanelLoadTypeCooling = 'cooling'
  ElectricPanelLoadTypeWaterHeater = 'hot water'
  ElectricPanelLoadTypeClothesDryer = 'clothes dryer'
  ElectricPanelLoadTypeDishwasher = 'dishwasher'
  ElectricPanelLoadTypeRangeOven = 'range/oven'
  ElectricPanelLoadTypeMechVent = 'mech vent'
  ElectricPanelLoadTypePermanentSpaHeater = 'permanent spa heater'
  ElectricPanelLoadTypePermanentSpaPump = 'permanent spa pump'
  ElectricPanelLoadTypePoolHeater = 'pool heater'
  ElectricPanelLoadTypePoolPump = 'pool pump'
  ElectricPanelLoadTypeWellPump = 'well pump'
  ElectricPanelLoadTypeElectricVehicleCharging = 'electric vehicle charging'
  ElectricPanelLoadTypeLighting = 'lighting'
  ElectricPanelLoadTypeKitchen = 'kitchen'
  ElectricPanelLoadTypeLaundry = 'laundry'
  ElectricPanelLoadTypeOther = 'other'
  ElectricPanelVoltage120 = '120'
  ElectricPanelVoltage240 = '240'
  ElectricResistanceDistributionRadiantCeiling = 'radiant ceiling'
  ElectricResistanceDistributionRadiantFloor = 'radiant floor'
  ElectricResistanceDistributionBaseboard = 'baseboard'
  ElectricVehicleChargingLocationHome = 'Home'
  ExteriorShadingTypeAwnings = 'awnings'
  ExteriorShadingTypeBuilding = 'building'
  ExteriorShadingTypeDeciduousTree = 'deciduous tree'
  ExteriorShadingTypeEvergreenTree = 'evergreen tree'
  ExteriorShadingTypeExternalOverhangs = 'external overhangs'
  ExteriorShadingTypeNotPresent = 'not present'
  ExteriorShadingTypeOther = 'other'
  ExteriorShadingTypeSolarFilm = 'solar film'
  ExteriorShadingTypeSolarScreens = 'solar screens'
  FoundationTypeAboveApartment = 'AboveApartment'
  FoundationTypeAmbient = 'Ambient'
  FoundationTypeBasementConditioned = 'ConditionedBasement'
  FoundationTypeBasementUnconditioned = 'UnconditionedBasement'
  FoundationTypeBasementUnknown = 'UnknownBasement'
  FoundationTypeCrawlspaceConditioned = 'ConditionedCrawlspace'
  FoundationTypeCrawlspaceUnvented = 'UnventedCrawlspace'
  FoundationTypeCrawlspaceUnknown = 'UnknownCrawlspace'
  FoundationTypeCrawlspaceVented = 'VentedCrawlspace'
  FoundationTypeBellyAndWing = 'BellyAndWing'
  FoundationTypeGarage = 'Garage'
  FoundationTypeOther = 'Other'
  FoundationTypeRubbleStone = 'RubbleStone'
  FoundationTypeSlab = 'SlabOnGrade'
  FoundationWallTypeConcreteBlock = 'concrete block'
  FoundationWallTypeConcreteBlockFoamCore = 'concrete block foam core'
  FoundationWallTypeConcreteBlockPerliteCore = 'concrete block perlite core'
  FoundationWallTypeConcreteBlockSolidCore = 'concrete block solid core'
  FoundationWallTypeConcreteBlockVermiculiteCore = 'concrete block vermiculite core'
  FoundationWallTypeDoubleBrick = 'double brick'
  FoundationWallTypeSolidConcrete = 'solid concrete'
  FoundationWallTypeWood = 'wood'
  FloorOrCeilingCeiling = 'ceiling'
  FloorOrCeilingFloor = 'floor'
  FloorTypeWoodFrame = 'WoodFrame'
  FloorTypeSIP = 'StructuralInsulatedPanel'
  FloorTypeSteelFrame = 'SteelFrame'
  FloorTypeConcrete = 'SolidConcrete'
  FuelLoadTypeFireplace = 'fireplace'
  FuelLoadTypeGrill = 'grill'
  FuelLoadTypeLighting = 'lighting'
  FuelLoadTypeOther = 'other'
  FuelTypeCoal = 'coal'
  FuelTypeCoalAnthracite = 'anthracite coal'
  FuelTypeCoalBituminous = 'bituminous coal'
  FuelTypeCoke = 'coke'
  FuelTypeDiesel = 'diesel'
  FuelTypeElectricity = 'electricity'
  FuelTypeKerosene = 'kerosene'
  FuelTypeNaturalGas = 'natural gas'
  FuelTypeOil = 'fuel oil'
  FuelTypeOil1 = 'fuel oil 1'
  FuelTypeOil2 = 'fuel oil 2'
  FuelTypeOil4 = 'fuel oil 4'
  FuelTypeOil5or6 = 'fuel oil 5/6'
  FuelTypePropane = 'propane'
  FuelTypeWoodCord = 'wood'
  FuelTypeWoodPellets = 'wood pellets'
  FurnitureMassTypeLightWeight = 'light-weight'
  FurnitureMassTypeHeavyWeight = 'heavy-weight'
  GeothermalLoopBorefieldConfigurationRectangle = 'Rectangle'
  GeothermalLoopBorefieldConfigurationZonedRectangle = 'Zoned Rectangle'
  GeothermalLoopBorefieldConfigurationOpenRectangle = 'Open Rectangle'
  GeothermalLoopBorefieldConfigurationC = 'C'
  GeothermalLoopBorefieldConfigurationL = 'L'
  GeothermalLoopBorefieldConfigurationU = 'U'
  GeothermalLoopBorefieldConfigurationLopsidedU = 'Lopsided U'
  GeothermalLoopLoopConfigurationDiagonal = 'diagonal'
  GeothermalLoopLoopConfigurationHorizontal = 'horizontal'
  GeothermalLoopLoopConfigurationOther = 'other'
  GeothermalLoopLoopConfigurationVertical = 'vertical'
  GeothermalLoopGroutOrPipeTypeStandard = 'standard'
  GeothermalLoopGroutOrPipeTypeThermallyEnhanced = 'thermally enhanced'
  GroundToAirHeatPumpModelTypeStandard = 'standard'
  GroundToAirHeatPumpModelTypeExperimental = 'experimental'
  HeaterTypeElectricResistance = 'electric resistance'
  HeaterTypeGas = 'gas fired'
  HeaterTypeHeatPump = 'heat pump'
  HeatPumpBackupTypeIntegrated = 'integrated'
  HeatPumpBackupTypeSeparate = 'separate'
  HeatPumpBackupSizingEmergency = 'emergency'
  HeatPumpBackupSizingSupplemental = 'supplemental'
  HeatPumpSizingACCA = 'ACCA'
  HeatPumpSizingHERS = 'HERS'
  HeatPumpSizingMaxLoad = 'MaxLoad'
  HVACCompressorTypeSingleStage = 'single stage'
  HVACCompressorTypeTwoStage = 'two stage'
  HVACCompressorTypeVariableSpeed = 'variable speed'
  HVACControlTypeManual = 'manual thermostat'
  HVACControlTypeProgrammable = 'programmable thermostat'
  HVACDistributionTypeAir = 'AirDistribution'
  HVACDistributionTypeDSE = 'DSE'
  HVACDistributionTypeHydronic = 'HydronicDistribution'
  HVACEquipmentTypeSplit = 'split system'
  HVACEquipmentTypePackaged = 'packaged system'
  HVACEquipmentTypeSDHV = 'small duct high velocity system'
  HVACEquipmentTypeSpaceConstrained = 'space constrained system'
  HVACTypeBoiler = 'Boiler'
  HVACTypeCentralAirConditioner = 'central air conditioner'
  HVACTypeChiller = 'chiller'
  HVACTypeCoolingTower = 'cooling tower'
  HVACTypeElectricResistance = 'ElectricResistance'
  HVACTypeEvaporativeCooler = 'evaporative cooler'
  HVACTypeFireplace = 'Fireplace'
  HVACTypeFloorFurnace = 'FloorFurnace'
  HVACTypeFurnace = 'Furnace'
  HVACTypeHeatPumpAirToAir = 'air-to-air'
  HVACTypeHeatPumpGroundToAir = 'ground-to-air'
  HVACTypeHeatPumpMiniSplit = 'mini-split'
  HVACTypeHeatPumpWaterLoopToAir = 'water-loop-to-air'
  HVACTypeHeatPumpPTHP = 'packaged terminal heat pump'
  HVACTypeHeatPumpRoom = 'room air conditioner with reverse cycle'
  HVACTypeMiniSplitAirConditioner = 'mini-split'
  HVACTypePTAC = 'packaged terminal air conditioner'
  HVACTypeRoomAirConditioner = 'room air conditioner'
  HVACTypeSpaceHeater = 'SpaceHeater'
  HVACTypeStove = 'Stove'
  HVACTypeWallFurnace = 'WallFurnace'
  HVACFanMotorTypePSC = 'PSC'
  HVACFanMotorTypeBPM = 'BPM'
  HVACPanHeaterControlTypeContinuous = 'continuous'
  HVACPanHeaterControlTypeDefrost = 'defrost mode'
  HydronicTypeBaseboard = 'baseboard'
  HydronicTypeRadiantCeiling = 'radiant ceiling'
  HydronicTypeRadiantFloor = 'radiant floor'
  HydronicTypeRadiator = 'radiator'
  HydronicTypeWaterLoop = 'water loop'
  InteriorFinishGypsumBoard = 'gypsum board'
  InteriorFinishGypsumCompositeBoard = 'gypsum composite board'
  InteriorFinishNotPresent = 'not present'
  InteriorFinishPlaster = 'plaster'
  InteriorFinishWood = 'wood'
  InteriorShadingTypeDarkBlinds = 'dark blinds'
  InteriorShadingTypeDarkCurtains = 'dark curtains'
  InteriorShadingTypeDarkShades = 'dark shades'
  InteriorShadingTypeLightBlinds = 'light blinds'
  InteriorShadingTypeLightCurtains = 'light curtains'
  InteriorShadingTypeLightShades = 'light shades'
  InteriorShadingTypeMediumBlinds = 'medium blinds'
  InteriorShadingTypeMediumCurtains = 'medium curtains'
  InteriorShadingTypeMediumShades = 'medium shades'
  InteriorShadingTypeOther = 'other'
  InteriorShadingTypeNotPresent = 'not present'
  InfiltrationTypeUnitTotal = 'unit total'
  InfiltrationTypeUnitExterior = 'unit exterior only'
  LeakinessVeryTight = 'very tight'
  LeakinessTight = 'tight'
  LeakinessAverage = 'average'
  LeakinessLeaky = 'leaky'
  LeakinessVeryLeaky = 'very leaky'
  LightingTypeCFL = 'CompactFluorescent'
  LightingTypeLED = 'LightEmittingDiode'
  LightingTypeLFL = 'FluorescentTube'
  LocationAttic = 'attic'
  LocationAtticUnconditioned = 'attic - unconditioned'
  LocationAtticUnvented = 'attic - unvented'
  LocationAtticVented = 'attic - vented'
  LocationBasement = 'basement'
  LocationBasementConditioned = 'basement - conditioned'
  LocationBasementUnconditioned = 'basement - unconditioned'
  LocationBath = 'bath'
  LocationConditionedSpace = 'conditioned space'
  LocationCrawlspace = 'crawlspace'
  LocationCrawlspaceConditioned = 'crawlspace - conditioned'
  LocationCrawlspaceUnvented = 'crawlspace - unvented'
  LocationCrawlspaceVented = 'crawlspace - vented'
  LocationExterior = 'exterior'
  LocationExteriorWall = 'exterior wall'
  LocationGarage = 'garage'
  LocationGround = 'ground'
  LocationInterior = 'interior'
  LocationKitchen = 'kitchen'
  LocationManufacturedHomeBelly = 'manufactured home belly'
  LocationManufacturedHomeUnderBelly = 'manufactured home underbelly'
  LocationOtherExterior = 'other exterior'
  LocationOtherHousingUnit = 'other housing unit'
  LocationOtherHeatedSpace = 'other heated space'
  LocationOtherMultifamilyBufferSpace = 'other multifamily buffer space'
  LocationOtherNonFreezingSpace = 'other non-freezing space'
  LocationOutside = 'outside'
  LocationRoof = 'roof'
  LocationRoofDeck = 'roof deck'
  LocationUnconditionedSpace = 'unconditioned space'
  LocationUnderSlab = 'under slab'
  ManualJDailyTempRangeLow = 'low'
  ManualJDailyTempRangeMedium = 'medium'
  ManualJDailyTempRangeHigh = 'high'
  ManualJInfiltrationMethodDefaultTable = 'default infiltration table'
  ManualJInfiltrationMethodBlowerDoor = 'blower door'
  ManualJDuctLeakageLevelDefaultNotSealed = 'default not sealed'
  ManualJDuctLeakageLevelPartiallySealed = 'partially sealed'
  ManualJDuctLeakageLevelDefaultSealed = 'default sealed'
  ManualJDuctLeakageLevelNotablySealed = 'notably sealed'
  ManualJDuctLeakageLevelExtremelySealed = 'extremely sealed'
  MechVentTypeBalanced = 'balanced'
  MechVentTypeCFIS = 'central fan integrated supply'
  MechVentTypeERV = 'energy recovery ventilator'
  MechVentTypeExhaust = 'exhaust only'
  MechVentTypeHRV = 'heat recovery ventilator'
  MechVentTypeSupply = 'supply only'
  OrientationEast = 'east'
  OrientationNorth = 'north'
  OrientationNortheast = 'northeast'
  OrientationNorthwest = 'northwest'
  OrientationSouth = 'south'
  OrientationSoutheast = 'southeast'
  OrientationSouthwest = 'southwest'
  OrientationWest = 'west'
  PlugLoadTypeAquarium = 'aquarium'
  PlugLoadTypeComputer = 'computer'
  PlugLoadTypeElectricVehicleCharging = 'electric vehicle charging'
  PlugLoadTypeOther = 'other'
  PlugLoadTypeSauna = 'sauna'
  PlugLoadTypeSpaceHeater = 'space heater'
  PlugLoadTypeTelevision = 'TV other'
  PlugLoadTypeTelevisionCRT = 'TV CRT'
  PlugLoadTypeTelevisionPlasma = 'TV plasma'
  PlugLoadTypeWaterBed = 'water bed'
  PlugLoadTypeWellPump = 'well pump'
  PVAnnualExcessSellbackRateTypeRetailElectricityCost = 'Retail Electricity Cost'
  PVAnnualExcessSellbackRateTypeUserSpecified = 'User-Specified'
  PVCompensationTypeFeedInTariff = 'FeedInTariff'
  PVCompensationTypeNetMetering = 'NetMetering'
  PVModuleTypePremium = 'premium'
  PVModuleTypeStandard = 'standard'
  PVModuleTypeThinFilm = 'thin film'
  PVTrackingTypeFixed = 'fixed'
  PVTrackingType1Axis = '1-axis'
  PVTrackingType1AxisBacktracked = '1-axis backtracked'
  PVTrackingType2Axis = '2-axis'
  RadiantBarrierLocationAtticRoofOnly = 'Attic roof only'
  RadiantBarrierLocationAtticRoofAndGableWalls = 'Attic roof and gable walls'
  RadiantBarrierLocationAtticFloor = 'Attic floor'
  ResidentialTypeApartment = 'apartment unit'
  ResidentialTypeManufactured = 'manufactured home'
  ResidentialTypeSFA = 'single-family attached'
  ResidentialTypeSFD = 'single-family detached'
  RoofTypeAsphaltShingles = 'asphalt or fiberglass shingles'
  RoofTypeConcrete = 'concrete'
  RoofTypeCool = 'cool roof'
  RoofTypeClayTile = 'slate or tile shingles'
  RoofTypeEPS = 'expanded polystyrene sheathing'
  RoofTypeMetal = 'metal surfacing'
  RoofTypePlasticRubber = 'plastic/rubber/synthetic sheeting'
  RoofTypeShingles = 'shingles'
  RoofTypeWoodShingles = 'wood shingles or shakes'
  ScheduleRegular = 'regular schedule'
  ScheduleAvailable = 'always available'
  ScheduleUnavailable = 'always unavailable'
  ShieldingExposed = 'exposed'
  ShieldingNormal = 'normal'
  ShieldingWellShielded = 'well-shielded'
  SidingTypeAluminum = 'aluminum siding'
  SidingTypeAsbestos = 'asbestos siding'
  SidingTypeBrick = 'brick veneer'
  SidingTypeCompositeShingle = 'composite shingle siding'
  SidingTypeFiberCement = 'fiber cement siding'
  SidingTypeMasonite = 'masonite siding'
  SidingTypeNotPresent = 'not present'
  SidingTypeStone = 'stone veneer'
  SidingTypeStucco = 'stucco'
  SidingTypeSyntheticStucco = 'synthetic stucco'
  SidingTypeVinyl = 'vinyl siding'
  SidingTypeWood = 'wood siding'
  SiteSoilMoistureTypeDry = 'dry'
  SiteSoilMoistureTypeMixed = 'mixed'
  SiteSoilMoistureTypeWet = 'wet'
  SiteSoilTypeClay = 'clay'
  SiteSoilTypeGravel = 'gravel'
  SiteSoilTypeLoam = 'loam'
  SiteSoilTypeOther = 'other'
  SiteSoilTypeSand = 'sand'
  SiteSoilTypeSilt = 'silt'
  SiteSoilTypeUnknown = 'unknown'
  SiteTypeUrban = 'urban'
  SiteTypeSuburban = 'suburban'
  SiteTypeRural = 'rural'
  SolarThermalCollectorTypeDoubleGlazing = 'double glazing black'
  SolarThermalCollectorTypeEvacuatedTube = 'evacuated tube'
  SolarThermalCollectorTypeICS = 'integrated collector storage'
  SolarThermalCollectorTypeSingleGlazing = 'single glazing black'
  SolarThermalLoopTypeDirect = 'liquid direct'
  SolarThermalLoopTypeIndirect = 'liquid indirect'
  SolarThermalLoopTypeThermosyphon = 'passive thermosyphon'
  SolarThermalSystemTypeHotWater = 'hot water'
  SpaceFenestrationLoadProcedureStandard = 'standard'
  SpaceFenestrationLoadProcedurePeak = 'peak'
  SurroundingsOneSide = 'attached on one side'
  SurroundingsTwoSides = 'attached on two sides'
  SurroundingsThreeSides = 'attached on three sides'
  SurroundingsStandAlone = 'stand-alone'
  TypeNotPresent = 'not present'
  TypeUnknown = 'unknown'
  UnitsACH = 'ACH'
  UnitsACHNatural = 'ACHnatural'
  UnitsAFUE = 'AFUE'
  UnitsAh = 'Ah'
  UnitsBtuPerHour = 'Btu/hr'
  UnitsCFM = 'CFM'
  UnitsCFM25 = 'CFM25'
  UnitsCFM50 = 'CFM50'
  UnitsCFMNatural = 'CFMnatural'
  UnitsCOP = 'COP'
  UnitsDegFPerHour = 'F/hr'
  UnitsDollars = '$'
  UnitsDollarsPerkW = '$/kW'
  UnitsEER = 'EER'
  UnitsEER2 = 'EER2'
  UnitsCEER = 'CEER'
  UnitsHSPF = 'HSPF'
  UnitsHSPF2 = 'HSPF2'
  UnitsKwh = 'kWh'
  UnitsKwhPerYear = 'kWh/year'
  UnitsKwhPerDay = 'kWh/day'
  UnitsKwhPerMile = 'kWh/mile'
  UnitsKwPerTon = 'kW/ton'
  UnitsMiles = 'miles'
  UnitsMilePerKwh = 'mile/kWh'
  UnitsMPG = 'mpg'
  UnitsMPGe = 'mpge'
  UnitsPercent = 'Percent'
  UnitsPercentPerHour = '%/hr'
  UnitsSEER = 'SEER'
  UnitsSEER2 = 'SEER2'
  UnitsSLA = 'SLA'
  UnitsThermPerYear = 'therm/year'
  VehicleTypeBEV = 'BatteryElectricVehicle'
  VehicleTypePHEV = 'PlugInHybridElectricVehicle'
  VehicleTypeHybrid = 'HybridElectricVehicle'
  VehicleTypeICE = 'InternalCombustionEngine'
  VehicleTypeFCEV = 'FuelCellElectricVehicle'
  VerticalSurroundingsNoAboveOrBelow = 'no units above or below'
  VerticalSurroundingsAboveAndBelow = 'unit above and below'
  VerticalSurroundingsBelow = 'unit below'
  VerticalSurroundingsAbove = 'unit above'
  WallTypeAdobe = 'Adobe'
  WallTypeBrick = 'StructuralBrick'
  WallTypeCMU = 'ConcreteMasonryUnit'
  WallTypeConcrete = 'SolidConcrete'
  WallTypeDoubleWoodStud = 'DoubleWoodStud'
  WallTypeICF = 'InsulatedConcreteForms'
  WallTypeLog = 'LogWall'
  WallTypeSIP = 'StructuralInsulatedPanel'
  WallTypeSteelStud = 'SteelFrame'
  WallTypeStone = 'Stone'
  WallTypeStrawBale = 'StrawBale'
  WallTypeWoodStud = 'WoodStud'
  WaterFixtureTypeFaucet = 'faucet'
  WaterFixtureTypeShowerhead = 'shower head'
  WaterHeaterHPWHOperatingModeHybridAuto = 'hybrid/auto'
  WaterHeaterHPWHOperatingModeHeatPumpOnly = 'heat pump only'
  WaterHeaterTankModelTypeMixed = 'mixed'
  WaterHeaterTankModelTypeStratified = 'stratified'
  WaterHeaterTypeCombiStorage = 'space-heating boiler with storage tank'
  WaterHeaterTypeCombiTankless = 'space-heating boiler with tankless coil'
  WaterHeaterTypeHeatPump = 'heat pump water heater'
  WaterHeaterTypeTankless = 'instantaneous water heater'
  WaterHeaterTypeStorage = 'storage water heater'
  WaterHeaterUsageBinVerySmall = 'very small'
  WaterHeaterUsageBinLow = 'low'
  WaterHeaterUsageBinMedium = 'medium'
  WaterHeaterUsageBinHigh = 'high'
  WindowFrameTypeAluminum = 'Aluminum'
  WindowFrameTypeComposite = 'Composite'
  WindowFrameTypeFiberglass = 'Fiberglass'
  WindowFrameTypeMetal = 'Metal'
  WindowFrameTypeVinyl = 'Vinyl'
  WindowFrameTypeWood = 'Wood'
  WindowGasAir = 'air'
  WindowGasArgon = 'argon'
  WindowGasKrypton = 'krypton'
  WindowGasNitrogen = 'nitrogen'
  WindowGasOther = 'other'
  WindowGasXenon = 'xenon'
  WindowGlassTypeClear = 'clear'
  WindowGlassTypeLowE = 'low-e'
  WindowGlassTypeLowEHighSolarGain = 'low-e, high-solar-gain'
  WindowGlassTypeLowELowSolarGain = 'low-e, low-solar-gain'
  WindowGlassTypeReflective = 'reflective'
  WindowGlassTypeTinted = 'tinted'
  WindowGlassTypeTintedReflective = 'tinted/reflective'
  WindowLayersDoublePane = 'double-pane'
  WindowLayersGlassBlock = 'glass block'
  WindowLayersSinglePane = 'single-pane'
  WindowLayersTriplePane = 'triple-pane'
  WindowClassArchitectural = 'architectural'
  WindowClassCommercial = 'commercial'
  WindowClassHeavyCommercial = 'heavy commercial'
  WindowClassResidential = 'residential'
  WindowClassLightCommercial = 'light commercial'
  ZoneTypeConditioned = 'conditioned'
  ZoneTypeUnconditioned = 'unconditioned'

  # Heating/cooling design load attributes
  HDL_ATTRS = { hdl_total: 'Total',
                hdl_ducts: 'Ducts',
                hdl_windows: 'Windows',
                hdl_skylights: 'Skylights',
                hdl_doors: 'Doors',
                hdl_walls: 'Walls',
                hdl_roofs: 'Roofs',
                hdl_floors: 'Floors',
                hdl_slabs: 'Slabs',
                hdl_ceilings: 'Ceilings',
                hdl_infil: 'Infiltration',
                hdl_vent: 'Ventilation',
                hdl_piping: 'Piping' }
  CDL_SENS_ATTRS = { cdl_sens_total: 'Total',
                     cdl_sens_ducts: 'Ducts',
                     cdl_sens_windows: 'Windows',
                     cdl_sens_skylights: 'Skylights',
                     cdl_sens_doors: 'Doors',
                     cdl_sens_walls: 'Walls',
                     cdl_sens_roofs: 'Roofs',
                     cdl_sens_floors: 'Floors',
                     cdl_sens_slabs: 'Slabs',
                     cdl_sens_ceilings: 'Ceilings',
                     cdl_sens_infil: 'Infiltration',
                     cdl_sens_vent: 'Ventilation',
                     cdl_sens_intgains: 'InternalLoads',
                     cdl_sens_blowerheat: 'BlowerHeat',
                     cdl_sens_aedexcursion: 'AEDExcursion',
                     cdl_sens_aed_curve: 'AEDCurve' }
  CDL_LAT_ATTRS = { cdl_lat_total: 'Total',
                    cdl_lat_ducts: 'Ducts',
                    cdl_lat_infil: 'Infiltration',
                    cdl_lat_vent: 'Ventilation',
                    cdl_lat_intgains: 'InternalLoads' }

  # Electric panel attributes
  CLB_ATTRS = { clb_type: 'Type',
                clb_total_w: 'TotalWatts',
                clb_total_a: 'TotalAmps',
                clb_headroom_a: 'HeadroomAmps' }
  BS_ATTRS = { bs_total: 'Total',
               bs_occupied: 'Occupied',
               bs_headroom: 'Headroom' }

  attr_accessor(:contents)

  def initialize(hpxml_path: nil, schema_validator: nil, schematron_validator: nil, building_id: nil)
    @hpxml_path = hpxml_path
    @errors = []
    @warnings = []
    building_id = nil if building_id.to_s.empty?

    hpxml_element = nil
    if not hpxml_path.nil?
      @contents = File.read(hpxml_path)
      doc = XMLHelper.parse_file(hpxml_path, hpxml_contents: @contents)

      # Validate against XSD schema
      if not schema_validator.nil?
        xsd_errors, xsd_warnings = XMLValidator.validate_against_schema(hpxml_path, schema_validator)
        @errors += xsd_errors
        @warnings += xsd_warnings
        return unless @errors.empty?
      end

      # Check HPXML version
      hpxml_element = XMLHelper.get_element(doc, '/HPXML')
      Version.check_hpxml_version(XMLHelper.get_attribute_value(hpxml_element, 'schemaVersion'))

      # Get value of WholeSFAorMFBuildingSimulation element
      whole_sfa_or_mf_building_sim = XMLHelper.get_value(hpxml_element, 'SoftwareInfo/extension/WholeSFAorMFBuildingSimulation', :boolean)
      whole_sfa_or_mf_building_sim = false if whole_sfa_or_mf_building_sim.nil?
      has_mult_building_elements = XMLHelper.get_elements(hpxml_element, 'Building').size > 1
      if has_mult_building_elements
        if building_id.nil? && !whole_sfa_or_mf_building_sim
          @errors << 'Multiple Building elements defined in HPXML file; provide Building ID argument or set WholeSFAorMFBuildingSimulation=true.'
          return unless @errors.empty?
        elsif whole_sfa_or_mf_building_sim && (not building_id.nil?)
          @warnings << 'Multiple Building elements defined in HPXML file and WholeSFAorMFBuildingSimulation=true; Building ID argument will be ignored.'
          building_id = nil
        end
      end

      # Handle multiple buildings
      # Do this before schematron validation so that:
      # 1. We don't give schematron warnings for Building elements that are not of interest.
      # 2. The schematron validation occurs faster (as we're only validating one Building).
      if has_mult_building_elements && (not building_id.nil?)
        # Discard all Building elements except the one of interest
        XMLHelper.get_elements(hpxml_element, 'Building').reverse_each do |building|
          next if XMLHelper.get_attribute_value(XMLHelper.get_element(building, 'BuildingID'), 'id') == building_id

          building.remove
        end
        if XMLHelper.get_elements(hpxml_element, 'Building').size == 0
          @errors << "Could not find Building element with ID '#{building_id}'."
          return unless @errors.empty?
        end

        # Write new HPXML file with all other Building elements removed
        hpxml_path = Tempfile.new(['hpxml', '.xml']).path.to_s
        XMLHelper.write_file(hpxml_element, hpxml_path)
      end

      # Validate against Schematron
      if not schematron_validator.nil?
        sct_errors, sct_warnings = XMLValidator.validate_against_schematron(hpxml_path, schematron_validator, hpxml_element)
        @errors += sct_errors
        @warnings += sct_warnings
        return unless @errors.empty?
      end
    end

    # Create/populate child objects
    from_doc(hpxml_element)

    # Check for additional errors (those hard to check via Schematron)
    @errors += header.check_for_errors
    @buildings.each do |_building|
      @errors += buildings.check_for_errors()
    end
    @errors.map! { |e| "#{hpxml_path}: #{e}" }
    return unless @errors.empty?
  end

  # Returns the HPXML object converted to an Oga XML Document.
  #
  # @return [Oga::XML::Document] HPXML object as an XML document
  def to_doc
    hpxml_doc = _create_hpxml_document()
    @header.to_doc(hpxml_doc)
    @buildings.to_doc(hpxml_doc)
    return hpxml_doc
  end

  # Populates the HPXML object(s) from the XML document.
  #
  # @param hpxml_element [Oga::XML::Element] Root XML element of the HPXML document
  # @return [nil]
  def from_doc(hpxml_element)
    @header = Header.new(self, hpxml_element)
    @buildings = Buildings.new(self, hpxml_element)
  end

  # Make all IDs unique so the HPXML is valid.
  #
  # @param hpxml_doc [Oga::XML::Document] HPXML object as an XML document
  # @param last_building_only [Boolean] Whether to update IDs for all Building elements or only the last Building element
  # @return [nil]
  def set_unique_hpxml_ids(hpxml_doc, last_building_only = false)
    buildings = XMLHelper.get_elements(hpxml_doc, '/HPXML/Building')

    buildings.each_with_index do |building, i|
      next if last_building_only && (i != buildings.size - 1)

      bldg_no = "_#{i + 1}"
      building.each_node do |node|
        next unless node.is_a?(Oga::XML::Element)

        if not XMLHelper.get_attribute_value(node, 'id').nil?
          XMLHelper.add_attribute(node, 'id', "#{XMLHelper.get_attribute_value(node, 'id')}#{bldg_no}")
        elsif not XMLHelper.get_attribute_value(node, 'idref').nil?
          XMLHelper.add_attribute(node, 'idref', "#{XMLHelper.get_attribute_value(node, 'idref')}#{bldg_no}")
        end
      end
    end
  end

  # Returns a hash with whether each fuel exists in the HPXML Building or Buildings
  #
  # @param building_id [String] If provided, only search the single HPXML Building with the given ID
  # @return [Hash] Map of HPXML::FuelTypeXXX => boolean
  def has_fuels(building_id = nil)
    has_fuel = {}
    has_fuel[HPXML::FuelTypeElectricity] = true

    HPXML::fossil_fuels.each do |fuel|
      has_fuel[fuel] = false

      buildings.each do |hpxml_bldg|
        next if (not building_id.nil?) && (hpxml_bldg.building_id != building_id)

        # Check HVAC systems
        hpxml_bldg.hvac_systems.each do |hvac_system|
          if hvac_system.respond_to?(:heating_system_fuel) && hvac_system.heating_system_fuel == fuel
            has_fuel[fuel] = true
          end
          if hvac_system.respond_to?(:cooling_system_fuel) && hvac_system.cooling_system_fuel == fuel
            has_fuel[fuel] = true
          end
          if hvac_system.respond_to?(:heat_pump_fuel) && hvac_system.heat_pump_fuel == fuel
            has_fuel[fuel] = true
          end
          if hvac_system.respond_to?(:backup_heating_fuel) && hvac_system.backup_heating_fuel == fuel
            has_fuel[fuel] = true
          end
          if hvac_system.respond_to?(:integrated_heating_system_fuel) && hvac_system.integrated_heating_system_fuel == fuel
            has_fuel[fuel] = true
          end
        end

        # Check other appliances
        (hpxml_bldg.water_heating_systems +
         hpxml_bldg.generators +
         hpxml_bldg.clothes_dryers +
         hpxml_bldg.cooking_ranges +
         hpxml_bldg.fuel_loads).each do |appliance|
          if appliance.fuel_type == fuel
            has_fuel[fuel] = true
          end
        end

        # Check pool/spa heaters
        if fuel == HPXML::FuelTypeNaturalGas
          (hpxml_bldg.pools + hpxml_bldg.permanent_spas).each do |pool_or_spa|
            if pool_or_spa.heater_type == HPXML::HeaterTypeGas
              has_fuel[fuel] = true
            end
          end
        end

        break if has_fuel[fuel]
      end
    end

    return has_fuel
  end

  # Object to store additional properties on an HPXML object that are not intended
  # to end up in the HPXML file. For example, you can store the OpenStudio::Model::Space
  # object for an appliance.
  class AdditionalProperties < OpenStruct
    # Throw an error if no value has been set for a given additional property
    # rather than just returning nil.
    def method_missing(method_name, *args, **kwargs)
      raise NoMethodError, "undefined method '#{method_name}' for #{self}" unless method_name.to_s.end_with?('=')

      super
    end
  end

  # HPXML Standard Element (e.g., used for Roof)
  class BaseElement
    attr_accessor(:parent_object, :additional_properties)

    def initialize(parent_object, hpxml_element = nil, **kwargs)
      @parent_object = parent_object
      @additional_properties = AdditionalProperties.new

      # Automatically add :foo_isdefaulted attributes to class
      self.class::ATTRS.each do |attribute|
        next if attribute.to_s.end_with? '_isdefaulted'

        attr = "#{attribute}_isdefaulted".to_sym
        next if self.class::ATTRS.include? attr

        # Add attribute to ATTRS and class
        self.class::ATTRS << attr
        create_attr(attr.to_s) # From https://stackoverflow.com/a/4082937
      end

      if not hpxml_element.nil?
        # Set values from HPXML element
        from_doc(hpxml_element)
      else
        # Set values from **kwargs
        kwargs.each do |k, v|
          send(k.to_s + '=', v)
        end
      end
    end

    # Used to create _isdefaulted attributes on the fly that correspond to every defined attribute.
    def create_method(name, &block)
      self.class.send(:define_method, name, &block)
    end

    # Used to create _isdefaulted attributes on the fly that correspond to every defined attribute.
    def create_attr(name)
      create_method("#{name}=".to_sym) { |val| instance_variable_set('@' + name, val) }
      create_method(name.to_sym) { instance_variable_get('@' + name) }
    end

    # Creates a hash out of the object properties.
    #
    # @return [Hash] Map of attribute name => value
    def to_h
      h = {}
      self.class::ATTRS.each do |attribute|
        h[attribute] = send(attribute)
      end
      return h
    end

    # Returns how the object is formatted when using .to_s.
    def to_s
      return to_h.to_s
    end

    # Returns whether all attributes are nil
    #
    # @return [Boolean] True if all attributes are nil
    def nil?
      to_h.each do |k, v|
        next if k.to_s.end_with? '_isdefaulted'
        return false if not v.nil?
      end
      return true
    end
  end

  # HPXML Array Element (e.g., used for Roofs)
  class BaseArrayElement < Array
    attr_accessor(:parent_object, :additional_properties)

    def initialize(parent_object, hpxml_element = nil)
      @parent_object = parent_object
      @additional_properties = AdditionalProperties.new

      if not hpxml_element.nil?
        # Set values from HPXML element
        from_doc(hpxml_element)
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages across all objects in the array
    def check_for_errors
      errors = []
      each do |child|
        if not child.respond_to? :check_for_errors
          fail "Need to add 'check_for_errors' method to #{child.class} class."
        end

        errors += child.check_for_errors
      end
      return errors
    end

    # Adds each object in the array to the provided Oga XML element.
    #
    # @param xml_element [Oga::XML::Element] XML element
    # @return [nil]
    def to_doc(xml_element)
      each do |child|
        child.to_doc(xml_element)
      end
    end

    # Returns how the object is formatted when using .to_s.
    def to_s
      return map { |x| x.to_s }
    end
  end

  # Object for high-level HPXML header information.
  # Applies to all Buildings (i.e., outside the Building elements).
  class Header < BaseElement
    def initialize(hpxml_element, *args, **kwargs)
      @emissions_scenarios = EmissionsScenarios.new(hpxml_element)
      @utility_bill_scenarios = UtilityBillScenarios.new(hpxml_element)
      @unavailable_periods = UnavailablePeriods.new(hpxml_element)
      super(hpxml_element, *args, **kwargs)
    end
    CLASS_ATTRS = [:emissions_scenarios,    # [HPXML::EmissionSenarios]
                   :utility_bill_scenarios, # [HPXML::UtilityBillScenarios]
                   :unavailable_periods]    # [HPXML::UnavailablePeriods]
    ATTRS = [:xml_type,                                    # [String] XMLTransactionHeaderInformation/XMLType
             :xml_generated_by,                            # [String] XMLTransactionHeaderInformation/XMLGeneratedBy
             :created_date_and_time,                       # [String] XMLTransactionHeaderInformation/CreatedDateAndTime
             :transaction,                                 # [String] XMLTransactionHeaderInformation/Transaction
             :software_program_used,                       # [String] SoftwareInfo/SoftwareProgramUsed
             :software_program_version,                    # [String] SoftwareInfo/SoftwareProgramVersion
             :apply_ashrae140_assumptions,                 # [Boolean] SoftwareInfo/extension/ApplyASHRAE140Assumptions
             :whole_sfa_or_mf_building_sim,                # [Boolean] SoftwareInfo/extension/WholeSFAorMFBuildingSimulation
             :eri_calculation_versions,                    # [Array<String>] SoftwareInfo/extension/ERICalculation/Version
             :co2index_calculation_versions,               # [Array<String>] SoftwareInfo/extension/CO2IndexCalculation/Version
             :energystar_calculation_versions,             # [Array<String>] SoftwareInfo/extension/EnergyStarCalculation/Version
             :iecc_eri_calculation_versions,               # [Array<String>] SoftwareInfo/extension/IECCERICalculation/Version
             :denh_calculation_versions,                   # [Array<String>] SoftwareInfo/extension/DENHCalculation/Version
             :timestep,                                    # [Integer] SoftwareInfo/extension/SimulationControl/Timestep (minutes)
             :sim_begin_month,                             # [Integer] SoftwareInfo/extension/SimulationControl/BeginMonth
             :sim_begin_day,                               # [Integer] SoftwareInfo/extension/SimulationControl/BeginDayOfMonth
             :sim_end_month,                               # [Integer] SoftwareInfo/extension/SimulationControl/EndMonth
             :sim_end_day,                                 # [Integer] SoftwareInfo/extension/SimulationControl/EndDayOfMonth
             :sim_calendar_year,                           # [Integer] SoftwareInfo/extension/SimulationControl/CalendarYear
             :temperature_capacitance_multiplier,          # [Double] SoftwareInfo/extension/SimulationControl/AdvancedResearchFeatures/TemperatureCapacitanceMultiplier
             :ground_to_air_heat_pump_model_type,          # [String] SoftwareInfo/extension/SimulationControl/AdvancedResearchFeatures/GroundToAirHeatPumpModelType (HPXML::GroundToAirHeatPumpModelTypeXXX)
             :hvac_onoff_thermostat_deadband,              # [Double] SoftwareInfo/extension/SimulationControl/AdvancedResearchFeatures/OnOffThermostatDeadbandTemperature (F)
             :heat_pump_backup_heating_capacity_increment, # [Double] SoftwareInfo/extension/SimulationControl/AdvancedResearchFeatures/HeatPumpBackupCapacityIncrement (Btu/hr)
             :service_feeders_load_calculation_types]      # [Array<String>] SoftwareInfo/extension/ElectricPanelLoadCalculations/ServiceFeeders/Type
    attr_reader(*CLASS_ATTRS)
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      errors += HPXML::check_dates('Run Period', @sim_begin_month, @sim_begin_day, @sim_end_month, @sim_end_day)
      if (not @sim_begin_month.nil?) && (not @sim_end_month.nil?)
        if @sim_begin_month > @sim_end_month
          errors << "Run Period Begin Month (#{@sim_begin_month}) cannot come after Run Period End Month (#{@sim_end_month})."
        end
        if (not @sim_begin_day.nil?) && (not @sim_end_day.nil?)
          if @sim_begin_month == @sim_end_month && @sim_begin_day > @sim_end_day
            errors << "Run Period Begin Day of Month (#{@sim_begin_day}) cannot come after Run Period End Day of Month (#{@sim_end_day}) for the same month (#{begin_month})."
          end
        end
      end
      errors += @emissions_scenarios.check_for_errors
      errors += @utility_bill_scenarios.check_for_errors
      errors += @unavailable_periods.check_for_errors
      return errors
    end

    # Adds this object to the Oga XML document.
    #
    # @param hpxml_doc [Oga::XML::Document] HPXML object as an XML document
    # @return [nil]
    def to_doc(hpxml_doc)
      return if nil?

      hpxml = XMLHelper.get_element(hpxml_doc, '/HPXML')
      header = XMLHelper.add_element(hpxml, 'XMLTransactionHeaderInformation')
      XMLHelper.add_element(header, 'XMLType', @xml_type, :string)
      XMLHelper.add_element(header, 'XMLGeneratedBy', @xml_generated_by, :string)
      if not @created_date_and_time.nil?
        XMLHelper.add_element(header, 'CreatedDateAndTime', @created_date_and_time, :string)
      else
        XMLHelper.add_element(header, 'CreatedDateAndTime', Time.now.strftime('%Y-%m-%dT%H:%M:%S%:z'), :string)
      end
      XMLHelper.add_element(header, 'Transaction', @transaction, :string)

      software_info = XMLHelper.add_element(hpxml, 'SoftwareInfo')
      XMLHelper.add_element(software_info, 'SoftwareProgramUsed', @software_program_used, :string) unless @software_program_used.nil?
      XMLHelper.add_element(software_info, 'SoftwareProgramVersion', @software_program_version, :string) unless @software_program_version.nil?
      XMLHelper.add_extension(software_info, 'ApplyASHRAE140Assumptions', @apply_ashrae140_assumptions, :boolean) unless @apply_ashrae140_assumptions.nil?
      XMLHelper.add_extension(software_info, 'WholeSFAorMFBuildingSimulation', @whole_sfa_or_mf_building_sim, :boolean) unless @whole_sfa_or_mf_building_sim.nil?
      { 'ERICalculation' => @eri_calculation_versions,
        'CO2IndexCalculation' => @co2index_calculation_versions,
        'EnergyStarCalculation' => @energystar_calculation_versions,
        'IECCERICalculation' => @iecc_eri_calculation_versions,
        'DENHCalculation' => @denh_calculation_versions }.each do |element_name, calculation_versions|
        calculation_versions = [] if calculation_versions.nil?
        if not calculation_versions.empty?
          extension = XMLHelper.create_elements_as_needed(software_info, ['extension'])
          calculation = XMLHelper.add_element(extension, element_name)
        end
        calculation_versions.each do |calculation_version|
          XMLHelper.add_element(calculation, 'Version', calculation_version, :string)
        end
      end
      if (not @timestep.nil?) || (not @sim_begin_month.nil?) || (not @sim_begin_day.nil?) || (not @sim_end_month.nil?) || (not @sim_end_day.nil?) || (not @sim_calendar_year.nil?) || (not @temperature_capacitance_multiplier.nil?) || (not @hvac_onoff_thermostat_deadband.nil?) || (not @heat_pump_backup_heating_capacity_increment.nil?) || (not @ground_to_air_heat_pump_model_type.nil?)
        extension = XMLHelper.create_elements_as_needed(software_info, ['extension'])
        simulation_control = XMLHelper.add_element(extension, 'SimulationControl')
        XMLHelper.add_element(simulation_control, 'Timestep', @timestep, :integer, @timestep_isdefaulted) unless @timestep.nil?
        XMLHelper.add_element(simulation_control, 'BeginMonth', @sim_begin_month, :integer, @sim_begin_month_isdefaulted) unless @sim_begin_month.nil?
        XMLHelper.add_element(simulation_control, 'BeginDayOfMonth', @sim_begin_day, :integer, @sim_begin_day_isdefaulted) unless @sim_begin_day.nil?
        XMLHelper.add_element(simulation_control, 'EndMonth', @sim_end_month, :integer, @sim_end_month_isdefaulted) unless @sim_end_month.nil?
        XMLHelper.add_element(simulation_control, 'EndDayOfMonth', @sim_end_day, :integer, @sim_end_day_isdefaulted) unless @sim_end_day.nil?
        XMLHelper.add_element(simulation_control, 'CalendarYear', @sim_calendar_year, :integer, @sim_calendar_year_isdefaulted) unless @sim_calendar_year.nil?
        if (not @temperature_capacitance_multiplier.nil?) || (not @hvac_onoff_thermostat_deadband.nil?) || (not @heat_pump_backup_heating_capacity_increment.nil?) || (not @ground_to_air_heat_pump_model_type.nil?)
          advanced_research_features = XMLHelper.create_elements_as_needed(simulation_control, ['AdvancedResearchFeatures'])
          XMLHelper.add_element(advanced_research_features, 'TemperatureCapacitanceMultiplier', @temperature_capacitance_multiplier, :float, @temperature_capacitance_multiplier_isdefaulted) unless @temperature_capacitance_multiplier.nil?
          XMLHelper.add_element(advanced_research_features, 'OnOffThermostatDeadbandTemperature', @hvac_onoff_thermostat_deadband, :float, @hvac_onoff_thermostat_deadband_isdefaulted) unless @hvac_onoff_thermostat_deadband.nil?
          XMLHelper.add_element(advanced_research_features, 'HeatPumpBackupCapacityIncrement', @heat_pump_backup_heating_capacity_increment, :float, @heat_pump_backup_heating_capacity_increment_isdefaulted) unless @heat_pump_backup_heating_capacity_increment.nil?
          XMLHelper.add_element(advanced_research_features, 'GroundToAirHeatPumpModelType', @ground_to_air_heat_pump_model_type, :string, @ground_to_air_heat_pump_model_type_isdefaulted) unless @ground_to_air_heat_pump_model_type.nil?
        end
      end
      if (not @service_feeders_load_calculation_types.nil?) && (not @service_feeders_load_calculation_types.empty?)
        extension = XMLHelper.create_elements_as_needed(software_info, ['extension'])
        electric_panel_load_calculations = XMLHelper.create_elements_as_needed(extension, ['ElectricPanelLoadCalculations'])
        service_feeders = XMLHelper.add_element(electric_panel_load_calculations, 'ServiceFeeders')
        @service_feeders_load_calculation_types.each do |service_feeders_load_calculation_type|
          XMLHelper.add_element(service_feeders, 'Type', service_feeders_load_calculation_type, :string)
        end
      end
      @emissions_scenarios.to_doc(hpxml)
      @utility_bill_scenarios.to_doc(hpxml)
      @unavailable_periods.to_doc(hpxml)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param hpxml [Oga::XML::Element] Root XML element of the HPXML document
    # @return [nil]
    def from_doc(hpxml)
      return if hpxml.nil?

      @xml_type = XMLHelper.get_value(hpxml, 'XMLTransactionHeaderInformation/XMLType', :string)
      @xml_generated_by = XMLHelper.get_value(hpxml, 'XMLTransactionHeaderInformation/XMLGeneratedBy', :string)
      @created_date_and_time = XMLHelper.get_value(hpxml, 'XMLTransactionHeaderInformation/CreatedDateAndTime', :string)
      @transaction = XMLHelper.get_value(hpxml, 'XMLTransactionHeaderInformation/Transaction', :string)
      @software_program_used = XMLHelper.get_value(hpxml, 'SoftwareInfo/SoftwareProgramUsed', :string)
      @software_program_version = XMLHelper.get_value(hpxml, 'SoftwareInfo/SoftwareProgramVersion', :string)
      @eri_calculation_versions = XMLHelper.get_values(hpxml, 'SoftwareInfo/extension/ERICalculation/Version', :string)
      @co2index_calculation_versions = XMLHelper.get_values(hpxml, 'SoftwareInfo/extension/CO2IndexCalculation/Version', :string)
      @iecc_eri_calculation_versions = XMLHelper.get_values(hpxml, 'SoftwareInfo/extension/IECCERICalculation/Version', :string)
      @energystar_calculation_versions = XMLHelper.get_values(hpxml, 'SoftwareInfo/extension/EnergyStarCalculation/Version', :string)
      @denh_calculation_versions = XMLHelper.get_values(hpxml, 'SoftwareInfo/extension/DENHCalculation/Version', :string)
      @timestep = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/Timestep', :integer)
      @sim_begin_month = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/BeginMonth', :integer)
      @sim_begin_day = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/BeginDayOfMonth', :integer)
      @sim_end_month = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/EndMonth', :integer)
      @sim_end_day = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/EndDayOfMonth', :integer)
      @sim_calendar_year = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/CalendarYear', :integer)
      @temperature_capacitance_multiplier = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/AdvancedResearchFeatures/TemperatureCapacitanceMultiplier', :float)
      @hvac_onoff_thermostat_deadband = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/AdvancedResearchFeatures/OnOffThermostatDeadbandTemperature', :float)
      @heat_pump_backup_heating_capacity_increment = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/AdvancedResearchFeatures/HeatPumpBackupCapacityIncrement', :float)
      @ground_to_air_heat_pump_model_type = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/SimulationControl/AdvancedResearchFeatures/GroundToAirHeatPumpModelType', :string)
      @apply_ashrae140_assumptions = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/ApplyASHRAE140Assumptions', :boolean)
      @whole_sfa_or_mf_building_sim = XMLHelper.get_value(hpxml, 'SoftwareInfo/extension/WholeSFAorMFBuildingSimulation', :boolean)
      @service_feeders_load_calculation_types = XMLHelper.get_values(hpxml, 'SoftwareInfo/extension/ElectricPanelLoadCalculations/ServiceFeeders/Type', :string)
      @emissions_scenarios.from_doc(hpxml)
      @utility_bill_scenarios.from_doc(hpxml)
      @unavailable_periods.from_doc(hpxml)
    end
  end

  # Array of HPXML::EmissionSenario objects.
  class EmissionsScenarios < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << EmissionsScenario.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param hpxml [Oga::XML::Element] Root XML element of the HPXML document
    # @return [nil]
    def from_doc(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'SoftwareInfo/extension/EmissionsScenarios/EmissionsScenario').each do |emissions_scenario|
        self << EmissionsScenario.new(@parent_object, emissions_scenario)
      end
    end
  end

  # Object for /HPXML/SoftwareInfo/extension/EmissionsScenarios/EmissionsScenario.
  class EmissionsScenario < BaseElement
    UnitsKgPerMWh = 'kg/MWh'
    UnitsKgPerMBtu = 'kg/MBtu'
    UnitsLbPerMWh = 'lb/MWh'
    UnitsLbPerMBtu = 'lb/MBtu'

    ATTRS = [:name,                                # [String] Name
             :emissions_type,                      # [String] EmissionsType
             :elec_units,                          # [String] EmissionsFactor[FuelType="electricity"]/Units
             :elec_value,                          # [Double] EmissionsFactor[FuelType="electricity"]/Value
             :elec_schedule_filepath,              # [String] EmissionsFactor[FuelType="electricity"]/ScheduleFilePath
             :elec_schedule_number_of_header_rows, # [Integer] EmissionsFactor[FuelType="electricity"]/NumberofHeaderRows
             :elec_schedule_column_number,         # [Integer] EmissionsFactor[FuelType="electricity"]/ColumnNumber
             :natural_gas_units,                   # [String] EmissionsFactor[FuelType="natural gas"]/Units
             :natural_gas_value,                   # [Double] EmissionsFactor[FuelType="natural gas"]/Value
             :propane_units,                       # [String] EmissionsFactor[FuelType="propane"]/Units
             :propane_value,                       # [Double] EmissionsFactor[FuelType="propane"]/Value
             :fuel_oil_units,                      # [String] EmissionsFactor[FuelType="fuel oil"]/Units
             :fuel_oil_value,                      # [Double] EmissionsFactor[FuelType="fuel oil"]/Value
             :coal_units,                          # [String] EmissionsFactor[FuelType="coal"]/Units
             :coal_value,                          # [Double] EmissionsFactor[FuelType="coal"]/Value
             :wood_units,                          # [String] EmissionsFactor[FuelType="wood"]/Units
             :wood_value,                          # [Double] EmissionsFactor[FuelType="wood"]/Value
             :wood_pellets_units,                  # [String] EmissionsFactor[FuelType="wood pellets"]/Units
             :wood_pellets_value]                  # [Double] EmissionsFactor[FuelType="wood pellets"]/Value
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.header.emissions_scenarios.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the Oga XML document.
    #
    # @param hpxml [Oga::XML::Element] Root XML element of the HPXML document
    # @return [nil]
    def to_doc(hpxml)
      emissions_scenarios = XMLHelper.create_elements_as_needed(hpxml, ['SoftwareInfo', 'extension', 'EmissionsScenarios'])
      emissions_scenario = XMLHelper.add_element(emissions_scenarios, 'EmissionsScenario')
      XMLHelper.add_element(emissions_scenario, 'Name', @name, :string) unless @name.nil?
      XMLHelper.add_element(emissions_scenario, 'EmissionsType', @emissions_type, :string) unless @emissions_type.nil?
      if not @elec_schedule_filepath.nil?
        emissions_factor = XMLHelper.add_element(emissions_scenario, 'EmissionsFactor')
        XMLHelper.add_element(emissions_factor, 'FuelType', HPXML::FuelTypeElectricity, :string)
        XMLHelper.add_element(emissions_factor, 'Units', @elec_units, :string)
        XMLHelper.add_element(emissions_factor, 'ScheduleFilePath', @elec_schedule_filepath, :string)
        XMLHelper.add_element(emissions_factor, 'NumberofHeaderRows', @elec_schedule_number_of_header_rows, :integer, @elec_schedule_number_of_header_rows_isdefaulted) unless @elec_schedule_number_of_header_rows.nil?
        XMLHelper.add_element(emissions_factor, 'ColumnNumber', @elec_schedule_column_number, :integer, @elec_schedule_column_number_isdefaulted) unless @elec_schedule_column_number.nil?
      end
      { HPXML::FuelTypeElectricity => [@elec_units, @elec_units_isdefaulted,
                                       @elec_value, @elec_value_isdefaulted],
        HPXML::FuelTypeNaturalGas => [@natural_gas_units, @natural_gas_units_isdefaulted,
                                      @natural_gas_value, @natural_gas_value_isdefaulted],
        HPXML::FuelTypePropane => [@propane_units, @propane_units_isdefaulted,
                                   @propane_value, @propane_value_isdefaulted],
        HPXML::FuelTypeOil => [@fuel_oil_units, @fuel_oil_units_isdefaulted,
                               @fuel_oil_value, @fuel_oil_value_isdefaulted],
        HPXML::FuelTypeCoal => [@coal_units, @coal_units_isdefaulted,
                                @coal_value, @coal_value_isdefaulted],
        HPXML::FuelTypeWoodCord => [@wood_units, @wood_units_isdefaulted,
                                    @wood_value, @wood_value_isdefaulted],
        HPXML::FuelTypeWoodPellets => [@wood_pellets_units, @wood_pellets_units_isdefaulted,
                                       @wood_pellets_value, @wood_pellets_value_isdefaulted] }.each do |fuel, vals|
        units, units_isdefaulted, value, value_isdefaulted = vals
        next if value.nil?

        emissions_factor = XMLHelper.add_element(emissions_scenario, 'EmissionsFactor')
        XMLHelper.add_element(emissions_factor, 'FuelType', fuel, :string)
        XMLHelper.add_element(emissions_factor, 'Units', units, :string, units_isdefaulted)
        XMLHelper.add_element(emissions_factor, 'Value', value, :float, value_isdefaulted)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param emissions_scenario [Oga::XML::Element] The current EmissionsScenario XML element
    # @return [nil]
    def from_doc(emissions_scenario)
      return if emissions_scenario.nil?

      @name = XMLHelper.get_value(emissions_scenario, 'Name', :string)
      @emissions_type = XMLHelper.get_value(emissions_scenario, 'EmissionsType', :string)
      @elec_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeElectricity}']/Units", :string)
      @elec_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeElectricity}']/Value", :float)
      @elec_schedule_filepath = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeElectricity}']/ScheduleFilePath", :string)
      @elec_schedule_number_of_header_rows = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeElectricity}']/NumberofHeaderRows", :integer)
      @elec_schedule_column_number = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeElectricity}']/ColumnNumber", :integer)
      @natural_gas_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeNaturalGas}']/Units", :string)
      @natural_gas_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeNaturalGas}']/Value", :float)
      @propane_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypePropane}']/Units", :string)
      @propane_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypePropane}']/Value", :float)
      @fuel_oil_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeOil}']/Units", :string)
      @fuel_oil_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeOil}']/Value", :float)
      @coal_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeCoal}']/Units", :string)
      @coal_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeCoal}']/Value", :float)
      @wood_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeWoodCord}']/Units", :string)
      @wood_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeWoodCord}']/Value", :float)
      @wood_pellets_units = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeWoodPellets}']/Units", :string)
      @wood_pellets_value = XMLHelper.get_value(emissions_scenario, "EmissionsFactor[FuelType='#{HPXML::FuelTypeWoodPellets}']/Value", :float)
    end
  end

  # Array of HPXML::UtilityBillScenario objects.
  class UtilityBillScenarios < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << UtilityBillScenario.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param hpxml [Oga::XML::Element] Root XML element of the HPXML document
    # @return [nil]
    def from_doc(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'SoftwareInfo/extension/UtilityBillScenarios/UtilityBillScenario').each do |utility_bill_scenario|
        self << UtilityBillScenario.new(@parent_object, utility_bill_scenario)
      end
    end

    # Checks whether the utility bill scenario has simple (vs detailed) electric rates
    #
    # @return [Boolean] true if simple electric rates
    def has_simple_electric_rates
      any? { |bill_scen| !bill_scen.elec_fixed_charge.nil? || !bill_scen.elec_marginal_rate.nil? }
    end

    # Checks whether the utility bill scenario has detailed (vs simple) electric rates
    #
    # @return [Boolean] true if detailed electric rates
    def has_detailed_electric_rates
      any? { |bill_scen| !bill_scen.elec_tariff_filepath.nil? }
    end
  end

  # Object for /HPXML/SoftwareInfo/extension/UtilityBillScenarios/UtilityBillScenario.
  class UtilityBillScenario < BaseElement
    ATTRS = [:name,                                             # [String] Name
             :elec_tariff_filepath,                             # [String] UtilityRate[FuelType="electricity"]/TariffFilePath
             :elec_fixed_charge,                                # [Double] UtilityRate[FuelType="electricity"]/FixedCharge ($/month)
             :elec_marginal_rate,                               # [Double] UtilityRate[FuelType="electricity"]/MarginalRate ($/kWh)
             :natural_gas_fixed_charge,                         # [Double] UtilityRate[FuelType="natural gas"]/FixedCharge ($/month)
             :natural_gas_marginal_rate,                        # [Double] UtilityRate[FuelType="natural gas"]/MarginalRate ($/therm)
             :propane_fixed_charge,                             # [Double] UtilityRate[FuelType="propane"]/FixedCharge ($/month)
             :propane_marginal_rate,                            # [Double] UtilityRate[FuelType="propane"]/MarginalRate ($/gallon)
             :fuel_oil_fixed_charge,                            # [Double] UtilityRate[FuelType="fuel oil"]/FixedCharge ($/month)
             :fuel_oil_marginal_rate,                           # [Double] UtilityRate[FuelType="fuel oil"]/MarginalRate ($/gallon)
             :coal_fixed_charge,                                # [Double] UtilityRate[FuelType="coal"]/FixedCharge ($/month)
             :coal_marginal_rate,                               # [Double] UtilityRate[FuelType="coal"]/MarginalRate ($/kBtu)
             :wood_fixed_charge,                                # [Double] UtilityRate[FuelType="wood"]/FixedCharge ($/month)
             :wood_marginal_rate,                               # [Double] UtilityRate[FuelType="wood"]/MarginalRate ($/kBtu)
             :wood_pellets_fixed_charge,                        # [Double] UtilityRate[FuelType="wood pellets"]/FixedCharge ($/month)
             :wood_pellets_marginal_rate,                       # [Double] UtilityRate[FuelType="wood pellets"]/MarginalRate ($/kBtu)
             :pv_compensation_type,                             # [String] PVCompensation/CompensationType/*
             :pv_net_metering_annual_excess_sellback_rate_type, # [String] PVCompensation/CompensationType/NetMetering/AnnualExcessSellbackRateType (HPXML::PVAnnualExcessSellbackRateTypeXXX)
             :pv_net_metering_annual_excess_sellback_rate,      # [Double] PVCompensation/CompensationType/NetMetering/AnnualExcessSellbackRate ($/kWh)
             :pv_feed_in_tariff_rate,                           # [Double] PVCompensation/CompensationType/FeedInTariff/FeedInTariffRate ($/kWh)
             :pv_monthly_grid_connection_fee_dollars_per_kw,    # [Double] PVCompensation/MonthlyGridConnectionFee[Units="$/kW"]/Value ($/kW)
             :pv_monthly_grid_connection_fee_dollars]           # [Double] PVCompensation/MonthlyGridConnectionFee[Units="$"]/Value ($)
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.header.utility_bill_scenarios.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the Oga XML document.
    #
    # @param hpxml [Oga::XML::Element] Root XML element of the HPXML document
    # @return [nil]
    def to_doc(hpxml)
      utility_bill_scenarios = XMLHelper.create_elements_as_needed(hpxml, ['SoftwareInfo', 'extension', 'UtilityBillScenarios'])
      utility_bill_scenario = XMLHelper.add_element(utility_bill_scenarios, 'UtilityBillScenario')
      XMLHelper.add_element(utility_bill_scenario, 'Name', @name, :string) unless @name.nil?
      { HPXML::FuelTypeElectricity => [@elec_fixed_charge, @elec_fixed_charge_isdefaulted, @elec_marginal_rate, @elec_marginal_rate_isdefaulted, @elec_tariff_filepath],
        HPXML::FuelTypeNaturalGas => [@natural_gas_fixed_charge, @natural_gas_fixed_charge_isdefaulted, @natural_gas_marginal_rate, @natural_gas_marginal_rate_isdefaulted, nil],
        HPXML::FuelTypePropane => [@propane_fixed_charge, @propane_fixed_charge_isdefaulted, @propane_marginal_rate, @propane_marginal_rate_isdefaulted, nil],
        HPXML::FuelTypeOil => [@fuel_oil_fixed_charge, @fuel_oil_fixed_charge_isdefaulted, @fuel_oil_marginal_rate, @fuel_oil_marginal_rate_isdefaulted, nil],
        HPXML::FuelTypeCoal => [@coal_fixed_charge, @coal_fixed_charge_isdefaulted, @coal_marginal_rate, @coal_marginal_rate_isdefaulted, nil],
        HPXML::FuelTypeWoodCord => [@wood_fixed_charge, @wood_fixed_charge_isdefaulted, @wood_marginal_rate, @wood_marginal_rate_isdefaulted, nil],
        HPXML::FuelTypeWoodPellets => [@wood_pellets_fixed_charge, @wood_pellets_fixed_charge_isdefaulted, @wood_pellets_marginal_rate, @wood_pellets_marginal_rate_isdefaulted, nil] }.each do |fuel, vals|
        fixed_charge, fixed_charge_isdefaulted, marginal_rate, marginal_rate_isdefaulted, tariff_filepath = vals
        next if fixed_charge.nil? && marginal_rate.nil? && tariff_filepath.nil?

        utility_rate = XMLHelper.add_element(utility_bill_scenario, 'UtilityRate')
        XMLHelper.add_element(utility_rate, 'FuelType', fuel, :string)
        XMLHelper.add_element(utility_rate, 'TariffFilePath', tariff_filepath, :string) unless tariff_filepath.nil?
        XMLHelper.add_element(utility_rate, 'FixedCharge', fixed_charge, :float, fixed_charge_isdefaulted) unless fixed_charge.nil?
        XMLHelper.add_element(utility_rate, 'MarginalRate', marginal_rate, :float, marginal_rate_isdefaulted) unless marginal_rate.nil?
      end
      if not @pv_compensation_type.nil?
        pv = XMLHelper.add_element(utility_bill_scenario, 'PVCompensation')
        pc_compensation_type = XMLHelper.add_element(pv, 'CompensationType')
        pv_compensation_type_el = XMLHelper.add_element(pc_compensation_type, @pv_compensation_type, nil, nil, pv_compensation_type_isdefaulted)
        if @pv_compensation_type == HPXML::PVCompensationTypeNetMetering
          XMLHelper.add_element(pv_compensation_type_el, 'AnnualExcessSellbackRateType', @pv_net_metering_annual_excess_sellback_rate_type, :string, pv_net_metering_annual_excess_sellback_rate_type_isdefaulted) unless @pv_net_metering_annual_excess_sellback_rate_type.nil?
          if @pv_net_metering_annual_excess_sellback_rate_type == HPXML::PVAnnualExcessSellbackRateTypeUserSpecified
            XMLHelper.add_element(pv_compensation_type_el, 'AnnualExcessSellbackRate', @pv_net_metering_annual_excess_sellback_rate, :float, pv_net_metering_annual_excess_sellback_rate_isdefaulted) unless @pv_net_metering_annual_excess_sellback_rate.nil?
          end
        elsif @pv_compensation_type == HPXML::PVCompensationTypeFeedInTariff
          XMLHelper.add_element(pv_compensation_type_el, 'FeedInTariffRate', @pv_feed_in_tariff_rate, :float, pv_feed_in_tariff_rate_isdefaulted) unless @pv_feed_in_tariff_rate.nil?
        end
        if not @pv_monthly_grid_connection_fee_dollars_per_kw.nil?
          monthly_grid_connection_fee = XMLHelper.add_element(pv, 'MonthlyGridConnectionFee')
          XMLHelper.add_element(monthly_grid_connection_fee, 'Units', UnitsDollarsPerkW, :string)
          XMLHelper.add_element(monthly_grid_connection_fee, 'Value', @pv_monthly_grid_connection_fee_dollars_per_kw, :float, pv_monthly_grid_connection_fee_dollars_per_kw_isdefaulted)
        end
        if not @pv_monthly_grid_connection_fee_dollars.nil?
          monthly_grid_connection_fee = XMLHelper.add_element(pv, 'MonthlyGridConnectionFee')
          XMLHelper.add_element(monthly_grid_connection_fee, 'Units', UnitsDollars, :string)
          XMLHelper.add_element(monthly_grid_connection_fee, 'Value', @pv_monthly_grid_connection_fee_dollars, :float, pv_monthly_grid_connection_fee_dollars_isdefaulted)
        end
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param utility_bill_scenario [Oga::XML::Element] The current UtilityBillScenario XML element
    # @return [nil]
    def from_doc(utility_bill_scenario)
      return if utility_bill_scenario.nil?

      @name = XMLHelper.get_value(utility_bill_scenario, 'Name', :string)
      @elec_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeElectricity}']/FixedCharge", :float)
      @elec_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeElectricity}']/MarginalRate", :float)
      @elec_tariff_filepath = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeElectricity}']/TariffFilePath", :string)
      @natural_gas_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeNaturalGas}']/FixedCharge", :float)
      @natural_gas_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeNaturalGas}']/MarginalRate", :float)
      @propane_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypePropane}']/FixedCharge", :float)
      @propane_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypePropane}']/MarginalRate", :float)
      @fuel_oil_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeOil}']/FixedCharge", :float)
      @fuel_oil_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeOil}']/MarginalRate", :float)
      @coal_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeCoal}']/FixedCharge", :float)
      @coal_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeCoal}']/MarginalRate", :float)
      @wood_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeWoodCord}']/FixedCharge", :float)
      @wood_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeWoodCord}']/MarginalRate", :float)
      @wood_pellets_fixed_charge = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeWoodPellets}']/FixedCharge", :float)
      @wood_pellets_marginal_rate = XMLHelper.get_value(utility_bill_scenario, "UtilityRate[FuelType='#{HPXML::FuelTypeWoodPellets}']/MarginalRate", :float)
      @pv_compensation_type = XMLHelper.get_child_name(utility_bill_scenario, 'PVCompensation/CompensationType')
      if @pv_compensation_type == HPXML::PVCompensationTypeNetMetering
        @pv_net_metering_annual_excess_sellback_rate_type = XMLHelper.get_value(utility_bill_scenario, "PVCompensation/CompensationType/#{HPXML::PVCompensationTypeNetMetering}/AnnualExcessSellbackRateType", :string)
        if @pv_net_metering_annual_excess_sellback_rate_type == HPXML::PVAnnualExcessSellbackRateTypeUserSpecified
          @pv_net_metering_annual_excess_sellback_rate = XMLHelper.get_value(utility_bill_scenario, "PVCompensation/CompensationType/#{HPXML::PVCompensationTypeNetMetering}/AnnualExcessSellbackRate", :float)
        end
      elsif @pv_compensation_type == HPXML::PVCompensationTypeFeedInTariff
        @pv_feed_in_tariff_rate = XMLHelper.get_value(utility_bill_scenario, "PVCompensation/CompensationType/#{HPXML::PVCompensationTypeFeedInTariff}/FeedInTariffRate", :float)
      end
      @pv_monthly_grid_connection_fee_dollars_per_kw = XMLHelper.get_value(utility_bill_scenario, "PVCompensation/MonthlyGridConnectionFee[Units='#{UnitsDollarsPerkW}']/Value", :float)
      @pv_monthly_grid_connection_fee_dollars = XMLHelper.get_value(utility_bill_scenario, "PVCompensation/MonthlyGridConnectionFee[Units='#{UnitsDollars}']/Value", :float)
    end
  end

  # Array of HPXML::UnavailablePeriod objects.
  class UnavailablePeriods < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << UnavailablePeriod.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param hpxml [Oga::XML::Element] Root XML element of the HPXML document
    # @return [nil]
    def from_doc(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'SoftwareInfo/extension/UnavailablePeriods/UnavailablePeriod').each do |unavailable_period|
        self << UnavailablePeriod.new(@parent_object, unavailable_period)
      end
    end
  end

  # Object for /HPXML/SoftwareInfo/extension/UnavailablePeriods/UnavailablePeriod.
  class UnavailablePeriod < BaseElement
    ATTRS = [:column_name,          # [String] ColumnName
             :begin_month,          # [Integer] BeginMonth
             :begin_day,            # [Integer] BeginDayOfMonth
             :begin_hour,           # [Integer] BeginHourOfDay
             :end_month,            # [Integer] EndMonth
             :end_day,              # [Integer] EndDayOfMonth
             :end_hour,             # [Integer] EndHourOfDay
             :natvent_availability] # [String] NaturalVentilation (HPXML::ScheduleXXX)
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.header.unavailable_periods.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      errors += HPXML::check_dates('Unavailable Period', @begin_month, @begin_day, @end_month, @end_day)
      return errors
    end

    # Adds this object to the Oga XML document.
    #
    # @param hpxml [Oga::XML::Element] Root XML element of the HPXML document
    # @return [nil]
    def to_doc(hpxml)
      unavailable_periods = XMLHelper.create_elements_as_needed(hpxml, ['SoftwareInfo', 'extension', 'UnavailablePeriods'])
      unavailable_period = XMLHelper.add_element(unavailable_periods, 'UnavailablePeriod')
      XMLHelper.add_element(unavailable_period, 'ColumnName', @column_name, :string) unless @column_name.nil?
      XMLHelper.add_element(unavailable_period, 'BeginMonth', @begin_month, :integer, @begin_month_isdefaulted) unless @begin_month.nil?
      XMLHelper.add_element(unavailable_period, 'BeginDayOfMonth', @begin_day, :integer, @begin_day_isdefaulted) unless @begin_day.nil?
      XMLHelper.add_element(unavailable_period, 'BeginHourOfDay', @begin_hour, :integer, @begin_hour_isdefaulted) unless @begin_hour.nil?
      XMLHelper.add_element(unavailable_period, 'EndMonth', @end_month, :integer, @end_month_isdefaulted) unless @end_month.nil?
      XMLHelper.add_element(unavailable_period, 'EndDayOfMonth', @end_day, :integer, @end_day_isdefaulted) unless @end_day.nil?
      XMLHelper.add_element(unavailable_period, 'EndHourOfDay', @end_hour, :integer, @end_hour_isdefaulted) unless @end_hour.nil?
      XMLHelper.add_element(unavailable_period, 'NaturalVentilation', @natvent_availability, :string, @natvent_availability_isdefaulted) unless @natvent_availability.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param unavailable_period [Oga::XML::Element] The current UnavailablePeriod XML element
    # @return [nil]
    def from_doc(unavailable_period)
      return if unavailable_period.nil?

      @column_name = XMLHelper.get_value(unavailable_period, 'ColumnName', :string)
      @begin_month = XMLHelper.get_value(unavailable_period, 'BeginMonth', :integer)
      @begin_day = XMLHelper.get_value(unavailable_period, 'BeginDayOfMonth', :integer)
      @begin_hour = XMLHelper.get_value(unavailable_period, 'BeginHourOfDay', :integer)
      @end_month = XMLHelper.get_value(unavailable_period, 'EndMonth', :integer)
      @end_day = XMLHelper.get_value(unavailable_period, 'EndDayOfMonth', :integer)
      @end_hour = XMLHelper.get_value(unavailable_period, 'EndHourOfDay', :integer)
      @natvent_availability = XMLHelper.get_value(unavailable_period, 'NaturalVentilation', :string)
    end
  end

  # Array of HPXML::Building objects.
  class Buildings < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Building.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param hpxml [Oga::XML::Element] Root XML element of the HPXML document
    # @return [nil]
    def from_doc(hpxml)
      return if hpxml.nil?

      XMLHelper.get_elements(hpxml, 'Building').each do |building|
        self << Building.new(@parent_object, building)
      end
    end
  end

  # Object for /HPXML/Building.
  class Building < BaseElement
    CLASS_ATTRS = [:site,                          # [HPXML::Site]
                   :neighbor_buildings,            # [HPXML::NeighborBuildings]
                   :building_occupancy,            # [HPXML::BuildingOccupancy]
                   :building_construction,         # [HPXML::BuildingConstruction]
                   :header,                        # [HPXML::BuildingHeader]
                   :climate_and_risk_zones,        # [HPXML::ClimateandRiskZones]
                   :zones,                         # [HPXML::Zones]
                   :air_infiltration,              # [HPXML::AirInfiltration]
                   :air_infiltration_measurements, # [HPXML::AirInfiltrationMeasurements]
                   :attics,                        # [HPXML::Attics]
                   :foundations,                   # [HPXML::Foundations]
                   :roofs,                         # [HPXML::Roofs]
                   :rim_joists,                    # [HPXML::RimJoists]
                   :walls,                         # [HPXML::Walls]
                   :foundation_walls,              # [HPXML::FoundationWalls]
                   :floors,                        # [HPXML::Floors]
                   :slabs,                         # [HPXML::Slabs]
                   :windows,                       # [HPXML::Windows]
                   :skylights,                     # [HPXML::Skylights]
                   :doors,                         # [HPXML::Doors]
                   :partition_wall_mass,           # [HPXML::PartitionWallMass]
                   :furniture_mass,                # [HPXML::FurnitureMass]
                   :heating_systems,               # [HPXML::HeatingSystems]
                   :cooling_systems,               # [HPXML::CoolingSystems]
                   :heat_pumps,                    # [HPXML::HeatPumps]
                   :geothermal_loops,              # [HPXML::GeothermalLoops]
                   :hvac_plant,                    # [HPXML::HVACPlant]
                   :hvac_controls,                 # [HPXML::HVACControls]
                   :hvac_distributions,            # [HPXML::HVACDistributions]
                   :ventilation_fans,              # [HPXML::VentilationFans]
                   :water_heating_systems,         # [HPXML::WaterHeatingSystems]
                   :hot_water_distributions,       # [HPXML::HotWaterDistributions]
                   :water_fixtures,                # [HPXML::WaterFixtures]
                   :water_heating,                 # [HPXML::WaterHeating]
                   :solar_thermal_systems,         # [HPXML::SolarThermalSystems]
                   :pv_systems,                    # [HPXML::PVSystems]
                   :inverters,                     # [HPXML::Inverters]
                   :electric_panels,               # [HPXML::ElectricPanels]
                   :batteries,                     # [HPXML::Batteries]
                   :vehicles,                      # [HPXML::Vehicles]
                   :ev_chargers,                   # [HPXML::ElectricVehicleChargers]
                   :generators,                    # [HPXML::Generators]
                   :clothes_washers,               # [HPXML::ClothesWashers]
                   :clothes_dryers,                # [HPXML::ClothesDryers]
                   :dishwashers,                   # [HPXML::Dishwashers]
                   :refrigerators,                 # [HPXML::Refrigerators]
                   :freezers,                      # [HPXML::Freezers]
                   :dehumidifiers,                 # [HPXML::Dehumidifiers]
                   :cooking_ranges,                # [HPXML::CookingRanges]
                   :ovens,                         # [HPXML::Ovens]
                   :lighting_groups,               # [HPXML::LightingGroups]
                   :ceiling_fans,                  # [HPXML::CeilingFans]
                   :lighting,                      # [HPXML::Lighting]
                   :pools,                         # [HPXML::Pools]
                   :permanent_spas,                # [HPXML::PermanentSpas]
                   :portable_spas,                 # [HPXML::PortableSpas]
                   :plug_loads,                    # [HPXML::PlugLoads]
                   :fuel_loads]                    # [HPXML::FuelLoads]
    ATTRS = [:building_id,          # [String] BuildingID/@id
             :site_id,              # [String] Site/SiteID/@id
             :city,                 # [String] Site/Address/CityMunicipality
             :state_code,           # [String] Site/Address/StateCode
             :zip_code,             # [String] Site/Address/ZipCode
             :latitude,             # [Double] Site/GeoLocation/Latitude (deg)
             :longitude,            # [Double] Site/GeoLocation/Longitude (deg)
             :elevation,            # [Double] Site/Elevation (ft)
             :egrid_region,         # [String] Site/eGridRegion
             :egrid_subregion,      # [String] Site/eGridSubregion
             :cambium_region_gea,   # [String] Site/CambiumRegionGEA
             :time_zone_utc_offset, # [Double] TimeZone/UTCOffset
             :dst_observed,         # [Boolean] TimeZone/DSTObserved
             :dst_begin_month,      # [Integer] TimeZone/extension/DSTBeginMonth
             :dst_begin_day,        # [Integer] TimeZone/extension/DSTBeginDayOfMonth
             :dst_end_month,        # [Integer] TimeZone/extension/DSTEndMonth
             :dst_end_day,          # [Integer] TimeZone/extension/DSTEndDayOfMonth
             :event_type]           # [String] ProjectStatus/EventType
    attr_reader(*CLASS_ATTRS)
    attr_accessor(*ATTRS)

    def initialize(*args, **kwargs)
      from_doc(nil)
      super(*args, **kwargs)
    end

    # Adds this object to the Oga XML document.
    #
    # @param hpxml_doc [Oga::XML::Document] HPXML object as an XML document
    # @return [nil]
    def to_doc(hpxml_doc)
      return if nil?

      hpxml = XMLHelper.create_elements_as_needed(hpxml_doc, ['HPXML'])
      building = XMLHelper.add_element(hpxml, 'Building')
      building_building_id = XMLHelper.add_element(building, 'BuildingID')
      XMLHelper.add_attribute(building_building_id, 'id', @building_id)
      if (not @state_code.nil?) || (not @zip_code.nil?) || (not @city.nil?) || (not @latitude.nil?) || (not @longitude.nil?) || (not @elevation.nil?) || (not @time_zone_utc_offset.nil?) || (not @egrid_region.nil?) || (not @egrid_subregion.nil?) || (not @cambium_region_gea.nil?) || (not @dst_observed.nil?) || (not @dst_begin_month.nil?) || (not @dst_begin_day.nil?) || (not @dst_end_month.nil?) || (not @dst_end_day.nil?)
        building_site = XMLHelper.add_element(building, 'Site')
        building_site_id = XMLHelper.add_element(building_site, 'SiteID')
        if @site_id.nil?
          bldg_idx = XMLHelper.get_elements(hpxml, 'Building').size
          if bldg_idx > 1
            XMLHelper.add_attribute(building_site_id, 'id', "SiteID_#{bldg_idx}")
          else
            XMLHelper.add_attribute(building_site_id, 'id', 'SiteID')
          end
        else
          XMLHelper.add_attribute(building_site_id, 'id', @site_id)
        end
        if (not @state_code.nil?) || (not @zip_code.nil?) || (not @city.nil?)
          address = XMLHelper.add_element(building_site, 'Address')
          XMLHelper.add_element(address, 'CityMunicipality', @city, :string, @city_isdefaulted) unless @city.nil?
          XMLHelper.add_element(address, 'StateCode', @state_code, :string, @state_code_isdefaulted) unless @state_code.nil?
          XMLHelper.add_element(address, 'ZipCode', @zip_code, :string) unless @zip_code.nil?
        end
        if (not @latitude.nil?) || (not @longitude.nil?)
          geo_location = XMLHelper.add_element(building_site, 'GeoLocation')
          XMLHelper.add_element(geo_location, 'Latitude', @latitude, :float, @latitude_isdefaulted) unless @latitude.nil?
          XMLHelper.add_element(geo_location, 'Longitude', @longitude, :float, @longitude_isdefaulted) unless @longitude.nil?
        end
        XMLHelper.add_element(building_site, 'Elevation', @elevation, :float, @elevation_isdefaulted) unless @elevation.nil?
        XMLHelper.add_element(building_site, 'eGridRegion', @egrid_region, :string, @egrid_region_isdefaulted) unless @egrid_region.nil?
        XMLHelper.add_element(building_site, 'eGridSubregion', @egrid_subregion, :string, @egrid_subregion_isdefaulted) unless @egrid_subregion.nil?
        XMLHelper.add_element(building_site, 'CambiumRegionGEA', @cambium_region_gea, :string, @cambium_region_gea_isdefaulted) unless @cambium_region_gea.nil?
        if (not @time_zone_utc_offset.nil?) || (not @dst_observed.nil?) || (not @dst_begin_month.nil?) || (not @dst_begin_day.nil?) || (not @dst_end_month.nil?) || (not @dst_end_day.nil?)
          time_zone = XMLHelper.add_element(building_site, 'TimeZone')
          XMLHelper.add_element(time_zone, 'UTCOffset', @time_zone_utc_offset, :float, @time_zone_utc_offset_isdefaulted) unless @time_zone_utc_offset.nil?
          XMLHelper.add_element(time_zone, 'DSTObserved', @dst_observed, :boolean, @dst_observed_isdefaulted) unless @dst_observed.nil?
          XMLHelper.add_extension(time_zone, 'DSTBeginMonth', @dst_begin_month, :integer, @dst_begin_month_isdefaulted) unless @dst_begin_month.nil?
          XMLHelper.add_extension(time_zone, 'DSTBeginDayOfMonth', @dst_begin_day, :integer, @dst_begin_day_isdefaulted) unless @dst_begin_day.nil?
          XMLHelper.add_extension(time_zone, 'DSTEndMonth', @dst_end_month, :integer, @dst_end_month_isdefaulted) unless @dst_end_month.nil?
          XMLHelper.add_extension(time_zone, 'DSTEndDayOfMonth', @dst_end_day, :integer, @dst_end_day_isdefaulted) unless @dst_end_day.nil?
        end
      end
      project_status = XMLHelper.add_element(building, 'ProjectStatus')
      XMLHelper.add_element(project_status, 'EventType', @event_type, :string)

      @site.to_doc(building)
      @neighbor_buildings.to_doc(building)
      @building_occupancy.to_doc(building)
      @building_construction.to_doc(building)
      @header.to_doc(building)
      @climate_and_risk_zones.to_doc(building)
      @zones.to_doc(building)
      @air_infiltration_measurements.to_doc(building)
      @air_infiltration.to_doc(building)
      @attics.to_doc(building)
      @foundations.to_doc(building)
      @roofs.to_doc(building)
      @rim_joists.to_doc(building)
      @walls.to_doc(building)
      @foundation_walls.to_doc(building)
      @floors.to_doc(building)
      @slabs.to_doc(building)
      @windows.to_doc(building)
      @skylights.to_doc(building)
      @doors.to_doc(building)
      @partition_wall_mass.to_doc(building)
      @furniture_mass.to_doc(building)
      @heating_systems.to_doc(building)
      @cooling_systems.to_doc(building)
      @heat_pumps.to_doc(building)
      @geothermal_loops.to_doc(building)
      @hvac_plant.to_doc(building)
      @hvac_controls.to_doc(building)
      @hvac_distributions.to_doc(building)
      @ventilation_fans.to_doc(building)
      @water_heating_systems.to_doc(building)
      @hot_water_distributions.to_doc(building)
      @water_fixtures.to_doc(building)
      @water_heating.to_doc(building)
      @solar_thermal_systems.to_doc(building)
      @pv_systems.to_doc(building)
      @inverters.to_doc(building)
      @electric_panels.to_doc(building)
      @batteries.to_doc(building)
      @vehicles.to_doc(building)
      @ev_chargers.to_doc(building)
      @generators.to_doc(building)
      @clothes_washers.to_doc(building)
      @clothes_dryers.to_doc(building)
      @dishwashers.to_doc(building)
      @refrigerators.to_doc(building)
      @freezers.to_doc(building)
      @dehumidifiers.to_doc(building)
      @cooking_ranges.to_doc(building)
      @ovens.to_doc(building)
      @lighting_groups.to_doc(building)
      @ceiling_fans.to_doc(building)
      @lighting.to_doc(building)
      @pools.to_doc(building)
      @permanent_spas.to_doc(building)
      @portable_spas.to_doc(building)
      @plug_loads.to_doc(building)
      @fuel_loads.to_doc(building)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      if not building.nil?
        @building_id = HPXML::get_id(building, 'BuildingID')
        @event_type = XMLHelper.get_value(building, 'ProjectStatus/EventType', :string)
        @site_id = HPXML::get_id(building, 'Site/SiteID')
        @city = XMLHelper.get_value(building, 'Site/Address/CityMunicipality', :string)
        @state_code = XMLHelper.get_value(building, 'Site/Address/StateCode', :string)
        @zip_code = XMLHelper.get_value(building, 'Site/Address/ZipCode', :string)
        @latitude = XMLHelper.get_value(building, 'Site/GeoLocation/Latitude', :float)
        @longitude = XMLHelper.get_value(building, 'Site/GeoLocation/Longitude', :float)
        @elevation = XMLHelper.get_value(building, 'Site/Elevation', :float)
        @egrid_region = XMLHelper.get_value(building, 'Site/eGridRegion', :string)
        @egrid_subregion = XMLHelper.get_value(building, 'Site/eGridSubregion', :string)
        @cambium_region_gea = XMLHelper.get_value(building, 'Site/CambiumRegionGEA', :string)
        @time_zone_utc_offset = XMLHelper.get_value(building, 'Site/TimeZone/UTCOffset', :float)
        @dst_observed = XMLHelper.get_value(building, 'Site/TimeZone/DSTObserved', :boolean)
        if @dst_observed
          @dst_begin_month = XMLHelper.get_value(building, 'Site/TimeZone/extension/DSTBeginMonth', :integer)
          @dst_begin_day = XMLHelper.get_value(building, 'Site/TimeZone/extension/DSTBeginDayOfMonth', :integer)
          @dst_end_month = XMLHelper.get_value(building, 'Site/TimeZone/extension/DSTEndMonth', :integer)
          @dst_end_day = XMLHelper.get_value(building, 'Site/TimeZone/extension/DSTEndDayOfMonth', :integer)
        end
      end

      @site = Site.new(self, building)
      @neighbor_buildings = NeighborBuildings.new(self, building)
      @building_occupancy = BuildingOccupancy.new(self, building)
      @building_construction = BuildingConstruction.new(self, building)
      @header = BuildingHeader.new(self, building)
      @climate_and_risk_zones = ClimateandRiskZones.new(self, building)
      @zones = Zones.new(self, building)
      @air_infiltration_measurements = AirInfiltrationMeasurements.new(self, building)
      @air_infiltration = AirInfiltration.new(self, building)
      @attics = Attics.new(self, building)
      @foundations = Foundations.new(self, building)
      @roofs = Roofs.new(self, building)
      @rim_joists = RimJoists.new(self, building)
      @walls = Walls.new(self, building)
      @foundation_walls = FoundationWalls.new(self, building)
      @floors = Floors.new(self, building)
      @slabs = Slabs.new(self, building)
      @windows = Windows.new(self, building)
      @skylights = Skylights.new(self, building)
      @doors = Doors.new(self, building)
      @partition_wall_mass = PartitionWallMass.new(self, building)
      @furniture_mass = FurnitureMass.new(self, building)
      @heating_systems = HeatingSystems.new(self, building)
      @cooling_systems = CoolingSystems.new(self, building)
      @heat_pumps = HeatPumps.new(self, building)
      @geothermal_loops = GeothermalLoops.new(self, building)
      @hvac_plant = HVACPlant.new(self, building)
      @hvac_controls = HVACControls.new(self, building)
      @hvac_distributions = HVACDistributions.new(self, building)
      @ventilation_fans = VentilationFans.new(self, building)
      @water_heating_systems = WaterHeatingSystems.new(self, building)
      @hot_water_distributions = HotWaterDistributions.new(self, building)
      @water_fixtures = WaterFixtures.new(self, building)
      @water_heating = WaterHeating.new(self, building)
      @solar_thermal_systems = SolarThermalSystems.new(self, building)
      @pv_systems = PVSystems.new(self, building)
      @inverters = Inverters.new(self, building)
      @electric_panels = ElectricPanels.new(self, building)
      @batteries = Batteries.new(self, building)
      @vehicles = Vehicles.new(self, building)
      @ev_chargers = ElectricVehicleChargers.new(self, building)
      @generators = Generators.new(self, building)
      @clothes_washers = ClothesWashers.new(self, building)
      @clothes_dryers = ClothesDryers.new(self, building)
      @dishwashers = Dishwashers.new(self, building)
      @refrigerators = Refrigerators.new(self, building)
      @freezers = Freezers.new(self, building)
      @dehumidifiers = Dehumidifiers.new(self, building)
      @cooking_ranges = CookingRanges.new(self, building)
      @ovens = Ovens.new(self, building)
      @lighting_groups = LightingGroups.new(self, building)
      @ceiling_fans = CeilingFans.new(self, building)
      @lighting = Lighting.new(self, building)
      @pools = Pools.new(self, building)
      @permanent_spas = PermanentSpas.new(self, building)
      @portable_spas = PortableSpas.new(self, building)
      @plug_loads = PlugLoads.new(self, building)
      @fuel_loads = FuelLoads.new(self, building)
    end

    # Returns all HPXML enclosure surfaces.
    #
    # @return [Array<HPXML::XXX>] List of surface objects
    def surfaces
      return (@roofs + @rim_joists + @walls + @foundation_walls + @floors + @slabs)
    end

    # Returns all HPXML enclosure sub-surfaces.
    #
    # @return [Array<HPXML::XXX>] List of sub-surface objects
    def subsurfaces
      return (@windows + @skylights + @doors)
    end

    # Returns all HPXML HVAC systems.
    #
    # @return [Array<HPXML::XXX>] List of HVAC system objects
    def hvac_systems
      return (@heating_systems + @cooling_systems + @heat_pumps)
    end

    # Returns all HPXML appliances.
    #
    # @return [Array<HPXML::XXX>] List of appliance objects
    def appliances
      return (@clothes_washers + @clothes_dryers + @dishwashers + @refrigerators +
              @freezers + @dehumidifiers + @cooking_ranges + @ovens)
    end

    # Returns whether the building has a given location.
    #
    # @param location [String] The location of interest (HPXML::LocationXXX)
    # @return [Boolean] True if location is used by the building
    def has_location(location)
      # Search for surfaces attached to this location
      surfaces.each do |surface|
        return true if surface.interior_adjacent_to == location
        return true if surface.exterior_adjacent_to == location
      end
      return false
    end

    # Returns whether the building has access to non-electric fuels
    # (e.g., natural gas, propane, etc.).
    #
    # @return [Boolean] True if building has access to fuels
    def has_fuel_access
      @site.available_fuels.each do |fuel|
        if fuel != FuelTypeElectricity
          return true
        end
      end
      return false
    end

    # Returns a hash with whether each fuel exists in the HPXML Building.
    #
    # @return [Hash] Map of HPXML::FuelTypeXXX => boolean
    def has_fuels()
      return @parent_object.has_fuels(@building_id)
    end

    # Returns the predominant heating fuel type (weighted by fraction of
    # heating load served).
    #
    # @return [String] Predominant heating fuel (HPXML::FuelTypeXXX)
    def predominant_heating_fuel
      fuel_fracs = {}
      @heating_systems.each do |heating_system|
        fuel = heating_system.heating_system_fuel
        fuel_fracs[fuel] = 0.0 if fuel_fracs[fuel].nil?
        fuel_fracs[fuel] += heating_system.fraction_heat_load_served.to_f
      end
      @heat_pumps.each do |heat_pump|
        fuel = heat_pump.heat_pump_fuel
        fuel_fracs[fuel] = 0.0 if fuel_fracs[fuel].nil?
        fuel_fracs[fuel] += heat_pump.fraction_heat_load_served.to_f
      end
      return FuelTypeElectricity if fuel_fracs.empty?
      return FuelTypeElectricity if fuel_fracs[FuelTypeElectricity].to_f > 0.5

      # Choose fossil fuel
      fuel_fracs.delete FuelTypeElectricity
      return fuel_fracs.key(fuel_fracs.values.max)
    end

    # Returns the predominant water heating fuel type (weighted by fraction of
    # DHW load served).
    #
    # @return [String] Predominant water heating fuel (HPXML::FuelTypeXXX)
    def predominant_water_heating_fuel
      fuel_fracs = {}
      @water_heating_systems.each do |water_heating_system|
        fuel = water_heating_system.fuel_type
        if fuel.nil? # Combi boiler
          fuel = water_heating_system.related_hvac_system.heating_system_fuel
        end
        fuel_fracs[fuel] = 0.0 if fuel_fracs[fuel].nil?
        fuel_fracs[fuel] += water_heating_system.fraction_dhw_load_served
      end
      return FuelTypeElectricity if fuel_fracs.empty?
      return FuelTypeElectricity if fuel_fracs[FuelTypeElectricity].to_f > 0.5

      # Choose fossil fuel
      fuel_fracs.delete FuelTypeElectricity
      return fuel_fracs.key(fuel_fracs.values.max)
    end

    # Calculates the fraction of windows that are operable.
    # Since we don't have count available, we use area as an approximation.
    #
    # @return [Double] Total fraction of window area that is window area of operable windows
    def fraction_of_windows_operable
      window_area_total = @windows.map { |w| w.area }.sum(0.0)
      window_area_operable = @windows.map { |w| w.fraction_operable * w.area }.sum(0.0)
      if window_area_total <= 0
        return 0.0
      end

      return window_area_operable / window_area_total
    end

    # Returns all HPXML zones that are conditioned.
    #
    # @return [Array<HPXML::Zone>] Conditioned zones
    def conditioned_zones
      return zones.select { |z| z.zone_type == ZoneTypeConditioned }
    end

    # Returns all HPXML spaces that are conditioned.
    #
    # @return [Array<HPXML::Space>] Conditioned spaces
    def conditioned_spaces
      return conditioned_zones.map { |z| z.spaces }.flatten
    end

    # Returns all HVAC systems that are labeled as primary systems.
    #
    # @return [Array<HPXML::XXX>] List of primary HVAC systems
    def primary_hvac_systems
      return hvac_systems.select { |h| h.primary_system }
    end

    # Returns the total fraction of building's cooling load served by HVAC systems.
    #
    # @return [Double] Total fraction of building's cooling load served
    def total_fraction_cool_load_served
      return @cooling_systems.total_fraction_cool_load_served + @heat_pumps.total_fraction_cool_load_served
    end

    # Returns the total fraction of building's heating load served by HVAC systems.
    #
    # @return [Double] Total fraction of building's heating load served
    def total_fraction_heat_load_served
      return @heating_systems.total_fraction_heat_load_served + @heat_pumps.total_fraction_heat_load_served + @cooling_systems.total_fraction_heat_load_served
    end

    # Calculates above-grade and below-grade thermal boundary wall areas.
    # Used to calculate the window area in the ERI Reference Home.
    #
    # Thermal boundary wall is any wall that separates conditioned space from
    # unconditioned space, outside, or soil. Above-grade thermal boundary
    # wall is any portion of a thermal boundary wall not in contact with soil.
    # Below-grade thermal boundary wall is any portion of a thermal boundary
    # wall in contact with soil.
    #
    # Source: ANSI/RESNET/ICC 301
    #
    # @return [Array<Double, Double>] Above-grade and below-grade thermal boundary wall areas (ft2)
    def thermal_boundary_wall_areas
      ag_wall_area = 0.0
      bg_wall_area = 0.0

      (@walls + @rim_joists).each do |wall|
        next unless wall.is_thermal_boundary

        ag_wall_area += wall.area
      end

      @foundation_walls.each do |foundation_wall|
        next unless foundation_wall.is_thermal_boundary

        height = foundation_wall.height
        bg_depth = foundation_wall.depth_below_grade
        ag_wall_area += (height - bg_depth) / height * foundation_wall.area
        bg_wall_area += bg_depth / height * foundation_wall.area
      end

      return ag_wall_area, bg_wall_area
    end

    # Estimates the above-grade conditioned volume.
    #
    # @return [Double] Above-grade conditioned volume (ft3)
    def above_grade_conditioned_volume
      ag_cond_vol = @building_construction.conditioned_building_volume

      # Subtract below grade conditioned volume
      HPXML::conditioned_below_grade_locations.each do |location|
        adj_fnd_walls = @foundation_walls.select { |fw| fw.is_exterior && fw.interior_adjacent_to == location }

        floor_area = @slabs.select { |s| s.interior_adjacent_to == location }.map { |s| s.area }.sum
        next if floor_area <= 0

        # Calculate weighted-average (by length) below-grade depth
        avg_depth_bg = adj_fnd_walls.map { |fw| fw.depth_below_grade * (fw.area / fw.height) }.sum(0.0) / adj_fnd_walls.map { |fw| fw.area / fw.height }.sum

        ag_cond_vol -= avg_depth_bg * floor_area
      end

      return ag_cond_vol
    end

    # Calculates common wall area. Used to calculate the window area in the ERI Reference Home.
    #
    # Source: ANSI/RESNET/ICC 301
    #
    # Common wall is the total wall area of walls adjacent to other unit's
    # conditioned space, not including foundation walls.
    #
    # @return [Double] Common wall area (ft2)
    def common_wall_area
      area = 0.0
      (@walls + @rim_joists).each do |wall|
        next unless HPXML::conditioned_locations_this_unit.include? wall.interior_adjacent_to

        if wall.exterior_adjacent_to == HPXML::LocationOtherHousingUnit
          area += wall.area
        elsif wall.exterior_adjacent_to == wall.interior_adjacent_to
          area += wall.area
        end
      end
      return area
    end

    # Deletes any adiabatic sub-surfaces since EnergyPlus does not allow it.
    #
    # @return [nil]
    def delete_adiabatic_subsurfaces
      @doors.reverse_each do |door|
        next if door.wall.nil?
        next if door.wall.exterior_adjacent_to != HPXML::LocationOtherHousingUnit

        door.delete
      end
      @windows.reverse_each do |window|
        next if window.wall.nil?
        next if window.wall.exterior_adjacent_to != HPXML::LocationOtherHousingUnit

        window.delete
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    # It's preferred to check for errors in the validators, but that is not always
    # easy or possible, so additional checking occurs here.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []

      errors += HPXML::check_dates('Daylight Saving', @dst_begin_month, @dst_begin_day, @dst_end_month, @dst_end_day)

      # ------------------------------- #
      # Check for errors within objects #
      # ------------------------------- #

      # Ask objects to check for errors
      self.class::CLASS_ATTRS.each do |attribute|
        hpxml_obj = send(attribute)
        if not hpxml_obj.respond_to? :check_for_errors
          fail "Need to add 'check_for_errors' method to #{hpxml_obj.class} class."
        end

        errors += hpxml_obj.check_for_errors
      end

      # ------------------------------- #
      # Check for errors across objects #
      # ------------------------------- #

      # Check for HVAC systems referenced by multiple water heating systems
      hvac_systems.each do |hvac_system|
        num_attached = 0
        @water_heating_systems.each do |water_heating_system|
          next if water_heating_system.related_hvac_idref.nil?
          next unless hvac_system.id == water_heating_system.related_hvac_idref

          num_attached += 1
        end
        next if num_attached <= 1

        errors << "RelatedHVACSystem '#{hvac_system.id}' is attached to multiple water heating systems."
      end

      # Check for HVAC systems on the same distribution system that are attached to different zones
      @hvac_distributions.each do |hvac_distribution|
        zone_ids = []
        hvac_distribution.hvac_systems.each do |hvac_system|
          next if hvac_system.attached_to_zone_idref.nil?

          zone_ids << hvac_system.attached_to_zone_idref
        end
        if zone_ids.uniq.size > 1
          errors << "HVAC distribution system '#{hvac_distribution.id}' has HVAC systems attached to different zones."
        end
      end

      # Check for the sum of CFA served by distribution systems <= CFA
      if not @building_construction.conditioned_floor_area.nil?
        air_distributions = @hvac_distributions.select { |dist| dist if HPXML::HVACDistributionTypeAir == dist.distribution_system_type }
        heating_dist = []
        cooling_dist = []
        air_distributions.each do |dist|
          heating_systems = dist.hvac_systems.select { |sys| sys if (sys.respond_to? :fraction_heat_load_served) && (sys.fraction_heat_load_served.to_f > 0) }
          cooling_systems = dist.hvac_systems.select { |sys| sys if (sys.respond_to? :fraction_cool_load_served) && (sys.fraction_cool_load_served.to_f > 0) }
          if heating_systems.size > 0
            heating_dist << dist
          end
          if cooling_systems.size > 0
            cooling_dist << dist
          end
        end
        heating_total_dist_cfa_served = heating_dist.map { |htg_dist| htg_dist.conditioned_floor_area_served.to_f }.sum(0.0)
        cooling_total_dist_cfa_served = cooling_dist.map { |clg_dist| clg_dist.conditioned_floor_area_served.to_f }.sum(0.0)
        if (heating_total_dist_cfa_served > @building_construction.conditioned_floor_area + 1.0) # Allow 1 ft2 of tolerance
          errors << 'The total conditioned floor area served by the HVAC distribution system(s) for heating is larger than the conditioned floor area of the building.'
        end
        if (cooling_total_dist_cfa_served > @building_construction.conditioned_floor_area + 1.0) # Allow 1 ft2 of tolerance
          errors << 'The total conditioned floor area served by the HVAC distribution system(s) for cooling is larger than the conditioned floor area of the building.'
        end
      end

      # Check for correct PrimaryIndicator values across all refrigerators
      if @refrigerators.size > 1
        primary_indicators = @refrigerators.count { |r| r.primary_indicator }
        if primary_indicators > 1
          errors << 'More than one refrigerator designated as the primary.'
        elsif primary_indicators == 0
          errors << 'Could not find a primary refrigerator.'
        end
      end

      # Check for correct PrimaryHeatingSystem values across all HVAC systems
      n_primary_heating = @heating_systems.count { |h| h.primary_system } +
                          @heat_pumps.count { |h| h.primary_heating_system }
      if n_primary_heating > 1
        errors << 'More than one heating system designated as the primary.'
      end

      # Check for correct PrimaryCoolingSystem values across all HVAC systems
      n_primary_cooling = @cooling_systems.count { |c| c.primary_system } +
                          @heat_pumps.count { |c| c.primary_cooling_system }
      if n_primary_cooling > 1
        errors << 'More than one cooling system designated as the primary.'
      end

      # Check for at most 1 shared heating system and 1 shared cooling system
      num_htg_shared = 0
      num_clg_shared = 0
      (@heating_systems + @heat_pumps).each do |hvac_system|
        next unless hvac_system.is_shared_system

        num_htg_shared += 1
      end
      (@cooling_systems + @heat_pumps).each do |hvac_system|
        next unless hvac_system.is_shared_system

        num_clg_shared += 1
      end
      if num_htg_shared > 1
        errors << 'More than one shared heating system found.'
      end
      if num_clg_shared > 1
        errors << 'More than one shared cooling system found.'
      end

      return errors
    end

    # Collapses like surfaces into a single surface with, e.g., aggregate surface area.
    # This can significantly speed up performance for HPXML files with lots of individual
    # surfaces (e.g., windows).
    #
    # @param surf_types_of_interest [Array<Symbol>] Subset of surface types (e.g., :roofs, :walls, etc.) to collapse
    # @return [nil]
    def collapse_enclosure_surfaces(surf_types_of_interest = nil)
      surf_types = { roofs: @roofs,
                     walls: @walls,
                     rim_joists: @rim_joists,
                     foundation_walls: @foundation_walls,
                     floors: @floors,
                     slabs: @slabs,
                     windows: @windows,
                     skylights: @skylights,
                     doors: @doors }

      attrs_to_ignore = [:id,
                         :insulation_id,
                         :perimeter_insulation_id,
                         :exterior_horizontal_insulation_id,
                         :under_slab_insulation_id,
                         :area,
                         :length,
                         :exposed_perimeter,
                         :interior_shading_id,
                         :exterior_shading_id,
                         :attached_to_space_idref]

      # Look for pairs of surfaces that can be collapsed
      like_foundation_walls = {}
      surf_types.each do |surf_type, surfaces|
        next unless surf_types_of_interest.nil? || surf_types_of_interest.include?(surf_type)

        for i in 0..surfaces.size - 1
          surf = surfaces[i]
          next if surf.nil?

          for j in (surfaces.size - 1).downto(i + 1)
            surf2 = surfaces[j]
            next if surf2.nil?

            match = true
            surf.class::ATTRS.each do |attribute|
              next if attribute.to_s.end_with? '_isdefaulted'
              next if attrs_to_ignore.include? attribute
              next if (surf_type == :foundation_walls) && ([:azimuth, :orientation].include? attribute) # Azimuth of foundation walls is irrelevant
              next if (surf_type == :foundation_walls) && (attribute == :depth_below_grade) # Ignore BG depth difference; we will later calculate an effective BG depth for the combined surface
              next if surf.send(attribute) == surf2.send(attribute)

              match = false
              break
            end
            next unless match

            if (surf_type == :foundation_walls) && (surf.depth_below_grade != surf2.depth_below_grade)
              if like_foundation_walls[surf].nil?
                like_foundation_walls[surf] = [{ bgdepth: surf.depth_below_grade, length: surf.area / surf.height }]
              end
              like_foundation_walls[surf] << { bgdepth: surf2.depth_below_grade, length: surf2.area / surf2.height }
            end

            # Update values
            if (not surf.area.nil?) && (not surf2.area.nil?)
              surf.area += surf2.area
            end
            if (surf_type == :slabs) && (not surf.exposed_perimeter.nil?) && (not surf2.exposed_perimeter.nil?)
              surf.exposed_perimeter += surf2.exposed_perimeter
            end
            if (surf_type == :foundation_walls) && (not surf.length.nil?) && (not surf2.length.nil?)
              surf.length += surf2.length
            end

            # Update subsurface idrefs as appropriate
            (@windows + @doors).each do |subsurf|
              next unless subsurf.attached_to_wall_idref == surf2.id

              subsurf.attached_to_wall_idref = surf.id
            end
            @skylights.each do |subsurf|
              next unless subsurf.attached_to_roof_idref == surf2.id

              subsurf.attached_to_roof_idref = surf.id
            end
            @skylights.each do |subsurf|
              next unless subsurf.attached_to_floor_idref == surf2.id

              subsurf.attached_to_floor_idref = surf.id
            end

            # Remove old surface
            surfaces[j].delete
          end
        end
      end

      like_foundation_walls.each do |foundation_wall, properties|
        # Calculate weighted-average (by length) below-grade depth
        foundation_wall.depth_below_grade = properties.map { |p| p[:bgdepth] * p[:length] }.sum(0.0) / properties.map { |p| p[:length] }.sum
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/BuildingSummary/Site.
  class Site < BaseElement
    ATTRS = [:site_type,                    # [String] SiteType (HPXML::SiteTypeXXX)
             :surroundings,                 # [String] Surroundings (HPXML::SurroundingsXXX)
             :vertical_surroundings,        # [String] VerticalSurroundings (HPXML::VerticalSurroundingsXXX)
             :shielding_of_home,            # [String] ShieldingofHome (HPXML::ShieldingXXX)
             :orientation_of_front_of_home, # [String] OrientationOfFrontOfHome (HPXML::OrientationXXX)
             :azimuth_of_front_of_home,     # [Integer] AzimuthOfFrontOfHome (deg)
             :available_fuels,              # [Array<String>] FuelTypesAvailable/Fuel (HPXML::FuelTypeXXX)
             :soil_type,                    # [String] Soil/SoilType (HPXML::SiteSoilTypeXXX)
             :moisture_type,                # [String] Soil/MoistureType (HPXML::SiteSoilMoistureTypeXXX)
             :ground_conductivity,          # [Double] Soil/Conductivity (Btu/hr-ft-F)
             :ground_diffusivity]           # [Double] Soil/extension/Diffusivity (ft2/hr)
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      site = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'Site'])
      XMLHelper.add_element(site, 'SiteType', @site_type, :string, @site_type_isdefaulted) unless @site_type.nil?
      XMLHelper.add_element(site, 'Surroundings', @surroundings, :string) unless @surroundings.nil?
      XMLHelper.add_element(site, 'VerticalSurroundings', @vertical_surroundings, :string) unless @vertical_surroundings.nil?
      XMLHelper.add_element(site, 'ShieldingofHome', @shielding_of_home, :string, @shielding_of_home_isdefaulted) unless @shielding_of_home.nil?
      XMLHelper.add_element(site, 'OrientationOfFrontOfHome', @orientation_of_front_of_home, :string) unless @orientation_of_front_of_home.nil?
      XMLHelper.add_element(site, 'AzimuthOfFrontOfHome', @azimuth_of_front_of_home, :integer) unless @azimuth_of_front_of_home.nil?
      if (not @available_fuels.nil?) && (not @available_fuels.empty?)
        fuel_types_available = XMLHelper.add_element(site, 'FuelTypesAvailable')
        @available_fuels.each do |fuel|
          XMLHelper.add_element(fuel_types_available, 'Fuel', fuel, :string)
        end
      end
      if (not @soil_type.nil?) || (not @moisture_type.nil?) || (not @ground_conductivity.nil?) || (not @ground_diffusivity.nil?)
        soil = XMLHelper.add_element(site, 'Soil')
        XMLHelper.add_element(soil, 'SoilType', @soil_type, :string, @soil_type_isdefaulted) unless @soil_type.nil?
        XMLHelper.add_element(soil, 'MoistureType', @moisture_type, :string, @moisture_type_isdefaulted) unless @moisture_type.nil?
        XMLHelper.add_element(soil, 'Conductivity', @ground_conductivity, :float, @ground_conductivity_isdefaulted) unless @ground_conductivity.nil?
        if not @ground_diffusivity.nil?
          extension = XMLHelper.create_elements_as_needed(soil, ['extension'])
          XMLHelper.add_element(extension, 'Diffusivity', @ground_diffusivity, :float, @ground_diffusivity_isdefaulted) unless @ground_diffusivity.nil?
        end
      end

      if site.children.size == 0
        bldg_summary = XMLHelper.get_element(building, 'BuildingDetails/BuildingSummary')
        XMLHelper.delete_element(bldg_summary, 'Site')
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      site = XMLHelper.get_element(building, 'BuildingDetails/BuildingSummary/Site')
      return if site.nil?

      @site_type = XMLHelper.get_value(site, 'SiteType', :string)
      @surroundings = XMLHelper.get_value(site, 'Surroundings', :string)
      @vertical_surroundings = XMLHelper.get_value(site, 'VerticalSurroundings', :string)
      @shielding_of_home = XMLHelper.get_value(site, 'ShieldingofHome', :string)
      @orientation_of_front_of_home = XMLHelper.get_value(site, 'OrientationOfFrontOfHome', :string)
      @azimuth_of_front_of_home = XMLHelper.get_value(site, 'AzimuthOfFrontOfHome', :integer)
      @available_fuels = XMLHelper.get_values(site, 'FuelTypesAvailable/Fuel', :string)
      @soil_type = XMLHelper.get_value(site, 'Soil/SoilType', :string)
      @moisture_type = XMLHelper.get_value(site, 'Soil/MoistureType', :string)
      @ground_conductivity = XMLHelper.get_value(site, 'Soil/Conductivity', :float)
      @ground_diffusivity = XMLHelper.get_value(site, 'Soil/extension/Diffusivity', :float)
    end
  end

  # Array of HPXML::NeighborBuilding objects.
  class NeighborBuildings < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << NeighborBuilding.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/BuildingSummary/Site/extension/Neighbors/NeighborBuilding').each do |neighbor_building|
        self << NeighborBuilding.new(@parent_object, neighbor_building)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/BuildingSummary/Site/extension/Neighbors/NeighborBuilding.
  class NeighborBuilding < BaseElement
    ATTRS = [:orientation, # [String] Orientation (HPXML::OrientationXXX)
             :azimuth,     # [Integer] Azimuth (deg)
             :distance,    # [Double] Distance (ft)
             :height]      # [Double] Height (ft)
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.neighbor_buildings.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      neighbors = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'Site', 'extension', 'Neighbors'])
      neighbor_building = XMLHelper.add_element(neighbors, 'NeighborBuilding')
      XMLHelper.add_element(neighbor_building, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      XMLHelper.add_element(neighbor_building, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(neighbor_building, 'Distance', @distance, :float) unless @distance.nil?
      XMLHelper.add_element(neighbor_building, 'Height', @height, :float) unless @height.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param neighbor_building [Oga::XML::Element] The current NeighborBuilding XML element
    # @return [nil]
    def from_doc(neighbor_building)
      return if neighbor_building.nil?

      @orientation = XMLHelper.get_value(neighbor_building, 'Orientation', :string)
      @azimuth = XMLHelper.get_value(neighbor_building, 'Azimuth', :integer)
      @distance = XMLHelper.get_value(neighbor_building, 'Distance', :float)
      @height = XMLHelper.get_value(neighbor_building, 'Height', :float)
    end
  end

  # Object for /HPXML/Building/BuildingDetails/BuildingSummary/BuildingOccupancy.
  class BuildingOccupancy < BaseElement
    ATTRS = [:number_of_residents,                   # [Double] NumberofResidents
             :weekday_fractions,                     # [String] extension/WeekdayScheduleFractions
             :weekend_fractions,                     # [String] extension/WeekendScheduleFractions
             :monthly_multipliers,                   # [String] extension/MonthlyScheduleMultipliers
             :general_water_use_usage_multiplier,    # [Double] extension/GeneralWaterUseUsageMultiplier
             :general_water_use_weekday_fractions,   # [String] extension/GeneralWaterUseWeekdayScheduleFractions
             :general_water_use_weekend_fractions,   # [String] extension/GeneralWaterUseWeekendScheduleFractions
             :general_water_use_monthly_multipliers] # [String] extension/GeneralWaterUseMonthlyScheduleMultipliers
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      building_occupancy = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'BuildingOccupancy'])
      XMLHelper.add_element(building_occupancy, 'NumberofResidents', @number_of_residents, :float, @number_of_residents_isdefaulted) unless @number_of_residents.nil?
      XMLHelper.add_extension(building_occupancy, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(building_occupancy, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(building_occupancy, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
      XMLHelper.add_extension(building_occupancy, 'GeneralWaterUseUsageMultiplier', @general_water_use_usage_multiplier, :float, @general_water_use_usage_multiplier_isdefaulted) unless @general_water_use_usage_multiplier.nil?
      XMLHelper.add_extension(building_occupancy, 'GeneralWaterUseWeekdayScheduleFractions', @general_water_use_weekday_fractions, :string, @general_water_use_weekday_fractions_isdefaulted) unless @general_water_use_weekday_fractions.nil?
      XMLHelper.add_extension(building_occupancy, 'GeneralWaterUseWeekendScheduleFractions', @general_water_use_weekend_fractions, :string, @general_water_use_weekend_fractions_isdefaulted) unless @general_water_use_weekend_fractions.nil?
      XMLHelper.add_extension(building_occupancy, 'GeneralWaterUseMonthlyScheduleMultipliers', @general_water_use_monthly_multipliers, :string, @general_water_use_monthly_multipliers_isdefaulted) unless @general_water_use_monthly_multipliers.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      building_occupancy = XMLHelper.get_element(building, 'BuildingDetails/BuildingSummary/BuildingOccupancy')
      return if building_occupancy.nil?

      @number_of_residents = XMLHelper.get_value(building_occupancy, 'NumberofResidents', :float)
      @weekday_fractions = XMLHelper.get_value(building_occupancy, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(building_occupancy, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(building_occupancy, 'extension/MonthlyScheduleMultipliers', :string)
      @general_water_use_usage_multiplier = XMLHelper.get_value(building_occupancy, 'extension/GeneralWaterUseUsageMultiplier', :float)
      @general_water_use_weekday_fractions = XMLHelper.get_value(building_occupancy, 'extension/GeneralWaterUseWeekdayScheduleFractions', :string)
      @general_water_use_weekend_fractions = XMLHelper.get_value(building_occupancy, 'extension/GeneralWaterUseWeekendScheduleFractions', :string)
      @general_water_use_monthly_multipliers = XMLHelper.get_value(building_occupancy, 'extension/GeneralWaterUseMonthlyScheduleMultipliers', :string)
    end
  end

  # Object for /HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction.
  class BuildingConstruction < BaseElement
    ATTRS = [:year_built,                               # [Integer] YearBuilt
             :residential_facility_type,                # [String] ResidentialFacilityType (HXPML::ResidentialTypeXXX)
             :unit_height_above_grade,                  # [Double] UnitHeightAboveGrade
             :number_of_units,                          # [Integer] NumberofUnits
             :number_of_units_in_building,              # [Integer] NumberofUnitsInBuilding
             :number_of_conditioned_floors,             # [Double] NumberofConditionedFloors
             :number_of_conditioned_floors_above_grade, # [Double] NumberofConditionedFloorsAboveGrade
             :average_ceiling_height,                   # [Double] AverageCeilingHeight (ft)
             :number_of_bedrooms,                       # [Integer] NumberofBedrooms
             :number_of_bathrooms,                      # [Integer] NumberofBathrooms
             :building_footprint_area,                  # [Double] BuildingFootprintArea (ft2)
             :conditioned_floor_area,                   # [Double] ConditionedFloorArea (ft2)
             :conditioned_building_volume,              # [Double] ConditionedBuildingVolume (ft3)
             :manufactured_home_sections]               # [String] ManufacturedHomeSections
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      building_construction = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'BuildingConstruction'])
      XMLHelper.add_element(building_construction, 'YearBuilt', @year_built, :integer) unless @year_built.nil?
      XMLHelper.add_element(building_construction, 'ResidentialFacilityType', @residential_facility_type, :string) unless @residential_facility_type.nil?
      XMLHelper.add_element(building_construction, 'UnitHeightAboveGrade', @unit_height_above_grade, :float, @unit_height_above_grade_isdefaulted) unless @unit_height_above_grade.nil?
      XMLHelper.add_element(building_construction, 'NumberofUnits', @number_of_units, :integer, @number_of_units_isdefaulted) unless @number_of_units.nil?
      XMLHelper.add_element(building_construction, 'NumberofUnitsInBuilding', @number_of_units_in_building, :integer) unless @number_of_units_in_building.nil?
      XMLHelper.add_element(building_construction, 'NumberofConditionedFloors', @number_of_conditioned_floors, :float) unless @number_of_conditioned_floors.nil?
      XMLHelper.add_element(building_construction, 'NumberofConditionedFloorsAboveGrade', @number_of_conditioned_floors_above_grade, :float) unless @number_of_conditioned_floors_above_grade.nil?
      XMLHelper.add_element(building_construction, 'AverageCeilingHeight', @average_ceiling_height, :float, @average_ceiling_height_isdefaulted) unless @average_ceiling_height.nil?
      XMLHelper.add_element(building_construction, 'NumberofBedrooms', @number_of_bedrooms, :integer) unless @number_of_bedrooms.nil?
      XMLHelper.add_element(building_construction, 'NumberofBathrooms', @number_of_bathrooms, :integer, @number_of_bathrooms_isdefaulted) unless @number_of_bathrooms.nil?
      XMLHelper.add_element(building_construction, 'BuildingFootprintArea', @building_footprint_area, :float, @building_footprint_area_isdefaulted) unless @building_footprint_area.nil?
      XMLHelper.add_element(building_construction, 'ConditionedFloorArea', @conditioned_floor_area, :float) unless @conditioned_floor_area.nil?
      XMLHelper.add_element(building_construction, 'ConditionedBuildingVolume', @conditioned_building_volume, :float, @conditioned_building_volume_isdefaulted) unless @conditioned_building_volume.nil?
      XMLHelper.add_element(building_construction, 'ManufacturedHomeSections', @manufactured_home_sections, :string) unless @manufactured_home_sections.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      building_construction = XMLHelper.get_element(building, 'BuildingDetails/BuildingSummary/BuildingConstruction')
      return if building_construction.nil?

      @year_built = XMLHelper.get_value(building_construction, 'YearBuilt', :integer)
      @residential_facility_type = XMLHelper.get_value(building_construction, 'ResidentialFacilityType', :string)
      @unit_height_above_grade = XMLHelper.get_value(building_construction, 'UnitHeightAboveGrade', :float)
      @number_of_units = XMLHelper.get_value(building_construction, 'NumberofUnits', :integer)
      @number_of_units_in_building = XMLHelper.get_value(building_construction, 'NumberofUnitsInBuilding', :integer)
      @number_of_conditioned_floors = XMLHelper.get_value(building_construction, 'NumberofConditionedFloors', :float)
      @number_of_conditioned_floors_above_grade = XMLHelper.get_value(building_construction, 'NumberofConditionedFloorsAboveGrade', :float)
      @average_ceiling_height = XMLHelper.get_value(building_construction, 'AverageCeilingHeight', :float)
      @number_of_bedrooms = XMLHelper.get_value(building_construction, 'NumberofBedrooms', :integer)
      @number_of_bathrooms = XMLHelper.get_value(building_construction, 'NumberofBathrooms', :integer)
      @building_footprint_area = XMLHelper.get_value(building_construction, 'BuildingFootprintArea', :float)
      @conditioned_floor_area = XMLHelper.get_value(building_construction, 'ConditionedFloorArea', :float)
      @conditioned_building_volume = XMLHelper.get_value(building_construction, 'ConditionedBuildingVolume', :float)
      @manufactured_home_sections = XMLHelper.get_value(building_construction, 'ManufacturedHomeSections', :string)
    end
  end

  # Object for high-level Building-specific information in /HPXML/Building/BuildingDetails/BuildingSummary/extension.
  class BuildingHeader < BaseElement
    ATTRS = [:heat_pump_sizing_methodology,         # [String] HVACSizingControl/HeatPumpSizingMethodology (HPXML::HeatPumpSizingXXX)
             :heat_pump_backup_sizing_methodology,  # [String] HVACSizingControl/HeatPumpBackupSizingMethodology (HPXML::HeatPumpBackupSizingXXX)
             :allow_increased_fixed_capacities,     # [Boolean] HVACSizingControl/AllowIncreasedFixedCapacities
             :manualj_heating_design_temp,          # [Double] HVACSizingControl/ManualJInputs/HeatingDesignTemperature (F)
             :manualj_cooling_design_temp,          # [Double] HVACSizingControl/ManualJInputs/CoolingDesignTemperature (F)
             :manualj_daily_temp_range,             # [String] HVACSizingControl/ManualJInputs/DailyTemperatureRange (HPXML::ManualJDailyTempRangeXXX)
             :manualj_heating_setpoint,             # [Double] HVACSizingControl/ManualJInputs/HeatingSetpoint (F)
             :manualj_cooling_setpoint,             # [Double] HVACSizingControl/ManualJInputs/CoolingSetpoint (F)
             :manualj_humidity_setpoint,            # [Double] HVACSizingControl/ManualJInputs/HumiditySetpoint (frac)
             :manualj_humidity_difference,          # [Double] HVACSizingControl/ManualJInputs/HumidityDifference (grains)
             :manualj_internal_loads_sensible,      # [Double] HVACSizingControl/ManualJInputs/InternalLoadsSensible (Btu/hr)
             :manualj_internal_loads_latent,        # [Double] HVACSizingControl/ManualJInputs/InternalLoadsLatent (Btu/hr)
             :manualj_num_occupants,                # [Double] HVACSizingControl/ManualJInputs/NumberofOccupants
             :manualj_infiltration_shielding_class, # [Integer] HVACSizingControl/ManualJInputs/InfiltrationShieldingClass (1-5)
             :manualj_infiltration_method,          # [String] HVACSizingControl/ManualJInputs/InfiltrationMethod (HPXML::ManualJInfiltrationMethodXXX)
             :natvent_days_per_week,                # [Integer] NaturalVentilationAvailabilityDaysperWeek
             :schedules_filepaths,                  # [Array<String>] SchedulesFilePath
             :shading_summer_begin_month,           # [Integer] ShadingControl/SummerBeginMonth
             :shading_summer_begin_day,             # [Integer] ShadingControl/SummerBeginDayOfMonth
             :shading_summer_end_month,             # [Integer] ShadingControl/SummerEndMonth
             :shading_summer_end_day,               # [Integer] ShadingControl/SummerEndDayOfMonth
             :electric_panel_baseline_peak_power,   # [Double] ElectricPanelBaselinePeakPower
             :extension_properties]                 # [Hash] AdditionalProperties
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      errors += HPXML::check_dates('Shading Summer Season', @shading_summer_begin_month, @shading_summer_begin_day, @shading_summer_end_month, @shading_summer_end_day)
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      building_summary = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary'])
      if (not @heat_pump_sizing_methodology.nil?) || (not @allow_increased_fixed_capacities.nil?) || (not @heat_pump_backup_sizing_methodology.nil?)
        hvac_sizing_control = XMLHelper.create_elements_as_needed(building_summary, ['extension', 'HVACSizingControl'])
        XMLHelper.add_element(hvac_sizing_control, 'HeatPumpSizingMethodology', @heat_pump_sizing_methodology, :string, @heat_pump_sizing_methodology_isdefaulted) unless @heat_pump_sizing_methodology.nil?
        XMLHelper.add_element(hvac_sizing_control, 'HeatPumpBackupSizingMethodology', @heat_pump_backup_sizing_methodology, :string, @heat_pump_backup_sizing_methodology_isdefaulted) unless @heat_pump_backup_sizing_methodology.nil?
        XMLHelper.add_element(hvac_sizing_control, 'AllowIncreasedFixedCapacities', @allow_increased_fixed_capacities, :boolean, @allow_increased_fixed_capacities_isdefaulted) unless @allow_increased_fixed_capacities.nil?
      end
      if (not @manualj_heating_design_temp.nil?) || (not @manualj_cooling_design_temp.nil?) || (not @manualj_daily_temp_range.nil?) || (not @manualj_humidity_difference.nil?) || (not @manualj_heating_setpoint.nil?) || (not @manualj_cooling_setpoint.nil?) || (not @manualj_humidity_setpoint.nil?) || (not @manualj_internal_loads_sensible.nil?) || (not @manualj_internal_loads_latent.nil?) || (not @manualj_num_occupants.nil?) || (not @manualj_infiltration_shielding_class.nil?) || (not @manualj_infiltration_method.nil?)
        manualj_sizing_inputs = XMLHelper.create_elements_as_needed(building_summary, ['extension', 'HVACSizingControl', 'ManualJInputs'])
        XMLHelper.add_element(manualj_sizing_inputs, 'HeatingDesignTemperature', @manualj_heating_design_temp, :float, @manualj_heating_design_temp_isdefaulted) unless @manualj_heating_design_temp.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'CoolingDesignTemperature', @manualj_cooling_design_temp, :float, @manualj_cooling_design_temp_isdefaulted) unless @manualj_cooling_design_temp.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'DailyTemperatureRange', @manualj_daily_temp_range, :string, @manualj_daily_temp_range_isdefaulted) unless @manualj_daily_temp_range.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'HeatingSetpoint', @manualj_heating_setpoint, :float, @manualj_heating_setpoint_isdefaulted) unless @manualj_heating_setpoint.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'CoolingSetpoint', @manualj_cooling_setpoint, :float, @manualj_cooling_setpoint_isdefaulted) unless @manualj_cooling_setpoint.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'HumiditySetpoint', @manualj_humidity_setpoint, :float, @manualj_humidity_setpoint_isdefaulted) unless @manualj_humidity_setpoint.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'HumidityDifference', @manualj_humidity_difference, :float, @manualj_humidity_difference_isdefaulted) unless @manualj_humidity_difference.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'InternalLoadsSensible', @manualj_internal_loads_sensible, :float, @manualj_internal_loads_sensible_isdefaulted) unless @manualj_internal_loads_sensible.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'InternalLoadsLatent', @manualj_internal_loads_latent, :float, @manualj_internal_loads_latent_isdefaulted) unless @manualj_internal_loads_latent.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'NumberofOccupants', @manualj_num_occupants, :float, @manualj_num_occupants_isdefaulted) unless @manualj_num_occupants.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'InfiltrationShieldingClass', @manualj_infiltration_shielding_class, :integer, @manualj_infiltration_shielding_class_isdefaulted) unless @manualj_infiltration_shielding_class.nil?
        XMLHelper.add_element(manualj_sizing_inputs, 'InfiltrationMethod', @manualj_infiltration_method, :string, @manualj_infiltration_method_isdefaulted) unless @manualj_infiltration_method.nil?
      end
      XMLHelper.add_extension(building_summary, 'NaturalVentilationAvailabilityDaysperWeek', @natvent_days_per_week, :integer, @natvent_days_per_week_isdefaulted) unless @natvent_days_per_week.nil?
      if (not @schedules_filepaths.nil?) && (not @schedules_filepaths.empty?)
        @schedules_filepaths.each do |schedules_filepath|
          XMLHelper.add_extension(building_summary, 'SchedulesFilePath', schedules_filepath, :string)
        end
      end
      if (not @shading_summer_begin_month.nil?) || (not @shading_summer_begin_day.nil?) || (not @shading_summer_end_month.nil?) || (not @shading_summer_end_day.nil?)
        window_shading_season = XMLHelper.create_elements_as_needed(building_summary, ['extension', 'ShadingControl'])
        XMLHelper.add_element(window_shading_season, 'SummerBeginMonth', @shading_summer_begin_month, :integer, @shading_summer_begin_month_isdefaulted) unless @shading_summer_begin_month.nil?
        XMLHelper.add_element(window_shading_season, 'SummerBeginDayOfMonth', @shading_summer_begin_day, :integer, @shading_summer_begin_day_isdefaulted) unless @shading_summer_begin_day.nil?
        XMLHelper.add_element(window_shading_season, 'SummerEndMonth', @shading_summer_end_month, :integer, @shading_summer_end_month_isdefaulted) unless @shading_summer_end_month.nil?
        XMLHelper.add_element(window_shading_season, 'SummerEndDayOfMonth', @shading_summer_end_day, :integer, @shading_summer_end_day_isdefaulted) unless @shading_summer_end_day.nil?
      end
      if not @electric_panel_baseline_peak_power.nil?
        XMLHelper.add_extension(building_summary, 'ElectricPanelBaselinePeakPower', @electric_panel_baseline_peak_power, :float)
      end
      if (not @extension_properties.nil?) && (not @extension_properties.empty?)
        properties = XMLHelper.create_elements_as_needed(building_summary, ['extension', 'AdditionalProperties'])
        @extension_properties.each do |key, value|
          XMLHelper.add_element(properties, key, value, :string)
        end
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      building_summary = XMLHelper.get_element(building, 'BuildingDetails/BuildingSummary')
      return if building_summary.nil?

      @schedules_filepaths = XMLHelper.get_values(building_summary, 'extension/SchedulesFilePath', :string)
      @natvent_days_per_week = XMLHelper.get_value(building_summary, 'extension/NaturalVentilationAvailabilityDaysperWeek', :integer)
      @shading_summer_begin_month = XMLHelper.get_value(building_summary, 'extension/ShadingControl/SummerBeginMonth', :integer)
      @shading_summer_begin_day = XMLHelper.get_value(building_summary, 'extension/ShadingControl/SummerBeginDayOfMonth', :integer)
      @shading_summer_end_month = XMLHelper.get_value(building_summary, 'extension/ShadingControl/SummerEndMonth', :integer)
      @shading_summer_end_day = XMLHelper.get_value(building_summary, 'extension/ShadingControl/SummerEndDayOfMonth', :integer)
      @heat_pump_sizing_methodology = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/HeatPumpSizingMethodology', :string)
      @heat_pump_backup_sizing_methodology = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/HeatPumpBackupSizingMethodology', :string)
      @allow_increased_fixed_capacities = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/AllowIncreasedFixedCapacities', :boolean)
      @manualj_heating_design_temp = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/ManualJInputs/HeatingDesignTemperature', :float)
      @manualj_cooling_design_temp = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/ManualJInputs/CoolingDesignTemperature', :float)
      @manualj_daily_temp_range = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/ManualJInputs/DailyTemperatureRange', :string)
      @manualj_heating_setpoint = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/ManualJInputs/HeatingSetpoint', :float)
      @manualj_cooling_setpoint = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/ManualJInputs/CoolingSetpoint', :float)
      @manualj_humidity_setpoint = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/ManualJInputs/HumiditySetpoint', :float)
      @manualj_humidity_difference = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/ManualJInputs/HumidityDifference', :float)
      @manualj_internal_loads_sensible = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/ManualJInputs/InternalLoadsSensible', :float)
      @manualj_internal_loads_latent = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/ManualJInputs/InternalLoadsLatent', :float)
      @manualj_num_occupants = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/ManualJInputs/NumberofOccupants', :float)
      @manualj_infiltration_shielding_class = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/ManualJInputs/InfiltrationShieldingClass', :integer)
      @manualj_infiltration_method = XMLHelper.get_value(building_summary, 'extension/HVACSizingControl/ManualJInputs/InfiltrationMethod', :string)
      @electric_panel_baseline_peak_power = XMLHelper.get_value(building_summary, 'extension/ElectricPanelBaselinePeakPower', :float)
      @extension_properties = {}
      XMLHelper.get_elements(building_summary, 'extension/AdditionalProperties').each do |property|
        property.children.each do |child|
          next unless child.is_a? Oga::XML::Element

          @extension_properties[child.name] = child.text
          @extension_properties[child.name] = nil if @extension_properties[child.name].empty?
        end
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/ClimateandRiskZones.
  class ClimateandRiskZones < BaseElement
    def initialize(hpxml_bldg, *args, **kwargs)
      @climate_zone_ieccs = ClimateZoneIECCs.new(hpxml_bldg)
      super(hpxml_bldg, *args, **kwargs)
    end
    CLASS_ATTRS = [:climate_zone_ieccs] # [HPXML::ClimateZoneIECCs]
    ATTRS = [:weather_station_id,           # [String] WeatherStation/SystemIdentifier/@id
             :weather_station_name,         # [String] WeatherStation/Name
             :weather_station_wmo,          # [String] WeatherStation/WMO
             :weather_station_epw_filepath] # [String] WeatherStation/extension/EPWFilePath
    attr_reader(*CLASS_ATTRS)
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      errors += @climate_zone_ieccs.check_for_errors
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      climate_and_risk_zones = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'ClimateandRiskZones'])
      @climate_zone_ieccs.to_doc(climate_and_risk_zones)
      return if nil?

      if not @weather_station_id.nil?
        weather_station = XMLHelper.add_element(climate_and_risk_zones, 'WeatherStation')
        sys_id = XMLHelper.add_element(weather_station, 'SystemIdentifier')
        XMLHelper.add_attribute(sys_id, 'id', @weather_station_id)
        XMLHelper.add_element(weather_station, 'Name', @weather_station_name, :string, @weather_station_name_isdefaulted) unless @weather_station_name.nil?
        XMLHelper.add_element(weather_station, 'WMO', @weather_station_wmo, :string, @weather_station_wmo_isdefaulted) unless @weather_station_wmo.nil?
        XMLHelper.add_extension(weather_station, 'EPWFilePath', @weather_station_epw_filepath, :string, @weather_station_epw_filepath_isdefaulted) unless @weather_station_epw_filepath.nil?
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      climate_and_risk_zones = XMLHelper.get_element(building, 'BuildingDetails/ClimateandRiskZones')
      return if climate_and_risk_zones.nil?

      @climate_zone_ieccs.from_doc(building)

      weather_station = XMLHelper.get_element(climate_and_risk_zones, 'WeatherStation')
      if not weather_station.nil?
        @weather_station_id = HPXML::get_id(weather_station)
        @weather_station_name = XMLHelper.get_value(weather_station, 'Name', :string)
        @weather_station_wmo = XMLHelper.get_value(weather_station, 'WMO', :string)
        @weather_station_epw_filepath = XMLHelper.get_value(weather_station, 'extension/EPWFilePath', :string)
      end
    end
  end

  # Array of HPXML::ClimateZoneIECC objects.
  class ClimateZoneIECCs < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << ClimateZoneIECC.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/ClimateandRiskZones/ClimateZoneIECC').each do |climate_zone_iecc|
        self << ClimateZoneIECC.new(@parent_object, climate_zone_iecc)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC.
  class ClimateZoneIECC < BaseElement
    ATTRS = [:year, # [Integer] Year
             :zone] # [String] ClimateZone
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.climate_and_risk_zones.climate_zone_ieccs.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param climate_and_risk_zones [Oga::XML::Element] Parent XML element
    # @return [nil]
    def to_doc(climate_and_risk_zones)
      climate_zone_iecc = XMLHelper.add_element(climate_and_risk_zones, 'ClimateZoneIECC')
      XMLHelper.add_element(climate_zone_iecc, 'Year', @year, :integer, @year_isdefaulted) unless @year.nil?
      XMLHelper.add_element(climate_zone_iecc, 'ClimateZone', @zone, :string, @zone_isdefaulted) unless @zone.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param climate_and_risk_zones [Oga::XML::Element] The current ClimateZoneIECC XML element
    # @return [nil]
    def from_doc(climate_zone_iecc)
      return if climate_zone_iecc.nil?

      @year = XMLHelper.get_value(climate_zone_iecc, 'Year', :integer)
      @zone = XMLHelper.get_value(climate_zone_iecc, 'ClimateZone', :string)
    end
  end

  # Array of HPXML::Zone objects.
  class Zones < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Zone.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Zones/Zone').each do |zone|
        self << Zone.new(@parent_object, zone)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Zones/Zone.
  class Zone < BaseElement
    def initialize(hpxml_bldg, *args, **kwargs)
      @spaces = Spaces.new(hpxml_bldg)
      super(hpxml_bldg, *args, **kwargs)
    end
    CLASS_ATTRS = [:spaces] # [HPXML::Spaces]
    ATTRS = [:id,          # [String] SystemIdentifier/@id
             :zone_type] + # [String] ZoneType (HPXML::ZoneTypeXXX)
            HDL_ATTRS.keys +
            CDL_SENS_ATTRS.keys +
            CDL_LAT_ATTRS.keys
    attr_accessor(*CLASS_ATTRS)
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      if zone_type == ZoneTypeConditioned
        # Check all surfaces attached to the zone are adjacent to conditioned space
        surfaces.each do |surface|
          next if HPXML::conditioned_locations_this_unit.include? surface.interior_adjacent_to
          next if HPXML::conditioned_locations_this_unit.include? surface.exterior_adjacent_to

          errors << "Surface '#{surface.id}' is not adjacent to conditioned space but was assigned to conditioned Zone '#{@id}'."
        end
      end
      return errors
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      hvac_systems.reverse_each do |hvac_system|
        hvac_system.attached_to_zone_idref = nil
      end
      @parent_object.zones.delete(self)
    end

    # Returns all heating systems for this zone.
    #
    # @return [Array<HPXML::HeatingSystem>] List of heating system objects
    def heating_systems
      return @parent_object.heating_systems.select { |s| s.attached_to_zone_idref == @id }
    end

    # Returns all cooling systems for this zone.
    #
    # @return [Array<HPXML::CoolingSystem>] List of cooling system objects
    def cooling_systems
      return @parent_object.cooling_systems.select { |s| s.attached_to_zone_idref == @id }
    end

    # Returns all heat pumps for this zone.
    #
    # @return [Array<HPXML::HeatPump>] List of heat pump objects
    def heat_pumps
      return @parent_object.heat_pumps.select { |s| s.attached_to_zone_idref == @id }
    end

    # Returns all HVAC systems for this zone.
    #
    # @return [Array<HPXML::XXX>] List of HVAC system objects
    def hvac_systems
      return @parent_object.hvac_systems.select { |s| s.attached_to_zone_idref == @id }
    end

    # Returns all HVAC distributions for this zone.
    #
    # @return [Array<HPXML::HVACDistribution>] List of HVAC distribution objects
    def hvac_distributions
      return hvac_systems.select { |s| !s.distribution_system.nil? }.map { |s| s.distribution_system }.uniq
    end

    # Returns the total floor area for this zone.
    #
    # @return [Double] Zone floor area (ft2)
    def floor_area
      return spaces.map { |space| space.floor_area }.sum
    end

    # Returns all roofs for this zone.
    #
    # @return [Array<HPXML::Roof>] List of roof objects
    def roofs
      return spaces.map { |space| space.roofs }.flatten
    end

    # Returns all rim joists for this zone.
    #
    # @return [Array<HPXML::RimJoist>] List of rim joist objects
    def rim_joists
      return spaces.map { |space| space.rim_joists }.flatten
    end

    # Returns all walls for this zone.
    #
    # @return [Array<HPXML::Wall>] List of wall objects
    def walls
      return spaces.map { |space| space.walls }.flatten
    end

    # Returns all foundation walls for this zone.
    #
    # @return [Array<HPXML::FoundationWall>] List of foundation wall objects
    def foundation_walls
      return spaces.map { |space| space.foundation_walls }.flatten
    end

    # Returns all floors for this zone.
    #
    # @return [Array<HPXML::Floor>] List of floor objects
    def floors
      return spaces.map { |space| space.floors }.flatten
    end

    # Returns all slabs for this zone.
    #
    # @return [Array<HPXML::Slab>] List of slab objects
    def slabs
      return spaces.map { |space| space.slabs }.flatten
    end

    # Returns all windows for this zone.
    #
    # @return [Array<HPXML::Window>] List of window objects
    def windows
      return spaces.map { |space| space.windows }.flatten
    end

    # Returns all doors for this zone.
    #
    # @return [Array<HPXML::Door>] List of door objects
    def doors
      return spaces.map { |space| space.doors }.flatten
    end

    # Returns all skylights for this zone.
    #
    # @return [Array<HPXML::Skylight>] List of skylight objects
    def skylights
      return spaces.map { |space| space.skylights }.flatten
    end

    # Returns all enclosure surfaces for this zone.
    #
    # @return [Array<HPXML::XXX>] List of surface objects
    def surfaces
      return (roofs + rim_joists + walls + foundation_walls + floors + slabs)
    end

    # Returns all HPXML enclosure sub-surfaces for this zone.
    #
    # @return [Array<HPXML::XXX>] List of sub-surface objects
    def subsurfaces
      return (windows + skylights + doors)
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      zones = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Zones'])
      zone = XMLHelper.add_element(zones, 'Zone')
      sys_id = XMLHelper.add_element(zone, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(zone, 'ZoneType', @zone_type, :string) unless @zone_type.nil?
      @spaces.to_doc(zone)
      if (HDL_ATTRS.keys + CDL_SENS_ATTRS.keys + CDL_LAT_ATTRS.keys).map { |key| send(key) }.any?
        HPXML.design_loads_to_doc(self, zone)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param zone [Oga::XML::Element] The current Zone XML element
    # @return [nil]
    def from_doc(zone)
      return if zone.nil?

      @id = HPXML::get_id(zone)
      @zone_type = XMLHelper.get_value(zone, 'ZoneType', :string)
      @spaces.from_doc(zone)
      HPXML.design_loads_from_doc(self, zone)
    end
  end

  # Array of HPXML::Space objects.
  class Spaces < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Space.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param zone [Oga::XML::Element] The current Zone XML element
    # @return [nil]
    def from_doc(zone)
      return if zone.nil?

      XMLHelper.get_elements(zone, 'Spaces/Space').each do |space|
        self << Space.new(@parent_object, space)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Zones/Zone/Spaces/Space.
  class Space < BaseElement
    ATTRS = [:id,                              # [String] SystemIdentifier/@id
             :floor_area,                      # [Double] FloorArea (ft2)
             :manualj_internal_loads_sensible, # [Double] extension/ManualJInputs/InternalLoadsSensible (Btu/hr)
             :manualj_internal_loads_latent,   # [Double] extension/ManualJInputs/InternalLoadsLatent (Btu/hr)
             :manualj_num_occupants,           # [Double] extension/ManualJInputs/NumberofOccupants
             :fenestration_load_procedure] +   # [String] extension/ManualJInputs/FenestrationLoadProcedure (HPXML::SpaceFenestrationLoadProcedureXXX)
            HDL_ATTRS.keys +
            CDL_SENS_ATTRS.keys +
            CDL_LAT_ATTRS.keys
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      surfaces.reverse_each do |surface|
        surface.attached_to_space_idref = nil
      end
      zone.spaces.delete(self)
    end

    # Returns the parent zone.
    #
    # @return [HPXML::Zone] Zone object
    def zone
      return @parent_object.zones.find { |zone| zone.spaces.include? self }
    end

    # Returns all roofs for this space.
    #
    # @return [Array<HPXML::Roof>] List of roof objects
    def roofs
      return @parent_object.roofs.select { |s| s.attached_to_space_idref == @id }
    end

    # Returns all rim joists for this space.
    #
    # @return [Array<HPXML::RimJoist>] List of rim joist objects
    def rim_joists
      return @parent_object.rim_joists.select { |s| s.attached_to_space_idref == @id }
    end

    # Returns all walls for this space.
    #
    # @return [Array<HPXML::Wall>] List of wall objects
    def walls
      return @parent_object.walls.select { |s| s.attached_to_space_idref == @id }
    end

    # Returns all foundation walls for this space.
    #
    # @return [Array<HPXML::FoundationWall>] List of foundation wall objects
    def foundation_walls
      return @parent_object.foundation_walls.select { |s| s.attached_to_space_idref == @id }
    end

    # Returns all floors for this space.
    #
    # @return [Array<HPXML::Floor>] List of floor objects
    def floors
      return @parent_object.floors.select { |s| s.attached_to_space_idref == @id }
    end

    # Returns all slabs for this space.
    #
    # @return [Array<HPXML::Slab>] List of slab objects
    def slabs
      return @parent_object.slabs.select { |s| s.attached_to_space_idref == @id }
    end

    # Returns all windows for this space.
    #
    # @return [Array<HPXML::Window>] List of window objects
    def windows
      return @parent_object.windows.select { |s| s.wall.attached_to_space_idref == @id }
    end

    # Returns all doors for this space.
    #
    # @return [Array<HPXML::Door>] List of door objects
    def doors
      return @parent_object.doors.select { |s| s.wall.attached_to_space_idref == @id }
    end

    # Returns all skylights for this space.
    #
    # @return [Array<HPXML::Skylight>] List of skylight objects
    def skylights
      return @parent_object.skylights.select { |s| s.roof.attached_to_space_idref == @id || ((not s.floor.nil?) && s.floor.attached_to_space_idref == @id) }
    end

    # Returns all enclosure surfaces for this space.
    #
    # @return [Array<HPXML::XXX>] List of surface objects
    def surfaces
      return (roofs + rim_joists + walls + foundation_walls + floors + slabs)
    end

    # Returns all HPXML enclosure sub-surfaces for this space.
    #
    # @return [Array<HPXML::XXX>] List of sub-surface objects
    def subsurfaces
      return (windows + skylights + doors)
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param zone [Oga::XML::Element] Parent XML element
    # @return [nil]
    def to_doc(zone)
      return if nil?

      spaces = XMLHelper.create_elements_as_needed(zone, ['Spaces'])
      space = XMLHelper.add_element(spaces, 'Space')
      sys_id = XMLHelper.add_element(space, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_element(space, 'FloorArea', @floor_area, :float) unless @floor_area.nil?
      if (not @manualj_internal_loads_sensible.nil?) || (not @manualj_internal_loads_latent.nil?) || (not @manualj_num_occupants.nil?) || (not @fenestration_load_procedure.nil?)
        mj_extension = XMLHelper.add_extension(space, 'ManualJInputs')
        XMLHelper.add_element(mj_extension, 'InternalLoadsSensible', @manualj_internal_loads_sensible, :float, @manualj_internal_loads_sensible_isdefaulted) unless @manualj_internal_loads_sensible.nil?
        XMLHelper.add_element(mj_extension, 'InternalLoadsLatent', @manualj_internal_loads_latent, :float, @manualj_internal_loads_latent_isdefaulted) unless @manualj_internal_loads_latent.nil?
        XMLHelper.add_element(mj_extension, 'NumberofOccupants', @manualj_num_occupants, :float, @manualj_num_occupants_isdefaulted) unless @manualj_num_occupants.nil?
        XMLHelper.add_element(mj_extension, 'FenestrationLoadProcedure', @fenestration_load_procedure, :string, @fenestration_load_procedure_isdefaulted) unless @fenestration_load_procedure.nil?
      end
      if (HDL_ATTRS.keys + CDL_SENS_ATTRS.keys + CDL_LAT_ATTRS.keys).map { |key| send(key) }.any?
        HPXML.design_loads_to_doc(self, space)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param space [Oga::XML::Element] The current Space XML element
    # @return [nil]
    def from_doc(space)
      return if space.nil?

      @id = HPXML::get_id(space)
      @floor_area = XMLHelper.get_value(space, 'FloorArea', :float)
      @manualj_internal_loads_sensible = XMLHelper.get_value(space, 'extension/ManualJInputs/InternalLoadsSensible', :float)
      @manualj_internal_loads_latent = XMLHelper.get_value(space, 'extension/ManualJInputs/InternalLoadsLatent', :float)
      @manualj_num_occupants = XMLHelper.get_value(space, 'extension/ManualJInputs/NumberofOccupants', :float)
      @fenestration_load_procedure = XMLHelper.get_value(space, 'extension/ManualJInputs/FenestrationLoadProcedure', :string)
      HPXML.design_loads_from_doc(self, space)
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/AirInfiltration.
  class AirInfiltration < BaseElement
    ATTRS = [:has_flue_or_chimney_in_conditioned_space] # [Boolean] extension/HasFlueOrChimneyInConditionedSpace
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      air_infiltration = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'AirInfiltration'])
      XMLHelper.add_extension(air_infiltration, 'HasFlueOrChimneyInConditionedSpace', @has_flue_or_chimney_in_conditioned_space, :boolean, @has_flue_or_chimney_in_conditioned_space_isdefaulted) unless @has_flue_or_chimney_in_conditioned_space.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      air_infiltration = XMLHelper.get_element(building, 'BuildingDetails/Enclosure/AirInfiltration')
      return if air_infiltration.nil?

      @has_flue_or_chimney_in_conditioned_space = XMLHelper.get_value(air_infiltration, 'extension/HasFlueOrChimneyInConditionedSpace', :boolean)
    end
  end

  # Array of HPXML::AirInfiltrationMeasurement objects.
  class AirInfiltrationMeasurements < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << AirInfiltrationMeasurement.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement').each do |air_infiltration_measurement|
        self << AirInfiltrationMeasurement.new(@parent_object, air_infiltration_measurement)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement.
  class AirInfiltrationMeasurement < BaseElement
    ATTRS = [:id,                     # [String] SystemIdentifier/@id
             :sameas_id,              # [String] SystemIdentifier/@sameas
             :type_of_measurement,    # [String] TypeOfInfiltrationMeasurement
             :infiltration_type,      # [String] TypeOfInfiltrationLeakage (HPXML::InfiltrationTypeXXX)
             :house_pressure,         # [Double] HousePressure (Pa)
             :leakiness_description,  # [String] LeakinessDescription (HPXML::LeakinessXXX)
             :unit_of_measure,        # [String] BuildingAirLeakage/UnitofMeasure (HPXML::UnitsXXX)
             :air_leakage,            # [Double] BuildingAirLeakage/AirLeakage
             :effective_leakage_area, # [Double] EffectiveLeakageArea (sq. in.)
             :specific_leakage_area,  # [Double] SpecificLeakageArea (frac)
             :infiltration_volume,    # [Double] InfiltrationVolume (ft3)
             :infiltration_height,    # [Double] InfiltrationHeight (ft)
             :a_ext]                  # [Double] Aext (frac)
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      air_infiltration = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'AirInfiltration'])
      air_infiltration_measurement = XMLHelper.add_element(air_infiltration, 'AirInfiltrationMeasurement')
      sys_id = XMLHelper.add_element(air_infiltration_measurement, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(air_infiltration_measurement, 'TypeOfInfiltrationMeasurement', @type_of_measurement, :string) unless @type_of_measurement.nil?
      XMLHelper.add_element(air_infiltration_measurement, 'TypeOfInfiltrationLeakage', @infiltration_type, :string, @infiltration_type_isdefaulted) unless @infiltration_type.nil?
      XMLHelper.add_element(air_infiltration_measurement, 'HousePressure', @house_pressure, :float, @house_pressure_isdefaulted) unless @house_pressure.nil?
      XMLHelper.add_element(air_infiltration_measurement, 'LeakinessDescription', @leakiness_description, :string) unless @leakiness_description.nil?
      if (not @unit_of_measure.nil?) && (not @air_leakage.nil?)
        building_air_leakage = XMLHelper.add_element(air_infiltration_measurement, 'BuildingAirLeakage')
        XMLHelper.add_element(building_air_leakage, 'UnitofMeasure', @unit_of_measure, :string, @unit_of_measure_isdefaulted)
        XMLHelper.add_element(building_air_leakage, 'AirLeakage', @air_leakage, :float, @air_leakage_isdefaulted)
      end
      XMLHelper.add_element(air_infiltration_measurement, 'EffectiveLeakageArea', @effective_leakage_area, :float) unless @effective_leakage_area.nil?
      XMLHelper.add_element(air_infiltration_measurement, 'SpecificLeakageArea', @specific_leakage_area, :float) unless @specific_leakage_area.nil?
      XMLHelper.add_element(air_infiltration_measurement, 'InfiltrationVolume', @infiltration_volume, :float, @infiltration_volume_isdefaulted) unless @infiltration_volume.nil?
      XMLHelper.add_element(air_infiltration_measurement, 'InfiltrationHeight', @infiltration_height, :float, @infiltration_height_isdefaulted) unless @infiltration_height.nil?
      XMLHelper.add_extension(air_infiltration_measurement, 'Aext', @a_ext, :float, @a_ext_isdefaulted) unless @a_ext.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param air_infiltration_measurement [Oga::XML::Element] The current AirInfiltrationMeasurement XML element
    # @return [nil]
    def from_doc(air_infiltration_measurement)
      return if air_infiltration_measurement.nil?

      @id = HPXML::get_id(air_infiltration_measurement)
      @type_of_measurement = XMLHelper.get_value(air_infiltration_measurement, 'TypeOfInfiltrationMeasurement', :string)
      @infiltration_type = XMLHelper.get_value(air_infiltration_measurement, 'TypeOfInfiltrationLeakage', :string)
      @house_pressure = XMLHelper.get_value(air_infiltration_measurement, 'HousePressure', :float)
      @leakiness_description = XMLHelper.get_value(air_infiltration_measurement, 'LeakinessDescription', :string)
      @unit_of_measure = XMLHelper.get_value(air_infiltration_measurement, 'BuildingAirLeakage/UnitofMeasure', :string)
      @air_leakage = XMLHelper.get_value(air_infiltration_measurement, 'BuildingAirLeakage/AirLeakage', :float)
      @effective_leakage_area = XMLHelper.get_value(air_infiltration_measurement, 'EffectiveLeakageArea', :float)
      @specific_leakage_area = XMLHelper.get_value(air_infiltration_measurement, 'SpecificLeakageArea', :float)
      @infiltration_volume = XMLHelper.get_value(air_infiltration_measurement, 'InfiltrationVolume', :float)
      @infiltration_height = XMLHelper.get_value(air_infiltration_measurement, 'InfiltrationHeight', :float)
      @a_ext = XMLHelper.get_value(air_infiltration_measurement, 'extension/Aext', :float)
    end
  end

  # Array of HPXML::Attic objects.
  class Attics < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Attic.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Attics/Attic').each do |attic|
        self << Attic.new(@parent_object, attic)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/Attics/Attic.
  class Attic < BaseElement
    ATTRS = [:id,                         # [String] SystemIdentifier/@id
             :sameas_id,                  # [String] SystemIdentifier/@sameas
             :attic_type,                 # [String] AtticType/*
             :vented_attic_sla,           # [Double] AtticType/Vented/VentilationRate[UnitofMeasure="SLA"]/Value
             :vented_attic_ach,           # [Double] AtticType/Vented/VentilationRate[UnitofMeasure="ACHnatural"]/Value
             :within_infiltration_volume, # [Boolean] WithinInfiltrationVolume
             :attached_to_roof_idrefs,    # [Array<String>] AttachedToRoof/@idref
             :attached_to_wall_idrefs,    # [Array<String>] AttachedToWall/@idref
             :attached_to_floor_idrefs]   # [Array<String>] AttachedToFloor/@idref
    attr_accessor(*ATTRS)

    # Returns all roofs for this attic.
    #
    # @return [Array<HPXML::Roof>] List of roof objects
    def attached_roofs
      return [] if @attached_to_roof_idrefs.nil?

      list = @parent_object.roofs.select { |roof| @attached_to_roof_idrefs.include? roof.id }
      if @attached_to_roof_idrefs.size > list.size
        fail "Attached roof not found for attic '#{@id}'."
      end

      return list
    end

    # Returns all walls for this attic.
    #
    # @return [Array<HPXML::Wall>] List of wall objects
    def attached_walls
      return [] if @attached_to_wall_idrefs.nil?

      list = @parent_object.walls.select { |wall| @attached_to_wall_idrefs.include? wall.id }
      if @attached_to_wall_idrefs.size > list.size
        fail "Attached wall not found for attic '#{@id}'."
      end

      return list
    end

    # Returns all floors for this attic.
    #
    # @return [Array<HPXML::Floor>] List of floor objects
    def attached_floors
      return [] if @attached_to_floor_idrefs.nil?

      list = @parent_object.floors.select { |floor| @attached_to_floor_idrefs.include? floor.id }
      if @attached_to_floor_idrefs.size > list.size
        fail "Attached floor not found for attic '#{@id}'."
      end

      return list
    end

    # Returns the location that corresponds to the attic.
    #
    # @return [String] Adjacent location (HPXML::LocationXXX)
    def to_location
      return if @attic_type.nil?

      case @attic_type
      when AtticTypeCathedral, AtticTypeConditioned,
           AtticTypeFlatRoof, AtticTypeBelowApartment
        return LocationConditionedSpace
      when AtticTypeUnvented
        return LocationAtticUnvented
      when AtticTypeVented
        return LocationAtticVented
      when AtticTypeUnknown, AtticTypeOther
        return # Not currently used
      else
        fail "Unexpected attic type: '#{@attic_type}'."
      end
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.attics.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; attached_roofs; rescue StandardError => e; errors << e.message; end
      begin; attached_walls; rescue StandardError => e; errors << e.message; end
      begin; attached_floors; rescue StandardError => e; errors << e.message; end
      begin; to_location; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      attics = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Attics'])
      attic = XMLHelper.add_element(attics, 'Attic')
      sys_id = XMLHelper.add_element(attic, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      if not @attic_type.nil?
        attic_type_el = XMLHelper.add_element(attic, 'AtticType')
        case @attic_type
        when AtticTypeFlatRoof, AtticTypeCathedral, AtticTypeBelowApartment
          XMLHelper.add_element(attic_type_el, @attic_type)
        when AtticTypeUnvented
          attic_type_attic = XMLHelper.add_element(attic_type_el, 'Attic')
          XMLHelper.add_element(attic_type_attic, 'Vented', false, :boolean)
        when AtticTypeVented
          attic_type_attic = XMLHelper.add_element(attic_type_el, 'Attic')
          XMLHelper.add_element(attic_type_attic, 'Vented', true, :boolean)
          if not @vented_attic_sla.nil?
            ventilation_rate = XMLHelper.add_element(attic, 'VentilationRate')
            XMLHelper.add_element(ventilation_rate, 'UnitofMeasure', UnitsSLA, :string)
            XMLHelper.add_element(ventilation_rate, 'Value', @vented_attic_sla, :float, @vented_attic_sla_isdefaulted)
          elsif not @vented_attic_ach.nil?
            ventilation_rate = XMLHelper.add_element(attic, 'VentilationRate')
            XMLHelper.add_element(ventilation_rate, 'UnitofMeasure', UnitsACHNatural, :string)
            XMLHelper.add_element(ventilation_rate, 'Value', @vented_attic_ach, :float)
          end
        when AtticTypeConditioned
          attic_type_attic = XMLHelper.add_element(attic_type_el, 'Attic')
          XMLHelper.add_element(attic_type_attic, 'Conditioned', true, :boolean)
        when AtticTypeUnknown
          XMLHelper.add_element(attic_type_el, 'Attic')
        when AtticTypeOther
          XMLHelper.add_element(attic_type_el, @attic_type)
        else
          fail "Unhandled attic type '#{@attic_type}'."
        end
      else
        fail 'AtticType is a required element.'
      end
      XMLHelper.add_element(attic, 'WithinInfiltrationVolume', @within_infiltration_volume, :boolean, @within_infiltration_volume_isdefaulted) unless @within_infiltration_volume.nil?
      if not @attached_to_roof_idrefs.nil?
        @attached_to_roof_idrefs.each do |roof|
          roof_attached = XMLHelper.add_element(attic, 'AttachedToRoof')
          XMLHelper.add_attribute(roof_attached, 'idref', roof)
        end
      end
      if not @attached_to_wall_idrefs.nil?
        @attached_to_wall_idrefs.each do |wall|
          wall_attached = XMLHelper.add_element(attic, 'AttachedToWall')
          XMLHelper.add_attribute(wall_attached, 'idref', wall)
        end
      end
      if not @attached_to_floor_idrefs.nil?
        @attached_to_floor_idrefs.each do |floor|
          floor_attached = XMLHelper.add_element(attic, 'AttachedToFloor')
          XMLHelper.add_attribute(floor_attached, 'idref', floor)
        end
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param attic [Oga::XML::Element] The current Attic XML element
    # @return [nil]
    def from_doc(attic)
      return if attic.nil?

      @id = HPXML::get_id(attic)
      if XMLHelper.has_element(attic, "AtticType/Attic[Vented='false']")
        @attic_type = AtticTypeUnvented
      elsif XMLHelper.has_element(attic, "AtticType/Attic[Vented='true']")
        @attic_type = AtticTypeVented
      elsif XMLHelper.has_element(attic, "AtticType/Attic[Conditioned='true']")
        @attic_type = AtticTypeConditioned
      elsif XMLHelper.has_element(attic, 'AtticType/Attic')
        @attic_type = AtticTypeUnknown
      elsif XMLHelper.has_element(attic, 'AtticType/FlatRoof')
        @attic_type = AtticTypeFlatRoof
      elsif XMLHelper.has_element(attic, 'AtticType/CathedralCeiling')
        @attic_type = AtticTypeCathedral
      elsif XMLHelper.has_element(attic, 'AtticType/BelowApartment')
        @attic_type = AtticTypeBelowApartment
      elsif XMLHelper.has_element(attic, 'AtticType/Other')
        @attic_type = AtticTypeOther
      end
      if @attic_type == AtticTypeVented
        @vented_attic_sla = XMLHelper.get_value(attic, "VentilationRate[UnitofMeasure='#{UnitsSLA}']/Value", :float)
        @vented_attic_ach = XMLHelper.get_value(attic, "VentilationRate[UnitofMeasure='#{UnitsACHNatural}']/Value", :float)
      end
      @within_infiltration_volume = XMLHelper.get_value(attic, 'WithinInfiltrationVolume', :boolean)
      @attached_to_roof_idrefs = []
      XMLHelper.get_elements(attic, 'AttachedToRoof').each do |roof|
        @attached_to_roof_idrefs << HPXML::get_idref(roof)
      end
      @attached_to_wall_idrefs = []
      XMLHelper.get_elements(attic, 'AttachedToWall').each do |wall|
        @attached_to_wall_idrefs << HPXML::get_idref(wall)
      end
      @attached_to_floor_idrefs = []
      XMLHelper.get_elements(attic, 'AttachedToFloor').each do |floor|
        @attached_to_floor_idrefs << HPXML::get_idref(floor)
      end
    end
  end

  # Array of HPXML::Foundation objects.
  class Foundations < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Foundation.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Foundations/Foundation').each do |foundation|
        self << Foundation.new(@parent_object, foundation)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation.
  class Foundation < BaseElement
    ATTRS = [:id,                                 # [String] SystemIdentifier/@id
             :sameas_id,                          # [String] SystemIdentifier/@sameas
             :foundation_type,                    # [String] FoundationType/*
             :vented_crawlspace_sla,              # [Double] FoundationType/Crawlspace[Vented="true"]/VentilationRate[UnitofMeasure="SLA"]/Value
             :belly_wing_skirt_present,           # [Boolean] FoundationType/BellyAndWing/SkirtPresent
             :within_infiltration_volume,         # [Boolean] WithinInfiltrationVolume
             :attached_to_rim_joist_idrefs,       # [Array<String>] AttachedToRimJoist/@idref
             :attached_to_wall_idrefs,            # [Array<String>] AttachedToWall/@idref
             :attached_to_foundation_wall_idrefs, # [Array<String>] AttachedToFoundationWall/@idref
             :attached_to_floor_idrefs,           # [Array<String>] AttachedToFloor/@idref
             :attached_to_slab_idrefs]            # [Array<String>] AttachedToSlab/@idref
    attr_accessor(*ATTRS)

    # Returns all slabs for this foundation.
    #
    # @return [Array<HPXML::Slab>] List of slab objects
    def attached_slabs
      return [] if @attached_to_slab_idrefs.nil?

      list = @parent_object.slabs.select { |slab| @attached_to_slab_idrefs.include? slab.id }
      if @attached_to_slab_idrefs.size > list.size
        fail "Attached slab not found for foundation '#{@id}'."
      end

      return list
    end

    # Returns all floors for this foundation.
    #
    # @return [Array<HPXML::Floor>] List of floor objects
    def attached_floors
      return [] if @attached_to_floor_idrefs.nil?

      list = @parent_object.floors.select { |floor| @attached_to_floor_idrefs.include? floor.id }
      if @attached_to_floor_idrefs.size > list.size
        fail "Attached floor not found for foundation '#{@id}'."
      end

      return list
    end

    # Returns all foundation walls for this foundation.
    #
    # @return [Array<HPXML::FoundationWall>] List of foundation wall objects
    def attached_foundation_walls
      return [] if @attached_to_foundation_wall_idrefs.nil?

      list = @parent_object.foundation_walls.select { |foundation_wall| @attached_to_foundation_wall_idrefs.include? foundation_wall.id }
      if @attached_to_foundation_wall_idrefs.size > list.size
        fail "Attached foundation wall not found for foundation '#{@id}'."
      end

      return list
    end

    # Returns all walls for this foundation.
    #
    # @return [Array<HPXML::Wall>] List of wall objects
    def attached_walls
      return [] if @attached_to_wall_idrefs.nil?

      list = @parent_object.walls.select { |wall| @attached_to_wall_idrefs.include? wall.id }
      if @attached_to_wall_idrefs.size > list.size
        fail "Attached wall not found for foundation '#{@id}'."
      end

      return list
    end

    # Returns all rim joists for this foundation.
    #
    # @return [Array<HPXML::RimJoist>] List of rim joist objects
    def attached_rim_joists
      return [] if @attached_to_rim_joist_idrefs.nil?

      list = @parent_object.rim_joists.select { |rim_joist| @attached_to_rim_joist_idrefs.include? rim_joist.id }
      if @attached_to_rim_joist_idrefs.size > list.size
        fail "Attached rim joist not found for foundation '#{@id}'."
      end

      return list
    end

    # Returns the location that corresponds to the foundation.
    #
    # @return [String] Adjacent location (HPXML::LocationXXX)
    def to_location
      return if @foundation_type.nil?

      case @foundation_type
      when FoundationTypeSlab, FoundationTypeAboveApartment
        return LocationConditionedSpace
      when FoundationTypeAmbient
        return LocationOutside
      when FoundationTypeBasementConditioned
        return LocationBasementConditioned
      when FoundationTypeBasementUnconditioned
        return LocationBasementUnconditioned
      when FoundationTypeCrawlspaceUnvented
        return LocationCrawlspaceUnvented
      when FoundationTypeCrawlspaceVented
        return LocationCrawlspaceVented
      when FoundationTypeCrawlspaceConditioned
        return LocationCrawlspaceConditioned
      when FoundationTypeBellyAndWing
        return LocationManufacturedHomeUnderBelly
      when FoundationTypeBasementUnknown,
           FoundationTypeCrawlspaceUnknown,
           FoundationTypeGarage,
           FoundationTypeRubbleStone,
           FoundationTypeOther
        return # Not currently used
      else
        fail "Unexpected foundation type: '#{@foundation_type}'."
      end
    end

    # Calculates the foundation footprint area.
    #
    # @return [Double] Foundation area (ft2)
    def area
      sum_area = 0.0
      # Check Slabs first
      attached_slabs.each do |slab|
        sum_area += slab.area
      end
      if sum_area <= 0
        # Check Floors next
        attached_floors.each do |floor|
          sum_area += floor.area
        end
      end
      return sum_area
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.foundations.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; attached_slabs; rescue StandardError => e; errors << e.message; end
      begin; attached_floors; rescue StandardError => e; errors << e.message; end
      begin; attached_foundation_walls; rescue StandardError => e; errors << e.message; end
      begin; attached_walls; rescue StandardError => e; errors << e.message; end
      begin; attached_rim_joists; rescue StandardError => e; errors << e.message; end
      begin; to_location; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      foundations = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Foundations'])
      foundation = XMLHelper.add_element(foundations, 'Foundation')
      sys_id = XMLHelper.add_element(foundation, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      if not @foundation_type.nil?
        foundation_type_el = XMLHelper.add_element(foundation, 'FoundationType')
        case @foundation_type
        when FoundationTypeSlab, FoundationTypeAmbient, FoundationTypeAboveApartment
          XMLHelper.add_element(foundation_type_el, @foundation_type)
        when FoundationTypeBasementConditioned
          basement = XMLHelper.add_element(foundation_type_el, 'Basement')
          XMLHelper.add_element(basement, 'Conditioned', true, :boolean)
        when FoundationTypeBasementUnconditioned
          basement = XMLHelper.add_element(foundation_type_el, 'Basement')
          XMLHelper.add_element(basement, 'Conditioned', false, :boolean)
        when FoundationTypeBasementUnknown
          XMLHelper.add_element(foundation_type_el, 'Basement')
        when FoundationTypeCrawlspaceVented
          crawlspace = XMLHelper.add_element(foundation_type_el, 'Crawlspace')
          XMLHelper.add_element(crawlspace, 'Vented', true, :boolean)
          if not @vented_crawlspace_sla.nil?
            ventilation_rate = XMLHelper.add_element(foundation, 'VentilationRate')
            XMLHelper.add_element(ventilation_rate, 'UnitofMeasure', UnitsSLA, :string)
            XMLHelper.add_element(ventilation_rate, 'Value', @vented_crawlspace_sla, :float, @vented_crawlspace_sla_isdefaulted)
          end
        when FoundationTypeCrawlspaceUnvented
          crawlspace = XMLHelper.add_element(foundation_type_el, 'Crawlspace')
          XMLHelper.add_element(crawlspace, 'Vented', false, :boolean)
        when FoundationTypeCrawlspaceConditioned
          crawlspace = XMLHelper.add_element(foundation_type_el, 'Crawlspace')
          XMLHelper.add_element(crawlspace, 'Conditioned', true, :boolean)
        when FoundationTypeCrawlspaceUnknown
          XMLHelper.add_element(foundation_type_el, 'Crawlspace')
        when FoundationTypeBellyAndWing
          belly_and_wing = XMLHelper.add_element(foundation_type_el, 'BellyAndWing')
          XMLHelper.add_element(belly_and_wing, 'SkirtPresent', @belly_wing_skirt_present, :boolean, @belly_wing_skirt_present_isdefaulted) unless @belly_wing_skirt_present.nil?
        when FoundationTypeGarage
          XMLHelper.add_element(foundation_type_el, 'Garage')
        when FoundationTypeRubbleStone
          XMLHelper.add_element(foundation_type_el, 'RubbleStone')
        when FoundationTypeOther
          XMLHelper.add_element(foundation_type_el, 'Other')
        else
          fail "Unhandled foundation type '#{@foundation_type}'."
        end
      else
        fail 'FoundationType is a required element.'
      end
      XMLHelper.add_element(foundation, 'WithinInfiltrationVolume', @within_infiltration_volume, :boolean) unless @within_infiltration_volume.nil?
      if not @attached_to_rim_joist_idrefs.nil?
        @attached_to_rim_joist_idrefs.each do |rim_joist|
          rim_joist_attached = XMLHelper.add_element(foundation, 'AttachedToRimJoist')
          XMLHelper.add_attribute(rim_joist_attached, 'idref', rim_joist)
        end
      end
      if not @attached_to_wall_idrefs.nil?
        @attached_to_wall_idrefs.each do |wall|
          wall_attached = XMLHelper.add_element(foundation, 'AttachedToWall')
          XMLHelper.add_attribute(wall_attached, 'idref', wall)
        end
      end
      if not @attached_to_foundation_wall_idrefs.nil?
        @attached_to_foundation_wall_idrefs.each do |foundation_wall|
          foundation_wall_attached = XMLHelper.add_element(foundation, 'AttachedToFoundationWall')
          XMLHelper.add_attribute(foundation_wall_attached, 'idref', foundation_wall)
        end
      end
      if not @attached_to_floor_idrefs.nil?
        @attached_to_floor_idrefs.each do |floor|
          floor_attached = XMLHelper.add_element(foundation, 'AttachedToFloor')
          XMLHelper.add_attribute(floor_attached, 'idref', floor)
        end
      end
      if not @attached_to_slab_idrefs.nil?
        @attached_to_slab_idrefs.each do |slab|
          slab_attached = XMLHelper.add_element(foundation, 'AttachedToSlab')
          XMLHelper.add_attribute(slab_attached, 'idref', slab)
        end
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param foundation [Oga::XML::Element] The current Foundation XML element
    # @return [nil]
    def from_doc(foundation)
      return if foundation.nil?

      @id = HPXML::get_id(foundation)
      if XMLHelper.has_element(foundation, 'FoundationType/SlabOnGrade')
        @foundation_type = FoundationTypeSlab
      elsif XMLHelper.has_element(foundation, "FoundationType/Basement[Conditioned='false']")
        @foundation_type = FoundationTypeBasementUnconditioned
      elsif XMLHelper.has_element(foundation, "FoundationType/Basement[Conditioned='true']")
        @foundation_type = FoundationTypeBasementConditioned
      elsif XMLHelper.has_element(foundation, 'FoundationType/Basement')
        @foundation_type = FoundationTypeBasementUnknown
      elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace[Vented='false']")
        @foundation_type = FoundationTypeCrawlspaceUnvented
      elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace[Vented='true']")
        @foundation_type = FoundationTypeCrawlspaceVented
      elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace[Conditioned='true']")
        @foundation_type = FoundationTypeCrawlspaceConditioned
      elsif XMLHelper.has_element(foundation, 'FoundationType/Crawlspace')
        @foundation_type = FoundationTypeCrawlspaceUnknown
      elsif XMLHelper.has_element(foundation, 'FoundationType/Ambient')
        @foundation_type = FoundationTypeAmbient
      elsif XMLHelper.has_element(foundation, 'FoundationType/AboveApartment')
        @foundation_type = FoundationTypeAboveApartment
      elsif XMLHelper.has_element(foundation, 'FoundationType/BellyAndWing')
        @foundation_type = FoundationTypeBellyAndWing
        @belly_wing_skirt_present = XMLHelper.get_value(foundation, 'FoundationType/BellyAndWing/SkirtPresent', :boolean)
      elsif XMLHelper.has_element(foundation, 'FoundationType/RubbleStone')
        @foundation_type = FoundationTypeRubbleStone
      elsif XMLHelper.has_element(foundation, 'FoundationType/Garage')
        @foundation_type = FoundationTypeGarage
      elsif XMLHelper.has_element(foundation, 'FoundationType/Other')
        @foundation_type = FoundationTypeOther
      end
      if @foundation_type == FoundationTypeCrawlspaceVented
        @vented_crawlspace_sla = XMLHelper.get_value(foundation, "VentilationRate[UnitofMeasure='#{UnitsSLA}']/Value", :float)
      end
      @within_infiltration_volume = XMLHelper.get_value(foundation, 'WithinInfiltrationVolume', :boolean)
      @attached_to_rim_joist_idrefs = []
      XMLHelper.get_elements(foundation, 'AttachedToRimJoist').each do |rim_joist|
        @attached_to_rim_joist_idrefs << HPXML::get_idref(rim_joist)
      end
      @attached_to_wall_idrefs = []
      XMLHelper.get_elements(foundation, 'AttachedToWall').each do |wall|
        @attached_to_wall_idrefs << HPXML::get_idref(wall)
      end
      @attached_to_slab_idrefs = []
      XMLHelper.get_elements(foundation, 'AttachedToSlab').each do |slab|
        @attached_to_slab_idrefs << HPXML::get_idref(slab)
      end
      @attached_to_floor_idrefs = []
      XMLHelper.get_elements(foundation, 'AttachedToFloor').each do |floor|
        @attached_to_floor_idrefs << HPXML::get_idref(floor)
      end
      @attached_to_foundation_wall_idrefs = []
      XMLHelper.get_elements(foundation, 'AttachedToFoundationWall').each do |foundation_wall|
        @attached_to_foundation_wall_idrefs << HPXML::get_idref(foundation_wall)
      end
    end
  end

  # Array of HPXML::Roof objects.
  class Roofs < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Roof.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Roofs/Roof').each do |roof|
        self << Roof.new(@parent_object, roof)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof.
  class Roof < BaseElement
    ATTRS = [:id,                             # [String] SystemIdentifier/@id
             :sameas_id,                      # [String] SystemIdentifier/@sameas
             :attached_to_space_idref,        # [String] AttachedToSpace/@idref
             :interior_adjacent_to,           # [String] InteriorAdjacentTo (HPXML::LocationXXX)
             :area,                           # [Double] Area (ft2)
             :orientation,                    # [String] Orientation (HPXML::OrientationXXX)
             :azimuth,                        # [Integer] Azimuth (deg)
             :roof_type,                      # [String] RoofType (HPXML::RoofTypeXXX)
             :roof_color,                     # [String] RoofColor (HPXML::ColorXXX)
             :solar_absorptance,              # [Double] SolarAbsorptance
             :emittance,                      # [Double] Emittance
             :interior_finish_type,           # [String] InteriorFinish/Type (HPXML::InteriorFinishXXX)
             :interior_finish_thickness,      # [Double] InteriorFinish/Thickness (in)
             :framing_size,                   # [String] Rafters/Size
             :framing_spacing,                # [Double] Rafters/Spacing (in)
             :framing_factor,                 # [Double] Rafters/FramingFactor (frac)
             :pitch,                          # [Double] Pitch (?/12)
             :radiant_barrier,                # [Boolean] RadiantBarrier
             :radiant_barrier_grade,          # [Integer] RadiantBarrierGrade
             :insulation_id,                  # [String] Insulation/@id
             :insulation_grade,               # [Integer] Insulation/InsulationGrade
             :insulation_assembly_r_value,    # [Double] Insulation/AssemblyEffectiveRValue (F-ft2-hr/Btu)
             :insulation_cavity_r_value,      # [Double] Insulation/Layer[InstallationType="cavity"]/NominalRValue (F-ft2-hr/Btu)
             :insulation_continuous_r_value]  # [Double] Insulation/Layer[InstallationType="continuous"]/NominalRValue (F-ft2-hr/Btu)
    attr_accessor(*ATTRS)

    # Returns all skylights for this roof.
    #
    # @return [Array<HPXML::Skylight>] List of skylight objects
    def skylights
      return @parent_object.skylights.select { |skylight| skylight.attached_to_roof_idref == @id }
    end

    # Returns the space that the roof is attached to.
    #
    # @return [HPXML::Space] Space object
    def space
      return if @attached_to_space_idref.nil?

      @parent_object.zones.each do |z|
        z.spaces.each do |s|
          return s if s.id == @attached_to_space_idref
        end
      end

      fail "Attached space '#{@attached_to_space_idref}' not found for roof '#{@id}'."
    end

    # Calculates the net area (gross area minus subsurface area).
    #
    # @return [Double] Net area (ft2)
    def net_area
      val = @area
      skylights.each do |skylight|
        val -= skylight.area
      end
      fail "Calculated a negative net surface area for surface '#{@id}'." if val < 0

      return val
    end

    # Returns the assumed exterior adjacent to location.
    #
    # @return [String] Exterior adjacent to location (HPXML::LocationXXX)
    def exterior_adjacent_to
      return LocationOutside
    end

    # Returns whether the roof is an exterior surface (i.e., adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an exterior surface
    def is_exterior
      return true
    end

    # Returns whether the roof is an interior surface (i.e., NOT adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an interior surface
    def is_interior
      return !is_exterior
    end

    # Returns whether the roof is between conditioned space and outside.
    #
    # @return [Boolean] True if a thermal boundary surface
    def is_thermal_boundary
      return HPXML::is_thermal_boundary(self)
    end

    # Returns whether the roof is both an exterior surface and a thermal boundary surface.
    #
    # @return [Boolean] True if an exterior, thermal boundary surface
    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    # Returns whether the roof is adjacent to conditioned space.
    #
    # @return [Boolean] True if adjacent to conditioned space
    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.roofs.delete(self)
      skylights.reverse_each do |skylight|
        skylight.delete
      end
      @parent_object.attics.each do |attic|
        attic.attached_to_roof_idrefs.delete(@id) unless attic.attached_to_roof_idrefs.nil?
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; net_area; rescue StandardError => e; errors << e.message; end
      begin; space; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      roofs = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Roofs'])
      roof = XMLHelper.add_element(roofs, 'Roof')
      sys_id = XMLHelper.add_element(roof, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      if not @attached_to_space_idref.nil?
        space_attached = XMLHelper.add_element(roof, 'AttachedToSpace')
        XMLHelper.add_attribute(space_attached, 'idref', @attached_to_space_idref)
      end
      XMLHelper.add_element(roof, 'InteriorAdjacentTo', @interior_adjacent_to, :string) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(roof, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(roof, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      XMLHelper.add_element(roof, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(roof, 'RoofType', @roof_type, :string, @roof_type_isdefaulted) unless @roof_type.nil?
      XMLHelper.add_element(roof, 'RoofColor', @roof_color, :string, @roof_color_isdefaulted) unless @roof_color.nil?
      XMLHelper.add_element(roof, 'SolarAbsorptance', @solar_absorptance, :float, @solar_absorptance_isdefaulted) unless @solar_absorptance.nil?
      XMLHelper.add_element(roof, 'Emittance', @emittance, :float, @emittance_isdefaulted) unless @emittance.nil?
      if (not @interior_finish_type.nil?) || (not @interior_finish_thickness.nil?)
        interior_finish = XMLHelper.add_element(roof, 'InteriorFinish')
        XMLHelper.add_element(interior_finish, 'Type', @interior_finish_type, :string, @interior_finish_type_isdefaulted) unless @interior_finish_type.nil?
        XMLHelper.add_element(interior_finish, 'Thickness', @interior_finish_thickness, :float, @interior_finish_thickness_isdefaulted) unless @interior_finish_thickness.nil?
      end
      if (not @framing_factor.nil?) || (not @framing_size.nil?) || (not @framing_spacing.nil?)
        rafters = XMLHelper.add_element(roof, 'Rafters')
        XMLHelper.add_element(rafters, 'Size', @framing_size, :string) unless @framing_size.nil?
        XMLHelper.add_element(rafters, 'Spacing', @framing_spacing, :float) unless @framing_spacing.nil?
        XMLHelper.add_element(rafters, 'FramingFactor', @framing_factor, :float) unless @framing_factor.nil?
      end
      XMLHelper.add_element(roof, 'Pitch', @pitch, :float) unless @pitch.nil?
      XMLHelper.add_element(roof, 'RadiantBarrier', @radiant_barrier, :boolean, @radiant_barrier_isdefaulted) unless @radiant_barrier.nil?
      XMLHelper.add_element(roof, 'RadiantBarrierGrade', @radiant_barrier_grade, :integer, @radiant_barrier_grade_isdefaulted) unless @radiant_barrier_grade.nil?
      insulation = XMLHelper.add_element(roof, 'Insulation')
      sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
      if not @insulation_id.nil?
        XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
      else
        XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
      end
      XMLHelper.add_element(insulation, 'InsulationGrade', @insulation_grade, :integer) unless @insulation_grade.nil?
      XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', @insulation_assembly_r_value, :float) unless @insulation_assembly_r_value.nil?
      if not @insulation_cavity_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'cavity', :string)
        XMLHelper.add_element(layer, 'NominalRValue', @insulation_cavity_r_value, :float)
      end
      if not @insulation_continuous_r_value.nil?
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'InstallationType', 'continuous', :string)
        XMLHelper.add_element(layer, 'NominalRValue', @insulation_continuous_r_value, :float)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param roof [Oga::XML::Element] The current Roof XML element
    # @return [nil]
    def from_doc(roof)
      return if roof.nil?

      @id = HPXML::get_id(roof)
      @interior_adjacent_to = XMLHelper.get_value(roof, 'InteriorAdjacentTo', :string)
      @area = XMLHelper.get_value(roof, 'Area', :float)
      @orientation = XMLHelper.get_value(roof, 'Orientation', :string)
      @azimuth = XMLHelper.get_value(roof, 'Azimuth', :integer)
      @roof_type = XMLHelper.get_value(roof, 'RoofType', :string)
      @roof_color = XMLHelper.get_value(roof, 'RoofColor', :string)
      @solar_absorptance = XMLHelper.get_value(roof, 'SolarAbsorptance', :float)
      @emittance = XMLHelper.get_value(roof, 'Emittance', :float)
      interior_finish = XMLHelper.get_element(roof, 'InteriorFinish')
      if not interior_finish.nil?
        @interior_finish_type = XMLHelper.get_value(interior_finish, 'Type', :string)
        @interior_finish_thickness = XMLHelper.get_value(interior_finish, 'Thickness', :float)
      end
      @framing_factor = XMLHelper.get_value(roof, 'Rafters/FramingFactor', :float)
      @framing_size = XMLHelper.get_value(roof, 'Rafters/Size', :string)
      @framing_spacing = XMLHelper.get_value(roof, 'Rafters/Spacing', :float)
      @pitch = XMLHelper.get_value(roof, 'Pitch', :float)
      @radiant_barrier = XMLHelper.get_value(roof, 'RadiantBarrier', :boolean)
      @radiant_barrier_grade = XMLHelper.get_value(roof, 'RadiantBarrierGrade', :integer)
      insulation = XMLHelper.get_element(roof, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_grade = XMLHelper.get_value(insulation, 'InsulationGrade', :integer)
        @insulation_assembly_r_value = XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue', :float)
        @insulation_cavity_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue", :float)
        @insulation_continuous_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue", :float)
      end
      @attached_to_space_idref = HPXML::get_idref(XMLHelper.get_elements(roof, 'AttachedToSpace')[0])
    end
  end

  # Array of HPXML::RimJoist objects.
  class RimJoists < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << RimJoist.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/RimJoists/RimJoist').each do |rim_joist|
        self << RimJoist.new(@parent_object, rim_joist)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/RimJoists/RimJoist.
  class RimJoist < BaseElement
    ATTRS = [:id,                             # [String] SystemIdentifier/@id
             :sameas_id,                      # [String] SystemIdentifier/@sameas
             :attached_to_space_idref,        # [String] AttachedToSpace/@idref
             :exterior_adjacent_to,           # [String] ExteriorAdjacentTo (HPXML::LocationXXX)
             :interior_adjacent_to,           # [String] InteriorAdjacentTo (HPXML::LocationXXX)
             :area,                           # [Double] Area (ft2)
             :orientation,                    # [String] Orientation (HPXML::OrientationXXX)
             :azimuth,                        # [Integer] Azimuth (deg)
             :siding,                         # [String] Siding (HPXML::SidingTypeXXX)
             :color,                          # [String] Color (HPXML::ColorXXX)
             :solar_absorptance,              # [Double] SolarAbsorptance
             :emittance,                      # [Double] Emittance
             :insulation_id,                  # [String] Insulation/SystemIdentifier/@id
             :insulation_assembly_r_value,    # [Double] Insulation/AssemblyEffectiveRValue (F-ft2-hr/Btu)
             :insulation_cavity_r_value,      # [Double] Insulation/Layer[InstallationType="cavity"]/NominalRValue (F-ft2-hr/Btu)
             :insulation_continuous_r_value,  # [Double] Insulation/Layer[InstallationType="continuous"]/NominalRValue (F-ft2-hr/Btu)
             :framing_size]                   # [String] FloorJoists/Size
    attr_accessor(*ATTRS)

    # Returns the same rim joist specified in other places.
    #
    # @return [<HPXML::RimJoist>] RimJoist object linked by sameas attribute
    def sameas
      return HPXML::get_sameas_obj(@parent_object, self)
    end

    # Returns the space that the rim joist is attached to.
    #
    # @return [HPXML::Space] Space object
    def space
      return if @attached_to_space_idref.nil?

      @parent_object.zones.each do |z|
        z.spaces.each do |s|
          return s if s.id == @attached_to_space_idref
        end
      end

      fail "Attached space '#{@attached_to_space_idref}' not found for rim joist '#{@id}'."
    end

    # Returns whether the rim joist is an exterior surface (i.e., adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an exterior surface
    def is_exterior
      return @exterior_adjacent_to == LocationOutside
    end

    # Returns whether the rim joist is an interior surface (i.e., NOT adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an interior surface
    def is_interior
      return !is_exterior
    end

    # Returns whether the rim joist is determined to be adiabatic.
    #
    # @return [Boolean] True if adiabatic
    def is_adiabatic
      return HPXML::is_adiabatic(self)
    end

    # Returns whether the rim joist is between conditioned space and outside/ground/unconditioned space.
    # Note: The location of insulation is not considered here, so an insulated rim joist of an
    # unconditioned basement, for example, returns false.
    #
    # @return [Boolean] True if a thermal boundary surface
    def is_thermal_boundary
      return HPXML::is_thermal_boundary(self)
    end

    # Returns whether the rim joist is both an exterior surface and a thermal boundary surface.
    #
    # @return [Boolean] True if an exterior, thermal boundary surface
    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    # Returns whether the rim joist is adjacent to conditioned space.
    #
    # @return [Boolean] True if adjacent to conditioned space
    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    # Calculates the net area (gross area minus subsurface area).
    #
    # @return [Double] Net area (ft2)
    def net_area
      return area
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.rim_joists.delete(self)
      @parent_object.foundations.each do |foundation|
        foundation.attached_to_rim_joist_idrefs.delete(@id) unless foundation.attached_to_rim_joist_idrefs.nil?
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; space; rescue StandardError => e; errors << e.message; end
      if sameas_id
        begin; sameas; rescue StandardError => e; errors << e.message; end
      end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      rim_joists = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'RimJoists'])
      rim_joist = XMLHelper.add_element(rim_joists, 'RimJoist')
      sys_id = XMLHelper.add_element(rim_joist, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?

      if not @attached_to_space_idref.nil?
        space_attached = XMLHelper.add_element(rim_joist, 'AttachedToSpace')
        XMLHelper.add_attribute(space_attached, 'idref', @attached_to_space_idref)
      end
      XMLHelper.add_element(rim_joist, 'ExteriorAdjacentTo', @exterior_adjacent_to, :string) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(rim_joist, 'InteriorAdjacentTo', @interior_adjacent_to, :string) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(rim_joist, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(rim_joist, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      XMLHelper.add_element(rim_joist, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(rim_joist, 'Siding', @siding, :string, @siding_isdefaulted) unless @siding.nil?
      XMLHelper.add_element(rim_joist, 'Color', @color, :string, @color_isdefaulted) unless @color.nil?
      XMLHelper.add_element(rim_joist, 'SolarAbsorptance', @solar_absorptance, :float, @solar_absorptance_isdefaulted) unless @solar_absorptance.nil?
      XMLHelper.add_element(rim_joist, 'Emittance', @emittance, :float, @emittance_isdefaulted) unless @emittance.nil?
      if (not @insulation_id.nil?) || (not @insulation_assembly_r_value.nil?) || (not @insulation_cavity_r_value.nil?) || (not @insulation_continuous_r_value.nil?)
        insulation = XMLHelper.add_element(rim_joist, 'Insulation')
        sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
        if not @insulation_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
        end
        XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', @insulation_assembly_r_value, :float) unless @insulation_assembly_r_value.nil?
        if not @insulation_cavity_r_value.nil?
          layer = XMLHelper.add_element(insulation, 'Layer')
          XMLHelper.add_element(layer, 'InstallationType', 'cavity', :string)
          XMLHelper.add_element(layer, 'NominalRValue', @insulation_cavity_r_value, :float)
        end
        if not @insulation_continuous_r_value.nil?
          layer = XMLHelper.add_element(insulation, 'Layer')
          XMLHelper.add_element(layer, 'InstallationType', 'continuous', :string)
          XMLHelper.add_element(layer, 'NominalRValue', @insulation_continuous_r_value, :float)
        end
      end
      if not @framing_size.nil?
        floor_joists = XMLHelper.add_element(rim_joist, 'FloorJoists')
        XMLHelper.add_element(floor_joists, 'Size', @framing_size, :string) unless @framing_size.nil?
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param rim_joist [Oga::XML::Element] The current RimJoist XML element
    # @return [nil]
    def from_doc(rim_joist)
      return if rim_joist.nil?

      @id = HPXML::get_id(rim_joist)
      @sameas_id = HPXML::get_sameas_id(rim_joist)
      @exterior_adjacent_to = XMLHelper.get_value(rim_joist, 'ExteriorAdjacentTo', :string)
      @interior_adjacent_to = XMLHelper.get_value(rim_joist, 'InteriorAdjacentTo', :string)
      @area = XMLHelper.get_value(rim_joist, 'Area', :float)
      @orientation = XMLHelper.get_value(rim_joist, 'Orientation', :string)
      @azimuth = XMLHelper.get_value(rim_joist, 'Azimuth', :integer)
      @siding = XMLHelper.get_value(rim_joist, 'Siding', :string)
      @color = XMLHelper.get_value(rim_joist, 'Color', :string)
      @solar_absorptance = XMLHelper.get_value(rim_joist, 'SolarAbsorptance', :float)
      @emittance = XMLHelper.get_value(rim_joist, 'Emittance', :float)
      insulation = XMLHelper.get_element(rim_joist, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_assembly_r_value = XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue', :float)
        @insulation_cavity_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue", :float)
        @insulation_continuous_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue", :float)
      end
      @framing_size = XMLHelper.get_value(rim_joist, 'FloorJoists/Size', :string)
      @attached_to_space_idref = HPXML::get_idref(XMLHelper.get_elements(rim_joist, 'AttachedToSpace')[0])
    end
  end

  # Array of HPXML::Wall objects.
  class Walls < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Wall.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Walls/Wall').each do |wall|
        self << Wall.new(@parent_object, wall)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/Walls/Wall.
  class Wall < BaseElement
    ATTRS = [:id,                             # [String] SystemIdentifier/@id
             :sameas_id,                      # [String] SystemIdentifier/@sameas
             :attached_to_space_idref,        # [String] AttachedToSpace/@idref
             :exterior_adjacent_to,           # [String] ExteriorAdjacentTo (HPXML::LocationXXX)
             :interior_adjacent_to,           # [String] InteriorAdjacentTo (HPXML::LocationXXX)
             :attic_wall_type,                # [String] AtticWallType (HPXML::AtticWallTypeXXX)
             :wall_type,                      # [String] WallType/*
             :optimum_value_engineering,      # [Boolean] WallType/WoodStud/OptimumValueEngineering
             :area,                           # [Double] Area (ft2)
             :orientation,                    # [String] Orientation (HPXML::OrientationXXX)
             :azimuth,                        # [Integer] Azimuth (deg)
             :framing_size,                   # [String] Studs/Size
             :framing_spacing,                # [Double] Studs/Spacing (in)
             :framing_factor,                 # [Double] Studs/FramingFactor (frac)
             :siding,                         # [String] Siding (HPXML::SidingTypeXXX)
             :color,                          # [String] Color (HPXML::ColorXXX)
             :solar_absorptance,              # [Double] SolarAbsorptance
             :emittance,                      # [Double] Emittance
             :interior_finish_type,           # [String] InteriorFinish/Type (HPXML::InteriorFinishXXX)
             :interior_finish_thickness,      # [Double] InteriorFinish/Thickness (in)
             :radiant_barrier,                # [Boolean] RadiantBarrier
             :radiant_barrier_grade,          # [Integer] RadiantBarrierGrade
             :insulation_id,                  # [String] Insulation/SystemIdentifier/@id
             :insulation_grade,               # [Integer] Insulation/InsulationGrade
             :insulation_assembly_r_value,    # [Double] Insulation/AssemblyEffectiveRValue (F-ft2-hr/Btu)
             :insulation_cavity_r_value,      # [Double] Insulation/Layer[InstallationType="cavity"]/NominalRValue (F-ft2-hr/Btu)
             :insulation_continuous_r_value]  # [Double] Insulation/Layer[InstallationType="continuous"]/NominalRValue (F-ft2-hr/Btu)
    attr_accessor(*ATTRS)

    # Returns the same wall specified in other places.
    #
    # @return [<HPXML::Wall>] Wall object linked by sameas attribute
    def sameas
      return HPXML::get_sameas_obj(@parent_object, self)
    end

    # Returns all windows for this wall.
    #
    # @return [Array<HPXML::Window>] List of window objects
    def windows
      return @parent_object.windows.select { |window| window.attached_to_wall_idref == @id }
    end

    # Returns all doors for this wall.
    #
    # @return [Array<HPXML::Door>] List of door objects
    def doors
      return @parent_object.doors.select { |door| door.attached_to_wall_idref == @id }
    end

    # Returns the space that the wall is attached to.
    #
    # @return [HPXML::Space] Space object
    def space
      return if @attached_to_space_idref.nil?

      @parent_object.zones.each do |z|
        z.spaces.each do |s|
          return s if s.id == @attached_to_space_idref
        end
      end

      fail "Attached space '#{@attached_to_space_idref}' not found for wall '#{@id}'."
    end

    # Calculates the net area (gross area minus subsurface area).
    #
    # @return [Double] Net area (ft2)
    def net_area
      val = @area
      (windows + doors).each do |subsurface|
        val -= subsurface.area
      end
      fail "Calculated a negative net surface area for surface '#{@id}'." if val < 0

      return val
    end

    # Returns whether the wall is an exterior surface (i.e., adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an exterior surface
    def is_exterior
      return @exterior_adjacent_to == LocationOutside
    end

    # Returns whether the wall is an interior surface (i.e., NOT adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an interior surface
    def is_interior
      return !is_exterior
    end

    # Returns whether the wall is determined to be adiabatic.
    #
    # @return [Boolean] True if adiabatic
    def is_adiabatic
      return HPXML::is_adiabatic(self)
    end

    # Returns whether the wall is between conditioned space and outside/ground/unconditioned space.
    # Note: The location of insulation is not considered here, so an insulated wall of a garage,
    # for example, returns false.
    #
    # @return [Boolean] True if a thermal boundary surface
    def is_thermal_boundary
      return HPXML::is_thermal_boundary(self)
    end

    # Returns whether the wall is both an exterior surface and a thermal boundary surface.
    #
    # @return [Boolean] True if an exterior, thermal boundary surface
    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    # Returns whether the wall is adjacent to conditioned space.
    #
    # @return [Boolean] True if adjacent to conditioned space
    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.walls.delete(self)
      windows.reverse_each do |window|
        window.delete
      end
      doors.reverse_each do |door|
        door.delete
      end
      @parent_object.attics.each do |attic|
        attic.attached_to_wall_idrefs.delete(@id) unless attic.attached_to_wall_idrefs.nil?
      end
      @parent_object.foundations.each do |foundation|
        foundation.attached_to_wall_idrefs.delete(@id) unless foundation.attached_to_wall_idrefs.nil?
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      if not sameas_id
        begin; net_area; rescue StandardError => e; errors << e.message; end
      else
        begin; sameas; rescue StandardError => e; errors << e.message; end
      end
      begin; space; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      walls = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Walls'])
      wall = XMLHelper.add_element(walls, 'Wall')
      sys_id = XMLHelper.add_element(wall, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?

      if not @attached_to_space_idref.nil?
        space_attached = XMLHelper.add_element(wall, 'AttachedToSpace')
        XMLHelper.add_attribute(space_attached, 'idref', @attached_to_space_idref)
      end
      XMLHelper.add_element(wall, 'ExteriorAdjacentTo', @exterior_adjacent_to, :string) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(wall, 'InteriorAdjacentTo', @interior_adjacent_to, :string) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(wall, 'AtticWallType', @attic_wall_type, :string) unless @attic_wall_type.nil?
      if not @wall_type.nil?
        wall_type_el = XMLHelper.add_element(wall, 'WallType')
        wall_type = XMLHelper.add_element(wall_type_el, @wall_type)
        if @wall_type == HPXML::WallTypeWoodStud
          XMLHelper.add_element(wall_type, 'OptimumValueEngineering', @optimum_value_engineering, :boolean) unless @optimum_value_engineering.nil?
        end
      end
      XMLHelper.add_element(wall, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(wall, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      XMLHelper.add_element(wall, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      if (not @framing_factor.nil?) || (not @framing_size.nil?) || (not @framing_spacing.nil?)
        studs = XMLHelper.add_element(wall, 'Studs')
        XMLHelper.add_element(studs, 'Size', @framing_size, :string) unless @framing_size.nil?
        XMLHelper.add_element(studs, 'Spacing', @framing_spacing, :float) unless @framing_spacing.nil?
        XMLHelper.add_element(studs, 'FramingFactor', @framing_factor, :float) unless @framing_factor.nil?
      end
      XMLHelper.add_element(wall, 'Siding', @siding, :string, @siding_isdefaulted) unless @siding.nil?
      XMLHelper.add_element(wall, 'Color', @color, :string, @color_isdefaulted) unless @color.nil?
      XMLHelper.add_element(wall, 'SolarAbsorptance', @solar_absorptance, :float, @solar_absorptance_isdefaulted) unless @solar_absorptance.nil?
      XMLHelper.add_element(wall, 'Emittance', @emittance, :float, @emittance_isdefaulted) unless @emittance.nil?
      if (not @interior_finish_type.nil?) || (not @interior_finish_thickness.nil?)
        interior_finish = XMLHelper.add_element(wall, 'InteriorFinish')
        XMLHelper.add_element(interior_finish, 'Type', @interior_finish_type, :string, @interior_finish_type_isdefaulted) unless @interior_finish_type.nil?
        XMLHelper.add_element(interior_finish, 'Thickness', @interior_finish_thickness, :float, @interior_finish_thickness_isdefaulted) unless @interior_finish_thickness.nil?
      end
      XMLHelper.add_element(wall, 'RadiantBarrier', @radiant_barrier, :boolean, @radiant_barrier_isdefaulted) unless @radiant_barrier.nil?
      XMLHelper.add_element(wall, 'RadiantBarrierGrade', @radiant_barrier_grade, :integer, @radiant_barrier_grade_isdefaulted) unless @radiant_barrier_grade.nil?
      if (not @insulation_id.nil?) || (not @insulation_grade.nil?) || (not @insulation_assembly_r_value.nil?) || (not @insulation_cavity_r_value.nil?) || (not @insulation_continuous_r_value.nil?)
        insulation = XMLHelper.add_element(wall, 'Insulation')
        sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
        if not @insulation_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
        end
        XMLHelper.add_element(insulation, 'InsulationGrade', @insulation_grade, :integer) unless @insulation_grade.nil?
        XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', @insulation_assembly_r_value, :float) unless @insulation_assembly_r_value.nil?
        if not @insulation_cavity_r_value.nil?
          layer = XMLHelper.add_element(insulation, 'Layer')
          XMLHelper.add_element(layer, 'InstallationType', 'cavity', :string)
          XMLHelper.add_element(layer, 'NominalRValue', @insulation_cavity_r_value, :float)
        end
        if not @insulation_continuous_r_value.nil?
          layer = XMLHelper.add_element(insulation, 'Layer')
          XMLHelper.add_element(layer, 'InstallationType', 'continuous', :string)
          XMLHelper.add_element(layer, 'NominalRValue', @insulation_continuous_r_value, :float)
        end
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param wall [Oga::XML::Element] The current Wall XML element
    # @return [nil]
    def from_doc(wall)
      return if wall.nil?

      @id = HPXML::get_id(wall)
      @sameas_id = HPXML::get_sameas_id(wall)
      @exterior_adjacent_to = XMLHelper.get_value(wall, 'ExteriorAdjacentTo', :string)
      @interior_adjacent_to = XMLHelper.get_value(wall, 'InteriorAdjacentTo', :string)
      @attic_wall_type = XMLHelper.get_value(wall, 'AtticWallType', :string)
      @wall_type = XMLHelper.get_child_name(wall, 'WallType')
      if @wall_type == HPXML::WallTypeWoodStud
        @optimum_value_engineering = XMLHelper.get_value(wall, 'WallType/WoodStud/OptimumValueEngineering', :boolean)
      end
      @area = XMLHelper.get_value(wall, 'Area', :float)
      @orientation = XMLHelper.get_value(wall, 'Orientation', :string)
      @azimuth = XMLHelper.get_value(wall, 'Azimuth', :integer)
      @framing_size = XMLHelper.get_value(wall, 'Studs/Size', :string)
      @framing_spacing = XMLHelper.get_value(wall, 'Studs/Spacing', :float)
      @framing_factor = XMLHelper.get_value(wall, 'Studs/FramingFactor', :float)
      @siding = XMLHelper.get_value(wall, 'Siding', :string)
      @color = XMLHelper.get_value(wall, 'Color', :string)
      @solar_absorptance = XMLHelper.get_value(wall, 'SolarAbsorptance', :float)
      @emittance = XMLHelper.get_value(wall, 'Emittance', :float)
      interior_finish = XMLHelper.get_element(wall, 'InteriorFinish')
      if not interior_finish.nil?
        @interior_finish_type = XMLHelper.get_value(interior_finish, 'Type', :string)
        @interior_finish_thickness = XMLHelper.get_value(interior_finish, 'Thickness', :float)
      end
      @radiant_barrier = XMLHelper.get_value(wall, 'RadiantBarrier', :boolean)
      @radiant_barrier_grade = XMLHelper.get_value(wall, 'RadiantBarrierGrade', :integer)
      insulation = XMLHelper.get_element(wall, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_grade = XMLHelper.get_value(insulation, 'InsulationGrade', :integer)
        @insulation_assembly_r_value = XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue', :float)
        @insulation_cavity_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue", :float)
        @insulation_continuous_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue", :float)
      end
      @attached_to_space_idref = HPXML::get_idref(XMLHelper.get_elements(wall, 'AttachedToSpace')[0])
    end
  end

  # Array of HPXML::FoundationWall objects.
  class FoundationWalls < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << FoundationWall.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/FoundationWalls/FoundationWall').each do |foundation_wall|
        self << FoundationWall.new(@parent_object, foundation_wall)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall.
  class FoundationWall < BaseElement
    ATTRS = [:id,                                     # [String] SystemIdentifier/@id
             :sameas_id,                              # [String] SystemIdentifier/@sameas
             :attached_to_space_idref,                # [String] AttachedToSpace/@idref
             :exterior_adjacent_to,                   # [String] ExteriorAdjacentTo (HPXML::LocationXXX)
             :interior_adjacent_to,                   # [String] InteriorAdjacentTo (HPXML::LocationXXX)
             :type,                                   # [String] Type (HPXML::FoundationWallTypeXXX)
             :length,                                 # [Double] Length (ft)
             :height,                                 # [Double] Height (ft)
             :area,                                   # [Double] Area (ft2)
             :orientation,                            # [String] Orientation (HPXML::OrientationXXX)
             :azimuth,                                # [Integer] Azimuth (deg)
             :thickness,                              # [Double] Thickness (in)
             :depth_below_grade,                      # [Double] DepthBelowGrade (ft)
             :interior_finish_type,                   # [String] InteriorFinish/Type (HPXML::InteriorFinishXXX)
             :interior_finish_thickness,              # [Double] InteriorFinish/Thickness (in)
             :insulation_id,                          # [String] Insulation/SystemIdentifier/@id
             :insulation_assembly_r_value,            # [Double] Insulation/AssemblyEffectiveRValue (F-ft2-hr/Btu)
             :insulation_exterior_r_value,            # [Double] Insulation/Layer[InstallationType="continuous - exterior"]/NominalRValue (F-ft2-hr/Btu)
             :insulation_exterior_distance_to_top,    # [Double] Insulation/Layer[InstallationType="continuous - exterior"]/DistanceToTopOfInsulation (ft)
             :insulation_exterior_distance_to_bottom, # [Double] Insulation/Layer[InstallationType="continuous - exterior"]/DistanceToBottomOfInsulation (ft)
             :insulation_interior_r_value,            # [Double] Insulation/Layer[InstallationType="continuous - interior"]/NominalRValue (F-ft2-hr/Btu)
             :insulation_interior_distance_to_top,    # [Double] Insulation/Layer[InstallationType="continuous - interior"]/DistanceToTopOfInsulation (ft)
             :insulation_interior_distance_to_bottom] # [Double] Insulation/Layer[InstallationType="continuous - interior"]/DistanceToBottomOfInsulation (ft)
    attr_accessor(*ATTRS)

    # Returns the same foundation wall specified in other places.
    #
    # @return [<HPXML::FoundationWall>] FoundationWall object linked by sameas attribute
    def sameas
      return HPXML::get_sameas_obj(@parent_object, self)
    end

    # Returns all windows for this foundation wall.
    #
    # @return [Array<HPXML::Window>] List of window objects
    def windows
      return @parent_object.windows.select { |window| window.attached_to_wall_idref == @id }
    end

    # Returns all doors for this foundation wall.
    #
    # @return [Array<HPXML::Door>] List of door objects
    def doors
      return @parent_object.doors.select { |door| door.attached_to_wall_idref == @id }
    end

    # Returns the space that the foundation wall is attached to.
    #
    # @return [HPXML::Space] Space object
    def space
      return if @attached_to_space_idref.nil?

      @parent_object.zones.each do |z|
        z.spaces.each do |s|
          return s if s.id == @attached_to_space_idref
        end
      end

      fail "Attached space '#{@attached_to_space_idref}' not found for foundation wall '#{@id}'."
    end

    # Calculates the net area (gross area minus subsurface area).
    #
    # @return [Double] Net area (ft2)
    def net_area
      val = @area.nil? ? @length * @height : @area
      (@parent_object.windows + @parent_object.doors).each do |subsurface|
        next unless subsurface.attached_to_wall_idref == @id

        val -= subsurface.area
      end
      fail "Calculated a negative net surface area for surface '#{@id}'." if val < 0

      return val
    end

    # Calculates the above-grade gross area.
    #
    # @return [Double] Above-grade gross area (ft2)
    def above_grade_area
      gross_area = @area.nil? ? @length * @height : @area
      ag_frac = (@height - @depth_below_grade) / @height
      return gross_area * ag_frac
    end

    # Calculates the below-grade area.
    #
    # @return [Double] Below-grade area (ft2)
    def below_grade_area
      gross_area = @area.nil? ? @length * @height : @area
      return gross_area - above_grade_area
    end

    # Calculates the above-grade net area (net area minus below grade area).
    #
    # @return [Double] Above-grade net area (ft2)
    def above_grade_net_area
      return net_area - below_grade_area
    end

    # Returns all slabs that are adjacent to the same HPXML::LocationXXX as the connected
    # foundation walls.
    # FUTURE: Is this just returning slabs with the same interior_adjacent_to as this slab?
    #
    # @return [Array<HPXML::Slab>] List of connected slabs
    def connected_slabs
      return @parent_object.slabs.select { |s| s.connected_foundation_walls.include? self }
    end

    # Estimates the fraction of the foundation wall's length that is along exposed perimeter.
    #
    # @return [Double] Exposed fraction
    def exposed_fraction
      # Calculate total slab exposed perimeter
      slab_exposed_length = connected_slabs.select { |s| s.interior_adjacent_to == interior_adjacent_to }.map { |s| s.exposed_perimeter }.sum

      # Calculate total length of exterior foundation walls
      ext_adjacent_fnd_walls = connected_slabs.map { |s| s.connected_foundation_walls.select { |fw| fw.is_exterior } }.flatten.uniq
      wall_total_length = ext_adjacent_fnd_walls.map { |fw| fw.area / fw.height }.sum

      # Calculate exposed fraction
      if slab_exposed_length < wall_total_length
        return slab_exposed_length / wall_total_length
      end

      return 1.0
    end

    # Returns whether the foundation wall is an exterior surface (i.e., adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an exterior surface
    def is_exterior
      return @exterior_adjacent_to == LocationGround
    end

    # Returns whether the foundation wall is an interior surface (i.e., NOT adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an interior surface
    def is_interior
      return !is_exterior
    end

    # Returns whether the foundation wall is determined to be adiabatic.
    #
    # @return [Boolean] True if adiabatic
    def is_adiabatic
      return HPXML::is_adiabatic(self)
    end

    # Returns whether the foundation wall is between conditioned space and outside/ground/unconditioned space.
    # Note: The location of insulation is not considered here, so an insulated foundation wall of an
    # unconditioned basement, for example, returns false.
    #
    # @return [Boolean] True if a thermal boundary surface
    def is_thermal_boundary
      return HPXML::is_thermal_boundary(self)
    end

    # Returns whether the foundation wall is both an exterior surface and a thermal boundary surface.
    #
    # @return [Boolean] True if an exterior, thermal boundary surface
    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    # Returns whether the foundation wall is adjacent to conditioned space.
    #
    # @return [Boolean] True if adjacent to conditioned space
    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.foundation_walls.delete(self)
      windows.reverse_each do |window|
        window.delete
      end
      doors.reverse_each do |door|
        door.delete
      end
      @parent_object.foundations.each do |foundation|
        foundation.attached_to_foundation_wall_idrefs.delete(@id) unless foundation.attached_to_foundation_wall_idrefs.nil?
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      if not sameas_id
        begin; net_area; rescue StandardError => e; errors << e.message; end
      else
        begin; sameas; rescue StandardError => e; errors << e.message; end
      end
      begin; space; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      foundation_walls = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'FoundationWalls'])
      foundation_wall = XMLHelper.add_element(foundation_walls, 'FoundationWall')
      sys_id = XMLHelper.add_element(foundation_wall, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?

      if not @attached_to_space_idref.nil?
        space_attached = XMLHelper.add_element(foundation_wall, 'AttachedToSpace')
        XMLHelper.add_attribute(space_attached, 'idref', @attached_to_space_idref)
      end
      XMLHelper.add_element(foundation_wall, 'ExteriorAdjacentTo', @exterior_adjacent_to, :string) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(foundation_wall, 'InteriorAdjacentTo', @interior_adjacent_to, :string) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(foundation_wall, 'Type', @type, :string, @type_isdefaulted) unless @type.nil?
      XMLHelper.add_element(foundation_wall, 'Length', @length, :float) unless @length.nil?
      XMLHelper.add_element(foundation_wall, 'Height', @height, :float) unless @height.nil?
      XMLHelper.add_element(foundation_wall, 'Area', @area, :float, @area_isdefaulted) unless @area.nil?
      XMLHelper.add_element(foundation_wall, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      XMLHelper.add_element(foundation_wall, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(foundation_wall, 'Thickness', @thickness, :float, @thickness_isdefaulted) unless @thickness.nil?
      XMLHelper.add_element(foundation_wall, 'DepthBelowGrade', @depth_below_grade, :float) unless @depth_below_grade.nil?
      if (not @interior_finish_type.nil?) || (not @interior_finish_thickness.nil?)
        interior_finish = XMLHelper.add_element(foundation_wall, 'InteriorFinish')
        XMLHelper.add_element(interior_finish, 'Type', @interior_finish_type, :string, @interior_finish_type_isdefaulted) unless @interior_finish_type.nil?
        XMLHelper.add_element(interior_finish, 'Thickness', @interior_finish_thickness, :float, @interior_finish_thickness_isdefaulted) unless @interior_finish_thickness.nil?
      end
      if (not @insulation_id.nil?) || (not @insulation_assembly_r_value.nil?) || (not @insulation_exterior_r_value.nil?) || (not @insulation_interior_r_value.nil?)
        insulation = XMLHelper.add_element(foundation_wall, 'Insulation')
        sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
        if not @insulation_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
        end
        XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', @insulation_assembly_r_value, :float) unless @insulation_assembly_r_value.nil?
        if not @insulation_exterior_r_value.nil?
          layer = XMLHelper.add_element(insulation, 'Layer')
          XMLHelper.add_element(layer, 'InstallationType', 'continuous - exterior', :string)
          XMLHelper.add_element(layer, 'NominalRValue', @insulation_exterior_r_value, :float)
          XMLHelper.add_element(layer, 'DistanceToTopOfInsulation', @insulation_exterior_distance_to_top, :float, @insulation_exterior_distance_to_top_isdefaulted) unless @insulation_exterior_distance_to_top.nil?
          XMLHelper.add_element(layer, 'DistanceToBottomOfInsulation', @insulation_exterior_distance_to_bottom, :float, @insulation_exterior_distance_to_bottom_isdefaulted) unless @insulation_exterior_distance_to_bottom.nil?
        end
        if not @insulation_interior_r_value.nil?
          layer = XMLHelper.add_element(insulation, 'Layer')
          XMLHelper.add_element(layer, 'InstallationType', 'continuous - interior', :string)
          XMLHelper.add_element(layer, 'NominalRValue', @insulation_interior_r_value, :float)
          XMLHelper.add_element(layer, 'DistanceToTopOfInsulation', @insulation_interior_distance_to_top, :float, @insulation_interior_distance_to_top_isdefaulted) unless @insulation_interior_distance_to_top.nil?
          XMLHelper.add_element(layer, 'DistanceToBottomOfInsulation', @insulation_interior_distance_to_bottom, :float, @insulation_interior_distance_to_bottom_isdefaulted) unless @insulation_interior_distance_to_bottom.nil?
        end
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param foundation_wall [Oga::XML::Element] The current FoundationWall XML element
    # @return [nil]
    def from_doc(foundation_wall)
      return if foundation_wall.nil?

      @id = HPXML::get_id(foundation_wall)
      @sameas_id = HPXML::get_sameas_id(foundation_wall)
      @exterior_adjacent_to = XMLHelper.get_value(foundation_wall, 'ExteriorAdjacentTo', :string)
      @interior_adjacent_to = XMLHelper.get_value(foundation_wall, 'InteriorAdjacentTo', :string)
      @type = XMLHelper.get_value(foundation_wall, 'Type', :string)
      @length = XMLHelper.get_value(foundation_wall, 'Length', :float)
      @height = XMLHelper.get_value(foundation_wall, 'Height', :float)
      @area = XMLHelper.get_value(foundation_wall, 'Area', :float)
      @orientation = XMLHelper.get_value(foundation_wall, 'Orientation', :string)
      @azimuth = XMLHelper.get_value(foundation_wall, 'Azimuth', :integer)
      @thickness = XMLHelper.get_value(foundation_wall, 'Thickness', :float)
      @depth_below_grade = XMLHelper.get_value(foundation_wall, 'DepthBelowGrade', :float)
      interior_finish = XMLHelper.get_element(foundation_wall, 'InteriorFinish')
      if not interior_finish.nil?
        @interior_finish_type = XMLHelper.get_value(interior_finish, 'Type', :string)
        @interior_finish_thickness = XMLHelper.get_value(interior_finish, 'Thickness', :float)
      end
      insulation = XMLHelper.get_element(foundation_wall, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_assembly_r_value = XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue', :float)
        @insulation_interior_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - interior']/NominalRValue", :float)
        @insulation_interior_distance_to_top = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - interior']/DistanceToTopOfInsulation", :float)
        @insulation_interior_distance_to_bottom = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - interior']/DistanceToBottomOfInsulation", :float)
        @insulation_exterior_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - exterior']/NominalRValue", :float)
        @insulation_exterior_distance_to_top = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - exterior']/DistanceToTopOfInsulation", :float)
        @insulation_exterior_distance_to_bottom = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous - exterior']/DistanceToBottomOfInsulation", :float)
      end
      @attached_to_space_idref = HPXML::get_idref(XMLHelper.get_elements(foundation_wall, 'AttachedToSpace')[0])
    end
  end

  # Array of HPXML::Floor objects.
  class Floors < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Floor.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Floors/Floor').each do |floor|
        self << Floor.new(@parent_object, floor)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/Floors/Floor.
  class Floor < BaseElement
    ATTRS = [:id,                             # [String] SystemIdentifier/@id
             :sameas_id,                      # [String] SystemIdentifier/@sameas
             :attached_to_space_idref,        # [String] AttachedToSpace/@idref
             :exterior_adjacent_to,           # [String] ExteriorAdjacentTo (HPXML::LocationXXX)
             :interior_adjacent_to,           # [String] InteriorAdjacentTo (HPXML::LocationXXX)
             :floor_or_ceiling,               # [String] FloorOrCeiling (HPXML::FloorOrCeilingXXX)
             :floor_type,                     # [String] FloorType/* (HPXML::FloorTypeXXX)
             :framing_size,                   # [String] FloorJoists/Size
             :framing_spacing,                # [Double] FloorJoists/Spacing (in)
             :framing_factor,                 # [Double] FloorJoists/FramingFactor (frac)
             :area,                           # [Double] Area (ft2)
             :interior_finish_type,           # [String] InteriorFinish/Type (HPXML::InteriorFinishXXX)
             :interior_finish_thickness,      # [Double] InteriorFinish/Thickness (in)
             :radiant_barrier,                # [Boolean] RadiantBarrier
             :radiant_barrier_grade,          # [Integer] RadiantBarrierGrade
             :insulation_id,                  # [String] Insulation/SystemIdentifier/@id
             :insulation_grade,               # [Integer] Insulation/InsulationGrade
             :insulation_assembly_r_value,    # [Double] Insulation/AssemblyEffectiveRValue (F-ft2-hr/Btu)
             :insulation_cavity_r_value,      # [Double] Insulation/Layer[InstallationType="cavity"]/NominalRValue (F-ft2-hr/Btu)
             :insulation_continuous_r_value]  # [Double] Insulation/Layer[InstallationType="continuous"]/NominalRValue (F-ft2-hr/Btu)
    attr_accessor(*ATTRS)

    # Returns the same floor specified in other places.
    #
    # @return [<HPXML::Floor>] Floor object linked by sameas attribute
    def sameas
      return HPXML::get_sameas_obj(@parent_object, self)
    end

    # Returns all skylights for this floor.
    #
    # @return [Array<HPXML::Skylight>] List of skylight objects
    def skylights
      return @parent_object.skylights.select { |skylight| skylight.attached_to_floor_idref == @id }
    end

    # Returns the space that the floor is attached to.
    #
    # @return [HPXML::Space] Space object
    def space
      return if @attached_to_space_idref.nil?

      @parent_object.zones.each do |z|
        z.spaces.each do |s|
          return s if s.id == @attached_to_space_idref
        end
      end

      fail "Attached space '#{@attached_to_space_idref}' not found for floor '#{@id}'."
    end

    # Calculates the net area (gross area minus subsurface area).
    #
    # @return [Double] Net area (ft2)
    def net_area
      val = @area
      skylights.each do |skylight|
        val -= skylight.area
      end
      fail "Calculated a negative net surface area for surface '#{@id}'." if val < 0

      return val
    end

    # Returns whether the HPXML::Floor object represents a ceiling or floor
    # from the perspective of the conditioned space.
    #
    # For example, the surface above an unconditioned basement is a floor.
    # The surface below an attic is a ceiling.
    #
    # @return [Boolean] True if the surface is a ceiling
    def is_ceiling
      if @floor_or_ceiling.nil?
        return HPXML::is_floor_a_ceiling(self, true)
      else
        return @floor_or_ceiling == FloorOrCeilingCeiling
      end
    end

    # Returns whether the HPXML::Floor object represents a ceiling or floor
    # from the perspective of the conditioned space.
    #
    # For example, the surface above an unconditioned basement is a floor.
    # The surface below an attic is a ceiling.
    #
    # @return [Boolean] True if the surface is a floor
    def is_floor
      return !is_ceiling
    end

    # Returns whether the floor is an exterior surface (i.e., adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an exterior surface
    def is_exterior
      return [LocationOutside, LocationManufacturedHomeUnderBelly].include?(@exterior_adjacent_to)
    end

    # Returns whether the floor is an interior surface (i.e., NOT adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an interior surface
    def is_interior
      return !is_exterior
    end

    # Returns whether the floor is determined to be adiabatic.
    #
    # @return [Boolean] True if adiabatic
    def is_adiabatic
      return HPXML::is_adiabatic(self)
    end

    # Returns whether the floor is between conditioned space and outside/unconditioned space.
    # Note: The location of insulation is not considered here, so an insulated floor of a
    # garage, for example, returns false.
    #
    # @return [Boolean] True if a thermal boundary surface
    def is_thermal_boundary
      return HPXML::is_thermal_boundary(self)
    end

    # Returns whether the floor is both an exterior surface and a thermal boundary surface.
    #
    # @return [Boolean] True if an exterior, thermal boundary surface
    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    # Returns whether the floor is adjacent to conditioned space.
    #
    # @return [Boolean] True if adjacent to conditioned space
    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.floors.delete(self)
      skylights.reverse_each do |skylight|
        skylight.delete
      end
      @parent_object.attics.each do |attic|
        attic.attached_to_floor_idrefs.delete(@id) unless attic.attached_to_floor_idrefs.nil?
      end
      @parent_object.foundations.each do |foundation|
        foundation.attached_to_floor_idrefs.delete(@id) unless foundation.attached_to_floor_idrefs.nil?
      end
      @parent_object.attics.each do |attic|
        attic.attached_to_floor_idrefs.delete(@id) unless attic.attached_to_floor_idrefs.nil?
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      if not sameas_id
        begin; net_area; rescue StandardError => e; errors << e.message; end
      else
        begin; sameas; rescue StandardError => e; errors << e.message; end
      end
      begin; space; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      floors = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Floors'])
      floor = XMLHelper.add_element(floors, 'Floor')
      sys_id = XMLHelper.add_element(floor, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?

      if not @attached_to_space_idref.nil?
        space_attached = XMLHelper.add_element(floor, 'AttachedToSpace')
        XMLHelper.add_attribute(space_attached, 'idref', @attached_to_space_idref)
      end
      XMLHelper.add_element(floor, 'ExteriorAdjacentTo', @exterior_adjacent_to, :string) unless @exterior_adjacent_to.nil?
      XMLHelper.add_element(floor, 'InteriorAdjacentTo', @interior_adjacent_to, :string) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(floor, 'FloorOrCeiling', @floor_or_ceiling, :string, @floor_or_ceiling_isdefaulted) unless @floor_or_ceiling.nil?
      if not @floor_type.nil?
        floor_type_el = XMLHelper.add_element(floor, 'FloorType')
        XMLHelper.add_element(floor_type_el, @floor_type)
      end
      if (not @framing_factor.nil?) || (not @framing_size.nil?) || (not @framing_spacing.nil?)
        joists = XMLHelper.add_element(floor, 'FloorJoists')
        XMLHelper.add_element(joists, 'Size', @framing_size, :string) unless @framing_size.nil?
        XMLHelper.add_element(joists, 'Spacing', @framing_spacing, :float) unless @framing_spacing.nil?
        XMLHelper.add_element(joists, 'FramingFactor', @framing_factor, :float) unless @framing_factor.nil?
      end
      XMLHelper.add_element(floor, 'Area', @area, :float) unless @area.nil?
      if (not @interior_finish_type.nil?) || (not @interior_finish_thickness.nil?)
        interior_finish = XMLHelper.add_element(floor, 'InteriorFinish')
        XMLHelper.add_element(interior_finish, 'Type', @interior_finish_type, :string, @interior_finish_type_isdefaulted) unless @interior_finish_type.nil?
        XMLHelper.add_element(interior_finish, 'Thickness', @interior_finish_thickness, :float, @interior_finish_thickness_isdefaulted) unless @interior_finish_thickness.nil?
      end
      XMLHelper.add_element(floor, 'RadiantBarrier', @radiant_barrier, :boolean, @radiant_barrier_isdefaulted) unless @radiant_barrier.nil?
      XMLHelper.add_element(floor, 'RadiantBarrierGrade', @radiant_barrier_grade, :integer, @radiant_barrier_grade_isdefaulted) unless @radiant_barrier_grade.nil?
      if (not @insulation_id.nil?) || (not @insulation_grade.nil?) || (not @insulation_assembly_r_value.nil?) || (not @insulation_cavity_r_value.nil?) || (not @insulation_continuous_r_value.nil?)
        insulation = XMLHelper.add_element(floor, 'Insulation')
        sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
        if not @insulation_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @insulation_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Insulation')
        end
        XMLHelper.add_element(insulation, 'InsulationGrade', @insulation_grade, :integer) unless @insulation_grade.nil?
        XMLHelper.add_element(insulation, 'AssemblyEffectiveRValue', @insulation_assembly_r_value, :float) unless @insulation_assembly_r_value.nil?
        if not @insulation_cavity_r_value.nil?
          layer = XMLHelper.add_element(insulation, 'Layer')
          XMLHelper.add_element(layer, 'InstallationType', 'cavity', :string)
          XMLHelper.add_element(layer, 'NominalRValue', @insulation_cavity_r_value, :float)
        end
        if not @insulation_continuous_r_value.nil?
          layer = XMLHelper.add_element(insulation, 'Layer')
          XMLHelper.add_element(layer, 'InstallationType', 'continuous', :string)
          XMLHelper.add_element(layer, 'NominalRValue', @insulation_continuous_r_value, :float)
        end
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param floor [Oga::XML::Element] The current Floor XML element
    # @return [nil]
    def from_doc(floor)
      return if floor.nil?

      @id = HPXML::get_id(floor)
      @sameas_id = HPXML::get_sameas_id(floor)
      @exterior_adjacent_to = XMLHelper.get_value(floor, 'ExteriorAdjacentTo', :string)
      @interior_adjacent_to = XMLHelper.get_value(floor, 'InteriorAdjacentTo', :string)
      @floor_or_ceiling = XMLHelper.get_value(floor, 'FloorOrCeiling', :string)
      @floor_type = XMLHelper.get_child_name(floor, 'FloorType')
      @framing_size = XMLHelper.get_value(floor, 'FloorJoists/Size', :string)
      @framing_spacing = XMLHelper.get_value(floor, 'FloorJoists/Spacing', :float)
      @framing_factor = XMLHelper.get_value(floor, 'FloorJoists/FramingFactor', :float)
      @area = XMLHelper.get_value(floor, 'Area', :float)
      interior_finish = XMLHelper.get_element(floor, 'InteriorFinish')
      if not interior_finish.nil?
        @interior_finish_type = XMLHelper.get_value(interior_finish, 'Type', :string)
        @interior_finish_thickness = XMLHelper.get_value(interior_finish, 'Thickness', :float)
      end
      @radiant_barrier = XMLHelper.get_value(floor, 'RadiantBarrier', :boolean)
      @radiant_barrier_grade = XMLHelper.get_value(floor, 'RadiantBarrierGrade', :integer)
      insulation = XMLHelper.get_element(floor, 'Insulation')
      if not insulation.nil?
        @insulation_id = HPXML::get_id(insulation)
        @insulation_grade = XMLHelper.get_value(insulation, 'InsulationGrade', :float)
        @insulation_assembly_r_value = XMLHelper.get_value(insulation, 'AssemblyEffectiveRValue', :float)
        @insulation_cavity_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='cavity']/NominalRValue", :float)
        @insulation_continuous_r_value = XMLHelper.get_value(insulation, "Layer[InstallationType='continuous']/NominalRValue", :float)
      end
      @attached_to_space_idref = HPXML::get_idref(XMLHelper.get_elements(floor, 'AttachedToSpace')[0])
    end
  end

  # Array of HPXML::Slab objects.
  class Slabs < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Slab.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Slabs/Slab').each do |slab|
        self << Slab.new(@parent_object, slab)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/Slabs/Slab.
  class Slab < BaseElement
    ATTRS = [:id,                                               # [String] SystemIdentifier/@id
             :sameas_id,                                        # [String] SystemIdentifier/@sameas
             :attached_to_space_idref,                          # [String] AttachedToSpace/@idref
             :interior_adjacent_to,                             # [String] InteriorAdjacentTo (HPXML::LocationXXX)
             :area,                                             # [Double] Area (ft2)
             :thickness,                                        # [Double] Thickness (in)
             :exposed_perimeter,                                # [Double] ExposedPerimeter (ft)
             :depth_below_grade,                                # [Double] DepthBelowGrade (ft)
             :perimeter_insulation_id,                          # [String] PerimeterInsulation/SystemIdentifier/@id
             :perimeter_insulation_r_value,                     # [Double] PerimeterInsulation/Layer/NominalRValue (F-ft2-hr/Btu)
             :perimeter_insulation_depth,                       # [Double] PerimeterInsulation/Layer/InsulationDepth (ft)
             :exterior_horizontal_insulation_id,                # [String] ExteriorHorizontalInsulation/SystemIdentifier/@id
             :exterior_horizontal_insulation_r_value,           # [Double] ExteriorHorizontalInsulation/Layer/NominalRValue (F-ft2-hr/Btu)
             :exterior_horizontal_insulation_width,             # [Double] ExteriorHorizontalInsulation/Layer/InsulationWidth (ft)
             :exterior_horizontal_insulation_depth_below_grade, # [Double] ExteriorHorizontalInsulation/Layer/InsulationDepthBelowGrade (ft)
             :under_slab_insulation_id,                         # [String] UnderSlabInsulation/SystemIdentifier/@id
             :under_slab_insulation_r_value,                    # [Double] UnderSlabInsulation/Layer/NominalRValue (F-ft2-hr/Btu)
             :under_slab_insulation_width,                      # [Double] UnderSlabInsulation/Layer/InsulationWidth (ft)
             :under_slab_insulation_spans_entire_slab,          # [Boolean] UnderSlabInsulation/Layer/InsulationSpansEntireSlab
             :gap_insulation_r_value,                           # [Double] extension/GapInsulationRValue (F-ft2-hr/Btu)
             :carpet_fraction,                                  # [Double] extension/CarpetFraction (frac)
             :carpet_r_value]                                   # [Double] extension/CarpetRValue (F-ft2-hr/Btu)
    attr_accessor(*ATTRS)

    # Returns the space that the slab is attached to.
    #
    # @return [HPXML::Space] Space object
    def space
      return if @attached_to_space_idref.nil?

      @parent_object.zones.each do |z|
        z.spaces.each do |s|
          return s if s.id == @attached_to_space_idref
        end
      end

      fail "Attached space '#{@attached_to_space_idref}' not found for slab '#{@id}'."
    end

    # Returns the assumed exterior adjacent to location.
    #
    # @return [String] Exterior adjacent to location (HPXML::LocationXXX)
    def exterior_adjacent_to
      return LocationGround
    end

    # Returns whether the slab is an exterior surface (i.e., adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an exterior surface
    def is_exterior
      return true
    end

    # Returns whether the slab is an interior surface (i.e., NOT adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an interior surface
    def is_interior
      return !is_exterior
    end

    # Returns whether the slab is between conditioned space and ground.
    # Note: The location of insulation is not considered here, so an insulated slab of a
    # garage, for example, returns false.
    #
    # @return [Boolean] True if a thermal boundary surface
    def is_thermal_boundary
      return HPXML::is_thermal_boundary(self)
    end

    # Returns whether the slab is both an exterior surface and a thermal boundary surface.
    #
    # @return [Boolean] True if an exterior, thermal boundary surface
    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    # Returns whether the slab is adjacent to conditioned space.
    #
    # @return [Boolean] True if adjacent to conditioned space
    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    # Returns all foundation walls that are adjacent to the same HPXML::LocationXXX as the slab.
    #
    # @return [Array<HPXML::FoundationWall>] List of connected foundation walls
    def connected_foundation_walls
      return @parent_object.foundation_walls.select { |fw| [fw.interior_adjacent_to, fw.exterior_adjacent_to].include? interior_adjacent_to }
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.slabs.delete(self)
      @parent_object.foundations.each do |foundation|
        foundation.attached_to_slab_idrefs.delete(@id) unless foundation.attached_to_slab_idrefs.nil?
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; space; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      slabs = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Slabs'])
      slab = XMLHelper.add_element(slabs, 'Slab')
      sys_id = XMLHelper.add_element(slab, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      if not @attached_to_space_idref.nil?
        space_attached = XMLHelper.add_element(slab, 'AttachedToSpace')
        XMLHelper.add_attribute(space_attached, 'idref', @attached_to_space_idref)
      end
      XMLHelper.add_element(slab, 'InteriorAdjacentTo', @interior_adjacent_to, :string) unless @interior_adjacent_to.nil?
      XMLHelper.add_element(slab, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(slab, 'Thickness', @thickness, :float, @thickness_isdefaulted) unless @thickness.nil?
      XMLHelper.add_element(slab, 'ExposedPerimeter', @exposed_perimeter, :float) unless @exposed_perimeter.nil?
      XMLHelper.add_element(slab, 'DepthBelowGrade', @depth_below_grade, :float, @depth_below_grade_isdefaulted) unless @depth_below_grade.nil?

      if (not @perimeter_insulation_id.nil?) || (not @perimeter_insulation_r_value.nil?) || (not @perimeter_insulation_depth.nil?)
        insulation = XMLHelper.add_element(slab, 'PerimeterInsulation')
        sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
        if not @perimeter_insulation_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @perimeter_insulation_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'PerimeterInsulation')
        end
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'NominalRValue', @perimeter_insulation_r_value, :float, @perimeter_insulation_r_value_isdefaulted) unless @perimeter_insulation_r_value.nil?
        XMLHelper.add_element(layer, 'InsulationDepth', @perimeter_insulation_depth, :float, @perimeter_insulation_depth_isdefaulted) unless @perimeter_insulation_depth.nil?
      end

      if (not @exterior_horizontal_insulation_id.nil?) || (not @exterior_horizontal_insulation_r_value.nil?) || (not @exterior_horizontal_insulation_width.nil?) || (not @exterior_horizontal_insulation_depth_below_grade.nil?)
        insulation = XMLHelper.add_element(slab, 'ExteriorHorizontalInsulation')
        sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
        if not @exterior_horizontal_insulation_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @exterior_horizontal_insulation_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'ExteriorHorizontalInsulation')
        end
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'NominalRValue', @exterior_horizontal_insulation_r_value, :float, @exterior_horizontal_insulation_r_value_isdefaulted) unless @exterior_horizontal_insulation_r_value.nil?
        XMLHelper.add_element(layer, 'InsulationWidth', @exterior_horizontal_insulation_width, :float, @exterior_horizontal_insulation_width_isdefaulted) unless @exterior_horizontal_insulation_width.nil?
        XMLHelper.add_element(layer, 'InsulationDepthBelowGrade', @exterior_horizontal_insulation_depth_below_grade, :float, @exterior_horizontal_insulation_depth_below_grade_isdefaulted) unless @exterior_horizontal_insulation_depth_below_grade.nil?
      end

      if (not @under_slab_insulation_id.nil?) || (not @under_slab_insulation_r_value.nil?) || (not @under_slab_insulation_width.nil?) || (not @under_slab_insulation_spans_entire_slab.nil?)
        insulation = XMLHelper.add_element(slab, 'UnderSlabInsulation')
        sys_id = XMLHelper.add_element(insulation, 'SystemIdentifier')
        if not @under_slab_insulation_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @under_slab_insulation_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'UnderSlabInsulation')
        end
        layer = XMLHelper.add_element(insulation, 'Layer')
        XMLHelper.add_element(layer, 'NominalRValue', @under_slab_insulation_r_value, :float, @under_slab_insulation_r_value_isdefaulted) unless @under_slab_insulation_r_value.nil?
        XMLHelper.add_element(layer, 'InsulationWidth', @under_slab_insulation_width, :float, @under_slab_insulation_width_isdefaulted) unless @under_slab_insulation_width.nil?
        XMLHelper.add_element(layer, 'InsulationSpansEntireSlab', @under_slab_insulation_spans_entire_slab, :boolean, @under_slab_insulation_spans_entire_slab_isdefaulted) unless @under_slab_insulation_spans_entire_slab.nil?
      end

      XMLHelper.add_extension(slab, 'GapInsulationRValue', @gap_insulation_r_value, :float, @gap_insulation_r_value_isdefaulted) unless @gap_insulation_r_value.nil?
      XMLHelper.add_extension(slab, 'CarpetFraction', @carpet_fraction, :float, @carpet_fraction_isdefaulted) unless @carpet_fraction.nil?
      XMLHelper.add_extension(slab, 'CarpetRValue', @carpet_r_value, :float, @carpet_r_value_isdefaulted) unless @carpet_r_value.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param slab [Oga::XML::Element] The current Slab XML element
    # @return [nil]
    def from_doc(slab)
      return if slab.nil?

      @id = HPXML::get_id(slab)
      @interior_adjacent_to = XMLHelper.get_value(slab, 'InteriorAdjacentTo', :string)
      @area = XMLHelper.get_value(slab, 'Area', :float)
      @thickness = XMLHelper.get_value(slab, 'Thickness', :float)
      @exposed_perimeter = XMLHelper.get_value(slab, 'ExposedPerimeter', :float)
      @depth_below_grade = XMLHelper.get_value(slab, 'DepthBelowGrade', :float)
      perimeter_insulation = XMLHelper.get_element(slab, 'PerimeterInsulation')
      if not perimeter_insulation.nil?
        @perimeter_insulation_id = HPXML::get_id(perimeter_insulation)
        @perimeter_insulation_r_value = XMLHelper.get_value(perimeter_insulation, 'Layer/NominalRValue', :float)
        @perimeter_insulation_depth = XMLHelper.get_value(perimeter_insulation, 'Layer/InsulationDepth', :float)
      end

      exterior_horizontal_insulation = XMLHelper.get_element(slab, 'ExteriorHorizontalInsulation')
      if not exterior_horizontal_insulation.nil?
        @exterior_horizontal_insulation_id = HPXML::get_id(exterior_horizontal_insulation)
        @exterior_horizontal_insulation_r_value = XMLHelper.get_value(exterior_horizontal_insulation, 'Layer/NominalRValue', :float)
        @exterior_horizontal_insulation_width = XMLHelper.get_value(exterior_horizontal_insulation, 'Layer/InsulationWidth', :float)
        @exterior_horizontal_insulation_depth_below_grade = XMLHelper.get_value(exterior_horizontal_insulation, 'Layer/InsulationDepthBelowGrade', :float)
      end

      under_slab_insulation = XMLHelper.get_element(slab, 'UnderSlabInsulation')
      if not under_slab_insulation.nil?
        @under_slab_insulation_id = HPXML::get_id(under_slab_insulation)
        @under_slab_insulation_r_value = XMLHelper.get_value(under_slab_insulation, 'Layer/NominalRValue', :float)
        @under_slab_insulation_width = XMLHelper.get_value(under_slab_insulation, 'Layer/InsulationWidth', :float)
        @under_slab_insulation_spans_entire_slab = XMLHelper.get_value(under_slab_insulation, 'Layer/InsulationSpansEntireSlab', :boolean)
      end
      @gap_insulation_r_value = XMLHelper.get_value(slab, 'extension/GapInsulationRValue', :float)
      @carpet_fraction = XMLHelper.get_value(slab, 'extension/CarpetFraction', :float)
      @carpet_r_value = XMLHelper.get_value(slab, 'extension/CarpetRValue', :float)
      @attached_to_space_idref = HPXML::get_idref(XMLHelper.get_elements(slab, 'AttachedToSpace')[0])
    end
  end

  # Array of HPXML::Window objects.
  class Windows < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Window.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Windows/Window').each do |window|
        self << Window.new(@parent_object, window)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/Windows/Window.
  class Window < BaseElement
    ATTRS = [:id,                                             # [String] SystemIdentifier/@id
             :sameas_id,                                      # [String] SystemIdentifier/@sameas
             :area,                                           # [Double] Area (ft2)
             :azimuth,                                        # [Integer] Azimuth (deg)
             :orientation,                                    # [String] Orientation (HPXML::OrientationXXX)
             :frame_type,                                     # [String] FrameType/* (HPXML::WindowFrameTypeXXX)
             :thermal_break,                                  # [Boolean] FrameType/*/ThermalBreak
             :glass_layers,                                   # [String] GlassLayers (HPXML::WindowLayersXXX)
             :glass_type,                                     # [String] GlassType (HPXML::WindowGlassTypeXXX)
             :gas_fill,                                       # [String] GasFill (HPXML::WindowGasXXX)
             :ufactor,                                        # [Double] UFactor (Btu/F-ft2-hr)
             :shgc,                                           # [Double] SHGC
             :exterior_shading_id,                            # [String] ExteriorShading/SystemIdentifier/@id
             :exterior_shading_type,                          # [String] ExteriorShading/Type (HPXML::ExteriorShadingTypeXXX)
             :exterior_shading_coverage_summer,               # [Double] ExteriorShading/SummerFractionCovered
             :exterior_shading_coverage_winter,               # [Double] ExteriorShading/WinterFractionCovered
             :exterior_shading_factor_summer,                 # [Double] ExteriorShading/SummerShadingCoefficient (frac)
             :exterior_shading_factor_winter,                 # [Double] ExteriorShading/WinterShadingCoefficient (frac)
             :interior_shading_id,                            # [String] InteriorShading/SystemIdentifier/@id
             :interior_shading_type,                          # [String] InteriorShading/Type (HPXML::InteriorShadingTypeXXX)
             :interior_shading_blinds_summer_closed_or_open,  # [String] InteriorShading/BlindsSummerClosedOrOpen (HPXML::BlindsXXX)
             :interior_shading_blinds_winter_closed_or_open,  # [String] InteriorShading/BlindsWinterClosedOrOpen (HPXML::BlindsXXX)
             :interior_shading_coverage_summer,               # [Double] InteriorShading/SummerFractionCovered
             :interior_shading_coverage_winter,               # [Double] InteriorShading/WinterFractionCovered
             :interior_shading_factor_summer,                 # [Double] InteriorShading/SummerShadingCoefficient (frac)
             :interior_shading_factor_winter,                 # [Double] InteriorShading/WinterShadingCoefficient (frac)
             :storm_id,                                       # [String] StormWindow/SystemIdentifier/@id
             :storm_type,                                     # [String] StormWindow/GlassType (HPXML::WindowGlassTypeXXX)
             :insect_screen_present,                          # [Element] InsectScreen
             :insect_screen_id,                               # [String] InsectScreen/SystemIdentifier/@id
             :insect_screen_location,                         # [String] InsectScreen/Location (HPXML::LocationXXX)
             :insect_screen_coverage_summer,                  # [Double] InsectScreen/SummerFractionCovered (frac)
             :insect_screen_coverage_winter,                  # [Double] InsectScreen/WinterFractionCovered (frac)
             :insect_screen_factor_summer,                    # [Double] InsectScreen/SummerShadingCoefficient (frac)
             :insect_screen_factor_winter,                    # [Double] InsectScreen/WinterShadingCoefficient (frac)
             :overhangs_depth,                                # [Double] Overhangs/Depth (ft)
             :overhangs_distance_to_top_of_window,            # [Double] Overhangs/DistanceToTopOfWindow (ft)
             :overhangs_distance_to_bottom_of_window,         # [Double] Overhangs/DistanceToBottomOfWindow (ft)
             :fraction_operable,                              # [Double] FractionOperable (frac)
             :performance_class,                              # [String] PerformanceClass (HPXML::WindowClassXXX)
             :attached_to_wall_idref]                         # [String] AttachedToWall/@idref
    attr_accessor(*ATTRS)

    # Returns the parent wall that includes this skylight.
    #
    # @return [HPXML::Wall] Parent wall surface
    def wall
      return if @attached_to_wall_idref.nil?

      (@parent_object.walls + @parent_object.foundation_walls).each do |wall|
        next unless wall.id == @attached_to_wall_idref

        return wall
      end
      fail "Attached wall '#{@attached_to_wall_idref}' not found for window '#{@id}'."
    end

    # Returns whether the window is on an exterior surface (i.e., adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an exterior surface
    def is_exterior
      return wall.is_exterior
    end

    # Returns whether the window is on an interior surface (i.e., NOT adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an interior surface
    def is_interior
      return !is_exterior
    end

    # Returns whether the window is on a thermal boundary parent surface.
    #
    # @return [Boolean] True if a thermal boundary surface
    def is_thermal_boundary
      return HPXML::is_thermal_boundary(wall)
    end

    # Returns whether the window's parent surface is both an exterior surface and a thermal boundary surface.
    #
    # @return [Boolean] True if an exterior, thermal boundary surface
    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    # Returns whether the window is on a surface adjacent to conditioned space.
    #
    # @return [Boolean] True if adjacent to conditioned space
    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.windows.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; wall; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      windows = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Windows'])
      window = XMLHelper.add_element(windows, 'Window')
      sys_id = XMLHelper.add_element(window, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(window, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(window, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(window, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      if not @frame_type.nil?
        frame_type_el = XMLHelper.add_element(window, 'FrameType')
        frame_type = XMLHelper.add_element(frame_type_el, @frame_type)
        if [HPXML::WindowFrameTypeAluminum, HPXML::WindowFrameTypeMetal].include? @frame_type
          XMLHelper.add_element(frame_type, 'ThermalBreak', @thermal_break, :boolean, @thermal_break_isdefaulted) unless @thermal_break.nil?
        end
      end
      XMLHelper.add_element(window, 'GlassLayers', @glass_layers, :string, @glass_layers_isdefaulted) unless @glass_layers.nil?
      XMLHelper.add_element(window, 'GlassType', @glass_type, :string, @glass_type_isdefaulted) unless @glass_type.nil?
      XMLHelper.add_element(window, 'GasFill', @gas_fill, :string, @gas_fill_isdefaulted) unless @gas_fill.nil?
      XMLHelper.add_element(window, 'UFactor', @ufactor, :float, @ufactor_isdefaulted) unless @ufactor.nil?
      XMLHelper.add_element(window, 'SHGC', @shgc, :float, @shgc_isdefaulted) unless @shgc.nil?
      if (not @exterior_shading_type.nil?) || (not @exterior_shading_factor_summer.nil?) || (not @exterior_shading_factor_winter.nil?) || (not @exterior_shading_coverage_summer.nil?) || (not @exterior_shading_coverage_winter.nil?)
        exterior_shading = XMLHelper.add_element(window, 'ExteriorShading')
        sys_id = XMLHelper.add_element(exterior_shading, 'SystemIdentifier')
        if @exterior_shading_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', "#{id}ExteriorShading")
        else
          XMLHelper.add_attribute(sys_id, 'id', @exterior_shading_id)
        end
        XMLHelper.add_element(exterior_shading, 'Type', @exterior_shading_type, :string, @exterior_shading_type_isdefaulted) unless @exterior_shading_type.nil?
        XMLHelper.add_element(exterior_shading, 'SummerFractionCovered', @exterior_shading_coverage_summer, :float, @exterior_shading_coverage_summer_isdefaulted) unless @exterior_shading_coverage_summer.nil?
        XMLHelper.add_element(exterior_shading, 'WinterFractionCovered', @exterior_shading_coverage_winter, :float, @exterior_shading_coverage_winter_isdefaulted) unless @exterior_shading_coverage_winter.nil?
        XMLHelper.add_element(exterior_shading, 'SummerShadingCoefficient', @exterior_shading_factor_summer, :float, @exterior_shading_factor_summer_isdefaulted) unless @exterior_shading_factor_summer.nil?
        XMLHelper.add_element(exterior_shading, 'WinterShadingCoefficient', @exterior_shading_factor_winter, :float, @exterior_shading_factor_winter_isdefaulted) unless @exterior_shading_factor_winter.nil?
      end
      if (not @interior_shading_type.nil?) || (not @interior_shading_factor_summer.nil?) || (not @interior_shading_factor_winter.nil?) || (not @interior_shading_blinds_summer_closed_or_open.nil?) || (not @interior_shading_blinds_winter_closed_or_open.nil?) || (not @interior_shading_coverage_summer.nil?) || (not @interior_shading_coverage_winter.nil?)
        interior_shading = XMLHelper.add_element(window, 'InteriorShading')
        sys_id = XMLHelper.add_element(interior_shading, 'SystemIdentifier')
        if @interior_shading_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', "#{id}InteriorShading")
        else
          XMLHelper.add_attribute(sys_id, 'id', @interior_shading_id)
        end
        XMLHelper.add_element(interior_shading, 'Type', @interior_shading_type, :string, @interior_shading_type_isdefaulted) unless @interior_shading_type.nil?
        XMLHelper.add_element(interior_shading, 'BlindsSummerClosedOrOpen', @interior_shading_blinds_summer_closed_or_open, :string, @interior_shading_blinds_summer_closed_or_open_isdefaulted) unless @interior_shading_blinds_summer_closed_or_open.nil?
        XMLHelper.add_element(interior_shading, 'BlindsWinterClosedOrOpen', @interior_shading_blinds_winter_closed_or_open, :string, @interior_shading_blinds_winter_closed_or_open_isdefaulted) unless @interior_shading_blinds_winter_closed_or_open.nil?
        XMLHelper.add_element(interior_shading, 'SummerFractionCovered', @interior_shading_coverage_summer, :float, @interior_shading_coverage_summer_isdefaulted) unless @interior_shading_coverage_summer.nil?
        XMLHelper.add_element(interior_shading, 'WinterFractionCovered', @interior_shading_coverage_winter, :float, @interior_shading_coverage_winter_isdefaulted) unless @interior_shading_coverage_winter.nil?
        XMLHelper.add_element(interior_shading, 'SummerShadingCoefficient', @interior_shading_factor_summer, :float, @interior_shading_factor_summer_isdefaulted) unless @interior_shading_factor_summer.nil?
        XMLHelper.add_element(interior_shading, 'WinterShadingCoefficient', @interior_shading_factor_winter, :float, @interior_shading_factor_winter_isdefaulted) unless @interior_shading_factor_winter.nil?
      end
      if @insect_screen_present
        insect_screen = XMLHelper.add_element(window, 'InsectScreen')
        sys_id = XMLHelper.add_element(insect_screen, 'SystemIdentifier')
        if @insect_screen_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', "#{id}InsectScreen")
        else
          XMLHelper.add_attribute(sys_id, 'id', @insect_screen_id)
        end
        XMLHelper.add_element(insect_screen, 'Location', @insect_screen_location, :string, @insect_screen_location_isdefaulted) unless @insect_screen_location.nil?
        XMLHelper.add_element(insect_screen, 'SummerFractionCovered', @insect_screen_coverage_summer, :float, @insect_screen_coverage_summer_isdefaulted) unless @insect_screen_coverage_summer.nil?
        XMLHelper.add_element(insect_screen, 'WinterFractionCovered', @insect_screen_coverage_winter, :float, @insect_screen_coverage_winter_isdefaulted) unless @insect_screen_coverage_winter.nil?
        XMLHelper.add_element(insect_screen, 'SummerShadingCoefficient', @insect_screen_factor_summer, :float, @insect_screen_factor_summer_isdefaulted) unless @insect_screen_factor_summer.nil?
        XMLHelper.add_element(insect_screen, 'WinterShadingCoefficient', @insect_screen_factor_winter, :float, @insect_screen_factor_winter_isdefaulted) unless @insect_screen_factor_winter.nil?
      end
      if not @storm_type.nil?
        storm_window = XMLHelper.add_element(window, 'StormWindow')
        sys_id = XMLHelper.add_element(storm_window, 'SystemIdentifier')
        if @storm_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', "#{id}StormWindow")
        else
          XMLHelper.add_attribute(sys_id, 'id', @storm_id)
        end
        XMLHelper.add_element(storm_window, 'GlassType', @storm_type, :string, @storm_type_isdefaulted) unless @storm_type.nil?
      end
      if (not @overhangs_depth.nil?) || (not @overhangs_distance_to_top_of_window.nil?) || (not @overhangs_distance_to_bottom_of_window.nil?)
        overhangs = XMLHelper.add_element(window, 'Overhangs')
        XMLHelper.add_element(overhangs, 'Depth', @overhangs_depth, :float) unless @overhangs_depth.nil?
        XMLHelper.add_element(overhangs, 'DistanceToTopOfWindow', @overhangs_distance_to_top_of_window, :float) unless @overhangs_distance_to_top_of_window.nil?
        XMLHelper.add_element(overhangs, 'DistanceToBottomOfWindow', @overhangs_distance_to_bottom_of_window, :float) unless @overhangs_distance_to_bottom_of_window.nil?
      end
      XMLHelper.add_element(window, 'FractionOperable', @fraction_operable, :float, @fraction_operable_isdefaulted) unless @fraction_operable.nil?
      XMLHelper.add_element(window, 'PerformanceClass', @performance_class, :string, @performance_class_isdefaulted) unless @performance_class.nil?
      if not @attached_to_wall_idref.nil?
        attached_to_wall = XMLHelper.add_element(window, 'AttachedToWall')
        XMLHelper.add_attribute(attached_to_wall, 'idref', @attached_to_wall_idref)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param window [Oga::XML::Element] The current Window XML element
    # @return [nil]
    def from_doc(window)
      return if window.nil?

      @id = HPXML::get_id(window)
      @area = XMLHelper.get_value(window, 'Area', :float)
      @azimuth = XMLHelper.get_value(window, 'Azimuth', :integer)
      @orientation = XMLHelper.get_value(window, 'Orientation', :string)
      @frame_type = XMLHelper.get_child_name(window, 'FrameType')
      if @frame_type == HPXML::WindowFrameTypeAluminum
        @thermal_break = XMLHelper.get_value(window, 'FrameType/Aluminum/ThermalBreak', :boolean)
      elsif @frame_type == HPXML::WindowFrameTypeMetal
        @thermal_break = XMLHelper.get_value(window, 'FrameType/Metal/ThermalBreak', :boolean)
      end
      @glass_layers = XMLHelper.get_value(window, 'GlassLayers', :string)
      @glass_type = XMLHelper.get_value(window, 'GlassType', :string)
      @gas_fill = XMLHelper.get_value(window, 'GasFill', :string)
      @ufactor = XMLHelper.get_value(window, 'UFactor', :float)
      @shgc = XMLHelper.get_value(window, 'SHGC', :float)
      @exterior_shading_id = HPXML::get_id(window, 'ExteriorShading/SystemIdentifier')
      @exterior_shading_type = XMLHelper.get_value(window, 'ExteriorShading/Type', :string)
      @exterior_shading_coverage_summer = XMLHelper.get_value(window, 'ExteriorShading/SummerFractionCovered', :float)
      @exterior_shading_coverage_winter = XMLHelper.get_value(window, 'ExteriorShading/WinterFractionCovered', :float)
      @exterior_shading_factor_summer = XMLHelper.get_value(window, 'ExteriorShading/SummerShadingCoefficient', :float)
      @exterior_shading_factor_winter = XMLHelper.get_value(window, 'ExteriorShading/WinterShadingCoefficient', :float)
      @interior_shading_id = HPXML::get_id(window, 'InteriorShading/SystemIdentifier')
      @interior_shading_type = XMLHelper.get_value(window, 'InteriorShading/Type', :string)
      @interior_shading_blinds_summer_closed_or_open = XMLHelper.get_value(window, 'InteriorShading/BlindsSummerClosedOrOpen', :string)
      @interior_shading_blinds_winter_closed_or_open = XMLHelper.get_value(window, 'InteriorShading/BlindsWinterClosedOrOpen', :string)
      @interior_shading_coverage_summer = XMLHelper.get_value(window, 'InteriorShading/SummerFractionCovered', :float)
      @interior_shading_coverage_winter = XMLHelper.get_value(window, 'InteriorShading/WinterFractionCovered', :float)
      @interior_shading_factor_summer = XMLHelper.get_value(window, 'InteriorShading/SummerShadingCoefficient', :float)
      @interior_shading_factor_winter = XMLHelper.get_value(window, 'InteriorShading/WinterShadingCoefficient', :float)
      @overhangs_depth = XMLHelper.get_value(window, 'Overhangs/Depth', :float)
      @overhangs_distance_to_top_of_window = XMLHelper.get_value(window, 'Overhangs/DistanceToTopOfWindow', :float)
      @overhangs_distance_to_bottom_of_window = XMLHelper.get_value(window, 'Overhangs/DistanceToBottomOfWindow', :float)
      @fraction_operable = XMLHelper.get_value(window, 'FractionOperable', :float)
      @performance_class = XMLHelper.get_value(window, 'PerformanceClass', :string)
      @attached_to_wall_idref = HPXML::get_idref(XMLHelper.get_element(window, 'AttachedToWall'))
      @storm_id = HPXML::get_id(window, 'StormWindow/SystemIdentifier')
      @storm_type = XMLHelper.get_value(window, 'StormWindow/GlassType', :string)
      @insect_screen_present = XMLHelper.has_element(window, 'InsectScreen')
      if @insect_screen_present
        @insect_screen_id = HPXML::get_id(window, 'InsectScreen/SystemIdentifier')
        @insect_screen_location = XMLHelper.get_value(window, 'InsectScreen/Location', :string)
        @insect_screen_coverage_summer = XMLHelper.get_value(window, 'InsectScreen/SummerFractionCovered', :float)
        @insect_screen_coverage_winter = XMLHelper.get_value(window, 'InsectScreen/WinterFractionCovered', :float)
        @insect_screen_factor_summer = XMLHelper.get_value(window, 'InsectScreen/SummerShadingCoefficient', :float)
        @insect_screen_factor_winter = XMLHelper.get_value(window, 'InsectScreen/WinterShadingCoefficient', :float)
      end
    end
  end

  # Array of HPXML::Skylight objects.
  class Skylights < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Skylight.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Skylights/Skylight').each do |skylight|
        self << Skylight.new(@parent_object, skylight)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight.
  class Skylight < BaseElement
    ATTRS = [:id,                             # [String] SystemIdentifier/@id
             :sameas_id,                      # [String] SystemIdentifier/@sameas
             :area,                           # [Double] Area (ft2)
             :azimuth,                        # [Integer] Azimuth (deg)
             :orientation,                    # [String] Orientation (HPXML::OrientationXXX)
             :frame_type,                     # [String] FrameType/* (HPXML::WindowFrameTypeXXX)
             :thermal_break,                  # [Boolean] FrameType/*/ThermalBreak
             :glass_layers,                   # [String] GlassLayers (HPXML::WindowLayersXXX)
             :glass_type,                     # [String] GlassType (HPXML::WindowGlassTypeXXX)
             :gas_fill,                       # [String] GasFill (HPXML::WindowGasXXX)
             :ufactor,                        # [Double] UFactor (Btu/F-ft2-hr)
             :shgc,                           # [Double] SHGC
             :exterior_shading_id,            # [String] ExteriorShading/SystemIdentifier/@id
             :exterior_shading_type,          # [String] ExteriorShading/Type
             :exterior_shading_factor_summer, # [Double] ExteriorShading/SummerShadingCoefficient (frac)
             :exterior_shading_factor_winter, # [Double] ExteriorShading/WinterShadingCoefficient (frac)
             :interior_shading_id,            # [String] InteriorShading/SystemIdentifier/@id
             :interior_shading_type,          # [String] InteriorShading/Type
             :interior_shading_factor_summer, # [Double] InteriorShading/SummerShadingCoefficient (frac)
             :interior_shading_factor_winter, # [Double] InteriorShading/WinterShadingCoefficient (frac)
             :storm_id,                       # [String] StormWindow/SystemIdentifier/@id
             :storm_type,                     # [String] StormWindow/GlassType (HPXML::WindowGlassTypeXXX)
             :attached_to_roof_idref,         # [String] AttachedToRoof/@idref
             :attached_to_floor_idref,        # [String] AttachedToFloor/@idref
             :curb_area,                      # [Double] extension/Curb/Area (ft2)
             :curb_assembly_r_value,          # [Double] extension/Curb/AssemblyEffectiveRValue (F-ft2-hr/Btu)
             :shaft_area,                     # [Double] extension/Shaft/Area (ft2)
             :shaft_assembly_r_value]         # [Double] extension/Shaft/AssemblyEffectiveRValue (F-ft2-hr/Btu)
    attr_accessor(*ATTRS)

    # Returns the parent roof that includes this skylight.
    #
    # @return [HPXML::Roof] Parent roof surface
    def roof
      return if @attached_to_roof_idref.nil?

      @parent_object.roofs.each do |roof|
        next unless roof.id == @attached_to_roof_idref

        return roof
      end
      fail "Attached roof '#{@attached_to_roof_idref}' not found for skylight '#{@id}'."
    end

    # Returns the parent floor that includes this skylight.
    #
    # @return [HPXML::Floor] Parent floor surface
    def floor
      return if @attached_to_floor_idref.nil?

      @parent_object.floors.each do |floor|
        next unless floor.id == @attached_to_floor_idref

        return floor
      end
      fail "Attached floor '#{@attached_to_floor_idref}' not found for skylight '#{@id}'."
    end

    # Returns whether the skylight is on an exterior surface (i.e., adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an exterior surface
    def is_exterior
      return roof.is_exterior
    end

    # Returns whether the skylight is on an interior surface (i.e., NOT adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an interior surface
    def is_interior
      return !is_exterior
    end

    # Returns whether the skylight is on a thermal boundary parent surface.
    #
    # @return [Boolean] True if a thermal boundary surface
    def is_thermal_boundary
      return HPXML::is_thermal_boundary(roof)
    end

    # Returns whether the skylight's parent surface is both an exterior surface and a thermal boundary surface.
    #
    # @return [Boolean] True if an exterior, thermal boundary surface
    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    # Returns whether the skylight is on a surface adjacent to conditioned space.
    #
    # @return [Boolean] True if adjacent to conditioned space
    def is_conditioned
      if not floor.nil?
        return HPXML::is_conditioned(floor)
      else
        return HPXML::is_conditioned(roof)
      end
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.skylights.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; roof; rescue StandardError => e; errors << e.message; end
      begin; floor; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      skylights = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Skylights'])
      skylight = XMLHelper.add_element(skylights, 'Skylight')
      sys_id = XMLHelper.add_element(skylight, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(skylight, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(skylight, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(skylight, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      if not @frame_type.nil?
        frame_type_el = XMLHelper.add_element(skylight, 'FrameType')
        frame_type = XMLHelper.add_element(frame_type_el, @frame_type)
        if [HPXML::WindowFrameTypeAluminum, HPXML::WindowFrameTypeMetal].include? @frame_type
          XMLHelper.add_element(frame_type, 'ThermalBreak', @thermal_break, :boolean, @thermal_break_isdefaulted) unless @thermal_break.nil?
        end
      end
      XMLHelper.add_element(skylight, 'GlassLayers', @glass_layers, :string, @glass_layers_isdefaulted) unless @glass_layers.nil?
      XMLHelper.add_element(skylight, 'GlassType', @glass_type, :string, @glass_type_isdefaulted) unless @glass_type.nil?
      XMLHelper.add_element(skylight, 'GasFill', @gas_fill, :string, @gas_fill_isdefaulted) unless @gas_fill.nil?
      XMLHelper.add_element(skylight, 'UFactor', @ufactor, :float, @ufactor_isdefaulted) unless @ufactor.nil?
      XMLHelper.add_element(skylight, 'SHGC', @shgc, :float, @shgc_isdefaulted) unless @shgc.nil?
      if (not @exterior_shading_type.nil?) || (not @exterior_shading_factor_summer.nil?) || (not @exterior_shading_factor_winter.nil?)
        exterior_shading = XMLHelper.add_element(skylight, 'ExteriorShading')
        sys_id = XMLHelper.add_element(exterior_shading, 'SystemIdentifier')
        if @exterior_shading_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', "#{id}ExteriorShading")
        else
          XMLHelper.add_attribute(sys_id, 'id', @exterior_shading_id)
        end
        XMLHelper.add_element(exterior_shading, 'Type', @exterior_shading_type, :string) unless @exterior_shading_type.nil?
        XMLHelper.add_element(exterior_shading, 'SummerShadingCoefficient', @exterior_shading_factor_summer, :float, @exterior_shading_factor_summer_isdefaulted) unless @exterior_shading_factor_summer.nil?
        XMLHelper.add_element(exterior_shading, 'WinterShadingCoefficient', @exterior_shading_factor_winter, :float, @exterior_shading_factor_winter_isdefaulted) unless @exterior_shading_factor_winter.nil?
      end
      if (not @interior_shading_type.nil?) || (not @interior_shading_factor_summer.nil?) || (not @interior_shading_factor_winter.nil?)
        interior_shading = XMLHelper.add_element(skylight, 'InteriorShading')
        sys_id = XMLHelper.add_element(interior_shading, 'SystemIdentifier')
        if @interior_shading_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', "#{id}InteriorShading")
        else
          XMLHelper.add_attribute(sys_id, 'id', @interior_shading_id)
        end
        XMLHelper.add_element(interior_shading, 'Type', @interior_shading_type, :string) unless @interior_shading_type.nil?
        XMLHelper.add_element(interior_shading, 'SummerShadingCoefficient', @interior_shading_factor_summer, :float, @interior_shading_factor_summer_isdefaulted) unless @interior_shading_factor_summer.nil?
        XMLHelper.add_element(interior_shading, 'WinterShadingCoefficient', @interior_shading_factor_winter, :float, @interior_shading_factor_winter_isdefaulted) unless @interior_shading_factor_winter.nil?
      end
      if not @storm_type.nil?
        storm_window = XMLHelper.add_element(skylight, 'StormWindow')
        sys_id = XMLHelper.add_element(storm_window, 'SystemIdentifier')
        if @storm_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', "#{id}StormWindow")
        else
          XMLHelper.add_attribute(sys_id, 'id', @storm_id)
        end
        XMLHelper.add_element(storm_window, 'GlassType', @storm_type, :string, @storm_type_isdefaulted) unless @storm_type.nil?
      end
      if not @attached_to_roof_idref.nil?
        attached_to_roof = XMLHelper.add_element(skylight, 'AttachedToRoof')
        XMLHelper.add_attribute(attached_to_roof, 'idref', @attached_to_roof_idref)
      end
      if not @attached_to_floor_idref.nil?
        attached_to_floor = XMLHelper.add_element(skylight, 'AttachedToFloor')
        XMLHelper.add_attribute(attached_to_floor, 'idref', @attached_to_floor_idref)
      end
      if (not @curb_area.nil?) || (not @curb_assembly_r_value.nil?)
        curb = XMLHelper.create_elements_as_needed(skylight, ['extension', 'Curb'])
        XMLHelper.add_element(curb, 'Area', @curb_area, :float) unless @curb_area.nil?
        XMLHelper.add_element(curb, 'AssemblyEffectiveRValue', @curb_assembly_r_value, :float) unless @curb_assembly_r_value.nil?
      end
      if (not @shaft_area.nil?) || (not @shaft_assembly_r_value.nil?)
        shaft = XMLHelper.create_elements_as_needed(skylight, ['extension', 'Shaft'])
        XMLHelper.add_element(shaft, 'Area', @shaft_area, :float) unless @shaft_area.nil?
        XMLHelper.add_element(shaft, 'AssemblyEffectiveRValue', @shaft_assembly_r_value, :float) unless @shaft_assembly_r_value.nil?
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param skylight [Oga::XML::Element] The current Skylight XML element
    # @return [nil]
    def from_doc(skylight)
      return if skylight.nil?

      @id = HPXML::get_id(skylight)
      @area = XMLHelper.get_value(skylight, 'Area', :float)
      @azimuth = XMLHelper.get_value(skylight, 'Azimuth', :integer)
      @orientation = XMLHelper.get_value(skylight, 'Orientation', :string)
      @frame_type = XMLHelper.get_child_name(skylight, 'FrameType')
      if @frame_type == HPXML::WindowFrameTypeAluminum
        @thermal_break = XMLHelper.get_value(skylight, 'FrameType/Aluminum/ThermalBreak', :boolean)
      elsif @frame_type == HPXML::WindowFrameTypeMetal
        @thermal_break = XMLHelper.get_value(skylight, 'FrameType/Metal/ThermalBreak', :boolean)
      end
      @glass_layers = XMLHelper.get_value(skylight, 'GlassLayers', :string)
      @glass_type = XMLHelper.get_value(skylight, 'GlassType', :string)
      @gas_fill = XMLHelper.get_value(skylight, 'GasFill', :string)
      @ufactor = XMLHelper.get_value(skylight, 'UFactor', :float)
      @shgc = XMLHelper.get_value(skylight, 'SHGC', :float)
      @exterior_shading_id = HPXML::get_id(skylight, 'ExteriorShading/SystemIdentifier')
      @exterior_shading_type = XMLHelper.get_value(skylight, 'ExteriorShading/Type', :string)
      @exterior_shading_factor_summer = XMLHelper.get_value(skylight, 'ExteriorShading/SummerShadingCoefficient', :float)
      @exterior_shading_factor_winter = XMLHelper.get_value(skylight, 'ExteriorShading/WinterShadingCoefficient', :float)
      @interior_shading_id = HPXML::get_id(skylight, 'InteriorShading/SystemIdentifier')
      @interior_shading_type = XMLHelper.get_value(skylight, 'InteriorShading/Type', :string)
      @interior_shading_factor_summer = XMLHelper.get_value(skylight, 'InteriorShading/SummerShadingCoefficient', :float)
      @interior_shading_factor_winter = XMLHelper.get_value(skylight, 'InteriorShading/WinterShadingCoefficient', :float)
      @attached_to_roof_idref = HPXML::get_idref(XMLHelper.get_element(skylight, 'AttachedToRoof'))
      @attached_to_floor_idref = HPXML::get_idref(XMLHelper.get_element(skylight, 'AttachedToFloor'))
      @storm_id = HPXML::get_id(skylight, 'StormWindow/SystemIdentifier')
      @storm_type = XMLHelper.get_value(skylight, 'StormWindow/GlassType', :string)
      @curb_area = XMLHelper.get_value(skylight, 'extension/Curb/Area', :float)
      @curb_assembly_r_value = XMLHelper.get_value(skylight, 'extension/Curb/AssemblyEffectiveRValue', :float)
      @shaft_area = XMLHelper.get_value(skylight, 'extension/Shaft/Area', :float)
      @shaft_assembly_r_value = XMLHelper.get_value(skylight, 'extension/Shaft/AssemblyEffectiveRValue', :float)
    end
  end

  # Array of HPXML::Door objects.
  class Doors < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Door.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Enclosure/Doors/Door').each do |door|
        self << Door.new(@parent_object, door)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/Doors/Door.
  class Door < BaseElement
    ATTRS = [:id,                     # [String] SystemIdentifier/@id
             :sameas_id,              # [String] SystemIdentifier/@sameas
             :attached_to_wall_idref, # [String] AttachedToWall/@idref
             :area,                   # [Double] Area (ft2)
             :azimuth,                # [Integer] Azimuth (deg)
             :orientation,            # [String] Orientation (HPXML::OrientationXXX)
             :r_value]                # [Double] RValue (F-ft2-hr/Btu)
    attr_accessor(*ATTRS)

    # Returns the parent wall that includes this door.
    #
    # @return [HPXML::Wall] Parent wall surface
    def wall
      return if @attached_to_wall_idref.nil?

      (@parent_object.walls + @parent_object.foundation_walls).each do |wall|
        next unless wall.id == @attached_to_wall_idref

        return wall
      end
      fail "Attached wall '#{@attached_to_wall_idref}' not found for door '#{@id}'."
    end

    # Returns whether the door is on an exterior surface (i.e., adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an exterior surface
    def is_exterior
      return wall.is_exterior
    end

    # Returns whether the door is on an interior surface (i.e., NOT adjacent to
    # outside or ground).
    #
    # @return [Boolean] True if an interior surface
    def is_interior
      return !is_exterior
    end

    # Returns whether the door is on a thermal boundary parent surface.
    #
    # @return [Boolean] True if a thermal boundary surface
    def is_thermal_boundary
      return HPXML::is_thermal_boundary(wall)
    end

    # Returns whether the door's parent surface is both an exterior surface and a thermal boundary surface.
    #
    # @return [Boolean] True if an exterior, thermal boundary surface
    def is_exterior_thermal_boundary
      return (is_exterior && is_thermal_boundary)
    end

    # Returns whether the door is on a surface adjacent to conditioned space.
    #
    # @return [Boolean] True if adjacent to conditioned space
    def is_conditioned
      return HPXML::is_conditioned(self)
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.doors.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; wall; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      doors = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'Doors'])
      door = XMLHelper.add_element(doors, 'Door')
      sys_id = XMLHelper.add_element(door, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      if not @attached_to_wall_idref.nil?
        attached_to_wall = XMLHelper.add_element(door, 'AttachedToWall')
        XMLHelper.add_attribute(attached_to_wall, 'idref', @attached_to_wall_idref)
      end
      XMLHelper.add_element(door, 'Area', @area, :float) unless @area.nil?
      XMLHelper.add_element(door, 'Azimuth', @azimuth, :integer, @azimuth_isdefaulted) unless @azimuth.nil?
      XMLHelper.add_element(door, 'Orientation', @orientation, :string, @orientation_isdefaulted) unless @orientation.nil?
      XMLHelper.add_element(door, 'RValue', @r_value, :float) unless @r_value.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param door [Oga::XML::Element] The current Door XML element
    # @return [nil]
    def from_doc(door)
      return if door.nil?

      @id = HPXML::get_id(door)
      @attached_to_wall_idref = HPXML::get_idref(XMLHelper.get_element(door, 'AttachedToWall'))
      @area = XMLHelper.get_value(door, 'Area', :float)
      @azimuth = XMLHelper.get_value(door, 'Azimuth', :integer)
      @orientation = XMLHelper.get_value(door, 'Orientation', :string)
      @r_value = XMLHelper.get_value(door, 'RValue', :float)
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/extension/PartitionWallMass.
  class PartitionWallMass < BaseElement
    ATTRS = [:area_fraction,             # [Double] AreaFraction (frac)
             :interior_finish_type,      # [String] InteriorFinish/Type (HPXML::InteriorFinishXXX)
             :interior_finish_thickness] # [Double] InteriorFinish/Thickness (in)
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      partition_wall_mass = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'extension', 'PartitionWallMass'])
      XMLHelper.add_element(partition_wall_mass, 'AreaFraction', @area_fraction, :float, @area_fraction_isdefaulted) unless @area_fraction.nil?
      if (not @interior_finish_type.nil?) || (not @interior_finish_thickness.nil?)
        interior_finish = XMLHelper.add_element(partition_wall_mass, 'InteriorFinish')
        XMLHelper.add_element(interior_finish, 'Type', @interior_finish_type, :string, @interior_finish_type_isdefaulted) unless @interior_finish_type.nil?
        XMLHelper.add_element(interior_finish, 'Thickness', @interior_finish_thickness, :float, @interior_finish_thickness_isdefaulted) unless @interior_finish_thickness.nil?
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      partition_wall_mass = XMLHelper.get_element(building, 'BuildingDetails/Enclosure/extension/PartitionWallMass')
      return if partition_wall_mass.nil?

      @area_fraction = XMLHelper.get_value(partition_wall_mass, 'AreaFraction', :float)
      interior_finish = XMLHelper.get_element(partition_wall_mass, 'InteriorFinish')
      if not interior_finish.nil?
        @interior_finish_type = XMLHelper.get_value(interior_finish, 'Type', :string)
        @interior_finish_thickness = XMLHelper.get_value(interior_finish, 'Thickness', :float)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Enclosure/extension/FurnitureMass.
  class FurnitureMass < BaseElement
    ATTRS = [:area_fraction, # [Double] AreaFraction (frac)
             :type]          # [String] Type (HPXML::FurnitureMassTypeXXX)
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      furniture_mass = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Enclosure', 'extension', 'FurnitureMass'])
      XMLHelper.add_element(furniture_mass, 'AreaFraction', @area_fraction, :float, @area_fraction_isdefaulted) unless @area_fraction.nil?
      XMLHelper.add_element(furniture_mass, 'Type', @type, :string, @type_isdefaulted) unless @type.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      furniture_mass = XMLHelper.get_element(building, 'BuildingDetails/Enclosure/extension/FurnitureMass')
      return if furniture_mass.nil?

      @area_fraction = XMLHelper.get_value(furniture_mass, 'AreaFraction', :float)
      @type = XMLHelper.get_value(furniture_mass, 'Type', :string)
    end
  end

  # Array of HPXML::HeatingSystem objects.
  class HeatingSystems < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << HeatingSystem.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem').each do |heating_system|
        self << HeatingSystem.new(@parent_object, heating_system)
      end
    end

    # Returns the total fraction of building's heating load served by all heating systems.
    #
    # @return [Double] Total fraction of building's heating load served
    def total_fraction_heat_load_served
      map { |htg_sys| htg_sys.fraction_heat_load_served.to_f }.sum(0.0)
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem.
  class HeatingSystem < BaseElement
    def initialize(hpxml_element, *args, **kwargs)
      @heating_detailed_performance_data = HeatingDetailedPerformanceData.new(hpxml_element)
      super(hpxml_element, *args, **kwargs)
    end
    CLASS_ATTRS = [:heating_detailed_performance_data] # [HPXML::HeatingDetailedPerformanceData]
    ATTRS = [:primary_system,                   # [Boolean] ../PrimarySystems/PrimaryHeatingSystem/@id
             :id,                               # [String] SystemIdentifier/@id
             :sameas_id,                        # [String] SystemIdentifier/@sameas
             :attached_to_zone_idref,           # [String] AttachedToZone/@idref
             :location,                         # [String] UnitLocation (HPXML::LocationXXX)
             :year_installed,                   # [Integer] YearInstalled
             :third_party_certification,        # [String] ThirdPartyCertification
             :distribution_system_idref,        # [String] DistributionSystem/@idref
             :is_shared_system,                 # [Boolean] IsSharedSystem
             :number_of_units_served,           # [Integer] NumberofUnitsServed
             :heating_system_type,              # [String] HeatingSystemType/* (HPXML::HVACTypeXXX)
             :pilot_light,                      # [Boolean] HeatingSystemType/*/PilotLight
             :pilot_light_btuh,                 # [Double] HeatingSystemType/*/extension/PilotLightBtuh (Btu/hr)
             :electric_resistance_distribution, # [String] HeatingSystemType/ElectricResistance/ElectricDistribution (HPXML::ElectricResistanceDistributionXXX)
             :heating_system_fuel,              # [String] HeatingSystemFuel (HPXML::FuelTypeXXX)
             :heating_capacity,                 # [Double] HeatingCapacity (Btu/hr)
             :heating_efficiency_afue,          # [Double] AnnualHeatingEfficiency[Units="AFUE"]/Value (frac)
             :heating_efficiency_percent,       # [Double] AnnualHeatingEfficiency[Units="Percent"]/Value (frac)
             :fraction_heat_load_served,        # [Double] FractionHeatLoadServed (frac)
             :electric_auxiliary_energy,        # [Double] ElectricAuxiliaryEnergy (kWh/yr)
             :shared_loop_watts,                # [Double] extension/SharedLoopWatts (W)
             :shared_loop_motor_efficiency,     # [Double] extension/SharedLoopMotorEfficiency (frac)
             :fan_coil_watts,                   # [Double] extension/FanCoilWatts (W)
             :fan_watts_per_cfm,                # [Double] extension/FanPowerWattsPerCFM (W/cfm)
             :fan_watts,                        # [Double] extension/FanPowerWatts (W)
             :airflow_defect_ratio,             # [Double] extension/AirflowDefectRatio (frac)
             :heating_design_airflow_cfm,       # [Double] extension/HeatingDesignAirflowCFM (cfm)
             :heating_autosizing_factor,        # [Double] extension/HeatingAutosizingFactor (frac)
             :heating_autosizing_limit,         # [Double] extension/HeatingAutosizingLimit (Btu/hr)
             :fan_motor_type,                   # [String] extension/FanMotorType
             :htg_seed_id]                      # [String] extension/HeatingSeedId
    attr_reader(*CLASS_ATTRS)
    attr_accessor(*ATTRS)

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def branch_circuits
      return HPXML::branch_circuits(@id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def service_feeders
      return HPXML::service_feeders(@id, @parent_object.electric_panels)
    end

    # Returns the zone that the heating system serves.
    #
    # @return [HPXML::Zone] Zone served
    def zone
      return if @attached_to_zone_idref.nil?

      @parent_object.zones.each do |z|
        return z if z.id == @attached_to_zone_idref
      end

      fail "Attached zone '#{@attached_to_zone_idref}' not found for heating system '#{@id}'."
    end

    # Returns the HVAC distribution system for the heating system.
    #
    # @return [HPXML::HVACDistribution] The attached HVAC distribution system
    def distribution_system
      return if @distribution_system_idref.nil?

      @parent_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.id == @distribution_system_idref

        return hvac_distribution
      end
      fail "Attached HVAC distribution system '#{@distribution_system_idref}' not found for HVAC system '#{@id}'."
    end

    # Returns the cooling system on the same distribution system as the heating system.
    #
    # @return [HPXML::XXX] The attached cooling system
    def attached_cooling_system
      return if distribution_system.nil?

      # by distribution system
      distribution_system.hvac_systems.each do |hvac_system|
        next if hvac_system.id == @id

        return hvac_system
      end

      return
    end

    # Returns the water heating system related to the heating system (e.g., for
    # a combination boiler that provides both water heating and space heating).
    #
    # @return [HPXML::WaterHeatingSystem] The related water heating system
    def related_water_heating_system
      @parent_object.water_heating_systems.each do |water_heating_system|
        next unless water_heating_system.related_hvac_idref == @id

        return water_heating_system
      end
      return
    end

    # Returns the primary heat pump when the heating system serves as a heat pump backup system.
    #
    # @return [HPXML::HeatPump] The primary heat pump
    def primary_heat_pump
      # Returns the HP for which this heating system is backup
      @parent_object.heat_pumps.each do |heat_pump|
        next if heat_pump.backup_system_idref.nil?
        next if heat_pump.backup_system_idref != @id

        return heat_pump
      end
      return
    end

    # Returns whether the heating system serves as a heat pump backup system.
    #
    # @return [Boolean] True if a heat pump backup system
    def is_heat_pump_backup_system
      return !primary_heat_pump.nil?
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.heating_systems.delete(self)
      @parent_object.water_heating_systems.each do |water_heating_system|
        next unless water_heating_system.related_hvac_idref == @id

        water_heating_system.related_hvac_idref = nil
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; distribution_system; rescue StandardError => e; errors << e.message; end
      begin; zone; rescue StandardError => e; errors << e.message; end
      errors += @heating_detailed_performance_data.check_for_errors
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      hvac_plant = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC', 'HVACPlant'])
      primary_systems = XMLHelper.create_elements_as_needed(hvac_plant, ['PrimarySystems']) unless @parent_object.primary_hvac_systems.empty?
      heating_system = XMLHelper.add_element(hvac_plant, 'HeatingSystem')
      sys_id = XMLHelper.add_element(heating_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      if not @attached_to_zone_idref.nil?
        zone_attached = XMLHelper.add_element(heating_system, 'AttachedToZone')
        XMLHelper.add_attribute(zone_attached, 'idref', @attached_to_zone_idref)
      end
      XMLHelper.add_element(heating_system, 'UnitLocation', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(heating_system, 'YearInstalled', @year_installed, :integer) unless @year_installed.nil?
      XMLHelper.add_element(heating_system, 'ThirdPartyCertification', @third_party_certification, :string) unless @third_party_certification.nil?
      if not @distribution_system_idref.nil?
        distribution_system = XMLHelper.add_element(heating_system, 'DistributionSystem')
        XMLHelper.add_attribute(distribution_system, 'idref', @distribution_system_idref)
      end
      XMLHelper.add_element(heating_system, 'IsSharedSystem', @is_shared_system, :boolean) unless @is_shared_system.nil?
      XMLHelper.add_element(heating_system, 'NumberofUnitsServed', @number_of_units_served, :integer) unless @number_of_units_served.nil?
      if not @heating_system_type.nil?
        heating_system_type_el = XMLHelper.add_element(heating_system, 'HeatingSystemType')
        type_el = XMLHelper.add_element(heating_system_type_el, @heating_system_type)
        if [HPXML::HVACTypeFurnace,
            HPXML::HVACTypeWallFurnace,
            HPXML::HVACTypeFloorFurnace,
            HPXML::HVACTypeFireplace,
            HPXML::HVACTypeStove,
            HPXML::HVACTypeBoiler].include? @heating_system_type
          XMLHelper.add_element(type_el, 'PilotLight', @pilot_light, :boolean, @pilot_light_isdefaulted) unless @pilot_light.nil?
          if @pilot_light
            XMLHelper.add_extension(type_el, 'PilotLightBtuh', @pilot_light_btuh, :float, @pilot_light_btuh_isdefaulted) unless @pilot_light_btuh.nil?
          end
        end
        if @heating_system_type == HPXML::HVACTypeElectricResistance
          XMLHelper.add_element(type_el, 'ElectricDistribution', @electric_resistance_distribution, :string, @electric_resistance_distribution_isdefaulted) unless @electric_resistance_distribution.nil?
        end
      end
      XMLHelper.add_element(heating_system, 'HeatingSystemFuel', @heating_system_fuel, :string) unless @heating_system_fuel.nil?
      XMLHelper.add_element(heating_system, 'HeatingCapacity', @heating_capacity, :float, @heating_capacity_isdefaulted) unless @heating_capacity.nil?
      if not @heating_efficiency_afue.nil?
        annual_efficiency = XMLHelper.add_element(heating_system, 'AnnualHeatingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsAFUE, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @heating_efficiency_afue, :float, @heating_efficiency_afue_isdefaulted)
      end
      if not @heating_efficiency_percent.nil?
        annual_efficiency = XMLHelper.add_element(heating_system, 'AnnualHeatingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsPercent, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @heating_efficiency_percent, :float, @heating_efficiency_percent_isdefaulted)
      end
      @heating_detailed_performance_data.to_doc(heating_system)
      XMLHelper.add_element(heating_system, 'FractionHeatLoadServed', @fraction_heat_load_served, :float, @fraction_heat_load_served_isdefaulted) unless @fraction_heat_load_served.nil?
      XMLHelper.add_element(heating_system, 'ElectricAuxiliaryEnergy', @electric_auxiliary_energy, :float, @electric_auxiliary_energy_isdefaulted) unless @electric_auxiliary_energy.nil?
      XMLHelper.add_extension(heating_system, 'SharedLoopWatts', @shared_loop_watts, :float) unless @shared_loop_watts.nil?
      XMLHelper.add_extension(heating_system, 'SharedLoopMotorEfficiency', @shared_loop_motor_efficiency, :float) unless @shared_loop_motor_efficiency.nil?
      XMLHelper.add_extension(heating_system, 'FanMotorType', @fan_motor_type, :string, @fan_motor_type_isdefaulted) unless @fan_motor_type.nil?
      XMLHelper.add_extension(heating_system, 'FanCoilWatts', @fan_coil_watts, :float) unless @fan_coil_watts.nil?
      XMLHelper.add_extension(heating_system, 'FanPowerWattsPerCFM', @fan_watts_per_cfm, :float, @fan_watts_per_cfm_isdefaulted) unless @fan_watts_per_cfm.nil?
      XMLHelper.add_extension(heating_system, 'FanPowerWatts', @fan_watts, :float, @fan_watts_isdefaulted) unless @fan_watts.nil?
      XMLHelper.add_extension(heating_system, 'AirflowDefectRatio', @airflow_defect_ratio, :float, @airflow_defect_ratio_isdefaulted) unless @airflow_defect_ratio.nil?
      XMLHelper.add_extension(heating_system, 'HeatingDesignAirflowCFM', @heating_design_airflow_cfm, :float, @heating_design_airflow_cfm_isdefaulted) unless @heating_design_airflow_cfm.nil?
      XMLHelper.add_extension(heating_system, 'HeatingAutosizingFactor', @heating_autosizing_factor, :float, @heating_autosizing_factor_isdefaulted) unless @heating_autosizing_factor.nil?
      XMLHelper.add_extension(heating_system, 'HeatingAutosizingLimit', @heating_autosizing_limit, :float, @heating_autosizing_limit_isdefaulted) unless @heating_autosizing_limit.nil?
      XMLHelper.add_extension(heating_system, 'HeatingSeedId', @htg_seed_id, :string) unless @htg_seed_id.nil?
      if @primary_system
        primary_heating_system = XMLHelper.insert_element(primary_systems, 'PrimaryHeatingSystem')
        XMLHelper.add_attribute(primary_heating_system, 'idref', @id)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param heating_system [Oga::XML::Element] The current HeatingSystem XML element
    # @return [nil]
    def from_doc(heating_system)
      return if heating_system.nil?

      @id = HPXML::get_id(heating_system)
      @attached_to_zone_idref = HPXML::get_idref(XMLHelper.get_elements(heating_system, 'AttachedToZone')[0])
      @location = XMLHelper.get_value(heating_system, 'UnitLocation', :string)
      @year_installed = XMLHelper.get_value(heating_system, 'YearInstalled', :integer)
      @third_party_certification = XMLHelper.get_value(heating_system, 'ThirdPartyCertification', :string)
      @distribution_system_idref = HPXML::get_idref(XMLHelper.get_element(heating_system, 'DistributionSystem'))
      @is_shared_system = XMLHelper.get_value(heating_system, 'IsSharedSystem', :boolean)
      @number_of_units_served = XMLHelper.get_value(heating_system, 'NumberofUnitsServed', :integer)
      @heating_system_type = XMLHelper.get_child_name(heating_system, 'HeatingSystemType')
      @heating_system_fuel = XMLHelper.get_value(heating_system, 'HeatingSystemFuel', :string)
      @pilot_light = XMLHelper.get_value(heating_system, "HeatingSystemType/#{@heating_system_type}/PilotLight", :boolean)
      if @pilot_light
        @pilot_light_btuh = XMLHelper.get_value(heating_system, "HeatingSystemType/#{@heating_system_type}/extension/PilotLightBtuh", :float)
      end
      if @heating_system_type == HPXML::HVACTypeElectricResistance
        @electric_resistance_distribution = XMLHelper.get_value(heating_system, "HeatingSystemType/#{@heating_system_type}/ElectricDistribution", :string)
      end
      @heating_capacity = XMLHelper.get_value(heating_system, 'HeatingCapacity', :float)
      @heating_efficiency_afue = XMLHelper.get_value(heating_system, "AnnualHeatingEfficiency[Units='#{UnitsAFUE}']/Value", :float)
      @heating_efficiency_percent = XMLHelper.get_value(heating_system, "AnnualHeatingEfficiency[Units='Percent']/Value", :float)
      @heating_detailed_performance_data.from_doc(heating_system)
      @fraction_heat_load_served = XMLHelper.get_value(heating_system, 'FractionHeatLoadServed', :float)
      @electric_auxiliary_energy = XMLHelper.get_value(heating_system, 'ElectricAuxiliaryEnergy', :float)
      @shared_loop_watts = XMLHelper.get_value(heating_system, 'extension/SharedLoopWatts', :float)
      @shared_loop_motor_efficiency = XMLHelper.get_value(heating_system, 'extension/SharedLoopMotorEfficiency', :float)
      @fan_motor_type = XMLHelper.get_value(heating_system, 'extension/FanMotorType', :string)
      @fan_coil_watts = XMLHelper.get_value(heating_system, 'extension/FanCoilWatts', :float)
      @fan_watts_per_cfm = XMLHelper.get_value(heating_system, 'extension/FanPowerWattsPerCFM', :float)
      @fan_watts = XMLHelper.get_value(heating_system, 'extension/FanPowerWatts', :float)
      @airflow_defect_ratio = XMLHelper.get_value(heating_system, 'extension/AirflowDefectRatio', :float)
      @heating_design_airflow_cfm = XMLHelper.get_value(heating_system, 'extension/HeatingDesignAirflowCFM', :float)
      @heating_autosizing_factor = XMLHelper.get_value(heating_system, 'extension/HeatingAutosizingFactor', :float)
      @heating_autosizing_limit = XMLHelper.get_value(heating_system, 'extension/HeatingAutosizingLimit', :float)
      @htg_seed_id = XMLHelper.get_value(heating_system, 'extension/HeatingSeedId', :string)
      primary_heating_system = HPXML::get_idref(XMLHelper.get_element(heating_system, '../PrimarySystems/PrimaryHeatingSystem'))
      if primary_heating_system == @id
        @primary_system = true
      else
        @primary_system = false
      end
    end
  end

  # Array of HPXML::CoolingSystem objects.
  class CoolingSystems < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << CoolingSystem.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem').each do |cooling_system|
        self << CoolingSystem.new(@parent_object, cooling_system)
      end
    end

    # Returns the total fraction of building's cooling load served by all cooling systems.
    #
    # @return [Double] Total fraction of building's cooling load served
    def total_fraction_cool_load_served
      map { |clg_sys| clg_sys.fraction_cool_load_served.to_f }.sum(0.0)
    end

    # Returns the total fraction of building's heating load served by all cooling systems.
    #
    # @return [Double] Total fraction of building's heating load served
    def total_fraction_heat_load_served
      map { |clg_sys| clg_sys.integrated_heating_system_fraction_heat_load_served.to_f }.sum(0.0)
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem.
  class CoolingSystem < BaseElement
    def initialize(hpxml_element, *args, **kwargs)
      @cooling_detailed_performance_data = CoolingDetailedPerformanceData.new(hpxml_element)
      super(hpxml_element, *args, **kwargs)
    end
    CLASS_ATTRS = [:cooling_detailed_performance_data] # [HPXML::CoolingDetailedPerformanceData]
    ATTRS = [:primary_system,                                      # [Boolean] ../PrimarySystems/PrimaryCoolingSystem/@idref
             :id,                                                  # [String] SystemIdentifier/@id
             :sameas_id,                                           # [String] SystemIdentifier/@sameas
             :attached_to_zone_idref,                              # [String] AttachedToZone/@idref
             :location,                                            # [String] UnitLocation (HPXML::LocationXXX)
             :year_installed,                                      # [Integer] YearInstalled
             :third_party_certification,                           # [String] ThirdPartyCertification
             :distribution_system_idref,                           # [String] DistributionSystem/@idref
             :is_shared_system,                                    # [Boolean] IsSharedSystem
             :number_of_units_served,                              # [Integer] NumberofUnitsServed
             :cooling_system_type,                                 # [String] CoolingSystemType (HPXML::HVACTypeXXX)
             :cooling_system_fuel,                                 # [String] CoolingSystemFuel (HPXML::FuelTypeXXX)
             :cooling_capacity,                                    # [Double] CoolingCapacity (Btu/hr)
             :compressor_type,                                     # [String] CompressorType (HPXML::HVACCompressorTypeXXX)
             :fraction_cool_load_served,                           # [Double] FractionCoolLoadServed (frac)
             :cooling_efficiency_seer,                             # [Double] AnnualCoolingEfficiency[Units="SEER"]/Value (Btu/Wh)
             :cooling_efficiency_seer2,                            # [Double] AnnualCoolingEfficiency[Units="SEER2"]/Value (Btu/Wh)
             :cooling_efficiency_eer,                              # [Double] AnnualCoolingEfficiency[Units="EER"]/Value (Btu/Wh)
             :cooling_efficiency_eer2,                             # [Double] AnnualCoolingEfficiency[Units="EER2"]/Value (Btu/Wh)
             :cooling_efficiency_ceer,                             # [Double] AnnualCoolingEfficiency[Units="CEER"]/Value (Btu/Wh)
             :cooling_efficiency_kw_per_ton,                       # [Double] AnnualCoolingEfficiency[Units="kW/ton"]/Value (kW/ton)
             :integrated_heating_system_fuel,                      # [String] IntegratedHeatingSystemFuel (HPXML::FuelTypeXXX)
             :integrated_heating_system_capacity,                  # [Double] IntegratedHeatingSystemCapacity (Btu/hr)
             :integrated_heating_system_efficiency_percent,        # [Double] IntegratedHeatingSystemAnnualEfficiency[Units="Percent"]/Value (frac)
             :integrated_heating_system_fraction_heat_load_served, # [Double] IntegratedHeatingSystemFractionHeatLoadServed (frac)
             :airflow_defect_ratio,                                # [Double] extension/AirflowDefectRatio (frac)
             :charge_defect_ratio,                                 # [Double] extension/ChargeDefectRatio (frac)
             :fan_motor_type,                                      # [String] extension/FanMotorType
             :fan_watts_per_cfm,                                   # [Double] extension/FanPowerWattsPerCFM (W/cfm)
             :cooling_design_airflow_cfm,                          # [Double] extension/CoolingDesignAirflowCFM (cfm)
             :integrated_heating_system_airflow_cfm,               # [Double] extension/HeatingDesignAirflowCFM (cfm)
             :shared_loop_watts,                                   # [Double] extension/SharedLoopWatts (W)
             :shared_loop_motor_efficiency,                        # [Double] extension/SharedLoopMotorEfficiency (frac)
             :fan_coil_watts,                                      # [Double] extension/FanCoilWatts (W)
             :crankcase_heater_watts,                              # [Double] extension/CrankcaseHeaterPowerWatts (W)
             :cooling_autosizing_factor,                           # [Double] extension/CoolingAutosizingFactor (frac)
             :cooling_autosizing_limit,                            # [Double] extension/CoolingAutosizingLimit (Btu/hr)
             :equipment_type,                                      # [String] extension/EquipmentType (HPXML::HVACEquipmentTypeXXX)
             :clg_seed_id,                                         # [String] extension/CoolingSeedId
             :htg_seed_id]                                         # [String] extension/HeatingSeedId
    attr_reader(*CLASS_ATTRS)
    attr_accessor(*ATTRS)

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def branch_circuits
      return HPXML::branch_circuits(@id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def service_feeders
      return HPXML::service_feeders(@id, @parent_object.electric_panels)
    end

    # Returns the zone that the cooling system serves.
    #
    # @return [HPXML::Zone] Zone served
    def zone
      return if @attached_to_zone_idref.nil?

      @parent_object.zones.each do |z|
        return z if z.id == @attached_to_zone_idref
      end

      fail "Attached zone '#{@attached_to_zone_idref}' not found for cooling system '#{@id}'."
    end

    # Returns the HVAC distribution system for the cooling system.
    #
    # @return [HPXML::HVACDistribution] The attached HVAC distribution system
    def distribution_system
      return if @distribution_system_idref.nil?

      @parent_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.id == @distribution_system_idref

        return hvac_distribution
      end
      fail "Attached HVAC distribution system '#{@distribution_system_idref}' not found for HVAC system '#{@id}'."
    end

    # Returns the heating system on the same distribution system as the cooling system.
    #
    # @return [HPXML::XXX] The attached heating system
    def attached_heating_system
      # by distribution system
      return if distribution_system.nil?

      distribution_system.hvac_systems.each do |hvac_system|
        next if hvac_system.id == @id

        return hvac_system
      end
      return
    end

    # Returns whether the cooling system has integrated heating.
    #
    # @return [Boolean] True if it has integrated heating
    def has_integrated_heating
      return false unless [HVACTypePTAC, HVACTypeRoomAirConditioner].include? @cooling_system_type
      return false if @integrated_heating_system_fuel.nil?

      return true
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.cooling_systems.delete(self)
      @parent_object.water_heating_systems.each do |water_heating_system|
        next unless water_heating_system.related_hvac_idref == @id

        water_heating_system.related_hvac_idref = nil
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; distribution_system; rescue StandardError => e; errors << e.message; end
      begin; zone; rescue StandardError => e; errors << e.message; end
      errors += @cooling_detailed_performance_data.check_for_errors
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      hvac_plant = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC', 'HVACPlant'])
      primary_systems = XMLHelper.create_elements_as_needed(hvac_plant, ['PrimarySystems']) unless @parent_object.primary_hvac_systems.empty?
      cooling_system = XMLHelper.add_element(hvac_plant, 'CoolingSystem')
      sys_id = XMLHelper.add_element(cooling_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      if not @attached_to_zone_idref.nil?
        zone_attached = XMLHelper.add_element(cooling_system, 'AttachedToZone')
        XMLHelper.add_attribute(zone_attached, 'idref', @attached_to_zone_idref)
      end
      XMLHelper.add_element(cooling_system, 'UnitLocation', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(cooling_system, 'YearInstalled', @year_installed, :integer) unless @year_installed.nil?
      XMLHelper.add_element(cooling_system, 'ThirdPartyCertification', @third_party_certification, :string) unless @third_party_certification.nil?
      if not @distribution_system_idref.nil?
        distribution_system = XMLHelper.add_element(cooling_system, 'DistributionSystem')
        XMLHelper.add_attribute(distribution_system, 'idref', @distribution_system_idref)
      end
      XMLHelper.add_element(cooling_system, 'IsSharedSystem', @is_shared_system, :boolean) unless @is_shared_system.nil?
      XMLHelper.add_element(cooling_system, 'NumberofUnitsServed', @number_of_units_served, :integer) unless @number_of_units_served.nil?
      XMLHelper.add_element(cooling_system, 'CoolingSystemType', @cooling_system_type, :string) unless @cooling_system_type.nil?
      XMLHelper.add_element(cooling_system, 'CoolingSystemFuel', @cooling_system_fuel, :string) unless @cooling_system_fuel.nil?
      XMLHelper.add_element(cooling_system, 'CoolingCapacity', @cooling_capacity, :float, @cooling_capacity_isdefaulted) unless @cooling_capacity.nil?
      XMLHelper.add_element(cooling_system, 'CompressorType', @compressor_type, :string, @compressor_type_isdefaulted) unless @compressor_type.nil?
      XMLHelper.add_element(cooling_system, 'FractionCoolLoadServed', @fraction_cool_load_served, :float, @fraction_cool_load_served_isdefaulted) unless @fraction_cool_load_served.nil?
      if not @cooling_efficiency_seer.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsSEER, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_seer, :float, @cooling_efficiency_seer_isdefaulted)
      end
      if not @cooling_efficiency_seer2.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsSEER2, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_seer2, :float, @cooling_efficiency_seer2_isdefaulted)
      end
      if not @cooling_efficiency_eer.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsEER, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_eer, :float, @cooling_efficiency_eer_isdefaulted)
      end
      if not @cooling_efficiency_eer2.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsEER2, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_eer2, :float, @cooling_efficiency_eer2_isdefaulted)
      end
      if not @cooling_efficiency_ceer.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsCEER, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_ceer, :float, @cooling_efficiency_ceer_isdefaulted)
      end
      if not @cooling_efficiency_kw_per_ton.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsKwPerTon, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_kw_per_ton, :float, @cooling_efficiency_kw_per_ton_isdefaulted)
      end
      @cooling_detailed_performance_data.to_doc(cooling_system)
      XMLHelper.add_element(cooling_system, 'IntegratedHeatingSystemFuel', @integrated_heating_system_fuel, :string) unless @integrated_heating_system_fuel.nil?
      XMLHelper.add_element(cooling_system, 'IntegratedHeatingSystemCapacity', @integrated_heating_system_capacity, :float, @integrated_heating_system_capacity_isdefaulted) unless @integrated_heating_system_capacity.nil?
      if not @integrated_heating_system_efficiency_percent.nil?
        annual_efficiency = XMLHelper.add_element(cooling_system, 'IntegratedHeatingSystemAnnualEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsPercent, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @integrated_heating_system_efficiency_percent, :float, @integrated_heating_system_efficiency_percent_isdefaulted)
      end
      XMLHelper.add_element(cooling_system, 'IntegratedHeatingSystemFractionHeatLoadServed', @integrated_heating_system_fraction_heat_load_served, :float) unless @integrated_heating_system_fraction_heat_load_served.nil?
      XMLHelper.add_extension(cooling_system, 'AirflowDefectRatio', @airflow_defect_ratio, :float, @airflow_defect_ratio_isdefaulted) unless @airflow_defect_ratio.nil?
      XMLHelper.add_extension(cooling_system, 'ChargeDefectRatio', @charge_defect_ratio, :float, @charge_defect_ratio_isdefaulted) unless @charge_defect_ratio.nil?
      XMLHelper.add_extension(cooling_system, 'FanMotorType', @fan_motor_type, :string, @fan_motor_type_isdefaulted) unless @fan_motor_type.nil?
      XMLHelper.add_extension(cooling_system, 'FanPowerWattsPerCFM', @fan_watts_per_cfm, :float, @fan_watts_per_cfm_isdefaulted) unless @fan_watts_per_cfm.nil?
      XMLHelper.add_extension(cooling_system, 'CoolingDesignAirflowCFM', @cooling_design_airflow_cfm, :float, @cooling_design_airflow_cfm_isdefaulted) unless @cooling_design_airflow_cfm.nil?
      XMLHelper.add_extension(cooling_system, 'HeatingDesignAirflowCFM', @integrated_heating_system_airflow_cfm, :float, @integrated_heating_system_airflow_cfm_isdefaulted) unless @integrated_heating_system_airflow_cfm.nil?
      XMLHelper.add_extension(cooling_system, 'SharedLoopWatts', @shared_loop_watts, :float) unless @shared_loop_watts.nil?
      XMLHelper.add_extension(cooling_system, 'SharedLoopMotorEfficiency', @shared_loop_motor_efficiency, :float) unless @shared_loop_motor_efficiency.nil?
      XMLHelper.add_extension(cooling_system, 'FanCoilWatts', @fan_coil_watts, :float) unless @fan_coil_watts.nil?
      XMLHelper.add_extension(cooling_system, 'CrankcaseHeaterPowerWatts', @crankcase_heater_watts, :float, @crankcase_heater_watts_isdefaulted) unless @crankcase_heater_watts.nil?
      XMLHelper.add_extension(cooling_system, 'CoolingAutosizingFactor', @cooling_autosizing_factor, :float, @cooling_autosizing_factor_isdefaulted) unless @cooling_autosizing_factor.nil?
      XMLHelper.add_extension(cooling_system, 'CoolingAutosizingLimit', @cooling_autosizing_limit, :float, @cooling_autosizing_limit_isdefaulted) unless @cooling_autosizing_limit.nil?
      XMLHelper.add_extension(cooling_system, 'EquipmentType', @equipment_type, :string, @equipment_type_isdefaulted) unless @equipment_type.nil?
      XMLHelper.add_extension(cooling_system, 'CoolingSeedId', @clg_seed_id, :string) unless @clg_seed_id.nil?
      XMLHelper.add_extension(cooling_system, 'HeatingSeedId', @htg_seed_id, :string) unless @htg_seed_id.nil?
      if @primary_system
        primary_cooling_system = XMLHelper.add_element(primary_systems, 'PrimaryCoolingSystem')
        XMLHelper.add_attribute(primary_cooling_system, 'idref', @id)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param cooling_system [Oga::XML::Element] The current CoolingSystem XML element
    # @return [nil]
    def from_doc(cooling_system)
      return if cooling_system.nil?

      @id = HPXML::get_id(cooling_system)
      @attached_to_zone_idref = HPXML::get_idref(XMLHelper.get_elements(cooling_system, 'AttachedToZone')[0])
      @location = XMLHelper.get_value(cooling_system, 'UnitLocation', :string)
      @year_installed = XMLHelper.get_value(cooling_system, 'YearInstalled', :integer)
      @third_party_certification = XMLHelper.get_value(cooling_system, 'ThirdPartyCertification', :string)
      @distribution_system_idref = HPXML::get_idref(XMLHelper.get_element(cooling_system, 'DistributionSystem'))
      @is_shared_system = XMLHelper.get_value(cooling_system, 'IsSharedSystem', :boolean)
      @number_of_units_served = XMLHelper.get_value(cooling_system, 'NumberofUnitsServed', :integer)
      @cooling_system_type = XMLHelper.get_value(cooling_system, 'CoolingSystemType', :string)
      @cooling_system_fuel = XMLHelper.get_value(cooling_system, 'CoolingSystemFuel', :string)
      @cooling_capacity = XMLHelper.get_value(cooling_system, 'CoolingCapacity', :float)
      @compressor_type = XMLHelper.get_value(cooling_system, 'CompressorType', :string)
      @fraction_cool_load_served = XMLHelper.get_value(cooling_system, 'FractionCoolLoadServed', :float)
      @cooling_efficiency_seer = XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='#{UnitsSEER}']/Value", :float)
      @cooling_efficiency_seer2 = XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='#{UnitsSEER2}']/Value", :float)
      @cooling_efficiency_eer = XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='#{UnitsEER}']/Value", :float)
      @cooling_efficiency_eer2 = XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='#{UnitsEER2}']/Value", :float)
      @cooling_efficiency_ceer = XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='#{UnitsCEER}']/Value", :float)
      @cooling_efficiency_kw_per_ton = XMLHelper.get_value(cooling_system, "AnnualCoolingEfficiency[Units='#{UnitsKwPerTon}']/Value", :float)
      @cooling_detailed_performance_data.from_doc(cooling_system)
      @integrated_heating_system_fuel = XMLHelper.get_value(cooling_system, 'IntegratedHeatingSystemFuel', :string)
      @integrated_heating_system_capacity = XMLHelper.get_value(cooling_system, 'IntegratedHeatingSystemCapacity', :float)
      @integrated_heating_system_efficiency_percent = XMLHelper.get_value(cooling_system, "IntegratedHeatingSystemAnnualEfficiency[Units='#{UnitsPercent}']/Value", :float)
      @integrated_heating_system_fraction_heat_load_served = XMLHelper.get_value(cooling_system, 'IntegratedHeatingSystemFractionHeatLoadServed', :float)
      @airflow_defect_ratio = XMLHelper.get_value(cooling_system, 'extension/AirflowDefectRatio', :float)
      @charge_defect_ratio = XMLHelper.get_value(cooling_system, 'extension/ChargeDefectRatio', :float)
      @fan_motor_type = XMLHelper.get_value(cooling_system, 'extension/FanMotorType', :string)
      @fan_watts_per_cfm = XMLHelper.get_value(cooling_system, 'extension/FanPowerWattsPerCFM', :float)
      @cooling_design_airflow_cfm = XMLHelper.get_value(cooling_system, 'extension/CoolingDesignAirflowCFM', :float)
      @integrated_heating_system_airflow_cfm = XMLHelper.get_value(cooling_system, 'extension/HeatingDesignAirflowCFM', :float)
      @shared_loop_watts = XMLHelper.get_value(cooling_system, 'extension/SharedLoopWatts', :float)
      @shared_loop_motor_efficiency = XMLHelper.get_value(cooling_system, 'extension/SharedLoopMotorEfficiency', :float)
      @fan_coil_watts = XMLHelper.get_value(cooling_system, 'extension/FanCoilWatts', :float)
      @crankcase_heater_watts = XMLHelper.get_value(cooling_system, 'extension/CrankcaseHeaterPowerWatts', :float)
      @cooling_autosizing_factor = XMLHelper.get_value(cooling_system, 'extension/CoolingAutosizingFactor', :float)
      @cooling_autosizing_limit = XMLHelper.get_value(cooling_system, 'extension/CoolingAutosizingLimit', :float)
      @equipment_type = XMLHelper.get_value(cooling_system, 'extension/EquipmentType', :string)
      @clg_seed_id = XMLHelper.get_value(cooling_system, 'extension/CoolingSeedId', :string)
      @htg_seed_id = XMLHelper.get_value(cooling_system, 'extension/HeatingSeedId', :string)
      primary_cooling_system = HPXML::get_idref(XMLHelper.get_element(cooling_system, '../PrimarySystems/PrimaryCoolingSystem'))
      if primary_cooling_system == @id
        @primary_system = true
      else
        @primary_system = false
      end
    end
  end

  # Array of HPXML::HeatPump objects.
  class HeatPumps < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << HeatPump.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/HVAC/HVACPlant/HeatPump').each do |heat_pump|
        self << HeatPump.new(@parent_object, heat_pump)
      end
    end

    # Returns the total fraction of building's heating load served by all heat pumps.
    #
    # @return [Double] Total fraction of building's heating load served
    def total_fraction_heat_load_served
      map { |hp| hp.fraction_heat_load_served.to_f }.sum(0.0)
    end

    # Returns the total fraction of building's cooling load served by all heat pumps.
    #
    # @return [Double] Total fraction of building's cooling load served
    def total_fraction_cool_load_served
      map { |hp| hp.fraction_cool_load_served.to_f }.sum(0.0)
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump.
  class HeatPump < BaseElement
    def initialize(hpxml_element, *args, **kwargs)
      @cooling_detailed_performance_data = CoolingDetailedPerformanceData.new(hpxml_element)
      @heating_detailed_performance_data = HeatingDetailedPerformanceData.new(hpxml_element)
      super(hpxml_element, *args, **kwargs)
    end
    CLASS_ATTRS = [:cooling_detailed_performance_data, # [HPXML::CoolingDetailedPerformanceData]
                   :heating_detailed_performance_data] # [HPXML::HeatingDetailedPerformanceData]
    ATTRS = [:primary_heating_system,               # [Boolean] ../PrimarySystems/PrimaryHeatingSystem/@idref
             :primary_cooling_system,               # [Boolean] ../PrimarySystems/PrimaryCoolingSystem/@idref
             :id,                                   # [String] SystemIdentifier/@id
             :sameas_id,                            # [String] SystemIdentifier/@sameas
             :attached_to_zone_idref,               # [String] AttachedToZone/@idref
             :location,                             # [String] UnitLocation (HPXML::LocationXXX)
             :year_installed,                       # [Integer] YearInstalled
             :third_party_certification,            # [String] ThirdPartyCertification
             :distribution_system_idref,            # [String] DistributionSystem/@idref
             :is_shared_system,                     # [Boolean] IsSharedSystem
             :number_of_units_served,               # [Integer] NumberofUnitsServed
             :heat_pump_type,                       # [String] HeatPumpType (HPXML::HVACTypeXXX)
             :heat_pump_fuel,                       # [String] HeatPumpFuel (HPXML::FuelTypeXXX)
             :heating_capacity,                     # [Double] HeatingCapacity (Btu/hr)
             :heating_capacity_17F,                 # [Double] HeatingCapacity17F (Btu/hr)
             :cooling_capacity,                     # [Double] CoolingCapacity (Btu/hr)
             :compressor_type,                      # [String] CompressorType (HPXML::HVACCompressorTypeXXX)
             :compressor_lockout_temp,              # [Double] CompressorLockoutTemperature (F)
             :backup_type,                          # [String] BackupType (HPXML::HeatPumpBackupTypeXXX)
             :backup_system_idref,                  # [String] BackupSystem/@idref
             :backup_heating_fuel,                  # [String] BackupSystemFuel (HPXML::FuelTypeXXX)
             :backup_heating_efficiency_percent,    # [Double] BackupAnnualHeatingEfficiency[Units="Percent"]/Value (frac)
             :backup_heating_efficiency_afue,       # [Double] BackupAnnualHeatingEfficiency[Units="AFUE"]/Value (frac)
             :backup_heating_capacity,              # [Double] BackupHeatingCapacity (Btu/hr)
             :backup_heating_switchover_temp,       # [Double] BackupHeatingSwitchoverTemperature (F)
             :backup_heating_lockout_temp,          # [Double] BackupHeatingLockoutTemperature (F)
             :fraction_heat_load_served,            # [Double] FractionHeatLoadServed (frac)
             :fraction_cool_load_served,            # [Double] FractionCoolLoadServed (frac)
             :cooling_efficiency_seer,              # [Double] AnnualCoolingEfficiency[Units="SEER"]/Value (Btu/Wh)
             :cooling_efficiency_seer2,             # [Double] AnnualCoolingEfficiency[Units="SEER2"]/Value (Btu/Wh)
             :cooling_efficiency_eer,               # [Double] AnnualCoolingEfficiency[Units="EER"]/Value (Btu/Wh)
             :cooling_efficiency_eer2,              # [Double] AnnualCoolingEfficiency[Units="EER2"]/Value (Btu/Wh)
             :cooling_efficiency_ceer,              # [Double] AnnualCoolingEfficiency[Units="CEER"]/Value (Btu/Wh)
             :heating_efficiency_hspf,              # [Double] AnnualHeatingEfficiency[Units="HSPF"]/Value (Btu/Wh)
             :heating_efficiency_hspf2,             # [Double] AnnualHeatingEfficiency[Units="HSPF2"]/Value (Btu/Wh)
             :heating_efficiency_cop,               # [Double] AnnualHeatingEfficiency[Units="COP"]/Value (W/W)
             :geothermal_loop_idref,                # [String] AttachedToGeothermalLoop/@idref
             :airflow_defect_ratio,                 # [Double] extension/AirflowDefectRatio (frac)
             :charge_defect_ratio,                  # [Double] extension/ChargeDefectRatio (frac)
             :fan_motor_type,                       # [String] extension/FanMotorType
             :fan_watts_per_cfm,                    # [Double] extension/FanPowerWattsPerCFM (W/cfm)
             :heating_design_airflow_cfm,           # [Double] extension/HeatingDesignAirflowCFM (cfm)
             :cooling_design_airflow_cfm,           # [Double] extension/CoolingDesignAirflowCFM (cfm)
             :pump_watts_per_ton,                   # [Double] extension/PumpPowerWattsPerTon (W/ton)
             :shared_loop_watts,                    # [Double] extension/SharedLoopWatts (W)
             :shared_loop_motor_efficiency,         # [Double] extension/SharedLoopMotorEfficiency (frac)
             :crankcase_heater_watts,               # [Double] extension/CrankcaseHeaterPowerWatts (W)
             :pan_heater_watts,                     # [Double] extension/PanHeaterPowerWatts (W)
             :pan_heater_control_type,              # [String] extension/PanHeaterControlType (HPXML::HVACPanHeaterControlTypeXXX)
             :backup_heating_active_during_defrost, # [Boolean] extension/BackupHeatingActiveDuringDefrost
             :heating_capacity_fraction_17F,        # [Double] extension/HeatingCapacityFraction17F (frac)
             :cooling_autosizing_factor,            # [Double] extension/CoolingAutosizingFactor (frac)
             :heating_autosizing_factor,            # [Double] extension/HeatingAutosizingFactor (frac)
             :backup_heating_autosizing_factor,     # [Double] extension/BackupHeatingAutosizingFactor (frac)
             :cooling_autosizing_limit,             # [Double] extension/CoolingAutosizingLimit (Btu/hr)
             :heating_autosizing_limit,             # [Double] extension/HeatingAutosizingLimit (Btu/hr)
             :backup_heating_autosizing_limit,      # [Double] extension/BackupHeatingAutosizingLimit (Btu/hr)
             :equipment_type,                       # [String] extension/EquipmentType (HPXML::HVACEquipmentTypeXXX)
             :htg_seed_id,                          # [String] extension/HeatingSeedId (Used by OS-ERI)
             :clg_seed_id]                          # [String] extension/CoolingSeedId (Used by OS-ERI)
    attr_reader(*CLASS_ATTRS)
    attr_accessor(*ATTRS)

    # Based on compressor and backup heating lockout temperatures, returns whether the heat pump and backup system can both operate in the same temperature range.
    # Note that this indicates there may be simultaneous operation (e.g., a heat pump with integrated electric backup) or they may cycle (e.g., a dual-fuel heat pump).
    #
    # @return [Boolean] True if backup system can operate at the same time as the compressor
    def overlapping_compressor_and_backup_operation
      if !@compressor_lockout_temp.nil? &&
         !@backup_heating_lockout_temp.nil? &&
         (@backup_heating_lockout_temp > @compressor_lockout_temp)
        return true
      end

      return false
    end

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def branch_circuits
      return HPXML::branch_circuits(@id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def service_feeders
      return HPXML::service_feeders(@id, @parent_object.electric_panels)
    end

    # Returns the zone that the heat pump serves.
    #
    # @return [HPXML::Zone] Zone served
    def zone
      return if @attached_to_zone_idref.nil?

      @parent_object.zones.each do |z|
        return z if z.id == @attached_to_zone_idref
      end

      fail "Attached zone '#{@attached_to_zone_idref}' not found for heat pump '#{@id}'."
    end

    # Returns the HVAC distribution system for the heat pump.
    #
    # @return [HPXML::HVACDistribution] The attached HVAC distribution system
    def distribution_system
      return if @distribution_system_idref.nil?

      @parent_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.id == @distribution_system_idref

        return hvac_distribution
      end
      fail "Attached HVAC distribution system '#{@distribution_system_idref}' not found for HVAC system '#{@id}'."
    end

    # Returns the geothermal loop for the (ground source) heat pump.
    #
    # @return [HPXML::GeothermalLoop] The attached geothermal loop
    def geothermal_loop
      return if @geothermal_loop_idref.nil?

      @parent_object.geothermal_loops.each do |geothermal_loop|
        next unless geothermal_loop.id == @geothermal_loop_idref

        return geothermal_loop
      end
      fail "Attached geothermal loop '#{@geothermal_loop_idref}' not found for heat pump '#{@id}'."
    end

    # Returns whether the heat pump is a dual-fuel heat pump (i.e., an electric
    # heat pump with fossil fuel backup).
    #
    # @return [Boolean] True if it is dual-fuel
    def is_dual_fuel
      if backup_system.nil?
        if @backup_heating_fuel.nil?
          return false
        end
        if @backup_heating_fuel.to_s == @heat_pump_fuel.to_s
          return false
        end
      else
        if backup_system.heating_system_fuel.to_s == @heat_pump_fuel.to_s
          return false
        end
      end

      return true
    end

    # Returns whether the heat pump is the primary heating or cooling system.
    #
    # @return [Boolean] True if the primary heating and/or cooling system
    def primary_system
      return @primary_heating_system || @primary_cooling_system
    end

    # Returns the backup heating system for the heat pump, if the heat pump
    # has a separate (i.e., not integrated) backup system.
    #
    # @return [HPXML::HeatingSystem] The backup heating system
    def backup_system
      return if @backup_system_idref.nil?

      @parent_object.heating_systems.each do |heating_system|
        next unless heating_system.id == @backup_system_idref

        return heating_system
      end
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.heat_pumps.delete(self)
      @parent_object.water_heating_systems.each do |water_heating_system|
        next unless water_heating_system.related_hvac_idref == @id

        water_heating_system.related_hvac_idref = nil
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; distribution_system; rescue StandardError => e; errors << e.message; end
      begin; zone; rescue StandardError => e; errors << e.message; end
      begin; geothermal_loop; rescue StandardError => e; errors << e.message; end
      errors += @cooling_detailed_performance_data.check_for_errors
      errors += @heating_detailed_performance_data.check_for_errors
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      hvac_plant = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC', 'HVACPlant'])
      primary_systems = XMLHelper.create_elements_as_needed(hvac_plant, ['PrimarySystems']) unless @parent_object.primary_hvac_systems.empty?
      heat_pump = XMLHelper.add_element(hvac_plant, 'HeatPump')
      sys_id = XMLHelper.add_element(heat_pump, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      if not @attached_to_zone_idref.nil?
        zone_attached = XMLHelper.add_element(heat_pump, 'AttachedToZone')
        XMLHelper.add_attribute(zone_attached, 'idref', @attached_to_zone_idref)
      end
      XMLHelper.add_element(heat_pump, 'UnitLocation', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(heat_pump, 'YearInstalled', @year_installed, :integer) unless @year_installed.nil?
      XMLHelper.add_element(heat_pump, 'ThirdPartyCertification', @third_party_certification, :string) unless @third_party_certification.nil?
      if not @distribution_system_idref.nil?
        distribution_system = XMLHelper.add_element(heat_pump, 'DistributionSystem')
        XMLHelper.add_attribute(distribution_system, 'idref', @distribution_system_idref)
      end
      XMLHelper.add_element(heat_pump, 'IsSharedSystem', @is_shared_system, :boolean) unless @is_shared_system.nil?
      XMLHelper.add_element(heat_pump, 'NumberofUnitsServed', @number_of_units_served, :integer) unless @number_of_units_served.nil?
      XMLHelper.add_element(heat_pump, 'HeatPumpType', @heat_pump_type, :string) unless @heat_pump_type.nil?
      XMLHelper.add_element(heat_pump, 'HeatPumpFuel', @heat_pump_fuel, :string) unless @heat_pump_fuel.nil?
      XMLHelper.add_element(heat_pump, 'HeatingCapacity', @heating_capacity, :float, @heating_capacity_isdefaulted) unless @heating_capacity.nil?
      XMLHelper.add_element(heat_pump, 'HeatingCapacity17F', @heating_capacity_17F, :float, @heating_capacity_17F_isdefaulted) unless @heating_capacity_17F.nil?
      XMLHelper.add_element(heat_pump, 'CoolingCapacity', @cooling_capacity, :float, @cooling_capacity_isdefaulted) unless @cooling_capacity.nil?
      XMLHelper.add_element(heat_pump, 'CompressorType', @compressor_type, :string, @compressor_type_isdefaulted) unless @compressor_type.nil?
      XMLHelper.add_element(heat_pump, 'CompressorLockoutTemperature', @compressor_lockout_temp, :float, @compressor_lockout_temp_isdefaulted) unless @compressor_lockout_temp.nil?
      XMLHelper.add_element(heat_pump, 'BackupType', @backup_type, :string, @backup_type_isdefaulted) unless @backup_type.nil?
      if not @backup_system_idref.nil?
        backup_system = XMLHelper.add_element(heat_pump, 'BackupSystem')
        XMLHelper.add_attribute(backup_system, 'idref', @backup_system_idref)
      end
      XMLHelper.add_element(heat_pump, 'BackupSystemFuel', @backup_heating_fuel, :string, @backup_heating_fuel_isdefaulted) unless @backup_heating_fuel.nil?
      if not @backup_heating_efficiency_percent.nil?
        backup_eff = XMLHelper.add_element(heat_pump, 'BackupAnnualHeatingEfficiency')
        XMLHelper.add_element(backup_eff, 'Units', UnitsPercent, :string)
        XMLHelper.add_element(backup_eff, 'Value', @backup_heating_efficiency_percent, :float)
      end
      if not @backup_heating_efficiency_afue.nil?
        backup_eff = XMLHelper.add_element(heat_pump, 'BackupAnnualHeatingEfficiency')
        XMLHelper.add_element(backup_eff, 'Units', UnitsAFUE, :string)
        XMLHelper.add_element(backup_eff, 'Value', @backup_heating_efficiency_afue, :float)
      end
      XMLHelper.add_element(heat_pump, 'BackupHeatingCapacity', @backup_heating_capacity, :float, @backup_heating_capacity_isdefaulted) unless @backup_heating_capacity.nil?
      XMLHelper.add_element(heat_pump, 'BackupHeatingSwitchoverTemperature', @backup_heating_switchover_temp, :float, @backup_heating_switchover_temp_isdefaulted) unless @backup_heating_switchover_temp.nil?
      XMLHelper.add_element(heat_pump, 'BackupHeatingLockoutTemperature', @backup_heating_lockout_temp, :float, @backup_heating_lockout_temp_isdefaulted) unless @backup_heating_lockout_temp.nil?
      XMLHelper.add_element(heat_pump, 'FractionHeatLoadServed', @fraction_heat_load_served, :float, @fraction_heat_load_served_isdefaulted) unless @fraction_heat_load_served.nil?
      XMLHelper.add_element(heat_pump, 'FractionCoolLoadServed', @fraction_cool_load_served, :float, @fraction_cool_load_served_isdefaulted) unless @fraction_cool_load_served.nil?
      if not @cooling_efficiency_seer.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsSEER, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_seer, :float, @cooling_efficiency_seer_isdefaulted)
      end
      if not @cooling_efficiency_seer2.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsSEER2, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_seer2, :float, @cooling_efficiency_seer2_isdefaulted)
      end
      if not @cooling_efficiency_ceer.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsCEER, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_ceer, :float, @cooling_efficiency_ceer_isdefaulted)
      end
      if not @cooling_efficiency_eer.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsEER, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_eer, :float, @cooling_efficiency_eer_isdefaulted)
      end
      if not @cooling_efficiency_eer2.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualCoolingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsEER2, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @cooling_efficiency_eer2, :float, @cooling_efficiency_eer2_isdefaulted)
      end
      if not @heating_efficiency_hspf.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualHeatingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsHSPF, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @heating_efficiency_hspf, :float, @heating_efficiency_hspf_isdefaulted)
      end
      if not @heating_efficiency_hspf2.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualHeatingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsHSPF2, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @heating_efficiency_hspf2, :float, @heating_efficiency_hspf2_isdefaulted)
      end
      if not @heating_efficiency_cop.nil?
        annual_efficiency = XMLHelper.add_element(heat_pump, 'AnnualHeatingEfficiency')
        XMLHelper.add_element(annual_efficiency, 'Units', UnitsCOP, :string)
        XMLHelper.add_element(annual_efficiency, 'Value', @heating_efficiency_cop, :float, @heating_efficiency_cop_isdefaulted)
      end
      if not @geothermal_loop_idref.nil?
        attached_to_geothermal_loop = XMLHelper.add_element(heat_pump, 'AttachedToGeothermalLoop')
        XMLHelper.add_attribute(attached_to_geothermal_loop, 'idref', @geothermal_loop_idref)
      end
      @cooling_detailed_performance_data.to_doc(heat_pump)
      @heating_detailed_performance_data.to_doc(heat_pump)
      XMLHelper.add_extension(heat_pump, 'AirflowDefectRatio', @airflow_defect_ratio, :float, @airflow_defect_ratio_isdefaulted) unless @airflow_defect_ratio.nil?
      XMLHelper.add_extension(heat_pump, 'ChargeDefectRatio', @charge_defect_ratio, :float, @charge_defect_ratio_isdefaulted) unless @charge_defect_ratio.nil?
      XMLHelper.add_extension(heat_pump, 'FanMotorType', @fan_motor_type, :string, @fan_motor_type_isdefaulted) unless @fan_motor_type.nil?
      XMLHelper.add_extension(heat_pump, 'FanPowerWattsPerCFM', @fan_watts_per_cfm, :float, @fan_watts_per_cfm_isdefaulted) unless @fan_watts_per_cfm.nil?
      XMLHelper.add_extension(heat_pump, 'HeatingDesignAirflowCFM', @heating_design_airflow_cfm, :float, @heating_design_airflow_cfm_isdefaulted) unless @heating_design_airflow_cfm.nil?
      XMLHelper.add_extension(heat_pump, 'CoolingDesignAirflowCFM', @cooling_design_airflow_cfm, :float, @cooling_design_airflow_cfm_isdefaulted) unless @cooling_design_airflow_cfm.nil?
      XMLHelper.add_extension(heat_pump, 'PumpPowerWattsPerTon', @pump_watts_per_ton, :float, @pump_watts_per_ton_isdefaulted) unless @pump_watts_per_ton.nil?
      XMLHelper.add_extension(heat_pump, 'SharedLoopWatts', @shared_loop_watts, :float) unless @shared_loop_watts.nil?
      XMLHelper.add_extension(heat_pump, 'SharedLoopMotorEfficiency', @shared_loop_motor_efficiency, :float) unless @shared_loop_motor_efficiency.nil?
      XMLHelper.add_extension(heat_pump, 'CrankcaseHeaterPowerWatts', @crankcase_heater_watts, :float, @crankcase_heater_watts_isdefaulted) unless @crankcase_heater_watts.nil?
      XMLHelper.add_extension(heat_pump, 'PanHeaterPowerWatts', @pan_heater_watts, :float, @pan_heater_watts_isdefaulted) unless @pan_heater_watts.nil?
      XMLHelper.add_extension(heat_pump, 'PanHeaterControlType', @pan_heater_control_type, :string, @pan_heater_control_type_isdefaulted) unless @pan_heater_control_type.nil?
      XMLHelper.add_extension(heat_pump, 'BackupHeatingActiveDuringDefrost', @backup_heating_active_during_defrost, :boolean, @backup_heating_active_during_defrost_isdefaulted) unless @backup_heating_active_during_defrost.nil?
      XMLHelper.add_extension(heat_pump, 'HeatingCapacityFraction17F', @heating_capacity_fraction_17F, :float, @heating_capacity_fraction_17F_isdefaulted) unless @heating_capacity_fraction_17F.nil?
      XMLHelper.add_extension(heat_pump, 'CoolingAutosizingFactor', @cooling_autosizing_factor, :float, @cooling_autosizing_factor_isdefaulted) unless @cooling_autosizing_factor.nil?
      XMLHelper.add_extension(heat_pump, 'HeatingAutosizingFactor', @heating_autosizing_factor, :float, @heating_autosizing_factor_isdefaulted) unless @heating_autosizing_factor.nil?
      XMLHelper.add_extension(heat_pump, 'BackupHeatingAutosizingFactor', @backup_heating_autosizing_factor, :float, @backup_heating_autosizing_factor_isdefaulted) unless @backup_heating_autosizing_factor.nil?
      XMLHelper.add_extension(heat_pump, 'CoolingAutosizingLimit', @cooling_autosizing_limit, :float, @cooling_autosizing_limit_isdefaulted) unless @cooling_autosizing_limit.nil?
      XMLHelper.add_extension(heat_pump, 'HeatingAutosizingLimit', @heating_autosizing_limit, :float, @heating_autosizing_limit_isdefaulted) unless @heating_autosizing_limit.nil?
      XMLHelper.add_extension(heat_pump, 'BackupHeatingAutosizingLimit', @backup_heating_autosizing_limit, :float, @backup_heating_autosizing_limit_isdefaulted) unless @backup_heating_autosizing_limit.nil?
      XMLHelper.add_extension(heat_pump, 'EquipmentType', @equipment_type, :string, @equipment_type_isdefaulted) unless @equipment_type.nil?
      XMLHelper.add_extension(heat_pump, 'HeatingSeedId', @htg_seed_id, :string) unless @htg_seed_id.nil?
      XMLHelper.add_extension(heat_pump, 'CoolingSeedId', @clg_seed_id, :string) unless @clg_seed_id.nil?
      if @primary_heating_system
        primary_heating_system = XMLHelper.insert_element(primary_systems, 'PrimaryHeatingSystem')
        XMLHelper.add_attribute(primary_heating_system, 'idref', @id)
      end
      if @primary_cooling_system
        primary_cooling_system = XMLHelper.add_element(primary_systems, 'PrimaryCoolingSystem')
        XMLHelper.add_attribute(primary_cooling_system, 'idref', @id)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param heat_pump [Oga::XML::Element] The current HeatPump XML element
    # @return [nil]
    def from_doc(heat_pump)
      return if heat_pump.nil?

      @id = HPXML::get_id(heat_pump)
      @attached_to_zone_idref = HPXML::get_idref(XMLHelper.get_elements(heat_pump, 'AttachedToZone')[0])
      @location = XMLHelper.get_value(heat_pump, 'UnitLocation', :string)
      @year_installed = XMLHelper.get_value(heat_pump, 'YearInstalled', :integer)
      @third_party_certification = XMLHelper.get_value(heat_pump, 'ThirdPartyCertification', :string)
      @distribution_system_idref = HPXML::get_idref(XMLHelper.get_element(heat_pump, 'DistributionSystem'))
      @is_shared_system = XMLHelper.get_value(heat_pump, 'IsSharedSystem', :boolean)
      @number_of_units_served = XMLHelper.get_value(heat_pump, 'NumberofUnitsServed', :integer)
      @heat_pump_type = XMLHelper.get_value(heat_pump, 'HeatPumpType', :string)
      @heat_pump_fuel = XMLHelper.get_value(heat_pump, 'HeatPumpFuel', :string)
      @heating_capacity = XMLHelper.get_value(heat_pump, 'HeatingCapacity', :float)
      @heating_capacity_17F = XMLHelper.get_value(heat_pump, 'HeatingCapacity17F', :float)
      @cooling_capacity = XMLHelper.get_value(heat_pump, 'CoolingCapacity', :float)
      @compressor_type = XMLHelper.get_value(heat_pump, 'CompressorType', :string)
      @compressor_lockout_temp = XMLHelper.get_value(heat_pump, 'CompressorLockoutTemperature', :float)
      @backup_type = XMLHelper.get_value(heat_pump, 'BackupType', :string)
      @backup_system_idref = HPXML::get_idref(XMLHelper.get_element(heat_pump, 'BackupSystem'))
      @backup_heating_fuel = XMLHelper.get_value(heat_pump, 'BackupSystemFuel', :string)
      @backup_heating_efficiency_percent = XMLHelper.get_value(heat_pump, "BackupAnnualHeatingEfficiency[Units='Percent']/Value", :float)
      @backup_heating_efficiency_afue = XMLHelper.get_value(heat_pump, "BackupAnnualHeatingEfficiency[Units='#{UnitsAFUE}']/Value", :float)
      @backup_heating_capacity = XMLHelper.get_value(heat_pump, 'BackupHeatingCapacity', :float)
      @backup_heating_switchover_temp = XMLHelper.get_value(heat_pump, 'BackupHeatingSwitchoverTemperature', :float)
      @backup_heating_lockout_temp = XMLHelper.get_value(heat_pump, 'BackupHeatingLockoutTemperature', :float)
      @fraction_heat_load_served = XMLHelper.get_value(heat_pump, 'FractionHeatLoadServed', :float)
      @fraction_cool_load_served = XMLHelper.get_value(heat_pump, 'FractionCoolLoadServed', :float)
      @cooling_efficiency_seer = XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='#{UnitsSEER}']/Value", :float)
      @cooling_efficiency_seer2 = XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='#{UnitsSEER2}']/Value", :float)
      @cooling_efficiency_ceer = XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='#{UnitsCEER}']/Value", :float)
      @cooling_efficiency_eer = XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='#{UnitsEER}']/Value", :float)
      @cooling_efficiency_eer2 = XMLHelper.get_value(heat_pump, "AnnualCoolingEfficiency[Units='#{UnitsEER2}']/Value", :float)
      @heating_efficiency_hspf = XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='#{UnitsHSPF}']/Value", :float)
      @heating_efficiency_hspf2 = XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='#{UnitsHSPF2}']/Value", :float)
      @heating_efficiency_cop = XMLHelper.get_value(heat_pump, "AnnualHeatingEfficiency[Units='#{UnitsCOP}']/Value", :float)
      @geothermal_loop_idref = HPXML::get_idref(XMLHelper.get_element(heat_pump, 'AttachedToGeothermalLoop'))
      @cooling_detailed_performance_data.from_doc(heat_pump)
      @heating_detailed_performance_data.from_doc(heat_pump)
      @airflow_defect_ratio = XMLHelper.get_value(heat_pump, 'extension/AirflowDefectRatio', :float)
      @charge_defect_ratio = XMLHelper.get_value(heat_pump, 'extension/ChargeDefectRatio', :float)
      @fan_motor_type = XMLHelper.get_value(heat_pump, 'extension/FanMotorType', :string)
      @fan_watts_per_cfm = XMLHelper.get_value(heat_pump, 'extension/FanPowerWattsPerCFM', :float)
      @heating_design_airflow_cfm = XMLHelper.get_value(heat_pump, 'extension/HeatingDesignAirflowCFM', :float)
      @cooling_design_airflow_cfm = XMLHelper.get_value(heat_pump, 'extension/CoolingDesignAirflowCFM', :float)
      @pump_watts_per_ton = XMLHelper.get_value(heat_pump, 'extension/PumpPowerWattsPerTon', :float)
      @shared_loop_watts = XMLHelper.get_value(heat_pump, 'extension/SharedLoopWatts', :float)
      @shared_loop_motor_efficiency = XMLHelper.get_value(heat_pump, 'extension/SharedLoopMotorEfficiency', :float)
      @crankcase_heater_watts = XMLHelper.get_value(heat_pump, 'extension/CrankcaseHeaterPowerWatts', :float)
      @pan_heater_watts = XMLHelper.get_value(heat_pump, 'extension/PanHeaterPowerWatts', :float)
      @pan_heater_control_type = XMLHelper.get_value(heat_pump, 'extension/PanHeaterControlType', :string)
      @backup_heating_active_during_defrost = XMLHelper.get_value(heat_pump, 'extension/BackupHeatingActiveDuringDefrost', :boolean)
      @heating_capacity_fraction_17F = XMLHelper.get_value(heat_pump, 'extension/HeatingCapacityFraction17F', :float)
      @cooling_autosizing_factor = XMLHelper.get_value(heat_pump, 'extension/CoolingAutosizingFactor', :float)
      @heating_autosizing_factor = XMLHelper.get_value(heat_pump, 'extension/HeatingAutosizingFactor', :float)
      @backup_heating_autosizing_factor = XMLHelper.get_value(heat_pump, 'extension/BackupHeatingAutosizingFactor', :float)
      @cooling_autosizing_limit = XMLHelper.get_value(heat_pump, 'extension/CoolingAutosizingLimit', :float)
      @heating_autosizing_limit = XMLHelper.get_value(heat_pump, 'extension/HeatingAutosizingLimit', :float)
      @backup_heating_autosizing_limit = XMLHelper.get_value(heat_pump, 'extension/BackupHeatingAutosizingLimit', :float)
      @equipment_type = XMLHelper.get_value(heat_pump, 'extension/EquipmentType', :string)
      @htg_seed_id = XMLHelper.get_value(heat_pump, 'extension/HeatingSeedId', :string)
      @clg_seed_id = XMLHelper.get_value(heat_pump, 'extension/CoolingSeedId', :string)
      primary_heating_system = HPXML::get_idref(XMLHelper.get_element(heat_pump, '../PrimarySystems/PrimaryHeatingSystem'))
      if primary_heating_system == @id
        @primary_heating_system = true
      else
        @primary_heating_system = false
      end
      primary_cooling_system = HPXML::get_idref(XMLHelper.get_element(heat_pump, '../PrimarySystems/PrimaryCoolingSystem'))
      if primary_cooling_system == @id
        @primary_cooling_system = true
      else
        @primary_cooling_system = false
      end
    end
  end

  # Array of HPXML::GeothermalLoop objects.
  class GeothermalLoops < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << GeothermalLoop.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/HVAC/HVACPlant/GeothermalLoop').each do |geothermal_loop|
        self << GeothermalLoop.new(@parent_object, geothermal_loop)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/GeothermalLoop.
  class GeothermalLoop < BaseElement
    ATTRS = [:id, # [String] SystemIdentifier/@id
             :sameas_id, # [String] SystemIdentifier/@sameas
             :loop_configuration, # [String] LoopConfiguration (HPXML::GeothermalLoopLoopConfigurationXXX)
             :loop_flow,          # [Double] LoopFlow (gal/min)
             :num_bore_holes,     # [Integer] BoreholesOrTrenches/Count
             :bore_length,        # [Double] BoreholesOrTrenches/Length (ft)
             :bore_spacing,       # [Double] BoreholesOrTrenches/Spacing (ft)
             :bore_diameter,      # [Double] BoreholesOrTrenches/Diameter (in)
             :grout_type,         # [String] Grout/Type (HPXML::GeothermalLoopGroutOrPipeTypeXXX)
             :grout_conductivity, # [Double] Grout/Conductivity (Btu/hr-ft-F)
             :pipe_type,          # [String] Pipe/Type (HPXML::GeothermalLoopGroutOrPipeTypeXXX)
             :pipe_conductivity,  # [Double] Pipe/Conductivity (Btu/hr-ft-F)
             :pipe_diameter,      # [Double] Pipe/Diameter (in)
             :shank_spacing,      # [Double] Pipe/ShankSpacing (in)
             :bore_config]        # [String] extension/BorefieldConfiguration (HPXML::GeothermalLoopBorefieldConfigurationXXX)
    attr_accessor(*ATTRS)

    # Returns all heat pumps connect to the geothermal loop.
    #
    # @return [Array<HPXML::HeatPump>] List of heat pump objects
    def heat_pump
      list = []
      @parent_object.heat_pumps.each do |heat_pump|
        next if heat_pump.geothermal_loop_idref.nil?
        next unless heat_pump.geothermal_loop_idref == @id

        list << heat_pump
      end

      if list.size == 0
        fail "Geothermal loop '#{@id}' found but no heat pump attached to it."
      elsif list.size > 1
        fail "Multiple heat pumps found attached to geothermal loop '#{@id}'."
      end
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.geothermal_loops.delete(self)
      @parent_object.heat_pumps.each do |heat_pump|
        next unless heat_pump.geothermal_loop_idref == @id

        heat_pump.geothermal_loop_idref = nil
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; heat_pump; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      hvac_plant = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC', 'HVACPlant'])
      geothermal_loop = XMLHelper.add_element(hvac_plant, 'GeothermalLoop')
      sys_id = XMLHelper.add_element(geothermal_loop, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(geothermal_loop, 'LoopConfiguration', @loop_configuration, :string, @loop_configuration_isdefaulted) unless @loop_configuration.nil?
      XMLHelper.add_element(geothermal_loop, 'LoopFlow', @loop_flow, :float, @loop_flow_isdefaulted) unless @loop_flow.nil?
      if (not @num_bore_holes.nil?) || (not @bore_spacing.nil?) || (not @bore_length.nil?) || (not @bore_diameter.nil?)
        boreholes_or_trenches = XMLHelper.add_element(geothermal_loop, 'BoreholesOrTrenches')
        XMLHelper.add_element(boreholes_or_trenches, 'Count', @num_bore_holes, :integer, @num_bore_holes_isdefaulted) unless @num_bore_holes.nil?
        XMLHelper.add_element(boreholes_or_trenches, 'Length', @bore_length, :float, @bore_length_isdefaulted) unless @bore_length.nil?
        XMLHelper.add_element(boreholes_or_trenches, 'Spacing', @bore_spacing, :float, @bore_spacing_isdefaulted) unless @bore_spacing.nil?
        XMLHelper.add_element(boreholes_or_trenches, 'Diameter', @bore_diameter, :float, @bore_diameter_isdefaulted) unless @bore_diameter.nil?
      end
      if (not @grout_type.nil?) || (not @grout_conductivity.nil?)
        grout = XMLHelper.add_element(geothermal_loop, 'Grout')
        XMLHelper.add_element(grout, 'Type', @grout_type, :string, @grout_type_isdefaulted) unless @grout_type.nil?
        XMLHelper.add_element(grout, 'Conductivity', @grout_conductivity, :float, @grout_conductivity_isdefaulted) unless @grout_conductivity.nil?
      end
      if (not @pipe_type.nil?) || (not @pipe_conductivity.nil?) || (not @pipe_diameter.nil?) || (not @shank_spacing.nil?)
        pipe = XMLHelper.add_element(geothermal_loop, 'Pipe')
        XMLHelper.add_element(pipe, 'Type', @pipe_type, :string, @pipe_type_isdefaulted) unless @pipe_type.nil?
        XMLHelper.add_element(pipe, 'Conductivity', @pipe_conductivity, :float, @pipe_conductivity_isdefaulted) unless @pipe_conductivity.nil?
        XMLHelper.add_element(pipe, 'Diameter', @pipe_diameter, :float, @pipe_diameter_isdefaulted) unless @pipe_diameter.nil?
        XMLHelper.add_element(pipe, 'ShankSpacing', @shank_spacing, :float, @shank_spacing_isdefaulted) unless @shank_spacing.nil?
      end
      if not @bore_config.nil?
        extension = XMLHelper.create_elements_as_needed(geothermal_loop, ['extension'])
        XMLHelper.add_element(extension, 'BorefieldConfiguration', @bore_config, :string, @bore_config_isdefaulted) unless @bore_config.nil?
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param geothermal_loop [Oga::XML::Element] The current GeothermalLoop XML element
    # @return [nil]
    def from_doc(geothermal_loop)
      return if geothermal_loop.nil?

      @id = HPXML::get_id(geothermal_loop)
      @loop_configuration = XMLHelper.get_value(geothermal_loop, 'LoopConfiguration', :string)
      @loop_flow = XMLHelper.get_value(geothermal_loop, 'LoopFlow', :float)
      @num_bore_holes = XMLHelper.get_value(geothermal_loop, 'BoreholesOrTrenches/Count', :integer)
      @bore_length = XMLHelper.get_value(geothermal_loop, 'BoreholesOrTrenches/Length', :float)
      @bore_spacing = XMLHelper.get_value(geothermal_loop, 'BoreholesOrTrenches/Spacing', :float)
      @bore_diameter = XMLHelper.get_value(geothermal_loop, 'BoreholesOrTrenches/Diameter', :float)
      @grout_type = XMLHelper.get_value(geothermal_loop, 'Grout/Type', :string)
      @grout_conductivity = XMLHelper.get_value(geothermal_loop, 'Grout/Conductivity', :float)
      @pipe_type = XMLHelper.get_value(geothermal_loop, 'Pipe/Type', :string)
      @pipe_conductivity = XMLHelper.get_value(geothermal_loop, 'Pipe/Conductivity', :float)
      @pipe_diameter = XMLHelper.get_value(geothermal_loop, 'Pipe/Diameter', :float)
      @shank_spacing = XMLHelper.get_value(geothermal_loop, 'Pipe/ShankSpacing', :float)
      @bore_config = XMLHelper.get_value(geothermal_loop, 'extension/BorefieldConfiguration', :string)
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/extension.
  class HVACPlant < BaseElement
    ATTRS = HDL_ATTRS.keys + CDL_SENS_ATTRS.keys + CDL_LAT_ATTRS.keys
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      hvac_plant = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC', 'HVACPlant'])
      HPXML.design_loads_to_doc(self, hvac_plant)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      hvac_plant = XMLHelper.get_element(building, 'BuildingDetails/Systems/HVAC/HVACPlant')
      return if hvac_plant.nil?

      HPXML.design_loads_from_doc(self, hvac_plant)
    end
  end

  # Array of HPXML::HVACControl objects.
  class HVACControls < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << HVACControl.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/HVAC/HVACControl').each do |hvac_control|
        self << HVACControl.new(@parent_object, hvac_control)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl.
  class HVACControl < BaseElement
    ATTRS = [:id,                                       # [String] SystemIdentifier/@id
             :sameas_id,                                # [String] SystemIdentifier/@sameas
             :control_type,                             # [String] ControlType (HPXML::HVACControlTypeXXX)
             :heating_setpoint_temp,                    # [Double] SetpointTempHeatingSeason (F)
             :heating_setback_temp,                     # [Double] SetbackTempHeatingSeason (F)
             :heating_setback_hours_per_week,           # [Double] TotalSetbackHoursperWeekHeating (hrs/week)
             :cooling_setup_temp,                       # [Double] SetupTempCoolingSeason (F)
             :cooling_setpoint_temp,                    # [Double] SetpointTempCoolingSeason (F)
             :cooling_setup_hours_per_week,             # [Double] TotalSetupHoursperWeekCooling (hrs/week)
             :seasons_heating_begin_month,              # [Integer] HeatingSeason/BeginMonth
             :seasons_heating_begin_day,                # [Integer] HeatingSeason/BeginDayOfMonth
             :seasons_heating_end_month,                # [Integer] HeatingSeason/EndMonth
             :seasons_heating_end_day,                  # [Integer] HeatingSeason/EndDayOfMonth
             :seasons_cooling_begin_month,              # [Integer] CoolingSeason/BeginMonth
             :seasons_cooling_begin_day,                # [Integer] CoolingSeason/BeginDayOfMonth
             :seasons_cooling_end_month,                # [Integer] CoolingSeason/EndMonth
             :seasons_cooling_end_day,                  # [Integer] CoolingSeason/EndDayOfMonth
             :heating_setback_start_hour,               # [Integer] extension/SetbackStartHourHeating
             :cooling_setup_start_hour,                 # [Integer] extension/SetupStartHourCooling
             :ceiling_fan_cooling_setpoint_temp_offset, # [Double] extension/CeilingFanSetpointTempCoolingSeasonOffset (F)
             :weekday_heating_setpoints,                # [String] extension/WeekdaySetpointTempsHeatingSeason
             :weekend_heating_setpoints,                # [String] extension/WeekendSetpointTempsHeatingSeason
             :weekday_cooling_setpoints,                # [String] extension/WeekdaySetpointTempsCoolingSeason
             :weekend_cooling_setpoints]                # [String] extension/WeekendSetpointTempsCoolingSeason
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.hvac_controls.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      errors += HPXML::check_dates('Heating Season', @seasons_heating_begin_month, @seasons_heating_begin_day, @seasons_heating_end_month, @seasons_heating_end_day)
      errors += HPXML::check_dates('Cooling Season', @seasons_cooling_begin_month, @seasons_cooling_begin_day, @seasons_cooling_end_month, @seasons_cooling_end_day)
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      hvac = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC'])
      hvac_control = XMLHelper.add_element(hvac, 'HVACControl')
      sys_id = XMLHelper.add_element(hvac_control, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(hvac_control, 'ControlType', @control_type, :string) unless @control_type.nil?
      XMLHelper.add_element(hvac_control, 'SetpointTempHeatingSeason', @heating_setpoint_temp, :float, @heating_setpoint_temp_isdefaulted) unless @heating_setpoint_temp.nil?
      XMLHelper.add_element(hvac_control, 'SetbackTempHeatingSeason', @heating_setback_temp, :float) unless @heating_setback_temp.nil?
      XMLHelper.add_element(hvac_control, 'TotalSetbackHoursperWeekHeating', @heating_setback_hours_per_week, :integer) unless @heating_setback_hours_per_week.nil?
      XMLHelper.add_element(hvac_control, 'SetupTempCoolingSeason', @cooling_setup_temp, :float) unless @cooling_setup_temp.nil?
      XMLHelper.add_element(hvac_control, 'SetpointTempCoolingSeason', @cooling_setpoint_temp, :float, @cooling_setpoint_temp_isdefaulted) unless @cooling_setpoint_temp.nil?
      XMLHelper.add_element(hvac_control, 'TotalSetupHoursperWeekCooling', @cooling_setup_hours_per_week, :integer) unless @cooling_setup_hours_per_week.nil?
      if (not @seasons_heating_begin_month.nil?) || (not @seasons_heating_begin_day.nil?) || (not @seasons_heating_end_month.nil?) || (not @seasons_heating_end_day.nil?)
        heating_season = XMLHelper.add_element(hvac_control, 'HeatingSeason')
        XMLHelper.add_element(heating_season, 'BeginMonth', @seasons_heating_begin_month, :integer, @seasons_heating_begin_month_isdefaulted) unless @seasons_heating_begin_month.nil?
        XMLHelper.add_element(heating_season, 'BeginDayOfMonth', @seasons_heating_begin_day, :integer, @seasons_heating_begin_day_isdefaulted) unless @seasons_heating_begin_day.nil?
        XMLHelper.add_element(heating_season, 'EndMonth', @seasons_heating_end_month, :integer, @seasons_heating_end_month_isdefaulted) unless @seasons_heating_end_month.nil?
        XMLHelper.add_element(heating_season, 'EndDayOfMonth', @seasons_heating_end_day, :integer, @seasons_heating_end_day_isdefaulted) unless @seasons_heating_end_day.nil?
      end
      if (not @seasons_cooling_begin_month.nil?) || (not @seasons_cooling_begin_day.nil?) || (not @seasons_cooling_end_month.nil?) || (not @seasons_cooling_end_day.nil?)
        cooling_season = XMLHelper.add_element(hvac_control, 'CoolingSeason')
        XMLHelper.add_element(cooling_season, 'BeginMonth', @seasons_cooling_begin_month, :integer, @seasons_cooling_begin_month_isdefaulted) unless @seasons_cooling_begin_month.nil?
        XMLHelper.add_element(cooling_season, 'BeginDayOfMonth', @seasons_cooling_begin_day, :integer, @seasons_cooling_begin_day_isdefaulted) unless @seasons_cooling_begin_day.nil?
        XMLHelper.add_element(cooling_season, 'EndMonth', @seasons_cooling_end_month, :integer, @seasons_cooling_end_month_isdefaulted) unless @seasons_cooling_end_month.nil?
        XMLHelper.add_element(cooling_season, 'EndDayOfMonth', @seasons_cooling_end_day, :integer, @seasons_cooling_end_day_isdefaulted) unless @seasons_cooling_end_day.nil?
      end
      XMLHelper.add_extension(hvac_control, 'SetbackStartHourHeating', @heating_setback_start_hour, :integer, @heating_setback_start_hour_isdefaulted) unless @heating_setback_start_hour.nil?
      XMLHelper.add_extension(hvac_control, 'SetupStartHourCooling', @cooling_setup_start_hour, :integer, @cooling_setup_start_hour_isdefaulted) unless @cooling_setup_start_hour.nil?
      XMLHelper.add_extension(hvac_control, 'CeilingFanSetpointTempCoolingSeasonOffset', @ceiling_fan_cooling_setpoint_temp_offset, :float) unless @ceiling_fan_cooling_setpoint_temp_offset.nil?
      XMLHelper.add_extension(hvac_control, 'WeekdaySetpointTempsHeatingSeason', @weekday_heating_setpoints, :string) unless @weekday_heating_setpoints.nil?
      XMLHelper.add_extension(hvac_control, 'WeekendSetpointTempsHeatingSeason', @weekend_heating_setpoints, :string) unless @weekend_heating_setpoints.nil?
      XMLHelper.add_extension(hvac_control, 'WeekdaySetpointTempsCoolingSeason', @weekday_cooling_setpoints, :string) unless @weekday_cooling_setpoints.nil?
      XMLHelper.add_extension(hvac_control, 'WeekendSetpointTempsCoolingSeason', @weekend_cooling_setpoints, :string) unless @weekend_cooling_setpoints.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param hvac_control [Oga::XML::Element] The current HVACControl XML element
    # @return [nil]
    def from_doc(hvac_control)
      return if hvac_control.nil?

      @id = HPXML::get_id(hvac_control)
      @control_type = XMLHelper.get_value(hvac_control, 'ControlType', :string)
      @heating_setpoint_temp = XMLHelper.get_value(hvac_control, 'SetpointTempHeatingSeason', :float)
      @heating_setback_temp = XMLHelper.get_value(hvac_control, 'SetbackTempHeatingSeason', :float)
      @heating_setback_hours_per_week = XMLHelper.get_value(hvac_control, 'TotalSetbackHoursperWeekHeating', :integer)
      @cooling_setup_temp = XMLHelper.get_value(hvac_control, 'SetupTempCoolingSeason', :float)
      @cooling_setpoint_temp = XMLHelper.get_value(hvac_control, 'SetpointTempCoolingSeason', :float)
      @cooling_setup_hours_per_week = XMLHelper.get_value(hvac_control, 'TotalSetupHoursperWeekCooling', :integer)
      @seasons_heating_begin_month = XMLHelper.get_value(hvac_control, 'HeatingSeason/BeginMonth', :integer)
      @seasons_heating_begin_day = XMLHelper.get_value(hvac_control, 'HeatingSeason/BeginDayOfMonth', :integer)
      @seasons_heating_end_month = XMLHelper.get_value(hvac_control, 'HeatingSeason/EndMonth', :integer)
      @seasons_heating_end_day = XMLHelper.get_value(hvac_control, 'HeatingSeason/EndDayOfMonth', :integer)
      @seasons_cooling_begin_month = XMLHelper.get_value(hvac_control, 'CoolingSeason/BeginMonth', :integer)
      @seasons_cooling_begin_day = XMLHelper.get_value(hvac_control, 'CoolingSeason/BeginDayOfMonth', :integer)
      @seasons_cooling_end_month = XMLHelper.get_value(hvac_control, 'CoolingSeason/EndMonth', :integer)
      @seasons_cooling_end_day = XMLHelper.get_value(hvac_control, 'CoolingSeason/EndDayOfMonth', :integer)
      @heating_setback_start_hour = XMLHelper.get_value(hvac_control, 'extension/SetbackStartHourHeating', :integer)
      @cooling_setup_start_hour = XMLHelper.get_value(hvac_control, 'extension/SetupStartHourCooling', :integer)
      @ceiling_fan_cooling_setpoint_temp_offset = XMLHelper.get_value(hvac_control, 'extension/CeilingFanSetpointTempCoolingSeasonOffset', :float)
      @weekday_heating_setpoints = XMLHelper.get_value(hvac_control, 'extension/WeekdaySetpointTempsHeatingSeason', :string)
      @weekend_heating_setpoints = XMLHelper.get_value(hvac_control, 'extension/WeekendSetpointTempsHeatingSeason', :string)
      @weekday_cooling_setpoints = XMLHelper.get_value(hvac_control, 'extension/WeekdaySetpointTempsCoolingSeason', :string)
      @weekend_cooling_setpoints = XMLHelper.get_value(hvac_control, 'extension/WeekendSetpointTempsCoolingSeason', :string)
    end
  end

  # Array of HPXML::HVACDistribution objects.
  class HVACDistributions < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << HVACDistribution.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/HVAC/HVACDistribution').each do |hvac_distribution|
        self << HVACDistribution.new(@parent_object, hvac_distribution)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution.
  class HVACDistribution < BaseElement
    def initialize(hpxml_bldg, *args, **kwargs)
      @duct_leakage_measurements = DuctLeakageMeasurements.new(hpxml_bldg)
      @ducts = Ducts.new(hpxml_bldg)
      @manualj_duct_loads = ManualJDuctLoads.new(hpxml_bldg)
      super(hpxml_bldg, *args, **kwargs)
    end
    CLASS_ATTRS = [:duct_leakage_measurements, # [HPXML::DuctLeakageMeasurements]
                   :ducts,                     # [HPXML::Ducts]
                   :manualj_duct_loads]        # [HPXML::ManualJDuctLoads]
    ATTRS = [:id,                            # [String] SystemIdentifier/@id
             :sameas_id,                     # [String] SystemIdentifier/@sameas
             :distribution_system_type,      # [String] DistributionSystemType/* (HPXML::HVACDistributionTypeXXX)
             :number_of_return_registers,    # [Integer] DistributionSystemType/AirDistribution/NumberofReturnRegisters
             :air_type,                      # [String] DistributionSystemType/AirDistribution/AirDistributionType (HPXML::AirTypeXXX)
             :manualj_blower_fan_heat_btuh,  # [Double] DistributionSystemType/AirDistribution/extension/ManualJInputs/BlowerFanHeatBtuh (Btu/hr)
             :hydronic_type,                 # [String] DistributionSystemType/HydronicDistribution/HydronicDistributionType (HPXML::HydronicTypeXXX)
             :manualj_hot_water_piping_btuh, # [Double] DistributionSystemType/HydronicDistribution/extension/ManualJInputs/HotWaterPipingBtuh (Btu/hr)
             :annual_heating_dse,            # [Double] DistributionSystemType/Other/AnnualHeatingDistributionSystemEfficiency (frac)
             :annual_cooling_dse,            # [Double] DistributionSystemType/Other/AnnualCoolingDistributionSystemEfficiency (frac)
             :conditioned_floor_area_served] # [Double] ConditionedFloorAreaServed (ft2)
    attr_reader(*CLASS_ATTRS)
    attr_accessor(*ATTRS)

    # Returns all the HVAC systems attached to this HVAC distribution system.
    #
    # @return [Array<HPXML::XXX>] The list of HVAC systems
    def hvac_systems
      list = []
      @parent_object.hvac_systems.each do |hvac_system|
        next if hvac_system.distribution_system_idref.nil?
        next unless hvac_system.distribution_system_idref == @id

        list << hvac_system
      end

      if list.size == 0
        fail "Distribution system '#{@id}' found but no HVAC system attached to it."
      end

      num_htg = 0
      num_clg = 0
      list.each do |obj|
        if obj.respond_to? :fraction_heat_load_served
          num_htg += 1 if obj.fraction_heat_load_served.to_f > 0
        end
        if obj.respond_to? :fraction_cool_load_served
          num_clg += 1 if obj.fraction_cool_load_served.to_f > 0
        end
      end

      if num_clg > 1
        fail "Multiple cooling systems found attached to distribution system '#{@id}'."
      end
      if num_htg > 1
        fail "Multiple heating systems found attached to distribution system '#{@id}'."
      end

      return list
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.hvac_distributions.delete(self)
      @parent_object.hvac_systems.each do |hvac_system|
        next if hvac_system.distribution_system_idref.nil?
        next unless hvac_system.distribution_system_idref == @id

        hvac_system.distribution_system_idref = nil
      end
      @parent_object.ventilation_fans.each do |ventilation_fan|
        next unless ventilation_fan.distribution_system_idref == @id

        ventilation_fan.distribution_system_idref = nil
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; hvac_systems; rescue StandardError => e; errors << e.message; end
      errors += @duct_leakage_measurements.check_for_errors
      errors += @ducts.check_for_errors
      errors += @manualj_duct_loads.check_for_errors
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      hvac = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'HVAC'])
      hvac_distribution = XMLHelper.add_element(hvac, 'HVACDistribution')
      sys_id = XMLHelper.add_element(hvac_distribution, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      if [HVACDistributionTypeAir, HVACDistributionTypeHydronic].include? @distribution_system_type
        distribution_system_type_el = XMLHelper.add_element(hvac_distribution, 'DistributionSystemType')
        XMLHelper.add_element(distribution_system_type_el, @distribution_system_type)
        XMLHelper.add_element(hvac_distribution, 'ConditionedFloorAreaServed', @conditioned_floor_area_served, :float) unless @conditioned_floor_area_served.nil?
      elsif [HVACDistributionTypeDSE].include? @distribution_system_type
        distribution_system_type_el = XMLHelper.add_element(hvac_distribution, 'DistributionSystemType')
        XMLHelper.add_element(distribution_system_type_el, 'Other', @distribution_system_type, :string)
        XMLHelper.add_element(hvac_distribution, 'AnnualHeatingDistributionSystemEfficiency', @annual_heating_dse, :float) unless @annual_heating_dse.nil?
        XMLHelper.add_element(hvac_distribution, 'AnnualCoolingDistributionSystemEfficiency', @annual_cooling_dse, :float) unless @annual_cooling_dse.nil?
      else
        fail "Unexpected distribution_system_type '#{@distribution_system_type}'."
      end

      if [HPXML::HVACDistributionTypeHydronic].include? @distribution_system_type
        hydronic_distribution = XMLHelper.get_element(hvac_distribution, 'DistributionSystemType/HydronicDistribution')
        XMLHelper.add_element(hydronic_distribution, 'HydronicDistributionType', @hydronic_type, :string) unless @hydronic_type.nil?
        if not @manualj_hot_water_piping_btuh.nil?
          manualj_inputs = XMLHelper.create_elements_as_needed(hydronic_distribution, ['extension', 'ManualJInputs'])
          XMLHelper.add_element(manualj_inputs, 'HotWaterPipingBtuh', @manualj_hot_water_piping_btuh, :float, @manualj_hot_water_piping_btuh_isdefaulted)
        end
      end
      if [HPXML::HVACDistributionTypeAir].include? @distribution_system_type
        air_distribution = XMLHelper.get_element(hvac_distribution, 'DistributionSystemType/AirDistribution')
        XMLHelper.add_element(air_distribution, 'AirDistributionType', @air_type, :string) unless @air_type.nil?
        @duct_leakage_measurements.to_doc(air_distribution)
        @ducts.to_doc(air_distribution)
        XMLHelper.add_element(air_distribution, 'NumberofReturnRegisters', @number_of_return_registers, :integer, @number_of_return_registers_isdefaulted) unless @number_of_return_registers.nil?
        if not @manualj_blower_fan_heat_btuh.nil?
          manualj_inputs = XMLHelper.create_elements_as_needed(air_distribution, ['extension', 'ManualJInputs'])
          XMLHelper.add_element(manualj_inputs, 'BlowerFanHeatBtuh', @manualj_blower_fan_heat_btuh, :float, @manualj_blower_fan_heat_btuh_isdefaulted)
        end
        @manualj_duct_loads.to_doc(air_distribution)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param hvac_distribution [Oga::XML::Element] The current HVACDistribution XML element
    # @return [nil]
    def from_doc(hvac_distribution)
      return if hvac_distribution.nil?

      @id = HPXML::get_id(hvac_distribution)
      @distribution_system_type = XMLHelper.get_child_name(hvac_distribution, 'DistributionSystemType')
      if @distribution_system_type == 'Other'
        @distribution_system_type = XMLHelper.get_value(XMLHelper.get_element(hvac_distribution, 'DistributionSystemType'), 'Other', :string)
      end
      @annual_heating_dse = XMLHelper.get_value(hvac_distribution, 'AnnualHeatingDistributionSystemEfficiency', :float)
      @annual_cooling_dse = XMLHelper.get_value(hvac_distribution, 'AnnualCoolingDistributionSystemEfficiency', :float)
      @conditioned_floor_area_served = XMLHelper.get_value(hvac_distribution, 'ConditionedFloorAreaServed', :float)

      air_distribution = XMLHelper.get_element(hvac_distribution, 'DistributionSystemType/AirDistribution')
      hydronic_distribution = XMLHelper.get_element(hvac_distribution, 'DistributionSystemType/HydronicDistribution')

      if not hydronic_distribution.nil?
        @hydronic_type = XMLHelper.get_value(hydronic_distribution, 'HydronicDistributionType', :string)
        @manualj_hot_water_piping_btuh = XMLHelper.get_value(hydronic_distribution, 'extension/ManualJInputs/HotWaterPipingBtuh', :float)
      end
      if not air_distribution.nil?
        @air_type = XMLHelper.get_value(air_distribution, 'AirDistributionType', :string)
        @number_of_return_registers = XMLHelper.get_value(air_distribution, 'NumberofReturnRegisters', :integer)
        @duct_leakage_measurements.from_doc(air_distribution)
        @ducts.from_doc(air_distribution)
        @manualj_blower_fan_heat_btuh = XMLHelper.get_value(air_distribution, 'extension/ManualJInputs/BlowerFanHeatBtuh', :float)
        @manualj_duct_loads.from_doc(air_distribution)
      end
    end
  end

  # Array of HPXML::DuctLeakageMeasurement objects.
  class DuctLeakageMeasurements < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << DuctLeakageMeasurement.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param hvac_distribution [Oga::XML::Element] The current HVACDistribution XML element
    # @return [nil]
    def from_doc(hvac_distribution)
      return if hvac_distribution.nil?

      XMLHelper.get_elements(hvac_distribution, 'DuctLeakageMeasurement').each do |duct_leakage_measurement|
        self << DuctLeakageMeasurement.new(@parent_object, duct_leakage_measurement)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DuctLeakageMeasurement.
  class DuctLeakageMeasurement < BaseElement
    ATTRS = [:duct_type,                        # [String] DuctType (HPXML::DuctTypeXXX)
             :duct_leakage_test_method,         # [String] DuctLeakageTestMethod
             :duct_leakage_units,               # [String] DuctLeakage/Units (HPXML::UnitsXXX)
             :duct_leakage_value,               # [Double] DuctLeakage/Value
             :duct_leakage_total_or_to_outside] # [String] DuctLeakage/TotalOrToOutside (HPXML::DuctLeakageXXX)
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.duct_leakage_measurements.include? self

        hvac_distribution.duct_leakage_measurements.delete(self)
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param air_distribution [Oga::XML::Element] Parent XML element
    # @return [nil]
    def to_doc(air_distribution)
      duct_leakage_measurement_el = XMLHelper.add_element(air_distribution, 'DuctLeakageMeasurement')
      XMLHelper.add_element(duct_leakage_measurement_el, 'DuctType', @duct_type, :string) unless @duct_type.nil?
      XMLHelper.add_element(duct_leakage_measurement_el, 'DuctLeakageTestMethod', @duct_leakage_test_method, :string) unless @duct_leakage_test_method.nil?
      if not @duct_leakage_value.nil?
        duct_leakage_el = XMLHelper.add_element(duct_leakage_measurement_el, 'DuctLeakage')
        XMLHelper.add_element(duct_leakage_el, 'Units', @duct_leakage_units, :string) unless @duct_leakage_units.nil?
        XMLHelper.add_element(duct_leakage_el, 'Value', @duct_leakage_value, :float)
        XMLHelper.add_element(duct_leakage_el, 'TotalOrToOutside', @duct_leakage_total_or_to_outside, :string) unless @duct_leakage_total_or_to_outside.nil?
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param duct_leakage_measurement [Oga::XML::Element] The current DuctLeakageMeasurement XML element
    # @return [nil]
    def from_doc(duct_leakage_measurement)
      return if duct_leakage_measurement.nil?

      @duct_type = XMLHelper.get_value(duct_leakage_measurement, 'DuctType', :string)
      @duct_leakage_test_method = XMLHelper.get_value(duct_leakage_measurement, 'DuctLeakageTestMethod', :string)
      @duct_leakage_units = XMLHelper.get_value(duct_leakage_measurement, 'DuctLeakage/Units', :string)
      @duct_leakage_value = XMLHelper.get_value(duct_leakage_measurement, 'DuctLeakage/Value', :float)
      @duct_leakage_total_or_to_outside = XMLHelper.get_value(duct_leakage_measurement, 'DuctLeakage/TotalOrToOutside', :string)
    end
  end

  # Array of HPXML::Duct objects.
  class Ducts < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Duct.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param hvac_distribution [Oga::XML::Element] The current HVACDistribution XML element
    # @return [nil]
    def from_doc(hvac_distribution)
      return if hvac_distribution.nil?

      XMLHelper.get_elements(hvac_distribution, 'Ducts').each do |duct|
        self << Duct.new(@parent_object, duct)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/Ducts.
  class Duct < BaseElement
    ATTRS = [:id,                           # [String] SystemIdentifier/@id
             :sameas_id,                    # [String] SystemIdentifier/@sameas
             :duct_type,                    # [String] DuctType (HPXML::DuctTypeXXX)
             :duct_insulation_r_value,      # [Double] DuctInsulationRValue (F-ft2-hr/Btu)
             :duct_buried_insulation_level, # [String] DuctBuriedInsulationLevel (HPXML::DuctBuriedInsulationXXX)
             :duct_effective_r_value,       # [Double] DuctEffectiveRValue (F-ft2-hr/Btu)
             :duct_location,                # [String] DuctLocation (HPXML::LocationXXX)
             :duct_fraction_area,           # [Double] FractionDuctArea (frac)
             :duct_surface_area,            # [Double] DuctSurfaceArea (ft2)
             :duct_shape,                   # [String] DuctShape (HPXML::DuctShapeXXX)
             :duct_surface_area_multiplier, # [Double] extension/DuctSurfaceAreaMultiplier
             :duct_fraction_rectangular]    # [Double] extension/DuctFractionRectangular (frac)
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.ducts.include? self

        hvac_distribution.ducts.delete(self)
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param air_distribution [Oga::XML::Element] Parent XML element
    # @return [nil]
    def to_doc(air_distribution)
      ducts_el = XMLHelper.add_element(air_distribution, 'Ducts')
      sys_id = XMLHelper.add_element(ducts_el, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(ducts_el, 'DuctType', @duct_type, :string) unless @duct_type.nil?
      XMLHelper.add_element(ducts_el, 'DuctInsulationRValue', @duct_insulation_r_value, :float) unless @duct_insulation_r_value.nil?
      XMLHelper.add_element(ducts_el, 'DuctBuriedInsulationLevel', @duct_buried_insulation_level, :string, @duct_buried_insulation_level_isdefaulted) unless @duct_buried_insulation_level.nil?
      XMLHelper.add_element(ducts_el, 'DuctEffectiveRValue', @duct_effective_r_value, :float, @duct_effective_r_value_isdefaulted) unless @duct_effective_r_value.nil?
      XMLHelper.add_element(ducts_el, 'DuctLocation', @duct_location, :string, @duct_location_isdefaulted) unless @duct_location.nil?
      XMLHelper.add_element(ducts_el, 'FractionDuctArea', @duct_fraction_area, :float, @duct_fraction_area_isdefaulted) unless @duct_fraction_area.nil?
      XMLHelper.add_element(ducts_el, 'DuctSurfaceArea', @duct_surface_area, :float, @duct_surface_area_isdefaulted) unless @duct_surface_area.nil?
      XMLHelper.add_element(ducts_el, 'DuctShape', @duct_shape, :string, @duct_shape_isdefaulted) unless @duct_shape.nil?
      XMLHelper.add_extension(ducts_el, 'DuctSurfaceAreaMultiplier', @duct_surface_area_multiplier, :float, @duct_surface_area_multiplier_isdefaulted) unless @duct_surface_area_multiplier.nil?
      XMLHelper.add_extension(ducts_el, 'DuctFractionRectangular', @duct_fraction_rectangular, :float, @duct_fraction_rectangular_isdefaulted) unless @duct_fraction_rectangular.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param duct [Oga::XML::Element] The current Duct XML element
    # @return [nil]
    def from_doc(duct)
      return if duct.nil?

      @id = HPXML::get_id(duct)
      @duct_type = XMLHelper.get_value(duct, 'DuctType', :string)
      @duct_insulation_r_value = XMLHelper.get_value(duct, 'DuctInsulationRValue', :float)
      @duct_buried_insulation_level = XMLHelper.get_value(duct, 'DuctBuriedInsulationLevel', :string)
      @duct_effective_r_value = XMLHelper.get_value(duct, 'DuctEffectiveRValue', :float)
      @duct_location = XMLHelper.get_value(duct, 'DuctLocation', :string)
      @duct_fraction_area = XMLHelper.get_value(duct, 'FractionDuctArea', :float)
      @duct_surface_area = XMLHelper.get_value(duct, 'DuctSurfaceArea', :float)
      @duct_shape = XMLHelper.get_value(duct, 'DuctShape', :string)
      @duct_surface_area_multiplier = XMLHelper.get_value(duct, 'extension/DuctSurfaceAreaMultiplier', :float)
      @duct_fraction_rectangular = XMLHelper.get_value(duct, 'extension/DuctFractionRectangular', :float)
    end
  end

  # Array of HPXML::ManualJDuctLoad objects.
  class ManualJDuctLoads < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << ManualJDuctLoad.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param hvac_distribution [Oga::XML::Element] The current HVACDistribution XML element
    # @return [nil]
    def from_doc(hvac_distribution)
      return if hvac_distribution.nil?

      XMLHelper.get_elements(hvac_distribution, 'extension/ManualJInputs/DefaultTableDuctLoad').each do |manualj_duct_load|
        self << ManualJDuctLoad.new(@parent_object, manualj_duct_load)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/extension/ManualJInputs/DefaultTableDuctLoad.
  class ManualJDuctLoad < BaseElement
    ATTRS = [:table_number,        # [String] TableNumber
             :lookup_floor_area,   # [Double] LookupFloorArea (ft2)
             :leakage_level,       # [String] LeakageLevel (HPXML::ManualJDuctLeakageLevelXXX)
             :insulation_r_value,  # [Double] InsulationRValue (F-ft2-hr/Btu)
             :supply_surface_area, # [Double] SupplySurfaceArea (ft2)
             :return_surface_area, # [Double] ReturnSurfaceArea (ft2)
             :dsf]                 # [Double] DSF (frac)
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.manualj_duct_loads.include? self

        hvac_distribution.manualj_duct_loads.delete(self)
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param air_distribution [Oga::XML::Element] Parent XML element
    # @return [nil]
    def to_doc(air_distribution)
      if (not @table_number.nil?) || (not @lookup_floor_area.nil?) || (not @leakage_level.nil?) || (not @insulation_r_value.nil?) || (not @supply_surface_area.nil?) || (not @return_surface_area.nil?) || (not @dsf.nil?)
        manualj_inputs = XMLHelper.create_elements_as_needed(air_distribution, ['extension', 'ManualJInputs'])
        duct_load = XMLHelper.add_element(manualj_inputs, 'DefaultTableDuctLoad')
        XMLHelper.add_element(duct_load, 'TableNumber', @table_number, :string) unless @table_number.nil?
        XMLHelper.add_element(duct_load, 'LookupFloorArea', @lookup_floor_area, :float) unless @lookup_floor_area.nil?
        XMLHelper.add_element(duct_load, 'LeakageLevel', @leakage_level, :string) unless @leakage_level.nil?
        XMLHelper.add_element(duct_load, 'InsulationRValue', @insulation_r_value, :float) unless @insulation_r_value.nil?
        XMLHelper.add_element(duct_load, 'SupplySurfaceArea', @supply_surface_area, :float) unless @supply_surface_area.nil?
        XMLHelper.add_element(duct_load, 'ReturnSurfaceArea', @return_surface_area, :float) unless @return_surface_area.nil?
        XMLHelper.add_element(duct_load, 'DSF', @dsf, :float) unless @dsf.nil?
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param manualj_duct_load [Oga::XML::Element] The current ManualJDuctLoad XML element
    # @return [nil]
    def from_doc(manualj_duct_load)
      return if manualj_duct_load.nil?

      @table_number = XMLHelper.get_value(manualj_duct_load, 'TableNumber', :string)
      @lookup_floor_area = XMLHelper.get_value(manualj_duct_load, 'LookupFloorArea', :float)
      @leakage_level = XMLHelper.get_value(manualj_duct_load, 'LeakageLevel', :string)
      @insulation_r_value = XMLHelper.get_value(manualj_duct_load, 'InsulationRValue', :float)
      @supply_surface_area = XMLHelper.get_value(manualj_duct_load, 'SupplySurfaceArea', :float)
      @return_surface_area = XMLHelper.get_value(manualj_duct_load, 'ReturnSurfaceArea', :float)
      @return_surface_area = XMLHelper.get_value(manualj_duct_load, 'ReturnSurfaceArea', :float)
      @dsf = XMLHelper.get_value(manualj_duct_load, 'DSF', :float)
    end
  end

  # Array of HPXML::VentilationFan objects.
  class VentilationFans < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << VentilationFan.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan').each do |ventilation_fan|
        self << VentilationFan.new(@parent_object, ventilation_fan)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan.
  class VentilationFan < BaseElement
    ATTRS = [:id,                                              # [String] SystemIdentifier/@id
             :sameas_id,                                       # [String] SystemIdentifier/@sameas
             :count,                                           # [Integer] Count
             :fan_type,                                        # [String] FanType (HPXML::MechVentTypeXXX)
             :cfis_has_outdoor_air_control,                    # [Boolean] CFISControls/HasOutdoorAirControl
             :cfis_addtl_runtime_operating_mode,               # [String] CFISControls/AdditionalRuntimeOperatingMode (HPXML::CFISModeXXX)
             :cfis_supplemental_fan_idref,                     # [String] CFISControls/SupplementalFan/@idref
             :cfis_control_type,                               # [String] CFISControls/extension/ControlType (HPXML::CFISControlTypeXXX)
             :cfis_supplemental_fan_runs_with_air_handler_fan, # [Boolean] CFISControls/extension/SupplementalFanRunsWithAirHandlerFan
             :rated_flow_rate,                                 # [Double] RatedFlowRate (cfm)
             :calculated_flow_rate,                            # [Double] CalculatedFlowRate (cfm)
             :tested_flow_rate,                                # [Double] TestedFlowRate (cfm)
             :hours_in_operation,                              # [Double] HoursInOperation (hrs/day)
             :delivered_ventilation,                           # [Double] DeliveredVentilation (cfm)
             :fan_location,                                    # [String] FanLocation (HPXML::LocationXXX)
             :used_for_local_ventilation,                      # [Boolean] UsedForLocalVentilation
             :used_for_whole_building_ventilation,             # [Boolean] UsedForWholeBuildingVentilation
             :used_for_seasonal_cooling_load_reduction,        # [Boolean] UsedForSeasonalCoolingLoadReduction
             :used_for_garage_ventilation,                     # [Boolean] UsedForGarageVentilation
             :is_shared_system,                                # [Boolean] IsSharedSystem
             :fraction_recirculation,                          # [Double] FractionRecirculation (frac)
             :total_recovery_efficiency,                       # [Double] TotalRecoveryEfficiency (frac)
             :sensible_recovery_efficiency,                    # [Double] SensibleRecoveryEfficiency (frac)
             :total_recovery_efficiency_adjusted,              # [Double] AdjustedTotalRecoveryEfficiency (frac)
             :sensible_recovery_efficiency_adjusted,           # [Double] AdjustedSensibleRecoveryEfficiency (frac)
             :fan_power,                                       # [Double] FanPower (W)
             :distribution_system_idref,                       # [String] AttachedToHVACDistributionSystem/@idref
             :start_hour,                                      # [Integer] extension/StartHour
             :in_unit_flow_rate,                               # [Double] extension/InUnitFlowRate (cfm)
             :preheating_fuel,                                 # [String] extension/PreHeating/Fuel (HPXML::FuelTypeXXX)
             :preheating_efficiency_cop,                       # [Double] extension/PreHeating/AnnualHeatingEfficiency[Units="COP"]/Value (W/W)
             :preheating_fraction_load_served,                 # [Double] extension/PreHeating/FractionVentilationHeatLoadServed (frac)
             :precooling_fuel,                                 # [String] extension/PreCooling/Fuel (HPXML::FuelTypeXXX)
             :precooling_efficiency_cop,                       # [Double] extension/PreCooling/AnnualCoolingEfficiency[Units="COP"]/Value (W/W)
             :precooling_fraction_load_served,                 # [Double] extension/PreCooling/FractionVentilationCoolLoadServed (frac)
             :flow_rate_not_tested,                            # [Boolean] extension/FlowRateNotTested
             :fan_power_defaulted,                             # [Boolean] extension/FanPowerDefaulted
             :cfis_vent_mode_airflow_fraction]                 # [Double] extension/VentilationOnlyModeAirflowFraction (frac)
    attr_accessor(*ATTRS)

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def branch_circuits
      return HPXML::branch_circuits(@id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def service_feeders
      return HPXML::service_feeders(@id, @parent_object.electric_panels)
    end

    # Returns the HVAC distribution system for the ventilation fan.
    #
    # @return [HPXML::HVACDistribution] The attached HVAC distribution system
    def distribution_system
      return if @distribution_system_idref.nil?
      return unless @fan_type == MechVentTypeCFIS

      @parent_object.hvac_distributions.each do |hvac_distribution|
        next unless hvac_distribution.id == @distribution_system_idref

        if hvac_distribution.distribution_system_type == HVACDistributionTypeHydronic
          fail "Attached HVAC distribution system '#{@distribution_system_idref}' cannot be hydronic for ventilation fan '#{@id}'."
        end

        return hvac_distribution
      end
      fail "Attached HVAC distribution system '#{@distribution_system_idref}' not found for ventilation fan '#{@id}'."
    end

    # Returns the (instantaneous) flow rate. Used because there are multiple
    # HPXML inputs that can describe the flow rate.
    #
    # @return [Double] Flow rate (cfm)
    def flow_rate
      [@tested_flow_rate, @delivered_ventilation, @calculated_flow_rate, @rated_flow_rate].each do |fr|
        return fr unless fr.nil?
      end
      return
    end

    # Returns the (instantaneous) flow rate for the dwelling unit. Shared
    # ventilation systems that serve multiple dwelling units have a separate
    # flow rate input that describes how much of the total airflow serves
    # the dwelling unit.
    #
    # @return [Double] Flow rate to the dwelling unit (cfm)
    def unit_flow_rate
      if not @is_shared_system
        return flow_rate
      else
        return @in_unit_flow_rate
      end
    end

    # Returns the outdoor air-only flow rate for the dwelling unit.
    # Only differs from unit_flow_rate for shared systems with recirculation.
    #
    # @return [Double] Outdoor air flow rate to the dwelling unit (cfm)
    def oa_unit_flow_rate
      return if unit_flow_rate.nil?
      if not @is_shared_system
        return unit_flow_rate
      else
        if @fan_type == HPXML::MechVentTypeExhaust && @fraction_recirculation > 0.0
          fail "Exhaust fan '#{@id}' must have the fraction recirculation set to zero."
        else
          return unit_flow_rate * (1 - @fraction_recirculation)
        end
      end
    end

    # Returns the (instantaneous) fan power associated with the dwelling unit.
    # For shared ventilation systems that serve multiple dwelling units, the
    # total fan power is apportioned to the dwelling unit using the
    # flow rate to the dwelling unit divided by the total flow rate.
    #
    # @return [Double] Fan power associated with the dwelling unit (W)
    def unit_fan_power
      return if @fan_power.nil?

      if @is_shared_system
        return if @in_unit_flow_rate.nil?
        return if flow_rate.nil?

        unit_flow_rate_ratio = @in_unit_flow_rate / flow_rate

        return @fan_power * unit_flow_rate_ratio
      else
        return @fan_power
      end
    end

    # Returns the daily-average flow rate for the dwelling unit.
    # Only differs from unit_flow_rate for systems that operate < 24 hrs/day.
    #
    # @return [Double] Daily-average flow rate to the dwelling unit (cfm)
    def average_unit_flow_rate
      return if unit_flow_rate.nil?
      return if @hours_in_operation.nil?

      return unit_flow_rate * (@hours_in_operation / 24.0)
    end

    # Returns the daily-average outdoor air flow rate for the dwelling unit.
    # Only differs from oa_unit_flow_rate for systems that operate < 24 hrs/day.
    #
    # @return [Double] Daily-average outdoor air flow rate to the dwelling unit (cfm)
    def average_oa_unit_flow_rate
      return if oa_unit_flow_rate.nil?
      return if @hours_in_operation.nil?

      return oa_unit_flow_rate * (@hours_in_operation / 24.0)
    end

    # Returns the daily average fan power associated with the dwelling unit.
    # Only differs from unit_fan_power for systems that operate < 24 hrs/day.
    #
    # @return [Double] Daily-average fan power associated with the dwelling unit (W)
    def average_unit_fan_power
      return if unit_fan_power.nil?
      return if @hours_in_operation.nil?

      return unit_fan_power * (@hours_in_operation / 24.0)
    end

    # Returns whether the ventilation fan supplies air.
    #
    # @return [Boolean] True if it supplies air
    def includes_supply_air
      return [MechVentTypeSupply, MechVentTypeCFIS, MechVentTypeBalanced, MechVentTypeERV, MechVentTypeHRV].include?(@fan_type)
    end

    # Returns whether the ventilation fan exhausts air.
    #
    # @return [Boolean] True if it exhausts air
    def includes_exhaust_air
      return [MechVentTypeExhaust, MechVentTypeBalanced, MechVentTypeERV, MechVentTypeHRV].include?(@fan_type)
    end

    # Returns whether the ventilation fan both supplies and exhausts air, which indicates
    # it is a balanced system.
    #
    # @return [Boolean] True if it is a balanced system
    def is_balanced
      return includes_supply_air && includes_exhaust_air
    end

    # Returns the supplemental fan to this ventilation fan if it's a CFIS system.
    #
    # @return [HPXML::VentilationFan] The supplemental fan
    def cfis_supplemental_fan
      return if @cfis_supplemental_fan_idref.nil?
      return unless @fan_type == MechVentTypeCFIS

      @parent_object.ventilation_fans.each do |ventilation_fan|
        next unless ventilation_fan.id == @cfis_supplemental_fan_idref

        if not [MechVentTypeSupply, MechVentTypeExhaust].include? ventilation_fan.fan_type
          fail "CFIS supplemental fan '#{ventilation_fan.id}' must be of type '#{MechVentTypeSupply}' or '#{MechVentTypeExhaust}'."
        end
        if not ventilation_fan.used_for_whole_building_ventilation
          fail "CFIS supplemental fan '#{ventilation_fan.id}' must be set as used for whole building ventilation."
        end
        if ventilation_fan.is_shared_system
          fail "CFIS supplemental fan '#{ventilation_fan.id}' cannot be a shared system."
        end
        if not ventilation_fan.hours_in_operation.nil?
          fail "CFIS supplemental fan '#{ventilation_fan.id}' cannot have HoursInOperation specified."
        end

        return ventilation_fan
      end
      fail "CFIS Supplemental Fan '#{@cfis_supplemental_fan_idref}' not found for ventilation fan '#{@id}'."
    end

    # Returns whether this ventilation fan serves as a supplemental fan to a CFIS system.
    #
    # @return [Boolean] True if a CFIS supplemental fan
    def is_cfis_supplemental_fan
      @parent_object.ventilation_fans.each do |ventilation_fan|
        next unless ventilation_fan.fan_type == MechVentTypeCFIS
        next unless ventilation_fan.cfis_supplemental_fan_idref == @id

        return true
      end
      return false
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      if is_cfis_supplemental_fan
        @parent_object.ventilation_fans.each do |vent_fan|
          vent_fan.cfis_supplemental_fan_idref = nil if vent_fan.cfis_supplemental_fan_idref == @id
        end
      end
      @parent_object.ventilation_fans.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; distribution_system; rescue StandardError => e; errors << e.message; end
      begin; oa_unit_flow_rate; rescue StandardError => e; errors << e.message; end
      begin; cfis_supplemental_fan; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      ventilation_fans = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'MechanicalVentilation', 'VentilationFans'])
      ventilation_fan = XMLHelper.add_element(ventilation_fans, 'VentilationFan')
      sys_id = XMLHelper.add_element(ventilation_fan, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(ventilation_fan, 'Count', @count, :integer, @count_isdefaulted) unless @count.nil?
      XMLHelper.add_element(ventilation_fan, 'FanType', @fan_type, :string) unless @fan_type.nil?
      if (not @cfis_addtl_runtime_operating_mode.nil?) || (not @cfis_supplemental_fan_idref.nil?) || (not @cfis_has_outdoor_air_control.nil?) || (not @cfis_control_type.nil?) || (not @cfis_supplemental_fan_runs_with_air_handler_fan.nil?)
        cfis_controls = XMLHelper.add_element(ventilation_fan, 'CFISControls')
        XMLHelper.add_element(cfis_controls, 'HasOutdoorAirControl', @cfis_has_outdoor_air_control, :boolean, @cfis_has_outdoor_air_control_isdefaulted) unless @cfis_has_outdoor_air_control.nil?
        XMLHelper.add_element(cfis_controls, 'AdditionalRuntimeOperatingMode', @cfis_addtl_runtime_operating_mode, :string, @cfis_addtl_runtime_operating_mode_isdefaulted) unless @cfis_addtl_runtime_operating_mode.nil?
        if not @cfis_supplemental_fan_idref.nil?
          supplemental_fan = XMLHelper.add_element(cfis_controls, 'SupplementalFan')
          XMLHelper.add_attribute(supplemental_fan, 'idref', @cfis_supplemental_fan_idref)
        end
        XMLHelper.add_extension(cfis_controls, 'ControlType', @cfis_control_type, :string, @cfis_control_type_isdefaulted) unless @cfis_control_type.nil?
        XMLHelper.add_extension(cfis_controls, 'SupplementalFanRunsWithAirHandlerFan', @cfis_supplemental_fan_runs_with_air_handler_fan, :boolean, @cfis_supplemental_fan_runs_with_air_handler_fan_isdefaulted) unless @cfis_supplemental_fan_runs_with_air_handler_fan.nil?
      end
      XMLHelper.add_element(ventilation_fan, 'RatedFlowRate', @rated_flow_rate, :float, @rated_flow_rate_isdefaulted) unless @rated_flow_rate.nil?
      XMLHelper.add_element(ventilation_fan, 'CalculatedFlowRate', @calculated_flow_rate, :float, @calculated_flow_rate_isdefaulted) unless @calculated_flow_rate.nil?
      XMLHelper.add_element(ventilation_fan, 'TestedFlowRate', @tested_flow_rate, :float, @tested_flow_rate_isdefaulted) unless @tested_flow_rate.nil?
      XMLHelper.add_element(ventilation_fan, 'HoursInOperation', @hours_in_operation, :float, @hours_in_operation_isdefaulted) unless @hours_in_operation.nil?
      XMLHelper.add_element(ventilation_fan, 'DeliveredVentilation', @delivered_ventilation, :float, @delivered_ventilation_isdefaulted) unless @delivered_ventilation.nil?
      XMLHelper.add_element(ventilation_fan, 'FanLocation', @fan_location, :string) unless @fan_location.nil?
      XMLHelper.add_element(ventilation_fan, 'UsedForLocalVentilation', @used_for_local_ventilation, :boolean) unless @used_for_local_ventilation.nil?
      XMLHelper.add_element(ventilation_fan, 'UsedForWholeBuildingVentilation', @used_for_whole_building_ventilation, :boolean) unless @used_for_whole_building_ventilation.nil?
      XMLHelper.add_element(ventilation_fan, 'UsedForSeasonalCoolingLoadReduction', @used_for_seasonal_cooling_load_reduction, :boolean) unless @used_for_seasonal_cooling_load_reduction.nil?
      XMLHelper.add_element(ventilation_fan, 'UsedForGarageVentilation', @used_for_garage_ventilation, :boolean) unless @used_for_garage_ventilation.nil?
      XMLHelper.add_element(ventilation_fan, 'IsSharedSystem', @is_shared_system, :boolean, @is_shared_system_isdefaulted) unless @is_shared_system.nil?
      XMLHelper.add_element(ventilation_fan, 'FractionRecirculation', @fraction_recirculation, :float) unless @fraction_recirculation.nil?
      XMLHelper.add_element(ventilation_fan, 'TotalRecoveryEfficiency', @total_recovery_efficiency, :float) unless @total_recovery_efficiency.nil?
      XMLHelper.add_element(ventilation_fan, 'SensibleRecoveryEfficiency', @sensible_recovery_efficiency, :float) unless @sensible_recovery_efficiency.nil?
      XMLHelper.add_element(ventilation_fan, 'AdjustedTotalRecoveryEfficiency', @total_recovery_efficiency_adjusted, :float) unless @total_recovery_efficiency_adjusted.nil?
      XMLHelper.add_element(ventilation_fan, 'AdjustedSensibleRecoveryEfficiency', @sensible_recovery_efficiency_adjusted, :float) unless @sensible_recovery_efficiency_adjusted.nil?
      XMLHelper.add_element(ventilation_fan, 'FanPower', @fan_power, :float, @fan_power_isdefaulted) unless @fan_power.nil?
      if not @distribution_system_idref.nil?
        attached_to_hvac_distribution_system = XMLHelper.add_element(ventilation_fan, 'AttachedToHVACDistributionSystem')
        XMLHelper.add_attribute(attached_to_hvac_distribution_system, 'idref', @distribution_system_idref)
      end
      XMLHelper.add_extension(ventilation_fan, 'StartHour', @start_hour, :integer, @start_hour_isdefaulted) unless @start_hour.nil?
      XMLHelper.add_extension(ventilation_fan, 'InUnitFlowRate', @in_unit_flow_rate, :float) unless @in_unit_flow_rate.nil?
      if (not @preheating_fuel.nil?) && (not @preheating_efficiency_cop.nil?)
        precond_htg = XMLHelper.create_elements_as_needed(ventilation_fan, ['extension', 'PreHeating'])
        XMLHelper.add_element(precond_htg, 'Fuel', @preheating_fuel, :string) unless @preheating_fuel.nil?
        eff = XMLHelper.add_element(precond_htg, 'AnnualHeatingEfficiency') unless @preheating_efficiency_cop.nil?
        XMLHelper.add_element(eff, 'Value', @preheating_efficiency_cop, :float) unless eff.nil?
        XMLHelper.add_element(eff, 'Units', UnitsCOP, :string) unless eff.nil?
        XMLHelper.add_element(precond_htg, 'FractionVentilationHeatLoadServed', @preheating_fraction_load_served, :float) unless @preheating_fraction_load_served.nil?
      end
      if (not @precooling_fuel.nil?) && (not @precooling_efficiency_cop.nil?)
        precond_clg = XMLHelper.create_elements_as_needed(ventilation_fan, ['extension', 'PreCooling'])
        XMLHelper.add_element(precond_clg, 'Fuel', @precooling_fuel, :string) unless @precooling_fuel.nil?
        eff = XMLHelper.add_element(precond_clg, 'AnnualCoolingEfficiency') unless @precooling_efficiency_cop.nil?
        XMLHelper.add_element(eff, 'Value', @precooling_efficiency_cop, :float) unless eff.nil?
        XMLHelper.add_element(eff, 'Units', UnitsCOP, :string) unless eff.nil?
        XMLHelper.add_element(precond_clg, 'FractionVentilationCoolLoadServed', @precooling_fraction_load_served, :float) unless @precooling_fraction_load_served.nil?
      end
      XMLHelper.add_extension(ventilation_fan, 'FlowRateNotTested', @flow_rate_not_tested, :boolean) unless @flow_rate_not_tested.nil?
      XMLHelper.add_extension(ventilation_fan, 'FanPowerDefaulted', @fan_power_defaulted, :boolean) unless @fan_power_defaulted.nil?
      XMLHelper.add_extension(ventilation_fan, 'VentilationOnlyModeAirflowFraction', @cfis_vent_mode_airflow_fraction, :float, @cfis_vent_mode_airflow_fraction_isdefaulted) unless @cfis_vent_mode_airflow_fraction.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param ventilation_fan [Oga::XML::Element] The current VentilationFan XML element
    # @return [nil]
    def from_doc(ventilation_fan)
      return if ventilation_fan.nil?

      @id = HPXML::get_id(ventilation_fan)
      @count = XMLHelper.get_value(ventilation_fan, 'Count', :integer)
      @fan_type = XMLHelper.get_value(ventilation_fan, 'FanType', :string)
      @cfis_has_outdoor_air_control = XMLHelper.get_value(ventilation_fan, 'CFISControls/HasOutdoorAirControl', :boolean)
      @cfis_addtl_runtime_operating_mode = XMLHelper.get_value(ventilation_fan, 'CFISControls/AdditionalRuntimeOperatingMode', :string)
      @cfis_supplemental_fan_idref = HPXML::get_idref(XMLHelper.get_element(ventilation_fan, 'CFISControls/SupplementalFan'))
      @cfis_control_type = XMLHelper.get_value(ventilation_fan, 'CFISControls/extension/ControlType', :string)
      @cfis_supplemental_fan_runs_with_air_handler_fan = XMLHelper.get_value(ventilation_fan, 'CFISControls/extension/SupplementalFanRunsWithAirHandlerFan', :boolean)
      @rated_flow_rate = XMLHelper.get_value(ventilation_fan, 'RatedFlowRate', :float)
      @calculated_flow_rate = XMLHelper.get_value(ventilation_fan, 'CalculatedFlowRate', :float)
      @tested_flow_rate = XMLHelper.get_value(ventilation_fan, 'TestedFlowRate', :float)
      @hours_in_operation = XMLHelper.get_value(ventilation_fan, 'HoursInOperation', :float)
      @delivered_ventilation = XMLHelper.get_value(ventilation_fan, 'DeliveredVentilation', :float)
      @fan_location = XMLHelper.get_value(ventilation_fan, 'FanLocation', :string)
      @used_for_local_ventilation = XMLHelper.get_value(ventilation_fan, 'UsedForLocalVentilation', :boolean)
      @used_for_whole_building_ventilation = XMLHelper.get_value(ventilation_fan, 'UsedForWholeBuildingVentilation', :boolean)
      @used_for_seasonal_cooling_load_reduction = XMLHelper.get_value(ventilation_fan, 'UsedForSeasonalCoolingLoadReduction', :boolean)
      @used_for_garage_ventilation = XMLHelper.get_value(ventilation_fan, 'UsedForGarageVentilation', :boolean)
      @is_shared_system = XMLHelper.get_value(ventilation_fan, 'IsSharedSystem', :boolean)
      @fraction_recirculation = XMLHelper.get_value(ventilation_fan, 'FractionRecirculation', :float)
      @total_recovery_efficiency = XMLHelper.get_value(ventilation_fan, 'TotalRecoveryEfficiency', :float)
      @sensible_recovery_efficiency = XMLHelper.get_value(ventilation_fan, 'SensibleRecoveryEfficiency', :float)
      @total_recovery_efficiency_adjusted = XMLHelper.get_value(ventilation_fan, 'AdjustedTotalRecoveryEfficiency', :float)
      @sensible_recovery_efficiency_adjusted = XMLHelper.get_value(ventilation_fan, 'AdjustedSensibleRecoveryEfficiency', :float)
      @fan_power = XMLHelper.get_value(ventilation_fan, 'FanPower', :float)
      @distribution_system_idref = HPXML::get_idref(XMLHelper.get_element(ventilation_fan, 'AttachedToHVACDistributionSystem'))
      @start_hour = XMLHelper.get_value(ventilation_fan, 'extension/StartHour', :integer)
      @in_unit_flow_rate = XMLHelper.get_value(ventilation_fan, 'extension/InUnitFlowRate', :float)
      @preheating_fuel = XMLHelper.get_value(ventilation_fan, 'extension/PreHeating/Fuel', :string)
      @preheating_efficiency_cop = XMLHelper.get_value(ventilation_fan, "extension/PreHeating/AnnualHeatingEfficiency[Units='#{UnitsCOP}']/Value", :float)
      @preheating_fraction_load_served = XMLHelper.get_value(ventilation_fan, 'extension/PreHeating/FractionVentilationHeatLoadServed', :float)
      @precooling_fuel = XMLHelper.get_value(ventilation_fan, 'extension/PreCooling/Fuel', :string)
      @precooling_efficiency_cop = XMLHelper.get_value(ventilation_fan, "extension/PreCooling/AnnualCoolingEfficiency[Units='#{UnitsCOP}']/Value", :float)
      @precooling_fraction_load_served = XMLHelper.get_value(ventilation_fan, 'extension/PreCooling/FractionVentilationCoolLoadServed', :float)
      @flow_rate_not_tested = XMLHelper.get_value(ventilation_fan, 'extension/FlowRateNotTested', :boolean)
      @fan_power_defaulted = XMLHelper.get_value(ventilation_fan, 'extension/FanPowerDefaulted', :boolean)
      @cfis_vent_mode_airflow_fraction = XMLHelper.get_value(ventilation_fan, 'extension/VentilationOnlyModeAirflowFraction', :float)
    end
  end

  # Array of HPXML::WaterHeatingSystem objects.
  class WaterHeatingSystems < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << WaterHeatingSystem.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/WaterHeating/WaterHeatingSystem').each do |water_heating_system|
        self << WaterHeatingSystem.new(@parent_object, water_heating_system)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem.
  class WaterHeatingSystem < BaseElement
    ATTRS = [:id,                                     # [String] SystemIdentifier/@id
             :sameas_id,                              # [String] SystemIdentifier/@sameas
             :fuel_type,                              # [String] FuelType (HPXML::FuelTypeXXX)
             :water_heater_type,                      # [String] WaterHeaterType (HPXML::WaterHeaterTypeXXX)
             :location,                               # [String] Location (HPXML::LocationXXX)
             :year_installed,                         # [Integer] YearInstalled
             :is_shared_system,                       # [Boolean] IsSharedSystem
             :performance_adjustment,                 # [Double] PerformanceAdjustment (frac)
             :third_party_certification,              # [String] ThirdPartyCertification
             :tank_volume,                            # [Double] TankVolume (gal)
             :fraction_dhw_load_served,               # [Double] FractionDHWLoadServed (frac)
             :heating_capacity,                       # [Double] HeatingCapacity (Btu/hr)
             :backup_heating_capacity,                # [Double] BackupHeatingCapacity (Btu/hr)
             :energy_factor,                          # [Double] EnergyFactor (frac)
             :uniform_energy_factor,                  # [Double] UniformEnergyFactor (frac)
             :hpwh_operating_mode,                    # [String] HPWHOperatingMode (HPXML::WaterHeaterHPWHOperatingModeXXX)
             :hpwh_ducting_supply,                    # [String] HPWHDucting/SupplyAirSource (HPXML::LocationXXX)
             :hpwh_ducting_exhaust,                   # [String] HPWHDucting/ExhaustAirTermination (HPXML::LocationXXX)
             :first_hour_rating,                      # [Double] FirstHourRating (gal/hr)
             :usage_bin,                              # [String] UsageBin (HPXML::WaterHeaterUsageBinXXX)
             :recovery_efficiency,                    # [Double] RecoveryEfficiency (frac)
             :jacket_r_value,                         # [Double] WaterHeaterInsulation/Jacket/JacketRValue (F-ft2-hr/Btu)
             :standby_loss_units,                     # [String] StandbyLoss/Units (HPXML::UnitsXXX)
             :standby_loss_value,                     # [Double] StandbyLoss/Value
             :temperature,                            # [Double] HotWaterTemperature (F)
             :uses_desuperheater,                     # [Boolean] UsesDesuperheater
             :related_hvac_idref,                     # [String] RelatedHVACSystem/@idref
             :tank_model_type,                        # [String] extension/TankModelType (HPXML::WaterHeaterTankModelTypeXXX)
             :number_of_bedrooms_served,              # [Integer] extension/NumberofBedroomsServed
             :hpwh_confined_space_without_mitigation, # [Boolean] extension/HPWHInConfinedSpaceWithoutMitigation
             :hpwh_containment_volume]                # [Double] extension/HPWHContainmentVolume
    attr_accessor(*ATTRS)

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def branch_circuits
      return HPXML::branch_circuits(@id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def service_feeders
      return HPXML::service_feeders(@id, @parent_object.electric_panels)
    end

    # Returns the HVAC system related to this water heating system (e.g., for
    # a combination boiler that provides both water heating and space heating).
    #
    # @return [HPXML::XXX] The HVAC system
    def related_hvac_system
      return if @related_hvac_idref.nil?

      @parent_object.hvac_systems.each do |hvac_system|
        next unless hvac_system.id == @related_hvac_idref

        return hvac_system
      end
      fail "RelatedHVACSystem '#{@related_hvac_idref}' not found for water heating system '#{@id}'."
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.water_heating_systems.delete(self)
      @parent_object.solar_thermal_systems.each do |solar_thermal_system|
        next unless solar_thermal_system.water_heating_system_idref == @id

        solar_thermal_system.water_heating_system_idref = nil
      end
      @parent_object.clothes_washers.each do |clothes_washer|
        next unless clothes_washer.water_heating_system_idref == @id

        clothes_washer.water_heating_system_idref = nil
      end
      @parent_object.dishwashers.each do |dishwasher|
        next unless dishwasher.water_heating_system_idref == @id

        dishwasher.water_heating_system_idref = nil
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; related_hvac_system; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      water_heating = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'WaterHeating'])
      water_heating_system = XMLHelper.add_element(water_heating, 'WaterHeatingSystem')
      sys_id = XMLHelper.add_element(water_heating_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(water_heating_system, 'FuelType', @fuel_type, :string) unless @fuel_type.nil?
      XMLHelper.add_element(water_heating_system, 'WaterHeaterType', @water_heater_type, :string) unless @water_heater_type.nil?
      XMLHelper.add_element(water_heating_system, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(water_heating_system, 'YearInstalled', @year_installed, :integer) unless @year_installed.nil?
      XMLHelper.add_element(water_heating_system, 'IsSharedSystem', @is_shared_system, :boolean, @is_shared_system_isdefaulted) unless @is_shared_system.nil?
      XMLHelper.add_element(water_heating_system, 'PerformanceAdjustment', @performance_adjustment, :float, @performance_adjustment_isdefaulted) unless @performance_adjustment.nil?
      XMLHelper.add_element(water_heating_system, 'ThirdPartyCertification', @third_party_certification, :string) unless @third_party_certification.nil?
      XMLHelper.add_element(water_heating_system, 'TankVolume', @tank_volume, :float, @tank_volume_isdefaulted) unless @tank_volume.nil?
      XMLHelper.add_element(water_heating_system, 'FractionDHWLoadServed', @fraction_dhw_load_served, :float) unless @fraction_dhw_load_served.nil?
      XMLHelper.add_element(water_heating_system, 'HeatingCapacity', @heating_capacity, :float, @heating_capacity_isdefaulted) unless @heating_capacity.nil?
      XMLHelper.add_element(water_heating_system, 'BackupHeatingCapacity', @backup_heating_capacity, :float, @backup_heating_capacity_isdefaulted) unless @backup_heating_capacity.nil?
      XMLHelper.add_element(water_heating_system, 'EnergyFactor', @energy_factor, :float, @energy_factor_isdefaulted) unless @energy_factor.nil?
      XMLHelper.add_element(water_heating_system, 'UniformEnergyFactor', @uniform_energy_factor, :float) unless @uniform_energy_factor.nil?
      XMLHelper.add_element(water_heating_system, 'HPWHOperatingMode', @hpwh_operating_mode, :string, @hpwh_operating_mode_isdefaulted) unless @hpwh_operating_mode.nil?
      if (not @hpwh_ducting_exhaust.nil?) || (not @hpwh_ducting_supply.nil?)
        hpwh_ducting = XMLHelper.add_element(water_heating_system, 'HPWHDucting')
        XMLHelper.add_element(hpwh_ducting, 'SupplyAirSource', @hpwh_ducting_supply, :string, @hpwh_ducting_supply_isdefaulted) unless @hpwh_ducting_supply.nil?
        XMLHelper.add_element(hpwh_ducting, 'ExhaustAirTermination', @hpwh_ducting_exhaust, :string, @hpwh_ducting_exhaust_isdefaulted) unless @hpwh_ducting_exhaust.nil?
      end
      XMLHelper.add_element(water_heating_system, 'FirstHourRating', @first_hour_rating, :float) unless @first_hour_rating.nil?
      XMLHelper.add_element(water_heating_system, 'UsageBin', @usage_bin, :string, @usage_bin_isdefaulted) unless @usage_bin.nil?
      XMLHelper.add_element(water_heating_system, 'RecoveryEfficiency', @recovery_efficiency, :float, @recovery_efficiency_isdefaulted) unless @recovery_efficiency.nil?
      if not @jacket_r_value.nil?
        water_heater_insulation = XMLHelper.add_element(water_heating_system, 'WaterHeaterInsulation')
        jacket = XMLHelper.add_element(water_heater_insulation, 'Jacket')
        XMLHelper.add_element(jacket, 'JacketRValue', @jacket_r_value, :float)
      end
      if (not @standby_loss_units.nil?) && (not @standby_loss_value.nil?)
        standby_loss = XMLHelper.add_element(water_heating_system, 'StandbyLoss')
        XMLHelper.add_element(standby_loss, 'Units', @standby_loss_units, :string, @standby_loss_units_isdefaulted)
        XMLHelper.add_element(standby_loss, 'Value', @standby_loss_value, :float, @standby_loss_value_isdefaulted)
      end
      XMLHelper.add_element(water_heating_system, 'HotWaterTemperature', @temperature, :float, @temperature_isdefaulted) unless @temperature.nil?
      XMLHelper.add_element(water_heating_system, 'UsesDesuperheater', @uses_desuperheater, :boolean) unless @uses_desuperheater.nil?
      if not @related_hvac_idref.nil?
        related_hvac_idref_el = XMLHelper.add_element(water_heating_system, 'RelatedHVACSystem')
        XMLHelper.add_attribute(related_hvac_idref_el, 'idref', @related_hvac_idref)
      end
      if (not @tank_model_type.nil?) || (not @number_of_bedrooms_served.nil?) || (not @hpwh_confined_space_without_mitigation.nil?) || (not @hpwh_containment_volume.nil?)
        extension = XMLHelper.create_elements_as_needed(water_heating_system, ['extension'])
        XMLHelper.add_element(extension, 'TankModelType', @tank_model_type, :string, @tank_model_type_isdefaulted) unless @tank_model_type.nil?
        XMLHelper.add_element(extension, 'NumberofBedroomsServed', @number_of_bedrooms_served, :integer, @number_of_bedrooms_served_isdefaulted) unless @number_of_bedrooms_served.nil?
        XMLHelper.add_element(extension, 'HPWHInConfinedSpaceWithoutMitigation', @hpwh_confined_space_without_mitigation, :boolean, @hpwh_confined_space_without_mitigation_isdefaulted) unless @hpwh_confined_space_without_mitigation.nil?
        XMLHelper.add_element(extension, 'HPWHContainmentVolume', @hpwh_containment_volume, :float, @hpwh_containment_volume_isdefaulted) unless @hpwh_containment_volume.nil?
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param water_heating_system [Oga::XML::Element] The current WaterHeatingSystem XML element
    # @return [nil]
    def from_doc(water_heating_system)
      return if water_heating_system.nil?

      @id = HPXML::get_id(water_heating_system)
      @fuel_type = XMLHelper.get_value(water_heating_system, 'FuelType', :string)
      @water_heater_type = XMLHelper.get_value(water_heating_system, 'WaterHeaterType', :string)
      @location = XMLHelper.get_value(water_heating_system, 'Location', :string)
      @year_installed = XMLHelper.get_value(water_heating_system, 'YearInstalled', :integer)
      @is_shared_system = XMLHelper.get_value(water_heating_system, 'IsSharedSystem', :boolean)
      @performance_adjustment = XMLHelper.get_value(water_heating_system, 'PerformanceAdjustment', :float)
      @third_party_certification = XMLHelper.get_value(water_heating_system, 'ThirdPartyCertification', :string)
      @tank_volume = XMLHelper.get_value(water_heating_system, 'TankVolume', :float)
      @fraction_dhw_load_served = XMLHelper.get_value(water_heating_system, 'FractionDHWLoadServed', :float)
      @heating_capacity = XMLHelper.get_value(water_heating_system, 'HeatingCapacity', :float)
      @backup_heating_capacity = XMLHelper.get_value(water_heating_system, 'BackupHeatingCapacity', :float)
      @energy_factor = XMLHelper.get_value(water_heating_system, 'EnergyFactor', :float)
      @uniform_energy_factor = XMLHelper.get_value(water_heating_system, 'UniformEnergyFactor', :float)
      @hpwh_operating_mode = XMLHelper.get_value(water_heating_system, 'HPWHOperatingMode', :string)
      @hpwh_ducting_supply = XMLHelper.get_value(water_heating_system, 'HPWHDucting/SupplyAirSource', :string)
      @hpwh_ducting_exhaust = XMLHelper.get_value(water_heating_system, 'HPWHDucting/ExhaustAirTermination', :string)
      @first_hour_rating = XMLHelper.get_value(water_heating_system, 'FirstHourRating', :float)
      @usage_bin = XMLHelper.get_value(water_heating_system, 'UsageBin', :string)
      @recovery_efficiency = XMLHelper.get_value(water_heating_system, 'RecoveryEfficiency', :float)
      @jacket_r_value = XMLHelper.get_value(water_heating_system, 'WaterHeaterInsulation/Jacket/JacketRValue', :float)
      @standby_loss_units = XMLHelper.get_value(water_heating_system, 'StandbyLoss/Units', :string)
      @standby_loss_value = XMLHelper.get_value(water_heating_system, 'StandbyLoss/Value', :float)
      @temperature = XMLHelper.get_value(water_heating_system, 'HotWaterTemperature', :float)
      @uses_desuperheater = XMLHelper.get_value(water_heating_system, 'UsesDesuperheater', :boolean)
      @related_hvac_idref = HPXML::get_idref(XMLHelper.get_element(water_heating_system, 'RelatedHVACSystem'))
      @tank_model_type = XMLHelper.get_value(water_heating_system, 'extension/TankModelType', :string)
      @number_of_bedrooms_served = XMLHelper.get_value(water_heating_system, 'extension/NumberofBedroomsServed', :integer)
      @hpwh_confined_space_without_mitigation = XMLHelper.get_value(water_heating_system, 'extension/HPWHInConfinedSpaceWithoutMitigation', :boolean)
      @hpwh_containment_volume = XMLHelper.get_value(water_heating_system, 'extension/HPWHContainmentVolume', :float)
    end
  end

  # Array of HPXML::HotWaterDistribution objects.
  class HotWaterDistributions < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << HotWaterDistribution.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/WaterHeating/HotWaterDistribution').each do |hot_water_distribution|
        self << HotWaterDistribution.new(@parent_object, hot_water_distribution)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution.
  class HotWaterDistribution < BaseElement
    ATTRS = [:id,                                             # [String] SystemIdentifier/@id
             :sameas_id,                                      # [String] SystemIdentifier/@sameas
             :system_type,                                    # [String] SystemType/* (HPXML::DHWDistTypeXXX)
             :standard_piping_length,                         # [Double] SystemType/Standard/PipingLength (ft)
             :recirculation_control_type,                     # [String] SystemType/Recirculation/ControlType (HPXML::DHWRecircControlTypeXXX)
             :recirculation_piping_loop_length,               # [Double] SystemType/Recirculation/RecirculationPipingLoopLength (ft)
             :recirculation_branch_piping_length,             # [Double] SystemType/Recirculation/BranchPipingLength (ft)
             :recirculation_pump_power,                       # [Double] SystemType/Recirculation/PumpPower (W)
             :pipe_r_value,                                   # [Double] PipeInsulation/PipeRValue (F-ft2-hr/Btu)
             :dwhr_facilities_connected,                      # [String] DrainWaterHeatRecovery/FacilitiesConnected (HPXML::DWHRFacilitiesConnectedXXX)
             :dwhr_equal_flow,                                # [Boolean] DrainWaterHeatRecovery/EqualFlow
             :dwhr_efficiency,                                # [Double] DrainWaterHeatRecovery/Efficiency (frac)
             :has_shared_recirculation,                       # [Boolean] extension/SharedRecirculation
             :shared_recirculation_number_of_bedrooms_served, # [Integer] extension/SharedRecirculation/NumberofBedroomsServed
             :shared_recirculation_pump_power,                # [Double] extension/SharedRecirculation/PumpPower (W)
             :shared_recirculation_motor_efficiency,          # [Double] extension/SharedRecirculation/MotorEfficiency (frac)
             :shared_recirculation_control_type,              # [String] extension/SharedRecirculation/ControlType (HPXML::DHWRecircControlTypeXXX)
             :recirculation_pump_weekday_fractions,           # [String] extension/RecirculationPumpWeekdayScheduleFractions
             :recirculation_pump_weekend_fractions,           # [String] extension/RecirculationPumpWeekendScheduleFractions
             :recirculation_pump_monthly_multipliers]         # [String] extension/RecirculationPumpMonthlyScheduleMultipliers
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.hot_water_distributions.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      water_heating = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'WaterHeating'])
      hot_water_distribution = XMLHelper.add_element(water_heating, 'HotWaterDistribution')
      sys_id = XMLHelper.add_element(hot_water_distribution, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      if not @system_type.nil?
        system_type_el = XMLHelper.add_element(hot_water_distribution, 'SystemType')
        if @system_type == DHWDistTypeStandard
          standard = XMLHelper.add_element(system_type_el, @system_type)
          XMLHelper.add_element(standard, 'PipingLength', @standard_piping_length, :float, @standard_piping_length_isdefaulted) unless @standard_piping_length.nil?
        elsif system_type == DHWDistTypeRecirc
          recirculation = XMLHelper.add_element(system_type_el, @system_type)
          XMLHelper.add_element(recirculation, 'ControlType', @recirculation_control_type, :string) unless @recirculation_control_type.nil?
          XMLHelper.add_element(recirculation, 'RecirculationPipingLoopLength', @recirculation_piping_loop_length, :float, @recirculation_piping_loop_length_isdefaulted) unless @recirculation_piping_loop_length.nil?
          XMLHelper.add_element(recirculation, 'BranchPipingLength', @recirculation_branch_piping_length, :float, @recirculation_branch_piping_length_isdefaulted) unless @recirculation_branch_piping_length.nil?
          XMLHelper.add_element(recirculation, 'PumpPower', @recirculation_pump_power, :float, @recirculation_pump_power_isdefaulted) unless @recirculation_pump_power.nil?
        else
          fail "Unhandled hot water distribution type '#{@system_type}'."
        end
      end
      if not @pipe_r_value.nil?
        pipe_insulation = XMLHelper.add_element(hot_water_distribution, 'PipeInsulation')
        XMLHelper.add_element(pipe_insulation, 'PipeRValue', @pipe_r_value, :float, @pipe_r_value_isdefaulted)
      end
      if (not @dwhr_facilities_connected.nil?) || (not @dwhr_equal_flow.nil?) || (not @dwhr_efficiency.nil?)
        drain_water_heat_recovery = XMLHelper.add_element(hot_water_distribution, 'DrainWaterHeatRecovery')
        XMLHelper.add_element(drain_water_heat_recovery, 'FacilitiesConnected', @dwhr_facilities_connected, :string) unless @dwhr_facilities_connected.nil?
        XMLHelper.add_element(drain_water_heat_recovery, 'EqualFlow', @dwhr_equal_flow, :boolean) unless @dwhr_equal_flow.nil?
        XMLHelper.add_element(drain_water_heat_recovery, 'Efficiency', @dwhr_efficiency, :float) unless @dwhr_efficiency.nil?
      end
      if @has_shared_recirculation
        extension = XMLHelper.create_elements_as_needed(hot_water_distribution, ['extension'])
        shared_recirculation = XMLHelper.add_element(extension, 'SharedRecirculation')
        XMLHelper.add_element(shared_recirculation, 'NumberofBedroomsServed', @shared_recirculation_number_of_bedrooms_served, :integer) unless @shared_recirculation_number_of_bedrooms_served.nil?
        XMLHelper.add_element(shared_recirculation, 'PumpPower', @shared_recirculation_pump_power, :float, @shared_recirculation_pump_power_isdefaulted) unless @shared_recirculation_pump_power.nil?
        XMLHelper.add_element(shared_recirculation, 'MotorEfficiency', @shared_recirculation_motor_efficiency, :float) unless @shared_recirculation_motor_efficiency.nil?
        XMLHelper.add_element(shared_recirculation, 'ControlType', @shared_recirculation_control_type, :string) unless @shared_recirculation_control_type.nil?
      end
      XMLHelper.add_extension(hot_water_distribution, 'RecirculationPumpWeekdayScheduleFractions', @recirculation_pump_weekday_fractions, :string, @recirculation_pump_weekday_fractions_isdefaulted) unless @recirculation_pump_weekday_fractions.nil?
      XMLHelper.add_extension(hot_water_distribution, 'RecirculationPumpWeekendScheduleFractions', @recirculation_pump_weekend_fractions, :string, @recirculation_pump_weekend_fractions_isdefaulted) unless @recirculation_pump_weekend_fractions.nil?
      XMLHelper.add_extension(hot_water_distribution, 'RecirculationPumpMonthlyScheduleMultipliers', @recirculation_pump_monthly_multipliers, :string, @recirculation_pump_monthly_multipliers_isdefaulted) unless @recirculation_pump_monthly_multipliers.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param hot_water_distribution [Oga::XML::Element] The current HotWaterDistribution XML element
    # @return [nil]
    def from_doc(hot_water_distribution)
      return if hot_water_distribution.nil?

      @id = HPXML::get_id(hot_water_distribution)
      @system_type = XMLHelper.get_child_name(hot_water_distribution, 'SystemType')
      if @system_type == 'Standard'
        @standard_piping_length = XMLHelper.get_value(hot_water_distribution, 'SystemType/Standard/PipingLength', :float)
      elsif @system_type == 'Recirculation'
        @recirculation_control_type = XMLHelper.get_value(hot_water_distribution, 'SystemType/Recirculation/ControlType', :string)
        @recirculation_piping_loop_length = XMLHelper.get_value(hot_water_distribution, 'SystemType/Recirculation/RecirculationPipingLoopLength', :float)
        @recirculation_branch_piping_length = XMLHelper.get_value(hot_water_distribution, 'SystemType/Recirculation/BranchPipingLength', :float)
        @recirculation_pump_power = XMLHelper.get_value(hot_water_distribution, 'SystemType/Recirculation/PumpPower', :float)
      end
      @pipe_r_value = XMLHelper.get_value(hot_water_distribution, 'PipeInsulation/PipeRValue', :float)
      @dwhr_facilities_connected = XMLHelper.get_value(hot_water_distribution, 'DrainWaterHeatRecovery/FacilitiesConnected', :string)
      @dwhr_equal_flow = XMLHelper.get_value(hot_water_distribution, 'DrainWaterHeatRecovery/EqualFlow', :boolean)
      @dwhr_efficiency = XMLHelper.get_value(hot_water_distribution, 'DrainWaterHeatRecovery/Efficiency', :float)
      @has_shared_recirculation = XMLHelper.has_element(hot_water_distribution, 'extension/SharedRecirculation')
      if @has_shared_recirculation
        @shared_recirculation_number_of_bedrooms_served = XMLHelper.get_value(hot_water_distribution, 'extension/SharedRecirculation/NumberofBedroomsServed', :integer)
        @shared_recirculation_pump_power = XMLHelper.get_value(hot_water_distribution, 'extension/SharedRecirculation/PumpPower', :float)
        @shared_recirculation_motor_efficiency = XMLHelper.get_value(hot_water_distribution, 'extension/SharedRecirculation/MotorEfficiency', :float)
        @shared_recirculation_control_type = XMLHelper.get_value(hot_water_distribution, 'extension/SharedRecirculation/ControlType', :string)
      end
      @recirculation_pump_weekday_fractions = XMLHelper.get_value(hot_water_distribution, 'extension/RecirculationPumpWeekdayScheduleFractions', :string)
      @recirculation_pump_weekend_fractions = XMLHelper.get_value(hot_water_distribution, 'extension/RecirculationPumpWeekendScheduleFractions', :string)
      @recirculation_pump_monthly_multipliers = XMLHelper.get_value(hot_water_distribution, 'extension/RecirculationPumpMonthlyScheduleMultipliers', :string)
    end
  end

  # Array of HPXML::WaterFixture objects.
  class WaterFixtures < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << WaterFixture.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/WaterHeating/WaterFixture').each do |water_fixture|
        self << WaterFixture.new(@parent_object, water_fixture)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture.
  class WaterFixture < BaseElement
    ATTRS = [:id,                 # [String] SystemIdentifier/@id
             :sameas_id,          # [String] SystemIdentifier/@sameas
             :water_fixture_type, # [String] WaterFixtureType (HPXML::WaterFixtureTypeXXX)
             :count,              # [Integer] Count
             :flow_rate,          # [Double] FlowRate (gpm)
             :low_flow]           # [Boolean] LowFlow
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.water_fixtures.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      water_heating = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'WaterHeating'])
      water_fixture = XMLHelper.add_element(water_heating, 'WaterFixture')
      sys_id = XMLHelper.add_element(water_fixture, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(water_fixture, 'WaterFixtureType', @water_fixture_type, :string) unless @water_fixture_type.nil?
      XMLHelper.add_element(water_fixture, 'Count', @count, :integer, @count_isdefaulted) unless @count.nil?
      XMLHelper.add_element(water_fixture, 'FlowRate', @flow_rate, :float, @flow_rate_isdefaulted) unless @flow_rate.nil?
      XMLHelper.add_element(water_fixture, 'LowFlow', @low_flow, :boolean, @low_flow_isdefaulted) unless @low_flow.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param water_fixture [Oga::XML::Element] The current WaterFixture XML element
    # @return [nil]
    def from_doc(water_fixture)
      return if water_fixture.nil?

      @id = HPXML::get_id(water_fixture)
      @water_fixture_type = XMLHelper.get_value(water_fixture, 'WaterFixtureType', :string)
      @count = XMLHelper.get_value(water_fixture, 'Count', :integer)
      @flow_rate = XMLHelper.get_value(water_fixture, 'FlowRate', :float)
      @low_flow = XMLHelper.get_value(water_fixture, 'LowFlow', :boolean)
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/WaterHeating/extension.
  class WaterHeating < BaseElement
    ATTRS = [:water_fixtures_usage_multiplier,    # [Double] extension/WaterFixturesUsageMultiplier
             :water_fixtures_weekday_fractions,   # [String] extension/WaterFixturesWeekdayScheduleFractions
             :water_fixtures_weekend_fractions,   # [String] extension/WaterFixturesWeekendScheduleFractions
             :water_fixtures_monthly_multipliers] # [String] extension/WaterFixturesMonthlyScheduleMultipliers
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      water_heating = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'WaterHeating'])
      XMLHelper.add_extension(water_heating, 'WaterFixturesUsageMultiplier', @water_fixtures_usage_multiplier, :float, @water_fixtures_usage_multiplier_isdefaulted) unless @water_fixtures_usage_multiplier.nil?
      XMLHelper.add_extension(water_heating, 'WaterFixturesWeekdayScheduleFractions', @water_fixtures_weekday_fractions, :string, @water_fixtures_weekday_fractions_isdefaulted) unless @water_fixtures_weekday_fractions.nil?
      XMLHelper.add_extension(water_heating, 'WaterFixturesWeekendScheduleFractions', @water_fixtures_weekend_fractions, :string, @water_fixtures_weekend_fractions_isdefaulted) unless @water_fixtures_weekend_fractions.nil?
      XMLHelper.add_extension(water_heating, 'WaterFixturesMonthlyScheduleMultipliers', @water_fixtures_monthly_multipliers, :string, @water_fixtures_monthly_multipliers_isdefaulted) unless @water_fixtures_monthly_multipliers.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      water_heating = XMLHelper.get_element(building, 'BuildingDetails/Systems/WaterHeating')
      return if water_heating.nil?

      @water_fixtures_usage_multiplier = XMLHelper.get_value(water_heating, 'extension/WaterFixturesUsageMultiplier', :float)
      @water_fixtures_weekday_fractions = XMLHelper.get_value(water_heating, 'extension/WaterFixturesWeekdayScheduleFractions', :string)
      @water_fixtures_weekend_fractions = XMLHelper.get_value(water_heating, 'extension/WaterFixturesWeekendScheduleFractions', :string)
      @water_fixtures_monthly_multipliers = XMLHelper.get_value(water_heating, 'extension/WaterFixturesMonthlyScheduleMultipliers', :string)
    end
  end

  # Array of HPXML::SolarThermalSystem objects.
  class SolarThermalSystems < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << SolarThermalSystem.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/SolarThermal/SolarThermalSystem').each do |solar_thermal_system|
        self << SolarThermalSystem.new(@parent_object, solar_thermal_system)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem.
  class SolarThermalSystem < BaseElement
    ATTRS = [:id,                                 # [String] SystemIdentifier/@id
             :sameas_id,                          # [String] SystemIdentifier/@sameas
             :system_type,                        # [String] SystemType (HPXML::SolarThermalSystemTypeXXX)
             :collector_area,                     # [Double] CollectorArea (ft2)
             :collector_loop_type,                # [String] CollectorLoopType (HPXML::SolarThermalLoopTypeXXX)
             :collector_type,                     # [String] CollectorType (HPXML::SolarThermalCollectorTypeXXX)
             :collector_orientation,              # [String] CollectorOrientation (HPXML::OrientationXXX)
             :collector_azimuth,                  # [Integer] CollectorAzimuth (deg)
             :collector_tilt,                     # [Double] CollectorTilt (deg)
             :collector_rated_optical_efficiency, # [Double] CollectorRatedOpticalEfficiency (frac)
             :collector_rated_thermal_losses,     # [Double] CollectorRatedThermalLosses (Btu/hr-ft2-R)
             :storage_volume,                     # [Double] StorageVolume (gal)
             :water_heating_system_idref,         # [String] ConnectedTo/@idref
             :solar_fraction]                     # [Double] SolarFraction (frac)
    attr_accessor(*ATTRS)

    # Returns the water heater connected to the solar thermal system.
    #
    # @return [HPXML::WaterHeatingSystem] The attached water heating system
    def water_heating_system
      return if @water_heating_system_idref.nil?

      @parent_object.water_heating_systems.each do |water_heater|
        next unless water_heater.id == @water_heating_system_idref

        return water_heater
      end
      fail "Attached water heating system '#{@water_heating_system_idref}' not found for solar thermal system '#{@id}'."
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.solar_thermal_systems.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; water_heating_system; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      solar_thermal = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'SolarThermal'])
      solar_thermal_system = XMLHelper.add_element(solar_thermal, 'SolarThermalSystem')
      sys_id = XMLHelper.add_element(solar_thermal_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(solar_thermal_system, 'SystemType', @system_type, :string) unless @system_type.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorArea', @collector_area, :float) unless @collector_area.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorLoopType', @collector_loop_type, :string) unless @collector_loop_type.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorType', @collector_type, :string) unless @collector_type.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorOrientation', @collector_orientation, :string, @collector_orientation_isdefaulted) unless @collector_orientation.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorAzimuth', @collector_azimuth, :integer, @collector_azimuth_isdefaulted) unless @collector_azimuth.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorTilt', @collector_tilt, :float) unless @collector_tilt.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorRatedOpticalEfficiency', @collector_rated_optical_efficiency, :float) unless @collector_rated_optical_efficiency.nil?
      XMLHelper.add_element(solar_thermal_system, 'CollectorRatedThermalLosses', @collector_rated_thermal_losses, :float) unless @collector_rated_thermal_losses.nil?
      XMLHelper.add_element(solar_thermal_system, 'StorageVolume', @storage_volume, :float, @storage_volume_isdefaulted) unless @storage_volume.nil?
      if not @water_heating_system_idref.nil?
        connected_to = XMLHelper.add_element(solar_thermal_system, 'ConnectedTo')
        XMLHelper.add_attribute(connected_to, 'idref', @water_heating_system_idref)
      end
      XMLHelper.add_element(solar_thermal_system, 'SolarFraction', @solar_fraction, :float) unless @solar_fraction.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param solar_thermal_system [Oga::XML::Element] The current SolarThermalSystem XML element
    # @return [nil]
    def from_doc(solar_thermal_system)
      return if solar_thermal_system.nil?

      @id = HPXML::get_id(solar_thermal_system)
      @system_type = XMLHelper.get_value(solar_thermal_system, 'SystemType', :string)
      @collector_area = XMLHelper.get_value(solar_thermal_system, 'CollectorArea', :float)
      @collector_loop_type = XMLHelper.get_value(solar_thermal_system, 'CollectorLoopType', :string)
      @collector_type = XMLHelper.get_value(solar_thermal_system, 'CollectorType', :string)
      @collector_orientation = XMLHelper.get_value(solar_thermal_system, 'CollectorOrientation', :string)
      @collector_azimuth = XMLHelper.get_value(solar_thermal_system, 'CollectorAzimuth', :integer)
      @collector_tilt = XMLHelper.get_value(solar_thermal_system, 'CollectorTilt', :float)
      @collector_rated_optical_efficiency = XMLHelper.get_value(solar_thermal_system, 'CollectorRatedOpticalEfficiency', :float)
      @collector_rated_thermal_losses = XMLHelper.get_value(solar_thermal_system, 'CollectorRatedThermalLosses', :float)
      @storage_volume = XMLHelper.get_value(solar_thermal_system, 'StorageVolume', :float)
      @water_heating_system_idref = HPXML::get_idref(XMLHelper.get_element(solar_thermal_system, 'ConnectedTo'))
      @solar_fraction = XMLHelper.get_value(solar_thermal_system, 'SolarFraction', :float)
    end
  end

  # Array of HPXML::PVSystem objects.
  class PVSystems < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << PVSystem.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/Photovoltaics/PVSystem').each do |pv_system|
        self << PVSystem.new(@parent_object, pv_system)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem.
  class PVSystem < BaseElement
    ATTRS = [:id,                        # [String] SystemIdentifier/@id
             :sameas_id,                 # [String] SystemIdentifier/@sameas
             :is_shared_system,          # [Boolean] IsSharedSystem
             :location,                  # [String] Location (HPXML::LocationXXX)
             :module_type,               # [String] ModuleType (HPXML::PVModuleTypeXXX)
             :tracking,                  # [String] Tracking (HPXML::PVTrackingTypeXXX)
             :array_orientation,         # [String] ArrayOrientation (HPXML::OrientationXXX)
             :array_azimuth,             # [Integer] ArrayAzimuth (deg)
             :array_tilt,                # [Double] ArrayTilt (deg)
             :max_power_output,          # [Double] MaxPowerOutput (W)
             :number_of_panels,          # [Integer] NumberOfPanels
             :system_losses_fraction,    # [Double] SystemLossesFraction (frac)
             :year_modules_manufactured, # [Integer] YearModulesManufactured
             :inverter_idref,            # [String] AttachedToInverter/@idref
             :number_of_bedrooms_served] # [Integer] extension/NumberofBedroomsServed
    attr_accessor(*ATTRS)

    # Returns the inverter connected to the PV system.
    #
    # @return [HPXML::Inverter] The attached inverter object
    def inverter
      return if @inverter_idref.nil?

      @parent_object.inverters.each do |inv|
        next unless inv.id == @inverter_idref

        return inv
      end
      fail "Attached inverter '#{@inverter_idref}' not found for pv system '#{@id}'."
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.pv_systems.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; inverter; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      photovoltaics = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'Photovoltaics'])
      pv_system = XMLHelper.add_element(photovoltaics, 'PVSystem')
      sys_id = XMLHelper.add_element(pv_system, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(pv_system, 'IsSharedSystem', @is_shared_system, :boolean, @is_shared_system_isdefaulted) unless @is_shared_system.nil?
      XMLHelper.add_element(pv_system, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(pv_system, 'ModuleType', @module_type, :string, @module_type_isdefaulted) unless @module_type.nil?
      XMLHelper.add_element(pv_system, 'Tracking', @tracking, :string, @tracking_isdefaulted) unless @tracking.nil?
      XMLHelper.add_element(pv_system, 'ArrayOrientation', @array_orientation, :string, @array_orientation_isdefaulted) unless @array_orientation.nil?
      XMLHelper.add_element(pv_system, 'ArrayAzimuth', @array_azimuth, :integer, @array_azimuth_isdefaulted) unless @array_azimuth.nil?
      XMLHelper.add_element(pv_system, 'ArrayTilt', @array_tilt, :float) unless @array_tilt.nil?
      XMLHelper.add_element(pv_system, 'MaxPowerOutput', @max_power_output, :float) unless @max_power_output.nil?
      XMLHelper.add_element(pv_system, 'NumberOfPanels', @number_of_panels, :integer) unless @number_of_panels.nil?
      XMLHelper.add_element(pv_system, 'SystemLossesFraction', @system_losses_fraction, :float, @system_losses_fraction_isdefaulted) unless @system_losses_fraction.nil?
      XMLHelper.add_element(pv_system, 'YearModulesManufactured', @year_modules_manufactured, :integer) unless @year_modules_manufactured.nil?
      if not @inverter_idref.nil?
        attached_to_inverter = XMLHelper.add_element(pv_system, 'AttachedToInverter')
        XMLHelper.add_attribute(attached_to_inverter, 'idref', @inverter_idref)
      end
      XMLHelper.add_extension(pv_system, 'NumberofBedroomsServed', @number_of_bedrooms_served, :integer) unless @number_of_bedrooms_served.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param pv_system [Oga::XML::Element] The current PVSystem XML element
    # @return [nil]
    def from_doc(pv_system)
      return if pv_system.nil?

      @id = HPXML::get_id(pv_system)
      @is_shared_system = XMLHelper.get_value(pv_system, 'IsSharedSystem', :boolean)
      @location = XMLHelper.get_value(pv_system, 'Location', :string)
      @module_type = XMLHelper.get_value(pv_system, 'ModuleType', :string)
      @tracking = XMLHelper.get_value(pv_system, 'Tracking', :string)
      @array_orientation = XMLHelper.get_value(pv_system, 'ArrayOrientation', :string)
      @array_azimuth = XMLHelper.get_value(pv_system, 'ArrayAzimuth', :integer)
      @array_tilt = XMLHelper.get_value(pv_system, 'ArrayTilt', :float)
      @max_power_output = XMLHelper.get_value(pv_system, 'MaxPowerOutput', :float)
      @number_of_panels = XMLHelper.get_value(pv_system, 'NumberOfPanels', :integer)
      @system_losses_fraction = XMLHelper.get_value(pv_system, 'SystemLossesFraction', :float)
      @year_modules_manufactured = XMLHelper.get_value(pv_system, 'YearModulesManufactured', :integer)
      @inverter_idref = HPXML::get_idref(XMLHelper.get_element(pv_system, 'AttachedToInverter'))
      @number_of_bedrooms_served = XMLHelper.get_value(pv_system, 'extension/NumberofBedroomsServed', :integer)
    end
  end

  # Array of HPXML::Inverter objects.
  class Inverters < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Inverter.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/Photovoltaics/Inverter').each do |inverter|
        self << Inverter.new(@parent_object, inverter)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/Photovoltaics/Inverter.
  class Inverter < BaseElement
    ATTRS = [:id,                  # [String] SystemIdentifier/@id
             :sameas_id,           # [String] SystemIdentifier/@sameas
             :inverter_efficiency] # [Double] InverterEfficiency (frac)
    attr_accessor(*ATTRS)

    # Returns all PV systems connected to the inverter.
    #
    # @return [HPXML::PVSystem] The list of PV systems
    def pv_systems
      return if @id.nil?

      list = []
      @parent_object.pv_systems.each do |pv|
        next unless @id == pv.inverter_idref

        list << pv
      end

      if list.size == 0
        fail "Inverter '#{@id}' found but no PV systems attached to it."
      end

      return list
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      pv_systems.reverse.each do |pv_system|
        pv_system.inverter_idref = nil
      end
      @parent_object.inverters.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; pv_systems; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      photovoltaics = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'Photovoltaics'])
      inverter = XMLHelper.add_element(photovoltaics, 'Inverter')
      sys_id = XMLHelper.add_element(inverter, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(inverter, 'InverterEfficiency', @inverter_efficiency, :float, @inverter_efficiency_isdefaulted) unless @inverter_efficiency.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param inverter [Oga::XML::Element] The current Inverter XML element
    # @return [nil]
    def from_doc(inverter)
      return if inverter.nil?

      @id = HPXML::get_id(inverter)
      @inverter_efficiency = XMLHelper.get_value(inverter, 'InverterEfficiency', :float)
    end
  end

  # Array of HPXML::ElectricVehicleCharger objects
  class ElectricVehicleChargers < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << ElectricVehicleCharger.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/ElectricVehicleChargers/ElectricVehicleCharger').each do |charger|
        self << ElectricVehicleCharger.new(@parent_object, charger)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/ElectricVehicleChargers/ElectricVehicleCharger.
  class ElectricVehicleCharger < BaseElement
    ATTRS = [:id,             # [String] SystemIdentifier/@id
             :sameas_id,      # [String] SystemIdentifier/@sameas
             :charging_level, # [Integer] ChargingLevel (1-3)
             :charging_power] # [Double] ChargingPower (W)
    attr_accessor(*ATTRS)

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def branch_circuits
      return HPXML::branch_circuits(@id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def service_feeders
      return HPXML::service_feeders(@id, @parent_object.electric_panels)
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.ev_chargers.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      chargers = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'ElectricVehicleChargers'])
      charger = XMLHelper.add_element(chargers, 'ElectricVehicleCharger')
      sys_id = XMLHelper.add_element(charger, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(charger, 'ChargingLevel', @charging_level, :integer, @charging_level_isdefaulted) unless @charging_level.nil?
      XMLHelper.add_element(charger, 'ChargingPower', @charging_power, :float, @charging_power_isdefaulted) unless @charging_power.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param battery [Oga::XML::Element] The current Battery XML element
    # @return [nil]
    def from_doc(charger)
      return if charger.nil?

      @id = HPXML::get_id(charger)
      @charging_level = XMLHelper.get_value(charger, 'ChargingLevel', :integer)
      @charging_power = XMLHelper.get_value(charger, 'ChargingPower', :float)
    end
  end

  # Array of HPXML::Vehicle objects.
  class Vehicles < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Vehicle.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/Vehicles/Vehicle').each do |vehicle|
        self << Vehicle.new(@parent_object, vehicle)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/Vehicles/Vehicle.
  class Vehicle < BaseElement
    ATTRS = [:id,                     # [String] SystemIdentifier/@id
             :sameas_id,              # [String] SystemIdentifier/@sameas
             :vehicle_type,           # [String] VehicleType (HPXML::VehicleTypeXXX)
             :miles_per_year,         # [Double] MilesDrivenPerYear (miles)
             :hours_per_week,         # [Double] HoursDrivenPerWeek (hours)
             :fuel_economy_combined,  # [Double] FuelEconomyCombined/Value
             :fuel_economy_units,     # [String] FuelEconomyCombined/Units
             :fraction_charged_home,  # [Double] VehicleType/BatteryElectricVehicle/FractionChargedLocation[Location="Home"]/Percentage (frac)
             :ev_charger_idref,       # [String] VehicleType/BatteryElectricVehicle/ConnectedCharger/@idref
             :battery_type,           # [String] VehicleType/BatteryElectricVehicle/Battery/BatteryType (HPXML::BatteryTypeXXX)
             :nominal_capacity_kwh,   # [Double] VehicleType/BatteryElectricVehicle/Battery/NominalCapacity[Units="kWh"]/Value (kWh)
             :nominal_capacity_ah,    # [Double] VehicleType/BatteryElectricVehicle/Battery/NominalCapacity[Units="Ah"]/Value (Ah)
             :usable_capacity_kwh,    # [Double] VehicleType/BatteryElectricVehicle/Battery/UsableCapacity[Units="kWh"]/Value (kWh)
             :usable_capacity_ah,     # [Double] VehicleType/BatteryElectricVehicle/Battery/UsableCapacity[Units="Ah"]/Value (Ah)
             :nominal_voltage,        # [Double] VehicleType/BatteryElectricVehicle/Battery/NominalVoltage (V)
             :ev_usage_multiplier,    # [Double] VehicleType/BatteryElectricVehicle/extension/UsageMultiplier
             :ev_weekday_fractions,   # [String] VehicleType/BatteryElectricVehicle/extension/WeekdayScheduleFractions
             :ev_weekend_fractions,   # [String] VehicleType/BatteryElectricVehicle/extension/WeekendScheduleFractions
             :ev_monthly_multipliers] # [String] VehicleType/BatteryElectricVehicle/extension/MonthlyScheduleMultipliers
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.vehicles.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      vehicles = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'Vehicles'])
      vehicle = XMLHelper.add_element(vehicles, 'Vehicle')
      sys_id = XMLHelper.add_element(vehicle, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      vehicle_type_element = XMLHelper.add_element(vehicle, 'VehicleType')
      vehicle_type = XMLHelper.add_element(vehicle_type_element, @vehicle_type)

      if [HPXML::VehicleTypeBEV, HPXML::VehicleTypePHEV, HPXML::VehicleTypeHybrid].include? @vehicle_type
        if (not @battery_type.nil?) || (not @nominal_capacity_kwh.nil?) || (not @nominal_capacity_ah.nil?) || (not @usable_capacity_kwh.nil?) || (not @usable_capacity_ah.nil?) || (not @nominal_voltage.nil?)
          battery = XMLHelper.add_element(vehicle_type, 'Battery')
          XMLHelper.add_element(battery, 'BatteryType', @battery_type, :string, @battery_type_isdefaulted) unless @battery_type.nil?
          if not @nominal_capacity_kwh.nil?
            nominal_capacity = XMLHelper.add_element(battery, 'NominalCapacity')
            XMLHelper.add_element(nominal_capacity, 'Units', UnitsKwh, :string)
            XMLHelper.add_element(nominal_capacity, 'Value', @nominal_capacity_kwh, :float, @nominal_capacity_kwh_isdefaulted)
          end
          if not @nominal_capacity_ah.nil?
            nominal_capacity = XMLHelper.add_element(battery, 'NominalCapacity')
            XMLHelper.add_element(nominal_capacity, 'Units', UnitsAh, :string)
            XMLHelper.add_element(nominal_capacity, 'Value', @nominal_capacity_ah, :float, @nominal_capacity_ah_isdefaulted)
          end
          if not @usable_capacity_kwh.nil?
            usable_capacity = XMLHelper.add_element(battery, 'UsableCapacity')
            XMLHelper.add_element(usable_capacity, 'Units', UnitsKwh, :string)
            XMLHelper.add_element(usable_capacity, 'Value', @usable_capacity_kwh, :float, @usable_capacity_kwh_isdefaulted)
          end
          if not @usable_capacity_ah.nil?
            usable_capacity = XMLHelper.add_element(battery, 'UsableCapacity')
            XMLHelper.add_element(usable_capacity, 'Units', UnitsAh, :string)
            XMLHelper.add_element(usable_capacity, 'Value', @usable_capacity_ah, :float, @usable_capacity_ah_isdefaulted)
          end
          XMLHelper.add_element(battery, 'NominalVoltage', @nominal_voltage, :float, @nominal_voltage_isdefaulted) unless @nominal_voltage.nil?
        end
      end

      case @vehicle_type
      when HPXML::VehicleTypeBEV
        if not @fraction_charged_home.nil?
          fraction_charged_location = XMLHelper.add_element(vehicle_type, 'FractionChargedLocation')
          XMLHelper.add_element(fraction_charged_location, 'Location', HPXML::ElectricVehicleChargingLocationHome, :string)
          XMLHelper.add_element(fraction_charged_location, 'Percentage', @fraction_charged_home, :float, @fraction_charged_home_isdefaulted)
        end
        if not @ev_charger_idref.nil?
          charger = XMLHelper.add_element(vehicle_type, 'ConnectedCharger')
          XMLHelper.add_attribute(charger, 'idref', @ev_charger_idref)
        end
        XMLHelper.add_extension(vehicle_type, 'UsageMultiplier', @ev_usage_multiplier, :float, @ev_usage_multiplier_isdefaulted) unless @ev_usage_multiplier.nil?
        XMLHelper.add_extension(vehicle_type, 'WeekdayScheduleFractions', @ev_weekday_fractions, :string, @ev_weekday_fractions_isdefaulted) unless @ev_weekday_fractions.nil?
        XMLHelper.add_extension(vehicle_type, 'WeekendScheduleFractions', @ev_weekend_fractions, :string, @ev_weekend_fractions_isdefaulted) unless @ev_weekend_fractions.nil?
        XMLHelper.add_extension(vehicle_type, 'MonthlyScheduleMultipliers', @ev_monthly_multipliers, :string, @ev_monthly_multipliers_isdefaulted) unless @ev_monthly_multipliers.nil?
      end

      XMLHelper.add_element(vehicle, 'MilesDrivenPerYear', @miles_per_year, :float, @miles_per_year_isdefaulted) unless @miles_per_year.nil?
      XMLHelper.add_element(vehicle, 'HoursDrivenPerWeek', @hours_per_week, :float, @hours_per_week_isdefaulted) unless @hours_per_week.nil?
      if (not @fuel_economy_units.nil?) && (not @fuel_economy_combined.nil?)
        fuel_economy = XMLHelper.add_element(vehicle, 'FuelEconomyCombined')
        XMLHelper.add_element(fuel_economy, 'Units', @fuel_economy_units, :string, @fuel_economy_units_isdefaulted)
        XMLHelper.add_element(fuel_economy, 'Value', @fuel_economy_combined, :float, @fuel_economy_combined_isdefaulted)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param battery [Oga::XML::Element] The current Battery XML element
    # @return [nil]
    def from_doc(vehicle)
      return if vehicle.nil?

      @id = HPXML::get_id(vehicle)
      @miles_per_year = XMLHelper.get_value(vehicle, 'MilesDrivenPeryear', :float)
      @hours_per_week = XMLHelper.get_value(vehicle, 'HoursDrivenPerWeek', :float)
      @fuel_economy_combined = XMLHelper.get_value(vehicle, 'FuelEconomyCombined/Value', :float)
      @fuel_economy_units = XMLHelper.get_value(vehicle, 'FuelEconomyCombined/Units', :string)
      @vehicle_type = XMLHelper.get_child_name(vehicle, 'VehicleType')
      if @vehicle_type == HPXML::VehicleTypeBEV
        battery_prefix = "VehicleType/#{@vehicle_type}/Battery"
        @battery_type = XMLHelper.get_value(vehicle, "#{battery_prefix}/BatteryType", :string)
        @nominal_capacity_kwh = XMLHelper.get_value(vehicle, "#{battery_prefix}/NominalCapacity[Units='#{UnitsKwh}']/Value", :float)
        @nominal_capacity_ah = XMLHelper.get_value(vehicle, "#{battery_prefix}/NominalCapacity[Units='#{UnitsAh}']/Value", :float)
        @usable_capacity_kwh = XMLHelper.get_value(vehicle, "#{battery_prefix}/UsableCapacity[Units='#{UnitsKwh}']/Value", :float)
        @usable_capacity_ah = XMLHelper.get_value(vehicle, "#{battery_prefix}/UsableCapacity[Units='#{UnitsAh}']/Value", :float)
        @nominal_voltage = XMLHelper.get_value(vehicle, "#{battery_prefix}/NominalVoltage", :float)
        @fraction_charged_home = XMLHelper.get_value(vehicle, "VehicleType/#{@vehicle_type}/FractionChargedLocation[Location='#{HPXML::ElectricVehicleChargingLocationHome}']/Percentage", :float)
        @ev_charger_idref = HPXML::get_idref(XMLHelper.get_element(vehicle, "VehicleType/#{@vehicle_type}/ConnectedCharger"))
        @ev_usage_multiplier = XMLHelper.get_value(vehicle, "VehicleType/#{@vehicle_type}/extension/UsageMultiplier", :float)
        @ev_weekday_fractions = XMLHelper.get_value(vehicle, "VehicleType/#{@vehicle_type}/extension/WeekdayScheduleFractions", :string)
        @ev_weekend_fractions = XMLHelper.get_value(vehicle, "VehicleType/#{@vehicle_type}/extension/WeekendScheduleFractions", :string)
        @ev_monthly_multipliers = XMLHelper.get_value(vehicle, "VehicleType/#{@vehicle_type}/extension/MonthlyScheduleMultipliers", :string)
      end
    end

    # Returns the EV charger for the vehicle.
    #
    # @return [HPXML::ElectricVehicleCharger] The connected EV charger
    def ev_charger
      return if @ev_charger_idref.nil?

      @parent_object.ev_chargers.each do |ev_charger|
        next unless ev_charger.id == @ev_charger_idref

        return ev_charger
      end
      fail "Connected charger '#{@ev_charger_idref}' not found for vehicle '#{@id}'."
    end
  end

  # Array of HPXML::ElectricPanel objects.
  class ElectricPanels < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << ElectricPanel.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/ElectricPanels/ElectricPanel').each do |electric_panel|
        self << ElectricPanel.new(@parent_object, electric_panel)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/ElectricPanels/ElectricPanel.
  class ElectricPanel < BaseElement
    def initialize(hpxml_element, *args, **kwargs)
      @branch_circuits = BranchCircuits.new(hpxml_element)
      @service_feeders = ServiceFeeders.new(hpxml_element)
      super(hpxml_element, *args, **kwargs)
    end
    CLASS_ATTRS = [:branch_circuits,
                   :service_feeders]
    ATTRS = [:id,                      # [String] SystemIdentifier/@id
             :sameas_id,               # [String] SystemIdentifier/@sameas
             :voltage,                 # [String] Voltage
             :max_current_rating,      # [Double] MaxCurrentRating
             :headroom_spaces,         # [Integer] HeadroomSpaces
             :rated_total_spaces,      # [Integer] RatedTotalSpaces
             :capacity_types,          # [Array<String>] extension/Outputs/Capacity/Type
             :capacity_total_watts,    # [Array<Double>] extension/Outputs/Capacity/TotalWatts
             :capacity_total_amps,     # [Array<Double>] extension/Outputs/Capacity/TotalAmps
             :capacity_headroom_amps]  # [Array<Double>] extension/Outputs/Capacity/HeadroomAmps
    attr_reader(*CLASS_ATTRS)
    attr_accessor(*ATTRS)

    # Returns the electric panels attached to branch circuits.
    #
    # @return [Array<HPXML::ElectricPanel>] The list of attached electric panels
    def sub_panels
      list = []
      branch_circuits.each do |branch_circuit|
        list << branch_circuit.electric_panel
      end
      return list
    end

    # Calculate the sum of OccupiedSpaces across BranchCircuits.
    #
    # @return [Double] Total occupied spaces
    def occupied_spaces
      occupied_spaces = 0.0
      branch_circuits.each do |branch_circuit|
        occupied_spaces += branch_circuit.occupied_spaces
      end
      return occupied_spaces
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.electric_panels.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      errors += @branch_circuits.check_for_errors
      errors += @service_feeders.check_for_errors
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      electric_panels = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'ElectricPanels'])
      electric_panel = XMLHelper.add_element(electric_panels, 'ElectricPanel')
      sys_id = XMLHelper.add_element(electric_panel, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(electric_panel, 'Voltage', @voltage, :string, @voltage_isdefaulted) unless @voltage.nil?
      XMLHelper.add_element(electric_panel, 'MaxCurrentRating', @max_current_rating, :float, @max_current_rating_isdefaulted) unless @max_current_rating.nil?
      XMLHelper.add_element(electric_panel, 'HeadroomSpaces', @headroom_spaces, :integer, @headroom_spaces_isdefaulted) unless @headroom_spaces.nil?
      XMLHelper.add_element(electric_panel, 'RatedTotalSpaces', @rated_total_spaces, :integer, @rated_total_spaces_isdefaulted) unless @rated_total_spaces.nil?
      @branch_circuits.to_doc(electric_panel)
      @service_feeders.to_doc(electric_panel)
      if (not @capacity_types.nil?) && (not @capacity_types.empty?)
        outputs = XMLHelper.create_elements_as_needed(electric_panel, ['extension', 'Outputs'])
        XMLHelper.add_attribute(outputs, 'dataSource', 'software')
        capacities = @capacity_types.zip(@capacity_total_watts, @capacity_total_amps, @capacity_headroom_amps)
        capacities.each do |capacity|
          capacity_type, capacity_total_watt, capacity_total_amp, capacity_headroom_amp = capacity
          capacity = XMLHelper.add_element(outputs, 'Capacity')
          XMLHelper.add_element(capacity, 'Type', capacity_type, :string)
          XMLHelper.add_element(capacity, 'TotalWatts', capacity_total_watt, :float)
          XMLHelper.add_element(capacity, 'TotalAmps', capacity_total_amp, :float)
          XMLHelper.add_element(capacity, 'HeadroomAmps', capacity_headroom_amp, :float)
        end
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param electric_panel [Oga::XML::Element] The current ElectricPanel XML element
    # @return [nil]
    def from_doc(electric_panel)
      return if electric_panel.nil?

      @id = HPXML::get_id(electric_panel)
      @voltage = XMLHelper.get_value(electric_panel, 'Voltage', :string)
      @max_current_rating = XMLHelper.get_value(electric_panel, 'MaxCurrentRating', :float)
      @headroom_spaces = XMLHelper.get_value(electric_panel, 'HeadroomSpaces', :integer)
      @rated_total_spaces = XMLHelper.get_value(electric_panel, 'RatedTotalSpaces', :integer)
      @branch_circuits.from_doc(electric_panel)
      @service_feeders.from_doc(electric_panel)
      @capacity_types = XMLHelper.get_values(electric_panel, 'extension/Outputs/Capacity/Type', :string)
      @capacity_total_watts = XMLHelper.get_values(electric_panel, 'extension/Outputs/Capacity/TotalWatts', :float)
      @capacity_total_amps = XMLHelper.get_values(electric_panel, 'extension/Outputs/Capacity/TotalAmps', :float)
      @capacity_headroom_amps = XMLHelper.get_values(electric_panel, 'extension/Outputs/Capacity/HeadroomAmps', :float)
    end
  end

  # Array of HPXML::BranchCircuit objects.
  class BranchCircuits < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << BranchCircuit.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param electric_panel [Oga::XML::Element] The current Electric panel XML element
    # @return [nil]
    def from_doc(electric_panel)
      return if electric_panel.nil?

      XMLHelper.get_elements(electric_panel, 'BranchCircuits/BranchCircuit').each do |branch_circuit|
        self << BranchCircuit.new(@parent_object, branch_circuit)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/ElectricPanels/ElectricPanel/BranchCircuits/BranchCircuit.
  class BranchCircuit < BaseElement
    ATTRS = [:id,                 # [String] SystemIdentifier/@id
             :sameas_id,          # [String] SystemIdentifier/@sameas
             :voltage,            # [String] Voltage
             :max_current_rating, # [Double] MaxCurrentRating
             :occupied_spaces,    # [Double] OccupiedSpaces
             :component_idrefs,   # [Array<String>] AttachedToComponent/@idref
             :panel_idref]        # [String] AttachedToElectricPanel/@idref
    attr_accessor(*ATTRS)

    # Returns the components attached to the branch circuit.
    # These are the same components that can be attached to a service feeder, plus any components defaulted to 240V.
    #
    # @return [Array<HPXML::XXX>] The attached components
    def components
      return [] if @component_idrefs.nil?

      heating_systems = @parent_object.heating_systems.select { |heating_system| @component_idrefs.include? heating_system.id }
      cooling_systems = @parent_object.cooling_systems.select { |cooling_system| @component_idrefs.include? cooling_system.id }
      heat_pumps = @parent_object.heat_pumps.select { |heat_pump| @component_idrefs.include? heat_pump.id }
      water_heating_systems = @parent_object.water_heating_systems.select { |water_heating_system| @component_idrefs.include? water_heating_system.id }
      clothes_dryers = @parent_object.clothes_dryers.select { |clothes_dryer| @component_idrefs.include? clothes_dryer.id }
      dishwashers = @parent_object.dishwashers.select { |dishwasher| @component_idrefs.include? dishwasher.id }
      cooking_ranges = @parent_object.cooking_ranges.select { |cooking_range| @component_idrefs.include? cooking_range.id }
      ventilation_fans = @parent_object.ventilation_fans.select { |ventilation_fan| @component_idrefs.include? ventilation_fan.id }
      permanent_spa_pumps = @parent_object.permanent_spas.select { |permanent_spa| @component_idrefs.include? permanent_spa.pump_id }
      permanent_spa_heaters = @parent_object.permanent_spas.select { |permanent_spa| @component_idrefs.include? permanent_spa.heater_id }
      pool_pumps = @parent_object.pools.select { |pool| @component_idrefs.include? pool.pump_id }
      pool_heaters = @parent_object.pools.select { |pool| @component_idrefs.include? pool.heater_id }
      plug_load_well_pumps = @parent_object.plug_loads.select { |plug_load| @component_idrefs.include?(plug_load.id) && plug_load.plug_load_type == HPXML::PlugLoadTypeWellPump }
      plug_load_vehicles = @parent_object.plug_loads.select { |plug_load| @component_idrefs.include?(plug_load.id) && plug_load.plug_load_type == HPXML::PlugLoadTypeElectricVehicleCharging }
      ev_chargers = @parent_object.ev_chargers.select { |ev_charger| @component_idrefs.include?(ev_charger.id) }
      pv_systems = @parent_object.pv_systems.select { |pv_system| @component_idrefs.include? pv_system.id }
      batteries = @parent_object.batteries.select { |battery| @component_idrefs.include? battery.id }

      list = (heating_systems + cooling_systems + heat_pumps + water_heating_systems + clothes_dryers + dishwashers + cooking_ranges + ventilation_fans +
              permanent_spa_pumps + permanent_spa_heaters + pool_pumps + pool_heaters + plug_load_well_pumps + plug_load_vehicles + ev_chargers + pv_systems + batteries)

      return list
    end

    # Returns the panel connected to the branch circuit.
    #
    # @return [HPXML::ElectricPanel] The attached electric panel object
    def electric_panel
      return if @panel_idref.nil?

      @parent_object.electric_panels.each do |electric_panel|
        next unless electric_panel.id == @panel_idref

        return electric_panel
      end
      fail "Attached electric panel '#{@panel_idref}' not found for branch circuit '#{@id}'."
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.electric_panels.each do |electric_panel|
        electric_panel.branch_circuits.delete(self)
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(electric_panel)
      return if nil?

      branch_circuits = XMLHelper.create_elements_as_needed(electric_panel, ['BranchCircuits'])
      branch_circuit = XMLHelper.add_element(branch_circuits, 'BranchCircuit')
      sys_id = XMLHelper.add_element(branch_circuit, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(branch_circuit, 'Voltage', @voltage, :string, @voltage_isdefaulted) unless @voltage.nil?
      XMLHelper.add_element(branch_circuit, 'MaxCurrentRating', @max_current_rating, :float, @max_current_rating_isdefaulted) unless @max_current_rating.nil?
      XMLHelper.add_element(branch_circuit, 'OccupiedSpaces', @occupied_spaces, :float, @occupied_spaces_isdefaulted) unless @occupied_spaces.nil?
      if (not @component_idrefs.nil?) && (not @component_idrefs.empty?)
        @component_idrefs.each do |component_idref|
          component = XMLHelper.add_element(branch_circuit, 'AttachedToComponent')
          XMLHelper.add_attribute(component, 'idref', component_idref)
          XMLHelper.add_attribute(component, 'dataSource', 'software') if @component_idrefs_isdefaulted
        end
      end
      if not @panel_idref.nil?
        attached_to_panel = XMLHelper.add_element(branch_circuit, 'AttachedToElectricPanel')
        XMLHelper.add_attribute(attached_to_panel, 'idref', @panel_idref)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param branch_circuit [Oga::XML::Element] The current BranchCircuit XML element
    # @return [nil]
    def from_doc(branch_circuit)
      return if branch_circuit.nil?

      @id = HPXML::get_id(branch_circuit)
      @voltage = XMLHelper.get_value(branch_circuit, 'Voltage', :string)
      @max_current_rating = XMLHelper.get_value(branch_circuit, 'MaxCurrentRating', :float)
      @occupied_spaces = XMLHelper.get_value(branch_circuit, 'OccupiedSpaces', :float)
      @component_idrefs = HPXML::get_idrefs(branch_circuit, 'AttachedToComponent')
      @panel_idref = HPXML::get_idref(XMLHelper.get_element(branch_circuit, 'AttachedToElectricPanel'))
    end
  end

  # Array of HPXML::ServiceFeeder objects.
  class ServiceFeeders < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << ServiceFeeder.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param electric_panel [Oga::XML::Element] The current Electric panel XML element
    # @return [nil]
    def from_doc(electric_panel)
      return if electric_panel.nil?

      XMLHelper.get_elements(electric_panel, 'ServiceFeeders/ServiceFeeder').each do |service_feeder|
        self << ServiceFeeder.new(@parent_object, service_feeder)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/ElectricPanels/ElectricPanel/ServiceFeeders/ServiceFeeder.
  class ServiceFeeder < BaseElement
    ATTRS = [:id,                # [String] SystemIdentifier/@id
             :sameas_id,         # [String] SystemIdentifier/@sameas
             :type,              # [String] LoadType
             :power,             # [Double] PowerRating
             :is_new_load,       # [Boolean] IsNewLoad
             :component_idrefs]  # [Array<String>] AttachedToComponent/@idref
    attr_accessor(*ATTRS)

    # Returns the components attached to the service feeder (i.e., components that are allowed for a given load type).
    #
    # @return [Array<HPXML::XXX>] The attached components
    def components
      return [] if @component_idrefs.nil?

      heating_systems = @parent_object.heating_systems.select { |heating_system| @component_idrefs.include? heating_system.id }
      cooling_systems = @parent_object.cooling_systems.select { |cooling_system| @component_idrefs.include? cooling_system.id }
      heat_pumps = @parent_object.heat_pumps.select { |heat_pump| @component_idrefs.include? heat_pump.id }
      water_heating_systems = @parent_object.water_heating_systems.select { |water_heating_system| @component_idrefs.include? water_heating_system.id }
      clothes_dryers = @parent_object.clothes_dryers.select { |clothes_dryer| @component_idrefs.include? clothes_dryer.id }
      dishwashers = @parent_object.dishwashers.select { |dishwasher| @component_idrefs.include? dishwasher.id }
      cooking_ranges = @parent_object.cooking_ranges.select { |cooking_range| @component_idrefs.include? cooking_range.id }
      ventilation_fans = @parent_object.ventilation_fans.select { |ventilation_fan| @component_idrefs.include? ventilation_fan.id }
      permanent_spa_pumps = @parent_object.permanent_spas.select { |permanent_spa| @component_idrefs.include? permanent_spa.pump_id }
      permanent_spa_heaters = @parent_object.permanent_spas.select { |permanent_spa| @component_idrefs.include? permanent_spa.heater_id }
      pool_pumps = @parent_object.pools.select { |pool| @component_idrefs.include? pool.pump_id }
      pool_heaters = @parent_object.pools.select { |pool| @component_idrefs.include? pool.heater_id }
      plug_load_well_pumps = @parent_object.plug_loads.select { |plug_load| @component_idrefs.include?(plug_load.id) && plug_load.plug_load_type == HPXML::PlugLoadTypeWellPump }
      plug_load_vehicles = @parent_object.plug_loads.select { |plug_load| @component_idrefs.include?(plug_load.id) && plug_load.plug_load_type == HPXML::PlugLoadTypeElectricVehicleCharging }
      ev_chargers = @parent_object.ev_chargers.select { |ev_charger| @component_idrefs.include?(ev_charger.id) }

      {
        heating_systems => [HPXML::ElectricPanelLoadTypeHeating],
        cooling_systems => [HPXML::ElectricPanelLoadTypeCooling],
        heat_pumps => [HPXML::ElectricPanelLoadTypeHeating, HPXML::ElectricPanelLoadTypeCooling],
        water_heating_systems => [HPXML::ElectricPanelLoadTypeWaterHeater],
        clothes_dryers => [HPXML::ElectricPanelLoadTypeClothesDryer],
        dishwashers => [HPXML::ElectricPanelLoadTypeDishwasher],
        cooking_ranges => [HPXML::ElectricPanelLoadTypeRangeOven],
        ventilation_fans => [HPXML::ElectricPanelLoadTypeMechVent],
        permanent_spa_pumps => [HPXML::ElectricPanelLoadTypePermanentSpaPump],
        permanent_spa_heaters => [HPXML::ElectricPanelLoadTypePermanentSpaHeater],
        pool_pumps => [HPXML::ElectricPanelLoadTypePoolPump],
        pool_heaters => [HPXML::ElectricPanelLoadTypePoolHeater],
        plug_load_well_pumps => [HPXML::ElectricPanelLoadTypeWellPump],
        plug_load_vehicles => [HPXML::ElectricPanelLoadTypeElectricVehicleCharging],
        ev_chargers => [HPXML::ElectricPanelLoadTypeElectricVehicleCharging],
      }.each do |hpxml_objects, load_types|
        if !hpxml_objects.empty? && !load_types.include?(@type)
          fail "One or more referenced components '#{@component_idrefs.join("', '")}' not valid for service feeder '#{@id}' with LoadType '#{@type}'."
        end
      end

      list = (heating_systems + cooling_systems + heat_pumps + water_heating_systems + clothes_dryers + dishwashers + cooking_ranges + ventilation_fans +
              permanent_spa_pumps + permanent_spa_heaters + pool_pumps + pool_heaters + plug_load_well_pumps + plug_load_vehicles + ev_chargers)

      return list
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.electric_panels.each do |electric_panel|
        electric_panel.service_feeders.delete(self)
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; components; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(electric_panel)
      return if nil?

      service_feeders = XMLHelper.create_elements_as_needed(electric_panel, ['ServiceFeeders'])
      service_feeder = XMLHelper.add_element(service_feeders, 'ServiceFeeder')
      sys_id = XMLHelper.add_element(service_feeder, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(service_feeder, 'LoadType', @type, :string, @type_isdefaulted) unless @type.nil?
      XMLHelper.add_element(service_feeder, 'PowerRating', @power, :float, @power_isdefaulted) unless @power.nil?
      XMLHelper.add_element(service_feeder, 'IsNewLoad', @is_new_load, :boolean, @is_new_load_isdefaulted) unless @is_new_load.nil?
      if (not @component_idrefs.nil?) && (not @component_idrefs.empty?)
        @component_idrefs.each do |component_idref|
          component = XMLHelper.add_element(service_feeder, 'AttachedToComponent')
          XMLHelper.add_attribute(component, 'idref', component_idref)
          XMLHelper.add_attribute(component, 'dataSource', 'software') if @component_idrefs_isdefaulted
        end
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param service_feeder [Oga::XML::Element] The current ServiceFeeder XML element
    # @return [nil]
    def from_doc(service_feeder)
      return if service_feeder.nil?

      @id = HPXML::get_id(service_feeder)
      @type = XMLHelper.get_value(service_feeder, 'LoadType', :string)
      @power = XMLHelper.get_value(service_feeder, 'PowerRating', :float)
      @is_new_load = XMLHelper.get_value(service_feeder, 'IsNewLoad', :boolean)
      @component_idrefs = HPXML::get_idrefs(service_feeder, 'AttachedToComponent')
    end
  end

  # Array of HPXML::Battery objects.
  class Batteries < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Battery.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/Batteries/Battery').each do |battery|
        self << Battery.new(@parent_object, battery)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/Batteries/Battery.
  class Battery < BaseElement
    ATTRS = [:id,                        # [String] SystemIdentifier/@id
             :sameas_id,                 # [String] SystemIdentifier/@sameas
             :is_shared_system,          # [Boolean] IsSharedSystem
             :location,                  # [String] Location (HPXML::LocationXXX)
             :type,                      # [String] BatteryType (HPXML::BatteryTypeXXX)
             :nominal_capacity_kwh,      # [Double] NominalCapacity[Units="kWh"]/Value (kWh)
             :nominal_capacity_ah,       # [Double] NominalCapacity[Units="Ah"]/Value (Ah)
             :usable_capacity_kwh,       # [Double] UsableCapacity[Units="kWh"]/Value (kWh)
             :usable_capacity_ah,        # [Double] UsableCapacity[Units="Ah"]/Value (Ah)
             :rated_power_output,        # [Double] RatedPowerOutput (W)
             :nominal_voltage,           # [Double] NominalVoltage (V)
             :round_trip_efficiency,     # [Double] RoundTripEfficiency (frac)
             :number_of_bedrooms_served] # [Integer] extension/NumberofBedroomsServed
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.batteries.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      batteries = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'Batteries'])
      battery = XMLHelper.add_element(batteries, 'Battery')
      sys_id = XMLHelper.add_element(battery, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(battery, 'IsSharedSystem', @is_shared_system, :boolean, @is_shared_system_isdefaulted) unless @is_shared_system.nil?
      XMLHelper.add_element(battery, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(battery, 'BatteryType', @type, :string) unless @type.nil?
      if not @nominal_capacity_kwh.nil?
        nominal_capacity = XMLHelper.add_element(battery, 'NominalCapacity')
        XMLHelper.add_element(nominal_capacity, 'Units', UnitsKwh, :string)
        XMLHelper.add_element(nominal_capacity, 'Value', @nominal_capacity_kwh, :float, @nominal_capacity_kwh_isdefaulted)
      end
      if not @nominal_capacity_ah.nil?
        nominal_capacity = XMLHelper.add_element(battery, 'NominalCapacity')
        XMLHelper.add_element(nominal_capacity, 'Units', UnitsAh, :string)
        XMLHelper.add_element(nominal_capacity, 'Value', @nominal_capacity_ah, :float, @nominal_capacity_ah_isdefaulted)
      end
      if not @usable_capacity_kwh.nil?
        nominal_capacity = XMLHelper.add_element(battery, 'UsableCapacity')
        XMLHelper.add_element(nominal_capacity, 'Units', UnitsKwh, :string)
        XMLHelper.add_element(nominal_capacity, 'Value', @usable_capacity_kwh, :float, @usable_capacity_kwh_isdefaulted)
      end
      if not @usable_capacity_ah.nil?
        nominal_capacity = XMLHelper.add_element(battery, 'UsableCapacity')
        XMLHelper.add_element(nominal_capacity, 'Units', UnitsAh, :string)
        XMLHelper.add_element(nominal_capacity, 'Value', @usable_capacity_ah, :float, @usable_capacity_ah_isdefaulted)
      end
      XMLHelper.add_element(battery, 'RatedPowerOutput', @rated_power_output, :float, @rated_power_output_isdefaulted) unless @rated_power_output.nil?
      XMLHelper.add_element(battery, 'NominalVoltage', @nominal_voltage, :float, @nominal_voltage_isdefaulted) unless @nominal_voltage.nil?
      XMLHelper.add_element(battery, 'RoundTripEfficiency', @round_trip_efficiency, :float, @round_trip_efficiency_isdefaulted) unless @round_trip_efficiency.nil?
      XMLHelper.add_extension(battery, 'NumberofBedroomsServed', @number_of_bedrooms_served, :integer) unless @number_of_bedrooms_served.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param battery [Oga::XML::Element] The current Battery XML element
    # @return [nil]
    def from_doc(battery)
      return if battery.nil?

      @id = HPXML::get_id(battery)
      @is_shared_system = XMLHelper.get_value(battery, 'IsSharedSystem', :boolean)
      @location = XMLHelper.get_value(battery, 'Location', :string)
      @type = XMLHelper.get_value(battery, 'BatteryType', :string)
      @nominal_capacity_kwh = XMLHelper.get_value(battery, "NominalCapacity[Units='#{UnitsKwh}']/Value", :float)
      @nominal_capacity_ah = XMLHelper.get_value(battery, "NominalCapacity[Units='#{UnitsAh}']/Value", :float)
      @usable_capacity_kwh = XMLHelper.get_value(battery, "UsableCapacity[Units='#{UnitsKwh}']/Value", :float)
      @usable_capacity_ah = XMLHelper.get_value(battery, "UsableCapacity[Units='#{UnitsAh}']/Value", :float)
      @rated_power_output = XMLHelper.get_value(battery, 'RatedPowerOutput', :float)
      @nominal_voltage = XMLHelper.get_value(battery, 'NominalVoltage', :float)
      @round_trip_efficiency = XMLHelper.get_value(battery, 'RoundTripEFficiency', :float)
      @number_of_bedrooms_served = XMLHelper.get_value(battery, 'extension/NumberofBedroomsServed', :integer)
    end
  end

  # Array of HPXML::Generator objects.
  class Generators < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Generator.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Systems/extension/Generators/Generator').each do |generator|
        self << Generator.new(@parent_object, generator)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/extension/Generators/Generator.
  class Generator < BaseElement
    ATTRS = [:id,                        # [String] SystemIdentifier/@id
             :sameas_id,                 # [String] SystemIdentifier/@sameas
             :is_shared_system,          # [Boolean] IsSharedSystem
             :fuel_type,                 # [String] FuelType (HPXML::FuelTypeXXX)
             :annual_consumption_kbtu,   # [Double] AnnualConsumptionkBtu (kBtu/yr)
             :annual_output_kwh,         # [Double] AnnualOutputkWh (kWh/yr)
             :number_of_bedrooms_served] # [Integer] NumberofBedroomsServed
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.generators.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      generators = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Systems', 'extension', 'Generators'])
      generator = XMLHelper.add_element(generators, 'Generator')
      sys_id = XMLHelper.add_element(generator, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(generator, 'IsSharedSystem', @is_shared_system, :boolean, @is_shared_system_isdefaulted) unless @is_shared_system.nil?
      XMLHelper.add_element(generator, 'FuelType', @fuel_type, :string) unless @fuel_type.nil?
      XMLHelper.add_element(generator, 'AnnualConsumptionkBtu', @annual_consumption_kbtu, :float) unless @annual_consumption_kbtu.nil?
      XMLHelper.add_element(generator, 'AnnualOutputkWh', @annual_output_kwh, :float) unless @annual_output_kwh.nil?
      XMLHelper.add_element(generator, 'NumberofBedroomsServed', @number_of_bedrooms_served, :integer) unless @number_of_bedrooms_served.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param generator [Oga::XML::Element] The current Generator XML element
    # @return [nil]
    def from_doc(generator)
      return if generator.nil?

      @id = HPXML::get_id(generator)
      @is_shared_system = XMLHelper.get_value(generator, 'IsSharedSystem', :boolean)
      @fuel_type = XMLHelper.get_value(generator, 'FuelType', :string)
      @annual_consumption_kbtu = XMLHelper.get_value(generator, 'AnnualConsumptionkBtu', :float)
      @annual_output_kwh = XMLHelper.get_value(generator, 'AnnualOutputkWh', :float)
      @number_of_bedrooms_served = XMLHelper.get_value(generator, 'NumberofBedroomsServed', :integer)
    end
  end

  # Array of HPXML::ClothesWasher.
  class ClothesWashers < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << ClothesWasher.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/ClothesWasher').each do |clothes_washer|
        self << ClothesWasher.new(@parent_object, clothes_washer)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Appliances/ClothesWasher.
  class ClothesWasher < BaseElement
    ATTRS = [:id,                                # [String] SystemIdentifier/@id
             :sameas_id,                         # [String] SystemIdentifier/@sameas
             :count,                             # [Integer] Count
             :is_shared_appliance,               # [Boolean] IsSharedAppliance
             :number_of_units_served,            # [Integer] NumberofUnitsServed
             :water_heating_system_idref,        # [String] AttachedToWaterHeatingSystem/@idref
             :hot_water_distribution_idref,      # [String] AttachedToHotWaterDistribution/@idref
             :location,                          # [String] Location (HPXML::LocationXXX)
             :modified_energy_factor,            # [Double] ModifiedEnergyFactor (ft3/kWh/cyc)
             :integrated_modified_energy_factor, # [Double] IntegratedModifiedEnergyFactor (ft3/kWh/cyc)
             :rated_annual_kwh,                  # [Double] RatedAnnualkWh (kWh/yr)
             :label_electric_rate,               # [Double] LabelElectricRate ($/kWh)
             :label_gas_rate,                    # [Double] LabelGasRate ($/therm)
             :label_annual_gas_cost,             # [Double] LabelAnnualGasCost ($)
             :label_usage,                       # [Double] LabelUsage (cyc/wk)
             :capacity,                          # [Double] Capacity (ft3)
             :usage_multiplier,                  # [Double] extension/UsageMultiplier
             :weekday_fractions,                 # [String] extension/WeekdayScheduleFractions
             :weekend_fractions,                 # [String] extension/WeekendScheduleFractions
             :monthly_multipliers]               # [String] extension/MonthlyScheduleMultipliers
    attr_accessor(*ATTRS)

    # Returns the water heating system connected to the clothes washer.
    #
    # @return [HPXML::WaterHeatingSystem] The attached water heating system
    def water_heating_system
      return if @water_heating_system_idref.nil?

      @parent_object.water_heating_systems.each do |water_heater|
        next unless water_heater.id == @water_heating_system_idref

        return water_heater
      end
      fail "Attached water heating system '#{@water_heating_system_idref}' not found for clothes washer '#{@id}'."
    end

    # Returns the hot water distribution system connected to the clothes washer.
    #
    # @return [HPXML::HotWaterDistribution] The connected hot water distribution system
    def hot_water_distribution
      return if @hot_water_distribution_idref.nil?

      @parent_object.hot_water_distributions.each do |hot_water_distribution|
        next unless hot_water_distribution.id == @hot_water_distribution_idref

        return hot_water_distribution
      end
      fail "Attached hot water distribution '#{@hot_water_distribution_idref}' not found for clothes washer '#{@id}'."
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.clothes_washers.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; water_heating_system; rescue StandardError => e; errors << e.message; end
      begin; hot_water_distribution; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      clothes_washer = XMLHelper.add_element(appliances, 'ClothesWasher')
      sys_id = XMLHelper.add_element(clothes_washer, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(clothes_washer, 'Count', @count, :integer) unless @count.nil?
      XMLHelper.add_element(clothes_washer, 'IsSharedAppliance', @is_shared_appliance, :boolean, @is_shared_appliance_isdefaulted) unless @is_shared_appliance.nil?
      XMLHelper.add_element(clothes_washer, 'NumberofUnitsServed', @number_of_units_served, :integer) unless @number_of_units_served.nil?
      if not @water_heating_system_idref.nil?
        attached_water_heater = XMLHelper.add_element(clothes_washer, 'AttachedToWaterHeatingSystem')
        XMLHelper.add_attribute(attached_water_heater, 'idref', @water_heating_system_idref)
      elsif not @hot_water_distribution_idref.nil?
        attached_hot_water_dist = XMLHelper.add_element(clothes_washer, 'AttachedToHotWaterDistribution')
        XMLHelper.add_attribute(attached_hot_water_dist, 'idref', @hot_water_distribution_idref)
      end
      XMLHelper.add_element(clothes_washer, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(clothes_washer, 'ModifiedEnergyFactor', @modified_energy_factor, :float) unless @modified_energy_factor.nil?
      XMLHelper.add_element(clothes_washer, 'IntegratedModifiedEnergyFactor', @integrated_modified_energy_factor, :float, @integrated_modified_energy_factor_isdefaulted) unless @integrated_modified_energy_factor.nil?
      XMLHelper.add_element(clothes_washer, 'RatedAnnualkWh', @rated_annual_kwh, :float, @rated_annual_kwh_isdefaulted) unless @rated_annual_kwh.nil?
      XMLHelper.add_element(clothes_washer, 'LabelElectricRate', @label_electric_rate, :float, @label_electric_rate_isdefaulted) unless @label_electric_rate.nil?
      XMLHelper.add_element(clothes_washer, 'LabelGasRate', @label_gas_rate, :float, @label_gas_rate_isdefaulted) unless @label_gas_rate.nil?
      XMLHelper.add_element(clothes_washer, 'LabelAnnualGasCost', @label_annual_gas_cost, :float, @label_annual_gas_cost_isdefaulted) unless @label_annual_gas_cost.nil?
      XMLHelper.add_element(clothes_washer, 'LabelUsage', @label_usage, :float, @label_usage_isdefaulted) unless @label_usage.nil?
      XMLHelper.add_element(clothes_washer, 'Capacity', @capacity, :float, @capacity_isdefaulted) unless @capacity.nil?
      XMLHelper.add_extension(clothes_washer, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(clothes_washer, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(clothes_washer, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(clothes_washer, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param clothes_washer [Oga::XML::Element] The current ClothesWasher XML element
    # @return [nil]
    def from_doc(clothes_washer)
      return if clothes_washer.nil?

      @id = HPXML::get_id(clothes_washer)
      @count = XMLHelper.get_value(clothes_washer, 'Count', :integer)
      @is_shared_appliance = XMLHelper.get_value(clothes_washer, 'IsSharedAppliance', :boolean)
      @number_of_units_served = XMLHelper.get_value(clothes_washer, 'NumberofUnitsServed', :integer)
      @water_heating_system_idref = HPXML::get_idref(XMLHelper.get_element(clothes_washer, 'AttachedToWaterHeatingSystem'))
      @hot_water_distribution_idref = HPXML::get_idref(XMLHelper.get_element(clothes_washer, 'AttachedToHotWaterDistribution'))
      @location = XMLHelper.get_value(clothes_washer, 'Location', :string)
      @modified_energy_factor = XMLHelper.get_value(clothes_washer, 'ModifiedEnergyFactor', :float)
      @integrated_modified_energy_factor = XMLHelper.get_value(clothes_washer, 'IntegratedModifiedEnergyFactor', :float)
      @rated_annual_kwh = XMLHelper.get_value(clothes_washer, 'RatedAnnualkWh', :float)
      @label_electric_rate = XMLHelper.get_value(clothes_washer, 'LabelElectricRate', :float)
      @label_gas_rate = XMLHelper.get_value(clothes_washer, 'LabelGasRate', :float)
      @label_annual_gas_cost = XMLHelper.get_value(clothes_washer, 'LabelAnnualGasCost', :float)
      @label_usage = XMLHelper.get_value(clothes_washer, 'LabelUsage', :float)
      @capacity = XMLHelper.get_value(clothes_washer, 'Capacity', :float)
      @usage_multiplier = XMLHelper.get_value(clothes_washer, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(clothes_washer, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(clothes_washer, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(clothes_washer, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  # Array of HPXML::ClothesDryer objects.
  class ClothesDryers < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << ClothesDryer.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/ClothesDryer').each do |clothes_dryer|
        self << ClothesDryer.new(@parent_object, clothes_dryer)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Appliances/ClothesDryer.
  class ClothesDryer < BaseElement
    ATTRS = [:id,                     # [String] SystemIdentifier/@id
             :sameas_id,              # [String] SystemIdentifier/@sameas
             :count,                  # [Integer] Count
             :is_shared_appliance,    # [Boolean] IsSharedAppliance
             :number_of_units_served, # [Integer] NumberofUnitsServed
             :location,               # [String] Location (HPXML::LocationXXX)
             :fuel_type,              # [String] FuelType (HPXML::FuelTypeXXX)
             :drying_method,          # [String] DryingMethod (HPXML::DryingMethodXXX)
             :energy_factor,          # [Double] EnergyFactor (lb/kWh)
             :combined_energy_factor, # [Double] CombinedEnergyFactor (lb/kWh)
             :control_type,           # [String] ControlType (HPXML::ClothesDryerControlTypeXXX)
             :is_vented,              # [Boolean] Vented
             :vented_flow_rate,       # [Double] VentedFlowRate (cfm)
             :usage_multiplier,       # [Double] extension/UsageMultiplier
             :weekday_fractions,      # [String] extension/WeekdayScheduleFractions
             :weekend_fractions,      # [String] extension/WeekendScheduleFractions
             :monthly_multipliers]    # [String] extension/MonthlyScheduleMultipliers
    attr_accessor(*ATTRS)

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def branch_circuits
      return HPXML::branch_circuits(@id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def service_feeders
      return HPXML::service_feeders(@id, @parent_object.electric_panels)
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.clothes_dryers.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      clothes_dryer = XMLHelper.add_element(appliances, 'ClothesDryer')
      sys_id = XMLHelper.add_element(clothes_dryer, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(clothes_dryer, 'Count', @count, :integer) unless @count.nil?
      XMLHelper.add_element(clothes_dryer, 'IsSharedAppliance', @is_shared_appliance, :boolean, @is_shared_appliance_isdefaulted) unless @is_shared_appliance.nil?
      XMLHelper.add_element(clothes_dryer, 'NumberofUnitsServed', @number_of_units_served, :integer) unless @number_of_units_served.nil?
      XMLHelper.add_element(clothes_dryer, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(clothes_dryer, 'FuelType', @fuel_type, :string) unless @fuel_type.nil?
      XMLHelper.add_element(clothes_dryer, 'DryingMethod', @drying_method, :string, @drying_method_isdefaulted) unless @drying_method.nil?
      XMLHelper.add_element(clothes_dryer, 'EnergyFactor', @energy_factor, :float) unless @energy_factor.nil?
      XMLHelper.add_element(clothes_dryer, 'CombinedEnergyFactor', @combined_energy_factor, :float, @combined_energy_factor_isdefaulted) unless @combined_energy_factor.nil?
      XMLHelper.add_element(clothes_dryer, 'ControlType', @control_type, :string, @control_type_isdefaulted) unless @control_type.nil?
      XMLHelper.add_element(clothes_dryer, 'Vented', @is_vented, :boolean, @is_vented_isdefaulted) unless @is_vented.nil?
      XMLHelper.add_element(clothes_dryer, 'VentedFlowRate', @vented_flow_rate, :float, @vented_flow_rate_isdefaulted) unless @vented_flow_rate.nil?
      XMLHelper.add_extension(clothes_dryer, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(clothes_dryer, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(clothes_dryer, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(clothes_dryer, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param clothes_dryer [Oga::XML::Element] The current ClothesDryer XML element
    # @return [nil]
    def from_doc(clothes_dryer)
      return if clothes_dryer.nil?

      @id = HPXML::get_id(clothes_dryer)
      @count = XMLHelper.get_value(clothes_dryer, 'Count', :integer)
      @is_shared_appliance = XMLHelper.get_value(clothes_dryer, 'IsSharedAppliance', :boolean)
      @number_of_units_served = XMLHelper.get_value(clothes_dryer, 'NumberofUnitsServed', :integer)
      @location = XMLHelper.get_value(clothes_dryer, 'Location', :string)
      @fuel_type = XMLHelper.get_value(clothes_dryer, 'FuelType', :string)
      @drying_method = XMLHelper.get_value(clothes_dryer, 'DryingMethod', :string)
      @energy_factor = XMLHelper.get_value(clothes_dryer, 'EnergyFactor', :float)
      @combined_energy_factor = XMLHelper.get_value(clothes_dryer, 'CombinedEnergyFactor', :float)
      @control_type = XMLHelper.get_value(clothes_dryer, 'ControlType', :string)
      @is_vented = XMLHelper.get_value(clothes_dryer, 'Vented', :boolean)
      @vented_flow_rate = XMLHelper.get_value(clothes_dryer, 'VentedFlowRate', :float)
      @usage_multiplier = XMLHelper.get_value(clothes_dryer, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(clothes_dryer, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(clothes_dryer, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(clothes_dryer, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  # Array of HPXML::Dishwasher objects.
  class Dishwashers < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Dishwasher.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/Dishwasher').each do |dishwasher|
        self << Dishwasher.new(@parent_object, dishwasher)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Appliances/Dishwasher.
  class Dishwasher < BaseElement
    ATTRS = [:id,                           # [String] SystemIdentifier/@id
             :sameas_id,                    # [String] SystemIdentifier/@sameas
             :is_shared_appliance,          # [Boolean] IsSharedAppliance
             :water_heating_system_idref,   # [String] AttachedToWaterHeatingSystem/@idref
             :hot_water_distribution_idref, # [String] AttachedToHotWaterDistribution/@idref
             :location,                     # [String] Location (HPXML::LocationXXX)
             :rated_annual_kwh,             # [Double] RatedAnnualkWh (kWh/yr)
             :energy_factor,                # [Double] EnergyFactor
             :place_setting_capacity,       # [Integer] PlaceSettingCapacity
             :label_electric_rate,          # [Double] LabelElectricRate ($/kWh)
             :label_gas_rate,               # [Double] LabelGasRate ($/therm)
             :label_annual_gas_cost,        # [Double] LabelAnnualGasCost ($)
             :label_usage,                  # [Double] LabelUsage (cyc/wk)
             :usage_multiplier,             # [Double] extension/UsageMultiplier
             :weekday_fractions,            # [String] extension/WeekdayScheduleFractions
             :weekend_fractions,            # [String] extension/WeekendScheduleFractions
             :monthly_multipliers]          # [String] extension/MonthlyScheduleMultipliers
    attr_accessor(*ATTRS)

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def branch_circuits
      return HPXML::branch_circuits(@id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def service_feeders
      return HPXML::service_feeders(@id, @parent_object.electric_panels)
    end

    # Returns the water heating system connected to the dishwasher.
    #
    # @return [HPXML::WaterHeatingSystem] The attached water heating system
    def water_heating_system
      return if @water_heating_system_idref.nil?

      @parent_object.water_heating_systems.each do |water_heater|
        next unless water_heater.id == @water_heating_system_idref

        return water_heater
      end
      fail "Attached water heating system '#{@water_heating_system_idref}' not found for dishwasher '#{@id}'."
    end

    # Returns the hot water distribution system connected to the dishwasher.
    #
    # @return [HPXML::HotWaterDistribution] The connected hot water distribution system
    def hot_water_distribution
      return if @hot_water_distribution_idref.nil?

      @parent_object.hot_water_distributions.each do |hot_water_distribution|
        next unless hot_water_distribution.id == @hot_water_distribution_idref

        return hot_water_distribution
      end
      fail "Attached hot water distribution '#{@hot_water_distribution_idref}' not found for dishwasher '#{@id}'."
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.dishwashers.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      begin; water_heating_system; rescue StandardError => e; errors << e.message; end
      begin; hot_water_distribution; rescue StandardError => e; errors << e.message; end
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      dishwasher = XMLHelper.add_element(appliances, 'Dishwasher')
      sys_id = XMLHelper.add_element(dishwasher, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(dishwasher, 'IsSharedAppliance', @is_shared_appliance, :boolean, @is_shared_appliance_isdefaulted) unless @is_shared_appliance.nil?
      if not @water_heating_system_idref.nil?
        attached_water_heater = XMLHelper.add_element(dishwasher, 'AttachedToWaterHeatingSystem')
        XMLHelper.add_attribute(attached_water_heater, 'idref', @water_heating_system_idref)
      elsif not @hot_water_distribution_idref.nil?
        attached_hot_water_dist = XMLHelper.add_element(dishwasher, 'AttachedToHotWaterDistribution')
        XMLHelper.add_attribute(attached_hot_water_dist, 'idref', @hot_water_distribution_idref)
      end
      XMLHelper.add_element(dishwasher, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(dishwasher, 'RatedAnnualkWh', @rated_annual_kwh, :float, @rated_annual_kwh_isdefaulted) unless @rated_annual_kwh.nil?
      XMLHelper.add_element(dishwasher, 'EnergyFactor', @energy_factor, :float) unless @energy_factor.nil?
      XMLHelper.add_element(dishwasher, 'PlaceSettingCapacity', @place_setting_capacity, :integer, @place_setting_capacity_isdefaulted) unless @place_setting_capacity.nil?
      XMLHelper.add_element(dishwasher, 'LabelElectricRate', @label_electric_rate, :float, @label_electric_rate_isdefaulted) unless @label_electric_rate.nil?
      XMLHelper.add_element(dishwasher, 'LabelGasRate', @label_gas_rate, :float, @label_gas_rate_isdefaulted) unless @label_gas_rate.nil?
      XMLHelper.add_element(dishwasher, 'LabelAnnualGasCost', @label_annual_gas_cost, :float, @label_annual_gas_cost_isdefaulted) unless @label_annual_gas_cost.nil?
      XMLHelper.add_element(dishwasher, 'LabelUsage', @label_usage, :float, @label_usage_isdefaulted) unless @label_usage.nil?
      XMLHelper.add_extension(dishwasher, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(dishwasher, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(dishwasher, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(dishwasher, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param dishwasher [Oga::XML::Element] The current Dishwasher XML element
    # @return [nil]
    def from_doc(dishwasher)
      return if dishwasher.nil?

      @id = HPXML::get_id(dishwasher)
      @is_shared_appliance = XMLHelper.get_value(dishwasher, 'IsSharedAppliance', :boolean)
      @water_heating_system_idref = HPXML::get_idref(XMLHelper.get_element(dishwasher, 'AttachedToWaterHeatingSystem'))
      @hot_water_distribution_idref = HPXML::get_idref(XMLHelper.get_element(dishwasher, 'AttachedToHotWaterDistribution'))
      @location = XMLHelper.get_value(dishwasher, 'Location', :string)
      @rated_annual_kwh = XMLHelper.get_value(dishwasher, 'RatedAnnualkWh', :float)
      @energy_factor = XMLHelper.get_value(dishwasher, 'EnergyFactor', :float)
      @place_setting_capacity = XMLHelper.get_value(dishwasher, 'PlaceSettingCapacity', :integer)
      @label_electric_rate = XMLHelper.get_value(dishwasher, 'LabelElectricRate', :float)
      @label_gas_rate = XMLHelper.get_value(dishwasher, 'LabelGasRate', :float)
      @label_annual_gas_cost = XMLHelper.get_value(dishwasher, 'LabelAnnualGasCost', :float)
      @label_usage = XMLHelper.get_value(dishwasher, 'LabelUsage', :float)
      @usage_multiplier = XMLHelper.get_value(dishwasher, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(dishwasher, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(dishwasher, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(dishwasher, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  # Array of HPXML::Refrigerator objects.
  class Refrigerators < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Refrigerator.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/Refrigerator').each do |refrigerator|
        self << Refrigerator.new(@parent_object, refrigerator)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Appliances/Refrigerator.
  class Refrigerator < BaseElement
    ATTRS = [:id,                       # [String] SystemIdentifier/@id
             :sameas_id,                # [String] SystemIdentifier/@sameas
             :location,                 # [String] Location (HPXML::LocationXXX)
             :rated_annual_kwh,         # [Double] RatedAnnualkWh (kWh/yr)
             :primary_indicator,        # [Boolean] PrimaryIndicator
             :usage_multiplier,         # [Double] UsageMultiplier
             :weekday_fractions,        # [String] WeekdayScheduleFractions
             :weekend_fractions,        # [String] WeekendScheduleFractions
             :monthly_multipliers,      # [String] MonthlyScheduleMultipliers
             :constant_coefficients,    # [String] ConstantScheduleCoefficients
             :temperature_coefficients] # [String] TemperatureScheduleCoefficients
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.refrigerators.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      refrigerator = XMLHelper.add_element(appliances, 'Refrigerator')
      sys_id = XMLHelper.add_element(refrigerator, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(refrigerator, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(refrigerator, 'RatedAnnualkWh', @rated_annual_kwh, :float, @rated_annual_kwh_isdefaulted) unless @rated_annual_kwh.nil?
      XMLHelper.add_element(refrigerator, 'PrimaryIndicator', @primary_indicator, :boolean, @primary_indicator_isdefaulted) unless @primary_indicator.nil?
      XMLHelper.add_extension(refrigerator, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(refrigerator, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(refrigerator, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(refrigerator, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
      XMLHelper.add_extension(refrigerator, 'ConstantScheduleCoefficients', @constant_coefficients, :string, @constant_coefficients_isdefaulted) unless @constant_coefficients.nil?
      XMLHelper.add_extension(refrigerator, 'TemperatureScheduleCoefficients', @temperature_coefficients, :string, @temperature_coefficients_isdefaulted) unless @temperature_coefficients.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param refrigerator [Oga::XML::Element] The current Refrigerator XML element
    # @return [nil]
    def from_doc(refrigerator)
      return if refrigerator.nil?

      @id = HPXML::get_id(refrigerator)
      @location = XMLHelper.get_value(refrigerator, 'Location', :string)
      @rated_annual_kwh = XMLHelper.get_value(refrigerator, 'RatedAnnualkWh', :float)
      @primary_indicator = XMLHelper.get_value(refrigerator, 'PrimaryIndicator', :boolean)
      @usage_multiplier = XMLHelper.get_value(refrigerator, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(refrigerator, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(refrigerator, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(refrigerator, 'extension/MonthlyScheduleMultipliers', :string)
      @constant_coefficients = XMLHelper.get_value(refrigerator, 'extension/ConstantScheduleCoefficients', :string)
      @temperature_coefficients = XMLHelper.get_value(refrigerator, 'extension/TemperatureScheduleCoefficients', :string)
    end
  end

  # Array of HPXML::Freezer objects.
  class Freezers < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Freezer.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/Freezer').each do |freezer|
        self << Freezer.new(@parent_object, freezer)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Appliances/Freezer.
  class Freezer < BaseElement
    ATTRS = [:id,                       # [String] SystemIdentifier/@id
             :sameas_id,                # [String] SystemIdentifier/@sameas
             :location,                 # [String] Location (HPXML::LocationXXX)
             :rated_annual_kwh,         # [Double] RatedAnnualkWh (kWh/yr)
             :usage_multiplier,         # [Double] UsageMultiplier
             :weekday_fractions,        # [String] WeekdayScheduleFractions
             :weekend_fractions,        # [String] WeekendScheduleFractions
             :monthly_multipliers,      # [String] MonthlyScheduleMultipliers
             :constant_coefficients,    # [String] ConstantScheduleCoefficients
             :temperature_coefficients] # [String] TemperatureScheduleCoefficients
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.freezers.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      freezer = XMLHelper.add_element(appliances, 'Freezer')
      sys_id = XMLHelper.add_element(freezer, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(freezer, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(freezer, 'RatedAnnualkWh', @rated_annual_kwh, :float, @rated_annual_kwh_isdefaulted) unless @rated_annual_kwh.nil?
      XMLHelper.add_extension(freezer, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(freezer, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(freezer, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(freezer, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
      XMLHelper.add_extension(freezer, 'ConstantScheduleCoefficients', @constant_coefficients, :string, @constant_coefficients_isdefaulted) unless @constant_coefficients.nil?
      XMLHelper.add_extension(freezer, 'TemperatureScheduleCoefficients', @temperature_coefficients, :string, @temperature_coefficients_isdefaulted) unless @temperature_coefficients.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param freezer [Oga::XML::Element] The current Freezer XML element
    # @return [nil]
    def from_doc(freezer)
      return if freezer.nil?

      @id = HPXML::get_id(freezer)
      @location = XMLHelper.get_value(freezer, 'Location', :string)
      @rated_annual_kwh = XMLHelper.get_value(freezer, 'RatedAnnualkWh', :float)
      @usage_multiplier = XMLHelper.get_value(freezer, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(freezer, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(freezer, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(freezer, 'extension/MonthlyScheduleMultipliers', :string)
      @constant_coefficients = XMLHelper.get_value(freezer, 'extension/ConstantScheduleCoefficients', :string)
      @temperature_coefficients = XMLHelper.get_value(freezer, 'extension/TemperatureScheduleCoefficients', :string)
    end
  end

  # Array of HPXML::Dehumidifier objects.
  class Dehumidifiers < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Dehumidifier.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/Dehumidifier').each do |dehumidifier|
        self << Dehumidifier.new(@parent_object, dehumidifier)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Appliances/Dehumidifier.
  class Dehumidifier < BaseElement
    ATTRS = [:id,                       # [String] SystemIdentifier/@id
             :sameas_id,                # [String] SystemIdentifier/@sameas
             :type,                     # [String] Type (HPXML::DehumidifierTypeXXX)
             :location,                 # [String] Location (HPXML::LocationXXX)
             :capacity,                 # [Double] Capacity (pints/day)
             :energy_factor,            # [Double] EnergyFactor (liters/kWh)
             :integrated_energy_factor, # [Double] IntegratedEnergyFactor (liters/kWh)
             :rh_setpoint,              # [Double] DehumidistatSetpoint (frac)
             :fraction_served]          # [Double] FractionDehumidificationLoadServed (frac)
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.dehumidifiers.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      dehumidifier = XMLHelper.add_element(appliances, 'Dehumidifier')
      sys_id = XMLHelper.add_element(dehumidifier, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(dehumidifier, 'Type', @type, :string) unless @type.nil?
      XMLHelper.add_element(dehumidifier, 'Location', @location, :string) unless @location.nil?
      XMLHelper.add_element(dehumidifier, 'Capacity', @capacity, :float) unless @capacity.nil?
      XMLHelper.add_element(dehumidifier, 'EnergyFactor', @energy_factor, :float) unless @energy_factor.nil?
      XMLHelper.add_element(dehumidifier, 'IntegratedEnergyFactor', @integrated_energy_factor, :float) unless @integrated_energy_factor.nil?
      XMLHelper.add_element(dehumidifier, 'DehumidistatSetpoint', @rh_setpoint, :float) unless @rh_setpoint.nil?
      XMLHelper.add_element(dehumidifier, 'FractionDehumidificationLoadServed', @fraction_served, :float) unless @fraction_served.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param dehumidifier [Oga::XML::Element] The current Dehumidifier XML element
    # @return [nil]
    def from_doc(dehumidifier)
      return if dehumidifier.nil?

      @id = HPXML::get_id(dehumidifier)
      @type = XMLHelper.get_value(dehumidifier, 'Type', :string)
      @location = XMLHelper.get_value(dehumidifier, 'Location', :string)
      @capacity = XMLHelper.get_value(dehumidifier, 'Capacity', :float)
      @energy_factor = XMLHelper.get_value(dehumidifier, 'EnergyFactor', :float)
      @integrated_energy_factor = XMLHelper.get_value(dehumidifier, 'IntegratedEnergyFactor', :float)
      @rh_setpoint = XMLHelper.get_value(dehumidifier, 'DehumidistatSetpoint', :float)
      @fraction_served = XMLHelper.get_value(dehumidifier, 'FractionDehumidificationLoadServed', :float)
    end
  end

  # Array of HPXML::CookingRange objects.
  class CookingRanges < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << CookingRange.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/CookingRange').each do |cooking_range|
        self << CookingRange.new(@parent_object, cooking_range)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Appliances/CookingRange.
  class CookingRange < BaseElement
    ATTRS = [:id,                  # [String] SystemIdentifier/@id
             :sameas_id,           # [String] SystemIdentifier/@sameas
             :location,            # [String] Location (HPXML::LocationXXX)
             :fuel_type,           # [String] FuelType (HPXML::FuelTypeXXX)
             :is_induction,        # [Boolean] IsInduction
             :usage_multiplier,    # [Double] UsageMultiplier
             :weekday_fractions,   # [String] WeekdayScheduleFractions
             :weekend_fractions,   # [String] WeekendScheduleFractions
             :monthly_multipliers] # [String] MonthlyScheduleMultipliers
    attr_accessor(*ATTRS)

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def branch_circuits
      return HPXML::branch_circuits(@id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def service_feeders
      return HPXML::service_feeders(@id, @parent_object.electric_panels)
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.cooking_ranges.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      cooking_range = XMLHelper.add_element(appliances, 'CookingRange')
      sys_id = XMLHelper.add_element(cooking_range, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(cooking_range, 'Location', @location, :string, @location_isdefaulted) unless @location.nil?
      XMLHelper.add_element(cooking_range, 'FuelType', @fuel_type, :string) unless @fuel_type.nil?
      XMLHelper.add_element(cooking_range, 'IsInduction', @is_induction, :boolean, @is_induction_isdefaulted) unless @is_induction.nil?
      XMLHelper.add_extension(cooking_range, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(cooking_range, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(cooking_range, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(cooking_range, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param cooking_range [Oga::XML::Element] The current CookingRange XML element
    # @return [nil]
    def from_doc(cooking_range)
      return if cooking_range.nil?

      @id = HPXML::get_id(cooking_range)
      @location = XMLHelper.get_value(cooking_range, 'Location', :string)
      @fuel_type = XMLHelper.get_value(cooking_range, 'FuelType', :string)
      @is_induction = XMLHelper.get_value(cooking_range, 'IsInduction', :boolean)
      @usage_multiplier = XMLHelper.get_value(cooking_range, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(cooking_range, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(cooking_range, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(cooking_range, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  # Array of HPXML::Oven objects.
  class Ovens < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Oven.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Appliances/Oven').each do |oven|
        self << Oven.new(@parent_object, oven)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Appliances/Oven.
  class Oven < BaseElement
    ATTRS = [:id,            # [String] SystemIdentifier/@id
             :sameas_id,     # [String] SystemIdentifier/@sameas
             :is_convection] # [Boolean] IsConvection
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.ovens.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      appliances = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Appliances'])
      oven = XMLHelper.add_element(appliances, 'Oven')
      sys_id = XMLHelper.add_element(oven, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(oven, 'IsConvection', @is_convection, :boolean, @is_convection_isdefaulted) unless @is_convection.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param oven [Oga::XML::Element] The current Oven XML element
    # @return [nil]
    def from_doc(oven)
      return if oven.nil?

      @id = HPXML::get_id(oven)
      @is_convection = XMLHelper.get_value(oven, 'IsConvection', :boolean)
    end
  end

  # Array of HPXML::LightingGroup objects.
  class LightingGroups < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << LightingGroup.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Lighting/LightingGroup').each do |lighting_group|
        self << LightingGroup.new(@parent_object, lighting_group)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Lighting/LightingGroup.
  class LightingGroup < BaseElement
    ATTRS = [:id,                            # [String] SystemIdentifier/@id
             :sameas_id,                     # [String] SystemIdentifier/@sameas
             :location,                      # [String] Location (HPXML::LocationXXX)
             :fraction_of_units_in_location, # [Double] FractionofUnitsInLocation (frac)
             :lighting_type,                 # [String] LightingType/* (HPXML::LightingTypeXXX)
             :kwh_per_year]                  # [Double] Load[Units="kWh/year"]/Value (kWh/yr)
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.lighting_groups.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      lighting = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Lighting'])
      lighting_group = XMLHelper.add_element(lighting, 'LightingGroup')
      sys_id = XMLHelper.add_element(lighting_group, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(lighting_group, 'Location', @location, :string) unless @location.nil?
      XMLHelper.add_element(lighting_group, 'FractionofUnitsInLocation', @fraction_of_units_in_location, :float) unless @fraction_of_units_in_location.nil?
      if not @lighting_type.nil?
        lighting_type = XMLHelper.add_element(lighting_group, 'LightingType')
        XMLHelper.add_element(lighting_type, @lighting_type)
      end
      if not @kwh_per_year.nil?
        lighting_load = XMLHelper.add_element(lighting_group, 'Load')
        XMLHelper.add_element(lighting_load, 'Units', UnitsKwhPerYear, :string)
        XMLHelper.add_element(lighting_load, 'Value', @kwh_per_year, :float, @kwh_per_year_isdefaulted)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param lighting_group [Oga::XML::Element] The current LightingGroup XML element
    # @return [nil]
    def from_doc(lighting_group)
      return if lighting_group.nil?

      @id = HPXML::get_id(lighting_group)
      @location = XMLHelper.get_value(lighting_group, 'Location', :string)
      @fraction_of_units_in_location = XMLHelper.get_value(lighting_group, 'FractionofUnitsInLocation', :float)
      @lighting_type = XMLHelper.get_child_name(lighting_group, 'LightingType')
      @kwh_per_year = XMLHelper.get_value(lighting_group, "Load[Units='#{UnitsKwhPerYear}']/Value", :float)
    end
  end

  # Array of HPXML::CeilingFan objects.
  class CeilingFans < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << CeilingFan.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Lighting/CeilingFan').each do |ceiling_fan|
        self << CeilingFan.new(@parent_object, ceiling_fan)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Lighting/CeilingFan.
  class CeilingFan < BaseElement
    ATTRS = [:id,                  # [String] SystemIdentifier/@id
             :sameas_id,           # [String] SystemIdentifier/@sameas
             :efficiency,          # [Double] Airflow[FanSpeed="medium"]/Efficiency (cfm/W)
             :count,               # [Integer] Count
             :label_energy_use,    # [Double] LabelEnergyUse (W)
             :weekday_fractions,   # [String] WeekdayScheduleFractions
             :weekend_fractions,   # [String] WeekendScheduleFractions
             :monthly_multipliers] # [String] MonthlyScheduleMultipliers
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.ceiling_fans.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      lighting = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Lighting'])
      ceiling_fan = XMLHelper.add_element(lighting, 'CeilingFan')
      sys_id = XMLHelper.add_element(ceiling_fan, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      if not @efficiency.nil?
        airflow = XMLHelper.add_element(ceiling_fan, 'Airflow')
        XMLHelper.add_element(airflow, 'FanSpeed', 'medium', :string)
        XMLHelper.add_element(airflow, 'Efficiency', @efficiency, :float, @efficiency_isdefaulted)
      end
      XMLHelper.add_element(ceiling_fan, 'Count', @count, :integer, @count_isdefaulted) unless @count.nil?
      XMLHelper.add_element(ceiling_fan, 'LabelEnergyUse', @label_energy_use, :float, @label_energy_use_isdefaulted) unless @label_energy_use.nil?
      XMLHelper.add_extension(ceiling_fan, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(ceiling_fan, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(ceiling_fan, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param ceiling_fan [Oga::XML::Element] The current CeilingFan XML element
    # @return [nil]
    def from_doc(ceiling_fan)
      @id = HPXML::get_id(ceiling_fan)
      @efficiency = XMLHelper.get_value(ceiling_fan, "Airflow[FanSpeed='medium']/Efficiency", :float)
      @label_energy_use = XMLHelper.get_value(ceiling_fan, 'LabelEnergyUse', :float)
      @count = XMLHelper.get_value(ceiling_fan, 'Count', :integer)
      @weekday_fractions = XMLHelper.get_value(ceiling_fan, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(ceiling_fan, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(ceiling_fan, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Lighting/extension.
  class Lighting < BaseElement
    ATTRS = [:interior_usage_multiplier,    # [Double] InteriorUsageMultiplier
             :garage_usage_multiplier,      # [Double] GarageUsageMultiplier
             :exterior_usage_multiplier,    # [Double] ExteriorUsageMultiplier
             :interior_weekday_fractions,   # [String] InteriorWeekdayScheduleFractions
             :interior_weekend_fractions,   # [String] InteriorWeekendScheduleFractions
             :interior_monthly_multipliers, # [String] InteriorMonthlyScheduleMultipliers
             :garage_weekday_fractions,     # [String] GarageWeekdayScheduleFractions
             :garage_weekend_fractions,     # [String] GarageWeekendScheduleFractions
             :garage_monthly_multipliers,   # [String] GarageMonthlyScheduleMultipliers
             :exterior_weekday_fractions,   # [String] ExteriorWeekdayScheduleFractions
             :exterior_weekend_fractions,   # [String] ExteriorWeekendScheduleFractions
             :exterior_monthly_multipliers, # [String] ExteriorMonthlyScheduleMultipliers
             :holiday_exists,               # [Boolean] ExteriorHolidayLighting
             :holiday_kwh_per_day,          # [Double] ExteriorHolidayLighting/Load[Units="kWh/day"]/Value (kWh/day)
             :holiday_period_begin_month,   # [Integer] ExteriorHolidayLighting/PeriodBeginMonth
             :holiday_period_begin_day,     # [Integer] ExteriorHolidayLighting/PeriodBeginDayOfMonth
             :holiday_period_end_month,     # [Integer] ExteriorHolidayLighting/PeriodEndMonth
             :holiday_period_end_day,       # [Integer] ExteriorHolidayLighting/PeriodEndDayOfMonth
             :holiday_weekday_fractions,    # [String] ExteriorHolidayLighting/WeekdayScheduleFractions
             :holiday_weekend_fractions]    # [String] ExteriorHolidayLighting/WeekendScheduleFractions
    attr_accessor(*ATTRS)

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      errors += HPXML::check_dates('Exterior Holiday Lighting', @holiday_period_begin_month, @holiday_period_begin_day, @holiday_period_end_month, @holiday_period_end_day)
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      lighting = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Lighting'])
      XMLHelper.add_extension(lighting, 'InteriorUsageMultiplier', @interior_usage_multiplier, :float, @interior_usage_multiplier_isdefaulted) unless @interior_usage_multiplier.nil?
      XMLHelper.add_extension(lighting, 'GarageUsageMultiplier', @garage_usage_multiplier, :float, @garage_usage_multiplier_isdefaulted) unless @garage_usage_multiplier.nil?
      XMLHelper.add_extension(lighting, 'ExteriorUsageMultiplier', @exterior_usage_multiplier, :float, @exterior_usage_multiplier_isdefaulted) unless @exterior_usage_multiplier.nil?
      XMLHelper.add_extension(lighting, 'InteriorWeekdayScheduleFractions', @interior_weekday_fractions, :string, @interior_weekday_fractions_isdefaulted) unless @interior_weekday_fractions.nil?
      XMLHelper.add_extension(lighting, 'InteriorWeekendScheduleFractions', @interior_weekend_fractions, :string, @interior_weekend_fractions_isdefaulted) unless @interior_weekend_fractions.nil?
      XMLHelper.add_extension(lighting, 'InteriorMonthlyScheduleMultipliers', @interior_monthly_multipliers, :string, @interior_monthly_multipliers_isdefaulted) unless @interior_monthly_multipliers.nil?
      XMLHelper.add_extension(lighting, 'GarageWeekdayScheduleFractions', @garage_weekday_fractions, :string, @garage_weekday_fractions_isdefaulted) unless @garage_weekday_fractions.nil?
      XMLHelper.add_extension(lighting, 'GarageWeekendScheduleFractions', @garage_weekend_fractions, :string, @garage_weekend_fractions_isdefaulted) unless @garage_weekend_fractions.nil?
      XMLHelper.add_extension(lighting, 'GarageMonthlyScheduleMultipliers', @garage_monthly_multipliers, :string, @garage_monthly_multipliers_isdefaulted) unless @garage_monthly_multipliers.nil?
      XMLHelper.add_extension(lighting, 'ExteriorWeekdayScheduleFractions', @exterior_weekday_fractions, :string, @exterior_weekday_fractions_isdefaulted) unless @exterior_weekday_fractions.nil?
      XMLHelper.add_extension(lighting, 'ExteriorWeekendScheduleFractions', @exterior_weekend_fractions, :string, @exterior_weekend_fractions_isdefaulted) unless @exterior_weekend_fractions.nil?
      XMLHelper.add_extension(lighting, 'ExteriorMonthlyScheduleMultipliers', @exterior_monthly_multipliers, :string, @exterior_monthly_multipliers_isdefaulted) unless @exterior_monthly_multipliers.nil?
      if @holiday_exists
        exterior_holiday_lighting = XMLHelper.create_elements_as_needed(lighting, ['extension', 'ExteriorHolidayLighting'])
        if not @holiday_kwh_per_day.nil?
          holiday_lighting_load = XMLHelper.add_element(exterior_holiday_lighting, 'Load')
          XMLHelper.add_element(holiday_lighting_load, 'Units', UnitsKwhPerDay, :string)
          XMLHelper.add_element(holiday_lighting_load, 'Value', @holiday_kwh_per_day, :float, @holiday_kwh_per_day_isdefaulted)
        end
        XMLHelper.add_element(exterior_holiday_lighting, 'PeriodBeginMonth', @holiday_period_begin_month, :integer, @holiday_period_begin_month_isdefaulted) unless @holiday_period_begin_month.nil?
        XMLHelper.add_element(exterior_holiday_lighting, 'PeriodBeginDayOfMonth', @holiday_period_begin_day, :integer, @holiday_period_begin_day_isdefaulted) unless @holiday_period_begin_day.nil?
        XMLHelper.add_element(exterior_holiday_lighting, 'PeriodEndMonth', @holiday_period_end_month, :integer, @holiday_period_end_month_isdefaulted) unless @holiday_period_end_month.nil?
        XMLHelper.add_element(exterior_holiday_lighting, 'PeriodEndDayOfMonth', @holiday_period_end_day, :integer, @holiday_period_end_day_isdefaulted) unless @holiday_period_end_day.nil?
        XMLHelper.add_element(exterior_holiday_lighting, 'WeekdayScheduleFractions', @holiday_weekday_fractions, :string, @holiday_weekday_fractions_isdefaulted) unless @holiday_weekday_fractions.nil?
        XMLHelper.add_element(exterior_holiday_lighting, 'WeekendScheduleFractions', @holiday_weekend_fractions, :string, @holiday_weekend_fractions_isdefaulted) unless @holiday_weekend_fractions.nil?
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      lighting = XMLHelper.get_element(building, 'BuildingDetails/Lighting')
      return if lighting.nil?

      @interior_usage_multiplier = XMLHelper.get_value(lighting, 'extension/InteriorUsageMultiplier', :float)
      @garage_usage_multiplier = XMLHelper.get_value(lighting, 'extension/GarageUsageMultiplier', :float)
      @exterior_usage_multiplier = XMLHelper.get_value(lighting, 'extension/ExteriorUsageMultiplier', :float)
      @interior_weekday_fractions = XMLHelper.get_value(lighting, 'extension/InteriorWeekdayScheduleFractions', :string)
      @interior_weekend_fractions = XMLHelper.get_value(lighting, 'extension/InteriorWeekendScheduleFractions', :string)
      @interior_monthly_multipliers = XMLHelper.get_value(lighting, 'extension/InteriorMonthlyScheduleMultipliers', :string)
      @garage_weekday_fractions = XMLHelper.get_value(lighting, 'extension/GarageWeekdayScheduleFractions', :string)
      @garage_weekend_fractions = XMLHelper.get_value(lighting, 'extension/GarageWeekendScheduleFractions', :string)
      @garage_monthly_multipliers = XMLHelper.get_value(lighting, 'extension/GarageMonthlyScheduleMultipliers', :string)
      @exterior_weekday_fractions = XMLHelper.get_value(lighting, 'extension/ExteriorWeekdayScheduleFractions', :string)
      @exterior_weekend_fractions = XMLHelper.get_value(lighting, 'extension/ExteriorWeekendScheduleFractions', :string)
      @exterior_monthly_multipliers = XMLHelper.get_value(lighting, 'extension/ExteriorMonthlyScheduleMultipliers', :string)
      if not XMLHelper.get_element(building, 'BuildingDetails/Lighting/extension/ExteriorHolidayLighting').nil?
        @holiday_exists = true
        @holiday_kwh_per_day = XMLHelper.get_value(lighting, "extension/ExteriorHolidayLighting/Load[Units='#{UnitsKwhPerDay}']/Value", :float)
        @holiday_period_begin_month = XMLHelper.get_value(lighting, 'extension/ExteriorHolidayLighting/PeriodBeginMonth', :integer)
        @holiday_period_begin_day = XMLHelper.get_value(lighting, 'extension/ExteriorHolidayLighting/PeriodBeginDayOfMonth', :integer)
        @holiday_period_end_month = XMLHelper.get_value(lighting, 'extension/ExteriorHolidayLighting/PeriodEndMonth', :integer)
        @holiday_period_end_day = XMLHelper.get_value(lighting, 'extension/ExteriorHolidayLighting/PeriodEndDayOfMonth', :integer)
        @holiday_weekday_fractions = XMLHelper.get_value(lighting, 'extension/ExteriorHolidayLighting/WeekdayScheduleFractions', :string)
        @holiday_weekend_fractions = XMLHelper.get_value(lighting, 'extension/ExteriorHolidayLighting/WeekendScheduleFractions', :string)
      else
        @holiday_exists = false
      end
    end
  end

  # Array of HPXML::Pool objects.
  class Pools < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << Pool.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Pools/Pool').each do |pool|
        self << Pool.new(@parent_object, pool)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Pools/Pool.
  class Pool < BaseElement
    ATTRS = [:id,                         # [String] SystemIdentifier/@id
             :sameas_id,                  # [String] SystemIdentifier/@sameas
             :type,                       # [String] Type
             :pump_id,                    # [String] Pumps/Pump/SystemIdentifier/@id
             :pump_type,                  # [String] Pumps/Pump/Type
             :pump_kwh_per_year,          # [Double] Pumps/Pump/Load[Units="kWh/year"]/Value (kWh/yr)
             :pump_usage_multiplier,      # [Double] Pumps/Pump/UsageMultiplier
             :pump_weekday_fractions,     # [String] Pumps/Pump/WeekdayScheduleFractions
             :pump_weekend_fractions,     # [String] Pumps/Pump/WeekendScheduleFractions
             :pump_monthly_multipliers,   # [String] Pumps/Pump/MonthlyScheduleMultipliers
             :heater_id,                  # [String] Heater/SystemIdentifier/@id
             :heater_type,                # [String] Heater/Type (HPXML::HeaterTypeXXX)
             :heater_load_units,          # [String] Heater/Load/Units (HPXML::UnitsXXX)
             :heater_load_value,          # [Double] Heater/Load/Value
             :heater_usage_multiplier,    # [Double] Heater/UsageMultiplier
             :heater_weekday_fractions,   # [String] Heater/WeekdayScheduleFractions
             :heater_weekend_fractions,   # [String] Heater/WeekendScheduleFractions
             :heater_monthly_multipliers] # [String] Heater/MonthlyScheduleMultipliers
    attr_accessor(*ATTRS)

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def pump_branch_circuits
      return HPXML::branch_circuits(@pump_id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def pump_service_feeders
      return HPXML::service_feeders(@pump_id, @parent_object.electric_panels)
    end

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def heater_branch_circuits
      return HPXML::branch_circuits(@heater_id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def heater_service_feeders
      return HPXML::service_feeders(@heater_id, @parent_object.electric_panels)
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.pools.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      pools = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Pools'])
      pool = XMLHelper.add_element(pools, 'Pool')
      sys_id = XMLHelper.add_element(pool, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(pool, 'Type', @type, :string) unless @type.nil?
      if @type != HPXML::TypeNotPresent
        pumps = XMLHelper.add_element(pool, 'Pumps')
        pool_pump = XMLHelper.add_element(pumps, 'Pump')
        sys_id = XMLHelper.add_element(pool_pump, 'SystemIdentifier')
        if not @pump_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @pump_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Pump')
        end
        XMLHelper.add_element(pool_pump, 'Type', @pump_type, :string)
        if @pump_type != HPXML::TypeNotPresent
          if not @pump_kwh_per_year.nil?
            load = XMLHelper.add_element(pool_pump, 'Load')
            XMLHelper.add_element(load, 'Units', UnitsKwhPerYear, :string)
            XMLHelper.add_element(load, 'Value', @pump_kwh_per_year, :float, @pump_kwh_per_year_isdefaulted)
          end
          XMLHelper.add_extension(pool_pump, 'UsageMultiplier', @pump_usage_multiplier, :float, @pump_usage_multiplier_isdefaulted) unless @pump_usage_multiplier.nil?
          XMLHelper.add_extension(pool_pump, 'WeekdayScheduleFractions', @pump_weekday_fractions, :string, @pump_weekday_fractions_isdefaulted) unless @pump_weekday_fractions.nil?
          XMLHelper.add_extension(pool_pump, 'WeekendScheduleFractions', @pump_weekend_fractions, :string, @pump_weekend_fractions_isdefaulted) unless @pump_weekend_fractions.nil?
          XMLHelper.add_extension(pool_pump, 'MonthlyScheduleMultipliers', @pump_monthly_multipliers, :string, @pump_monthly_multipliers_isdefaulted) unless @pump_monthly_multipliers.nil?
        end
        heater = XMLHelper.add_element(pool, 'Heater')
        sys_id = XMLHelper.add_element(heater, 'SystemIdentifier')
        if not @heater_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @heater_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Heater')
        end
        XMLHelper.add_element(heater, 'Type', @heater_type, :string)
        if @heater_type != HPXML::TypeNotPresent
          if (not @heater_load_units.nil?) && (not @heater_load_value.nil?)
            load = XMLHelper.add_element(heater, 'Load')
            XMLHelper.add_element(load, 'Units', @heater_load_units, :string)
            XMLHelper.add_element(load, 'Value', @heater_load_value, :float, @heater_load_value_isdefaulted)
          end
          XMLHelper.add_extension(heater, 'UsageMultiplier', @heater_usage_multiplier, :float, @heater_usage_multiplier_isdefaulted) unless @heater_usage_multiplier.nil?
          XMLHelper.add_extension(heater, 'WeekdayScheduleFractions', @heater_weekday_fractions, :string, @heater_weekday_fractions_isdefaulted) unless @heater_weekday_fractions.nil?
          XMLHelper.add_extension(heater, 'WeekendScheduleFractions', @heater_weekend_fractions, :string, @heater_weekend_fractions_isdefaulted) unless @heater_weekend_fractions.nil?
          XMLHelper.add_extension(heater, 'MonthlyScheduleMultipliers', @heater_monthly_multipliers, :string, @heater_monthly_multipliers_isdefaulted) unless @heater_monthly_multipliers.nil?
        end
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param pool [Oga::XML::Element] The current Pool XML element
    # @return [nil]
    def from_doc(pool)
      @id = HPXML::get_id(pool)
      @type = XMLHelper.get_value(pool, 'Type', :string)
      pool_pump = XMLHelper.get_element(pool, 'Pumps/Pump')
      if not pool_pump.nil?
        @pump_id = HPXML::get_id(pool_pump)
        @pump_type = XMLHelper.get_value(pool_pump, 'Type', :string)
        @pump_kwh_per_year = XMLHelper.get_value(pool_pump, "Load[Units='#{UnitsKwhPerYear}']/Value", :float)
        @pump_usage_multiplier = XMLHelper.get_value(pool_pump, 'extension/UsageMultiplier', :float)
        @pump_weekday_fractions = XMLHelper.get_value(pool_pump, 'extension/WeekdayScheduleFractions', :string)
        @pump_weekend_fractions = XMLHelper.get_value(pool_pump, 'extension/WeekendScheduleFractions', :string)
        @pump_monthly_multipliers = XMLHelper.get_value(pool_pump, 'extension/MonthlyScheduleMultipliers', :string)
      end
      heater = XMLHelper.get_element(pool, 'Heater')
      if not heater.nil?
        @heater_id = HPXML::get_id(heater)
        @heater_type = XMLHelper.get_value(heater, 'Type', :string)
        @heater_load_units = XMLHelper.get_value(heater, 'Load/Units', :string)
        @heater_load_value = XMLHelper.get_value(heater, 'Load/Value', :float)
        @heater_usage_multiplier = XMLHelper.get_value(heater, 'extension/UsageMultiplier', :float)
        @heater_weekday_fractions = XMLHelper.get_value(heater, 'extension/WeekdayScheduleFractions', :string)
        @heater_weekend_fractions = XMLHelper.get_value(heater, 'extension/WeekendScheduleFractions', :string)
        @heater_monthly_multipliers = XMLHelper.get_value(heater, 'extension/MonthlyScheduleMultipliers', :string)
      end
    end
  end

  # Array of HPXML::PermanentSpa objects.
  class PermanentSpas < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << PermanentSpa.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Spas/PermanentSpa').each do |spa|
        self << PermanentSpa.new(@parent_object, spa)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Spas/PermanentSpa.
  class PermanentSpa < BaseElement
    ATTRS = [:id,                         # [String] SystemIdentifier/@id
             :sameas_id,                  # [String] SystemIdentifier/@sameas
             :type,                       # [String] Type
             :pump_id,                    # [String] Pumps/Pump/SystemIdentifier/@id
             :pump_type,                  # [String] Pumps/Pump/Type
             :pump_kwh_per_year,          # [Double] Pumps/Pump/Load[Units="kWh/year"]/Value (kWh/yr)
             :pump_usage_multiplier,      # [Double] Pumps/Pump/UsageMultiplier
             :pump_weekday_fractions,     # [String] Pumps/Pump/WeekdayScheduleFractions
             :pump_weekend_fractions,     # [String] Pumps/Pump/WeekendScheduleFractions
             :pump_monthly_multipliers,   # [String] Pumps/Pump/MonthlyScheduleMultipliers
             :heater_id,                  # [String] Heater/SystemIdentifier/@id
             :heater_type,                # [String] Heater/Type (HPXML::HeaterTypeXXX)
             :heater_load_units,          # [String] Heater/Load/Units (HPXML::UnitsXXX)
             :heater_load_value,          # [Double] Heater/Load/Value
             :heater_usage_multiplier,    # [Double] Heater/UsageMultiplier
             :heater_weekday_fractions,   # [String] Heater/WeekdayScheduleFractions
             :heater_weekend_fractions,   # [String] Heater/WeekendScheduleFractions
             :heater_monthly_multipliers] # [String] Heater/MonthlyScheduleMultipliers
    attr_accessor(*ATTRS)

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def pump_branch_circuits
      return HPXML::branch_circuits(@pump_id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def pump_service_feeders
      return HPXML::service_feeders(@pump_id, @parent_object.electric_panels)
    end

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def heater_branch_circuits
      return HPXML::branch_circuits(@heater_id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def heater_service_feeders
      return HPXML::service_feeders(@heater_id, @parent_object.electric_panels)
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.permanent_spas.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      spas = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Spas'])
      spa = XMLHelper.add_element(spas, 'PermanentSpa')
      sys_id = XMLHelper.add_element(spa, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(spa, 'Type', @type, :string) unless @type.nil?
      if @type != HPXML::TypeNotPresent
        pumps = XMLHelper.add_element(spa, 'Pumps')
        spa_pump = XMLHelper.add_element(pumps, 'Pump')
        sys_id = XMLHelper.add_element(spa_pump, 'SystemIdentifier')
        if not @pump_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @pump_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Pump')
        end
        XMLHelper.add_element(spa_pump, 'Type', @pump_type, :string)
        if @pump_type != HPXML::TypeNotPresent
          if not @pump_kwh_per_year.nil?
            load = XMLHelper.add_element(spa_pump, 'Load')
            XMLHelper.add_element(load, 'Units', UnitsKwhPerYear, :string)
            XMLHelper.add_element(load, 'Value', @pump_kwh_per_year, :float, @pump_kwh_per_year_isdefaulted)
          end
          XMLHelper.add_extension(spa_pump, 'UsageMultiplier', @pump_usage_multiplier, :float, @pump_usage_multiplier_isdefaulted) unless @pump_usage_multiplier.nil?
          XMLHelper.add_extension(spa_pump, 'WeekdayScheduleFractions', @pump_weekday_fractions, :string, @pump_weekday_fractions_isdefaulted) unless @pump_weekday_fractions.nil?
          XMLHelper.add_extension(spa_pump, 'WeekendScheduleFractions', @pump_weekend_fractions, :string, @pump_weekend_fractions_isdefaulted) unless @pump_weekend_fractions.nil?
          XMLHelper.add_extension(spa_pump, 'MonthlyScheduleMultipliers', @pump_monthly_multipliers, :string, @pump_monthly_multipliers_isdefaulted) unless @pump_monthly_multipliers.nil?
        end
        heater = XMLHelper.add_element(spa, 'Heater')
        sys_id = XMLHelper.add_element(heater, 'SystemIdentifier')
        if not @heater_id.nil?
          XMLHelper.add_attribute(sys_id, 'id', @heater_id)
        else
          XMLHelper.add_attribute(sys_id, 'id', @id + 'Heater')
        end
        XMLHelper.add_element(heater, 'Type', @heater_type, :string)
        if @heater_type != HPXML::TypeNotPresent
          if (not @heater_load_units.nil?) && (not @heater_load_value.nil?)
            load = XMLHelper.add_element(heater, 'Load')
            XMLHelper.add_element(load, 'Units', @heater_load_units, :string)
            XMLHelper.add_element(load, 'Value', @heater_load_value, :float, @heater_load_value_isdefaulted)
          end
          XMLHelper.add_extension(heater, 'UsageMultiplier', @heater_usage_multiplier, :float, @heater_usage_multiplier_isdefaulted) unless @heater_usage_multiplier.nil?
          XMLHelper.add_extension(heater, 'WeekdayScheduleFractions', @heater_weekday_fractions, :string, @heater_weekday_fractions_isdefaulted) unless @heater_weekday_fractions.nil?
          XMLHelper.add_extension(heater, 'WeekendScheduleFractions', @heater_weekend_fractions, :string, @heater_weekend_fractions_isdefaulted) unless @heater_weekend_fractions.nil?
          XMLHelper.add_extension(heater, 'MonthlyScheduleMultipliers', @heater_monthly_multipliers, :string, @heater_monthly_multipliers_isdefaulted) unless @heater_monthly_multipliers.nil?
        end
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param spa [Oga::XML::Element] The current Spa XML element
    # @return [nil]
    def from_doc(spa)
      @id = HPXML::get_id(spa)
      @type = XMLHelper.get_value(spa, 'Type', :string)
      spa_pump = XMLHelper.get_element(spa, 'Pumps/Pump')
      if not spa_pump.nil?
        @pump_id = HPXML::get_id(spa_pump)
        @pump_type = XMLHelper.get_value(spa_pump, 'Type', :string)
        @pump_kwh_per_year = XMLHelper.get_value(spa_pump, "Load[Units='#{UnitsKwhPerYear}']/Value", :float)
        @pump_usage_multiplier = XMLHelper.get_value(spa_pump, 'extension/UsageMultiplier', :float)
        @pump_weekday_fractions = XMLHelper.get_value(spa_pump, 'extension/WeekdayScheduleFractions', :string)
        @pump_weekend_fractions = XMLHelper.get_value(spa_pump, 'extension/WeekendScheduleFractions', :string)
        @pump_monthly_multipliers = XMLHelper.get_value(spa_pump, 'extension/MonthlyScheduleMultipliers', :string)
      end
      heater = XMLHelper.get_element(spa, 'Heater')
      if not heater.nil?
        @heater_id = HPXML::get_id(heater)
        @heater_type = XMLHelper.get_value(heater, 'Type', :string)
        @heater_load_units = XMLHelper.get_value(heater, 'Load/Units', :string)
        @heater_load_value = XMLHelper.get_value(heater, 'Load/Value', :float)
        @heater_usage_multiplier = XMLHelper.get_value(heater, 'extension/UsageMultiplier', :float)
        @heater_weekday_fractions = XMLHelper.get_value(heater, 'extension/WeekdayScheduleFractions', :string)
        @heater_weekend_fractions = XMLHelper.get_value(heater, 'extension/WeekendScheduleFractions', :string)
        @heater_monthly_multipliers = XMLHelper.get_value(heater, 'extension/MonthlyScheduleMultipliers', :string)
      end
    end
  end

  # Array of HPXML::PortableSpa objects.
  class PortableSpas < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << PortableSpa.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/Spas/PortableSpa').each do |spa|
        self << PortableSpa.new(@parent_object, spa)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Spas/PortableSpa.
  class PortableSpa < BaseElement
    ATTRS = [:id,        # [String] SystemIdentifier/@id
             :sameas_id] # [String] SystemIdentifier/@sameas
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.portable_spas.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      spas = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'Spas'])
      spa = XMLHelper.add_element(spas, 'PortableSpa')
      sys_id = XMLHelper.add_element(spa, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param spa [Oga::XML::Element] The current Spa XML element
    # @return [nil]
    def from_doc(spa)
      @id = HPXML::get_id(spa)
    end
  end

  # Array of HPXML::PlugLoad objects.
  class PlugLoads < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << PlugLoad.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/MiscLoads/PlugLoad').each do |plug_load|
        self << PlugLoad.new(@parent_object, plug_load)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/MiscLoads/PlugLoad.
  class PlugLoad < BaseElement
    ATTRS = [:id,                  # [String] SystemIdentifier/@id
             :sameas_id,           # [String] SystemIdentifier/@sameas
             :plug_load_type,      # [String] PlugLoadType (HPXML::PlugLoadTypeXXX)
             :kwh_per_year,        # [Double] Load[Units="kWh/year"]/Value (kWh/yr)
             :frac_sensible,       # [Double] FracSensible (frac)
             :frac_latent,         # [Double] FracLatent (frac)
             :usage_multiplier,    # [Double] UsageMultiplier
             :weekday_fractions,   # [String] WeekdayScheduleFractions
             :weekend_fractions,   # [String] WeekendScheduleFractions
             :monthly_multipliers] # [String] MonthlyScheduleMultipliers
    attr_accessor(*ATTRS)

    # Returns any branch circuits that the component may be attached to.
    #
    # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
    def branch_circuits
      return HPXML::branch_circuits(@id, @parent_object.electric_panels)
    end

    # Returns any service feeders that the component may be attached to.
    #
    # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
    def service_feeders
      return HPXML::service_feeders(@id, @parent_object.electric_panels)
    end

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.plug_loads.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      misc_loads = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'MiscLoads'])
      plug_load = XMLHelper.add_element(misc_loads, 'PlugLoad')
      sys_id = XMLHelper.add_element(plug_load, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(plug_load, 'PlugLoadType', @plug_load_type, :string) unless @plug_load_type.nil?
      if not @kwh_per_year.nil?
        load = XMLHelper.add_element(plug_load, 'Load')
        XMLHelper.add_element(load, 'Units', UnitsKwhPerYear, :string)
        XMLHelper.add_element(load, 'Value', @kwh_per_year, :float, @kwh_per_year_isdefaulted)
      end
      XMLHelper.add_extension(plug_load, 'FracSensible', @frac_sensible, :float, @frac_sensible_isdefaulted) unless @frac_sensible.nil?
      XMLHelper.add_extension(plug_load, 'FracLatent', @frac_latent, :float, @frac_latent_isdefaulted) unless @frac_latent.nil?
      XMLHelper.add_extension(plug_load, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(plug_load, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(plug_load, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(plug_load, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param plug_load [Oga::XML::Element] The current PlugLoad XML element
    # @return [nil]
    def from_doc(plug_load)
      @id = HPXML::get_id(plug_load)
      @plug_load_type = XMLHelper.get_value(plug_load, 'PlugLoadType', :string)
      @kwh_per_year = XMLHelper.get_value(plug_load, "Load[Units='#{UnitsKwhPerYear}']/Value", :float)
      @frac_sensible = XMLHelper.get_value(plug_load, 'extension/FracSensible', :float)
      @frac_latent = XMLHelper.get_value(plug_load, 'extension/FracLatent', :float)
      @usage_multiplier = XMLHelper.get_value(plug_load, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(plug_load, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(plug_load, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(plug_load, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  # Array of HPXML::FuelLoad objects.
  class FuelLoads < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << FuelLoad.new(@parent_object, **kwargs)
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def from_doc(building)
      return if building.nil?

      XMLHelper.get_elements(building, 'BuildingDetails/MiscLoads/FuelLoad').each do |fuel_load|
        self << FuelLoad.new(@parent_object, fuel_load)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/MiscLoads/FuelLoad.
  class FuelLoad < BaseElement
    ATTRS = [:id,                  # [String] SystemIdentifier/@id
             :sameas_id,           # [String] SystemIdentifier/@sameas
             :fuel_load_type,      # [String] FuelLoadType (HPXML::FuelLoadTypeXXX)
             :therm_per_year,      # [Double] Load[Units="therm/year"]/Value (therm/yr)
             :fuel_type,           # [String] FuelType (HPXML::FuelTypeXXX)
             :frac_sensible,       # [Double] FracSensible (frac)
             :frac_latent,         # [Double] FracLatent (frac)
             :usage_multiplier,    # [Double] UsageMultiplier
             :weekday_fractions,   # [String] WeekdayScheduleFractions
             :weekend_fractions,   # [String] WeekendScheduleFractions
             :monthly_multipliers] # [String] MonthlyScheduleMultipliers
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      @parent_object.fuel_loads.delete(self)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param building [Oga::XML::Element] The current Building XML element
    # @return [nil]
    def to_doc(building)
      return if nil?

      misc_loads = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'MiscLoads'])
      fuel_load = XMLHelper.add_element(misc_loads, 'FuelLoad')
      sys_id = XMLHelper.add_element(fuel_load, 'SystemIdentifier')
      XMLHelper.add_attribute(sys_id, 'id', @id)
      XMLHelper.add_attribute(sys_id, 'sameas', @sameas_id) unless @sameas_id.nil?
      XMLHelper.add_element(fuel_load, 'FuelLoadType', @fuel_load_type, :string) unless @fuel_load_type.nil?
      if not @therm_per_year.nil?
        load = XMLHelper.add_element(fuel_load, 'Load')
        XMLHelper.add_element(load, 'Units', UnitsThermPerYear, :string)
        XMLHelper.add_element(load, 'Value', @therm_per_year, :float, @therm_per_year_isdefaulted)
      end
      XMLHelper.add_element(fuel_load, 'FuelType', @fuel_type, :string) unless @fuel_type.nil?
      XMLHelper.add_extension(fuel_load, 'FracSensible', @frac_sensible, :float, @frac_sensible_isdefaulted) unless @frac_sensible.nil?
      XMLHelper.add_extension(fuel_load, 'FracLatent', @frac_latent, :float, @frac_latent_isdefaulted) unless @frac_latent.nil?
      XMLHelper.add_extension(fuel_load, 'UsageMultiplier', @usage_multiplier, :float, @usage_multiplier_isdefaulted) unless @usage_multiplier.nil?
      XMLHelper.add_extension(fuel_load, 'WeekdayScheduleFractions', @weekday_fractions, :string, @weekday_fractions_isdefaulted) unless @weekday_fractions.nil?
      XMLHelper.add_extension(fuel_load, 'WeekendScheduleFractions', @weekend_fractions, :string, @weekend_fractions_isdefaulted) unless @weekend_fractions.nil?
      XMLHelper.add_extension(fuel_load, 'MonthlyScheduleMultipliers', @monthly_multipliers, :string, @monthly_multipliers_isdefaulted) unless @monthly_multipliers.nil?
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param fuel_load [Oga::XML::Element] The current FuelLoad XML element
    # @return [nil]
    def from_doc(fuel_load)
      @id = HPXML::get_id(fuel_load)
      @fuel_load_type = XMLHelper.get_value(fuel_load, 'FuelLoadType', :string)
      @therm_per_year = XMLHelper.get_value(fuel_load, "Load[Units='#{UnitsThermPerYear}']/Value", :float)
      @fuel_type = XMLHelper.get_value(fuel_load, 'FuelType', :string)
      @frac_sensible = XMLHelper.get_value(fuel_load, 'extension/FracSensible', :float)
      @frac_latent = XMLHelper.get_value(fuel_load, 'extension/FracLatent', :float)
      @usage_multiplier = XMLHelper.get_value(fuel_load, 'extension/UsageMultiplier', :float)
      @weekday_fractions = XMLHelper.get_value(fuel_load, 'extension/WeekdayScheduleFractions', :string)
      @weekend_fractions = XMLHelper.get_value(fuel_load, 'extension/WeekendScheduleFractions', :string)
      @monthly_multipliers = XMLHelper.get_value(fuel_load, 'extension/MonthlyScheduleMultipliers', :string)
    end
  end

  # Array of HPXML::CoolingPerformanceDataPoint objects.
  class CoolingDetailedPerformanceData < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << CoolingPerformanceDataPoint.new(@parent_object, **kwargs)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param hvac_system [Oga::XML::Element] The current HVAC system XML element
    # @return [nil]
    def from_doc(hvac_system)
      return if hvac_system.nil?

      XMLHelper.get_elements(hvac_system, 'CoolingDetailedPerformanceData/PerformanceDataPoint').each do |performance_data_point|
        self << CoolingPerformanceDataPoint.new(@parent_object, performance_data_point)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/*/CoolingDetailedPerformanceData/PerformanceDataPoint.
  class CoolingPerformanceDataPoint < BaseElement
    ATTRS = [:isdefaulted,                  # [Boolean] @dataSource="software"
             :outdoor_temperature,          # [Double] OutdoorTemperature (F)
             :indoor_temperature,           # [Double] IndoorTemperature (F)
             :indoor_wetbulb,               # [Double] IndoorWetbulbTemperature (F)
             :capacity,                     # [Double] Capacity (Btu/hr)
             :capacity_fraction_of_nominal, # [Double] CapacityFractionOfNominal (frac)
             :capacity_description,         # [String] CapacityDescription (HPXML::CapacityDescriptionXXX)
             :efficiency_cop,               # [Double] Efficiency[Units="COP"]/Value (W/W)
             :gross_capacity,               # FUTURE: Not in HPXML schema, should move to additional_properties
             :gross_efficiency_cop,         # FUTURE: Not in HPXML schema, should move to additional_properties
             :gross_input_power,            # FUTURE: Not in HPXML schema, should move to additional_properties
             :input_power]                  # FUTURE: Not in HPXML schema, should move to additional_properties
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      (@parent_object.cooling_systems + @parent_object.heat_pumps).each do |cooling_system|
        cooling_system.cooling_detailed_performance_data.delete(self)
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param hvac_system [Oga::XML::Element] Parent XML element
    # @return [nil]
    def to_doc(hvac_system)
      detailed_performance_data = XMLHelper.create_elements_as_needed(hvac_system, ['CoolingDetailedPerformanceData'])
      performance_data_point = XMLHelper.add_element(detailed_performance_data, 'PerformanceDataPoint')
      XMLHelper.add_attribute(performance_data_point, 'dataSource', 'software') if @isdefaulted
      XMLHelper.add_element(performance_data_point, 'OutdoorTemperature', @outdoor_temperature, :float, @outdoor_temperature_isdefaulted) unless @outdoor_temperature.nil?
      XMLHelper.add_element(performance_data_point, 'IndoorTemperature', @indoor_temperature, :float, @indoor_temperature_isdefaulted) unless @indoor_temperature.nil?
      XMLHelper.add_element(performance_data_point, 'IndoorWetbulbTemperature', @indoor_wetbulb, :float, @indoor_wetbulb_isdefaulted) unless @indoor_wetbulb.nil?
      XMLHelper.add_element(performance_data_point, 'Capacity', @capacity, :float, @capacity_isdefaulted) unless @capacity.nil?
      XMLHelper.add_element(performance_data_point, 'CapacityFractionOfNominal', @capacity_fraction_of_nominal, :float, @capacity_fraction_of_nominal_isdefaulted) unless @capacity_fraction_of_nominal.nil?
      XMLHelper.add_element(performance_data_point, 'CapacityDescription', @capacity_description, :string, @capacity_description_isdefaulted) unless @capacity_description.nil?
      if not @efficiency_cop.nil?
        efficiency = XMLHelper.add_element(performance_data_point, 'Efficiency')
        XMLHelper.add_element(efficiency, 'Units', UnitsCOP, :string)
        XMLHelper.add_element(efficiency, 'Value', @efficiency_cop, :float)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param performance_data_point [Oga::XML::Element] The current CoolingPerformanceDataPoint XML element
    # @return [nil]
    def from_doc(performance_data_point)
      return if performance_data_point.nil?

      @outdoor_temperature = XMLHelper.get_value(performance_data_point, 'OutdoorTemperature', :float)
      @indoor_temperature = XMLHelper.get_value(performance_data_point, 'IndoorTemperature', :float)
      @indoor_wetbulb = XMLHelper.get_value(performance_data_point, 'IndoorWetbulbTemperature', :float)
      @capacity = XMLHelper.get_value(performance_data_point, 'Capacity', :float)
      @capacity_fraction_of_nominal = XMLHelper.get_value(performance_data_point, 'CapacityFractionOfNominal', :float)
      @capacity_description = XMLHelper.get_value(performance_data_point, 'CapacityDescription', :string)
      @efficiency_cop = XMLHelper.get_value(performance_data_point, "Efficiency[Units='#{UnitsCOP}']/Value", :float)
    end
  end

  # Array of HPXML::HeatingPerformanceDataPoint objects.
  class HeatingDetailedPerformanceData < BaseArrayElement
    # Adds a new object, with the specified keyword arguments, to the array.
    #
    # @return [nil]
    def add(**kwargs)
      self << HeatingPerformanceDataPoint.new(@parent_object, **kwargs)
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param hvac_system [Oga::XML::Element] The current HVAC system XML element
    # @return [nil]
    def from_doc(hvac_system)
      return if hvac_system.nil?

      XMLHelper.get_elements(hvac_system, 'HeatingDetailedPerformanceData/PerformanceDataPoint').each do |performance_data_point|
        self << HeatingPerformanceDataPoint.new(@parent_object, performance_data_point)
      end
    end
  end

  # Object for /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/*/HeatingDetailedPerformanceData/PerformanceDataPoint.
  class HeatingPerformanceDataPoint < BaseElement
    ATTRS = [:isdefaulted,                  # [Boolean] @dataSource="software"
             :outdoor_temperature,          # [Double] OutdoorTemperature (F)
             :indoor_temperature,           # [Double] IndoorTemperature (F)
             :capacity,                     # [Double] Capacity (Btu/hr)
             :capacity_fraction_of_nominal, # [Double] CapacityFractionOfNominal (frac)
             :capacity_description,         # [String] CapacityDescription (HPXML::CapacityDescriptionXXX)
             :efficiency_cop,               # [Double] Efficiency[Units="COP"]/Value (W/W)
             :gross_capacity,               # FUTURE: Not in HPXML schema, should move to additional_properties
             :gross_efficiency_cop,         # FUTURE: Not in HPXML schema, should move to additional_properties
             :gross_input_power,            # FUTURE: Not in HPXML schema, should move to additional_properties
             :input_power]                  # FUTURE: Not in HPXML schema, should move to additional_properties
    attr_accessor(*ATTRS)

    # Deletes the current object from the array.
    #
    # @return [nil]
    def delete
      (@parent_object.heating_systems + @parent_object.heat_pumps).each do |heating_system|
        heating_system.heating_detailed_performance_data.delete(self)
      end
    end

    # Additional error-checking beyond what's checked in Schema/Schematron validators.
    #
    # @return [Array<String>] List of error messages
    def check_for_errors
      errors = []
      return errors
    end

    # Adds this object to the provided Oga XML element.
    #
    # @param hvac_system [Oga::XML::Element] Parent XML element
    # @return [nil]
    def to_doc(hvac_system)
      detailed_performance_data = XMLHelper.create_elements_as_needed(hvac_system, ['HeatingDetailedPerformanceData'])
      performance_data_point = XMLHelper.add_element(detailed_performance_data, 'PerformanceDataPoint')
      XMLHelper.add_attribute(performance_data_point, 'dataSource', 'software') if @isdefaulted
      XMLHelper.add_element(performance_data_point, 'OutdoorTemperature', @outdoor_temperature, :float, @outdoor_temperature_isdefaulted) unless @outdoor_temperature.nil?
      XMLHelper.add_element(performance_data_point, 'IndoorTemperature', @indoor_temperature, :float, @indoor_temperature_isdefaulted) unless @indoor_temperature.nil?
      XMLHelper.add_element(performance_data_point, 'Capacity', @capacity, :float, @capacity_isdefaulted) unless @capacity.nil?
      XMLHelper.add_element(performance_data_point, 'CapacityFractionOfNominal', @capacity_fraction_of_nominal, :float, @capacity_fraction_of_nominal_isdefaulted) unless @capacity_fraction_of_nominal.nil?
      XMLHelper.add_element(performance_data_point, 'CapacityDescription', @capacity_description, :string, @capacity_description_isdefaulted) unless @capacity_description.nil?
      if not @efficiency_cop.nil?
        efficiency = XMLHelper.add_element(performance_data_point, 'Efficiency')
        XMLHelper.add_element(efficiency, 'Units', UnitsCOP, :string)
        XMLHelper.add_element(efficiency, 'Value', @efficiency_cop, :float)
      end
    end

    # Populates the HPXML object(s) from the XML document.
    #
    # @param performance_data_point [Oga::XML::Element] The current HeatingPerformanceDataPoint XML element
    # @return [nil]
    def from_doc(performance_data_point)
      return if performance_data_point.nil?

      @outdoor_temperature = XMLHelper.get_value(performance_data_point, 'OutdoorTemperature', :float)
      @indoor_temperature = XMLHelper.get_value(performance_data_point, 'IndoorTemperature', :float)
      @capacity = XMLHelper.get_value(performance_data_point, 'Capacity', :float)
      @capacity_fraction_of_nominal = XMLHelper.get_value(performance_data_point, 'CapacityFractionOfNominal', :float)
      @capacity_description = XMLHelper.get_value(performance_data_point, 'CapacityDescription', :string)
      @efficiency_cop = XMLHelper.get_value(performance_data_point, "Efficiency[Units='#{UnitsCOP}']/Value", :float)
    end
  end

  # Returns a new, empty HPXML document
  #
  # @return [Oga::XML::Document] The HPXML document
  def _create_hpxml_document
    doc = XMLHelper.create_doc()
    hpxml = XMLHelper.add_element(doc, 'HPXML')
    XMLHelper.add_attribute(hpxml, 'xmlns', NameSpace)
    XMLHelper.add_attribute(hpxml, 'schemaVersion', Version::HPXML_Version)
    return doc
  end

  # The unique set of HPXML fossil fuel types that end up used in the EnergyPlus model.
  # Some other fuel types (e.g., FuelTypeCoalAnthracite) are collapsed into this list.
  #
  # @return [Array<String>] List of fuel types (HPXML::FuelTypeXXX)
  def self.fossil_fuels
    return [HPXML::FuelTypeNaturalGas,
            HPXML::FuelTypePropane,
            HPXML::FuelTypeOil,
            HPXML::FuelTypeCoal,
            HPXML::FuelTypeWoodCord,
            HPXML::FuelTypeWoodPellets]
  end

  # The unique set of all HPXML fuel types that end up used in the EnergyPlus model.
  # Some other fuel types (e.g., FuelTypeCoalAnthracite) are collapsed into this list.
  #
  # @return [Array<String>] List of fuel types (HPXML::FuelTypeXXX)
  def self.all_fuels
    return [HPXML::FuelTypeElectricity] + fossil_fuels
  end

  # Returns the set of all location types that are vented.
  #
  # @return [Array<String>] List of vented locations (HPXML::LocationXXX)
  def self.vented_locations
    return [HPXML::LocationAtticVented,
            HPXML::LocationCrawlspaceVented]
  end

  # Returns the set of all location types that are conditioned.
  #
  # @return [Array<String>] List of conditioned locations (HPXML::LocationXXX)
  def self.conditioned_locations
    return [HPXML::LocationConditionedSpace,
            HPXML::LocationBasementConditioned,
            HPXML::LocationCrawlspaceConditioned,
            HPXML::LocationOtherHousingUnit]
  end

  # Returns the set of all location types that are multifamily common spaces.
  #
  # @return [Array<String>] List of multifamily common space locations (HPXML::LocationXXX)
  def self.multifamily_common_space_locations
    return [HPXML::LocationOtherHeatedSpace,
            HPXML::LocationOtherMultifamilyBufferSpace,
            HPXML::LocationOtherNonFreezingSpace]
  end

  # Returns the set of all location types that are conditioned and part of the
  # dwelling unit.
  #
  # @return [Array<String>] List of conditioned locations (HPXML::LocationXXX)
  def self.conditioned_locations_this_unit
    return [HPXML::LocationConditionedSpace,
            HPXML::LocationBasementConditioned,
            HPXML::LocationCrawlspaceConditioned]
  end

  # Returns the set of all location types that are conditioned and assumed to
  # be finished (e.g., have interior finishes like drywall).
  #
  # @return [Array<String>] List of conditioned, finished locations (HPXML::LocationXXX)
  def self.conditioned_finished_locations
    return [HPXML::LocationConditionedSpace,
            HPXML::LocationBasementConditioned]
  end

  # Returns the set of all location types that are conditioned and below-grade.
  #
  # @return [Array<String>] List of conditioned, below-grade locations (HPXML::LocationXXX)
  def self.conditioned_below_grade_locations
    return [HPXML::LocationBasementConditioned,
            HPXML::LocationCrawlspaceConditioned]
  end

  # Returns whether the surface is adjacent to conditioned space.
  #
  # @param surface [HPXML::XXX] HPXML surface of interest
  # @return [Boolean] True if adjacent to conditioned space
  def self.is_conditioned(surface)
    return conditioned_locations.include?(surface.interior_adjacent_to)
  end

  # Returns whether the surface is determined to be adiabatic.
  #
  # @param surface [HPXML::XXX] HPXML surface of interest
  # @return [Boolean] True if adiabatic
  def self.is_adiabatic(surface)
    if surface.exterior_adjacent_to == surface.interior_adjacent_to
      # E.g., wall between unit crawlspace and neighboring unit crawlspace
      return true
    elsif conditioned_locations.include?(surface.interior_adjacent_to) &&
          conditioned_locations.include?(surface.exterior_adjacent_to)
      # E.g., wall with conditioned space on both sides
      return true
    end

    return false
  end

  # Returns whether the surface is between conditioned space and outside/ground/unconditioned space.
  # Note: The location of insulation is not considered here, so an insulated foundation wall of an
  # unconditioned basement, for example, returns false.
  #
  # @param surface [OpenStudio::Model::Surface] the surface of interest
  # @return [Boolean] True if a thermal boundary surface
  def self.is_thermal_boundary(surface)
    interior_conditioned = conditioned_locations.include? surface.interior_adjacent_to
    exterior_conditioned = conditioned_locations.include? surface.exterior_adjacent_to
    return (interior_conditioned && !exterior_conditioned)
  end

  # Returns whether the HPXML::Floor object represents a ceiling or floor
  # from the perspective of the conditioned space.
  #
  # For example, the surface above an unconditioned basement is a floor.
  # The surface below an attic is a ceiling.
  #
  # @param hpxml_floor [HPXML::Floor] HPXML floor surface
  # @param force_decision [Boolean] If false, can return nil if not explicitly known
  # @return [Boolean or nil] True if the surface is a ceiling
  def self.is_floor_a_ceiling(hpxml_floor, force_decision)
    ceiling_locations = [LocationAtticUnconditioned,
                         LocationAtticVented,
                         LocationAtticUnvented]
    floor_locations = [LocationCrawlspaceVented,
                       LocationCrawlspaceUnvented,
                       LocationBasementUnconditioned,
                       LocationManufacturedHomeUnderBelly]
    if (ceiling_locations.include? hpxml_floor.interior_adjacent_to) || (ceiling_locations.include? hpxml_floor.exterior_adjacent_to)
      return true
    elsif (floor_locations.include? hpxml_floor.interior_adjacent_to) || (floor_locations.include? hpxml_floor.exterior_adjacent_to)
      return false
    elsif force_decision
      # If we don't explicitly know, assume a floor
      return false
    end
  end

  # Gets the ID attribute for the given element.
  #
  # @param parent [Oga::XML::Element] The parent HPXML element
  # @param element_name [String] The name of the child element with the ID attribute
  # @return [String] The element ID attribute
  def self.get_id(parent, element_name = 'SystemIdentifier')
    return XMLHelper.get_attribute_value(XMLHelper.get_element(parent, element_name), 'id')
  end

  # Gets the sameas attribute for the given element.
  #
  # @param parent [Oga::XML::Element] The parent HPXML element
  # @param element_name [String] The name of the child element with the sameas attribute
  # @return [String] The element sameas attribute
  def self.get_sameas_id(parent, element_name = 'SystemIdentifier')
    return XMLHelper.get_attribute_value(XMLHelper.get_element(parent, element_name), 'sameas')
  end

  # Gets the IDREF attribute for the given element.
  #
  # @param element [Oga::XML::Element] The HPXML element
  # @return [String] The element IDREF attribute
  def self.get_idref(element)
    return XMLHelper.get_attribute_value(element, 'idref')
  end

  # Gets the IDREF attribute for all instances of the given element.
  #
  # @param parent [Oga::XML::Element] The parent HPXML element
  # @param element [Oga::XML::Element] The HPXML element
  # @return [Array<String>] The list of element IDREF attributes
  def self.get_idrefs(parent, element_name)
    idrefs = []
    parent.xpath(element_name).each do |value|
      idrefs << XMLHelper.get_attribute_value(value, 'idref')
    end
    return idrefs
  end

  # Find the sameas object (from another HPXML Building) with sameas_id as well as assigns
  # the adjacent_hpxml_id, adjacent_unit_number, and adjacent_space_type additional properties.
  # Returns the referenced sameas object if found.
  #
  # @param parent_building [Oga::XML::Element] The parent Building element
  # @param sameas_object [Oga::XML::Element]  The HPXML element with sameas id
  # @return [Oga::XML::Element] The element that sameas id attribute associated with
  def self.get_sameas_obj(parent_building, sameas_object)
    hpxml = parent_building.parent_object
    return unless hpxml.header.whole_sfa_or_mf_building_sim

    hpxml.buildings.each do |building|
      building.class::CLASS_ATTRS.each do |attr|
        building_child = building.send(attr)
        next unless building_child.is_a? HPXML::BaseArrayElement

        building_child.each do |adjacent_obj|
          next unless adjacent_obj.id == sameas_object.sameas_id
          if building.building_id == parent_building.building_id
            fail "'#{sameas_object.id}' sameas references the object in the same building '#{parent_building.building_id}'."
          end

          if adjacent_obj.is_a? sameas_object.class
            # Assign adjacent_hpxml_id
            adjacent_ap = adjacent_obj.additional_properties
            if not adjacent_ap.respond_to? :adjacent_hpxml_id
              adjacent_ap.adjacent_hpxml_id = sameas_object.id
              adjacent_ap.adjacent_unit_number = hpxml.buildings.index(sameas_object.parent_object)
              # Note: sameas surface is assumed to have the same interior_adjacent_to as the adjacent surface.
              # If that's not the case, we would have to allow InteriorAdjacentTo to be provided for the sameas
              # surface. See https://github.com/NREL/OpenStudio-HPXML/pull/2105#discussion_r2583146171.
              adjacent_ap.adjacent_space_type = adjacent_obj.interior_adjacent_to
            elsif adjacent_ap.adjacent_hpxml_id != sameas_object.id
              fail "'#{adjacent_obj.id}' is referenced by multiple objects."
            end
            return adjacent_obj
          else
            fail "'#{sameas_object.id}' reference the wrong object type with sameas id '#{sameas_object.sameas_id}'."
          end
        end
      end
    end
    if not sameas_object.sameas_id.nil?
      fail "Sameas object '#{sameas_object.sameas_id}' not found."
    end

    return
  end

  # Checks whether a given date is valid (e.g., Sep 31 is invalid).
  #
  # @param use_case [String] Name of the use case to include in the error message
  # @param begin_month [Integer] Date begin month
  # @param begin_day [Integer] Date begin day
  # @param end_month [Integer] Date end month
  # @param end_day [Integer] Date end day
  # @return [Array<String>] List of error messages
  def self.check_dates(use_case, begin_month, begin_day, end_month, end_day)
    errors = []

    # Check for valid months
    valid_months = (1..12).to_a

    if not begin_month.nil?
      if not valid_months.include? begin_month
        errors << "#{use_case} Begin Month (#{begin_month}) must be one of: #{valid_months.join(', ')}."
      end
    end

    if not end_month.nil?
      if not valid_months.include? end_month
        errors << "#{use_case} End Month (#{end_month}) must be one of: #{valid_months.join(', ')}."
      end
    end

    # Check for valid days
    months_days = { [1, 3, 5, 7, 8, 10, 12] => (1..31).to_a, [4, 6, 9, 11] => (1..30).to_a, [2] => (1..28).to_a }
    months_days.each do |months, valid_days|
      if (not begin_day.nil?) && (months.include? begin_month)
        if not valid_days.include? begin_day
          errors << "#{use_case} Begin Day of Month (#{begin_day}) must be one of: #{valid_days.join(', ')}."
        end
      end
      next unless (not end_day.nil?) && (months.include? end_month)

      if not valid_days.include? end_day
        errors << "#{use_case} End Day of Month (#{end_day}) must be one of: #{valid_days.join(', ')}."
      end
    end

    return errors
  end

  # Adds this object's design loads to the provided Oga XML element.
  #
  # @param hpxml_object [HPXML::XXX] The Zone/Space/HVACPlant object
  # @param hpxml_element [Oga::XML::Element] The Zone/Space/HVACPlant XML element
  # @return [nil]
  def self.design_loads_to_doc(hpxml_object, hpxml_element)
    { HDL_ATTRS => 'Heating',
      CDL_SENS_ATTRS => 'CoolingSensible',
      CDL_LAT_ATTRS => 'CoolingLatent' }.each do |attrs, dl_child_name|
      next if hpxml_object.is_a?(HPXML::Space) && dl_child_name == 'CoolingLatent' # Latent loads are not calculated for spaces

      dl_extension = XMLHelper.create_elements_as_needed(hpxml_element, ['extension', 'DesignLoads'])
      XMLHelper.add_attribute(dl_extension, 'dataSource', 'software')
      dl_child = XMLHelper.add_element(dl_extension, dl_child_name)
      attrs.each do |attr, element_name|
        if element_name.include? 'AEDCurve'
          XMLHelper.add_element(dl_child, element_name, hpxml_object.send(attr), :string)
        else
          XMLHelper.add_element(dl_child, element_name, hpxml_object.send(attr), :float)
        end
      end
    end
  end

  # Populates the HPXML object's design loads from the XML element.
  #
  # @param hpxml_object [HPXML::XXX] The Zone/Space/HVACPlant object
  # @param hpxml_element [Oga::XML::Element] The Zone/Space/HVACPlant XML element
  # @return [nil]
  def self.design_loads_from_doc(hpxml_object, hpxml_element)
    { HDL_ATTRS => 'Heating',
      CDL_SENS_ATTRS => 'CoolingSensible',
      CDL_LAT_ATTRS => 'CoolingLatent' }.each do |attrs, dl_child_name|
      attrs.each do |attr, element_name|
        if element_name.include? 'AEDCurve'
          hpxml_object.send("#{attr}=", XMLHelper.get_value(hpxml_element, "extension/DesignLoads/#{dl_child_name}/#{element_name}", :string))
        else
          hpxml_object.send("#{attr}=", XMLHelper.get_value(hpxml_element, "extension/DesignLoads/#{dl_child_name}/#{element_name}", :float))
        end
      end
    end
  end

  # Returns attached branch circuits for provided component ID.
  #
  # @param component [HPXML::XXX] HPXML component
  # @param electric_panels [Array<HPXML::ElectricPanel>] List of electric panel objects
  # @return [Array<HPXML::BranchCircuit>] List of branch circuit objects
  def self.branch_circuits(id, electric_panels)
    list = []
    electric_panels.each do |electric_panel|
      electric_panel.branch_circuits.each do |branch_circuit|
        next if branch_circuit.component_idrefs.nil? || branch_circuit.component_idrefs.empty?
        next unless branch_circuit.component_idrefs.include?(id)

        list << branch_circuit
      end
    end

    return list
  end

  # Returns attached service feeders for provided component ID.
  #
  # @param id [String] SystemIdentifier/@id
  # @param electric_panels [Array<HPXML::ElectricPanel>] List of electric panel objects
  # @return [Array<HPXML::ServiceFeeder>] List of service feeder objects
  def self.service_feeders(id, electric_panels)
    list = []
    electric_panels.each do |electric_panel|
      electric_panel.service_feeders.each do |service_feeder|
        next if service_feeder.component_idrefs.empty?
        next unless service_feeder.component_idrefs.include?(id)

        list << service_feeder
      end
    end

    return list
  end
end
