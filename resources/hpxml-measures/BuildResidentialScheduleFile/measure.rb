# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://natlabrockies.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

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
      runner.registerError("'#{hpxml_path}' does not exist or is not an .xml file.")
      return false
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

    hpxml = HPXML.new(hpxml_path: hpxml_path)

    create_backup = false
    if hpxml_path == hpxml_output_path
      # Check if HPXML data will be dropped when we write the new HPXML file.
      # This can happen if the original HPXML file was not written by OS-HPXML.
      # If this will occur, we will save a backup of the original HPXML file.
      orig_hpxml_contents = hpxml.contents.delete("\r").gsub(" dataSource='software'", '')
      new_hpxml_contents = XMLHelper.finalize_doc_string(hpxml.to_doc()).gsub(" dataSource='software'", '')
      if orig_hpxml_contents != new_hpxml_contents
        create_backup = true
      end
    end

    # Since we modify the HPXML object (apply defaults), use a copy of the
    # original HPXML object so that the HPXML object we write does not include
    # any such modifications.
    orig_hpxml = Marshal.load(Marshal.dump(hpxml))

    hpxml.buildings.each_with_index do |hpxml_bldg, i|
      next if hpxml.buildings.size > 1 && args[:building_id] != 'ALL' && args[:building_id] != hpxml_bldg.building_id

      # Only need to do this once
      if epw_path.nil?
        epw_path = Location.get_epw_path(hpxml_bldg, hpxml_path)
        weather = WeatherFile.new(epw_path: epw_path, runner: runner)
      end

      # deterministically vary schedules across building units
      args[:random_seed] *= (i + 1)

      # exit if number of occupants is zero
      if hpxml_bldg.building_occupancy.number_of_residents == 0
        runner.registerInfo("#{hpxml_bldg.building_id}: Number of occupants set to zero; skipping generation of stochastic schedules.")
        next
      end

      # output csv path
      args[:output_csv_path] = "#{output_csv_basename}.csv"
      args[:output_csv_path] = "#{output_csv_basename}_#{i + 1}.csv" if i > 0 && args[:building_id] == 'ALL'

      # create the schedules
      success = create_schedules(runner, hpxml, hpxml_bldg, weather, args)
      return false unless success

      update_hpxml_building(orig_hpxml.buildings[i], args)
    end

    if create_backup
      # Create a backup of the original HPXML file
      runner.registerWarning('HPXML Output File Path is same as HPXML File Path, creating backup.')
      File.rename(hpxml_path, hpxml_path.gsub('.xml', '_bak.xml'))
    end

    XMLHelper.write_file(orig_hpxml.to_doc(), hpxml_output_path)

    return true
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

    if !args[:schedules_column_names].nil?
      args[:column_names] = args[:schedules_column_names].split(',').map(&:strip)
    else
      args[:column_names] = ScheduleGenerator.export_columns
    end

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

  # Updates the HPXML Building (that will be written to file) to include the new
  # schedule filepath and remove simple schedules.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def update_hpxml_building(hpxml_bldg, args)
    # Update the schedules path
    if !hpxml_bldg.header.schedules_filepaths.include?(args[:output_csv_path])
      hpxml_bldg.header.schedules_filepaths << args[:output_csv_path]
    end

    # Remove simple schedules (so that we don't have both detailed/stochastic schedules
    # and simple schedules referenced by the HPXML).
    args[:column_names].each do |column_name|
      case column_name
      when SchedulesFile::Columns[:Occupants].name
        hpxml_bldg.building_occupancy.weekday_fractions = nil
        hpxml_bldg.building_occupancy.weekend_fractions = nil
        hpxml_bldg.building_occupancy.monthly_multipliers = nil
      when SchedulesFile::Columns[:LightingInterior].name
        hpxml_bldg.lighting.interior_weekday_fractions = nil
        hpxml_bldg.lighting.interior_weekend_fractions = nil
        hpxml_bldg.lighting.interior_monthly_multipliers = nil
      when SchedulesFile::Columns[:LightingGarage].name
        hpxml_bldg.lighting.garage_weekday_fractions = nil
        hpxml_bldg.lighting.garage_weekend_fractions = nil
        hpxml_bldg.lighting.garage_monthly_multipliers = nil
      when SchedulesFile::Columns[:CookingRange].name
        hpxml_bldg.cooking_ranges.each do |cooking_range|
          cooking_range.weekday_fractions = nil
          cooking_range.weekend_fractions = nil
          cooking_range.monthly_multipliers = nil
        end
      when SchedulesFile::Columns[:Dishwasher].name,
           SchedulesFile::Columns[:HotWaterDishwasher].name
        hpxml_bldg.dishwashers.each do |dishwasher|
          dishwasher.weekday_fractions = nil
          dishwasher.weekend_fractions = nil
          dishwasher.monthly_multipliers = nil
        end
      when SchedulesFile::Columns[:ClothesWasher].name,
           SchedulesFile::Columns[:HotWaterClothesWasher].name
        hpxml_bldg.clothes_washers.each do |clothes_washer|
          clothes_washer.weekday_fractions = nil
          clothes_washer.weekend_fractions = nil
          clothes_washer.monthly_multipliers = nil
        end
      when SchedulesFile::Columns[:ClothesDryer].name
        hpxml_bldg.clothes_dryers.each do |clothes_dryer|
          clothes_dryer.weekday_fractions = nil
          clothes_dryer.weekend_fractions = nil
          clothes_dryer.monthly_multipliers = nil
        end
      when SchedulesFile::Columns[:CeilingFan].name
        hpxml_bldg.ceiling_fans.each do |ceiling_fan|
          ceiling_fan.weekday_fractions = nil
          ceiling_fan.weekend_fractions = nil
          ceiling_fan.monthly_multipliers = nil
        end
      when SchedulesFile::Columns[:HotWaterFixtures].name
        hpxml_bldg.water_heating.water_fixtures_weekday_fractions = nil
        hpxml_bldg.water_heating.water_fixtures_weekend_fractions = nil
        hpxml_bldg.water_heating.water_fixtures_monthly_multipliers = nil
      when SchedulesFile::Columns[:PlugLoadsOther].name
        hpxml_bldg.plug_loads.select { |pl| pl.plug_load_type == HPXML::PlugLoadTypeOther }.each do |plug_load|
          plug_load.weekday_fractions = nil
          plug_load.weekend_fractions = nil
          plug_load.monthly_multipliers = nil
        end
      when SchedulesFile::Columns[:PlugLoadsTV].name
        hpxml_bldg.plug_loads.select { |pl| pl.plug_load_type == HPXML::PlugLoadTypeTelevision }.each do |plug_load|
          plug_load.weekday_fractions = nil
          plug_load.weekend_fractions = nil
          plug_load.monthly_multipliers = nil
        end
      when SchedulesFile::Columns[:ElectricVehicle].name
        hpxml_bldg.vehicles.select { |v| v.vehicle_type == HPXML::VehicleTypeBEV }.each do |vehicle|
          vehicle.ev_weekday_fractions = nil
          vehicle.ev_weekend_fractions = nil
          vehicle.ev_monthly_multipliers = nil
        end
      else
        fail "Unexpected column name: #{column_name}"
      end
    end
  end
end

# register the measure to be used by the application
BuildResidentialScheduleFile.new.registerWithApplication
