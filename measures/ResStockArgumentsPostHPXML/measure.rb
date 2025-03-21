# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require_relative 'resources/hvac_flexibility/detailed_schedule_generator'
require_relative 'resources/hvac_flexibility/setpoint_modifier'

# start the measure
class ResStockArgumentsPostHPXML < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'ResStock Arguments Post-HPXML'
  end

  # human readable description
  def description
    return 'Measure that post-processes the output of the BuildResidentialHPXML and BuildResidentialScheduleFile measures.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Passes in all ResStockArgumentsPostHPXML arguments from the options lookup, processes them, and then modifies output of other measures.'
  end

  # define the arguments that the user will input
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

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('hvac_flex_random_shift_minutes', false)
    arg.setDisplayName('HVAC Load Flexibility: Random Shift (minutes)')
    arg.setDescription('Number of minutes to randomly shift the peak period. If minutes less than timestep, will be assumed to be 0.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('building_id', false)
    arg.setDisplayName('Building Unit ID')
    arg.setDescription('The building unit number (between 1 and the number of samples).')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('output_csv_path', false)
    arg.setDisplayName('Schedules: Output CSV Path')
    arg.setDescription('Absolute/relative path of the csv file containing occupancy schedules. Relative paths are relative to the HPXML output path.')
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)
    if skip_post_hpxml?(args)
      runner.registerInfo('Skipping ResStockArgumentsPostHPXML')
      return true
    end

    @prngs = get_random_number_generators(args[:building_id].to_i)
  
    hpxml_path = args[:hpxml_path]
    unless (Pathname.new hpxml_path).absolute?
      hpxml_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_path))
    end
    unless File.exist?(hpxml_path) && hpxml_path.downcase.end_with?('.xml')
      fail "'#{hpxml_path}' does not exist or is not an .xml file."
    end

    hpxml = HPXML.new(hpxml_path: hpxml_path)

    # Parse the HPXML document
    doc = XMLHelper.parse_file(hpxml_path)
    hpxml_doc = XMLHelper.get_element(doc, '/HPXML')
    doc_buildings = XMLHelper.get_elements(hpxml_doc, 'Building')

    # Process each building
    doc_buildings.each_with_index do |building, index|
      hpxml_bldg = hpxml.buildings[index]
      if hpxml_bldg.hvac_controls.to_a.length == 0
        runner.registerInfo("Skipping hvac flexibility for building #{index + 1} since it has no HVAC controls.")
        next
      end
      hvac_schedule = create_hvac_schedule(hpxml, hpxml_path, runner, index)
      modified_schedule = modify_hvac_schedule(hpxml, index, args, runner, hvac_schedule)
      write_schedule(modified_schedule, building, index)
    end

    # Write out the modified hpxml
    XMLHelper.write_file(doc, hpxml_path)
    runner.registerInfo("Wrote file: #{hpxml_path} with modified schedules.")
    true
  end

  # Creates random number generators for the main program and each end use
  # @param seed [Integer] The seed value for random number generation
  # @return [Hash] Hash containing random number generators for main program and each end use
  def get_random_number_generators(seed)
    generators = {}
    generators[:main] = Random.new(seed)
    seed_generator = Random.new(seed)
    enduse_types = [:hvac]
    enduse_types.each do |key|
      generators[key] = Random.new(seed_generator.rand(2**32))
    end
    generators
  end

  def skip_post_hpxml?(args)
    skip_hvac_flexibility?(args)
  end

  def skip_hvac_flexibility?(args)
    return true if (args[:hvac_flex_peak_offset] == 0 && args[:hvac_flex_pre_peak_duration_hours] == 0)
  end

  def create_hvac_schedule(hpxml, hpxml_path, runner, building_index)
    generator = HVACScheduleGenerator.new(hpxml, hpxml_path, runner, building_index)
    generator.get_heating_cooling_setpoint_schedule
  end


  def get_schedule_modifier(hpxml, building_index, args, runner, modifier_class)
    unless modifier_class < ScheduleModifier
      raise ArgumentError, "#{modifier_class} must be a subclass of ScheduleModifier"
    end
    minutes_per_step = hpxml.header.timestep
    hpxml_bldg = hpxml.buildings[building_index]
    state = hpxml_bldg.state_code
    sim_year = hpxml.header.sim_calendar_year
    epw_path = Location.get_epw_path(hpxml_bldg, args[:hpxml_path])
    weather = WeatherFile.new(epw_path: epw_path, runner: runner)
    dst_info = DSTInfo.new(dst_begin_month: hpxml_bldg.dst_begin_month,
                           dst_begin_day: hpxml_bldg.dst_begin_day,
                           dst_end_month: hpxml_bldg.dst_end_month,
                           dst_end_day: hpxml_bldg.dst_end_day)
    modifier_class.new(state: state,
                       sim_year: sim_year,
                       weather: weather,
                       epw_path: epw_path,
                       minutes_per_step: minutes_per_step,
                       runner: runner,
                       dst_info: dst_info)
  end

  def modify_hvac_schedule(hpxml, building_index, args, runner, schedule)
    hvac_schedule_modifier = get_schedule_modifier(hpxml, building_index, args, runner, HVACScheduleModifier)
    hvac_flexibility_inputs = get_hvac_hvac_flexibility_inputs(args, hpxml)
    hvac_schedule_modifier.modify_shedule(schedule, hvac_flexibility_inputs)
  end

  def get_hvac_hvac_flexibility_inputs(args, hpxml)
    minutes_per_step = hpxml.header.timestep
    max_random_shift_steps = (args[:hvac_flex_random_shift_minutes] / minutes_per_step).to_i
    random_shift_steps = @prngs[:hvac].rand(-max_random_shift_steps..max_random_shift_steps)
    FlexibilityInputs.new(
      peak_offset: args[:hvac_flex_peak_offset],
      pre_peak_duration_steps: (args[:hvac_flex_pre_peak_duration_hours] * 60 / minutes_per_step).to_i,
      pre_peak_offset: args[:hvac_flex_pre_peak_offset],
      random_shift_steps: random_shift_steps
    )
  end

  def write_schedule(schedule, building, index)
    schedule_file = get_existing_schedule_filepath(building)
    if schedule_file.nil?
      # Create a new schedule file
      schedule_file = "schedule_#{index}.csv"
      CSV.open(schedule_file, 'w') do |csv|
        headers = schedule.keys.map(&:to_s)
        csv << headers
        row_count = schedule.values.first.length
        (0...row_count).each do |i|
          row = headers.map { |h| schedule[h.to_sym][i] }
          csv << row
        end
      end
      update_hpxml_schedule_filepath(building, schedule_file)
    else
      # Process existing file
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
      CSV.open(schedule_file, 'w') do |csv|
        csv << headers
        data.each { |row| csv << row }
      end
    end
    return schedule_file
  end

  def get_existing_schedule_filepath(building)
    building_extension = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'extension'])
    existing_schedules_filepaths = XMLHelper.get_values(building_extension, 'SchedulesFilePath', :string)
    existing_schedules_filepaths.first
  end

  def update_hpxml_schedule_filepath(building, new_schedule_filepath)
    building_extension = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'extension'])
    XMLHelper.add_element(building_extension, 'SchedulesFilePath', new_schedule_filepath, :string)
  end
end

# register the measure to be used by the application
ResStockArgumentsPostHPXML.new.registerWithApplication
