
from __future__ import annotations

from enum import StrEnum
from typing import  TypedDict
from pydantic import BaseModel


class NoExtraModel(BaseModel):
    class Config:
        extra = "forbid"
        frozen = True


class DBSchema(StrEnum):
    OEDI_NEW = "resstock_oedi_new"
    OEDI = "resstock_oedi_vu"


class DataCol(StrEnum):
    ELECTRICITY_TOTAL = "electricity_total"
    ELECTRICITY_SPACE_HEATING = "electricity_space_heating"
    ELECTRICITY_HEATING_FANS_PUMPS = "electricity_heating_fans_pumps"
    ELECTRICITY_SPACE_COOLING = "electricity_space_cooling"
    ELECTRICITY_WATER_HEATING = "electricity_water_heating"
    ELECTRICITY_REFRIGERATOR = "electricity_refrigerator"
    ELECTRICITY_FREEZER = "electricity_freezer"
    ELECTRICITY_COOKING = "electricity_cooking"
    ELECTRICITY_PLUG_LOADS = "electricity_plug_load"
    ELECTRICITY_CLOTHES_WASHER = "electricity_clothes_washer"
    ELECTRICITY_CLOTHES_DRYER = "electricity_clothes_dryer"
    ELECTRICITY_DISHWASHER = "electricity_dishwasher"
    ELECTRICITY_LIGHTING = "electricity_lighting"
    ELECTRICITY_TELEVISION = "electricity_television"
    ELECTRICITY_FAN_PUMPS = "electricity_fan_pumps"
    ELECTRICITY_COOLING_FAN_PUMPS = "electricity_cooling_fan_pumps"
    ELECTRICITY_CEILING_FANS = "electricity_ceiling_fan"
    ELECTRICITY_DEHUMIDIFIER = "electricity_dehumidifier"
    ELECTRICITY_POOL_PUMPS = "electricity_pool_pumps"
    ELECTRICITY_POOL_HEATER = "electricity_pool_heater"
    ELECTRICITY_EV_CHARGING = "electricity_ev_charging"
    NATURAL_GAS_TOTAL = "natural_gas_total"
    NATURAL_GAS_SPACE_HEATING = "natural_gas_space_heating"
    NATURAL_GAS_WATER_HEATING = "natural_gas_water_heating"
    NATURAL_GAS_COOKING = "natural_gas_cooking"
    NATURAL_GAS_CLOTHES_DRYER = "natural_gas_clothes_dryer"
    NATURAL_GAS_POOL_HEATER = "natural_gas_pool_heater"
    PROPANE_TOTAL = "propane_total"
    PROPANE_SPACE_HEATING = "propane_space_heating"
    PROPANE_WATER_HEATING = "propane_water_heating"
    PROPANE_COOKING = "propane_cooking"
    PROPANE_CLOTHES_DRYER = "propane_clothes_dryer"
    FUEL_OIL_TOTAL = "fuel_oil_total"
    FUEL_OIL_SPACE_HEATING = "fuel_oil_space_heating"
    FUEL_OIL_WATER_HEATING = "fuel_oil_water_heating"
    STATE = "state"
    VACANCY = "vacancy"
    COUNTY = "county"
    VINTAGE = "vintage"
    BUILDING_TYPE = "geometry_building_type_recs"
    HEATING_FUEL = "heating_fuel"
    CENSUS_DIVISION = "census_division_recs"
    BLDG_AMERICA_CLIMATE_ZONE = "building_america_climate_zone"
    EV_OWNERSHIP = "electric_vehicle_ownership"
    UNITS_COUNT = "units_count"
    OUTDOOR_DRYBULB_TEMP = "outdoor_drybulb_temp"
    TIMESTAMP = "timestamp"


_RESSTOCK_ENDUSE_COL_MAP: dict[DBSchema, dict[DataCol, None | str | tuple[str, ...]]] = {
    DBSchema.OEDI_NEW: {
        DataCol.ELECTRICITY_TOTAL: "out.electricity.total.energy_consumption..kwh",
        DataCol.ELECTRICITY_SPACE_HEATING: (
            "out.electricity.heating.energy_consumption..kwh",
            "out.electricity.heating_hp_bkup.energy_consumption..kwh",
        ),
        DataCol.ELECTRICITY_HEATING_FANS_PUMPS: "out.electricity.heating_fans_pumps.energy_consumption..kwh",
        DataCol.ELECTRICITY_SPACE_COOLING: "out.electricity.cooling.energy_consumption..kwh",
        DataCol.ELECTRICITY_WATER_HEATING: (
            "out.electricity.hot_water.energy_consumption..kwh",
            "out.electricity.hot_water_solar_th.energy_consumption..kwh",
        ),
        DataCol.ELECTRICITY_REFRIGERATOR: "out.electricity.refrigerator.energy_consumption..kwh",
        DataCol.ELECTRICITY_FREEZER: "out.electricity.freezer.energy_consumption..kwh",
        DataCol.ELECTRICITY_COOKING: "out.electricity.range_oven.energy_consumption..kwh",
        DataCol.ELECTRICITY_PLUG_LOADS: "out.electricity.plug_loads.energy_consumption..kwh",
        DataCol.ELECTRICITY_CLOTHES_WASHER: "out.electricity.clothes_washer.energy_consumption..kwh",
        DataCol.ELECTRICITY_CLOTHES_DRYER: "out.electricity.clothes_dryer.energy_consumption..kwh",
        DataCol.ELECTRICITY_DISHWASHER: "out.electricity.dishwasher.energy_consumption..kwh",
        DataCol.ELECTRICITY_LIGHTING: (
            "out.electricity.lighting_interior.energy_consumption..kwh",
            "out.electricity.lighting_exterior.energy_consumption..kwh",
            "out.electricity.lighting_garage.energy_consumption..kwh",
        ),
        DataCol.ELECTRICITY_TELEVISION: "out.electricity.television.energy_consumption..kwh",
        DataCol.ELECTRICITY_COOLING_FAN_PUMPS: "out.electricity.cooling_fans_pumps.energy_consumption..kwh",
        DataCol.ELECTRICITY_CEILING_FANS: (
            "out.electricity.ceiling_fan.energy_consumption..kwh",
        ),
        DataCol.ELECTRICITY_DEHUMIDIFIER: None,
        DataCol.ELECTRICITY_POOL_PUMPS: "out.electricity.pool_pump.energy_consumption..kwh",
        DataCol.ELECTRICITY_POOL_HEATER: "out.electricity.pool_heater.energy_consumption..kwh",
        DataCol.ELECTRICITY_EV_CHARGING: "out.electricity.ev_charging.energy_consumption..kwh",
        DataCol.NATURAL_GAS_TOTAL: "out.natural_gas.total.energy_consumption..kwh",
        DataCol.NATURAL_GAS_SPACE_HEATING: "out.natural_gas.heating.energy_consumption..kwh",
        DataCol.NATURAL_GAS_WATER_HEATING: "out.natural_gas.hot_water.energy_consumption..kwh",
        DataCol.NATURAL_GAS_COOKING: "out.natural_gas.range_oven.energy_consumption..kwh",
        DataCol.NATURAL_GAS_CLOTHES_DRYER: "out.natural_gas.clothes_dryer.energy_consumption..kwh",
        DataCol.NATURAL_GAS_POOL_HEATER: "out.natural_gas.pool_heater.energy_consumption..kwh",
        DataCol.PROPANE_TOTAL: "out.propane.total.energy_consumption..kwh",
        DataCol.PROPANE_SPACE_HEATING: "out.propane.heating.energy_consumption..kwh",
        DataCol.PROPANE_WATER_HEATING: "out.propane.hot_water.energy_consumption..kwh",
        DataCol.PROPANE_COOKING: "out.propane.range_oven.energy_consumption..kwh",
        DataCol.PROPANE_CLOTHES_DRYER: "out.propane.clothes_dryer.energy_consumption..kwh",
        DataCol.FUEL_OIL_TOTAL: "out.fuel_oil.total.energy_consumption..kwh",
        DataCol.FUEL_OIL_SPACE_HEATING: "out.fuel_oil.heating.energy_consumption..kwh",
        DataCol.FUEL_OIL_WATER_HEATING: "out.fuel_oil.hot_water.energy_consumption..kwh",
        DataCol.OUTDOOR_DRYBULB_TEMP: "out.outdoor_air_drybulb_temp..c",
    },
    DBSchema.OEDI: {
        DataCol.ELECTRICITY_TOTAL: "out.electricity.total.energy_consumption",
        DataCol.ELECTRICITY_SPACE_HEATING: (
            "out.electricity.heating.energy_consumption",
            "out.electricity.heating_hp_bkup.energy_consumption",
        ),
        DataCol.ELECTRICITY_HEATING_FANS_PUMPS: "out.electricity.heating_fans_pumps.energy_consumption",
        DataCol.ELECTRICITY_SPACE_COOLING: "out.electricity.cooling.energy_consumption",
        DataCol.ELECTRICITY_WATER_HEATING: "out.electricity.hot_water.energy_consumption",
        DataCol.ELECTRICITY_REFRIGERATOR: "out.electricity.refrigerator.energy_consumption",
        DataCol.ELECTRICITY_FREEZER: "out.electricity.freezer.energy_consumption",
        DataCol.ELECTRICITY_COOKING: "out.electricity.range_oven.energy_consumption",
        DataCol.ELECTRICITY_PLUG_LOADS: "out.electricity.plug_loads.energy_consumption",
        DataCol.ELECTRICITY_CLOTHES_WASHER: "out.electricity.clothes_washer.energy_consumption",
        DataCol.ELECTRICITY_CLOTHES_DRYER: "out.electricity.clothes_dryer.energy_consumption",
        DataCol.ELECTRICITY_DISHWASHER: "out.electricity.dishwasher.energy_consumption",
        DataCol.ELECTRICITY_LIGHTING: (
            "out.electricity.lighting_interior.energy_consumption",
            "out.electricity.lighting_exterior.energy_consumption",
            "out.electricity.lighting_garage.energy_consumption",
        ),
        DataCol.ELECTRICITY_TELEVISION: None,
        DataCol.ELECTRICITY_COOLING_FAN_PUMPS: "out.electricity.cooling_fans_pumps.energy_consumption",
        DataCol.ELECTRICITY_CEILING_FANS: (
            "out.electricity.ceiling_fan.energy_consumption",
        ),
        DataCol.ELECTRICITY_DEHUMIDIFIER: None,
        DataCol.ELECTRICITY_POOL_PUMPS: "out.electricity.pool_pump.energy_consumption",
        DataCol.ELECTRICITY_POOL_HEATER: "out.electricity.pool_heater.energy_consumption",
        DataCol.ELECTRICITY_EV_CHARGING: None,
        DataCol.NATURAL_GAS_TOTAL: "out.natural_gas.total.energy_consumption",
        DataCol.NATURAL_GAS_SPACE_HEATING: "out.natural_gas.heating.energy_consumption",
        DataCol.NATURAL_GAS_WATER_HEATING: "out.natural_gas.hot_water.energy_consumption",
        DataCol.NATURAL_GAS_COOKING: "out.natural_gas.range_oven.energy_consumption",
        DataCol.NATURAL_GAS_CLOTHES_DRYER: "out.natural_gas.clothes_dryer.energy_consumption",
        DataCol.NATURAL_GAS_POOL_HEATER: "out.natural_gas.pool_heater.energy_consumption",
        DataCol.PROPANE_TOTAL: "out.propane.total.energy_consumption",
        DataCol.PROPANE_SPACE_HEATING: "out.propane.heating.energy_consumption",
        DataCol.PROPANE_WATER_HEATING: "out.propane.hot_water.energy_consumption",
        DataCol.PROPANE_COOKING: "out.propane.range_oven.energy_consumption",
        DataCol.PROPANE_CLOTHES_DRYER: "out.propane.clothes_dryer.energy_consumption",
        DataCol.FUEL_OIL_TOTAL: "out.fuel_oil.total.energy_consumption",
        DataCol.FUEL_OIL_SPACE_HEATING: "out.fuel_oil.heating.energy_consumption",
        DataCol.FUEL_OIL_WATER_HEATING: "out.fuel_oil.hot_water.energy_consumption",
        DataCol.OUTDOOR_DRYBULB_TEMP: "out.outdoor_air_dryblub_temp.c",
    },
}


class DBCharCol(NoExtraModel):
    STATE: str
    VACANCY: str
    COUNTY: str
    VINTAGE: str
    BUILDING_TYPE: str
    HEATING_FUEL: str
    CENSUS_DIVISION: str
    BLDG_AMERICA_CLIMATE_ZONE: str
    EV_OWNERSHIP: str
    ISO_RTO_REGION: str
    TIMESTAMP: str


_RESSTOCK_CHAR_COL_MAP: dict[DBSchema, DBCharCol] = {
    DBSchema.OEDI_NEW: DBCharCol(
        STATE="in.state",
        VACANCY="in.vacancy_status",
        COUNTY="in.county",
        VINTAGE="in.vintage",
        BUILDING_TYPE="in.geometry_building_type_recs",
        HEATING_FUEL="in.heating_fuel",
        CENSUS_DIVISION="in.census_division",
        BLDG_AMERICA_CLIMATE_ZONE="in.building_america_climate_zone",
        EV_OWNERSHIP="in.electric_vehicle_ownership",
        ISO_RTO_REGION="in.iso_rto_region",
        TIMESTAMP="timestamp",

    ),
    DBSchema.OEDI: DBCharCol(
        STATE="in.state",
        VACANCY="in.vacancy_status",
        COUNTY="in.county",
        VINTAGE="in.vintage",
        BUILDING_TYPE="in.geometry_building_type_recs",
        HEATING_FUEL="in.heating_fuel",
        CENSUS_DIVISION="in.census_division",
        BLDG_AMERICA_CLIMATE_ZONE="in.building_america_climate_zone",
        EV_OWNERSHIP="in.electric_vehicle_ownership",
        ISO_RTO_REGION="in.iso_rto_region",
        TIMESTAMP="timestamp",
    ),
}


def get_db_enduse_colnames_map(db_schema: DBSchema):
    return _RESSTOCK_ENDUSE_COL_MAP[db_schema]

def get_db_characteristics_colnames(db_schema: DBSchema):
    return _RESSTOCK_CHAR_COL_MAP[db_schema]