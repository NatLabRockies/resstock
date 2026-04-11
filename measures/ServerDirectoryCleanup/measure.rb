# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ServerDirectoryCleanup < OpenStudio::Measure::ReportingMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    'Server Directory Cleanup'
  end

  # human readable description
  def description
    return 'Optionally removes a significant portion of the saved results from each run, helping to alleviate memory problems.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Present a bunch of bool arguments corresponding to EnergyPlus output files. "False" deletes the file, and "True" retains it. Most arguments default to not retaining the file. Only the in.idf and \*schedules.csv are retained by default.'
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_in_osm', true)
    arg.setDisplayName('Retain in.osm')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_in_idf', true)
    arg.setDisplayName('Retain in.idf')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_pre_process_idf', true)
    arg.setDisplayName('Retain pre_process.idf')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_eplusout_audit', true)
    arg.setDisplayName('Retain eplusout.audit')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_eplusout_bnd', true)
    arg.setDisplayName('Retain eplusout.bnd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_eplusout_eio', true)
    arg.setDisplayName('Retain eplusout.eio')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_eplusout_end', true)
    arg.setDisplayName('Retain eplusout.end')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_eplusout_err', true)
    arg.setDisplayName('Retain eplusout.err')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_eplusout_eso', true)
    arg.setDisplayName('Retain eplusout.eso')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_eplusout_mdd', true)
    arg.setDisplayName('Retain eplusout.mdd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_eplusout_mtd', true)
    arg.setDisplayName('Retain eplusout.mtd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_eplusout_rdd', true)
    arg.setDisplayName('Retain eplusout.rdd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_eplusout_shd', true)
    arg.setDisplayName('Retain eplusout.shd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_eplusout_msgpack', true)
    arg.setDisplayName('Retain eplusout*.msgpack')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_eplustbl_htm', true)
    arg.setDisplayName('Retain eplustbl.htm')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_stdout_energyplus', true)
    arg.setDisplayName('Retain stdout-energyplus')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_stdout_expandobject', true)
    arg.setDisplayName('Retain stdout-expandobject')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('retain_schedules_csv', true)
    arg.setDisplayName('Retain *schedules.csv')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('debug', false)
    arg.setDisplayName('Debug Mode?')
    arg.setDescription('If true, retain all files.')
    arg.setDefaultValue(false)
    args << arg

    return args
  end # end the arguments method

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find OpenStudio model.')
      return false
    end
    model = model.get

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)

    # retain everything if debug is true
    if !args[:debug].nil? && args[:debug]
      args.each do |arg_name, _value|
        args[arg_name] = true
      end
    end

    # construct an argument name to file(s) map
    arg_name_to_file = {
      :retain_in_osm => 'in.osm',
      :retain_in_idf => 'in.idf',
      :retain_pre_process_idf => 'pre-preprocess.idf',
      :retain_eplusout_audit => 'eplusout.audit',
      :retain_eplusout_bnd => 'eplusout.bnd',
      :retain_eplusout_eio => 'eplusout.eio',
      :retain_eplusout_end => 'eplusout.end',
      :retain_eplusout_err => 'eplusout.err',
      :retain_eplusout_eso => 'eplusout.eso',
      :retain_eplusout_mdd => 'eplusout.mdd',
      :retain_eplusout_mtd => 'eplusout.mtd',
      :retain_eplusout_rdd => 'eplusout.rdd',
      :retain_eplusout_shd => 'eplusout.shd',
      :retain_eplusout_msgpack => 'eplusout*.msgpack',
      :retain_eplustbl_htm => 'eplustbl.htm',
      :retain_stdout_energyplus => 'stdout-energyplus',
      :retain_stdout_expandobject => 'stdout-expandobject',
      :retain_schedules_csv => '*schedules.csv'
    }

    # delete output files based on the map
    arg_name_to_file.each do |arg_name, file|
      Dir.glob("./../#{file}").each do |f|
        File.delete(f) if !args[arg_name]
        runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
      end
    end

    return true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
ServerDirectoryCleanup.new.registerWithApplication
