# frozen_string_literal: true

# Collection of helper methods related to setting simulation controls.
module SimControls
  # Applies various high-level simulation controls/settings to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_header [HPXML::Header] HPXML Header object (one per HPXML file)
  # @return [nil]
  def self.apply(model, hpxml_header)
    sim = model.getSimulationControl
    sim.setRunSimulationforSizingPeriods(false)

    tstep = model.getTimestep
    tstep.setNumberOfTimestepsPerHour(60 / hpxml_header.timestep)

    shad = model.getShadowCalculation
    shad.setMaximumFiguresInShadowOverlapCalculations(200)
    shad.setShadingCalculationUpdateFrequency(20) # EnergyPlus default

    outsurf = model.getOutsideSurfaceConvectionAlgorithm
    outsurf.setAlgorithm('DOE-2') # EnergyPlus default

    insurf = model.getInsideSurfaceConvectionAlgorithm
    insurf.setAlgorithm('TARP') # EnergyPlus default

    zonecap = model.getZoneCapacitanceMultiplierResearchSpecial
    zonecap.setTemperatureCapacityMultiplier(hpxml_header.temperature_capacitance_multiplier)

    # 15 is based on EPA'sIndoor Humidity Assessment Tool (IHAT) Reference Manual and previous
    # studies for simulation of residential buildings by Hugh Henderson
    # See https://docs.nlr.gov/docs/fy11osti/49899.pdf
    zonecap.setHumidityCapacityMultiplier(15)

    # Speed improvements with minimal effect on results
    convlim = model.getConvergenceLimits
    convlim.setMinimumSystemTimestep(0)
    convlim.setMaximumHVACIterations(8)

    run_period = model.getRunPeriod
    run_period.setBeginMonth(hpxml_header.sim_begin_month)
    run_period.setBeginDayOfMonth(hpxml_header.sim_begin_day)
    run_period.setEndMonth(hpxml_header.sim_end_month)
    run_period.setEndDayOfMonth(hpxml_header.sim_end_day)

    # This is now disabled because https://github.com/NatLabRockies/EnergyPlus/pull/11187
    # caused larger changes to our simulation results.
    # ppt = model.getPerformancePrecisionTradeoffs
    # ppt.setZoneRadiantExchangeAlgorithm('CarrollMRT') # Speed improvement with minimal effect on results
  end
end
