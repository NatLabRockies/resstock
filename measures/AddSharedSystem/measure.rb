# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
# require 'openstudio-standards'
require_relative '../../resources/buildstock'

# start the measure
class AddSharedSystem < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Add Shared System'
  end

  # human readable description
  def description
    return 'TODO'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'TODO'
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    # Allow same arguments as ResStockArguments measure

    full_measure_path = File.join(File.dirname(__FILE__), '..', 'ResStockArguments', 'measure.rb')
    measure_arguments = get_measure_instance(full_measure_path).arguments(model)
    measure_arguments.each do |arg|
      # Convert to optional argument for the unit test
      # Replace all of this if https://github.com/NREL/OpenStudio/issues/5469 is addressed
      case arg.type.valueName.downcase
      when 'choice'
        new_arg = OpenStudio::Measure::OSArgument.makeChoiceArgument(arg.name, arg.choiceValues, false)
        new_arg.setDefaultValue(arg.defaultValueAsString) if arg.hasDefaultValue
      when 'boolean'
        new_arg = OpenStudio::Measure::OSArgument.makeBoolArgument(arg.name, false)
        new_arg.setDefaultValue(arg.defaultValueAsBool) if arg.hasDefaultValue
      when 'string'
        new_arg = OpenStudio::Measure::OSArgument.makeStringArgument(arg.name, false)
        new_arg.setDefaultValue(arg.defaultValueAsString) if arg.hasDefaultValue
      when 'double'
        new_arg = OpenStudio::Measure::OSArgument.makeDoubleArgument(arg.name, false)
        new_arg.setDefaultValue(arg.defaultValueAsDouble) if arg.hasDefaultValue
      when 'integer'
        new_arg = OpenStudio::Measure::OSArgument.makeIntegerArgument(arg.name, false)
        new_arg.setDefaultValue(arg.defaultValueAsInteger) if arg.hasDefaultValue
      else
        fail "Unhandled argument type: #{arg.type.valueName.downcase}"
      end
      new_arg.setDisplayName(arg.displayName.to_s)
      new_arg.setDescription(arg.description.to_s)
      new_arg.setUnits(arg.units.to_s)
      args << new_arg
    end

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', false)
    arg.setDisplayName('HPXML File Path')
    arg.setDescription('Absolute/relative path of the HPXML file.')
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

    # Assign the user inputs to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)
    args = convert_args(arguments(model), args)

    return true if args[:add_shared_system_argument] == 'None'

    register_value(runner, 'add_shared_system_argument', args[:add_shared_system_argument])

    return true
  end

  def convert_args(measure_arguments, args)
    measure_arguments.each do |arg|
      arg_name = arg.name.to_sym
      value = args[arg_name]
      next if value.nil?

      case arg.type.valueName.downcase
      when 'double'
        args[arg_name] = Float(value)
      when 'integer'
        args[arg_name] = Integer(value)
      end
    end
    return args
  end
end

# register the measure to be used by the application
AddSharedSystem.new.registerWithApplication
