import os
import sys
import argparse
import numpy as np
import pandas as pd
import csv
import plotly
import plotly.graph_objects as go
from plotly.subplots import make_subplots
sys.path.insert(0, os.path.abspath(os.path.join(os.path.abspath(__file__), '../../resources/hpxml-measures/workflow/tests')))
from compare import BaseCompare, read_csv


enum_maps = {'build_existing_model.geometry_building_type_recs': {'Single-Family Detached': 'SFD',
                                                                  'Mobile Home': 'MH',
                                                                  'Single-Family Attached': 'SFA',
                                                                  'Multi-Family with 2 - 4 Units': 'MF',
                                                                  'Multi-Family with 5+ Units': 'MF'} }

class MoreCompare(BaseCompare):
  def __init__(self, base_folder, feature_folder, export_folder, export_file, map_file):
    self.base_folder = base_folder
    self.feature_folder = feature_folder
    self.export_folder = export_folder
    self.export_file = export_file

    if map_file:
      self.map_columns(map_file)


  def samples(self):

    def value_counts(df, file):
      value_counts = []
      with open(file, 'w', newline='') as f:

        for col in sorted(df.columns):
          if col == 'Building':
            continue

          value_count = df[col].value_counts(normalize=True)
          value_count = value_count.round(2)
          keys_to_values = dict(zip(value_count.index.values, value_count.values))
          keys_to_values = dict(sorted(keys_to_values.items(), key=lambda x: (x[1], x[0]), reverse=True))
          value_counts.append([col])
          value_counts.append(keys_to_values.keys())
          value_counts.append(keys_to_values.values())
          value_counts.append('')

        w = csv.writer(f)
        w.writerows(value_counts)

    df = read_csv(os.path.join(self.base_folder, 'buildstock.csv'), dtype=str)
    file = os.path.join(self.export_folder, 'base_samples.csv')
    value_counts(df, file)

    df = read_csv(os.path.join(self.feature_folder, 'buildstock.csv'), dtype=str)
    file = os.path.join(self.export_folder, 'feature_samples.csv')
    value_counts(df, file)

  def convert_units(self, df):
    for col in df.columns:
      units = col.split('_')[-1]
      if units == 'kwh':
          df[col] *= 3412.14/1000000  # to mbtu
      elif units == 'therm':
          df[col] *= 0.1  # to mbtu

    return


  def write_results(self, base_df, feature_df):
    base_df.to_csv(os.path.join(self.base_folder, 'results_output.csv'))
    feature_df.to_csv(os.path.join(self.feature_folder, 'results_output.csv'))
      

  def map_columns(self, map_file):
    # This function uses a column mapping csv (specified with the -m argument) with columns "map_from" and "map_to"
    # If a "map_from" column is found in either the base or feature results, the column will be updated to the "map_to" value
    # Any columns that do not appear in both base and feature after the mapping will be dropped
    # An entry in the column mapping csv may have multiple column headers separated by a comma, in which case the columns will be summed and first entry will be used as the column header

    ## Characteristics
    # This is optional since you aren't necessarily going to visualize by characteristics
    has_characteristics = False
    if os.path.exists(os.path.join(self.base_folder, 'results_characteristics.csv')) and os.path.exists(os.path.join(self.feature_folder, 'results_characteristics.csv')):
      has_characteristics = True
      base_df_char = read_csv(os.path.join(self.base_folder, 'results_characteristics.csv'), index_col=0)
      feature_df_char = read_csv(os.path.join(self.feature_folder, 'results_characteristics.csv'), index_col=0)

    ## Outputs
    base_df = read_csv(os.path.join(self.base_folder, 'results_output.csv'), index_col=0)
    feature_df = read_csv(os.path.join(self.feature_folder, 'results_output.csv'), index_col=0)

    ## Mapping
    cwd = os.path.dirname(os.path.realpath(__file__))
    map_df = read_csv(map_file, usecols=['map_from','map_to'])
    map_df = map_df.dropna(axis=0)
    map_dict = {k:v for k,v in zip(map_df['map_from'], map_df['map_to'])}

    # Set new base and feature folders
    self.base_folder = os.path.join(self.base_folder, 'map')
    self.feature_folder = os.path.join(self.feature_folder, 'map')
    if not os.path.exists(self.base_folder):
      os.makedirs(self.base_folder)
    if not os.path.exists(self.feature_folder):
      os.makedirs(self.feature_folder)

    ## Characteristics
    if has_characteristics:
      # Align results_charactersitics columns
      base_cols = ['build_existing_model.' + col if  'build_existing_model' not in col else col for col in base_df_char.columns]
      feature_cols = ['build_existing_model.' + col if  'build_existing_model' not in col else col for col in feature_df_char.columns]

      base_df_char.columns = base_cols
      feature_df_char.columns = feature_cols

      common_cols = np.intersect1d(base_df_char.columns, feature_df_char.columns)
      base_df_char = base_df_char[common_cols]
      feature_df_char = feature_df_char[common_cols]

      base_df_char.to_csv(os.path.join(self.base_folder, 'results_characteristics.csv'))
      feature_df_char.to_csv(os.path.join(self.feature_folder, 'results_characteristics.csv'))

    # Skip mapping if not needed
    if set(base_df.columns).issubset(set(feature_df.columns)) or set(feature_df).issubset(set(base_df.columns)):
      self.write_results(base_df, feature_df)
      return

    # Sum columns with more than 1 column header in mapping csv
    results_dfs = {'base': base_df, 'feature': feature_df}
    map_dict_copy = map_dict.copy()
    for key, df in results_dfs.items():
      column_headers = df.columns

      for map_from, map_to in map_dict.items():
        # Sum 'map to' columns and use first parameter as col name
        map_to_s = map_to.split(',')
        if len(map_to_s) > 1: 
          map_to = map_to_s[0]
          if map_to in column_headers:
            # sum columns
            df[map_to] = df[map_to_s].sum(axis=1)
            # update mapping
            map_dict_copy[map_from] = map_to 
            # drop summed columns
            df.drop(map_to_s[1:], axis='columns', inplace=True)

        # Sum 'map from' columns and use first parameter as col name
        map_from_s = map_from.split(',')
        if len(map_from_s)>1:
          map_from = map_from_s[0]
          if map_from in column_headers:
            # sum columns
            df[map_from] = df[map_from_s].sum(axis=1)
            # update mapping
            map_dict_copy[map_from] = map_to
            # drop summed columns
            df.drop(map_from_s[1:], axis='columns', inplace=True)

      results_dfs[key] = df

    base_df = results_dfs['base']
    feature_df = results_dfs['feature']

    # Convert units
    self.convert_units(base_df)
    self.convert_units(feature_df)
   
    # Map column headers
    map_dict = map_dict_copy
    base_df.rename(columns=map_dict, inplace=True)
    feature_df.rename(columns=map_dict, inplace=True)

    # Output only columns in common
    common_cols = base_df.columns.intersection(feature_df.columns)
    base_df = base_df[common_cols]
    feature_df = feature_df[common_cols]

    base_df = base_df.reindex(sorted(base_df.columns), axis=1)
    feature_df = feature_df.reindex(sorted(feature_df.columns), axis=1)

    # Store new mapped csvs
    self.write_results(base_df, feature_df)
    print("Wrote mapped results_output.csv for base and feature results")
    return


  def timeseries(self):
    files = []
    for file in os.listdir(self.base_folder):
      files.append(file)

    def cvrmse(b, f):
      if np.all(b == 0):
        return 'NA'

      s = np.sum((b - f) ** 2)
      s /= (len(b) - 1)
      s **= (0.5)
      s /= np.mean(b)
      s *= 100.0
      return s

    def nmbe(b, f):
      if np.all(b == 0):
        return 'NA'

      s = np.sum(b - f)
      s /= (len(b) - 1)
      s /= np.mean(b)
      s *= 100.0
      return s

    metrics = ['cvrmse', 'nmbe']

    for file in sorted(files):
      base_df = read_csv(os.path.join(self.base_folder, file), index_col=0)
      feature_df = read_csv(os.path.join(self.feature_folder, file), index_col=0)

      base_df = self.intersect_rows(base_df, feature_df)
      feature_df = self.intersect_rows(feature_df, base_df)

      cols = sorted(list(set(base_df.columns) & set(feature_df.columns)))

      for time_col in ['Time', 'time']:
        if time_col in cols:
          cols.remove(time_col)

      if not cols:
        return

      g = base_df.groupby('PROJECT')
      groups = g.groups.keys()

      dfs = []
      for group in groups:
        b_df = base_df.copy()
        f_df = feature_df.copy()

        cdfs = []
        for col in cols:
          b = b_df.loc[group][col].values
          f = f_df.loc[group][col].values

          data = {'CVRMSE (%)': [cvrmse(b, f)], 'NMBE (%)': [nmbe(b, f)]}
          df = pd.DataFrame(data=data, index=[group])
          columns = [(col, 'CVRMSE (%)'), (col, 'NMBE (%)')]
          df.columns = pd.MultiIndex.from_tuples(columns)
          cdfs.append(df)

        df = pd.concat(cdfs, axis=1)
        dfs.append(df)

      df = pd.concat(dfs).transpose()
      df.to_csv(os.path.join(self.export_folder, 'cvrmse_nmbe_{}'.format(file)))

if __name__ == '__main__':

  default_base_folder = 'test/base_results/baseline'
  default_feature_folder = 'test/base_results/results'
  default_export_folder = 'test/base_results/comparisons'
  actions = [method for method in dir(MoreCompare) if method.startswith('__') is False]
  actions += ['timeseries']
  aggregate_columns = ['build_existing_model.geometry_building_type_recs',
                       'build_existing_model.census_region']
  aggregate_functions = ['sum', 'mean']
  display_columns = ['build_existing_model.geometry_building_type_recs',
                     'build_existing_model.geometry_foundation_type',
                     'build_existing_model.census_region']
  map_result_choices = ['base', 'feature']

  parser = argparse.ArgumentParser()
  parser.add_argument('-b', '--base_folder', default=default_base_folder, help='The path of the base folder.')
  parser.add_argument('-f', '--feature_folder', default=default_feature_folder, help='The path of the feature folder.')
  parser.add_argument('-e', '--export_folder', default=default_export_folder, help='The path of the export folder.')
  parser.add_argument('-x', '--export_file', help='The path of the export file.')
  parser.add_argument('-a', '--actions', action='append', choices=actions, help='The method to call.')
  parser.add_argument('-ac', '--aggregate_column', choices=aggregate_columns, help='On which column to aggregate data.')
  parser.add_argument('-af', '--aggregate_function', choices=aggregate_functions, help='Function to use for aggregating data.')
  parser.add_argument('-dc', '--display_column', choices=display_columns, help='How to organize the subplots.')
  parser.add_argument('-m', '--map_file', help='Column mapping csv path.')

  args = parser.parse_args()
  print(args)

  if not os.path.exists(args.export_folder):
    os.makedirs(args.export_folder)
    
  compare = MoreCompare(args.base_folder, args.feature_folder, args.export_folder, args.export_file, args.map_file)

  if args.actions == None:
    args.actions = [] 

  for action in args.actions:
    if action == 'samples':
      compare.samples()
    elif action == 'results':
      excludes = ['buildstock.csv']
      compare.results(args.aggregate_column, args.aggregate_function, excludes, enum_maps)
    elif action == 'visualize':
      excludes = ['buildstock.csv', 'results_characteristics.csv']
      categories = ['.component_load_', '.emissions_', '.end_use_', '.energy_use_', '.fuel_use_', '.hot_water_', '.hvac_', '.load_', '.peak_', '.resilience_', '.unmet_hours_', '.electric_panel_', 'report_utility_bills.', 'upgrade_costs.', 'qoi_report.']
      for category in categories:
        export_file, ext = args.export_file.split('.')
        export_file = '{}_{}.{}'.format(export_file, category.strip('.').rstrip('_'), ext)
        cols_to_ignore = ['color_index'] + categories
        cols_to_ignore.remove(category)
        compare = MoreCompare(args.base_folder, args.feature_folder, args.export_folder, export_file, args.map_file)
        compare.visualize(args.aggregate_column, args.aggregate_function, args.display_column, excludes, enum_maps, cols_to_ignore)
    elif action == 'timeseries':
      compare.timeseries()
