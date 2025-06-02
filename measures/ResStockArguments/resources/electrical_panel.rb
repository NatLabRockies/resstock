# frozen_string_literal: true

require 'csv'

# HPXML declared values: https://github.com/NREL/OpenStudio-HPXML/blob/master/HPXMLtoOpenStudio/resources/hpxml.rb
class ElectricalPanelSampler
  def initialize(runner:,
                 building_id:,
                 **)
    @runner = runner
    @prng = Random.new(building_id) # initialize a random number generator
  end

  def assign_rated_capacity(args:)
    # load probability distribution csv
    capacity_prob_map = read_rated_capacity_probs(args[:geometry_unit_type], args[:heating_system_fuel])

    # assign rated capacity bin and value
    capacity_bin = sample_rated_capacity_bin(capacity_prob_map, args)
    capacity_value = convert_capacity_bin_to_value(capacity_bin, args[:heating_system_fuel], args[:geometry_unit_cfa_bin])

    return capacity_bin, capacity_value
  end

  def assign_breaker_space_headroom(args:)
    # load probability distribution csv
    breaker_space_headroom_prob_map = read_breaker_space_headroom_probs()

    # assign breaker space headroom number
    breaker_space_headroom = sample_breaker_space_headroom(breaker_space_headroom_prob_map, args)

    return breaker_space_headroom
  end

  def sample_rated_capacity_bin(rated_capacity_map, args)
    # get default vintage if nil (for project_testing)
    if args[:vintage].nil?
      vintage = '1960s'
    else
      vintage = args[:vintage]
    end

    if args[:geometry_unit_type] == HPXML::ResidentialTypeApartment
      geometry_unit_cfa_bin_simp = simplify_geometry_unit_cfa_bin(args[:geometry_unit_cfa_bin])
      vintage_simp = simplify_vintage(vintage)
      heating_fuel = simplify_fuel_type(args[:heating_system_fuel])

      lookup_array = [
        geometry_unit_cfa_bin_simp,
        vintage_simp,
        heating_fuel,
      ]
    elsif args[:heating_system_fuel] == HPXML::FuelTypeElectricity
      hvac_cooling_type = convert_cooling_type(args[:cooling_system_type], args[:heat_pump_type])
      clothes_dryer = convert_fuel_and_presence(args[:clothes_dryer_present], args[:clothes_dryer_fuel_type])
      cooking_range = convert_fuel_and_presence(args[:cooking_range_oven_present], args[:cooking_range_fuel_type])
      water_heater_fuel_type = simplify_fuel_type(args[:water_heater_fuel_type])

      lookup_array = [
        clothes_dryer,
        cooking_range,
        args[:geometry_unit_type],
        args[:geometry_unit_cfa_bin],
        hvac_cooling_type,
        vintage,
        water_heater_fuel_type,
      ]
    else
      lookup_array = [
        args[:geometry_unit_type],
        args[:geometry_unit_cfa_bin],
        vintage,
      ]
    end
    capacity_bins = get_row_headers(rated_capacity_map, lookup_array, header_size: 7)
    row_probability = get_row_probability(rated_capacity_map, lookup_array, header_size: 7)
    index = weighted_random(row_probability)
    return capacity_bins[index]
  end

  def sample_breaker_space_headroom(breaker_space_headroom_prob_map, args)
    # emulate Geometry Building Type RECS
    geometry_building_type_recs = convert_building_type(args[:geometry_unit_type], args[:geometry_building_num_units])
    # calculate number of major electric load
    major_elec_load_count = get_major_elec_load_count(args)

    lookup_array = [
      geometry_building_type_recs,
      args[:geometry_unit_cfa_bin],
      major_elec_load_count.to_s,
      args[:electric_panel_service_max_current_rating_bin].to_s,
    ]

    breaker_space_headroom = get_row_headers(breaker_space_headroom_prob_map, lookup_array, header_size: 32)
    row_probability = get_row_probability(breaker_space_headroom_prob_map, lookup_array, header_size: 32)
    index = weighted_random(row_probability)
    return breaker_space_headroom[index]
  end

  def convert_capacity_bin_to_value(capacity_bin, heating_system_fuel, geometry_unit_cfa_bin)
    if capacity_bin == '<100'
      if heating_system_fuel == HPXML::FuelTypeElectricity
        return 90
      else
        return 60
      end
    elsif capacity_bin == '101-124'
      return 120
    elsif capacity_bin == '126-199'
      return 150
    elsif capacity_bin == '201+'
      if geometry_unit_cfa_bin == '3000-3999'
        return 300
      elsif geometry_unit_cfa_bin == '4000+'
        return 400
      else
        return 250
      end
    else
      return Float(capacity_bin)
    end
  end

  def get_major_elec_load_count(args)
    # has electric primary heating
    has_elec_heating_primary = is_electric_fuel(args[:heating_system_fuel])
    # has electric water heater
    has_elec_water_heater = is_electric_fuel(args[:water_heater_fuel_type])
    # has cooling that is central and not heat pump
    has_cooling = has_central_non_heat_pump_cooling(args)
    # appliance presence and electric fuel
    has_elec_drying = electric_fuel_and_presence(args[:clothes_dryer_present], args[:clothes_dryer_fuel_type])
    has_elec_cooking = electric_fuel_and_presence(args[:cooking_range_oven_present], args[:cooking_range_fuel_type])
    # has pv
    has_pv = bool_to_numeric(args[:pv_system_present])
    # has ev charging
    has_ev_charging = bool_to_numeric(args[:ev_charger_present])

    load_vars = [
      has_elec_heating_primary,
      has_elec_water_heater,
      has_elec_drying,
      has_elec_cooking,
      has_cooling,
      has_ev_charging,
      has_pv
    ]
    # The maximum load_count is 7.
    # The calculation of load_count is based on the available information of training data, not the real load count in the model.
    load_count = load_vars.sum
    return load_count
  end

  def simplify_geometry_unit_cfa_bin(geometry_unit_cfa_bin)
    if ['0-499', '500-749', '750-999'].include?(geometry_unit_cfa_bin)
      return '0-999'
    elsif ['1000-1499', '1500-1999'].include?(geometry_unit_cfa_bin)
      return '1000-1999'
    elsif ['2000-2499', '2500-2999', '3000-3999', '4000+'].include?(geometry_unit_cfa_bin)
      return '2000+'
    else
      @runner.registerError("ElectricalPanelSampler cannot simplify geometry_unit_cfa_bin: '#{geometry_unit_cfa_bin}'.")
    end
  end

  def simplify_vintage(vintage)
    if vintage == '<1940'
      return vintage
    elsif ['1940s', '1950s', '1960s'].include?(vintage)
      return '1940-69'
    elsif vintage == '1970s'
      return '1970-79'
    elsif vintage == '1980s'
      return '1980-89'
    elsif ['1990s', '2000s', '2010s'].include?(vintage)
      return '1990+'
    else
      @runner.registerError("ElectricalPanelSampler cannot simplify vintage: '#{vintage}'.")
    end
  end

  def convert_building_type(geometry_unit_type, geometry_building_num_units)
    if geometry_unit_type == HPXML::ResidentialTypeApartment
      if geometry_building_num_units < 5
        return 'apartment unit, 2-4'
      else
        return 'apartment unit, 5+'
      end
    elsif [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeSFD, HPXML::ResidentialTypeManufactured].include?(geometry_unit_type)
      return geometry_unit_type
    else
      @runner.registerError("ElectricalPanelSampler cannot map geometry_unit_type: '#{geometry_unit_type}'.")
    end
  end

  def convert_cooling_type(cooling_system_type, heat_pump_type)
    if [HPXML::HVACTypeCentralAirConditioner, HPXML::HVACTypeRoomAirConditioner].include?(cooling_system_type)
      return cooling_system_type
    elsif cooling_system_type == HPXML::TypeNone
      if heat_pump_type != HPXML::TypeNone
        return 'heat pump'
      else
        return 'none'
      end
    elsif cooling_system_type == HPXML::HVACTypeMiniSplitAirConditioner
      # shared cooling, use none for lookup (note: this would be different if assigned via tsv since shared cooling is not none in HVAC Cooling Type)
      return 'none'
    else
      @runner.registerError("ElectricalPanelSampler cannot map cooling type based on: '#{cooling_system_type}' and '#{heat_pump_type}'.")
    end
  end

  def has_central_non_heat_pump_cooling(args)
    # emulate HVAC Cooling Type
    hvac_cooling_type = convert_cooling_type(args[:cooling_system_type], args[:heat_pump_type])
    is_ducted_heat_pump_heating = is_ducted_heat_pump_heating(args[:heat_pump_type])

    # Adjust count for cooling
    if hvac_cooling_type == 'none'
      return 0
    elsif hvac_cooling_type == 'heat pump' && is_ducted_heat_pump_heating
      return 0 # Ducted heat pump provides heating and cooling, so no additional slots for cooling
    elsif hvac_cooling_type == HPXML::HVACTypeRoomAirConditioner
      return 0 # All Room ACs are assumed plug-in and do not take up slots
    else
      return 1
    end
  end

  def is_ducted_heat_pump_heating(heat_pump_type)
    if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpGroundToAir].include?(heat_pump_type)
      return true
    else
      return false
    end
  end

  def convert_fuel_and_presence(equipment_present, fuel_type)
    if not equipment_present
      return 'none'
    else
      return simplify_fuel_type(fuel_type)
    end
  end

  def simplify_fuel_type(fuel_type)
    if fuel_type == HPXML::FuelTypeElectricity
      return fuel_type
    else
      return 'non-electricity'
    end
  end

  def electric_fuel_and_presence(equipment_present, fuel_type)
    if not equipment_present
      return 0
    else
      return is_electric_fuel(fuel_type)
    end
  end

  def is_electric_fuel(fuel_type)
    if fuel_type == HPXML::FuelTypeElectricity
      return 1
    else
      return 0
    end
  end

  def bool_to_numeric(is_present)
    if is_present
      return 1
    else
      return 0
    end
  end

  def read_rated_capacity_probs(geometry_unit_type, heating_system_fuel)
    if geometry_unit_type == HPXML::ResidentialTypeApartment
      filename = 'electrical_panel_rated_capacity__multi_family.csv'
    elsif heating_system_fuel == HPXML::FuelTypeElectricity
      filename = 'electrical_panel_rated_capacity__single_family_electric_heating.csv'
    else
      filename = 'electrical_panel_rated_capacity__single_family_nonelectric_heating.csv'
    end
    file = File.absolute_path(File.join(File.dirname(__FILE__), 'electrical_panel', filename))
    prob_table = CSV.read(file)
    return prob_table
  end

  def read_breaker_space_headroom_probs()
    filename = 'electrical_panel_breaker_space.csv'
    file = File.absolute_path(File.join(File.dirname(__FILE__), 'electrical_panel', filename))
    prob_table = CSV.read(file)
    return prob_table
  end

  def get_row_headers(prob_table, lookup_array, header_size:)
    len = lookup_array.length()
    row_headers = prob_table[0][len..len + header_size - 1]
    return row_headers
  end

  def get_row_probability(prob_table, lookup_array, header_size:)
    len = lookup_array.length()
    row_probability = []
    prob_table.each do |row|
      next if row[0..len - 1] != lookup_array

      row_probability = row[len..len + header_size - 1].map(&:to_f)
    end

    if row_probability.length() != header_size
      @runner.registerError("ElectricalPanelSampler cannot find row_probability for keys: #{lookup_array}")
    end
    return row_probability
  end

  def weighted_random(weights)
    n = @prng.rand
    cum_weights = 0
    weights.each_with_index do |w, index|
      cum_weights += w
      if n <= cum_weights
        return index
      end
    end
    return weights.size - 1 # If the prob weight don't sum to n, return last index
  end
end
