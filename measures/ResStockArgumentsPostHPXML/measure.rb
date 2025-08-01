# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# Load required dependencies for HVAC flexibility processing
require_relative 'resources/hvac_flexibility/detailed_schedule_generator'
require_relative 'resources/hvac_flexibility/setpoint_modifier'
require_relative 'resources/ev_flexibility/ev_schedule_modifier'

# OpenStudio Measure class to process ResStock arguments after HPXML generation
class ResStockArgumentsPostHPXML < OpenStudio::Measure::ModelMeasure
  # Define human readable name
  def name
    'ResStock Arguments Post-HPXML'
  end

  # Brief human readable description of the measure
  def description
    'Measure that post-processes the output of the BuildResidentialHPXML and BuildResidentialScheduleFile measures.'
  end

  # Detailed human readable description of modeling approach
  def modeler_description
    'Passes in all ResStockArgumentsPostHPXML arguments from the options lookup, processes them, and then modifies output of other measures.'
  end

  # Define user input arguments
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', false)
    arg.setDisplayName('HPXML File Path')
    arg.setDescription('Absolute/relative path of the HPXML file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('hvac_flex_peak_offset', false)
    arg.setDisplayName('HVAC Load Flexibility: Peak Offset (deg F)')
    arg.setDescription('Offset of the peak period in degrees Fahrenheit.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeDoubleArgument('hvac_flex_pre_peak_duration_hours', false)
    arg.setDisplayName('HVAC Load Flexibility: Pre-Peak Duration (hours)')
    arg.setDescription('Duration of the pre-peak period in hours.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('hvac_flex_pre_peak_offset', false)
    arg.setDisplayName('HVAC Load Flexibility: Pre-Peak Offset (deg F)')
    arg.setDescription('Offset of the pre-peak period in degrees Fahrenheit.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('flex_random_shift_minutes', false)
    arg.setDisplayName('Load Flexibility: Random Shift (minutes)')
    arg.setDescription('Number of minutes to randomly shift the peak period. If minutes is less than timestep, it will be assumed to be 0.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('ev_flex_enabled', false)
    arg.setDisplayName('EV Flexibility Enabled')
    arg.setDescription('Whether to enable EV flexibility.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('air_leakage_percent_reduction', false)
    arg.setDisplayName('Air Leakage: Value Reduction')
    arg.setDescription('Reduction (%) on the air exchange rate value.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('refrigerator_usage_multiplier', true)
    arg.setDisplayName('Appliances: Refrigerator Usage Multiplier')
    arg.setDescription('Multiplier on the refrigerator energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_dryer_usage_multiplier', true)
    arg.setDisplayName('Appliances: Clothes Dryer Usage Multiplier')
    arg.setDescription('Multiplier on the clothes dryer energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_usage_multiplier', true)
    arg.setDisplayName('Appliances: Clothes Washer Usage Multiplier')
    arg.setDescription('Multiplier on the clothes washer energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooking_range_oven_usage_multiplier', true)
    arg.setDisplayName('Appliances: Cooking Range/Oven Usage Multiplier')
    arg.setDescription('Multiplier on the cooking range/oven energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dishwasher_usage_multiplier', true)
    arg.setDisplayName('Appliances: Dishwasher Usage Multiplier')
    arg.setDescription('Multiplier on the dishwasher energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('extra_refrigerator_usage_multiplier', true)
    arg.setDisplayName('Appliances: Extra Refrigerator Usage Multiplier')
    arg.setDescription('Multiplier on the extra refrigerator energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('freezer_usage_multiplier', true)
    arg.setDisplayName('Appliances: Freezer Usage Multiplier')
    arg.setDescription('Multiplier on the freezer energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('misc_plug_loads_television_usage_multiplier', true)
    arg.setDisplayName('Plug Loads: Television Usage Multiplier')
    arg.setDescription('Multiplier on the television energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('misc_plug_loads_other_usage_multiplier', true)
    arg.setDisplayName('Plug Loads: Other Usage Multiplier')
    arg.setDescription('Multiplier on the other energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('bathroom_fans_start_hour', true)
    arg.setDisplayName('Ventilation: Bathroom Fans Start Hour')
    arg.setDescription('The hour of the day when the bathroom fans run.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('kitchen_fans_start_hour', true)
    arg.setDisplayName('Ventilation: Kitchen Fans Start Hour')
    arg.setDescription('The hour of the day when the kitchen fans run.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_vacancy_periods', false)
    arg.setDisplayName('Schedules: Vacancy Periods')
    arg.setDescription('Specifies the vacancy periods. Enter a date like "Dec 15 - Jan 15". Optionally, can enter hour of the day like "Dec 15 2 - Jan 15 20" (start hour can be 0 through 23 and end hour can be 1 through 24). If multiple periods, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('building_id', false)
    arg.setDisplayName('Building Unit ID')
    arg.setDescription('The building unit number (between 1 and the number of samples).')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ev_miles_driven_per_year', false)
    arg.setDisplayName('Electric Vehicle: Miles Driven Per Year')
    arg.setDescription('The annual miles the electric vehicle is driven.')
    arg.setUnits('miles')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ev_fraction_charged_home', false)
    arg.setDisplayName('Electric Vehicle: Fraction Charged at Home')
    arg.setDescription('The fraction of charging energy provided by the at-home charger to the electric vehicle.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ev_efficiency_percent_increase', false)
    arg.setDisplayName('Electric Vehicle: Efficiency Improvement')
    arg.setDescription('The increase (fraction) in efficiency of the electric vehicle.')
    arg.setUnits('Frac')
    args << arg

    return args
  end

  # Run the measure
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    @runner = runner
    # Use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    # Parse user arguments and assign to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)
    @args = args

    @hpxml_path = args[:hpxml_path]
    @hpxml_path = File.expand_path(@hpxml_path) unless (Pathname.new @hpxml_path).absolute?
    raise "'#{@hpxml_path}' does not exist or is not an .xml file." unless File.exist?(@hpxml_path) && @hpxml_path.downcase.end_with?('.xml')

    # Load HPXML
    @hpxml = HPXML.new(hpxml_path: @hpxml_path)

    # Usage Multipliers
    @hpxml.plug_loads.each do |plug_load|
      if plug_load.plug_load_type == HPXML::PlugLoadTypeTelevision
        plug_load.usage_multiplier *= args[:misc_plug_loads_television_2_usage_multiplier]
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeOther
        plug_load.usage_multiplier *= args[:misc_plug_loads_other_2_usage_multiplier]
      end
    end
    @hpxml.refrigerators.each do |refrigerator|
      if refrigerator.primary_indicator
        refrigerator.usage_multiplier *= args[:refrigerator_usage_multiplier]
      else
        refrigerator.usage_multiplier *= args[:extra_refrigerator_usage_multiplier]
      end
    end
    @hpxml.clothes_dryers.each do |clothes_dryer|
      clothes_dryer.usage_multiplier *= args[:clothes_dryer_usage_multiplier]
    end
    @hpxml.clothes_washers.each do |clothes_washer|
      clothes_washer.usage_multiplier *= args[:clothes_washer_usage_multiplier]
    end
    @hpxml.cooking_ranges.each do |cooking_range|
      cooking_range.usage_multiplier *= args[:cooking_range_oven_usage_multiplier]
    end
    @hpxml.dishwashers.each do |dishwasher|
      dishwasher.usage_multiplier *= args[:dishwasher_usage_multiplier]
    end
    @hpxml.freezers.each do |freezer|
      freezer.usage_multiplier *= args[:freezer_usage_multiplier]
    end

    # Ventilation Start Hours
    @hpxml.ventilation_fans.each do |ventilation_fan|
      next unless ventilation_fan.used_for_local_ventilation

      if ventilation_fan.fan_location == HPXML::LocationKitchen
        ventilation_fan.start_hour = args[:kitchen_fans_start_hour]
      elsif ventilation_fan.fan_location == HPXML::LocationBath
        ventilation_fan.start_hour = args[:bathroom_fans_start_hour]
      end
    end

    # Vacancy
    schedules_vacancy_periods = args[:schedules_vacancy_periods].split(',').map(&:strip)
    schedules_vacancy_periods.each do |schedule_vacancy_period|
      begin_month, begin_day, begin_hour, end_month, end_day, end_hour = Calendar.parse_date_time_range(schedule_vacancy_period)
      @hpxml.header.unavailable_periods.add(column_name: 'Vacancy',
                                            begin_month: begin_month,
                                            begin_day: begin_day,
                                            begin_hour: begin_hour,
                                            end_month: end_month,
                                            end_day: end_day,
                                            end_hour: end_hour)
    end

    # EVs
    @vehicles.each do |vehicle|
      next unless vehicle.vehicle_type == HPXML::VehicleTypeBEV

      if not args[:ev_efficiency_percent_increase].nil?
        # Adjust efficiency (in kWh/mile) to reflect a percentage improvement in efficiency.
        vehicle.fuel_economy_combined /= 1 + args[:ev_efficiency_percent_increase]
      end
      if not args[:ev_fraction_charged_home].nil?
        vehicle.fraction_charged_home = args[:ev_fraction_charged_home]
      end
      if not args[:ev_miles_driven_per_year].nil?
        vehicle.miles_per_year = args[:ev_miles_driven_per_year]
      end
    end

    # Infiltration Reduction
    if not args[:air_leakage_percent_reduction].nil?
      @hpxml.buildings.each do |hpxml_bldg|
        hpxml_bldg.air_infiltration_measurements.each do |air_infiltration_measurement|
          air_infiltration_measurement.air_leakage *= (1.0 - args[:air_leakage_percent_reduction] / 100.0)
        end
      end
      runner.registerInfo("Wrote file: #{@hpxml_path} with modified <AirLeakage>.")
    end

    if not skip_hvac_flexibility?(args)
      # define variables needed for hvac_flexibility adjustment
      output_csv_path = File.dirname(@hpxml_path)
      @prng = Random.new(args[:building_id].to_i)
      @minutes_per_step = @hpxml.header.timestep
      max_random_shift_steps = (args[:flex_random_shift_minutes] / @minutes_per_step).to_i
      @random_shift_steps = @prng.rand(-max_random_shift_steps..max_random_shift_steps)

      # Process each building
      doc_buildings.each_with_index do |building, index|
        hpxml_bldg = @hpxml.buildings[index]
        if hpxml_bldg.hvac_controls.to_a.length == 0
          runner.registerInfo("Skipping hvac flexibility for building #{index + 1} since it has no HVAC controls.")
          next
        end
        hvac_schedule = create_hvac_schedule(index)
        modified_schedule = modify_hvac_schedule(index, hvac_schedule)
        write_schedule(modified_schedule, building, index, output_csv_path)
      end
      runner.registerInfo("Wrote file: #{@hpxml_path} with modified schedules.")
    else
      runner.registerInfo('Skipping hvac flexibility since hvac_flex_peak_offset and hvac_flex_pre_peak_duration_hours are both 0')
    end

    # Write out the modified hpxml
    XMLHelper.write_file(@hpxml.to_doc(), @hpxml_path)
    return true
  end

  # Determines if HVAC flexibility modifications should be skipped
  # Skips if both peak offset and pre-peak duration are set to 0
  def skip_hvac_flexibility?(args)
    return true if args[:hvac_flex_peak_offset] == 0 && args[:hvac_flex_pre_peak_duration_hours] == 0
  end

  def skip_ev_flexibility?(args)
    return true if !args[:ev_flex_enabled]
  end

  def get_ev_schedule(hpxml_bldg)
    schedule_file = get_existing_schedule_filepath(hpxml_bldg)
    return if schedule_file.nil?

    schedule = CSV.read(schedule_file, headers: true)
    ev_schedule = {}
    ev_column = 'electric_vehicle'
    return unless schedule.headers.include?(ev_column)

    ev_schedule[ev_column.to_sym] = schedule[ev_column].map(&:to_f)
    return ev_schedule
  end

  # Generates the HVAC schedule for a given building index
  def create_hvac_schedule(building_index)
    generator = HVACScheduleGenerator.new(@hpxml, @hpxml_path, @runner, building_index)
    return generator.get_heating_cooling_setpoint_schedule
  end

  # Retrieves an appropriate schedule modifier for a given building
  def get_schedule_modifier(hpxml_bldg, modifier_class)
    # Ensure the provided class is a subclass of ScheduleModifier
    raise ArgumentError, "#{modifier_class} must be a subclass of ScheduleModifier" unless modifier_class < ScheduleModifier

    state = hpxml_bldg.state_code
    sim_year = @hpxml.header.sim_calendar_year
    epw_path = Location.get_epw_path(hpxml_bldg, @hpxml_path)
    weather = WeatherFile.new(epw_path: epw_path, runner: @runner)

    # Get daylight saving time information
    dst_info = DSTInfo.new(dst_begin_month: hpxml_bldg.dst_begin_month,
                           dst_begin_day: hpxml_bldg.dst_begin_day,
                           dst_end_month: hpxml_bldg.dst_end_month,
                           dst_end_day: hpxml_bldg.dst_end_day)

    # Create and return the modifier instance
    return modifier_class.new(state: state,
                              sim_year: sim_year,
                              weather: weather,
                              epw_path: epw_path,
                              minutes_per_step: @minutes_per_step,
                              runner: @runner,
                              dst_info: dst_info)
  end

  # Modifies the HVAC schedule based on flexibility inputs
  def modify_hvac_schedule(hpxml_bldg, schedule)
    hvac_schedule_modifier = get_schedule_modifier(hpxml_bldg, HVACScheduleModifier)

    # Define flexibility inputs
    hvac_flexibility_inputs = FlexibilityInputs.new(
      peak_offset: @args[:hvac_flex_peak_offset],
      pre_peak_duration_steps: (@args[:hvac_flex_pre_peak_duration_hours] * 60 / @minutes_per_step).to_i,
      pre_peak_offset: @args[:hvac_flex_pre_peak_offset],
      random_shift_steps: @random_shift_steps
    )

    # Apply modifications to the schedule
    return hvac_schedule_modifier.modify_shedule(schedule, hvac_flexibility_inputs)
  end

  def modify_ev_schedule(hpxml_bldg, schedule)
    ev_schedule_modifier = get_schedule_modifier(hpxml_bldg, EVScheduleModifier)
    ev_flexibility_inputs = FlexibilityInputs.new(
      peak_offset: 0,
      # Use hvac_flex_pre_peak_duration_hours so that shift/shed is the same as HVAC
      pre_peak_duration_steps: (@args[:hvac_flex_pre_peak_duration_hours] * 60 / @minutes_per_step).to_i,
      pre_peak_offset: 0,
      random_shift_steps: @random_shift_steps
    )
    return ev_schedule_modifier.modify_schedule(schedule, ev_flexibility_inputs)
  end

  # Writes the HVAC schedule to a CSV file
  def write_schedule(schedule, hpxml_bldg, index, output_csv_path)
    schedule_file = get_existing_schedule_filepath(hpxml_bldg)

    if schedule_file.nil?
      # Create a new schedule file if one does not exist
      schedule_file = File.join(output_csv_path, "schedule_#{index}.csv")
      CSV.open(schedule_file, 'w') do |csv|
        headers = schedule.keys.map(&:to_s)
        csv << headers
        row_count = schedule.values.first.length
        (0...row_count).each do |i|
          row = headers.map { |h| schedule[h.to_sym][i] }
          csv << row
        end
      end
      hpxml_bldg.header.schedules_filepaths << schedule_file
    else
      # Process existing schedule file and update values
      data = CSV.read(schedule_file, headers: true)
      headers = data.headers

      schedule.each do |column_name, values|
        string_column_name = column_name.to_s
        column_index = headers.index { |h| h.to_s == string_column_name }

        if column_index
          data.each_with_index do |row, i|
            row[column_index] = values[i]
          end
        else
          headers << string_column_name
          data.each_with_index do |row, i|
            row[string_column_name] = values[i]
          end
        end
      end

      # Write the updated schedule back to the CSV file
      CSV.open(schedule_file, 'w') do |csv|
        csv << headers
        data.each { |row| csv << row }
      end
    end

    return schedule_file
  end

  # Retrieves the existing schedule file path from the HPXML file
  def get_existing_schedule_filepath(hpxml_bldg)
    schedule_file = hpxml_bldg.header.schedules_filepaths.first
    return if schedule_file.nil?

    # Ensure the path is absolute
    if !Pathname.new(schedule_file).absolute?
      schedule_file = File.join(File.dirname(@hpxml_path), schedule_file)
    end
    return schedule_file
  end
end

# register the measure to be used by the application
ResStockArgumentsPostHPXML.new.registerWithApplication
