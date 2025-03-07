# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.
import os
from textwrap import indent

import boto3
import logging
import numpy as np
import pandas as pd

from comstockpostproc.resstock_naming_mixin import ResStockNamingMixin
from comstockpostproc.units_mixin import UnitsMixin
from comstockpostproc.s3_utilities_mixin import S3UtilitiesMixin

logger = logging.getLogger(__name__)


class ResStock(ResStockNamingMixin, UnitsMixin, S3UtilitiesMixin):
    def __init__(self, s3_base_dir, resstock_run_name, resstock_run_version, resstock_year,
        truth_data_version, weighted_energy_units='tbtu', reload_from_csv=False, downselect_to_multifamily=True,
        multifamily_building_efficiency_ratio=0.75):
        """
        A class to load and transform ResStock multifamily data for export, analysis, and comparison.
        Set up to pull from postprocessed results from S3 OEDI bucket, not raw ResStock results from S3 RESBLDG.
        Args:

            resstock_run_s3_dir (str): The location of the ResStock run on S3 in the OEDI bucket
            resstock_run_name (str): The name of the ResStock run, used to look
            up the data on S3
            resstock_year (int): The year represented by this ResStock run
            resstock_run_version (str): The version string for this ResStock run
            to differentiate it from other ResStock runs
            downselect_to_multifamily (bool): If True, drops all non-multifamily results
            multifamily_building_efficiency_ratio (float): 0-1 fraction of rentable area (units) to gross area,
            which includes common areas such as corridors, lobbies, gyms, etc.
            Typical ratio is 75% for multfamily per several sources such as
            https://multifamilyrefinance.com/glossary/building-efficiency-ratio-in-real-estate.
        """

        # Initialize members
        self.resstock_run_name = resstock_run_name
        self.resstock_run_version = resstock_run_version
        self.year = resstock_year
        self.truth_data_version = truth_data_version
        self.dataset_name = f'ResStock {self.resstock_run_version} {self.year}'
        current_dir = os.path.dirname(os.path.abspath(__file__))
        self.data_dir = os.path.join(current_dir, '..', 'resstock_data', self.resstock_run_version)
        self.truth_data_dir = os.path.join(current_dir, '..', 'truth_data', self.truth_data_version)
        self.resource_dir = os.path.join(current_dir, 'resources')
        self.output_dir = os.path.join(current_dir, '..', 'output', self.dataset_name)
        self.results_file_name = 'metadata.parquet'
        self.egrid_file_name = 'egrid_emissions_2019.csv'
        self.downselect_to_multifamily = downselect_to_multifamily
        self.multifamily_building_efficiency_ratio = multifamily_building_efficiency_ratio
        self.column_definition_file_name = 'resstock_column_definitions.csv'
        self.data = None
        self.weighted_energy_units = weighted_energy_units
        self.s3_client = boto3.client('s3')
        logger.info(f'Creating {self.dataset_name}')

        # Make directories
        for p in [self.data_dir, self.truth_data_dir, self.output_dir]:
            if not os.path.exists(p):
                os.makedirs(p)

        # S3 location
        self.s3_inpath = f"s3://{s3_base_dir}/{self.resstock_run_name}"

        # Load and transform data, preserving all columns
        self.download_data()
        if reload_from_csv:
            file_name = f'ResStock wide.csv'
            file_path = os.path.join(self.output_dir, file_name)
            if not os.path.exists(file_path):
                 raise FileNotFoundError(
                    f'Cannot find {file_path} to reload data, set reload_from_csv=False to create CSV.')
            logger.info(f'Reloading from CSV: {file_path}')
            self.data = pd.read_csv(file_path)
        else:
            self.load_data()
            self.rename_columns_and_convert_units()
            self.add_weighted_area_and_energy_columns()
            self.add_dataset_column()
            self.add_building_type_group_column()
            self.down_to_multifamily()
            self.add_multifamily_size_bin_column()
            self.reweight_to_multifamily_counts()

            logger.debug('ResStock columns after adding all data:')
            for c in self.data.columns:
                logger.debug(c)

    def download_data(self):
        # results.csv
        results_data_path = os.path.join(self.data_dir, self.results_file_name)
        if not os.path.exists(results_data_path):
            s3_path = f"{self.s3_inpath}/metadata/{self.results_file_name}"
            data = pd.read_parquet(s3_path, engine="pyarrow")
            data.to_parquet(results_data_path)

        # egrid emissions factors
        egrid_data_path = os.path.join(self.truth_data_dir, self.egrid_file_name)
        if not os.path.exists(egrid_data_path):
            s3_file_path = f'truth_data/{self.truth_data_version}/EPA/eGRID/{self.egrid_file_name}'
            self.read_delimited_truth_data_file_from_S3(s3_file_path, ',')

    def load_data(self):
        data_file_path = os.path.join(self.data_dir, self.results_file_name)
        if not os.path.exists(data_file_path):
            raise FileNotFoundError(
                f'Missing {data_file_path}, cannot load ResStock data')

        self.data = pd.read_parquet(data_file_path)

        logger.debug('ResStock columns before modification:')
        for c in self.data.columns:
            logger.debug(c)

    def rename_columns_and_convert_units(self):
        self.data.reset_index(inplace=True)  # bldg_id is the index, make a column

        # Add units to all energy columns
        energy_cols = [
            'out.electricity.bath_fan.energy_consumption',
            'out.electricity.ceiling_fan.energy_consumption',
            'out.electricity.clothes_dryer.energy_consumption',
            'out.electricity.clothes_washer.energy_consumption',
            'out.electricity.cooking_range.energy_consumption',
            'out.electricity.cooling.energy_consumption',
            'out.electricity.dishwasher.energy_consumption',
            'out.electricity.ext_holiday_light.energy_consumption',
            'out.electricity.exterior_lighting.energy_consumption',
            'out.electricity.extra_refrigerator.energy_consumption',
            'out.electricity.fans_cooling.energy_consumption',
            'out.electricity.fans_heating.energy_consumption',
            'out.electricity.freezer.energy_consumption',
            'out.electricity.garage_lighting.energy_consumption',
            'out.electricity.heating.energy_consumption',
            'out.electricity.heating_supplement.energy_consumption',
            'out.electricity.hot_tub_heater.energy_consumption',
            'out.electricity.hot_tub_pump.energy_consumption',
            'out.electricity.house_fan.energy_consumption',
            'out.electricity.interior_lighting.energy_consumption',
            'out.electricity.plug_loads.energy_consumption',
            'out.electricity.pool_heater.energy_consumption',
            'out.electricity.pool_pump.energy_consumption',
            'out.electricity.pumps_cooling.energy_consumption',
            'out.electricity.pumps_heating.energy_consumption',
            'out.electricity.pv.energy_consumption',
            'out.electricity.range_fan.energy_consumption',
            'out.electricity.recirc_pump.energy_consumption',
            'out.electricity.refrigerator.energy_consumption',
            'out.electricity.vehicle.energy_consumption',
            'out.electricity.water_systems.energy_consumption',
            'out.electricity.well_pump.energy_consumption',
            'out.fuel_oil.heating.energy_consumption',
            'out.fuel_oil.water_systems.energy_consumption',
            'out.natural_gas.clothes_dryer.energy_consumption',
            'out.natural_gas.cooking_range.energy_consumption',
            'out.natural_gas.fireplace.energy_consumption',
            'out.natural_gas.grill.energy_consumption',
            'out.natural_gas.heating.energy_consumption',
            'out.natural_gas.hot_tub_heater.energy_consumption',
            'out.natural_gas.lighting.energy_consumption',
            'out.natural_gas.pool_heater.energy_consumption',
            'out.natural_gas.water_systems.energy_consumption',
            'out.propane.clothes_dryer.energy_consumption',
            'out.propane.cooking_range.energy_consumption',
            'out.propane.heating.energy_consumption',
            'out.propane.water_systems.energy_consumption',
            'out.wood.heating.energy_consumption',
            'out.electricity.total.energy_consumption',
            'out.fuel_oil.total.energy_consumption',
            'out.natural_gas.total.energy_consumption',
            'out.propane.total.energy_consumption',
            'out.wood.total.energy_consumption',
            'out.site_energy.total.energy_consumption'
        ]

        for orig_name in energy_cols:
            logger.debug(f"Processing {orig_name}")

            # Check for unit conversion
            orig_units = 'kwh'

            # Ensure the column is numeric
            self.data[orig_name] = self.data[orig_name].replace('Not Applicable', np.nan)
            self.data[orig_name] = self.data[orig_name].astype('float64')

            # Append new units to column name, using .. separator for easier parsing
            new_name = f'{orig_name}..{orig_units}'

            # Rename the column
            logger.debug(f'-- New name = {new_name}')
            self.data.rename(columns={orig_name: new_name}, inplace=True)

    def down_to_multifamily(self):
    # Downselect to just multifamily buildings
        if not self.downselect_to_multifamily:
            logger.warning('ResStock not downselected to Multifamily: if unintentional, \
                set downselect_to_multifamily=True in constructor')
        else:
            logger.info('Downselecting ResStock to Multifamily buildings only')
            logger.debug(f'before downselect to multifamily, self.data[weight].sum() = {self.data["weight"].sum()}')
            self.data = self.data.loc[~(self.data['in.geometry_building_number_units_mf'] == 'None')].copy()
            self.data.loc[:, 'in.geometry_building_number_units_mf'] = pd.to_numeric(self.data['in.geometry_building_number_units_mf'])
            logger.debug(f'after downselect to multifamily, self.data[weight].sum() = {self.data["weight"].sum()}')

    def add_multifamily_size_bin_column(self):
    # Adds bins for the size of the multifamily buildings the unit is inside
        if not self.downselect_to_multifamily:
            return

        # Estimate the rentable floor area of the building this unit is in
        self.data.loc[:, 'in.rentable_floor_area_of_building_this_unit_is_in..ft2'] = self.data['in.geometry_building_number_units_mf'] * self.data[self.FLR_AREA]

        # Estimate the total floor area of the building the unit is in, including common areas
        ber = self.multifamily_building_efficiency_ratio
        logger.info(f'Assuming a rentable area to gross area ratio of {ber:.2f} when setting multifamily building size bins only.')
        logger.info(f'This is reflected ONLY in "{self.FLR_AREA_CAT}" and "in.total_floor_area_of_building_this_unit_is_in..ft2"')
        logger.info(f'It is not reflected in the weighted energy or floor area columns!')
        self.data.loc[:, 'in.total_floor_area_of_building_this_unit_is_in..ft2'] = self.data['in.geometry_building_number_units_mf'] * self.data[self.FLR_AREA] / ber

        # Put each model into a bin by floor area of the building the unit is inside
        def size_bin(row):
            sf = row['in.total_floor_area_of_building_this_unit_is_in..ft2']

            # Bin the square footage
            if sf < 1_000:
                b = '_1000'
            elif sf < 5_000:
                b = '1001_5000'
            elif sf < 10_000:
                b = '5001_10000'
            elif sf < 25_000:
                b = '10001_25000'
            elif sf < 50_000:
                b = '25001_50000'
            elif sf < 100_000:
                b = '50001_100000'
            elif sf < 200_000:
                b = '100001_200000'
            elif sf < 500_000:
                b = '200001_500000'
            elif sf < 1_000_000:
                b = '500001_1mil'
            else:
                b = 'over_1mil'

            return b

        self.data.loc[:, self.FLR_AREA_CAT] = self.data.apply(lambda row: size_bin(row), axis=1)

    def reweight_to_multifamily_counts(self):
    # Changes the weights from the ResStock convention of representing number of units
    # to the ComStock convention of representing number of buildings.
    # Weights will be fractional as each unit is a fraction of a single building.
        if not self.downselect_to_multifamily:
            return
        else:
            logger.info('Recalculating weights to represent number of multifamily buildings represented')

        # Reweight to approximate number of multifamily buildings of the given size represented by
        # the results for this model.
        def reweight_to_bldg_count(row):
            sf_of_building_unit_is_in = row['in.rentable_floor_area_of_building_this_unit_is_in..ft2']
            sf_represented_by_results = row[self.FLR_AREA] * row['weight']
            num_bldgs_represented_by_results = sf_represented_by_results / sf_of_building_unit_is_in

            return num_bldgs_represented_by_results

        self.data.loc[:, self.BLDG_WEIGHT] = self.data.apply(lambda row: reweight_to_bldg_count(row), axis=1)

    def add_dataset_column(self):
        self.data.loc[:, 'dataset'] = self.dataset_name

    def add_building_type_group_column(self):
        self.data.loc[:, 'in.comstock_building_type_group'] = 'Multifamily'

    def add_weighted_area_and_energy_columns(self):
        # Area - ensure the column is numeric then create weighted column
        self.data.loc[:, self.FLR_AREA] = self.data[self.FLR_AREA].replace('Not Applicable', np.nan)
        self.data.loc[:, self.FLR_AREA] = self.data[self.FLR_AREA].astype('float64')
        new_area_col = self.col_name_to_weighted(self.FLR_AREA)
        self.data.loc[:, new_area_col] = self.data[self.FLR_AREA] * self.data[self.BLDG_WEIGHT]

        # Energy
        for col in (self.COLS_TOT_ANN_ENGY + self.COLS_ENDUSE_ANN_ENGY):
            # Ensure the energy column is numeric then create weighted column
            self.data.loc[:, col] = self.data[col].replace('Not Applicable', np.nan).astype('float64')
            new_col = self.col_name_to_weighted(col, self.weighted_energy_units)

            # Weight and convert to TBtu
            old_units = self.units_from_col_name(col)
            new_units = self.weighted_energy_units
            conv_fact = self.conv_fact(old_units, new_units)
            self.data.loc[:, new_col] = self.data[col] * self.data[self.BLDG_WEIGHT] * conv_fact

    def export_to_csv_wide(self):
        # Exports resstock data to CSV in wide format

        file_name = f'ResStock wide.csv'
        file_path = os.path.join(self.output_dir, file_name)
        self.data.to_csv(file_path, index=False)

    def export_to_csv_long(self, add_egrid_emissions=True):
        # Exports resstock data to CSV in long format, with rows for each end use

        # Convert ResStock into long format, with a new row for each Fuel.Enduse combination
        engy_cols = []
        for col in (self.COLS_ENDUSE_ANN_ENGY):
            engy_cols.append(self.col_name_to_weighted(col, self.weighted_energy_units))

        bldg_cols = []
        for c in self.data.columns:
            if not 'out.' in c:
                bldg_cols.append(c)

        var_col = 'type.fuel.enduse.energy_consumption..units'
        val_col = 'weighted_energy_consumption'
        dl = pd.melt(self.data, id_vars=[self.BLDG_ID, 'in.state_abbreviation'], value_vars=engy_cols, var_name=var_col, value_name=val_col)

        # Remove rows with zero values for the fuel type/end use combo
        dl = dl.loc[dl[val_col] > 0]

        # Sort by building ID
        dl.sort_values(self.BLDG_ID, inplace=True)

        # Separate'type.fuel.enduse.energy_consumption..units' into multiple columns
        def split_col_name(col_name):
            p = self.engy_col_name_to_parts(col_name)

            return [p['fuel'], p['enduse'], p['units'], ]

        dl['fuel'], dl['enduse'], dl['weighted_energy_consumption_units'] = zip(*dl[var_col].apply(split_col_name))

        # Drop the combined type.fuel.enduse.energy_consumption..units column
        dl.drop(var_col, axis=1, inplace=True)

        if add_egrid_emissions:
            logger.info('Adding emissions using eGRID 2019 emissions factors')
            # Read the emissions data
            file_name = self.egrid_file_name
            file_path = os.path.join(self.truth_data_dir, file_name)
            egrid = pd.read_csv(file_path, index_col='State')

            # metric_ton_to_lb = 2204.62
            cf = (1.0/1e3)*(1.0/3.412)*(1e9/1.0)*(1.0/2204.62)*(1.0/1e6)

            egrid['million_metric_ton_CO2e_per_TBtu'] = egrid['total_output_emissions_rates_CO2e_lb_per_MWh'] * cf
            egrid.head()

            # Calculate the emissions factors for each row
            def emissions(egrid, row):
                # Determine emissions factor by fuel (and location, for electricity)
                fuel = row['fuel']
                state = row['in.state_abbreviation']
                if pd.isna(state):
                    logger.error(f'Missing electric emissions factor for state {row["in.state_abbreviation"]}')
                    return 0.0
                if fuel == 'electricity':
                    cf_million_metric_tons_per_TBtu = egrid.loc[state]['million_metric_ton_CO2e_per_TBtu']
                elif fuel == 'natural_gas':
                    # Natural Gas for homes and businesses: 116.65 lb CO2/million BTU
                    # https://www.eia.gov/environment/emissions/co2_vol_mass.php
                    # Plus 2.3% leakage rate of methane calculated from Science paper
                    # https://www.science.org/doi/10.1126/science.aar7204
                    cf_million_metric_tons_per_TBtu = 141.67/1000000*1000*1E9/2204.62/1000000
                elif fuel == 'fuel_oil':
                    # Home Heating Fuel for homes and businesses: 163.45 lb CO2/million BTU
                    # https://www.eia.gov/environment/emissions/co2_vol_mass.php
                    cf_million_metric_tons_per_TBtu = 163.45/1000000*1000*1E9/2204.62/1000000
                elif fuel == 'propane':
                    # Propane for homes and businesses: 138.63 lb CO2/million BTU
                    # https://www.eia.gov/environment/emissions/co2_vol_mass.php
                    cf_million_metric_tons_per_TBtu = 138.63/1000000*1000*1E9/2204.62/1000000
                elif fuel == 'wood':
                    # No data for wood or biomass here
                    # https://www.eia.gov/environment/emissions/co2_vol_mass.php
                    return 0.0
                else:
                    raise Exception(f'Fuel type {fuel} was not recognized, cannot calculate emissions factor')

                # Calculate emssions (million metric tons)
                energy_units = row['weighted_energy_consumption_units']
                assert(energy_units == 'TBtu')
                energy_TBtu = row['weighted_energy_consumption']
                emis_mmt = energy_TBtu * cf_million_metric_tons_per_TBtu

                return emis_mmt

            dl['ghg_emissions..million_metric_tons_CO2e)'] = dl.apply(lambda row: emissions(egrid, row), axis=1)

            # Drop the in.state_abbreviation column, will be in building characteristics data
            dl.drop('in.state_abbreviation', axis=1, inplace=True)

        # Save files - separate building energy from characteristics for file size
        file_name = f'ResStock energy long.csv'
        file_path = os.path.join(self.output_dir, file_name)
        dl.to_csv(file_path, index=False)
