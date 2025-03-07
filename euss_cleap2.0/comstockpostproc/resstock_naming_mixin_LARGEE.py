# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.
import re

class ResStockNamingMixin():
    # Column aliases for code readability
    # Add to this list for commonly-used columns
    DATASET = 'dataset'
    BLDG_ID = 'bldg_id'
    CEN_REG = 'in.census_region_name'
    CEN_DIV = 'in.census_division_name'
    FLR_AREA = 'in.sqft'
    FLR_AREA_CAT = 'in.floor_area_category'
    CBECS_BLDG_TYPE = 'in.cbecs_building_type'
    YEAR_BUILT = 'in.year_built'
    BLDG_WEIGHT = 'weight'
    BLDG_TYPE = 'in.comstock_building_type'
    AEO_BLDG_TYPE = 'in.aeo_and_nems_building_type'
    VINTAGE = 'in.vintage'
    CZ_ASHRAE = 'in.climate_zone_ashrae_2006'

    # Total annual energy
    ANN_TOT_ENGY_KBTU = 'out.site_energy.total.energy_consumption..kwh'#
    ANN_TOT_ELEC_KBTU = 'out.electricity.total.energy_consumption..kwh'#
    ANN_TOT_GAS_KBTU = 'out.natural_gas.total.energy_consumption..kwh' #
    ANN_TOT_FUELOIL_KBTU = 'out.fuel_oil.total.energy_consumption..kwh'#
    ANN_TOT_PROPANE_KBTU = 'out.propane.total.energy_consumption..kwh'#
    # ANN_TOT_WOOD_KBTU = 'out.wood.total.energy_consumption..kwh'

    # End use energy - electricity
    # ANN_ELEC_BATHFAN_KBTU = 'out.electricity.bath_fan.energy_consumption..kwh'
    ANN_ELEC_CEILFAN_KBTU = 'out.electricity.ceiling_fan.energy_consumption..kwh' #
    ANN_ELEC_CLOTHESDRYR_KBTU = 'out.electricity.clothes_dryer.energy_consumption..kwh'#
    ANN_ELEC_CLOTHESWSHR_KBTU = 'out.electricity.clothes_washer.energy_consumption..kwh'#
    ANN_ELEC_RANGE_KBTU = 'out.electricity.range_oven.energy_consumption..kwh'#
    ANN_ELEC_COOL_KBTU = 'out.electricity.cooling.energy_consumption..kwh' #
    ANN_ELEC_DISHWSHR_KBTU = 'out.electricity.dishwasher.energy_consumption..kwh' #
    # ANN_ELEC_HOLLTG_KBTU = 'out.electricity.ext_holiday_light.energy_consumption..kwh'
    ANN_ELEC_EXTLTG_KBTU = 'out.electricity.lighting_exterior.energy_consumption..kwh' #
    # ANN_ELEC_EXTRAREFRIG_KBTU = 'out.electricity.extra_refrigerator.energy_consumption..kwh'
    ANN_ELEC_FANSCOOL_KBTU = 'out.electricity.cooling_fans_pumps.energy_consumption..kwh'#
    ANN_ELEC_FANSHEAT_KBTU = 'out.electricity.heating_fans_pumps.energy_consumption..kwh' #
    ANN_ELEC_FREEZER_KBTU = 'out.electricity.freezer.energy_consumption..kwh' #
    ANN_ELEC_GARAGELTG_KBTU = 'out.electricity.lighting_garage.energy_consumption..kwh' #
    ANN_ELEC_HEAT_KBTU = 'out.electricity.heating.energy_consumption..kwh' #
    ANN_ELEC_HEATSUPPL_KBTU = 'out.electricity.heating_hp_bkup.energy_consumption..kwh' #
    ANN_ELEC_HOTTUBHEAT_KBTU = 'out.electricity.hot_tub_heater.energy_consumption..kwh'#
    ANN_ELEC_HOTTUBPUMP_KBTU = 'out.electricity.hot_tub_pump.energy_consumption..kwh'#
    ANN_ELEC_HOUSEFAN_KBTU = 'out.electricity.mech_vent.energy_consumption..kwh' #
    ANN_ELEC_INTLTG_KBTU = 'out.electricity.lighting_interior.energy_consumption..kwh' #
    ANN_ELEC_PLUGLOADS_KBTU = 'out.electricity.plug_loads.energy_consumption..kwh' #
    ANN_ELEC_POOLHEAT_KBTU = 'out.electricity.pool_heater.energy_consumption..kwh' #
    ANN_ELEC_POOLPUMP_KBTU = 'out.electricity.pool_pump.energy_consumption..kwh' #
    # ANN_ELEC_PUMPSCOOL_KBTU = 'out.electricity.pumps_cooling.energy_consumption..kwh'
    # ANN_ELEC_PUMPSHEAT_KBTU = 'out.electricity.pumps_heating.energy_consumption..kwh'
    ANN_ELEC_PV_KBTU = 'out.electricity.pv.energy_consumption..kwh' #
    # ANN_ELEC_RANGEFAN_KBTU = 'out.electricity.range_fan.energy_consumption..kwh'
    # ANN_ELEC_RECIRCPUMP_KBTU = 'out.electricity.recirc_pump.energy_consumption..kwh'
    ANN_ELEC_REFRIG_KBTU = 'out.electricity.refrigerator.energy_consumption..kwh' #
    # ANN_ELEC_VEHICLE_KBTU = 'out.electricity.vehicle.energy_consumption..kwh'
    ANN_ELEC_SWH_KBTU = 'out.electricity.hot_water.energy_consumption..kwh' #
    ANN_ELEC_WELLPUMP_KBTU = 'out.electricity.well_pump.energy_consumption..kwh' #


    # End use energy - natural gas
    ANN_GAS_CLOTHESDRYR_KBTU = 'out.natural_gas.clothes_dryer.energy_consumption..kwh'#
    ANN_GAS_RANGE_KBTU = 'out.natural_gas.range_oven.energy_consumption..kwh'#
    ANN_GAS_FIREPLACE_KBTU = 'out.natural_gas.fireplace.energy_consumption..kwh'#
    ANN_GAS_GRILL_KBTU = 'out.natural_gas.grill.energy_consumption..kwh'#
    ANN_GAS_HEAT_KBTU = 'out.natural_gas.heating.energy_consumption..kwh'#
    ANN_GAS_HEATSUPPL_KBTU = 'out.natural_gas.heating_hp_bkup.energy_consumption..kwh' ##
    ANN_GAS_HOTTUBHEAT_KBTU = 'out.natural_gas.hot_tub_heater.energy_consumption..kwh'#
    ANN_GAS_LTG_KBTU = 'out.natural_gas.lighting.energy_consumption..kwh'#
    ANN_GAS_POOLHEAT_KBTU = 'out.natural_gas.pool_heater.energy_consumption..kwh'#
    ANN_GAS_SWH_KBTU = 'out.natural_gas.hot_water.energy_consumption..kwh'#

    # End use energy - fuel oil
    ANN_FUELOIL_HEAT_KBTU = 'out.fuel_oil.heating.energy_consumption..kwh' #
    ANN_FUELOIL_HEATSUPPL_KBTU = 'out.fuel_oil.heating_hp_bkup.energy_consumption..kwh' ##
    ANN_FUELOIL_SWH_KBTU = 'out.fuel_oil.hot_water.energy_consumption..kwh' #

    # End use energy - propane
    ANN_PROPANE_CLOTHESDRYR_KBTU = 'out.propane.clothes_dryer.energy_consumption..kwh' #
    ANN_PROPANE_RANGE_KBTU = 'out.propane.range_oven.energy_consumption..kwh' #
    ANN_PROPANE_HEAT_KBTU = 'out.propane.heating.energy_consumption..kwh' #
    ANN_PROPANE_HEATSUPPL_KBTU = 'out.propane.heating_hp_bkup.energy_consumption..kwh' ##
    ANN_PROPANE_SWH_KBTU = 'out.propane.hot_water.energy_consumption..kwh'#

    # End use energy - wood
    # ANN_WOOD_HEAT_KBTU = 'out.wood.heating.energy_consumption..kwh'

    # List of total annual energy columns
    COLS_TOT_ANN_ENGY = [
        ANN_TOT_ENGY_KBTU,
        ANN_TOT_ELEC_KBTU,
        ANN_TOT_GAS_KBTU,
        ANN_TOT_FUELOIL_KBTU,
        ANN_TOT_PROPANE_KBTU,
        # ANN_TOT_WOOD_KBTU
    ]

    # List of end use annual energy columns
    COLS_ENDUSE_ANN_ENGY = [
        # End use energy - electricity
        # ANN_ELEC_BATHFAN_KBTU,
        ANN_ELEC_CEILFAN_KBTU,
        ANN_ELEC_CLOTHESDRYR_KBTU,
        ANN_ELEC_CLOTHESWSHR_KBTU,
        ANN_ELEC_RANGE_KBTU,
        ANN_ELEC_COOL_KBTU,
        ANN_ELEC_DISHWSHR_KBTU,
        # ANN_ELEC_HOLLTG_KBTU,
        ANN_ELEC_EXTLTG_KBTU,
        # ANN_ELEC_EXTRAREFRIG_KBTU,
        ANN_ELEC_FANSCOOL_KBTU,
        ANN_ELEC_FANSHEAT_KBTU,
        ANN_ELEC_FREEZER_KBTU,
        ANN_ELEC_GARAGELTG_KBTU,
        ANN_ELEC_HEAT_KBTU,
        ANN_ELEC_HEATSUPPL_KBTU,
        ANN_ELEC_HOTTUBHEAT_KBTU,
        ANN_ELEC_HOTTUBPUMP_KBTU,
        ANN_ELEC_HOUSEFAN_KBTU,
        ANN_ELEC_INTLTG_KBTU,
        ANN_ELEC_PLUGLOADS_KBTU,
        ANN_ELEC_POOLHEAT_KBTU,
        ANN_ELEC_POOLPUMP_KBTU,
        # ANN_ELEC_PUMPSCOOL_KBTU,
        # ANN_ELEC_PUMPSHEAT_KBTU,
        ANN_ELEC_PV_KBTU,
        # ANN_ELEC_RANGEFAN_KBTU,
        # ANN_ELEC_RECIRCPUMP_KBTU,
        ANN_ELEC_REFRIG_KBTU,
        # ANN_ELEC_VEHICLE_KBTU,
        ANN_ELEC_SWH_KBTU,
        ANN_ELEC_WELLPUMP_KBTU,
        # End use energy - natural gas
        ANN_GAS_CLOTHESDRYR_KBTU,
        ANN_GAS_RANGE_KBTU,
        ANN_GAS_FIREPLACE_KBTU,
        ANN_GAS_GRILL_KBTU,
        ANN_GAS_HEAT_KBTU,
        ANN_GAS_HOTTUBHEAT_KBTU,
        ANN_GAS_LTG_KBTU,
        ANN_GAS_POOLHEAT_KBTU,
        ANN_GAS_SWH_KBTU,
        # End use energy - fuel oil
        ANN_FUELOIL_HEAT_KBTU,
        ANN_FUELOIL_SWH_KBTU,
        ANN_FUELOIL_HEATSUPPL_KBTU,
        # End use energy - propane
        ANN_PROPANE_CLOTHESDRYR_KBTU,
        ANN_PROPANE_RANGE_KBTU,
        ANN_PROPANE_HEAT_KBTU,
        ANN_PROPANE_SWH_KBTU,
        ANN_PROPANE_HEATSUPPL_KBTU,
        # End use energy - wood
        # ANN_WOOD_HEAT_KBTU,
    ]

    # List of natural gas end use columns
    COLS_GAS_ENDUSE = [
        ANN_GAS_CLOTHESDRYR_KBTU,
        ANN_GAS_RANGE_KBTU,
        ANN_GAS_FIREPLACE_KBTU,
        ANN_GAS_GRILL_KBTU,
        ANN_GAS_HEAT_KBTU,
        ANN_GAS_HEATSUPPL_KBTU,
        ANN_GAS_HOTTUBHEAT_KBTU,
        ANN_GAS_LTG_KBTU,
        ANN_GAS_POOLHEAT_KBTU,
        ANN_GAS_SWH_KBTU
    ]

    # List of electricity end use columns
    COLS_ELEC_ENDUSE = [
        # ANN_ELEC_BATHFAN_KBTU,
        ANN_ELEC_CEILFAN_KBTU,
        ANN_ELEC_CLOTHESDRYR_KBTU,
        ANN_ELEC_CLOTHESWSHR_KBTU,
        ANN_ELEC_RANGE_KBTU,
        ANN_ELEC_COOL_KBTU,
        ANN_ELEC_DISHWSHR_KBTU,
        # ANN_ELEC_HOLLTG_KBTU,
        ANN_ELEC_EXTLTG_KBTU,
        # ANN_ELEC_EXTRAREFRIG_KBTU,
        ANN_ELEC_FANSCOOL_KBTU,
        ANN_ELEC_FANSHEAT_KBTU,
        ANN_ELEC_FREEZER_KBTU,
        ANN_ELEC_GARAGELTG_KBTU,
        ANN_ELEC_HEAT_KBTU,
        ANN_ELEC_HEATSUPPL_KBTU,
        ANN_ELEC_HOTTUBHEAT_KBTU,
        ANN_ELEC_HOTTUBPUMP_KBTU,
        ANN_ELEC_HOUSEFAN_KBTU,
        ANN_ELEC_INTLTG_KBTU,
        ANN_ELEC_PLUGLOADS_KBTU,
        ANN_ELEC_POOLHEAT_KBTU,
        ANN_ELEC_POOLPUMP_KBTU,
        # ANN_ELEC_PUMPSCOOL_KBTU,
        # ANN_ELEC_PUMPSHEAT_KBTU,
        ANN_ELEC_PV_KBTU,
        # ANN_ELEC_RANGEFAN_KBTU,
        # ANN_ELEC_RECIRCPUMP_KBTU,
        ANN_ELEC_REFRIG_KBTU,
        # ANN_ELEC_VEHICLE_KBTU,
        ANN_ELEC_SWH_KBTU,
        ANN_ELEC_WELLPUMP_KBTU,
    ]

    # List of HVAC enduse aggregations
    COLS_HVAC_ENDUSE = [
        # End use energy - electricity
        ANN_ELEC_FANSCOOL_KBTU,
        ANN_ELEC_FANSHEAT_KBTU,
        ANN_ELEC_COOL_KBTU,
        ANN_ELEC_CEILFAN_KBTU,
        ANN_ELEC_HEAT_KBTU,
        ANN_ELEC_HEATSUPPL_KBTU,
        ANN_ELEC_HOUSEFAN_KBTU,
        # End use energy - natural gas
        ANN_GAS_HEAT_KBTU,
        ANN_GAS_HEATSUPPL_KBTU,
        # End use energy - propane
        ANN_PROPANE_HEAT_KBTU,
        ANN_PROPANE_HEATSUPPL_KBTU,
        # End use energy - fuel oil
        ANN_FUELOIL_HEAT_KBTU,
        ANN_FUELOIL_HEATSUPPL_KBTU

    ]

    # List of Water Heating enduse aggregations
    COLS_DHW_ENDUSE = [
        # End use energy - electricity
        ANN_ELEC_SWH_KBTU,
        # End use energy - natural gas
        ANN_GAS_SWH_KBTU,
        # End use energy - propane
        ANN_PROPANE_SWH_KBTU,
        # End use energy - fuel oil
        ANN_FUELOIL_SWH_KBTU
    ]

    # List of Appliance enduse aggregations
    COLS_APP_ENDUSE = [
        # End use energy - electricity
        ANN_ELEC_CLOTHESDRYR_KBTU,
        ANN_ELEC_CLOTHESWSHR_KBTU,
        ANN_ELEC_RANGE_KBTU,
        ANN_ELEC_DISHWSHR_KBTU,
        ANN_ELEC_FREEZER_KBTU,
        ANN_ELEC_REFRIG_KBTU,
        # End use energy - natural gas
        ANN_GAS_CLOTHESDRYR_KBTU,
        ANN_GAS_RANGE_KBTU,
        # End use energy - propane
        ANN_PROPANE_CLOTHESDRYR_KBTU,
        ANN_PROPANE_RANGE_KBTU

    ]

    # List of Lighting enduse aggregations
    COLS_LIGHT_ENDUSE = [
        # End use energy - electricity
        ANN_ELEC_EXTLTG_KBTU,
        ANN_ELEC_GARAGELTG_KBTU,
        ANN_ELEC_INTLTG_KBTU,
        # End use energy - nautral gas
        ANN_GAS_LTG_KBTU

    ]

    # List of Miscellaneous enduse aggregations
    COLS_MISC_ENDUSE = [
        # End use energy - electricity
        ANN_ELEC_PLUGLOADS_KBTU,
        ANN_ELEC_POOLHEAT_KBTU,
        ANN_ELEC_POOLPUMP_KBTU,
        ANN_ELEC_HOTTUBHEAT_KBTU,
        ANN_ELEC_HOTTUBPUMP_KBTU,
        # End use energy - nautral gas
        ANN_GAS_FIREPLACE_KBTU,
        ANN_GAS_GRILL_KBTU,
        ANN_GAS_HOTTUBHEAT_KBTU,
        ANN_GAS_POOLHEAT_KBTU,
        ANN_ELEC_WELLPUMP_KBTU

    ]

    # List of PV enduse aggregations
    COLS_PV_ENDUSE = [
        ANN_ELEC_PV_KBTU
    ]

    def units_from_col_name(self, col_name):
        # Extract the units from the column name
        match = re.search('\.\.(.*)', col_name)
        if match:
            units = match.group(1)
        else:
            units = ''

        return units

    def col_name_to_weighted(self, col_name, new_units=None):
        col_name = col_name.replace('in.', 'in.weighted.')
        col_name = col_name.replace('out.', 'out.weighted.')
        if not new_units is None:
            old_units = self.units_from_col_name(col_name)
            col_name = col_name.replace(f'..{old_units}', f'..{new_units}')

        return col_name
    
    def col_name_to_ghg(self, col_name):
        # 'out.weighted.electricity.pv.energy_consumption..tbtu'
        # 'out.weighted.natural_gas.clothes_dryer.emissions..co2e_mmt'
        col_name = col_name.replace('energy_consumption', 'emissions')
        col_name = col_name.replace('tbtu', 'co2e_mmt')

        return col_name

    def col_name_to_eui(self, col_name):
        col_name = col_name.replace('in.', 'in.eui.')
        col_name = col_name.replace('out.', 'out.eui.')

        engy_units = self.units_from_col_name(col_name)
        area_units = self.units_from_col_name(self.FLR_AREA)
        eui_units = f'{engy_units}_per_{area_units}'
        col_name = col_name.replace(f'..{engy_units}', f'..{eui_units}')

        return col_name

    def col_name_to_nice_name(self, col_name):
        # out.natural_gas.heating.energy_consumption..kwh
        # becomes
        # Natural Gas Heating Energy Consumption
        units = self.units_from_col_name(col_name)
        col_name = col_name.replace(f'..{units}', '')
        col_name = col_name.replace('in.', '')
        col_name = col_name.replace('out.', '')
        col_name = col_name.replace('stat.', '')
        col_name = col_name.replace('weighted.', '')
        col_name = col_name.replace('.', ' ')
        col_name = col_name.replace('_', ' ')
        col_name = col_name.title()

        return col_name

    def engy_col_name_to_parts(self, col_name):
        # out.electricity.cooling.energy_consumption..kwh
        # out.eui.electricity.cooling.energy_consumption..kwh_per_ft2
        # out.weighted.electricity.cooling.energy_consumption..TBtu
        col_name = col_name.replace(f'..', '.')
        p = col_name.split('.')
        if len(p) == 5:
            p.insert(1, 'unweighted')
        parts = {
            'type': p[1],
            'fuel': p[2],
            'enduse': p[3],
            # p[4] currently always 'energy_consumption'
            'units': p[5]
        }

        return parts

    def dataframe_sorted_with_nice_names(self, df):
        #

        # TODO Sort the index in a standard way
        # for old_name in df.index.names:
        #     if old_name in self.ORDERED_CATEGORIES.keys():
        #         print(f'Found fixed ordering for {old_name}:')
        #         print(f'{self.ORDERED_CATEGORIES[old_name]}')

        # Rename index to nice names
        new_names = []
        for old_name in df.index.names:
            new_names.append(self.col_name_to_nice_name(old_name))

        df.index.rename(names=new_names, inplace=True)

        return df
