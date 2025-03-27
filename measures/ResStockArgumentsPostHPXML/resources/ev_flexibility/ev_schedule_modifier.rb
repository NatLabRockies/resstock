# frozen_string_literal: true

require 'date'
require 'csv'
require 'json'
require 'openstudio'
require_relative '../common/schedule_modifier'

Dir["#{File.dirname(__FILE__)}/../../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end


class EVScheduleModifier < ScheduleModifier

  # Modifies the EV schedule based on flexibility inputs
  # @param ev_schedule [Array] Array of EV charging values (+ve is charging, -ve is discharging)
  # @param flexibility_inputs [FlexibilityInputs] Inputs for schedule modification
  # @return [Array] Modified EV schedule with charging (positive values) set to 0 during peak periods
  def modify_schedule(ev_schedule, flexibility_inputs)
    log_inputs(flexibility_inputs)
    modified_schedule = ev_schedule[:electric_vehicle].dup
    total_indices = modified_schedule.length
    # Initialize peak_period array with zeros
    peak_period = Array.new(total_indices, 0)
    total_indices.times do |index|
      offset_times = _get_peak_times(index, flexibility_inputs)
      index_in_day = index % (24 * @num_timesteps_per_hour)   
      # Check if current time is within peak period
      if offset_times.peak_start_index <= index_in_day && index_in_day < offset_times.peak_end_index
        peak_period[index] = 1
        if modified_schedule[index] > 0  # if charging, set to 0
          modified_schedule[index] = 0
        end
      end
    end
    return {
      electric_vehicle: modified_schedule,
      peak_period: peak_period
    }
  end

  def log_inputs(inputs)
    return unless @runner

    @runner.registerInfo('Modifying EV schedule ...')
    @runner.registerInfo("random_shift_steps=#{inputs.random_shift_steps}")
  end

end