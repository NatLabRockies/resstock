"""
Script to switch a project yaml file to a precomputed sample for CI.

Usage: python use_precomputed_sample_in_yaml.py <yaml_file> <sample_file> <n_buildings_represented>

Example: python use_precomputed_sample_in_yaml.py project_national/sdr_upgrades_amy2018.yml \
    resources/sdr_minimal_buildstock.csv 139647020

The committed project file uses the residential_stratified sampler, as a production run does. The
stratified sampler is too large to run in CI, so the GitHub workflow uses this script to swap in the
minimal buildstock from the sdr-options-analysis job instead. The precomputed sampler gives every
building the flat weight n_buildings_represented / n_datapoints, so it needs
baseline:n_buildings_represented, which the stratified sampler rejects. The sample file path is
relative to the project directory, as in the sampler args.
"""

import sys

import yaml

file_path, sample_file, n_buildings_represented = sys.argv[1], sys.argv[2], int(sys.argv[3])

with open(file_path, "r") as f:
    data = yaml.safe_load(f)

old_type = data["sampler"]["type"]
data["sampler"] = {"type": "precomputed", "args": {"sample_file": sample_file}}
data.setdefault("baseline", {})["n_buildings_represented"] = n_buildings_represented
print(
    f"Replaced the {old_type} sampler in {file_path} with precomputed {sample_file}, "
    f"n_buildings_represented {n_buildings_represented}"
)

with open(file_path, "w") as f:
    yaml.dump(data, f, default_flow_style=False, sort_keys=False)
