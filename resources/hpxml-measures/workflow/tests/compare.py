import os
import argparse
import numpy as np
import pandas as pd
import plotly
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import plotly.express as px


class BaseCompare:
    def __init__(self, base_folder, feature_folder, export_folder, export_file):
        self.base_folder = base_folder
        self.feature_folder = feature_folder
        self.export_folder = export_folder
        self.export_file = export_file

    @staticmethod
    def intersect_rows(df1, df2):
        return df1[df1.index.isin(df2.index)]

    @staticmethod
    def union_columns(df1, df2):
        cols = sorted(list(set(df1.columns) | set(df2.columns)))
        for col in cols:
            if col not in df1.columns:
                df1[col] = np.nan
        return df1[cols]

    def results(self, aggregate_column=None, aggregate_function=None, excludes=[], enum_maps={}):
        aggregate_columns = []
        if aggregate_column:
            aggregate_columns.append(aggregate_column)

        files = []
        for file in os.listdir(self.base_folder):
            if file not in excludes:
                files.append(file)

        for file in sorted(files):
            base_file = os.path.join(self.base_folder, file)
            feature_file = os.path.join(self.feature_folder, file)

            if not os.path.exists(feature_file):
                print("Warning: %s not found. Skipping..." % feature_file)
                continue

            base_df = read_csv(base_file, index_col=0)
            feature_df = read_csv(feature_file, index_col=0)

            base_df = self.intersect_rows(base_df, feature_df)
            feature_df = self.intersect_rows(feature_df, base_df)

            if file == 'results_output.csv':
                base_df = base_df.select_dtypes(exclude=['string', 'bool'])
                feature_df = feature_df.select_dtypes(exclude=['string', 'bool'])

            try:
                df = feature_df - base_df
            except BaseException:
                base_df = self.union_columns(base_df, feature_df)
                feature_df = self.union_columns(feature_df, base_df)
                df = feature_df != base_df
                df = df.astype(int)

            df = df.fillna('NA')
            df.to_csv(os.path.join(self.export_folder, file))

            # Get results charactersistics of groupby columns
            if file == 'results_characteristics.csv':
                group_df = base_df[aggregate_columns]

            # Write grouped & aggregated results dfs
            if file == 'results_output.csv':
                for col, enum_map in enum_maps.items():
                    if col in aggregate_columns:
                        group_df[col] = group_df[col].map(enum_map)

                # Merge groupby df and aggregate
                sim_ct_base = len(base_df)
                sim_ct_feature = len(feature_df)
                if aggregate_columns:
                    base_df = group_df.merge(base_df, 'outer', left_index=True, right_index=True)\
                                      .groupby(aggregate_columns)
                    feature_df = group_df.merge(feature_df, 'outer', left_index=True, right_index=True)\
                                         .groupby(aggregate_columns)
                    if aggregate_function == 'sum':
                        base_df = base_df.sum(min_count=1).stack(dropna=False)
                        feature_df = feature_df.sum(min_count=1).stack(dropna=False)
                    elif aggregate_function == 'mean':
                        base_df = base_df.mean(numeric_only=True).stack(dropna=False)
                        feature_df = feature_df.mean(numeric_only=True).stack(dropna=False)
                else:
                    if aggregate_function == 'sum':
                        base_df = base_df.sum(min_count=1)
                        feature_df = feature_df.sum(min_count=1)
                    elif aggregate_function == 'mean':
                        base_df = base_df.mean(numeric_only=True)
                        feature_df = feature_df.mean(numeric_only=True)

        if not aggregate_function:
            return

        # Write aggregate results df
        deltas = pd.DataFrame()
        deltas['base'] = base_df
        deltas['feature'] = feature_df
        deltas['diff'] = deltas['feature'] - deltas['base']
        deltas_non_zero = deltas[deltas['base'] != 0].index
        deltas.loc[deltas_non_zero, '% diff'] = (100 * (deltas.loc[deltas_non_zero, 'diff'] /
                                                 deltas.loc[deltas_non_zero, 'base']))
        deltas = deltas.round(2)
        deltas.reset_index(level=aggregate_columns, inplace=True)
        deltas.index.name = 'enduse'
        deltas.fillna('n/a', inplace=True)
        sims_df = pd.DataFrame({'base': sim_ct_base,
                                'feature': sim_ct_feature,
                                'diff': 'n/a',
                                '% diff': 'n/a'},
                               index=['simulation_count'])
        sims_df[aggregate_columns] = 'n/a'
        deltas = pd.concat([sims_df, deltas])
        for group in aggregate_columns:
            first_col = deltas.pop(group)
            deltas.insert(0, group, first_col)

        basename, ext = os.path.splitext(file)
        if aggregate_columns:
            basename += '_{aggregate_column}'.format(aggregate_column=aggregate_columns[0])

        deltas.to_csv(
            os.path.join(
                self.export_folder,
                self.export_file))

    def visualize(self, aggregate_column=None, aggregate_function=None, display_column=None,
                  excludes=[], enum_maps={}, cols_to_ignore=[]):
        colors = px.colors.qualitative.Dark24

        aggregate_columns = []
        if aggregate_column:
            aggregate_columns.append(aggregate_column)

        display_columns = []
        if display_column:
            display_columns.append(display_column)

        files = []
        for file in os.listdir(self.base_folder):
            if file not in excludes:
                files.append(file)

        if display_columns or aggregate_columns:
            base_characteristics_df = read_csv(
                os.path.join(
                    self.base_folder,
                    'results_characteristics.csv'),
                index_col=0)[
                display_columns +
                aggregate_columns]
            feature_characteristics_df = read_csv(
                os.path.join(
                    self.feature_folder,
                    'results_characteristics.csv'),
                index_col=0)[
                display_columns +
                aggregate_columns]

        def get_min_max(x_col, y_col, min_value, max_value):
            try:
                if 0.9 * np.min([x_col.min(), y_col.min()]) < min_value:
                    min_value = 0.9 * np.min([x_col.min(), y_col.min()])
            except BaseException:
                pass
            try:
                if 1.1 * np.max([x_col.max(), y_col.max()]) > max_value:
                    max_value = 1.1 * np.max([x_col.max(), y_col.max()])
            except BaseException:
                pass

            return (min_value, max_value)

        def add_error_lines(fig, showlegend, row, col, min_value, max_value):
            fig.add_trace(go.Scatter(x=[min_value, max_value], y=[min_value, max_value],
                                     line=dict(color='black', dash='dash', width=1), mode='lines',
                                     showlegend=showlegend, name='0% Error'), row=row, col=col)
            fig.add_trace(go.Scatter(x=[min_value, max_value], y=[0.9 * min_value, 0.9 * max_value],
                                     line=dict(color='black', dash='dashdot', width=1), mode='lines',
                                     showlegend=showlegend, name='+/- 10% Error'), row=row, col=col)
            fig.add_trace(go.Scatter(x=[min_value, max_value], y=[1.1 * min_value, 1.1 * max_value],
                                     line=dict(color='black', dash='dashdot', width=1), mode='lines',
                                     showlegend=False), row=row, col=col)

        def remove_columns(cols):
            for col in cols[:]:
                if all(v == 0 for v in base_df[col].values) and all(v == 0 for v in feature_df[col].values):
                    cols.remove(col)
            for col in cols[:]:
                for col_to_ignore in cols_to_ignore:
                    if col_to_ignore in col:
                        cols.remove(col)
            return cols

        for file in sorted(files):
            base_file = os.path.join(self.base_folder, file)
            feature_file = os.path.join(self.feature_folder, file)

            if not os.path.exists(feature_file):
                print("Warning: %s not found. Skipping..." % feature_file)
                continue

            base_df = read_csv(base_file, index_col=0)
            feature_df = read_csv(feature_file, index_col=0)

            base_df = self.intersect_rows(base_df, feature_df)
            feature_df = self.intersect_rows(feature_df, base_df)

            for col in base_df.columns:
                if base_df[col].isnull().all():
                    base_df.drop(col, axis=1, inplace=True)
            for col in feature_df.columns:
                if feature_df[col].isnull().all():
                    feature_df.drop(col, axis=1, inplace=True)

            cols = sorted(list(set(base_df.columns) & set(feature_df.columns)))
            cols = remove_columns(cols)
            n_cols = max(len(cols), 1)

            groups = [None]
            if display_columns:
                base_df = base_characteristics_df.join(base_df, how='right')
                feature_df = feature_characteristics_df.join(feature_df, how='right')

                for col, enum_map in enum_maps.items():
                    if col in display_columns:
                        for df in [base_df, feature_df]:
                            df[col] = df[col].map(enum_map)

                groups = list(base_df[display_columns[0]].unique())
            n_groups = max(len(groups), 1)

            vertical_spacing = 0.3 / n_cols
            fig = make_subplots(
                rows=n_cols,
                cols=n_groups,
                subplot_titles=groups * n_cols,
                row_titles=[
                    f'<b>{f}</b>' for f in cols],
                vertical_spacing=vertical_spacing)

            nrow = 0
            for col in cols:
                nrow += 1
                for group in groups:
                    ncol = groups.index(group) + 1
                    showlegend = False
                    if ncol == 1 and nrow == 1:
                        showlegend = True

                    x = base_df.copy()
                    y = feature_df.copy()

                    if group:
                        x = x.loc[x[display_columns[0]] == group, :]
                        y = y.loc[y[display_columns[0]] == group, :]

                    if aggregate_function:
                        x = x.assign(count=1)
                        sizes = x.groupby(aggregate_columns)[['count']].sum().reset_index()

                        if aggregate_function == 'sum':
                            x = x.groupby(aggregate_columns).sum().reset_index()
                            y = y.groupby(aggregate_columns).sum().reset_index()
                        elif aggregate_function == 'mean':
                            x = x.groupby(aggregate_columns).mean().reset_index()
                            y = y.groupby(aggregate_columns).mean().reset_index()

                        for agg_col in sorted(list(x[aggregate_columns[0]].unique())):
                            x_c = x[x[aggregate_columns[0]] == agg_col]
                            y_c = y[y[aggregate_columns[0]] == agg_col]
                            s_c = sizes[sizes[aggregate_columns[0]] == agg_col]
                            fig.add_trace(go.Scatter(x=x_c[col],
                                                     y=y_c[col],
                                                     marker=dict(size=s_c['count'],
                                                                 line=dict(width=1.5,
                                                                           color='DarkSlateGrey')),
                                                     mode='markers',
                                                     text=s_c['count'],
                                                     name=agg_col,
                                                     legendgroup=agg_col,
                                                     showlegend=False),
                                          row=nrow, col=ncol)
                    else:
                        color = [colors[0] for i in y[col]]
                        if 'color_index' in y.columns.values:
                            color = [colors[i] for i in y['color_index']]
                        fig.add_trace(go.Scatter(x=x[col],
                                                 y=y[col],
                                                 marker=dict(size=12,
                                                             color=color,
                                                             line=dict(width=1.5,
                                                                       color='DarkSlateGrey')),
                                                 mode='markers',
                                                 text=x.index,
                                                 name='',
                                                 legendgroup=col,
                                                 showlegend=False),
                                      row=nrow, col=ncol)

                    min_value, max_value = get_min_max(x[col], y[col], 0, 0)
                    add_error_lines(fig, showlegend, nrow, ncol, min_value, max_value)
                    fig.update_xaxes(title_text='base', row=nrow, col=ncol)
                    fig.update_yaxes(title_text='feature', row=nrow, col=ncol)

            fig['layout'].update(template='plotly_white')
            fig.update_layout(width=800 * n_groups, height=600 * n_cols, autosize=False, font=dict(size=12))

            # Re-locate row titles above plots
            increment = (1/n_cols/2)*0.95
            for i in fig['layout']['annotations']:
                text = i['text'].replace('<b>', '').replace('</b>', '')
                if text in cols:
                    i['textangle'] = 0
                    i['x'] = 0
                    i['y'] += increment

            basename, ext = os.path.splitext(file)
            filename = '{basename}.html'.format(basename=basename)
            if self.export_file:
                filename = self.export_file

            plotly.offline.plot(fig,
                                filename=os.path.join(self.export_folder, '{filename}'.format(filename=filename)),
                                auto_open=False)


def read_csv(csv_file_path, **kwargs) -> pd.DataFrame:
    default_na_values = pd._libs.parsers.STR_NA_VALUES
    df = pd.read_csv(csv_file_path, na_values=list(default_na_values - {'None'}), keep_default_na=False, **kwargs)
    return df


if __name__ == '__main__':

    default_base_folder = 'workflow/tests/base_results'
    default_feature_folder = 'workflow/tests/test_results'
    default_export_folder = 'workflow/tests/comparisons'
    actions = [method for method in dir(BaseCompare) if method.startswith('__') is False]

    parser = argparse.ArgumentParser()
    parser.add_argument('-b', '--base_folder', default=default_base_folder, help='Path of the base folder.')
    parser.add_argument('-f', '--feature_folder', default=default_feature_folder, help='Path of the feature folder.')
    parser.add_argument('-e', '--export_folder', default=default_export_folder, help='Path of the export folder.')
    parser.add_argument('-x', '--export_file', help='Path of the export file.')
    parser.add_argument('-a', '--actions', action='append', choices=actions, help='Method to call.')
    args = parser.parse_args()
    print(args)

    if not os.path.exists(args.export_folder):
        os.makedirs(args.export_folder)

    compare = BaseCompare(args.base_folder, args.feature_folder, args.export_folder, args.export_file)

    if args.actions is None:
        args.actions = []

    for action in args.actions:
        if action == 'results':
            compare.results()
        elif action == 'visualize':
            compare.visualize()
