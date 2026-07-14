# EIA SEDS Prices

This dataset is generated using the U.S. Energy Information Administration (EIA) Open Data API (SEDS):

- https://www.eia.gov/opendata/browser/seds

The data is fetched programmatically from the EIA SEDS API and processed into a simplified state-level fuel price table.

---

## Fuel types included

Only the following residential fuel types are included:

- Electricity ($/MMBtu)
- Natural Gas ($/MMBtu)
- Fuel Oil ($/MMBtu)
- Propane ($/MMBtu)
- Wood ($/MMBtu)

---

## How to generate the file

Run the following OpenStudio task:

```bash
openstudio tasks.rb download_simple_utility_rates
```

This script:

- Calls the EIA SEDS API
- Filters relevant fuel types
- Keeps latest non-zero values per state and fuel
- Writes output to: [ReportUtilityBills/resources/simple_rates/eia_fuel_rates_by_state.csv](ReportUtilityBills/resources/simple_rates/eia_fuel_rates_by_state.csv)