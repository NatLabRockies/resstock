# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'
require_relative '../../BuildResidentialHPXML/resources/geometry.rb'
require_relative 'util.rb'

class HPXMLtoOpenStudioEnclosureTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(File.dirname(__FILE__), 'tmp.xml')
    @schema_validator = XMLValidator.get_xml_validator(File.join(File.dirname(__FILE__), '..', 'resources', 'hpxml_schema', 'HPXML.xsd'))
    @schematron_validator = XMLValidator.get_xml_validator(File.join(File.dirname(__FILE__), '..', 'resources', 'hpxml_schematron', 'EPvalidator.sch'))
  end

  def teardown
    cleanup_output_files([@tmp_hpxml_path])
  end

  def test_roofs
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    # Open cavity, asphalt shingles roof
    roofs_values = [{ assembly_r: 0.1, layer_names: ['asphalt or fiberglass shingles + osb'] },
                    { assembly_r: 5.0, layer_names: ['asphalt or fiberglass shingles + osb', 'roof rigid ins'] },
                    { assembly_r: 20.0, layer_names: ['asphalt or fiberglass shingles + osb', 'roof rigid ins'] }]

    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    roofs_values.each_with_index do |roof_values, j|
      hpxml_bldg.roofs[0].insulation_assembly_r_value = roof_values[:assembly_r]
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: j > 0) # Only validate in.xml once for speed

      # Check properties
      os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_bldg.roofs[0].id}:" }
      _check_surface(hpxml_bldg.roofs[0], os_surface, roof_values[:layer_names])
    end

    # Closed cavity, asphalt shingles roof
    roofs_values = [{ assembly_r: 0.1, layer_names: ['asphalt or fiberglass shingles + osb', 'roof stud and cavity', 'gypsum board'] },
                    { assembly_r: 5.0, layer_names: ['asphalt or fiberglass shingles + osb', 'roof stud and cavity', 'gypsum board'] },
                    { assembly_r: 20.0, layer_names: ['asphalt or fiberglass shingles + osb', 'roof rigid ins', 'roof stud and cavity', 'gypsum board'] }]

    hpxml, hpxml_bldg = _create_hpxml('base-atticroof-cathedral.xml')
    roofs_values.each_with_index do |roof_values, j|
      hpxml_bldg.roofs[0].insulation_assembly_r_value = roof_values[:assembly_r]
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: j > 0) # Only validate in.xml once for speed

      # Check properties
      os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_bldg.roofs[0].id}:" }
      _check_surface(hpxml_bldg.roofs[0], os_surface, roof_values[:layer_names])
    end

    # Closed cavity, Miscellaneous
    roofs_values = [
      # Slate or tile
      [{ assembly_r: 0.1, layer_names: ['slate or tile shingles + osb', 'roof stud and cavity', 'gypsum board'] },
       { assembly_r: 5.0, layer_names: ['slate or tile shingles + osb', 'roof stud and cavity', 'gypsum board'] },
       { assembly_r: 20.0, layer_names: ['slate or tile shingles + osb', 'roof rigid ins', 'roof stud and cavity', 'gypsum board'] }],
      # Metal
      [{ assembly_r: 0.1, layer_names: ['metal surfacing + osb', 'roof stud and cavity', 'plaster'] },
       { assembly_r: 5.0, layer_names: ['metal surfacing + osb', 'roof stud and cavity', 'plaster'] },
       { assembly_r: 20.0, layer_names: ['metal surfacing + osb', 'roof rigid ins', 'roof stud and cavity', 'plaster'] }],
      # Wood shingles
      [{ assembly_r: 0.1, layer_names: ['wood shingles or shakes + osb', 'roof stud and cavity', 'wood'] },
       { assembly_r: 5.0, layer_names: ['wood shingles or shakes + osb', 'roof stud and cavity', 'wood'] },
       { assembly_r: 20.0, layer_names: ['wood shingles or shakes + osb', 'roof rigid ins', 'roof stud and cavity', 'wood'] }],
      # Shingles
      [{ assembly_r: 0.1, layer_names: ['shingles + osb', 'roof stud and cavity', 'gypsum board'] },
       { assembly_r: 5.0, layer_names: ['shingles + osb', 'roof stud and cavity', 'gypsum board'] },
       { assembly_r: 20.0, layer_names: ['shingles + osb', 'roof rigid ins', 'roof stud and cavity', 'gypsum board'] }],
      # Plastic/rubber
      [{ assembly_r: 0.1, layer_names: ['plastic/rubber/synthetic sheeting + osb', 'roof stud and cavity', 'plaster'] },
       { assembly_r: 5.0, layer_names: ['plastic/rubber/synthetic sheeting + osb', 'roof stud and cavity', 'plaster'] },
       { assembly_r: 20.0, layer_names: ['plastic/rubber/synthetic sheeting + osb', 'roof rigid ins', 'roof stud and cavity', 'plaster'] }],
      # EPS
      [{ assembly_r: 0.1, layer_names: ['expanded polystyrene sheathing + osb', 'roof stud and cavity', 'wood'] },
       { assembly_r: 5.0, layer_names: ['expanded polystyrene sheathing + osb', 'roof stud and cavity', 'wood'] },
       { assembly_r: 20.0, layer_names: ['expanded polystyrene sheathing + osb', 'roof rigid ins', 'roof stud and cavity', 'wood'] }],
      # Concrete
      [{ assembly_r: 0.1, layer_names: ['concrete + osb', 'roof stud and cavity', 'gypsum board'] },
       { assembly_r: 5.0, layer_names: ['concrete + osb', 'roof stud and cavity', 'gypsum board'] },
       { assembly_r: 20.0, layer_names: ['concrete + osb', 'roof rigid ins', 'roof stud and cavity', 'gypsum board'] }],
      # Cool
      [{ assembly_r: 0.1, layer_names: ['cool roof + osb', 'roof stud and cavity', 'plaster'] },
       { assembly_r: 5.0, layer_names: ['cool roof + osb', 'roof stud and cavity', 'plaster'] },
       { assembly_r: 20.0, layer_names: ['cool roof + osb', 'roof rigid ins', 'roof stud and cavity', 'plaster'] }],

    ]

    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-rooftypes.xml')
    for i in 0..hpxml_bldg.roofs.size - 1
      roofs_values[i].each_with_index do |roof_values, j|
        hpxml_bldg.roofs[i].insulation_assembly_r_value = roof_values[:assembly_r]
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: i + j > 0) # Only validate in.xml once for speed

        # Check properties
        os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_bldg.roofs[i].id}:" }
        _check_surface(hpxml_bldg.roofs[i], os_surface, roof_values[:layer_names])
      end
    end
  end

  def test_radiant_barriers
    # Attic roof and gable walls
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    roofs_values = [{ assembly_r: 0.1, layer_names: ['asphalt or fiberglass shingles + osb', 'radiant barrier'] },
                    { assembly_r: 5.0, layer_names: ['asphalt or fiberglass shingles + osb', 'roof rigid ins', 'radiant barrier'] },
                    { assembly_r: 20.0, layer_names: ['asphalt or fiberglass shingles + osb', 'roof rigid ins', 'radiant barrier'] }]
    gablewalls_values = [{ assembly_r: 0.1, layer_names: ['wood siding', 'wall stud and cavity', 'radiant barrier'] },
                         { assembly_r: 5.0, layer_names: ['wood siding', 'osb 0.5 in.', 'wall stud and cavity', 'radiant barrier'] },
                         { assembly_r: 20.0, layer_names: ['wood siding', 'wall rigid ins', 'osb 0.5 in.', 'wall stud and cavity', 'radiant barrier'] }]

    hpxml, hpxml_bldg = _create_hpxml('base-atticroof-radiant-barrier.xml')
    roofs_values.each_with_index do |roof_values, j|
      gablewall_values = gablewalls_values[j]
      hpxml_bldg.roofs[0].insulation_assembly_r_value = roof_values[:assembly_r]
      hpxml_bldg.walls[1].insulation_assembly_r_value = gablewall_values[:assembly_r]
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: j > 0) # Only validate in.xml once for speed

      # Check roof properties
      os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_bldg.roofs[0].id}:" }
      _check_surface(hpxml_bldg.roofs[0], os_surface, roof_values[:layer_names], 0.05)

      # Check gable wall properties
      os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_bldg.walls[1].id}:" }
      _check_surface(hpxml_bldg.walls[1], os_surface, gablewall_values[:layer_names], 0.05)
    end

    # Attic floor
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    ceilings_values = [{ assembly_r: 0.1, layer_names: ['radiant barrier', 'ceiling stud and cavity', 'gypsum board'] },
                       { assembly_r: 5.0, layer_names: ['radiant barrier', 'ceiling stud and cavity', 'gypsum board'] },
                       { assembly_r: 20.0, layer_names: ['radiant barrier', 'ceiling loosefill ins', 'ceiling stud and cavity', 'gypsum board'] }]

    hpxml, hpxml_bldg = _create_hpxml('base-atticroof-radiant-barrier-ceiling.xml')
    ceilings_values.each_with_index do |ceiling_values, j|
      hpxml_bldg.floors[0].insulation_assembly_r_value = ceiling_values[:assembly_r]
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: j > 0) # Only validate in.xml once for speed

      # Check ceiling properties
      os_surface = model.getSurfaces.find { |s| s.name.to_s == hpxml_bldg.floors[0].id }
      _check_surface(hpxml_bldg.floors[0], os_surface, ceiling_values[:layer_names], 0.5)
    end
  end

  def test_rim_joists
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    # Wood siding
    rimjs_values = [{ assembly_r: 0.1, layer_names: ['wood siding', 'rim joist stud and cavity'] },
                    { assembly_r: 5.0, layer_names: ['wood siding', 'osb', 'rim joist stud and cavity'] },
                    { assembly_r: 20.0, layer_names: ['wood siding', 'rim joist rigid ins', 'osb', 'rim joist stud and cavity'] }]

    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    rimjs_values.each_with_index do |rimj_values, j|
      hpxml_bldg.rim_joists[0].insulation_assembly_r_value = rimj_values[:assembly_r]
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: j > 0) # Only validate in.xml once for speed

      # Check properties
      os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_bldg.rim_joists[0].id}:" }
      _check_surface(hpxml_bldg.rim_joists[0], os_surface, rimj_values[:layer_names])
    end

    # Miscellaneous
    rimjs_values = [
      # Aluminum
      [{ assembly_r: 0.1, layer_names: ['aluminum siding', 'rim joist stud and cavity'] },
       { assembly_r: 5.0, layer_names: ['aluminum siding', 'osb', 'rim joist stud and cavity'] },
       { assembly_r: 20.0, layer_names: ['aluminum siding', 'rim joist rigid ins', 'osb', 'rim joist stud and cavity'] }],
      # Asbestos
      [{ assembly_r: 0.1, layer_names: ['asbestos siding', 'rim joist stud and cavity'] },
       { assembly_r: 5.0, layer_names: ['asbestos siding', 'osb', 'rim joist stud and cavity'] },
       { assembly_r: 20.0, layer_names: ['asbestos siding', 'rim joist rigid ins', 'osb', 'rim joist stud and cavity'] }],
      # Brick veneer
      [{ assembly_r: 0.1, layer_names: ['brick veneer', 'rim joist stud and cavity'] },
       { assembly_r: 5.0, layer_names: ['brick veneer', 'osb', 'rim joist stud and cavity'] },
       { assembly_r: 20.0, layer_names: ['brick veneer', 'rim joist rigid ins', 'osb', 'rim joist stud and cavity'] }],
      # Composite shingle
      [{ assembly_r: 0.1, layer_names: ['composite shingle siding', 'rim joist stud and cavity'] },
       { assembly_r: 5.0, layer_names: ['composite shingle siding', 'osb', 'rim joist stud and cavity'] },
       { assembly_r: 20.0, layer_names: ['composite shingle siding', 'rim joist rigid ins', 'osb', 'rim joist stud and cavity'] }],
      # Fiber cement
      [{ assembly_r: 0.1, layer_names: ['fiber cement siding', 'rim joist stud and cavity'] },
       { assembly_r: 5.0, layer_names: ['fiber cement siding', 'osb', 'rim joist stud and cavity'] },
       { assembly_r: 20.0, layer_names: ['fiber cement siding', 'rim joist rigid ins', 'osb', 'rim joist stud and cavity'] }],
      # Masonite
      [{ assembly_r: 0.1, layer_names: ['masonite siding', 'rim joist stud and cavity'] },
       { assembly_r: 5.0, layer_names: ['masonite siding', 'osb', 'rim joist stud and cavity'] },
       { assembly_r: 20.0, layer_names: ['masonite siding', 'rim joist rigid ins', 'osb', 'rim joist stud and cavity'] }],
      # Stucco
      [{ assembly_r: 0.1, layer_names: ['stucco', 'rim joist stud and cavity'] },
       { assembly_r: 5.0, layer_names: ['stucco', 'osb', 'rim joist stud and cavity'] },
       { assembly_r: 20.0, layer_names: ['stucco', 'rim joist rigid ins', 'osb', 'rim joist stud and cavity'] }],
      # Synthetic stucco
      [{ assembly_r: 0.1, layer_names: ['synthetic stucco', 'rim joist stud and cavity'] },
       { assembly_r: 5.0, layer_names: ['synthetic stucco', 'rim joist stud and cavity'] },
       { assembly_r: 20.0, layer_names: ['synthetic stucco', 'rim joist rigid ins', 'osb', 'rim joist stud and cavity'] }],
      # Vinyl
      [{ assembly_r: 0.1, layer_names: ['vinyl siding', 'rim joist stud and cavity'] },
       { assembly_r: 5.0, layer_names: ['vinyl siding', 'osb', 'rim joist stud and cavity'] },
       { assembly_r: 20.0, layer_names: ['vinyl siding', 'rim joist rigid ins', 'osb', 'rim joist stud and cavity'] }],
      # None
      [{ assembly_r: 0.1, layer_names: ['rim joist stud and cavity'] },
       { assembly_r: 5.0, layer_names: ['osb', 'rim joist stud and cavity'] },
       { assembly_r: 20.0, layer_names: ['rim joist rigid ins', 'osb', 'rim joist stud and cavity'] }],
      # Stone veneer
      [{ assembly_r: 0.1, layer_names: ['stone veneer', 'rim joist stud and cavity'] },
       { assembly_r: 5.0, layer_names: ['stone veneer', 'osb', 'rim joist stud and cavity'] },
       { assembly_r: 20.0, layer_names: ['stone veneer', 'rim joist rigid ins', 'osb', 'rim joist stud and cavity'] }],
    ]

    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-walltypes.xml')
    for i in 0..hpxml_bldg.rim_joists.size - 1
      rimjs_values[i].each_with_index do |rimj_values, j|
        hpxml_bldg.rim_joists[i].insulation_assembly_r_value = rimj_values[:assembly_r]
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: i + j > 0) # Only validate in.xml once for speed

        # Check properties
        os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_bldg.rim_joists[i].id}:" }
        _check_surface(hpxml_bldg.rim_joists[i], os_surface, rimj_values[:layer_names])
      end
    end
  end

  def test_walls
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    # Wood Stud wall
    walls_values = [{ assembly_r: 0.1, layer_names: ['wood siding', 'wall stud and cavity', 'gypsum board'] },
                    { assembly_r: 5.0, layer_names: ['wood siding', 'osb', 'wall stud and cavity', 'gypsum board'] },
                    { assembly_r: 20.0, layer_names: ['wood siding', 'wall rigid ins', 'osb', 'wall stud and cavity', 'gypsum board'] }]

    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    walls_values.each_with_index do |wall_values, j|
      hpxml_bldg.walls[0].insulation_assembly_r_value = wall_values[:assembly_r]
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: j > 0) # Only validate in.xml once for speed

      # Check properties
      os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_bldg.walls[0].id}:" }
      _check_surface(hpxml_bldg.walls[0], os_surface, wall_values[:layer_names])
    end

    # Miscellaneous
    walls_values = [
      # CMU wall
      [{ assembly_r: 0.1, layer_names: ['aluminum siding', 'concrete block', 'gypsum board'] },
       { assembly_r: 5.0, layer_names: ['aluminum siding', 'wall rigid ins', 'concrete block', 'gypsum board'] },
       { assembly_r: 20.0, layer_names: ['aluminum siding', 'wall rigid ins', 'osb', 'concrete block', 'gypsum board'] }],
      # Double Stud wall
      [{ assembly_r: 0.1, layer_names: ['asbestos siding', 'wall stud and cavity', 'wall cavity', 'wall stud and cavity', 'gypsum board'] },
       { assembly_r: 5.0, layer_names: ['asbestos siding', 'osb', 'wall stud and cavity', 'wall cavity', 'wall stud and cavity', 'gypsum board'] },
       { assembly_r: 20.0, layer_names: ['asbestos siding', 'osb', 'wall stud and cavity', 'wall cavity', 'wall stud and cavity', 'gypsum board'] }],
      # ICF wall
      [{ assembly_r: 0.1, layer_names: ['brick veneer', 'wall ins form', 'wall concrete', 'wall ins form', 'gypsum composite board'] },
       { assembly_r: 5.0, layer_names: ['brick veneer', 'osb', 'wall ins form', 'wall concrete', 'wall ins form', 'gypsum composite board'] },
       { assembly_r: 20.0, layer_names: ['brick veneer', 'osb', 'wall ins form', 'wall concrete', 'wall ins form', 'gypsum composite board'] }],
      # Log wall
      [{ assembly_r: 0.1, layer_names: ['composite shingle siding', 'wall layer', 'plaster'] },
       { assembly_r: 5.0, layer_names: ['composite shingle siding', 'osb', 'wall layer', 'plaster'] },
       { assembly_r: 20.0, layer_names: ['composite shingle siding', 'wall rigid ins', 'osb', 'wall layer', 'plaster'] }],
      # SIP wall
      [{ assembly_r: 0.1, layer_names: ['fiber cement siding', 'wall spline layer', 'wall ins layer', 'wall spline layer', 'osb', 'wood'] },
       { assembly_r: 5.0, layer_names: ['fiber cement siding', 'osb', 'wall spline layer', 'wall ins layer', 'wall spline layer', 'osb', 'wood'] },
       { assembly_r: 20.0, layer_names: ['fiber cement siding', 'osb', 'wall spline layer', 'wall ins layer', 'wall spline layer', 'osb', 'wood'] }],
      # Solid Concrete wall
      [{ assembly_r: 0.1, layer_names: ['masonite siding', 'wall layer'] },
       { assembly_r: 5.0, layer_names: ['masonite siding', 'osb', 'wall layer'] },
       { assembly_r: 20.0, layer_names: ['masonite siding', 'wall rigid ins', 'osb', 'wall layer'] }],
      # Steel frame wall
      [{ assembly_r: 0.1, layer_names: ['stucco', 'wall stud and cavity', 'gypsum board'] },
       { assembly_r: 5.0, layer_names: ['stucco', 'osb', 'wall stud and cavity', 'gypsum board'] },
       { assembly_r: 20.0, layer_names: ['stucco', 'wall rigid ins', 'osb', 'wall stud and cavity', 'gypsum board'] }],
      # Stone wall
      [{ assembly_r: 0.1, layer_names: ['synthetic stucco', 'wall layer', 'gypsum board'] },
       { assembly_r: 5.0, layer_names: ['synthetic stucco', 'wall layer', 'gypsum board'] },
       { assembly_r: 20.0, layer_names: ['synthetic stucco', 'wall rigid ins', 'osb', 'wall layer', 'gypsum board'] }],
      # Straw Bale wall
      [{ assembly_r: 0.1, layer_names: ['vinyl siding', 'wall layer', 'gypsum composite board'] },
       { assembly_r: 5.0, layer_names: ['vinyl siding', 'osb', 'wall layer', 'gypsum composite board'] },
       { assembly_r: 20.0, layer_names: ['vinyl siding', 'wall rigid ins', 'osb', 'wall layer', 'gypsum composite board'] }],
      # Structural Brick wall
      [{ assembly_r: 0.1, layer_names: ['wall layer', 'plaster'] },
       { assembly_r: 5.0, layer_names: ['osb', 'wall layer', 'plaster'] },
       { assembly_r: 20.0, layer_names: ['wall rigid ins', 'osb', 'wall layer', 'plaster'] }],
      # Adobe wall
      [{ assembly_r: 0.1, layer_names: ['stone veneer', 'wall layer', 'wood'] },
       { assembly_r: 5.0, layer_names: ['stone veneer', 'osb', 'wall layer', 'wood'] },
       { assembly_r: 20.0, layer_names: ['stone veneer', 'wall rigid ins', 'osb', 'wall layer', 'wood'] }],
    ]

    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-walltypes.xml')
    for i in 0..hpxml_bldg.walls.size - 2
      walls_values[i].each_with_index do |wall_values, j|
        hpxml_bldg.walls[i].insulation_assembly_r_value = wall_values[:assembly_r]
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: i + j > 0) # Only validate in.xml once for speed

        # Check properties
        os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_bldg.walls[i].id}:" }
        _check_surface(hpxml_bldg.walls[i], os_surface, wall_values[:layer_names])
      end
    end
  end

  def test_foundation_walls
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    # Foundation wall w/ Assembly R-values
    walls_values = [{ assembly_r: 0.1, layer_names: ['concrete'] },
                    { assembly_r: 5.0, layer_names: ['concrete', 'exterior vertical ins'] },
                    { assembly_r: 20.0, layer_names: ['concrete', 'exterior vertical ins'] }]

    hpxml, hpxml_bldg = _create_hpxml('base-foundation-unconditioned-basement-assembly-r.xml')
    walls_values.each_with_index do |wall_values, j|
      hpxml_bldg.foundation_walls[0].insulation_assembly_r_value = wall_values[:assembly_r]
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: j > 0) # Only validate in.xml once for speed

      # Check properties
      os_surface = model.getSurfaces.find { |s| s.name.to_s == hpxml_bldg.foundation_walls[0].id }
      _check_surface(hpxml_bldg.foundation_walls[0], os_surface, wall_values[:layer_names])
    end

    # Foundation wall w/ different material types
    walls_values = [{ type: HPXML::FoundationWallTypeSolidConcrete, layer_names: ['concrete'] },
                    { type: HPXML::FoundationWallTypeConcreteBlock, layer_names: ['concrete block'] },
                    { type: HPXML::FoundationWallTypeConcreteBlockFoamCore, layer_names: ['concrete block foam core'] },
                    { type: HPXML::FoundationWallTypeConcreteBlockPerliteCore, layer_names: ['concrete block perlite core'] },
                    { type: HPXML::FoundationWallTypeConcreteBlockSolidCore, layer_names: ['concrete block solid core'] },
                    { type: HPXML::FoundationWallTypeConcreteBlockVermiculiteCore, layer_names: ['concrete block vermiculite core'] },
                    { type: HPXML::FoundationWallTypeDoubleBrick, layer_names: ['double brick'] },
                    { type: HPXML::FoundationWallTypeWood, layer_names: ['wood'] }]

    hpxml, hpxml_bldg = _create_hpxml('base-foundation-unconditioned-basement-assembly-r.xml')
    walls_values.each_with_index do |wall_values, j|
      hpxml_bldg.foundation_walls[0].insulation_assembly_r_value = 0.1 # Ensure just a single layer
      hpxml_bldg.foundation_walls[0].type = wall_values[:type]
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: j > 0) # Only validate in.xml once for speed

      # Check properties
      os_surface = model.getSurfaces.find { |s| s.name.to_s == hpxml_bldg.foundation_walls[0].id }
      _check_surface(hpxml_bldg.foundation_walls[0], os_surface, wall_values[:layer_names])
    end

    # Foundation wall w/ Insulation Layers
    walls_values = [{ interior_r: 0.0, exterior_r: 0.0, layer_names: ['concrete'] },
                    { interior_r: 5.0, exterior_r: 0.0, layer_names: ['concrete', 'interior vertical ins'] },
                    { interior_r: 20.0, exterior_r: 0.0, layer_names: ['concrete', 'interior vertical ins'] },
                    { interior_r: 0.0, exterior_r: 5.0, layer_names: ['concrete', 'exterior vertical ins'] },
                    { interior_r: 0.0, exterior_r: 20.0, layer_names: ['concrete', 'exterior vertical ins'] },
                    { interior_r: 5.0, exterior_r: 5.0, layer_names: ['concrete', 'interior vertical ins', 'exterior vertical ins'] },
                    { interior_r: 20.0, exterior_r: 20.0, layer_names: ['concrete', 'interior vertical ins', 'exterior vertical ins'] }]

    hpxml, hpxml_bldg = _create_hpxml('base-foundation-unconditioned-basement-wall-insulation.xml')
    walls_values.each_with_index do |wall_values, j|
      hpxml_bldg.foundation_walls[0].insulation_interior_r_value = wall_values[:interior_r]
      hpxml_bldg.foundation_walls[0].insulation_interior_distance_to_top = 0.0
      hpxml_bldg.foundation_walls[0].insulation_interior_distance_to_bottom = 8.0
      hpxml_bldg.foundation_walls[0].insulation_exterior_r_value = wall_values[:exterior_r]
      hpxml_bldg.foundation_walls[0].insulation_exterior_distance_to_top = 0.0
      hpxml_bldg.foundation_walls[0].insulation_exterior_distance_to_bottom = 8.0
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: j > 0) # Only validate in.xml once for speed

      # Check properties
      os_surface = model.getSurfaces.find { |s| s.name.to_s == hpxml_bldg.foundation_walls[0].id }
      _check_surface(hpxml_bldg.foundation_walls[0], os_surface, wall_values[:layer_names])
    end
  end

  def test_ceilings
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    # Wood Frame
    ceilings_values = [{ assembly_r: 0.1, layer_names: ['ceiling stud and cavity', 'gypsum board'] },
                       { assembly_r: 5.0, layer_names: ['ceiling stud and cavity', 'gypsum board'] },
                       { assembly_r: 20.0, layer_names: ['ceiling loosefill ins', 'ceiling stud and cavity', 'gypsum board'] }]

    hpxml, hpxml_bldg = _create_hpxml('base-foundation-vented-crawlspace.xml')
    ceilings_values.each_with_index do |ceiling_values, j|
      hpxml_bldg.floors[1].insulation_assembly_r_value = ceiling_values[:assembly_r]
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: j > 0) # Only validate in.xml once for speed

      # Check properties
      os_surface = model.getSurfaces.find { |s| s.name.to_s == hpxml_bldg.floors[1].id }
      _check_surface(hpxml_bldg.floors[1], os_surface, ceiling_values[:layer_names])
    end

    # Miscellaneous
    ceilings_values = [
      # SIP
      [{ assembly_r: 0.1, layer_names: ['ceiling spline layer', 'ceiling ins layer', 'ceiling spline layer', 'gypsum board'] },
       { assembly_r: 5.0, layer_names: ['ceiling spline layer', 'ceiling ins layer', 'ceiling spline layer', 'gypsum board'] },
       { assembly_r: 20.0, layer_names: ['ceiling spline layer', 'ceiling ins layer', 'ceiling spline layer', 'gypsum board'] }],
      # Solid Concrete
      [{ assembly_r: 0.1, layer_names: ['ceiling layer', 'gypsum board'] },
       { assembly_r: 5.0, layer_names: ['ceiling layer', 'gypsum board'] },
       { assembly_r: 20.0, layer_names: ['ceiling layer', 'ceiling rigid ins', 'gypsum board'] }],
      # Steel frame
      [{ assembly_r: 0.1, layer_names: ['ceiling stud and cavity', 'gypsum board'] },
       { assembly_r: 5.0, layer_names: ['ceiling stud and cavity', 'gypsum board'] },
       { assembly_r: 20.0, layer_names: ['ceiling loosefill ins', 'ceiling stud and cavity', 'gypsum board'] }],
    ]

    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-ceilingtypes.xml')
    for i in 0..hpxml_bldg.floors.size - 1
      ceilings_values[i].each_with_index do |ceiling_values, j|
        hpxml_bldg.floors[i].insulation_assembly_r_value = ceiling_values[:assembly_r]
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: i + j > 0) # Only validate in.xml once for speed

        # Check properties
        os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_bldg.floors[i].id}" }
        _check_surface(hpxml_bldg.floors[i], os_surface, ceiling_values[:layer_names])
      end
    end
  end

  def test_floors
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    # Wood Frame
    floors_values = [{ assembly_r: 0.1, layer_names: ['floor stud and cavity', 'floor covering'] },
                     { assembly_r: 5.0, layer_names: ['floor stud and cavity', 'osb', 'floor covering'] },
                     { assembly_r: 20.0, layer_names: ['floor stud and cavity', 'floor rigid ins', 'osb', 'floor covering'] }]

    hpxml, hpxml_bldg = _create_hpxml('base-foundation-vented-crawlspace.xml')
    floors_values.each_with_index do |floor_values, j|
      hpxml_bldg.floors[0].insulation_assembly_r_value = floor_values[:assembly_r]
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: j > 0) # Only validate in.xml once for speed

      # Check properties
      os_surface = model.getSurfaces.find { |s| s.name.to_s == hpxml_bldg.floors[0].id }
      _check_surface(hpxml_bldg.floors[0], os_surface, floor_values[:layer_names])
    end

    # Miscellaneous
    floors_values = [
      # SIP
      [{ assembly_r: 0.1, layer_names: ['floor spline layer', 'floor ins layer', 'floor spline layer', 'floor covering'] },
       { assembly_r: 5.0, layer_names: ['floor spline layer', 'floor ins layer', 'floor spline layer', 'osb', 'floor covering'] },
       { assembly_r: 20.0, layer_names: ['floor spline layer', 'floor ins layer', 'floor spline layer', 'osb', 'floor covering'] }],
      # Solid Concrete
      [{ assembly_r: 0.1, layer_names: ['floor layer', 'floor covering'] },
       { assembly_r: 5.0, layer_names: ['floor layer', 'osb', 'floor covering'] },
       { assembly_r: 20.0, layer_names: ['floor layer', 'floor rigid ins', 'osb', 'floor covering'] }],
      # Steel frame
      [{ assembly_r: 0.1, layer_names: ['floor stud and cavity', 'floor covering'] },
       { assembly_r: 5.0, layer_names: ['floor stud and cavity', 'osb', 'floor covering'] },
       { assembly_r: 20.0, layer_names: ['floor stud and cavity', 'floor rigid ins', 'osb', 'floor covering'] }],
    ]

    hpxml, hpxml_bldg = _create_hpxml('base-enclosure-floortypes.xml')
    for i in 0..hpxml_bldg.floors.size - 2
      floors_values[i].each_with_index do |floor_values, j|
        hpxml_bldg.floors[i].insulation_assembly_r_value = floor_values[:assembly_r]
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: i + j > 0) # Only validate in.xml once for speed

        # Check properties
        os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_bldg.floors[i].id}" }
        _check_surface(hpxml_bldg.floors[i], os_surface, floor_values[:layer_names])
      end
    end
  end

  def test_manufactured_home_foundation
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    hpxml, _hpxml_bldg = _create_hpxml('base-foundation-belly-wing-skirt.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, hpxml, hpxml_bldg = _test_measure(args_hash)
    hpxml_floor = hpxml_bldg.floors.find { |x| x.exterior_adjacent_to == HPXML::LocationManufacturedHomeUnderBelly }
    os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_floor.id}" }
    assert_equal(EPlus::SurfaceWindExposureNo, os_surface.windExposure)

    hpxml_bldg.foundations.clear
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    hpxml_floor = hpxml_bldg.floors.find { |x| x.exterior_adjacent_to == HPXML::LocationManufacturedHomeUnderBelly }
    os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_floor.id}" }
    assert_equal(EPlus::SurfaceWindExposureNo, os_surface.windExposure)

    hpxml, _hpxml_bldg = _create_hpxml('base-foundation-belly-wing-no-skirt.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    hpxml_floor = hpxml_bldg.floors.find { |x| x.exterior_adjacent_to == HPXML::LocationManufacturedHomeUnderBelly }
    os_surface = model.getSurfaces.find { |s| s.name.to_s.start_with? "#{hpxml_floor.id}" }
    assert_equal(EPlus::SurfaceWindExposureYes, os_surface.windExposure)
  end

  def test_slabs
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    # Slab
    slabs_values = [{ perimeter_r: 0.0, under_r: 0.0, gap_r: nil, under_span: false, ext_horiz_r: 0.0, layer_names: ['concrete', 'floor covering'] },
                    { perimeter_r: 0.0, under_r: 0.0, gap_r: 5.0, under_span: false, ext_horiz_r: 0.0, layer_names: ['concrete', 'floor covering', 'interior vertical ins'] },
                    { perimeter_r: 5.0, under_r: 0.0, gap_r: nil, under_span: false, ext_horiz_r: 0.0, layer_names: ['concrete', 'floor covering', 'exterior vertical ins'] },
                    { perimeter_r: 5.0, under_r: 0.0, gap_r: nil, under_span: false, ext_horiz_r: 5.0, layer_names: ['concrete', 'floor covering', 'exterior horizontal ins', 'exterior vertical ins'] },
                    { perimeter_r: 20.0, under_r: 0.0, gap_r: nil, under_span: false, ext_horiz_r: 0.0, layer_names: ['concrete', 'floor covering', 'exterior vertical ins'] },
                    { perimeter_r: 20.0, under_r: 0.0, gap_r: nil, under_span: false, ext_horiz_r: 20.0, layer_names: ['concrete', 'floor covering', 'exterior horizontal ins', 'exterior vertical ins'] },
                    { perimeter_r: 0.0, under_r: 5.0, gap_r: nil, under_span: false, ext_horiz_r: 0.0, layer_names: ['concrete', 'floor covering', 'interior horizontal ins', 'interior vertical ins'] },
                    { perimeter_r: 0.0, under_r: 20.0, gap_r: nil, under_span: false, ext_horiz_r: 0.0, layer_names: ['concrete', 'floor covering', 'interior horizontal ins', 'interior vertical ins'] },
                    { perimeter_r: 0.0, under_r: 5.0, gap_r: nil, under_span: true, ext_horiz_r: 0.0, layer_names: ['slab rigid ins', 'concrete', 'floor covering', 'interior vertical ins'] },
                    { perimeter_r: 0.0, under_r: 20.0, gap_r: nil, under_span: true, ext_horiz_r: 0.0, layer_names: ['slab rigid ins', 'concrete', 'floor covering', 'interior vertical ins'] },
                    { perimeter_r: 5.0, under_r: 5.0, gap_r: nil, under_span: false, ext_horiz_r: 0.0, layer_names: ['concrete', 'floor covering', 'interior horizontal ins', 'interior vertical ins', 'exterior vertical ins'] },
                    { perimeter_r: 5.0, under_r: 5.0, gap_r: nil, under_span: false, ext_horiz_r: 5.0, layer_names: ['concrete', 'floor covering', 'interior horizontal ins', 'exterior horizontal ins', 'interior vertical ins', 'exterior vertical ins'] },
                    { perimeter_r: 20.0, under_r: 20.0, gap_r: 20.0, under_span: false, ext_horiz_r: 0.0, layer_names: ['concrete', 'floor covering', 'interior horizontal ins', 'interior vertical ins', 'exterior vertical ins'] },
                    { perimeter_r: 20.0, under_r: 20.0, gap_r: 20.0, under_span: false, ext_horiz_r: 20.0, layer_names: ['concrete', 'floor covering', 'interior horizontal ins', 'exterior horizontal ins', 'interior vertical ins', 'exterior vertical ins'] }]

    hpxml, hpxml_bldg = _create_hpxml('base-foundation-slab.xml')
    slabs_values.each_with_index do |slab_values, j|
      hpxml_bldg.slabs[0].perimeter_insulation_r_value = slab_values[:perimeter_r]
      hpxml_bldg.slabs[0].perimeter_insulation_depth = 2.0

      hpxml_bldg.slabs[0].under_slab_insulation_r_value = slab_values[:under_r]
      if slab_values[:under_span]
        hpxml_bldg.slabs[0].under_slab_insulation_spans_entire_slab = true
        hpxml_bldg.slabs[0].under_slab_insulation_width = nil
      else
        hpxml_bldg.slabs[0].under_slab_insulation_width = 2.0
        hpxml_bldg.slabs[0].under_slab_insulation_spans_entire_slab = nil
      end

      hpxml_bldg.slabs[0].gap_insulation_r_value = slab_values[:gap_r]

      hpxml_bldg.slabs[0].exterior_horizontal_insulation_r_value = slab_values[:ext_horiz_r]
      hpxml_bldg.slabs[0].exterior_horizontal_insulation_width = 2.0
      hpxml_bldg.slabs[0].exterior_horizontal_insulation_depth_below_grade = 2.0

      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: j > 0) # Only validate in.xml once for speed

      # Check properties
      os_surface = model.getSurfaces.find { |s| s.name.to_s == hpxml_bldg.slabs[0].id }
      _check_surface(hpxml_bldg.slabs[0], os_surface, slab_values[:layer_names])
    end
  end

  def test_windows
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base.xml'))
    model, hpxml, hpxml_bldg = _test_measure(args_hash)

    # Check window properties
    hpxml_bldg.windows.each do |window|
      os_window = model.getSubSurfaces.find { |w| w.name.to_s == window.id }
      os_simple_glazing = os_window.construction.get.to_LayeredConstruction.get.getLayer(0).to_SimpleGlazing.get

      assert_equal(window.shgc, os_simple_glazing.solarHeatGainCoefficient)
      assert_in_epsilon(window.ufactor, UnitConversions.convert(os_simple_glazing.uFactor, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)'), 0.001)
    end

    # Storm windows
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml, hpxml_bldg = _create_hpxml('base.xml')

    hpxml_bldg.windows.each do |window|
      window.storm_type = HPXML::WindowGlassTypeLowE
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, hpxml, hpxml_bldg = _test_measure(args_hash)

    # Check window properties
    hpxml_bldg.windows.each do |window|
      os_window = model.getSubSurfaces.find { |w| w.name.to_s == window.id }
      os_simple_glazing = os_window.construction.get.to_LayeredConstruction.get.getLayer(0).to_SimpleGlazing.get

      assert_equal(0.352, os_simple_glazing.solarHeatGainCoefficient)
      assert_in_epsilon(0.2351, UnitConversions.convert(os_simple_glazing.uFactor, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)'), 0.001)
    end

    hpxml_bldg.windows.each do |window|
      window.ufactor = 0.6
      window.storm_type = HPXML::WindowGlassTypeLowE
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    model, hpxml, hpxml_bldg = _test_measure(args_hash)

    # Check window properties
    hpxml_bldg.windows.each do |window|
      os_window = model.getSubSurfaces.find { |w| w.name.to_s == window.id }
      os_simple_glazing = os_window.construction.get.to_LayeredConstruction.get.getLayer(0).to_SimpleGlazing.get

      assert_equal(0.352, os_simple_glazing.solarHeatGainCoefficient)
      assert_in_epsilon(0.2936, UnitConversions.convert(os_simple_glazing.uFactor, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)'), 0.001)
    end

    # Check window shading
    ['USA_CO_Denver.Intl.AP.725650_TMY3.epw',
     'ZAF_Cape.Town.688160_IWEC.epw'].each do |epw_path| # Test both northern & southern hemisphere
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
      hpxml, hpxml_bldg = _create_hpxml('base-enclosure-windows-shading-factors.xml')
      hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = epw_path
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash)

      if epw_path == 'USA_CO_Denver.Intl.AP.725650_TMY3.epw'
        summer_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('June'), 1, model.yearDescription.get.assumedYear)
        winter_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('January'), 1, model.yearDescription.get.assumedYear)
      elsif epw_path == 'ZAF_Cape.Town.688160_IWEC.epw'
        winter_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('June'), 1, model.yearDescription.get.assumedYear)
        summer_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('January'), 1, model.yearDescription.get.assumedYear)
      end

      hpxml_bldg.windows.each do |window|
        sf_summer = window.interior_shading_factor_summer
        sf_winter = window.interior_shading_factor_winter
        sf_summer *= window.exterior_shading_factor_summer unless window.exterior_shading_factor_summer.nil?
        sf_winter *= window.exterior_shading_factor_winter unless window.exterior_shading_factor_winter.nil?

        # Check shading transmittance for sky beam and sky diffuse
        os_subsurface = model.getSubSurfaces.select { |ss| ss.name.to_s.start_with? window.id }[0]
        os_ism = nil
        model.getSurfacePropertyIncidentSolarMultipliers.each do |ism|
          next unless os_subsurface == ism.subSurface

          os_ism = ism
        end
        if (sf_summer == 1) && (sf_winter == 1)
          assert_nil(os_ism) # No shading
        else
          refute_nil(os_ism) # Shading
          if sf_summer == sf_winter
            summer_transmittance = os_ism.incidentSolarMultiplierSchedule.get.to_ScheduleConstant.get.value
            winter_transmittance = summer_transmittance
          else
            summer_transmittance = os_ism.incidentSolarMultiplierSchedule.get.to_ScheduleRuleset.get.getDaySchedules(summer_date, summer_date).map { |ds| ds.values.sum }.sum
            winter_transmittance = os_ism.incidentSolarMultiplierSchedule.get.to_ScheduleRuleset.get.getDaySchedules(winter_date, winter_date).map { |ds| ds.values.sum }.sum
          end
          assert_equal(sf_summer, summer_transmittance)
          assert_equal(sf_winter, winter_transmittance)
        end
      end
    end
  end

  def test_skylights
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-enclosure-skylights.xml'))
    model, hpxml, hpxml_bldg = _test_measure(args_hash)

    # Check skylight properties
    hpxml_bldg.skylights.each do |skylight|
      os_skylight = model.getSubSurfaces.find { |w| w.name.to_s == skylight.id }
      os_simple_glazing = os_skylight.construction.get.to_LayeredConstruction.get.getLayer(0).to_SimpleGlazing.get

      assert_equal(skylight.shgc, os_simple_glazing.solarHeatGainCoefficient)
      assert_in_epsilon(skylight.ufactor / 1.2, UnitConversions.convert(os_simple_glazing.uFactor, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)'), 0.001)
    end

    # Check skylight shading
    ['USA_CO_Denver.Intl.AP.725650_TMY3.epw',
     'ZAF_Cape.Town.688160_IWEC.epw'].each do |epw_path| # Test both northern & southern hemisphere
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
      hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights-shading.xml')
      hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = epw_path
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash)

      if epw_path == 'USA_CO_Denver.Intl.AP.725650_TMY3.epw'
        summer_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('June'), 1, model.yearDescription.get.assumedYear)
        winter_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('January'), 1, model.yearDescription.get.assumedYear)
      elsif epw_path == 'ZAF_Cape.Town.688160_IWEC.epw'
        winter_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('June'), 1, model.yearDescription.get.assumedYear)
        summer_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('January'), 1, model.yearDescription.get.assumedYear)
      end

      hpxml_bldg.skylights.each do |skylight|
        sf_summer = skylight.interior_shading_factor_summer
        sf_winter = skylight.interior_shading_factor_winter
        sf_summer *= skylight.exterior_shading_factor_summer unless skylight.exterior_shading_factor_summer.nil?
        sf_winter *= skylight.exterior_shading_factor_winter unless skylight.exterior_shading_factor_winter.nil?

        # Check shading transmittance for sky beam and sky diffuse
        os_subsurface = model.getSubSurfaces.select { |ss| ss.name.to_s.start_with? skylight.id }[0]
        os_ism = nil
        model.getSurfacePropertyIncidentSolarMultipliers.each do |ism|
          next unless os_subsurface == ism.subSurface

          os_ism = ism
        end
        if (sf_summer == 1) && (sf_winter == 1)
          assert_nil(os_ism) # No shading
        else
          refute_nil(os_ism) # Shading
          if sf_summer == sf_winter
            summer_transmittance = os_ism.incidentSolarMultiplierSchedule.get.to_ScheduleConstant.get.value
            winter_transmittance = summer_transmittance
          else
            summer_transmittance = os_ism.incidentSolarMultiplierSchedule.get.to_ScheduleRuleset.get.getDaySchedules(summer_date, summer_date).map { |ds| ds.values.sum }.sum
            winter_transmittance = os_ism.incidentSolarMultiplierSchedule.get.to_ScheduleRuleset.get.getDaySchedules(winter_date, winter_date).map { |ds| ds.values.sum }.sum
          end
          assert_equal(sf_summer, summer_transmittance)
          assert_equal(sf_winter, winter_transmittance)
        end
      end
    end
  end

  def test_doors
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    # Door
    doors_values = [{ assembly_r: 0.1, layer_names: ['door material'] },
                    { assembly_r: 5.0, layer_names: ['door material'] },
                    { assembly_r: 20.0, layer_names: ['door material'] }]

    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    doors_values.each_with_index do |door_values, j|
      hpxml_bldg.doors[0].r_value = door_values[:assembly_r]
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      model, hpxml, hpxml_bldg = _test_measure(args_hash, skip_in_xml_validation: j > 0) # Only validate in.xml once for speed

      # Check properties
      os_surface = model.getSubSurfaces.find { |s| s.name.to_s == hpxml_bldg.doors[0].id }
      _check_surface(hpxml_bldg.doors[0], os_surface, door_values[:layer_names])
    end
  end

  def test_partition_wall_mass
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-enclosure-thermal-mass.xml'))

    # Thermal masses
    partition_wall_mass_layer_names = ['gypsum board', 'wall stud and cavity', 'gypsum board']

    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Check properties
    os_surface = model.getInternalMassDefinitions.find { |s| s.name.to_s == 'partition wall mass' }
    _check_surface(hpxml_bldg.partition_wall_mass, os_surface, partition_wall_mass_layer_names)
  end

  def test_furniture_mass
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-enclosure-thermal-mass.xml'))

    # Thermal masses
    furniture_mass_layer_names = ['furniture material conditioned space']

    model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Check properties
    os_surface = model.getInternalMassDefinitions.find { |s| s.name.to_s.start_with?('furniture mass conditioned space') }
    _check_surface(hpxml_bldg.furniture_mass, os_surface, furniture_mass_layer_names)
  end

  def test_foundation_properties
    tests = {
      '../tests/ASHRAE_Standard_140/L322XC.xml' => 1,                 # 1 basement foundation
      'base.xml' => 1,                                                # 1 basement foundation
      'base-foundation-slab.xml' => 1,                                # 1 slab-on-grade foundation
      'base-foundation-basement-garage.xml' => 2,                     # 1 basement foundation + 1 garage slab
      'base-foundation-unconditioned-basement-above-grade.xml' => 1,  # 1 basement foundation
      'base-foundation-conditioned-crawlspace.xml' => 1,              # 1 crawlspace foundation
      'base-foundation-ambient.xml' => 0,                             # 0 foundations
      'base-foundation-walkout-basement.xml' => 2,                    # 1 basement foundation with 1 effective below-grade depth + additional no-wall exposed perimeter
      'base-foundation-multiple.xml' => 2,                            # 1 basement foundation + 1 crawlspace foundation
      'base-foundation-complex.xml' => 6,                             # 2 basement foundations, each with 1 effective below-grade depth + additional no-wall exposed perimeter
      'base-bldgtype-sfa-unit-2stories.xml' => 1,                     # 1 basement foundation
      'base-enclosure-2stories-garage.xml' => 2,                      # 1 basement foundation + 1 garage slab
    }

    tests.each do |hpxml_name, num_kiva_objects|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_name))
      model, _hpxml, hpxml_bldg = _test_measure(args_hash)

      # Gather HPXML info
      slab_int_adj_tos = {}
      ext_fwall_int_adj_tos = {}
      int_fwall_int_adj_tos = {}
      hpxml_bldg.slabs.each do |slab|
        int_adj_to = slab.interior_adjacent_to
        int_adj_to = HPXML::LocationConditionedSpace if HPXML::conditioned_locations.include?(int_adj_to)

        slab_int_adj_tos[int_adj_to] = [] if slab_int_adj_tos[int_adj_to].nil?
        slab_int_adj_tos[int_adj_to] << slab
      end
      hpxml_bldg.foundation_walls.each do |fwall|
        int_adj_to = fwall.interior_adjacent_to
        int_adj_to = HPXML::LocationConditionedSpace if HPXML::conditioned_locations.include?(int_adj_to)

        if fwall.is_exterior
          ext_fwall_int_adj_tos[int_adj_to] = [] if ext_fwall_int_adj_tos[int_adj_to].nil?
          ext_fwall_int_adj_tos[int_adj_to] << fwall
        else
          int_fwall_int_adj_tos[int_adj_to] = [] if int_fwall_int_adj_tos[int_adj_to].nil?
          int_fwall_int_adj_tos[int_adj_to] << fwall
        end
      end

      # Check number of Kiva:Foundation objects
      # We want the lowest possible number that is sufficient, in order to keep runtime performance fast
      assert_equal(num_kiva_objects, model.getFoundationKivas.size)

      # Check slab exposed perimeters
      slab_int_adj_tos.each do |int_adj_to, slabs|
        osm_props = []
        model.getSurfacePropertyExposedFoundationPerimeters.each do |osm_prop|
          next unless osm_prop.surface.space.get.name.to_s.start_with? int_adj_to

          osm_props << osm_prop
        end

        osm_exposed_perimeter = osm_props.map { |p| p.totalExposedPerimeter.get }.sum
        hpxml_exposed_perimeter = slabs.map { |s| s.exposed_perimeter }.sum
        assert_in_epsilon(hpxml_exposed_perimeter, UnitConversions.convert(osm_exposed_perimeter, 'm', 'ft'), 0.01)
      end

      # Check each Kiva:Foundation has identical slab exposed perimeter and total exterior foundation wall length
      # This is required by Kiva, otherwise you get simulation errors.
      model.getFoundationKivas.each do |foundation|
        osm_exposed_perimeter = 0.0
        model.getSurfacePropertyExposedFoundationPerimeters.each do |osm_prop|
          next unless osm_prop.surface.outsideBoundaryCondition == EPlus::BoundaryConditionFoundation && osm_prop.surface.adjacentFoundation.get == foundation

          osm_exposed_perimeter += UnitConversions.convert(osm_prop.totalExposedPerimeter.get, 'm', 'ft')
        end

        osm_fwalls = model.getSurfaces.select { |s| s.outsideBoundaryCondition == EPlus::BoundaryConditionFoundation && s.adjacentFoundation.get == foundation && s.surfaceType == EPlus::SurfaceTypeWall }
        if not osm_fwalls.empty?
          osm_fwalls_length = osm_fwalls.map { |s| Geometry.get_surface_length(s) }.sum
          assert_in_epsilon(osm_exposed_perimeter, osm_fwalls_length, 0.01)
        end
      end

      # Check slab areas
      slab_int_adj_tos.each do |int_adj_to, slabs|
        osm_slabs = model.getSurfaces.select { |s| s.surfaceType == EPlus::SurfaceTypeFloor && s.outsideBoundaryCondition == EPlus::BoundaryConditionFoundation && s.space.get.name.to_s.start_with?(int_adj_to) }

        osm_area = osm_slabs.map { |s| s.grossArea }.sum
        hpxml_area = slabs.map { |s| s.area }.sum
        assert_in_epsilon(hpxml_area, UnitConversions.convert(osm_area, 'm^2', 'ft^2'), 0.01)
      end

      # Check exterior foundation wall exposed areas
      ext_fwall_int_adj_tos.each do |int_adj_to, fwalls|
        osm_fwalls = model.getSurfaces.select { |s| s.surfaceType == EPlus::SurfaceTypeWall && s.outsideBoundaryCondition == EPlus::BoundaryConditionFoundation && s.space.get.name.to_s.start_with?(int_adj_to) }

        osm_area = osm_fwalls.map { |s| s.grossArea }.sum
        hpxml_area = fwalls.map { |fw| fw.net_area * fw.exposed_fraction }.sum
        assert_in_epsilon(hpxml_area, UnitConversions.convert(osm_area, 'm^2', 'ft^2'), 0.01)
      end

      # Check exterior foundation wall heights & below-grade depths
      ext_fwall_int_adj_tos.each do |int_adj_to, fwalls|
        osm_fwalls = model.getSurfaces.select { |s| s.surfaceType == EPlus::SurfaceTypeWall && s.outsideBoundaryCondition == EPlus::BoundaryConditionFoundation && s.space.get.name.to_s.start_with?(int_adj_to) }

        osm_heights = osm_fwalls.map { |s| Geometry.get_surface_height(s) }.uniq.sort
        hpxml_heights = fwalls.map { |fw| fw.height }.uniq.sort
        assert_equal(hpxml_heights, osm_heights)

        osm_bgdepths = osm_fwalls.map { |s| -1 * Geometry.get_surface_z_values(surfaceArray: [s]).min }.uniq.sort
        if hpxml_name == 'base-foundation-walkout-basement.xml'
          # All foundation walls similar: single foundation wall w/ effective below-grade depth
          hpxml_bgdepths = [4.5]
        elsif hpxml_name == 'base-foundation-complex.xml'
          # Pairs of foundation walls similar: pairs of foundation walls w/ effective below-grade depths
          hpxml_bgdepths = [4.33333, 4.5]
        else
          hpxml_bgdepths = fwalls.map { |fw| fw.depth_below_grade }.uniq.sort
        end
        assert_equal(hpxml_bgdepths, osm_bgdepths)
      end

      # Check interior foundation wall heights & below-grade depths
      int_fwall_int_adj_tos.each do |int_adj_to, fwalls|
        osm_fwalls = model.getSurfaces.select { |s| s.surfaceType == EPlus::SurfaceTypeWall && s.outsideBoundaryCondition != EPlus::BoundaryConditionFoundation && Geometry.get_surface_z_values(surfaceArray: [s]).min < 0 && s.space.get.name.to_s.start_with?(int_adj_to) }

        osm_heights = osm_fwalls.map { |s| Geometry.get_surface_z_values(surfaceArray: [s]).max - Geometry.get_surface_z_values(surfaceArray: [s]).min }.uniq.sort
        hpxml_heights = fwalls.map { |fw| fw.height - fw.depth_below_grade }.uniq.sort
        assert_equal(hpxml_heights, osm_heights)

        osm_bgdepths = osm_fwalls.map { |s| -1 * Geometry.get_surface_z_values(surfaceArray: [s]).min }.uniq.sort
        hpxml_bgdepths = fwalls.map { |fw| fw.height - fw.depth_below_grade }.uniq.sort
        assert_equal(hpxml_bgdepths, osm_bgdepths)
      end
    end
  end

  def test_kiva_initial_temperatures
    initial_temps = { 'base.xml' => 68.0, # foundation adjacent to conditioned space, IECC zone 5
                      'base-foundation-conditioned-crawlspace.xml' => 68.0, # foundation adjacent to conditioned space, IECC zone 5
                      'base-foundation-slab.xml' => 68.0, # foundation adjacent to conditioned space, IECC zone 5
                      'base-foundation-unconditioned-basement.xml' => 41.4, # foundation adjacent to unconditioned basement w/ ceiling insulation
                      'base-foundation-unvented-crawlspace.xml' => 38.6, # foundation adjacent to unvented crawlspace w/ ceiling insulation
                      'base-foundation-vented-crawlspace.xml' => 36.9, # foundation adjacent to vented crawlspace w/ ceiling insulation
                      'base-location-miami-fl.xml' => 78.0 } # foundation adjacent to conditioned space, IECC zone 1

    initial_temps.each do |hpxml_name, expected_temp|
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, hpxml_name))
      model, _hpxml, _hpxml_bldg = _test_measure(args_hash)

      actual_temp = UnitConversions.convert(model.getFoundationKivas[0].initialIndoorAirTemperature.get, 'C', 'F')
      assert_in_delta(expected_temp, actual_temp, 0.1)
    end
  end

  def test_collapse_surfaces
    # Check that multiple similar surfaces are correctly collapsed
    # to reduce EnergyPlus runtime.

    def add_zones_spaces(hpxml_bldg)
      hpxml_bldg.zones.add(id: 'Zone1',
                           zone_type: HPXML::ZoneTypeConditioned)
      hpxml_bldg.zones[-1].spaces.add(id: 'Zone1Space1')
      hpxml_bldg.zones[-1].spaces.add(id: 'Zone1Space2')
      hpxml_bldg.zones.add(id: 'Zone2',
                           zone_type: HPXML::ZoneTypeConditioned)
      hpxml_bldg.zones[-1].spaces.add(id: 'Zone2Space1')
      hpxml_bldg.zones[-1].spaces.add(id: 'Zone2Space2')
    end

    def split_surfaces(surfaces, should_collapse_surfaces)
      surf_class = surfaces[0].class
      for n in 1..surfaces.size
        surfaces[n - 1].area /= 9.0
        surfaces[n - 1].exposed_perimeter /= 9.0 if surf_class == HPXML::Slab
        for i in 2..9
          surfaces << surfaces[n - 1].dup
          surfaces[-1].id += "_#{i}"
          next if should_collapse_surfaces

          # Change a property to a unique value so that it won't collapse
          # with other properties of the same surface type.
          if [HPXML::Roof, HPXML::Wall, HPXML::RimJoist, HPXML::Floor].include? surf_class
            surfaces[-1].insulation_assembly_r_value += 0.01 * i
          elsif [HPXML::FoundationWall].include? surf_class
            surfaces[-1].insulation_exterior_r_value += 0.01 * i
          elsif [HPXML::Slab].include? surf_class
            if i < 2
              surfaces[-1].perimeter_insulation_depth += 0.01 * i
            elsif i < 3
              surfaces[-1].perimeter_insulation_r_value += 0.01 * i
            elsif i < 4
              surfaces[-1].under_slab_insulation_r_value += 0.01 * i
            elsif i < 5
              surfaces[-1].under_slab_insulation_width += 0.01 * i
            elsif i < 6
              surfaces[-1].exterior_horizontal_insulation_r_value = surfaces[-1].exterior_horizontal_insulation_r_value.to_f + 0.01 * i
            elsif i < 7
              surfaces[-1].exterior_horizontal_insulation_width = surfaces[-1].exterior_horizontal_insulation_width.to_f + 0.01 * i
            else
              surfaces[-1].exterior_horizontal_insulation_depth_below_grade = surfaces[-1].exterior_horizontal_insulation_depth_below_grade.to_f + 0.01 * i
            end
          elsif [HPXML::Window, HPXML::Skylight].include? surf_class
            if i < 3
              surfaces[-1].ufactor += 0.01 * i
            elsif i < 6
              surfaces[-1].interior_shading_factor_summer = 1.0 - 0.02 * i
            else
              surfaces[-1].interior_shading_factor_winter = 1.0 - 0.01 * i
              if surf_class == HPXML::Window
                surfaces[-1].fraction_operable = 1.0 - surfaces[-1].fraction_operable
              end
            end
          elsif [HPXML::Door].include? surf_class
            surfaces[-1].r_value += 0.01 * i
          else
            fail 'Unexpected surface type.'
          end
        end
      end
      surfaces << surfaces[-1].dup
      surfaces[-1].id += '_tiny'
      surfaces[-1].area = 0.05
      surfaces[-1].exposed_perimeter = 0.05 if surf_class == HPXML::Slab

      if surfaces[0].respond_to?(:attached_to_space_idref)
        for n in 1..surfaces.size
          if n % 4 == 1
            surfaces[n - 1].attached_to_space_idref = 'Zone1Space1'
          elsif n % 4 == 2
            surfaces[n - 1].attached_to_space_idref = 'Zone1Space2'
          elsif n % 4 == 3
            surfaces[n - 1].attached_to_space_idref = 'Zone2Space1'
          elsif n % 4 == 0
            surfaces[n - 1].attached_to_space_idref = 'Zone2Space2'
          end
        end
      end
    end

    def get_num_surfaces_by_type(hpxml_bldg)
      return { roofs: hpxml_bldg.roofs.size,
               walls: hpxml_bldg.walls.size,
               rim_joists: hpxml_bldg.rim_joists.size,
               foundation_walls: hpxml_bldg.foundation_walls.size,
               floors: hpxml_bldg.floors.size,
               slabs: hpxml_bldg.slabs.size,
               windows: hpxml_bldg.windows.size,
               skylights: hpxml_bldg.skylights.size,
               doors: hpxml_bldg.doors.size }
    end

    [true, false].each do |should_collapse_surfaces|
      _hpxml, hpxml_bldg = _create_hpxml('base-enclosure-skylights.xml')
      hpxml_bldg.windows.each do |window|
        window.interior_shading_type = nil
        window.interior_shading_factor_summer = 0.7
        window.interior_shading_factor_winter = 0.85
      end

      # Make sure that the presence of HPXML zones/spaces doesn't affect this
      add_zones_spaces(hpxml_bldg)

      orig_num_surfaces_by_type = get_num_surfaces_by_type(hpxml_bldg)

      split_surfaces(hpxml_bldg.roofs, should_collapse_surfaces)
      split_surfaces(hpxml_bldg.rim_joists, should_collapse_surfaces)
      split_surfaces(hpxml_bldg.walls, should_collapse_surfaces)
      split_surfaces(hpxml_bldg.foundation_walls, should_collapse_surfaces)
      split_surfaces(hpxml_bldg.floors, should_collapse_surfaces)
      split_surfaces(hpxml_bldg.slabs, should_collapse_surfaces)
      split_surfaces(hpxml_bldg.windows, should_collapse_surfaces)
      split_surfaces(hpxml_bldg.skylights, should_collapse_surfaces)
      split_surfaces(hpxml_bldg.doors, should_collapse_surfaces)

      split_num_surfaces_by_type = get_num_surfaces_by_type(hpxml_bldg)
      hpxml_bldg.collapse_enclosure_surfaces()
      final_num_surfaces_by_type = get_num_surfaces_by_type(hpxml_bldg)

      for surf_type in orig_num_surfaces_by_type.keys
        if should_collapse_surfaces
          assert_equal(orig_num_surfaces_by_type[surf_type], final_num_surfaces_by_type[surf_type])
        else
          assert_equal(split_num_surfaces_by_type[surf_type] - 1, final_num_surfaces_by_type[surf_type])
        end
      end
    end

    # Check that Slab/DepthBelowGrade is ignored for below-grade spaces when
    # collapsing surfaces.
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-foundation-walkout-basement.xml'))
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)
    num_kiva_fnd_objects = model.getFoundationKivas.size

    hpxml, hpxml_bldg = _create_hpxml('base-foundation-walkout-basement.xml')
    hpxml_bldg.slabs[0].depth_below_grade = hpxml_bldg.foundation_walls[0].depth_below_grade
    hpxml_bldg.slabs[0].area /= 3.0
    hpxml_bldg.slabs[0].exposed_perimeter /= 3.0
    for i in 1..2
      hpxml_bldg.slabs << hpxml_bldg.slabs[0].dup
      hpxml_bldg.slabs[i].id = "Slab#{i + 1}"
      hpxml_bldg.slabs[i].perimeter_insulation_id = "Slab#{i + 1}PerimeterInsulation"
      hpxml_bldg.slabs[i].under_slab_insulation_id = "Slab#{i + 1}UnderSlabInsulation"
      hpxml_bldg.slabs[i].exterior_horizontal_insulation_id = "Slab#{i + 1}ExteriorHorizontalInsulation"
      hpxml_bldg.slabs[i].depth_below_grade = hpxml_bldg.foundation_walls[i].depth_below_grade * i / 3.0
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    model, _hpxml, _hpxml_bldg = _test_measure(args_hash)
    assert_equal(num_kiva_fnd_objects, model.getFoundationKivas.size)
  end

  def test_aspect_ratios
    # Test single-family attached
    _hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-sfa-unit.xml')
    wall_outside = hpxml_bldg.walls.find { |w| w.exterior_adjacent_to == HPXML::LocationOutside && w.interior_adjacent_to == HPXML::LocationConditionedSpace }
    wall_other_housing_unit = hpxml_bldg.walls.find { |w| w.exterior_adjacent_to == HPXML::LocationOtherHousingUnit && w.interior_adjacent_to == HPXML::LocationConditionedSpace }

    wall_height = hpxml_bldg.building_construction.average_ceiling_height
    left_right_wall_length = wall_other_housing_unit.area / wall_height
    front_back_wall_length = ((wall_outside.area / wall_height) - left_right_wall_length) / 2.0
    assert_in_delta(0.6667, front_back_wall_length / left_right_wall_length, 0.01)

    # Test multifamily
    _hpxml, hpxml_bldg = _create_hpxml('base-bldgtype-mf-unit.xml')
    wall_outside = hpxml_bldg.walls.find { |w| w.exterior_adjacent_to == HPXML::LocationOutside && w.interior_adjacent_to == HPXML::LocationConditionedSpace }
    wall_other_housing_unit = hpxml_bldg.walls.find { |w| w.exterior_adjacent_to == HPXML::LocationOtherHousingUnit && w.interior_adjacent_to == HPXML::LocationConditionedSpace }

    wall_height = hpxml_bldg.building_construction.average_ceiling_height
    left_right_wall_length = wall_other_housing_unit.area / wall_height
    front_back_wall_length = ((wall_outside.area / wall_height) - left_right_wall_length) / 2.0
    assert_in_delta(0.6667, front_back_wall_length / left_right_wall_length, 0.01)
  end

  def _check_surface(hpxml_surface, os_surface, expected_layer_names, radiant_barrier_emittance = nil)
    os_construction = os_surface.construction.get.to_LayeredConstruction.get

    # Check layers have valid properties
    for i in 0..os_construction.numLayers - 1
      layer = os_construction.getLayer(i)
      assert_operator(layer.thickness, :>, 0)
      assert_operator(layer.to_OpaqueMaterial.get.thermalConductivity, :>, 0)
    end

    # Check exterior solar absorptance and emittance
    exterior_layer = os_construction.getLayer(0).to_OpaqueMaterial.get
    if hpxml_surface.respond_to? :solar_absorptance
      assert_equal(hpxml_surface.solar_absorptance, exterior_layer.solarAbsorptance)
    end
    if hpxml_surface.respond_to? :emittance
      assert_equal(hpxml_surface.emittance, exterior_layer.thermalAbsorptance)
    end

    # Check radiant barrier properties
    has_radiant_barrier = false
    expected_layer_names.each_with_index do |expected_layer_name, idx|
      next if expected_layer_name != 'radiant barrier'

      has_radiant_barrier = true
      layer = os_construction.getLayer(idx).to_OpaqueMaterial.get
      assert(idx == 0 || idx == expected_layer_names.size - 1) # Must be the interior layer of the construction
      assert_in_delta(radiant_barrier_emittance, layer.thermalAbsorptance, 0.1)
      assert_equal(0.05, layer.solarAbsorptance)
    end
    assert(has_radiant_barrier) unless radiant_barrier_emittance.nil?

    # Check interior finish solar absorptance and emittance
    if hpxml_surface.respond_to?(:interior_finish_type) && hpxml_surface.interior_finish_type != HPXML::InteriorFinishNotPresent && !has_radiant_barrier
      interior_layer = os_construction.getLayer(os_construction.numLayers - 1).to_OpaqueMaterial.get
      assert_equal(0.6, interior_layer.solarAbsorptance)
      assert_equal(0.9, interior_layer.thermalAbsorptance)
    end

    # Check for appropriate construction layers (including Kiva insulation/custom blocks)

    num_layers = os_construction.numLayers
    if os_surface.is_a?(OpenStudio::Model::Surface) && os_surface.adjacentFoundation.is_initialized
      adjacent_foundation = os_surface.adjacentFoundation.get
      if adjacent_foundation.interiorHorizontalInsulationMaterial.is_initialized
        num_layers += 1
      end
      if adjacent_foundation.exteriorHorizontalInsulationMaterial.is_initialized
        num_layers += 1
      end
      if adjacent_foundation.interiorVerticalInsulationMaterial.is_initialized
        num_layers += 1
      end
      if adjacent_foundation.exteriorVerticalInsulationMaterial.is_initialized
        num_layers += 1
      end
      num_layers += adjacent_foundation.numberofCustomBlocks
    end

    # Construction layers
    for i in 0..os_construction.numLayers - 1
      break if i + 1 > num_layers

      layer_name = os_construction.getLayer(i).name.to_s
      expected_layer_name = expected_layer_names[i]
      if not layer_name.start_with? expected_layer_name
        puts "Layer #{i + 1}: '#{layer_name}' does not start with '#{expected_layer_name}'"
      end
      assert(layer_name.start_with? expected_layer_name)
    end
    curr_layer_num = os_construction.numLayers

    if not adjacent_foundation.nil?
      # Kiva - Interior Horizontal Insulation
      if adjacent_foundation.interiorHorizontalInsulationMaterial.is_initialized
        layer_name = adjacent_foundation.interiorHorizontalInsulationMaterial.get.name.to_s
        expected_layer_name = expected_layer_names[curr_layer_num]
        curr_layer_num += 1
        if not layer_name.start_with? expected_layer_name
          puts "'#{layer_name}' does not start with '#{expected_layer_name}'"
        end
        assert(layer_name.start_with? expected_layer_name)
      end

      # Kiva - Exterior Horizontal Insulation
      if adjacent_foundation.exteriorHorizontalInsulationMaterial.is_initialized
        layer_name = adjacent_foundation.exteriorHorizontalInsulationMaterial.get.name.to_s
        expected_layer_name = expected_layer_names[curr_layer_num]
        curr_layer_num += 1
        if not layer_name.start_with? expected_layer_name
          puts "'#{layer_name}' does not start with '#{expected_layer_name}'"
        end
        assert(layer_name.start_with? expected_layer_name)
      end

      # Kiva - Interior Vertical Insulation
      if adjacent_foundation.interiorVerticalInsulationMaterial.is_initialized
        layer_name = adjacent_foundation.interiorVerticalInsulationMaterial.get.name.to_s
        expected_layer_name = expected_layer_names[curr_layer_num]
        curr_layer_num += 1
        if not layer_name.start_with? expected_layer_name
          puts "'#{layer_name}' does not start with '#{expected_layer_name}'"
        end
        assert(layer_name.start_with? expected_layer_name)
      end

      # Kiva - Exterior Vertical Insulation
      if adjacent_foundation.exteriorVerticalInsulationMaterial.is_initialized
        layer_name = adjacent_foundation.exteriorVerticalInsulationMaterial.get.name.to_s
        expected_layer_name = expected_layer_names[curr_layer_num]
        curr_layer_num += 1
        if not layer_name.start_with? expected_layer_name
          puts "'#{layer_name}' does not start with '#{expected_layer_name}'"
        end
        assert(layer_name.start_with? expected_layer_name)
      end

      # Kiva - Custom insulation blocks
      for i in 0..adjacent_foundation.numberofCustomBlocks - 1
        layer_name = adjacent_foundation.customBlocks[i].material.name.to_s
        expected_layer_name = expected_layer_names[curr_layer_num]
        curr_layer_num += 1
        if not layer_name.start_with? expected_layer_name
          puts "'#{layer_name}' does not start with '#{expected_layer_name}'"
        end
        assert(layer_name.start_with? expected_layer_name)
      end
    end

    assert_equal(expected_layer_names.size, num_layers)
  end

  def _test_measure(args_hash, skip_in_xml_validation: false)
    # create an instance of the measure
    measure = HPXMLtoOpenStudio.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    args_hash['output_dir'] = File.dirname(__FILE__)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    result.showOutput() unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    hpxml_defaults_path = File.join(File.dirname(__FILE__), 'in.xml')
    if (args_hash['hpxml_path'] == @tmp_hpxml_path) && (not skip_in_xml_validation)
      # Since there is a penalty to performing schema/schematron validation, we only do it for custom models
      # Sample files already have their in.xml's checked in the workflow tests
      schema_validator = @schema_validator
      schematron_validator = @schematron_validator
    else
      schema_validator = nil
      schematron_validator = nil
    end
    hpxml = HPXML.new(hpxml_path: hpxml_defaults_path, schema_validator: schema_validator, schematron_validator: schematron_validator)
    if not hpxml.errors.empty?
      puts 'ERRORS:'
      hpxml.errors.each do |error|
        puts error
      end
      flunk "Validation error(s) in #{hpxml_defaults_path}."
    end

    File.delete(hpxml_defaults_path)

    return model, hpxml, hpxml.buildings[0]
  end

  def _create_hpxml(hpxml_name)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
    return hpxml, hpxml.buildings[0]
  end
end
