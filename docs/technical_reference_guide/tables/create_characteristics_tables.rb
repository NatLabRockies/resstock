# frozen_string_literal: true

require 'csv'
require 'oga'

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

arguments_cols = ['Name', 'Required', 'Units', 'Type', 'Choices', 'Description']

lookup_file = File.join(resources_dir, 'options_lookup.tsv')
option_sat_file = File.join('project_national', 'resources', 'options_saturations.csv')
lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a
option_sat_csv_data = CSV.open(option_sat_file, quote_char: '"', col_sep: ',').each.to_a

desc_exclusions = ['If not provided', 'If neither']
saturation_inclusions = ['Orientation',
                         'Geometry Stories',
                         'Geometry Story Bin',
                         'Geometry Building Type Height',
                         'Geometry Building Number Units MF',
                         'Geometry Building Number Units SFA',
                         'Geometry Building Level MF',
                         'Geometry Building Horizontal Location MF',
                         'Geometry Building Horizontal Location SFA',
                         'Neighbors',
                         'Corridor',
                         'Geometry Building Type ACS',
                         'Geometry Building Type RECS',
                         'Vintage',
                         'Vintage ACS']

source_report = CSV.read(File.join(File.dirname(__FILE__), '../../../project_national/resources/source_report.csv'), headers: true)
source_report.each do |row|
  parameter = row['Parameter']

  r_arguments = []
  lookup_csv_data.each do |lookup_row|
    next if lookup_row[0] != parameter
    next if lookup_row[2] != 'ResStockArguments'

    lookup_row[3..-1].each do |argument_value|
      argument, _value = argument_value.split('=')
      r_arguments << argument if !r_arguments.include?(argument)
    end
  end

  # Arguments
  if r_arguments.any?
    f = File.open(File.join(File.dirname(__FILE__), "arguments/#{parameter}.tex"), 'w')

    f.puts('\begin{customLongTable}{ |p{3cm}|p{1.25cm}|p{1.5cm}|p{1.5cm}|p{3cm}|p{3.5cm}| }')
    f.puts("{The ResStock argument definitions set in the #{parameter} characteristic} {table:hc_arg_def_#{parameter.downcase.gsub(' ', '_')}}")
    f.puts("{#{arguments_cols.join(' & ')}}")
    r_arguments.each_with_index do |r_argument, i|
      name = "\\texttt{#{r_argument}}".gsub('_', '\_')
      required = resstockarguments_xml[r_argument]['required']
      units = resstockarguments_xml[r_argument]['units'].gsub('$', '\$').gsub('#', '\#').gsub('^2', '\textsuperscript{2}')
      type = resstockarguments_xml[r_argument]['type']
      choices = resstockarguments_xml[r_argument]['choices'].join(', ')
      description = resstockarguments_xml[r_argument]['description']
      desc_exclusions.each do |desc_exclusion|
        ix = description.index(desc_exclusion)
        if ix
          description = description.slice(0, ix)
        end
      end
      row = "#{name} & #{required} & #{units} & #{type} & #{choices} & #{description}  \\\\"
      if i < r_arguments.size - 1
        row += ' \\hline'
      end
      f.puts(row)
    end
    f.puts('\end{customLongTable}')
  end

  # Options
  f = File.open(File.join(File.dirname(__FILE__), "options/#{parameter}.tex"), 'w')

  options = {}
  option_sat_csv_data.each do |param_option_row|
    # If the parameter does not match next
    next if param_option_row[1] != parameter

    # Insert the options and the stock saturation
    option = param_option_row[2]

    if not options.keys.include?(option)
      options[option] = {}
    end

    next if Float(param_option_row[3]) == 0

    sat_percent = Float(param_option_row[3]) * 100.0
    if Integer(sat_percent.truncate()) == 100
      sat_percent = '%.3g%%' % [sat_percent]
    else
      sat_percent = '%.2g%%' % [sat_percent]
    end
    options[option]['sat'] = "#{sat_percent}".gsub("%", "\\%")

    # Check if there are arguments
    next unless !r_arguments.empty?

    # If there are arguments, go through options lookup to find the option
    lookup_csv_data.each do |lookup_row|
      next if lookup_row[0] != parameter
      next if lookup_row[1] != option

      next unless lookup_row[2] == 'ResStockArguments'

      # If option specifies arguments, insert arguments according to the order of r_arguments
      r_arguments.each do |argument|
        # Look for each argument in r_arguments
        lookup_row[3..-1].each do |argument_value|
          arg, value = argument_value.split('=')
          if argument == arg
            options[option][arg] = value
          end
        end
      end
    end
  end

  changing_args = []
  r_arguments.each do |r_argument|
    vals = []
    options.keys.each do |option|
      vals << options[option][r_argument]
    end
    if vals.uniq.size != 1
      changing_args << r_argument
    end
  end

  max_changing_args = 4
  if changing_args.size > max_changing_args
    puts "Warning: #{parameter} varying arguments #{changing_args.size} / #{max_changing_args}"
  end

  row = '\begin{customLongTable}{ |p{3cm}'
  if saturation_inclusions.include?(parameter)
    row += '|p{2.75cm}'
  end
  changing_args.each do |_changing_arg|
    row += '|p{2.75cm}'
  end
  f.puts("#{row}| }")
  f.puts("{#{parameter} options and arguments that vary for each option} {table:hc_opt_#{parameter.downcase.gsub(' ', '_')}}")

  row = '{Option name'
  if saturation_inclusions.include?(parameter)
    row += ' & Stock saturation'
  end
  changing_args.each do |changing_arg|
    row += " & \\texttt{#{changing_arg}}".gsub('_', '\_')
  end
  f.puts("#{row}}")

  options.keys.each_with_index do |option, i|
    row = option
    if saturation_inclusions.include?(parameter)
      row += " & #{options[option]['sat']}"
    end
    changing_args.each_with_index do |changing_arg, _i|
      row += " & #{options[option][changing_arg]}"
    end
    row = "#{row} \\\\"
    if i < options.keys.size - 1
      row += ' \\hline'
    end
    f.puts(row)
  end
  f.puts('\end{customLongTable}')
end
