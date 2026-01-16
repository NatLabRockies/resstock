# frozen_string_literal: true

def download_epws
  require_relative 'resources/hpxml-measures/HPXMLtoOpenStudio/resources/util'

  weather_dir = File.join(File.dirname(__FILE__), 'weather')
  FileUtils.mkdir(weather_dir) if !File.exist?(weather_dir)

  require 'tempfile'
  tmpfile = Tempfile.new('epw')

  UrlResolver.fetch('https://data.nrel.gov/system/files/156/Buildstock_TMY3_FIPS-1678817889.zip', tmpfile)

  puts 'Extracting weather files...'
  require 'zip'
  Zip.on_exists_proc = true
  Zip::File.open(tmpfile.path.to_s) do |zip_file|
    zip_file.each do |f|
      zip_file.extract(f, File.join(weather_dir, f.name))
    end
  end

  num_epws_actual = Dir[File.join(weather_dir, '*.epw')].count
  puts "#{num_epws_actual} weather files are available in the weather directory."
  puts 'Completed.'
  exit!
end

command_list = [
  :update_measures,
  :update_resources,
  :integrity_check_national,
  :integrity_check_testing,
  :download_weather,
  :unit_tests
]

def display_usage(command_list)
  puts "Usage: openstudio #{File.basename(__FILE__)} [COMMAND]\nCommands:\n  " + command_list.join("\n  ")
end

if ARGV.size == 0
  puts 'ERROR: Missing command.'
  display_usage(command_list)
  exit!
elsif ARGV.size > 1
  puts 'ERROR: Too many commands.'
  display_usage(command_list)
  exit!
elsif not command_list.include? ARGV[0].to_sym
  puts "ERROR: Invalid command '#{ARGV[0]}'."
  display_usage(command_list)
  exit!
end

if ARGV[0].to_sym == :update_measures
  # Apply rubocop (uses .rubocop.yml)
  commands = ["\"require 'rubocop/rake_task' \"",
              "\"require 'stringio' \"",
              "\"RuboCop::RakeTask.new(:rubocop) do |t| t.options = ['--autocorrect-all', '--format', 'simple'] end\"",
              '"Rake.application[:rubocop].invoke"']
  command = "#{OpenStudio.getOpenStudioCLI} -e #{commands.join(' -e ')}"
  puts 'Applying rubocop auto-correct to measures...'
  system(command)

  # Update a ResStockArguments/ResStockArgumentsPostHPXML/AddSharedSystem resources file
  # when the BuildResidentialHPXML/BuildResidentialScheduleFile measure changes.
  # This will ensure that their measure.xml is appropriately updated.
  # Without this, the measure has no differences and so OpenStudio
  # would skip updating it.
  hexdigest = ''
  [File.join(File.dirname(__FILE__), 'resources/hpxml-measures/BuildResidentialHPXML/measure.rb'),
   File.join(File.dirname(__FILE__), 'resources/hpxml-measures/BuildResidentialHPXML/measure.rb')].each do |measure_rb_path|
    hexdigest += Digest::MD5.file(measure_rb_path).hexdigest
  end
  ['ResStockArguments', 'ResStockArgumentsPostHPXML', 'AddSharedSystem'].each do |resstock_measure_name|
    measure_txt_path = File.join(File.dirname(__FILE__), "measures/#{resstock_measure_name}/resources/measure.txt")
    File.write(measure_txt_path, hexdigest)
  end

  # Likewise for SimulationOutput, update a resource file
  # when the ReportSimulationOutput/ReportUtilityBills measure changes.
  hexdigest = ''
  [File.join(File.dirname(__FILE__), 'resources/hpxml-measures/ReportSimulationOutput/measure.rb'),
   File.join(File.dirname(__FILE__), 'resources/hpxml-measures/ReportUtilityBills/measure.rb')].each do |measure_rb_path|
    hexdigest += Digest::MD5.file(measure_rb_path).hexdigest
  end
  ['SimulationOutput'].each do |resstock_measure_name|
    measure_txt_path = File.join(File.dirname(__FILE__), "measures/#{resstock_measure_name}/resources/measure.txt")
    File.write(measure_txt_path, hexdigest)
  end

  # Update measures XMLs
  puts 'Updating measure.xmls...'
  Dir['measures/**/measure.xml'].each do |measure_xml|
    measure_dir = File.dirname(measure_xml)
    command = "#{OpenStudio.getOpenStudioCLI} measure -u '#{measure_dir}'"
    system(command, [:out, :err] => File::NULL)
  end

  puts 'Done.'
end

if ARGV[0].to_sym == :update_resources
  prefix = 'resources/hpxml-measures'
  repository = 'https://github.com/NREL/OpenStudio-HPXML.git'
  branch_or_tag = 'master'

  system("git subtree pull --prefix #{prefix} #{repository} #{branch_or_tag} --squash")
end

if ARGV[0].to_sym == :integrity_check_national
  require_relative 'test/integrity_checks'

  project_dir_name = 'project_national'
  integrity_check(project_dir_name)
  integrity_check_options_lookup_tsv(project_dir_name)
end

if ARGV[0].to_sym == :integrity_check_testing
  require_relative 'test/integrity_checks'

  project_dir_name = 'project_testing'
  integrity_check(project_dir_name)
  integrity_check_options_lookup_tsv(project_dir_name)
end

if ARGV[0].to_sym == :download_weather
  download_epws
end

if ARGV[0].to_sym == :unit_tests
  tests_rbs = Dir['project_*/tests/*.rb'] + Dir['test/test_integrity_checks.rb'] + Dir['measures/*/tests/*.rb']

  # Run tests in random order; we don't want them to only
  # work when run in a specific order
  tests_rbs.shuffle!

  # Ensure we run all tests even if there are failures
  failed_tests = []
  tests_rbs.each do |test_rb|
    success = system("#{OpenStudio.getOpenStudioCLI} #{test_rb}")
    failed_tests << test_rb unless success
  end

  puts
  puts

  if not failed_tests.empty?
    puts 'The following tests FAILED:'
    failed_tests.each do |failed_test|
      puts "- #{failed_test}"
    end
    exit! 1
  end

  puts 'All tests passed.'
end
