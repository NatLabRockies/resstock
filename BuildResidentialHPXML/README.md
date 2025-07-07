
###### (Automatically generated documentation)

# HPXML Builder

## Description
Builds a residential HPXML file.

The measure handles geometry by 1) translating high-level geometry inputs (conditioned floor area, number of stories, etc.) to 3D closed-form geometry in an OpenStudio model and then 2) mapping the OpenStudio surfaces to HPXML surfaces (using surface type, boundary condition, area, orientation, etc.). Like surfaces are collapsed into a single surface with aggregate surface area. Note: OS-HPXML default values can be found in the documentation or can be seen by using the 'apply_defaults' argument.

## Arguments


**HPXML File Path**

Absolute/relative path of the HPXML file.

- **Name:** ``hpxml_path``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Existing HPXML File Path**

Absolute/relative path of the existing HPXML file. If not provided, a new HPXML file with one Building element is created. If provided, a new Building element will be appended to this HPXML file (e.g., to create a multifamily HPXML file describing multiple dwelling units).

- **Name:** ``existing_hpxml_path``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Whole SFA/MF Building Simulation?**

If the HPXML file represents a single family-attached/multifamily building with multiple dwelling units defined, specifies whether to run the HPXML file as a single whole building model.

- **Name:** ``whole_sfa_or_mf_building_sim``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Software Info: Program Used**

The name of the software program used.

- **Name:** ``software_info_program_used``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Software Info: Program Version**

The version of the software program used.

- **Name:** ``software_info_program_version``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Schedules: CSV File Paths**

Absolute/relative paths of csv files containing user-specified detailed schedules. If multiple files, use a comma-separated list.

- **Name:** ``schedules_filepaths``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Schedules: Unavailable Period Types**

Specifies the unavailable period types. Possible types are column names defined in unavailable_periods.csv: Vacancy, Power Outage, No Space Heating, No Space Cooling. If multiple periods, use a comma-separated list.

- **Name:** ``schedules_unavailable_period_types``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Schedules: Unavailable Period Dates**

Specifies the unavailable period date ranges. Enter a date range like "Dec 15 - Jan 15". Optionally, can enter hour of the day like "Dec 15 2 - Jan 15 20" (start hour can be 0 through 23 and end hour can be 1 through 24). If multiple periods, use a comma-separated list.

- **Name:** ``schedules_unavailable_period_dates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Schedules: Unavailable Period Window Natural Ventilation Availabilities**

The availability of the natural ventilation schedule during unavailable periods. Valid choices are: regular schedule, always available, always unavailable. If multiple periods, use a comma-separated list. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-unavailable-periods'>HPXML Unavailable Periods</a>) is used.

- **Name:** ``schedules_unavailable_period_window_natvent_availabilities``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Simulation Control: Timestep**

Value must be a divisor of 60. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-simulation-control'>HPXML Simulation Control</a>) is used.

- **Name:** ``simulation_control_timestep``
- **Type:** ``Integer``

- **Units:** ``min``

- **Required:** ``false``

<br/>

**Simulation Control: Run Period**

Enter a date range like 'Jan 1 - Dec 31'. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-simulation-control'>HPXML Simulation Control</a>) is used.

- **Name:** ``simulation_control_run_period``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Simulation Control: Run Period Calendar Year**

This numeric field should contain the calendar year that determines the start day of week. If you are running simulations using AMY weather files, the value entered for calendar year will not be used; it will be overridden by the actual year found in the AMY weather file. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-simulation-control'>HPXML Simulation Control</a>) is used.

- **Name:** ``simulation_control_run_period_calendar_year``
- **Type:** ``Integer``

- **Units:** ``year``

- **Required:** ``false``

<br/>

**Simulation Control: Daylight Saving Enabled**

Whether to use daylight saving. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-building-site'>HPXML Building Site</a>) is used.

- **Name:** ``simulation_control_daylight_saving_enabled``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Simulation Control: Daylight Saving Period**

Enter a date range like 'Mar 15 - Dec 15'. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-building-site'>HPXML Building Site</a>) is used.

- **Name:** ``simulation_control_daylight_saving_period``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Simulation Control: Temperature Capacitance Multiplier**

Affects the transient calculation of indoor air temperatures. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-simulation-control'>HPXML Simulation Control</a>) is used.

- **Name:** ``simulation_control_temperature_capacitance_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Simulation Control: Ground-to-Air Heat Pump Model Type**

Research feature to select the type of ground-to-air heat pump model. Use standard for standard ground-to-air heat pump modeling. Use experimental for an improved model that better accounts for coil staging. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-simulation-control'>HPXML Simulation Control</a>) is used.

- **Name:** ``simulation_control_ground_to_air_heat_pump_model_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `standard`, `experimental`

<br/>

**Simulation Control: HVAC On-Off Thermostat Deadband**

Research feature to model on-off thermostat deadband and start-up degradation for single or two speed AC/ASHP systems, and realistic time-based staging for two speed AC/ASHP systems. Currently only supported with 1 min timestep.

- **Name:** ``simulation_control_onoff_thermostat_deadband``
- **Type:** ``Double``

- **Units:** ``deg-F``

- **Required:** ``false``

<br/>

**Simulation Control: Heat Pump Backup Heating Capacity Increment**

Research feature to model capacity increment of multi-stage heat pump backup systems with time-based staging. Only applies to air-source heat pumps where Backup Type is 'integrated' and Backup Fuel Type is 'electricity'. Currently only supported with 1 min timestep.

- **Name:** ``simulation_control_heat_pump_backup_heating_capacity_increment``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Site: Type**

The type of site. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-site'>HPXML Site</a>) is used.

- **Name:** ``site_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `suburban`, `urban`, `rural`

<br/>

**Site: Shielding of Home**

Presence of nearby buildings, trees, obstructions for infiltration model. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-site'>HPXML Site</a>) is used.

- **Name:** ``site_shielding_of_home``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `exposed`, `normal`, `well-shielded`

<br/>

**Site: Soil and Moisture Type**

Type of soil and moisture. This is used to inform ground conductivity and diffusivity. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-site'>HPXML Site</a>) is used.

- **Name:** ``site_soil_and_moisture_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `clay, dry`, `clay, mixed`, `clay, wet`, `gravel, dry`, `gravel, mixed`, `gravel, wet`, `loam, dry`, `loam, mixed`, `loam, wet`, `sand, dry`, `sand, mixed`, `sand, wet`, `silt, dry`, `silt, mixed`, `silt, wet`, `unknown, dry`, `unknown, mixed`, `unknown, wet`

<br/>

**Site: Ground Conductivity**

Conductivity of the ground soil. If provided, overrides the previous site and moisture type input.

- **Name:** ``site_ground_conductivity``
- **Type:** ``Double``

- **Units:** ``Btu/hr-ft-F``

- **Required:** ``false``

<br/>

**Site: Ground Diffusivity**

Diffusivity of the ground soil. If provided, overrides the previous site and moisture type input.

- **Name:** ``site_ground_diffusivity``
- **Type:** ``Double``

- **Units:** ``ft^2/hr``

- **Required:** ``false``

<br/>

**Site: IECC Zone**

IECC zone of the home address.

- **Name:** ``site_iecc_zone``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `1A`, `1B`, `1C`, `2A`, `2B`, `2C`, `3A`, `3B`, `3C`, `4A`, `4B`, `4C`, `5A`, `5B`, `5C`, `6A`, `6B`, `6C`, `7`, `8`

<br/>

**Site: City**

City/municipality of the home address.

- **Name:** ``site_city``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Site: State Code**

State code of the home address. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-site'>HPXML Site</a>) is used.

- **Name:** ``site_state_code``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `AK`, `AL`, `AR`, `AZ`, `CA`, `CO`, `CT`, `DC`, `DE`, `FL`, `GA`, `HI`, `IA`, `ID`, `IL`, `IN`, `KS`, `KY`, `LA`, `MA`, `MD`, `ME`, `MI`, `MN`, `MO`, `MS`, `MT`, `NC`, `ND`, `NE`, `NH`, `NJ`, `NM`, `NV`, `NY`, `OH`, `OK`, `OR`, `PA`, `RI`, `SC`, `SD`, `TN`, `TX`, `UT`, `VA`, `VT`, `WA`, `WI`, `WV`, `WY`

<br/>

**Site: Zip Code**

Zip code of the home address. Either this or the Weather Station: EnergyPlus Weather (EPW) Filepath input below must be provided.

- **Name:** ``site_zip_code``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Site: Time Zone UTC Offset**

Time zone UTC offset of the home address. Must be between -12 and 14. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-site'>HPXML Site</a>) is used.

- **Name:** ``site_time_zone_utc_offset``
- **Type:** ``Double``

- **Units:** ``hr``

- **Required:** ``false``

<br/>

**Site: Elevation**

Elevation of the home address. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-site'>HPXML Site</a>) is used.

- **Name:** ``site_elevation``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Site: Latitude**

Latitude of the home address. Must be between -90 and 90. Use negative values for southern hemisphere. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-site'>HPXML Site</a>) is used.

- **Name:** ``site_latitude``
- **Type:** ``Double``

- **Units:** ``deg``

- **Required:** ``false``

<br/>

**Site: Longitude**

Longitude of the home address. Must be between -180 and 180. Use negative values for the western hemisphere. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-site'>HPXML Site</a>) is used.

- **Name:** ``site_longitude``
- **Type:** ``Double``

- **Units:** ``deg``

- **Required:** ``false``

<br/>

**Weather Station: EnergyPlus Weather (EPW) Filepath**

Path of the EPW file. Either this or the Site: Zip Code input above must be provided.

- **Name:** ``weather_station_epw_filepath``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Building Construction: Year Built**

The year the building was built.

- **Name:** ``year_built``
- **Type:** ``Integer``

- **Required:** ``false``

<br/>

**Building Construction: Unit Multiplier**

The number of similar dwelling units. EnergyPlus simulation results will be multiplied this value. If not provided, defaults to 1.

- **Name:** ``unit_multiplier``
- **Type:** ``Integer``

- **Required:** ``false``

<br/>

**Geometry: Unit Type**

The type of dwelling unit. Use single-family attached for a dwelling unit with 1 or more stories, attached units to one or both sides, and no units above/below. Use apartment unit for a dwelling unit with 1 story, attached units to one, two, or three sides, and units above and/or below.

- **Name:** ``geometry_unit_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `single-family detached`, `single-family attached`, `apartment unit`, `manufactured home`

<br/>

**Geometry: Unit Left Wall Is Adiabatic**

Presence of an adiabatic left wall.

- **Name:** ``geometry_unit_left_wall_is_adiabatic``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Geometry: Unit Right Wall Is Adiabatic**

Presence of an adiabatic right wall.

- **Name:** ``geometry_unit_right_wall_is_adiabatic``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Geometry: Unit Front Wall Is Adiabatic**

Presence of an adiabatic front wall, for example, the unit is adjacent to a conditioned corridor.

- **Name:** ``geometry_unit_front_wall_is_adiabatic``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Geometry: Unit Back Wall Is Adiabatic**

Presence of an adiabatic back wall.

- **Name:** ``geometry_unit_back_wall_is_adiabatic``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Geometry: Unit Number of Floors Above Grade**

The number of floors above grade in the unit. Attic type ConditionedAttic is included. Assumed to be 1 for apartment units.

- **Name:** ``geometry_unit_num_floors_above_grade``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``true``

<br/>

**Geometry: Unit Conditioned Floor Area**

The total floor area of the unit's conditioned space (including any conditioned basement floor area).

- **Name:** ``geometry_unit_cfa``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Geometry: Unit Aspect Ratio**

The ratio of front/back wall length to left/right wall length for the unit, excluding any protruding garage wall area.

- **Name:** ``geometry_unit_aspect_ratio``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Geometry: Unit Orientation**

The unit's orientation is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).

- **Name:** ``geometry_unit_orientation``
- **Type:** ``Double``

- **Units:** ``degrees``

- **Required:** ``true``

<br/>

**Geometry: Unit Number of Bedrooms**

The number of bedrooms in the unit.

- **Name:** ``geometry_unit_num_bedrooms``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``true``

<br/>

**Geometry: Unit Number of Bathrooms**

The number of bathrooms in the unit. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-building-construction'>HPXML Building Construction</a>) is used.

- **Name:** ``geometry_unit_num_bathrooms``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Geometry: Unit Number of Occupants**

The number of occupants in the unit. If not provided, an *asset* calculation is performed assuming standard occupancy, in which various end use defaults (e.g., plug loads, appliances, and hot water usage) are calculated based on Number of Bedrooms and Conditioned Floor Area per ANSI/RESNET/ICC 301. If provided, an *operational* calculation is instead performed in which the end use defaults to reflect real-world data (where possible).

- **Name:** ``geometry_unit_num_occupants``
- **Type:** ``Double``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Geometry: Building Number of Units**

The number of units in the building. Required for single-family attached and apartment units.

- **Name:** ``geometry_building_num_units``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Geometry: Average Ceiling Height**

Average distance from the floor to the ceiling.

- **Name:** ``geometry_average_ceiling_height``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Geometry: Unit Height Above Grade**

Describes the above-grade height of apartment units on upper floors or homes above ambient or belly-and-wing foundations. It is defined as the height of the lowest conditioned floor above grade and is used to calculate the wind speed for the infiltration model. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-building-construction'>HPXML Building Construction</a>) is used.

- **Name:** ``geometry_unit_height_above_grade``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Geometry: Garage Width**

The width of the garage. Enter zero for no garage. Only applies to single-family detached units.

- **Name:** ``geometry_garage_width``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Geometry: Garage Depth**

The depth of the garage. Only applies to single-family detached units.

- **Name:** ``geometry_garage_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Geometry: Garage Protrusion**

The fraction of the garage that is protruding from the conditioned space. Only applies to single-family detached units.

- **Name:** ``geometry_garage_protrusion``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Geometry: Garage Position**

The position of the garage. Only applies to single-family detached units.

- **Name:** ``geometry_garage_position``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Right`, `Left`

<br/>

**Geometry: Foundation Type**

The foundation type of the building. Foundation types ConditionedBasement and ConditionedCrawlspace are not allowed for apartment units.

- **Name:** ``geometry_foundation_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `SlabOnGrade`, `VentedCrawlspace`, `UnventedCrawlspace`, `ConditionedCrawlspace`, `UnconditionedBasement`, `ConditionedBasement`, `Ambient`, `AboveApartment`, `BellyAndWingWithSkirt`, `BellyAndWingNoSkirt`

<br/>

**Geometry: Foundation Height**

The height of the foundation (e.g., 3ft for crawlspace, 8ft for basement). Only applies to basements/crawlspaces.

- **Name:** ``geometry_foundation_height``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Geometry: Foundation Height Above Grade**

The depth above grade of the foundation wall. Only applies to basements/crawlspaces.

- **Name:** ``geometry_foundation_height_above_grade``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Geometry: Rim Joist Height**

The height of the rim joists. Only applies to basements/crawlspaces.

- **Name:** ``geometry_rim_joist_height``
- **Type:** ``Double``

- **Units:** ``in``

- **Required:** ``false``

<br/>

**Geometry: Attic Type**

The attic type of the building. Attic type ConditionedAttic is not allowed for apartment units.

- **Name:** ``geometry_attic_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `FlatRoof`, `VentedAttic`, `UnventedAttic`, `ConditionedAttic`, `BelowApartment`

<br/>

**Geometry: Roof Type**

The roof type of the building. Ignored if the building has a flat roof.

- **Name:** ``geometry_roof_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `gable`, `hip`

<br/>

**Geometry: Roof Pitch**

The roof pitch of the attic. Ignored if the building has a flat roof.

- **Name:** ``geometry_roof_pitch``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `1:12`, `2:12`, `3:12`, `4:12`, `5:12`, `6:12`, `7:12`, `8:12`, `9:12`, `10:12`, `11:12`, `12:12`

<br/>

**Geometry: Eaves Depth**

The eaves depth of the roof.

- **Name:** ``geometry_eaves_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Neighbor: Front Distance**

The distance between the unit and the neighboring building to the front (not including eaves). A value of zero indicates no neighbors. Used for shading.

- **Name:** ``neighbor_front_distance``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Neighbor: Back Distance**

The distance between the unit and the neighboring building to the back (not including eaves). A value of zero indicates no neighbors. Used for shading.

- **Name:** ``neighbor_back_distance``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Neighbor: Left Distance**

The distance between the unit and the neighboring building to the left (not including eaves). A value of zero indicates no neighbors. Used for shading.

- **Name:** ``neighbor_left_distance``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Neighbor: Right Distance**

The distance between the unit and the neighboring building to the right (not including eaves). A value of zero indicates no neighbors. Used for shading.

- **Name:** ``neighbor_right_distance``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Neighbor: Front Height**

The height of the neighboring building to the front. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-neighbor-buildings'>HPXML Neighbor Building</a>) is used.

- **Name:** ``neighbor_front_height``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Neighbor: Back Height**

The height of the neighboring building to the back. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-neighbor-buildings'>HPXML Neighbor Building</a>) is used.

- **Name:** ``neighbor_back_height``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Neighbor: Left Height**

The height of the neighboring building to the left. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-neighbor-buildings'>HPXML Neighbor Building</a>) is used.

- **Name:** ``neighbor_left_height``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Neighbor: Right Height**

The height of the neighboring building to the right. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-neighbor-buildings'>HPXML Neighbor Building</a>) is used.

- **Name:** ``neighbor_right_height``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Floor: Over Foundation Assembly R-value**

Assembly R-value for the floor over the foundation. Ignored if the building has a slab-on-grade foundation.

- **Name:** ``floor_over_foundation_assembly_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Floor: Over Garage Assembly R-value**

Assembly R-value for the floor over the garage. Ignored unless the building has a garage under conditioned space.

- **Name:** ``floor_over_garage_assembly_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Floor: Type**

The type of floors.

- **Name:** ``floor_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `WoodFrame`, `StructuralInsulatedPanel`, `SolidConcrete`, `SteelFrame`

<br/>

**Foundation Wall: Type**

The material type of the foundation wall. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-foundation-walls'>HPXML Foundation Walls</a>) is used.

- **Name:** ``foundation_wall_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `solid concrete`, `concrete block`, `concrete block foam core`, `concrete block perlite core`, `concrete block vermiculite core`, `concrete block solid core`, `double brick`, `wood`

<br/>

**Foundation Wall: Thickness**

The thickness of the foundation wall. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-foundation-walls'>HPXML Foundation Walls</a>) is used.

- **Name:** ``foundation_wall_thickness``
- **Type:** ``Double``

- **Units:** ``in``

- **Required:** ``false``

<br/>

**Foundation Wall: Insulation Nominal R-value**

Nominal R-value for the foundation wall insulation. Only applies to basements/crawlspaces.

- **Name:** ``foundation_wall_insulation_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Foundation Wall: Insulation Location**

Whether the insulation is on the interior or exterior of the foundation wall. Only applies to basements/crawlspaces.

- **Name:** ``foundation_wall_insulation_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `interior`, `exterior`

<br/>

**Foundation Wall: Insulation Distance To Top**

The distance from the top of the foundation wall to the top of the foundation wall insulation. Only applies to basements/crawlspaces. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-foundation-walls'>HPXML Foundation Walls</a>) is used.

- **Name:** ``foundation_wall_insulation_distance_to_top``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Foundation Wall: Insulation Distance To Bottom**

The distance from the top of the foundation wall to the bottom of the foundation wall insulation. Only applies to basements/crawlspaces. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-foundation-walls'>HPXML Foundation Walls</a>) is used.

- **Name:** ``foundation_wall_insulation_distance_to_bottom``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Foundation Wall: Assembly R-value**

Assembly R-value for the foundation walls. Only applies to basements/crawlspaces. If provided, overrides the previous foundation wall insulation inputs. If not provided, it is ignored.

- **Name:** ``foundation_wall_assembly_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``false``

<br/>

**Rim Joist: Assembly R-value**

Assembly R-value for the rim joists. Only applies to basements/crawlspaces. Required if a rim joist height is provided.

- **Name:** ``rim_joist_assembly_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``false``

<br/>

**Slab: Perimeter Insulation Nominal R-value**

Nominal R-value of the vertical slab perimeter insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.

- **Name:** ``slab_perimeter_insulation_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Slab: Perimeter Insulation Depth**

Depth from grade to bottom of vertical slab perimeter insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.

- **Name:** ``slab_perimeter_insulation_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Slab: Exterior Horizontal Insulation Nominal R-value**

Nominal R-value of the slab exterior horizontal insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.

- **Name:** ``slab_exterior_horizontal_insulation_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``false``

<br/>

**Slab: Exterior Horizontal Insulation Width**

Width of the slab exterior horizontal insulation measured from the exterior surface of the vertical slab perimeter insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.

- **Name:** ``slab_exterior_horizontal_insulation_width``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Slab: Exterior Horizontal Insulation Depth Below Grade**

Depth of the slab exterior horizontal insulation measured from the top surface of the slab exterior horizontal insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.

- **Name:** ``slab_exterior_horizontal_insulation_depth_below_grade``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Slab: Under Slab Insulation Nominal R-value**

Nominal R-value of the horizontal under slab insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.

- **Name:** ``slab_under_insulation_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Slab: Under Slab Insulation Width**

Width from slab edge inward of horizontal under-slab insulation. Enter 999 to specify that the under slab insulation spans the entire slab. Applies to slab-on-grade foundations and basement/crawlspace floors.

- **Name:** ``slab_under_insulation_width``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Slab: Thickness**

The thickness of the slab. Zero can be entered if there is a dirt floor instead of a slab. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-slabs'>HPXML Slabs</a>) is used.

- **Name:** ``slab_thickness``
- **Type:** ``Double``

- **Units:** ``in``

- **Required:** ``false``

<br/>

**Slab: Carpet Fraction**

Fraction of the slab floor area that is carpeted. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-slabs'>HPXML Slabs</a>) is used.

- **Name:** ``slab_carpet_fraction``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Slab: Carpet R-value**

R-value of the slab carpet. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-slabs'>HPXML Slabs</a>) is used.

- **Name:** ``slab_carpet_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``false``

<br/>

**Ceiling: Assembly R-value**

Assembly R-value for the ceiling (attic floor).

- **Name:** ``ceiling_assembly_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Roof: Material Type**

The material type of the roof. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-roofs'>HPXML Roofs</a>) is used.

- **Name:** ``roof_material_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `asphalt or fiberglass shingles`, `concrete`, `cool roof`, `slate or tile shingles`, `expanded polystyrene sheathing`, `metal surfacing`, `plastic/rubber/synthetic sheeting`, `shingles`, `wood shingles or shakes`

<br/>

**Roof: Color**

The color of the roof. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-roofs'>HPXML Roofs</a>) is used.

- **Name:** ``roof_color``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `dark`, `light`, `medium`, `medium dark`, `reflective`

<br/>

**Roof: Assembly R-value**

Assembly R-value of the roof.

- **Name:** ``roof_assembly_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Attic: Radiant Barrier Location**

The location of the radiant barrier in the attic.

- **Name:** ``radiant_barrier_attic_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `none`, `Attic roof only`, `Attic roof and gable walls`, `Attic floor`

<br/>

**Attic: Radiant Barrier Grade**

The grade of the radiant barrier in the attic. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-roofs'>HPXML Roofs</a>) is used.

- **Name:** ``radiant_barrier_grade``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `1`, `2`, `3`

<br/>

**Wall: Type**

The type of walls.

- **Name:** ``wall_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `WoodStud`, `ConcreteMasonryUnit`, `DoubleWoodStud`, `InsulatedConcreteForms`, `LogWall`, `StructuralInsulatedPanel`, `SolidConcrete`, `SteelFrame`, `Stone`, `StrawBale`, `StructuralBrick`

<br/>

**Wall: Siding Type**

The siding type of the walls. Also applies to rim joists. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-walls'>HPXML Walls</a>) is used.

- **Name:** ``wall_siding_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `aluminum siding`, `asbestos siding`, `brick veneer`, `composite shingle siding`, `fiber cement siding`, `masonite siding`, `none`, `stucco`, `synthetic stucco`, `vinyl siding`, `wood siding`

<br/>

**Wall: Color**

The color of the walls. Also applies to rim joists. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-walls'>HPXML Walls</a>) is used.

- **Name:** ``wall_color``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `dark`, `light`, `medium`, `medium dark`, `reflective`

<br/>

**Wall: Assembly R-value**

Assembly R-value of the walls.

- **Name:** ``wall_assembly_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Windows: Front Window-to-Wall Ratio**

The ratio of window area to wall area for the unit's front facade. Enter 0 if specifying Front Window Area instead. If the front wall is adiabatic, the value will be ignored.

- **Name:** ``window_front_wwr``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Windows: Back Window-to-Wall Ratio**

The ratio of window area to wall area for the unit's back facade. Enter 0 if specifying Back Window Area instead. If the back wall is adiabatic, the value will be ignored.

- **Name:** ``window_back_wwr``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Windows: Left Window-to-Wall Ratio**

The ratio of window area to wall area for the unit's left facade (when viewed from the front). Enter 0 if specifying Left Window Area instead. If the left wall is adiabatic, the value will be ignored.

- **Name:** ``window_left_wwr``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Windows: Right Window-to-Wall Ratio**

The ratio of window area to wall area for the unit's right facade (when viewed from the front). Enter 0 if specifying Right Window Area instead. If the right wall is adiabatic, the value will be ignored.

- **Name:** ``window_right_wwr``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Windows: Front Window Area**

The amount of window area on the unit's front facade. Enter 0 if specifying Front Window-to-Wall Ratio instead. If the front wall is adiabatic, the value will be ignored.

- **Name:** ``window_area_front``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Windows: Back Window Area**

The amount of window area on the unit's back facade. Enter 0 if specifying Back Window-to-Wall Ratio instead. If the back wall is adiabatic, the value will be ignored.

- **Name:** ``window_area_back``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Windows: Left Window Area**

The amount of window area on the unit's left facade (when viewed from the front). Enter 0 if specifying Left Window-to-Wall Ratio instead. If the left wall is adiabatic, the value will be ignored.

- **Name:** ``window_area_left``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Windows: Right Window Area**

The amount of window area on the unit's right facade (when viewed from the front). Enter 0 if specifying Right Window-to-Wall Ratio instead. If the right wall is adiabatic, the value will be ignored.

- **Name:** ``window_area_right``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Windows: Aspect Ratio**

Ratio of window height to width.

- **Name:** ``window_aspect_ratio``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Windows: Fraction Operable**

Fraction of windows that are operable. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-windows'>HPXML Windows</a>) is used.

- **Name:** ``window_fraction_operable``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Windows: Natural Ventilation Availability**

For operable windows, the number of days/week that windows can be opened by occupants for natural ventilation. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-windows'>HPXML Windows</a>) is used.

- **Name:** ``window_natvent_availability``
- **Type:** ``Integer``

- **Units:** ``Days/week``

- **Required:** ``false``

<br/>

**Windows: U-Factor**

Full-assembly NFRC U-factor.

- **Name:** ``window_ufactor``
- **Type:** ``Double``

- **Units:** ``Btu/hr-ft^2-R``

- **Required:** ``true``

<br/>

**Windows: SHGC**

Full-assembly NFRC solar heat gain coefficient.

- **Name:** ``window_shgc``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Windows: Interior Shading Type**

Type of window interior shading. Summer/winter shading coefficients can be provided below instead. If neither is provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-interior-shading'>HPXML Interior Shading</a>) is used.

- **Name:** ``window_interior_shading_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `light curtains`, `light shades`, `light blinds`, `medium curtains`, `medium shades`, `medium blinds`, `dark curtains`, `dark shades`, `dark blinds`, `none`

<br/>

**Windows: Winter Interior Shading Coefficient**

Interior shading coefficient for the winter season, which if provided overrides the shading type input. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-interior-shading'>HPXML Interior Shading</a>) is used.

- **Name:** ``window_interior_shading_winter``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Windows: Summer Interior Shading Coefficient**

Interior shading coefficient for the summer season, which if provided overrides the shading type input. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-interior-shading'>HPXML Interior Shading</a>) is used.

- **Name:** ``window_interior_shading_summer``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Windows: Exterior Shading Type**

Type of window exterior shading. Summer/winter shading coefficients can be provided below instead. If neither is provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-exterior-shading'>HPXML Exterior Shading</a>) is used.

- **Name:** ``window_exterior_shading_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `solar film`, `solar screens`, `none`

<br/>

**Windows: Winter Exterior Shading Coefficient**

Exterior shading coefficient for the winter season, which if provided overrides the shading type input. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-exterior-shading'>HPXML Exterior Shading</a>) is used.

- **Name:** ``window_exterior_shading_winter``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Windows: Summer Exterior Shading Coefficient**

Exterior shading coefficient for the summer season, which if provided overrides the shading type input. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-exterior-shading'>HPXML Exterior Shading</a>) is used.

- **Name:** ``window_exterior_shading_summer``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Windows: Shading Summer Season**

Enter a date range like 'May 1 - Sep 30'. Defines the summer season for purposes of shading coefficients; the rest of the year is assumed to be winter. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-windows'>HPXML Windows</a>) is used.

- **Name:** ``window_shading_summer_season``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Windows: Insect Screens**

The type of insect screens, if present. If not provided, assumes there are no insect screens.

- **Name:** ``window_insect_screens``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `none`, `exterior`, `interior`

<br/>

**Windows: Storm Type**

The type of storm, if present. If not provided, assumes there is no storm.

- **Name:** ``window_storm_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `clear`, `low-e`

<br/>

**Overhangs: Front Depth**

The depth of overhangs for windows for the front facade.

- **Name:** ``overhangs_front_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Front Distance to Top of Window**

The overhangs distance to the top of window for the front facade.

- **Name:** ``overhangs_front_distance_to_top_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Front Distance to Bottom of Window**

The overhangs distance to the bottom of window for the front facade.

- **Name:** ``overhangs_front_distance_to_bottom_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Back Depth**

The depth of overhangs for windows for the back facade.

- **Name:** ``overhangs_back_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Back Distance to Top of Window**

The overhangs distance to the top of window for the back facade.

- **Name:** ``overhangs_back_distance_to_top_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Back Distance to Bottom of Window**

The overhangs distance to the bottom of window for the back facade.

- **Name:** ``overhangs_back_distance_to_bottom_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Left Depth**

The depth of overhangs for windows for the left facade.

- **Name:** ``overhangs_left_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Left Distance to Top of Window**

The overhangs distance to the top of window for the left facade.

- **Name:** ``overhangs_left_distance_to_top_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Left Distance to Bottom of Window**

The overhangs distance to the bottom of window for the left facade.

- **Name:** ``overhangs_left_distance_to_bottom_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Right Depth**

The depth of overhangs for windows for the right facade.

- **Name:** ``overhangs_right_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Right Distance to Top of Window**

The overhangs distance to the top of window for the right facade.

- **Name:** ``overhangs_right_distance_to_top_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Right Distance to Bottom of Window**

The overhangs distance to the bottom of window for the right facade.

- **Name:** ``overhangs_right_distance_to_bottom_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Skylights: Front Roof Area**

The amount of skylight area on the unit's front conditioned roof facade.

- **Name:** ``skylight_area_front``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Skylights: Back Roof Area**

The amount of skylight area on the unit's back conditioned roof facade.

- **Name:** ``skylight_area_back``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Skylights: Left Roof Area**

The amount of skylight area on the unit's left conditioned roof facade (when viewed from the front).

- **Name:** ``skylight_area_left``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Skylights: Right Roof Area**

The amount of skylight area on the unit's right conditioned roof facade (when viewed from the front).

- **Name:** ``skylight_area_right``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Skylights: U-Factor**

Full-assembly NFRC U-factor.

- **Name:** ``skylight_ufactor``
- **Type:** ``Double``

- **Units:** ``Btu/hr-ft^2-R``

- **Required:** ``true``

<br/>

**Skylights: SHGC**

Full-assembly NFRC solar heat gain coefficient.

- **Name:** ``skylight_shgc``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Skylights: Storm Type**

The type of storm, if present. If not provided, assumes there is no storm.

- **Name:** ``skylight_storm_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `clear`, `low-e`

<br/>

**Doors: Area**

The area of the opaque door(s).

- **Name:** ``door_area``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Doors: R-value**

R-value of the opaque door(s).

- **Name:** ``door_rvalue``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Air Leakage: Leakiness Description**

Qualitative description of infiltration. If provided, the Year Built of the home is required. Either provide this input or provide a numeric air leakage value below.

- **Name:** ``air_leakage_leakiness_description``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `very tight`, `tight`, `average`, `leaky`, `very leaky`

<br/>

**Air Leakage: Units**

The unit of measure for the air leakage if providing a numeric air leakage value.

- **Name:** ``air_leakage_units``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `ACH`, `CFM`, `ACHnatural`, `CFMnatural`, `EffectiveLeakageArea`

<br/>

**Air Leakage: House Pressure**

The house pressure relative to outside if providing a numeric air leakage value. Required when units are ACH or CFM.

- **Name:** ``air_leakage_house_pressure``
- **Type:** ``Double``

- **Units:** ``Pa``

- **Required:** ``false``

<br/>

**Air Leakage: Value**

Numeric air leakage value. For 'EffectiveLeakageArea', provide value in sq. in. If provided, overrides Leakiness Description input.

- **Name:** ``air_leakage_value``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Air Leakage: Type**

Type of air leakage if providing a numeric air leakage value. If 'unit total', represents the total infiltration to the unit as measured by a compartmentalization test, in which case the air leakage value will be adjusted by the ratio of exterior envelope surface area to total envelope surface area. Otherwise, if 'unit exterior only', represents the infiltration to the unit from outside only as measured by a guarded test. Required when unit type is single-family attached or apartment unit.

- **Name:** ``air_leakage_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `unit total`, `unit exterior only`

<br/>

**Air Leakage: Has Flue or Chimney in Conditioned Space**

Presence of flue or chimney with combustion air from conditioned space; used for infiltration model. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#flue-or-chimney'>Flue or Chimney</a>) is used.

- **Name:** ``air_leakage_has_flue_or_chimney_in_conditioned_space``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Heating System: Type**

The type of heating system. Use 'none' if there is no heating system or if there is a heat pump serving a heating load.

- **Name:** ``heating_system_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `Furnace`, `WallFurnace`, `FloorFurnace`, `Boiler`, `ElectricResistance`, `Stove`, `SpaceHeater`, `Fireplace`, `Shared Boiler w/ Baseboard`, `Shared Boiler w/ Ductless Fan Coil`

<br/>

**Heating System: Fuel Type**

The fuel type of the heating system. Ignored for ElectricResistance.

- **Name:** ``heating_system_fuel``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`, `wood`, `wood pellets`, `coal`

<br/>

**Heating System: Rated AFUE or Percent**

The rated heating efficiency value of the heating system.

- **Name:** ``heating_system_heating_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Heating System: Heating Capacity**

The output heating capacity of the heating system. If not provided, the OS-HPXML autosized default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-heating-systems'>HPXML Heating Systems</a>) is used.

- **Name:** ``heating_system_heating_capacity``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Heating System: Heating Autosizing Factor**

The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.

- **Name:** ``heating_system_heating_autosizing_factor``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Heating System: Heating Autosizing Limit**

The maximum capacity limit applied to the auto-sizing methodology. If not provided, no limit is used.

- **Name:** ``heating_system_heating_autosizing_limit``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Heating System: Fraction Heat Load Served**

The heating load served by the heating system.

- **Name:** ``heating_system_fraction_heat_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Heating System: Pilot Light**

The fuel usage of the pilot light. Applies only to Furnace, WallFurnace, FloorFurnace, Stove, Boiler, and Fireplace with non-electric fuel type. If not provided, assumes no pilot light.

- **Name:** ``heating_system_pilot_light``
- **Type:** ``Double``

- **Units:** ``Btuh``

- **Required:** ``false``

<br/>

**Heating System: Airflow Defect Ratio**

The airflow defect ratio, defined as (InstalledAirflow - DesignAirflow) / DesignAirflow, of the heating system per ANSI/RESNET/ACCA Standard 310. A value of zero means no airflow defect. Applies only to Furnace. If not provided, assumes no defect.

- **Name:** ``heating_system_airflow_defect_ratio``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Cooling System: Type**

The type of cooling system. Use 'none' if there is no cooling system or if there is a heat pump serving a cooling load.

- **Name:** ``cooling_system_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `central air conditioner`, `room air conditioner`, `evaporative cooler`, `mini-split`, `packaged terminal air conditioner`

<br/>

**Cooling System: Cooling Compressor Type**

The compressor type of the cooling system. Required for central air conditioner and mini-split.

- **Name:** ``cooling_system_compressor_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `single stage`, `two stage`, `variable speed`

<br/>

**Cooling System: Efficiency Type**

The efficiency type of the cooling system. System types central air conditioner and mini-split use SEER or SEER2. System types room air conditioner and packaged terminal air conditioner use EER or CEER. Ignored for system type evaporative cooler.

- **Name:** ``cooling_system_cooling_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `SEER`, `SEER2`, `EER`, `CEER`

<br/>

**Cooling System: Efficiency**

The rated efficiency value of the cooling system. Ignored for evaporative cooler.

- **Name:** ``cooling_system_cooling_efficiency``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Cooling System: Cooling Capacity**

The output cooling capacity of the cooling system. If not provided, the OS-HPXML autosized default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#central-air-conditioner'>Central Air Conditioner</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#room-air-conditioner'>Room Air Conditioner</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#packaged-terminal-air-conditioner'>Packaged Terminal Air Conditioner</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#evaporative-cooler'>Evaporative Cooler</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#mini-split-air-conditioner'>Mini-Split Air Conditioner</a>) is used.

- **Name:** ``cooling_system_cooling_capacity``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Cooling System: Cooling Autosizing Factor**

The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.

- **Name:** ``cooling_system_cooling_autosizing_factor``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Cooling System: Cooling Autosizing Limit**

The maximum capacity limit applied to the auto-sizing methodology. If not provided, no limit is used.

- **Name:** ``cooling_system_cooling_autosizing_limit``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Cooling System: Fraction Cool Load Served**

The cooling load served by the cooling system.

- **Name:** ``cooling_system_fraction_cool_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Cooling System: Is Ducted**

Whether the cooling system is ducted or not. Only used for mini-split and evaporative cooler. It's assumed that central air conditioner is ducted, and room air conditioner and packaged terminal air conditioner are not ducted.

- **Name:** ``cooling_system_is_ducted``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Cooling System: Airflow Defect Ratio**

The airflow defect ratio, defined as (InstalledAirflow - DesignAirflow) / DesignAirflow, of the cooling system per ANSI/RESNET/ACCA Standard 310. A value of zero means no airflow defect. Applies only to central air conditioner and ducted mini-split. If not provided, assumes no defect.

- **Name:** ``cooling_system_airflow_defect_ratio``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Cooling System: Charge Defect Ratio**

The refrigerant charge defect ratio, defined as (InstalledCharge - DesignCharge) / DesignCharge, of the cooling system per ANSI/RESNET/ACCA Standard 310. A value of zero means no refrigerant charge defect. Applies only to central air conditioner and mini-split. If not provided, assumes no defect.

- **Name:** ``cooling_system_charge_defect_ratio``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Cooling System: Crankcase Heater Power Watts**

Cooling system crankcase heater power consumption in Watts. Applies only to central air conditioner, room air conditioner, packaged terminal air conditioner and mini-split. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#central-air-conditioner'>Central Air Conditioner</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#room-air-conditioner'>Room Air Conditioner</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#packaged-terminal-air-conditioner'>Packaged Terminal Air Conditioner</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#mini-split-air-conditioner'>Mini-Split Air Conditioner</a>) is used.

- **Name:** ``cooling_system_crankcase_heater_watts``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Cooling System: Integrated Heating System Fuel Type**

The fuel type of the heating system integrated into cooling system. Only used for packaged terminal air conditioner and room air conditioner.

- **Name:** ``cooling_system_integrated_heating_system_fuel``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`, `wood`, `wood pellets`, `coal`

<br/>

**Cooling System: Integrated Heating System Efficiency**

The rated heating efficiency value of the heating system integrated into cooling system. Only used for packaged terminal air conditioner and room air conditioner.

- **Name:** ``cooling_system_integrated_heating_system_efficiency_percent``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Cooling System: Integrated Heating System Heating Capacity**

The output heating capacity of the heating system integrated into cooling system. If not provided, the OS-HPXML autosized default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#room-air-conditioner'>Room Air Conditioner</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#packaged-terminal-air-conditioner'>Packaged Terminal Air Conditioner</a>) is used. Only used for room air conditioner and packaged terminal air conditioner.

- **Name:** ``cooling_system_integrated_heating_system_capacity``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Cooling System: Integrated Heating System Fraction Heat Load Served**

The heating load served by the heating system integrated into cooling system. Only used for packaged terminal air conditioner and room air conditioner.

- **Name:** ``cooling_system_integrated_heating_system_fraction_heat_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Heat Pump: Type**

The type of heat pump. Use 'none' if there is no heat pump.

- **Name:** ``heat_pump_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `air-to-air`, `mini-split`, `ground-to-air`, `packaged terminal heat pump`, `room air conditioner with reverse cycle`

<br/>

**Heat Pump: Cooling Compressor Type**

The compressor type of the heat pump. Required for air-to-air, mini-split and ground-to-air.

- **Name:** ``heat_pump_compressor_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `single stage`, `two stage`, `variable speed`

<br/>

**Heat Pump: Heating Efficiency Type**

The heating efficiency type of heat pump. System types air-to-air and mini-split use HSPF or HSPF2. System types ground-to-air, packaged terminal heat pump and room air conditioner with reverse cycle use COP.

- **Name:** ``heat_pump_heating_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `HSPF`, `HSPF2`, `COP`

<br/>

**Heat Pump: Heating Efficiency**

The rated heating efficiency value of the heat pump.

- **Name:** ``heat_pump_heating_efficiency``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Heat Pump: Cooling Efficiency Type**

The cooling efficiency type of heat pump. System types air-to-air and mini-split use SEER or SEER2. System types ground-to-air, packaged terminal heat pump and room air conditioner with reverse cycle use EER.

- **Name:** ``heat_pump_cooling_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `SEER`, `SEER2`, `EER`, `CEER`

<br/>

**Heat Pump: Cooling Efficiency**

The rated cooling efficiency value of the heat pump.

- **Name:** ``heat_pump_cooling_efficiency``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Heat Pump: Heating Capacity**

The output heating capacity of the heat pump. If not provided, the OS-HPXML autosized default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#mini-split-heat-pump'>Mini-Split Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#packaged-terminal-heat-pump'>Packaged Terminal Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#room-air-conditioner-w-reverse-cycle'>Room Air Conditioner w/ Reverse Cycle</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#ground-to-air-heat-pump'>Ground-to-Air Heat Pump</a>) is used.

- **Name:** ``heat_pump_heating_capacity``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Heat Pump: Heating Autosizing Factor**

The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.

- **Name:** ``heat_pump_heating_autosizing_factor``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Heat Pump: Heating Autosizing Limit**

The maximum capacity limit applied to the auto-sizing methodology. If not provided, no limit is used.

- **Name:** ``heat_pump_heating_autosizing_limit``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Heat Pump: Heating Capacity Fraction at 17F**

The output heating capacity of the heat pump at 17F divided by the above nominal heating capacity at 47F. Applies to all heat pump types except ground-to-air. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#mini-split-heat-pump'>Mini-Split Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#packaged-terminal-heat-pump'>Packaged Terminal Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#room-air-conditioner-w-reverse-cycle'>Room Air Conditioner w/ Reverse Cycle</a>) is used.

- **Name:** ``heat_pump_heating_capacity_fraction_17_f``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Heat Pump: Cooling Capacity**

The output cooling capacity of the heat pump. If not provided, the OS-HPXML autosized default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#mini-split-heat-pump'>Mini-Split Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#packaged-terminal-heat-pump'>Packaged Terminal Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#room-air-conditioner-w-reverse-cycle'>Room Air Conditioner w/ Reverse Cycle</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#ground-to-air-heat-pump'>Ground-to-Air Heat Pump</a>) is used.

- **Name:** ``heat_pump_cooling_capacity``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Heat Pump: Cooling Autosizing Factor**

The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.

- **Name:** ``heat_pump_cooling_autosizing_factor``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Heat Pump: Cooling Autosizing Limit**

The maximum capacity limit applied to the auto-sizing methodology. If not provided, no limit is used.

- **Name:** ``heat_pump_cooling_autosizing_limit``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Heat Pump: Fraction Heat Load Served**

The heating load served by the heat pump.

- **Name:** ``heat_pump_fraction_heat_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Heat Pump: Fraction Cool Load Served**

The cooling load served by the heat pump.

- **Name:** ``heat_pump_fraction_cool_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Heat Pump: Compressor Lockout Temperature**

The temperature below which the heat pump compressor is disabled. If both this and Backup Heating Lockout Temperature are provided and use the same value, it essentially defines a switchover temperature (for, e.g., a dual-fuel heat pump). Applies to all heat pump types other than ground-to-air. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#mini-split-heat-pump'>Mini-Split Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#packaged-terminal-heat-pump'>Packaged Terminal Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#room-air-conditioner-w-reverse-cycle'>Room Air Conditioner w/ Reverse Cycle</a>) is used.

- **Name:** ``heat_pump_compressor_lockout_temp``
- **Type:** ``Double``

- **Units:** ``F``

- **Required:** ``false``

<br/>

**Heat Pump: Backup Type**

The backup type of the heat pump. If 'integrated', represents e.g. built-in electric strip heat or dual-fuel integrated furnace. If 'separate', represents e.g. electric baseboard or boiler based on the Heating System 2 specified below. Use 'none' if there is no backup heating.

- **Name:** ``heat_pump_backup_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `integrated`, `separate`

<br/>

**Heat Pump: Backup Heating Autosizing Factor**

The capacity scaling factor applied to the auto-sizing methodology if Backup Type is 'integrated'. If not provided, 1.0 is used. If Backup Type is 'separate', use Heating System 2: Heating Autosizing Factor.

- **Name:** ``heat_pump_backup_heating_autosizing_factor``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Heat Pump: Backup Heating Autosizing Limit**

The maximum capacity limit applied to the auto-sizing methodology if Backup Type is 'integrated'. If not provided, no limit is used. If Backup Type is 'separate', use Heating System 2: Heating Autosizing Limit.

- **Name:** ``heat_pump_backup_heating_autosizing_limit``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Heat Pump: Backup Fuel Type**

The backup fuel type of the heat pump. Only applies if Backup Type is 'integrated'.

- **Name:** ``heat_pump_backup_fuel``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`

<br/>

**Heat Pump: Backup Rated Efficiency**

The backup rated efficiency value of the heat pump. Percent for electricity fuel type. AFUE otherwise. Only applies if Backup Type is 'integrated'.

- **Name:** ``heat_pump_backup_heating_efficiency``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Heat Pump: Backup Heating Capacity**

The backup output heating capacity of the heat pump. If not provided, the OS-HPXML autosized default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#backup'>Backup</a>) is used. Only applies if Backup Type is 'integrated'.

- **Name:** ``heat_pump_backup_heating_capacity``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Heat Pump: Backup Heating Lockout Temperature**

The temperature above which the heat pump backup system is disabled. If both this and Compressor Lockout Temperature are provided and use the same value, it essentially defines a switchover temperature (for, e.g., a dual-fuel heat pump). Applies for both Backup Type of 'integrated' and 'separate'. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#backup'>Backup</a>) is used.

- **Name:** ``heat_pump_backup_heating_lockout_temp``
- **Type:** ``Double``

- **Units:** ``F``

- **Required:** ``false``

<br/>

**Heat Pump: Sizing Methodology**

The auto-sizing methodology to use when the heat pump capacity is not provided. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-hvac-sizing-control'>HPXML HVAC Sizing Control</a>) is used.

- **Name:** ``heat_pump_sizing_methodology``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `ACCA`, `HERS`, `MaxLoad`

<br/>

**Heat Pump: Backup Sizing Methodology**

The auto-sizing methodology to use when the heat pump backup capacity is not provided. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-hvac-sizing-control'>HPXML HVAC Sizing Control</a>) is used.

- **Name:** ``heat_pump_backup_sizing_methodology``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `emergency`, `supplemental`

<br/>

**Heat Pump: Is Ducted**

Whether the heat pump is ducted or not. Only used for mini-split. It's assumed that air-to-air and ground-to-air are ducted, and packaged terminal heat pump and room air conditioner with reverse cycle are not ducted. If not provided, assumes not ducted.

- **Name:** ``heat_pump_is_ducted``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Heat Pump: Airflow Defect Ratio**

The airflow defect ratio, defined as (InstalledAirflow - DesignAirflow) / DesignAirflow, of the heat pump per ANSI/RESNET/ACCA Standard 310. A value of zero means no airflow defect. Applies only to air-to-air, ducted mini-split, and ground-to-air. If not provided, assumes no defect.

- **Name:** ``heat_pump_airflow_defect_ratio``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Heat Pump: Charge Defect Ratio**

The refrigerant charge defect ratio, defined as (InstalledCharge - DesignCharge) / DesignCharge, of the heat pump per ANSI/RESNET/ACCA Standard 310. A value of zero means no refrigerant charge defect. Applies to all heat pump types. If not provided, assumes no defect.

- **Name:** ``heat_pump_charge_defect_ratio``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Heat Pump: Crankcase Heater Power Watts**

Heat Pump crankcase heater power consumption in Watts. Applies only to air-to-air, mini-split, packaged terminal heat pump and room air conditioner with reverse cycle. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#mini-split-heat-pump'>Mini-Split Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#packaged-terminal-heat-pump'>Packaged Terminal Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#room-air-conditioner-w-reverse-cycle'>Room Air Conditioner w/ Reverse Cycle</a>) is used.

- **Name:** ``heat_pump_crankcase_heater_watts``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Heat Pump: Pan Heater Power Watts**

Heat Pump pan heater power consumption in Watts. Applies only to air-to-air and mini-split. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#mini-split-heat-pump'>Mini-Split Heat Pump</a>) is used.

- **Name:** ``heat_pump_pan_heater_watts``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Heat Pump: Pan Heater Control Type**

Heat pump pan heater control type. If 'continuous', operates continuously when outdoor temperature is below 32F. If 'defrost mode', operates only during defrost mode when outdoor temperature is below 32F. Applies only to air-to-air and mini-split. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#mini-split-heat-pump'>Mini-Split Heat Pump</a>) is used.

- **Name:** ``heat_pump_pan_heater_control_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `continuous`, `defrost mode`

<br/>

**HVAC Detailed Performance Data: Capacity Type**

Type of capacity values for detailed performance data if available. Applies only to air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps).

- **Name:** ``hvac_perf_data_capacity_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Absolute capacities`, `Normalized capacity fractions`

<br/>

**HVAC Detailed Performance Data: Heating Outdoor Temperatures**

Outdoor temperatures of heating detailed performance data if available. Applies only to air-source HVAC systems (air-to-air and mini-split heat pumps). Only certain outdoor temperatures are allowed, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-heating-performance-data'>Detailed Heating Performance Data</a>).

- **Name:** ``hvac_perf_data_heating_outdoor_temperatures``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Detailed Performance Data: Heating Minimum Speed Capacities**

Minimum speed capacities of heating detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to two stage and variable speed air-source HVAC systems (air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-heating-performance-data'>Detailed Heating Performance Data</a>).

- **Name:** ``hvac_perf_data_heating_min_speed_capacities``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Detailed Performance Data: Heating Nominal Speed Capacities**

Nominal speed capacities of heating detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to air-source HVAC systems (air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-heating-performance-data'>Detailed Heating Performance Data</a>).

- **Name:** ``hvac_perf_data_heating_nom_speed_capacities``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Detailed Performance Data: Heating Maximum Speed Capacities**

Maximum speed capacities of heating detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to variable speed air-source HVAC systems (air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-heating-performance-data'>Detailed Heating Performance Data</a>).

- **Name:** ``hvac_perf_data_heating_max_speed_capacities``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Detailed Performance Data: Heating Minimum Speed COPs**

Minimum speed efficiency COP values of heating detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to two stage and variable speed air-source HVAC systems (air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-heating-performance-data'>Detailed Heating Performance Data</a>).

- **Name:** ``hvac_perf_data_heating_min_speed_cops``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Detailed Performance Data: Heating Nominal Speed COPs**

Nominal speed efficiency COP values of heating detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to air-source HVAC systems (air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-heating-performance-data'>Detailed Heating Performance Data</a>).

- **Name:** ``hvac_perf_data_heating_nom_speed_cops``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Detailed Performance Data: Heating Maximum Speed COPs**

Maximum speed efficiency COP values of heating detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to variable speed air-source HVAC systems (air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-heating-performance-data'>Detailed Heating Performance Data</a>).

- **Name:** ``hvac_perf_data_heating_max_speed_cops``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Detailed Performance Data: Cooling Outdoor Temperatures**

Outdoor temperatures of cooling detailed performance data if available. Applies only to variable-speed air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Only certain outdoor temperatures are allowed, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-cooling-performance-data'>Detailed Cooling Performance Data</a>).

- **Name:** ``hvac_perf_data_cooling_outdoor_temperatures``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Detailed Performance Data: Cooling Minimum Speed Capacities**

Minimum speed capacities of cooling detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to two stage and variable speed air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-cooling-performance-data'>Detailed Cooling Performance Data</a>).

- **Name:** ``hvac_perf_data_cooling_min_speed_capacities``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Detailed Performance Data: Cooling Nominal Speed Capacities**

Nominal speed capacities of cooling detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-cooling-performance-data'>Detailed Cooling Performance Data</a>).

- **Name:** ``hvac_perf_data_cooling_nom_speed_capacities``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Detailed Performance Data: Cooling Maximum Speed Capacities**

Maximum speed capacities of cooling detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to variable speed air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-cooling-performance-data'>Detailed Cooling Performance Data</a>).

- **Name:** ``hvac_perf_data_cooling_max_speed_capacities``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Detailed Performance Data: Cooling Minimum Speed COPs**

Minimum speed efficiency COP values of cooling detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to two stage and variable speed air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-cooling-performance-data'>Detailed Cooling Performance Data</a>).

- **Name:** ``hvac_perf_data_cooling_min_speed_cops``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Detailed Performance Data: Cooling Nominal Speed COPs**

Nominal speed efficiency COP values of cooling detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-cooling-performance-data'>Detailed Cooling Performance Data</a>).

- **Name:** ``hvac_perf_data_cooling_nom_speed_cops``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Detailed Performance Data: Cooling Maximum Speed COPs**

Maximum speed efficiency COP values of cooling detailed performance data if available, corresponding to the above outdoor temperatures. Applies only to variable speed air-source HVAC systems (central and mini-split air conditioners, air-to-air and mini-split heat pumps). Not all values are required, see the OS-HPXML documentation (<a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-cooling-performance-data'>Detailed Cooling Performance Data</a>).

- **Name:** ``hvac_perf_data_cooling_max_speed_cops``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Geothermal Loop: Configuration**

Configuration of the geothermal loop. Only applies to ground-to-air heat pump type. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#ground-to-air-heat-pump'>Ground-to-Air Heat Pump</a>) is used.

- **Name:** ``geothermal_loop_configuration``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `none`, `vertical`

<br/>

**Geothermal Loop: Borefield Configuration**

Borefield configuration of the geothermal loop. Only applies to ground-to-air heat pump type. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>) is used.

- **Name:** ``geothermal_loop_borefield_configuration``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Rectangle`, `Open Rectangle`, `C`, `L`, `U`, `Lopsided U`

<br/>

**Geothermal Loop: Loop Flow**

Water flow rate through the geothermal loop. Only applies to ground-to-air heat pump type. If not provided, the OS-HPXML autosized default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>) is used.

- **Name:** ``geothermal_loop_loop_flow``
- **Type:** ``Double``

- **Units:** ``gpm``

- **Required:** ``false``

<br/>

**Geothermal Loop: Boreholes Count**

Number of boreholes. Only applies to ground-to-air heat pump type. If not provided, the OS-HPXML autosized default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>) is used.

- **Name:** ``geothermal_loop_boreholes_count``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Geothermal Loop: Boreholes Length**

Average length of each borehole (vertical). Only applies to ground-to-air heat pump type. If not provided, the OS-HPXML autosized default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>) is used.

- **Name:** ``geothermal_loop_boreholes_length``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Geothermal Loop: Boreholes Spacing**

Distance between bores. Only applies to ground-to-air heat pump type. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>) is used.

- **Name:** ``geothermal_loop_boreholes_spacing``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Geothermal Loop: Boreholes Diameter**

Diameter of bores. Only applies to ground-to-air heat pump type. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>) is used.

- **Name:** ``geothermal_loop_boreholes_diameter``
- **Type:** ``Double``

- **Units:** ``in``

- **Required:** ``false``

<br/>

**Geothermal Loop: Grout Type**

Grout type of the geothermal loop. Only applies to ground-to-air heat pump type. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>) is used.

- **Name:** ``geothermal_loop_grout_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `standard`, `thermally enhanced`

<br/>

**Geothermal Loop: Pipe Type**

Pipe type of the geothermal loop. Only applies to ground-to-air heat pump type. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>) is used.

- **Name:** ``geothermal_loop_pipe_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `standard`, `thermally enhanced`

<br/>

**Geothermal Loop: Pipe Diameter**

Pipe diameter of the geothermal loop. Only applies to ground-to-air heat pump type. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>) is used.

- **Name:** ``geothermal_loop_pipe_diameter``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `3/4" pipe`, `1" pipe`, `1-1/4" pipe`

<br/>

**Heating System 2: Type**

The type of the second heating system. If a heat pump is specified and the backup type is 'separate', this heating system represents 'separate' backup heating. For ducted heat pumps where the backup heating system is a 'Furnace', the backup would typically be characterized as 'integrated' in that the furnace and heat pump share the same distribution system and blower fan; a 'Furnace' as 'separate' backup to a ducted heat pump is not supported.

- **Name:** ``heating_system_2_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `Furnace`, `WallFurnace`, `FloorFurnace`, `Boiler`, `ElectricResistance`, `Stove`, `SpaceHeater`, `Fireplace`

<br/>

**Heating System 2: Fuel Type**

The fuel type of the second heating system. Ignored for ElectricResistance.

- **Name:** ``heating_system_2_fuel``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`, `wood`, `wood pellets`, `coal`

<br/>

**Heating System 2: Rated AFUE or Percent**

The rated heating efficiency value of the second heating system.

- **Name:** ``heating_system_2_heating_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Heating System 2: Heating Capacity**

The output heating capacity of the second heating system. If not provided, the OS-HPXML autosized default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-heating-systems'>HPXML Heating Systems</a>) is used.

- **Name:** ``heating_system_2_heating_capacity``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Heating System 2: Heating Autosizing Factor**

The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.

- **Name:** ``heating_system_2_heating_autosizing_factor``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Heating System 2: Heating Autosizing Limit**

The maximum capacity limit applied to the auto-sizing methodology. If not provided, no limit is used.

- **Name:** ``heating_system_2_heating_autosizing_limit``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Heating System 2: Fraction Heat Load Served**

The heat load served fraction of the second heating system. Ignored if this heating system serves as a backup system for a heat pump.

- **Name:** ``heating_system_2_fraction_heat_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**HVAC Control: Heating Weekday Setpoint Schedule**

Specify the constant or 24-hour comma-separated weekday heating setpoint schedule. Required unless a detailed CSV schedule is provided.

- **Name:** ``hvac_control_heating_weekday_setpoint``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Control: Heating Weekend Setpoint Schedule**

Specify the constant or 24-hour comma-separated weekend heating setpoint schedule. Required unless a detailed CSV schedule is provided.

- **Name:** ``hvac_control_heating_weekend_setpoint``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Control: Cooling Weekday Setpoint Schedule**

Specify the constant or 24-hour comma-separated weekday cooling setpoint schedule. Required unless a detailed CSV schedule is provided.

- **Name:** ``hvac_control_cooling_weekday_setpoint``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Control: Cooling Weekend Setpoint Schedule**

Specify the constant or 24-hour comma-separated weekend cooling setpoint schedule. Required unless a detailed CSV schedule is provided.

- **Name:** ``hvac_control_cooling_weekend_setpoint``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Control: Heating Season Period**

Enter a date range like 'Nov 1 - Jun 30'. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-hvac-control'>HPXML HVAC Control</a>) is used. Can also provide 'BuildingAmerica' to use automatic seasons from the Building America House Simulation Protocols.

- **Name:** ``hvac_control_heating_season_period``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Control: Cooling Season Period**

Enter a date range like 'Jun 1 - Oct 31'. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-hvac-control'>HPXML HVAC Control</a>) is used. Can also provide 'BuildingAmerica' to use automatic seasons from the Building America House Simulation Protocols.

- **Name:** ``hvac_control_cooling_season_period``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**HVAC Blower: Fan Efficiency**

The blower fan efficiency at maximum fan speed. Applies only to split (not packaged) systems (i.e., applies to ducted systems as well as ductless mini-split systems). If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-heating-systems'>HPXML Heating Systems</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-cooling-systems'>HPXML Cooling Systems</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-heat-pumps'>HPXML Heat Pumps</a>) is used.

- **Name:** ``hvac_blower_fan_watts_per_cfm``
- **Type:** ``Double``

- **Units:** ``W/CFM``

- **Required:** ``false``

<br/>

**Ducts: Leakage Units**

The leakage units of the ducts.

- **Name:** ``ducts_leakage_units``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `CFM25`, `CFM50`, `Percent`

<br/>

**Ducts: Supply Leakage to Outside Value**

The leakage value to outside for the supply ducts.

- **Name:** ``ducts_supply_leakage_to_outside_value``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Ducts: Supply Location**

The location of the supply ducts. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-distribution'>Air Distribution</a>) is used.

- **Name:** ``ducts_supply_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `conditioned space`, `basement - conditioned`, `basement - unconditioned`, `crawlspace`, `crawlspace - vented`, `crawlspace - unvented`, `crawlspace - conditioned`, `attic`, `attic - vented`, `attic - unvented`, `garage`, `exterior wall`, `under slab`, `roof deck`, `outside`, `other housing unit`, `other heated space`, `other multifamily buffer space`, `other non-freezing space`, `manufactured home belly`

<br/>

**Ducts: Supply Insulation R-Value**

The nominal insulation r-value of the supply ducts excluding air films. Use 0 for uninsulated ducts.

- **Name:** ``ducts_supply_insulation_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Ducts: Supply Buried Insulation Level**

Whether the supply ducts are buried in, e.g., attic loose-fill insulation. Partially buried ducts have insulation that does not cover the top of the ducts. Fully buried ducts have insulation that just covers the top of the ducts. Deeply buried ducts have insulation that continues above the top of the ducts.

- **Name:** ``ducts_supply_buried_insulation_level``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `not buried`, `partially buried`, `fully buried`, `deeply buried`

<br/>

**Ducts: Supply Surface Area**

The supply ducts surface area in the given location. If neither Surface Area nor Area Fraction provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-distribution'>Air Distribution</a>) is used.

- **Name:** ``ducts_supply_surface_area``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``false``

<br/>

**Ducts: Supply Area Fraction**

The fraction of supply ducts surface area in the given location. Only used if Surface Area is not provided. If the fraction is less than 1, the remaining duct area is assumed to be in conditioned space. If neither Surface Area nor Area Fraction provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-distribution'>Air Distribution</a>) is used.

- **Name:** ``ducts_supply_surface_area_fraction``
- **Type:** ``Double``

- **Units:** ``frac``

- **Required:** ``false``

<br/>

**Ducts: Supply Fraction Rectangular**

The fraction of supply ducts that are rectangular (as opposed to round); this affects the duct effective R-value used for modeling. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-distribution'>Air Distribution</a>) is used.

- **Name:** ``ducts_supply_fraction_rectangular``
- **Type:** ``Double``

- **Units:** ``frac``

- **Required:** ``false``

<br/>

**Ducts: Return Leakage to Outside Value**

The leakage value to outside for the return ducts.

- **Name:** ``ducts_return_leakage_to_outside_value``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Ducts: Return Location**

The location of the return ducts. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-distribution'>Air Distribution</a>) is used.

- **Name:** ``ducts_return_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `conditioned space`, `basement - conditioned`, `basement - unconditioned`, `crawlspace`, `crawlspace - vented`, `crawlspace - unvented`, `crawlspace - conditioned`, `attic`, `attic - vented`, `attic - unvented`, `garage`, `exterior wall`, `under slab`, `roof deck`, `outside`, `other housing unit`, `other heated space`, `other multifamily buffer space`, `other non-freezing space`, `manufactured home belly`

<br/>

**Ducts: Return Insulation R-Value**

The nominal insulation r-value of the return ducts excluding air films. Use 0 for uninsulated ducts.

- **Name:** ``ducts_return_insulation_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Ducts: Return Buried Insulation Level**

Whether the return ducts are buried in, e.g., attic loose-fill insulation. Partially buried ducts have insulation that does not cover the top of the ducts. Fully buried ducts have insulation that just covers the top of the ducts. Deeply buried ducts have insulation that continues above the top of the ducts.

- **Name:** ``ducts_return_buried_insulation_level``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `not buried`, `partially buried`, `fully buried`, `deeply buried`

<br/>

**Ducts: Return Surface Area**

The return ducts surface area in the given location. If neither Surface Area nor Area Fraction provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-distribution'>Air Distribution</a>) is used.

- **Name:** ``ducts_return_surface_area``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``false``

<br/>

**Ducts: Return Area Fraction**

The fraction of return ducts surface area in the given location. Only used if Surface Area is not provided. If the fraction is less than 1, the remaining duct area is assumed to be in conditioned space. If neither Surface Area nor Area Fraction provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-distribution'>Air Distribution</a>) is used.

- **Name:** ``ducts_return_surface_area_fraction``
- **Type:** ``Double``

- **Units:** ``frac``

- **Required:** ``false``

<br/>

**Ducts: Number of Return Registers**

The number of return registers of the ducts. Only used to calculate default return duct surface area. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-distribution'>Air Distribution</a>) is used.

- **Name:** ``ducts_number_of_return_registers``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Ducts: Return Fraction Rectangular**

The fraction of return ducts that are rectangular (as opposed to round); this affects the duct effective R-value used for modeling. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#air-distribution'>Air Distribution</a>) is used.

- **Name:** ``ducts_return_fraction_rectangular``
- **Type:** ``Double``

- **Units:** ``frac``

- **Required:** ``false``

<br/>

**Mechanical Ventilation: Fan Type**

The type of the mechanical ventilation. Use 'none' if there is no mechanical ventilation system.

- **Name:** ``mech_vent_fan_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `exhaust only`, `supply only`, `energy recovery ventilator`, `heat recovery ventilator`, `balanced`, `central fan integrated supply`

<br/>

**Mechanical Ventilation: Flow Rate**

The flow rate of the mechanical ventilation. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-mechanical-ventilation-fans'>HPXML Mechanical Ventilation Fans</a>) is used.

- **Name:** ``mech_vent_flow_rate``
- **Type:** ``Double``

- **Units:** ``CFM``

- **Required:** ``false``

<br/>

**Mechanical Ventilation: Hours In Operation**

The hours in operation of the mechanical ventilation. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-mechanical-ventilation-fans'>HPXML Mechanical Ventilation Fans</a>) is used.

- **Name:** ``mech_vent_hours_in_operation``
- **Type:** ``Double``

- **Units:** ``hrs/day``

- **Required:** ``false``

<br/>

**Mechanical Ventilation: Total Recovery Efficiency Type**

The total recovery efficiency type of the mechanical ventilation.

- **Name:** ``mech_vent_recovery_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Unadjusted`, `Adjusted`

<br/>

**Mechanical Ventilation: Total Recovery Efficiency**

The Unadjusted or Adjusted total recovery efficiency of the mechanical ventilation. Applies to energy recovery ventilator.

- **Name:** ``mech_vent_total_recovery_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Mechanical Ventilation: Sensible Recovery Efficiency**

The Unadjusted or Adjusted sensible recovery efficiency of the mechanical ventilation. Applies to energy recovery ventilator and heat recovery ventilator.

- **Name:** ``mech_vent_sensible_recovery_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Mechanical Ventilation: Fan Power**

The fan power of the mechanical ventilation. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-mechanical-ventilation-fans'>HPXML Mechanical Ventilation Fans</a>) is used.

- **Name:** ``mech_vent_fan_power``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Mechanical Ventilation: Number of Units Served**

Number of dwelling units served by the mechanical ventilation system. Must be 1 if single-family detached. Used to apportion flow rate and fan power to the unit.

- **Name:** ``mech_vent_num_units_served``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``true``

<br/>

**Shared Mechanical Ventilation: Fraction Recirculation**

Fraction of the total supply air that is recirculated, with the remainder assumed to be outdoor air. The value must be 0 for exhaust only systems. Required for a shared mechanical ventilation system.

- **Name:** ``mech_vent_shared_frac_recirculation``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Shared Mechanical Ventilation: Preheating Fuel**

Fuel type of the preconditioning heating equipment. Only used for a shared mechanical ventilation system. If not provided, assumes no preheating.

- **Name:** ``mech_vent_shared_preheating_fuel``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`, `wood`, `wood pellets`, `coal`

<br/>

**Shared Mechanical Ventilation: Preheating Efficiency**

Efficiency of the preconditioning heating equipment. Only used for a shared mechanical ventilation system. If not provided, assumes no preheating.

- **Name:** ``mech_vent_shared_preheating_efficiency``
- **Type:** ``Double``

- **Units:** ``COP``

- **Required:** ``false``

<br/>

**Shared Mechanical Ventilation: Preheating Fraction Ventilation Heat Load Served**

Fraction of heating load introduced by the shared ventilation system that is met by the preconditioning heating equipment. If not provided, assumes no preheating.

- **Name:** ``mech_vent_shared_preheating_fraction_heat_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Shared Mechanical Ventilation: Precooling Fuel**

Fuel type of the preconditioning cooling equipment. Only used for a shared mechanical ventilation system. If not provided, assumes no precooling.

- **Name:** ``mech_vent_shared_precooling_fuel``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `electricity`

<br/>

**Shared Mechanical Ventilation: Precooling Efficiency**

Efficiency of the preconditioning cooling equipment. Only used for a shared mechanical ventilation system. If not provided, assumes no precooling.

- **Name:** ``mech_vent_shared_precooling_efficiency``
- **Type:** ``Double``

- **Units:** ``COP``

- **Required:** ``false``

<br/>

**Shared Mechanical Ventilation: Precooling Fraction Ventilation Cool Load Served**

Fraction of cooling load introduced by the shared ventilation system that is met by the preconditioning cooling equipment. If not provided, assumes no precooling.

- **Name:** ``mech_vent_shared_precooling_fraction_cool_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Mechanical Ventilation 2: Fan Type**

The type of the second mechanical ventilation. Use 'none' if there is no second mechanical ventilation system.

- **Name:** ``mech_vent_2_fan_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `exhaust only`, `supply only`, `energy recovery ventilator`, `heat recovery ventilator`, `balanced`

<br/>

**Mechanical Ventilation 2: Flow Rate**

The flow rate of the second mechanical ventilation.

- **Name:** ``mech_vent_2_flow_rate``
- **Type:** ``Double``

- **Units:** ``CFM``

- **Required:** ``true``

<br/>

**Mechanical Ventilation 2: Hours In Operation**

The hours in operation of the second mechanical ventilation.

- **Name:** ``mech_vent_2_hours_in_operation``
- **Type:** ``Double``

- **Units:** ``hrs/day``

- **Required:** ``true``

<br/>

**Mechanical Ventilation 2: Total Recovery Efficiency Type**

The total recovery efficiency type of the second mechanical ventilation.

- **Name:** ``mech_vent_2_recovery_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Unadjusted`, `Adjusted`

<br/>

**Mechanical Ventilation 2: Total Recovery Efficiency**

The Unadjusted or Adjusted total recovery efficiency of the second mechanical ventilation. Applies to energy recovery ventilator.

- **Name:** ``mech_vent_2_total_recovery_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Mechanical Ventilation 2: Sensible Recovery Efficiency**

The Unadjusted or Adjusted sensible recovery efficiency of the second mechanical ventilation. Applies to energy recovery ventilator and heat recovery ventilator.

- **Name:** ``mech_vent_2_sensible_recovery_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Mechanical Ventilation 2: Fan Power**

The fan power of the second mechanical ventilation.

- **Name:** ``mech_vent_2_fan_power``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``true``

<br/>

**Kitchen Fans: Quantity**

The quantity of the kitchen fans. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>) is used.

- **Name:** ``kitchen_fans_quantity``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Kitchen Fans: Flow Rate**

The flow rate of the kitchen fan. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>) is used.

- **Name:** ``kitchen_fans_flow_rate``
- **Type:** ``Double``

- **Units:** ``CFM``

- **Required:** ``false``

<br/>

**Kitchen Fans: Hours In Operation**

The hours in operation of the kitchen fan. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>) is used.

- **Name:** ``kitchen_fans_hours_in_operation``
- **Type:** ``Double``

- **Units:** ``hrs/day``

- **Required:** ``false``

<br/>

**Kitchen Fans: Fan Power**

The fan power of the kitchen fan. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>) is used.

- **Name:** ``kitchen_fans_power``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Kitchen Fans: Start Hour**

The start hour of the kitchen fan. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>) is used.

- **Name:** ``kitchen_fans_start_hour``
- **Type:** ``Integer``

- **Units:** ``hr``

- **Required:** ``false``

<br/>

**Bathroom Fans: Quantity**

The quantity of the bathroom fans. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>) is used.

- **Name:** ``bathroom_fans_quantity``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Bathroom Fans: Flow Rate**

The flow rate of the bathroom fans. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>) is used.

- **Name:** ``bathroom_fans_flow_rate``
- **Type:** ``Double``

- **Units:** ``CFM``

- **Required:** ``false``

<br/>

**Bathroom Fans: Hours In Operation**

The hours in operation of the bathroom fans. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>) is used.

- **Name:** ``bathroom_fans_hours_in_operation``
- **Type:** ``Double``

- **Units:** ``hrs/day``

- **Required:** ``false``

<br/>

**Bathroom Fans: Fan Power**

The fan power of the bathroom fans. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>) is used.

- **Name:** ``bathroom_fans_power``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Bathroom Fans: Start Hour**

The start hour of the bathroom fans. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>) is used.

- **Name:** ``bathroom_fans_start_hour``
- **Type:** ``Integer``

- **Units:** ``hr``

- **Required:** ``false``

<br/>

**Whole House Fan: Present**

Whether there is a whole house fan.

- **Name:** ``whole_house_fan_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Whole House Fan: Flow Rate**

The flow rate of the whole house fan. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-whole-house-fans'>HPXML Whole House Fans</a>) is used.

- **Name:** ``whole_house_fan_flow_rate``
- **Type:** ``Double``

- **Units:** ``CFM``

- **Required:** ``false``

<br/>

**Whole House Fan: Fan Power**

The fan power of the whole house fan. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-whole-house-fans'>HPXML Whole House Fans</a>) is used.

- **Name:** ``whole_house_fan_power``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Water Heater: Type**

The type of water heater. Use 'none' if there is no water heater.

- **Name:** ``water_heater_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `storage water heater`, `instantaneous water heater`, `heat pump water heater`, `space-heating boiler with storage tank`, `space-heating boiler with tankless coil`

<br/>

**Water Heater: Fuel Type**

The fuel type of water heater. Ignored for heat pump water heater.

- **Name:** ``water_heater_fuel_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`, `wood`, `coal`

<br/>

**Water Heater: Location**

The location of water heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-water-heating-systems'>HPXML Water Heating Systems</a>) is used.

- **Name:** ``water_heater_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `conditioned space`, `basement - conditioned`, `basement - unconditioned`, `garage`, `attic`, `attic - vented`, `attic - unvented`, `crawlspace`, `crawlspace - vented`, `crawlspace - unvented`, `crawlspace - conditioned`, `other exterior`, `other housing unit`, `other heated space`, `other multifamily buffer space`, `other non-freezing space`

<br/>

**Water Heater: Tank Volume**

Nominal volume of water heater tank. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#conventional-storage'>Conventional Storage</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#heat-pump'>Heat Pump</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#combi-boiler-w-storage'>Combi Boiler w/ Storage</a>) is used.

- **Name:** ``water_heater_tank_volume``
- **Type:** ``Double``

- **Units:** ``gal``

- **Required:** ``false``

<br/>

**Water Heater: Efficiency Type**

The efficiency type of water heater. Does not apply to space-heating boilers.

- **Name:** ``water_heater_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `EnergyFactor`, `UniformEnergyFactor`

<br/>

**Water Heater: Efficiency**

Rated Energy Factor or Uniform Energy Factor. Does not apply to space-heating boilers.

- **Name:** ``water_heater_efficiency``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Water Heater: Usage Bin**

The usage of the water heater. Only applies if Efficiency Type is UniformEnergyFactor and Type is not instantaneous water heater. Does not apply to space-heating boilers. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#conventional-storage'>Conventional Storage</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#heat-pump'>Heat Pump</a>) is used.

- **Name:** ``water_heater_usage_bin``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `very small`, `low`, `medium`, `high`

<br/>

**Water Heater: Recovery Efficiency**

Ratio of energy delivered to water heater to the energy content of the fuel consumed by the water heater. Only used for non-electric storage water heaters. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#conventional-storage'>Conventional Storage</a>) is used.

- **Name:** ``water_heater_recovery_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Water Heater: Heating Capacity**

Heating capacity. Only applies to storage water heater and heat pump water heater (compressor). If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#conventional-storage'>Conventional Storage</a>, <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#heat-pump'>Heat Pump</a>) is used.

- **Name:** ``water_heater_heating_capacity``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Water Heater: Backup Heating Capacity**

Backup heating capacity for a heat pump water heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#heat-pump'>Heat Pump</a>) is used.

- **Name:** ``water_heater_backup_heating_capacity``
- **Type:** ``Double``

- **Units:** ``Btu/hr``

- **Required:** ``false``

<br/>

**Water Heater: Standby Loss**

The standby loss of water heater. Only applies to space-heating boilers. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#combi-boiler-w-storage'>Combi Boiler w/ Storage</a>) is used.

- **Name:** ``water_heater_standby_loss``
- **Type:** ``Double``

- **Units:** ``F/hr``

- **Required:** ``false``

<br/>

**Water Heater: Jacket R-value**

The jacket R-value of water heater. Doesn't apply to instantaneous water heater or space-heating boiler with tankless coil. If not provided, defaults to no jacket insulation.

- **Name:** ``water_heater_jacket_rvalue``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``false``

<br/>

**Water Heater: Setpoint Temperature**

The setpoint temperature of water heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-water-heating-systems'>HPXML Water Heating Systems</a>) is used.

- **Name:** ``water_heater_setpoint_temperature``
- **Type:** ``Double``

- **Units:** ``F``

- **Required:** ``false``

<br/>

**Water Heater: Number of Bedrooms Served**

Number of bedrooms served (directly or indirectly) by the water heater. Only needed if single-family attached or apartment unit and it is a shared water heater serving multiple dwelling units. Used to apportion water heater tank losses to the unit.

- **Name:** ``water_heater_num_bedrooms_served``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Water Heater: Uses Desuperheater**

Requires that the dwelling unit has a air-to-air, mini-split, or ground-to-air heat pump or a central air conditioner or mini-split air conditioner. If not provided, assumes no desuperheater.

- **Name:** ``water_heater_uses_desuperheater``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Water Heater: Tank Type**

Type of tank model to use. The 'stratified' tank generally provide more accurate results, but may significantly increase run time. Applies only to storage water heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#conventional-storage'>Conventional Storage</a>) is used.

- **Name:** ``water_heater_tank_model_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `mixed`, `stratified`

<br/>

**Water Heater: Operating Mode**

The water heater operating mode. The 'heat pump only' option only uses the heat pump, while 'hybrid/auto' allows the backup electric resistance to come on in high demand situations. This is ignored if a scheduled operating mode type is selected. Applies only to heat pump water heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#heat-pump'>Heat Pump</a>) is used.

- **Name:** ``water_heater_operating_mode``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `hybrid/auto`, `heat pump only`

<br/>

**Hot Water Distribution: System Type**

The type of the hot water distribution system.

- **Name:** ``hot_water_distribution_system_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Standard`, `Recirculation`

<br/>

**Hot Water Distribution: Standard Piping Length**

If the distribution system is Standard, the length of the piping. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#standard'>Standard</a>) is used.

- **Name:** ``hot_water_distribution_standard_piping_length``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Hot Water Distribution: Recirculation Control Type**

If the distribution system is Recirculation, the type of hot water recirculation control, if any.

- **Name:** ``hot_water_distribution_recirc_control_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `no control`, `timer`, `temperature`, `presence sensor demand control`, `manual demand control`

<br/>

**Hot Water Distribution: Recirculation Piping Length**

If the distribution system is Recirculation, the length of the recirculation piping. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#recirculation-in-unit'>Recirculation (In-Unit)</a>) is used.

- **Name:** ``hot_water_distribution_recirc_piping_length``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Hot Water Distribution: Recirculation Branch Piping Length**

If the distribution system is Recirculation, the length of the recirculation branch piping. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#recirculation-in-unit'>Recirculation (In-Unit)</a>) is used.

- **Name:** ``hot_water_distribution_recirc_branch_piping_length``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``false``

<br/>

**Hot Water Distribution: Recirculation Pump Power**

If the distribution system is Recirculation, the recirculation pump power. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#recirculation-in-unit'>Recirculation (In-Unit)</a>) is used.

- **Name:** ``hot_water_distribution_recirc_pump_power``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Hot Water Distribution: Pipe Insulation Nominal R-Value**

Nominal R-value of the pipe insulation. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-hot-water-distribution'>HPXML Hot Water Distribution</a>) is used.

- **Name:** ``hot_water_distribution_pipe_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``false``

<br/>

**Drain Water Heat Recovery: Facilities Connected**

Which facilities are connected for the drain water heat recovery. Use 'none' if there is no drain water heat recovery system.

- **Name:** ``dwhr_facilities_connected``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `one`, `all`

<br/>

**Drain Water Heat Recovery: Equal Flow**

Whether the drain water heat recovery has equal flow.

- **Name:** ``dwhr_equal_flow``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Drain Water Heat Recovery: Efficiency**

The efficiency of the drain water heat recovery.

- **Name:** ``dwhr_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Hot Water Fixtures: Is Shower Low Flow**

Whether the shower fixture is low flow.

- **Name:** ``water_fixtures_shower_low_flow``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Hot Water Fixtures: Is Sink Low Flow**

Whether the sink fixture is low flow.

- **Name:** ``water_fixtures_sink_low_flow``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Hot Water Fixtures: Usage Multiplier**

Multiplier on the hot water usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-water-fixtures'>HPXML Water Fixtures</a>) is used.

- **Name:** ``water_fixtures_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**General Water Use: Usage Multiplier**

Multiplier on internal gains from general water use (floor mopping, shower evaporation, water films on showers, tubs & sinks surfaces, plant watering, etc.) that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-building-occupancy'>HPXML Building Occupancy</a>) is used.

- **Name:** ``general_water_use_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Solar Thermal: System Type**

The type of solar thermal system. Use 'none' if there is no solar thermal system.

- **Name:** ``solar_thermal_system_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `hot water`

<br/>

**Solar Thermal: Collector Area**

The collector area of the solar thermal system.

- **Name:** ``solar_thermal_collector_area``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Solar Thermal: Collector Loop Type**

The collector loop type of the solar thermal system.

- **Name:** ``solar_thermal_collector_loop_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `liquid direct`, `liquid indirect`, `passive thermosyphon`

<br/>

**Solar Thermal: Collector Type**

The collector type of the solar thermal system.

- **Name:** ``solar_thermal_collector_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `evacuated tube`, `single glazing black`, `double glazing black`, `integrated collector storage`

<br/>

**Solar Thermal: Collector Azimuth**

The collector azimuth of the solar thermal system. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).

- **Name:** ``solar_thermal_collector_azimuth``
- **Type:** ``Double``

- **Units:** ``degrees``

- **Required:** ``true``

<br/>

**Solar Thermal: Collector Tilt**

The collector tilt of the solar thermal system. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.

- **Name:** ``solar_thermal_collector_tilt``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Solar Thermal: Collector Rated Optical Efficiency**

The collector rated optical efficiency of the solar thermal system.

- **Name:** ``solar_thermal_collector_rated_optical_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Solar Thermal: Collector Rated Thermal Losses**

The collector rated thermal losses of the solar thermal system.

- **Name:** ``solar_thermal_collector_rated_thermal_losses``
- **Type:** ``Double``

- **Units:** ``Btu/hr-ft^2-R``

- **Required:** ``true``

<br/>

**Solar Thermal: Storage Volume**

The storage volume of the solar thermal system. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#detailed-inputs'>Detailed Inputs</a>) is used.

- **Name:** ``solar_thermal_storage_volume``
- **Type:** ``Double``

- **Units:** ``gal``

- **Required:** ``false``

<br/>

**Solar Thermal: Solar Fraction**

The solar fraction of the solar thermal system. If provided, overrides all other solar thermal inputs.

- **Name:** ``solar_thermal_solar_fraction``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**PV System: Present**

Whether there is a PV system present.

- **Name:** ``pv_system_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**PV System: Module Type**

Module type of the PV system. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-photovoltaics'>HPXML Photovoltaics</a>) is used.

- **Name:** ``pv_system_module_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `standard`, `premium`, `thin film`

<br/>

**PV System: Location**

Location of the PV system. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-photovoltaics'>HPXML Photovoltaics</a>) is used.

- **Name:** ``pv_system_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `roof`, `ground`

<br/>

**PV System: Tracking**

Type of tracking for the PV system. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-photovoltaics'>HPXML Photovoltaics</a>) is used.

- **Name:** ``pv_system_tracking``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `fixed`, `1-axis`, `1-axis backtracked`, `2-axis`

<br/>

**PV System: Array Azimuth**

Array azimuth of the PV system. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).

- **Name:** ``pv_system_array_azimuth``
- **Type:** ``Double``

- **Units:** ``degrees``

- **Required:** ``true``

<br/>

**PV System: Array Tilt**

Array tilt of the PV system. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.

- **Name:** ``pv_system_array_tilt``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**PV System: Maximum Power Output**

Maximum power output of the PV system. For a shared system, this is the total building maximum power output.

- **Name:** ``pv_system_max_power_output``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``true``

<br/>

**PV System: Inverter Efficiency**

Inverter efficiency of the PV system. If there are two PV systems, this will apply to both. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-photovoltaics'>HPXML Photovoltaics</a>) is used.

- **Name:** ``pv_system_inverter_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**PV System: System Losses Fraction**

System losses fraction of the PV system. If there are two PV systems, this will apply to both. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-photovoltaics'>HPXML Photovoltaics</a>) is used.

- **Name:** ``pv_system_system_losses_fraction``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**PV System: Number of Bedrooms Served**

Number of bedrooms served by PV system. Only needed if single-family attached or apartment unit and it is a shared PV system serving multiple dwelling units. Used to apportion PV generation to the unit of a SFA/MF building. If there are two PV systems, this will apply to both.

- **Name:** ``pv_system_num_bedrooms_served``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**PV System 2: Present**

Whether there is a second PV system present.

- **Name:** ``pv_system_2_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**PV System 2: Module Type**

Module type of the second PV system. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-photovoltaics'>HPXML Photovoltaics</a>) is used.

- **Name:** ``pv_system_2_module_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `standard`, `premium`, `thin film`

<br/>

**PV System 2: Location**

Location of the second PV system. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-photovoltaics'>HPXML Photovoltaics</a>) is used.

- **Name:** ``pv_system_2_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `roof`, `ground`

<br/>

**PV System 2: Tracking**

Type of tracking for the second PV system. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-photovoltaics'>HPXML Photovoltaics</a>) is used.

- **Name:** ``pv_system_2_tracking``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `fixed`, `1-axis`, `1-axis backtracked`, `2-axis`

<br/>

**PV System 2: Array Azimuth**

Array azimuth of the second PV system. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).

- **Name:** ``pv_system_2_array_azimuth``
- **Type:** ``Double``

- **Units:** ``degrees``

- **Required:** ``true``

<br/>

**PV System 2: Array Tilt**

Array tilt of the second PV system. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.

- **Name:** ``pv_system_2_array_tilt``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**PV System 2: Maximum Power Output**

Maximum power output of the second PV system. For a shared system, this is the total building maximum power output.

- **Name:** ``pv_system_2_max_power_output``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``true``

<br/>

**Electric Panel: Service/Feeders Load Calculation Types**

Types of electric panel service/feeder load calculations. These calculations are experimental research features. Possible types are: 2023 Existing Dwelling Load-Based, 2023 Existing Dwelling Meter-Based. If multiple types, use a comma-separated list. If not provided, no electric panel loads are calculated.

- **Name:** ``electric_panel_service_feeders_load_calculation_types``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Electric Panel: Baseline Peak Power**

Specifies the baseline peak power. Used for 2023 Existing Dwelling Meter-Based. If not provided, assumed to be zero.

- **Name:** ``electric_panel_baseline_peak_power``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Service Voltage**

The service voltage of the electric panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-electric-panels'>HPXML Electric Panels</a>) is used.

- **Name:** ``electric_panel_service_voltage``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `120`, `240`

<br/>

**Electric Panel: Service Max Current Rating**

The service max current rating of the electric panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-electric-panels'>HPXML Electric Panels</a>) is used.

- **Name:** ``electric_panel_service_max_current_rating``
- **Type:** ``Double``

- **Units:** ``A``

- **Required:** ``false``

<br/>

**Electric Panel: Breaker Spaces Headroom**

The unoccupied number of breaker spaces on the electric panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-electric-panels'>HPXML Electric Panels</a>) is used.

- **Name:** ``electric_panel_breaker_spaces_headroom``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Electric Panel: Breaker Spaces Rated Total**

The rated total number of breaker spaces on the electric panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-electric-panels'>HPXML Electric Panels</a>) is used.

- **Name:** ``electric_panel_breaker_spaces_rated_total``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Electric Panel: Heating System Power Rating**

Specifies the panel load heating system power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_heating_system_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Heating System New Load**

Whether the heating system is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_heating_system_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Cooling System Power Rating**

Specifies the panel load cooling system power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_cooling_system_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Cooling System New Load**

Whether the cooling system is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_cooling_system_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Heat Pump Power Rating**

Specifies the panel load heat pump power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_heat_pump_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Heat Pump New Load**

Whether the heat pump is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_heat_pump_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Heating System 2 Power Rating**

Specifies the panel load second heating system power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_heating_system_2_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Heating System 2 New Load**

Whether the second heating system is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_heating_system_2_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Mechanical Ventilation Power Rating**

Specifies the panel load mechanical ventilation power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_mech_vent_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Mechanical Ventilation New Load**

Whether the mechanical ventilation is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_mech_vent_fan_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Mechanical Ventilation 2 Power Rating**

Specifies the panel load second mechanical ventilation power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_mech_vent_2_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Mechanical Ventilation 2 New Load**

Whether the second mechanical ventilation is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_mech_vent_2_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Whole House Fan Power Rating**

Specifies the panel load whole house fan power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_whole_house_fan_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Whole House Fan New Load**

Whether the whole house fan is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_whole_house_fan_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Kitchen Fans Power Rating**

Specifies the panel load kitchen fans power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_kitchen_fans_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Kitchen Fans New Load**

Whether the kitchen fans is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_kitchen_fans_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Bathroom Fans Power Rating**

Specifies the panel load bathroom fans power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_bathroom_fans_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Bathroom Fans New Load**

Whether the bathroom fans is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_bathroom_fans_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Electric Water Heater Power Rating**

Specifies the panel load water heater power rating. Only applies to electric water heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_electric_water_heater_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Electric Water Heater Voltage**

Specifies the panel load water heater voltage. Only applies to electric water heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_electric_water_heater_voltage``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `120`, `240`

<br/>

**Electric Panel: Electric Water Heater New Load**

Whether the water heater is a new panel load addition to an existing service panel. Only applies to electric water heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_electric_water_heater_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Electric Clothes Dryer Power Rating**

Specifies the panel load clothes dryer power rating. Only applies to electric clothes dryer. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_electric_clothes_dryer_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Electric Clothes Dryer Voltage**

Specifies the panel load clothes dryer voltage. Only applies to electric clothes dryer. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_electric_clothes_dryer_voltage``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `120`, `240`

<br/>

**Electric Panel: Electric Clothes Dryer New Load**

Whether the clothes dryer is a new panel load addition to an existing service panel. Only applies to electric clothes dryer. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_electric_clothes_dryer_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Dishwasher Power Rating**

Specifies the panel load dishwasher power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_dishwasher_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Dishwasher New Load**

Whether the dishwasher is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_dishwasher_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Electric Cooking Range/Oven Power Rating**

Specifies the panel load cooking range/oven power rating. Only applies to electric cooking range/oven. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_electric_cooking_range_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Electric Cooking Range/Oven Voltage**

Specifies the panel load cooking range/oven voltage. Only applies to electric cooking range/oven. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_electric_cooking_range_voltage``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `120`, `240`

<br/>

**Electric Panel: Electric Cooking Range/Oven New Load**

Whether the cooking range is a new panel load addition to an existing service panel. Only applies to electric cooking range/oven. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_electric_cooking_range_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Misc Plug Loads Well Pump Power Rating**

Specifies the panel load well pump power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_misc_plug_loads_well_pump_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Misc Plug Loads Well Pump New Load**

Whether the well pump is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_misc_plug_loads_well_pump_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Misc Plug Loads Vehicle Power Rating**

Specifies the panel load electric vehicle power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_misc_plug_loads_vehicle_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Misc Plug Loads Vehicle Voltage**

Specifies the panel load electric vehicle voltage. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_misc_plug_loads_vehicle_voltage``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `120`, `240`

<br/>

**Electric Panel: Misc Plug Loads Vehicle New Load**

Whether the electric vehicle is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_misc_plug_loads_vehicle_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Pool Pump Power Rating**

Specifies the panel load pool pump power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_pool_pump_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Pool Pump New Load**

Whether the pool pump is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_pool_pump_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Electric Pool Heater Power Rating**

Specifies the panel load pool heater power rating. Only applies to electric pool heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_electric_pool_heater_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Electric Pool Heater New Load**

Whether the pool heater is a new panel load addition to an existing service panel. Only applies to electric pool heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_electric_pool_heater_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Permanent Spa Pump Power Rating**

Specifies the panel load permanent spa pump power rating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_permanent_spa_pump_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Permanent Spa Pump New Load**

Whether the spa pump is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_permanent_spa_pump_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Electric Permanent Spa Heater Power Rating**

Specifies the panel load permanent spa heater power rating. Only applies to electric permanent spa heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_electric_permanent_spa_heater_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Electric Permanent Spa Heater New Load**

Whether the spa heater is a new panel load addition to an existing service panel. Only applies to electric permanent spa heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_electric_permanent_spa_heater_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Panel: Other Power Rating**

Specifies the panel load other power rating. This represents the total of all other electric loads that are fastened in place, permanently connected, or located on a specific circuit. For example, garbage disposal, built-in microwave. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_other_power_rating``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Electric Panel: Other New Load**

Whether the other load is a new panel load addition to an existing service panel. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#service-feeders'>Service Feeders</a>) is used.

- **Name:** ``electric_panel_load_other_new_load``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Battery: Present**

Whether there is a lithium ion battery present.

- **Name:** ``battery_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Battery: Location**

The space type for the lithium ion battery location. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-batteries'>HPXML Batteries</a>) is used.

- **Name:** ``battery_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `conditioned space`, `basement - conditioned`, `basement - unconditioned`, `crawlspace`, `crawlspace - vented`, `crawlspace - unvented`, `crawlspace - conditioned`, `attic`, `attic - vented`, `attic - unvented`, `garage`, `outside`

<br/>

**Battery: Rated Power Output**

The rated power output of the lithium ion battery. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-batteries'>HPXML Batteries</a>) is used.

- **Name:** ``battery_power``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Battery: Nominal Capacity**

The nominal capacity of the lithium ion battery. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-batteries'>HPXML Batteries</a>) is used.

- **Name:** ``battery_capacity``
- **Type:** ``Double``

- **Units:** ``kWh``

- **Required:** ``false``

<br/>

**Battery: Usable Capacity**

The usable capacity of the lithium ion battery. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-batteries'>HPXML Batteries</a>) is used.

- **Name:** ``battery_usable_capacity``
- **Type:** ``Double``

- **Units:** ``kWh``

- **Required:** ``false``

<br/>

**Battery: Round Trip Efficiency**

The round trip efficiency of the lithium ion battery. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-batteries'>HPXML Batteries</a>) is used.

- **Name:** ``battery_round_trip_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Battery: Number of Bedrooms Served**

Number of bedrooms served by the lithium ion battery. Only needed if single-family attached or apartment unit and it is a shared battery serving multiple dwelling units. Used to apportion battery charging/discharging to the unit of a SFA/MF building.

- **Name:** ``battery_num_bedrooms_served``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Vehicle: Type**

The type of vehicle present at the home.

- **Name:** ``vehicle_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Vehicle: EV Battery Nominal Battery Capacity**

The nominal capacity of the vehicle battery, only applies to electric vehicles. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-vehicles'>HPXML Vehicles</a>) is used.

- **Name:** ``vehicle_battery_capacity``
- **Type:** ``Double``

- **Units:** ``kWh``

- **Required:** ``false``

<br/>

**Vehicle: EV Battery Usable Capacity**

The usable capacity of the vehicle battery, only applies to electric vehicles. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-vehicles'>HPXML Vehicles</a>) is used.

- **Name:** ``vehicle_battery_usable_capacity``
- **Type:** ``Double``

- **Units:** ``kWh``

- **Required:** ``false``

<br/>

**Vehicle: Combined Fuel Economy Units**

The combined fuel economy units of the vehicle. Only 'kWh/mile', 'mile/kWh', or 'mpge' are allow for electric vehicles. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-vehicles'>HPXML Vehicles</a>) is used.

- **Name:** ``vehicle_fuel_economy_units``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `kWh/mile`, `mile/kWh`, `mpge`, `mpg`

<br/>

**Vehicle: Combined Fuel Economy**

The combined fuel economy of the vehicle. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-vehicles'>HPXML Vehicles</a>) is used.

- **Name:** ``vehicle_fuel_economy_combined``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Vehicle: Miles Driven Per Year**

The annual miles the vehicle is driven. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-vehicles'>HPXML Vehicles</a>) is used.

- **Name:** ``vehicle_miles_driven_per_year``
- **Type:** ``Double``

- **Units:** ``miles``

- **Required:** ``false``

<br/>

**Vehicle: Hours Driven Per Week**

The weekly hours the vehicle is driven. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-vehicles'>HPXML Vehicles</a>) is used.

- **Name:** ``vehicle_hours_driven_per_week``
- **Type:** ``Double``

- **Units:** ``hours``

- **Required:** ``false``

<br/>

**Vehicle: Fraction Charged at Home**

The fraction of charging energy provided by the at-home charger to the vehicle, only applies to electric vehicles. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-vehicles'>HPXML Vehicles</a>) is used.

- **Name:** ``vehicle_fraction_charged_home``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Electric Vehicle Charger: Present**

Whether there is an electric vehicle charger present.

- **Name:** ``ev_charger_present``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Electric Vehicle Charger: Charging Level**

The charging level of the EV charger. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-electric-vehicle-chargers'>HPXML Electric Vehicle Chargers</a>) is used.

- **Name:** ``ev_charger_level``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `1`, `2`, `3`

<br/>

**Electric Vehicle Charger: Rated Charging Power**

The rated power output of the EV charger. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-electric-vehicle-chargers'>HPXML Electric Vehicle Chargers</a>) is used.

- **Name:** ``ev_charger_power``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Lighting: Present**

Whether there is lighting energy use.

- **Name:** ``lighting_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Lighting: Interior Fraction CFL**

Fraction of all lamps (interior) that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_interior_fraction_cfl``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Interior Fraction LFL**

Fraction of all lamps (interior) that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_interior_fraction_lfl``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Interior Fraction LED**

Fraction of all lamps (interior) that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_interior_fraction_led``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Interior Usage Multiplier**

Multiplier on the lighting energy usage (interior) that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-lighting'>HPXML Lighting</a>) is used.

- **Name:** ``lighting_interior_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Lighting: Exterior Fraction CFL**

Fraction of all lamps (exterior) that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_exterior_fraction_cfl``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Exterior Fraction LFL**

Fraction of all lamps (exterior) that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_exterior_fraction_lfl``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Exterior Fraction LED**

Fraction of all lamps (exterior) that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_exterior_fraction_led``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Exterior Usage Multiplier**

Multiplier on the lighting energy usage (exterior) that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-lighting'>HPXML Lighting</a>) is used.

- **Name:** ``lighting_exterior_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Lighting: Garage Fraction CFL**

Fraction of all lamps (garage) that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_garage_fraction_cfl``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Garage Fraction LFL**

Fraction of all lamps (garage) that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_garage_fraction_lfl``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Garage Fraction LED**

Fraction of all lamps (garage) that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_garage_fraction_led``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Garage Usage Multiplier**

Multiplier on the lighting energy usage (garage) that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-lighting'>HPXML Lighting</a>) is used.

- **Name:** ``lighting_garage_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Holiday Lighting: Present**

Whether there is holiday lighting.

- **Name:** ``holiday_lighting_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Holiday Lighting: Daily Consumption**

The daily energy consumption for holiday lighting (exterior). If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-lighting'>HPXML Lighting</a>) is used.

- **Name:** ``holiday_lighting_daily_kwh``
- **Type:** ``Double``

- **Units:** ``kWh/day``

- **Required:** ``false``

<br/>

**Holiday Lighting: Period**

Enter a date range like 'Nov 25 - Jan 5'. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-lighting'>HPXML Lighting</a>) is used.

- **Name:** ``holiday_lighting_period``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Dehumidifier: Type**

The type of dehumidifier.

- **Name:** ``dehumidifier_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `portable`, `whole-home`

<br/>

**Dehumidifier: Efficiency Type**

The efficiency type of dehumidifier.

- **Name:** ``dehumidifier_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `EnergyFactor`, `IntegratedEnergyFactor`

<br/>

**Dehumidifier: Efficiency**

The efficiency of the dehumidifier.

- **Name:** ``dehumidifier_efficiency``
- **Type:** ``Double``

- **Units:** ``liters/kWh``

- **Required:** ``true``

<br/>

**Dehumidifier: Capacity**

The capacity (water removal rate) of the dehumidifier.

- **Name:** ``dehumidifier_capacity``
- **Type:** ``Double``

- **Units:** ``pint/day``

- **Required:** ``true``

<br/>

**Dehumidifier: Relative Humidity Setpoint**

The relative humidity setpoint of the dehumidifier.

- **Name:** ``dehumidifier_rh_setpoint``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Dehumidifier: Fraction Dehumidification Load Served**

The dehumidification load served fraction of the dehumidifier.

- **Name:** ``dehumidifier_fraction_dehumidification_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Clothes Washer: Present**

Whether there is a clothes washer present.

- **Name:** ``clothes_washer_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Clothes Washer: Location**

The space type for the clothes washer location. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-clothes-washer'>HPXML Clothes Washer</a>) is used.

- **Name:** ``clothes_washer_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `conditioned space`, `basement - conditioned`, `basement - unconditioned`, `garage`, `other housing unit`, `other heated space`, `other multifamily buffer space`, `other non-freezing space`

<br/>

**Clothes Washer: Efficiency Type**

The efficiency type of the clothes washer.

- **Name:** ``clothes_washer_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `ModifiedEnergyFactor`, `IntegratedModifiedEnergyFactor`

<br/>

**Clothes Washer: Efficiency**

The efficiency of the clothes washer. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-clothes-washer'>HPXML Clothes Washer</a>) is used.

- **Name:** ``clothes_washer_efficiency``
- **Type:** ``Double``

- **Units:** ``ft^3/kWh-cyc``

- **Required:** ``false``

<br/>

**Clothes Washer: Rated Annual Consumption**

The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-clothes-washer'>HPXML Clothes Washer</a>) is used.

- **Name:** ``clothes_washer_rated_annual_kwh``
- **Type:** ``Double``

- **Units:** ``kWh/yr``

- **Required:** ``false``

<br/>

**Clothes Washer: Label Electric Rate**

The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-clothes-washer'>HPXML Clothes Washer</a>) is used.

- **Name:** ``clothes_washer_label_electric_rate``
- **Type:** ``Double``

- **Units:** ``$/kWh``

- **Required:** ``false``

<br/>

**Clothes Washer: Label Gas Rate**

The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-clothes-washer'>HPXML Clothes Washer</a>) is used.

- **Name:** ``clothes_washer_label_gas_rate``
- **Type:** ``Double``

- **Units:** ``$/therm``

- **Required:** ``false``

<br/>

**Clothes Washer: Label Annual Cost with Gas DHW**

The annual cost of using the system under test conditions. Input is obtained from the EnergyGuide label. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-clothes-washer'>HPXML Clothes Washer</a>) is used.

- **Name:** ``clothes_washer_label_annual_gas_cost``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Clothes Washer: Label Usage**

The clothes washer loads per week. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-clothes-washer'>HPXML Clothes Washer</a>) is used.

- **Name:** ``clothes_washer_label_usage``
- **Type:** ``Double``

- **Units:** ``cyc/wk``

- **Required:** ``false``

<br/>

**Clothes Washer: Drum Volume**

Volume of the washer drum. Obtained from the EnergyStar website or the manufacturer's literature. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-clothes-washer'>HPXML Clothes Washer</a>) is used.

- **Name:** ``clothes_washer_capacity``
- **Type:** ``Double``

- **Units:** ``ft^3``

- **Required:** ``false``

<br/>

**Clothes Washer: Usage Multiplier**

Multiplier on the clothes washer energy and hot water usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-clothes-washer'>HPXML Clothes Washer</a>) is used.

- **Name:** ``clothes_washer_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Clothes Dryer: Present**

Whether there is a clothes dryer present.

- **Name:** ``clothes_dryer_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Clothes Dryer: Location**

The space type for the clothes dryer location. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-clothes-dryer'>HPXML Clothes Dryer</a>) is used.

- **Name:** ``clothes_dryer_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `conditioned space`, `basement - conditioned`, `basement - unconditioned`, `garage`, `other housing unit`, `other heated space`, `other multifamily buffer space`, `other non-freezing space`

<br/>

**Clothes Dryer: Fuel Type**

Type of fuel used by the clothes dryer.

- **Name:** ``clothes_dryer_fuel_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`, `wood`, `coal`

<br/>

**Clothes Dryer: Drying Method**

The method of drying used by the clothes dryer. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-clothes-dryer'>HPXML Clothes Dryer</a>) is used.

- **Name:** ``clothes_dryer_drying_method``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `conventional`, `condensing`, `heat pump`, `other`

<br/>

**Clothes Dryer: Efficiency Type**

The efficiency type of the clothes dryer.

- **Name:** ``clothes_dryer_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `EnergyFactor`, `CombinedEnergyFactor`

<br/>

**Clothes Dryer: Efficiency**

The efficiency of the clothes dryer. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-clothes-dryer'>HPXML Clothes Dryer</a>) is used.

- **Name:** ``clothes_dryer_efficiency``
- **Type:** ``Double``

- **Units:** ``lb/kWh``

- **Required:** ``false``

<br/>

**Clothes Dryer: Usage Multiplier**

Multiplier on the clothes dryer energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-clothes-dryer'>HPXML Clothes Dryer</a>) is used.

- **Name:** ``clothes_dryer_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Dishwasher: Present**

Whether there is a dishwasher present.

- **Name:** ``dishwasher_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Dishwasher: Location**

The space type for the dishwasher location. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-dishwasher'>HPXML Dishwasher</a>) is used.

- **Name:** ``dishwasher_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `conditioned space`, `basement - conditioned`, `basement - unconditioned`, `garage`, `other housing unit`, `other heated space`, `other multifamily buffer space`, `other non-freezing space`

<br/>

**Dishwasher: Efficiency Type**

The efficiency type of dishwasher.

- **Name:** ``dishwasher_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `RatedAnnualkWh`, `EnergyFactor`

<br/>

**Dishwasher: Efficiency**

The efficiency of the dishwasher. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-dishwasher'>HPXML Dishwasher</a>) is used.

- **Name:** ``dishwasher_efficiency``
- **Type:** ``Double``

- **Units:** ``RatedAnnualkWh or EnergyFactor``

- **Required:** ``false``

<br/>

**Dishwasher: Label Electric Rate**

The label electric rate of the dishwasher. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-dishwasher'>HPXML Dishwasher</a>) is used.

- **Name:** ``dishwasher_label_electric_rate``
- **Type:** ``Double``

- **Units:** ``$/kWh``

- **Required:** ``false``

<br/>

**Dishwasher: Label Gas Rate**

The label gas rate of the dishwasher. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-dishwasher'>HPXML Dishwasher</a>) is used.

- **Name:** ``dishwasher_label_gas_rate``
- **Type:** ``Double``

- **Units:** ``$/therm``

- **Required:** ``false``

<br/>

**Dishwasher: Label Annual Gas Cost**

The label annual gas cost of the dishwasher. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-dishwasher'>HPXML Dishwasher</a>) is used.

- **Name:** ``dishwasher_label_annual_gas_cost``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Dishwasher: Label Usage**

The dishwasher loads per week. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-dishwasher'>HPXML Dishwasher</a>) is used.

- **Name:** ``dishwasher_label_usage``
- **Type:** ``Double``

- **Units:** ``cyc/wk``

- **Required:** ``false``

<br/>

**Dishwasher: Number of Place Settings**

The number of place settings for the unit. Data obtained from manufacturer's literature. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-dishwasher'>HPXML Dishwasher</a>) is used.

- **Name:** ``dishwasher_place_setting_capacity``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Dishwasher: Usage Multiplier**

Multiplier on the dishwasher energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-dishwasher'>HPXML Dishwasher</a>) is used.

- **Name:** ``dishwasher_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Refrigerator: Present**

Whether there is a refrigerator present.

- **Name:** ``refrigerator_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Refrigerator: Location**

The space type for the refrigerator location. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-refrigerators'>HPXML Refrigerators</a>) is used.

- **Name:** ``refrigerator_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `conditioned space`, `basement - conditioned`, `basement - unconditioned`, `garage`, `other housing unit`, `other heated space`, `other multifamily buffer space`, `other non-freezing space`

<br/>

**Refrigerator: Rated Annual Consumption**

The EnergyGuide rated annual energy consumption for a refrigerator. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-refrigerators'>HPXML Refrigerators</a>) is used.

- **Name:** ``refrigerator_rated_annual_kwh``
- **Type:** ``Double``

- **Units:** ``kWh/yr``

- **Required:** ``false``

<br/>

**Refrigerator: Usage Multiplier**

Multiplier on the refrigerator energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-refrigerators'>HPXML Refrigerators</a>) is used.

- **Name:** ``refrigerator_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Extra Refrigerator: Present**

Whether there is an extra refrigerator present.

- **Name:** ``extra_refrigerator_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Extra Refrigerator: Location**

The space type for the extra refrigerator location. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-refrigerators'>HPXML Refrigerators</a>) is used.

- **Name:** ``extra_refrigerator_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `conditioned space`, `basement - conditioned`, `basement - unconditioned`, `garage`, `other housing unit`, `other heated space`, `other multifamily buffer space`, `other non-freezing space`

<br/>

**Extra Refrigerator: Rated Annual Consumption**

The EnergyGuide rated annual energy consumption for an extra refrigerator. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-refrigerators'>HPXML Refrigerators</a>) is used.

- **Name:** ``extra_refrigerator_rated_annual_kwh``
- **Type:** ``Double``

- **Units:** ``kWh/yr``

- **Required:** ``false``

<br/>

**Extra Refrigerator: Usage Multiplier**

Multiplier on the extra refrigerator energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-refrigerators'>HPXML Refrigerators</a>) is used.

- **Name:** ``extra_refrigerator_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Freezer: Present**

Whether there is a freezer present.

- **Name:** ``freezer_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Freezer: Location**

The space type for the freezer location. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-freezers'>HPXML Freezers</a>) is used.

- **Name:** ``freezer_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `conditioned space`, `basement - conditioned`, `basement - unconditioned`, `garage`, `other housing unit`, `other heated space`, `other multifamily buffer space`, `other non-freezing space`

<br/>

**Freezer: Rated Annual Consumption**

The EnergyGuide rated annual energy consumption for a freezer. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-freezers'>HPXML Freezers</a>) is used.

- **Name:** ``freezer_rated_annual_kwh``
- **Type:** ``Double``

- **Units:** ``kWh/yr``

- **Required:** ``false``

<br/>

**Freezer: Usage Multiplier**

Multiplier on the freezer energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-freezers'>HPXML Freezers</a>) is used.

- **Name:** ``freezer_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Cooking Range/Oven: Present**

Whether there is a cooking range/oven present.

- **Name:** ``cooking_range_oven_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Cooking Range/Oven: Location**

The space type for the cooking range/oven location. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-cooking-range-oven'>HPXML Cooking Range/Oven</a>) is used.

- **Name:** ``cooking_range_oven_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `conditioned space`, `basement - conditioned`, `basement - unconditioned`, `garage`, `other housing unit`, `other heated space`, `other multifamily buffer space`, `other non-freezing space`

<br/>

**Cooking Range/Oven: Fuel Type**

Type of fuel used by the cooking range/oven.

- **Name:** ``cooking_range_oven_fuel_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`, `wood`, `coal`

<br/>

**Cooking Range/Oven: Is Induction**

Whether the cooking range is induction. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-cooking-range-oven'>HPXML Cooking Range/Oven</a>) is used.

- **Name:** ``cooking_range_oven_is_induction``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Cooking Range/Oven: Is Convection**

Whether the oven is convection. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-cooking-range-oven'>HPXML Cooking Range/Oven</a>) is used.

- **Name:** ``cooking_range_oven_is_convection``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Cooking Range/Oven: Usage Multiplier**

Multiplier on the cooking range/oven energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-cooking-range-oven'>HPXML Cooking Range/Oven</a>) is used.

- **Name:** ``cooking_range_oven_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Ceiling Fan: Present**

Whether there are any ceiling fans.

- **Name:** ``ceiling_fan_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Ceiling Fan: Label Energy Use**

The label average energy use of the ceiling fan(s). If neither Efficiency nor Label Energy Use provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-ceiling-fans'>HPXML Ceiling Fans</a>) is used.

- **Name:** ``ceiling_fan_label_energy_use``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``false``

<br/>

**Ceiling Fan: Efficiency**

The efficiency rating of the ceiling fan(s) at medium speed. Only used if Label Energy Use not provided. If neither Efficiency nor Label Energy Use provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-ceiling-fans'>HPXML Ceiling Fans</a>) is used.

- **Name:** ``ceiling_fan_efficiency``
- **Type:** ``Double``

- **Units:** ``CFM/W``

- **Required:** ``false``

<br/>

**Ceiling Fan: Quantity**

Total number of ceiling fans. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-ceiling-fans'>HPXML Ceiling Fans</a>) is used.

- **Name:** ``ceiling_fan_quantity``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Ceiling Fan: Cooling Setpoint Temperature Offset**

The cooling setpoint temperature offset during months when the ceiling fans are operating. Only applies if ceiling fan quantity is greater than zero. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-ceiling-fans'>HPXML Ceiling Fans</a>) is used.

- **Name:** ``ceiling_fan_cooling_setpoint_temp_offset``
- **Type:** ``Double``

- **Units:** ``F``

- **Required:** ``false``

<br/>

**Misc Plug Loads: Television Present**

Whether there are televisions.

- **Name:** ``misc_plug_loads_television_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Misc Plug Loads: Television Annual kWh**

The annual energy consumption of the television plug loads. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-plug-loads'>HPXML Plug Loads</a>) is used.

- **Name:** ``misc_plug_loads_television_annual_kwh``
- **Type:** ``Double``

- **Units:** ``kWh/yr``

- **Required:** ``false``

<br/>

**Misc Plug Loads: Television Usage Multiplier**

Multiplier on the television energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-plug-loads'>HPXML Plug Loads</a>) is used.

- **Name:** ``misc_plug_loads_television_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Misc Plug Loads: Other Annual kWh**

The annual energy consumption of the other residual plug loads. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-plug-loads'>HPXML Plug Loads</a>) is used.

- **Name:** ``misc_plug_loads_other_annual_kwh``
- **Type:** ``Double``

- **Units:** ``kWh/yr``

- **Required:** ``false``

<br/>

**Misc Plug Loads: Other Sensible Fraction**

Fraction of other residual plug loads' internal gains that are sensible. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-plug-loads'>HPXML Plug Loads</a>) is used.

- **Name:** ``misc_plug_loads_other_frac_sensible``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Misc Plug Loads: Other Latent Fraction**

Fraction of other residual plug loads' internal gains that are latent. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-plug-loads'>HPXML Plug Loads</a>) is used.

- **Name:** ``misc_plug_loads_other_frac_latent``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Misc Plug Loads: Other Usage Multiplier**

Multiplier on the other energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-plug-loads'>HPXML Plug Loads</a>) is used.

- **Name:** ``misc_plug_loads_other_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Misc Plug Loads: Well Pump Present**

Whether there is a well pump.

- **Name:** ``misc_plug_loads_well_pump_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Misc Plug Loads: Well Pump Annual kWh**

The annual energy consumption of the well pump plug loads. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-plug-loads'>HPXML Plug Loads</a>) is used.

- **Name:** ``misc_plug_loads_well_pump_annual_kwh``
- **Type:** ``Double``

- **Units:** ``kWh/yr``

- **Required:** ``false``

<br/>

**Misc Plug Loads: Well Pump Usage Multiplier**

Multiplier on the well pump energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-plug-loads'>HPXML Plug Loads</a>) is used.

- **Name:** ``misc_plug_loads_well_pump_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Misc Plug Loads: Vehicle Present**

Whether there is an electric vehicle.

- **Name:** ``misc_plug_loads_vehicle_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Misc Plug Loads: Vehicle Annual kWh**

The annual energy consumption of the electric vehicle plug loads. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-plug-loads'>HPXML Plug Loads</a>) is used.

- **Name:** ``misc_plug_loads_vehicle_annual_kwh``
- **Type:** ``Double``

- **Units:** ``kWh/yr``

- **Required:** ``false``

<br/>

**Misc Plug Loads: Vehicle Usage Multiplier**

Multiplier on the electric vehicle energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-plug-loads'>HPXML Plug Loads</a>) is used.

- **Name:** ``misc_plug_loads_vehicle_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Misc Fuel Loads: Grill Present**

Whether there is a fuel loads grill.

- **Name:** ``misc_fuel_loads_grill_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Misc Fuel Loads: Grill Fuel Type**

The fuel type of the fuel loads grill.

- **Name:** ``misc_fuel_loads_grill_fuel_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `natural gas`, `fuel oil`, `propane`, `wood`, `wood pellets`

<br/>

**Misc Fuel Loads: Grill Annual therm**

The annual energy consumption of the fuel loads grill. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-fuel-loads'>HPXML Fuel Loads</a>) is used.

- **Name:** ``misc_fuel_loads_grill_annual_therm``
- **Type:** ``Double``

- **Units:** ``therm/yr``

- **Required:** ``false``

<br/>

**Misc Fuel Loads: Grill Usage Multiplier**

Multiplier on the fuel loads grill energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-fuel-loads'>HPXML Fuel Loads</a>) is used.

- **Name:** ``misc_fuel_loads_grill_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Misc Fuel Loads: Lighting Present**

Whether there is fuel loads lighting.

- **Name:** ``misc_fuel_loads_lighting_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Misc Fuel Loads: Lighting Fuel Type**

The fuel type of the fuel loads lighting.

- **Name:** ``misc_fuel_loads_lighting_fuel_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `natural gas`, `fuel oil`, `propane`, `wood`, `wood pellets`

<br/>

**Misc Fuel Loads: Lighting Annual therm**

The annual energy consumption of the fuel loads lighting. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-fuel-loads'>HPXML Fuel Loads</a>)is used.

- **Name:** ``misc_fuel_loads_lighting_annual_therm``
- **Type:** ``Double``

- **Units:** ``therm/yr``

- **Required:** ``false``

<br/>

**Misc Fuel Loads: Lighting Usage Multiplier**

Multiplier on the fuel loads lighting energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-fuel-loads'>HPXML Fuel Loads</a>) is used.

- **Name:** ``misc_fuel_loads_lighting_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Misc Fuel Loads: Fireplace Present**

Whether there is fuel loads fireplace.

- **Name:** ``misc_fuel_loads_fireplace_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Misc Fuel Loads: Fireplace Fuel Type**

The fuel type of the fuel loads fireplace.

- **Name:** ``misc_fuel_loads_fireplace_fuel_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `natural gas`, `fuel oil`, `propane`, `wood`, `wood pellets`

<br/>

**Misc Fuel Loads: Fireplace Annual therm**

The annual energy consumption of the fuel loads fireplace. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-fuel-loads'>HPXML Fuel Loads</a>) is used.

- **Name:** ``misc_fuel_loads_fireplace_annual_therm``
- **Type:** ``Double``

- **Units:** ``therm/yr``

- **Required:** ``false``

<br/>

**Misc Fuel Loads: Fireplace Sensible Fraction**

Fraction of fireplace residual fuel loads' internal gains that are sensible. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-fuel-loads'>HPXML Fuel Loads</a>) is used.

- **Name:** ``misc_fuel_loads_fireplace_frac_sensible``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Misc Fuel Loads: Fireplace Latent Fraction**

Fraction of fireplace residual fuel loads' internal gains that are latent. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-fuel-loads'>HPXML Fuel Loads</a>) is used.

- **Name:** ``misc_fuel_loads_fireplace_frac_latent``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Misc Fuel Loads: Fireplace Usage Multiplier**

Multiplier on the fuel loads fireplace energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#hpxml-fuel-loads'>HPXML Fuel Loads</a>) is used.

- **Name:** ``misc_fuel_loads_fireplace_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Pool: Present**

Whether there is a pool.

- **Name:** ``pool_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Pool: Pump Annual kWh**

The annual energy consumption of the pool pump. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#pool-pump'>Pool Pump</a>) is used.

- **Name:** ``pool_pump_annual_kwh``
- **Type:** ``Double``

- **Units:** ``kWh/yr``

- **Required:** ``false``

<br/>

**Pool: Pump Usage Multiplier**

Multiplier on the pool pump energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#pool-pump'>Pool Pump</a>) is used.

- **Name:** ``pool_pump_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Pool: Heater Type**

The type of pool heater. Use 'none' if there is no pool heater.

- **Name:** ``pool_heater_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `electric resistance`, `gas fired`, `heat pump`

<br/>

**Pool: Heater Annual kWh**

The annual energy consumption of the electric resistance pool heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#pool-heater'>Pool Heater</a>) is used.

- **Name:** ``pool_heater_annual_kwh``
- **Type:** ``Double``

- **Units:** ``kWh/yr``

- **Required:** ``false``

<br/>

**Pool: Heater Annual therm**

The annual energy consumption of the gas fired pool heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#pool-heater'>Pool Heater</a>) is used.

- **Name:** ``pool_heater_annual_therm``
- **Type:** ``Double``

- **Units:** ``therm/yr``

- **Required:** ``false``

<br/>

**Pool: Heater Usage Multiplier**

Multiplier on the pool heater energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#pool-heater'>Pool Heater</a>) is used.

- **Name:** ``pool_heater_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Permanent Spa: Present**

Whether there is a permanent spa.

- **Name:** ``permanent_spa_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Permanent Spa: Pump Annual kWh**

The annual energy consumption of the permanent spa pump. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#permanent-spa-pump'>Permanent Spa Pump</a>) is used.

- **Name:** ``permanent_spa_pump_annual_kwh``
- **Type:** ``Double``

- **Units:** ``kWh/yr``

- **Required:** ``false``

<br/>

**Permanent Spa: Pump Usage Multiplier**

Multiplier on the permanent spa pump energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#permanent-spa-pump'>Permanent Spa Pump</a>) is used.

- **Name:** ``permanent_spa_pump_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Permanent Spa: Heater Type**

The type of permanent spa heater. Use 'none' if there is no permanent spa heater.

- **Name:** ``permanent_spa_heater_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `electric resistance`, `gas fired`, `heat pump`

<br/>

**Permanent Spa: Heater Annual kWh**

The annual energy consumption of the electric resistance permanent spa heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#permanent-spa-heater'>Permanent Spa Heater</a>) is used.

- **Name:** ``permanent_spa_heater_annual_kwh``
- **Type:** ``Double``

- **Units:** ``kWh/yr``

- **Required:** ``false``

<br/>

**Permanent Spa: Heater Annual therm**

The annual energy consumption of the gas fired permanent spa heater. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#permanent-spa-heater'>Permanent Spa Heater</a>) is used.

- **Name:** ``permanent_spa_heater_annual_therm``
- **Type:** ``Double``

- **Units:** ``therm/yr``

- **Required:** ``false``

<br/>

**Permanent Spa: Heater Usage Multiplier**

Multiplier on the permanent spa heater energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see <a href='https://openstudio-hpxml.readthedocs.io/en/v1.11.0/workflow_inputs.html#permanent-spa-heater'>Permanent Spa Heater</a>) is used.

- **Name:** ``permanent_spa_heater_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Emissions: Scenario Names**

Names of emissions scenarios. If multiple scenarios, use a comma-separated list. If not provided, no emissions scenarios are calculated.

- **Name:** ``emissions_scenario_names``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Types**

Types of emissions (e.g., CO2e, NOx, etc.). If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_types``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Electricity Units**

Electricity emissions factors units. If multiple scenarios, use a comma-separated list. Only lb/MWh and kg/MWh are allowed.

- **Name:** ``emissions_electricity_units``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Electricity Values or File Paths**

Electricity emissions factors values, specified as either an annual factor or an absolute/relative path to a file with hourly factors. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_electricity_values_or_filepaths``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Electricity Files Number of Header Rows**

The number of header rows in the electricity emissions factor file. Only applies when an electricity filepath is used. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_electricity_number_of_header_rows``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Electricity Files Column Numbers**

The column number in the electricity emissions factor file. Only applies when an electricity filepath is used. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_electricity_column_numbers``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Fossil Fuel Units**

Fossil fuel emissions factors units. If multiple scenarios, use a comma-separated list. Only lb/MBtu and kg/MBtu are allowed.

- **Name:** ``emissions_fossil_fuel_units``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Natural Gas Values**

Natural gas emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_natural_gas_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Propane Values**

Propane emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_propane_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Fuel Oil Values**

Fuel oil emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_fuel_oil_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Coal Values**

Coal emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_coal_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Wood Values**

Wood emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_wood_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Emissions: Wood Pellets Values**

Wood pellets emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.

- **Name:** ``emissions_wood_pellets_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Scenario Names**

Names of utility bill scenarios. If multiple scenarios, use a comma-separated list. If not provided, no utility bills scenarios are calculated.

- **Name:** ``utility_bill_scenario_names``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Electricity File Paths**

Electricity tariff file specified as an absolute/relative path to a file with utility rate structure information. Tariff file must be formatted to OpenEI API version 7. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_electricity_filepaths``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Electricity Fixed Charges**

Electricity utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_electricity_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Natural Gas Fixed Charges**

Natural gas utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_natural_gas_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Propane Fixed Charges**

Propane utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_propane_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Fuel Oil Fixed Charges**

Fuel oil utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_fuel_oil_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Coal Fixed Charges**

Coal utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_coal_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Wood Fixed Charges**

Wood utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_wood_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Wood Pellets Fixed Charges**

Wood pellets utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_wood_pellets_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Electricity Marginal Rates**

Electricity utility bill marginal rates. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_electricity_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Natural Gas Marginal Rates**

Natural gas utility bill marginal rates. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_natural_gas_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Propane Marginal Rates**

Propane utility bill marginal rates. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_propane_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Fuel Oil Marginal Rates**

Fuel oil utility bill marginal rates. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_fuel_oil_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Coal Marginal Rates**

Coal utility bill marginal rates. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_coal_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Wood Marginal Rates**

Wood utility bill marginal rates. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_wood_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: Wood Pellets Marginal Rates**

Wood pellets utility bill marginal rates. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_wood_pellets_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: PV Compensation Types**

Utility bill PV compensation types. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_pv_compensation_types``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: PV Net Metering Annual Excess Sellback Rate Types**

Utility bill PV net metering annual excess sellback rate types. Only applies if the PV compensation type is 'NetMetering'. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_pv_net_metering_annual_excess_sellback_rate_types``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: PV Net Metering Annual Excess Sellback Rates**

Utility bill PV net metering annual excess sellback rates. Only applies if the PV compensation type is 'NetMetering' and the PV annual excess sellback rate type is 'User-Specified'. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_pv_net_metering_annual_excess_sellback_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: PV Feed-In Tariff Rates**

Utility bill PV annual full/gross feed-in tariff rates. Only applies if the PV compensation type is 'FeedInTariff'. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_pv_feed_in_tariff_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: PV Monthly Grid Connection Fee Units**

Utility bill PV monthly grid connection fee units. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_pv_monthly_grid_connection_fee_units``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Utility Bills: PV Monthly Grid Connection Fees**

Utility bill PV monthly grid connection fees. If multiple scenarios, use a comma-separated list.

- **Name:** ``utility_bill_pv_monthly_grid_connection_fees``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Additional Properties**

Additional properties specified as key-value pairs (i.e., key=value). If multiple additional properties, use a |-separated list. For example, 'LowIncome=false|Remodeled|Description=2-story home in Denver'. These properties will be stored in the HPXML file under /HPXML/SoftwareInfo/extension/AdditionalProperties.

- **Name:** ``additional_properties``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Combine like surfaces?**

If true, combines like surfaces to simplify the HPXML file generated.

- **Name:** ``combine_like_surfaces``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Apply Default Values?**

If true, applies OS-HPXML default values to the HPXML output file. Setting to true will also force validation of the HPXML output file before applying OS-HPXML default values.

- **Name:** ``apply_defaults``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Apply Validation?**

If true, validates the HPXML output file. Set to false for faster performance. Note that validation is not needed if the HPXML file will be validated downstream (e.g., via the HPXMLtoOpenStudio measure).

- **Name:** ``apply_validation``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>





