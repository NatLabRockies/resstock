# frozen_string_literal: true

# Collection of methods for applying site, year, daylight saving time, and ground temperature properties.
# Also includes some helper methods for getting IECC climate zone based on WMO, EPW file path, and simulation calendar year.
module Location
  # This method calls individual methods for applying site, year, daylight saving time, and ground temperature properties on OpenStudio objects.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply(model, weather, hpxml_bldg, hpxml_header)
    apply_weather_file(model, weather)
    apply_year(model, hpxml_header, weather)
    apply_site(model, hpxml_bldg)
    apply_dst(model, hpxml_bldg)
    apply_ground_temps(model, weather, hpxml_bldg)
  end

  # Sets the OpenStudio WeatherFile object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [nil]
  def self.apply_weather_file(model, weather)
    OpenStudio::Model::WeatherFile.setWeatherFile(model, weather.epw_file)
  end

  # Set latitude, longitude, time zone, and elevation on the OpenStudio Site object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_site(model, hpxml_bldg)
    site = model.getSite
    site.setName("#{hpxml_bldg.city}_#{hpxml_bldg.state_code}")
    site.setLatitude(hpxml_bldg.latitude)
    site.setLongitude(hpxml_bldg.longitude)
    site.setTimeZone(hpxml_bldg.time_zone_utc_offset)
    site.setElevation(UnitConversions.convert(hpxml_bldg.elevation, 'ft', 'm').round)

    # Tell EnergyPlus to use these values, not what's in the weather station (which
    # may be at a very different, e.g., elevation)
    site.setKeepSiteLocationInformation(true)
  end

  # Set calendar year on the OpenStudio YearDescription object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [nil]
  def self.apply_year(model, hpxml_header, weather)
    if Date.leap?(hpxml_header.sim_calendar_year)
      n_hours = weather.header.NumRecords
      if n_hours != 8784
        fail "Specified a leap year (#{hpxml_header.sim_calendar_year}) but weather data has #{n_hours} hours."
      end
    end

    year_description = model.getYearDescription
    year_description.setCalendarYear(hpxml_header.sim_calendar_year)
  end

  # If enabled, set daylight saving time start and end dates on the OpenStudio RunPeriodControlDaylightSavingTime object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_dst(model, hpxml_bldg)
    return unless hpxml_bldg.dst_observed

    month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    dst_start_date = "#{month_names[hpxml_bldg.dst_begin_month - 1]} #{hpxml_bldg.dst_begin_day}"
    dst_end_date = "#{month_names[hpxml_bldg.dst_end_month - 1]} #{hpxml_bldg.dst_end_day}"

    run_period_control_daylight_saving_time = model.getRunPeriodControlDaylightSavingTime
    run_period_control_daylight_saving_time.setStartDate(dst_start_date)
    run_period_control_daylight_saving_time.setEndDate(dst_end_date)
  end

  # Set monthly shallow (varies by month) and monthly deep (constant) ground temperatures on the OpenStudio SiteGroundTemperatureShallow and SiteGroundTemperatureDeep objects, respectively.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_ground_temps(model, weather, hpxml_bldg)
    # Shallow ground temperatures only currently used for ducts located under slab
    sgts = model.getSiteGroundTemperatureShallow
    sgts.resetAllMonths
    sgts.setAllMonthlyTemperatures(weather.data.ShallowGroundMonthlyTemps.map { |t| UnitConversions.convert(t, 'F', 'C') })

    if hpxml_bldg.heat_pumps.count { |h| h.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir } > 0
      # Deep ground temperatures used by GSHP setpoint manager
      dgts = model.getSiteGroundTemperatureDeep
      dgts.resetAllMonths
      dgts.setAllMonthlyTemperatures([UnitConversions.convert(weather.data.DeepGroundAnnualTemp, 'F', 'C')] * 12)
    end
  end

  # Get (find) the absolute path to the EPW file.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_path [String] Path to the HPXML file
  # @return [String] Path to the EnergyPlus weather file (EPW)
  def self.get_epw_path(hpxml_bldg, hpxml_path)
    if hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath.nil?
      epw_filepath = Defaults.lookup_weather_data_from_zipcode(hpxml_bldg.zip_code)[:station_filename]
    else
      epw_filepath = hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath
    end
    abs_epw_path = File.absolute_path(epw_filepath)

    if not File.exist? abs_epw_path
      # Check path relative to HPXML file
      abs_epw_path = File.absolute_path(File.join(File.dirname(hpxml_path), epw_filepath))
    end
    if not File.exist? abs_epw_path
      # Check for weather path relative to the HPXML file
      for level_deep in 1..3
        level = (['..'] * level_deep).join('/')
        abs_epw_path = File.absolute_path(File.join(File.dirname(hpxml_path), level, 'weather', epw_filepath))
        break if File.exist? abs_epw_path
      end
    end
    if not File.exist? abs_epw_path
      # Check for weather path relative to this file
      for level_deep in 1..3
        level = (['..'] * level_deep).join('/')
        abs_epw_path = File.absolute_path(File.join(File.dirname(__FILE__), level, 'weather', epw_filepath))
        break if File.exist? abs_epw_path
      end
    end
    if not File.exist? abs_epw_path
      fail "'#{epw_filepath}' could not be found."
    end

    return abs_epw_path
  end

  # Get the simulation calendar year.
  #
  # @param sim_calendar_year [Integer] nil if EPW is AMY or using 2007 default
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [Integer] the simulation calendar year
  def self.get_sim_calendar_year(sim_calendar_year, weather)
    if not weather.header.ActualYear.nil? # AMY
      sim_calendar_year = weather.header.ActualYear
    end
    if sim_calendar_year.nil?
      sim_calendar_year = 2007
    end

    return sim_calendar_year
  end
end
