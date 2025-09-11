# frozen_string_literal: true

# Collection of methods related to HVAC systems.
module HVAC
  # Creates setpoint schedules.
  # This method ensures that we don't construct a setpoint schedule where the cooling setpoint
  # is less than the heating setpoint, which would result in an E+ error.
  #
  # Note: It's tempting to adjust the setpoints, e.g., outside of the heating/cooling seasons,
  # to prevent unmet hours being reported. This is a dangerous idea. These setpoints are used
  # by natural ventilation, Kiva initialization, and probably other things.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param htg_wd_setpoints [TODO] TODO
  # @param htg_we_setpoints [TODO] TODO
  # @param clg_wd_setpoints [TODO] TODO
  # @param clg_we_setpoints [TODO] TODO
  # @param year [Integer] the calendar year
  # @param hvac_season_days [Hash] Map of htg/clg => Array of 365 days with 1s during the heating/cooling season and 0s otherwise
  # @return [TODO] TODO
  def self.create_setpoint_schedules(runner, htg_wd_setpoints, htg_we_setpoints, clg_wd_setpoints, clg_we_setpoints, year,
                                     hvac_season_days)
    warning = false
    for i in 0..(Calendar.num_days_in_year(year) - 1)
      if (hvac_season_days[:htg][i] == hvac_season_days[:clg][i]) # both (or neither) heating/cooling seasons
        htg_wkdy = htg_wd_setpoints[i].zip(clg_wd_setpoints[i]).map { |h, c| c < h ? (h + c) / 2.0 : h }
        htg_wked = htg_we_setpoints[i].zip(clg_we_setpoints[i]).map { |h, c| c < h ? (h + c) / 2.0 : h }
        clg_wkdy = htg_wd_setpoints[i].zip(clg_wd_setpoints[i]).map { |h, c| c < h ? (h + c) / 2.0 : c }
        clg_wked = htg_we_setpoints[i].zip(clg_we_setpoints[i]).map { |h, c| c < h ? (h + c) / 2.0 : c }
      elsif hvac_season_days[:htg][i] == 1 # heating only seasons; cooling has minimum of heating
        htg_wkdy = htg_wd_setpoints[i]
        htg_wked = htg_we_setpoints[i]
        clg_wkdy = htg_wd_setpoints[i].zip(clg_wd_setpoints[i]).map { |h, c| c < h ? h : c }
        clg_wked = htg_we_setpoints[i].zip(clg_we_setpoints[i]).map { |h, c| c < h ? h : c }
      elsif hvac_season_days[:clg][i] == 1 # cooling only seasons; heating has maximum of cooling
        htg_wkdy = clg_wd_setpoints[i].zip(htg_wd_setpoints[i]).map { |c, h| c < h ? c : h }
        htg_wked = clg_we_setpoints[i].zip(htg_we_setpoints[i]).map { |c, h| c < h ? c : h }
        clg_wkdy = clg_wd_setpoints[i]
        clg_wked = clg_we_setpoints[i]
      else
        fail 'HeatingSeason and CoolingSeason, when combined, must span the entire year.'
      end
      if (htg_wkdy != htg_wd_setpoints[i]) || (htg_wked != htg_we_setpoints[i]) || (clg_wkdy != clg_wd_setpoints[i]) || (clg_wked != clg_we_setpoints[i])
        warning = true
      end
      htg_wd_setpoints[i] = htg_wkdy
      htg_we_setpoints[i] = htg_wked
      clg_wd_setpoints[i] = clg_wkdy
      clg_we_setpoints[i] = clg_wked
    end

    if warning
      runner.registerWarning('HVAC setpoints have been automatically adjusted to prevent periods where the heating setpoint is greater than the cooling setpoint.')
    end

    return htg_wd_setpoints, htg_we_setpoints, clg_wd_setpoints, clg_we_setpoints
  end
end
