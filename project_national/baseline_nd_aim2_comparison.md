# North Dakota AIM-2 Wind Coefficient Sensitivity

## Purpose

This comparison isolates the effect of the conditioned-space AIM-2 wind coefficient (`Cw`) for two North Dakota buildings. The baseline uses the calculated coefficient, while `baseline_nd_aim2` sets `Cw` to `0.0001`, which is effectively zero relative to the baseline values.

The comparison uses `results_annual.csv` for annual metrics and `results_timeseries.csv` for hourly and monthly metrics.

## Experiment verification

| Building | Flue | Baseline `Cw` | Sensitivity `Cw` | Other AIM-2 terms |
|---|---:|---:|---:|---|
| `bldg0029849_no_flue` | No | 0.1601 | 0.0001 | Unchanged (`Cs=0.0954`, `sft=f_t*0.5`) |
| `bldg0102305_flue` | Yes | 0.1274 | 0.0001 | Unchanged (`Cs=0.0711`, `sft=f_t*0.7`) |

The IDF comparison found no substantive model changes other than the conditioned-space AIM-2 `Cw`. In particular, the vented-attic and natural-ventilation wind coefficients are unchanged. Differences in the ordering of output meter objects do not affect the simulation.

Because the AIM-2 wind term is proportional to `Cw`, the sensitivity values retain only 0.06% and 0.08% of the respective baseline wind-flow terms. They can therefore be treated as no-wind cases.

## Building characteristics

| Characteristic | `bldg0029849_no_flue` | `bldg0102305_flue` |
|---|---|---|
| Location | Minot, North Dakota | North Dakota, other census place |
| Building type | Single-family detached | Single-family detached |
| Vintage | 1990s | 2010s |
| Floor area bin | 1,500-1,999 ft2 | 2,000-2,499 ft2 |
| Stories | 2 | 1 |
| Foundation | Heated basement | Vented crawlspace |
| Attic | Vented | Vented |
| Leakage | 10 ACH50 | 4 ACH50 |
| Heating fuel | Electricity | Electricity |
| Water-heater fuel | Electricity | Natural gas |
| Mean weather wind speed | 11.79 mph | 11.22 mph |
| Maximum weather wind speed | 40.27 mph | 48.32 mph |

The natural-gas consumption of the flue building is not space heating; its modeled heating fuel is electricity and its water-heater fuel is natural gas.

## Annual results

### Building 0029849: no flue

| Metric | Baseline | `Cw=0.0001` | Change |
|---|---:|---:|---:|
| Total energy | 86.446 MBtu | 83.424 MBtu | -3.022 MBtu (-3.50%) |
| Electricity | 86.446 MBtu | 83.424 MBtu | -3.022 MBtu (-3.50%) |
| Total heating electricity | 58.928 MBtu | 55.922 MBtu | -3.006 MBtu (-5.10%) |
| Delivered heating load | 74.902 MBtu | 70.998 MBtu | -3.904 MBtu (-5.21%) |
| Heat-pump backup load | 41.228 MBtu | 38.678 MBtu | -2.550 MBtu (-6.19%) |
| Mean infiltration | 114.98 cfm | 93.53 cfm | -21.45 cfm (-18.7%) |
| Winter peak electricity | 17.100 kW | 16.796 kW | -0.304 kW (-1.78%) |
| Peak delivered heating load | 46.436 kBtu/h | 46.162 kBtu/h | -0.274 kBtu/h (-0.59%) |
| Heating unmet hours | 50 h | 46 h | -4 h |

The heating electricity reduction is about 881 kWh. Most of the reduction is heat-pump backup electricity: 2.538 MBtu, or 84% of the total energy reduction.

### Building 0102305: flue

| Metric | Baseline | `Cw=0.0001` | Change |
|---|---:|---:|---:|
| Total energy | 118.880 MBtu | 116.671 MBtu | -2.209 MBtu (-1.86%) |
| Electricity | 102.335 MBtu | 100.128 MBtu | -2.207 MBtu (-2.16%) |
| Natural gas | 16.546 MBtu | 16.542 MBtu | -0.004 MBtu (-0.02%) |
| Total heating electricity | 77.798 MBtu | 75.622 MBtu | -2.176 MBtu (-2.80%) |
| Delivered heating load | 92.708 MBtu | 89.770 MBtu | -2.938 MBtu (-3.17%) |
| Heat-pump backup load | 47.922 MBtu | 46.473 MBtu | -1.449 MBtu (-3.02%) |
| Mean infiltration | 45.76 cfm | 33.84 cfm | -11.92 cfm (-26.0%) |
| Winter peak electricity | 21.420 kW | 21.420 kW | No change |
| Peak delivered heating load | 64.518 kBtu/h | 64.431 kBtu/h | -0.087 kBtu/h (-0.13%) |
| Heating unmet hours | 189 h | 185 h | -4 h |

The heating electricity reduction is about 638 kWh. Natural-gas use is essentially unchanged because it is not used for space heating in this building.

## Monthly results

### Building 0029849: no flue

| Month | Mean infiltration, baseline | Mean infiltration, `Cw=0.0001` | Change | Heating electricity saved |
|---|---:|---:|---:|---:|
| Jan | 173.1 cfm | 158.1 cfm | -8.7% | 189.3 kWh |
| Feb | 164.6 cfm | 144.9 cfm | -12.0% | 200.3 kWh |
| Mar | 154.3 cfm | 133.3 cfm | -13.6% | 187.7 kWh |
| Apr | 100.1 cfm | 80.4 cfm | -19.7% | 23.2 kWh |
| May | 84.1 cfm | 59.0 cfm | -29.8% | 12.9 kWh |
| Jun | 69.3 cfm | 45.0 cfm | -35.1% | 0.6 kWh |
| Jul | 68.8 cfm | 40.1 cfm | -41.7% | 0.0 kWh |
| Aug | 72.5 cfm | 44.8 cfm | -38.2% | 0.0 kWh |
| Sep | 89.7 cfm | 63.3 cfm | -29.4% | 14.9 kWh |
| Oct | 107.0 cfm | 84.4 cfm | -21.1% | 34.6 kWh |
| Nov | 138.2 cfm | 121.7 cfm | -11.9% | 109.4 kWh |
| Dec | 160.6 cfm | 150.1 cfm | -6.6% | 107.9 kWh |

### Building 0102305: flue

| Month | Mean infiltration, baseline | Mean infiltration, `Cw=0.0001` | Change | Heating electricity saved |
|---|---:|---:|---:|---:|
| Jan | 70.4 cfm | 58.8 cfm | -16.5% | 198.7 kWh |
| Feb | 64.4 cfm | 54.8 cfm | -14.8% | 103.6 kWh |
| Mar | 55.1 cfm | 41.7 cfm | -24.3% | 103.6 kWh |
| Apr | 45.1 cfm | 31.1 cfm | -31.1% | 27.6 kWh |
| May | 33.1 cfm | 20.0 cfm | -39.7% | 2.9 kWh |
| Jun | 32.0 cfm | 16.2 cfm | -49.4% | 0.0 kWh |
| Jul | 26.1 cfm | 14.4 cfm | -45.0% | 0.0 kWh |
| Aug | 29.5 cfm | 16.6 cfm | -43.7% | 0.0 kWh |
| Sep | 30.9 cfm | 21.8 cfm | -29.7% | 2.8 kWh |
| Oct | 42.1 cfm | 30.7 cfm | -27.1% | 26.1 kWh |
| Nov | 60.6 cfm | 44.6 cfm | -26.4% | 113.9 kWh |
| Dec | 61.0 cfm | 56.7 cfm | -7.1% | 58.7 kWh |

## Interpretation

1. **Wind materially affects annual infiltration.** Removing the AIM-2 wind term reduces mean infiltration by 18.7% in the no-flue building and 26.0% in the flue building.

2. **The heating-energy response is smaller.** Total heating electricity falls by 5.1% and 2.8%, respectively. Total site energy falls by only 3.5% and 1.9% because non-heating end uses are mostly unaffected.

3. **Cold-month infiltration is less wind-sensitive than annual-average infiltration.** January and December reductions are generally 7-17%, while summer reductions reach 35-49%. This is consistent with the AIM-2 formulation: stack-driven flow is strongest during cold weather and combines with wind-driven flow in quadrature.

4. **Peak heating changes very little.** Peak delivered heating load falls by only 0.6% and 0.1%. The most severe heating hours are predominantly stack- and temperature-driven rather than wind-driven.

5. **The flue building has a larger fractional airflow response but smaller energy response.** Its lower leakage (4 ACH50) yields a smaller absolute infiltration reduction than the 10 ACH50 building. Its flue assumption also increases the shelter multiplier from `f_t*0.5` to `f_t*0.7`, making wind a larger fraction of its lower baseline airflow.

6. **Wind alone is unlikely to explain a large state-level winter discrepancy.** Completely suppressing conditioned AIM-2 wind reduces annual heating electricity by only 3-5% for these examples. Wind can contribute to the discrepancy, especially through backup resistance heat, but temperature, envelope leakage distributions, HVAC sizing/performance, and stock composition likely require separate evaluation.

## Source files

- Baseline IDFs and results: `project_national/baseline_nd/simulation_output/up00/`
- AIM-2 sensitivity IDFs and results: `project_national/baseline_nd_aim2/simulation_output/up00/`
- Buildings: `bldg0029849_no_flue` and `bldg0102305_flue`
