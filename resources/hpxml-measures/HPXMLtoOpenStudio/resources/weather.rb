# frozen_string_literal: true

$weather_cache = {}

# Object that stores EnergyPlus weather information (either directly sourced from the EPW or
# calculated based on the EPW data).
class WeatherFile
  # @param epw_path [String] Path to the EPW weather file
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  def initialize(epw_path:, runner:)
    if not File.exist?(epw_path)
      fail "Cannot find weather file at #{epw_path}."
    end

    @epw_path = epw_path
    if not $weather_cache[epw_path].nil?
      # Use cache
      epw_data = $weather_cache[epw_path]
      @header = epw_data[:header]
      @data = epw_data[:data]
      @design = epw_data[:design]
      @epw_file = epw_data[:epw_file]
      return
    else
      @header = WeatherHeader.new
      @data = WeatherData.new
      @design = WeatherDesign.new
      @epw_file = OpenStudio::EpwFile.new(epw_path, true)
      $weather_cache[epw_path] = { header: @header,
                                   data: @data,
                                   design: @design,
                                   epw_file: @epw_file }
    end

    process_epw(runner)
  end

  attr_accessor(:header, :data, :design, :epw_file, :epw_path)

  private

  # Main method that processes the EPW file to extract any information we need.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @return [nil]
  def process_epw(runner)
    get_header_info_from_epw(epw_file)
    epw_has_design_data = get_design_info_from_epw(runner, epw_file)

    # Timeseries data:
    rowdata = []
    dailydbs = []
    dailyhighdbs = []
    dailylowdbs = []
    monthdbs = []
    epw_file.data.each_with_index do |epwdata, rownum|
      rowdict = {}
      rowdict['month'] = epwdata.month
      rowdict['day'] = epwdata.day
      rowdict['hour'] = epwdata.hour
      begin
        rowdict['db'] = epwdata.dryBulbTemperature.get
      rescue
        fail "Cannot retrieve dryBulbTemperature from the EPW for hour #{rownum + 1}."
      end
      begin
        rowdict['rh'] = epwdata.relativeHumidity.get / 100.0
      rescue
        fail "Cannot retrieve relativeHumidity from the EPW for hour #{rownum + 1}."
      end
      begin
        rowdict['ws'] = epwdata.windSpeed.get
      rescue
        fail "Cannot retrieve windSpeed from the EPW for hour #{rownum + 1}."
      end
      monthdbs << [] if rowdict['day'] == 1
      monthdbs[rowdict['month'] - 1] << rowdict['db']

      rowdata << rowdict

      next unless (rownum + 1) % (24 * header.RecordsPerHour) == 0

      db = []
      maxdb = rowdata[rowdata.length - (24 * header.RecordsPerHour)]['db']
      mindb = rowdata[rowdata.length - (24 * header.RecordsPerHour)]['db']
      rowdata[rowdata.length - (24 * header.RecordsPerHour)..-1].each do |x|
        if x['db'] > maxdb
          maxdb = x['db']
        end
        if x['db'] < mindb
          mindb = x['db']
        end
        db << x['db']
      end

      dailydbs << db.sum(0.0) / (24.0 * header.RecordsPerHour)
      dailyhighdbs << maxdb
      dailylowdbs << mindb
    end

    data.AnnualAvgDrybulb = UnitConversions.convert(rowdata.map { |x| x['db'] }.sum(0.0) / rowdata.length, 'C', 'F')
    data.AnnualMinDrybulb = UnitConversions.convert(rowdata.map { |x| x['db'] }.min, 'C', 'F')
    data.AnnualMaxDrybulb = UnitConversions.convert(rowdata.map { |x| x['db'] }.max, 'C', 'F')
    data.MonthlyAvgDrybulbs = []
    for i in 1..12
      data.MonthlyAvgDrybulbs << UnitConversions.convert(monthdbs[i - 1].sum / monthdbs[i - 1].length, 'C', 'F')
    end

    calc_heat_cool_degree_days(dailydbs)
    calc_avg_monthly_highs_lows(dailyhighdbs, dailylowdbs)
    calc_shallow_ground_temperatures()
    calc_deep_ground_temperatures()
    calc_mains_temperatures(dailydbs.size)
    data.WSF = calc_ashrae_622_wsf(rowdata)

    if not epw_has_design_data
      calc_design_info(runner, rowdata)
    end
  end

  # Calculates and stores heating/cooling degree days for different base temperatures.
  #
  # @param dailydbs [Array<Double>] Daily average drybulb temperatures (C)
  # @return [nil]
  def calc_heat_cool_degree_days(dailydbs)
    data.HDD65F = calc_degree_days(dailydbs, 65, true)
    data.HDD50F = calc_degree_days(dailydbs, 50, true)
    data.CDD65F = calc_degree_days(dailydbs, 65, false)
    data.CDD50F = calc_degree_days(dailydbs, 50, false)
  end

  # Calculates and returns degree days from a base temperature for either heating or cooling.
  #
  # @param dailydbs [Array<Double>] Daily average drybulb temperatures (C)
  # @param base_temp_f [Double] Base drybulb temperature for the calculation (F)
  # @param is_heating [Boolean] True if heating, false if cooling
  # @return [Double] Degree days (deltaF)
  def calc_degree_days(daily_dbs, base_temp_f, is_heating)
    base_temp_c = UnitConversions.convert(base_temp_f, 'F', 'C')

    deg_days = []
    if is_heating
      daily_dbs.each do |x|
        if x < base_temp_c
          deg_days << base_temp_c - x
        end
      end
    else
      daily_dbs.each do |x|
        if x > base_temp_c
          deg_days << x - base_temp_c
        end
      end
    end
    if deg_days.size == 0
      return 0.0
    end

    deg_days = deg_days.sum(0.0)
    return UnitConversions.convert(deg_days, 'deltac', 'deltaf')
  end

  # Calculates and stores avg daily highs and lows for each month.
  #
  # @param daily_high_dbs [Array<Double>] Daily maximum drybulb temperatures (C)
  # @param daily_low_dbs [Array<Double>] Daily minimum drybulb temperatures (C)
  # @return [nil]
  def calc_avg_monthly_highs_lows(daily_high_dbs, daily_low_dbs)
    data.MonthlyAvgDailyHighDrybulbs = []
    data.MonthlyAvgDailyLowDrybulbs = []

    if daily_high_dbs.size == 365 # standard year
      month_num_days = Calendar.num_days_in_months(1999)
    elsif daily_high_dbs.size == 366 # leap year
      month_num_days = Calendar.num_days_in_months(2000)
    else
      fail "Unexpected number of days: #{daily_high_dbs.size}."
    end

    first_day = 0
    for month in 1..12
      ndays = month_num_days[month - 1] # Number of days in current month
      if month > 1
        first_day += month_num_days[month - 2] # Number of days in previous month
      end
      avg_high = daily_high_dbs[first_day, ndays].sum(0.0) / ndays.to_f
      avg_low = daily_low_dbs[first_day, ndays].sum(0.0) / ndays.to_f
      data.MonthlyAvgDailyHighDrybulbs << UnitConversions.convert(avg_high, 'C', 'F')
      data.MonthlyAvgDailyLowDrybulbs << UnitConversions.convert(avg_low, 'C', 'F')
    end
  end

  # Calculates the ASHRAE 62.2 Weather and Shielding Factor (WSF) value per report
  # LBNL-5795E "Infiltration as Ventilation: Weather-Induced Dilution" if the value is
  # not available in the ashrae622_wsf.csv resource file.
  #
  # @param rowdata [Array<Hash>] Weather data for each EPW record
  # @return [Double] WSF value
  def calc_ashrae_622_wsf(rowdata)
    # First look in CSV
    wsf = nil
    csv_path = File.join(File.dirname(__FILE__), 'data', 'ashrae622_wsf.csv')
    File.readlines(csv_path).each do |row|
      row = row.split(',')
      next if row[0] != header.WMONumber

      wsf = Float(row[1])
    end
    if not wsf.nil?
      return wsf.round(2)
    end

    # If not found, calculate from weather data

    # Constants
    c_d = 1.0       # discharge coefficient for ELA (at 4 Pa) (unitless)
    t_indoor = 22.0 # indoor setpoint year-round (C)
    n = 0.67        # pressure exponent (unitless)
    s = 0.7         # shelter class 4 for 1-story with flue, enhanced model (unitless)
    delta_p = 4.0   # pressure difference indoor-outdoor (Pa)
    u_min = 1.0     # minimum windspeed per hour (m/s)
    ela = 0.074     # effective leakage area (assumed) (m2)
    cfa = 185.0     # conditioned floor area (m2)
    h = 2.5         # single story height (m)
    g = 0.48        # wind speed multiplier for 1-story, enhanced model (unitless)
    c_s = 0.069     # stack coefficient, 1-story with flue, enhanced model ((Pa/K)^n)
    c_w = 0.142     # wind coefficient, bsmt slab 1-story with flue, enhanced model ((Pa*s^2/m^2)^n)
    roe = 1.2       # air density (assumed at sea level) (kg/m^3)

    c = c_d * ela * (2 / roe)**0.5 * delta_p**(0.5 - n) # m^3/(s*Pa^n), flow coefficient

    taus = []
    prev_tau = 0.0
    for hr in 0..rowdata.size - 1
      q_s = c * c_s * (t_indoor - rowdata[hr]['db']).abs**n
      q_w = c * c_w * (s * g * [rowdata[hr]['ws'], u_min].max)**(2 * n)
      q_tot = (q_s**2 + q_w**2)**0.5
      ach = 3600.0 * q_tot / (h * cfa)
      taus << (1 - Math.exp(-ach)) / ach + prev_tau * Math.exp(-ach)
      prev_tau = taus[-1]
    end

    tau = taus.sum(0.0) / taus.size.to_f # Mean annual turnover time (hours)
    wsf = (cfa / ela) / (1000.0 * tau)

    return wsf.round(2)
  end

  # Gets and stores various EPW header data.
  #
  # @param epw_file [OpenStudio::EpwFile] OpenStudio EpwFile object
  # @return [nil]
  def get_header_info_from_epw(epw_file)
    header.City = epw_file.city
    header.StateProvinceRegion = epw_file.stateProvinceRegion
    header.Latitude = epw_file.latitude
    header.Longitude = epw_file.longitude
    header.Elevation = UnitConversions.convert(epw_file.elevation, 'm', 'ft')
    header.TimeZone = epw_file.timeZone
    header.WMONumber = epw_file.wmoNumber
    if epw_file.daylightSavingStartDate.is_initialized
      header.DSTStartDate = epw_file.daylightSavingStartDate.get
    end
    if epw_file.daylightSavingEndDate.is_initialized
      header.DSTEndDate = epw_file.daylightSavingEndDate.get
    end
    if epw_file.startDateActualYear.is_initialized
      header.ActualYear = epw_file.startDateActualYear.get
    end
    header.RecordsPerHour = epw_file.recordsPerHour
    header.NumRecords = epw_file.data.size

    if header.RecordsPerHour != 1
      fail "Unexpected records per hour: #{header.RecordsPerHour}."
    end
  end

  # Stores design conditions from the EPW header if available. If there are multiple
  # design conditions, retrieves the first one and issues a warning.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param epw_file [OpenStudio::EpwFile] OpenStudio EpwFile object
  # @return [Boolean] True if the EPW file has design conditions in the header
  def get_design_info_from_epw(runner, epw_file)
    epw_design_conditions = epw_file.designConditions
    if epw_design_conditions.length > 0
      epw_design_condition = epw_design_conditions[0]
      if epw_design_conditions.length > 1 && (not runner.nil?)
        runner.registerWarning("Multiple EPW design conditions found; the first one (#{epw_design_condition.titleOfDesignCondition}) will be used.")
      end

      incomplete_data = false
      if epw_design_condition.heatingDryBulb99.is_initialized
        hdb = epw_design_condition.heatingDryBulb99.get
      else
        incomplete_data = true
      end
      if epw_design_condition.coolingDryBulb1.is_initialized
        cdb = epw_design_condition.coolingDryBulb1.get
      else
        incomplete_data = true
      end
      if epw_design_condition.coolingDryBulbRange.is_initialized
        dtr = epw_design_condition.coolingDryBulbRange.get
      else
        incomplete_data = true
      end
      if epw_design_condition.coolingMeanCoincidentWetBulb1.is_initialized
        mcwb = epw_design_condition.coolingMeanCoincidentWetBulb1.get
      else
        incomplete_data = true
      end

      if incomplete_data
        if not runner.nil?
          runner.registerWarning('Incomplete EPW design conditions found; calculating design conditions from EPW weather data.')
        end
        return false
      end

      design.HeatingDrybulb = UnitConversions.convert(hdb, 'C', 'F')
      design.CoolingDrybulb = UnitConversions.convert(cdb, 'C', 'F')
      design.DailyTemperatureRange = UnitConversions.convert(dtr, 'deltaC', 'deltaF')
      press_psi = Psychrometrics.Pstd_fZ(header.Elevation)
      design.CoolingHumidityRatio = Psychrometrics.w_fT_Twb_P(design.CoolingDrybulb, UnitConversions.convert(mcwb, 'C', 'F'), press_psi)
      return true
    end

    if not runner.nil?
      runner.registerWarning('No EPW design conditions found; calculating design conditions from EPW weather data.')
    end
    return false
  end

  # Calculates and stores design conditions from the EPW data. This is a fallback for
  # when the EPW header does not have design conditions.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param rowdata [Array<Hash>] Weather data for each EPW record
  # @return [nil]
  def calc_design_info(runner, rowdata)
    press_psi = Psychrometrics.Pstd_fZ(header.Elevation)
    annual_hd_sorted_by_db = rowdata.sort_by { |x| x['db'] }

    # 1%/99% values
    heat99per_db = annual_hd_sorted_by_db[88 * header.RecordsPerHour]['db']
    cool01per_db = annual_hd_sorted_by_db[8673 * header.RecordsPerHour]['db']

    # Mean coincident values for cooling
    cool_wetbulb = []
    for i in 0..(annual_hd_sorted_by_db.size - 1)
      next unless (annual_hd_sorted_by_db[i]['db'] > cool01per_db - 0.5) && (annual_hd_sorted_by_db[i]['db'] < cool01per_db + 0.5)

      wb = Psychrometrics.Twb_fT_R_P(runner, UnitConversions.convert(annual_hd_sorted_by_db[i]['db'], 'C', 'F'), annual_hd_sorted_by_db[i]['rh'], press_psi)
      cool_wetbulb << wb
    end
    cool_design_wb = cool_wetbulb.sum(0.0) / cool_wetbulb.size

    design.CoolingDrybulb = UnitConversions.convert(cool01per_db, 'C', 'F')
    design.CoolingHumidityRatio = Psychrometrics.w_fT_Twb_P(design.CoolingDrybulb, cool_design_wb, press_psi)

    hottest_month_index = data.MonthlyAvgDrybulbs.each_with_index.max[1]
    design.DailyTemperatureRange = data.MonthlyAvgDailyHighDrybulbs[hottest_month_index] - data.MonthlyAvgDailyLowDrybulbs[hottest_month_index]

    design.HeatingDrybulb = UnitConversions.convert(heat99per_db, 'C', 'F')
  end

  # Calculates and stores shallow monthly/annual ground temperatures.
  # This correlation is the same that is used in DOE-2's src\WTH.f file, subroutine GTEMP.
  #
  # @return [nil]
  def calc_shallow_ground_temperatures()
    amon = [15.0, 46.0, 74.0, 95.0, 135.0, 166.0, 196.0, 227.0, 258.0, 288.0, 319.0, 349.0]
    po = 0.6
    dif = 0.025
    p = UnitConversions.convert(1.0, 'yr', 'hr')

    beta = Math::sqrt(Math::PI / (p * dif)) * 10.0
    x = Math::exp(-beta)
    s = Math::sin(beta)
    c = Math::cos(beta)
    y = (x**2 - 2.0 * x * c + 1.0) / (2.0 * beta**2.0)
    gm = Math::sqrt(y)
    z = (1.0 - x * (c + s)) / (1.0 - x * (c - s))
    phi = Math::atan(z)
    bo = (data.MonthlyAvgDrybulbs.max - data.MonthlyAvgDrybulbs.min) * 0.5

    data.ShallowGroundMonthlyTemps = []
    for i in 0..11
      theta = amon[i] * 24.0
      data.ShallowGroundMonthlyTemps << UnitConversions.convert(data.AnnualAvgDrybulb - bo * Math::cos(2.0 * Math::PI / p * theta - po - phi) * gm + 460.0, 'R', 'F')
    end
    data.ShallowGroundAnnualTemp = data.AnnualAvgDrybulb

    if header.Latitude < 0
      # Southern hemisphere
      data.ShallowGroundMonthlyTemps.rotate!(6)
    end
  end

  # Stores deep ground temperature data for Xing's model, for use with
  # the ground source heat pump model.
  #
  # @return [nil]
  def calc_deep_ground_temperatures()
    csv_path = File.join(File.dirname(__FILE__), 'data', 'Xing_okstate_0664D_13659_Table_A-3.csv')
    if not File.exist?(csv_path)
      fail 'Could not find Xing_okstate_0664D_13659_Table_A-3.csv'
    end

    require 'csv'
    require 'matrix'

    # Note: We don't use the CSV library here because it's slow for large files
    csv_data = File.readlines(csv_path).map(&:strip)

    # Minimize distance to Station
    v1 = Vector[header.Latitude, header.Longitude]
    dist = 1 / Constants::Small
    temperatures_amplitudes = nil
    csv_data.each_with_index do |row, i|
      next if i == 0 # skip header

      row = row.split(',')
      v2 = Vector[row[3].to_f, row[4].to_f]
      new_dist = (v1 - v2).magnitude
      if new_dist < dist
        temperatures_amplitudes = row[5..9].map(&:to_f)
        dist = new_dist
      end
    end

    data.DeepGroundAnnualTemp = UnitConversions.convert(temperatures_amplitudes[0], 'C', 'F')
    data.DeepGroundSurfTempAmp1 = UnitConversions.convert(temperatures_amplitudes[1], 'deltac', 'deltaf')
    data.DeepGroundSurfTempAmp2 = UnitConversions.convert(temperatures_amplitudes[2], 'deltac', 'deltaf')
    data.DeepGroundPhaseShiftTempAmp1 = temperatures_amplitudes[3] # days
    data.DeepGroundPhaseShiftTempAmp2 = temperatures_amplitudes[4] # days
  end

  # Calculates and stores the mains water temperature using Burch & Christensen algorithm from
  # "Towards Development of an Algorithm for Mains Water Temperature".
  #
  # @param n_days [Integer] Number of days (typically 365 or 366 if a leap year) in the EPW file
  # @return [nil]
  def calc_mains_temperatures(n_days)
    deg_rad = Math::PI / 180

    tmains_ratio = 0.4 + 0.01 * (data.AnnualAvgDrybulb - 44)
    tmains_lag = 35 - (data.AnnualAvgDrybulb - 44)
    if header.Latitude < 0
      sign = 1 # southern hemisphere
    else
      sign = -1
    end

    maxDiffMonthlyAvgOAT = data.MonthlyAvgDrybulbs.max - data.MonthlyAvgDrybulbs.min

    # Calculate daily and annual
    data.MainsDailyTemps = []
    for d in 1..n_days
      data.MainsDailyTemps << data.AnnualAvgDrybulb + 6 + tmains_ratio * maxDiffMonthlyAvgOAT / 2 * Math.sin(deg_rad * (0.986 * (d - 15 - tmains_lag) + sign * 90))
    end
    data.MainsDailyTemps.map! { |temp| [32.0, temp].max } # ensure mains never gets below freezing. Algorithm will never provide water over boiling without a check
    data.MainsAnnualTemp = data.MainsDailyTemps.sum / n_days

    # Calculate monthly
    data.MainsMonthlyTemps = []
    for m in 1..12
      data.MainsMonthlyTemps << data.AnnualAvgDrybulb + 6 + tmains_ratio * maxDiffMonthlyAvgOAT / 2 * Math.sin(deg_rad * (0.986 * ((m * 30 - 15) - 15 - tmains_lag) + sign * 90))
    end
    data.MainsMonthlyTemps.map! { |temp| [32.0, temp].max } # ensure mains never gets below freezing. Algorithm will never provide water over boiling without a check
  end
end

# WeatherFile child object with EPW header data
class WeatherHeader
  attr_accessor(:City,                # [String] Weather station name of city
                :StateProvinceRegion, # [String] Weather station state or province
                :Latitude,            # [Double] Weather station latitude (+/- degrees.minutes)
                :Longitude,           # [Double] Weather station longitude (+/- degrees.minutes)
                :Elevation,           # [Double] Weather station elevation (ft)
                :TimeZone,            # [Double] Weather station time zone (GTM +/-)
                :WMONumber,           # [String] Weather station World Meteorological Organization (WMO) number
                :DSTStartDate,        # [OpenStudio::Date] Daylight Saving start date
                :DSTEndDate,          # [OpenStudio::Date] Daylight Saving end date
                :ActualYear,          # [Integer] Calendar year if an AMY (Actual Meteorological Year) weather file
                :RecordsPerHour,      # [Integer] Number of EPW datapoints per hour (typically 1)
                :NumRecords)          # [Integer] Number of EPW datapoints (typically 8760 or 8784 if a leap year)
end

# WeatherFile child object with data calculated based on 8760 hourly EPW data or other sources
class WeatherData
  attr_accessor(:AnnualAvgDrybulb,             # [Double] Annual average drybulb temperature (F)
                :AnnualMinDrybulb,             # [Double] Annual minimum drybulb temperature (F)
                :AnnualMaxDrybulb,             # [Double] Annual maximum drybulb temperature (F)
                :CDD50F,                       # [Double] Cooling degree days using 50 F base temperature (F-days)
                :CDD65F,                       # [Double] Cooling degree days using 65 F base temperature (F-days)
                :HDD50F,                       # [Double] Heating degree days using 50 F base temperature (F-days)
                :HDD65F,                       # [Double] Heating degree days using 65 F base temperature (F-days)
                :MonthlyAvgDrybulbs,           # [Array<Double>] Monthly average drybulb temperatures (F)
                :ShallowGroundAnnualTemp,      # [Double] Shallow ground annual average drybulb temperature (F)
                :ShallowGroundMonthlyTemps,    # [Array<Double>] Shallow ground monthly average drybulb temperatures (F)
                :DeepGroundAnnualTemp,         # [Double] Deep ground annual average drybulb temperature (F)
                :DeepGroundSurfTempAmp1,       # [Double] First ground temperature amplitude parameter for Xing model (deltaF)
                :DeepGroundSurfTempAmp2,       # [Double] Second ground temperature amplitude parameter for Xing model (deltaF)
                :DeepGroundPhaseShiftTempAmp1, # [Double] First phase shift of surface temperature amplitude for Xing model (days)
                :DeepGroundPhaseShiftTempAmp2, # [Double] Second phase shift of surface temperature amplitude for Xing model (days)
                :WSF,                          # [Double] Weather and Shielding Factor (WSF) from ASHRAE 62.2
                :MonthlyAvgDailyHighDrybulbs,  # [Array<Double>] Average daily high drybulb temperatures for each month (F)
                :MonthlyAvgDailyLowDrybulbs,   # [Array<Double>] Average daily low drybulb temperatures for each month (F)
                :MainsAnnualTemp,              # [Double] Annual average mains water temperature (F)
                :MainsDailyTemps,              # [Array<Double>] Daily average mains water temperatures (F)
                :MainsMonthlyTemps)            # [Array<Double>] Monthly average mains water temperatures (F)
end

# WeatherFile child object with EPW data related to design load calculations
# Either taken directly directly from the EPW header or calculated based on the 8760 hourly data
class WeatherDesign
  attr_accessor(:HeatingDrybulb,        # [Double] 99% heating design drybulb temperature (F)
                :CoolingDrybulb,        # [Double] 1% cooling design drybulb temperature (F)
                :CoolingHumidityRatio,  # [Double] Humidity ratio corresponding to cooling mean coincident wetbulb temperature (lbm/lbm)
                :DailyTemperatureRange) # [Double] Difference between daily high/low outdoor drybulb temperatures during the hottest month (deltaF)
end
