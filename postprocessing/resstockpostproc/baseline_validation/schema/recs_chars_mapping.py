from typing import TypedDict
from resstockpostproc.shared_utils.db_column_names import DataCol, DBCharCol

class PartialMap(dict):
    def __missing__(self, key):
        return key

class MapSpec(TypedDict):
    column_name: str
    mapping: dict[str | int, str] | PartialMap


class VariableSpec(TypedDict):
    ResStock: MapSpec 
    RECS: MapSpec


RECS_CHARS_MAPPING: dict[str, VariableSpec] = {
    DataCol.VINTAGE: {
        "ResStock": {
            "column_name": "in.vintage",
            "mapping": PartialMap({
                "<1940": "<1950",
                "1940s": "<1950"
            }),
        },
        "RECS": {
            "column_name": "YEARMADERANGE",
            "mapping": {
                1: "<1950",
                2: "1950s",
                3: "1960s",
                4: "1970s",
                5: "1980s",
                6: "1990s",
                7: "2000s",
                8: "2010s",
                9: "2010s",
            }
        },
    },
    DataCol.BUILDING_TYPE: {
        "ResStock": {
            "column_name": "in.geometry_building_type_recs",
            "mapping": PartialMap({})
        },
        "RECS": {
            "column_name": "TYPEHUQ",
            "mapping": {
                1: "Mobile Home",
                2: "Single-Family Detached",
                3: "Single-Family Attached",
                4: "Multi-Family with 2 - 4 Units",
                5: "Multi-Family with 5+ Units",
            }
        },
    },
    DataCol.HEATING_FUEL: {
        "ResStock": {
            "column_name": "in.heating_fuel",
            "mapping": {
                "Natural Gas": "Natural Gas",
                "Propane": "Propane",
                "Fuel Oil": "Fuel Oil",
                "Electricity": "Electricity",
            }
        },
        "RECS": {
            "column_name": "FUELHEAT",
            "mapping": {
                1: "Natural Gas",
                2: "Propane",
                3: "Fuel Oil",
                4: "Electricity",
            }
        },
    },
    DataCol.CENSUS_DIVISION: {
        "ResStock": {
            "column_name": "in.census_division",
            "mapping": PartialMap({})
        },
        "RECS": {
            "column_name": "DIVISION",
            "mapping": PartialMap({})
        },
    },
    DataCol.BLDG_AMERICA_CLIMATE_ZONE: {
        "ResStock": {
            "column_name": "in.building_america_climate_zone",
            "mapping": PartialMap({})
        },
        "RECS": {
            "column_name": "BA_climate",
            "mapping": PartialMap({}),
        },
    },
    DataCol.EV_OWNERSHIP: {
        "ResStock": {
            "column_name": "in.electric_vehicle_ownership",
            "mapping": {
                "Yes": "Has EV",
                "No": "No EV",
            }
        },
        "RECS": {
            "column_name": "ELECVEH",
            "mapping": {
                1: "Has EV",
                0: "No EV",
            }
        },
    },
    DataCol.STATE: {
        "ResStock": {
            "column_name": "in.state",
            "mapping": PartialMap({})
        },
        "RECS": {
            "column_name": "state_postal",
            "mapping": PartialMap({}),
        },
    },
}
