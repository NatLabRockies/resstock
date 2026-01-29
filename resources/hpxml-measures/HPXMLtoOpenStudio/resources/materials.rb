# frozen_string_literal: true

# TODO
class Material
  # @param name [String] Material name
  # @param thick_in [Double] Thickness (in)
  # @param mat_base [TODO] Base material object that defines k, rho, and can be overridden with values for those arguments
  # @param k_in [TODO] Conductivity (Btu-in/h-ft2-F)
  # @param rho [TODO] Density (lb/ft3)
  # @param cp [TODO] Specific heat (Btu/lb-F)
  # @param tAbs [TODO] thermal absorptance (emittance); 0.9 is EnergyPlus default
  # @param sAbs [TODO] solar absorptance; 0.7 is EnergyPlus default
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
      @rvalue = rvalue # h-ft2-F/Btu
    elsif (not @thick_in.nil?) && (not @k_in.nil?)
      if @k_in > 0
        @rvalue = @thick_in / @k_in # h-ft2-F/Btu
      else
        @rvalue = @thick_in / 10000000.0 # h-ft2-F/Btu
      end
    end
  end

  attr_accessor :name, :thick, :thick_in, :k, :k_in, :rho, :cp, :rvalue, :tAbs, :sAbs

  # TODO
  #
  # @param thick_in [TODO] TODO
  # @return [TODO] TODO
  def self.AirCavityClosed(thick_in)
    rvalue = 1.0 # hr*ft*F/Btu (Assume for all air gap configurations since there is no correction for direction of heat flow in the simulation tools)
    return new(thick_in: thick_in, k_in: thick_in / rvalue, rho: Gas.Air.rho, cp: Gas.Air.cp)
  end

  # TODO
  #
  # @param thick_in [TODO] TODO
  # @return [TODO] TODO
  def self.AirCavityOpen(thick_in)
    return new(thick_in: thick_in, k_in: 10000000.0, rho: Gas.Air.rho, cp: Gas.Air.cp)
  end

  # TODO
  #
  # @param rvalue [TODO] TODO
  # @return [TODO] TODO
  def self.AirFilm(rvalue)
    return new(name: Constants::AirFilm, thick_in: 1.0, k_in: 1.0 / rvalue)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.AirFilmOutside
    rvalue = 0.197 # hr-ft-F/Btu
    return self.AirFilm(rvalue)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.AirFilmOutsideASHRAE140
    return self.AirFilm(0.174)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.AirFilmVertical
    rvalue = 0.68 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    return self.AirFilm(rvalue)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.AirFilmVerticalASHRAE140
    return self.AirFilm(0.685)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.AirFilmFlatEnhanced
    rvalue = 0.61 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    return self.AirFilm(rvalue)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.AirFilmFlatReduced
    rvalue = 0.92 # hr-ft-F/Btu (ASHRAE 2005, F25.2, Table 1)
    return self.AirFilm(rvalue)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.AirFilmFloorAverage
    # For floors between conditioned spaces where heat does not flow across
    # the floor; heat transfer is only important with regards to the thermal
    rvalue = (self.AirFilmFlatReduced.rvalue + self.AirFilmFlatEnhanced.rvalue) / 2.0 # hr-ft-F/Btu
    return self.AirFilm(rvalue)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.AirFilmFloorReduced
    # For floors above unconditioned basement spaces, where heat will
    # always flow down through the floor.
    rvalue = self.AirFilmFlatReduced.rvalue # hr-ft-F/Btu
    return self.AirFilm(rvalue)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.AirFilmFloorASHRAE140
    return self.AirFilm(0.765)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.AirFilmFloorZeroWindASHRAE140
    return self.AirFilm(0.455)
  end

  # TODO
  #
  # @param roof_pitch [TODO] TODO
  # @return [TODO] TODO
  def self.AirFilmSlopeEnhanced(roof_pitch)
    # Correlation functions used to interpolate between values provided
    # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
    # 0, 45, and 90 degrees. Values are for non-reflective materials of
    # emissivity = 0.90.
    rvalue = 0.002 * Math::exp(0.0398 * roof_pitch) + 0.608 # hr-ft-F/Btu (evaluates to film_flat_enhanced at 0 degrees, 0.62 at 45 degrees, and film_vertical at 90 degrees)
    return self.AirFilm(rvalue)
  end

  # TODO
  #
  # @param roof_pitch [TODO] TODO
  # @return [TODO] TODO
  def self.AirFilmSlopeReduced(roof_pitch)
    # Correlation functions used to interpolate between values provided
    # in ASHRAE 2005, F25.2, Table 1 - which only provides values for
    # 0, 45, and 90 degrees. Values are for non-reflective materials of
    # emissivity = 0.90.
    rvalue = 0.32 * Math::exp(-0.0154 * roof_pitch) + 0.6 # hr-ft-F/Btu (evaluates to film_flat_reduced at 0 degrees, 0.76 at 45 degrees, and film_vertical at 90 degrees)
    return self.AirFilm(rvalue)
  end

  # TODO
  #
  # @param roof_pitch [TODO] TODO
  # @return [TODO] TODO
  def self.AirFilmRoof(roof_pitch)
    rvalue = (self.AirFilmSlopeEnhanced(roof_pitch).rvalue + self.AirFilmSlopeReduced(roof_pitch).rvalue) / 2.0 # hr-ft-F/Btu
    return self.AirFilm(rvalue)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.AirFilmRoofASHRAE140
    return self.AirFilm(0.752)
  end

  # TODO
  #
  # @param floorFraction [TODO] TODO
  # @param rvalue [TODO] TODO
  # @return [TODO] TODO
  def self.CoveringBare(floorFraction = 0.8, rvalue = 2.08)
    # Combined layer of, e.g., carpet and bare floor
    thick_in = 0.5 # in
    return new(name: 'floor covering', thick_in: thick_in, k_in: thick_in / (rvalue * floorFraction), rho: 3.4, cp: 0.32, tAbs: 0.9, sAbs: 0.9)
  end

  # TODO
  #
  # @param thick_in [TODO] TODO
  # @return [TODO] TODO
  def self.Concrete(thick_in)
    return new(name: "concrete #{thick_in} in.", thick_in: thick_in, mat_base: BaseMaterial.Concrete, tAbs: 0.9)
  end

  # TODO
  #
  # @param type [TODO] TODO
  # @param thick_in [TODO] TODO
  # @return [TODO] TODO
  def self.ExteriorFinishMaterial(type, thick_in = nil)
    if (type == HPXML::SidingTypeNone) || (!thick_in.nil? && thick_in <= 0)
      return
    end

    case type
    when HPXML::SidingTypeAsbestos
      thick_in = 0.25 if thick_in.nil?
      return new(name: type, thick_in: thick_in, k_in: 4.20, rho: 118.6, cp: 0.24)
    when HPXML::SidingTypeBrick
      thick_in = 4.0 if thick_in.nil?
      return new(name: type, thick_in: thick_in, mat_base: BaseMaterial.Brick)
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
      thick_in = 1.0 if thick_in.nil?
      return new(name: type, thick_in: thick_in, k_in: 0.71, rho: 34.0, cp: 0.28)
    end

    fail "Unexpected type: #{type}."
  end

  # TODO
  #
  # @param type [TODO] TODO
  # @param thick_in [TODO] TODO
  # @return [TODO] TODO
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

  # TODO
  #
  # @param type [TODO] TODO
  # @param thick_in [TODO] TODO
  # @return [TODO] TODO
  def self.InteriorFinishMaterial(type, thick_in = nil)
    if (type == HPXML::InteriorFinishNone) || (!thick_in.nil? && thick_in <= 0)
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

  # TODO
  #
  # @param thick_in [TODO] TODO
  # @param k_in [TODO] TODO
  # @return [TODO] TODO
  def self.Soil(thick_in, k_in)
    return new(name: "soil #{thick_in} in.", thick_in: thick_in, mat_base: BaseMaterial.Soil(k_in))
  end

  # TODO
  #
  # @param thick_in [TODO] TODO
  # @return [TODO] TODO
  def self.Stud2x(thick_in)
    return new(name: "stud 2x #{thick_in} in.", thick_in: thick_in, mat_base: BaseMaterial.Wood)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.Stud2x4
    return new(name: 'stud 2x4', thick_in: 3.5, mat_base: BaseMaterial.Wood)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.Stud2x6
    return new(name: 'stud 2x6', thick_in: 5.5, mat_base: BaseMaterial.Wood)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.Stud2x8
    return new(name: 'stud 2x8', thick_in: 7.25, mat_base: BaseMaterial.Wood)
  end

  # TODO
  #
  # @param thick_in [TODO] TODO
  # @return [TODO] TODO
  def self.OSBSheathing(thick_in)
    return new(name: "osb sheathing #{thick_in} in.", thick_in: thick_in, mat_base: BaseMaterial.Wood)
  end

  # TODO
  #
  # @param grade [TODO] TODO
  # @param is_attic_floor [TODO] TODO
  # @return [TODO] TODO
  def self.RadiantBarrier(grade, is_attic_floor)
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

  # TODO
  #
  # @param type [TODO] TODO
  # @param thick_in [TODO] TODO
  # @return [TODO] TODO
  def self.RoofMaterial(type, thick_in = nil)
    case type
    when HPXML::RoofTypeMetal
      thick_in = 0.02 if thick_in.nil?
      return new(name: type, thick_in: thick_in, k_in: 346.9, rho: 487.0, cp: 0.11)
    when HPXML::RoofTypeAsphaltShingles, HPXML::RoofTypeWoodShingles, HPXML::RoofTypeShingles, HPXML::RoofTypeCool
      thick_in = 0.25 if thick_in.nil?
      return new(name: type, thick_in: thick_in, k_in: 1.128, rho: 70.0, cp: 0.35)
    when HPXML::RoofTypeConcrete
      thick_in = 0.75 if thick_in.nil?
      return new(name: type, thick_in: thick_in, k_in: 7.63, rho: 131.1, cp: 0.199)
    when HPXML::RoofTypeClayTile
      thick_in = 0.75 if thick_in.nil?
      return new(name: type, thick_in: thick_in, k_in: 5.83, rho: 118.6, cp: 0.191)
    when HPXML::RoofTypeEPS
      thick_in = 1.0 if thick_in.nil?
      return new(name: type, thick_in: thick_in, mat_base: BaseMaterial.InsulationRigid)
    when HPXML::RoofTypePlasticRubber
      thick_in = 0.25 if thick_in.nil?
      return new(name: type, thick_in: thick_in, k_in: 2.78, rho: 110.8, cp: 0.36)
    end

    fail "Unexpected type: #{type}."
  end
end

# TODO
class BaseMaterial
  # @param rho [TODO] TODO
  # @param cp [TODO] TODO
  # @param k_in [TODO] TODO
  def initialize(rho:, cp:, k_in: nil)
    @rho = rho
    @cp = cp
    @k_in = k_in
  end

  attr_accessor :rho, :cp, :k_in

  # TODO
  #
  # @return [TODO] TODO
  def self.Gypsum
    return new(rho: 50.0, cp: 0.2, k_in: 1.1112)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.Wood
    return new(rho: 32.0, cp: 0.29, k_in: 0.8004)
  end

  # TODO
  #
  # @param thick_in [TODO] TODO
  # @return [TODO] TODO
  def self.Concrete
    return new(rho: 140.0, cp: 0.2, k_in: 12.5)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.FurnitureLightWeight
    return new(rho: 40.0, cp: 0.29, k_in: 0.8004)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.FurnitureHeavyWeight
    return new(rho: 80.0, cp: 0.35, k_in: 1.1268)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.Gypcrete
    # http://www.maxxon.com/gyp-crete/data
    return new(rho: 100.0, cp: 0.223, k_in: 4.7424)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.InsulationRigid
    return new(rho: 2.0, cp: 0.29, k_in: 0.204)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.InsulationCelluloseDensepack
    return new(rho: 3.5, cp: 0.25)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.InsulationCelluloseLoosefill
    return new(rho: 1.5, cp: 0.25)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.InsulationFiberglassDensepack
    return new(rho: 2.2, cp: 0.25)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.InsulationFiberglassLoosefill
    return new(rho: 0.5, cp: 0.25)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.InsulationGenericDensepack
    return new(rho: (self.InsulationFiberglassDensepack.rho + self.InsulationCelluloseDensepack.rho) / 2.0, cp: 0.25)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.InsulationGenericLoosefill
    return new(rho: (self.InsulationFiberglassLoosefill.rho + self.InsulationCelluloseLoosefill.rho) / 2.0, cp: 0.25)
  end

  # TODO
  #
  # @param thick_in [TODO] TODO
  # @param k_in [TODO] TODO
  # @return [TODO] TODO
  def self.Soil(k_in)
    return new(rho: 115.0, cp: 0.1, k_in: k_in)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.Brick
    return new(rho: 110.0, cp: 0.19, k_in: 5.5)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.Vinyl
    return new(rho: 11.1, cp: 0.25, k_in: 0.62)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.Stucco
    return new(rho: 80.0, cp: 0.21, k_in: 4.5)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.Stone
    return new(rho: 140.0, cp: 0.2, k_in: 12.5)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.StrawBale
    return new(rho: 11.1652, cp: 0.2991, k_in: 0.4164)
  end
end

# TODO
class GlazingMaterial
  # @param name [TODO] TODO
  # @param ufactor [TODO] TODO
  # @param shgc [TODO] TODO
  def initialize(name:, ufactor:, shgc:)
    @name = name
    @ufactor = ufactor
    @shgc = shgc
  end

  attr_accessor :name, :ufactor, :shgc
end

# TODO
class Liquid
  # @param rho [TODO] TODO
  # @param cp [TODO] TODO
  # @param k [TODO] TODO
  # @param h_fg [TODO] TODO
  # @param t_frz [TODO] TODO
  def initialize(rho: nil, cp: nil, k: nil, h_fg: nil, t_frz: nil)
    @rho = rho          # Density (lb/ft3)
    @cp = cp            # Specific Heat (Btu/lbm-R)
    @k = k              # Thermal Conductivity (Btu/h-ft-R)
    @h_fg = h_fg        # Latent Heat of Vaporization (Btu/lbm)
    @t_frz = t_frz      # Freezing Temperature (degF)
  end

  attr_accessor :rho, :cp, :k, :mu, :h_fg, :t_frz

  # TODO
  #
  # @return [TODO] TODO
  def self.H2O_l
    # From EES at STP
    return new(rho: 62.32, cp: 0.9991, k: 0.3386, h_fg: 1055, t_frz: 32.0)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.R22_l
    # Converted from EnthDR22 f77 in ResAC (Brandemuehl)
    return new(cp: 0.2732, h_fg: 100.5)
  end
end

# TODO
class Gas
  # @param rho [TODO] TODO
  # @param cp [TODO] TODO
  # @param k [TODO] TODO
  # @param m [TODO] TODO
  def initialize(rho: nil, cp: nil, k: nil, m: nil)
    @rho = rho # Density (lb/ft3)
    @cp = cp   # Specific Heat (Btu/lbm-R)
    @k = k     # Thermal Conductivity (Btu/h-ft-R)
    @m = m     # Molecular Weight (lbm/lbmol)
    if @m
      gas_constant = 1.9858 # Gas Constant (Btu/lbmol-R)
      @r = gas_constant / m # Gas Constant (Btu/lbm-R)
    else
      @r = nil
    end
  end

  attr_accessor :rho, :cp, :k, :m, :r

  # TODO
  #
  # @return [TODO] TODO
  def self.Air
    # From EES at STP
    return new(rho: 0.07518, cp: 0.2399, k: 0.01452, m: 28.97)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.H2O_v
    # From EES at STP
    return new(cp: 0.4495, m: 18.02)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.R22_v
    # Converted from EnthDR22 f77 in ResAC (Brandemuehl)
    return new(cp: 0.1697)
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.PsychMassRat
    return self.H2O_v.m / self.Air.m
  end
end
