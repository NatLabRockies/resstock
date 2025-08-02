# frozen_string_literal: true

require 'csv'

# HPXML declared values: https://github.com/NREL/OpenStudio-HPXML/blob/master/HPXMLtoOpenStudio/resources/hpxml.rb
class ElectricalPanelSampler
  def initialize(runner, building_id, hpxml_bldg)
    @runner = runner
    @prng = Random.new(Integer(building_id)) # initialize a random number generator

    @unit_type = hpxml_bldg.building_construction.residential_facility_type
    @num_units = 1 # FIXME
    @heating_fuel = (hpxml_bldg.heating_systems.find { |h| h.primary_system }.heating_system_fuel rescue nil)
    @hp_type = (hpxml_bldg.heat_pumps.find { |hp| hp.primary_system }.heat_pump_type rescue nil)
    @cooling_type = (hpxml_bldg.cooling_systems.find { |c| c.primary_system }.cooling_system_type rescue nil)
    @dryer_fuel = (hpxml_bldg.clothes_dryers[0].fuel_type rescue nil)
    @cooking_range_oven_fuel = (hpxml_bldg.cooking_ranges[0].fuel_type rescue nil)
    @water_heater_fuel = (hpxml_bldg.water_heating_systems[0].fuel_type rescue nil)
    @has_pv = (hpxml_bldg.pv_systems.size > 0)
    @has_ev_charging = (hpxml_bldg.ev_chargers.size > 0)

    @cfa = hpxml_bldg.building_construction.conditioned_floor_area
    if @cfa < 500
      @cfa_bin = '0-499'
    elsif @cfa < 750
      @cfa_bin = '500-749'
    elsif @cfa < 1000
      @cfa_bin = '750-999'
    elsif @cfa < 1500
      @cfa_bin = '1000-1499'
    elsif @cfa < 2000
      @cfa_bin = '1500-1999'
    elsif @cfa < 2500
      @cfa_bin = '2000-2499'
    elsif @cfa < 3000
      @cfa_bin = '2500-2999'
    elsif @cfa < 4000
      @cfa_bin = '3000-3999'
    else
      @cfa_bin = '4000+'
    end

    year_built = hpxml_bldg.building_construction.year_built
    year_built = 1960 if year_built.nil? # get default year_built if nil (for project_testing)
    if year_built < 1940
      @vintage = '<1940'
    elsif year_built < 1950
      @vintage = '1940s'
    elsif year_built < 1960
      @vintage = '1950s'
    elsif year_built < 1970
      @vintage = '1960s'
    elsif year_built < 1980
      @vintage = '1970s'
    elsif year_built < 1990
      @vintage = '1980s'
    elsif year_built < 2000
      @vintage = '1990s'
    elsif year_built < 2010
      @vintage = '2000s'
    elsif year_built < 2020
      @vintage = '2010s'
    end
  end

  def assign_rated_capacity()
    # load probability distribution csv
    capacity_prob_map = read_rated_capacity_probs()

    # assign rated capacity bin and value
    capacity_bin = sample_rated_capacity_bin(capacity_prob_map)
    capacity_value = convert_capacity_bin_to_value(capacity_bin)

    return capacity_bin, Float(capacity_value)
  end

  def assign_breaker_space_headroom(cap_bin)
    # load probability distribution csv
    breaker_space_headroom_prob_map = read_breaker_space_headroom_probs()

    # assign breaker space headroom number
    breaker_space_headroom = sample_breaker_space_headroom(breaker_space_headroom_prob_map, cap_bin)

    return breaker_space_headroom
  end

  def sample_rated_capacity_bin(rated_capacity_map)
    if @unit_type == HPXML::ResidentialTypeApartment
      geometry_unit_cfa_bin_simp = simplify_geometry_unit_cfa_bin()
      vintage_simp = simplify_vintage()
      heating_fuel_simp = simplify_fuel(@heating_fuel)

      lookup_array = [
        geometry_unit_cfa_bin_simp,
        vintage_simp,
        heating_fuel_simp,
      ]
    elsif @heating_fuel == HPXML::FuelTypeElectricity
      cooling_type = convert_cooling_type(@cooling_type, @hp_type)
      clothes_dryer_fuel = simplify_fuel(@dryer_fuel)
      cooking_range_fuel = simplify_fuel(@cooking_range_oven_fuel)
      water_heater_fuel = simplify_fuel(@water_heater_fuel)

      lookup_array = [
        clothes_dryer_fuel,
        cooking_range_fuel,
        @unit_type,
        @cfa_bin,
        cooling_type,
        @vintage,
        water_heater_fuel,
      ]
    else
      lookup_array = [
        @unit_type,
        @cfa_bin,
        @vintage,
      ]
    end
    capacity_bins = get_row_headers(rated_capacity_map, lookup_array, header_size: 7)
    row_probability = get_row_probability(rated_capacity_map, lookup_array, header_size: 7)
    index = weighted_random(row_probability)
    return capacity_bins[index]
  end

  def sample_breaker_space_headroom(breaker_space_headroom_prob_map, cap_bin)
    # emulate Geometry Building Type RECS
    geometry_building_type_recs = convert_building_type(@unit_type, @num_units)
    # calculate number of major electric load
    major_elec_load_count = get_major_elec_load_count()

    lookup_array = [
      geometry_building_type_recs,
      @cfa_bin,
      major_elec_load_count.to_s,
      cap_bin.to_s,
    ]
    breaker_space_headroom = get_row_headers(breaker_space_headroom_prob_map, lookup_array, header_size: 32)
    row_probability = get_row_probability(breaker_space_headroom_prob_map, lookup_array, header_size: 32)
    index = weighted_random(row_probability)
    return Integer(breaker_space_headroom[index])
  end

  def convert_capacity_bin_to_value(capacity_bin)
    if capacity_bin == '<100'
      if @heating_fuel == HPXML::FuelTypeElectricity
        return 90
      else
        return 60
      end
    elsif capacity_bin == '101-124'
      return 120
    elsif capacity_bin == '126-199'
      return 150
    elsif capacity_bin == '201+'
      if @cfa_bin == '3000-3999'
        return 300
      elsif @cfa_bin == '4000+'
        return 400
      else
        return 250
      end
    else
      return Float(capacity_bin)
    end
  end

  def get_major_elec_load_count()
    has_elec_heating_primary = is_electric_fuel(@heating_fuel)
    has_elec_water_heater = is_electric_fuel(@water_heater_fuel)
    has_cooling = has_central_non_heat_pump_cooling()
    has_elec_drying = is_electric_fuel(@dryer_fuel)
    has_elec_cooking = is_electric_fuel(@cooking_range_oven_fuel)
    has_pv = bool_to_numeric(@has_pv)
    has_ev_charging = bool_to_numeric(@has_ev_charging)

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

  def simplify_geometry_unit_cfa_bin()
    if ['0-499', '500-749', '750-999'].include?(@cfa_bin)
      return '0-999'
    elsif ['1000-1499', '1500-1999'].include?(@cfa_bin)
      return '1000-1999'
    elsif ['2000-2499', '2500-2999', '3000-3999', '4000+'].include?(@cfa_bin)
      return '2000+'
    else
      @runner.registerError("ElectricalPanelSampler cannot simplify cfa_bin: '#{@cfa_bin}'.")
    end
  end

  def simplify_vintage()
    if @vintage == '<1940'
      return @vintage
    elsif ['1940s', '1950s', '1960s'].include?(@vintage)
      return '1940-69'
    elsif @vintage == '1970s'
      return '1970-79'
    elsif @vintage == '1980s'
      return '1980-89'
    elsif ['1990s', '2000s', '2010s'].include?(@vintage)
      return '1990+'
    else
      @runner.registerError("ElectricalPanelSampler cannot simplify vintage: '#{@vintage}'.")
    end
  end

  def convert_building_type(geometry_facility_type, geometry_building_num_units)
    if geometry_facility_type == HPXML::ResidentialTypeApartment
      if geometry_building_num_units < 5
        return 'apartment unit, 2-4'
      else
        return 'apartment unit, 5+'
      end
    elsif [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeSFD, HPXML::ResidentialTypeManufactured].include?(geometry_facility_type)
      return geometry_facility_type
    else
      @runner.registerError("ElectricalPanelSampler cannot map geometry_facility_type: '#{geometry_facility_type}'.")
    end
  end

  def convert_cooling_type(cooling_type, hp_type)
    if [HPXML::HVACTypeCentralAirConditioner, HPXML::HVACTypeRoomAirConditioner].include?(cooling_type)
      return cooling_type
    elsif cooling_type.nil?
      if not hp_type.nil?
        return 'heat pump'
      else
        return 'none'
      end
    elsif cooling_type == HPXML::HVACTypeMiniSplitAirConditioner
      # shared cooling, use none for lookup (note: this would be different if assigned via tsv since shared cooling is not none in HVAC Cooling Type)
      return 'none'
    else
      @runner.registerError("ElectricalPanelSampler cannot map cooling type based on: '#{cooling_type}' and '#{hp_type}'.")
    end
  end

  def has_central_non_heat_pump_cooling()
    # emulate HVAC Cooling Type
    hvac_cooling_type = convert_cooling_type(@cooling_type, @heat_pump_type)
    is_ducted_heat_pump_heating = is_ducted_heat_pump_heating(@heat_pump_type)

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

  def convert_fuel_and_presence(equipment_present, fuel)
    if not equipment_present
      return 'none'
    else
      return simplify_fuel(fuel)
    end
  end

  def simplify_fuel(fuel)
    if fuel.nil?
      return 'none'
    elsif fuel == HPXML::FuelTypeElectricity
      return fuel
    else
      return 'non-electricity'
    end
  end

  def is_electric_fuel(fuel)
    if fuel.nil?
      return 0
    elsif fuel == HPXML::FuelTypeElectricity
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

  def read_rated_capacity_probs()
    if @unit_type == HPXML::ResidentialTypeApartment
      filename = 'electrical_panel_rated_capacity__multi_family.csv'
    elsif @heating_fuel == HPXML::FuelTypeElectricity
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
