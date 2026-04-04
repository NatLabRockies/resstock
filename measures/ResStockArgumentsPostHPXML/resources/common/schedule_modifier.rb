# frozen_string_literal: true

require 'date'
require 'csv'
require 'json'
require 'openstudio'

Dir["#{File.dirname(__FILE__)}/../../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end

FlexibilityInputs = Struct.new(:peak_offset, :pre_peak_duration_steps, :pre_peak_offset, :random_shift_steps, keyword_init: true)
DailyPeakIndices = Struct.new(:pre_peak_start_index, :peak_start_index, :peak_end_index)
DSTInfo = Struct.new(:dst_begin_month, :dst_begin_day, :dst_end_month, :dst_end_day)

# ScheduleModifier is a base class for modifying schedules based on flexibility inputs.
# It provides common functionality for calculating peak times, determining day types,
# and handling daylight saving time adjustments.
class ScheduleModifier
  # Initializes a new ScheduleModifier instance
  # @param state [String] The state code (e.g., 'CA', 'NY')
  # @param sim_year [Integer] The simulation year
  # @param weather [WeatherFile] The weather file object
  # @param epw_path [String] Path to the EPW weather file
  # @param minutes_per_step [Integer] Number of minutes per timestep
  # @param runner [OpenStudio::Measure::OSRunner] The measure runner for logging
  # @param dst_info [DSTInfo] Struct containing daylight saving time information
  def initialize(state:, sim_year:, weather:, epw_path:, minutes_per_step:, runner:, dst_info:)
    @state = state
    @minutes_per_step = minutes_per_step
    @runner = runner
    @weather = weather
    @epw_path = epw_path
    @daily_avg_temps = _get_daily_avg_temps
    @sim_year = Location.get_sim_calendar_year(sim_year, @weather)
    @total_days_in_year = Calendar.num_days_in_year(@sim_year)
    @sim_start_day = DateTime.new(@sim_year, 1, 1)
    @steps_in_day = 24 * 60 / @minutes_per_step
    @num_timesteps_per_hour = 60 / @minutes_per_step
    current_dir = File.dirname(__FILE__)
    @peak_hours_dict_shift = JSON.parse(File.read("#{current_dir}/seasonal_shifting_peak_hours.json"))
    @peak_hours_dict_shed = JSON.parse(File.read("#{current_dir}/seasonal_shedding_peak_hours.json"))
    @dst_info = dst_info
  end

  # Calculates peak times for a given index and flexibility inputs
  # @param index [Integer] The timestep index in the simulation
  # @param flexibility_inputs [FlexibilityInputs] Struct containing peak_offset, pre_peak_duration_steps, pre_peak_offset, and random_shift_steps
  # @return [DailyPeakIndices] Struct containing pre_peak_start_index, peak_start_index, and peak_end_index
  def _get_peak_times(index, flexibility_inputs)
    month, day = _get_month_day(index:)

    pre_peak_duration = flexibility_inputs.pre_peak_duration_steps
    peak_hour_start, peak_hour_end = _get_peak_hour(pre_peak_duration, month:)
    if @dst_info.values.all? { |v| !v.nil? }
      dst_adjust_hour = _dst_ajustment(month, day)
      peak_hour_start += dst_adjust_hour
      peak_hour_end += dst_adjust_hour
    end

    peak_times = DailyPeakIndices.new
    random_shift_steps = flexibility_inputs.random_shift_steps
    peak_times.peak_start_index = (peak_hour_start * @num_timesteps_per_hour) + random_shift_steps
    peak_times.peak_end_index = (peak_hour_end * @num_timesteps_per_hour) + random_shift_steps
    peak_times.pre_peak_start_index = peak_times.peak_start_index - flexibility_inputs.pre_peak_duration_steps
    peak_times
  end

  # Gets the month and day for a given timestep index
  # @param index [Integer] The timestep index in the simulation
  # @return [Array<Integer>] Array containing [month, day]
  def _get_month_day(index:)
    start_of_year = Date.new(@sim_year, 1, 1)
    index_date = start_of_year + (index.to_f / @num_timesteps_per_hour / 24)
    index_date.month
    index_date.day
    [index_date.month, index_date.day]
  end

  # Gets the peak hour start and end times based on month and pre-peak duration
  # @param pre_peak_duration [Integer] Duration of pre-peak period in timesteps
  # @param month [Integer] Month (1-12)
  # @return [Array<Integer>] Array containing [peak_hour_start, peak_hour_end]
  def _get_peak_hour(pre_peak_duration, month:)
    peak_hours = if pre_peak_duration == 0
                   @peak_hours_dict_shed[@state]
                 else
                   @peak_hours_dict_shift[@state]
                 end
    if [6, 7, 8, 9].include?(month)
      [peak_hours['summer_peak_start'][11..12].to_i, peak_hours['summer_peak_end'][11..12].to_i]
    elsif [1, 2, 3, 12].include?(month)
      [peak_hours['winter_peak_start'][11..12].to_i, peak_hours['winter_peak_end'][11..12].to_i]
    else
      [peak_hours['intermediate_peak_start'][11..12].to_i, peak_hours['intermediate_peak_end'][11..12].to_i]
    end
  end

  # Calculates the daylight saving time adjustment for a given month and day
  # @param month [Integer] Month (1-12)
  # @param day [Integer] Day of month
  # @return [Integer] DST adjustment (0 or 1)
  def _dst_ajustment(month, day)
    if month > @dst_info.dst_begin_month && month < @dst_info.dst_end_month
      1
    elsif month == @dst_info.dst_begin_month && day >= @dst_info.dst_begin_day # double check
      1
    elsif month == @dst_info.dst_end_month && day < @dst_info.dst_end_day # double check
      1
    else
      0
    end
  end

  # Determines the day type based on the average daily temperature
  # @param index [Integer] The timestep index in the simulation
  # @return [String] The day type: 'preheating' for cold days (<50°F),
  #                  'precooling' for hot days (>68°F), or
  #                  'prenothing' for moderate temperature days
  def _get_day_type(index)
    day = index / @steps_in_day
    if @daily_avg_temps[day] < 50.0
      'preheating'
    elsif @daily_avg_temps[day] > 68.0
      'precooling'
    else
      'prenothing' # Neither preheating nor precooling
    end
  end

  # Calculates daily average temperatures from the EPW weather file
  # @return [Array<Float>] Array of daily average temperatures in Fahrenheit
  def _get_daily_avg_temps
    epw_file = OpenStudio::EpwFile.new(@epw_path, true)
    daily_avg_temps = []
    hourly_temps = []
    epw_file.data.each_with_index do |epwdata, rownum|
      begin
        db_temp = epwdata.dryBulbTemperature.get
      rescue StandardError
        raise "Cannot retrieve dryBulbTemperature from the EPW for hour #{rownum + 1}."
      end
      hourly_temps << db_temp
      if (rownum + 1) % (24 * epw_file.recordsPerHour) == 0
        daily_avg_temps << (hourly_temps.sum / hourly_temps.length)
        hourly_temps = []
      end
    end
    daily_avg_temps.map { |temp| UnitConversions.convert(temp, 'C', 'F') }
  end

  # add abstract modify schedule method
  # rubocop:disable Lint/UnusedMethodArgument
  def modify_schedule(schedule, flexibility_inputs)
    raise 'Not implemented'
  end
end
