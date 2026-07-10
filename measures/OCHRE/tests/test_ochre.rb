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

  def test_start_date_arguments_defaults
    # Create an instance of the measure
    measure = OCHRE.new

    # Make an empty model
    model = OpenStudio::Model::Model.new

    # Get arguments
    arguments = measure.arguments(model)

    # Find the start date arguments
    start_year_arg = arguments.find { |arg| arg.name == 'start_year' }
    start_month_arg = arguments.find { |arg| arg.name == 'start_month' }
    start_day_arg = arguments.find { |arg| arg.name == 'start_day' }

    # Check that they exist and are optional
    assert_equal('start_year', start_year_arg.name)
    assert_equal(false, start_year_arg.required)
    assert_equal(2018, start_year_arg.defaultValueAsInteger)

    assert_equal('start_month', start_month_arg.name)
    assert_equal(false, start_month_arg.required)
    assert_equal(1, start_month_arg.defaultValueAsInteger)

    assert_equal('start_day', start_day_arg.name)
    assert_equal(false, start_day_arg.required)
    assert_equal(1, start_day_arg.defaultValueAsInteger)
  end
end
