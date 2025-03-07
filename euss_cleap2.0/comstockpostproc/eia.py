# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.


"""
# Commercial EIA annual comparisons.
- - - - - - - - -
A class to run EIA Form 861M data and EIA natural gas data comparisons.
This class queries ComStock results and Load data from Athena and creates graphics for validation. \
The methods in this class produce the following graphics.

- Annual EIA Electricity Comparison by utility number
- Annual EIA Gas Comparison by State

**Authors:**

- Liang Zhang (Liang.Zhang@nrel.gov)
- Anthony Fontanini (Anthony.Fontanini@nrel.gov)
- Andrew Parker (Andrew.Parker@nrel.gov)
- Jonathan Gonzalez
- Lauren Adams (Lauren.Adams@nrel.gov)
"""

# Import Modules
import os

import boto3
import botocore
import logging
import numpy as np
import pandas as pd
import polars as pl

from comstockpostproc.naming_mixin import NamingMixin
from comstockpostproc.units_mixin import UnitsMixin
from comstockpostproc.s3_utilities_mixin import S3UtilitiesMixin

# Create logger for AWS queries
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Rename month numbers to month names
MONTH_DICT = {
    1: "January",
    2: "February",
    3: "March",
    4: "April",
    5: "May",
    6: "June",
    7: "July",
    8: "August",
    9: "September",
    10: "October",
    11: "November",
    12: "December"
}
MONTHS = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
]

class EIA(NamingMixin, UnitsMixin, S3UtilitiesMixin):
    def __init__(self, truth_data_version, year, color_hex=NamingMixin.COLOR_EIA, reload_from_csv=False):
        """
        A class to produce validation graphics based on EIA Form 861, EIA natural gas data, and utility LRD.
        Args:
            truth_data_version (string): The version of the EIA truth data. Example: 'v01'.
            year (int): The year to perform the comparison
        """

        # Initialize members
        self.Btu_to_kBtu = (1.0 / 1e3)
        self.MWh_to_kWh = 1e3
        self.truth_data_version = truth_data_version
        self.year = year
        self.dataset_name = f'EIA {self.year}'
        current_dir = os.path.dirname(os.path.abspath(__file__))
        self.truth_data_dir = os.path.join(current_dir, '..', 'truth_data', self.truth_data_version)
        self.output_dir = os.path.join(current_dir, '..', 'output', self.dataset_name)
        self.monthly_data = None
        self.color = color_hex
        self.emissions_data = None
        self.emissions_cols = []

        # Initialize s3 client
        self.s3_client = boto3.client('s3', config=botocore.client.Config(max_pool_connections=50))

        # Make directories
        for p in [self.truth_data_dir, self.output_dir]:
            if not os.path.exists(p):
                os.makedirs(p)

        # Load and transform data, preserving all columns
        self.download_truth_data()
        if reload_from_csv:
            file_name = f'EIA wide.csv'
            file_path = os.path.join(self.output_dir, file_name)
            if not os.path.exists(file_path):
                 raise FileNotFoundError(
                    f'Cannot find {file_path} to reload data, set reload_from_csv=False to create CSV.')
            logger.info(f'Reloading from CSV: {file_path}')
            self.monthly_data = pd.read_csv(file_path, low_memory=False)
        else:
            self.convert_eia_natural_gas_volumes_to_energy()
            self.get_eia_monthly_consumption_by_state()
            self.get_eia_annual_emissions_by_fuel()


    def download_truth_data(self):
        # Monthly electricity by state
        file_name = 'eia_form_861M_monthly_electricity_sales_to_commercial_customers_by_state.csv'
        file_path = os.path.join(self.truth_data_dir, file_name)
        if not os.path.exists(file_path):
            s3_file_path = f'truth_data/{self.truth_data_version}/EIA/EIA Form 861/{file_name}'
            self.read_delimited_truth_data_file_from_S3(s3_file_path, ',')

        # Monthly natural gas by state
        file_name = 'eia_monthly_natural_gas_volumes_to_commercial_consumers_by_state.csv'
        file_path = os.path.join(self.truth_data_dir, file_name)
        if not os.path.exists(file_path):
            s3_file_path = f'truth_data/{self.truth_data_version}/EIA/EIA Form 861/{file_name}'
            self.read_delimited_truth_data_file_from_S3(s3_file_path, ',')

        # Monthly gas heat content by state
        file_name = 'eia_monthly_natural_gas_heat_content_per_volume_by_state.csv'
        file_path = os.path.join(self.truth_data_dir, file_name)
        if not os.path.exists(file_path):
            s3_file_path = f'truth_data/{self.truth_data_version}/EIA/EIA Form 861/{file_name}'
            self.read_delimited_truth_data_file_from_S3(s3_file_path, ',')

        # State/census region/census division mapping
        file_name = 'state_region_division_table.csv'
        file_path = os.path.join(self.truth_data_dir, file_name)
        if not os.path.exists(file_path):
            s3_file_path = f'truth_data/{self.truth_data_version}/EIA/CBECS/{file_name}'
            self.read_delimited_truth_data_file_from_S3(s3_file_path, ',')

        # Annual emissions by fuel
        file_name = 'eia_annual_commercial_emissions.csv'
        file_path = os.path.join(self.truth_data_dir, file_name)
        if not os.path.exists(file_path):
            s3_file_path = f'truth_data/{self.truth_data_version}/EIA/EIA Emissions Data/{file_name}'
            self.read_delimited_truth_data_file_from_S3(s3_file_path, ',')

    def convert_eia_natural_gas_volumes_to_energy(self):
        """Convert EIA natural gas sales volumes to energy based on heat content."""

        # Monthly natural gas by state
        file_name = 'eia_monthly_natural_gas_volumes_to_commercial_consumers_by_state.csv'
        file_path = os.path.join(self.truth_data_dir, file_name)
        gas_sales = pd.read_csv(file_path)
        gas_sales.rename(columns=lambda x: x.replace('(MMcf)', '').strip(), inplace=True)
        # remove leading 'the ' from DC
        gas_sales.rename(columns=lambda x: x.replace('the ', '').strip(), inplace=True)
        gas_sales_long = pd.melt(gas_sales, id_vars=['Year', 'Month'], var_name='State', value_name='Delivered Volume MMcf')
        gas_sales_long = gas_sales_long.set_index(['Year', 'Month', 'State'])

        # Monthly gas heat content by state
        file_name = 'eia_monthly_natural_gas_heat_content_per_volume_by_state.csv'
        file_path = os.path.join(self.truth_data_dir, file_name)
        heat_content = pd.read_csv(file_path)
        heat_content.rename(columns=lambda x: x.replace('(BTU per Cubic Foot)', '').strip(), inplace=True)
        heat_content_long = pd.melt(heat_content, id_vars=['Year', 'Month'], var_name='State', value_name='Heat Content BTU per cf')
        heat_content_long = heat_content_long.set_index(['Year', 'Month', 'State'])

        # Merge the two datasets together
        vol_and_heat = pd.merge(gas_sales_long,
                                heat_content_long,
                                left_index=True,
                                right_index=True,
                                how='inner'
                                )

        # Calculate the natural gas energy
        MMcf_to_cf = 1e6
        vol_and_heat['BTU'] = vol_and_heat['Delivered Volume MMcf'] * MMcf_to_cf * vol_and_heat['Heat Content BTU per cf']

        # Write data
        file_name = 'calculated_eia_monthly_natural_gas_energy_by_state.csv'
        file_path = os.path.join(self.truth_data_dir, file_name)
        vol_and_heat.to_csv(file_path)

        return vol_and_heat

    def get_state_metadata(self, file_name):
        # load the state id table
        file_path = os.path.join(self.truth_data_dir, file_name)
        if not os.path.exists(file_path):
            raise AssertionError('State metadata not found, download truth data')
        else:
            state_table = pl.read_csv(file_path)

        # Rename columns
        state_table = state_table.rename({'State': self.STATE_NAME, 'State Code': self.STATE_ABBRV})

        return state_table

    def get_eia_monthly_gas_consumption(self, file_name):
        # load the EIA nat gas truth data
        file_path = os.path.join(self.truth_data_dir, file_name)
        if not os.path.exists(file_path):
            raise AssertionError('EIA monthly natural gas data not found, download truth data')
        else:
            eia_gas = pd.read_csv(file_path)

        # Rename columns
        eia_gas.rename(columns={'State': self.STATE_NAME}, inplace=True)

        # Downselect to the year of interest
        eia_gas = eia_gas[eia_gas['Year']==self.year]

        # Remove U.S. total row, leaving only States
        eia_gas = eia_gas[~(eia_gas[self.STATE_NAME] == 'U.S.')]

        # Convert to kBtu
        eia_gas['Natural gas consumption (thous Btu)'] = pd.to_numeric(eia_gas['BTU']) * self.Btu_to_kBtu

        return eia_gas

    def get_eia_monthly_electricity_consumption(self, file_name):
        # load the EIA electricity data
        file_path = os.path.join(self.truth_data_dir, file_name)
        if not os.path.exists(file_path):
            raise AssertionError('EIA monthly electricity data not found, download truth data')
        else:
            eia_electricity = pd.read_csv(file_path)

        # Rename columns
        eia_electricity.rename(columns={'State': self.STATE_ABBRV}, inplace=True)

        # Downselect to the year of interest
        eia_electricity[['Year']] = eia_electricity[['Year']].apply(pd.to_numeric, errors='coerce')
        eia_electricity = eia_electricity[eia_electricity['Year']==self.year]

        # Convert to kWh
        eia_electricity['Electricity consumption (kWh)'] = pd.to_numeric(eia_electricity['Sales (Megawatthours)']) * self.MWh_to_kWh

        return eia_electricity

    def get_eia_monthly_consumption_by_state(self):

        # load the state id table
        state_table = self.get_state_metadata('state_region_division_table.csv').to_pandas()

        # load the EIA natural gas data
        file_name = f'calculated_eia_monthly_natural_gas_energy_by_state.csv'
        eia_gas = self.get_eia_monthly_gas_consumption(file_name)
        eia_gas = pd.merge(eia_gas, state_table, how='left', on=self.STATE_NAME)
        eia_gas[self.DATASET] = f'EIA Gas Data {self.year}'
        eia_gas = eia_gas[['Month', 'FIPS Code', self.STATE_ABBRV, 'Division', self.DATASET, 'Natural gas consumption (thous Btu)']]

        # load the EIA electricity data
        file_name = f'eia_form_861M_monthly_electricity_sales_to_commercial_customers_by_state.csv'
        eia_electricity = self.get_eia_monthly_electricity_consumption(file_name)
        eia_electricity = pd.merge(eia_electricity, state_table, how='left', on=self.STATE_ABBRV)
        eia_electricity[self.DATASET] = f'EIA 861M Electricity Data {self.year}'
        eia_electricity = eia_electricity[['Month', 'FIPS Code', self.STATE_ABBRV, 'Division', self.DATASET, 'Electricity consumption (kWh)']]

        # Merge EIA gas and electricity datasets
        eia = pd.merge(eia_gas, eia_electricity[['Month' , self.STATE_ABBRV, 'Electricity consumption (kWh)']], on=['Month' , self.STATE_ABBRV])
        eia[self.DATASET] = f'EIA {self.year}'
        self.monthly_data = eia

        # Exports EIA dataset to CSV in wide format
        file_name = f'EIA wide.csv'
        file_path = os.path.join(self.output_dir, file_name)
        eia.to_csv(file_path, index=False)

        return eia

    def get_eia_annual_emissions_by_fuel(self):
        # load the EIA electricity data
        file_name = 'eia_annual_commercial_emissions.csv'
        file_path = os.path.join(self.truth_data_dir, file_name)
        if not os.path.exists(file_path):
            raise AssertionError('EIA annual emissions data not found, download truth data')
        else:
            eia_emissions = pl.read_csv(file_path, infer_schema_length=10000)

        # Downselect to year of interest
        eia_emissions = eia_emissions.filter(pl.col('Year') == self.year)

        # Rename the EIA data to match ComStock emissions column names
        weighted_ghg_units='co2e_mmt'

        ghg_elec_col = self.col_name_to_weighted(self.GHG_ELEC_EGRID, weighted_ghg_units)
        ghg_gas_col = self.col_name_to_weighted(self.GHG_NATURAL_GAS, weighted_ghg_units)
        ghg_fuel_oil_col = self.col_name_to_weighted(self.GHG_FUEL_OIL, weighted_ghg_units)
        ghg_propane_col = self.col_name_to_weighted(self.GHG_PROPANE, weighted_ghg_units)

        col_renames = {
            'Commercial Share of Electric Power Sector CO2 Emissions (Million Metric Tons of Carbon Dioxide)': ghg_elec_col,
            'Natural Gas, Excluding Supplemental Gaseous Fuels, Commercial Sector CO2 Emissions (Million Metric Tons of Carbon Dioxide)': ghg_gas_col,
            'Distillate Fuel Oil Commercial Sector CO2 Emissions (Million Metric Tons of Carbon Dioxide)': ghg_fuel_oil_col,
            'Petroleum, Excluding Biofuels, Commercial Sector CO2 Emissions (Million Metric Tons of Carbon Dioxide)': ghg_propane_col,
        }
        eia_emissions = eia_emissions.rename(col_renames)

        # Downselect to the fuels represented in ComStock
        self.emissions_cols = list(col_renames.values())
        eia_emissions = eia_emissions.select(self.emissions_cols)

        # Add a dataset column
        eia_emissions = eia_emissions.with_columns([pl.lit(self.dataset_name).alias(self.DATASET)])

        # Assign data to an attribute
        self.emissions_data = eia_emissions