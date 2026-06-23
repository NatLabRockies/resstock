# frozen_string_literal: true

# Collection of methods related to generators.
module Generator
  # Adds any HPXML Generators to the OpenStudio model.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply(model, hpxml_bldg)
    hpxml_bldg.generators.each do |generator|
      apply_generator(model, hpxml_bldg, generator)
    end
  end

  # Adds the HPXML Generator to the OpenStudio model.
  #
  # Apply a on-site power generator to the model using OpenStudio GeneratorMicroTurbine and ElectricLoadCenterDistribution objects.
  # The system may be shared, in which case annual consumption (kBtu) and output (kWh) are apportioned to the dwelling unit by total number of bedrooms served.
  # A new ElectricLoadCenterDistribution object is created for each generator.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param generator [HPXML::Generator] Object that defines a single generator that provides on-site power
  # @return [nil]
  def self.apply_generator(model, hpxml_bldg, generator)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    obj_name = generator.id

    # Apply unit multiplier
    annual_consumption_kbtu = generator.annual_consumption_kbtu * unit_multiplier
    annual_output_kwh = generator.annual_output_kwh * unit_multiplier

    if generator.is_shared_system
      # Apportion to single dwelling unit by # bedrooms
      fail if generator.number_of_bedrooms_served.to_f <= nbeds.to_f # EPvalidator.sch should prevent this

      annual_consumption_kbtu = annual_consumption_kbtu * nbeds.to_f / generator.number_of_bedrooms_served.to_f
      annual_output_kwh = annual_output_kwh * nbeds.to_f / generator.number_of_bedrooms_served.to_f
    end

    input_w = UnitConversions.convert(annual_consumption_kbtu, 'kBtu', 'Wh') / 8760.0
    output_w = UnitConversions.convert(annual_output_kwh, 'kWh', 'Wh') / 8760.0
    efficiency = output_w / input_w
    fail if efficiency > 1.0 # EPvalidator.sch should prevent this

    curve_biquadratic_constant = Model.add_curve_biquadratic(
      model,
      name: 'ConstantBiquadratic',
      coeff: [1, 0, 0, 0, 0, 0]
    )
    curve_cubic_constant = Model.add_curve_cubic(
      model,
      name: 'ConstantCubic',
      coeff: [1, 0, 0, 0]
    )

    gmt = OpenStudio::Model::GeneratorMicroTurbine.new(model)
    gmt.setName("#{obj_name} generator")
    gmt.setFuelType(EPlus.fuel_type(generator.fuel_type))
    gmt.setReferenceElectricalPowerOutput(output_w)
    gmt.setMinimumFullLoadElectricalPowerOutput(output_w - 0.001)
    gmt.setMaximumFullLoadElectricalPowerOutput(output_w)
    gmt.setReferenceElectricalEfficiencyUsingLowerHeatingValue(efficiency)
    gmt.setFuelHigherHeatingValue(50000)
    gmt.setFuelLowerHeatingValue(50000)
    gmt.setStandbyPower(0.0)
    gmt.setAncillaryPower(0.0)
    gmt.electricalPowerFunctionofTemperatureandElevationCurve.remove
    gmt.electricalEfficiencyFunctionofTemperatureCurve.remove
    gmt.electricalEfficiencyFunctionofPartLoadRatioCurve.remove
    gmt.setElectricalPowerFunctionofTemperatureandElevationCurve(curve_biquadratic_constant)
    gmt.setElectricalEfficiencyFunctionofTemperatureCurve(curve_cubic_constant)
    gmt.setElectricalEfficiencyFunctionofPartLoadRatioCurve(curve_cubic_constant)
    gmt.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeGenerator)

    elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
    elcd.setName("#{obj_name} elec load center dist")
    elcd.setGeneratorOperationSchemeType('Baseload')
    elcd.addGenerator(gmt)
    elcd.setElectricalBussType('AlternatingCurrent')
  end
end
