# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.

import os
import logging

import pandas as pd
import polars as pl
from typing import List

from comstockpostproc.naming_mixin import NamingMixin
from comstockpostproc.units_mixin import UnitsMixin
from comstockpostproc.plotting_mixin import PlottingMixin
from comstockpostproc.eia import EIA
from comstockpostproc.comstock import ComStock

logger = logging.getLogger(__name__)

class ComStockToEIAComparison(NamingMixin, UnitsMixin, PlottingMixin):
    def __init__(self, comstock_list: List[ComStock], eia_list: List[EIA], upgrade_id=0, image_type='jpg', name=None, make_comparison_plots=True):
        """
        Creates the ComStock to EIA comparison plots.

        Args:
            comstock_list (List[ComStock]): List of ComStock dataset objects
            eia_list (List[EIA]): List of EIA dataset objects.
            upgrade_id (Union[str, int], optional): The upgrade ID to include in the chart, or 'All' to include all upgrades for the ComStock run(s).
            image_type (str, optional): Image file type to use. Defaults to 'jpg'.
            name (str, optional): Name of output directory. If None, a name will be generated. Defaults to None.
            make_comparison_plots (bool, optional): Flag to create comparison plots. Defaults to True.
        """
        # Initialize members
        self.comstock_list = comstock_list
        self.eia_list = eia_list
        self.data = None
        self.monthly_data = None
        self.monthly_data_gap = None
        self.color_map = {}
        self.monthly_color_map = {}
        self.image_type = image_type
        self.name = name

        # Concatenate the datasets and create a color map
        monthly_dfs_to_concat = []
        annual_dfs_to_concat = []
        dataset_names = []
        for dataset in (eia_list + comstock_list):
        # for dataset in (comstock_list + eia_list):
            logger.info(f'Adding dataset: {dataset.dataset_name}')
            dataset_names.append(dataset.dataset_name)
            if isinstance(dataset, ComStock):
                # Annual emissions
                annual_upgrade_ids = [upgrade_id]
                if upgrade_id == 'All':
                    annual_upgrade_ids = dataset.data.get_column('upgrade').unique().to_list()
                annual_data = dataset.data.filter(pl.col('upgrade').is_in(annual_upgrade_ids))
                if not annual_upgrade_ids == [0]:
                    annual_data = annual_data.with_columns(
                        pl.concat_str([pl.col(dataset.DATASET), pl.col(dataset.UPGRADE_NAME)], separator=" - ").alias(dataset.DATASET),
                    )
                color_dict = self.linear_gradient(dataset.COLOR_COMSTOCK_BEFORE, dataset.COLOR_COMSTOCK_AFTER, len(annual_upgrade_ids))
                for idx, dataset_upgrade_name in enumerate(annual_data.get_column(dataset.DATASET).unique().sort().to_list()):
                    self.color_map[dataset_upgrade_name] = color_dict['hex'][idx]
                annual_dfs_to_concat.append(annual_data.to_pandas())

                # Monthly energy
                if dataset.monthly_data is None:
                    logger.warning(f'No monthly_data was available for {dataset.dataset_name}, not including in EIA comparison.')
                    continue
                monthly_upgrade_ids = [upgrade_id]
                if upgrade_id == 'All':
                    monthly_upgrade_ids = dataset.monthly_data.get_column('upgrade').unique().to_list()
                monthly_data = dataset.monthly_data.filter(pl.col('upgrade').is_in(monthly_upgrade_ids))
                if not monthly_upgrade_ids == [0]:
                    monthly_data = monthly_data.with_columns(
                        pl.concat_str([pl.col(dataset.DATASET), pl.col('upgrade_name')], separator=" - ").alias(dataset.DATASET),
                    )
                color_dict = self.linear_gradient(dataset.COLOR_COMSTOCK_BEFORE, dataset.COLOR_COMSTOCK_AFTER, len(monthly_upgrade_ids))
                for idx, dataset_upgrade_name in enumerate(monthly_data.get_column(dataset.DATASET).unique().sort().to_list()):
                    self.monthly_color_map[dataset_upgrade_name] = color_dict['hex'][idx]
                monthly_dfs_to_concat.append(monthly_data.to_pandas())
            else:
                # Annual emissions
                annual_dfs_to_concat.append(dataset.emissions_data.to_pandas())
                self.color_map[dataset.dataset_name] = dataset.color

                # Monthly energy
                monthly_dfs_to_concat.append(dataset.monthly_data)
                self.monthly_color_map[dataset.dataset_name] = dataset.color

        # Name the comparison
        if self.name is None:
            self.name = ' vs '.join(sorted(dataset_names,key=len)[:2])

        # Combine into a single dataframe for convenience
        self.monthly_data = pd.concat(monthly_dfs_to_concat, join='outer', ignore_index=True)
        self.data = pd.concat(annual_dfs_to_concat, join='inner', ignore_index=True)
        current_dir = os.path.dirname(os.path.abspath(__file__))

        # Make directories
        self.output_dir = os.path.abspath(os.path.join(current_dir, '..', 'output', self.name))
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)
        logger.info(f"output_dir: {self.output_dir}")

        # Make ComStock to EIA comparison plots
        if make_comparison_plots:
            self.make_emissions_plots(self.data, self.color_map, self.output_dir)
            self.make_plots(self.monthly_data, self.monthly_color_map, self.output_dir)
        else:
            logger.info("make_comparison_plots is set to false, so not plots were created. Set make_comparison_plots to True for plots.")

    def export_to_csv_wide(self):
        # Exports comparison data to CSV in wide format
        file_name = f'ComStock Monthly Long.csv'
        file_path = os.path.join(self.output_dir, file_name)
        self.monthly_data.to_csv(file_path, index=False)

    def make_plots(self, df, color_map, output_dir):
        # Make plots comparing the datasets

        logger.info('Making energy comparison plots')
        self.plot_annual_energy_consumption_for_eia(df, color_map, output_dir)
        self.plot_monthly_energy_consumption_for_eia(df, color_map, output_dir)

    def make_emissions_plots(self, df, color_map, output_dir):
        # Make plots comparing annual emissions by fuel

        logger.info('Making emissions comparison plots')
        self.plot_annual_emissions_comparison(df, self.DATASET, color_map, output_dir)