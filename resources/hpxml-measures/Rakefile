# frozen_string_literal: true

# This file is only used to run all tests and collect results on the CI.
# All rake tasks have been moved to tasks.rb.

require 'rake'
require 'rake/testtask'

desc 'Run all tests'
Rake::TestTask.new('test_all') do |t|
  t.test_files = Dir['*/tests/*.rb']
  t.warning = false
  t.verbose = true
end

desc 'Run measure unit tests'
Rake::TestTask.new('test_measures') do |t|
  t.test_files = Dir['*/tests/*.rb'] - Dir['workflow/tests/*.rb']
  t.warning = false
  t.verbose = true
end

desc 'Run workflow1 tests'
Rake::TestTask.new('test_workflow1') do |t|
  t.test_files = Dir['workflow/tests/test_simulations1.rb']
  t.warning = false
  t.verbose = true
end

desc 'Run workflow2 tests'
Rake::TestTask.new('test_workflow2') do |t|
  t.test_files = Dir['workflow/tests/*.rb'] - Dir['workflow/tests/test_simulations1.rb']
  t.warning = false
  t.verbose = true
end
