# frozen_string_literal: true

require_relative '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../test/integrity_checks'

class TestProjectNational < Minitest::Test
  def test_housing_characteristics
    begin
      project_dir_name = File.basename(File.dirname(File.dirname(__FILE__)))
      integrity_check(project_dir_name)
      integrity_check_options_lookup_tsv(project_dir_name)
    rescue Exception => e
      flunk e

      # Need a backtrace? Uncomment below
      # flunk "#{e}\n#{e.backtrace.join('\n')}"
    end
  end
end
