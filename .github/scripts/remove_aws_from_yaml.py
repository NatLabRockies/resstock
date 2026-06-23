"""
Script to remove the aws section from the yaml file.

Usage: python remove_aws_from_yaml.py <yaml_file>

Example: python remove_aws_from_yaml.py project_national/sdr_upgrades_amy2018.yml

This script is used in the GitHub workflow to remove the aws section from the yaml file
when being run in a PR branch so as to prevent the workflow from trying to upload the
results to s3 and Athena. It is not used when running on the develop branch as we want
the workflow to upload the results to s3 and Athena from the develop branch.
"""

import yaml
import sys

file_path = sys.argv[1]

with open(file_path, 'r') as f:
    data = yaml.safe_load(f)

if 'postprocessing' in data and 'aws' in data['postprocessing']:
    del data['postprocessing']['aws']
    print(f"Removed 'aws' section from {file_path}")
else:
    print(f"'aws' section not found in {file_path}")

with open(file_path, 'w') as f:
    yaml.dump(data, f, default_flow_style=False)
