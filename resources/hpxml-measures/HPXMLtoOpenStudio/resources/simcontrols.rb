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
    zonecap.setHumidityCapacityMultiplier(15) # Per Hugh Henderson ACEEE 2008 Summer Study Paper

    convlim = model.getConvergenceLimits
    convlim.setMinimumSystemTimestep(0) # Speed improvement with minimal effect on results

    run_period = model.getRunPeriod
    run_period.setBeginMonth(hpxml_header.sim_begin_month)
    run_period.setBeginDayOfMonth(hpxml_header.sim_begin_day)
    run_period.setEndMonth(hpxml_header.sim_end_month)
    run_period.setEndDayOfMonth(hpxml_header.sim_end_day)

    ppt = model.getPerformancePrecisionTradeoffs
    ppt.setZoneRadiantExchangeAlgorithm('CarrollMRT') # Speed improvement with minimal effect on results
  end
end
