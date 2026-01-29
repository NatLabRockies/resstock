# frozen_string_literal: true

def integrity_check(project_dir_name, housing_characteristics_dir = 'housing_characteristics', lookup_file = nil)
  # Load helper file and sampling file
  resources_dir = File.join(File.dirname(__FILE__), '../resources')
  require File.join(resources_dir, 'buildstock')
  require File.join(resources_dir, 'run_sampling_lib')
  require 'csv'

  # Setup
  if lookup_file.nil?
    lookup_file = File.join(resources_dir, 'options_lookup.tsv')
  end
  check_file_exists(lookup_file, nil)

  # Perform various checks on each probability distribution file
  parameters_processed = []
  tsvfiles = {}
  last_size = -1

  parameter_names = []
  lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a
  get_parameters_ordered_from_options_lookup_tsv(lookup_csv_data).each do |parameter_name|
    tsvpath = File.join(project_dir_name, housing_characteristics_dir, "#{parameter_name}.tsv")
    next if not File.exist?(tsvpath) # Not every parameter used by every project

    parameter_names << parameter_name
  end
  j = 1
  n_params = parameter_names.length
  while parameters_processed.size != parameter_names.size

    if last_size == parameters_processed.size
      # No additional processing occurred during last pass
      unprocessed_parameters = parameter_names - parameters_processed
      err = "ERROR: Unable to process these parameters: #{unprocessed_parameters.join(', ')}."
      deps = []
      unprocessed_parameters.each do |p|
        tsvpath = File.join(project_dir_name, housing_characteristics_dir, "#{p}.tsv")
        tsvfile = tsvfiles[p]
        if tsvfile.nil?
          tsvfile = TsvFile.new(tsvpath, nil)
          tsvfiles[p] = tsvfile
        end
        tsvfile.dependency_cols.keys.each do |d|
          next if deps.include?(d)

          deps << d
        end
      end
      undefined_deps = deps - unprocessed_parameters - parameters_processed
      # Check if undefined deps exist but are undefined simply because they're not in options_lookup.tsv
      undefined_deps_exist = true
      undefined_deps.each do |undefined_dep|
        tsvpath = File.join(project_dir_name, housing_characteristics_dir, "#{undefined_dep}.tsv")
        next if File.exist?(tsvpath)

        undefined_deps_exist = false
      end
      if undefined_deps_exist
        err += "\nPerhaps one of these dependency files has options missing from options_lookup.tsv? #{undefined_deps.join(', ')}."
      else
        err += "\nPerhaps one of these dependency files is missing? #{undefined_deps.join(', ')}."
      end
      raise err
    end

    err = ''
    last_size = parameters_processed.size
    parameter_names.each do |parameter_name|
      # Already processed? Skip
      next if parameters_processed.include?(parameter_name)

      tsvpath = File.join(project_dir_name, housing_characteristics_dir, "#{parameter_name}.tsv")
      check_file_exists(tsvpath, nil)
      tsvfile = tsvfiles[parameter_name]
      if tsvfile.nil?
        tsvfile = TsvFile.new(tsvpath, nil)
        tsvfiles[parameter_name] = tsvfile
      end

      # Dependencies not yet processed? Skip until a subsequent pass
      skip = false
      tsvfile.dependency_cols.keys.each do |dep|
        next if parameters_processed.include?(dep)

        skip = true
      end
      next if skip

      puts "(#{j}/#{n_params}) Checking for issues with #{project_dir_name}/#{parameter_name}..."
      parameters_processed << parameter_name

      # Test that dependency options exist
      tsvfile.dependency_options.each do |dependency, options|
        options.each do |option|
          if not tsvfiles[dependency].option_cols.keys.include? option
            err += "ERROR: #{dependency}=#{option} not a valid dependency option for #{parameter_name}.\n"
          end
        end
      end

      # Test all possible combinations of dependency value combinations
      combo_hashes = get_combination_hashes(tsvfiles, tsvfile.dependency_cols.keys)
      if combo_hashes.size > 0
        i = 1
        starting = Time.now
        total_hashes = combo_hashes.length
        combo_hashes.each do |combo_hash|
          # Check dependency value combination
          _matched_option_name, _matched_row_num = tsvfile.get_option_name_from_sample_number(1.0, combo_hash)

          # Print to screen so CircleCI does not timeout
          if i % 10000 == 0
            puts "  Checked #{i}/#{total_hashes} possible dependency value combinations..."
          end
          i += 1
        end
        ending = Time.now
        puts "  Checking all possible combinations: \t\t#{ending - starting} seconds\n"
      else
        # global distribution
        _matched_option_name, _matched_row_num = tsvfile.get_option_name_from_sample_number(1.0, nil)
      end

      # Check file format to be consistent with specified guidelines
      starting = Time.now
      check_parameter_file_format(tsvpath, parameter_name)
      ending = Time.now
      puts "  Checking file format: \t\t\t#{ending - starting} seconds\n"

      # Check for all options defined in options_lookup.tsv
      starting = Time.now
      get_measure_args_from_option_names(lookup_csv_data, tsvfile.option_cols.keys, parameter_name, lookup_file)
      ending = Time.now
      puts "  Checking all options in options_lookup.tsv: \t#{ending - starting} seconds\n\n"
      j += 1
    end
    if not err.empty?
      raise err
    end
  end # parameter_name

  # Test sampling
  r = RunSampling.new
  output_file = r.run(project_dir_name, 10000, "#{project_dir_name}.csv", housing_characteristics_dir, lookup_file)

  # Check outfile
  check_buildstock(output_file, lookup_file, lookup_csv_data)

  if File.exist?(output_file)
    if project_dir_name == 'project_national'
      FileUtils.mv(output_file, output_file.gsub(project_dir_name, 'buildstock'))
    else
      File.delete(output_file) # Clean up
    end
  end

  # Unused TSVs?
  err = ''
  Dir[File.join(project_dir_name, housing_characteristics_dir, '*.tsv')].each do |tsvpath|
    parameter_name = File.basename(tsvpath, '.*')
    if not parameter_names.include? parameter_name
      err += "ERROR: TSV file #{tsvpath} not used in options_lookup.tsv.\n"
    end
  end
  if not err.empty?
    raise err
  end
end

def integrity_check_options_lookup_tsv(project_dir_name, housing_characteristics_dir = 'housing_characteristics', lookup_file = nil)
  require 'openstudio'

  # Load helper file and sampling file
  resources_dir = File.join(File.dirname(__FILE__), '../resources')
  require File.join(resources_dir, 'buildstock')

  # Setup
  if lookup_file.nil?
    lookup_file = File.join(resources_dir, 'options_lookup.tsv')
  end
  check_file_exists(lookup_file, nil)

  # Integrity checks for option_lookup.tsv
  measures = {}
  model = OpenStudio::Model::Model.new

  # Gather all options/arguments
  all_errors = []
  lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a
  parameter_names = get_parameters_ordered_from_options_lookup_tsv(lookup_csv_data)
  parameter_names.each do |parameter_name|
    check_for_illegal_chars(parameter_name, 'parameter')

    tsvpath = File.join(project_dir_name, housing_characteristics_dir, "#{parameter_name}.tsv")
    next if not File.exist?(tsvpath) # Not every parameter used by every project

    option_names = get_options_for_parameter_from_options_lookup_tsv(lookup_csv_data, parameter_name)
    options_measure_args, errors = get_measure_args_from_option_names(lookup_csv_data, option_names, parameter_name, lookup_file)
    all_errors += errors
    option_names.each do |option_name|
      check_for_illegal_chars(option_name, 'option')

      # Check for (parameter, option) names
      # Get measure name and arguments associated with the option
      options_measure_args[option_name].each do |measure_subdir, args_hash|
        if not measures.has_key?(measure_subdir)
          measures[measure_subdir] = {}
        end
        if not measures[measure_subdir].has_key?(parameter_name)
          measures[measure_subdir][parameter_name] = {}
        end

        # Skip options with duplicate argument values as a previous option; speeds up processing.
        duplicate_args = false
        measures[measure_subdir][parameter_name].keys.each do |opt_name|
          next if measures[measure_subdir][parameter_name][opt_name].to_s != args_hash.to_s

          duplicate_args = true
          break
        end
        next if duplicate_args

        # Store arguments
        measures[measure_subdir][parameter_name][option_name] = args_hash
      end
    end
  end

  if not all_errors.empty?
    raise all_errors.map { |e| "ERROR: #{e}" }.join("\n")
  end

  measures.keys.each do |measure_subdir|
    puts "Checking for issues with #{measure_subdir} measure..."

    measurerb_path = File.absolute_path(File.join(File.dirname(lookup_file), '..', 'test', measure_subdir, 'measure.rb'))
    if not File.exist?(measurerb_path)
      measurerb_path = File.absolute_path(File.join(File.dirname(lookup_file), '..', 'measures', measure_subdir, 'measure.rb'))
    end
    check_file_exists(measurerb_path, nil)
    measure_instance = get_measure_instance(measurerb_path)

    # Validate measure arguments for combinations of options
    param_names = measures[measure_subdir].keys()
    options_array = []
    max_param_size = 0
    param_names.each do |parameter_name|
      options_array << measures[measure_subdir][parameter_name].keys()
      max_param_size = [max_param_size, options_array[-1].size].max
    end

    option_combinations = []
    options_array.each_with_index do |option_array, idx|
      for n in 0..max_param_size - 1
        if idx == 0
          option_combinations << []
        end
        option_combinations[n] << option_array[n % option_array.size]
      end
    end

    all_measure_args = []
    option_combinations.each do |option_combination|
      measure_args = {}
      option_combination.each_with_index do |option_name, idx|
        measures[measure_subdir][param_names[idx]][option_name].each do |k, v|
          measure_args[k] = v
        end
      end
      next if all_measure_args.include?(measure_args)

      all_measure_args << measure_args
    end

    measure_instance_args = measure_instance.arguments(model)
    all_measure_args.shuffle.each do |measure_args|
      validate_measure_args(measure_instance_args, measure_args, lookup_file, measure_subdir, nil)
    end
  end
end

def check_buildstock(output_file, lookup_file, lookup_csv_data = nil)
  require 'csv'

  puts "Opening #{lookup_file}..."
  lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a if lookup_csv_data.nil?

  # Cache {parameter => options}
  puts "Reading #{output_file}..."
  parameters_options = {}
  csv = CSV.foreach(output_file, headers: true)
  raise 'ERROR: Missing the Building column.' if !csv.first.include?('Building')

  csv.each do |row|
    row.each do |parameter_name, option_name|
      next if parameter_name == 'Building'
      next if parameter_name == 'sample_weight'

      unless parameters_options.keys.include? parameter_name
        parameters_options[parameter_name] = []
      end

      unless parameters_options[parameter_name].include? option_name
        parameters_options[parameter_name] << option_name
      end
    end
  end

  # Cache {parameter => {option => {measure => {arg => value}}}}
  puts 'Checking parameters/options...'
  all_errors = []
  parameters_options_measure_args = {}
  parameters_options.each do |parameter_name, option_names|
    parameters_options_measure_args[parameter_name], errors = get_measure_args_from_option_names(lookup_csv_data, option_names, parameter_name, lookup_file)
    all_errors += errors
  end

  if not all_errors.empty?
    raise all_errors.map { |e| "ERROR: #{e}" }.join("\n")
  end

  # Check that measure arguments aren't getting overwritten
  puts 'Checking for argument duplication...'
  err = ''
  CSV.foreach(output_file, headers: true).each do |row|
    args_map = {}
    row.each do |parameter_name, option_name|
      next if parameter_name == 'Building'
      next if parameter_name == 'sample_weight'

      parameters_options_measure_args[parameter_name][option_name].each do |measure_name, args|
        args.keys.each do |arg|
          args_map[[measure_name, arg]] = [] if args_map[[measure_name, arg]].nil?
          args_map[[measure_name, arg]] << parameter_name
        end
      end
    end
    args_map.each do |k, v|
      next unless v.size > 1

      param_names = v.join('", "')
      measure_name = k[0]
      arg_name = k[1]
      next if err.include?(param_names) && err.include?(measure_name) && err.include?(arg_name)

      err += "ERROR: Duplicate measure argument assignment(s) across [\"#{param_names}\"] parameters. #{measure_name} => \"#{arg_name}\" already assigned.\n"
    end
  end

  if not err.empty?
    raise err
  end
end

def check_for_illegal_chars(name, name_type)
  # Check for illegal characters in parameter/option names. These characters are
  # reserved for use in the apply upgrade logic.
  ['(', ')', '|', '&'].each do |char|
    next unless name.include? char

    raise "ERROR: Illegal character ('#{char}') found in #{name_type} name '#{name}'."
  end
end

def check_parameter_file_format(tsvpath, name)
  # For each line in file
  i = 1
  File.read(tsvpath, mode: 'rb').each_line do |line|
    # If not a comment line
    next if line.start_with? "\#"

    # Check endline character
    if not line.include? "\r\n"
      # Found wrong endline format
      raise "ERROR: Incorrect newline character found in '#{name}', line '#{i}'."
    end # End checks

    i += 1
  end
end
