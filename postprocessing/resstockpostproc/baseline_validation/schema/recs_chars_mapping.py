from typing import TypedDict
from resstockpostproc.shared_utils.db_column_names import DataCol


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
            "mapping": {
                "<1940": "<1950",
                "1940s": "<1950",
                "1950s": "1950s",
                "1960s": "1960s",
                "1970s": "1970s",
                "1980s": "1980s",
                "1990s": "1990s",
                "2000s": "2000s",
                "2010s": "2010s",
            },
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
            },
        },
    },
    DataCol.BUILDING_TYPE: {
        "ResStock": {"column_name": "in.geometry_building_type_recs", "mapping": PartialMap({})},
        "RECS": {
            "column_name": "TYPEHUQ",
            "mapping": {
                1: "Mobile Home",
                2: "Single-Family Detached",
                3: "Single-Family Attached",
                4: "Multi-Family with 2 - 4 Units",
                5: "Multi-Family with 5+ Units",
            },
        },
    },
    DataCol.HEATING_FUEL: {
        "ResStock": {"column_name": "in.heating_fuel", "mapping": PartialMap({})},
        "RECS": {
            "column_name": "FUELHEAT",
            "mapping": {
                -2: "None",
                1: "Natural Gas",
                2: "Propane",
                3: "Fuel Oil",
                5: "Electricity",
                7: "Wood",
                99: "Other Fuel",
            },
        },
    },
    DataCol.CENSUS_DIVISION: {
        "ResStock": {"column_name": "in.census_division_recs", "mapping": PartialMap({})},
        "RECS": {"column_name": "DIVISION", "mapping": PartialMap({})},
    },
    DataCol.CLIMATE_ZONE: {
        "ResStock": {"column_name": "in.building_america_climate_zone", "mapping": PartialMap({})},
        "RECS": {
            "column_name": "BA_climate",
            "mapping": PartialMap({"Very-Cold": "Very Cold"}),
        },
    },
    DataCol.EV_OWNERSHIP: {
        "ResStock": {"column_name": "in.electric_vehicle_ownership", "mapping": PartialMap({})},
        "RECS": {
            "column_name": "ELECVEH",
            "mapping": {
                1: "Yes",
                0: "No",
            },
        },
    },
    DataCol.STATE: {
        "ResStock": {"column_name": "in.state", "mapping": PartialMap({})},
        "RECS": {
            "column_name": "state_postal",
            "mapping": PartialMap({}),
        },
    },
}
