# frozen_string_literal: true

require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/version'
require_relative '../resources/buildstock'
require_relative '../test/analysis'
require 'open3'
require 'openstudio'

class TestRunAnalysis < Minitest::Test
  def before_setup
    cli_path = OpenStudio.getOpenStudioCLI
    @command = "\"#{cli_path}\" workflow/run_analysis.rb"

    @buildstock_directory = File.join(File.dirname(__FILE__), '..')

    @testing_baseline = File.join(@buildstock_directory, 'testing_baseline')
    @national_baseline = File.join(@buildstock_directory, 'national_baseline')

    FileUtils.rm_rf(@testing_baseline)
    FileUtils.rm_rf(@national_baseline)
  end

  def test_version
    @command += ' -v'

    stdout_str, _stderr_str, _status = Open3.capture3(@command, unsetenv_others: true)

    assert_includes(stdout_str, "ResStock v#{Version::ResStock_Version}")
    assert_includes(stdout_str, "OpenStudio-HPXML v#{Version::OS_HPXML_Version}")
    assert_includes(stdout_str, "HPXML v#{Version::HPXML_Version}")
    assert_includes(stdout_str, "OpenStudio v#{OpenStudio.openStudioLongVersion}")
    assert_includes(stdout_str, "EnergyPlus v#{OpenStudio.energyPlusVersion}.#{OpenStudio.energyPlusBuildSHA}")
  end

  def test_errors_wrong_path
    yml = ' -y test/yml_bad_value/testing_baseline.yml'
    @command += yml

    stdout_str, _stderr_str, _status = Open3.capture3(@command, unsetenv_others: true)

    _assert_and_puts([stdout_str], "Error: YML file does not exist at 'test/yml_bad_value/testing_baseline.yml'.")
  end

  def test_no_yml_argument
    stdout_str, _stderr_str, _status = Open3.capture3(@command, unsetenv_others: true)

    _assert_and_puts([stdout_str], 'Error: YML argument is required. Call run_analysis.rb -h for usage.')
  end

  def test_errors_bad_value
    yml = ' -y test/tests_yml_files/yml_bad_value/testing_baseline.yml'
    @command += yml

    stdout_str, _stderr_str, _status = Open3.capture3(@command, unsetenv_others: true)

    _assert_and_puts([stdout_str], 'Failures detected for: 1, 2.')

    cli_output_log = File.readlines(File.join(@testing_baseline, 'cli_output.log'))
    _assert_and_puts(cli_output_log, 'ERROR')
    _assert_and_puts(cli_output_log, 'Run Period End Day of Month (32) must be one of')
  end

  def test_errors_already_exists
    yml = ' -y test/tests_yml_files/yml_bad_value/testing_baseline.yml'
    @command += yml

    Open3.capture3(@command, unsetenv_others: true)
    stdout_str, _stderr_str, _status = Open3.capture3(@command, unsetenv_others: true)

    _assert_and_puts([stdout_str], "Error: Output directory 'testing_baseline' already exists.")
  end

  def test_errors_downselect_resample
    yml = ' -y test/tests_yml_files/yml_resample/testing_baseline.yml'
    @command += yml

    stdout_str, _stderr_str, _status = Open3.capture3(@command, unsetenv_others: true)

    _assert_and_puts([stdout_str], "Error: Not supporting residential_quota_downselect's 'resample' at this time.")
  end

  def test_errors_weather_files
    yml = ' -y test/tests_yml_files/yml_weather_files/testing_baseline.yml'
    @command += yml

    FileUtils.rm_rf(File.join(File.dirname(__FILE__), '../weather'))
    assert(!File.exist?(File.join(File.dirname(__FILE__), '../weather')))
    stdout_str, _stderr_str, _status = Open3.capture3(@command, unsetenv_others: true)

    _assert_and_puts([stdout_str], "Error: Must include 'weather_files_url' or 'weather_files_path' in yml.")
    assert(!File.exist?(File.join(File.dirname(__FILE__), '../weather')))
  end

  def test_errors_downsampler
    yml = ' -y test/tests_yml_files/yml_downsampler/testing_baseline.yml'
    @command += yml

    stdout_str, _stderr_str, _status = Open3.capture3(@command, unsetenv_others: true)

    _assert_and_puts([stdout_str], "Error: Sampler type 'residential_quota_downsampler' is invalid or not supported.")
  end

  def test_errors_missing_key
    yml = ' -y test/tests_yml_files/yml_missing_key/testing_baseline.yml'
    @command += yml

    stdout_str, _stderr_str, _status = Open3.capture3(@command, unsetenv_others: true)

    _assert_and_puts([stdout_str], "Error: Both 'build_existing_model' and 'simulation_output_report' must be included in yml.")
  end

  def test_errors_precomputed_outdated_missing_parameter
    yml = ' -y test/tests_yml_files/yml_precomputed_outdated/testing_baseline_missing.yml'
    @command += yml

    system(@command)
    cli_output = File.readlines(File.join(@testing_baseline, 'cli_output.log'))

    _assert_and_puts(cli_output, 'Mismatch between buildstock.csv and options_lookup.tsv. Missing parameters: HVAC Cooling Partial Space Conditioning.')
  end

  def test_errors_precomputed_outdated_extra_parameter
    yml = ' -y test/tests_yml_files/yml_precomputed_outdated/testing_baseline_extra.yml'
    @command += yml

    system(@command)
    cli_output = File.readlines(File.join(@testing_baseline, 'cli_output.log'))

    _assert_and_puts(cli_output, 'Mismatch between buildstock.csv and options_lookup.tsv. Extra parameters: Extra Parameter.')
  end

  def test_errors_invalid_upgrade_name
    yml = ' -y test/tests_yml_files/yml_valid/test_upgrade_name.yml'
    @command += yml
    @command += ' -u "Fuondation Type" -u Walls'

    stdout_str, _stderr_str, _status = Open3.capture3(@command, unsetenv_others: true)

    _assert_and_puts([stdout_str], 'Error: At least one invalid upgrade_name was specified: Fuondation Type. Valid choices are: Baseline, Windows, Walls, Sheathing, Foundation Type.')
  end

  def test_measures_only
    yml = ' -y test/tests_yml_files/yml_valid/testing_baseline.yml'
    @command += yml
    @command += ' -m'

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(!File.exist?(File.join(@testing_baseline, 'run1', 'eplusout.sql')))
  end

  def test_sampling_only
    yml = ' -y test/tests_yml_files/yml_valid/testing_baseline.yml'
    @command += yml
    @command += ' -s'

    system(@command)

    assert(!File.exist?(File.join(@testing_baseline, 'testing_baseline-Baseline.osw')))
    assert(!File.exist?(File.join(@testing_baseline, 'run1')))
    assert(File.exist?(File.join(@testing_baseline, 'buildstock.csv')))
  end

  def test_building_id
    yml = ' -y test/tests_yml_files/yml_valid/testing_baseline.yml'
    @command += yml
    @command += ' -i 1'

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(!File.exist?(File.join(@testing_baseline, 'run2')))
  end

  def test_upgrade_name
    yml = ' -y test/tests_yml_files/yml_valid/test_upgrade_name.yml'
    @command += yml
    @command += ' -u "Foundation Type" -u Walls'
    system(@command)

    test_upgrade_name = File.join(@buildstock_directory, 'test_upgrade_name')

    _test_measure_order(File.join(test_upgrade_name, 'test_upgrade_name-FoundationType.osw'))
    assert(File.exist?(File.join(test_upgrade_name, 'results-FoundationType.csv')))
    _test_measure_order(File.join(test_upgrade_name, 'test_upgrade_name-Walls.osw'))
    assert(File.exist?(File.join(test_upgrade_name, 'results-Walls.csv')))
    assert(!File.exist?(File.join(test_upgrade_name, 'results-Baseline.csv')))
  end

  def test_threads_and_keep_run_folders
    yml = ' -y test/tests_yml_files/yml_valid/testing_baseline.yml'
    @command += yml
    @command += ' -n 1'
    @command += ' -k'

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(File.exist?(File.join(@testing_baseline, 'run2')))
  end

  def test_relative_weather_files_path
    yml = ' -y test/tests_yml_files/yml_relative_weather_path/testing_baseline.yml'
    @command += yml

    FileUtils.rm_rf(File.join(File.dirname(__FILE__), '../weather'))
    assert(!File.exist?(File.join(File.dirname(__FILE__), '../weather')))

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(File.exist?(File.join(@testing_baseline, 'run2')))

    FileUtils.rm_rf(File.join(File.dirname(__FILE__), '../weather'))
    assert(!File.exist?(File.join(File.dirname(__FILE__), '../weather')))
  end

  def test_precomputed
    yml = ' -y test/tests_yml_files/yml_precomputed/testing_baseline.yml'
    @command += yml

    system(@command)

    cli_output_log = File.join(@testing_baseline, 'cli_output.log')
    assert(File.exist?(cli_output_log))
    cli_output = File.readlines(cli_output_log)
    _assert_and_puts(cli_output, 'ERROR', false)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(File.exist?(File.join(@testing_baseline, 'run2')))
    assert(!File.exist?(File.join(@testing_baseline, 'run3')))

    results_baseline = File.join(@testing_baseline, 'results-Baseline.csv')
    assert(File.exist?(results_baseline))
    results = CSV.read(results_baseline, headers: true)
    assert(results.headers.include?('build_existing_model.sample_weight'))
    assert_in_delta(results['build_existing_model.sample_weight'][0].to_f, 110000000 / 2, 0.001)
    assert_in_delta(results['build_existing_model.sample_weight'][1].to_f, 110000000 / 2, 0.001)
  end

  def test_precomputed_sample_weight
    yml = ' -y test/tests_yml_files/yml_precomputed_weight/testing_baseline.yml'
    @command += yml

    system(@command)

    cli_output_log = File.join(@testing_baseline, 'cli_output.log')
    assert(File.exist?(cli_output_log))
    cli_output = File.readlines(cli_output_log)
    _assert_and_puts(cli_output, 'ERROR', false)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(File.exist?(File.join(@testing_baseline, 'run2')))
    assert(!File.exist?(File.join(@testing_baseline, 'run3')))

    results_baseline = File.join(@testing_baseline, 'results-Baseline.csv')
    assert(File.exist?(results_baseline))
    results = CSV.read(results_baseline, headers: true)
    assert(results.headers.include?('build_existing_model.sample_weight'))
    assert_in_delta(results['build_existing_model.sample_weight'][0].to_f, 226.2342, 0.001)
    assert_in_delta(results['build_existing_model.sample_weight'][1].to_f, 1.000009, 0.001)
  end

  def test_testing_baseline
    yml = ' -y project_testing/testing_baseline.yml'
    @command += yml
    @command += ' -k'

    system(@command)

    cli_output_log = File.join(@testing_baseline, 'cli_output.log')
    assert(File.exist?(cli_output_log))
    cli_output = File.readlines(cli_output_log)
    _assert_and_puts(cli_output, 'ERROR', false)
    _verify_outputs(cli_output_log)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    results_baseline = File.join(@testing_baseline, 'results-Baseline.csv')
    assert(File.exist?(results_baseline))
    results = CSV.read(results_baseline, headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@testing_baseline, 'run1', 'run')))
    contents = Dir[File.join(@testing_baseline, 'run1', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, true)

    timeseries = _get_timeseries_columns(Dir[File.join(@testing_baseline, 'run*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))

    assert(File.exist?(File.join(@testing_baseline, 'osw', 'Baseline', '1.osw')))
    assert(File.exist?(File.join(@testing_baseline, 'xml', 'Baseline', '1.xml')))

    des = File.join(@buildstock_directory, 'project_testing/testing_baseline')
    Dir.mkdir(des)
    FileUtils.cp(results_baseline, des)
  end

  def test_national_baseline
    yml = ' -y project_national/national_baseline.yml'
    @command += yml
    @command += ' -k'

    system(@command)

    cli_output_log = File.join(@national_baseline, 'cli_output.log')
    assert(File.exist?(cli_output_log))
    cli_output = File.readlines(cli_output_log)
    _assert_and_puts(cli_output, 'ERROR', false)
    _verify_outputs(cli_output_log)

    _test_measure_order(File.join(@national_baseline, 'national_baseline-Baseline.osw'))
    results_baseline = File.join(@national_baseline, 'results-Baseline.csv')
    assert(File.exist?(results_baseline))
    results = CSV.read(results_baseline, headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@national_baseline, 'run1', 'run')))
    contents = Dir[File.join(@national_baseline, 'run1', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false)

    timeseries = _get_timeseries_columns(Dir[File.join(@national_baseline, 'run*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries))

    assert(!File.exist?(File.join(@national_baseline, 'osw', 'Baseline', '1.osw')))
    assert(File.exist?(File.join(@national_baseline, 'xml', 'Baseline', '1.xml')))

    des = File.join(@buildstock_directory, 'project_national/national_baseline')
    Dir.mkdir(des)
    FileUtils.cp(results_baseline, des)
  end

  private

  def _test_measure_order(osw)
    expected_order = ['BuildExistingModel',
                      'ApplyUpgrade',
                      'HPXMLtoOpenStudio',
                      'UpgradeCosts',
                      'ReportSimulationOutput',
                      'ReportUtilityBills',
                      'QOIReport',
                      'ServerDirectoryCleanup']
    json = JSON.parse(File.read(osw), symbolize_names: true)
    actual_order = json[:steps].collect { |k, _v| k[:measure_dir_name] }.uniq
    expected_order &= actual_order # subset expected_order to what's in actual_order
    assert_equal(expected_order, actual_order)
  end

  def _assert_and_puts(output, msg, expect = true)
    includes = output.select { |o| o.include?(msg) }.size > 0
    if !includes && expect
      puts output
      assert(includes)
    elsif includes && !expect
      puts output
      assert(!includes)
    end
  end

  def _verify_outputs(cli_output_log)
    # Check cli_output.log warnings
    File.readlines(cli_output_log).each do |message|
      next if message.strip.empty?
      next if message.include?('Building ID:')

      # Expected warnings
      next if _expected_warning_message(message, 'The model contains existing objects and is being reset.')
      next if _expected_warning_message(message, 'HVAC setpoints have been automatically adjusted to prevent periods where the heating setpoint is greater than the cooling setpoint.')
      next if _expected_warning_message(message, 'It is not possible to eliminate all HVAC energy use (e.g. crankcase/defrost energy) in EnergyPlus during an unavailable period.')
      next if _expected_warning_message(message, 'It is not possible to eliminate all DHW energy use (e.g. water heater parasitics) in EnergyPlus during an unavailable period.')
      next if _expected_warning_message(message, 'It is not possible to eliminate all HVAC energy use (e.g. crankcase/defrost energy) in EnergyPlus outside of an HVAC season.')
      next if _expected_warning_message(message, 'No space heating specified, the model will not include space heating energy use. [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]')
      next if _expected_warning_message(message, 'No space cooling specified, the model will not include space cooling energy use. [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]')
      next if _expected_warning_message(message, 'No clothes washer specified, the model will not include clothes washer energy use. [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]')
      next if _expected_warning_message(message, 'No clothes dryer specified, the model will not include clothes dryer energy use. [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]')
      next if _expected_warning_message(message, 'No dishwasher specified, the model will not include dishwasher energy use. [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]')
      next if _expected_warning_message(message, 'No refrigerator specified, the model will not include refrigerator energy use. [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]')
      next if _expected_warning_message(message, 'No cooking range specified, the model will not include cooking range/oven energy use. [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]')
      next if _expected_warning_message(message, "Foundation type of 'AboveApartment' cannot have a non-zero height. Assuming height is zero.")
      next if _expected_warning_message(message, 'Could not find state average propane rate based on')
      next if _expected_warning_message(message, 'Could not find state average fuel oil rate based on')
      next if _expected_warning_message(message, "Specified incompatible corridor; setting corridor position to 'Single Exterior (Front)'.")
      next if _expected_warning_message(message, 'DistanceToTopOfWindow is greater than 12 feet; this may indicate incorrect units. [context: /HPXML/Building/BuildingDetails/Enclosure/Windows/Window/Overhangs[number(Depth) > 0]')
      next if _expected_warning_message(message, 'Not calculating emissions because an electricity filepath for at least one emissions scenario could not be located.') # these are AK/HI samples
      next if _expected_warning_message(message, 'Could not find State=AK') # these are AK samples
      next if _expected_warning_message(message, 'No EPW design conditions found; calculating design conditions from EPW weather data.')
      next if _expected_warning_message(message, 'The garage pitch was changed to accommodate garage ridge >= house ridge')
      next if _expected_warning_message(message, 'Could not find County=') # we intentionally leave some fields blank in resources/data/simple_rates/County.tsv
      next if _expected_warning_message(message, 'Battery without PV specified, and no charging/discharging schedule provided; battery is assumed to operate as backup and will not be modeled.')
      next if _expected_warning_message(message, "Request for output variable 'Zone People Occupant Count' returned no results.")
      next if _expected_warning_message(message, 'No windows specified, the model will not include window heat transfer. [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]')
      next if _expected_warning_message(message, 'No interior lighting specified, the model will not include interior lighting energy use. [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]')
      next if _expected_warning_message(message, 'No exterior lighting specified, the model will not include exterior lighting energy use. [context: /HPXML/Building/BuildingDetails, id: "MyBuilding"]')
      next if _expected_warning_message(message, 'Home with unconditioned basement/crawlspace foundation type has both foundation wall insulation and floor insulation.')
      next if _expected_warning_message(message, 'Cooling capacity should typically be greater than or equal to 1000 Btu/hr. [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="room air conditioner" or CoolingSystemType="packaged terminal air conditioner"]')
      next if _expected_warning_message(message, 'Cooling capacity should typically be greater than or equal to 1000 Btu/hr. [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="central air conditioner"]')
      next if _expected_warning_message(message, 'Cooling capacity should typically be greater than or equal to 1000 Btu/hr. [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="mini-split"]')
      next if _expected_warning_message(message, 'Heating capacity should typically be greater than or equal to 1000 Btu/hr. [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Fireplace]')
      next if _expected_warning_message(message, 'Heating capacity should typically be greater than or equal to 1000 Btu/hr. [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/SpaceHeater]')
      next if _expected_warning_message(message, 'Backup heating capacity should typically be greater than or equal to 1000 Btu/hr. [context: /HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[BackupType="integrated" or BackupSystemFuel]')
      next if _expected_warning_message(message, 'driving hours could not be met due to insufficient vehicle charge. This issue may result from a combination EV battery parameters, charging power, and driving or discharging schedules')
      next if _expected_warning_message(message, 'do not match the hours per week calculated from the discharging schedule')
      next if _expected_warning_message(message, 'Unknown column found in schedule file: peak_period')
      next if _expected_warning_message(message, 'Unknown column found in schedule file: pre_peak_period')
      next if _expected_warning_message(message, "Could not find row='peak_period' in unavailable_periods.csv")
      next if _expected_warning_message(message, "Could not find row='pre_peak_period' in unavailable_periods.csv")

      # For the EV minutes warning try replacing the number of minutes as a string rather than a number.
      new_message = message.gsub(/\(([^)]+)\)/) { |match| $1.match?(/^\d+(\.\d+)?$/) ? '(<number of minutes>)' : match }
      new_message = new_message.gsub(/Only \d+ minutes was used/, 'Only <minutes value> minutes was used')
      next if _expected_warning_message(new_message, 'Insufficient away minutes (<number of minutes>) for required driving minutes (<number of minutes>)Only <minutes value> minutes was used.')

      flunk "Unexpected cli_output.log message found: #{message}"
    end
  end

  def _expected_warning_message(message, txt)
    return true if message.include?('WARN') && message.include?(txt)

    return false
  end
end
