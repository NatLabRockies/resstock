# frozen_string_literal: true

# Collection of helper methods for performing unit conversions.
module UnitConversions
  @Scalars = {
    # Energy
    ['btu', 'j'] => 1055.05585262,
    ['j', 'btu'] => 3412.141633127942 / 1000.0 / 3600.0,
    ['j', 'kbtu'] => 3412.141633127942 / 1000.0 / 3600.0 / 1000.0,
    ['j', 'mbtu'] => 3412.141633127942 / 1000.0 / 3600.0 / 1000000.0,
    ['j', 'therm'] => 3412.141633127942 / 1000.0 / 3600.0 / 1000.0 / 100.0,
    ['kj', 'btu'] => 0.9478171203133172,
    ['gj', 'mbtu'] => 0.9478171203133172,
    ['gj', 'kwh'] => 277.778,
    ['gj', 'therm'] => 9.48043,
    ['kwh', 'btu'] => 3412.141633127942,
    ['kwh', 'j'] => 3600000.0,
    ['mwh', 'j'] => 3600000000.0,
    ['wh', 'gj'] => 0.0000036,
    ['kwh', 'mwh'] => 1.0 / 1000.0,
    ['kwh', 'wh'] => 1000.0,
    ['mbtu', 'kwh'] => 293.0710701722222,
    ['kbtu', 'kwh'] => 293.0710701722222 / 1000.0,
    ['mbtu', 'therm'] => 10.0,
    ['mbtu', 'wh'] => 293071.0701722222,
    ['therm', 'btu'] => 100000.0,
    ['therm', 'kbtu'] => 100.0,
    ['therm', 'kwh'] => 29.307107017222222,
    ['therm', 'wh'] => 29307.10701722222,
    ['wh', 'btu'] => 3.412141633127942,
    ['wh', 'kbtu'] => 0.003412141633127942,
    ['kbtu', 'btu'] => 1000.0,
    ['kbtu', 'mbtu'] => 0.001,
    ['gal_fuel_oil', 'kbtu'] => 139,
    ['gal_fuel_oil', 'mbtu'] => 139 / 1000.0,
    ['gal_fuel_oil', 'j'] => 139 * 1000.0 * 1055.05585262,
    ['gal_propane', 'kbtu'] => 91.6,
    ['gal_propane', 'mbtu'] => 91.6 / 1000.0,
    ['gal_propane', 'j'] => 91.6 * 1000.0 * 1055.05585262,

    # Power
    ['btu/hr', 'w'] => 0.2930710701722222,
    ['kbtu/hr', 'btu/hr'] => 1000.0,
    ['kbtu/hr', 'w'] => 293.0710701722222,
    ['kw', 'w'] => 1000.0,
    ['ton', 'btu/hr'] => 12000.0,
    ['ton', 'kbtu/hr'] => 12.0,
    ['ton', 'w'] => 3516.85284207,
    ['w', 'btu/hr'] => 3.412141633127942,
    ['kw', 'btu/hr'] => 3412.141633127942,
    ['kbtu/hr', 'kw'] => 0.2930710701722222,

    # Power Flux
    ['w/m^2', 'btu/(hr*ft^2)'] => 0.3169983306281505,

    # Temperature
    ['deltac', 'deltaf'] => 1.8,

    # Specific Heat
    ['btu/(lbm*r)', 'j/(kg*k)'] => 4187.0, # by mass
    ['btu/(ft^3*f)', 'j/(m^3*k)'] => 67100.0, # by volume
    ['btu/(lbm*r)', 'wh/(kg*k)'] => 1.1632,

    # Length
    ['ft', 'in'] => 12.0,
    ['ft', 'm'] => 0.3048,
    ['in', 'm'] => 0.0254,
    ['m', 'mm'] => 1000.0,
    ['in', 'mm'] => 25.4,

    # Area
    ['cm^2', 'ft^2'] => 1.0 / 929.0304,
    ['ft^2', 'cm^2'] => 929.0304,
    ['ft^2', 'in^2'] => 144.0,
    ['ft^2', 'm^2'] => 0.09290304,
    ['m^2', 'ft^2'] => 1.0 / 0.09290304,

    # Volume
    ['ft^3', 'gal'] => 7.480519480579059,
    ['ft^3', 'l'] => 28.316846591999997,
    ['ft^3', 'm^3'] => 0.028316846592000004,
    ['gal', 'in^3'] => 231.0,
    ['gal', 'm^3'] => 0.0037854117839698515,
    ['l', 'pint'] => 2.1133764,
    ['pint', 'l'] => 0.47317647,

    # Mass
    ['lbm', 'kg'] => 0.45359237,

    # Volume Flow Rate
    ['m^3/s', 'gal/min'] => 15850.323141615143,
    ['m^3/s', 'cfm'] => 2118.880003289315,
    ['m^3/s', 'ft^3/min'] => 2118.880003289315,

    # Mass Flow Rate
    ['lbm/min', 'kg/hr'] => 27.2155422,
    ['lbm/min', 'kg/s'] => 27.2155422 / 3600.0,

    # Time
    ['day', 'hr'] => 24.0,
    ['hr', 'min'] => 60.0,
    ['hr', 's'] => 3600.0,
    ['min', 's'] => 60.0,
    ['yr', 'day'] => 365.0,
    ['yr', 'hr'] => 8760.0,

    # Velocity
    ['knots', 'm/s'] => 0.51444444,
    ['mph', 'm/s'] => 0.44704,
    ['m/s', 'knots'] => 1.9438445,
    ['m/s', 'mph'] => 2.2369363,

    # Pressure & Density
    ['atm', 'btu/ft^3'] => 2.719,
    ['atm', 'kpa'] => 101.325,
    ['atm', 'psi'] => 14.692,
    ['inh2o', 'pa'] => 249.1,
    ['lbm/(ft*s^2)', 'inh2o'] => 0.005974,
    ['lbm/ft^3', 'inh2o/mph^2'] => 0.01285,
    ['lbm/ft^3', 'kg/m^3'] => 16.02,
    ['psi', 'btu/ft^3'] => 0.185,
    ['psi', 'kpa'] => 6.89475729,
    ['psi', 'pa'] => 6.89475729 * 1000.0,

    # Angles
    ['rad', 'deg'] => 180.0 / Math::PI,

    # R-Value
    ['hr*ft^2*f/btu', 'm^2*k/w'] => 0.1761,

    # U-Factor
    ['btu/(hr*ft^2*f)', 'w/(m^2*k)'] => 5.678,

    # UA
    ['btu/(hr*f)', 'w/k'] => 0.5275,

    # Thermal Conductivity
    ['btu/(hr*ft*r)', 'w/(m*k)'] => 1.731,
    ['btu*in/(hr*ft^2*r)', 'w/(m*k)'] => 0.14425,

    # Thermal Diffusivity
    ['m^2/s', 'ft^2/hr'] => 38750.1,

    # Infiltration
    ['ft^2/(s^2*r)', 'l^2/(s^2*cm^4*k)'] => 0.001672,
    ['inh2o/mph^2', 'pa*s^2/m^2'] => 1246.0,
    ['inh2o/r', 'pa/k'] => 448.4,

    # Humidity
    ['lbm/lbm', 'grains'] => 7000.0,
  }

  # Converts a number from one unit (e.g., 'ft') to another unit (e.g, 'm').
  #
  # As there is a *significant* performance penalty to using OpenStudio's built-in
  # unit convert() method, we use our own approach here.
  #
  # @param x [Double] value to be converted from
  # @param from [String] type of unit to convert from
  # @param to [String] type of unit to convert to
  # @return [Double] value converted to
  def self.convert(x, from, to)
    from_d = from.downcase
    to_d = to.downcase

    return x if from_d == to_d

    # Try forward
    key = [from_d, to_d]
    scalar = @Scalars[key]
    if not scalar.nil?
      return x * scalar
    end

    # Try reverse
    key = [to_d, from_d]
    scalar = @Scalars[key]
    if not scalar.nil?
      return x / scalar
    end

    # Non-scalar conversions
    key = [from_d, to_d]
    if key == ['c', 'f']
      return 1.8 * x + 32.0
    elsif key == ['c', 'k']
      return x + 273.15
    elsif key == ['f', 'c']
      return (x - 32.0) / 1.8
    elsif key == ['f', 'k']
      return (x - 32.0) / 1.8 + 273.15
    elsif key == ['f', 'r']
      return x + 459.67
    elsif key == ['k', 'c']
      return x - 273.15
    elsif key == ['r', 'f']
      return x - 459.67
    end

    fail "Unhandled unit conversion from #{from_d} to #{to_d}."
  end
end
