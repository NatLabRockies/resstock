# frozen_string_literal: true

# Object that stores material properties for opaque materials.
# Unlike the BaseMaterial, the Material object includes a thickness and R-value.
class Material
  # @param name [String] Material name
  # @param thick_in [Double] Thickness (in)
  # @param mat_base [BaseMaterial] Optional base material object that defines k_in, rho, and cp
  # @param k_in [Double] Conductivity (Btu-in/h-ft2-F)
  # @param rho [Double] Density (lb/ft3)
  # @param cp [Double] Specific heat (Btu/lb-F)
  # @param tAbs [Double] Thermal absorptance (emittance); 0.9 is EnergyPlus default
  # @param sAbs [Double] Solar absorptance; 0.7 is EnergyPlus default
  def initialize(name: nil, thick_in: nil, mat_base: nil, k_in: nil, rho: nil, cp: nil, tAbs: 0.9, sAbs: 0.7)
    @name = name

    if not thick_in.nil?
      @thick_in = thick_in # in
      @thick = UnitConversions.convert(thick_in, 'in', 'ft') # ft
    end

    if not mat_base.nil?
      @k_in = mat_base.k_in # Btu-in/h-ft2-F
      if not mat_base.k_in.nil?
        @k = UnitConversions.convert(mat_base.k_in, 'in', 'ft') # Btu/h-ft-F
      else
        @k = nil
      end
      @rho = mat_base.rho
      @cp = mat_base.cp
    else
      @k_in = nil
      @k = nil
      @rho = nil
      @cp = nil
    end

    # Override the base material if both are included
    if not k_in.nil?
      @k_in = k_in # Btu-in/h-ft2-F
      @k = UnitConversions.convert(k_in, 'in', 'ft') # Btu/h-ft-F
    end
    if not rho.nil?
      @rho = rho # lb/ft3
    end
    if not cp.nil?
      @cp = cp # Btu/lb*F
    end

    @tAbs = tAbs
    @sAbs = sAbs

    # Calculate R-value
    if not rvalue.nil?
      @rvalue = rvalue # hr-ft2-F/Btu
    elsif (not @thick_in.nil?) && (not @k_in.nil?)
      if @k_in > 0
        @rvalue = @thick_in / @k_in # hr-ft2-F/Btu
      else
        @rvalue = @thick_in / 10000000.0 # hr-ft2-F/Btu
      end
    end
  end

  # Combines two materials into a new single material.
  #
  # @param mat1 [Material] The first material to combine
  # @param mat2 [Material] The second material to combine
  # @return [Material] The combined material object
  def self.combine(mat1, mat2, new_name)
    rvalue = mat2.thick_in / mat2.k_in + mat1.thick_in / mat1.k_in
    thick_in = mat2.thick_in + mat1.thick_in
    rho = (mat2.rho * mat2.thick_in + mat1.rho * mat1.thick_in) / thick_in
    cp = (mat2.cp * mat2.rho * mat2.thick_in + mat1.cp * mat1.rho * mat1.thick_in) / (rho * thick_in)

    return new(name: new_name, thick_in: thick_in, k_in: thick_in / rvalue, rho: rho, cp: cp)
  end

  attr_accessor :name, :thick, :thick_in, :k, :k_in, :rho, :cp, :rvalue, :tAbs, :sAbs

  # Creates a material associated with a closed air cavity (e.g.,
  # inside an uninsulated wood stud wall).
  #
  # @param thick_in [Double] Thickness (in)
  # @return [Material] The material object
  def self.AirCavityClosed(thick_in)
    rvalue = 1.0 # hr*ft*F/Btu (Assume for all air gap configurations since there is no correction for direction of heat flow in the simulation tools)
    return new(thick_in: thick_in, k_in: thick_in / rvalue, rho: Gas.Air.rho, cp: Gas.Air.cp)
  end

  # Creates a material associated with a cavity between framing
  # that is not enclosed (e.g., the floor above a crawlspace or an
  # attic floor).
  #
  # @param thick_in [Double] Thickness (in)
  # @return [Material] The material object
  def self.AirCavityOpen(thick_in)
    return new(thick_in: thick_in, k_in: 10000000.0, rho: Gas.Air.rho, cp: Gas.Air.cp)
  end

  # Creates a material that characterizes the combined radiative
  # and convective surface film thermal resistance.
  #
  # @param rvalue [Double] Thermal resistance (hr-ft2-F/Btu)
  # @return [Material] The material object
  def self.AirFilm(rvalue)
    return new(name: Constants::AirFilm, thick_in: 1.0, k_in: 1.0 / rvalue)
  end

  # Creates a material for the exterior air film of a surface exposed to outdoors.
  #
  # @param no_wind_exposure [Boolean] True if the surface experiences little to no wind
  # @param apply_ashrae140_assumptions [Boolean] True if an ASHRAE 140 test case where we want to override our normal assumptions
  # @return [Material] The material object
  def self.AirFilmOutside(no_wind_exposure = false, apply_ashrae140_assumptions = false)
    if no_wind_exposure
      rvalue = 0.455 # hr-ft-F/Btu
    else
      if apply_ashrae140_assumptions
        rvalue = 0.174 # hr-ft-F/Btu
      else
        rvalue_winter = 0.17 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
        rvalue_summer = 0.25 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
        rvalue = (rvalue_winter + rvalue_summer) / 2.0
      end
    end
    return self.AirFilm(rvalue)
  end

  # Creates a material for the interior air film of a wall (vertical) surface.
  #
  # @return [Material] The material object
  def self.AirFilmIndoorWall
    rvalue = 0.68 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    return self.AirFilm(rvalue)
  end

  # Creates a material for the interior air film of a ceiling (horizontal) surface
  # with neither upward now downward heat flow. Used for floors below attics, raised
  # floors, or adiabatic floors, where heat flow can be either direction because the
  # temperature on the other side may be either hotter or colder.
  #
  # @return [Material] The material object
  def self.AirFilmIndoorFloorAverage
    rvalue_down = self.AirFilmIndoorFloorDown.rvalue
    rvalue_up = 0.61 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    rvalue = (rvalue_down + rvalue_up) / 2.0
    return self.AirFilm(rvalue)
  end

  # Creates a material for the interior air film of a floor (horizontal) surface
  # with downward heat flow. Used for floors above foundations where heat flow will
  # be downward because the foundation space is generally colder than conditioned space.
  #
  # @return [Material] The material object
  def self.AirFilmIndoorFloorDown
    rvalue = 0.92 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    return self.AirFilm(rvalue)
  end

  # Creates a material for the interior air film of a roof (sloped) surface.
  #
  # @param surface_angle [Double] The angle of the surface from horizontal (degrees)
  # @param apply_ashrae140_assumptions [Boolean] True if an ASHRAE 140 test case where we want to override our normal assumptions
  # @return [Material] The material object
  def self.AirFilmIndoorRoof(surface_angle, apply_ashrae140_assumptions = false)
    if apply_ashrae140_assumptions
      rvalue = 0.752 # hr-ft-F/Btu
    else
      # Correlation functions used to interpolate between values provided
      # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
      # 0, 45, and 90 degrees.
      # Uses the average of upward/downward heat flow values with the assumption
      # that the temperature above the roof can be either hotter or colder.
      rvalue_up = 0.002 * Math::exp(0.0398 * surface_angle) + 0.608 # hr-ft-F/Btu (evaluates to 0.62 at 45 degrees, when direction of heat flow is upward)
      rvalue_down = 0.32 * Math::exp(-0.0154 * surface_angle) + 0.6 # hr-ft-F/Btu (evaluates to 0.76 at 45 degrees, when direction of heat flow is downward)
      rvalue = (rvalue_up + rvalue_down) / 2.0 # hr-ft-F/Btu
    end
    return self.AirFilm(rvalue)
  end

  # Creates a material for the combined layer of, e.g., carpet and bare floor.
  #
  # @param floorFraction [Double] Fraction of the floor that is covered (i.e., not bare)
  # @param rvalue [Double] Thermal resistance (hr-ft2-F/Btu)
  # @return [Material] The material object
  def self.CoveringBare(floor_fraction = 0.8, rvalue = 2.08)
    thick_in = 0.5 # in
    return new(name: 'floor covering', thick_in: thick_in, k_in: thick_in / (rvalue * floor_fraction), rho: 3.4, cp: 0.32, tAbs: 0.9, sAbs: 0.9)
  end

  # Creates a material for a given thickness of concrete.
  #
  # @param thick_in [Double] Thickness of the concrete (in)
  # @return [Material] The material object
  def self.Concrete(thick_in)
    return new(name: "concrete #{thick_in} in.", thick_in: thick_in, mat_base: BaseMaterial.Concrete, tAbs: 0.9)
  end

  # Creates a material for the wall exterior finish (siding) material.
  #
  # @param type [HPXML::SidingTypeXXX] Type of siding
  # @param thick_in [Double] Thickness of the siding (in)
  # @return [Material] The material object
  def self.ExteriorFinishMaterial(type, thick_in = nil)
    if (type == HPXML::SidingTypeNotPresent) || (!thick_in.nil? && thick_in <= 0)
      return
    end

    case type
    when HPXML::SidingTypeAsbestos
      thick_in = 0.25 if thick_in.nil?
      return new(name: type, thick_in: thick_in, k_in: 4.20, rho: 118.6, cp: 0.24)
    when HPXML::SidingTypeBrick
      thick_in = 4.0 if thick_in.nil?
      return new(name: type, thick_in: thick_in, mat_base: BaseMaterial.Brick)
    when HPXML::SidingTypeStone
      thick_in = 1.0 if thick_in.nil?
      return new(name: type, thick_in: thick_in, mat_base: BaseMaterial.Stone)
    when HPXML::SidingTypeCompositeShingle
      thick_in = 0.25 if thick_in.nil?
      return new(name: type, thick_in: thick_in, k_in: 1.128, rho: 70.0, cp: 0.35)
    when HPXML::SidingTypeFiberCement
      thick_in = 0.375 if thick_in.nil?
      return new(name: type, thick_in: thick_in, k_in: 1.79, rho: 21.7, cp: 0.24)
    when HPXML::SidingTypeMasonite # Masonite hardboard
      thick_in = 0.5 if thick_in.nil?
      return new(name: type, thick_in: thick_in, k_in: 0.69, rho: 46.8, cp: 0.39)
    when HPXML::SidingTypeStucco
      thick_in = 1.0 if thick_in.nil?
      return new(name: type, thick_in: thick_in, mat_base: BaseMaterial.Stucco)
    when HPXML::SidingTypeSyntheticStucco # EIFS
      thick_in = 1.0 if thick_in.nil?
      return new(name: type, thick_in: thick_in, mat_base: BaseMaterial.InsulationRigid)
    when HPXML::SidingTypeVinyl, HPXML::SidingTypeAluminum
      thick_in = 0.375 if thick_in.nil?
      return new(name: type, thick_in: thick_in, mat_base: BaseMaterial.Vinyl)
    when HPXML::SidingTypeWood
      thick_in = 0.75 if thick_in.nil?
      return new(name: type, thick_in: thick_in, k_in: 0.71, rho: 34.0, cp: 0.28)
    end

    fail "Unexpected type: #{type}."
  end

  # Creates a material for the foundation wall.
  #
  # @param type [FoundationWallTypeXXX] Type of foundation wall
  # @param thick_in [Double] Thickness of the siding (in)
  # @return [Material] The material object
  def self.FoundationWallMaterial(type, thick_in)
    case type
    when HPXML::FoundationWallTypeSolidConcrete
      return Material.Concrete(thick_in)
    when HPXML::FoundationWallTypeDoubleBrick
      return new(name: "#{type} #{thick_in} in.", thick_in: thick_in, mat_base: BaseMaterial.Brick, tAbs: 0.9)
    when HPXML::FoundationWallTypeWood
      # Open wood cavity wall, so just assume 0.5" of sheathing
      return new(name: "#{type} #{thick_in} in.", thick_in: 0.5, mat_base: BaseMaterial.Wood, tAbs: 0.9)
    # Concrete block conductivity values below derived from Table 2 of
    # https://ncma.org/resource/rvalues-ufactors-of-single-wythe-concrete-masonry-walls/. Values
    # for 6-in thickness and 115 pcf, with interior/exterior films removed (R-0.68/R-0.17).
    when HPXML::FoundationWallTypeConcreteBlockSolidCore
      return new(name: "#{type} #{thick_in} in.", thick_in: thick_in, k_in: 8.5, rho: 115.0, cp: 0.2, tAbs: 0.9)
    when HPXML::FoundationWallTypeConcreteBlock
      return new(name: "#{type} #{thick_in} in.", thick_in: thick_in, k_in: 5.0, rho: 45.0, cp: 0.2, tAbs: 0.9)
    when HPXML::FoundationWallTypeConcreteBlockPerliteCore
      return new(name: "#{type} #{thick_in} in.", thick_in: thick_in, k_in: 2.0, rho: 67.0, cp: 0.2, tAbs: 0.9)
    when HPXML::FoundationWallTypeConcreteBlockFoamCore
      return new(name: "#{type} #{thick_in} in.", thick_in: thick_in, k_in: 1.8, rho: 67.0, cp: 0.2, tAbs: 0.9)
    when HPXML::FoundationWallTypeConcreteBlockVermiculiteCore
      return new(name: "#{type} #{thick_in} in.", thick_in: thick_in, k_in: 2.1, rho: 67.0, cp: 0.2, tAbs: 0.9)
    end

    fail "Unexpected type: #{type}."
  end

  # Creates a material for the wall interior finish (e.g., gypsum board/drywall).
  #
  # @param type [HPXML::InteriorFinishXXX] Type of interior finish
  # @param thick_in [Double] Thickness of the siding (in)
  # @return [Material] The material object
  def self.InteriorFinishMaterial(type, thick_in = nil)
    if (type == HPXML::InteriorFinishNotPresent) || (!thick_in.nil? && thick_in <= 0)
      return
    else
      thick_in = 0.5 if thick_in.nil?
      case type
      when HPXML::InteriorFinishGypsumBoard, HPXML::InteriorFinishGypsumCompositeBoard, HPXML::InteriorFinishPlaster
        return new(name: type, thick_in: thick_in, mat_base: BaseMaterial.Gypsum)
      when HPXML::InteriorFinishWood
        return new(name: type, thick_in: thick_in, mat_base: BaseMaterial.Wood)
      end
    end

    fail "Unexpected type: #{type}."
  end

  # Creates a material for the soil.
  #
  # @param thick_in [Double] Thickness of the soil (in)
  # @param k_in [Double] Conductivity (Btu-in/h-ft2-F)
  # @return [Material] The material object
  def self.Soil(thick_in, k_in)
    return new(name: "soil #{thick_in} in.", thick_in: thick_in, mat_base: BaseMaterial.Soil(k_in))
  end

  # Creates a material for a 2x? wood stud.
  #
  # @param nominal_thick_in [Double] The nominal thickness of the wood stud, e.g. 4 for 2x4 (in)
  # @return [Material] The material object
  def self.Stud2x(nominal_thick_in)
    actual_thick_in = { 1 => 0.75,
                        2 => 1.5,
                        3 => 2.5,
                        4 => 3.5,
                        6 => 5.5,
                        8 => 7.25,
                        10 => 9.25,
                        12 => 11.25 }[nominal_thick_in]
    fail "Unexpected stud nominal thickness: #{nominal_thick_in}." if actual_thick_in.nil?

    return new(name: "stud 2x#{nominal_thick_in}", thick_in: actual_thick_in, mat_base: BaseMaterial.Wood)
  end

  # Creates a material for OSB sheathing.
  #
  # @param thick_in [Double] Thickness of the sheathing (in)
  # @return [Material] The material object
  def self.OSBSheathing(thick_in)
    return new(name: "osb #{thick_in} in.", thick_in: thick_in, mat_base: BaseMaterial.Wood)
  end

  # Creates a material for a radiant batter (in an attic).
  #
  # @param install_grade [Integer] Installation grade (1-3)
  # @param is_attic_floor [Boolean] True if the radiant barrier is on the attic floor (as opposed to roof of the attic)
  # @return [Material] The material object
  def self.RadiantBarrier(grade, is_attic_floor = false)
    # FUTURE: Merge w/ Constructions.get_gap_factor
    if grade == 1
      gap_frac = 0.0
    elsif grade == 2
      gap_frac = 0.02
    elsif grade == 3
      gap_frac = 0.05
    end
    if is_attic_floor
      # Assume reduced effectiveness due to accumulation of dust per https://web.ornl.gov/sci/buildings/tools/radiant/rb2/
      rb_emittance = 0.5
    else
      # ASTM C1313 3.2.1 defines a radiant barrier as <= 0.1
      rb_emittance = 0.05
    end
    non_rb_emittance = 0.90
    emittance = rb_emittance * (1.0 - gap_frac) + non_rb_emittance * gap_frac
    return new(name: 'radiant barrier', thick_in: 0.0084, k_in: 1629.6, rho: 168.6, cp: 0.22, tAbs: emittance, sAbs: 0.05)
  end

  # Creates a material for the roof exterior layers (e.g. shingles + osb sheathing).
  #
  # @param roof_type [HPXML::RoofTypeXXX] Type of roof material
  # @param osb_thick_in [Double] Thickness of the OSB sheathing (in)
  # @return [Material] The material object
  def self.RoofMaterialAndSheathing(roof_type, osb_thick_in = 0.625)
    # Note: We include OSB sheathing in the same material layer to prevent possible attic
    # temperature out of bounds errors in E+.
    #
    # From https://bigladdersoftware.com/epx/docs/22-2/engineering-reference/conduction-through-the-walls.html#conduction-transfer-function-ctf-calculations-special-case-r-value-only-layers:
    # "There are potential issues with having a resistance-only layer at either the inner or
    # outer most layers of a construction. A little or no mass layer there could receive intense
    # thermal radiation from internal sources or the sun causing the temperature at the inner or
    # outer surface to achieve very high levels."
    #
    # In the case of an attic roof, the outer most material can see significant solar radiation.
    mat_osb = OSBSheathing(osb_thick_in)
    case roof_type
    when HPXML::RoofTypeMetal
      mat_roof = new(name: roof_type, thick_in: 0.02, k_in: 346.9, rho: 487.0, cp: 0.11)
    when HPXML::RoofTypeAsphaltShingles, HPXML::RoofTypeWoodShingles, HPXML::RoofTypeShingles, HPXML::RoofTypeCool
      mat_roof = new(name: roof_type, thick_in: 0.25, k_in: 1.128, rho: 70.0, cp: 0.35)
    when HPXML::RoofTypeConcrete
      mat_roof = new(name: roof_type, thick_in: 0.75, k_in: 7.63, rho: 131.1, cp: 0.199)
    when HPXML::RoofTypeClayTile
      mat_roof = new(name: roof_type, thick_in: 0.75, k_in: 5.83, rho: 118.6, cp: 0.191)
    when HPXML::RoofTypeEPS
      mat_roof = new(name: roof_type, thick_in: 1.0, mat_base: BaseMaterial.InsulationRigid)
    when HPXML::RoofTypePlasticRubber
      mat_roof = new(name: roof_type, thick_in: 0.25, k_in: 2.78, rho: 110.8, cp: 0.36)
    else
      fail "Unexpected roof type: #{roof_type}."
    end

    return combine(mat_roof, mat_osb, "#{mat_roof.name} + #{mat_osb.name}")
  end
end

# Object that stores base material properties for opaque materials.
# Material objects (e.g., 2x4 wood stud) can be created that derive
# from the base material (e.g., wood).
class BaseMaterial
  # @param rho [Double] Density (lb/ft3)
  # @param cp [Double] Specific heat (Btu/lb-F)
  # @param k_in [Double] Conductivity (Btu-in/h-ft2-F)
  def initialize(rho:, cp:, k_in: nil)
    @rho = rho
    @cp = cp
    @k_in = k_in
  end

  attr_accessor :rho, :cp, :k_in

  # Creates a base material with properties for gypsum.
  #
  # @return [BaseMaterial] The base material object
  def self.Gypsum
    return new(rho: 50.0, cp: 0.2, k_in: 1.1112)
  end

  # Creates a base material with properties for wood.
  #
  # @return [BaseMaterial] The base material object
  def self.Wood
    return new(rho: 32.0, cp: 0.29, k_in: 0.8004)
  end

  # Creates a base material with properties for concrete.
  #
  # @return [BaseMaterial] The base material object
  def self.Concrete
    return new(rho: 140.0, cp: 0.2, k_in: 12.5)
  end

  # Creates a base material with properties for light-weight furniture.
  #
  # @return [BaseMaterial] The base material object
  def self.FurnitureLightWeight
    return new(rho: 40.0, cp: 0.29, k_in: 0.8004)
  end

  # Creates a base material with properties for heavy-weight furniture.
  #
  # @return [BaseMaterial] The base material object
  def self.FurnitureHeavyWeight
    return new(rho: 80.0, cp: 0.35, k_in: 1.1268)
  end

  # Creates a base material with properties for gypcrete.
  #
  # @return [BaseMaterial] The base material object
  def self.Gypcrete
    # http://www.maxxon.com/gyp-crete/data
    return new(rho: 100.0, cp: 0.223, k_in: 4.7424)
  end

  # Creates a base material with properties for rigid insulation.
  #
  # @return [BaseMaterial] The base material object
  def self.InsulationRigid
    return new(rho: 2.0, cp: 0.29, k_in: 0.204)
  end

  # Creates a base material with properties for densepack cellulose insulation.
  #
  # @return [BaseMaterial] The base material object
  def self.InsulationCelluloseDensepack
    return new(rho: 3.5, cp: 0.25)
  end

  # Creates a base material with properties for loosefill cellulose insulation.
  #
  # @return [BaseMaterial] The base material object
  def self.InsulationCelluloseLoosefill
    return new(rho: 1.5, cp: 0.25)
  end

  # Creates a base material with properties for densepack fiberglass insulation.
  #
  # @return [BaseMaterial] The base material object
  def self.InsulationFiberglassDensepack
    return new(rho: 2.2, cp: 0.25)
  end

  # Creates a base material with properties for loosefill fiberglass insulation.
  #
  # @return [BaseMaterial] The base material object
  def self.InsulationFiberglassLoosefill
    return new(rho: 0.5, cp: 0.25)
  end

  # Creates a base material with properties for generic densepack insulation.
  #
  # @return [BaseMaterial] The base material object
  def self.InsulationGenericDensepack
    return new(rho: (self.InsulationFiberglassDensepack.rho + self.InsulationCelluloseDensepack.rho) / 2.0, cp: 0.25)
  end

  # Creates a base material with properties for generic loosefill insulation.
  #
  # @return [BaseMaterial] The base material object
  def self.InsulationGenericLoosefill
    return new(rho: (self.InsulationFiberglassLoosefill.rho + self.InsulationCelluloseLoosefill.rho) / 2.0, cp: 0.25)
  end

  # Creates a base material with properties for soil.
  #
  # @param k_in [Double] Conductivity (Btu-in/h-ft2-F)
  # @return [BaseMaterial] The base material object
  def self.Soil(k_in)
    return new(rho: 115.0, cp: 0.1, k_in: k_in)
  end

  # Creates a base material with properties for brick.
  #
  # @return [BaseMaterial] The base material object
  def self.Brick
    return new(rho: 110.0, cp: 0.19, k_in: 5.5)
  end

  # Creates a base material with properties for vinyl.
  #
  # @return [BaseMaterial] The base material object
  def self.Vinyl
    return new(rho: 11.1, cp: 0.25, k_in: 0.62)
  end

  # Creates a base material with properties for stucco.
  #
  # @return [BaseMaterial] The base material object
  def self.Stucco
    return new(rho: 80.0, cp: 0.21, k_in: 4.5)
  end

  # Creates a base material with properties for stone.
  #
  # @return [BaseMaterial] The base material object
  def self.Stone
    return new(rho: 140.0, cp: 0.2, k_in: 12.5)
  end

  # Creates a base material with properties for strawbale.
  #
  # @return [BaseMaterial] The base material object
  def self.StrawBale
    return new(rho: 11.1652, cp: 0.2991, k_in: 0.4164)
  end
end

# Object that stores material properties for glazing materials.
class GlazingMaterial
  # @param name [String] Glazing material name
  # @param ufactor [Double] Full assembly glazing U-factor (Btu/F-ft2-hr)
  # @param shgc [Double] Full assembly glazing solar heat gain coefficient (0-1)
  def initialize(name:, ufactor:, shgc:)
    @name = name
    @ufactor = ufactor
    @shgc = shgc
  end

  attr_accessor :name, :ufactor, :shgc
end

# Object that stores material properties for liquid materials.
class Liquid
  # @param rho [Double] Density (lb/ft3)
  # @param cp [Double] Specific heat (Btu/lb-F)
  # @param k [Double] Thermal Conductivity (Btu/h-ft-R)
  # @param h_fg [Double] Latent Heat of Vaporization (Btu/lb)
  # @param t_frz [Double] Freezing Temperature (F)
  def initialize(rho: nil, cp: nil, k: nil, h_fg: nil, t_frz: nil)
    @rho = rho
    @cp = cp
    @k = k
    @h_fg = h_fg
    @t_frz = t_frz
  end

  attr_accessor :rho, :cp, :k, :mu, :h_fg, :t_frz

  # Creates a liquid with properties for water at STP.
  #
  # @return [Liquid] The liquid object
  def self.H2O_l
    return new(rho: 62.32, cp: 0.9991, k: 0.3386, h_fg: 1055, t_frz: 32.0) # Source: EES
  end
end

# Object that stores material properties for gas materials.
class Gas
  # @param rho [Double] Density (lb/ft3)
  # @param cp [Double] Specific heat (Btu/lb-F)
  # @param k [Double] Conductivity (Btu/hr-ft-F)
  # @param m [Double] Molecular Weight (lb/lbmol)
  def initialize(rho: nil, cp: nil, k: nil, m: nil)
    @rho = rho
    @cp = cp
    @k = k
    @m = m
    if @m
      gas_constant = 1.9858 # Gas Constant (Btu/lbmol-R)
      @r = gas_constant / m # Gas Constant (Btu/lbm-R)
    else
      @r = nil
    end
  end

  attr_accessor :rho, :cp, :k, :m, :r

  # Creates a gas with properties for air at STP.
  #
  # @return [Gas] The gas object
  def self.Air
    return new(rho: 0.07518, cp: 0.2399, k: 0.01452, m: 28.97) # Source: EES
  end

  # Creates a gas with properties for water vapor at STP.
  #
  # @return [Gas] The gas object
  def self.H2O_v
    return new(cp: 0.4495, m: 18.02) # Source: EES
  end

  # The molecular weight ratio of water vapor to air.
  #
  # @return [Double] The ratio
  def self.PsychMassRat
    return self.H2O_v.m / self.Air.m
  end
end
