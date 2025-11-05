
from __future__ import annotations

from enum import Enum
from pathlib import Path
from typing import Literal

import yaml
from pydantic import BaseModel, Field, field_validator


class NoExtraModel(BaseModel):
    class Config:
        extra = "forbid"
        frozen = True

class DBCol(NoExtraModel):
    ELECTRICITY_TOTAL: str
    NATURAL_GAS_TOTAL: str
    COUNTY: str
    STATE: str
    TIMESTAMP: str


_dbschema_to_column_names = {
    "resstock_oedi_new": DBCol(
        ELECTRICITY_TOTAL="out.electricity.total.energy_consumption..kwh",
        NATURAL_GAS_TOTAL="out.natural_gas.total.energy_consumption..kwh",
        COUNTY="in.county",
        STATE="in.state",
        TIMESTAMP="timestamp"
    ),
    "resstock_oedi": DBCol(
        ELECTRICITY_TOTAL="out.electricity.total.energy_consumption",
        NATURAL_GAS_TOTAL="out.natural_gas.total.energy_consumption",
        COUNTY="in.county",
        STATE="in.state",
        TIMESTAMP="timestamp"
    ),
    "resstock_oedi_vu": DBCol(
        ELECTRICITY_TOTAL="out.electricity.total.energy_consumption",
        NATURAL_GAS_TOTAL="out.natural_gas.total.energy_consumption",
        COUNTY="in.county",
        STATE="in.state",
        TIMESTAMP="timestamp"
    )
}

def get_db_column_names(db_schema: str) -> DBCol:
    return _dbschema_to_column_names[db_schema]