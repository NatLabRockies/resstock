# frozen_string_literal: true

resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../../resources'))
characteristics_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../../project_national/housing_characteristics'))

require 'fileutils'
require_relative '../../resources/util'
require_relative File.join(resources_dir, 'buildstock')
require_relative File.join(resources_dir, 'hpxml-measures/BuildResidentialHPXML/resources/options')

def write_subsection(folder, parameter, field, _name)
  f = File.open(File.join(folder, "#{parameter}.tex"), 'w')
  # f.puts("\\paragraph{#{name}}")
  f.puts('\begin{itemize}')
  items = field.split(';').map(&:strip)
  items.each_with_index do |item, i|
    item = item.gsub('%', '\\%')

    if item.start_with?(/\[\d+\]/)
      if not items[i - 1].start_with?(/\[\d+\]/)
        f.puts('  \begin{itemize}')
      end
      f.puts("  \\item #{item.gsub(/\[\d+\]/, '').strip}")
      if (i == items.size - 1) || (not items[i + 1].start_with?(/\[\d+\]/))
        f.puts('  \end{itemize}')
      end
    else
      f.puts("\\item #{item}")
    end
  end
  f.puts('\end{itemize}')
end

@subsections_name_map = { 'description' => 'Description',
                          'sources' => 'Distribution Sources',
                          'dependencies' => 'Direct Conditional Dependencies',
                          'options' => 'Options',
                          'properties' => 'Properties',
                          'assumptions' => 'Distribution Assumptions' }

def create_parent_characteristics_file(parameter)
  return # Comment this out, and re-run script, if you want to remove manually added text
  f = File.open(File.join(File.dirname(__FILE__), "#{parameter}.tex"), 'w')
  @subsections_name_map.each do |folder, subsection|
    f.puts("\\paragraph{#{subsection}}")
    f.puts("\\input{characteristics/#{folder}/#{parameter}}")
    f.puts
  end
end

filepath = File.read(File.join(resources_dir, 'hpxml-measures/BuildResidentialHPXML/measure.xml'))
buildreshpxmlarguments_xml = get_measure_xml(filepath)

filepath = File.read(File.join(resources_dir, '../measures/ResStockArguments/measure.xml'))
resstockarguments_xml = get_measure_xml(filepath)

arg_order = get_arg_order(buildreshpxmlarguments_xml, resstockarguments_xml)
properties_cols = get_properties_cols()

properties = get_properties(resources_dir)
options = get_options(resources_dir)

source_report_cols = get_source_report_cols()

lookup_csv_data, option_sat_csv_data = get_lookup_and_saturations_csv_data(resources_dir)

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
                         'Vintage ACS',
                         'Insulation Rim Joist',
                         'Misc Gas Lighting',
                         'HVAC Shared Efficiencies'] # include "Stock saturation" column for options tables

properties_folder = File.join(File.dirname(__FILE__), 'properties')
options_folder = File.join(File.dirname(__FILE__), 'options')
description_folder = File.join(File.dirname(__FILE__), 'description')
distribution_sources_folder = File.join(File.dirname(__FILE__), 'sources')
direct_conditional_dependencies_folder = File.join(File.dirname(__FILE__), 'dependencies')
distribution_assumptions_folder = File.join(File.dirname(__FILE__), 'assumptions')

FileUtils.rm_rf(Dir.glob("#{properties_folder}/*"))
FileUtils.rm_rf(Dir.glob("#{options_folder}/*"))

max_options_per_table = 3
max_options_total = 56

source_report = CSV.read(File.join(File.dirname(__FILE__), '../../../project_national/resources/source_report.csv'), headers: true)
source_report.each do |row|
  parameter = row['Parameter']

  create_parent_characteristics_file(parameter)

  source_report_cols.each do |subsection_name|
    next if subsection_name == 'Created by'

    if subsection_name == 'Description'
      f = File.open(File.join(description_folder, "#{parameter}.tex"), 'w')
      # f.puts("\paragraph{#{subsections_name_map['description']}}")
      f.puts(row['Description'])
    elsif subsection_name == 'Source'
      break if row['Source'].nil?

      write_subsection(distribution_sources_folder, parameter, row['Source'], @subsections_name_map['sources'])
    elsif subsection_name == 'Assumption'
      break if row['Assumption'].nil?

      write_subsection(distribution_assumptions_folder, parameter, row['Assumption'], @subsections_name_map['assumptions'])
    end
  end

  tsvfile = TsvFile.new(File.join(characteristics_dir, parameter + '.tsv'), nil)
  write_subsection(direct_conditional_dependencies_folder, parameter, tsvfile.dependency_cols.keys.join(';'), @subsections_name_map['dependencies'])

  r_arguments = []
  lookup_csv_data.each do |lookup_row|
    next if lookup_row[0] != parameter
    next if lookup_row[2] != 'ResStockArguments'

    lookup_row[3..-1].each do |argument_value|
      argument, _value = argument_value.split('=')
      r_arguments << argument if !r_arguments.include?(argument)
    end
  end

  r_arguments = r_arguments.sort_by &arg_order.method(:index)

  # Options and stock saturation
  lookup = {}
  option_sat_csv_data.each do |param_option_row|
    # If the parameter does not match next
    next if param_option_row[1] != parameter

    # Insert the options and the stock saturation
    option = param_option_row[2]

    next if option == 'Void'

    lookup[option] = {}

    sat_percent = Float(param_option_row[3]) * 100.0
    if Integer(sat_percent.truncate()) == 100
      sat_percent = '%.3g%%' % [sat_percent]
    else
      sat_percent = '%.2g%%' % [sat_percent]
    end

    lookup[option]['sat'] = "#{sat_percent}".gsub('%', '\\%')

    # Check if there are arguments
    next if r_arguments.empty?

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

  m_args = []
  if lookup.keys.size > max_options_total
    puts "Error: #{parameter} options #{lookup.keys.size} greater than max allowed of #{max_options_total}; skipping"
  else
    if lookup.keys.size > max_options_per_table
      puts "Warning: #{parameter} options #{lookup.keys.size} greater than max per table of #{max_options_per_table}; extending the table vertically"
    end

    # Options
    f = File.open(File.join(options_folder, "#{parameter}.tex"), 'w')

    option_sets = lookup.keys.each_slice(max_options_per_table).to_a
    option_sets.each_with_index do |lookup_keys, i|
      args = {}
      r_arguments.each do |r_argument|
        if properties.keys.include?(r_argument)
          properties[r_argument].keys.each do |arg|
            args[arg] = []

            lookup_keys.each do |option|
              option_name = lookup[option][r_argument]

              if not option_name.nil?
                options[r_argument][option_name].each do |arg2, value|
                  next if arg != arg2

                  args[arg] << value
                end
              else
                args[arg] << nil
              end
            end
          end
        else
          args[r_argument] = []
          lookup_keys.each do |option|
            args[r_argument] << lookup[option][r_argument]
          end
        end
      end

      args.delete_if { |_k, v| v.all?(&:nil?) }

      if i == 0
        row = '\begin{customLongTable}{ |p{5cm}'

        lookup_keys.each do |_option_name|
          row += '|p{3cm}'
        end

        f.puts("#{row}| }")

        caption = "{#{parameter} options and properties} {table:hc_opt_#{parameter.downcase.gsub(' ', '_')}}"
        f.puts(caption)

        row = ['Option name']
        lookup_keys.each do |option_name|
          row << "#{option_name}".gsub('^2', '\textsuperscript{2}').gsub('%', '\\%').gsub('<', '\textless') # Door Area, Partial Space Conditioning
        end
        f.puts("{#{row.join(' & ')}}")
        f.puts('\\endhead')
        f.puts('\\hline')
      else
        f.puts('\\hline')
        row = ['Option name']
        lookup_keys.each do |option_name|
          row << "#{option_name}".gsub('^2', '\textsuperscript{2}').gsub('%', '\\%').gsub('<', '\textless') # Door Area, Partial Space Conditioning
        end

        if (row.size < max_options_per_table + 1) && (i > 0)
          pad = max_options_per_table + 1 - row.size
          (1..pad).each do |_p|
            row << ''
          end
        end

        row = "#{row.join(' & ')} \\\\ \\hline"
        f.puts(row)
      end

      if saturation_inclusions.include?(parameter)
        row = 'Stock saturation'
        lookup_keys.each do |option|
          row += " & #{lookup[option]['sat']}"
        end
        f.puts("#{row} \\\\ \\hline")
      end

      args.each do |property, values|
        next if values.all?(&:nil?)

        row = ["\\texttt{#{property}}".gsub('_', '\_')]
        row += values

        if (row.size < max_options_per_table + 1) && (i > 0)
          pad = max_options_per_table + 1 - row.size
          (1..pad).each do |_p|
            row << ''
          end
        end

        row = "#{row.join(' & ')} \\\\"
        if (property != args.keys[-1]) || (i != option_sets.size - 1)
          row += ' \\hline'
        end
        f.puts(row)
      end

      args.keys.each do |k|
        m_args << k.to_s unless m_args.include?(k)
      end
    end # end option_sets.each_with_index do |lookup_keys, i|

    f.puts('\end{customLongTable}')

  end

  # Properties
  next unless r_arguments.any?

  f = File.open(File.join(properties_folder, "#{parameter}.tex"), 'w')

  f.puts('\begin{customLongTable}{ |p{5cm}|p{3cm}|p{7cm}| }')
  f.puts("{The ResStock properties set in the #{parameter} characteristic} {table:hc_arg_def_#{parameter.downcase.gsub(' ', '_')}}")
  f.puts("{#{properties_cols.join(' & ')}}")
  rows = []
  r_arguments.each do |r_argument|
    if properties.keys.include?(r_argument)
      properties[r_argument].each do |property_name, property_unit_description|
        next unless m_args.include?(property_name)

        name = "\\texttt{#{property_name}}".gsub('_', '\_')
        units = property_unit_description['property_unit'].gsub('$', '\$').gsub('#', '\#').gsub('^2', '\textsuperscript{2}').gsub('^3', '\textsuperscript{3}')
        description = property_unit_description['description'].gsub('%', '\\%').gsub('_', '\_').gsub('&', '\\\&')
        rows << "#{name} & #{units} & #{description}"
      end
    else
      name = "\\texttt{#{r_argument}}".gsub('_', '\_')
      units = resstockarguments_xml[r_argument]['units'].gsub('$', '\$').gsub('#', '\#').gsub('^2', '\textsuperscript{2}').gsub('^3', '\textsuperscript{3}')
      description = resstockarguments_xml[r_argument]['description'].gsub('%', '\\%').gsub('_', '\_').gsub('&', '\\\&')
      rows << "#{name} & #{units} & #{description}"
    end
  end
  rows.each do |row|
    if row != rows[-1]
      f.puts("#{row} \\\\ \\hline")
    else
      f.puts("#{row} \\\\")
    end
  end
  f.puts('\end{customLongTable}')
end
