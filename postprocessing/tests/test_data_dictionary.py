import polars as pl
from pathlib import Path
import re

def test_data_dictionary():
    current_dir = Path(__file__).parent
    sdr_dict_path = current_dir.parent / "resstockpostproc" / "resources" / "publication" / "sdr_column_definitions.csv"
    input_dict_path = current_dir.parent.parent / "resources" / "data" / "dictionary" / "inputs.csv"
    output_dict_path = current_dir.parent.parent / "resources" / "data" / "dictionary" / "outputs.csv"

    sdr_dict = pl.read_csv(sdr_dict_path, infer_schema_length=0)
    input_dict = pl.read_csv(input_dict_path, infer_schema_length=0)
    output_dict = pl.read_csv(output_dict_path, infer_schema_length=0)
    input_names = input_dict["Input Name"].to_list()
    output_names = output_dict["Annual Name"].to_list()
    all_dict_names = [n for n in input_names + output_names if n is not None]
    plain_names_set = {
        name
        for name in all_dict_names
        if "<type>" not in name and "<scenario_name>" not in name
    }
    pattern_names = [
        name.replace("<type>", "([a-zA-Z0-9_]+)").replace("<scenario_name>", "([a-zA-Z0-9_]+)")
        for name in all_dict_names
        if "<type>" in name or "<scenario_name>" in name
    ]
    sdr_names = [n for n in sdr_dict["Annual Name"].to_list() if n is not None]
    unmatched_names = []
    for name in sdr_names:
        if name in plain_names_set:
            continue
        for pattern in pattern_names:
            if re.match(pattern, name):
                break
        else:
            unmatched_names.append(name)
    allowed_names = {"upgrade"}
    unmatched_names = [n for n in unmatched_names if n not in allowed_names]
    if unmatched_names:
        raise ValueError(
            "These Annual Name values in sdr_column_definitions.csv do not "
            f"match any Input Name or Annual Name values in inputs.csv or outputs.csv:\n {unmatched_names}"
        )

