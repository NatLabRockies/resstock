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

# HVACScheduleModifier extends ScheduleModifier to provide functionality for modifying HVAC setpoints
# based on flexibility inputs such as peak offsets and pre-peak durations.
# It implements methods to adjust heating and cooling setpoints during peak and pre-peak periods.
class HVACScheduleModifier < ScheduleModifier
  # Modifies heating and cooling setpoints based on flexibility inputs
  # @param setpoints [Hash] Hash containing :heating_setpoint and :cooling_setpoint arrays
  # @param flexibility_inputs [HVACFlexibilityInputs] Struct containing peak_offset, pre_peak_duration_steps, pre_peak_offset, and random_shift_steps
  # @return [Hash] Hash containing modified :heating_setpoint, :cooling_setpoint, :peak_period, and :pre_peak_period arrays
  def modify_shedule(schedule, flexibility_inputs)
    log_inputs(flexibility_inputs)
    heating_setpoint = schedule[:heating_setpoint].dup
    cooling_setpoint = schedule[:cooling_setpoint].dup
    raise 'heating_setpoint.length != cooling_setpoint.length' unless heating_setpoint.length == cooling_setpoint.length

    total_indices = heating_setpoint.length
    # Initialize peak_period and pre_peak_period arrays with zeros
    peak_period = Array.new(total_indices, 0)
    pre_peak_period = Array.new(total_indices, 0)

    total_indices.times do |index|
      offset_times = _get_peak_times(index, flexibility_inputs)
      day_type = _get_day_type(index)
      index_in_day = index % (24 * @num_timesteps_per_hour)

      if offset_times.pre_peak_start_index <= index_in_day && index_in_day < offset_times.peak_start_index
        # Preheating/Precooling period
        pre_peak_period[index] = 1
        if day_type == 'preheating'
          heating_setpoint[index] += flexibility_inputs.pre_peak_offset
          heating_setpoint[index] = _clip_setpoints(heating_setpoint[index])
          # If the offset causes the set points to be inverted, adjust the cooling setpoint to correct it
          # This can happen during pre-heating if originally the cooling and heating setpoints were the same
          cooling_setpoint[index] = heating_setpoint[index] if heating_setpoint[index] > cooling_setpoint[index]
        elsif day_type == 'precooling'
          cooling_setpoint[index] -= flexibility_inputs.pre_peak_offset
          cooling_setpoint[index] = _clip_setpoints(cooling_setpoint[index])
          # If the offset causes the set points to be inverted, adjust the heating setpoint to correct it
          # This can happen during precooling if originally the cooling and heating setpoints were the same
          heating_setpoint[index] = cooling_setpoint[index] if heating_setpoint[index] > cooling_setpoint[index]
        end
      elsif offset_times.peak_start_index <= index_in_day && index_in_day < offset_times.peak_end_index
        # Peak period
        peak_period[index] = 1
        heating_setpoint[index] -= flexibility_inputs.peak_offset
        cooling_setpoint[index] += flexibility_inputs.peak_offset
      end
    end

    {
      heating_setpoint: heating_setpoint,
      cooling_setpoint: cooling_setpoint,
      peak_period: peak_period,
      pre_peak_period: pre_peak_period
    }
  end

  # Clips the setpoint temperature to be within a reasonable range (55-82°F)
  # @param setpoint [Float] The temperature setpoint to be clipped
  # @return [Float] The clipped temperature setpoint
  def _clip_setpoints(setpoint)
    return 82 if setpoint > 82
    return 55 if setpoint < 55

    setpoint
  end

  # Logs the flexibility inputs to the runner for debugging and information purposes
  # @param inputs [FlexibilityInputs] The flexibility inputs struct containing parameters
  # @return [nil]
  def log_inputs(inputs)
    return unless @runner

    @runner.registerInfo('Modifying setpoints ...')
    @runner.registerInfo("pre_peak_duration_steps=#{inputs.pre_peak_duration_steps}")
    @runner.registerInfo("random_shift_steps=#{inputs.random_shift_steps}")
    @runner.registerInfo("pre_peak_offset=#{inputs.pre_peak_offset}")
    @runner.registerInfo("peak_offset=#{inputs.peak_offset}")
  end
end
