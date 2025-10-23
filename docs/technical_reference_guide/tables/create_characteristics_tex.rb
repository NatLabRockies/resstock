# frozen_string_literal: true

resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../../resources'))

require 'fileutils'
require_relative '../../resources/util'
require_relative File.join(resources_dir, 'hpxml-measures/BuildResidentialHPXML/resources/options')

filepath = File.read(File.join(resources_dir, 'hpxml-measures/BuildResidentialHPXML/measure.xml'))
buildreshpxmlarguments_xml = get_measure_xml(filepath)

filepath = File.read(File.join(resources_dir, '../measures/ResStockArguments/measure.xml'))
resstockarguments_xml = get_measure_xml(filepath)

arg_order = get_arg_order(buildreshpxmlarguments_xml, resstockarguments_xml)
properties_cols = get_properties_cols()

properties = get_properties(resources_dir)
options = get_options(resources_dir)

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

FileUtils.rm_rf(Dir.glob("#{properties_folder}/*"))
FileUtils.rm_rf(Dir.glob("#{options_folder}/*"))

source_report = CSV.read(File.join(File.dirname(__FILE__), '../../../project_national/resources/source_report.csv'), headers: true)
parameters = source_report.collect { |row| row['Parameter'] }

# Accommodate special "non-heat pump heating system" and "heat pump" options
parameters << 'HVAC Heating Efficiency - heating_system'
parameters << 'HVAC Heating Efficiency - heat_pump'

# Accommodate special "storage and tankless" and "solar" options
parameters << 'Water Heater Efficiency - water_heater'
parameters << 'Water Heater Efficiency - solar_thermal'

parameters.each do |parameter|
  parameter_name = parameter
  if parameter.include?('HVAC Heating Efficiency')
    parameter_name = 'HVAC Heating Efficiency'
  elsif parameter.include?('Water Heater Efficiency')
    parameter_name = 'Water Heater Efficiency'
  end

  r_arguments = []
  lookup_csv_data.each do |lookup_row|
    next if lookup_row[0] != parameter_name
    next if lookup_row[2] != 'ResStockArguments'

    lookup_row[3..-1].each do |argument_value|
      argument, _value = argument_value.split('=')

      if parameter.include?('heating_system')
        next unless argument.include?('heating_system')
      elsif parameter.include?('heat_pump')
        next unless argument.include?('heat_pump')
      elsif parameter.include?('water_heater')
        next unless argument.include?('water_heater')
      elsif parameter.include?('solar_thermal')
        # next unless argument.include?('solar_thermal') # intentionally include water_heater arguments with Solar Thermal options
      end

      r_arguments << argument if !r_arguments.include?(argument)
    end
  end

  r_arguments = r_arguments.sort_by &arg_order.method(:index)

  # Properties
  if r_arguments.any? && !parameter.include?('heating_system') && !parameter.include?('heat_pump') && !parameter.include?('water_heater') && !parameter.include?('solar_thermal')
    f = File.open(File.join(properties_folder, "#{parameter}.tex"), 'w')

    f.puts('\begin{customLongTable}{ |p{5cm}|p{3cm}|p{7cm}| }')
    f.puts("{The ResStock properties set in the #{parameter} characteristic} {table:hc_arg_def_#{parameter.downcase.gsub(' ', '_')}}")
    f.puts("{#{properties_cols.join(' & ')}}")

    r_arguments.each do |r_argument|
      if properties.keys.include?(r_argument)
        properties[r_argument].each do |property_name, property_unit_comment|
          name = "\\texttt{#{property_name}}".gsub('_', '\_')
          units = property_unit_comment['property_unit'].gsub('$', '\$').gsub('#', '\#').gsub('^2', '\textsuperscript{2}').gsub('^3', '\textsuperscript{3}')
          description = property_unit_comment['comment_row'].gsub('%', '\\%').gsub('_', '\_').gsub('&', '\\\&')
          row = "#{name} & #{units} & #{description}  \\\\"
          if property_name != properties[r_argument].keys[-1]
            row += ' \\hline'
          end
          f.puts(row)
        end
      else
        name = "\\texttt{#{r_argument}}".gsub('_', '\_')
        units = resstockarguments_xml[r_argument]['units'].gsub('$', '\$').gsub('#', '\#').gsub('^2', '\textsuperscript{2}').gsub('^3', '\textsuperscript{3}')
        description = resstockarguments_xml[r_argument]['description'].gsub('%', '\\%').gsub('_', '\_').gsub('&', '\\\&')
        row = "#{name} & #{units} & #{description}  \\\\"
        if r_argument != r_arguments[-1]
          row += ' \\hline'
        end
        f.puts(row)
      end
    end
    f.puts('\end{customLongTable}')
  end

  # Options
  next if parameter.end_with?('HVAC Heating Efficiency')
  next if parameter.end_with?('Water Heater Efficiency')

  f = File.open(File.join(options_folder, "#{parameter}.tex"), 'w')

  # Options and stock saturation
  lookup = {}
  option_sat_csv_data.each do |param_option_row|
    # If the parameter does not match next
    next if param_option_row[1] != parameter_name

    # Insert the options and the stock saturation
    option = param_option_row[2]

    if parameter.include?('heating_system')
      next if option.include?('HP,')
      next if option.include?('Shared Heating')
    elsif parameter.include?('heat_pump')
      next unless option.include?('HP,')
    elsif parameter.include?('water_heater')
      next if option.include?('Solar Thermal,')
    elsif parameter.include?('solar_thermal')
      next unless option.include?('Solar Thermal,')
    elsif parameter == 'HVAC Cooling Efficiency'
      next if ['Shared Cooling'].include?(option)
    elsif parameter == 'HVAC Shared Efficiencies'
      next if ['Fan Coil Cooling Only', 'None'].include?(option)
    elsif ['Dishwasher', 'Clothes Washer', 'Clothes Dryer'].include?(parameter) # options table may be too wide
      next if option.include?('None')
    elsif ['Misc Hot Tub Spa'].include?(parameter) # options table may be too wide
      next if option.include?('None')
      next if option.include?('Other Fuel')
    end

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
    next unless !r_arguments.empty?

    # If there are arguments, go through options lookup to find the option
    lookup_csv_data.each do |lookup_row|
      next if lookup_row[0] != parameter_name
      next if lookup_row[1] != option
      next if lookup_row[2] != 'ResStockArguments'

      lookup_row[3..-1].each do |argument_value|
        arg, value = argument_value.split('=')

        lookup[option][arg] = value
      end
    end
  end

  max_options = 4
  if lookup.keys.size > max_options
    puts "Warning: #{parameter} options #{lookup.keys.size} / #{max_options}"
  end

  row = '\begin{customLongTable}{ |p{5cm}'
  lookup.keys.each do |_option_name|
    row += '|p{2.5cm}'
  end

  f.puts("#{row}| }")

  caption = "{#{parameter_name}"
  if parameter.include?('heating_system')
    caption += ' non-heat pump heating system'
  elsif parameter.include?('heat_pump')
    caption += ' heat pump'
  elsif parameter.include?('water_heater')
    caption += ' storage and tankless'
  elsif parameter.include?('solar_thermal')
    caption += ' solar thermal'
  end
  caption += " options and properties that vary for each option} {table:hc_opt_#{parameter.downcase.gsub(' ', '_')}}"
  f.puts(caption)

  row = '{Option name'
  lookup.keys.each do |option_name|
    row += " & #{option_name}".gsub('^2', '\textsuperscript{2}').gsub('%', '\\%').gsub('<', '\textless') # Door Area, Partial Space Conditioning
  end
  f.puts("#{row}}")

  if saturation_inclusions.include?(parameter_name)
    row = 'Stock saturation'
    lookup.keys.each do |option|
      row += " & #{lookup[option]['sat']}"
    end
    f.puts("#{row} \\\\ \\hline")
  end

  r_arguments.each do |r_argument|
    if properties.keys.include?(r_argument)
      properties[r_argument].keys.each do |arg|
        row = ["\\texttt{#{arg}}".gsub('_', '\_')]

        lookup.keys.each do |option|
          option_name = lookup[option][r_argument]

          if not option_name.nil?
            options[r_argument][option_name].each do |arg2, value|
              next if arg != arg2

              row << value
            end
          else
            row << ''
          end
        end
        row = "#{row.join(' & ')} \\\\"
        if arg != properties[r_argument].keys[-1]
          row += ' \\hline'
        end
        f.puts(row)
      end
    else
      row = "\\texttt{#{r_argument}}".gsub('_', '\_')
      lookup.keys.each do |option|
        row += " & #{lookup[option][r_argument]}"
      end
      row += ' \\\\'
      if r_argument != r_arguments[-1]
        row += ' \\hline'
      end
      f.puts(row)
    end
  end
  f.puts('\end{customLongTable}')
end
