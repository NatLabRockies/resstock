# frozen_string_literal: true

module Constants
  NumApplyUpgradeOptions = 100
  NumApplyUpgradesCostsPerOption = 2
  DuctRestrictionAssumedAirflow = 400.0 # Per Jon W, the recommended airflow for most heat pumps; it's also the max cfm/ton airflow rate for typical DX equipment (per hvac_sizing.rb).

  CostMultiplierChoices = [
    '',
    'Fixed (1)',
    'Wall Area, Above-Grade, Conditioned (ft^2)',
    'Wall Area, Above-Grade, Exterior (ft^2)',
    'Wall Area, Below-Grade (ft^2)',
    'Floor Area, Conditioned (ft^2)',
    'Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)',
    'Floor Area, Lighting (ft^2)',
    'Floor Area, Foundation (ft^2)',
    'Floor Area, Attic (ft^2)',
    'Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)',
    'Roof Area (ft^2)',
    'Window Area (ft^2)',
    'Door Area (ft^2)',
    'Duct Unconditioned Surface Area (ft^2)',
    'Rim Joist Area, Above-Grade, Exterior (ft^2)',
    'Slab Perimeter, Exposed, Conditioned (ft)',
    'Size, Heating System Primary (kBtu/h)',
    'Size, Heating System Secondary (kBtu/h)',
    'Size, Cooling System Primary (kBtu/h)',
    'Size, Heat Pump Backup Primary (kBtu/h)',
    'Size, Water Heater (gal)',
    'Flow Rate, Mechanical Ventilation (cfm)'
  ]
end
