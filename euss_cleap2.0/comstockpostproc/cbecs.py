# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.
import os

import boto3
import botocore
import logging
import numpy as np
import pandas as pd

from comstockpostproc.naming_mixin import NamingMixin
from comstockpostproc.units_mixin import UnitsMixin
from comstockpostproc.s3_utilities_mixin import S3UtilitiesMixin

logger = logging.getLogger(__name__)


class CBECS(NamingMixin, UnitsMixin, S3UtilitiesMixin):
    def __init__(self, cbecs_year, truth_data_version, color_hex=NamingMixin.COLOR_CBECS_2012, weighted_energy_units='tbtu', reload_from_csv=False):
        """
        A class to load and transform CBECS data for export, analysis, and comparison.
        Args:

            cbecs_year (int): The year of CBECS data to retrieve. Currently 2012 and 2018 are available.
            truth_data_version (str): The version/location to retrieve truth/starting data. Truth data
            may change for certain data sources over time, although unlikely for CBECS.
        """

        # Initialize members
        self.year = cbecs_year
        self.truth_data_version = truth_data_version
        self.dataset_name = f'CBECS {self.year}'
        current_dir = os.path.dirname(os.path.abspath(__file__))
        self.truth_data_dir = os.path.join(current_dir, '..', 'truth_data', self.truth_data_version)
        self.resource_dir = os.path.join(current_dir, 'resources')
        self.output_dir = os.path.join(current_dir, '..', 'output', self.dataset_name)
        self.data_file_name = f'CBECS_{self.year}_microdata.csv'
        self.data_codebook_file_name = f'CBECS_{self.year}_microdata_codebook.csv'
        self.building_type_mapping_file_name = f'CBECS_{self.year}_to_comstock_nems_aeo_building_types.csv'
        self.data = None
        self.color = color_hex
        self.weighted_energy_units = weighted_energy_units
        self.s3_client = boto3.client('s3', config=botocore.client.Config(max_pool_connections=50))
        logger.info(f'Creating {self.dataset_name}')

        # Make directories
        for p in [self.truth_data_dir, self.output_dir]:
            if not os.path.exists(p):
                os.makedirs(p)

        # Load and transform data, preserving all columns
        self.download_data()
        if reload_from_csv:
            file_name = f'CBECS wide.csv'
            file_path = os.path.join(self.output_dir, file_name)
            if not os.path.exists(file_path):
                 raise FileNotFoundError(
                    f'Cannot find {file_path} to reload data, set reload_from_csv=False to create CSV.')
            logger.info(f'Reloading from CSV: {file_path}')
            self.data = pd.read_csv(file_path, low_memory=False)
        else:
            self.load_data()
            self.rename_columns_and_convert_units()
            self.set_column_data_types()
            self.add_dataset_column()
            self.add_comstock_building_type_column()
            self.add_vintage_column()
            self.add_energy_intensity_columns()
            self.add_bill_intensity_columns()
            self.add_energy_rate_columns()
            # Calculate weighted area and energy consumption columns
            self.add_weighted_area_and_energy_columns()

        logger.debug('\nCBECS columns after adding all data')
        for c in self.data.columns:
            logger.debug(c)

    def download_data(self):
        # CBECS microdata
        file_name = f'CBECS_{self.year}_microdata.csv'
        file_path = os.path.join(self.truth_data_dir, file_name)
        if not os.path.exists(file_path):
            s3_file_path = f'truth_data/{self.truth_data_version}/EIA/CBECS/{file_name}'
            self.read_delimited_truth_data_file_from_S3(s3_file_path, ',')

        # CBECS microdata codebook
        file_name = f'CBECS_{self.year}_microdata_codebook.csv'
        file_path = os.path.join(self.truth_data_dir, file_name)
        if not os.path.exists(file_path):
            s3_file_path = f'truth_data/{self.truth_data_version}/EIA/CBECS/{file_name}'
            self.read_delimited_truth_data_file_from_S3(s3_file_path, ',')

        # state region division table
        file_name = f'state_region_division_table.csv'
        file_path = os.path.join(self.truth_data_dir, file_name)
        if not os.path.exists(file_path):
            s3_file_path = f'truth_data/{self.truth_data_version}/EIA/CBECS/{file_name}'
            self.read_delimited_truth_data_file_from_S3(s3_file_path, ',')
    

    def load_data(self):
        # Load raw microdata and codebook and decode numeric keys to strings using codebook

        # Load microdata
        file_path = os.path.join(self.truth_data_dir, self.data_file_name)
        self.data = pd.read_csv(file_path, low_memory=False, na_values=['.'])

        # Load microdata codebook
        file_path = os.path.join(self.truth_data_dir, self.data_codebook_file_name)
        codebook = pd.read_csv(file_path, index_col='File order', low_memory=False)
        # Make a dict of column names (e.g. PBA) to labels (e.g. Principal building activity)
        # and a dict of numeric enumerations to strings for non-numeric variables
        var_name_to_label = {}
        var_label_to_enums = {}
        for file_order, row in codebook.iterrows():
            var_name = row['Variable name'].strip()
            var_type = row['Variable type'].strip()
            var_label = row['Label'].strip()
            var_vals = row['Values/Format codes']
            # logger.debug('')
            # logger.debug('*'*20)
            # logger.debug(var_name)
            # logger.debug(var_label)
            # logger.debug(var_type)
            # logger.debug(var_vals)

            # Check if this label was already used by CBECS for another column
            if var_label in list(var_name_to_label.values()):
                logger.debug(f'CBECS used the label "{var_label}" for multiple columns')
                logger.debug(f'    - now: {var_name}')
                for nm, lbl in var_name_to_label.items():
                    if lbl == var_label:
                        logger.debug(f'    - prev: {nm}')
                # If reused, append the column name to the label to differentiate
                var_label = f'{var_label} {var_name}'
                logger.debug(f'    Relabeling "{var_name}" to: "{var_label}"')

            # Add the name to label mapping
            var_name_to_label[var_name] = var_label

            # For non-numeric fields, parse the value/format codes into a dict
            enum_to_value = {}
            if not pd.isna(var_vals) and '=' in var_vals:
                for v in var_vals.split('|'):
                    if '=' in v:
                        n, val = v.split('=')
                        enum_to_value[n] = val.strip()
            if len(enum_to_value) > 0:
                var_label_to_enums[var_label] = enum_to_value

        # Rename the columns
        self.data.rename(columns=var_name_to_label, inplace=True)

        # Double-check for duplicate columns; there should be none
        for col, dup in zip(self.data.columns, self.data.columns.duplicated()):
            if dup:
                logger.warning(f'Dropped column with duplicate label: {col}')
                self.data.drop(col, axis=1, inplace=True)

        # Decode the column values
        def decode_variable(val, decoder_map):
            # logger.debug('***')
            # logger.debug(f'DECODING {val}')
            # logger.debug(f'with {decoder_map}')
            if pd.isna(val):  # NaN = 'Missing' in decoder map
                val = 'Missing'
            if val in decoder_map.keys():
                return decoder_map[val]
            elif str(int(val)) in decoder_map.keys():
                return decoder_map[str(int(val))]
            else:
                return val

        for col_name in list(self.data):
            # logger.debug(col_name)
            if col_name in var_label_to_enums.keys():
                decoder_map = var_label_to_enums[col_name]
                # logger.debug(f'Decoding {col_name}')
                # logger.debug('  value map:')
                # logger.debug(f'  {decoder_map}')
                self.data[col_name] = self.data[col_name].apply(lambda key: decode_variable(key, decoder_map))

    def rename_columns_and_convert_units(self):
        column_map = {
            # Building characteristics
            'Building identifier': self.BLDG_ID,  # CBECS 2012
            'Public use file building identifier': self.BLDG_ID,  # CBECS 2018
            'Census region': self.CEN_REG,
            'Census division': self.CEN_DIV,
            'Square footage': self.FLR_AREA,
            'Square footage category': self.FLR_AREA_CAT,
            'More specific building activity': self.CBECS_BLDG_TYPE,
            'Year of construction': self.YEAR_BUILT,
            'Final full sample building weight': self.BLDG_WEIGHT,  # CBECS 2012
            'Nonresponse Adjusted Weight': self.BLDG_WEIGHT,  # CBECS 2018
            'Annual major fuel consumption (thous Btu)': self.ANN_TOT_ENGY_KBTU,
            'Annual electricity consumption (thous Btu)': self.ANN_TOT_ELEC_KBTU,
            'Annual natural gas consumption (thous Btu)': self.ANN_TOT_GAS_KBTU,
            'Annual fuel oil consumption (thous Btu)': self.ANN_TOT_OTHFUEL_KBTU,
            'Annual district heat consumption (thous Btu)': self.ANN_TOT_DISTHTG_KBTU,
            # End use energy - electricity
            'Electricity heating use (thous Btu)': self.ANN_ELEC_HEAT_KBTU,
            'Electricity cooling use (thous Btu)': self.ANN_ELEC_COOL_KBTU,
            'Electricity ventilation use (thous Btu)': self.ANN_ELEC_FANS_KBTU,
            'Electricity water heating use (thous Btu)': self.ANN_ELEC_SWH_KBTU,
            'Electricity lighting use (thous Btu)': self.ANN_ELEC_INTLTG_KBTU,
            'Electricity refrigeration use (thous Btu)': self.ANN_ELEC_REFRIG_KBTU,
            # End use energy - natural gas
            'Natural gas heating use (thous Btu)': self.ANN_GAS_HEAT_KBTU,
            'Natural gas cooling use (thous Btu)': self.ANN_GAS_COOL_KBTU,
            'Natural gas water heating use (thous Btu)': self.ANN_GAS_SWH_KBTU,
            # End use energy - district heating
            'District heat heating use (thous Btu)': self.ANN_DISTHTG_HEAT_KBTU,
            'District heat cooling use (thous Btu)': self.ANN_DISTHTG_COOL_KBTU,
            'District heat water heating use (thous Btu)': self.ANN_DISTHTG_SWH_KBTU,
            # End use energy - other fuels (sum of propane and fuel oil)
            'Fuel oil heating use (thous Btu)': self.ANN_OTHER_HEAT_KBTU,
            'Fuel oil cooling use (thous Btu)': self.ANN_OTHER_COOL_KBTU,
            'Fuel oil water heating use (thous Btu)': self.ANN_OTHER_SWH_KBTU,
            # Utility bills
            'Annual electricity expenditures ($)': self.UTIL_BILL_ELEC,
            'Annual natural gas expenditures ($)': self.UTIL_BILL_GAS,
            'Annual fuel oil expenditures ($)': self.UTIL_BILL_FUEL_OIL
        }
        self.data.rename(columns=column_map, inplace=True)

        # Combine some CBECS columns to match ComStock
        combo_cols = [
            # End use energy - electricity interior equipment
            [['Electricity cooking use (thous Btu)',
            'Electricity office equipment use (thous Btu)',
            'Electricity computing use (thous Btu)',
            'Electricity miscellaneous use (thous Btu)'], self.ANN_ELEC_INTEQUIP_KBTU],
            # End use energy - natural gas interior equipment
            [['Natural gas cooking use (thous Btu)',
            'Natural gas miscellaneous use (thous Btu)'], self.ANN_GAS_INTEQUIP_KBTU],
            # End use energy - district heating interior equipment
            [['District heat cooking use (thous Btu)',
            'District heat miscellaneous use (thous Btu)'], self.ANN_DISTHTG_INTEQUIP_KBTU],
            # End use energy - fuel oil interior equipment
            [['Fuel oil cooking use (thous Btu)',
            'Fuel oil miscellaneous use (thous Btu)'], self.ANN_OTHER_INTEQUIP_KBTU]
        ]
        for cols, new_col_name in combo_cols:
            found_cols = []
            for col in cols:
                if not col in self.data:
                    logger.warning(f'Missing energy column {col}, will not be included in {new_col_name}')
                    continue
                self.data[col] = self.data[col].replace('Not Applicable', np.nan)
                self.data[col] = self.data[col].replace('Not applicable', np.nan)
                self.data[col] = self.data[col].astype('float64')
                found_cols.append(col)
            new_col_dict = {}
            new_col_dict[new_col_name] = self.data[found_cols].sum(axis=1)
            self.data = pd.concat([self.data, pd.DataFrame(new_col_dict)],axis=1)

        # Convert all energy columns from base CBECS kBtu to kWh
        for col in (self.COLS_TOT_ANN_ENGY + self.COLS_ENDUSE_ANN_ENGY):
            # Skip end-use columns that aren't part of CBECS
            if not col in self.data:
                continue
            # Ensure the energy column is numeric then create weighted column
            self.data[col] = self.data[col].replace('Not Applicable', np.nan)
            self.data[col] = self.data[col].replace('Not applicable', np.nan)
            self.data[col] = self.data[col].astype('float64')
            new_col = self.col_name_to_weighted(col, self.weighted_energy_units)

            # Convert to match units in updated column name
            base_cbecs_units = 'kbtu'
            target_units = self.units_from_col_name(col)
            conv_fact = self.conv_fact(base_cbecs_units, target_units)
            self.data[col] = self.data[col] * conv_fact

    def set_column_data_types(self):
        # TODO generalize this on CBECS loading?
        for col in self.COLS_TOT_ANN_ENGY:
            if col in self.data:
                self.data[col] = self.data[col].replace('Not Applicable', np.nan)
                self.data[col] = self.data[col].astype('float64')

    def add_dataset_column(self):
        self.data[self.DATASET] = self.dataset_name

    def add_energy_intensity_columns(self):
        # Create EUI column for each annual energy column
        for engy_col in (self.COLS_TOT_ANN_ENGY + self.COLS_ENDUSE_ANN_ENGY):
            # Put in np.nan for end-use columns that aren't part of CBECS
            if not engy_col in self.data:
                self.data[engy_col] = np.nan
            # Divide energy by area to create intensity
            eui_col = self.col_name_to_eui(engy_col)
            self.data[engy_col] = self.data[engy_col].replace('Not Applicable', np.nan)
            self.data[engy_col] = self.data[engy_col].astype('float64')
            self.data[eui_col] = self.data[engy_col] / self.data[self.FLR_AREA]

    def add_bill_intensity_columns(self):
        # Create bill per area column for each annual utility bill column
        for bill_col in self.COLS_UTIL_BILLS:
            # Put in np.nan for bill columns that aren't part of CBECS
            if not bill_col in self.data:
                self.data[bill_col] = np.nan
            # Divide bill by area to create intensity
            per_area_col = self.col_name_to_area_intensity(bill_col)
            self.data[bill_col] = self.data[bill_col].replace('Not applicable', np.nan)
            self.data[bill_col] = self.data[bill_col].astype('float64')
            self.data[per_area_col] = self.data[bill_col] / self.data[self.FLR_AREA]

    def add_energy_rate_columns(self):
        # Create energy rate column for each annual utility bill column
        for bill_col in self.COLS_UTIL_BILLS:
            # Get the corresponding energy consumption column
            bill_to_engy_col = {
                self.UTIL_BILL_ELEC: self.ANN_TOT_ELEC_KBTU,
                self.UTIL_BILL_GAS: self.ANN_TOT_GAS_KBTU,
                self.UTIL_BILL_FUEL_OIL: None,
                self.UTIL_BILL_PROPANE: None
            }
            # Only create rate columns for fuels with bills
            engy_col = bill_to_engy_col[bill_col]
            if not engy_col:
                continue
            # Divide bill by consumption to create rate
            rate_col = self.col_name_to_energy_rate(bill_col)
            self.data[bill_col] = self.data[bill_col].replace('Not applicable', np.nan)
            self.data[bill_col] = self.data[bill_col].astype('float64')
            self.data[rate_col] = self.data[bill_col] / self.data[engy_col]

    def add_comstock_building_type_column(self):
        # Add the ComStock building type for each row of CBECS

        # Load the building type mapping file
        file_path = os.path.join(self.resource_dir, self.building_type_mapping_file_name)
        bldg_type_map = pd.read_csv(file_path, index_col='CBECS More specific building activity')
        bldg_type_map.head()

        def cbecs_to_comstock_bldg_type(row, bldg_type_map):
            # Get the CBECS properties
            cbecs_bldg_type = row[self.CBECS_BLDG_TYPE]
            sqft = row[self.FLR_AREA]
            nfloor = row['Number of floors']
            # Recode CBECS 2012 enumerations
            if nfloor == '15 to 25':
                nfloor = 15
            elif nfloor == 'More than 25':
                nfloor = 26
            # Recode CBECS 2018 enumerations
            elif nfloor == '10 to 14':
                nfloor = 10
            elif nfloor == '15 or more':
                nfloor = 15

            # Look up the intermediate comstock building type
            cstock_bldg_type = bldg_type_map['ComStock Intermediate Building Type'].loc[cbecs_bldg_type]

            # Assign size category to offices
            if cstock_bldg_type == 'Office':
                if sqft < 25_000:
                    if nfloor <=3:
                        cstock_bldg_type = 'SmallOffice'
                    else:
                        cstock_bldg_type = 'MediumOffice'
                elif sqft >= 25_000 and sqft < 150_000:
                    if nfloor <= 5:
                        cstock_bldg_type = 'MediumOffice'
                    else:
                        cstock_bldg_type = 'LargeOffice'
                elif sqft >= 150_000:
                    cstock_bldg_type = 'LargeOffice'
                else:
                    err_msg = f"Should never get here, check logic for {row}"
                    logger.error(err_msg)
                    raise Exception(err_msg)
                assert cstock_bldg_type != 'Office'  # Offices must be assigned a size

            return cstock_bldg_type

        self.data[self.BLDG_TYPE] = self.data.apply(lambda row: cbecs_to_comstock_bldg_type(row, bldg_type_map), axis=1)

    def add_aeo_nems_building_type_column(self):
        # Add the AEO and NEMS building type for each row of CBECS

        # Load the building type mapping file
        file_path = os.path.join(self.resource_dir, self.building_type_mapping_file_name)
        bldg_type_map = pd.read_csv(file_path, index_col='CBECS More specific building activity')
        bldg_type_map.head()

        def cbecs_to_aeo_bldg_type(row, bldg_type_map):
            # Get the CBECS properties
            cbecs_bldg_type = row[self.CBECS_BLDG_TYPE]
            sqft = row[self.FLR_AREA]

            # Look up the intermediate comstock building type
            aeo_bldg_type = bldg_type_map['NEMS and AEO Intermediate Building Type'].loc[cbecs_bldg_type]

            # Assign size category to offices
            if aeo_bldg_type == 'Office':
                if sqft <= 50_000:
                    aeo_bldg_type = 'Office - Small'
                else:
                    aeo_bldg_type = 'Office - Large'
                assert aeo_bldg_type != 'office'  # Offices must be assigned a size

            return aeo_bldg_type

        self.data[self.AEO_BLDG_TYPE] = self.data.apply(lambda row: cbecs_to_aeo_bldg_type(row, bldg_type_map), axis=1)

    def add_vintage_column(self):
        # Adds decadal vintage bins used in CBECS 2018

        if self.YEAR_BUILT in self.data.columns:
            def vintage_bin_from_year(year):
                if year == 'Before 1946':
                    return 'Before 1946'
                year = int(year)
                if 1946 < year < 1960:
                    vint = '1946 to 1959'
                elif year < 1970:
                    vint = '1960 to 1969'
                elif year < 1980:
                    vint = '1970 to 1979'
                elif year < 1990:
                    vint = '1980 to 1989'
                elif year < 2000:
                    vint = '1990 to 1999'
                elif year < 2013:
                    vint = '2000 to 2012'
                elif year < 2019:
                    vint = '2013 to 2018'
                else:
                    vint = '2019 or newer'
                return vint

            self.data[self.VINTAGE] = self.data.apply(lambda row: vintage_bin_from_year(row[self.YEAR_BUILT]), axis=1)
        else:
            # Use the vintage bins already in CBECS
            self.data[self.VINTAGE] = self.data['Year of construction category']

    def add_weighted_area_and_energy_columns(self):
        # # Area
        # new_area_col = self.col_name_to_weighted(self.FLR_AREA)
        # self.data[new_area_col] = self.data[self.FLR_AREA] * self.data[self.BLDG_WEIGHT]

        # # Energy
        # for col in self.COLS_TOT_ANN_ENGY:
        #     new_col = self.col_name_to_weighted(col)
        #     self.data[new_col] = self.data[col] * self.data[self.BLDG_WEIGHT]

        # Area - ensure the column is numeric then create weighted column
        self.data[self.FLR_AREA] = self.data[self.FLR_AREA].replace('Not Applicable', np.nan)
        self.data[self.FLR_AREA] = self.data[self.FLR_AREA].astype('float64')
        new_area_col = self.col_name_to_weighted(self.FLR_AREA)
        self.data[new_area_col] = self.data[self.FLR_AREA] * self.data[self.BLDG_WEIGHT]

        # Energy
        new_col_dict = {}
        for col in (self.COLS_TOT_ANN_ENGY + self.COLS_ENDUSE_ANN_ENGY):
            # Skip end-use columns that aren't part of CBECS
            if not col in self.data:
                continue
            # Ensure the energy column is numeric then create weighted column
            self.data[col] = self.data[col].replace('Not Applicable', np.nan)
            self.data[col] = self.data[col].astype('float64')
            new_col = self.col_name_to_weighted(col, self.weighted_energy_units)

            # Weight and convert to TBtu
            old_units = self.units_from_col_name(col)
            new_units = self.weighted_energy_units
            conv_fact = self.conv_fact(old_units, new_units)
            new_col_dict[new_col] = self.data[col] * self.data[self.BLDG_WEIGHT] * conv_fact
        self.data = pd.concat([self.data, pd.DataFrame(new_col_dict)], axis=1)

    def export_to_csv_wide(self):
        # Exports comstock data to CSV in wide format

        file_name = f'CBECS wide.csv'
        file_path = os.path.join(self.output_dir, file_name)
        self.data.to_csv(file_path, index=False)
