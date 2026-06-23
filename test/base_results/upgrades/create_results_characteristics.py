import os
import sys
import argparse
import pandas as pd
sys.path.insert(0, os.path.abspath(os.path.join(os.path.abspath(__file__), '../../../../resources/hpxml-measures/workflow/tests')))
from compare import read_csv


if __name__ == '__main__':

  parser = argparse.ArgumentParser()
  parser.add_argument('-f', '--file', help='The path of the results csv file.')

  args = parser.parse_args()
  print(args)

  df = read_csv(args.file)
  df = df[['bldg_id', 'in.geometry_building_type_recs']]
  df = df.rename(columns={'in.geometry_building_type_recs': 'build_existing_model.geometry_building_type_recs'})
  df = df.set_index('bldg_id')
  df.to_csv(os.path.join(os.path.dirname(args.file), 'results_characteristics.csv'))
