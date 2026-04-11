# frozen_string_literal: true

# Collection of helper methods for performing psychrometric calculations.
module Psychrometrics
  # Calculate the latent heat of vaporization at a given drybulb temperature.
  # Valid for temperatures between 0 and 200 degC (32 - 392 degF)
  #
  # Source: Based on correlation from steam tables - "Introduction to
  # Thermodynamics, Classical and Statistical" by Sonntag and Wylen
  #
  # H_fg = 2518600 - 2757.1*T (J/kg with T in degC)
  #      = 2581600 - 2757.1*(T - 32)*5/9 (J/kg with T in degF)
  #      = 2581600 - 1531.72*T + 49015.1 (J/kg with T in degF)
  #      = 1083 - 0.6585*T + 21.07 (Btu/lbm with T in degF)
  #
  # @param t [Double] temperature (F)
  # @return [Double] latent heat of vaporization (Btu/lbm)
  def self.H_fg_fT(t)
    h_fg = 1083 - 0.6585 * t + 21.07

    return h_fg
  end

  # Calculate the saturation pressure of water vapor at a given temperature
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param tdb [Double] drybulb temperature (F)
  # @return [Double] saturated vapor pressure (psia)
  def self.Psat_fT(tdb)
    c1 = -1.0214165e4
    c2 = -4.8932428
    c3 = -5.3765794e-3
    c4 = 1.9202377e-7
    c5 = 3.5575832e-10
    c6 = -9.0344688e-14
    c7 = 4.1635019
    c8 = -1.0440397e4
    c9 = -1.1294650e1
    c10 = -2.7022355e-2
    c11 = 1.2890360e-5
    c12 = -2.4780681e-9
    c13 = 6.5459673

    t_abs = UnitConversions.convert(tdb, 'F', 'R')
    t_frz_abs = UnitConversions.convert(Liquid.H2O_l.t_frz, 'F', 'R')

    if t_abs < t_frz_abs
      # If below freezing, calculate saturation pressure over ice
      psat = Math.exp(c1 / t_abs + c2 + t_abs * (c3 + t_abs * (c4 + t_abs * (c5 + c6 * t_abs))) + c7 * Math.log(t_abs))
    else
      # If above freezing, calculate saturation pressure over liquid water
      psat = Math.exp(c8 / t_abs + c9 + t_abs * (c10 + t_abs * (c11 + c12 * t_abs)) + c13 * Math.log(t_abs))
    end
    return psat
  end

  # Calculate the saturation temperature of water vapor at a given pressure
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param p [Double] pressure (psia)
  # @return [Double] saturated vapor temperature (F)
  def self.Tsat_fP(runner, p)
    # Initialize
    tsat = 212.0 # (F)
    tsat1 = tsat # (F)
    tsat2 = tsat # (F)

    error = p - self.Psat_fT(tsat) # (psia)
    error1 = error # (psia)
    error2 = error # (psia)

    itmax = 50 # maximum iterations
    cvg = false

    for i in 1..itmax

      error = p - self.Psat_fT(tsat) # (psia)

      tsat, cvg, tsat1, error1, tsat2, error2 = MathTools.Iterate(tsat, error, tsat1, error1, tsat2, error2, i, cvg)

      if cvg
        break
      end

    end

    if !cvg && !runner.nil?
      runner.registerWarning('Tsat_fP failed to converge')
    end

    return tsat
  end

  # Calculate the drybulb temperature at saturation a given enthalpy and pressure.
  #
  # Source: Based on TAIRSAT f77 code in ResAC (Brandemuehl)
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param h [Double] enthalpy (Btu/lbm)
  # @param p [Double] pressure (psia)
  # @return [Double] drybulb temperature (F)
  def self.Tsat_fh_P(runner, h, p)
    # Initialize
    tdb = 50
    tdb1 = tdb # (F)
    tdb2 = tdb # (F)

    error = h - hsat_fT_P(tdb, p) # (Btu/lbm)
    error1 = error
    error2 = error

    itmax = 50 # maximum iterations
    cvg = false

    for i in 1..itmax

      error = h - hsat_fT_P(tdb, p) # (Btu/lbm)

      tdb, cvg, tdb1, error1, tdb2, error2 = MathTools.Iterate(tdb, error, tdb1, error1, tdb2, error2, i, cvg)

      if cvg
        break
      end

    end

    if !cvg && !runner.nil?
      runner.registerWarning('Tsat_fh_P failed to converge')
    end

    return tdb
  end

  # Calculate the density of dry air at a given drybulb temperature, humidity ratio, and pressure.
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param tdb [Double] drybulb temperature (F)
  # @param w [Double] humidity ratio (lbm/lbm)
  # @param p [Double] pressure (psia)
  # @return [Double] density of dry air (lbm/ft3)
  def self.rhoD_fT_w_P(tdb, w, p)
    pair = Gas.PsychMassRat * p / (Gas.PsychMassRat + w) # (psia)
    rhoD = UnitConversions.convert(pair, 'psi', 'Btu/ft^3') / Gas.Air.r / UnitConversions.convert(tdb, 'F', 'R') # (lbm/ft3)

    return rhoD
  end

  # Calculate the enthalpy at a given drybulb temperature and humidity ratio (SI units).
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param tdb [Double] drybulb temperature(C)
  # @param w [Double] humidity ratio (kg/kg)
  # @return [Double] enthalpy (J/kg)
  def self.h_fT_w_SI(tdb, w)
    h = 1000.0 * (1.006 * tdb + w * (2501.0 + 1.86 * tdb))
    return h
  end

  # Calculate the enthalpy at a given drybulb temperature and humidity ratio.
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param tdb [Double] drybulb temperature (F)
  # @param w [Double] humidity ratio (lbm/lbm)
  # @return [Double] enthalpy (Btu/lb)
  def self.h_fT_w(tdb, w)
    h = h_fT_w_SI(UnitConversions.convert(tdb, 'F', 'C'), w)
    h *= UnitConversions.convert(1.0, 'J', 'Btu') * UnitConversions.convert(1.0, 'lbm', 'kg')
    return h
  end

  # Calculate the humidity ratio at a given drybulb temperature and enthalpy (SI units).
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param tdb [Double] drybulb temperature(C)
  # @param h [Double] enthalpy (J/kg)
  # @return [Double] humidity ratio (kg/kg)
  def self.w_fT_h_SI(tdb, h)
    w = (h / 1000.0 - 1.006 * tdb) / (2501.0 + 1.86 * tdb)
    return w
  end

  # Calculate standard pressure of air at a given altitude
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param z [Double] altitude (ft)
  # @return [Double] barometric pressure (psia)
  def self.Pstd_fZ(z)
    pstd = UnitConversions.convert(((1 - 6.8754e-6 * z)**5.2559), 'atm', 'psi')
    return pstd
  end

  # Calculate the wetbulb temperature at a given drybulb temperature, humidity ratio, and pressure.
  #
  # Source: Based on WETBULB f77 code in ResAC (Brandemuehl)
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param tdb [Double] drybulb temperature (F)
  # @param w [Double] humidity ratio (lbm/lbm)
  # @param p [Double] pressure (psia)
  # @return [Double] wetbulb temperature (F)
  def self.Twb_fT_w_P(runner, tdb, w, p)
    # Initialize
    tboil = self.Tsat_fP(runner, p) # (F)
    twb = [[tdb, tboil - 0.1].min, 0.0].max # (F)

    twb1 = twb # (F)
    twb2 = twb # (F)

    psat_star = self.Psat_fT(twb) # (psia)
    w_star = w_fP(p, psat_star) # (lbm/lbm)
    w_new = ((Liquid.H2O_l.h_fg - (Liquid.H2O_l.cp - Gas.H2O_v.cp) * twb) * w_star - Gas.Air.cp * (tdb - twb)) / (Liquid.H2O_l.h_fg + Gas.H2O_v.cp * tdb - Liquid.H2O_l.cp * twb) # (lbm/lbm)

    error = w - w_new
    error1 = error
    error2 = error

    itmax = 50 # maximum iterations
    cvg = false

    for i in 1..itmax

      psat_star = self.Psat_fT(twb) # (psia)
      w_star = w_fP(p, psat_star) # (lbm/lbm)
      w_new = ((Liquid.H2O_l.h_fg - (Liquid.H2O_l.cp - Gas.H2O_v.cp) * twb) * w_star - Gas.Air.cp * (tdb - twb)) / (Liquid.H2O_l.h_fg + Gas.H2O_v.cp * tdb - Liquid.H2O_l.cp * twb) # (lbm/lbm)

      error = w - w_new

      twb, cvg, twb1, error1, twb2, error2 = MathTools.Iterate(twb, error, twb1, error1, twb2, error2, i, cvg)

      if cvg
        break
      end
    end

    if !cvg && !runner.nil?
      runner.registerWarning('Twb_fT_w_P failed to converge')
    end

    if twb > tdb
      twb = tdb # (F)
    end

    return twb
  end

  # Calculate the humidity ratio at a given pressure and partial pressure.
  #
  # Source: Based on HUMRATIO f77 code in ResAC (Brandemuehl)
  #
  # @param p [Double] pressure (psia)
  # @param pw [Double] partial pressure (psia)
  # @return [Double] humidity ratio (lbm/lbm)
  def self.w_fP(p, pw)
    w = Gas.PsychMassRat * pw / (p - pw)
    return w
  end

  # Calculate the drybulb temperature at a given humidity ratio and enthalpy (SI units).
  #
  # @param w [Double] humidity ratio (kg/kg)
  # @param h [Double] enthalpy (J/kg)
  # @return [Double] drybulb temperature(C)
  def self.T_fw_h_SI(w, h)
    t = (h / 1000 - w * 2501) / (1.006 + w * 1.86)
    return t
  end

  # Calculate the relative humidity at a given drybulb temperature, humidity ratio, and pressure (SI units).
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param tdb [Double] drybulb temperature(C)
  # @param w [Double] humidity ratio (g/g)
  # @param p [Double] pressure (kPa)
  # @return [Double] relative humidity (frac)
  def self.R_fT_w_P_SI(tdb, w, p)
    return self.R_fT_w_P(UnitConversions.convert(tdb, 'C', 'F'), w, UnitConversions.convert(p, 'kPa', 'psi'))
  end

  # Calculate the dewpoint temperature at a given pressure and humidity ratio (SI units).
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param p [Double] pressure (kPa)
  # @param w [Double] humidity ratio (g/g)
  # @return [Double] dewpoint temperature(C)
  def self.Tdp_fP_w_SI(p, w)
    return UnitConversions.convert(self.Tdp_fP_w(UnitConversions.convert(p, 'kPa', 'psi'), w), 'F', 'C')
  end

  # Calculate the humidity ratio at a given drybulb temperature, wetbulb temperature, and pressure (SI units).
  #
  # Source: ASHRAE Handbook 2009
  #
  # @param tdb [Double] drybulb temperature(C)
  # @param twb [Double] wetbulb temperature(C)
  # @param p [Double] pressure (kPa)
  # @return [Double] humidity ratio (g/g)
  def self.w_fT_Twb_P_SI(tdb, twb, p)
    return w_fT_Twb_P(UnitConversions.convert(tdb, 'C', 'F'), UnitConversions.convert(twb, 'C', 'F'), UnitConversions.convert(p, 'kPa', 'psi'))
  end

  # Calculate the humidity ratio at a given drybulb temperature, wetbulb temperature, and pressure.
  #
  # Source: ASHRAE Handbook 2009
  #
  # @param tdb [Double] drybulb temperature (F)
  # @param twb [Double] wetbulb temperature (F)
  # @param p [Double] pressure (psia)
  # @return [Double] humidity ratio (lbm/lbm)
  def self.w_fT_Twb_P(tdb, twb, p)
    w_star = w_fP(p, self.Psat_fT(twb))

    w = ((Liquid.H2O_l.h_fg - (Liquid.H2O_l.cp - Gas.H2O_v.cp) * twb) * w_star - Gas.Air.cp * (tdb - twb)) / (Liquid.H2O_l.h_fg + Gas.H2O_v.cp * tdb - Liquid.H2O_l.cp * twb) # (lbm/lbm)

    return w
  end

  # Calculate the relative humidity at a given drybulb temperature, humidity ratio, and pressure.
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param tdb [Double] drybulb temperature (F)
  # @param w [Double] humidity ratio (lbm/lbm)
  # @param p [Double] pressure (psia)
  # @return [Double] relative humidity (frac)
  def self.R_fT_w_P(tdb, w, p)
    pw = self.Pw_fP_w(p, w)
    r = pw / self.Psat_fT(tdb)
    return r
  end

  # Calculate the partial vapor pressure at a given pressure and humidity ratio.
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param p [Double] pressure (psia)
  # @param w [Double] humidity ratio (lbm/lbm)
  # @return [Double] partial pressure (psia)
  def self.Pw_fP_w(p, w)
    pw = p * w / (Gas.PsychMassRat + w)
    return pw
  end

  # Calculate the dewpoint temperature at a given pressure and humidity ratio.
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param p [Double] pressure (psia)
  # @param w [Double] humidity ratio (lbm/lbm)
  # @return [Double] dewpoint temperature (F)
  def self.Tdp_fP_w(p, w)
    c14 = 100.45
    c15 = 33.193
    c16 = 2.319
    c17 = 0.17074
    c18 = 1.2063

    pw = self.Pw_fP_w(p, w) # (psia)
    alpha = Math.log(pw)
    tdp1 = c14 + c15 * alpha + c16 * alpha**2 + c17 * alpha**3 + c18 * pw**0.1984
    tdp2 = 90.12 + 26.142 * alpha + 0.8927 * alpha**2
    if tdp1 >= Liquid.H2O_l.t_frz
      return tdp1
    else
      return tdp2
    end
  end

  # Calculate the humidity ratio at a given drybulb temperature, relative humidity, and pressure.
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param tdb [Double] drybulb temperature (F)
  # @param r [Double] relative humidity (frac)
  # @param p [Double] pressure (psia)
  # @return [Double] humidity ratio (lbm/lbm)
  def self.w_fT_R_P(tdb, r, p)
    pws = self.Psat_fT(tdb)
    pw = r * pws
    w = 0.62198 * pw / (p - pw)

    return w
  end

  # Calculate the humidity ratio at a given drybulb temperature, relative humidity, and pressure (SI units).
  #
  # Source: 2009 ASHRAE Handbook
  #
  # @param tdb [Double] drybulb temperature(C)
  # @param r [Double] relative humidity (frac)
  # @param p [Double] pressure (kPa)
  # @return [Double] humidity ratio (g/g)
  def self.w_fT_R_P_SI(tdb, r, p)
    pws = UnitConversions.convert(self.Psat_fT(UnitConversions.convert(tdb, 'C', 'F')), 'psi', 'kPa')
    pw = r * pws
    w = 0.62198 * pw / (p - pw)
    return w
  end

  # Calculate the wetbulb temperature at a given drybulb temperature, relative humidity, and pressure.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param tdb [Double] drybulb temperature (F)
  # @param r [Double] relative humidity (frac)
  # @param p [Double] pressure (psia)
  # @return [Double] wetbulb temperature (F)
  def self.Twb_fT_R_P(runner, tdb, r, p)
    w = w_fT_R_P(tdb, r, p)
    twb = self.Twb_fT_w_P(runner, tdb, w, p)
    return twb
  end

  # Calculate the coil Ao factor at the given incoming air state (entering drybulb and wetbulb) and CFM, total capacity, and SHR.
  # The Ao factor is the effective coil surface area as calculated using the relation BF = exp(-NTU) where NTU = Ao/(m*cp).
  #
  # Source: EnergyPlus source code
  #
  # @param dBin [Double] Entering Dry Bulb (F)
  # @param p [Double] Barometric pressure (psi)
  # @param qdot [Double] Total capacity of unit (kBtu/h)
  # @param cfm [Double] Volumetric flow rate of unit (CFM)
  # @param shr [Double] Sensible heat ratio
  # @param win [Double] Entering humidity ratio
  # @return [Double] Coil Ao Factor
  def self.CoilAoFactor(dBin, p, qdot, cfm, shr, win)
    bf = self.CoilBypassFactor(dBin, p, qdot, cfm, shr, win)
    mfr = UnitConversions.convert(self.CalculateMassflowRate(dBin, p, cfm, win), 'lbm/min', 'kg/s')

    ntu = -1.0 * Math.log(bf) # Number of Transfer Units
    ao = ntu * mfr
    return ao
  end

  # Calculate the coil bypass factor at the given incoming air state (entering drybulb and wetbulb) and CFM, total capacity, and SHR.
  # The bypass factor is analogous to the "ineffectiveness" (1-ε) of a heat exchanger.
  #
  # Source: EnergyPlus source code
  #
  # @param dBin [Double] Entering Dry Bulb (F)
  # @param p [Double] Barometric pressure (psi)
  # @param qdot [Double] Total capacity of unit (kBtu/h)
  # @param cfm [Double] Volumetric flow rate of unit (CFM)
  # @param shr [Double] Sensible heat ratio
  # @param win [Double] Entering humidity ratio
  # @return [Double] Coil Bypass Factor
  def self.CoilBypassFactor(dBin, p, qdot, cfm, shr, win)
    mfr = UnitConversions.convert(self.CalculateMassflowRate(dBin, p, cfm, win), 'lbm/min', 'kg/s')

    tin = UnitConversions.convert(dBin, 'F', 'C')
    p = UnitConversions.convert(p, 'psi', 'kPa')

    dH = UnitConversions.convert(qdot, 'kBtu/hr', 'W') / mfr
    hin = h_fT_w_SI(tin, win)
    h_Tin_Wout = hin - (1 - shr) * dH
    wout = w_fT_h_SI(tin, h_Tin_Wout)
    dW = win - wout
    hout = hin - dH
    tout = self.T_fw_h_SI(wout, hout)
    # rH_out = self.R_fT_w_P_SI(tout, wout, p)

    dT = tin - tout
    m_c = dW / dT

    t_ADP = self.Tdp_fP_w_SI(p, wout) # Initial guess for iteration

    if shr == 1
      w_ADP = w_fT_Twb_P_SI(t_ADP, t_ADP, p)
      h_ADP = h_fT_w_SI(t_ADP, w_ADP)
      bF = (hout - h_ADP) / (hin - h_ADP)
      return [bF, 0.01].max
    end

    cnt = 0
    tol = 1.0
    errorLast = 100
    d_T_ADP = 5.0

    while (cnt < 100) && (tol > 0.001)

      if cnt > 0
        t_ADP += d_T_ADP
      end

      w_ADP = w_fT_Twb_P_SI(t_ADP, t_ADP, p)

      m = (win - w_ADP) / (tin - t_ADP)
      error = (m - m_c) / m_c

      if (error > 0) && (errorLast < 0)
        d_T_ADP = -1.0 * d_T_ADP / 2.0
      end

      if (error < 0) && (errorLast > 0)
        d_T_ADP = -1.0 * d_T_ADP / 2.0
      end

      errorLast = error
      tol = error.abs.to_f
      cnt += 1
    end

    h_ADP = h_fT_w_SI(t_ADP, w_ADP)

    bF = (hout - h_ADP) / (hin - h_ADP)
    return [bF, 0.01].max
  end

  # Calculate the coil SHR at the given incoming air state, CFM, total capacity, and coil Ao factor.
  # Uses the apparatus dewpoint (ADP)/bypass factor (BF) approach described in the EnergyPlus
  # Engineering Reference documentation.
  #
  # Source: EnergyPlus source code
  #
  # @param dBin [Double] Entering Dry Bulb (F)
  # @param p [Double] Barometric pressure (psi)
  # @param q [Double] Total capacity of unit (kBtu/h)
  # @param cfm [Double] Volumetric flow rate of unit (CFM)
  # @param ao [Double] Coil Ao factor (=UA/Cp - IN SI UNITS)
  # @param win [Double] Entering humidity ratio (dimensionless)
  # @return [Double] Sensible Heat Ratio
  def self.CalculateSHR(dBin, p, q, cfm, ao, win)
    mfr = UnitConversions.convert(self.CalculateMassflowRate(dBin, p, cfm, win), 'lbm/min', 'kg/s')
    bf = Math.exp(-1.0 * ao / mfr)

    p = UnitConversions.convert(p, 'psi', 'kPa')
    tin = UnitConversions.convert(dBin, 'F', 'C')
    hin = h_fT_w_SI(tin, win)
    dH = UnitConversions.convert(q, 'kBtu/hr', 'W') / mfr
    h_ADP = hin - dH / (1 - bf)

    # T_ADP = self.Tsat_fh_P_SI(H_ADP, P)
    # W_ADP = self.w_fT_h_SI(T_ADP, H_ADP)

    # Initialize
    t_ADP = self.Tdp_fP_w_SI(p, win)
    t_ADP_1 = t_ADP # (C)
    t_ADP_2 = t_ADP # (C)
    w_ADP = w_fT_R_P_SI(t_ADP, 1.0, p)
    error = h_ADP - h_fT_w_SI(t_ADP, w_ADP)
    error1 = error
    error2 = error

    itmax = 50 # maximum iterations
    cvg = false

    for i in 1..itmax
      w_ADP = w_fT_R_P_SI(t_ADP, 1.0, p)
      error = h_ADP - h_fT_w_SI(t_ADP, w_ADP)

      t_ADP, cvg, t_ADP_1, error1, t_ADP_2, error2 = MathTools.Iterate(t_ADP, error, t_ADP_1, error1, t_ADP_2, error2, i, cvg)

      if cvg
        break
      end
    end

    if not cvg
      runnger.registerWarning('CalculateSHR failed to converge')
    end

    h_Tin_Wadp = h_fT_w_SI(tin, w_ADP)

    if (hin - h_ADP != 0)
      shr = [(h_Tin_Wadp - h_ADP) / (hin - h_ADP), 1.0].min
    else
      shr = 1
    end
    return shr
  end

  # Calculate the mass flow rate at the given incoming air state (entering drybulb and wetbulb) and CFM.
  #
  # @param dBin [Double] Entering Dry Bulb (F)
  # @param p [Double] Barometric pressure (psi)
  # @param cfm [Double] Volumetric flow rate of unit (CFM)
  # @param win [Double] Entering humidity ratio
  # @return [Double] mass flow rate (lbm/min)
  def self.CalculateMassflowRate(dBin, p, cfm, win)
    rho_in = rhoD_fT_w_P(dBin, win, p)
    mfr = cfm * rho_in
    return mfr
  end
end
