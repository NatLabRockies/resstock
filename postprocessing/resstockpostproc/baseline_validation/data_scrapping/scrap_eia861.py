import urllib.request
from pathlib import Path
import zipfile
import pandas as pd
import ssl
# Download the 861 Annual Data files from EIA

files_path = Path(__file__).parent / "data"
files_path.mkdir(parents=True, exist_ok=True)
eia861_raw_path = files_path / "eia861_raw"

eia861_raw_path.mkdir(parents=True, exist_ok=True)
eia861_processed_path = files_path / "eia861_processed"
eia861_processed_path.mkdir(parents=True, exist_ok=True)


def get_excel_file(zip_file, file_name):
    all_file_names = [f"{file_name}.xlsx", f"{file_name}.xls",
                  f"{file_name.lower()}.xlsx", f"{file_name.lower()}.xls"]
    for candidate_file in all_file_names:
        try:
            file = zip_file.open(candidate_file)
            print(f"Read {candidate_file}.")
            return file
        except KeyError:
            continue
    raise KeyError(f"File {file_name} not found in zip file {zip_file}")

sales_dfs = []
territory_dfs = []
last_year = 2026
for year in range(2012, last_year + 1):
    raw_file = eia861_raw_path / f"f861{year}.zip"
    if not raw_file.exists():
        if year < last_year:
            url = f"https://www.eia.gov/electricity/data/eia861/archive/zip/f861{year}.zip"
        else:
            url = f"https://www.eia.gov/electricity/data/eia861/zip/f861{year}.zip"
        print(f"Downloading {url}")
        ssl_context = ssl._create_unverified_context()
        with urllib.request.urlopen(url, context=ssl_context) as response:
            with open(raw_file, 'wb') as out_file:
                out_file.write(response.read())
    try:
        filezip = zipfile.ZipFile(raw_file)
    except zipfile.BadZipFile:
        print(f"File {raw_file} is not a zip file.")
        continue
    # Open Sales_Ult_Cust_2018.xlsx from zip file
    sales_file = get_excel_file(filezip, f"Sales_Ult_Cust_{year}")
    # read the excel file
    cols_to_read = ["Data Year", "Utility Number", "Utility Name", "State", "Megawatthours", "Count", "Part"]
    sales_df = pd.read_excel(sales_file, usecols=cols_to_read, skiprows=2, skipfooter=1, na_values=["."],
                             sheet_name=0, verbose=False)
    # Exclude "C" for Sales and Customers aggregation according to EIA
    # Check the footnote in the excel file
    sales_df = sales_df[sales_df["Part"] != "C"]

    col_rename_dict = {"Data Year": "year", "Utility Number": "eiaid", "Utility Name": "utility_name",
                       "State": "state", "Megawatthours": "sales_mwh",
                       "Count": "customers", "County": "county"}
    sales_df.rename(columns=col_rename_dict, inplace=True)
    sales_df = sales_df.groupby(['year', 'eiaid', 'state']).agg({"utility_name": "first", 'sales_mwh': 'sum',
                                                                 'customers': 'sum'})

    sales_dfs.append(sales_df.reset_index())

    territory_file = get_excel_file(filezip, f"Service_Territory_{year}")
    territory_df = pd.read_excel(territory_file, na_values=["."], sheet_name=0, verbose=False)
    territory_dfs.append(territory_df)

all_territory_df = pd.concat(territory_dfs)
all_sales_df = pd.concat(sales_dfs)

all_territory_df.to_csv(eia861_processed_path / "utility_territories.csv", index=False)
all_sales_df.to_csv(eia861_processed_path / "electricity_annual_sales.csv", index=False)