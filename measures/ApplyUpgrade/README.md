
###### (Automatically generated documentation)

# Apply Upgrade

## Description
Measure that applies an upgrade (one or more child measures) to a building model based on the specified logic.

Determines if the upgrade should apply to a given building model. If so, calls one or more child measures with the appropriate arguments.

## Arguments


**Upgrade Name**

User-specificed name that describes the upgrade.

- **Name:** ``upgrade_name``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Project Directory**

The directory containing the housing characteristics folder (e.g., project_national).

- **Name:** ``project_directory``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Option 1**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_1``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Option 1 Apply Logic**

Logic that specifies if the Option 1 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_1_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 1 Cost 1 Value**

Total option 1 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_1_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 1 Cost 1 Multiplier**

Total option 1 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_1_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 1 Cost 2 Value**

Total option 1 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_1_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 1 Cost 2 Multiplier**

Total option 1 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_1_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 1 Lifetime**

The option lifetime.

- **Name:** ``option_1_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 2**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_2``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 2 Apply Logic**

Logic that specifies if the Option 2 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_2_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 2 Cost 1 Value**

Total option 2 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_2_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 2 Cost 1 Multiplier**

Total option 2 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_2_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 2 Cost 2 Value**

Total option 2 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_2_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 2 Cost 2 Multiplier**

Total option 2 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_2_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 2 Lifetime**

The option lifetime.

- **Name:** ``option_2_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 3**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_3``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 3 Apply Logic**

Logic that specifies if the Option 3 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_3_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 3 Cost 1 Value**

Total option 3 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_3_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 3 Cost 1 Multiplier**

Total option 3 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_3_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 3 Cost 2 Value**

Total option 3 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_3_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 3 Cost 2 Multiplier**

Total option 3 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_3_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 3 Lifetime**

The option lifetime.

- **Name:** ``option_3_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 4**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_4``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 4 Apply Logic**

Logic that specifies if the Option 4 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_4_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 4 Cost 1 Value**

Total option 4 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_4_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 4 Cost 1 Multiplier**

Total option 4 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_4_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 4 Cost 2 Value**

Total option 4 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_4_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 4 Cost 2 Multiplier**

Total option 4 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_4_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 4 Lifetime**

The option lifetime.

- **Name:** ``option_4_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 5**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_5``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 5 Apply Logic**

Logic that specifies if the Option 5 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_5_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 5 Cost 1 Value**

Total option 5 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_5_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 5 Cost 1 Multiplier**

Total option 5 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_5_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 5 Cost 2 Value**

Total option 5 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_5_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 5 Cost 2 Multiplier**

Total option 5 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_5_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 5 Lifetime**

The option lifetime.

- **Name:** ``option_5_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 6**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_6``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 6 Apply Logic**

Logic that specifies if the Option 6 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_6_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 6 Cost 1 Value**

Total option 6 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_6_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 6 Cost 1 Multiplier**

Total option 6 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_6_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 6 Cost 2 Value**

Total option 6 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_6_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 6 Cost 2 Multiplier**

Total option 6 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_6_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 6 Lifetime**

The option lifetime.

- **Name:** ``option_6_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 7**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_7``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 7 Apply Logic**

Logic that specifies if the Option 7 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_7_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 7 Cost 1 Value**

Total option 7 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_7_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 7 Cost 1 Multiplier**

Total option 7 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_7_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 7 Cost 2 Value**

Total option 7 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_7_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 7 Cost 2 Multiplier**

Total option 7 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_7_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 7 Lifetime**

The option lifetime.

- **Name:** ``option_7_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 8**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_8``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 8 Apply Logic**

Logic that specifies if the Option 8 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_8_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 8 Cost 1 Value**

Total option 8 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_8_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 8 Cost 1 Multiplier**

Total option 8 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_8_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 8 Cost 2 Value**

Total option 8 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_8_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 8 Cost 2 Multiplier**

Total option 8 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_8_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 8 Lifetime**

The option lifetime.

- **Name:** ``option_8_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 9**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_9``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 9 Apply Logic**

Logic that specifies if the Option 9 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_9_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 9 Cost 1 Value**

Total option 9 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_9_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 9 Cost 1 Multiplier**

Total option 9 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_9_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 9 Cost 2 Value**

Total option 9 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_9_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 9 Cost 2 Multiplier**

Total option 9 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_9_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 9 Lifetime**

The option lifetime.

- **Name:** ``option_9_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 10**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_10``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 10 Apply Logic**

Logic that specifies if the Option 10 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_10_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 10 Cost 1 Value**

Total option 10 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_10_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 10 Cost 1 Multiplier**

Total option 10 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_10_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 10 Cost 2 Value**

Total option 10 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_10_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 10 Cost 2 Multiplier**

Total option 10 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_10_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 10 Lifetime**

The option lifetime.

- **Name:** ``option_10_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 11**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_11``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 11 Apply Logic**

Logic that specifies if the Option 11 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_11_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 11 Cost 1 Value**

Total option 11 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_11_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 11 Cost 1 Multiplier**

Total option 11 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_11_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 11 Cost 2 Value**

Total option 11 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_11_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 11 Cost 2 Multiplier**

Total option 11 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_11_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 11 Lifetime**

The option lifetime.

- **Name:** ``option_11_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 12**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_12``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 12 Apply Logic**

Logic that specifies if the Option 12 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_12_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 12 Cost 1 Value**

Total option 12 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_12_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 12 Cost 1 Multiplier**

Total option 12 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_12_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 12 Cost 2 Value**

Total option 12 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_12_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 12 Cost 2 Multiplier**

Total option 12 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_12_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 12 Lifetime**

The option lifetime.

- **Name:** ``option_12_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 13**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_13``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 13 Apply Logic**

Logic that specifies if the Option 13 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_13_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 13 Cost 1 Value**

Total option 13 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_13_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 13 Cost 1 Multiplier**

Total option 13 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_13_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 13 Cost 2 Value**

Total option 13 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_13_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 13 Cost 2 Multiplier**

Total option 13 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_13_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 13 Lifetime**

The option lifetime.

- **Name:** ``option_13_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 14**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_14``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 14 Apply Logic**

Logic that specifies if the Option 14 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_14_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 14 Cost 1 Value**

Total option 14 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_14_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 14 Cost 1 Multiplier**

Total option 14 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_14_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 14 Cost 2 Value**

Total option 14 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_14_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 14 Cost 2 Multiplier**

Total option 14 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_14_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 14 Lifetime**

The option lifetime.

- **Name:** ``option_14_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 15**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_15``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 15 Apply Logic**

Logic that specifies if the Option 15 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_15_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 15 Cost 1 Value**

Total option 15 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_15_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 15 Cost 1 Multiplier**

Total option 15 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_15_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 15 Cost 2 Value**

Total option 15 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_15_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 15 Cost 2 Multiplier**

Total option 15 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_15_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 15 Lifetime**

The option lifetime.

- **Name:** ``option_15_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 16**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_16``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 16 Apply Logic**

Logic that specifies if the Option 16 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_16_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 16 Cost 1 Value**

Total option 16 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_16_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 16 Cost 1 Multiplier**

Total option 16 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_16_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 16 Cost 2 Value**

Total option 16 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_16_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 16 Cost 2 Multiplier**

Total option 16 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_16_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 16 Lifetime**

The option lifetime.

- **Name:** ``option_16_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 17**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_17``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 17 Apply Logic**

Logic that specifies if the Option 17 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_17_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 17 Cost 1 Value**

Total option 17 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_17_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 17 Cost 1 Multiplier**

Total option 17 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_17_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 17 Cost 2 Value**

Total option 17 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_17_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 17 Cost 2 Multiplier**

Total option 17 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_17_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 17 Lifetime**

The option lifetime.

- **Name:** ``option_17_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 18**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_18``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 18 Apply Logic**

Logic that specifies if the Option 18 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_18_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 18 Cost 1 Value**

Total option 18 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_18_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 18 Cost 1 Multiplier**

Total option 18 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_18_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 18 Cost 2 Value**

Total option 18 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_18_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 18 Cost 2 Multiplier**

Total option 18 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_18_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 18 Lifetime**

The option lifetime.

- **Name:** ``option_18_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 19**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_19``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 19 Apply Logic**

Logic that specifies if the Option 19 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_19_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 19 Cost 1 Value**

Total option 19 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_19_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 19 Cost 1 Multiplier**

Total option 19 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_19_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 19 Cost 2 Value**

Total option 19 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_19_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 19 Cost 2 Multiplier**

Total option 19 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_19_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 19 Lifetime**

The option lifetime.

- **Name:** ``option_19_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 20**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_20``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 20 Apply Logic**

Logic that specifies if the Option 20 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_20_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 20 Cost 1 Value**

Total option 20 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_20_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 20 Cost 1 Multiplier**

Total option 20 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_20_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 20 Cost 2 Value**

Total option 20 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_20_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 20 Cost 2 Multiplier**

Total option 20 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_20_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 20 Lifetime**

The option lifetime.

- **Name:** ``option_20_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 21**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_21``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 21 Apply Logic**

Logic that specifies if the Option 21 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_21_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 21 Cost 1 Value**

Total option 21 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_21_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 21 Cost 1 Multiplier**

Total option 21 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_21_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 21 Cost 2 Value**

Total option 21 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_21_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 21 Cost 2 Multiplier**

Total option 21 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_21_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 21 Lifetime**

The option lifetime.

- **Name:** ``option_21_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 22**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_22``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 22 Apply Logic**

Logic that specifies if the Option 22 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_22_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 22 Cost 1 Value**

Total option 22 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_22_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 22 Cost 1 Multiplier**

Total option 22 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_22_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 22 Cost 2 Value**

Total option 22 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_22_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 22 Cost 2 Multiplier**

Total option 22 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_22_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 22 Lifetime**

The option lifetime.

- **Name:** ``option_22_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 23**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_23``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 23 Apply Logic**

Logic that specifies if the Option 23 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_23_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 23 Cost 1 Value**

Total option 23 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_23_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 23 Cost 1 Multiplier**

Total option 23 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_23_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 23 Cost 2 Value**

Total option 23 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_23_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 23 Cost 2 Multiplier**

Total option 23 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_23_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 23 Lifetime**

The option lifetime.

- **Name:** ``option_23_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 24**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_24``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 24 Apply Logic**

Logic that specifies if the Option 24 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_24_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 24 Cost 1 Value**

Total option 24 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_24_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 24 Cost 1 Multiplier**

Total option 24 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_24_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 24 Cost 2 Value**

Total option 24 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_24_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 24 Cost 2 Multiplier**

Total option 24 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_24_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 24 Lifetime**

The option lifetime.

- **Name:** ``option_24_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 25**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_25``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 25 Apply Logic**

Logic that specifies if the Option 25 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_25_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 25 Cost 1 Value**

Total option 25 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_25_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 25 Cost 1 Multiplier**

Total option 25 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_25_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 25 Cost 2 Value**

Total option 25 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_25_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 25 Cost 2 Multiplier**

Total option 25 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_25_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 25 Lifetime**

The option lifetime.

- **Name:** ``option_25_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 26**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_26``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 26 Apply Logic**

Logic that specifies if the Option 26 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_26_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 26 Cost 1 Value**

Total option 26 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_26_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 26 Cost 1 Multiplier**

Total option 26 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_26_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 26 Cost 2 Value**

Total option 26 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_26_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 26 Cost 2 Multiplier**

Total option 26 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_26_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 26 Lifetime**

The option lifetime.

- **Name:** ``option_26_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 27**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_27``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 27 Apply Logic**

Logic that specifies if the Option 27 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_27_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 27 Cost 1 Value**

Total option 27 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_27_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 27 Cost 1 Multiplier**

Total option 27 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_27_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 27 Cost 2 Value**

Total option 27 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_27_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 27 Cost 2 Multiplier**

Total option 27 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_27_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 27 Lifetime**

The option lifetime.

- **Name:** ``option_27_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 28**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_28``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 28 Apply Logic**

Logic that specifies if the Option 28 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_28_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 28 Cost 1 Value**

Total option 28 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_28_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 28 Cost 1 Multiplier**

Total option 28 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_28_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 28 Cost 2 Value**

Total option 28 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_28_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 28 Cost 2 Multiplier**

Total option 28 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_28_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 28 Lifetime**

The option lifetime.

- **Name:** ``option_28_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 29**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_29``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 29 Apply Logic**

Logic that specifies if the Option 29 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_29_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 29 Cost 1 Value**

Total option 29 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_29_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 29 Cost 1 Multiplier**

Total option 29 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_29_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 29 Cost 2 Value**

Total option 29 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_29_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 29 Cost 2 Multiplier**

Total option 29 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_29_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 29 Lifetime**

The option lifetime.

- **Name:** ``option_29_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 30**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_30``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 30 Apply Logic**

Logic that specifies if the Option 30 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_30_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 30 Cost 1 Value**

Total option 30 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_30_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 30 Cost 1 Multiplier**

Total option 30 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_30_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 30 Cost 2 Value**

Total option 30 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_30_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 30 Cost 2 Multiplier**

Total option 30 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_30_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 30 Lifetime**

The option lifetime.

- **Name:** ``option_30_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 31**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_31``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 31 Apply Logic**

Logic that specifies if the Option 31 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_31_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 31 Cost 1 Value**

Total option 31 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_31_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 31 Cost 1 Multiplier**

Total option 31 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_31_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 31 Cost 2 Value**

Total option 31 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_31_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 31 Cost 2 Multiplier**

Total option 31 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_31_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 31 Lifetime**

The option lifetime.

- **Name:** ``option_31_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 32**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_32``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 32 Apply Logic**

Logic that specifies if the Option 32 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_32_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 32 Cost 1 Value**

Total option 32 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_32_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 32 Cost 1 Multiplier**

Total option 32 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_32_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 32 Cost 2 Value**

Total option 32 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_32_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 32 Cost 2 Multiplier**

Total option 32 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_32_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 32 Lifetime**

The option lifetime.

- **Name:** ``option_32_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 33**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_33``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 33 Apply Logic**

Logic that specifies if the Option 33 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_33_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 33 Cost 1 Value**

Total option 33 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_33_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 33 Cost 1 Multiplier**

Total option 33 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_33_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 33 Cost 2 Value**

Total option 33 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_33_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 33 Cost 2 Multiplier**

Total option 33 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_33_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 33 Lifetime**

The option lifetime.

- **Name:** ``option_33_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 34**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_34``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 34 Apply Logic**

Logic that specifies if the Option 34 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_34_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 34 Cost 1 Value**

Total option 34 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_34_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 34 Cost 1 Multiplier**

Total option 34 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_34_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 34 Cost 2 Value**

Total option 34 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_34_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 34 Cost 2 Multiplier**

Total option 34 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_34_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 34 Lifetime**

The option lifetime.

- **Name:** ``option_34_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 35**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_35``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 35 Apply Logic**

Logic that specifies if the Option 35 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_35_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 35 Cost 1 Value**

Total option 35 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_35_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 35 Cost 1 Multiplier**

Total option 35 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_35_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 35 Cost 2 Value**

Total option 35 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_35_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 35 Cost 2 Multiplier**

Total option 35 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_35_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 35 Lifetime**

The option lifetime.

- **Name:** ``option_35_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 36**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_36``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 36 Apply Logic**

Logic that specifies if the Option 36 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_36_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 36 Cost 1 Value**

Total option 36 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_36_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 36 Cost 1 Multiplier**

Total option 36 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_36_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 36 Cost 2 Value**

Total option 36 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_36_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 36 Cost 2 Multiplier**

Total option 36 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_36_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 36 Lifetime**

The option lifetime.

- **Name:** ``option_36_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 37**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_37``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 37 Apply Logic**

Logic that specifies if the Option 37 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_37_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 37 Cost 1 Value**

Total option 37 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_37_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 37 Cost 1 Multiplier**

Total option 37 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_37_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 37 Cost 2 Value**

Total option 37 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_37_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 37 Cost 2 Multiplier**

Total option 37 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_37_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 37 Lifetime**

The option lifetime.

- **Name:** ``option_37_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 38**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_38``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 38 Apply Logic**

Logic that specifies if the Option 38 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_38_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 38 Cost 1 Value**

Total option 38 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_38_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 38 Cost 1 Multiplier**

Total option 38 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_38_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 38 Cost 2 Value**

Total option 38 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_38_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 38 Cost 2 Multiplier**

Total option 38 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_38_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 38 Lifetime**

The option lifetime.

- **Name:** ``option_38_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 39**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_39``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 39 Apply Logic**

Logic that specifies if the Option 39 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_39_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 39 Cost 1 Value**

Total option 39 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_39_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 39 Cost 1 Multiplier**

Total option 39 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_39_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 39 Cost 2 Value**

Total option 39 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_39_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 39 Cost 2 Multiplier**

Total option 39 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_39_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 39 Lifetime**

The option lifetime.

- **Name:** ``option_39_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 40**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_40``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 40 Apply Logic**

Logic that specifies if the Option 40 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_40_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 40 Cost 1 Value**

Total option 40 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_40_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 40 Cost 1 Multiplier**

Total option 40 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_40_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 40 Cost 2 Value**

Total option 40 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_40_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 40 Cost 2 Multiplier**

Total option 40 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_40_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 40 Lifetime**

The option lifetime.

- **Name:** ``option_40_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 41**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_41``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 41 Apply Logic**

Logic that specifies if the Option 41 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_41_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 41 Cost 1 Value**

Total option 41 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_41_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 41 Cost 1 Multiplier**

Total option 41 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_41_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 41 Cost 2 Value**

Total option 41 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_41_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 41 Cost 2 Multiplier**

Total option 41 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_41_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 41 Lifetime**

The option lifetime.

- **Name:** ``option_41_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 42**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_42``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 42 Apply Logic**

Logic that specifies if the Option 42 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_42_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 42 Cost 1 Value**

Total option 42 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_42_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 42 Cost 1 Multiplier**

Total option 42 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_42_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 42 Cost 2 Value**

Total option 42 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_42_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 42 Cost 2 Multiplier**

Total option 42 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_42_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 42 Lifetime**

The option lifetime.

- **Name:** ``option_42_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 43**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_43``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 43 Apply Logic**

Logic that specifies if the Option 43 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_43_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 43 Cost 1 Value**

Total option 43 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_43_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 43 Cost 1 Multiplier**

Total option 43 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_43_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 43 Cost 2 Value**

Total option 43 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_43_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 43 Cost 2 Multiplier**

Total option 43 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_43_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 43 Lifetime**

The option lifetime.

- **Name:** ``option_43_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 44**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_44``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 44 Apply Logic**

Logic that specifies if the Option 44 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_44_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 44 Cost 1 Value**

Total option 44 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_44_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 44 Cost 1 Multiplier**

Total option 44 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_44_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 44 Cost 2 Value**

Total option 44 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_44_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 44 Cost 2 Multiplier**

Total option 44 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_44_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 44 Lifetime**

The option lifetime.

- **Name:** ``option_44_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 45**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_45``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 45 Apply Logic**

Logic that specifies if the Option 45 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_45_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 45 Cost 1 Value**

Total option 45 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_45_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 45 Cost 1 Multiplier**

Total option 45 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_45_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 45 Cost 2 Value**

Total option 45 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_45_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 45 Cost 2 Multiplier**

Total option 45 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_45_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 45 Lifetime**

The option lifetime.

- **Name:** ``option_45_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 46**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_46``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 46 Apply Logic**

Logic that specifies if the Option 46 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_46_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 46 Cost 1 Value**

Total option 46 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_46_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 46 Cost 1 Multiplier**

Total option 46 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_46_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 46 Cost 2 Value**

Total option 46 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_46_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 46 Cost 2 Multiplier**

Total option 46 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_46_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 46 Lifetime**

The option lifetime.

- **Name:** ``option_46_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 47**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_47``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 47 Apply Logic**

Logic that specifies if the Option 47 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_47_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 47 Cost 1 Value**

Total option 47 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_47_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 47 Cost 1 Multiplier**

Total option 47 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_47_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 47 Cost 2 Value**

Total option 47 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_47_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 47 Cost 2 Multiplier**

Total option 47 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_47_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 47 Lifetime**

The option lifetime.

- **Name:** ``option_47_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 48**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_48``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 48 Apply Logic**

Logic that specifies if the Option 48 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_48_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 48 Cost 1 Value**

Total option 48 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_48_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 48 Cost 1 Multiplier**

Total option 48 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_48_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 48 Cost 2 Value**

Total option 48 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_48_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 48 Cost 2 Multiplier**

Total option 48 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_48_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 48 Lifetime**

The option lifetime.

- **Name:** ``option_48_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 49**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_49``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 49 Apply Logic**

Logic that specifies if the Option 49 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_49_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 49 Cost 1 Value**

Total option 49 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_49_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 49 Cost 1 Multiplier**

Total option 49 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_49_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 49 Cost 2 Value**

Total option 49 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_49_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 49 Cost 2 Multiplier**

Total option 49 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_49_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 49 Lifetime**

The option lifetime.

- **Name:** ``option_49_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 50**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_50``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 50 Apply Logic**

Logic that specifies if the Option 50 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_50_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 50 Cost 1 Value**

Total option 50 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_50_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 50 Cost 1 Multiplier**

Total option 50 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_50_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 50 Cost 2 Value**

Total option 50 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_50_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 50 Cost 2 Multiplier**

Total option 50 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_50_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 50 Lifetime**

The option lifetime.

- **Name:** ``option_50_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 51**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_51``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 51 Apply Logic**

Logic that specifies if the Option 51 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_51_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 51 Cost 1 Value**

Total option 51 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_51_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 51 Cost 1 Multiplier**

Total option 51 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_51_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 51 Cost 2 Value**

Total option 51 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_51_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 51 Cost 2 Multiplier**

Total option 51 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_51_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 51 Lifetime**

The option lifetime.

- **Name:** ``option_51_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 52**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_52``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 52 Apply Logic**

Logic that specifies if the Option 52 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_52_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 52 Cost 1 Value**

Total option 52 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_52_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 52 Cost 1 Multiplier**

Total option 52 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_52_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 52 Cost 2 Value**

Total option 52 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_52_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 52 Cost 2 Multiplier**

Total option 52 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_52_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 52 Lifetime**

The option lifetime.

- **Name:** ``option_52_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 53**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_53``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 53 Apply Logic**

Logic that specifies if the Option 53 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_53_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 53 Cost 1 Value**

Total option 53 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_53_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 53 Cost 1 Multiplier**

Total option 53 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_53_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 53 Cost 2 Value**

Total option 53 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_53_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 53 Cost 2 Multiplier**

Total option 53 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_53_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 53 Lifetime**

The option lifetime.

- **Name:** ``option_53_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 54**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_54``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 54 Apply Logic**

Logic that specifies if the Option 54 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_54_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 54 Cost 1 Value**

Total option 54 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_54_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 54 Cost 1 Multiplier**

Total option 54 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_54_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 54 Cost 2 Value**

Total option 54 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_54_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 54 Cost 2 Multiplier**

Total option 54 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_54_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 54 Lifetime**

The option lifetime.

- **Name:** ``option_54_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 55**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_55``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 55 Apply Logic**

Logic that specifies if the Option 55 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_55_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 55 Cost 1 Value**

Total option 55 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_55_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 55 Cost 1 Multiplier**

Total option 55 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_55_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 55 Cost 2 Value**

Total option 55 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_55_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 55 Cost 2 Multiplier**

Total option 55 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_55_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 55 Lifetime**

The option lifetime.

- **Name:** ``option_55_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 56**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_56``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 56 Apply Logic**

Logic that specifies if the Option 56 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_56_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 56 Cost 1 Value**

Total option 56 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_56_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 56 Cost 1 Multiplier**

Total option 56 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_56_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 56 Cost 2 Value**

Total option 56 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_56_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 56 Cost 2 Multiplier**

Total option 56 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_56_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 56 Lifetime**

The option lifetime.

- **Name:** ``option_56_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 57**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_57``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 57 Apply Logic**

Logic that specifies if the Option 57 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_57_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 57 Cost 1 Value**

Total option 57 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_57_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 57 Cost 1 Multiplier**

Total option 57 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_57_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 57 Cost 2 Value**

Total option 57 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_57_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 57 Cost 2 Multiplier**

Total option 57 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_57_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 57 Lifetime**

The option lifetime.

- **Name:** ``option_57_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 58**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_58``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 58 Apply Logic**

Logic that specifies if the Option 58 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_58_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 58 Cost 1 Value**

Total option 58 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_58_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 58 Cost 1 Multiplier**

Total option 58 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_58_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 58 Cost 2 Value**

Total option 58 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_58_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 58 Cost 2 Multiplier**

Total option 58 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_58_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 58 Lifetime**

The option lifetime.

- **Name:** ``option_58_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 59**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_59``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 59 Apply Logic**

Logic that specifies if the Option 59 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_59_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 59 Cost 1 Value**

Total option 59 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_59_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 59 Cost 1 Multiplier**

Total option 59 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_59_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 59 Cost 2 Value**

Total option 59 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_59_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 59 Cost 2 Multiplier**

Total option 59 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_59_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 59 Lifetime**

The option lifetime.

- **Name:** ``option_59_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 60**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_60``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 60 Apply Logic**

Logic that specifies if the Option 60 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_60_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 60 Cost 1 Value**

Total option 60 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_60_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 60 Cost 1 Multiplier**

Total option 60 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_60_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 60 Cost 2 Value**

Total option 60 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_60_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 60 Cost 2 Multiplier**

Total option 60 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_60_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 60 Lifetime**

The option lifetime.

- **Name:** ``option_60_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 61**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_61``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 61 Apply Logic**

Logic that specifies if the Option 61 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_61_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 61 Cost 1 Value**

Total option 61 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_61_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 61 Cost 1 Multiplier**

Total option 61 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_61_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 61 Cost 2 Value**

Total option 61 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_61_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 61 Cost 2 Multiplier**

Total option 61 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_61_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 61 Lifetime**

The option lifetime.

- **Name:** ``option_61_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 62**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_62``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 62 Apply Logic**

Logic that specifies if the Option 62 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_62_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 62 Cost 1 Value**

Total option 62 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_62_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 62 Cost 1 Multiplier**

Total option 62 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_62_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 62 Cost 2 Value**

Total option 62 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_62_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 62 Cost 2 Multiplier**

Total option 62 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_62_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 62 Lifetime**

The option lifetime.

- **Name:** ``option_62_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 63**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_63``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 63 Apply Logic**

Logic that specifies if the Option 63 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_63_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 63 Cost 1 Value**

Total option 63 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_63_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 63 Cost 1 Multiplier**

Total option 63 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_63_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 63 Cost 2 Value**

Total option 63 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_63_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 63 Cost 2 Multiplier**

Total option 63 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_63_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 63 Lifetime**

The option lifetime.

- **Name:** ``option_63_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 64**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_64``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 64 Apply Logic**

Logic that specifies if the Option 64 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_64_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 64 Cost 1 Value**

Total option 64 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_64_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 64 Cost 1 Multiplier**

Total option 64 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_64_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 64 Cost 2 Value**

Total option 64 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_64_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 64 Cost 2 Multiplier**

Total option 64 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_64_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 64 Lifetime**

The option lifetime.

- **Name:** ``option_64_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 65**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_65``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 65 Apply Logic**

Logic that specifies if the Option 65 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_65_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 65 Cost 1 Value**

Total option 65 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_65_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 65 Cost 1 Multiplier**

Total option 65 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_65_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 65 Cost 2 Value**

Total option 65 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_65_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 65 Cost 2 Multiplier**

Total option 65 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_65_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 65 Lifetime**

The option lifetime.

- **Name:** ``option_65_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 66**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_66``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 66 Apply Logic**

Logic that specifies if the Option 66 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_66_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 66 Cost 1 Value**

Total option 66 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_66_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 66 Cost 1 Multiplier**

Total option 66 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_66_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 66 Cost 2 Value**

Total option 66 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_66_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 66 Cost 2 Multiplier**

Total option 66 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_66_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 66 Lifetime**

The option lifetime.

- **Name:** ``option_66_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 67**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_67``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 67 Apply Logic**

Logic that specifies if the Option 67 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_67_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 67 Cost 1 Value**

Total option 67 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_67_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 67 Cost 1 Multiplier**

Total option 67 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_67_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 67 Cost 2 Value**

Total option 67 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_67_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 67 Cost 2 Multiplier**

Total option 67 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_67_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 67 Lifetime**

The option lifetime.

- **Name:** ``option_67_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 68**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_68``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 68 Apply Logic**

Logic that specifies if the Option 68 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_68_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 68 Cost 1 Value**

Total option 68 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_68_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 68 Cost 1 Multiplier**

Total option 68 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_68_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 68 Cost 2 Value**

Total option 68 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_68_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 68 Cost 2 Multiplier**

Total option 68 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_68_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 68 Lifetime**

The option lifetime.

- **Name:** ``option_68_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 69**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_69``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 69 Apply Logic**

Logic that specifies if the Option 69 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_69_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 69 Cost 1 Value**

Total option 69 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_69_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 69 Cost 1 Multiplier**

Total option 69 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_69_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 69 Cost 2 Value**

Total option 69 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_69_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 69 Cost 2 Multiplier**

Total option 69 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_69_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 69 Lifetime**

The option lifetime.

- **Name:** ``option_69_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 70**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_70``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 70 Apply Logic**

Logic that specifies if the Option 70 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_70_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 70 Cost 1 Value**

Total option 70 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_70_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 70 Cost 1 Multiplier**

Total option 70 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_70_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 70 Cost 2 Value**

Total option 70 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_70_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 70 Cost 2 Multiplier**

Total option 70 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_70_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 70 Lifetime**

The option lifetime.

- **Name:** ``option_70_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 71**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_71``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 71 Apply Logic**

Logic that specifies if the Option 71 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_71_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 71 Cost 1 Value**

Total option 71 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_71_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 71 Cost 1 Multiplier**

Total option 71 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_71_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 71 Cost 2 Value**

Total option 71 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_71_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 71 Cost 2 Multiplier**

Total option 71 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_71_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 71 Lifetime**

The option lifetime.

- **Name:** ``option_71_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 72**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_72``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 72 Apply Logic**

Logic that specifies if the Option 72 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_72_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 72 Cost 1 Value**

Total option 72 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_72_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 72 Cost 1 Multiplier**

Total option 72 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_72_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 72 Cost 2 Value**

Total option 72 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_72_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 72 Cost 2 Multiplier**

Total option 72 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_72_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 72 Lifetime**

The option lifetime.

- **Name:** ``option_72_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 73**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_73``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 73 Apply Logic**

Logic that specifies if the Option 73 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_73_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 73 Cost 1 Value**

Total option 73 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_73_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 73 Cost 1 Multiplier**

Total option 73 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_73_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 73 Cost 2 Value**

Total option 73 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_73_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 73 Cost 2 Multiplier**

Total option 73 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_73_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 73 Lifetime**

The option lifetime.

- **Name:** ``option_73_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 74**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_74``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 74 Apply Logic**

Logic that specifies if the Option 74 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_74_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 74 Cost 1 Value**

Total option 74 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_74_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 74 Cost 1 Multiplier**

Total option 74 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_74_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 74 Cost 2 Value**

Total option 74 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_74_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 74 Cost 2 Multiplier**

Total option 74 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_74_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 74 Lifetime**

The option lifetime.

- **Name:** ``option_74_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 75**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_75``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 75 Apply Logic**

Logic that specifies if the Option 75 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_75_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 75 Cost 1 Value**

Total option 75 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_75_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 75 Cost 1 Multiplier**

Total option 75 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_75_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 75 Cost 2 Value**

Total option 75 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_75_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 75 Cost 2 Multiplier**

Total option 75 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_75_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 75 Lifetime**

The option lifetime.

- **Name:** ``option_75_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 76**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_76``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 76 Apply Logic**

Logic that specifies if the Option 76 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_76_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 76 Cost 1 Value**

Total option 76 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_76_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 76 Cost 1 Multiplier**

Total option 76 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_76_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 76 Cost 2 Value**

Total option 76 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_76_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 76 Cost 2 Multiplier**

Total option 76 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_76_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 76 Lifetime**

The option lifetime.

- **Name:** ``option_76_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 77**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_77``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 77 Apply Logic**

Logic that specifies if the Option 77 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_77_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 77 Cost 1 Value**

Total option 77 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_77_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 77 Cost 1 Multiplier**

Total option 77 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_77_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 77 Cost 2 Value**

Total option 77 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_77_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 77 Cost 2 Multiplier**

Total option 77 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_77_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 77 Lifetime**

The option lifetime.

- **Name:** ``option_77_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 78**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_78``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 78 Apply Logic**

Logic that specifies if the Option 78 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_78_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 78 Cost 1 Value**

Total option 78 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_78_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 78 Cost 1 Multiplier**

Total option 78 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_78_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 78 Cost 2 Value**

Total option 78 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_78_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 78 Cost 2 Multiplier**

Total option 78 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_78_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 78 Lifetime**

The option lifetime.

- **Name:** ``option_78_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 79**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_79``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 79 Apply Logic**

Logic that specifies if the Option 79 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_79_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 79 Cost 1 Value**

Total option 79 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_79_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 79 Cost 1 Multiplier**

Total option 79 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_79_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 79 Cost 2 Value**

Total option 79 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_79_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 79 Cost 2 Multiplier**

Total option 79 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_79_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 79 Lifetime**

The option lifetime.

- **Name:** ``option_79_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 80**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_80``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 80 Apply Logic**

Logic that specifies if the Option 80 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_80_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 80 Cost 1 Value**

Total option 80 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_80_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 80 Cost 1 Multiplier**

Total option 80 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_80_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 80 Cost 2 Value**

Total option 80 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_80_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 80 Cost 2 Multiplier**

Total option 80 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_80_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 80 Lifetime**

The option lifetime.

- **Name:** ``option_80_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 81**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_81``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 81 Apply Logic**

Logic that specifies if the Option 81 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_81_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 81 Cost 1 Value**

Total option 81 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_81_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 81 Cost 1 Multiplier**

Total option 81 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_81_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 81 Cost 2 Value**

Total option 81 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_81_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 81 Cost 2 Multiplier**

Total option 81 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_81_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 81 Lifetime**

The option lifetime.

- **Name:** ``option_81_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 82**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_82``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 82 Apply Logic**

Logic that specifies if the Option 82 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_82_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 82 Cost 1 Value**

Total option 82 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_82_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 82 Cost 1 Multiplier**

Total option 82 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_82_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 82 Cost 2 Value**

Total option 82 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_82_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 82 Cost 2 Multiplier**

Total option 82 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_82_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 82 Lifetime**

The option lifetime.

- **Name:** ``option_82_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 83**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_83``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 83 Apply Logic**

Logic that specifies if the Option 83 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_83_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 83 Cost 1 Value**

Total option 83 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_83_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 83 Cost 1 Multiplier**

Total option 83 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_83_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 83 Cost 2 Value**

Total option 83 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_83_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 83 Cost 2 Multiplier**

Total option 83 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_83_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 83 Lifetime**

The option lifetime.

- **Name:** ``option_83_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 84**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_84``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 84 Apply Logic**

Logic that specifies if the Option 84 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_84_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 84 Cost 1 Value**

Total option 84 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_84_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 84 Cost 1 Multiplier**

Total option 84 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_84_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 84 Cost 2 Value**

Total option 84 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_84_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 84 Cost 2 Multiplier**

Total option 84 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_84_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 84 Lifetime**

The option lifetime.

- **Name:** ``option_84_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 85**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_85``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 85 Apply Logic**

Logic that specifies if the Option 85 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_85_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 85 Cost 1 Value**

Total option 85 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_85_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 85 Cost 1 Multiplier**

Total option 85 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_85_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 85 Cost 2 Value**

Total option 85 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_85_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 85 Cost 2 Multiplier**

Total option 85 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_85_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 85 Lifetime**

The option lifetime.

- **Name:** ``option_85_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 86**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_86``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 86 Apply Logic**

Logic that specifies if the Option 86 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_86_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 86 Cost 1 Value**

Total option 86 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_86_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 86 Cost 1 Multiplier**

Total option 86 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_86_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 86 Cost 2 Value**

Total option 86 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_86_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 86 Cost 2 Multiplier**

Total option 86 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_86_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 86 Lifetime**

The option lifetime.

- **Name:** ``option_86_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 87**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_87``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 87 Apply Logic**

Logic that specifies if the Option 87 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_87_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 87 Cost 1 Value**

Total option 87 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_87_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 87 Cost 1 Multiplier**

Total option 87 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_87_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 87 Cost 2 Value**

Total option 87 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_87_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 87 Cost 2 Multiplier**

Total option 87 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_87_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 87 Lifetime**

The option lifetime.

- **Name:** ``option_87_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 88**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_88``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 88 Apply Logic**

Logic that specifies if the Option 88 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_88_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 88 Cost 1 Value**

Total option 88 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_88_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 88 Cost 1 Multiplier**

Total option 88 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_88_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 88 Cost 2 Value**

Total option 88 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_88_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 88 Cost 2 Multiplier**

Total option 88 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_88_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 88 Lifetime**

The option lifetime.

- **Name:** ``option_88_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 89**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_89``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 89 Apply Logic**

Logic that specifies if the Option 89 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_89_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 89 Cost 1 Value**

Total option 89 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_89_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 89 Cost 1 Multiplier**

Total option 89 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_89_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 89 Cost 2 Value**

Total option 89 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_89_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 89 Cost 2 Multiplier**

Total option 89 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_89_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 89 Lifetime**

The option lifetime.

- **Name:** ``option_89_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 90**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_90``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 90 Apply Logic**

Logic that specifies if the Option 90 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_90_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 90 Cost 1 Value**

Total option 90 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_90_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 90 Cost 1 Multiplier**

Total option 90 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_90_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 90 Cost 2 Value**

Total option 90 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_90_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 90 Cost 2 Multiplier**

Total option 90 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_90_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 90 Lifetime**

The option lifetime.

- **Name:** ``option_90_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 91**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_91``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 91 Apply Logic**

Logic that specifies if the Option 91 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_91_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 91 Cost 1 Value**

Total option 91 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_91_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 91 Cost 1 Multiplier**

Total option 91 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_91_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 91 Cost 2 Value**

Total option 91 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_91_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 91 Cost 2 Multiplier**

Total option 91 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_91_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 91 Lifetime**

The option lifetime.

- **Name:** ``option_91_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 92**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_92``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 92 Apply Logic**

Logic that specifies if the Option 92 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_92_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 92 Cost 1 Value**

Total option 92 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_92_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 92 Cost 1 Multiplier**

Total option 92 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_92_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 92 Cost 2 Value**

Total option 92 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_92_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 92 Cost 2 Multiplier**

Total option 92 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_92_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 92 Lifetime**

The option lifetime.

- **Name:** ``option_92_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 93**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_93``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 93 Apply Logic**

Logic that specifies if the Option 93 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_93_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 93 Cost 1 Value**

Total option 93 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_93_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 93 Cost 1 Multiplier**

Total option 93 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_93_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 93 Cost 2 Value**

Total option 93 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_93_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 93 Cost 2 Multiplier**

Total option 93 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_93_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 93 Lifetime**

The option lifetime.

- **Name:** ``option_93_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 94**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_94``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 94 Apply Logic**

Logic that specifies if the Option 94 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_94_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 94 Cost 1 Value**

Total option 94 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_94_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 94 Cost 1 Multiplier**

Total option 94 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_94_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 94 Cost 2 Value**

Total option 94 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_94_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 94 Cost 2 Multiplier**

Total option 94 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_94_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 94 Lifetime**

The option lifetime.

- **Name:** ``option_94_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 95**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_95``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 95 Apply Logic**

Logic that specifies if the Option 95 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_95_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 95 Cost 1 Value**

Total option 95 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_95_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 95 Cost 1 Multiplier**

Total option 95 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_95_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 95 Cost 2 Value**

Total option 95 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_95_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 95 Cost 2 Multiplier**

Total option 95 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_95_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 95 Lifetime**

The option lifetime.

- **Name:** ``option_95_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 96**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_96``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 96 Apply Logic**

Logic that specifies if the Option 96 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_96_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 96 Cost 1 Value**

Total option 96 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_96_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 96 Cost 1 Multiplier**

Total option 96 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_96_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 96 Cost 2 Value**

Total option 96 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_96_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 96 Cost 2 Multiplier**

Total option 96 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_96_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 96 Lifetime**

The option lifetime.

- **Name:** ``option_96_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 97**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_97``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 97 Apply Logic**

Logic that specifies if the Option 97 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_97_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 97 Cost 1 Value**

Total option 97 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_97_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 97 Cost 1 Multiplier**

Total option 97 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_97_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 97 Cost 2 Value**

Total option 97 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_97_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 97 Cost 2 Multiplier**

Total option 97 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_97_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 97 Lifetime**

The option lifetime.

- **Name:** ``option_97_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 98**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_98``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 98 Apply Logic**

Logic that specifies if the Option 98 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_98_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 98 Cost 1 Value**

Total option 98 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_98_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 98 Cost 1 Multiplier**

Total option 98 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_98_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 98 Cost 2 Value**

Total option 98 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_98_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 98 Cost 2 Multiplier**

Total option 98 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_98_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 98 Lifetime**

The option lifetime.

- **Name:** ``option_98_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 99**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_99``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 99 Apply Logic**

Logic that specifies if the Option 99 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_99_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 99 Cost 1 Value**

Total option 99 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_99_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 99 Cost 1 Multiplier**

Total option 99 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_99_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 99 Cost 2 Value**

Total option 99 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_99_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 99 Cost 2 Multiplier**

Total option 99 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_99_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 99 Lifetime**

The option lifetime.

- **Name:** ``option_99_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 100**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_100``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 100 Apply Logic**

Logic that specifies if the Option 100 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_100_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 100 Cost 1 Value**

Total option 100 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_100_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 100 Cost 1 Multiplier**

Total option 100 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_100_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 100 Cost 2 Value**

Total option 100 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_100_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 100 Cost 2 Multiplier**

Total option 100 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_100_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 100 Lifetime**

The option lifetime.

- **Name:** ``option_100_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Package Apply Logic**

Logic that specifies if the entire package upgrade (all options) will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``package_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Run Measure**

integer argument to run measure [1 is run, 0 is no run]

- **Name:** ``run_measure``
- **Type:** ``Integer``

- **Required:** ``true``

<br/>





