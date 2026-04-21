from pathlib import Path
import pandas as pd
import urllib.request
# Download the 861 Annual Data files from EIA

files_path = Path(__file__).parent / "data"
files_path.mkdir(parents=True, exist_ok=True)
eia861_raw_path = files_path / "eia861_raw"

eia861_raw_path.mkdir(parents=True, exist_ok=True)
eia861_processed_path = files_path / "eia861_processed"
eia861_processed_path.mkdir(parents=True, exist_ok=True)

sales_dfs = []
last_year = 2025
for year in range(2012, last_year + 1):
    if year <= 2016:
        filename = f"f826{year}.xls"
    elif year <= 2020:
        filename = f"retail_sales_{year}.xlsx"
    else:
        filename = f"sales_ult_cust_{year}.xlsx"

    raw_file = eia861_raw_path / filename

    if not raw_file.exists():
        if year < last_year:
            url = f"https://www.eia.gov/electricity/data/eia861m/archive/xls/{filename}"
        else:
            url = f"https://www.eia.gov/electricity/data/eia861m/xls/{filename}"
        print(f"Downloading {url}")
        response = urllib.request.urlopen(url)
        if "spreadsheetml.sheet" not in response.headers.get_content_type():
            raise ValueError(f"URL {url} does not contain a downloadable file")
        urllib.request.urlretrieve(url, raw_file)


    # read the excel file
    print(f"Reading {raw_file}")
    if year == 2012:
        cols_to_read = ["UTILITYID", "UTILNAME", "STATE_CODE", "YEAR", "MONTH",  "RESIDENTIAL SALES (MWh)",
                        "RESIDENTIAL CUSTOMERS"]
        sales_df = pd.read_excel(raw_file, usecols=cols_to_read, skipfooter=1, na_values=["."], sheet_name=0)
        col_rename_dict = {"YEAR": "year", "MONTH": "month", "UTILITYID": "eiaid", "UTILNAME": "utility_name",
                           "STATE_CODE": "state", "RESIDENTIAL SALES (MWh)": "sales_mwh",
                           "RESIDENTIAL CUSTOMERS": "customers"}
        sales_df.rename(columns=col_rename_dict, inplace=True)
    else:
        cols_to_read = ["Year", "Month", "Utility Number",
                        "Utility Name", "State", "Megawatthours", "Count"]
        sales_df = pd.read_excel(raw_file, usecols=cols_to_read, skiprows=2, skipfooter=1, na_values=["."],
                                 sheet_name=0)
        col_rename_dict = {"Year": "year", "Month": "month", "Utility Number": "eiaid",
                           "Utility Name": "utility_name",
                           "State": "state", "Megawatthours": "sales_mwh",
                           "Count": "customers"}
        sales_df.rename(columns=col_rename_dict, inplace=True)
    # Exclude 88888 utility which represents "All Utilities"
    sales_df = sales_df[sales_df["eiaid"] != 88888]
    sales_df = sales_df.groupby(["year", "month", "eiaid", "state"]).agg({"utility_name": "first", "sales_mwh": "sum",
                                                                          "customers": "sum"})

    sales_dfs.append(sales_df.reset_index())

all_sales_df = pd.concat(sales_dfs)
all_sales_df.to_csv(eia861_processed_path / "electricity_monthly_sales.csv", index=False)
