# Comparison plot showcase

A gallery of representative plots from a baseline_validation run. The actual dashboard produces hundreds more — per state, per building type, per climate zone, per vintage, per heating fuel, per end use, plus cross-filtered combinations — all navigable through the interactive sidebar shown below.

## The dashboard

<img src="dashboard_screenshot.png" alt="Dashboard screenshot" width="900">

A single `comparison_dashboard.html` bundles every plot, data table, and metric from the run. The left sidebar filters by comparison dataset, quantity, metric, coverage, and up to two additional dimensions (state, building type, etc.). The right pane shows the selected plot plus its data table and discrepancy metrics (MAPE).

---

## EIA comparisons

Annual and monthly electricity and natural gas consumption compared against published EIA data (861 for electricity, 176 for natural gas).

### State-level tilemap

<img src="eia_electricity_state_tilemap.svg" alt="EIA electricity by state" width="900">

50-state small-multiples laid out geographically. Each cell is one state; the row of bars inside is (reference, ResStock 2024, ResStock 2025). The sidebar column on the right tabulates the percent difference against EIA for every state.

### State tilemap — dwelling-unit counts

<img src="eia_dwelling_units_by_state.svg" alt="EIA dwelling units by state" width="900">

The same tilemap applied to a different quantity — dwelling-unit counts. Useful as a sanity check: ResStock's modeled housing stock should be close to EIA's customer counts in every state, otherwise downstream consumption comparisons are scale-biased.

### U.S. Total — annual total

<img src="eia_electricity_ustotal_annual.svg" alt="EIA electricity U.S. Total annual" width="400">

When the run is focused on "U.S. Total" (via the sidebar), tilemaps collapse to a single grouped-bar plot showing the national aggregate.

### Monthly seasonal pattern

<img src="eia_monthly_electricity_ustotal.svg" alt="EIA monthly electricity per unit" width="400">

Average monthly electricity consumption per dwelling unit, with 95% confidence bands where available. Captures seasonal shape match, not just annual totals.

### State drill-down

<img src="eia_monthly_alaska_drill.svg" alt="EIA Alaska monthly" width="400">

Clicking a single state in the sidebar (Alaska here) produces a focused view with per-month bars and the same 95% CI bands.

### Two-column layout

<img src="eia_natural_gas_by_state_two_column.svg" alt="EIA natural gas by state two-column" width="900">

An alternative layout for state-level annual plots: the 50 states split into two columns of subplots, sorted by magnitude. More compact than the tilemap when magnitude ordering matters more than geography.

### Difference view

<img src="eia_electricity_perunit_difference_ustotal.svg" alt="EIA electricity per-unit difference" width="400">

Every value plot has a "difference view" that replaces the absolute bars with signed percent differences relative to the reference (EIA here). Useful for spotting bias that's hard to see on a log-scale value plot.

---

## RECS comparisons

Residential end-use and household-level distributions compared against RECS 2020 survey microdata. The RECS family supports six cross-filter dimensions: state, census division, building type, climate zone, vintage, and heating fuel.

### Grouped end-use breakdown (per unit)

<img src="recs_enduse_perunit_grouped_ustotal.svg" alt="RECS end-use grouped per unit" width="900">

One of the most-used plots. Bars grouped by end use (space heating, space cooling, water heating, lighting, etc.) with side-by-side comparison between RECS 2020 and each ResStock release. Available for both "per occupied unit" and "per occupied consuming unit" normalizations.

### End-use breakdown — stacked view

<img src="recs_enduse_grouped_ustotal.svg" alt="RECS end-use stacked" width="900">

The stacked-bar variant of the same data. Easier for reading total annual consumption and the relative mix of end uses at a glance.

### Per-consumer normalization

<img src="recs_naturalgas_perconsumer_ustotal.svg" alt="RECS natural gas per consumer" width="400">

"Per occupied consuming dwelling unit" — only households with non-zero consumption for the fuel. Removes the confound of fuel-switching trends from the comparison (if ResStock has fewer gas customers than RECS, per-unit-all totals look artificially low; per-consumer normalizes that out).

### Space heating — annual total

<img src="recs_space_heating_naturalgas_ustotal.svg" alt="RECS space heating annual" width="400">

Per-end-use annual totals. Space heating natural gas shown here; the catalog includes the full matrix of (fuel × end use) combinations.

### Monthly seasonal pattern

<img src="recs_monthly_electricity_ustotal.svg" alt="RECS monthly electricity" width="400">

RECS also publishes monthly consumption estimates; the monthly plot compares seasonal shape, not just annual magnitude.

### Penetration — share using natural gas

<img src="recs_naturalgas_penetration_ustotal.svg" alt="RECS natural gas penetration" width="400">

What share of occupied units use each fuel for each end use. A different metric type (% rather than kWh/therms) useful for catching modeled-housing-stock mismatches.

### Penetration grouped across end uses

<img src="recs_enduse_penetration_grouped.svg" alt="RECS end-use penetration grouped" width="900">

The penetration metric rolled up across every end use at once.

---

## RECS cross-filter dimensions

The sidebar lets you slice any RECS plot by a characteristic. Each of the following is the same "average annual consumption" metric, re-grouped by a different dimension.

### By state

<img src="recs_electricity_by_state_two_column.svg" alt="RECS by state two-column" width="900">

50 states sorted by magnitude (two-column layout). The RECS family also supports the full tilemap layout.

### By building type

<img src="recs_electricity_by_building_type.svg" alt="RECS by building type" width="900">

Mobile home, single-family detached, single-family attached, multi-family variants.

### By climate zone

<img src="recs_space_heating_by_climate_zone.svg" alt="RECS by climate zone" width="900">

Building America climate zones. Shown here for space-heating natural gas — a quantity strongly driven by heating-degree-days.

### By census division

<img src="recs_electricity_by_census_division.svg" alt="RECS by census division" width="900">

Nine U.S. census divisions. Coarser than states but has the advantage of statistical significance on the RECS side even for small end uses.

### By vintage

<img src="recs_electricity_by_vintage.svg" alt="RECS by vintage" width="900">

Pre-1950 through 2010s+. Useful for catching envelope-age and equipment-stock effects.

### By heating fuel

<img src="recs_naturalgas_by_heating_fuel.svg" alt="RECS by heating fuel" width="900">

Slice by each home's primary heating fuel. Natural-gas-heated homes vs electric-heated homes vs fuel-oil-heated homes, etc.

### State drill-down

<img src="recs_enduse_alaska.svg" alt="RECS Alaska end uses" width="900">

Clicking a single state produces the full per-end-use grouped view for that one state. Each cross-filter dimension has its own drill-down view.

---

## Distribution plots — box plots

RECS 2020 is microdata, so the tool can compare full consumption _distributions_ across each ResStock release, not just means. Box-plot layout is the default.

### Box plot — U.S. Total

<img src="recs_distribution_electricity.svg" alt="RECS distribution box plot" width="400">

Min / Q1 / median / Q3 / max for each source's per-household annual consumption. Catches cases where ResStock hits the right mean but the wrong spread (over-uniform or over-dispersed).

### Box plot — space heating

<img src="recs_distribution_space_heating.svg" alt="RECS distribution space heating" width="400">

Distribution of space-heating natural gas per consuming unit. Box plots are available for every end use — electricity, natural gas, space cooling, space heating, water heating, and so on.

### Box plot — by building type

<img src="recs_distribution_electricity_by_building_type.svg" alt="RECS distribution by building type" width="900">

Distributions respect the full cross-filter system — here split by building type rather than rolled up to U.S. Total. Same for state, vintage, climate zone, census division, and heating fuel.

---

## Distribution plots — histograms

Every distribution also has a histogram layout, emphasizing the _shape_ of the distribution rather than the quartile summary. Useful for catching bimodality, truncation, or heavy-tail differences that box plots hide.

### Histogram — U.S. Total

<img src="recs_distribution_electricity_histogram.svg" alt="RECS histogram U.S. Total" width="400">

Annual electricity consumption per occupied dwelling unit. ResStock releases are compared bin-for-bin against RECS 2020 microdata.

### Histogram — by building type

<img src="recs_histogram_by_building_type.svg" alt="RECS histogram by building type" width="700">

Same quantity split by building type. Mobile homes, single-family detached, single-family attached, and multi-family variants each have their own subplot — differences in distribution shape (not just mean) stand out immediately.

### Histogram — by vintage

<img src="recs_histogram_by_vintage.svg" alt="RECS histogram by vintage" width="700">

Distribution of annual electricity consumption split by vintage. Useful for catching envelope-age or equipment-stock effects that show up as shifted or widened distributions.

### Histogram — by heating fuel

<img src="recs_histogram_naturalgas_by_heating_fuel.svg" alt="RECS histogram natural gas by heating fuel" width="700">

Distribution of natural gas consumption (per consuming unit) split by the home's primary heating fuel. NG-heated homes show the expected tail of high annual consumption; other-heated homes' NG use is concentrated near zero.

---

## Difference views

Every value plot has a sibling "difference view" that replaces absolute values with signed percent delta. It's the same underlying data, re-expressed in a way that highlights bias.

### U.S. Total difference

<img src="recs_electricity_ustotal_difference.svg" alt="RECS U.S. Total difference" width="400">

Signed % difference from RECS 2020 for each ResStock release.

### State-level difference

<img src="recs_electricity_by_state_difference.svg" alt="RECS state difference" width="900">

The state tilemap, re-rendered as percent-difference bars. States where ResStock systematically under- or over-shoots RECS jump out.

---

## LRD comparisons

Utility Load Research Data — hourly metered consumption from participating utilities — compared against ResStock's hourly output. The focus is load _shape_, not annual totals.

### Load duration curve

<img src="lrd_load_duration_curve.svg" alt="Load duration curve" width="900">

The signature LRD plot. Hourly load values sorted from highest to lowest across the year, showing the full distribution of load as a function of "percent of hours at or above this level." Mismatch in the peak tail (top 1-5% of hours) is what matters most for capacity planning.

### Load vs outdoor temperature

<img src="lrd_load_vs_temperature.svg" alt="Load vs outdoor drybulb temperature" width="900">

Per-temperature-bin average load, showing the heating slope (cold side) and cooling slope (hot side) plus the shoulder-season minimum. Captures how load responds to weather — a direct check on modeled HVAC behavior.

### Average summer day hourly profile

<img src="lrd_summer_day_hourly.svg" alt="Average summer day hourly" width="900">

Average hourly load across all summer days (Jun–Aug). Same layout is available for winter days, and for the full-year daily average. Catches whether ResStock's modeled diurnal shape matches metered reality — e.g. AM peak timing, evening cooling ramp-down.

### Monthly profile by utility

<img src="lrd_monthly_by_utility.svg" alt="Monthly by utility" width="900">

Average monthly electricity consumption per dwelling unit across every configured utility, with ResStock compared side-by-side. A coarser shape view than load duration curves, but easier for reading seasonal totals.

### Per-utility hourly matrix

<img src="lrd_hourly_matrix_comed.svg" alt="ComEd hourly load matrix" width="700">

Clicking a single utility in the sidebar produces a full month × hour-of-day × day-type matrix. Rows are months; columns are hour-of-day groupings (All Days / Weekday / Weekend). Shown here for ComEd (IL); every configured utility has its own matrix.
