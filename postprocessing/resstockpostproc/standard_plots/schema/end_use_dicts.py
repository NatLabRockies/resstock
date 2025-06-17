from itertools import product

EnduseFuelToPattern = {"Electricity": "", "Natural Gas": "/", "Propane": "x", "Fuel Oil": "+"}
EnduseGroupToColor = {
    "Heating": "#EF1C21",
    "Heating Fans Pumps": "#EF1C21",
    "Cooling": "#0071BD",
    "Cooling Fans Pumps": "#EF1C21",
    "Lighting": "#F7DF10",
    "Appliances": "#4A4D4A",
    "Electric Vehicle Charging": "Blue",
    "Vent Fan": "#FF79AD",
    "Heating Heat Pump Backup": "#d95f0e",
    "Hot Water": "#FFB239",
    "Miscellaneous": "#B5B2B5",
}
EnduseToColor = {}
for enduse_group, fuel in product(EnduseGroupToColor.keys(), EnduseFuelToPattern.keys()):
    EnduseToColor[enduse_group + ", " + fuel] = EnduseGroupToColor[enduse_group]
EnduseToPattern = {}
for enduse_group, fuel in product(EnduseGroupToColor.keys(), EnduseFuelToPattern.keys()):
    EnduseToPattern[enduse_group + ", " + fuel] = EnduseFuelToPattern[fuel]


EnduseGroupToEnduses = {
    "Electric Vehicle Charging, Electricity": ["out.electricity.electric_vehicle_charging.energy_consumption.kwh"],
    "Hot Water, Electricity": [
        "out.electricity.hot_water.energy_consumption.kwh",
    ],
    "Hot Water, Natural Gas": [
        "out.natural_gas.hot_water.energy_consumption.kwh",
    ],
    "Hot Water, Fuel Oil": [
        "out.fuel_oil.hot_water.energy_consumption.kwh",
    ],
    "Hot Water, Propane": ["out.propane.hot_water.energy_consumption.kwh"],
    "Heating Heat Pump Backup, Electricity": [
        "out.electricity.heating_heat_pump_backup.energy_consumption.kwh",
        "out.electricity.heating_heat_pump_backup_fans_pumps.energy_consumption.kwh",
    ],
    "Heating Heat Pump Backup, Natural Gas": [
        "out.natural_gas.heating_heat_pump_backup.energy_consumption.kwh",
    ],
    "Heating Heat Pump Backup, Fuel Oil": [
        "out.fuel_oil.heating_heat_pump_backup.energy_consumption.kwh",
    ],
    "Heating Heat Pump Backup, Propane": ["out.propane.heating_heat_pump_backup.energy_consumption.kwh"],
    "Heating Fans Pumps, Electricity": ["out.electricity.heating_fans_pumps_m_btu.energy_consumption.kwh"],
    "Heating, Electricity": [
        "out.electricity.heating.energy_consumption.kwh",
    ],
    "Heating, Natural Gas": [
        "out.natural_gas.heating.energy_consumption.kwh",
    ],
    "Heating, Fuel Oil": [
        "out.fuel_oil.heating.energy_consumption.kwh",
    ],
    "Heating, Propane": ["out.propane.heating.energy_consumption.kwh"],
    "Cooling Fans Pumps, Electricity": ["out.electricity.cooling_fans_pumps_m_btu.energy_consumption.kwh"],
    "Cooling, Electricity": [
        "out.electricity.cooling.energy_consumption.kwh",
    ],
    "Lighting, Electricity": [
        "out.electricity.lighting_interior.energy_consumption.kwh",
        "out.electricity.lighting_exterior.energy_consumption.kwh",
        "out.electricity.lighting_garage.energy_consumption.kwh",
    ],
    "Lighting, Natural Gas": [
        "out.natural_gas.lighting.energy_consumption.kwh",
    ],
    "Lighting, Fuel Oil": [
        "out.fuel_oil.lighting.energy_consumption.kwh",
        "out.propane.lighting.energy_consumption.kwh",
    ],
    "Vent Fan, Electricity": [
        "out.electricity.mechanical_ventilation.energy_consumption.kwh",
        "out.electricity.ceiling_fan.energy_consumption.kwh",
    ],
    "Miscellaneous, Electricity": [
        "out.electricity.plug_loads.energy_consumption.kwh",
        "out.electricity.pool_pump.energy_consumption.kwh",
        "out.electricity.pool_heater.energy_consumption.kwh",
        "out.electricity.permanent_spa_pump.energy_consumption.kwh",
        "out.electricity.permanent_spa_heater.energy_consumption.kwh",
        "out.electricity.well_pump.energy_consumption.kwh",
    ],
    "Miscellaneous, Natural Gas": [
        "out.natural_gas.fireplace.energy_consumption.kwh",
        "out.natural_gas.grill.energy_consumption.kwh",
        "out.natural_gas.permanent_spa_heater.energy_consumption.kwh",
        "out.natural_gas.pool_heater.energy_consumption.kwh",
        "out.natural_gas.mech_vent_preheating.energy_consumption.kwh",
        "out.natural_gas.generator.energy_consumption.kwh",
    ],
    "Miscellaneous, Fuel Oil": [
        "out.fuel_oil.fireplace.energy_consumption.kwh",
        "out.fuel_oil.grill.energy_consumption.kwh",
        "out.fuel_oil.mech_vent_preheating.energy_consumption.kwh",
        "out.fuel_oil.generator.energy_consumption.kwh",
    ],
    "Miscellaneous, Propane": [
        "out.propane.fireplace.energy_consumption.kwh",
        "out.propane.grill.energy_consumption.kwh",
        "out.propane.mech_vent_preheating.energy_consumption.kwh",
        "out.propane.generator.energy_consumption.kwh",
    ],
    "Appliances, Electricity": [
        "out.electricity.clothes_dryer.energy_consumption.kwh",
        "out.electricity.clothes_washer.energy_consumption.kwh",
        "out.electricity.dishwasher.energy_consumption.kwh",
        "out.electricity.freezer.energy_consumption.kwh",
        "out.electricity.refrigerator.energy_consumption.kwh",
        "out.electricity.range_oven.energy_consumption.kwh",
    ],
    "Appliances, Natural Gas": [
        "out.natural_gas.clothes_dryer.energy_consumption.kwh",
        "out.natural_gas.range_oven.energy_consumption.kwh",
    ],
    "Appliances, Fuel Oil": [
        "out.fuel_oil.clothes_dryer.energy_consumption.kwh",
        "out.fuel_oil.range_oven.energy_consumption.kwh",
    ],
    "Appliances, Propane": [
        "out.propane.clothes_dryer.energy_consumption.kwh",
        "out.propane.range_oven.energy_consumption.kwh",
    ],
}
