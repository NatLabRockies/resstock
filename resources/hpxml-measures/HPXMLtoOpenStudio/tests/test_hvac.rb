# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioHVACTest < Minitest::Test
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

  def _get_table_lookup_factor(curve, t1, t2)
    tbl = curve.to_TableLookup.get
    t1_tbl_values = tbl.independentVariables[0].values
    t2_tbl_values = tbl.independentVariables[1].values
    t1c = UnitConversions.convert(t1, 'F', 'C')
    t2c = UnitConversions.convert(t2, 'F', 'C')
    t1_tbl_value = t1_tbl_values.min_by { |v| (v - t1c).abs }
    t2_tbl_value = t2_tbl_values.min_by { |v| (v - t2c).abs }
    if (t1c - t1_tbl_value).abs > 1
      fail "Could not find close value to #{t1c} in #{t1_tbl_values}"
    end
    if (t2c - t2_tbl_value).abs > 1
      fail "Could not find close value to #{t2c} in #{t2_tbl_values}"
    end

    idx1 = t1_tbl_values.index(t1_tbl_value)
    idx2 = t2_tbl_values.index(t2_tbl_value)
    return tbl.outputValues[idx1 * t2_tbl_values.size + idx2]
  end

  def _get_num_speeds(compressor_type)
    return { HPXML::HVACCompressorTypeSingleStage => 1,
             HPXML::HVACCompressorTypeTwoStage => 2,
             HPXML::HVACCompressorTypeVariableSpeed => 3 }[compressor_type]
  end

  def test_resnet_dx_ac_and_hp
    # Test to verify the model is consistent with RESNET's NEEP-Statistical-Model.xlsm
    # Spreadsheet can be found in https://github.com/NREL/OpenStudio-HPXML/pull/1879

    tol = 0.02 # 2%, higher tolerance because expected values from spreadsheet are not rounded like they are in the RESNET Standard

    # ====================== #
    # Variable Speed, Ducted #
    # ====================== #

    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed.xml')
    hpxml_bldg.heat_pumps[0].cooling_capacity = 8000.0
    hpxml_bldg.heat_pumps[0].heating_capacity = 8700.0
    hpxml_bldg.heat_pumps[0].heating_capacity_17F = 7500.0
    hpxml_bldg.heat_pumps[0].cooling_efficiency_seer = nil
    hpxml_bldg.heat_pumps[0].cooling_efficiency_seer2 = 14.3
    hpxml_bldg.heat_pumps[0].cooling_efficiency_eer = nil
    hpxml_bldg.heat_pumps[0].cooling_efficiency_eer2 = 11.0
    hpxml_bldg.heat_pumps[0].heating_efficiency_hspf = nil
    hpxml_bldg.heat_pumps[0].heating_efficiency_hspf2 = 7.5
    hpxml_bldg.heat_pumps[0].heating_capacity_fraction_17F = nil
    hpxml_bldg.heat_pumps[0].fan_motor_type = HPXML::HVACFanMotorTypeBPM
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    args_hash = {}
    args_hash['hpxml_path'] = @tmp_hpxml_path
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Values for [min, rated, max] speeds
    expected_clg_cfms = [91.7, 266.7, 285.6]
    expected_clg_cops = {
      104 => [3.29, 3.08, 2.88],
      95 => [3.89, 3.71, 3.47],
      82 => [5.14, 5.05, 4.74],
      55.6 => [11.66, 13.24, 12.53],
      40 => [12.32, 14.06, 13.31],
    }
    expected_clg_capacities = {
      104 => [2658.3, 7905.7, 8500.3],
      95 => [2763.7, 8255.7, 8876.7],
      82 => [2915.9, 8761.2, 9420.4],
      55.6 => [3224.5, 9786.4, 10523.2],
      40 => [3407.5, 10394.3, 11177.0],
    }
    expected_htg_cfms = [86.7, 290.0, 319.2]
    expected_htg_cops = {
      70 => [8.44, 3.60, 3.88],
      47 => [3.40, 2.79, 2.63],
      17 => [2.20, 2.02, 1.81],
      5 => [1.74, 1.53, 1.54],
      -20 => [1.20, 1.05, 1.05],
    }
    expected_htg_capacities = {
      70 => [2186.2, 9298.0, 9463.7],
      47 => [2589.6, 8378.0, 9157.3],
      17 => [3115.8, 7178.0, 8757.6],
      5 => [2541.1, 7535.3, 7531.5],
      -20 => [1585.7, 4536.7, 4496.8],
    }

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(3, clg_coil.stages.size)
    expected_clg_cfms.each_with_index do |cfm, i|
      assert_in_epsilon(cfm, UnitConversions.convert(clg_coil.stages[i].ratedAirFlowRate.get, 'm^3/s', 'cfm'), tol)
    end
    expected_clg_cops.each do |odb, cops|
      cops.each_with_index do |cop, i|
        eir_adj = _get_table_lookup_factor(clg_coil.stages[i].energyInputRatioFunctionofTemperatureCurve, HVAC::AirSourceCoolRatedIWB, odb)
        assert_in_epsilon(cop, 1.0 / eir_adj * clg_coil.stages[i].grossRatedCoolingCOP, tol)
      end
    end
    expected_clg_capacities.each do |odb, capacities|
      capacities.each_with_index do |capacity, i|
        cap_adj = _get_table_lookup_factor(clg_coil.stages[i].totalCoolingCapacityFunctionofTemperatureCurve, HVAC::AirSourceCoolRatedIWB, odb)
        assert_in_epsilon(capacity, cap_adj * UnitConversions.convert(clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 'W', 'Btu/hr'), tol)
      end
    end
    clg_coil.stages.each do |stage|
      assert_equal(0.708, stage.grossRatedSensibleHeatRatio.get)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(3, htg_coil.stages.size)
    expected_htg_cfms.each_with_index do |cfm, i|
      assert_in_epsilon(cfm, UnitConversions.convert(htg_coil.stages[i].ratedAirFlowRate.get, 'm^3/s', 'cfm'), tol)
    end
    expected_htg_cops.each do |odb, cops|
      cops.each_with_index do |cop, i|
        eir_adj = _get_table_lookup_factor(htg_coil.stages[i].energyInputRatioFunctionofTemperatureCurve, HVAC::AirSourceHeatRatedIDB, odb)
        assert_in_epsilon(cop, 1.0 / eir_adj * htg_coil.stages[i].grossRatedHeatingCOP, tol)
      end
    end
    expected_htg_capacities.each do |odb, capacities|
      capacities.each_with_index do |capacity, i|
        cap_adj = _get_table_lookup_factor(htg_coil.stages[i].heatingCapacityFunctionofTemperatureCurve, HVAC::AirSourceHeatRatedIDB, odb)
        assert_in_epsilon(capacity, cap_adj * UnitConversions.convert(htg_coil.stages[i].grossRatedHeatingCapacity.get, 'W', 'Btu/hr'), tol)
      end
    end

    # Check fan
    fan_cfms = [82.67, 240.0, 256.96, 78.19, 261.0, 287.44]
    expected_watts_per_flow = UnitConversions.convert(0.375, 'm^3/s', 'cfm')
    expected_fan_cfm_fractions = fan_cfms.map { |cfm| cfm / fan_cfms.max }.sort
    #  relationship for ducted BPM fan
    expected_fan_power_fractions = expected_fan_cfm_fractions.map { |cfm_fraction| cfm_fraction**2.75 }
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    fan.speeds.map { |speed| speed.flowFraction }.sort.each_with_index do |ff, i|
      assert_in_epsilon(ff, expected_fan_cfm_fractions[i])
    end
    fan.speeds.map { |speed| speed.electricPowerFraction.get }.sort.each_with_index do |pf, i|
      assert_in_epsilon(pf, expected_fan_power_fractions[i])
    end
    assert_in_epsilon(fan.electricPowerPerUnitFlowRate, expected_watts_per_flow)

    # ================= #
    # Two Stage, Ducted #
    # ================= #

    hpxml_bldg.heat_pumps[0].compressor_type = HPXML::HVACCompressorTypeTwoStage
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Values for [min, rated] speeds
    expected_clg_cfms = [194.0, 266.7]
    expected_clg_cops = {
      104 => [3.33, 3.19],
      95 => [3.86, 3.71],
      82 => [4.84, 4.69],
      42.3 => [12.58, 12.93],
      40 => [12.70, 13.05],
    }
    expected_clg_capacities = {
      104 => [5650.4, 7875.7],
      95 => [5926.9, 8255.7],
      82 => [6326.3, 8804.6],
      42.3 => [7546.1, 10481.3],
      40 => [7616.5, 10578.2],
    }
    expected_htg_cfms = [206.4, 290.0]
    expected_htg_cops = {
      70 => [4.19, 3.66],
      47 => [3.26, 2.83],
      17 => [2.37, 2.04],
      5 => [2.09, 1.79],
      0 => [1.98, 1.70],
    }
    expected_htg_capacities = {
      70 => [6719.2, 9298.0],
      47 => [6064.5, 8378.0],
      17 => [5210.6, 7178.0],
      5 => [4869.1, 6698.0],
      0 => [4726.7, 6498.0],
    }

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    expected_clg_cfms.each_with_index do |cfm, i|
      assert_in_epsilon(cfm, UnitConversions.convert(clg_coil.stages[i].ratedAirFlowRate.get, 'm^3/s', 'cfm'), tol)
    end
    expected_clg_cops.each do |odb, cops|
      cops.each_with_index do |cop, i|
        eir_adj = _get_table_lookup_factor(clg_coil.stages[i].energyInputRatioFunctionofTemperatureCurve, HVAC::AirSourceCoolRatedIWB, odb)
        assert_in_epsilon(cop, 1.0 / eir_adj * clg_coil.stages[i].grossRatedCoolingCOP, tol)
      end
    end
    expected_clg_capacities.each do |odb, capacities|
      capacities.each_with_index do |capacity, i|
        cap_adj = _get_table_lookup_factor(clg_coil.stages[i].totalCoolingCapacityFunctionofTemperatureCurve, HVAC::AirSourceCoolRatedIWB, odb)
        assert_in_epsilon(capacity, cap_adj * UnitConversions.convert(clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 'W', 'Btu/hr'), tol)
      end
    end
    clg_coil.stages.each do |stage|
      assert_equal(0.708, stage.grossRatedSensibleHeatRatio.get)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)
    expected_htg_cfms.each_with_index do |cfm, i|
      assert_in_epsilon(cfm, UnitConversions.convert(htg_coil.stages[i].ratedAirFlowRate.get, 'm^3/s', 'cfm'), tol)
    end
    expected_htg_cops.each do |odb, cops|
      cops.each_with_index do |cop, i|
        eir_adj = _get_table_lookup_factor(htg_coil.stages[i].energyInputRatioFunctionofTemperatureCurve, HVAC::AirSourceHeatRatedIDB, odb)
        assert_in_epsilon(cop, 1.0 / eir_adj * htg_coil.stages[i].grossRatedHeatingCOP, tol)
      end
    end
    expected_htg_capacities.each do |odb, capacities|
      capacities.each_with_index do |capacity, i|
        cap_adj = _get_table_lookup_factor(htg_coil.stages[i].heatingCapacityFunctionofTemperatureCurve, HVAC::AirSourceHeatRatedIDB, odb)
        assert_in_epsilon(capacity, cap_adj * UnitConversions.convert(htg_coil.stages[i].grossRatedHeatingCapacity.get, 'W', 'Btu/hr'), tol)
      end
    end

    # Check fan
    fan_cfms = [174.72, 240.0, 185.832, 261.0]
    expected_fan_cfm_fractions = fan_cfms.map { |cfm| cfm / fan_cfms.max }.sort
    #  relationship for ducted BPM fan
    expected_fan_power_fractions = expected_fan_cfm_fractions.map { |cfm_fraction| cfm_fraction**2.75 }
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    fan.speeds.map { |speed| speed.flowFraction }.sort.each_with_index do |ff, i|
      assert_in_epsilon(ff, expected_fan_cfm_fractions[i])
    end
    fan.speeds.map { |speed| speed.electricPowerFraction.get }.sort.each_with_index do |pf, i|
      assert_in_epsilon(pf, expected_fan_power_fractions[i])
    end
    assert_in_epsilon(fan.electricPowerPerUnitFlowRate, expected_watts_per_flow)

    # ==================== #
    # Single Stage, Ducted #
    # ==================== #

    # Values for rated speed
    expected_clg_cfm = 266.7
    expected_clg_cops = {
      104 => 3.24,
      95 => 3.98,
      82 => 5.64,
      57.7 => 16.52,
      40 => 17.76,
    }
    expected_clg_capacities = {
      104 => 7996.7,
      95 => 8376.7,
      82 => 8925.7,
      57.7 => 9952.8,
      40 => 10699.2,
    }
    expected_htg_cfm = 290.0
    expected_htg_cops = {
      70 => 4.36,
      47 => 3.33,
      17 => 2.38,
      5 => 2.08,
      0 => 1.96,
    }
    expected_htg_capacities = {
      70 => 9199.6,
      47 => 8279.6,
      17 => 7079.6,
      5 => 6599.6,
      0 => 6399.6,
    }

    hpxml_bldg.heat_pumps[0].compressor_type = HPXML::HVACCompressorTypeSingleStage
    hpxml_bldg.heat_pumps[0].fan_motor_type = HPXML::HVACFanMotorTypePSC
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(expected_clg_cfm, UnitConversions.convert(clg_coil.ratedAirFlowRate.get, 'm^3/s', 'cfm'), tol)
    expected_clg_cops.each do |odb, cop|
      eir_adj = _get_table_lookup_factor(clg_coil.energyInputRatioFunctionOfTemperatureCurve, HVAC::AirSourceCoolRatedIWB, odb)
      assert_in_epsilon(cop, 1.0 / eir_adj * clg_coil.ratedCOP, tol)
    end
    expected_clg_capacities.each do |odb, capacity|
      cap_adj = _get_table_lookup_factor(clg_coil.totalCoolingCapacityFunctionOfTemperatureCurve, HVAC::AirSourceCoolRatedIWB, odb)
      assert_in_epsilon(capacity, cap_adj * UnitConversions.convert(clg_coil.ratedTotalCoolingCapacity.get, 'W', 'Btu/hr'), tol)
    end
    assert_equal(0.708, clg_coil.ratedSensibleHeatRatio.get)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    assert_in_epsilon(expected_htg_cfm, UnitConversions.convert(htg_coil.ratedAirFlowRate.get, 'm^3/s', 'cfm'), tol)
    expected_htg_cops.each do |odb, cop|
      eir_adj = _get_table_lookup_factor(htg_coil.energyInputRatioFunctionofTemperatureCurve, HVAC::AirSourceHeatRatedIDB, odb)
      assert_in_epsilon(cop, 1.0 / eir_adj * htg_coil.ratedCOP, tol)
    end
    expected_htg_capacities.each do |odb, capacity|
      cap_adj = _get_table_lookup_factor(htg_coil.totalHeatingCapacityFunctionofTemperatureCurve, HVAC::AirSourceHeatRatedIDB, odb)
      assert_in_epsilon(capacity, cap_adj * UnitConversions.convert(htg_coil.ratedTotalHeatingCapacity.get, 'W', 'Btu/hr'), tol)
    end

    # Check fan
    fan_cfms = [240.0, 261.0]
    expected_watts_per_flow = UnitConversions.convert(0.5, 'm^3/s', 'cfm')
    expected_fan_cfm_fractions = fan_cfms.map { |cfm| cfm / fan_cfms.max }.sort
    #  relationship for PSC fan
    expected_fan_power_fractions = expected_fan_cfm_fractions.map { |cfm_fraction| cfm_fraction * (0.3 * cfm_fraction + 0.7) }
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    fan.speeds.map { |speed| speed.flowFraction }.sort.each_with_index do |ff, i|
      assert_in_epsilon(ff, expected_fan_cfm_fractions[i])
    end
    fan.speeds.map { |speed| speed.electricPowerFraction.get }.sort.each_with_index do |pf, i|
      assert_in_epsilon(pf, expected_fan_power_fractions[i])
    end
    assert_in_epsilon(fan.electricPowerPerUnitFlowRate, expected_watts_per_flow)

    # ======================== #
    # Variable Speed, Ductless #
    # ======================== #

    hpxml_bldg.heat_pumps[0].heat_pump_type = HPXML::HVACTypeHeatPumpMiniSplit
    hpxml_bldg.heat_pumps[0].compressor_type = HPXML::HVACCompressorTypeVariableSpeed
    hpxml_bldg.heat_pumps[0].distribution_system_idref = nil
    hpxml_bldg.heat_pumps[0].fan_motor_type = HPXML::HVACFanMotorTypeBPM
    hpxml_bldg.hvac_distributions[0].delete
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Values for [min, rated, max] speeds
    expected_clg_cfms = [91.7, 266.7, 285.6]
    expected_clg_cops = {
      104 => [3.26, 2.93, 2.73],
      95 => [3.86, 3.51, 3.27],
      82 => [5.09, 4.72, 4.41],
      55.6 => [11.42, 11.54, 10.83],
      40 => [12.07, 12.27, 11.51],
    }
    expected_clg_capacities = {
      104 => [2653.0, 7805.7, 8379.4],
      95 => [2758.4, 8155.6, 8755.8],
      82 => [2910.5, 8661.1, 9299.6],
      55.6 => [3219.2, 9686.3, 10402.3],
      40 => [3402.2, 10294.2, 11056.2],
    }
    expected_htg_cfms = [86.7, 290.0, 319.2]
    expected_htg_cops = {
      70 => [8.31, 3.48, 3.70],
      47 => [3.39, 2.72, 2.56],
      17 => [2.19, 1.99, 1.79],
      5 => [1.74, 1.52, 1.53],
      -20 => [1.20, 1.05, 1.05],
    }
    expected_htg_capacities = {
      70 => [2190.8, 9424.0, 9627.9],
      47 => [2594.2, 8504.0, 9321.4],
      17 => [3120.4, 7304.0, 8921.7],
      5 => [2545.6, 7661.4, 7695.6],
      -20 => [1590.3, 4662.8, 4661.0],
    }

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(3, clg_coil.stages.size)
    expected_clg_cfms.each_with_index do |cfm, i|
      assert_in_epsilon(cfm, UnitConversions.convert(clg_coil.stages[i].ratedAirFlowRate.get, 'm^3/s', 'cfm'), tol)
    end
    expected_clg_cops.each do |odb, cops|
      cops.each_with_index do |cop, i|
        eir_adj = _get_table_lookup_factor(clg_coil.stages[i].energyInputRatioFunctionofTemperatureCurve, HVAC::AirSourceCoolRatedIWB, odb)
        assert_in_epsilon(cop, 1.0 / eir_adj * clg_coil.stages[i].grossRatedCoolingCOP, tol)
      end
    end
    expected_clg_capacities.each do |odb, capacities|
      capacities.each_with_index do |capacity, i|
        cap_adj = _get_table_lookup_factor(clg_coil.stages[i].totalCoolingCapacityFunctionofTemperatureCurve, HVAC::AirSourceCoolRatedIWB, odb)
        assert_in_epsilon(capacity, cap_adj * UnitConversions.convert(clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 'W', 'Btu/hr'), tol)
      end
    end
    clg_coil.stages.each do |stage|
      assert_equal(0.708, stage.grossRatedSensibleHeatRatio.get)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(3, htg_coil.stages.size)
    expected_htg_cfms.each_with_index do |cfm, i|
      assert_in_epsilon(cfm, UnitConversions.convert(htg_coil.stages[i].ratedAirFlowRate.get, 'm^3/s', 'cfm'), tol)
    end
    expected_htg_cops.each do |odb, cops|
      cops.each_with_index do |cop, i|
        eir_adj = _get_table_lookup_factor(htg_coil.stages[i].energyInputRatioFunctionofTemperatureCurve, HVAC::AirSourceHeatRatedIDB, odb)
        assert_in_epsilon(cop, 1.0 / eir_adj * htg_coil.stages[i].grossRatedHeatingCOP, tol)
      end
    end
    expected_htg_capacities.each do |odb, capacities|
      capacities.each_with_index do |capacity, i|
        cap_adj = _get_table_lookup_factor(htg_coil.stages[i].heatingCapacityFunctionofTemperatureCurve, HVAC::AirSourceHeatRatedIDB, odb)
        assert_in_epsilon(capacity, cap_adj * UnitConversions.convert(htg_coil.stages[i].grossRatedHeatingCapacity.get, 'W', 'Btu/hr'), tol)
      end
    end

    # Check fan
    fan_cfms = [82.67, 240.0, 256.96, 78.19, 261.0, 287.44]
    expected_watts_per_flow = UnitConversions.convert(0.07, 'm^3/s', 'cfm')
    expected_fan_cfm_fractions = fan_cfms.map { |cfm| cfm / fan_cfms.max }.sort
    #  relationship for BPM fan, ductless
    expected_fan_power_fractions = expected_fan_cfm_fractions.map { |cfm_fraction| cfm_fraction**3 }
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    fan.speeds.map { |speed| speed.flowFraction }.sort.each_with_index do |ff, i|
      assert_in_epsilon(ff, expected_fan_cfm_fractions[i])
    end
    fan.speeds.map { |speed| speed.electricPowerFraction.get }.sort.each_with_index do |pf, i|
      assert_in_epsilon(pf, expected_fan_power_fractions[i])
    end
    assert_in_epsilon(fan.electricPowerPerUnitFlowRate, expected_watts_per_flow)
  end

  def test_central_air_conditioner_1_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-central-ac-only-1-speed.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Values for rated speed
    expected_clg_cop_95 = 4.09
    expected_clg_capacity_95 = 7360

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(expected_clg_cop_95, clg_coil.ratedCOP, 0.01)
    assert_in_epsilon(expected_clg_capacity_95, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_central_air_conditioner_2_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-central-ac-only-2-speed.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Values for [min, rated] speeds
    expected_clg_cops_95 = [4.68, 4.52]
    expected_clg_capacities_95 = [5204, 7234]

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    expected_clg_cops_95.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    expected_clg_capacities_95.each_with_index do |capacity, i|
      assert_in_epsilon(capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end
    clg_coil.stages.each do |stage|
      assert_equal(0.708, stage.grossRatedSensibleHeatRatio.get)
    end

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_central_air_conditioner_var_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-central-ac-only-var-speed.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Values for [min, rated, max] speeds
    expected_clg_cops_95 = [7.36, 4.71, 4.41]
    expected_clg_capacities_95 = [1668, 7213, 7747]

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(3, clg_coil.stages.size)
    expected_clg_cops_95.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    expected_clg_capacities_95.each_with_index do |capacity, i|
      assert_in_epsilon(capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end
    clg_coil.stages.each do |stage|
      assert_equal(0.708, stage.grossRatedSensibleHeatRatio.get)
    end

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
    assert(program_values.empty?) # Check no EMS program

    # Test w/ max power ratio

    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-central-ac-only-var-speed-max-power-ratio-schedule.xml'))
    model, _hpxml = _test_measure(args_hash)

    _check_max_power_ratio_EMS_multispeed(model, nil, nil, expected_clg_capacities_95, expected_clg_cops_95)

    # Test w/ furnace & max power ratio
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-furnace-gas-central-ac-var-speed-max-power-ratio-schedule.xml'))
    model, _hpxml = _test_measure(args_hash)

    _check_max_power_ratio_EMS_multispeed(model, nil, nil, expected_clg_capacities_95, expected_clg_cops_95)
  end

  def test_room_air_conditioner
    ['base-hvac-room-ac-only.xml',
     'base-hvac-room-ac-only-eer.xml',
     'base-hvac-room-ac-with-heating.xml'].each do |hpxml_path|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_path))
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
      assert_equal(0.65, clg_coil.ratedSensibleHeatRatio.get)

      next unless not cooling_system.integrated_heating_system_capacity.nil?

      heat_efficiency = cooling_system.integrated_heating_system_efficiency_percent
      heat_efficiency = 1.0 if heat_efficiency.nil?
      heat_capacity = UnitConversions.convert(cooling_system.integrated_heating_system_capacity, 'Btu/hr', 'W')

      # Check heating coil
      assert_equal(1, model.getCoilHeatingElectrics.size)
      htg_coil = model.getCoilHeatingElectrics[0]
      assert_in_epsilon(heat_efficiency, htg_coil.efficiency, 0.01)
      assert_in_epsilon(heat_capacity, htg_coil.nominalCapacity.get, 0.01)
    end
  end

  def test_ptac
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ptac.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    ceer = cooling_system.cooling_efficiency_ceer
    cop = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    capacity = UnitConversions.convert(cooling_system.cooling_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop, clg_coil.ratedCOP, 0.001)
    assert_in_epsilon(capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)
    assert_equal(0.65, clg_coil.ratedSensibleHeatRatio.get)
  end

  def test_ptac_with_heating_electricity
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ptac-with-heating-electricity.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    cooling_system = hpxml_bldg.cooling_systems[0]
    ceer = cooling_system.cooling_efficiency_ceer
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
    assert_equal(0.65, clg_coil.ratedSensibleHeatRatio.get)

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
    ceer = cooling_system.cooling_efficiency_ceer
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
    assert_equal(0.65, clg_coil.ratedSensibleHeatRatio.get)

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
    backup_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')
    ceer = heat_pump.cooling_efficiency_ceer
    cop_cool = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    cop_heat = heat_pump.heating_efficiency_cop # Expected value

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop_cool, clg_coil.ratedCOP, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)
    assert_equal(0.65, clg_coil.ratedSensibleHeatRatio.get)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    assert_in_epsilon(cop_heat, htg_coil.ratedCOP, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedTotalHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(backup_capacity, supp_htg_coil.nominalCapacity.get, 0.01)
  end

  def test_room_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-room-ac-with-reverse-cycle.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')
    backup_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')
    ceer = heat_pump.cooling_efficiency_ceer
    cop_cool = UnitConversions.convert(ceer, 'Btu/hr', 'W') # Expected value
    cop_heat = heat_pump.heating_efficiency_cop

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(cop_cool, clg_coil.ratedCOP, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)
    assert_equal(0.65, clg_coil.ratedSensibleHeatRatio.get)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    assert_in_epsilon(cop_heat, htg_coil.ratedCOP, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedTotalHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_capacity, supp_htg_coil.nominalCapacity.get, 0.01)
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
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-1-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Values for rated speed
    expected_clg_cop_95 = 4.09
    expected_clg_capacity_95 = 11040
    expected_htg_cop_47 = 3.31
    expected_htg_capacity_47 = 10077
    expected_c_d = 0.08

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    backup_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(expected_clg_cop_95, clg_coil.ratedCOP, 0.01)
    assert_in_epsilon(expected_clg_capacity_95, clg_coil.ratedTotalCoolingCapacity.get, 0.01)
    assert_in_epsilon(1.0 - expected_c_d, clg_coil.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient1Constant, 0.01)
    assert_in_epsilon(expected_c_d, clg_coil.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient2x, 0.01)
    assert_in_epsilon(0.0, clg_coil.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient3xPOW2, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    assert_in_epsilon(expected_htg_cop_47, htg_coil.ratedCOP, 0.01)
    assert_in_epsilon(expected_htg_capacity_47, htg_coil.ratedTotalHeatingCapacity.get, 0.01)
    assert_in_epsilon(1.0 - expected_c_d, htg_coil.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient1Constant, 0.01)
    assert_in_epsilon(expected_c_d, htg_coil.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient2x, 0.01)
    assert_in_epsilon(0.0, htg_coil.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient3xPOW2, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(backup_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
    assert(program_values.empty?) # Check no EMS program
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
      backup_capacity_increment = 5000 # 5kw
      backup_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

      # Check cooling coil
      assert_equal(1, (model.getCoilCoolingDXSingleSpeeds.size + model.getCoilCoolingDXMultiSpeeds.size))

      # Check heating coil
      assert_equal(1, (model.getCoilHeatingDXSingleSpeeds.size + model.getCoilHeatingDXMultiSpeeds.size))

      # Check supp heating coil
      assert_equal(1, model.getCoilHeatingElectricMultiStages.size)
      supp_htg_coil = model.getCoilHeatingElectricMultiStages[0]
      supp_htg_coil.stages.each_with_index do |stage, i|
        capacity = [backup_capacity_increment * (i + 1), backup_capacity].min
        assert_in_epsilon(capacity, stage.nominalCapacity.get, 0.01)
        assert_in_epsilon(backup_efficiency, stage.efficiency, 0.01)
      end

      # Check EMS
      assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
      unitary_system = model.getAirLoopHVACUnitarySystems[0]
      program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
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
        if unitary_system.supplementalHeatingCoil.is_initialized
          # integrated backup
          assert_in_delta(backup_lockout_temp, unitary_system.maximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation, 0.01)
        else
          # separate backup system, EMS used instead
          program_values = get_ems_values(model.getEnergyManagementSystemPrograms, 'max heating temp program')
          assert_in_delta(backup_lockout_temp, program_values['max_heating_temp'].sum, 0.01)
        end
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

    # Values for [min, rated] speeds
    expected_clg_cops_95 = [4.68, 4.52]
    expected_clg_capacities_95 = [7806, 10851]
    expected_htg_cops_47 = [4.14, 3.61]
    expected_htg_capacities_47 = [7394, 10250]
    expected_c_d = 0.08

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    backup_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(2, clg_coil.stages.size)
    expected_clg_cops_95.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    expected_clg_capacities_95.each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end
    clg_coil.stages.each do |stage|
      assert_equal(0.708, stage.grossRatedSensibleHeatRatio.get)
      assert_in_epsilon(1.0 - expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient1Constant, 0.01)
      assert_in_epsilon(expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient2x, 0.01)
      assert_in_epsilon(0.0, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient3xPOW2, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(2, htg_coil.stages.size)
    expected_htg_cops_47.each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    expected_htg_capacities_47.each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end
    htg_coil.stages.each do |stage|
      assert_in_epsilon(1.0 - expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient1Constant, 0.01)
      assert_in_epsilon(expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient2x, 0.01)
      assert_in_epsilon(0.0, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient3xPOW2, 0.01)
    end

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(backup_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_air_to_air_heat_pump_var_speed
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Values for [min, rated, max] speeds
    expected_clg_cops_95 = [6.51, 4.45, 4.17]
    expected_clg_capacities_95 = [2655, 10819, 11620]
    expected_htg_cops_47 = [4.52, 3.77, 3.57]
    expected_htg_capacities_47 = [3151, 10282, 11269]
    expected_c_d = 0.4

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    backup_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(3, clg_coil.stages.size)
    expected_clg_cops_95.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    expected_clg_capacities_95.each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end
    clg_coil.stages.each do |stage|
      assert_equal(0.708, stage.grossRatedSensibleHeatRatio.get)
      assert_in_epsilon(1.0 - expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient1Constant, 0.01)
      assert_in_epsilon(expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient2x, 0.01)
      assert_in_epsilon(0.0, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient3xPOW2, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(3, htg_coil.stages.size)
    expected_htg_cops_47.each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    expected_htg_capacities_47.each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end
    htg_coil.stages.each do |stage|
      assert_in_epsilon(1.0 - expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient1Constant, 0.01)
      assert_in_epsilon(expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient2x, 0.01)
      assert_in_epsilon(0.0, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient3xPOW2, 0.01)
    end

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(backup_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
    assert(program_values.empty?) # Check no EMS program

    # Test w/ max power ratio

    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed-research-features.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    _check_max_power_ratio_EMS_multispeed(model, expected_htg_capacities_47, expected_htg_cops_47, expected_clg_capacities_95, expected_clg_cops_95)

    # Test w/ two systems and max power ratio

    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed-max-power-ratio-schedule-two-systems.xml'))
    model, _hpxml = _test_measure(args_hash)

    _check_max_power_ratio_EMS_multispeed(model, expected_htg_capacities_47, expected_htg_cops_47, expected_clg_capacities_95, expected_clg_cops_95, 2, 0)
    _check_max_power_ratio_EMS_multispeed(model, expected_htg_capacities_47, expected_htg_cops_47, expected_clg_capacities_95, expected_clg_cops_95, 2, 1)
  end

  def test_air_to_air_heat_pump_var_speed_detailed_performance
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed-detailed-performance.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Values for [min, rated, max] speeds
    expected_clg_cops_95 = [4.56, 2.98, 2.98]
    expected_clg_capacities_95 = [3501, 10825, 10825]
    expected_htg_cops_47 = [4.73, 3.69, 3.69]
    expected_htg_capacities_47 = [2894, 10222, 10222]

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(3, clg_coil.stages.size)
    expected_clg_cops_95.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    expected_clg_capacities_95.each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end
    clg_coil.stages.each do |stage|
      assert_equal(0.708, stage.grossRatedSensibleHeatRatio.get)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(3, htg_coil.stages.size)
    expected_htg_cops_47.each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    expected_htg_capacities_47.each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end

    # Check supp heating coil
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    backup_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(backup_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
    assert(program_values.empty?) # Check no EMS program
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

  def test_heat_pump_defrost_and_pan_heater
    # Single Speed heat pump test
    args_hash = {}
    args_hash['hpxml_path'] = @tmp_hpxml_path
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
    hpxml_bldg.heat_pumps[0].pan_heater_watts = 60.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    backup_fuel = EPlus.fuel_type(hpxml_bldg.heat_pumps[0].backup_heating_fuel)
    pan_heater_watts = hpxml_bldg.heat_pumps[0].pan_heater_watts

    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    _check_defrost_and_pan_heater(model, htg_coil, 10000, 1.0, backup_fuel, 0.1, 0.0, pan_heater_watts)

    # Ductless heat pump test
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-heat-pump-ductless-backup-integrated.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    backup_fuel = EPlus.fuel_type(HPXML::FuelTypeElectricity)

    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    _check_defrost_and_pan_heater(model, htg_coil, 0.0, 0.0, backup_fuel, 0.06667, 0.0)

    # Ductless heat pump w/ backup heat during defrost test
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-heat-pump-ductless-backup-integrated-defrost-with-backup-heat-active.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    backup_fuel = EPlus.fuel_type(HPXML::FuelTypeElectricity)

    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    _check_defrost_and_pan_heater(model, htg_coil, 10000, 1.0, backup_fuel, 0.06667, 0.0)

    # Dual fuel heat pump test
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-dual-fuel-air-to-air-heat-pump-2-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    backup_fuel = EPlus.fuel_type(hpxml_bldg.heat_pumps[0].backup_heating_fuel)

    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    _check_defrost_and_pan_heater(model, htg_coil, 10000, 0.95, backup_fuel, 0.06667, 0.0)

    # Two heat pump test
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed-max-power-ratio-schedule-two-systems.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    # Same backup fuel for these two systems
    backup_fuel = EPlus.fuel_type(hpxml_bldg.heat_pumps[0].backup_heating_fuel)

    assert_equal(2, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    _check_defrost_and_pan_heater(model, htg_coil, 10000, 1.0, backup_fuel, 0.06667, 0.0, 150.0, 2)

    htg_coil = model.getCoilHeatingDXMultiSpeeds[1]
    _check_defrost_and_pan_heater(model, htg_coil, 10000, 1.0, backup_fuel, 0.06667, 0.0, 150.0, 2)

    # Separate backup heat pump test
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    backup_fuel = EPlus.fuel_type(HPXML::FuelTypeElectricity)

    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    _check_defrost_and_pan_heater(model, htg_coil, 0.0, 0.0, backup_fuel, 0.06667, 0.0)
  end

  def test_mini_split_heat_pump_ductless
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-heat-pump-ductless.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Values for [min, rated, max] speeds
    expected_clg_cops_95 = [5.67, 3.97, 3.71]
    expected_clg_capacities_95 = [2838, 10709, 11490]
    expected_htg_cops_47 = [4.37, 3.55, 3.35]
    expected_htg_capacities_47 = [3156, 10392, 11408]
    expected_c_d = 0.4

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(3, clg_coil.stages.size)
    expected_clg_cops_95.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    expected_clg_capacities_95.each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end
    clg_coil.stages.each do |stage|
      assert_equal(0.708, stage.grossRatedSensibleHeatRatio.get)
      assert_in_epsilon(1.0 - expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient1Constant, 0.01)
      assert_in_epsilon(expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient2x, 0.01)
      assert_in_epsilon(0.0, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient3xPOW2, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(3, htg_coil.stages.size)
    expected_htg_cops_47.each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    expected_htg_capacities_47.each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end
    htg_coil.stages.each do |stage|
      assert_in_epsilon(1.0 - expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient1Constant, 0.01)
      assert_in_epsilon(expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient2x, 0.01)
      assert_in_epsilon(0.0, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient3xPOW2, 0.01)
    end

    # Check supp heating coil
    assert_equal(0, model.getCoilHeatingElectrics.size)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_mini_split_heat_pump_ducted
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-heat-pump-ducted.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    backup_efficiency = heat_pump.backup_heating_efficiency_percent
    backup_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Values for [min, rated, max] speeds
    expected_clg_cops_95 = [5.35, 4.11, 3.85]
    expected_clg_capacities_95 = [2957, 10819, 11620]
    expected_htg_cops_47 = [4.12, 3.41, 3.22]
    expected_htg_capacities_47 = [3151, 10282, 11269]
    expected_c_d = 0.4

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(3, clg_coil.stages.size)
    expected_clg_cops_95.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    expected_clg_capacities_95.each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end
    clg_coil.stages.each do |stage|
      assert_equal(0.708, stage.grossRatedSensibleHeatRatio.get)
      assert_in_epsilon(1.0 - expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient1Constant, 0.01)
      assert_in_epsilon(expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient2x, 0.01)
      assert_in_epsilon(0.0, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient3xPOW2, 0.01)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(3, htg_coil.stages.size)
    expected_htg_cops_47.each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    expected_htg_capacities_47.each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end
    htg_coil.stages.each do |stage|
      assert_in_epsilon(1.0 - expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient1Constant, 0.01)
      assert_in_epsilon(expected_c_d, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient2x, 0.01)
      assert_in_epsilon(0.0, stage.partLoadFractionCorrelationCurve.to_CurveQuadratic.get.coefficient3xPOW2, 0.01)
    end

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(backup_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
    assert(program_values.empty?) # Check no EMS program

    # Test w/ max power ratio

    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-heat-pump-ducted-max-power-ratio-schedule.xml'))
    model, _hpxml = _test_measure(args_hash)

    _check_max_power_ratio_EMS_multispeed(model, expected_htg_capacities_47, expected_htg_cops_47, expected_clg_capacities_95, expected_clg_cops_95)
  end

  def test_mini_split_heat_pump_ductless_detailed_performance
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-heat-pump-ductless-detailed-performance.xml'))
    model, _hpxml = _test_measure(args_hash)

    # Values for [min, rated, max] speeds
    expected_clg_cops_95 = [3.77, 2.67, 2.63]
    expected_clg_capacities_95 = [2669, 10674, 10795]
    expected_htg_cops_47 = [3.49, 2.78, 2.92]
    expected_htg_capacities_47 = [3337, 10992, 13185]

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(3, clg_coil.stages.size)
    expected_clg_cops_95.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    expected_clg_capacities_95.each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end
    clg_coil.stages.each do |stage|
      assert_equal(0.708, stage.grossRatedSensibleHeatRatio.get)
    end

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXMultiSpeeds.size)
    htg_coil = model.getCoilHeatingDXMultiSpeeds[0]
    assert_equal(3, htg_coil.stages.size)
    expected_htg_cops_47.each_with_index do |cop, i|
      assert_in_epsilon(cop, htg_coil.stages[i].grossRatedHeatingCOP, 0.01)
    end
    expected_htg_capacities_47.each_with_index do |htg_capacity, i|
      assert_in_epsilon(htg_capacity, htg_coil.stages[i].grossRatedHeatingCapacity.get, 0.01)
    end

    # Check supp heating coil
    assert_equal(0, model.getCoilHeatingElectrics.size)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_mini_split_air_conditioner
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-mini-split-air-conditioner-only-ductless.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Values for [min, rated, max] speeds
    expected_clg_cops_95 = [5.67, 3.97, 3.71]
    expected_clg_capacities_95 = [1892, 7139, 7660]

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXMultiSpeeds.size)
    clg_coil = model.getCoilCoolingDXMultiSpeeds[0]
    assert_equal(3, clg_coil.stages.size)
    expected_clg_cops_95.each_with_index do |cop, i|
      assert_in_epsilon(cop, clg_coil.stages[i].grossRatedCoolingCOP, 0.01)
    end
    expected_clg_capacities_95.each_with_index do |clg_capacity, i|
      assert_in_epsilon(clg_capacity, clg_coil.stages[i].grossRatedTotalCoolingCapacity.get, 0.01)
    end
    clg_coil.stages.each do |stage|
      assert_equal(0.708, stage.grossRatedSensibleHeatRatio.get)
    end

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
    assert(program_values.empty?) # Check no EMS program
  end

  def test_ground_to_air_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-ground-to-air-heat-pump-1-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    _check_ghp_standard(model, heat_pump, 6.14, 4.02, 962, [12.5, -1.3], [20, 31])

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
    _check_ghp_experimental(model, heat_pump, [10550.56], [10550.56], [6.14], [4.02], 962, [12.5, -1.3], [20, 31])

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
    backup_capacity = UnitConversions.convert(heat_pump.backup_heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpEquationFits.size)
    clg_coil = model.getCoilCoolingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(6.14, clg_coil.ratedCoolingCoefficientofPerformance, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpEquationFits.size)
    htg_coil = model.getCoilHeatingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(4.02, htg_coil.ratedHeatingCoefficientofPerformance, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedHeatingCapacity.get, 0.01)

    # Check supp heating coil
    assert_equal(1, model.getCoilHeatingElectrics.size)
    supp_htg_coil = model.getCoilHeatingElectrics[0]
    assert_in_epsilon(backup_efficiency, supp_htg_coil.efficiency, 0.01)
    assert_in_epsilon(backup_capacity, supp_htg_coil.nominalCapacity.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
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
    gfnc_coeff = [2.21, 2.56, 2.85, 3.20, 3.52, 4.0, 4.67, 5.36, 6.55, 7.43, 8.12, 9.17, 9.95, 11.78, 13.4, 13.85, 14.26, 14.66, 14.96, 15.22, 15.45, 15.64, 15.78, 15.94, 16.05, 16.1, 16.19]
    gFunctions = lntts.zip(gfnc_coeff)
    ghx.gFunctions.each_with_index do |gFunction, i|
      assert_in_epsilon(gFunction.lnValue, gFunctions[i][0], 0.01)
      assert_in_epsilon(gFunction.gValue, gFunctions[i][1], 0.01)
    end
  end

  def test_shared_chiller_baseboard
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-chiller-only-baseboard.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    shared_capacity = UnitConversions.convert(HPXML.new(hpxml_path: args_hash['hpxml_path']).buildings[0].cooling_systems[0].cooling_capacity.to_f, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(3.62, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(shared_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_chiller_fan_coil
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-chiller-only-fan-coil.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    shared_capacity = UnitConversions.convert(HPXML.new(hpxml_path: args_hash['hpxml_path']).buildings[0].cooling_systems[0].cooling_capacity.to_f, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(3.26, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(shared_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_chiller_water_loop_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-chiller-only-water-loop-heat-pump.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    shared_capacity = UnitConversions.convert(HPXML.new(hpxml_path: args_hash['hpxml_path']).buildings[0].cooling_systems[0].cooling_capacity.to_f, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(1.41, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(shared_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_cooling_tower_water_loop_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-cooling-tower-only-water-loop-heat-pump.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    shared_capacity = UnitConversions.convert(HPXML.new(hpxml_path: args_hash['hpxml_path']).buildings[0].cooling_systems[0].cooling_capacity.to_f, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingDXSingleSpeeds.size)
    clg_coil = model.getCoilCoolingDXSingleSpeeds[0]
    assert_in_epsilon(3.46, clg_coil.ratedCOP, 0.01)
    refute_in_epsilon(shared_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01) # Uses autosized capacity
  end

  def test_shared_boiler_baseboard
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-boiler-only-baseboard.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    fuel = heating_system.heating_system_fuel
    shared_capacity = UnitConversions.convert(HPXML.new(hpxml_path: args_hash['hpxml_path']).buildings[0].heating_systems[0].heating_capacity.to_f, 'Btu/hr', 'W')

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    refute_in_epsilon(shared_capacity, boiler.nominalCapacity.get, 0.01) # Uses autosized capacity
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)
  end

  def test_shared_boiler_fan_coil
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-boiler-only-fan-coil.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    fuel = heating_system.heating_system_fuel
    shared_capacity = UnitConversions.convert(HPXML.new(hpxml_path: args_hash['hpxml_path']).buildings[0].heating_systems[0].heating_capacity.to_f, 'Btu/hr', 'W')

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    refute_in_epsilon(shared_capacity, boiler.nominalCapacity.get, 0.01) # Uses autosized capacity
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)
  end

  def test_shared_boiler_water_loop_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-boiler-only-water-loop-heat-pump.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heating_system = hpxml_bldg.heating_systems[0]
    afue = heating_system.heating_efficiency_afue
    fuel = heating_system.heating_system_fuel
    heat_pump = hpxml_bldg.heat_pumps[0]
    wlhp_cop = heat_pump.heating_efficiency_cop
    shared_capacity = UnitConversions.convert(HPXML.new(hpxml_path: args_hash['hpxml_path']).buildings[0].heating_systems[0].heating_capacity.to_f, 'Btu/hr', 'W')

    # Check boiler
    assert_equal(1, model.getBoilerHotWaters.size)
    boiler = model.getBoilerHotWaters[0]
    assert_in_epsilon(afue, boiler.nominalThermalEfficiency, 0.01)
    refute_in_epsilon(shared_capacity, boiler.nominalCapacity.get, 0.01) # Uses autosized capacity
    assert_equal(EPlus.fuel_type(fuel), boiler.fuelType)

    # Check cooling coil
    assert_equal(0, model.getCoilCoolingDXSingleSpeeds.size)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingDXSingleSpeeds.size)
    htg_coil = model.getCoilHeatingDXSingleSpeeds[0]
    assert_in_epsilon(wlhp_cop, htg_coil.ratedCOP, 0.01)
    refute_in_epsilon(shared_capacity, htg_coil.ratedTotalHeatingCapacity.get, 0.01) # Uses autosized capacity

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
    pump_w = heat_pump.pump_watts_per_ton * UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'ton')
    shared_pump_w = heat_pump.shared_loop_watts
    shared_pump_n_units = heat_pump.number_of_units_served

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpEquationFits.size)
    clg_coil = model.getCoilCoolingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(6.14, clg_coil.ratedCoolingCoefficientofPerformance, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpEquationFits.size)
    htg_coil = model.getCoilHeatingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(4.02, htg_coil.ratedHeatingCoefficientofPerformance, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedHeatingCapacity.get, 0.01)

    # Check pump
    assert_equal(2, model.getPumpVariableSpeeds.size) # 1 for dhw, 1 for ghp
    pump = model.getPumpVariableSpeeds.find { |pump| pump.name.get.include? Constants::ObjectTypeGroundSourceHeatPump }
    assert_equal(pump_w + shared_pump_w / shared_pump_n_units, pump.ratedPowerConsumption.get)
  end

  def test_install_quality_air_to_air_heat_pump
    ['base-hvac-install-quality-air-to-air-heat-pump-1-speed.xml',
     'base-hvac-install-quality-air-to-air-heat-pump-2-speed.xml',
     'base-hvac-install-quality-air-to-air-heat-pump-var-speed.xml',
     'base-hvac-install-quality-air-to-air-heat-pump-var-speed-detailed-performance.xml'].each do |hpxml_name|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_name))
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)

      # Get HPXML values
      heat_pump = hpxml_bldg.heat_pumps[0]
      airflow_defect = heat_pump.airflow_defect_ratio
      heat_capacity = heat_pump.heating_capacity
      if heat_capacity.nil?
        heat_capacity = heat_pump.heating_detailed_performance_data.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionNominal && dp.outdoor_temperature == 47.0 }.capacity
      end
      cool_capacity = heat_pump.cooling_capacity
      if cool_capacity.nil?
        cool_capacity = heat_pump.cooling_detailed_performance_data.find { |dp| dp.capacity_description == HPXML::CapacityDescriptionNominal && dp.outdoor_temperature == 95.0 }.capacity
      end
      heat_design_airflow_cfm = heat_pump.heating_design_airflow_cfm
      cool_design_airflow_cfm = heat_pump.cooling_design_airflow_cfm
      charge_defect = heat_pump.charge_defect_ratio
      fan_watts_cfm = heat_pump.fan_watts_per_cfm

      # Unitary system
      assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
      unitary_system = model.getAirLoopHVACUnitarySystems[0]

      # Fan
      fan = unitary_system.supplyFan.get.to_FanSystemModel.get
      assert_in_epsilon(fan_watts_cfm, UnitConversions.convert(fan.electricPowerPerUnitFlowRate, 'cfm', 'm^3/s'), 0.01)

      # Check installation quality EMS
      if heat_pump.compressor_type == HPXML::HVACCompressorTypeSingleStage
        program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
        assert_in_epsilon(charge_defect, program_values['F_CH'].sum, 0.01)
      else
        program_values = _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)
      end

      cool_rated_airflow_ratio = cool_design_airflow_cfm * (1 + airflow_defect) / (HVAC::RatedCFMPerTon * UnitConversions.convert(cool_capacity, 'Btu/hr', 'ton'))
      heat_rated_airflow_ratio = heat_design_airflow_cfm * (1 + airflow_defect) / (HVAC::RatedCFMPerTon * UnitConversions.convert(heat_capacity, 'Btu/hr', 'ton'))
      for i in 0.._get_num_speeds(heat_pump.compressor_type) - 1
        assert_in_epsilon(cool_rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
        assert_in_epsilon(heat_rated_airflow_ratio, program_values['FF_AF_htg'][i], 0.01)
      end
    end
  end

  def test_install_quality_furnace_central_air_conditioner
    ['base-hvac-install-quality-furnace-gas-central-ac-1-speed.xml',
     'base-hvac-install-quality-furnace-gas-central-ac-2-speed.xml',
     'base-hvac-install-quality-furnace-gas-central-ac-var-speed.xml'].each do |hpxml_name|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_name))
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)

      # Get HPXML values
      cooling_system = hpxml_bldg.cooling_systems[0]
      heating_system = hpxml_bldg.heating_systems[0]
      charge_defect = cooling_system.charge_defect_ratio
      fan_watts_cfm = cooling_system.fan_watts_per_cfm
      fan_watts_cfm2 = heating_system.fan_watts_per_cfm
      airflow_defect = cooling_system.airflow_defect_ratio
      cool_capacity = cooling_system.cooling_capacity
      cool_design_airflow_cfm = cooling_system.cooling_design_airflow_cfm

      # Unitary system
      assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
      unitary_system = model.getAirLoopHVACUnitarySystems[0]

      # Fan
      fan = unitary_system.supplyFan.get.to_FanSystemModel.get
      assert_in_epsilon(fan_watts_cfm, UnitConversions.convert(fan.electricPowerPerUnitFlowRate, 'cfm', 'm^3/s'), 0.01)
      assert_in_epsilon(fan_watts_cfm2, UnitConversions.convert(fan.electricPowerPerUnitFlowRate, 'cfm', 'm^3/s'), 0.01)

      # Check installation quality EMS
      if cooling_system.compressor_type == HPXML::HVACCompressorTypeSingleStage
        program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
        assert_in_epsilon(program_values['F_CH'].sum, charge_defect, 0.01)
      else
        program_values = _check_install_quality_multispeed_ratio(cooling_system, model)
      end

      cool_rated_airflow_ratio = cool_design_airflow_cfm * (1 + airflow_defect) / (HVAC::RatedCFMPerTon * UnitConversions.convert(cool_capacity, 'Btu/hr', 'ton'))
      for i in 0.._get_num_speeds(cooling_system.compressor_type) - 1
        assert_in_epsilon(cool_rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
      end
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
    assert_in_epsilon(fan_watts_cfm, UnitConversions.convert(fan.electricPowerPerUnitFlowRate, 'cfm', 'm^3/s'), 0.01)
  end

  def test_install_quality_ground_to_air_heat_pump
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-ground-to-air-heat-pump-1-speed.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    charge_defect = heat_pump.charge_defect_ratio
    fan_watts_cfm = heat_pump.fan_watts_per_cfm
    airflow_defect = heat_pump.airflow_defect_ratio
    heat_capacity = heat_pump.heating_capacity
    cool_capacity = heat_pump.cooling_capacity
    heat_design_airflow_cfm = heat_pump.heating_design_airflow_cfm
    cool_design_airflow_cfm = heat_pump.cooling_design_airflow_cfm

    # Unitary system
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]

    # Fan
    fan = unitary_system.supplyFan.get.to_FanSystemModel.get
    assert_in_epsilon(fan_watts_cfm, UnitConversions.convert(fan.electricPowerPerUnitFlowRate, 'cfm', 'm^3/s'), 0.01)

    # Check installation quality EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
    assert_in_epsilon(program_values['F_CH'].sum, charge_defect, 0.01)

    cool_rated_airflow_ratio = cool_design_airflow_cfm * (1 + airflow_defect) / (HVAC::RatedCFMPerTon * UnitConversions.convert(cool_capacity, 'Btu/hr', 'ton'))
    heat_rated_airflow_ratio = heat_design_airflow_cfm * (1 + airflow_defect) / (HVAC::RatedCFMPerTon * UnitConversions.convert(heat_capacity, 'Btu/hr', 'ton'))
    assert_in_epsilon(cool_rated_airflow_ratio, program_values['FF_AF_clg'][0], 0.01)
    assert_in_epsilon(heat_rated_airflow_ratio, program_values['FF_AF_htg'][0], 0.01)

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
      program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")

      # defect ratios in EMS is calculated correctly
      assert_in_epsilon(program_values['F_CH'].sum, charge_defect, 0.01)
      [0.675, 0.675].each_with_index do |rated_airflow_ratio, i|
        assert_in_epsilon(rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
      end
      [0.675, 0.675].each_with_index do |rated_airflow_ratio, i|
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
    airflow_defect = cooling_system.airflow_defect_ratio
    cool_capacity = cooling_system.cooling_capacity
    cool_design_airflow_cfm = cooling_system.cooling_design_airflow_cfm

    # Check installation quality EMS
    program_values = _check_install_quality_multispeed_ratio(cooling_system, model)

    cool_rated_airflow_ratio = cool_design_airflow_cfm * (1 + airflow_defect) / (HVAC::RatedCFMPerTon * UnitConversions.convert(cool_capacity, 'Btu/hr', 'ton'))
    for i in 0.._get_num_speeds(cooling_system.compressor_type) - 1
      assert_in_epsilon(cool_rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
    end
  end

  def test_install_quality_mini_split_heat_pump_ducted
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-install-quality-mini-split-heat-pump-ducted.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]
    airflow_defect = heat_pump.airflow_defect_ratio
    heat_capacity = heat_pump.heating_capacity
    cool_capacity = heat_pump.cooling_capacity
    heat_design_airflow_cfm = heat_pump.heating_design_airflow_cfm
    cool_design_airflow_cfm = heat_pump.cooling_design_airflow_cfm

    # Check installation quality EMS
    program_values = _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)

    cool_rated_airflow_ratio = cool_design_airflow_cfm * (1 + airflow_defect) / (HVAC::RatedCFMPerTon * UnitConversions.convert(cool_capacity, 'Btu/hr', 'ton'))
    heat_rated_airflow_ratio = heat_design_airflow_cfm * (1 + airflow_defect) / (HVAC::RatedCFMPerTon * UnitConversions.convert(heat_capacity, 'Btu/hr', 'ton'))
    for i in 0.._get_num_speeds(heat_pump.compressor_type) - 1
      assert_in_epsilon(cool_rated_airflow_ratio, program_values['FF_AF_clg'][i], 0.01)
      assert_in_epsilon(heat_rated_airflow_ratio, program_values['FF_AF_htg'][i], 0.01)
    end

    # Test with different design airflow rates
    heat_design_airflow_mult = 1.2
    cool_design_airflow_mult = 0.8

    args_hash = {}
    args_hash['hpxml_path'] = @tmp_hpxml_path
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-install-quality-mini-split-heat-pump-ducted.xml')
    hpxml_bldg.heat_pumps[0].heating_design_airflow_cfm *= heat_design_airflow_mult
    hpxml_bldg.heat_pumps[0].cooling_design_airflow_cfm *= cool_design_airflow_mult
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]

    # Check installation quality EMS
    program_values = _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)

    for i in 0.._get_num_speeds(heat_pump.compressor_type) - 1
      assert_in_epsilon(cool_rated_airflow_ratio * cool_design_airflow_mult, program_values['FF_AF_clg'][i], 0.01)
      assert_in_epsilon(heat_rated_airflow_ratio * heat_design_airflow_mult, program_values['FF_AF_htg'][i], 0.01)
    end

    # Test without heating design airflow rate
    args_hash = {}
    args_hash['hpxml_path'] = @tmp_hpxml_path
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-install-quality-mini-split-heat-pump-ducted.xml')
    hpxml_bldg.heat_pumps[0].heating_design_airflow_cfm = nil
    hpxml_bldg.heat_pumps[0].cooling_design_airflow_cfm *= cool_design_airflow_mult
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]

    # Check installation quality EMS
    program_values = _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)

    for i in 0.._get_num_speeds(heat_pump.compressor_type) - 1
      assert_in_epsilon(cool_rated_airflow_ratio * cool_design_airflow_mult, program_values['FF_AF_clg'][i], 0.01)
      assert_in_epsilon(heat_rated_airflow_ratio * cool_design_airflow_mult, program_values['FF_AF_htg'][i], 0.01)
    end

    # Test without cooling design airflow rate
    args_hash = {}
    args_hash['hpxml_path'] = @tmp_hpxml_path
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-install-quality-mini-split-heat-pump-ducted.xml')
    hpxml_bldg.heat_pumps[0].heating_design_airflow_cfm *= heat_design_airflow_mult
    hpxml_bldg.heat_pumps[0].cooling_design_airflow_cfm = nil
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    heat_pump = hpxml_bldg.heat_pumps[0]

    # Check installation quality EMS
    program_values = _check_install_quality_multispeed_ratio(heat_pump, model, heat_pump)

    for i in 0.._get_num_speeds(heat_pump.compressor_type) - 1
      assert_in_epsilon(cool_rated_airflow_ratio * heat_design_airflow_mult, program_values['FF_AF_clg'][i], 0.01)
      assert_in_epsilon(heat_rated_airflow_ratio * heat_design_airflow_mult, program_values['FF_AF_htg'][i], 0.01)
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
    assert_in_epsilon(fan_watts_cfm, UnitConversions.convert(fan.electricPowerPerUnitFlowRate, 'cfm', 'm^3/s'), 0.01)

    # Check installation quality EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
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

  def _check_max_power_ratio_EMS_multispeed(model, htg_capacities, htg_cops, clg_capacities, clg_cops, num_sys = 1, sys_i = 0)
    # model objects:
    # Unitary system
    assert_equal(num_sys, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[sys_i]

    # Check max power ratio EMS
    index = 0
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} max power ratio program", true)
    if not htg_capacities.nil?
      # two coils, two sets of values
      assert_equal(2, program_values['rated_eir_0'].size)
      assert_equal(2, program_values['rated_eir_1'].size)
      assert_equal(2, program_values['rated_eir_2'].size)
      assert_equal(2, program_values['rt_capacity_0'].size)
      assert_equal(2, program_values['rt_capacity_1'].size)
      assert_equal(2, program_values['rt_capacity_2'].size)
      assert_in_epsilon(1.0 / program_values['rated_eir_0'][index], htg_cops[0], 0.01) unless htg_cops[0].nil?
      assert_in_epsilon(1.0 / program_values['rated_eir_1'][index], htg_cops[1], 0.01) unless htg_cops[1].nil?
      assert_in_epsilon(1.0 / program_values['rated_eir_2'][index], htg_cops[2], 0.01) unless htg_cops[2].nil?
      assert_in_epsilon(program_values['rt_capacity_0'][index], htg_capacities[0], 0.01) unless htg_capacities[0].nil?
      assert_in_epsilon(program_values['rt_capacity_1'][index], htg_capacities[1], 0.01) unless htg_capacities[1].nil?
      assert_in_epsilon(program_values['rt_capacity_2'][index], htg_capacities[2], 0.01) unless htg_capacities[3].nil?
      index += 1
    else
      assert_equal(1, program_values['rated_eir_0'].size)
      assert_equal(1, program_values['rated_eir_1'].size)
      assert_equal(1, program_values['rated_eir_2'].size)
      assert_equal(1, program_values['rt_capacity_0'].size)
      assert_equal(1, program_values['rt_capacity_1'].size)
      assert_equal(1, program_values['rt_capacity_2'].size)
    end
    assert_in_epsilon(1.0 / program_values['rated_eir_0'][index], clg_cops[0], 0.01) unless clg_cops[0].nil?
    assert_in_epsilon(1.0 / program_values['rated_eir_1'][index], clg_cops[1], 0.01) unless clg_cops[1].nil?
    assert_in_epsilon(1.0 / program_values['rated_eir_2'][index], clg_cops[2], 0.01) unless clg_cops[2].nil?
    assert_in_epsilon(program_values['rt_capacity_0'][index], clg_capacities[0], 0.01) unless clg_capacities[0].nil?
    assert_in_epsilon(program_values['rt_capacity_1'][index], clg_capacities[1], 0.01) unless clg_capacities[1].nil?
    assert_in_epsilon(program_values['rt_capacity_2'][index], clg_capacities[2], 0.01) unless clg_capacities[2].nil?

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

  def _check_defrost_and_pan_heater(model, htg_coil, supp_capacity, supp_efficiency, backup_fuel, defrost_time_fraction, defrost_power, pan_heater_watts = 150.0, num_of_ems = 1)
    # Check Other equipment inputs
    defrost_heat_load_oe = model.getOtherEquipments.select { |oe| oe.additionalProperties.getFeatureAsString('ObjectType').to_s == Constants::ObjectTypeHPDefrostHeatLoad }
    assert_equal(num_of_ems, defrost_heat_load_oe.size)
    assert_equal(0, defrost_heat_load_oe[0].otherEquipmentDefinition.fractionRadiant)
    assert_equal(0, defrost_heat_load_oe[0].otherEquipmentDefinition.fractionLatent)
    assert_equal(0, defrost_heat_load_oe[0].otherEquipmentDefinition.fractionLost)
    defrost_supp_heat_energy_oe = model.getOtherEquipments.select { |oe| oe.endUseSubcategory.start_with? Constants::ObjectTypeHPDefrostSupplHeat }
    assert_equal(num_of_ems, defrost_supp_heat_energy_oe.size)
    assert_equal(0, defrost_supp_heat_energy_oe[0].otherEquipmentDefinition.fractionRadiant)
    assert_equal(0, defrost_supp_heat_energy_oe[0].otherEquipmentDefinition.fractionLatent)
    assert_in_epsilon(1.0, defrost_supp_heat_energy_oe[0].otherEquipmentDefinition.fractionLost, 0.01)
    assert(backup_fuel == defrost_supp_heat_energy_oe[0].fuelType.to_s)

    # Check heating coil defrost inputs
    assert(htg_coil.defrostStrategy == 'Resistive')
    assert_in_epsilon(htg_coil.defrostTimePeriodFraction, defrost_time_fraction, 0.01)
    assert_in_delta(htg_coil.resistiveDefrostHeaterCapacity.get, defrost_power, 1.0)

    # Check EMS
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{htg_coil.name} defrost program")
    assert_in_epsilon(program_values['supp_capacity'].sum, supp_capacity, 0.01)
    assert_in_epsilon(program_values['supp_efficiency'].sum, supp_efficiency, 0.01)
    pan_heater_act_name = program_values.keys.find { |k| k.include? 'pan_heater_energy_act' }
    assert_equal(pan_heater_watts, program_values[pan_heater_act_name][0])
    assert(!program_values.empty?)
  end

  def _check_ghp_standard(model, heat_pump, clg_cop, htg_cop, soil_density, soil_surface_temp_amps, phase_shift_temp_amps)
    clg_capacity = UnitConversions.convert(heat_pump.cooling_capacity, 'Btu/hr', 'W')
    htg_capacity = UnitConversions.convert(heat_pump.heating_capacity, 'Btu/hr', 'W')

    # Check cooling coil
    assert_equal(1, model.getCoilCoolingWaterToAirHeatPumpEquationFits.size)
    clg_coil = model.getCoilCoolingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(clg_cop, clg_coil.ratedCoolingCoefficientofPerformance, 0.01)
    assert_in_epsilon(clg_capacity, clg_coil.ratedTotalCoolingCapacity.get, 0.01)
    assert_in_epsilon(0.708, clg_coil.ratedSensibleCoolingCapacity.get / clg_coil.ratedTotalCoolingCapacity.get, 0.01)
    assert_in_epsilon(0.566, clg_coil.ratedAirFlowRate.get, 0.01)

    # Check heating coil
    assert_equal(1, model.getCoilHeatingWaterToAirHeatPumpEquationFits.size)
    htg_coil = model.getCoilHeatingWaterToAirHeatPumpEquationFits[0]
    assert_in_epsilon(htg_cop, htg_coil.ratedHeatingCoefficientofPerformance, 0.01)
    assert_in_epsilon(htg_capacity, htg_coil.ratedHeatingCapacity.get, 0.01)
    assert_in_epsilon(0.566, htg_coil.ratedAirFlowRate.get, 0.01)

    # Check EMS
    assert_equal(1, model.getAirLoopHVACUnitarySystems.size)
    unitary_system = model.getAirLoopHVACUnitarySystems[0]
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
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
    program_values = get_ems_values(model.getEnergyManagementSystemPrograms, "#{unitary_system.name} install quality program")
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
