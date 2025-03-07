# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.
import os

import logging
import numpy as np
import pandas as pd
import polars as pl
from typing import List

from comstockpostproc.naming_mixin import NamingMixin
from comstockpostproc.units_mixin import UnitsMixin
from comstockpostproc.plotting_mixin import PlottingMixin
from comstockpostproc.cbecs import CBECS
from comstockpostproc.comstock import ComStock


logger = logging.getLogger(__name__)

class ComStockToCBECSComparison(NamingMixin, UnitsMixin, PlottingMixin):
    def __init__(self, comstock_list: List[ComStock], cbecs_list: List[CBECS], upgrade_id=0, image_type='jpg', name=None, make_comparison_plots=True):
        """
        Creates the ComStock to CBECS comaprison plots.
        
        Args:
            comstock_list (List[ComStock]): List of ComStock dataset objects.
            cbecs_list (List[CBECS]): List of CBECS dataset objects.
            upgrade_id (Union(str, int), optional): The upgrade ID to include in the plots, or 'All' to include all upgrades for the ComStock run(s).
            image_type (str, optional): Image file type to use. Defaults to 'jpg'.
            name (str, optional): Name of output directory. If None, a name will be generated. Defaults to None.
            make_comparison_plots (bool, optional): Flag to create compairison plots. Defaults to True.
        """
        # Initialize members
        self.comstock_list = comstock_list
        self.cbecs_list = cbecs_list
        self.data = None
        self.color_map = {}
        self.image_type = image_type
        self.name = name
        self.column_for_grouping = self.DATASET

        # Concatenate the datasets and create a color map
        dfs_to_concat = []
        comstock_dfs_to_concat = []
        dataset_names = []
        comstock_color_map = {}
        for dataset in (cbecs_list + comstock_list):

            # remove measure data from ComStock
            if isinstance(dataset, ComStock):
                dataset.add_sightglass_column_units()  # Add units to SightGlass columns if missing
                if upgrade_id == 'All':
                    df_data = dataset.data.to_pandas()
                    # df_data[dataset.DATASET] = df_data[dataset.DATASET] + ' - ' + df_data['upgrade_name']
                    comstock_dfs_to_concat.append(df_data)
                    df_data[dataset.DATASET] = df_data[dataset.DATASET].astype(str) + ' - ' + df_data[dataset.UPGRADE_NAME].astype(str)
                    dfs_to_concat.append(df_data)
                    up_name_map = dict(zip(df_data[dataset.UPGRADE_ID].unique(), df_data[dataset.UPGRADE_NAME].unique()))
                    upgrade_list = list(df_data[dataset.UPGRADE_ID].unique())
                    color_dict = self.linear_gradient(dataset.COLOR_COMSTOCK_BEFORE, dataset.COLOR_COMSTOCK_AFTER, len(upgrade_list))
                    for idx, upgrade_id in enumerate(upgrade_list):
                        dataset_name = dataset.dataset_name + ' - ' + up_name_map[upgrade_id]
                        dataset_names.append(dataset_name)
                        comstock_color_map[dataset_name] = color_dict['hex'][idx]
                        self.color_map[dataset_name] = color_dict['hex'][idx]
                elif upgrade_id not in dataset.data[dataset.UPGRADE_ID]:
                    logger.error(f"Upgrade {upgrade_id} not found in {dataset.dataset_name}. Enter a valid upgrade ID in the ComStockToCBECSComparison constructor or \"All\" to include all upgrades.")
                else:
                    # df_data = dataset.data.filter(pl.col(self.UPGRADE_NAME) == self.BASE_NAME).to_pandas()
                    df_data = dataset.data.filter(pl.col(dataset.UPGRADE_ID) == upgrade_id).to_pandas()
                    df_data[dataset.DATASET] = df_data[dataset.DATASET].astype(str) + ' - ' + df_data[dataset.UPGRADE_NAME].astype(str)
                    dataset_name = dataset.dataset_name + ' - ' + df_data.iloc[0][dataset.UPGRADE_NAME]
                    comstock_dfs_to_concat.append(df_data)
                    dfs_to_concat.append(df_data)
                    comstock_color_map[dataset_name] = dataset.color
                    self.color_map[dataset_name] = dataset.color
                    dataset_names.append(dataset_name)
            else:
                df_data = dataset.data
                dfs_to_concat.append(df_data)
                self.color_map[dataset.dataset_name] = dataset.color
                dataset_names.append(dataset.dataset_name)

        # Name the comparison
        if self.name is None:
            if len(dataset_names) > 2:
                self.name = ' vs '.join(sorted(dataset_names,key=len)[:2]) + ' and Upgrades'
            else:
                self.name = ' vs '.join(sorted(dataset_names))

        # Combine into a single dataframe for convenience
        self.data = pd.concat(dfs_to_concat, join='inner', ignore_index=True)
        current_dir = os.path.dirname(os.path.abspath(__file__))

        # Combine just comstock runs into single dataframe for QOI plots
        comstock_df = pd.concat(comstock_dfs_to_concat, join='inner', ignore_index=True)
        comstock_df = comstock_df[[self.DATASET] + self.QOI_MAX_DAILY_TIMING_COLS + self.QOI_MAX_USE_COLS + self.QOI_MIN_USE_COLS + self.QOI_MAX_USE_COLS_NORMALIZED + self.QOI_MIN_USE_COLS_NORMALIZED]

        # Make directories
        self.output_dir = os.path.join(current_dir, '..', 'output', self.name)
        for p in [self.output_dir]:
            if not os.path.exists(p):
                os.makedirs(p)

        # Make ComStock to CBECS comparison plots
        if make_comparison_plots:
            self.make_plots(self.data, self.column_for_grouping, self.color_map, self.output_dir)
            # QOI plots can only be made with comstock data because CBECS data do not have QOI columns
            self.make_qoi_plots(comstock_df, self.column_for_grouping, comstock_color_map, self.output_dir)
        else:
            logger.info("make_comparison_plots is set to false, so not plots were created. Set make_comparison_plots to True for plots.")

    def make_plots(self, df, column_for_grouping, color_map, output_dir):
        # Make plots comparing the datasets

        logger.info('Making comparison plots')
        self.plot_floor_area_and_energy_totals(df, column_for_grouping, color_map, output_dir)
        self.plot_eui_boxplots(df, column_for_grouping, color_map, output_dir)
        self.plot_floor_area_and_energy_totals_by_building_type(df, column_for_grouping, color_map, output_dir)
        self.plot_end_use_totals_by_building_type(df, column_for_grouping, color_map, output_dir)
        self.plot_eui_histograms_by_building_type(df, column_for_grouping, color_map, output_dir)
        self.plot_eui_boxplots_by_building_type(df, column_for_grouping, color_map, output_dir)
        self.plot_energy_rate_boxplots(df, column_for_grouping, color_map, output_dir)

    def make_qoi_plots(self, df, column_for_grouping, color_map, output_dir):
        self.plot_qoi_timing(df, column_for_grouping, color_map, output_dir)
        self.plot_qoi_max_use(df, column_for_grouping, color_map, output_dir)
        self.plot_qoi_min_use(df, column_for_grouping, color_map, output_dir)

    def export_to_csv_wide(self):
        # Exports comparison data to CSV in wide format

        file_name = f'ComStock wide.csv'
        file_path = os.path.join(self.output_dir, file_name)
        self.data.to_csv(file_path, index=False)