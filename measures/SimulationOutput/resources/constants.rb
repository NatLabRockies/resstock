# frozen_string_literal: true

module Constants
  # Exclude scaling these ReportSimulationOutput outputs
  ReportSimulationOutputUnchangeds = [
    'Unmet Hours',
    'HVAC Design Temperature',
    'Temperature',
    'Humidity Ratio',
    'Relative Humidity',
    'Dewpoint Temperature',
    'Radiant Temperature',
    'Operative Temperature',
    'Weather',
    'HVAC Geothermal Loop'
  ]
end
