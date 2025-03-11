# frozen_string_literal: true

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'

require_relative '../measure'

class ModelMeasureNameTest < Minitest::Test
  def test_number_of_arguments_and_argument_names
    measure = ResStockArgumentsPostHPXML.new
    model = OpenStudio::Model::Model.new
    arguments = measure.arguments(model)
    argument_names = arguments.collect { |a| a.name }
    expected_argument_names = ['hpxml_path', 'building_id', 'output_csv_path']
    expected_argument_names.each do |expected_name|
      assert_includes(argument_names, expected_name, "Expected argument '#{expected_name}' not found")
    end
  end
end
