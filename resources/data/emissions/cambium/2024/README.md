These are all 15 available Standard Scenarios for three metrics at GEA geographic resolution. Metrics:
1. LRMER levelized over 15 years
2. LRMER levelized over 25 years
3. average emissions rate (AER) non-levelized, month-hour average over 2025-2050

2024 Cambium release data:
- Levelized **LRMER** come from Cambium24_Workbook.xlsx (available via [Long-run Marginal Emission Rates for Electricity - Workbooks for 2024 Cambium Data](https://data.nlr.gov/submissions/289)):

  On the "Levelized LRMER" tab:
  - Emission | CO2e
  - Emission stage | Combined
  - Start year | 2027
  - Evaluation period (years) | 15, 25
  - Discount rate (real) | 0.03
  - Scenario | Mid-case, Low RE Cost, High RE Cost, Low RE Cost High NG Price, High RE Cost Low NG Price
  - Global Warming Potentials | 100-year (AR5)
  - Location | End-use

- Non-levelized **AER** come from the Scenario Viewer (available via [Scenario Viewer :: Data Downloader](https://cambium.nrel.gov)):

  Browse "Cambium 24", and on the "Download" tab:
  - Scenarios | Mid-case, Low RE Cost, High RE Cost, Low RE Cost High NG Price, High RE Cost Low NG Price
  - Time Resolutions | Hourly
  - Location Types | GEA Regions

  Extract .zip files and copy the CSV files from all scenarios into a single directory.

  Run the `process_cambium_AER.py` script available in the resstock-estimation repository to create month-hour averages across all years.

  Copy the resulting data for each scenario into a tab of the Cambium_2024_Select_For_ResStock.xlsx file.

  Run the `process_cambium_LRMER.py` script available in the resstock-estimation repository to export the data into the 2024 directory.

Note that the GEA regions have change from previous Cambium datasets.
See the Generation And Emissions Assessment Region map [here](https://github.com/NREL/resstock/wiki/Generation-And-Emissions-Assessment-Region-Map-2023-Update).
