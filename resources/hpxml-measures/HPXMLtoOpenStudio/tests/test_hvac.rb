# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioHVACTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    File.delete(File.join(File.dirname(__FILE__), 'in.schedules.csv')) if File.exist? File.join(File.dirname(__FILE__), 'in.schedules.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_annual.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_annual.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_design_load_details.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_design_load_details.csv')
  end

  def test_central_air_conditioner_1_speed
    ['base-hvac-central-ac-only-1-speed.xml',
     'base-hvac-central-ac-only-1-speed-seer2.xml'].each do |hpxml_path|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_path))
      model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

      # Check cooling coil
      assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
      clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
      assert_in_epsilon(3.77, clg_coil.ratedCOP, 0.01)
      assert_in_epsilon(7230, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

      # Check EMS
      assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
      unitary_system = model.getAirLoopHVACUnitarySystems[0]
      program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
      assert(program_values.empty?) # Check no EMS program
    end
  end

  def test_central_air_conditioner_2_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-central-ac-only-2-speed.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [4.95, 4.53].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [5143, 7158].each_with_index do |capacity, i|
      assert_in_epsilon(capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_central_air_conditioner_var_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-central-ac-only-var-speed.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [5.89, 5.25].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [2780, 7169].each_with_index do |capacity, i|
      assert_in_epsilon(capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_central_air_conditioner_var_speed_max_power_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-central-ac-only-var-speed-max-power-ratio-schedule.xml'))
    model, _hpxml = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)

    # Check heating coil
    assert_equal(0, model.getCoilHeatingDXMultiSpeeds.size)

    # Check supp heating coil
    assert_equal(0, model.getCoilHeatingElectrics.size)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    _check_max_power_ratio_EMS_multispeed(model, nil, nil, nil, nil, 2779.53, 5.89, 7168.65, 5.25)
  end

  def test_central_air_conditioner_furnace_var_speed_max_power_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-furnace-gas-central-ac-var-speed-max-power-ratio-schedule.xml'))
    model, _hpxml = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)

    # Check heating coil
    assert_equal(0, model.getCoilHeatingDXMultiSpeeds.size)
    assert_equal(1, model.getCoilHeatingGass.size)

    # Check supp heating coil
    assert_equal(0, model.getCoilHeatingElectrics.size)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    _check_max_power_ratio_EMS_multispeed(model, nil, nil, nil, nil, 2779.53, 5.89, 7168.65, 5.25)
  end

  def test_room_air_conditioner
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-room-ac-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    eer = cooling_system.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.001)
    assert_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)
  end

  def test_room_air_conditioner_ceer
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-room-ac-only-ceer.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    ceer = cooling_system.cooling_efficiency_ceer
    cop = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.001)
    assert_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)
  end

  def test_room_ac_with_heating
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-room-ac-with-heating.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    eer = cooling_system.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    cool_capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    heat_efficiency = cooling_system.integrated_heating_system_efficiency_percent
    heat_efficiency = 1.0 if heat_efficiency.nil?
    heat_capacity = UnitConversions.convert(cooling_system.integrated_heating_system_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.001)
    assert_in_epsilon(cool_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    baseboard = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(heat_efficiency, baseboard.efficiency, 0.01)
    assert_in_epsilon(heat_capacity, baseboard.nominalCapacity.get, 0.01)
  end

  def test_ptac
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ptac.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    eer = cooling_system.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.001)
    assert_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)
  end

  def test_ptac_with_heating_electricity
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ptac-with-heating-electricity.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    eer = cooling_system.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    cool_capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    heat_efficiency = cooling_system.integrated_heating_system_efficiency_percent
    heat_efficiency = 1.0 if heat_efficiency.nil?
    heat_capacity = UnitConversions.convert(cooling_system.integrated_heating_system_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.001)
    assert_in_epsilon(cool_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    baseboard = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(heat_efficiency, baseboard.efficiency, 0.01)
    assert_in_epsilon(heat_capacity, baseboard.nominalCapacity.get, 0.01)
  end

  def test_ptac_with_heating_gas
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ptac-with-heating-electricity.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    eer = cooling_system.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    cool_capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    heat_efficiency = cooling_system.integrated_heating_system_efficiency_percent
    heat_efficiency = 1.0 if heat_efficiency.nil?
    heat_capacity = UnitConversions.convert(cooling_system.integrated_heating_system_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.001)
    assert_in_epsilon(cool_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    baseboard = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(heat_efficiency, baseboard.efficiency, 0.01)
    assert_in_epsilon(heat_capacity, baseboard.nominalCapacity.get, 0.01)
  end

  def test_pthp
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-pthp.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')
    eer = heat_pump.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop_cool = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    cop_heat = heat_pump.heating_efficiency_cop # Expected value

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop_cool, clg_coil.ratedCOP, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    assert_in_epsilon(cop_heat, htg_coil.ratedCOP, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedTotalHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)
  end

  def test_room_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-room-ac-with-reverse-cycle.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')
    eer = heat_pump.cooling_efficiency_eer
    ceer = eer / 1.01 # convert to ceer
    cop_cool = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    cop_heat = heat_pump.heating_efficiency_cop

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop_cool, clg_coil.ratedCOP, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    assert_in_epsilon(cop_heat, htg_coil.ratedCOP, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedTotalHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)
  end

  def test_evap_cooler
    # TODO
  end

  def test_furnace_gas
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-furnace-gas-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check heating coil
    assert_equal(1, model.getCoilHeatingGass.size)
    htg_coil = model.getCoilHeatingGass[0]
    assert_in_epsilon(afue, htg_coil.gasBurnerEfficiency, 0.01)
    assert_in_epsilon(capacity, htg_coil.nominalCapacity.get, 0.01)
    assert_equal(EPlus.fuel_type(fuel), htg_coil.fuelType)
  end

  def test_furnace_electric
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-furnace-elec-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')

    # Check heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(afue, htg_coil.efficiency, 0.01)
    assert_in_epsilon(capacity, htg_coil.nominalCapacity.get, 0.01)
  end

  def test_boiler_gas
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-boiler-gas-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    assert_in_epsilon(capacity, boiler.nominalCapacity.get, 0.01)
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)
  end

  def test_boiler_coal
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-boiler-coal-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    assert_in_epsilon(capacity, boiler.nominalCapacity.get, 0.01)
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)
  end

  def test_boiler_electric
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-boiler-elec-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    assert_in_epsilon(capacity, boiler.nominalCapacity.get, 0.01)
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)
  end

  def test_electric_resistance
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-elec-resistance-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    efficiency = heating_system.heating_efficiency_percent
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')

    # Check baseboard
    assert_equal(1, model.getZoneHVACBaseboardConvectiveElectrics.size)
    baseboard = model.getZoneHVACBaseboardConvectiveElectrics[0]
    assert_in_epsilon(efficiency, baseboard.efficiency, 0.01)
    assert_in_epsilon(capacity, baseboard.nominalCapacity.get, 0.01)
  end

  def test_stove_oil
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-stove-oil-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    efficiency = heating_system.heating_efficiency_percent
    capacity = UnitConversions.convert(heating_system.heating_capacity, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check heating coil
    assert_equal(1, model.getCoilHeatingGass.size)
    htg_coil = model.getCoilHeatingGass[0]
    assert_in_epsilon(efficiency, htg_coil.gasBurnerEfficiency, 0.01)
    assert_in_epsilon(capacity, htg_coil.nominalCapacity.get, 0.01)
    assert_equal(EPlus.fuel_type(fuel), htg_coil.fuelType)
  end

  def test_air_to_air_heat_pump_1_speed
    ['base-hvac-air-to-air-heat-pump-1-speed.xml',
     'base-hvac-air-to-air-heat-pump-1-speed-seer2-hspf2.xml'].each do |hpxml_path|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_path))
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)

      # Get HPXML values
      heat_pump = hpxml_bldg.heat_pumps[0]
      backup_efficiency = heat_pump.backup_heating_efficiency_percent
      supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

      # Check cooling coil
      assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
      clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
      assert_in_epsilon(3.77, clg_coil.ratedCOP, 0.01)
      assert_in_epsilon(10846, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

      # Check heating coil
      assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
      htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
      assert_in_epsilon(3.29, htg_coil.ratedCOP, 0.01)
      assert_in_epsilon(10262, htg_coil.ratedTotalHeatingCapacity.get, 0.01)

      # Check supp heating coil
      assert_equal(1, model.getCoilHeatingElectrics.size)
      supp_htg_coil = model.getCoilHeatingElectrics[0]
      assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
      assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

      # Check EMS
      assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
      unitary_system = model.getAirLoopHVACUnitarySystems[0]
      program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
      assert(program_values.empty?) # Check no EMS program
    end
  end

  def test_air_to_air_heat_pump_multistage_backup_system
    ['base-hvac-air-to-air-heat-pump-1-speed-research-features.xml',
     'base-hvac-air-to-air-heat-pump-2-speed-research-features.xml'].each do |hpxml_path|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_path))
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)

      # Get HPXML values
      heat_pump = hpxml_bldg.heat_pumps[0]
      backup_efficiency = heat_pump.backup_heating_efficiency_percent
      supp_htg_capacity_increment = 5000 # 5kw
      supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

      # Check cooling coil
      assert_equal(1, (model.getCoilCoolingDXSingleSpeeds.size + model.getCoilCoolingDXMultiSpeeds.size))

      # Check heating coil
      assert_equal(1, (model.getCoilHeatingDXSingleSpeeds.size + model.getCoilHeatingDXMultiSpeeds.size))

      # Check supp heating coil
      assert_equal(1, model.getCoilHeatingElectricMultiStages.size)
      supp_htg_coil = model.getCoilHeatingElectricMultiStages[0]
      supp_htg_coil.stages.each_with_index do |stage, i|
        capacity = [supp_htg_capacity_increment * (i + 1), supp_htg_capacity].min
        assert_in_epsilon(capacity, stage.nominalCapacity.get, 0.01)
        assert_in_epsilon(backup_efficiency, stage.efficiency, 0.01)
      end

      # Check EMS
      assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
      unitary_system = model.getAirLoopHVACUnitarySystems[0]
      program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
      assert(program_values.empty?) # Check no EMS program
    end
  end

  def test_heat_pump_temperatures
    ['base-hvac-air-to-air-heat-pump-1-speed.xml',
     'base-hvac-air-to-air-heat-pump-1-speed-lockout-temperatures.xml',
     'base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml',
     'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
     'base-hvac-mini-split-heat-pump-ductless.xml',
     'base-hvac-mini-split-heat-pump-ductless-backup-baseboard.xml'].each do |hpxml_name|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_name))
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)

      # Get HPXML values
      heat_pump = hpxml_bldg.heat_pumps[0]
      if not heat_pump.backup_heating_switchover_temp.nil?
        backup_lockout_temp = UnitConversions.convert(heat_pump.backup_heating_switchover_temp, 'F', 'C')
        compressor_lockout_temp = UnitConversions.convert(heat_pump.backup_heating_switchover_temp, 'F', 'C')
      else
        if not heat_pump.backup_heating_lockout_temp.nil?
          backup_lockout_temp = UnitConversions.convert(heat_pump.backup_heating_lockout_temp, 'F', 'C')
        end
        if not heat_pump.compressor_lockout_temp.nil?
          compressor_lockout_temp = UnitConversions.convert(heat_pump.compressor_lockout_temp, 'F', 'C')
        end
      end

      # Check unitary system
      assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
      unitary_system = model.getAirLoopHVACUnitarySystems[0]
      if not backup_lockout_temp.nil?
        assert_in_delta(backup_lockout_temp, unitary_system.maximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation, 0.01)
      end

      # Check coil
      assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size + model.getCoilHeatingDXMultiSpeeds.size)
      if not compressor_lockout_temp.nil?
        heating_coil = model.getCoilHeatingDXSingleSpeeds.size > 0 ? model.getCoilHeatingDXSingleSpeeds[0] : model.getCoilHeatingDXMultiSpeeds[0]
        assert_in_delta(compressor_lockout_temp, heating_coil.minimumOutdoorDryBulbTemperatureforCompressorOperation, 0.01)
      end
    end
  end

  def test_air_to_air_heat_pump_2_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-2-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [4.95, 4.53].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [7715, 10736].each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)
    [4.52, 3.93].each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    [7499, 10360].each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_air_to_air_heat_pump_var_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [5.39, 4.77].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [4169, 10753].each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)
    [4.41, 3.74].each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    [3876, 10634].each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_air_to_air_heat_pump_var_speed_detailed_performance
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed-detailed-performance.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [4.51, 2.80].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [3494, 10721].each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)
    [4.70, 3.54].each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    [2898, 10324].each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end

    # Check supp heating coil
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_air_to_air_heat_pump_var_speed_max_power_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed-research-features.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    _check_max_power_ratio_EMS_multispeed(model, 3875.80, 4.41, 10634.05, 3.74, 4169.30, 5.39, 10752.98, 4.77)

    # two systems
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed-max-power-ratio-schedule-two-systems.xml'))
    model, _hpxml = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(2, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil_1 = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil_1.stages.size)
    clg_coil_2 = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil_2.stages.size)

    # Check heating coil
    assert_equal(2, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil_1 = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil_1.stages.size)
    htg_coil_2 = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil_2.stages.size)

    # Check supp heating coil
    assert_equal(2, model.getCoilHeatingElectrics.size)

    # Check EMS
    assert_equal(2, model.getAirLoopHVACUnitarySystems.size)
    _check_max_power_ratio_EMS_multispeed(model, 3875.80, 4.41, 10634.05, 3.74, 4169.30, 5.39, 10752.98, 4.77, 2, 0)
    _check_max_power_ratio_EMS_multispeed(model, 3875.80, 4.41, 10634.05, 3.74, 4169.30, 5.39, 10752.98, 4.77, 2, 1)
  end

  def test_air_to_air_heat_pump_1_speed_onoff_thermostat
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed-research-features.xml'))
    model, hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectricMultiStages.size)

    # E+ thermostat
    onoff_thermostat_deadband = hpxml.header.hvac_onoff_thermostat_deadband
    assert_equal(1, model.getThermostatSetpointDualSetpoints.size)
    thermostat_setpoint = model.getThermostatSetpointDualSetpoints[0]
    assert_in_epsilon(UnitConversions.convert(onoff_thermostat_deadband, 'deltaF', 'deltaC'), thermostat_setpoint.temperatureDifferenceBetweenCutoutAndSetpoint)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    _check_onoff_thermostat_EMS(model, htg_coil, 0.694, 0.474, -0.168, 2.185, -1.943, 0.757)
    _check_onoff_thermostat_EMS(model, clg_coil, 0.719, 0.418, -0.137, 1.143, -0.139, -0.00405)

    # Onoff thermostat with detailed setpoints
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-room-ac-only-research-features.xml'))
    model, hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]

    # E+ thermostat
    onoff_thermostat_deadband = hpxml.header.hvac_onoff_thermostat_deadband
    assert_equal(1, model.getThermostatSetpointDualSetpoints.size)
    thermostat_setpoint = model.getThermostatSetpointDualSetpoints[0]
    assert_in_epsilon(UnitConversions.convert(onoff_thermostat_deadband, 'deltaF', 'deltaC'), thermostat_setpoint.temperatureDifferenceBetweenCutoutAndSetpoint)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    _check_onoff_thermostat_EMS(model, clg_coil, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
  end

  def test_heat_pump_advanced_defrost
    # Var Speed heat pump test
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed-research-features.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_fuel = EPlus.fuel_type(heat_pump.backup_heating_fuel)

    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    # q_dot smaller than backup capacity
    _check_advanced_defrost(model, htg_coil, 4747.75, 4747.75, backup_fuel, 0.06667, 1199.87)

    # Single Speed heat pump test
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed-research-features.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_fuel = EPlus.fuel_type(heat_pump.backup_heating_fuel)

    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    # q_dot smaller than backup capacity
    _check_advanced_defrost(model, htg_coil, 4747.75, 4747.75, backup_fuel, 0.1, 1391.6)

    # Ductless heat pump test
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-heat-pump-ductless-advanced-defrost.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    backup_fuel = EPlus.fuel_type(HPXML::FuelTypeElectricity)

    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    # q_dot smaller than backup capacity
    _check_advanced_defrost(model, htg_coil, 0.0, 0.0, backup_fuel, 0.06667, 4028.7)

    # Dual fuel heat pump test
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-dual-fuel-air-to-air-heat-pump-2-speed-advanced-defrost.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_fuel = EPlus.fuel_type(heat_pump.backup_heating_fuel)
    supp_htg_power = 4747.75 / 0.95

    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    # q_dot smaller than backup capacity
    _check_advanced_defrost(model, htg_coil, supp_htg_power, 4747.75, backup_fuel, 0.06667, 1218)

    # Separate backup heat pump test
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed-backup-boiler-advanced-defrost.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    backup_heating_system = hpxml_bldg.heating_systems[0]
    backup_fuel = EPlus.fuel_type(backup_heating_system.heating_system_fuel)
    supp_htg_power = 2373.9 / 0.8

    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    # q_dot smaller than backup capacity
    _check_advanced_defrost(model, htg_coil, supp_htg_power, 2373.9, backup_fuel, 0.06667, 569)

    # Small capacity test
    args_hash = {}
    args_hash['hpxml_path'] = @tmp_hpxml_path
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-research-features.xml')
    hpxml_bldg.heat_pumps[0].cooling_capacity = 1000
    hpxml_bldg.heat_pumps[0].heating_capacity = 1000
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]

    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    supp_htg_power = 131.88
    backup_fuel = EPlus.fuel_type(heat_pump.backup_heating_fuel)
    # q_dot smaller than backup capacity
    _check_advanced_defrost(model, htg_coil, supp_htg_power, 131.88, backup_fuel, 0.1, 36.85)
  end

  def test_mini_split_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-heat-pump-ductless.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [4.40, 3.20].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [2691, 10606].each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)
    [4.34, 3.10].each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    [3273, 12890].each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end

    # Check supp heating coil
    assert_equal(0, model.getCoilHeatingElectrics.size)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_mini_split_heat_pump_detailed_performance
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-heat-pump-ductless-detailed-performance.xml'))
    model, _hpxml = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [3.77, 2.49].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [2668, 10720].each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)
    [3.48, 2.79].each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    [3339, 13519].each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end

    # Check supp heating coil
    assert_equal(0, model.getCoilHeatingElectrics.size)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_mini_split_heat_pump_max_power_ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-heat-pump-ducted-max-power-ratio-schedule.xml'))
    model, _hpxml = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    _check_max_power_ratio_EMS_multispeed(model, 3304.36, 4.39, 10634.05, 3.74, 4169.30, 4.64, 10752.98, 4.07)
  end

  def test_mini_split_air_conditioner
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-air-conditioner-only-ductless.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    [4.40, 3.23].each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    [1794, 7086].each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_ground_to_air_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ground-to-air-heat-pump-1-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    _check_ghp_standard(model, heat_pump, 5.84, 3.94, 962, [12.5, -1.3], [20, 31])

    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ground-to-air-heat-pump-2-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    _check_ghp_standard(model, heat_pump, 7.52, 4.44, 962, [12.5, -1.3], [20, 31])

    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ground-to-air-heat-pump-var-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    _check_ghp_standard(model, heat_pump, 12.79, 4.94, 962, [12.5, -1.3], [20, 31])

    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ground-to-air-heat-pump-1-speed-experimental.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    _check_ghp_experimental(model, heat_pump, [10550.56], [10550.56], [5.84], [3.94], 962, [12.5, -1.3], [20, 31])

    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ground-to-air-heat-pump-2-speed-experimental.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    _check_ghp_experimental(model, heat_pump, [7757.83, 10550.56], [7779.98, 10550.56], [8.29, 7.52], [5.15, 4.44], 962, [12.5, -1.3], [20, 31])

    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ground-to-air-heat-pump-var-speed-experimental.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    _check_ghp_experimental(model, heat_pump, [5066.38, 10550.56], [4719.26, 10550.56], [13.55, 12.79], [5.69, 4.94], 962, [12.5, -1.3], [20, 31])
  end

  def test_ground_to_air_heat_pump_integrated_backup
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ground-to-air-heat-pump-backup-integrated.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')
    supp_htg_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpEquationFits.size)
    clg_coil = model.getCoilCoolingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(5.84, clg_coil.ratedCoolingCoefficientofPerformance, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpEquationFits.size)
    htg_coil = model.getCoilHeatingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(3.94, htg_coil.ratedHeatingCoefficientofPerformance, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(supp_htg_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program

    # Check ghx
    assert(1, model.getGroundHeatExchangerVerticals.size)
    ghx = model.getGroundHeatExchangerVerticals[0]

    # Check xing
    assert(1, model.getSiteGroundTemperatureUndisturbedXings.size)
    xing = model.getSiteGroundTemperatureUndisturbedXings[0]
    assert_in_epsilon(ghx.groundThermalConductivity.get, xing.soilThermalConductivity, 0.01)
    assert_in_epsilon(962, xing.soilDensity, 0.01)
    assert_in_epsilon(ghx.groundThermalHeatCapacity.get / xing.soilDensity, xing.soilSpecificHeat, 0.01)
    assert_in_epsilon(ghx.groundTemperature.get, xing.averageSoilSurfaceTemperature, 0.01)
    assert_in_epsilon(12.5, xing.soilSurfaceTemperatureAmplitude1, 0.01)
    assert_in_epsilon(-1.3, xing.soilSurfaceTemperatureAmplitude2, 0.01)
    assert_in_epsilon(20, xing.phaseShiftofTemperatureAmplitude1, 0.01)
    assert_in_epsilon(31, xing.phaseShiftofTemperatureAmplitude2, 0.01)
  end

  def test_geothermal_loop
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ground-to-air-heat-pump-detailed-geothermal-loop.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    geothermal_loop = hpxml_bldg.geothermal_loops[0]
    bore_radius = UnitConversions.convert(geothermal_loop.bore_diameter / 2.0, 'in', 'm')
    grout_conductivity = UnitConversions.convert(0.75, 'Btu/(hr*ft*R)', 'W/(m*K)')
    pipe_conductivity = UnitConversions.convert(0.23, 'Btu/(hr*ft*R)', 'W/(m*K)')
    shank_spacing = UnitConversions.convert(geothermal_loop.shank_spacing, 'in', 'm')

    # Check ghx
    assert(1, model.getGroundHeatExchangerVerticals.size)
    ghx = model.getGroundHeatExchangerVerticals[0]
    assert_in_epsilon(bore_radius, ghx.boreHoleRadius.get, 0.01)
    assert_in_epsilon(grout_conductivity, ghx.groutThermalConductivity.get, 0.01)
    assert_in_epsilon(pipe_conductivity, ghx.pipeThermalConductivity.get, 0.01)
    assert_in_epsilon(shank_spacing, ghx.uTubeDistance.get, 0.01)

    # Check G-Functions
    # Expected values
    # 4_4: 1: g: 5._96._0.075 from "LopU_configurations_5m_v1.0.json"
    lntts = [-8.5, -7.8, -7.2, -6.5, -5.9, -5.2, -4.5, -3.963, -3.27, -2.864, -2.577, -2.171, -1.884, -1.191, -0.497, -0.274, -0.051, 0.196, 0.419, 0.642, 0.873, 1.112, 1.335, 1.679, 2.028, 2.275, 3.003]
    gfnc_coeff = [2.209271810327404, 2.5553235626058273, 2.8519138306223555, 3.2001519249819794, 3.523354932375397, 4.001549412014162, 4.669089316628495, 5.359101946268944, 6.552379489671893, 7.429815477491777, 8.121820314543074, 9.173143912712952, 9.946213029499233, 11.781039134458084, 13.403268695619028, 13.854454372473098, 14.260003929688882, 14.655669234316463, 14.962475413080817, 15.224731293240202, 15.450225154706388, 15.638568709166531, 15.778910465988814, 15.938820677805234, 16.047959625600665, 16.1015379064994, 16.188353466015815]
    gFunctions = lntts.zip(gfnc_coeff)
    ghx.gFunctions.each_with_index do |gFunction, i|
      assert_in_epsilon(gFunction.lnValue, gFunctions[i][0], 0.01)
      assert_in_epsilon(gFunction.gValue, gFunctions[i][1], 0.01)
    end
  end

  def test_shared_chiller_baseboard
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-chiller-only-baseboard.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(3.62, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_chiller_fan_coil
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-chiller-only-fan-coil.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(3.31, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_chiller_water_loop_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-chiller-only-water-loop-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(1.50, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_cooling_tower_water_loop_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-cooling-tower-only-water-loop-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    capacity = UnitConversions.convert(cooling_system.cooling_capacity.to_f, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(3.50, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_boiler_baseboard
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-boiler-only-baseboard.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity.to_f, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    refute_in_epsilon(capacity, boiler.nominalCapacity.get, 0.01) # Uses autosized capacity
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)
  end

  def test_shared_boiler_fan_coil
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-boiler-only-fan-coil.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity.to_f, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    refute_in_epsilon(capacity, boiler.nominalCapacity.get, 0.01) # Uses autosized capacity
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)
  end

  def test_shared_boiler_water_loop_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-boiler-only-water-loop-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    capacity = UnitConversions.convert(heating_system.heating_capacity.to_f, 'Btu/hr', 'W')
    fuel = heating_system.heating_system_fuel
    heat_pump = hpxml_bldg.heat_pumps[0]
    wlhp_cop = heat_pump.heating_efficiency_cop

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    refute_in_epsilon(capacity, boiler.nominalCapacity.get, 0.01) # Uses autosized capacity
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)

    # Check cooling coil
    assert_equal(0, model.getCoilCoolingDXSingleSpeeds.size)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    assert_in_epsilon(wlhp_cop, htg_coil.ratedCOP, 0.01)
    refute_in_epsilon(capacity, htg_coil.ratedTotalHeatingCapacity.get, 0.01) # Uses autosized capacity

    # Check supp heating coil
    assert_equal(0, model.getCoilHeatingElectrics.size)
  end

  def test_shared_ground_loop_ground_to_air_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-ground-loop-ground-to-air-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpEquationFits.size)
    clg_coil = model.getCoilCoolingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(5.84, clg_coil.ratedCoolingCoefficientofPerformance, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpEquationFits.size)
    htg_coil = model.getCoilHeatingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(3.94, htg_coil.ratedHeatingCoefficientofPerformance, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedHeatingCapacity.get, 0.01)
  end

  def test_install_quality_air_to_air_heat_pump_1_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-air-to-air-heat-pump-1-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    charge_defect = heat_pump.charge_defect_ratio
    fan_watts_cfm = heat_pump.fan_watts_per_cfm

    # model objects:
    # Unitary system
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    cooling_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringCoolingOperation.get, 'm^3/s', 'cfm')
    heating_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringHeatingOperation.get, 'm^3/s', 'cfm')

    # Cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    rated_airflow_cfm_clg = UnitConversions.convert(clg_coil.ratedAirFlowRate.get, 'm^3/s', 'cfm')

    # Heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    rated_airflow_cfm_htg = UnitConversions.convert(htg_coil.ratedAirFlowRate.get, 'm^3/s', 'cfm')

    # Fan
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    assert_in_epsilon(fan_watts_cfm, fan.electricPowerPerUnitFlowRate * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)

    # Check installation quality EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")

    # defect ratios in EMS is calculated correctly
    assert_in_epsilon(program_values['F_CH'].sum, charge_defect, 0.01)
    assert_in_epsilon(program_values['FF_AF_clg'].sum, cooling_cfm / rated_airflow_cfm_clg, 0.01)
    assert_in_epsilon(program_values['FF_AF_htg'].sum, heating_cfm / rated_airflow_cfm_htg, 0.01)
  end

  def test_install_quality_air_to_air_heat_pump_2_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-air-to-air-heat-pump-2-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    program_values = _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)
    [0.87, 0.87].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
    end
    [0.8, 0.8].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_htg'][i], 0.01)
    end
  end

  def test_install_quality_air_to_air_heat_pump_var_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-air-to-air-heat-pump-var-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    program_values = _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)
    [0.748, 0.748].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
    end
    [0.702, 0.702].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_htg'][i], 0.01)
    end

    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-air-to-air-heat-pump-var-speed-detailed-performance.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    program_values = _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)
    [0.748, 0.748].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
    end
    [0.702, 0.702].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_htg'][i], 0.01)
    end
  end

  def test_install_quality_furnace_central_air_conditioner_1_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-furnace-gas-central-ac-1-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    heating_system = hpxml_bldg.heating_systems[0]
    charge_defect = cooling_system.charge_defect_ratio
    fan_watts_cfm = cooling_system.fan_watts_per_cfm
    fan_watts_cfm2 = heating_system.fan_watts_per_cfm

    # model objects:
    # Unitary system
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    cooling_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringCoolingOperation.get, 'm^3/s', 'cfm')

    # Cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    rated_airflow_cfm = UnitConversions.convert(clg_coil.ratedAirFlowRate.get, 'm^3/s', 'cfm')

    # Fan
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    assert_in_epsilon(fan_watts_cfm, fan.electricPowerPerUnitFlowRate * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)
    assert_in_epsilon(fan_watts_cfm2, fan.electricPowerPerUnitFlowRate * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)

    # Check installation quality EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")

    # defect ratios in EMS is calculated correctly
    assert_in_epsilon(program_values['F_CH'].sum, charge_defect, 0.01)

    # Fan air flow has already applied air flow defect ratio
    assert_in_epsilon(program_values['FF_AF_clg'].sum, cooling_cfm / rated_airflow_cfm, 0.01)
  end

  def test_install_quality_furnace_central_air_conditioner_2_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-furnace-gas-central-ac-2-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    program_values = _check_install_quality_multispeed_ratio(cooling_system, model)
    [0.87, 0.87].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
    end
  end

  def test_install_quality_furnace_central_air_conditioner_var_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-furnace-gas-central-ac-var-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    program_values = _check_install_quality_multispeed_ratio(cooling_system, model)
    [0.747, 0.748].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
    end
  end

  def test_install_quality_furnace_gas
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-furnace-gas-only.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    fan_watts_cfm = heating_system.fan_watts_per_cfm

    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]

    # Fan
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    assert_in_epsilon(fan_watts_cfm, fan.electricPowerPerUnitFlowRate * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)
  end

  def test_install_quality_ground_to_air_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-ground-to-air-heat-pump-1-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    charge_defect = heat_pump.charge_defect_ratio
    fan_watts_cfm = heat_pump.fan_watts_per_cfm

    # model objects:
    # Unitary system
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    cooling_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringCoolingOperation.get, 'm^3/s', 'cfm')
    heating_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringHeatingOperation.get, 'm^3/s', 'cfm')

    # Cooling coil
    assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpEquationFits.size)
    clg_coil = model.getCoilCoolingWaterToAirHeatPumpEquationFits[0]
    rated_airflow_cfm_clg = UnitConversions.convert(clg_coil.ratedAirFlowRate.get, 'm^3/s', 'cfm')

    # Heating coil
    assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpEquationFits.size)
    htg_coil = model.getCoilHeatingWaterToAirHeatPumpEquationFits[0]
    rated_airflow_cfm_htg = UnitConversions.convert(htg_coil.ratedAirFlowRate.get, 'm^3/s', 'cfm')

    # Fan
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    assert_in_epsilon(fan_watts_cfm, fan.electricPowerPerUnitFlowRate * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)

    # Check installation quality EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")

    # defect ratios in EMS is calculated correctly
    assert_in_epsilon(program_values['F_CH'].sum, charge_defect, 0.01)
    assert_in_epsilon(program_values['FF_AF_clg'].sum, cooling_cfm / rated_airflow_cfm_clg, 0.01)
    assert_in_epsilon(program_values['FF_AF_htg'].sum, heating_cfm / rated_airflow_cfm_htg, 0.01)

    ['base-hvac-install-quality-ground-to-air-heat-pump-2-speed-experimental.xml',
     'base-hvac-install-quality-ground-to-air-heat-pump-var-speed-experimental.xml'].each do |filename|
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, filename))
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)

      # Get HPXML values
      heat_pump = hpxml_bldg.heat_pumps[0]
      charge_defect = heat_pump.charge_defect_ratio
      fan_watts_cfm = heat_pump.fan_watts_per_cfm

      # model objects:
      # Unitary system
      assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
      unitary_system = model.getAirLoopHVACUnitarySystems[0]

      # Cooling coil
      assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpVariableSpeedEquationFits.size)

      # Heating coil
      assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpVariableSpeedEquationFits.size)

      # Fan
      fan = unitary_system.supplyFan.get.to_FanSystemModel.get
      assert_in_epsilon(fan_watts_cfm, fan.electricPowerPerUnitFlowRate * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)

      # Check installation quality EMS
      program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")

      # defect ratios in EMS is calculated correctly
      assert_in_epsilon(program_values['F_CH'].sum, charge_defect, 0.01)
      [0.75, 0.75].each_with_index do |rated_airflow_ratio, i|
        assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
      end
      [0.702, 0.702].each_with_index do |rated_airflow_ratio, i|
        assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_htg'][i], 0.01)
      end
    end
  end

  def test_install_quality_mini_split_air_conditioner
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-mini-split-air-conditioner-only-ducted.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    program_values = _check_install_quality_multispeed_ratio(cooling_system, model)
    [0.749, 0.749].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
    end
  end

  def test_install_quality_mini_split_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-mini-split-heat-pump-ducted.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    program_values = _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)
    [0.748, 0.748].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
    end
    [0.702, 0.702].each_with_index do |rated_airflow_ratio, i|
      assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_htg'][i], 0.01)
    end
  end

  def test_custom_seasons
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-seasons.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    hvac_control = hpxml_bldg.hvac_controls[0]
    seasons_heating_begin_month = hvac_control.seasons_heating_begin_month
    seasons_heating_begin_day = hvac_control.seasons_heating_begin_day
    seasons_heating_end_month = hvac_control.seasons_heating_end_month
    seasons_heating_end_day = hvac_control.seasons_heating_end_day
    seasons_cooling_begin_month = hvac_control.seasons_cooling_begin_month
    seasons_cooling_begin_day = hvac_control.seasons_cooling_begin_day
    seasons_cooling_end_month = hvac_control.seasons_cooling_end_month
    seasons_cooling_end_day = hvac_control.seasons_cooling_end_day

    # Get objects
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    zone = unitary_system.controllingZoneorThermostatLocation.get
    year = model.getYearDescription.assumedYear

    # Check heating season
    start_day_num = Calendar.get_day_num_from_month_day(year, seasons_heating_begin_month, seasons_heating_begin_day)
    end_day_num = Calendar.get_day_num_from_month_day(year, seasons_heating_end_month, seasons_heating_end_day)
    start_date = OpenStudio::Date::fromDayOfYear(start_day_num, year)
    end_date = OpenStudio::Date::fromDayOfYear(end_day_num, year)
    heating_days = zone.sequentialHeatingFractionSchedule(zone.airLoopHVACTerminals[0]).get.to_ScheduleRuleset.get
    assert_equal(heating_days.scheduleRules.size, 3)
    start_dates = []
    end_dates = []
    heating_days.scheduleRules.each do |schedule_rule|
      next unless schedule_rule.daySchedule.values.include? 1

      start_dates.push(schedule_rule.startDate.get)
      end_dates.push(schedule_rule.endDate.get)
    end
    assert_includes(start_dates, start_date)
    assert_includes(end_dates, end_date)

    # Check cooling season
    start_day_num = Calendar.get_day_num_from_month_day(year, seasons_cooling_begin_month, seasons_cooling_begin_day)
    end_day_num = Calendar.get_day_num_from_month_day(year, seasons_cooling_end_month, seasons_cooling_end_day)
    start_date = OpenStudio::Date::fromDayOfYear(start_day_num, year)
    end_date = OpenStudio::Date::fromDayOfYear(end_day_num, year)
    cooling_days = zone.sequentialCoolingFractionSchedule(zone.airLoopHVACTerminals[0]).get.to_ScheduleRuleset.get
    assert_equal(cooling_days.scheduleRules.size, 3)
    cooling_days.scheduleRules.each do |schedule_rule|
      next unless schedule_rule.daySchedule.values.include? 1

      start_dates.push(schedule_rule.startDate.get)
      end_dates.push(schedule_rule.endDate.get)
    end
    assert_includes(start_dates, start_date)
    assert_includes(end_dates, end_date)
  end

  def test_crankcase_heater_watts
    args_hash = {}
    args_hash['hpxml_path'] = @tmp_hpxml_path
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.cooling_systems[0].crankcase_heater_watts = 40.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    crankcase_heater_watts = cooling_system.crankcase_heater_watts

    # Check cooling coil
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(crankcase_heater_watts, clg_coil.crankcaseHeaterCapacity, 0.01)
  end

  def test_ceiling_fan
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-lighting-ceiling-fans.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    hvac_control = hpxml_bldg.hvac_controls[0]
    cooling_setpoint_temp = hvac_control.cooling_setpoint_temp
    ceiling_fan_cooling_setpoint_temp_offset = hvac_control.ceiling_fan_cooling_setpoint_temp_offset

    # Check ceiling fan months
    assert_equal(1, model.getThermostatSetpointDualSetpoints.size)
    thermostat = model.getThermostatSetpointDualSetpoints[0]

    cooling_schedule = thermostat.coolingSetpointTemperatureSchedule.get.to_ScheduleRuleset.get
    assert_equal(3, cooling_schedule.scheduleRules.size)

    rule = cooling_schedule.scheduleRules[1] # cooling months
    assert_equal(6, rule.startDate.get.monthOfYear.value)
    assert_equal(1, rule.startDate.get.dayOfMonth)
    assert_equal(9, rule.endDate.get.monthOfYear.value)
    assert_equal(30, rule.endDate.get.dayOfMonth)
    day_schedule = rule.daySchedule
    values = day_schedule.values
    assert_equal(1, values.size)
    assert_in_epsilon(cooling_setpoint_temp + ceiling_fan_cooling_setpoint_temp_offset, UnitConversions.convert(values[0], 'C', 'F'), 0.01)
  end

  def test_operational_0_occupants
    args_hash = {}
    args_hash['hpxml_path'] = @tmp_hpxml_path
    hpxml, hpxml_bldg = _create_hpxml('base-residents-0.xml')
    hpxml_bldg.ceiling_fans.add(id: "CeilingFan#{hpxml_bldg.ceiling_fans.size + 1}")
    hpxml_bldg.hvac_controls[0].ceiling_fan_cooling_setpoint_temp_offset = 2.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    hvac_control = hpxml_bldg.hvac_controls[0]
    cooling_setpoint_temp = hvac_control.cooling_setpoint_temp

    # Check ceiling fan months
    assert_equal(1, model.getThermostatSetpointDualSetpoints.size)
    thermostat = model.getThermostatSetpointDualSetpoints[0]

    cooling_schedule = thermostat.coolingSetpointTemperatureSchedule.get.to_ScheduleRuleset.get
    assert_equal(1, cooling_schedule.scheduleRules.size)

    rule = cooling_schedule.scheduleRules[0] # year-round setpoints
    day_schedule = rule.daySchedule
    values = day_schedule.values
    assert_equal(1, values.size)
    assert_in_epsilon(cooling_setpoint_temp, UnitConversions.convert(values[0], 'C', 'F'), 0.01)
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

  def _check_install_quality_multispeed_ratio(hpxml_clg_sys, model, hpxml_htg_sys = nil)
    charge_defect = hpxml_clg_sys.charge_defect_ratio
    fan_watts_cfm = hpxml_clg_sys.fan_watts_per_cfm

    # model objects:
    # Unitary system
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    perf = unitary_system.designSpecificationMultispeedObject.get.to_UnitarySystemPerformanceMultispeed.get
    clg_ratios = perf.supplyAirflowRatioFields.map { |field| field.coolingRatio.get }
    cooling_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringCoolingOperation.get, 'm^3/s', 'cfm')

    # Cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    rated_airflow_cfm_clg = []
    clg_coil.stages.each do |stage|
      rated_airflow_cfm_clg << UnitConversions.convert(stage.ratedAirFlowRate.get, 'm^3/s', 'cfm')
    end

    # Fan
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    assert_in_epsilon(fan_watts_cfm, fan.electricPowerPerUnitFlowRate * UnitConversions.convert(1.0, 'cfm', 'm^3/s'), 0.01)

    # Check installation quality EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    clg_speed_cfms = clg_ratios.map { |ratio| cooling_cfm * ratio }
    assert_in_epsilon(program_values['F_CH'].sum, charge_defect, 0.01)
    assert_in_epsilon(program_values['FF_AF_clg'].sum, clg_speed_cfms.zip(rated_airflow_cfm_clg).map { |cfm, rated_cfm| cfm / rated_cfm }.sum, 0.01)
    if not hpxml_htg_sys.nil?
      heating_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringHeatingOperation.get, 'm^3/s', 'cfm')
      htg_ratios = perf.supplyAirflowRatioFields.map { |field| field.heatingRatio.get }

      # Heating coil
      assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
      htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
      rated_airflow_cfm_htg = []
      htg_coil.stages.each do |stage|
        rated_airflow_cfm_htg << UnitConversions.convert(stage.ratedAirFlowRate.get, 'm^3/s', 'cfm')
      end

      htg_speed_cfms = htg_ratios.map { |ratio| heating_cfm * ratio }
      assert_in_epsilon(program_values['FF_AF_htg'].sum, htg_speed_cfms.zip(rated_airflow_cfm_htg).map { |cfm, rated_cfm| cfm / rated_cfm }.sum, 0.01)
    end

    return program_values
  end

  def _check_max_power_ratio_EMS_multispeed(model, htg_speed1_capacity, htg_speed1_cop, htg_speed2_capacity, htg_speed2_cop, clg_speed1_capacity, clg_speed1_cop, clg_speed2_capacity, clg_speed2_cop, num_sys = 1, sys_i = 0)
    # model objects:
    # Unitary system
    assert_equal(num_sys, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[sys_i]

    # Check max power ratio EMS
    index = 0
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} max power ratio program", true)
    if not htg_speed1_capacity.nil?
      # two coils, two sets of values
      assert_equal(2, program_values['rated_eir_0'].size)
      assert_equal(2, program_values['rated_eir_1'].size)
      assert_equal(2, program_values['rt_capacity_0'].size)
      assert_equal(2, program_values['rt_capacity_1'].size)
      assert_in_epsilon(program_values['rated_eir_0'][index], 1.0 / htg_speed1_cop, 0.01) unless htg_speed1_cop.nil?
      assert_in_epsilon(program_values['rated_eir_1'][index], 1.0 / htg_speed2_cop, 0.01) unless htg_speed2_cop.nil?
      assert_in_epsilon(program_values['rt_capacity_0'][index], htg_speed1_capacity, 0.01) unless htg_speed1_capacity.nil?
      assert_in_epsilon(program_values['rt_capacity_1'][index], htg_speed2_capacity, 0.01) unless htg_speed2_capacity.nil?
      index += 1
    else
      assert_equal(1, program_values['rated_eir_0'].size)
      assert_equal(1, program_values['rated_eir_1'].size)
      assert_equal(1, program_values['rt_capacity_0'].size)
      assert_equal(1, program_values['rt_capacity_1'].size)
    end
    assert_in_epsilon(program_values['rated_eir_0'][index], 1.0 / clg_speed1_cop, 0.01) unless clg_speed1_cop.nil?
    assert_in_epsilon(program_values['rated_eir_1'][index], 1.0 / clg_speed2_cop, 0.01) unless clg_speed2_cop.nil?
    assert_in_epsilon(program_values['rt_capacity_0'][index], clg_speed1_capacity, 0.01) unless clg_speed1_capacity.nil?
    assert_in_epsilon(program_values['rt_capacity_1'][index], clg_speed2_capacity, 0.01) unless clg_speed2_capacity.nil?

    return program_values
  end

  def _check_onoff_thermostat_EMS(model, clg_or_htg_coil, c1_cap, c2_cap, c3_cap, c1_eir, c2_eir, c3_eir)
    # Check max power ratio EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{clg_or_htg_coil.name} cycling degradation program", true)
    assert_in_epsilon(program_values['c_1_cap'].sum, c1_cap, 0.01)
    assert_in_epsilon(program_values['c_2_cap'].sum, c2_cap, 0.01)
    assert_in_epsilon(program_values['c_3_cap'].sum, c3_cap, 0.01)
    assert_in_epsilon(program_values['c_1_eir'].sum, c1_eir, 0.01)
    assert_in_epsilon(program_values['c_2_eir'].sum, c2_eir, 0.01)
    assert_in_epsilon(program_values['c_3_eir'].sum, c3_eir, 0.01)
    # Other equations to complicated to check (contains functions, variables, or "()")

    return program_values
  end

  def _check_advanced_defrost(model, htg_coil, supp_design_level, supp_delivered_htg, backup_fuel, defrost_time_fraction, defrost_power)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]

    # Check Other equipment inputs
    defrost_heat_load_oe = model.getOtherEquipments.select { |oe| oe.name.get.include? 'defrost heat load' }
    assert_equal(1, defrost_heat_load_oe.size)
    assert_equal(0, defrost_heat_load_oe[0].otherEquipmentDefinition.fractionRadiant)
    assert_equal(0, defrost_heat_load_oe[0].otherEquipmentDefinition.fractionLatent)
    assert_equal(0, defrost_heat_load_oe[0].otherEquipmentDefinition.fractionLost)
    defrost_supp_heat_energy_oe = model.getOtherEquipments.select { |oe| oe.name.get.include? 'defrost supp heat energy' }
    assert_equal(1, defrost_supp_heat_energy_oe.size)
    assert_equal(0, defrost_supp_heat_energy_oe[0].otherEquipmentDefinition.fractionRadiant)
    assert_equal(0, defrost_supp_heat_energy_oe[0].otherEquipmentDefinition.fractionLatent)
    assert_equal(1, defrost_supp_heat_energy_oe[0].otherEquipmentDefinition.fractionLost)
    assert(backup_fuel == defrost_supp_heat_energy_oe[0].fuelType.to_s)

    # Check heating coil defrost inputs
    assert(htg_coil.defrostStrategy == 'Resistive')
    assert_in_epsilon(htg_coil.defrostTimePeriodFraction, defrost_time_fraction, 0.01)
    assert_in_epsilon(htg_coil.resistiveDefrostHeaterCapacity.get, defrost_power, 0.01)

    # Check EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} defrost program")
    assert_in_epsilon(program_values['supp_design_level'].sum, supp_design_level, 0.01)
    assert_in_epsilon(program_values['supp_delivered_htg'].sum, supp_delivered_htg, 0.01)
  end

  def _check_ghp_standard(model, heat_pump, clg_cop, htg_cop, soil_density, soil_surface_temp_amps, phase_shift_temp_amps)
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpEquationFits.size)
    clg_coil = model.getCoilCoolingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(clg_cop, clg_coil.ratedCoolingCoefficientofPerformance, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpEquationFits.size)
    htg_coil = model.getCoilHeatingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(htg_cop, htg_coil.ratedHeatingCoefficientofPerformance, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedHeatingCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program

    # Check ghx
    assert(1, model.getGroundHeatExchangerVerticals.size)
    ghx = model.getGroundHeatExchangerVerticals[0]

    # Check xing
    assert(1, model.getSiteGroundTemperatureUndisturbedXings.size)
    xing = model.getSiteGroundTemperatureUndisturbedXings[0]
    assert_in_epsilon(ghx.groundThermalConductivity.get, xing.soilThermalConductivity, 0.01)
    assert_in_epsilon(soil_density, xing.soilDensity, 0.01)
    assert_in_epsilon(ghx.groundThermalHeatCapacity.get / xing.soilDensity, xing.soilSpecificHeat, 0.01)
    assert_in_epsilon(ghx.groundTemperature.get, xing.averageSoilSurfaceTemperature, 0.01)
    assert_in_epsilon(soil_surface_temp_amps[0], xing.soilSurfaceTemperatureAmplitude1, 0.01)
    assert_in_epsilon(soil_surface_temp_amps[1], xing.soilSurfaceTemperatureAmplitude2, 0.01)
    assert_in_epsilon(phase_shift_temp_amps[0], xing.phaseShiftofTemperatureAmplitude1, 0.01)
    assert_in_epsilon(phase_shift_temp_amps[1], xing.phaseShiftofTemperatureAmplitude2, 0.01)
  end

  def _check_ghp_experimental(model, heat_pump, clg_capacities, htg_capacities, clg_cops, htg_cops, soil_density, soil_surface_temp_amps, phase_shift_temp_amps)
    # Check cooling coil
    assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpVariableSpeedEquationFits.size)
    clg_coil = model.getCoilCoolingWaterToAirHeatPumpVariableSpeedEquationFits[0]
    clg_cops.each_with_index do |clg_cop, i|
      assert_in_epsilon(clg_cop, clg_coil.speeds[i].referenceUnitGrossRatedCoolingCOP, 0.01)
      assert_in_epsilon(clg_capacities[i], clg_coil.speeds[i].referenceUnitGrossRatedTotalCoolingCapacity, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpVariableSpeedEquationFits.size)
    htg_coil = model.getCoilHeatingWaterToAirHeatPumpVariableSpeedEquationFits[0]
    htg_cops.each_with_index do |htg_cop, i|
      assert_in_epsilon(htg_cop, htg_coil.speeds[i].referenceUnitGrossRatedHeatingCOP, 0.01)
      assert_in_epsilon(htg_capacities[i], htg_coil.speeds[i].referenceUnitGrossRatedHeatingCapacity, 0.01)
    end

    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]

    assert_equal(2, model.getPumpVariableSpeeds.size) # 1 for dhw, 1 for ghp
    pump = model.getPumpVariableSpeeds.find { |pump| pump.name.get.include? Constants::ObjectTypeGroundSourceHeatPump }
    assert_equal(EPlus::PumpControlTypeIntermittent, pump.pumpControlType)
    # Check EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} IQ")
    assert(program_values.empty?) # Check no EMS program
    if heat_pump.compressor_type == HPXML::HVACCompressorTypeVariableSpeed
      program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{pump.name} mfr program")
      assert_in_epsilon(program_values['max_vfr_htg'].sum, htg_coil.ratedWaterFlowRateAtSelectedNominalSpeedLevel.get, 0.01)
      assert_in_epsilon(program_values['max_vfr_clg'].sum, clg_coil.ratedWaterFlowRateAtSelectedNominalSpeedLevel.get, 0.01)
    end

    # Check ghx
    assert(1, model.getGroundHeatExchangerVerticals.size)
    ghx = model.getGroundHeatExchangerVerticals[0]

    # Check xing
    assert(1, model.getSiteGroundTemperatureUndisturbedXings.size)
    xing = model.getSiteGroundTemperatureUndisturbedXings[0]
    assert_in_epsilon(ghx.groundThermalConductivity.get, xing.soilThermalConductivity, 0.01)
    assert_in_epsilon(soil_density, xing.soilDensity, 0.01)
    assert_in_epsilon(ghx.groundThermalHeatCapacity.get / xing.soilDensity, xing.soilSpecificHeat, 0.01)
    assert_in_epsilon(ghx.groundTemperature.get, xing.averageSoilSurfaceTemperature, 0.01)
    assert_in_epsilon(soil_surface_temp_amps[0], xing.soilSurfaceTemperatureAmplitude1, 0.01)
    assert_in_epsilon(soil_surface_temp_amps[1], xing.soilSurfaceTemperatureAmplitude2, 0.01)
    assert_in_epsilon(phase_shift_temp_amps[0], xing.phaseShiftofTemperatureAmplitude1, 0.01)
    assert_in_epsilon(phase_shift_temp_amps[1], xing.phaseShiftofTemperatureAmplitude2, 0.01)
  end

  def _create_hpxml(hpxml_name)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
    return hpxml, hpxml.buildings[0]
  end
end
