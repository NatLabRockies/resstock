import pandas as pd
import numpy as np

def er_heating_cost(df):
    option = df.columns[df.isin(['HVAC Heating Efficiency|Electric Boiler, 100% AFUE']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_hvac_usd'] = c_boiler + c_wiring

    option = df.columns[df.isin(['HVAC Heating Efficiency|Electric Furnace, 100% AFUE']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        temp_cost = c_furnace + c_furnace_v * df['upgrade_costs.size_heating_system_primary_k_btu_h']+ c_wiring 
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_hvac_usd'] = temp_cost
        
    option = df.columns[df.isin(['HVAC Heating Efficiency|Electric Wall Furnace, 100% AFUE']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        temp_cost = c_furnace + c_furnace_v * df['upgrade_costs.size_heating_system_primary_k_btu_h']+ c_wiring
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_hvac_usd'] = temp_cost

    option = df.columns[df.isin(['HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Electricity']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        temp_cost = c_shared_v * df['upgrade_costs.size_heating_system_primary_k_btu_h']+ c_wiring_shared
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_hvac_usd'] = temp_cost
        
    option = df.columns[df.isin(['HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Electricity']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        temp_cost = c_shared_v * df['upgrade_costs.size_heating_system_primary_k_btu_h']+ c_wiring_shared
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_hvac_usd'] = temp_cost     
    return df

def hp_heating_cost_adjustment(df):
    df['hp_cost_adjustment'] = 0
    df['upgrade_costs.size_heat_pump_backup_primary_10kwh'] = df['upgrade_costs.size_heat_pump_backup_primary_k_btu_h']/34.1214
    df['num_10kw_hpbkup'] = df['upgrade_costs.size_heat_pump_backup_primary_10kwh'].apply(np.ceil)
    for i, row in df.iterrows():
        ##### HVAC Has Ducts
        if row['build_existing_model.hvac_has_ducts'] == 'Yes':
            #### CAC
            if row['build_existing_model.hvac_cooling_type'] == 'Central AC':
                ### ducted heating
                if row['build_existing_model.hvac_heating_type'] in (['Ducted Heating', 'Ducted Heat Pump']):
                    ## electric heating
                    if row['build_existing_model.heating_fuel'] == 'Electricity':
                        if row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] <= 34.1214:
                            df.at[i, 'hp_cost_adjustment'] = -c_wiring*2
                        elif row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] > 34.1214:
                            df.at[i, 'hp_cost_adjustment'] = -c_wiring*2 + c_wiring*(row['num_10kw_hpbkup']-1)
                    ## non-electric heating 
                    else:
                        if row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] <= 34.1214:
                            df.at[i, 'hp_cost_adjustment'] = -c_wiring
                        elif row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] > 34.1214:
                            df.at[i, 'hp_cost_adjustment'] = -c_wiring + c_wiring*(row['num_10kw_hpbkup']-1)
                ### non-ducted heating or no heating
                else:
                    if row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] <= 34.1214:
                        df.at[i, 'hp_cost_adjustment'] = -c_wiring*2
                    elif row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] > 34.1214:
                        df.at[i, 'hp_cost_adjustment'] = -c_wiring*2 + c_wiring*(row['num_10kw_hpbkup']-1)
            #### Non CAC
            else:
                ### ducted heating
                if row['build_existing_model.hvac_heating_type'] in (['Ducted Heating', 'Ducted Heat Pump']):
                    ## electric heating
                    if row['build_existing_model.heating_fuel'] == 'Electricity':
                        if row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] <= 34.1214:
                            df.at[i, 'hp_cost_adjustment'] = -c_wiring
                        elif row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] > 34.1214:
                            df.at[i, 'hp_cost_adjustment'] = -c_wiring + c_wiring*(row['num_10kw_hpbkup']-1)
                    ## non-electric heating 
                    else:
                        if row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] > 34.1214:
                            df.at[i, 'hp_cost_adjustment'] = c_wiring*(row['num_10kw_hpbkup']-1)
        ##### HVAC Don't Have Ducts
        else:
            ## electric heating
            if row['build_existing_model.heating_fuel'] == 'Electricity' and row['build_existing_model.hvac_heating_efficiency'] != 'Shared Heating':
                if row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] > 34.1214:
                    df.at[i, 'hp_cost_adjustment'] = c_wiring*(row['num_10kw_hpbkup']-1)
            ## non-electric heating 
            else:
                if 0 < row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] <= 34.1214:
                    df.at[i, 'hp_cost_adjustment'] = c_wiring
                elif row['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] > 34.1214:
                    df.at[i, 'hp_cost_adjustment'] = c_wiring + c_wiring*(row['num_10kw_hpbkup']-1)
    return df
    
def hp_heating_existing_backup_cost_adjustment(df):
    df['hp_cost_adjustment'] = 0
    for i, row in df.iterrows():
        if row['build_existing_model.hvac_has_ducts'] == 'Yes':
            if row['build_existing_model.hvac_cooling_type'] == 'Central AC':
                df.at[i, 'hp_cost_adjustment'] = -c_wiring*2
            else:
                df.at[i, 'hp_cost_adjustment'] = -c_wiring
    return df
    
def hp_heating_cost_calculation(df, option_num, c, c_v):
    temp_cost =\
    c + df['hp_cost_adjustment'] + c_v * df['upgrade_costs.size_heating_system_primary_k_btu_h']+ df['heat_pump_backup_cost_usd']
    df.loc[~pd.isnull(df[f'{option_num}_name']), f'{option_num}_cost_usd'] = temp_cost
    df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_hvac_usd'] = temp_cost
    return df

def hp_heating_cost(df):
    # heat pump backup cost
    df['heat_pump_backup_cost_usd'] = 0
    df.loc[(df['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] <= 34.1214) & (df['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] > 0), 'heat_pump_backup_cost_usd'] = hp_backup_less_10kw
    df.loc[df['upgrade_costs.size_heat_pump_backup_primary_k_btu_h'] > 34.1214, 'heat_pump_backup_cost_usd'] = hp_backup_more_10kw

    # add wiring cost
    df = hp_heating_cost_adjustment(df)
    
    option = df.columns[df.isin(['HVAC Heating Efficiency|ASHP, SEER 15.05, 8.82 HSPF, HERS, Supplemental Backup Sizing']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        c = c_ashp15
        c_v = c_ashp15_v
        df = hp_heating_cost_calculation(df, option_num, c, c_v)

    option = df.columns[df.isin(['HVAC Heating Efficiency|MSHP, SEER 14.5, 8.33 HSPF, HERS, Supplemental Backup Sizing']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        c = c_mshp14
        c_v = c_mshp14_v
        df = hp_heating_cost_calculation(df, option_num, c, c_v)

    option = df.columns[df.isin(['HVAC Heating Efficiency|ASHP, SEER 20, 11 HSPF, CCHP, Max Load, Supplemental Backup Sizing']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        c = c_ashp20 
        c_v = c_ashp20_v
        df = hp_heating_cost_calculation(df, option_num, c, c_v)
        
    option = df.columns[df.isin(['HVAC Heating Efficiency|MSHP, SEER 20, 11 HSPF, CCHP, Max Load, Supplemental Backup Sizing']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        c = c_mshp20 
        c_v = c_mshp20_v
        df = hp_heating_cost_calculation(df, option_num, c, c_v)

    return df

def hp_heating_existing_backup_cost(df):
    df['heat_pump_backup_cost_usd'] = 0
    # add wiring cost
    df = hp_heating_existing_backup_cost_adjustment(df)
    
    ashp_list = ['HVAC Heating Efficiency|ASHP, SEER 15.05, 8.82 HSPF, Separate Backup, HERS, Emergency Backup Sizing',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 60% AFUE NG, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 76% AFUE NG, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 80% AFUE NG, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 92.5% AFUE NG, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 60% AFUE Fuel Oil, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 76% AFUE Fuel Oil, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 80% AFUE Fuel Oil, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 92.5% AFUE Fuel Oil, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 60% AFUE Propane, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 76% AFUE Propane, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 80% AFUE Propane, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 92.5% AFUE Propane, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 60% AFUE Other Fuel, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 76% AFUE Other Fuel, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 80% AFUE Other Fuel, 0F-40F switchover band',
                'HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15.05, 8.82 HSPF, Integrated Backup, HERS, Emergency Backup Sizing, 92.5% AFUE Other Fuel, 0F-40F switchover band',
                'HVAC Heating Efficiency|ASHP, SEER 15.05, 8.82 HSPF, HERS, Emergency Backup Sizing']
    
    for hp in ashp_list:
        option = df.columns[df.isin([hp]).any()]
        if len(option) != 0:
            option_num = option[0][:-5]
            c = c_ashp15
            c_v = c_ashp15_v
            df = hp_heating_cost_calculation(df, option_num, c, c_v)
            
    option = df.columns[df.isin(['HVAC Heating Efficiency|MSHP, SEER 14.5, 8.33 HSPF, Separate Backup, HERS, Emergency Backup Sizing']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        c = c_mshp14
        c_v = c_mshp14_v
        df = hp_heating_cost_calculation(df, option_num, c, c_v)
        
    return df

def water_heating_cost(df):
    option = df.columns[df.isin(['Water Heater Efficiency|Electric Premium']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        temp_cost = c_water_p + c_water_p_v * df['upgrade_costs.size_water_heater_gal'] + c_wiring 
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_water_heater_usd'] = temp_cost
        
    option = df.columns[df.isin(['Water Heater Efficiency|Electric Standard']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        temp_cost = c_water_s + c_water_s_v * df['upgrade_costs.size_water_heater_gal'] + c_wiring 
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_water_heater_usd'] = temp_cost
        
    option = df.columns[df.isin(['Water Heater Efficiency|Electric Tankless']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        temp_cost = c_water_tankless + c_wiring
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_water_heater_usd'] = temp_cost

    option = df.columns[df.isin(['Water Heater Efficiency|Electric Heat Pump, 50 gal, 3.45 UEF']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        df.loc[(~pd.isnull(df[f'{option_num}_name'])) & (df['build_existing_model.water_heater_fuel'] == 'Electricity'), 'upgrade_cost_water_heater_usd'] = c_hpwh50 - c_wiring
        df.loc[(~pd.isnull(df[f'{option_num}_name'])) & (df['build_existing_model.water_heater_fuel'] != 'Electricity'), 'upgrade_cost_water_heater_usd'] = c_hpwh50
    if len(option) == 2:
        option_num = option[1][:-5]
        df.loc[(~pd.isnull(df[f'{option_num}_name'])) & (df['build_existing_model.water_heater_fuel'] == 'Electricity'), 'upgrade_cost_water_heater_usd'] = c_hpwh50 - c_wiring
        df.loc[(~pd.isnull(df[f'{option_num}_name'])) & (df['build_existing_model.water_heater_fuel'] != 'Electricity'), 'upgrade_cost_water_heater_usd'] = c_hpwh50

    option = df.columns[df.isin(['Water Heater Efficiency|Electric Heat Pump, 66 gal, 3.35 UEF']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        df.loc[(~pd.isnull(df[f'{option_num}_name'])) & (df['build_existing_model.water_heater_fuel'] == 'Electricity'), 'upgrade_cost_water_heater_usd'] = c_hpwh66 - c_wiring 
        df.loc[(~pd.isnull(df[f'{option_num}_name'])) & (df['build_existing_model.water_heater_fuel'] != 'Electricity'), 'upgrade_cost_water_heater_usd'] = c_hpwh66 
    if len(option) == 2:
        option_num = option[1][:-5]
        df.loc[(~pd.isnull(df[f'{option_num}_name'])) & (df['build_existing_model.water_heater_fuel'] == 'Electricity'), 'upgrade_cost_water_heater_usd'] = c_hpwh66 - c_wiring
        df.loc[(~pd.isnull(df[f'{option_num}_name'])) & (df['build_existing_model.water_heater_fuel'] != 'Electricity'), 'upgrade_cost_water_heater_usd'] = c_hpwh66 
    
    option = df.columns[df.isin(['Water Heater Efficiency|Electric Heat Pump, 80 gal, 3.45 UEF']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        df.loc[(~pd.isnull(df[f'{option_num}_name'])) & (df['build_existing_model.water_heater_fuel'] == 'Electricity'), 'upgrade_cost_water_heater_usd'] = c_hpwh80 - c_wiring 
        df.loc[(~pd.isnull(df[f'{option_num}_name'])) & (df['build_existing_model.water_heater_fuel'] != 'Electricity'), 'upgrade_cost_water_heater_usd'] = c_hpwh80
    if len(option) == 2:
        option_num = option[1][:-5]
        df.loc[(~pd.isnull(df[f'{option_num}_name'])) & (df['build_existing_model.water_heater_fuel'] == 'Electricity'), 'upgrade_cost_water_heater_usd'] = c_hpwh80 - c_wiring
        df.loc[(~pd.isnull(df[f'{option_num}_name'])) & (df['build_existing_model.water_heater_fuel'] != 'Electricity'), 'upgrade_cost_water_heater_usd'] = c_hpwh80

    option = df.columns[df.isin(['Water Heater Efficiency|Electric Heat Pump, 50 gal, 120 V Shared']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_water_heater_usd'] = c_hpwh_lp50
        df.loc[~pd.isnull(df[f'{option_num}_name']), f'{option_num}_lifetime_yrs'] = 13

    option = df.columns[df.isin(['Water Heater Efficiency|Electric Heat Pump, 65 gal, 120 V Shared']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_water_heater_usd'] = c_hpwh_lp65
        df.loc[~pd.isnull(df[f'{option_num}_name']), f'{option_num}_lifetime_yrs'] = 13

    option = df.columns[df.isin(['Water Heater Efficiency|Electric Heat Pump, 80 gal, 120 V Shared']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_water_heater_usd'] = c_hpwh_lp80
        df.loc[~pd.isnull(df[f'{option_num}_name']), f'{option_num}_lifetime_yrs'] = 13
        
    return df

def cooking_dryer(df):
    option = df.columns[df.isin(['Cooking Range|Electric Resistance']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_cooking_usd'] = c_cooking + c_wiring

    option = df.columns[df.isin(['Clothes Dryer|Electric']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_dryer_usd'] = c_dryer + c_wiring

    option = df.columns[df.isin(['Cooking Range|Electric Induction, 120V, battery powered']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_cooking_usd'] = c_cooking_lp

    option = df.columns[df.isin(['Clothes Dryer|Electric Heat Pump, 120V']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_dryer_usd'] = c_dryer_lp
        
    return df

def pool_spa(df):
    option = df.columns[df.isin(['Misc Pool Heater|Electricity']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_pool_heater_usd'] = c_pool + c_wiring
        
    option = df.columns[df.isin(['Misc Hot Tub Spa|Electricity']).any()]
    if len(option) != 0:
        option_num = option[0][:-5]
        df.loc[~pd.isnull(df[f'{option_num}_name']), 'upgrade_cost_hot_tub_spa_usd'] = c_spa + c_wiring
        
    return df

def add_total_envelop_uprade_cost(df):
    colNames = []
    env_name = ['Insulation Ceiling|R-30',
           'Insulation Ceiling|R-49',
           'Insulation Ceiling|R-60',
           'Infiltration Reduction|30%',
           'Duct Leakage and Insulation|10% Leakage to Outside, R-8',
           'Duct Leakage and Insulation|10% Leakage to Outside, R-6',
           'Insulation Wall|Wood Stud, R-13']
    for env in env_name:
        options = df.columns[df.isin([env]).any()]
        if len(options) != 0:
            for i in range(len(options)):
                temp = options[i][:-5]
                temp = temp+'_cost_usd'
                colNames.append(temp)
    df['upgrade_cost_envelope_usd']= df[colNames].sum(axis=1)
    return df
    
def total_cost_multiplier(df, df_cost_mutiplier):
    colNames = df.columns[df.columns.str.contains(pat = 'upgrade_costs.option_') & df.columns.str.contains(pat = '_cost_usd')] 
    df['upgrade_costs.upgrade_cost_usd']= df[colNames].sum(axis=1)
    cost_mutipliers = []
    for state in df['build_existing_model.state']:
        row = df_cost_mutiplier.loc[df_cost_mutiplier['state'] == state]
        cost_mutiplier = row['location_factor']
        cost_mutipliers.append(cost_mutiplier.values[0])
    df['cost_mutipliers'] = cost_mutipliers
    df['upgrade_costs.upgrade_cost_usd']= df['upgrade_costs.upgrade_cost_usd'] * df['cost_mutipliers']

    # update cost for individual options
    df_filter= df.filter(like='upgrade_costs.option_').columns
    df_filter = df_filter.to_list()
    cost_columns = [s for s in df_filter if "_cost_usd" in s]
    for col in cost_columns:
        df[f'{col}'] = df[f'{col}'] * df['cost_mutipliers']

    cost_columns = ['upgrade_cost_hvac_usd',
                    'upgrade_cost_water_heater_usd',
                    'upgrade_cost_cooking_usd',
                    'upgrade_cost_dryer_usd',
                    'upgrade_cost_pool_heater_usd',
                    'upgrade_cost_hot_tub_spa_usd',
                    'upgrade_cost_envelope_usd']
    for col in cost_columns:
        df[f'{col}'] = df[f'{col}'] * df['cost_mutipliers']
    
        
    return df  

def drop_columns(df):
    df = df.drop(columns=['build_existing_model.state',
                          'build_existing_model.heating_fuel',
                          'build_existing_model.water_heater_fuel',
                          'build_existing_model.hvac_cooling_type',
                          'build_existing_model.hvac_has_ducts',
                         'build_existing_model.hvac_heating_type',
                          'build_existing_model.hvac_heating_efficiency',
                         'cost_mutipliers'])
    return df


def cost_update_validation(df):
    colNames = ['upgrade_cost_hvac_usd',
                'upgrade_cost_water_heater_usd',
                'upgrade_cost_cooking_usd',
                'upgrade_cost_dryer_usd',
                'upgrade_cost_pool_heater_usd',
                'upgrade_cost_hot_tub_spa_usd',
                'upgrade_cost_envelope_usd']
    df['upgrade_costs.upgrade_cost_usd_validation']= df[colNames].sum(axis=1)
    df['validation'] = (df['upgrade_costs.upgrade_cost_usd'] - df['upgrade_costs.upgrade_cost_usd_validation'])/df['upgrade_costs.upgrade_cost_usd']
    if (df['validation'] > 0.001).any():
        print('!!! Cost Validation Error'+df['apply_upgrade.upgrade_name'].unique())
    elif (df['validation'] < -0.001).any():
        print('!!! Cost Validation Error'+df['apply_upgrade.upgrade_name'].unique())
    else:
        print('Cost Validation Pass '+df['apply_upgrade.upgrade_name'].unique())

## Main Code
# inputs
c_wiring = 1384
c_wiring_shared = 1384
c_boiler = 3844
c_furnace = 1984
c_furnace_v = 350
c_shared_v = 85.42
c_ashp15 = 9989.73
c_ashp15_v = 133.16
c_mshp14 = 1474
c_mshp14_v = 391.26
c_ashp20 = 14405.68
c_ashp20_v = 133.16
c_mshp20 = 2797.4
c_mshp20_v = 391.26
c_water_p = 1078.8
c_water_p_v = 2.36
c_water_s = 1016.8
c_water_s_v = 4.34
c_water_tankless = 2039.91
c_hpwh50 = 4966
c_hpwh66 = 5366
c_hpwh80 = 6080
c_hpwh_lp50 = 3582
c_hpwh_lp65 = 3982
c_hpwh_lp80 = 4696
c_cooking = 1214.94
c_cooking_lp = 5450
c_dryer = 990
c_dryer_lp = 1611
hp_backup_less_10kw = 300
hp_backup_more_10kw = 500
c_pool = 1997.11
c_spa = 1997.11

file_path = 'full_run'
file_cost_mutiplier = 'data_/rsmeans_locationfactors_statemean_2023.csv'

# add cost multiplier into baseline model
df0 = pd.read_csv(f'{file_path}/data_cleaning_results_up00.csv', low_memory=False)
df_cost_mutiplier = pd.read_csv(file_cost_mutiplier)

cost_mutipliers = []
for state in df0['build_existing_model.state']:
    row = df_cost_mutiplier.loc[df_cost_mutiplier['state'] == state]
    cost_mutiplier = row['location_factor']
    cost_mutipliers.append(cost_mutiplier.values[0])
df0['build_existing_model.cost_mutipliers'] = cost_mutipliers
df0.to_parquet(f'{file_path}/cost_updated_results_up00.parquet', index=False)

# cost update
up_list_er = ['01']
up_list_hp = ['02','03','04','05','06','07','09','10','11','12','13','14',
              '16', '17', '18', '19']
up_list_hp_existing_backup = ['08','15']
up_list_all = up_list_er+up_list_hp+up_list_hp_existing_backup

df_existing_model = df0[['building_id',
                         'build_existing_model.state',
                         'build_existing_model.heating_fuel',
                         'build_existing_model.water_heater_fuel',
                         'build_existing_model.hvac_cooling_type',
                        'build_existing_model.hvac_has_ducts',
                         'build_existing_model.hvac_heating_type',
                        'build_existing_model.hvac_heating_efficiency']] 

# upgrades electric resistance heating
for up in up_list_er:
    df = pd.read_csv(f'{file_path}/data_cleaning_results_up{up}.csv', low_memory=False)
    df = pd.merge(df_existing_model, df, on='building_id')
    df = er_heating_cost(df)
    df = water_heating_cost(df)
    df = cooking_dryer(df)
    df = pool_spa(df)
    df = add_total_envelop_uprade_cost(df)
    df = total_cost_multiplier(df, df_cost_mutiplier)
    #df = drop_columns(df)
    df.to_parquet(f'{file_path}/cost_updated_results_up{up}.parquet', index=False)
    
# upgrades including heat pump heating
for up in up_list_hp:
    df = pd.read_csv(f'{file_path}/data_cleaning_results_up{up}.csv', low_memory=False)
    df = pd.merge(df_existing_model, df, on='building_id')
    df = hp_heating_cost(df)
    df = water_heating_cost(df)
    df = cooking_dryer(df)
    df = pool_spa(df)
    df = add_total_envelop_uprade_cost(df)
    df = total_cost_multiplier(df, df_cost_mutiplier)
    #df = drop_columns(df)
    df.to_parquet(f'{file_path}/cost_updated_results_up{up}.parquet', index=False)
    
# upgrades including heat pump heating with existing fuel as backup
for up in up_list_hp_existing_backup:
    df = pd.read_csv(f'{file_path}/data_cleaning_results_up{up}.csv', low_memory=False)
    df = pd.merge(df_existing_model, df, on='building_id')
    df = hp_heating_existing_backup_cost(df)
    df = water_heating_cost(df)
    df = cooking_dryer(df)
    df = pool_spa(df)
    df = add_total_envelop_uprade_cost(df)
    df = total_cost_multiplier(df, df_cost_mutiplier)
    #df = drop_columns(df)
    df.to_parquet(f'{file_path}/cost_updated_results_up{up}.parquet', index=False)

# upgrade cost validation
for up in up_list_all:
    df = pd.read_parquet(f'{file_path}/cost_updated_results_up{up}.parquet')
    cost_update_validation(df)