# frozen_string_literal: true

# Annual constant schedule object.
class ScheduleConstant
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param sch_name [String] name that is assigned to the OpenStudio Schedule object
  # @param val [Double] the constant schedule value
  # @param schedule_type_limits_name [String] data type for the values contained in the schedule
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  def initialize(model, sch_name, val = 1.0, schedule_type_limits_name = nil, unavailable_periods: [])
    @schedule = create_schedule(model, sch_name, val, schedule_type_limits_name, unavailable_periods)
  end

  attr_accessor(:schedule)

  private

  # Create the constant OpenStudio Schedule object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param sch_name [String] name that is assigned to the OpenStudio Schedule object
  # @param val [Double] the constant schedule value
  # @param schedule_type_limits_name [String] data type for the values contained in the schedule
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [OpenStudio::Model::ScheduleConstant or OpenStudio::Model::ScheduleRuleset] the OpenStudio Schedule object with constant schedule
  def create_schedule(model, sch_name, val, schedule_type_limits_name, unavailable_periods)
    if unavailable_periods.empty?
      if val == 1.0 && (schedule_type_limits_name.nil? || schedule_type_limits_name == EPlus::ScheduleTypeLimitsOnOff)
        schedule = model.alwaysOnDiscreteSchedule
      elsif val == 0.0 && (schedule_type_limits_name.nil? || schedule_type_limits_name == EPlus::ScheduleTypeLimitsOnOff)
        schedule = model.alwaysOffDiscreteSchedule
      else
        schedule = Model.add_schedule_constant(
          model,
          name: sch_name,
          value: val,
          limits: schedule_type_limits_name
        )
      end
    else
      schedule = Model.add_schedule_ruleset(
        model,
        name: sch_name,
        limits: schedule_type_limits_name
      )

      default_day_sch = schedule.defaultDaySchedule
      default_day_sch.clearValues
      default_day_sch.addValue(OpenStudio::Time.new(0, 24, 0, 0), val)

      Schedule.set_unavailable_periods(model, schedule, sch_name, unavailable_periods)
    end

    return schedule
  end
end

# Annual schedule object defined by 12 24-hour values for weekdays and weekends.
class HourlyByMonthSchedule
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param sch_name [String] name that is assigned to the OpenStudio Schedule object
  # @param weekday_month_by_hour_values [Array<Array<Double>>] a 12-element array of 24-element arrays of numbers
  # @param weekday_month_by_hour_values [Array<Array<Double>>] a 12-element array of 24-element arrays of numbers
  # @param schedule_type_limits_name [String] data type for the values contained in the schedule
  # @param normalize_values [Boolean] whether to divide schedule values by the max value
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  def initialize(model, sch_name, weekday_month_by_hour_values, weekend_month_by_hour_values,
                 schedule_type_limits_name = nil, normalize_values = true, unavailable_periods: nil)
    @weekday_month_by_hour_values = validate_values(weekday_month_by_hour_values, 12, 24)
    @weekend_month_by_hour_values = validate_values(weekend_month_by_hour_values, 12, 24)
    if normalize_values
      @maxval = calc_max_val()
    else
      @maxval = 1.0
    end
    @schedule = create_schedule(model, sch_name, schedule_type_limits_name, unavailable_periods)
  end

  attr_accessor(:schedule, :maxval)

  private

  # Ensure that defined schedule value arrays are the correct lengths.
  #
  # @param vals [Array<Array<Double>>] a num_outer_values-element array of num_inner_values-element arrays of numbers
  # @param num_outer_values [Integer] expected number of values in the outer array
  # @param num_inner_values [Integer] expected number of values in the inner arrays
  # @return [Array<Array<Double>>] a num_outer_values-element array of num_inner_values-element arrays of numbers
  def validate_values(vals, num_outer_values, num_inner_values)
    err_msg = "A #{num_outer_values}-element array with #{num_inner_values}-element arrays of numbers must be entered for the schedule."
    if not vals.is_a?(Array)
      fail err_msg
    end

    begin
      if vals.length != num_outer_values
        fail err_msg
      end

      vals.each do |val|
        if not val.is_a?(Array)
          fail err_msg
        end
        if val.length != num_inner_values
          fail err_msg
        end
      end
    rescue
      fail err_msg
    end
    return vals
  end

  # Get the max weekday/weekend schedule value.
  #
  # @return [Double] the max hourly schedule value
  def calc_max_val()
    maxval = [@weekday_month_by_hour_values.flatten.max, @weekend_month_by_hour_values.flatten.max].max
    if maxval == 0.0
      maxval = 1.0 # Prevent divide by zero
    end
    return maxval
  end

  # Create the ruleset OpenStudio Schedule object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param sch_name [String] name that is assigned to the OpenStudio Schedule object
  # @param schedule_type_limits_name [String] data type for the values contained in the schedule
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [OpenStudio::Model::Ruleset] the OpenStudio Schedule object with rules
  def create_schedule(model, sch_name, schedule_type_limits_name, unavailable_periods)
    year = model.getYearDescription.assumedYear
    day_startm = Calendar.day_start_months(year)
    day_endm = Calendar.day_end_months(year)

    schedule = Model.add_schedule_ruleset(
      model,
      name: sch_name,
      limits: schedule_type_limits_name
    )

    prev_wkdy_vals, prev_wkdy_rule = nil, nil
    prev_wknd_vals, prev_wknd_rule = nil, nil
    for m in 1..12
      date_s = OpenStudio::Date::fromDayOfYear(day_startm[m - 1], year)
      date_e = OpenStudio::Date::fromDayOfYear(day_endm[m - 1], year)

      wkdy_vals, wknd_vals = [], []
      for h in 1..24
        wkdy_vals[h] = (@weekday_month_by_hour_values[m - 1][h - 1]) / @maxval
        wknd_vals[h] = (@weekend_month_by_hour_values[m - 1][h - 1]) / @maxval
      end

      if (wkdy_vals == prev_wkdy_vals) && (wknd_vals == prev_wknd_vals)
        # Extend end date of current rule(s)
        prev_wkdy_rule.setEndDate(date_e) unless prev_wkdy_rule.nil?
        prev_wknd_rule.setEndDate(date_e) unless prev_wknd_rule.nil?
      elsif wkdy_vals == wknd_vals
        alld_rule = Model.add_schedule_ruleset_rule(
          schedule,
          start_date: date_s,
          end_date: date_e,
          hourly_values: wkdy_vals
        )
        prev_wkdy_rule, prev_wknd_rule = alld_rule, nil
      else
        wkdy_rule = Model.add_schedule_ruleset_rule(
          schedule,
          start_date: date_s,
          end_date: date_e,
          apply_to_days: [0, 1, 1, 1, 1, 1, 0],
          hourly_values: wkdy_vals
        )
        wknd_rule = Model.add_schedule_ruleset_rule(
          schedule,
          start_date: date_s,
          end_date: date_e,
          apply_to_days: [1, 0, 0, 0, 0, 0, 1],
          hourly_values: wknd_vals
        )
        prev_wkdy_rule, prev_wknd_rule = wkdy_rule, wknd_rule
      end

      prev_wkdy_vals, prev_wknd_vals = wkdy_vals, wknd_vals
    end

    Schedule.set_unavailable_periods(model, schedule, sch_name, unavailable_periods)

    return schedule
  end
end

# Annual schedule object defined by 365 24-hour values for weekdays and weekends.
class HourlyByDaySchedule
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param sch_name [String] name that is assigned to the OpenStudio Schedule object
  # @param weekday_day_by_hour_values [Array<Array<Double>>] a 365-element array of 24-element arrays of numbers
  # @param weekend_day_by_hour_values [Array<Array<Double>>] a 365-element array of 24-element arrays of numbers
  # @param normalize_values [Boolean] whether to divide schedule values by the max value
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  def initialize(model, sch_name, weekday_day_by_hour_values, weekend_day_by_hour_values,
                 schedule_type_limits_name = nil, normalize_values = true, unavailable_periods: nil)
    num_days = Calendar.num_days_in_year(model.getYearDescription.assumedYear)
    @weekday_day_by_hour_values = validate_values(weekday_day_by_hour_values, num_days, 24)
    @weekend_day_by_hour_values = validate_values(weekend_day_by_hour_values, num_days, 24)
    if normalize_values
      @maxval = calc_max_val()
    else
      @maxval = 1.0
    end
    @schedule = create_schedule(model, sch_name, num_days, schedule_type_limits_name, unavailable_periods)
  end

  attr_accessor(:schedule, :maxval)

  private

  # Ensure that defined schedule value arrays are the correct lengths.
  #
  # @param vals [Array<Array<Double>>] a num_outer_values-element array of num_inner_values-element arrays of numbers
  # @param num_outer_values [Integer] expected number of values in the outer array
  # @param num_inner_values [Integer] expected number of values in the inner arrays
  # @return [Array<Array<Double>>] a num_outer_values-element array of num_inner_values-element arrays of numbers
  def validate_values(vals, num_outer_values, num_inner_values)
    err_msg = "A #{num_outer_values}-element array with #{num_inner_values}-element arrays of numbers must be entered for the schedule."
    if not vals.is_a?(Array)
      fail err_msg
    end

    begin
      if vals.length != num_outer_values
        fail err_msg
      end

      vals.each do |val|
        if not val.is_a?(Array)
          fail err_msg
        end
        if val.length != num_inner_values
          fail err_msg
        end
      end
    rescue
      fail err_msg
    end
    return vals
  end

  # Get the max weekday/weekend schedule value.
  #
  # @return [Double] the max hourly schedule value
  def calc_max_val()
    maxval = [@weekday_day_by_hour_values.flatten.max, @weekend_day_by_hour_values.flatten.max].max
    if maxval == 0.0
      maxval = 1.0 # Prevent divide by zero
    end
    return maxval
  end

  # Create the ruleset OpenStudio Schedule object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param sch_name [String] name that is assigned to the OpenStudio Schedule object
  # @param num_days [Integer] the number of days in the calendar year
  # @param schedule_type_limits_name [String] data type for the values contained in the schedule
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [OpenStudio::Model::Ruleset] the OpenStudio Schedule object with rules
  def create_schedule(model, sch_name, num_days, schedule_type_limits_name, unavailable_periods)
    schedule = Model.add_schedule_ruleset(
      model,
      name: sch_name,
      limits: schedule_type_limits_name
    )

    year = model.getYearDescription.assumedYear

    prev_wkdy_vals, prev_wkdy_rule = nil, nil
    prev_wknd_vals, prev_wknd_rule = nil, nil
    for d in 1..num_days
      date_s = OpenStudio::Date::fromDayOfYear(d, year)
      date_e = OpenStudio::Date::fromDayOfYear(d, year)

      wkdy_vals, wknd_vals = [], []
      for h in 1..24
        wkdy_vals[h] = (@weekday_day_by_hour_values[d - 1][h - 1]) / @maxval
        wknd_vals[h] = (@weekend_day_by_hour_values[d - 1][h - 1]) / @maxval
      end

      if (wkdy_vals == prev_wkdy_vals) && (wknd_vals == prev_wknd_vals)
        # Extend end date of current rule(s)
        prev_wkdy_rule.setEndDate(date_e) unless prev_wkdy_rule.nil?
        prev_wknd_rule.setEndDate(date_e) unless prev_wknd_rule.nil?
      elsif wkdy_vals == wknd_vals
        alld_rule = Model.add_schedule_ruleset_rule(
          schedule,
          start_date: date_s,
          end_date: date_e,
          hourly_values: wkdy_vals
        )
        prev_wkdy_rule, prev_wknd_rule = alld_rule, nil
      else
        wkdy_rule = Model.add_schedule_ruleset_rule(
          schedule,
          start_date: date_s,
          end_date: date_e,
          apply_to_days: [0, 1, 1, 1, 1, 1, 0],
          hourly_values: wkdy_vals
        )
        wknd_rule = Model.add_schedule_ruleset_rule(
          schedule,
          start_date: date_s,
          end_date: date_e,
          apply_to_days: [1, 0, 0, 0, 0, 0, 1],
          hourly_values: wknd_vals
        )
        prev_wkdy_rule, prev_wknd_rule = wkdy_rule, wknd_rule
      end

      prev_wkdy_vals, prev_wknd_vals = wkdy_vals, wknd_vals
    end

    Schedule.set_unavailable_periods(model, schedule, sch_name, unavailable_periods)

    return schedule
  end
end

# Annual schedule object defined by 24 weekday hourly values, 24 weekend hourly values, and 12 monthly values.
class MonthWeekdayWeekendSchedule
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param sch_name [String] name that is assigned to the OpenStudio Schedule object
  # @param weekday_hourly_values [String or Array<Double>] a comma-separated string of 24 numbers or a 24-element array of numbers
  # @param weekend_hourly_values [String or Array<Double>] a comma-separated string of 24 numbers or a 24-element array of numbers
  # @param monthly_values [String or Array<Double>] a comma-separated string of 12 numbers or a 12-element array of numbers
  # @param schedule_type_limits_name [String] data type for the values contained in the schedule
  # @param normalize_values [Boolean] whether to divide schedule values by the max value
  # @param begin_month [Integer] the begin month of the year
  # @param begin_day [Integer] the begin day of the begin month
  # @param end_month [Integer] the end month of the year
  # @param end_day [Integer] the end day of the end month
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  def initialize(model, sch_name, weekday_hourly_values, weekend_hourly_values, monthly_values,
                 schedule_type_limits_name = nil, normalize_values = true, begin_month = 1,
                 begin_day = 1, end_month = 12, end_day = 31, unavailable_periods: nil)
    @weekday_hourly_values = Schedule.validate_values(weekday_hourly_values, 24, 'weekday')
    @weekend_hourly_values = Schedule.validate_values(weekend_hourly_values, 24, 'weekend')
    @monthly_values = Schedule.validate_values(monthly_values, 12, 'monthly')
    if normalize_values
      @weekday_hourly_values = normalize_sum_to_one(@weekday_hourly_values)
      @weekend_hourly_values = normalize_sum_to_one(@weekend_hourly_values)
      @monthly_values = normalize_avg_to_one(@monthly_values)
      @maxval = calc_max_val()
      @schadjust = calc_sch_adjust()
    else
      @maxval = 1.0
      @schadjust = 1.0
    end
    @schedule = create_schedule(model, sch_name, begin_month, begin_day, end_month, end_day,
                                schedule_type_limits_name, unavailable_periods)
  end

  attr_accessor(:schedule)

  # Calculate the design level from daily kWh.
  #
  # @param daily_kwh [Double] daily energy use (kWh)
  # @return [Double] design level used to represent maximum input (W)
  def calc_design_level_from_daily_kwh(daily_kwh)
    design_level_kw = daily_kwh * @maxval * @schadjust
    return UnitConversions.convert(design_level_kw, 'kW', 'W')
  end

  # Calculate the design level from daily therm.
  #
  # @param daily_therm [Double] daily energy use (therm)
  # @return [Double] design level used to represent maximum input (W)
  def calc_design_level_from_daily_therm(daily_therm)
    return calc_design_level_from_daily_kwh(UnitConversions.convert(daily_therm, 'therm', 'kWh'))
  end

  # Calculate the water design level from daily use.
  #
  # @param daily_water [Double] daily water use (gal/day)
  # @return [Double] design level used to represent maximum input (m3/s)
  def calc_design_level_from_daily_gpm(daily_water)
    water_gpm = daily_water * @maxval * @schadjust / 60.0
    return UnitConversions.convert(water_gpm, 'gal/min', 'm^3/s')
  end

  private

  # Divide each value in the array by the sum of all values in the array.
  #
  # @param values [Array<Double>] an array of numbers
  # @return [Array<Double>] normalized values that sum to one
  def normalize_sum_to_one(values)
    sum = values.sum.to_f
    if sum == 0.0
      return values
    end

    return values.map { |val| val / sum }
  end

  # Divide each value in the array by the average all values in the array.
  #
  # @param values [Array<Double>] an array of numbers
  # @return [Array<Double>] normalized values that average to one
  def normalize_avg_to_one(values)
    avg = values.sum.to_f / values.size
    if avg == 0.0
      return values
    end

    return values.map { |val| val / avg }
  end

  # Get the max weekday/weekend schedule value.
  #
  # @return [Double] the max hourly schedule value
  def calc_max_val()
    if @weekday_hourly_values.max > @weekend_hourly_values.max
      maxval = @monthly_values.max * @weekday_hourly_values.max
    else
      maxval = @monthly_values.max * @weekend_hourly_values.max
    end
    if maxval == 0.0
      maxval = 1.0 # Prevent divide by zero
    end
    return maxval
  end

  # If sum != 1, normalize to get correct max val.
  #
  # @return [Double] the calculated schedule adjustment
  def calc_sch_adjust()
    sum_wkdy = 0
    sum_wknd = 0
    @weekday_hourly_values.each do |v|
      sum_wkdy += v
    end
    @weekend_hourly_values.each do |v|
      sum_wknd += v
    end
    if sum_wkdy < sum_wknd
      return 1 / sum_wknd
    end

    return 1 / sum_wkdy
  end

  # Create the constant OpenStudio Schedule object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param sch_name [String] name that is assigned to the OpenStudio Schedule object
  # @param begin_month [Integer] the begin month of the year
  # @param begin_day [Integer] the begin day of the begin month
  # @param end_month [Integer] the end month of the year
  # @param end_day [Integer] the end day of the end month
  # @param schedule_type_limits_name [String] data type for the values contained in the schedule
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [OpenStudio::Model::ScheduleRuleset] the OpenStudio Schedule object with rules
  def create_schedule(model, sch_name, begin_month, begin_day, end_month, end_day,
                      schedule_type_limits_name, unavailable_periods)
    year = model.getYearDescription.assumedYear
    month_num_days = Calendar.num_days_in_months(year)
    month_num_days[end_month - 1] = end_day

    day_startm = Calendar.day_start_months(year)
    day_startm[begin_month - 1] += begin_day - 1
    day_endm = [Calendar.day_start_months(year), month_num_days].transpose.map { |i| i.sum - 1 }

    schedule = Model.add_schedule_ruleset(
      model,
      name: sch_name,
      limits: schedule_type_limits_name
    )

    prev_wkdy_vals, prev_wkdy_rule = nil, nil
    prev_wknd_vals, prev_wknd_rule = nil, nil

    periods = []
    if begin_month <= end_month # contiguous period
      periods << [begin_month, end_month]
    else # non-contiguous period
      periods << [1, end_month]
      periods << [begin_month, 12]
    end

    periods.each do |period|
      for m in period[0]..period[1]
        date_s = OpenStudio::Date::fromDayOfYear(day_startm[m - 1], year)
        date_e = OpenStudio::Date::fromDayOfYear(day_endm[m - 1], year)

        wkdy_vals, wknd_vals = [], []
        for h in 1..24
          wkdy_vals[h] = (@monthly_values[m - 1] * @weekday_hourly_values[h - 1]) / @maxval
          wknd_vals[h] = (@monthly_values[m - 1] * @weekend_hourly_values[h - 1]) / @maxval
        end

        if (wkdy_vals == prev_wkdy_vals) && (wknd_vals == prev_wknd_vals)
          # Extend end date of current rule(s)
          prev_wkdy_rule.setEndDate(date_e) unless prev_wkdy_rule.nil?
          prev_wknd_rule.setEndDate(date_e) unless prev_wknd_rule.nil?
        elsif wkdy_vals == wknd_vals
          alld_rule = Model.add_schedule_ruleset_rule(
            schedule,
            start_date: date_s,
            end_date: date_e,
            hourly_values: wkdy_vals
          )
          prev_wkdy_rule, prev_wknd_rule = alld_rule, nil
        else
          wkdy_rule = Model.add_schedule_ruleset_rule(
            schedule,
            start_date: date_s,
            end_date: date_e,
            apply_to_days: [0, 1, 1, 1, 1, 1, 0],
            hourly_values: wkdy_vals
          )
          wknd_rule = Model.add_schedule_ruleset_rule(
            schedule,
            start_date: date_s,
            end_date: date_e,
            apply_to_days: [1, 0, 0, 0, 0, 0, 1],
            hourly_values: wknd_vals
          )
          prev_wkdy_rule, prev_wknd_rule = wkdy_rule, wknd_rule
        end

        prev_wkdy_vals, prev_wknd_vals = wkdy_vals, wknd_vals
      end
    end

    Schedule.set_unavailable_periods(model, schedule, sch_name, unavailable_periods)

    return schedule
  end
end

# Collection of helper methods related to schedules.
module Schedule
  # Get the total number of full load hours for this schedule.
  #
  # @param modelYear [Integer] the calendar year
  # @param schedule [OpenStudio::Model::ScheduleInterval or OpenStudio::Model::ScheduleConstant or OpenStudio::Model::ScheduleRuleset] the OpenStudio Schedule object
  # @return [Double] annual equivalent full load hours
  def self.annual_equivalent_full_load_hrs(modelYear, schedule)
    if schedule.to_ScheduleInterval.is_initialized
      timeSeries = schedule.to_ScheduleInterval.get.timeSeries
      annual_flh = timeSeries.averageValue * 8760
      return annual_flh
    end

    if schedule.to_ScheduleConstant.is_initialized
      annual_flh = schedule.to_ScheduleConstant.get.value * Calendar.num_hours_in_year(modelYear)
      return annual_flh
    end

    if not schedule.to_ScheduleRuleset.is_initialized
      return
    end

    schedule = schedule.to_ScheduleRuleset.get

    # Define the start and end date
    year_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('January'), 1, modelYear)
    year_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('December'), 31, modelYear)

    # Get the ordered list of all the day schedules
    # that are used by this schedule ruleset
    day_schs = schedule.getDaySchedules(year_start_date, year_end_date)

    # Get a 365-value array of which schedule is used on each day of the year,
    day_schs_used_each_day = schedule.getActiveRuleIndices(year_start_date, year_end_date)
    if !day_schs_used_each_day.length == 365
      fail "#{schedule.name} does not have 365 daily schedules accounted for, cannot accurately calculate annual EFLH."
    end

    # Create a map that shows how many days each schedule is used
    day_sch_freq = day_schs_used_each_day.group_by { |n| n }

    # Build a hash that maps schedule day index to schedule day
    schedule_index_to_day = {}
    for i in 0..(day_schs.length - 1)
      schedule_index_to_day[day_schs_used_each_day[i]] = day_schs[i]
    end

    # Loop through each of the schedules that is used, figure out the
    # full load hours for that day, then multiply this by the number
    # of days that day schedule applies and add this to the total.
    annual_flh = 0
    max_daily_flh = 0
    default_day_sch = schedule.defaultDaySchedule
    day_sch_freq.each do |freq|
      sch_index = freq[0]
      number_of_days_sch_used = freq[1].size

      # Get the day schedule at this index
      day_sch = nil
      if sch_index == -1 # If index = -1, this day uses the default day schedule (not a rule)
        day_sch = default_day_sch
      else
        day_sch = schedule_index_to_day[sch_index]
      end

      # Determine the full load hours for just one day
      daily_flh = 0
      values = day_sch.values
      times = day_sch.times

      previous_time_decimal = 0
      for i in 0..(times.length - 1)
        time_days = times[i].days
        time_hours = times[i].hours
        time_minutes = times[i].minutes
        time_seconds = times[i].seconds
        time_decimal = (time_days * 24.0) + time_hours + (time_minutes / 60.0) + (time_seconds / 3600.0)
        duration_of_value = time_decimal - previous_time_decimal
        daily_flh += values[i] * duration_of_value
        previous_time_decimal = time_decimal
      end

      # Multiply the daily EFLH by the number
      # of days this schedule is used per year
      # and add this to the overall total
      annual_flh += daily_flh * number_of_days_sch_used
    end

    # Check if the max daily EFLH is more than 24,
    # which would indicate that this isn't a
    # fractional schedule.
    if max_daily_flh > 24
      fail "#{schedule.name} has more than 24 EFLH in one day schedule, indicating that it is not a fractional schedule."
    end

    return annual_flh
  end

  # Downselect the unavailable periods to only those that apply to the given schedule.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param schedule_name [String] the column header of the detailed schedule
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [HPXML::UnavailablePeriods] the subset of unavailable period objects for which the ColumnName applies to the provided schedule name
  def self.get_unavailable_periods(runner, schedule_name, unavailable_periods)
    return unavailable_periods.select { |p| Schedule.unavailable_period_applies(runner, schedule_name, p.column_name) }
  end

  # Add unavailable period rules to the OpenStudio Schedule object.
  # An unavailable period rule is an OpenStudio ScheduleRule object.
  # Each OpenStudio ScheduleRule stores start month/day, end month/day, and day (24 hour) schedule.
  # The unavailable period (i.e., number of consecutive days, whether starting/ending in the middle of the day, etc.) determines
  # the number of ScheduleRule objects that are needed, as well as the start, end, and day schedule fields that are set.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param schedule [OpenStudio::Model::ScheduleRuleset] the OpenStudio Schedule object for which to set unavailable period rules
  # @param sch_name [String] name that is assigned to the OpenStudio Schedule object
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [nil]
  def self.set_unavailable_periods(model, schedule, sch_name, unavailable_periods)
    return if unavailable_periods.nil?

    year = model.getYearDescription.assumedYear

    # Add off rule(s), will override previous rules
    unavailable_periods.each do |period|
      # Special Values
      # FUTURE: Assign an object type to the schedules and use that to determine what
      # kind of schedule each is, rather than looking at object names. That would
      # be more robust. See https://github.com/NREL/OpenStudio-HPXML/issues/1450.
      if sch_name.include? Constants::ObjectTypeWaterHeaterSetpoint
        # Water heater setpoint
        # Temperature of tank < 2C indicates of possibility of freeze.
        value = 2.0
      elsif sch_name.include? Constants::ObjectTypeNaturalVentilation
        if period.natvent_availability == HPXML::ScheduleRegular
          next # don't change the natural ventilation availability schedule
        elsif period.natvent_availability == HPXML::ScheduleAvailable
          value = 1.0
        elsif period.natvent_availability == HPXML::ScheduleUnavailable
          value = 0.0
        end
      else
        value = 0.0
      end

      day_s = Calendar.get_day_num_from_month_day(year, period.begin_month, period.begin_day)
      day_e = Calendar.get_day_num_from_month_day(year, period.end_month, period.end_day)

      date_s = OpenStudio::Date::fromDayOfYear(day_s, year)
      date_e = OpenStudio::Date::fromDayOfYear(day_e, year)

      begin_day_schedule = schedule.getDaySchedules(date_s, date_s)[0]
      end_day_schedule = schedule.getDaySchedules(date_e, date_e)[0]

      # [[start_date, end_date, hourly_values], ...]
      schedule_ruleset_rules = []

      unavail_days = day_e - day_s
      if unavail_days == 0 # unavailable period is less than 1 calendar day (need 1 unavailable period rule)
        schedule_ruleset_rules << [date_s, date_e, (0..23).map { |h| (h < period.begin_hour) || (h >= period.end_hour) ? begin_day_schedule.getValue(OpenStudio::Time.new(0, h + 1, 0, 0)) : value }]
      else # unavailable period is at least 1 calendar day
        if period.begin_hour == 0 && period.end_hour == 24 # 1 unavailable period rule
          schedule_ruleset_rules << [date_s, date_e, [value] * 24]
        elsif (period.begin_hour == 0 && period.end_hour != 24) || (period.begin_hour != 0 && period.end_hour == 24) # 2 unavailable period rules
          if period.begin_hour == 0 && period.end_hour != 24
            schedule_ruleset_rules << [date_e, date_e, (0..23).map { |h| (h >= period.end_hour) ? end_day_schedule.getValue(OpenStudio::Time.new(0, h + 1, 0, 0)) : value }] # last day
            schedule_ruleset_rules << [date_s, OpenStudio::Date::fromDayOfYear(day_e - 1, year), [value] * 24] # all other days
          elsif period.begin_hour != 0 && period.end_hour == 24
            schedule_ruleset_rules << [date_s, date_s, (0..23).map { |h| (h < period.begin_hour) ? begin_day_schedule.getValue(OpenStudio::Time.new(0, h + 1, 0, 0)) : value }] # first day
            schedule_ruleset_rules << [OpenStudio::Date::fromDayOfYear(day_s + 1, year), date_e, [value] * 24]
          end
        else # 2 or 3 unavailable period rules
          if unavail_days == 1 # 2 unavailable period rules
            schedule_ruleset_rules << [date_s, date_s, (0..23).map { |h| (h < period.begin_hour) ? begin_day_schedule.getValue(OpenStudio::Time.new(0, h + 1, 0, 0)) : value }] # first day
            schedule_ruleset_rules << [date_e, date_e, (0..23).map { |h| (h >= period.end_hour) ? end_day_schedule.getValue(OpenStudio::Time.new(0, h + 1, 0, 0)) : value }] # last day
          else # 3 unavailable period rules
            schedule_ruleset_rules << [date_s, date_s, (0..23).map { |h| (h < period.begin_hour) ? begin_day_schedule.getValue(OpenStudio::Time.new(0, h + 1, 0, 0)) : value }] # first day
            schedule_ruleset_rules << [OpenStudio::Date::fromDayOfYear(day_s + 1, year), OpenStudio::Date::fromDayOfYear(day_e - 1, year), [value] * 24] # all other days
            schedule_ruleset_rules << [date_e, date_e, (0..23).map { |h| (h >= period.end_hour) ? end_day_schedule.getValue(OpenStudio::Time.new(0, h + 1, 0, 0)) : value }] # last day
          end
        end
      end

      schedule_ruleset_rules.each do |schedule_ruleset_rule|
        start_date, end_date, hourly_values = schedule_ruleset_rule
        Model.add_schedule_ruleset_rule(
          schedule,
          start_date: start_date,
          end_date: end_date,
          hourly_values: hourly_values
        )
      end
    end
  end

  # Create an OpenStudio Schedule object based on a 365-element (or 366 for a leap year) daily season array.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param sch_name [String] name that is assigned to the OpenStudio Schedule object
  # @param values [Array<Double>] array of daily sequential load fractions
  # @return [OpenStudio::Model::ScheduleRuleset] the OpenStudio Schedule object with rules
  def self.create_ruleset_from_daily_season(model, sch_name, values)
    schedule = Model.add_schedule_ruleset(
      model,
      name: sch_name,
      limits: EPlus::ScheduleTypeLimitsFraction
    )
    year = model.getYearDescription.assumedYear
    start_value = values[0]
    start_date = OpenStudio::Date::fromDayOfYear(1, year)
    values.each_with_index do |value, i|
      i += 1
      next unless value != start_value || i == values.length

      i += 1 if i == values.length

      Model.add_schedule_ruleset_rule(
        schedule,
        start_date: start_date,
        end_date: OpenStudio::Date::fromDayOfYear(i - 1, year),
        hourly_values: [start_value] * 24
      )

      break if i == values.length + 1

      start_date = OpenStudio::Date::fromDayOfYear(i, year)
      start_value = value
    end
    return schedule
  end

  # Return a array of maps that reflect the contents of the unavailable_periods.csv file.
  #
  # @return [Array<Hash>] array with maps for components that are affected by unavailable period types
  def self.get_unavailable_periods_csv_data
    unavailable_periods_csv = File.join(File.dirname(__FILE__), 'data', 'unavailable_periods.csv')
    if not File.exist?(unavailable_periods_csv)
      fail 'Could not find unavailable_periods.csv'
    end

    require 'csv'
    unavailable_periods_csv_data = CSV.open(unavailable_periods_csv, headers: true).map(&:to_h)

    return unavailable_periods_csv_data
  end

  # Get the unavailable period type column names from unvailable_periods.csv.
  #
  # @return [Array<String>] list of all defined unavailable period types in unavailable_periods.csv
  def self.unavailable_period_types
    if @unavailable_periods_csv_data.nil?
      @unavailable_periods_csv_data = Schedule.get_unavailable_periods_csv_data
    end
    column_names = @unavailable_periods_csv_data[0].keys[1..-1]
    return column_names
  end

  # Determine whether an unavailable period applies to a given detailed schedule.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param schedule_name [String] the column header of the detailed schedule
  # @param col_name [String] the unavailable period type
  # @return [Boolean] true if the unavailable period type applies to the detailed schedule
  def self.unavailable_period_applies(runner, schedule_name, col_name)
    if @unavailable_periods_csv_data.nil?
      @unavailable_periods_csv_data = get_unavailable_periods_csv_data
    end
    @unavailable_periods_csv_data.each do |csv_row|
      next if csv_row['Schedule Name'] != schedule_name

      if not csv_row.keys.include? col_name
        fail "Could not find column='#{col_name}' in unavailable_periods.csv."
      end

      begin
        applies = Integer(csv_row[col_name])
      rescue
        fail "Value is not a valid integer for row='#{schedule_name}' and column='#{col_name}' in unavailable_periods.csv."
      end
      if applies == 1
        if not runner.nil?
          if [SchedulesFile::Columns[:SpaceHeating].name, SchedulesFile::Columns[:SpaceCooling].name].include?(schedule_name)
            runner.registerWarning('It is not possible to eliminate all HVAC energy use (e.g. crankcase/defrost energy) in EnergyPlus during an unavailable period.')
          elsif schedule_name == SchedulesFile::Columns[:WaterHeater].name
            runner.registerWarning('It is not possible to eliminate all DHW energy use (e.g. water heater parasitics) in EnergyPlus during an unavailable period.')
          end
        end
        return true
      elsif applies == 0
        return false
      end
    end

    runner.registerWarning("Could not find row='#{schedule_name}' in unavailable_periods.csv; it will not be affected by the '#{col_name}' unavailable period.")
    return false
  end

  # Ensure that the defined schedule value array (or string of numbers) is the correct length.
  #
  # @param values [Array<Double> or Array<String> or String] a num_values-element array of numbers or a comma-separated string of numbers
  # @param num_values [Integer] expected number of values in the outer array
  # @param sch_name [String] name that is assigned to the OpenStudio Schedule object
  # @return [Array<Double>] a num_values-element array of numbers
  def self.validate_values(values, num_values, sch_name)
    err_msg = "A comma-separated string of #{num_values} numbers must be entered for the #{sch_name} schedule."

    # Check whether string is a valid float.
    #
    # @param str [String] string representation of a possible float
    # @return [Boolean] true if valid float
    def self.valid_float?(str)
      !!Float(str) rescue false
    end

    if values.is_a?(Array)
      if values.length != num_values
        fail err_msg
      end

      values.each do |val|
        if not valid_float?(val)
          fail err_msg
        end
      end
      floats = values.map { |i| i.to_f }
    elsif values.is_a?(String)
      begin
        vals = values.split(',')
        vals.each do |val|
          if not valid_float?(val)
            fail err_msg
          end
        end
        floats = vals.map { |i| i.to_f }
        if floats.length != num_values
          fail err_msg
        end
      rescue
        fail err_msg
      end
    else
      fail err_msg
    end
    return floats
  end

  # Check/update emissions file references.
  #
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param hpxml_path [String] Path to the HPXML file
  # @return [nil]
  def self.check_emissions_references(hpxml_header, hpxml_path)
    hpxml_header.emissions_scenarios.each do |scenario|
      if hpxml_header.emissions_scenarios.count { |s| s.emissions_type == scenario.emissions_type && s.name == scenario.name } > 1
        fail "Found multiple Emissions Scenarios with the Scenario Name=#{scenario.name} and Emissions Type=#{scenario.emissions_type}."
      end
      next if scenario.elec_schedule_filepath.nil?

      scenario.elec_schedule_filepath = FilePath.check_path(scenario.elec_schedule_filepath,
                                                            File.dirname(hpxml_path),
                                                            'Emissions File')
    end
  end

  # Check/update schedule file references.
  #
  # @param hpxml_bldg_header [HPXML::BuildingHeader] HPXML Building Header object
  # @param hpxml_path [String] Path to the HPXML file
  # @return [nil]
  def self.check_schedule_references(hpxml_bldg_header, hpxml_path)
    hpxml_bldg_header.schedules_filepaths = hpxml_bldg_header.schedules_filepaths.collect { |sfp|
      FilePath.check_path(sfp,
                          File.dirname(hpxml_path),
                          'Schedules')
    }
  end

  # Check that any electricity emissions schedule files contain the correct number of rows and columns.
  #
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.validate_emissions_files(hpxml_header)
    hpxml_header.emissions_scenarios.each do |scenario|
      next if scenario.elec_schedule_filepath.nil?

      data = File.readlines(scenario.elec_schedule_filepath)
      num_header_rows = scenario.elec_schedule_number_of_header_rows
      col_index = scenario.elec_schedule_column_number - 1

      if data.size != 8760 + num_header_rows
        fail "Emissions File has invalid number of rows (#{data.size}). Expected 8760 plus #{num_header_rows} header row(s)."
      end
      if col_index > data[num_header_rows, 8760].map { |x| x.count(',') }.min
        fail "Emissions File has too few columns. Cannot find column number (#{scenario.elec_schedule_column_number})."
      end
    end
  end

  # Splits a comma separated schedule string into charging (positive) and discharging (negative) schedules
  #
  # @param schedule_str [String] schedule with values separated by commas
  # @return [Array<String, String>] 24 hourly comma-separated charging and discharging schedules
  def self.split_signed_charging_schedule(schedule_str)
    charge_schedule, discharge_schedule = [], []
    schedule_str.split(',').map(&:strip).map(&:to_f).each do |frac|
      if frac >= 0
        charge_schedule << frac.to_s
        discharge_schedule << 0
      elsif frac < 0
        charge_schedule << 0
        discharge_schedule << (-frac).to_s
      end
    end
    return charge_schedule.join(', '), discharge_schedule.join(', ')
  end
end

# Object that contains information for detailed schedule CSVs.
class SchedulesFile
  # Struct for storing schedule CSV column information.
  class Column
    # @param name [String] the column header of the detailed schedule
    # @param used_by_unavailable_periods [Boolean] affected by unavailable periods
    # @param can_be_stochastic [Boolean] detailed stochastic occupancy schedule can be automatically generated
    # @param type [Symbol] units
    def initialize(name, used_by_unavailable_periods, can_be_stochastic, type)
      @name = name
      @used_by_unavailable_periods = used_by_unavailable_periods
      @can_be_stochastic = can_be_stochastic
      @type = type
    end
    attr_accessor(:name, :used_by_unavailable_periods, :can_be_stochastic, :type)
  end

  # Define all schedule columns
  # Columns may be used for A) detailed schedule CSVs (e.g., occupants), B) unavailable
  # periods CSV (e.g., heating), and/or C) EnergyPlus-specific schedules (e.g., battery_charging).
  Columns = {
    Occupants: Column.new('occupants', true, true, :frac),
    LightingInterior: Column.new('lighting_interior', true, true, :frac),
    LightingExterior: Column.new('lighting_exterior', true, false, :frac),
    LightingGarage: Column.new('lighting_garage', true, true, :frac),
    LightingExteriorHoliday: Column.new('lighting_exterior_holiday', true, false, :frac),
    CookingRange: Column.new('cooking_range', true, true, :frac),
    Refrigerator: Column.new('refrigerator', true, false, :frac),
    ExtraRefrigerator: Column.new('extra_refrigerator', true, false, :frac),
    Freezer: Column.new('freezer', true, false, :frac),
    Dishwasher: Column.new('dishwasher', true, true, :frac),
    ClothesWasher: Column.new('clothes_washer', true, true, :frac),
    ClothesDryer: Column.new('clothes_dryer', true, true, :frac),
    CeilingFan: Column.new('ceiling_fan', true, true, :frac),
    PlugLoadsOther: Column.new('plug_loads_other', true, true, :frac),
    PlugLoadsTV: Column.new('plug_loads_tv', true, true, :frac),
    PlugLoadsVehicle: Column.new('plug_loads_vehicle', true, false, :frac),
    PlugLoadsWellPump: Column.new('plug_loads_well_pump', true, false, :frac),
    FuelLoadsGrill: Column.new('fuel_loads_grill', true, false, :frac),
    FuelLoadsLighting: Column.new('fuel_loads_lighting', true, false, :frac),
    FuelLoadsFireplace: Column.new('fuel_loads_fireplace', true, false, :frac),
    PoolPump: Column.new('pool_pump', true, false, :frac),
    PoolHeater: Column.new('pool_heater', true, false, :frac),
    PermanentSpaPump: Column.new('permanent_spa_pump', true, false, :frac),
    PermanentSpaHeater: Column.new('permanent_spa_heater', true, false, :frac),
    HotWaterDishwasher: Column.new('hot_water_dishwasher', false, true, :frac),
    HotWaterClothesWasher: Column.new('hot_water_clothes_washer', false, true, :frac),
    HotWaterFixtures: Column.new('hot_water_fixtures', true, true, :frac),
    HotWaterRecirculationPump: Column.new('hot_water_recirculation_pump', true, false, :frac),
    GeneralWaterUse: Column.new('general_water_use', true, false, :frac),
    Sleeping: Column.new('sleeping', false, false, nil), # only used to debug stochastic schedule generation
    EVOccupant: Column.new('ev_occupant', false, false, nil), # only used to debug stochastic schedule generation
    HeatingSetpoint: Column.new('heating_setpoint', false, false, :setpoint),
    CoolingSetpoint: Column.new('cooling_setpoint', false, false, :setpoint),
    WaterHeaterSetpoint: Column.new('water_heater_setpoint', false, false, :setpoint),
    WaterHeaterOperatingMode: Column.new('water_heater_operating_mode', false, false, :zero_or_one),
    Battery: Column.new('battery', false, false, :neg_one_to_one),
    BatteryCharging: Column.new('battery_charging', true, false, nil),
    BatteryDischarging: Column.new('battery_discharging', true, false, nil),
    ElectricVehicle: Column.new('electric_vehicle', false, true, :neg_one_to_one),
    ElectricVehicleCharging: Column.new('electric_vehicle_charging', true, false, nil),
    ElectricVehicleDischarging: Column.new('electric_vehicle_discharging', true, false, nil),
    SpaceHeating: Column.new('space_heating', true, false, nil),
    SpaceCooling: Column.new('space_cooling', true, false, nil),
    HVACMaximumPowerRatio: Column.new('hvac_maximum_power_ratio', false, false, :frac),
    WaterHeater: Column.new('water_heater', true, false, nil),
    Dehumidifier: Column.new('dehumidifier', true, false, nil),
    KitchenFan: Column.new('kitchen_fan', true, false, nil),
    BathFan: Column.new('bath_fan', true, false, nil),
    HouseFan: Column.new('house_fan', true, false, nil),
    WholeHouseFan: Column.new('whole_house_fan', true, false, nil),
  }

  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param schedules_paths [Array<String>] array of file paths pointing to detailed schedule CSVs
  # @param year [Integer] the calendar year
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @param output_path [String] the file path for which to export a single detailed schedule CSV file and also reference from OpenStudio ScheduleFile objects
  def initialize(runner: nil,
                 schedules_paths:,
                 year:,
                 unavailable_periods: [],
                 output_path:,
                 offset_db: nil)
    return if schedules_paths.empty?

    @year = year
    import(runner, schedules_paths)
    create_battery_charging_discharging_schedules
    expand_schedules
    @tmp_schedules = Marshal.load(Marshal.dump(@schedules)) # make a deep copy because we use unmodified schedules downstream
    set_unavailable_periods(runner, unavailable_periods)
    convert_setpoints(offset_db)
    @output_schedules_path = output_path
    export()
  end

  attr_accessor(:schedules, :tmp_schedules)

  # Check if any detailed schedules are referenced.
  #
  # @return [Boolean] true if SchedulesFile was instantiated without any schedule file paths
  def nil?
    if @schedules.nil?
      return true
    end

    return false
  end

  # Check whether the detailed schedules include a specific column.
  #
  # @param col_name [String] the column header of the detailed schedule
  # @return [Boolean] true if schedules include the provided column name.
  def includes_col_name(col_name)
    if @schedules.keys.include?(col_name)
      return true
    end

    return false
  end

  # Assemble schedules from all detailed schedule CSVs into a hash and perform various
  # error-checks and data validation.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param schedules_paths [Array<String>] array of file paths pointing to detailed schedule CSVs
  # @return [nil]
  def import(runner, schedules_paths)
    num_hrs_in_year = Calendar.num_hours_in_year(@year)
    @schedules = {}
    schedules_paths.each do |schedules_path|
      # Note: We don't use the CSV library here because it's slow for large files
      columns = File.readlines(schedules_path).map(&:strip).map { |r| r.split(',') }.transpose
      columns.each do |col|
        col_name = col[0]
        column = Columns.values.find { |c| c.name == col_name }
        if column.nil?
          @schedules[col_name] = col[1..-1]
          runner.registerWarning("Unknown column found in schedule file: #{col_name}. [context: #{schedules_path}]")
          next
        end
        values = col[1..-1].reject { |v| v.nil? }

        begin
          values = values.map { |v| Float(v) }
        rescue ArgumentError
          fail "Schedule value must be numeric for column '#{col_name}'. [context: #{schedules_path}]"
        end

        if @schedules.keys.include? col_name
          fail "Schedule column name '#{col_name}' is duplicated. [context: #{schedules_path}]"
        end

        if column.type == :frac
          if values.max > 1.01 || values.max < 0.99 # Allow some imprecision
            fail "Schedule max value for column '#{col_name}' must be 1. [context: #{schedules_path}]"
          end
        end

        if column.type == :frac
          if values.min < 0
            fail "Schedule min value for column '#{col_name}' must be non-negative. [context: #{schedules_path}]"
          end
        end

        if column.type == :neg_one_to_one
          if values.min < -1
            fail "Schedule value for column '#{col_name}' must be greater than or equal to -1. [context: #{schedules_path}]"
          end
          if values.max > 1
            fail "Schedule value for column '#{col_name}' must be less than or equal to 1. [context: #{schedules_path}]"
          end
        end

        if column.type == :zero_or_one
          if values.any? { |v| v != 0 && v != 1 }
            fail "Schedule value for column '#{col_name}' must be either 0 or 1. [context: #{schedules_path}]"
          end
        end

        valid_minutes_per_item = [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60]
        valid_num_rows = valid_minutes_per_item.map { |min_per_item| (60.0 * num_hrs_in_year / min_per_item).to_i }
        unless valid_num_rows.include? values.length
          fail "Schedule has invalid number of rows (#{values.length}) for column '#{col_name}'. Must be one of: #{valid_num_rows.reverse.join(', ')}. [context: #{@schedules_path}]"
        end

        @schedules[col_name] = values
      end
    end
  end

  # Export a single detailed schedule CSV file.
  #
  # @return [Boolean] true if schedule is exported
  def export()
    return false if @output_schedules_path.nil?

    # Note: We don't use the CSV library here because it's slow for large files
    File.open(@output_schedules_path, 'w') do |csv|
      csv << "#{@tmp_schedules.keys.join(',')}\n"
      @tmp_schedules.values.transpose.each do |row|
        csv << "#{row.join(',')}\n"
      end
    end

    return true
  end

  # Get the column index from the schedules hash to be referenced by OpenStudio ScheduleFile objects.
  #
  # @param col_name [String] the column header of the detailed schedule
  # @return [Integer] the column index of the hash
  def get_col_index(col_name:)
    headers = @tmp_schedules.keys

    col_num = headers.index(col_name)
    return col_num
  end

  # Create a new OpenStudio ScheduleFile object for a column name if one doesn't already exist.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param col_name [String] the column header of the detailed schedule
  # @param rows_to_skip [Integer] number of metadata rows (column headers) in detailed schedule CSV
  # @param schedule_type_limits_name [String] data type for the values contained in the schedule
  # @return [OpenStudio::Model::ScheduleFile] an OpenStudio ScheduleFile object
  def create_schedule_file(model, col_name:, rows_to_skip: 1,
                           schedule_type_limits_name: nil)
    model.getScheduleFiles.each do |schedule_file|
      next if schedule_file.name.to_s != col_name

      return schedule_file
    end

    if @schedules[col_name].nil?
      return
    end

    num_hrs_in_year = Calendar.num_hours_in_year(@year)
    schedule_length = @schedules[col_name].length

    schedule_file = Model.add_schedule_file(
      model,
      name: col_name,
      file_path: @output_schedules_path,
      col_num: get_col_index(col_name: col_name) + 1,
      rows_to_skip: rows_to_skip,
      num_hours: num_hrs_in_year.to_i,
      mins_per_item: (60.0 / (schedule_length / num_hrs_in_year)).to_i,
      limits: schedule_type_limits_name
    )

    return schedule_file
  end

  # The equivalent number of hours in the year, if the schedule was at full load (1.0).
  #
  # @param col_name [String] the column header of the detailed schedule
  # @param schedules [Hash] schedules from all detailed schedule CSVs
  # @return [Double] total number of full load hours for the year
  def annual_equivalent_full_load_hrs(col_name:,
                                      schedules: nil)

    ann_equiv_full_load_hrs = period_equivalent_full_load_hrs(col_name: col_name, schedules: schedules)

    return ann_equiv_full_load_hrs
  end

  # The equivalent number of hours in the period, if the schedule was at full load (1.0).
  #
  # @param col_name [String] the column header of the detailed schedule
  # @param schedules [Hash] schedules from all detailed schedule CSVs
  # @param period [HPXM::UnavailablePeriod] Object that defines begin/end month/day/hour for, e.g., a power outage or vacancy
  # @return [Double] total number of full load hours for the period
  def period_equivalent_full_load_hrs(col_name:,
                                      schedules: nil,
                                      period: nil)
    if schedules.nil?
      schedules = @schedules # the schedules before unavailable periods are applied
    end

    if schedules[col_name].nil?
      return
    end

    num_hrs_in_year = Calendar.num_hours_in_year(@year)
    schedule_length = schedules[col_name].length
    min_per_item = 60.0 / (schedule_length / num_hrs_in_year)

    equiv_full_load_hrs = 0.0
    if not period.nil?
      n_steps = schedules[schedules.keys[0]].length
      num_days_in_year = Calendar.num_days_in_year(@year)
      steps_in_day = n_steps / num_days_in_year
      steps_in_hour = steps_in_day / 24

      begin_day_num = Calendar.get_day_num_from_month_day(@year, period.begin_month, period.begin_day)
      end_day_num = Calendar.get_day_num_from_month_day(@year, period.end_month, period.end_day)

      begin_hour = 0
      end_hour = 24

      begin_hour = period.begin_hour if not period.begin_hour.nil?
      end_hour = period.end_hour if not period.end_hour.nil?

      if end_day_num >= begin_day_num
        start_ix = (begin_day_num - 1) * steps_in_day + (begin_hour * steps_in_hour)
        end_ix = (end_day_num - begin_day_num + 1) * steps_in_day - ((24 - end_hour + begin_hour) * steps_in_hour)
        equiv_full_load_hrs += schedules[col_name][start_ix..end_ix].sum / (60.0 / min_per_item)
      else # Wrap around year
        start_ix = (begin_day_num - 1) * steps_in_day + (begin_hour * steps_in_hour)
        end_ix = -1
        equiv_full_load_hrs += schedules[col_name][start_ix..end_ix].sum / (60.0 / min_per_item)

        start_ix = 0
        end_ix = (end_day_num - 1) * steps_in_day + (end_hour * steps_in_hour)
        equiv_full_load_hrs += schedules[col_name][start_ix..end_ix].sum / (60.0 / min_per_item)
      end
    else # Annual
      equiv_full_load_hrs += schedules[col_name].sum / (60.0 / min_per_item)
    end

    return equiv_full_load_hrs
  end

  # The power in watts the equipment needs to consume so that, if it were to run annual_equivalent_full_load_hrs hours,
  # it would consume the annual_kwh energy in the year. Essentially, returns the watts for the equipment when schedule
  # is at 1.0, so that, for the given schedule values, the equipment will consume annual_kwh energy in a year.
  #
  # @param col_name [String] the column header of the detailed schedule
  # @param annual_kwh [Double] annual consumption in a year (kWh)
  # @return [Double] design level used to represent maximum input (W)
  def calc_design_level_from_annual_kwh(col_name:,
                                        annual_kwh:)
    if @schedules[col_name].nil?
      return
    end

    ann_equiv_full_load_hrs = annual_equivalent_full_load_hrs(col_name: col_name)
    return 0 if ann_equiv_full_load_hrs == 0

    design_level = annual_kwh * 1000.0 / ann_equiv_full_load_hrs # W

    return design_level
  end

  # Similar to ann_equiv_full_load_hrs, but for thermal energy.
  #
  # @param col_name [String] the column header of the detailed schedule
  # @param annual_therm [Double] annual consumption in a year (therm)
  # @return [Double] design level used to represent maximum input (W)
  def calc_design_level_from_annual_therm(col_name:,
                                          annual_therm:)
    if @schedules[col_name].nil?
      return
    end

    annual_kwh = UnitConversions.convert(annual_therm, 'therm', 'kWh')
    design_level = calc_design_level_from_annual_kwh(col_name: col_name, annual_kwh: annual_kwh)

    return design_level
  end

  # Similar to the calc_design_level_from_annual_kwh, but use daily_kwh instead of annual_kwh to calculate the design level.
  #
  # @param col_name [String] the column header of the detailed schedule
  # @param daily_kwh [Double] daily energy use (kWh)
  # @return [Double] design level used to represent maximum input (W)
  def calc_design_level_from_daily_kwh(col_name:,
                                       daily_kwh:)
    if @schedules[col_name].nil?
      return
    end

    full_load_hrs = annual_equivalent_full_load_hrs(col_name: col_name)
    return 0 if full_load_hrs == 0

    num_days_in_year = Calendar.num_days_in_year(@year)
    daily_full_load_hrs = full_load_hrs / num_days_in_year
    design_level = UnitConversions.convert(daily_kwh / daily_full_load_hrs, 'kW', 'W')

    return design_level
  end

  # Similar to calc_design_level_from_daily_kwh but for water usage.
  #
  # @param col_name [String] the column header of the detailed schedule
  # @param daily_water [Double] daily water use (gal/day)
  # @return [Double] peak flow used to represent maximum input (m^3/s)
  def calc_peak_flow_from_daily_gpm(col_name:,
                                    daily_water:)
    if @schedules[col_name].nil?
      return
    end

    ann_equiv_full_load_hrs = annual_equivalent_full_load_hrs(col_name: col_name)
    return 0 if ann_equiv_full_load_hrs == 0

    num_days_in_year = Calendar.num_days_in_year(@year)
    daily_full_load_hrs = ann_equiv_full_load_hrs / num_days_in_year
    peak_flow = daily_water / daily_full_load_hrs # gallons_per_hour
    peak_flow /= 60 # convert to gallons per minute
    peak_flow = UnitConversions.convert(peak_flow, 'gal/min', 'm^3/s') # convert to m^3/s
    return peak_flow
  end

  # Create a column of zeroes or ones for, e.g., vacancy periods or power outage periods.
  #
  # @param col_name [String] the column header of the detailed schedule
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [nil]
  def create_column_values_from_periods(col_name, unavailable_periods)
    n_steps = @tmp_schedules[@tmp_schedules.keys[0]].length
    num_days_in_year = Calendar.num_days_in_year(@year)
    steps_in_day = n_steps / num_days_in_year
    steps_in_hour = steps_in_day / 24

    if @tmp_schedules[col_name].nil?
      @tmp_schedules[col_name] = Array.new(n_steps, 0)
    end

    unavailable_periods.each do |unavailable_period|
      begin_day_num = Calendar.get_day_num_from_month_day(@year, unavailable_period.begin_month, unavailable_period.begin_day)
      end_day_num = Calendar.get_day_num_from_month_day(@year, unavailable_period.end_month, unavailable_period.end_day)

      begin_hour = 0
      end_hour = 24

      begin_hour = unavailable_period.begin_hour if not unavailable_period.begin_hour.nil?
      end_hour = unavailable_period.end_hour if not unavailable_period.end_hour.nil?

      if end_day_num >= begin_day_num
        @tmp_schedules[col_name].fill(1.0, (begin_day_num - 1) * steps_in_day + (begin_hour * steps_in_hour), (end_day_num - begin_day_num + 1) * steps_in_day - ((24 - end_hour + begin_hour) * steps_in_hour)) # Fill between begin/end days
      else # Wrap around year
        @tmp_schedules[col_name].fill(1.0, (begin_day_num - 1) * steps_in_day + (begin_hour * steps_in_hour)) # Fill between begin day and end of year
        @tmp_schedules[col_name].fill(1.0, 0, (end_day_num - 1) * steps_in_day + (end_hour * steps_in_hour)) # Fill between begin of year and end day
      end
    end
  end

  # Expand schedules with fewer elements such that all the schedules have the same number of elements.
  #
  # @return [nil]
  def expand_schedules
    max_size = @schedules.map { |_k, v| v.size }.uniq.max
    @schedules.each do |col, values|
      if values.size < max_size
        @schedules[col] = values.map { |v| [v] * (max_size / values.size) }.flatten
      end
    end
  end

  # Modify the detailed schedules hash referenced by EnergyPlus with appropriate unavailable period values.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [nil]
  def set_unavailable_periods(runner, unavailable_periods)
    if @unavailable_periods_csv_data.nil?
      @unavailable_periods_csv_data = Schedule.get_unavailable_periods_csv_data
    end
    column_names = @unavailable_periods_csv_data[0].keys[1..-1]
    column_names.each do |column_name|
      create_column_values_from_periods(column_name, unavailable_periods.select { |p| p.column_name == column_name })
      next if @tmp_schedules[column_name].all? { |i| i == 0 }

      @tmp_schedules.keys.each do |schedule_name|
        next if column_names.include? schedule_name

        case schedule_name
        when SchedulesFile::Columns[:HotWaterDishwasher].name
          schedule_name2 = SchedulesFile::Columns[:Dishwasher].name
        when SchedulesFile::Columns[:HotWaterClothesWasher].name
          schedule_name2 = SchedulesFile::Columns[:ClothesWasher].name
        when SchedulesFile::Columns[:HeatingSetpoint].name
          schedule_name2 = SchedulesFile::Columns[:SpaceHeating].name
        when SchedulesFile::Columns[:CoolingSetpoint].name
          schedule_name2 = SchedulesFile::Columns[:SpaceCooling].name
        when SchedulesFile::Columns[:WaterHeaterSetpoint].name
          schedule_name2 = SchedulesFile::Columns[:WaterHeater].name
        else
          schedule_name2 = schedule_name
        end

        # Skip those unaffected
        next unless Schedule.unavailable_period_applies(runner, schedule_name2, column_name)

        @tmp_schedules[column_name].each_with_index do |_ts, i|
          if schedule_name == SchedulesFile::Columns[:WaterHeaterSetpoint].name
            # Temperature of tank < 2C indicates of possibility of freeze.
            @tmp_schedules[schedule_name][i] = UnitConversions.convert(2.0, 'C', 'F') if @tmp_schedules[column_name][i] == 1.0
          elsif ![SchedulesFile::Columns[:HeatingSetpoint].name, SchedulesFile::Columns[:CoolingSetpoint].name].include?(schedule_name)
            @tmp_schedules[schedule_name][i] *= (1.0 - @tmp_schedules[column_name][i])
          end
        end
      end
    end
  end

  # Convert detailed setpoint schedule values from F to C.
  #
  # @param offset_db [Double] On-off thermostat deadband
  # @return [nil]
  def convert_setpoints(offset_db)
    setpoint_col_names = Columns.values.select { |c| c.type == :setpoint }.map { |c| c.name }
    return if @tmp_schedules.keys.none? { |k| setpoint_col_names.include?(k) }

    col_names = @tmp_schedules.keys

    offset_db_c = UnitConversions.convert(offset_db.to_f / 2.0, 'deltaF', 'deltaC')
    @tmp_schedules[col_names[0]].each_with_index do |_ts, i|
      setpoint_col_names.each do |setpoint_col_name|
        next unless col_names.include?(setpoint_col_name)

        @tmp_schedules[setpoint_col_name][i] = UnitConversions.convert(@tmp_schedules[setpoint_col_name][i], 'f', 'c').round(4)
        next if offset_db_c == 0.0

        @tmp_schedules[setpoint_col_name][i] = (@tmp_schedules[setpoint_col_name][i] - offset_db_c).round(4) if (setpoint_col_name == SchedulesFile::Columns[:HeatingSetpoint].name)
        @tmp_schedules[setpoint_col_name][i] = (@tmp_schedules[setpoint_col_name][i] + offset_db_c).round(4) if (setpoint_col_name == SchedulesFile::Columns[:CoolingSetpoint].name)
      end
    end
  end

  # Assign separate detailed battery charging and discharging schedules
  # If a single column (e.g., 'battery' or 'electric_vehicle') is provided, it will be split into two columns based on the sign.
  #
  # @return [nil]
  def create_battery_charging_discharging_schedules
    battery_col_hashes = [:Battery, :ElectricVehicle].map do |battery_type|
      { col: SchedulesFile::Columns[battery_type].name, charging_col: SchedulesFile::Columns[:"#{battery_type}Charging"].name, discharging_col: SchedulesFile::Columns[:"#{battery_type}Discharging"].name }
    end
    battery_col_hashes.each do |battery_cols|
      next unless @schedules.keys.include?(battery_cols[:col])

      split_signed_column(battery_cols[:col], battery_cols[:charging_col], battery_cols[:discharging_col])
    end
  end

  # Splits a single column from the @schedules object into two columns, one populated with the positive values and zeros, and one with the negative values and zeros, then deletes the original column.
  #
  # @param column [String] Column name in the @schedules object
  # @param positive_col [String] Name of new positive column in the @schedules object
  # @param negative_col [String] Name of new negative column in the @schedules object
  #
  # @return [nil]
  def split_signed_column(column, positive_col, negative_col)
    @schedules[positive_col] = Array.new(@schedules[column].size, 0)
    @schedules[negative_col] = Array.new(@schedules[column].size, 0)
    @schedules[column].each_with_index do |_ts, i|
      if @schedules[column][i] > 0
        @schedules[positive_col][i] = @schedules[column][i]
      elsif @schedules[column][i] < 0
        @schedules[negative_col][i] = -1 * @schedules[column][i]
      end
    end
    @schedules.delete(column)
  end
end
