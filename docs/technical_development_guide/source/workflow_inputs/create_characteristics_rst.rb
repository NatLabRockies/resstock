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

def write_subsection(f, row, name, sc, delim)
  return if row[name].nil?

  f.puts(name)
  f.puts(sc * name.size)
  f.puts
  entry = row[name].tr('\\', '/')
  entry = "``#{entry}``" if entry.include?('.py')
  if !delim.nil?
    items = []
    entries = entry.split(delim).map(&:strip)
    entries.each do |entry|
      if entry.start_with?(/\[\d+\]/)
        item = "  - \\#{entry}"
      else
        item = "- \\#{entry}"
      end
      items << item
      items << ''
    end
    entry = items
  end
  f.puts(entry)
  f.puts
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

resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../../../resources'))

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
  if (properties['description'].include?('OS-HPXML default') && ['String', 'Double', 'Integer'].include?(properties['type'])) || (name == 'year_built') || (name == 'geometry_unit_num_occupants') # these last 2 are special because ResStockArguments provides the default instead of OS-HPXML
    resstockarguments_xml[name]['choices'].unshift('auto')
  end

  # Convert href to rst for description
  resstockarguments_xml[name]['description'] = href_to_rst(resstockarguments_xml[name]['description'])
end

source_report_cols = ['Description', 'Created by', 'Source', 'Assumption']
arguments_cols = ['Name', 'Required', 'Units', 'Type', 'Choices', 'Description']

f = File.open(File.join(File.dirname(__FILE__), 'characteristics.rst'), 'w')
f.puts('.. _housing_characteristics:')
f.puts
f.puts('Housing Characteristics')
f.puts('=======================')
f.puts
f.puts('Each parameter sampled by the national project is listed alphabetically as its own subsection below.')
f.puts('For each parameter, the following (if applicable) are reported based on the contents of the `source_report.csv <https://github.com/NREL/resstock/blob/develop/project_national/resources/source_report.csv>`_:')
f.puts
source_report_cols.each do |source_report_col|
  f.puts("- **#{source_report_col}**")
end
f.puts
f.puts('Additionally, for each parameter an **Arguments** table is populated (if applicable) based on the contents of `ResStockArguments <https://github.com/NREL/resstock/blob/develop/measures/ResStockArguments>`_ and `BuildResidentialHPXML <https://github.com/NREL/resstock/blob/develop/resources/hpxml-measures/BuildResidentialHPXML>`_ measure.xml files.')
f.puts
arguments_cols.each do |arguments_col|
  if ['Name', 'Required', 'Type'].include?(arguments_col)
    f.puts("- **#{arguments_col}** [#]_")
  else
    f.puts("- **#{arguments_col}**")
  end
end
f.puts
f.puts('.. [#] Each **Name** entry is an argument that is assigned using defined options from the `options_lookup.tsv <https://github.com/NREL/resstock/blob/develop/resources/options_lookup.tsv>`_.')
f.puts('.. [#] May be "true" or "false".')
f.puts('.. [#] May be "String", "Double", "Integer", "Boolean", or "Choice".')
f.puts
f.puts('Furthermore, all *optional* Choice arguments include "auto" as one of the possible **Choices**.')
f.puts('Most *optional* String/Double/Integer/Boolean arguments can also be assigned a value of "auto" (e.g., ``site_ground_conductivity``).')
f.puts('Assigning "auto" means that downstream default values (e.g., from OpenStudio-HPXML) will be used (if applicable).')
f.puts('When an argument is defaulted using OpenStudio-HPXML, the **Description** field will include link(s) to `OpenStudio-HPXML documentation <https://openstudio-hpxml.readthedocs.io/en/latest/?badge=latest>`_ describing these default values.')
f.puts

lookup_file = File.join(resources_dir, 'options_lookup.tsv')
option_sat_file = File.join('project_national', 'resources', 'options_saturations.csv')
lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a
option_sat_csv_data = CSV.open(option_sat_file, quote_char: '"', col_sep: ',').each.to_a

source_report = CSV.read(File.join(File.dirname(__FILE__), '../../../../project_national/resources/source_report.csv'), headers: true)
source_report.each do |row|
  parameter = row['Parameter']

  # ref
  f.puts(".. _#{parameter.to_underscore_case}:")
  f.puts

  # section
  f.puts(parameter)
  f.puts('-' * parameter.size)
  f.puts

  source_report_cols.each do |subsection_name|
    # delim = nil
    delim = ';' if ['Source', 'Assumption'].include?(subsection_name)
    write_subsection(f, row, subsection_name, '*', delim)
  end

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
  if r_arguments.any?

    name = 'Arguments'
    f.puts(name)
    f.puts('*' * name.size)
    f.puts
    f.puts('.. list-table::')
    f.puts('   :header-rows: 1')
    f.puts('   :stub-columns: 1')
    f.puts
    arguments_cols.each_with_index do |arguments_col, i|
      line = "     - #{arguments_col}"
      line = "   * - #{arguments_col}" if i == 0
      f.puts(line)
    end

    r_arguments = r_arguments.sort_by &resstockarguments_xml.keys.method(:index)
    r_arguments.each do |r_argument|
      f.puts("   * - ``#{r_argument}``")
      f.puts("     - #{resstockarguments_xml[r_argument]['required']}")
      f.puts("     - #{resstockarguments_xml[r_argument]['units']}")
      f.puts("     - #{resstockarguments_xml[r_argument]['type']}")
      choices = resstockarguments_xml[r_argument]['choices']
      if choices.empty?
        f.puts('     -')
      else
        f.puts("     - #{choices.join(', ')}")
      end
      f.puts("     - #{resstockarguments_xml[r_argument]['description']}")
    end
    f.puts
  end
  # Options
  name = 'Options'
  f.puts(name)
  f.puts('*' * name.size)
  f.puts
  f.puts("From ``project_national`` the list of options, option stock sturation, and option arguments for the **#{parameter}** characteristic.")
  f.puts
  f.puts('.. list-table::')
  f.puts('   :header-rows: 1')
  f.puts('   :stub-columns: 1')
  f.puts('   :widths: auto')
  f.puts
  f.puts('   * - Option name')
  f.puts('     - Stock saturation')

  # Get arguments for table header
  if !r_arguments.empty?
    r_arguments.each do |r_argument|
      f.puts("     - ``#{r_argument}``")
    end
  end
  f.puts

  # Options and stock saturation
  option_sat_csv_data.each do |param_option_row|
    # If the parameter does not match next
    next if param_option_row[1] != parameter

    # Insert the options and the stock saturation
    option = param_option_row[2]
    f.puts("   * - #{option}")
    sat_percent = Float(param_option_row[3]) * 100.0
    if Integer(sat_percent.truncate()) == 100
      f.puts('     - %.3g%%' % [sat_percent])
    else
      f.puts('     - %.2g%%' % [sat_percent])
    end

    # Check if there are arguments
    next unless !r_arguments.empty?

    # If there are arguments, go through options lookup to find the option
    lookup_csv_data.each do |lookup_row|
      next if lookup_row[0] != parameter
      next if lookup_row[1] != option

      # When the option is found
      if lookup_row[2] != 'ResStockArguments'
        # Put all blank rows if there is no arguments
        for _a in 1..r_arguments.length() do
          f.puts('     - ')
        end
      else
        # If option specifies arguments, insert arguments according to the order of r_arguements
        r_arguments.each do |argument|
          # Look for each argument in r_arguments
          found_arg = false
          lookup_row[3..-1].each do |argument_value|
            arg, value = argument_value.split('=')
            if argument == arg
              found_arg = true
              f.puts("     - #{value}")
            end
          end
          # if the argument is not found (a not specified optional argument)
          if !found_arg
            f.puts('     - ')
          end
        end
      end
    end
  end
  f.puts
end
