
###import comstockpostproc-standard things, and then don't use most of them

import os
from textwrap import indent

import boto3
import logging
import numpy as np
import pandas as pd

from comstockpostproc.resstock_naming_mixin_LARGEE import ResStockNamingMixin
from comstockpostproc.units_mixin import UnitsMixin
from comstockpostproc.s3_utilities_mixin import S3UtilitiesMixin
from comstockpostproc import resstock_LARGEE

logger = logging.getLogger(__name__)

class ResStock_data_process():
    def __init__(self, resstock_results_folder, resstock_file_name, downselect_rows_tf, downselect_row_fields, 
                 values_to_keep,  col_plan_folder, col_plan_name,
                 add_wide_fields_tf, dfs_for_wide_fields, wide_mergeon_fields, wide_merge_cols, wide_col_plans, wide_merge_newnames,
                 add_local_bills_tf, downselect_cols_tf, add_long_fields_tf, rate_inputs_df, 
                 long_fields_also_wide_tf, long_fields_also_wide, long_fields_also_wide_names,
                 save_file_tf, output_folder, output_file_name, debug_tf):
        """
        A class to load and transform ResStock 2024.2 data for futher steps in an automated workflow
        """
        #initialize members
        self.resstock_results_folder = resstock_results_folder
        self.resstock_file_name = resstock_file_name
        self.downselect_rows_tf = downselect_rows_tf
        self.downselect_row_fields = downselect_row_fields
        self.values_to_keep = values_to_keep
        self.col_plan_folder = col_plan_folder
        self.col_plan_name = col_plan_name
        self.add_wide_fields_tf = add_wide_fields_tf
        self.dfs_for_wide_fields = dfs_for_wide_fields
        self.wide_mergeon_fields = wide_mergeon_fields
        self.wide_merge_cols = wide_merge_cols
        self.wide_col_plans = wide_col_plans
        self.wide_merge_newnames = wide_merge_newnames
        self.add_local_bills_tf = add_local_bills_tf
        self.downselect_cols_tf = downselect_cols_tf
        self.add_long_fields_tf = add_long_fields_tf
        self.rate_inputs_df = rate_inputs_df
        self.long_fields_also_wide_tf = long_fields_also_wide_tf
        self.long_fields_also_wide = long_fields_also_wide
        self.long_fields_also_wide_names = long_fields_also_wide_names
        self.save_file_tf = save_file_tf
        self.output_folder = output_folder
        self.output_file_name = output_file_name
        self.debug_tf = debug_tf

        #execute
        self.download_data()
        self.downselect_rows()
        self.make_col_plan()
        self.add_wide_fields()
        self.downselect_cols()
        self.pivot_data()
        self.add_long_fields()
        self.categorize_outputs()
        self.addl_wide_fields_in_long()
        self.add_weighted_values_col()
        self.return_and_save_file()

    def download_data(self):
    #load results from already-downloaded OEDI file
        if self.debug_tf == True:
            print (1)
        results_file_path = os.path.join(self.resstock_results_folder, self.resstock_file_name)
        self.data = pd.read_csv(results_file_path, engine = "pyarrow")

    def downselect_rows(self):
    #downselect to a subset of results 
        if self.debug_tf == True:
            print (2)
        if(self.downselect_rows_tf == True):
            for field, values in zip(self.downselect_row_fields, self.values_to_keep):
                self.data = self.data.loc[self.data[field].isin(values)]

    def make_col_plan(self):
    #assign a plan for each column in the dataset, from a premade csv
        if self.debug_tf == True:
            print (3)
        plan_file_path = os.path.join(self.col_plan_folder, self.col_plan_name)
        self.col_plan = pd.read_csv(plan_file_path, engine = "pyarrow")
        #flag columns in the data that aren't in the column plan
        data_cols = self.data.columns.tolist()
        cols_in_plan = self.col_plan['column'].tolist()
        cols_not_in_plan = list(set(data_cols) - set(cols_in_plan))
        if len(cols_not_in_plan) > 0:
            print ("These columns are in the data but not the column plan:") 
            print(cols_not_in_plan)
        #flag columns in the column plan that will need to be added to the data
        cols_not_in_data = list(set(cols_in_plan) - set(data_cols))
        if len(cols_not_in_data) > 0:
            print ("These columns are not in the data and will be added, with NaNs:")
            print (cols_not_in_data)
        #remake data in standard order and with cols of NAs so that all files have the same columns
        for col in cols_not_in_data:
            self.data[col] = np.nan
        self.data = self.data[cols_in_plan]
        #create lists of columns
        self.cols_to_remove = self.col_plan.loc[self.col_plan['plan']=='remove', 'column'].tolist()
        self.cols_wide = self.col_plan.loc[self.col_plan['plan']=='keep', 'column'].tolist()
        self.cols_to_pivot = self.col_plan.loc[self.col_plan['plan']=='pivot', 'column'].tolist()
        
    def add_wide_fields(self):
    #add additional wide format fields before pivoting, and also add plans for them
        if self.debug_tf == True:
            print (4)
        #add additional precomputed wide format fields before pivoting
        if(self.add_wide_fields_tf == True):
            if self.debug_tf == True:
                print ("4a")
            for dfw, wide_mergeon_field, wide_merge_col, wide_merge_newname, wide_col_plan in zip(
                self.dfs_for_wide_fields, self.wide_mergeon_fields, self.wide_merge_cols, self.wide_merge_newnames, self.wide_col_plans):
                self.data = self.data.merge(dfw, [[wide_mergeon_field, wide_merge_col]], on = wide_mergeon_field, how = "left")
                self.data.rename(columns = {wide_merge_col:wide_merge_newname}, inplace = True)
                if self.wide_col_plan == 'pivot':
                    self.cols_to_pivot = self.cols_to_pivot + [wide_merge_newname]
                elif self.wide_col_plan == 'keep':
                    self.cols_wide = self.cols_wide + [wide_merge_newname]
                else:
                    self.cols_to_remove = self.cols_to_remove + [wide_merge_newname]
        #add local bills before pivoting
        if(self.add_local_bills_tf == True):
            if self.debug_tf == True:
                print ("4b")
            for index, row in self.rate_inputs_df.iterrows():
                # for each row of rate inputs, create a column in the data, NaN if the scaling row doesn't exist (e.g savings rows in baseline)
                if (all(type(x) == float for x in self.data[row['col list for scaling']])):
                    self.data[row['column']] = row['fixed monthly cost']*12 + row['variable cost per kwh']*(self.data[row['col list for scaling']].sum(axis = 1))
                else:
                    self.data[row['column']] = np.nan
                if row['plan'] == 'pivot':
                    self.cols_to_pivot = self.cols_to_pivot + [row['column']]
                elif row['plan'] == 'keep':
                    self.cols_wide = self.cols_wide + [row['column']]
                else:
                    self.cols_to_remove = self.cols_to_remove + [row['column']]
            plan_for_new_cols_df = self.rate_inputs_df.drop(['fixed monthly cost', 'variable cost per kwh', 'col list for scaling'], axis = 1)
            self.col_plan = pd.concat([self.col_plan, plan_for_new_cols_df], axis = 0)
    
    def downselect_cols(self):
    #remove unneceessary columns
        if self.debug_tf == True:
            print (5)
        if(self.downselect_cols_tf == True):
            self.data.drop(self.data[self.cols_to_remove], axis = 1, inplace = True)
            #print(self.data.columns)

    def pivot_data(self):
    #make all the results long format, keep the characteristics wide
        if self.debug_tf == True:
            print (6)
        self.data_long = pd.melt(
            self.data,
            id_vars = self.cols_wide,
            var_name = "Output",
            value_name = "Value"
        )
    
    def add_long_fields(self):
    #this is where you add any long format fields.
        if self.debug_tf == True:
            print (7)
        if(self.add_long_fields_tf == True):
            if self.debug_tf == True:
                print (1)

    def categorize_outputs(self):
    #Develop output categorization
        if self.debug_tf == True:
            print (8)
        #use mappings to get the categorizations
        out_cats = self.col_plan.drop(self.col_plan[["col_type", "plan"]], axis = 1, inplace = False)
        self.data_long = self.data_long.merge(out_cats, left_on = 'Output', right_on = "column", how = 'left')

    def addl_wide_fields_in_long(self):
    #re-merge in any long fields that are also needed as wide fields
        if self.debug_tf == True:
            print (9)
        if(self.long_fields_also_wide_tf == True):
            merge_data_cols = ["bldg_id"] + self.long_fields_also_wide
            self.data_long = self.data_long.merge(self.data[merge_data_cols], on = "bldg_id", how = "left")
            for colname, newcolname in zip(self.long_fields_also_wide, self.long_fields_also_wide_names):
                self.data_long.rename(columns = {colname:newcolname}, inplace = True)

    def add_weighted_values_col(self):
    #add a column with the weighted value alongside the unweighted value column
        if self.debug_tf == True:
            print (10)
        self.data_long['Weighted Value'] = self.data_long['Value']*self.data_long['weight']

    def return_and_save_file(self):
    #save file
        if self.debug_tf == True:
            print (11)
        return self.data_long
        if self.save_file_tf == True:
            self.data_long.to_csv(os.path.join(self.output_folder, self.output_file_name))


####Prepare utility rates for C2C DV

##project-specific utility bills - inputs
#Electricity
#TODO: Fix the cost below to maatch community cost
fixed_elec_cost_monthly = 10.56
var_elec_cost_per_kwh = 0.17404 #cf 0.137/kwh

#Natural Gas
fixed_ng_cost_monthly = 16.25
var_ng_cost_per_ccf = 1.495

#Fuel Oil
var_fo_cost_per_gal = 2.851

#Propane
var_propane_cost_per_gal = 3.199

##project-specific utility bills - unit conversions
gal_fuel_oil_to_mbtu = 139/1000
gal_propane_to_mbtu = 91.6 / 1000
mbtu_to_kwh = 293.0710701722222
dol_per_ccf_to_dol_per_therm = 1/1.038 #$ per Ccf divided by 1.038 equals $ per therm https://www.eia.gov/tools/faqs/faq.php?id=45&t=8
therm_to_kwh = 29.307107017222222

var_ng_cost_per_kwh = var_ng_cost_per_ccf * (dol_per_ccf_to_dol_per_therm) * (1/therm_to_kwh)
var_fo_cost_per_kwh = var_fo_cost_per_gal * (1/gal_fuel_oil_to_mbtu) * (1/mbtu_to_kwh)
var_propane_cost_per_kwh = var_propane_cost_per_gal * (1/gal_propane_to_mbtu) * (1/mbtu_to_kwh)

#print(var_ng_cost_per_kwh) #0.011423113848862812, cf 0.0339307/kwh
#print(var_fo_cost_per_kwh) #0.06998572515142275, cf 0.0704125/kwh
#print(var_propane_cost_per_kwh) #0.11916420397790706. cf 0.101456/kWh

#assemble for input
rates_data_inputs = [
    ["out.bills_local.electricity.total.usd", fixed_elec_cost_monthly, var_elec_cost_per_kwh, ["out.electricity.total.energy_consumption.kwh"], 
     "out.x", "pivot", "Utility Bills", "Electricity", "Electricity Total", "Total"],
    ["out.bills_local.natural_gas.total.usd", fixed_ng_cost_monthly, var_ng_cost_per_kwh, ["out.natural_gas.total.energy_consumption.kwh"], 
     "out.x", "pivot", "Utility Bills", "Natural Gas", "Natural Gas Total", "Total"],
    ["out.bills_local.fuel_oil.total.usd", 0, var_fo_cost_per_kwh, ["out.fuel_oil.total.energy_consumption.kwh"], 
     "out.x", "pivot", "Utility Bills", "Fuel Oil", "Fuel Oil Total", "Total"],
    ["out.bills_local.propane.total.usd", 0, var_propane_cost_per_kwh, ["out.propane.total.energy_consumption.kwh"], 
     "out.x", "pivot", "Utility Bills", "Propane", "Total", "Total"],
    ["out.bills_local.all_fuels.total.usd", 0, 1, ["out.bills_local.electricity.total.usd", "out.bills_local.natural_gas.total.usd", "out.bills_local.fuel_oil.total.usd", "out.bills_local.propane.total.usd"], 
     "out.x", "pivot", "Utility Bill Totals", "Energy", "Total", "Total"],
    ["out.bills_local.electricity.total.usd.savings", 0, var_elec_cost_per_kwh, ["out.electricity.total.energy_consumption.kwh.savings"], 
     "out.x", "pivot", "Utility Bills", "Electricity", "Electricity Total", "Total"],
    ["out.bills_local.natural_gas.total.usd.savings", 0, var_ng_cost_per_kwh, ["out.natural_gas.total.energy_consumption.kwh.savings"], 
     "out.x", "pivot", "Utility Bill Savings", "Natural Gas", "Natural Gas Total", "Total"],
    ["out.bills_local.fuel_oil.total.usd.savings", 0, var_fo_cost_per_kwh, ["out.propane.total.energy_consumption.kwh"], 
     "out.x", "pivot", "Utility Bill Savings", "Fuel Oil", "Fuel Oil Total", "Total"],
    ["out.bills_local.propane.total.usd.savings", 0, var_propane_cost_per_kwh, ["out.propane.total.energy_consumption.kwh"], 
     "out.x", "pivot", "Utility Bill Savings", "Propane", "Propane Total", "Total"],
    ["out.bills_local.all_fuels.total.usd.savings", 0, 1, ["out.bills_local.electricity.total.usd.savings", "out.bills_local.natural_gas.total.usd.savings", "out.bills_local.fuel_oil.total.usd.savings", "out.bills_local.propane.total.usd.savings"], 
     "out.x", "pivot", "Utility Bills Savings Totals", "Energy", "Total", "Total"]
]

rate_inputs_df = pd.DataFrame(rates_data_inputs, columns = ['column', 'fixed monthly cost', 'variable cost per kwh', 'col list for scaling', 'col_type', 'plan', 'Result Type', 'Fuel', 'End Use', 'End Use Category'])

current_dir = os.path.dirname(os.path.abspath(__file__))
resstock_folder_path = os.path.join(current_dir, "data_", "final_results") #TODO: Might need to change this path depending on where the data is
column_plan_path = os.path.join(current_dir, "data_")

#output and save one set of data
ResStock_data_process(
    resstock_results_folder = resstock_folder_path,
    resstock_file_name = "brainerd_baseline_metadata_and_annual_results_downsampled_with_inflation_adj_income_and_energy_burden.csv", #TODO: Change here for interested community file. This is a bit manual still 
    downselect_rows_tf = False, #False because CLEAP data is already downsampled and/or resampled
    downselect_row_fields = None, #["in.county_name"], #TODO: Change here since we are not using county filter. One way to this is to filter the data rather by counties by resampling results 
    # values_to_keep = [["Montgomery County", "Bucks County", "Chester County", "Delaware County"]],
    values_to_keep = None, #[["Montgomery County", "Bucks County"]], #False because CLEAP data is already downsampled and/or resampled
    col_plan_folder = column_plan_path,
    col_plan_name = '2024-2 Col Plan CLEAP including Upgrades.csv', #TODO: Potentially need to go into this file to add/change some columns i have since I have a few new columns than what is listed by Elaina. Also rename the file
    add_wide_fields_tf = False,
    dfs_for_wide_fields = 'NA',
    wide_mergeon_fields = 'NA',
    wide_merge_cols = 'NA', 
    wide_col_plans = 'NA',
    wide_merge_newnames = 'NA',
    add_local_bills_tf = True,
    downselect_cols_tf = True, 
    add_long_fields_tf = False, 
    rate_inputs_df = rate_inputs_df, 
    long_fields_also_wide_tf = True,
    long_fields_also_wide = ["out.emissions.all_fuels.lrmer_mid_case_15.co2e_kg", "out.bills_local.all_fuels.total.usd"], 
    long_fields_also_wide_names = ["Emissions", "Utility Bills Total"],
    save_file_tf = True,
    output_folder = resstock_folder_path,
    output_file_name = "resstock_function_upgrades_test_1.csv",
    debug_tf = True
    )


# process multiple sets of data
#up_list = ["baseline", "upgrade02", "upgrade04", "upgrade07", "upgrade09", "upgrade12", "upgrade13", "upgrade16"]
up_list = ["baseline", "upgrade02"] # TODO: change here for list of interested upgrades
processed_data = []
for up in up_list:
    print (up)
    resstock_file_name = "brainerd_" + up + "_metadata_and_annual_results_downsampled_with_inflation_adj_income_and_energy_burden.csv" #TODO: Change this to resampled/downsampled file names 
    outname = "brainerd_" + up + "processed_results.csv"  #TODO: Change this to resampled/downsampled file names 
    results = ResStock_data_process(
        resstock_results_folder = resstock_folder_path,
        resstock_file_name = resstock_file_name,
        downselect_rows_tf = False, #False because CLEAP data is already downsampled and/or resampled
        downselect_row_fields = None, #["in.county_name"], #None because CLEAP data is already downsampled and/or resampled
        values_to_keep = None, #[["Montgomery County", "Bucks County", "Chester County", "Delaware County"]], #None because CLEAP data is already downsampled and/or resampled
        col_plan_folder = column_plan_path,
        col_plan_name = '2024-2 Col Plan CLEAP including Upgrades.csv',
        add_wide_fields_tf = False,
        dfs_for_wide_fields = 'NA',
        wide_mergeon_fields = 'NA',
        wide_merge_cols = 'NA', 
        wide_col_plans = 'NA',
        wide_merge_newnames = 'NA',
        add_local_bills_tf = True,
        downselect_cols_tf = True, 
        add_long_fields_tf = False, 
        rate_inputs_df = rate_inputs_df, 
        long_fields_also_wide_tf = True,
        long_fields_also_wide = ["out.emissions.all_fuels.lrmer_mid_case_15.co2e_kg", "out.bills_local.all_fuels.total.usd"], 
        long_fields_also_wide_names = ["Emissions", "Utility Bills Total"],
        save_file_tf = True,
        output_folder = resstock_folder_path, 
        output_file_name = outname, 
        debug_tf = False
        )
    processed_data = processed_data + [results.data_long]


# combine multiple sets of processed data into a single dataframe for saving
# EKP 2025-01-07 this has thrown a memory error every time I've tried to run it
processed_data_df = pd.concat(processed_data, axis = 0, copy = False)


#save multiple sets of processed data - this is still in progress
output_folder = resstock_folder_path
output_file_name = "CLEAP_Brainerd_data_with_upgrades.csv" #TODO: Change to approporiate name for community
output_path = os.path.join(output_folder, output_file_name)
#processed_data_df.to_csv(output_path)

#the below runs, but because the columns aren't exactly the same in every file, it isn't the way to do it
for dataset in processed_data:
    print(dataset.head())
    dataset.to_csv(output_path, mode = 'a')