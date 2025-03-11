# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
# require 'csv'
require_relative '../measure.rb'

class BuildResidentialScheduleFileTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @tmp_output_path = File.join(@sample_files_path, 'tmp_output')
    @tmp_schedule_file_path = File.join(@sample_files_path, 'tmp.csv')
    FileUtils.mkdir_p(@tmp_output_path)

    @args_hash = {}
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    @args_hash['hpxml_output_path'] = @args_hash['hpxml_path']
    @year = 2007
    @tol = 0.005
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    File.delete(@tmp_schedule_file_path) if File.exist? @tmp_schedule_file_path
    FileUtils.rm_rf(@tmp_output_path)
  end

  def test_stochastic
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'occupancy-stochastic.csv'))
    hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('stochastic schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?("SimYear=#{@year}") })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=CO') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('RandomSeed') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('TimeZoneUTCOffset=-7.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Latitude=39.83') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Longitude=-104.65') })

    sf = SchedulesFile.new(schedules_paths: hpxml.buildings[0].header.schedules_filepaths,
                           year: @year,
                           output_path: @tmp_schedule_file_path)

    expected_values = {
      Occupants: 6689,
      LightingInterior: 2102.7,
      CookingRange: 300.9,
      Dishwasher: 161.5,
      ClothesWasher: 67.7,
      ClothesDryer: 114.0,
      PlugLoadsOther: 5424.3,
      PlugLoadsTV: 1542.2,
      HotWaterDishwasher: 287.3,
      HotWaterClothesWasher: 322.6,
      HotWaterFixtures: 981.2,
    }
    assert_full_load_hrs_match(sf, expected_values, @tol)
    assert(!sf.schedules.keys.include?(SchedulesFile::Columns[:Sleeping].name))
  end

  def test_stochastic_subset_of_columns
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    columns = [SchedulesFile::Columns[:CookingRange].name,
               SchedulesFile::Columns[:Dishwasher].name,
               SchedulesFile::Columns[:HotWaterDishwasher].name,
               SchedulesFile::Columns[:ClothesWasher].name,
               SchedulesFile::Columns[:HotWaterClothesWasher].name,
               SchedulesFile::Columns[:ClothesDryer].name,
               SchedulesFile::Columns[:HotWaterFixtures].name]

    @args_hash['schedules_type'] = 'stochastic'
    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'occupancy-stochastic.csv'))
    @args_hash['schedules_column_names'] = columns.join(', ')
    hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('ColumnNames') })

    sf = SchedulesFile.new(schedules_paths: hpxml.buildings[0].header.schedules_filepaths,
                           year: @year,
                           output_path: @tmp_schedule_file_path)

    columns.each do |column|
      assert(sf.schedules.keys.include?(column))
    end
    (SchedulesFile::Columns.values.map { |c| c.name } - columns).each do |column|
      assert(!sf.schedules.keys.include?(column))
    end
  end

  def test_stochastic_subset_of_columns_invalid_name
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    @args_hash['schedules_type'] = 'stochastic'
    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'occupancy-stochastic.csv'))
    @args_hash['schedules_column_names'] = "foobar, #{SchedulesFile::Columns[:CookingRange].name}, foobar2"
    _hpxml, result = _test_measure(expect_fail: true)

    error_msgs = result.errors.map { |x| x.logMessage }
    assert(error_msgs.any? { |error_msg| error_msg.include?("Invalid column name specified: 'foobar'.") })
    assert(error_msgs.any? { |error_msg| error_msg.include?("Invalid column name specified: 'foobar2'.") })
  end

  def test_stochastic_location_detailed
    hpxml = _create_hpxml('base-location-detailed.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'occupancy-stochastic.csv'))
    hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('stochastic schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?("SimYear=#{@year}") })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=CO') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('RandomSeed') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('TimeZoneUTCOffset=-6.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Latitude=39.77') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Longitude=-104.73') })

    sf = SchedulesFile.new(schedules_paths: hpxml.buildings[0].header.schedules_filepaths,
                           year: @year,
                           output_path: @tmp_schedule_file_path)

    expected_values = {
      Occupants: 6689,
      LightingInterior: 2002.2,
      CookingRange: 300.9,
      Dishwasher: 161.5,
      ClothesWasher: 67.7,
      ClothesDryer: 114.0,
      PlugLoadsOther: 5424.3,
      PlugLoadsTV: 1542.2,
      HotWaterDishwasher: 287.3,
      HotWaterClothesWasher: 322.6,
      HotWaterFixtures: 981.2,
    }
    assert_full_load_hrs_match(sf, expected_values, @tol)
    assert(!sf.schedules.keys.include?(SchedulesFile::Columns[:Sleeping].name))
  end

  def test_stochastic_debug
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'occupancy-stochastic.csv'))
    @args_hash['debug'] = true
    hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('stochastic schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?("SimYear=#{@year}") })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=CO') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('RandomSeed') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('TimeZoneUTCOffset=-7.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Latitude=39.83') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Longitude=-104.65') })

    sf = SchedulesFile.new(schedules_paths: hpxml.buildings[0].header.schedules_filepaths,
                           year: @year,
                           output_path: @tmp_schedule_file_path)

    expected_values = {
      Occupants: 6689,
      LightingInterior: 2102.7,
      CookingRange: 300.9,
      Dishwasher: 161.5,
      ClothesWasher: 67.7,
      ClothesDryer: 114.0,
      PlugLoadsOther: 5424.3,
      PlugLoadsTV: 1542.2,
      HotWaterDishwasher: 287.3,
      HotWaterClothesWasher: 322.6,
      HotWaterFixtures: 981.2,
      Sleeping: 3101.7,
    }
    assert_full_load_hrs_match(sf, expected_values, @tol)
  end

  def test_random_seed
    hpxml = _create_hpxml('base-location-baltimore-md.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    @args_hash['schedules_random_seed'] = 1
    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'occupancy-stochastic.csv'))
    hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('stochastic schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?("SimYear=#{@year}") })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=MD') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('RandomSeed=1') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('TimeZoneUTCOffset=-5.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Latitude=39.17') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Longitude=-76.68') })

    sf = SchedulesFile.new(schedules_paths: hpxml.buildings[0].header.schedules_filepaths,
                           year: @year,
                           output_path: @tmp_schedule_file_path)
    expected_values = {
      Occupants: 6689,
      LightingInterior: 2070,
      CookingRange: 300,
      Dishwasher: 161,
      ClothesWasher: 64,
      ClothesDryer: 113.9,
      PlugLoadsOther: 5425.6,
      PlugLoadsTV: 1517,
      HotWaterDishwasher: 304,
      HotWaterClothesWasher: 322,
      HotWaterFixtures: 936,
    }
    assert_full_load_hrs_match(sf, expected_values, @tol)

    assert(!sf.schedules.keys.include?(SchedulesFile::Columns[:Sleeping].name))
    assert(!sf.schedules.keys.include?(SchedulesFile::Columns[:EVOccupant].name))

    @args_hash['schedules_random_seed'] = 2
    hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('stochastic schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?("SimYear=#{@year}") })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=MD') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('RandomSeed=2') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('TimeZoneUTCOffset=-5.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Latitude=39.17') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Longitude=-76.68') })

    sf = SchedulesFile.new(schedules_paths: hpxml.buildings[0].header.schedules_filepaths,
                           year: @year,
                           output_path: @tmp_schedule_file_path)
    expected_values = {
      Occupants: 6072,
      LightingInterior: 1767.5,
      CookingRange: 336,
      Dishwasher: 297,
      ClothesWasher: 116,
      ClothesDryer: 188,
      PlugLoadsOther: 5336.9,
      PlugLoadsTV: 1205,
      HotWaterDishwasher: 243,
      HotWaterClothesWasher: 263,
      HotWaterFixtures: 1049,
    }
    assert_full_load_hrs_match(sf, expected_values, @tol)
  end

  def test_10_min_timestep
    hpxml = _create_hpxml('base-simcontrol-timestep-10-mins.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'occupancy-stochastic.csv'))
    hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('stochastic schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?("SimYear=#{@year}") })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=10') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=CO') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('RandomSeed') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('TimeZoneUTCOffset=-7.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Latitude=39.83') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Longitude=-104.65') })

    sf = SchedulesFile.new(schedules_paths: hpxml.buildings[0].header.schedules_filepaths,
                           year: @year,
                           output_path: @tmp_schedule_file_path)

    expected_values = {
      Occupants: 6707,
      LightingInterior: 2077,
      CookingRange: 300.9,
      Dishwasher: 161.4,
      ClothesWasher: 64.3,
      ClothesDryer: 114.0,
      PlugLoadsOther: 5393,
      PlugLoadsTV: 1505,
      HotWaterDishwasher: 155.9,
      HotWaterClothesWasher: 138.4,
      HotWaterFixtures: 280.2,
    }
    assert_full_load_hrs_match(sf, expected_values, @tol)
    assert(!sf.schedules.keys.include?(SchedulesFile::Columns[:Sleeping].name))
  end

  def test_non_integer_number_of_occupants
    num_occupants = 3.2

    hpxml = _create_hpxml('base.xml')
    hpxml.buildings[0].building_occupancy.number_of_residents = num_occupants
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'occupancy-stochastic.csv'))
    _hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?("GeometryNumOccupants=#{Float(Integer(num_occupants))}") })
  end

  def test_zero_occupants
    num_occupants = 0.0

    hpxml = _create_hpxml('base.xml')
    hpxml.buildings[0].building_occupancy.number_of_residents = num_occupants
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'occupancy-stochastic.csv'))
    _hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    assert(1, info_msgs.size)
    assert(info_msgs.any? { |info_msg| info_msg.include?('Number of occupants set to zero; skipping generation of stochastic schedules.') })
    assert(!File.exist?(@args_hash['output_csv_path']))
    assert_empty(hpxml.buildings[0].header.schedules_filepaths)
  end

  def test_ev_battery
    num_occupants = 1.0

    hpxml = _create_hpxml('base-vehicle-ev-charger.xml')
    hpxml.buildings[0].building_occupancy.number_of_residents = num_occupants
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'occupancy-stochastic.csv'))
    hpxml, _result = _test_measure()
    sf = SchedulesFile.new(schedules_paths: hpxml.buildings[0].header.schedules_filepaths,
                           year: @year,
                           output_path: @tmp_schedule_file_path)
    assert_in_epsilon(5762, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ElectricVehicleCharging].name, schedules: sf.tmp_schedules), @tol)
    assert_in_epsilon(729.9, sf.annual_equivalent_full_load_hrs(col_name: SchedulesFile::Columns[:ElectricVehicleDischarging].name, schedules: sf.tmp_schedules), @tol)
  end

  def test_multiple_buildings
    hpxml = _create_hpxml('base-bldgtype-mf-whole-building.xml')
    hpxml.buildings.each do |hpxml_bldg|
      hpxml_bldg.header.schedules_filepaths = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'occupancy-stochastic.csv'))
    @args_hash['building_id'] = 'ALL'
    hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('stochastic schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?("SimYear=#{@year}") })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=CO') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('RandomSeed') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('TimeZoneUTCOffset=-7.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Latitude=39.83') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Longitude=-104.65') })

    hpxml.buildings.each do |hpxml_bldg|
      sf = SchedulesFile.new(schedules_paths: hpxml_bldg.header.schedules_filepaths,
                             year: @year,
                             output_path: @tmp_schedule_file_path)

      if hpxml_bldg.building_id == 'MyBuilding'
        assert_equal(1, hpxml_bldg.header.schedules_filepaths.size)
        assert(hpxml_bldg.header.schedules_filepaths[0].include? 'occupancy-stochastic.csv')
        expected_values = {
          Occupants: 6689,
          LightingInterior: 2102.7,
          CookingRange: 300.9,
          Dishwasher: 161.5,
          ClothesWasher: 67.7,
          PlugLoadsOther: 5424.3,
          PlugLoadsTV: 1542.2,
          HotWaterDishwasher: 287.3,
          HotWaterClothesWasher: 322.6,
          HotWaterFixtures: 981.2,
        }
        assert_full_load_hrs_match(sf, expected_values, @tol)
      elsif hpxml_bldg.building_id == 'MyBuilding_2'
        assert_equal(1, hpxml_bldg.header.schedules_filepaths.size)
        assert(hpxml_bldg.header.schedules_filepaths[0].include? 'occupancy-stochastic_2.csv')
        expected_values = {
          Occupants: 6072,
          LightingInterior: 1765,
          CookingRange: 336.4,
          Dishwasher: 297.4,
          ClothesWasher: 116.3,
          PlugLoadsOther: 5336.8,
          PlugLoadsTV: 1205,
          HotWaterDishwasher: 229.8,
          HotWaterClothesWasher: 246.5,
          HotWaterFixtures: 956.4,
        }
        assert_full_load_hrs_match(sf, expected_values, @tol)
      elsif hpxml_bldg.building_id == 'MyBuilding_3'
        assert_equal(1, hpxml_bldg.header.schedules_filepaths.size)
        assert(hpxml_bldg.header.schedules_filepaths[0].include? 'occupancy-stochastic_3.csv')
        expected_values = {
          Occupants: 6045,
          LightingInterior: 1816.3,
          CookingRange: 358.5,
          Dishwasher: 207.2,
          ClothesWasher: 126.4,
          PlugLoadsOther: 5359.8,
          PlugLoadsTV: 1182.2,
          HotWaterDishwasher: 232.1,
          HotWaterClothesWasher: 206.8,
          HotWaterFixtures: 857.1,
        }
        assert_full_load_hrs_match(sf, expected_values, @tol)
      end
    end
  end

  def test_multiple_buildings_id
    hpxml = _create_hpxml('base-bldgtype-mf-whole-building.xml')
    hpxml.buildings.each do |hpxml_bldg|
      hpxml_bldg.header.schedules_filepaths = nil
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)

    @args_hash['output_csv_path'] = File.absolute_path(File.join(@tmp_output_path, 'occupancy-stochastic_2.csv'))
    @args_hash['building_id'] = 'MyBuilding_2'
    hpxml, result = _test_measure()

    info_msgs = result.info.map { |x| x.logMessage }
    assert(info_msgs.any? { |info_msg| info_msg.include?('stochastic schedule') })
    assert(info_msgs.any? { |info_msg| info_msg.include?("SimYear=#{@year}") })
    assert(info_msgs.any? { |info_msg| info_msg.include?('MinutesPerStep=60') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('State=CO') })
    assert(!info_msgs.any? { |info_msg| info_msg.include?('RandomSeed') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('GeometryNumOccupants=3.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('TimeZoneUTCOffset=-7.0') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Latitude=39.83') })
    assert(info_msgs.any? { |info_msg| info_msg.include?('Longitude=-104.65') })

    hpxml.buildings.each do |hpxml_bldg|
      building_id = hpxml_bldg.building_id

      if building_id == @args_hash['building_id']
        sf = SchedulesFile.new(schedules_paths: hpxml_bldg.header.schedules_filepaths,
                               year: @year,
                               output_path: @tmp_schedule_file_path)

        assert_equal(1, hpxml_bldg.header.schedules_filepaths.size)
        assert(hpxml_bldg.header.schedules_filepaths[0].include? 'occupancy-stochastic_2.csv')
        expected_values = {
          Occupants: 6072,
          LightingInterior: 1765,
          CookingRange: 336.4,
          Dishwasher: 297.4,
          ClothesWasher: 116.3,
          PlugLoadsOther: 5336.8,
          PlugLoadsTV: 1205,
          HotWaterDishwasher: 229.8,
          HotWaterClothesWasher: 246.5,
          HotWaterFixtures: 956.4,
        }
        assert_full_load_hrs_match(sf, expected_values, @tol)
        assert(!sf.schedules.keys.include?(SchedulesFile::Columns[:Sleeping].name))
      else
        assert_empty(hpxml_bldg.header.schedules_filepaths)
      end
    end
  end

  def test_append_output
    existing_csv_path = File.join(File.dirname(__FILE__), '..', '..', 'HPXMLtoOpenStudio', 'resources', 'schedule_files', 'setpoints.csv')
    orig_cols = File.readlines(existing_csv_path)[0].strip.split(',')

    # Test w/ append_output=false
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    FileUtils.cp(existing_csv_path, @tmp_schedule_file_path)
    @args_hash['output_csv_path'] = @tmp_schedule_file_path
    @args_hash['append_output'] = false
    _test_measure()
    assert(File.exist?(@tmp_schedule_file_path))
    outdata = File.readlines(@tmp_schedule_file_path)
    expected_cols = ScheduleGenerator.export_columns
    assert((outdata[0].strip.split(',').to_set - expected_cols.to_set).empty?)

    # Test w/ append_output=true
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    FileUtils.cp(existing_csv_path, @tmp_schedule_file_path)
    @args_hash['output_csv_path'] = @tmp_schedule_file_path
    @args_hash['append_output'] = true
    _test_measure()

    assert(File.exist?(@tmp_schedule_file_path))
    outdata = File.readlines(@tmp_schedule_file_path)
    expected_cols = ScheduleGenerator.export_columns
    assert_equal(orig_cols.to_set, (outdata[0].strip.split(',').to_set - expected_cols.to_set)) # Header

    # Test w/ append_output=true and inconsistent data
    existing_csv_path = File.join(File.dirname(__FILE__), '..', '..', 'HPXMLtoOpenStudio', 'resources', 'schedule_files', 'setpoints-10-mins.csv')
    hpxml = _create_hpxml('base.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    FileUtils.cp(existing_csv_path, @tmp_schedule_file_path)
    @args_hash['output_csv_path'] = @tmp_schedule_file_path
    @args_hash['append_output'] = true
    _hpxml, result = _test_measure(expect_fail: true)

    error_msgs = result.errors.map { |x| x.logMessage }
    assert(error_msgs.any? { |error_msg| error_msg.include?('Invalid number of rows (52561) in file.csv. Expected 8761 rows (including the header row).') })
  end

  private

  def _test_measure(expect_fail: false)
    # create an instance of the measure
    measure = BuildResidentialScheduleFile.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if @args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(@args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # assert that it ran correctly
    if expect_fail
      show_output(result) unless result.value.valueName == 'Fail'
      assert_equal('Fail', result.value.valueName)
    else
      show_output(result) unless result.value.valueName == 'Success'
      assert_equal('Success', result.value.valueName)
    end

    hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)

    return hpxml, result
  end

  def _create_hpxml(hpxml_name)
    return HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
  end

  def assert_full_load_hrs_match(sf, expected_values, tol)
    mismatches = []
    suggested_values = {}
    missing_cols = []
    schedule_col_names = []
    cols_to_ignore = Set.new(['Vacancy', 'Power Outage', 'No Space Heating', 'No Space Cooling'])
    expected_values.each do |col_name, expected_value|
      unless SchedulesFile::Columns.key?(col_name.to_sym)
        puts "Error: Column '#{col_name}' not found in SchedulesFile::Columns"
        assert(false)
      end
      schedule_col_name = SchedulesFile::Columns[col_name.to_sym].name
      schedule_col_names << schedule_col_name
      if !sf.tmp_schedules.key?(schedule_col_name)
        missing_cols << col_name
        next
      end
      actual_value = sf.annual_equivalent_full_load_hrs(col_name: schedule_col_name, schedules: sf.tmp_schedules)

      delta = tol * [actual_value.abs, expected_value.abs].min
      diff = (actual_value - expected_value).abs
      if diff > delta
        mismatches << { col_name: col_name, expected_value: expected_value, actual_value: actual_value,
                        message: "Expected |#{expected_value} - #{actual_value}| (#{diff}) to be <= #{delta}" }
        suggested_values[col_name] = "#{format('%.1f', actual_value)}"
      else
        suggested_values[col_name] = "#{expected_value}"
      end
    end
    extra_cols = sf.tmp_schedules.keys.to_set - schedule_col_names.to_set - cols_to_ignore.to_set

    unless (mismatches.empty? && missing_cols.empty? && extra_cols.empty?)
      if !mismatches.empty?
        puts "\nMismatches found:"
        mismatches.each do |mismatch|
          puts "#{mismatch[:col_name]}: #{mismatch[:message]}"
        end
      end

      if !missing_cols.empty?
        puts "\nMissing columns:"
        missing_cols.each do |col_name|
          puts "    :#{col_name}"
        end
      end

      if !extra_cols.empty?
        puts "\nUnexpected columns found in the schedule file"
        extra_cols.each do |col_name|
          puts "    :#{col_name}"
        end
      end

      puts "\nTo fix this, you can update the expected values to match the actual values and columns:"
      puts '    expected_values = {'
      expected_values.keys.each do |col_name|
        if missing_cols.include?(col_name)
          next
        end

        puts "      #{col_name}: #{suggested_values[col_name]},"
      end
      puts '    }'
      assert(false)
    end
  end
end
