import os
import sys
import pandas as pd
from functools import reduce
import csv
sys.path.insert(0, os.path.abspath(os.path.join(os.path.abspath(__file__), '../../resources/hpxml-measures/workflow/tests')))
from compare import read_csv
import glob


if __name__ == '__main__':

    col_exclusions = ['applicability',
                      'weight',
                      'upgrade_name',
                      'upgrade.']

    folders = ['base_results/upgrades/sdr_annual', 'test/base_results/upgrades/sdr_annual']

    for folder in folders:

        outdir = os.path.join(folder, 'combined')
        if not os.path.exists(outdir):
          os.makedirs(outdir)

        dfs = []
        results_csvs = sorted(glob.glob(os.path.join(folder, '*.csv')))
        for results_csv in results_csvs:
            df = read_csv(results_csv)
            _, upg_ext = os.path.basename(results_csv).split('_')
            upg, _ = upg_ext.split('.')
            df['bldg_id'] = df['bldg_id'].apply(lambda x: '{}-{}'.format(upg, x))
            dfs.append(df)
        df = pd.concat(dfs)
        df = df.set_index('bldg_id')
        
        col_inclusions = []
        for col in df.columns.values:
            if any([col_exclusion in col for col_exclusion in col_exclusions]):
                continue
            col_inclusions.append(col)
        df = df[col_inclusions]

        df = df.rename(columns={'upgrade': 'color_index'})

        df.to_csv(os.path.join(outdir, 'results.csv'))
