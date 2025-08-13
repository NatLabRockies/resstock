
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


- **Default:** `hpxml.xml`

<br/>

**Simulation Control: Timestep**

The timestep for the simulation; defaults to hourly calculations for fastest runtime.

- **Name:** ``simulation_control_timestep``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `60`, `30`, `20`, `15`, `12`, `10`, `6`, `5`, `4`, `3`, `2`, `1`


- **Default:** `60`

<br/>

**Simulation Control: Run Period**

Enter a date range like 'Mar 1 - May 31'. Defaults to the entire year.

- **Name:** ``simulation_control_run_period``
- **Type:** ``String``

- **Required:** ``false``


- **Default:** `Jan 1 - Dec 31`

<br/>

**Location: Zip Code**

Zip code of the home address. Either this or the EnergyPlus Weather (EPW) File Path input below must be provided.

- **Name:** ``location_zip_code``
- **Type:** ``String``

- **Required:** ``false``


<br/>

**Location: EnergyPlus Weather (EPW) File Path**

Path to the EPW file. Either this or the Zip Code input above must be provided.

- **Name:** ``location_epw_path``
- **Type:** ``String``

- **Required:** ``false``


<br/>

**Location: Site Type**

The terrain/shielding of the home, for the infiltration model. Defaults to 'Suburban, Normal' for single-family detached and manufactured home and 'Suburban, Well-Shielded' for single-family attached and apartment units.

- **Name:** ``location_site_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Default`, `Suburban, Normal`, `Suburban, Well-Shielded`, `Suburban, Exposed`, `Urban, Normal`, `Urban, Well-Shielded`, `Urban, Exposed`, `Rural, Normal`, `Rural, Well-Shielded`, `Rural, Exposed`


- **Default:** `Default`

<br/>

**Location: Soil Type**

The soil and moisture type.

- **Name:** ``location_soil_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Unknown`, `Clay, Dry`, `Clay, Mixed`, `Clay, Wet`, `Gravel, Dry`, `Gravel, Mixed`, `Gravel, Wet`, `Loam, Dry`, `Loam, Mixed`, `Loam, Wet`, `Sand, Dry`, `Sand, Mixed`, `Sand, Wet`, `Silt, Dry`, `Silt, Mixed`, `Silt, Wet`, `0.5 Btu/hr-ft-F`, `0.8 Btu/hr-ft-F`, `1.1 Btu/hr-ft-F`, `1.4 Btu/hr-ft-F`, `1.7 Btu/hr-ft-F`, `2.0 Btu/hr-ft-F`, `2.3 Btu/hr-ft-F`, `2.6 Btu/hr-ft-F`, `Detailed Example: Sand, Dry, 0.03 Diffusivity`


- **Default:** `Unknown`

<br/>

**Building Construction: Year Built**

The year the building was built.

- **Name:** ``building_year_built``
- **Type:** ``Integer``

- **Required:** ``false``


- **Default:** `2025`

<br/>

**Geometry: Unit Type**

The type of dwelling unit and number of stories. Includes conditioned attics and excludes conditioned basements.

- **Name:** ``geometry_unit_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Single-Family Detached, 1 Story`, `Single-Family Detached, 2 Stories`, `Single-Family Detached, 3 Stories`, `Single-Family Detached, 4 Stories`, `Single-Family Attached, 1 Story`, `Single-Family Attached, 2 Stories`, `Single-Family Attached, 3 Stories`, `Single-Family Attached, 4 Stories`, `Apartment Unit, 1 Story`, `Manufactured Home, 1 Story`, `Manufactured Home, 2 Stories`, `Manufactured Home, 3 Stories`, `Manufactured Home, 4 Stories`


- **Default:** `Single-Family Detached, 2 Stories`

<br/>

**Geometry: Unit Attached Walls**

For single-family attached and apartment units, the location(s) of the attached walls.

- **Name:** ``geometry_attached_walls``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `1 Side: Front`, `1 Side: Back`, `1 Side: Left`, `1 Side: Right`, `2 Sides: Front, Left`, `2 Sides: Front, Right`, `2 Sides: Back, Left`, `2 Sides: Back, Right`, `2 Sides: Front, Back`, `2 Sides: Left, Right`, `3 Sides: Front, Back, Left`, `3 Sides: Front, Back, Right`, `3 Sides: Front, Left, Right`, `3 Sides: Back, Left, Right`


- **Default:** `None`

<br/>

**Geometry: Unit Conditioned Floor Area**

The total floor area of the unit's conditioned space (including any conditioned basement/attic floor area).

- **Name:** ``geometry_unit_conditioned_floor_area``
- **Type:** ``Double``

- **Units:** ``ft2``

- **Required:** ``true``


- **Default:** `2000.0`

<br/>

**Geometry: Unit Aspect Ratio**

The ratio of front/back wall length to left/right wall length for the unit, excluding any protruding garage wall area.

- **Name:** ``geometry_unit_aspect_ratio``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``


- **Default:** `2.0`

<br/>

**Geometry: Unit Direction**

Direction of the front of the unit.

- **Name:** ``geometry_unit_direction``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `North`, `North-Northeast`, `Northeast`, `East-Northeast`, `East`, `East-Southeast`, `Southeast`, `South-Southeast`, `South`, `South-Southwest`, `Southwest`, `West-Southwest`, `West`, `West-Northwest`, `Northwest`, `North-Northwest`


- **Default:** `South`

<br/>

**Geometry: Unit Number of Bedrooms**

The number of bedrooms in the unit.

- **Name:** ``geometry_unit_num_bedrooms``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `0`, `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`, `10`, `11`, `12`


- **Default:** `3`

<br/>

**Geometry: Unit Number of Bathrooms**

The number of bathrooms in the unit. Defaults to NumberofBedrooms/2 + 0.5.

- **Name:** ``geometry_unit_num_bathrooms``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Default`, `0`, `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`, `10`, `11`, `12`


- **Default:** `Default`

<br/>

**Geometry: Unit Number of Occupants**

The number of occupants in the unit. Defaults to an *asset* calculation assuming standard occupancy, in which various end use defaults (e.g., plug loads, appliances, and hot water usage) are calculated based on Number of Bedrooms and Conditioned Floor Area. If provided, an *operational* calculation is instead performed in which the end use defaults reflect real-world data (where possible).

- **Name:** ``geometry_unit_num_occupants``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Default`, `0`, `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`, `10`, `11`, `12`


- **Default:** `Default`

<br/>

**Geometry: Ceiling Height**

Average distance from the floor to the ceiling.

- **Name:** ``geometry_ceiling_height``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `6.0 ft`, `6.5 ft`, `7.0 ft`, `7.5 ft`, `8.0 ft`, `8.5 ft`, `9.0 ft`, `9.5 ft`, `10.0 ft`, `10.5 ft`, `11.0 ft`, `11.5 ft`, `12.0 ft`, `12.5 ft`, `13.0 ft`, `13.5 ft`, `14.0 ft`, `14.5 ft`, `15.0 ft`


- **Default:** `8.0 ft`

<br/>

**Geometry: Attached Garage**

The type of attached garage. Only applies to single-family detached units.

- **Name:** ``geometry_garage_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `1 Car, Left, Fully Inset`, `1 Car, Left, Half Protruding`, `1 Car, Left, Fully Protruding`, `1 Car, Right, Fully Inset`, `1 Car, Right, Half Protruding`, `1 Car, Right, Fully Protruding`, `2 Car, Left, Fully Inset`, `2 Car, Left, Half Protruding`, `2 Car, Left, Fully Protruding`, `2 Car, Right, Fully Inset`, `2 Car, Right, Half Protruding`, `2 Car, Right, Fully Protruding`, `3 Car, Left, Fully Inset`, `3 Car, Left, Half Protruding`, `3 Car, Left, Fully Protruding`, `3 Car, Right, Fully Inset`, `3 Car, Right, Half Protruding`, `3 Car, Right, Fully Protruding`


- **Default:** `None`

<br/>

**Geometry: Foundation Type**

The foundation type of the building. Garages are assumed to be over slab-on-grade.

- **Name:** ``geometry_foundation_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Slab-on-Grade`, `Crawlspace, Vented`, `Crawlspace, Unvented`, `Crawlspace, Conditioned`, `Basement, Unconditioned`, `Basement, Unconditioned, Half Above-Grade`, `Basement, Conditioned`, `Basement, Conditioned, Half Above-Grade`, `Ambient`, `Above Apartment`, `Belly and Wing, With Skirt`, `Belly and Wing, No Skirt`, `Detailed Example: Basement, Unconditioned, 7.25 ft Height, 8 in Above-Grade, 9 in Rim Joists`, `Detailed Example: Basement, Conditioned, 7.25 ft Height, 8 in Above-Grade, 9 in Rim Joists`, `Detailed Example: Basement, Conditioned, 5 ft Height`, `Detailed Example: Crawlspace, Vented, Above-Grade`


- **Default:** `Crawlspace, Vented`

<br/>

**Geometry: Attic Type**

The attic/roof type of the building.

- **Name:** ``geometry_attic_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Flat Roof`, `Attic, Vented, Gable`, `Attic, Vented, Hip`, `Attic, Unvented, Gable`, `Attic, Unvented, Hip`, `Attic, Conditioned, Gable`, `Attic, Conditioned, Hip`, `Below Apartment`


- **Default:** `Attic, Vented, Gable`

<br/>

**Geometry: Roof Pitch**

The roof pitch of the attic. Ignored if the building has a flat roof.

- **Name:** ``geometry_roof_pitch``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `1:12`, `2:12`, `3:12`, `4:12`, `5:12`, `6:12`, `7:12`, `8:12`, `9:12`, `10:12`, `11:12`, `12:12`, `13:12`, `14:12`, `15:12`, `16:12`


- **Default:** `6:12`

<br/>

**Geometry: Eaves**

The type of eaves extending from the roof.

- **Name:** ``geometry_eaves``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `1 ft`, `2 ft`, `3 ft`, `4 ft`, `5 ft`


- **Default:** `2 ft`

<br/>

**Geometry: Neighbor Buildings**

The presence and geometry of neighboring buildings, for shading purposes.

- **Name:** ``geometry_neighbor_buildings``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Left/Right at 2ft`, `Left/Right at 4ft`, `Left/Right at 5ft`, `Left/Right at 7ft`, `Left/Right at 10ft`, `Left/Right at 12ft`, `Left/Right at 15ft`, `Left/Right at 20ft`, `Left/Right at 25ft`, `Left/Right at 27ft`, `Left at 2ft`, `Left at 4ft`, `Left at 5ft`, `Left at 7ft`, `Left at 10ft`, `Left at 12ft`, `Left at 15ft`, `Left at 20ft`, `Left at 25ft`, `Left at 27ft`, `Right at 2ft`, `Right at 4ft`, `Right at 5ft`, `Right at 7ft`, `Right at 10ft`, `Right at 12ft`, `Right at 15ft`, `Right at 20ft`, `Right at 25ft`, `Right at 27ft`, `Detailed Example: Left/Right at 25ft, Front/Back at 80ft, 12ft Height`


- **Default:** `None`

<br/>

**Geometry: Window Areas or WWRs**

The amount of window area on the unit's front/back/left/right facades. Use a comma-separated list like '0.2, 0.2, 0.1, 0.1' to specify Window-to-Wall Ratios (WWR) or '108, 108, 72, 72' to specify absolute areas. If a facade is adiabatic, the value will be ignored.

- **Name:** ``geometry_window_areas_or_wwrs``
- **Type:** ``String``

- **Required:** ``false``


- **Default:** `0.15, 0.15, 0.15, 0.15`

<br/>

**Geometry: Skylight Areas**

The amount of window area on the unit's front/back/left/right roofs. Use a comma-separated list like '50, 0, 0, 0'.

- **Name:** ``geometry_skylight_areas``
- **Type:** ``String``

- **Required:** ``false``


- **Default:** `0, 0, 0, 0`

<br/>

**Geometry: Doors Area**

The area of the opaque door(s). Any door glazing (e.g., sliding glass doors) should be captured as window area.

- **Name:** ``geometry_door_area``
- **Type:** ``Double``

- **Units:** ``ft2``

- **Required:** ``false``


- **Default:** `20.0`

<br/>

**Enclosure: Floor Over Foundation**

The type and insulation level of the floor over the foundation (e.g., crawlspace or basement).

- **Name:** ``enclosure_floor_over_foundation``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Wood Frame, Uninsulated`, `Wood Frame, R-11`, `Wood Frame, R-13`, `Wood Frame, R-15`, `Wood Frame, R-19`, `Wood Frame, R-21`, `Wood Frame, R-25`, `Wood Frame, R-30`, `Wood Frame, R-35`, `Wood Frame, R-38`, `Wood Frame, IECC U-0.064`, `Wood Frame, IECC U-0.047`, `Wood Frame, IECC U-0.033`, `Wood Frame, IECC U-0.028`, `Detailed Example: Wood Frame, Uninsulated, 2x6, 24 in o.c., 10% Framing, No Carpet/Subfloor`, `Detailed Example: Wood Frame, R-11, 2x6, 24 in o.c., 13% Framing, No Carpet/Subfloor`, `Detailed Example: Wood Frame, R-11, 2x6, 24 in o.c., 10% Framing, No Carpet/Subfloor`


- **Default:** `Wood Frame, Uninsulated`

<br/>

**Enclosure: Floor Over Garage**

The type and insulation level of the floor over the garage.

- **Name:** ``enclosure_floor_over_garage``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Wood Frame, Uninsulated`, `Wood Frame, R-11`, `Wood Frame, R-13`, `Wood Frame, R-15`, `Wood Frame, R-19`, `Wood Frame, R-21`, `Wood Frame, R-25`, `Wood Frame, R-30`, `Wood Frame, R-35`, `Wood Frame, R-38`, `Wood Frame, IECC U-0.064`, `Wood Frame, IECC U-0.047`, `Wood Frame, IECC U-0.033`, `Detailed Example: Wood Frame, Uninsulated, 2x6, 24 in o.c., 10% Framing, No Carpet/Subfloor`, `Detailed Example: Wood Frame, R-11, 2x6, 24 in o.c., 13% Framing, No Carpet/Subfloor`, `Detailed Example: Wood Frame, R-11, 2x6, 24 in o.c., 10% Framing, No Carpet/Subfloor`


- **Default:** `Wood Frame, Uninsulated`

<br/>

**Enclosure: Foundation Wall**

The type and insulation level of the foundation walls.

- **Name:** ``enclosure_foundation_wall``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Solid Concrete, Uninsulated`, `Solid Concrete, Half Wall, R-5`, `Solid Concrete, Half Wall, R-10`, `Solid Concrete, Half Wall, R-15`, `Solid Concrete, Half Wall, R-20`, `Solid Concrete, Whole Wall, R-5`, `Solid Concrete, Whole Wall, R-10`, `Solid Concrete, Whole Wall, R-10.2, Interior`, `Solid Concrete, Whole Wall, R-15`, `Solid Concrete, Whole Wall, R-20`, `Solid Concrete, Assembly R-10.69`, `Concrete Block Foam Core, Whole Wall, R-18.9`


- **Default:** `Solid Concrete, Uninsulated`

<br/>

**Enclosure: Rim Joists**

The type and insulation level of the rim joists.

- **Name:** ``enclosure_rim_joist``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Uninsulated`, `R-7`, `R-11`, `R-13`, `R-15`, `R-19`, `R-21`, `Detailed Example: Uninsulated, Fiberboard Sheathing, Hardboard Siding`, `Detailed Example: R-11, Fiberboard Sheathing, Hardboard Siding`


- **Default:** `Uninsulated`

<br/>

**Enclosure: Slab**

The type and insulation level of the slab. Applies to slab-on-grade as well as basement/crawlspace foundations. Under Slab insulation is placed horizontally from the edge of the slab inward. Perimeter insulation is placed vertically from the top of the slab downward. Whole Slab insulation is placed horizontally below the entire slab area.

- **Name:** ``enclosure_slab``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Uninsulated`, `Under Slab, 2ft, R-5`, `Under Slab, 2ft, R-10`, `Under Slab, 2ft, R-15`, `Under Slab, 2ft, R-20`, `Under Slab, 4ft, R-5`, `Under Slab, 4ft, R-10`, `Under Slab, 4ft, R-15`, `Under Slab, 4ft, R-20`, `Perimeter, 2ft, R-5`, `Perimeter, 2ft, R-10`, `Perimeter, 2ft, R-15`, `Perimeter, 2ft, R-20`, `Perimeter, 4ft, R-5`, `Perimeter, 4ft, R-10`, `Perimeter, 4ft, R-15`, `Perimeter, 4ft, R-20`, `Whole Slab, R-5`, `Whole Slab, R-10`, `Whole Slab, R-15`, `Whole Slab, R-20`, `Whole Slab, R-30`, `Whole Slab, R-40`, `Detailed Example: Uninsulated, No Carpet`, `Detailed Example: Uninsulated, 100% R-2.08 Carpet`, `Detailed Example: Uninsulated, 100% R-2.50 Carpet`, `Detailed Example: Perimeter, 2ft, R-5, 100% R-2.08 Carpet`, `Detailed Example: Whole Slab, R-5, 100% R-2.5 Carpet`


- **Default:** `Uninsulated`

<br/>

**Enclosure: Ceiling**

The type and insulation level of the ceiling (attic floor).

- **Name:** ``enclosure_ceiling``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Uninsulated`, `R-7`, `R-13`, `R-19`, `R-30`, `R-38`, `R-49`, `R-60`, `IECC U-0.035`, `IECC U-0.030`, `IECC U-0.026`, `IECC U-0.024`, `Detailed Example: R-11, 2x6, 24 in o.c., 10% Framing`, `Detailed Example: R-19, 2x6, 24 in o.c., 10% Framing`, `Detailed Example: R-19 + R-38, 2x6, 24 in o.c., 10% Framing`


- **Default:** `R-30`

<br/>

**Enclosure: Roof**

The type and insulation level of the roof.

- **Name:** ``enclosure_roof``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Uninsulated`, `R-7`, `R-13`, `R-19`, `R-30`, `R-38`, `R-49`, `IECC U-0.035`, `IECC U-0.030`, `IECC U-0.026`, `IECC U-0.024`, `Detailed Example: Uninsulated, 0.5 in plywood, 0.25 in asphalt shingle`


- **Default:** `Uninsulated`

<br/>

**Enclosure: Roof Material**

The material type and color of the roof.

- **Name:** ``enclosure_roof_material``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Asphalt/Fiberglass Shingles, Dark`, `Asphalt/Fiberglass Shingles, Medium Dark`, `Asphalt/Fiberglass Shingles, Medium`, `Asphalt/Fiberglass Shingles, Light`, `Asphalt/Fiberglass Shingles, Reflective`, `Tile/Slate, Dark`, `Tile/Slate, Medium Dark`, `Tile/Slate, Medium`, `Tile/Slate, Light`, `Tile/Slate, Reflective`, `Metal, Dark`, `Metal, Medium Dark`, `Metal, Medium`, `Metal, Light`, `Metal, Reflective`, `Wood Shingles/Shakes, Dark`, `Wood Shingles/Shakes, Medium Dark`, `Wood Shingles/Shakes, Medium`, `Wood Shingles/Shakes, Light`, `Wood Shingles/Shakes, Reflective`, `Shingles, Dark`, `Shingles, Medium Dark`, `Shingles, Medium`, `Shingles, Light`, `Shingles, Reflective`, `Synthetic Sheeting, Dark`, `Synthetic Sheeting, Medium Dark`, `Synthetic Sheeting, Medium`, `Synthetic Sheeting, Light`, `Synthetic Sheeting, Reflective`, `EPS Sheathing, Dark`, `EPS Sheathing, Medium Dark`, `EPS Sheathing, Medium`, `EPS Sheathing, Light`, `EPS Sheathing, Reflective`, `Concrete, Dark`, `Concrete, Medium Dark`, `Concrete, Medium`, `Concrete, Light`, `Concrete, Reflective`, `Cool Roof`, `Detailed Example: 0.2 Solar Absorptance`, `Detailed Example: 0.4 Solar Absorptance`, `Detailed Example: 0.6 Solar Absorptance`, `Detailed Example: 0.75 Solar Absorptance`


- **Default:** `Asphalt/Fiberglass Shingles, Medium`

<br/>

**Enclosure: Radiant Barrier**

The type of radiant barrier in the attic.

- **Name:** ``enclosure_radiant_barrier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Attic Roof Only`, `Attic Roof and Gable Walls`, `Attic Floor`


- **Default:** `None`

<br/>

**Enclosure: Walls**

The type and insulation level of the walls.

- **Name:** ``enclosure_wall``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Wood Stud, Uninsulated`, `Wood Stud, R-7`, `Wood Stud, R-11`, `Wood Stud, R-13`, `Wood Stud, R-15`, `Wood Stud, R-19`, `Wood Stud, R-21`, `Double Wood Stud, R-33`, `Double Wood Stud, R-39`, `Double Wood Stud, R-45`, `Steel Stud, Uninsulated`, `Steel Stud, R-11`, `Steel Stud, R-13`, `Steel Stud, R-15`, `Steel Stud, R-19`, `Steel Stud, R-21`, `Steel Stud, R-25`, `Concrete Masonry Unit, Hollow or Concrete Filled, Uninsulated`, `Concrete Masonry Unit, Hollow or Concrete Filled, R-7`, `Concrete Masonry Unit, Hollow or Concrete Filled, R-11`, `Concrete Masonry Unit, Hollow or Concrete Filled, R-13`, `Concrete Masonry Unit, Hollow or Concrete Filled, R-15`, `Concrete Masonry Unit, Hollow or Concrete Filled, R-19`, `Concrete Masonry Unit, Perlite Filled, Uninsulated`, `Concrete Masonry Unit, Perlite Filled, R-7`, `Concrete Masonry Unit, Perlite Filled, R-11`, `Concrete Masonry Unit, Perlite Filled, R-13`, `Concrete Masonry Unit, Perlite Filled, R-15`, `Concrete Masonry Unit, Perlite Filled, R-19`, `Structural Insulated Panel, R-17.5`, `Structural Insulated Panel, R-27.5`, `Structural Insulated Panel, R-37.5`, `Structural Insulated Panel, R-47.5`, `Insulated Concrete Forms, R-5 per side`, `Insulated Concrete Forms, R-10 per side`, `Insulated Concrete Forms, R-15 per side`, `Insulated Concrete Forms, R-20 per side`, `Structural Brick, Uninsulated`, `Structural Brick, R-7`, `Structural Brick, R-11`, `Structural Brick, R-15`, `Structural Brick, R-19`, `Wood Stud, IECC U-0.084`, `Wood Stud, IECC U-0.082`, `Wood Stud, IECC U-0.060`, `Wood Stud, IECC U-0.057`, `Wood Stud, IECC U-0.048`, `Wood Stud, IECC U-0.045`, `Detailed Example: Wood Stud, Uninsulated, 2x4, 16 in o.c., 25% Framing`, `Detailed Example: Wood Stud, R-11, 2x4, 16 in o.c., 25% Framing`, `Detailed Example: Wood Stud, R-18, 2x6, 24 in o.c., 25% Framing`


- **Default:** `Wood Stud, R-13`

<br/>

**Enclosure: Wall Continuous Insulation**

The insulation level of the wall continuous insulation. The R-value of the continuous insulation will be ignored if a wall option with an IECC U-factor is selected.

- **Name:** ``enclosure_wall_continuous_insulation``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Uninsulated`, `R-5`, `R-6`, `R-7`, `R-10`, `R-12`, `R-14`, `R-15`, `R-18`, `R-20`, `R-21`, `Detailed Example: R-7.2`


- **Default:** `Uninsulated`

<br/>

**Enclosure: Wall Siding**

The type, color, and insulation level of the wall siding. The R-value of the siding will be ignored if a wall option with an IECC U-factor is selected.

- **Name:** ``enclosure_wall_siding``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Aluminum, Dark`, `Aluminum, Medium`, `Aluminum, Medium Dark`, `Aluminum, Light`, `Aluminum, Reflective`, `Brick, Dark`, `Brick, Medium`, `Brick, Medium Dark`, `Brick, Light`, `Brick, Reflective`, `Fiber-Cement, Dark`, `Fiber-Cement, Medium`, `Fiber-Cement, Medium Dark`, `Fiber-Cement, Light`, `Fiber-Cement, Reflective`, `Asbestos, Dark`, `Asbestos, Medium`, `Asbestos, Medium Dark`, `Asbestos, Light`, `Asbestos, Reflective`, `Composition Shingle, Dark`, `Composition Shingle, Medium`, `Composition Shingle, Medium Dark`, `Composition Shingle, Light`, `Composition Shingle, Reflective`, `Stucco, Dark`, `Stucco, Medium`, `Stucco, Medium Dark`, `Stucco, Light`, `Stucco, Reflective`, `Vinyl, Dark`, `Vinyl, Medium`, `Vinyl, Medium Dark`, `Vinyl, Light`, `Vinyl, Reflective`, `Wood, Dark`, `Wood, Medium`, `Wood, Medium Dark`, `Wood, Light`, `Wood, Reflective`, `Synthetic Stucco, Dark`, `Synthetic Stucco, Medium`, `Synthetic Stucco, Medium Dark`, `Synthetic Stucco, Light`, `Synthetic Stucco, Reflective`, `Masonite, Dark`, `Masonite, Medium`, `Masonite, Medium Dark`, `Masonite, Light`, `Masonite, Reflective`, `Detailed Example: 0.2 Solar Absorptance`, `Detailed Example: 0.4 Solar Absorptance`, `Detailed Example: 0.6 Solar Absorptance`, `Detailed Example: 0.75 Solar Absorptance`


- **Default:** `Wood, Medium`

<br/>

**Enclosure: Windows**

The type of windows.

- **Name:** ``enclosure_window``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Single, Clear, Metal`, `Single, Clear, Non-Metal`, `Double, Clear, Metal, Air`, `Double, Clear, Thermal-Break, Air`, `Double, Clear, Non-Metal, Air`, `Double, Low-E, Non-Metal, Air, High Gain`, `Double, Low-E, Non-Metal, Air, Med Gain`, `Double, Low-E, Non-Metal, Air, Low Gain`, `Double, Low-E, Non-Metal, Gas, High Gain`, `Double, Low-E, Non-Metal, Gas, Med Gain`, `Double, Low-E, Non-Metal, Gas, Low Gain`, `Double, Low-E, Insulated, Air, High Gain`, `Double, Low-E, Insulated, Air, Med Gain`, `Double, Low-E, Insulated, Air, Low Gain`, `Double, Low-E, Insulated, Gas, High Gain`, `Double, Low-E, Insulated, Gas, Med Gain`, `Double, Low-E, Insulated, Gas, Low Gain`, `Triple, Low-E, Non-Metal, Air, High Gain`, `Triple, Low-E, Non-Metal, Air, Low Gain`, `Triple, Low-E, Non-Metal, Gas, High Gain`, `Triple, Low-E, Non-Metal, Gas, Low Gain`, `Triple, Low-E, Insulated, Air, High Gain`, `Triple, Low-E, Insulated, Air, Low Gain`, `Triple, Low-E, Insulated, Gas, High Gain`, `Triple, Low-E, Insulated, Gas, Low Gain`, `IECC U-1.20, SHGC 0.40`, `IECC U-1.20, SHGC 0.30`, `IECC U-1.20, SHGC 0.25`, `IECC U-0.75, SHGC 0.40`, `IECC U-0.65, SHGC 0.40`, `IECC U-0.65, SHGC 0.30`, `IECC U-0.50, SHGC 0.30`, `IECC U-0.50, SHGC 0.25`, `IECC U-0.40, SHGC 0.40`, `IECC U-0.40, SHGC 0.25`, `IECC U-0.35, SHGC 0.40`, `IECC U-0.35, SHGC 0.30`, `IECC U-0.35, SHGC 0.25`, `IECC U-0.32, SHGC 0.25`, `IECC U-0.30, SHGC 0.25`, `Detailed Example: Single, Clear, Aluminum w/ Thermal Break`, `Detailed Example: Double, Low-E, Wood, Argon, Insulated Spacer`


- **Default:** `Double, Clear, Metal, Air`

<br/>

**Enclosure: Window Natural Ventilation**

The amount of natural ventilation from occupants opening operable windows when outdoor conditions are favorable.

- **Name:** ``enclosure_window_natural_ventilation``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `33% Operable Windows`, `50% Operable Windows`, `67% Operable Windows`, `100% Operable Windows`, `Detailed Example: 67% Operable Windows, 7 Days/Week`


- **Default:** `67% Operable Windows`

<br/>

**Enclosure: Window Interior Shading**

The type of window interior shading. If shading coefficients are selected, note they indicate the reduction in solar gain (e.g., 0.7 indicates 30% reduction).

- **Name:** ``enclosure_window_interior_shading``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Curtains, Light`, `Curtains, Medium`, `Curtains, Dark`, `Shades, Light`, `Shades, Medium`, `Shades, Dark`, `Blinds, Light`, `Blinds, Medium`, `Blinds, Dark`, `Summer 0.5, Winter 0.5`, `Summer 0.5, Winter 0.6`, `Summer 0.5, Winter 0.7`, `Summer 0.5, Winter 0.8`, `Summer 0.5, Winter 0.9`, `Summer 0.6, Winter 0.6`, `Summer 0.6, Winter 0.7`, `Summer 0.6, Winter 0.8`, `Summer 0.6, Winter 0.9`, `Summer 0.7, Winter 0.7`, `Summer 0.7, Winter 0.8`, `Summer 0.7, Winter 0.9`, `Summer 0.8, Winter 0.8`, `Summer 0.8, Winter 0.9`, `Summer 0.9, Winter 0.9`


- **Default:** `Curtains, Light`

<br/>

**Enclosure: Window Exterior Shading**

The type of window exterior shading. If shading coefficients are selected, note they indicate the reduction in solar gain (e.g., 0.7 indicates 30% reduction).

- **Name:** ``enclosure_window_exterior_shading``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Solar Film`, `Solar Screen`, `Summer 0.25, Winter 0.25`, `Summer 0.25, Winter 0.50`, `Summer 0.25, Winter 0.75`, `Summer 0.25, Winter 1.00`, `Summer 0.50, Winter 0.25`, `Summer 0.50, Winter 0.50`, `Summer 0.50, Winter 0.75`, `Summer 0.50, Winter 1.00`, `Summer 0.75, Winter 0.25`, `Summer 0.75, Winter 0.50`, `Summer 0.75, Winter 0.75`, `Summer 0.75, Winter 1.00`, `Summer 1.00, Winter 0.25`, `Summer 1.00, Winter 0.50`, `Summer 1.00, Winter 0.75`, `Summer 1.00, Winter 1.00`


- **Default:** `None`

<br/>

**Enclosure: Window Insect Screens**

The type of window insect screens.

- **Name:** ``enclosure_window_insect_screens``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Exterior`, `Interior`


- **Default:** `None`

<br/>

**Enclosure: Window Storm**

The type of storm window.

- **Name:** ``enclosure_window_storm``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Clear`, `Low-E`


- **Default:** `None`

<br/>

**Enclosure: Window Overhangs**

The type of window overhangs.

- **Name:** ``enclosure_overhangs``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `1ft, All Windows`, `2ft, All Windows`, `3ft, All Windows`, `4ft, All Windows`, `5ft, All Windows`, `10ft, All Windows`, `1ft, Front Windows`, `2ft, Front Windows`, `3ft, Front Windows`, `4ft, Front Windows`, `5ft, Front Windows`, `10ft, Front Windows`, `1ft, Back Windows`, `2ft, Back Windows`, `3ft, Back Windows`, `4ft, Back Windows`, `5ft, Back Windows`, `10ft, Back Windows`, `1ft, Left Windows`, `2ft, Left Windows`, `3ft, Left Windows`, `4ft, Left Windows`, `5ft, Left Windows`, `10ft, Left Windows`, `1ft, Right Windows`, `2ft, Right Windows`, `3ft, Right Windows`, `4ft, Right Windows`, `5ft, Right Windows`, `10ft, Right Windows`, `Detailed Example: 1.5ft, Back/Left/Right Windows, 2ft Offset, 4ft Window Height`, `Detailed Example: 2.5ft, Front Windows, 1ft Offset, 5ft Window Height`


- **Default:** `None`

<br/>

**Enclosure: Skylights**

The type of skylights.

- **Name:** ``enclosure_skylight``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Single, Clear, Metal`, `Single, Clear, Non-Metal`, `Double, Clear, Metal`, `Double, Clear, Non-Metal`, `Double, Low-E, Metal, High Gain`, `Double, Low-E, Non-Metal, High Gain`, `Double, Low-E, Metal, Med Gain`, `Double, Low-E, Non-Metal, Med Gain`, `Double, Low-E, Metal, Low Gain`, `Double, Low-E, Non-Metal, Low Gain`, `Triple, Clear, Metal`, `Triple, Clear, Non-Metal`, `IECC U-0.75, SHGC 0.40`, `IECC U-0.75, SHGC 0.30`, `IECC U-0.75, SHGC 0.25`, `IECC U-0.65, SHGC 0.40`, `IECC U-0.65, SHGC 0.30`, `IECC U-0.65, SHGC 0.25`, `IECC U-0.60, SHGC 0.40`, `IECC U-0.60, SHGC 0.30`, `IECC U-0.55, SHGC 0.40`, `IECC U-0.55, SHGC 0.25`


- **Default:** `Single, Clear, Metal`

<br/>

**Enclosure: Doors**

The type of doors.

- **Name:** ``enclosure_door``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Solid Wood, R-2`, `Solid Wood, R-3`, `Insulated Fiberglass/Steel, R-4`, `Insulated Fiberglass/Steel, R-5`, `Insulated Fiberglass/Steel, R-6`, `Insulated Fiberglass/Steel, R-7`, `IECC U-1.20`, `IECC U-0.75`, `IECC U-0.65`, `IECC U-0.50`, `IECC U-0.40`, `IECC U-0.35`, `IECC U-0.32`, `IECC U-0.30`, `Detailed Example: Solid Wood, R-3.04`, `Detailed Example: Insulated Fiberglass/Steel, R-4.4`


- **Default:** `Solid Wood, R-2`

<br/>

**Enclosure: Air Leakage**

The amount of air leakage coming from outside. If a qualitative leakiness description (e.g., 'Average') is selected, the Year Built of the home is also required.

- **Name:** ``enclosure_air_leakage``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Very Tight`, `Tight`, `Average`, `Leaky`, `Very Leaky`, `1 ACH50`, `2 ACH50`, `3 ACH50`, `4 ACH50`, `5 ACH50`, `6 ACH50`, `7 ACH50`, `8 ACH50`, `10 ACH50`, `15 ACH50`, `20 ACH50`, `25 ACH50`, `30 ACH50`, `40 ACH50`, `50 ACH50`, `0.2 nACH`, `0.3 nACH`, `0.335 nACH`, `0.5 nACH`, `0.67 nACH`, `1.0 nACH`, `1.5 nACH`, `Detailed Example: 3.57 ACH50`, `Detailed Example: 12.16 ACH50`, `Detailed Example: 2.8 ACH45`, `Detailed Example: 0.375 nACH`, `Detailed Example: 72 nCFM`, `Detailed Example: 79.8 sq. in. ELA`, `Detailed Example: 123 sq. in. ELA`, `Detailed Example: 1080 CFM50`, `Detailed Example: 1010 CFM45`


- **Default:** `Average`

<br/>

**HVAC: Heating System**

The type and efficiency of the heating system. Use 'None' if there is no heating system or if there is a heat pump serving a heating load.

- **Name:** ``hvac_heating_system``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `None`, `Electric Resistance`, `Central Furnace, 60% AFUE`, `Central Furnace, 64% AFUE`, `Central Furnace, 68% AFUE`, `Central Furnace, 72% AFUE`, `Central Furnace, 76% AFUE`, `Central Furnace, 78% AFUE`, `Central Furnace, 80% AFUE`, `Central Furnace, 85% AFUE`, `Central Furnace, 90% AFUE`, `Central Furnace, 92% AFUE`, `Central Furnace, 92.5% AFUE`, `Central Furnace, 96% AFUE`, `Central Furnace, 98% AFUE`, `Central Furnace, 100% AFUE`, `Wall Furnace, 60% AFUE`, `Wall Furnace, 68% AFUE`, `Wall Furnace, 82% AFUE`, `Wall Furnace, 98% AFUE`, `Wall Furnace, 100% AFUE`, `Floor Furnace, 60% AFUE`, `Floor Furnace, 70% AFUE`, `Floor Furnace, 80% AFUE`, `Boiler, 60% AFUE`, `Boiler, 72% AFUE`, `Boiler, 76% AFUE`, `Boiler, 78% AFUE`, `Boiler, 80% AFUE`, `Boiler, 82% AFUE`, `Boiler, 85% AFUE`, `Boiler, 90% AFUE`, `Boiler, 92% AFUE`, `Boiler, 92.5% AFUE`, `Boiler, 95% AFUE`, `Boiler, 96% AFUE`, `Boiler, 98% AFUE`, `Boiler, 100% AFUE`, `Stove, 60% Efficiency`, `Stove, 70% Efficiency`, `Stove, 80% Efficiency`, `Space Heater, 60% Efficiency`, `Space Heater, 70% Efficiency`, `Space Heater, 80% Efficiency`, `Space Heater, 92% Efficiency`, `Space Heater, 100% Efficiency`, `Fireplace, 60% Efficiency`, `Fireplace, 70% Efficiency`, `Fireplace, 80% Efficiency`, `Fireplace, 100% Efficiency`, `Detailed Example: Central Furnace, 92% AFUE, 600 Btu/hr Pilot Light`, `Detailed Example: Floor Furnace, 80% AFUE, 600 Btu/hr Pilot Light`, `Detailed Example: Boiler, 92% AFUE, 600 Btu/hr Pilot Light`


- **Default:** `Central Furnace, 78% AFUE`

<br/>

**HVAC: Heating System Fuel Type**

The fuel type of the heating system. Ignored for ElectricResistance.

- **Name:** ``hvac_heating_system_fuel``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Electricity`, `Natural Gas`, `Fuel Oil`, `Propane`, `Wood Cord`, `Wood Pellets`, `Coal`


- **Default:** `Natural Gas`

<br/>

**HVAC: Heating System Capacity**

The output capacity of the heating system.

- **Name:** ``hvac_heating_system_capacity``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Autosize`, `5 kBtu/hr`, `10 kBtu/hr`, `15 kBtu/hr`, `20 kBtu/hr`, `25 kBtu/hr`, `30 kBtu/hr`, `35 kBtu/hr`, `40 kBtu/hr`, `45 kBtu/hr`, `50 kBtu/hr`, `55 kBtu/hr`, `60 kBtu/hr`, `65 kBtu/hr`, `70 kBtu/hr`, `75 kBtu/hr`, `80 kBtu/hr`, `85 kBtu/hr`, `90 kBtu/hr`, `95 kBtu/hr`, `100 kBtu/hr`, `105 kBtu/hr`, `110 kBtu/hr`, `115 kBtu/hr`, `120 kBtu/hr`, `125 kBtu/hr`, `130 kBtu/hr`, `135 kBtu/hr`, `140 kBtu/hr`, `145 kBtu/hr`, `150 kBtu/hr`, `Detailed Example: Autosize, 140% Multiplier`, `Detailed Example: Autosize, 170% Multiplier`, `Detailed Example: Autosize, 90% Multiplier, 45 kBtu/hr Limit`, `Detailed Example: Autosize, 140% Multiplier, 45 kBtu/hr Limit`


- **Default:** `Autosize`

<br/>

**HVAC: Heating System Fraction Heat Load Served**

The fraction of the heating load served by the heating system.

- **Name:** ``hvac_heating_system_heating_load_served``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `100%`, `95%`, `90%`, `85%`, `80%`, `75%`, `70%`, `65%`, `60%`, `55%`, `50%`, `45%`, `40%`, `35%`, `30%`, `25%`, `20%`, `15%`, `10%`, `5%`, `0%`


- **Default:** `100%`

<br/>

**HVAC: Cooling System**

The type and efficiency of the cooling system. Use 'None' if there is no cooling system or if there is a heat pump serving a cooling load.

- **Name:** ``hvac_cooling_system``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `None`, `Central AC, SEER 8`, `Central AC, SEER 10`, `Central AC, SEER 13`, `Central AC, SEER 14`, `Central AC, SEER 15`, `Central AC, SEER 16`, `Central AC, SEER 17`, `Central AC, SEER 18`, `Central AC, SEER 21`, `Central AC, SEER 24`, `Central AC, SEER 24.5`, `Central AC, SEER 27`, `Central AC, SEER2 12.4`, `Mini-Split AC, SEER 13`, `Mini-Split AC, SEER 17`, `Mini-Split AC, SEER 19`, `Mini-Split AC, SEER 19, Ducted`, `Mini-Split AC, SEER 24`, `Mini-Split AC, SEER 25`, `Mini-Split AC, SEER 29.3`, `Mini-Split AC, SEER 33`, `Room AC, EER 8.5`, `Room AC, EER 8.5, Electric Resistance Heating`, `Room AC, EER 9.8`, `Room AC, EER 10.7`, `Room AC, EER 12.0`, `Room AC, CEER 8.4`, `Packaged Terminal AC, EER 10.7`, `Packaged Terminal AC, EER 10.7, Electric Resistance Heating`, `Packaged Terminal AC, EER 10.7, 80% AFUE Gas Heating`, `Evaporative Cooler`, `Evaporative Cooler, Ducted`, `Detailed Example: Central AC, SEER 13, Absolute Detailed Performance`, `Detailed Example: Central AC, SEER 18, Absolute Detailed Performance`, `Detailed Example: Central AC, SEER 17.5, Absolute Detailed Performance`, `Detailed Example: Central AC, SEER 17.5, Normalized Detailed Performance`, `Detailed Example: Mini-Split AC, SEER 17, Absolute Detailed Performance`, `Detailed Example: Mini-Split AC, SEER 17, Normalized Detailed Performance`


- **Default:** `Central AC, SEER 13`

<br/>

**HVAC: Cooling System Capacity**

The output capacity of the cooling system.

- **Name:** ``hvac_cooling_system_capacity``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Autosize`, `0.5 tons`, `0.75 tons`, `1.0 tons`, `1.5 tons`, `2.0 tons`, `2.5 tons`, `3.0 tons`, `3.5 tons`, `4.0 tons`, `4.5 tons`, `5.0 tons`, `5.5 tons`, `6.0 tons`, `6.5 tons`, `7.0 tons`, `7.5 tons`, `8.0 tons`, `8.5 tons`, `9.0 tons`, `9.5 tons`, `10.0 tons`, `Detailed Example: Autosize, 140% Multiplier`, `Detailed Example: Autosize, 170% Multiplier`, `Detailed Example: Autosize, 170% Multiplier, 3.0 tons Limit`


- **Default:** `Autosize`

<br/>

**HVAC: Cooling System Fraction Cool Load Served**

The fraction of the cooling load served by the cooling system.

- **Name:** ``hvac_cooling_system_cooling_load_served``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `100%`, `95%`, `90%`, `85%`, `80%`, `75%`, `70%`, `65%`, `60%`, `55%`, `50%`, `45%`, `40%`, `35%`, `30%`, `25%`, `20%`, `15%`, `10%`, `5%`, `0%`


- **Default:** `100%`

<br/>

**HVAC: Cooling System Integrated Heating Capacity**

The output capacity of the cooling system's integrated heating system. Only used for packaged terminal air conditioner and room air conditioner systems with integrated heating.

- **Name:** ``hvac_cooling_system_integrated_heating_capacity``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Autosize`, `5 kBtu/hr`, `10 kBtu/hr`, `15 kBtu/hr`, `20 kBtu/hr`, `25 kBtu/hr`, `30 kBtu/hr`, `35 kBtu/hr`, `40 kBtu/hr`, `45 kBtu/hr`, `50 kBtu/hr`, `55 kBtu/hr`, `60 kBtu/hr`, `65 kBtu/hr`, `70 kBtu/hr`, `75 kBtu/hr`, `80 kBtu/hr`, `85 kBtu/hr`, `90 kBtu/hr`, `95 kBtu/hr`, `100 kBtu/hr`, `105 kBtu/hr`, `110 kBtu/hr`, `115 kBtu/hr`, `120 kBtu/hr`, `125 kBtu/hr`, `130 kBtu/hr`, `135 kBtu/hr`, `140 kBtu/hr`, `145 kBtu/hr`, `150 kBtu/hr`


- **Default:** `Autosize`

<br/>

**HVAC: Cooling System Integrated Heating Fraction Heat Load Served**

The fraction of the heating load served by the cooling system's integrated heating system.

- **Name:** ``hvac_cooling_system_integrated_heating_load_served``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `100%`, `95%`, `90%`, `85%`, `80%`, `75%`, `70%`, `65%`, `60%`, `55%`, `50%`, `45%`, `40%`, `35%`, `30%`, `25%`, `20%`, `15%`, `10%`, `5%`, `0%`


- **Default:** `100%`

<br/>

**HVAC: Heat Pump**

The type and efficiency of the heat pump.

- **Name:** ``hvac_heat_pump``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `None`, `Central HP, SEER 8, 6.0 HSPF`, `Central HP, SEER 10, 6.2 HSPF`, `Central HP, SEER 10, 6.8 HSPF`, `Central HP, SEER 10.3, 7.0 HSPF`, `Central HP, SEER 11.5, 7.5 HSPF`, `Central HP, SEER 13, 7.7 HSPF`, `Central HP, SEER 13, 8.0 HSPF`, `Central HP, SEER 13, 9.85 HSPF`, `Central HP, SEER 14, 8.2 HSPF`, `Central HP, SEER 14.3, 8.5 HSPF`, `Central HP, SEER 15, 8.5 HSPF`, `Central HP, SEER 15, 9.0 HSPF`, `Central HP, SEER 16, 9.0 HSPF`, `Central HP, SEER 17, 8.7 HSPF`, `Central HP, SEER 18, 9.3 HSPF`, `Central HP, SEER 20, 11 HSPF`, `Central HP, SEER 22, 10 HSPF`, `Central HP, SEER 24, 13 HSPF`, `Mini-Split HP, SEER 14.5, 8.2 HSPF`, `Mini-Split HP, SEER 14.5, 8.2 HSPF, Ducted`, `Mini-Split HP, SEER 16, 9.2 HSPF`, `Mini-Split HP, SEER 17, 9.5 HSPF`, `Mini-Split HP, SEER 17, 9.5 HSPF, Ducted`, `Mini-Split HP, SEER 18.0, 9.6 HSPF`, `Mini-Split HP, SEER 18.0, 9.6 HSPF, Ducted`, `Mini-Split HP, SEER 19, 10 HSPF, Ducted`, `Mini-Split HP, SEER 19, 10 HSPF`, `Mini-Split HP, SEER 20, 11 HSPF`, `Mini-Split HP, SEER 24, 13 HSPF`, `Mini-Split HP, SEER 25, 12.7 HSPF`, `Mini-Split HP, SEER 25, 12.7 HSPF, Ducted`, `Mini-Split HP, SEER 29.3, 14 HSPF`, `Mini-Split HP, SEER 29.3, 14 HSPF, Ducted`, `Mini-Split HP, SEER 33, 13.3 HSPF`, `Mini-Split HP, SEER 33, 13.3 HSPF, Ducted`, `Geothermal HP, EER 16.6, COP 3.6`, `Geothermal HP, EER 18.2, COP 3.7`, `Geothermal HP, EER 18.6, COP 3.8`, `Geothermal HP, EER 19.4, COP 3.8`, `Geothermal HP, EER 20.2, COP 4.2`, `Geothermal HP, EER 20.5, COP 4.0`, `Geothermal HP, EER 30.9, COP 4.4`, `Packaged Terminal HP, EER 11.4, COP 3.6`, `Room AC w/ Reverse Cycle, EER 11.4, COP 3.6`, `Detailed Example: Central HP, SEER2 12.4, HSPF2 6.5`, `Detailed Example: Central HP, SEER 13, 7.7 HSPF, Absolute Detailed Performance`, `Detailed Example: Central HP, SEER 18, 9.3 HSPF, Absolute Detailed Performance`, `Detailed Example: Central HP, SEER 17.5, 9.5 HSPF, Absolute Detailed Performance`, `Detailed Example: Central HP, SEER 17.5, 9.5 HSPF, Normalized Detailed Performance`, `Detailed Example: Mini-Split HP, SEER 16.7, 11.3 HSPF, Absolute Detailed Performance`, `Detailed Example: Mini-Split HP, SEER 16.7, 11.3 HSPF, Normalized Detailed Performance`, `Detailed Example: Mini-Split HP, SEER 17, 10 HSPF, Absolute Detailed Performance`, `Detailed Example: Mini-Split HP, SEER 17, 10 HSPF, Normalized Detailed Performance`


- **Default:** `None`

<br/>

**HVAC: Heat Pump Capacity**

The output capacity of the heat pump.

- **Name:** ``hvac_heat_pump_capacity``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Autosize`, `Autosize (ACCA)`, `Autosize (MaxLoad)`, `0.5 tons`, `0.75 tons`, `1.0 tons`, `1.5 tons`, `2.0 tons`, `2.5 tons`, `3.0 tons`, `3.5 tons`, `4.0 tons`, `4.5 tons`, `5.0 tons`, `5.5 tons`, `6.0 tons`, `6.5 tons`, `7.0 tons`, `7.5 tons`, `8.0 tons`, `8.5 tons`, `9.0 tons`, `9.5 tons`, `10.0 tons`, `Detailed Example: Autosize, 140% Multiplier`, `Detailed Example: Autosize, 170% Multiplier`, `Detailed Example: Autosize, 170% Multiplier, 3.0 tons Limit`


- **Default:** `Autosize`

<br/>

**HVAC: Heat Pump Fraction Heat Load Served**

The fraction of the heating load served by the heat pump.

- **Name:** ``hvac_heat_pump_heating_load_served``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `100%`, `95%`, `90%`, `85%`, `80%`, `75%`, `70%`, `65%`, `60%`, `55%`, `50%`, `45%`, `40%`, `35%`, `30%`, `25%`, `20%`, `15%`, `10%`, `5%`, `0%`


- **Default:** `100%`

<br/>

**HVAC: Heat Pump Fraction Cool Load Served**

The fraction of the cooling load served by the heat pump.

- **Name:** ``hvac_heat_pump_cooling_load_served``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `100%`, `95%`, `90%`, `85%`, `80%`, `75%`, `70%`, `65%`, `60%`, `55%`, `50%`, `45%`, `40%`, `35%`, `30%`, `25%`, `20%`, `15%`, `10%`, `5%`, `0%`


- **Default:** `100%`

<br/>

**HVAC: Heat Pump Temperatures**

Specifies the minimum compressor temperature and/or maximum HP backup temperature. If both are the same, a binary switchover temperature is used.

- **Name:** ``hvac_heat_pump_temperatures``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Default`, `-20F Min Compressor Temp`, `-15F Min Compressor Temp`, `-10F Min Compressor Temp`, `-5F Min Compressor Temp`, `0F Min Compressor Temp`, `5F Min Compressor Temp`, `10F Min Compressor Temp`, `15F Min Compressor Temp`, `20F Min Compressor Temp`, `25F Min Compressor Temp`, `30F Min Compressor Temp`, `35F Min Compressor Temp`, `40F Min Compressor Temp`, `30F Min Compressor Temp, 30F Max HP Backup Temp`, `35F Min Compressor Temp, 35F Max HP Backup Temp`, `40F Min Compressor Temp, 40F Max HP Backup Temp`, `Detailed Example: 5F Min Compressor Temp, 35F Max HP Backup Temp`, `Detailed Example: 25F Min Compressor Temp, 45F Max HP Backup Temp`


- **Default:** `Default`

<br/>

**HVAC: Heat Pump Backup Type**

The type and efficiency of the heat pump backup. Use 'None' if there is no backup heating. If Backup Type is Separate Heating System, Heating System 2 is used to specify the backup.

- **Name:** ``hvac_heat_pump_backup``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Integrated, Electricity, 100% Efficiency`, `Integrated, Natural Gas, 60% AFUE`, `Integrated, Natural Gas, 76% AFUE`, `Integrated, Natural Gas, 80% AFUE`, `Integrated, Natural Gas, 92.5% AFUE`, `Integrated, Natural Gas, 95% AFUE`, `Integrated, Fuel Oil, 60% AFUE`, `Integrated, Fuel Oil, 76% AFUE`, `Integrated, Fuel Oil, 80% AFUE`, `Integrated, Fuel Oil, 92.5% AFUE`, `Integrated, Fuel Oil, 95% AFUE`, `Integrated, Propane, 60% AFUE`, `Integrated, Propane, 76% AFUE`, `Integrated, Propane, 80% AFUE`, `Integrated, Propane, 92.5% AFUE`, `Integrated, Propane, 95% AFUE`, `Separate Heating System`


- **Default:** `Integrated, Electricity, 100% Efficiency`

<br/>

**HVAC: Heat Pump Backup Capacity**

The output capacity of the heat pump backup if there is integrated backup heating.

- **Name:** ``hvac_heat_pump_backup_capacity``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Autosize`, `Autosize (Supplemental)`, `5 kW`, `10 kW`, `15 kW`, `20 kW`, `25 kW`, `5 kBtu/hr`, `10 kBtu/hr`, `15 kBtu/hr`, `20 kBtu/hr`, `25 kBtu/hr`, `30 kBtu/hr`, `35 kBtu/hr`, `40 kBtu/hr`, `45 kBtu/hr`, `50 kBtu/hr`, `55 kBtu/hr`, `60 kBtu/hr`, `65 kBtu/hr`, `70 kBtu/hr`, `75 kBtu/hr`, `80 kBtu/hr`, `85 kBtu/hr`, `90 kBtu/hr`, `95 kBtu/hr`, `100 kBtu/hr`, `105 kBtu/hr`, `110 kBtu/hr`, `115 kBtu/hr`, `120 kBtu/hr`, `125 kBtu/hr`, `130 kBtu/hr`, `135 kBtu/hr`, `140 kBtu/hr`, `145 kBtu/hr`, `150 kBtu/hr`, `Detailed Example: Autosize, 140% Multiplier`, `Detailed Example: Autosize, 170% Multiplier`, `Detailed Example: Autosize, 90% Multiplier, 45 kBtu/hr Limit`


- **Default:** `Autosize`

<br/>

**HVAC: Geothermal Loop**

The geothermal loop configuration if there's a ground-to-air heat pump.

- **Name:** ``hvac_geothermal_loop``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Default`, `Vertical Loop, Enhanced Grout`, `Vertical Loop, Enhanced Pipe`, `Vertical Loop, Enhanced Grout & Pipe`, `Detailed Example: Lopsided U Configuration, 10 Boreholes`


- **Default:** `Default`

<br/>

**HVAC: Heating System 2**

The type and efficiency of the second heating system. If a heat pump is specified and the backup type is 'separate', this heating system represents the 'separate' backup heating.

- **Name:** ``hvac_heating_system_2``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Electric Resistance`, `Central Furnace, 60% AFUE`, `Central Furnace, 64% AFUE`, `Central Furnace, 68% AFUE`, `Central Furnace, 72% AFUE`, `Central Furnace, 76% AFUE`, `Central Furnace, 78% AFUE`, `Central Furnace, 80% AFUE`, `Central Furnace, 85% AFUE`, `Central Furnace, 90% AFUE`, `Central Furnace, 92% AFUE`, `Central Furnace, 92.5% AFUE`, `Central Furnace, 96% AFUE`, `Central Furnace, 98% AFUE`, `Central Furnace, 100% AFUE`, `Wall Furnace, 60% AFUE`, `Wall Furnace, 68% AFUE`, `Wall Furnace, 82% AFUE`, `Wall Furnace, 98% AFUE`, `Wall Furnace, 100% AFUE`, `Floor Furnace, 60% AFUE`, `Floor Furnace, 70% AFUE`, `Floor Furnace, 80% AFUE`, `Boiler, 60% AFUE`, `Boiler, 72% AFUE`, `Boiler, 76% AFUE`, `Boiler, 78% AFUE`, `Boiler, 80% AFUE`, `Boiler, 82% AFUE`, `Boiler, 85% AFUE`, `Boiler, 90% AFUE`, `Boiler, 92% AFUE`, `Boiler, 92.5% AFUE`, `Boiler, 95% AFUE`, `Boiler, 96% AFUE`, `Boiler, 98% AFUE`, `Boiler, 100% AFUE`, `Stove, 60% Efficiency`, `Stove, 70% Efficiency`, `Stove, 80% Efficiency`, `Space Heater, 60% Efficiency`, `Space Heater, 70% Efficiency`, `Space Heater, 80% Efficiency`, `Space Heater, 92% Efficiency`, `Space Heater, 100% Efficiency`, `Fireplace, 60% Efficiency`, `Fireplace, 70% Efficiency`, `Fireplace, 80% Efficiency`, `Fireplace, 100% Efficiency`, `Detailed Example: Central Furnace, 92% AFUE, 600 Btu/hr Pilot Light`, `Detailed Example: Floor Furnace, 80% AFUE, 600 Btu/hr Pilot Light`, `Detailed Example: Boiler, 92% AFUE, 600 Btu/hr Pilot Light`


- **Default:** `None`

<br/>

**HVAC: Heating System 2 Fuel Type**

The fuel type of the second heating system. Ignored for ElectricResistance.

- **Name:** ``hvac_heating_system_2_fuel``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Electricity`, `Natural Gas`, `Fuel Oil`, `Propane`, `Wood Cord`, `Wood Pellets`, `Coal`


- **Default:** `Electricity`

<br/>

**HVAC: Heating System 2 Capacity**

The output capacity of the second heating system.

- **Name:** ``hvac_heating_system_2_capacity``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Autosize`, `5 kBtu/hr`, `10 kBtu/hr`, `15 kBtu/hr`, `20 kBtu/hr`, `25 kBtu/hr`, `30 kBtu/hr`, `35 kBtu/hr`, `40 kBtu/hr`, `45 kBtu/hr`, `50 kBtu/hr`, `55 kBtu/hr`, `60 kBtu/hr`, `65 kBtu/hr`, `70 kBtu/hr`, `75 kBtu/hr`, `80 kBtu/hr`, `85 kBtu/hr`, `90 kBtu/hr`, `95 kBtu/hr`, `100 kBtu/hr`, `105 kBtu/hr`, `110 kBtu/hr`, `115 kBtu/hr`, `120 kBtu/hr`, `125 kBtu/hr`, `130 kBtu/hr`, `135 kBtu/hr`, `140 kBtu/hr`, `145 kBtu/hr`, `150 kBtu/hr`, `Detailed Example: Autosize, 140% Multiplier`, `Detailed Example: Autosize, 170% Multiplier`, `Detailed Example: Autosize, 90% Multiplier, 45 kBtu/hr Limit`, `Detailed Example: Autosize, 140% Multiplier, 45 kBtu/hr Limit`


- **Default:** `Autosize`

<br/>

**HVAC: Heating System 2 Fraction Heat Load Served**

The fraction of the heating load served by the second heating system.

- **Name:** ``hvac_heating_system_2_heating_load_served``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `100%`, `95%`, `90%`, `85%`, `80%`, `75%`, `70%`, `65%`, `60%`, `55%`, `50%`, `45%`, `40%`, `35%`, `30%`, `25%`, `20%`, `15%`, `10%`, `5%`, `0%`


- **Default:** `25%`

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

Enter a date range like 'Nov 1 - Jun 30'. Defaults to year-round heating availability.

- **Name:** ``hvac_control_heating_season_period``
- **Type:** ``String``

- **Required:** ``false``


- **Default:** `Jan 1 - Dec 31`

<br/>

**HVAC Control: Cooling Season Period**

Enter a date range like 'Jun 1 - Oct 31'. Defaults to year-round cooling availability.

- **Name:** ``hvac_control_cooling_season_period``
- **Type:** ``String``

- **Required:** ``false``


- **Default:** `Jan 1 - Dec 31`

<br/>

**HVAC Ducts**

The leakage to outside and insulation level of the ducts.

- **Name:** ``hvac_ducts``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `None`, `0% Leakage, Uninsulated`, `0% Leakage, R-4`, `0% Leakage, R-6`, `0% Leakage, R-8`, `5% Leakage, Uninsulated`, `5% Leakage, R-4`, `5% Leakage, R-6`, `5% Leakage, R-8`, `10% Leakage, Uninsulated`, `10% Leakage, R-4`, `10% Leakage, R-6`, `10% Leakage, R-8`, `15% Leakage, Uninsulated`, `15% Leakage, R-4`, `15% Leakage, R-6`, `15% Leakage, R-8`, `20% Leakage, Uninsulated`, `20% Leakage, R-4`, `20% Leakage, R-6`, `20% Leakage, R-8`, `25% Leakage, Uninsulated`, `25% Leakage, R-4`, `25% Leakage, R-6`, `25% Leakage, R-8`, `30% Leakage, Uninsulated`, `30% Leakage, R-4`, `30% Leakage, R-6`, `30% Leakage, R-8`, `35% Leakage, Uninsulated`, `35% Leakage, R-4`, `35% Leakage, R-6`, `35% Leakage, R-8`, `0 CFM25 per 100ft2, Uninsulated`, `0 CFM25 per 100ft2, R-4`, `0 CFM25 per 100ft2, R-6`, `0 CFM25 per 100ft2, R-8`, `1 CFM25 per 100ft2, Uninsulated`, `1 CFM25 per 100ft2, R-4`, `1 CFM25 per 100ft2, R-6`, `1 CFM25 per 100ft2, R-8`, `2 CFM25 per 100ft2, Uninsulated`, `2 CFM25 per 100ft2, R-4`, `2 CFM25 per 100ft2, R-6`, `2 CFM25 per 100ft2, R-8`, `4 CFM25 per 100ft2, Uninsulated`, `4 CFM25 per 100ft2, R-4`, `4 CFM25 per 100ft2, R-6`, `4 CFM25 per 100ft2, R-8`, `6 CFM25 per 100ft2, Uninsulated`, `6 CFM25 per 100ft2, R-4`, `6 CFM25 per 100ft2, R-6`, `6 CFM25 per 100ft2, R-8`, `8 CFM25 per 100ft2, Uninsulated`, `8 CFM25 per 100ft2, R-4`, `8 CFM25 per 100ft2, R-6`, `8 CFM25 per 100ft2, R-8`, `12 CFM25 per 100ft2, Uninsulated`, `12 CFM25 per 100ft2, R-4`, `12 CFM25 per 100ft2, R-6`, `12 CFM25 per 100ft2, R-8`, `Detailed Example: 4 CFM25 per 100ft2 (75% Supply), R-4`, `Detailed Example: 5 CFM50 per 100ft2 (75% Supply), R-4`, `Detailed Example: 250 CFM25, R-6`, `Detailed Example: 400 CFM50 (75% Supply), R-6`


- **Default:** `15% Leakage, Uninsulated`

<br/>

**HVAC Ducts: Supply Location**

The primary location of the supply ducts. The remainder of the supply ducts are assumed to be in conditioned space. Defaults based on the foundation/attic/garage type.

- **Name:** ``hvac_ducts_supply_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Default`, `Conditioned Space`, `Basement`, `Crawlspace`, `Attic`, `Garage`, `Outside`, `Exterior Wall`, `Under Slab`, `Roof Deck`, `Manufactured Home Belly`, `Detailed Example: Attic, 75%`


- **Default:** `Default`

<br/>

**HVAC Ducts: Return Location**

The primary location of the return ducts. The remainder of the return ducts are assumed to be in conditioned space. Defaults based on the foundation/attic/garage type.

- **Name:** ``hvac_ducts_return_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Default`, `Conditioned Space`, `Basement`, `Crawlspace`, `Attic`, `Garage`, `Outside`, `Exterior Wall`, `Under Slab`, `Roof Deck`, `Manufactured Home Belly`, `Detailed Example: Attic, 75%`


- **Default:** `Default`

<br/>

**Ventilation Fans: Mechanical Ventilation**

The type of mechanical ventilation system used for whole building ventilation.

- **Name:** ``ventilation_mechanical``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Exhaust Only`, `Supply Only`, `Balanced`, `CFIS`, `HRV, 55%`, `HRV, 60%`, `HRV, 65%`, `HRV, 70%`, `HRV, 75%`, `HRV, 80%`, `HRV, 85%`, `ERV, 55%`, `ERV, 60%`, `ERV, 65%`, `ERV, 70%`, `ERV, 75%`, `ERV, 80%`, `ERV, 85%`


- **Default:** `None`

<br/>

**Ventilation Fans: Kitchen Exhaust Fan**

The type of kitchen exhaust fan used for local ventilation.

- **Name:** ``ventilation_kitchen``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Default`, `100 cfm, 1 hr/day`, `100 cfm, 2 hrs/day`, `200 cfm, 1 hr/day`, `200 cfm, 2 hrs/day`, `300 cfm, 1 hr/day`, `300 cfm, 2 hrs/day`, `Detailed Example: 100 cfm, 1.5 hrs/day @ 6pm, 30 W`


- **Default:** `None`

<br/>

**Ventilation Fans: Bathroom Exhaust Fans**

The type of bathroom exhaust fans used for local ventilation.

- **Name:** ``ventilation_bathroom``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Default`, `50 cfm/bathroom, 1 hr/day`, `50 cfm/bathroom, 2 hrs/day`, `80 cfm/bathroom, 1 hr/day`, `80 cfm/bathroom, 2 hrs/day`, `100 cfm/bathroom, 1 hr/day`, `100 cfm/bathroom, 2 hrs/day`, `Detailed Example: 50 cfm/bathroom, 1.5 hrs/day @ 7am, 15 W`


- **Default:** `None`

<br/>

**Ventilation Fans: Whole House Fan**

The type of whole house fans used for seasonal cooling load reduction.

- **Name:** ``ventilation_whole_house_fan``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `1000 cfm`, `1500 cfm`, `2000 cfm`, `2500 cfm`, `3000 cfm`, `3500 cfm`, `4000 cfm`, `4500 cfm`, `5000 cfm`, `5500 cfm`, `6000 cfm`, `Detailed Example: 4500 cfm, 300 W`


- **Default:** `None`

<br/>

**DHW: Water Heater**

The type and efficiency of the water heater.

- **Name:** ``dhw_water_heater``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `None`, `Electricity, Tank, UEF 0.90`, `Electricity, Tank, UEF 0.92`, `Electricity, Tank, UEF 0.94`, `Electricity, Tankless, UEF 0.94`, `Electricity, Tankless, UEF 0.98`, `Electricity, Heat Pump, UEF 3.50`, `Electricity, Heat Pump, UEF 3.75`, `Electricity, Heat Pump, UEF 4.00`, `Natural Gas, Tank, UEF 0.57`, `Natural Gas, Tank, UEF 0.60`, `Natural Gas, Tank, UEF 0.64`, `Natural Gas, Tank, UEF 0.67`, `Natural Gas, Tank, UEF 0.70`, `Natural Gas, Tank, UEF 0.80`, `Natural Gas, Tankless, UEF 0.82`, `Natural Gas, Tankless, UEF 0.93`, `Natural Gas, Tankless, UEF 0.96`, `Fuel Oil, Tank, UEF 0.61`, `Fuel Oil, Tank, UEF 0.64`, `Fuel Oil, Tank, UEF 0.67`, `Propane, Tank, UEF 0.57`, `Propane, Tank, UEF 0.60`, `Propane, Tank, UEF 0.64`, `Propane, Tank, UEF 0.67`, `Propane, Tank, UEF 0.70`, `Propane, Tank, UEF 0.80`, `Propane, Tankless, UEF 0.82`, `Propane, Tankless, UEF 0.93`, `Propane, Tankless, UEF 0.96`, `Wood, Tank, UEF 0.60`, `Coal, Tank, UEF 0.60`, `Space-Heating Boiler w/ Storage Tank`, `Space-Heating Boiler w/ Tankless Coil`, `Detailed Example: Electricity, Tank, 40 gal, EF 0.93`, `Detailed Example: Electricity, Tank, UEF 0.94, 135F`, `Detailed Example: Electricity, Tankless, EF 0.96`, `Detailed Example: Electricity, Heat Pump, 80 gal, EF 3.1`, `Detailed Example: Natural Gas, Tank, 40 gal, EF 0.56, RE 0.78`, `Detailed Example: Natural Gas, Tank, 40 gal, EF 0.62, RE 0.78`, `Detailed Example: Natural Gas, Tank, 50 gal, EF 0.59, RE 0.76`, `Detailed Example: Natural Gas, Tankless, EF 0.95`


- **Default:** `Electricity, Tank, UEF 0.92`

<br/>

**DHW: Water Heater Location**

The location of the water heater. Defaults based on the foundation/garage type.

- **Name:** ``dhw_water_heater_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Default`, `Conditioned Space`, `Basement`, `Garage`, `Crawlspace`, `Attic`, `Other Heated Space`, `Outside`


- **Default:** `Default`

<br/>

**DHW: Hot Water Distribution**

The type of domestic hot water distrubtion.

- **Name:** ``dhw_distribution``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Uninsulated, Standard`, `Uninsulated, Recirc, Uncontrolled`, `Uninsulated, Recirc, Timer Control`, `Uninsulated, Recirc, Temperature Control`, `Uninsulated, Recirc, Presence Sensor Demand Control`, `Uninsulated, Recirc, Manual Demand Control`, `Insulated, Standard`, `Insulated, Recirc, Uncontrolled`, `Insulated, Recirc, Timer Control`, `Insulated, Recirc, Temperature Control`, `Insulated, Recirc, Presence Sensor Demand Control`, `Insulated, Recirc, Manual Demand Control`, `Detailed Example: Insulated, Recirc, Uncontrolled, 156.9ft Loop, 10ft Branch, 50 W`, `Detailed Example: Insulated, Recirc, Manual Demand Control, 156.9ft Loop, 10ft Branch, 50 W`


- **Default:** `Uninsulated, Standard`

<br/>

**DHW: Hot Water Fixtures**

The type and usage of domestic hot water fixtures.

- **Name:** ``dhw_fixtures``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Standard, 25% Usage`, `Standard, 50% Usage`, `Standard, 75% Usage`, `Standard, 100% Usage`, `Standard, 125% Usage`, `Standard, 150% Usage`, `Standard, 175% Usage`, `Standard, 200% Usage`, `Standard, 400% Usage`, `Low Flow, 25% Usage`, `Low Flow, 50% Usage`, `Low Flow, 75% Usage`, `Low Flow, 100% Usage`, `Low Flow, 125% Usage`, `Low Flow, 150% Usage`, `Low Flow, 175% Usage`, `Low Flow, 200% Usage`, `Low Flow, 400% Usage`


- **Default:** `Standard, 100% Usage`

<br/>

**DHW: Drain Water Heat Reovery**

The type of drain water heater recovery.

- **Name:** ``dhw_drain_water_heat_recovery``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `25% Efficient, Preheats Hot Only, All Showers`, `25% Efficient, Preheats Hot Only, 1 Shower`, `25% Efficient, Preheats Hot and Cold, All Showers`, `25% Efficient, Preheats Hot and Cold, 1 Shower`, `35% Efficient, Preheats Hot Only, All Showers`, `35% Efficient, Preheats Hot Only, 1 Shower`, `35% Efficient, Preheats Hot and Cold, All Showers`, `35% Efficient, Preheats Hot and Cold, 1 Shower`, `45% Efficient, Preheats Hot Only, All Showers`, `45% Efficient, Preheats Hot Only, 1 Shower`, `45% Efficient, Preheats Hot and Cold, All Showers`, `45% Efficient, Preheats Hot and Cold, 1 Shower`, `55% Efficient, Preheats Hot Only, All Showers`, `55% Efficient, Preheats Hot Only, 1 Shower`, `55% Efficient, Preheats Hot and Cold, All Showers`, `55% Efficient, Preheats Hot and Cold, 1 Shower`, `Detailed Example: 54% Efficient, Preheats Hot and Cold, All Showers`


- **Default:** `None`

<br/>

**DHW: Solar Thermal**

The size and type of the solar thermal system for domestic hot water.

- **Name:** ``dhw_solar_thermal``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Indirect, Flat Plate, 40 sqft`, `Indirect, Flat Plate, 64 sqft`, `Direct, Flat Plate, 40 sqft`, `Direct. Flat Plate, 64 sqft`, `Direct, Integrated Collector Storage, 40 sqft`, `Direct, Integrated Collector Storage, 64 sqft`, `Direct, Evacuated Tube, 40 sqft`, `Direct, Evacuated Tube, 64 sqft`, `Thermosyphon, Flat Plate, 40 sqft`, `Thermosyphon, Flat Plate, 64 sqft`, `60% Solar Fraction`, `65% Solar Fraction`, `70% Solar Fraction`, `75% Solar Fraction`, `80% Solar Fraction`, `85% Solar Fraction`, `90% Solar Fraction`, `95% Solar Fraction`


- **Default:** `None`

<br/>

**DHW: Solar Thermal Direction**

The azimuth and tilt of the solar thermal system collectors.

- **Name:** ``dhw_solar_thermal_direction``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Roof Pitch, West`, `Roof Pitch, Southwest`, `Roof Pitch, South`, `Roof Pitch, Southeast`, `Roof Pitch, East`, `Roof Pitch, Northeast`, `Roof Pitch, North`, `Roof Pitch, Northwest`, `0 Degrees`, `5 Degrees, West`, `5 Degrees, Southwest`, `5 Degrees, South`, `5 Degrees, Southeast`, `5 Degrees, East`, `10 Degrees, West`, `10 Degrees, Southwest`, `10 Degrees, South`, `10 Degrees, Southeast`, `10 Degrees, East`, `15 Degrees, West`, `15 Degrees, Southwest`, `15 Degrees, South`, `15 Degrees, Southeast`, `15 Degrees, East`, `20 Degrees, West`, `20 Degrees, Southwest`, `20 Degrees, South`, `20 Degrees, Southeast`, `20 Degrees, East`, `25 Degrees, West`, `25 Degrees, Southwest`, `25 Degrees, South`, `25 Degrees, Southeast`, `25 Degrees, East`, `30 Degrees, West`, `30 Degrees, Southwest`, `30 Degrees, South`, `30 Degrees, Southeast`, `30 Degrees, East`, `35 Degrees, West`, `35 Degrees, Southwest`, `35 Degrees, South`, `35 Degrees, Southeast`, `35 Degrees, East`, `40 Degrees, West`, `40 Degrees, Southwest`, `40 Degrees, South`, `40 Degrees, Southeast`, `40 Degrees, East`, `45 Degrees, West`, `45 Degrees, Southwest`, `45 Degrees, South`, `45 Degrees, Southeast`, `45 Degrees, East`, `50 Degrees, West`, `50 Degrees, Southwest`, `50 Degrees, South`, `50 Degrees, Southeast`, `50 Degrees, East`


- **Default:** `Roof Pitch, South`

<br/>

**PV: System**

The size and type of the PV system.

- **Name:** ``pv_system``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `0.5 kW`, `1.0 kW`, `1.5 kW`, `2.0 kW`, `2.5 kW`, `3.0 kW`, `3.5 kW`, `4.0 kW`, `4.5 kW`, `5.0 kW`, `5.5 kW`, `6.0 kW`, `6.5 kW`, `7.0 kW`, `7.5 kW`, `8.0 kW`, `8.5 kW`, `9.0 kW`, `9.5 kW`, `10.0 kW`, `10.5 kW`, `11.0 kW`, `11.5 kW`, `12.0 kW`, `12.5 kW`, `13.0 kW`, `13.5 kW`, `14.0 kW`, `14.5 kW`, `15.0 kW`, `Detailed Example: 10.0 kW, Standard, 14% System Losses, 96% Inverter Efficiency`, `Detailed Example: 1.5 kW, Premium`, `Detailed Example: 1.5 kW, Thin Film`


- **Default:** `None`

<br/>

**PV: System Direction**

The azimuth and tilt of the PV system array.

- **Name:** ``pv_system_direction``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Roof Pitch, West`, `Roof Pitch, Southwest`, `Roof Pitch, South`, `Roof Pitch, Southeast`, `Roof Pitch, East`, `Roof Pitch, Northeast`, `Roof Pitch, North`, `Roof Pitch, Northwest`, `0 Degrees`, `5 Degrees, West`, `5 Degrees, Southwest`, `5 Degrees, South`, `5 Degrees, Southeast`, `5 Degrees, East`, `10 Degrees, West`, `10 Degrees, Southwest`, `10 Degrees, South`, `10 Degrees, Southeast`, `10 Degrees, East`, `15 Degrees, West`, `15 Degrees, Southwest`, `15 Degrees, South`, `15 Degrees, Southeast`, `15 Degrees, East`, `20 Degrees, West`, `20 Degrees, Southwest`, `20 Degrees, South`, `20 Degrees, Southeast`, `20 Degrees, East`, `25 Degrees, West`, `25 Degrees, Southwest`, `25 Degrees, South`, `25 Degrees, Southeast`, `25 Degrees, East`, `30 Degrees, West`, `30 Degrees, Southwest`, `30 Degrees, South`, `30 Degrees, Southeast`, `30 Degrees, East`, `35 Degrees, West`, `35 Degrees, Southwest`, `35 Degrees, South`, `35 Degrees, Southeast`, `35 Degrees, East`, `40 Degrees, West`, `40 Degrees, Southwest`, `40 Degrees, South`, `40 Degrees, Southeast`, `40 Degrees, East`, `45 Degrees, West`, `45 Degrees, Southwest`, `45 Degrees, South`, `45 Degrees, Southeast`, `45 Degrees, East`, `50 Degrees, West`, `50 Degrees, Southwest`, `50 Degrees, South`, `50 Degrees, Southeast`, `50 Degrees, East`


- **Default:** `Roof Pitch, South`

<br/>

**PV: System 2**

The size and type of the second PV system.

- **Name:** ``pv_system_2``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `0.5 kW`, `1.0 kW`, `1.5 kW`, `2.0 kW`, `2.5 kW`, `3.0 kW`, `3.5 kW`, `4.0 kW`, `4.5 kW`, `5.0 kW`, `5.5 kW`, `6.0 kW`, `6.5 kW`, `7.0 kW`, `7.5 kW`, `8.0 kW`, `8.5 kW`, `9.0 kW`, `9.5 kW`, `10.0 kW`, `10.5 kW`, `11.0 kW`, `11.5 kW`, `12.0 kW`, `12.5 kW`, `13.0 kW`, `13.5 kW`, `14.0 kW`, `14.5 kW`, `15.0 kW`, `Detailed Example: 10.0 kW, Standard, 14% System Losses`, `Detailed Example: 1.5 kW, Premium`, `Detailed Example: 1.5 kW, Thin Film`


- **Default:** `None`

<br/>

**PV: System 2 Direction**

The azimuth and tilt of the second PV system array.

- **Name:** ``pv_system_2_direction``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Roof Pitch, West`, `Roof Pitch, Southwest`, `Roof Pitch, South`, `Roof Pitch, Southeast`, `Roof Pitch, East`, `Roof Pitch, Northeast`, `Roof Pitch, North`, `Roof Pitch, Northwest`, `0 Degrees`, `5 Degrees, West`, `5 Degrees, Southwest`, `5 Degrees, South`, `5 Degrees, Southeast`, `5 Degrees, East`, `10 Degrees, West`, `10 Degrees, Southwest`, `10 Degrees, South`, `10 Degrees, Southeast`, `10 Degrees, East`, `15 Degrees, West`, `15 Degrees, Southwest`, `15 Degrees, South`, `15 Degrees, Southeast`, `15 Degrees, East`, `20 Degrees, West`, `20 Degrees, Southwest`, `20 Degrees, South`, `20 Degrees, Southeast`, `20 Degrees, East`, `25 Degrees, West`, `25 Degrees, Southwest`, `25 Degrees, South`, `25 Degrees, Southeast`, `25 Degrees, East`, `30 Degrees, West`, `30 Degrees, Southwest`, `30 Degrees, South`, `30 Degrees, Southeast`, `30 Degrees, East`, `35 Degrees, West`, `35 Degrees, Southwest`, `35 Degrees, South`, `35 Degrees, Southeast`, `35 Degrees, East`, `40 Degrees, West`, `40 Degrees, Southwest`, `40 Degrees, South`, `40 Degrees, Southeast`, `40 Degrees, East`, `45 Degrees, West`, `45 Degrees, Southwest`, `45 Degrees, South`, `45 Degrees, Southeast`, `45 Degrees, East`, `50 Degrees, West`, `50 Degrees, Southwest`, `50 Degrees, South`, `50 Degrees, Southeast`, `50 Degrees, East`


- **Default:** `Roof Pitch, South`

<br/>

**Battery**

The size and type of battery storage.

- **Name:** ``battery``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `5.0 kWh`, `7.5 kWh`, `10.0 kWh`, `12.5 kWh`, `15.0 kWh`, `17.5 kWh`, `20.0 kWh`, `Detailed Example: 20.0 kWh, 6 kW, Garage`, `Detailed Example: 20.0 kWh, 6 kW, Outside`, `Detailed Example: 20.0 kWh, 6 kW, Outside, 80% Efficiency`


- **Default:** `None`

<br/>

**Electric Vehicle**

The type of battery electric vehicle.

- **Name:** ``electric_vehicle``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Compact, 200 Mile Range, 10% Usage`, `Compact, 200 Mile Range, 25% Usage`, `Compact, 200 Mile Range, 50% Usage`, `Compact, 200 Mile Range, 75% Usage`, `Compact, 200 Mile Range, 100% Usage`, `Compact, 200 Mile Range, 125% Usage`, `Compact, 200 Mile Range, 150% Usage`, `Compact, 200 Mile Range, 175% Usage`, `Compact, 200 Mile Range, 200% Usage`, `Compact, 300 Mile Range, 10% Usage`, `Compact, 300 Mile Range, 25% Usage`, `Compact, 300 Mile Range, 50% Usage`, `Compact, 300 Mile Range, 75% Usage`, `Compact, 300 Mile Range, 100% Usage`, `Compact, 300 Mile Range, 125% Usage`, `Compact, 300 Mile Range, 150% Usage`, `Compact, 300 Mile Range, 175% Usage`, `Compact, 300 Mile Range, 200% Usage`, `Midsize, 200 Mile Range, 10% Usage`, `Midsize, 200 Mile Range, 25% Usage`, `Midsize, 200 Mile Range, 50% Usage`, `Midsize, 200 Mile Range, 75% Usage`, `Midsize, 200 Mile Range, 100% Usage`, `Midsize, 200 Mile Range, 125% Usage`, `Midsize, 200 Mile Range, 150% Usage`, `Midsize, 200 Mile Range, 175% Usage`, `Midsize, 200 Mile Range, 200% Usage`, `Midsize, 300 Mile Range, 10% Usage`, `Midsize, 300 Mile Range, 25% Usage`, `Midsize, 300 Mile Range, 50% Usage`, `Midsize, 300 Mile Range, 75% Usage`, `Midsize, 300 Mile Range, 100% Usage`, `Midsize, 300 Mile Range, 125% Usage`, `Midsize, 300 Mile Range, 150% Usage`, `Midsize, 300 Mile Range, 175% Usage`, `Midsize, 300 Mile Range, 200% Usage`, `Pickup, 200 Mile Range, 10% Usage`, `Pickup, 200 Mile Range, 25% Usage`, `Pickup, 200 Mile Range, 50% Usage`, `Pickup, 200 Mile Range, 75% Usage`, `Pickup, 200 Mile Range, 100% Usage`, `Pickup, 200 Mile Range, 125% Usage`, `Pickup, 200 Mile Range, 150% Usage`, `Pickup, 200 Mile Range, 175% Usage`, `Pickup, 200 Mile Range, 200% Usage`, `Pickup, 300 Mile Range, 10% Usage`, `Pickup, 300 Mile Range, 25% Usage`, `Pickup, 300 Mile Range, 50% Usage`, `Pickup, 300 Mile Range, 75% Usage`, `Pickup, 300 Mile Range, 100% Usage`, `Pickup, 300 Mile Range, 125% Usage`, `Pickup, 300 Mile Range, 150% Usage`, `Pickup, 300 Mile Range, 175% Usage`, `Pickup, 300 Mile Range, 200% Usage`, `SUV, 200 Mile Range, 10% Usage`, `SUV, 200 Mile Range, 25% Usage`, `SUV, 200 Mile Range, 50% Usage`, `SUV, 200 Mile Range, 75% Usage`, `SUV, 200 Mile Range, 100% Usage`, `SUV, 200 Mile Range, 125% Usage`, `SUV, 200 Mile Range, 150% Usage`, `SUV, 200 Mile Range, 175% Usage`, `SUV, 200 Mile Range, 200% Usage`, `SUV, 300 Mile Range, 10% Usage`, `SUV, 300 Mile Range, 25% Usage`, `SUV, 300 Mile Range, 50% Usage`, `SUV, 300 Mile Range, 75% Usage`, `SUV, 300 Mile Range, 100% Usage`, `SUV, 300 Mile Range, 125% Usage`, `SUV, 300 Mile Range, 150% Usage`, `SUV, 300 Mile Range, 175% Usage`, `SUV, 300 Mile Range, 200% Usage`, `Detailed Example: 100 kWh battery, 0.25 kWh/mile`, `Detailed Example: 100 kWh battery, 4.0 miles/kWh`, `Detailed Example: 100 kWh battery, 135.0 mpge`


- **Default:** `None`

<br/>

**Electric Vehicle: Charger**

The type and usage of electric vehicle charger.

- **Name:** ``electric_vehicle_charger``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Level 1, 10% Charging at Home`, `Level 1, 30% Charging at Home`, `Level 1, 50% Charging at Home`, `Level 1, 70% Charging at Home`, `Level 1, 90% Charging at Home`, `Level 1, 100% Charging at Home`, `Level 2, 10% Charging at Home`, `Level 2, 30% Charging at Home`, `Level 2, 50% Charging at Home`, `Level 2, 70% Charging at Home`, `Level 2, 90% Charging at Home`, `Level 2, 100% Charging at Home`, `Detailed Example: Level 2, 7000 W, 75% Charging at Home`


- **Default:** `None`

<br/>

**Appliances: Clothes Washer**

The type and usage of clothes washer.

- **Name:** ``appliance_clothes_washer``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Standard, 2008-2017, 50% Usage`, `Standard, 2008-2017, 75% Usage`, `Standard, 2008-2017, 100% Usage`, `Standard, 2008-2017, 150% Usage`, `Standard, 2008-2017, 200% Usage`, `Standard, 2018-present, 50% Usage`, `Standard, 2018-present, 75% Usage`, `Standard, 2018-present, 100% Usage`, `Standard, 2018-present, 150% Usage`, `Standard, 2018-present, 200% Usage`, `EnergyStar, 2006-2017, 50% Usage`, `EnergyStar, 2006-2017, 75% Usage`, `EnergyStar, 2006-2017, 100% Usage`, `EnergyStar, 2006-2017, 150% Usage`, `EnergyStar, 2006-2017, 200% Usage`, `EnergyStar, 2018-present, 50% Usage`, `EnergyStar, 2018-present, 75% Usage`, `EnergyStar, 2018-present, 100% Usage`, `EnergyStar, 2018-present, 150% Usage`, `EnergyStar, 2018-present, 200% Usage`, `CEE Tier II, 2018, 50% Usage`, `CEE Tier II, 2018, 75% Usage`, `CEE Tier II, 2018, 100% Usage`, `CEE Tier II, 2018, 150% Usage`, `CEE Tier II, 2018, 200% Usage`, `Detailed Example: ERI Reference 2006`, `Detailed Example: MEF 1.65`, `Detailed Example: Standard, 2008-2017, Conditioned Basement`, `Detailed Example: Standard, 2008-2017, Unconditioned Basement`, `Detailed Example: Standard, 2008-2017, Garage`


- **Default:** `Standard, 2008-2017, 100% Usage`

<br/>

**Appliances: Clothes Dryer**

The type and usage of clothes dryer.

- **Name:** ``appliance_clothes_dryer``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Electricity, Standard, 50% Usage`, `Electricity, Standard, 75% Usage`, `Electricity, Standard, 100% Usage`, `Electricity, Standard, 150% Usage`, `Electricity, Standard, 200% Usage`, `Electricity, Premium, 50% Usage`, `Electricity, Premium, 75% Usage`, `Electricity, Premium, 100% Usage`, `Electricity, Premium, 150% Usage`, `Electricity, Premium, 200% Usage`, `Electricity, Heat Pump, 50% Usage`, `Electricity, Heat Pump, 75% Usage`, `Electricity, Heat Pump, 100% Usage`, `Electricity, Heat Pump, 150% Usage`, `Electricity, Heat Pump, 200% Usage`, `Natural Gas, Standard, 50% Usage`, `Natural Gas, Standard, 75% Usage`, `Natural Gas, Standard, 100% Usage`, `Natural Gas, Standard, 150% Usage`, `Natural Gas, Standard, 200% Usage`, `Natural Gas, Premium, 50% Usage`, `Natural Gas, Premium, 75% Usage`, `Natural Gas, Premium, 100% Usage`, `Natural Gas, Premium, 150% Usage`, `Natural Gas, Premium, 200% Usage`, `Propane, Standard, 50% Usage`, `Propane, Standard, 75% Usage`, `Propane, Standard, 100% Usage`, `Propane, Standard, 150% Usage`, `Propane, Standard, 200% Usage`, `Detailed Example: Electricity, ERI Reference 2006`, `Detailed Example: Natural Gas, ERI Reference 2006`, `Detailed Example: Electricity, EF 4.29`, `Detailed Example: Electricity, Standard, Conditioned Basement`, `Detailed Example: Electricity, Standard, Unconditioned Basement`, `Detailed Example: Electricity, Standard, Garage`


- **Default:** `Electricity, Standard, 100% Usage`

<br/>

**Appliances: Dishwasher**

The type and usage of dishwasher.

- **Name:** ``appliance_dishwasher``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Federal Minimum, Standard, 50% Usage`, `Federal Minimum, Standard, 75% Usage`, `Federal Minimum, Standard, 100% Usage`, `Federal Minimum, Standard, 150% Usage`, `Federal Minimum, Standard, 200% Usage`, `EnergyStar, Standard, 50% Usage`, `EnergyStar, Standard, 75% Usage`, `EnergyStar, Standard, 100% Usage`, `EnergyStar, Standard, 150% Usage`, `EnergyStar, Standard, 200% Usage`, `EnergyStar, Compact, 50% Usage`, `EnergyStar, Compact, 75% Usage`, `EnergyStar, Compact, 100% Usage`, `EnergyStar, Compact, 150% Usage`, `EnergyStar, Compact, 200% Usage`, `Detailed Example: ERI Reference 2006`, `Detailed Example: EF 0.7, Compact`, `Detailed Example: Federal Minimum, Standard, Conditioned Basement`, `Detailed Example: Federal Minimum, Standard, Unconditioned Basement`, `Detailed Example: Federal Minimum, Standard, Garage`


- **Default:** `Federal Minimum, Standard, 100% Usage`

<br/>

**Appliances: Refrigerator**

The type and usage of refrigerator.

- **Name:** ``appliance_refrigerator``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `1139 kWh/yr, 90% Usage`, `1139 kWh/yr, 100% Usage`, `1139 kWh/yr, 110% Usage`, `748 kWh/yr, 90% Usage`, `748 kWh/yr, 100% Usage`, `748 kWh/yr, 110% Usage`, `727 kWh/yr, 90% Usage`, `727 kWh/yr, 100% Usage`, `727 kWh/yr, 110% Usage`, `650 kWh/yr, 90% Usage`, `650 kWh/yr, 100% Usage`, `650 kWh/yr, 110% Usage`, `574 kWh/yr, 90% Usage`, `574 kWh/yr, 100% Usage`, `574 kWh/yr, 110% Usage`, `547 kWh/yr, 90% Usage`, `547 kWh/yr, 100% Usage`, `547 kWh/yr, 110% Usage`, `480 kWh/yr, 90% Usage`, `480 kWh/yr, 100% Usage`, `480 kWh/yr, 110% Usage`, `458 kWh/yr, 90% Usage`, `458 kWh/yr, 100% Usage`, `458 kWh/yr, 110% Usage`, `434 kWh/yr, 90% Usage`, `434 kWh/yr, 100% Usage`, `434 kWh/yr, 110% Usage`, `384 kWh/yr, 90% Usage`, `384 kWh/yr, 100% Usage`, `384 kWh/yr, 110% Usage`, `348 kWh/yr, 90% Usage`, `348 kWh/yr, 100% Usage`, `348 kWh/yr, 110% Usage`, `Detailed Example: ERI Reference 2006, 2-Bedroom Home`, `Detailed Example: ERI Reference 2006, 3-Bedroom Home`, `Detailed Example: ERI Reference 2006, 4-Bedroom Home`, `Detailed Example: 650 kWh/yr, Conditioned Basement`, `Detailed Example: 650 kWh/yr, Unconditioned Basement`, `Detailed Example: 650 kWh/yr, Garage`


- **Default:** `434 kWh/yr, 100% Usage`

<br/>

**Appliances: Extra Refrigerator**

The type and usage of extra refrigerator.

- **Name:** ``appliance_extra_refrigerator``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `1139 kWh/yr, 90% Usage`, `1139 kWh/yr, 100% Usage`, `1139 kWh/yr, 110% Usage`, `748 kWh/yr, 90% Usage`, `748 kWh/yr, 100% Usage`, `748 kWh/yr, 110% Usage`, `727 kWh/yr, 90% Usage`, `727 kWh/yr, 100% Usage`, `727 kWh/yr, 110% Usage`, `650 kWh/yr, 90% Usage`, `650 kWh/yr, 100% Usage`, `650 kWh/yr, 110% Usage`, `574 kWh/yr, 90% Usage`, `574 kWh/yr, 100% Usage`, `574 kWh/yr, 110% Usage`, `547 kWh/yr, 90% Usage`, `547 kWh/yr, 100% Usage`, `547 kWh/yr, 110% Usage`, `480 kWh/yr, 90% Usage`, `480 kWh/yr, 100% Usage`, `480 kWh/yr, 110% Usage`, `458 kWh/yr, 90% Usage`, `458 kWh/yr, 100% Usage`, `458 kWh/yr, 110% Usage`, `434 kWh/yr, 90% Usage`, `434 kWh/yr, 100% Usage`, `434 kWh/yr, 110% Usage`, `384 kWh/yr, 90% Usage`, `384 kWh/yr, 100% Usage`, `384 kWh/yr, 110% Usage`, `348 kWh/yr, 90% Usage`, `348 kWh/yr, 100% Usage`, `348 kWh/yr, 110% Usage`, `Detailed Example: 748 kWh/yr, Conditioned Basement`, `Detailed Example: 748 kWh/yr, Unconditioned Basement`, `Detailed Example: 748 kWh/yr, Garage`


- **Default:** `None`

<br/>

**Appliances: Freezer**

The type and usage of freezer.

- **Name:** ``appliance_freezer``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `935 kWh/yr, 90% Usage`, `935 kWh/yr, 100% Usage`, `935 kWh/yr, 110% Usage`, `712 kWh/yr, 90% Usage`, `712 kWh/yr, 100% Usage`, `712 kWh/yr, 110% Usage`, `641 kWh/yr, 90% Usage`, `641 kWh/yr, 100% Usage`, `641 kWh/yr, 110% Usage`, `568 kWh/yr, 90% Usage`, `568 kWh/yr, 100% Usage`, `568 kWh/yr, 110% Usage`, `417 kWh/yr, 90% Usage`, `417 kWh/yr, 100% Usage`, `417 kWh/yr, 110% Usage`, `375 kWh/yr, 90% Usage`, `375 kWh/yr, 100% Usage`, `375 kWh/yr, 110% Usage`, `354 kWh/yr, 90% Usage`, `354 kWh/yr, 100% Usage`, `354 kWh/yr, 110% Usage`, `Detailed Example: 712 kWh/yr, Conditioned Basement`, `Detailed Example: 712 kWh/yr, Unconditioned Basement`, `Detailed Example: 712 kWh/yr, Garage`


- **Default:** `None`

<br/>

**Appliances: Cooking Range/Oven**

The type and usage of cooking range/oven.

- **Name:** ``appliance_cooking_range_oven``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Electricity, Standard, Non-Convection, 50% Usage`, `Electricity, Standard, Non-Convection, 75% Usage`, `Electricity, Standard, Non-Convection, 100% Usage`, `Electricity, Standard, Non-Convection, 150% Usage`, `Electricity, Standard, Non-Convection, 200% Usage`, `Electricity, Standard, Convection, 50% Usage`, `Electricity, Standard, Convection, 75% Usage`, `Electricity, Standard, Convection, 100% Usage`, `Electricity, Standard, Convection, 150% Usage`, `Electricity, Standard, Convection, 200% Usage`, `Electricity, Induction, Non-Convection, 50% Usage`, `Electricity, Induction, Non-Convection, 75% Usage`, `Electricity, Induction, Non-Convection, 100% Usage`, `Electricity, Induction, Non-Convection, 150% Usage`, `Electricity, Induction, Non-Convection, 200% Usage`, `Electricity, Induction, Convection, 50% Usage`, `Electricity, Induction, Convection, 75% Usage`, `Electricity, Induction, Convection, 100% Usage`, `Electricity, Induction, Convection, 150% Usage`, `Electricity, Induction, Convection, 200% Usage`, `Natural Gas, Non-Convection, 50% Usage`, `Natural Gas, Non-Convection, 75% Usage`, `Natural Gas, Non-Convection, 100% Usage`, `Natural Gas, Non-Convection, 150% Usage`, `Natural Gas, Non-Convection, 200% Usage`, `Natural Gas, Convection, 50% Usage`, `Natural Gas, Convection, 75% Usage`, `Natural Gas, Convection, 100% Usage`, `Natural Gas, Convection, 150% Usage`, `Natural Gas, Convection, 200% Usage`, `Propane, Non-Convection, 50% Usage`, `Propane, Non-Convection, 75% Usage`, `Propane, Non-Convection, 100% Usage`, `Propane, Non-Convection, 150% Usage`, `Propane, Non-Convection, 200% Usage`, `Propane, Convection, 50% Usage`, `Propane, Convection, 75% Usage`, `Propane, Convection, 100% Usage`, `Propane, Convection, 150% Usage`, `Propane, Convection, 200% Usage`, `Detailed Example: Electricity, Standard, Non-Convection, Conditioned Basement`, `Detailed Example: Electricity, Standard, Non-Convection, Unconditioned Basement`, `Detailed Example: Electricity, Standard, Non-Convection, Garage`


- **Default:** `Electricity, Standard, Non-Convection, 100% Usage`

<br/>

**Appliances: Dehumidifier**

The type of dehumidifier.

- **Name:** ``appliance_dehumidifier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Portable, 15 pints/day`, `Portable, 20 pints/day`, `Portable, 30 pints/day`, `Portable, 40 pints/day`, `Whole-Home, 60 pints/day`, `Whole-Home, 75 pints/day`, `Whole-Home, 95 pints/day`, `Whole-Home, 125 pints/day`, `Detailed Example: Portable, 40 pints/day, EF 1.8`


- **Default:** `None`

<br/>

**Appliances: Dehumidifier Setpoint**

The dehumidifier's relative humidity (RH) setpoint.

- **Name:** ``appliance_dehumidifier_setpoint``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `40% RH`, `45% RH`, `50% RH`, `55% RH`, `60% RH`, `65% RH`


- **Default:** `50% RH`

<br/>

**Lighting**

The type and usage of interior, exterior, and garage lighting.

- **Name:** ``lighting``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `100% Incandescent, 50% Usage`, `100% Incandescent, 75% Usage`, `100% Incandescent, 100% Usage`, `100% Incandescent, 150% Usage`, `100% Incandescent, 200% Usage`, `25% LED, 50% Usage`, `25% LED, 75% Usage`, `25% LED, 100% Usage`, `25% LED, 150% Usage`, `25% LED, 200% Usage`, `50% LED, 50% Usage`, `50% LED, 75% Usage`, `50% LED, 100% Usage`, `50% LED, 150% Usage`, `50% LED, 200% Usage`, `75% LED, 50% Usage`, `75% LED, 75% Usage`, `75% LED, 100% Usage`, `75% LED, 150% Usage`, `75% LED, 200% Usage`, `100% LED, 50% Usage`, `100% LED, 75% Usage`, `100% LED, 100% Usage`, `100% LED, 150% Usage`, `100% LED, 200% Usage`, `25% CFL, 50% Usage`, `25% CFL, 75% Usage`, `25% CFL, 100% Usage`, `25% CFL, 150% Usage`, `25% CFL, 200% Usage`, `50% CFL, 50% Usage`, `50% CFL, 75% Usage`, `50% CFL, 100% Usage`, `50% CFL, 150% Usage`, `50% CFL, 200% Usage`, `75% CFL, 50% Usage`, `75% CFL, 75% Usage`, `75% CFL, 100% Usage`, `75% CFL, 150% Usage`, `75% CFL, 200% Usage`, `100% CFL, 50% Usage`, `100% CFL, 75% Usage`, `100% CFL, 100% Usage`, `100% CFL, 150% Usage`, `100% CFL, 200% Usage`, `Detailed Example: 10% CFL`, `Detailed Example: 40% CFL, 10% LFL, 25% LED`


- **Default:** `50% LED, 100% Usage`

<br/>

**Ceiling Fans**

The type of ceiling fans.

- **Name:** ``ceiling_fans``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `#Bedrooms+1 Fans, 45.0 W`, `#Bedrooms+1 Fans, 37.5 W`, `#Bedrooms+1 Fans, 30.0 W`, `#Bedrooms+1 Fans, 22.5 W`, `#Bedrooms+1 Fans, 15.0 W`, `1 Fan, 45.0 W`, `1 Fan, 37.5 W`, `1 Fan, 30.0 W`, `1 Fan, 22.5 W`, `1 Fan, 15.0 W`, `2 Fans, 45.0 W`, `2 Fans, 37.5 W`, `2 Fans, 30.0 W`, `2 Fans, 22.5 W`, `2 Fans, 15.0 W`, `3 Fans, 45.0 W`, `3 Fans, 37.5 W`, `3 Fans, 30.0 W`, `3 Fans, 22.5 W`, `3 Fans, 15.0 W`, `4 Fans, 45.0 W`, `4 Fans, 37.5 W`, `4 Fans, 30.0 W`, `4 Fans, 22.5 W`, `4 Fans, 15.0 W`, `5 Fans, 45.0 W`, `5 Fans, 37.5 W`, `5 Fans, 30.0 W`, `5 Fans, 22.5 W`, `5 Fans, 15.0 W`, `Detailed Example: 4 Fans, 39 W, 0.5 deg-F Setpoint Offset`, `Detailed Example: 4 Fans, 100 cfm/W, 0.5 deg-F Setpoint Offset`


- **Default:** `None`

<br/>

**Misc: Television**

The amount of television usage, relative to the national average.

- **Name:** ``misc_television``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `25% Usage`, `33% Usage`, `50% Usage`, `75% Usage`, `80% Usage`, `90% Usage`, `100% Usage`, `110% Usage`, `125% Usage`, `150% Usage`, `200% Usage`, `300% Usage`, `400% Usage`, `Detailed Example: 620 kWh/yr`


- **Default:** `100% Usage`

<br/>

**Misc: Plug Loads**

The amount of additional plug load usage, relative to the national average.

- **Name:** ``misc_plug_loads``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `25% Usage`, `33% Usage`, `50% Usage`, `75% Usage`, `80% Usage`, `90% Usage`, `100% Usage`, `110% Usage`, `125% Usage`, `150% Usage`, `200% Usage`, `300% Usage`, `400% Usage`, `Detailed Example: 2457 kWh/yr, 85.5% Sensible, 4.5% Latent`, `Detailed Example: 7302 kWh/yr, 82.2% Sensible, 17.8% Latent`


- **Default:** `100% Usage`

<br/>

**Misc: Well Pump**

The amount of well pump usage, relative to the national average.

- **Name:** ``misc_well_pump``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Typical Efficiency`, `High Efficiency`, `Detailed Example: 475 kWh/yr`


- **Default:** `None`

<br/>

**Misc: Electric Vehicle Charging**

The amount of EV charging usage, relative to the national average. Only use this if a detailed EV & EV charger were not otherwise specified.

- **Name:** ``misc_electric_vehicle_charging``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `25% Usage`, `33% Usage`, `50% Usage`, `75% Usage`, `80% Usage`, `90% Usage`, `100% Usage`, `110% Usage`, `125% Usage`, `150% Usage`, `200% Usage`, `300% Usage`, `400% Usage`, `Detailed Example: 1500 kWh/yr`, `Detailed Example: 3000 kWh/yr`


- **Default:** `None`

<br/>

**Misc: Gas Grill**

The amount of outdoor gas grill usage, relative to the national average.

- **Name:** ``misc_grill``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Natural Gas, 25% Usage`, `Natural Gas, 50% Usage`, `Natural Gas, 75% Usage`, `Natural Gas, 100% Usage`, `Natural Gas, 150% Usage`, `Natural Gas, 200% Usage`, `Natural Gas, 400% Usage`, `Propane, 25% Usage`, `Propane, 50% Usage`, `Propane, 75% Usage`, `Propane, 100% Usage`, `Propane, 150% Usage`, `Propane, 200% Usage`, `Propane, 400% Usage`, `Detailed Example: Propane, 25 therm/yr`


- **Default:** `None`

<br/>

**Misc: Gas Lighting**

The amount of gas lighting usage, relative to the national average.

- **Name:** ``misc_gas_lighting``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Natural Gas, 25% Usage`, `Natural Gas, 50% Usage`, `Natural Gas, 75% Usage`, `Natural Gas, 100% Usage`, `Natural Gas, 150% Usage`, `Natural Gas, 200% Usage`, `Natural Gas, 400% Usage`, `Detailed Example: Natural Gas, 28 therm/yr`


- **Default:** `None`

<br/>

**Misc: Fireplace**

The amount of fireplace usage, relative to the national average. Fireplaces can also be specified as heating systems that meet a portion of the heating load.

- **Name:** ``misc_fireplace``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Natural Gas, 25% Usage`, `Natural Gas, 50% Usage`, `Natural Gas, 75% Usage`, `Natural Gas, 100% Usage`, `Natural Gas, 150% Usage`, `Natural Gas, 200% Usage`, `Natural Gas, 400% Usage`, `Propane, 25% Usage`, `Propane, 50% Usage`, `Propane, 75% Usage`, `Propane, 100% Usage`, `Propane, 150% Usage`, `Propane, 200% Usage`, `Propane, 400% Usage`, `Wood, 25% Usage`, `Wood, 50% Usage`, `Wood, 75% Usage`, `Wood, 100% Usage`, `Wood, 150% Usage`, `Wood, 200% Usage`, `Wood, 400% Usage`, `Electric, 25% Usage`, `Electric, 50% Usage`, `Electric, 75% Usage`, `Electric, 100% Usage`, `Electric, 150% Usage`, `Electric, 200% Usage`, `Electric, 400% Usage`, `Detailed Example: Wood, 55 therm/yr`


- **Default:** `None`

<br/>

**Misc: Pool**

The type of pool (pump & heater).

- **Name:** ``misc_pool``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Unheated, 25% Usage`, `Unheated, 50% Usage`, `Unheated, 75% Usage`, `Unheated, 100% Usage`, `Unheated, 150% Usage`, `Unheated, 200% Usage`, `Unheated, 400% Usage`, `Electric Resistance Heater, 25% Usage`, `Electric Resistance Heater, 50% Usage`, `Electric Resistance Heater, 75% Usage`, `Electric Resistance Heater, 100% Usage`, `Electric Resistance Heater, 150% Usage`, `Electric Resistance Heater, 200% Usage`, `Electric Resistance Heater, 400% Usage`, `Heat Pump Heater, 25% Usage`, `Heat Pump Heater, 50% Usage`, `Heat Pump Heater, 75% Usage`, `Heat Pump Heater, 100% Usage`, `Heat Pump Heater, 150% Usage`, `Heat Pump Heater, 200% Usage`, `Heat Pump Heater, 400% Usage`, `Natural Gas Heater, 25% Usage`, `Natural Gas Heater, 50% Usage`, `Natural Gas Heater, 75% Usage`, `Natural Gas Heater, 100% Usage`, `Natural Gas Heater, 150% Usage`, `Natural Gas Heater, 200% Usage`, `Natural Gas Heater, 400% Usage`, `Detailed Example: 2700 kWh/yr Pump, Unheated`, `Detailed Example: 2700 kWh/yr Pump, 500 therms/yr Natural Gas Heater`


- **Default:** `None`

<br/>

**Misc: Permanent Spa**

The type of permanent spa (pump & heater).

- **Name:** ``misc_permanent_spa``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Unheated, 25% Usage`, `Unheated, 50% Usage`, `Unheated, 75% Usage`, `Unheated, 100% Usage`, `Unheated, 150% Usage`, `Unheated, 200% Usage`, `Unheated, 400% Usage`, `Electric Resistance Heater, 25% Usage`, `Electric Resistance Heater, 50% Usage`, `Electric Resistance Heater, 75% Usage`, `Electric Resistance Heater, 100% Usage`, `Electric Resistance Heater, 150% Usage`, `Electric Resistance Heater, 200% Usage`, `Electric Resistance Heater, 400% Usage`, `Heat Pump Heater, 25% Usage`, `Heat Pump Heater, 50% Usage`, `Heat Pump Heater, 75% Usage`, `Heat Pump Heater, 100% Usage`, `Heat Pump Heater, 150% Usage`, `Heat Pump Heater, 200% Usage`, `Heat Pump Heater, 400% Usage`, `Natural Gas Heater, 25% Usage`, `Natural Gas Heater, 50% Usage`, `Natural Gas Heater, 75% Usage`, `Natural Gas Heater, 100% Usage`, `Natural Gas Heater, 150% Usage`, `Natural Gas Heater, 200% Usage`, `Natural Gas Heater, 400% Usage`, `Detailed Example: 1000 kWh/yr Pump, 1300 kWh/yr Electric Resistance Heater`, `Detailed Example: 1000 kWh/yr Pump, 260 kWh/yr Heat Pump Heater`


- **Default:** `None`

<br/>

**Schedules: CSV File Paths**

Absolute/relative paths of csv files containing user-specified detailed schedules, if desired. Use a comma-separated list for multiple files.

- **Name:** ``schedules_paths``
- **Type:** ``String``

- **Required:** ``false``


<br/>

**Advanced Feature**

Select an advanced research feature to use in the model, if desired.

- **Name:** ``advanced_feature``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Temperature Capacitance Multiplier, 1`, `Temperature Capacitance Multiplier, 4`, `Temperature Capacitance Multiplier, 10`, `Temperature Capacitance Multiplier, 15`, `On/Off Thermostat Deadband, 1F`, `On/Off Thermostat Deadband, 2F`, `On/Off Thermostat Deadband, 3F`, `Heat Pump Backup Staging, 5 kW`, `Heat Pump Backup Staging, 10 kW`, `Experimental Ground-to-Air Heat Pump Model`, `HVAC Allow Increased Fixed Capacities`


- **Default:** `None`

<br/>

**Advanced Feature 2**

Select a second advanced research feature to use in the model, if desired.

- **Name:** ``advanced_feature_2``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Temperature Capacitance Multiplier, 1`, `Temperature Capacitance Multiplier, 4`, `Temperature Capacitance Multiplier, 10`, `Temperature Capacitance Multiplier, 15`, `On/Off Thermostat Deadband, 1F`, `On/Off Thermostat Deadband, 2F`, `On/Off Thermostat Deadband, 3F`, `Heat Pump Backup Staging, 5 kW`, `Heat Pump Backup Staging, 10 kW`, `Experimental Ground-to-Air Heat Pump Model`, `HVAC Allow Increased Fixed Capacities`


- **Default:** `None`

<br/>

**Utility Bill Scenario**

The type of utility bill calculations to perform.

- **Name:** ``utility_bill_scenario``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Default (EIA Average Rates)`, `Detailed Example: $0.12/kWh, $1.1/therm, $12/month`, `Detailed Example: Sample Tiered Rate`, `Detailed Example: Sample Time-of-Use Rate`, `Detailed Example: Sample Tiered and Time-of-Use Rate`, `Detailed Example: Sample Real-Time Pricing`, `Detailed Example: Net Metering w/ Wholesale Excess Rate`, `Detailed Example: Net Metering w/ Retail Excess Rate`, `Detailed Example: Feed-in Tariff`


- **Default:** `Default (EIA Average Rates)`

<br/>

**Utility Bill Scenario 2**

The second type of utility bill calculations to perform, if desired.

- **Name:** ``utility_bill_scenario_2``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Default (EIA Average Rates)`, `Detailed Example: $0.12/kWh, $1.1/therm, $12/month`, `Detailed Example: Sample Tiered Rate`, `Detailed Example: Sample Time-of-Use Rate`, `Detailed Example: Sample Tiered and Time-of-Use Rate`, `Detailed Example: Sample Real-Time Pricing`, `Detailed Example: Net Metering w/ Wholesale Excess Rate`, `Detailed Example: Net Metering w/ Retail Excess Rate`, `Detailed Example: Feed-in Tariff`


- **Default:** `None`

<br/>

**Utility Bill Scenario 3**

The third type of utility bill calculations to perform, if desired.

- **Name:** ``utility_bill_scenario_3``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Default (EIA Average Rates)`, `Detailed Example: $0.12/kWh, $1.1/therm, $12/month`, `Detailed Example: Sample Tiered Rate`, `Detailed Example: Sample Time-of-Use Rate`, `Detailed Example: Sample Tiered and Time-of-Use Rate`, `Detailed Example: Sample Real-Time Pricing`, `Detailed Example: Net Metering w/ Wholesale Excess Rate`, `Detailed Example: Net Metering w/ Retail Excess Rate`, `Detailed Example: Feed-in Tariff`


- **Default:** `None`

<br/>

**Additional Properties**

Additional properties specified as key-value pairs (i.e., key=value). If multiple additional properties, use a |-separated list. For example, 'LowIncome=false|Remodeled|Description=2-story home in Denver'. These properties will be stored in the HPXML file under /HPXML/SoftwareInfo/extension/AdditionalProperties.

- **Name:** ``additional_properties``
- **Type:** ``String``

- **Required:** ``false``


<br/>

**Whole SFA/MF Building Simulation?**

Set true if creating an HPXML file to simulate a whole single-family attached or multifamily building with multiple dwelling units within. If an HPXML file already exists at the specified HPXML File Path, a new HPXML Building element describing the current dwelling unit will be appended to this HPXML file.

- **Name:** ``whole_sfa_or_mf_building_sim``
- **Type:** ``Boolean``

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





