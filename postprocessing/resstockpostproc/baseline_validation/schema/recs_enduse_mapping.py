from typing import TypedDict

from resstockpostproc.baseline_validation.plot_helpers.utils import KBTU2KWH
from resstockpostproc.shared_utils.db_column_names import DataCol


class SourceSpec(TypedDict):
    column_name: str
    description: str
    factor: float


class VariableSpec(TypedDict):
    ResStock: SourceSpec | tuple[SourceSpec, ...]
    RECS: SourceSpec | tuple[SourceSpec, ...]


class RECSField(TypedDict):
    column_name: str
    description: str
    factor: float


RECS_ENDUSE_MAP: dict[DataCol, RECSField | tuple[RECSField, ...]] = {
    DataCol.ELECTRICITY_TOTAL: {
        "column_name": "KWH",
        "description": "Total electricity use, in kilowatthours, 2020, including self-generation of solar power",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_SPACE_HEATING: {
        "column_name": "KWHSPH",
        "description": "Electricity used for space heating, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_SPACE_COOLING: {
        "column_name": "KWHCOL",
        "description": "Electricity used for space cooling, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_WATER_HEATING: {
        "column_name": "KWHWTH",
        "description": "Electricity used for water heating, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_REFRIGERATOR: {
        "column_name": "KWHRFG",
        "description": "Electricity used for refrigerators, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_FREEZER: {
        "column_name": "KWHFRZ",
        "description": "Electricity used for freezer, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_COOKING: {
        "column_name": "KWHCOK",
        "description": "Electricity used for cooking, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_PLUG_LOADS: (
        {
            "column_name": "KWHNEC",
            "description": "Electricity usage for other purposes not elsewhere classified in kilowatthours, 2020",
            "factor": 1.0,
        },
        {
            "column_name": "KWHMICRO",
            "description": "Electricity used for Microwave, 2020",
            "factor": 1.0,
        },
        {
            "column_name": "KWHHUM",
            "description": "Electricity used for Humidifier, 2020",
            "factor": 1.0,
        },
    ),
    DataCol.ELECTRICITY_CLOTHES_WASHER: {
        "column_name": "KWHCW",
        "description": "Electricity used for clothes washer, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_CLOTHES_DRYER: {
        "column_name": "KWHCDR",
        "description": "Electricity used for clothes dryer, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_DISHWASHER: {
        "column_name": "KWHDWH",
        "description": "Electricity used for dishwasher, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_LIGHTING: {
        "column_name": "KWHLGT",
        "description": "Electricity used for lighting, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_TELEVISION: {
        "column_name": "KWHTVREL",
        "description": "Electricity used for television, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_HEATING_FANS_PUMPS: {
        "column_name": "KWHAHUHEAT",
        "description": "Electricity used for heating fans and pumps, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_COOLING_FAN_PUMPS: {
        "column_name": "KWHAHUCOL",
        "description": "Electricity used for cooling fans and pumps, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_CEILING_FANS: {
        "column_name": "KWHCFAN",
        "description": "Electricity used for ceiling fans, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_DEHUMIDIFIER: {
        "column_name": "KWHDHUM",
        "description": "Electricity used for dehumidifier, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_POOL_PUMPS: (
        {
            "column_name": "KWHPLPMP",
            "description": "Electricity used for pool pumps, in kilowatthours, 2020",
            "factor": 1.0,
        },
        {
            "column_name": "KWHHTBPMP",
            "description": "Electricity used for hot tub pumps, in kilowatthours, 2020",
            "factor": 1.0,
        },
    ),
    DataCol.ELECTRICITY_POOL_HEATER: {
        "column_name": "KWHHTBHEAT",
        "description": "Electricity used for hot tub heater, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.ELECTRICITY_EV_CHARGING: {
        "column_name": "KWHEVCHRG",
        "description": "Electricity used for electric vehicle charging, in kilowatthours, 2020",
        "factor": 1.0,
    },
    DataCol.NATURAL_GAS_TOTAL: {
        "column_name": "BTUNG",
        "description": "Total natural gas use, in KBTU, 2020 (converted to kWh)",
        "factor": KBTU2KWH,
    },
    DataCol.NATURAL_GAS_SPACE_HEATING: {
        "column_name": "BTUNGSPH",
        "description": "Natural gas used for space heating, in KBTU, 2020 (converted to kWh)",
        "factor": KBTU2KWH,
    },
    DataCol.NATURAL_GAS_WATER_HEATING: {
        "column_name": "BTUNGWTH",
        "description": "Natural gas used for water heating, in KBTU, 2020 (converted to kWh)",
        "factor": KBTU2KWH,
    },
    DataCol.NATURAL_GAS_COOKING: {
        "column_name": "BTUNGCOK",
        "description": "Natural gas used for cooking, in KBTU, 2020 (converted to kWh)",
        "factor": KBTU2KWH,
    },
    DataCol.NATURAL_GAS_CLOTHES_DRYER: {
        "column_name": "BTUNGCDR",
        "description": "Natural gas used for clothes dryer, in KBTU, 2020 (converted to kWh)",
        "factor": KBTU2KWH,
    },
    DataCol.NATURAL_GAS_POOL_HEATER: (
        {
            "column_name": "BTUNGPLHEAT",
            "description": "Natural gas used for pool heater, in KBTU, 2020 (converted to kWh)",
            "factor": KBTU2KWH,
        },
        {
            "column_name": "BTUNGHTBHEAT",
            "description": "Natural gas used for hot tub heater, in KBTU, 2020 (converted to kWh)",
            "factor": KBTU2KWH,
        },
    ),
    DataCol.PROPANE_TOTAL: {
        "column_name": "BTULP",
        "description": "Total propane use, in KBTU, 2020 (converted to kWh)",
        "factor": KBTU2KWH,
    },
    DataCol.PROPANE_SPACE_HEATING: {
        "column_name": "BTULPSPH",
        "description": "Propane used for space heating, in KBTU, 2020 (converted to kWh)",
        "factor": KBTU2KWH,
    },
    DataCol.PROPANE_WATER_HEATING: {
        "column_name": "BTULPWTH",
        "description": "Propane used for water heating, in KBTU, 2020 (converted to kWh)",
        "factor": KBTU2KWH,
    },
    DataCol.PROPANE_COOKING: {
        "column_name": "BTULPCOK",
        "description": "Propane used for cooking, in KBTU, 2020 (converted to kWh)",
        "factor": KBTU2KWH,
    },
    DataCol.PROPANE_CLOTHES_DRYER: {
        "column_name": "BTULPCDR",
        "description": "Propane used for clothes dryer, in KBTU, 2020 (converted to kWh)",
        "factor": KBTU2KWH,
    },
    DataCol.FUEL_OIL_TOTAL: {
        "column_name": "BTUFO",
        "description": "Total fuel oil/kerosene use, in KBTU, 2020 (converted to kWh)",
        "factor": KBTU2KWH,
    },
    DataCol.FUEL_OIL_SPACE_HEATING: {
        "column_name": "BTUFOSPH",
        "description": "Fuel oil/kerosene used for space heating, in KBTU, 2020 (converted to kWh)",
        "factor": KBTU2KWH,
    },
    DataCol.FUEL_OIL_WATER_HEATING: {
        "column_name": "BTUFOWTH",
        "description": "Fuel oil/kerosene used for water heating, in KBTU, 2020 (converted to kWh)",
        "factor": KBTU2KWH,
    },
}


if __name__ == "__main__":
    electricity_enduses = [col.value for col in DataCol if col.value.startswith("electricity")]
    print(f"List of RECS end-use mappings ({len(electricity_enduses)}):")
