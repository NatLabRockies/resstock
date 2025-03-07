# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.
import os
import re
import logging
import numpy as np
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
from matplotlib import ticker
import plotly.express as px
import seaborn as sns
import plotly.graph_objects as go

matplotlib.use('Agg')
logger = logging.getLogger(__name__)

# color setting for savings distributions
color_violin = "#EFF2F1"
color_interquartile = "#6A9AC3"

class PlottingMixin():

    # plot energy consumption by fuel type and enduse
    def plot_energy_by_enduse_and_fuel_type(self, df, column_for_grouping, color_map, output_dir):

        # ghg columns; uses Cambium low renewable energy cost 15-year for electricity
        cols_enduse_ann_en = self.COLS_ENDUSE_ANN_ENGY
        wtd_cols_enduse_ann_en = [self.col_name_to_weighted(c, 'tbtu') for c in cols_enduse_ann_en]


        # plots for both applicable and total stock
        for applicable_scenario in ['stock', 'applicable_only']:

            df_scen = df.copy()


            if applicable_scenario == 'applicable_only':
                applic_bldgs = df_scen.loc[(df_scen[self.UPGRADE_NAME]!='Baseline') & (df_scen['applicability']==True), self.BLDG_ID]
                df_scen = df_scen.loc[df_scen[self.BLDG_ID].isin(applic_bldgs), :]

            # groupby and long format for plotting
            df_emi_gb = (df_scen.groupby(column_for_grouping, observed=True)[wtd_cols_enduse_ann_en].sum()).reset_index()
            df_emi_gb = df_emi_gb.loc[:, (df_emi_gb !=0).any(axis=0)]
            df_emi_gb_long = df_emi_gb.melt(id_vars=[column_for_grouping], value_name='Annual Energy Consumption (TBtu)').sort_values(by='Annual Energy Consumption (TBtu)', ascending=False)

            # naming for plotting
            df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('calc.weighted.', '', regex=True)
            df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('.energy_consumption..tbtu', '', regex=True)
            # split end use and fuel names for coordianted color and texture assignments
            df_emi_gb_long[['Fuel Type', 'End Use']] = df_emi_gb_long['variable'].str.split('.', expand=True)
            df_emi_gb_long['Fuel Type'] = df_emi_gb_long['Fuel Type'].str.replace('_', ' ', regex=True)
            df_emi_gb_long['Fuel Type'] = df_emi_gb_long['Fuel Type'].str.title()
            df_emi_gb_long['End Use'] = df_emi_gb_long['End Use'].str.replace('_', ' ', regex=True)
            df_emi_gb_long['End Use'] = df_emi_gb_long['End Use'].str.title()

            # add OS color map
            color_dict = {'Heating':'#EF1C21',
            'Cooling':'#0071BD',
            'Interior Lighting':'#F7DF10',
            'Exterior Lighting':'#DEC310',
            'Interior Equipment':'#4A4D4A',
            'Exterior Equipment':'#B5B2B5',
            'Fans':'#FF79AD',
            'Pumps':'#632C94',
            'Heat Rejection':'#F75921',
            'Humidification':'#293094',
            'Heat Recovery': '#CE5921',
            'Water Systems': '#FFB239',
            'Refrigeration': '#29AAE7',
            'Generators': '#8CC739'}

            # set patterns by fuel type
            pattern_dict = {
                'Electricity': "",
                'Natural Gas':"/",
                'District Cooling':"x",
                'District Heating':".",
                'Other Fuel':'+'
            }

            # set category orders by end use
            cat_order = {
               'End Use': [ 'Interior Equipment',
                            'Fans',
                            'Cooling',
                            'Interior Lighting',
                            'Heating',
                            'Water Systems',
                            'Exterior Lighting',
                            'Refrigeration',
                            'Pumps',
                            'Heat Recovery',
                            'Heat Rejection'],
                'Fuel Type': [
                            'Electricity',
                            'Natural Gas',
                            'District Cooling',
                            'District Heating',
                            'Other Fuel',
                ]
            }

            # plot
            fig = px.bar(df_emi_gb_long, x=column_for_grouping, y='Annual Energy Consumption (TBtu)', color='End Use', pattern_shape='Fuel Type',
                    barmode='stack', text_auto='.1f', template='simple_white', width=700, category_orders=cat_order, color_discrete_map=color_dict,
                    pattern_shape_map=pattern_dict)

            # formatting and saving image
            title = 'ann_energy_by_enduse_and_fuel'
            # format title and axis
            # update plot width based on number of upgrades
            upgrade_count = df_emi_gb_long[column_for_grouping].nunique()
            plot_width=550
            if upgrade_count <= 2:
                plot_width = 550
            else:
                extra_elements = upgrade_count - 2
                plot_width = 550 * (1 + 0.15 * extra_elements)

            fig.update_traces(textposition='inside', width=0.5)
            fig.update_xaxes(type='category', mirror=True, showgrid=False, showline=True, title=None, ticks='outside', linewidth=1, linecolor='black',
                            categoryorder='array', categoryarray=np.array(list(color_map.keys())))
            fig.update_yaxes(mirror=True, showgrid=False, showline=True, ticks='outside', linewidth=1, linecolor='black', rangemode="tozero")
            fig.update_layout(title=None,  margin=dict(l=20, r=20, t=27, b=20), width=plot_width, legend_title=None, legend_traceorder="reversed",
                            uniformtext_minsize=7, uniformtext_mode='hide', bargap=0.05)
            fig.update_layout(
                font=dict(
                    size=12)
                )

            # add summed values at top of bar charts
            df_emi_plot = df_emi_gb_long.groupby(column_for_grouping, observed=True)['Annual Energy Consumption (TBtu)'].sum()
            fig.add_trace(go.Scatter(
            x=df_emi_plot.index,
            y=df_emi_plot,
            text=round(df_emi_plot, 0),
            mode='text',
            textposition='top center',
            textfont=dict(
                size=12,
            ),
            showlegend=False
            ))

            # figure name and save
            fig_name = f'{title.replace(" ", "_").lower()}_{applicable_scenario}.{self.image_type}'
            fig_name_html = f'{title.replace(" ", "_").lower()}_{applicable_scenario}.html'
            fig_sub_dir = os.path.abspath(os.path.join(output_dir))
            if not os.path.exists(fig_sub_dir):
                os.makedirs(fig_sub_dir)
            fig_path = os.path.abspath(os.path.join(fig_sub_dir, fig_name))
            fig_path_html = os.path.abspath(os.path.join(fig_sub_dir, fig_name_html))
            fig.write_image(fig_path, scale=10)
            fig.write_html(fig_path_html)

    # plot for GHG emissions by fuel type for baseline and upgrade
    def plot_emissions_by_fuel_type(self, df, column_for_grouping, color_map, output_dir):

        # ghg columns; uses Cambium low renewable energy cost 15-year for electricity
        ghg_cols = self.GHG_FUEL_COLS
        wtd_ghg_cols = [self.col_name_to_weighted(c, 'co2e_mmt') for c in ghg_cols]

        # groupby and long format for plotting
        df_emi_gb = (df.groupby(column_for_grouping, observed=True)[wtd_ghg_cols].sum()).reset_index()
        df_emi_gb_long = df_emi_gb.melt(id_vars=[column_for_grouping], value_name='Annual GHG Emissions (MMT CO2e)').sort_values(by='Annual GHG Emissions (MMT CO2e)', ascending=False)
        df_emi_gb_long.loc[:, 'in.upgrade_name'] = df_emi_gb_long['in.upgrade_name'].astype(str)

        # naming for plotting
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('ghg.weighted.', '', regex=True)
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('_emissions..co2e_mmt', '', regex=True)
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('..co2e_mmt', '', regex=True)
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('_emissions_', '', regex=True)
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('electricity', 'electricity:_', regex=True)
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('_', ' ', regex=True)
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.title()
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('Lrmer', 'LRMER', regex=True)
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('Egrid', 'eGRID', regex=True)
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('Re', 'RE', regex=True)
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('Calc.Weighted.Emissions.', '', regex=True)
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('calc.weighted.emissions.', '', regex=True)
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('.', '', regex=False)
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace('Subregion', '', regex=True)
        df_emi_gb_long['variable'] = df_emi_gb_long['variable'].str.replace(' 2023 Start', '', regex=True)

        # plot
        order_map = list(color_map.keys()) # this will set baseline first in plots
        color_palette = sns.color_palette("colorblind")

        # update plot width based on number of upgrades
        upgrade_count = df_emi_gb_long[column_for_grouping].nunique()
        plot_width=8
        if upgrade_count <= 2:
            plot_width = 8
        else:
            extra_elements = upgrade_count - 2
            plot_width = 8 * (1 + 0.40 * extra_elements)

        # Create three vertical subplots with shared y-axis
        fig, axes = plt.subplots(1, 3, figsize=(plot_width, 3.4), sharey=True, gridspec_kw={'top': 1.2})
        plt.rcParams['axes.facecolor'] = 'white'
        # list of electricity grid scenarios
        electricity_scenarios = list(df_emi_gb_long[df_emi_gb_long['variable'].str.contains('electricity', case=False)]['variable'].unique())

        # loop through grid scenarios
        ax_position = 0
        for scenario in electricity_scenarios:

            # filter to grid scenario plus on-site combustion fuels
            df_scenario = df_emi_gb_long.loc[(df_emi_gb_long['variable']==scenario) | (df_emi_gb_long['variable'].isin(['Natural Gas', 'Fuel Oil', 'Propane']))]

            # Pivot the DataFrame to prepare for the stacked bars
            pivot_df = df_scenario.pivot(index='in.upgrade_name', columns='variable', values='Annual GHG Emissions (MMT CO2e)')

            # Sort the columns by the sum in descending order
            pivot_df = pivot_df[pivot_df.sum().sort_values(ascending=False).index]
            pivot_df = pivot_df.reindex(['Baseline'] + [idx for idx in pivot_df.index if idx != 'Baseline'])

            # # Set the color palette; colorblind friendly
            sns.set_palette(color_palette)

            # Create plot
            pivot_df.plot(kind='bar', stacked=True, ax=axes[ax_position], width=0.5)

            # Set the title for the specific subplot
            axes[ax_position].set_title(scenario.replace('Electricity:', ''))
            axes[ax_position].set_xticklabels(axes[ax_position].get_xticklabels())
            for ax in axes:
                for label in ax.get_xticklabels():
                    label.set_horizontalalignment('left')
                    label.set_rotation(-30)  # Rotate the labels for better visibility

            # remove x label
            axes[ax_position].set_xlabel(None)
            # Increase font size for text labels
            axes[ax_position].tick_params(axis='both', labelsize=12)
            # Add text labels to the bars for bars taller than a threshold
            threshold = 15*upgrade_count  # Adjust this threshold as needed
            for bar in axes[ax_position].containers:
                if bar.datavalues.sum() > threshold:
                    axes[ax_position].bar_label(bar, fmt='%.0f', padding=2, label_type='center')

            # Add aggregate values above the bars
            for i, v in enumerate(pivot_df.sum(axis=1)):
                # Display percentage savings only on the second bar
                if i != 0:
                    # Calculate percentage savings versus the first bar (baseline)
                    savings = (v - pivot_df.sum(axis=1).iloc[0]) / pivot_df.sum(axis=1).iloc[0] * 100
                    axes[ax_position].text(i, v + 2, f'{v:.0f} ({savings:.0f}%)', ha='center', va='bottom')
                else:
                    axes[ax_position].text(i, v + 2, f'{v:.0f}', ha='center', va='bottom')

            # increase axes position
            ax_position+=1

        # Create single plot legend
        handles, labels = axes[2].get_legend_handles_labels()
        # Modify the labels to simplify them
        labels = [label.replace('Electricity: LRMER Low RE Cost 15', 'Electricity') for label in labels]
        # Create a legend at the top of the plot, above the subplot titles
        fig.legend(handles, labels, title=None, loc='upper center', bbox_to_anchor=(0.5, 1.4), ncol=4)
        # Hide legends in the other subplots
        for ax in axes[:]:
            ax.get_legend().remove()
        # y label name
        axes[0].set_ylabel('Annual GHG Emissions (MMT CO2e)', fontsize=14)

        # Add black boxes around the plot areas
        for ax in axes:
            for spine in ax.spines.values():
                spine.set_edgecolor('black')
        # Adjust spacing between subplots and reduce white space
        plt.subplots_adjust(wspace=0.2, hspace=0.2, bottom=0.15)
        # figure name and save
        title=f"GHG_emissions_{order_map[1]}"
        fig_name = f'{title.replace(" ", "_").lower()}.{self.image_type}'
        fig_sub_dir = os.path.abspath(os.path.join(output_dir))
        if not os.path.exists(fig_sub_dir):
            os.makedirs(fig_sub_dir)
        fig_path = os.path.abspath(os.path.join(fig_sub_dir, fig_name))
        plt.savefig(fig_path, dpi=600, bbox_inches = 'tight')

    # Plot for GHG emissions by fuel for baseline and EIA data
    def plot_annual_emissions_comparison(self, df, column_for_grouping, color_map, output_dir):
        # Summarize annual emissions by fuel

        # Columns to summarize
        weighted_ghg_units='co2e_mmt'
        cols_to_summarize = {
            self.col_name_to_weighted(self.GHG_ELEC_EGRID, weighted_ghg_units): np.sum,
            self.col_name_to_weighted(self.GHG_NATURAL_GAS, weighted_ghg_units): np.sum,
            self.col_name_to_weighted(self.GHG_FUEL_OIL, weighted_ghg_units): np.sum,
            self.col_name_to_weighted(self.GHG_PROPANE, weighted_ghg_units): np.sum,
        }

        # Disaggregate to these levels
        group_bys = [
            None,
        ]

        for col, agg_method in cols_to_summarize.items(): # loops through column names and provides agg function for specific column

            for group_by in group_bys: # loops through group by options

                # Summarize the data
                if group_by is None:
                    # No group-by
                    g = sns.catplot(
                        data=df,
                        x=column_for_grouping,
                        hue=column_for_grouping,
                        y=col,
                        estimator=agg_method,
                        order=list(color_map.keys()),
                        palette=color_map.values(),
                        kind='bar',
                        errorbar=None,
                        aspect=1.5,
                        legend=False
                    )
                else:
                    # With group-by
                    g = sns.catplot(
                        data=df,
                        y=col,
                        estimator=agg_method,
                        hue=column_for_grouping,
                        x=group_by,
                        order=self.ORDERED_CATEGORIES[group_by],
                        hue_order=list(color_map.keys()),
                        palette=color_map.values(),
                        kind='bar',
                        errorbar=None,
                        aspect=2
                    )
                    g._legend.set_title(self.col_name_to_nice_name(column_for_grouping))

                fig = g.figure

                # Extract the units from the column name
                units = self.nice_units(self.units_from_col_name(col))

                # Title and axis labels
                if group_by is None:
                    # No group-by
                    title = f'{self.col_name_to_nice_name(col)}'
                    for ax in g.axes.flatten():
                        ax.set_ylabel(f'{self.col_name_to_nice_name(col)} ({units})')
                        ax.set_xlabel('')
                        ax.tick_params(axis='x', labelrotation = 90)
                else:
                    # With group-by
                    title = f'{self.col_name_to_nice_name(col)}\n by {self.col_name_to_nice_name(group_by)}'
                    for ax in g.axes.flatten():
                        ax.set_ylabel(f'{self.col_name_to_nice_name(col)} ({units})')
                        ax.set_xlabel(f'{self.col_name_to_nice_name(group_by)}')
                        ax.tick_params(axis='x', labelrotation = 90)

                # Formatting
                fig.subplots_adjust(top=0.9)

                # Save figure
                title = title.replace('\n', '')
                fig_name = f'{title.replace(" ", "_").lower()}.{self.image_type}'
                fig_path = os.path.abspath(os.path.join(output_dir, fig_name))
                plt.savefig(fig_path, bbox_inches = 'tight')
                plt.close()

    def plot_floor_area_and_energy_totals(self, df, column_for_grouping, color_map, output_dir):
        # Summarize square footage and energy totals

        # Columns to summarize
        cols_to_summarize = {
            self.col_name_to_weighted(self.FLR_AREA): np.sum,
            self.col_name_to_weighted(self.ANN_TOT_ENGY_KBTU, 'tbtu'): np.sum,
            self.col_name_to_weighted(self.ANN_TOT_ELEC_KBTU, 'tbtu'): np.sum,
            self.col_name_to_weighted(self.ANN_TOT_GAS_KBTU, 'tbtu'): np.sum,
            # 'Normalized Annual major fuel consumption (thous Btu per sqft)': np.mean,
            # 'Normalized Annual electricity consumption (thous Btu per sqft)': np.mean,
            # 'Normalized Annual natural gas consumption (thous Btu per sqft)': np.mean
        }

        # Disaggregate to these levels
        group_bys = [
            None,
            self.CEN_DIV,
            self.BLDG_TYPE,
            # self.FLR_AREA_CAT, TODO reenable after adding to both CBECS and ComStock
            self.VINTAGE,
        ]

        for col, agg_method in cols_to_summarize.items(): # loops through column names and provides agg function for specific column

            for group_by in group_bys: # loops through group by options

                # Summarize the data
                if group_by is None:

                    # No group-by
                    g = sns.catplot(
                        data=df,
                        x=column_for_grouping,
                        hue=column_for_grouping,
                        y=col,
                        estimator=agg_method,
                        order=list(color_map.keys()),
                        palette=color_map.values(),
                        kind='bar',
                        errorbar=None,
                        aspect=1.5,
                        legend=False
                    )
                else:
                    # With group-by
                    g = sns.catplot(
                        data=df,
                        y=col,
                        estimator=agg_method,
                        hue=column_for_grouping,
                        x=group_by,
                        order=self.ORDERED_CATEGORIES[group_by],
                        hue_order=list(color_map.keys()),
                        palette=color_map.values(),
                        kind='bar',
                        errorbar=None,
                        aspect=2
                    )
                    g._legend.set_title(self.col_name_to_nice_name(column_for_grouping))

                fig = g.figure

                # Extract the units from the column name
                units = self.nice_units(self.units_from_col_name(col))

                # Title and axis labels
                if group_by is None:
                    # No group-by
                    title = f'{self.col_name_to_nice_name(col)}'
                    for ax in g.axes.flatten():
                        ax.set_ylabel(f'{self.col_name_to_nice_name(col)} ({units})')
                        ax.tick_params(axis='x', labelrotation = 90)
                else:
                    # With group-by
                    title = f'{self.col_name_to_nice_name(col)}\n by {self.col_name_to_nice_name(group_by)}'
                    for ax in g.axes.flatten():
                        ax.set_ylabel(f'{self.col_name_to_nice_name(col)} ({units})')
                        ax.set_xlabel(f'{self.col_name_to_nice_name(group_by)}')
                        ax.tick_params(axis='x', labelrotation = 90)

                # Formatting
                fig.subplots_adjust(top=0.9)

                # Save figure
                title = title.replace('\n', '')
                fig_name = f'{title.replace(" ", "_").lower()}.{self.image_type}'
                fig_name = fig_name.replace('_total_energy_consumption', '')
                fig_path = os.path.abspath(os.path.join(output_dir, fig_name))
                plt.savefig(fig_path, bbox_inches = 'tight')
                plt.close()

    def plot_eui_boxplots(self, df, column_for_grouping, color_map, output_dir):
        # EUI box plot comparisons by building type and several disaggregations

        # Columns to summarize
        cols_to_summarize = [
            self.col_name_to_eui(self.ANN_TOT_ENGY_KBTU),
            self.col_name_to_eui(self.ANN_TOT_ELEC_KBTU),
            self.col_name_to_eui(self.ANN_TOT_GAS_KBTU),
        ]

        # Disaggregate to these levels
        group_bys = [
            None,
            self.BLDG_TYPE
        ]

        for col in cols_to_summarize:
            # for bldg_type, bldg_type_ts_df in df.groupby(self.BLDG_TYPE):

            # Make a plot for each group
            for group_by in group_bys:
                if group_by is None:
                    # No group-by
                    g = sns.catplot(
                        data=df,
                        y=column_for_grouping,
                        hue=column_for_grouping,
                        x=col,
                        order=list(color_map.keys()),
                        palette=color_map.values(),
                        kind='box',
                        orient='h',
                        fliersize=0,
                        showmeans=True,
                        meanprops={"marker":"d",
                            "markerfacecolor":"yellow",
                            "markeredgecolor":"black",
                            "markersize":"8"
                        },
                        legend=False
                    )
                else:
                    # With group-by
                    g = sns.catplot(
                        data=df,
                        x=col,
                        hue=column_for_grouping,
                        y=group_by,
                        order=self.ORDERED_CATEGORIES[group_by],
                        hue_order=list(color_map.keys()),
                        palette=color_map.values(),
                        kind='box',
                        orient='h',
                        fliersize=0,
                        showmeans=True,
                        meanprops={"marker":"d",
                            "markerfacecolor":"yellow",
                            "markeredgecolor":"black",
                            "markersize":"8"
                        },
                        aspect=2
                    )
                    g._legend.set_title(self.col_name_to_nice_name(column_for_grouping))

                fig = g.figure

                # Extract the units from the column name
                units = self.nice_units(self.units_from_col_name(col))

                # Titles and axis labels
                col_title = self.col_name_to_nice_name(col)
                # col_title = col.replace(f' {units}', '')
                # col_title = col_title.replace('Normalized Annual ', '')
                fuel = self.col_name_to_fuel(col_title)

                # Formatting
                if group_by is None:
                    # No group-by
                    title = f"Boxplot of {col_title}".title()
                    for ax in g.axes.flatten():
                        ax.set_xlabel(f'{fuel} EUI ({units})')
                        ax.set_ylabel('')
                else:
                    # With group-by
                    gb = self.col_name_to_nice_name(group_by)
                    title = f"Boxplot of {col_title} by {f'{gb}'}".title()
                    for ax in g.axes.flatten():
                        ax.set_xlabel(f'{fuel} EUI ({units})')
                        ax.set_ylabel(f'{gb}')

                # Save figure
                title = title.replace('\n', '')
                fig_name = f'{title.replace(" ", "_").lower()}.{self.image_type}'
                fig_name = fig_name.replace('boxplot_of_', 'bp_')
                fig_name = fig_name.replace('total_energy_consumption_', '')
                fig_path = os.path.abspath(os.path.join(output_dir, fig_name))
                plt.savefig(fig_path, bbox_inches = 'tight')
                plt.close()

    def plot_energy_rate_boxplots(self, df, column_for_grouping, color_map, output_dir):
        # energy rate box plot comparisons by building type and several disaggregations

        # Columns to summarize
        cols_to_summarize = [
            self.col_name_to_energy_rate(self.UTIL_BILL_ELEC),
            self.col_name_to_energy_rate(self.UTIL_BILL_GAS),
        ]

        # Disaggregate to these levels
        group_bys = [
            self.CEN_DIV,
            self.BLDG_TYPE
        ]

        for col in cols_to_summarize:
            # for bldg_type, bldg_type_ts_df in df.groupby(self.BLDG_TYPE):

            # Make a plot for each group
            for group_by in group_bys:
                if group_by is None:
                    # No group-by
                    g = sns.catplot(
                        data=df,
                        y=column_for_grouping,
                        hue=column_for_grouping,
                        x=col,
                        order=list(color_map.keys()),
                        palette=color_map.values(),
                        kind='box',
                        orient='h',
                        showfliers=False,
                        showmeans=True,
                        meanprops={"marker":"d",
                            "markerfacecolor":"yellow",
                            "markeredgecolor":"black",
                            "markersize":"8"
                        },
                        legend=False
                    )
                else:
                    # With group-by
                    g = sns.catplot(
                        data=df,
                        x=col,
                        hue=column_for_grouping,
                        y=group_by,
                        order=self.ORDERED_CATEGORIES[group_by],
                        hue_order=list(color_map.keys()),
                        palette=color_map.values(),
                        kind='box',
                        orient='h',
                        showfliers=False,
                        showmeans=True,
                        meanprops={"marker":"d",
                            "markerfacecolor":"yellow",
                            "markeredgecolor":"black",
                            "markersize":"8"
                        },
                        aspect=2
                    )
                    g._legend.set_title(self.col_name_to_nice_name(column_for_grouping))

                fig = g.figure

                # Extract the units from the column name
                units = self.nice_units(self.units_from_col_name(col))

                # Titles and axis labels
                col_title = self.col_name_to_nice_name(col)
                # col_title = col.replace(f' {units}', '')
                # col_title = col_title.replace('Normalized Annual ', '')
                fuel = self.col_name_to_fuel(col_title)

                # Formatting
                if group_by is None:
                    # No group-by
                    title = f"Boxplot of {col_title}".title()
                    for ax in g.axes.flatten():
                        ax.set_xlabel(f'{fuel} rate ({units})')
                        ax.set_ylabel('')
                else:
                    # With group-by
                    gb = self.col_name_to_nice_name(group_by)
                    title = f"Boxplot of {col_title} by {f'{gb}'}".title()
                    for ax in g.axes.flatten():
                        ax.set_xlabel(f'{fuel} rate ({units})')
                        ax.set_ylabel(f'{gb}')

                # Save figure
                title = title.replace('\n', '')
                fig_name = f'{title.replace(" ", "_").lower()}.{self.image_type}'
                fig_name = fig_name.replace('boxplot_of_', 'bp_')
                # fig_name = fig_name.replace('total_energy_consumption_', '')
                fig_path = os.path.abspath(os.path.join(output_dir, fig_name))
                plt.savefig(fig_path, bbox_inches = 'tight')
                plt.close()

    def plot_floor_area_and_energy_totals_by_building_type(self, df, column_for_grouping, color_map, output_dir):
        # Summarize square footage and energy totals by building type

        # Columns to summarize
        cols_to_summarize = {
            self.col_name_to_weighted(self.FLR_AREA): np.sum,
            self.col_name_to_weighted(self.ANN_TOT_ENGY_KBTU, 'tbtu'): np.sum,
            self.col_name_to_weighted(self.ANN_TOT_ELEC_KBTU, 'tbtu'): np.sum,
            self.col_name_to_weighted(self.ANN_TOT_GAS_KBTU, 'tbtu'): np.sum,
            # 'Normalized Annual major fuel consumption (thous Btu per sqft)': np.mean,
            # 'Normalized Annual electricity consumption (thous Btu per sqft)': np.mean,
            # 'Normalized Annual natural gas consumption (thous Btu per sqft)': np.mean
        }

        # Disaggregate to these levels
        group_bys = [
            None,
            self.CEN_DIV,
            # self.FLR_AREA_CAT, TODO reenable after adding to both CBECS and ComStock
            # self.VINTAGE,
        ]

        for col, agg_method in cols_to_summarize.items():
            for bldg_type, bldg_type_ts_df in df.groupby(self.BLDG_TYPE):

                # Make a plot for each group
                for group_by in group_bys:
                    if group_by is None:
                        # No group-by
                        g = sns.catplot(
                            data=bldg_type_ts_df,
                            x=column_for_grouping,
                            hue=column_for_grouping,
                            y=col,
                            estimator=agg_method,
                            order=list(color_map.keys()),
                            palette=color_map.values(),
                            errorbar=None,
                            kind='bar',
                            aspect=1.5,
                            legend=False
                        )
                    else:
                        # With group-by
                        g = sns.catplot(
                            data=bldg_type_ts_df,
                            y=col,
                            hue=column_for_grouping,
                            x=group_by,
                            estimator=agg_method,
                            order=self.ORDERED_CATEGORIES[group_by],
                            hue_order=list(color_map.keys()),
                            palette=color_map.values(),
                            kind='bar',
                            errorbar=None,
                            aspect=2
                        )
                        g._legend.set_title(self.col_name_to_nice_name(column_for_grouping))

                    fig = g.figure

                    # Extract the units from the column name
                    units = self.nice_units(self.units_from_col_name(col))

                    # Titles and axis labels
                    col_title = self.col_name_to_nice_name(col)
                    # col_title = col.replace(f' {units}', '')
                    # col_title = col_title.replace('Normalized Annual ', '')

                    # Formatting
                    if group_by is None:
                        # No group-by
                        title = f"{col_title}\n for {bldg_type.replace('_', ' ')}".title()
                        for ax in g.axes.flatten():
                            ax.set_ylabel(f'{col_title} ({units})')
                            ax.set_xlabel('')
                    else:
                        # With group-by
                        gb = self.col_name_to_nice_name(group_by)
                        title = f"{col_title}\n for {bldg_type.replace('_', ' ')} by {f'{gb}'}".title()
                        for ax in g.axes.flatten():
                            ax.set_ylabel(f'{col_title} ({units})')
                            ax.set_xlabel(f'{gb}')
                            ax.tick_params(axis='x', labelrotation = 90)

                    # Save figure
                    title = title.replace('\n', '')
                    fig_name = f'{title.replace(" ", "_").lower()}.{self.image_type}'
                    fig_name = fig_name.replace('_total_energy_consumption', '')
                    fig_sub_dir = os.path.abspath(os.path.join(output_dir, bldg_type))
                    if not os.path.exists(fig_sub_dir):
                        os.makedirs(fig_sub_dir)
                    fig_path = os.path.abspath(os.path.join(fig_sub_dir, fig_name))
                    plt.savefig(fig_path, bbox_inches = 'tight')
                    plt.close()

    def plot_end_use_totals_by_building_type(self, df, column_for_grouping, color_map, output_dir):
        # Summarize end use energy totals by building type

        # End uses to include
        end_use_cols = self.COLS_ENDUSE_ANN_ENGY
        wtd_end_use_cols = [self.col_name_to_weighted(c, 'tbtu') for c in end_use_cols]

        # Disaggregate to these levels
        group_bys = [
            # None,
            self.CEN_DIV,
            # self.FLR_AREA_CAT, TODO reenable after adding to both CBECS and ComStock
            # self.VINTAGE,
        ]

        # How the data will be combined
        agg_method = np.sum  # Could use np.mean etc. for different look at data

        # Extract the units from the name of the first column
        units = self.nice_units(self.units_from_col_name(wtd_end_use_cols[0]))

        for bldg_type, bldg_type_df in df.groupby(self.BLDG_TYPE):
            for group_by in group_bys:
                var_name = 'End Use'
                val_name = f'Energy Consumption ({units})'
                tots_long = pd.melt(
                    bldg_type_df,
                    id_vars=[
                        column_for_grouping,
                        group_by
                    ],
                    value_vars=wtd_end_use_cols,
                    var_name=var_name,
                    value_name=val_name
                )
                # logger.debug(tots_long)

                g = sns.catplot(
                    data=tots_long,
                    x=group_by,
                    y=val_name,
                    row=var_name,
                    hue=column_for_grouping,
                    estimator=agg_method,
                    order=self.ORDERED_CATEGORIES[group_by],
                    hue_order=list(color_map.keys()),
                    palette=color_map.values(),
                    sharex=False,
                    kind='bar',
                    errorbar=None,
                    aspect=3
                )
                g._legend.set_title(self.col_name_to_nice_name(column_for_grouping))

                fig = g.figure

                # Titles and axis labels

                # Formatting
                gb = self.col_name_to_nice_name(group_by)
                title = f"End Use Energy Consumption \n for {bldg_type.replace('_', ' ')} by {f'{gb}'}".title()
                for ax in g.axes.flatten():
                    # Improve the title and move to the y-axis label
                    ax_title = ax.get_title()
                    ax_title = ax_title.replace(f'{var_name} = ', '')
                    ax_units = self.units_from_col_name(ax_title)
                    ax_title = self.col_name_to_nice_name(ax_title)
                    ax_title = ax_title.replace('Energy Consumption', f'({ax_units})')
                    ax_title = ax_title.replace(' ', '\n')
                    ax.set_ylabel(ax_title, rotation=0, ha='right')
                    ax.set_title('')
                ax.set_xlabel(gb)

                g.tight_layout()

                # Save figure
                title = title.replace('\n', '')
                fig_name = f'{title.replace(" ", "_").lower()}.{self.image_type}'
                fig_sub_dir = os.path.abspath(os.path.join(output_dir, bldg_type))
                if not os.path.exists(fig_sub_dir):
                    os.makedirs(fig_sub_dir)
                fig_path = os.path.abspath(os.path.join(fig_sub_dir, fig_name))
                plt.savefig(fig_path, bbox_inches = 'tight')
                plt.close()

    def plot_eui_histograms_by_building_type(self, df, column_for_grouping, color_map, output_dir):
        # EUI histogram comparisons by building type

        # Columns to summarize
        cols_to_summarize = [
            self.col_name_to_eui(self.ANN_TOT_ENGY_KBTU),
            self.col_name_to_eui(self.ANN_TOT_ELEC_KBTU),
            self.col_name_to_eui(self.ANN_TOT_GAS_KBTU),
        ]

        # Disaggregate to these levels
        group_bys = [
            None,
            # self.CEN_DIV,
            # self.FLR_AREA_CAT, TODO reenable after adding to both CBECS and ComStock
            # self.VINTAGE,
        ]

        for col in cols_to_summarize:
            for bldg_type, bldg_type_ts_df in df.groupby(self.BLDG_TYPE):
                # Group as specified
                group_ts_dfs = {}
                for group_by in group_bys:
                    if group_by is None:
                        # No group-by
                        group_ts_dfs[None] = bldg_type_ts_df
                    else:
                        # With group-by
                        for group, group_ts_df in bldg_type_ts_df.groupby(group_by):
                            group_ts_dfs[group] = group_ts_df

                # Plot a histogram for each group
                for group, group_ts_df in group_ts_dfs.items():
                    # Create a common bin size and count to use for both datasets
                    min_eui = group_ts_df[col].min()
                    max_eui = group_ts_df[col].max()
                    # max_eui = group_ts_df[col].quantile(0.9)  # Could use 90th percentile to trim tails if desired
                    n_bins = 100
                    bin_size = (max_eui - min_eui) / n_bins
                    logger.debug(f'bldg_type: {bldg_type}, min_eui: {min_eui}, max_eui: {max_eui}, n_bins: {n_bins}, bin_size: {bin_size}')

                    # Make the histogram
                    for dataset, dataset_ts_df in group_ts_df.groupby(column_for_grouping):
                        euis = dataset_ts_df[col]
                        n_samples = len(euis)

                        # Select the color for this dataset
                        ds_color = color_map[dataset]

                        # Weight each sample by the fraction of total sqft it represents, NOT by the fraction of the building count it represents
                        wts = dataset_ts_df[self.col_name_to_weighted(self.FLR_AREA)] / dataset_ts_df[self.col_name_to_weighted(self.FLR_AREA)].sum()
                        n, bins, barcontainer = plt.hist(euis, weights=wts, range=(min_eui, max_eui), bins=n_bins, alpha=0.75, label=f'{dataset}, n={n_samples}', color=ds_color)

                        # Calculate the area-weighted mean
                        mean_eui = (euis * wts).sum()
                        plt.axvline(x=mean_eui, ymin=0, ymax=0.02,  alpha=1, ls = '', marker = 'd', mec='black', ms=10, label=f'{dataset} Mean', color=ds_color)

                    # Extract the units from the column name
                    units = self.nice_units(self.units_from_col_name(col))

                    # Titles and axis labels
                    col_title = self.col_name_to_nice_name(col)
                    col_title = col_title.replace('Normalized Annual ', '')
                    fuel = self.col_name_to_fuel(col_title)
                    if group is None:
                        # No group-by
                        title = f"Distribution of {col_title}\n for {bldg_type.replace('_', ' ')}".title()
                    else:
                        # With group-by
                        title = f"Distribution of {col_title}\n for {bldg_type.replace('_', ' ')} in {f'{group}'}".title()

                    plt.xlabel(f'{fuel} EUI ({units})\nbin size = {round(bin_size, 1)}')
                    plt.ylabel('Area-weighted fraction')
                    plt.legend()

                    # Save figure
                    title = title.replace('\n', '')
                    fig_name = f'{title.replace(" ", "_").lower()}.{self.image_type}'
                    fig_name = fig_name.replace('distribution_of_', 'dist_')
                    fig_sub_dir = os.path.abspath(os.path.join(output_dir, bldg_type))
                    if not os.path.exists(fig_sub_dir):
                        os.makedirs(fig_sub_dir)
                    fig_path = os.path.abspath(os.path.join(fig_sub_dir, fig_name))
                    plt.savefig(fig_path, bbox_inches = 'tight')
                    plt.cla()
                    plt.close()

    def plot_eui_boxplots_by_building_type(self, df, column_for_grouping, color_map, output_dir):
        # EUI box plot comparisons by building type and several disaggregations

        # Columns to summarize
        cols_to_summarize = [
            self.col_name_to_eui(self.ANN_TOT_ENGY_KBTU),
            self.col_name_to_eui(self.ANN_TOT_ELEC_KBTU),
            self.col_name_to_eui(self.ANN_TOT_GAS_KBTU),
        ]

        # Disaggregate to these levels
        group_bys = [
            None,
            self.CEN_DIV,
            # self.FLR_AREA_CAT, TODO reenable after adding to both CBECS and ComStock
            # self.VINTAGE,
        ]

        for col in cols_to_summarize:
            for bldg_type, bldg_type_ts_df in df.groupby(self.BLDG_TYPE):

                # Make a plot for each group
                for group_by in group_bys:
                    if group_by is None:
                        # No group-by
                        g = sns.catplot(
                            data=bldg_type_ts_df,
                            y=column_for_grouping,
                            hue=column_for_grouping,
                            x=col,
                            order=list(color_map.keys()),
                            palette=color_map.values(),
                            kind='box',
                            orient='h',
                            fliersize=0,
                            showmeans=True,
                            meanprops={"marker":"d",
                                "markerfacecolor":"yellow",
                                "markeredgecolor":"black",
                                "markersize":"8"
                            },
                            legend=False
                        )
                    else:
                        # With group-by
                        g = sns.catplot(
                            data=bldg_type_ts_df,
                            x=col,
                            hue=column_for_grouping,
                            y=group_by,
                            order=self.ORDERED_CATEGORIES[group_by],
                            hue_order=list(color_map.keys()),
                            palette=color_map.values(),
                            kind='box',
                            orient='h',
                            fliersize=0,
                            showmeans=True,
                            meanprops={"marker":"d",
                                "markerfacecolor":"yellow",
                                "markeredgecolor":"black",
                                "markersize":"8"
                            },
                            aspect=2
                        )
                        g._legend.set_title(self.col_name_to_nice_name(column_for_grouping))

                    fig = g.figure

                    # Extract the units from the column name
                    units = self.nice_units(self.units_from_col_name(col))

                    # Titles and axis labels
                    col_title = self.col_name_to_nice_name(col)
                    # col_title = col.replace(f' {units}', '')
                    # col_title = col_title.replace('Normalized Annual ', '')
                    fuel = self.col_name_to_fuel(col_title)

                    # Formatting
                    if group_by is None:
                        # No group-by
                        title = f"Boxplot of {col_title}\n for {bldg_type.replace('_', ' ')}".title()
                        for ax in g.axes.flatten():
                            ax.set_xlabel(f'{fuel} EUI ({units})')
                            ax.set_ylabel('')
                    else:
                        # With group-by
                        gb = self.col_name_to_nice_name(group_by)
                        title = f"Boxplot of {col_title}\n for {bldg_type.replace('_', ' ')} by {f'{gb}'}".title()
                        for ax in g.axes.flatten():
                            ax.set_xlabel(f'{fuel} EUI ({units})')
                            ax.set_ylabel(f'{gb}')

                    # Save figure
                    title = title.replace('\n', '')
                    fig_name = f'{title.replace(" ", "_").lower()}.{self.image_type}'
                    fig_name = fig_name.replace('boxplot_of_', 'bp_')
                    fig_name = fig_name.replace('total_energy_consumption_', '')
                    fig_sub_dir = os.path.abspath(os.path.join(output_dir, bldg_type))
                    if not os.path.exists(fig_sub_dir):
                        os.makedirs(fig_sub_dir)
                    fig_path = os.path.abspath((os.path.join(fig_sub_dir, fig_name)))
                    plt.savefig(fig_path, bbox_inches = 'tight')
                    plt.close()

    def plot_measure_savings_distributions_by_building_type(self, df, output_dir):

        # remove baseline; not needed
        df_upgrade = df.loc[df[self.UPGRADE_ID]!=0, :]

        # get upgrade name and id for labeling
        upgrade_num = df_upgrade[self.UPGRADE_ID].iloc[0]
        upgrade_name = df_upgrade[self.UPGRADE_NAME].iloc[0]

        # group column
        col_group = self.BLDG_TYPE

        # energy column
        en_col = self.ANN_TOT_ENGY_KBTU

        # set grouping list
        li_group = sorted(list(df_upgrade[col_group].drop_duplicates().astype(str)), reverse=True)

        # make lists of columns; these savings columns should exist in dataframe
        # enduse
        dict_saving = {}
        li_eui_svgs_btype = self.col_name_to_savings(self.col_name_to_eui(en_col))
        dict_saving['Site EUI Savings by Building Type (kBtu/ft<sup>2</sup>)'] = li_eui_svgs_btype
        li_pct_svgs_btype = self.col_name_to_percent_savings(en_col, 'percent')
        dict_saving['Percent Site Energy Savings by Building Type (%)'] = li_pct_svgs_btype

        # # loop through plot types
        for group_name, energy_col in dict_saving.items():

            # remove unit from group_name
            group_name_wo_unit = group_name.rsplit(" ", 1)[0]

            # filter to group and energy column
            df_upgrade_plt = df_upgrade.loc[:, [col_group, energy_col]]

            # apply method for filtering percent savings; this will not affect EUI
            df_upgrade_plt = self.filter_outlier_pct_savings_values(df_upgrade_plt, 1)

            # create figure template
            fig = go.Figure()

            # loop through groups, i.e. building type etc.
            for group in li_group:

                # get data for enduse; remove 0s and na values
                df_enduse = df_upgrade_plt.loc[(df_upgrade_plt[energy_col]!=0) & ((df_upgrade_plt[col_group]==group)), energy_col]

                # add traces to plot
                fig.add_trace(go.Violin(
                    x=df_enduse,
                    y=np.array(group),
                    orientation = 'h',
                    box_visible=True,
                    points='outliers',
                    pointpos=1,
                    spanmode='hard',
                    marker_size=1,
                    showlegend=False,
                    name=str(group) + f' (n={len(df_enduse)})',
                    meanline_visible=True,
                    line=dict(width=0.7),
                    fillcolor=color_violin,
                    box_fillcolor=color_interquartile,
                    line_color='black',
                    width=0.95
                ))

            fig.add_annotation(
                align="right",
                font_size=12,
                showarrow=False,
                text=f"Upgrade {str(upgrade_num).zfill(2)}: {upgrade_name} (unweighted)",
                x=1,
                xanchor="right",
                xref="x domain",
                y=1.01,
                yanchor="bottom",
                yref="y domain",
            )

            title = group_name_wo_unit
            # formatting and saving image
            fig.update_layout(template='simple_white', margin=dict(l=20, r=20, t=20, b=20), width=800)
            fig.update_xaxes(mirror=True, showgrid=True, zeroline=True, nticks=16, title=group_name)
            fig.update_yaxes(mirror=True, showgrid=True, type='category', dtick=1)
            fig_name = f'{title.replace(" ", "_").lower()}.{self.image_type}'
            fig_name = fig_name.replace('_total_energy_consumption', '')
            fig_sub_dir = os.path.abspath(os.path.join(output_dir, 'savings_distributions'))
            if not os.path.exists(fig_sub_dir):
                os.makedirs(fig_sub_dir)
            fig_path = os.path.abspath(os.path.join(fig_sub_dir, fig_name))
            fig.write_image(fig_path, scale=10)

        return

    def plot_measure_savings_distributions_by_climate_zone(self, df, output_dir):

        # remove baseline; not needed
        df_upgrade = df.loc[df[self.UPGRADE_ID]!=0, :]

        # get upgrade name and id for labeling
        upgrade_num = df_upgrade[self.UPGRADE_ID].iloc[0]
        upgrade_name = df_upgrade[self.UPGRADE_NAME].iloc[0]

        # group column
        col_group = self.CZ_ASHRAE

        # energy column
        en_col = self.ANN_TOT_ENGY_KBTU

        # set grouping list
        li_group = sorted(list(df_upgrade[col_group].unique().astype(str)), reverse=True)

        # make lists of columns; these savings columns should exist in dataframe
        # enduse
        dict_saving = {}
        li_eui_svgs_btype = self.col_name_to_savings(self.col_name_to_eui(en_col))
        dict_saving['Site EUI Savings by Climate Zone (kBtu/ft<sup>2</sup>)'] = li_eui_svgs_btype
        li_pct_svgs_btype = self.col_name_to_percent_savings(en_col, 'percent')
        dict_saving['Percent Site Energy Savings by Climate Zone (%)'] = li_pct_svgs_btype

        # # loop through plot types
        for group_name, energy_col in dict_saving.items():

            # remove unit from group_name
            group_name_wo_unit = group_name.rsplit(" ", 1)[0]

            # filter to group and energy column
            df_upgrade_plt = df_upgrade.loc[:, [col_group, energy_col]]

            # apply method for filtering percent savings; this will not affect EUI metrics
            df_upgrade_plt = self.filter_outlier_pct_savings_values(df_upgrade_plt, 1)

            # create figure template
            fig = go.Figure()

            # loop through groups, i.e. building type etc.
            for group in li_group:

                # get data for enduse; remove 0s and na values
                df_enduse = df_upgrade_plt.loc[(df_upgrade_plt[energy_col]!=0) & ((df_upgrade_plt[col_group]==group)), energy_col]

                # add traces to plot
                fig.add_trace(go.Violin(
                    x=df_enduse,
                    y=np.array(group),
                    orientation = 'h',
                    box_visible=True,
                    points='outliers',
                    pointpos=1,
                    spanmode='hard',
                    marker_size=1,
                    showlegend=False,
                    name=str(group) + f' (n={len(df_enduse)})',
                    meanline_visible=True,
                    line=dict(width=0.7),
                    fillcolor=color_violin,
                    box_fillcolor=color_interquartile,
                    line_color='black',
                    width=0.95
                ))

            fig.add_annotation(
                align="right",
                font_size=12,
                showarrow=False,
                text=f"Upgrade {str(upgrade_num).zfill(2)}: {upgrade_name} (unweighted)",
                x=1,
                xanchor="right",
                xref="x domain",
                y=1.01,
                yanchor="bottom",
                yref="y domain",
            )

            title = group_name_wo_unit
            # formatting and saving image
            fig.update_layout(template='simple_white', margin=dict(l=20, r=20, t=20, b=20), width=800)
            fig.update_xaxes(mirror=True, showgrid=True, zeroline=True, nticks=16, title=group_name)
            fig.update_yaxes(mirror=True, showgrid=True, type='category', dtick=1)
            fig_name = f'{title.replace(" ", "_").lower()}.{self.image_type}'
            fig_sub_dir = os.path.abspath(os.path.join(output_dir, 'savings_distributions'))
            if not os.path.exists(fig_sub_dir):
                os.makedirs(fig_sub_dir)
            fig_path = os.path.abspath(os.path.join(fig_sub_dir, fig_name))
            fig.write_image(fig_path, scale=10)

        return

    def plot_measure_savings_distributions_by_hvac_system_type(self, df, output_dir):

        # remove baseline; not needed
        df_upgrade = df.loc[df[self.UPGRADE_ID]!=0, :]

        # get upgrade name and id for labeling
        upgrade_num = df_upgrade[self.UPGRADE_ID].iloc[0]
        upgrade_name = df_upgrade[self.UPGRADE_NAME].iloc[0]

        # group column
        col_group = self.HVAC_SYS

        # energy column
        en_col = self.ANN_TOT_ENGY_KBTU

        # set grouping list
        li_group = sorted(list(df_upgrade[col_group].drop_duplicates().astype(str)), reverse=True)

        # make lists of columns; these savings columns should exist in dataframe
        # enduse
        dict_saving = {}
        li_eui_svgs_btype = self.col_name_to_savings(self.col_name_to_eui(en_col))
        dict_saving['Site EUI Savings by HVAC System (kBtu/ft<sup>2</sup>)'] = li_eui_svgs_btype
        li_pct_svgs_btype = self.col_name_to_percent_savings(en_col, 'percent')
        dict_saving['Percent Site Energy Savings by HVAC System (%)'] = li_pct_svgs_btype

        # # loop through plot types
        for group_name, energy_col in dict_saving.items():

            # remove unit from group_name
            group_name_wo_unit = group_name.rsplit(" ", 1)[0]

            # filter to group and energy column
            df_upgrade_plt = df_upgrade.loc[:, [col_group, energy_col]]

            # apply method for filtering percent savings; this will not affect EUI
            df_upgrade_plt = self.filter_outlier_pct_savings_values(df_upgrade_plt, 1)

            # create figure template
            fig = go.Figure()

            # loop through groups, i.e. building type etc.
            for group in li_group:

                # get data for enduse; remove 0s and na values
                df_enduse = df_upgrade_plt.loc[(df_upgrade_plt[energy_col]!=0) & ((df_upgrade_plt[col_group]==group)), energy_col]

                # add traces to plot
                fig.add_trace(go.Violin(
                    x=df_enduse,
                    y=np.array(group),
                    orientation = 'h',
                    box_visible=True,
                    points='outliers',
                    pointpos=1,
                    spanmode='hard',
                    marker_size=1,
                    showlegend=False,
                    name=str(group) + f' (n={len(df_enduse)})',
                    meanline_visible=True,
                    line=dict(width=0.7),
                    fillcolor=color_violin,
                    box_fillcolor=color_interquartile,
                    line_color='black',
                    width=0.95
                ))

            fig.add_annotation(
                align="right",
                font_size=12,
                showarrow=False,
                text=f"Upgrade {str(upgrade_num).zfill(2)}: {upgrade_name} (unweighted)",
                x=1,
                xanchor="right",
                xref="x domain",
                y=1.01,
                yanchor="bottom",
                yref="y domain",
            )

            title = group_name_wo_unit
            # formatting and saving image
            fig.update_layout(template='simple_white', margin=dict(l=20, r=20, t=20, b=20), width=800)
            fig.update_xaxes(mirror=True, showgrid=True, zeroline=True, nticks=16, title=group_name, automargin=True)
            fig.update_yaxes(mirror=True, showgrid=True, nticks=len(li_group), type='category', dtick=1, automargin=True)
            fig_name = f'{title.replace(" ", "_").lower()}.{self.image_type}'
            fig_sub_dir = os.path.abspath(os.path.join(output_dir, 'savings_distributions'))
            if not os.path.exists(fig_sub_dir):
                os.makedirs(fig_sub_dir)
            fig_path = os.path.abspath(os.path.join(fig_sub_dir, fig_name))
            fig.write_image(fig_path, scale=10)


        return

    def plot_measure_savings_distributions_enduse_and_fuel(self, df, output_dir):

        # remove baseline; not needed
        df_upgrade = df.loc[df[self.UPGRADE_ID]!=0, :]

        # get upgrade name and id for labeling;
        upgrade_num = df_upgrade[self.UPGRADE_ID].iloc[1]
        upgrade_name = df_upgrade[self.UPGRADE_NAME].iloc[1]

        # make lists of columns; these savings columns should exist in dataframe
        # enduse
        dict_saving = {}
        li_eui_svgs_enduse_cols = [self.col_name_to_savings(self.col_name_to_eui(c)) for c in self.COLS_ENDUSE_ANN_ENGY]
        dict_saving['Site EUI Savings by End Use (kBtu/ft<sup>2</sup>)'] = li_eui_svgs_enduse_cols
        li_pct_svgs_enduse_cols = [self.col_name_to_percent_savings(c, 'percent') for c in self.COLS_ENDUSE_ANN_ENGY]
        dict_saving['Percent Site Energy Savings by End Use (%)'] = li_pct_svgs_enduse_cols
        # fuel
        li_eui_svgs_fuel_cols = [self.col_name_to_savings(self.col_name_to_eui(c)) for c in self.COLS_TOT_ANN_ENGY]
        dict_saving['Site EUI Savings by Fuel (kBtu/ft<sup>2</sup>)'] = li_eui_svgs_fuel_cols
        li_pct_svgs_fuel_cols = [self.col_name_to_percent_savings(c, 'percent') for c in self.COLS_TOT_ANN_ENGY]
        dict_saving['Percent Site Energy Savings by Fuel (%)'] = li_pct_svgs_fuel_cols

        # loop through plot types
        for savings_name, col_list in dict_saving.items():

            # remove unit from savings_name
            savings_name_wo_unit = savings_name.rsplit(" ", 1)[0]

            # apply method for filtering percent savings; this will not affect EUI
            df_upgrade_plt = self.filter_outlier_pct_savings_values(df_upgrade[col_list], 1.5)

            # create figure template
            fig = go.Figure()

            # loop through enduses
            for enduse_col in col_list:

                # get data for enduse; remove 0s and na values
                df_enduse = df_upgrade_plt.loc[(df_upgrade_plt[enduse_col]!=0), enduse_col]

                # column name
                col_name = self.col_name_to_nice_saving_name(df_enduse.name)

                # add traces to plot
                fig.add_trace(go.Violin(
                    x=df_enduse,
                    y=np.array(col_name),
                    orientation = 'h',
                    box_visible=True,
                    points='outliers',
                    pointpos=1,
                    spanmode='hard',
                    marker_size=1,
                    showlegend=False,
                    name=str(col_name) + f'(n={len(df_enduse)})',
                    meanline_visible=True,
                    line=dict(width=0.7),
                    fillcolor=color_violin,
                    box_fillcolor=color_interquartile,
                    line_color='black',
                    width=0.95
                ))

            fig.add_annotation(
                align="right",
                font_size=12,
                showarrow=False,
                text=f"Upgrade {str(upgrade_num).zfill(2)}: {upgrade_name} (unweighted)",
                x=1,
                xanchor="right",
                xref="x domain",
                y=1.01,
                yanchor="bottom",
                yref="y domain",
            )

            title = savings_name_wo_unit
            # formatting and saving image
            fig.update_layout(template='simple_white', margin=dict(l=20, r=20, t=20, b=20), width=800)
            fig.update_xaxes(mirror=True, showgrid=True, zeroline=True, nticks=16, title=savings_name)
            fig.update_yaxes(mirror=True, showgrid=True, nticks=len(li_pct_svgs_enduse_cols), type='category', dtick=1)
            fig_name = f'{title.replace(" ", "_").lower()}.{self.image_type}'
            fig_sub_dir = os.path.abspath(os.path.join(output_dir, 'savings_distributions'))
            if not os.path.exists(fig_sub_dir):
                os.makedirs(fig_sub_dir)
            fig_path = os.path.abspath(os.path.join(fig_sub_dir, fig_name))
            fig.write_image(fig_path, scale=10)

    def plot_qoi_timing(self, df, column_for_grouping, color_map, output_dir):

        qoi_timing = self.QOI_MAX_DAILY_TIMING_COLS

        short_names = []
        for col_name in qoi_timing:
            col_name = self.shorten_qoi_names(col_name)
            short_names.append(col_name)

        violin_qoi_timing = px.violin(
            data_frame = df,
            x = qoi_timing,
            orientation = 'h',
            box = True,
            points = 'outliers',
            color = column_for_grouping,
            color_discrete_sequence = list(color_map.values()),
            violinmode = "group",
            template='simple_white'
        )

        # formatting and saving image
        title="maximum_daily_peak_timing_hr"
        violin_qoi_timing.update_yaxes(mirror=True, title="Season", tickmode = "array", ticktext =short_names, tickvals=qoi_timing)
        violin_qoi_timing.update_xaxes(mirror=True, title="Maximum Daily Peak Timing by Season (Hour of Day)")
        violin_qoi_timing.update_layout(
            legend_title = self.col_name_to_nice_name(column_for_grouping),
            margin=dict(l=5, r=5, t=5, b=5),
            )
        fig_name = f'{title}.{self.image_type}'
        fig_sub_dir = os.path.abspath(os.path.join(output_dir, 'qoi_distributions'))
        if not os.path.exists(fig_sub_dir):
            os.makedirs(fig_sub_dir)
        fig_path = os.path.abspath(os.path.join(fig_sub_dir, fig_name))
        violin_qoi_timing.write_image(fig_path, scale=10)

    def plot_qoi_max_use(self, df, column_for_grouping, color_map, output_dir):

        max_use_cols_normalized = self.QOI_MAX_USE_COLS_NORMALIZED

        short_names = []
        for col_name in max_use_cols_normalized:
            col_name = self.shorten_qoi_names(col_name)
            short_names.append(col_name)

        violin_qoi_timing = px.violin(
            data_frame = df,
            x = max_use_cols_normalized,
            orientation = 'h',
            box = True,
            points = 'outliers',
            color = column_for_grouping,
            color_discrete_sequence = list(color_map.values()),
            violinmode = "group",
            template='simple_white'
        )

        # formatting and saving image
        title="maximum_daily_peak_magnitude_w_ft2"
        violin_qoi_timing.update_yaxes(mirror=True, title="Season",  tickmode = "array", ticktext =short_names, tickvals=max_use_cols_normalized)
        violin_qoi_timing.update_xaxes(mirror=True, title="Maximum Daily Peak Magnitude by Season (W/ft<sup>2</sup>)")
        violin_qoi_timing.update_layout(
            legend_title = self.col_name_to_nice_name(column_for_grouping),
            margin=dict(l=5, r=5, t=5, b=5),
            )
        fig_name = f'{title}.{self.image_type}'
        fig_sub_dir = os.path.abspath(os.path.join(output_dir, 'qoi_distributions'))
        if not os.path.exists(fig_sub_dir):
            os.makedirs(fig_sub_dir)
        fig_path = os.path.abspath(os.path.join(fig_sub_dir, fig_name))
        violin_qoi_timing.write_image(fig_path, scale=10)

    def plot_qoi_min_use(self, df, column_for_grouping, color_map, output_dir):

        min_use_cols_normalized = self.QOI_MIN_USE_COLS_NORMALIZED

        short_names = []
        for col_name in min_use_cols_normalized:
            col_name = self.shorten_qoi_names(col_name)
            short_names.append(col_name)

        violin_qoi_timing = px.violin(
            data_frame = df,
            x = min_use_cols_normalized,
            orientation = 'h',
            box = True,
            points = 'outliers',
            color = column_for_grouping,
            color_discrete_sequence = list(color_map.values()),
            violinmode = "group",
            template='simple_white'
        )

        # formatting and saving image
        title="minimum_daily_peak_magnitude_w_ft2"
        violin_qoi_timing.update_yaxes(mirror=True, title="Season", tickmode="array", ticktext=short_names, tickvals=min_use_cols_normalized)
        violin_qoi_timing.update_xaxes(mirror=True, title="Minimum Daily Peak Magnitude by Season (W/ft<sup>2</sup>)")
        violin_qoi_timing.update_layout(
            legend_title = self.col_name_to_nice_name(column_for_grouping),
            margin=dict(l=5, r=5, t=5, b=5),
            )
        fig_name = f'{title}.{self.image_type}'
        fig_sub_dir = os.path.abspath(os.path.join(output_dir, 'qoi_distributions'))
        if not os.path.exists(fig_sub_dir):
            os.makedirs(fig_sub_dir)
        fig_path = os.path.abspath(os.path.join(fig_sub_dir, fig_name))
        violin_qoi_timing.write_image(fig_path, scale=10)

    def filter_outlier_pct_savings_values(self, df, max_fraction_change):

        # get applicable columns
        cols = df.loc[:, df.columns.str.contains('percent_savings')].columns

        # make copy of dataframe
        df_2 = df.copy()

        # filter out data that falls outside of user-input range by changing them to nan
        # when plotting, nan values will be skipped
        df_2.loc[:, cols] = df_2[cols].mask(df[cols]>max_fraction_change, np.nan)
        df_2.loc[:, cols] = df_2[cols].mask(df[cols]<-max_fraction_change, np.nan)

        # multiply by 100 to get percent savings
        df_2.loc[:, cols] = df_2[cols] * 100

        return df_2

    def plot_annual_energy_consumption_for_eia(self, df, color_map, output_dir):
         # Summarize annual energy consumption for EIA plots

       # Columns to summarize
        cols_to_summarize = {
            'Electricity consumption (kWh)': 'sum',
            'Natural gas consumption (thous Btu)': 'sum'
        }

        # Disaggregate to these levels
        group_bys = [
            None,
            self.STATE_ABBRV,
            'Division'
        ]

        for col, agg_method in cols_to_summarize.items():
            for group_by in group_bys:
                # Summarize the data
                vals = [col]  # Values in Excel pivot table
                ags = [agg_method]  # How each of the values will be aggregated, like Value Field Settings in Excel, but applied to all values
                cols = [self.DATASET] # Columns in Excel pivot table

                first_ax = None

                if group_by is None:
                    # No group-by
                    pivot = df.pivot_table(values=vals, columns=cols, aggfunc=ags)
                    pivot = pivot.droplevel([0], axis=1)
                else:
                    # With group-by
                    idx = [group_by]  # Rows in Excel pivot table
                    pivot = df.pivot_table(values=vals, columns=cols, index=idx, aggfunc=ags)
                    pivot = pivot.droplevel([0, 1], axis=1)

                # Make the graph
                if first_ax is None:
                    ax = pivot.plot.bar(color=color_map)
                    first_ax = ax
                else:
                    ax = pivot.plot.bar(color=color_map, ax=first_ax)

                # Extract the units from the column name
                match = re.search('\\(.*\\)', col)
                if match:
                    units = match.group(0)
                else:
                    units = 'TODO units'

                # Formatting
                if group_by is None:
                    # No group-by]
                    title = f"{agg_method} {col.replace(f' {units}', '')}".title()
                    ax.tick_params(axis='x', labelrotation = 0)
                    for container in ax.containers:
                        ax.bar_label(container, fmt='%.2e')
                else:
                    # With group-by
                    title = f"{agg_method} {col.replace(f' {units}', '')}\n by {group_by}".title()

                # Remove 'Sum' from title
                title = title.replace('Sum', '').strip()

                # Set title and units
                ax.set_title(title)
                ax.set_ylabel(f'Annual Energy Consumption {units}')

                # Add legend with no duplicate entries
                handles, labels = first_ax.get_legend_handles_labels()
                new_labels = []
                new_handles = []
                for l, h in zip(labels, handles):
                    if not l in new_labels:
                        new_labels.append(l)  # Add the first instance of the label
                        new_handles.append(h)
                ax.legend(new_handles, new_labels, bbox_to_anchor=(1.01,1), loc="upper left")

                # Save the figure
                title = title.replace('\n', '')
                fig_name = f'com_eia_{title.replace(" ", "_").lower()}.{self.image_type}'
                fig_path = os.path.abspath(os.path.join(output_dir, fig_name))
                plt.savefig(fig_path, bbox_inches = 'tight')
                plt.close()

    def plot_monthly_energy_consumption_for_eia(self, df, color_map, output_dir):
        # Columns to summarize
        cols_to_summarize = {
            'Electricity consumption (kWh)': 'sum',
            'Natural gas consumption (thous Btu)': 'sum'
        }

        # Disaggregate to these levels
        group_bys = [
            self.STATE_ABBRV,
            'Division'
        ]

        for col, agg_method in cols_to_summarize.items():
            for group_by in group_bys:
                # Summarize the data
                vals = [col]  # Values in Excel pivot table
                ags = [agg_method]  # How each of the values will be aggregated, like Value Field Settings in Excel, but applied to all values
                cols = [self.DATASET] # Columns in Excel pivot table


                for group_name, group_data in df.groupby(group_by):

                    # With group-by
                    pivot = group_data.pivot_table(values=vals, columns=cols, index='Month', aggfunc=ags)
                    pivot = pivot.droplevel([0, 1], axis=1)

                    # Make the graph
                    ax = pivot.plot.bar(color=color_map)

                    # Extract the units from the column name
                    match = re.search('\\(.*\\)', col)
                    if match:
                        units = match.group(0)
                    else:
                        units = 'TODO units'

                    # Set title and units
                    title = f"{agg_method} Monthly {col.replace(f' {units}', '')}\n by {group_by} for {group_name}".title()

                    # Remove 'Sum' from title
                    title = title.replace('Sum', '').strip()

                    ax.set_title(title)
                    ax.set_ylabel(f'Monthly Energy Consumption {units}')

                    # Add legend with no duplicate entries
                    handles, labels = ax.get_legend_handles_labels()
                    new_labels = []
                    new_handles = []
                    for l, h in zip(labels, handles):
                        if not l in new_labels:
                            new_labels.append(l)  # Add the first instance of the label
                            new_handles.append(h)
                    ax.legend(new_handles, new_labels, bbox_to_anchor=(1.01,1), loc="upper left")

                    # Save the figure
                    title = title.replace('\n', '')
                    fig_name = f'com_eia_{title.replace(" ", "_").lower()}.{self.image_type}'
                    fig_path = os.path.abspath(os.path.join(output_dir, fig_name))
                    plt.savefig(fig_path, bbox_inches = 'tight')
                    plt.close()


    # color functions from https://bsouthga.dev/posts/color-gradients-with-python
    def linear_gradient(self, start_hex, finish_hex="#FFFFFF", n=10):
        ''' returns a gradient list of (n) colors between
            two hex colors. start_hex and finish_hex
            should be the full six-digit color string,
            inlcuding the number sign ("#FFFFFF") '''
        # Starting and ending colors in RGB for
        s = self.hex_to_RGB(start_hex)
        f = self.hex_to_RGB(finish_hex)
        # Initilize a list of the output colors with the starting color
        RGB_list = [s]
        # Calcuate a color at each evenly spaced value of t from 1 to n
        for t in range(1, n):
            # Interpolate RGB vector for color at the current value of t
            curr_vector = [
            int(s[j] + (float(t)/(n-1))*(f[j]-s[j]))
            for j in range(3)
            ]
            # Add it to our list of output colors
            RGB_list.append(curr_vector)

        return self.color_dict(RGB_list)

    def color_dict(self, gradient):
        ''' Takes in a list of RGB sub-lists and returns dictionary of
            colors in RGB and hex form for use in a graphing function
            defined later on '''
        return {"hex":[self.RGB_to_hex(RGB) for RGB in gradient],
            "r":[RGB[0] for RGB in gradient],
            "g":[RGB[1] for RGB in gradient],
            "b":[RGB[2] for RGB in gradient]}

    def hex_to_RGB(self, hex):
        ''' "#FFFFFF" -> [255,255,255] '''
        # Pass 16 to the integer function for change of base
        return [int(hex[i:i+2], 16) for i in range(1,6,2)]

    def RGB_to_hex(self, RGB):
        ''' [255,255,255] -> "#FFFFFF" '''
        # Components need to be integers for hex to make sense
        RGB = [int(x) for x in RGB]
        return "#"+"".join(["0{0:x}".format(v) if v < 16 else
                    "{0:x}".format(v) for v in RGB])


    """
    Seasonal load stacked area plots by daytype (weekday and weekdend) comparison
    Args:
        df: long form dataset with a comstock run and ami data
        region: region object from AMI class
        building_type (str): building type
        color_map: hash with dataset names as the keys
        output_dir (str): output directory
        normalization (str): how to normalize the data. Default is 'None' which directly compares kwh_per_sf. Other options are 'Annual' and 'Daytype'. 'Annual' will normalize the data as a fraction compared to the total annual energy use. 'Daytype' will normalize to the energy use for the given day type.
        save_graph_data (bool): set to true to save graph data
    """
    def plot_day_type_comparison_stacked_by_enduse(self, df, region, building_type, color_map, output_dir, normalization='None', save_graph_data=False):
        summer_months = region['summer_months']
        winter_months = region['winter_months']
        shoulder_months = region['shoulder_months']

        enduse_list = [
            'exterior_lighting',
            'interior_lighting',
            'interior_equipment',
            'exterior_equipment',
            'water_systems',
            'heat_recovery',
            'fans',
            'pumps',
            'heat_rejection',
            'humidification',
            'cooling',
            'heating',
            'refrigeration'
        ]

        enduse_colors = [
            '#DEC310',  # exterior lighting
            '#F7DF10',  # interior lighting
            '#4A4D4A',  # interior equipment
            '#B5B2B5',  # exterior equipment
            '#FFB239',  # water systems
            '#CE5921',  # heat recovery
            '#FF79AD',  # fans
            '#632C94',  # pumps
            '#F75921',  # heat rejection
            '#293094',  # humidification
            '#0071BD',  # cooling
            '#EF1C21',  # heating
            '#29AAE7'   # refrigeration
        ]

        comstock_data_label = list(color_map.keys())[0]
        ami_data_label = list(color_map.keys())[1]
        energy_column = 'kwh_per_sf'
        default_uncertainty = 0.1

        # filter and collect comstock data
        comstock_data = df.loc[df.run.isin([comstock_data_label])]
        comstock_count = comstock_data['bldg_count']
        comstock_count_max = int(comstock_count.max())
        comstock_count_avg = comstock_count.mean()
        comstock_count_min = int(comstock_count.min())
        comstock_data = comstock_data[['enduse', energy_column]]
        comstock_data = comstock_data.reset_index().groupby(['enduse', 'timestamp']).sum().reset_index().set_index('timestamp')
        comstock_data = comstock_data.pivot(columns='enduse', values=[energy_column])
        comstock_data.columns = comstock_data.columns.droplevel(0)
        comstock_data = comstock_data.reset_index().rename_axis(None, axis=1)
        comstock_data = comstock_data.set_index('timestamp')
        comstock_data = comstock_data.head(8760)
        if normalization == 'Annual':
          comstock_annual_total = comstock_data['total'].sum()
          comstock_data = comstock_data / comstock_annual_total

        # Remove missing enduses from enduse list and enduse colors before plotting
        filtered_enduse_list = [col for col in enduse_list if col in comstock_data.columns]
        filtered_enduse_colors = [enduse_colors[i] for i, col in enumerate(enduse_list) if col in comstock_data.columns]

        # filter and collect ami data
        ami_data = df.loc[df.run.isin([ami_data_label])]
        ami_count = ami_data['bldg_count']
        ami_count_max = int(ami_count.max())
        ami_count_avg = ami_count.mean()
        ami_count_min = int(ami_count.min())
        ami_data = ami_data[['run', energy_column]]
        ami_data = ami_data.pivot(columns='run', values=[energy_column])
        ami_data.columns = ami_data.columns.droplevel(0)
        ami_data = ami_data.reset_index().rename_axis(None, axis=1)
        ami_data = ami_data.set_index('timestamp')
        ami_data = ami_data.head(8760)
        if normalization == 'Annual':
          ami_annual_total = ami_data.sum()
          ami_data = ami_data / ami_annual_total

        # Assign sample uncertainty
        total_data = df.loc[df.enduse.isin(['total'])]
        try:
            sample_uncertainty = total_data.loc[total_data.run.isin([ami_data_label])][['sample_uncertainty']]
        except KeyError:
            sample_uncertainty = total_data.loc[total_data.run.isin([ami_data_label])][['run', energy_column]]
            sample_uncertainty.rename(columns={energy_column: 'sample_uncertainty'}, inplace=True)
            sample_uncertainty['sample_uncertainty'] = default_uncertainty

        # comstock day type dictionary
        comstock_day_type_dict = {}
        if summer_months:
            comstock_day_type_dict.update({'Summer_Weekday': (comstock_data.index.weekday < 5)
                                    & (comstock_data.index.month.isin(summer_months))})
            comstock_day_type_dict.update({'Summer_Weekend': (comstock_data.index.weekday >= 5)
                                    & (comstock_data.index.month.isin(summer_months))})
        if winter_months:
            comstock_day_type_dict.update({'Winter_Weekday': (comstock_data.index.weekday < 5)
                                    & (comstock_data.index.month.isin(winter_months))})
            comstock_day_type_dict.update({'Winter_Weekend': (comstock_data.index.weekday >= 5)
                                    & (comstock_data.index.month.isin(winter_months))})
        if shoulder_months:
            comstock_day_type_dict.update({'Shoulder_Weekday': (comstock_data.index.weekday < 5)
                                    & (comstock_data.index.month.isin(shoulder_months))})
            comstock_day_type_dict.update({'Shoulder_Weekend': (comstock_data.index.weekday >= 5)
                                    & (comstock_data.index.month.isin(shoulder_months))})

        # ami day type dictionary
        ami_day_type_dict = {}
        if summer_months:
            ami_day_type_dict.update({'Summer_Weekday': (ami_data.index.weekday < 5)
                                    & (ami_data.index.month.isin(summer_months))})
            ami_day_type_dict.update({'Summer_Weekend': (ami_data.index.weekday >= 5)
                                    & (ami_data.index.month.isin(summer_months))})
        if winter_months:
            ami_day_type_dict.update({'Winter_Weekday': (ami_data.index.weekday < 5)
                                    & (ami_data.index.month.isin(winter_months))})
            ami_day_type_dict.update({'Winter_Weekend': (ami_data.index.weekday >= 5)
                                    & (ami_data.index.month.isin(winter_months))})
        if shoulder_months:
            ami_day_type_dict.update({'Shoulder_Weekday': (ami_data.index.weekday < 5)
                                    & (ami_data.index.month.isin(shoulder_months))})
            ami_day_type_dict.update({'Shoulder_Weekend': (ami_data.index.weekday >= 5)
                                    & (ami_data.index.month.isin(shoulder_months))})

        # plot
        plt.figure(figsize=(20, 20))
        filename = (region['source_name'] + '_' + ami_data_label.lower().replace(' ', '') + '_' + building_type)
        graph_type = ''
        if normalization == 'Annual':
            day_type_label = 'Annual Normalized'
            graph_type = "annual_normalized_day_type_comparison_by_enduse"
        elif normalization == 'Daytype':
            day_type_label = 'Day Type Normalized'
            graph_type = "daytype_normalized_day_type_comparison_by_enduse"
        else:
            day_type_label = ''
            graph_type = "day_type_comparison_by_enduse"
        plt.suptitle('{} Day Type Comparison by Enduse\n{} (n={}) vs. {} (n={})\n{}, {}'.format(day_type_label, comstock_data_label, comstock_count_max, ami_data_label, ami_count_max, region['source_name'], building_type), fontsize=24)
        filename = filename + "_" + graph_type
        plt.subplots_adjust(top=0.9)
        fig_n = 0

        ylabel_text = 'Electric Load (kwh/ft2)'
        if normalization == 'Annual':
            ylabel_text = 'Normalized (Annual Sum = 1)'
        elif normalization == 'Daytype':
            ylabel_text = 'Normalized (Day Sum = 1)'

        # calculate y_max in the plot
        y_max_buildstock = 0
        for day_type in comstock_day_type_dict.keys():
            y_max_temp = pd.DataFrame(comstock_data['total'][comstock_day_type_dict[day_type]])
            y_max_temp['hour'] = y_max_temp.index.hour
            y_max_temp = y_max_temp.groupby('hour').mean()
            if normalization == 'Daytype':
                y_max_temp_value = float(y_max_temp['total'].max()/y_max_temp['total'].sum())
            else:
                y_max_temp_value = float(y_max_temp['total'].max())
            if y_max_temp_value > y_max_buildstock:
                y_max_buildstock = y_max_temp_value

        y_max_ami = 0
        for day_type in ami_day_type_dict.keys():
            y_max_temp = pd.DataFrame(ami_data[ami_day_type_dict[day_type]])
            y_max_temp['hour'] = y_max_temp.index.hour
            y_max_temp_value = float(y_max_temp.groupby('hour').mean().max().iloc[0])
            if y_max_temp_value > y_max_ami:
                y_max_ami = y_max_temp_value
        y_max = max(y_max_buildstock, y_max_ami)

        plot_data_df = pd.DataFrame()
        for day_type in ami_day_type_dict.keys():
            fig_n = fig_n + 1
            ax = plt.subplot(3, 2, fig_n)
            ax.spines['top'].set_color('black')
            ax.spines['bottom'].set_color('black')
            ax.spines['right'].set_color('black')
            ax.spines['left'].set_color('black')
            plt.rcParams.update({'font.size': 16})

            # Truth data
            truth_data = pd.DataFrame(ami_data[ami_data_label][ami_day_type_dict[day_type]])
            truth_data['hour'] = truth_data.index.hour
            truth_data = truth_data.groupby('hour').mean()
            if normalization == 'Daytype':
                truth_data_total = truth_data.sum()
                truth_data = truth_data / truth_data_total

            # Stacked Enduses Plot
            processed_data_for_stack_plot = pd.DataFrame(comstock_data[filtered_enduse_list][comstock_day_type_dict[day_type]])
            processed_data_for_stack_plot['hour'] = processed_data_for_stack_plot.index.hour
            processed_data_for_stack_plot = processed_data_for_stack_plot.groupby('hour').mean()
            if normalization == 'Daytype':
                processed_data_total = processed_data_for_stack_plot.sum().sum()
                processed_data_for_stack_plot = processed_data_for_stack_plot / processed_data_total

            plt.stackplot(
                processed_data_for_stack_plot.index,
                processed_data_for_stack_plot.T,
                labels=filtered_enduse_list,
                colors=filtered_enduse_colors
            )

            # Truth Data Plot
            y = truth_data
            s_uncertainty = pd.DataFrame(sample_uncertainty[ami_day_type_dict[day_type]])
            s_uncertainty['hour'] = s_uncertainty.index.hour
            s_uncertainty = s_uncertainty.groupby('hour').mean()

            # Upper Estimate
            upper_truth = pd.DataFrame(
                y[ami_data_label].values +
                y[ami_data_label].values * s_uncertainty['sample_uncertainty'].values
            )
            plt.plot(
                upper_truth,
                color='k',
                label='{}: 80% CI upper estimate'.format(ami_data_label),
                linestyle='--'
            )
            y_max = np.max([float(np.max(upper_truth)), y_max])

            # Mean Estimate
            plt.plot(
                y,
                color='k',
                label=ami_data_label
            )

            # Lower estimate
            lower_truth = pd.DataFrame(
                y[ami_data_label].values -
                y[ami_data_label].values * s_uncertainty['sample_uncertainty'].values
            )
            # values cannot be negative
            lower_truth = lower_truth.clip(lower=0)
            plt.plot(
                lower_truth,
                color='k',
                label='{}: 80% CI lower estimate'.format(ami_data_label),
                linestyle='dashed'
            )

            plt.title(day_type.replace("_", " "))
            plt.xlim([0, 23])
            plt.ylim([0, y_max * 1.1])

            if fig_n > 4:
                plt.xlabel('Hour of Day', fontsize=24)
            if fig_n % 2 != 0:
                plt.ylabel(ylabel_text, fontsize=24)

            # collect graph data
            data_df = processed_data_for_stack_plot.copy()
            data_df['hour'] = data_df.index
            data_df['region'] = region['source_name']
            data_df['building_type'] = building_type
            data_df['day_type'] = day_type
            #data_df['lci80'] = lower_truth
            data_df['ami_total'] = truth_data
            #data_df['uci80'] = upper_truth
            data_df['graph_type'] = graph_type
            data_df['ami_n_min'] = ami_count_min
            data_df['ami_n_mean'] = ami_count_avg
            data_df['ami_n_max'] = ami_count_max
            data_df['comstock_n_min'] = comstock_count_min
            data_df['comstock_n_mean'] = comstock_count_avg
            data_df['comstock_n_max'] = comstock_count_max

            # add comstock total
            processed_total_data = pd.DataFrame(comstock_data['total'][comstock_day_type_dict[day_type]])
            processed_total_data['hour'] = processed_total_data.index.hour
            processed_total_data = processed_total_data.groupby('hour').mean()
            data_df['comstock_total'] = processed_total_data
            data_df['error'] = data_df['ami_total'] - data_df['comstock_total']
            data_df['relative_error'] = (data_df['ami_total'] - data_df['comstock_total']) / data_df['ami_total']

            # add to total plot data
            data_df = data_df.reset_index(drop=True)
            plot_data_df = pd.concat([plot_data_df, data_df])

        ax = plt.gca()
        handles, labels = ax.get_legend_handles_labels()
        plt.figlegend(handles[::-1], labels[::-1], loc='center right', bbox_to_anchor=(1.2, 0.52), ncol=1)

        # save plot
        output_path = os.path.abspath(os.path.join(output_dir, '%s.png' % (filename) ))
        plt.savefig(output_path, bbox_inches='tight')

        # save graph data
        if save_graph_data:
            output_path = os.path.abspath(os.path.join(output_dir, '%s.csv' % (filename) ))
            plot_data_df.to_csv(output_path, index=False)

        plt.close('all')
        return plot_data_df

    """
    Load duration curve comparison
    Args:
        df: long form dataset with a comstock run and ami data
        region: region object from AMI class
        building_type (str): building type
        color_map: hash with dataset names as the keys
        output_dir (str): output directory
    """
    def plot_load_duration_curve(self, df, region, building_type, color_map, output_dir):
        comstock_data_label = list(color_map.keys())[0]
        ami_data_label = list(color_map.keys())[1]
        energy_column = 'kwh_per_sf'
        default_uncertainty = 0.1
        zoom_in_hours = -1

        total_data = df.loc[df.enduse.isin(['total'])]

        # format comstock data
        comstock_data = total_data.loc[total_data.run.isin([comstock_data_label])][['run', energy_column]]
        comstock_data = comstock_data.pivot(columns='run', values=[energy_column])
        comstock_data.columns = comstock_data.columns.droplevel(0)
        comstock_data = comstock_data.reset_index().rename_axis(None, axis=1)
        comstock_data = comstock_data.set_index('timestamp')

        # format ami data
        ami_data = total_data.loc[total_data.run.isin([ami_data_label])][['run', energy_column]]
        ami_data = ami_data.pivot(columns='run', values=[energy_column])
        ami_data.columns = ami_data.columns.droplevel(0)
        ami_data = ami_data.reset_index().rename_axis(None, axis=1)
        ami_data = ami_data.set_index('timestamp')

        # assign sample uncertainty
        try:
            sample_uncertainty = np.array(total_data.loc[total_data.run.isin([ami_data_label])][['sample_uncertainty']])
        except KeyError:
            sample_uncertainty = total_data.loc[total_data.run.isin([ami_data_label])][['run', energy_column]]
            sample_uncertainty.rename(columns={energy_column: 'sample_uncertainty'}, inplace=True)
            sample_uncertainty['sample_uncertainty'] = default_uncertainty
            sample_uncertainty = np.array(sample_uncertainty['sample_uncertainty']).reshape(-1, 1)

        # set up default values
        if zoom_in_hours == -1:
            zoom_in_hours = len(ami_data)

        # sort values
        ami_data_sorted = ami_data.sort_values(
            by=list(ami_data.columns), ascending=False).reset_index(drop=True).iloc[0:zoom_in_hours, :]
        ami_data_sorted = ami_data_sorted.reset_index(drop=True)
        comstock_data_sorted = pd.DataFrame(
            np.sort(comstock_data.values,
                    axis=0)[::-1],
            index=comstock_data.index,
            columns=comstock_data.columns
        ).iloc[0:zoom_in_hours, :]
        comstock_data_sorted = comstock_data_sorted.reset_index(drop=True)
        sample_uncertainty = sample_uncertainty[0:zoom_in_hours].max()

        # plot
        plt.figure(figsize=(12, 8))
        plt.ylabel('kwh/ft2', fontsize=16)
        plt.plot(comstock_data_sorted, color='#d73027', linewidth=2)
        y = ami_data_sorted
        plt.plot(y + y * sample_uncertainty, color='k', linestyle='dashed')
        plt.plot(y, color='k')
        plt.plot(y - y * sample_uncertainty, color='k', linestyle='dashed')
        plt.xlabel('Hours Equaled or Exceeded', fontsize=16)

        y_max = max([ami_data_sorted.values.max(), comstock_data_sorted.values.max()])
        y_min = 0
        if zoom_in_hours < 501:
            y_min = 0.9 * min([ami_data_sorted.values.min(), comstock_data_sorted.values.min()])
        plt.xlim(0, len(ami_data_sorted))
        plt.ylim([y_min, 1.1 * y_max])
        plt.yticks(fontsize=15)
        plt.xticks(fontsize=15)
        plt.legend([comstock_data_label] + [ami_data_label + ': upper estimate'] +
                    [ami_data_label] + [ami_data_label + ': lower estimate'], fontsize=15, loc=1)
        plt.title('{}, {}, Load Duration Curve: {} hours'.format(region['source_name'], building_type, len(ami_data_sorted)), fontsize=19)

        # output figure
        filename = region['source_name'] + '_' + ami_data_label.lower().replace(' ', '') + '_' + building_type + '_load_duration_curve_top_' + str(zoom_in_hours) + '_hours.png'
        output_path = os.path.abspath(os.path.join(output_dir, filename))
        plt.savefig(output_path, bbox_inches='tight')
