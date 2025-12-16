# frozen_string_literal: true

# Collection of methods related to geometry.
module Geometry
  # Adds any HPXML Roofs to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply_roofs(runner, model, spaces, hpxml_bldg, hpxml_header)
    default_azimuths = Defaults.get_azimuths(hpxml_bldg)
    walls_top = hpxml_bldg.building_construction.additional_properties.walls_height_above_grade

    hpxml_bldg.roofs.each do |roof|
      next if roof.net_area < 1.0 # skip modeling net surface area for surfaces comprised entirely of subsurface area

      if roof.azimuth.nil?
        if roof.pitch > 0
          azimuths = default_azimuths # Model as four directions for average exterior incident solar
        else
          azimuths = [default_azimuths[0]] # Arbitrary azimuth for flat roof
        end
      else
        azimuths = [roof.azimuth]
      end

      surfaces = []

      azimuths.each do |azimuth|
        width = Math::sqrt(roof.net_area)
        length = (roof.net_area / width) / azimuths.size
        tilt = roof.pitch / 12.0
        z_origin = walls_top + 0.5 * Math.sin(Math.atan(tilt)) * width

        vertices = create_roof_vertices(length, width, z_origin, azimuth, tilt)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surfaces << surface
        surface.additionalProperties.setFeature('Length', length)
        surface.additionalProperties.setFeature('Width', width)
        surface.additionalProperties.setFeature('Azimuth', azimuth)
        surface.additionalProperties.setFeature('Tilt', tilt)
        surface.additionalProperties.setFeature('SurfaceType', 'Roof')
        if azimuths.size > 1
          surface.setName("#{roof.id}:#{azimuth}")
        else
          surface.setName(roof.id)
        end
        surface.setSurfaceType(EPlus::SurfaceTypeRoofCeiling)
        surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)
        set_surface_interior(model, spaces, surface, roof, hpxml_bldg)
      end

      next if surfaces.empty?

      # Apply construction
      has_radiant_barrier = roof.radiant_barrier
      if has_radiant_barrier
        radiant_barrier_grade = roof.radiant_barrier_grade
      end
      # FUTURE: Create Constructions.get_air_film(surface) method; use in measure.rb and hpxml_translator_test.rb
      interior_film = Material.AirFilmIndoorRoof(UnitConversions.convert(surfaces[0].tilt, 'rad', 'deg'), hpxml_header.apply_ashrae140_assumptions)
      exterior_film = Material.AirFilmOutside(false, hpxml_header.apply_ashrae140_assumptions)
      mat_roofing = Material.RoofMaterial(roof.roof_type)
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
          WoodStudConstructionSet.new(Material.Stud2x(8), 0.07, 20.0, 0.625, mat_int_finish, mat_roofing),    # 2x8, 24" o.c. + R20
          WoodStudConstructionSet.new(Material.Stud2x(8), 0.07, 10.0, 0.625, mat_int_finish, mat_roofing),    # 2x8, 24" o.c. + R10
          WoodStudConstructionSet.new(Material.Stud2x(8), 0.07, 0.0, 0.625, mat_int_finish, mat_roofing),     # 2x8, 24" o.c.
          WoodStudConstructionSet.new(Material.Stud2x(6), 0.07, 0.0, 0.625, mat_int_finish, mat_roofing), # 2x6, 24" o.c.
          WoodStudConstructionSet.new(Material.Stud2x(4), 0.07, 0.0, 0.5, mat_int_finish, mat_roofing),          # 2x4, 16" o.c.
          WoodStudConstructionSet.new(Material.Stud2x(4), 0.01, 0.0, 0.0, fallback_mat_int_finish, mat_roofing), # Fallback
        ]
        match, constr_set, cavity_r = Constructions.pick_wood_stud_construction_set(assembly_r, constr_sets, interior_film, exterior_film)

        Constructions.apply_closed_cavity_roof(model, surfaces, "#{roof.id} construction",
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
          GenericConstructionSet.new(10.0, 0.625, nil, mat_roofing), # w/R-10 rigid
          GenericConstructionSet.new(0.0, 0.625, nil, mat_roofing),  # Standard
        ]
        match, constr_set, layer_r = Constructions.pick_generic_construction_set(assembly_r, constr_sets, interior_film, exterior_film)

        cavity_r = 0
        cavity_ins_thick_in = 0
        framing_factor = 0
        framing_thick_in = 0

        Constructions.apply_open_cavity_roof(model, surfaces, "#{roof.id} construction",
                                             cavity_r, install_grade, cavity_ins_thick_in,
                                             framing_factor, framing_thick_in,
                                             constr_set.osb_thick_in, layer_r + constr_set.rigid_r,
                                             constr_set.mat_ext_finish, has_radiant_barrier,
                                             interior_film, exterior_film, radiant_barrier_grade,
                                             roof.solar_absorptance, roof.emittance)
      end
      Constructions.check_surface_assembly_rvalue(runner, surfaces, interior_film, exterior_film, assembly_r, match)
    end
  end

  # Adds any HPXML Walls to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply_walls(runner, model, spaces, hpxml_bldg, hpxml_header)
    default_azimuths = Defaults.get_azimuths(hpxml_bldg)
    foundation_top = hpxml_bldg.building_construction.additional_properties.foundation_height_above_grade

    hpxml_bldg.walls.each do |wall|
      next if wall.sameas_id && hpxml_header.whole_sfa_or_mf_building_sim
      next if wall.net_area < 1.0 # skip modeling net surface area for surfaces comprised entirely of subsurface area

      if wall.azimuth.nil?
        if wall.is_exterior
          azimuths = default_azimuths # Model as four directions for average exterior incident solar
        else
          azimuths = [default_azimuths[0]] # Arbitrary direction, doesn't receive exterior incident solar
        end
      else
        azimuths = [wall.azimuth]
      end

      surfaces = []

      azimuths.each do |azimuth|
        height = 8.0 * hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade
        length = (wall.net_area / height) / azimuths.size
        z_origin = foundation_top

        vertices = create_wall_vertices(length, height, z_origin, azimuth)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surfaces << surface
        surface.additionalProperties.setFeature('Length', length)
        surface.additionalProperties.setFeature('Azimuth', azimuth)
        surface.additionalProperties.setFeature('Tilt', 90.0)
        surface.additionalProperties.setFeature('SurfaceType', 'Wall')
        if azimuths.size > 1
          surface.setName("#{wall.id}:#{azimuth}")
        else
          surface.setName(wall.id)
        end
        surface.setSurfaceType(EPlus::SurfaceTypeWall)
        set_surface_interior(model, spaces, surface, wall, hpxml_bldg)
        set_surface_exterior(model, spaces, surface, wall, hpxml_bldg, hpxml_header)
        if wall.is_interior
          surface.setSunExposure(EPlus::SurfaceSunExposureNo)
          surface.setWindExposure(EPlus::SurfaceWindExposureNo)
        end
        next unless hpxml_header.whole_sfa_or_mf_building_sim && wall.additional_properties.respond_to?(:adjacent_hpxml_id)

        surface.additionalProperties.setFeature('adjacentHpxmlID', wall.additional_properties.adjacent_hpxml_id)
        surface.additionalProperties.setFeature('adjacentUnitNumber', wall.additional_properties.adjacent_unit_number)
        surface.additionalProperties.setFeature('adjacentSpaceType', wall.additional_properties.adjacent_space_type)
      end

      next if surfaces.empty?

      # Apply construction
      # The code below constructs a reasonable wall construction based on the
      # wall type while ensuring the correct assembly R-value.
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

      Constructions.apply_wall_construction(runner, model, surfaces, wall.id, wall.wall_type, wall.insulation_assembly_r_value,
                                            mat_int_finish, has_radiant_barrier, interior_film, exterior_film,
                                            radiant_barrier_grade, mat_ext_finish, wall.solar_absorptance,
                                            wall.emittance)
    end
  end

  # Adds any HPXML RimJoists to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply_rim_joists(runner, model, spaces, hpxml_bldg, hpxml_header)
    default_azimuths = Defaults.get_azimuths(hpxml_bldg)
    foundation_top = hpxml_bldg.building_construction.additional_properties.foundation_height_above_grade

    hpxml_bldg.rim_joists.each do |rim_joist|
      next if rim_joist.sameas_id && hpxml_header.whole_sfa_or_mf_building_sim

      if rim_joist.azimuth.nil?
        if rim_joist.is_exterior
          azimuths = default_azimuths # Model as four directions for average exterior incident solar
        else
          azimuths = [default_azimuths[0]] # Arbitrary direction, doesn't receive exterior incident solar
        end
      else
        azimuths = [rim_joist.azimuth]
      end

      surfaces = []

      azimuths.each do |azimuth|
        height = 1.0
        length = (rim_joist.area / height) / azimuths.size
        z_origin = foundation_top

        vertices = create_wall_vertices(length, height, z_origin, azimuth)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surfaces << surface
        surface.additionalProperties.setFeature('Length', length)
        surface.additionalProperties.setFeature('Azimuth', azimuth)
        surface.additionalProperties.setFeature('Tilt', 90.0)
        surface.additionalProperties.setFeature('SurfaceType', 'RimJoist')
        if azimuths.size > 1
          surface.setName("#{rim_joist.id}:#{azimuth}")
        else
          surface.setName(rim_joist.id)
        end
        surface.setSurfaceType(EPlus::SurfaceTypeWall)
        set_surface_interior(model, spaces, surface, rim_joist, hpxml_bldg)
        set_surface_exterior(model, spaces, surface, rim_joist, hpxml_bldg, hpxml_header)
        if rim_joist.is_interior
          surface.setSunExposure(EPlus::SurfaceSunExposureNo)
          surface.setWindExposure(EPlus::SurfaceWindExposureNo)
        end
        next unless hpxml_header.whole_sfa_or_mf_building_sim && rim_joist.additional_properties.respond_to?(:adjacent_hpxml_id)

        surface.additionalProperties.setFeature('adjacentHpxmlID', rim_joist.additional_properties.adjacent_hpxml_id)
        surface.additionalProperties.setFeature('adjacentUnitNumber', rim_joist.additional_properties.adjacent_unit_number)
        surface.additionalProperties.setFeature('adjacentSpaceType', rim_joist.additional_properties.adjacent_space_type)
      end

      # Apply construction

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
      match, constr_set, cavity_r = Constructions.pick_wood_stud_construction_set(assembly_r, constr_sets, interior_film, exterior_film)
      install_grade = 1

      Constructions.apply_rim_joist(model, surfaces, "#{rim_joist.id} construction", cavity_r,
                                    install_grade, constr_set.stud.thick_in, constr_set.framing_factor,
                                    constr_set.mat_int_finish, constr_set.osb_thick_in,
                                    constr_set.rigid_r, constr_set.mat_ext_finish,
                                    interior_film, exterior_film, rim_joist.solar_absorptance,
                                    rim_joist.emittance)
      Constructions.check_surface_assembly_rvalue(runner, surfaces, interior_film, exterior_film, assembly_r, match)
    end
  end

  # Adds any HPXML Floors to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply_floors(runner, model, spaces, hpxml_bldg, hpxml_header)
    default_azimuths = Defaults.get_azimuths(hpxml_bldg)
    walls_top = hpxml_bldg.building_construction.additional_properties.walls_height_above_grade
    foundation_top = hpxml_bldg.building_construction.additional_properties.foundation_height_above_grade

    hpxml_bldg.floors.each do |floor|
      next if floor.sameas_id && hpxml_header.whole_sfa_or_mf_building_sim
      next if floor.net_area < 1.0 # skip modeling net surface area for surfaces comprised entirely of subsurface area

      area = floor.net_area
      width = Math::sqrt(area)
      length = area / width
      if floor.interior_adjacent_to.include?('attic') || floor.exterior_adjacent_to.include?('attic')
        z_origin = walls_top
      else
        z_origin = foundation_top
      end

      if floor.is_ceiling
        vertices = create_ceiling_vertices(length, width, z_origin, default_azimuths)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surface.additionalProperties.setFeature('SurfaceType', 'Ceiling')
      else
        vertices = create_floor_vertices(length, width, z_origin, default_azimuths)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surface.additionalProperties.setFeature('SurfaceType', 'Floor')
      end
      surface.additionalProperties.setFeature('Tilt', 0.0)
      set_surface_interior(model, spaces, surface, floor, hpxml_bldg)
      set_surface_exterior(model, spaces, surface, floor, hpxml_bldg, hpxml_header)
      surface.setName(floor.id)
      if floor.is_interior
        surface.setSunExposure(EPlus::SurfaceSunExposureNo)
        surface.setWindExposure(EPlus::SurfaceWindExposureNo)
      elsif floor.is_floor
        surface.setSunExposure(EPlus::SurfaceSunExposureNo)
        if floor.exterior_adjacent_to == HPXML::LocationManufacturedHomeUnderBelly
          foundation = hpxml_bldg.foundations.find { |x| x.to_location == floor.exterior_adjacent_to }
          if foundation.belly_wing_skirt_present
            zero_wind = true
            surface.setWindExposure(EPlus::SurfaceWindExposureNo)
          end
        end
        if floor.is_exterior && hpxml_header.apply_ashrae140_assumptions
          zero_wind = true
          surface.setWindExposure(EPlus::SurfaceWindExposureNo)
        end
      end
      if hpxml_header.whole_sfa_or_mf_building_sim && floor.additional_properties.respond_to?(:adjacent_hpxml_id)
        surface.additionalProperties.setFeature('adjacentHpxmlID', floor.additional_properties.adjacent_hpxml_id)
        surface.additionalProperties.setFeature('adjacentUnitNumber', floor.additional_properties.adjacent_unit_number)
        surface.additionalProperties.setFeature('adjacentSpaceType', floor.additional_properties.adjacent_space_type)
      end

      # Apply construction

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

      Constructions.apply_floor_ceiling_construction(runner, model, [surface], floor.id, floor.floor_type, floor.is_ceiling, floor.insulation_assembly_r_value,
                                                     mat_int_finish_or_covering, has_radiant_barrier, interior_film, exterior_film, radiant_barrier_grade)
    end
  end

  # Adds any HPXML Foundation Walls and Slabs to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_foundation_walls_slabs(runner, model, spaces, weather, hpxml_bldg, hpxml_header, schedules_file)
    default_azimuths = Defaults.get_azimuths(hpxml_bldg)

    foundation_types = hpxml_bldg.slabs.map { |s| s.interior_adjacent_to }.uniq
    foundation_types.each do |foundation_type|
      # Get attached slabs/foundation walls
      slabs = []
      hpxml_bldg.slabs.each do |slab|
        next unless slab.interior_adjacent_to == foundation_type

        slabs << slab
        slab.exposed_perimeter = [slab.exposed_perimeter, 1.0].max # minimum value to prevent error if no exposed slab
      end

      slabs.each do |slab|
        slab_frac = slab.exposed_perimeter / slabs.map { |s| s.exposed_perimeter }.sum
        ext_fnd_walls = slab.connected_foundation_walls.select { |fw| fw.net_area >= 1.0 && fw.is_exterior }

        if ext_fnd_walls.empty?
          # Slab w/o foundation walls
          apply_foundation_slab(model, weather, spaces, hpxml_bldg, hpxml_header, slab, -1 * slab.depth_below_grade.to_f, slab.exposed_perimeter, nil, default_azimuths, schedules_file)
        else
          # Slab w/ foundation walls
          ext_fnd_walls_length = ext_fnd_walls.map { |fw| fw.area / fw.height }.sum
          remaining_exposed_length = slab.exposed_perimeter

          # Since we don't know which FoundationWalls are adjacent to which Slabs, we apportion
          # each FoundationWall to each slab.
          ext_fnd_walls.each do |fnd_wall|
            # Both the foundation wall and slab must have same exposed length to prevent Kiva errors.
            # For the foundation wall, we are effectively modeling the net *exposed* area.
            fnd_wall_length = fnd_wall.area / fnd_wall.height
            apportioned_exposed_length = fnd_wall_length / ext_fnd_walls_length * slab.exposed_perimeter # Slab exposed perimeter apportioned to this foundation wall
            apportioned_total_length = fnd_wall_length * slab_frac # Foundation wall length apportioned to this slab
            exposed_length = [apportioned_exposed_length, apportioned_total_length].min
            remaining_exposed_length -= exposed_length

            kiva_foundation = apply_foundation_wall(runner, model, spaces, hpxml_bldg, hpxml_header, fnd_wall, exposed_length, fnd_wall_length, default_azimuths)
            apply_foundation_slab(model, weather, spaces, hpxml_bldg, hpxml_header, slab, -1 * fnd_wall.depth_below_grade, exposed_length, kiva_foundation, default_azimuths, schedules_file)
          end

          if remaining_exposed_length > 1 # Skip if a small length (e.g., due to rounding)
            # The slab's exposed perimeter exceeds the sum of attached exterior foundation wall lengths.
            # This may legitimately occur for a walkout basement, where a portion of the slab has no
            # adjacent foundation wall.
            apply_foundation_slab(model, weather, spaces, hpxml_bldg, hpxml_header, slab, 0, remaining_exposed_length, nil, default_azimuths, schedules_file)
          end
        end
      end

      # Interzonal foundation wall surfaces
      # The above-grade portion of these walls are modeled as EnergyPlus surfaces with standard adjacency.
      # The below-grade portion of these walls (in contact with ground) are not modeled, as Kiva does not
      # calculate heat flow between two zones through the ground.
      hpxml_bldg.foundation_walls.each do |fnd_wall|
        next if fnd_wall.sameas_id && hpxml_header.whole_sfa_or_mf_building_sim
        next unless fnd_wall.is_interior
        next if fnd_wall.interior_adjacent_to != foundation_type

        ag_height = fnd_wall.height - fnd_wall.depth_below_grade
        ag_net_area = fnd_wall.net_area * ag_height / fnd_wall.height
        next if ag_net_area < 1.0

        length = ag_net_area / ag_height
        z_origin = -1 * ag_height
        if fnd_wall.azimuth.nil?
          azimuth = default_azimuths[0] # Arbitrary direction, doesn't receive exterior incident solar
        else
          azimuth = fnd_wall.azimuth
        end

        vertices = create_wall_vertices(length, ag_height, z_origin, azimuth)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surface.additionalProperties.setFeature('Length', length)
        surface.additionalProperties.setFeature('Azimuth', azimuth)
        surface.additionalProperties.setFeature('Tilt', 90.0)
        surface.additionalProperties.setFeature('SurfaceType', 'FoundationWall')
        surface.setName(fnd_wall.id)
        surface.setSurfaceType(EPlus::SurfaceTypeWall)
        set_surface_interior(model, spaces, surface, fnd_wall, hpxml_bldg)
        set_surface_exterior(model, spaces, surface, fnd_wall, hpxml_bldg, hpxml_header)
        surface.setSunExposure(EPlus::SurfaceSunExposureNo)
        surface.setWindExposure(EPlus::SurfaceWindExposureNo)
        if hpxml_header.whole_sfa_or_mf_building_sim && fnd_wall.additional_properties.respond_to?(:adjacent_hpxml_id)
          surface.additionalProperties.setFeature('adjacentHpxmlID', fnd_wall.additional_properties.adjacent_hpxml_id)
          surface.additionalProperties.setFeature('adjacentUnitNumber', fnd_wall.additional_properties.adjacent_unit_number)
          surface.additionalProperties.setFeature('adjacentSpaceType', fnd_wall.additional_properties.adjacent_space_type)
        end

        # Apply construction

        wall_type = HPXML::WallTypeConcrete
        interior_film = Material.AirFilmIndoorWall
        exterior_film = Material.AirFilmIndoorWall
        assembly_r = fnd_wall.insulation_assembly_r_value
        mat_int_finish = Material.InteriorFinishMaterial(fnd_wall.interior_finish_type, fnd_wall.interior_finish_thickness)
        if assembly_r.nil?
          concrete_thick_in = fnd_wall.thickness
          int_r = fnd_wall.insulation_interior_r_value
          ext_r = fnd_wall.insulation_exterior_r_value
          mat_concrete = Material.Concrete(concrete_thick_in)
          mat_int_finish_rvalue = mat_int_finish.nil? ? 0.0 : mat_int_finish.rvalue
          assembly_r = int_r + ext_r + mat_concrete.rvalue + mat_int_finish_rvalue + interior_film.rvalue + exterior_film.rvalue
        end
        mat_ext_finish = nil

        Constructions.apply_wall_construction(runner, model, [surface], fnd_wall.id, wall_type, assembly_r, mat_int_finish,
                                              false, interior_film, exterior_film, nil, mat_ext_finish, nil, nil)
      end
    end
  end

  # Adds an HPXML Foundation Wall to the OpenStudio model.
  #
  # Note: Since we don't know which FoundationWalls are adjacent to which Slabs, we may call this method multiple times
  # for the same HPXML Foundation Wall, each time with a different exposed_length and fnd_wall_length, specific to an
  # adjacent HPXML Slab.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param foundation_wall [HPXML::FoundationWall] The HPXML foundation wall of interest
  # @param exposed_length [Double] Length of foundation wall exposed to ambient conditions, specific to an associated HPXML Slab (ft)
  # @param fnd_wall_length [Double] The total length of the foundation wall (ft)
  # @param default_azimuths [Array<Double>] Default azimuths for the four sides of the home, used for surfaces without an orientation
  # @return [OpenStudio::Model::FoundationKiva] OpenStudio Foundation Kiva object
  def self.apply_foundation_wall(runner, model, spaces, hpxml_bldg, hpxml_header, foundation_wall, exposed_length, fnd_wall_length, default_azimuths)
    exposed_fraction = exposed_length / fnd_wall_length
    net_exposed_area = foundation_wall.net_area * exposed_fraction
    gross_exposed_area = foundation_wall.area * exposed_fraction
    height = foundation_wall.height
    height_ag = height - foundation_wall.depth_below_grade
    z_origin = -1 * foundation_wall.depth_below_grade
    if foundation_wall.azimuth.nil?
      azimuth = default_azimuths[0] # Arbitrary; solar incidence in Kiva is applied as an orientation average (to the above grade portion of the wall)
    else
      azimuth = foundation_wall.azimuth
    end

    return if exposed_length < 0.1 # Avoid Kiva error if exposed wall length is too small

    if gross_exposed_area > net_exposed_area
      # Create a "notch" in the wall to account for the subsurfaces. This ensures that
      # we preserve the appropriate wall height, length, and area for Kiva.
      subsurface_area = gross_exposed_area - net_exposed_area
    else
      subsurface_area = 0
    end

    vertices = create_wall_vertices(exposed_length, height, z_origin, azimuth, subsurface_area: subsurface_area)
    surface = OpenStudio::Model::Surface.new(vertices, model)
    surface.additionalProperties.setFeature('Length', exposed_length)
    surface.additionalProperties.setFeature('Azimuth', azimuth)
    surface.additionalProperties.setFeature('Tilt', 90.0)
    surface.additionalProperties.setFeature('SurfaceType', 'FoundationWall')
    surface.setName(foundation_wall.id)
    surface.setSurfaceType(EPlus::SurfaceTypeWall)
    set_surface_interior(model, spaces, surface, foundation_wall, hpxml_bldg)
    set_surface_exterior(model, spaces, surface, foundation_wall, hpxml_bldg, hpxml_header)

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

    Constructions.apply_foundation_wall(model, [surface], "#{foundation_wall.id} construction",
                                        ext_rigid_offset, int_rigid_offset, ext_rigid_height, int_rigid_height,
                                        ext_rigid_r, int_rigid_r, mat_int_finish, mat_wall, height_ag,
                                        soil_k_in)

    if not assembly_r.nil?
      Constructions.check_surface_assembly_rvalue(runner, [surface], interior_film, nil, assembly_r, match)
    end

    return surface.adjacentFoundation.get
  end

  # Adds an HPXML Slab to the OpenStudio model.
  #
  # Note: Since we don't know which FoundationWalls are adjacent to which Slabs, we may call this method multiple times
  # for the same HPXML Slab, each time with a different exposed_length, specific to an adjacent HPXML FoundationWall.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @param slab [HPXML::Slab] The HPXML slab of interest
  # @param z_origin [Double] The z-coordinate for which the slab is relative (ft)
  # @param exposed_length [Double] Length of foundation wall exposed to ambient conditions, specific to an associated HPXML Slab (ft)
  # @param kiva_foundation [OpenStudio::Model::FoundationKiva] OpenStudio Foundation Kiva object
  # @param default_azimuths [Array<Double>] Default azimuths for the four sides of the home, used for surfaces without an orientation
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [OpenStudio::Model::FoundationKiva] OpenStudio Foundation Kiva object
  def self.apply_foundation_slab(model, weather, spaces, hpxml_bldg, hpxml_header, slab, z_origin,
                                 exposed_length, kiva_foundation, default_azimuths, schedules_file)
    exposed_fraction = exposed_length / slab.exposed_perimeter
    slab_tot_perim = exposed_length
    slab_area = slab.area * exposed_fraction
    if slab_tot_perim**2 - 16.0 * slab_area <= 0
      # Cannot construct rectangle with this perimeter/area. Some of the
      # perimeter is presumably not exposed, so bump up perimeter value.
      slab_tot_perim = Math.sqrt(16.0 * slab_area)
    end
    sqrt_term = [slab_tot_perim**2 - 16.0 * slab_area, 0.0].max
    slab_length = slab_tot_perim / 4.0 + Math.sqrt(sqrt_term) / 4.0
    slab_width = slab_tot_perim / 4.0 - Math.sqrt(sqrt_term) / 4.0

    vertices = create_floor_vertices(slab_length, slab_width, z_origin, default_azimuths)
    surface = OpenStudio::Model::Surface.new(vertices, model)
    surface.setName(slab.id)
    surface.setSurfaceType(EPlus::SurfaceTypeFloor)
    surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionFoundation)
    surface.additionalProperties.setFeature('SurfaceType', 'Slab')
    set_surface_interior(model, spaces, surface, slab, hpxml_bldg)
    surface.setSunExposure(EPlus::SurfaceSunExposureNo)
    surface.setWindExposure(EPlus::SurfaceWindExposureNo)

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

    Constructions.apply_foundation_slab(model, surface, "#{slab.id} construction",
                                        slab_under_r, slab_under_width, slab_gap_r, slab_perim_r,
                                        slab_perim_depth, slab_whole_r, slab.thickness,
                                        exposed_length, mat_carpet, soil_k_in, kiva_foundation,
                                        ext_horiz_r, ext_horiz_width, ext_horiz_depth)

    kiva_foundation = surface.adjacentFoundation.get

    Constructions.apply_kiva_initial_temperature(kiva_foundation, weather, hpxml_bldg, hpxml_header,
                                                 spaces, schedules_file, slab.interior_adjacent_to)

    return kiva_foundation
  end

  # Adds any HPXML Windows to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply_windows(runner, model, spaces, hpxml_bldg, hpxml_header)
    # We already stored @fraction_of_windows_operable, so lets remove the
    # fraction_operable properties from windows and re-collapse the enclosure
    # so as to prevent potentially modeling multiple identical windows in E+,
    # which can increase simulation runtime.
    hpxml_bldg.windows.each do |window|
      window.fraction_operable = nil
    end
    hpxml_bldg.collapse_enclosure_surfaces()

    foundation_top = hpxml_bldg.building_construction.additional_properties.foundation_height_above_grade

    shading_schedules = {}

    surfaces = []
    hpxml_bldg.windows.each do |window|
      window_height = 4.0 # ft, default

      overhang_depth = nil
      if (not window.overhangs_depth.nil?) && (window.overhangs_depth > 0)
        overhang_depth = window.overhangs_depth
        overhang_distance_to_top = window.overhangs_distance_to_top_of_window
        overhang_distance_to_bottom = window.overhangs_distance_to_bottom_of_window
        window_height = overhang_distance_to_bottom - overhang_distance_to_top
      end

      window_length = window.area / window_height
      z_origin = foundation_top

      ufactor, shgc = Constructions.get_ufactor_shgc_adjusted_by_storms(runner, window.storm_type, window.ufactor, window.shgc)

      if window.is_exterior

        # Create parent surface slightly bigger than window
        vertices = create_wall_vertices(window_length, window_height, z_origin, window.azimuth, add_buffer: true)
        surface = OpenStudio::Model::Surface.new(vertices, model)

        surface.additionalProperties.setFeature('Length', window_length)
        surface.additionalProperties.setFeature('Azimuth', window.azimuth)
        surface.additionalProperties.setFeature('Tilt', 90.0)
        surface.additionalProperties.setFeature('SurfaceType', 'Window')
        surface.setName("surface #{window.id}")
        surface.setSurfaceType(EPlus::SurfaceTypeWall)
        set_surface_interior(model, spaces, surface, window.wall, hpxml_bldg)

        vertices = create_wall_vertices(window_length, window_height, z_origin, window.azimuth)
        sub_surface = OpenStudio::Model::SubSurface.new(vertices, model)
        sub_surface.setName(window.id)
        sub_surface.setSurface(surface)
        sub_surface.setSubSurfaceType(EPlus::SubSurfaceTypeWindow)

        set_subsurface_exterior(surface, spaces, model, window.wall, hpxml_bldg, hpxml_header)
        surfaces << surface

        if not overhang_depth.nil?
          overhang = sub_surface.addOverhang(UnitConversions.convert(overhang_depth, 'ft', 'm'), UnitConversions.convert(overhang_distance_to_top, 'ft', 'm'))
          overhang.get.setName("#{sub_surface.name} overhangs")
        end

        # Apply construction
        Constructions.apply_window(model, sub_surface, 'WindowConstruction', ufactor, shgc)

        # Apply interior/exterior shading (as needed)
        Constructions.apply_window_skylight_shading(model, window, sub_surface, shading_schedules, hpxml_header, hpxml_bldg)
      else
        # Window is on an interior surface, which E+ does not allow. Model
        # as a door instead so that we can get the appropriate conduction
        # heat transfer; there is no solar gains anyway.

        # Create parent surface slightly bigger than window
        vertices = create_wall_vertices(window_length, window_height, z_origin, window.azimuth, add_buffer: true)
        surface = OpenStudio::Model::Surface.new(vertices, model)

        surface.additionalProperties.setFeature('Length', window_length)
        surface.additionalProperties.setFeature('Azimuth', window.azimuth)
        surface.additionalProperties.setFeature('Tilt', 90.0)
        surface.additionalProperties.setFeature('SurfaceType', 'Door')
        surface.setName("surface #{window.id}")
        surface.setSurfaceType(EPlus::SurfaceTypeWall)
        set_surface_interior(model, spaces, surface, window.wall, hpxml_bldg)

        vertices = create_wall_vertices(window_length, window_height, z_origin, window.azimuth)
        sub_surface = OpenStudio::Model::SubSurface.new(vertices, model)
        sub_surface.setName(window.id)
        sub_surface.setSurface(surface)
        sub_surface.setSubSurfaceType(EPlus::SubSurfaceTypeDoor)

        set_subsurface_exterior(surface, spaces, model, window.wall, hpxml_bldg, hpxml_header)
        surfaces << surface

        # Apply construction
        interior_film = Material.AirFilmIndoorWall
        exterior_film = Material.AirFilmIndoorWall
        Constructions.apply_door(model, [sub_surface], 'Window', ufactor, interior_film, exterior_film)
      end
    end

    Constructions.apply_adiabatic_construction(model, surfaces, 'wall')
  end

  # Adds any HPXML Doors to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply_doors(model, spaces, hpxml_bldg, hpxml_header)
    foundation_top = hpxml_bldg.building_construction.additional_properties.foundation_height_above_grade

    surfaces = []
    hpxml_bldg.doors.each do |door|
      door_height = 6.67 # ft
      door_length = door.area / door_height
      z_origin = foundation_top

      # Create parent surface slightly bigger than door
      vertices = create_wall_vertices(door_length, door_height, z_origin, door.azimuth, add_buffer: true)
      surface = OpenStudio::Model::Surface.new(vertices, model)

      surface.additionalProperties.setFeature('Length', door_length)
      surface.additionalProperties.setFeature('Azimuth', door.azimuth)
      surface.additionalProperties.setFeature('Tilt', 90.0)
      surface.additionalProperties.setFeature('SurfaceType', 'Door')
      surface.setName("surface #{door.id}")
      surface.setSurfaceType(EPlus::SurfaceTypeWall)
      set_surface_interior(model, spaces, surface, door.wall, hpxml_bldg)

      vertices = create_wall_vertices(door_length, door_height, z_origin, door.azimuth)
      sub_surface = OpenStudio::Model::SubSurface.new(vertices, model)
      sub_surface.setName(door.id)
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType(EPlus::SubSurfaceTypeDoor)

      set_subsurface_exterior(surface, spaces, model, door.wall, hpxml_bldg, hpxml_header)
      surfaces << surface

      # Apply construction
      ufactor = 1.0 / door.r_value
      interior_film = Material.AirFilmIndoorWall
      if door.wall.is_exterior
        exterior_film = Material.AirFilmOutside
      else
        exterior_film = Material.AirFilmIndoorWall
      end
      Constructions.apply_door(model, [sub_surface], 'Door', ufactor, interior_film, exterior_film)
    end

    Constructions.apply_adiabatic_construction(model, surfaces, 'wall')
  end

  # Adds any HPXML Skylights to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply_skylights(runner, model, spaces, hpxml_bldg, hpxml_header)
    default_azimuths = Defaults.get_azimuths(hpxml_bldg)
    walls_top = hpxml_bldg.building_construction.additional_properties.walls_height_above_grade

    surfaces = []
    shading_schedules = {}

    hpxml_bldg.skylights.each do |skylight|
      if not skylight.is_conditioned
        fail "Skylight '#{skylight.id}' not connected to conditioned space; if it's a skylight with a shaft, use AttachedToFloor to connect it to conditioned space."
      end

      tilt = skylight.roof.pitch / 12.0
      width = Math::sqrt(skylight.area)
      length = skylight.area / width
      z_origin = walls_top + 0.5 * Math.sin(Math.atan(tilt)) * width

      ufactor, shgc = Constructions.get_ufactor_shgc_adjusted_by_storms(runner, skylight.storm_type, skylight.ufactor, skylight.shgc)

      if not skylight.curb_area.nil?
        # Create parent surface that includes curb heat transfer
        total_area = skylight.area + skylight.curb_area
        total_width = Math::sqrt(total_area)
        total_length = total_area / total_width
        vertices = create_roof_vertices(total_length, total_width, z_origin, skylight.azimuth, tilt, add_buffer: true)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surface.additionalProperties.setFeature('Length', total_length)
        surface.additionalProperties.setFeature('Width', total_width)

        # Assign curb construction
        curb_assembly_r = [skylight.curb_assembly_r_value - Material.AirFilmIndoorWall.rvalue - Material.AirFilmOutside.rvalue, 0.1].max
        curb_mat = Model.add_massless_material(
          model,
          name: 'SkylightCurbMaterial',
          rvalue: UnitConversions.convert(curb_assembly_r, 'hr*ft^2*f/btu', 'm^2*k/w')
        )
        curb_const = Model.add_construction(
          model,
          name: 'SkylightCurbConstruction',
          layers: [curb_mat]
        )
        surface.setConstruction(curb_const)
      else
        # Create parent surface slightly bigger than skylight
        vertices = create_roof_vertices(length, width, z_origin, skylight.azimuth, tilt, add_buffer: true)
        surface = OpenStudio::Model::Surface.new(vertices, model)
        surface.additionalProperties.setFeature('Length', length)
        surface.additionalProperties.setFeature('Width', width)
        surfaces << surface # Add to surfaces list so it's assigned an adiabatic construction
      end
      surface.additionalProperties.setFeature('Azimuth', skylight.azimuth)
      surface.additionalProperties.setFeature('Tilt', tilt)
      surface.additionalProperties.setFeature('SurfaceType', 'Skylight')
      surface.setName("surface #{skylight.id}")
      surface.setSurfaceType(EPlus::SurfaceTypeRoofCeiling)
      surface.setSpace(create_or_get_space(model, spaces, HPXML::LocationConditionedSpace, hpxml_bldg))
      surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors) # cannot be adiabatic because subsurfaces won't be created

      vertices = create_roof_vertices(length, width, z_origin, skylight.azimuth, tilt)
      sub_surface = OpenStudio::Model::SubSurface.new(vertices, model)
      sub_surface.setName(skylight.id)
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType('Skylight')

      # Apply construction
      Constructions.apply_skylight(model, sub_surface, 'SkylightConstruction', ufactor, shgc)

      # Apply interior/exterior shading (as needed)
      Constructions.apply_window_skylight_shading(model, skylight, sub_surface, shading_schedules, hpxml_header, hpxml_bldg)

      next unless (not skylight.shaft_area.nil?) && (not skylight.floor.nil?)

      # Add skylight shaft heat transfer, similar to attic knee walls

      shaft_height = Math::sqrt(skylight.shaft_area)
      shaft_width = skylight.shaft_area / shaft_height
      shaft_azimuth = default_azimuths[0] # Arbitrary direction, doesn't receive exterior incident solar
      shaft_z_origin = walls_top - shaft_height

      vertices = create_wall_vertices(shaft_width, shaft_height, shaft_z_origin, shaft_azimuth)
      surface = OpenStudio::Model::Surface.new(vertices, model)
      surface.additionalProperties.setFeature('Length', shaft_width)
      surface.additionalProperties.setFeature('Width', shaft_height)
      surface.additionalProperties.setFeature('Azimuth', shaft_azimuth)
      surface.additionalProperties.setFeature('Tilt', 90.0)
      surface.additionalProperties.setFeature('SurfaceType', 'Skylight')
      surface.setName("surface #{skylight.id} shaft")
      surface.setSurfaceType(EPlus::SurfaceTypeWall)
      set_surface_interior(model, spaces, surface, skylight.floor, hpxml_bldg)
      set_surface_exterior(model, spaces, surface, skylight.floor, hpxml_bldg, hpxml_header)
      surface.setSunExposure(EPlus::SurfaceSunExposureNo)
      surface.setWindExposure(EPlus::SurfaceWindExposureNo)

      # Apply construction
      shaft_assembly_r = [skylight.shaft_assembly_r_value - 2 * Material.AirFilmIndoorWall.rvalue, 0.1].max
      shaft_mat = Model.add_massless_material(
        model,
        name: 'SkylightShaftMaterial',
        rvalue: UnitConversions.convert(shaft_assembly_r, 'hr*ft^2*f/btu', 'm^2*k/w')
      )
      shaft_const = Model.add_construction(
        model,
        name: 'SkylightShaftConstruction',
        layers: [shaft_mat]
      )
      surface.setConstruction(shaft_const)
    end

    Constructions.apply_adiabatic_construction(model, surfaces, 'roof')
  end

  # Check if we need to add floors between conditioned spaces (e.g., between first
  # and second story or conditioned basement ceiling).
  # This ensures that the E+ reported Conditioned Floor Area is correct.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_conditioned_floor_area(model, spaces, hpxml_bldg)
    default_azimuths = Defaults.get_azimuths(hpxml_bldg)
    foundation_top = hpxml_bldg.building_construction.additional_properties.foundation_height_above_grade

    sum_cfa = 0.0
    hpxml_bldg.floors.each do |floor|
      next unless floor.is_floor
      next unless [HPXML::LocationConditionedSpace, HPXML::LocationBasementConditioned].include?(floor.interior_adjacent_to) ||
                  [HPXML::LocationConditionedSpace, HPXML::LocationBasementConditioned].include?(floor.exterior_adjacent_to)

      sum_cfa += floor.area
    end
    hpxml_bldg.slabs.each do |slab|
      next unless [HPXML::LocationConditionedSpace, HPXML::LocationBasementConditioned].include? slab.interior_adjacent_to

      sum_cfa += slab.area
    end

    addtl_cfa = hpxml_bldg.building_construction.conditioned_floor_area - sum_cfa

    fail if addtl_cfa < -1.0 # Allow some rounding; EPvalidator.sch should prevent this

    return unless addtl_cfa > 1.0 # Allow some rounding

    floor_width = Math::sqrt(addtl_cfa)
    floor_length = addtl_cfa / floor_width
    z_origin = foundation_top + 8.0 * (hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade - 1)

    # Add floor surface
    vertices = create_floor_vertices(floor_length, floor_width, z_origin, default_azimuths)
    floor_surface = OpenStudio::Model::Surface.new(vertices, model)

    floor_surface.setSunExposure(EPlus::SurfaceSunExposureNo)
    floor_surface.setWindExposure(EPlus::SurfaceWindExposureNo)
    floor_surface.setName('inferred conditioned floor')
    floor_surface.setSurfaceType(EPlus::SurfaceTypeFloor)
    floor_surface.setSpace(create_or_get_space(model, spaces, HPXML::LocationConditionedSpace, hpxml_bldg))
    floor_surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionAdiabatic)
    floor_surface.additionalProperties.setFeature('SurfaceType', 'InferredFloor')
    floor_surface.additionalProperties.setFeature('Tilt', 0.0)

    # Add ceiling surface
    vertices = create_ceiling_vertices(floor_length, floor_width, z_origin, default_azimuths)
    ceiling_surface = OpenStudio::Model::Surface.new(vertices, model)

    ceiling_surface.setSunExposure(EPlus::SurfaceSunExposureNo)
    ceiling_surface.setWindExposure(EPlus::SurfaceWindExposureNo)
    ceiling_surface.setName('inferred conditioned ceiling')
    ceiling_surface.setSurfaceType(EPlus::SurfaceTypeRoofCeiling)
    ceiling_surface.setSpace(create_or_get_space(model, spaces, HPXML::LocationConditionedSpace, hpxml_bldg))
    ceiling_surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionAdiabatic)
    ceiling_surface.additionalProperties.setFeature('SurfaceType', 'InferredCeiling')
    ceiling_surface.additionalProperties.setFeature('Tilt', 0.0)

    # Apply Construction
    Constructions.apply_adiabatic_construction(model, [floor_surface, ceiling_surface], 'floor')
  end

  # Calls construction methods for applying partition walls and furniture to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply_thermal_mass(model, spaces, hpxml_bldg, hpxml_header)
    if hpxml_header.apply_ashrae140_assumptions
      # 1024 ft2 of interior partition wall mass, no furniture mass
      mat_int_finish = Material.InteriorFinishMaterial(HPXML::InteriorFinishGypsumBoard, 0.5)
      partition_wall_area = 1024.0 * 2 # Exposed partition wall area (both sides)
      Constructions.apply_partition_walls(model, 'PartitionWallConstruction', mat_int_finish, partition_wall_area, spaces)
    else
      mat_int_finish = Material.InteriorFinishMaterial(hpxml_bldg.partition_wall_mass.interior_finish_type, hpxml_bldg.partition_wall_mass.interior_finish_thickness)
      partition_wall_area = hpxml_bldg.partition_wall_mass.area_fraction * hpxml_bldg.building_construction.conditioned_floor_area # Exposed partition wall area (both sides)
      Constructions.apply_partition_walls(model, 'PartitionWallConstruction', mat_int_finish, partition_wall_area, spaces)

      Constructions.apply_furniture(model, hpxml_bldg.furniture_mass, spaces)
    end
  end

  # Assigns the assumed above-grade height of the top of the dwelling unit's walls and foundation walls.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply_foundation_and_walls_top(hpxml_bldg, hpxml_header)
    foundation_top = [hpxml_bldg.building_construction.unit_height_above_grade, 0].max
    hpxml_bldg.foundation_walls.each do |foundation_wall|
      next if foundation_wall.sameas_id && hpxml_header.whole_sfa_or_mf_building_sim

      top = -1 * foundation_wall.depth_below_grade + foundation_wall.height
      foundation_top = top if top > foundation_top
    end
    ncfl_ag = hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade
    walls_top = foundation_top + hpxml_bldg.building_construction.average_ceiling_height * ncfl_ag

    hpxml_bldg.building_construction.additional_properties.walls_height_above_grade = walls_top
    hpxml_bldg.building_construction.additional_properties.foundation_height_above_grade = foundation_top
  end

  # Get the default number of occupants.
  #
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [Double] Number of occupants in the dwelling unit
  def self.get_occupancy_default_num(nbeds)
    return Float(nbeds) # Per ANSI/RESNET/ICC 301 for an asset calculation
  end

  # Creates a space and zone based on contents of spaces and value of location.
  # Sets a "dwelling unit multiplier" equal to the number of similar units represented.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param location [String] The location of interest (HPXML::LocationXXX)
  # @param zone_multiplier [Integer] the number of similar zones represented
  # @return [OpenStudio::Model::Space, nil] updated spaces hash if location is not already a key
  def self.create_space_and_zone(model, spaces, location, zone_multiplier)
    if not spaces.keys.include? location
      thermal_zone = OpenStudio::Model::ThermalZone.new(model)
      thermal_zone.setName(location)
      thermal_zone.additionalProperties.setFeature('ObjectType', location)
      thermal_zone.setMultiplier(zone_multiplier)

      space = OpenStudio::Model::Space.new(model)
      space.setName(location)

      space.setThermalZone(thermal_zone)
      spaces[location] = space
    end
  end

  # Create vertices for a pitched horizontal plane based on length, height, z origin, azimuth, tilt, and presence of a buffer.
  #
  # @param length [Double] length of the roof (ft)
  # @param width [Double] width of the roof (ft)
  # @param z_origin [Double] The z-coordinate for which the length and height are relative (ft)
  # @param azimuth [Double] azimuth (degrees)
  # @param tilt [Double] ratio of vertical rise to horizontal run (frac)
  # @param add_buffer [Boolean] whether to use a buffer on each side of a subsurface
  # @return [OpenStudio::Point3dVector] an array of points
  def self.create_roof_vertices(length, width, z_origin, azimuth, tilt, add_buffer: false)
    length = UnitConversions.convert(length, 'ft', 'm')
    width = UnitConversions.convert(width, 'ft', 'm')
    z_origin = UnitConversions.convert(z_origin, 'ft', 'm')

    if add_buffer
      buffer = calculate_subsurface_parent_buffer(length, width)
      buffer /= 2.0 # Buffer on each side
    else
      buffer = 0
    end

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(length / 2 + buffer, -width / 2 - buffer, 0)
    vertices << OpenStudio::Point3d.new(length / 2 + buffer, width / 2 + buffer, 0)
    vertices << OpenStudio::Point3d.new(-length / 2 - buffer, width / 2 + buffer, 0)
    vertices << OpenStudio::Point3d.new(-length / 2 - buffer, -width / 2 - buffer, 0)

    # Rotate about the x axis
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0, 0] = 1
    m[1, 1] = Math::cos(Math::atan(tilt))
    m[1, 2] = -Math::sin(Math::atan(tilt))
    m[2, 1] = Math::sin(Math::atan(tilt))
    m[2, 2] = Math::cos(Math::atan(tilt))
    m[3, 3] = 1
    transformation = OpenStudio::Transformation.new(m)
    vertices = transformation * vertices

    # Rotate about the z axis
    azimuth_rad = UnitConversions.convert(azimuth, 'deg', 'rad')
    rad180 = UnitConversions.convert(180, 'deg', 'rad')
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0, 0] = Math::cos(rad180 - azimuth_rad)
    m[1, 1] = Math::cos(rad180 - azimuth_rad)
    m[0, 1] = -Math::sin(rad180 - azimuth_rad)
    m[1, 0] = Math::sin(rad180 - azimuth_rad)
    m[2, 2] = 1
    m[3, 3] = 1
    transformation = OpenStudio::Transformation.new(m)
    vertices = transformation * vertices

    # Shift up by z
    new_vertices = OpenStudio::Point3dVector.new
    vertices.each do |vertex|
      new_vertices << OpenStudio::Point3d.new(vertex.x, vertex.y, vertex.z + z_origin)
    end

    return new_vertices
  end

  # Create vertices for a vertical plane based on length, height, z origin, azimuth, presence of a buffer, and any subsurface area.
  #
  # @param length [Double] length of the wall (ft)
  # @param height [Double] height of the wall (ft)
  # @param z_origin [Double] The z-coordinate for which the length and height are relative (ft)
  # @param azimuth [Double] azimuth (degrees)
  # @param add_buffer [Boolean] whether to use a buffer on each side of a subsurface
  # @param subsurface_area [Double] the area of a subsurface within the parent surface (ft2)
  # @return [OpenStudio::Point3dVector] an array of points
  def self.create_wall_vertices(length, height, z_origin, azimuth, add_buffer: false, subsurface_area: 0)
    length = UnitConversions.convert(length, 'ft', 'm')
    height = UnitConversions.convert(height, 'ft', 'm')
    z_origin = UnitConversions.convert(z_origin, 'ft', 'm')

    if add_buffer
      buffer = calculate_subsurface_parent_buffer(length, height)
      buffer /= 2.0 # Buffer on each side
    else
      buffer = 0
    end

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(-length / 2 - buffer, 0, z_origin - buffer)
    vertices << OpenStudio::Point3d.new(-length / 2 - buffer, 0, z_origin + height + buffer)
    if subsurface_area > 0
      subsurface_area = UnitConversions.convert(subsurface_area, 'ft^2', 'm^2')
      sub_length = length / 10.0
      sub_height = subsurface_area / sub_length
      if sub_height >= height
        sub_height = height - 0.1
        sub_length = subsurface_area / sub_height
      end
      vertices << OpenStudio::Point3d.new(length / 2 - sub_length + buffer, 0, z_origin + height + buffer)
      vertices << OpenStudio::Point3d.new(length / 2 - sub_length + buffer, 0, z_origin + height - sub_height + buffer)
      vertices << OpenStudio::Point3d.new(length / 2 + buffer, 0, z_origin + height - sub_height + buffer)
    else
      vertices << OpenStudio::Point3d.new(length / 2 + buffer, 0, z_origin + height + buffer)
    end
    vertices << OpenStudio::Point3d.new(length / 2 + buffer, 0, z_origin - buffer)

    # Rotate about the z axis
    azimuth_rad = UnitConversions.convert(azimuth, 'deg', 'rad')
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0, 0] = Math::cos(-azimuth_rad)
    m[1, 1] = Math::cos(-azimuth_rad)
    m[0, 1] = -Math::sin(-azimuth_rad)
    m[1, 0] = Math::sin(-azimuth_rad)
    m[2, 2] = 1
    m[3, 3] = 1
    transformation = OpenStudio::Transformation.new(m)

    return transformation * vertices
  end

  # Reverse the vertices after calling create_floor_vertices with the same argument values.
  #
  # @param length [Double] length of the ceiling (ft)
  # @param width [Double] width of the ceiling (ft)
  # @param z_origin [Double] The z-coordinate for which the length and width are relative (ft)
  # @param default_azimuths [Array<Double>] Default azimuths for the four sides of the home, used for surfaces without an orientation
  # @return [OpenStudio::Point3dVector] an array of points
  def self.create_ceiling_vertices(length, width, z_origin, default_azimuths)
    return OpenStudio::reverse(create_floor_vertices(length, width, z_origin, default_azimuths))
  end

  # Create vertices for a horizontal plane based on length, width, z origin, and default azimuths.
  #
  # @param length [Double] length of the floor (ft)
  # @param width [Double] width of the floor (ft)
  # @param z_origin [Double] The z-coordinate for which the length and width are relative (ft)
  # @param default_azimuths [Array<Double>] Default azimuths for the four sides of the home, used for surfaces without an orientation
  # @return [OpenStudio::Point3dVector] an array of points
  def self.create_floor_vertices(length, width, z_origin, default_azimuths)
    length = UnitConversions.convert(length, 'ft', 'm')
    width = UnitConversions.convert(width, 'ft', 'm')
    z_origin = UnitConversions.convert(z_origin, 'ft', 'm')

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(-length / 2, -width / 2, z_origin)
    vertices << OpenStudio::Point3d.new(-length / 2, width / 2, z_origin)
    vertices << OpenStudio::Point3d.new(length / 2, width / 2, z_origin)
    vertices << OpenStudio::Point3d.new(length / 2, -width / 2, z_origin)

    # Rotate about the z axis
    # This is not strictly needed, but will make the floor edges
    # parallel to the walls for a better geometry rendering.
    azimuth_rad = UnitConversions.convert(default_azimuths[0], 'deg', 'rad')
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0, 0] = Math::cos(-azimuth_rad)
    m[1, 1] = Math::cos(-azimuth_rad)
    m[0, 1] = -Math::sin(-azimuth_rad)
    m[1, 0] = Math::sin(-azimuth_rad)
    m[2, 2] = 1
    m[3, 3] = 1
    transformation = OpenStudio::Transformation.new(m)

    return transformation * vertices
  end

  # Set calculated zone volumes for all HPXML locations on OpenStudio Thermal Zone and Space objects.
  #
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.set_zone_volumes(spaces, hpxml_bldg, hpxml_header)
    # Conditioned space
    volume = UnitConversions.convert(hpxml_bldg.building_construction.conditioned_building_volume, 'ft^3', 'm^3')
    spaces[HPXML::LocationConditionedSpace].thermalZone.get.setVolume(volume)
    spaces[HPXML::LocationConditionedSpace].setVolume(volume)

    # Basement, crawlspace, garage
    spaces.keys.each do |location|
      next unless [HPXML::LocationBasementUnconditioned, HPXML::LocationCrawlspaceUnvented, HPXML::LocationCrawlspaceVented, HPXML::LocationGarage].include? location

      volume = UnitConversions.convert(calculate_zone_volume(hpxml_bldg, location), 'ft^3', 'm^3')
      spaces[location].thermalZone.get.setVolume(volume)
      spaces[location].setVolume(volume)
    end

    # Attic
    spaces.keys.each do |location|
      next unless [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include? location

      if hpxml_header.apply_ashrae140_assumptions
        volume = UnitConversions.convert(3463, 'ft^3', 'm^3') # Hardcode the attic volume to match ASHRAE 140 Table 7-2 specification
      else
        volume = UnitConversions.convert(calculate_zone_volume(hpxml_bldg, location), 'ft^3', 'm^3')
      end

      spaces[location].thermalZone.get.setVolume(volume)
      spaces[location].setVolume(volume)
    end
  end

  # Re-position surfaces so as to not shade each other and to make it easier to visualize the building.
  # Horizontally pushes out OpenStudio::Model::Surface, OpenStudio::Model::SubSurface, and OpenStudio::Model::ShadingSurface objects.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.explode_surfaces(model, hpxml_bldg)
    gap_distance = UnitConversions.convert(10.0, 'ft', 'm') # distance between surfaces of the same azimuth
    rad90 = UnitConversions.convert(90, 'deg', 'rad')

    # Determine surfaces to shift and distance with which to explode surfaces horizontally outward
    surfaces = []
    azimuth_lengths = {}
    model.getSurfaces.sort.each do |surface|
      next unless [EPlus::SurfaceTypeWall, EPlus::SurfaceTypeRoofCeiling].include? surface.surfaceType
      next unless [EPlus::BoundaryConditionOutdoors, EPlus::BoundaryConditionFoundation, EPlus::BoundaryConditionAdiabatic, EPlus::BoundaryConditionCoefficients].include? surface.outsideBoundaryCondition
      next if surface.additionalProperties.getFeatureAsDouble('Tilt').get <= 0 # skip flat roofs

      surfaces << surface
      azimuth = surface.additionalProperties.getFeatureAsInteger('Azimuth').get
      if azimuth_lengths[azimuth].nil?
        azimuth_lengths[azimuth] = 0.0
      end
      azimuth_lengths[azimuth] += surface.additionalProperties.getFeatureAsDouble('Length').get + gap_distance
    end
    max_azimuth_length = azimuth_lengths.values.max

    # Using the max length for a given azimuth, calculate the apothem (radius of the incircle) of a regular
    # n-sided polygon to create the smallest polygon possible without self-shading. The number of polygon
    # sides is defined by the minimum difference between two azimuths.
    min_azimuth_diff = 360
    azimuths_sorted = azimuth_lengths.keys.sort
    azimuths_sorted.each_with_index do |az, idx|
      diff1 = (az - azimuths_sorted[(idx + 1) % azimuths_sorted.size]).abs
      diff2 = 360.0 - diff1 # opposite direction
      if diff1 < min_azimuth_diff
        min_azimuth_diff = diff1
      end
      if diff2 < min_azimuth_diff
        min_azimuth_diff = diff2
      end
    end
    if min_azimuth_diff > 0
      nsides = [(360.0 / min_azimuth_diff).ceil, 4].max # assume rectangle at the minimum
    else
      nsides = 4
    end
    explode_distance = max_azimuth_length / (2.0 * Math.tan(UnitConversions.convert(180.0 / nsides, 'deg', 'rad')))

    add_neighbor_shading(model, max_azimuth_length, hpxml_bldg)

    # Initial distance of shifts at 90-degrees to horizontal outward
    azimuth_side_shifts = {}
    azimuth_lengths.keys.each do |azimuth|
      azimuth_side_shifts[azimuth] = max_azimuth_length / 2.0
    end

    # Explode neighbors
    model.getShadingSurfaceGroups.each do |shading_group|
      next unless shading_group.name.to_s == Constants::ObjectTypeNeighbors

      shading_group.shadingSurfaces.each do |shading_surface|
        azimuth = shading_surface.additionalProperties.getFeatureAsInteger('Azimuth').get
        azimuth_rad = UnitConversions.convert(azimuth, 'deg', 'rad')
        distance = shading_surface.additionalProperties.getFeatureAsDouble('Distance').get

        unless azimuth_lengths.keys.include? azimuth
          fail "A neighbor building has an azimuth (#{azimuth}) not equal to the azimuth of any wall."
        end

        # Push out horizontally
        distance += explode_distance
        transformation = get_surface_transformation(offset: distance, x: Math::sin(azimuth_rad), y: Math::cos(azimuth_rad), z: 0)

        shading_surface.setVertices(transformation * shading_surface.vertices)
      end
    end

    # Explode walls, windows, doors, roofs, and skylights
    surfaces_moved = []

    surfaces.sort.each do |surface|
      next if surface.additionalProperties.getFeatureAsDouble('Tilt').get <= 0 # skip flat roofs

      if surface.adjacentSurface.is_initialized
        next if surfaces_moved.include? surface.adjacentSurface.get
      end

      azimuth = surface.additionalProperties.getFeatureAsInteger('Azimuth').get
      azimuth_rad = UnitConversions.convert(azimuth, 'deg', 'rad')

      # Get associated shading surfaces (e.g., overhangs, interior shading surfaces)
      overhang_surfaces = []
      shading_surfaces = []
      surface.subSurfaces.each do |subsurface|
        next unless subsurface.subSurfaceType == EPlus::SubSurfaceTypeWindow

        subsurface.shadingSurfaceGroups.each do |overhang_group|
          overhang_group.shadingSurfaces.each do |overhang|
            overhang_surfaces << overhang
          end
        end
      end

      # Push out horizontally
      distance = explode_distance

      if surface.surfaceType == EPlus::SurfaceTypeRoofCeiling
        # Ensure pitched surfaces are positioned outward justified with walls, etc.
        tilt = surface.additionalProperties.getFeatureAsDouble('Tilt').get
        width = surface.additionalProperties.getFeatureAsDouble('Width').get
        distance -= 0.5 * Math.cos(Math.atan(tilt)) * width
      end
      transformation = get_surface_transformation(offset: distance, x: Math::sin(azimuth_rad), y: Math::cos(azimuth_rad), z: 0)
      transformation_shade = get_surface_transformation(offset: distance + 0.001, x: Math::sin(azimuth_rad), y: Math::cos(azimuth_rad), z: 0) # Offset slightly from window

      ([surface] + surface.subSurfaces + overhang_surfaces).each do |s|
        s.setVertices(transformation * s.vertices)
      end
      shading_surfaces.each do |s|
        s.setVertices(transformation_shade * s.vertices)
      end
      if surface.adjacentSurface.is_initialized
        surface.adjacentSurface.get.setVertices(transformation * surface.adjacentSurface.get.vertices)
      end

      # Shift at 90-degrees to previous transformation, so surfaces don't overlap and shade each other
      azimuth_side_shifts[azimuth] -= surface.additionalProperties.getFeatureAsDouble('Length').get / 2.0
      transformation_shift = get_surface_transformation(offset: azimuth_side_shifts[azimuth], x: Math::sin(azimuth_rad + rad90), y: Math::cos(azimuth_rad + rad90), z: 0)

      ([surface] + surface.subSurfaces + overhang_surfaces + shading_surfaces).each do |s|
        s.setVertices(transformation_shift * s.vertices)
      end
      if surface.adjacentSurface.is_initialized
        surface.adjacentSurface.get.setVertices(transformation_shift * surface.adjacentSurface.get.vertices)
      end

      azimuth_side_shifts[azimuth] -= (surface.additionalProperties.getFeatureAsDouble('Length').get / 2.0 + gap_distance)

      surfaces_moved << surface
    end
  end

  # Shift units so they aren't right on top and shade each other.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param unit_number [Integer] index number corresponding to an HPXML Building object
  # @return [nil]
  def self.shift_surfaces(model, unit_number)
    y_shift = 200.0 * unit_number # meters

    # shift the unit so it's not right on top of the previous one
    model.getSpaces.sort.each do |space|
      space.setYOrigin(y_shift)
    end

    # shift shading surfaces
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0, 0] = 1
    m[1, 1] = 1
    m[2, 2] = 1
    m[3, 3] = 1
    m[1, 3] = y_shift
    t = OpenStudio::Transformation.new(m)

    model.getShadingSurfaceGroups.each do |shading_surface_group|
      next if shading_surface_group.space.is_initialized # already got shifted

      shading_surface_group.shadingSurfaces.each do |shading_surface|
        shading_surface.setVertices(t * shading_surface.vertices)
      end
    end
  end

  # Get the surface transformation using the translation matrix defined by an offset multiplied by 3D translation vector (x, y, z).
  # Applying the affine transformation will shift a set of vertices.
  #
  # @param offset [Double] the magnitude of the vector (ft)
  # @param x [Double] the x-coordinate of the translation vector
  # @param y [Double] the y-coordinate of the translation vector
  # @param z [Double] the z-coordinate of the translation vector
  # @return [OpenStudio::Transformation] the OpenStudio transformation object
  def self.get_surface_transformation(offset:, x:, y:, z:)
    x = UnitConversions.convert(x, 'ft', 'm')
    y = UnitConversions.convert(y, 'ft', 'm')
    z = UnitConversions.convert(z, 'ft', 'm')

    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0, 0] = 1
    m[1, 1] = 1
    m[2, 2] = 1
    m[3, 3] = 1
    m[0, 3] = x * offset
    m[1, 3] = y * offset
    m[2, 3] = z.abs * offset

    return OpenStudio::Transformation.new(m)
  end

  # Add OpenStudio Shading Surfaces representing neighbor buildings.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param length [Double] the shading surface length for each neighbor azimuth (ft)
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.add_neighbor_shading(model, length, hpxml_bldg)
    walls_top = hpxml_bldg.building_construction.additional_properties.walls_height_above_grade
    z_origin = 0 # shading surface always starts at grade

    shading_surfaces = []
    hpxml_bldg.neighbor_buildings.each do |neighbor_building|
      height = neighbor_building.height.nil? ? walls_top : neighbor_building.height

      vertices = create_wall_vertices(length, height, z_origin, neighbor_building.azimuth)
      shading_surface = OpenStudio::Model::ShadingSurface.new(vertices, model)
      shading_surface.additionalProperties.setFeature('Azimuth', neighbor_building.azimuth)
      shading_surface.additionalProperties.setFeature('Distance', neighbor_building.distance)
      shading_surface.setName("Neighbor azimuth #{neighbor_building.azimuth} distance #{neighbor_building.distance}")

      shading_surfaces << shading_surface
    end

    unless shading_surfaces.empty?
      shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
      shading_surface_group.setName(Constants::ObjectTypeNeighbors)
      shading_surfaces.each do |shading_surface|
        shading_surface.setShadingSurfaceGroup(shading_surface_group)
      end
    end
  end

  # Calculate zone volume for an HPXML location based on floor area and an assumed height.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param location [String] The location of interest (HPXML::LocationXXX)
  # @return [Double] The zone volume (ft^3)
  def self.calculate_zone_volume(hpxml_bldg, location)
    if [HPXML::LocationBasementConditioned,
        HPXML::LocationBasementUnconditioned,
        HPXML::LocationCrawlspaceUnvented,
        HPXML::LocationCrawlspaceVented,
        HPXML::LocationCrawlspaceConditioned,
        HPXML::LocationGarage].include? location
      floor_area = hpxml_bldg.slabs.select { |s| s.interior_adjacent_to == location }.map { |s| s.area }.sum(0.0)
      height = calculate_zone_height(hpxml_bldg, location)
      return floor_area * height
    elsif [HPXML::LocationAtticUnvented,
           HPXML::LocationAtticVented].include? location
      footprint_area = calculate_height_and_footprint_of_roofs(hpxml_bldg, location)[1]
      height = calculate_zone_height(hpxml_bldg, location)
      return [footprint_area * height / 3.0, 0.01].max # Assume square hip roof
    end
  end

  # Calculate (or assume) the zone height (difference between top and bottom of the zone) for a
  # given HPXML location.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param location [String] The location of interest (HPXML::LocationXXX)
  # @param above_grade [Boolean] True to return the above-grade height (vs the total height) for a below-grade space
  # @return [Double] The zone height (ft)
  def self.calculate_zone_height(hpxml_bldg, location, above_grade: false)
    if [HPXML::LocationBasementConditioned,
        HPXML::LocationBasementUnconditioned,
        HPXML::LocationCrawlspaceUnvented,
        HPXML::LocationCrawlspaceVented,
        HPXML::LocationCrawlspaceConditioned,
        HPXML::LocationGarage].include? location
      if above_grade
        height = hpxml_bldg.foundation_walls.select { |w| w.interior_adjacent_to == location }.map { |w| w.height - w.depth_below_grade }.max
      else
        height = hpxml_bldg.foundation_walls.select { |w| w.interior_adjacent_to == location }.map { |w| w.height }.max
      end
      if height.nil? # No foundation walls, need to make assumption because HPXML Wall elements don't have a height
        height = { HPXML::LocationBasementConditioned => 8,
                   HPXML::LocationBasementUnconditioned => 8,
                   HPXML::LocationCrawlspaceUnvented => 3,
                   HPXML::LocationCrawlspaceVented => 3,
                   HPXML::LocationCrawlspaceConditioned => 3,
                   HPXML::LocationGarage => 8 }[location]
      end
    elsif [HPXML::LocationAtticUnvented,
           HPXML::LocationAtticVented].include? location
      height = calculate_height_and_footprint_of_roofs(hpxml_bldg, location)[0]
    end
    return height
  end

  # Approximates the height (difference between top and bottom) for the roof surfaces
  # adjacent to the specified location.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param location [String] The location of interest (HPXML::LocationXXX)
  # @return [Double, Double] The height (ft) and footprint area (ft^2) of the roof
  def self.calculate_height_and_footprint_of_roofs(hpxml_bldg, location)
    roofs = hpxml_bldg.roofs.select { |r| r.interior_adjacent_to == location }
    roof_area = roofs.map { |r| r.area }.sum(0.0)
    avg_pitch = roofs.map { |r| r.pitch }.sum(0.0) / roofs.size
    roof_pitch_multiplier = ((avg_pitch / 12.0)**2 + 1)**0.5
    roof_footprint_area = roof_area / roof_pitch_multiplier
    if avg_pitch > 0
      # Assume square hip roof
      length = roof_footprint_area**0.5
      height = 0.5 * Math.sin(Math.atan(avg_pitch / 12.0)) * length
    else
      if [HPXML::LocationAtticUnvented,
          HPXML::LocationAtticVented].include? location
        # Flat roof w/ attic, assume height
        height = 2.0
      else
        height = 0.0
      end
    end
    return height, roof_footprint_area
  end

  # Get temperature scheduled space values for an HPXML location.
  #
  # @param location [String] The location of interest (HPXML::LocationXXX)
  # @return [Hash] Map of minimum temperature, indoor/outdoor/ground weights, duct regain factor
  def self.get_temperature_scheduled_space_values(location)
    case location
    when HPXML::LocationOtherHeatedSpace
      # Average of indoor/outdoor temperatures with minimum of heating setpoint
      return { temp_min: 68,
               indoor_weight: 0.5,
               outdoor_weight: 0.5,
               ground_weight: 0.0,
               f_regain: 0.0 }
    when HPXML::LocationOtherMultifamilyBufferSpace
      # Average of indoor/outdoor temperatures with minimum of 50 F
      return { temp_min: 50,
               indoor_weight: 0.5,
               outdoor_weight: 0.5,
               ground_weight: 0.0,
               f_regain: 0.0 }
    when HPXML::LocationOtherNonFreezingSpace
      # Floating with outdoor air temperature with minimum of 40 F
      return { temp_min: 40,
               indoor_weight: 0.0,
               outdoor_weight: 1.0,
               ground_weight: 0.0,
               f_regain: 0.0 }
    when HPXML::LocationOtherHousingUnit
      # Indoor air temperature
      return { temp_min: nil,
               indoor_weight: 1.0,
               outdoor_weight: 0.0,
               ground_weight: 0.0,
               f_regain: 0.0 }
    when HPXML::LocationExteriorWall
      # Average of indoor/outdoor temperatures
      return { temp_min: nil,
               indoor_weight: 0.5,
               outdoor_weight: 0.5,
               ground_weight: 0.0,
               f_regain: 0.5 } # From LBNL's "Technical Background for default values used for Forced Air Systems in Proposed ASHRAE Standard 152P"
    when HPXML::LocationUnderSlab
      # Ground temperature
      return { temp_min: nil,
               indoor_weight: 0.0,
               outdoor_weight: 0.0,
               ground_weight: 1.0,
               f_regain: 0.83 } # From LBNL's "Technical Background for default values used for Forced Air Systems in Proposed ASHRAE Standard 152P"
    when HPXML::LocationManufacturedHomeBelly
      # From LBNL's "Technical Background for default values used for Forced Air Systems in Proposed ASHRAE Standard 152P"
      # 3.5 Manufactured House Belly Pan Temperatures
      # FUTURE: Consider modeling the belly as a separate thermal zone so that we dynamically calculate temperatures.
      return { temp_min: nil,
               indoor_weight: 1.0,
               outdoor_weight: 0.0,
               ground_weight: 0.0,
               f_regain: 0.62 }
    end
    fail "Unhandled location: #{location}."
  end

  # For a given OpenStudio Surface, set the OpenStudio Space based on the adjacent interior location of an HPXML Surface.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param surface [OpenStudio::Model::Surface] an OpenStudio::Model::Surface object
  # @param hpxml_surface [HPXML::Wall or HPXML::Roof or HPXML::RimJoist or HPXML::FoundationWall or HPXML::Slab] any HPXML surface
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.set_surface_interior(model, spaces, surface, hpxml_surface, hpxml_bldg)
    if HPXML::conditioned_below_grade_locations.include? hpxml_surface.interior_adjacent_to
      surface.setSpace(create_or_get_space(model, spaces, HPXML::LocationConditionedSpace, hpxml_bldg))
    else
      surface.setSpace(create_or_get_space(model, spaces, hpxml_surface.interior_adjacent_to, hpxml_bldg))
    end
  end

  # For a given OpenStudio Surface, set either an outside boundary condition or adjacent OpenStudio Surface based on the adjacent exterior location of an HPXML Surface.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param surface [OpenStudio::Model::Surface] an OpenStudio::Model::Surface object
  # @param hpxml_surface [HPXML::Wall or HPXML::Roof or HPXML::RimJoist or HPXML::FoundationWall or HPXML::Slab] any HPXML surface
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.set_surface_exterior(model, spaces, surface, hpxml_surface, hpxml_bldg, hpxml_header)
    return if hpxml_header.whole_sfa_or_mf_building_sim && hpxml_surface.additional_properties.respond_to?(:adjacent_hpxml_id)

    exterior_adjacent_to = hpxml_surface.exterior_adjacent_to
    is_adiabatic = hpxml_surface.is_adiabatic
    if [HPXML::LocationOutside, HPXML::LocationManufacturedHomeUnderBelly].include? exterior_adjacent_to
      surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)
    elsif exterior_adjacent_to == HPXML::LocationGround
      surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionFoundation)
    elsif is_adiabatic
      surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionAdiabatic)
    elsif [HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace,
           HPXML::LocationOtherNonFreezingSpace, HPXML::LocationOtherHousingUnit].include? exterior_adjacent_to
      set_surface_otherside_coefficients(surface, exterior_adjacent_to, model, spaces)
    elsif HPXML::conditioned_below_grade_locations.include? exterior_adjacent_to
      adjacent_surface = surface.createAdjacentSurface(create_or_get_space(model, spaces, HPXML::LocationConditionedSpace, hpxml_bldg)).get
      adjacent_surface.additionalProperties.setFeature('SurfaceType', surface.additionalProperties.getFeatureAsString('SurfaceType').get)
    else
      adjacent_surface = surface.createAdjacentSurface(create_or_get_space(model, spaces, exterior_adjacent_to, hpxml_bldg)).get
      adjacent_surface.additionalProperties.setFeature('SurfaceType', surface.additionalProperties.getFeatureAsString('SurfaceType').get)
    end
  end

  # Set its parent surface outside boundary condition, which will be also applied to subsurfaces through OS
  # The parent surface is entirely comprised of the subsurface.
  #
  # @param surface [OpenStudio::Model::Surface] an OpenStudio::Model::Surface object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_surface [HPXML::Wall or HPXML::Roof or HPXML::RimJoist or HPXML::FoundationWall or HPXML::Slab] any HPXML surface
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.set_subsurface_exterior(surface, spaces, model, hpxml_surface, hpxml_bldg, hpxml_header)
    # Subsurface on foundation wall, set it to be adjacent to outdoors
    if hpxml_surface.exterior_adjacent_to == HPXML::LocationGround
      surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)
    else
      set_surface_exterior(model, spaces, surface, hpxml_surface, hpxml_bldg, hpxml_header)
    end
  end

  # For a given OpenStudio Surface, set the Other Side Coefficients (based on space temperature schedule) and sun/wind exposure.
  #
  # @param surface [OpenStudio::Model::Surface] an OpenStudio::Model::Surface object
  # @param exterior_adjacent_to [String] Exterior adjacent to location (HPXML::LocationXXX)
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @return [nil]
  def self.set_surface_otherside_coefficients(surface, exterior_adjacent_to, model, spaces)
    otherside_coeffs = nil
    model.getSurfacePropertyOtherSideCoefficientss.each do |c|
      next unless c.name.to_s == exterior_adjacent_to

      otherside_coeffs = c
    end
    if otherside_coeffs.nil?
      # Create E+ other side coefficient object
      otherside_coeffs = OpenStudio::Model::SurfacePropertyOtherSideCoefficients.new(model)
      otherside_coeffs.setName(exterior_adjacent_to)
      otherside_coeffs.setCombinedConvectiveRadiativeFilmCoefficient(UnitConversions.convert(1.0 / Material.AirFilmIndoorWall.rvalue, 'Btu/(hr*ft^2*F)', 'W/(m^2*K)'))
      # Schedule of space temperature, can be shared with water heater/ducts
      sch = get_space_temperature_schedule(model, exterior_adjacent_to, spaces)
      otherside_coeffs.setConstantTemperatureSchedule(sch)
    end
    surface.setSurfacePropertyOtherSideCoefficients(otherside_coeffs)
    surface.setSunExposure(EPlus::SurfaceSunExposureNo)
    surface.setWindExposure(EPlus::SurfaceWindExposureNo)
  end

  # Create outside boundary schedules to be actuated by EMS,
  # can be shared by any surface, duct adjacent to / located in those spaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param location [String] The location of interest (HPXML::LocationXXX)
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @return [OpenStudio::Model::ScheduleConstant] OpenStudio ScheduleConstant object
  def self.get_space_temperature_schedule(model, location, spaces)
    # return if already exists
    model.getScheduleConstants.each do |sch|
      next unless sch.name.to_s == location

      return sch
    end

    sch = Model.add_schedule_constant(
      model,
      name: location,
      value: nil,
      limits: EPlus::ScheduleTypeLimitsTemperature
    )
    sch.additionalProperties.setFeature('ObjectType', location)

    space_values = get_temperature_scheduled_space_values(location)

    htg_weekday_setpoints, htg_weekend_setpoints = Defaults.get_heating_setpoint(HPXML::HVACControlTypeManual, @eri_version)
    if htg_weekday_setpoints.split(', ').uniq.size == 1 && htg_weekend_setpoints.split(', ').uniq.size == 1 && htg_weekday_setpoints.split(', ').uniq == htg_weekend_setpoints.split(', ').uniq
      default_htg_sp = htg_weekend_setpoints.split(', ').uniq[0].to_f # F
    else
      fail 'Unexpected heating setpoints.'
    end

    clg_weekday_setpoints, clg_weekend_setpoints = Defaults.get_cooling_setpoint(HPXML::HVACControlTypeManual, @eri_version)
    if clg_weekday_setpoints.split(', ').uniq.size == 1 && clg_weekend_setpoints.split(', ').uniq.size == 1 && clg_weekday_setpoints.split(', ').uniq == clg_weekend_setpoints.split(', ').uniq
      default_clg_sp = clg_weekend_setpoints.split(', ').uniq[0].to_f # F
    else
      fail 'Unexpected cooling setpoints.'
    end

    if location == HPXML::LocationOtherHeatedSpace
      if spaces[HPXML::LocationConditionedSpace].thermalZone.get.thermostatSetpointDualSetpoint.is_initialized
        # Create a sensor to get dynamic heating setpoint
        htg_sch = spaces[HPXML::LocationConditionedSpace].thermalZone.get.thermostatSetpointDualSetpoint.get.heatingSetpointTemperatureSchedule.get
        space_values[:temp_min] = Model.add_ems_sensor(
          model,
          name: 'htg_spt',
          output_var_or_meter_name: 'Schedule Value',
          key_name: htg_sch.name
        )
        space_values[:temp_min] = space_values[:temp_min].name.to_s
      else
        # No HVAC system; use the defaulted heating setpoint.
        space_values[:temp_min] = default_htg_sp # F
      end
    end

    # Sensors
    if space_values[:indoor_weight] > 0
      if not spaces[HPXML::LocationConditionedSpace].thermalZone.get.thermostatSetpointDualSetpoint.is_initialized
        # No HVAC system; use the average of defaulted heating/cooling setpoints.
        sensor_ia = UnitConversions.convert((default_htg_sp + default_clg_sp) / 2.0, 'F', 'C')
      else
        sensor_ia = Model.add_ems_sensor(
          model,
          name: 'cond_zone_temp',
          output_var_or_meter_name: 'Zone Air Temperature',
          key_name: spaces[HPXML::LocationConditionedSpace].thermalZone.get.name
        )
        sensor_ia = sensor_ia.name
      end
    end

    if space_values[:outdoor_weight] > 0
      sensor_oa = Model.add_ems_sensor(
        model,
        name: 'oa_temp',
        output_var_or_meter_name: 'Site Outdoor Air Drybulb Temperature',
        key_name: nil
      )
    end

    if space_values[:ground_weight] > 0
      sensor_gnd = Model.add_ems_sensor(
        model,
        name: 'ground_temp',
        output_var_or_meter_name: 'Site Surface Ground Temperature',
        key_name: nil
      )
    end

    actuator = Model.add_ems_actuator(
      name: "#{location} temp sch",
      model_object: sch,
      comp_type_and_control: EPlus::EMSActuatorScheduleConstantValue
    )

    # EMS to actuate schedule
    program = Model.add_ems_program(
      model,
      name: "#{location} Temperature Program"
    )
    program.addLine("Set #{actuator.name} = 0.0")
    if not sensor_ia.nil?
      program.addLine("Set #{actuator.name} = #{actuator.name} + (#{sensor_ia} * #{space_values[:indoor_weight]})")
    end
    if not sensor_oa.nil?
      program.addLine("Set #{actuator.name} = #{actuator.name} + (#{sensor_oa.name} * #{space_values[:outdoor_weight]})")
    end
    if not sensor_gnd.nil?
      program.addLine("Set #{actuator.name} = #{actuator.name} + (#{sensor_gnd.name} * #{space_values[:ground_weight]})")
    end
    if not space_values[:temp_min].nil?
      if space_values[:temp_min].is_a? String
        min_temp_c = space_values[:temp_min]
      else
        min_temp_c = UnitConversions.convert(space_values[:temp_min], 'F', 'C')
      end
      program.addLine("If #{actuator.name} < #{min_temp_c}")
      program.addLine("Set #{actuator.name} = #{min_temp_c}")
      program.addLine('EndIf')
    end

    Model.add_ems_program_calling_manager(
      model,
      name: "#{program.name} calling manager",
      calling_point: 'EndOfSystemTimestepAfterHVACReporting',
      ems_programs: [program]
    )

    return sch
  end

  # Returns an OS:Space, or temperature OS:Schedule for a MF space, or nil if outside
  # Should be called when the object's energy use is sensitive to ambient temperature
  # (e.g., water heaters, ducts, and refrigerators).
  #
  # @param location [String] The location of interest (HPXML::LocationXXX)
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @return [OpenStudio::Model::Space or OpenStudio::Model::ScheduleConstant] OpenStudio Space or Schedule object
  def self.get_space_or_schedule_from_location(location, model, spaces)
    return if [HPXML::LocationOtherExterior,
               HPXML::LocationOutside,
               HPXML::LocationRoofDeck].include? location

    sch = nil
    space = nil
    if [HPXML::LocationOtherHeatedSpace,
        HPXML::LocationOtherHousingUnit,
        HPXML::LocationOtherMultifamilyBufferSpace,
        HPXML::LocationOtherNonFreezingSpace,
        HPXML::LocationExteriorWall,
        HPXML::LocationUnderSlab].include? location
      # if located in spaces where we don't model a thermal zone, create and return temperature schedule
      sch = get_space_temperature_schedule(model, location, spaces)
    else
      space = get_space_from_location(location, spaces)
    end

    return space, sch
  end

  # Returns an OS:Space, or nil if a MF space or outside
  # Should be called when the object's energy use is NOT sensitive to ambient temperature
  # (e.g., appliances).
  #
  # @param location [String] The location of interest (HPXML::LocationXXX)
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @return [OpenStudio::Model::Space] OpenStudio Space object
  def self.get_space_from_location(location, spaces)
    return if [HPXML::LocationOutside,
               HPXML::LocationOtherHeatedSpace,
               HPXML::LocationOtherHousingUnit,
               HPXML::LocationOtherMultifamilyBufferSpace,
               HPXML::LocationOtherNonFreezingSpace].include? location

    if HPXML::conditioned_locations.include? location
      location = HPXML::LocationConditionedSpace
    end

    return spaces[location]
  end

  # Calculates the minimum buffer distance that the parent surface
  # needs relative to the subsurface in order to prevent E+ warnings
  # about "Very small surface area".
  #
  # @param length [Double] length of the subsurface (m)
  # @param width [Double] width of the subsurface (m)
  # @return [Double] minimum needed buffer distance (m)
  def self.calculate_subsurface_parent_buffer(length, width)
    min_surface_area = 0.005 # m^2
    return 0.5 * (((length + width)**2 + 4.0 * min_surface_area)**0.5 - length - width)
  end

  # For a provided HPXML Location, create an OpenStudio Space and Thermal Zone if the provided spaces hash doesn't already contain the OpenStudio Space.
  # Otherwise, return the already-created OpenStudio Space for the provided HPXML Location.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param location [String] The location of interest (HPXML::LocationXXX)
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [OpenStudio::Model::Space] the OpenStudio::Model::Space object corresponding to HPXML::LocationXXX
  def self.create_or_get_space(model, spaces, location, hpxml_bldg)
    if spaces[location].nil?
      create_space_and_zone(model, spaces, location, hpxml_bldg.building_construction.number_of_units)
    end
    return spaces[location]
  end

  # Store the HPXML Building object unit number for use in reporting measure.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml [HPXML] HPXML object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply_building_unit(model, hpxml, hpxml_bldg)
    return if hpxml.buildings.size == 1

    unit_num = hpxml.buildings.index(hpxml_bldg) + 1

    unit = OpenStudio::Model::BuildingUnit.new(model)
    unit.additionalProperties.setFeature('unit_num', unit_num)
    model.getSpaces.each do |s|
      s.setBuildingUnit(unit)
    end
  end
end
