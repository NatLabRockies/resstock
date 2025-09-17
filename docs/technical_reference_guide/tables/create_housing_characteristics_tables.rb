# frozen_string_literal: true

require 'csv'
require 'oga'

class String
  def to_underscore_case
    gsub(/::/, '/')
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr('-', '_')
      .tr(' ', '_')
      .downcase
  end
end

def href_to_rst(str)
  urls_names = str.scan(/<a href='(.+?)'>(.+?)<\/a>/)
  return str if urls_names.empty?

  urls_names.each do |url_name|
    url, name = url_name

    str = str.gsub("<a href='#{url}'>#{name}</a>", "`#{name} <#{url}>`_")
  end
  return str
end

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

resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../../resources'))

filepath = File.read(File.join(resources_dir, 'hpxml-measures/BuildResidentialHPXML/measure.xml'))
buildreshpxmlarguments_xml = get_measure_xml(filepath)

filepath = File.read(File.join(resources_dir, '../measures/ResStockArguments/measure.xml'))
resstockarguments_xml = get_measure_xml(filepath)

# Refine resstockarguments_xml
resstockarguments_xml.each do |name, properties|
  # Get required and type from BuildResidentialHPXML
  ['required', 'type'].each do |property|
    resstockarguments_xml[name][property] = buildreshpxmlarguments_xml[name][property] if buildreshpxmlarguments_xml.keys.include?(name)
  end

  # Add "auto" to Choices for optional String/Double/Integer
  extra_args_with_auto = ['year_built', 'geometry_unit_num_occupants', 'geometry_unit_cfa', 'heat_pump_backup_heating_efficiency'] # these are special because ResStockArguments provides the default instead of OS-HPXML
  if (properties['description'].include?('OS-HPXML default') && ['String', 'Double', 'Integer'].include?(properties['type'])) ||
     extra_args_with_auto.include?(name)
    resstockarguments_xml[name]['choices'].unshift('auto')
  end

  # Convert href to rst for description
  resstockarguments_xml[name]['description'] = href_to_rst(resstockarguments_xml[name]['description'])
end

# Display arguments in Arguments and Options table by the order they appear in BuildResidentialHPXML, otherwise use ResStockArguments if only defined there
arg_order = buildreshpxmlarguments_xml.keys
resstockarguments_xml.keys.each do |k|
  if !arg_order.include?(k)
    arg_order << k
  end
end

source_report_cols = ['Description', 'Created by', 'Source', 'Assumption']
arguments_cols = ['Name', 'Required', 'Units', 'Type', 'Choices', 'Description']

lookup_file = File.join(resources_dir, 'options_lookup.tsv')
option_sat_file = File.join('project_national', 'resources', 'options_saturations.csv')
lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a
option_sat_csv_data = CSV.open(option_sat_file, quote_char: '"', col_sep: ',').each.to_a

source_report = CSV.read(File.join(File.dirname(__FILE__), '../../../project_national/resources/source_report.csv'), headers: true)
source_report.each do |row|
  parameter = row['Parameter']

  # Arguments
  r_arguments = []
  lookup_csv_data.each do |lookup_row|
    next if lookup_row[0] != parameter
    next if lookup_row[2] != 'ResStockArguments'

    lookup_row[3..-1].each do |argument_value|
      argument, _value = argument_value.split('=')
      r_arguments << argument if !r_arguments.include?(argument)
    end
  end
  next unless r_arguments.any?

  f = File.open(File.join(File.dirname(__FILE__), "#{parameter}.tex"), 'w')

  f.puts('\begin{customLongTable}{ |p{2.5cm}|p{1.5cm}|p{2.5cm}|p{1.1cm}|p{2.9cm}|p{3cm}| }')
  f.puts("{The ResStock argument definitions set in the #{parameter} characteristic} {table:hc_arg_def_#{parameter.downcase}}")
  f.puts("{#{arguments_cols.join(' & ')}}")
  r_arguments.each_with_index do |r_argument, i|
    name = "\\texttt{#{r_argument}}".gsub('_', '\_')
    required = resstockarguments_xml[r_argument]['required']
    units = resstockarguments_xml[r_argument]['units'].gsub('$', '\$').gsub('#', '\#')
    type = resstockarguments_xml[r_argument]['type']
    choices = resstockarguments_xml[r_argument]['choices'].join(', ')
    description = resstockarguments_xml[r_argument]['description']
    ix = description.index('If not provided')
    if ix
      description = description.slice(0, ix)
    end
    row = "#{name} & #{required} & #{units} & #{type} & #{choices} & #{description}  \\\\"
    if i < r_arguments.size - 1
      row += ' \\hline'
    end
    f.puts(row)
  end
  f.puts('\end{customLongTable}')
end
