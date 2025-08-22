import polars as pl
from pathlib import Path
import yaml
from resstockpostproc.process_data_dict import get_annual_results_schema, get_timeseries_results_schema

def test_annual_data_dictionary():
    current_dir = Path(__file__).parent
    sdr_yaml_path = current_dir.parent.parent / "project_national" / "sdr_upgrades_tmy3.yml"
    sdr_dict_path = current_dir.parent / "resstockpostproc" / "resources" / "publication" / "sdr_column_definitions.csv"
    cfg = yaml.safe_load(sdr_yaml_path.read_text())
    annual_results_schema = get_annual_results_schema(cfg)

    sdr_dict = pl.read_csv(sdr_dict_path, infer_schema_length=0)
    sdr_names = [n for n in sdr_dict["Annual Name"].to_list() if n is not None]
    unmatched_names = [n for n in sdr_names if n not in annual_results_schema]
    if unmatched_names:
        raise ValueError(
            "These Annual Name values in sdr_column_definitions.csv do not "
            f"match any Input Name or Annual Name values in inputs.csv or outputs.csv:\n {unmatched_names}"
        )

def test_timeseries_data_dictionary():
    current_dir = Path(__file__).parent
    sdr_yaml_path = current_dir.parent.parent / "project_national" / "sdr_upgrades_tmy3.yml"
    sdr_dict_path = current_dir.parent / "resstockpostproc" / "resources" / "publication" / "sdr_column_definitions.csv"
    cfg = yaml.safe_load(sdr_yaml_path.read_text())
    timeseries_results_schema = get_timeseries_results_schema(cfg, "resstock")

    sdr_dict = pl.read_csv(sdr_dict_path, infer_schema_length=0)
    sdr_names = [n for n in sdr_dict["Timeseries Name"].to_list() if n is not None]
    unmatched_names = [n for n in sdr_names if n not in timeseries_results_schema]
    if unmatched_names:
        raise ValueError(
            "These Timeseries Name values in sdr_column_definitions.csv do not "
            f"match any Input Name or Timeseries Name values in inputs.csv or outputs.csv:\n {unmatched_names}"
        )
