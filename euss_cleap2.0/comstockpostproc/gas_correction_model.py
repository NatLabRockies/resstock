# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.

import logging
import numpy as np
import polars as pl
import pandas as pd

from comstockpostproc.cbecs import CBECS

logger = logging.getLogger(__name__)


class GasCorrectionModelMixin():
    # Corrects annual ComStock natural gas consumption results to match CBECS

    def correct_comstock_gas_to_match_cbecs(self, cbecs: CBECS):
        # Corrects annual ComStock natural gas consumption results to match CBECS.
        #
        # Correction is done by summing CBECS and ComStock each by building type
        # and census division, then computing the ratio and applying that
        # ratio to ComStock natural gas end uses.

        self.data = self.data.to_pandas()  # TODO POLARS rewrite

        ### Add gas interior equipment to buildings with other gas usage ###

        # Add gas interior equipment to buildings with any other gas usage, weighted by EFLH
        for btype in ['LargeOffice', 'MediumOffice', 'SmallOffice', 'RetailStandalone', 'Warehouse']:

            # Find census divisions with no gas usage for interior equipment
            df_gb = self.data.loc[self.data[self.BLDG_TYPE] == btype, :].groupby(self.CEN_DIV)[self.ANN_GAS_INTEQUIP_KBTU].sum()
            cdivs = df_gb.loc[df_gb == 0].index.tolist()

            mask = (self.data[self.ANN_TOT_GAS_KBTU] > 0) & (self.data[self.BLDG_TYPE] == btype) & (self.data[self.CEN_DIV].isin(cdivs))

            # Put in a small placeholder value for each building
            # The value is proportional to this building's share of both floor area
            # and interior equipment full load hours
            intequip_col = self.ANN_GAS_INTEQUIP_KBTU
            wtd_intequip_col = self.col_name_to_weighted(intequip_col, self.weighted_energy_units)
            intequip_cols = [intequip_col, wtd_intequip_col]

            # weight by area
            self.data.loc[mask, intequip_cols] = (
                1 * self.data.loc[mask, self.FLR_AREA]) / (
                self.data.loc[mask, self.FLR_AREA].sum(axis=0))

            # weight by EFLH
            self.data.loc[mask, intequip_cols] = (
            (self.data.loc[mask, self.ANN_GAS_INTEQUIP_KBTU]) * (
                self.data.loc[mask, 'out.params.interior_electric_equipment_eflh..hr'])) / (
                self.data.loc[mask, 'out.params.interior_electric_equipment_eflh..hr'].sum(axis=0))

        ### Add gas service water heating to buildings with other gas usage ###

        # Add gas service water heating to buildings with any other gas usage, weighted by EFLH
        for btype in ['RetailStandalone', 'Warehouse']:

            # Find census divisions with no gas usage for SWH
            df_gb = self.data.loc[self.data[self.BLDG_TYPE] == btype, :].groupby(self.CEN_DIV)[self.ANN_GAS_SWH_KBTU].sum()
            cdivs = df_gb.loc[df_gb == 0].index.tolist()

            mask = (self.data[self.ANN_TOT_GAS_KBTU] > 0) & (self.data[self.BLDG_TYPE] == btype) & (self.data[self.CEN_DIV].isin(cdivs))

            # Put in a small placeholder value for each building
            # The value is proportional to this building's share of both floor area
            # and occupant full load hours
            swh_col = self.ANN_GAS_SWH_KBTU
            wtd_swh_col = self.col_name_to_weighted(swh_col, self.weighted_energy_units)
            swh_cols = [swh_col, wtd_swh_col]

            # weight by area
            self.data.loc[mask, swh_cols] = (
                1 * self.data.loc[mask, self.FLR_AREA]) / (
                self.data.loc[mask, self.FLR_AREA].sum(axis=0))

            # weight by EFLH
            self.data.loc[mask, swh_cols] = (
                (self.data.loc[mask, self.ANN_GAS_SWH_KBTU]) * (
                    self.data.loc[mask, 'out.params.occupant_eflh..hr'])) / (
                    self.data.loc[mask, 'out.params.occupant_eflh..hr'].sum(axis=0))

        ### Lists of gas consumption columns, common to ComStock and CBECS ###

        gas_tot_col = self.ANN_TOT_GAS_KBTU
        gas_enduse_cols = self.COLS_GAS_ENDUSE
        gas_cols = [gas_tot_col] + gas_enduse_cols

        wtd_gas_tot_col = self.col_name_to_weighted(gas_tot_col, self.weighted_energy_units)
        wtd_gas_enduse_cols = [self.col_name_to_weighted(c, self.weighted_energy_units) for c in gas_enduse_cols]
        wtd_gas_cols = [wtd_gas_tot_col] + wtd_gas_enduse_cols

        ### Sum ComStock natural gas consumption by building type and census division ###

        self.data[self.CEN_DIV] = self.data[self.CEN_DIV].astype(str)
        self.data[self.BLDG_TYPE] = self.data[self.BLDG_TYPE].astype(str)
        df_cstock_gb = self.data.groupby([self.BLDG_TYPE, self.CEN_DIV])[wtd_gas_cols].sum()

        # determine enduse vs.total correction factor
        df_cstock_gb['sum_of_enduse'] = df_cstock_gb.loc[:, wtd_gas_enduse_cols].sum(axis=1)
        df_cstock_gb['tot_to_eu_frac'] = round((df_cstock_gb[wtd_gas_tot_col] / df_cstock_gb['sum_of_enduse']), 3)
        # logger.debug('ComStock gas totals')
        # logger.debug(df_cstock_gb)

        # remove uneeded columns
        df_cstock_gb.drop(labels = ['sum_of_enduse', 'tot_to_eu_frac'], axis=1, inplace=True)

        ### Sum CBECS natural gas consumption by building type and census division ###

        # create grouped df of values, weighted
        df_cbecs_gb = cbecs.data.groupby([self.BLDG_TYPE, self.CEN_DIV])[wtd_gas_cols].sum()

        # determine enduse vs.total correction factor
        df_cbecs_gb.loc[:, 'sum_of_enduse'] = df_cbecs_gb.loc[:, wtd_gas_enduse_cols].sum(axis=1)
        df_cbecs_gb.loc[:, 'tot_to_eu_frac'] = round((df_cbecs_gb[wtd_gas_tot_col] / df_cbecs_gb['sum_of_enduse']), 3)

        logger.info('CBECS before correction')
        logger.info(df_cbecs_gb)

        # correct end use columns to match total column
        df_cbecs_gb.loc[:, wtd_gas_enduse_cols] = df_cbecs_gb.loc[:, wtd_gas_enduse_cols].multiply(df_cbecs_gb['tot_to_eu_frac'], axis='index')

        # evaluate success of correction factor
        df_cbecs_gb.loc[:, 'sum_of_enduse'] = df_cbecs_gb.loc[:, wtd_gas_enduse_cols].sum(axis=1)
        df_cbecs_gb.loc[:, 'tot_to_eu_frac'] = round((df_cbecs_gb[wtd_gas_tot_col] / df_cbecs_gb['sum_of_enduse']), 3)

        logger.info('CBECS after correction')
        logger.info(df_cbecs_gb)

        # remove uneeded columns
        df_cbecs_gb.drop(labels = ['sum_of_enduse', 'tot_to_eu_frac'], axis=1, inplace=True)

        ### Create ComStock to CBECS scaling factors for each end use by building type and census division ###

        # divide CBECS totals by ComStock totals to create scaling factors
        df_scale_factors = df_cbecs_gb.divide(df_cstock_gb)
        df_scale_factors.replace([np.inf, -np.inf], 0, inplace=True)

        # rename columns for readable printing
        # df_scale_factors.columns = ['Total', 'Heating', 'SWH', 'Interior Equip', 'Cool']
        # logger.debug('ComStock to CBECS scaling factors by building type, census div, and end use')
        # logger.debug(df_scale_factors)

        ### Apply scaling factors to each building type and census division combination ###
        for meta, df_meta in df_scale_factors.groupby(level=[0,1]):
            btype = meta[0]
            cdiv = meta[1]
            btype_cdiv_scale_factors = df_meta.values
            # logger.debug(f'ComStock to CBECS scaling factors for {btype} in {cdiv}:')
            # logger.debug(btype_cdiv_scale_factors)

            # Correct weighted and unweighted gas end use columns
            mask = (self.data[self.BLDG_TYPE] == btype) & (self.data[self.CEN_DIV] == cdiv)
            # logger.debug('before correction')
            # logger.debug(self.data.loc[mask, wtd_gas_cols].sum())

            # self.data.loc[mask, gas_cols] *= btype_cdiv_scale_factors
            # self.data.loc[mask, wtd_gas_cols] *= btype_cdiv_scale_factors

            self.data.loc[mask, gas_cols] *= btype_cdiv_scale_factors
            self.data.loc[mask, wtd_gas_cols] *= btype_cdiv_scale_factors

            # logger.debug('after correction')
            # logger.debug(self.data.loc[mask, cstock_wtd_gas_cols].sum())

        # Sum weighted and unweighted end use columns to recalculate site total natural gas
        self.data.loc[:, gas_tot_col] = self.data.loc[:, gas_enduse_cols].sum(axis=1)
        self.data.loc[:, wtd_gas_tot_col] = self.data.loc[:, wtd_gas_enduse_cols].sum(axis=1)

        # Sum weighted and unweighted fuels (with corrected natural gas) to recalculate site total energy
        fuel_tot_cols = [
            self.ANN_TOT_ELEC_KBTU,
            self.ANN_TOT_GAS_KBTU,
            self.ANN_TOT_OTHFUEL_KBTU,
            self.ANN_TOT_DISTCLG_KBTU,
            self.ANN_TOT_DISTHTG_KBTU,
        ]
        wtd_fuel_tot_cols = [self.col_name_to_weighted(c, self.weighted_energy_units) for c in fuel_tot_cols]
        self.data.loc[:, self.ANN_TOT_ENGY_KBTU] = self.data.loc[:, fuel_tot_cols].sum(axis=1)
        wtd_energy_tot_col = self.col_name_to_weighted(self.ANN_TOT_ENGY_KBTU, self.weighted_energy_units)
        self.data.loc[:, wtd_energy_tot_col] = self.data.loc[:, wtd_fuel_tot_cols].sum(axis=1)

        # Recalculate total site energy intensity and gas end use intensity columns
        euis_cols_to_update = [self.ANN_TOT_ENGY_KBTU] + gas_cols
        for engy_col in euis_cols_to_update:
            eui_col = self.col_name_to_eui(engy_col)
            # Divide energy by area to create intensity
            self.data[eui_col] = self.data[engy_col] / self.data[self.FLR_AREA]

        self.data = pl.from_pandas(self.data)  # TODO POLARS remove after rewrite
