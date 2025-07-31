# frozen_string_literal: true

# Returns the list of option names specified in the given TSV resource file.
#
# @param tsv_file_name [String] Name of the TSV resource file
# @return [OpenStudio::StringVector] List of option names
def get_option_names(tsv_file_name)
  csv_data = get_csv_data_for_tsv_file(tsv_file_name)
  option_names = OpenStudio::StringVector.new
  csv_data.map { |row| row['Option Name'] }.each do |option_name|
    break if option_name.nil?

    option_names << option_name
  end
  return option_names
end

# Updates the args hash with key-value detailed properties for the
# given option name and TSV resource file.
#
# @param args [Hash] Map of :argument_name => value
# @param tsv_file_name [String] Name of the TSV resource file
# @param option_name [String] Name of the option in the TSV resource file
# @return [nil]
def get_option_properties(args, tsv_file_name, option_name)
  return if option_name.nil?

  csv_data = get_csv_data_for_tsv_file(tsv_file_name)

  csv_data.each do |row|
    next if row['Option Name'] != option_name

    # Match, add detailed properties to args hash
    row.each do |key, value|
      next if key == 'Option Name'

      if key.include? '[' # strip units
        key = key[0..key.index('[') - 1].strip
      end
      tsv_name = File.basename(tsv_file_name, File.extname(tsv_file_name))
      final_key = "#{tsv_name}_#{key.downcase.gsub(' ', '_').gsub('-', '_')}".to_sym

      if not args[final_key].nil?
        fail "Duplicate value assigned to #{key}."
      end

      args[final_key] = value
    end
    return
  end

  fail "Unexpected error: Could not look up #{option_name} in #{tsv_file_name}."
end

# Reads the data (or retrieves the cached data) from the given TSV resource file.
# Uses a global variable so the data is only read once.
#
# @return [CSV::Table] CSV data for the TSV file
def get_csv_data_for_tsv_file(tsv_file_name)
  if $csv_data.nil?
    $csv_data = {}
  end

  if $csv_data[tsv_file_name].nil?
    tsv_dir = File.join(File.dirname(__FILE__), 'options')
    $csv_data[tsv_file_name] = CSV.read(File.join(tsv_dir, tsv_file_name), col_sep: "\t", headers: true)

    # Automatically determine column data types from values
    column_datatype = {}
    $csv_data[tsv_file_name][0].headers.each do |key|
      datatypes = []
      $csv_data[tsv_file_name].each do |row|
        next if row[key].nil? || row[key].empty?

        begin
          val = Float(row[key])
          if val % 1 == 0
            datatypes << 'integer'
          else
            datatypes << 'float'
          end
        rescue
          if ['TRUE', 'FALSE'].include? row[key].upcase
            datatypes << 'boolean'
          else
            datatypes << 'string'
          end
        end
      end
      if datatypes.uniq.sort == ['float', 'integer']
        column_datatype[key] = 'float'
      elsif datatypes.uniq.size != 1
        column_datatype[key] = 'string'
      else
        column_datatype[key] = datatypes.uniq[0]
      end
    end

    # Convert data to appropriate data Types
    $csv_data[tsv_file_name].each do |row|
      row.each do |key, value|
        next if row[key].nil? || row[key].empty?

        case column_datatype[key]
        when 'integer'
          row[key] = Integer(Float(value))
        when 'float'
          row[key] = Float(value)
        when 'boolean'
          row[key] = { 'TRUE' => true, 'FALSE' => false }[value.upcase]
        end
      end
    end
  end

  return $csv_data[tsv_file_name]
end
