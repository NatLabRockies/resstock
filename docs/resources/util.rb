# frozen_string_literal: true

require 'csv'
require 'oga'

# Assemble measure.xml information into a hash.
def get_measure_xml(filepath)
  measure_xml = {}
  parse_xml = Oga.parse_xml(filepath)
  parse_xml.xpath('//measure/arguments/argument').each do |argument|
    name = argument.at_xpath('name').text
    measure_xml[name] = {}
    ['type', 'required', 'units', 'choices', 'description'].each do |property|
      if property != 'choices'
        element = argument.at_xpath(property)
        value = !element.nil? ? element.text : ''
      else
        value = argument.xpath('choices/choice').map { |c| c.at_xpath('value').text }
      end
      measure_xml[name][property] = value
    end
  end
  return measure_xml
end

# Display arguments in Arguments and Options table by the order they appear in BuildResidentialHPXML, otherwise use ResStockArguments if only defined there
def get_arg_order(buildreshpxmlarguments_xml, resstockarguments_xml)
  arg_order = buildreshpxmlarguments_xml.keys
  resstockarguments_xml.keys.each do |k|
    if !arg_order.include?(k)
      arg_order << k
    end
  end
  return arg_order
end

# These are column headers in both TDG's "Argument" table and TRG's "The ResStock argument definitions set" table.
def get_arguments_cols()
  return ['Name', 'Required', 'Units', 'Type', 'Choices', 'Description']
end

# Get csv data for options_lookup.tsv and options_saturations.csv.
def get_lookup_and_saturations_csv_data(resources_dir)
  lookup_file = File.join(resources_dir, 'options_lookup.tsv')
  option_sat_file = File.join('project_national', 'resources', 'options_saturations.csv')
  lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a
  option_sat_csv_data = CSV.open(option_sat_file, quote_char: '"', col_sep: ',').each.to_a
  return lookup_csv_data, option_sat_csv_data
end

# Refine resstockarguments_xml
def refine_resstockarguments_xml(resstockarguments_xml, buildreshpxmlarguments_xml, name, properties)
  # Get required and type from BuildResidentialHPXML
  ['required', 'type'].each do |property|
    resstockarguments_xml[name][property] = buildreshpxmlarguments_xml[name][property] if buildreshpxmlarguments_xml.keys.include?(name)
  end
end
