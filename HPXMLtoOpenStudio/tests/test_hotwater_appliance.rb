# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioHotWaterApplianceTest < Minitest::Test
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

  def get_ee_kwh(model, name)
    kwh_yr = 0.0
    model.getElectricEquipments.each do |ee|
      next unless ee.endUseSubcategory.start_with? name

      hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, ee.schedule.get)
      kwh_yr += UnitConversions.convert(hrs * ee.designLevel.get * ee.multiplier * ee.space.get.multiplier, 'Wh', 'kWh')
    end
    return kwh_yr
  end

  def get_ee_fractions(model, name)
    sens_frac = []
    lat_frac = []
    model.getElectricEquipments.each do |ee|
      next unless ee.endUseSubcategory.start_with? name

      sens_frac << 1.0 - ee.electricEquipmentDefinition.fractionLost - ee.electricEquipmentDefinition.fractionLatent
      lat_frac << ee.electricEquipmentDefinition.fractionLatent
    end
    if sens_frac.empty?
      return []
    else
      return sens_frac.sum(0.0) / sens_frac.size, lat_frac.sum(0.0) / lat_frac.size
    end
  end

  def get_oe_kbtu(model, name)
    kwh_yr = []
    model.getOtherEquipments.each do |oe|
      next unless oe.endUseSubcategory.start_with? name

      hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, oe.schedule.get)
      kwh_yr << UnitConversions.convert(hrs * oe.otherEquipmentDefinition.designLevel.get * oe.multiplier * oe.space.get.multiplier, 'Wh', 'kBtu')
    end
    if kwh_yr.empty?
      return
    else
      return kwh_yr.sum(0.0)
    end
  end

  def get_oe_fuel(model, name)
    fuel = []
    model.getOtherEquipments.each do |oe|
      next unless oe.endUseSubcategory.start_with? name

      fuel << oe.fuelType
    end
    if fuel.empty?
      return
    elsif fuel.uniq.size != 1
      flunk 'different fuels'
    else
      return fuel[0]
    end
  end

  def get_oe_fractions(model, name)
    sens_frac = []
    lat_frac = []
    model.getOtherEquipments.each do |oe|
      next unless oe.endUseSubcategory.start_with? name

      sens_frac << 1.0 - oe.otherEquipmentDefinition.fractionLost - oe.otherEquipmentDefinition.fractionLatent
      lat_frac << oe.otherEquipmentDefinition.fractionLatent
    end
    if sens_frac.empty?
      return []
    else
      return sens_frac.sum(0.0) / sens_frac.size, lat_frac.sum(0.0) / lat_frac.size
    end
  end

  def get_wu_gpd(model, name)
    gpd = []
    model.getWaterUseEquipments.each do |wue|
      next unless wue.waterUseEquipmentDefinition.endUseSubcategory.start_with? name

      full_load_hrs = Schedule.annual_equivalent_full_load_hrs(model.yearDescription.get.assumedYear, wue.flowRateFractionSchedule.get)
      gpd << UnitConversions.convert(full_load_hrs * wue.waterUseEquipmentDefinition.peakFlowRate * wue.multiplier, 'm^3/s', 'gal/min') * 60.0 / 365.0
    end
    if gpd.empty?
      return
    else
      return gpd.sum(0.0)
    end
  end

  def test_base
    hpxml_names = ['base.xml',
                   'base-misc-usage-multiplier.xml']

    hpxml_names.each do |hpxml_name|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_name))
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)

      # water use equipment hot water gal/day
      fixture_gpd = 44.87 * hpxml_bldg.water_heating.water_fixtures_usage_multiplier
      dist_gpd = 15.42 * hpxml_bldg.water_heating.water_fixtures_usage_multiplier
      cw_gpd = 3.52 * hpxml_bldg.clothes_washers[0].usage_multiplier
      dw_gpd = 2.44 * hpxml_bldg.dishwashers[0].usage_multiplier
      assert_in_delta(cw_gpd, get_wu_gpd(model, Constants::ObjectTypeClothesWasher), 0.01)
      assert_in_delta(dw_gpd, get_wu_gpd(model, Constants::ObjectTypeDishwasher), 0.01)
      assert_in_delta(fixture_gpd, get_wu_gpd(model, Constants::ObjectTypeFixtures), 0.01)
      assert_in_delta(dist_gpd, get_wu_gpd(model, Constants::ObjectTypeDistributionWaste), 0.01)

      # electric equipment
      cw_ee_kwh_yr = 101.7 * hpxml_bldg.clothes_washers[0].usage_multiplier
      cw_sens_frac = 0.27
      cw_lat_frac = 0.03
      assert_in_delta(cw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesWasher), 0.1)
      assert_in_delta(cw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[0], 0.01)
      assert_in_delta(cw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[1], 0.01)

      dw_ee_kwh_yr = 83.3 * hpxml_bldg.dishwashers[0].usage_multiplier
      dw_sens_frac = 0.3
      dw_lat_frac = 0.300
      assert_in_delta(dw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeDishwasher), 0.1)
      assert_in_delta(dw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[0], 0.01)
      assert_in_delta(dw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[1], 0.01)

      cd_ee_kwh_yr = 421.0 * hpxml_bldg.clothes_dryers[0].usage_multiplier
      cd_sens_frac = 0.135
      cd_lat_frac = 0.015
      assert_in_delta(cd_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesDryer), 0.1)
      assert_in_delta(cd_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
      assert_in_delta(cd_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

      rf_sens_frac = 1.0
      rf_lat_frac = 0.0
      assert_in_delta(rf_sens_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[0], 0.01)
      assert_in_delta(rf_lat_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[1], 0.01)

      cook_ee_kwh_yr = 448.0 * hpxml_bldg.cooking_ranges[0].usage_multiplier
      cook_sens_frac = 0.72
      cook_lat_frac = 0.080
      assert_in_delta(cook_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeCookingRange), 0.1)
      assert_in_delta(cook_sens_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
      assert_in_delta(cook_lat_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)

      # other equipment
      water_sens = -895.7 * hpxml_bldg.building_occupancy.general_water_use_usage_multiplier
      water_lat = 908.8 * hpxml_bldg.building_occupancy.general_water_use_usage_multiplier
      assert_in_delta(water_sens, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible), 0.1)
      assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[0], 0.01)
      assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[1], 0.01)

      assert_in_delta(water_lat, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent), 0.1)
      assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[0], 0.01)
      assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[1], 0.01)

      # mains temperature
      assert_equal('Correlation', model.getSiteWaterMainsTemperature.calculationMethod)
      assert_in_delta(10.88, model.getSiteWaterMainsTemperature.annualAverageOutdoorAirTemperature.get, 0.01)
      assert_in_delta(23.15, model.getSiteWaterMainsTemperature.maximumDifferenceInMonthlyAverageOutdoorAirTemperatures.get, 0.01)
      assert_in_delta(1.0, model.getSiteWaterMainsTemperature.temperatureMultiplier, 0.01)
      assert_in_delta(0.0, model.getSiteWaterMainsTemperature.temperatureOffset, 0.01)
    end
  end

  def test_dhw_multiple
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-multiple.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    fixture_gpd = 15.70
    dist_gpd = 5.40
    cw_gpd = 1.23
    dw_gpd = 0.85
    assert_in_delta(fixture_gpd, get_wu_gpd(model, Constants::ObjectTypeFixtures), 0.01)
    assert_in_delta(dist_gpd, get_wu_gpd(model, Constants::ObjectTypeDistributionWaste), 0.01)
    assert_in_delta(cw_gpd, get_wu_gpd(model, Constants::ObjectTypeClothesWasher), 0.01)
    assert_in_delta(dw_gpd, get_wu_gpd(model, Constants::ObjectTypeDishwasher), 0.01)

    # electric equipment
    cw_ee_kwh_yr = 101.7
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_delta(cw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesWasher), 0.1)
    assert_in_delta(cw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[0], 0.01)
    assert_in_delta(cw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[1], 0.01)

    dw_ee_kwh_yr = 83.3
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_delta(dw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeDishwasher), 0.1)
    assert_in_delta(dw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[0], 0.01)
    assert_in_delta(dw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[1], 0.01)

    cd_ee_kwh_yr = 421.0
    cd_sens_frac = 0.135
    cd_lat_frac = 0.015
    assert_in_delta(cd_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_in_delta(cd_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_delta(rf_sens_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[0], 0.01)
    assert_in_delta(rf_lat_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[1], 0.01)

    cook_ee_kwh_yr = 448.0
    cook_sens_frac = 0.72
    cook_lat_frac = 0.080
    assert_in_delta(cook_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_in_delta(cook_sens_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)

    # other equipment
    water_sens = -895.7
    water_lat = 908.8
    assert_in_delta(water_sens, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible), 0.1)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[0], 0.01)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[1], 0.01)

    assert_in_delta(water_lat, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent), 0.1)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[0], 0.01)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[1], 0.01)
  end

  def test_dhw_shared_water_heater_recirc
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-water-heater-recirc.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    fixture_gpd = 47.13
    dist_gpd = 16.07
    cw_gpd = 3.62
    dw_gpd = 2.49
    assert_in_delta(cw_gpd, get_wu_gpd(model, Constants::ObjectTypeClothesWasher), 0.01)
    assert_in_delta(dw_gpd, get_wu_gpd(model, Constants::ObjectTypeDishwasher), 0.01)
    assert_in_delta(fixture_gpd, get_wu_gpd(model, Constants::ObjectTypeFixtures), 0.01)
    assert_in_delta(dist_gpd, get_wu_gpd(model, Constants::ObjectTypeDistributionWaste), 0.01)

    # electric equipment
    cw_ee_kwh_yr = 104.6
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_delta(cw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesWasher), 0.1)
    assert_in_delta(cw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[0], 0.01)
    assert_in_delta(cw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[1], 0.01)

    dw_ee_kwh_yr = 85.2
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_delta(dw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeDishwasher), 0.1)
    assert_in_delta(dw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[0], 0.01)
    assert_in_delta(dw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[1], 0.01)

    cd_ee_kwh_yr = 432.9
    cd_sens_frac = 0.135
    cd_lat_frac = 0.015
    assert_in_delta(cd_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_in_delta(cd_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_delta(rf_sens_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[0], 0.01)
    assert_in_delta(rf_lat_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[1], 0.01)

    cook_ee_kwh_yr = 448.0
    cook_sens_frac = 0.72
    cook_lat_frac = 0.080
    assert_in_delta(cook_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_in_delta(cook_sens_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)

    # other equipment
    water_sens = -895.7
    water_lat = 908.8
    assert_in_delta(water_sens, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible), 0.1)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[0], 0.01)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[1], 0.01)

    assert_in_delta(water_lat, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent), 0.1)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[0], 0.01)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[1], 0.01)

    # recirc
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    pump_kwh_yr = 8.76 * hot_water_distribution.shared_recirculation_pump_power * hpxml_bldg.building_construction.number_of_bedrooms.to_f / hot_water_distribution.shared_recirculation_number_of_bedrooms_served
    assert_in_delta(pump_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeHotWaterRecircPump), 0.1)

    # zero bedroom
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-water-heater-recirc-beds-0.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # recirc
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    pump_kwh_yr = 8.76 * hot_water_distribution.shared_recirculation_pump_power * 1.0 / hot_water_distribution.shared_recirculation_number_of_bedrooms_served
    assert_in_delta(pump_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeHotWaterRecircPump), 0.1)
  end

  def test_dhw_shared_laundry
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-bldgtype-mf-unit-shared-laundry-room.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    fixture_gpd = 47.13
    dist_gpd = 16.07
    cw_gpd = 3.62
    dw_gpd = 2.49
    assert_in_delta(cw_gpd, get_wu_gpd(model, Constants::ObjectTypeClothesWasher), 0.01)
    assert_in_delta(dw_gpd, get_wu_gpd(model, Constants::ObjectTypeDishwasher), 0.01)
    assert_in_delta(fixture_gpd, get_wu_gpd(model, Constants::ObjectTypeFixtures), 0.01)
    assert_in_delta(dist_gpd, get_wu_gpd(model, Constants::ObjectTypeDistributionWaste), 0.01)

    # electric equipment
    cw_ee_kwh_yr = 104.6
    cw_sens_frac = 0.0
    cw_lat_frac = 0.0
    assert_in_delta(cw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesWasher), 0.1)
    assert_in_delta(cw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[0], 0.01)
    assert_in_delta(cw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[1], 0.01)

    dw_ee_kwh_yr = 85.2
    dw_sens_frac = 0.0
    dw_lat_frac = 0.0
    assert_in_delta(dw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeDishwasher), 0.1)
    assert_in_delta(dw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[0], 0.01)
    assert_in_delta(dw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[1], 0.01)

    cd_ee_kwh_yr = 432.9
    cd_sens_frac = 0.0
    cd_lat_frac = 0.0
    assert_in_delta(cd_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_in_delta(cd_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_delta(rf_sens_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[0], 0.01)
    assert_in_delta(rf_lat_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[1], 0.01)

    cook_ee_kwh_yr = 448.0
    cook_sens_frac = 0.72
    cook_lat_frac = 0.080
    assert_in_delta(cook_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_in_delta(cook_sens_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)

    # other equipment
    water_sens = -895.7
    water_lat = 908.8
    assert_in_delta(water_sens, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible), 0.1)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[0], 0.01)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[1], 0.01)

    assert_in_delta(water_lat, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent), 0.1)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[0], 0.01)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[1], 0.01)
  end

  def test_dhw_low_flow_fixtures
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-low-flow-fixtures.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    fixture_gpd = 42.63
    dist_gpd = 14.65
    assert_in_delta(fixture_gpd, get_wu_gpd(model, Constants::ObjectTypeFixtures), 0.01)
    assert_in_delta(dist_gpd, get_wu_gpd(model, Constants::ObjectTypeDistributionWaste), 0.01)
  end

  def test_dhw_dwhr
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-dwhr.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    fixture_gpd = 44.87
    dist_gpd = 15.42
    assert_in_delta(fixture_gpd, get_wu_gpd(model, Constants::ObjectTypeFixtures), 0.01)
    assert_in_delta(dist_gpd, get_wu_gpd(model, Constants::ObjectTypeDistributionWaste), 0.01)

    # mains temperature
    assert_equal('Correlation', model.getSiteWaterMainsTemperature.calculationMethod)
    assert_in_delta(10.88, model.getSiteWaterMainsTemperature.annualAverageOutdoorAirTemperature.get, 0.01)
    assert_in_delta(23.15, model.getSiteWaterMainsTemperature.maximumDifferenceInMonthlyAverageOutdoorAirTemperatures.get, 0.01)
    assert_in_delta(0.68, model.getSiteWaterMainsTemperature.temperatureMultiplier, 0.01)
    assert_in_delta(11.72, model.getSiteWaterMainsTemperature.temperatureOffset, 0.01)
  end

  def test_dhw_recirc_demand
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-recirc-demand.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    pump_kwh_yr = 0.15 * hot_water_distribution.recirculation_pump_power
    assert_in_delta(pump_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeHotWaterRecircPump), 0.1)
  end

  def test_dhw_recirc_manual
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-recirc-manual.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    pump_kwh_yr = 0.10 * hot_water_distribution.recirculation_pump_power
    assert_in_delta(pump_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeHotWaterRecircPump), 0.1)
  end

  def test_dhw_recirc_no_control
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-recirc-nocontrol.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    pump_kwh_yr = 8.76 * hot_water_distribution.recirculation_pump_power
    assert_in_delta(pump_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeHotWaterRecircPump), 0.1)
  end

  def test_dhw_recirc_timer
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-recirc-timer.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    pump_kwh_yr = 8.76 * hot_water_distribution.recirculation_pump_power
    assert_in_delta(pump_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeHotWaterRecircPump), 0.1)
  end

  def test_dhw_recirc_temp
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-dhw-recirc-temperature.xml'))
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Get HPXML values
    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]
    pump_kwh_yr = 1.46 * hot_water_distribution.recirculation_pump_power
    assert_in_delta(pump_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeHotWaterRecircPump), 0.1)
  end

  def test_appliances_none
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-appliances-none.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    assert_nil(get_wu_gpd(model, Constants::ObjectTypeClothesWasher))
    assert_nil(get_wu_gpd(model, Constants::ObjectTypeDishwasher))

    # electric equipment
    assert_equal(0.0, get_ee_kwh(model, Constants::ObjectTypeClothesWasher))
    assert(get_ee_fractions(model, Constants::ObjectTypeClothesWasher).empty?)

    assert_equal(0.0, get_ee_kwh(model, Constants::ObjectTypeDishwasher))
    assert(get_ee_fractions(model, Constants::ObjectTypeDishwasher).empty?)

    assert_equal(0.0, get_ee_kwh(model, Constants::ObjectTypeClothesDryer))
    assert(get_ee_fractions(model, Constants::ObjectTypeClothesDryer).empty?)

    assert_equal(0.0, get_ee_kwh(model, Constants::ObjectTypeRefrigerator))
    assert(get_ee_fractions(model, Constants::ObjectTypeRefrigerator).empty?)

    assert_equal(0.0, get_ee_kwh(model, Constants::ObjectTypeCookingRange))
    assert(get_ee_fractions(model, Constants::ObjectTypeCookingRange).empty?)

    # other equipment
    water_sens = -895.7
    water_lat = 908.8
    assert_in_delta(water_sens, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible), 0.1)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[0], 0.01)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[1], 0.01)

    assert_in_delta(water_lat, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent), 0.1)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[0], 0.01)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[1], 0.01)
  end

  def test_appliances_modified
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-appliances-modified.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    cw_gpd = 3.52
    dw_gpd = 4.89
    assert_in_delta(cw_gpd, get_wu_gpd(model, Constants::ObjectTypeClothesWasher), 0.01)
    assert_in_delta(dw_gpd, get_wu_gpd(model, Constants::ObjectTypeDishwasher), 0.01)

    # electric equipment
    cw_ee_kwh_yr = 101.7
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_delta(cw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesWasher), 0.1)
    assert_in_delta(cw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[0], 0.01)
    assert_in_delta(cw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[1], 0.01)

    dw_ee_kwh_yr = 166.5
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_delta(dw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeDishwasher), 0.1)
    assert_in_delta(dw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[0], 0.01)
    assert_in_delta(dw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[1], 0.01)

    cd_ee_kwh_yr = 422.7
    cd_sens_frac = 0.9
    cd_lat_frac = 0.1
    assert_in_delta(cd_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_in_delta(cd_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_delta(rf_sens_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[0], 0.01)
    assert_in_delta(rf_lat_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[1], 0.01)

    cook_ee_kwh_yr = 448.0
    cook_sens_frac = 0.72
    cook_lat_frac = 0.080
    assert_in_delta(cook_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_in_delta(cook_sens_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)

    # other equipment
    water_sens = -895.7
    water_lat = 908.8
    assert_in_delta(water_sens, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible), 0.1)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[0], 0.01)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[1], 0.01)

    assert_in_delta(water_lat, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent), 0.1)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[0], 0.01)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[1], 0.01)
  end

  def test_appliances_oil
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-appliances-oil.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    cw_gpd = 3.52
    dw_gpd = 2.44
    assert_in_delta(cw_gpd, get_wu_gpd(model, Constants::ObjectTypeClothesWasher), 0.01)
    assert_in_delta(dw_gpd, get_wu_gpd(model, Constants::ObjectTypeDishwasher), 0.01)

    # electric equipment
    cw_ee_kwh_yr = 101.7
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_delta(cw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesWasher), 0.1)
    assert_in_delta(cw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[0], 0.01)
    assert_in_delta(cw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[1], 0.01)

    dw_ee_kwh_yr = 83.3
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_delta(dw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeDishwasher), 0.1)
    assert_in_delta(dw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[0], 0.01)
    assert_in_delta(dw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[1], 0.01)

    cd_ee_kwh_yr = 37.6
    cd_sens_frac = 0.135
    cd_lat_frac = 0.015
    assert_in_delta(cd_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_in_delta(cd_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_delta(rf_sens_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[0], 0.01)
    assert_in_delta(rf_lat_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[1], 0.01)

    cook_ee_kwh_yr = 30.7
    cook_sens_frac = 0.64
    cook_lat_frac = 0.16
    assert_in_delta(cook_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_in_delta(cook_sens_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)

    # other equipment
    water_sens = -895.7
    water_lat = 908.8
    assert_in_delta(water_sens, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible), 0.1)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[0], 0.01)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[1], 0.01)

    assert_in_delta(water_lat, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent), 0.1)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[0], 0.01)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[1], 0.01)

    cd_fuel_kwh = 1706.6
    assert_in_delta(cd_fuel_kwh, get_oe_kbtu(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_equal(EPlus::FuelTypeOil, get_oe_fuel(model, Constants::ObjectTypeClothesDryer))
    assert_in_delta(cd_sens_frac, get_oe_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_oe_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    cook_fuel_kwh = 3070.0
    assert_in_delta(cook_fuel_kwh, get_oe_kbtu(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_equal(EPlus::FuelTypeOil, get_oe_fuel(model, Constants::ObjectTypeCookingRange))
    assert_in_delta(cook_sens_frac, get_oe_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_oe_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)
  end

  def test_appliances_gas
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-appliances-gas.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    cw_gpd = 3.52
    dw_gpd = 2.44
    assert_in_delta(cw_gpd, get_wu_gpd(model, Constants::ObjectTypeClothesWasher), 0.01)
    assert_in_delta(dw_gpd, get_wu_gpd(model, Constants::ObjectTypeDishwasher), 0.01)

    # electric equipment
    cw_ee_kwh_yr = 101.7
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_delta(cw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesWasher), 0.1)
    assert_in_delta(cw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[0], 0.01)
    assert_in_delta(cw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[1], 0.01)

    dw_ee_kwh_yr = 83.3
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_delta(dw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeDishwasher), 0.1)
    assert_in_delta(dw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[0], 0.01)
    assert_in_delta(dw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[1], 0.01)

    cd_ee_kwh_yr = 37.6
    cd_sens_frac = 0.135
    cd_lat_frac = 0.015
    assert_in_delta(cd_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_in_delta(cd_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_delta(rf_sens_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[0], 0.01)
    assert_in_delta(rf_lat_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[1], 0.01)

    cook_ee_kwh_yr = 30.7
    cook_sens_frac = 0.64
    cook_lat_frac = 0.16
    assert_in_delta(cook_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_in_delta(cook_sens_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)

    # other equipment
    water_sens = -895.7
    water_lat = 908.8
    assert_in_delta(water_sens, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible), 0.1)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[0], 0.01)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[1], 0.01)

    assert_in_delta(water_lat, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent), 0.1)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[0], 0.01)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[1], 0.01)

    cd_fuel_kwh = 1706.6
    assert_in_delta(cd_fuel_kwh, get_oe_kbtu(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_equal(EPlus::FuelTypeNaturalGas, get_oe_fuel(model, Constants::ObjectTypeClothesDryer))
    assert_in_delta(cd_sens_frac, get_oe_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_oe_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    cook_fuel_kwh = 3070.0
    assert_in_delta(cook_fuel_kwh, get_oe_kbtu(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_equal(EPlus::FuelTypeNaturalGas, get_oe_fuel(model, Constants::ObjectTypeCookingRange))
    assert_in_delta(cook_sens_frac, get_oe_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_oe_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)
  end

  def test_appliances_propane
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-appliances-propane.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    cw_gpd = 3.52
    dw_gpd = 2.44
    assert_in_delta(cw_gpd, get_wu_gpd(model, Constants::ObjectTypeClothesWasher), 0.01)
    assert_in_delta(dw_gpd, get_wu_gpd(model, Constants::ObjectTypeDishwasher), 0.01)

    # electric equipment
    cw_ee_kwh_yr = 101.7
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_delta(cw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesWasher), 0.1)
    assert_in_delta(cw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[0], 0.01)
    assert_in_delta(cw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[1], 0.01)

    dw_ee_kwh_yr = 83.3
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_delta(dw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeDishwasher), 0.1)
    assert_in_delta(dw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[0], 0.01)
    assert_in_delta(dw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[1], 0.01)

    cd_ee_kwh_yr = 37.6
    cd_sens_frac = 0.135
    cd_lat_frac = 0.015
    assert_in_delta(cd_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_in_delta(cd_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_delta(rf_sens_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[0], 0.01)
    assert_in_delta(rf_lat_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[1], 0.01)

    cook_ee_kwh_yr = 30.7
    cook_sens_frac = 0.64
    cook_lat_frac = 0.16
    assert_in_delta(cook_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_in_delta(cook_sens_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)

    # other equipment
    water_sens = -895.7
    water_lat = 908.8
    assert_in_delta(water_sens, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible), 0.1)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[0], 0.01)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[1], 0.01)

    assert_in_delta(water_lat, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent), 0.1)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[0], 0.01)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[1], 0.01)

    cd_fuel_kwh = 1706.6
    assert_in_delta(cd_fuel_kwh, get_oe_kbtu(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_equal(EPlus::FuelTypePropane, get_oe_fuel(model, Constants::ObjectTypeClothesDryer))
    assert_in_delta(cd_sens_frac, get_oe_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_oe_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    cook_fuel_kwh = 3070.0
    assert_in_delta(cook_fuel_kwh, get_oe_kbtu(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_equal(EPlus::FuelTypePropane, get_oe_fuel(model, Constants::ObjectTypeCookingRange))
    assert_in_delta(cook_sens_frac, get_oe_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_oe_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)
  end

  def test_appliances_wood
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-appliances-wood.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    cw_gpd = 3.52
    dw_gpd = 2.44
    assert_in_delta(cw_gpd, get_wu_gpd(model, Constants::ObjectTypeClothesWasher), 0.01)
    assert_in_delta(dw_gpd, get_wu_gpd(model, Constants::ObjectTypeDishwasher), 0.01)

    # electric equipment
    cw_ee_kwh_yr = 101.7
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_delta(cw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesWasher), 0.1)
    assert_in_delta(cw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[0], 0.01)
    assert_in_delta(cw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[1], 0.01)

    dw_ee_kwh_yr = 83.3
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_delta(dw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeDishwasher), 0.1)
    assert_in_delta(dw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[0], 0.01)
    assert_in_delta(dw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[1], 0.01)

    cd_ee_kwh_yr = 37.6
    cd_sens_frac = 0.135
    cd_lat_frac = 0.015
    assert_in_delta(cd_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_in_delta(cd_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_delta(rf_sens_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[0], 0.01)
    assert_in_delta(rf_lat_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[1], 0.01)

    cook_ee_kwh_yr = 30.7
    cook_sens_frac = 0.64
    cook_lat_frac = 0.16
    assert_in_delta(cook_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_in_delta(cook_sens_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)

    # other equipment
    water_sens = -895.7
    water_lat = 908.8
    assert_in_delta(water_sens, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible), 0.1)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[0], 0.01)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[1], 0.01)

    assert_in_delta(water_lat, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent), 0.1)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[0], 0.01)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[1], 0.01)

    cd_fuel_kwh = 1706.6
    assert_in_delta(cd_fuel_kwh, get_oe_kbtu(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_equal(EPlus::FuelTypeWoodCord, get_oe_fuel(model, Constants::ObjectTypeClothesDryer))
    assert_in_delta(cd_sens_frac, get_oe_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_oe_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    cook_fuel_kwh = 3070.0
    assert_in_delta(cook_fuel_kwh, get_oe_kbtu(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_equal(EPlus::FuelTypeWoodCord, get_oe_fuel(model, Constants::ObjectTypeCookingRange))
    assert_in_delta(cook_sens_frac, get_oe_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_oe_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)
  end

  def test_appliances_coal
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-appliances-coal.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    cw_gpd = 3.52
    dw_gpd = 2.44
    assert_in_delta(cw_gpd, get_wu_gpd(model, Constants::ObjectTypeClothesWasher), 0.01)
    assert_in_delta(dw_gpd, get_wu_gpd(model, Constants::ObjectTypeDishwasher), 0.01)

    # electric equipment
    cw_ee_kwh_yr = 101.7
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_delta(cw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesWasher), 0.1)
    assert_in_delta(cw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[0], 0.01)
    assert_in_delta(cw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[1], 0.01)

    dw_ee_kwh_yr = 83.3
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_delta(dw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeDishwasher), 0.1)
    assert_in_delta(dw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[0], 0.01)
    assert_in_delta(dw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[1], 0.01)

    cd_ee_kwh_yr = 37.6
    cd_sens_frac = 0.135
    cd_lat_frac = 0.015
    assert_in_delta(cd_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_in_delta(cd_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_delta(rf_sens_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[0], 0.01)
    assert_in_delta(rf_lat_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[1], 0.01)

    cook_ee_kwh_yr = 30.7
    cook_sens_frac = 0.64
    cook_lat_frac = 0.16
    assert_in_delta(cook_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_in_delta(cook_sens_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)

    # other equipment
    water_sens = -895.7
    water_lat = 908.8
    assert_in_delta(water_sens, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible), 0.1)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[0], 0.01)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[1], 0.01)

    assert_in_delta(water_lat, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent), 0.1)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[0], 0.01)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[1], 0.01)

    cd_fuel_kwh = 1706.6
    assert_in_delta(cd_fuel_kwh, get_oe_kbtu(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_equal(EPlus::FuelTypeCoal, get_oe_fuel(model, Constants::ObjectTypeClothesDryer))
    assert_in_delta(cd_sens_frac, get_oe_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_oe_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    cook_fuel_kwh = 3070.0
    assert_in_delta(cook_fuel_kwh, get_oe_kbtu(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_equal(EPlus::FuelTypeCoal, get_oe_fuel(model, Constants::ObjectTypeCookingRange))
    assert_in_delta(cook_sens_frac, get_oe_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_oe_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)
  end

  def test_operational_0_occupants
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-residents-0.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    assert_equal(0, get_wu_gpd(model, Constants::ObjectTypeClothesWasher))
    assert_equal(0, get_wu_gpd(model, Constants::ObjectTypeDishwasher))
    assert_equal(0, get_wu_gpd(model, Constants::ObjectTypeFixtures))
    assert_equal(0, get_wu_gpd(model, Constants::ObjectTypeDistributionWaste))

    # electric equipment
    assert_equal(0, get_ee_kwh(model, Constants::ObjectTypeClothesWasher))
    assert_equal(0, get_ee_kwh(model, Constants::ObjectTypeDishwasher))
    assert_equal(0, get_ee_kwh(model, Constants::ObjectTypeClothesDryer))
    assert_equal(0, get_ee_kwh(model, Constants::ObjectTypeCookingRange))

    # other equipment
    assert_equal(0, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible))
    assert_equal(0, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent))
  end

  def test_operational_1_occupant
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-residents-1.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    fixture_gpd = 13.76
    dist_gpd = 7.16
    cw_gpd = 2.25
    dw_gpd = 1.71
    assert_in_delta(cw_gpd, get_wu_gpd(model, Constants::ObjectTypeClothesWasher), 0.01)
    assert_in_delta(dw_gpd, get_wu_gpd(model, Constants::ObjectTypeDishwasher), 0.01)
    assert_in_delta(fixture_gpd, get_wu_gpd(model, Constants::ObjectTypeFixtures), 0.01)
    assert_in_delta(dist_gpd, get_wu_gpd(model, Constants::ObjectTypeDistributionWaste), 0.01)

    # electric equipment
    cw_ee_kwh_yr = 64.9
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_delta(cw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesWasher), 0.1)
    assert_in_delta(cw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[0], 0.01)
    assert_in_delta(cw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[1], 0.01)

    dw_ee_kwh_yr = 58.5
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_delta(dw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeDishwasher), 0.1)
    assert_in_delta(dw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[0], 0.01)
    assert_in_delta(dw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[1], 0.01)

    cd_ee_kwh_yr = 268.8
    cd_sens_frac = 0.135
    cd_lat_frac = 0.015
    assert_in_delta(cd_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_in_delta(cd_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_delta(rf_sens_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[0], 0.01)
    assert_in_delta(rf_lat_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[1], 0.01)

    cook_ee_kwh_yr = 326.7
    cook_sens_frac = 0.72
    cook_lat_frac = 0.080
    assert_in_delta(cook_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_in_delta(cook_sens_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)

    # other equipment
    water_sens = -431.4
    water_lat = 437.8
    assert_in_delta(water_sens, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible), 0.1)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[0], 0.01)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[1], 0.01)

    assert_in_delta(water_lat, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent), 0.1)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[0], 0.01)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[1], 0.01)
  end

  def test_operational_5point5_occupants
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-residents-5-5.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

    # water use equipment hot water gal/day
    fixture_gpd = 97.46
    dist_gpd = 23.61
    cw_gpd = 6.67
    dw_gpd = 5.72
    assert_in_delta(cw_gpd, get_wu_gpd(model, Constants::ObjectTypeClothesWasher), 0.01)
    assert_in_delta(dw_gpd, get_wu_gpd(model, Constants::ObjectTypeDishwasher), 0.01)
    assert_in_delta(fixture_gpd, get_wu_gpd(model, Constants::ObjectTypeFixtures), 0.01)
    assert_in_delta(dist_gpd, get_wu_gpd(model, Constants::ObjectTypeDistributionWaste), 0.01)

    # electric equipment
    cw_ee_kwh_yr = 149.6
    cw_sens_frac = 0.27
    cw_lat_frac = 0.03
    assert_in_delta(cw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesWasher), 0.1)
    assert_in_delta(cw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[0], 0.01)
    assert_in_delta(cw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesWasher)[1], 0.01)

    dw_ee_kwh_yr = 173.8
    dw_sens_frac = 0.3
    dw_lat_frac = 0.300
    assert_in_delta(dw_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeDishwasher), 0.1)
    assert_in_delta(dw_sens_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[0], 0.01)
    assert_in_delta(dw_lat_frac, get_ee_fractions(model, Constants::ObjectTypeDishwasher)[1], 0.01)

    cd_ee_kwh_yr = 1113.0
    cd_sens_frac = 0.135
    cd_lat_frac = 0.015
    assert_in_delta(cd_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeClothesDryer), 0.1)
    assert_in_delta(cd_sens_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[0], 0.01)
    assert_in_delta(cd_lat_frac, get_ee_fractions(model, Constants::ObjectTypeClothesDryer)[1], 0.01)

    rf_sens_frac = 1.0
    rf_lat_frac = 0.0
    assert_in_delta(rf_sens_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[0], 0.01)
    assert_in_delta(rf_lat_frac, get_ee_fractions(model, Constants::ObjectTypeRefrigerator)[1], 0.01)

    cook_ee_kwh_yr = 691.8
    cook_sens_frac = 0.72
    cook_lat_frac = 0.080
    assert_in_delta(cook_ee_kwh_yr, get_ee_kwh(model, Constants::ObjectTypeCookingRange), 0.1)
    assert_in_delta(cook_sens_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[0], 0.01)
    assert_in_delta(cook_lat_frac, get_ee_fractions(model, Constants::ObjectTypeCookingRange)[1], 0.01)

    # other equipment
    water_sens = -1828.7
    water_lat = 1855.6
    assert_in_delta(water_sens, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseSensible), 0.1)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[0], 0.01)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseSensible)[1], 0.01)

    assert_in_delta(water_lat, get_oe_kbtu(model, Constants::ObjectTypeGeneralWaterUseLatent), 0.1)
    assert_in_delta(0.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[0], 0.01)
    assert_in_delta(1.0, get_oe_fractions(model, Constants::ObjectTypeGeneralWaterUseLatent)[1], 0.01)
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
end
