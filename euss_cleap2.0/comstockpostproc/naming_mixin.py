# ComStock™, Copyright (c) 2023 Alliance for Sustainable Energy, LLC. All rights reserved.
# See top level LICENSE.txt file for license terms.
import re

class NamingMixin():
    # Column aliases for code readability
    # Add to this list for commonly-used columns
    DATASET = 'dataset'
    BLDG_ID = 'bldg_id'
    CEN_REG = 'in.census_region_name'
    CEN_DIV = 'in.census_division_name'
    STATE_NAME = 'in.state_name'
    STATE_ABBRV = 'in.state'
    FLR_AREA = 'in.sqft'
    FLR_AREA_CAT = 'in.floor_area_category'
    CBECS_BLDG_TYPE = 'in.cbecs_building_type'
    YEAR_BUILT = 'in.year_built'
    BLDG_WEIGHT = 'weight'
    BLDG_TYPE = 'in.comstock_building_type'
    BLDG_TYPE_GROUP = 'in.comstock_building_type_group'
    AEO_BLDG_TYPE = 'in.aeo_and_nems_building_type'
    VINTAGE = 'in.vintage'
    CZ_ASHRAE = 'in.ashrae_iecc_climate_zone_2006'
    UPGRADE_NAME = 'in.upgrade_name'
    UPGRADE_ID = 'upgrade'
    UPGRADE_APPL = 'applicability'
    BASE_NAME = 'Baseline'
    BLDG_UP_ID = 'in.building_upgrade_id'
    HVAC_SYS = 'in.hvac_system_type'
    SEG_NAME = 'calc.segment'
    COMP_STATUS = 'completed_status'
    META_IDX = 'metadata_index'

    # Total annual energy
    ANN_TOT_ENGY_KBTU = 'out.site_energy.total.energy_consumption..kwh'
    ANN_TOT_ELEC_KBTU = 'out.electricity.total.energy_consumption..kwh'
    ANN_TOT_GAS_KBTU = 'out.natural_gas.total.energy_consumption..kwh'
    ANN_TOT_OTHFUEL_KBTU = 'out.other_fuel.total.energy_consumption..kwh'
    ANN_TOT_DISTHTG_KBTU = 'out.district_heating.total.energy_consumption..kwh'
    ANN_TOT_DISTCLG_KBTU = 'out.district_cooling.total.energy_consumption..kwh'

    # End use energy - electricity
    ANN_ELEC_COOL_KBTU = 'out.electricity.cooling.energy_consumption..kwh'
    ANN_ELEC_EXTLTG_KBTU = 'out.electricity.exterior_lighting.energy_consumption..kwh'
    ANN_ELEC_FANS_KBTU = 'out.electricity.fans.energy_consumption..kwh'
    ANN_ELEC_HEATREJECT_KBTU = 'out.electricity.heat_recovery.energy_consumption..kwh'
    ANN_ELEC_HEATRECOV_KBTU = 'out.electricity.heat_rejection.energy_consumption..kwh'
    ANN_ELEC_HEAT_KBTU = 'out.electricity.heating.energy_consumption..kwh'
    ANN_ELEC_INTEQUIP_KBTU = 'out.electricity.interior_equipment.energy_consumption..kwh'
    ANN_ELEC_INTLTG_KBTU = 'out.electricity.interior_lighting.energy_consumption..kwh'
    ANN_ELEC_PUMPS_KBTU = 'out.electricity.pumps.energy_consumption..kwh'
    ANN_ELEC_REFRIG_KBTU = 'out.electricity.refrigeration.energy_consumption..kwh'
    ANN_ELEC_SWH_KBTU = 'out.electricity.water_systems.energy_consumption..kwh'

    # End use energy - natural gas
    ANN_GAS_HEAT_KBTU = 'out.natural_gas.heating.energy_consumption..kwh'
    ANN_GAS_INTEQUIP_KBTU = 'out.natural_gas.interior_equipment.energy_consumption..kwh'
    ANN_GAS_SWH_KBTU = 'out.natural_gas.water_systems.energy_consumption..kwh'
    ANN_GAS_COOL_KBTU = 'out.natural_gas.cooling.energy_consumption..kwh'

    # End use energy - district cooling
    ANN_DISTCLG_COOL_KBTU = 'out.district_cooling.cooling.energy_consumption..kwh'

    # End use energy - district heating
    ANN_DISTHTG_HEAT_KBTU = 'out.district_heating.heating.energy_consumption..kwh'
    ANN_DISTHTG_SWH_KBTU = 'out.district_heating.water_systems.energy_consumption..kwh'
    ANN_DISTHTG_INTEQUIP_KBTU = 'out.district_heating.interior_equipment.energy_consumption..kwh'
    ANN_DISTHTG_COOL_KBTU = 'out.district_heating.cooling.energy_consumption..kwh'

    # End use energy - other fuels (sum of propane and fuel oil)
    ANN_OTHER_HEAT_KBTU = 'out.other_fuel.heating.energy_consumption..kwh'
    ANN_OTHER_SWH_KBTU = 'out.other_fuel.water_systems.energy_consumption..kwh'
    ANN_OTHER_INTEQUIP_KBTU = 'out.other_fuel.interior_equipment.energy_consumption..kwh'
    ANN_OTHER_COOL_KBTU = 'out.other_fuel.cooling.energy_consumption..kwh'

    # End use group energy - all fuels
    ANN_HEAT_GROUP_KBTU = 'calc.enduse_group.site_energy.heating.energy_consumption..kwh'
    ANN_COOL_GROUP_KBTU = 'calc.enduse_group.site_energy.cooling.energy_consumption..kwh'
    ANN_HVAC_GROUP_KBTU = 'calc.enduse_group.site_energy.hvac.energy_consumption..kwh'
    ANN_LTG_GROUP_KBTU = 'calc.enduse_group.site_energy.lighting.energy_consumption..kwh'
    ANN_INTEQUIP_GROUP_KBTU = 'calc.enduse_group.site_energy.interior_equipment.energy_consumption..kwh'
    ANN_REFRIG_GROUP_KBTU = 'calc.enduse_group.site_energy.refrigeration.energy_consumption..kwh'
    ANN_SWH_GROUP_KBTU = 'calc.enduse_group.site_energy.water_systems.energy_consumption..kwh'

    # End use group energy - electricity
    ANN_ELEC_HVAC_GROUP_KBTU = 'calc.enduse_group.electricity.hvac.energy_consumption..kwh'
    ANN_ELEC_LTG_GROUP_KBTU = 'calc.enduse_group.electricity.lighting.energy_consumption..kwh'
    ANN_ELEC_INTEQUIP_GROUP_KBTU = 'calc.enduse_group.electricity.interior_equipment.energy_consumption..kwh'
    ANN_ELEC_REFRIG_GROUP_KBTU = 'calc.enduse_group.electricity.refrigeration.energy_consumption..kwh'
    ANN_ELEC_SWH_GROUP_KBTU = 'calc.enduse_group.electricity.water_systems.energy_consumption..kwh'

    # End use group energy - natural gas
    ANN_GAS_HVAC_GROUP_KBTU = 'calc.enduse_group.natural_gas.hvac.energy_consumption..kwh'
    ANN_GAS_INTEQUIP_GROUP_KBTU = 'calc.enduse_group.natural_gas.interior_equipment.energy_consumption..kwh'
    ANN_GAS_SWH_GROUP_KBTU = 'calc.enduse_group.natural_gas.water_systems.energy_consumption..kwh'

    # End use group energy - district heating
    ANN_DISTHTG_HVAC_GROUP_KBTU = 'calc.enduse_group.district_heating.hvac.energy_consumption..kwh'
    ANN_DISTHTG_INTEQUIP_GROUP_KBTU = 'calc.enduse_group.district_heating.interior_equipment.energy_consumption..kwh'
    ANN_DISTHTG_SWH_GROUP_KBTU = 'calc.enduse_group.district_heating.water_systems.energy_consumption..kwh'

    # End use group energy - district cooling
    ANN_DISTCLG_HVAC_GROUP_KBTU = 'calc.enduse_group.district_cooling.hvac.energy_consumption..kwh'

    # End use group energy - other fuels
    ANN_OTHER_HVAC_GROUP_KBTU = 'calc.enduse_group.other_fuel.hvac.energy_consumption..kwh'
    ANN_OTHER_SWH_GROUP_KBTU = 'calc.enduse_group.other_fuel.water_systems.energy_consumption..kwh'
    ANN_OTHER_INTEQUIP_GROUP_KBTU = 'calc.enduse_group.other_fuel.interior_equipment.energy_consumption..kwh'

    # List of total annual energy end use group columns
    COLS_ENDUSE_GROUP_TOT_ANN_ENGY = [
        ANN_HVAC_GROUP_KBTU,
        ANN_LTG_GROUP_KBTU,
        ANN_INTEQUIP_GROUP_KBTU,
        ANN_REFRIG_GROUP_KBTU,
        ANN_SWH_GROUP_KBTU
    ]

    # List of end use group columns
    COLS_ENDUSE_GROUP_ANN_ENGY = [
        ANN_ELEC_HVAC_GROUP_KBTU,
        ANN_ELEC_LTG_GROUP_KBTU,
        ANN_ELEC_INTEQUIP_GROUP_KBTU,
        ANN_ELEC_REFRIG_GROUP_KBTU,
        ANN_ELEC_SWH_GROUP_KBTU,
        ANN_GAS_HVAC_GROUP_KBTU,
        ANN_GAS_INTEQUIP_GROUP_KBTU,
        ANN_GAS_SWH_GROUP_KBTU,
        ANN_DISTHTG_HVAC_GROUP_KBTU,
        ANN_DISTHTG_INTEQUIP_GROUP_KBTU,
        ANN_DISTHTG_SWH_GROUP_KBTU,
        ANN_DISTCLG_HVAC_GROUP_KBTU,
        ANN_OTHER_HVAC_GROUP_KBTU,
        ANN_OTHER_SWH_GROUP_KBTU,
        ANN_OTHER_INTEQUIP_GROUP_KBTU
    ]

    # Utility bills
    UTIL_BILL_ELEC = 'out.utility_bills.electricity_bill_mean..usd'
    UTIL_BILL_GAS = 'out.utility_bills.natural_gas_bill..usd'
    UTIL_BILL_FUEL_OIL = 'out.utility_bills.fuel_oil_bill..usd'
    UTIL_BILL_PROPANE = 'out.utility_bills.propane_bill..usd'

    # Utility bill columns
    COLS_UTIL_BILLS = [
        UTIL_BILL_ELEC,
        UTIL_BILL_GAS,
        UTIL_BILL_FUEL_OIL,
        UTIL_BILL_PROPANE
    ]

    # GHG emissions columns
    ANN_GHG_EGRID = 'calc.emissions.total_with_egrid..co2e_kg'
    ANN_GHG_CAMBIUM = 'calc.emissions.total_with_cambium_mid_case_15y..co2e_kg'

    # GHG emissions columns to sum for eGrid total
    COLS_GHG_EGRID = [
        'out.emissions.natural_gas..co2e_kg',
        'out.emissions.fuel_oil..co2e_kg',
        'out.emissions.propane..co2e_kg',
        'out.emissions.electricity.egrid_2021_subregion..co2e_kg'
    ]

    # GHG emissions columns to sum for Cambium total
    COLS_GHG_CAMBIUM = [
        'out.emissions.natural_gas..co2e_kg',
        'out.emissions.fuel_oil..co2e_kg',
        'out.emissions.propane..co2e_kg',
        'out.emissions.electricity.lrmer_95_decarb_by_2035_15_2023_start..co2e_kg'
    ]

    # QOI COLS
    QOI_MAX_SHOULDER_HR = 'out.qoi.maximum_daily_timing_shoulder_hour..hr'
    QOI_MAX_SUMMER_HR = 'out.qoi.maximum_daily_timing_summer_hour..hr'
    QOI_MAX_WINTER_HR = 'out.qoi.maximum_daily_timing_winter_hour..hr'

    QOI_MAX_SHOULDER_USE = 'out.qoi.maximum_daily_use_shoulder..kw'
    QOI_MAX_SUMMER_USE = 'out.qoi.maximum_daily_use_summer..kw'
    QOI_MAX_WINTER_USE = 'out.qoi.maximum_daily_use_winter..kw'

    QOI_MIN_SHOULDER_USE = 'out.qoi.minimum_daily_use_shoulder..kw'
    QOI_MIN_SUMMER_USE = 'out.qoi.minimum_daily_use_summer..kw'
    QOI_MIN_WINTER_USE = 'out.qoi.minimum_daily_use_winter..kw'

    QOI_MAX_SHOULDER_USE_NORMALIZED = 'out.qoi.maximum_daily_use_shoulder_intensity..w_per_ft2'
    QOI_MAX_SUMMER_USE_NORMALIZED = 'out.qoi.maximum_daily_use_summer_intensity..w_per_ft2'
    QOI_MAX_WINTER_USE_NORMALIZED = 'out.qoi.maximum_daily_use_winter_intensity..w_per_ft2'

    QOI_MIN_SHOULDER_USE_NORMALIZED = 'out.qoi.minimum_daily_use_shoulder_intensity..w_per_ft2'
    QOI_MIN_SUMMER_USE_NORMALIZED = 'out.qoi.minimum_daily_use_summer_intensity..w_per_ft2'
    QOI_MIN_WINTER_USE_NORMALIZED = 'out.qoi.minimum_daily_use_winter_intensity..w_per_ft2'

    # Greenhouse gas emissions columns
    GHG_NATURAL_GAS = 'out.emissions.natural_gas..co2e_kg'
    GHG_FUEL_OIL = 'out.emissions.fuel_oil..co2e_kg'
    GHG_PROPANE = 'out.emissions.propane..co2e_kg'
    GHG_LRMER_LOW_RE_COST_15_ELEC = 'out.emissions.electricity.lrmer_low_re_cost_15_2023_start..co2e_kg'
    GHG_LRMER_MID_CASE_15_ELEC = 'out.emissions.electricity.lrmer_mid_case_15_2023_start..co2e_kg'
    GHG_LRMER_HIGH_RE_COST_15_ELEC = 'out.emissions.electricity.lrmer_high_re_cost_15_2023_start..co2e_kg'
    GHG_ELEC_EGRID = 'out.emissions.electricity.egrid_2021_subregion..co2e_kg'

    # Addressable segment columns
    SEG_A = 'A: Non Food-Service Buildings with Small Packaged Units'
    SEG_B = 'B: Food-Service Buildings with Small Packaged Units'
    SEG_C = 'C: Strip Malls with some Food-Service with Small Packaged Units'
    SEG_D = 'D: Buildings with Hydronically Heated Multizone Systems'
    SEG_E = 'E: Lodging with Zone-by-Zone Systems'
    SEG_F = 'F: Buildings with Electric Resistance Multizone Systems'
    SEG_G = 'G: Buildings with Furnace-Based Multizone Systems'
    SEG_H = 'H: Buildings with Residential Style Central Systems'
    SEG_I = 'I: Non-Lodging Buildings with Zone-by-Zone Systems'
    SEG_J = 'J: Other'

    # List of addressable segments
    COLS_SEGMENTS = [
        SEG_A,
        SEG_B,
        SEG_C,
        SEG_D,
        SEG_E,
        SEG_F,
        SEG_G,
        SEG_H,
        SEG_I,
        SEG_J
    ]

    # List of total annual energy columns
    COLS_TOT_ANN_ENGY = [
        ANN_TOT_ENGY_KBTU,
        ANN_TOT_ELEC_KBTU,
        ANN_TOT_GAS_KBTU,
        ANN_TOT_OTHFUEL_KBTU,
        ANN_TOT_DISTHTG_KBTU,
        ANN_TOT_DISTCLG_KBTU
    ]

    # List of end use annual energy columns
    COLS_ENDUSE_ANN_ENGY = [
        ANN_ELEC_COOL_KBTU,
        ANN_ELEC_EXTLTG_KBTU,
        ANN_ELEC_FANS_KBTU,
        ANN_ELEC_HEATREJECT_KBTU,
        ANN_ELEC_HEATRECOV_KBTU,
        ANN_ELEC_HEAT_KBTU,
        ANN_ELEC_INTEQUIP_KBTU,
        ANN_ELEC_INTLTG_KBTU,
        ANN_ELEC_PUMPS_KBTU,
        ANN_ELEC_REFRIG_KBTU,
        ANN_ELEC_SWH_KBTU,
        ANN_GAS_HEAT_KBTU,
        ANN_GAS_INTEQUIP_KBTU,
        ANN_GAS_SWH_KBTU,
        ANN_GAS_COOL_KBTU,
        ANN_DISTCLG_COOL_KBTU,
        ANN_DISTHTG_HEAT_KBTU,
        ANN_DISTHTG_INTEQUIP_KBTU,
        ANN_DISTHTG_SWH_KBTU,
        ANN_DISTHTG_COOL_KBTU,
        ANN_OTHER_HEAT_KBTU,
        ANN_OTHER_SWH_KBTU,
        ANN_OTHER_INTEQUIP_KBTU,
        ANN_OTHER_COOL_KBTU
    ]

    # List of natural gas end use columns
    COLS_GAS_ENDUSE = [
        ANN_GAS_HEAT_KBTU,
        ANN_GAS_SWH_KBTU,
        ANN_GAS_INTEQUIP_KBTU,
        ANN_GAS_COOL_KBTU
    ]

    # List of electricity end use columns
    COLS_ELEC_ENDUSE = [
        ANN_ELEC_COOL_KBTU,
        ANN_ELEC_EXTLTG_KBTU,
        ANN_ELEC_FANS_KBTU,
        ANN_ELEC_HEATREJECT_KBTU,
        ANN_ELEC_HEATRECOV_KBTU,
        ANN_ELEC_HEAT_KBTU,
        ANN_ELEC_INTEQUIP_KBTU,
        ANN_ELEC_INTLTG_KBTU,
        ANN_ELEC_PUMPS_KBTU,
        ANN_ELEC_REFRIG_KBTU,
        ANN_ELEC_SWH_KBTU,
    ]

    # List of heating end use columns
    COLS_HEAT_ENDUSE = [
        ANN_ELEC_HEAT_KBTU,
        ANN_GAS_HEAT_KBTU,
        ANN_DISTHTG_HEAT_KBTU,
        ANN_OTHER_HEAT_KBTU
    ]

    # List of cooling end use columns
    COLS_COOL_ENDUSE = [
        ANN_ELEC_COOL_KBTU,
        ANN_GAS_COOL_KBTU,
        ANN_DISTHTG_COOL_KBTU,
        ANN_DISTCLG_COOL_KBTU,
        ANN_OTHER_COOL_KBTU
    ]

    # List of HVAC, electricity end use columns
    COLS_HVAC_ELEC_ENDUSE = [
        ANN_ELEC_COOL_KBTU,
        ANN_ELEC_HEAT_KBTU,
        ANN_ELEC_FANS_KBTU,
        ANN_ELEC_PUMPS_KBTU,
        ANN_ELEC_HEATRECOV_KBTU,
        ANN_ELEC_HEATREJECT_KBTU
    ]

    # List of HVAC, natural_gas end use columns
    COLS_HVAC_GAS_ENDUSE = [
        ANN_GAS_COOL_KBTU,
        ANN_GAS_HEAT_KBTU
    ]

    # List of HVAC, district_heating end use columns
    COLS_HVAC_DISTHTG_ENDUSE = [
        ANN_DISTHTG_COOL_KBTU,
        ANN_DISTHTG_HEAT_KBTU
    ]

    # List of HVAC, district_cooling end use columns
    COLS_HVAC_DISTCLG_ENDUSE = [
        ANN_DISTCLG_COOL_KBTU
    ]

    # List of HVAC, other_fuel end use columns
    COLS_HVAC_OTHER_ENDUSE = [
        ANN_OTHER_COOL_KBTU,
        ANN_OTHER_HEAT_KBTU
    ]

    # List of Lighting, electricity end use columns
    COLS_LTG_ELEC_ENDUSE = [
        ANN_ELEC_INTLTG_KBTU,
        ANN_ELEC_EXTLTG_KBTU
    ]

    # List of Interior Equipment, electricity end use columns
    COLS_INTEQUIP_ELEC_ENDUSE = [
        ANN_ELEC_INTEQUIP_KBTU
    ]

    # List of Interior Equipment, natural gas end use columns
    COLS_INTEQUIP_GAS_ENDUSE = [
        ANN_GAS_INTEQUIP_KBTU
    ]

    # List of Interior Equipment, district_heating end use columns
    COLS_INTEQUIP_DISTHTG_ENDUSE = [
        ANN_DISTHTG_INTEQUIP_KBTU
    ]

    # List of Interior Equipment, other_fuel end use columns
    COLS_INTEQUIP_OTHER_ENDUSE = [
        ANN_OTHER_INTEQUIP_KBTU
    ]

    # List of Water Heating, electricity end use columns
    COLS_SWH_ELEC_ENDUSE = [
        ANN_ELEC_SWH_KBTU
    ]

    # List of Water Heating, natural gas end use columns
    COLS_SWH_GAS_ENDUSE = [
        ANN_GAS_SWH_KBTU
    ]

    # List of Water Heating, district_heating end use columns
    COLS_SWH_DISTHTG_ENDUSE = [
        ANN_DISTHTG_SWH_KBTU
    ]

    # List of Water Heating, other_fuel end use columns
    COLS_SWH_OTHER_ENDUSE = [
        ANN_OTHER_SWH_KBTU
    ]

    # List of Refrigeration, electricity end use columns
    COLS_REFRIG_ELEC_ENDUSE = [
        ANN_ELEC_REFRIG_KBTU
    ]

    # List of HVAC end use group columns
    COLS_HVAC_ENERGY = COLS_HVAC_ELEC_ENDUSE + COLS_HVAC_GAS_ENDUSE + COLS_HVAC_DISTHTG_ENDUSE + COLS_HVAC_DISTCLG_ENDUSE + COLS_HVAC_OTHER_ENDUSE

    # List of Equipment end use group columns
    COLS_INTEQUIP_ENERGY = [
        ANN_ELEC_INTEQUIP_KBTU,
        ANN_GAS_INTEQUIP_KBTU,
        ANN_DISTHTG_INTEQUIP_KBTU,
        ANN_OTHER_INTEQUIP_KBTU
    ]

    # List of Water Heating end use group columns
    COLS_SWH_ENERGY = [
        ANN_ELEC_SWH_KBTU,
        ANN_GAS_SWH_KBTU,
        ANN_DISTHTG_SWH_KBTU,
        ANN_OTHER_SWH_KBTU
    ]

    QOI_MAX_DAILY_TIMING_COLS = [
        QOI_MAX_SHOULDER_HR,
        QOI_MAX_SUMMER_HR,
        QOI_MAX_WINTER_HR
    ]

    QOI_MAX_USE_COLS = [
        QOI_MAX_SHOULDER_USE,
        QOI_MAX_SUMMER_USE,
        QOI_MAX_WINTER_USE
    ]

    QOI_MIN_USE_COLS = [
        QOI_MIN_SHOULDER_USE,
        QOI_MIN_SUMMER_USE,
        QOI_MIN_WINTER_USE
    ]

    QOI_MAX_USE_COLS_NORMALIZED = [
        QOI_MAX_SHOULDER_USE_NORMALIZED,
        QOI_MAX_SUMMER_USE_NORMALIZED,
        QOI_MAX_WINTER_USE_NORMALIZED
    ]

    QOI_MIN_USE_COLS_NORMALIZED = [
        QOI_MIN_SHOULDER_USE_NORMALIZED,
        QOI_MIN_SUMMER_USE_NORMALIZED,
        QOI_MIN_WINTER_USE_NORMALIZED
    ]

    GHG_FUEL_COLS = [
        GHG_NATURAL_GAS,
        GHG_FUEL_OIL,
        GHG_PROPANE,
        GHG_LRMER_LOW_RE_COST_15_ELEC,
        #GHG_LRMER_MID_CASE_15_ELEC,
        GHG_LRMER_HIGH_RE_COST_15_ELEC,
        GHG_ELEC_EGRID
    ]

    # Colors from https://davidmathlogic.com/colorblind Bang Wong color palette
    COLOR_COMSTOCK_BEFORE = '#0072B2'
    COLOR_COMSTOCK_AFTER = '#56B4E9'
    COLOR_CBECS_2012 = '#009E73'
    COLOR_CBECS_2018 = '#16f0b4'
    COLOR_EIA = '#D55E00'
    COLOR_AMI = '#CC79A7'

    # Define ordering for some categorical variables to make plots easier to interpret
    ORDERED_CATEGORIES = {
        FLR_AREA_CAT:
            ['1,000 square feet or less',
            '1,001 to 5,000 square feet',
            '5,001 to 10,000 square feet',
            '10,001 to 25,000 square feet',
            '25,001 to 50,000 square feet',
            '50,001 to 100,000 square feet',
            '100,001 to 200,000 square feet',
            '200,001 to 500,000 square feet',
            '500,001 to 1 million square feet',
            'Over 1 million square feet'],
        CEN_DIV:
            ['New England',
            'Middle Atlantic',
            'East North Central',
            'West North Central',
            'South Atlantic',
            'East South Central',
            'West South Central',
            'Mountain',
            'Pacific'],
        VINTAGE:
            ['Before 1946',
            '1946 to 1959',
            '1960 to 1969',
            '1970 to 1979',
            '1980 to 1989',
            '1990 to 1999',
            '2000 to 2012',
            '2013 to 2018'],
        BLDG_TYPE:
            ['FullServiceRestaurant',
            'QuickServiceRestaurant',
            'RetailStripmall',
            'RetailStandalone',
            'SmallOffice',
            'MediumOffice',
            'LargeOffice',
            'PrimarySchool',
            'SecondarySchool',
            'Outpatient',
            'Hospital',
            'SmallHotel',
            'LargeHotel',
            'Warehouse']
    }

    BLDG_TYPE_TO_SNAKE_CASE = {
        'FullServiceRestaurant': 'full_service_restaurant',
        'QuickServiceRestaurant': 'quick_service_restaurant',
        'RetailStripmall': 'strip_mall',
        'RetailStandalone': 'retail',
        'SmallOffice': 'small_office',
        'MediumOffice': 'medium_office',
        'LargeOffice': 'large_office',
        'PrimarySchool': 'primary_school',
        'SecondarySchool': 'secondary_school',
        'Outpatient': 'outpatient',
        'Hospital': 'hospital',
        'SmallHotel': 'small_hotel',
        'LargeHotel': 'large_hotel',
        'Warehouse': 'warehouse'
    }

    END_USES = [
        'exterior_lighting',
        'interior_lighting',
        'interior_equipment',
        'water_systems',
        'heat_recovery',
        'heat_rejection',
        'cooling',
        'heating',
        'fans',
        'pumps',
        'refrigeration'
    ]

    END_USES_TIMESERIES_DICT = {
        'exterior_lighting': 'electricity_exterior_lighting_kwh',
        'interior_lighting': 'electricity_interior_lighting_kwh',
        'interior_equipment': 'electricity_interior_equipment_kwh',
        'water_systems': 'electricity_water_systems_kwh',
        'heat_recovery': 'electricity_heat_recovery_kwh',
        'heat_rejection': 'electricity_heat_rejection_kwh',
        'cooling': 'electricity_cooling_kwh',
        'heating': 'electricity_heating_kwh',
        'fans': 'electricity_fans_kwh',
        'pumps': 'electricity_pumps_kwh',
        'refrigeration': 'electricity_refrigeration_kwh'
    }

    def end_use_group(self, end_use):
        # Add an End Use Group
        end_use_groups = {
            'cooling': 'HVAC',
            'exterior_lighting': 'Lighting',
            'fans': 'HVAC',
            'generators': 'Power Generation',
            'heat_recovery': 'HVAC',
            'heat_rejection': 'HVAC',
            'heating': 'HVAC',
            'humidification': 'HVAC',
            'interior_equipment': 'Equipment',
            'interior_lighting': 'Lighting',
            'pumps': 'HVAC',
            'pv': 'Power Generation',
            'refrigeration': 'Refrigeration',
            'water_systems': 'Water Heating',
            'total': 'Total',
        }

        return end_use_groups[end_use]

    def units_from_col_name(self, col_name):
        # Extract the units from the column name
        match = re.search('\.\.(.*)', col_name)
        if match:
            units = match.group(1)
        else:
            units = ''

        return units

    def col_name_to_weighted(self, col_name, new_units=None):
        col_name = col_name.replace('in.', 'out.')
        col_name = col_name.replace('out.', 'calc.')
        col_name = col_name.replace('calc.', 'calc.weighted.')
        if not new_units is None:
            old_units = self.units_from_col_name(col_name)
            col_name = col_name.replace(f'..{old_units}', f'..{new_units}')

        return col_name

    def col_name_to_weighted_savings(self, col_name, new_units=None):
        col_name = self.col_name_to_weighted(col_name, new_units)
        col_name = col_name.replace('.weighted.', '.weighted.savings.')

        return col_name

    def col_name_to_savings(self, col_name, new_units=None):
        col_name = col_name.replace('.energy_consumption', '.energy_savings')
        return col_name

    def col_name_to_weighted_percent_savings(self, col_name, new_units=None):
        col_name = self.col_name_to_weighted(col_name, new_units)
        col_name = col_name.replace('.weighted.', '.weighted.percent_savings.')
        if not new_units is None:
            old_units = self.units_from_col_name(col_name)
            col_name = col_name.replace(f'..{old_units}', f'..{new_units}')

        return col_name

    def col_name_to_percent_savings(self, col_name, new_units=None):
        # col_name = self.col_name_to_savings(col_name)
        col_name = col_name.replace('out.', 'calc.')
        col_name = col_name.replace('calc.', 'calc.percent_savings.')
        if not new_units is None:
            old_units = self.units_from_col_name(col_name)
            col_name = col_name.replace(f'..{old_units}', f'..{new_units}')

        return col_name

    def col_name_to_eui(self, col_name):
        engy_units = self.units_from_col_name(col_name)
        col_name = col_name.replace('energy_consumption', 'energy_consumption_intensity')
        col_name = col_name.replace('energy_savings', 'energy_savings_intensity')
        area_units = 'ft2'  # Hard-coded because in.sqft column name is required by SightGlass
        eui_units = f'{engy_units}_per_{area_units}'
        col_name = col_name.replace(f'..{engy_units}', f'..{eui_units}')

        return col_name

    def col_name_to_area_intensity(self, col_name):
        units = self.units_from_col_name(col_name)
        col_name = col_name.replace('bill_mean..usd', 'bill_intensity..usd')
        col_name = col_name.replace('bill..usd', 'bill_intensity..usd')
        area_units = 'ft2'
        intensity_units = f'{units}_per_{area_units}'
        col_name = col_name.replace(f'..{units}', f'..{intensity_units}')

        return col_name

    def col_name_to_energy_rate(self, col_name):
        units = self.units_from_col_name(col_name)
        col_name = col_name.replace('bill_mean..usd', 'energy_rate..usd')
        col_name = col_name.replace('bill..usd', 'energy_rate..usd')
        energy_units = 'kwh'
        intensity_units = f'{units}_per_{energy_units}'
        col_name = col_name.replace(f'..{units}', f'..{intensity_units}')

        return col_name

    def col_name_to_nice_name(self, col_name):
        # out.natural_gas.heating.energy_consumption..kwh
        # becomes
        # Natural Gas Heating Energy Consumption
        units = self.units_from_col_name(col_name)
        col_name = col_name.replace(f'..{units}', '')
        col_name = col_name.replace('in.', '')
        col_name = col_name.replace('out.', '')
        col_name = col_name.replace('params.', '')
        col_name = col_name.replace('weighted.', '')
        col_name = col_name.replace('calc.', '')
        col_name = col_name.replace('.', ' ')
        col_name = col_name.replace('_', ' ')
        col_name = col_name.replace('Eui', 'EUI')
        col_name = col_name.title()

        return col_name


    def col_name_to_nice_saving_name(self, col_name):
        units = self.nice_units(self.units_from_col_name(col_name))
        col_name = self.col_name_to_nice_name(col_name)
        col_name = col_name.replace(f' {units}', '')
        col_name = col_name.replace("Savings", '')
        col_name = col_name.replace("Consumption", '')
        col_name = col_name.replace("Eui", '')
        col_name = col_name.replace("Energy", '')
        col_name = col_name.replace("Percent", '')
        col_name = col_name.replace("Total", '')

        return col_name

    def col_name_to_fuel(self, col_name):

        # list of fuel type
        list_fuel = [
            "electricity",
            "natural gas",
            "site",
        ]

        # initialize
        fueltype = ''

        # search for fuel in col_name
        for fuel in list_fuel:
            if fuel in col_name.lower():
                fueltype = fuel.title()
                break
            else:
                fueltype = ""

        return fueltype

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

        # Add end use group
        parts['enduse_group'] = self.end_use_group(parts['enduse'])

        return parts

    def enduse_col_name_to_enduse(self, col_name):
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

    def shorten_qoi_names(self, col_name):
        col_name = col_name.replace("out.qoi.", '')
        col_name = col_name.replace("maximum_daily_", '')
        col_name = col_name.replace("minimum_daily_", '')
        col_name = col_name.replace("timing_", '')
        col_name = col_name.replace("use_", '')
        col_name = col_name.replace("_w_per_ft2", '')
        col_name = col_name.replace("_hour..hr", '')
        col_name = col_name.replace("_normalized", '')

        return col_name
