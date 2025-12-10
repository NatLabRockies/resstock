# frozen_string_literal: true

require 'openstudio'
require 'fileutils'
require 'time'
Dir["#{File.dirname(__FILE__)}/../resources/*.rb"].each do |resource_file|
  require resource_file
end
require_relative 'util.rb'

class HPXMLtoOpenStudioWeatherTest < Minitest::Test
  def teardown
    cleanup_output_files()
  end

  def weather_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'weather')
  end

  def test_denver
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherFile.new(epw_path: File.join(weather_dir, 'USA_CO_Denver.Intl.AP.725650_TMY3.epw'), runner: runner)

    # Check data
    assert_in_delta(51.6, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(51.6, weather.data.ShallowGroundAnnualTemp, 0.1)
    assert_in_delta(56.3, weather.data.DeepGroundAnnualTemp, 0.1)
    assert_in_delta(57.6, weather.data.MainsAnnualTemp, 0.1)
    assert_in_delta(3072.3, weather.data.CDD50F, 0.1)
    assert_in_delta(883.6, weather.data.CDD65F, 0.1)
    assert_in_delta(2497.2, weather.data.HDD50F, 0.1)
    assert_in_delta(5783.5, weather.data.HDD65F, 0.1)
    assert_equal(0.59, weather.data.WSF)
    [33.4, 31.9, 43.0, 42.5, 59.9, 73.6, 72.1, 72.7, 66.5, 50.1, 37.2, 34.6].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDrybulbs[i], 0.1)
    end
    [47.4, 46.6, 55.2, 53.7, 72.8, 88.7, 86.2, 85.9, 82.1, 63.2, 48.7, 48.9].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyHighDrybulbs[i], 0.1)
    end
    [19.3, 19.9, 30.3, 31.1, 47.4, 57.9, 59.1, 61.0, 52.4, 38.4, 27.0, 23.0].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyLowDrybulbs[i], 0.1)
    end
    [44.1, 40.9, 40.6, 42.2, 48.2, 54.3, 59.5, 62.8, 63.1, 60.4, 55.3, 49.4].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.ShallowGroundMonthlyTemps[i], 0.1)
    end
    [48.7, 47.7, 49.2, 52.9, 57.8, 62.7, 66.2, 67.5, 66.2, 62.7, 57.8, 52.9].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MainsMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(6.8, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(91.8, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(0.0061, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(27.4, weather.design.DailyTemperatureRange, 0.1)

    # Check ground temps
    assert_in_delta(22.5, weather.data.DeepGroundSurfTempAmp1, 0.1)
    assert_in_delta(-2.3, weather.data.DeepGroundSurfTempAmp2, 0.1)
    assert_equal(20, weather.data.DeepGroundPhaseShiftTempAmp1)
    assert_equal(31, weather.data.DeepGroundPhaseShiftTempAmp2)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(0, runner.result.stepWarnings.size)
  end

  def test_miami
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherFile.new(epw_path: File.join(weather_dir, 'USA_FL_Miami.Intl.AP.722020_TMY3.epw'), runner: runner)

    # Check data
    assert_in_delta(76.1, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(76.1, weather.data.ShallowGroundAnnualTemp, 0.1)
    assert_in_delta(77.2, weather.data.DeepGroundAnnualTemp, 0.1)
    assert_in_delta(82.1, weather.data.MainsAnnualTemp, 0.1)
    assert_in_delta(9531.0, weather.data.CDD50F, 0.1)
    assert_in_delta(4195.7, weather.data.CDD65F, 0.1)
    assert_in_delta(0.0, weather.data.HDD50F, 0.1)
    assert_in_delta(139.7, weather.data.HDD65F, 0.1)
    assert_equal(0.41, weather.data.WSF)
    [67.0, 69.6, 70.8, 75.4, 79.5, 81.8, 82.6, 82.4, 81.5, 79.4, 74.5, 68.5].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDrybulbs[i], 0.1)
    end
    [74.5, 77.7, 77.3, 81.7, 86.0, 87.0, 90.4, 88.5, 87.9, 85.9, 80.0, 75.4].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyHighDrybulbs[i], 0.1)
    end
    [59.8, 61.7, 64.2, 69.7, 74.2, 76.7, 76.3, 77.1, 75.8, 74.0, 67.9, 61.8].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyLowDrybulbs[i], 0.1)
    end
    [73.5, 72.3, 72.2, 72.8, 75.1, 77.3, 79.3, 80.6, 80.7, 79.6, 77.7, 75.5].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.ShallowGroundMonthlyTemps[i], 0.1)
    end
    [76.5, 77.1, 79.0, 81.7, 84.5, 86.7, 87.7, 87.3, 85.5, 82.8, 79.9, 77.6].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MainsMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(51.6, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(90.7, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(0.0173, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(12.1, weather.design.DailyTemperatureRange, 0.1)

    # Check ground temps
    assert_in_delta(7.7, weather.data.DeepGroundSurfTempAmp1, 0.1)
    assert_in_delta(1.3, weather.data.DeepGroundSurfTempAmp2, 0.1)
    assert_equal(30, weather.data.DeepGroundPhaseShiftTempAmp1)
    assert_equal(12, weather.data.DeepGroundPhaseShiftTempAmp2)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(0, runner.result.stepWarnings.size)
  end

  def test_honolulu
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherFile.new(epw_path: File.join(weather_dir, 'USA_HI_Honolulu.Intl.AP.911820_TMY3.epw'), runner: runner)

    # Check data
    assert_in_delta(76.8, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(76.8, weather.data.ShallowGroundAnnualTemp, 0.1)
    assert_in_delta(81.0, weather.data.DeepGroundAnnualTemp, 0.1)
    assert_in_delta(82.8, weather.data.MainsAnnualTemp, 0.1)
    assert_in_delta(9798.7, weather.data.CDD50F, 0.1)
    assert_in_delta(4323.7, weather.data.CDD65F, 0.1)
    assert_in_delta(0.0, weather.data.HDD50F, 0.1)
    assert_in_delta(0.0, weather.data.HDD65F, 0.1)
    assert_equal(0.42, weather.data.WSF)
    [72.5, 73.0, 73.7, 74.8, 77.4, 78.6, 80.4, 80.7, 80.4, 79.2, 76.6, 74.6].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDrybulbs[i], 0.1)
    end
    [80.0, 80.6, 81.7, 82.5, 85.4, 84.3, 87.8, 88.9, 87.0, 88.2, 83.6, 80.6].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyHighDrybulbs[i], 0.1)
    end
    [66.1, 65.9, 66.6, 68.8, 70.7, 73.7, 75.2, 74.5, 75.2, 71.9, 70.6, 69.1].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyLowDrybulbs[i], 0.1)
    end
    [75.6, 75.0, 74.9, 75.2, 76.4, 77.6, 78.7, 79.3, 79.4, 78.9, 77.8, 76.7].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.ShallowGroundMonthlyTemps[i], 0.1)
    end
    [79.8, 80.2, 81.2, 82.7, 84.2, 85.3, 85.8, 85.6, 84.6, 83.2, 81.6, 80.4].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MainsMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(63.3, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(89.1, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(0.0141, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(12.8, weather.design.DailyTemperatureRange, 0.1)

    # Check ground temps
    assert_in_delta(4.7, weather.data.DeepGroundSurfTempAmp1, 0.1)
    assert_in_delta(0.2, weather.data.DeepGroundSurfTempAmp2, 0.1)
    assert_equal(37, weather.data.DeepGroundPhaseShiftTempAmp1)
    assert_equal(-13, weather.data.DeepGroundPhaseShiftTempAmp2)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(0, runner.result.stepWarnings.size)
  end

  def test_cape_town
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherFile.new(epw_path: File.join(weather_dir, 'ZAF_Cape.Town.688160_IWEC.epw'), runner: runner)

    # Check data
    assert_in_delta(61.7, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(61.7, weather.data.ShallowGroundAnnualTemp, 0.1)
    assert_in_delta(65.8, weather.data.DeepGroundAnnualTemp, 0.1)
    assert_in_delta(67.7, weather.data.MainsAnnualTemp, 0.1)
    assert_in_delta(4297.8, weather.data.CDD50F, 0.1)
    assert_in_delta(503.0, weather.data.CDD65F, 0.1)
    assert_in_delta(17.5, weather.data.HDD50F, 0.1)
    assert_in_delta(1697.6, weather.data.HDD65F, 0.1)
    assert_equal(0.56, weather.data.WSF)
    [69.5, 69.5, 66.4, 61.7, 58.6, 55.1, 54.2, 55.2, 57.8, 60.7, 65.0, 67.6].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDrybulbs[i], 0.1)
    end
    [79.0, 78.5, 74.2, 70.0, 68.8, 64.6, 63.3, 64.2, 66.4, 70.6, 72.3, 76.0].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyHighDrybulbs[i], 0.1)
    end
    [61.0, 61.9, 59.7, 54.5, 50.8, 46.7, 45.3, 47.7, 50.1, 50.6, 57.9, 59.6].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyLowDrybulbs[i], 0.1)
    end
    [64.9, 66.1, 66.2, 65.2, 63.3, 61.1, 59.2, 58.0, 57.9, 58.5, 60.7, 62.9].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.ShallowGroundMonthlyTemps[i], 0.1)
    end
    [72.0, 72.1, 71.0, 69.1, 66.9, 64.8, 63.5, 63.4, 64.3, 66.1, 68.4, 70.5].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MainsMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(41.0, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(84.4, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(0.0095, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(17.1, weather.design.DailyTemperatureRange, 0.1)

    # Check ground temps
    assert_in_delta(-9.4, weather.data.DeepGroundSurfTempAmp1, 0.1)
    assert_in_delta(0.2, weather.data.DeepGroundSurfTempAmp2, 0.1)
    assert_equal(17, weather.data.DeepGroundPhaseShiftTempAmp1)
    assert_equal(15, weather.data.DeepGroundPhaseShiftTempAmp2)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(0, runner.result.stepWarnings.size)
  end

  def test_boulder_amy_with_leap_day
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherFile.new(epw_path: File.join(weather_dir, 'US_CO_Boulder_AMY_2012.epw'), runner: runner)

    # Check data
    assert_in_delta(49.4, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(49.4, weather.data.ShallowGroundAnnualTemp, 0.1)
    assert_in_delta(55.2, weather.data.DeepGroundAnnualTemp, 0.1)
    assert_in_delta(55.4, weather.data.MainsAnnualTemp, 0.1)
    assert_in_delta(2633.8, weather.data.CDD50F, 0.1)
    assert_in_delta(609.1, weather.data.CDD65F, 0.1)
    assert_in_delta(2863.0, weather.data.HDD50F, 0.1)
    assert_in_delta(6328.3, weather.data.HDD65F, 0.1)
    assert_equal(0.58, weather.data.WSF)
    [30.8, 26.4, 43.0, 49.4, 56.8, 71.1, 71.2, 70.4, 60.8, 45.3, 39.6, 27.0].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDrybulbs[i], 0.1)
    end
    [42.4, 37.8, 59.1, 66.2, 73.9, 89.2, 86.2, 87.5, 76.5, 61.2, 54.5, 38.2].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyHighDrybulbs[i], 0.1)
    end
    [22.1, 17.4, 30.4, 34.4, 40.8, 54.1, 57.5, 55.6, 48.1, 33.5, 30.0, 18.9].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyLowDrybulbs[i], 0.1)
    end
    [41.3, 37.9, 37.6, 39.2, 45.7, 52.2, 57.9, 61.4, 61.8, 58.8, 53.4, 47.1].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.ShallowGroundMonthlyTemps[i], 0.1)
    end
    [46.5, 45.2, 46.6, 50.2, 55.2, 60.3, 64.0, 65.5, 64.4, 60.9, 56.0, 50.9].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MainsMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(10.2, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(91.4, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(0.0046, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(28.7, weather.design.DailyTemperatureRange, 0.1)

    # Check ground temps
    assert_in_delta(22.1, weather.data.DeepGroundSurfTempAmp1, 0.1)
    assert_in_delta(2.0, weather.data.DeepGroundSurfTempAmp2, 0.1)
    assert_equal(19, weather.data.DeepGroundPhaseShiftTempAmp1)
    assert_equal(-34, weather.data.DeepGroundPhaseShiftTempAmp2)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(1, runner.result.stepWarnings.count { |w| w == 'No EPW design conditions found; calculating design conditions from EPW weather data.' })
  end

  def test_boulder_tmyx
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    weather = WeatherFile.new(epw_path: File.join(weather_dir, 'USA_CO_Boulder.Muni.AP.720533_TMYx.2009-2023.epw'), runner: runner)

    # Check data
    assert_in_delta(49.2, weather.data.AnnualAvgDrybulb, 0.1)
    assert_in_delta(49.2, weather.data.ShallowGroundAnnualTemp, 0.1)
    assert_in_delta(55.2, weather.data.DeepGroundAnnualTemp, 0.1)
    assert_in_delta(55.2, weather.data.MainsAnnualTemp, 0.1)
    assert_in_delta(2475.4, weather.data.CDD50F, 0.1)
    assert_in_delta(555.5, weather.data.CDD65F, 0.1)
    assert_in_delta(2765.0, weather.data.HDD50F, 0.1)
    assert_in_delta(6320.2, weather.data.HDD65F, 0.1)
    assert_equal(0.52, weather.data.WSF)
    [32.7, 29.8, 38.5, 45.3, 51.7, 66.6, 71.8, 71.1, 63.3, 50.0, 36.2, 31.9].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDrybulbs[i], 0.1)
    end
    [42.3, 38.8, 51.6, 59.6, 66.0, 81.9, 86.1, 87.3, 79.6, 65.9, 45.3, 41.8].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyHighDrybulbs[i], 0.1)
    end
    [24.1, 21.0, 28.6, 33.1, 39.0, 50.9, 56.4, 55.8, 48.1, 37.8, 28.8, 23.8].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MonthlyAvgDailyLowDrybulbs[i], 0.1)
    end
    [41.7, 38.4, 38.2, 39.7, 45.8, 51.9, 57.2, 60.5, 60.8, 58.1, 53.0, 47.1].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.ShallowGroundMonthlyTemps[i], 0.1)
    end
    [46.9, 45.7, 47.0, 50.4, 55.0, 59.7, 63.3, 64.7, 63.6, 60.4, 55.8, 51.0].each_with_index do |monthly_temp, i|
      assert_in_delta(monthly_temp, weather.data.MainsMonthlyTemps[i], 0.1)
    end

    # Check design
    assert_in_delta(9.7, weather.design.HeatingDrybulb, 0.1)
    assert_in_delta(90.9, weather.design.CoolingDrybulb, 0.1)
    assert_in_delta(0.0054, weather.design.CoolingHumidityRatio, 0.0001)
    assert_in_delta(25.7, weather.design.DailyTemperatureRange, 0.1)

    # Check ground temps
    assert_in_delta(22.1, weather.data.DeepGroundSurfTempAmp1, 0.1)
    assert_in_delta(2.0, weather.data.DeepGroundSurfTempAmp2, 0.1)
    assert_equal(19, weather.data.DeepGroundPhaseShiftTempAmp1)
    assert_equal(-34, weather.data.DeepGroundPhaseShiftTempAmp2)

    # Check runner
    assert_equal(0, runner.result.stepErrors.size)
    assert_equal(0, runner.result.stepWarnings.size)
  end
end
