# frozen_string_literal: true

resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../../../resources'))

require_relative '../../../resources/util'
require_relative File.join(resources_dir, 'hpxml-measures/BuildResidentialHPXML/resources/options')

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

filepath = File.read(File.join(resources_dir, 'hpxml-measures/BuildResidentialHPXML/measure.xml'))
buildreshpxmlarguments_xml = get_measure_xml(filepath)

filepath = File.read(File.join(resources_dir, '../measures/ResStockArguments/measure.xml'))
resstockarguments_xml = get_measure_xml(filepath)

arg_order = get_arg_order(buildreshpxmlarguments_xml, resstockarguments_xml)
source_report_cols = ['Description', 'Created by', 'Source', 'Assumption']
properties_cols = get_properties_cols()

properties = get_properties(resources_dir)
options = get_options(resources_dir)

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
f.puts('For each parameter a **Properties** table is populated (if applicable) based on the contents of `BuildResidentialHPXML/resources/options/*.tsv <https://github.com/NREL/resstock/blob/develop/resources/hpxml-measures/BuildResidentialHPXML/resources/options>`_ files, each containing the following columns:')
f.puts
properties_cols.each do |properties_col|
  if ['Name'].include?(properties_col)
    f.puts("- **#{properties_col}** [#]_")
  else
    f.puts("- **#{properties_col}**")
  end
end
f.puts
f.puts('.. [#] Each **Name** entry is an argument that is assigned using defined options from the `options_lookup.tsv <https://github.com/NREL/resstock/blob/develop/resources/options_lookup.tsv>`_.')
f.puts
f.puts('For each parameter an **Options** table is populated based on the contents of the `options_lookup.tsv <https://github.com/NREL/resstock/blob/develop/resources/options_lookup.tsv>`_, `options_saturations.csv <https://github.com/NREL/resstock/blob/develop/project_national/resources/options_saturations.csv>`_, and `BuildResidentialHPXML/resources/options/*.tsv <https://github.com/NREL/resstock/blob/develop/resources/hpxml-measures/BuildResidentialHPXML/resources/options>`_ files.')
f.puts

lookup_csv_data, option_sat_csv_data = get_lookup_and_saturations_csv_data(resources_dir)

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
    delim = ';' if ['Source', 'Assumption'].include?(subsection_name)
    write_subsection(f, row, subsection_name, '*', delim)
  end

  # Properties
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

    name = 'Properties'
    f.puts(name)
    f.puts('*' * name.size)
    f.puts
    f.puts('.. list-table::')
    f.puts('   :header-rows: 1')
    f.puts('   :stub-columns: 1')
    f.puts
    properties_cols.each_with_index do |properties_col, i|
      line = "     - #{properties_col}"
      line = "   * - #{properties_col}" if i == 0
      f.puts(line)
    end

    r_arguments = r_arguments.sort_by &arg_order.method(:index)

    r_arguments.each do |r_argument|
      if properties.keys.include?(r_argument)
        properties[r_argument].each do |property_name, property_unit_comment|
          f.puts("   * - ``#{property_name}``")
          f.puts("     - #{property_unit_comment['property_unit']}")
          f.puts("     - #{property_unit_comment['comment_row']}")
        end
      else
        f.puts("   * - ``#{r_argument}``")
        f.puts("     - #{resstockarguments_xml[r_argument]['units']}")
        f.puts("     - #{resstockarguments_xml[r_argument]['description']}")
      end
    end
    f.puts
  end

  # Options
  name = 'Options'
  f.puts(name)
  f.puts('*' * name.size)
  f.puts
  f.puts("From ``project_national`` the list of options, option stock saturation, and option properties for the **#{parameter}** characteristic.")
  f.puts
  f.puts('.. list-table::')
  f.puts('   :header-rows: 1')
  f.puts('   :stub-columns: 1')
  f.puts('   :widths: auto')
  f.puts
  f.puts('   * - Option name')

  # Options and stock saturation
  lookup = {}
  option_sat_csv_data.each do |param_option_row|
    # If the parameter does not match next
    next if param_option_row[1] != parameter

    # Insert the options and the stock saturation
    option = param_option_row[2]

    lookup[option] = {}

    sat_percent = Float(param_option_row[3]) * 100.0
    if Integer(sat_percent.truncate()) == 100
      sat_percent = '%.3g%%' % [sat_percent]
    else
      sat_percent = '%.2g%%' % [sat_percent]
    end

    lookup[option]['sat'] = sat_percent

    # Check if there are arguments
    next unless !r_arguments.empty?

    # If there are arguments, go through options lookup to find the option
    lookup_csv_data.each do |lookup_row|
      next if lookup_row[0] != parameter
      next if lookup_row[1] != option
      next if lookup_row[2] != 'ResStockArguments'

      lookup_row[3..-1].each do |argument_value|
        arg, value = argument_value.split('=')

        lookup[option][arg] = value
      end
    end
  end

  lookup.keys.each do |option_name|
    f.puts("     - #{option_name}")
  end

  f.puts('   * - Stock saturation')

  lookup.keys.each do |option|
    f.puts("     - #{lookup[option]['sat']}")
  end

  r_arguments.each do |r_argument|
    if properties.keys.include?(r_argument)
      properties[r_argument].keys.each do |arg|
        f.puts("   * - ``#{arg}``")

        lookup.keys.each do |option|
          option_name = lookup[option][r_argument]

          if not option_name.nil?
            options[r_argument][option_name].each do |arg2, value|
              next if arg != arg2

              f.puts("     - #{value}")
            end
          else
            f.puts('     -')
          end
        end
      end
    else
      f.puts("   * - ``#{r_argument}``")
      lookup.keys.each do |option|
        f.puts("     - #{lookup[option][r_argument]}")
      end
    end
  end
end
