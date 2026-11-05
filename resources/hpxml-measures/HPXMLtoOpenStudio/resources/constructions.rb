# frozen_string_literal: true

# Collection of methods related to surface constructions.
module Constructions
  # Applies a roof construction to the OpenStudio surfaces.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param roof [HPXML::Roof] The HPXML surface that defines the construction
  # @param surfaces [Array<OpenStudio::Model::Surface>] The surfaces to apply the construction to
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply_roof(runner, model, roof, surfaces, hpxml_header)
    has_radiant_barrier = roof.radiant_barrier
    if has_radiant_barrier
      radiant_barrier_grade = roof.radiant_barrier_grade
    end
    interior_film = Material.AirFilmIndoorRoof(UnitConversions.convert(surfaces[0].tilt, 'rad', 'deg'), hpxml_header.apply_ashrae140_assumptions)
    exterior_film = Material.AirFilmOutside(false, hpxml_header.apply_ashrae140_assumptions)
    if hpxml_header.apply_ashrae140_assumptions
      mat_ext_finish = Material.RoofMaterialAndSheathing(roof.roof_type, 0.5) # Combined roof material + OSB sheathing
    else
      mat_ext_finish = Material.RoofMaterialAndSheathing(roof.roof_type) # Combined roof material + OSB sheathing
    end
    mat_int_finish = Material.InteriorFinishMaterial(roof.interior_finish_type, roof.interior_finish_thickness)
    if mat_int_finish.nil?
      fallback_mat_int_finish = nil
    else
      fallback_mat_int_finish = Material.InteriorFinishMaterial(mat_int_finish.name, 0.1) # Try thin material
    end

    install_grade = 1
    assembly_r = roof.insulation_assembly_r_value

    if not mat_int_finish.nil?
      # Closed cavity
      constr_sets = [
        WoodStudConstructionSet.new(Material.Stud2x(8), 0.07, 20.0, 0.0, mat_int_finish, mat_ext_finish),         # 2x8, 24" o.c. + R20
        WoodStudConstructionSet.new(Material.Stud2x(8), 0.07, 10.0, 0.0, mat_int_finish, mat_ext_finish),         # 2x8, 24" o.c. + R10
        WoodStudConstructionSet.new(Material.Stud2x(8), 0.07, 0.0, 0.0, mat_int_finish, mat_ext_finish),          # 2x8, 24" o.c.
        WoodStudConstructionSet.new(Material.Stud2x(6), 0.07, 0.0, 0.0, mat_int_finish, mat_ext_finish),          # 2x6, 24" o.c.
        WoodStudConstructionSet.new(Material.Stud2x(4), 0.01, 0.0, 0.0, fallback_mat_int_finish, mat_ext_finish), # Fallback
      ]
      match, constr_set, cavity_r = pick_wood_stud_construction_set(assembly_r, constr_sets, interior_film, exterior_film)

      apply_closed_cavity_roof(model, surfaces, "#{roof.id} construction",
                               cavity_r, install_grade,
                               constr_set.stud.thick_in,
                               true, constr_set.framing_factor,
                               constr_set.mat_int_finish,
                               constr_set.osb_thick_in, constr_set.rigid_r,
                               constr_set.mat_ext_finish, has_radiant_barrier,
                               interior_film, exterior_film, radiant_barrier_grade,
                               roof.solar_absorptance, roof.emittance)
    else
      # Open cavity
      constr_sets = [
        GenericConstructionSet.new(10.0, 0.0, nil, mat_ext_finish), # w/R-10 rigid
        GenericConstructionSet.new(0.0, 0.0, nil, mat_ext_finish),  # Standard
      ]
      match, constr_set, layer_r = pick_generic_construction_set(assembly_r, constr_sets, interior_film, exterior_film)

      if layer_r + constr_set.rigid_r < 1.0
        # Increase the roof material & sheathing layer to avoid creating
        # a thin insulation layer, which can lead to CTF errors.
        mult = (mat_ext_finish.rvalue + layer_r + constr_set.rigid_r) / mat_ext_finish.rvalue
        mat_ext_finish.thick_in *= mult
        layer_r = 0
        constr_set.rigid_r = 0
      end

      cavity_r = 0
      cavity_ins_thick_in = 0
      framing_factor = 0
      framing_thick_in = 0

      apply_open_cavity_roof(model, surfaces, "#{roof.id} construction",
                             cavity_r, install_grade, cavity_ins_thick_in,
                             framing_factor, framing_thick_in,
                             constr_set.osb_thick_in, layer_r + constr_set.rigid_r,
                             constr_set.mat_ext_finish, has_radiant_barrier,
                             interior_film, exterior_film, radiant_barrier_grade,
                             roof.solar_absorptance, roof.emittance)
    end
    check_surface_assembly_rvalue(runner, surfaces, interior_film, exterior_film, assembly_r, match)
  end

  # Applies a wall construction to the OpenStudio surfaces.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param wall [HPXML::Wall] The HPXML surface that defines the construction
  # @param surfaces [Array<OpenStudio::Model::Surface>] The surfaces to apply the construction to
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply_wall(runner, model, wall, surfaces, hpxml_header)
    has_radiant_barrier = wall.radiant_barrier
    if has_radiant_barrier
      radiant_barrier_grade = wall.radiant_barrier_grade
    end
    interior_film = Material.AirFilmIndoorWall
    if wall.is_exterior
      exterior_film = Material.AirFilmOutside(false, hpxml_header.apply_ashrae140_assumptions)
      mat_ext_finish = Material.ExteriorFinishMaterial(wall.siding)
    else
      exterior_film = Material.AirFilmIndoorWall
      mat_ext_finish = nil
    end
    mat_int_finish = Material.InteriorFinishMaterial(wall.interior_finish_type, wall.interior_finish_thickness)

    apply_wall_construction(runner, model, surfaces, wall.id, wall.wall_type, wall.insulation_assembly_r_value,
                            mat_int_finish, has_radiant_barrier, interior_film, exterior_film,
                            radiant_barrier_grade, mat_ext_finish, wall.solar_absorptance,
                            wall.emittance)
  end

  # Applies a rim joist construction to the OpenStudio surfaces.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param rim_joist [HPXML::RimJoist] The HPXML surface that defines the construction
  # @param surfaces [Array<OpenStudio::Model::Surface>] The surfaces to apply the construction to
  # @return [nil]
  def self.apply_rim_joist(runner, model, rim_joist, surfaces)
    interior_film = Material.AirFilmIndoorWall
    if rim_joist.is_exterior
      exterior_film = Material.AirFilmOutside
      mat_ext_finish = Material.ExteriorFinishMaterial(rim_joist.siding)
    else
      exterior_film = Material.AirFilmIndoorWall
      mat_ext_finish = nil
    end

    assembly_r = rim_joist.insulation_assembly_r_value

    constr_sets = [
      WoodStudConstructionSet.new(Material.Stud2x(2), 0.17, 20.0, 2.0, nil, mat_ext_finish),  # 2x4 + R20
      WoodStudConstructionSet.new(Material.Stud2x(2), 0.17, 10.0, 2.0, nil, mat_ext_finish),  # 2x4 + R10
      WoodStudConstructionSet.new(Material.Stud2x(2), 0.17, 0.0, 2.0, nil, mat_ext_finish),   # 2x4
      WoodStudConstructionSet.new(Material.Stud2x(2), 0.01, 0.0, 0.0, nil, mat_ext_finish),   # Fallback
    ]
    match, constr_set, cavity_r = pick_wood_stud_construction_set(assembly_r, constr_sets, interior_film, exterior_film)
    install_grade = 1

    apply_wood_rim_joist(model, surfaces, "#{rim_joist.id} construction", cavity_r,
                         install_grade, constr_set.stud.thick_in, constr_set.framing_factor,
                         constr_set.mat_int_finish, constr_set.osb_thick_in,
                         constr_set.rigid_r, constr_set.mat_ext_finish,
                         interior_film, exterior_film, rim_joist.solar_absorptance,
                         rim_joist.emittance)
    check_surface_assembly_rvalue(runner, surfaces, interior_film, exterior_film, assembly_r, match)
  end

  # Applies a floor/ceiling construction to the OpenStudio surface.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param floor [HPXML::Floor] The HPXML surface that defines the construction
  # @param surface [OpenStudio::Model::Surface] The surface to apply the construction to
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param zero_wind [Boolean] Whether the surface has wind exposure or not
  # @return [nil]
  def self.apply_floor(runner, model, floor, surface, hpxml_header, zero_wind)
    if floor.is_ceiling
      interior_film = Material.AirFilmIndoorFloorAverage
      exterior_film = Material.AirFilmIndoorFloorAverage
      mat_int_finish_or_covering = Material.InteriorFinishMaterial(floor.interior_finish_type, floor.interior_finish_thickness)
      has_radiant_barrier = floor.radiant_barrier
      if has_radiant_barrier
        radiant_barrier_grade = floor.radiant_barrier_grade
      end
    else # Floor
      if floor.interior_adjacent_to == HPXML::LocationConditionedSpace
        mat_int_finish_or_covering = Material.CoveringBare
      elsif floor.is_exterior && hpxml_header.apply_ashrae140_assumptions
        mat_int_finish_or_covering = Material.CoveringBare(1.0)
      end
      if floor.is_exterior
        interior_film = Material.AirFilmIndoorFloorAverage
        exterior_film = Material.AirFilmOutside(zero_wind)
      else
        interior_film = Material.AirFilmIndoorFloorDown
        exterior_film = Material.AirFilmIndoorFloorDown
      end
    end

    apply_floor_ceiling_construction(runner, model, [surface], floor.id, floor.floor_type, floor.is_ceiling, floor.insulation_assembly_r_value,
                                     mat_int_finish_or_covering, has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade)
  end

  # Applies a slab construction to the OpenStudio surface.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param slab [HPXML::Slab] The HPXML surface that defines the construction
  # @param surface [OpenStudio::Model::Surface] The surface to apply the construction to
  # @param kiva_foundation [OpenStudio::Model::FoundationKiva] OpenStudio Foundation Kiva object
  # @param exposed_length [Double] Length of foundation wall exposed to ambient conditions, specific to an associated HPXML Slab (ft)
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_slab(model, slab, surface, kiva_foundation, exposed_length, hpxml_bldg)
    slab_perim_r = slab.perimeter_insulation_r_value
    slab_perim_depth = slab.perimeter_insulation_depth
    if (slab_perim_r == 0) || (slab_perim_depth == 0)
      slab_perim_r = 0
      slab_perim_depth = 0
    end

    if slab.under_slab_insulation_spans_entire_slab
      slab_whole_r = slab.under_slab_insulation_r_value
      slab_under_r = 0
      slab_under_width = 0
    else
      slab_under_r = slab.under_slab_insulation_r_value
      slab_under_width = slab.under_slab_insulation_width
      if (slab_under_r == 0) || (slab_under_width == 0)
        slab_under_r = 0
        slab_under_width = 0
      end
      slab_whole_r = 0
    end
    slab_gap_r = slab.gap_insulation_r_value

    mat_carpet = nil
    if (slab.carpet_fraction > 0) && (slab.carpet_r_value > 0)
      mat_carpet = Material.CoveringBare(slab.carpet_fraction,
                                         slab.carpet_r_value)
    end
    soil_k_in = UnitConversions.convert(hpxml_bldg.site.ground_conductivity, 'ft', 'in')

    ext_horiz_r = slab.exterior_horizontal_insulation_r_value
    ext_horiz_width = slab.exterior_horizontal_insulation_width
    ext_horiz_depth = slab.exterior_horizontal_insulation_depth_below_grade

    apply_kiva_foundation_slab(model, surface, "#{slab.id} construction",
                               slab_under_r, slab_under_width, slab_gap_r, slab_perim_r,
                               slab_perim_depth, slab_whole_r, slab.thickness,
                               exposed_length, mat_carpet, soil_k_in, kiva_foundation,
                               ext_horiz_r, ext_horiz_width, ext_horiz_depth)
  end

  # Applies a foundation wall construction to the OpenStudio surface.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param foundation_wall [HPXML::FoundationWall] The HPXML surface that defines the construction
  # @param surface [OpenStudio::Model::Surface] The surface to apply the construction to
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_foundation_wall(runner, model, foundation_wall, surface, hpxml_bldg)
    height = foundation_wall.height
    height_ag = height - foundation_wall.depth_below_grade

    assembly_r = foundation_wall.insulation_assembly_r_value
    mat_int_finish = Material.InteriorFinishMaterial(foundation_wall.interior_finish_type, foundation_wall.interior_finish_thickness)
    mat_wall = Material.FoundationWallMaterial(foundation_wall.type, foundation_wall.thickness)
    if not assembly_r.nil?
      ext_rigid_height = height
      ext_rigid_offset = 0.0
      interior_film = Material.AirFilmIndoorWall

      mat_int_finish_rvalue = mat_int_finish.nil? ? 0.0 : mat_int_finish.rvalue
      ext_rigid_r = assembly_r - mat_wall.rvalue - mat_int_finish_rvalue - interior_film.rvalue
      int_rigid_r = 0.0
      if ext_rigid_r < 0 # Try without interior finish
        mat_int_finish = nil
        ext_rigid_r = assembly_r - mat_wall.rvalue - interior_film.rvalue
      end
      if (ext_rigid_r > 0) && (ext_rigid_r < 0.1)
        ext_rigid_r = 0.0 # Prevent tiny strip of insulation
      end
      if ext_rigid_r < 0
        ext_rigid_r = 0.0
        match = false
      else
        match = true
      end
    else
      ext_rigid_offset = foundation_wall.insulation_exterior_distance_to_top
      ext_rigid_height = foundation_wall.insulation_exterior_distance_to_bottom - ext_rigid_offset
      ext_rigid_r = foundation_wall.insulation_exterior_r_value
      int_rigid_offset = foundation_wall.insulation_interior_distance_to_top
      int_rigid_height = foundation_wall.insulation_interior_distance_to_bottom - int_rigid_offset
      int_rigid_r = foundation_wall.insulation_interior_r_value
    end

    soil_k_in = UnitConversions.convert(hpxml_bldg.site.ground_conductivity, 'ft', 'in')

    apply_kiva_foundation_wall(model, [surface], "#{foundation_wall.id} construction",
                               ext_rigid_offset, int_rigid_offset, ext_rigid_height, int_rigid_height,
                               ext_rigid_r, int_rigid_r, mat_int_finish, mat_wall, height_ag,
                               soil_k_in)

    if not assembly_r.nil?
      check_surface_assembly_rvalue(runner, [surface], interior_film, nil, assembly_r, match)
    end
  end

  # Applies an interzonal foundation wall construction to the OpenStudio surface.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param foundation_wall [HPXML::FoundationWall] The HPXML surface that defines the construction
  # @param surface [OpenStudio::Model::Surface] The surface to apply the construction to
  # @return [nil]
  def self.apply_interzonal_foundation_wall(runner, model, foundation_wall, surface)
    wall_type = HPXML::WallTypeConcrete
    interior_film = Material.AirFilmIndoorWall
    exterior_film = Material.AirFilmIndoorWall
    assembly_r = foundation_wall.insulation_assembly_r_value
    mat_int_finish = Material.InteriorFinishMaterial(foundation_wall.interior_finish_type, foundation_wall.interior_finish_thickness)
    if assembly_r.nil?
      concrete_thick_in = foundation_wall.thickness
      int_r = foundation_wall.insulation_interior_r_value
      ext_r = foundation_wall.insulation_exterior_r_value
      mat_concrete = Material.Concrete(concrete_thick_in)
      mat_int_finish_rvalue = mat_int_finish.nil? ? 0.0 : mat_int_finish.rvalue
      assembly_r = int_r + ext_r + mat_concrete.rvalue + mat_int_finish_rvalue + interior_film.rvalue + exterior_film.rvalue
    end
    mat_ext_finish = nil

    apply_wall_construction(runner, model, [surface], foundation_wall.id, wall_type, assembly_r, mat_int_finish,
                            false, interior_film, exterior_film, nil, mat_ext_finish, nil, nil)
  end

  # Creates a wood stud wall construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param cavity_r [Double] R-value of the cavity insulation (hr-ft2-F/Btu)
  # @param install_grade [Integer] Insulation installation grade as defined by RESNET (1-3)
  # @param stud_depth_in [Double] Depth of the wood studs (in)
  # @param cavity_filled [Boolean] Whether the cavity insulation completely fills the depth of the cavity
  # @param framing_factor [Double] Fraction of total surface area comprised of structural framing and framing for windows/doors (frac)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic gable wall)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @param solar_absorptance [Double] Solar absorptance of the outermost material (frac)
  # @param emittance [Double] Emittance of the outermost material (frac)
  # @return [nil]
  def self.apply_wood_stud_wall(model, surfaces, constr_name, cavity_r, install_grade, stud_depth_in,
                                cavity_filled, framing_factor, mat_int_finish, osb_thick_in, rigid_r,
                                mat_ext_finish, has_radiant_barrier, interior_film, exterior_film,
                                radiant_barrier_grade, solar_absorptance = nil, emittance = nil)
    return if surfaces.empty?

    # Define materials
    if cavity_r > 0
      if cavity_filled
        # Insulation
        mat_cavity = Material.new(thick_in: stud_depth_in, mat_base: BaseMaterial.InsulationGenericDensepack, k_in: stud_depth_in / cavity_r)
      else
        # Insulation plus air gap when insulation thickness < cavity depth
        mat_cavity = Material.new(thick_in: stud_depth_in, mat_base: BaseMaterial.InsulationGenericDensepack, k_in: stud_depth_in / (cavity_r + Gas.AirGapRvalue))
      end
    else
      # Empty cavity
      mat_cavity = Material.AirCavityClosed(stud_depth_in)
    end
    mat_framing = Material.new(thick_in: stud_depth_in, mat_base: BaseMaterial.Wood)
    mat_gap = Material.AirCavityClosed(stud_depth_in)
    mat_osb = nil
    if osb_thick_in > 0
      mat_osb = Material.OSBSheathing(osb_thick_in)
    end
    mat_rigid = nil
    if rigid_r > 0
      rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
      mat_rigid = Material.new(name: 'wall rigid ins', thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
    end
    mat_rb = nil
    if has_radiant_barrier
      mat_rb = Material.RadiantBarrier(radiant_barrier_grade)
    end

    # Set paths
    ins_gap_frac = get_install_grade_gap_fraction(install_grade, cavity_r > 0)
    ins_factor = 1 - framing_factor
    path_fracs = [framing_factor, ins_factor * (1 - ins_gap_frac), ins_factor * ins_gap_frac]

    # Define construction
    constr = Construction.new(constr_name, path_fracs)
    constr.add_layer(exterior_film)
    if not mat_ext_finish.nil?
      constr.add_layer(mat_ext_finish)
    end
    if not mat_rigid.nil?
      constr.add_layer(mat_rigid)
    end
    if not mat_osb.nil?
      constr.add_layer(mat_osb)
    end
    constr.add_layer([mat_framing, mat_cavity, mat_gap], 'wall stud and cavity')
    if not mat_int_finish.nil?
      constr.add_layer(mat_int_finish)
    end
    if not mat_rb.nil?
      constr.add_layer(mat_rb)
    end
    constr.add_layer(interior_film)

    constr.set_exterior_material_properties(solar_absorptance, emittance)
    constr.set_interior_material_properties() unless has_radiant_barrier

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Creates a double wood stud wall construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param cavity_r [Double] R-value of the cavity insulation (hr-ft2-F/Btu)
  # @param install_grade [Integer] Insulation installation grade as defined by RESNET (1-3)
  # @param stud_depth_in [Double] Depth of the wood studs (in)
  # @param gap_depth_in [Double] Depth of the gap between the wood studs (in)
  # @param framing_factor [Double] Fraction of total surface area comprised of structural framing and framing for windows/doors (frac)
  # @param framing_spacing [Double] The on-center spacing between framing (in)
  # @param is_staggered [Boolean] Whether the wood studs are staggered or aligned
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic gable wall)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @param solar_absorptance [Double] Solar absorptance of the outermost material (frac)
  # @param emittance [Double] Emittance of the outermost material (frac)
  # @return [nil]
  def self.apply_double_stud_wall(model, surfaces, constr_name, cavity_r, install_grade, stud_depth_in,
                                  gap_depth_in, framing_factor, framing_spacing, is_staggered,
                                  mat_int_finish, osb_thick_in, rigid_r, mat_ext_finish,
                                  has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade,
                                  solar_absorptance = nil, emittance = nil)

    return if surfaces.empty?

    # Define materials
    cavity_depth_in = 2.0 * stud_depth_in + gap_depth_in
    mat_ins_inner_outer = Material.new(thick_in: stud_depth_in, mat_base: BaseMaterial.InsulationGenericDensepack, k_in: cavity_depth_in / cavity_r)
    mat_ins_middle = Material.new(thick_in: gap_depth_in, mat_base: BaseMaterial.InsulationGenericDensepack, k_in: cavity_depth_in / cavity_r)
    mat_framing_inner_outer = Material.new(thick_in: stud_depth_in, mat_base: BaseMaterial.Wood)
    mat_framing_middle = Material.new(thick_in: gap_depth_in, mat_base: BaseMaterial.Wood)
    mat_stud = Material.new(thick_in: stud_depth_in, mat_base: BaseMaterial.Wood)
    mat_gap_total = Material.AirCavityClosed(cavity_depth_in)
    mat_gap_inner_outer = Material.new(thick_in: stud_depth_in, k_in: stud_depth_in / (mat_gap_total.rvalue * stud_depth_in / cavity_depth_in), rho: Gas.Air.rho, cp: Gas.Air.cp)
    mat_gap_middle = Material.new(thick_in: gap_depth_in, k_in: gap_depth_in / (mat_gap_total.rvalue * gap_depth_in / cavity_depth_in), rho: Gas.Air.rho, cp: Gas.Air.cp)
    mat_osb = nil
    if osb_thick_in > 0
      mat_osb = Material.OSBSheathing(osb_thick_in)
    end
    mat_rigid = nil
    if rigid_r > 0
      rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
      mat_rigid = Material.new(name: 'wall rigid ins', thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
    end

    mat_rb = nil
    if has_radiant_barrier
      mat_rb = Material.RadiantBarrier(radiant_barrier_grade)
    end

    # Set paths
    stud_frac = 1.5 / framing_spacing
    misc_framing_factor = framing_factor - stud_frac
    if misc_framing_factor < 0
      stud_frac = framing_factor
      misc_framing_factor = 0.0
    end

    ins_gap_frac = get_install_grade_gap_fraction(install_grade, cavity_r > 0)
    ins_factor = 1 - misc_framing_factor - 2 * stud_frac
    path_fracs = [misc_framing_factor, stud_frac, stud_frac, ins_factor * ins_gap_frac, ins_factor * (1 - ins_gap_frac)]

    # Define construction
    constr = Construction.new(constr_name, path_fracs)
    constr.add_layer(exterior_film)
    if not mat_ext_finish.nil?
      constr.add_layer(mat_ext_finish)
    end
    if not mat_rigid.nil?
      constr.add_layer(mat_rigid)
    end
    if not mat_osb.nil?
      constr.add_layer(mat_osb)
    end
    if is_staggered
      constr.add_layer([mat_framing_inner_outer, mat_ins_inner_outer, mat_stud, mat_gap_inner_outer, mat_ins_inner_outer], 'wall stud and cavity')
    else
      constr.add_layer([mat_framing_inner_outer, mat_stud, mat_ins_inner_outer, mat_gap_inner_outer, mat_ins_inner_outer], 'wall stud and cavity')
    end
    if gap_depth_in > 0
      constr.add_layer([mat_framing_middle, mat_ins_middle, mat_ins_middle, mat_gap_middle, mat_ins_middle], 'wall cavity')
    end
    constr.add_layer([mat_framing_inner_outer, mat_stud, mat_ins_inner_outer, mat_gap_inner_outer, mat_ins_inner_outer], 'wall stud and cavity')
    if not mat_int_finish.nil?
      constr.add_layer(mat_int_finish)
    end
    if not mat_rb.nil?
      constr.add_layer(mat_rb)
    end
    constr.add_layer(interior_film)

    constr.set_exterior_material_properties(solar_absorptance, emittance)
    constr.set_interior_material_properties() unless has_radiant_barrier

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Creates a concrete masonry unit (CMU) wall construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param thick_in [Double] Thickness of the CMU (in)
  # @param conductivity_in [Double] Conductivity of the CMU (Btu-in/h-ft2-F)
  # @param density [Double] Density of the CMU (lb/ft3)
  # @param framing_factor [Double] Fraction of total surface area comprised of framing for windows/doors (frac)
  # @param furring_r [Double] R-value of the insulation filling the furring cavity (hr-ft2-F/Btu)
  # @param furring_cavity_depth_in [Double] Depth of the interior furring cavity (in)
  # @param furring_spacing [Double] On-center spacing of the furring strips (in)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic gable wall)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @param solar_absorptance [Double] Solar absorptance of the outermost material (frac)
  # @param emittance [Double] Emittance of the outermost material (frac)
  # @return [nil]
  def self.apply_cmu_wall(model, surfaces, constr_name, thick_in, conductivity_in, density, framing_factor,
                          furring_r, furring_cavity_depth_in, furring_spacing, mat_int_finish, osb_thick_in,
                          rigid_r, mat_ext_finish, has_radiant_barrier, interior_film, exterior_film,
                          radiant_barrier_grade, solar_absorptance = nil, emittance = nil)

    return if surfaces.empty?

    # Define materials
    mat_cmu = Material.new(thick_in: thick_in, mat_base: BaseMaterial.Concrete, k_in: conductivity_in, rho: density)
    mat_framing = Material.new(thick_in: thick_in, mat_base: BaseMaterial.Wood)
    mat_furring = nil
    mat_furring_cavity = nil
    if furring_cavity_depth_in != 0
      mat_furring = Material.new(thick_in: furring_cavity_depth_in, mat_base: BaseMaterial.Wood)
      if furring_r == 0
        mat_furring_cavity = Material.AirCavityClosed(furring_cavity_depth_in)
      else
        mat_furring_cavity = Material.new(thick_in: furring_cavity_depth_in, mat_base: BaseMaterial.InsulationGenericDensepack, k_in: furring_cavity_depth_in / furring_r)
      end
    end
    mat_osb = nil
    if osb_thick_in > 0
      mat_osb = Material.OSBSheathing(osb_thick_in)
    end
    mat_rigid = nil
    if rigid_r > 0
      rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
      mat_rigid = Material.new(name: 'wall rigid ins', thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
    end
    mat_rb = nil
    if has_radiant_barrier
      mat_rb = Material.RadiantBarrier(radiant_barrier_grade)
    end

    # Set paths
    if not mat_furring.nil?
      stud_frac = 1.5 / furring_spacing
      cavity_frac = 1.0 - (stud_frac + framing_factor)
      path_fracs = [framing_factor, stud_frac, cavity_frac]
    else # No furring:
      path_fracs = [framing_factor, 1.0 - framing_factor]
    end

    # Define construction
    constr = Construction.new(constr_name, path_fracs)
    constr.add_layer(exterior_film)
    if not mat_ext_finish.nil?
      constr.add_layer(mat_ext_finish)
    end
    if not mat_rigid.nil?
      constr.add_layer(mat_rigid)
    end
    if not mat_osb.nil?
      constr.add_layer(mat_osb)
    end
    if not mat_furring.nil?
      constr.add_layer([mat_framing, mat_cmu, mat_cmu], 'concrete block')
      constr.add_layer([mat_furring, mat_furring, mat_furring_cavity], 'furring')
    else
      constr.add_layer([mat_framing, mat_cmu], 'concrete block')
    end
    if not mat_int_finish.nil?
      constr.add_layer(mat_int_finish)
    end
    if not mat_rb.nil?
      constr.add_layer(mat_rb)
    end
    constr.add_layer(interior_film)

    constr.set_exterior_material_properties(solar_absorptance, emittance)
    constr.set_interior_material_properties() unless has_radiant_barrier

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Creates an insulated concrete form (ICF) wall construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param ins_r [Double] R-value of each insulation layer (hr-ft2-F/Btu)
  # @param ins_thick_in [Double] Thickness of each insulation layer (in)
  # @param concrete_thick_in [Double] Thickness of the concrete form (in)
  # @param framing_factor [Double] Fraction of total surface area comprised of framing for windows/doors (frac)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic gable wall)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @param solar_absorptance [Double] Solar absorptance of the outermost material (frac)
  # @param emittance [Double] Emittance of the outermost material (frac)
  # @return [nil]
  def self.apply_icf_wall(model, surfaces, constr_name, ins_r, ins_thick_in, concrete_thick_in,
                          framing_factor, mat_int_finish, osb_thick_in, rigid_r, mat_ext_finish,
                          has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade,
                          solar_absorptance = nil, emittance = nil)

    return if surfaces.empty?

    # Define materials
    mat_ins = Material.new(thick_in: ins_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: ins_thick_in / ins_r)
    mat_conc = Material.new(thick_in: concrete_thick_in, mat_base: BaseMaterial.Concrete)
    mat_framing_inner_outer = Material.new(thick_in: ins_thick_in, mat_base: BaseMaterial.Wood)
    mat_framing_middle = Material.new(thick_in: concrete_thick_in, mat_base: BaseMaterial.Wood)
    mat_osb = nil
    if osb_thick_in > 0
      mat_osb = Material.OSBSheathing(osb_thick_in)
    end
    mat_rigid = nil
    if rigid_r > 0
      rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
      mat_rigid = Material.new(name: 'wall rigid ins', thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
    end

    mat_rb = nil
    if has_radiant_barrier
      mat_rb = Material.RadiantBarrier(radiant_barrier_grade)
    end

    # Set paths
    path_fracs = [framing_factor, 1.0 - framing_factor]

    # Define construction
    constr = Construction.new(constr_name, path_fracs)
    constr.add_layer(exterior_film)
    if not mat_ext_finish.nil?
      constr.add_layer(mat_ext_finish)
    end
    if not mat_rigid.nil?
      constr.add_layer(mat_rigid)
    end
    if not mat_osb.nil?
      constr.add_layer(mat_osb)
    end
    constr.add_layer([mat_framing_inner_outer, mat_ins], 'wall ins form')
    constr.add_layer([mat_framing_middle, mat_conc], 'wall concrete')
    constr.add_layer([mat_framing_inner_outer, mat_ins], 'wall ins form')
    if not mat_int_finish.nil?
      constr.add_layer(mat_int_finish)
    end
    if not mat_rb.nil?
      constr.add_layer(mat_rb)
    end
    constr.add_layer(interior_film)

    constr.set_exterior_material_properties(solar_absorptance, emittance)
    constr.set_interior_material_properties() unless has_radiant_barrier

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Creates a structural insulated panel (SIP) wall construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param ins_r [Double] R-value of the insulating core of the SIP (hr-ft2-F/Btu)
  # @param ins_thick_in [Double] Thickness of the insulating core of the SIP (in)
  # @param framing_factor [Double] Fraction of total surface area comprised of framing for windows/doors (frac)
  # @param sheath_thick_in [Double] Thickness of the interior sheathing (in)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic gable wall)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @param solar_absorptance [Double] Solar absorptance of the outermost material (frac)
  # @param emittance [Double] Emittance of the outermost material (frac)
  # @return [nil]
  def self.apply_sip_wall(model, surfaces, constr_name, ins_r, ins_thick_in, framing_factor,
                          sheath_thick_in, mat_int_finish, osb_thick_in, rigid_r, mat_ext_finish,
                          has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade,
                          solar_absorptance = nil, emittance = nil)

    return if surfaces.empty?

    # Define materials
    spline_thick_in = 0.5
    middle_thick_in = ins_thick_in - (2.0 * spline_thick_in) # in
    mat_int_sheath = Material.OSBSheathing(sheath_thick_in) # Assumed to be OSB, but could be gyp, crete, etc.
    mat_framing_inner_outer = Material.new(thick_in: spline_thick_in, mat_base: BaseMaterial.Wood)
    mat_framing_middle = Material.new(thick_in: middle_thick_in, mat_base: BaseMaterial.Wood)
    mat_spline = Material.new(thick_in: spline_thick_in, mat_base: BaseMaterial.Wood)
    mat_ins_inner_outer = Material.new(thick_in: spline_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: ins_thick_in / ins_r)
    mat_ins_middle = Material.new(thick_in: middle_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: ins_thick_in / ins_r)
    mat_osb = nil
    if osb_thick_in > 0
      mat_osb = Material.OSBSheathing(osb_thick_in)
    end
    mat_rigid = nil
    if rigid_r > 0
      rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
      mat_rigid = Material.new(name: 'wall rigid ins', thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
    end

    mat_rb = nil
    if has_radiant_barrier
      mat_rb = Material.RadiantBarrier(radiant_barrier_grade)
    end

    # Set paths
    spline_frac = 4.0 / 48.0 # One 4" spline for every 48" wide panel
    cavity_frac = 1.0 - (spline_frac + framing_factor)
    path_fracs = [framing_factor, spline_frac, cavity_frac]

    # Define construction
    constr = Construction.new(constr_name, path_fracs)
    constr.add_layer(exterior_film)
    if not mat_ext_finish.nil?
      constr.add_layer(mat_ext_finish)
    end
    if not mat_rigid.nil?
      constr.add_layer(mat_rigid)
    end
    if not mat_osb.nil?
      constr.add_layer(mat_osb)
    end
    constr.add_layer([mat_framing_inner_outer, mat_spline, mat_ins_inner_outer], 'wall spline layer')
    constr.add_layer([mat_framing_middle, mat_ins_middle, mat_ins_middle], 'wall ins layer')
    constr.add_layer([mat_framing_inner_outer, mat_spline, mat_ins_inner_outer], 'wall spline layer')
    constr.add_layer(mat_int_sheath)
    if not mat_int_finish.nil?
      constr.add_layer(mat_int_finish)
    end
    if not mat_rb.nil?
      constr.add_layer(mat_rb)
    end
    constr.add_layer(interior_film)

    constr.set_exterior_material_properties(solar_absorptance, emittance)
    constr.set_interior_material_properties() unless has_radiant_barrier

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Creates a steel frame wall construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param cavity_r [Double] R-value of the cavity insulation (hr-ft2-F/Btu)
  # @param install_grade [Integer] Insulation installation grade as defined by RESNET (1-3)
  # @param cavity_depth_in [Double] Depth of the cavity (in)
  # @param cavity_filled [Boolean] Whether the cavity insulation completely fills the depth of the cavity
  # @param corr_factor [Double] Parallel path correction factor per ASHRAE 90.1 to determine the effective thermal resistance of steel construction (frac)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic gable wall)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @param solar_absorptance [Double] Solar absorptance of the outermost material (frac)
  # @param emittance [Double] Emittance of the outermost material (frac)
  # @return [nil]
  def self.apply_steel_stud_wall(model, surfaces, constr_name, cavity_r, install_grade, cavity_depth_in, cavity_filled,
                                 corr_factor, mat_int_finish, osb_thick_in, rigid_r, mat_ext_finish, has_radiant_barrier,
                                 interior_film, exterior_film, radiant_barrier_grade, solar_absorptance = nil, emittance = nil)

    return if surfaces.empty?

    # Define materials
    effective_r = cavity_r * corr_factor # The effective R-value of the cavity insulation with steel stud framing
    if effective_r > 0
      if cavity_filled
        # Insulation
        mat_cavity = Material.new(thick_in: cavity_depth_in, mat_base: BaseMaterial.InsulationGenericDensepack, k_in: cavity_depth_in / effective_r)
      else
        # Insulation plus air gap when insulation thickness < cavity depth
        mat_cavity = Material.new(thick_in: cavity_depth_in, mat_base: BaseMaterial.InsulationGenericDensepack, k_in: cavity_depth_in / (effective_r + Gas.AirGapRvalue))
      end
    else
      # Empty cavity
      mat_cavity = Material.AirCavityClosed(cavity_depth_in)
    end
    mat_gap = Material.AirCavityClosed(cavity_depth_in)
    mat_osb = nil
    if osb_thick_in > 0
      mat_osb = Material.OSBSheathing(osb_thick_in)
    end
    mat_rigid = nil
    if rigid_r > 0
      rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
      mat_rigid = Material.new(name: 'wall rigid ins', thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
    end

    mat_rb = nil
    if has_radiant_barrier
      mat_rb = Material.RadiantBarrier(radiant_barrier_grade)
    end

    # Set paths
    ins_gap_frac = get_install_grade_gap_fraction(install_grade, cavity_r > 0)
    path_fracs = [1 - ins_gap_frac, ins_gap_frac]

    # Define construction
    constr = Construction.new(constr_name, path_fracs)
    constr.add_layer(exterior_film)
    if not mat_ext_finish.nil?
      constr.add_layer(mat_ext_finish)
    end
    if not mat_rigid.nil?
      constr.add_layer(mat_rigid)
    end
    if not mat_osb.nil?
      constr.add_layer(mat_osb)
    end
    constr.add_layer([mat_cavity, mat_gap], 'wall stud and cavity')
    if not mat_int_finish.nil?
      constr.add_layer(mat_int_finish)
    end
    if not mat_rb.nil?
      constr.add_layer(mat_rb)
    end
    constr.add_layer(interior_film)

    constr.set_exterior_material_properties(solar_absorptance, emittance)
    constr.set_interior_material_properties() unless has_radiant_barrier

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Creates a generic layer-by-layer wall construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param layers_thick_in [Array<Double>] Thickness of each layer from outermost to innermost (in)
  # @param layers_conductivity_in [Array<Double>] Conductivity of each layer from outermost to innermost (Btu-in/h-ft2-F)
  # @param layers_density [Array<Double>] Density of each layer from outermost to innermost (lb/ft3)
  # @param layers_spec_heat [Array<Double>] Specific heat of each layer from outermost to innermost (Btu/lb-F)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic gable wall)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @param solar_absorptance [Double] Solar absorptance of the outermost material (frac)
  # @param emittance [Double] Emittance of the outermost material (frac)
  # @return [nil]
  def self.apply_generic_layered_wall(model, surfaces, constr_name, layers_thick_in, layers_conductivity_in, layers_density,
                                      layers_spec_heat, mat_int_finish, osb_thick_in, rigid_r, mat_ext_finish,
                                      has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade,
                                      solar_absorptance = nil, emittance = nil)

    return if surfaces.empty?

    # Validate inputs
    for idx in 0..4
      next unless (layers_thick_in[idx].nil? != layers_conductivity_in[idx].nil?) ||
                  (layers_thick_in[idx].nil? != layers_density[idx].nil?) ||
                  (layers_thick_in[idx].nil? != layers_spec_heat[idx].nil?)

      fail "Layer #{idx + 1} does not have all four properties (thickness, conductivity, density, specific heat) entered."
    end

    # Define materials
    mats = []
    mats << Material.new(name: 'wall layer 1', thick_in: layers_thick_in[0], k_in: layers_conductivity_in[0], rho: layers_density[0], cp: layers_spec_heat[0])
    if not layers_thick_in[1].nil?
      mats << Material.new(name: 'wall layer 2', thick_in: layers_thick_in[1], k_in: layers_conductivity_in[1], rho: layers_density[1], cp: layers_spec_heat[1])
    end
    if not layers_thick_in[2].nil?
      mats << Material.new(name: 'wall layer 3', thick_in: layers_thick_in[2], k_in: layers_conductivity_in[2], rho: layers_density[2], cp: layers_spec_heat[2])
    end
    if not layers_thick_in[3].nil?
      mats << Material.new(name: 'wall layer 4', thick_in: layers_thick_in[3], k_in: layers_conductivity_in[3], rho: layers_density[3], cp: layers_spec_heat[3])
    end
    if not layers_thick_in[4].nil?
      mats << Material.new(name: 'wall layer 5', thick_in: layers_thick_in[4], k_in: layers_conductivity_in[4], rho: layers_density[4], cp: layers_spec_heat[4])
    end
    mat_osb = nil
    if osb_thick_in > 0
      mat_osb = Material.OSBSheathing(osb_thick_in)
    end
    mat_rigid = nil
    if rigid_r > 0
      rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
      mat_rigid = Material.new(name: 'wall rigid ins', thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
    end
    mat_rb = nil
    if has_radiant_barrier
      mat_rb = Material.RadiantBarrier(radiant_barrier_grade)
    end

    # Define construction
    constr = Construction.new(constr_name, [1])
    constr.add_layer(exterior_film)
    if not mat_ext_finish.nil?
      constr.add_layer(mat_ext_finish)
    end
    if not mat_rigid.nil?
      constr.add_layer(mat_rigid)
    end
    if not mat_osb.nil?
      constr.add_layer(mat_osb)
    end
    mats.each do |mat|
      constr.add_layer(mat)
    end
    if not mat_int_finish.nil?
      constr.add_layer(mat_int_finish)
    end
    if not mat_rb.nil?
      constr.add_layer(mat_rb)
    end
    constr.add_layer(interior_film)

    constr.set_exterior_material_properties(solar_absorptance, emittance)
    constr.set_interior_material_properties() unless has_radiant_barrier

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Creates a wood frame rim joist construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param cavity_r [Double] R-value of the cavity insulation (hr-ft2-F/Btu)
  # @param install_grade [Integer] Insulation installation grade as defined by RESNET (1-3)
  # @param joist_thick_in [Double] Thickness of the joist (in)
  # @param framing_factor [Double] Fraction of total surface area comprised of structural framing (frac)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param solar_absorptance [Double] Solar absorptance of the outermost material (frac)
  # @param emittance [Double] Emittance of the outermost material (frac)
  # @return [nil]
  def self.apply_wood_rim_joist(model, surfaces, constr_name, cavity_r, install_grade, joist_thick_in, framing_factor,
                                mat_int_finish, osb_thick_in, rigid_r, mat_ext_finish, interior_film,
                                exterior_film, solar_absorptance = nil, emittance = nil)

    return if surfaces.empty?

    # Define materials
    if cavity_r > 0
      # Insulation
      mat_cavity = Material.new(thick_in: joist_thick_in, mat_base: BaseMaterial.InsulationGenericDensepack, k_in: joist_thick_in / cavity_r)
    else
      # Empty cavity
      mat_cavity = Material.AirCavityOpen(joist_thick_in)
    end
    mat_framing = Material.new(thick_in: joist_thick_in, mat_base: BaseMaterial.Wood)
    mat_gap = Material.AirCavityClosed(joist_thick_in)
    mat_osb = nil
    if osb_thick_in > 0
      mat_osb = Material.OSBSheathing(osb_thick_in)
    end
    mat_rigid = nil
    if rigid_r > 0
      rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
      mat_rigid = Material.new(name: 'rim joist rigid ins', thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
    end

    # Set paths
    ins_gap_frac = get_install_grade_gap_fraction(install_grade, cavity_r > 0)
    ins_factor = 1 - framing_factor
    path_fracs = [framing_factor, ins_factor * (1 - ins_gap_frac), ins_factor * ins_gap_frac]

    # Define construction
    constr = Construction.new(constr_name, path_fracs)
    constr.add_layer(exterior_film)
    if not mat_ext_finish.nil?
      constr.add_layer(mat_ext_finish)
    end
    if not mat_rigid.nil?
      constr.add_layer(mat_rigid)
    end
    if not mat_osb.nil?
      constr.add_layer(mat_osb)
    end
    constr.add_layer([mat_framing, mat_cavity, mat_gap], 'rim joist stud and cavity')
    if not mat_int_finish.nil?
      constr.add_layer(mat_int_finish)
    end
    constr.add_layer(interior_film)

    constr.set_exterior_material_properties(solar_absorptance, emittance)
    constr.set_interior_material_properties()

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Creates an open cavity, wood frame roof construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param cavity_r [Double] R-value of the cavity insulation (hr-ft2-F/Btu)
  # @param install_grade [Integer] Insulation installation grade as defined by RESNET (1-3)
  # @param cavity_ins_thick_in [Double] Thickness of the cavity insulation (in)
  # @param framing_factor [Double] Fraction of total surface area comprised of structural framing (frac)
  # @param framing_thick_in [Double] Thickness of the framing (in)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., roofing material)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic roof)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @param solar_absorptance [Double] Solar absorptance of the outermost material (frac)
  # @param emittance [Double] Emittance of the outermost material (frac)
  # @return [nil]
  def self.apply_open_cavity_roof(model, surfaces, constr_name, cavity_r, install_grade,
                                  cavity_ins_thick_in, framing_factor, framing_thick_in, osb_thick_in,
                                  rigid_r, mat_ext_finish, has_radiant_barrier, interior_film, exterior_film,
                                  radiant_barrier_grade, solar_absorptance = nil, emittance = nil)

    return if surfaces.empty?

    # Define materials
    roof_ins_thickness_in = [cavity_ins_thick_in, framing_thick_in].max
    if cavity_r == 0
      mat_cavity = Material.AirCavityOpen(roof_ins_thickness_in)
    else
      cavity_k = cavity_ins_thick_in / cavity_r
      if cavity_ins_thick_in < framing_thick_in
        cavity_k = cavity_k * framing_thick_in / cavity_ins_thick_in
      end
      mat_cavity = Material.new(thick_in: roof_ins_thickness_in, mat_base: BaseMaterial.InsulationGenericDensepack, k_in: cavity_k)
    end
    if (cavity_ins_thick_in > framing_thick_in) && (framing_thick_in > 0)
      wood_k = BaseMaterial.Wood.k_in * cavity_ins_thick_in / framing_thick_in
    else
      wood_k = BaseMaterial.Wood.k_in
    end
    mat_framing = Material.new(thick_in: roof_ins_thickness_in, mat_base: BaseMaterial.Wood, k_in: wood_k)
    mat_gap = Material.AirCavityOpen(roof_ins_thickness_in)
    mat_osb = nil
    if osb_thick_in > 0
      mat_osb = Material.OSBSheathing(osb_thick_in)
    end
    mat_rigid = nil
    if rigid_r > 0
      rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
      mat_rigid = Material.new(name: 'roof rigid ins', thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
    end
    mat_rb = nil
    if has_radiant_barrier
      mat_rb = Material.RadiantBarrier(radiant_barrier_grade)
    end

    # Set paths
    ins_gap_frac = get_install_grade_gap_fraction(install_grade, cavity_r > 0)
    ins_factor = 1 - framing_factor
    path_fracs = [framing_factor, ins_factor * (1 - ins_gap_frac), ins_factor * ins_gap_frac]

    # Define construction
    constr = Construction.new(constr_name, path_fracs)
    constr.add_layer(exterior_film)
    if not mat_ext_finish.nil?
      constr.add_layer(mat_ext_finish)
    end
    if not mat_rigid.nil?
      constr.add_layer(mat_rigid)
    end
    if not mat_osb.nil?
      constr.add_layer(mat_osb)
    end
    if framing_thick_in > 0
      constr.add_layer([mat_framing, mat_cavity, mat_gap], 'roof stud and cavity')
    end
    if not mat_rb.nil?
      constr.add_layer(mat_rb)
    end
    constr.add_layer(interior_film)

    constr.set_exterior_material_properties(solar_absorptance, emittance)
    constr.set_interior_material_properties() unless has_radiant_barrier

    # Create and assign construction to roof surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Creates a closed cavity, wood frame roof construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param cavity_r [Double] R-value of the cavity insulation (hr-ft2-F/Btu)
  # @param install_grade [Integer] Insulation installation grade as defined by RESNET (1-3)
  # @param cavity_depth_in [Double] Depth of the cavity (in)
  # @param cavity_filled [Boolean] Whether the cavity insulation completely fills the depth of the cavity
  # @param framing_factor [Double] Fraction of total surface area comprised of structural framing (frac)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., roofing material)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic roof)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @param solar_absorptance [Double] Solar absorptance of the outermost material (frac)
  # @param emittance [Double] Emittance of the outermost material (frac)
  # @return [nil]
  def self.apply_closed_cavity_roof(model, surfaces, constr_name, cavity_r, install_grade, cavity_depth_in,
                                    cavity_filled, framing_factor, mat_int_finish,
                                    osb_thick_in, rigid_r, mat_ext_finish, has_radiant_barrier,
                                    interior_film, exterior_film, radiant_barrier_grade,
                                    solar_absorptance = nil, emittance = nil)

    return if surfaces.empty?

    # Define materials
    if cavity_r > 0
      if cavity_filled
        # Insulation
        mat_cavity = Material.new(thick_in: cavity_depth_in, mat_base: BaseMaterial.InsulationGenericDensepack, k_in: cavity_depth_in / cavity_r)
      else
        # Insulation plus air gap when insulation thickness < cavity depth
        mat_cavity = Material.new(thick_in: cavity_depth_in, mat_base: BaseMaterial.InsulationGenericDensepack, k_in: cavity_depth_in / (cavity_r + Gas.AirGapRvalue))
      end
    else
      # Empty cavity
      mat_cavity = Material.AirCavityClosed(cavity_depth_in)
    end
    mat_framing = Material.new(thick_in: cavity_depth_in, mat_base: BaseMaterial.Wood)
    mat_gap = Material.AirCavityClosed(cavity_depth_in)
    mat_osb = nil
    if osb_thick_in > 0
      mat_osb = Material.OSBSheathing(osb_thick_in)
    end
    mat_rigid = nil
    if rigid_r > 0
      rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
      mat_rigid = Material.new(name: 'roof rigid ins', thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
    end
    mat_rb = nil
    if has_radiant_barrier
      mat_rb = Material.RadiantBarrier(radiant_barrier_grade)
    end

    # Set paths
    ins_gap_frac = get_install_grade_gap_fraction(install_grade, cavity_r > 0)
    ins_factor = 1 - framing_factor
    path_fracs = [framing_factor, ins_factor * (1 - ins_gap_frac), ins_factor * ins_gap_frac]

    # Define construction
    constr = Construction.new(constr_name, path_fracs)
    constr.add_layer(exterior_film)
    if not mat_ext_finish.nil?
      constr.add_layer(mat_ext_finish)
    end
    if not mat_rigid.nil?
      constr.add_layer(mat_rigid)
    end
    if not mat_osb.nil?
      constr.add_layer(mat_osb)
    end
    constr.add_layer([mat_framing, mat_cavity, mat_gap], 'roof stud and cavity')
    if not mat_int_finish.nil?
      constr.add_layer(mat_int_finish)
    end
    if not mat_rb.nil?
      constr.add_layer(mat_rb)
    end
    constr.add_layer(interior_film)

    constr.set_exterior_material_properties(solar_absorptance, emittance)
    constr.set_interior_material_properties() unless has_radiant_barrier

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Creates a wood frame ceiling/floor construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param is_ceiling [Boolean] Whether the HPXML Floor represents a ceiling or floor surface
  # @param cavity_r [Double] R-value of the cavity insulation (hr-ft2-F/Btu)
  # @param install_grade [Integer] Insulation installation grade as defined by RESNET (1-3)
  # @param framing_factor [Double] Fraction of total surface area comprised of structural framing (frac)
  # @param joist_height_in [Double] Thickness of the joist height (in)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_int_finish_or_covering [Material] Material properties for the ceiling interior finish (e.g., drywall) or floor covering (e.g., carpet)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic floor)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @return [nil]
  def self.apply_wood_frame_floor_ceiling(model, surfaces, constr_name, is_ceiling, cavity_r, install_grade,
                                          framing_factor, joist_height_in, osb_thick_in,
                                          rigid_r, mat_int_finish_or_covering, has_radiant_barrier,
                                          interior_film, exterior_film, radiant_barrier_grade)

    # Interior finish below, open cavity above (e.g., attic floor)
    # Open cavity below, floor covering above (e.g., crawlspace ceiling)

    return if surfaces.empty?

    if is_ceiling
      # Define materials
      mat_addtl_ins = nil
      if cavity_r == 0
        mat_cavity = Material.AirCavityOpen(joist_height_in)
      else
        if rigid_r > 0
          # If there is additional insulation beyond the rafter height,
          # these inputs are used for defining an additional layer
          addtl_thick_in = rigid_r / 3.0 # Assume roughly R-3 per inch of loose-fill above cavity
          mat_addtl_ins = Material.new(name: 'ceiling loosefill ins', thick_in: addtl_thick_in, mat_base: BaseMaterial.InsulationGenericLoosefill, k_in: addtl_thick_in / rigid_r)
        end

        mat_cavity = Material.new(thick_in: joist_height_in, mat_base: BaseMaterial.InsulationGenericLoosefill, k_in: joist_height_in / cavity_r)
      end
      mat_rb = nil
      if has_radiant_barrier
        mat_rb = Material.RadiantBarrier(radiant_barrier_grade, true)
      end
      mat_framing = Material.new(thick_in: joist_height_in, mat_base: BaseMaterial.Wood)
      mat_gap = Material.AirCavityOpen(joist_height_in)

      # Set paths
      ins_gap_frac = get_install_grade_gap_fraction(install_grade, cavity_r > 0)
      ins_factor = 1 - framing_factor
      path_fracs = [framing_factor, ins_factor * (1 - ins_gap_frac), ins_factor * ins_gap_frac]

      # Define construction
      constr = Construction.new(constr_name, path_fracs)
      constr.add_layer(exterior_film)
      if not mat_rb.nil?
        constr.add_layer(mat_rb)
      end
      if not mat_addtl_ins.nil?
        constr.add_layer(mat_addtl_ins)
      end
      constr.add_layer([mat_framing, mat_cavity, mat_gap], 'ceiling stud and cavity')
      if not mat_int_finish_or_covering.nil?
        constr.add_layer(mat_int_finish_or_covering)
      end
      constr.add_layer(interior_film)
    else # floors
      # Define materials
      mat_2x = Material.Stud2x(joist_height_in.ceil)
      if cavity_r == 0
        mat_cavity = Material.AirCavityOpen(mat_2x.thick_in)
      else
        mat_cavity = Material.new(thick_in: mat_2x.thick_in, mat_base: BaseMaterial.InsulationGenericDensepack, k_in: mat_2x.thick_in / cavity_r)
      end
      mat_framing = Material.new(thick_in: mat_2x.thick_in, mat_base: BaseMaterial.Wood)
      mat_gap = Material.AirCavityOpen(joist_height_in)
      mat_rigid = nil
      if rigid_r > 0
        rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
        mat_rigid = Material.new(name: 'floor rigid ins', thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
      end

      # Set paths
      ins_gap_frac = get_install_grade_gap_fraction(install_grade, cavity_r > 0)
      ins_factor = 1 - framing_factor
      path_fracs = [framing_factor, ins_factor * (1 - ins_gap_frac), ins_factor * ins_gap_frac]

      # Define construction
      constr = Construction.new(constr_name, path_fracs)
      constr.add_layer(exterior_film)
      if not mat_rb.nil?
        constr.add_layer(mat_rb)
      end
      constr.add_layer([mat_framing, mat_cavity, mat_gap], 'floor stud and cavity')
      if not mat_rigid.nil?
        constr.add_layer(mat_rigid)
      end
      if osb_thick_in > 0
        constr.add_layer(Material.OSBSheathing(osb_thick_in))
      end
      if not mat_int_finish_or_covering.nil?
        constr.add_layer(mat_int_finish_or_covering)
      end
      constr.add_layer(interior_film)
    end

    constr.set_interior_material_properties() unless has_radiant_barrier

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Creates a steel frame ceiling/floor construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param is_ceiling [Boolean] Whether the HPXML Floor represents a ceiling or floor surface
  # @param cavity_r [Double] R-value of the cavity insulation (hr-ft2-F/Btu)
  # @param install_grade [Integer] Insulation installation grade as defined by RESNET (1-3)
  # @param corr_factor [Double] Parallel path correction factor per ASHRAE 90.1 to determine the effective thermal resistance of steel construction (frac)
  # @param joist_height_in [Double] Thickness of the joist height (in)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_int_finish_or_covering [Material] Material properties for the ceiling interior finish (e.g., drywall) or floor covering (e.g., carpet)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic floor)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @return [nil]
  def self.apply_steel_frame_floor_ceiling(model, surfaces, constr_name, is_ceiling, cavity_r, install_grade, corr_factor,
                                           joist_height_in, osb_thick_in, rigid_r, mat_int_finish_or_covering,
                                           has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade)

    # Interior finish below, open cavity above (e.g., attic floor)
    # Open cavity below, floor covering above (e.g., crawlspace ceiling)

    return if surfaces.empty?

    if is_ceiling
      # Define materials
      mat_addtl_ins = nil
      effective_r = cavity_r * corr_factor # The effective R-value of the cavity insulation with steel stud framing
      if effective_r == 0
        mat_cavity = Material.AirCavityOpen(joist_height_in)
      else
        if rigid_r > 0
          # If there is additional insulation beyond the rafter height,
          # these inputs are used for defining an additional layer
          addtl_thick_in = rigid_r / 3.0 # Assume roughly R-3 per inch of loose-fill above cavity
          mat_addtl_ins = Material.new(name: 'ceiling loosefill ins', thick_in: addtl_thick_in, mat_base: BaseMaterial.InsulationGenericLoosefill, k_in: addtl_thick_in / rigid_r)
        end
        mat_cavity = Material.new(thick_in: joist_height_in, mat_base: BaseMaterial.InsulationGenericLoosefill, k_in: joist_height_in / effective_r)
      end
      mat_rb = nil
      if has_radiant_barrier
        mat_rb = Material.RadiantBarrier(radiant_barrier_grade, true)
      end
      mat_gap = Material.AirCavityOpen(joist_height_in)

      # Set paths
      ins_gap_frac = get_install_grade_gap_fraction(install_grade, cavity_r > 0)
      path_fracs = [1 - ins_gap_frac, ins_gap_frac]

      # Define construction
      constr = Construction.new(constr_name, path_fracs)
      constr.add_layer(exterior_film)
      if not mat_rb.nil?
        constr.add_layer(mat_rb)
      end
      if not mat_addtl_ins.nil?
        constr.add_layer(mat_addtl_ins)
      end
      constr.add_layer([mat_cavity, mat_gap], 'ceiling stud and cavity')
      if not mat_int_finish_or_covering.nil?
        constr.add_layer(mat_int_finish_or_covering)
      end
      constr.add_layer(interior_film)
    else # floors
      # Define materials
      mat_2x = Material.Stud2x(joist_height_in.ceil)
      effective_r = cavity_r * corr_factor # The effective R-value of the cavity insulation with steel stud framing
      if effective_r == 0
        mat_cavity = Material.AirCavityOpen(mat_2x.thick_in)
      else
        mat_cavity = Material.new(thick_in: mat_2x.thick_in, mat_base: BaseMaterial.InsulationGenericDensepack, k_in: mat_2x.thick_in / effective_r)
      end
      mat_gap = Material.AirCavityOpen(joist_height_in)
      mat_rigid = nil
      if rigid_r > 0
        rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
        mat_rigid = Material.new(name: 'floor rigid ins', thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
      end

      # Set paths
      ins_gap_frac = get_install_grade_gap_fraction(install_grade, cavity_r > 0)
      path_fracs = [1 - ins_gap_frac, ins_gap_frac]

      # Define construction
      constr = Construction.new(constr_name, path_fracs)
      constr.add_layer(exterior_film)
      constr.add_layer([mat_cavity, mat_gap], 'floor stud and cavity')
      if not mat_rigid.nil?
        constr.add_layer(mat_rigid)
      end
      if osb_thick_in > 0
        constr.add_layer(Material.OSBSheathing(osb_thick_in))
      end
      if not mat_int_finish_or_covering.nil?
        constr.add_layer(mat_int_finish_or_covering)
      end
      constr.add_layer(interior_film)
    end

    constr.set_interior_material_properties() unless has_radiant_barrier

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Creates a structural insulated panel (SIP) ceiling/floor construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param is_ceiling [Boolean] Whether the HPXML Floor represents a ceiling or floor surface
  # @param ins_r [Double] R-value of the insulating core of the SIP (hr-ft2-F/Btu)
  # @param ins_thick_in [Double] Thickness of the insulating core of the SIP (in)
  # @param framing_factor [Double] Fraction of total surface area comprised of structural framing (frac)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic floor)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @param solar_absorptance [Double] Solar absorptance of the outermost material (frac)
  # @param emittance [Double] Emittance of the outermost material (frac)
  # @return [nil]
  def self.apply_sip_floor_ceiling(model, surfaces, constr_name, is_ceiling, ins_r, ins_thick_in,
                                   framing_factor, mat_int_finish, osb_thick_in, rigid_r, mat_ext_finish,
                                   has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade,
                                   solar_absorptance = nil, emittance = nil)

    return if surfaces.empty?

    if is_ceiling
      constr_type = HPXML::FloorOrCeilingCeiling
    else
      constr_type = HPXML::FloorOrCeilingFloor
    end

    # Define materials
    spline_thick_in = 0.5
    middle_thick_in = ins_thick_in - (2.0 * spline_thick_in) # in
    mat_framing_inner_outer = Material.new(thick_in: spline_thick_in, mat_base: BaseMaterial.Wood)
    mat_framing_middle = Material.new(thick_in: middle_thick_in, mat_base: BaseMaterial.Wood)
    mat_spline = Material.new(thick_in: spline_thick_in, mat_base: BaseMaterial.Wood)
    mat_ins_inner_outer = Material.new(thick_in: spline_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: ins_thick_in / ins_r)
    mat_ins_middle = Material.new(thick_in: middle_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: ins_thick_in / ins_r)
    mat_osb = nil
    if osb_thick_in > 0
      mat_osb = Material.OSBSheathing(osb_thick_in)
    end
    mat_rigid = nil
    if rigid_r > 0
      rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
      mat_rigid = Material.new(name: "#{constr_type} rigid ins", thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
    end
    mat_rb = nil
    if has_radiant_barrier
      mat_rb = Material.RadiantBarrier(radiant_barrier_grade, true)
    end

    # Set paths
    spline_frac = 4.0 / 48.0 # One 4" spline for every 48" wide panel
    cavity_frac = 1.0 - (spline_frac + framing_factor)
    path_fracs = [framing_factor, spline_frac, cavity_frac]

    # Define construction
    constr = Construction.new(constr_name, path_fracs)
    constr.add_layer(exterior_film)
    if not mat_ext_finish.nil?
      constr.add_layer(mat_ext_finish)
    end
    if not mat_rb.nil?
      constr.add_layer(mat_rb)
    end
    constr.add_layer([mat_framing_inner_outer, mat_spline, mat_ins_inner_outer], "#{constr_type} spline layer")
    constr.add_layer([mat_framing_middle, mat_ins_middle, mat_ins_middle], "#{constr_type} ins layer")
    constr.add_layer([mat_framing_inner_outer, mat_spline, mat_ins_inner_outer], "#{constr_type} spline layer")
    if not mat_rigid.nil?
      constr.add_layer(mat_rigid)
    end
    if not mat_osb.nil?
      constr.add_layer(mat_osb)
    end
    if not mat_int_finish.nil?
      constr.add_layer(mat_int_finish)
    end
    constr.add_layer(interior_film)

    constr.set_exterior_material_properties(solar_absorptance, emittance)
    constr.set_interior_material_properties() unless has_radiant_barrier

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Creates a generic layer-by-layer ceiling/floor construction and applies it to the specified surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param constr_name [String] Name for the construction being created
  # @param is_ceiling [Boolean] Whether the HPXML Floor represents a ceiling or floor surface
  # @param layers_thick_in [Double] Thickness of each layer from outermost to innermost (in)
  # @param layers_conductivity_in [Array<Double>] Conductivity of each layer from outermost to innermost (Btu-in/h-ft2-F)
  # @param layers_density [Array<Double>] Density of each layer from outermost to innermost (lb/ft3)
  # @param layers_spec_heat [Array<Double>] Specific heat of each layer from outermost to innermost (Btu/lb-F)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic floor)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @param solar_absorptance [Double] Solar absorptance of the outermost material (frac)
  # @param emittance [Double] Emittance of the outermost material (frac)
  # @return [nil]
  def self.apply_generic_layered_floor_ceiling(model, surfaces, constr_name, is_ceiling, layers_thick_in, layers_conductivity_in,
                                               layers_density, layers_spec_heat, mat_int_finish, osb_thick_in, rigid_r,
                                               mat_ext_finish, has_radiant_barrier, interior_film, exterior_film,
                                               radiant_barrier_grade, solar_absorptance = nil, emittance = nil)

    return if surfaces.empty?

    if is_ceiling
      constr_type = HPXML::FloorOrCeilingCeiling
    else
      constr_type = HPXML::FloorOrCeilingFloor
    end

    # Validate inputs
    for idx in 0..4
      next unless (layers_thick_in[idx].nil? != layers_conductivity_in[idx].nil?) ||
                  (layers_thick_in[idx].nil? != layers_density[idx].nil?) ||
                  (layers_thick_in[idx].nil? != layers_spec_heat[idx].nil?)

      fail "Layer #{idx + 1} does not have all four properties (thickness, conductivity, density, specific heat) entered."
    end

    # Define materials
    mats = []
    mats << Material.new(name: "#{constr_type} layer 1", thick_in: layers_thick_in[0], k_in: layers_conductivity_in[0], rho: layers_density[0], cp: layers_spec_heat[0])
    if not layers_thick_in[1].nil?
      mats << Material.new(name: "#{constr_type} layer 2", thick_in: layers_thick_in[1], k_in: layers_conductivity_in[1], rho: layers_density[1], cp: layers_spec_heat[1])
    end
    if not layers_thick_in[2].nil?
      mats << Material.new(name: "#{constr_type} layer 3", thick_in: layers_thick_in[2], k_in: layers_conductivity_in[2], rho: layers_density[2], cp: layers_spec_heat[2])
    end
    if not layers_thick_in[3].nil?
      mats << Material.new(name: "#{constr_type} layer 4", thick_in: layers_thick_in[3], k_in: layers_conductivity_in[3], rho: layers_density[3], cp: layers_spec_heat[3])
    end
    if not layers_thick_in[4].nil?
      mats << Material.new(name: "#{constr_type} layer 5", thick_in: layers_thick_in[4], k_in: layers_conductivity_in[4], rho: layers_density[4], cp: layers_spec_heat[4])
    end
    mat_osb = nil
    if osb_thick_in > 0
      mat_osb = Material.OSBSheathing(osb_thick_in)
    end
    mat_rigid = nil
    if rigid_r > 0
      rigid_thick_in = rigid_r * BaseMaterial.InsulationRigid.k_in
      mat_rigid = Material.new(name: "#{constr_type} rigid ins", thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / rigid_r)
    end
    mat_rb = nil
    if has_radiant_barrier
      mat_rb = Material.RadiantBarrier(radiant_barrier_grade, true)
    end

    # Define construction
    constr = Construction.new(constr_name, [1])
    constr.add_layer(exterior_film)
    if not mat_ext_finish.nil?
      constr.add_layer(mat_ext_finish)
    end
    if not mat_rb.nil?
      constr.add_layer(mat_rb)
    end
    mats.each do |mat|
      constr.add_layer(mat)
    end
    if not mat_rigid.nil?
      constr.add_layer(mat_rigid)
    end
    if not mat_osb.nil?
      constr.add_layer(mat_osb)
    end
    if not mat_int_finish.nil?
      constr.add_layer(mat_int_finish)
    end
    constr.add_layer(interior_film)

    constr.set_exterior_material_properties(solar_absorptance, emittance)
    constr.set_interior_material_properties() unless has_radiant_barrier

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)
  end

  # Applies a Kiva walled foundation and construction to the OpenStudio surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] Foundation wall surfaces
  # @param constr_name [String] Name for the construction being created
  # @param ext_vert_offset [Double] Vertical distance from top of foundation wall to top of exterior vertical insulation (ft)
  # @param int_vert_offset [Double] Vertical distance from top of foundation wall to top of interior vertical insulation (ft)
  # @param ext_vert_depth [Double] Depth of the exterior vertical insulation (ft)
  # @param int_vert_depth [Double] Depth of the interior vertical insulation (ft)
  # @param ext_vert_r [Double] Nominal R-value of the exterior vertical insulation (hr-ft2-F/Btu)
  # @param int_vert_r [Double] Nominal R-value of the interior vertical insulation (hr-ft2-F/Btu)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param mat_wall [Material] Material properties for the base foundation wall (i.e., excluding insulation materials)
  # @param height_above_grade [Double] Vertical distance from the top of the foundation wall to grade (ft)
  # @param soil_k_in [Double] Soil conductivity (Btu-in/h-ft2-F)
  # @return [nil]
  def self.apply_kiva_foundation_wall(model, surfaces, constr_name, ext_vert_offset, int_vert_offset,
                                      ext_vert_depth, int_vert_depth, ext_vert_r, int_vert_r,
                                      mat_int_finish, mat_wall, height_above_grade, soil_k_in)

    # Create Kiva foundation
    foundation = OpenStudio::Model::FoundationKiva.new(model)

    # Interior vertical insulation
    if (int_vert_r > 0) && (int_vert_depth > 0)
      int_vert_mat = create_insulation_material_for_kiva(model, 'interior vertical ins', int_vert_r)
      foundation.addCustomBlock(int_vert_mat,
                                UnitConversions.convert(int_vert_depth, 'ft', 'm'),
                                -int_vert_mat.thickness,
                                UnitConversions.convert(int_vert_offset, 'ft', 'm'))
    end

    # Exterior vertical insulation
    if (ext_vert_r > 0) && (ext_vert_depth > 0)
      ext_vert_mat = create_insulation_material_for_kiva(model, 'exterior vertical ins', ext_vert_r)
      mat_int_finish_thick_in = mat_int_finish.nil? ? 0.0 : mat_int_finish.thick_in
      foundation.addCustomBlock(ext_vert_mat,
                                UnitConversions.convert(ext_vert_depth, 'ft', 'm'),
                                UnitConversions.convert(mat_wall.thick_in + mat_int_finish_thick_in, 'in', 'm'),
                                UnitConversions.convert(ext_vert_offset, 'ft', 'm'))
    end

    foundation.setWallHeightAboveGrade(UnitConversions.convert(height_above_grade, 'ft', 'm'))
    foundation.setWallDepthBelowSlab(UnitConversions.convert(8.0, 'in', 'm'))

    apply_kiva_settings(model, soil_k_in)

    # Define construction
    constr = Construction.new(constr_name, [1])
    constr.add_layer(mat_wall)
    if not mat_int_finish.nil?
      constr.add_layer(mat_int_finish)
    end

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions(surfaces, model)

    # Assign surfaces to Kiva foundation
    surfaces.each do |surface|
      surface.setAdjacentFoundation(foundation)
    end
  end

  # Applies a Kiva slab foundation and construction to the OpenStudio surface.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surface [OpenStudio::Model::Surface] an OpenStudio::Model::Surface object
  # @param constr_name [String] Name for the construction being created
  # @param int_horiz_r [Double] Nominal R-value of the interior horizontal insulation (hr-ft2-F/Btu)
  # @param int_horiz_width [Double] Width of the interior horizontal insulation (ft)
  # @param int_vert_r [Double] Nominal R-value of the interior vertical insulation (hr-ft2-F/Btu)
  # @param ext_vert_r [Double] Nominal R-value of the exterior vertical insulation (hr-ft2-F/Btu)
  # @param ext_vert_depth [Double] Depth of the exterior vertical insulation (ft)
  # @param whole_r [Double] Nominal R-value for the horizontal insulation that covers the whole slab (hr-ft2-F/Btu)
  # @param concrete_thick_in [Double] Thickness of the concrete slab (in)
  # @param exposed_perimeter [Double] Slab perimeter exposed to ambient conditions (ft)
  # @param mat_carpet [Material] Material properties for the carpet
  # @param soil_k_in [Double] Soil conductivity (Btu-in/h-ft2-F)
  # @param foundation [OpenStudio::Model::FoundationKiva] The Kiva foundation object of interest
  # @param ext_horiz_r [Double] Nominal R-value of the exterior horizontal insulation (hr-ft2-F/Btu)
  # @param ext_horiz_width [Double] Width of the exterior horizontal insulation (ft)
  # @param ext_horiz_depth [Double] Vertical distance from the top of the exterior horizontal insulation to grade (ft)
  # @return [nil]
  def self.apply_kiva_foundation_slab(model, surface, constr_name, int_horiz_r, int_horiz_width, int_vert_r, ext_vert_r,
                                      ext_vert_depth, whole_r, concrete_thick_in, exposed_perimeter, mat_carpet,
                                      soil_k_in, foundation, ext_horiz_r, ext_horiz_width, ext_horiz_depth)

    return if surface.nil?

    if foundation.nil?
      # Create Kiva foundation for slab
      foundation = OpenStudio::Model::FoundationKiva.new(model)

      # Interior horizontal insulation
      if (int_horiz_r > 0) && (int_horiz_width > 0)
        int_horiz_mat = create_insulation_material_for_kiva(model, 'interior horizontal ins', int_horiz_r)
        foundation.setInteriorHorizontalInsulationMaterial(int_horiz_mat)
        foundation.setInteriorHorizontalInsulationDepth(0)
        foundation.setInteriorHorizontalInsulationWidth(UnitConversions.convert(int_horiz_width, 'ft', 'm'))
      end

      # Interior vertical insulation
      if (int_vert_r > 0) && (concrete_thick_in > 0)
        int_vert_mat = create_insulation_material_for_kiva(model, 'interior vertical ins', int_vert_r)
        foundation.setInteriorVerticalInsulationMaterial(int_vert_mat)
        foundation.setInteriorVerticalInsulationDepth(UnitConversions.convert(concrete_thick_in, 'in', 'm'))
      end

      # Exterior vertical insulation
      if (ext_vert_r > 0) && (ext_vert_depth > 0)
        ext_vert_mat = create_insulation_material_for_kiva(model, 'exterior vertical ins', ext_vert_r)
        foundation.setExteriorVerticalInsulationMaterial(ext_vert_mat)
        foundation.setExteriorVerticalInsulationDepth(UnitConversions.convert(ext_vert_depth, 'ft', 'm'))
      end

      # Exterior horizontal insulation
      if (ext_horiz_r > 0) && (ext_horiz_width > 0)
        ext_horiz_mat = create_insulation_material_for_kiva(model, 'exterior horizontal ins', ext_horiz_r)
        foundation.setExteriorHorizontalInsulationMaterial(ext_horiz_mat)
        foundation.setExteriorHorizontalInsulationDepth(UnitConversions.convert(ext_horiz_depth, 'ft', 'm'))
        foundation.setExteriorHorizontalInsulationWidth(UnitConversions.convert(ext_horiz_width, 'ft', 'm'))
      end

      foundation.setWallHeightAboveGrade(UnitConversions.convert(concrete_thick_in, 'in', 'm'))
      foundation.setWallDepthBelowSlab(UnitConversions.convert(8.0, 'in', 'm'))

      apply_kiva_settings(model, soil_k_in)

    else
      # Kiva foundation (for crawlspace/basement) exists
      if (int_horiz_r > 0) && (int_horiz_width > 0)
        int_horiz_mat = create_insulation_material_for_kiva(model, 'interior horizontal ins', int_horiz_r)
        foundation.setInteriorHorizontalInsulationMaterial(int_horiz_mat)
        foundation.setInteriorHorizontalInsulationDepth(0)
        foundation.setInteriorHorizontalInsulationWidth(UnitConversions.convert(int_horiz_width, 'ft', 'm'))
      end

    end

    # Define materials
    mat_concrete = nil
    mat_soil = nil
    if concrete_thick_in > 0
      mat_concrete = Material.Concrete(concrete_thick_in)
    else
      # Use 0.5 - 1.0 inches of soil, per Neal Kruis recommendation
      mat_soil = Material.Soil(0.5, soil_k_in)
    end
    mat_rigid = nil
    if whole_r > 0
      rigid_thick_in = whole_r * BaseMaterial.InsulationRigid.k_in
      mat_rigid = Material.new(name: 'slab rigid ins', thick_in: rigid_thick_in, mat_base: BaseMaterial.InsulationRigid, k_in: rigid_thick_in / whole_r)
    end

    # Define construction
    constr = Construction.new(constr_name, [1])
    if not mat_rigid.nil?
      constr.add_layer(mat_rigid)
    end
    if not mat_concrete.nil?
      constr.add_layer(mat_concrete)
    end
    if not mat_soil.nil?
      constr.add_layer(mat_soil)
    end
    if not mat_carpet.nil?
      constr.add_layer(mat_carpet)
    end

    # Create and assign construction to surfaces
    constr.create_and_assign_constructions([surface], model)

    # Assign surface to Kiva foundation
    surface.setAdjacentFoundation(foundation)
    surface.createSurfacePropertyExposedFoundationPerimeter('TotalExposedPerimeter', UnitConversions.convert(exposed_perimeter, 'ft', 'm'))
  end

  # Applies a door construction to the OpenStudio subsurfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param subsurfaces [Array<OpenStudio::Model::SubSurface>] The subsurfaces to apply the construction to
  # @param constr_name [String] Name for the construction being created
  # @param ufactor [Double] Door U-factor (Btu/F-ft2-hr)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @return [nil]
  def self.apply_door(model, subsurfaces, constr_name, ufactor, interior_film, exterior_film)
    return if subsurfaces.empty?

    # Define materials
    door_r_value = [1.0 / ufactor - interior_film.rvalue - exterior_film.rvalue, 0.1].max
    door_thickness = 1.75 # in
    fin_door_mat = Material.new(name: 'door material', thick_in: door_thickness, mat_base: BaseMaterial.Wood, k_in: 1.0 / door_r_value * door_thickness)

    # Define construction
    constr = Construction.new(constr_name, [1])
    constr.add_layer(fin_door_mat)

    # Create and assign construction to subsurfaces
    constr.create_and_assign_constructions(subsurfaces, model)
  end

  # Applies a window construction to the OpenStudio subsurface.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param subsurface [OpenStudio::Model::SubSurface] The subsurface to apply the construction to
  # @param constr_name [String] Name for the construction being created
  # @param ufactor [Double] Full-assembly NFRC U-factor (Btu/F-ft2-hr)
  # @param shgc [Double] Full-assembly NFRC solar heat gain coefficient (frac)
  # @return [nil]
  def self.apply_window(model, subsurface, constr_name, ufactor, shgc)
    apply_window_skylight(model, 'Window', subsurface, constr_name, ufactor, shgc)
  end

  # Applies a skylight construction to the OpenStudio subsurface.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param subsurface [OpenStudio::Model::SubSurface] The subsurface to apply the construction to
  # @param constr_name [String] Name for the construction being created
  # @param ufactor [Double] Full-assembly NFRC U-factor (Btu/F-ft2-hr)
  # @param shgc [Double] Full-assembly NFRC solar heat gain coefficient (frac)
  # @return [nil]
  def self.apply_skylight(model, subsurface, constr_name, ufactor, shgc)
    apply_window_skylight(model, 'Skylight', subsurface, constr_name, ufactor, shgc)
  end

  # Creates an OpenStudio internal mass object with a wood stud construction to represent
  # partition wall area (e.g., walls between different rooms in the homes).
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param constr_name [String] Name for the construction being created
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param partition_wall_area [Double] Partition wall surface area (both sides) (ft^2)
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @return [nil]
  def self.apply_partition_walls(model, constr_name, mat_int_finish, partition_wall_area, spaces)
    return if partition_wall_area <= 0

    # Add remaining partition walls within spaces (those without geometric representation)
    # as internal mass object.
    im = Model.add_internal_mass(
      model,
      name: 'partition wall mass',
      space: spaces[HPXML::LocationConditionedSpace],
      area: partition_wall_area,
    )
    imdef = im.internalMassDefinition

    apply_wood_stud_wall(model, [imdef], constr_name, 0, 1, 3.5, false, 0.16, mat_int_finish, 0, 0, mat_int_finish,
                         false, Material.AirFilmIndoorWall, Material.AirFilmIndoorWall, 1, nil, nil)
  end

  # Creates an OpenStudio internal mass object to represent furniture and furnishings
  # in the conditioned space, unconditioned basement, and garage thermal zones.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param furniture_mass [HPXML::FurnitureMass] HPXML FurnitureMass object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @return [nil]
  def self.apply_furniture(model, furniture_mass, spaces)
    if furniture_mass.type == HPXML::FurnitureMassTypeLightWeight
      mass_lb_per_sqft = 8.0
      mat = BaseMaterial.FurnitureLightWeight
    elsif furniture_mass.type == HPXML::FurnitureMassTypeHeavyWeight
      mass_lb_per_sqft = 16.0
      mat = BaseMaterial.FurnitureHeavyWeight
    end

    # Add user-specified furniture mass
    spaces.each do |location, space|
      floor_area = UnitConversions.convert(space.floorArea, 'm^2', 'ft^2')
      next if floor_area <= 0

      furnAreaFraction = nil # Fraction of conditioned floor area
      furnConductivity = mat.k_in
      furnSolarAbsorptance = 0.6
      furnSpecHeat = mat.cp
      furnDensity = mat.rho

      case location
      when HPXML::LocationConditionedSpace
        furnAreaFraction = furniture_mass.area_fraction
        furnMass = mass_lb_per_sqft
      when HPXML::LocationBasementUnconditioned
        furnAreaFraction = 0.4
        furnMass = mass_lb_per_sqft
      when HPXML::LocationGarage
        furnAreaFraction = 0.1
        furnMass = 2.0
      end

      next if furnAreaFraction.nil?
      next if furnAreaFraction <= 0

      furnThickness = UnitConversions.convert(furnMass / (furnDensity * furnAreaFraction), 'ft', 'in')

      # Define materials
      mat_fm = Material.new(name: "furniture material #{space.name}", thick_in: furnThickness, k_in: furnConductivity, rho: furnDensity, cp: furnSpecHeat, tAbs: 0.9, sAbs: furnSolarAbsorptance)

      # Define construction
      constr = Construction.new("furniture construction #{space.name}", [1])
      constr.add_layer(mat_fm)

      surface_area = furnAreaFraction * floor_area
      im = Model.add_internal_mass(
        model,
        name: "furniture mass #{space.name}",
        space: space,
        area: surface_area,
      )
      imdef = im.internalMassDefinition

      # Create and assign construction to surfaces
      constr.create_and_assign_constructions([imdef], model)
    end
  end

  # Returns the mapping between solar absorptance and roof color/material.
  #
  # @return [Hash] Map of [HPXML::ColorXXX, HPXML::RoofMaterialXXX] => solar absorptance
  def self.get_roof_color_and_solar_absorptance_map
    # Values informed by:
    # - 2021 ASHRAE Handbook of Fundamentals (HOF), Chapter 17, Table 8
    # - "Laboratory Testing of the Reflectance Properties of Roofing Materials", FSEC-CR-670-00
    # - CRRC Rated Roof Products (https://coolroofs.org/directory/roof), 3-year solar reflectance

    map = {}

    # Asphalt/wood shingles
    [HPXML::RoofTypeAsphaltShingles,
     HPXML::RoofTypeWoodShingles,
     HPXML::RoofTypeShingles,
     HPXML::RoofTypeEPS].each do |roof_type|
      map[[HPXML::ColorDark, roof_type]] = 0.92 # ASHRAE HOF
      map[[HPXML::ColorMediumDark, roof_type]] = 0.89 # Average of dark & medium
      map[[HPXML::ColorMedium, roof_type]] = 0.85 # ASHRAE HOF
      map[[HPXML::ColorMediumLight, roof_type]] = 0.80 # Average of medium & light
      map[[HPXML::ColorLight, roof_type]] = 0.75 # ASHRAE HOF
      map[[HPXML::ColorWhite, roof_type]] = 0.75 # ASHRAE HOF
      map[[HPXML::ColorReflective, roof_type]] = 0.25 # Engineering judgment; assume a reflective coating
    end

    # Concrete/clay tile
    [HPXML::RoofTypeClayTile,
     HPXML::RoofTypeConcrete].each do |roof_type|
      map[[HPXML::ColorDark, roof_type]] = 0.85 # CRRC for black Tile products
      map[[HPXML::ColorMediumDark, roof_type]] = 0.80 # ASHRAE HOF dark & medium
      map[[HPXML::ColorMedium, roof_type]] = 0.75 # CRRC for Tile products, FSEC
      map[[HPXML::ColorMediumLight, roof_type]] = 0.65 # CRRC for Tile products, FSEC
      map[[HPXML::ColorLight, roof_type]] = 0.40 # ASHRAE HOF
      map[[HPXML::ColorWhite, roof_type]] = 0.30 # ASHRAE HOF
      map[[HPXML::ColorReflective, roof_type]] = 0.25 # Engineering judgment; assume a reflective coating
    end

    # Metal roofing
    [HPXML::RoofTypeMetal].each do |roof_type|
      map[[HPXML::ColorDark, roof_type]] = 0.90 # ASHRAE HOF
      map[[HPXML::ColorMediumDark, roof_type]] = 0.80 # Average above/below
      map[[HPXML::ColorMedium, roof_type]] = 0.70 # ASHRAE HOF
      map[[HPXML::ColorMediumLight, roof_type]] = 0.60 # Average of medium & light
      map[[HPXML::ColorLight, roof_type]] = 0.50 # ASHRAE HOF
      map[[HPXML::ColorWhite, roof_type]] = 0.35 # ASHRAE HOF
      map[[HPXML::ColorReflective, roof_type]] = 0.25 # Engineering judgment; assume a reflective coating
    end

    # Plastic/rubber
    [HPXML::RoofTypePlasticRubber].each do |roof_type|
      map[[HPXML::ColorDark, roof_type]] = 0.90 # CRRC for black Single-Ply products
      map[[HPXML::ColorMediumDark, roof_type]] = 0.78 # Average of dark & medium
      map[[HPXML::ColorMedium, roof_type]] = 0.65 # Average of dark & light
      map[[HPXML::ColorMediumLight, roof_type]] = 0.53 # Average of medium & light
      map[[HPXML::ColorLight, roof_type]] = 0.40 # CRRC for off-white/tan Single-Ply products
      map[[HPXML::ColorWhite, roof_type]] = 0.30 # CRRC for bright white Single-Ply products
      map[[HPXML::ColorReflective, roof_type]] = 0.25 # Engineering judgment; assume a reflective coating
    end

    return map
  end

  # Returns the mapping between solar absorptance and wall color.
  #
  # @return [Hash] Map of HPXML::ColorXXX => solar absorptance
  def self.get_wall_color_and_solar_absorptance_map
    return {
      HPXML::ColorDark => 0.90, # Home Energy Saver
      HPXML::ColorMediumDark => 0.80, # Home Energy Saver
      HPXML::ColorMedium => 0.70, # Home Energy Saver
      HPXML::ColorMediumLight => 0.63, # Average of medium & light
      HPXML::ColorLight => 0.55, # Home Energy Saver
      HPXML::ColorWhite => 0.35, # Home Energy Saver
      HPXML::ColorReflective => 0.25 # Engineering judgment; assume a reflective coating
    }
  end

  # Returns the fraction of the insulation area that has gaps as determined
  # by the RESNET installation grade.
  #
  # @param install_grade [Integer] Insulation installation grade as defined by RESNET (1-3)
  # @param has_insulation [Boolean] Where insulation is present
  # @return [Double] Insulation gap fraction
  def self.get_install_grade_gap_fraction(install_grade, has_insulation)
    if not has_insulation
      return 0 # Gap fraction only applies when there is cavity insulation
    end

    case install_grade
    when 1
      return 0
    when 2
      return 0.02
    when 3
      return 0.05
    end

    return 0
  end

  # Applies Kiva settings to the model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param soil_k_in [Double] Soil conductivity (Btu-in/h-ft2-F)
  # @return [nil]
  def self.apply_kiva_settings(model, soil_k_in)
    # Set the Foundation:Kiva:Settings object
    soil_mat = BaseMaterial.Soil(soil_k_in)
    settings = model.getFoundationKivaSettings
    settings.setSoilConductivity(UnitConversions.convert(soil_mat.k_in, 'Btu*in/(hr*ft^2*R)', 'W/(m*K)'))
    settings.setSoilDensity(UnitConversions.convert(soil_mat.rho, 'lbm/ft^3', 'kg/m^3'))
    settings.setSoilSpecificHeat(UnitConversions.convert(soil_mat.cp, 'Btu/(lbm*R)', 'J/(kg*K)'))
    settings.setGroundSolarAbsorptivity(0.9)
    settings.setGroundThermalAbsorptivity(0.9)
    settings.setGroundSurfaceRoughness(0.03)
    settings.setFarFieldWidth(40) # FUTURE: Set based on neighbor building distances?
    settings.setDeepGroundBoundaryCondition('ZeroFlux')
    settings.setDeepGroundDepth(40)
    settings.setMinimumCellDimension(0.2)
    settings.setMaximumCellGrowthCoefficient(3.0)
    # Using 'Timestep' instead of 'Hourly' below because it makes timeseries results
    # smoother with only a small increase in runtime.
    settings.setSimulationTimestep('Timestep')
  end

  # Sets Kiva foundation initial temperature.
  #
  # @param foundation [OpenStudio::Model::FoundationKiva] The Kiva foundation object of interest
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param interior_adjacent_to [String] Interior adjacent to location (HPXML::LocationXXX)
  # @return [nil]
  def self.apply_kiva_initial_temperature(foundation, weather, hpxml_bldg, hpxml_header, spaces, schedules_file, interior_adjacent_to)
    sim_begin_month = hpxml_header.sim_begin_month
    sim_begin_day = hpxml_header.sim_begin_day
    sim_year = hpxml_header.sim_calendar_year

    outdoor_temp = weather.data.MonthlyAvgDrybulbs[sim_begin_month - 1]

    foundation_walls_insulated = false
    hpxml_bldg.foundation_walls.each do |fnd_wall|
      next unless fnd_wall.interior_adjacent_to == interior_adjacent_to
      next unless fnd_wall.exterior_adjacent_to == HPXML::LocationGround

      if fnd_wall.insulation_assembly_r_value.to_f > 5
        foundation_walls_insulated = true
      elsif fnd_wall.insulation_exterior_r_value.to_f + fnd_wall.insulation_interior_r_value.to_f > 0
        foundation_walls_insulated = true
      end
    end

    foundation_ceiling_insulated = false
    hpxml_bldg.floors.each do |floor|
      next unless floor.interior_adjacent_to == HPXML::LocationConditionedSpace
      next unless floor.exterior_adjacent_to == interior_adjacent_to

      if floor.insulation_assembly_r_value > 5
        foundation_ceiling_insulated = true
      end
    end

    # Approximate indoor temperature
    conditioned_zone = spaces[HPXML::LocationConditionedSpace].thermalZone.get
    if conditioned_zone.thermostatSetpointDualSetpoint.is_initialized
      # Building has HVAC system
      setpoint_sch = conditioned_zone.thermostatSetpointDualSetpoint.get
      sim_begin_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(sim_begin_month), sim_begin_day, sim_year)
      sim_begin_hour = (Calendar.get_day_num_from_month_day(sim_year, sim_begin_month, sim_begin_day) - 1) * 24

      # Get heating/cooling setpoints for the simulation start
      htg_setpoint_sch = setpoint_sch.heatingSetpointTemperatureSchedule.get
      if htg_setpoint_sch.to_ScheduleRuleset.is_initialized
        htg_day_sch = htg_setpoint_sch.to_ScheduleRuleset.get.getDaySchedules(sim_begin_date, sim_begin_date)[0]
        heat_setpoint = UnitConversions.convert(htg_day_sch.values[0], 'C', 'F')
      else
        heat_setpoint = schedules_file.schedules[SchedulesFile::Columns[:HeatingSetpoint].name][sim_begin_hour]
      end
      clg_setpoint_sch = setpoint_sch.coolingSetpointTemperatureSchedule.get
      if clg_setpoint_sch.to_ScheduleRuleset.is_initialized
        clg_day_sch = clg_setpoint_sch.to_ScheduleRuleset.get.getDaySchedules(sim_begin_date, sim_begin_date)[0]
        cool_setpoint = UnitConversions.convert(clg_day_sch.values[0], 'C', 'F')
      else
        cool_setpoint = schedules_file.schedules[SchedulesFile::Columns[:CoolingSetpoint].name][sim_begin_hour]
      end

      # Methodology adapted from https://github.com/NatLabRockies/EnergyPlus/blob/b18a2733c3131db808feac44bc278a14b05d8e1f/src/EnergyPlus/HeatBalanceKivaManager.cc#L303-L313
      heat_balance_temp = UnitConversions.convert(10.0, 'C', 'F')
      cool_balance_temp = UnitConversions.convert(15.0, 'C', 'F')
      if outdoor_temp < heat_balance_temp
        indoor_temp = heat_setpoint
      elsif outdoor_temp > cool_balance_temp
        indoor_temp = cool_setpoint
      elsif cool_balance_temp == heat_balance_temp
        indoor_temp = heat_balance_temp
      else
        weight = (cool_balance_temp - outdoor_temp) / (cool_balance_temp - heat_balance_temp)
        indoor_temp = heat_setpoint * weight + cool_setpoint * (1.0 - weight)
      end
    else
      # Building does not have HVAC system
      indoor_temp = outdoor_temp
    end

    # Determine initial temperature
    # For unconditioned spaces, this overrides EnergyPlus's built-in assumption of 22C (71.6F);
    #   see https://github.com/NatLabRockies/EnergyPlus/blob/b18a2733c3131db808feac44bc278a14b05d8e1f/src/EnergyPlus/HeatBalanceKivaManager.cc#L257-L259
    # For conditioned spaces, this avoids an E+ 22.2 bug; see https://github.com/NatLabRockies/EnergyPlus/issues/9692
    if HPXML::conditioned_locations.include? interior_adjacent_to
      initial_temp = indoor_temp
    else
      # Space temperature assumptions from ASHRAE 152 - Duct Efficiency Calculations.xls, Zone temperatures
      ground_temp = weather.data.ShallowGroundMonthlyTemps[sim_begin_month - 1]
      case interior_adjacent_to
      when HPXML::LocationBasementUnconditioned
        if foundation_ceiling_insulated
          # Insulated ceiling: 75% ground, 25% outdoor, 0% indoor
          ground_weight, outdoor_weight, indoor_weight = 0.75, 0.25, 0.0
        elsif foundation_walls_insulated
          # Insulated walls: 50% ground, 0% outdoor, 50% indoor (case not in ASHRAE 152)
          ground_weight, outdoor_weight, indoor_weight = 0.5, 0.0, 0.5
        else
          # Uninsulated: 50% ground, 20% outdoor, 30% indoor
          ground_weight, outdoor_weight, indoor_weight = 0.5, 0.2, 0.3
        end
        initial_temp = outdoor_temp * outdoor_weight + ground_temp * ground_weight + indoor_weight * indoor_temp
      when HPXML::LocationCrawlspaceVented
        if foundation_ceiling_insulated
          # Insulated ceiling: 90% outdoor, 10% indoor
          outdoor_weight, indoor_weight = 0.9, 0.1
        elsif foundation_walls_insulated
          # Insulated walls: 25% outdoor, 75% indoor (case not in ASHRAE 152)
          outdoor_weight, indoor_weight = 0.25, 0.75
        else
          # Uninsulated: 50% outdoor, 50% indoor
          outdoor_weight, indoor_weight = 0.5, 0.5
        end
        initial_temp = outdoor_temp * outdoor_weight + indoor_weight * indoor_temp
      when HPXML::LocationCrawlspaceUnvented
        if foundation_ceiling_insulated
          # Insulated ceiling: 85% outdoor, 15% indoor
          outdoor_weight, indoor_weight = 0.85, 0.15
        elsif foundation_walls_insulated
          # Insulated walls: 25% outdoor, 75% indoor
          outdoor_weight, indoor_weight = 0.25, 0.75
        else
          # Uninsulated: 40% outdoor, 60% indoor
          outdoor_weight, indoor_weight = 0.4, 0.6
        end
        initial_temp = outdoor_temp * outdoor_weight + indoor_weight * indoor_temp
      when HPXML::LocationGarage
        initial_temp = outdoor_temp + 11.0
      else
        fail "Unhandled space: #{interior_adjacent_to}"
      end
    end

    foundation.setInitialIndoorAirTemperature(UnitConversions.convert(initial_temp, 'F', 'C'))
  end

  # Creates an OpenStudio material to represent insulation for the Kiva foundation objects.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the material
  # @param rvalue [Double] Nominal R-value of the insulation (hr-ft2-F/Btu)
  # @return [OpenStudio::Model::StandardOpaqueMaterial] The OpenStudio material
  def self.create_insulation_material_for_kiva(model, name, rvalue)
    rigid_mat = BaseMaterial.InsulationRigid
    mat = Model.add_opaque_material(
      model,
      name: name,
      thickness: UnitConversions.convert(rvalue * rigid_mat.k_in, 'in', 'm'),
      conductivity: UnitConversions.convert(rigid_mat.k_in, 'Btu*in/(hr*ft^2*R)', 'W/(m*K)'),
      density: UnitConversions.convert(rigid_mat.rho, 'lbm/ft^3', 'kg/m^3'),
      specific_heat: UnitConversions.convert(rigid_mat.cp, 'Btu/(lbm*R)', 'J/(kg*K)')
    )
    return mat
  end

  # Applies a window/skylight construction to the OpenStudio subsurface.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param type [String] "Skylight" or "Window"
  # @param subsurface [OpenStudio::Model::SubSurface] The subsurface to apply the construction to
  # @param constr_name [String] Name for the construction being created
  # @param ufactor [Double] Full assembly window U-factor (Btu/F-ft2-hr)
  # @param shgc [Double] Full assembly glazing solar heat gain coefficient (0-1)
  # @return [nil]
  def self.apply_window_skylight(model, type, subsurface, constr_name, ufactor, shgc)
    # Define materials
    if type == 'Skylight'
      # As of 2004, NFRC skylights are rated at a 20-degree slope (instead of vertical), but
      # the E+ SimpleGlazingSystem model accepts a U-factor that "is assumed to be for
      # vertically mounted products". According to NFRC, "Ratings ... shall be converted to
      # the 20-deg slope from the vertical position by multiplying the tested value at vertical
      # by 1.20." Thus we divide by 1.2 to get the vertical position value.
      ufactor /= 1.2
    end
    glaz_mat = GlazingMaterial.new(name: "#{type}Material", ufactor: ufactor, shgc: shgc)

    # Define construction
    constr = Construction.new(constr_name, [1])
    constr.add_layer(glaz_mat)

    # Create and assign construction to subsurfaces
    constr.create_and_assign_constructions([subsurface], model)
  end

  # Applies a shading schedule to the window/skylight using the simple E+
  # SurfaceProperty:IncidentSolarMultiplier object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param window_or_skylight [HPXML::Window or HPXML::Skylight] The HPXML Window or Skylight with the shading information
  # @param subsurface [OpenStudio::Model::SubSurface] The subsurface to apply the shading to
  # @param shading_schedules [Hash] Map of shading factors array => OpenStudio schedule, used to prevent creating duplicative schedule objects in the model
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_window_skylight_shading(model, window_or_skylight, subsurface, shading_schedules, hpxml_header, hpxml_bldg)
    # Interior shading factors
    isf_summer = window_or_skylight.interior_shading_factor_summer
    isf_winter = window_or_skylight.interior_shading_factor_winter

    # Exterior shading factors
    esf_summer = window_or_skylight.exterior_shading_factor_summer.nil? ? 1.0 : window_or_skylight.exterior_shading_factor_summer
    esf_winter = window_or_skylight.exterior_shading_factor_winter.nil? ? 1.0 : window_or_skylight.exterior_shading_factor_winter
    if window_or_skylight.is_a? HPXML::Window
      # These inputs currently only pertain to windows (not skylights)
      case window_or_skylight.exterior_shading_type
      when HPXML::ExteriorShadingTypeExternalOverhangs, HPXML::ExteriorShadingTypeAwnings
        if window_or_skylight.overhangs_depth.to_f > 0
          # Explicitly modeling the overhangs, so don't double count the shading effect
          esf_summer = 1.0
          esf_winter = 1.0
        end
      when HPXML::ExteriorShadingTypeBuilding
        if hpxml_bldg.neighbor_buildings.size > 0
          # Explicitly modeling neighboring building, so don't double count the shading effect
          esf_summer = 1.0
          esf_winter = 1.0
        end
      end
    end

    # Insect screen factors
    is_summer = 1.0
    is_winter = 1.0
    if window_or_skylight.respond_to?(:insect_screen_present) && window_or_skylight.insect_screen_present
      is_summer = window_or_skylight.insect_screen_factor_summer
      is_winter = window_or_skylight.insect_screen_factor_winter
    end

    # Total combined factors
    sf_summer = isf_summer * esf_summer * is_summer
    sf_winter = isf_winter * esf_winter * is_winter

    if (sf_summer < 1.0) || (sf_winter < 1.0) # Apply shading

      # Determine transmittance values throughout the year
      sf_values = []
      num_days_in_year = Calendar.num_days_in_year(hpxml_header.sim_calendar_year)
      if not hpxml_bldg.header.shading_summer_begin_month.nil?
        summer_start_day_num = Calendar.get_day_num_from_month_day(hpxml_header.sim_calendar_year,
                                                                   hpxml_bldg.header.shading_summer_begin_month,
                                                                   hpxml_bldg.header.shading_summer_begin_day)
        summer_end_day_num = Calendar.get_day_num_from_month_day(hpxml_header.sim_calendar_year,
                                                                 hpxml_bldg.header.shading_summer_end_month,
                                                                 hpxml_bldg.header.shading_summer_end_day)
        for i in 0..(num_days_in_year - 1)
          day_num = i + 1
          if summer_end_day_num >= summer_start_day_num
            if (day_num >= summer_start_day_num) && (day_num <= summer_end_day_num)
              sf_values << [sf_summer] * 24
              next
            end
          else
            if (day_num >= summer_start_day_num) || (day_num <= summer_end_day_num)
              sf_values << [sf_summer] * 24
              next
            end
          end
          # If we got this far, winter
          sf_values << [sf_winter] * 24
        end
      else
        # No summer (year-round winter)
        sf_values = [[sf_winter] * 24] * num_days_in_year
      end

      # Create transmittance schedule
      if shading_schedules[sf_values].nil?
        sch_name = "trans schedule winter=#{sf_winter} summer=#{sf_summer}"
        if sf_values.flatten.uniq.size == 1
          sf_sch = Model.add_schedule_constant(
            model,
            name: sch_name,
            value: sf_values[0][0],
            limits: EPlus::ScheduleTypeLimitsFraction
          )
        else
          sf_sch = HourlyByDaySchedule.new(model, sch_name, sf_values, sf_values, EPlus::ScheduleTypeLimitsFraction, false).schedule
        end
        shading_schedules[sf_values] = sf_sch
      end

      ism = OpenStudio::Model::SurfacePropertyIncidentSolarMultiplier.new(subsurface)
      ism.setIncidentSolarMultiplierSchedule(shading_schedules[sf_values])
    end
  end

  # Calculates the R-value for all layers with a single material represented by the
  # construction set (i.e., all layers other than the cavity/stud parallel path layer).
  #
  # @param constr_set [XXXConstructionSet] The construction set of interest
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @return [Double] The construction set base R-value (hr-ft2-F/Btu)
  def self.calc_construction_set_base_r(constr_set, interior_film, exterior_film)
    base_r = interior_film.rvalue + exterior_film.rvalue
    if not constr_set.mat_ext_finish.nil?
      base_r += constr_set.mat_ext_finish.rvalue
    end
    if not constr_set.rigid_r.nil?
      base_r += constr_set.rigid_r
    end
    if not constr_set.osb_thick_in.nil?
      base_r += Material.OSBSheathing(constr_set.osb_thick_in).rvalue
    end
    if not constr_set.mat_int_finish.nil?
      base_r += constr_set.mat_int_finish.rvalue
    end
    return base_r
  end

  # Applies a wall construction to the OpenStudio surfaces.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param wall_id [String] HPXML Wall ID
  # @param wall_type [HPXML::WallTypeXXX] The wall construction type
  # @param assembly_r [Double] Air-to-air insulation assembly R-value (hr-ft2-F/Btu)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic gable wall)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  # @param solar_absorptance [Double] Solar absorptance of the outermost material (frac)
  # @param emittance [Double] Emittance of the outermost material (frac)
  # @return [nil]
  def self.apply_wall_construction(runner, model, surfaces, wall_id, wall_type, assembly_r, mat_int_finish,
                                   has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade,
                                   mat_ext_finish, solar_absorptance, emittance)

    if mat_ext_finish.nil?
      fallback_mat_ext_finish = nil
    else
      fallback_mat_ext_finish = Material.ExteriorFinishMaterial(mat_ext_finish.name, 0.1) # Try thin material
    end
    if mat_int_finish.nil?
      fallback_mat_int_finish = nil
    else
      fallback_mat_int_finish = Material.InteriorFinishMaterial(mat_int_finish.name, 0.1) # Try thin material
    end

    case wall_type
    when HPXML::WallTypeWoodStud
      install_grade = 1
      cavity_filled = true

      constr_sets = [
        WoodStudConstructionSet.new(Material.Stud2x(6), 0.20, 20.0, 0.5, mat_int_finish, mat_ext_finish),                  # 2x6, 24" o.c. + R20
        WoodStudConstructionSet.new(Material.Stud2x(6), 0.20, 10.0, 0.5, mat_int_finish, mat_ext_finish),                  # 2x6, 24" o.c. + R10
        WoodStudConstructionSet.new(Material.Stud2x(6), 0.20, 0.0, 0.5, mat_int_finish, mat_ext_finish),                   # 2x6, 24" o.c.
        WoodStudConstructionSet.new(Material.Stud2x(4), 0.23, 0.0, 0.5, mat_int_finish, mat_ext_finish),                   # 2x4, 16" o.c.
        WoodStudConstructionSet.new(Material.Stud2x(4), 0.01, 0.0, 0.0, fallback_mat_int_finish, fallback_mat_ext_finish), # Fallback
      ]
      match, constr_set, cavity_r = pick_wood_stud_construction_set(assembly_r, constr_sets, interior_film, exterior_film)

      apply_wood_stud_wall(model, surfaces, "#{wall_id} construction", cavity_r, install_grade,
                           constr_set.stud.thick_in, cavity_filled, constr_set.framing_factor,
                           constr_set.mat_int_finish, constr_set.osb_thick_in, constr_set.rigid_r,
                           constr_set.mat_ext_finish, has_radiant_barrier, interior_film,
                           exterior_film, radiant_barrier_grade, solar_absorptance, emittance)

    when HPXML::WallTypeSteelStud
      install_grade = 1
      cavity_filled = true
      corr_factor = 0.45

      constr_sets = [
        SteelStudConstructionSet.new(5.5, corr_factor, 10.0, 0.5, mat_int_finish, mat_ext_finish),          # 2x6 + R20
        SteelStudConstructionSet.new(5.5, corr_factor, 10.0, 0.5, mat_int_finish, mat_ext_finish),          # 2x6 + R10
        SteelStudConstructionSet.new(5.5, corr_factor, 0.0, 0.5, mat_int_finish, mat_ext_finish),           # 2x6
        SteelStudConstructionSet.new(3.5, corr_factor, 0.0, 0.5, mat_int_finish, mat_ext_finish),           # 2x4
        SteelStudConstructionSet.new(3.5, 1.0, 0.0, 0.0, fallback_mat_int_finish, fallback_mat_ext_finish), # Fallback
      ]
      match, constr_set, cavity_r = pick_steel_stud_construction_set(assembly_r, constr_sets, interior_film, exterior_film)

      apply_steel_stud_wall(model, surfaces, "#{wall_id} construction", cavity_r, install_grade,
                            constr_set.cavity_depth_in, cavity_filled, constr_set.corr_factor,
                            constr_set.mat_int_finish, constr_set.osb_thick_in, constr_set.rigid_r,
                            constr_set.mat_ext_finish, has_radiant_barrier, interior_film, exterior_film,
                            radiant_barrier_grade, solar_absorptance, emittance)

    when HPXML::WallTypeDoubleWoodStud
      install_grade = 1
      is_staggered = false

      constr_sets = [
        DoubleStudConstructionSet.new(Material.Stud2x(4), 0.23, 24.0, 0.0, 0.5, mat_int_finish, mat_ext_finish),                   # 2x4, 24" o.c.
        DoubleStudConstructionSet.new(Material.Stud2x(4), 0.01, 16.0, 0.0, 0.0, fallback_mat_int_finish, fallback_mat_ext_finish), # Fallback
      ]
      match, constr_set, cavity_r = pick_double_stud_construction_set(assembly_r, constr_sets, interior_film, exterior_film)

      apply_double_stud_wall(model, surfaces, "#{wall_id} construction", cavity_r, install_grade,
                             constr_set.stud.thick_in, constr_set.stud.thick_in, constr_set.framing_factor,
                             constr_set.framing_spacing, is_staggered, constr_set.mat_int_finish,
                             constr_set.osb_thick_in, constr_set.rigid_r, constr_set.mat_ext_finish,
                             has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade,
                             solar_absorptance, emittance)

    when HPXML::WallTypeCMU
      density = 119.0 # lb/ft^3
      furring_r = 0
      furring_cavity_depth_in = 0 # in
      furring_spacing = 0

      constr_sets = [
        CMUConstructionSet.new(8.0, 1.4, 0.08, 0.5, mat_int_finish, mat_ext_finish),                    # 8" perlite-filled CMU
        CMUConstructionSet.new(6.0, 5.29, 0.01, 0.0, fallback_mat_int_finish, fallback_mat_ext_finish), # Fallback (6" hollow CMU)
      ]
      match, constr_set, rigid_r = pick_cmu_construction_set(assembly_r, constr_sets, interior_film, exterior_film)

      apply_cmu_wall(model, surfaces, "#{wall_id} construction", constr_set.thick_in, constr_set.conductivity_in,
                     density, constr_set.framing_factor, furring_r, furring_cavity_depth_in, furring_spacing,
                     constr_set.mat_int_finish, constr_set.osb_thick_in, rigid_r, constr_set.mat_ext_finish,
                     has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade,
                     solar_absorptance, emittance)

    when HPXML::WallTypeSIP
      sheath_thick_in = 0.44

      constr_sets = [
        SIPConstructionSet.new(10.0, 0.16, 0.0, sheath_thick_in, 0.5, mat_int_finish, mat_ext_finish),                  # 10" SIP core
        SIPConstructionSet.new(5.0, 0.16, 0.0, sheath_thick_in, 0.5, mat_int_finish, mat_ext_finish),                   # 5" SIP core
        SIPConstructionSet.new(1.1, 0.01, 0.0, sheath_thick_in, 0.0, fallback_mat_int_finish, fallback_mat_ext_finish), # Fallback
      ]
      match, constr_set, cavity_r = pick_sip_construction_set(assembly_r, constr_sets, interior_film, exterior_film)

      apply_sip_wall(model, surfaces, "#{wall_id} construction", cavity_r, constr_set.ins_thick_in,
                     constr_set.framing_factor, constr_set.sheath_thick_in, constr_set.mat_int_finish,
                     constr_set.osb_thick_in, constr_set.rigid_r, constr_set.mat_ext_finish,
                     has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade,
                     solar_absorptance, emittance)

    when HPXML::WallTypeICF
      constr_sets = [
        ICFConstructionSet.new(2.0, 4.0, 0.08, 0.0, 0.5, mat_int_finish, mat_ext_finish),                   # ICF w/4" concrete and 2" rigid ins layers
        ICFConstructionSet.new(1.0, 1.0, 0.01, 0.0, 0.0, fallback_mat_int_finish, fallback_mat_ext_finish), # Fallback
      ]
      match, constr_set, icf_r = pick_icf_construction_set(assembly_r, constr_sets, interior_film, exterior_film)

      apply_icf_wall(model, surfaces, "#{wall_id} construction", icf_r, constr_set.ins_thick_in,
                     constr_set.concrete_thick_in, constr_set.framing_factor, constr_set.mat_int_finish,
                     constr_set.osb_thick_in, constr_set.rigid_r, constr_set.mat_ext_finish,
                     has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade,
                     solar_absorptance, emittance)

    when HPXML::WallTypeConcrete, HPXML::WallTypeBrick, HPXML::WallTypeAdobe, HPXML::WallTypeStrawBale, HPXML::WallTypeStone, HPXML::WallTypeLog
      constr_sets = [
        GenericConstructionSet.new(10.0, 0.5, mat_int_finish, mat_ext_finish),                  # w/R-10 rigid
        GenericConstructionSet.new(0.0, 0.5, mat_int_finish, mat_ext_finish),                   # Standard
        GenericConstructionSet.new(0.0, 0.0, fallback_mat_int_finish, fallback_mat_ext_finish), # Fallback
      ]
      match, constr_set, layer_r = pick_generic_construction_set(assembly_r, constr_sets, interior_film, exterior_film)

      case wall_type
      when HPXML::WallTypeConcrete
        thick_in = 6.0
        base_mat = BaseMaterial.Concrete
      when HPXML::WallTypeBrick
        thick_in = 8.0
        base_mat = BaseMaterial.Brick
      when HPXML::WallTypeAdobe
        thick_in = 10.0
        base_mat = BaseMaterial.Soil(12.0)
      when HPXML::WallTypeStrawBale
        thick_in = 23.0
        base_mat = BaseMaterial.StrawBale
      when HPXML::WallTypeStone
        thick_in = 6.0
        base_mat = BaseMaterial.Stone
      when HPXML::WallTypeLog
        thick_in = 6.0
        base_mat = BaseMaterial.Wood
      end
      thick_ins = [thick_in]
      if layer_r == 0
        conds = [99]
      else
        conds = [thick_in / layer_r]
      end
      denss = [base_mat.rho]
      specheats = [base_mat.cp]

      apply_generic_layered_wall(model, surfaces, "#{wall_id} construction", thick_ins, conds, denss,
                                 specheats, constr_set.mat_int_finish, constr_set.osb_thick_in,
                                 constr_set.rigid_r, constr_set.mat_ext_finish, has_radiant_barrier,
                                 interior_film, exterior_film, radiant_barrier_grade, solar_absorptance,
                                 emittance)

    else
      fail "Unexpected wall type '#{wall_type}'."

    end

    check_surface_assembly_rvalue(runner, surfaces, interior_film, exterior_film, assembly_r, match)
  end

  # Applies a floor/ceiling construction to the OpenStudio surface.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surface [OpenStudio::Model::Surface] an OpenStudio::Model::Surface object
  # @param floor_id [String] HPXML Floor ID
  # @param floor_type [HPXML::FloorTypeXXX] The floor construction type
  # @param is_ceiling [Boolean] Whether the HPXML Floor represents a ceiling or floor surface
  # @param assembly_r [Double] Air-to-air insulation assembly R-value (hr-ft2-F/Btu)
  # @param mat_int_finish_or_covering [Material] Material properties for the ceiling interior finish (e.g., drywall) or floor covering (e.g., carpet)
  # @param has_radiant_barrier [Boolean] Whether a radiant barrier is present (for an attic floor)
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param radiant_barrier_grade [Integer] Radiant barrier installation grade as defined by RESNET (1-3)
  # @return [nil]
  def self.apply_floor_ceiling_construction(runner, model, surface, floor_id, floor_type, is_ceiling, assembly_r,
                                            mat_int_finish_or_covering, has_radiant_barrier, interior_film, exterior_film,
                                            radiant_barrier_grade)

    if mat_int_finish_or_covering.nil?
      fallback_mat_int_finish_or_covering = nil
    else
      if is_ceiling
        fallback_mat_int_finish_or_covering = Material.InteriorFinishMaterial(mat_int_finish_or_covering.name, 0.1) # Try thin material
      else
        fallback_mat_int_finish_or_covering = Material.CoveringBare(0.8, 0.01) # Try thin material
      end
    end
    osb_thick_in = (is_ceiling ? 0.0 : 0.75)

    case floor_type
    when HPXML::FloorTypeWoodFrame
      install_grade = 1
      constr_sets = [
        WoodStudConstructionSet.new(Material.Stud2x(6), 0.10, 50.0, osb_thick_in, mat_int_finish_or_covering, nil), # 2x6, 24" o.c. + R50
        WoodStudConstructionSet.new(Material.Stud2x(6), 0.10, 40.0, osb_thick_in, mat_int_finish_or_covering, nil), # 2x6, 24" o.c. + R40
        WoodStudConstructionSet.new(Material.Stud2x(6), 0.10, 30.0, osb_thick_in, mat_int_finish_or_covering, nil), # 2x6, 24" o.c. + R30
        WoodStudConstructionSet.new(Material.Stud2x(6), 0.10, 20.0, osb_thick_in, mat_int_finish_or_covering, nil), # 2x6, 24" o.c. + R20
        WoodStudConstructionSet.new(Material.Stud2x(6), 0.10, 10.0, osb_thick_in, mat_int_finish_or_covering, nil), # 2x6, 24" o.c. + R10
        WoodStudConstructionSet.new(Material.Stud2x(6), 0.10, 0.0, osb_thick_in, mat_int_finish_or_covering, nil), # 2x6, 24" o.c.
        WoodStudConstructionSet.new(Material.Stud2x(4), 0.13, 0.0, osb_thick_in, mat_int_finish_or_covering, nil),  # 2x4, 16" o.c.
        WoodStudConstructionSet.new(Material.Stud2x(4), 0.01, 0.0, 0.0, fallback_mat_int_finish_or_covering, nil),  # Fallback
      ]
      match, constr_set, cavity_r = pick_wood_stud_construction_set(assembly_r, constr_sets, interior_film, exterior_film)
      constr_int_finish_or_covering = constr_set.mat_int_finish

      apply_wood_frame_floor_ceiling(model, surface, "#{floor_id} construction", is_ceiling, cavity_r, install_grade,
                                     constr_set.framing_factor, constr_set.stud.thick_in,
                                     constr_set.osb_thick_in, constr_set.rigid_r, constr_int_finish_or_covering,
                                     has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade)

    when HPXML::FloorTypeSteelFrame
      install_grade = 1
      corr_factor = 0.45
      osb_thick_in = (is_ceiling ? 0.0 : 0.75)
      constr_sets = [
        SteelStudConstructionSet.new(5.5, corr_factor, 50.0, osb_thick_in, mat_int_finish_or_covering, nil), # 2x6 + R50
        SteelStudConstructionSet.new(5.5, corr_factor, 40.0, osb_thick_in, mat_int_finish_or_covering, nil), # 2x6 + R40
        SteelStudConstructionSet.new(5.5, corr_factor, 30.0, osb_thick_in, mat_int_finish_or_covering, nil), # 2x6 + R30
        SteelStudConstructionSet.new(5.5, corr_factor, 20.0, osb_thick_in, mat_int_finish_or_covering, nil), # 2x6 + R20
        SteelStudConstructionSet.new(5.5, corr_factor, 10.0, osb_thick_in, mat_int_finish_or_covering, nil), # 2x6 + R10
        SteelStudConstructionSet.new(3.5, corr_factor, 0.0, osb_thick_in, mat_int_finish_or_covering, nil),  # 2x4
        SteelStudConstructionSet.new(3.5, 1.0, 0.0, 0.0, fallback_mat_int_finish_or_covering, nil),          # Fallback
      ]
      match, constr_set, cavity_r = pick_steel_stud_construction_set(assembly_r, constr_sets, interior_film, exterior_film)
      constr_int_finish_or_covering = constr_set.mat_int_finish

      apply_steel_frame_floor_ceiling(model, surface, "#{floor_id} construction", is_ceiling, cavity_r, install_grade,
                                      constr_set.corr_factor, constr_set.cavity_depth_in, constr_set.osb_thick_in,
                                      constr_set.rigid_r, constr_int_finish_or_covering, has_radiant_barrier, interior_film,
                                      exterior_film, radiant_barrier_grade)

    when HPXML::FloorTypeSIP
      constr_sets = [
        SIPConstructionSet.new(16.0, 0.08, 0.0, 0.0, osb_thick_in, mat_int_finish_or_covering, nil), # 16" SIP core
        SIPConstructionSet.new(12.0, 0.08, 0.0, 0.0, osb_thick_in, mat_int_finish_or_covering, nil), # 12" SIP core
        SIPConstructionSet.new(8.0, 0.08, 0.0, 0.0, osb_thick_in, mat_int_finish_or_covering, nil),  # 8" SIP core
        SIPConstructionSet.new(1.1, 0.01, 0.0, 0.0, 0.0, fallback_mat_int_finish_or_covering, nil), # Fallback
      ]
      match, constr_set, cavity_r = pick_sip_construction_set(assembly_r, constr_sets, interior_film, exterior_film)

      apply_sip_floor_ceiling(model, surface, "#{floor_id} construction", is_ceiling, cavity_r,
                              constr_set.ins_thick_in, constr_set.framing_factor, constr_set.mat_int_finish,
                              constr_set.osb_thick_in, constr_set.rigid_r, constr_set.mat_ext_finish,
                              has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade)

    when HPXML::FloorTypeConcrete
      constr_sets = [
        GenericConstructionSet.new(20.0, osb_thick_in, mat_int_finish_or_covering, nil), # w/R-20 rigid
        GenericConstructionSet.new(10.0, osb_thick_in, mat_int_finish_or_covering, nil), # w/R-10 rigid
        GenericConstructionSet.new(0.0, osb_thick_in, mat_int_finish_or_covering, nil),  # Standard
        GenericConstructionSet.new(0.0, 0.0, fallback_mat_int_finish_or_covering, nil),  # Fallback
      ]
      match, constr_set, layer_r = pick_generic_construction_set(assembly_r, constr_sets, interior_film, exterior_film)

      thick_in = 6.0
      base_mat = BaseMaterial.Concrete
      thick_ins = [thick_in]
      if layer_r == 0
        conds = [99]
      else
        conds = [thick_in / layer_r]
      end
      denss = [base_mat.rho]
      specheats = [base_mat.cp]

      apply_generic_layered_floor_ceiling(model, surface, "#{floor_id} construction", is_ceiling, thick_ins,
                                          conds, denss, specheats, constr_set.mat_int_finish, constr_set.osb_thick_in,
                                          constr_set.rigid_r, constr_set.mat_ext_finish, has_radiant_barrier,
                                          interior_film, exterior_film, radiant_barrier_grade)

    else
      fail "Unexpected floor type '#{floor_type}'."

    end

    check_surface_assembly_rvalue(runner, surface, interior_film, exterior_film, assembly_r, match)
  end

  # Arbitrary construction for heat capacitance.
  # Only applies to surfaces where outside boundary conditioned is
  # adiabatic or surface net area is near zero.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param type [String] floor, wall, or roof
  # @return [nil]
  def self.apply_adiabatic_construction(model, surfaces, type)
    return if surfaces.empty?

    if type == 'wall'
      mat_int_finish = Material.InteriorFinishMaterial(HPXML::InteriorFinishGypsumBoard, 0.5)
      mat_ext_finish = Material.ExteriorFinishMaterial(HPXML::SidingTypeWood)
      apply_wood_stud_wall(model, surfaces, 'AdiabaticWallConstruction',
                           0, 1, 3.5, true, 0.1, mat_int_finish, 0, 99, mat_ext_finish, false,
                           Material.AirFilmIndoorWall, Material.AirFilmIndoorWall, nil)
    elsif type == 'floor'
      apply_wood_frame_floor_ceiling(model, surfaces, 'AdiabaticFloorConstruction', false,
                                     0, 1, 0.07, 5.5, 0.75, 99, Material.CoveringBare, false,
                                     Material.AirFilmIndoorFloorAverage, Material.AirFilmIndoorFloorAverage, nil)
    elsif type == 'roof'
      apply_open_cavity_roof(model, surfaces, 'AdiabaticRoofConstruction',
                             0, 1, 7.25, 0.07, 7.25, 0.0, 99,
                             Material.RoofMaterialAndSheathing(HPXML::RoofTypeAsphaltShingles),
                             false, Material.AirFilmOutside,
                             Material.AirFilmIndoorRoof(UnitConversions.convert(surfaces[0].tilt, 'rad', 'deg')), nil)
    end
  end

  # Picks a wood stud construction set from supplied constr_sets for which a positive R-value
  # can be calculated for the unknown insulation to achieve the assembly R-value.
  #
  # @param assembly_r [Double] Air-to-air insulation assembly R-value (hr-ft2-F/Btu)
  # @param constr_sets [Array<WoodStudConstructionSet>] List of construction sets to choose from, in order of priority
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @return [Array<Boolean, WoodStudConstructionSet, Double>] Whether we could match the assembly R-value, the selected construction set, and the calculated cavity R-value (hr-ft2-F/Btu)
  def self.pick_wood_stud_construction_set(assembly_r, constr_sets, interior_film, exterior_film)
    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? WoodStudConstructionSet

      non_cavity_r = calc_construction_set_base_r(constr_set, interior_film, exterior_film)

      # Calculate effective cavity R-value
      # Assumes installation quality 1
      cavity_frac = 1.0 - constr_set.framing_factor
      cavity_r = cavity_frac / (1.0 / assembly_r - constr_set.framing_factor / (constr_set.stud.rvalue + non_cavity_r)) - non_cavity_r
      if cavity_r > 0 && cavity_r < Float::INFINITY # Choose this construction set
        return true, constr_set, cavity_r
      end
    end

    return false, constr_sets[-1], 0.0 # Pick fallback construction with minimum R-value
  end

  # Picks a steel frame construction set from supplied constr_sets for which a positive R-value
  # can be calculated for the unknown insulation to achieve the assembly R-value.
  #
  # @param assembly_r [Double] Air-to-air insulation assembly R-value (hr-ft2-F/Btu)
  # @param constr_sets [Array<SteelStudConstructionSet>] List of construction sets to choose from, in order of priority
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @return [Array<Boolean, SteelStudConstructionSet, Double>] Whether we could match the assembly R-value, the selected construction set, and the calculated cavity R-value (hr-ft2-F/Btu)
  def self.pick_steel_stud_construction_set(assembly_r, constr_sets, interior_film, exterior_film)
    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? SteelStudConstructionSet

      non_cavity_r = calc_construction_set_base_r(constr_set, interior_film, exterior_film)

      # Calculate effective cavity R-value
      # Assumes installation quality 1
      cavity_r = (assembly_r - non_cavity_r) / constr_set.corr_factor
      if cavity_r > 0 && cavity_r < Float::INFINITY # Choose this construction set
        return true, constr_set, cavity_r
      end
    end

    return false, constr_sets[-1], 0.0 # Pick fallback construction with minimum R-value
  end

  # Picks a double wood stud construction set from supplied constr_sets for which a positive R-value
  # can be calculated for the unknown insulation to achieve the assembly R-value.
  #
  # @param assembly_r [Double] Air-to-air insulation assembly R-value (hr-ft2-F/Btu)
  # @param constr_sets [Array<DoubleStudConstructionSet>] List of construction sets to choose from, in order of priority
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @return [Array<Boolean, DoubleStudConstructionSet, Double>] Whether we could match the assembly R-value, the selected construction set, and the calculated cavity R-value (hr-ft2-F/Btu)
  def self.pick_double_stud_construction_set(assembly_r, constr_sets, interior_film, exterior_film)
    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? DoubleStudConstructionSet

      non_cavity_r = calc_construction_set_base_r(constr_set, interior_film, exterior_film)

      # Calculate effective cavity R-value
      # Assumes installation quality 1, not staggered, gap depth == stud depth
      # Solved in Wolfram Alpha: https://www.wolframalpha.com/input/?i=1%2FA+%3D+B%2F(2*C%2Bx%2BD)+%2B+E%2F(3*C%2BD)+%2B+(1-B-E)%2F(3*x%2BD)
      stud_frac = 1.5 / constr_set.framing_spacing
      misc_framing_factor = constr_set.framing_factor - stud_frac
      a = assembly_r
      b = stud_frac
      c = constr_set.stud.rvalue
      d = non_cavity_r
      e = misc_framing_factor
      cavity_r = ((3 * c + d) * Math.sqrt(4 * a**2 * b**2 + 12 * a**2 * b * e + 4 * a**2 * b + 9 * a**2 * e**2 - 6 * a**2 * e + a**2 - 48 * a * b * c - 16 * a * b * d - 36 * a * c * e + 12 * a * c - 12 * a * d * e + 4 * a * d + 36 * c**2 + 24 * c * d + 4 * d**2) + 6 * a * b * c + 2 * a * b * d + 3 * a * c * e + 3 * a * c + 3 * a * d * e + a * d - 18 * c**2 - 18 * c * d - 4 * d**2) / (2 * (-3 * a * e + 9 * c + 3 * d))
      cavity_r = 3 * cavity_r
      if cavity_r > 0 && cavity_r < Float::INFINITY # Choose this construction set
        return true, constr_set, cavity_r
      end
    end

    return false, constr_sets[-1], 0.1 # Pick fallback construction with minimum R-value
  end

  # Picks a structural insulated panel (SIP) construction set from supplied constr_sets for which a positive R-value
  # can be calculated for the unknown insulation to achieve the assembly R-value.
  #
  # @param assembly_r [Double] Air-to-air insulation assembly R-value (hr-ft2-F/Btu)
  # @param constr_sets [Array<SIPConstructionSet>] List of construction sets to choose from, in order of priority
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @return [Array<Boolean, SIPConstructionSet, Double>] Whether we could match the assembly R-value, the selected construction set, and the calculated cavity R-value (hr-ft2-F/Btu)
  def self.pick_sip_construction_set(assembly_r, constr_sets, interior_film, exterior_film)
    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? SIPConstructionSet

      non_cavity_r = calc_construction_set_base_r(constr_set, interior_film, exterior_film)
      non_cavity_r += Material.new(thick_in: constr_set.sheath_thick_in, mat_base: BaseMaterial.Wood).rvalue

      # Calculate effective SIP core R-value
      # Solved in Wolfram Alpha: https://www.wolframalpha.com/input/?i=1%2FA+%3D+B%2F(C%2BD)+%2B+E%2F(2*F%2BG%2FH*x%2BD)+%2B+(1-B-E)%2F(x%2BD)
      spline_thick_in = 0.5 # in
      ins_thick_in = constr_set.ins_thick_in - (2.0 * spline_thick_in) # in
      framing_r = Material.new(thick_in: constr_set.ins_thick_in, mat_base: BaseMaterial.Wood).rvalue
      spline_r = Material.new(thick_in: spline_thick_in, mat_base: BaseMaterial.Wood).rvalue
      spline_frac = 4.0 / 48.0 # One 4" spline for every 48" wide panel
      a = assembly_r
      b = constr_set.framing_factor
      c = framing_r
      d = non_cavity_r
      e = spline_frac
      f = spline_r
      g = ins_thick_in
      h = constr_set.ins_thick_in
      cavity_r = (Math.sqrt((a * b * c * g - a * b * d * h - 2 * a * b * f * h + a * c * e * g - a * c * e * h - a * c * g + a * d * e * g - a * d * e * h - a * d * g + c * d * g + c * d * h + 2 * c * f * h + d**2 * g + d**2 * h + 2 * d * f * h)**2 - 4 * (-a * b * g + c * g + d * g) * (a * b * c * d * h + 2 * a * b * c * f * h - a * c * d * h + 2 * a * c * e * f * h - 2 * a * c * f * h - a * d**2 * h + 2 * a * d * e * f * h - 2 * a * d * f * h + c * d**2 * h + 2 * c * d * f * h + d**3 * h + 2 * d**2 * f * h)) - a * b * c * g + a * b * d * h + 2 * a * b * f * h - a * c * e * g + a * c * e * h + a * c * g - a * d * e * g + a * d * e * h + a * d * g - c * d * g - c * d * h - 2 * c * f * h - g * d**2 - d**2 * h - 2 * d * f * h) / (2 * (-a * b * g + c * g + d * g))
      if cavity_r > 0 && cavity_r < Float::INFINITY # Choose this construction set
        return true, constr_set, cavity_r
      end
    end

    return false, constr_sets[-1], 0.1 # Pick fallback construction with minimum R-value
  end

  # Picks a concrete masonry unit (CMU) construction set from supplied constr_sets for which a positive R-value
  # can be calculated for the unknown insulation to achieve the assembly R-value.
  #
  # @param assembly_r [Double] Air-to-air insulation assembly R-value (hr-ft2-F/Btu)
  # @param constr_sets [Array<CMUConstructionSet>] List of construction sets to choose from, in order of priority
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @return [Array<Boolean, CMUConstructionSet, Double>] Whether we could match the assembly R-value, the selected construction set, and the calculated cavity R-value (hr-ft2-F/Btu)
  def self.pick_cmu_construction_set(assembly_r, constr_sets, interior_film, exterior_film)
    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? CMUConstructionSet

      non_cavity_r = calc_construction_set_base_r(constr_set, interior_film, exterior_film)

      # Calculate effective other CMU R-value
      # Assumes no furring strips
      # Solved in Wolfram Alpha: https://www.wolframalpha.com/input/?i=1%2FA+%3D+B%2F(C%2BE%2Bx)+%2B+(1-B)%2F(D%2BE%2Bx)
      a = assembly_r
      b = constr_set.framing_factor
      c = Material.new(thick_in: constr_set.thick_in, mat_base: BaseMaterial.Wood).rvalue # Framing
      d = Material.new(thick_in: constr_set.thick_in, mat_base: BaseMaterial.Concrete, k_in: constr_set.conductivity_in).rvalue # Concrete
      e = non_cavity_r
      rigid_r = 0.5 * (Math.sqrt(a**2 - 4 * a * b * c + 4 * a * b * d + 2 * a * c - 2 * a * d + c**2 - 2 * c * d + d**2) + a - c - d - 2 * e)
      if rigid_r > 0 && rigid_r < Float::INFINITY # Choose this construction set
        return true, constr_set, rigid_r
      end
    end

    return false, constr_sets[-1], 0.0 # Pick fallback construction with minimum R-value
  end

  # Picks an insulated concrete form (ICF) construction set from supplied constr_sets for which a positive R-value
  # can be calculated for the unknown insulation to achieve the assembly R-value.
  #
  # @param assembly_r [Double] Air-to-air insulation assembly R-value (hr-ft2-F/Btu)
  # @param constr_sets [Array<ICFConstructionSet>] List of construction sets to choose from, in order of priority
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @return [Array<Boolean, ICFConstructionSet, Double>] Whether we could match the assembly R-value, the selected construction set, and the calculated cavity R-value (hr-ft2-F/Btu)
  def self.pick_icf_construction_set(assembly_r, constr_sets, interior_film, exterior_film)
    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? ICFConstructionSet

      non_cavity_r = calc_construction_set_base_r(constr_set, interior_film, exterior_film)

      # Calculate effective ICF rigid ins R-value
      # Solved in Wolfram Alpha: https://www.wolframalpha.com/input/?i=1%2FA+%3D+B%2F(C%2BE)+%2B+(1-B)%2F(D%2BE%2B2*x)
      a = assembly_r
      b = constr_set.framing_factor
      c = Material.new(thick_in: 2 * constr_set.ins_thick_in + constr_set.concrete_thick_in, mat_base: BaseMaterial.Wood).rvalue # Framing
      d = Material.new(thick_in: constr_set.concrete_thick_in, mat_base: BaseMaterial.Concrete).rvalue # Concrete
      e = non_cavity_r
      icf_r = (a * b * c - a * b * d - a * c - a * e + c * d + c * e + d * e + e**2) / (2 * (a * b - c - e))
      if icf_r > 0 && icf_r < Float::INFINITY # Choose this construction set
        return true, constr_set, icf_r
      end
    end

    return false, constr_sets[-1], 0.0 # Pick fallback construction with minimum R-value
  end

  # Picks a generic layer-by-layer construction set from supplied constr_sets for which a positive R-value
  # can be calculated for the unknown insulation to achieve the assembly R-value.
  #
  # @param assembly_r [Double] Air-to-air insulation assembly R-value (hr-ft2-F/Btu)
  # @param constr_sets [Array<GenericConstructionSet>] List of construction sets to choose from, in order of priority
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @return [Array<Boolean, GenericConstructionSet, Double>] Whether we could match the assembly R-value, the selected construction set, and the calculated cavity R-value (hr-ft2-F/Btu)
  def self.pick_generic_construction_set(assembly_r, constr_sets, interior_film, exterior_film)
    constr_sets.each do |constr_set|
      fail 'Unexpected object.' unless constr_set.is_a? GenericConstructionSet

      non_cavity_r = calc_construction_set_base_r(constr_set, interior_film, exterior_film)

      # Calculate effective ins layer R-value
      layer_r = assembly_r - non_cavity_r
      if layer_r > 0 && layer_r < Float::INFINITY # Choose this construction set
        return true, constr_set, layer_r
      end
    end

    return false, constr_sets[-1], 0.0 # Pick fallback construction with minimum R-value
  end

  # Verifies that the actual OpenStudio construction R-value matches our target assembly R-value.
  # Throws an error if they do not match and should, or throws a warning if they do not match
  # but it's because the assembly R-value has been increased because it is too low.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param interior_film [Material] Material with the interior air film R-value
  # @param exterior_film [Material] Material with the exterior air film R-value
  # @param assembly_r [Double] Air-to-air insulation assembly R-value (hr-ft2-F/Btu)
  # @param match [Boolean] Whether we are expecting the construction R-value to match the target assembly R-value
  # @return [nil]
  def self.check_surface_assembly_rvalue(runner, surfaces, interior_film, exterior_film, assembly_r, match)
    film_r = 0.0
    film_r += interior_film.rvalue unless interior_film.nil?
    film_r += exterior_film.rvalue unless exterior_film.nil?
    surfaces.each do |surface|
      constr_r = UnitConversions.convert(1.0 / surface.construction.get.uFactor(0.0).get, 'm^2*k/w', 'hr*ft^2*f/btu') + film_r

      if surface.adjacentFoundation.is_initialized
        foundation = surface.adjacentFoundation.get
        foundation.customBlocks.each do |custom_block|
          ins_mat = custom_block.material.to_StandardOpaqueMaterial.get
          constr_r += UnitConversions.convert(ins_mat.thickness, 'm', 'ft') / UnitConversions.convert(ins_mat.thermalConductivity, 'W/(m*K)', 'Btu/(hr*ft*R)')
        end
      end

      if (assembly_r - constr_r).abs > 0.1
        if match
          fail "Construction R-value (#{constr_r}) does not match Assembly R-value (#{assembly_r}) for '#{surface.name}'."
        else
          runner.registerWarning("Assembly R-value (#{assembly_r}) for '#{surface.name}' below minimum expected value. Construction R-value increased to #{constr_r.round(2)}.")
        end
      end
    end
  end

  # Returns a window U-factor and SHGC that accounts for the effect of a storm window.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param storm_type [HPXML::WindowGlassTypeXXX] The type of storm
  # @param base_ufactor [Double] Full-assembly NFRC U-factor (Btu/F-ft2-hr)
  # @param base_shgc [Double] Full-assembly NFRC solar heat gain coefficient (frac)
  # @return [Array<Double, Double>] Storm-adjusted U-factor (Btu/F-ft2-hr) and SHGC (frac)
  def self.get_ufactor_shgc_adjusted_by_storms(runner, storm_type, base_ufactor, base_shgc)
    return base_ufactor, base_shgc if storm_type.nil?

    # U-factor and SHGC adjustment based on data from https://www.pnnl.gov/main/publications/external/technical_reports/PNNL-24444.pdf
    min_base_ufactor_for_storm = 0.3
    if base_ufactor < min_base_ufactor_for_storm
      runner.registerWarning("Storm windows may not be modeled accurately when window U-factor is lower than #{min_base_ufactor_for_storm}, while base window U-Factor was #{base_ufactor}.")
    end

    if storm_type == HPXML::WindowGlassTypeClear
      ufactor_abs_reduction = [0.6435 * base_ufactor - 0.1533, 0.0].max
      shgc_corr = 0.9
    elsif storm_type == HPXML::WindowGlassTypeLowE
      ufactor_abs_reduction = [0.766 * base_ufactor - 0.1532, 0.0].max
      shgc_corr = 0.8
    else
      fail "Could not find adjustment factors for storm type '#{storm_type}'"
    end

    ufactor = base_ufactor - ufactor_abs_reduction
    shgc = base_shgc * shgc_corr

    return ufactor, shgc
  end
end

# Facilitates creating and assigning an OpenStudio construction (with accompanying
# OpenStudio Materials) from Material objects. Handles parallel path calculations.
class Construction
  # @param name [String] Name of the construction
  # @param path_fracs [Array<Double>] Fractions of surface area corresponding to every unique parallel path in the construction
  def initialize(name, path_fracs)
    @name = name
    @path_fracs = path_fracs
    @layers_names = []
    @layers_materials = []
  end

  # Adds the specified layer material(s) to the construction.
  #
  # @param materials [Material or Array<Material>] One or more materials that make up the layer
  # @param name [String or nil] Name of the layer; required if multiple materials are provided, otherwise the material name is used
  # @return [nil]
  def add_layer(materials, name = nil)
    if not materials.kind_of?(Array)
      @layers_materials << [materials]
      if not name.nil?
        @layers_names << name
      else
        @layers_names << materials.name
      end
    else
      @layers_materials << materials
      if not name.nil?
        @layers_names << name
      else
        @layers_names << 'ParallelMaterial'
      end
    end
  end

  # Calculates the overall assembly R-value for the construction.
  #
  # @return [Double] Construction assembly R-value (hr-ft2-F/Btu)
  def assembly_rvalue()
    validate

    u_overall = 0
    @path_fracs.each_with_index do |path_frac, path_num|
      # For each parallel path, sum series:
      r_path = 0
      @layers_materials.each do |layer_materials|
        if layer_materials.size == 1
          # One material for this layer
          r_path += layer_materials[0].rvalue
        else
          # Multiple parallel materials for this layer, use appropriate one
          r_path += layer_materials[path_num].rvalue
        end
      end
      u_overall += 1.0 / r_path * path_frac
    end
    r_overall = 1.0 / u_overall
    return r_overall
  end

  # Creates the OpenStudio construction and applies it to the OpenStudio surfaces.
  # Also handles the reverse construction as needed.
  #
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [nil]
  def create_and_assign_constructions(surfaces, model)
    validate

    # Create list of OpenStudio materials
    materials = construct_materials(model)

    # Create OpenStudio construction and assign to surface
    constr = Model.add_construction(
      model,
      name: @name,
      layers: materials
    )
    revconstr = nil

    # Assign constructions to surfaces
    surfaces.each do |surface|
      surface.setConstruction(constr)

      # Assign reverse construction to adjacent surface as needed
      next if surface.is_a?(OpenStudio::Model::SubSurface) || surface.is_a?(OpenStudio::Model::InternalMassDefinition) || (not surface.adjacentSurface.is_initialized)

      if revconstr.nil?
        revconstr = constr.reverseConstruction
      end
      adjacent_surface = surface.adjacentSurface.get
      adjacent_surface.setConstruction(revconstr)
    end
  end

  # Sets solar absorptance and emittance for the outermost construction material.
  #
  # @param solar_absorptance [Double] Material solar absorptance (frac)
  # @param emittance [Double] Material emittance (frac)
  # @return [nil]
  def set_exterior_material_properties(solar_absorptance = 0.75, emittance = 0.9)
    # We use index 1 because 0 is the exterior air film
    @layers_materials[1].each do |exterior_material|
      exterior_material.sAbs = solar_absorptance
      exterior_material.tAbs = emittance
    end
  end

  # Sets solar absorptance and emittance for the innermost construction material.
  #
  # @param solar_absorptance [Double] Material solar absorptance (frac)
  # @param emittance [Double] Material emittance (frac)
  # @return [nil]
  def set_interior_material_properties(solar_absorptance = 0.6, emittance = 0.9)
    # If there is only a single opaque material (i.e., excluding the two
    # air film layers), EnergyPlus currently only supports a single solar
    # absorptance/emittance, so it is not possible to assign different values
    # to the two sides.
    # FUTURE: Improve this when https://github.com/NatLabRockies/EnergyPlus/pull/11750
    # is available.
    if @layers_materials.size <= 3
      return
    end

    # We use index -2 because -1 is the interior air film
    @layers_materials[-2].each do |interior_material|
      interior_material.sAbs = solar_absorptance
      interior_material.tAbs = emittance
    end
  end

  private

  # Returns a new Material object with effective properties for the specified parallel
  # path layer (e.g., wood stud and cavity insulation) within the construction.
  #
  # @param layer_idx [Integer] Index of the construction layer with the parallel paths
  # @param name [String] Name for the combined material
  # @return [Material] The combined material
  def get_parallel_material(layer_idx, name)
    mat = Material.new(name: name)

    curr_layer_materials = @layers_materials[layer_idx]

    r_overall = assembly_rvalue()

    # Calculate individual R-values for each layer
    sum_r_all_layers = 0
    sum_r_parallel_layers = 0
    layer_rvalues = []
    @layers_materials.each do |layer_materials|
      u_path = 0
      layer_materials.each_with_index do |layer_material, idx|
        if layer_materials.size > 1
          u_path += @path_fracs[idx] / (layer_material.thick / layer_material.k)
        else
          u_path += 1.0 / (layer_material.thick / layer_material.k)
        end
      end
      r_path = 1.0 / u_path
      layer_rvalues << r_path
      sum_r_all_layers += r_path
      if layer_materials.size > 1
        sum_r_parallel_layers += r_path
      end
    end

    # Material R-value
    # Apportion R-value to the current parallel path layer
    mat.rvalue = layer_rvalues[layer_idx] + (r_overall - sum_r_all_layers) * layer_rvalues[layer_idx] / sum_r_parallel_layers

    # Material thickness and conductivity
    mat.thick_in = curr_layer_materials[0].thick_in # All paths have equal thickness
    mat.thick = curr_layer_materials[0].thick # All paths have equal thickness
    mat.k = mat.thick / mat.rvalue

    # Material density
    mat.rho = 0
    @path_fracs.each_with_index do |path_frac, path_num|
      mat.rho += curr_layer_materials[path_num].rho * path_frac
    end

    # Material specific heat
    mat.cp = 0
    @path_fracs.each_with_index do |path_frac, path_num|
      mat.cp += (curr_layer_materials[path_num].cp * curr_layer_materials[path_num].rho * path_frac) / mat.rho
    end

    # Material solar absorptance
    mat.sAbs = curr_layer_materials[0].sAbs # All paths have equal solar absorptance

    # Material thermal absorptance
    mat.tAbs = curr_layer_materials[0].tAbs # All paths have equal thermal absorptance

    return mat
  end

  # Creates the OpenStudio material objects for this construction.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [Array<OpenStudio::Model::StandardOpaqueMaterial or OpenStudio::Model::GlazingMaterial>] The list of OpenStudio materials
  def construct_materials(model)
    materials = []
    @layers_materials.each_with_index do |layer_materials, layer_idx|
      if layer_materials.size == 1
        # Do not include air films in the E+ construction
        next if layer_materials[0].name == Constants::AirFilm

        mat = create_os_material(model, layer_materials[0])
      else
        parallel_path_mat = get_parallel_material(layer_idx, @layers_names[layer_idx])
        mat = create_os_material(model, parallel_path_mat)
      end
      materials << mat
    end
    return materials
  end

  # Various error-checking on the Construction object inputs/properties. Throws
  # an error if something is not right.
  #
  # @return [nil]
  def validate
    # Check that sum of path fracs equal 1
    sum_path_fracs = @path_fracs.sum(0.0)
    if (sum_path_fracs <= 0.999) || (sum_path_fracs >= 1.001)
      fail "Invalid construction: Sum of path fractions (#{sum_path_fracs}) is not 1."
    end

    # Check that all path fractions are not negative
    @path_fracs.each do |path_frac|
      if path_frac < 0
        fail "Invalid construction: Path fraction (#{path_frac}) must be greater than or equal to 0."
      end
    end

    # Check if all materials are GlazingMaterial
    all_glazing = true
    @layers_materials.each do |layer_materials|
      layer_materials.each do |mat|
        if not mat.is_a? GlazingMaterial
          all_glazing = false
        end
      end
    end
    if all_glazing
      # Check that no parallel materials
      @layers_materials.each do |layer_materials|
        if layer_materials.size > 1
          fail 'Invalid construction: Cannot have multiple GlazingMaterials in a single layer.'
        end
      end
      return
    end

    # Check for valid object types
    @layers_materials.each do |layer_materials|
      layer_materials.each do |mat|
        if (not mat.is_a? Material)
          fail 'Invalid construction: Materials must be instances of Material classes.'
        end
      end
    end

    # Check if invalid number of materials in a layer
    @layers_materials.each do |layer_materials|
      if (layer_materials.size > 1) && (layer_materials.size < @path_fracs.size)
        fail 'Invalid construction: Layer must either have one material or same number of materials as paths.'
      end
    end

    # Check if multiple materials in a given layer have differing thicknesses/absorptances
    @layers_materials.each do |layer_materials|
      next unless layer_materials.size > 1

      thick_in = nil
      solar_abs = nil
      emitt = nil
      layer_materials.each do |mat|
        if thick_in.nil?
          thick_in = mat.thick_in
        elsif thick_in != mat.thick_in
          fail 'Invalid construction: Materials in a layer have different thicknesses.'
        end
        if solar_abs.nil?
          solar_abs = mat.sAbs
        elsif solar_abs != mat.sAbs
          fail 'Invalid construction: Materials in a layer have different solar absorptances.'
        end
        if emitt.nil?
          emitt = mat.tAbs
        elsif emitt != mat.tAbs
          fail 'Invalid construction: Materials in a layer have different thermal absorptances.'
        end
      end
    end

    # Check if multiple non-contiguous parallel layers
    found_parallel = false
    last_parallel = false
    @layers_materials.each do |layer_materials|
      if layer_materials.size > 1
        if not found_parallel
          found_parallel = true
        elsif not last_parallel
          fail 'Invalid construction: Non-contiguous parallel layers found.'
        end
      end
      last_parallel = (layer_materials.size > 1)
    end
  end

  # Creates (or returns an existing) OpenStudio material from our own Material object
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param material [Material] The material to create an OpenStudio material from
  # @return [OpenStudio::Model::StandardOpaqueMaterial or OpenStudio::Model::GlazingMaterial] The corresponding OpenStudio material
  def create_os_material(model, material)
    if material.is_a? GlazingMaterial
      mat = Model.add_simple_glazing(
        model,
        name: material.name,
        ufactor: UnitConversions.convert(material.ufactor, 'Btu/(hr*ft^2*F)', 'W/(m^2*K)'),
        shgc: material.shgc
      )
    else
      mat = Model.add_opaque_material(
        model,
        name: material.name,
        thickness: UnitConversions.convert(material.thick_in, 'in', 'm'),
        conductivity: UnitConversions.convert(material.k, 'Btu/(hr*ft*R)', 'W/(m*K)'),
        density: UnitConversions.convert(material.rho, 'lbm/ft^3', 'kg/m^3'),
        specific_heat: UnitConversions.convert(material.cp, 'Btu/(lbm*R)', 'J/(kg*K)'),
        thermal_abs: material.tAbs,
        solar_abs: material.sAbs
      )
    end
    return mat
  end
end

# Object with properties that describe a wood stud construction
class WoodStudConstructionSet
  # @param stud [Material] Material properties for the wood stud
  # @param framing_factor [Double] Fraction of total surface area comprised of structural framing and framing for windows/doors (frac)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  def initialize(stud, framing_factor, rigid_r, osb_thick_in, mat_int_finish, mat_ext_finish)
    @stud = stud
    @framing_factor = framing_factor
    @rigid_r = rigid_r
    @osb_thick_in = osb_thick_in
    @mat_int_finish = mat_int_finish
    @mat_ext_finish = mat_ext_finish
  end
  attr_accessor(:stud, :framing_factor, :rigid_r, :osb_thick_in, :mat_int_finish, :mat_ext_finish)
end

# Object with properties that describe a steel frame construction
class SteelStudConstructionSet
  # @param cavity_depth_in [Double] Depth of the cavity (in)
  # @param corr_factor [Double] Parallel path correction factor per ASHRAE 90.1 to determine the effective thermal resistance of steel construction (frac)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  def initialize(cavity_depth_in, corr_factor, rigid_r, osb_thick_in, mat_int_finish, mat_ext_finish)
    @cavity_depth_in = cavity_depth_in
    @corr_factor = corr_factor
    @rigid_r = rigid_r
    @osb_thick_in = osb_thick_in
    @mat_int_finish = mat_int_finish
    @mat_ext_finish = mat_ext_finish
  end
  attr_accessor(:cavity_depth_in, :corr_factor, :rigid_r, :osb_thick_in, :mat_int_finish, :mat_ext_finish)
end

# Object with properties that describe a double wood stud construction
class DoubleStudConstructionSet
  # @param stud [Material] Material properties for the wood stud
  # @param framing_factor [Double] Fraction of total surface area comprised of structural framing and framing for windows/doors (frac)
  # @param framing_spacing [Double] Framing spacing on center (in)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  def initialize(stud, framing_factor, framing_spacing, rigid_r, osb_thick_in, mat_int_finish, mat_ext_finish)
    @stud = stud
    @framing_factor = framing_factor
    @framing_spacing = framing_spacing
    @rigid_r = rigid_r
    @osb_thick_in = osb_thick_in
    @mat_int_finish = mat_int_finish
    @mat_ext_finish = mat_ext_finish
  end
  attr_accessor(:stud, :framing_factor, :framing_spacing, :rigid_r, :osb_thick_in, :mat_int_finish, :mat_ext_finish)
end

# Object with properties that describe a structural insulated panel (SIP) construction
class SIPConstructionSet
  # @param ins_thick_in [Double] Thickness of the insulating core of the SIP (in)
  # @param framing_factor [Double] Fraction of total surface area comprised of framing for windows/doors (frac)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param sheath_thick_in [Double] Thickness of the interior sheathing (in)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  def initialize(ins_thick_in, framing_factor, rigid_r, sheath_thick_in, osb_thick_in, mat_int_finish, mat_ext_finish)
    @ins_thick_in = ins_thick_in
    @framing_factor = framing_factor
    @rigid_r = rigid_r
    @sheath_thick_in = sheath_thick_in
    @osb_thick_in = osb_thick_in
    @mat_int_finish = mat_int_finish
    @mat_ext_finish = mat_ext_finish
  end
  attr_accessor(:ins_thick_in, :framing_factor, :rigid_r, :sheath_thick_in, :osb_thick_in, :mat_int_finish, :mat_ext_finish)
end

# Object with properties that describe a concrete masonry unit (CMU) construction
class CMUConstructionSet
  # @param thick_in [Double] Thickness of the CMU (in)
  # @param conductivity_in [Double] Conductivity of the CMU (Btu-in/h-ft2-F)
  # @param framing_factor [Double] Fraction of total surface area comprised of framing for windows/doors (frac)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  def initialize(thick_in, conductivity_in, framing_factor, osb_thick_in, mat_int_finish, mat_ext_finish)
    @thick_in = thick_in
    @conductivity_in = conductivity_in
    @framing_factor = framing_factor
    @osb_thick_in = osb_thick_in
    @mat_int_finish = mat_int_finish
    @mat_ext_finish = mat_ext_finish
    @rigid_r = nil # solved for
  end
  attr_accessor(:thick_in, :conductivity_in, :framing_factor, :rigid_r, :osb_thick_in, :mat_int_finish, :mat_ext_finish)
end

# Object with properties that describe an insulated concrete form (ICF) construction
class ICFConstructionSet
  # @param ins_thick_in [Double] Thickness of each insulation layer (in)
  # @param concrete_thick_in [Double] Thickness of the concrete form (in)
  # @param framing_factor [Double] Fraction of total surface area comprised of framing for windows/doors (frac)
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  def initialize(ins_thick_in, concrete_thick_in, framing_factor, rigid_r, osb_thick_in, mat_int_finish, mat_ext_finish)
    @ins_thick_in = ins_thick_in
    @concrete_thick_in = concrete_thick_in
    @framing_factor = framing_factor
    @rigid_r = rigid_r
    @osb_thick_in = osb_thick_in
    @mat_int_finish = mat_int_finish
    @mat_ext_finish = mat_ext_finish
  end
  attr_accessor(:ins_thick_in, :concrete_thick_in, :framing_factor, :rigid_r, :osb_thick_in, :mat_int_finish, :mat_ext_finish)
end

# Object with properties that describe a generic layer-by-layer construction
class GenericConstructionSet
  # @param rigid_r [Double] R-value of the continuous insulation (hr-ft2-F/Btu)
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @param mat_int_finish [Material] Material properties for the interior finish (e.g., drywall)
  # @param mat_ext_finish [Material] Material properties for the exterior finish (e.g., siding)
  def initialize(rigid_r, osb_thick_in, mat_int_finish, mat_ext_finish)
    @rigid_r = rigid_r
    @osb_thick_in = osb_thick_in
    @mat_int_finish = mat_int_finish
    @mat_ext_finish = mat_ext_finish
  end
  attr_accessor(:rigid_r, :osb_thick_in, :mat_int_finish, :mat_ext_finish)
end
