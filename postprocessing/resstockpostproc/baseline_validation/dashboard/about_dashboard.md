# About this dashboard

This dashboard compares two [**ResStock**](https://resstock.nlr.gov/) Standard
Data Releases — **2024 Release 2** and **2025 Release 1** — against three
residential energy consumption datasets: **EIA 2018** (EIA-861, EIA-861M, and
EIA-176 utility filings), **RECS 2020** (the EIA household energy consumption
survey), and **LRD 2018** (a set of utility load research datasets).

## Dataset Summary

| Name                             | Source                                                                                                                                                                                                                                                                                                                                                           | Vintage                                         |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| **ResStock 2024 R2 and 2025 R1** | NLR's bottom-up, physics-based simulation of the U.S. residential building stock, built on EnergyPlus and OpenStudio. [2024 R2](https://resstock.nlr.gov/datasets#ResStock%202024%20Release%202) covers the 48 contiguous states + DC; [2025 R1](https://resstock.nlr.gov/datasets#ResStock%202025%20Release%201) adds Alaska and Hawaii.                        | ~2020 housing characteristics, AMY2018 weather. |
| **EIA 2018**                     | Mandatory utility filings: [EIA-861](https://www.eia.gov/electricity/data/eia861/) (annual electricity, all U.S. electric utilities), [EIA-861M](https://www.eia.gov/electricity/data/eia861m/) (monthly electricity), and [EIA-176](https://www.eia.gov/dnav/ng/ng_cons_sum_a_EPG0_vrs_mmcf_m.htm) (natural gas, all distributors and interstate transporters). | 2018.                                           |
| **RECS 2020**                    | EIA's [_Residential Energy Consumption Survey_](https://www.eia.gov/consumption/residential/) — a nationally representative household survey of ~18,500 occupied primary residences.                                                                                                                                                                             | 2020.                                           |
| **LRD 2018**                     | Load research data: aggregated hourly residential load shapes from ~14 large electric utilities. Illustrative coverage, not nationally representative.                                                                                                                                                                                                           | 2018.                                           |

## How do these datasets differ?

Each dataset measures something slightly different, and the dashboard
adjusts for some but not all of those differences. The most important ones
are below.

### Different years

ResStock uses 2018 weather with ~2020 housing characteristics; EIA and LRD
report 2018 consumption; RECS reports 2020 housing characteristics and 2020
consumption.

### Different populations

- **EIA forms** count every metered residential customer, including vacant
  and seasonally occupied homes that still have an active meter. For EIA
  comparisons, ResStock includes all of its modeled dwelling units.
- **RECS** surveys _occupied primary residences_ only. For RECS comparisons,
  ResStock is filtered to occupied units to match.
- **LRD** is a small, non-representative set of utility service territories
  — useful for load-shape comparisons within those regions, not for
  national totals. LRD comparisons use per-dwelling-unit consumption rather
  than absolute totals, and ResStock is filtered to the utility service
  territory.

### Different methods

- **ResStock** is a bottom-up EnergyPlus simulation: every dwelling unit's
  consumption is computed from physics, and the sample is then statistically
  weighted up to a national total.
- **EIA-861, EIA-861M, and EIA-176** are broad, mandatory censuses of U.S.
  electric utilities (annual EIA-861 and monthly EIA-861M) and natural gas
  distributors (EIA-176), with state-level imputation filling gaps from
  small or missing reporters. These forms also carry **bill-to-calendar
  drift**: utilities report monthly totals based on their own meter-read
  cycles, which don't perfectly align with calendar months and which differ
  across utilities. Utilities with high AMI (advanced metering
  infrastructure) penetration can attribute consumption to calendar days;
  those still on AMR or manual reads report whatever fell into each ~30-day
  route cycle.
- **RECS** estimates each household's annual fuel consumption from actual
  monthly utility billing records (the Energy Supplier Survey), with
  imputation where supplier records are missing and prorating where
  billing periods cross the survey-year boundary. Monthly consumption
  comes from apportioning bills to calendar months via model-guided
  prorating. End-use breakdowns come from an engineering model that
  disaggregates each household's total into space heating, space cooling,
  water heating, refrigeration, and other end uses, calibrated using
  billing data.
- **LRD** is hourly metered data from a sample of customers in each
  participating utility's service territory, normalized to per-dwelling-unit
  consumption.
