# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.
import os
import logging

import numpy as np

from comstockpostproc.naming_mixin import NamingMixin
from comstockpostproc.units_mixin import UnitsMixin
from comstockpostproc.plotting_mixin import PlottingMixin


logger = logging.getLogger(__name__)

class ComStockMeasureComparison(NamingMixin, UnitsMixin, PlottingMixin):
    def __init__(self, comstock_object, image_type='jpg', name=None, make_comparison_plots=True):

        # Initialize members
        self.data = comstock_object.data.to_pandas()
        self.color_map = {}
        self.image_type = image_type
        self.name = name
        self.dict_upid_to_upname = dict(zip(self.data[self.UPGRADE_ID], self.data[self.UPGRADE_NAME]))
        current_dir = os.path.dirname(os.path.abspath(__file__))
        self.dataset_name = comstock_object.dataset_name
        self.output_dir = os.path.join(current_dir, '..', 'output', self.dataset_name, 'measure_runs')
        self.column_for_grouping = self.UPGRADE_NAME
        self.dict_measure_dir = {} # this can be called to determine output directory
        self.upgrade_ids_for_comparison = comstock_object.upgrade_ids_for_comparison

        # Ensure that the comstock object has savings columns included
        if not comstock_object.include_upgrades:
            logger.error(f'Cannot compare upgrades for {comstock_object.dataset_name}, retry with include_upgrades=True')
            return

        # make output directories; create dictionary to store upgrade ID as key and upgrade name as value
        for upgrade, upgrade_name in self.dict_upid_to_upname.items():

            # add dictionary entry and create directory for non-baseline
            if upgrade != '00' and upgrade != 0:
                upgrade_dir_name = 'up' + str(upgrade).zfill(2) + '_' + upgrade_name
                upgrade_dir_name = upgrade_dir_name[:20]  # Truncate name to avoid long filepath errors on Windows
                self.dict_measure_dir[upgrade] = os.path.join(self.output_dir, upgrade_dir_name)
                # make directory if does not exist
                if not os.path.exists(self.dict_measure_dir[upgrade]):
                    os.makedirs(self.dict_measure_dir[upgrade])

                # filter dataset to upgrade and baseline only
                up_base_id = '00'
                upgrade_id = upgrade
                if self.data.dtypes[self.UPGRADE_ID] == np.int64:
                    up_base_id = 0
                    upgrade_id = int(upgrade)

                # convert grouping column from cat to str to avoid processing errors with more than 2 measures
                self.data[self.column_for_grouping] = self.data[self.column_for_grouping].astype(str)

                df_upgrade = self.data.loc[(self.data[self.UPGRADE_ID]==upgrade_id) | (self.data[self.UPGRADE_ID]==up_base_id), :]

                color_map = {'Baseline': self.COLOR_COMSTOCK_BEFORE, upgrade_name: self.COLOR_COMSTOCK_AFTER}

                # make consumption plots for upgrades if requested by user
                if make_comparison_plots:
                    self.make_plots(df_upgrade, self.column_for_grouping, color_map, self.dict_measure_dir[upgrade])
                else:
                    logger.info("make_comparison_plots is set to false, so not plots were created. Set make_comparison_plots to True for plots.")

        # make plots comparing multiple upgrades together
        for comp_name, comp_up_ids in self.upgrade_ids_for_comparison.items():

                comp_output_dir =  os.path.join(self.output_dir, comp_name)

                # make directory if does not exist
                if not os.path.exists(comp_output_dir):
                    os.makedirs(comp_output_dir)

                # convert grouping column from cat to str to avoid processing errors with more than 2 measures
                self.data[self.column_for_grouping] = self.data[self.column_for_grouping].astype(str)

                # filter to requested upgrades
                df_upgrade = self.data.loc[(self.data[self.UPGRADE_ID].isin(comp_up_ids))]

                ## set color map for colors and measure ordering in plots
                color_dict = self.linear_gradient(self.COLOR_COMSTOCK_BEFORE, self.COLOR_COMSTOCK_AFTER, len(comp_up_ids))
                color_map = {}
                for i, up_id in enumerate(comp_up_ids):
                    if up_id in self.dict_upid_to_upname:
                        color_map[self.dict_upid_to_upname[up_id]] = color_dict['hex'][i]
                    else:
                        print(f"up_id {up_id} not found in self.dict_upid_to_upname")

                # make consumption plots for upgrades if requested by user
                if make_comparison_plots:
                    self.make_comparative_plots(df_upgrade, self.column_for_grouping, color_map, comp_output_dir)
                else:
                    logger.info("make_comparison_plots is set to false, so not plots were created. Set make_comparison_plots to True for plots.")


    def make_plots(self, df, column_for_grouping, color_map, output_dir):
        # Make plots comparing the upgrades

        logger.info(f'Making comparison plots for upgrade')
        self.plot_energy_by_enduse_and_fuel_type(df, column_for_grouping, color_map, output_dir)
        self.plot_emissions_by_fuel_type(df, column_for_grouping, color_map, output_dir)
        self.plot_floor_area_and_energy_totals(df, column_for_grouping, color_map, output_dir)
        self.plot_floor_area_and_energy_totals_by_building_type(df, column_for_grouping, color_map, output_dir)
        self.plot_end_use_totals_by_building_type(df, column_for_grouping, color_map, output_dir)
        self.plot_eui_histograms_by_building_type(df, column_for_grouping, color_map, output_dir)
        self.plot_eui_boxplots_by_building_type(df, column_for_grouping, color_map, output_dir)
        self.plot_measure_savings_distributions_enduse_and_fuel(df, output_dir)
        self.plot_measure_savings_distributions_by_building_type(df, output_dir)
        self.plot_measure_savings_distributions_by_climate_zone(df, output_dir)
        self.plot_measure_savings_distributions_by_hvac_system_type(df, output_dir)
        self.plot_qoi_timing(df, column_for_grouping, color_map, output_dir)
        self.plot_qoi_max_use(df, column_for_grouping, color_map, output_dir)
        self.plot_qoi_min_use(df, column_for_grouping, color_map, output_dir)

    def make_comparative_plots(self, df, column_for_grouping, color_map, output_dir):
        # Make plots comparing the upgrades

        logger.info(f'Making comparison plots for upgrade groupings')
        self.plot_energy_by_enduse_and_fuel_type(df, column_for_grouping, color_map, output_dir)
        self.plot_emissions_by_fuel_type(df, column_for_grouping, color_map, output_dir)
        self.plot_floor_area_and_energy_totals(df, column_for_grouping, color_map, output_dir)


