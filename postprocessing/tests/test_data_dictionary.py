import polars as pl
from pathlib import Path
import yaml
from resstockpostproc.process_data_dict import get_annual_results_schema, get_resstock_timeseries_schema, get_bsb_timeseries_schema
import pytest


@pytest.mark.parametrize("yaml_path", ["sdr_upgrades_tmy3.yml", "national_baseline.yml"])
def test_annual_data_dictionary(yaml_path: str):
    current_dir = Path(__file__).parent
    sdr_yaml_path = current_dir.parent.parent / "project_national" / yaml_path
    sdr_dict_path = current_dir.parent / "resstockpostproc" / "resources" / "publication" / "sdr_column_definitions.csv"
    cfg = yaml.safe_load(sdr_yaml_path.read_text())
    annual_results_schema = get_annual_results_schema(cfg)
    unresolved_cols = [col for col in annual_results_schema if "<scenario_name>" in col or "<type>" in col]
    if unresolved_cols:
        raise ValueError(
            "get_annual_results_schema function wasn't able to resolve these columns: \n {unresolved_cols}"
        )
    if yaml_path == "national_baseline.yml":
        return  # sdr_column_definitions are based on the sdr_upgrades_tmy3.yml

    sdr_dict = pl.read_csv(sdr_dict_path, infer_schema_length=0)
    sdr_names = [n for n in sdr_dict["Annual Name"].to_list() if n is not None]
    unmatched_names = [n for n in sdr_names if n not in annual_results_schema]
    if unmatched_names:
        raise ValueError(
            "These Annual Name values in sdr_column_definitions.csv do not "
            f"match any Input Name or Annual Name values in inputs.csv or outputs.csv:\n {unmatched_names}"
        )


@pytest.mark.parametrize("type", ["resstock", "buildstockbatch"])
def test_timeseries_data_dictionary(type: str):
    current_dir = Path(__file__).parent
    sdr_yaml_path = current_dir.parent.parent / "project_national" / "sdr_upgrades_tmy3.yml"
    sdr_dict_path = current_dir.parent / "resstockpostproc" / "resources" / "publication" / "sdr_column_definitions.csv"
    cfg = yaml.safe_load(sdr_yaml_path.read_text())
    if type == "buildstockbatch":
        timeseries_results_schema = get_bsb_timeseries_schema(cfg)
    else:
        timeseries_results_schema = get_resstock_timeseries_schema(cfg)
    
    time_cols = [col for col in timeseries_results_schema if "time" in col.lower()]
    assert len(time_cols) > 0
    assert all(timeseries_results_schema[col] == pl.Datetime(time_unit="ms") for col in time_cols)
    unresolved_cols = [col for col in timeseries_results_schema if "<scenario_name>" in col or "<type>" in col]
    if unresolved_cols:
        raise ValueError(
            "get_timeseries_results_schema function wasn't able to resolve these columns: \n {unresolved_cols}"
        )
    if type == "buildstockbatch":
        return  # sdr_column_definitions.csv uses ResStock Timeseries name for the mapping
    sdr_dict = pl.read_csv(sdr_dict_path, infer_schema_length=0)
    sdr_names = [n for n in sdr_dict["Timeseries Name"].to_list() if n is not None]
    unmatched_names = [n for n in sdr_names if n not in timeseries_results_schema]
    if unmatched_names:
        raise ValueError(
            "These Timeseries Name values in sdr_column_definitions.csv do not "
            f"match any Input Name or Timeseries Name values in inputs.csv or outputs.csv:\n {unmatched_names}"
        )
