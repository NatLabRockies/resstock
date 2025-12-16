# frozen_string_literal: true

require 'openstudio'
require 'openstudio-standards'
require_relative '../../resources/buildstock'

# start the measure
class AddSharedSystem < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'AddSharedSystem'
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

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('add_shared_system_argument', false)
    arg.setDisplayName('Argument Name')
    arg.setDescription('TODO.')
    arg.setDefaultValue('None')
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

    return true if args[:add_shared_system_argument] == 'None'

    register_value(runner, 'add_shared_system_argument', args[:add_shared_system_argument])

    return true
  end
end

# register the measure to be used by the application
AddSharedSystem.new.registerWithApplication
