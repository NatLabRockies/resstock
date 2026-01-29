# frozen_string_literal: true

# Collection of helper methods related to XML validation.
module XMLValidator
  # Gets an OpenStudio::XMLValidator object for the supplied XSD schema or Schematron path.
  #
  # @param schema_or_schematron_path [String] Path to the XSD schema or Schematron file
  # @return [OpenStudio::XMLValidator] OpenStudio XMLValidator object
  def self.get_xml_validator(schema_or_schematron_path)
    return OpenStudio::XMLValidator.new(schema_or_schematron_path)
  end

  # Validates an HPXML file against a XSD schema file.
  #
  # @param hpxml_path [String] Path to the HPXML file
  # @param validator [OpenStudio::XMLValidator] OpenStudio XMLValidator object
  # @return [Array<Array<String>, Array<String>>] list of error messages, list of warning messages
  def self.validate_against_schema(hpxml_path, validator)
    errors, warnings = [], []
    validator.validate(hpxml_path)
    validator.errors.each do |e|
      next unless e.logMessage.count(':') >= 2

      # Clean up message
      msg_txt = e.logMessage.split(':')[2..-1].join(':').strip
      msg_txt = msg_txt.gsub("{#{HPXML::NameSpace}}", '').gsub("\n", '')
      errors.append(msg_txt)
    end
    warnings += validator.warnings.map { |w| w.logMessage }
    return errors, warnings
  end

  # Validates an HPXML file against a Schematron file.
  #
  # @param hpxml_path [String] Path to the HPXML file
  # @param validator [OpenStudio::XMLValidator] OpenStudio XMLValidator object
  # @param hpxml_element [Oga::XML::Element] Root XML element of the HPXML document
  # @return [Array<Array<String>, Array<String>>] list of error messages, list of warning messages
  def self.validate_against_schematron(hpxml_path, validator, hpxml_element)
    errors, warnings = [], []
    validator.validate(hpxml_path)
    if validator.fullValidationReport.is_initialized
      report_doc = Oga.parse_xml(validator.fullValidationReport.get)

      # Parse validation report for user-friendly errors/warnings
      current_context = nil
      current_context_idx = 0
      XMLHelper.get_elements(report_doc, '//svrl:schematron-output/svrl:*').each do |n|
        if n.name == 'fired-rule'
          # Keep track of current context
          new_context = XMLHelper.get_attribute_value(n, 'context')
          if new_context == current_context
            current_context_idx += 1
          else
            current_context = new_context
            current_context_idx = 0
          end
        elsif n.name == 'failed-assert' || n.name == 'successful-report'
          # Error
          msg_txt = XMLHelper.get_value(n, 'svrl:text', :string)

          # Try to retrieve SystemIdentifier
          context_element = hpxml_element.xpath(current_context.gsub('h:', ''))[current_context_idx]
          if context_element.nil?
            fail "Could not find element at xpath '#{current_context}' with index #{current_context_idx}."
          end

          element_id = get_element_id(context_element)
          if element_id.nil?
            # Keep checking parent elements
            context_element.each_ancestor do |parent_element|
              element_id = get_element_id(parent_element)
              break unless element_id.nil?
            end
          end
          element_id_string = ", id: \"#{element_id}\"" unless element_id.nil?

          full_msg = "#{msg_txt} [context: #{current_context.gsub('h:', '')}#{element_id_string}]"
          if n.name == 'failed-assert'
            errors.append(full_msg)
          elsif n.name == 'successful-report'
            warnings.append(full_msg)
          end
        end
      end
    end
    return errors, warnings
  end

  # Gets the ID of the specified HPXML element
  #
  # @param element [Oga::XML::Element] XML element of interest
  # @return [String] ID of the HPXML element
  def self.get_element_id(element)
    if element.name.to_s == 'Building'
      return XMLHelper.get_attribute_value(XMLHelper.get_element(element, 'BuildingID'), 'id')
    else
      return XMLHelper.get_attribute_value(XMLHelper.get_element(element, 'SystemIdentifier'), 'id')
    end
  end
end
