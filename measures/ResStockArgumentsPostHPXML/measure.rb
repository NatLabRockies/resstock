# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# Load required dependencies for HVAC flexibility processing
require_relative 'resources/hvac_flexibility/detailed_schedule_generator'
require_relative 'resources/hvac_flexibility/setpoint_modifier'
require_relative 'resources/ev_flexibility/ev_schedule_modifier'

# OpenStudio Measure class to process ResStock arguments after HPXML generation
class ResStockArgumentsPostHPXML < OpenStudio::Measure::ModelMeasure
  # Define human readable name
  def name
    'ResStock Arguments Post-HPXML'
  end

  # Brief human readable description of the measure
  def description
    'Measure that post-processes the output of the BuildResidentialHPXML and BuildResidentialScheduleFile measures.'
  end

  # Detailed human readable description of modeling approach
  def modeler_description
    'Passes in all ResStockArgumentsPostHPXML arguments from the options lookup, processes them, and then modifies output of other measures.'
  end

  # Define user input arguments
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', false)
    arg.setDisplayName('HPXML File Path')
    arg.setDescription('Absolute/relative path of the HPXML file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('hvac_flex_peak_offset', false)
    arg.setDisplayName('HVAC Load Flexibility: Peak Offset (deg F)')
    arg.setDescription('Offset of the peak period in degrees Fahrenheit.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('hvac_flex_pre_peak_duration_hours', false)
    arg.setDisplayName('HVAC Load Flexibility: Pre-Peak Duration (hours)')
    arg.setDescription('Duration of the pre-peak period in hours.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('hvac_flex_pre_peak_offset', false)
    arg.setDisplayName('HVAC Load Flexibility: Pre-Peak Offset (deg F)')
    arg.setDescription('Offset of the pre-peak period in degrees Fahrenheit.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('flex_random_shift_minutes', false)
    arg.setDisplayName('Load Flexibility: Random Shift (minutes)')
    arg.setDescription('Number of minutes to randomly shift the peak period. If minutes is less than timestep, it will be assumed to be 0.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('ev_flex_enabled', false)
    arg.setDisplayName('EV Flexibility Enabled')
    arg.setDescription('Whether to enable EV flexibility.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('building_id', false)
    arg.setDisplayName('Building Unit ID')
    arg.setDescription('The building unit number (between 1 and the number of samples).')
    args << arg

    args
  end

  # Run the measure
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    @runner = runner
    # Use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    # Parse user arguments and assign to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)
    if skip_post_hpxml?(args)
      runner.registerInfo('Skipping ResStockArgumentsPostHPXML')
      return true
    end
    @args = args

    @hpxml_path = args[:hpxml_path]
    @hpxml_path = File.expand_path(@hpxml_path) unless (Pathname.new @hpxml_path).absolute?
    raise "'#{@hpxml_path}' does not exist or is not an .xml file." unless File.exist?(@hpxml_path) && @hpxml_path.downcase.end_with?('.xml')

    output_csv_path = File.dirname(@hpxml_path)

    # Load HPXML
    @hpxml = HPXML.new(hpxml_path: @hpxml_path)
    @prng = Random.new(args[:building_id].to_i)
    @minutes_per_step = @hpxml.header.timestep
    max_random_shift_steps = (args[:flex_random_shift_minutes] / @minutes_per_step).to_i
    @random_shift_steps = @prng.rand(-max_random_shift_steps..max_random_shift_steps)

    # Process each building
    @hpxml.buildings.each_with_index do |hpxml_bldg, index|
      if hpxml_bldg.hvac_controls.to_a.length != 0 && !skip_hvac_flexibility?(args)
        hvac_schedule = create_hvac_schedule(index)
        modified_schedule = modify_hvac_schedule(hpxml_bldg, hvac_schedule)
        write_schedule(modified_schedule, hpxml_bldg, index, output_csv_path)
      end
      next unless !skip_ev_flexibility?(args)

      ev_schedule = get_ev_schedule(hpxml_bldg)
      next if ev_schedule.nil?

      modified_ev_schedule = modify_ev_schedule(hpxml_bldg, ev_schedule)
      write_schedule(modified_ev_schedule, hpxml_bldg, index, output_csv_path)
    end

    # Write out the modified hpxml
    XMLHelper.write_file(@hpxml.to_doc(), @hpxml_path)
    runner.registerInfo("Wrote file: #{@hpxml_path} with modified schedules.")
    return true
  end

  # Determines if the post-processing step for HPXML should be skipped
  def skip_post_hpxml?(args)
    return skip_hvac_flexibility?(args) && skip_ev_flexibility?(args)
  end

  # Determines if HVAC flexibility modifications should be skipped
  # Skips if both peak offset and pre-peak duration are set to 0
  def skip_hvac_flexibility?(args)
    return true if args[:hvac_flex_peak_offset] == 0 && args[:hvac_flex_pre_peak_duration_hours] == 0
  end

  def skip_ev_flexibility?(args)
    return true if !args[:ev_flex_enabled]
  end

  def get_ev_schedule(hpxml_bldg)
    schedule_file = get_existing_schedule_filepath(hpxml_bldg)
    return if schedule_file.nil?

    schedule = CSV.read(schedule_file, headers: true)
    ev_schedule = {}
    ev_column = 'electric_vehicle'
    return unless schedule.headers.include?(ev_column)

    ev_schedule[ev_column.to_sym] = schedule[ev_column].map(&:to_f)
    return ev_schedule
  end

  # Generates the HVAC schedule for a given building index
  def create_hvac_schedule(building_index)
    generator = HVACScheduleGenerator.new(@hpxml, @hpxml_path, @runner, building_index)
    return generator.get_heating_cooling_setpoint_schedule
  end

  # Retrieves an appropriate schedule modifier for a given building
  def get_schedule_modifier(hpxml_bldg, modifier_class)
    # Ensure the provided class is a subclass of ScheduleModifier
    raise ArgumentError, "#{modifier_class} must be a subclass of ScheduleModifier" unless modifier_class < ScheduleModifier

    state = hpxml_bldg.state_code
    sim_year = @hpxml.header.sim_calendar_year
    epw_path = Location.get_epw_path(hpxml_bldg, @hpxml_path)
    weather = WeatherFile.new(epw_path: epw_path, runner: @runner)

    # Get daylight saving time information
    dst_info = DSTInfo.new(dst_begin_month: hpxml_bldg.dst_begin_month,
                           dst_begin_day: hpxml_bldg.dst_begin_day,
                           dst_end_month: hpxml_bldg.dst_end_month,
                           dst_end_day: hpxml_bldg.dst_end_day)

    # Create and return the modifier instance
    return modifier_class.new(state: state,
                              sim_year: sim_year,
                              weather: weather,
                              epw_path: epw_path,
                              minutes_per_step: @minutes_per_step,
                              runner: @runner,
                              dst_info: dst_info)
  end

  # Modifies the HVAC schedule based on flexibility inputs
  def modify_hvac_schedule(hpxml_bldg, schedule)
    hvac_schedule_modifier = get_schedule_modifier(hpxml_bldg, HVACScheduleModifier)

    # Define flexibility inputs
    hvac_flexibility_inputs = FlexibilityInputs.new(
      peak_offset: @args[:hvac_flex_peak_offset],
      pre_peak_duration_steps: (@args[:hvac_flex_pre_peak_duration_hours] * 60 / @minutes_per_step).to_i,
      pre_peak_offset: @args[:hvac_flex_pre_peak_offset],
      random_shift_steps: @random_shift_steps
    )

    # Apply modifications to the schedule
    return hvac_schedule_modifier.modify_shedule(schedule, hvac_flexibility_inputs)
  end

  def modify_ev_schedule(hpxml_bldg, schedule)
    ev_schedule_modifier = get_schedule_modifier(hpxml_bldg, EVScheduleModifier)
    ev_flexibility_inputs = FlexibilityInputs.new(
      peak_offset: 0,
      # Use hvac_flex_pre_peak_duration_hours so that shift/shed is the same as HVAC
      pre_peak_duration_steps: (@args[:hvac_flex_pre_peak_duration_hours] * 60 / @minutes_per_step).to_i,
      pre_peak_offset: 0,
      random_shift_steps: @random_shift_steps
    )
    return ev_schedule_modifier.modify_schedule(schedule, ev_flexibility_inputs)
  end

  # Writes the HVAC schedule to a CSV file
  def write_schedule(schedule, hpxml_bldg, index, output_csv_path)
    schedule_file = get_existing_schedule_filepath(hpxml_bldg)

    if schedule_file.nil?
      # Create a new schedule file if one does not exist
      schedule_file = File.join(output_csv_path, "schedule_#{index}.csv")
      CSV.open(schedule_file, 'w') do |csv|
        headers = schedule.keys.map(&:to_s)
        csv << headers
        row_count = schedule.values.first.length
        (0...row_count).each do |i|
          row = headers.map { |h| schedule[h.to_sym][i] }
          csv << row
        end
      end
      hpxml_bldg.header.schedules_filepaths << schedule_file
    else
      # Process existing schedule file and update values
      data = CSV.read(schedule_file, headers: true)
      headers = data.headers

      schedule.each do |column_name, values|
        string_column_name = column_name.to_s
        column_index = headers.index { |h| h.to_s == string_column_name }

        if column_index
          data.each_with_index do |row, i|
            row[column_index] = values[i]
          end
        else
          headers << string_column_name
          data.each_with_index do |row, i|
            row[string_column_name] = values[i]
          end
        end
      end

      # Write the updated schedule back to the CSV file
      CSV.open(schedule_file, 'w') do |csv|
        csv << headers
        data.each { |row| csv << row }
      end
    end

    return schedule_file
  end

  # Retrieves the existing schedule file path from the HPXML file
  def get_existing_schedule_filepath(hpxml_bldg)
    schedule_file = hpxml_bldg.header.schedules_filepaths.first
    return if schedule_file.nil?

    # Ensure the path is absolute
    if !Pathname.new(schedule_file).absolute?
      schedule_file = File.join(File.dirname(@hpxml_path), schedule_file)
    end
    return schedule_file
  end
end

# register the measure to be used by the application
ResStockArgumentsPostHPXML.new.registerWithApplication
