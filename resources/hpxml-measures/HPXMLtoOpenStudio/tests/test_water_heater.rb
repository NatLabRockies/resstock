# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'

class HPXMLtoOpenStudioWaterHeaterTest < Minitest::Test
  def teardown
    File.delete(File.join(File.dirname(__FILE__), 'in.schedules.csv')) if File.exist? File.join(File.dirname(__FILE__), 'in.schedules.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_annual.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_annual.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_design_load_details.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_design_load_details.csv')
  end

  def sample_files_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files')
  end

  def test_tank_gas
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tank-gas.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(7.88, 'Btu/(hr*F)', 'W/K')
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(0.64, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_gas_uef
    ['base-dhw-tank-gas-uef.xml', 'base-dhw-tank-gas-uef-fhr.xml'].each do |hpxml_name|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, hpxml_name))
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)

      # Get HPXML values
      water_heating_system = hpxml_bldg.water_heating_systems[0]

      # Expected value
      tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
      cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
      fuel = EPlus.fuel_type(water_heating_system.fuel_type)
      ua = UnitConversions.convert(6.476, 'Btu/(hr*F)', 'W/K')
      t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
      ther_eff = 0.762
      loc = water_heating_system.location

      # Check water heater
      assert_equal(1, model.getWaterHeaterMixeds.size)
      wh = model.getWaterHeaterMixeds[0]
      assert_equal(fuel, wh.heaterFuelType)
      assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
      assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
      assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
      assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
      assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
      assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
      assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
      assert_equal(0.64, wh.offCycleLossFractiontoThermalZone)
    end
  end

  def test_tank_oil
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tank-oil.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(7.88, 'Btu/(hr*F)', 'W/K')
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(0.64, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_wood
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tank-wood.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(7.88, 'Btu/(hr*F)', 'W/K')
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(0.64, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_coal
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tank-coal.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(7.88, 'Btu/(hr*F)', 'W/K')
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(0.64, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_electric
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(1.335, 'Btu/(hr*F)', 'W/K')
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 1.0
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_electric_uef
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tank-elec-uef.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(1.503, 'Btu/(hr*F)', 'W/K')
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 1.0
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tankless_electric
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tankless-electric.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(1.0, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(100000000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = 0.0
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C')
    ther_eff = 0.9108
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tankless_electric_uef
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tankless-electric-uef.xml'))
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tankless_gas_uef
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tankless-gas-uef.xml'))
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_outside
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tank-gas-outside.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(7.88, 'Btu/(hr*F)', 'W/K')
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal('Outdoors', wh.ambientTemperatureIndicator)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
  end

  def test_dsh_1_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-desuperheater.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(1.335, 'Btu/(hr*F)', 'W/K')
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    loc = water_heating_system.location
    ther_eff = 1.0

    # Check water heater
    assert_equal(2, model.getWaterHeaterMixeds.size) # preheat tank + water heater
    wh = model.getWaterHeaterMixeds.find { |wh| (not wh.name.get.include? 'storage tank') }
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check desuperheater
    assert_equal(1, model.getCoilWaterHeatingDesuperheaters.size)
    preheat_tank = model.getWaterHeaterMixeds.find { |wh| wh.name.get.include? 'storage tank' }
    dsh_coil = model.getCoilWaterHeatingDesuperheaters[0]
    assert_equal(true, dsh_coil.heatingSource.get.to_CoilCoolingDXSingleSpeed.is_initialized)
    assert_equal(preheat_tank, dsh_coil.heatRejectionTarget.get.to_WaterHeaterMixed.get)
  end

  def test_dsh_var_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-desuperheater-var-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(1.335, 'Btu/(hr*F)', 'W/K')
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    loc = water_heating_system.location
    ther_eff = 1.0

    # Check water heater
    assert_equal(2, model.getWaterHeaterMixeds.size) # preheat tank + water heater
    wh = model.getWaterHeaterMixeds.find { |wh| (not wh.name.get.include? 'storage tank') }
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check desuperheater
    assert_equal(1, model.getCoilWaterHeatingDesuperheaters.size)
    preheat_tank = model.getWaterHeaterMixeds.find { |wh| wh.name.get.include? 'storage tank' }
    dsh_coil = model.getCoilWaterHeatingDesuperheaters[0]
    assert_equal(true, dsh_coil.heatingSource.get.to_CoilCoolingDXMultiSpeed.is_initialized)
    assert_equal(preheat_tank, dsh_coil.heatRejectionTarget.get.to_WaterHeaterMixed.get)
  end

  def test_dsh_gshp
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-desuperheater-ghp.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(1.335, 'Btu/(hr*F)', 'W/K')
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    loc = water_heating_system.location
    ther_eff = 1.0

    # Check water heater
    assert_equal(2, model.getWaterHeaterMixeds.size) # preheat tank + water heater
    wh = model.getWaterHeaterMixeds.find { |wh| (not wh.name.get.include? 'storage tank') }
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check desuperheater
    assert_equal(1, model.getCoilWaterHeatingDesuperheaters.size)
    preheat_tank = model.getWaterHeaterMixeds.find { |wh| wh.name.get.include? 'storage tank' }
    dsh_coil = model.getCoilWaterHeatingDesuperheaters[0]
    assert_equal(true, dsh_coil.heatingSource.get.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized)
    assert_equal(preheat_tank, dsh_coil.heatRejectionTarget.get.to_WaterHeaterMixed.get)
  end

  def test_solar_direct_evacuated_tube
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-solar-direct-evacuated-tube.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]
    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(1.335, 'Btu/(hr*F)', 'W/K')
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check solar thermal system
    assert_equal(1, model.getSolarCollectorFlatPlateWaters.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    preheat_tank = model.getWaterHeaterStratifieds[0]
    assert_in_epsilon(storage_tank_volume, preheat_tank.tankVolume.get, 0.001)
    assert_in_epsilon(storage_tank_height, preheat_tank.tankHeight.get, 0.001)
    assert_in_epsilon(hx_eff, preheat_tank.sourceSideEffectiveness, 0.001)
    assert_in_epsilon(storage_tank_u, preheat_tank.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.001)

    collector = model.getSolarCollectorFlatPlateWaters[0]
    collector_performance = collector.solarCollectorPerformance
    assert_in_epsilon(collector_area, collector_performance.grossArea, 0.001)
    assert_in_epsilon(solar_thermal_system.collector_rated_optical_efficiency, collector_performance.coefficient1ofEfficiencyEquation, 0.001)
    assert_in_epsilon(collector_coeff_2, collector_performance.coefficient2ofEfficiencyEquation, 0.001)
    assert_in_epsilon(-iam_coeff2, collector_performance.coefficient2ofIncidentAngleModifier.get, 0.001)
    assert_in_epsilon(iam_coeff3, collector_performance.coefficient3ofIncidentAngleModifier.get, 0.001)

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
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-solar-direct-flat-plate.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]
    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(1.335, 'Btu/(hr*F)', 'W/K')
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check solar thermal system
    assert_equal(1, model.getSolarCollectorFlatPlateWaters.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    preheat_tank = model.getWaterHeaterStratifieds[0]
    assert_in_epsilon(storage_tank_volume, preheat_tank.tankVolume.get, 0.001)
    assert_in_epsilon(storage_tank_height, preheat_tank.tankHeight.get, 0.001)
    assert_in_epsilon(hx_eff, preheat_tank.sourceSideEffectiveness, 0.001)
    assert_in_epsilon(storage_tank_u, preheat_tank.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.001)

    collector = model.getSolarCollectorFlatPlateWaters[0]
    collector_performance = collector.solarCollectorPerformance
    assert_in_epsilon(collector_area, collector_performance.grossArea, 0.001)
    assert_in_epsilon(solar_thermal_system.collector_rated_optical_efficiency, collector_performance.coefficient1ofEfficiencyEquation, 0.001)
    assert_in_epsilon(collector_coeff_2, collector_performance.coefficient2ofEfficiencyEquation, 0.001)
    assert_in_epsilon(-iam_coeff2, collector_performance.coefficient2ofIncidentAngleModifier.get, 0.001)
    assert_in_epsilon(iam_coeff3, collector_performance.coefficient3ofIncidentAngleModifier.get, 0.001)

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
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-solar-indirect-flat-plate.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]
    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(1.335, 'Btu/(hr*F)', 'W/K')
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check solar thermal system
    assert_equal(1, model.getSolarCollectorFlatPlateWaters.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    preheat_tank = model.getWaterHeaterStratifieds[0]
    assert_in_epsilon(storage_tank_volume, preheat_tank.tankVolume.get, 0.001)
    assert_in_epsilon(storage_tank_height, preheat_tank.tankHeight.get, 0.001)
    assert_in_epsilon(hx_eff, preheat_tank.sourceSideEffectiveness, 0.001)
    assert_in_epsilon(storage_tank_u, preheat_tank.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.001)

    collector = model.getSolarCollectorFlatPlateWaters[0]
    collector_performance = collector.solarCollectorPerformance
    assert_in_epsilon(collector_area, collector_performance.grossArea, 0.001)
    assert_in_epsilon(solar_thermal_system.collector_rated_optical_efficiency, collector_performance.coefficient1ofEfficiencyEquation, 0.001)
    assert_in_epsilon(collector_coeff_2, collector_performance.coefficient2ofEfficiencyEquation, 0.001)
    assert_in_epsilon(-iam_coeff2, collector_performance.coefficient2ofIncidentAngleModifier.get, 0.001)
    assert_in_epsilon(iam_coeff3, collector_performance.coefficient3ofIncidentAngleModifier.get, 0.001)

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
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-solar-thermosyphon-flat-plate.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]
    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(1.335, 'Btu/(hr*F)', 'W/K')
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check solar thermal system
    assert_equal(1, model.getSolarCollectorFlatPlateWaters.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    preheat_tank = model.getWaterHeaterStratifieds[0]
    assert_in_epsilon(storage_tank_volume, preheat_tank.tankVolume.get, 0.001)
    assert_in_epsilon(storage_tank_height, preheat_tank.tankHeight.get, 0.001)
    assert_in_epsilon(hx_eff, preheat_tank.sourceSideEffectiveness, 0.001)
    assert_in_epsilon(storage_tank_u, preheat_tank.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.001)

    collector = model.getSolarCollectorFlatPlateWaters[0]
    collector_performance = collector.solarCollectorPerformance
    assert_in_epsilon(collector_area, collector_performance.grossArea, 0.001)
    assert_in_epsilon(solar_thermal_system.collector_rated_optical_efficiency, collector_performance.coefficient1ofEfficiencyEquation, 0.001)
    assert_in_epsilon(collector_coeff_2, collector_performance.coefficient2ofEfficiencyEquation, 0.001)
    assert_in_epsilon(-iam_coeff2, collector_performance.coefficient2ofIncidentAngleModifier.get, 0.001)
    assert_in_epsilon(iam_coeff3, collector_performance.coefficient3ofIncidentAngleModifier.get, 0.001)

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
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-solar-direct-ics.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]
    solar_thermal_system = hpxml_bldg.solar_thermal_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(1.335, 'Btu/(hr*F)', 'W/K')
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)

    # Check solar thermal system
    assert_equal(1, model.getSolarCollectorIntegralCollectorStorages.size)
    assert_equal(1, model.getWaterHeaterStratifieds.size)
    preheat_tank = model.getWaterHeaterStratifieds[0]
    assert_in_epsilon(storage_tank_volume, preheat_tank.tankVolume.get, 0.001)
    assert_in_epsilon(storage_tank_height, preheat_tank.tankHeight.get, 0.001)
    assert_in_epsilon(hx_eff, preheat_tank.sourceSideEffectiveness, 0.001)
    assert_in_epsilon(storage_tank_u, preheat_tank.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.001)

    collector = model.getSolarCollectorIntegralCollectorStorages[0]
    collector_performance = collector.solarCollectorPerformance
    assert_in_epsilon(collector_area, collector_performance.grossArea, 0.001)
    assert_in_epsilon(collector_storage_volume, collector_performance.collectorWaterVolume, 0.001)

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
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-solar-fraction.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(1.335, 'Btu/(hr*F)', 'W/K') * 0.35
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 1.0
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_tank_indirect
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-indirect.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = 0.0
    ua = UnitConversions.convert(5.056, 'Btu/(hr*F)', 'W/K')
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-combi-tankless.xml'))
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tank-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    u =  0.925
    ther_eff = 1.0
    cop = 2.820
    tank_height = 1.598
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(tank_height, wh.tankHeight.get, 0.001)
    assert_in_epsilon(backup_cap, wh.heater1Capacity.get, 0.001)
    assert_in_epsilon(backup_cap, wh.heater2Capacity, 0.001)
    assert_in_epsilon(u, wh.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency, 0.001)

    # Check heat pump cooling coil cop
    assert_in_epsilon(cop, coil.ratedCOP, 0.001)
    assert_in_epsilon(cap, coil.ratedHeatingCapacity, 0.001)
  end

  def test_tank_heat_pump_uef
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tank-heat-pump-uef.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    u =  1.045
    ther_eff = 1.0
    cop = 4.004
    tank_height = 1.0335
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(tank_height, wh.tankHeight.get, 0.001)
    assert_in_epsilon(backup_cap, wh.heater1Capacity.get, 0.001)
    assert_in_epsilon(backup_cap, wh.heater2Capacity, 0.001)
    assert_in_epsilon(u, wh.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency, 0.001)

    # Check heat pump cooling coil cop
    assert_in_epsilon(cop, coil.ratedCOP, 0.001)
    assert_in_epsilon(cap, coil.ratedHeatingCapacity, 0.001)
  end

  def test_tank_heat_pump_capacities
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tank-heat-pump-capacities.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    u =  0.925
    ther_eff = 1.0
    cop = 2.820
    tank_height = 1.598
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(tank_height, wh.tankHeight.get, 0.001)
    assert_in_epsilon(backup_cap, wh.heater1Capacity.get, 0.001)
    assert_in_epsilon(backup_cap, wh.heater2Capacity, 0.001)
    assert_in_epsilon(u, wh.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency, 0.001)

    # Check heat pump cooling coil cop
    assert_in_epsilon(cop, coil.ratedCOP, 0.001)
    assert_in_epsilon(cap, coil.ratedHeatingCapacity, 0.001)
  end

  def test_tank_jacket
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-jacket-electric.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(0.6415, 'Btu/(hr*F)', 'W/K')
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 1.0
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
    assert_equal(1.0, wh.offCycleLossFractiontoThermalZone)
  end

  def test_shared_water_heater
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-mf-unit-shared-water-heater.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(7.88, 'Btu/(hr*F)', 'W/K') * hpxml_bldg.building_construction.number_of_bedrooms.to_f / water_heating_system.number_of_bedrooms_served
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)

    # zero bedroom
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-mf-unit-shared-water-heater-recirc-beds-0.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    ua = UnitConversions.convert(7.88, 'Btu/(hr*F)', 'W/K') * 1.0 / water_heating_system.number_of_bedrooms_served

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
  end

  def test_shared_water_heater_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-mf-unit-shared-water-heater-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    u =  0.1081
    ther_eff = 1.0
    cop = 2.820
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(tank_height, wh.tankHeight.get, 0.001)
    assert_in_epsilon(backup_cap, wh.heater1Capacity.get, 0.001)
    assert_in_epsilon(backup_cap, wh.heater2Capacity, 0.001)
    assert_in_epsilon(u, wh.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency, 0.001)

    # Check heat pump cooling coil cop
    assert_in_epsilon(cop, coil.ratedCOP, 0.001)
    assert_in_epsilon(cap, coil.ratedHeatingCapacity, 0.001)
  end

  def test_shared_laundry_room
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-mf-unit-shared-laundry-room.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.95, 'gal', 'm^3') # convert to actual volume
    cap = UnitConversions.convert(water_heating_system.heating_capacity / 1000.0, 'kBtu/hr', 'W')
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    ua = UnitConversions.convert(7.88, 'Btu/(hr*F)', 'W/K') * hpxml_bldg.building_construction.number_of_bedrooms.to_f / water_heating_system.number_of_bedrooms_served
    t_set = UnitConversions.convert(water_heating_system.temperature, 'F', 'C') + 1 # setpoint + 1/2 deadband
    ther_eff = 0.773
    loc = water_heating_system.location

    # Check water heater
    assert_equal(1, model.getWaterHeaterMixeds.size)
    wh = model.getWaterHeaterMixeds[0]
    assert_equal(fuel, wh.heaterFuelType)
    assert_equal(loc, wh.ambientTemperatureThermalZone.get.name.get)
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(cap, wh.heaterMaximumCapacity.get, 0.001)
    assert_in_epsilon(ua, wh.onCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ua, wh.offCycleLossCoefficienttoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.setpointTemperatureSchedule.get.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency.get, 0.001)
  end

  def test_tank_heat_pump_operating_mode_heat_pump_only
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tank-heat-pump-operating-mode-heat-pump-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    u =  1.045
    ther_eff = 1.0
    cop = 4.004
    tank_height = 1.0335
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(tank_height, wh.tankHeight.get, 0.001)
    assert_in_epsilon(backup_cap, wh.heater1Capacity.get, 0.001)
    assert_in_epsilon(backup_cap, wh.heater2Capacity, 0.001)
    assert_in_epsilon(u, wh.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency, 0.001)

    # Check heat pump cooling coil cop
    assert_in_epsilon(cop, coil.ratedCOP, 0.001)
    assert_in_epsilon(cap, coil.ratedHeatingCapacity, 0.001)
  end

  def test_tank_stratified
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-dhw-tank-model-type-stratified.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    water_heating_system = hpxml_bldg.water_heating_systems[0]

    # Expected value
    tank_volume = UnitConversions.convert(water_heating_system.tank_volume * 0.9, 'gal', 'm^3') # convert to actual volume
    fuel = EPlus.fuel_type(water_heating_system.fuel_type)
    u = 0.422
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
    assert_in_epsilon(tank_volume, wh.tankVolume.get, 0.001)
    assert_in_epsilon(tank_height, wh.tankHeight.get, 0.001)
    assert_in_epsilon(cap, wh.heater1Capacity.get, 0.001)
    assert_in_epsilon(cap, wh.heater2Capacity, 0.001)
    assert_in_epsilon(u, wh.uniformSkinLossCoefficientperUnitAreatoAmbientTemperature.get, 0.001)
    assert_in_epsilon(t_set, wh.heater1SetpointTemperatureSchedule.to_ScheduleConstant.get.value, 0.001)
    assert_in_epsilon(ther_eff, wh.heaterThermalEfficiency, 0.001)
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
    show_output(result) unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])

    File.delete(File.join(File.dirname(__FILE__), 'in.xml'))

    return model, hpxml, hpxml.buildings[0]
  end
end
