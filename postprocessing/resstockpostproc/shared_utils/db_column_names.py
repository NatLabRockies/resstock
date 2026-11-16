
from __future__ import annotations

from enum import StrEnum
from pydantic import BaseModel


class NoExtraModel(BaseModel):
    class Config:
        extra = "forbid"
        frozen = True


class DBSchema(StrEnum):
    OEDI_NEW = "resstock_oedi_new"
    OEDI = "resstock_oedi_vu"


class DataCol(StrEnum):
    ALL = "all"  # Sentinel: all available quantities/enduses
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
    CLIMATE_ZONE = "building_america_climate_zone"
    EV_OWNERSHIP = "electric_vehicle_ownership"
    UNITS_COUNT = "units_count"
    OUTDOOR_DRYBULB_TEMP = "outdoor_drybulb_temp"
    UTILITY = "utility"
    TIMESTAMP = "timestamp"

    @property
    def label(self) -> str:
        """Human-readable display name for plot titles and labels.

        Fuel totals: "Electricity", "Natural Gas", etc.
        End uses: "Space Heating Electricity", "Cooking Natural Gas", etc.
        """
        for prefix, fuel_name in _FUEL_PREFIXES.items():
            if self.value.startswith(prefix + "_"):
                enduse = self.value[len(prefix) + 1:]
                if enduse == "total":
                    return fuel_name
                enduse_name = _ENDUSE_OVERRIDES.get(enduse, enduse.replace("_", " ").title())
                return f"{enduse_name} {fuel_name}"
        return self.value.replace("_", " ").title()

    @property
    def penetration_label(self) -> str:
        """Label for usage-share titles and end-use bar labels.

        Electricity-only end-uses drop the "Electric" prefix (e.g. "Refrigerator", "Lighting").
        Multi-fuel end-uses keep the fuel adjective (e.g. "Electric Space Heating", "Natural Gas Cooking").
        Fuel totals use the noun form: "Electricity", "Natural Gas".
        """
        for prefix, adj in _FUEL_ADJECTIVES.items():
            if self.value.startswith(prefix + "_"):
                enduse = self.value[len(prefix) + 1:]
                if enduse == "total":
                    return _FUEL_PREFIXES[prefix]
                enduse_name = _ENDUSE_OVERRIDES.get(enduse, enduse.replace("_", " ").title())
                if prefix == "electricity" and enduse in _ELECTRICITY_ONLY_ENDUSES:
                    return enduse_name
                return f"{adj} {enduse_name}"
        return self.value.replace("_", " ").title()


_FUEL_PREFIXES = {
    "electricity": "Electricity",
    "natural_gas": "Natural Gas",
    "propane": "Propane",
    "fuel_oil": "Fuel Oil",
}

_ENDUSE_OVERRIDES = {
    "ev_charging": "EV Charging",
    "fan_pumps": "Fans & Pumps",
    "heating_fans_pumps": "Heating Fans & Pumps",
    "cooling_fan_pumps": "Cooling Fans & Pumps",
    "plug_load": "Plug Loads",
    "ceiling_fan": "Ceiling Fans",
}

_FUEL_ADJECTIVES = {
    "electricity": "Electric",
    "natural_gas": "Natural Gas",
    "propane": "Propane",
    "fuel_oil": "Fuel Oil",
}


def _compute_electricity_only_enduses() -> set[str]:
    """Identify end-uses that exist only as electricity (no gas/propane/oil variant)."""
    enduse_fuels: dict[str, set[str]] = {}
    for dc in DataCol:
        for fuel in _FUEL_PREFIXES:
            if dc.value.startswith(fuel + "_"):
                enduse = dc.value[len(fuel) + 1:]
                if enduse != "total":
                    enduse_fuels.setdefault(enduse, set()).add(fuel)
    return {e for e, fuels in enduse_fuels.items() if fuels == {"electricity"}}


_ELECTRICITY_ONLY_ENDUSES = _compute_electricity_only_enduses()


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
        # NOTE: upstream Athena column is literally misspelled 'dryblub' for the
        # resstock_2024_amy2018_release_2_by_state_vu table (OEDI_VU schema).
        # Do NOT "fix" the spelling — it will break LRD plots against that table.
        # Verified against live Athena on 2026-04-22.
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