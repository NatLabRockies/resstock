# frozen_string_literal: true

# Collection of methods related to Photovoltaic systems.
module PV
  # Adds any HPXML Photovoltaics to the OpenStudio model.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.apply(runner, model, hpxml_bldg)
    total_max_power_output = hpxml_bldg.pv_systems.map { |pv| pv.max_power_output }.sum
    return if total_max_power_output <= 0

    # Get inverter efficiency
    # If multiple inverters with different efficiencies, calculate PV size weighted-average
    inverter_efficiency = 0.0
    hpxml_bldg.pv_systems.each do |pv_system|
      inverter_efficiency += (pv_system.inverter.inverter_efficiency * pv_system.max_power_output / total_max_power_output)
    end
    if hpxml_bldg.inverters.map { |i| i.inverter_efficiency }.uniq.size > 1
      runner.registerWarning('Inverters with varying efficiencies found; using a single PV size weighted-average in the model.')
    end

    hpxml_bldg.pv_systems.each do |pv_system|
      apply_pv_system(model, hpxml_bldg, pv_system, inverter_efficiency)
    end
  end

  # Adds the HPXML Photovoltaic to the OpenStudio model.
  #
  # Apply a photovoltaic system to the model using OpenStudio ElectricLoadCenterDistribution, ElectricLoadCenterInverterPVWatts, and GeneratorPVWatts objects.
  # The system may be shared, in which case max power is apportioned to the dwelling unit by total number of bedrooms served.
  # In case an ElectricLoadCenterDistribution object does not already exist, a new ElectricLoadCenterInverterPVWatts object is set on a new ElectricLoadCenterDistribution object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param pv_system [HPXML::PVSystem] Object that defines a single solar electric photovoltaic (PV) system
  # @param inverter_efficiency [Double] Efficiency of the inverter
  # @return [nil]
  def self.apply_pv_system(model, hpxml_bldg, pv_system, inverter_efficiency)
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    unit_multiplier = hpxml_bldg.building_construction.number_of_units
    obj_name = pv_system.id

    # Apply unit multiplier
    max_power = pv_system.max_power_output * unit_multiplier
    return if max_power <= 0

    if pv_system.is_shared_system
      # Apportion to single dwelling unit by # bedrooms
      fail if pv_system.number_of_bedrooms_served.to_f <= nbeds.to_f # EPvalidator.sch should prevent this

      max_power = max_power * nbeds.to_f / pv_system.number_of_bedrooms_served.to_f
    end

    elcds = model.getElectricLoadCenterDistributions
    if elcds.empty?
      elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
      elcd.setName('PVSystem elec load center dist')

      ipvwatts = OpenStudio::Model::ElectricLoadCenterInverterPVWatts.new(model)
      ipvwatts.setName('PVSystem inverter')
      ipvwatts.setInverterEfficiency(inverter_efficiency)

      elcd.setInverter(ipvwatts)
    else
      elcd = elcds[0]
    end

    gpvwatts = OpenStudio::Model::GeneratorPVWatts.new(model, max_power)
    gpvwatts.setName("#{obj_name} generator")
    gpvwatts.setSystemLosses(pv_system.system_losses_fraction)
    gpvwatts.setTiltAngle(pv_system.array_tilt)
    gpvwatts.setAzimuthAngle(pv_system.array_azimuth)
    gpvwatts.additionalProperties.setFeature('ObjectType', Constants::ObjectTypePhotovoltaics)

    case pv_system.tracking
    when HPXML::PVTrackingTypeFixed
      if pv_system.location == HPXML::LocationRoof
        gpvwatts.setArrayType('FixedRoofMounted')
      elsif pv_system.location == HPXML::LocationGround
        gpvwatts.setArrayType('FixedOpenRack')
      end
    when HPXML::PVTrackingType1Axis
      gpvwatts.setArrayType('OneAxis')
    when HPXML::PVTrackingType1AxisBacktracked
      gpvwatts.setArrayType('OneAxisBacktracking')
    when HPXML::PVTrackingType2Axis
      gpvwatts.setArrayType('TwoAxis')
    end

    case pv_system.module_type
    when HPXML::PVModuleTypeStandard
      gpvwatts.setModuleType('Standard')
    when HPXML::PVModuleTypePremium
      gpvwatts.setModuleType('Premium')
    when HPXML::PVModuleTypeThinFilm
      gpvwatts.setModuleType('ThinFilm')
    end

    elcd.addGenerator(gpvwatts)
  end

  # Calculates the maximum power output of the array.
  #
  # @param number_of_panels [Integer] Number of PV panels
  # @param pv_year [Integer] Year panels were manufactured or installed
  # @return [Double] The maximum power output for the array (W)
  def self.calc_max_power_output_from_num_panels(number_of_panels, pv_year)
    # Equation from Home Energy Score
    return [Float((number_of_panels * (13.3 * pv_year - 26494.0)).round), 0.0].max
  end

  # Calculates the system losses fraction using an assumed annual degradation.
  #
  # @param pv_year [Integer] Year panels were manufactured or installed
  # @return [Double] the calculated losses fraction from year
  def self.calc_losses_fraction_from_year(pv_year)
    base_loss_fraction = 0.14 # Default from PV Watts, excludes age-based degradation
    degradation_per_year = 0.995 # 0.5%/yr
    age = [Time.new.year - pv_year, 0].max
    return 1.0 - (1.0 - base_loss_fraction) * degradation_per_year**age
  end

  # Calculates the number of PV panels for a given array area.
  #
  # @param collector_area [Double] Total area of PV array (ft2)
  # @return [Integer] Number of panels (#)
  def self.calc_num_panels_from_area(collector_area)
    # Assumption from Home Energy Score
    return [(collector_area / 17.6).round, 1].max
  end
end
