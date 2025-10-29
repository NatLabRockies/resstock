# frozen_string_literal: true

# Collection of methods to get, add, assign, create, etc. geometry-related OpenStudio objects.
module Geometry
  # Create a 3D representation of a single-family detached home using the following arguments.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param geometry_unit_cfa [Double] conditioned floor area (ft2)
  # @param geometry_average_ceiling_height [Double] average ceiling height (ft)
  # @param geometry_unit_num_floors_above_grade [Integer] number of floors above grade
  # @param geometry_unit_aspect_ratio [Double] ratio of front/back wall length to left/right wall length (frac)
  # @param geometry_garage_width [Double] width of the garage (ft)
  # @param geometry_garage_depth [Double] depth of the garage (ft)
  # @param geometry_garage_protrusion [Double] fraction of garage that protrudes from conditioned space
  # @param geometry_garage_position [String] Right or Left
  # @param geometry_foundation_type [String] foundation type of the building
  # @param geometry_foundation_height [Double] height of the foundation (ft)
  # @param geometry_rim_joist_height [Double] height of the rim joists (ft)
  # @param geometry_attic_type [String] attic type of the building
  # @param geometry_roof_type [String] roof type of the building
  # @param geometry_roof_pitch [Double] ratio of vertical rise to horizontal run (frac)
  # @return [Boolean] true if model is successfully updated with a single-family detached unit
  def self.create_single_family_detached(runner, model,
                                         geometry_unit_cfa:,
                                         geometry_average_ceiling_height:,
                                         geometry_unit_num_floors_above_grade:,
                                         geometry_unit_aspect_ratio:,
                                         geometry_garage_width:,
                                         geometry_garage_depth:,
                                         geometry_garage_protrusion:,
                                         geometry_garage_position:,
                                         geometry_foundation_type:,
                                         geometry_foundation_height:,
                                         geometry_rim_joist_height:,
                                         geometry_attic_type:,
                                         geometry_roof_type:,
                                         geometry_roof_pitch:,
                                         **)
    cfa = geometry_unit_cfa
    average_ceiling_height = geometry_average_ceiling_height
    num_floors = geometry_unit_num_floors_above_grade
    aspect_ratio = geometry_unit_aspect_ratio
    garage_width = geometry_garage_width
    garage_depth = geometry_garage_depth
    garage_protrusion = geometry_garage_protrusion
    garage_position = geometry_garage_position
    foundation_type = geometry_foundation_type
    foundation_height = geometry_foundation_height
    rim_joist_height = geometry_rim_joist_height
    attic_type = geometry_attic_type
    if attic_type == HPXML::AtticTypeConditioned
      num_floors -= 1
    end
    roof_type = geometry_roof_type
    roof_pitch = geometry_roof_pitch

    # Convert to SI
    cfa = UnitConversions.convert(cfa, 'ft^2', 'm^2')
    average_ceiling_height = UnitConversions.convert(average_ceiling_height, 'ft', 'm')
    garage_width = UnitConversions.convert(garage_width, 'ft', 'm')
    garage_depth = UnitConversions.convert(garage_depth, 'ft', 'm')
    foundation_height = UnitConversions.convert(foundation_height, 'ft', 'm')
    rim_joist_height = UnitConversions.convert(rim_joist_height, 'ft', 'm')

    length, width = calculate_footprint_length_width(garage_width, garage_depth, garage_protrusion, foundation_type, attic_type, num_floors, cfa, aspect_ratio)

    # Error checking: adjust garage width if too wide relative the living space dimensions
    # e.g., this can happen if garage protrudes too much for a small dwelling unit
    garage_width_adjusted = false
    while ((garage_width >= length) && (garage_depth > 0))
      garage_width -= UnitConversions.convert(1, 'ft', 'm') # reduce garage width in 1 ft increments
      length, width = calculate_footprint_length_width(garage_width, garage_depth, garage_protrusion, foundation_type, attic_type, num_floors, cfa, aspect_ratio)
      garage_width_adjusted = true
    end
    if garage_width_adjusted
      runner.registerWarning("Garage is as wide as the single-family detached unit; garage width reduced from #{geometry_garage_width} ft to #{UnitConversions.convert(garage_width, 'm', 'ft').round(1)} ft.")
    end

    # Error checking: adjust garage depth if too deep relative the living space dimensions
    # e.g., this can happen if garage doesn't protrude enough for a small dwelling unit
    garage_depth_adjusted = false
    while ((((1.0 - garage_protrusion) * garage_depth) >= width) && (garage_width > 0))
      garage_depth -= UnitConversions.convert(1, 'ft', 'm') # reduce garage depth in 1 ft increments
      length, width = calculate_footprint_length_width(garage_width, garage_depth, garage_protrusion, foundation_type, attic_type, num_floors, cfa, aspect_ratio)
      garage_depth_adjusted = true
    end
    if garage_depth_adjusted
      runner.registerWarning("Garage is as deep as the single-family detached unit; garage depth reduced from #{geometry_garage_depth} ft to #{UnitConversions.convert(garage_depth, 'm', 'ft').round(1)} ft.")
    end

    # create conditioned zone
    conditioned_zone = OpenStudio::Model::ThermalZone.new(model)
    conditioned_zone.setName(HPXML::LocationConditionedSpace)

    # loop through the number of floors
    foundation_polygon_with_wrong_zs = nil
    for floor in (0..num_floors - 1)
      z = average_ceiling_height * floor + rim_joist_height

      if (garage_width * garage_depth > 0) && (z == rim_joist_height) # first floor and has garage

        # create garage zone
        garage_space_name = HPXML::LocationGarage
        garage_zone = OpenStudio::Model::ThermalZone.new(model)
        garage_zone.setName(garage_space_name)

        # make points and polygons
        if garage_position == Constants::PositionRight
          garage_sw_point = OpenStudio::Point3d.new(length - garage_width, -garage_protrusion * garage_depth, z)
          garage_nw_point = OpenStudio::Point3d.new(length - garage_width, garage_depth - garage_protrusion * garage_depth, z)
          garage_ne_point = OpenStudio::Point3d.new(length, garage_depth - garage_protrusion * garage_depth, z)
          garage_se_point = OpenStudio::Point3d.new(length, -garage_protrusion * garage_depth, z)
          garage_polygon = make_polygon(garage_sw_point, garage_nw_point, garage_ne_point, garage_se_point)
        elsif garage_position == Constants::PositionLeft
          garage_sw_point = OpenStudio::Point3d.new(0, -garage_protrusion * garage_depth, z)
          garage_nw_point = OpenStudio::Point3d.new(0, garage_depth - garage_protrusion * garage_depth, z)
          garage_ne_point = OpenStudio::Point3d.new(garage_width, garage_depth - garage_protrusion * garage_depth, z)
          garage_se_point = OpenStudio::Point3d.new(garage_width, -garage_protrusion * garage_depth, z)
          garage_polygon = make_polygon(garage_sw_point, garage_nw_point, garage_ne_point, garage_se_point)
        end

        # make space
        garage_space = OpenStudio::Model::Space::fromFloorPrint(garage_polygon, average_ceiling_height, model)
        garage_space = garage_space.get
        assign_indexes(model, footprint_polygon: garage_polygon, space: garage_space)
        garage_space.setName(garage_space_name)
        garage_space_type = OpenStudio::Model::SpaceType.new(model)
        garage_space_type.setStandardsSpaceType(garage_space_name)
        garage_space.setSpaceType(garage_space_type)

        # set this to the garage zone
        garage_space.setThermalZone(garage_zone)

        m = initialize_transformation_matrix()
        m[2, 3] = z
        garage_space.changeTransformation(OpenStudio::Transformation.new(m))

        if garage_position == Constants::PositionRight
          sw_point = OpenStudio::Point3d.new(0, 0, z)
          nw_point = OpenStudio::Point3d.new(0, width, z)
          ne_point = OpenStudio::Point3d.new(length, width, z)
          se_point = OpenStudio::Point3d.new(length, 0, z)
          l_se_point = OpenStudio::Point3d.new(length - garage_width, 0, z)
          if ((garage_depth < width) || (garage_protrusion > 0)) && (garage_protrusion < 1) # garage protrudes but not fully
            conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, garage_ne_point, garage_nw_point, l_se_point)
          elsif garage_protrusion < 1 # garage fits perfectly within conditioned space
            conditioned_polygon = make_polygon(sw_point, nw_point, garage_nw_point, garage_sw_point)
          else # garage fully protrudes
            conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)
          end
        elsif garage_position == Constants::PositionLeft
          sw_point = OpenStudio::Point3d.new(0, 0, z)
          nw_point = OpenStudio::Point3d.new(0, width, z)
          ne_point = OpenStudio::Point3d.new(length, width, z)
          se_point = OpenStudio::Point3d.new(length, 0, z)
          l_sw_point = OpenStudio::Point3d.new(garage_width, 0, z)
          if ((garage_depth < width) || (garage_protrusion > 0)) && (garage_protrusion < 1) # garage protrudes but not fully
            conditioned_polygon = make_polygon(garage_nw_point, nw_point, ne_point, se_point, l_sw_point, garage_ne_point)
          elsif garage_protrusion < 1 # garage fits perfectly within conditioned space
            conditioned_polygon = make_polygon(garage_se_point, garage_ne_point, ne_point, se_point)
          else # garage fully protrudes
            conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)
          end
        end
        foundation_polygon_with_wrong_zs = conditioned_polygon
      else # first floor without garage or above first floor

        if (garage_width * garage_depth > 0)
          garage_se_point = OpenStudio::Point3d.new(garage_se_point.x, garage_se_point.y, z)
          garage_sw_point = OpenStudio::Point3d.new(garage_sw_point.x, garage_sw_point.y, z)
          garage_nw_point = OpenStudio::Point3d.new(garage_nw_point.x, garage_nw_point.y, z)
          garage_ne_point = OpenStudio::Point3d.new(garage_ne_point.x, garage_ne_point.y, z)
          if garage_position == Constants::PositionRight
            sw_point = OpenStudio::Point3d.new(0, 0, z)
            nw_point = OpenStudio::Point3d.new(0, width, z)
            ne_point = OpenStudio::Point3d.new(length, width, z)
            se_point = OpenStudio::Point3d.new(length, 0, z)
            l_se_point = OpenStudio::Point3d.new(length - garage_width, 0, z)
            if garage_protrusion > 0 # garage protrudes
              conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, garage_se_point, garage_sw_point, l_se_point)
            else # garage does not protrude
              conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)
            end
          elsif garage_position == Constants::PositionLeft
            sw_point = OpenStudio::Point3d.new(0, 0, z)
            nw_point = OpenStudio::Point3d.new(0, width, z)
            ne_point = OpenStudio::Point3d.new(length, width, z)
            se_point = OpenStudio::Point3d.new(length, 0, z)
            l_sw_point = OpenStudio::Point3d.new(garage_width, 0, z)
            if garage_protrusion > 0 # garage protrudes
              conditioned_polygon = make_polygon(garage_sw_point, nw_point, ne_point, se_point, l_sw_point, garage_se_point)
            else # garage does not protrude
              conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)
            end
          end

        else

          sw_point = OpenStudio::Point3d.new(0, 0, z)
          nw_point = OpenStudio::Point3d.new(0, width, z)
          ne_point = OpenStudio::Point3d.new(length, width, z)
          se_point = OpenStudio::Point3d.new(length, 0, z)
          conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)
          if z == rim_joist_height
            foundation_polygon_with_wrong_zs = conditioned_polygon
          end

        end

      end

      # make space
      conditioned_space = OpenStudio::Model::Space::fromFloorPrint(conditioned_polygon, average_ceiling_height, model)
      conditioned_space = conditioned_space.get
      assign_indexes(model, footprint_polygon: conditioned_polygon, space: conditioned_space)

      if floor > 0
        conditioned_space_name = "#{HPXML::LocationConditionedSpace} story #{floor + 1}"
      else
        conditioned_space_name = HPXML::LocationConditionedSpace
      end
      conditioned_space.setName(conditioned_space_name)
      conditioned_space_type = OpenStudio::Model::SpaceType.new(model)
      conditioned_space_type.setStandardsSpaceType(HPXML::LocationConditionedSpace)
      conditioned_space.setSpaceType(conditioned_space_type)

      # set these to the conditioned zone
      conditioned_space.setThermalZone(conditioned_zone)

      m = initialize_transformation_matrix()
      m[2, 3] = z
      conditioned_space.changeTransformation(OpenStudio::Transformation.new(m))
    end

    # Attic
    if attic_type != HPXML::AtticTypeFlatRoof

      z += average_ceiling_height

      # calculate the dimensions of the attic
      if length >= width
        attic_height = (width / 2.0) * roof_pitch
      else
        attic_height = (length / 2.0) * roof_pitch
      end

      # make points
      roof_nw_point = OpenStudio::Point3d.new(0, width, z)
      roof_ne_point = OpenStudio::Point3d.new(length, width, z)
      roof_se_point = OpenStudio::Point3d.new(length, 0, z)
      roof_sw_point = OpenStudio::Point3d.new(0, 0, z)

      # make polygons
      polygon_floor = make_polygon(roof_nw_point, roof_ne_point, roof_se_point, roof_sw_point)
      side_type = nil
      case roof_type
      when Constants::RoofTypeGable
        if length >= width
          roof_w_point = OpenStudio::Point3d.new(0, width / 2.0, z + attic_height)
          roof_e_point = OpenStudio::Point3d.new(length, width / 2.0, z + attic_height)
          polygon_s_roof = make_polygon(roof_e_point, roof_w_point, roof_sw_point, roof_se_point)
          polygon_n_roof = make_polygon(roof_w_point, roof_e_point, roof_ne_point, roof_nw_point)
          polygon_w_wall = make_polygon(roof_w_point, roof_nw_point, roof_sw_point)
          polygon_e_wall = make_polygon(roof_e_point, roof_se_point, roof_ne_point)
        else
          roof_w_point = OpenStudio::Point3d.new(length / 2.0, 0, z + attic_height)
          roof_e_point = OpenStudio::Point3d.new(length / 2.0, width, z + attic_height)
          polygon_s_roof = make_polygon(roof_e_point, roof_w_point, roof_se_point, roof_ne_point)
          polygon_n_roof = make_polygon(roof_w_point, roof_e_point, roof_nw_point, roof_sw_point)
          polygon_w_wall = make_polygon(roof_w_point, roof_sw_point, roof_se_point)
          polygon_e_wall = make_polygon(roof_e_point, roof_ne_point, roof_nw_point)
        end
        side_type = EPlus::SurfaceTypeWall
      when Constants::RoofTypeHip
        if length >= width
          roof_w_point = OpenStudio::Point3d.new(width / 2.0, width / 2.0, z + attic_height)
          roof_e_point = OpenStudio::Point3d.new(length - width / 2.0, width / 2.0, z + attic_height)
          polygon_s_roof = make_polygon(roof_e_point, roof_w_point, roof_sw_point, roof_se_point)
          polygon_n_roof = make_polygon(roof_w_point, roof_e_point, roof_ne_point, roof_nw_point)
          polygon_w_wall = make_polygon(roof_w_point, roof_nw_point, roof_sw_point)
          polygon_e_wall = make_polygon(roof_e_point, roof_se_point, roof_ne_point)
        else
          roof_w_point = OpenStudio::Point3d.new(length / 2.0, length / 2.0, z + attic_height)
          roof_e_point = OpenStudio::Point3d.new(length / 2.0, width - length / 2.0, z + attic_height)
          polygon_s_roof = make_polygon(roof_e_point, roof_w_point, roof_se_point, roof_ne_point)
          polygon_n_roof = make_polygon(roof_w_point, roof_e_point, roof_nw_point, roof_sw_point)
          polygon_w_wall = make_polygon(roof_w_point, roof_sw_point, roof_se_point)
          polygon_e_wall = make_polygon(roof_e_point, roof_ne_point, roof_nw_point)
        end
        side_type = EPlus::SurfaceTypeRoofCeiling
      end

      # make surfaces
      surface_floor = create_surface(model, polygon_floor)
      surface_floor.setSurfaceType(EPlus::SurfaceTypeFloor)
      surface_floor.setOutsideBoundaryCondition(EPlus::BoundaryConditionSurface)
      surface_n_roof = create_surface(model, polygon_n_roof)
      surface_n_roof.setSurfaceType(EPlus::SurfaceTypeRoofCeiling)
      surface_n_roof.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)
      surface_e_wall = create_surface(model, polygon_e_wall)
      surface_e_wall.setSurfaceType(side_type)
      surface_e_wall.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)
      surface_s_roof = create_surface(model, polygon_s_roof)
      surface_s_roof.setSurfaceType(EPlus::SurfaceTypeRoofCeiling)
      surface_s_roof.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)
      surface_w_wall = create_surface(model, polygon_w_wall)
      surface_w_wall.setSurfaceType(side_type)
      surface_w_wall.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)

      # assign surfaces to the space
      attic_space = create_space(model)
      surface_floor.setSpace(attic_space)
      surface_s_roof.setSpace(attic_space)
      surface_n_roof.setSpace(attic_space)
      surface_w_wall.setSpace(attic_space)
      surface_e_wall.setSpace(attic_space)

      # set these to the attic zone
      case attic_type
      when HPXML::AtticTypeVented, HPXML::AtticTypeUnvented
        # create attic zone
        attic_zone = OpenStudio::Model::ThermalZone.new(model)
        attic_space.setThermalZone(attic_zone)
        if attic_type == HPXML::AtticTypeVented
          attic_space_name = HPXML::LocationAtticVented
        elsif attic_type == HPXML::AtticTypeUnvented
          attic_space_name = HPXML::LocationAtticUnvented
        end
        attic_zone.setName(attic_space_name)
      when HPXML::AtticTypeConditioned
        attic_space.setThermalZone(conditioned_zone)
        attic_space_name = HPXML::LocationConditionedSpace
      end
      attic_space.setName(attic_space_name)
      attic_space_type = OpenStudio::Model::SpaceType.new(model)
      attic_space_type.setStandardsSpaceType(attic_space_name)
      attic_space.setSpaceType(attic_space_type)

      m = initialize_transformation_matrix()
      m[2, 3] = z
      attic_space.changeTransformation(OpenStudio::Transformation.new(m))

    end

    # Foundation
    if [HPXML::FoundationTypeCrawlspaceVented,
        HPXML::FoundationTypeCrawlspaceUnvented,
        HPXML::FoundationTypeCrawlspaceConditioned,
        HPXML::FoundationTypeBasementUnconditioned,
        HPXML::FoundationTypeBasementConditioned,
        HPXML::FoundationTypeAmbient].include?(foundation_type) || foundation_type.start_with?(HPXML::FoundationTypeBellyAndWing)

      z = -foundation_height

      # create foundation zone
      foundation_zone = OpenStudio::Model::ThermalZone.new(model)

      # make polygons
      p = OpenStudio::Point3dVector.new
      foundation_polygon_with_wrong_zs.each do |point|
        p << OpenStudio::Point3d.new(point.x, point.y, z)
      end
      foundation_polygon = p

      # make space
      foundation_space = OpenStudio::Model::Space::fromFloorPrint(foundation_polygon, foundation_height, model)
      foundation_space = foundation_space.get
      assign_indexes(model, footprint_polygon: foundation_polygon, space: foundation_space)
      case foundation_type
      when HPXML::FoundationTypeCrawlspaceVented
        foundation_space_name = HPXML::LocationCrawlspaceVented
      when HPXML::FoundationTypeCrawlspaceUnvented
        foundation_space_name = HPXML::LocationCrawlspaceUnvented
      when HPXML::FoundationTypeCrawlspaceConditioned
        foundation_space_name = HPXML::LocationCrawlspaceConditioned
      when HPXML::FoundationTypeBasementUnconditioned
        foundation_space_name = HPXML::LocationBasementUnconditioned
      when HPXML::FoundationTypeBasementConditioned
        foundation_space_name = HPXML::LocationBasementConditioned
      when HPXML::FoundationTypeAmbient
        foundation_space_name = HPXML::LocationOutside
      else
        if foundation_type.start_with? HPXML::FoundationTypeBellyAndWing
          foundation_space_name = HPXML::LocationManufacturedHomeUnderBelly
        end
      end
      foundation_zone.setName(foundation_space_name)
      foundation_space.setName(foundation_space_name)
      foundation_space_type = OpenStudio::Model::SpaceType.new(model)
      foundation_space_type.setStandardsSpaceType(foundation_space_name)
      foundation_space.setSpaceType(foundation_space_type)

      # set these to the foundation zone
      foundation_space.setThermalZone(foundation_zone)

      # set foundation walls outside boundary condition
      spaces = model.getSpaces
      spaces.each do |space|
        next unless get_space_floor_z(space) + UnitConversions.convert(space.zOrigin, 'm', 'ft') < 0

        surfaces = space.surfaces
        surfaces.each do |surface|
          next if surface.surfaceType != EPlus::SurfaceTypeWall

          surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionGround)
        end
      end

      m = initialize_transformation_matrix()
      m[2, 3] = z
      foundation_space.changeTransformation(OpenStudio::Transformation.new(m))

      # Rim Joist
      add_rim_joist(model, polygon: foundation_polygon_with_wrong_zs, space: foundation_space, rim_joist_height: rim_joist_height, z: foundation_height)
    end

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end

    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)

    if (garage_width * garage_depth > 0) && attic_type != HPXML::AtticTypeFlatRoof
      if num_floors > 1
        space_with_roof_over_garage = conditioned_space
      else
        space_with_roof_over_garage = garage_space
      end
      space_with_roof_over_garage.surfaces.each do |surface|
        next unless (surface.surfaceType == EPlus::SurfaceTypeRoofCeiling) && (surface.outsideBoundaryCondition == EPlus::BoundaryConditionOutdoors)

        n_points = []
        s_points = []
        surface.vertices.each do |vertex|
          if vertex.y.abs < 0.00001
            n_points << vertex
          elsif vertex.y < 0
            s_points << vertex
          end
        end
        if n_points[0].x > n_points[1].x
          nw_point = n_points[1]
          ne_point = n_points[0]
        else
          nw_point = n_points[0]
          ne_point = n_points[1]
        end
        if s_points[0].x > s_points[1].x
          sw_point = s_points[1]
          se_point = s_points[0]
        else
          sw_point = s_points[0]
          se_point = s_points[1]
        end

        if num_floors == 1
          nw_point = OpenStudio::Point3d.new(nw_point.x, nw_point.y, conditioned_space.zOrigin + nw_point.z)
          ne_point = OpenStudio::Point3d.new(ne_point.x, ne_point.y, conditioned_space.zOrigin + ne_point.z)
          sw_point = OpenStudio::Point3d.new(sw_point.x, sw_point.y, conditioned_space.zOrigin + sw_point.z)
          se_point = OpenStudio::Point3d.new(se_point.x, se_point.y, conditioned_space.zOrigin + se_point.z)
        else
          nw_point = OpenStudio::Point3d.new(nw_point.x, nw_point.y, num_floors * nw_point.z + rim_joist_height)
          ne_point = OpenStudio::Point3d.new(ne_point.x, ne_point.y, num_floors * ne_point.z + rim_joist_height)
          sw_point = OpenStudio::Point3d.new(sw_point.x, sw_point.y, num_floors * sw_point.z + rim_joist_height)
          se_point = OpenStudio::Point3d.new(se_point.x, se_point.y, num_floors * se_point.z + rim_joist_height)
        end

        garage_attic_height = (ne_point.x - nw_point.x) / 2 * roof_pitch

        if garage_attic_height >= attic_height
          garage_attic_height = attic_height - 0.01 # garage attic height slightly below attic height so that we don't get any roof decks with only three vertices
          garage_roof_pitch = garage_attic_height / (garage_width / 2)
          runner.registerWarning("The garage pitch was changed to accommodate garage ridge >= house ridge (from #{roof_pitch.round(3)} to #{garage_roof_pitch.round(3)}).")
        end

        if num_floors == 1
          if attic_type != HPXML::AtticTypeConditioned
            roof_n_point = OpenStudio::Point3d.new((nw_point.x + ne_point.x) / 2, nw_point.y + garage_attic_height / roof_pitch, conditioned_space.zOrigin + average_ceiling_height + garage_attic_height)
            roof_s_point = OpenStudio::Point3d.new((sw_point.x + se_point.x) / 2, sw_point.y, conditioned_space.zOrigin + average_ceiling_height + garage_attic_height)
          else
            roof_n_point = OpenStudio::Point3d.new((nw_point.x + ne_point.x) / 2, nw_point.y + garage_attic_height / roof_pitch, garage_attic_height + average_ceiling_height)
            roof_s_point = OpenStudio::Point3d.new((sw_point.x + se_point.x) / 2, sw_point.y, garage_attic_height + average_ceiling_height)
          end
        else
          roof_n_point = OpenStudio::Point3d.new((nw_point.x + ne_point.x) / 2, nw_point.y + garage_attic_height / roof_pitch, num_floors * average_ceiling_height + garage_attic_height + rim_joist_height)
          roof_s_point = OpenStudio::Point3d.new((sw_point.x + se_point.x) / 2, sw_point.y, num_floors * average_ceiling_height + garage_attic_height + rim_joist_height)
        end

        polygon_w_roof = make_polygon(nw_point, sw_point, roof_s_point, roof_n_point)
        polygon_e_roof = make_polygon(ne_point, roof_n_point, roof_s_point, se_point)
        polygon_n_wall = make_polygon(nw_point, roof_n_point, ne_point)
        polygon_s_wall = make_polygon(sw_point, se_point, roof_s_point)

        wall_n = create_surface(model, polygon_n_wall)
        wall_n.setSurfaceType(EPlus::SurfaceTypeWall)
        deck_e = create_surface(model, polygon_e_roof)
        deck_e.setSurfaceType(EPlus::SurfaceTypeRoofCeiling)
        deck_e.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)
        wall_s = create_surface(model, polygon_s_wall)
        wall_s.setSurfaceType(EPlus::SurfaceTypeWall)
        wall_s.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)
        deck_w = create_surface(model, polygon_w_roof)
        deck_w.setSurfaceType(EPlus::SurfaceTypeRoofCeiling)
        deck_w.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)

        garage_attic_space = create_space(model)
        deck_w.setSpace(garage_attic_space)
        deck_e.setSpace(garage_attic_space)
        wall_n.setSpace(garage_attic_space)
        wall_s.setSpace(garage_attic_space)

        if attic_type == HPXML::AtticTypeConditioned
          garage_attic_space_name = attic_space_name
          garage_attic_space.setThermalZone(conditioned_zone)
        else
          if num_floors > 1
            garage_attic_space_name = attic_space_name
            garage_attic_space.setThermalZone(attic_zone)
          else
            garage_attic_space_name = garage_space_name
            garage_attic_space.setThermalZone(garage_zone)
          end
        end

        surface.createAdjacentSurface(garage_attic_space) # garage attic floor
        surface.adjacentSurface.get.additionalProperties.setFeature('Index', indexer(model))
        garage_attic_space.setName(garage_attic_space_name)
        garage_attic_space_type = OpenStudio::Model::SpaceType.new(model)
        garage_attic_space_type.setStandardsSpaceType(garage_attic_space_name)
        garage_attic_space.setSpaceType(garage_attic_space_type)

        # put all of the spaces in the model into a vector
        spaces = OpenStudio::Model::SpaceVector.new
        model.getSpaces.each do |space|
          spaces << space
        end

        # intersect and match surfaces for each space in the vector
        OpenStudio::Model.intersectSurfaces(spaces)
        OpenStudio::Model.matchSurfaces(spaces)

        # remove triangular surface between unconditioned attic and garage attic
        unless attic_space.nil?
          attic_space.surfaces.each do |surface|
            next if roof_type == Constants::RoofTypeHip
            next unless surface.vertices.length == 3
            next unless (90 - surface.tilt * 180 / Math::PI).abs > 0.01 # don't remove the vertical attic walls
            next unless surface.adjacentSurface.is_initialized

            surface.adjacentSurface.get.remove
            surface.remove
          end
        end

        garage_attic_space.surfaces.each do |surface|
          m = initialize_transformation_matrix()
          m[2, 3] = -attic_space.zOrigin
          transformation = OpenStudio::Transformation.new(m)
          new_vertices = transformation * surface.vertices
          surface.setVertices(new_vertices)
          surface.setSpace(attic_space)
        end

        garage_attic_space.remove

        # remove other unused surfaces
        # FUTURE: remove this once geometry methods are fixed in openstudio 3.x
        attic_space.surfaces.each do |surface1|
          next if surface1.surfaceType != EPlus::SurfaceTypeRoofCeiling

          attic_space.surfaces.each do |surface2|
            next if surface2.surfaceType != EPlus::SurfaceTypeRoofCeiling
            next if surface1 == surface2

            if has_same_vertices(surface1, surface2)
              surface1.remove
              surface2.remove
            end
          end
        end

        break
      end
    end

    garage_spaces = get_garage_spaces(model.getSpaces)

    # set foundation outside boundary condition to Kiva "foundation"
    model.getSurfaces.each do |surface|
      if surface.outsideBoundaryCondition == EPlus::BoundaryConditionGround
        surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionFoundation) if foundation_type != HPXML::FoundationTypeAmbient
        surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors) if foundation_type == HPXML::FoundationTypeAmbient
      elsif (UnitConversions.convert(rim_joist_height, 'm', 'ft') - get_surface_height(surface)).abs < 0.001
        next if surface.surfaceType != EPlus::SurfaceTypeWall

        garage_spaces.each do |garage_space|
          garage_space.surfaces.each do |garage_surface|
            next if garage_surface.surfaceType != EPlus::SurfaceTypeFloor

            if get_walls_connected_to_floor(wall_surfaces: [surface], floor_surface: garage_surface, same_space: false).include? surface
              surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionFoundation) if foundation_type != HPXML::FoundationTypeAmbient
              surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors) if foundation_type == HPXML::FoundationTypeAmbient
            end
          end
        end
      end
    end

    # set foundation walls adjacent to garage to adiabatic
    foundation_walls = []
    model.getSurfaces.each do |surface|
      next if surface.surfaceType != EPlus::SurfaceTypeWall
      next if surface.outsideBoundaryCondition != EPlus::BoundaryConditionFoundation

      foundation_walls << surface
    end

    garage_spaces.each do |garage_space|
      garage_space.surfaces.each do |surface|
        next if surface.surfaceType != EPlus::SurfaceTypeFloor

        adjacent_wall_surfaces = get_walls_connected_to_floor(wall_surfaces: foundation_walls, floor_surface: surface, same_space: false)
        adjacent_wall_surfaces.each do |adjacent_wall_surface|
          adjacent_wall_surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionAdiabatic)
        end
      end
    end

    assign_remaining_surface_indexes(model)

    apply_ambient_foundation_shift(model, foundation_type: foundation_type, foundation_height: foundation_height)

    return true
  end

  # Create a 3D representation of a single-family attached home using the following arguments.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param geometry_unit_cfa [Double] conditioned floor area (ft2)
  # @param geometry_average_ceiling_height [Double] average ceiling height (ft)
  # @param geometry_unit_num_floors_above_grade [Integer] number of floors above grade
  # @param geometry_unit_aspect_ratio [Double] ratio of front/back wall length to left/right wall length (frac)
  # @param geometry_foundation_type [String] foundation type of the building
  # @param geometry_foundation_height [Double] height of the foundation (ft)
  # @param geometry_rim_joist_height [Double] height of the rim joists (ft)
  # @param geometry_attic_type [String] attic type of the building
  # @param geometry_roof_type [String] roof type of the building
  # @param geometry_roof_pitch [Double] ratio of vertical rise to horizontal run (frac)
  # @param geometry_unit_left_wall_is_adiabatic [Boolean] presence of an adiabatic left wall
  # @param geometry_unit_right_wall_is_adiabatic [Boolean] presence of an adiabatic right wall
  # @param geometry_unit_front_wall_is_adiabatic [Boolean] presence of an adiabatic front wall
  # @param geometry_unit_back_wall_is_adiabatic [Boolean] presence of an adiabatic back wall
  # @return [Boolean] true if model is successfully updated with a single-family attached unit
  def self.create_single_family_attached(model,
                                         geometry_unit_cfa:,
                                         geometry_average_ceiling_height:,
                                         geometry_unit_num_floors_above_grade:,
                                         geometry_unit_aspect_ratio:,
                                         geometry_foundation_type:,
                                         geometry_foundation_height:,
                                         geometry_rim_joist_height:,
                                         geometry_attic_type:,
                                         geometry_roof_type:,
                                         geometry_roof_pitch:,
                                         geometry_unit_left_wall_is_adiabatic:,
                                         geometry_unit_right_wall_is_adiabatic:,
                                         geometry_unit_front_wall_is_adiabatic:,
                                         geometry_unit_back_wall_is_adiabatic:,
                                         **)

    cfa = geometry_unit_cfa
    average_ceiling_height = geometry_average_ceiling_height
    num_floors = geometry_unit_num_floors_above_grade
    aspect_ratio = geometry_unit_aspect_ratio
    foundation_type = geometry_foundation_type
    foundation_height = geometry_foundation_height
    rim_joist_height = geometry_rim_joist_height
    attic_type = geometry_attic_type
    if attic_type == HPXML::AtticTypeConditioned
      num_floors -= 1
    end
    roof_type = geometry_roof_type
    roof_pitch = geometry_roof_pitch
    adiabatic_left_wall = geometry_unit_left_wall_is_adiabatic
    adiabatic_right_wall = geometry_unit_right_wall_is_adiabatic
    adiabatic_front_wall = geometry_unit_front_wall_is_adiabatic
    adiabatic_back_wall = geometry_unit_back_wall_is_adiabatic

    # Convert to SI
    cfa = UnitConversions.convert(cfa, 'ft^2', 'm^2')
    average_ceiling_height = UnitConversions.convert(average_ceiling_height, 'ft', 'm')
    foundation_height = UnitConversions.convert(foundation_height, 'ft', 'm')
    rim_joist_height = UnitConversions.convert(rim_joist_height, 'ft', 'm')

    if (foundation_type == HPXML::FoundationTypeBasementConditioned) && (attic_type == HPXML::AtticTypeConditioned)
      footprint = cfa / (num_floors + 2)
    elsif (foundation_type == HPXML::FoundationTypeBasementConditioned) || (attic_type == HPXML::AtticTypeConditioned)
      footprint = cfa / (num_floors + 1)
    else
      footprint = cfa / num_floors
    end

    # calculate the dimensions of the unit
    # we have: (1) aspect_ratio = fb / lr, and (2) footprint = fb * lr
    fb = Math.sqrt(footprint * aspect_ratio)
    lr = footprint / fb
    x = fb
    y = lr

    # create the prototype unit footprint
    nw_point = OpenStudio::Point3d.new(0, 0, rim_joist_height)
    ne_point = OpenStudio::Point3d.new(x, 0, rim_joist_height)
    sw_point = OpenStudio::Point3d.new(0, -y, rim_joist_height)
    se_point = OpenStudio::Point3d.new(x, -y, rim_joist_height)
    conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)

    # foundation
    foundation_polygon = nil
    if (foundation_height > 0) && foundation_polygon.nil?
      foundation_polygon = conditioned_polygon
    end

    # create conditioned zone
    conditioned_zone = OpenStudio::Model::ThermalZone.new(model)
    conditioned_zone.setName(HPXML::LocationConditionedSpace)

    # first floor
    conditioned_space = OpenStudio::Model::Space::fromFloorPrint(conditioned_polygon, average_ceiling_height, model)
    conditioned_space = conditioned_space.get
    assign_indexes(model, footprint_polygon: conditioned_polygon, space: conditioned_space)
    conditioned_space.setName(HPXML::LocationConditionedSpace)
    conditioned_space_type = OpenStudio::Model::SpaceType.new(model)
    conditioned_space_type.setStandardsSpaceType(HPXML::LocationConditionedSpace)
    conditioned_space.setSpaceType(conditioned_space_type)
    conditioned_space.setThermalZone(conditioned_zone)

    # Adiabatic surfaces for walls
    adb_facade_hash = { Constants::FacadeLeft => adiabatic_left_wall, Constants::FacadeRight => adiabatic_right_wall, Constants::FacadeFront => adiabatic_front_wall, Constants::FacadeBack => adiabatic_back_wall }
    adb_facades = adb_facade_hash.select { |_, v| v == true }.keys

    # Make surfaces adiabatic
    model.getSpaces.each do |space|
      space.surfaces.each do |surface|
        os_facade = get_surface_facade(surface)
        next unless surface.surfaceType == EPlus::SurfaceTypeWall
        next unless adb_facades.include? os_facade

        x_ft = UnitConversions.convert(x, 'm', 'ft')
        max_x = get_surface_x_values(surfaceArray: [surface]).max
        min_x = get_surface_x_values(surfaceArray: [surface]).min
        next if ((max_x - x_ft).abs >= 0.01) && (min_x > 0)

        surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionAdiabatic)
      end
    end

    # additional floors
    for story in 2..num_floors
      new_conditioned_space = conditioned_space.clone.to_Space.get
      assign_indexes(model, footprint_polygon: conditioned_polygon, space: new_conditioned_space)
      new_conditioned_space.setName("conditioned space|story #{story}")
      new_conditioned_space.setSpaceType(conditioned_space_type)

      m = initialize_transformation_matrix()
      m[2, 3] = average_ceiling_height * (story - 1)
      new_conditioned_space.setTransformation(OpenStudio::Transformation.new(m))
      new_conditioned_space.setThermalZone(conditioned_zone)
    end

    # attic
    attic_spaces = []
    if attic_type != HPXML::AtticTypeFlatRoof
      attic_space = get_attic_space(model, x: x, y: y, average_ceiling_height: average_ceiling_height, num_floors: num_floors, roof_pitch: roof_pitch, roof_type: roof_type, rim_joist_height: rim_joist_height)
      if attic_type == HPXML::AtticTypeConditioned
        attic_space_name = HPXML::LocationConditionedSpace
        attic_space.setName(attic_space_name)
        attic_space.setThermalZone(conditioned_zone)
        attic_space.setSpaceType(conditioned_space_type)
        attic_space_type = OpenStudio::Model::SpaceType.new(model)
        attic_space_type.setStandardsSpaceType(attic_space_name)
      else
        attic_spaces << attic_space
      end
    end

    # foundation
    if foundation_height > 0

      # foundation front
      foundation_space = OpenStudio::Model::Space::fromFloorPrint(foundation_polygon, foundation_height, model)
      foundation_space = foundation_space.get
      assign_indexes(model, footprint_polygon: foundation_polygon, space: foundation_space)
      m = initialize_transformation_matrix()
      m[2, 3] = foundation_height
      foundation_space.changeTransformation(OpenStudio::Transformation.new(m))
      foundation_space.setXOrigin(0)
      foundation_space.setYOrigin(0)
      foundation_space.setZOrigin(0)

      # create foundation zone
      foundation_zone = OpenStudio::Model::ThermalZone.new(model)

      case foundation_type
      when HPXML::FoundationTypeCrawlspaceVented
        foundation_space_name = HPXML::LocationCrawlspaceVented
      when HPXML::FoundationTypeCrawlspaceUnvented
        foundation_space_name = HPXML::LocationCrawlspaceUnvented
      when HPXML::FoundationTypeCrawlspaceConditioned
        foundation_space_name = HPXML::LocationCrawlspaceConditioned
      when HPXML::FoundationTypeBasementUnconditioned
        foundation_space_name = HPXML::LocationBasementUnconditioned
      when HPXML::FoundationTypeBasementConditioned
        foundation_space_name = HPXML::LocationBasementConditioned
      when HPXML::FoundationTypeAmbient
        foundation_space_name = HPXML::LocationOutside
      end
      foundation_zone.setName(foundation_space_name)
      foundation_space.setName(foundation_space_name)
      foundation_space_type = OpenStudio::Model::SpaceType.new(model)
      foundation_space_type.setStandardsSpaceType(foundation_space_name)
      foundation_space.setSpaceType(foundation_space_type)

      # set these to the foundation zone
      foundation_space.setThermalZone(foundation_zone)

      # Rim Joist
      add_rim_joist(model, polygon: foundation_polygon, space: foundation_space, rim_joist_height: rim_joist_height, z: 0)

      # put all of the spaces in the model into a vector
      spaces = OpenStudio::Model::SpaceVector.new
      model.getSpaces.each do |space|
        spaces << space
      end

      # intersect and match surfaces for each space in the vector
      OpenStudio::Model.intersectSurfaces(spaces)
      OpenStudio::Model.matchSurfaces(spaces)

      # Foundation space boundary conditions
      spaces = model.getSpaces
      spaces.each do |space|
        next unless get_space_floor_z(space) + UnitConversions.convert(space.zOrigin, 'm', 'ft') < 0

        surfaces = space.surfaces
        surfaces.each do |surface|
          next if surface.surfaceType != EPlus::SurfaceTypeWall

          os_facade = get_surface_facade(surface)
          if adb_facades.include? os_facade
            surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionAdiabatic)
          elsif get_surface_z_values(surfaceArray: [surface]).min < 0
            surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionFoundation) if foundation_type != HPXML::FoundationTypeAmbient
            surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors) if foundation_type == HPXML::FoundationTypeAmbient
          else
            surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)
          end
        end
      end

    end

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end

    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)

    if [HPXML::AtticTypeVented, HPXML::AtticTypeUnvented].include?(attic_type)
      attic_spaces.each do |attic_space|
        attic_space.remove
      end
      attic_space = get_attic_space(model, x: x, y: y, average_ceiling_height: average_ceiling_height, num_floors: num_floors, roof_pitch: roof_pitch, roof_type: roof_type, rim_joist_height: rim_joist_height)

      # set these to the attic zone
      case attic_type
      when HPXML::AtticTypeVented, HPXML::AtticTypeUnvented
        # create attic zone
        attic_zone = OpenStudio::Model::ThermalZone.new(model)
        attic_space.setThermalZone(attic_zone)
        if attic_type == HPXML::AtticTypeVented
          attic_space_name = HPXML::LocationAtticVented
        elsif attic_type == HPXML::AtticTypeUnvented
          attic_space_name = HPXML::LocationAtticUnvented
        end
        attic_zone.setName(attic_space_name)
      end
      attic_space.setName(attic_space_name)
      attic_space_type = OpenStudio::Model::SpaceType.new(model)
      attic_space_type.setStandardsSpaceType(attic_space_name)
      attic_space.setSpaceType(attic_space_type)
    end

    # Adiabatic gable walls
    if [HPXML::AtticTypeVented, HPXML::AtticTypeUnvented, HPXML::AtticTypeConditioned].include? attic_type
      attic_space.surfaces.each do |surface|
        os_facade = get_surface_facade(surface)
        next unless surface.surfaceType == EPlus::SurfaceTypeWall
        next unless adb_facades.include? os_facade

        x_ft = UnitConversions.convert(x, 'm', 'ft')
        max_x = get_surface_x_values(surfaceArray: [surface]).max
        min_x = get_surface_x_values(surfaceArray: [surface]).min
        next if ((max_x - x_ft).abs >= 0.01) && (min_x > 0)

        surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionAdiabatic)
      end
    end

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end

    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)

    # set foundation outside boundary condition to Kiva "foundation"
    model.getSurfaces.each do |surface|
      next if surface.outsideBoundaryCondition != EPlus::BoundaryConditionGround

      surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionFoundation) if foundation_type != HPXML::FoundationTypeAmbient
      surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors) if foundation_type == HPXML::FoundationTypeAmbient
    end

    assign_remaining_surface_indexes(model)

    apply_ambient_foundation_shift(model, foundation_type: foundation_type, foundation_height: foundation_height)

    return true
  end

  # Create a 3D representation of an apartment (dwelling unit in a multifamily building) home using the following arguments.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param geometry_unit_cfa [Double] conditioned floor area (ft2)
  # @param geometry_average_ceiling_height [Double] average ceiling height (ft)
  # @param geometry_unit_num_floors_above_grade [Integer] number of floors above grade
  # @param geometry_unit_aspect_ratio [Double] ratio of front/back wall length to left/right wall length (frac)
  # @param geometry_foundation_type [String] foundation type of the building
  # @param geometry_foundation_height [Double] height of the foundation (ft)
  # @param geometry_rim_joist_height [Double] height of the rim joists (ft)
  # @param geometry_attic_type [String] attic type of the building
  # @param geometry_roof_type [String] roof type of the building
  # @param geometry_roof_pitch [Double] ratio of vertical rise to horizontal run (frac)
  # @param geometry_unit_left_wall_is_adiabatic [Boolean] presence of an adiabatic left wall
  # @param geometry_unit_right_wall_is_adiabatic [Boolean] presence of an adiabatic right wall
  # @param geometry_unit_front_wall_is_adiabatic [Boolean] presence of an adiabatic front wall
  # @param geometry_unit_back_wall_is_adiabatic [Boolean] presence of an adiabatic back wall
  # @return [Boolean] true if model is successfully updated with an apartment unit
  def self.create_apartment(model,
                            geometry_unit_cfa:,
                            geometry_average_ceiling_height:,
                            geometry_unit_num_floors_above_grade:,
                            geometry_unit_aspect_ratio:,
                            geometry_foundation_type:,
                            geometry_foundation_height:,
                            geometry_rim_joist_height:,
                            geometry_attic_type:,
                            geometry_roof_type:,
                            geometry_roof_pitch:,
                            geometry_unit_left_wall_is_adiabatic:,
                            geometry_unit_right_wall_is_adiabatic:,
                            geometry_unit_front_wall_is_adiabatic:,
                            geometry_unit_back_wall_is_adiabatic:,
                            **)

    cfa = geometry_unit_cfa
    average_ceiling_height = geometry_average_ceiling_height
    num_floors = geometry_unit_num_floors_above_grade
    aspect_ratio = geometry_unit_aspect_ratio
    foundation_type = geometry_foundation_type
    foundation_height = geometry_foundation_height
    rim_joist_height = geometry_rim_joist_height
    attic_type = geometry_attic_type
    roof_type = geometry_roof_type
    roof_pitch = geometry_roof_pitch
    adiabatic_left_wall = geometry_unit_left_wall_is_adiabatic
    adiabatic_right_wall = geometry_unit_right_wall_is_adiabatic
    adiabatic_front_wall = geometry_unit_front_wall_is_adiabatic
    adiabatic_back_wall = geometry_unit_back_wall_is_adiabatic

    if foundation_type == HPXML::FoundationTypeAboveApartment
      foundation_type = HPXML::LocationOtherHousingUnit
      foundation_height = 0.0
      rim_joist_height = 0.0
    end
    if attic_type == HPXML::AtticTypeBelowApartment
      attic_type = HPXML::LocationOtherHousingUnit
    end

    # Convert to SI
    cfa = UnitConversions.convert(cfa, 'ft^2', 'm^2')
    average_ceiling_height = UnitConversions.convert(average_ceiling_height, 'ft', 'm')
    foundation_height = UnitConversions.convert(foundation_height, 'ft', 'm')
    rim_joist_height = UnitConversions.convert(rim_joist_height, 'ft', 'm')

    # calculate the dimensions of the unit
    # we have: (1) aspect_ratio = fb / lr, and (2) footprint = fb * lr
    footprint = cfa
    fb = Math.sqrt(footprint * aspect_ratio)
    lr = footprint / fb
    x = fb
    y = lr

    foundation_polygon = nil

    # create the prototype unit footprint
    nw_point = OpenStudio::Point3d.new(0, 0, rim_joist_height)
    ne_point = OpenStudio::Point3d.new(x, 0, rim_joist_height)
    sw_point = OpenStudio::Point3d.new(0, -y, rim_joist_height)
    se_point = OpenStudio::Point3d.new(x, -y, rim_joist_height)
    conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)

    # foundation
    if (foundation_height > 0) && foundation_polygon.nil?
      foundation_polygon = conditioned_polygon
    end

    # create conditioned zone
    conditioned_zone = OpenStudio::Model::ThermalZone.new(model)
    conditioned_zone.setName(HPXML::LocationConditionedSpace)

    # first floor
    conditioned_space = OpenStudio::Model::Space::fromFloorPrint(conditioned_polygon, average_ceiling_height, model)
    conditioned_space = conditioned_space.get
    assign_indexes(model, footprint_polygon: conditioned_polygon, space: conditioned_space)
    conditioned_space.setName(HPXML::LocationConditionedSpace)
    conditioned_space_type = OpenStudio::Model::SpaceType.new(model)
    conditioned_space_type.setStandardsSpaceType(HPXML::LocationConditionedSpace)
    conditioned_space.setSpaceType(conditioned_space_type)
    conditioned_space.setThermalZone(conditioned_zone)

    # Map surface facades to adiabatic walls
    adb_facade_hash = { Constants::FacadeLeft => adiabatic_left_wall, Constants::FacadeRight => adiabatic_right_wall, Constants::FacadeFront => adiabatic_front_wall, Constants::FacadeBack => adiabatic_back_wall }
    adb_facades = adb_facade_hash.select { |_, v| v == true }.keys

    # Adiabatic floor/ceiling
    adb_levels = []
    if attic_type == HPXML::LocationOtherHousingUnit
      adb_levels.concat([EPlus::SurfaceTypeRoofCeiling])
    end
    if foundation_type == HPXML::LocationOtherHousingUnit
      adb_levels.concat([EPlus::SurfaceTypeFloor])
    end

    # Make conditioned space surfaces adiabatic
    model.getSpaces.each do |space|
      space.surfaces.each do |surface|
        os_facade = get_surface_facade(surface)
        if surface.surfaceType == EPlus::SurfaceTypeWall
          if adb_facades.include? os_facade
            x_ft = UnitConversions.convert(x, 'm', 'ft')
            max_x = get_surface_x_values(surfaceArray: [surface]).max
            min_x = get_surface_x_values(surfaceArray: [surface]).min
            next if ((max_x - x_ft).abs >= 0.01) && (min_x > 0)

            surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionAdiabatic)
          end
        else
          if (adb_levels.include? surface.surfaceType)
            surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionAdiabatic)
          end
        end
      end
    end

    # attic
    attic_spaces = []
    if [HPXML::AtticTypeVented, HPXML::AtticTypeUnvented].include? attic_type
      attic_space = get_attic_space(model, x: x, y: y, average_ceiling_height: average_ceiling_height, num_floors: num_floors, roof_pitch: roof_pitch, roof_type: roof_type, rim_joist_height: rim_joist_height)
      attic_spaces << attic_space
    end

    # foundation
    if foundation_height > 0

      # foundation front
      foundation_space = OpenStudio::Model::Space::fromFloorPrint(foundation_polygon, foundation_height, model)
      foundation_space = foundation_space.get
      assign_indexes(model, footprint_polygon: foundation_polygon, space: foundation_space)
      m = initialize_transformation_matrix()
      m[2, 3] = foundation_height + rim_joist_height
      foundation_space.changeTransformation(OpenStudio::Transformation.new(m))
      foundation_space.setXOrigin(0)
      foundation_space.setYOrigin(0)
      foundation_space.setZOrigin(0)

      # create foundation zone
      foundation_zone = OpenStudio::Model::ThermalZone.new(model)

      case foundation_type
      when HPXML::FoundationTypeCrawlspaceVented
        foundation_space_name = HPXML::LocationCrawlspaceVented
      when HPXML::FoundationTypeCrawlspaceUnvented
        foundation_space_name = HPXML::LocationCrawlspaceUnvented
      when HPXML::FoundationTypeCrawlspaceConditioned
        foundation_space_name = HPXML::LocationCrawlspaceConditioned
      when HPXML::FoundationTypeBasementUnconditioned
        foundation_space_name = HPXML::LocationBasementUnconditioned
      when HPXML::FoundationTypeBasementConditioned
        foundation_space_name = HPXML::LocationBasementConditioned
      when HPXML::FoundationTypeAmbient
        foundation_space_name = HPXML::LocationOutside
      end
      foundation_zone.setName(foundation_space_name)
      foundation_space.setName(foundation_space_name)
      foundation_space_type = OpenStudio::Model::SpaceType.new(model)
      foundation_space_type.setStandardsSpaceType(foundation_space_name)
      foundation_space.setSpaceType(foundation_space_type)

      # set these to the foundation zone
      foundation_space.setThermalZone(foundation_zone)

      # Rim Joist
      add_rim_joist(model, polygon: foundation_polygon, space: foundation_space, rim_joist_height: rim_joist_height, z: 0)

      # put all of the spaces in the model into a vector
      spaces = OpenStudio::Model::SpaceVector.new
      model.getSpaces.each do |space|
        spaces << space
      end

      # intersect and match surfaces for each space in the vector
      OpenStudio::Model.intersectSurfaces(spaces)
      OpenStudio::Model.matchSurfaces(spaces)

      # Foundation space boundary conditions
      model.getSpaces.each do |space|
        next unless get_space_floor_z(space) + UnitConversions.convert(space.zOrigin, 'm', 'ft') < 0 # Foundation

        surfaces = space.surfaces
        surfaces.each do |surface|
          next unless surface.surfaceType == EPlus::SurfaceTypeWall

          os_facade = get_surface_facade(surface)
          if adb_facades.include?(os_facade) && (os_facade != EPlus::SurfaceTypeRoofCeiling) && (os_facade != EPlus::SurfaceTypeFloor)
            surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionAdiabatic)
          elsif get_surface_z_values(surfaceArray: [surface]).min < 0
            surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionFoundation) if foundation_type != HPXML::FoundationTypeAmbient
            surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors) if foundation_type == HPXML::FoundationTypeAmbient
          else
            surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)
          end
        end
      end
    end

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end

    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)

    if [HPXML::AtticTypeVented, HPXML::AtticTypeUnvented].include?(attic_type)
      attic_spaces.each do |attic_space|
        attic_space.remove
      end
      attic_space = get_attic_space(model, x: x, y: y, average_ceiling_height: average_ceiling_height, num_floors: num_floors, roof_pitch: roof_pitch, roof_type: roof_type, rim_joist_height: rim_joist_height)

      # set these to the attic zone
      case attic_type
      when HPXML::AtticTypeVented, HPXML::AtticTypeUnvented
        # create attic zone
        attic_zone = OpenStudio::Model::ThermalZone.new(model)
        attic_space.setThermalZone(attic_zone)
        if attic_type == HPXML::AtticTypeVented
          attic_space_name = HPXML::LocationAtticVented
        elsif attic_type == HPXML::AtticTypeUnvented
          attic_space_name = HPXML::LocationAtticUnvented
        end
        attic_zone.setName(attic_space_name)
      end
      attic_space.setName(attic_space_name)
      attic_space_type = OpenStudio::Model::SpaceType.new(model)
      attic_space_type.setStandardsSpaceType(attic_space_name)
      attic_space.setSpaceType(attic_space_type)

      # Adiabatic surfaces for attic walls
      attic_space.surfaces.each do |surface|
        os_facade = get_surface_facade(surface)
        next unless surface.surfaceType == EPlus::SurfaceTypeWall
        next unless adb_facades.include? os_facade

        x_ft = UnitConversions.convert(x, 'm', 'ft')
        max_x = get_surface_x_values(surfaceArray: [surface]).max
        min_x = get_surface_x_values(surfaceArray: [surface]).min
        next if ((max_x - x_ft).abs >= 0.01) && (min_x > 0)

        surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionAdiabatic)
      end
    end

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end

    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)

    # set foundation outside boundary condition to Kiva "foundation"
    model.getSurfaces.each do |surface|
      next if surface.outsideBoundaryCondition != EPlus::BoundaryConditionGround

      surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionFoundation) if foundation_type != HPXML::FoundationTypeAmbient
      surface.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors) if foundation_type == HPXML::FoundationTypeAmbient
    end

    assign_remaining_surface_indexes(model)

    apply_ambient_foundation_shift(model, foundation_type: foundation_type, foundation_height: foundation_height)

    return true
  end

  # Calculate the overall dimensions (length, width) of the dwelling unit based on garage presence/size/protrusion,
  # foundation/attic type, conditioned floor area, number of floors, and aspect ratio.
  #
  # @param garage_width [Double] width of the garage (m)
  # @param garage_depth [Double] depth of the garage (m)
  # @param garage_protrusion [Double] fraction of garage that protrudes from conditioned space
  # @param foundation_type [String] foundation type of the building
  # @param attic_type [String] attic type of the building
  # @param num_floors [Integer] number of floors above grade
  # @param cfa [Double] conditioned floor area (m2)
  # @param aspect_ratio [Double] ratio of front/back wall length to left/right wall length (frac)
  # @return [Array<Double, Double>] length (m) and width (m) of the footprint
  def self.calculate_footprint_length_width(garage_width, garage_depth, garage_protrusion, foundation_type, attic_type, num_floors, cfa, aspect_ratio)
    garage_area = garage_width * garage_depth
    has_garage = (garage_area > 0)

    # calculate the footprint of the building
    garage_area_inside_footprint = 0
    if has_garage
      garage_area_inside_footprint = garage_area * (1.0 - garage_protrusion)
    end
    bonus_area_above_garage = garage_area * garage_protrusion
    if (foundation_type == HPXML::FoundationTypeBasementConditioned) && (attic_type == HPXML::AtticTypeConditioned)
      footprint = (cfa + 2 * garage_area_inside_footprint - num_floors * bonus_area_above_garage) / (num_floors + 2)
    elsif foundation_type == HPXML::FoundationTypeBasementConditioned
      footprint = (cfa + 2 * garage_area_inside_footprint - (num_floors - 1) * bonus_area_above_garage) / (num_floors + 1)
    elsif attic_type == HPXML::AtticTypeConditioned
      footprint = (cfa + garage_area_inside_footprint - num_floors * bonus_area_above_garage) / (num_floors + 1)
    else
      footprint = (cfa + garage_area_inside_footprint - (num_floors - 1) * bonus_area_above_garage) / num_floors
    end

    # calculate the dimensions of the building
    # we have: (1) aspect_ratio = fb / lr, and (2) footprint = fb * lr
    fb = Math.sqrt(footprint * aspect_ratio)
    lr = footprint / fb
    length = fb
    width = lr

    return length, width
  end

  # Place a door subsurface on an exterior wall surface (with enough area) prioritized by front, then back, then left, then right, and lowest story.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param door_area [Double] the area of the opaque door(s) (ft2)
  # @return [Boolean] true if successful
  def self.create_doors(runner, model, door_area:, **)
    # error checking
    if door_area == 0
      runner.registerFinalCondition('No doors added because door area was set to 0.')
      return true
    end

    door_height = 7.0 # ft
    door_width = door_area / door_height
    door_offset = 0.5 # ft

    # Get all exterior walls prioritized by front, then back, then left, then right
    facades = [Constants::FacadeFront, Constants::FacadeBack]
    avail_walls = []
    facades.each do |_facade|
      sorted_spaces = model.getSpaces.sort_by { |s| s.additionalProperties.getFeatureAsInteger('Index').get }
      get_conditioned_spaces(sorted_spaces).each do |space|
        next if space_is_below_grade(space)

        sorted_surfaces = space.surfaces.sort_by { |s| s.additionalProperties.getFeatureAsInteger('Index').get }
        sorted_surfaces.each do |surface|
          next unless get_surface_facade(surface) == Constants::FacadeFront
          next unless (surface.outsideBoundaryCondition == EPlus::BoundaryConditionOutdoors) || (surface.outsideBoundaryCondition == EPlus::BoundaryConditionAdiabatic)
          next if (90 - surface.tilt * 180 / Math::PI).abs > 0.01 # Not a vertical wall

          avail_walls << surface
        end
      end
      break if avail_walls.size > 0
    end

    # Get subset of exterior walls on lowest story
    min_story_avail_walls = []
    min_story_avail_wall_minz = 99999
    avail_walls.each do |avail_wall|
      zvalues = get_surface_z_values(surfaceArray: [avail_wall])
      minz = zvalues.min + avail_wall.space.get.zOrigin
      if minz < min_story_avail_wall_minz
        min_story_avail_walls.clear
        min_story_avail_walls << avail_wall
        min_story_avail_wall_minz = minz
      elsif (minz - min_story_avail_wall_minz).abs < 0.001
        min_story_avail_walls << avail_wall
      end
    end

    unit_has_door = true
    if min_story_avail_walls.size == 0
      runner.registerWarning('Could not find appropriate surface for the door. No door was added.')
      unit_has_door = false
    end

    door_sub_surface = nil
    min_story_avail_walls.each do |min_story_avail_wall|
      wall_gross_area = UnitConversions.convert(min_story_avail_wall.grossArea, 'm^2', 'ft^2')

      # Try to place door on any surface with enough area
      next if door_area >= wall_gross_area

      facade = get_surface_facade(min_story_avail_wall)

      if (door_offset + door_width) * door_height > wall_gross_area
        # Reduce door offset to fit door on surface
        door_offset = 0
      end

      num_existing_doors_on_this_surface = 0
      min_story_avail_wall.subSurfaces.each do |sub_surface|
        if sub_surface.subSurfaceType == EPlus::SubSurfaceTypeDoor
          num_existing_doors_on_this_surface += 1
        end
      end
      new_door_offset = door_offset + (door_offset + door_width) * num_existing_doors_on_this_surface

      # Create door vertices in relative coordinates
      upperleft = [new_door_offset, door_height]
      upperright = [new_door_offset + door_width, door_height]
      lowerright = [new_door_offset + door_width, 0]
      lowerleft = [new_door_offset, 0]

      # Convert to 3D geometry; assign to surface
      door_polygon = OpenStudio::Point3dVector.new
      case facade
      when Constants::FacadeFront
        multx = 1
        multy = 0
      when Constants::FacadeBack
        multx = -1
        multy = 0
      when Constants::FacadeLeft
        multx = 0
        multy = -1
      when Constants::FacadeRight
        multx = 0
        multy = 1
      end
      if (facade == Constants::FacadeBack) || (facade == Constants::FacadeLeft)
        leftx = get_surface_x_values(surfaceArray: [min_story_avail_wall]).max
        lefty = get_surface_y_values(surfaceArray: [min_story_avail_wall]).max
      else
        leftx = get_surface_x_values(surfaceArray: [min_story_avail_wall]).min
        lefty = get_surface_y_values(surfaceArray: [min_story_avail_wall]).min
      end
      bottomz = get_surface_z_values(surfaceArray: [min_story_avail_wall]).min

      [upperleft, lowerleft, lowerright, upperright].each do |coord|
        newx = UnitConversions.convert(leftx + multx * coord[0], 'ft', 'm')
        newy = UnitConversions.convert(lefty + multy * coord[0], 'ft', 'm')
        newz = UnitConversions.convert(bottomz + coord[1], 'ft', 'm')
        door_vertex = OpenStudio::Point3d.new(newx, newy, newz)
        door_polygon << door_vertex
      end

      door_sub_surface = create_sub_surface(model, door_polygon)
      door_sub_surface.setName("#{min_story_avail_wall.name} - Door")
      door_sub_surface.setSurface(min_story_avail_wall)
      door_sub_surface.setSubSurfaceType(EPlus::SubSurfaceTypeDoor)

      break
    end

    if door_sub_surface.nil? && unit_has_door
      runner.registerWarning('Could not find appropriate surface for the door. No door was added.')
    end

    return true
  end

  # Place window subsurfaces on exterior wall surfaces (or skylight subsurfaces on roof surfaces) using target facade areas based on either window to wall area ratios or window areas.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param window_front_wwr [Double] ratio of window to wall area for the unit's front facade (frac)
  # @param window_back_wwr [Double] ratio of window to wall area for the unit's back facade (frac)
  # @param window_left_wwr [Double] ratio of window to wall area for the unit's left facade (frac)
  # @param window_right_wwr [Double] ratio of window to wall area for the unit's right facade (frac)
  # @param window_area_front [Double] amount of window area on unit's front facade (ft2)
  # @param window_area_back [Double] amount of window area on unit's back facade (ft2)
  # @param window_area_left [Double] amount of window area on unit's left facade (ft2)
  # @param window_area_right [Double] amount of window area on unit's right facade (ft2)
  # @param window_aspect_ratio [Double] ratio of window height to width (frac)
  # @param skylight_area_front [Double] amount of skylight area on the unit's front conditioned roof facade (ft2)
  # @param skylight_area_back [Double] amount of skylight area on the unit's back conditioned roof facade (ft2)
  # @param skylight_area_left [Double] amount of skylight area on the unit's left conditioned roof facade (ft2)
  # @param skylight_area_right [Double] amount of skylight area on the unit's right conditioned roof facade (ft2)
  # @return [Boolean] true if successful
  def self.create_windows_and_skylights(runner, model,
                                        window_front_wwr:, window_back_wwr:, window_left_wwr:, window_right_wwr:,
                                        window_area_front:, window_area_back:, window_area_left:, window_area_right:, window_aspect_ratio:,
                                        skylight_area_front:, skylight_area_back:, skylight_area_left:, skylight_area_right:,
                                        **)
    facades = [Constants::FacadeBack, Constants::FacadeRight, Constants::FacadeFront, Constants::FacadeLeft]

    wwrs = {}
    wwrs[Constants::FacadeBack] = window_back_wwr
    wwrs[Constants::FacadeRight] = window_right_wwr
    wwrs[Constants::FacadeFront] = window_front_wwr
    wwrs[Constants::FacadeLeft] = window_left_wwr
    window_areas = {}
    window_areas[Constants::FacadeBack] = window_area_back
    window_areas[Constants::FacadeRight] = window_area_right
    window_areas[Constants::FacadeFront] = window_area_front
    window_areas[Constants::FacadeLeft] = window_area_left

    skylight_areas = {}
    skylight_areas[Constants::FacadeBack] = skylight_area_back
    skylight_areas[Constants::FacadeRight] = skylight_area_right
    skylight_areas[Constants::FacadeFront] = skylight_area_front
    skylight_areas[Constants::FacadeLeft] = skylight_area_left
    skylight_areas[Constants::FacadeNone] = 0

    # Store surfaces that should get windows by facade
    wall_surfaces = { Constants::FacadeFront => [], Constants::FacadeBack => [],
                      Constants::FacadeLeft => [], Constants::FacadeRight => [] }
    roof_surfaces = { Constants::FacadeFront => [], Constants::FacadeBack => [],
                      Constants::FacadeLeft => [], Constants::FacadeRight => [],
                      Constants::FacadeNone => [] }

    sorted_spaces = model.getSpaces.sort_by { |s| s.additionalProperties.getFeatureAsInteger('Index').get }
    get_conditioned_spaces(sorted_spaces).each do |space|
      sorted_surfaces = space.surfaces.sort_by { |s| s.additionalProperties.getFeatureAsInteger('Index').get }
      sorted_surfaces.each do |surface|
        next unless (surface.surfaceType == EPlus::SurfaceTypeWall) && (surface.outsideBoundaryCondition == EPlus::BoundaryConditionOutdoors)
        next if (90 - surface.tilt * 180 / Math::PI).abs > 0.01 # Not a vertical wall

        facade = get_surface_facade(surface)
        next if facade.nil?

        wall_surfaces[facade] << surface
      end
    end
    sorted_spaces.each do |space|
      sorted_surfaces = space.surfaces.sort_by { |s| s.additionalProperties.getFeatureAsInteger('Index').get }
      sorted_surfaces.each do |surface|
        next unless (surface.surfaceType == EPlus::SurfaceTypeRoofCeiling) && (surface.outsideBoundaryCondition == EPlus::BoundaryConditionOutdoors)

        facade = get_surface_facade(surface)
        if facade.nil?
          if surface.tilt == 0 # flat roof
            roof_surfaces[Constants::FacadeNone] << surface
          end
          next
        end
        roof_surfaces[facade] << surface
      end
    end

    # error checking
    facades.each do |facade|
      if (wwrs[facade] > 0) && (window_areas[facade] > 0)
        runner.registerError("Both #{facade} window-to-wall ratio and #{facade} window area are specified.")
        return false
      elsif (wwrs[facade] < 0) || (wwrs[facade] >= 1)
        runner.registerError("#{facade.capitalize} window-to-wall ratio must be greater than or equal to 0 and less than 1.")
        return false
      elsif window_areas[facade] < 0
        runner.registerError("#{facade.capitalize} window area must be greater than or equal to 0.")
        return false
      elsif skylight_areas[facade] < 0
        runner.registerError("#{facade.capitalize} skylight area must be greater than or equal to 0.")
        return false
      end
    end

    # Split any surfaces that have doors so that we can ignore them when adding windows
    facades.each do |facade|
      wall_surfaces[facade].each do |surface|
        next if surface.subSurfaces.size == 0

        new_surfaces = surface.splitSurfaceForSubSurfaces
        new_surfaces.each do |new_surface|
          wall_surfaces[facade] << new_surface
        end
      end
    end

    # Windows

    # Default assumptions
    min_single_window_area = 5.333 # sqft
    max_single_window_area = 12.0 # sqft
    window_gap_y = 1.0 # ft; distance from top of wall
    window_gap_x = 0.2 # ft; distance between windows in a two-window group
    min_wall_height = Math.sqrt(max_single_window_area * window_aspect_ratio) + window_gap_y * 1.05 # allow some wall area above/below
    min_wall_width = Math.sqrt(min_single_window_area / window_aspect_ratio) * 1.05 # allow some wall area to the left/right

    # Calculate available area for each wall, facade
    surface_avail_area = {}
    facade_avail_area = {}
    facades.each do |facade|
      facade_avail_area[facade] = 0
      wall_surfaces[facade].each do |surface|
        if not surface_avail_area.include? surface
          surface_avail_area[surface] = 0
        end

        area = get_wall_area_for_windows(surface: surface, min_wall_height: min_wall_height, min_wall_width: min_wall_width)
        surface_avail_area[surface] += area
        facade_avail_area[facade] += area
      end
    end

    # Initialize
    surface_window_area = {}
    target_facade_areas = {}
    facades.each do |facade|
      target_facade_areas[facade] = 0.0
      wall_surfaces[facade].each do |surface|
        surface_window_area[surface] = 0
      end
    end

    facades.each do |facade|
      # Calculate target window area for this facade
      if wwrs[facade] > 0
        wall_area = 0
        wall_surfaces[facade].each do |surface|
          wall_area += UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2')
        end
        target_facade_areas[facade] += wall_area * wwrs[facade]
      else
        target_facade_areas[facade] += window_areas[facade]
      end
    end

    facades.each do |facade|
      # Initial guess for wall of this facade
      next if facade_avail_area[facade] == 0

      wall_surfaces[facade].each do |surface|
        surface_window_area[surface] += surface_avail_area[surface] / facade_avail_area[facade] * target_facade_areas[facade]
      end
    end

    tot_win_area = 0
    facades.each do |facade|
      facade_win_area = 0
      wall_surfaces[facade].each do |surface|
        next if surface_window_area[surface] == 0
        if not add_windows_to_wall(runner, model, surface: surface, window_area: surface_window_area[surface], window_gap_y: window_gap_y, window_gap_x: window_gap_x, window_aspect_ratio: window_aspect_ratio, max_single_window_area: max_single_window_area, facade: facade)
          return false
        end

        tot_win_area += surface_window_area[surface]
        facade_win_area += surface_window_area[surface]
      end
      if (facade_win_area - target_facade_areas[facade]).abs > 0.1
        runner.registerWarning("Unable to assign appropriate window area for #{facade} facade.")
      end
    end

    # Skylights
    unless roof_surfaces[Constants::FacadeNone].empty?
      tot_sky_area = 0
      skylight_areas.each do |facade, skylight_area|
        next if facade == Constants::FacadeNone

        skylight_area /= roof_surfaces[Constants::FacadeNone].length
        skylight_areas[Constants::FacadeNone] += skylight_area
        skylight_areas[facade] = 0
      end
    end

    tot_sky_area = 0
    skylight_areas.each do |facade, skylight_area|
      next if skylight_area == 0

      surfaces = roof_surfaces[facade]

      if surfaces.empty? && (facade != Constants::FacadeNone)
        runner.registerError("There are no #{facade} roof surfaces, but #{skylight_area} ft^2 of skylights were specified.")
        return false
      end

      surfaces.each do |surface|
        if (UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2') / get_surface_length(surface)) > get_surface_length(surface)
          skylight_aspect_ratio = get_surface_length(surface) / (UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2') / get_surface_length(surface)) # aspect ratio of the roof surface
        else
          skylight_aspect_ratio = (UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2') / get_surface_length(surface)) / get_surface_length(surface) # aspect ratio of the roof surface
        end

        skylight_width = Math.sqrt(UnitConversions.convert(skylight_area, 'ft^2', 'm^2') / skylight_aspect_ratio)
        skylight_length = UnitConversions.convert(skylight_area, 'ft^2', 'm^2') / skylight_width

        skylight_bottom_left = OpenStudio::getCentroid(surface.vertices).get
        leftx = skylight_bottom_left.x
        lefty = skylight_bottom_left.y
        bottomz = skylight_bottom_left.z
        case facade
        when Constants::FacadeFront, Constants::FacadeNone
          skylight_top_left = OpenStudio::Point3d.new(leftx, lefty + Math.cos(surface.tilt) * skylight_length, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_top_right = OpenStudio::Point3d.new(leftx + skylight_width, lefty + Math.cos(surface.tilt) * skylight_length, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_bottom_right = OpenStudio::Point3d.new(leftx + skylight_width, lefty, bottomz)
        when Constants::FacadeBack
          skylight_top_left = OpenStudio::Point3d.new(leftx, lefty - Math.cos(surface.tilt) * skylight_length, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_top_right = OpenStudio::Point3d.new(leftx - skylight_width, lefty - Math.cos(surface.tilt) * skylight_length, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_bottom_right = OpenStudio::Point3d.new(leftx - skylight_width, lefty, bottomz)
        when Constants::FacadeLeft
          skylight_top_left = OpenStudio::Point3d.new(leftx + Math.cos(surface.tilt) * skylight_length, lefty, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_top_right = OpenStudio::Point3d.new(leftx + Math.cos(surface.tilt) * skylight_length, lefty - skylight_width, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_bottom_right = OpenStudio::Point3d.new(leftx, lefty - skylight_width, bottomz)
        when Constants::FacadeRight
          skylight_top_left = OpenStudio::Point3d.new(leftx - Math.cos(surface.tilt) * skylight_length, lefty, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_top_right = OpenStudio::Point3d.new(leftx - Math.cos(surface.tilt) * skylight_length, lefty + skylight_width, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_bottom_right = OpenStudio::Point3d.new(leftx, lefty + skylight_width, bottomz)
        end

        skylight_polygon = OpenStudio::Point3dVector.new
        [skylight_bottom_left, skylight_bottom_right, skylight_top_right, skylight_top_left].each do |skylight_vertex|
          skylight_polygon << skylight_vertex
        end

        sub_surface = create_sub_surface(model, skylight_polygon)
        sub_surface.setName("#{surface.name} - Skylight")
        sub_surface.setSurface(surface)

        tot_sky_area += skylight_area
      end
    end

    if (tot_win_area == 0) && (tot_sky_area == 0)
      runner.registerFinalCondition('No windows or skylights added.')
    end

    return true
  end

  # Return the HPXML location that is assigned to an OpenStudio Surface object.
  #
  # @param surface [OpenStudio::Model::Surface] the surface of interest
  # @return [String] the HPXML location assigned to the OpenStudio Surface object
  def self.get_surface_adjacent_to(surface)
    space = surface.space.get
    st = space.spaceType.get
    space_type = st.standardsSpaceType.get

    return space_type
  end

  # Return the absolute azimuth of an OpenStudio Surface object.
  #
  # @param surface [OpenStudio::Model::Surface] the surface of interest
  # @param orientation [Double] the orientation of the building measured clockwise from north (degrees)
  # @return [Double] the absolute azimuth based on surface facade and building orientation
  def self.get_surface_azimuth(surface, orientation)
    facade = get_surface_facade(surface)
    return get_azimuth_from_facade(facade, orientation)
  end

  # Identify whether an OpenStudio Surface object is a rim joist.
  #
  # @param surface [OpenStudio::Model::Surface] the surface of interest
  # @param height [Double] height of the rim joist (ft)
  # @return [Boolean] true if successful
  def self.surface_is_rim_joist(surface, height)
    return false unless (height - get_surface_height(surface)).abs < 0.00001
    return false unless get_surface_z_values(surfaceArray: [surface]).max > 0

    return true
  end

  # Takes in a list of floor surfaces for which to calculate the exposed perimeter.
  # Returns the total exposed perimeter.
  # NOTE: Does not work for buildings with non-orthogonal walls.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param ground_floor_surfaces [Array<OpenStudio::Model::Surface>] the array of OpenStudio Surface objects for which to calculate exposed perimeter
  # @param has_foundation_walls [Boolean] whether the ground floor surfaces have foundation walls
  # @return [Double] the exposed perimeter (ft)
  def self.calculate_exposed_perimeter(model,
                                       ground_floor_surfaces:,
                                       has_foundation_walls: false)
    perimeter = 0

    # Get ground edges
    if not has_foundation_walls
      # Use edges from floor surface
      ground_edges = get_edges_for_surfaces(ground_floor_surfaces, use_top_edge: false)
    else
      # Use top edges from foundation walls instead
      surfaces = []
      ground_floor_surfaces.each do |ground_floor_surface|
        next if not ground_floor_surface.space.is_initialized

        foundation_space = ground_floor_surface.space.get
        wall_surfaces = []
        foundation_space.surfaces.each do |surface|
          next if surface.surfaceType != EPlus::SurfaceTypeWall
          next if surface.adjacentSurface.is_initialized

          wall_surfaces << surface
        end
        get_walls_connected_to_floor(wall_surfaces: wall_surfaces, floor_surface: ground_floor_surface).each do |surface|
          next if surfaces.include? surface

          surfaces << surface
        end
      end
      ground_edges = get_edges_for_surfaces(surfaces, use_top_edge: true)
    end
    # Get bottom edges of exterior walls (building footprint)
    surfaces = []
    model.getSurfaces.each do |surface|
      next if surface.surfaceType != EPlus::SurfaceTypeWall
      next if surface.outsideBoundaryCondition != EPlus::BoundaryConditionOutdoors

      surfaces << surface
    end
    model_edges = get_edges_for_surfaces(surfaces, use_top_edge: false)

    # compare edges for overlap
    ground_edges.each do |e1|
      model_edges.each do |e2|
        next if not is_point_between(p: e2[0], v1: e1[0], v2: e1[1])
        next if not is_point_between(p: e2[1], v1: e1[0], v2: e1[1])

        point_one = OpenStudio::Point3d.new(e2[0][0], e2[0][1], e2[0][2])
        point_two = OpenStudio::Point3d.new(e2[1][0], e2[1][1], e2[1][2])
        length = OpenStudio::Vector3d.new(point_one - point_two).length
        perimeter += length
      end
    end

    return UnitConversions.convert(perimeter, 'm', 'ft')
  end

  # This is perimeter adjacent to a 100% protruding garage that is not exposed.
  # We need this because it's difficult to set this surface to Adiabatic using our geometry methods.
  #
  # @param geometry_garage_protrusion [Double] fraction of the garage that is protruding from the conditioned space
  # @param geometry_garage_width [Double] width of the garage (ft)
  # @param geometry_garage_depth [Double] depth of the garage (ft)
  # @return [Double] the unexposed garage perimeter
  def self.get_unexposed_garage_perimeter(geometry_garage_protrusion:,
                                          geometry_garage_width:,
                                          geometry_garage_depth:,
                                          **)
    protrusion = geometry_garage_protrusion
    width = geometry_garage_width
    depth = geometry_garage_depth

    if (protrusion == 1.0) && (width * depth > 0)
      return width
    end

    return 0
  end

  # Return the facade for the given OpenStudio Surface object.
  #
  # @param surface [OpenStudio::Model::Surface] the surface of interest
  # @return [String] front, back, left, or right based on the OpenStudio Surface outward normal
  def self.get_surface_facade(surface)
    tol = 0.001
    n = surface.outwardNormal
    facade = nil
    if n.z.abs < tol
      if (n.x.abs < tol) && ((n.y + 1).abs < tol)
        facade = Constants::FacadeFront
      elsif ((n.x - 1).abs < tol) && (n.y.abs < tol)
        facade = Constants::FacadeRight
      elsif (n.x.abs < tol) && ((n.y - 1).abs < tol)
        facade = Constants::FacadeBack
      elsif ((n.x + 1).abs < tol) && (n.y.abs < tol)
        facade = Constants::FacadeLeft
      end
    else
      if (n.x.abs < tol) && (n.y < 0)
        facade = Constants::FacadeFront
      elsif (n.x > 0) && (n.y.abs < tol)
        facade = Constants::FacadeRight
      elsif (n.x.abs < tol) && (n.y > 0)
        facade = Constants::FacadeBack
      elsif (n.x < 0) && (n.y.abs < tol)
        facade = Constants::FacadeLeft
      end
    end
    return facade
  end

  # Return the absolute azimuth of a facade.
  #
  # @param facade [String] front, back, left, or right
  # @param orientation [Double] the orientation of the building measured clockwise from north (degrees)
  # @return [Double] the absolute azimuth based on relative azimuth of the facade and building orientation
  def self.get_azimuth_from_facade(facade, orientation)
    case facade
    when Constants::FacadeFront
      return get_abs_azimuth(relative_azimuth: 0, building_orientation: orientation)
    when Constants::FacadeBack
      return get_abs_azimuth(relative_azimuth: 180, building_orientation: orientation)
    when Constants::FacadeLeft
      return get_abs_azimuth(relative_azimuth: 90, building_orientation: orientation)
    when Constants::FacadeRight
      return get_abs_azimuth(relative_azimuth: 270, building_orientation: orientation)
    else
      fail 'Unexpected facade.'
    end
  end

  # Get the adiabatic OpenStudio Surface object adjacent to an adiabatic OpenStudio Surface object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surface [OpenStudio::Model::Surface] the surface of interest
  # @return [OpenStudio::Model::Surface] the adiabatic adjacent OpenStudio Surface
  def self.get_adiabatic_adjacent_surface(model, surface)
    return if surface.outsideBoundaryCondition != EPlus::BoundaryConditionAdiabatic

    adjacentSurfaceType = EPlus::SurfaceTypeWall
    if surface.surfaceType == EPlus::SurfaceTypeRoofCeiling
      adjacentSurfaceType = EPlus::SurfaceTypeFloor
    elsif surface.surfaceType == EPlus::SurfaceTypeFloor
      adjacentSurfaceType = EPlus::SurfaceTypeRoofCeiling
    end

    model.getSurfaces.sort.each do |adjacent_surface|
      next if surface == adjacent_surface
      next if adjacent_surface.surfaceType != adjacentSurfaceType
      next if adjacent_surface.outsideBoundaryCondition != EPlus::BoundaryConditionAdiabatic
      next unless has_same_vertices(surface, adjacent_surface)

      return adjacent_surface
    end
    return
  end

  # Get the absolute tilt based on tilt, roof pitch, and latitude.
  #
  # @param tilt_str [Double, String] tilt in degrees or RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.
  # @param roof_pitch [Double] roof pitch in vertical rise inches for every 12 inches of horizontal run
  # @param latitude [Double] latitude (degrees)
  # @return [Double] absolute tilt
  def self.get_absolute_tilt(tilt_str:, roof_pitch:, latitude:)
    tilt_str = tilt_str.downcase
    if tilt_str.start_with? 'roofpitch'
      roof_angle = Math.atan(roof_pitch / 12.0) * 180.0 / Math::PI
      return Float(eval(tilt_str.gsub('roofpitch', roof_angle.to_s))).round(2)
    elsif tilt_str.start_with? 'latitude'
      return Float(eval(tilt_str.gsub('latitude', latitude.to_s))).round(2)
    else
      return Float(tilt_str)
    end
  end

  # Get the height of the conditioned attic for gable or hip roof type.
  #
  # @param spaces [Array<OpenStudio::Model::Space>] array of OpenStudio::Model::Space objects
  # @return [Double] the height of the conditioned attic (ft)
  def self.get_conditioned_attic_height(spaces)
    # gable roof type
    get_conditioned_spaces(spaces).each do |space|
      space.surfaces.each do |surface|
        next if surface.vertices.size != 3
        next if surface.outsideBoundaryCondition != EPlus::BoundaryConditionOutdoors
        next if surface.surfaceType != EPlus::SurfaceTypeWall

        return get_space_height(space)
      end
    end

    # hip roof type
    get_conditioned_spaces(spaces).each do |space|
      space.surfaces.each do |surface|
        next if surface.outsideBoundaryCondition != EPlus::BoundaryConditionOutdoors
        next if surface.surfaceType != EPlus::SurfaceTypeRoofCeiling

        return get_space_height(space)
      end
    end

    return false
  end

  # Calculates space height as the max z coordinate minus the min z coordinate.
  #
  # @param space [OpenStudio::Model::Space] an OpenStudio::Model::Space object
  # @return [Double] space height (ft)
  def self.get_space_height(space)
    zvalues = get_surface_z_values(surfaceArray: space.surfaces)
    return zvalues.max - zvalues.min
  end

  # Determine the length of an OpenStudio Surface by calculating the maximum difference between x and y coordinates.
  #
  # @param surface [OpenStudio::Model::Surface] an OpenStudio::Model::Surface object
  # @return [Double] length of the OpenStudio Surface (ft)
  def self.get_surface_length(surface)
    xvalues = get_surface_x_values(surfaceArray: [surface])
    yvalues = get_surface_y_values(surfaceArray: [surface])
    xrange = xvalues.max - xvalues.min
    yrange = yvalues.max - yvalues.min
    if xrange > yrange
      return xrange
    end

    return yrange
  end

  # Get the largest z difference for a surface.
  #
  # @param surface [OpenStudio::Model::Surface] an OpenStudio::Model::Surface object
  # @return [Double] the max z value minus the min x value
  def self.get_surface_height(surface)
    zvalues = get_surface_z_values(surfaceArray: [surface])
    zrange = zvalues.max - zvalues.min
    return zrange
  end

  # Return an array of x values for surfaces passed in.
  # The values will be relative to the parent origin.
  # This was intended for spaces.
  #
  # @param surfaceArray [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @return [Array<Double>] array of x-coordinates (ft)
  def self.get_surface_x_values(surfaceArray:)
    xValueArray = []
    surfaceArray.each do |surface|
      surface.vertices.each do |vertex|
        xValueArray << UnitConversions.convert(vertex.x, 'm', 'ft').round(5)
      end
    end
    return xValueArray
  end

  # Return an array of y values for surfaces passed in.
  # The values will be relative to the parent origin.
  # This was intended for spaces.
  #
  # @param surfaceArray [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @return [Array<Double>] array of y-coordinates (ft)
  def self.get_surface_y_values(surfaceArray:)
    yValueArray = []
    surfaceArray.each do |surface|
      surface.vertices.each do |vertex|
        yValueArray << UnitConversions.convert(vertex.y, 'm', 'ft').round(5)
      end
    end
    return yValueArray
  end

  # Return an array of z values for surfaces passed in.
  # The values will be relative to the parent origin.
  # This was intended for spaces.
  #
  # @param surfaceArray [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @return [Array<Double>] array of z-coordinates (ft)
  def self.get_surface_z_values(surfaceArray:)
    # Return an array of z values for surfaces passed in. The values will be relative to the parent origin. This was intended for spaces.
    zValueArray = []
    surfaceArray.each do |surface|
      surface.vertices.each do |vertex|
        zValueArray << UnitConversions.convert(vertex.z, 'm', 'ft').round(5)
      end
    end
    return zValueArray
  end

  # Get the absolute azimuth based on relative azimuth and building orientation.
  #
  # @param relative_azimuth [Double] relative azimuth (degrees)
  # @param building_orientation [Double] dwelling unit orientation (degrees)
  # @return [Double] absolute azimuth
  def self.get_abs_azimuth(relative_azimuth:, building_orientation:)
    azimuth = relative_azimuth + building_orientation

    # Ensure azimuth is >=0 and <360
    while azimuth < 0.0
      azimuth += 360.0
    end

    while azimuth >= 360.0
      azimuth -= 360.0
    end

    return azimuth
  end

  # Add a rim joist OpenStudio Surface to a space.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param polygon [OpenStudio::Point3dVector] the vertices for the surface
  # @param space [OpenStudio::Model::Space] the foundation space adjacent to the rim joist
  # @param rim_joist_height [Double] height of the rim joists (ft)
  # @param z [Double] z coordinate of the bottom of the rim joists
  # @return [nil]
  def self.add_rim_joist(model, polygon:, space:, rim_joist_height:, z:)
    if rim_joist_height > 0
      # make polygons
      p = OpenStudio::Point3dVector.new
      polygon.each do |point|
        p << OpenStudio::Point3d.new(point.x, point.y, z)
      end
      rim_joist_polygon = p

      # make space
      rim_joist_space = OpenStudio::Model::Space::fromFloorPrint(rim_joist_polygon, rim_joist_height, model)
      rim_joist_space = rim_joist_space.get
      assign_indexes(model, footprint_polygon: rim_joist_polygon, space: rim_joist_space)

      space.surfaces.each do |surface|
        next if surface.surfaceType != EPlus::SurfaceTypeRoofCeiling

        surface.remove
      end

      rim_joist_space.surfaces.each do |surface|
        next if surface.surfaceType != EPlus::SurfaceTypeFloor

        surface.remove
      end

      rim_joist_space.surfaces.each do |surface|
        surface.setSpace(space)
      end

      rim_joist_space.remove
    end
  end

  # For a given polygon and space, assign Index values to the (in order) space, floor surface, wall surfaces, and roofceiling surface.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param footprint_polygon [OpenStudio::Point3dVector] an OpenStudio::Point3dVector object
  # @param space [OpenStudio::Model::Space] an OpenStudio::Model::Space object
  # @return [nil]
  def self.assign_indexes(model, footprint_polygon:, space:)
    space.additionalProperties.setFeature('Index', indexer(model))

    space.surfaces.each do |surface|
      next if surface.surfaceType != EPlus::SurfaceTypeFloor

      surface.additionalProperties.setFeature('Index', indexer(model))
    end

    num_points = footprint_polygon.size
    for i in 1..num_points
      pt1 = footprint_polygon[(i + 1) % num_points]
      pt2 = footprint_polygon[i % num_points]
      polygon_points = [pt1, pt2]

      space.surfaces.each do |surface|
        next if surface.surfaceType != EPlus::SurfaceTypeWall

        num_points_matched = 0
        polygon_points.each do |polygon_point|
          surface.vertices.each do |surface_point|
            x = polygon_point.x - surface_point.x
            y = polygon_point.y - surface_point.y
            z = polygon_point.z - surface_point.z
            num_points_matched += 1 if x.abs < Constants::Small && y.abs < Constants::Small && z.abs < Constants::Small
          end
        end
        next if num_points_matched < 2 # match at least 2 points of the footprint_polygon and you've found the correct wall surface

        surface.additionalProperties.setFeature('Index', indexer(model))
      end
    end

    space.surfaces.each do |surface|
      next if surface.surfaceType != EPlus::SurfaceTypeRoofCeiling

      surface.additionalProperties.setFeature('Index', indexer(model))
    end
  end

  # Index any remaining surfaces created from intersecting/matching.
  # We can't deterministically assign indexes to these surfaces.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [nil]
  def self.assign_remaining_surface_indexes(model)
    model.getSurfaces.each do |surface|
      next if surface.additionalProperties.getFeatureAsInteger('Index').is_initialized

      surface.additionalProperties.setFeature('Index', indexer(model))
    end
  end

  # Create a new OpenStudio space and assign an Index to it.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [OpenStudio::Model::Space] the newly created space
  def self.create_space(model)
    space = OpenStudio::Model::Space.new(model)
    space.additionalProperties.setFeature('Index', indexer(model))
    return space
  end

  # Create a new OpenStudio surface and assign an Index to it.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param polygon [OpenStudio::Point3dVector] the vertices for the surface
  # @return [OpenStudio::Model::Surface] the newly created surface
  def self.create_surface(model, polygon)
    surface = OpenStudio::Model::Surface.new(polygon, model)
    surface.additionalProperties.setFeature('Index', indexer(model))
    return surface
  end

  # Create a new OpenStudio subsurface and assign an Index to it.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param polygon [OpenStudio::Point3dVector] the vertices for the subsurface
  # @return [OpenStudio::Model::SubSurface] the newly created subsurface
  def self.create_sub_surface(model, polygon)
    sub_surface = OpenStudio::Model::SubSurface.new(polygon, model)
    sub_surface.additionalProperties.setFeature('Index', indexer(model))
    return sub_surface
  end

  # Search through all spaces, surfaces, and subsurfaces, and populate an array of Index values.
  # Return an Index integer value equal to one more than the max of existing Index values.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [Integer] the incremented Index value
  def self.indexer(model)
    indexes = [0]
    (model.getSpaces + model.getSurfaces + model.getSubSurfaces).each do |s|
      next if !s.additionalProperties.getFeatureAsInteger('Index').is_initialized

      indexes << s.additionalProperties.getFeatureAsInteger('Index').get
    end
    return indexes.max + 1
  end

  # Determine whether two OpenStudio surface objects share the same set of vertices.
  #
  # @param surface1 [OpenStudio::Model::Surface] the first surface to compare
  # @param surface2 [OpenStudio::Model::Surface] the second surface to compare
  # @return [Boolean] true if two surfaces share the same vertices
  def self.has_same_vertices(surface1, surface2)
    if get_surface_x_values(surfaceArray: [surface1]).sort == get_surface_x_values(surfaceArray: [surface2]).sort &&
       get_surface_y_values(surfaceArray: [surface1]).sort == get_surface_y_values(surfaceArray: [surface2]).sort &&
       get_surface_z_values(surfaceArray: [surface1]).sort == get_surface_z_values(surfaceArray: [surface2]).sort &&
       surface1.space.get.zOrigin.round(5) == surface2.space.get.zOrigin.round(5)
      return true
    end

    return false
  end

  # Creates a polygon using an array of points.
  #
  # @param pts [Array<OpenStudio::Point3d>] the list of vertices
  # @return [OpenStudio::Point3dVector] the newly created polygon
  def self.make_polygon(*pts)
    p = OpenStudio::Point3dVector.new
    pts.each do |pt|
      p << pt
    end
    return p
  end

  # Initialize an identity matrix by setting the main diagonal elements to one.
  #
  # @return [OpenStudio::Matrix] a modified 4x4 OpenStudio::Matrix object
  def self.initialize_transformation_matrix()
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0, 0] = 1
    m[1, 1] = 1
    m[2, 2] = 1
    m[3, 3] = 1
    return m
  end

  # Returns the z value for the floor surface of a space.
  #
  # @param space [OpenStudio::Model::Space] the space of interest
  # @return [Double] the z value corresponding to floor surface in the provided space
  def self.get_space_floor_z(space)
    space.surfaces.each do |surface|
      next unless surface.surfaceType == EPlus::SurfaceTypeFloor

      return get_surface_z_values(surfaceArray: [surface])[0]
    end
  end

  # Returns the available wall area suitable for placing windows.
  #
  # @param surface [OpenStudio::Model::Surface] the wall of interest
  # @param min_wall_height [Double] Minimum wall height needed to support windows (ft)
  # @param min_wall_width [Double] Minimum wall length needed to support windows (ft)
  # @return [Double] the gross area of the surface for which windows may be applied (ft2)
  def self.get_wall_area_for_windows(surface:, min_wall_height:, min_wall_width:)
    # Skip surfaces with doors
    if surface.subSurfaces.size > 0
      return 0.0
    end

    # Only allow on gable and rectangular walls
    if not (is_suface_rectangular_wall(surface) || is_surface_gable_wall(surface))
      return 0.0
    end

    # Can't fit the smallest window?
    if get_surface_length(surface) < min_wall_width
      return 0.0
    end

    # Wall too short?
    if min_wall_height > get_surface_height(surface)
      return 0.0
    end

    # Gable too short?
    # super crude safety factor of 1.5
    if is_surface_gable_wall(surface) && (min_wall_height > get_surface_height(surface) / 1.5)
      return 0.0
    end

    return UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2')
  end

  # Adds pairs of windows to the given wall that achieve the desired window area.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surface [OpenStudio::Model::Surface] the wall of interest
  # @param window_area [Double] amount of window area (ft2)
  # @param window_gap_y [Double] distance from top of wall (ft)
  # @param window_gap_x [Double] distance between windows in a two-window group (ft)
  # @param window_aspect_ratio [Double] ratio of window height to width (frac)
  # @param max_single_window_area [Double] maximum area for a single window (ft2)
  # @param facade [String] front, back, left, or right
  # @return [Boolean] true if successful
  def self.add_windows_to_wall(runner, model, surface:, window_area:, window_gap_y:, window_gap_x:,
                               window_aspect_ratio:, max_single_window_area:, facade:)
    wall_width = get_surface_length(surface) # ft
    average_ceiling_height = get_surface_height(surface) # ft

    # Calculate number of windows needed
    num_windows = (window_area / max_single_window_area).ceil
    num_window_groups = (num_windows / 2.0).ceil
    num_window_gaps = num_window_groups
    if num_windows % 2 == 1
      num_window_gaps -= 1
    end
    window_width = Math.sqrt((window_area / num_windows.to_f) / window_aspect_ratio)
    window_height = (window_area / num_windows.to_f) / window_width
    width_for_windows = window_width * num_windows.to_f + window_gap_x * num_window_gaps.to_f

    if width_for_windows > wall_width
      surface_area = UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2')
      wwr = window_area / surface_area
      if wwr > 0.90
        runner.registerWarning("Could not fit windows on #{surface.name}; reducing window area to 90% WWR.")
        wwr = 0.90
      end

      # Instead of using this
      # ss_ = surface.setWindowToWallRatio(wwr, offset, true)
      # We offset the vertices towards the centroid to maximize the likelihood of fitting the window area on the surface
      window_vertices = []
      g = surface.centroid
      scale_factor = wwr**0.5

      surface.vertices.each do |vertex|
        # A vertex is a Point3d.
        # A diff from 2 Point3d creates a Vector3d

        # Vector from centroid to vertex (GA, GB, GC, etc)
        centroid_vector = vertex - g

        # Resize the vector (done in place) according to scale_factor
        centroid_vector.setLength(centroid_vector.length * scale_factor)

        # Change the vertex
        vertex = g + centroid_vector

        window_vertices << vertex
      end

      sub_surface = create_sub_surface(model, window_vertices)
      sub_surface.setName("#{surface.name} - Window 1")
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType(EPlus::SubSurfaceTypeWindow)
      return true
    end

    # Position window from top of surface
    win_top = average_ceiling_height - window_gap_y
    if is_surface_gable_wall(surface)
      # For gable surfaces, position windows from bottom of surface so they fit
      win_top = window_height + window_gap_y
    end

    # Groups of two windows
    win_num = 0
    for i in (1..num_window_groups)

      # Center vertex for group
      group_cx = wall_width * i / (num_window_groups + 1).to_f
      group_cy = win_top - window_height / 2.0

      if not ((i == num_window_groups) && (num_windows % 2 == 1))
        # Two windows in group
        win_num += 1
        add_window_to_wall(model, surface: surface, win_width: window_width, win_height: window_height, win_center_x: group_cx - window_width / 2.0 - window_gap_x / 2.0, win_center_y: group_cy, win_num: win_num, facade: facade)
        win_num += 1
        add_window_to_wall(model, surface: surface, win_width: window_width, win_height: window_height, win_center_x: group_cx + window_width / 2.0 + window_gap_x / 2.0, win_center_y: group_cy, win_num: win_num, facade: facade)
      else
        # One window in group
        win_num += 1
        add_window_to_wall(model, surface: surface, win_width: window_width, win_height: window_height, win_center_x: group_cx, win_center_y: group_cy, win_num: win_num, facade: facade)
      end
    end

    return true
  end

  # Adds a single window to the given wall with the specified location/size.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param surface [OpenStudio::Model::Surface] the wall of interest
  # @param win_width [Double] width of the window (ft)
  # @param win_height [Double] height of the window (ft)
  # @param win_center_x [Double] x-position of the window's center (ft)
  # @param win_center_y [Double] y-position of the window's center (ft)
  # @param win_num [Integer] The window number for the current surface
  # @param facade [String] front, back, left, or right
  # @return [nil]
  def self.add_window_to_wall(model, surface:, win_width:, win_height:, win_center_x:, win_center_y:,
                              win_num:, facade:)
    # Create window vertices in relative coordinates, ft
    upperleft = [win_center_x - win_width / 2.0, win_center_y + win_height / 2.0]
    upperright = [win_center_x + win_width / 2.0, win_center_y + win_height / 2.0]
    lowerright = [win_center_x + win_width / 2.0, win_center_y - win_height / 2.0]
    lowerleft = [win_center_x - win_width / 2.0, win_center_y - win_height / 2.0]

    # Convert to 3D geometry; assign to surface
    window_polygon = OpenStudio::Point3dVector.new
    case facade
    when Constants::FacadeFront
      multx = 1
      multy = 0
    when Constants::FacadeBack
      multx = -1
      multy = 0
    when Constants::FacadeLeft
      multx = 0
      multy = -1
    when Constants::FacadeRight
      multx = 0
      multy = 1
    end
    if (facade == Constants::FacadeBack) || (facade == Constants::FacadeLeft)
      leftx = get_surface_x_values(surfaceArray: [surface]).max
      lefty = get_surface_y_values(surfaceArray: [surface]).max
    else
      leftx = get_surface_x_values(surfaceArray: [surface]).min
      lefty = get_surface_y_values(surfaceArray: [surface]).min
    end
    bottomz = get_surface_z_values(surfaceArray: [surface]).min
    [upperleft, lowerleft, lowerright, upperright].each do |coord|
      newx = UnitConversions.convert(leftx + multx * coord[0], 'ft', 'm')
      newy = UnitConversions.convert(lefty + multy * coord[0], 'ft', 'm')
      newz = UnitConversions.convert(bottomz + coord[1], 'ft', 'm')
      window_vertex = OpenStudio::Point3d.new(newx, newy, newz)
      window_polygon << window_vertex
    end
    sub_surface = create_sub_surface(model, window_polygon)
    sub_surface.setName("#{surface.name} - Window #{win_num}")
    sub_surface.setSurface(surface)
    sub_surface.setSubSurfaceType(EPlus::SubSurfaceTypeWindow)
  end

  # From a provided array of OpenStudio spaces, return the subset for which the standards space type is equal to the HPXML location for conditioned space.
  #
  # @param spaces [Array<OpenStudio::Model::Space>] array of OpenStudio::Model::Space objects
  # @return [Array<OpenStudio::Model::Space>] array of conditioned OpenStudio spaces
  def self.get_conditioned_spaces(spaces)
    conditioned_spaces = []
    spaces.each do |space|
      next unless space.spaceType.get.standardsSpaceType.get == HPXML::LocationConditionedSpace

      conditioned_spaces << space
    end
    return conditioned_spaces
  end

  # From a provided array of OpenStudio spaces, return the subset for which the standards space type is equal to the HPXML location for garage.
  #
  # @param spaces [Array<OpenStudio::Model::Space>] array of OpenStudio::Model::Space objects
  # @return [Array<OpenStudio::Model::Space>] array of garage OpenStudio spaces
  def self.get_garage_spaces(spaces)
    garage_spaces = []
    spaces.each do |space|
      next unless space.spaceType.get.standardsSpaceType.get == HPXML::LocationGarage

      garage_spaces << space
    end
    return garage_spaces
  end

  # An OpenStudio surface is a rectangular wall if:
  # - surface type is wall
  # - outside boundary condition is outdoors
  # - vertically oriented with 4 vertices
  #
  # @param surface [OpenStudio::Model::Surface] the surface of interest
  # @return [Boolean] true if surface satisfies rectangular wall criteria
  def self.is_suface_rectangular_wall(surface)
    if ((surface.surfaceType != EPlus::SurfaceTypeWall) || (surface.outsideBoundaryCondition != EPlus::BoundaryConditionOutdoors))
      return false
    end
    if surface.vertices.size != 4
      return false
    end

    xvalues = get_surface_x_values(surfaceArray: [surface])
    yvalues = get_surface_y_values(surfaceArray: [surface])
    zvalues = get_surface_z_values(surfaceArray: [surface])
    if not (((xvalues.uniq.size == 1) && (yvalues.uniq.size == 2)) ||
            ((xvalues.uniq.size == 2) && (yvalues.uniq.size == 1)))
      return false
    end
    if zvalues.uniq.size != 2
      return false
    end

    return true
  end

  # An OpenStudio surface is a gable wall if:
  # - surface type is wall
  # - outside boundary condition is outdoors
  # - has 3 vertices
  # - its space has a roof
  #
  # @param surface [OpenStudio::Model::Surface] the surface of interest
  # @return [Boolean] true if surface satisfies gable wall criteria
  def self.is_surface_gable_wall(surface)
    if ((surface.surfaceType != EPlus::SurfaceTypeWall) || (surface.outsideBoundaryCondition != EPlus::BoundaryConditionOutdoors))
      return false
    end
    if surface.vertices.size != 3
      return false
    end
    if not surface.space.is_initialized
      return false
    end

    space = surface.space.get
    if not space_has_roof(space)
      return false
    end

    return true
  end

  # An OpenStudio space has a roof if there is at least one surface that:
  # - surface type is roofceiling
  # - outside boundary condition is outdoors
  # - tilt is zero
  #
  # @param space [OpenStudio::Model::Space] the space of interest
  # @return [Boolean] true if space has a roof deck
  def self.space_has_roof(space)
    space.surfaces.each do |surface|
      next if surface.surfaceType != EPlus::SurfaceTypeRoofCeiling
      next if surface.outsideBoundaryCondition != EPlus::BoundaryConditionOutdoors
      next if surface.tilt == 0

      return true
    end
    return false
  end

  # Create and return an OpenStudio attic space provided the following information.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param x [Double] the front-back length (m)
  # @param y [Double] the left-right length (m)
  # @param average_ceiling_height [Double] average ceiling height (m)
  # @param num_floors [Integer] number of floors
  # @param roof_pitch [Double] ratio of vertical rise to horizontal run (frac)
  # @param roof_type [String] roof type of the building
  # @param rim_joist_height [Double] height of the rim joists (ft)
  # @return [OpenStudio::Model::Space] the newly created attic space
  def self.get_attic_space(model, x:, y:, average_ceiling_height:, num_floors:,
                           roof_pitch:, roof_type:, rim_joist_height:)
    y_rear = 0
    y_peak = -y / 2
    y_tot = y

    nw_point = OpenStudio::Point3d.new(0, 0, average_ceiling_height * num_floors + rim_joist_height)
    ne_point = OpenStudio::Point3d.new(x, 0, average_ceiling_height * num_floors + rim_joist_height)
    sw_point = OpenStudio::Point3d.new(0, -y, average_ceiling_height * num_floors + rim_joist_height)
    se_point = OpenStudio::Point3d.new(x, -y, average_ceiling_height * num_floors + rim_joist_height)
    attic_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)

    attic_height = (y_tot / 2.0) * roof_pitch + rim_joist_height # Roof always has same orientation

    side_type = nil
    case roof_type
    when Constants::RoofTypeGable
      roof_w_point = OpenStudio::Point3d.new(0, y_peak, average_ceiling_height * num_floors + attic_height)
      roof_e_point = OpenStudio::Point3d.new(x, y_peak, average_ceiling_height * num_floors + attic_height)
      polygon_w_roof = make_polygon(roof_w_point, roof_e_point, ne_point, nw_point)
      polygon_e_roof = make_polygon(roof_e_point, roof_w_point, sw_point, se_point)
      polygon_s_wall = make_polygon(roof_w_point, nw_point, sw_point)
      polygon_n_wall = make_polygon(roof_e_point, se_point, ne_point)
      side_type = EPlus::SurfaceTypeWall
    when Constants::RoofTypeHip
      if y > 0
        if x <= (y + y_rear)
          roof_n_point = OpenStudio::Point3d.new(x / 2.0, y_rear - x / 2.0, average_ceiling_height * num_floors + attic_height)
          roof_s_point = OpenStudio::Point3d.new(x / 2.0, -y + x / 2.0, average_ceiling_height * num_floors + attic_height)
          polygon_w_roof = make_polygon(roof_n_point, nw_point, sw_point, roof_s_point)
          polygon_e_roof = make_polygon(roof_s_point, se_point, ne_point, roof_n_point)
          polygon_s_wall = make_polygon(roof_s_point, sw_point, se_point)
          polygon_n_wall = make_polygon(roof_n_point, ne_point, nw_point)
        else
          roof_w_point = OpenStudio::Point3d.new((y + y_rear) / 2.0, (y_rear - y) / 2.0, average_ceiling_height * num_floors + attic_height)
          roof_e_point = OpenStudio::Point3d.new(x - (y + y_rear) / 2.0, (y_rear - y) / 2.0, average_ceiling_height * num_floors + attic_height)
          polygon_w_roof = make_polygon(roof_w_point, sw_point, se_point, roof_e_point)
          polygon_e_roof = make_polygon(roof_e_point, ne_point, nw_point, roof_w_point)
          polygon_s_wall = make_polygon(roof_e_point, se_point, ne_point)
          polygon_n_wall = make_polygon(roof_w_point, nw_point, sw_point)
        end
      else
        if x <= y.abs
          roof_n_point = OpenStudio::Point3d.new(x / 2.0, -y - x / 2.0, average_ceiling_height * num_floors + attic_height)
          roof_s_point = OpenStudio::Point3d.new(x / 2.0, x / 2.0, average_ceiling_height * num_floors + attic_height)
          polygon_w_roof = make_polygon(roof_n_point, nw_point, sw_point, roof_s_point)
          polygon_e_roof = make_polygon(roof_s_point, se_point, ne_point, roof_n_point)
          polygon_s_wall = make_polygon(roof_s_point, sw_point, se_point)
          polygon_n_wall = make_polygon(roof_n_point, ne_point, nw_point)
        else
          roof_w_point = OpenStudio::Point3d.new(-y / 2.0, -y / 2.0, average_ceiling_height * num_floors + attic_height)
          roof_e_point = OpenStudio::Point3d.new(x + y / 2.0, -y / 2.0, average_ceiling_height * num_floors + attic_height)
          polygon_w_roof = make_polygon(roof_w_point, sw_point, se_point, roof_e_point)
          polygon_e_roof = make_polygon(roof_e_point, ne_point, nw_point, roof_w_point)
          polygon_s_wall = make_polygon(roof_e_point, se_point, ne_point)
          polygon_n_wall = make_polygon(roof_w_point, nw_point, sw_point)
        end
      end
      side_type = EPlus::SurfaceTypeRoofCeiling
    end

    surface_floor = create_surface(model, attic_polygon)
    surface_floor.setSurfaceType(EPlus::SurfaceTypeFloor)
    surface_floor.setOutsideBoundaryCondition(EPlus::BoundaryConditionSurface)
    surface_w_roof = create_surface(model, polygon_w_roof)
    surface_w_roof.setSurfaceType(EPlus::SurfaceTypeRoofCeiling)
    surface_w_roof.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)
    surface_e_roof = create_surface(model, polygon_e_roof)
    surface_e_roof.setSurfaceType(EPlus::SurfaceTypeRoofCeiling)
    surface_e_roof.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)
    surface_s_wall = create_surface(model, polygon_s_wall)
    surface_s_wall.setSurfaceType(side_type)
    surface_s_wall.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)
    surface_n_wall = create_surface(model, polygon_n_wall)
    surface_n_wall.setSurfaceType(side_type)
    surface_n_wall.setOutsideBoundaryCondition(EPlus::BoundaryConditionOutdoors)

    attic_space = create_space(model)

    surface_floor.setSpace(attic_space)
    surface_w_roof.setSpace(attic_space)
    surface_e_roof.setSpace(attic_space)
    surface_s_wall.setSpace(attic_space)
    surface_n_wall.setSpace(attic_space)

    return attic_space
  end

  # Shift all spaces up by foundation height for ambient foundation.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param foundation_type [String] HPXML location for foundation type
  # @param foundation_height [Double] height of the foundation (m)
  # @return [nil]
  def self.apply_ambient_foundation_shift(model, foundation_type:, foundation_height:)
    if [HPXML::FoundationTypeAmbient, HPXML::FoundationTypeBellyAndWing].include?(foundation_type)
      m = initialize_transformation_matrix()
      m[2, 3] = -foundation_height
      model.getSpaces.each do |space|
        space.changeTransformation(OpenStudio::Transformation.new(m))
        space.setXOrigin(0)
        space.setYOrigin(0)
        space.setZOrigin(0)
      end
    end
  end

  # Returns true if space is either fully or partially below grade (i.e., space has a surface with outside boundary condition of foundation).
  #
  # @param space [OpenStudio::Model::Space] the space of interest
  # @return [Boolean] true if space is below grade
  def self.space_is_below_grade(space)
    space.surfaces.each do |surface|
      next if surface.surfaceType != EPlus::SurfaceTypeWall
      if surface.outsideBoundaryCondition == EPlus::BoundaryConditionFoundation
        return true
      end
    end
    return false
  end

  # Checks if point p is between points v1 and v2.
  #
  # @param p [OpenStudio::Point3d] the vertex to check
  # @param v1 [OpenStudio::Point3d] the first vertex to check against
  # @param v2 [OpenStudio::Point3d] the second vertex to check against
  # @return [Boolean] true if point is between the other two points
  def self.is_point_between(p:, v1:, v2:)
    is_between = false
    tol = 0.001
    if ((p[2] - v1[2]).abs <= tol) && ((p[2] - v2[2]).abs <= tol) # equal z
      if ((p[0] - v1[0]).abs <= tol) && ((p[0] - v2[0]).abs <= tol) # equal x; vertical
        if (p[1] >= v1[1] - tol) && (p[1] <= v2[1] + tol)
          is_between = true
        elsif (p[1] <= v1[1] + tol) && (p[1] >= v2[1] - tol)
          is_between = true
        end
      elsif ((p[1] - v1[1]).abs <= tol) && ((p[1] - v2[1]).abs <= tol) # equal y; horizontal
        if (p[0] >= v1[0] - tol) && (p[0] <= v2[0] + tol)
          is_between = true
        elsif (p[0] <= v1[0] + tol) && (p[0] >= v2[0] - tol)
          is_between = true
        end
      end
    end
    return is_between
  end

  # Get and return an array of OpenStudio wall surfaces that are adjacent to an OpenStudio floor surface.
  #
  # @param wall_surfaces [Array<OpenStudio::Model::Surface>] the walls of interest
  # @param floor_surface [OpenStudio::Model::Surface] the floor of interest
  # @param same_space [Boolean] true if connected walls should share the space of the floor surface
  # @return [Array<OpenStudio::Model::Surface>] subset of wall surfaces adjacent to the floor surface
  def self.get_walls_connected_to_floor(wall_surfaces:,
                                        floor_surface:,
                                        same_space: true)
    adjacent_wall_surfaces = []

    wall_surfaces.each do |wall_surface|
      if same_space
        next if wall_surface.space.get != floor_surface.space.get
      else
        next if wall_surface.space.get == floor_surface.space.get
      end

      wall_vertices = wall_surface.vertices
      wall_vertices.each_with_index do |wv1, widx|
        wv2 = wall_vertices[widx - 1]
        floor_vertices = floor_surface.vertices
        floor_vertices.each_with_index do |fv1, fidx|
          fv2 = floor_vertices[fidx - 1]
          # Wall within floor edge?
          next unless (is_point_between(p: [wv1.x, wv1.y, wv1.z + wall_surface.space.get.zOrigin],
                                        v1: [fv1.x, fv1.y, fv1.z + floor_surface.space.get.zOrigin],
                                        v2: [fv2.x, fv2.y, fv2.z + floor_surface.space.get.zOrigin]) \
                    && is_point_between(p: [wv2.x, wv2.y, wv2.z + wall_surface.space.get.zOrigin],
                                        v1: [fv1.x, fv1.y, fv1.z + floor_surface.space.get.zOrigin],
                                        v2: [fv2.x, fv2.y, fv2.z + floor_surface.space.get.zOrigin]))

          if not adjacent_wall_surfaces.include? wall_surface
            adjacent_wall_surfaces << wall_surface
          end
        end
      end
    end

    return adjacent_wall_surfaces
  end

  # Returns an array of edges for the set of surfaces.
  #
  # @param surfaces [Array<OpenStudio::Model::Surface>] array of OpenStudio::Model::Surface objects
  # @param use_top_edge [Boolean] true if matching on max z values for surfaces
  # @return [Array<Array, Array, String>] List of edges, where each edge is an array with two vertices and a facade
  def self.get_edges_for_surfaces(surfaces,
                                  use_top_edge:)
    edges = []
    surfaces.each do |surface|
      if use_top_edge
        matchz = get_surface_z_values(surfaceArray: [surface]).max
      else
        matchz = get_surface_z_values(surfaceArray: [surface]).min
      end

      # get vertices
      vertex_hash = {}
      vertex_counter = 0
      surface.vertices.each do |vertex|
        next if (UnitConversions.convert(vertex.z, 'm', 'ft') - matchz).abs > 0.0001 # ensure we only process bottom/top edge of wall surfaces

        vertex_counter += 1
        vertex_hash[vertex_counter] = [vertex.x + surface.space.get.xOrigin,
                                       vertex.y + surface.space.get.yOrigin,
                                       vertex.z + surface.space.get.zOrigin]
      end

      facade = get_surface_facade(surface)

      # make edges
      counter = 0
      vertex_hash.values.each do |v|
        counter += 1
        if vertex_hash.size != counter
          edges << [v, vertex_hash[counter + 1], facade]
        elsif vertex_hash.size > 2 # different code for wrap around vertex (if > 2 vertices)
          edges << [v, vertex_hash[1], facade]
        end
      end
    end

    return edges
  end
end
