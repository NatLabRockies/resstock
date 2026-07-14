# frozen_string_literal: true

# Downselect jsons found at https://gdr.openei.org/files/1325/g-function_library_1.0.zip.
# See https://data.openei.org/submissions/7442 for more information.
#
# @param filepath [String] temporary file path to store downloaded g-function config json files
# @return [Integer] total number of g-function config json files generated
def process_g_functions(filepath)
  require 'json'
  require 'zip'

  g_functions_path = File.dirname(filepath)
  Dir[File.join(filepath, '*.json')].each do |config_json|
    file = File.open(config_json)
    config_json = File.basename(config_json)
    puts "Processing #{config_json}..."
    json = JSON.load(file)

    # It's possible that multiple m_n keys exist for a given config/boreholes combo.
    # So, we are choosing the "most square" m_n for each config/boreholes combo.
    json2 = {}
    case config_json
    when 'rectangle_5m_v1.0.json'
      add_m_n(json, json2, 1, '1_1')
      add_m_n(json, json2, 2, '1_2')
      add_m_n(json, json2, 3, '1_3')
      add_m_n(json, json2, 4, '2_2')
      add_m_n(json, json2, 5, '1_5')
      add_m_n(json, json2, 6, '2_3')
      add_m_n(json, json2, 7, '1_7')
      add_m_n(json, json2, 8, '2_4')
      add_m_n(json, json2, 9, '3_3')
      add_m_n(json, json2, 10, '2_5')
      add_m_n(json, json2, 11, '1_11')
      add_m_n(json, json2, 12, '3_4')
      add_m_n(json, json2, 13, '1_13')
      add_m_n(json, json2, 14, '2_7')
      add_m_n(json, json2, 15, '3_5')
      add_m_n(json, json2, 40, '5_8') # test case
    when 'L_configurations_5m_v1.0.json'
      add_m_n(json, json2, 4, '2_3')
      add_m_n(json, json2, 5, '3_3')
      add_m_n(json, json2, 6, '3_4')
      add_m_n(json, json2, 7, '4_4')
      add_m_n(json, json2, 8, '4_5')
      add_m_n(json, json2, 9, '5_5')
      add_m_n(json, json2, 10, '5_6')
      add_m_n(json, json2, 11, '6_6')
      add_m_n(json, json2, 12, '6_7')
      add_m_n(json, json2, 13, '7_7')
      add_m_n(json, json2, 14, '7_8')
      add_m_n(json, json2, 15, '8_8')
    when 'C_configurations_5m_v1.0.json' # has key2
      add_m_n(json, json2, 7, '3_3', '1')
      add_m_n(json, json2, 9, '3_4', '1')
      add_m_n(json, json2, 11, '4_4', '1')
      add_m_n(json, json2, 13, '4_5', '1')
      add_m_n(json, json2, 14, '5_5', '2')
      add_m_n(json, json2, 15, '5_5', '1')
    when 'LopU_configurations_5m_v1.0.json'
      add_m_n(json, json2, 6, '3_3', '1')
      add_m_n(json, json2, 7, '3_4', '2')
      add_m_n(json, json2, 8, '3_4', '1')
      add_m_n(json, json2, 9, '4_4', '1')
      add_m_n(json, json2, 10, '3_5', '1')
      add_m_n(json, json2, 11, '4_5', '1')
      add_m_n(json, json2, 12, '5_5', '1')
      add_m_n(json, json2, 13, '5_6', '2')
      add_m_n(json, json2, 14, '5_6', '1')
      add_m_n(json, json2, 15, '6_6', '1')
    when 'Open_configurations_5m_v1.0.json' # has key2
      add_m_n(json, json2, 8, '3_3', '1')
      add_m_n(json, json2, 10, '3_4', '1')
      add_m_n(json, json2, 12, '4_4', '1')
      add_m_n(json, json2, 14, '4_5', '1')
    when 'U_configurations_5m_v1.0.json' # has key2
      add_m_n(json, json2, 7, '3_3', '1')
      add_m_n(json, json2, 9, '3_4', '1')
      add_m_n(json, json2, 10, '4_4', '1')
      add_m_n(json, json2, 11, '3_5', '1')
      add_m_n(json, json2, 12, '4_5', '1')
      add_m_n(json, json2, 13, '5_5', '1')
      add_m_n(json, json2, 14, '4_6', '1')
      add_m_n(json, json2, 15, '3_7', '1')
    when 'zoned_rectangle_5m_v1.0.json'
      # requires larger number of boreholes and is unusual for residential application, skip it
    else
      fail "Unrecognized config_json: #{config_json}"
    end
    next if json2.empty?

    configpath = File.join(g_functions_path, File.basename(config_json))
    File.open(configpath, 'w') do |f|
      json = JSON.pretty_generate(json2)
      f.write(json)
    end
  end

  FileUtils.rm_rf(filepath)

  num_configs_actual = Dir[File.join(g_functions_path, '*.json')].count

  return num_configs_actual
end

# Update a json hash with configurations of interest and check that number of boreholes are what we'd expect.
#
# @param json [Hash] the downloaded g-function config hash
# @param json2 [Hash] the hash being populated with configurations of interest
# @param expected_num_boreholes [Integer] expected number of boreholes for a config/boreholes combo
# @param m_n [String] keys from the config files where m is borehole "columns" and n is borehole "rows"
# @param key2 [String] additional key some configs use to access specific configurations
# @return [nil]
def add_m_n(json, json2, expected_num_boreholes, m_n, key2 = nil)
  if key2.nil?
    actual_num_boreholes = json[m_n]['bore_locations'].size
    fail "#{expected_num_boreholes} vs #{actual_num_boreholes}" if expected_num_boreholes != actual_num_boreholes

    json2.update({ m_n => json[m_n] })
  else
    actual_num_boreholes = json[m_n][key2]['bore_locations'].size
    fail "#{expected_num_boreholes} vs #{actual_num_boreholes}" if expected_num_boreholes != actual_num_boreholes

    if !json2[m_n].nil?
      json2[m_n].update({ key2 => json[m_n][key2] })
    else
      json2.update({ m_n => { key2 => json[m_n][key2] } })
    end
  end
end
