# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require 'msgpack'
require_relative 'resources/constants'

# start the measure
class QOIReport < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    return 'QOI Report'
  end

  # human readable description
  def description
    return 'Reports uncertainty quantification quantities of interest.'
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    return OpenStudio::IdfObjectVector.new if runner.halted

    results = OpenStudio::IdfObjectVector.new
    results << OpenStudio::IdfObject.load('Output:Variable,*,Site Outdoor Air Drybulb Temperature,hourly;').get
    results << OpenStudio::IdfObject.load('Output:Meter,Electricity:Facility,hourly;').get

    return results
  end

  def seasons
    return {
      Constants::SeasonHeating => [-1e9, 55],
      Constants::SeasonCooling => [70, 1e9],
      Constants::SeasonOverlap => [55, 70]
    }
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find OpenStudio model.')
      return false
    end
    model = model.get

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    hpxml_defaults_path = model.getBuilding.additionalProperties.getFeatureAsString('hpxml_defaults_path').get
    output_dir = File.dirname(hpxml_defaults_path)

    # Initialize timeseries hash
    timeseries = { 'Temperature' => [],
                   'total_site_electricity_kw' => [] }

    if not File.exist? File.join(output_dir, 'eplusout.msgpack')
      runner.registerError('Cannot find eplusout.msgpack.')
      return false
    end

    # Outdoor temperatures
    msgpackData = MessagePack.unpack(File.read(File.join(output_dir, 'eplusout_hourly.msgpack'), mode: 'rb'))
    hourly_cols = msgpackData['Cols']
    hourly_rows = msgpackData['Rows']
    index = hourly_cols.each_index.select { |i| hourly_cols[i]['Variable'] == 'Environment:Site Outdoor Air Drybulb Temperature' }[0]
    hourly_rows.each do |row|
      timeseries['Temperature'] << UnitConversions.convert(row[row.keys[0]][index], 'C', 'F')
    end

    # Total electricity usages
    msgpackData = MessagePack.unpack(File.read(File.join(output_dir, 'eplusout.msgpack'), mode: 'rb'))
    meter_cols = msgpackData['MeterData']['Hourly']['Cols']
    meter_rows = msgpackData['MeterData']['Hourly']['Rows']
    index = meter_cols.each_index.select { |i| meter_cols[i]['Variable'] == 'Electricity:Facility' }[0]
    meter_rows.each do |row|
      timeseries['total_site_electricity_kw'] << row[row.keys[0]][index] / (1000.0 * 3600.0)
    end

    # Peak magnitude (1)
    report_sim_output(runner, 'qoi_hourly_peak_magnitude_use_kw', use(timeseries, [-1e9, 1e9], 'max'), '', '')

    # Timing of peak magnitude (1)
    report_sim_output(runner, 'qoi_hourly_peak_magnitude_timing_hour', timing(timeseries, [-1e9, 1e9], 'max'), '', '')

    # Average daily base magnitude (by season) (3)
    seasons.each do |season, temperature_range|
      report_sim_output(runner, "qoi_average_minimum_daily_use_#{season.downcase}_kw", average_daily_use(timeseries, temperature_range, 'min'), '', '')
    end

    # Average daily peak magnitude (by season) (3)
    seasons.each do |season, temperature_range|
      report_sim_output(runner, "qoi_average_maximum_daily_use_#{season.downcase}_kw", average_daily_use(timeseries, temperature_range, 'max'), '', '')
    end

    # Average daily peak timing (by season) (3)
    seasons.each do |season, temperature_range|
      report_sim_output(runner, "qoi_average_maximum_daily_timing_#{season.downcase}_hour", average_daily_timing(timeseries, temperature_range, 'max'), '', '')
    end

    # Top 10 daily seasonal peak magnitude (2)
    seasons.each do |season, temperature_range|
      next if season == Constants::SeasonOverlap

      report_sim_output(runner, "qoi_average_of_top_ten_highest_peaks_use_#{season.downcase}_kw", average_daily_use(timeseries, temperature_range, 'max', 10), '', '')
    end

    # Top 10 seasonal timing of peak (2)
    seasons.each do |season, temperature_range|
      next if season == Constants::SeasonOverlap

      report_sim_output(runner, "qoi_average_of_top_ten_highest_peaks_timing_#{season.downcase}_hour", average_daily_timing(timeseries, temperature_range, 'max', 10), '', '')
    end

    return true
  end

  def use(timeseries, temperature_range, min_or_max)
    ''"
    Determines the annual base or peak use value.
    Parameters:
      timeseries (hash): { 'Temperature' => [...], 'total_site_electricity_kw' => [...] }
      temperature_range (array): [lower, upper]
      min_or_max (str): 'min' or 'max'
    Returns:
      base_or_peak: float
    "''
    vals = []
    timeseries['total_site_electricity_kw'].each_with_index do |kw, i|
      temp = timeseries['Temperature'][i]
      if (temp > temperature_range[0]) && (temp < temperature_range[1])
        vals << kw
      end
    end
    if min_or_max == 'min'
      return vals.min
    elsif min_or_max == 'max'
      return vals.max
    end
  end

  def timing(timeseries, temperature_range, min_or_max)
    ''"
    Determines the hour of annual base or peak use value.
    Parameters:
      timeseries (hash): { 'Temperature' => [...], 'total_site_electricity_kw' => [...] }
      temperature_range (array): [lower, upper]
      min_or_max (str): 'min' or 'max'
    Returns:
      base_or_peak: float
    "''
    vals = []
    timeseries['total_site_electricity_kw'].each_with_index do |kw, i|
      temp = timeseries['Temperature'][i]
      if (temp > temperature_range[0]) && (temp < temperature_range[1])
        vals << kw
      end
    end
    if min_or_max == 'min'
      return vals.index(vals.min)
    elsif min_or_max == 'max'
      return vals.index(vals.max)
    end
  end

  def average_daily_use(timeseries, temperature_range, min_or_max, top = 'all')
    ''"
    Calculates the average of daily base or peak use values during heating, cooling, or overlap seasons.
    Parameters:
      timeseries (hash): { 'Temperature' => [...], 'total_site_electricity_kw' => [...] }
      temperature_range (array): [lower, upper]
      min_or_max (str): 'min' or 'max'
      top: integer or 'all'
    Returns:
      average_daily_use: float or nil
    "''
    daily_vals = []
    timeseries['total_site_electricity_kw'].each_slice(24).with_index do |kws, i|
      temps = timeseries['Temperature'][(24 * i)...(24 * i + 24)]
      avg_temp = temps.inject { |sum, el| sum + el }.to_f / temps.size
      if (avg_temp > temperature_range[0]) && (avg_temp < temperature_range[1]) # day is in this season
        if min_or_max == 'min'
          daily_vals << kws.min
        elsif min_or_max == 'max'
          daily_vals << kws.max
        end
      end
    end
    if daily_vals.empty?
      return
    end

    if top == 'all'
      top = daily_vals.length
    else
      top = [top, daily_vals.length].min # don't try to access indexes that don't exist
    end
    daily_vals = daily_vals.sort.reverse
    daily_vals = daily_vals[0..top]
    return daily_vals.inject { |sum, el| sum + el }.to_f / daily_vals.size
  end

  def average_daily_timing(timeseries, temperature_range, min_or_max, top = 'all')
    ''"
    Calculates the average hour of daily base or peak use values during heating, cooling, or overlap seasons.
    Parameters:
      timeseries (hash): { 'Temperature' => [...], 'total_site_electricity_kw' => [...] }
      temperature_range (array): [lower, upper]
      min_or_max (str): 'min' or 'max'
      top: integer or 'all'
    Returns:
      average_daily_use: float or nil
    "''
    daily_vals = { 'hour' => [], 'use' => [] }
    timeseries['total_site_electricity_kw'].each_slice(24).with_index do |kws, i|
      temps = timeseries['Temperature'][(24 * i)...(24 * i + 24)]
      avg_temp = temps.inject { |sum, el| sum + el }.to_f / temps.size
      if (avg_temp > temperature_range[0]) && (avg_temp < temperature_range[1]) # day is in this season
        if min_or_max == 'min'
          hour = kws.index(kws.min)
          daily_vals['hour'] << hour
          daily_vals['use'] << kws.min
        elsif min_or_max == 'max'
          hour = kws.index(kws.max)
          daily_vals['hour'] << hour
          daily_vals['use'] << kws.max
        end
      end
    end
    if daily_vals.empty?
      return
    end

    if top == 'all'
      top = daily_vals['hour'].length
    else
      top = [top, daily_vals['hour'].length].min # don't try to access indexes that don't exist
    end

    if top.zero?
      return
    end

    daily_vals['use'], daily_vals['hour'] = daily_vals['use'].zip(daily_vals['hour']).sort.reverse.transpose
    daily_vals = daily_vals['hour'][0..top]
    return daily_vals.inject { |sum, el| sum + el }.to_f / daily_vals.size
  end

  def report_sim_output(runner, name, total_val, os_units, desired_units, percent_of_val = 1.0)
    if total_val.nil?
      runner.registerInfo("Registering (blank) for #{name}.")
      return
    end
    total_val *= percent_of_val
    if os_units.nil? || desired_units.nil? || (os_units == desired_units)
      valInUnits = total_val
    else
      valInUnits = UnitConversions.convert(total_val, os_units, desired_units)
    end
    valInUnits = valInUnits.round(2)
    runner.registerValue(name, valInUnits)
    runner.registerInfo("Registering #{valInUnits} for #{name}.")
  end
end

# register the measure to be used by the application
QOIReport.new.registerWithApplication
