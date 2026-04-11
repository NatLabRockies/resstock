# frozen_string_literal: true

# Collection of helper methods related to calendar dates/time.
module Calendar
  # Returns the number of days in each month of the specified calendar year.
  #
  # @param year [Integer] the calendar year
  # @return [Array<Double>] number of days in each month
  def self.num_days_in_months(year)
    n_days_in_months = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    n_days_in_months[1] += 1 if Date.leap?(year)
    return n_days_in_months
  end

  # Returns the number of days in the specified calendar year.
  #
  # @param year [Integer] the calendar year
  # @return [Integer] number of days in the calendar year
  def self.num_days_in_year(year)
    n_days_in_months = num_days_in_months(year)
    n_days_in_year = n_days_in_months.sum
    return n_days_in_year
  end

  # Returns the number of hours in the specified calendar year.
  #
  # @param year [Integer] the calendar year
  # @return [Integer] number of hours in the calendar year
  def self.num_hours_in_year(year)
    n_days_in_year = num_days_in_year(year)
    n_hours_in_year = n_days_in_year * 24
    return n_hours_in_year
  end

  # Returns a value between 1 and 365 (or 366 for a leap year).
  # Returns e.g. 32 for month=2 and day=1 (Feb 1).
  #
  # @param year [Integer] the calendar year
  # @param month [Integer] the month of the year
  # @param day [Integer] the day of the month
  # @return [Integer] the day number of the year
  def self.get_day_num_from_month_day(year, month, day)
    month_num_days = Calendar.num_days_in_months(year)
    day_num = day
    for m in 0..month - 2
      day_num += month_num_days[m]
    end
    return day_num
  end

  # Returns an array of 365 (or 366 for a leap year) values of 0s and 1s that define a daily season.
  #
  # @param year [Integer] the calendar year
  # @param start_month [Integer] the start month of the year
  # @param start_day [Integer] the start day of the start month
  # @param end_month [Integer] the end month of the year
  # @param end_day [Integer] the end day of the end month
  # @return [Array<Integer>] 1s ranging from start month/day to end month/day, and 0s outside of this range
  def self.get_daily_season(year, start_month, start_day, end_month, end_day)
    start_day_num = get_day_num_from_month_day(year, start_month, start_day)
    end_day_num = get_day_num_from_month_day(year, end_month, end_day)

    season = Array.new(Calendar.num_days_in_year(year), 0)
    if end_day_num >= start_day_num
      season.fill(1, start_day_num - 1, end_day_num - start_day_num + 1) # Fill between start/end days
    else # Wrap around year
      season.fill(1, start_day_num - 1) # Fill between start day and end of year
      season.fill(1, 0, end_day_num) # Fill between start of year and end day
    end
    return season
  end

  # Convert a 12-element monthly array of 1s and 0s to a 365-element (or 366-element for a leap year) daily array of 1s and 0s.
  #
  # @param year [Integer] the calendar year
  # @param months [Array<Integer>] monthly array of 1s and 0s
  # @return [Array<Integer>] daily array of 1s and 0s
  def self.months_to_days(year, months)
    month_num_days = Calendar.num_days_in_months(year)
    days = []
    for m in 0..11
      days.concat([months[m]] * month_num_days[m])
    end

    return days
  end

  # Returns a 12-element array of day numbers of the year corresponding to the first days of each month.
  #
  # @param year [Integer] the calendar year
  # @return [Array<Integer>] day number of the year for the first day of each month
  def self.day_start_months(year)
    month_num_days = Calendar.num_days_in_months(year)
    return month_num_days.each_with_index.map { |_n, i| get_day_num_from_month_day(year, i + 1, 1) }
  end

  # Returns a 12-element array of day numbers of the year corresponding to the last days of each month.
  #
  # @param year [Integer] the calendar year
  # @return [Array<Integer>] day number of the year for the last day of each month
  def self.day_end_months(year)
    month_num_days = Calendar.num_days_in_months(year)
    return month_num_days.each_with_index.map { |n, i| get_day_num_from_month_day(year, i + 1, n) }
  end

  # Return begin month/day/hour and end month/day/hour integers based on a string datetime range.
  #
  # @param date_time_range [String] a date like 'Jan 1 - Dec 31' (optionally can enter hour like 'Dec 15 2 - Jan 15 20')
  # @return [Array<Integer, Integer, Integer or nil, Integer, Integer, Integer or nil>] begin/end month/day/hour
  def self.parse_date_time_range(date_time_range)
    begin_end_dates = date_time_range.split('-').map { |v| v.strip }
    if begin_end_dates.size != 2
      fail "Invalid date format specified for '#{date_time_range}'."
    end

    begin_values = begin_end_dates[0].split(' ').map { |v| v.strip }
    end_values = begin_end_dates[1].split(' ').map { |v| v.strip }

    if !(begin_values.size == 2 || begin_values.size == 3) || !(end_values.size == 2 || end_values.size == 3)
      fail "Invalid date format specified for '#{date_time_range}'."
    end

    require 'date'
    begin_month = Date::ABBR_MONTHNAMES.index(begin_values[0].capitalize)
    end_month = Date::ABBR_MONTHNAMES.index(end_values[0].capitalize)
    begin_day = begin_values[1].to_i
    end_day = end_values[1].to_i
    if begin_values.size == 3
      begin_hour = begin_values[2].to_i
    end
    if end_values.size == 3
      end_hour = end_values[2].to_i
    end
    if begin_month.nil? || end_month.nil? || begin_day == 0 || end_day == 0
      fail "Invalid date format specified for '#{date_time_range}'."
    end

    return begin_month, begin_day, begin_hour, end_month, end_day, end_hour
  end

  # Return begin month/day and end month/day based on a provided monthly availability array.
  #
  # @param months [Array<Integer>] monthly array of 1s and 0s
  # @param year [Integer] the calendar year
  # @return [Array<Integer, Integer, Integer, Integer>] begin month/day and end month/day
  def self.get_begin_and_end_dates_from_monthly_array(months, year)
    num_days_in_month = Calendar.num_days_in_months(year)

    if months.uniq.size == 1 && months[0] == 1 # Year-round
      return 1, 1, 12, num_days_in_month[11]
    elsif months.uniq.size == 1 && months[0] == 0 # Never
      return
    elsif months[0] == 1 && months[11] == 1 # Wrap around year
      begin_month = 12 - months.reverse.index(0) + 1
      end_month = months.index(0)
    else
      begin_month = months.index(1) + 1
      end_month = 12 - months.reverse.index(1)
    end

    begin_day = 1
    end_day = num_days_in_month[end_month - 1]

    return begin_month, begin_day, end_month, end_day
  end
end
