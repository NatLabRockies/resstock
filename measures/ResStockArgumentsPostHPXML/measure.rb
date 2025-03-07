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

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('loadflex_peak_offset', false)
    arg.setDisplayName('Load Flexibility: Peak Offset (deg F)')
    arg.setDescription('Offset of the peak period in degrees Fahrenheit.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('loadflex_pre_peak_duration_hours', false)
    arg.setDisplayName('Load Flexibility: Pre-Peak Duration (hours)')
    arg.setDescription('Duration of the pre-peak period in hours.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('loadflex_pre_peak_offset', false)
    arg.setDisplayName('Load Flexibility: Pre-Peak Offset (deg F)')
    arg.setDescription('Offset of the pre-peak period in degrees Fahrenheit.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('loadflex_random_shift_minutes', false)
    arg.setDisplayName('Load Flexibility: Random Shift (minutes)')
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
    if skip_load_flexibility?(args)
      runner.registerInfo('Skipping ResStockArgumentsPostHPXML since load flexibility inputs are 0.')
      return true
    end

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
      hpmxl_bldg = hpxml.buildings[index]
      if skip_hvac_flexibility?(hpmxl_bldg)
        runner.registerInfo('Skipping hvac flexibility for building #{index + 1} since it has no HVAC controls.')
        next
      end
      schedule = create_schedule(hpxml, hpxml_path, runner, index)
      modified_schedule = modify_schedule(hpxml, index, args, runner, schedule)
      schedules_filepath = write_schedule(modified_schedule, args[:output_csv_path], index)
      update_hpxml_schedule_filepath(building, schedules_filepath)
    end

    # Write out the modified hpxml
    XMLHelper.write_file(doc, hpxml_path)
    runner.registerInfo("Wrote file: #{hpxml_path} with modified schedules.")
    true
  end

  def skip_load_flexibility?(args)
    args[:loadflex_peak_offset] == 0 && args[:loadflex_pre_peak_duration_hours] == 0
  end

  def skip_hvac_flexibility?(hpxml_bldg)
    hpxml_bldg.hvac_controls.to_a.length == 0
  end

  def create_schedule(hpxml, hpxml_path, runner, building_index)
    generator = HVACScheduleGenerator.new(hpxml, hpxml_path, runner, building_index)
    generator.get_heating_cooling_setpoint_schedule
  end

  def modify_schedule(hpxml, building_index, args, runner, schedule)
    minutes_per_step = hpxml.header.timestep
    hpxml_bldg = hpxml.buildings[building_index]
    building_id = (args[:building_id] or 0).to_i
    state = hpxml_bldg.state_code
    sim_year = hpxml.header.sim_calendar_year
    epw_path = Location.get_epw_path(hpxml_bldg, args[:hpxml_path])
    weather = WeatherFile.new(epw_path: epw_path, runner: runner, hpxml: hpxml)
    dst_info = DSTInfo.new(dst_begin_month: hpxml_bldg.dst_begin_month,
                           dst_begin_day: hpxml_bldg.dst_begin_day,
                           dst_end_month: hpxml_bldg.dst_end_month,
                           dst_end_day: hpxml_bldg.dst_end_day)
    schedule_modifier = HVACScheduleModifier.new(state: state,
                                                 sim_year: sim_year,
                                                 weather: weather,
                                                 epw_path: epw_path,
                                                 minutes_per_step: minutes_per_step,
                                                 runner: runner,
                                                 dst_info: dst_info)
    flexibility_inputs = get_flexibility_inputs(args, minutes_per_step, building_id)
    schedule_modifier.modify_setpoints(schedule, flexibility_inputs)
  end

  def get_flexibility_inputs(args, minutes_per_step, building_id)
    srand(building_id)
    max_random_shift_steps = (args[:loadflex_random_shift_minutes] / minutes_per_step).to_i
    random_shift_steps = rand(-max_random_shift_steps..max_random_shift_steps)
    FlexibilityInputs.new(
      peak_offset: args[:loadflex_peak_offset],
      pre_peak_duration_steps: (args[:loadflex_pre_peak_duration_hours] * 60 / minutes_per_step).to_i,
      pre_peak_offset: args[:loadflex_pre_peak_offset],
      random_shift_steps: random_shift_steps
    )
  end

  def write_schedule(schedule, output_csv_path, building_index)
    schedules_filepath = File.join(File.dirname(output_csv_path), "detailed_schedules_#{building_index + 1}.csv")
    CSV.open(schedules_filepath, 'w') do |csv|
      csv << schedule.keys
      schedule.values.transpose.each do |row|
        csv << row.map { |x| '%.3g' % x }
      end
    end
    return schedules_filepath
  end

  def update_hpxml_schedule_filepath(building, new_schedule_filepath)
    building_extension = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'extension'])
    existing_schedules_filepaths = XMLHelper.get_values(building_extension, 'SchedulesFilePath', :string)
    XMLHelper.add_element(building_extension, 'SchedulesFilePath', new_schedule_filepath, :string) unless existing_schedules_filepaths.include?(new_schedule_filepath)
  end
end

# register the measure to be used by the application
ResStockArgumentsPostHPXML.new.registerWithApplication
