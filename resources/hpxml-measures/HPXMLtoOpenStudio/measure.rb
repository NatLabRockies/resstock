# frozen_string_literal: true

# Require all gems upfront; this is much faster than multiple resource
# files lazy loading as needed, as it prevents multiple lookups for the
# same gem.
require 'pathname'
require 'csv'
require 'oga'
Dir["#{File.dirname(__FILE__)}/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end

# start the measure
class HPXMLtoOpenStudio < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'HPXML to OpenStudio Translator'
  end

  # human readable description
  def description
    return 'Translates HPXML file to OpenStudio Model'
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # Define the arguments that the user will input.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [OpenStudio::Measure::OSArgumentVector] an OpenStudio::Measure::OSArgumentVector object
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', true)
    arg.setDisplayName('HPXML File Path')
    arg.setDescription('Absolute/relative path of the HPXML file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('output_dir', true)
    arg.setDisplayName('Directory for Output Files')
    arg.setDescription('Absolute/relative path for the output files directory.')
    args << arg

    format_chs = OpenStudio::StringVector.new
    format_chs << 'csv'
    format_chs << 'json'
    format_chs << 'msgpack'
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('output_format', format_chs, false)
    arg.setDisplayName('Output Format')
    arg.setDescription('The file format of the HVAC design load details output.')
    arg.setDefaultValue('csv')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('annual_output_file_name', false)
    arg.setDisplayName('Annual Output File Name')
    arg.setDescription("The name of the file w/ HVAC design loads and capacities. If not provided, defaults to 'results_annual.csv' (or '.json' or '.msgpack').")
    arg.setDefaultValue('results_annual')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('electric_panel_output_file_name', false)
    arg.setDisplayName('Electric Panel Output File Name')
    arg.setDescription("The name of the file w/ electric panel outputs. If not provided, defaults to 'results_panel.csv' (or '.json' or '.msgpack').")
    arg.setDefaultValue('results_panel')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('design_load_details_output_file_name', false)
    arg.setDisplayName('Design Load Details Output File Name')
    arg.setDescription("The name of the file w/ additional HVAC design load details. If not provided, defaults to 'results_design_load_details.csv' (or '.json' or '.msgpack').")
    arg.setDefaultValue('results_design_load_details')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('add_component_loads', false)
    arg.setDisplayName('Add component loads?')
    arg.setDescription('If true, adds the calculation of heating/cooling component loads (not enabled by default for faster performance).')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('building_id', false)
    arg.setDisplayName('BuildingID')
    arg.setDescription('The ID of the HPXML Building. Only required if the HPXML has multiple Building elements and WholeSFAorMFBuildingSimulation is not true.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('skip_validation', false)
    arg.setDisplayName('Skip Validation?')
    arg.setDescription('If true, bypasses HPXML input validation for faster performance. WARNING: This should only be used if the supplied HPXML file has already been validated against the Schema & Schematron documents.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('debug', false)
    arg.setDisplayName('Debug Mode?')
    arg.setDescription('If true: 1) Writes in.osm file, 2) Generates additional log output, and 3) Creates all EnergyPlus output files.')
    arg.setDefaultValue(false)
    args << arg

    return args
  end

  # Define what happens when the measure is run.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param user_arguments [OpenStudio::Measure::OSArgumentMap] OpenStudio measure arguments
  # @return [Boolean] true if successful
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    Version.check_openstudio_version()
    Model.reset(runner, model)

    args = runner.getArgumentValues(arguments(model), user_arguments)
    set_file_paths(args)

    begin
      hpxml = create_hpxml_object(runner, args)
      return false unless hpxml.errors.empty?

      # Do these once upfront for the entire HPXML object
      weather = process_weather(runner, hpxml, args)
      process_whole_sfa_mf_inputs(hpxml)
      hpxml_sch_map, design_loads_results_out = process_defaults_schedules_emissions_files(runner, weather, hpxml, args)

      # Write updated HPXML object (w/ defaults) to file for inspection
      XMLHelper.write_file(hpxml.to_doc, args[:hpxml_defaults_path])

      # Create OpenStudio unit model(s)
      hpxml_osm_map = {}
      hpxml.buildings.each do |hpxml_bldg|
        # Create the model for this single unit
        # If we're running a whole SFA/MF building, all the unit models will be merged later
        if hpxml.buildings.size > 1
          unit_model = OpenStudio::Model::Model.new
          create_unit_model(hpxml, hpxml_bldg, runner, unit_model, weather, hpxml_sch_map[hpxml_bldg])
          hpxml_osm_map[hpxml_bldg] = unit_model
        else
          create_unit_model(hpxml, hpxml_bldg, runner, model, weather, hpxml_sch_map[hpxml_bldg])
          hpxml_osm_map[hpxml_bldg] = model
        end
      end

      # Merge unit models into final model
      if hpxml.buildings.size > 1
        Model.merge_unit_models(model, hpxml_osm_map)
      end

      # Create EnergyPlus outputs
      Outputs.apply_ems_programs(model, hpxml_osm_map, hpxml.header, args[:add_component_loads])
      Outputs.apply_output_file_controls(model, args[:debug])
      Outputs.apply_additional_properties(model, hpxml, hpxml_osm_map, args[:hpxml_path], args[:building_id], args[:hpxml_defaults_path])
      Outputs.create_custom_meters(model)
      # Outputs.apply_ems_debug_output(model) # Uncomment to debug EMS

      # Write output files
      Outputs.write_debug_files(runner, model, weather, args[:debug], args[:output_dir])

      # Write annual results output file
      # This is helpful if the user wants to get these results right away (e.g.,
      # they might be using the run_simulation.rb --skip-simulation argument).
      annual_results_out = []
      Outputs.append_sizing_results(hpxml.buildings, annual_results_out)
      Outputs.write_results_out_to_file(annual_results_out, args[:output_format], args[:annual_output_file_path])

      # Write electric panel output file as needed
      electric_panel_results_out = Outputs.get_panel_results(hpxml.header, hpxml.buildings)
      if not electric_panel_results_out.empty?
        Outputs.write_results_out_to_file(electric_panel_results_out, args[:output_format], args[:electric_panel_output_file_path])
      end

      # Write design load details output file
      HVACSizing.write_detailed_output(design_loads_results_out, args[:output_format], args[:design_load_details_output_file_path])
    rescue Exception => e
      runner.registerError("#{e.message}\n#{e.backtrace.join("\n")}")
      return false
    end

    return true
  end

  # Updates the args hash with final paths for various input/output files.
  #
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def set_file_paths(args)
    if not (Pathname.new args[:hpxml_path]).absolute?
      args[:hpxml_path] = File.expand_path(args[:hpxml_path])
    end
    if not File.exist?(args[:hpxml_path]) && args[:hpxml_path].downcase.end_with?('.xml')
      fail "'#{args[:hpxml_path]}' does not exist or is not an .xml file."
    end

    if not (Pathname.new args[:output_dir]).absolute?
      args[:output_dir] = File.expand_path(args[:output_dir])
    end

    if File.extname(args[:annual_output_file_name]).length == 0
      args[:annual_output_file_name] = "#{args[:annual_output_file_name]}.#{args[:output_format]}"
    end
    args[:annual_output_file_path] = File.join(args[:output_dir], args[:annual_output_file_name])

    if File.extname(args[:electric_panel_output_file_name]).length == 0
      args[:electric_panel_output_file_name] = "#{args[:electric_panel_output_file_name]}.#{args[:output_format]}"
    end
    args[:electric_panel_output_file_path] = File.join(args[:output_dir], args[:electric_panel_output_file_name])

    if File.extname(args[:design_load_details_output_file_name]).length == 0
      args[:design_load_details_output_file_name] = "#{args[:design_load_details_output_file_name]}.#{args[:output_format]}"
    end
    args[:design_load_details_output_file_path] = File.join(args[:output_dir], args[:design_load_details_output_file_name])

    args[:hpxml_defaults_path] = File.join(args[:output_dir], 'in.xml')
  end

  # Creates the HPXML object from the HPXML file. Performs schema/schematron validation
  # as appropriate.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param args [Hash] Map of :argument_name => value
  # @return [HPXML] HPXML object
  def create_hpxml_object(runner, args)
    if args[:skip_validation]
      schema_validator = nil
      schematron_validator = nil
    else
      schema_path = File.join(File.dirname(__FILE__), 'resources', 'hpxml_schema', 'HPXML.xsd')
      schema_validator = XMLValidator.get_xml_validator(schema_path)
      schematron_path = File.join(File.dirname(__FILE__), 'resources', 'hpxml_schematron', 'EPvalidator.sch')
      schematron_validator = XMLValidator.get_xml_validator(schematron_path)
    end

    hpxml = HPXML.new(hpxml_path: args[:hpxml_path], schema_validator: schema_validator, schematron_validator: schematron_validator, building_id: args[:building_id])
    hpxml.errors.each do |error|
      runner.registerError(error)
    end
    hpxml.warnings.each do |warning|
      runner.registerWarning(warning)
    end
    return hpxml
  end

  # Returns the WeatherFile object.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml [HPXML] HPXML object
  # @param args [Hash] Map of :argument_name => value
  # @return [WeatherFile> Weather object containing EPW information
  def process_weather(runner, hpxml, args)
    epw_path = Location.get_epw_path(hpxml.buildings[0], args[:hpxml_path])
    weather = WeatherFile.new(epw_path: epw_path, runner: runner)
    hpxml.buildings.each_with_index do |hpxml_bldg, i|
      next if i == 0
      next if Location.get_epw_path(hpxml_bldg, args[:hpxml_path]) == epw_path

      fail 'Weather station EPW filepath has different values across dwelling units.'
    end

    return weather
  end

  # Performs error-checking on the inputs for whole SFA/MF building simulations.
  #
  # @param hpxml [HPXML] HPXML object
  # @return [nil]
  def process_whole_sfa_mf_inputs(hpxml)
    if hpxml.header.whole_sfa_or_mf_building_sim && (hpxml.buildings.size > 1)
      if hpxml.buildings.map { |hpxml_bldg| hpxml_bldg.batteries.size }.sum > 0
        # FUTURE: Figure out how to allow this. If we allow it, update docs and hpxml_translator_test.rb too.
        # Batteries use "TrackFacilityElectricDemandStoreExcessOnSite"; to support modeling of batteries in whole
        # SFA/MF building simulations, we'd need to create custom meters with electricity usage *for each unit*
        # and switch to "TrackMeterDemandStoreExcessOnSite".
        # https://github.com/NREL/OpenStudio-HPXML/issues/1499
        fail 'Modeling batteries for whole SFA/MF buildings is not currently supported.'
      end
    end
  end

  # Processes HPXML defaults, schedules, and emissions files upfront.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param hpxml [HPXML] HPXML object
  # @param args [Hash] Map of :argument_name => value
  # @return [Array<Hash, Array>] Maps of HPXML Building => SchedulesFile object, Rows of design loads output data
  def process_defaults_schedules_emissions_files(runner, weather, hpxml, args)
    hpxml_sch_map = {}
    hpxml_all_zone_loads = {}
    hpxml_all_space_loads = {}
    hpxml.buildings.each_with_index do |hpxml_bldg, i|
      # Schedules file
      Schedule.check_schedule_references(hpxml_bldg.header, args[:hpxml_path])
      in_schedules_csv = i > 0 ? "in.schedules#{i + 1}.csv" : 'in.schedules.csv'
      schedules_file = SchedulesFile.new(runner: runner,
                                         schedules_paths: hpxml_bldg.header.schedules_filepaths,
                                         year: Location.get_sim_calendar_year(hpxml.header.sim_calendar_year, weather),
                                         unavailable_periods: hpxml.header.unavailable_periods,
                                         output_path: File.join(args[:output_dir], in_schedules_csv),
                                         offset_db: hpxml.header.hvac_onoff_thermostat_deadband)
      hpxml_sch_map[hpxml_bldg] = schedules_file

      # HPXML defaults
      all_zone_loads, all_space_loads = Defaults.apply(runner, hpxml, hpxml_bldg, weather, schedules_file: schedules_file)
      hpxml_all_zone_loads[hpxml_bldg] = all_zone_loads
      hpxml_all_space_loads[hpxml_bldg] = all_space_loads
    end

    # Emissions files
    Schedule.check_emissions_references(hpxml.header, args[:hpxml_path])
    Schedule.validate_emissions_files(hpxml.header)

    # Compile design load outputs for subsequent writing
    # This needs to come before we collapse enclosure surfaces
    design_loads_results_out = []
    hpxml.buildings.each do |hpxml_bldg|
      HVACSizing.append_detailed_output(args[:output_format], hpxml_bldg, hpxml_all_zone_loads[hpxml_bldg],
                                        hpxml_all_space_loads[hpxml_bldg], design_loads_results_out)
    end

    return hpxml_sch_map, design_loads_results_out
  end

  # Creates a full OpenStudio model that represents the given HPXML individual dwelling by
  # adding OpenStudio objects to the empty OpenStudio model for each component of the building.
  #
  # @param hpxml [HPXML] HPXML object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def create_unit_model(hpxml, hpxml_bldg, runner, model, weather, schedules_file)
    init(model, hpxml_bldg, hpxml.header)
    SimControls.apply(model, hpxml.header)
    Location.apply(model, weather, hpxml_bldg, hpxml.header)

    # Conditioned space & setpoints
    spaces = {} # Map of HPXML locations => OpenStudio Space objects
    Geometry.create_or_get_space(model, spaces, HPXML::LocationConditionedSpace, hpxml_bldg)
    hvac_days = HVAC.apply_setpoints(runner, model, weather, spaces, hpxml_bldg, hpxml.header, schedules_file)

    # Geometry & Enclosure
    Geometry.apply_foundation_and_walls_top(hpxml_bldg)
    Geometry.apply_roofs(runner, model, spaces, hpxml_bldg, hpxml.header)
    Geometry.apply_walls(runner, model, spaces, hpxml_bldg, hpxml.header)
    Geometry.apply_rim_joists(runner, model, spaces, hpxml_bldg)
    Geometry.apply_floors(runner, model, spaces, hpxml_bldg, hpxml.header)
    Geometry.apply_foundation_walls_slabs(runner, model, spaces, weather, hpxml_bldg, hpxml.header, schedules_file)
    Geometry.apply_windows(model, spaces, hpxml_bldg, hpxml.header)
    Geometry.apply_doors(model, spaces, hpxml_bldg)
    Geometry.apply_skylights(model, spaces, hpxml_bldg, hpxml.header)
    Geometry.apply_conditioned_floor_area(model, spaces, hpxml_bldg)
    Geometry.apply_thermal_mass(model, spaces, hpxml_bldg, hpxml.header)
    Geometry.set_zone_volumes(spaces, hpxml_bldg, hpxml.header)
    Geometry.explode_surfaces(model, hpxml_bldg)
    Geometry.apply_building_unit(model, hpxml, hpxml_bldg)

    # HVAC
    airloop_map = HVAC.apply_hvac_systems(runner, model, weather, spaces, hpxml_bldg, hpxml.header, schedules_file, hvac_days)
    HVAC.apply_dehumidifiers(runner, model, spaces, hpxml_bldg, hpxml.header)
    HVAC.apply_ceiling_fans(runner, model, spaces, weather, hpxml_bldg, hpxml.header, schedules_file)

    # Hot Water & Appliances
    Waterheater.apply_dhw_appliances(runner, model, weather, spaces, hpxml_bldg, hpxml.header, schedules_file)

    # Lighting
    Lighting.apply(runner, model, spaces, hpxml_bldg, hpxml.header, schedules_file)

    # MiscLoads, Pools/Spas
    MiscLoads.apply_plug_loads(runner, model, spaces, hpxml_bldg, hpxml.header, schedules_file)
    MiscLoads.apply_fuel_loads(runner, model, spaces, hpxml_bldg, hpxml.header, schedules_file)
    MiscLoads.apply_pools_and_permanent_spas(runner, model, spaces, hpxml_bldg, hpxml.header, schedules_file)

    # Internal Gains
    InternalGains.apply_building_occupants(runner, model, hpxml_bldg, hpxml.header, spaces, schedules_file)
    InternalGains.apply_general_water_use(runner, model, hpxml_bldg, hpxml.header, spaces, schedules_file)

    # Airflow (e.g., ducts, infiltration, ventilation)
    Airflow.apply(runner, model, weather, spaces, hpxml_bldg, hpxml.header, schedules_file, airloop_map)

    # Other
    PV.apply(runner, model, hpxml_bldg)
    Generator.apply(model, hpxml_bldg)
    Battery.apply(runner, model, spaces, hpxml_bldg, schedules_file)
    Vehicle.apply(runner, model, spaces, hpxml_bldg, hpxml.header, schedules_file)
  end

  # Miscellaneous logic that needs to occur upfront.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def init(model, hpxml_bldg, hpxml_header)
    # Here we turn off OS error-checking so that any invalid values provided
    # to OS SDK methods are passed along to EnergyPlus and produce errors. If
    # we didn't go this, we'd end up with successful EnergyPlus simulations that
    # use the wrong (default) value unless we check the return value of *every*
    # OS SDK setter method to notice there was an invalid value provided.
    # See https://github.com/NREL/OpenStudio/pull/4505 for more background.
    model.setStrictnessLevel('None'.to_StrictnessLevel)

    # Store the fraction of windows operable before we collapse surfaces
    hpxml_bldg.additional_properties.initial_frac_windows_operable = hpxml_bldg.fraction_of_windows_operable()

    # Make adjustments for modeling purposes
    hpxml_bldg.collapse_enclosure_surfaces() # Speeds up simulation
    hpxml_bldg.delete_adiabatic_subsurfaces() # EnergyPlus doesn't allow this

    # Hidden feature: Version of the ANSI/RESNET/ICC 301 Standard to use for equations/assumptions
    if hpxml_header.eri_calculation_versions.size > 1
      fail 'Only a single ERI version is supported.'
    end

    if hpxml_header.eri_calculation_versions.empty?
      hpxml_header.eri_calculation_versions = ['latest']
    end

    # Hidden feature: Whether to override certain assumptions to better match the ASHRAE 140 specification
    if hpxml_header.apply_ashrae140_assumptions.nil?
      hpxml_header.apply_ashrae140_assumptions = false
    end
  end
end

# register the measure to be used by the application
HPXMLtoOpenStudio.new.registerWithApplication
