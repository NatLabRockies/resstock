# frozen_string_literal: true

require 'fileutils'
require_relative '../../resources/util'

resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../../resources'))

filepath = File.read(File.join(resources_dir, 'hpxml-measures/BuildResidentialHPXML/measure.xml'))
buildreshpxmlarguments_xml = get_measure_xml(filepath)

filepath = File.read(File.join(resources_dir, '../measures/ResStockArguments/measure.xml'))
resstockarguments_xml = get_measure_xml(filepath)

resstockarguments_xml.each do |name, properties|
  refine_resstockarguments_xml(resstockarguments_xml, buildreshpxmlarguments_xml, name, properties)
end

arg_order = get_arg_order(buildreshpxmlarguments_xml, resstockarguments_xml)
arguments_cols = get_arguments_cols()
lookup_csv_data, option_sat_csv_data = get_lookup_and_saturations_csv_data(resources_dir)

desc_exclusions = ['If not provided', 'If neither'] # skip these sentences in argument descriptions
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

arguments_folder = File.join(File.dirname(__FILE__), 'arguments')
options_folder = File.join(File.dirname(__FILE__), 'options')

FileUtils.rm_rf(Dir.glob("#{arguments_folder}/*"))
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

  # Arguments
  if r_arguments.any? && !parameter.include?('heating_system') && !parameter.include?('heat_pump') && !parameter.include?('water_heater') && !parameter.include?('solar_thermal')
    f = File.open(File.join(arguments_folder, "#{parameter}.tex"), 'w')

    f.puts('\begin{customLongTable}{ |p{3cm}|p{1.25cm}|p{1.5cm}|p{1.5cm}|p{3cm}|p{3.5cm}| }')
    f.puts("{The ResStock argument definitions set in the #{parameter} characteristic} {table:hc_arg_def_#{parameter.downcase.gsub(' ', '_')}}")
    f.puts("{#{arguments_cols.join(' & ')}}")
    r_arguments.each_with_index do |r_argument, i|
      name = "\\texttt{#{r_argument}}".gsub('_', '\_')
      required = resstockarguments_xml[r_argument]['required']
      units = resstockarguments_xml[r_argument]['units'].gsub('$', '\$').gsub('#', '\#').gsub('^2', '\textsuperscript{2}').gsub('^3', '\textsuperscript{3}')
      type = resstockarguments_xml[r_argument]['type']
      choices = resstockarguments_xml[r_argument]['choices'].join(', ').gsub('%', '\\%').gsub('&', '\\\&')
      description = resstockarguments_xml[r_argument]['description'].gsub('%', '\\%').gsub('_', '\_').gsub('&', '\\\&')
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
  next if parameter.end_with?('HVAC Heating Efficiency')
  next if parameter.end_with?('Water Heater Efficiency')

  f = File.open(File.join(options_folder, "#{parameter}.tex"), 'w')

  options = {}
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

    if not options.keys.include?(option)
      options[option] = {}
    end

    sat_percent = Float(param_option_row[3]) * 100.0
    if Integer(sat_percent.truncate()) == 100
      sat_percent = '%.3g%%' % [sat_percent]
    else
      sat_percent = '%.2g%%' % [sat_percent]
    end
    options[option]['sat'] = "#{sat_percent}".gsub('%', '\\%')

    # Check if there are arguments
    next unless !r_arguments.empty?

    # If there are arguments, go through options lookup to find the option
    lookup_csv_data.each do |lookup_row|
      next if lookup_row[0] != parameter_name
      next if lookup_row[1] != option

      next unless lookup_row[2] == 'ResStockArguments'

      # If option specifies arguments, insert arguments according to the order of r_arguments
      r_arguments.each do |argument|
        # Look for each argument in r_arguments
        lookup_row[3..-1].each do |argument_value|
          arg, value = argument_value.split('=')

          if parameter == 'HVAC Shared Efficiencies'
            next if arg.include?('cooling_system_')
          end

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
    if (vals.uniq.size != 1) || (vals.size == 1)
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
  changing_args.each do |changing_arg|
    if changing_arg.end_with?('setpoint_schedule') # increase column widths for XXX Setpoint Offset Period
      row += '|p{4.5cm}'
    elsif options.keys.include?('ASHP, SEER 10, 6.2 HSPF') # decrease column widths for HVAC Heating Efficiency - heat_pump
      row += '|p{2.25cm}'
    else
      row += '|p{2.75cm}'
    end
  end
  f.puts("#{row}| }")
  if parameter.include?('heating_system')
    f.puts("{#{parameter_name} non-heat pump heating system options and arguments that vary for each option} {table:hc_opt_#{parameter.downcase.gsub(' ', '_')}}")
  elsif parameter.include?('heat_pump')
    f.puts("{#{parameter_name} heat pump options and arguments that vary for each option} {table:hc_opt_#{parameter.downcase.gsub(' ', '_')}}")
  elsif parameter.include?('water_heater')
    f.puts("{#{parameter_name} storage and tankless options and arguments that vary for each option} {table:hc_opt_#{parameter.downcase.gsub(' ', '_')}}")
  elsif parameter.include?('solar_thermal')
    f.puts("{#{parameter_name} solar thermal options and arguments that vary for each option} {table:hc_opt_#{parameter.downcase.gsub(' ', '_')}}")
  else
    f.puts("{#{parameter_name} options and arguments that vary for each option} {table:hc_opt_#{parameter.downcase.gsub(' ', '_')}}")
  end

  row = '{Option name'
  if saturation_inclusions.include?(parameter_name)
    row += ' & Stock saturation'
  end
  changing_args.each do |changing_arg|
    row += " & \\texttt{#{changing_arg}}".gsub('_', '\_')
  end
  f.puts("#{row}}")

  options.keys.each_with_index do |option, i|
    row = option.gsub('^2', '\textsuperscript{2}').gsub('%', '\\%').gsub('<', '\textless') # Door Area, Partial Space Conditioning
    if saturation_inclusions.include?(parameter_name)
      row += " & #{options[option]['sat']}"
    end
    changing_args.each_with_index do |changing_arg, _i|
      row += " & #{options[option][changing_arg]}".gsub('%', '\\%')
    end
    row = "#{row} \\\\"
    if i < options.keys.size - 1
      row += ' \\hline'
    end
    f.puts(row)
  end
  f.puts('\end{customLongTable}')
end
