# frozen_string_literal: true

# Collection of methods related to software versions.
module Version
  OS_HPXML_Version = '1.10.0' # Version of the OS-HPXML workflow
  OS_Version = '3.9.0' # Required version of OpenStudio (can be 'X.X' or 'X.X.X')
  HPXML_Version = '4.0' # HPXML schemaVersion

  # Checks whether the version of OpenStudio that is running OpenStudio-HPXML
  # meets the version requirements; throws an error if not.
  #
  # @return [nil]
  def self.check_openstudio_version
    if not OpenStudio.openStudioVersion.start_with? OS_Version
      if OS_Version.count('.') == 2
        fail "OpenStudio version #{OS_Version} is required. Found version: #{OpenStudio.openStudioVersion}"
      else
        fail "OpenStudio version #{OS_Version}.X is required. Found version: #{OpenStudio.openStudioVersion}"
      end
    end
  end

  # Checks whether the version of the HPXML file running through OpenStudio-HPXML
  # meets the version requirements; throws an error if not.
  #
  # @param hpxml_version [String] Version of HPXML input file
  # @return [nil]
  def self.check_hpxml_version(hpxml_version)
    if hpxml_version != HPXML_Version
      fail "HPXML version #{HPXML_Version} is required."
    end
  end
end
