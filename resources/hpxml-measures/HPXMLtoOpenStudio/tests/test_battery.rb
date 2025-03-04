# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioBatteryTest < Minitest::Test
  def teardown
    File.delete(File.join(File.dirname(__FILE__), 'in.schedules.csv')) if File.exist? File.join(File.dirname(__FILE__), 'in.schedules.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_annual.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_annual.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_design_load_details.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_design_load_details.csv')
  end

  def sample_files_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files')
  end

  def get_batteries(model, name)
    batteries = []
    model.getElectricLoadCenterStorageLiIonNMCBatterys.each do |b|
      next unless b.name.to_s.start_with? "#{name} "

      batteries << b
    end
    return batteries
  end

  def get_elcds(model, name)
    elcds = []
    model.getElectricLoadCenterDistributions.each do |elcd|
      next unless elcd.name.to_s.start_with? "#{name} "

      elcds << elcd
    end
    return elcds
  end

  def calc_nom_capacity(battery)
    return (battery.numberofCellsinSeries * battery.numberofStringsinParallel *
            battery.cellVoltageatEndofNominalZone * battery.fullyChargedCellCapacity)
  end

  def test_battery_default
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-misc-defaults.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.batteries.each do |hpxml_battery|
      batteries = get_batteries(model, hpxml_battery.id)
      assert_equal(1, batteries.size)
      battery = batteries[0]

      # Check object
      assert(!battery.thermalZone.is_initialized)
      assert_equal(0, battery.radiativeFraction)
      assert_equal(0.925, battery.dctoDCChargingEfficiency)
      assert_equal(HPXML::BatteryLifetimeModelNone, battery.lifetimeModel)
      assert_in_epsilon(15, battery.numberofCellsinSeries, 0.01)
      assert_in_epsilon(62, battery.numberofStringsinParallel, 0.01)
      assert_in_epsilon(0.0, battery.initialFractionalStateofCharge, 0.01)
      assert_in_epsilon(99.0, battery.batteryMass, 0.01)
      assert_in_epsilon(1.42, battery.batterySurfaceArea, 0.01)
      assert_in_epsilon(10000, calc_nom_capacity(battery), 0.01)

      elcds = get_elcds(model, 'PVSystem')
      assert_equal(1, elcds.size)
      elcd = elcds[0]

      # Check object
      assert_equal('DirectCurrentWithInverterACStorage', elcd.electricalBussType)
      assert_equal(0.075, elcd.minimumStorageStateofChargeFraction)
      assert_equal(0.975, elcd.maximumStorageStateofChargeFraction)
      assert_equal(5000.0, elcd.designStorageControlChargePower.get)
      assert_equal(5000.0, elcd.designStorageControlDischargePower.get)
      assert(!elcd.demandLimitSchemePurchasedElectricDemandLimit.is_initialized)
      assert_equal('TrackFacilityElectricDemandStoreExcessOnSite', elcd.storageOperationScheme)
    end
  end

  def test_battery
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-battery.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.batteries.each do |hpxml_battery|
      batteries = get_batteries(model, hpxml_battery.id)
      assert_equal(0, batteries.size)

      elcds = get_elcds(model, hpxml_battery.id)
      assert_equal(0, elcds.size)
    end
  end

  def test_battery_scheduled
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-battery-scheduled.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.batteries.each do |hpxml_battery|
      batteries = get_batteries(model, hpxml_battery.id)
      assert_equal(1, batteries.size)
      battery = batteries[0]

      # Check object
      assert(!battery.thermalZone.is_initialized)
      assert_equal(0, battery.radiativeFraction)
      assert_equal(0.925, battery.dctoDCChargingEfficiency)
      assert_equal(HPXML::BatteryLifetimeModelNone, battery.lifetimeModel)
      assert_in_epsilon(15, battery.numberofCellsinSeries, 0.01)
      assert_in_epsilon(125, battery.numberofStringsinParallel, 0.01)
      assert_in_epsilon(0.0, battery.initialFractionalStateofCharge, 0.01)
      assert_in_epsilon(198.0, battery.batteryMass, 0.01)
      assert_in_epsilon(2.25, battery.batterySurfaceArea, 0.01)
      assert_in_epsilon(20000, calc_nom_capacity(battery), 0.01)

      elcds = get_elcds(model, hpxml_battery.id)
      assert_equal(1, elcds.size)
      elcd = elcds[0]

      # Check object
      assert_equal('AlternatingCurrentWithStorage', elcd.electricalBussType)
      assert_equal(0.075, elcd.minimumStorageStateofChargeFraction)
      assert_equal(0.975, elcd.maximumStorageStateofChargeFraction)
      assert_equal(6000.0, elcd.designStorageControlChargePower.get)
      assert_equal(6000.0, elcd.designStorageControlDischargePower.get)
      assert(!elcd.demandLimitSchemePurchasedElectricDemandLimit.is_initialized)
      assert_equal('TrackChargeDischargeSchedules', elcd.storageOperationScheme)
      assert(elcd.storageChargePowerFractionSchedule.is_initialized)
      assert(elcd.storageDischargePowerFractionSchedule.is_initialized)
      assert(elcd.storageConverter.is_initialized)

      elcscs = model.getElectricLoadCenterStorageConverters
      assert_equal(1, elcscs.size)
      elcsc = elcscs[0]
      assert_equal(1.0, elcsc.simpleFixedEfficiency.get)
    end
  end

  def test_pv_battery
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-pv-battery.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.batteries.each do |hpxml_battery|
      batteries = get_batteries(model, hpxml_battery.id)
      assert_equal(1, batteries.size)
      battery = batteries[0]

      # Check object
      assert(!battery.thermalZone.is_initialized)
      assert_equal(0, battery.radiativeFraction)
      assert_equal(0.925, battery.dctoDCChargingEfficiency)
      assert_equal(HPXML::BatteryLifetimeModelNone, battery.lifetimeModel)
      assert_in_epsilon(15, battery.numberofCellsinSeries, 0.01)
      assert_in_epsilon(125, battery.numberofStringsinParallel, 0.01)
      assert_in_epsilon(0.0, battery.initialFractionalStateofCharge, 0.01)
      assert_in_epsilon(198.0, battery.batteryMass, 0.01)
      assert_in_epsilon(2.25, battery.batterySurfaceArea, 0.01)
      assert_in_epsilon(20000, calc_nom_capacity(battery), 0.01)

      elcds = get_elcds(model, 'PVSystem')
      assert_equal(1, elcds.size)
      elcd = elcds[0]

      # Check object
      assert_equal('DirectCurrentWithInverterACStorage', elcd.electricalBussType)
      assert_equal(0.075, elcd.minimumStorageStateofChargeFraction)
      assert_equal(0.975, elcd.maximumStorageStateofChargeFraction)
      assert_equal(6000.0, elcd.designStorageControlChargePower.get)
      assert_equal(6000.0, elcd.designStorageControlDischargePower.get)
      assert(!elcd.demandLimitSchemePurchasedElectricDemandLimit.is_initialized)
      assert_equal('TrackFacilityElectricDemandStoreExcessOnSite', elcd.storageOperationScheme)
      assert(!elcd.storageChargePowerFractionSchedule.is_initialized)
      assert(!elcd.storageDischargePowerFractionSchedule.is_initialized)
      assert(!elcd.storageConverter.is_initialized)
    end
  end

  def test_pv_battery_shared
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-bldgtype-mf-unit-shared-pv-battery.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.batteries.each do |hpxml_battery|
      batteries = get_batteries(model, hpxml_battery.id)
      assert_equal(1, batteries.size)
      battery = batteries[0]

      # Check object
      assert(!battery.thermalZone.is_initialized)
      assert_equal(0, battery.radiativeFraction)
      assert_equal(0.925, battery.dctoDCChargingEfficiency)
      assert_equal(HPXML::BatteryLifetimeModelNone, battery.lifetimeModel)
      assert_in_epsilon(15, battery.numberofCellsinSeries, 0.01)
      assert_in_epsilon(125, battery.numberofStringsinParallel, 0.01)
      assert_in_epsilon(0.0, battery.initialFractionalStateofCharge, 0.01)
      assert_in_epsilon(198.0, battery.batteryMass, 0.01)
      assert_in_epsilon(2.25, battery.batterySurfaceArea, 0.01)
      assert_in_epsilon(20000, calc_nom_capacity(battery), 0.01)

      elcds = get_elcds(model, 'PVSystem')
      assert_equal(1, elcds.size)
      elcd = elcds[0]

      # Check object
      assert_equal('DirectCurrentWithInverterACStorage', elcd.electricalBussType)
      assert_equal(0.075, elcd.minimumStorageStateofChargeFraction)
      assert_equal(0.975, elcd.maximumStorageStateofChargeFraction)
      assert_equal(6000.0, elcd.designStorageControlChargePower.get)
      assert_equal(6000.0, elcd.designStorageControlDischargePower.get)
      assert(!elcd.demandLimitSchemePurchasedElectricDemandLimit.is_initialized)
      assert_equal('TrackFacilityElectricDemandStoreExcessOnSite', elcd.storageOperationScheme)
      assert(!elcd.storageChargePowerFractionSchedule.is_initialized)
      assert(!elcd.storageDischargePowerFractionSchedule.is_initialized)
      assert(!elcd.storageConverter.is_initialized)
    end
  end

  def test_pv_battery_scheduled
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-pv-battery-scheduled.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.batteries.each do |hpxml_battery|
      batteries = get_batteries(model, hpxml_battery.id)
      assert_equal(1, batteries.size)
      battery = batteries[0]

      # Check object
      assert(!battery.thermalZone.is_initialized)
      assert_equal(0, battery.radiativeFraction)
      assert_equal(0.925, battery.dctoDCChargingEfficiency)
      assert_equal(HPXML::BatteryLifetimeModelNone, battery.lifetimeModel)
      assert_in_epsilon(15, battery.numberofCellsinSeries, 0.01)
      assert_in_epsilon(125, battery.numberofStringsinParallel, 0.01)
      assert_in_epsilon(0.0, battery.initialFractionalStateofCharge, 0.01)
      assert_in_epsilon(198.0, battery.batteryMass, 0.01)
      assert_in_epsilon(2.25, battery.batterySurfaceArea, 0.01)
      assert_in_epsilon(20000, calc_nom_capacity(battery), 0.01)

      elcds = get_elcds(model, 'PVSystem')
      assert_equal(1, elcds.size)
      elcd = elcds[0]

      # Check object
      assert_equal('DirectCurrentWithInverterACStorage', elcd.electricalBussType)
      assert_equal(0.075, elcd.minimumStorageStateofChargeFraction)
      assert_equal(0.975, elcd.maximumStorageStateofChargeFraction)
      assert_equal(6000.0, elcd.designStorageControlChargePower.get)
      assert_equal(6000.0, elcd.designStorageControlDischargePower.get)
      assert(!elcd.demandLimitSchemePurchasedElectricDemandLimit.is_initialized)
      assert_equal('TrackChargeDischargeSchedules', elcd.storageOperationScheme)
      assert(elcd.storageChargePowerFractionSchedule.is_initialized)
      assert(elcd.storageDischargePowerFractionSchedule.is_initialized)
      assert(elcd.storageConverter.is_initialized)

      elcscs = model.getElectricLoadCenterStorageConverters
      assert_equal(1, elcscs.size)
      elcsc = elcscs[0]
      assert_equal(1.0, elcsc.simpleFixedEfficiency.get)
    end
  end

  def test_pv_battery_round_trip_efficiency
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-pv-battery-round-trip-efficiency.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.batteries.each do |hpxml_battery|
      batteries = get_batteries(model, hpxml_battery.id)
      assert_equal(1, batteries.size)
      battery = batteries[0]

      # Check object
      assert(!battery.thermalZone.is_initialized)
      assert_equal(0, battery.radiativeFraction)
      assert_equal(0.8, battery.dctoDCChargingEfficiency)
      assert_equal(HPXML::BatteryLifetimeModelNone, battery.lifetimeModel)
      assert_in_epsilon(15, battery.numberofCellsinSeries, 0.01)
      assert_in_epsilon(125, battery.numberofStringsinParallel, 0.01)
      assert_in_epsilon(0.0, battery.initialFractionalStateofCharge, 0.01)
      assert_in_epsilon(198.0, battery.batteryMass, 0.01)
      assert_in_epsilon(2.25, battery.batterySurfaceArea, 0.01)
      assert_in_epsilon(20000, calc_nom_capacity(battery), 0.01)

      elcds = get_elcds(model, 'PVSystem')
      assert_equal(1, elcds.size)
      elcd = elcds[0]

      # Check object
      assert_equal('DirectCurrentWithInverterACStorage', elcd.electricalBussType)
      assert_equal(0.075, elcd.minimumStorageStateofChargeFraction)
      assert_equal(0.975, elcd.maximumStorageStateofChargeFraction)
      assert_equal(6000.0, elcd.designStorageControlChargePower.get)
      assert_equal(6000.0, elcd.designStorageControlDischargePower.get)
      assert(!elcd.demandLimitSchemePurchasedElectricDemandLimit.is_initialized)
      assert_equal('TrackFacilityElectricDemandStoreExcessOnSite', elcd.storageOperationScheme)
      assert(!elcd.storageChargePowerFractionSchedule.is_initialized)
      assert(!elcd.storageDischargePowerFractionSchedule.is_initialized)
      assert(!elcd.storageConverter.is_initialized)
    end
  end

  def test_pv_battery_lifetime_model
    skip # Temporarily disabled
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-pv-battery-lifetime-model.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.batteries.each do |hpxml_battery|
      batteries = get_batteries(model, hpxml_battery.id)
      assert_equal(1, batteries.size)
      battery = batteries[0]

      # Check object
      assert(!battery.thermalZone.is_initialized)
      assert_equal(0, battery.radiativeFraction)
      assert_equal(0.925, battery.dctoDCChargingEfficiency)
      assert_equal(HPXML::BatteryLifetimeModelKandlerSmith, battery.lifetimeModel)
      assert_in_epsilon(15, battery.numberofCellsinSeries, 0.01)
      assert_in_epsilon(125, battery.numberofStringsinParallel, 0.01)
      assert_in_epsilon(0.0, battery.initialFractionalStateofCharge, 0.01)
      assert_in_epsilon(198.0, battery.batteryMass, 0.01)
      assert_in_epsilon(2.25, battery.batterySurfaceArea, 0.01)
      assert_in_epsilon(20000, calc_nom_capacity(battery), 0.01)

      elcds = get_elcds(model, 'PVSystem')
      assert_equal(1, elcds.size)
      elcd = elcds[0]

      # Check object
      assert_equal('DirectCurrentWithInverterACStorage', elcd.electricalBussType)
      assert_equal(0.075, elcd.minimumStorageStateofChargeFraction)
      assert_equal(0.975, elcd.maximumStorageStateofChargeFraction)
      assert_equal(6000.0, elcd.designStorageControlChargePower.get)
      assert_equal(6000.0, elcd.designStorageControlDischargePower.get)
      assert(!elcd.demandLimitSchemePurchasedElectricDemandLimit.is_initialized)
      assert_equal('TrackFacilityElectricDemandStoreExcessOnSite', elcd.storageOperationScheme)
    end
  end

  def test_pv_battery_garage
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-pv-battery-garage.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.batteries.each do |hpxml_battery|
      batteries = get_batteries(model, hpxml_battery.id)
      assert_equal(1, batteries.size)
      battery = batteries[0]

      # Check object
      assert(battery.thermalZone.is_initialized)
      assert_equal(HPXML::LocationGarage, battery.thermalZone.get.name.to_s)
      assert_equal(0.9, battery.radiativeFraction)
      assert_equal(0.925, battery.dctoDCChargingEfficiency)
      assert_equal(HPXML::BatteryLifetimeModelNone, battery.lifetimeModel)
      assert_in_epsilon(15, battery.numberofCellsinSeries, 0.01)
      assert_in_epsilon(125, battery.numberofStringsinParallel, 0.01)
      assert_in_epsilon(0.0, battery.initialFractionalStateofCharge, 0.01)
      assert_in_epsilon(198.0, battery.batteryMass, 0.01)
      assert_in_epsilon(2.25, battery.batterySurfaceArea, 0.01)
      assert_in_epsilon(20000, calc_nom_capacity(battery), 0.01)

      elcds = get_elcds(model, 'PVSystem')
      assert_equal(1, elcds.size)
      elcd = elcds[0]

      # Check object
      assert_equal('DirectCurrentWithInverterACStorage', elcd.electricalBussType)
      assert_equal(0.075, elcd.minimumStorageStateofChargeFraction)
      assert_equal(0.975, elcd.maximumStorageStateofChargeFraction)
      assert_equal(6000.0, elcd.designStorageControlChargePower.get)
      assert_equal(6000.0, elcd.designStorageControlDischargePower.get)
      assert(!elcd.demandLimitSchemePurchasedElectricDemandLimit.is_initialized)
      assert_equal('TrackFacilityElectricDemandStoreExcessOnSite', elcd.storageOperationScheme)
    end
  end

  def test_pv_battery_ah
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-pv-battery-ah.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.batteries.each do |hpxml_battery|
      batteries = get_batteries(model, hpxml_battery.id)
      assert_equal(1, batteries.size)
      battery = batteries[0]

      # Check object
      assert(!battery.thermalZone.is_initialized)
      assert_equal(0, battery.radiativeFraction)
      assert_equal(0.925, battery.dctoDCChargingEfficiency)
      assert_equal(HPXML::BatteryLifetimeModelNone, battery.lifetimeModel)
      assert_in_epsilon(15, battery.numberofCellsinSeries, 0.01)
      assert_in_epsilon(125, battery.numberofStringsinParallel, 0.01)
      assert_in_epsilon(0.0, battery.initialFractionalStateofCharge, 0.01)
      assert_in_epsilon(198.0, battery.batteryMass, 0.01)
      assert_in_epsilon(2.25, battery.batterySurfaceArea, 0.01)
      assert_in_epsilon(20000, calc_nom_capacity(battery), 0.01)

      elcds = get_elcds(model, 'PVSystem')
      assert_equal(1, elcds.size)
      elcd = elcds[0]

      # Check object
      assert_equal('DirectCurrentWithInverterACStorage', elcd.electricalBussType)
      assert_equal(0.075, elcd.minimumStorageStateofChargeFraction)
      assert_equal(0.975, elcd.maximumStorageStateofChargeFraction)
      assert_equal(6000.0, elcd.designStorageControlChargePower.get)
      assert_equal(6000.0, elcd.designStorageControlDischargePower.get)
      assert(!elcd.demandLimitSchemePurchasedElectricDemandLimit.is_initialized)
      assert_equal('TrackFacilityElectricDemandStoreExcessOnSite', elcd.storageOperationScheme)
    end
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
