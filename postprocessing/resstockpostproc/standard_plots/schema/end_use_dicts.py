EnduseFuelToPattern = {"Electricity": "", "Natural Gas": "/", "Propane": "x", "Fuel Oil": "+"}
EnduseGroupToColor = {
    "Heating": "#EF1C21",
    "Heating Fans Pumps": "#EF1C21",
    "Cooling": "#0071BD",
    "Cooling Fans Pumps": "#EF1C21",
    "Lighting": "#F7DF10",
    "Appliances": "#4A4D4A",
    "Electric Vehicle Charging": "#C1EE86",
    "Vent Fan": "#FF79AD",
    "Heating Heat Pump Backup": "#d95f0e",
    "Hot Water": "#FFB239",
    "Miscellaneous": "#B5B2B5",
    "Generation": "#9ECE42",
}
fuel_colors = {
    "electricity": "#EE9521",  # EE9521 orange
    "natural_gas": "#0079C2",  # 0079C2 blue
    "propane": "#A16911",  # A16911  # brown
    "fuel_oil": "#626D72",  # 626D72 gray
}
summer_winter_color = {
    "summer": "#EF1C21",
    "winter": "#0079C2",
}

column2color = {
    f"{enduse_group}, {fuel}": EnduseGroupToColor[enduse_group]
    for enduse_group in EnduseGroupToColor
    for fuel in EnduseFuelToPattern
}
column2pattern = {
    f"{enduse_group}, {fuel}": EnduseFuelToPattern[fuel]
    for enduse_group in EnduseGroupToColor
    for fuel in EnduseFuelToPattern
}

unit_separator = '.'
column2color.update(
    {
        f"out.bills.{fuel}{unit_separator}usd": fuel_colors.get(fuel, "#3A4246")
        for fuel in ["electricity", "natural_gas", "propane", "fuel_oil"]
    }
)
column2color.update(
    {
        f"out.{fuel}.total.energy_consumption{unit_separator}kwh": fuel_colors.get(fuel, "#3A4246")
        for fuel in ["electricity", "natural_gas", "propane", "fuel_oil"]
    }
)
column2color.update(
    {
        f"out.unmet_hours.{heat_cool.lower()}{unit_separator}hour": EnduseGroupToColor.get(heat_cool, "#3A4246")
        for heat_cool in ["Heating", "Cooling"]
    }
)
column2color.update(
    {
        f"out.load.{load_type.lower()}.energy_delivered{unit_separator}kbtu": EnduseGroupToColor.get(load_type, "#3A4246")
        for load_type in ["Heating", "Cooling", "Hot Water"]
    }
)
column2color.update(
    {
        f"out.electricity.{summer_winter.lower()}.peak{unit_separator}kw": summer_winter_color.get(summer_winter, "#3A4246")
        for summer_winter in ["summer", "winter"]
    }
)
column2color.update(
    {
        f"out.load.{load_type.lower()}.peak{unit_separator}kbtu_hr": EnduseGroupToColor.get(load_type, "#3A4246")
        for load_type in ["Heating", "Cooling"]
    }
)
column2color.update(
    {
        f"out.emissions.{fuel}.lrmer_mid_case_25{unit_separator}co2e_kg": fuel_colors.get(fuel, "#3A4246")
        for fuel in ["electricity", "natural_gas", "propane", "fuel_oil"]
    }
)


column2color["out.panel.load.occupied_capacity.2023_nec_existing_dwelling_load_based.a"] = "#0079C2"
column2color["out.panel.load.headroom_capacity.2023_nec_existing_dwelling_load_based.a"] = "#7DA544"
column2color["in.electric_panel_service_rating"] = "#626D72"
column2color["out.panel.breaker_space.occupied.count"] = "#0079C2"
column2color["out.panel.breaker_space.headroom.count"] = "#7DA544"
column2color["in.electric_panel_breaker_space_total_count"] = "#626D72"

EnduseGroupToEnduses = {
    "Generation, Electricity": [
        f"out.electricity.pv.energy_consumption{unit_separator}kwh",
        f"out.electricity.generator.energy_consumption{unit_separator}kwh",
        f"out.electricity.battery.energy_consumption{unit_separator}kwh",
    ],
    "Electric Vehicle Charging, Electricity": [
        f"out.electricity.ev_charging.energy_consumption{unit_separator}kwh",
    ],
    "Hot Water, Electricity": [
        f"out.electricity.hot_water.energy_consumption{unit_separator}kwh",
    ],
    "Hot Water, Natural Gas": [
        f"out.natural_gas.hot_water.energy_consumption{unit_separator}kwh",
    ],
    "Hot Water, Fuel Oil": [
        f"out.fuel_oil.hot_water.energy_consumption{unit_separator}kwh",
    ],
    "Hot Water, Propane": [
        f"out.propane.hot_water.energy_consumption{unit_separator}kwh",
    ],
    "Heating Heat Pump Backup, Electricity": [
        f"out.electricity.heating_hp_bkup.energy_consumption{unit_separator}kwh",
        f"out.electricity.heating_hp_bkup_fa.energy_consumption{unit_separator}kwh",
    ],
    "Heating Heat Pump Backup, Natural Gas": [
        f"out.natural_gas.heating_hp_bkup.energy_consumption{unit_separator}kwh",
    ],
    "Heating Heat Pump Backup, Fuel Oil": [
        f"out.fuel_oil.heating_hp_bkup.energy_consumption{unit_separator}kwh",
    ],
    "Heating Heat Pump Backup, Propane": [
        f"out.propane.heating_hp_bkup.energy_consumption{unit_separator}kwh",
    ],
    "Heating Fans Pumps, Electricity": [
        f"out.electricity.heating_fans_pumps.energy_consumption{unit_separator}kwh",
    ],
    "Heating, Electricity": [
        f"out.electricity.heating.energy_consumption{unit_separator}kwh",
    ],
    "Heating, Natural Gas": [
        f"out.natural_gas.heating.energy_consumption{unit_separator}kwh",
    ],
    "Heating, Fuel Oil": [
        f"out.fuel_oil.heating.energy_consumption{unit_separator}kwh",
    ],
    "Heating, Propane": [
        f"out.propane.heating.energy_consumption{unit_separator}kwh",
    ],
    "Cooling Fans Pumps, Electricity": [
        f"out.electricity.cooling_fans_pumps.energy_consumption{unit_separator}kwh",
    ],
    "Cooling, Electricity": [
        f"out.electricity.cooling.energy_consumption{unit_separator}kwh",
    ],
    "Lighting, Electricity": [
        f"out.electricity.lighting_interior.energy_consumption{unit_separator}kwh",
        f"out.electricity.lighting_exterior.energy_consumption{unit_separator}kwh",
        f"out.electricity.lighting_garage.energy_consumption{unit_separator}kwh",
    ],
    "Lighting, Natural Gas": [
        f"out.natural_gas.lighting.energy_consumption{unit_separator}kwh",
    ],
    "Lighting, Propane": [
        f"out.propane.lighting.energy_consumption{unit_separator}kwh",
    ],
    "Lighting, Fuel Oil": [
        f"out.fuel_oil.lighting.energy_consumption{unit_separator}kwh",
    ],
    "Vent Fan, Electricity": [
        f"out.electricity.mechanical_ventilation.energy_consumption{unit_separator}kwh",
        f"out.electricity.ceiling_fan.energy_consumption{unit_separator}kwh",
        f"out.electricity.whole_house_fan.energy_consumption{unit_separator}kwh",
    ],
    "Miscellaneous, Electricity": [
        f"out.electricity.plug_loads.energy_consumption{unit_separator}kwh",
        f"out.electricity.pool_pump.energy_consumption{unit_separator}kwh",
        f"out.electricity.pool_heater.energy_consumption{unit_separator}kwh",
        f"out.electricity.mech_vent_preheat.energy_consumption{unit_separator}kwh",
        f"out.electricity.permanent_spa_pump.energy_consumption{unit_separator}kwh",
        f"out.electricity.permanent_spa_heat.energy_consumption{unit_separator}kwh",
        f"out.electricity.well_pump.energy_consumption{unit_separator}kwh",
        f"out.electricity.dehumidifier.energy_consumption{unit_separator}kwh",
        f"out.electricity.hot_water_solar_th.energy_consumption{unit_separator}kwh",
        f"out.electricity.mech_vent_precool.energy_consumption{unit_separator}kwh",
        f"out.electricity.television.energy_consumption{unit_separator}kwh",
        f"out.electricity.mech_vent.energy_consumption{unit_separator}kwh",
    ],
    "Miscellaneous, Natural Gas": [
        f"out.natural_gas.fireplace.energy_consumption{unit_separator}kwh",
        f"out.natural_gas.grill.energy_consumption{unit_separator}kwh",
        f"out.natural_gas.permanent_spa_heat.energy_consumption{unit_separator}kwh",
        f"out.natural_gas.pool_heater.energy_consumption{unit_separator}kwh",
        f"out.natural_gas.mech_vent_preheat.energy_consumption{unit_separator}kwh",
        f"out.natural_gas.generator.energy_consumption{unit_separator}kwh",
    ],
    "Miscellaneous, Fuel Oil": [
        f"out.fuel_oil.fireplace.energy_consumption{unit_separator}kwh",
        f"out.fuel_oil.grill.energy_consumption{unit_separator}kwh",
        f"out.fuel_oil.mech_vent_preheating.energy_consumption{unit_separator}kwh",
        f"out.fuel_oil.generator.energy_consumption{unit_separator}kwh",
    ],
    "Miscellaneous, Propane": [
        f"out.propane.fireplace.energy_consumption{unit_separator}kwh",
        f"out.propane.grill.energy_consumption{unit_separator}kwh",
        f"out.propane.mech_vent_preheating.energy_consumption{unit_separator}kwh",
        f"out.propane.generator.energy_consumption{unit_separator}kwh",
    ],
    "Appliances, Electricity": [
        f"out.electricity.clothes_dryer.energy_consumption{unit_separator}kwh",
        f"out.electricity.clothes_washer.energy_consumption{unit_separator}kwh",
        f"out.electricity.dishwasher.energy_consumption{unit_separator}kwh",
        f"out.electricity.freezer.energy_consumption{unit_separator}kwh",
        f"out.electricity.refrigerator.energy_consumption{unit_separator}kwh",
        f"out.electricity.range_oven.energy_consumption{unit_separator}kwh",
        f"out.electricity.hot_water_recirc_p.energy_consumption{unit_separator}kwh",
    ],
    "Appliances, Natural Gas": [
        f"out.natural_gas.clothes_dryer.energy_consumption{unit_separator}kwh",
        f"out.natural_gas.range_oven.energy_consumption{unit_separator}kwh",
    ],
    "Appliances, Fuel Oil": [
        f"out.fuel_oil.clothes_dryer.energy_consumption{unit_separator}kwh",
        f"out.fuel_oil.range_oven.energy_consumption{unit_separator}kwh",
    ],
    "Appliances, Propane": [
        f"out.propane.clothes_dryer.energy_consumption{unit_separator}kwh",
        f"out.propane.range_oven.energy_consumption{unit_separator}kwh",
    ],
}
