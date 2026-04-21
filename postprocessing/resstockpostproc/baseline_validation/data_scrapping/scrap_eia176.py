import urllib.request
from pathlib import Path
import pandas as pd
from resstockpostproc.shared_utils.mapping import STATE2ABBR
import re
# Download the 861 Annual Data files from EIA


files_path = Path(__file__).parent / "data"
files_path.mkdir(parents=True, exist_ok=True)
eia861_raw_path = files_path / "eia861_raw"

eia861_raw_path.mkdir(parents=True, exist_ok=True)
eia861_processed_path = files_path / "eia861_processed"
eia861_processed_path.mkdir(parents=True, exist_ok=True)

# https://www.eia.gov/dnav/ng/ng_cons_sum_a_EPG0_vrs_mmcf_m.htm
# The annual values https://www.eia.gov/dnav/ng/ng_cons_sum_a_EPG0_vrs_mmcf_a.htm are simply sums of the monthly values
monthly_file = "NG_CONS_SUM_A_EPG0_VRS_MMCF_M.xls"
full_url = f"https://www.eia.gov/dnav/ng/xls/{monthly_file}"
raw_path = eia861_raw_path / monthly_file
urllib.request.urlretrieve(full_url, raw_path)
df_consumption = pd.read_excel(raw_path, sheet_name="Data 1", skiprows=2, skipfooter=1, na_values=["."])

monthly_heatcontent_file = "NG_CONS_HEAT_A_EPG0_VGTH_BTUCF_M.xls"
raw_path = eia861_raw_path / monthly_heatcontent_file
full_url = f"https://www.eia.gov/dnav/ng/xls/{monthly_heatcontent_file}"
urllib.request.urlretrieve(full_url, raw_path)
df_heat_content_monthly = pd.read_excel(raw_path, sheet_name="Data 1", skiprows=2, skipfooter=1, na_values=["."])

annul_heatcontent_file = "NG_CONS_HEAT_A_EPG0_VGTH_BTUCF_A.xls"
raw_path = eia861_raw_path / monthly_heatcontent_file
full_url = f"https://www.eia.gov/dnav/ng/xls/{annul_heatcontent_file}"
urllib.request.urlretrieve(full_url, raw_path)
df_heat_content_annual = pd.read_excel(raw_path, sheet_name="Data 1", skiprows=2, skipfooter=1, na_values=["."])


def cleanup_df(df, prefix, value_name):
    df = df.rename(columns=lambda col: m.group(1) if (m := re.match(r"([a-zA-Z\. ]*) " + f"{prefix}", col)) else col)
    df.insert(0, "year", pd.to_datetime(df["Date"]).dt.year)
    df.insert(1, "month", pd.to_datetime(df["Date"]).dt.month)
    df = df.drop(columns=["U.S.", "Date"])
    df = df[df["year"] >= 2012]
    df = df.melt(["year", "month"], var_name="state", value_name=value_name)
    df["state"] = df["state"].map(STATE2ABBR)
    assert df["state"].isna().sum() == 0
    return df


df_consumption = cleanup_df(df_consumption, "Natural Gas", "natural_gas_mmcf")
df_heat_content_monthly = cleanup_df(df_heat_content_monthly, "Heat Content", "heat_content_btu_per_cf")
df_heat_content_annual = cleanup_df(df_heat_content_annual, "Heat Content", "heat_content_btu_per_cf")

# for years where monthly data is not available, use annual data
df_heat_content_monthly.set_index(["year", "state"], inplace=True)
df_heat_content_monthly.update(df_heat_content_annual.set_index(["year", "state"]), overwrite=False)
df_heat_content_monthly.reset_index(inplace=True)

df_merged = df_consumption.merge(df_heat_content_monthly, on=["year", "month", "state"])
df_merged["natural_gas_kbtu"] = df_merged["natural_gas_mmcf"] * df_merged["heat_content_btu_per_cf"] * 1000
df_merged.to_csv(eia861_processed_path / "natural_gas_monthly_sales.csv", index=False)