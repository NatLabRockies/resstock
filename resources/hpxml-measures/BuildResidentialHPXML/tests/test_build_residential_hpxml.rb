# frozen_string_literal: true

require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require_relative '../resources/options.rb'
require 'fileutils'

class BuildResidentialHPXMLTest < Minitest::Test
  def setup
    @output_path = File.join(File.dirname(__FILE__), 'extra_files')
    @model_save = false # true helpful for debugging, i.e., can render osm in 3D
  end

  def teardown
    FileUtils.rm_rf(@output_path) if !@model_save
  end

  def test_workflows
    # Extra buildings that don't correspond with sample files
    hpxmls_files = {
      # Base files to derive from
      'base-sfd.xml' => nil,
      'base-sfa.xml' => 'base-sfd.xml',
      'base-mf.xml' => 'base-sfd.xml',
      'base-sfd-header.xml' => 'base-sfd.xml',

      # Extra files to test
      'extra-pv-roofpitch.xml' => 'base-sfd.xml',
      'extra-dhw-solar-latitude.xml' => 'base-sfd.xml',
      'extra-second-heating-system-portable-heater-to-heating-system.xml' => 'base-sfd.xml',
      'extra-second-heating-system-fireplace-to-heating-system.xml' => 'base-sfd.xml',
      'extra-second-heating-system-boiler-to-heating-system.xml' => 'base-sfd.xml',
      'extra-second-heating-system-portable-heater-to-heat-pump.xml' => 'base-sfd.xml',
      'extra-second-heating-system-boiler-to-heat-pump.xml' => 'base-sfd.xml',
      'extra-enclosure-windows-shading.xml' => 'base-sfd.xml',
      'extra-enclosure-garage-partially-protruded.xml' => 'base-sfd.xml',
      'extra-enclosure-garage-atticroof-conditioned.xml' => 'base-sfd.xml',
      'extra-enclosure-atticroof-conditioned-eaves-gable.xml' => 'base-sfd.xml',
      'extra-enclosure-atticroof-conditioned-eaves-hip.xml' => 'extra-enclosure-atticroof-conditioned-eaves-gable.xml',
      'extra-seasons-building-america.xml' => 'base-sfd.xml',
      'extra-ducts-crawlspace.xml' => 'base-sfd.xml',
      'extra-ducts-attic.xml' => 'base-sfd.xml',
      'extra-water-heater-crawlspace.xml' => 'base-sfd.xml',
      'extra-water-heater-attic.xml' => 'base-sfd.xml',
      'extra-vehicle-ev.xml' => 'extra-enclosure-garage-partially-protruded.xml',
      'extra-two-batteries.xml' => 'base-sfd.xml',
      'extra-detailed-performance-autosize.xml' => 'base-sfd.xml',

      'extra-sfa-atticroof-flat.xml' => 'base-sfa.xml',
      'extra-sfa-atticroof-conditioned-eaves-gable.xml' => 'extra-sfa-slab.xml',
      'extra-sfa-atticroof-conditioned-eaves-hip.xml' => 'extra-sfa-atticroof-conditioned-eaves-gable.xml',
      'extra-mf-eaves.xml' => 'extra-mf-slab.xml',

      'extra-sfa-slab.xml' => 'base-sfa.xml',
      'extra-sfa-vented-crawlspace.xml' => 'base-sfa.xml',
      'extra-sfa-unvented-crawlspace.xml' => 'base-sfa.xml',
      'extra-sfa-conditioned-crawlspace.xml' => 'base-sfa.xml',
      'extra-sfa-unconditioned-basement.xml' => 'base-sfa.xml',
      'extra-sfa-ambient.xml' => 'base-sfa.xml',

      'extra-sfa-slab-middle.xml' => 'extra-sfa-slab.xml',
      'extra-sfa-slab-right.xml' => 'extra-sfa-slab.xml',
      'extra-sfa-vented-crawlspace-middle.xml' => 'extra-sfa-vented-crawlspace.xml',
      'extra-sfa-vented-crawlspace-right.xml' => 'extra-sfa-vented-crawlspace.xml',
      'extra-sfa-unvented-crawlspace-middle.xml' => 'extra-sfa-unvented-crawlspace.xml',
      'extra-sfa-unvented-crawlspace-right.xml' => 'extra-sfa-unvented-crawlspace.xml',
      'extra-sfa-unconditioned-basement-middle.xml' => 'extra-sfa-unconditioned-basement.xml',
      'extra-sfa-unconditioned-basement-right.xml' => 'extra-sfa-unconditioned-basement.xml',

      'extra-mf-atticroof-flat.xml' => 'base-mf.xml',
      'extra-mf-atticroof-vented.xml' => 'base-mf.xml',

      'extra-mf-slab.xml' => 'base-mf.xml',
      'extra-mf-vented-crawlspace.xml' => 'base-mf.xml',
      'extra-mf-unvented-crawlspace.xml' => 'base-mf.xml',
      'extra-mf-ambient.xml' => 'base-sfa.xml',

      'extra-mf-slab-left-bottom.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-left-middle.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-left-top.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-middle-bottom.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-middle-middle.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-middle-top.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-right-bottom.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-right-middle.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-right-top.xml' => 'extra-mf-slab.xml',
      'extra-mf-vented-crawlspace-left-bottom.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-left-middle.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-left-top.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-middle-bottom.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-middle-middle.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-middle-top.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-right-bottom.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-right-middle.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-right-top.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-left-bottom.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-left-middle.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-left-top.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-middle-bottom.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-middle-middle.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-middle-top.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-right-bottom.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-right-middle.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-right-top.xml' => 'extra-mf-unvented-crawlspace.xml',

      'extra-mf-slab-rear-units.xml' => 'extra-mf-slab.xml',
      'extra-mf-vented-crawlspace-rear-units.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-rear-units.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-slab-left-bottom-rear-units.xml' => 'extra-mf-slab-left-bottom.xml',
      'extra-mf-slab-left-middle-rear-units.xml' => 'extra-mf-slab-left-middle.xml',
      'extra-mf-slab-left-top-rear-units.xml' => 'extra-mf-slab-left-top.xml',
      'extra-mf-slab-middle-bottom-rear-units.xml' => 'extra-mf-slab-middle-bottom.xml',
      'extra-mf-slab-middle-middle-rear-units.xml' => 'extra-mf-slab-middle-middle.xml',
      'extra-mf-slab-middle-top-rear-units.xml' => 'extra-mf-slab-middle-top.xml',
      'extra-mf-slab-right-bottom-rear-units.xml' => 'extra-mf-slab-right-bottom.xml',
      'extra-mf-slab-right-middle-rear-units.xml' => 'extra-mf-slab-right-middle.xml',
      'extra-mf-slab-right-top-rear-units.xml' => 'extra-mf-slab-right-top.xml',
      'extra-mf-vented-crawlspace-left-bottom-rear-units.xml' => 'extra-mf-vented-crawlspace-left-bottom.xml',
      'extra-mf-vented-crawlspace-left-middle-rear-units.xml' => 'extra-mf-vented-crawlspace-left-middle.xml',
      'extra-mf-vented-crawlspace-left-top-rear-units.xml' => 'extra-mf-vented-crawlspace-left-top.xml',
      'extra-mf-vented-crawlspace-middle-bottom-rear-units.xml' => 'extra-mf-vented-crawlspace-middle-bottom.xml',
      'extra-mf-vented-crawlspace-middle-middle-rear-units.xml' => 'extra-mf-vented-crawlspace-middle-middle.xml',
      'extra-mf-vented-crawlspace-middle-top-rear-units.xml' => 'extra-mf-vented-crawlspace-middle-top.xml',
      'extra-mf-vented-crawlspace-right-bottom-rear-units.xml' => 'extra-mf-vented-crawlspace-right-bottom.xml',
      'extra-mf-vented-crawlspace-right-middle-rear-units.xml' => 'extra-mf-vented-crawlspace-right-middle.xml',
      'extra-mf-vented-crawlspace-right-top-rear-units.xml' => 'extra-mf-vented-crawlspace-right-top.xml',
      'extra-mf-unvented-crawlspace-left-bottom-rear-units.xml' => 'extra-mf-unvented-crawlspace-left-bottom.xml',
      'extra-mf-unvented-crawlspace-left-middle-rear-units.xml' => 'extra-mf-unvented-crawlspace-left-middle.xml',
      'extra-mf-unvented-crawlspace-left-top-rear-units.xml' => 'extra-mf-unvented-crawlspace-left-top.xml',
      'extra-mf-unvented-crawlspace-middle-bottom-rear-units.xml' => 'extra-mf-unvented-crawlspace-middle-bottom.xml',
      'extra-mf-unvented-crawlspace-middle-middle-rear-units.xml' => 'extra-mf-unvented-crawlspace-middle-middle.xml',
      'extra-mf-unvented-crawlspace-middle-top-rear-units.xml' => 'extra-mf-unvented-crawlspace-middle-top.xml',
      'extra-mf-unvented-crawlspace-right-bottom-rear-units.xml' => 'extra-mf-unvented-crawlspace-right-bottom.xml',
      'extra-mf-unvented-crawlspace-right-middle-rear-units.xml' => 'extra-mf-unvented-crawlspace-right-middle.xml',
      'extra-mf-unvented-crawlspace-right-top-rear-units.xml' => 'extra-mf-unvented-crawlspace-right-top.xml',

      'error-heating-system-and-heat-pump.xml' => 'base-sfd.xml',
      'error-cooling-system-and-heat-pump.xml' => 'base-sfd.xml',
      'error-sfd-adiabatic-walls.xml' => 'base-sfd.xml',
      'error-second-heating-system-but-no-primary-heating.xml' => 'base-sfd.xml',
      'error-sfa-above-apartment.xml' => 'base-sfa.xml',
      'error-sfa-below-apartment.xml' => 'base-sfa.xml',
      'error-mf-conditioned-attic.xml' => 'base-mf.xml',
      'error-dhw-indirect-without-boiler.xml' => 'base-sfd.xml',
      'error-conditioned-attic-with-one-floor-above-grade.xml' => 'base-sfd.xml',
      'error-zero-number-of-bedrooms.xml' => 'base-sfd.xml',
      'error-hip-roof-and-protruding-garage.xml' => 'base-sfd.xml',
      'error-protruding-garage-under-gable-roof.xml' => 'base-sfd.xml',
      'error-ambient-with-garage.xml' => 'base-sfd.xml',
      'error-could-not-find-epw-file.xml' => 'base-sfd.xml',

      'warning-tiny-home-wide-garage.xml' => 'base-sfd.xml',
      'warning-tiny-home-deep-garage.xml' => 'base-sfd.xml',
      'warning-vented-crawlspace-with-wall-and-ceiling-insulation.xml' => 'base-sfd.xml',
      'warning-unvented-crawlspace-with-wall-and-ceiling-insulation.xml' => 'base-sfd.xml',
      'warning-unconditioned-basement-with-wall-and-ceiling-insulation.xml' => 'base-sfd.xml',
      'warning-vented-attic-with-floor-and-roof-insulation.xml' => 'base-sfd.xml',
      'warning-unvented-attic-with-floor-and-roof-insulation.xml' => 'base-sfd.xml',
      'warning-conditioned-basement-with-ceiling-insulation.xml' => 'base-sfd.xml',
      'warning-conditioned-attic-with-floor-insulation.xml' => 'base-sfd.xml',
    }

    expected_errors = {
      'error-heating-system-and-heat-pump.xml' => ['Multiple central heating systems are not currently supported.'],
      'error-cooling-system-and-heat-pump.xml' => ['Multiple central cooling systems are not currently supported.'],
      'error-sfd-adiabatic-walls.xml' => ['No adiabatic surfaces can be applied to single-family detached homes.'],
      'error-mf-conditioned-basement' => ['Conditioned basement/crawlspace foundation type for apartment units is not currently supported.'],
      'error-mf-conditioned-crawlspace' => ['Conditioned basement/crawlspace foundation type for apartment units is not currently supported.'],
      'error-second-heating-system-but-no-primary-heating.xml' => ['A second heating system was specified without a primary heating system.'],
      'error-sfa-above-apartment.xml' => ['Single-family attached units cannot be above another unit.'],
      'error-sfa-below-apartment.xml' => ['Single-family attached units cannot be below another unit.'],
      'error-mf-conditioned-attic.xml' => ['Conditioned attic type for apartment units is not currently supported.'],
      'error-dhw-indirect-without-boiler.xml' => ['Must specify a boiler when modeling an indirect water heater type.'],
      'error-conditioned-attic-with-one-floor-above-grade.xml' => ['Units with a conditioned attic must have at least two above-grade floors.'],
      'error-hip-roof-and-protruding-garage.xml' => ['Cannot handle protruding garage and hip roof.'],
      'error-protruding-garage-under-gable-roof.xml' => ['Cannot handle protruding garage and attic ridge running from front to back.'],
      'error-ambient-with-garage.xml' => ['Cannot handle garages with an ambient foundation type.'],
      'error-could-not-find-epw-file.xml' => ['Could not find EPW file at']
    }

    expected_warnings = {
      'warning-tiny-home-wide-garage.xml' => ['Garage is as wide as the single-family detached unit; garage width reduced from 12 ft to 8.0 ft.',
                                              'The garage pitch was changed to accommodate garage ridge >= house ridge (from 0.5 to 0.338).'],
      'warning-tiny-home-deep-garage.xml' => ['Garage is as deep as the single-family detached unit; garage depth reduced from 20 ft to 19.0 ft.',
                                              'The garage pitch was changed to accommodate garage ridge >= house ridge (from 0.5 to 0.393).'],
      'warning-vented-crawlspace-with-wall-and-ceiling-insulation.xml' => ['Home with unconditioned basement/crawlspace foundation type has both foundation wall insulation and floor insulation.'],
      'warning-unvented-crawlspace-with-wall-and-ceiling-insulation.xml' => ['Home with unconditioned basement/crawlspace foundation type has both foundation wall insulation and floor insulation.'],
      'warning-unconditioned-basement-with-wall-and-ceiling-insulation.xml' => ['Home with unconditioned basement/crawlspace foundation type has both foundation wall insulation and floor insulation.'],
      'warning-vented-attic-with-floor-and-roof-insulation.xml' => ['Home with unconditioned attic type has both ceiling insulation and roof insulation.'],
      'warning-unvented-attic-with-floor-and-roof-insulation.xml' => ['Home with unconditioned attic type has both ceiling insulation and roof insulation.'],
      'warning-conditioned-basement-with-ceiling-insulation.xml' => ['Home with conditioned basement has floor insulation.'],
      'warning-conditioned-attic-with-floor-insulation.xml' => ['Home with conditioned attic has ceiling insulation.'],
    }

    schema_path = File.join(File.dirname(__FILE__), '../..', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')
    schema_validator = XMLValidator.get_xml_validator(schema_path)

    puts "Generating #{hpxmls_files.size} HPXML files..."

    hpxmls_files.each_with_index do |(hpxml_file, parent), i|
      puts "[#{i + 1}/#{hpxmls_files.size}] Generating #{hpxml_file}..."

      begin
        all_hpxml_files = [hpxml_file]
        unless parent.nil?
          all_hpxml_files.unshift(parent)
        end
        while not parent.nil?
          next unless hpxmls_files.keys.include? parent

          unless hpxmls_files[parent].nil?
            all_hpxml_files.unshift(hpxmls_files[parent])
          end
          parent = hpxmls_files[parent]
        end

        args = {}
        all_hpxml_files.each do |f|
          _set_measure_argument_values(f, args)
        end

        measures_dir = File.join(File.dirname(__FILE__), '../..')
        measures = { 'BuildResidentialHPXML' => [args] }
        model = OpenStudio::Model::Model.new
        runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

        # Apply measure
        success = apply_measures(measures_dir, measures, runner, model)
        model.save(File.absolute_path(File.join(@output_path, hpxml_file.gsub('.xml', '.osm')))) if @model_save

        _test_measure(runner, expected_errors[hpxml_file], expected_warnings[hpxml_file])

        if not success
          runner.result.stepErrors.each do |s|
            puts "Error: #{s}"
          end

          next if hpxml_file.start_with?('error')

          flunk "Error: Did not successfully generate #{hpxml_file}."
        end
        hpxml_path = File.absolute_path(File.join(@output_path, hpxml_file))
        hpxml = HPXML.new(hpxml_path: hpxml_path)
        if hpxml.errors.size > 0
          puts hpxml.errors
          puts "\nError: Did not successfully validate #{hpxml_file}."
          exit!
        end
        hpxml.header.xml_generated_by = 'build_residential_hpxml_test.rb'
        hpxml.header.created_date_and_time = Time.new(2000, 1, 1).strftime('%Y-%m-%dT%H:%M:%S%:z') # Hard-code to prevent diffs

        hpxml_doc = hpxml.to_doc()
        XMLHelper.write_file(hpxml_doc, hpxml_path)

        errors, _warnings = XMLValidator.validate_against_schema(hpxml_path, schema_validator)
        next unless errors.size > 0

        puts errors
        puts "\nError: Did not successfully validate #{hpxml_file}."
        exit!
      rescue Exception => e
        puts "#{e.message}\n#{e.backtrace.join("\n")}"
        flunk "Error: Did not successfully generate #{hpxml_file}"
      end
    end

    # Check generated HPXML files
    hpxml = HPXML.new(hpxml_path: File.absolute_path(File.join(@output_path, 'extra-seasons-building-america.xml')))
    hvac_control = hpxml.buildings[0].hvac_controls[0]
    assert_equal(10, hvac_control.seasons_heating_begin_month)
    assert_equal(1, hvac_control.seasons_heating_begin_day)
    assert_equal(6, hvac_control.seasons_heating_end_month)
    assert_equal(30, hvac_control.seasons_heating_end_day)
    assert_equal(5, hvac_control.seasons_cooling_begin_month)
    assert_equal(1, hvac_control.seasons_cooling_begin_day)
    assert_equal(10, hvac_control.seasons_cooling_end_month)
    assert_equal(31, hvac_control.seasons_cooling_end_day)
  end

  def test_option_tsvs
    # Get measure arguments up front
    model = OpenStudio::Model::Model.new
    measure = BuildResidentialHPXML.new
    arguments = measure.arguments(model)

    num_tsvs = 0
    Dir["#{File.dirname(__FILE__)}/../resources/options/*.tsv"].each do |tsv_path|
      tsv_name = File.basename(tsv_path)
      puts "Checking #{tsv_name}..."

      # Check we can retrieve option names
      option_names = get_option_names(tsv_name)
      puts "  Number of options: #{option_names.size}"
      assert_operator(option_names.size, :>, 0)
      assert_equal(option_names.size, option_names.uniq.size) # Make sure there are no duplicates
      option_names.each do |option_name|
        refute(option_name.include?('=')) # don't allow "=" in option names for resstock
      end

      # Check for argument w/ valid default value
      arg_name = tsv_name.gsub('.tsv', '')
      arg = arguments.find { |a| a.name == arg_name }
      if arg.nil?
        flunk "Argument '#{arg_name}' not found."
      end
      if arg.hasDefaultValue
        puts "  Default value: #{arg.defaultValueAsString}"
        assert(option_names.include?(arg.defaultValueAsString))
      else
        flunk "Missing/invalid default value for #{tsv_name}; expected one of: \"#{option_names.to_a.join('","')}\"."
      end

      # Check we can retrieve properties for each option
      option_names.each_with_index do |option_name, i|
        args = {}
        get_option_properties(args, tsv_name, option_name)
        puts "  Number of properties: #{args.size}" if i == 0
        assert_operator(args.size, :>, 0)
        assert_equal(args.size, args.uniq.size) # Make sure there are no duplicates
      end

      # Check that every property has a description at the end of the file
      property_names = get_property_names(tsv_name)
      property_units = get_property_units(tsv_name)
      assert(property_names.size == property_units.size)
      property_descriptions = get_property_descriptions(tsv_name)
      puts "  Number of property descriptions: #{property_descriptions.size}"
      assert_operator(property_names.size, :>, 0)
      assert_operator(property_descriptions.size, :>, 0)
      missing_descriptions = property_names - property_descriptions.keys
      extra_descriptions = property_descriptions.keys - property_names
      if missing_descriptions.size > 0
        flunk "Missing property description(s) for #{tsv_name}: #{missing_descriptions.join(',')}."
      end
      if extra_descriptions.size > 0
        flunk "Extra property description(s) for #{tsv_name}: #{extra_descriptions.join(',')}."
      end

      num_tsvs += 1
    end
    assert_operator(num_tsvs, :>, 0)
  end

  private

  def _set_measure_argument_values(hpxml_file, args)
    args['hpxml_path'] = File.join(File.dirname(__FILE__), "extra_files/#{hpxml_file}")
    args['apply_defaults'] = true
    args['apply_validation'] = true

    # Base
    case hpxml_file
    when 'base-sfd.xml'
      args['simulation_control_timestep'] = '60'
      args['location_epw_path'] = 'USA_CO_Denver.Intl.AP.725650_TMY3.epw'
      args['location_site_type'] = 'Suburban, Normal'
      args['geometry_unit_type'] = 'Single-Family Detached, 1 Story'
      args['geometry_unit_conditioned_floor_area'] = '2700.0'
      args['geometry_ceiling_height'] = '8.0 ft'
      args['geometry_unit_direction'] = 'South'
      args['geometry_unit_aspect_ratio'] = '1.5'
      args['geometry_foundation_type'] = 'Basement, Conditioned'
      args['geometry_roof_pitch'] = '6:12'
      args['geometry_attic_type'] = 'Attic, Unvented, Gable'
      args['geometry_eaves'] = 'None'
      args['geometry_unit_num_bedrooms'] = '3'
      args['geometry_unit_num_bathrooms'] = '2'
      args['geometry_unit_num_occupants'] = '3'
      args['enclosure_rim_joist'] = 'Interior, R-13'
      args['enclosure_air_leakage'] = '3 ACH50'
      args['enclosure_ceiling'] = 'R-38'
      args['enclosure_roof_material'] = 'Asphalt/Fiberglass Shingles, Medium'
      args['enclosure_roof'] = 'Uninsulated'
      args['enclosure_wall'] = 'Wood Stud, R-21'
      args['enclosure_wall_siding'] = 'Wood, Medium'
      args['enclosure_foundation_wall'] = 'Solid Concrete, Whole Wall, R-10'
      args['enclosure_window'] = 'Double, Low-E, Insulated, Air, Med Gain'
      args['geometry_window_areas_or_wwrs'] = '108, 108, 72, 72'
      args['enclosure_window_natural_ventilation'] = '67% Operable Windows'
      args['enclosure_window_interior_shading'] = 'Summer 0.7, Winter 0.8'
      args['geometry_door_area'] = '40.0'
      args['enclosure_door'] = 'Solid Wood, R-2'
      args['hvac_heating_system_fuel'] = 'Natural Gas'
      args['hvac_heating_system'] = 'Central Furnace, 92% AFUE'
      args['hvac_heating_system_capacity'] = '40 kBtu/hr'
      args['hvac_heating_system_heating_load_served'] = '100%'
      args['hvac_cooling_system'] = 'Central AC, SEER2 12.4'
      args['hvac_cooling_system_capacity'] = '2.0 tons'
      args['hvac_cooling_system_cooling_load_served'] = '100%'
      args['hvac_heat_pump'] = 'None'
      args['hvac_heat_pump_capacity'] = '3.0 tons'
      args['hvac_heat_pump_heating_load_served'] = '100%'
      args['hvac_heat_pump_cooling_load_served'] = '100%'
      args['hvac_heat_pump_backup'] = 'Integrated, Electricity, 100% Efficiency'
      args['hvac_heat_pump_backup_capacity'] = '35 kBtu/hr'
      args['hvac_control_heating_weekday_setpoint'] = '68'
      args['hvac_control_heating_weekend_setpoint'] = '68'
      args['hvac_control_cooling_weekday_setpoint'] = '78'
      args['hvac_control_cooling_weekend_setpoint'] = '78'
      args['hvac_ducts'] = '4 CFM25 per 100ft2, R-4'
      args['hvac_ducts_supply_location'] = 'Attic'
      args['hvac_ducts_return_location'] = 'Attic'
      args['hvac_heating_system_2_fuel'] = 'Electricity'
      args['hvac_heating_system_2_heating_load_served'] = '25%'
      args['dhw_water_heater'] = 'Electricity, Tank, UEF 0.94'
      args['lighting'] = '25% LED, 100% Usage'
      args['appliance_clothes_washer'] = 'Standard, 2008-2017, 100% Usage'
      args['appliance_clothes_dryer'] = 'Electricity, Standard, 100% Usage'
      args['appliance_dishwasher'] = 'Federal Minimum, Standard, 100% Usage'
      args['appliance_refrigerator'] = '434 kWh/yr, 100% Usage'
      args['appliance_extra_refrigerator'] = 'None'
      args['appliance_freezer'] = 'None'
      args['appliance_cooking_range_oven'] = 'Electricity, Standard, Non-Convection, 100% Usage'
      args['appliance_dehumidifier'] = 'None'
      args['misc_plug_loads'] = '100% Usage'
      args['misc_television'] = '100% Usage'
      args['misc_electric_vehicle_charging'] = 'None'
      args['misc_pool'] = 'None'
      args['misc_permanent_spa'] = 'None'
    when 'base-sfa.xml'
      args['geometry_unit_type'] = 'Single-Family Attached, 1 Story'
      args['geometry_unit_conditioned_floor_area'] = '1800.0'
      args['geometry_attached_walls'] = '1 Side: Right'
      args['geometry_window_areas_or_wwrs'] = '0.18, 0.18, 0.18, 0.18'
    when 'base-mf.xml'
      args['geometry_unit_type'] = 'Apartment Unit, 1 Story'
      args['geometry_unit_conditioned_floor_area'] = '900.0'
      args['geometry_attic_type'] = 'Below Apartment'
      args['geometry_foundation_type'] = 'Above Apartment'
      args['geometry_attached_walls'] = '1 Side: Right'
      args['geometry_window_areas_or_wwrs'] = '0.18, 0.18, 0.18, 0.18'
      args['hvac_ducts'] = '0 CFM25 per 100ft2, Uninsulated'
      args['hvac_ducts_supply_location'] = 'Conditioned Space'
      args['hvac_ducts_return_location'] = 'Conditioned Space'
      args['geometry_door_area'] = '20.0'
    when 'base-sfd-header.xml'
      args['simulation_control_run_period'] = 'Jan 1 - Dec 31'
      args['utility_bill_scenario'] = 'Default (EIA Average Rates)'
      args['advanced_feature'] = 'Temperature Capacitance Multiplier, 1'
    end

    # Extras
    case hpxml_file
    when 'extra-pv-roofpitch.xml'
      args['pv_system'] = '4.0 kW'
      args['pv_system_direction'] = 'Roof Pitch, South'
      args['pv_system_2'] = '4.0 kW'
      args['pv_system_2_direction'] = 'Roof Pitch, East'
    when 'extra-dhw-solar-latitude.xml'
      args['dhw_solar_thermal'] = 'Indirect, Flat Plate, 40 sqft'
      args['dhw_solar_thermal_direction'] = 'Roof Pitch, South'
    when 'extra-second-heating-system-portable-heater-to-heating-system.xml'
      args['hvac_heating_system_fuel'] = 'Electricity'
      args['hvac_heating_system_capacity'] = '50 kBtu/hr'
      args['hvac_heating_system_heating_load_served'] = '75%'
      args['hvac_ducts'] = '0 CFM25 per 100ft2, Uninsulated'
      args['hvac_ducts_supply_location'] = 'Conditioned Space'
      args['hvac_ducts_return_location'] = 'Conditioned Space'
      args['hvac_heating_system_2'] = 'Space Heater, 100% Efficiency'
      args['hvac_heating_system_2_capacity'] = '15 kBtu/hr'
    when 'extra-second-heating-system-fireplace-to-heating-system.xml'
      args['hvac_heating_system_fuel'] = 'Electricity'
      args['hvac_heating_system'] = 'Electric Resistance'
      args['hvac_heating_system_capacity'] = '50 kBtu/hr'
      args['hvac_heating_system_heating_load_served'] = '75%'
      args['hvac_cooling_system'] = 'None'
      args['hvac_heating_system_2'] = 'Fireplace, 100% Efficiency'
      args['hvac_heating_system_2_capacity'] = '15 kBtu/hr'
    when 'extra-second-heating-system-boiler-to-heating-system.xml'
      args['hvac_heating_system'] = 'Boiler, 92% AFUE'
      args['hvac_heating_system_heating_load_served'] = '75%'
      args['hvac_heating_system_2'] = 'Boiler, 100% AFUE'
    when 'extra-second-heating-system-portable-heater-to-heat-pump.xml'
      args['hvac_heating_system'] = 'None'
      args['hvac_cooling_system'] = 'None'
      args['hvac_heat_pump'] = 'Central HP, SEER2 9.5, HSPF2 5.8'
      args['hvac_heat_pump_backup'] = 'Integrated, Electricity, 100% Efficiency'
      args['hvac_heat_pump_capacity'] = '4.0 tons'
      args['hvac_heat_pump_heating_load_served'] = '75%'
      args['hvac_ducts'] = '0 CFM25 per 100ft2, R-4'
      args['hvac_ducts_supply_location'] = 'Conditioned Space'
      args['hvac_ducts_return_location'] = 'Conditioned Space'
      args['hvac_heating_system_2'] = 'Space Heater, 100% Efficiency'
      args['hvac_heating_system_2_capacity'] = '15 kBtu/hr'
    when 'extra-second-heating-system-boiler-to-heat-pump.xml'
      args['hvac_heating_system'] = 'None'
      args['hvac_cooling_system'] = 'None'
      args['hvac_heat_pump'] = 'Geothermal HP, EER 16.6, COP 3.6'
      args['hvac_heat_pump_backup'] = 'Integrated, Electricity, 100% Efficiency'
      args['hvac_heat_pump_heating_load_served'] = '75%'
      args['hvac_heating_system_2'] = 'Boiler, 100% AFUE'
    when 'extra-enclosure-windows-shading.xml'
      args['enclosure_window_interior_shading'] = 'Summer 0.5, Winter 0.9'
      args['enclosure_window_exterior_shading'] = 'Summer 0.25, Winter 1.00'
    when 'extra-enclosure-garage-partially-protruded.xml'
      args['geometry_garage_type'] = '1 Car, Right, Half Protruding'
    when 'extra-enclosure-garage-atticroof-conditioned.xml'
      args['geometry_garage_type'] = '3 Car, Right, Half Protruding'
      args['geometry_window_areas_or_wwrs'] = '12, 108, 72, 72'
      args['geometry_unit_conditioned_floor_area'] = '4500.0'
      args['geometry_unit_type'] = 'Single-Family Detached, 2 Stories'
      args['geometry_attic_type'] = 'Attic, Conditioned, Gable'
      args['enclosure_floor_over_garage'] = 'Wood Frame, R-38'
      args['hvac_ducts_supply_location'] = 'Garage'
      args['hvac_ducts_return_location'] = 'Garage'
    when 'extra-enclosure-atticroof-conditioned-eaves-gable.xml'
      args['geometry_foundation_type'] = 'Slab-on-Grade'
      args['geometry_unit_conditioned_floor_area'] = '4500.0'
      args['geometry_unit_type'] = 'Single-Family Detached, 2 Stories'
      args['geometry_attic_type'] = 'Attic, Conditioned, Gable'
      args['geometry_eaves'] = '2 ft'
      args['hvac_ducts_supply_location'] = 'Under Slab'
      args['hvac_ducts_return_location'] = 'Under Slab'
    when 'extra-enclosure-atticroof-conditioned-eaves-hip.xml'
      args['geometry_attic_type'] = 'Attic, Conditioned, Hip'
    when 'extra-seasons-building-america.xml'
      args['hvac_control_heating_season_period'] = Constants::BuildingAmerica
      args['hvac_control_cooling_season_period'] = Constants::BuildingAmerica
    when 'extra-ducts-crawlspace.xml'
      args['geometry_foundation_type'] = 'Crawlspace, Unvented'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, R-15'
      args['hvac_ducts_supply_location'] = 'Crawlspace'
      args['hvac_ducts_return_location'] = 'Crawlspace'
    when 'extra-ducts-attic.xml'
      args['hvac_ducts_supply_location'] = 'Attic'
      args['hvac_ducts_return_location'] = 'Attic'
    when 'extra-water-heater-crawlspace.xml'
      args['geometry_foundation_type'] = 'Crawlspace, Unvented'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, R-15'
      args['dhw_water_heater_location'] = 'Crawlspace'
    when 'extra-water-heater-attic.xml'
      args['dhw_water_heater_location'] = 'Attic'
    when 'extra-vehicle-ev.xml'
      args['electric_vehicle'] = 'Midsize, 200 Mile Range, 11000 miles/yr'
      args['electric_vehicle_charger'] = 'Level 2, 70% Charging at Home'
    when 'extra-two-batteries.xml'
      args['electric_vehicle'] = 'Midsize, 200 Mile Range, 11000 miles/yr'
      args['battery'] = '20.0 kWh'
    when 'extra-detailed-performance-autosize.xml'
      args['hvac_heating_system'] = 'None'
      args['hvac_cooling_system'] = 'None'
      args['hvac_heat_pump'] = 'Detailed Example: Central HP, SEER 17.5, HSPF 9.5, Normalized Detailed Performance'
    when 'extra-sfa-atticroof-flat.xml'
      args['geometry_attic_type'] = 'Flat Roof'
      args['hvac_ducts'] = '0 CFM25 per 100ft2, R-4'
      args['hvac_ducts_supply_location'] = 'Basement'
      args['hvac_ducts_return_location'] = 'Basement'
    when 'extra-sfa-atticroof-conditioned-eaves-gable.xml'
      args['geometry_unit_type'] = 'Single-Family Attached, 2 Stories'
      args['geometry_attic_type'] = 'Attic, Conditioned, Gable'
      args['geometry_eaves'] = '2 ft'
      args['hvac_ducts_supply_location'] = 'Conditioned Space'
      args['hvac_ducts_return_location'] = 'Conditioned Space'
    when 'extra-sfa-atticroof-conditioned-eaves-hip.xml'
      args['geometry_attic_type'] = 'Attic, Conditioned, Hip'
    when 'extra-mf-eaves.xml'
      args['geometry_eaves'] = '2 ft'
    when 'extra-sfa-slab.xml'
      args['geometry_foundation_type'] = 'Slab-on-Grade'
    when 'extra-sfa-vented-crawlspace.xml'
      args['geometry_foundation_type'] = 'Crawlspace, Vented'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, R-15'
    when 'extra-sfa-unvented-crawlspace.xml'
      args['geometry_foundation_type'] = 'Crawlspace, Unvented'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, R-15'
    when 'extra-sfa-conditioned-crawlspace.xml'
      args['geometry_foundation_type'] = 'Crawlspace, Conditioned'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, Uninsulated'
    when 'extra-sfa-unconditioned-basement.xml'
      args['geometry_foundation_type'] = 'Basement, Unconditioned'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, R-15'
      args['enclosure_foundation_wall'] = 'Solid Concrete, Uninsulated'
    when 'extra-sfa-ambient.xml'
      args['geometry_unit_conditioned_floor_area'] = '900.0'
      args['geometry_foundation_type'] = 'Ambient'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, R-15'
    when 'extra-sfa-slab-middle.xml', 'extra-sfa-vented-crawlspace-middle.xml',
         'extra-sfa-unvented-crawlspace-middle.xml', 'extra-sfa-unconditioned-basement-middle.xml'
      args['geometry_attached_walls'] = '2 Sides: Left, Right'
    when 'extra-sfa-slab-right.xml', 'extra-sfa-vented-crawlspace-right.xml',
         'extra-sfa-unvented-crawlspace-right.xml', 'extra-sfa-unconditioned-basement-right.xml'
      args['geometry_attached_walls'] = '1 Side: Left'
    when 'extra-mf-atticroof-flat.xml'
      args['geometry_attic_type'] = 'Flat Roof'
    when 'extra-mf-atticroof-vented.xml'
      args['geometry_attic_type'] = 'Attic, Vented, Gable'
    when 'extra-mf-slab.xml'
      args['geometry_foundation_type'] = 'Slab-on-Grade'
    when 'extra-mf-vented-crawlspace.xml'
      args['geometry_foundation_type'] = 'Crawlspace, Vented'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, R-15'
    when 'extra-mf-unvented-crawlspace.xml'
      args['geometry_foundation_type'] = 'Crawlspace, Unvented'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, R-15'
    when 'extra-mf-ambient.xml'
      args['geometry_unit_conditioned_floor_area'] = '450.0'
      args['geometry_foundation_type'] = 'Ambient'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, R-15'
    when 'extra-mf-slab-left-bottom.xml', 'extra-mf-vented-crawlspace-left-bottom.xml',
         'extra-mf-unvented-crawlspace-left-bottom.xml'
      args['geometry_attached_walls'] = '1 Side: Right'
      args['geometry_attic_type'] = 'Below Apartment'
    when 'extra-mf-slab-left-middle.xml', 'extra-mf-vented-crawlspace-left-middle.xml',
         'extra-mf-unvented-crawlspace-left-middle.xml'
      args['geometry_attached_walls'] = '1 Side: Right'
      args['geometry_attic_type'] = 'Below Apartment'
      args['geometry_foundation_type'] = 'Above Apartment'
    when 'extra-mf-slab-left-top.xml', 'extra-mf-vented-crawlspace-left-top.xml',
         'extra-mf-unvented-crawlspace-left-top.xml'
      args['geometry_attached_walls'] = '1 Side: Right'
      args['geometry_foundation_type'] = 'Above Apartment'
    when 'extra-mf-slab-middle-bottom.xml', 'extra-mf-vented-crawlspace-middle-bottom.xml',
         'extra-mf-unvented-crawlspace-middle-bottom.xml'
      args['geometry_attached_walls'] = '2 Sides: Left, Right'
      args['geometry_attic_type'] = 'Below Apartment'
    when 'extra-mf-slab-middle-middle.xml', 'extra-mf-vented-crawlspace-middle-middle.xml',
         'extra-mf-unvented-crawlspace-middle-middle.xml'
      args['geometry_attached_walls'] = '2 Sides: Left, Right'
      args['geometry_attic_type'] = 'Below Apartment'
      args['geometry_foundation_type'] = 'Above Apartment'
    when 'extra-mf-slab-middle-top.xml', 'extra-mf-vented-crawlspace-middle-top.xml',
         'extra-mf-unvented-crawlspace-middle-top.xml'
      args['geometry_attached_walls'] = '2 Sides: Left, Right'
      args['geometry_foundation_type'] = 'Above Apartment'
    when 'extra-mf-slab-right-bottom.xml', 'extra-mf-vented-crawlspace-right-bottom.xml',
         'extra-mf-unvented-crawlspace-right-bottom.xml'
      args['geometry_attached_walls'] = '1 Side: Left'
      args['geometry_attic_type'] = 'Below Apartment'
    when 'extra-mf-slab-right-middle.xml', 'extra-mf-vented-crawlspace-right-middle.xml',
         'extra-mf-unvented-crawlspace-right-middle.xml'
      args['geometry_attached_walls'] = '1 Side: Left'
      args['geometry_attic_type'] = 'Below Apartment'
      args['geometry_foundation_type'] = 'Above Apartment'
    when 'extra-mf-slab-right-top.xml', 'extra-mf-vented-crawlspace-right-top.xml',
         'extra-mf-unvented-crawlspace-right-top.xml'
      args['geometry_attached_walls'] = '1 Side: Left'
      args['geometry_foundation_type'] = 'Above Apartment'
    when 'extra-mf-slab-rear-units.xml',
         'extra-mf-vented-crawlspace-rear-units.xml',
         'extra-mf-unvented-crawlspace-rear-units.xml',
         'extra-mf-slab-left-bottom-rear-units.xml',
         'extra-mf-slab-left-middle-rear-units.xml',
         'extra-mf-slab-left-top-rear-units.xml',
         'extra-mf-slab-middle-bottom-rear-units.xml',
         'extra-mf-slab-middle-middle-rear-units.xml',
         'extra-mf-slab-middle-top-rear-units.xml',
         'extra-mf-slab-right-bottom-rear-units.xml',
         'extra-mf-slab-right-middle-rear-units.xml',
          'extra-mf-slab-right-top-rear-units.xml',
          'extra-mf-vented-crawlspace-left-bottom-rear-units.xml',
          'extra-mf-vented-crawlspace-left-middle-rear-units.xml',
          'extra-mf-vented-crawlspace-left-top-rear-units.xml',
          'extra-mf-vented-crawlspace-middle-bottom-rear-units.xml',
          'extra-mf-vented-crawlspace-middle-middle-rear-units.xml',
          'extra-mf-vented-crawlspace-middle-top-rear-units.xml',
          'extra-mf-vented-crawlspace-right-bottom-rear-units.xml',
          'extra-mf-vented-crawlspace-right-middle-rear-units.xml',
          'extra-mf-vented-crawlspace-right-top-rear-units.xml',
           'extra-mf-unvented-crawlspace-left-bottom-rear-units.xml',
          'extra-mf-unvented-crawlspace-left-middle-rear-units.xml',
           'extra-mf-unvented-crawlspace-left-top-rear-units.xml',
           'extra-mf-unvented-crawlspace-middle-bottom-rear-units.xml',
           'extra-mf-unvented-crawlspace-middle-middle-rear-units.xml',
           'extra-mf-unvented-crawlspace-middle-top-rear-units.xml',
           'extra-mf-unvented-crawlspace-right-bottom-rear-units.xml',
           'extra-mf-unvented-crawlspace-right-middle-rear-units.xml',
           'extra-mf-unvented-crawlspace-right-top-rear-units.xml'
      args['geometry_attached_walls'] = '1 Side: Front'
    end

    # Error
    case hpxml_file
    when 'error-heating-system-and-heat-pump.xml'
      args['hvac_cooling_system'] = 'None'
      args['hvac_heat_pump'] = 'Central HP, SEER2 9.5, HSPF2 5.8'
    when 'error-cooling-system-and-heat-pump.xml'
      args['hvac_heating_system'] = 'None'
      args['hvac_heat_pump'] = 'Central HP, SEER2 9.5, HSPF2 5.8'
    when 'error-sfd-adiabatic-walls.xml'
      args['geometry_attached_walls'] = '1 Side: Left'
    when 'error-mf-conditioned-basement'
      args['geometry_foundation_type'] = 'Basement, Conditioned'
    when 'error-mf-conditioned-crawlspace'
      args['geometry_foundation_type'] = 'Crawlspace, Conditioned'
    when 'error-second-heating-system-but-no-primary-heating.xml'
      args['hvac_heating_system'] = 'None'
      args['hvac_heating_system_2'] = 'Fireplace, 100% Efficiency'
    when 'error-sfa-above-apartment.xml'
      args['geometry_foundation_type'] = 'Above Apartment'
    when 'error-sfa-below-apartment.xml'
      args['geometry_attic_type'] = 'Below Apartment'
    when 'error-mf-conditioned-attic.xml'
      args['geometry_attic_type'] = 'Attic, Conditioned, Gable'
    when 'error-dhw-indirect-without-boiler.xml'
      args['dhw_water_heater'] = 'Space-Heating Boiler w/ Storage Tank'
    when 'error-conditioned-attic-with-one-floor-above-grade.xml'
      args['geometry_attic_type'] = 'Attic, Conditioned, Gable'
      args['enclosure_ceiling'] = 'Uninsulated'
    when 'error-hip-roof-and-protruding-garage.xml'
      args['geometry_attic_type'] = 'Attic, Unvented, Hip'
      args['geometry_garage_type'] = '1 Car, Right, Half Protruding'
    when 'error-protruding-garage-under-gable-roof.xml'
      args['geometry_unit_aspect_ratio'] = '0.5'
      args['geometry_garage_type'] = '1 Car, Right, Half Protruding'
    when 'error-ambient-with-garage.xml'
      args['geometry_garage_type'] = '1 Car, Right, Half Protruding'
      args['geometry_foundation_type'] = 'Ambient'
    when 'error-could-not-find-epw-file.xml'
      args['location_epw_path'] = 'foo.epw'
    end

    # Warning
    case hpxml_file
    when 'warning-tiny-home-wide-garage.xml'
      args['geometry_unit_conditioned_floor_area'] = '298'
      args['geometry_unit_type'] = 'Single-Family Detached, 2 Stories'
      args['geometry_garage_type'] = '1 Car, Left, Fully Protruding'
    when 'warning-tiny-home-deep-garage.xml'
      args['geometry_unit_conditioned_floor_area'] = '298'
      args['geometry_unit_type'] = 'Single-Family Detached, 2 Stories'
      args['geometry_garage_type'] = '1 Car, Left, Half Protruding'
    when 'warning-vented-crawlspace-with-wall-and-ceiling-insulation.xml'
      args['geometry_foundation_type'] = 'Crawlspace, Vented'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, R-11'
      args['enclosure_foundation_wall'] = 'Solid Concrete, Whole Wall, R-10'
    when 'warning-unvented-crawlspace-with-wall-and-ceiling-insulation.xml'
      args['geometry_foundation_type'] = 'Crawlspace, Unvented'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, R-11'
      args['enclosure_foundation_wall'] = 'Solid Concrete, Whole Wall, R-10'
    when 'warning-unconditioned-basement-with-wall-and-ceiling-insulation.xml'
      args['geometry_foundation_type'] = 'Basement, Unconditioned'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, R-11'
      args['enclosure_foundation_wall'] = 'Solid Concrete, Whole Wall, R-10'
    when 'warning-vented-attic-with-floor-and-roof-insulation.xml'
      args['geometry_attic_type'] = 'Attic, Vented, Gable'
      args['enclosure_roof'] = 'R-7'
      args['hvac_ducts_supply_location'] = 'Attic'
      args['hvac_ducts_return_location'] = 'Attic'
    when 'warning-unvented-attic-with-floor-and-roof-insulation.xml'
      args['geometry_attic_type'] = 'Attic, Unvented, Gable'
      args['enclosure_roof'] = 'R-7'
    when 'warning-conditioned-basement-with-ceiling-insulation.xml'
      args['geometry_foundation_type'] = 'Basement, Conditioned'
      args['enclosure_floor_over_foundation'] = 'Wood Frame, R-11'
    when 'warning-conditioned-attic-with-floor-insulation.xml'
      args['geometry_unit_type'] = 'Single-Family Detached, 2 Stories'
      args['geometry_attic_type'] = 'Attic, Conditioned, Gable'
      args['hvac_ducts_supply_location'] = 'Conditioned Space'
      args['hvac_ducts_return_location'] = 'Conditioned Space'
    end
  end

  def _test_measure(runner, expected_errors, expected_warnings)
    # check warnings/errors
    if not expected_errors.nil?
      expected_errors.each do |expected_error|
        if runner.result.stepErrors.count { |s| s.include?(expected_error) } <= 0
          runner.result.stepErrors.each do |s|
            puts "ERROR: #{s}"
          end
        end
        assert(runner.result.stepErrors.count { |s| s.include?(expected_error) } > 0)
      end
    end
    if not expected_warnings.nil?
      expected_warnings.each do |expected_warning|
        if runner.result.stepWarnings.count { |s| s.include?(expected_warning) } <= 0
          runner.result.stepWarnings.each do |s|
            puts "WARNING: #{s}"
          end
        end
        assert(runner.result.stepWarnings.count { |s| s.include?(expected_warning) } > 0)
      end
    end
  end
end
