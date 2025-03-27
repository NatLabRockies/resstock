# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioVehicleTest < Minitest::Test
  def teardown
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

  def test_vehicle_ev_default
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-misc-defaults.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.vehicles.each do |hpxml_ev|
      ev_batteries = get_batteries(model, hpxml_ev.id)
      assert_equal(1, ev_batteries.size)
      ev_battery = ev_batteries[0]

      # Check object
      assert_equal(0.0, ev_battery.radiativeFraction)
      assert_equal(HPXML::BatteryLifetimeModelNone, ev_battery.lifetimeModel)
      assert_in_epsilon(15, ev_battery.numberofCellsinSeries, 0.01)
      assert_in_epsilon(395, ev_battery.numberofStringsinParallel, 0.01)
      assert_in_epsilon(0.95, ev_battery.initialFractionalStateofCharge, 0.01)
      assert_in_epsilon(627.99, ev_battery.batteryMass, 0.01)
      assert_in_epsilon(4.87, ev_battery.batterySurfaceArea, 0.01)
      assert_in_epsilon(63364, calc_nom_capacity(ev_battery), 0.01)

      ev_elcds = get_elcds(model, hpxml_ev.id)
      assert_equal(1, ev_elcds.size)
      ev_elcd = ev_elcds[0]

      # Check object
      assert_equal('AlternatingCurrentWithStorage', ev_elcd.electricalBussType)
      assert_equal(0.15, ev_elcd.minimumStorageStateofChargeFraction)
      assert_equal(0.95, ev_elcd.maximumStorageStateofChargeFraction)
      assert_equal(5690.0, ev_elcd.designStorageControlChargePower.get)
      assert_in_epsilon(5225.84, ev_elcd.designStorageControlDischargePower.get, 0.01)
      assert(!ev_elcd.demandLimitSchemePurchasedElectricDemandLimit.is_initialized)
      assert_equal('TrackChargeDischargeSchedules', ev_elcd.storageOperationScheme)
      assert(ev_elcd.storageChargePowerFractionSchedule.is_initialized)
      assert(ev_elcd.storageDischargePowerFractionSchedule.is_initialized)
      assert(ev_elcd.storageConverter.is_initialized)
    end
  end

  def test_vehicle_ev_no_charger
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-vehicle-ev-no-charger.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    hpxml_bldg.vehicles.each do |hpxml_ev|
      next unless hpxml_ev.vehicle_type == HPXML::VehicleTypeBEV

      ev_batteries = get_batteries(model, hpxml_ev.id)
      assert_equal(0, ev_batteries.size) # no charger means no EV is generated

      ev_elcds = get_elcds(model, hpxml_ev.id)
      assert_equal(0, ev_elcds.size)
    end
  end

  def test_vehicle_ev_no_battery
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-ev-charger.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)
    assert_equal(0, model.getElectricLoadCenterStorageLiIonNMCBatterys.size)
    assert_equal(0, model.getElectricLoadCenterDistributions.size)
  end

  def test_vehicle_ev_default_schedule
    # EV battery w/ no schedules
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-vehicle-ev-charger.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.vehicles.each do |hpxml_ev|
      ev_batteries = get_batteries(model, hpxml_ev.id)
      assert_equal(1, ev_batteries.size)
      ev_battery = ev_batteries[0]

      # Check object
      assert_equal(0.0, ev_battery.radiativeFraction)
      assert_equal(HPXML::BatteryLifetimeModelNone, ev_battery.lifetimeModel)
      assert_in_epsilon(15, ev_battery.numberofCellsinSeries, 0.01)
      assert_in_epsilon(623, ev_battery.numberofStringsinParallel, 0.01)
      assert_in_epsilon(0.95, ev_battery.initialFractionalStateofCharge, 0.01)
      assert_in_epsilon(990.0, ev_battery.batteryMass, 0.01)
      assert_in_epsilon(6.59, ev_battery.batterySurfaceArea, 0.01)
      assert_in_epsilon(100000, calc_nom_capacity(ev_battery), 0.01)

      ev_elcds = get_elcds(model, hpxml_ev.id)
      assert_equal(1, ev_elcds.size)
      ev_elcd = ev_elcds[0]

      # Check object
      assert_equal('AlternatingCurrentWithStorage', ev_elcd.electricalBussType)
      assert_equal(0.15, ev_elcd.minimumStorageStateofChargeFraction)
      assert_equal(0.95, ev_elcd.maximumStorageStateofChargeFraction)
      assert_equal(7000.0, ev_elcd.designStorageControlChargePower.get)
      assert_in_epsilon(5448.13, ev_elcd.designStorageControlDischargePower.get, 0.01)
      assert(!ev_elcd.demandLimitSchemePurchasedElectricDemandLimit.is_initialized)
      assert_equal('TrackChargeDischargeSchedules', ev_elcd.storageOperationScheme)
      assert(ev_elcd.storageChargePowerFractionSchedule.is_initialized)
      assert(ev_elcd.storageDischargePowerFractionSchedule.is_initialized)
      assert(ev_elcd.storageConverter.is_initialized)
    end
  end

  def test_vehicle_ev_scheduled
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-vehicle-ev-charger-scheduled.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.vehicles.each do |hpxml_ev|
      ev_batteries = get_batteries(model, hpxml_ev.id)
      assert_equal(1, ev_batteries.size)
      ev_battery = ev_batteries[0]

      # Check object
      assert_equal(0.0, ev_battery.radiativeFraction)
      assert_equal(HPXML::BatteryLifetimeModelNone, ev_battery.lifetimeModel)
      assert_in_epsilon(15, ev_battery.numberofCellsinSeries, 0.01)
      assert_in_epsilon(623, ev_battery.numberofStringsinParallel, 0.01)
      assert_in_epsilon(0.95, ev_battery.initialFractionalStateofCharge, 0.01)
      assert_in_epsilon(990.0, ev_battery.batteryMass, 0.01)
      assert_in_epsilon(6.59, ev_battery.batterySurfaceArea, 0.01)
      assert_in_epsilon(100000, calc_nom_capacity(ev_battery), 0.01)

      ev_elcds = get_elcds(model, hpxml_ev.id)
      assert_equal(1, ev_elcds.size)
      ev_elcd = ev_elcds[0]

      # Check object
      assert_equal('AlternatingCurrentWithStorage', ev_elcd.electricalBussType)
      assert_equal(0.15, ev_elcd.minimumStorageStateofChargeFraction)
      assert_equal(0.95, ev_elcd.maximumStorageStateofChargeFraction)
      assert_equal(7000.0, ev_elcd.designStorageControlChargePower.get)
      assert_in_epsilon(5136.99, ev_elcd.designStorageControlDischargePower.get, 0.01)
      assert(!ev_elcd.demandLimitSchemePurchasedElectricDemandLimit.is_initialized)
      assert_equal('TrackChargeDischargeSchedules', ev_elcd.storageOperationScheme)
      assert(ev_elcd.storageChargePowerFractionSchedule.is_initialized)
      assert(ev_elcd.storageDischargePowerFractionSchedule.is_initialized)
      assert(ev_elcd.storageConverter.is_initialized)
    end
  end

  def test_vehicle_ev_plug_load_ev
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-vehicle-ev-charger-plug-load-ev.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    hpxml_bldg.vehicles.each do |hpxml_ev|
      next unless hpxml_ev.vehicle_type == HPXML::VehicleTypeBEV

      ev_batteries = get_batteries(model, hpxml_ev.id)
      assert_equal(0, ev_batteries.size) # plug load method take precedence to battery model

      ev_elcds = get_elcds(model, hpxml_ev.id)
      assert_equal(0, ev_elcds.size)
    end
  end

  def test_vehicle_ev_home_battery
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-pv-battery-and-vehicle-ev.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Test EV Battery
    hpxml_bldg.vehicles.each do |hpxml_ev|
      ev_batteries = get_batteries(model, hpxml_ev.id)
      assert_equal(1, ev_batteries.size)
      ev_battery = ev_batteries[0]

      # Check object
      assert_equal(0.0, ev_battery.radiativeFraction)
      assert_equal(HPXML::BatteryLifetimeModelNone, ev_battery.lifetimeModel)
      assert_in_epsilon(15, ev_battery.numberofCellsinSeries, 0.01)
      assert_in_epsilon(395, ev_battery.numberofStringsinParallel, 0.01)
      assert_in_epsilon(0.95, ev_battery.initialFractionalStateofCharge, 0.01)
      assert_in_epsilon(627.99, ev_battery.batteryMass, 0.01)
      assert_in_epsilon(4.87, ev_battery.batterySurfaceArea, 0.01)
      assert_in_epsilon(63364, calc_nom_capacity(ev_battery), 0.01)

      ev_elcds = get_elcds(model, hpxml_ev.id)
      assert_equal(1, ev_elcds.size)
      ev_elcd = ev_elcds[0]

      # Check object
      assert_equal('AlternatingCurrentWithStorage', ev_elcd.electricalBussType)
      assert_equal(0.15, ev_elcd.minimumStorageStateofChargeFraction)
      assert_equal(0.95, ev_elcd.maximumStorageStateofChargeFraction)
      assert_equal(5690.0, ev_elcd.designStorageControlChargePower.get)
      assert_in_epsilon(4927.397, ev_elcd.designStorageControlDischargePower.get, 0.01)
      assert(!ev_elcd.demandLimitSchemePurchasedElectricDemandLimit.is_initialized)
      assert_equal('TrackChargeDischargeSchedules', ev_elcd.storageOperationScheme)
      assert(ev_elcd.storageChargePowerFractionSchedule.is_initialized)
      assert(ev_elcd.storageDischargePowerFractionSchedule.is_initialized)
      assert(ev_elcd.storageConverter.is_initialized)
    end

    # Test Home Battery
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
