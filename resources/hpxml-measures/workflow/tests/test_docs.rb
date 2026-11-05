# frozen_string_literal: true

require 'pathname'
require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'

class DocumentationTest < Minitest::Test
  def test_code_documentation
    errors = []

    here = File.dirname(__FILE__)
    root_path = File.absolute_path(File.join(here, '..', '..'))
    Dir.glob("#{here}/../../**/*.rb").each do |rb_path|
      rb_path = File.absolute_path(rb_path)
      rb_name = File.basename(rb_path)
      next if rb_path.split(File::SEPARATOR).include?('tests') || rb_name == 'minitest_helper.rb'
      next if rb_name == 'tasks.rb'
      next if rb_name == 'run_simulation.rb'

      rel_path = Pathname.new(rb_path).relative_path_from root_path

      rb_lines = File.readlines(rb_path)
      methods = parse_methods_from_lines(rb_lines)

      puts "[#{rel_path}] Checking #{methods.size} methods..."

      methods.each do |method|
        # Skip overloaded ruby methods that don't need to be documented
        next if ['method_missing',
                 'create_method',
                 'create_attr'].include? method[:name]

        # Skip OpenStudio measure methods that don't need to be documented
        if rb_name == 'measure.rb'
          next if ['name',
                   'description',
                   'modeler_description',
                   'arguments',
                   'run'].include? method[:name]
        end

        # Uncomment to debug:
        # puts "[#{rel_path}] Checking method #{method[:name]}()..."
        # puts "  args=(#{method[:args].join(', ')})"

        # Construct array of expected docs
        expected_docs = []
        method[:args].each do |arg|
          expected_docs << "# @param #{arg}"
        end
        if method[:name] != 'initialize' # No return documentation needed for constructor methods
          expected_docs << '# @return'
        end

        # Construct array of actual docs
        actual_docs = []
        line_idx = method[:start_line] - 2
        while line_idx >= 0 && rb_lines[line_idx].strip.start_with?('#')
          if rb_lines[line_idx].include? '# @return'
            actual_docs << '# @return'
          elsif rb_lines[line_idx].include? '# @param'
            actual_param = rb_lines[line_idx].strip.split(' ')[2]
            actual_docs << "# @param #{actual_param}"
          end
          line_idx -= 1
        end
        actual_docs.reverse!

        # Compare arrays
        next unless expected_docs != actual_docs

        if expected_docs == []
          expected_docs_s = '<nothing>'
        else
          expected_docs_s = expected_docs.join("\n      ")
        end
        if actual_docs == []
          actual_docs_s = '<nothing>'
        else
          actual_docs_s = actual_docs.join("\n      ")
        end
        errors << "  [#{rel_path}, method=#{method[:name]}, line=#{method[:start_line]}] Expected code docs with:\n      #{expected_docs_s}\n  but found:\n      #{actual_docs_s}"
      end
    end

    if not errors.empty?
      puts
      puts "#{errors.size} ERRORS found:\n\n"
      errors.each do |error|
        puts "#{error}\n\n"
      end
    end

    assert_equal(0, errors.size)
  end

  def extract_def_signature(lines, start_idx)
    sig = +''
    paren_depth = 0
    started_parens = false

    i = start_idx
    while i < lines.length
      code = lines[i].sub(/#.*$/, '') # naive comment strip
      sig << code

      code.each_char do |ch|
        if ch == '('
          paren_depth += 1
          started_parens = true
        elsif ch == ')'
          paren_depth -= 1 if paren_depth > 0
        end
      end

      if started_parens
        break if paren_depth == 0
      else
        # no paren-style args: signature is just this line
        break
      end

      i += 1
    end

    return [sig, i] # return signature and ending line index
  end

  def parse_def_signature(sig)
    # Get method name and arg string
    startpos = sig.index('(')
    if startpos.nil?
      name, raw_args = sig.strip.sub(/\Adef\s+/, '').split(/\s+/, 2)
      raw_args ||= ''
      name = name.gsub('self.', '')
    else
      endpos = sig.rindex(')')
      raw_args = sig[startpos + 1..endpos - 1]
      name = sig[0..startpos - 1].split(' ')[-1].gsub('self.', '')
    end

    # Strip out any text between pairs of chars
    # E.g., "a, b = [1,2]"  =>  "a, b = "
    char_pairs = [['(', ')'],
                  ['[', ']'],
                  ["'", "'"]]
    char_pairs.each do |char_pair|
      start_char, end_char = char_pair
      while raw_args.include?(start_char) && raw_args.include?(end_char)
        startpos = raw_args.index(start_char)
        endpos = raw_args[startpos + 1..-1].index(end_char) + startpos + 1
        raw_args = raw_args[0..startpos - 1] + raw_args[endpos + 1..-1]
      end
    end

    args =
      if raw_args.empty?
        []
      else
        raw_args.gsub(/\s+/, ' ').strip.split(/\s*,\s*/)
      end

    final_args = []
    args.each do |arg|
      next if ['**', '*args', '**kwargs'].include? arg

      while arg.start_with? '*'
        arg = arg[1..-1]
      end

      if arg.include? ':'
        final_args << arg.split(':')[0].strip
      elsif arg.include? '='
        final_args << arg.split('=')[0].strip
      else
        final_args << arg
      end
    end

    return { name: name, args: final_args }
  end

  def parse_methods_from_lines(lines)
    methods = []
    i = 0

    while i < lines.length
      if lines[i] =~ /^\s*def\s+/
        sig, end_idx = extract_def_signature(lines, i)
        parsed = parse_def_signature(sig)
        methods << parsed.merge(start_line: i + 1, end_line: end_idx + 1) if parsed
        i = end_idx + 1
      else
        i += 1
      end
    end

    return methods
  end
end
