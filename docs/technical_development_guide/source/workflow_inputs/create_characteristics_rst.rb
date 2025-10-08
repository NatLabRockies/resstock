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
arguments_cols = get_arguments_cols()

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
f.puts('For each parameter an **Arguments** table is populated (if applicable) based on the contents of `ResStockArguments <https://github.com/NREL/resstock/blob/develop/measures/ResStockArguments>`_ and `BuildResidentialHPXML <https://github.com/NREL/resstock/blob/develop/resources/hpxml-measures/BuildResidentialHPXML>`_ measure.xml files, each containing the following columns:')
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
f.puts('For each parameter an **Options** table is populated based on the contents of the `options_lookup.tsv <https://github.com/NREL/resstock/blob/develop/resources/options_lookup.tsv>`_, `options_saturations.csv <https://github.com/NREL/resstock/blob/develop/project_national/resources/options_saturations.csv>`_, and `BuildResidentialHPXML/resources/options/*.tsv <https://github.com/NREL/resstock/blob/develop/resources/hpxml-measures/BuildResidentialHPXML/resources/options>`_ files.')
f.puts

lookup_csv_data, option_sat_csv_data = get_lookup_and_saturations_csv_data(resources_dir)

arg_map = {}

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

    r_arguments = r_arguments.sort_by &arg_order.method(:index)

    r_arguments.each do |r_argument|
      f.puts("   * - ``#{r_argument}``")
      f.puts("     - #{resstockarguments_xml[r_argument]['required']}")
      f.puts("     - #{resstockarguments_xml[r_argument]['units']}")
      f.puts("     - #{resstockarguments_xml[r_argument]['type']}")
      choices = resstockarguments_xml[r_argument]['choices']
      if choices.empty?
        f.puts('     -')
      else
        f.puts("     - #{choices.join('; ')}")
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
  f.puts("From ``project_national`` the list of options, option stock saturation, and option properties for the **#{parameter}** characteristic.")
  f.puts
  f.puts('.. list-table::')
  f.puts('   :header-rows: 1')
  f.puts('   :stub-columns: 1')
  f.puts('   :widths: auto')
  f.puts

  cols = []
  cols << ['Option name', 'Stock saturation']

  # Options and stock saturation
  option_sat_csv_data.each do |param_option_row|
    # If the parameter does not match next
    next if param_option_row[1] != parameter

    # Insert the options and the stock saturation
    option = param_option_row[2]

    sat_percent = Float(param_option_row[3]) * 100.0
    if Integer(sat_percent.truncate()) == 100
      sat_percent = '%.3g%%' % [sat_percent]
    else
      sat_percent = '%.2g%%' % [sat_percent]
    end
    cols << [option, sat_percent]

    # Check if there are arguments
    next unless !r_arguments.empty?

    # If there are arguments, go through options lookup to find the option
    lookup_csv_data.each do |lookup_row|
      next if lookup_row[0] != parameter
      next if lookup_row[1] != option

      # When the option is found
      next unless lookup_row[2] == 'ResStockArguments'

      # If option specifies arguments, insert arguments according to the order of r_arguments
      r_arguments.each do |argument|
        # Look for each argument in r_arguments
        lookup_row[3..-1].each do |argument_value|
          arg, value = argument_value.split('=')

          next if argument != arg

          tsv_filename = "#{arg}.tsv"
          tsv_filepath = File.join(resources_dir, "hpxml-measures/BuildResidentialHPXML/resources/options/#{tsv_filename}")
          if File.exist?(tsv_filepath)
            args = {}
            get_option_properties(args, tsv_filename, value)

            arg_map[arg] = args.keys
            cols[-1] += args.values
          else
            cols[-1] << value
          end
        end
      end
    end
  end

  r_arguments.each do |r_argument|
    if arg_map.keys.include?(r_argument)
      arg_map[r_argument].each do |arg|
        cols[0] << "``#{arg}``"
      end
    else
      cols[0] << "``#{r_argument}``"
    end
  end

  cols.each do |col|
    n_vals = cols[0].size - col.size
    (1..n_vals).to_a.each do |_n|
      col << ''
    end

    col.each_with_index do |val, ix|
      if ix == 0
        f.puts("   * - #{val}")
      else
        f.puts("     - #{val}")
      end
    end
  end
end
