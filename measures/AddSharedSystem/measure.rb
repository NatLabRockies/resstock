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
      arg.setRequired(false)
      args << arg
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

    if args[:hvac_heating_shared_system] == 'None' && args[:hvac_cooling_shared_system] == 'None'
      register_value(runner, 'shared_system_type', 'None')
      return true
    end

    systems = { ['Baseboard', 'None'] => 'Boiler Baseboards Heating Only',
                ['None', 'FanCoil'] => 'Fan Coil Cooling Only',
                ['FanCoil', 'FanCoil'] => 'Fan Coil Heating and Cooling' }
    system = systems[[args[:hvac_heating_shared_system], args[:hvac_cooling_shared_system]]]
    if system.nil?
      register_value(runner, 'shared_system_type', 'Unsupported')
      return true
    end

    if system == 'Boiler Baseboards Heating Only'
      # method_a(model, args[:hvac_heating_system], args[:hvac_heating_system_fuel])
    elsif system == 'Fan Coil Cooling Only'
      # method_b(model, args[:hvac_cooling_system])
    elsif system == 'Fan Coil Heating and Cooling'
      # method_c(model, args[:hvac_heating_system], args[:hvac_heating_system_fuel], args[:hvac_cooling_system])
    end

    register_value(runner, 'shared_system_type', system)

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
