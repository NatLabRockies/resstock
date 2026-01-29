# frozen_string_literal: true

require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../measure.rb'

class QOIReportTest < Minitest::Test
  # create an instance of the measure
  @@measure = QOIReport.new

  def test_peak_magnitude_use
    temperature, total_site_electricity_kw = _setup_test
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.use(timeseries, [-1e9, 1e9], 'max')
    assert_in_epsilon(19, actual_val, 0.001)
  end

  def test_peak_magnitude_timing
    temperature, total_site_electricity_kw = _setup_test
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.timing(timeseries, [-1e9, 1e9], 'max')
    assert_in_epsilon(140, actual_val, 0.001)
  end

  def test_average_daily_use_base
    temperature, total_site_electricity_kw = _setup_test
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonHeating], 'min')
    assert_in_epsilon(5.0, actual_val, 0.001) # average of 0 and 10

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonCooling], 'min')
    assert_in_epsilon(9.0, actual_val, 0.001) # average of 8 and 10

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonOverlap], 'min')
    assert_in_epsilon(7.5, actual_val, 0.001) # average of 5 and 10
  end

  def test_average_daily_use_peak
    temperature, total_site_electricity_kw = _setup_test
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonHeating], 'max')
    assert_in_epsilon(11.0, actual_val, 0.001) # average of 10 and 12

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonCooling], 'max')
    assert_in_epsilon(13.0, actual_val, 0.001) # average of 10 and 16

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonOverlap], 'max')
    assert_in_epsilon(14.5, actual_val, 0.001) # average of 10 and 19
  end

  def test_average_daily_timing_base
    temperature, total_site_electricity_kw = _setup_test
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonHeating], 'min')
    assert_in_epsilon(0.0, actual_val, 0.001) # average of 0 and 0

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonCooling], 'min')
    assert_in_epsilon(1.5, actual_val, 0.001) # average of 3 and 0

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonOverlap], 'min')
    assert_in_epsilon(5.0, actual_val, 0.001) # average of 10 and 0
  end

  def test_average_daily_timing_peak
    temperature, total_site_electricity_kw = _setup_test
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonHeating], 'max')
    assert_in_epsilon(2.5, actual_val, 0.001) # average of 1 and 4

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonCooling], 'max')
    assert_in_epsilon(6.5, actual_val, 0.001) # average of 0 and 13

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonOverlap], 'max')
    assert_in_epsilon(10.0, actual_val, 0.001) # average of 0 and 20
  end

  def test_average_daily_use_base_no_heating_temperatures
    temperature, total_site_electricity_kw = _setup_test
    temperature[0..48] = _daily_cooling_temperatures * 2 # no heating temperatures
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonHeating], 'min')
    assert actual_val.nil?

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonCooling], 'min')
    assert_in_epsilon(7.0, actual_val, 0.001) # average of 0, 10, 8, and 10

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonOverlap], 'min')
    assert_in_epsilon(7.5, actual_val, 0.001) # average of 5 and 10
  end

  def test_average_daily_use_peak_no_heating_temperatures
    temperature, total_site_electricity_kw = _setup_test
    temperature[0..48] = _daily_cooling_temperatures * 2 # no heating temperatures
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonHeating], 'max')
    assert actual_val.nil?

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonCooling], 'max')
    assert_in_epsilon(12.0, actual_val, 0.001) # average of 10, 12, 10, 16

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonOverlap], 'max')
    assert_in_epsilon(14.5, actual_val, 0.001) # average of 10 and 19
  end

  def test_average_daily_use_base_no_cooling_temperatures
    temperature, total_site_electricity_kw = _setup_test
    temperature[47..96] = _daily_heating_temperatures * 2 # no cooling temperatures
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonHeating], 'min')
    assert_in_epsilon(7.0, actual_val, 0.001) # average of 0, 10, 8, and 10

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonCooling], 'min')
    assert actual_val.nil?

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonOverlap], 'min')
    assert_in_epsilon(7.5, actual_val, 0.001) # average of 5 and 10
  end

  def test_average_daily_use_peak_no_cooling_temperatures
    temperature, total_site_electricity_kw = _setup_test
    temperature[47..96] = _daily_heating_temperatures * 2 # no cooling temperatures
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonHeating], 'max')
    assert_in_epsilon(12.0, actual_val, 0.001) # average of 10, 12, 10, 16

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonCooling], 'max')
    assert actual_val.nil?

    actual_val = @@measure.average_daily_use(timeseries, @@measure.seasons[Constants::SeasonOverlap], 'max')
    assert_in_epsilon(14.5, actual_val, 0.001) # average of 10 and 19
  end

  def test_average_daily_timing_base_no_heating_temperatures
    temperature, total_site_electricity_kw = _setup_test
    temperature[0..48] = _daily_cooling_temperatures * 2 # no heating temperatures
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonHeating], 'min')
    assert actual_val.nil?

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonCooling], 'min')
    assert_in_epsilon(0.75, actual_val, 0.001) # average of 0, 0, 3, and 0

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonOverlap], 'min')
    assert_in_epsilon(5.0, actual_val, 0.001) # average of 10 and 0
  end

  def test_average_daily_timing_peak_no_heating_temperatures
    temperature, total_site_electricity_kw = _setup_test
    temperature[0..48] = _daily_cooling_temperatures * 2 # no heating temperatures
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonHeating], 'max')
    assert actual_val.nil?

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonCooling], 'max')
    assert_in_epsilon(4.5, actual_val, 0.001) # average of 1, 4, 0, 13

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonOverlap], 'max')
    assert_in_epsilon(10.0, actual_val, 0.001) # average of 0 and 20
  end

  def test_average_daily_timing_base_no_cooling_temperatures
    temperature, total_site_electricity_kw = _setup_test
    temperature[47..96] = _daily_heating_temperatures * 2 # no cooling temperatures
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonHeating], 'min')
    assert_in_epsilon(0.75, actual_val, 0.001) # average of 0, 0, 3, and 0

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonCooling], 'min')
    assert actual_val.nil?

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonOverlap], 'min')
    assert_in_epsilon(5.0, actual_val, 0.001) # average of 10 and 0
  end

  def test_average_daily_timing_peak_no_cooling_temperatures
    temperature, total_site_electricity_kw = _setup_test
    temperature[47..96] = _daily_heating_temperatures * 2 # no cooling temperatures
    timeseries = { 'Temperature' => temperature, 'total_site_electricity_kw' => total_site_electricity_kw }

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonHeating], 'max')
    assert_in_epsilon(4.5, actual_val, 0.001) # average of 1, 4, 0, 13

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonCooling], 'max')
    assert actual_val.nil?

    actual_val = @@measure.average_daily_timing(timeseries, @@measure.seasons[Constants::SeasonOverlap], 'max')
    assert_in_epsilon(10.0, actual_val, 0.001) # average of 0 and 20
  end

  def _setup_test
    temperature = []
    temperature += _daily_heating_temperatures * 2 # two days of random heating temperatures
    temperature += _daily_cooling_temperatures * 2 # two days of random cooling temperatures
    temperature += _daily_overlap_temperatures * 2 # two days of random overlap temperatures

    total_site_electricity_kw = [] # six days of total site electricity kw
    total_site_electricity_kw += [0, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
    total_site_electricity_kw += [10, 10, 10, 10, 12, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
    total_site_electricity_kw += [10, 10, 10, 8, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
    total_site_electricity_kw += [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 16, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
    total_site_electricity_kw += [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 5, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
    total_site_electricity_kw += [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 19, 10, 10, 10]

    return temperature, total_site_electricity_kw
  end

  def _daily_heating_temperatures
    lower = 0
    upper = @@measure.seasons[Constants::SeasonHeating][1].to_i
    return (lower..upper).to_a.sample(24) # random 24 hours of heating temperatures
  end

  def _daily_cooling_temperatures
    lower = @@measure.seasons[Constants::SeasonCooling][0].to_i
    upper = 100
    return (lower..upper).to_a.sample(24) # random 24 hours of cooling temperatures
  end

  def _daily_overlap_temperatures
    lower = @@measure.seasons[Constants::SeasonOverlap][0].to_i
    upper = @@measure.seasons[Constants::SeasonOverlap][1].to_i
    temperatures = (lower..upper).to_a * 2
    return temperatures.sample(24) # random 24 hours of overlap temperatures
  end
end
