# frozen_string_literal: true

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class OCHRETest < Minitest::Test
  def setup
    # Create a temporary directory for tests
    @test_dir = File.join(File.dirname(__FILE__), 'output')
    FileUtils.mkdir_p(@test_dir) unless File.exist?(@test_dir)
  end

  def teardown
    # Clean up test directory
    FileUtils.rm_rf(@test_dir) if File.exist?(@test_dir)
  end

  def test_number_of_arguments_and_argument_names
    # Create an instance of the measure
    measure = OCHRE.new

    # Make an empty model
    model = OpenStudio::Model::Model.new

    # Get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(5, arguments.size)

    # Check argument names
    arg_names = arguments.map(&:name)
    assert_includes(arg_names, 'hpxml_path')
    assert_includes(arg_names, 'output_dir')
    assert_includes(arg_names, 'time_res_minutes')
    assert_includes(arg_names, 'duration_days')
    assert_includes(arg_names, 'debug')
  end

  def test_bad_hpxml_path
    # Create an instance of the measure
    measure = OCHRE.new

    # Create runner with empty OSW
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Make an empty model
    model = OpenStudio::Model::Model.new

    # Get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # Set argument values
    argument_map['hpxml_path'].setValue('nonexistent_file.xml')
    argument_map['output_dir'].setValue(@test_dir)

    # Run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # Show the output
    show_output(result)

    # Assert that it failed (because file doesn't exist)
    assert_equal('Fail', result.value.valueName)
  end

  def test_measure_name
    # Create an instance of the measure
    measure = OCHRE.new

    # Check the name
    assert_equal('OCHRE Simulator', measure.name)
  end

  def test_description
    # Create an instance of the measure
    measure = OCHRE.new

    # Check the description
    assert(!measure.description.empty?)
    assert(measure.description.include?('OCHRE'))
  end

  def test_modeler_description
    # Create an instance of the measure
    measure = OCHRE.new

    # Check the modeler description
    assert(!measure.modeler_description.empty?)
    assert(measure.modeler_description.include?('HPXMLtoOpenStudio'))
  end

  # Helper method to show runner output
  def show_output(result)
    show_runner_output(result)
  end
end
