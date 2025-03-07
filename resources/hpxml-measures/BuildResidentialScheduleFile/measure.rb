# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require 'pathname'
require 'oga'
Dir["#{File.dirname(__FILE__)}/resources/*.rb"].each do |resource_file|
  require resource_file
end
Dir["#{File.dirname(__FILE__)}/../HPXMLtoOpenStudio/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end

# start the measure
class BuildResidentialScheduleFile < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Schedule File Builder'
  end

  # human readable description
  def description
    return 'Builds a residential stochastic occupancy schedule file.'
  end

  # human readable description of modeling approach
  def modeler_description
    return "Generates a CSV of schedules at the specified file path, and inserts the CSV schedule file path into the output HPXML file (or overwrites it if one already exists). Stochastic schedules are generated using time-inhomogeneous Markov chains derived from American Time Use Survey data, and supplemented with sampling duration and power level from NEEA RBSA data as well as DHW draw duration and flow rate from Aquacraft/AWWA data. See <a href='https://www.sciencedirect.com/science/article/pii/S0306261922011540'>Stochastic simulation of occupant-driven energy use in a bottom-up residential building stock model</a> for a more complete description of the methodology."
  end

  # Define the arguments that the user will input.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [OpenStudio::Measure::OSArgumentVector] an OpenStudio::Measure::OSArgumentVector object
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', true)
    arg.setDisplayName('HPXML File Path')
    arg.setDescription('Absolute/relative path of the HPXML file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_column_names', false)
    arg.setDisplayName('Schedules: Column Names')
    arg.setDescription("A comma-separated list of the column names to generate. If not provided, defaults to all columns. Possible column names are: #{ScheduleGenerator.export_columns.join(', ')}.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('schedules_random_seed', false)
    arg.setDisplayName('Schedules: Random Seed')
    arg.setUnits('#')
    arg.setDescription('This numeric field is the seed for the random number generator.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('output_csv_path', true)
    arg.setDisplayName('Schedules: Output CSV Path')
    arg.setDescription('Absolute/relative path of the CSV file containing occupancy schedules. Relative paths are relative to the HPXML output path.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_output_path', true)
    arg.setDisplayName('HPXML Output File Path')
    arg.setDescription('Absolute/relative output path of the HPXML file. This HPXML file will include the output CSV path.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('append_output', false)
    arg.setDisplayName('Append Output?')
    arg.setDescription('If true and the output CSV file already exists, appends columns to the file rather than overwriting it. The existing output CSV file must have the same number of rows (i.e., timeseries frequency) as the new columns being appended.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('debug', false)
    arg.setDisplayName('Debug Mode?')
    arg.setDescription('If true, writes extra column(s) for informational purposes.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('building_id', false)
    arg.setDisplayName('BuildingID')
    arg.setDescription("The ID of the HPXML Building. Only required if there are multiple Building elements in the HPXML file. Use 'ALL' to apply schedules to all the HPXML Buildings (dwelling units) of a multifamily building.")
    args << arg

    return args
  end

  # Define what happens when the measure is run.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param user_arguments [OpenStudio::Measure::OSArgumentMap] OpenStudio measure arguments
  # @return [Boolean] true if successful
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)

    hpxml_path = args[:hpxml_path]
    unless (Pathname.new hpxml_path).absolute?
      hpxml_path = File.expand_path(hpxml_path)
    end
    unless File.exist?(hpxml_path) && hpxml_path.downcase.end_with?('.xml')
      fail "'#{hpxml_path}' does not exist or is not an .xml file."
    end

    hpxml_output_path = args[:hpxml_output_path]
    unless (Pathname.new hpxml_output_path).absolute?
      hpxml_output_path = File.expand_path(hpxml_output_path)
    end
    args[:hpxml_output_path] = hpxml_output_path

    # random seed
    if not args[:schedules_random_seed].nil?
      args[:random_seed] = args[:schedules_random_seed]
      runner.registerInfo("Retrieved the schedules random seed; setting it to #{args[:random_seed]}.")
    else
      args[:random_seed] = 1
      runner.registerInfo('Unable to retrieve the schedules random seed; setting it to 1.')
    end

    epw_path, weather = nil, nil

    output_csv_basename, _ = args[:output_csv_path].split('.csv')

    doc = XMLHelper.parse_file(hpxml_path)
    hpxml_doc = XMLHelper.get_element(doc, '/HPXML')
    doc_buildings = XMLHelper.get_elements(hpxml_doc, 'Building')
    doc_buildings.each_with_index do |building, i|
      doc_building_id = XMLHelper.get_attribute_value(XMLHelper.get_element(building, 'BuildingID'), 'id')

      next if doc_buildings.size > 1 && args[:building_id] != 'ALL' && args[:building_id] != doc_building_id

      hpxml = HPXML.new(hpxml_path: hpxml_path, building_id: doc_building_id)
      hpxml_bldg = hpxml.buildings[0]

      if epw_path.nil?
        epw_path = Location.get_epw_path(hpxml_bldg, hpxml_path)
        weather = WeatherFile.new(epw_path: epw_path, runner: runner, hpxml: hpxml)
      end
      # deterministically vary schedules across building units
      args[:random_seed] *= (i + 1)

      # exit if number of occupants is zero
      if hpxml_bldg.building_occupancy.number_of_residents == 0
        runner.registerInfo("#{doc_building_id}: Number of occupants set to zero; skipping generation of stochastic schedules.")
        next
      end

      # output csv path
      args[:output_csv_path] = "#{output_csv_basename}.csv"
      args[:output_csv_path] = "#{output_csv_basename}_#{i + 1}.csv" if i > 0 && args[:building_id] == 'ALL'

      # create the schedules
      success = create_schedules(runner, hpxml, hpxml_bldg, weather, args)
      return false if not success

      # modify the hpxml with the schedules path
      extension = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'extension'])
      schedules_filepaths = XMLHelper.get_values(extension, 'SchedulesFilePath', :string)
      if !schedules_filepaths.include?(args[:output_csv_path])
        XMLHelper.add_element(extension, 'SchedulesFilePath', args[:output_csv_path], :string)
      end
      write_modified_hpxml(runner, doc, hpxml_path, hpxml_output_path, schedules_filepaths, args)
    end

    return true
  end

  # Write out the HPXML file with the output CSV path containing occupancy schedules.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param doc [Oga::XML::Document] Oga XML Document object
  # @param hpxml_path [String] Path to the HPXML file
  # @param hpxml_output_path [String] Path to the output HPXML file
  # @param schedules_filepaths [Array<String>] array of SchedulesFilePath strings in the input HPXML file
  # @param args [Hash] Map of :argument_name => value
  def write_modified_hpxml(runner, doc, hpxml_path, hpxml_output_path, schedules_filepaths, args)
    # write out the modified hpxml
    if (hpxml_path != hpxml_output_path) || !schedules_filepaths.include?(args[:output_csv_path])
      XMLHelper.write_file(doc, hpxml_output_path)
      runner.registerInfo("Wrote file: #{hpxml_output_path}")
    end
  end

  # Create and export the occupancy schedules.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml [HPXML] HPXML object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param args [Hash] Map of :argument_name => value
  # @return [Boolean] true if successful
  def create_schedules(runner, hpxml, hpxml_bldg, weather, args)
    info_msgs = []

    Defaults.apply(runner, hpxml, hpxml_bldg, weather)

    get_simulation_parameters(hpxml, args)
    get_generator_inputs(hpxml_bldg, args)

    args[:resources_path] = File.join(File.dirname(__FILE__), 'resources')
    schedule_generator = ScheduleGenerator.new(runner: runner, hpxml_bldg: hpxml_bldg, **args)

    success = schedule_generator.create(args: args, weather: weather)
    return false if not success

    output_csv_path = args[:output_csv_path]
    unless (Pathname.new output_csv_path).absolute?
      output_csv_path = File.expand_path(File.join(File.dirname(args[:hpxml_output_path]), output_csv_path))
    end

    success = schedule_generator.export(schedules_path: output_csv_path)
    return false if not success

    info_msgs << "SimYear=#{args[:sim_year]}"
    info_msgs << "MinutesPerStep=#{args[:minutes_per_step]}"
    info_msgs << "State=#{args[:state]}"
    info_msgs << "RandomSeed=#{args[:random_seed]}" if !args[:schedules_random_seed].nil?
    info_msgs << "GeometryNumOccupants=#{args[:geometry_num_occupants]}"
    info_msgs << "TimeZoneUTCOffset=#{args[:time_zone_utc_offset]}"
    info_msgs << "Latitude=#{args[:latitude]}"
    info_msgs << "Longitude=#{args[:longitude]}"
    info_msgs << "ColumnNames=#{args[:column_names]}" if !args[:schedules_column_names].nil?

    runner.registerInfo("Created stochastic schedule with #{info_msgs.join(', ')}")

    return true
  end

  # Get simulation parameters that are required for the stochastic schedule generator.
  #
  # @param hpxml [HPXML] HPXML object
  # @param args [Hash] Map of :argument_name => value
  def get_simulation_parameters(hpxml, args)
    args[:minutes_per_step] = 60
    if !hpxml.header.timestep.nil?
      args[:minutes_per_step] = hpxml.header.timestep
    end
    args[:steps_in_day] = 24 * 60 / args[:minutes_per_step]

    args[:sim_year] = hpxml.header.sim_calendar_year
    args[:sim_start_day] = DateTime.new(args[:sim_year], 1, 1)
    args[:total_days_in_year] = Calendar.num_days_in_year(hpxml.header.sim_calendar_year)
  end

  # Get generator inputs that are required for the stochastic schedule generator.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  def get_generator_inputs(hpxml_bldg, args)
    if Constants::StateCodesMap.keys.include?(hpxml_bldg.state_code)
      args[:state] = hpxml_bldg.state_code
    else
      # Unhandled state code, fallback to CO
      args[:state] = 'CO'
    end
    args[:column_names] = args[:schedules_column_names].split(',').map(&:strip) if !args[:schedules_column_names].nil?

    if hpxml_bldg.building_occupancy.number_of_residents.nil?
      args[:geometry_num_occupants] = Geometry.get_occupancy_default_num(hpxml_bldg.building_construction.number_of_bedrooms)
    else
      args[:geometry_num_occupants] = hpxml_bldg.building_occupancy.number_of_residents
    end
    args[:geometry_num_occupants] = Float(Integer(args[:geometry_num_occupants]))

    args[:time_zone_utc_offset] = hpxml_bldg.time_zone_utc_offset
    args[:latitude] = hpxml_bldg.latitude
    args[:longitude] = hpxml_bldg.longitude
  end
end

# register the measure to be used by the application
BuildResidentialScheduleFile.new.registerWithApplication
