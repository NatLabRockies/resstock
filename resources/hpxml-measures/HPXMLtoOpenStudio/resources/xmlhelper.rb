# frozen_string_literal: true

# Collection of helper methods related to XML reading/writing.
module XMLHelper
  # Adds the child element with 'element_name' and sets its value. If the value
  # has been defaulted, the dataSource='software' attribute will be assigned to
  # the element.
  #
  # @param parent [Oga::XML::Element] Parent element for the addition
  # @param element_name [String] Name of the element to add
  # @param value [*] The value for the element (could be a string, float, boolean, etc.)
  # @param datatype [Symbol] Datatype of the element (:integer, :float, :boolean, or :string)
  # @param defaulted [Boolean] Whether the value has been defaulted by OS-HPXML
  # @return [Oga::XML::Element] The added element
  def self.add_element(parent, element_name, value = nil, datatype = nil, defaulted = false)
    added = XMLHelper.insert_element(parent, element_name, -1, value, datatype, defaulted)
    return added
  end

  # Inserts the child element with 'element_name' and sets its value. If the value
  # has been defaulted, the dataSource='software' attribute will be assigned to
  # the element.
  #
  # @param parent [Oga::XML::Element] Parent element for the insertion
  # @param element_name [String] Name of the element to insert
  # @param index [Integer] The position of the element to be inserted
  # @param value [*] The value for the element (could be a string, float, boolean, etc.)
  # @param datatype [Symbol] Datatype of the element (:integer, :float, :boolean, or :string)
  # @param defaulted [Boolean] Whether the value has been defaulted by OS-HPXML
  # @return [Oga::XML::Element] The inserted element
  def self.insert_element(parent, element_name, index = 0, value = nil, datatype = nil, defaulted = false)
    added = Oga::XML::Element.new(name: element_name)
    if index == -1
      parent.children << added
    else
      parent.children.insert(index, added)
    end
    if not value.nil?
      case datatype
      when :integer
        value = to_integer(value, parent, element_name)
      when :float
        value = to_float(value, parent, element_name)
      when :boolean
        value = to_boolean(value, parent, element_name)
      else
        if datatype != :string
          # If value provided, datatype required
          fail 'Unexpected datatype.'
        end
      end
      added.inner_text = value.to_s
    end
    if defaulted
      XMLHelper.add_attribute(added, 'dataSource', 'software')
    end
    return added
  end

  # Adds the child element with 'element_name' to a single extension element and
  # sets its value. If the extension element already exists, it will be reused.
  #
  # @param parent [Oga::XML::Element] Parent element for the insertion
  # @param element_name [String] Name of the extension element to add
  # @param value [*] The value for the element (could be a string, float, boolean, etc.)
  # @param datatype [Symbol] Datatype of the element (:integer, :float, :boolean, or :string)
  # @param defaulted [Boolean] Whether the value has been defaulted by OS-HPXML
  # @return [Oga::XML::Element] The added extension element
  def self.add_extension(parent, element_name, value = nil, datatype = nil, defaulted = false)
    extension = XMLHelper.create_elements_as_needed(parent, ['extension'])
    return XMLHelper.add_element(extension, element_name, value, datatype, defaulted)
  end

  # Creates a hierarchy of elements under the parent element based on the supplied
  # list of element names. If a given child element already exists, it is reused.
  #
  # @param parent [Oga::XML::Element] Parent element for the insertion
  # @param element_names element_name [String] Name of the element to add
  # @return [Oga::XML::Element] The final created element
  def self.create_elements_as_needed(parent, element_names)
    this_parent = parent
    element_names.each do |element_name|
      if XMLHelper.get_element(this_parent, element_name).nil?
        XMLHelper.add_element(this_parent, element_name)
      end
      this_parent = XMLHelper.get_element(this_parent, element_name)
    end
    return this_parent
  end

  # Deletes the child element with element_name.
  #
  # @param parent [Oga::XML::Element] Parent element for the insertion
  # @param element_name [String] Name of the element to delete
  # @return [Oga::XML::Element] The deleted element
  def self.delete_element(parent, element_name)
    element = nil
    while !parent.at_xpath(element_name).nil?
      last_element = element
      element = parent.at_xpath(element_name).remove
    end
    return last_element
  end

  # Gets the value of 'element_name' in the parent element or nil.
  #
  # @param parent [Oga::XML::Element] Parent element for the insertion
  # @param element_name [String] Name of the element to get the value of
  # @param datatype [Symbol] Datatype of the element (:integer, :float, :boolean, or :string)
  # @return [* or nil] The value of the element in the specified datatype
  def self.get_value(parent, element_name, datatype)
    element = parent.at_xpath(element_name)
    if element.nil?
      return
    end

    value = element.text

    case datatype
    when :integer
      value = to_integer_or_nil(value, parent, element_name)
    when :float
      value = to_float_or_nil(value, parent, element_name)
    when :boolean
      value = to_boolean_or_nil(value, parent, element_name)
    else
      if datatype != :string
        fail 'Unexpected datatype.'
      end
    end

    return value
  end

  # Gets the value(s) of 'element_name' in the parent element or [].
  # Use for elements that can occur multiple times.
  #
  # @param parent [Oga::XML::Element] Parent element for the insertion
  # @param element_name [String] Name of the element to get the values of
  # @param datatype [Symbol] Datatype of the element (:integer, :float, :boolean, or :string)
  # @return [Array<*>] Array of values in the specified datatype
  def self.get_values(parent, element_name, datatype)
    values = []
    parent.xpath(element_name).each do |value|
      value = value.text

      case datatype
      when :integer
        value = to_integer_or_nil(value, parent, element_name)
      when :float
        value = to_float_or_nil(value, parent, element_name)
      when :boolean
        value = to_boolean_or_nil(value, parent, element_name)
      else
        if datatype != :string
          fail 'Unexpected datatype.'
        end
      end

      values << value
    end

    return values
  end

  # Gets the element with 'element_name' in the parent element.
  #
  # @param parent [Oga::XML::Element] Parent element for the insertion
  # @param element_name [String] Name of the element to get
  # @return [Oga::XML::Element] The element of interest
  def self.get_element(parent, element_name)
    return parent.at_xpath(element_name)
  end

  # Gets the elements with 'element_name' in the parent element.
  # Use for elements that can occur multiple times.
  #
  # @param parent [Oga::XML::Element] Parent element for the insertion
  # @param element_name [String] Name of the elements to get
  # @return [Array<Oga::XML::Element>] The elements of interest
  def self.get_elements(parent, element_name)
    return parent.xpath(element_name)
  end

  # Gets the name of the first child element of the 'element_name'
  # element on the parent element.
  #
  # @param parent [Oga::XML::Element] Parent element for the insertion
  # @param element_name [String] Name of the element with the child element to get
  # @return [String or nil] Name of the child element, or nil if no child element
  def self.get_child_name(parent, element_name)
    element = parent.at_xpath(element_name)
    return if element.nil? || element.children.nil?

    element.children.each do |child|
      next unless child.is_a? Oga::XML::Element

      return child.name
    end
  end

  # Checks whether the element has a child element with 'element_name'.
  #
  # @param parent [Oga::XML::Element] Parent element for the insertion
  # @param element_name [String] Name of the element to check for the presence of
  # @return [Boolean] True if the element exists
  def self.has_element(parent, element_name)
    element = parent.at_xpath(element_name)
    return !element.nil?
  end

  # Adds an attribute to the specified element.
  #
  # @param element [Oga::XML::Element] Element to add the attribute to
  # @param attr_name [String] Name of the attribute
  # @param attr_val [*] Value for the attribute
  # @return [nil]
  def self.add_attribute(element, attr_name, attr_val)
    element.set(attr_name, attr_val)
  end

  # Gets the value of the specified attribute for the given element.
  #
  # @param element [Oga::XML::Element] Element with the attribute whose value we want
  # @param attr_name [String] Name of the attribute
  # @return [String or nil] The value of the attribute, or nil if not found
  def self.get_attribute_value(element, attr_name)
    return if element.nil?

    return element.get(attr_name)
  end

  # Deletes the specified attribute for the given element.
  #
  # @param element [Oga::XML::Element] Element with the attribute we want to delete
  # @param attr_name [String] Name of the attribute
  # @return [nil]
  def self.delete_attribute(element, attr_name)
    return if element.nil?

    element.unset(attr_name)
  end

  # Creates an empty XML document.
  #
  # @return [Oga::XML::Document] The new XML document
  def self.create_doc()
    xml_declaration = Oga::XML::XmlDeclaration.new(version: '1.0', encoding: 'UTF-8')
    doc = Oga::XML::Document.new(xml_declaration: xml_declaration) # Oga.parse_xml
    return doc
  end

  # Obtains the XML document for the XML file at the specified path.
  #
  # @param hpxml_path [String] Path to the HPXML file
  # @param hpxml_path [String] Contents of the HPXML file if already available
  # @return [Oga::XML::Document] The XML document
  def self.parse_file(hpxml_path, hpxml_contents: nil)
    if hpxml_contents.nil?
      hpxml_contents = File.read(hpxml_path)
    end
    hpxml_doc = Oga.parse_xml(hpxml_contents)
    return hpxml_doc
  end

  # Returns the final string representation of the XML document -- i.e., one that is
  # ready to be written to a file.
  #
  # @param doc [Oga::XML::Document] Oga XML Document object
  # @return [String] The final string representation
  def self.finalize_doc_string(doc)
    doc_s = doc.to_xml.delete("\r")

    # Manually apply pretty-printing (indentation and newlines)
    # Can remove if https://gitlab.com/yorickpeterse/oga/-/issues/75 is implemented
    curr_pos = 1
    level = -1
    indents = {}
    while true
      open_pos = doc_s.index('<', curr_pos)
      close_pos = nil
      if not open_pos.nil?
        close_pos1 = doc_s.index('</', curr_pos)
        close_pos2 = doc_s.index('/>', curr_pos)
        close_pos1 = Float::MAX if close_pos1.nil?
        close_pos2 = Float::MAX if close_pos2.nil?
        close_pos = [close_pos1, close_pos2].min
      end
      break if open_pos.nil? && close_pos.nil?

      if close_pos <= open_pos
        indents[close_pos] = level if doc_s[close_pos - 1] == '>'
        level -= 1
        curr_pos = close_pos + 1
      elsif open_pos < close_pos
        level += 1
        indents[open_pos] = level unless level == 0
        curr_pos = open_pos + 1
      end
    end
    indents.reverse_each do |pos, level|
      next if doc_s[pos - 1] == ' '

      doc_s.insert(pos, "\n#{'  ' * level}")
    end
    # Retain REXML-styling
    doc_s.gsub!('"', "'")
    doc_s.gsub!(' />', '/>')
    doc_s.gsub!(' ?>', '?>')
    doc_s.gsub!('&quot;', '"')

    return doc_s
  end

  # Writes the XML file for the given XML document and returns the final
  # string representation of the XML document.
  #
  # @param doc [Oga::XML::Document] Oga XML Document object
  # @param hpxml_path [String] Path to the HPXML file
  # @return [String] The final string representation
  def self.write_file(doc, hpxml_path)
    doc_s = finalize_doc_string(doc)

    # Write XML file
    if not Dir.exist? File.dirname(hpxml_path)
      FileUtils.mkdir_p(File.dirname(hpxml_path))
    end
    File.open(hpxml_path, 'w', newline: :crlf) do |f|
      f << doc_s
    end

    return doc_s
  end
end

# Converts a value to float; throws an error if it can't be converted.
#
# @param value [*] The value in any datatype (float, integer, string)
# @param parent [Oga::XML::Element] Parent element for the error message
# @param element_name [String] Name of the element for the error message
# @return [Double] The value converted to double
def to_float(value, parent, element_name)
  begin
    return Float(value)
  rescue
    fail "Cannot convert '#{value}' to float for #{parent.name}/#{element_name}."
  end
end

# Converts a value to integer; throws an error if it can't be converted.
#
# @param value [*] The value in any datatype (float, integer, string)
# @param parent [Oga::XML::Element] Parent element for the error message
# @param element_name [String] Name of the element for the error message
# @return [Integer] The value converted to integer
def to_integer(value, parent, element_name)
  begin
    value = Float(value)
  rescue
    fail "Cannot convert '#{value}' to integer for #{parent.name}/#{element_name}."
  end
  if value % 1 == 0
    return Integer(value)
  else
    fail "Cannot convert '#{value}' to integer for #{parent.name}/#{element_name}."
  end
end

# Converts a value to boolean; throws an error if it can't be converted.
#
# @param value [*] The value in any datatype (float, integer, string)
# @param parent [Oga::XML::Element] Parent element for the error message
# @param element_name [String] Name of the element for the error message
# @return [Boolean] The value converted to boolean
def to_boolean(value, parent, element_name)
  if value.is_a? TrueClass
    return true
  elsif value.is_a? FalseClass
    return false
  elsif (value.downcase.to_s == 'true') || (value == '1') || (value == 1)
    return true
  elsif (value.downcase.to_s == 'false') || (value == '0') || (value == 0)
    return false
  end

  fail "Cannot convert '#{value}' to boolean for #{parent.name}/#{element_name}."
end

# Converts a value to float or returns nil if nil provided; throws an error if it can't be converted.
#
# @param value [*] The value in any datatype (float, integer, string)
# @param parent [Oga::XML::Element] Parent element for the error message
# @param element_name [String] Name of the element for the error message
# @return [Double or nil] The value converted to double, or nil
def to_float_or_nil(value, parent, element_name)
  return if value.nil?

  return to_float(value, parent, element_name)
end

# Converts a value to integer or returns nil if nil provided; throws an error if it can't be converted.
#
# @param value [*] The value in any datatype (float, integer, string)
# @param parent [Oga::XML::Element] Parent element for the error message
# @param element_name [String] Name of the element for the error message
# @return [Integer] The value converted to integer, or nil
def to_integer_or_nil(value, parent, element_name)
  return if value.nil?

  return to_integer(value, parent, element_name)
end

# Converts a value to boolean or returns nil if nil provided; throws an error if it can't be converted.
#
# @param value [*] The value in any datatype (float, integer, string)
# @param parent [Oga::XML::Element] Parent element for the error message
# @param element_name [String] Name of the element for the error message
# @return [Boolean] The value converted to boolean
def to_boolean_or_nil(value, parent, element_name)
  return if value.nil?

  return to_boolean(value, parent, element_name)
end
