import os
import pandas as pd
import argparse
import plotly
import plotly.express as px

columns = [
    'report_simulation_output.energy_use_total_m_btu',
    # 'report_simulation_output.fuel_use_electricity_total_m_btu',
    # 'report_simulation_output.fuel_use_natural_gas_total_m_btu'
]

def read_csv(csv_file_path, **kwargs) -> pd.DataFrame:
    default_na_values = pd._libs.parsers.STR_NA_VALUES
    df = pd.read_csv(csv_file_path, na_values=list(default_na_values - {'None'}), keep_default_na=False, **kwargs)
    # df = df[df['completed_status'] == 'Success']
    return df

def quick_plot(folder):
    us = []
    for file in os.listdir(folder):
        if 'results' in file and file.endswith('.csv'):
            df = read_csv(os.path.join(folder, file), index_col=['building_id'])
            if 'Baseline' in file:
                df = df[columns]
                b = df
            else:
                u = df[['apply_upgrade.upgrade_name'] + columns]
                us.append(u)

    for col in columns:
        dfs = []    
        for u in us:
            df = u[['apply_upgrade.upgrade_name'] + [col]].rename(columns={col: 'Upgrade'})
            df = df.join(b[[col]])
            df = df.rename(columns={col: 'Baseline'})
            dfs.append(df)

        df = pd.concat(dfs)
        df.groupby('apply_upgrade.upgrade_name').mean().to_csv(os.path.join(folder, '{}.csv'.format(col)))
        fig = px.scatter(df, x='Baseline', y='Upgrade', color='apply_upgrade.upgrade_name', template='plotly_white')
        fig.update_layout(title={'text': col})
        plotly.offline.plot(fig, filename=os.path.join(folder, '{}.html'.format(col)), auto_open=False)

if __name__ == '__main__':

    default_output_directory = 'testing_baseline'

    parser = argparse.ArgumentParser()
    parser.add_argument('-o', '--output_directory', default=default_output_directory, help='The path of the output directory.')

    args = parser.parse_args()

    quick_plot(args.output_directory)
