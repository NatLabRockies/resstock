# frozen_string_literal: true

require 'csv'

require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'

module Version
  ResStock_Version = '3.4.0' # Version of ResStock
  BuildStockBatch_Version = '2023.10.0' # Minimum required version of BuildStockBatch
  WorkflowGenerator_Version = '2025.04.29' # Version of buildstockbatch workflow generator

  def self.check_buildstockbatch_version
    if ENV.keys.include?('BUILDSTOCKBATCH_VERSION') # buildstockbatch is installed
      bsb_version = ENV['BUILDSTOCKBATCH_VERSION']
      if Gem::Version.new(bsb_version) < Gem::Version.new(BuildStockBatch_Version)
        fail "BuildStockBatch version #{BuildStockBatch_Version} or above is required. Found version: #{bsb_version}"
      end
    end
  end
end

class TsvFile
  def initialize(full_path, runner)
    @full_path = full_path
    @filename = File.basename(full_path)
    @runner = runner
    @rows, @option_cols, @dependency_cols, @dependency_options, @full_header, @header = get_file_data()
    @rows_keys_s = cache_data()
  end

  attr_accessor :dependency_cols, :dependency_options, :rows, :option_cols, :header, :filename, :rows_keys_s, :full_path

  def get_file_data()
    option_key = 'Option='
    dep_key = 'Dependency='

    rows = File.readlines(@full_path).map { |row| row.split("\t") } # don't use CSV class for faster processing of large files
    full_header = rows.shift
    rows.delete_if { |row| row[0].start_with? "\#" }
    rows.map! { |row| row.delete_if { |x| x.to_s.empty? } } # purge trailing empty fields

    if full_header.nil?
      register_error("Could not find header row in #{@filename}.", @runner)
    end

    # Strip out everything but options and dependencies from header
    header = full_header.select { |el| el.start_with?(option_key) || el.start_with?(dep_key) }

    # Get all option names/dependencies and corresponding column numbers on header row
    option_cols = {}
    dependency_cols = {}
    full_header.each_with_index do |d, col|
      next if d.nil?

      if d.strip.start_with?(option_key)
        val = d.strip.sub(option_key, '').strip
        option_cols[val] = col
      elsif d.strip.start_with?(dep_key)
        val = d.strip.sub(dep_key, '').strip
        dependency_cols[val] = col
      end
    end
    if option_cols.size == 0
      register_error("No options found in #{@filename}.", @runner)
    end

    # Get all dependencies and their listed options
    dependency_options = {}
    dependency_cols.each do |dependency, col|
      dependency_options[dependency] = []
      rows.each do |row|
        dependency_options[dependency] << row[col]
      end
      dependency_options[dependency].uniq!
    end

    return rows, option_cols, dependency_cols, dependency_options, full_header, header
  end

  def cache_data
    # Caches data for faster tsv lookups
    rows_keys_s = {}
    @rows.each_with_index do |row, rownum|
      row_key_values = {}
      @dependency_cols.each do |dep, col|
        row_key_values[dep] = row[col]
      end

      if not rows_keys_s[row_key_values].nil?
        if not row_key_values.empty?
          register_error("Multiple rows found in #{@filename} with dependencies: #{hash_to_string(row_key_values)}.", @runner)
        else
          register_error("Multiple rows found in #{@filename}.", @runner)
        end
      end

      rows_keys_s[row_key_values] = rownum
    end
    return rows_keys_s
  end

  def get_option_name_from_sample_number(sample_value, dependency_values)
    # Retrieve option name from probability file based on sample value

    matched_option_name = nil
    matched_row_num = nil

    if dependency_values.nil?
      dependency_values = {}
    end

    rownum = @rows_keys_s[dependency_values]
    if rownum.nil?
      if not dependency_values.empty?
        register_error("Could not determine appropriate option in #{@filename} for sample value #{sample_value} with dependencies: #{hash_to_string(dependency_values)}.", @runner)
      else
        register_error("Could not determine appropriate option in #{@filename} for sample value #{sample_value}.", @runner)
      end
    end

    # Convert data to numeric row values
    rowvals = {}
    row = @rows[rownum]
    @option_cols.each do |option_name, option_col|
      if not row[option_col].is_number?
        register_error("Field '#{row[option_col]}' in #{@filename} must be numeric.", @runner)
      end
      rowvals[option_name] = row[option_col].to_f

      # Check positivity of the probability values
      if rowvals[option_name] < 0
        register_error("Probability value in #{@filename} is less than zero.", @runner)
      end
    end

    # Sum of values within 2% of 100%?
    sum_rowvals = rowvals.values.reduce(:+)
    if (sum_rowvals < 0.98) || (sum_rowvals > 1.02)
      register_error("Values in #{@filename} incorrectly sum to #{sum_rowvals}.", @runner)
    end

    # If values don't exactly sum to 1, normalize them
    if sum_rowvals != 1.0
      rowvals.each do |option_name, rowval|
        rowvals[option_name] = rowval / sum_rowvals
      end
    end

    # Find appropriate value
    rowsum = 0
    n_options = @option_cols.size
    @option_cols.keys.each_with_index do |option_name, index|
      rowsum += rowvals[option_name]
      next unless (rowsum >= sample_value) || ((index == n_options - 1) && (rowsum + 0.00001 >= sample_value))

      matched_option_name = option_name
      matched_row_num = rownum
      break
    end

    return matched_option_name, matched_row_num
  end
end

def get_parameters_ordered_from_options_lookup_tsv(lookup_csv_data, characteristics_dir = nil)
  # Obtain full list of parameters and their order
  params = []
  lookup_csv_data.each do |row|
    next if row.size < 2
    next if row[0].nil? || (row[0].downcase == 'parameter name') || row[1].nil?
    next if params.include?(row[0])

    if not characteristics_dir.nil?
      # skip this option if there is no tsv file provided
      tsvpath = File.join(characteristics_dir, row[0] + '.tsv')
      next if not File.exist?(tsvpath)
    end
    params << row[0]
  end

  return params
end

def get_options_for_parameter_from_options_lookup_tsv(lookup_csv_data, parameter_name)
  options = []
  lookup_csv_data.each do |row|
    next if row.size < 2
    next if row[0].nil? || (row[0].downcase == 'parameter name') || row[1].nil?
    next if row[0].downcase != parameter_name.downcase

    options << row[1]
  end

  return options
end

def get_combination_hashes(tsvfiles, dependencies)
  # Returns an array with hashes that include each combination of
  # dependency values for the given dependencies.
  combos_hashes = []

  # Construct array of dependency value arrays
  depval_array = []
  dependencies.each do |dep|
    depval_array << tsvfiles[dep].option_cols.keys
    depval_array[-1].delete('Void') # Dependency will never have Void option
  end

  if depval_array.size == 0
    return combos_hashes
  end

  # Create combinations
  combos = depval_array.first.product(*depval_array[1..-1])

  # Convert to combinations of hashes
  combos.each do |combo|
    # Convert to hash
    combo_hash = {}
    if combo.is_a?(String)
      combo_hash[dependencies[0]] = combo
    else
      dependencies.each_with_index do |dep, i|
        combo_hash[dep] = combo[i]
      end
    end
    combos_hashes << combo_hash
  end
  return combos_hashes
end

def get_value_from_workflow_step_value(step_value)
  variant_type = step_value.variantType
  if variant_type == 'Boolean'.to_VariantType
    return step_value.valueAsBoolean
  elsif variant_type == 'Double'.to_VariantType
    return step_value.valueAsDouble
  elsif variant_type == 'Integer'.to_VariantType
    return step_value.valueAsInteger
  elsif variant_type == 'String'.to_VariantType
    return step_value.valueAsString
  end
end

def get_value_from_runner(runner, key_lookup, error_if_missing = true)
  key_lookup = OpenStudio::toUnderscoreCase(key_lookup)
  runner.result.stepValues.each do |step_value|
    next if step_value.name != key_lookup

    return get_value_from_workflow_step_value(step_value)
  end
  if error_if_missing
    register_error("Could not find value for '#{key_lookup}'.", runner)
  end
end

def get_measure_args_from_option_names(lookup_csv_data, option_names, parameter_name, lookup_file, runner = nil)
  found_options = {}
  options_measure_args = {}
  option_names.each do |option_name|
    found_options[option_name] = false
    options_measure_args[option_name] = {}
  end
  current_option = nil

  lookup_csv_data.each do |row|
    next if row.size < 2

    # Found option row?
    if (not row[0].nil?) && (not row[1].nil?)
      current_option = nil # reset
      option_names.each do |option_name|
        next unless not option_name.nil?

        if (row[0].downcase == parameter_name.downcase) && (row[1] == option_name)
          current_option = option_name
          break
        end
      end
    end
    if not current_option.nil?
      found_options[current_option] = true
      if (row.size >= 3) && (not row[2].nil?)
        measure_dir = row[2]
        args = {}
        for col in 3..(row.size - 1)
          next if row[col].nil? || (not row[col].include?('='))

          data = row[col].split('=')
          arg_name = data[0]
          arg_val = data[1]
          args[arg_name] = arg_val
        end
        options_measure_args[current_option][measure_dir] = args
      end
    else
      break if found_options.values.all? { |elem| elem == true }
    end
  end

  errors = []
  option_names.each do |option_name|
    next unless not found_options[option_name]

    msg = "Could not find parameter '#{parameter_name}' and option '#{option_name}' in #{lookup_file}."
    if runner.nil?
      errors << msg
    else
      register_error(msg, runner)
    end
  end

  return options_measure_args, errors
end

def print_option_assignment(parameter_name, option_name, runner)
  runner.registerInfo("Assigning option '#{option_name}' for parameter '#{parameter_name}'.")
end

def register_value(runner, parameter_name, option_name)
  runner.registerValue(parameter_name, option_name)
end

def register_logs(runner, new_runner)
  # Register logs from measures called by meta measures
  new_runner.result.warnings.each do |warning|
    runner.registerWarning(warning.logMessage)
  end
  new_runner.result.info.each do |info|
    runner.registerInfo(info.logMessage)
  end
  new_runner.result.errors.each do |error|
    runner.registerError(error.logMessage)
  end
end

# Accepts string option_apply_logic and tries to evaluate it based on
# (parameter_name, option_name) pairs stored in runner.
#
# Returns a Boolean if evaluating and applying the logic is successful; nil
# otherwise. Returning true means that the building as defined in runner belongs
# to the downselect set (should be run); returning false means that this
# building has been filtered out.
def evaluate_logic(option_apply_logic, runner, past_results = true)
  # Convert to appropriate ruby statement for evaluation
  if option_apply_logic.count('(') != option_apply_logic.count(')')
    runner.registerError('Inconsistent number of open and close parentheses in logic.')
    return
  end

  values = Hash[runner.getPastStepValuesForMeasure('build_existing_model').collect { |k, v| [k.to_s, v] }]
  ruby_eval_str = ''
  option_apply_logic.split('||').each do |or_segment|
    or_segment.split('&&').each do |segment|
      segment.strip!
      segment.delete!("'")

      # Handle presence of open parentheses
      rindex = segment.rindex('(')
      if rindex.nil?
        rindex = 0
      else
        rindex += 1
      end
      segment_open = segment[0, rindex].gsub(' ', '')

      # Handle presence of exclamation point
      segment_equality = "'=='"
      if segment[rindex] == '!'
        segment_equality = "'!='"
        rindex += 1
      end

      # Handle presence of close parentheses
      lindex = segment.index(')')
      if lindex.nil?
        lindex = segment.size
      end
      segment_close = segment[lindex, segment.size - lindex].gsub(' ', '')

      segment_parameter, segment_option = segment[rindex, lindex - rindex].strip.split('|')

      # Get existing building option name for the same parameter
      if past_results
        segment_existing_option = values[OpenStudio::toUnderscoreCase(segment_parameter)]
      else
        segment_existing_option = get_value_from_runner(runner, segment_parameter)
      end
      segment_existing_option.delete!("'")

      ruby_eval_str += segment_open + "'" + segment_existing_option + segment_equality + segment_option + "'" + segment_close + ' and '
    end
    ruby_eval_str.chomp!(' and ')
    ruby_eval_str += ' or '
  end
  ruby_eval_str.chomp!(' or ')
  result = eval(ruby_eval_str)
  runner.registerInfo("Evaluating logic: #{option_apply_logic}.")
  runner.registerInfo("Converted to Ruby: #{ruby_eval_str}.")
  runner.registerInfo("Ruby Evaluation: #{result}.")
  if not [true, false].include?(result)
    runner.registerError("Logic was not successfully evaluated: #{ruby_eval_str}")
    return
  end
  return result
end

def get_data_for_sample(buildstock_csv_path, building_id, runner)
  buildstock_csv = CSV.open(buildstock_csv_path, headers: true)

  buildstock_csv.each do |row|
    next if row['Building'].to_i != building_id.to_i

    return row.to_hash
  end
  # If we got this far, couldn't find the sample #
  msg = "Could not find row for #{building_id} in #{buildstock_csv_path}."
  runner.registerError(msg)
  fail msg
end

def update_args_hash(hash, key, args)
  if not hash.keys.include? key
    hash[key] = [args]
  else # merge new arguments into existing
    args.each do |k, v|
      hash[key][0][k] = v
    end
  end
end

class RunOSWs
  require 'openstudio'
  require 'csv'
  require 'json'

  def self.run(in_osw, parent_dir, run_output, upgrade, measures, reporting_measures, measures_only = false)
    # Run workflow
    cli_path = OpenStudio.getOpenStudioCLI
    command = "\"#{cli_path}\" run"
    command += ' -m' if measures_only
    command += " -w \"#{in_osw}\""

    system(command, [:out, :err] => File::NULL)
    run_log = File.readlines(File.expand_path(File.join(parent_dir, 'run/run.log')))
    run_log.each do |line|
      next if line.include? 'Cannot find current Workflow Step'
      next if line.include? 'WorkflowStepResult value called with undefined stepResult'
      next if line.include? 'Appears there are no design condition fields in the EPW file'
      next if line.include? 'No valid weather file defined in either the osm or osw.'
      next if line.include? 'EPW file not found'
      next if line.include? "'UseWeatherFile' is selected in YearDescription, but there are no weather file set for the model."
      next if line.include? 'not within the expected limits' # Ignore EpwFile warnings
      next if line.include? 'Unable to find sql file at'

      # FIXME: should we investigate the following errors/warnings?
      next if line.include? 'No construction for either surface'
      next if line.include? 'Initial area of other surface'
      next if line.include?('Surface') && line.include?('is adiabatic, removing all sub surfaces')

      run_output += line
    end

    result_output = {}

    out = File.join(parent_dir, 'out.osw')
    out = File.expand_path(out)
    fail "Could not find '#{out}'." unless File.exist?(out)

    text = File.read(out)
    out = JSON.parse(text)

    started_at = out['started_at']
    completed_at = out['completed_at']
    completed_status = out['completed_status']
    eplusout_err = out['eplusout_err']

    data_point_out = File.join(parent_dir, 'run/data_point_out.json')

    return started_at, completed_at, completed_status, eplusout_err, result_output, run_output if !File.exist?(data_point_out)

    rows = {}
    text = File.read(File.expand_path(data_point_out))
    old_rows = JSON.parse(text)
    old_rows.each do |measure, values|
      rows[measure] = {}
      values.each do |arg, val|
        next if measure == 'BuildExistingModel' && arg == 'building_id'

        rows[measure]["#{OpenStudio::toUnderscoreCase(measure)}.#{arg}"] = val
      end
    end

    result_output = get_measure_results(rows, result_output, 'BuildExistingModel') if !upgrade
    result_output = get_measure_results(rows, result_output, 'ApplyUpgrade')
    measures.each do |measure|
      result_output = get_measure_results(rows, result_output, measure)
    end
    result_output = get_measure_results(rows, result_output, 'UpgradeCosts')
    result_output = get_measure_results(rows, result_output, 'ReportSimulationOutput')
    result_output = get_measure_results(rows, result_output, 'ReportUtilityBills')
    reporting_measures.each do |reporting_measure|
      result_output = get_measure_results(rows, result_output, reporting_measure)
    end

    return started_at, completed_at, completed_status, eplusout_err, result_output, run_output
  end

  def self.get_measure_results(rows, result, measure)
    if rows.keys.include?(measure)
      result = result.merge(rows[measure])
    end
    return result
  end

  def self.write_summary_results(results_dir, filename, results)
    if not File.exist?(results_dir)
      Dir.mkdir(results_dir)
    end
    csv_out = File.join(results_dir, filename)

    column_headers = []
    results.each do |result|
      result.keys.each do |col|
        column_headers << col unless column_headers.include?(col)
      end
    end
    column_headers = column_headers.sort

    ['eplusout_err', 'completed_status', 'completed_at', 'started_at', 'job_id', 'building_id'].each do |col|
      column_headers.delete(col)
      column_headers.insert(0, col)
    end

    CSV.open(csv_out, 'wb') do |csv|
      csv << column_headers
      results.sort_by { |h| h['building_id'] }.each do |result|
        csv_row = []
        column_headers.each do |column_header|
          csv_row << result[column_header]
        end
        csv << csv_row
      end
    end

    puts "Wrote: #{csv_out}"
    return csv_out
  end
end
