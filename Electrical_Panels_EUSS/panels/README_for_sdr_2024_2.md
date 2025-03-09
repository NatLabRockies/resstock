# Electrical Panel Constraints Data Processing for OEDI Standard Dataset (SRD) 2024.2

POC: Lixi.Liu@nrel.gov
updated: 03/08/2025

This file explains the steps taken to postprocess electrical panel information and evaluate capacity constraints for SRD 2024.2 packages, except those containing geothermal heat pump.

Before proceeding, download a copy of all `metadata_and_annual_results` parquet files from [OEDI](https://data.openei.org/s3_viewer?bucket=oedi-data-lake&prefix=nrel-pds-building-stock%2Fend-use-load-profiles-for-us-building-stock%2F2024%2Fresstock_amy2018_release_2%2Fmetadata_and_annual_results%2Fnational%2Fparquet%2F) into a directory.

The following section will reference this directory as `<path_to_oedi_data>`. Do not change any of the files' name inside the directory.

When in doubt, call `--help` on any of the python files used below for syntax help.

### Set up environment
Follow the `README.md` one directory up on instructions on setting up a python environment.

### Generate panel information for baseline
Run the following command to generate a lookup file for electrical panel service rating and available breaker space by building id.
```
python panel_capacity_break_space_prediction_based_on_resource_files_resstock3_2_0.py -o -x <path_to_oedi_data>/baseline_metadata_and_annual_results.parquet
```
The `-o` flag is needed to process OEDI-formatted data. `-x` is used to export the result as a lookup by building id.

### Evalaute panel constraint by upgrade
Run the following command to generate one file per upgrade on panel capacity constraint.

```
$ python postprocess_panel_new_load_nec_for_sdr_2024_2__all_upgrades.py -x -o <path_to_oedi_data>
```
 This command can take a while to complete. The results will be exported to a folder labeled `nec_calculations` within the `<path_to_oedi_data>` directory.

 If desired, convert the generated result parquet files to csv files by running the following:
 ```
 $ python helper_files/for_sdr_2024_2/convert_from_parquet_to_csv.py <path_to_oedi_data>/nec_calculations                                       
 ```
This will create a new folder labeled `nec_calculations_csv` within the `<path_to_oedi_data>` directory for the converted files.
