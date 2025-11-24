# frozen_string_literal: true

# Collection of methods related to generic OpenStudio Model object operations.
module Model
  # Adds a SimpleGlazing object to the OpenStudio model.
  #
  # The SimpleGlazing object models a window where only SHGC/U-factor are known.
  # It is an alternative to a layer-by-layer model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param ufactor [Double] Overall heat transfer coefficient (W/m^2-K)
  # @param shgc [Double] Solar heat gain coefficient
  # @return [OpenStudio::Model::SimpleGlazing] The model object
  def self.add_simple_glazing(model, name:, ufactor:, shgc:)
    # Material already exists?
    tolerance = 0.0001
    model.getSimpleGlazings.each do |mat|
      next unless mat.name.to_s.start_with? name
      next if (mat.uFactor - ufactor).abs > tolerance
      next if (mat.solarHeatGainCoefficient - shgc).abs > tolerance

      return mat
    end

    mat = OpenStudio::Model::SimpleGlazing.new(model)
    mat.setName(name)
    mat.setUFactor(ufactor)
    mat.setSolarHeatGainCoefficient(shgc)
    return mat
  end

  # Adds a StandardOpaqueMaterial object to the OpenStudio model.
  #
  # The StandardOpaqueMaterial object models a construction material when
  # the four main thermal properties (thickness, conductivity, density, and
  # specific heat) are known.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param thickness [Double] Thickness (m)
  # @param conductivity [Double] Thermal conductivity (W/m-K)
  # @param density [Double] Density (kg/m^3)
  # @param specific_heat [Double] Specific heat (J/kg-K)
  # @param thermal_abs [Double] Thermal absorptance (emittance)
  # @param solar_abs [Double] Solar absorptance
  # @param roughness [String] Roughness for convection (Rough, Smooth, etc.)
  # @return [OpenStudio::Model::StandardOpaqueMaterial] The model object
  def self.add_opaque_material(model, name:, thickness:, conductivity:, density:, specific_heat:, thermal_abs: nil, solar_abs: nil, roughness: 'Rough')
    # Material already exists?
    tolerance = 0.0001
    model.getStandardOpaqueMaterials.each do |mat|
      next unless mat.name.to_s.start_with? name
      next if mat.roughness.downcase.to_s != roughness.downcase
      next if (mat.thickness - thickness).abs > tolerance
      next if (mat.conductivity - conductivity).abs > tolerance
      next if (mat.density - density).abs > tolerance
      next if (mat.specificHeat - specific_heat).abs > tolerance
      next if (mat.thermalAbsorptance - thermal_abs.to_f).abs > tolerance
      next if (mat.solarAbsorptance - solar_abs.to_f).abs > tolerance

      return mat
    end

    # New material
    mat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    mat.setName(name)
    mat.setRoughness(roughness)
    mat.setThickness(thickness)
    mat.setConductivity(conductivity)
    mat.setDensity(density)
    mat.setSpecificHeat(specific_heat)
    if not thermal_abs.nil?
      mat.setThermalAbsorptance(thermal_abs)
    end
    if not solar_abs.nil?
      mat.setSolarAbsorptance(solar_abs)
      mat.setVisibleAbsorptance(solar_abs)
    end
    return mat
  end

  # Adds a MasslessOpaqueMaterial object to the OpenStudio model.
  #
  # The MasslessOpaqueMaterial object models a construction material when
  # only the R-value is known.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param rvalue [Double] Thermal resistance (m^2-K/W)
  # @param thermal_abs [Double] Thermal absorptance (emittance)
  # @param solar_abs [Double] Solar absorptance
  # @param roughness [String] Roughness for convection (Rough, Smooth, etc.)
  # @return [OpenStudio::Model::MasslessOpaqueMaterial] The model object
  def self.add_massless_material(model, name:, rvalue:, thermal_abs: nil, solar_abs: nil, roughness: 'Rough')
    # Material already exists?
    tolerance = 0.0001
    model.getStandardOpaqueMaterials.each do |mat|
      next unless mat.name.to_s.start_with? name
      next if mat.roughness.downcase.to_s != roughness.downcase
      next if (mat.thermalResistance - rvalue).abs > tolerance
      next if (mat.thermalAbsorptance - thermal_abs.to_f).abs > tolerance
      next if (mat.solarAbsorptance - solar_abs.to_f).abs > tolerance

      return mat
    end

    # New material
    mat = OpenStudio::Model::MasslessOpaqueMaterial.new(model, roughness, rvalue)
    mat.setName(name)
    if not thermal_abs.nil?
      mat.setThermalAbsorptance(thermal_abs)
    end
    if not solar_abs.nil?
      mat.setSolarAbsorptance(solar_abs)
      mat.setVisibleAbsorptance(solar_abs)
    end
    return mat
  end

  # Adds a Construction object to the OpenStudio model.
  #
  # The Construction object is a set of materials, listed from outside to inside,
  # that applies to surfaces or subsurfaces (walls, roofs, windows, doors, etc.).
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param layers [Array<OpenStudio::Model::Material>] Set of material layers
  # @return [OpenStudio::Model::Construction] The model object
  def self.add_construction(model, name:, layers:)
    constr = OpenStudio::Model::Construction.new(model)
    constr.setName(name)
    constr.setLayers(layers)
    return constr
  end

  # Adds a WaterUseEquipment object to the OpenStudio model.
  #
  # The WaterUseEquipment object is a generalized object for simulating all (hot and cold)
  # water end uses.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param end_use [String] Name of the end use subcategory for output processing
  # @param peak_flow_rate [Double] Water peak flow rate (m^3/s)
  # @param flow_rate_schedule [OpenStudio::Model::Schedule] Schedule fraction that applies to the peak flow rate
  # @param water_use_connections [OpenStudio::Model::WaterUseConnections] Grouping of water use equipment objects
  # @param target_temperature_schedule [OpenStudio::Model::Schedule] The target water temperature schedule (F)
  # @return [OpenStudio::Model::WaterUseEquipment] The model object
  def self.add_water_use_equipment(model, name:, end_use:, peak_flow_rate:, flow_rate_schedule:, water_use_connections:, target_temperature_schedule:)
    wu_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
    wu = OpenStudio::Model::WaterUseEquipment.new(wu_def)
    wu.setName(name)
    wu_def.setName(name)
    wu_def.setPeakFlowRate(peak_flow_rate)
    wu_def.setEndUseSubcategory(end_use) unless end_use.nil?
    wu.setFlowRateFractionSchedule(flow_rate_schedule)
    wu_def.setTargetTemperatureSchedule(target_temperature_schedule) unless target_temperature_schedule.nil?
    water_use_connections.addWaterUseEquipment(wu)
    return wu
  end

  # Adds an ElectricEquipment object to the OpenStudio model.
  #
  # The ElectricEquipment object models equipment in a zone that consumes electricity (e.g.,
  # TVs, cooking, etc.). All the energy becomes a heat gain to the zone or is lost (exhausted).
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param end_use [String] Name of the end use subcategory for output processing
  # @param space [OpenStudio::Model::Space] The space the object is added to
  # @param design_level [Double] Maximum electrical power (W)
  # @param frac_radiant [Double] Fraction of energy consumption that is long-wave radiant heat to the zone
  # @param frac_latent [Double] Fraction of energy consumption that is latent heat to the zone
  # @param frac_lost [Double] Fraction of energy consumption that is not heat to the zone (for example, vented to the atmosphere)
  # @param schedule [OpenStudio::Model::Schedule] Schedule fraction (or multiplier) that applies to the design level
  # @return [OpenStudio::Model::ElectricEquipment] The model object
  def self.add_electric_equipment(model, name:, end_use:, space:, design_level:, frac_radiant:, frac_latent:, frac_lost:, schedule:)
    ee_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    ee = OpenStudio::Model::ElectricEquipment.new(ee_def)
    ee.setName(name)
    ee.setEndUseSubcategory(end_use) unless end_use.nil?
    ee.setSpace(space)
    ee_def.setName(name)
    ee_def.setDesignLevel(design_level) unless design_level.nil? # EMS-actuated if nil
    ee_def.setFractionRadiant(frac_radiant)
    ee_def.setFractionLatent(frac_latent)
    ee_def.setFractionLost(frac_lost)
    ee.setSchedule(schedule)
    return ee
  end

  # Adds an OtherEquipment object to the OpenStudio model.
  #
  # The OtherEquipment object models a heat gain/loss directly to the zone. Fuel consumption may
  # or may not be associated with the heat.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param end_use [String] Name of the end use subcategory for output processing
  # @param space [OpenStudio::Model::Space] The space the object is added to
  # @param design_level [Double] Maximum energy input (W)
  # @param frac_radiant [Double] Fraction of energy consumption that is long-wave radiant heat to the zone
  # @param frac_latent [Double] Fraction of energy consumption that is latent heat to the zone
  # @param frac_lost [Double] Fraction of energy consumption that is not heat to the zone (for example, vented to the atmosphere)
  # @param schedule [OpenStudio::Model::Schedule] Schedule fraction (or multiplier) that applies to the design level
  # @param fuel_type [String] Fuel type if the equipment consumes fuel (HPXML::FuelTypeXXX)
  # @return [OpenStudio::Model::OtherEquipment] The model object
  def self.add_other_equipment(model, name:, end_use:, space:, design_level:, frac_radiant:, frac_latent:, frac_lost:, schedule:, fuel_type:)
    oe_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
    oe = OpenStudio::Model::OtherEquipment.new(oe_def)
    oe.setName(name)
    oe.setEndUseSubcategory(end_use) unless end_use.nil?
    oe.setFuelType(EPlus.fuel_type(fuel_type)) unless fuel_type.nil?
    oe.setSpace(space)
    oe_def.setName(name)
    oe_def.setDesignLevel(design_level) unless design_level.nil? # EMS-actuated if nil
    oe_def.setFractionRadiant(frac_radiant)
    oe_def.setFractionLatent(frac_latent)
    oe_def.setFractionLost(frac_lost)
    oe.setSchedule(schedule)
    return oe
  end

  # Adds a Lights or ExteriorLights object to the OpenStudio model.
  #
  # The Lights/ExteriorLights objects model electric lighting in a zone or outside.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param end_use [String] Name of the end use subcategory for output processing
  # @param space [OpenStudio::Model::Space] The space the object is added to, or nil if exterior lighting
  # @param design_level [Double] Maximum electrical power input (W)
  # @param schedule [OpenStudio::Model::Schedule] Schedule fraction (or multiplier) that applies to the design level
  # @return [OpenStudio::Model::Lights or OpenStudio::Model::ExteriorLights] The model object
  def self.add_lights(model, name:, end_use:, space:, design_level:, schedule:)
    if space.nil?
      ltg_def = OpenStudio::Model::ExteriorLightsDefinition.new(model)
      ltg = OpenStudio::Model::ExteriorLights.new(ltg_def)
      ltg_def.setDesignLevel(design_level)
    else
      ltg_def = OpenStudio::Model::LightsDefinition.new(model)
      ltg = OpenStudio::Model::Lights.new(ltg_def)
      ltg.setSpace(space)
      ltg_def.setLightingLevel(design_level)
      ltg_def.setFractionRadiant(0.6)
      ltg_def.setFractionVisible(0.2)
      ltg_def.setReturnAirFraction(0.0)
    end
    ltg.setName(name)
    ltg.setEndUseSubcategory(end_use)
    ltg.setSchedule(schedule)
    ltg_def.setName(name)
    return ltg
  end

  # Adds a SpaceInfiltrationDesignFlowRate object to the OpenStudio model.
  #
  # Infiltration = FlowRate * [A + B*ABS(Tzone−Todb) +C*WindSpeed +D*Windspeed^2]
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param space [OpenStudio::Model::Space] The space to add infiltration
  # @param ach [Double] Air changes per hour
  # @param const_coeff [Double] Coeff A in the equation above
  # @param temp_coeff [Double] Coeff B in the equation above
  # @param wind_coeff [Double] Coeff C in the equation above
  # @param wind2_coeff [Double] Coeff D in the equation above
  # @return [OpenStudio::Model::SpaceInfiltrationDesignFlowRate] The model object
  def self.add_infiltration_flow_rate(model, name:, space:, ach:, const_coeff: 1, temp_coeff: 0, wind_coeff: 0, wind2_coeff: 0)
    infil = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
    infil.setName(name)
    infil.setSpace(space)
    infil.setSchedule(model.alwaysOnDiscreteSchedule)
    infil.setAirChangesperHour(ach) unless ach.nil? # EMS-actuated if nil
    infil.setConstantTermCoefficient(const_coeff) unless ach.nil?
    infil.setTemperatureTermCoefficient(temp_coeff) unless ach.nil?
    infil.setVelocityTermCoefficient(wind_coeff) unless ach.nil?
    infil.setVelocitySquaredTermCoefficient(wind2_coeff) unless ach.nil?
    return infil
  end

  # Adds a SpaceInfiltrationEffectiveLeakageArea object to the OpenStudio model.
  #
  # The SpaceInfiltrationEffectiveLeakageArea object uses the ASHRAE Basic
  # (Sherman Grimsrud) model.
  #
  # Infiltration = ELA/1000 * (C_s*ABS(Tzone−Todb) + C_w*Windspeed^2)^0.5
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param space [OpenStudio::Model::Space] The space to add infiltration
  # @param ela [Double] Effective leakage area at 4 Pa (cm^2)
  # @param stack_coeff [Double] Coeff C_S in the equation above
  # @param wind_coeff [Double] Coeff C_w in the equation above
  # @return [OpenStudio::Model::SpaceInfiltrationEffectiveLeakageArea] The model object
  def self.add_infiltration_ela(model, name:, space:, ela:, stack_coeff:, wind_coeff:)
    infil = OpenStudio::Model::SpaceInfiltrationEffectiveLeakageArea.new(model)
    infil.setName(name)
    infil.setSpace(space)
    infil.setSchedule(model.alwaysOnDiscreteSchedule)
    infil.setEffectiveAirLeakageArea(ela) unless ela.nil? # EMS-actuated if nil
    infil.setStackCoefficient(stack_coeff)
    infil.setWindCoefficient(wind_coeff)
    return infil
  end

  # Adds a CoilHeatingElectric or CoilHeatingGas object to the OpenStudio
  # model, depending on the fuel type.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param efficiency [Double] Equipment efficiency
  # @param capacity [Double] Heating capacity (W)
  # @param fuel_type [String] Fuel type (HPXML::FuelTypeXXX)
  # @param off_cycle_gas_load [Double] Off-cycle parasitic gas load (W)
  # @return [OpenStudio::Model::CoilHeatingElectric or OpenStudio::Model::CoilHeatingGas] The model object
  def self.add_coil_heating(model, name:, efficiency:, capacity:, fuel_type:, off_cycle_gas_load: 0)
    if fuel_type == HPXML::FuelTypeElectricity
      coil = OpenStudio::Model::CoilHeatingElectric.new(model)
      coil.setEfficiency(efficiency)
    else
      coil = OpenStudio::Model::CoilHeatingGas.new(model)
      coil.setFuelType(EPlus.fuel_type(fuel_type))
      coil.setGasBurnerEfficiency(efficiency)
      coil.setOnCycleParasiticElectricLoad(0)
      coil.setOffCycleParasiticGasLoad(off_cycle_gas_load)
    end
    coil.setName(name)
    coil.setNominalCapacity(capacity)
    return coil
  end

  # Adds a FanSystemModel object to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param end_use [String] Name of the end use subcategory for output processing
  # @param power_per_flow [Double] Electric power per flow rate (W/(m^3/s))
  # @param max_flow_rate [Double] Design volume flow rate (m^3/s)
  # @return [OpenStudio::Model::FanSystemModel] The model object
  def self.add_fan_system_model(model, name:, end_use:, power_per_flow:, max_flow_rate:)
    fan = OpenStudio::Model::FanSystemModel.new(model)
    fan.setName(name)
    fan.setEndUseSubcategory(end_use)
    fan.setSpeedControlMethod('Discrete')
    fan.setDesignPowerSizingMethod('PowerPerFlow')
    fan.setElectricPowerPerUnitFlowRate([power_per_flow, 0.000001].max)
    fan.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirStreamFraction(1.0)
    fan.setDesignMaximumAirFlowRate(max_flow_rate)
    return fan
  end

  # Adds a PlantLoop object to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param fluid_type [String] Fluid type (Eplus::FluidXXX)
  # @param glycol_concentration [Integer] Percent glycol concentration, only used if fluid is propylene glycol
  # @param volume [Double] Volume of the entire loop, both demand and supply side (m^3)
  # @param min_temp [Double] Minimum loop temperature (C)
  # @param max_temp [Double] Maximum loop temperature (C)
  # @param max_flow_rate [Double] Maximum loop flow rate (m^3/s)
  # @return [OpenStudio::Model::PlantLoop] The model object
  def self.add_plant_loop(model, name:, fluid_type: EPlus::FluidWater, glycol_concentration: 50, volume: nil, min_temp: nil, max_temp: nil, max_flow_rate: nil)
    plant_loop = OpenStudio::Model::PlantLoop.new(model)
    plant_loop.setName(name)
    plant_loop.setFluidType(fluid_type)
    if fluid_type == EPlus::FluidPropyleneGlycol
      plant_loop.setGlycolConcentration(glycol_concentration)
    end
    plant_loop.setMinimumLoopTemperature(min_temp) unless min_temp.nil?
    plant_loop.setMaximumLoopTemperature(max_temp) unless max_temp.nil?
    plant_loop.setMaximumLoopFlowRate(max_flow_rate) unless max_flow_rate.nil?
    if not volume.nil?
      plant_loop.setPlantLoopVolume(volume)
    else
      plant_loop.autocalculatePlantLoopVolume()
    end
    return plant_loop
  end

  # Adds a PumpVariableSpeed object to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param rated_power [Double] Design power consumption (W)
  # @param control_type [String] Pump control type (EPlus::PumpControlTypeXXX)
  # @return [OpenStudio::Model::PumpVariableSpeed] The model object
  def self.add_pump_variable_speed(model, name:, rated_power:, control_type: EPlus::PumpControlTypeIntermittent)
    pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    pump.setName(name)
    pump.setMotorEfficiency(0.85)
    pump.setRatedPowerConsumption(rated_power)
    pump_eff = 0.75 # Overall efficiency of the pump
    if rated_power > 0
      pump.setRatedPumpHead(20000)
      flow_rate = pump_eff * rated_power / pump.ratedPumpHead
      pump.setRatedFlowRate([flow_rate, 0.00001].max)
    else
      pump.setRatedPumpHead(1)
      pump.setRatedFlowRate(0.01)
    end
    pump.setFractionofMotorInefficienciestoFluidStream(0)
    pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
    pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient4ofthePartLoadPerformanceCurve(0)
    pump.setMinimumFlowRate(0)
    pump.setPumpControlType(control_type)
    return pump
  end

  # Adds a PipeAdiabatic object to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [OpenStudio::Model::PipeAdiabatic] The model object
  def self.add_pipe_adiabatic(model)
    return OpenStudio::Model::PipeAdiabatic.new(model)
  end

  # Adds a CurveQuadratic object to the OpenStudio model.
  #
  # y = C1 + C2*x + C3*x^2
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param coeff [Array<Double>] Coefficients for the above equation
  # @param min_x [Double] Minimum allowable value for x
  # @param max_x [Double] Maximum allowable value for x
  # @param min_y [Double] Minimum allowable value for y
  # @param max_y [Double] Maximum allowable value for y
  # @return [OpenStudio::Model::CurveQuadratic] The model object
  def self.add_curve_quadratic(model, name:, coeff:, min_x: nil, max_x: nil, min_y: nil, max_y: nil)
    curve = OpenStudio::Model::CurveQuadratic.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2x(coeff[1])
    curve.setCoefficient3xPOW2(coeff[2])
    curve.setMinimumValueofx(min_x) unless min_x.nil?
    curve.setMaximumValueofx(max_x) unless max_x.nil?
    curve.setMinimumCurveOutput(min_y) unless min_y.nil?
    curve.setMaximumCurveOutput(max_y) unless max_y.nil?
    return curve
  end

  # Adds a CurveBiquadratic object to the OpenStudio model.
  #
  # z = C1 + C2*x + C3*x^2 + C4*y + C5*y^2 + C6*x*y
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param coeff [Array<Double>] Coefficients for the above equation
  # @param min_x [Double] Minimum allowable value for x
  # @param max_x [Double] Maximum allowable value for x
  # @param min_y [Double] Minimum allowable value for y
  # @param max_y [Double] Maximum allowable value for y
  # @return [OpenStudio::Model::CurveBiquadratic] The model object
  def self.add_curve_biquadratic(model, name:, coeff:, min_x: nil, max_x: nil, min_y: nil, max_y: nil)
    curve = OpenStudio::Model::CurveBiquadratic.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2x(coeff[1])
    curve.setCoefficient3xPOW2(coeff[2])
    curve.setCoefficient4y(coeff[3])
    curve.setCoefficient5yPOW2(coeff[4])
    curve.setCoefficient6xTIMESY(coeff[5])
    curve.setMinimumValueofx(min_x) unless min_x.nil?
    curve.setMaximumValueofx(max_x) unless max_x.nil?
    curve.setMinimumValueofy(min_y) unless min_y.nil?
    curve.setMaximumValueofy(max_y) unless max_y.nil?
    return curve
  end

  # Adds a CurveCubic object to the OpenStudio model.
  #
  # y = C1 + C2*x + C3*x^2 + C4*x^3
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param coeff [Array<Double>] Coefficients for the above equation
  # @param min_x [Double] Minimum allowable value for x
  # @param max_x [Double] Maximum allowable value for x
  # @param min_y [Double] Minimum allowable value for y
  # @param max_y [Double] Maximum allowable value for y
  # @return [OpenStudio::Model::CurveCubic] The model object
  def self.add_curve_cubic(model, name:, coeff:, min_x: nil, max_x: nil, min_y: nil, max_y: nil)
    curve = OpenStudio::Model::CurveCubic.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2x(coeff[1])
    curve.setCoefficient3xPOW2(coeff[2])
    curve.setCoefficient4xPOW3(coeff[3])
    curve.setMinimumValueofx(min_x) unless min_x.nil?
    curve.setMaximumValueofx(max_x) unless max_x.nil?
    curve.setMinimumCurveOutput(min_y) unless min_y.nil?
    curve.setMaximumCurveOutput(max_y) unless max_y.nil?
    return curve
  end

  # Adds a CurveBicubic object to the OpenStudio model.
  #
  # z = C1 + C2*x + C3*x^2 + C4*y+ C5*y^2 + C6*x*y + C7*x3 + C8*y^3 + C9*x^2*y + C10*x*y^2
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param coeff [Array<Double>] Coefficients for the above equation
  # @param min_x [Double] Minimum allowable value for x
  # @param max_x [Double] Maximum allowable value for x
  # @param min_y [Double] Minimum allowable value for y
  # @param max_y [Double] Maximum allowable value for y
  # @return [OpenStudio::Model::CurveBicubic] The model object
  def self.add_curve_bicubic(model, name:, coeff:, min_x: nil, max_x: nil, min_y: nil, max_y: nil)
    curve = OpenStudio::Model::CurveBicubic.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2x(coeff[1])
    curve.setCoefficient3xPOW2(coeff[2])
    curve.setCoefficient4y(coeff[3])
    curve.setCoefficient5yPOW2(coeff[4])
    curve.setCoefficient6xTIMESY(coeff[5])
    curve.setCoefficient7xPOW3(coeff[6])
    curve.setCoefficient8yPOW3(coeff[7])
    curve.setCoefficient9xPOW2TIMESY(coeff[8])
    curve.setCoefficient10xTIMESYPOW2(coeff[9])
    curve.setMinimumValueofx(min_x) unless min_x.nil?
    curve.setMaximumValueofx(max_x) unless max_x.nil?
    curve.setMinimumValueofy(min_y) unless min_y.nil?
    curve.setMaximumValueofy(max_y) unless max_y.nil?
    return curve
  end

  # Adds a CurveQuadLinear object to the OpenStudio model.
  #
  # y = C1 + C2*w + C3*x + C4*y + C5*z
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param coeff [Array<Double>] Coefficients for the above equation
  # @return [OpenStudio::Model::CurveQuadLinear] The model object
  def self.add_curve_quad_linear(model, name:, coeff:)
    curve = OpenStudio::Model::CurveQuadLinear.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2w(coeff[1])
    curve.setCoefficient3x(coeff[2])
    curve.setCoefficient4y(coeff[3])
    curve.setCoefficient5z(coeff[4])
    return curve
  end

  # Adds a CurveQuintLinear object to the OpenStudio model.
  #
  # y = C1 + C2*v + C3*w + C4*x + C5*y + C6*z
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param coeff [Array<Double>] Coefficients for the above equation
  # @return [OpenStudio::Model::CurveQuintLinear] The model object
  def self.add_curve_quint_linear(model, name:, coeff:)
    curve = OpenStudio::Model::CurveQuintLinear.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2v(coeff[1])
    curve.setCoefficient3w(coeff[2])
    curve.setCoefficient4x(coeff[3])
    curve.setCoefficient5y(coeff[4])
    curve.setCoefficient6z(coeff[5])
    return curve
  end

  # Adds a TableIndependentVariable object to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param min [Double] Minimum allowable value
  # @param max [Double] Maximum allowable value
  # @param values [Array<Double>] List of values
  # @param extrap_method [String] Extrapolation method for values beyond the bounds of the independent variables
  # @return [OpenStudio::Model::TableIndependentVariable] The model object
  def self.add_table_independent_variable(model, name:, min:, max:, values:, extrap_method: 'Constant')
    ind_var = OpenStudio::Model::TableIndependentVariable.new(model)
    ind_var.setName(name)
    ind_var.setMinimumValue(min)
    ind_var.setMaximumValue(max)
    ind_var.setValues(values)
    ind_var.setExtrapolationMethod(extrap_method)
    return ind_var
  end

  # Adds a TableLookup object to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param ind_vars [Array<OpenStudio::Model::TableIndependentVariable>] List of independent variables
  # @param output_values [Array<Double>] List of output values
  # @param output_min [Double] The minimum allowable value of the evaluated table after interpolation and extrapolation
  # @param output_max [Double] The maximum allowable value of the evaluated table after interpolation and extrapolation
  # @return [OpenStudio::Model::TableLookup] The model object
  def self.add_table_lookup(model, name:, ind_vars:, output_values:, output_min: nil, output_max: nil)
    if (not output_min.nil?) && (output_values.min < output_min)
      fail "Minimum table lookup output value (#{output_values.min}) is less than #{output_min} for #{name}."
    end
    if (not output_max.nil?) && (output_values.max > output_max)
      fail "Maximum table lookup output value (#{output_values.max}) is greater than #{output_max} for #{name}."
    end

    table = OpenStudio::Model::TableLookup.new(model)
    table.setName(name)
    ind_vars.each do |ind_var|
      table.addIndependentVariable(ind_var)
    end
    table.setMinimumOutput(output_min) unless output_min.nil?
    table.setMaximumOutput(output_max) unless output_max.nil?
    table.setOutputValues(output_values)
    return table
  end

  # Adds a ScheduleConstant object to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param value [Double] Constant value for the year
  # @param limits [String] Data type for the values contained in the schedule (EPlus::ScheduleTypeXXX)
  # @return [OpenStudio::Model::ScheduleConstant] The model object
  def self.add_schedule_constant(model, name:, value:, limits: nil)
    sch = OpenStudio::Model::ScheduleConstant.new(model)
    sch.setName(name)
    sch.setValue(value) unless value.nil? # EMS-actuated if nil
    add_schedule_type_limits(model, schedule: sch, limits: limits)
    return sch
  end

  # Adds a ScheduleRuleset object to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param limits [String] Data type for the values contained in the schedule (EPlus::ScheduleTypeXXX)
  # @return [OpenStudio::Model::ScheduleRuleset] The model object
  def self.add_schedule_ruleset(model, name:, limits: nil)
    sch = OpenStudio::Model::ScheduleRuleset.new(model)
    sch.setName(name)
    sch.defaultDaySchedule.setName("#{name} default day")
    add_schedule_type_limits(model, schedule: sch, limits: limits)
    return sch
  end

  # Adds a ScheduleRule object to the OpenStudio model for a given ruleset.
  #
  # @param schedule [OpenStudio::Model::ScheduleRuleset] The ruleset to which the rule applies
  # @param start_date [OpenStudio::Date] Start date
  # @param end_date [OpenStudio::Date] End data
  # @param apply_to_days [Array<Integer>] Values for Sun, Mon, ..., Sat, where 1 means the rule applies
  # @param hourly_values [Array<Double>] 24 hourly values
  # @return [OpenStudio::Model::ScheduleRule] The model object
  def self.add_schedule_ruleset_rule(schedule, start_date:, end_date:, apply_to_days: [1, 1, 1, 1, 1, 1, 1], hourly_values:)
    rule = OpenStudio::Model::ScheduleRule.new(schedule)

    if (not apply_to_days.is_a? Array) || (apply_to_days.size != 7)
      fail 'Unexpected apply_to_days.'
    end

    # Allow for either 0-based or 1-based array for now
    # FUTURE: Restrict to 0-based
    if (not hourly_values.is_a? Array) || (hourly_values.size != 24 && hourly_values.size != 25)
      fail 'Unexpected hourly_values.'
    end

    if hourly_values.size == 24
      hourly_values = [nil] + hourly_values
    end

    if apply_to_days == [1, 1, 1, 1, 1, 1, 1]
      rule.setName("#{schedule.name} allday rule")
    elsif apply_to_days == [0, 1, 1, 1, 1, 1, 0]
      rule.setName("#{schedule.name} weekday rule")
    elsif apply_to_days == [1, 0, 0, 0, 0, 0, 1]
      rule.setName("#{schedule.name} weekend rule")
    else
      rule.setName("#{schedule.name} rule")
    end
    rule.setStartDate(start_date)
    rule.setEndDate(end_date)
    rule.setApplySunday(apply_to_days[0])
    rule.setApplyMonday(apply_to_days[1])
    rule.setApplyTuesday(apply_to_days[2])
    rule.setApplyWednesday(apply_to_days[3])
    rule.setApplyThursday(apply_to_days[4])
    rule.setApplyFriday(apply_to_days[5])
    rule.setApplySaturday(apply_to_days[6])

    day_sch = rule.daySchedule
    day_sch.setName("#{schedule.name} day")

    previous_value = hourly_values[1]
    for h in 1..24
      next if (h != 24) && (hourly_values[h + 1] == previous_value)

      day_sch.addValue(OpenStudio::Time.new(0, h, 0, 0), previous_value)
      previous_value = hourly_values[h + 1]
    end

    return rule
  end

  # Adds a ScheduleFile object to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param file_path [String] Full path to the CSV schedule file
  # @param col_num [Integer] The column number with the desired schedule values; first column is 1
  # @param rows_to_skip [Integer] The number of header rows to skip
  # @param num_hours [Integer] Number of hours of data, should be 8760 of 8784
  # @param mins_per_item [Integer] Number of minutes associated with each line of the file
  # @param limits [String] Data type for the values contained in the schedule (EPlus::ScheduleTypeXXX)
  # @return [OpenStudio::Model::ScheduleFile] The model object
  def self.add_schedule_file(model, name:, file_path:, col_num:, rows_to_skip:, num_hours:, mins_per_item:, limits: nil)
    file_dir = File.dirname(file_path)
    if not model.workflowJSON.filePaths.map(&:to_s).include?(file_dir)
      model.workflowJSON.addFilePath(file_dir)
    end

    sch = OpenStudio::Model::ScheduleFile.new(model, File.basename(file_path))
    sch.setName(name)
    sch.setColumnNumber(col_num)
    sch.setRowstoSkipatTop(rows_to_skip)
    sch.setNumberofHoursofData(num_hours)
    sch.setMinutesperItem(mins_per_item)
    sch.setTranslateFileWithRelativePath(true)
    sch.setInterpolatetoTimestep(true)
    add_schedule_type_limits(model, schedule: sch, limits: limits)
    return sch
  end

  # Adds a OpenStudio::Model::ScheduleTypeLimits object to the OpenStuio model (unless
  # one has already been added) and assigns the schedule to it.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param schedule [OpenStudio::Model::Schedule] The schedule of interest
  # @param limits [String] Data type for the values contained in the schedule (EPlus::ScheduleTypeXXX)
  # @return [OpenStudio::Model::ScheduleTypeLimits] The model object
  def self.add_schedule_type_limits(model, schedule:, limits:)
    return if limits.nil?

    stl = model.getScheduleTypeLimitss.find { |stl| stl.name.to_s == limits }

    if stl.nil?
      stl = OpenStudio::Model::ScheduleTypeLimits.new(model)
      stl.setName(limits)
      if limits == EPlus::ScheduleTypeLimitsFraction
        stl.setLowerLimitValue(0)
        stl.setUpperLimitValue(1)
        stl.setNumericType('Continuous')
      elsif limits == EPlus::ScheduleTypeLimitsOnOff
        stl.setLowerLimitValue(0)
        stl.setUpperLimitValue(1)
        stl.setNumericType('Discrete')
      elsif limits == EPlus::ScheduleTypeLimitsTemperature
        stl.setUnitType('Temperature')
      else
        fail "Unexpected schedule type limits: #{limits}"
      end
    end

    schedule.setScheduleTypeLimits(stl)

    return stl
  end

  # Adds an EnergyManagementSystemSensor object to the OpenStudio model.
  #
  # The EnergyManagementSystemSensor object gets information during the simulation
  # that can be used in custom calculations.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param output_var_or_meter_name [String] EnergyPlus Output:Variable or Output:Meter name
  # @param key_name [OpenStudio::Model::XXX] Model object name or 'Environment' or nil
  # @return [OpenStudio::Model::EnergyManagementSystemSensor] The model object
  def self.add_ems_sensor(model, name:, output_var_or_meter_name:, key_name:)
    sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_var_or_meter_name)
    sensor.setName(ems_friendly_name(name))
    sensor.setKeyName(key_name.to_s) unless key_name.nil?
    return sensor
  end

  # Adds an EnergyManagementSystemGlobalVariable object to the OpenStudio model.
  #
  # The EnergyManagementSystemGlobalVariable object allows an EMS variable to be
  # global such that it can be used across EMS programs/subroutines.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param var_name [String] Name of the EMS variable
  # @return [OpenStudio::Model::EnergyManagementSystemGlobalVariable] The model object
  def self.add_ems_global_var(model, var_name:)
    return OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, ems_friendly_name(var_name))
  end

  # Adds an EnergyManagementSystemTrendVariable object to the OpenStudio model.
  #
  # The EnergyManagementSystemTrendVariable object creates a global EMS variable
  # that stores the recent history of an EMS variable for use in a calculation.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param ems_object [OpenStudio::Model::EnergyManagementSystemXXX] The EMS object to track
  # @param num_timesteps_logged [Integer] How much data to be held in the trend variable
  # @return [OpenStudio::Model::EnergyManagementSystemTrendVariable] The model object
  def self.add_ems_trend_var(model, ems_object:, num_timesteps_logged:)
    tvar = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model, ems_object)
    tvar.setName(ems_friendly_name("#{ems_object.name} trend var"))
    tvar.setNumberOfTimestepsToBeLogged(num_timesteps_logged)
    return tvar
  end

  # Adds an EnergyManagementSystemInternalVariable object to the OpenStudio model.
  #
  # The EnergyManagementSystemInternalVariable object is used to obtain static data from
  # elsewhere in the model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param model_object [OpenStudio::Model::XXX] The OpenStudio model object to get data from
  # @param type [String] Data type of interest
  # @return [OpenStudio::Model::EnergyManagementSystemInternalVariable] The model object
  def self.add_ems_internal_var(model, name:, model_object:, type:)
    ivar = OpenStudio::Model::EnergyManagementSystemInternalVariable.new(model, type)
    ivar.setName(ems_friendly_name(name))
    ivar.setInternalDataIndexKeyName(model_object.name.to_s)
    return ivar
  end

  # Adds an EnergyManagementSystemActuator object to the OpenStudio model.
  #
  # The EnergyManagementSystemActuator object specifies the properties or controls
  # of an EnergyPlus object that is to be overridden during the simulation.
  #
  # @param name [String] Name for the OpenStudio object
  # @param model_object [OpenStudio::Model::XXX] The OpenStudio model object to actuate
  # @param comp_type_and_control [Array<String, String>] The type of component and its control type
  # @return [OpenStudio::Model::EnergyManagementSystemActuator] The model object
  def self.add_ems_actuator(name:, model_object:, comp_type_and_control:)
    if model_object.to_SpaceLoadInstance.is_initialized
      act = OpenStudio::Model::EnergyManagementSystemActuator.new(model_object, *comp_type_and_control, model_object.space.get)
    else
      act = OpenStudio::Model::EnergyManagementSystemActuator.new(model_object, *comp_type_and_control)
    end
    act.setName(ems_friendly_name(name))
    return act
  end

  # Adds an EnergyManagementSystemProgram object to the OpenStudio model.
  #
  # The EnergyManagementSystemProgram object allows custom calculations to be
  # performed within the EnergyPlus simulation in order to override the properties
  # or controls of an EnergyPlus object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param lines [Array<String>] The program lines to be executed
  # @return [OpenStudio::Model::EnergyManagementSystemProgram] The model object
  def self.add_ems_program(model, name:, lines: nil)
    prg = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    prg.setName(ems_friendly_name(name))
    prg.setLines(lines) unless lines.nil?
    return prg
  end

  # Adds an EnergyManagementSystemSubroutine object to the OpenStudio model.
  #
  # The EnergyManagementSystemSubroutine object allows EMS code to be reused
  # across multiple EMS programs.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param lines [Array<String>] The subroutine lines to be executed
  # @return [OpenStudio::Model::EnergyManagementSystemSubroutine] The model object
  def self.add_ems_subroutine(model, name:, lines: nil)
    sbrt = OpenStudio::Model::EnergyManagementSystemSubroutine.new(model)
    sbrt.setName(ems_friendly_name(name))
    sbrt.setLines(lines) unless lines.nil?
    return sbrt
  end

  # Adds an EnergyManagementSystemProgramCallingManager object to the OpenStudio model.
  #
  # The EnergyManagementSystemProgramCallingManager object is used to specify when
  # an EMS program is run during the simulation.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the OpenStudio object
  # @param calling_point [String] When the EMS program is called
  # @param ems_programs [Array<OpenStudio::Model::EnergyManagementSystemProgram>] The EMS programs to be managed
  # @return [OpenStudio::Model::EnergyManagementSystemProgramCallingManager] The model object
  def self.add_ems_program_calling_manager(model, name:, calling_point:, ems_programs:)
    pcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    pcm.setName(ems_friendly_name(name))
    pcm.setCallingPoint(calling_point)
    ems_programs.each do |ems_program|
      pcm.addProgram(ems_program)
    end
    return pcm
  end

  # Adds an EnergyManagementSystemOutputVariable object to the OpenStudio model.
  #
  # The EnergyManagementSystemOutputVariable object allows generating output for
  # an EMS variable; the object can be referenced by an OutputVariable object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] User-defined name for the new output variable
  # @param ems_variable_name [String] EMS variable name to be output
  # @param type_of_data [String] The nature of the variable ('averaged' or 'summed')
  # @param update_frequency [String] Timestep the variable is associated with ('ZoneTimestep' or 'SystemTimestep')
  # @param ems_program_or_subroutine [OpenStudio::Model::EnergyManagementSystemProgram or EnergyManagementSystemSubroutine] The EMS program/subroutine with the EMS variable
  # @param units [String] The units for the output variable in standard EnergyPlus units
  # @return [OpenStudio::Model::EnergyManagementSystemOutputVariable] The model object
  def self.add_ems_output_variable(model, name:, ems_variable_name:, type_of_data:, update_frequency:, ems_program_or_subroutine:, units:)
    ov = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, ems_variable_name)
    ov.setName(name)
    ov.setTypeOfDataInVariable(type_of_data)
    ov.setUpdateFrequency(update_frequency)
    ov.setEMSProgramOrSubroutineName(ems_program_or_subroutine)
    ov.setUnits(units)
    return ov
  end

  # Adds an OutputVariable object to the OpenStudio model. If there is already an
  # identical existing object on the model, returns that instead.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param key_value [String] The specific object reference for reporting
  # @param variable_name [String] The variable name as shown in the eplusout.rdd file
  # @param reporting_frequency [String] Output reporting frequency ('detailed', 'timestep', 'hourly', 'daily', 'monthly', 'runperiod', or 'annual')
  # @return [OpenStudio::Model::OutputVariable] The model object
  def self.add_output_variable(model, key_value:, variable_name:, reporting_frequency:)
    model.getOutputVariables.each do |ov|
      next unless ov.variableName == variable_name
      next unless ov.keyValue == key_value
      next unless ov.reportingFrequency == reporting_frequency

      return ov # Duplicate of existing object
    end
    ov = OpenStudio::Model::OutputVariable.new(variable_name, model)
    ov.setKeyValue(key_value)
    ov.setReportingFrequency(reporting_frequency)
    return ov
  end

  # Adds an OutputMeter object to the OpenStudio model. If there is already an
  # identical existing object on the model, returns that instead.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param meter_name [String] The meter name as shown in the eplusout.mdd file
  # @param reporting_frequency [String] Output reporting frequency ('detailed', 'timestep', 'hourly', 'daily', 'monthly', 'runperiod', or 'annual')
  # @return [OpenStudio::Model::OutputMeter] The model object
  def self.add_output_meter(model, meter_name:, reporting_frequency:)
    model.getOutputMeters.each do |om|
      next unless om.name == meter_name
      next unless om.reportingFrequency == reporting_frequency

      return om # Duplicate of existing object
    end
    om = OpenStudio::Model::OutputMeter.new(model)
    om.setName(meter_name)
    om.setReportingFrequency(reporting_frequency)
    return om
  end

  # Adds an OutputTableMonthly to the OpenStudio model. If there is already an
  # identical existing object on the model, returns that instead.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the output table
  # @param digits_after_decimal [Integer] Number of digits after the decimal point
  # @param output_var_or_meter_name [String] EnergyPlus Output:Variable or Output:Meter name
  # @param aggregation_type [String] Aggregation type (SumOrAverage, Maximum, Minimum, etc.)
  # @return [OpenStudio::Model::OutputTableMonthly] The model object
  def self.add_output_table_monthly(model, name:, digits_after_decimal: 2, output_var_or_meter_name:, aggregation_type:)
    model.getOutputTableMonthlys.each do |otm|
      next unless otm.name.to_s == name
      next unless otm.digitsAfterDecimal == digits_after_decimal
      next unless otm.numberofMonthlyVariableGroups == 1

      first_group = otm.getMonthlyVariableGroup(0).get
      next unless first_group.variableOrMeterName == output_var_or_meter_name
      next unless first_group.aggregationType == aggregation_type

      return otm # Duplicate of existing object
    end
    otm = OpenStudio::Model::OutputTableMonthly.new(model)
    otm.setName(name)
    otm.setDigitsAfterDecimal(digits_after_decimal)
    otm.addMonthlyVariableGroup(output_var_or_meter_name, aggregation_type)
    return otm
  end

  # Adds a MeterCustom to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the meter object
  # @param fuel_type [String] Fuel type (HPXML::FuelTypeXXX)
  # @param key_var_pairs [Array<Array<String>>] List of (key value, variable name) pairs to be included
  # @return [OpenStudio::Model::MeterCustom] The model object
  def self.add_meter_custom(model, name:, fuel_type:, key_var_pairs:)
    meter = OpenStudio::Model::MeterCustom.new(model)
    meter.setName(name)
    meter.setFuelType(fuel_type)
    key_var_pairs.uniq.each do |key_var|
      meter.addKeyVarGroup(key_var[0], key_var[1])
    end
    return meter
  end

  # Adds a MeterCustomDecrement to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param name [String] Name for the meter object
  # @param fuel_type [String] Fuel type (HPXML::FuelTypeXXX)
  # @param key_var_pairs [Array<Array<String>>] List of (key value, variable name) pairs to be included
  # @param source_meter_name [String] Name of source meter to subtract from
  # @return [OpenStudio::Model::MeterCustomDecrement] The model object
  def self.add_meter_custom_decrement(model, name:, fuel_type:, key_var_pairs:, source_meter_name:)
    meter = OpenStudio::Model::MeterCustomDecrement.new(model, source_meter_name)
    meter.setName(name)
    meter.setFuelType(fuel_type)
    key_var_pairs.uniq.each do |key_var|
      meter.addKeyVarGroup(key_var[0], key_var[1])
    end
    return meter
  end

  # Converts existing string to EMS friendly string.
  #
  # Source: openstudio-standards
  #
  # @param name [String] Original name
  # @return [String] The resulting EMS friendly string
  def self.ems_friendly_name(name)
    # replace white space and special characters with underscore
    # \W is equivalent to [^a-zA-Z0-9_]
    return name.to_s.gsub(/\W/, '_')
  end

  # Resets the existing model if it already has objects in it.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [nil]
  def self.reset(runner, model)
    handles = OpenStudio::UUIDVector.new
    model.objects.each do |obj|
      handles << obj.handle
    end
    if !handles.empty?
      runner.registerInfo('The model contains existing objects and is being reset.')
      model.removeObjects(handles)
    end
  end

  # When there are multiple dwelling units, merge all unit models into a single model.
  # First deal with unique objects; look for differences in values across unit models.
  # Then make all unit models "unique" by shifting geometry and prefixing object names.
  # Then bulk add all modified objects to the main OpenStudio Model object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @return [nil]
  def self.merge_unit_models(model, hpxml_osm_map)
    # Map of OpenStudio IDD objects => OSM class names
    # Note: ZoneCapacitanceMultiplierResearchSpecial is not actually unique, but we don't assign it to
    # individual thermal zones, so we'll treat it as unique here.
    unique_object_map = { 'OS:ConvergenceLimits' => 'ConvergenceLimits',
                          'OS:Foundation:Kiva:Settings' => 'FoundationKivaSettings',
                          'OS:OutputControl:Files' => 'OutputControlFiles',
                          'OS:Output:Diagnostics' => 'OutputDiagnostics',
                          'OS:Output:JSON' => 'OutputJSON',
                          'OS:PerformancePrecisionTradeoffs' => 'PerformancePrecisionTradeoffs',
                          'OS:RunPeriod' => 'RunPeriod',
                          'OS:RunPeriodControl:DaylightSavingTime' => 'RunPeriodControlDaylightSavingTime',
                          'OS:ShadowCalculation' => 'ShadowCalculation',
                          'OS:SimulationControl' => 'SimulationControl',
                          'OS:Site' => 'Site',
                          'OS:Site:GroundTemperature:Deep' => 'SiteGroundTemperatureDeep',
                          'OS:Site:GroundTemperature:Shallow' => 'SiteGroundTemperatureShallow',
                          'OS:Site:WaterMainsTemperature' => 'SiteWaterMainsTemperature',
                          'OS:SurfaceConvectionAlgorithm:Inside' => 'InsideSurfaceConvectionAlgorithm',
                          'OS:SurfaceConvectionAlgorithm:Outside' => 'OutsideSurfaceConvectionAlgorithm',
                          'OS:Timestep' => 'Timestep',
                          'OS:ZoneCapacitanceMultiplier:ResearchSpecial' => 'ZoneCapacitanceMultiplierResearchSpecial' }

    # Handle unique objects first: Grab one from the first model we find the
    # object on (may not be the first unit).
    unit_model_objects = []
    unique_handles_to_skip = []
    uuid_regex = /\{(.*?)\}/
    unique_object_map.each do |idd_obj, osm_class|
      first_model_object_by_type = nil
      hpxml_osm_map.values.each do |unit_model|
        next if unit_model.getObjectsByType(idd_obj.to_IddObjectType).empty?

        model_object = unit_model.send("get#{osm_class}")

        if first_model_object_by_type.nil?
          # Retain object for model
          unit_model_objects << model_object
          first_model_object_by_type = model_object
          if idd_obj == 'OS:Site:WaterMainsTemperature' # Handle referenced child object too
            unit_model_objects << unit_model.getObjectsByName(model_object.temperatureSchedule.get.name.to_s)[0]
          end
        else
          # Throw error if different values between this model_object and first_model_object_by_type
          if model_object.to_s.gsub(uuid_regex, '') != first_model_object_by_type.to_s.gsub(uuid_regex, '')
            fail "Unique object (#{idd_obj}) has different values across dwelling units."
          end

          if idd_obj == 'OS:Site:WaterMainsTemperature' # Handle referenced child object too
            if model_object.temperatureSchedule.get.to_s.gsub(uuid_regex, '') != first_model_object_by_type.temperatureSchedule.get.to_s.gsub(uuid_regex, '')
              fail "Unique object (#{idd_obj}) has different values across dwelling units."
            end
          end
        end

        unique_handles_to_skip << model_object.handle.to_s
        if idd_obj == 'OS:Site:WaterMainsTemperature' # Handle referenced child object too
          unique_handles_to_skip << model_object.temperatureSchedule.get.handle.to_s
        end
      end
    end

    hpxml_osm_map.values.each_with_index do |unit_model, unit_number|
      Geometry.shift_surfaces(unit_model, unit_number)
      prefix_object_names(unit_model, unit_number)

      # Handle remaining (non-unique) objects now
      unit_model.objects.each do |obj|
        next if unit_number > 0 && obj.to_Building.is_initialized
        next if unique_handles_to_skip.include? obj.handle.to_s

        unit_model_objects << obj
      end
    end

    model_size = model.to_s.size
    model.addObjects(unit_model_objects, true)
    if model.to_s.size == model_size
      # Objects not added, check for the culprit
      unit_model_objects.each do |o|
        n = model.to_s.size
        model.addObject(o)
        if model.to_s.size == n
          fail "object not successfully merged:\n\n#{o}"
        end
      end
    end
  end

  # Prefix all object names using using a provided unit number.
  #
  # @param unit_model [OpenStudio::Model::Model] OpenStudio Model object (corresponding to one of multiple dwelling units)
  # @param unit_number [Integer] index number corresponding to an HPXML Building object
  # @return [nil]
  def self.prefix_object_names(unit_model, unit_number)
    # FUTURE: Create objects with unique names up front so we don't have to do this

    # Create a new OpenStudio object name by prefixing the old with "unit" plus the unit number.
    #
    # @param obj_name [String] the OpenStudio object name
    # @param unit_number [Integer] index number corresponding to an HPXML Building object
    # @return [String] the new OpenStudio object name with unique unit prefix
    def self.make_variable_name(obj_name, unit_number)
      return ems_friendly_name("unit#{unit_number + 1}_#{obj_name}")
    end

    # EMS objects
    ems_map = {}

    unit_model.getEnergyManagementSystemSensors.each do |sensor|
      ems_map[sensor.name.to_s] = make_variable_name(sensor.name, unit_number)
      sensor.setKeyName(make_variable_name(sensor.keyName, unit_number)) unless sensor.keyName.empty? || sensor.keyName.downcase == 'environment'
    end

    unit_model.getEnergyManagementSystemActuators.each do |actuator|
      ems_map[actuator.name.to_s] = make_variable_name(actuator.name, unit_number)
    end

    unit_model.getEnergyManagementSystemInternalVariables.each do |internal_variable|
      ems_map[internal_variable.name.to_s] = make_variable_name(internal_variable.name, unit_number)
      internal_variable.setInternalDataIndexKeyName(make_variable_name(internal_variable.internalDataIndexKeyName, unit_number)) unless internal_variable.internalDataIndexKeyName.empty?
    end

    unit_model.getEnergyManagementSystemGlobalVariables.each do |global_variable|
      ems_map[global_variable.name.to_s] = make_variable_name(global_variable.name, unit_number)
    end

    unit_model.getEnergyManagementSystemOutputVariables.each do |output_variable|
      next if output_variable.emsVariableObject.is_initialized

      new_ems_variable_name = make_variable_name(output_variable.emsVariableName, unit_number)
      ems_map[output_variable.emsVariableName.to_s] = new_ems_variable_name
      output_variable.setEMSVariableName(new_ems_variable_name)
    end

    unit_model.getEnergyManagementSystemSubroutines.each do |subroutine|
      ems_map[subroutine.name.to_s] = make_variable_name(subroutine.name, unit_number)
    end

    # variables in program lines don't get updated automatically
    lhs_characters = [' ', ',', '(', ')', '+', '-', '*', '/', ';']
    rhs_characters = [''] + lhs_characters
    (unit_model.getEnergyManagementSystemPrograms + unit_model.getEnergyManagementSystemSubroutines).each do |program|
      new_lines = []
      program.lines.each do |line|
        ems_map.each do |old_name, new_name|
          next unless line.include?(old_name)

          # old_name between at least 1 character, with the exception of '' on left and ' ' on right
          lhs_characters.each do |lhs|
            next unless line.include?("#{lhs}#{old_name}")

            rhs_characters.each do |rhs|
              next unless line.include?("#{lhs}#{old_name}#{rhs}")
              next if lhs == '' && ['', ' '].include?(rhs)

              line.gsub!("#{lhs}#{old_name}#{rhs}", "#{lhs}#{new_name}#{rhs}")
            end
          end
        end
        new_lines << line
      end
      program.setLines(new_lines)
    end

    # All model objects
    unit_model.objects.each do |model_object|
      next if model_object.name.nil?

      if unit_number == 0
        # OpenStudio is unhappy if these schedules are renamed
        next if model_object.name.to_s == unit_model.alwaysOnContinuousSchedule.name.to_s
        next if model_object.name.to_s == unit_model.alwaysOnDiscreteSchedule.name.to_s
        next if model_object.name.to_s == unit_model.alwaysOffDiscreteSchedule.name.to_s
      end

      model_object.setName(make_variable_name(model_object.name, unit_number))
    end
  end
end
