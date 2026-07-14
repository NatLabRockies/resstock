# frozen_string_literal: true

# Collection of methods related to getting units by fuel type, EIA average and marginal rates by state, and household consumptions by state.
class UtilityBills
  # Get type of unit according to HPXML fuel type.
  #
  # @param fuel_type [String] HPXML fuel type
  # @return [String] type of unit as stored in unit_conversions.rb
  def self.get_fuel_units(fuel_type)
    return { HPXML::FuelTypeElectricity => 'kwh',
             HPXML::FuelTypeNaturalGas => 'therm',
             HPXML::FuelTypeOil => 'gal_fuel_oil',
             HPXML::FuelTypePropane => 'gal_propane',
             HPXML::FuelTypeCoal => 'kbtu',
             HPXML::FuelTypeWoodCord => 'kbtu',
             HPXML::FuelTypeWoodPellets => 'kbtu' }[fuel_type]
  end

  # For a given state, get either the average rate from EIA data and calculate the marginal rate or calculate the average rate from a given marginal rate.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param state_code [String] State code from the HPXML file
  # @param fuel_type [String] HPXML fuel type
  # @param fixed_charge [Double] the monthly fixed charge (USD/month)
  # @param marginal_rate [Double] the marginal flat rate (USD/kWh or USD/therm, etc.)
  # @return [Array<Double, Double>] the marginal and average rates (USD/kWh or USD/therm, etc., USD/month)
  def self.get_rates_from_eia_data(runner, state_code, fuel_type, fixed_charge, marginal_rate = nil)
    state_codes = Constants::StateCodesMap.keys
    state_codes << 'US'
    return unless state_codes.include? state_code # Check if the state_code is valid

    average_rate = nil

    if [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas].include? fuel_type
      household_consumption = get_household_consumption(state_code, fuel_type)
    end

    if not marginal_rate.nil?
      case fuel_type
      when HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas
        # Calculate average rate from user-specified marginal rate, user-specified fixed charge, and EIA data
        average_rate = marginal_rate_to_average_rate(marginal_rate, fixed_charge, household_consumption)
      when HPXML::FuelTypeOil, HPXML::FuelTypePropane, HPXML::FuelTypeCoal, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets
        # Do nothing
      end
    else
      case fuel_type
      when HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas
        average_rate = get_eia_seds_rate(runner, state_code, fuel_type)
        marginal_rate = average_rate_to_marginal_rate(average_rate, fixed_charge, household_consumption)
      when HPXML::FuelTypeOil, HPXML::FuelTypePropane, HPXML::FuelTypeCoal, HPXML::FuelTypeWoodCord, HPXML::FuelTypeWoodPellets
        marginal_rate = get_eia_seds_rate(runner, state_code, fuel_type)
      end
    end

    marginal_rate = marginal_rate.round(4) unless marginal_rate.nil?
    average_rate = average_rate.round(4) unless average_rate.nil?

    return marginal_rate, average_rate
  end

  # Get the average household consumption (kWh or therm per home per year) by state.
  #
  # @param state_code [String] State code from the HPXML file
  # @param fuel_type [String] HPXML fuel type
  # @return [Double] average household electricity or natural gas consumption (kWh/home/yr or therms/home/yr)
  def self.get_household_consumption(state_code, fuel_type)
    rows = CSV.read(File.join(File.dirname(__FILE__), '../../ReportUtilityBills/resources/simple_rates/HouseholdConsumption.csv'))
    rows.each do |row|
      next if row[0] != state_code

      if fuel_type == HPXML::FuelTypeElectricity
        return Float(row[1])
      elsif fuel_type == HPXML::FuelTypeNaturalGas
        return Float(row[2])
      end
    end
  end

  # Get the marginal rate given fixed charge and average household consumption.
  #
  # @param average_rate [Double] the fuel rate averaged over both fixed and marginal annual costs (USD/kWh or USD/therm, etc.)
  # @param fixed_charge [Double] the monthly fixed charge (USD/month)
  # @param household_consumption [Double] average household electricity or natural gas consumption (kWh/home/yr or therms/home/yr)
  # @return [Double] the marginal flat rate (USD/kWh or USD/therm, etc.)
  def self.average_rate_to_marginal_rate(average_rate, fixed_charge, household_consumption)
    return average_rate - 12.0 * fixed_charge / household_consumption
  end

  # Get the average rate given fixed charge and average household consumption.
  #
  # @param marginal_rate [Double] the marginal flat rate (USD/kWh or USD/therm, etc.)
  # @param fixed_charge [Double] the monthly fixed charge (USD/month)
  # @param household_consumption [Double] average household electricity or natural gas consumption (kWh/home/yr or therms/home/yr)
  # @return [Double] the fuel rate averaged over both fixed and marginal annual costs (USD/kWh or USD/therm, etc.)
  def self.marginal_rate_to_average_rate(marginal_rate, fixed_charge, household_consumption)
    return marginal_rate + 12.0 * fixed_charge / household_consumption
  end

  # Get the EIA SEDS prices by state and fuel type.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param state_code [String] State code from the HPXML file
  # @param fuel_type [String] HPXML fuel type
  # @return [Double] average rate for electricity or natural gas, and marginal rate for all other fuel types (USD/kWh or USD/therm, etc.)
  def self.get_eia_seds_rate(runner, state_code, fuel_type)
    csv_path = File.join(File.dirname(__FILE__), '../../ReportUtilityBills/resources/simple_rates/eia_fuel_rates_by_state.csv')

    # Collect the latest matching EIA SEDS rate for this state and fuel
    matching_rate = nil
    csv_fuel = fuel_type.to_s.downcase == HPXML::FuelTypeWoodPellets.to_s.downcase ? 'wood' : fuel_type.to_s.downcase

    CSV.foreach(csv_path, headers: true) do |row|
      next if row['state'].to_s.upcase != state_code.to_s.upcase
      next if row['fuel'].to_s.downcase != csv_fuel

      year = row['year'].to_i
      rate = row['rate_dollar_per_mmbtu'].to_f
      matching_rate = { year: year, rate: rate }
      break
    end

    if matching_rate.nil?
      runner.registerWarning("No EIA SEDS rate for #{fuel_type} was found for the state of #{state_code}.") if !runner.nil?
      return 0.0
    end

    if matching_rate[:rate] != 0.0
      seds_rate = matching_rate[:rate]
    else
      # Rate is zero/missing
      runner.registerWarning(
        "EIA SEDS rate for #{fuel_type} in #{state_code} is unavailable for #{matching_rate[:year]}."
      ) if !runner.nil?
      return 0.0
    end

    # Convert $/MMBtu to $/[fuel unit]
    seds_rate = UnitConversions.convert(seds_rate, get_fuel_units(fuel_type), 'mbtu')
    return seds_rate
  end
end
