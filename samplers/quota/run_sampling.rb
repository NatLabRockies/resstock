# frozen_string_literal: true

# Performs sampling technique and generates CSV file with parameter options for each building.

# The file has to follow general Ruby conventions.
# File name must for the snake case (underscore case) of the class name. For example: WorkerInit = worker_init

require 'optparse'
require_relative 'run_sampling_lib'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -p project_name -n num_datapoints -o outfile\n e.g., #{File.basename(__FILE__)} -p project_national -n 10000 -o buildstock.csv"

  opts.on('-p', '--project <STRING>', 'Project Name') do |t|
    options[:project] = t
  end

  opts.on('-n', '--num-datapoints <INTEGER>', 'Number of datapoints') do |t|
    options[:numdps] = t.to_i
  end

  opts.on('-o', '--output <STRING>', 'Output file name') do |t|
    options[:outfile] = t
  end

  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end
end.parse!

if (not options[:project]) || (not options[:numdps]) || (not options[:outfile])
  fail "ERROR: All 3 arguments are required. Call #{File.basename(__FILE__)} -h for usage."
end

r = RunSampling.new

t0 = Time.now
r.run(options[:project], options[:numdps], options[:outfile])
t1 = Time.now

puts "Sampling took: #{((t1 - t0) / 60.0).round(1)} minutes."
