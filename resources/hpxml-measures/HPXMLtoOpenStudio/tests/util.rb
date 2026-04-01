# frozen_string_literal: true

def get_ems_values(ems_objects, name, parse_more_operators = false)
  values = {}
  ems_objects.each do |ems_object|
    next unless ems_object.name.to_s.include? Model.ems_friendly_name(name)

    ems_object.lines.each do |line|
      next unless line.downcase.start_with? 'set'

      lhs, rhs = line.split('=')
      lhs = lhs.gsub('Set', '').gsub('set', '').strip
      rhs = rhs.gsub(',', '').gsub(';', '').strip
      values[lhs] = [] if values[lhs].nil?
      # eg. "Q = Q + 1.5"
      rhs = handle_operator(rhs, parse_more_operators)
      values[lhs] << rhs
    end
  end
  return values
end

def handle_operator(rhs, parse_more_operators)
  # Doesn't consider "()"
  operators = parse_more_operators ? ['+', '-', '*', '/'] : ['+']
  operator = rhs.chars.find { |c| operators.include? c }
  if not operator.nil?
    rhs_split = rhs.split(operator).map { |s| s.tr('()', '') }
    rhs_f = handle_operator(rhs_split[1], parse_more_operators)
    lhs_f = rhs_split[0].to_f
    rhs_f = 1.0 if rhs_f == 0.0 && operator == '/' # avoid divide by zero
    lhs_f = 1.0 if lhs_f == 0.0 && operator == '*' # avoid multiply a variable name(string), couldn't identify if it's a real 0.0
    rhs_f = 1.0 if rhs_f == 0.0 && operator == '*' # avoid multiply a variable name(string), couldn't identify if it's a real 0.0
    return lhs_f.send(operator, rhs_f)
  else
    return rhs.to_f
  end
end
