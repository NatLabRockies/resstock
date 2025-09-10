# frozen_string_literal: true

require 'openstudio'
require_relative '../../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require 'openstudio'
require 'pathname'
require 'oga'
require 'json'
require_relative 'hvac'

Dir["#{File.dirname(__FILE__)}/../../../../resources/hpxml-measures/BuildResidentialScheduleFile/resources/*.rb"].each do |resource_file|
  require resource_file
end
Dir["#{File.dirname(__FILE__)}/../../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end

class HVACScheduleGenerator
  def initialize(hpxml, hpxml_path, runner, building_index)
    @hpxml_path = hpxml_path
    @hpxml = hpxml
    @hpxml_bldg = @hpxml.buildings[building_index]
    @epw_path = Location.get_epw_path(@hpxml_bldg, @hpxml_path)
    @runner = runner
    @weather = WeatherFile.new(epw_path: @epw_path, runner: @runner)
    @sim_year = Location.get_sim_calendar_year(@hpxml.header.sim_calendar_year, @weather)
    @total_days_in_year = Calendar.num_days_in_year(@sim_year)
    @sim_start_day = DateTime.new(@sim_year, 1, 1)
    @minutes_per_step = @hpxml.header.timestep
    @steps_in_day = 24 * 60 / @minutes_per_step
  end

  def get_heating_cooling_setpoint_schedule
    @runner.registerInfo("Creating heating and cooling setpoint schedules for building #{@hpxml_path}")
    clg_weekday_setpoints, clg_weekend_setpoints, htg_weekday_setpoints, htg_weekend_setpoints = get_heating_cooling_weekday_weekend_setpoints

    heating_setpoint = []
    cooling_setpoint = []

    @total_days_in_year.times do |day|
      today = @sim_start_day + day
      day_of_week = today.wday
      if [0, 6].include?(day_of_week)
        heating_setpoint_sch = htg_weekend_setpoints
        cooling_setpoint_sch = clg_weekend_setpoints
      else
        heating_setpoint_sch = htg_weekday_setpoints
        cooling_setpoint_sch = clg_weekday_setpoints
      end
      @steps_in_day.times do |step|
        hour = (step * @minutes_per_step) / 60
        heating_setpoint << heating_setpoint_sch[day][hour]
        cooling_setpoint << cooling_setpoint_sch[day][hour]
      end
    end
    { heating_setpoint: heating_setpoint, cooling_setpoint: cooling_setpoint }
  end

  def c2f(setpoint_sch)
    setpoint_sch.map { |i| i.map { |j| UnitConversions.convert(j, 'C', 'F') } }
  end

  def get_heating_cooling_weekday_weekend_setpoints
    hvac_control = @hpxml_bldg.hvac_controls[0]
    hvac_season_days = get_heating_cooling_days(hvac_control)
    hvac_control = @hpxml_bldg.hvac_controls[0]
    onoff_thermostat_ddb = @hpxml.header.hvac_onoff_thermostat_deadband.to_f
    htg_weekday_setpoints, htg_weekend_setpoints = HVAC.get_hvac_setpoints(:htg, @hpxml_bldg, hvac_control, @sim_year, onoff_thermostat_ddb, @weather)
    clg_weekday_setpoints, clg_weekend_setpoints = HVAC.get_hvac_setpoints(:clg, @hpxml_bldg, hvac_control, @sim_year, onoff_thermostat_ddb, @weather)

    htg_weekday_setpoints, htg_weekend_setpoints, clg_weekday_setpoints, clg_weekend_setpoints = HVAC.create_setpoint_schedules(@runner, htg_weekday_setpoints, htg_weekend_setpoints, clg_weekday_setpoints, clg_weekend_setpoints, @sim_year, hvac_season_days)
    [c2f(clg_weekday_setpoints), c2f(clg_weekend_setpoints), c2f(htg_weekday_setpoints), c2f(htg_weekend_setpoints)]
  end

  def get_heating_cooling_days(hvac_control)
    htg_start_month = hvac_control.seasons_heating_begin_month || 1
    htg_start_day = hvac_control.seasons_heating_begin_day || 1
    htg_end_month = hvac_control.seasons_heating_end_month || 12
    htg_end_day = hvac_control.seasons_heating_end_day || 31
    clg_start_month = hvac_control.seasons_cooling_begin_month || 1
    clg_start_day = hvac_control.seasons_cooling_begin_day || 1
    clg_end_month = hvac_control.seasons_cooling_end_month || 12
    clg_end_day = hvac_control.seasons_cooling_end_day || 31
    heating_days = Calendar.get_daily_season(@sim_year, htg_start_month, htg_start_day, htg_end_month, htg_end_day)
    cooling_days = Calendar.get_daily_season(@sim_year, clg_start_month, clg_start_day, clg_end_month, clg_end_day)
    { clg: cooling_days, htg: heating_days }
  end

  def main(hpxml_path)
    hpxml = HPXML.new(hpxml_path: hpxml_path)
    _ = SchedulesFile.new(schedules_paths: hpxml.buildings[0].header.schedules_filepaths,
                          year: @year,
                          output_path: @tmp_schedule_file_path)
  end
end
