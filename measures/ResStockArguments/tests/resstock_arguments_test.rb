# frozen_string_literal: true

require 'csv'
require 'parallel'
require 'openstudio'
require_relative '../../../resources/buildstock'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../measure.rb'

class ResStockArgumentsTest < Minitest::Test
  def setup
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../../resources'))
    lookup_file = File.join(resources_dir, 'options_lookup.tsv')
    @lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a
  end

  def test_options_lookup_assignment
    lookup_arguments = []
    @lookup_csv_data.each do |lookup_row|
      next if lookup_row[2] != 'ResStockArguments'

      lookup_row[3..-1].each do |argument_value|
        argument, _value = argument_value.split('=')
        lookup_arguments << argument if !lookup_arguments.include?(argument)
      end
    end

    measure = ResStockArguments.new
    model = OpenStudio::Model::Model.new
    resstock_arguments = []
    measure.arguments(model).each do |arg|
      next if Constants::OtherExcludes.include? arg.name

      resstock_arguments << arg.name
    end

    resstock_arguments_extras = resstock_arguments - lookup_arguments
    puts "resstock_arguments - lookup_arguments: #{resstock_arguments_extras.sort}" if !resstock_arguments_extras.empty?
    assert_equal(0, resstock_arguments_extras.size)

    lookup_arguments_extras = lookup_arguments - resstock_arguments
    puts "lookup_arguments - resstock_arguments: #{lookup_arguments_extras.sort}" if !lookup_arguments_extras.empty?
    assert_equal(0, lookup_arguments_extras.size)
  end
end
