"""Download and preprocess the RECS 2020 public-use microdata."""

from __future__ import annotations
import urllib.request
from pathlib import Path

import polars as pl

from resstockpostproc.baseline_validation.data_processing.recs_mapping import add_enduse_columns
from resstockpostproc.baseline_validation.data_processing.recs_mapping import add_characteristic_columns
from resstockpostproc.baseline_validation.utils import KBTU2KWH
from resstockpostproc.shared_utils.mapping import STATE2ABBR
from resstockpostproc.baseline_validation.io_managers import comparison_data_paths as s3_paths
from resstockpostproc.shared_utils.db_column_names import DataCol

DATA_ROOT = Path(__file__).parent / "data"
RAW_DIR = DATA_ROOT / "recs_raw"
PROCESSED_DIR = DATA_ROOT / "recs_processed"
YEAR = 2020
RECS_RAW_URL = "https://www.eia.gov/consumption/residential/data/2020/csv/recs2020_public_v7.csv"
RAW_FILENAME = RECS_RAW_URL.split("/")[-1]
MICRODATA_FILENAME = "recs_2020_processed_microdata.csv"
MONTHLY_CONSUMPTION_FILENAME = "recs_2020_monthly_consumption.csv"

# Monthly consumption data URLs from EIA
MONTHLY_DATA_URLS = {
    DataCol.ELECTRICITY_TOTAL: "https://www.eia.gov/consumption/residential/data/2020/c&e/xls/CE8.1.M.2020.TotalSiteElectricityConsumption.xlsx",
    DataCol.ELECTRICITY_SPACE_HEATING: "https://www.eia.gov/consumption/residential/data/2020/c&e/xls/CE8.2.M.2020.TotalSpaceHeatingElectricityConsumption.xlsx",
    DataCol.ELECTRICITY_SPACE_COOLING: "https://www.eia.gov/consumption/residential/data/2020/c&e/xls/CE8.3.M.2020.TotalSpaceCoolingElectricityConsumption.xlsx",
    DataCol.ELECTRICITY_WATER_HEATING: "https://www.eia.gov/consumption/residential/data/2020/c&e/xls/CE8.4.M.2020.TotalWaterHeatingElectricityConsumption.xlsx",
    DataCol.NATURAL_GAS_TOTAL: "https://www.eia.gov/consumption/residential/data/2020/c&e/xls/CE8.11.M.2020.TotalSiteNaturalGasConsumption.xlsx",
    DataCol.NATURAL_GAS_SPACE_HEATING: "https://www.eia.gov/consumption/residential/data/2020/c&e/xls/CE8.12.M.2020.TotalSpaceHeatingNaturalGasConsumption.xlsx",
    DataCol.NATURAL_GAS_WATER_HEATING: "https://www.eia.gov/consumption/residential/data/2020/c&e/xls/CE8.13.M.2020.TotalWaterHeatingNaturalGasConsumption.xlsx",
}


def _ensure_directories() -> None:
    """Ensure data directories exist."""
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)


def _download_file(url: str, filepath: Path) -> None:
    """Download a file from URL to filepath."""
    print(f"Downloading {url} to {filepath}")
    urllib.request.urlretrieve(url, filepath)  #  noqa: S310


def _download_raw_microdata() -> Path:
    """Download and save the raw RECS microdata."""
    raw_filepath = RAW_DIR / RAW_FILENAME

    if not raw_filepath.exists():
        _download_file(RECS_RAW_URL, raw_filepath)
        print(f"Downloaded raw microdata to {raw_filepath}")
    else:
        print(f"Raw microdata already exists at {raw_filepath}")

    return raw_filepath


def _process_recs_monthly_excel_sheet(filepath: Path, sheet_name: str) -> pl.DataFrame:
    df = pl.read_excel(filepath, sheet_name=sheet_name, has_header=False)

    # Find key row indices
    all_homes_idx = None
    census_region_idx = None
    state_row_idx = None

    for i in range(df.height):
        first_col = df[i, 0]
        if first_col is not None:
            first_col_str = str(first_col).strip()
            if first_col_str == "All homes":
                all_homes_idx = i
            elif first_col_str == "Census region and division":
                census_region_idx = i + 1  # Data starts in the next row
            elif first_col_str == "States":
                state_row_idx = i + 1  # Data starts in the next row
                break

    if all_homes_idx is None or census_region_idx is None or state_row_idx is None:
        raise ValueError(f"Could not find required headers in {sheet_name}")

    def get_float(recs_data):
        if recs_data == "*":
            return 0.0
        try:
            return float(recs_data)
        except ValueError:
            return None

    all_data = []

    # Extract "All homes" (US Total)
    i = all_homes_idx
    geography_name = "US Total"
    customers = get_float(df[i, 1]) if df.width > 1 else None
    monthly_values = [get_float(df[i, j]) for j in range(3, min(15, df.width))]
    for month_idx, value in enumerate(monthly_values):
        all_data.append(
            {
                "geography": geography_name,
                "month": month_idx + 1,
                "value": value,
                "customers": customers,
                "resolution": 0.1,
            }
        )

    # Extract Census regions/divisions
    for i in range(census_region_idx, state_row_idx - 1):
        first_col = df[i, 0]
        if first_col is None or str(first_col).strip() in ["", "nan", "None"]:
            continue
        geography_name = str(first_col).strip()
        customers = get_float(df[i, 1]) if df.width > 1 else None
        monthly_values = [get_float(df[i, j]) for j in range(3, min(15, df.width))]
        for month_idx, value in enumerate(monthly_values):
            all_data.append(
                {
                    "geography": geography_name,
                    "month": month_idx + 1,
                    "value": value,
                    "customers": customers,
                    "resolution": 0.1,
                }
            )

    # Extract States
    rows_processed = 0
    for i in range(state_row_idx, df.height):
        first_col = df[i, 0]
        if first_col is None or str(first_col).strip() in ["", "nan", "None"]:
            continue
        state_name = str(first_col).strip()
        customers = get_float(df[i, 1]) if df.width > 1 else None
        monthly_values = [get_float(df[i, j]) for j in range(3, min(15, df.width))]
        state_abbrev = STATE2ABBR.get(state_name, state_name)
        for month_idx, value in enumerate(monthly_values):
            all_data.append(
                {
                    "geography": state_abbrev,
                    "month": month_idx + 1,
                    "value": value,
                    "customers": customers,
                    "resolution": 0.1,
                }
            )
        rows_processed += 1
        if rows_processed >= 51:
            break

    if rows_processed < 51:
        raise ValueError(f"Warning: Expected 51 states but found {rows_processed} in {sheet_name}")

    return pl.DataFrame(all_data)


def _extract_monthly_data_from_excel(filepath: Path) -> pl.DataFrame:
    value_df = _process_recs_monthly_excel_sheet(filepath, "Btu")
    value_df = value_df.with_columns(
        pl.col("value") * 1e9 * KBTU2KWH, pl.col("resolution") * 1e9 * KBTU2KWH, pl.col("customers") * 1e6
    )
    rse_df = _process_recs_monthly_excel_sheet(filepath, "rse")
    rse_df = rse_df.select(["geography", "month", "value"]).rename({"value": "rse"})
    monthly_df = value_df.join(rse_df, on=["geography", "month"], how="left")
    return monthly_df


def get_monthly_data() -> pl.DataFrame:
    """Download and process all monthly consumption Excel files."""
    all_records = []

    for enduse, url in MONTHLY_DATA_URLS.items():
        filename = url.split("/")[-1]
        filepath = RAW_DIR / filename
        if not filepath.exists():
            _download_file(url, filepath)
            print(f"Downloaded {filename}")

        data_df = _extract_monthly_data_from_excel(filepath)
        data_df = data_df.rename(
            {"value": f"{enduse}_value", "rse": f"{enduse}_value_rse", "resolution": f"{enduse}_value_resolution"}
        )
        all_records.append(data_df)
        print(f"Processed {len(data_df)} records from {filename}")

    return pl.concat(all_records, how="align")


def process_microdata() -> pl.DataFrame:
    """Process the raw microdata file."""
    raw_filepath = _download_raw_microdata()
    df = pl.read_csv(raw_filepath, infer_schema_length=None)
    df_with_enduse = add_enduse_columns(df)
    df_with_characteristics = add_characteristic_columns(df_with_enduse, data_source="RECS")
    microdata_filepath = PROCESSED_DIR / MICRODATA_FILENAME
    df_with_characteristics.write_csv(microdata_filepath)
    print(f"Saved processed microdata to {microdata_filepath}")
    return df_with_characteristics


def main():
    """Main function to download and process all RECS data."""
    _ensure_directories()

    print("=== Processing RECS 2020 Data ===")

    # Process microdata
    print("\n1. Processing microdata...")
    microdata_df = process_microdata()
    microdata_filepath = PROCESSED_DIR / MICRODATA_FILENAME
    microdata_df.write_csv(microdata_filepath)
    microdata_df.write_csv(s3_paths.RECS_2020_microdata)
    print(f"Processed microdata: {microdata_df.height} records, {microdata_df.width} columns")

    # Process monthly data
    print("\n2. Processing monthly consumption data...")
    monthly_df = get_monthly_data()

    monthly_filepath = PROCESSED_DIR / MONTHLY_CONSUMPTION_FILENAME
    monthly_df.write_csv(monthly_filepath)
    monthly_df.write_csv(s3_paths.RECS_2020_monthly)
    print(f"Saved monthly consumption data to {monthly_filepath}")
    print(f"Monthly data: {monthly_df.height} records")
    print("\n=== RECS data processing complete ===")


if __name__ == "__main__":
    main()
