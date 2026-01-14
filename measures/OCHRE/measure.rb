# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require 'json'
require 'csv'

# Load HPXML resources
resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources'))
Dir["#{resources_path}/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end

# start the measure
class OCHRE < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'OCHRE Simulator'
  end

  # human readable description
  def description
    return 'Runs OCHRE (Object-oriented Controllable High-resolution Residential Energy Model) simulation as an alternative to HPXMLtoOpenStudio/EnergyPlus.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure replaces the HPXMLtoOpenStudio + EnergyPlus workflow with OCHRE simulation. It takes an HPXML file as input, runs OCHRE via command line, and converts the outputs to match the expected format for downstream reporting measures.'
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', true)
    arg.setDisplayName('HPXML File Path')
    arg.setDescription('Absolute/relative path of the HPXML file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('output_dir', true)
    arg.setDisplayName('Output Directory')
    arg.setDescription('Absolute/relative path for outputs.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('time_res_minutes', false)
    arg.setDisplayName('Time Resolution (minutes)')
    arg.setDescription('Time resolution for OCHRE simulation in minutes.')
    arg.setDefaultValue(60)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('duration_days', false)
    arg.setDisplayName('Duration (days)')
    arg.setDescription('Simulation duration in days.')
    arg.setDefaultValue(365)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('start_year', false)
    arg.setDisplayName('Simulation Start Year')
    arg.setDescription('Year to start the OCHRE simulation.')
    arg.setDefaultValue(2018)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('start_month', false)
    arg.setDisplayName('Simulation Start Month')
    arg.setDescription('Month to start the OCHRE simulation (1-12).')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('start_day', false)
    arg.setDisplayName('Simulation Start Day')
    arg.setDescription('Day to start the OCHRE simulation (1-31).')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('debug', false)
    arg.setDisplayName('Debug Mode')
    arg.setDescription('If true, generates additional debug output.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('export_res', false)
    arg.setDisplayName('Export Resolution (minutes)')
    arg.setDescription('Export interval in minutes (exports results periodically to reduce memory). Recommended: 43200 (30 days) for 1-minute resolution, 86400 (60 days) for 5-minute resolution. Leave blank to disable periodic export.')
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
    args = Hash[args.map { |k, v| [k.to_sym, v] }]

    # Validate required inputs
    hpxml_path = args[:hpxml_path]
    if hpxml_path.nil? || hpxml_path.empty?
      runner.registerError('HPXML file path is required.')
      return false
    end

    output_dir = args[:output_dir]
    if output_dir.nil? || output_dir.empty?
      output_dir = '.'
    end

    # Create output directory if it doesn't exist
    unless Dir.exist?(output_dir)
      Dir.mkdir(output_dir)
    end

    # Get absolute paths
    hpxml_path = File.absolute_path(hpxml_path) if File.exist?(hpxml_path)
    output_dir = File.absolute_path(output_dir)

    # Check if HPXML file exists
    unless File.exist?(hpxml_path)
      runner.registerError("HPXML file not found: #{hpxml_path}")
      return false
    end

    runner.registerInfo("HPXML file: #{hpxml_path}")
    runner.registerInfo("Output directory: #{output_dir}")

    # Load HPXML to extract weather and schedule files
    begin
      hpxml = HPXML.new(hpxml_path: hpxml_path)
    rescue => e
      runner.registerError("Failed to load HPXML file: #{e.message}")
      return false
    end

    # Extract schedule file
    schedule_file = nil
    if hpxml.buildings.size > 0 && !hpxml.buildings[0].header.schedules_filepaths.nil? && !hpxml.buildings[0].header.schedules_filepaths.empty?
      schedule_file = hpxml.buildings[0].header.schedules_filepaths[0]
      runner.registerInfo("Found schedule file in HPXML: #{schedule_file}")
    else
      runner.registerWarning('Schedule file path not found in HPXML.')
    end

    # Build OCHRE command line
    time_res_minutes = args[:time_res_minutes] || 10
    duration_days = args[:duration_days] || 365
    start_year = args[:start_year] || 2018
    start_month = args[:start_month] || 1
    start_day = args[:start_day] || 1
    export_res_minutes = args[:export_res]

    # get weather file path
    hpxml_bldg = hpxml.buildings[0]
    weather_file = Location.get_epw_path(hpxml_bldg, hpxml_path)

    # Build OCHRE CLI command
    ochre_cmd = build_ochre_command(hpxml_path, output_dir,
                                    time_res_minutes, duration_days,
                                    schedule_file, weather_file,
                                    start_year, start_month, start_day,
                                    export_res_minutes)

    runner.registerInfo("Running OCHRE simulation: #{ochre_cmd}")

    begin
      output = `#{ochre_cmd} 2>&1`
      exit_status = $?.exitstatus

      if args[:debug]
        runner.registerInfo("OCHRE output:\n#{output}")
      end

      if exit_status != 0
        runner.registerError("OCHRE simulation failed with exit code #{exit_status}")
        runner.registerError("Output:\n#{output}")
        return false
      end

      runner.registerInfo('OCHRE simulation completed successfully')
    rescue => e
      runner.registerError("Failed to run OCHRE: #{e.message}")
      return false
    end

    runner.registerFinalCondition('OCHRE simulation completed successfully')

    return true
  end

  private

  # Build OCHRE command to run via CLI
  def build_ochre_command(hpxml_path, output_dir, time_res_minutes, duration_days, schedule_file, weather_file, start_year, start_month, start_day, export_res_minutes = nil)
    # Get directory and filename for HPXML
    hpxml_dir = File.dirname(hpxml_path)
    hpxml_name = File.basename(hpxml_path)

    # Escape paths for shell
    hpxml_dir_safe = hpxml_dir.gsub("'", "\\\\'")
    hpxml_name_safe = hpxml_name.gsub("'", "\\\\'")
    output_dir_safe = output_dir.gsub("'", "\\\\'")

    # Build the ochre command
    # Usage: ochre single [OPTIONS] INPUT_PATH
    # INPUT_PATH is the directory containing the HPXML file
    cmd = "/Users/radhikar/Documents/buildstock2025/res_ochre/OCHRE/.venv/bin/ochre single '#{hpxml_dir_safe}'"
    cmd += " --hpxml_file '#{hpxml_name_safe}'"
    cmd += " --output_path '#{output_dir_safe}'"
    cmd += " --time_res #{time_res_minutes}"
    cmd += " --duration #{duration_days}"
    cmd += " --start_year #{start_year} --start_month #{start_month} --start_day #{start_day}"
    cmd += ' --verbosity=9'

    if schedule_file && !schedule_file.empty?
      schedule_file_safe = schedule_file.gsub("'", "\\\\'")
      cmd += " --hpxml_schedule_file '#{schedule_file_safe}'"
    end
    cmd += " --weather_file_or_path '#{weather_file}'"

    # Add export_res if specified
    # Convert from minutes to days for the CLI (which expects days)
    if export_res_minutes && export_res_minutes > 0
      cmd += " --export_res #{export_res_minutes}"
    end

    return cmd
  end
end

# register the measure to be used by the application
OCHRE.new.registerWithApplication
