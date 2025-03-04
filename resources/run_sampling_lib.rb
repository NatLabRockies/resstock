# frozen_string_literal: true

# Performs sampling technique and generates CSV file with parameter options for each building.

# The file has to follow general Ruby conventions.
# File name must for the snake case (underscore case) of the class name. For example: WorkerInit = worker_init

require 'csv'
require_relative 'buildstock'
require 'pathname'

class RunSampling
  def run(project_dir_name, num_samples, outfile, housing_characteristics_dir = 'housing_characteristics', lookup_file = nil)
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', 'resources')) # Should have been uploaded per 'Additional Analysis Files' in PAT
    characteristics_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', housing_characteristics_dir)) # Should have been uploaded per 'Additional Analysis Files' in PAT
    if not File.exist?(characteristics_dir)
      characteristics_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', project_dir_name, housing_characteristics_dir)) # Being run locally?
    end

    if lookup_file.nil?
      lookup_file = File.join(resources_dir, 'options_lookup.tsv')
    end

    lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a

    params = get_parameters_ordered_from_options_lookup_tsv(lookup_csv_data)

    tsvfiles = {}
    params.each do |param|
      tsvpath = File.join(characteristics_dir, param + '.tsv')
      next if not File.exist?(tsvpath) # Not every parameter used by every mode

      tsvfile = TsvFile.new(tsvpath, nil)
      tsvfiles[param] = tsvfile
    end
    params = tsvfiles.keys
    if params.size == 0
      register_error('No parameters found, aborting...', nil)
    end

    params = update_parameter_dependencies(params, tsvfiles)
    sample_results = perform_sampling(params, num_samples, tsvfiles, project_dir_name).transpose
    out_file = write_csv(sample_results, outfile)
    return out_file
  end

  def update_parameter_dependencies(params, tsvfiles)
    # Returns a hash with the dependencies for each parameter
    params_with_deps = {}
    params.each do |param|
      params_with_deps[param] = tsvfiles[param].dependency_cols.keys
    end
    return params_with_deps
  end

  def perform_sampling(params, num_samples, tsvfiles, project_dir_name)
    results_data = []
    results_data_cols = {}

    # Add building numbers
    results_data_bldgs = ['Building'] + Array(1..num_samples)
    results_data << results_data_bldgs
    results_data_cols[results_data_bldgs[0]] = results_data.size - 1

    random_seed = 57 # Using a hard-coded seed so that we get repeatable results

    processed_params = []
    bldgs_hash = {}
    while processed_params.size != params.size
      params.each do |param, param_deps|
        # Already processed? Skip
        next if processed_params.include?(param)

        # Dependencies not yet processed? Skip until a subsequent pass
        skip = false
        param_deps.each do |param_dep|
          next if processed_params.include?(param_dep)

          skip = true
        end
        next if skip

        puts "Sampling #{project_dir_name}/#{param}..."

        results_data_param = [param] + [nil] * num_samples
        tsvfile = tsvfiles[param]

        if param_deps.size == 0
          # No dependencies, perform 'global' sampling
          sample_results = sample_probability_distribution(nil, tsvfile, num_samples)
          random_seed = distribute_samples(random_seed, results_data_param, sample_results, Array(1..num_samples))
        else
          # For each combination of dependency values, perform sampling
          dep_hashes = get_combination_hashes(tsvfiles, param_deps)
          bldgs_processed = 0
          if not bldgs_hash.keys.include?(param_deps)
            bldgs_hash[param_deps] = get_bldgs_by_dependency_values(results_data, dep_hashes, results_data_cols)
          end
          dep_hashes.each do |dep_hash|
            # Determine buildings this combo applies to
            bldgs = bldgs_hash[param_deps][dep_hash.values]
            next if bldgs.nil?

            sample_results = sample_probability_distribution(dep_hash, tsvfile, bldgs.size)
            random_seed = distribute_samples(random_seed, results_data_param, sample_results, bldgs)
            bldgs_processed += bldgs.size
          end
          # Ensure correct number of buildings were processed
          if bldgs_processed != num_samples
            register_error('Sampling algorithm unexpectedly failed.', nil)
          end
        end

        # Ensure no missing values
        if results_data_param.include?(nil)
          register_error('Sampling algorithm unexpectedly failed.', nil)
        end

        # Add results for this parameter
        results_data << results_data_param
        results_data_cols[results_data_param[0]] = results_data.size - 1
        processed_params << param

        # We just processed a parameter; start back at the beginning to try
        # to keep the parameters better ordered.
        break
      end
    end

    return results_data
  end

  def get_bldgs_by_dependency_values(results_data, dep_hashes, results_data_cols)
    # Returns a hash with key:dep_hash, value:Array[bldgs]

    data = []
    dep_hashes[0].keys.each do |dep_name|
      data << results_data[results_data_cols[dep_name]]
    end
    data = data.transpose

    bldgs_hash = {}
    data[1..-1].each_with_index do |bldg, idx|
      bldgs_hash[bldg] = [] if bldgs_hash[bldg].nil?
      bldgs_hash[bldg] << idx + 1
    end

    return bldgs_hash
  end

  def get_tsvrow_with_dependency_values(tsvfile, dep_hash)
    # Returns the row of data in the tsvfile with the given dependency values.
    if dep_hash.nil?
      return tsvfile.rows[0]
    end

    rownum = tsvfile.rows_keys_s[dep_hash]

    if rownum.nil?
      register_error("Could not find row in #{tsvfile.filename} with dependency values: #{dep_hash}.", nil)
    end

    return tsvfile.rows[rownum]
  end

  def binary_search(arr, value)
    # Implementation of binary search
    if arr.nil? || arr.size == 0
      return 0
    end

    lo = 0
    hi = arr.size - 1
    m = 0
    while lo < hi
      m = (hi + lo) / 2
      if arr[m] > value
        lo = m + 1
      else
        hi = m - 1
      end
    end
    if arr[lo] > value
      lo += 1
    end
    return lo
  end

  def sample_probability_distribution(dep_hash, tsvfile, num_samples)
    # Returns a dictionary with key:option_name, value:num_samples.

    # Create prob_dist hash needed by _sample_probability_distribution method.
    tsvrow = get_tsvrow_with_dependency_values(tsvfile, dep_hash)
    prob_dist = []
    tsvfile.option_cols.each do |option_name, option_col|
      prob_val = tsvrow[option_col].to_f
      next if prob_val <= 0

      prob_dist << [option_name, prob_val]
    end

    return _sample_probability_distribution(prob_dist, num_samples)
  end

  def _sample_probability_distribution(prob_dist, num_samples)
    # Instead of using Monte Carlo, which for small sample sizes can randomly choose
    # a low probability item, we use a quota sampling algorithm to more strategically
    # (non-randomly) choose the number of samples for each item in order to best
    # represent the input distribution.
    # prob_dist - array of arrays where the inner arrays are of the
    #             form [option_name, probability]
    # num_samples - integer for the total number of samples
    # Returns a dictionary with key:option_name, value:num_samples.

    if prob_dist.size == 1
      return { prob_dist[0][0] => num_samples } # Simply return num_samples for only item
    end

    return_samples = {}
    prob_dist.each do |item|
      return_samples[item[0]] = 0
    end

    # Sort array in descending order
    # Using stable sort algorithm from https://groups.google.com/g/comp.lang.ruby/c/JcDGbaFHifI/m/2gKpc9FQbCoJ
    n = 0
    prob_dist = prob_dist.sort_by { |x| n += 1; [x[1], n] }.reverse

    if num_samples == 1
      return { prob_dist[0][0] => 1 } # Simply return 1 sample for max item
    end

    # We'll never choose to sample an item beyond the first
    # num_samples number of items, so discard the rest.
    if prob_dist.size > num_samples
      prob_dist.slice!(num_samples..prob_dist.size - 1)
    end

    sum = prob_dist.transpose[1].inject(0, :+)
    remaining_samples = num_samples
    while remaining_samples > 0
      # Choose highest probability item (first in array)
      max_item = prob_dist[0]

      # Increment the number of samples for the highest probability
      return_samples[max_item[0]] += 1

      # Calculate new probability
      target_num_samples = remaining_samples * max_item[1] / sum
      new_probability = (target_num_samples - 1) / target_num_samples * max_item[1]

      # Remove item, insert back into the appropriate sorted
      # position based on its new probability value
      prob_dist.delete_at(0)
      index = binary_search(prob_dist.transpose[1], new_probability)
      prob_dist.insert(index, [max_item[0], new_probability])

      # Update sum and remaining_samples
      sum += (new_probability - max_item[1])
      remaining_samples -= 1

      # We'll never choose to sample an item beyond the first
      # remaining_samples number of items, so discard the rest.
      if prob_dist.size > remaining_samples
        prob_dist.pop
      end
    end

    # Remove items with no samples
    return_samples.delete_if { |_k, v| v == 0 }

    if return_samples.values.reduce(:+) != num_samples
      register_error('Sampling algorithm unexpectedly failed.', nil)
    end

    return return_samples
  end

  def distribute_samples(random_seed, results_data_param, sample_results, bldgs)
    # Randomly distributes sample_results to the specified bldgs.
    # Returns an updated results_data_param array.
    bldgs.shuffle(random: Random.new(random_seed)).each do |bldg|
      sample_results.each do |option_name, option_num_samples|
        next if option_num_samples <= 0

        results_data_param[bldg] = option_name
        sample_results[option_name] -= 1 # one less sample to distribute
        break
      end
    end
    return random_seed + 1
  end

  def write_csv(sample_results, outfile)
    # Writes the csv output file.
    unless (Pathname.new outfile).absolute?
      outfile = File.absolute_path(File.join(File.dirname(__FILE__), outfile))
    end
    CSV.open(outfile, 'w') do |csv_object|
      sample_results.each do |sample_result|
        csv_object << sample_result
      end
    end
    puts "Wrote output file #{File.basename(outfile)}."
    return outfile
  end
end
