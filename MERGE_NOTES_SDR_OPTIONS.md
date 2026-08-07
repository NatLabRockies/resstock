# SDR options lost in the geo_sampling merge

@asparke2 -- this needs your call.

Five `resources/options_lookup.tsv` rows were added on `new_sampling_postprocessing` against OpenStudio-HPXML **v1.10** argument names. Merging `geo_sampling` (OpenStudio-HPXML **v1.11**) over that branch dropped all five, which broke `project_national/sdr_upgrades_tmy3.yml` and `project_national/sdr_upgrades_furnace.yml` -- both still reference them.

All five are back in `options_lookup.tsv` as **placeholders**. Two are converted and safe; three are the v1.10 text verbatim and will not run. Pick the correct final row for each, then delete the matching `@asparke2 MERGE ATTENTION` comment block from the yml files and delete this file.

## The v1.10 -> v1.11 argument changes involved

- **Cooling (`cooling_system_*`):** `cooling_system_cooling_compressor_type` renamed to `cooling_system_compressor_type`, and `cooling_system_cooling_sensible_heat_fraction` removed outright.
- **Heat pump (`heat_pump_*`):** `heat_pump_heating_capacity_retention_fraction` + `heat_pump_heating_capacity_retention_temp` collapsed into the single `heat_pump_heating_capacity_fraction_17_f`; `heat_pump_cooling_compressor_type` renamed to `heat_pump_compressor_type`; `heat_pump_cooling_sensible_heat_fraction` removed; `heat_pump_pan_heater_watts` and `heat_pump_pan_heater_control_type` added.

The cooling change is purely mechanical. The heat-pump change is not: v1.10 let you state a retention fraction at an arbitrary temperature, v1.11 fixes the reference temperature at 17F, so any row whose v1.10 retention temperature was not 17F needs the fraction recomputed. That is a physics call and has deliberately not been made here.

## The five rows

| # | Parameter | Option | Placeholder now in `options_lookup.tsv` | Runs against v1.11? | Referenced from |
|---|---|---|---|---|---|
| 1 | HVAC Cooling Efficiency | `"AC, SEER2 13.4"` | v1.11 converted | yes | sdr_upgrades_tmy3.yml<br>sdr_upgrades_furnace.yml |
| 2 | HVAC Cooling Efficiency | `"AC, SEER2 14.3"` | v1.11 converted | yes | sdr_upgrades_tmy3.yml<br>sdr_upgrades_furnace.yml |
| 3 | HVAC Heating Efficiency | `"ASHP, SEER2 14.3, 7.5 HSPF2"` | v1.10 verbatim | **no** -- 4 extra args | sdr_upgrades_tmy3.yml<br>sdr_upgrades_furnace.yml |
| 4 | HVAC Heating Efficiency | `"Dual-Fuel ASHP, SEER 15.2, 7.8 HSPF2, Integrated Backup, 92.5% AFUE NG, 35F switchover"` | v1.10 verbatim | **no** -- 4 extra args | sdr_upgrades_tmy3.yml |
| 5 | HVAC Heating Efficiency | `"Dual-Fuel ASHP, SEER 15.2, 7.8 HSPF2, Integrated Backup, 95.0% AFUE NG, 35F switchover"` | v1.10 verbatim | **no** -- 4 extra args | sdr_upgrades_tmy3.yml |

The three heat-pump rows carry `heat_pump_heating_capacity_retention_fraction`, `heat_pump_heating_capacity_retention_temp`, `heat_pump_cooling_compressor_type` and `heat_pump_cooling_sensible_heat_fraction`, none of which exist in the v1.11 `ResStockArguments` measure. `rake integrity_check_national` rejects them with `Extra argument '...' specified`.

## Both states, in full

Rows below are tab-separated exactly as they belong in `options_lookup.tsv`. Each is a single line, soft-wrapped for display.

### 1. HVAC Cooling Efficiency | "AC, SEER2 13.4"

Referenced from: `project_national/sdr_upgrades_tmy3.yml`, `project_national/sdr_upgrades_furnace.yml`

**v1.10 (as added on `new_sampling_postprocessing`):**

```
HVAC Cooling Efficiency	"AC, SEER2 13.4"	ResStockArguments	cooling_system_type=central air conditioner	cooling_system_cooling_efficiency_type=SEER2	cooling_system_cooling_efficiency=13.4	cooling_system_cooling_capacity=auto	cooling_system_cooling_autosizing_limit=auto	cooling_system_is_ducted=false	cooling_system_cooling_compressor_type=single stage	cooling_system_cooling_sensible_heat_fraction=auto	cooling_system_crankcase_heater_watts=auto	cooling_system_integrated_heating_system_capacity=auto	cooling_system_integrated_heating_system_efficiency_percent=auto	cooling_system_integrated_heating_system_fraction_heat_load_served=auto	cooling_system_integrated_heating_system_fuel=auto
```

**v1.11 (currently in the tree -- rename applied, nothing else changed):**

```
HVAC Cooling Efficiency	"AC, SEER2 13.4"	ResStockArguments	cooling_system_type=central air conditioner	cooling_system_cooling_efficiency_type=SEER2	cooling_system_cooling_efficiency=13.4	cooling_system_cooling_capacity=auto	cooling_system_cooling_autosizing_limit=auto	cooling_system_is_ducted=false	cooling_system_compressor_type=single stage	cooling_system_crankcase_heater_watts=auto	cooling_system_integrated_heating_system_capacity=auto	cooling_system_integrated_heating_system_efficiency_percent=auto	cooling_system_integrated_heating_system_fraction_heat_load_served=auto	cooling_system_integrated_heating_system_fuel=auto
```

Delta: `cooling_system_cooling_compressor_type` renamed to `cooling_system_compressor_type`, and `cooling_system_cooling_sensible_heat_fraction` removed outright. Argument names and order now match the neighbouring v1.11 `"AC, SEER 13"` / `"AC, SEER 14"` rows exactly, so this validates clean. The only thing left for you to confirm is whether the SEER2 values themselves are what you want.

### 2. HVAC Cooling Efficiency | "AC, SEER2 14.3"

Referenced from: `project_national/sdr_upgrades_tmy3.yml`, `project_national/sdr_upgrades_furnace.yml`

**v1.10 (as added on `new_sampling_postprocessing`):**

```
HVAC Cooling Efficiency	"AC, SEER2 14.3"	ResStockArguments	cooling_system_type=central air conditioner	cooling_system_cooling_efficiency_type=SEER2	cooling_system_cooling_efficiency=14.3	cooling_system_cooling_capacity=auto	cooling_system_cooling_autosizing_limit=auto	cooling_system_is_ducted=false	cooling_system_cooling_compressor_type=single stage	cooling_system_cooling_sensible_heat_fraction=auto	cooling_system_crankcase_heater_watts=auto	cooling_system_integrated_heating_system_capacity=auto	cooling_system_integrated_heating_system_efficiency_percent=auto	cooling_system_integrated_heating_system_fraction_heat_load_served=auto	cooling_system_integrated_heating_system_fuel=auto
```

**v1.11 (currently in the tree -- rename applied, nothing else changed):**

```
HVAC Cooling Efficiency	"AC, SEER2 14.3"	ResStockArguments	cooling_system_type=central air conditioner	cooling_system_cooling_efficiency_type=SEER2	cooling_system_cooling_efficiency=14.3	cooling_system_cooling_capacity=auto	cooling_system_cooling_autosizing_limit=auto	cooling_system_is_ducted=false	cooling_system_compressor_type=single stage	cooling_system_crankcase_heater_watts=auto	cooling_system_integrated_heating_system_capacity=auto	cooling_system_integrated_heating_system_efficiency_percent=auto	cooling_system_integrated_heating_system_fraction_heat_load_served=auto	cooling_system_integrated_heating_system_fuel=auto
```

Delta: `cooling_system_cooling_compressor_type` renamed to `cooling_system_compressor_type`, and `cooling_system_cooling_sensible_heat_fraction` removed outright. Argument names and order now match the neighbouring v1.11 `"AC, SEER 13"` / `"AC, SEER 14"` rows exactly, so this validates clean. The only thing left for you to confirm is whether the SEER2 values themselves are what you want.

### 3. HVAC Heating Efficiency | "ASHP, SEER2 14.3, 7.5 HSPF2"

Referenced from: `project_national/sdr_upgrades_tmy3.yml`, `project_national/sdr_upgrades_furnace.yml`

**v1.10 (as added on `new_sampling_postprocessing`):**

```
HVAC Heating Efficiency	"ASHP, SEER2 14.3, 7.5 HSPF2"	ResStockArguments	heating_system_type=none	heating_system_heating_efficiency=0	heating_system_heating_capacity=auto	heating_system_heating_autosizing_limit=auto	heating_system_fraction_heat_load_served=1	heating_system_has_flue_or_chimney=auto	heat_pump_type=air-to-air	heat_pump_heating_efficiency_type=HSPF2	heat_pump_heating_efficiency=7.5	heat_pump_cooling_efficiency_type=SEER2	heat_pump_cooling_efficiency=14.3	heat_pump_sizing_methodology=ACCA	heat_pump_sizing_is_duct_limited=false	heat_pump_backup_sizing_methodology=auto	heat_pump_heating_capacity=auto	heat_pump_heating_autosizing_limit=auto	heat_pump_fraction_heat_load_served=1	heat_pump_cooling_capacity=auto	heat_pump_cooling_autosizing_limit=auto	heat_pump_fraction_cool_load_served=1	heat_pump_backup_use_existing_system=false	heat_pump_backup_type=integrated	heat_pump_backup_fuel=electricity	heat_pump_backup_heating_efficiency=1	heat_pump_backup_heating_capacity=auto	heat_pump_backup_heating_autosizing_limit=auto	heat_pump_heating_capacity_retention_fraction=auto	heat_pump_heating_capacity_retention_temp=auto	heat_pump_is_ducted=true	heat_pump_backup_heating_lockout_temp=auto	heat_pump_compressor_lockout_temp=auto	heat_pump_cooling_compressor_type=single stage	heat_pump_cooling_sensible_heat_fraction=auto	heat_pump_crankcase_heater_watts=auto	geothermal_loop_configuration=none	geothermal_loop_borefield_configuration=auto	geothermal_loop_loop_flow=auto	geothermal_loop_boreholes_count=auto	geothermal_loop_boreholes_length=auto	geothermal_loop_boreholes_spacing=auto	geothermal_loop_boreholes_diameter=auto	geothermal_loop_grout_type=auto	geothermal_loop_pipe_type=auto	geothermal_loop_pipe_diameter=auto
```

**v1.11 (NOT DETERMINED -- skeleton only, does not belong in the tree as-is):**

```
HVAC Heating Efficiency	"ASHP, SEER2 14.3, 7.5 HSPF2"	ResStockArguments	heating_system_type=none	heating_system_heating_efficiency=0	heating_system_heating_capacity=auto	heating_system_heating_autosizing_limit=auto	heating_system_fraction_heat_load_served=1	heating_system_has_flue_or_chimney=auto	heat_pump_type=air-to-air	heat_pump_heating_efficiency_type=HSPF2	heat_pump_heating_efficiency=7.5	heat_pump_cooling_efficiency_type=SEER2	heat_pump_cooling_efficiency=14.3	heat_pump_sizing_methodology=ACCA	heat_pump_sizing_is_duct_limited=false	heat_pump_backup_sizing_methodology=auto	heat_pump_heating_capacity=auto	heat_pump_heating_autosizing_limit=auto	heat_pump_fraction_heat_load_served=1	heat_pump_cooling_capacity=auto	heat_pump_cooling_autosizing_limit=auto	heat_pump_fraction_cool_load_served=1	heat_pump_backup_use_existing_system=false	heat_pump_backup_type=integrated	heat_pump_backup_fuel=electricity	heat_pump_backup_heating_efficiency=1	heat_pump_backup_heating_capacity=auto	heat_pump_backup_heating_autosizing_limit=auto	heat_pump_heating_capacity_fraction_17_f=<TBD 'auto' is the mechanical read, since v1.10 had auto/auto>	heat_pump_is_ducted=true	heat_pump_backup_heating_lockout_temp=auto	heat_pump_compressor_lockout_temp=auto	heat_pump_compressor_type=single stage	heat_pump_crankcase_heater_watts=auto	heat_pump_pan_heater_watts=<TBD every sibling v1.11 row uses auto>	heat_pump_pan_heater_control_type=<TBD every sibling v1.11 row uses auto>	geothermal_loop_configuration=none	geothermal_loop_borefield_configuration=auto	geothermal_loop_loop_flow=auto	geothermal_loop_boreholes_count=auto	geothermal_loop_boreholes_length=auto	geothermal_loop_boreholes_spacing=auto	geothermal_loop_boreholes_diameter=auto	geothermal_loop_grout_type=auto	geothermal_loop_pipe_type=auto	geothermal_loop_pipe_diameter=auto
```

Delta: `heat_pump_heating_capacity_retention_fraction` + `heat_pump_heating_capacity_retention_temp` collapsed into the single `heat_pump_heating_capacity_fraction_17_f`; `heat_pump_cooling_compressor_type` renamed to `heat_pump_compressor_type`; `heat_pump_cooling_sensible_heat_fraction` removed; `heat_pump_pan_heater_watts` and `heat_pump_pan_heater_control_type` added. Argument order above follows the v1.11 sibling row `HVAC Heating Efficiency | "ASHP, SEER 14.3, 8.5 HSPF"`. Every `<TBD ...>` is yours to resolve; the tree currently holds the v1.10 line above instead.

### 4. HVAC Heating Efficiency | "Dual-Fuel ASHP, SEER 15.2, 7.8 HSPF2, Integrated Backup, 92.5% AFUE NG, 35F switchover"

Referenced from: `project_national/sdr_upgrades_tmy3.yml`

**v1.10 (as added on `new_sampling_postprocessing`):**

```
HVAC Heating Efficiency	"Dual-Fuel ASHP, SEER 15.2, 7.8 HSPF2, Integrated Backup, 92.5% AFUE NG, 35F switchover"	ResStockArguments	heating_system_type=none	heating_system_heating_efficiency=0	heating_system_heating_capacity=auto	heating_system_heating_autosizing_limit=auto	heating_system_fraction_heat_load_served=1	heating_system_has_flue_or_chimney=auto	heat_pump_type=air-to-air	heat_pump_heating_efficiency_type=HSPF2	heat_pump_heating_efficiency=7.8	heat_pump_cooling_efficiency_type=SEER2	heat_pump_cooling_efficiency=15.2	heat_pump_sizing_methodology=ACCA	heat_pump_sizing_is_duct_limited=false	heat_pump_backup_sizing_methodology=auto	heat_pump_heating_capacity=auto	heat_pump_heating_autosizing_limit=auto	heat_pump_fraction_heat_load_served=1	heat_pump_cooling_capacity=auto	heat_pump_cooling_autosizing_limit=auto	heat_pump_fraction_cool_load_served=1	heat_pump_backup_use_existing_system=false	heat_pump_backup_type=integrated	heat_pump_backup_fuel=natural gas	heat_pump_backup_heating_efficiency=0.925	heat_pump_backup_heating_capacity=auto	heat_pump_backup_heating_autosizing_limit=auto	heat_pump_heating_capacity_retention_fraction=0.5	heat_pump_heating_capacity_retention_temp=5	heat_pump_is_ducted=true	heat_pump_backup_heating_lockout_temp=35	heat_pump_compressor_lockout_temp=35	heat_pump_cooling_compressor_type=single stage	heat_pump_cooling_sensible_heat_fraction=auto	heat_pump_crankcase_heater_watts=auto	geothermal_loop_configuration=none	geothermal_loop_borefield_configuration=auto	geothermal_loop_loop_flow=auto	geothermal_loop_boreholes_count=auto	geothermal_loop_boreholes_length=auto	geothermal_loop_boreholes_spacing=auto	geothermal_loop_boreholes_diameter=auto	geothermal_loop_grout_type=auto	geothermal_loop_pipe_type=auto	geothermal_loop_pipe_diameter=auto
```

**v1.11 (NOT DETERMINED -- skeleton only, does not belong in the tree as-is):**

```
HVAC Heating Efficiency	"Dual-Fuel ASHP, SEER 15.2, 7.8 HSPF2, Integrated Backup, 92.5% AFUE NG, 35F switchover"	ResStockArguments	heating_system_type=none	heating_system_heating_efficiency=0	heating_system_heating_capacity=auto	heating_system_heating_autosizing_limit=auto	heating_system_fraction_heat_load_served=1	heating_system_has_flue_or_chimney=auto	heat_pump_type=air-to-air	heat_pump_heating_efficiency_type=HSPF2	heat_pump_heating_efficiency=7.8	heat_pump_cooling_efficiency_type=SEER2	heat_pump_cooling_efficiency=15.2	heat_pump_sizing_methodology=ACCA	heat_pump_sizing_is_duct_limited=false	heat_pump_backup_sizing_methodology=auto	heat_pump_heating_capacity=auto	heat_pump_heating_autosizing_limit=auto	heat_pump_fraction_heat_load_served=1	heat_pump_cooling_capacity=auto	heat_pump_cooling_autosizing_limit=auto	heat_pump_fraction_cool_load_served=1	heat_pump_backup_use_existing_system=false	heat_pump_backup_type=integrated	heat_pump_backup_fuel=natural gas	heat_pump_backup_heating_efficiency=0.925	heat_pump_backup_heating_capacity=auto	heat_pump_backup_heating_autosizing_limit=auto	heat_pump_heating_capacity_fraction_17_f=<TBD PHYSICS: v1.10 said 0.5 retained at 5F; needs the fraction retained at 17F>	heat_pump_is_ducted=true	heat_pump_backup_heating_lockout_temp=35	heat_pump_compressor_lockout_temp=35	heat_pump_compressor_type=single stage	heat_pump_crankcase_heater_watts=auto	heat_pump_pan_heater_watts=<TBD every sibling v1.11 row uses auto>	heat_pump_pan_heater_control_type=<TBD every sibling v1.11 row uses auto>	geothermal_loop_configuration=none	geothermal_loop_borefield_configuration=auto	geothermal_loop_loop_flow=auto	geothermal_loop_boreholes_count=auto	geothermal_loop_boreholes_length=auto	geothermal_loop_boreholes_spacing=auto	geothermal_loop_boreholes_diameter=auto	geothermal_loop_grout_type=auto	geothermal_loop_pipe_type=auto	geothermal_loop_pipe_diameter=auto
```

Delta: `heat_pump_heating_capacity_retention_fraction` + `heat_pump_heating_capacity_retention_temp` collapsed into the single `heat_pump_heating_capacity_fraction_17_f`; `heat_pump_cooling_compressor_type` renamed to `heat_pump_compressor_type`; `heat_pump_cooling_sensible_heat_fraction` removed; `heat_pump_pan_heater_watts` and `heat_pump_pan_heater_control_type` added. Argument order above follows the v1.11 sibling row `HVAC Heating Efficiency | "ASHP, SEER 14.3, 8.5 HSPF"`. Every `<TBD ...>` is yours to resolve; the tree currently holds the v1.10 line above instead.

### 5. HVAC Heating Efficiency | "Dual-Fuel ASHP, SEER 15.2, 7.8 HSPF2, Integrated Backup, 95.0% AFUE NG, 35F switchover"

Referenced from: `project_national/sdr_upgrades_tmy3.yml`

**v1.10 (as added on `new_sampling_postprocessing`):**

```
HVAC Heating Efficiency	"Dual-Fuel ASHP, SEER 15.2, 7.8 HSPF2, Integrated Backup, 95.0% AFUE NG, 35F switchover"	ResStockArguments	heating_system_type=none	heating_system_heating_efficiency=0	heating_system_heating_capacity=auto	heating_system_heating_autosizing_limit=auto	heating_system_fraction_heat_load_served=1	heating_system_has_flue_or_chimney=auto	heat_pump_type=air-to-air	heat_pump_heating_efficiency_type=HSPF2	heat_pump_heating_efficiency=7.8	heat_pump_cooling_efficiency_type=SEER2	heat_pump_cooling_efficiency=15.2	heat_pump_sizing_methodology=ACCA	heat_pump_sizing_is_duct_limited=false	heat_pump_backup_sizing_methodology=auto	heat_pump_heating_capacity=auto	heat_pump_heating_autosizing_limit=auto	heat_pump_fraction_heat_load_served=1	heat_pump_cooling_capacity=auto	heat_pump_cooling_autosizing_limit=auto	heat_pump_fraction_cool_load_served=1	heat_pump_backup_use_existing_system=false	heat_pump_backup_type=integrated	heat_pump_backup_fuel=natural gas	heat_pump_backup_heating_efficiency=0.950	heat_pump_backup_heating_capacity=auto	heat_pump_backup_heating_autosizing_limit=auto	heat_pump_heating_capacity_retention_fraction=0.5	heat_pump_heating_capacity_retention_temp=5	heat_pump_is_ducted=true	heat_pump_backup_heating_lockout_temp=35	heat_pump_compressor_lockout_temp=35	heat_pump_cooling_compressor_type=single stage	heat_pump_cooling_sensible_heat_fraction=auto	heat_pump_crankcase_heater_watts=auto	geothermal_loop_configuration=none	geothermal_loop_borefield_configuration=auto	geothermal_loop_loop_flow=auto	geothermal_loop_boreholes_count=auto	geothermal_loop_boreholes_length=auto	geothermal_loop_boreholes_spacing=auto	geothermal_loop_boreholes_diameter=auto	geothermal_loop_grout_type=auto	geothermal_loop_pipe_type=auto	geothermal_loop_pipe_diameter=auto
```

**v1.11 (NOT DETERMINED -- skeleton only, does not belong in the tree as-is):**

```
HVAC Heating Efficiency	"Dual-Fuel ASHP, SEER 15.2, 7.8 HSPF2, Integrated Backup, 95.0% AFUE NG, 35F switchover"	ResStockArguments	heating_system_type=none	heating_system_heating_efficiency=0	heating_system_heating_capacity=auto	heating_system_heating_autosizing_limit=auto	heating_system_fraction_heat_load_served=1	heating_system_has_flue_or_chimney=auto	heat_pump_type=air-to-air	heat_pump_heating_efficiency_type=HSPF2	heat_pump_heating_efficiency=7.8	heat_pump_cooling_efficiency_type=SEER2	heat_pump_cooling_efficiency=15.2	heat_pump_sizing_methodology=ACCA	heat_pump_sizing_is_duct_limited=false	heat_pump_backup_sizing_methodology=auto	heat_pump_heating_capacity=auto	heat_pump_heating_autosizing_limit=auto	heat_pump_fraction_heat_load_served=1	heat_pump_cooling_capacity=auto	heat_pump_cooling_autosizing_limit=auto	heat_pump_fraction_cool_load_served=1	heat_pump_backup_use_existing_system=false	heat_pump_backup_type=integrated	heat_pump_backup_fuel=natural gas	heat_pump_backup_heating_efficiency=0.950	heat_pump_backup_heating_capacity=auto	heat_pump_backup_heating_autosizing_limit=auto	heat_pump_heating_capacity_fraction_17_f=<TBD PHYSICS: v1.10 said 0.5 retained at 5F; needs the fraction retained at 17F>	heat_pump_is_ducted=true	heat_pump_backup_heating_lockout_temp=35	heat_pump_compressor_lockout_temp=35	heat_pump_compressor_type=single stage	heat_pump_crankcase_heater_watts=auto	heat_pump_pan_heater_watts=<TBD every sibling v1.11 row uses auto>	heat_pump_pan_heater_control_type=<TBD every sibling v1.11 row uses auto>	geothermal_loop_configuration=none	geothermal_loop_borefield_configuration=auto	geothermal_loop_loop_flow=auto	geothermal_loop_boreholes_count=auto	geothermal_loop_boreholes_length=auto	geothermal_loop_boreholes_spacing=auto	geothermal_loop_boreholes_diameter=auto	geothermal_loop_grout_type=auto	geothermal_loop_pipe_type=auto	geothermal_loop_pipe_diameter=auto
```

Delta: `heat_pump_heating_capacity_retention_fraction` + `heat_pump_heating_capacity_retention_temp` collapsed into the single `heat_pump_heating_capacity_fraction_17_f`; `heat_pump_cooling_compressor_type` renamed to `heat_pump_compressor_type`; `heat_pump_cooling_sensible_heat_fraction` removed; `heat_pump_pan_heater_watts` and `heat_pump_pan_heater_control_type` added. Argument order above follows the v1.11 sibling row `HVAC Heating Efficiency | "ASHP, SEER 14.3, 8.5 HSPF"`. Every `<TBD ...>` is yours to resolve; the tree currently holds the v1.10 line above instead.

