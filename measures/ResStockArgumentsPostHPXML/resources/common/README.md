# Demand Flexibility Peak and Pre-Peak Periods
When analyzing the impact of load flexibility, it is necessary to define the target time periods when demand flexibility will be dispatched to reduce load. These time periods are commonly referred to as on-peak hours. On-peak hours can be identified in different ways depending on the goal. For instance:

-	**Reducing System Peak Power:** Grid-wide net load data can be analyzed to identify hours with the highest demand, and demand flexibility can be dispatched to help to lower overall system peak power requirements.
-	**Responding to Time-of-Use (TOU) Pricing:** Utility rates for individual customers can be analyzed to identify times with the highest electricity prices. This is only applicable for customers with TOU rates. Demand flexibility can be dispatched to reduce individual customer utility bills.
-	**Minimizing Grid Operation Costs:** Grid-wide operational cost data can be analyzed to identify hours with the highest operational costs, and demand flexibility can be dispatched to help lower overall system operation costs.

## Source Data

For demand flexibility measures, the goal is to quantify load flexibility’s technical potential to reduce system peak power in 2050. The measure uses 2050 net load data from Cambium’s MidCase scenario (Gagnon, et al., 2024) to identify the peak hour for each state, categorized by summer months (June to September), winter months (January to March and December) and intermediate months (April to May and October to November). Cambium data is a publicly available dataset that provides future load predictions and other related metrics. The MidCase scenario within Cambium adopts central estimates for key inputs, including technology costs, fuel prices, and demand growth. The identified peak hour is then applied consistently as the dispatch time for each day within the corresponding months for each state.

## Shedding and Shifting Input Files

The input data files are `seasonal_shedding_peak_hours.json` and `seasonal_shedding_peak_hours.json` for shedding and shifting events. These files provide the start and end timestamps for each season (summer, winter, and intermediate) for each State. An example from the `seasonal_shedding_peak_hours.json` file is below.

```
  "IA":
  {
    "summer_peak_start": "2050-08-28 17:00:00",
    "summer_peak_end": "2050-08-28 21:00:00",
    "winter_peak_start": "2050-01-19 17:00:00",
    "winter_peak_end": "2050-01-19 21:00:00",
    "intermediate_peak_start": "2050-11-04 17:00:00",
    "intermediate_peak_end": "2050-11-04 21:00:00"
  },
```