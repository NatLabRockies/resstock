# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.

"""
# Commercial AMI comparisons.
- - - - - - - - -
A class to run AMI data comparisons.
This class queries ComStock results and Load data from Athena and creates graphics for calibration. \
The methods in this class produce the following graphics.

- Compare stacked area end use for 3 seasons (summer, shoulder, winter), 2 day types (weekday, weekend), and (normalized, unnormalized)
- Load duration curves by building type
- Typical weekly load profile comparisons if the ComStock run is from the same weather year

**Authors:**

- Matthew Dahlhausen (Matthew.Dahlhausen@nrel.gov)
"""

# Import Modules
import os

import boto3
import botocore
import logging
import numpy as np
import pandas as pd
import polars as pl

from scipy import stats
from comstockpostproc.naming_mixin import NamingMixin
from comstockpostproc.units_mixin import UnitsMixin
from comstockpostproc.s3_utilities_mixin import S3UtilitiesMixin

# Create logger for AWS queries
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AMI(NamingMixin, UnitsMixin, S3UtilitiesMixin):
    def __init__(self, truth_data_version, color_hex=NamingMixin.COLOR_AMI, reload_from_csv=False):
        """
        A class to produce calibration graphics based on utility AMI data from the EULP project.
        Args:
            truth_data_version (string): The version of the AMI truth data. Example: 'v01'.
            year (int): The year to perform the comparison
        """

        # Initialize members
        self.truth_data_version = truth_data_version
        self.dataset_name = f'AMI {self.truth_data_version}'
        current_dir = os.path.dirname(os.path.abspath(__file__))
        self.truth_data_dir = os.path.join(current_dir, '..', 'truth_data', self.truth_data_version)
        self.output_dir = os.path.join(current_dir, '..', 'output', self.dataset_name)
        self.ami_timeseries_data = None
        self.color = color_hex
        # run map to list qoi months and county ids in each region
        # 1 is Fort Collins, Colorado
        # 2a is Seattle, Washington
        # 2b is Portland, Oregon
        # 3a is Portland, Maine
        # 3b is VEIC, Vermont
        # 3c is Cherryland, Michigan
        # 4a is Pepco (Maryland)
        # 4b is EPB (Tennessee)
        # 4c is Tallahassee, Florida
        # 4d is Horry, South Carolina
        self.ami_region_map = [
            {'region': 'region1', 'source_name': 'fort_collins', 'year': 2016,
            'filter_method': '3xmedian', 'county_ids': ['G0800690'],
            'summer_months': [6, 7, 8], 'shoulder_months': [5, 9, 10], 'winter_months': [1, 2, 3, 4, 11, 12]},
            {'region': 'region2a', 'source_name': 'seattle', 'year': 2019,
            'filter_method': '3xmedian', 'county_ids': ['G5300330'],
            'summer_months': [], 'shoulder_months': [4, 5, 6, 7, 8, 9], 'winter_months': [1, 2, 3, 10, 11, 12]},
            {'region': 'region2b', 'source_name': 'pge', 'year': 2019,
            'filter_method': '3xmedian', 'county_ids': ['G4100510'],
            'summer_months': [8], 'shoulder_months': [4, 5, 6, 7, 9, 10], 'winter_months': [1, 2, 3, 11, 12]},
            {'region': 'region3a', 'source_name': 'maine', 'year': 2018,
            'filter_method': '3xmedian', 'county_ids': ['G2300050'],
            'summer_months': [7, 8], 'shoulder_months': [5, 6, 9], 'winter_months': [1, 2, 3, 4, 10, 11, 12]},
            {'region': 'region3b', 'source_name': 'veic', 'year': 2018,
            'filter_method': '3xmedian',
            'county_ids': ['G5000010', 'G5000030', 'G5000070', 'G5000170', 'G5000210', 'G5000230', 'G5000250', 'G5000270'],
            'summer_months': [7, 8], 'shoulder_months': [5, 6, 9], 'winter_months': [1, 2, 3, 4, 10, 11, 12]},
            {'region': 'region3c', 'source_name': 'cherryland', 'year': 2019,
            'filter_method': '3xmedian',
            'county_ids': ['G2600190', 'G2600550', 'G2600790', 'G2600890', 'G2601010', 'G2601650'],
            'summer_months': [7], 'shoulder_months': [6, 8, 9], 'winter_months': [1, 2, 3, 4, 5, 10, 11, 12]},
            {'region': 'region4a', 'source_name': 'pepco', 'year':2019,
            'filter_method': '3xmedian',
            'county_ids': ['G1100010', 'G2400330'],
            'summer_months': [6, 7, 8, 9], 'shoulder_months': [4, 5, 10], 'winter_months': [1, 2, 3, 11, 12]},
            {'region': 'region4b', 'source_name': 'epb', 'year':2019,
            'filter_method': '3xmedian',
            'county_ids': ['G4700650'],
            'summer_months': [5, 6, 7, 8, 9], 'shoulder_months': [4, 10], 'winter_months': [1, 2, 3, 11, 12]},
            {'region': 'region4c', 'source_name': 'tallahassee', 'year':2019,
            'filter_method': '3xmedian',
            'county_ids': ['G1200730'],
            'summer_months': [5, 6, 7, 8, 9, 10], 'shoulder_months': [2, 3, 4, 11, 12], 'winter_months': [1]},
            {'region': 'region4d', 'source_name': 'horry', 'year':2019,
            'filter_method': '3xmedian',
            'county_ids': ['G4500510'],
            'summer_months': [5, 6, 7, 8, 9, 10], 'shoulder_months': [3, 4], 'winter_months': [1, 2, 11, 12]}
            ]
        self.building_types = [
            'full_service_restaurant',
            'hospital',
            'large_hotel',
            'large_office',
            'medium_office',
            'outpatient',
            'primary_school',
            'quick_service_restaurant',
            'retail',
            'secondary_school',
            'small_hotel',
            'small_office',
            'strip_mall',
            'warehouse'
            ]

        # Initialize s3 client
        self.s3_client = boto3.client('s3', config=botocore.client.Config(max_pool_connections=50))

        # Make directories
        for p in [self.truth_data_dir, self.output_dir]:
            if not os.path.exists(p):
                os.makedirs(p)

        # Load and transform data, preserving all columns
        logger.info(f'Downloading {self.dataset_name}')
        self.download_truth_data()
        if reload_from_csv:
            file_name = f'AMI long.csv'
            file_path = os.path.join(self.output_dir, file_name)
            if not os.path.exists(file_path):
                 raise FileNotFoundError(
                    f'Cannot find {file_path} to reload data, set reload_from_csv=False to create CSV.')
            logger.info(f'Reloading from CSV: {file_path}')
            self.ami_timeseries_data = pd.read_csv(file_path, low_memory=False, index_col='timestamp', parse_dates=True)
        else:
            self.calculate_ami_aggregates()

    def download_truth_data(self):
        # AMI data
        for region_hash in self.ami_region_map:
            region_source_name = region_hash['source_name']
            lookup_name = str(region_hash['year']) + '_' + region_source_name + '_' + region_hash['filter_method']
            for building_type in self.building_types:
                file_name = lookup_name + '_' + building_type + '_kwh_per_sqft.csv'
                file_path = os.path.join(self.truth_data_dir, file_name)
                if not os.path.exists(file_path):
                    s3_file_path = f'truth_data/{self.truth_data_version}/AMI/{file_name}'
                    if self.isfile_on_S3('eulp', s3_file_path):
                        self.read_delimited_truth_data_file_from_S3(s3_file_path, ',')
                    else:
                        logger.warning(f'Missing data for building type {building_type} in region {region_source_name}.')
                        continue

    def calculate_ami_aggregates(self):
        all_ami_df = pd.DataFrame()
        # load AMI data
        for region_hash in self.ami_region_map:
            region_source_name = region_hash['source_name']
            region_year = str(region_hash['year'])
            region_filter_method = region_hash['filter_method']
            lookup_name = region_year + '_' + region_source_name + '_' + region_filter_method
            ami_name = 'ami_' + lookup_name
            ami_raw_df = pd.DataFrame()
            for building_type in self.building_types:
                file_name = lookup_name + '_' + building_type + '_kwh_per_sqft.csv'
                file_path = os.path.join(self.truth_data_dir, file_name)
                if not os.path.isfile(file_path):
                    logger.warning(f'ami data for ' + file_name + ' does not exist.')
                    continue

                df = pd.read_csv(file_path, parse_dates=['timestamp'], index_col='timestamp')
                df['building_type'] = building_type

                # remove instances where the count of buildings in the timeseries is less than 30% of the max count
                max_count = df['bldg_count'].max()
                count_threshold = 0.3 * max_count
                df = df[df['bldg_count'] > count_threshold]
                ami_raw_df = pd.concat([ami_raw_df,df])

            if ami_raw_df.empty:
                logger.warning(f'no ami data for ' + region_source_name)
                continue

            # restrict to target year
            target_year = region_hash['year']
            ami_raw_df = ami_raw_df[ami_raw_df.index.year == target_year]
            ami_raw_df = ami_raw_df[ami_raw_df.index.dayofyear != 366]
            ami_raw_df['region_name'] = region_source_name
            ami_raw_df['year'] = region_year

            # compare against mean by square foot
            ami_raw_df['kwh_per_sf'] = ami_raw_df['mean_by_sqft']

            # drop other data
            ami_raw_df = ami_raw_df[['kwh_per_sf', 'total_sqft', 'std_by_count', 'bldg_count', 'building_type', 'region_name', 'year']]

            def calc_lci(row, confidence_interval):
                ci = stats.t.interval(confidence_interval, row['bldg_count'] - 1, row['kwh_per_sf'], row['std_by_count'] / (row['bldg_count']**0.5))
                return ci[0]

            def calc_uci(row, confidence_interval):
                ci = stats.t.interval(confidence_interval, row['bldg_count'] - 1, row['kwh_per_sf'], row['std_by_count'] / (row['bldg_count']**0.5))
                return ci[1]

            # calculate total kwh
            temp_df = pd.DataFrame()
            total_sf = 0.0
            for building_type in self.building_types:
                temp_sf = ami_raw_df[ami_raw_df['building_type'] == building_type]['total_sqft'].max()
                total_sf = total_sf + temp_sf
                type_df = ami_raw_df[ami_raw_df['building_type'] == building_type].copy()
                if len(type_df['kwh_per_sf']) < 6000:
                    continue
                type_df['kwh'] = type_df['kwh_per_sf'] * temp_sf
                type_df['lci_80'] = type_df.apply(lambda row: max(0, calc_lci(row, 0.8)), axis=1).values
                type_df['uci_80'] = type_df.apply(lambda row: calc_uci(row, 0.8), axis=1).values
                # type_df['sample_uncertainty'] = (type_df['std_by_count'] / (type_df['bldg_count']**0.5)) / type_df['kwh_per_sf']
                type_df['sample_uncertainty'] = (type_df['uci_80'] / type_df['kwh_per_sf']) - 1
                temp_df = pd.concat([temp_df, type_df])
            ami_df = temp_df

            # calculate the total
            df = ami_df.groupby(['timestamp', 'region_name', 'year']).sum().reset_index().set_index('timestamp')
            df = df.drop(['kwh_per_sf'], axis=1)
            df['kwh_per_sf'] = df['kwh'] / total_sf
            df['lci_80'] = df.apply(lambda row: calc_lci(row, 0.8), axis=1).values
            df['uci_80'] = df.apply(lambda row: calc_uci(row, 0.8), axis=1).values
            ### sum std_by_count is divided by total number of buildings to weight them, canceling the sqrt
            # df['sample_uncertainty'] = (df['std_by_count'] / df['bldg_count']) / df['kwh_per_sf']
            df['sample_uncertainty'] = (df['uci_80'] / df['kwh_per_sf']) -1
            df['building_type'] = 'total'

            # save out total aggregated
            # data_path = os.path.join('data', 'aggregated_dataset', ami_name + '_agg.csv')
            # df.to_csv(data_path, index=True)

            # add the total data to the AMI
            ami_df = pd.concat([ami_df, df])

            # drop other data
            ami_df = ami_df[['kwh_per_sf', 'bldg_count', 'building_type', 'region_name', 'year', 'sample_uncertainty']]

            # save out long data format
            logger.info(f'Adding data for region {region_source_name}.')
            # data_path = os.path.join(self.output_dir, ami_name + '_agg_long.csv')
            # ami_df.to_csv(data_path, index=True)
            all_ami_df = pd.concat([all_ami_df, ami_df])
        
        data_path = os.path.join(self.output_dir, 'AMI long.csv')
        all_ami_df.to_csv(data_path, index=True)
        self.ami_timeseries_data = all_ami_df
        return all_ami_df