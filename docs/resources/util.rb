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
    ['units', 'description'].each do |property|
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
def get_properties_cols()
  return ['Name', 'Units', 'Description']
end

# Get csv data for options_lookup.tsv and options_saturations.csv.
def get_lookup_and_saturations_csv_data(resources_dir)
  lookup_file = File.join(resources_dir, 'options_lookup.tsv')
  option_sat_file = File.join('project_national', 'resources', 'options_saturations.csv')
  lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a
  option_sat_csv_data = CSV.open(option_sat_file, quote_char: '"', col_sep: ',').each.to_a
  return lookup_csv_data, option_sat_csv_data
end

def get_properties(resources_dir)
  properties = {}
  Dir["#{resources_dir}/hpxml-measures/BuildResidentialHPXML/resources/options/*.tsv"].each do |tsv_filepath|
    tsv_filename = File.basename(tsv_filepath)
    arg_name = File.basename(tsv_filename, File.extname(tsv_filename))

    property_names = get_property_names(tsv_filename)
    property_units = get_property_units(tsv_filename)
    property_descriptions = get_property_descriptions(tsv_filename)

    properties[arg_name] = {}
    property_names.each_with_index do |property_name, i|
      property_description = property_descriptions[property_name]
      property_name = "#{arg_name}_#{property_name.downcase.gsub(' ', '_').gsub('-', '_')}"
      properties[arg_name][property_name] = { 'property_unit' => property_units[i], 'description' => property_description }
    end
  end
  return properties
end

def get_options(resources_dir)
  options = {}
  Dir["#{resources_dir}/hpxml-measures/BuildResidentialHPXML/resources/options/*.tsv"].each do |tsv_filepath|
    tsv_filename = File.basename(tsv_filepath)
    arg_name = File.basename(tsv_filename, File.extname(tsv_filename))

    options[arg_name] = {}
    option_names = get_option_names(tsv_filename)
    option_names.each do |option_name|
      args = {}
      get_option_properties(args, tsv_filename, option_name)

      options[arg_name][option_name] = args.transform_keys(&:to_s)
    end
  end
  return options
end
