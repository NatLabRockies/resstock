# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require_relative '../measure.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioWaterHeaterTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(File.dirname(__FILE__), 'tmp.xml')
    @schema_validator = XMLValidator.get_xml_validator(File.join(File.dirname(__FILE__), '..', 'resources', 'hpxml_schema', 'HPXML.xsd'))
    @schematron_validator = XMLValidator.get_xml_validator(File.join(File.dirname(__FILE__), '..', 'resources', 'hpxml_schematron', 'EPvalidator.sch'))
  end

  def teardown
    cleanup_output_files([@tmp_hpxml_path])
  end

  def test_tank_gas
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tank-gas.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 3.37
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(0.64, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_gas_ef
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tank-gas-ef.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 4.12
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.775
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(0.64, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_oil
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tank-oil.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 3.16
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(0.64, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_wood
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tank-wood.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 3.375
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(0.64, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_coal
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tank-coal.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 3.37
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(0.64, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_electric
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.97
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 1.0
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_electric_ef
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tank-elec-ef.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 1.30
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 1.0
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tankless_electric
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tankless-electric.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(1.0, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(100000000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.0
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C')
    ther_eff = 0.9212
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tankless_electric_ef
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tankless-electric-ef.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(1.0, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(100000000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.0
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C')
    ther_eff = 0.8832
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tankless_gas_ef
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tankless-gas-ef.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(1.0, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(100000000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.0
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C')
    ther_eff = 0.8742
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_outside
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tank-gas-outside.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 3.37
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal('Outdoors', wh.ambientTemperatureIndicator)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
  end

  def test_desuperheater_1_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-desuperheater.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.97
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    loc = water_heating_system.location
    ther_eff = 1.0

    # Check water heater
    assert_equal(2, model.getWaterHeaterMixeds.size) # preheat tank + water heater
    wh = model.getWaterHeaterMixeds.find { |wh| (not wh.name.get.include? 'storage tank') }
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check desuperheater
    assert_equal(1, model.getCoilWaterHeatingDesuperheaters.size)
    preheat_tank = model.getWaterHeaterMixeds.find { |wh| wh.name.get.include? 'storage tank' }
    dsh_coil = model.getCoilWaterHeatingDesuperheaters[0]
    assert_equal(true, dsh_coil.heatingSource.get.to_CoilCoolingDXSingleSpeed.is_initialized)
    assert_equal(preheat_tank, dsh_coil.heatRejectionTarget.get.to_WaterHeaterMixed.get)
  end

  def test_desuperheater_var_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-desuperheater-var-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.97
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    loc = water_heating_system.location
    ther_eff = 1.0

    # Check water heater
    assert_equal(2, model.getWaterHeaterMixeds.size) # preheat tank + water heater
    wh = model.getWaterHeaterMixeds.find { |wh| (not wh.name.get.include? 'storage tank') }
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check desuperheater
    assert_equal(1, model.getCoilWaterHeatingDesuperheaters.size)
    preheat_tank = model.getWaterHeaterMixeds.find { |wh| wh.name.get.include? 'storage tank' }
    dsh_coil = model.getCoilWaterHeatingDesuperheaters[0]
    assert_equal(true, dsh_coil.heatingSource.get.to_CoilCoolingDXMultiSpeed.is_initialized)
    assert_equal(preheat_tank, dsh_coil.heatRejectionTarget.get.to_WaterHeaterMixed.get)
  end

  def test_desuperheater_gshp
    ['base-dhw-desuperheater-ghp.xml',
     'base-dhw-desuperheater-ghp-experimental.xml'].each do |hpxml_name|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_name))
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)

      # Get HPXML values
      water_heating_system = hpxml_bldg.water_heating_systems[0]

      # Expected value
      tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
      cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
      fuel = EPlus.fuel_type(water_heating_system.fuel_type)
      ua = 0.97
      t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
      loc = water_heating_system.location
      ther_eff = 1.0

      # Check water heater
      assert_equal(2, model.getWaterHeaterMixeds.size) # preheat tank + water heater
      wh = model.getWaterHeaterMixeds.find { |wh| (not wh.name.get.include? 'storage tank') }
      assert_equal(fuel, wh.heaterFuelType)
      assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
      assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
      assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
      assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
      assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
      assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
      assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
      assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

      # Check desuperheater
      assert_equal(1, model.getCoilWaterHeatingDesuperheaters.size)
      preheat_tank = model.getWaterHeaterMixeds.find { |wh| wh.name.get.include? 'storage tank' }
      dsh_coil = model.getCoilWaterHeatingDesuperheaters[0]
      if hpxml_name == 'base-dhw-desuperheater-ghp.xml'
        assert_equal(true, dsh_coil.heatingSource.get.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized)
      elsif hpxml_name == 'base-dhw-desuperheater-ghp-experimental.xml'
        assert_equal(true, dsh_coil.heatingSource.get.to_CoilCoolingWaterToAirHeatPumpVariableSpeedEquationFit.is_initialized)
      end
      assert_equal(preheat_tank, dsh_coil.heatRejectionTarget.get.to_WaterHeaterMixed.get)
    end
  end

  def test_solar_direct_evacuated_tube
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-solar-direct-evacuated-tube.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]
    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.97
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    loc = water_heating_system.location
    hx_eff = 1.0

    collector_area = UnitConversions.convert(solar_thermal_system.collector_area, 'ft^2', 'm^2')
    ther_eff = 1.0
    iam_coeff2 = 0.3023
    iam_coeff3 = -0.3057
    collector_coeff_2 = -UnitConversions.convert(solar_thermal_system.collector_rated_thermal_losses, 'Btu/(hr*ft^2*F)', 'W/(m^2*K)')
    storage_tank_volume = 0.2271
    storage_tank_height = UnitConversions.convert(4.5, 'ft', 'm')
    storage_tank_u = 0.0
    pump_power = 0.8 * solar_thermal_system.collector_area

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size) # preheat tank + water heater
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check solar thermal system
    assert_equal(1, model.getSolarCollectorFlatPlateWaters.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    preheat_tank = model.getWaterHeaterStratifieds[0]
    assert_in_epsilon(storage_tank_volume, preheat_tank.tankVolume.get, 0.01)
    assert_in_epsilon(storage_tank_height, preheat_tank.tankHeight.get, 0.01)
    assert_in_epsilon(hx_eff, preheat_tank.sourceSideEffectiveness, 0.01)
    assert_in_epsilon(storage_tank_u, preheat_tank.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.01)

    collector = model.getSolarCollectorFlatPlateWaters[0]
    collector_performance = collector.solarCollectorPerformance
    assert_in_epsilon(collector_area, collector_performance.grossArea, 0.01)
    assert_in_epsilon(solar_thermal_system.collector_rated_optical_efficiency, collector_performance.coefficient1ofEfficiencyEquation, 0.01)
    assert_in_epsilon(collector_coeff_2, collector_performance.coefficient2ofEfficiencyEquation, 0.01)
    assert_in_epsilon(-iam_coeff2, collector_performance.coefficient2ofIncidentAngleModifier.get, 0.01)
    assert_in_epsilon(iam_coeff3, collector_performance.coefficient3ofIncidentAngleModifier.get, 0.01)

    collector_attached_to_tank = false
    loop = nil
    model.getPlantLoops.each do |plant_loop|
      next if plant_loop.supplyComponents.select { |comp| comp == collector }.empty?
      next if plant_loop.demandComponents.select { |comp| comp == preheat_tank }.empty?

      collector_attached_to_tank = true
      assert_equal(plant_loop.fluidType, EPlus::FluidWater)
      loop = plant_loop
    end
    pump = loop.supplyComponents.find { |comp| comp.to_PumpConstantSpeed.is_initialized }
    assert_equal(pump_power, pump.to_PumpConstantSpeed.get.ratedPowerConsumption.get)
    assert_equal(collector_attached_to_tank, true)
  end

  def test_solar_direct_flat_plate
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-solar-direct-flat-plate.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]
    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.97
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    loc = water_heating_system.location
    hx_eff = 1.0

    collector_area = UnitConversions.convert(solar_thermal_system.collector_area, 'ft^2', 'm^2')
    ther_eff = 1.0
    iam_coeff2 = 0.1
    iam_coeff3 = 0
    collector_coeff_2 = -UnitConversions.convert(solar_thermal_system.collector_rated_thermal_losses, 'Btu/(hr*ft^2*F)', 'W/(m^2*K)')
    storage_tank_volume = 0.2271
    storage_tank_height = UnitConversions.convert(4.5, 'ft', 'm')
    storage_tank_u = 0.0
    pump_power = 0.8 * solar_thermal_system.collector_area

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size) # preheat tank + water heater
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check solar thermal system
    assert_equal(1, model.getSolarCollectorFlatPlateWaters.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    preheat_tank = model.getWaterHeaterStratifieds[0]
    assert_in_epsilon(storage_tank_volume, preheat_tank.tankVolume.get, 0.01)
    assert_in_epsilon(storage_tank_height, preheat_tank.tankHeight.get, 0.01)
    assert_in_epsilon(hx_eff, preheat_tank.sourceSideEffectiveness, 0.01)
    assert_in_epsilon(storage_tank_u, preheat_tank.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.01)

    collector = model.getSolarCollectorFlatPlateWaters[0]
    collector_performance = collector.solarCollectorPerformance
    assert_in_epsilon(collector_area, collector_performance.grossArea, 0.01)
    assert_in_epsilon(solar_thermal_system.collector_rated_optical_efficiency, collector_performance.coefficient1ofEfficiencyEquation, 0.01)
    assert_in_epsilon(collector_coeff_2, collector_performance.coefficient2ofEfficiencyEquation, 0.01)
    assert_in_epsilon(-iam_coeff2, collector_performance.coefficient2ofIncidentAngleModifier.get, 0.01)
    assert_in_epsilon(iam_coeff3, collector_performance.coefficient3ofIncidentAngleModifier.get, 0.01)

    collector_attached_to_tank = false
    loop = nil
    model.getPlantLoops.each do |plant_loop|
      next if plant_loop.supplyComponents.select { |comp| comp == collector }.empty?
      next if plant_loop.demandComponents.select { |comp| comp == preheat_tank }.empty?

      collector_attached_to_tank = true
      assert_equal(plant_loop.fluidType, EPlus::FluidWater)
      loop = plant_loop
    end
    pump = loop.supplyComponents.find { |comp| comp.to_PumpConstantSpeed.is_initialized }
    assert_equal(pump_power, pump.to_PumpConstantSpeed.get.ratedPowerConsumption.get)
    assert_equal(collector_attached_to_tank, true)
  end

  def test_solar_indirect_flat_plate
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-solar-indirect-flat-plate.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]
    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.97
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    loc = water_heating_system.location
    hx_eff = 0.7

    collector_area = UnitConversions.convert(solar_thermal_system.collector_area, 'ft^2', 'm^2')
    ther_eff = 1.0
    iam_coeff2 = 0.1
    iam_coeff3 = 0
    collector_coeff_2 = -UnitConversions.convert(solar_thermal_system.collector_rated_thermal_losses, 'Btu/(hr*ft^2*F)', 'W/(m^2*K)')
    storage_tank_volume = UnitConversions.convert(solar_thermal_system.storage_volume, 'gal', 'm^3')
    storage_tank_height = UnitConversions.convert(4.5, 'ft', 'm')
    storage_tank_u = UnitConversions.convert(0.1, 'Btu/(hr*ft^2*F)', 'W/(m^2*K)')
    pump_power = 0.8 * solar_thermal_system.collector_area

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size) # preheat tank + water heater
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check solar thermal system
    assert_equal(1, model.getSolarCollectorFlatPlateWaters.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    preheat_tank = model.getWaterHeaterStratifieds[0]
    assert_in_epsilon(storage_tank_volume, preheat_tank.tankVolume.get, 0.01)
    assert_in_epsilon(storage_tank_height, preheat_tank.tankHeight.get, 0.01)
    assert_in_epsilon(hx_eff, preheat_tank.sourceSideEffectiveness, 0.01)
    assert_in_epsilon(storage_tank_u, preheat_tank.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.01)

    collector = model.getSolarCollectorFlatPlateWaters[0]
    collector_performance = collector.solarCollectorPerformance
    assert_in_epsilon(collector_area, collector_performance.grossArea, 0.01)
    assert_in_epsilon(solar_thermal_system.collector_rated_optical_efficiency, collector_performance.coefficient1ofEfficiencyEquation, 0.01)
    assert_in_epsilon(collector_coeff_2, collector_performance.coefficient2ofEfficiencyEquation, 0.01)
    assert_in_epsilon(-iam_coeff2, collector_performance.coefficient2ofIncidentAngleModifier.get, 0.01)
    assert_in_epsilon(iam_coeff3, collector_performance.coefficient3ofIncidentAngleModifier.get, 0.01)

    collector_attached_to_tank = false
    loop = nil
    model.getPlantLoops.each do |plant_loop|
      next if plant_loop.supplyComponents.select { |comp| comp == collector }.empty?
      next if plant_loop.demandComponents.select { |comp| comp == preheat_tank }.empty?

      collector_attached_to_tank = true
      assert_equal(plant_loop.fluidType, EPlus::FluidPropyleneGlycol)
      loop = plant_loop
    end
    pump = loop.supplyComponents.find { |comp| comp.to_PumpConstantSpeed.is_initialized }
    assert_equal(pump_power, pump.to_PumpConstantSpeed.get.ratedPowerConsumption.get)
    assert_equal(collector_attached_to_tank, true)
  end

  def test_solar_thermosyphon_flat_plate
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-solar-thermosyphon-flat-plate.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]
    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.97
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    loc = water_heating_system.location
    hx_eff = 1.0

    collector_area = UnitConversions.convert(solar_thermal_system.collector_area, 'ft^2', 'm^2')
    ther_eff = 1.0
    iam_coeff2 = 0.1
    iam_coeff3 = 0
    collector_coeff_2 = -UnitConversions.convert(solar_thermal_system.collector_rated_thermal_losses, 'Btu/(hr*ft^2*F)', 'W/(m^2*K)')
    storage_tank_volume = 0.2271
    storage_tank_height = UnitConversions.convert(4.5, 'ft', 'm')
    storage_tank_u = 0.0
    pump_power = 0.0

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size) # preheat tank + water heater
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check solar thermal system
    assert_equal(1, model.getSolarCollectorFlatPlateWaters.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    preheat_tank = model.getWaterHeaterStratifieds[0]
    assert_in_epsilon(storage_tank_volume, preheat_tank.tankVolume.get, 0.01)
    assert_in_epsilon(storage_tank_height, preheat_tank.tankHeight.get, 0.01)
    assert_in_epsilon(hx_eff, preheat_tank.sourceSideEffectiveness, 0.01)
    assert_in_epsilon(storage_tank_u, preheat_tank.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.01)

    collector = model.getSolarCollectorFlatPlateWaters[0]
    collector_performance = collector.solarCollectorPerformance
    assert_in_epsilon(collector_area, collector_performance.grossArea, 0.01)
    assert_in_epsilon(solar_thermal_system.collector_rated_optical_efficiency, collector_performance.coefficient1ofEfficiencyEquation, 0.01)
    assert_in_epsilon(collector_coeff_2, collector_performance.coefficient2ofEfficiencyEquation, 0.01)
    assert_in_epsilon(-iam_coeff2, collector_performance.coefficient2ofIncidentAngleModifier.get, 0.01)
    assert_in_epsilon(iam_coeff3, collector_performance.coefficient3ofIncidentAngleModifier.get, 0.01)

    collector_attached_to_tank = false
    loop = nil
    model.getPlantLoops.each do |plant_loop|
      next if plant_loop.supplyComponents.select { |comp| comp == collector }.empty?
      next if plant_loop.demandComponents.select { |comp| comp == preheat_tank }.empty?

      collector_attached_to_tank = true
      assert_equal(plant_loop.fluidType, EPlus::FluidWater)
      loop = plant_loop
    end
    pump = loop.supplyComponents.find { |comp| comp.to_PumpConstantSpeed.is_initialized }
    assert_equal(pump_power, pump.to_PumpConstantSpeed.get.ratedPowerConsumption.get)
    assert_equal(collector_attached_to_tank, true)
  end

  def test_solar_direct_ics
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-solar-direct-ics.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]
    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.97
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    loc = water_heating_system.location
    hx_eff = 1.0

    collector_area = UnitConversions.convert(solar_thermal_system.collector_area, 'ft^2', 'm^2')
    collector_storage_volume = UnitConversions.convert(solar_thermal_system.storage_volume, 'gal', 'm^3')
    ther_eff = 1.0
    storage_tank_volume = 0.2271
    storage_tank_height = UnitConversions.convert(4.5, 'ft', 'm')
    storage_tank_u = 0.0
    pump_power = 0.8 * solar_thermal_system.collector_area

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size) # preheat tank + water heater
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check solar thermal system
    assert_equal(1, model.getSolarCollectorIntegralCollectorStorages.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    preheat_tank = model.getWaterHeaterStratifieds[0]
    assert_in_epsilon(storage_tank_volume, preheat_tank.tankVolume.get, 0.01)
    assert_in_epsilon(storage_tank_height, preheat_tank.tankHeight.get, 0.01)
    assert_in_epsilon(hx_eff, preheat_tank.sourceSideEffectiveness, 0.01)
    assert_in_epsilon(storage_tank_u, preheat_tank.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.01)

    collector = model.getSolarCollectorIntegralCollectorStorages[0]
    collector_performance = collector.solarCollectorPerformance
    assert_in_epsilon(collector_area, collector_performance.grossArea, 0.01)
    assert_in_epsilon(collector_storage_volume, collector_performance.collectorWaterVolume, 0.01)

    collector_attached_to_tank = false
    loop = nil
    model.getPlantLoops.each do |plant_loop|
      next if plant_loop.supplyComponents.select { |comp| comp == collector }.empty?
      next if plant_loop.demandComponents.select { |comp| comp == preheat_tank }.empty?

      collector_attached_to_tank = true
      assert_equal(plant_loop.fluidType, EPlus::FluidWater)
      loop = plant_loop
    end
    pump = loop.supplyComponents.find { |comp| comp.to_PumpConstantSpeed.is_initialized }
    assert_equal(pump_power, pump.to_PumpConstantSpeed.get.ratedPowerConsumption.get)
    assert_equal(collector_attached_to_tank, true)
  end

  def test_solar_fraction
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-solar-fraction.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.34
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 1.0
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_indirect
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-indirect.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = 0.0
    ua = 2.47
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    tank_attached_to_boiler = false
    model.getPlantLoops.each do |plant_loop|
      next if plant_loop.demandComponents.select { |comp| comp == wh }.empty?
      next if plant_loop.supplyComponents.select { |comp| comp.name.get.include? 'boiler' }.empty?

      tank_attached_to_boiler = true
    end
    assert_equal(tank_attached_to_boiler, true)
  end

  def test_tank_combi_tankless
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-combi-tankless.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(1, 'gal', 'm^3') # convert to actual volume
    cap = 0.0
    ua = 0.0
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C')
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_equal('Modulate', wh.heaterControlType)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    tank_attached_to_boiler = false
    model.getPlantLoops.each do |plant_loop|
      next if plant_loop.demandComponents.select { |comp| comp == wh }.empty?
      next if plant_loop.supplyComponents.select { |comp| comp.name.get.include? 'boiler' }.empty?

      tank_attached_to_boiler = true
    end
    assert_equal(tank_attached_to_boiler, true)
  end

  def test_tank_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tank-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    u = 0.926
    ther_eff = 1.0
    cop = 3.731
    tank_height = 1.3343
    cap = 500.0 * cop # W
    backup_cap = 4500.0 # W

    # Check water heater
    assert_equal(1, model.getWaterHeaterHeatPumpWrappedCondensers.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    hpwh = model.getWaterHeaterHeatPumpWrappedCondensers[0]
    wh = hpwh.tank.to_WaterHeaterStratified.get
    coil = hpwh.dXCoil.to_CoilWaterHeatingAirToWaterHeatPumpWrapped.get
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal('Schedule', wh.ambientTemperatureIndicator)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(tank_height, wh.tankHeight.get, 0.01)
    assert_in_epsilon(backup_cap, wh.heater1Capacity.get, 0.01)
    assert_in_epsilon(backup_cap, wh.heater2Capacity, 0.01)
    assert_in_epsilon(u, wh.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency, 0.01)

    # Check heat pump cooling coil cop
    assert_in_epsilon(cop, coil.ratedCOP, 0.01)
    assert_in_epsilon(cap, coil.ratedHeatingCapacity, 0.01)
  end

  def test_tank_heat_pump_ef
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tank-heat-pump-ef.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    u = 0.92
    ther_eff = 1.0
    cop = 3.60
    tank_height = 1.5975
    cap = 500.0 * cop # W
    backup_cap = 4500.0 # W

    # Check water heater
    assert_equal(1, model.getWaterHeaterHeatPumpWrappedCondensers.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    hpwh = model.getWaterHeaterHeatPumpWrappedCondensers[0]
    wh = hpwh.tank.to_WaterHeaterStratified.get
    coil = hpwh.dXCoil.to_CoilWaterHeatingAirToWaterHeatPumpWrapped.get
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal('Schedule', wh.ambientTemperatureIndicator)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(tank_height, wh.tankHeight.get, 0.01)
    assert_in_epsilon(backup_cap, wh.heater1Capacity.get, 0.01)
    assert_in_epsilon(backup_cap, wh.heater2Capacity, 0.01)
    assert_in_epsilon(u, wh.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency, 0.01)

    # Check heat pump cooling coil cop
    assert_in_epsilon(cop, coil.ratedCOP, 0.01)
    assert_in_epsilon(cap, coil.ratedHeatingCapacity, 0.01)
  end

  def test_tank_heat_pump_capacities
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tank-heat-pump-capacities.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    u = 0.926
    ther_eff = 1.0
    cop = 3.731
    tank_height = 1.3343
    cap = UnitConversions.convert(water_heating_system.heating_capacity, 'Btu/hr', 'W') # W
    backup_cap = UnitConversions.convert(water_heating_system.backup_heating_capacity, 'Btu/hr', 'W') # W

    # Check water heater
    assert_equal(1, model.getWaterHeaterHeatPumpWrappedCondensers.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    hpwh = model.getWaterHeaterHeatPumpWrappedCondensers[0]
    wh = hpwh.tank.to_WaterHeaterStratified.get
    coil = hpwh.dXCoil.to_CoilWaterHeatingAirToWaterHeatPumpWrapped.get
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal('Schedule', wh.ambientTemperatureIndicator)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(tank_height, wh.tankHeight.get, 0.01)
    assert_in_epsilon(backup_cap, wh.heater1Capacity.get, 0.01)
    assert_in_epsilon(backup_cap, wh.heater2Capacity, 0.01)
    assert_in_epsilon(u, wh.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency, 0.01)

    # Check heat pump cooling coil cop
    assert_in_epsilon(cop, coil.ratedCOP, 0.01)
    assert_in_epsilon(cap, coil.ratedHeatingCapacity, 0.01)
  end

  def test_tank_heat_pump_containment_volume_adjustment
    # Volumes are based on RESNET spreadsheet: https://github.com/user-attachments/files/23135608/ConstrainedHPWH_04xlsx.xlsx,
    containment_volumes = [3000, 1500, 960, 707, 453, 200, 83.5]
    # Replaced the COP in the spreadsheet to 3.73135, and the expected COP are calculated as below:
    expected_cop = [3.720, 3.720, 3.647, 3.518, 3.191, 2.367, 1.642]
    expected_cap = 500.0 * 3.73135 # not adjusted
    args_hash = {}
    args_hash['hpxml_path'] = @tmp_hpxml_path
    containment_volumes.each_with_index do |v, i|
      hpxml, hpxml_bldg = _create_hpxml('base-dhw-tank-heat-pump-confined-space.xml')
      hpxml_bldg.water_heating_systems[0].hpwh_containment_volume = v
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)
      # Get HPXML values
      water_heating_system = hpxml_bldg.water_heating_systems[0]
      # Check EnergyPlus inputs
      assert_equal(1, model.getWaterHeaterHeatPumpWrappedCondensers.size)
      assert_equal(1, model.getWaterHeaterStratifieds.size)
      hpwh = model.getWaterHeaterHeatPumpWrappedCondensers[0]
      wh = hpwh.tank.to_WaterHeaterStratified.get
      coil = hpwh.dXCoil.to_CoilWaterHeatingAirToWaterHeatPumpWrapped.get
      assert_equal(EPlus.fuel_type(water_heating_system.fuel_type), wh.heaterFuelType)
      assert_equal('Schedule', wh.ambientTemperatureIndicator)
      assert_in_epsilon(UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3'), wh.tankVolume.get, 0.01)
      assert_in_epsilon(1.3343, wh.tankHeight.get, 0.01)
      assert_in_epsilon(UnitConversions.convert(water_heating_system.backup_heating_capacity, 'Btu/hr', 'W'), wh.heater1Capacity.get, 0.01)
      assert_in_epsilon(UnitConversions.convert(water_heating_system.backup_heating_capacity, 'Btu/hr', 'W'), wh.heater2Capacity, 0.01)
      assert_in_epsilon(0.926, wh.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.01)
      assert_in_epsilon(1.0, wh.heaterThermalEfficiency, 0.01)
      # Check heat pump cooling coil cop being adjusted
      assert_in_epsilon(expected_cop[i], coil.ratedCOP, 0.01)
      assert_in_epsilon(expected_cap, coil.ratedHeatingCapacity, 0.01)
    end
  end

  def test_tank_jacket
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-jacket-electric.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.56
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 1.0
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_shared_water_heater
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-water-heater.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.56
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)

    # zero bedroom
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-water-heater-recirc-beds-0.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
  end

  def test_shared_water_heater_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-water-heater-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    u =  0.1081
    ther_eff = 1.0
    cop = 3.73
    tank_height = 2.3495
    cap = 500.0 * cop # W
    backup_cap = 4500.0 # W

    # Check water heater
    assert_equal(1, model.getWaterHeaterHeatPumpWrappedCondensers.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    hpwh = model.getWaterHeaterHeatPumpWrappedCondensers[0]
    wh = hpwh.tank.to_WaterHeaterStratified.get
    coil = hpwh.dXCoil.to_CoilWaterHeatingAirToWaterHeatPumpWrapped.get
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal('Schedule', wh.ambientTemperatureIndicator)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(tank_height, wh.tankHeight.get, 0.01)
    assert_in_epsilon(backup_cap, wh.heater1Capacity.get, 0.01)
    assert_in_epsilon(backup_cap, wh.heater2Capacity, 0.01)
    assert_in_epsilon(u, wh.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency, 0.01)

    # Check heat pump cooling coil cop
    assert_in_epsilon(cop, coil.ratedCOP, 0.01)
    assert_in_epsilon(cap, coil.ratedHeatingCapacity, 0.01)
  end

  def test_shared_laundry_room
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-laundry-room.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.69
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.01)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.01)
  end

  def test_tank_heat_pump_operating_mode_heat_pump_only
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tank-heat-pump-operating-mode-heat-pump-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    u = 0.925
    ther_eff = 1.0
    cop = 3.60
    tank_height = 1.5975
    cap = 500.0 * cop # W
    backup_cap = 4500.0 # W

    # Check water heater
    assert_equal(1, model.getWaterHeaterHeatPumpWrappedCondensers.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    hpwh = model.getWaterHeaterHeatPumpWrappedCondensers[0]
    wh = hpwh.tank.to_WaterHeaterStratified.get
    coil = hpwh.dXCoil.to_CoilWaterHeatingAirToWaterHeatPumpWrapped.get
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal('Schedule', wh.ambientTemperatureIndicator)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(tank_height, wh.tankHeight.get, 0.01)
    assert_in_epsilon(backup_cap, wh.heater1Capacity.get, 0.01)
    assert_in_epsilon(backup_cap, wh.heater2Capacity, 0.01)
    assert_in_epsilon(u, wh.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency, 0.01)

    # Check heat pump cooling coil cop
    assert_in_epsilon(cop, coil.ratedCOP, 0.01)
    assert_in_epsilon(cap, coil.ratedHeatingCapacity, 0.01)
  end

  def test_tank_stratified
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-tank-model-type-stratified.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    u = 0.513
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 1.0
    tank_height = 1.2192
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    loc = water_heating_system.location

    # Check water heater
    assert_equal(0, model.getWaterHeaterHeatPumpWrappedCondensers.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    wh = model.getWaterHeaterStratifieds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.01)
    assert_in_epsilon(tank_height, wh.tankHeight.get, 0.01)
    assert_in_epsilon(cap, wh.heater1Capacity.get, 0.01)
    assert_in_epsilon(cap, wh.heater2Capacity, 0.01)
    assert_in_epsilon(u, wh.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.01)
    assert_in_epsilon(t_set, wh.heater1SetpointTemperatureSchedule.to_ScheduleConstant.get.value, 0.01)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency, 0.01)
  end

  def test_setpoint_temperature
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-setpoint-temperature.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.01)
  end

  def _test_measure(args_hash)
    # create an instance of the measure
    measure = HPXMLtoOpenStudio.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    args_hash['output_dir'] = File.dirname(__FILE__)
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

    # show the output
    result.showOutput() unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    hpxml_defaults_path = File.join(File.dirname(__FILE__), 'in.xml')
    if args_hash['hpxml_path'] == @tmp_hpxml_path
      # Since there is a penalty to performing schema/schematron validation, we only do it for custom models
      # Sample files already have their in.xml's checked in the workflow tests
      schema_validator = @schema_validator
      schematron_validator = @schematron_validator
    else
      schema_validator = nil
      schematron_validator = nil
    end
    hpxml = HPXML.new(hpxml_path: hpxml_defaults_path, schema_validator: schema_validator, schematron_validator: schematron_validator)
    if not hpxml.errors.empty?
      puts 'ERRORS:'
      hpxml.errors.each do |error|
        puts error
      end
      flunk "Validation error(s) in #{hpxml_defaults_path}."
    end

    File.delete(hpxml_defaults_path)

    return model, hpxml, hpxml.buildings[0]
  end

  def _create_hpxml(hpxml_name)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
    return hpxml, hpxml.buildings[0]
  end
end
