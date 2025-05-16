# frozen_string_literal: true

require 'csv'
require 'matrix'
# Collection of methods related to the generation of stochastic occupancy schedules.
class ScheduleGenerator
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param state [String] State code from the HPXML file
  # @param column_names [Array<String>] list of the schedule column names to generate
  # @param random_seed [Integer] the seed for the random number generator
  # @param minutes_per_step [Integer] the simulation timestep (minutes)
  # @param steps_in_day [Integer] the number of steps in a 24-hour day
  # @param total_days_in_year [Integer] number of days in the calendar year
  # @param sim_year [Integer] the calendar year
  # @param sim_start_day [DateTime] the DateTime object corresponding to Jan 1 of the calendar year
  # @param debug [Boolean] If true, writes extra column(s) (e.g., sleeping) for informational purposes.
  # @param append_output [Boolean] If true and the output CSV file already exists, appends columns to the file rather than overwriting it. The existing output CSV file must have the same number of rows (i.e., timeseries frequency) as the new columns being appended.
  def initialize(runner:,
                 hpxml_bldg:,
                 state:,
                 column_names: nil,
                 random_seed: nil,
                 minutes_per_step:,
                 steps_in_day:,
                 total_days_in_year:,
                 sim_year:,
                 sim_start_day:,
                 debug:,
                 append_output:,
                 **)
    @runner = runner
    @hpxml_bldg = hpxml_bldg
    @state = state
    @column_names = column_names
    @random_seed = random_seed
    @minutes_per_step = minutes_per_step
    @steps_in_day = steps_in_day
    @total_days_in_year = total_days_in_year
    @mkc_ts_per_day = 96
    @mkc_ts_per_hour = 96 / 24
    @minutes_per_mkc_ts = 15
    @minutes_per_day = 1440
    @mkc_steps_in_a_year = @total_days_in_year * @mkc_ts_per_day
    @mins_in_year = @total_days_in_year * 1440
    @sim_year = sim_year
    @sim_start_day = sim_start_day
    @debug = debug
    @append_output = append_output
  end

  attr_accessor(:schedules)

  # Get the subset of schedule column names that the stochastic schedule generator supports.
  #
  # @return [Array<String>] list of all schedule column names whose schedules can be stochastically generated
  def self.export_columns
    return SchedulesFile::Columns.values.select { |c| c.can_be_stochastic }.map { |c| c.name }
  end

  # The top-level method for initializing the schedules hash just before calling the main stochastic schedules method.
  #
  # @param args [Hash] Map of :argument_name => value
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [Boolean] true if successful
  def create(args:,
             weather:)
    @schedules = {}

    invalid_columns = (@column_names - ScheduleGenerator.export_columns)
    invalid_columns.each do |invalid_column|
      @runner.registerError("Invalid column name specified: '#{invalid_column}'.")
    end
    return false unless invalid_columns.empty?

    success = create_stochastic_schedules(args: args, weather: weather)
    return false if not success

    return true
  end

  # Export the generated schedules to a CSV file.
  #
  # @param schedules_path [String] Path to write the schedules CSV file to
  # @return [Boolean] Returns true if successful, false if there was an error
  def export(schedules_path:)
    (ScheduleGenerator.export_columns - @column_names).each do |col_to_remove|
      @schedules.delete(col_to_remove)
    end
    schedule_keys = @schedules.keys
    schedule_rows = @schedules.values.transpose.map { |row| row.map { |x| '%.3g' % x } }
    if @append_output && File.exist?(schedules_path)
      table = CSV.read(schedules_path)
      if table.size != schedule_rows.size + 1
        @runner.registerError("Invalid number of rows (#{table.size}) in file.csv. Expected #{schedule_rows.size + 1} rows (including the header row).")
        return false
      end
      schedule_keys = table[0] + schedule_keys
      schedule_rows = schedule_rows.map.with_index { |row, i| table[i + 1] + row }
    end

    # Note: We don't use the CSV library here because it's slow for large files
    File.open(schedules_path, 'w') do |csv|
      csv << "#{schedule_keys.join(',')}\n"
      schedule_rows.each do |row|
        csv << "#{row.join(',')}\n"
      end
    end

    return true
  end

  private

  # The main method for creating stochastic schedules.
  #
  # @param args [Hash] Map of :argument_name => value
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [Boolean] true if successful
  def create_stochastic_schedules(args:,
                                  weather:)
    # Use independent random number generators for each class of enduse so that when certain
    # enduses are removed/added in an upgrade run, the schedules for the other enduses are not affected
    # New class of enduses can be be added to the enduse_types list at the end without loss of backwards
    # compatibility (i.e. ability to generate same schedules for existing enduses with a given seed)
    # For plug loads and lighting, the schedules are deterministically generated from occupancy schedule so separate
    # prngs are not needed for them.
    @prngs = {}
    @prngs[:main] = Random.new(@random_seed)
    seed_generator = Random.new(@random_seed)
    enduse_types = [:hygiene, :dishwasher, :clothes_washer, :clothes_dryer, :ev, :cooking]
    enduse_types.each do |key|
      @prngs[key] = Random.new(seed_generator.rand(2**32))
    end

    @num_occupants = args[:geometry_num_occupants].to_i
    @resources_path = args[:resources_path]
    # pre-load the probability distribution csv files for speed
    @default_schedules_csv_data = Defaults.get_schedules_csv_data()
    @schedules_csv_data = get_schedules_csv_data()
    @cluster_size_prob_map = read_activity_cluster_size_probs()
    @event_duration_prob_map = read_event_duration_probs()
    @activity_duration_prob_map = read_activity_duration_prob()
    @appliance_power_dist_map = read_appliance_power_dist()
    @weekday_monthly_shift_dict = read_monthly_shift_minutes(daytype: 'weekday')
    @weekend_monthly_shift_dict = read_monthly_shift_minutes(daytype: 'weekend')
    mkc_activity_schedules = simulate_occupant_activities()
    # Apply random offset to schedules to avoid synchronization when aggregating across dwelling units
    offset_range = 30 # +- 30 minutes was minimum required to avoid synchronization spikes at 1000 unit aggregation
    @random_offset = (@prngs[:main].rand * 2 * offset_range).to_i - offset_range

    # shape of mkc_activity_schedules is [n, 35040, 7] i.e. (geometry_num_occupants, period_in_a_year, number_of_states)
    @ev_occupant_number = get_ev_occupant_number(mkc_activity_schedules)
    occupancy_schedules = generate_occupancy_schedules(mkc_activity_schedules)

    # Apply random shift to occupancy schedules
    home_schedule = occupancy_schedules[:away_schedule].map { |i| (1.0 - i) }
    @schedules[SchedulesFile::Columns[:Occupants].name] = random_shift_and_normalize(home_schedule, @minutes_per_step)

    fill_plug_loads_schedule(weather, occupancy_schedules)
    fill_lighting_schedule(args, occupancy_schedules)

    # Generate schedules for each class of enduse
    sink_activity_sch = generate_sink_schedule(mkc_activity_schedules)
    shower_activity_sch, bath_activity_sch = generate_bath_shower_schedules(mkc_activity_schedules)

    if !@hpxml_bldg.dishwashers.to_a.empty?
      dw_hot_water_sch = generate_dishwasher_schedule(mkc_activity_schedules)
      dw_power_sch = generate_dishwasher_power_schedule(mkc_activity_schedules)
      @schedules[SchedulesFile::Columns[:HotWaterDishwasher].name] = random_shift_and_normalize(dw_hot_water_sch)
      @schedules[SchedulesFile::Columns[:Dishwasher].name] = random_shift_and_normalize(dw_power_sch)
    end
    if !@hpxml_bldg.clothes_washers.to_a.empty?
      cw_hot_water_sch = generate_clothes_washer_schedule(mkc_activity_schedules)
      cw_power_sch, cd_power_sch = generate_clothes_washer_dryer_power_schedules(mkc_activity_schedules)
      @schedules[SchedulesFile::Columns[:HotWaterClothesWasher].name] = random_shift_and_normalize(cw_hot_water_sch)
      @schedules[SchedulesFile::Columns[:ClothesWasher].name] = random_shift_and_normalize(cw_power_sch)

      if !@hpxml_bldg.clothes_dryers.to_a.empty?
        @schedules[SchedulesFile::Columns[:ClothesDryer].name] = random_shift_and_normalize(cd_power_sch)
      end
    end
    if !@hpxml_bldg.cooking_ranges.to_a.empty?
      cooking_power_sch = generate_cooking_power_schedule(mkc_activity_schedules)
      @schedules[SchedulesFile::Columns[:CookingRange].name] = random_shift_and_normalize(cooking_power_sch)
    end

    showers = random_shift_and_normalize(shower_activity_sch)
    sinks = random_shift_and_normalize(sink_activity_sch)
    baths = random_shift_and_normalize(bath_activity_sch)

    fixtures = [showers, sinks, baths].transpose.map(&:sum)
    @schedules[SchedulesFile::Columns[:HotWaterFixtures].name] = normalize(fixtures)

    # Apply random shift to EV occupant presence but don't normalize
    ev_occupant_presence = random_shift_and_normalize(occupancy_schedules[:ev_occupant_presence], @minutes_per_step)
    fill_ev_schedules(mkc_activity_schedules, ev_occupant_presence)

    if @debug
      @schedules[SchedulesFile::Columns[:Sleeping].name] = random_shift_and_normalize(occupancy_schedules[:sleep_schedule], @minutes_per_step)
    end
    return true
  end

  # Simulate occupant activities using Markov chain model.
  #
  # @return [Array<Matrix>] Array of matrices containing activity schedules for each occupant
  def simulate_occupant_activities
    mkc_activity_schedules = [] # holds the markov-chain state for each of the seven simulated states for each occupant.
    # States are: 'sleeping', 'shower', 'laundry', 'cooking', 'dishwashing', 'absent', 'nothingAtHome'

    occupancy_types_probabilities = Schedule.validate_values(Constants::OccupancyTypesProbabilities, 4, 'occupancy types probabilities')
    initial_probabilities = get_initial_probabilities()
    transition_matrices = get_transition_matrices()
    init_state_vector = Array.new(7, 0.0)
    activity_duration_precomputed_vals = {}
    for _n in 1..@num_occupants
      occ_type_id = weighted_random(@prngs[:main], occupancy_types_probabilities)
      simulated_values = Array.new(@total_days_in_year * @mkc_ts_per_day, 0.0)
      # create activity_duration_precomputed_vals for each active state, day_type and current occ_type_id
      fill_activity_duration_precomputed_vals(activity_duration_precomputed_vals, occ_type_id)
      @total_days_in_year.times do |day|
        today = @sim_start_day + day
        day_type = [0, 6].include?(today.wday) ? :weekend : :weekday
        j = 0
        state_prob = initial_probabilities[occ_type_id][day_type] # [] shape = 1x7. probability of transitioning to each of the 7 states
        while j < @mkc_ts_per_day
          active_state = weighted_random(@prngs[:main], state_prob) # Randomly pick the next state
          state_vector = init_state_vector.dup
          state_vector[active_state] = 1 # Transition to the new state

          # sample the duration of the state, and skip markov-chain based state transition until the end of the duration
          precomputed_vals = activity_duration_precomputed_vals[occ_type_id][day_type][active_state][j / 4]
          activity_duration = sample_activity_duration(@prngs[:main], @activity_duration_prob_map, occ_type_id, active_state, day_type, j / 4, precomputed_vals)
          fill_duration = [activity_duration, @mkc_ts_per_day - j].min
          simulated_values.fill(state_vector, day * @mkc_ts_per_day + j, fill_duration)
          j += fill_duration
          break if j >= @mkc_ts_per_day # break as soon as we have filled activities for the day

          # obtain the transition matrix for current timestep
          transition_probs = transition_matrices[occ_type_id][day_type][(j - 1) * 7..j * 7 - 1]
          state_prob = transition_probs[active_state]
        end
      end
      # Markov-chain transition probabilities is based on ATUS data, and the starting time of day for the data is
      # 4 am. We need to shift everything forward by 16 timesteps to make it midnight-based.
      simulated_values.rotate!(-4 * 4) # 4am shifting (4 hours = 4 * 4 steps of 15 min intervals)
      mkc_activity_schedules << Matrix[*simulated_values]
    end
    return mkc_activity_schedules
  end

  # Precompute activity duration values for each occupant type, day type, and activity state. This helps
  # speed up the sampling of the activity duration.
  #
  # @param activity_duration_precomputed_vals [Hash] Hash to store precomputed values
  # @param occ_type_id [Integer] Occupant type ID (0-3)
  # @return [void]
  def fill_activity_duration_precomputed_vals(activity_duration_precomputed_vals, occ_type_id)
    if not activity_duration_precomputed_vals.key?(occ_type_id)
      activity_duration_precomputed_vals[occ_type_id] = {}
      [:weekday, :weekend].each do |day_type|
        activity_duration_precomputed_vals[occ_type_id][day_type] = {}
        (0..6).each do |active_state|
          activity_duration_precomputed_vals[occ_type_id][day_type][active_state] = {}
          (0..23).each do |hour|
            activity_duration_precomputed_vals[occ_type_id][day_type][active_state][hour] = get_activity_duration_precomputed_vals(@activity_duration_prob_map, occ_type_id, active_state, day_type, hour)
          end
        end
      end
    end
  end

  # Get initial probabilities for each occupancy type and day type.
  #
  # @return [Hash] Map of occupancy type ID to weekday/weekend initial probabilities
  def get_initial_probabilities()
    initial_probabilities = {}
    weekday_file_path = "#{@resources_path}/weekday/mkv_chain_initial_prob.csv"
    weekday_data = CSV.read(weekday_file_path)
    weekend_file_path = "#{@resources_path}/weekend/mkv_chain_initial_prob.csv"
    weekend_data = CSV.read(weekend_file_path)
    # get weekday/weekend initial probabilities for 4 occupancy types
    for occ_id in 0..3
      initial_probabilities[occ_id] = {}
      initial_probabilities[occ_id][:weekday] = weekday_data.select { |x| x[0].to_i == occ_id }.map { |x| x[1].to_f }
      initial_probabilities[occ_id][:weekend] = weekend_data.select { |x| x[0].to_i == occ_id }.map { |x| x[1].to_f }
    end
    return initial_probabilities
  end

  # Get markov-chain transition matrices for each occupancy type and day type.
  #
  # @return [Hash] Map of occupancy type ID to weekday/weekend transition matrices
  def get_transition_matrices()
    transition_matrices = {}
    weekday_file_path = "#{@resources_path}/weekday/mkv_chain_transition_prob.csv"
    weekday_data = CSV.read(weekday_file_path)
    weekend_file_path = "#{@resources_path}/weekend/mkv_chain_transition_prob.csv"
    weekend_data = CSV.read(weekend_file_path)
    # get weekday/weekend transition matrices for 4 occupancy types
    for occ_id in 0..3
      transition_matrices[occ_id] = {}
      transition_matrices[occ_id][:weekday] = weekday_data.select { |x| x[0].to_i == occ_id }.map { |x| x[1..-1].map { |y| y.to_f } }
      transition_matrices[occ_id][:weekend] = weekend_data.select { |x| x[0].to_i == occ_id }.map { |x| x[1..-1].map { |y| y.to_f } }
    end
    return transition_matrices
  end

  # Aggregate array values by summing groups of elements.
  #
  # @param array [Array] Array of values to aggregate
  # @param group_size [Integer] Number of consecutive elements to sum together
  # @return [Array] New array with values aggregated by group_size
  def aggregate_array(array, group_size)
    new_array_size = array.size / group_size
    new_array = [0] * new_array_size
    new_array_size.times do |j|
      new_array[j] = array[(j * group_size)..(j + 1) * group_size - 1].sum(0)
    end
    return new_array
  end

  # Apply monthly schedule shifts based on weekday/weekend patterns. This is done to bring the schedules into alignment
  # with observed monthly and weekday/weekend patterns at national level since our mkc doesn't model monthly patterns.
  #
  # @param array [Array] Array of minute-level schedule values to shift
  # @param weekday_monthly_shift_dict [Hash] Map of month name to number of minutes to shift weekday schedules
  # @param weekend_monthly_shift_dict [Hash] Map of month name to number of minutes to shift weekend schedules
  # @return [Array] New array with values shifted according to monthly patterns
  def apply_monthly_offsets(array:, weekday_monthly_shift_dict:, weekend_monthly_shift_dict:)
    month_strs = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'July', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    new_array = []
    @total_days_in_year.times do |day|
      today = @sim_start_day + day
      day_of_week = today.wday
      month = month_strs[today.month - 1]
      if [0, 6].include?(day_of_week)
        # Weekend
        lead = weekend_monthly_shift_dict[month]
      else
        # weekday
        lead = weekday_monthly_shift_dict[month]
      end
      if lead.nil?
        raise "Could not find the entry for month #{month}, day #{day_of_week} and state #{@state}"
      end

      new_array.concat(array[day * @minutes_per_day, @minutes_per_day].rotate(lead))
    end
    return new_array
  end

  # Read monthly schedule shift minutes from CSV file for a given state and day type.
  #
  # @param daytype [String] Type of day ('weekday' or 'weekend') to get shifts for
  # @return [Hash] Map of month name to number of minutes to shift schedules
  def read_monthly_shift_minutes(daytype:)
    shift_file = @resources_path + "/#{daytype}/state_and_monthly_schedule_shift.csv"
    shifts = CSV.read(shift_file)
    state_index = shifts[0].find_index('State')
    lead_index = shifts[0].find_index('Lead')
    month_index = shifts[0].find_index('Month')
    state_shifts = shifts.select { |row| row[state_index] == @state }
    monthly_shifts_dict = Hash[state_shifts.map { |row| [row[month_index], row[lead_index].to_i] }]
    return monthly_shifts_dict
  end

  # Read appliance power distribution data from CSV files.
  #
  # @return [Hash] Map of appliance name to array containing duration and consumption distributions
  def read_appliance_power_dist()
    activity_names = ['clothes_washer', 'dishwasher', 'clothes_dryer', 'cooking']
    power_dist_map = {}
    activity_names.each do |activity|
      duration_file = @resources_path + "/#{activity}_duration_dist.csv"
      consumption_file = @resources_path + "/#{activity}_consumption_dist.csv"
      duration_vals = CSV.read(duration_file)
      consumption_vals = CSV.read(consumption_file)
      duration_vals = duration_vals.map { |a| a.map { |i| i.to_i } }
      consumption_vals = consumption_vals.map { |a| a[0].to_f }
      power_dist_map[activity] = [duration_vals, consumption_vals]
    end
    return power_dist_map
  end

  # Sample the duration and power consumption for an appliance event.
  #
  # @param prng [Random] Random number generator to use for sampling
  # @param power_dist_map [Hash] Map of appliance name to array containing duration and consumption distributions
  # @param appliance_name [String] Name of the appliance to sample duration and power for
  # @return [Array<Integer, Float>] Array containing [duration in 15-min intervals, average power in watts]
  def sample_appliance_duration_power(prng, power_dist_map, appliance_name)
    # returns number number of 15-min interval the appliance runs, and the average 15-min power
    duration_vals, consumption_vals = power_dist_map[appliance_name]
    if @consumption_row.nil?
      # initialize and pick the consumption and duration row only the first time
      # checking only consumption_row is sufficient because duration_row always go side by side with consumption row
      @consumption_row = {}
      @duration_row = {}
    end
    if !@consumption_row.has_key?(appliance_name)
      @consumption_row[appliance_name] = (prng.rand * consumption_vals.size).to_i
      @duration_row[appliance_name] = (prng.rand * duration_vals.size).to_i
    end
    power = consumption_vals[@consumption_row[appliance_name]]
    sample = prng.rand(0..(duration_vals[@duration_row[appliance_name]].length - 1))
    duration = duration_vals[@duration_row[appliance_name]][sample]
    return [duration, power]
  end

  # Read activity cluster size probability distributions from CSV files.
  #
  # @return [Hash] Map of activity name to array containing cluster size probabilities
  def read_activity_cluster_size_probs
    activity_names = ['hot_water_clothes_washer', 'hot_water_dishwasher', 'shower']
    cluster_size_prob_map = {}
    activity_names.each do |activity|
      cluster_size_file = @resources_path + "/#{activity}_cluster_size_probability.csv"
      cluster_size_probabilities = CSV.read(cluster_size_file)
      cluster_size_probabilities = cluster_size_probabilities.map { |entry| entry[0].to_f }
      cluster_size_prob_map[activity] = cluster_size_probabilities
    end
    return cluster_size_prob_map
  end

  # Read event duration probability distributions from CSV files.
  #
  # @return [Hash] Map of activity name to array containing durations and probabilities
  def read_event_duration_probs()
    activity_names = ['hot_water_clothes_washer', 'hot_water_dishwasher', 'shower']
    event_duration_probabilites_map = {}
    activity_names.each do |activity|
      duration_file = @resources_path + "/#{activity}_event_duration_probability.csv"
      duration_probabilities = CSV.read(duration_file)
      durations = duration_probabilities.map { |entry| entry[0].to_f / 60 } # convert to minute
      probabilities = duration_probabilities.map { |entry| entry[1].to_f }
      event_duration_probabilites_map[activity] = [durations, probabilities]
    end
    return event_duration_probabilites_map
  end

  # Read activity duration probability distributions from CSV files.
  #
  # @return [Hash] Map of activity name to array containing durations and probabilities
  def read_activity_duration_prob()
    cluster_types = ['0', '1', '2', '3']
    day_types = ['weekday', 'weekend']
    time_of_days = ['morning', 'midday', 'evening']
    activity_names = ['shower', 'cooking', 'dishwashing', 'laundry']
    activity_duration_prob_map = {}
    day_types.each do |day_type|
      time_of_days.each do |time_of_day|
        activity_names.each do |activity_name|
          duration_file = @resources_path + "/#{day_type}/duration_probability/#{activity_name}_#{time_of_day}_duration_probability.csv"
          duration_probabilities = CSV.read(duration_file)
          cluster_types.each do |cluster_type|
            cluster_type_duration_probabilities = duration_probabilities.select { |entry| entry[0] == cluster_type }
            durations = cluster_type_duration_probabilities.map { |entry| entry[1].to_i }
            probabilities = cluster_type_duration_probabilities.map { |entry| entry[2].to_f }
            activity_duration_prob_map["#{cluster_type}_#{activity_name}_#{day_type}_#{time_of_day}"] = [durations, probabilities]
          end
        end
      end
    end
    return activity_duration_prob_map
  end

  # Precompute values for sample_activity_cluster_size to speed up the sampling.
  #
  # @param cluster_size_prob_map [Hash] Map of activity name to array of probabilities for different cluster sizes
  # @param activity_type_name [String] Name of the activity type to precompute values for
  # @return [Array] Precomputed values for weighted random sampling
  def get_activity_cluster_size_precomputed_vals(cluster_size_prob_map, activity_type_name)
    cluster_size_probabilities = cluster_size_prob_map[activity_type_name]
    return weighted_random_precompute(cluster_size_probabilities)
  end

  # Sample the number of events in a cluster for a given activity type.
  #
  # @param cluster_size_prob_map [Hash] Map of activity name to array of probabilities for different cluster sizes
  # @param activity_type_name [String] Name of the activity type to sample cluster size for
  # @param precomputed_vals [Array] Precomputed values for weighted random sampling
  # @return [Integer] Number of events in the cluster (1-based)
  def sample_activity_cluster_size(prng, cluster_size_prob_map, activity_type_name, precomputed_vals = nil)
    cluster_size_probabilities = cluster_size_prob_map[activity_type_name]
    return weighted_random(prng, cluster_size_probabilities, precomputed_vals) + 1
  end

  # Precompute values for sample_event_duration to speed up the sampling.
  #
  # @param duration_probabilites_map [Hash] Map of event type to array containing durations and probabilities
  # @param event_type [String] Type of event to precompute values for
  # @return [Array] Precomputed values for weighted random sampling
  def get_event_duration_precomputed_vals(duration_probabilites_map, event_type)
    return weighted_random_precompute(duration_probabilites_map[event_type][1])
  end

  # Sample a duration for a given event type based on its probability distribution.
  #
  # @param duration_probabilites_map [Hash] Map of event type to array containing durations and probabilities
  # @param event_type [String] Type of event to sample duration for (e.g. 'hot_water_clothes_washer')
  # @param precomputed_vals [Array] Precomputed values for weighted random sampling
  # @return [Float] Duration in minutes for the sampled event
  def sample_event_duration(prng, duration_probabilites_map, event_type, precomputed_vals = nil)
    durations = duration_probabilites_map[event_type][0]
    probabilities = duration_probabilites_map[event_type][1]
    return durations[weighted_random(prng, probabilities, precomputed_vals)]
  end

  # Precompute values for sample_activity_duration to speed up the sampling.
  #
  # @param activity_duration_prob_map [Hash] Map of activity parameters to arrays containing durations and probabilities
  # @param occ_type_id [String] Occupant type ID (cluster type)
  # @param activity [Integer] Activity state number (1=shower, 2=laundry, 3=cooking, 4=dishwashing)
  # @param day_type [String] Type of day ('weekday' or 'weekend')
  # @param hour [Integer] Hour of the day (0-23)
  def get_activity_duration_precomputed_vals(activity_duration_prob_map, occ_type_id, activity, day_type, hour)
    time_of_day = hour < 8 ? 'morning' : hour < 16 ? 'midday' : 'evening'
    if activity == 1
      activity_name = 'shower'
    elsif activity == 2
      activity_name = 'laundry'
    elsif activity == 3
      activity_name = 'cooking'
    elsif activity == 4
      activity_name = 'dishwashing'
    else
      return # precomputed value not needed since sample_activity_duration will return 1 in this case
    end
    return weighted_random_precompute(activity_duration_prob_map["#{occ_type_id}_#{activity_name}_#{day_type}_#{time_of_day}"][1])
  end

  # Sample a duration for an activity based on occupant type, activity type, day type and hour.
  #
  # @param activity_duration_prob_map [Hash] Map of activity parameters to arrays containing durations and probabilities
  # @param occ_type_id [String] Occupant type ID (cluster type)
  # @param activity [Integer] Activity state number (1=shower, 2=laundry, 3=cooking, 4=dishwashing)
  # @param day_type [String] Type of day ('weekday' or 'weekend')
  # @param hour [Integer] Hour of the day (0-23)
  # @param precomputed_vals [Array] Precomputed values for weighted random sampling
  # @return [Integer] Duration in minutes for the sampled activity
  def sample_activity_duration(prng, activity_duration_prob_map, occ_type_id, activity, day_type, hour, precomputed_vals = nil)
    # States are: 'sleeping', 'shower', 'laundry', 'cooking', 'dishwashing', 'absent', 'nothingAtHome'
    if hour < 8
      time_of_day = 'morning'
    elsif hour < 16
      time_of_day = 'midday'
    else
      time_of_day = 'evening'
    end

    if activity == 1
      activity_name = 'shower'
    elsif activity == 2
      activity_name = 'laundry'
    elsif activity == 3
      activity_name = 'cooking'
    elsif activity == 4
      activity_name = 'dishwashing'
    else
      return 1 # all other activity will span only one mkc step
    end
    durations = activity_duration_prob_map["#{occ_type_id}_#{activity_name}_#{day_type}_#{time_of_day}"][0]
    probabilities = activity_duration_prob_map["#{occ_type_id}_#{activity_name}_#{day_type}_#{time_of_day}"][1]
    return durations[weighted_random(prng, probabilities, precomputed_vals)]
  end

  # Generate a random number from a Gaussian (normal) distribution with the given parameters.
  #
  # @param prng [Random] Random number generator to use
  # @param mean [Float] The mean (average) value of the distribution
  # @param std [Float] The standard deviation of the distribution
  # @param min [Float, nil] The minimum allowed value (defaults to 0.1)
  # @param max [Float, nil] The maximum allowed value (optional)
  # @return [Float] A random number drawn from the specified Gaussian distribution, clipped to min/max if specified
  def gaussian_rand(prng, mean, std, min = 0.1, max = nil)
    t = 2 * Math::PI * prng.rand
    r = Math.sqrt(-2 * Math.log(1 - prng.rand))
    scale = std * r
    x = mean + scale * Math.cos(t)
    if (not min.nil?) && (x < min) then x = min end
    if (not max.nil?) && (x > max) then x = max end
    # y = mean + scale * Math.sin(t)
    return x
  end

  # Sum the activity state values across all occupants at a given time index.
  #
  # @param mkc_activity_schedules [Array<Matrix>] Array of matrices containing Markov chain activity states for each occupant
  # @param activity_index [Integer] Index of the activity state to sum (0=sleeping, 1=shower, etc)
  # @param time_index [Integer] Time index to sum the activity state values at
  # @param max_clip [Integer, nil] Optional maximum value to clip the sum to
  # @return [Integer] Sum of the activity state values across occupants, clipped to max_clip if specified
  def sum_across_occupants(mkc_activity_schedules, activity_index, time_index, max_clip: nil)
    sum = 0
    mkc_activity_schedules.size.times do |i|
      sum += mkc_activity_schedules[i][time_index, activity_index]
    end
    if (not max_clip.nil?) && (sum > max_clip)
      sum = max_clip
    end
    return sum
  end

  # Determines which occupant will be assigned as the EV driver based on their away hours.
  #
  # @param mkc_activity_schedules [Array<Matrix>] Array of matrices containing Markov chain activity states for each occupant
  # @return [Integer] Index of the occupant assigned as EV driver (0-based)
  def get_ev_occupant_number(mkc_activity_schedules)
    if @hpxml_bldg.vehicles.to_a.empty?
      return 0
    end

    vehicle = @hpxml_bldg.vehicles[0]
    hours_per_year = (vehicle.hours_per_week / 7) * UnitConversions.convert(1, 'yr', 'day')

    occupant_away_hours_per_year = []
    mkc_activity_schedules.size.times do |i|
      occupant_away_hours_per_year[i] = mkc_activity_schedules[i].column(5).sum() / 4
    end
    # Only keep occupants whose 80% (the portion available for driving) away hours are sufficient to meet hours_per_year
    elligible_occupant = occupant_away_hours_per_year.each_with_index.filter { |value, _| value * 0.8 > hours_per_year }
    if elligible_occupant.empty?
      # if nobody has enough away hours, find the index of the occupant with the highest away hours
      _, ev_occupant = occupant_away_hours_per_year.each_with_index.max_by { |value, _| value }
      return ev_occupant
    else
      # return the index of a random eligible occupant
      _, ev_occupant = elligible_occupant.sample(random: @prngs[:ev])
      return ev_occupant
    end
  end

  # Normalize an array by dividing all values by the maximum value.
  #
  # @param arr [Array] Array of numeric values to normalize
  # @param max_val [Float, nil] Maximum value to normalize to. If nil, use the maximum value in the schedule.
  # @return [Array] Array with values normalized to between 0 and 1
  def normalize(arr, max_val = nil)
    if max_val.nil?
      m = arr.max.to_f
    else
      m = max_val.to_f
    end
    arr = arr.map { |a| a / m }
    return arr
  end

  # Scale lighting schedule values based on occupancy.
  #
  # @param sch [Array] Array of hourly lighting schedule values
  # @param minute [Integer] Current minute in simulation
  # @param active_occupant_percentage [Float] Percentage of occupants that are active (not sleeping/away)
  # @return [Float] Scaled lighting schedule value based on occupancy
  def scale_lighting_by_occupancy(sch, minute, active_occupant_percentage)
    day_start = minute / @minutes_per_day
    day_sch = sch[day_start * 24, 24]
    current_val = sch[minute / 60]
    return day_sch.min + (current_val - day_sch.min) * active_occupant_percentage
  end

  # Precompute the cumulative weights for a given array of weights for speeding up weighted random sampling.
  #
  # @param weights [Array<Float>] Array of probability weights that sum to 1
  # @return [Array<Float>] Array of cumulative weights
  def weighted_random_precompute(weights)
    sum = 0
    return weights.map { |w| sum += w }
  end

  # Randomly select an index based on weighted probabilities.
  #
  # @param prng [Random] Random number generator
  # @param weights [Array<Float>] Array of probability weights that sum to 1
  # @param precomputed_vals [Array<Float>, nil] Precomputed values for faster sampling
  # @return [Integer] Randomly selected index based on probability weights
  def weighted_random(prng, weights, precomputed_vals = nil)
    n = prng.rand
    if precomputed_vals.nil?
      # this is faster than calling weighted_random_precompute and doing bsearch_index
      cum_weight = 0.0
      weights.size.times do |i|
        cum_weight += weights[i]
        return i if cum_weight >= n
      end
      return weights.size - 1
    else
      cum_weights = precomputed_vals
    end
    index = cum_weights.bsearch_index { |w| w >= n }
    return index || (weights.size - 1)
  end

  # Get the Building America lighting schedule based on location and time zone.
  #
  # @param time_zone_utc_offset [Integer] Offset from UTC in hours
  # @param latitude [Float] Latitude in degrees
  # @param longitude [Float] Longitude in degrees
  # @return [Array] Array of hourly lighting schedule values
  def get_building_america_lighting_schedule(time_zone_utc_offset, latitude, longitude)
    # Sunrise and sunset hours
    sunrise_hour = []
    sunset_hour = []
    std_long = -time_zone_utc_offset * 15
    normalized_hourly_lighting = [[1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24], [1..24]]
    for month in 0..11
      if latitude < 51.49
        m_num = month + 1
        jul_day = m_num * 30 - 15
        if not ((m_num < 4) || (m_num > 10))
          offset = 1
        else
          offset = 0
        end
        declination = 23.45 * Math.sin(0.9863 * (284 + jul_day) * 0.01745329)
        deg_rad = Math::PI / 180
        rad_deg = 1 / deg_rad
        b = (jul_day - 1) * 0.9863
        equation_of_time = (0.01667 * (0.01719 + 0.42815 * Math.cos(deg_rad * b) - 7.35205 * Math.sin(deg_rad * b) - 3.34976 * Math.cos(deg_rad * (2 * b)) - 9.37199 * Math.sin(deg_rad * (2 * b))))
        sunset_hour_angle = rad_deg * Math.acos(-1 * Math.tan(deg_rad * latitude) * Math.tan(deg_rad * declination))
        sunrise_hour[month] = offset + (12.0 - 1 * sunset_hour_angle / 15.0) - equation_of_time - (std_long + longitude) / 15
        sunset_hour[month] = offset + (12.0 + 1 * sunset_hour_angle / 15.0) - equation_of_time - (std_long + longitude) / 15
      else
        sunrise_hour = [8.125726064, 7.449258072, 6.388688653, 6.232405257, 5.27722936, 4.84705384, 5.127512162, 5.860163988, 6.684378904, 7.521267411, 7.390441945, 8.080667697]
        sunset_hour = [16.22214058, 17.08642353, 17.98324493, 19.83547864, 20.65149672, 21.20662992, 21.12124777, 20.37458274, 19.25834757, 18.08155615, 16.14359164, 15.75571306]
      end
    end

    june_kws = [0.060, 0.040, 0.035, 0.025, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.020, 0.025, 0.030, 0.030, 0.025, 0.020, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.020, 0.020, 0.020, 0.025, 0.025, 0.030, 0.030, 0.035, 0.045, 0.060, 0.085, 0.125, 0.145, 0.130, 0.105, 0.080]
    lighting_seasonal_multiplier = @schedules_csv_data[SchedulesFile::Columns[:LightingInterior].name]['LightingInteriorMonthlyMultipliers'].split(',').map { |v| v.to_f }
    amplConst1 = 0.929707907917098
    sunsetLag1 = 2.45016230615269
    stdDevCons1 = 1.58679810983444
    amplConst2 = 1.1372291802273
    sunsetLag2 = 20.1501965859073
    stdDevCons2 = 2.36567663279954

    monthly_kwh_per_day = []
    days_m = Calendar.num_days_in_months(1999) # Intentionally excluding leap year designation
    wtd_avg_monthly_kwh_per_day = 0
    for monthNum in 1..12
      month = monthNum - 1
      monthHalfHourKWHs = [0]
      for hourNum in 0..9
        monthHalfHourKWHs[hourNum] = june_kws[hourNum]
      end
      for hourNum in 9..17
        hour = (hourNum + 1.0) * 0.5
        monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[8] - (0.15 / (2 * Math::PI)) * Math.sin((2 * Math::PI) * (hour - 4.5) / 3.5) + (0.15 / 3.5) * (hour - 4.5)) * lighting_seasonal_multiplier[month]
      end
      for hourNum in 17..29
        hour = (hourNum + 1.0) * 0.5
        monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[16] - (-0.02 / (2 * Math::PI)) * Math.sin((2 * Math::PI) * (hour - 8.5) / 5.5) + (-0.02 / 5.5) * (hour - 8.5)) * lighting_seasonal_multiplier[month]
      end
      for hourNum in 29..45
        hour = (hourNum + 1.0) * 0.5
        monthHalfHourKWHs[hourNum] = (monthHalfHourKWHs[28] + amplConst1 * Math.exp((-1.0 * (hour - (sunset_hour[month] + sunsetLag1))**2) / (2.0 * ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1)**2)) / ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1 * (2.0 * Math::PI)**0.5))
      end
      for hourNum in 45..46
        hour = (hourNum + 1.0) * 0.5
        temp1 = (monthHalfHourKWHs[44] + amplConst1 * Math.exp((-1.0 * (hour - (sunset_hour[month] + sunsetLag1))**2) / (2.0 * ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1)**2)) / ((25.5 / ((6.5 - monthNum).abs + 20.0)) * stdDevCons1 * (2.0 * Math::PI)**0.5))
        temp2 = (0.04 + amplConst2 * Math.exp((-1.0 * (hour - sunsetLag2)**2) / (2.0 * stdDevCons2**2)) / (stdDevCons2 * (2.0 * Math::PI)**0.5))
        if sunsetLag2 < sunset_hour[month] + sunsetLag1
          monthHalfHourKWHs[hourNum] = [temp1, temp2].min
        else
          monthHalfHourKWHs[hourNum] = [temp1, temp2].max
        end
      end
      for hourNum in 46..47
        hour = (hourNum + 1) * 0.5
        monthHalfHourKWHs[hourNum] = (0.04 + amplConst2 * Math.exp((-1.0 * (hour - sunsetLag2)**2) / (2.0 * stdDevCons2**2)) / (stdDevCons2 * (2.0 * Math::PI)**0.5))
      end

      sum_kWh = 0.0
      for timenum in 0..47
        sum_kWh += monthHalfHourKWHs[timenum]
      end
      for hour in 0..23
        ltg_hour = (monthHalfHourKWHs[hour * 2] + monthHalfHourKWHs[hour * 2 + 1]).to_f
        normalized_hourly_lighting[month][hour] = ltg_hour / sum_kWh
        monthly_kwh_per_day[month] = sum_kWh / 2.0
      end
      wtd_avg_monthly_kwh_per_day += monthly_kwh_per_day[month] * days_m[month] / 365.0
    end

    # Calculate normalized monthly lighting fractions
    seasonal_multiplier = []
    sumproduct_seasonal_multiplier = 0
    normalized_monthly_lighting = seasonal_multiplier
    for month in 0..11
      seasonal_multiplier[month] = (monthly_kwh_per_day[month] / wtd_avg_monthly_kwh_per_day)
      sumproduct_seasonal_multiplier += seasonal_multiplier[month] * days_m[month]
    end

    for month in 0..11
      normalized_monthly_lighting[month] = seasonal_multiplier[month] * days_m[month] / sumproduct_seasonal_multiplier
    end

    # Calculate schedule values
    lighting_sch = [[], [], [], [], [], [], [], [], [], [], [], []]
    for month in 0..11
      for hour in 0..23
        lighting_sch[month][hour] = normalized_monthly_lighting[month] * normalized_hourly_lighting[month][hour] / days_m[month]
      end
    end

    return lighting_sch
  end

  # Generates EV battery charging and discharging schedules based on away schedule and annual driving hours.
  #
  # @param away_schedule [Array<Integer>] Array of 0s and 1s indicating when occupants are away (1) or home (0)
  # @param hours_driven_per_year [Float] Number of hours the EV is driven per year
  # @return [Array<Array<Integer>>] Two arrays - [charging_schedule, discharging_schedule], each containing 0s and 1s
  def get_ev_battery_schedule(away_schedule, hours_driven_per_year)
    total_driving_minutes_per_year = (hours_driven_per_year * 60).ceil
    expanded_away_schedule = away_schedule.flat_map { |status| [status] * 15 }
    charging_schedule = []
    discharging_schedule = []
    driving_minutes_used = 0
    chunk_counts = expanded_away_schedule.chunk(&:itself).map { |value, elements| [value, elements.size] }
    total_away_minutes = chunk_counts.map { |value, size| value * size }.sum
    extra_drive_minutes = 0 # accumulator for keeping track of extra driving minutes used due to ceil to upper integer
    chunk_counts.each do |is_away, activity_minutes|
      if is_away == 1
        current_chunk_proportion = (1.0 * activity_minutes) / total_away_minutes

        expected_driving_time = (total_driving_minutes_per_year * current_chunk_proportion - extra_drive_minutes).ceil
        max_driving_time = [expected_driving_time, total_driving_minutes_per_year - driving_minutes_used].min

        max_possible_driving_time = (activity_minutes * 0.8).ceil
        actual_driving_time = [max_driving_time, max_possible_driving_time].min
        extra_drive_minutes += actual_driving_time - total_driving_minutes_per_year * current_chunk_proportion

        idle_time = activity_minutes - actual_driving_time
        first_half_driving = (actual_driving_time / 2.0).ceil
        second_half_driving = actual_driving_time - first_half_driving

        discharging_schedule.concat([1] * first_half_driving)  # Start driving
        discharging_schedule.concat([0] * idle_time)           # Idle in the middle
        discharging_schedule.concat([1] * second_half_driving) # End driving
        charging_schedule.concat([0] * activity_minutes)

        driving_minutes_used += actual_driving_time
      else
        charging_schedule.concat([1] * activity_minutes)
        discharging_schedule.concat([0] * activity_minutes)
      end
    end
    if driving_minutes_used < total_driving_minutes_per_year
      msg = "Insufficient away minutes (#{total_away_minutes}) for required driving minutes (#{hours_driven_per_year * 60})"
      msg += "Only #{driving_minutes_used} minutes was used."
      @runner.registerWarning(msg)
    end

    return charging_schedule, discharging_schedule
  end

  # Fill EV battery charging and discharging schedules based on Markov chain simulation results
  #
  # @param markov_chain_simulation_result [Array<Matrix>] Array of matrices containing Markov chain simulation results for each occupant
  # @return [nil] Updates @schedules with EV battery charging and discharging schedules
  def fill_ev_schedules(markov_chain_simulation_result, ev_occupant_presence)
    if @hpxml_bldg.vehicles.to_a.empty?
      return
    end

    vehicle = @hpxml_bldg.vehicles[0]
    hours_per_year = (vehicle.hours_per_week / 7) * UnitConversions.convert(1, 'yr', 'day')
    away_index = 5 # Index of away activity in the markov-chain simulator
    away_schedule = markov_chain_simulation_result[@ev_occupant_number].column(away_index)
    charging_schedule, discharging_schedule = get_ev_battery_schedule(away_schedule, hours_per_year)
    agg_charging_schedule = random_shift_and_normalize(charging_schedule, @minutes_per_step)
    agg_discharging_schedule = random_shift_and_normalize(discharging_schedule, @minutes_per_step)

    # The combined schedule is not a sum of the charging and discharging schedules because when charging and discharging
    # both occur in a timestep, we don't want them to cancel out and draw no power from the building. So, whenever there
    # is discharging, we use the full discharge in that timestep (without subtracting the charging).
    combined_schedule = agg_charging_schedule.zip(agg_discharging_schedule).map { |charging, discharging| discharging > 0 ? -discharging : charging }
    @schedules[SchedulesFile::Columns[:EVOccupant].name] = ev_occupant_presence if @debug
    @schedules[SchedulesFile::Columns[:ElectricVehicle].name] = combined_schedule
  end

  # Get the weekday/weekend schedule fractions for TV plug loads and monthly multipliers for interior lighting, dishwasher, clothes washer/dryer, cooking range, and other/TV plug loads.
  #
  # @return [Hash] { schedule_name => { element => values, ... }, ... }
  def get_schedules_csv_data()
    schedules_csv = File.join(File.dirname(__FILE__), 'schedules.csv')
    if not File.exist?(schedules_csv)
      fail 'Could not find schedules.csv'
    end

    require 'csv'
    schedules_csv_data = {}
    CSV.foreach(schedules_csv, headers: true) do |row|
      schedule_name = row['Schedule Name']
      element = row['Element']
      values = row['Values']

      schedules_csv_data[schedule_name] = {} if !schedules_csv_data.keys.include?(schedule_name)
      schedules_csv_data[schedule_name][element] = values
    end

    return schedules_csv_data
  end

  # Initialize daily schedule data for plug loads, TV usage, and ceiling fans.
  #
  # @param default_schedules_csv_data [Hash] Default schedule data from CSV
  # @param schedules_csv_data [Hash] Custom schedule data from CSV
  # @param weather [WeatherFile] Weather object containing temperature data
  # @return [Hash] Map of schedule types to their weekday, weekend, and monthly values
  def get_plugload_daily_schedules(default_schedules_csv_data, schedules_csv_data, weather)
    {
      plug_loads_other: {
        # Table C.3(1) of ANSI/RESNET/ICC 301-2022 Addendum C
        weekday: Schedule.validate_values(default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsOther].name]['WeekdayScheduleFractions'], 24, 'weekday'),
        weekend: Schedule.validate_values(default_schedules_csv_data[SchedulesFile::Columns[:PlugLoadsOther].name]['WeekendScheduleFractions'], 24, 'weekend'),
        # Figure 24 of the 2010 BAHSP
        monthly: Schedule.validate_values(schedules_csv_data[SchedulesFile::Columns[:PlugLoadsOther].name]['PlugLoadsOtherMonthlyMultipliers'], 12, 'monthly')
      },
      plug_loads_tv: {
        # American Time Use Survey
        weekday: Schedule.validate_values(schedules_csv_data[SchedulesFile::Columns[:PlugLoadsTV].name]['PlugLoadsTVWeekdayFractions'], 24, 'weekday'),
        weekend: Schedule.validate_values(schedules_csv_data[SchedulesFile::Columns[:PlugLoadsTV].name]['PlugLoadsTVWeekendFractions'], 24, 'weekend'),
        monthly: Schedule.validate_values(schedules_csv_data[SchedulesFile::Columns[:PlugLoadsTV].name]['PlugLoadsTVMonthlyMultipliers'], 12, 'monthly')
      },
      ceiling_fan: {
        # Table C.3(5) of ANSI/RESNET/ICC 301-2022 Addendum C
        weekday: Schedule.validate_values(default_schedules_csv_data[SchedulesFile::Columns[:CeilingFan].name]['WeekdayScheduleFractions'], 24, 'weekday'),
        weekend: Schedule.validate_values(default_schedules_csv_data[SchedulesFile::Columns[:CeilingFan].name]['WeekendScheduleFractions'], 24, 'weekend'),
        # Based on monthly average outdoor temperatures per ANSI/RESNET/ICC 301
        monthly: Schedule.validate_values(Defaults.get_ceiling_fan_months(weather).join(', '), 12, 'monthly')
      }
    }
  end

  # Initialize the interior lighting schedule based on location parameters.
  #
  # @param args [Hash] Hash containing required parameters:
  # @option args [Integer] :time_zone_utc_offset Offset from UTC in hours
  # @option args [Float] :latitude Latitude in degrees
  # @option args [Float] :longitude Longitude in degrees
  # @return [Array<Float>] Array of hourly lighting schedule values normalized to 1.0
  def initialize_interior_lighting_schedule(args)
    sch = get_building_america_lighting_schedule(args[:time_zone_utc_offset], args[:latitude], args[:longitude])
    interior_lighting_schedule = []
    num_days_in_months = Calendar.num_days_in_months(@sim_year)

    for month in 0..11
      interior_lighting_schedule << sch[month] * num_days_in_months[month]
    end

    interior_lighting_schedule.flatten!
    return normalize(interior_lighting_schedule)
  end

  # Generate occupancy schedules for sleeping, away, idle, EV presence and total occupancy.
  #
  # @param mkc_activity_schedules [Array<Matrix>] Array of matrices containing Markov chain activity states for each occupant
  # @return [Hash] Hash containing arrays for sleep_schedule, away_schedule, idle_schedule, ev_occupant_presence
  def generate_occupancy_schedules(mkc_activity_schedules)
    # States are: 0='sleeping', 1='shower', 2='laundry', 3='cooking', 4='dishwashing', 5='absent', 6='nothingAtHome'
    occupancy_arrays = {
      sleep_schedule: Array.new(@total_days_in_year * @minutes_per_day, 0.0),
      away_schedule: Array.new(@total_days_in_year * @minutes_per_day, 0.0),
      idle_schedule: Array.new(@total_days_in_year * @minutes_per_day, 0.0),
      ev_occupant_presence: Array.new(@total_days_in_year * @minutes_per_day, 0.0),
    }
    @total_days_in_year.times do |day|
      @mkc_ts_per_day.times do |step|
        minute = day * @minutes_per_day + step * @minutes_per_mkc_ts
        index_15 = (minute / 15).to_i
        occupancy_arrays[:sleep_schedule].fill(sum_across_occupants(mkc_activity_schedules, 0, index_15).to_f / @num_occupants, minute, @minutes_per_mkc_ts)
        occupancy_arrays[:away_schedule].fill(sum_across_occupants(mkc_activity_schedules, 5, index_15).to_f / @num_occupants, minute, @minutes_per_mkc_ts)
        occupancy_arrays[:idle_schedule].fill(sum_across_occupants(mkc_activity_schedules, 6, index_15).to_f / @num_occupants, minute, @minutes_per_mkc_ts)
        occupancy_arrays[:ev_occupant_presence].fill(1 - mkc_activity_schedules[@ev_occupant_number][index_15, 5], minute, @minutes_per_mkc_ts)
      end
    end
    return occupancy_arrays
  end

  # Fill plug loads and ceiling fan schedules based on occupant activities.
  #
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param occupancy_schedules [Hash] Hash returned by generate_occupancy_schedules
  # @return [void] Updates @schedules with plug loads and ceiling fan schedules
  def fill_plug_loads_schedule(weather, occupancy_schedules)
    # Initialize base schedules
    daily_schedules = get_plugload_daily_schedules(@default_schedules_csv_data, @schedules_csv_data, weather)

    # Generate schedules for each plug load type if it exists
    if @hpxml_bldg.plug_loads.find { |p| p.plug_load_type == 'other' }
      plug_loads_other = generate_plug_load_schedule(daily_schedules, :plug_loads_other, occupancy_schedules)
      @schedules[SchedulesFile::Columns[:PlugLoadsOther].name] = random_shift_and_normalize(plug_loads_other)
    end

    if @hpxml_bldg.plug_loads.find { |p| p.plug_load_type == 'TV other' }
      plug_loads_tv = generate_plug_load_schedule(daily_schedules, :plug_loads_tv, occupancy_schedules)
      @schedules[SchedulesFile::Columns[:PlugLoadsTV].name] = random_shift_and_normalize(plug_loads_tv)
    end
    if !@hpxml_bldg.ceiling_fans.to_a.empty?
      ceiling_fan = generate_plug_load_schedule(daily_schedules, :ceiling_fan, occupancy_schedules)
      @schedules[SchedulesFile::Columns[:CeilingFan].name] = random_shift_and_normalize(ceiling_fan)
    end
  end

  # Generate plug load schedules based on occupant activities and daily schedules.
  #
  # @param daily_schedules [Hash] Hash containing daily schedule data for plug loads
  # @param schedule_type [Symbol] Type of plug load schedule to generate
  # @param occupancy_schedules [Hash] Hash returned by generate_occupancy_schedules
  # @return [Array<Float>] Array of hourly plug load schedule values normalized to 1.0
  def generate_plug_load_schedule(daily_schedules, schedule_type, occupancy_schedules)
    schedule = Array.new(@total_days_in_year * @minutes_per_day, 0.0)
    weekday_min = daily_schedules[schedule_type][:weekday].min
    weekend_min = daily_schedules[schedule_type][:weekend].min
    @total_days_in_year.times do |day|
      today = @sim_start_day + day
      month = today.month
      monthly_multiplier = daily_schedules[schedule_type][:monthly][month - 1].to_f
      if [0, 6].include?(today.wday)
        sch = daily_schedules[schedule_type][:weekend]
        sch_min = weekend_min
      else
        sch = daily_schedules[schedule_type][:weekday]
        sch_min = weekday_min
      end
      @mkc_ts_per_day.times do |step|
        minute = day * @minutes_per_day + step * @minutes_per_mkc_ts
        hour = (step * @minutes_per_mkc_ts / 60).to_i
        active_occupancy_percentage = 1 - (occupancy_schedules[:away_schedule][minute] + occupancy_schedules[:sleep_schedule][minute])
        full_occupancy_current_val = sch[hour] * monthly_multiplier
        modulated_value = sch_min + (full_occupancy_current_val - sch_min) * active_occupancy_percentage
        schedule.fill(modulated_value, minute, @minutes_per_mkc_ts)
      end
    end
    return schedule
  end

  # Fill the lighting schedule based on occupant activities.
  #
  # @param args [Hash] Map of :argument_name => value passed to the measure
  # @param occupancy_schedules [Hash] Hash returned by generate_occupancy_schedules
  # @return [nil]
  def fill_lighting_schedule(args, occupancy_schedules)
    # Initialize base lighting schedule
    interior_lighting_schedule = initialize_interior_lighting_schedule(args)

    # Generate minute-level schedule
    lighting_interior = Array.new(@total_days_in_year * @minutes_per_day, 0.0)

    @total_days_in_year.times do |day|
      day_sch = interior_lighting_schedule[day * 24, 24]
      day_min = day_sch.min
      @mkc_ts_per_day.times do |step|
        minute = day * @minutes_per_day + step * @minutes_per_mkc_ts
        active_occupancy_percentage = 1 - (occupancy_schedules[:away_schedule][minute] +
                                           occupancy_schedules[:sleep_schedule][minute])
        current_val = interior_lighting_schedule[minute / 60]
        value = day_min + (current_val - day_min) * active_occupancy_percentage
        lighting_interior.fill(value, minute, @minutes_per_mkc_ts)
      end
    end

    normalized_lighting = random_shift_and_normalize(lighting_interior)
    @schedules[SchedulesFile::Columns[:LightingInterior].name] = normalized_lighting
    if @hpxml_bldg.has_location(HPXML::LocationGarage)
      @schedules[SchedulesFile::Columns[:LightingGarage].name] = normalized_lighting
    end
  end

  # Generate the sink schedule based on occupant activities.
  #
  # @param mkc_activity_schedules [Array] Array of occupant activity schedules
  # @return [Array] Minute-level sink water draw schedule
  def generate_sink_schedule(mkc_activity_schedules)
    # Generate the Sink Schedule
    # 1. Find indexes (minutes) when at least one occupant can have sink event (they aren't sleeping or absent)
    # 2. Determine number of cluster per day
    # 3. Sample flow-rate for the sink
    # 4. For each cluster
    #   a. sample for number_of_events
    #   b. Re-normalize onset probability by removing invalid indexes (invalid = where we already have sink events)
    #   b. Probabilistically determine the start of the first event based on onset probability.
    #   c. For each event in number_of_events
    #      i. Sample the duration
    #      ii. Add the time occupied by event to invalid_index
    #      ii. if more events, offset by fixed wait time and goto c
    #   d. if more cluster, go to 4.

    sink_activity_probable_mins = get_sink_probable_minutes(mkc_activity_schedules)
    sink_activity_sch = [0] * @mins_in_year

    # Load probability distributions and constants
    sink_duration_probs = Schedule.validate_values(Constants::SinkDurationProbability, 9, 'sink_duration_probability')
    events_per_cluster_probs = Schedule.validate_values(Constants::SinkEventsPerClusterProbs, 15, 'sink_events_per_cluster_probs')
    hourly_onset_prob = Schedule.validate_values(Constants::SinkHourlyOnsetProb, 24, 'sink_hourly_onset_prob')

    # Calculate clusters and flow rate
    cluster_per_day = calculate_sink_clusters_per_day()
    sink_flow_rate = gaussian_rand(@prngs[:hygiene], Constants::SinkFlowRateMean, Constants::SinkFlowRateStd)
    events_per_cluster_precomputed = weighted_random_precompute(events_per_cluster_probs)
    duration_precomputed = weighted_random_precompute(sink_duration_probs)
    # Generate sink events for each day
    @total_days_in_year.times do |day|
      todays_probable_steps = sink_activity_probable_mins[day * @mkc_ts_per_day..((day + 1) * @mkc_ts_per_day - 1)]
      todays_probablities = todays_probable_steps.map.with_index { |p, i| p * hourly_onset_prob[i / @mkc_ts_per_hour] }
      # Normalize probabilities and select start time
      prob_sum = todays_probablities.sum(0)
      normalized_probabilities = todays_probablities.map { |p| p * 1 / prob_sum }
      precomputed_cumweights = weighted_random_precompute(normalized_probabilities)
      generated_clusters = 0
      max_attempts = 200
      attempts = 0
      while generated_clusters < cluster_per_day && attempts < max_attempts
        # Get probability distribution for today's events
        cluster_start_index = weighted_random(@prngs[:hygiene], normalized_probabilities, precomputed_cumweights)
        attempts += 1
        if sink_activity_probable_mins[day * @mkc_ts_per_day + cluster_start_index] == 0
          next # Sample again if time slot is already used
        end

        # Mark time slot as used
        sink_activity_probable_mins[day * @mkc_ts_per_day + cluster_start_index] = 0
        generated_clusters += 1
        # Generate events within this cluster
        num_events = weighted_random(@prngs[:hygiene], events_per_cluster_probs, events_per_cluster_precomputed) + 1
        start_min = cluster_start_index * 15
        end_min = (cluster_start_index + 1) * 15

        num_events.times do
          duration = weighted_random(@prngs[:hygiene], sink_duration_probs, duration_precomputed) + 1
          duration = end_min - start_min if start_min + duration > end_min

          sink_activity_sch.fill(sink_flow_rate, (day * @minutes_per_day) + start_min, duration)
          start_min += duration + Constants::SinkMinutesBetweenEventGap

          break if start_min >= end_min
        end
      end
    end
    return sink_activity_sch
  end

  # Initialize array marking minutes when sink activity is possible.
  #
  # @param mkc_activity_schedules [Array<Array<Integer>>] Array of occupant activity schedules from Markov chain simulation
  # @return [Array<Integer>] Array indicating minutes when sink activity is possible (1) or not (0)
  def get_sink_probable_minutes(mkc_activity_schedules)
    # Initialize array marking minutes when sink activity is possible
    # (when at least one occupant is not sleeping and not absent)
    sink_activity_probable_mins = [0] * @mkc_steps_in_a_year

    # States are: 0='sleeping', 1='shower', 2='laundry', 3='cooking', 4='dishwashing', 5='absent', 6='nothingAtHome'
    @mkc_steps_in_a_year.times do |step|
      mkc_activity_schedules.size.times do |i| # across occupants
        if not ((mkc_activity_schedules[i][step, 0] == 1) || (mkc_activity_schedules[i][step, 5] == 1))
          sink_activity_probable_mins[step] = 1
          break # One active occupant is sufficient
        end
      end
    end

    return sink_activity_probable_mins
  end

  # Calculate the number of sink clusters per day based on number of occupants.
  #
  # @return [Integer] Number of sink clusters per day
  def calculate_sink_clusters_per_day()
    # Lookup avg_sink_clusters_per_hh from constants and adjust for number of occupants
    avg_sink_clusters_per_hh = Constants::SinkAvgSinkClustersPerHH
    # Eq based on cluster scaling in Building America DHW Event Schedule Generator
    # (fewer sink draw clusters for larger households)
    total_clusters = avg_sink_clusters_per_hh * (0.29 * @num_occupants + 0.26)
    return (total_clusters / @total_days_in_year).to_i
  end

  # Generate minute level schedule for shower and bath.
  #
  # @param mkc_activity_schedules [Array<Array<Integer>>] Array of occupant activity schedules from Markov chain simulation
  # @return [Array<Float>, Array<Float>] Arrays containing shower and bath schedules
  def generate_bath_shower_schedules(mkc_activity_schedules)
    # Generate minute level schedule for shower and bath
    # 1. Identify the shower time slots from the mkc schedule. This corresponds to personal hygiene time
    # For each slot:
    # 2. Determine if the personal hygiene is to be bath/shower using bath_to_shower_ratio probability
    # 3. Sample for the shower and bath flow rate. (These will remain same throughout the year for a given building)
    #    However, the duration of each shower/bath event can be different, so, in 15-minute aggregation, the shower/bath
    #    Water consumption might appear different between different events
    # 4. If it is shower
    #   a. Determine the number of events in the shower cluster (there can be multiple showers)
    #   b. For each event, sample the shower duration
    #   c. Fill in the time period of personal hygiene using that many events of corresponding duration
    #      separated by shower_minutes_between_event_gap.
    #      TODO If there is room in the mkc personal hygiene slot, shift uniform randomly
    # 5. If it is bath
    #   a. Sample the bath duration
    #   b. Fill in the mkc personal hygiene slot with the bath duration and flow rate.
    #      TODO If there is room in the mkc personal hygiene slot, shift uniform randomly
    # 6. Repeat process 2-6 for each occupant
    bath_flow_rate = gaussian_rand(@prngs[:hygiene], Constants::BathFlowRateMean, Constants::BathFlowRateStd)
    shower_flow_rate = gaussian_rand(@prngs[:hygiene], Constants::ShowerFlowRateMean, Constants::ShowerFlowRateStd)
    bath_sch = [0] * @mins_in_year
    shower_sch = [0] * @mins_in_year
    # Generate schedules
    step = 0
    shower_cluster_size_precomputed_vals = get_activity_cluster_size_precomputed_vals(@cluster_size_prob_map, 'shower')
    shower_duration_precomputed_vals = get_event_duration_precomputed_vals(@event_duration_prob_map, 'shower')
    while step < @mkc_steps_in_a_year
      shower_state = sum_across_occupants(mkc_activity_schedules, 1, step)
      start_min = step * 15
      step_jump = 1
      shower_state.to_i.times do
        r = @prngs[:hygiene].rand
        if r <= Constants::BathToShowerRatio
          # Fill bath event
          duration = gaussian_rand(@prngs[:hygiene], Constants::BathDurationMean, Constants::BathDurationStd)
          int_duration = duration.ceil
          # since we are rounding duration to integer minute, we compensate by scaling flow rate
          flow_rate = bath_flow_rate * duration / int_duration
          m = 0
          int_duration.times do
            break if (start_min + m) >= @mins_in_year

            bath_sch[start_min + m] += flow_rate
            m += 1
          end
        else
          # Fill shower events
          num_events = sample_activity_cluster_size(@prngs[:hygiene], @cluster_size_prob_map, 'shower', shower_cluster_size_precomputed_vals)
          m = 0
          num_events.times do
            duration = sample_event_duration(@prngs[:hygiene], @event_duration_prob_map, 'shower', shower_duration_precomputed_vals)
            int_duration = duration.ceil
            flow_rate = shower_flow_rate * duration / int_duration
            int_duration.times do
              break if (start_min + m) >= @mins_in_year

              shower_sch[start_min + m] += flow_rate
              m += 1
            end
            Constants::ShowerMinutesBetweenEventGap.times do
              break if (start_min + m) >= @mins_in_year

              m += 1
            end
            break if start_min + m >= @mins_in_year
          end
        end
        step_jump = [step_jump, 1 + (m / 15)].max
      end
      step += step_jump
    end
    return shower_sch, bath_sch
  end

  # Generate the dishwasher schedule based on occupant activities.
  #
  # @param mkc_activity_schedules [Array] Array of occupant activity schedules
  # @return [Array] Minute-level dishwasher water draw schedule
  def generate_dishwasher_schedule(mkc_activity_schedules)
    # Generate minute level schedule for dishwasher
    # 1. Identify the dishwasher time slots from the mkc schedule.
    # 2. Sample for the flow_rate
    # 3. Determine the number of events in the dishwasher cluster
    #    (it's typically composed of multiple water draw events)
    # 4. For each event, sample the event duration
    # 5. Fill in the dishwasher time slot using those water draw events

    dw_flow_rate_mean = Constants::HotWaterDishwasherFlowRateMean
    dw_flow_rate_std = Constants::HotWaterDishwasherFlowRateStd
    dw_minutes_between_event_gap = Constants::HotWaterDishwasherMinutesBetweenEventGap
    dw_hot_water_sch = [0] * @mins_in_year
    m = 0
    dw_flow_rate = gaussian_rand(@prngs[:dishwasher], dw_flow_rate_mean, dw_flow_rate_std)

    # States are: 'sleeping','shower','laundry','cooking', 'dishwashing', 'absent', 'nothingAtHome'
    # Fill in dw_water draw schedule
    step = 0
    dishwasher_cluster_size_precomputed_vals = get_activity_cluster_size_precomputed_vals(@cluster_size_prob_map, 'hot_water_dishwasher')
    dishwasher_duration_precomputed_vals = get_event_duration_precomputed_vals(@event_duration_prob_map, 'hot_water_dishwasher')
    while step < @mkc_steps_in_a_year
      dish_state = sum_across_occupants(mkc_activity_schedules, 4, step, max_clip: 1)
      step_jump = 1
      if dish_state > 0
        cluster_size = sample_activity_cluster_size(@prngs[:dishwasher], @cluster_size_prob_map, 'hot_water_dishwasher', dishwasher_cluster_size_precomputed_vals)
        start_minute = step * 15
        m = 0
        cluster_size.times do
          duration = sample_event_duration(@prngs[:dishwasher], @event_duration_prob_map, 'hot_water_dishwasher', dishwasher_duration_precomputed_vals)
          int_duration = duration.ceil
          flow_rate = dw_flow_rate * duration / int_duration
          int_duration.times do
            dw_hot_water_sch[start_minute + m] = flow_rate
            m += 1
            if start_minute + m >= @mins_in_year then break end
          end
          if start_minute + m >= @mins_in_year then break end

          dw_minutes_between_event_gap.times do
            m += 1
            if start_minute + m >= @mins_in_year then break end
          end
          if start_minute + m >= @mins_in_year then break end
        end
        step_jump = [step_jump, 1 + (m / 15)].max
      end
      step += step_jump
    end

    return dw_hot_water_sch
  end

  # Generate the clothes washer schedule based on occupant activities.
  #
  # @param mkc_activity_schedules [Array] Array of occupant activity schedules
  # @return [Array] Minute-level clothes washer water draw schedule
  def generate_clothes_washer_schedule(mkc_activity_schedules)
    # Generate minute level schedule for clothes washer water draw
    cw_flow_rate_mean = Constants::HotWaterClothesWasherFlowRateMean
    cw_flow_rate_std = Constants::HotWaterClothesWasherFlowRateStd
    cw_minutes_between_event_gap = Constants::HotWaterClothesWasherMinutesBetweenEventGap
    cw_hot_water_sch = [0] * @mins_in_year # this is the clothes_washer water draw schedule
    cw_load_size_probability = Schedule.validate_values(Constants::HotWaterClothesWasherLoadSizeProbability, 4, 'hot_water_clothes_washer_load_size_probability')

    cw_flow_rate = gaussian_rand(@prngs[:clothes_washer], cw_flow_rate_mean, cw_flow_rate_std)

    # States are: 'sleeping','shower','laundry','cooking', 'dishwashing', 'absent', 'nothingAtHome'
    step = 0
    m = 0
    # Fill in clothes washer water draw schedule based on markov-chain state 2 (laundry)
    cw_cluster_size_precomputed = get_activity_cluster_size_precomputed_vals(@cluster_size_prob_map, 'hot_water_clothes_washer')
    cw_duration_precomputed = get_event_duration_precomputed_vals(@event_duration_prob_map, 'hot_water_clothes_washer')
    num_load_precomputed = weighted_random_precompute(cw_load_size_probability)
    while step < @mkc_steps_in_a_year
      clothes_state = sum_across_occupants(mkc_activity_schedules, 2, step, max_clip: 1)
      step_jump = 1
      if clothes_state > 0
        num_loads = weighted_random(@prngs[:clothes_washer], cw_load_size_probability, num_load_precomputed) + 1
        start_minute = step * 15
        m = 0
        num_loads.times do
          cluster_size = sample_activity_cluster_size(@prngs[:clothes_washer], @cluster_size_prob_map, 'hot_water_clothes_washer', cw_cluster_size_precomputed)
          cluster_size.times do
            duration = sample_event_duration(@prngs[:clothes_washer], @event_duration_prob_map, 'hot_water_clothes_washer', cw_duration_precomputed)
            int_duration = duration.ceil
            flow_rate = cw_flow_rate * duration.to_f / int_duration
            int_duration.times do
              cw_hot_water_sch[start_minute + m] = flow_rate
              m += 1
              if start_minute + m >= @mins_in_year then break end
            end
            if start_minute + m >= @mins_in_year then break end

            cw_minutes_between_event_gap.times do
              # skip the gap between events
              m += 1
              if start_minute + m >= @mins_in_year then break end
            end
            if start_minute + m >= @mins_in_year then break end
          end
        end
        if start_minute + m >= @mins_in_year then break end

        step_jump = [step_jump, 1 + (m / 15)].max
      end
      step += step_jump
    end
    return cw_hot_water_sch
  end

  # @param mkc_activity_schedules [Array<Array<Integer>>] Markov chain activity schedules for each occupant
  # @return [Array<Float>] Dishwasher power draw schedule for each minute of the year
  def generate_dishwasher_power_schedule(mkc_activity_schedules)
    # Fill in dishwasher power draw schedule based on markov-chain
    # This follows similar pattern as filling in water draw events, except we use different set of probability
    # distribution csv files for power level and duration of each event. And there is only one event per mkc slot.
    dw_power_sch = [0] * @mins_in_year
    step = 0
    last_state = 0
    start_time = Time.new(@sim_year, 1, 1)
    hot_water_dishwasher_monthly_multiplier = Schedule.validate_values(@schedules_csv_data[SchedulesFile::Columns[:Dishwasher].name]['HotWaterDishwasherMonthlyMultiplier'], 12, 'hot_water_dishwasher_monthly_multiplier')

    while step < @mkc_steps_in_a_year
      dish_state = sum_across_occupants(mkc_activity_schedules, 4, step, max_clip: 1)
      step_jump = 1
      if (dish_state > 0) && (last_state == 0) # last_state == 0 prevents consecutive dishwasher power without gap
        duration_15min, avg_power = sample_appliance_duration_power(@prngs[:dishwasher], @appliance_power_dist_map, 'dishwasher')

        month = (start_time + step * 15 * 60).month
        duration_min = (duration_15min * 15 * hot_water_dishwasher_monthly_multiplier[month - 1]).to_i

        duration = [duration_min, @mins_in_year - step * 15].min
        dw_power_sch.fill(avg_power, step * 15, duration)
        step_jump = duration_15min
      end
      last_state = dish_state
      step += step_jump
    end

    return dw_power_sch
  end

  # Generate power schedules for clothes washer and dryer based on occupant activities.
  #
  # @param mkc_activity_schedules [Array<Array<Integer>>] Markov chain activity schedules for each occupant
  # @return [Array<Float>, Array<Float>] Arrays containing clothes washer and dryer power draw schedules
  def generate_clothes_washer_dryer_power_schedules(mkc_activity_schedules)
    # Fill in cw and clothes dryer power schedule
    # States are: 'sleeping', 'shower', 'laundry', 'cooking', 'dishwashing', 'absent', 'nothingAtHome'
    cw_power_sch = [0] * @mins_in_year
    cd_power_sch = [0] * @mins_in_year
    step = 0
    last_state = 0
    start_time = Time.new(@sim_year, 1, 1)
    clothes_dryer_monthly_multiplier = Schedule.validate_values(@schedules_csv_data[SchedulesFile::Columns[:ClothesDryer].name]['ClothesDryerMonthlyMultiplier'], 12, 'clothes_dryer_monthly_multiplier')
    hot_water_clothes_washer_monthly_multiplier = Schedule.validate_values(@schedules_csv_data[SchedulesFile::Columns[:ClothesWasher].name]['HotWaterClothesWasherMonthlyMultiplier'], 12, 'hot_water_clothes_washer_monthly_multiplier')

    while step < @mkc_steps_in_a_year
      clothes_state = sum_across_occupants(mkc_activity_schedules, 2, step, max_clip: 1)
      step_jump = 1
      if (clothes_state > 0) && (last_state == 0) # last_state == 0 prevents consecutive washer power without gap
        cw_duration_15min, cw_avg_power = sample_appliance_duration_power(@prngs[:clothes_washer], @appliance_power_dist_map, 'clothes_washer')
        cd_duration_15min, cd_avg_power = sample_appliance_duration_power(@prngs[:clothes_dryer], @appliance_power_dist_map, 'clothes_dryer')

        month = (start_time + step * 15 * 60).month
        cd_duration_min = (cd_duration_15min * 15 * clothes_dryer_monthly_multiplier[month - 1]).to_i
        cw_duration_min = (cw_duration_15min * 15 * hot_water_clothes_washer_monthly_multiplier[month - 1]).to_i

        cw_duration = [cw_duration_min, @mins_in_year - step * 15].min
        cw_power_sch.fill(cw_avg_power, step * 15, cw_duration)
        cd_start_time = (step * 15 + cw_duration).to_i # clothes dryer starts immediately after washer ends\
        cd_duration = [cd_duration_min, @mins_in_year - cd_start_time].min # cd_duration would be negative if cd_start_time > @mins_in_year, and no filling would occur
        cd_power_sch = cd_power_sch.fill(cd_avg_power, cd_start_time, cd_duration)
        step_jump = cw_duration_15min + cd_duration_15min
      end
      last_state = clothes_state
      step += step_jump
    end

    return cw_power_sch, cd_power_sch
  end

  # Generate power schedule for cooking range based on occupant activities.
  #
  # @param mkc_activity_schedules [Array<Array<Integer>>] Markov chain activity schedules for each occupant
  # @return [Array<Float>] Array containing cooking range power draw schedule
  def generate_cooking_power_schedule(mkc_activity_schedules)
    # Fill in cooking power schedule
    # States are: 'sleeping', 'shower', 'laundry', 'cooking', 'dishwashing', 'absent', 'nothingAtHome'
    cooking_power_sch = [0] * @mins_in_year
    step = 0
    last_state = 0
    start_time = Time.new(@sim_year, 1, 1)
    cooking_monthly_multiplier = Schedule.validate_values(@schedules_csv_data[SchedulesFile::Columns[:CookingRange].name]['CookingMonthlyMultiplier'], 12, 'cooking_monthly_multiplier')

    while step < @mkc_steps_in_a_year
      cooking_state = sum_across_occupants(mkc_activity_schedules, 3, step, max_clip: 1)
      step_jump = 1
      if (cooking_state > 0) && (last_state == 0) # last_state == 0 prevents consecutive cooking power without gap
        duration_15min, avg_power = sample_appliance_duration_power(@prngs[:cooking], @appliance_power_dist_map, 'cooking')
        month = (start_time + step * 15 * 60).month
        duration_min = (duration_15min * 15 * cooking_monthly_multiplier[month - 1]).to_i
        duration = [duration_min, @mins_in_year - step * 15].min
        cooking_power_sch.fill(avg_power, step * 15, duration)
        step_jump = duration_15min
      end
      last_state = cooking_state
      step += step_jump
    end

    return cooking_power_sch
  end

  # Apply random time shift to schedule values without normalizing.
  #
  # @param schedule [Array<Float>] Array of minute-level schedule values
  # @return [Array<Float>] Schedule with random time shift applied
  def random_shift_and_aggregate(schedule)
    schedule.rotate!(@random_offset)

    # Apply monthly offsets and aggregate
    schedule = apply_monthly_offsets(array: schedule,
                                     weekday_monthly_shift_dict: @weekday_monthly_shift_dict,
                                     weekend_monthly_shift_dict: @weekend_monthly_shift_dict)
    schedule = aggregate_array(schedule, @minutes_per_step)

    return schedule
  end

  # Apply random time shift and normalize schedule values.
  #
  # @param schedule [Array<Float>] Array of minute-level schedule values
  # @param max_val [Float] Maximum value to normalize to. If nil, use the maximum value in the schedule.
  # @return [Array<Float>] Normalized schedule with random time shift applied
  def random_shift_and_normalize(schedule, max_val = nil)
    shifted_schedule = random_shift_and_aggregate(schedule)
    return normalize(shifted_schedule, max_val)
  end
end
