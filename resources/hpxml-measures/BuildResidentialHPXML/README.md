
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

- **Choices:** <br/>  - `60`<br/>  - `30`<br/>  - `20`<br/>  - `15`<br/>  - `12`<br/>  - `10`<br/>  - `6`<br/>  - `5`<br/>  - `4`<br/>  - `3`<br/>  - `2`<br/>  - `1`


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

- **Choices:** <br/>  - `Default`<br/>  - `Suburban, Normal`<br/>  - `Suburban, Well-Shielded`<br/>  - `Suburban, Exposed`<br/>  - `Urban, Normal`<br/>  - `Urban, Well-Shielded`<br/>  - `Urban, Exposed`<br/>  - `Rural, Normal`<br/>  - `Rural, Well-Shielded`<br/>  - `Rural, Exposed`


- **Default:** `Default`

<br/>

**Location: Soil Type**

The soil and moisture type.

- **Name:** ``location_soil_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Unknown`<br/>  - `Clay, Dry`<br/>  - `Clay, Mixed`<br/>  - `Clay, Wet`<br/>  - `Gravel, Dry`<br/>  - `Gravel, Mixed`<br/>  - `Gravel, Wet`<br/>  - `Loam, Dry`<br/>  - `Loam, Mixed`<br/>  - `Loam, Wet`<br/>  - `Sand, Dry`<br/>  - `Sand, Mixed`<br/>  - `Sand, Wet`<br/>  - `Silt, Dry`<br/>  - `Silt, Mixed`<br/>  - `Silt, Wet`<br/>  - `0.5 Btu/hr-ft-F`<br/>  - `0.8 Btu/hr-ft-F`<br/>  - `1.1 Btu/hr-ft-F`<br/>  - `1.4 Btu/hr-ft-F`<br/>  - `1.7 Btu/hr-ft-F`<br/>  - `2.0 Btu/hr-ft-F`<br/>  - `2.3 Btu/hr-ft-F`<br/>  - `2.6 Btu/hr-ft-F`<br/>  - `Detailed Example: Sand, Dry, 0.03 Diffusivity`


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

- **Choices:** <br/>  - `Single-Family Detached, 1 Story`<br/>  - `Single-Family Detached, 2 Stories`<br/>  - `Single-Family Detached, 3 Stories`<br/>  - `Single-Family Detached, 4 Stories`<br/>  - `Single-Family Attached, 1 Story`<br/>  - `Single-Family Attached, 2 Stories`<br/>  - `Single-Family Attached, 3 Stories`<br/>  - `Single-Family Attached, 4 Stories`<br/>  - `Apartment Unit, 1 Story`<br/>  - `Manufactured Home, 1 Story`<br/>  - `Manufactured Home, 2 Stories`<br/>  - `Manufactured Home, 3 Stories`<br/>  - `Manufactured Home, 4 Stories`


- **Default:** `Single-Family Detached, 2 Stories`

<br/>

**Geometry: Unit Attached Walls**

For single-family attached and apartment units, the location(s) of the attached walls.

- **Name:** ``geometry_attached_walls``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `1 Side: Front`<br/>  - `1 Side: Back`<br/>  - `1 Side: Left`<br/>  - `1 Side: Right`<br/>  - `2 Sides: Front, Left`<br/>  - `2 Sides: Front, Right`<br/>  - `2 Sides: Back, Left`<br/>  - `2 Sides: Back, Right`<br/>  - `2 Sides: Front, Back`<br/>  - `2 Sides: Left, Right`<br/>  - `3 Sides: Front, Back, Left`<br/>  - `3 Sides: Front, Back, Right`<br/>  - `3 Sides: Front, Left, Right`<br/>  - `3 Sides: Back, Left, Right`


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

- **Choices:** <br/>  - `North`<br/>  - `North-Northeast`<br/>  - `Northeast`<br/>  - `East-Northeast`<br/>  - `East`<br/>  - `East-Southeast`<br/>  - `Southeast`<br/>  - `South-Southeast`<br/>  - `South`<br/>  - `South-Southwest`<br/>  - `Southwest`<br/>  - `West-Southwest`<br/>  - `West`<br/>  - `West-Northwest`<br/>  - `Northwest`<br/>  - `North-Northwest`


- **Default:** `South`

<br/>

**Geometry: Unit Number of Bedrooms**

The number of bedrooms in the unit.

- **Name:** ``geometry_unit_num_bedrooms``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** <br/>  - `0`<br/>  - `1`<br/>  - `2`<br/>  - `3`<br/>  - `4`<br/>  - `5`<br/>  - `6`<br/>  - `7`<br/>  - `8`<br/>  - `9`<br/>  - `10`<br/>  - `11`<br/>  - `12`


- **Default:** `3`

<br/>

**Geometry: Unit Number of Bathrooms**

The number of bathrooms in the unit. Defaults to NumberofBedrooms/2 + 0.5.

- **Name:** ``geometry_unit_num_bathrooms``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Default`<br/>  - `0`<br/>  - `1`<br/>  - `2`<br/>  - `3`<br/>  - `4`<br/>  - `5`<br/>  - `6`<br/>  - `7`<br/>  - `8`<br/>  - `9`<br/>  - `10`<br/>  - `11`<br/>  - `12`


- **Default:** `Default`

<br/>

**Geometry: Unit Number of Occupants**

The number of occupants in the unit. Defaults to an *asset* calculation assuming standard occupancy, in which various end use defaults (e.g., plug loads, appliances, and hot water usage) are calculated based on Number of Bedrooms and Conditioned Floor Area. If provided, an *operational* calculation is instead performed in which the end use defaults reflect real-world data (where possible).

- **Name:** ``geometry_unit_num_occupants``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Default`<br/>  - `0`<br/>  - `1`<br/>  - `2`<br/>  - `3`<br/>  - `4`<br/>  - `5`<br/>  - `6`<br/>  - `7`<br/>  - `8`<br/>  - `9`<br/>  - `10`<br/>  - `11`<br/>  - `12`


- **Default:** `Default`

<br/>

**Geometry: Ceiling Height**

Average distance from the floor to the ceiling.

- **Name:** ``geometry_ceiling_height``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `6.0 ft`<br/>  - `6.5 ft`<br/>  - `7.0 ft`<br/>  - `7.5 ft`<br/>  - `8.0 ft`<br/>  - `8.5 ft`<br/>  - `9.0 ft`<br/>  - `9.5 ft`<br/>  - `10.0 ft`<br/>  - `10.5 ft`<br/>  - `11.0 ft`<br/>  - `11.5 ft`<br/>  - `12.0 ft`<br/>  - `12.5 ft`<br/>  - `13.0 ft`<br/>  - `13.5 ft`<br/>  - `14.0 ft`<br/>  - `14.5 ft`<br/>  - `15.0 ft`


- **Default:** `8.0 ft`

<br/>

**Geometry: Attached Garage**

The type of attached garage. Only applies to single-family detached units.

- **Name:** ``geometry_garage_type``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `1 Car, Left, Fully Inset`<br/>  - `1 Car, Left, Half Protruding`<br/>  - `1 Car, Left, Fully Protruding`<br/>  - `1 Car, Right, Fully Inset`<br/>  - `1 Car, Right, Half Protruding`<br/>  - `1 Car, Right, Fully Protruding`<br/>  - `2 Car, Left, Fully Inset`<br/>  - `2 Car, Left, Half Protruding`<br/>  - `2 Car, Left, Fully Protruding`<br/>  - `2 Car, Right, Fully Inset`<br/>  - `2 Car, Right, Half Protruding`<br/>  - `2 Car, Right, Fully Protruding`<br/>  - `3 Car, Left, Fully Inset`<br/>  - `3 Car, Left, Half Protruding`<br/>  - `3 Car, Left, Fully Protruding`<br/>  - `3 Car, Right, Fully Inset`<br/>  - `3 Car, Right, Half Protruding`<br/>  - `3 Car, Right, Fully Protruding`


- **Default:** `None`

<br/>

**Geometry: Foundation Type**

The foundation type of the building. Garages are assumed to be over slab-on-grade.

- **Name:** ``geometry_foundation_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** <br/>  - `Slab-on-Grade`<br/>  - `Crawlspace, Vented`<br/>  - `Crawlspace, Unvented`<br/>  - `Crawlspace, Conditioned`<br/>  - `Basement, Unconditioned`<br/>  - `Basement, Unconditioned, Half Above-Grade`<br/>  - `Basement, Conditioned`<br/>  - `Basement, Conditioned, Half Above-Grade`<br/>  - `Ambient`<br/>  - `Above Apartment`<br/>  - `Belly and Wing, With Skirt`<br/>  - `Belly and Wing, No Skirt`<br/>  - `Detailed Example: Basement, Unconditioned, 7.25 ft Height, 8 in Above-Grade, 9 in Rim Joists`<br/>  - `Detailed Example: Basement, Conditioned, 7.25 ft Height, 8 in Above-Grade, 9 in Rim Joists`<br/>  - `Detailed Example: Basement, Conditioned, 5 ft Height`<br/>  - `Detailed Example: Crawlspace, Vented, Above-Grade`


- **Default:** `Crawlspace, Vented`

<br/>

**Geometry: Attic Type**

The attic/roof type of the building.

- **Name:** ``geometry_attic_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** <br/>  - `Flat Roof`<br/>  - `Attic, Vented, Gable`<br/>  - `Attic, Vented, Hip`<br/>  - `Attic, Unvented, Gable`<br/>  - `Attic, Unvented, Hip`<br/>  - `Attic, Conditioned, Gable`<br/>  - `Attic, Conditioned, Hip`<br/>  - `Below Apartment`


- **Default:** `Attic, Vented, Gable`

<br/>

**Geometry: Roof Pitch**

The roof pitch of the attic. Ignored if the building has a flat roof.

- **Name:** ``geometry_roof_pitch``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `1:12`<br/>  - `2:12`<br/>  - `3:12`<br/>  - `4:12`<br/>  - `5:12`<br/>  - `6:12`<br/>  - `7:12`<br/>  - `8:12`<br/>  - `9:12`<br/>  - `10:12`<br/>  - `11:12`<br/>  - `12:12`<br/>  - `13:12`<br/>  - `14:12`<br/>  - `15:12`<br/>  - `16:12`


- **Default:** `6:12`

<br/>

**Geometry: Eaves**

The type of eaves extending from the roof.

- **Name:** ``geometry_eaves``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `1 ft`<br/>  - `2 ft`<br/>  - `3 ft`<br/>  - `4 ft`<br/>  - `5 ft`


- **Default:** `2 ft`

<br/>

**Geometry: Neighbor Buildings**

The presence and geometry of neighboring buildings, for shading purposes.

- **Name:** ``geometry_neighbor_buildings``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Left/Right at 2ft`<br/>  - `Left/Right at 4ft`<br/>  - `Left/Right at 5ft`<br/>  - `Left/Right at 7ft`<br/>  - `Left/Right at 10ft`<br/>  - `Left/Right at 12ft`<br/>  - `Left/Right at 15ft`<br/>  - `Left/Right at 20ft`<br/>  - `Left/Right at 25ft`<br/>  - `Left/Right at 27ft`<br/>  - `Left at 2ft`<br/>  - `Left at 4ft`<br/>  - `Left at 5ft`<br/>  - `Left at 7ft`<br/>  - `Left at 10ft`<br/>  - `Left at 12ft`<br/>  - `Left at 15ft`<br/>  - `Left at 20ft`<br/>  - `Left at 25ft`<br/>  - `Left at 27ft`<br/>  - `Right at 2ft`<br/>  - `Right at 4ft`<br/>  - `Right at 5ft`<br/>  - `Right at 7ft`<br/>  - `Right at 10ft`<br/>  - `Right at 12ft`<br/>  - `Right at 15ft`<br/>  - `Right at 20ft`<br/>  - `Right at 25ft`<br/>  - `Right at 27ft`<br/>  - `Detailed Example: Left/Right at 25ft, Front/Back at 80ft, 12ft Height`


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

The amount of skylight area on the unit's front/back/left/right roofs. Use a comma-separated list like '50, 0, 0, 0'.

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

- **Choices:** <br/>  - `Wood Frame, Uninsulated`<br/>  - `Wood Frame, R-11`<br/>  - `Wood Frame, R-13`<br/>  - `Wood Frame, R-15`<br/>  - `Wood Frame, R-19`<br/>  - `Wood Frame, R-21`<br/>  - `Wood Frame, R-25`<br/>  - `Wood Frame, R-30`<br/>  - `Wood Frame, R-35`<br/>  - `Wood Frame, R-38`<br/>  - `Wood Frame, IECC U-0.064`<br/>  - `Wood Frame, IECC U-0.047`<br/>  - `Wood Frame, IECC U-0.033`<br/>  - `Wood Frame, IECC U-0.028`<br/>  - `Detailed Example: Wood Frame, Uninsulated, 2x6, 24 in o.c., 10% Framing, No Carpet/Subfloor`<br/>  - `Detailed Example: Wood Frame, R-11, 2x6, 24 in o.c., 13% Framing, No Carpet/Subfloor`<br/>  - `Detailed Example: Wood Frame, R-11, 2x6, 24 in o.c., 10% Framing, No Carpet/Subfloor`


- **Default:** `Wood Frame, Uninsulated`

<br/>

**Enclosure: Floor Over Garage**

The type and insulation level of the floor over the garage.

- **Name:** ``enclosure_floor_over_garage``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Wood Frame, Uninsulated`<br/>  - `Wood Frame, R-11`<br/>  - `Wood Frame, R-13`<br/>  - `Wood Frame, R-15`<br/>  - `Wood Frame, R-19`<br/>  - `Wood Frame, R-21`<br/>  - `Wood Frame, R-25`<br/>  - `Wood Frame, R-30`<br/>  - `Wood Frame, R-35`<br/>  - `Wood Frame, R-38`<br/>  - `Wood Frame, IECC U-0.064`<br/>  - `Wood Frame, IECC U-0.047`<br/>  - `Wood Frame, IECC U-0.033`<br/>  - `Detailed Example: Wood Frame, Uninsulated, 2x6, 24 in o.c., 10% Framing, No Carpet/Subfloor`<br/>  - `Detailed Example: Wood Frame, R-11, 2x6, 24 in o.c., 13% Framing, No Carpet/Subfloor`<br/>  - `Detailed Example: Wood Frame, R-11, 2x6, 24 in o.c., 10% Framing, No Carpet/Subfloor`


- **Default:** `Wood Frame, Uninsulated`

<br/>

**Enclosure: Foundation Wall**

The type and insulation level of the foundation walls.

- **Name:** ``enclosure_foundation_wall``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Solid Concrete, Uninsulated`<br/>  - `Solid Concrete, Half Wall, R-5`<br/>  - `Solid Concrete, Half Wall, R-10`<br/>  - `Solid Concrete, Half Wall, R-15`<br/>  - `Solid Concrete, Half Wall, R-20`<br/>  - `Solid Concrete, Whole Wall, R-5`<br/>  - `Solid Concrete, Whole Wall, R-10`<br/>  - `Solid Concrete, Whole Wall, R-10.2, Interior`<br/>  - `Solid Concrete, Whole Wall, R-15`<br/>  - `Solid Concrete, Whole Wall, R-20`<br/>  - `Solid Concrete, Assembly R-10.69`<br/>  - `Concrete Block Foam Core, Whole Wall, R-18.9`


- **Default:** `Solid Concrete, Uninsulated`

<br/>

**Enclosure: Rim Joists**

The type and insulation level of the rim joists.

- **Name:** ``enclosure_rim_joist``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Uninsulated`<br/>  - `Interior, R-7`<br/>  - `Interior, R-11`<br/>  - `Interior, R-13`<br/>  - `Interior, R-15`<br/>  - `Interior, R-19`<br/>  - `Interior, R-21`<br/>  - `Exterior, R-5`<br/>  - `Exterior, R-10`<br/>  - `Exterior, R-15`<br/>  - `Exterior, R-20`<br/>  - `Detailed Example: Uninsulated, Fiberboard Sheathing, Hardboard Siding`<br/>  - `Detailed Example: R-11, Fiberboard Sheathing, Hardboard Siding`


- **Default:** `Uninsulated`

<br/>

**Enclosure: Slab**

The type and insulation level of the slab. Applies to slab-on-grade as well as basement/crawlspace foundations. Under Slab insulation is placed horizontally from the edge of the slab inward. Perimeter insulation is placed vertically from the top of the slab downward. Whole Slab insulation is placed horizontally below the entire slab area.

- **Name:** ``enclosure_slab``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Uninsulated`<br/>  - `Under Slab, 2ft, R-5`<br/>  - `Under Slab, 2ft, R-10`<br/>  - `Under Slab, 2ft, R-15`<br/>  - `Under Slab, 2ft, R-20`<br/>  - `Under Slab, 4ft, R-5`<br/>  - `Under Slab, 4ft, R-10`<br/>  - `Under Slab, 4ft, R-15`<br/>  - `Under Slab, 4ft, R-20`<br/>  - `Perimeter, 2ft, R-5`<br/>  - `Perimeter, 2ft, R-10`<br/>  - `Perimeter, 2ft, R-15`<br/>  - `Perimeter, 2ft, R-20`<br/>  - `Perimeter, 4ft, R-5`<br/>  - `Perimeter, 4ft, R-10`<br/>  - `Perimeter, 4ft, R-15`<br/>  - `Perimeter, 4ft, R-20`<br/>  - `Whole Slab, R-5`<br/>  - `Whole Slab, R-10`<br/>  - `Whole Slab, R-15`<br/>  - `Whole Slab, R-20`<br/>  - `Whole Slab, R-30`<br/>  - `Whole Slab, R-40`<br/>  - `Detailed Example: Uninsulated, No Carpet`<br/>  - `Detailed Example: Uninsulated, 100% R-2.08 Carpet`<br/>  - `Detailed Example: Uninsulated, 100% R-2.50 Carpet`<br/>  - `Detailed Example: Perimeter, 2ft, R-5, 100% R-2.08 Carpet`<br/>  - `Detailed Example: Whole Slab, R-5, 100% R-2.5 Carpet`


- **Default:** `Uninsulated`

<br/>

**Enclosure: Ceiling**

The type and insulation level of the ceiling (attic floor).

- **Name:** ``enclosure_ceiling``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** <br/>  - `Uninsulated`<br/>  - `R-7`<br/>  - `R-13`<br/>  - `R-19`<br/>  - `R-30`<br/>  - `R-38`<br/>  - `R-49`<br/>  - `R-60`<br/>  - `IECC U-0.035`<br/>  - `IECC U-0.030`<br/>  - `IECC U-0.026`<br/>  - `IECC U-0.024`<br/>  - `Detailed Example: R-11, 2x6, 24 in o.c., 10% Framing`<br/>  - `Detailed Example: R-19, 2x6, 24 in o.c., 10% Framing`<br/>  - `Detailed Example: R-19 + R-38, 2x6, 24 in o.c., 10% Framing`


- **Default:** `R-30`

<br/>

**Enclosure: Roof**

The type and insulation level of the roof.

- **Name:** ``enclosure_roof``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** <br/>  - `Uninsulated`<br/>  - `R-7`<br/>  - `R-13`<br/>  - `R-19`<br/>  - `R-30`<br/>  - `R-38`<br/>  - `R-49`<br/>  - `IECC U-0.035`<br/>  - `IECC U-0.030`<br/>  - `IECC U-0.026`<br/>  - `IECC U-0.024`<br/>  - `Detailed Example: Uninsulated, 0.5 in plywood, 0.25 in asphalt shingle`


- **Default:** `Uninsulated`

<br/>

**Enclosure: Roof Material**

The material type and color of the roof.

- **Name:** ``enclosure_roof_material``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Asphalt/Fiberglass Shingles, Dark`<br/>  - `Asphalt/Fiberglass Shingles, Medium Dark`<br/>  - `Asphalt/Fiberglass Shingles, Medium`<br/>  - `Asphalt/Fiberglass Shingles, Light`<br/>  - `Asphalt/Fiberglass Shingles, Reflective`<br/>  - `Tile/Slate, Dark`<br/>  - `Tile/Slate, Medium Dark`<br/>  - `Tile/Slate, Medium`<br/>  - `Tile/Slate, Light`<br/>  - `Tile/Slate, Reflective`<br/>  - `Metal, Dark`<br/>  - `Metal, Medium Dark`<br/>  - `Metal, Medium`<br/>  - `Metal, Light`<br/>  - `Metal, Reflective`<br/>  - `Wood Shingles/Shakes, Dark`<br/>  - `Wood Shingles/Shakes, Medium Dark`<br/>  - `Wood Shingles/Shakes, Medium`<br/>  - `Wood Shingles/Shakes, Light`<br/>  - `Wood Shingles/Shakes, Reflective`<br/>  - `Shingles, Dark`<br/>  - `Shingles, Medium Dark`<br/>  - `Shingles, Medium`<br/>  - `Shingles, Light`<br/>  - `Shingles, Reflective`<br/>  - `Synthetic Sheeting, Dark`<br/>  - `Synthetic Sheeting, Medium Dark`<br/>  - `Synthetic Sheeting, Medium`<br/>  - `Synthetic Sheeting, Light`<br/>  - `Synthetic Sheeting, Reflective`<br/>  - `EPS Sheathing, Dark`<br/>  - `EPS Sheathing, Medium Dark`<br/>  - `EPS Sheathing, Medium`<br/>  - `EPS Sheathing, Light`<br/>  - `EPS Sheathing, Reflective`<br/>  - `Concrete, Dark`<br/>  - `Concrete, Medium Dark`<br/>  - `Concrete, Medium`<br/>  - `Concrete, Light`<br/>  - `Concrete, Reflective`<br/>  - `Cool Roof`<br/>  - `Detailed Example: 0.2 Solar Absorptance`<br/>  - `Detailed Example: 0.4 Solar Absorptance`<br/>  - `Detailed Example: 0.6 Solar Absorptance`<br/>  - `Detailed Example: 0.75 Solar Absorptance`


- **Default:** `Asphalt/Fiberglass Shingles, Medium`

<br/>

**Enclosure: Radiant Barrier**

The type of radiant barrier in the attic.

- **Name:** ``enclosure_radiant_barrier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Attic Roof Only`<br/>  - `Attic Roof and Gable Walls`<br/>  - `Attic Floor`


- **Default:** `None`

<br/>

**Enclosure: Walls**

The type and insulation level of the walls.

- **Name:** ``enclosure_wall``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** <br/>  - `Wood Stud, Uninsulated`<br/>  - `Wood Stud, R-7`<br/>  - `Wood Stud, R-11`<br/>  - `Wood Stud, R-13`<br/>  - `Wood Stud, R-15`<br/>  - `Wood Stud, R-19`<br/>  - `Wood Stud, R-21`<br/>  - `Double Wood Stud, R-33`<br/>  - `Double Wood Stud, R-39`<br/>  - `Double Wood Stud, R-45`<br/>  - `Steel Stud, Uninsulated`<br/>  - `Steel Stud, R-11`<br/>  - `Steel Stud, R-13`<br/>  - `Steel Stud, R-15`<br/>  - `Steel Stud, R-19`<br/>  - `Steel Stud, R-21`<br/>  - `Steel Stud, R-25`<br/>  - `Concrete Masonry Unit, Hollow or Concrete Filled, Uninsulated`<br/>  - `Concrete Masonry Unit, Hollow or Concrete Filled, R-7`<br/>  - `Concrete Masonry Unit, Hollow or Concrete Filled, R-11`<br/>  - `Concrete Masonry Unit, Hollow or Concrete Filled, R-13`<br/>  - `Concrete Masonry Unit, Hollow or Concrete Filled, R-15`<br/>  - `Concrete Masonry Unit, Hollow or Concrete Filled, R-19`<br/>  - `Concrete Masonry Unit, Perlite Filled, Uninsulated`<br/>  - `Concrete Masonry Unit, Perlite Filled, R-7`<br/>  - `Concrete Masonry Unit, Perlite Filled, R-11`<br/>  - `Concrete Masonry Unit, Perlite Filled, R-13`<br/>  - `Concrete Masonry Unit, Perlite Filled, R-15`<br/>  - `Concrete Masonry Unit, Perlite Filled, R-19`<br/>  - `Structural Insulated Panel, R-17.5`<br/>  - `Structural Insulated Panel, R-27.5`<br/>  - `Structural Insulated Panel, R-37.5`<br/>  - `Structural Insulated Panel, R-47.5`<br/>  - `Insulated Concrete Forms, R-5 per side`<br/>  - `Insulated Concrete Forms, R-10 per side`<br/>  - `Insulated Concrete Forms, R-15 per side`<br/>  - `Insulated Concrete Forms, R-20 per side`<br/>  - `Structural Brick, Uninsulated`<br/>  - `Structural Brick, R-7`<br/>  - `Structural Brick, R-11`<br/>  - `Structural Brick, R-15`<br/>  - `Structural Brick, R-19`<br/>  - `Wood Stud, IECC U-0.084`<br/>  - `Wood Stud, IECC U-0.082`<br/>  - `Wood Stud, IECC U-0.060`<br/>  - `Wood Stud, IECC U-0.057`<br/>  - `Wood Stud, IECC U-0.048`<br/>  - `Wood Stud, IECC U-0.045`<br/>  - `Detailed Example: Wood Stud, Uninsulated, 2x4, 16 in o.c., 25% Framing`<br/>  - `Detailed Example: Wood Stud, R-11, 2x4, 16 in o.c., 25% Framing`<br/>  - `Detailed Example: Wood Stud, R-18, 2x6, 24 in o.c., 25% Framing`


- **Default:** `Wood Stud, R-13`

<br/>

**Enclosure: Wall Continuous Insulation**

The insulation level of the wall continuous insulation. The R-value of the continuous insulation will be ignored if a wall option with an IECC U-factor is selected.

- **Name:** ``enclosure_wall_continuous_insulation``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Uninsulated`<br/>  - `R-5`<br/>  - `R-6`<br/>  - `R-7`<br/>  - `R-10`<br/>  - `R-12`<br/>  - `R-14`<br/>  - `R-15`<br/>  - `R-18`<br/>  - `R-20`<br/>  - `R-21`<br/>  - `Detailed Example: R-7.2`


- **Default:** `Uninsulated`

<br/>

**Enclosure: Wall Siding**

The type, color, and insulation level of the wall siding. The R-value of the siding will be ignored if a wall option with an IECC U-factor is selected.

- **Name:** ``enclosure_wall_siding``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Aluminum, Dark`<br/>  - `Aluminum, Medium`<br/>  - `Aluminum, Medium Dark`<br/>  - `Aluminum, Light`<br/>  - `Aluminum, Reflective`<br/>  - `Brick, Dark`<br/>  - `Brick, Medium`<br/>  - `Brick, Medium Dark`<br/>  - `Brick, Light`<br/>  - `Brick, Reflective`<br/>  - `Fiber-Cement, Dark`<br/>  - `Fiber-Cement, Medium`<br/>  - `Fiber-Cement, Medium Dark`<br/>  - `Fiber-Cement, Light`<br/>  - `Fiber-Cement, Reflective`<br/>  - `Asbestos, Dark`<br/>  - `Asbestos, Medium`<br/>  - `Asbestos, Medium Dark`<br/>  - `Asbestos, Light`<br/>  - `Asbestos, Reflective`<br/>  - `Composition Shingle, Dark`<br/>  - `Composition Shingle, Medium`<br/>  - `Composition Shingle, Medium Dark`<br/>  - `Composition Shingle, Light`<br/>  - `Composition Shingle, Reflective`<br/>  - `Stucco, Dark`<br/>  - `Stucco, Medium`<br/>  - `Stucco, Medium Dark`<br/>  - `Stucco, Light`<br/>  - `Stucco, Reflective`<br/>  - `Vinyl, Dark`<br/>  - `Vinyl, Medium`<br/>  - `Vinyl, Medium Dark`<br/>  - `Vinyl, Light`<br/>  - `Vinyl, Reflective`<br/>  - `Wood, Dark`<br/>  - `Wood, Medium`<br/>  - `Wood, Medium Dark`<br/>  - `Wood, Light`<br/>  - `Wood, Reflective`<br/>  - `Synthetic Stucco, Dark`<br/>  - `Synthetic Stucco, Medium`<br/>  - `Synthetic Stucco, Medium Dark`<br/>  - `Synthetic Stucco, Light`<br/>  - `Synthetic Stucco, Reflective`<br/>  - `Masonite, Dark`<br/>  - `Masonite, Medium`<br/>  - `Masonite, Medium Dark`<br/>  - `Masonite, Light`<br/>  - `Masonite, Reflective`<br/>  - `Detailed Example: 0.2 Solar Absorptance`<br/>  - `Detailed Example: 0.4 Solar Absorptance`<br/>  - `Detailed Example: 0.6 Solar Absorptance`<br/>  - `Detailed Example: 0.75 Solar Absorptance`


- **Default:** `Wood, Medium`

<br/>

**Enclosure: Windows**

The type of windows.

- **Name:** ``enclosure_window``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** <br/>  - `Single, Clear, Metal`<br/>  - `Single, Clear, Non-Metal`<br/>  - `Double, Clear, Metal, Air`<br/>  - `Double, Clear, Thermal-Break, Air`<br/>  - `Double, Clear, Non-Metal, Air`<br/>  - `Double, Low-E, Non-Metal, Air, High Gain`<br/>  - `Double, Low-E, Non-Metal, Air, Med Gain`<br/>  - `Double, Low-E, Non-Metal, Air, Low Gain`<br/>  - `Double, Low-E, Non-Metal, Gas, High Gain`<br/>  - `Double, Low-E, Non-Metal, Gas, Med Gain`<br/>  - `Double, Low-E, Non-Metal, Gas, Low Gain`<br/>  - `Double, Low-E, Insulated, Air, High Gain`<br/>  - `Double, Low-E, Insulated, Air, Med Gain`<br/>  - `Double, Low-E, Insulated, Air, Low Gain`<br/>  - `Double, Low-E, Insulated, Gas, High Gain`<br/>  - `Double, Low-E, Insulated, Gas, Med Gain`<br/>  - `Double, Low-E, Insulated, Gas, Low Gain`<br/>  - `Triple, Low-E, Non-Metal, Air, High Gain`<br/>  - `Triple, Low-E, Non-Metal, Air, Low Gain`<br/>  - `Triple, Low-E, Non-Metal, Gas, High Gain`<br/>  - `Triple, Low-E, Non-Metal, Gas, Low Gain`<br/>  - `Triple, Low-E, Insulated, Air, High Gain`<br/>  - `Triple, Low-E, Insulated, Air, Low Gain`<br/>  - `Triple, Low-E, Insulated, Gas, High Gain`<br/>  - `Triple, Low-E, Insulated, Gas, Low Gain`<br/>  - `IECC U-1.20, SHGC 0.40`<br/>  - `IECC U-1.20, SHGC 0.30`<br/>  - `IECC U-1.20, SHGC 0.25`<br/>  - `IECC U-0.75, SHGC 0.40`<br/>  - `IECC U-0.65, SHGC 0.40`<br/>  - `IECC U-0.65, SHGC 0.30`<br/>  - `IECC U-0.50, SHGC 0.30`<br/>  - `IECC U-0.50, SHGC 0.25`<br/>  - `IECC U-0.40, SHGC 0.40`<br/>  - `IECC U-0.40, SHGC 0.25`<br/>  - `IECC U-0.35, SHGC 0.40`<br/>  - `IECC U-0.35, SHGC 0.30`<br/>  - `IECC U-0.35, SHGC 0.25`<br/>  - `IECC U-0.32, SHGC 0.25`<br/>  - `IECC U-0.30, SHGC 0.25`<br/>  - `EnergyStar, North-Central`<br/>  - `EnergyStar, Northern`<br/>  - `EnergyStar, South-Central`<br/>  - `EnergyStar, Southern`<br/>  - `Detailed Example: Single, Clear, Aluminum w/ Thermal Break`<br/>  - `Detailed Example: Double, Low-E, Wood, Argon, Insulated Spacer`


- **Default:** `Double, Clear, Metal, Air`

<br/>

**Enclosure: Window Natural Ventilation**

The amount of natural ventilation from occupants opening operable windows when outdoor conditions are favorable.

- **Name:** ``enclosure_window_natural_ventilation``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `33% Operable Windows`<br/>  - `50% Operable Windows`<br/>  - `67% Operable Windows`<br/>  - `100% Operable Windows`<br/>  - `Detailed Example: 67% Operable Windows, 7 Days/Week`


- **Default:** `67% Operable Windows`

<br/>

**Enclosure: Window Interior Shading**

The type of window interior shading. If shading coefficients are selected, note they indicate the reduction in solar gain (e.g., 0.7 indicates 30% reduction).

- **Name:** ``enclosure_window_interior_shading``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Curtains, Light`<br/>  - `Curtains, Medium`<br/>  - `Curtains, Dark`<br/>  - `Shades, Light`<br/>  - `Shades, Medium`<br/>  - `Shades, Dark`<br/>  - `Blinds, Light`<br/>  - `Blinds, Medium`<br/>  - `Blinds, Dark`<br/>  - `Summer 0.5, Winter 0.5`<br/>  - `Summer 0.5, Winter 0.6`<br/>  - `Summer 0.5, Winter 0.7`<br/>  - `Summer 0.5, Winter 0.8`<br/>  - `Summer 0.5, Winter 0.9`<br/>  - `Summer 0.6, Winter 0.6`<br/>  - `Summer 0.6, Winter 0.7`<br/>  - `Summer 0.6, Winter 0.8`<br/>  - `Summer 0.6, Winter 0.9`<br/>  - `Summer 0.7, Winter 0.7`<br/>  - `Summer 0.7, Winter 0.8`<br/>  - `Summer 0.7, Winter 0.9`<br/>  - `Summer 0.8, Winter 0.8`<br/>  - `Summer 0.8, Winter 0.9`<br/>  - `Summer 0.9, Winter 0.9`


- **Default:** `Curtains, Light`

<br/>

**Enclosure: Window Exterior Shading**

The type of window exterior shading. If shading coefficients are selected, note they indicate the reduction in solar gain (e.g., 0.7 indicates 30% reduction).

- **Name:** ``enclosure_window_exterior_shading``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Solar Film`<br/>  - `Solar Screen`<br/>  - `Summer 0.25, Winter 0.25`<br/>  - `Summer 0.25, Winter 0.50`<br/>  - `Summer 0.25, Winter 0.75`<br/>  - `Summer 0.25, Winter 1.00`<br/>  - `Summer 0.50, Winter 0.25`<br/>  - `Summer 0.50, Winter 0.50`<br/>  - `Summer 0.50, Winter 0.75`<br/>  - `Summer 0.50, Winter 1.00`<br/>  - `Summer 0.75, Winter 0.25`<br/>  - `Summer 0.75, Winter 0.50`<br/>  - `Summer 0.75, Winter 0.75`<br/>  - `Summer 0.75, Winter 1.00`<br/>  - `Summer 1.00, Winter 0.25`<br/>  - `Summer 1.00, Winter 0.50`<br/>  - `Summer 1.00, Winter 0.75`<br/>  - `Summer 1.00, Winter 1.00`


- **Default:** `None`

<br/>

**Enclosure: Window Insect Screens**

The type of window insect screens.

- **Name:** ``enclosure_window_insect_screens``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Exterior`<br/>  - `Interior`


- **Default:** `None`

<br/>

**Enclosure: Window Storm**

The type of storm window.

- **Name:** ``enclosure_window_storm``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Clear`<br/>  - `Low-E`


- **Default:** `None`

<br/>

**Enclosure: Window Overhangs**

The type of window overhangs.

- **Name:** ``enclosure_overhangs``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `1ft, All Windows`<br/>  - `2ft, All Windows`<br/>  - `3ft, All Windows`<br/>  - `4ft, All Windows`<br/>  - `5ft, All Windows`<br/>  - `10ft, All Windows`<br/>  - `1ft, Front Windows`<br/>  - `2ft, Front Windows`<br/>  - `3ft, Front Windows`<br/>  - `4ft, Front Windows`<br/>  - `5ft, Front Windows`<br/>  - `10ft, Front Windows`<br/>  - `1ft, Back Windows`<br/>  - `2ft, Back Windows`<br/>  - `3ft, Back Windows`<br/>  - `4ft, Back Windows`<br/>  - `5ft, Back Windows`<br/>  - `10ft, Back Windows`<br/>  - `1ft, Left Windows`<br/>  - `2ft, Left Windows`<br/>  - `3ft, Left Windows`<br/>  - `4ft, Left Windows`<br/>  - `5ft, Left Windows`<br/>  - `10ft, Left Windows`<br/>  - `1ft, Right Windows`<br/>  - `2ft, Right Windows`<br/>  - `3ft, Right Windows`<br/>  - `4ft, Right Windows`<br/>  - `5ft, Right Windows`<br/>  - `10ft, Right Windows`<br/>  - `Detailed Example: 1.5ft, Back/Left/Right Windows, 2ft Offset, 4ft Window Height`<br/>  - `Detailed Example: 2.5ft, Front Windows, 1ft Offset, 5ft Window Height`


- **Default:** `None`

<br/>

**Enclosure: Skylights**

The type of skylights.

- **Name:** ``enclosure_skylight``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Single, Clear, Metal`<br/>  - `Single, Clear, Non-Metal`<br/>  - `Double, Clear, Metal`<br/>  - `Double, Clear, Non-Metal`<br/>  - `Double, Low-E, Metal, High Gain`<br/>  - `Double, Low-E, Non-Metal, High Gain`<br/>  - `Double, Low-E, Metal, Med Gain`<br/>  - `Double, Low-E, Non-Metal, Med Gain`<br/>  - `Double, Low-E, Metal, Low Gain`<br/>  - `Double, Low-E, Non-Metal, Low Gain`<br/>  - `Triple, Clear, Metal`<br/>  - `Triple, Clear, Non-Metal`<br/>  - `IECC U-0.75, SHGC 0.40`<br/>  - `IECC U-0.75, SHGC 0.30`<br/>  - `IECC U-0.75, SHGC 0.25`<br/>  - `IECC U-0.65, SHGC 0.40`<br/>  - `IECC U-0.65, SHGC 0.30`<br/>  - `IECC U-0.65, SHGC 0.25`<br/>  - `IECC U-0.60, SHGC 0.40`<br/>  - `IECC U-0.60, SHGC 0.30`<br/>  - `IECC U-0.55, SHGC 0.40`<br/>  - `IECC U-0.55, SHGC 0.25`


- **Default:** `Single, Clear, Metal`

<br/>

**Enclosure: Doors**

The type of doors.

- **Name:** ``enclosure_door``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Solid Wood, R-2`<br/>  - `Solid Wood, R-3`<br/>  - `Insulated Fiberglass/Steel, R-4`<br/>  - `Insulated Fiberglass/Steel, R-5`<br/>  - `Insulated Fiberglass/Steel, R-6`<br/>  - `Insulated Fiberglass/Steel, R-7`<br/>  - `IECC U-1.20`<br/>  - `IECC U-0.75`<br/>  - `IECC U-0.65`<br/>  - `IECC U-0.50`<br/>  - `IECC U-0.40`<br/>  - `IECC U-0.35`<br/>  - `IECC U-0.32`<br/>  - `IECC U-0.30`<br/>  - `Detailed Example: Solid Wood, R-3.04`<br/>  - `Detailed Example: Insulated Fiberglass/Steel, R-4.4`


- **Default:** `Solid Wood, R-2`

<br/>

**Enclosure: Air Leakage**

The amount of air leakage coming from outside. If a qualitative leakiness description (e.g., 'Average') is selected, the Year Built of the home is also required.

- **Name:** ``enclosure_air_leakage``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Very Tight`<br/>  - `Tight`<br/>  - `Average`<br/>  - `Leaky`<br/>  - `Very Leaky`<br/>  - `1 ACH50`<br/>  - `2 ACH50`<br/>  - `3 ACH50`<br/>  - `4 ACH50`<br/>  - `5 ACH50`<br/>  - `6 ACH50`<br/>  - `7 ACH50`<br/>  - `8 ACH50`<br/>  - `9 ACH50`<br/>  - `10 ACH50`<br/>  - `11 ACH50`<br/>  - `12 ACH50`<br/>  - `13 ACH50`<br/>  - `14 ACH50`<br/>  - `15 ACH50`<br/>  - `16 ACH50`<br/>  - `17 ACH50`<br/>  - `18 ACH50`<br/>  - `19 ACH50`<br/>  - `20 ACH50`<br/>  - `25 ACH50`<br/>  - `30 ACH50`<br/>  - `35 ACH50`<br/>  - `40 ACH50`<br/>  - `45 ACH50`<br/>  - `50 ACH50`<br/>  - `0.2 nACH`<br/>  - `0.3 nACH`<br/>  - `0.335 nACH`<br/>  - `0.5 nACH`<br/>  - `0.67 nACH`<br/>  - `1.0 nACH`<br/>  - `1.5 nACH`<br/>  - `Detailed Example: 3.57 ACH50`<br/>  - `Detailed Example: 12.16 ACH50`<br/>  - `Detailed Example: 2.8 ACH45`<br/>  - `Detailed Example: 0.375 nACH`<br/>  - `Detailed Example: 72 nCFM`<br/>  - `Detailed Example: 79.8 sq. in. ELA`<br/>  - `Detailed Example: 123 sq. in. ELA`<br/>  - `Detailed Example: 1080 CFM50`<br/>  - `Detailed Example: 1010 CFM45`


- **Default:** `Average`

<br/>

**HVAC: Heating System**

The type and efficiency of the heating system. Use 'None' if there is no heating system or if there is a heat pump serving a heating load.

- **Name:** ``hvac_heating_system``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** <br/>  - `None`<br/>  - `Electric Resistance`<br/>  - `Central Furnace, 60% AFUE`<br/>  - `Central Furnace, 64% AFUE`<br/>  - `Central Furnace, 68% AFUE`<br/>  - `Central Furnace, 72% AFUE`<br/>  - `Central Furnace, 76% AFUE`<br/>  - `Central Furnace, 78% AFUE`<br/>  - `Central Furnace, 80% AFUE`<br/>  - `Central Furnace, 83% AFUE`<br/>  - `Central Furnace, 85% AFUE`<br/>  - `Central Furnace, 88% AFUE`<br/>  - `Central Furnace, 90% AFUE`<br/>  - `Central Furnace, 92% AFUE`<br/>  - `Central Furnace, 92.5% AFUE`<br/>  - `Central Furnace, 95% AFUE`<br/>  - `Central Furnace, 96% AFUE`<br/>  - `Central Furnace, 98% AFUE`<br/>  - `Central Furnace, 100% AFUE`<br/>  - `Wall Furnace, 60% AFUE`<br/>  - `Wall Furnace, 68% AFUE`<br/>  - `Wall Furnace, 82% AFUE`<br/>  - `Wall Furnace, 98% AFUE`<br/>  - `Wall Furnace, 100% AFUE`<br/>  - `Floor Furnace, 60% AFUE`<br/>  - `Floor Furnace, 70% AFUE`<br/>  - `Floor Furnace, 80% AFUE`<br/>  - `Boiler, 60% AFUE`<br/>  - `Boiler, 72% AFUE`<br/>  - `Boiler, 76% AFUE`<br/>  - `Boiler, 78% AFUE`<br/>  - `Boiler, 80% AFUE`<br/>  - `Boiler, 83% AFUE`<br/>  - `Boiler, 85% AFUE`<br/>  - `Boiler, 88% AFUE`<br/>  - `Boiler, 90% AFUE`<br/>  - `Boiler, 92% AFUE`<br/>  - `Boiler, 92.5% AFUE`<br/>  - `Boiler, 95% AFUE`<br/>  - `Boiler, 96% AFUE`<br/>  - `Boiler, 98% AFUE`<br/>  - `Boiler, 100% AFUE`<br/>  - `Stove, 60% Efficiency`<br/>  - `Stove, 70% Efficiency`<br/>  - `Stove, 80% Efficiency`<br/>  - `Space Heater, 60% Efficiency`<br/>  - `Space Heater, 70% Efficiency`<br/>  - `Space Heater, 80% Efficiency`<br/>  - `Space Heater, 92% Efficiency`<br/>  - `Space Heater, 100% Efficiency`<br/>  - `Fireplace, 60% Efficiency`<br/>  - `Fireplace, 70% Efficiency`<br/>  - `Fireplace, 80% Efficiency`<br/>  - `Fireplace, 100% Efficiency`<br/>  - `Detailed Example: Central Furnace, 92% AFUE, 600 Btu/hr Pilot Light`<br/>  - `Detailed Example: Floor Furnace, 80% AFUE, 600 Btu/hr Pilot Light`<br/>  - `Detailed Example: Boiler, 92% AFUE, 600 Btu/hr Pilot Light`


- **Default:** `Central Furnace, 78% AFUE`

<br/>

**HVAC: Heating System Fuel Type**

The fuel type of the heating system. Ignored for ElectricResistance.

- **Name:** ``hvac_heating_system_fuel``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Electricity`<br/>  - `Natural Gas`<br/>  - `Fuel Oil`<br/>  - `Propane`<br/>  - `Wood Cord`<br/>  - `Wood Pellets`<br/>  - `Coal`


- **Default:** `Natural Gas`

<br/>

**HVAC: Heating System Capacity**

The output capacity of the heating system.

- **Name:** ``hvac_heating_system_capacity``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Autosize`<br/>  - `5 kBtu/hr`<br/>  - `10 kBtu/hr`<br/>  - `15 kBtu/hr`<br/>  - `20 kBtu/hr`<br/>  - `25 kBtu/hr`<br/>  - `30 kBtu/hr`<br/>  - `35 kBtu/hr`<br/>  - `40 kBtu/hr`<br/>  - `45 kBtu/hr`<br/>  - `50 kBtu/hr`<br/>  - `55 kBtu/hr`<br/>  - `60 kBtu/hr`<br/>  - `65 kBtu/hr`<br/>  - `70 kBtu/hr`<br/>  - `75 kBtu/hr`<br/>  - `80 kBtu/hr`<br/>  - `85 kBtu/hr`<br/>  - `90 kBtu/hr`<br/>  - `95 kBtu/hr`<br/>  - `100 kBtu/hr`<br/>  - `105 kBtu/hr`<br/>  - `110 kBtu/hr`<br/>  - `115 kBtu/hr`<br/>  - `120 kBtu/hr`<br/>  - `125 kBtu/hr`<br/>  - `130 kBtu/hr`<br/>  - `135 kBtu/hr`<br/>  - `140 kBtu/hr`<br/>  - `145 kBtu/hr`<br/>  - `150 kBtu/hr`<br/>  - `Detailed Example: Autosize, 140% Multiplier`<br/>  - `Detailed Example: Autosize, 170% Multiplier`<br/>  - `Detailed Example: Autosize, 90% Multiplier, 45 kBtu/hr Limit`<br/>  - `Detailed Example: Autosize, 140% Multiplier, 45 kBtu/hr Limit`


- **Default:** `Autosize`

<br/>

**HVAC: Heating System Fraction Heat Load Served**

The fraction of the heating load served by the heating system.

- **Name:** ``hvac_heating_system_heating_load_served``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `100%`<br/>  - `95%`<br/>  - `90%`<br/>  - `85%`<br/>  - `80%`<br/>  - `75%`<br/>  - `70%`<br/>  - `65%`<br/>  - `60%`<br/>  - `55%`<br/>  - `50%`<br/>  - `45%`<br/>  - `40%`<br/>  - `35%`<br/>  - `30%`<br/>  - `25%`<br/>  - `20%`<br/>  - `15%`<br/>  - `10%`<br/>  - `5%`<br/>  - `0%`


- **Default:** `100%`

<br/>

**HVAC: Cooling System**

The type and efficiency of the cooling system. Use 'None' if there is no cooling system or if there is a heat pump serving a cooling load.

- **Name:** ``hvac_cooling_system``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** <br/>  - `None`<br/>  - `Central AC, SEER2 7.6`<br/>  - `Central AC, SEER2 9.5`<br/>  - `Central AC, SEER2 12.4`<br/>  - `Central AC, SEER2 13.4`<br/>  - `Central AC, SEER2 13.8`<br/>  - `Central AC, SEER2 14.0`<br/>  - `Central AC, SEER2 14.3`<br/>  - `Central AC, SEER2 15.0`<br/>  - `Central AC, SEER2 16.0`<br/>  - `Central AC, SEER2 17.0`<br/>  - `Central AC, SEER2 18.0`<br/>  - `Central AC, SEER2 19.0`<br/>  - `Central AC, SEER2 20.0`<br/>  - `Central AC, SEER2 21.0`<br/>  - `Central AC, SEER2 22.0`<br/>  - `Central AC, SEER2 23.0`<br/>  - `Central AC, SEER2 24.0`<br/>  - `Central AC, SEER2 25.0`<br/>  - `Ductless Mini-Split AC, SEER2 14.5`<br/>  - `Ductless Mini-Split AC, SEER2 16.0`<br/>  - `Ductless Mini-Split AC, SEER2 17.0`<br/>  - `Ductless Mini-Split AC, SEER2 18.0`<br/>  - `Ductless Mini-Split AC, SEER2 19.0`<br/>  - `Ductless Mini-Split AC, SEER2 20.0`<br/>  - `Ductless Mini-Split AC, SEER2 21.0`<br/>  - `Ductless Mini-Split AC, SEER2 22.0`<br/>  - `Ductless Mini-Split AC, SEER2 23.0`<br/>  - `Ductless Mini-Split AC, SEER2 24.0`<br/>  - `Ductless Mini-Split AC, SEER2 25.0`<br/>  - `Ductless Mini-Split AC, SEER2 26.0`<br/>  - `Ductless Mini-Split AC, SEER2 27.0`<br/>  - `Ductless Mini-Split AC, SEER2 28.0`<br/>  - `Room AC, CEER 8.4`<br/>  - `Room AC, CEER 9.7`<br/>  - `Room AC, CEER 10.6`<br/>  - `Room AC, CEER 11.0`<br/>  - `Room AC, CEER 11.9`<br/>  - `Room AC, CEER 13.1`<br/>  - `Packaged Terminal AC, EER 8.5`<br/>  - `Packaged Terminal AC, EER 9.8`<br/>  - `Packaged Terminal AC, EER 10.7`<br/>  - `Packaged Terminal AC, EER 11.9`<br/>  - `Packaged Terminal AC, EER 13.2`<br/>  - `Evaporative Cooler`<br/>  - `Detailed Example: Central AC, SEER2 13.4, Absolute Detailed Performance`<br/>  - `Detailed Example: Central AC, SEER2 17.1, Absolute Detailed Performance`<br/>  - `Detailed Example: Central AC, SEER 17.5, Absolute Detailed Performance`<br/>  - `Detailed Example: Central AC, SEER 17.5, Normalized Detailed Performance`<br/>  - `Detailed Example: Ductless Mini-Split AC, SEER2 19.0, Absolute Detailed Performance`<br/>  - `Detailed Example: Ductless Mini-Split AC, SEER2 19.0, Normalized Detailed Performance`


- **Default:** `Central AC, SEER2 13.4`

<br/>

**HVAC: Cooling System Capacity**

The output capacity of the cooling system.

- **Name:** ``hvac_cooling_system_capacity``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Autosize`<br/>  - `0.5 tons`<br/>  - `0.75 tons`<br/>  - `1.0 tons`<br/>  - `1.5 tons`<br/>  - `2.0 tons`<br/>  - `2.5 tons`<br/>  - `3.0 tons`<br/>  - `3.5 tons`<br/>  - `4.0 tons`<br/>  - `4.5 tons`<br/>  - `5.0 tons`<br/>  - `5.5 tons`<br/>  - `6.0 tons`<br/>  - `6.5 tons`<br/>  - `7.0 tons`<br/>  - `7.5 tons`<br/>  - `8.0 tons`<br/>  - `8.5 tons`<br/>  - `9.0 tons`<br/>  - `9.5 tons`<br/>  - `10.0 tons`<br/>  - `Detailed Example: Autosize, 140% Multiplier`<br/>  - `Detailed Example: Autosize, 170% Multiplier`<br/>  - `Detailed Example: Autosize, 170% Multiplier, 3.0 tons Limit`


- **Default:** `Autosize`

<br/>

**HVAC: Cooling System Fraction Cool Load Served**

The fraction of the cooling load served by the cooling system.

- **Name:** ``hvac_cooling_system_cooling_load_served``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `100%`<br/>  - `95%`<br/>  - `90%`<br/>  - `85%`<br/>  - `80%`<br/>  - `75%`<br/>  - `70%`<br/>  - `65%`<br/>  - `60%`<br/>  - `55%`<br/>  - `50%`<br/>  - `45%`<br/>  - `40%`<br/>  - `35%`<br/>  - `30%`<br/>  - `25%`<br/>  - `20%`<br/>  - `15%`<br/>  - `10%`<br/>  - `5%`<br/>  - `0%`


- **Default:** `100%`

<br/>

**HVAC: Heat Pump**

The type and efficiency of the heat pump.

- **Name:** ``hvac_heat_pump``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** <br/>  - `None`<br/>  - `Central HP, SEER2 7.6, HSPF2 5.1`<br/>  - `Central HP, SEER2 9.5, HSPF2 5.8`<br/>  - `Central HP, SEER2 12.4, HSPF2 6.6`<br/>  - `Central HP, SEER2 13.4, HSPF2 7.0`<br/>  - `Central HP, SEER2 13.8, HSPF2 7.2`<br/>  - `Central HP, SEER2 14.0, HSPF2 7.3`<br/>  - `Central HP, SEER2 14.3, HSPF2 7.4`<br/>  - `Central HP, SEER2 15.0, HSPF2 7.6`<br/>  - `Central HP, SEER2 16.0, HSPF2 7.9`<br/>  - `Central HP, SEER2 17.0, HSPF2 8.2`<br/>  - `Central HP, SEER2 18.0, HSPF2 8.5`<br/>  - `Central HP, SEER2 19.0, HSPF2 8.7`<br/>  - `Central HP, SEER2 20.0, HSPF2 9.0`<br/>  - `Central HP, SEER2 21.0, HSPF2 9.2`<br/>  - `Central HP, SEER2 22.0, HSPF2 9.5`<br/>  - `Ductless Mini-Split HP, SEER2 13.7, HSPF2 7.4`<br/>  - `Ductless Mini-Split HP, SEER2 14.5, HSPF2 7.7`<br/>  - `Ductless Mini-Split HP, SEER2 16.0, HSPF2 8.1`<br/>  - `Ductless Mini-Split HP, SEER2 17.0, HSPF2 8.5`<br/>  - `Ductless Mini-Split HP, SEER2 18.0, HSPF2 8.8`<br/>  - `Ductless Mini-Split HP, SEER2 19.0, HSPF2 9.0`<br/>  - `Ductless Mini-Split HP, SEER2 20.0, HSPF2 9.4`<br/>  - `Ductless Mini-Split HP, SEER2 21.0, HSPF2 9.7`<br/>  - `Ductless Mini-Split HP, SEER2 22.0, HSPF2 10.1`<br/>  - `Ductless Mini-Split HP, SEER2 23.0, HSPF2 10.4`<br/>  - `Ductless Mini-Split HP, SEER2 24.0, HSPF2 10.7`<br/>  - `Ductless Mini-Split HP, SEER2 25.0, HSPF2 11.0`<br/>  - `Ductless Mini-Split HP, SEER2 26.0, HSPF2 11.4`<br/>  - `Ductless Mini-Split HP, SEER2 27.0, HSPF2 11.7`<br/>  - `Ductless Mini-Split HP, SEER2 28.0, HSPF2 12.0`<br/>  - `Ductless Mini-Split HP, SEER2 29.0, HSPF2 12.3`<br/>  - `Ductless Mini-Split HP, SEER2 30.0, HSPF2 12.7`<br/>  - `Ductless Mini-Split HP, SEER2 32.0, HSPF2 13.3`<br/>  - `Geothermal HP, EER 16.6, COP 3.6`<br/>  - `Geothermal HP, EER 18.6, COP 3.8`<br/>  - `Geothermal HP, EER 20.5, COP 4.0`<br/>  - `Geothermal HP, EER 30.9, COP 4.4`<br/>  - `Room HP, CEER 8.4, COP 2.7`<br/>  - `Room HP, CEER 9.7, COP 3.0`<br/>  - `Room HP, CEER 10.6, COP 3.3`<br/>  - `Room HP, CEER 11.8, COP 3.6`<br/>  - `Room HP, CEER 13.1, COP 3.9`<br/>  - `Packaged Terminal HP, EER 8.5, COP 2.7`<br/>  - `Packaged Terminal HP, EER 9.8, COP 3.0`<br/>  - `Packaged Terminal HP, EER 10.7, COP 3.3`<br/>  - `Packaged Terminal HP, EER 11.9, COP 3.6`<br/>  - `Packaged Terminal HP, EER 13.2, COP 3.9`<br/>  - `Detailed Example: Central HP, SEER2 12.4, HSPF2 8.4`<br/>  - `Detailed Example: Central HP, SEER2 13.4, HSPF2 7.0, Absolute Detailed Performance`<br/>  - `Detailed Example: Central HP, SEER2 17.1, HSPF2 7.9, Absolute Detailed Performance`<br/>  - `Detailed Example: Central HP, SEER 17.5, HSPF 9.5, Absolute Detailed Performance`<br/>  - `Detailed Example: Central HP, SEER 17.5, HSPF 9.5, Normalized Detailed Performance`<br/>  - `Detailed Example: Ductless Mini-Split HP, SEER2 19.0, HSPF2 9.0, Absolute Detailed Performance`<br/>  - `Detailed Example: Ductless Mini-Split HP, SEER2 19.0, HSPF2 9.0, Normalized Detailed Performance`


- **Default:** `None`

<br/>

**HVAC: Heat Pump Capacity**

The output capacity of the heat pump.

- **Name:** ``hvac_heat_pump_capacity``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Autosize`<br/>  - `Autosize (ACCA)`<br/>  - `Autosize (MaxLoad)`<br/>  - `0.5 tons`<br/>  - `0.75 tons`<br/>  - `1.0 tons`<br/>  - `1.5 tons`<br/>  - `2.0 tons`<br/>  - `2.5 tons`<br/>  - `3.0 tons`<br/>  - `3.5 tons`<br/>  - `4.0 tons`<br/>  - `4.5 tons`<br/>  - `5.0 tons`<br/>  - `5.5 tons`<br/>  - `6.0 tons`<br/>  - `6.5 tons`<br/>  - `7.0 tons`<br/>  - `7.5 tons`<br/>  - `8.0 tons`<br/>  - `8.5 tons`<br/>  - `9.0 tons`<br/>  - `9.5 tons`<br/>  - `10.0 tons`<br/>  - `Detailed Example: Autosize, 140% Multiplier`<br/>  - `Detailed Example: Autosize, 170% Multiplier`<br/>  - `Detailed Example: Autosize, 170% Multiplier, 3.0 tons Limit`


- **Default:** `Autosize`

<br/>

**HVAC: Heat Pump Fraction Heat Load Served**

The fraction of the heating load served by the heat pump.

- **Name:** ``hvac_heat_pump_heating_load_served``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `100%`<br/>  - `95%`<br/>  - `90%`<br/>  - `85%`<br/>  - `80%`<br/>  - `75%`<br/>  - `70%`<br/>  - `65%`<br/>  - `60%`<br/>  - `55%`<br/>  - `50%`<br/>  - `45%`<br/>  - `40%`<br/>  - `35%`<br/>  - `30%`<br/>  - `25%`<br/>  - `20%`<br/>  - `15%`<br/>  - `10%`<br/>  - `5%`<br/>  - `0%`


- **Default:** `100%`

<br/>

**HVAC: Heat Pump Fraction Cool Load Served**

The fraction of the cooling load served by the heat pump.

- **Name:** ``hvac_heat_pump_cooling_load_served``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `100%`<br/>  - `95%`<br/>  - `90%`<br/>  - `85%`<br/>  - `80%`<br/>  - `75%`<br/>  - `70%`<br/>  - `65%`<br/>  - `60%`<br/>  - `55%`<br/>  - `50%`<br/>  - `45%`<br/>  - `40%`<br/>  - `35%`<br/>  - `30%`<br/>  - `25%`<br/>  - `20%`<br/>  - `15%`<br/>  - `10%`<br/>  - `5%`<br/>  - `0%`


- **Default:** `100%`

<br/>

**HVAC: Heat Pump Temperatures**

Specifies the minimum compressor temperature and/or maximum HP backup temperature. If both are the same, a binary switchover temperature is used.

- **Name:** ``hvac_heat_pump_temperatures``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Default`<br/>  - `-20F Min Compressor Temp`<br/>  - `-15F Min Compressor Temp`<br/>  - `-10F Min Compressor Temp`<br/>  - `-5F Min Compressor Temp`<br/>  - `0F Min Compressor Temp`<br/>  - `5F Min Compressor Temp`<br/>  - `10F Min Compressor Temp`<br/>  - `15F Min Compressor Temp`<br/>  - `20F Min Compressor Temp`<br/>  - `25F Min Compressor Temp`<br/>  - `30F Min Compressor Temp`<br/>  - `35F Min Compressor Temp`<br/>  - `40F Min Compressor Temp`<br/>  - `30F Min Compressor Temp, 30F Max HP Backup Temp`<br/>  - `35F Min Compressor Temp, 35F Max HP Backup Temp`<br/>  - `40F Min Compressor Temp, 40F Max HP Backup Temp`<br/>  - `Detailed Example: 5F Min Compressor Temp, 35F Max HP Backup Temp`<br/>  - `Detailed Example: 25F Min Compressor Temp, 45F Max HP Backup Temp`


- **Default:** `Default`

<br/>

**HVAC: Heat Pump Backup Type**

The type and efficiency of the heat pump backup. Use 'None' if there is no backup heating. If Backup Type is Separate Heating System, Heating System 2 is used to specify the backup.

- **Name:** ``hvac_heat_pump_backup``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Integrated, Electricity, 100% Efficiency`<br/>  - `Integrated, Natural Gas, 60% AFUE`<br/>  - `Integrated, Natural Gas, 76% AFUE`<br/>  - `Integrated, Natural Gas, 80% AFUE`<br/>  - `Integrated, Natural Gas, 92.5% AFUE`<br/>  - `Integrated, Natural Gas, 95% AFUE`<br/>  - `Integrated, Fuel Oil, 60% AFUE`<br/>  - `Integrated, Fuel Oil, 76% AFUE`<br/>  - `Integrated, Fuel Oil, 80% AFUE`<br/>  - `Integrated, Fuel Oil, 92.5% AFUE`<br/>  - `Integrated, Fuel Oil, 95% AFUE`<br/>  - `Integrated, Propane, 60% AFUE`<br/>  - `Integrated, Propane, 76% AFUE`<br/>  - `Integrated, Propane, 80% AFUE`<br/>  - `Integrated, Propane, 92.5% AFUE`<br/>  - `Integrated, Propane, 95% AFUE`<br/>  - `Separate Heating System`


- **Default:** `Integrated, Electricity, 100% Efficiency`

<br/>

**HVAC: Heat Pump Backup Capacity**

The output capacity of the heat pump backup if there is integrated backup heating.

- **Name:** ``hvac_heat_pump_backup_capacity``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Autosize`<br/>  - `Autosize (Supplemental)`<br/>  - `5 kW`<br/>  - `10 kW`<br/>  - `15 kW`<br/>  - `20 kW`<br/>  - `25 kW`<br/>  - `5 kBtu/hr`<br/>  - `10 kBtu/hr`<br/>  - `15 kBtu/hr`<br/>  - `20 kBtu/hr`<br/>  - `25 kBtu/hr`<br/>  - `30 kBtu/hr`<br/>  - `35 kBtu/hr`<br/>  - `40 kBtu/hr`<br/>  - `45 kBtu/hr`<br/>  - `50 kBtu/hr`<br/>  - `55 kBtu/hr`<br/>  - `60 kBtu/hr`<br/>  - `65 kBtu/hr`<br/>  - `70 kBtu/hr`<br/>  - `75 kBtu/hr`<br/>  - `80 kBtu/hr`<br/>  - `85 kBtu/hr`<br/>  - `90 kBtu/hr`<br/>  - `95 kBtu/hr`<br/>  - `100 kBtu/hr`<br/>  - `105 kBtu/hr`<br/>  - `110 kBtu/hr`<br/>  - `115 kBtu/hr`<br/>  - `120 kBtu/hr`<br/>  - `125 kBtu/hr`<br/>  - `130 kBtu/hr`<br/>  - `135 kBtu/hr`<br/>  - `140 kBtu/hr`<br/>  - `145 kBtu/hr`<br/>  - `150 kBtu/hr`<br/>  - `Detailed Example: Autosize, 140% Multiplier`<br/>  - `Detailed Example: Autosize, 170% Multiplier`<br/>  - `Detailed Example: Autosize, 90% Multiplier, 45 kBtu/hr Limit`


- **Default:** `Autosize`

<br/>

**HVAC: Geothermal Loop**

The geothermal loop configuration if there's a ground-to-air heat pump.

- **Name:** ``hvac_geothermal_loop``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Default`<br/>  - `Vertical Loop, Enhanced Grout`<br/>  - `Vertical Loop, Enhanced Pipe`<br/>  - `Vertical Loop, Enhanced Grout & Pipe`<br/>  - `Detailed Example: Lopsided U Configuration, 10 Boreholes`


- **Default:** `Default`

<br/>

**HVAC: Heating System 2**

The type and efficiency of the second heating system. If a heat pump is specified and the backup type is 'separate', this heating system represents the 'separate' backup heating.

- **Name:** ``hvac_heating_system_2``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Electric Resistance`<br/>  - `Central Furnace, 60% AFUE`<br/>  - `Central Furnace, 64% AFUE`<br/>  - `Central Furnace, 68% AFUE`<br/>  - `Central Furnace, 72% AFUE`<br/>  - `Central Furnace, 76% AFUE`<br/>  - `Central Furnace, 78% AFUE`<br/>  - `Central Furnace, 80% AFUE`<br/>  - `Central Furnace, 83% AFUE`<br/>  - `Central Furnace, 85% AFUE`<br/>  - `Central Furnace, 88% AFUE`<br/>  - `Central Furnace, 90% AFUE`<br/>  - `Central Furnace, 92% AFUE`<br/>  - `Central Furnace, 92.5% AFUE`<br/>  - `Central Furnace, 95% AFUE`<br/>  - `Central Furnace, 96% AFUE`<br/>  - `Central Furnace, 98% AFUE`<br/>  - `Central Furnace, 100% AFUE`<br/>  - `Wall Furnace, 60% AFUE`<br/>  - `Wall Furnace, 68% AFUE`<br/>  - `Wall Furnace, 82% AFUE`<br/>  - `Wall Furnace, 98% AFUE`<br/>  - `Wall Furnace, 100% AFUE`<br/>  - `Floor Furnace, 60% AFUE`<br/>  - `Floor Furnace, 70% AFUE`<br/>  - `Floor Furnace, 80% AFUE`<br/>  - `Boiler, 60% AFUE`<br/>  - `Boiler, 72% AFUE`<br/>  - `Boiler, 76% AFUE`<br/>  - `Boiler, 78% AFUE`<br/>  - `Boiler, 80% AFUE`<br/>  - `Boiler, 83% AFUE`<br/>  - `Boiler, 85% AFUE`<br/>  - `Boiler, 88% AFUE`<br/>  - `Boiler, 90% AFUE`<br/>  - `Boiler, 92% AFUE`<br/>  - `Boiler, 92.5% AFUE`<br/>  - `Boiler, 95% AFUE`<br/>  - `Boiler, 96% AFUE`<br/>  - `Boiler, 98% AFUE`<br/>  - `Boiler, 100% AFUE`<br/>  - `Stove, 60% Efficiency`<br/>  - `Stove, 70% Efficiency`<br/>  - `Stove, 80% Efficiency`<br/>  - `Space Heater, 60% Efficiency`<br/>  - `Space Heater, 70% Efficiency`<br/>  - `Space Heater, 80% Efficiency`<br/>  - `Space Heater, 92% Efficiency`<br/>  - `Space Heater, 100% Efficiency`<br/>  - `Fireplace, 60% Efficiency`<br/>  - `Fireplace, 70% Efficiency`<br/>  - `Fireplace, 80% Efficiency`<br/>  - `Fireplace, 100% Efficiency`<br/>  - `Detailed Example: Central Furnace, 92% AFUE, 600 Btu/hr Pilot Light`<br/>  - `Detailed Example: Floor Furnace, 80% AFUE, 600 Btu/hr Pilot Light`<br/>  - `Detailed Example: Boiler, 92% AFUE, 600 Btu/hr Pilot Light`


- **Default:** `None`

<br/>

**HVAC: Heating System 2 Fuel Type**

The fuel type of the second heating system. Ignored for ElectricResistance.

- **Name:** ``hvac_heating_system_2_fuel``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Electricity`<br/>  - `Natural Gas`<br/>  - `Fuel Oil`<br/>  - `Propane`<br/>  - `Wood Cord`<br/>  - `Wood Pellets`<br/>  - `Coal`


- **Default:** `Electricity`

<br/>

**HVAC: Heating System 2 Capacity**

The output capacity of the second heating system.

- **Name:** ``hvac_heating_system_2_capacity``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Autosize`<br/>  - `5 kBtu/hr`<br/>  - `10 kBtu/hr`<br/>  - `15 kBtu/hr`<br/>  - `20 kBtu/hr`<br/>  - `25 kBtu/hr`<br/>  - `30 kBtu/hr`<br/>  - `35 kBtu/hr`<br/>  - `40 kBtu/hr`<br/>  - `45 kBtu/hr`<br/>  - `50 kBtu/hr`<br/>  - `55 kBtu/hr`<br/>  - `60 kBtu/hr`<br/>  - `65 kBtu/hr`<br/>  - `70 kBtu/hr`<br/>  - `75 kBtu/hr`<br/>  - `80 kBtu/hr`<br/>  - `85 kBtu/hr`<br/>  - `90 kBtu/hr`<br/>  - `95 kBtu/hr`<br/>  - `100 kBtu/hr`<br/>  - `105 kBtu/hr`<br/>  - `110 kBtu/hr`<br/>  - `115 kBtu/hr`<br/>  - `120 kBtu/hr`<br/>  - `125 kBtu/hr`<br/>  - `130 kBtu/hr`<br/>  - `135 kBtu/hr`<br/>  - `140 kBtu/hr`<br/>  - `145 kBtu/hr`<br/>  - `150 kBtu/hr`<br/>  - `Detailed Example: Autosize, 140% Multiplier`<br/>  - `Detailed Example: Autosize, 170% Multiplier`<br/>  - `Detailed Example: Autosize, 90% Multiplier, 45 kBtu/hr Limit`<br/>  - `Detailed Example: Autosize, 140% Multiplier, 45 kBtu/hr Limit`


- **Default:** `Autosize`

<br/>

**HVAC: Heating System 2 Fraction Heat Load Served**

The fraction of the heating load served by the second heating system.

- **Name:** ``hvac_heating_system_2_heating_load_served``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `100%`<br/>  - `95%`<br/>  - `90%`<br/>  - `85%`<br/>  - `80%`<br/>  - `75%`<br/>  - `70%`<br/>  - `65%`<br/>  - `60%`<br/>  - `55%`<br/>  - `50%`<br/>  - `45%`<br/>  - `40%`<br/>  - `35%`<br/>  - `30%`<br/>  - `25%`<br/>  - `20%`<br/>  - `15%`<br/>  - `10%`<br/>  - `5%`<br/>  - `0%`


- **Default:** `25%`

<br/>

**HVAC Control: Heating Weekday Setpoint Schedule**

Specify the constant or 24-hour comma-separated weekday heating setpoint schedule.

- **Name:** ``hvac_control_heating_weekday_setpoint``
- **Type:** ``String``

- **Required:** ``false``


- **Default:** `68`

<br/>

**HVAC Control: Heating Weekend Setpoint Schedule**

Specify the constant or 24-hour comma-separated weekend heating setpoint schedule.

- **Name:** ``hvac_control_heating_weekend_setpoint``
- **Type:** ``String``

- **Required:** ``false``


- **Default:** `68`

<br/>

**HVAC Control: Cooling Weekday Setpoint Schedule**

Specify the constant or 24-hour comma-separated weekday cooling setpoint schedule.

- **Name:** ``hvac_control_cooling_weekday_setpoint``
- **Type:** ``String``

- **Required:** ``false``


- **Default:** `78`

<br/>

**HVAC Control: Cooling Weekend Setpoint Schedule**

Specify the constant or 24-hour comma-separated weekend cooling setpoint schedule.

- **Name:** ``hvac_control_cooling_weekend_setpoint``
- **Type:** ``String``

- **Required:** ``false``


- **Default:** `78`

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

- **Choices:** <br/>  - `None`<br/>  - `0% Leakage, Uninsulated`<br/>  - `0% Leakage, R-4`<br/>  - `0% Leakage, R-6`<br/>  - `0% Leakage, R-8`<br/>  - `5% Leakage, Uninsulated`<br/>  - `5% Leakage, R-4`<br/>  - `5% Leakage, R-6`<br/>  - `5% Leakage, R-8`<br/>  - `10% Leakage, Uninsulated`<br/>  - `10% Leakage, R-4`<br/>  - `10% Leakage, R-6`<br/>  - `10% Leakage, R-8`<br/>  - `15% Leakage, Uninsulated`<br/>  - `15% Leakage, R-4`<br/>  - `15% Leakage, R-6`<br/>  - `15% Leakage, R-8`<br/>  - `20% Leakage, Uninsulated`<br/>  - `20% Leakage, R-4`<br/>  - `20% Leakage, R-6`<br/>  - `20% Leakage, R-8`<br/>  - `25% Leakage, Uninsulated`<br/>  - `25% Leakage, R-4`<br/>  - `25% Leakage, R-6`<br/>  - `25% Leakage, R-8`<br/>  - `30% Leakage, Uninsulated`<br/>  - `30% Leakage, R-4`<br/>  - `30% Leakage, R-6`<br/>  - `30% Leakage, R-8`<br/>  - `35% Leakage, Uninsulated`<br/>  - `35% Leakage, R-4`<br/>  - `35% Leakage, R-6`<br/>  - `35% Leakage, R-8`<br/>  - `0 CFM25 per 100ft2, Uninsulated`<br/>  - `0 CFM25 per 100ft2, R-4`<br/>  - `0 CFM25 per 100ft2, R-6`<br/>  - `0 CFM25 per 100ft2, R-8`<br/>  - `1 CFM25 per 100ft2, Uninsulated`<br/>  - `1 CFM25 per 100ft2, R-4`<br/>  - `1 CFM25 per 100ft2, R-6`<br/>  - `1 CFM25 per 100ft2, R-8`<br/>  - `2 CFM25 per 100ft2, Uninsulated`<br/>  - `2 CFM25 per 100ft2, R-4`<br/>  - `2 CFM25 per 100ft2, R-6`<br/>  - `2 CFM25 per 100ft2, R-8`<br/>  - `4 CFM25 per 100ft2, Uninsulated`<br/>  - `4 CFM25 per 100ft2, R-4`<br/>  - `4 CFM25 per 100ft2, R-6`<br/>  - `4 CFM25 per 100ft2, R-8`<br/>  - `6 CFM25 per 100ft2, Uninsulated`<br/>  - `6 CFM25 per 100ft2, R-4`<br/>  - `6 CFM25 per 100ft2, R-6`<br/>  - `6 CFM25 per 100ft2, R-8`<br/>  - `8 CFM25 per 100ft2, Uninsulated`<br/>  - `8 CFM25 per 100ft2, R-4`<br/>  - `8 CFM25 per 100ft2, R-6`<br/>  - `8 CFM25 per 100ft2, R-8`<br/>  - `12 CFM25 per 100ft2, Uninsulated`<br/>  - `12 CFM25 per 100ft2, R-4`<br/>  - `12 CFM25 per 100ft2, R-6`<br/>  - `12 CFM25 per 100ft2, R-8`<br/>  - `Detailed Example: 4 CFM25 per 100ft2 (75% Supply), R-4`<br/>  - `Detailed Example: 5 CFM50 per 100ft2 (75% Supply), R-4`<br/>  - `Detailed Example: 250 CFM25, R-6`<br/>  - `Detailed Example: 400 CFM50 (75% Supply), R-6`


- **Default:** `15% Leakage, Uninsulated`

<br/>

**HVAC Ducts: Supply Location**

The primary location of the supply ducts. The remainder of the supply ducts are assumed to be in conditioned space. Defaults based on the foundation/attic/garage type.

- **Name:** ``hvac_ducts_supply_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Default`<br/>  - `Conditioned Space`<br/>  - `Basement`<br/>  - `Crawlspace`<br/>  - `Attic`<br/>  - `Garage`<br/>  - `Outside`<br/>  - `Exterior Wall`<br/>  - `Under Slab`<br/>  - `Roof Deck`<br/>  - `Manufactured Home Belly`<br/>  - `Detailed Example: Attic, 75%`


- **Default:** `Default`

<br/>

**HVAC Ducts: Return Location**

The primary location of the return ducts. The remainder of the return ducts are assumed to be in conditioned space. Defaults based on the foundation/attic/garage type.

- **Name:** ``hvac_ducts_return_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Default`<br/>  - `Conditioned Space`<br/>  - `Basement`<br/>  - `Crawlspace`<br/>  - `Attic`<br/>  - `Garage`<br/>  - `Outside`<br/>  - `Exterior Wall`<br/>  - `Under Slab`<br/>  - `Roof Deck`<br/>  - `Manufactured Home Belly`<br/>  - `Detailed Example: Attic, 75%`


- **Default:** `Default`

<br/>

**Ventilation Fans: Mechanical Ventilation**

The type of mechanical ventilation system used for whole building ventilation.

- **Name:** ``ventilation_mechanical``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Exhaust Only`<br/>  - `Supply Only`<br/>  - `Balanced`<br/>  - `CFIS`<br/>  - `HRV, 55%`<br/>  - `HRV, 60%`<br/>  - `HRV, 65%`<br/>  - `HRV, 70%`<br/>  - `HRV, 75%`<br/>  - `HRV, 80%`<br/>  - `HRV, 85%`<br/>  - `ERV, 55%`<br/>  - `ERV, 60%`<br/>  - `ERV, 65%`<br/>  - `ERV, 70%`<br/>  - `ERV, 75%`<br/>  - `ERV, 80%`<br/>  - `ERV, 85%`


- **Default:** `None`

<br/>

**Ventilation Fans: Kitchen Exhaust Fan**

The type of kitchen exhaust fan used for local ventilation.

- **Name:** ``ventilation_kitchen``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Default`<br/>  - `100 cfm, 1 hr/day`<br/>  - `100 cfm, 2 hrs/day`<br/>  - `200 cfm, 1 hr/day`<br/>  - `200 cfm, 2 hrs/day`<br/>  - `300 cfm, 1 hr/day`<br/>  - `300 cfm, 2 hrs/day`<br/>  - `Detailed Example: 100 cfm, 1.5 hrs/day @ 6pm, 30 W`


- **Default:** `None`

<br/>

**Ventilation Fans: Bathroom Exhaust Fans**

The type of bathroom exhaust fans used for local ventilation.

- **Name:** ``ventilation_bathroom``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Default`<br/>  - `50 cfm/bathroom, 1 hr/day`<br/>  - `50 cfm/bathroom, 2 hrs/day`<br/>  - `80 cfm/bathroom, 1 hr/day`<br/>  - `80 cfm/bathroom, 2 hrs/day`<br/>  - `100 cfm/bathroom, 1 hr/day`<br/>  - `100 cfm/bathroom, 2 hrs/day`<br/>  - `Detailed Example: 50 cfm/bathroom, 1.5 hrs/day @ 7am, 15 W`


- **Default:** `None`

<br/>

**Ventilation Fans: Whole House Fan**

The type of whole house fans used for seasonal cooling load reduction.

- **Name:** ``ventilation_whole_house_fan``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `1000 cfm`<br/>  - `1500 cfm`<br/>  - `2000 cfm`<br/>  - `2500 cfm`<br/>  - `3000 cfm`<br/>  - `3500 cfm`<br/>  - `4000 cfm`<br/>  - `4500 cfm`<br/>  - `5000 cfm`<br/>  - `5500 cfm`<br/>  - `6000 cfm`<br/>  - `Detailed Example: 4500 cfm, 300 W`


- **Default:** `None`

<br/>

**DHW: Water Heater**

The type and efficiency of the water heater.

- **Name:** ``dhw_water_heater``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** <br/>  - `None`<br/>  - `Electricity, Tank, UEF 0.90`<br/>  - `Electricity, Tank, UEF 0.92`<br/>  - `Electricity, Tank, UEF 0.94`<br/>  - `Electricity, Tankless, UEF 0.94`<br/>  - `Electricity, Tankless, UEF 0.98`<br/>  - `Electricity, Heat Pump, UEF 3.50`<br/>  - `Electricity, Heat Pump, UEF 3.75`<br/>  - `Electricity, Heat Pump, UEF 4.00`<br/>  - `Natural Gas, Tank, UEF 0.57`<br/>  - `Natural Gas, Tank, UEF 0.60`<br/>  - `Natural Gas, Tank, UEF 0.64`<br/>  - `Natural Gas, Tank, UEF 0.67`<br/>  - `Natural Gas, Tank, UEF 0.70`<br/>  - `Natural Gas, Tank, UEF 0.80`<br/>  - `Natural Gas, Tank, UEF 0.90`<br/>  - `Natural Gas, Tankless, UEF 0.82`<br/>  - `Natural Gas, Tankless, UEF 0.93`<br/>  - `Natural Gas, Tankless, UEF 0.96`<br/>  - `Natural Gas, Tankless, UEF 0.98`<br/>  - `Fuel Oil, Tank, UEF 0.61`<br/>  - `Fuel Oil, Tank, UEF 0.64`<br/>  - `Fuel Oil, Tank, UEF 0.67`<br/>  - `Propane, Tank, UEF 0.57`<br/>  - `Propane, Tank, UEF 0.60`<br/>  - `Propane, Tank, UEF 0.64`<br/>  - `Propane, Tank, UEF 0.67`<br/>  - `Propane, Tank, UEF 0.70`<br/>  - `Propane, Tank, UEF 0.80`<br/>  - `Propane, Tank, UEF 0.90`<br/>  - `Propane, Tankless, UEF 0.82`<br/>  - `Propane, Tankless, UEF 0.93`<br/>  - `Propane, Tankless, UEF 0.96`<br/>  - `Wood, Tank, UEF 0.60`<br/>  - `Coal, Tank, UEF 0.60`<br/>  - `Space-Heating Boiler w/ Storage Tank`<br/>  - `Space-Heating Boiler w/ Tankless Coil`<br/>  - `Detailed Example: Electricity, Tank, 40 gal, EF 0.93`<br/>  - `Detailed Example: Electricity, Tank, UEF 0.94, 135F`<br/>  - `Detailed Example: Electricity, Tankless, EF 0.96`<br/>  - `Detailed Example: Electricity, Heat Pump, 80 gal, EF 3.1`<br/>  - `Detailed Example: Natural Gas, Tank, 40 gal, EF 0.56, RE 0.78`<br/>  - `Detailed Example: Natural Gas, Tank, 40 gal, EF 0.62, RE 0.78`<br/>  - `Detailed Example: Natural Gas, Tank, 50 gal, EF 0.59, RE 0.76`<br/>  - `Detailed Example: Natural Gas, Tankless, EF 0.95`


- **Default:** `Electricity, Tank, UEF 0.92`

<br/>

**DHW: Water Heater Location**

The location of the water heater. Defaults based on the foundation/garage type.

- **Name:** ``dhw_water_heater_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Default`<br/>  - `Conditioned Space`<br/>  - `Basement`<br/>  - `Garage`<br/>  - `Crawlspace`<br/>  - `Attic`<br/>  - `Other Heated Space`<br/>  - `Outside`


- **Default:** `Default`

<br/>

**DHW: Hot Water Distribution**

The type of domestic hot water distrubtion.

- **Name:** ``dhw_distribution``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Uninsulated, Standard`<br/>  - `Uninsulated, Recirc, Uncontrolled`<br/>  - `Uninsulated, Recirc, Timer Control`<br/>  - `Uninsulated, Recirc, Temperature Control`<br/>  - `Uninsulated, Recirc, Presence Sensor Demand Control`<br/>  - `Uninsulated, Recirc, Manual Demand Control`<br/>  - `Insulated, Standard`<br/>  - `Insulated, Recirc, Uncontrolled`<br/>  - `Insulated, Recirc, Timer Control`<br/>  - `Insulated, Recirc, Temperature Control`<br/>  - `Insulated, Recirc, Presence Sensor Demand Control`<br/>  - `Insulated, Recirc, Manual Demand Control`<br/>  - `Detailed Example: Insulated, Recirc, Uncontrolled, 156.9ft Loop, 10ft Branch, 50 W`<br/>  - `Detailed Example: Insulated, Recirc, Manual Demand Control, 156.9ft Loop, 10ft Branch, 50 W`


- **Default:** `Uninsulated, Standard`

<br/>

**DHW: Hot Water Fixtures**

The type and usage of domestic hot water fixtures.

- **Name:** ``dhw_fixtures``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Standard, 25% Usage`<br/>  - `Standard, 50% Usage`<br/>  - `Standard, 75% Usage`<br/>  - `Standard, 100% Usage`<br/>  - `Standard, 125% Usage`<br/>  - `Standard, 150% Usage`<br/>  - `Standard, 175% Usage`<br/>  - `Standard, 200% Usage`<br/>  - `Standard, 400% Usage`<br/>  - `Low Flow, 25% Usage`<br/>  - `Low Flow, 50% Usage`<br/>  - `Low Flow, 75% Usage`<br/>  - `Low Flow, 100% Usage`<br/>  - `Low Flow, 125% Usage`<br/>  - `Low Flow, 150% Usage`<br/>  - `Low Flow, 175% Usage`<br/>  - `Low Flow, 200% Usage`<br/>  - `Low Flow, 400% Usage`


- **Default:** `Standard, 100% Usage`

<br/>

**DHW: Drain Water Heat Reovery**

The type of drain water heater recovery.

- **Name:** ``dhw_drain_water_heat_recovery``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `25% Efficient, Preheats Hot Only, All Showers`<br/>  - `25% Efficient, Preheats Hot Only, 1 Shower`<br/>  - `25% Efficient, Preheats Hot and Cold, All Showers`<br/>  - `25% Efficient, Preheats Hot and Cold, 1 Shower`<br/>  - `35% Efficient, Preheats Hot Only, All Showers`<br/>  - `35% Efficient, Preheats Hot Only, 1 Shower`<br/>  - `35% Efficient, Preheats Hot and Cold, All Showers`<br/>  - `35% Efficient, Preheats Hot and Cold, 1 Shower`<br/>  - `45% Efficient, Preheats Hot Only, All Showers`<br/>  - `45% Efficient, Preheats Hot Only, 1 Shower`<br/>  - `45% Efficient, Preheats Hot and Cold, All Showers`<br/>  - `45% Efficient, Preheats Hot and Cold, 1 Shower`<br/>  - `55% Efficient, Preheats Hot Only, All Showers`<br/>  - `55% Efficient, Preheats Hot Only, 1 Shower`<br/>  - `55% Efficient, Preheats Hot and Cold, All Showers`<br/>  - `55% Efficient, Preheats Hot and Cold, 1 Shower`<br/>  - `Detailed Example: 54% Efficient, Preheats Hot and Cold, All Showers`


- **Default:** `None`

<br/>

**DHW: Solar Thermal**

The size and type of the solar thermal system for domestic hot water.

- **Name:** ``dhw_solar_thermal``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Indirect, Flat Plate, 40 sqft`<br/>  - `Indirect, Flat Plate, 64 sqft`<br/>  - `Direct, Flat Plate, 40 sqft`<br/>  - `Direct. Flat Plate, 64 sqft`<br/>  - `Direct, Integrated Collector Storage, 40 sqft`<br/>  - `Direct, Integrated Collector Storage, 64 sqft`<br/>  - `Direct, Evacuated Tube, 40 sqft`<br/>  - `Direct, Evacuated Tube, 64 sqft`<br/>  - `Thermosyphon, Flat Plate, 40 sqft`<br/>  - `Thermosyphon, Flat Plate, 64 sqft`<br/>  - `60% Solar Fraction`<br/>  - `65% Solar Fraction`<br/>  - `70% Solar Fraction`<br/>  - `75% Solar Fraction`<br/>  - `80% Solar Fraction`<br/>  - `85% Solar Fraction`<br/>  - `90% Solar Fraction`<br/>  - `95% Solar Fraction`


- **Default:** `None`

<br/>

**DHW: Solar Thermal Direction**

The azimuth and tilt of the solar thermal system collectors.

- **Name:** ``dhw_solar_thermal_direction``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Roof Pitch, West`<br/>  - `Roof Pitch, Southwest`<br/>  - `Roof Pitch, South`<br/>  - `Roof Pitch, Southeast`<br/>  - `Roof Pitch, East`<br/>  - `Roof Pitch, Northeast`<br/>  - `Roof Pitch, North`<br/>  - `Roof Pitch, Northwest`<br/>  - `0 Degrees`<br/>  - `5 Degrees, West`<br/>  - `5 Degrees, Southwest`<br/>  - `5 Degrees, South`<br/>  - `5 Degrees, Southeast`<br/>  - `5 Degrees, East`<br/>  - `10 Degrees, West`<br/>  - `10 Degrees, Southwest`<br/>  - `10 Degrees, South`<br/>  - `10 Degrees, Southeast`<br/>  - `10 Degrees, East`<br/>  - `15 Degrees, West`<br/>  - `15 Degrees, Southwest`<br/>  - `15 Degrees, South`<br/>  - `15 Degrees, Southeast`<br/>  - `15 Degrees, East`<br/>  - `20 Degrees, West`<br/>  - `20 Degrees, Southwest`<br/>  - `20 Degrees, South`<br/>  - `20 Degrees, Southeast`<br/>  - `20 Degrees, East`<br/>  - `25 Degrees, West`<br/>  - `25 Degrees, Southwest`<br/>  - `25 Degrees, South`<br/>  - `25 Degrees, Southeast`<br/>  - `25 Degrees, East`<br/>  - `30 Degrees, West`<br/>  - `30 Degrees, Southwest`<br/>  - `30 Degrees, South`<br/>  - `30 Degrees, Southeast`<br/>  - `30 Degrees, East`<br/>  - `35 Degrees, West`<br/>  - `35 Degrees, Southwest`<br/>  - `35 Degrees, South`<br/>  - `35 Degrees, Southeast`<br/>  - `35 Degrees, East`<br/>  - `40 Degrees, West`<br/>  - `40 Degrees, Southwest`<br/>  - `40 Degrees, South`<br/>  - `40 Degrees, Southeast`<br/>  - `40 Degrees, East`<br/>  - `45 Degrees, West`<br/>  - `45 Degrees, Southwest`<br/>  - `45 Degrees, South`<br/>  - `45 Degrees, Southeast`<br/>  - `45 Degrees, East`<br/>  - `50 Degrees, West`<br/>  - `50 Degrees, Southwest`<br/>  - `50 Degrees, South`<br/>  - `50 Degrees, Southeast`<br/>  - `50 Degrees, East`


- **Default:** `Roof Pitch, South`

<br/>

**PV: System**

The size and type of the PV system.

- **Name:** ``pv_system``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `0.5 kW`<br/>  - `1.0 kW`<br/>  - `1.5 kW`<br/>  - `2.0 kW`<br/>  - `2.5 kW`<br/>  - `3.0 kW`<br/>  - `3.5 kW`<br/>  - `4.0 kW`<br/>  - `4.5 kW`<br/>  - `5.0 kW`<br/>  - `5.5 kW`<br/>  - `6.0 kW`<br/>  - `6.5 kW`<br/>  - `7.0 kW`<br/>  - `7.5 kW`<br/>  - `8.0 kW`<br/>  - `8.5 kW`<br/>  - `9.0 kW`<br/>  - `9.5 kW`<br/>  - `10.0 kW`<br/>  - `10.5 kW`<br/>  - `11.0 kW`<br/>  - `11.5 kW`<br/>  - `12.0 kW`<br/>  - `12.5 kW`<br/>  - `13.0 kW`<br/>  - `13.5 kW`<br/>  - `14.0 kW`<br/>  - `14.5 kW`<br/>  - `15.0 kW`<br/>  - `Detailed Example: 10.0 kW, Standard, 14% System Losses, 96% Inverter Efficiency`<br/>  - `Detailed Example: 1.5 kW, Premium`<br/>  - `Detailed Example: 1.5 kW, Thin Film`


- **Default:** `None`

<br/>

**PV: System Direction**

The azimuth and tilt of the PV system array.

- **Name:** ``pv_system_direction``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Roof Pitch, West`<br/>  - `Roof Pitch, Southwest`<br/>  - `Roof Pitch, South`<br/>  - `Roof Pitch, Southeast`<br/>  - `Roof Pitch, East`<br/>  - `Roof Pitch, Northeast`<br/>  - `Roof Pitch, North`<br/>  - `Roof Pitch, Northwest`<br/>  - `0 Degrees`<br/>  - `5 Degrees, West`<br/>  - `5 Degrees, Southwest`<br/>  - `5 Degrees, South`<br/>  - `5 Degrees, Southeast`<br/>  - `5 Degrees, East`<br/>  - `10 Degrees, West`<br/>  - `10 Degrees, Southwest`<br/>  - `10 Degrees, South`<br/>  - `10 Degrees, Southeast`<br/>  - `10 Degrees, East`<br/>  - `15 Degrees, West`<br/>  - `15 Degrees, Southwest`<br/>  - `15 Degrees, South`<br/>  - `15 Degrees, Southeast`<br/>  - `15 Degrees, East`<br/>  - `20 Degrees, West`<br/>  - `20 Degrees, Southwest`<br/>  - `20 Degrees, South`<br/>  - `20 Degrees, Southeast`<br/>  - `20 Degrees, East`<br/>  - `25 Degrees, West`<br/>  - `25 Degrees, Southwest`<br/>  - `25 Degrees, South`<br/>  - `25 Degrees, Southeast`<br/>  - `25 Degrees, East`<br/>  - `30 Degrees, West`<br/>  - `30 Degrees, Southwest`<br/>  - `30 Degrees, South`<br/>  - `30 Degrees, Southeast`<br/>  - `30 Degrees, East`<br/>  - `35 Degrees, West`<br/>  - `35 Degrees, Southwest`<br/>  - `35 Degrees, South`<br/>  - `35 Degrees, Southeast`<br/>  - `35 Degrees, East`<br/>  - `40 Degrees, West`<br/>  - `40 Degrees, Southwest`<br/>  - `40 Degrees, South`<br/>  - `40 Degrees, Southeast`<br/>  - `40 Degrees, East`<br/>  - `45 Degrees, West`<br/>  - `45 Degrees, Southwest`<br/>  - `45 Degrees, South`<br/>  - `45 Degrees, Southeast`<br/>  - `45 Degrees, East`<br/>  - `50 Degrees, West`<br/>  - `50 Degrees, Southwest`<br/>  - `50 Degrees, South`<br/>  - `50 Degrees, Southeast`<br/>  - `50 Degrees, East`


- **Default:** `Roof Pitch, South`

<br/>

**PV: System 2**

The size and type of the second PV system.

- **Name:** ``pv_system_2``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `0.5 kW`<br/>  - `1.0 kW`<br/>  - `1.5 kW`<br/>  - `2.0 kW`<br/>  - `2.5 kW`<br/>  - `3.0 kW`<br/>  - `3.5 kW`<br/>  - `4.0 kW`<br/>  - `4.5 kW`<br/>  - `5.0 kW`<br/>  - `5.5 kW`<br/>  - `6.0 kW`<br/>  - `6.5 kW`<br/>  - `7.0 kW`<br/>  - `7.5 kW`<br/>  - `8.0 kW`<br/>  - `8.5 kW`<br/>  - `9.0 kW`<br/>  - `9.5 kW`<br/>  - `10.0 kW`<br/>  - `10.5 kW`<br/>  - `11.0 kW`<br/>  - `11.5 kW`<br/>  - `12.0 kW`<br/>  - `12.5 kW`<br/>  - `13.0 kW`<br/>  - `13.5 kW`<br/>  - `14.0 kW`<br/>  - `14.5 kW`<br/>  - `15.0 kW`<br/>  - `Detailed Example: 10.0 kW, Standard, 14% System Losses`<br/>  - `Detailed Example: 1.5 kW, Premium`<br/>  - `Detailed Example: 1.5 kW, Thin Film`


- **Default:** `None`

<br/>

**PV: System 2 Direction**

The azimuth and tilt of the second PV system array.

- **Name:** ``pv_system_2_direction``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `Roof Pitch, West`<br/>  - `Roof Pitch, Southwest`<br/>  - `Roof Pitch, South`<br/>  - `Roof Pitch, Southeast`<br/>  - `Roof Pitch, East`<br/>  - `Roof Pitch, Northeast`<br/>  - `Roof Pitch, North`<br/>  - `Roof Pitch, Northwest`<br/>  - `0 Degrees`<br/>  - `5 Degrees, West`<br/>  - `5 Degrees, Southwest`<br/>  - `5 Degrees, South`<br/>  - `5 Degrees, Southeast`<br/>  - `5 Degrees, East`<br/>  - `10 Degrees, West`<br/>  - `10 Degrees, Southwest`<br/>  - `10 Degrees, South`<br/>  - `10 Degrees, Southeast`<br/>  - `10 Degrees, East`<br/>  - `15 Degrees, West`<br/>  - `15 Degrees, Southwest`<br/>  - `15 Degrees, South`<br/>  - `15 Degrees, Southeast`<br/>  - `15 Degrees, East`<br/>  - `20 Degrees, West`<br/>  - `20 Degrees, Southwest`<br/>  - `20 Degrees, South`<br/>  - `20 Degrees, Southeast`<br/>  - `20 Degrees, East`<br/>  - `25 Degrees, West`<br/>  - `25 Degrees, Southwest`<br/>  - `25 Degrees, South`<br/>  - `25 Degrees, Southeast`<br/>  - `25 Degrees, East`<br/>  - `30 Degrees, West`<br/>  - `30 Degrees, Southwest`<br/>  - `30 Degrees, South`<br/>  - `30 Degrees, Southeast`<br/>  - `30 Degrees, East`<br/>  - `35 Degrees, West`<br/>  - `35 Degrees, Southwest`<br/>  - `35 Degrees, South`<br/>  - `35 Degrees, Southeast`<br/>  - `35 Degrees, East`<br/>  - `40 Degrees, West`<br/>  - `40 Degrees, Southwest`<br/>  - `40 Degrees, South`<br/>  - `40 Degrees, Southeast`<br/>  - `40 Degrees, East`<br/>  - `45 Degrees, West`<br/>  - `45 Degrees, Southwest`<br/>  - `45 Degrees, South`<br/>  - `45 Degrees, Southeast`<br/>  - `45 Degrees, East`<br/>  - `50 Degrees, West`<br/>  - `50 Degrees, Southwest`<br/>  - `50 Degrees, South`<br/>  - `50 Degrees, Southeast`<br/>  - `50 Degrees, East`


- **Default:** `Roof Pitch, South`

<br/>

**Battery**

The size and type of battery storage.

- **Name:** ``battery``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `5.0 kWh`<br/>  - `7.5 kWh`<br/>  - `10.0 kWh`<br/>  - `12.5 kWh`<br/>  - `15.0 kWh`<br/>  - `17.5 kWh`<br/>  - `20.0 kWh`<br/>  - `Detailed Example: 20.0 kWh, 6 kW, Garage`<br/>  - `Detailed Example: 20.0 kWh, 6 kW, Outside`<br/>  - `Detailed Example: 20.0 kWh, 6 kW, Outside, 80% Efficiency`


- **Default:** `None`

<br/>

**Electric Vehicle**

The type of battery electric vehicle.

- **Name:** ``electric_vehicle``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Compact, 200 Mile Range, 1000 miles/yr`<br/>  - `Compact, 200 Mile Range, 3000 miles/yr`<br/>  - `Compact, 200 Mile Range, 5000 miles/yr`<br/>  - `Compact, 200 Mile Range, 7000 miles/yr`<br/>  - `Compact, 200 Mile Range, 9000 miles/yr`<br/>  - `Compact, 200 Mile Range, 11000 miles/yr`<br/>  - `Compact, 200 Mile Range, 13000 miles/yr`<br/>  - `Compact, 200 Mile Range, 15000 miles/yr`<br/>  - `Compact, 200 Mile Range, 17000 miles/yr`<br/>  - `Compact, 200 Mile Range, 19000 miles/yr`<br/>  - `Compact, 200 Mile Range, 22500 miles/yr`<br/>  - `Compact, 300 Mile Range, 1000 miles/yr`<br/>  - `Compact, 300 Mile Range, 3000 miles/yr`<br/>  - `Compact, 300 Mile Range, 5000 miles/yr`<br/>  - `Compact, 300 Mile Range, 7000 miles/yr`<br/>  - `Compact, 300 Mile Range, 9000 miles/yr`<br/>  - `Compact, 300 Mile Range, 11000 miles/yr`<br/>  - `Compact, 300 Mile Range, 13000 miles/yr`<br/>  - `Compact, 300 Mile Range, 15000 miles/yr`<br/>  - `Compact, 300 Mile Range, 17000 miles/yr`<br/>  - `Compact, 300 Mile Range, 19000 miles/yr`<br/>  - `Compact, 300 Mile Range, 22500 miles/yr`<br/>  - `Midsize, 200 Mile Range, 1000 miles/yr`<br/>  - `Midsize, 200 Mile Range, 3000 miles/yr`<br/>  - `Midsize, 200 Mile Range, 5000 miles/yr`<br/>  - `Midsize, 200 Mile Range, 7000 miles/yr`<br/>  - `Midsize, 200 Mile Range, 9000 miles/yr`<br/>  - `Midsize, 200 Mile Range, 11000 miles/yr`<br/>  - `Midsize, 200 Mile Range, 13000 miles/yr`<br/>  - `Midsize, 200 Mile Range, 15000 miles/yr`<br/>  - `Midsize, 200 Mile Range, 17000 miles/yr`<br/>  - `Midsize, 200 Mile Range, 19000 miles/yr`<br/>  - `Midsize, 200 Mile Range, 22500 miles/yr`<br/>  - `Midsize, 300 Mile Range, 1000 miles/yr`<br/>  - `Midsize, 300 Mile Range, 3000 miles/yr`<br/>  - `Midsize, 300 Mile Range, 5000 miles/yr`<br/>  - `Midsize, 300 Mile Range, 7000 miles/yr`<br/>  - `Midsize, 300 Mile Range, 9000 miles/yr`<br/>  - `Midsize, 300 Mile Range, 11000 miles/yr`<br/>  - `Midsize, 300 Mile Range, 13000 miles/yr`<br/>  - `Midsize, 300 Mile Range, 15000 miles/yr`<br/>  - `Midsize, 300 Mile Range, 17000 miles/yr`<br/>  - `Midsize, 300 Mile Range, 19000 miles/yr`<br/>  - `Midsize, 300 Mile Range, 22500 miles/yr`<br/>  - `Pickup, 200 Mile Range, 1000 miles/yr`<br/>  - `Pickup, 200 Mile Range, 3000 miles/yr`<br/>  - `Pickup, 200 Mile Range, 5000 miles/yr`<br/>  - `Pickup, 200 Mile Range, 7000 miles/yr`<br/>  - `Pickup, 200 Mile Range, 9000 miles/yr`<br/>  - `Pickup, 200 Mile Range, 11000 miles/yr`<br/>  - `Pickup, 200 Mile Range, 13000 miles/yr`<br/>  - `Pickup, 200 Mile Range, 15000 miles/yr`<br/>  - `Pickup, 200 Mile Range, 17000 miles/yr`<br/>  - `Pickup, 200 Mile Range, 19000 miles/yr`<br/>  - `Pickup, 200 Mile Range, 22500 miles/yr`<br/>  - `Pickup, 300 Mile Range, 1000 miles/yr`<br/>  - `Pickup, 300 Mile Range, 3000 miles/yr`<br/>  - `Pickup, 300 Mile Range, 5000 miles/yr`<br/>  - `Pickup, 300 Mile Range, 7000 miles/yr`<br/>  - `Pickup, 300 Mile Range, 9000 miles/yr`<br/>  - `Pickup, 300 Mile Range, 11000 miles/yr`<br/>  - `Pickup, 300 Mile Range, 13000 miles/yr`<br/>  - `Pickup, 300 Mile Range, 15000 miles/yr`<br/>  - `Pickup, 300 Mile Range, 17000 miles/yr`<br/>  - `Pickup, 300 Mile Range, 19000 miles/yr`<br/>  - `Pickup, 300 Mile Range, 22500 miles/yr`<br/>  - `SUV, 200 Mile Range, 1000 miles/yr`<br/>  - `SUV, 200 Mile Range, 3000 miles/yr`<br/>  - `SUV, 200 Mile Range, 5000 miles/yr`<br/>  - `SUV, 200 Mile Range, 7000 miles/yr`<br/>  - `SUV, 200 Mile Range, 9000 miles/yr`<br/>  - `SUV, 200 Mile Range, 11000 miles/yr`<br/>  - `SUV, 200 Mile Range, 13000 miles/yr`<br/>  - `SUV, 200 Mile Range, 15000 miles/yr`<br/>  - `SUV, 200 Mile Range, 17000 miles/yr`<br/>  - `SUV, 200 Mile Range, 19000 miles/yr`<br/>  - `SUV, 200 Mile Range, 22500 miles/yr`<br/>  - `SUV, 300 Mile Range, 1000 miles/yr`<br/>  - `SUV, 300 Mile Range, 3000 miles/yr`<br/>  - `SUV, 300 Mile Range, 5000 miles/yr`<br/>  - `SUV, 300 Mile Range, 7000 miles/yr`<br/>  - `SUV, 300 Mile Range, 9000 miles/yr`<br/>  - `SUV, 300 Mile Range, 11000 miles/yr`<br/>  - `SUV, 300 Mile Range, 13000 miles/yr`<br/>  - `SUV, 300 Mile Range, 15000 miles/yr`<br/>  - `SUV, 300 Mile Range, 17000 miles/yr`<br/>  - `SUV, 300 Mile Range, 19000 miles/yr`<br/>  - `SUV, 300 Mile Range, 22500 miles/yr`<br/>  - `Detailed Example: 100 kWh battery, 0.25 kWh/mile`<br/>  - `Detailed Example: 100 kWh battery, 4.0 miles/kWh`<br/>  - `Detailed Example: 100 kWh battery, 135.0 mpge`


- **Default:** `None`

<br/>

**Electric Vehicle: Charger**

The type and usage of electric vehicle charger.

- **Name:** ``electric_vehicle_charger``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Level 1, 10% Charging at Home`<br/>  - `Level 1, 30% Charging at Home`<br/>  - `Level 1, 50% Charging at Home`<br/>  - `Level 1, 70% Charging at Home`<br/>  - `Level 1, 90% Charging at Home`<br/>  - `Level 1, 100% Charging at Home`<br/>  - `Level 2, 10% Charging at Home`<br/>  - `Level 2, 30% Charging at Home`<br/>  - `Level 2, 50% Charging at Home`<br/>  - `Level 2, 70% Charging at Home`<br/>  - `Level 2, 90% Charging at Home`<br/>  - `Level 2, 100% Charging at Home`<br/>  - `Detailed Example: Level 2, 7000 W, 75% Charging at Home`


- **Default:** `None`

<br/>

**Appliances: Clothes Washer**

The type and usage of clothes washer.

- **Name:** ``appliance_clothes_washer``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Standard, 2008-2017, 50% Usage`<br/>  - `Standard, 2008-2017, 75% Usage`<br/>  - `Standard, 2008-2017, 100% Usage`<br/>  - `Standard, 2008-2017, 150% Usage`<br/>  - `Standard, 2008-2017, 200% Usage`<br/>  - `Standard, 2018-present, 50% Usage`<br/>  - `Standard, 2018-present, 75% Usage`<br/>  - `Standard, 2018-present, 100% Usage`<br/>  - `Standard, 2018-present, 150% Usage`<br/>  - `Standard, 2018-present, 200% Usage`<br/>  - `EnergyStar, 2006-2017, 50% Usage`<br/>  - `EnergyStar, 2006-2017, 75% Usage`<br/>  - `EnergyStar, 2006-2017, 100% Usage`<br/>  - `EnergyStar, 2006-2017, 150% Usage`<br/>  - `EnergyStar, 2006-2017, 200% Usage`<br/>  - `EnergyStar, 2018-present, 50% Usage`<br/>  - `EnergyStar, 2018-present, 75% Usage`<br/>  - `EnergyStar, 2018-present, 100% Usage`<br/>  - `EnergyStar, 2018-present, 150% Usage`<br/>  - `EnergyStar, 2018-present, 200% Usage`<br/>  - `CEE Tier II, 2018, 50% Usage`<br/>  - `CEE Tier II, 2018, 75% Usage`<br/>  - `CEE Tier II, 2018, 100% Usage`<br/>  - `CEE Tier II, 2018, 150% Usage`<br/>  - `CEE Tier II, 2018, 200% Usage`<br/>  - `Detailed Example: ERI Reference 2006`<br/>  - `Detailed Example: MEF 1.65`<br/>  - `Detailed Example: Standard, 2008-2017, Conditioned Basement`<br/>  - `Detailed Example: Standard, 2008-2017, Unconditioned Basement`<br/>  - `Detailed Example: Standard, 2008-2017, Garage`


- **Default:** `Standard, 2008-2017, 100% Usage`

<br/>

**Appliances: Clothes Dryer**

The type and usage of clothes dryer.

- **Name:** ``appliance_clothes_dryer``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Electricity, Standard, 50% Usage`<br/>  - `Electricity, Standard, 75% Usage`<br/>  - `Electricity, Standard, 100% Usage`<br/>  - `Electricity, Standard, 150% Usage`<br/>  - `Electricity, Standard, 200% Usage`<br/>  - `Electricity, Premium, 50% Usage`<br/>  - `Electricity, Premium, 75% Usage`<br/>  - `Electricity, Premium, 100% Usage`<br/>  - `Electricity, Premium, 150% Usage`<br/>  - `Electricity, Premium, 200% Usage`<br/>  - `Electricity, Heat Pump, 50% Usage`<br/>  - `Electricity, Heat Pump, 75% Usage`<br/>  - `Electricity, Heat Pump, 100% Usage`<br/>  - `Electricity, Heat Pump, 150% Usage`<br/>  - `Electricity, Heat Pump, 200% Usage`<br/>  - `Natural Gas, Standard, 50% Usage`<br/>  - `Natural Gas, Standard, 75% Usage`<br/>  - `Natural Gas, Standard, 100% Usage`<br/>  - `Natural Gas, Standard, 150% Usage`<br/>  - `Natural Gas, Standard, 200% Usage`<br/>  - `Natural Gas, Premium, 50% Usage`<br/>  - `Natural Gas, Premium, 75% Usage`<br/>  - `Natural Gas, Premium, 100% Usage`<br/>  - `Natural Gas, Premium, 150% Usage`<br/>  - `Natural Gas, Premium, 200% Usage`<br/>  - `Propane, Standard, 50% Usage`<br/>  - `Propane, Standard, 75% Usage`<br/>  - `Propane, Standard, 100% Usage`<br/>  - `Propane, Standard, 150% Usage`<br/>  - `Propane, Standard, 200% Usage`<br/>  - `Detailed Example: Electricity, ERI Reference 2006`<br/>  - `Detailed Example: Natural Gas, ERI Reference 2006`<br/>  - `Detailed Example: Electricity, EF 4.29`<br/>  - `Detailed Example: Electricity, Standard, Conditioned Basement`<br/>  - `Detailed Example: Electricity, Standard, Unconditioned Basement`<br/>  - `Detailed Example: Electricity, Standard, Garage`


- **Default:** `Electricity, Standard, 100% Usage`

<br/>

**Appliances: Dishwasher**

The type and usage of dishwasher.

- **Name:** ``appliance_dishwasher``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Federal Minimum, Standard, 50% Usage`<br/>  - `Federal Minimum, Standard, 75% Usage`<br/>  - `Federal Minimum, Standard, 100% Usage`<br/>  - `Federal Minimum, Standard, 150% Usage`<br/>  - `Federal Minimum, Standard, 200% Usage`<br/>  - `EnergyStar, Standard, 50% Usage`<br/>  - `EnergyStar, Standard, 75% Usage`<br/>  - `EnergyStar, Standard, 100% Usage`<br/>  - `EnergyStar, Standard, 150% Usage`<br/>  - `EnergyStar, Standard, 200% Usage`<br/>  - `EnergyStar, Compact, 50% Usage`<br/>  - `EnergyStar, Compact, 75% Usage`<br/>  - `EnergyStar, Compact, 100% Usage`<br/>  - `EnergyStar, Compact, 150% Usage`<br/>  - `EnergyStar, Compact, 200% Usage`<br/>  - `Detailed Example: ERI Reference 2006`<br/>  - `Detailed Example: EF 0.7, Compact`<br/>  - `Detailed Example: Federal Minimum, Standard, Conditioned Basement`<br/>  - `Detailed Example: Federal Minimum, Standard, Unconditioned Basement`<br/>  - `Detailed Example: Federal Minimum, Standard, Garage`


- **Default:** `Federal Minimum, Standard, 100% Usage`

<br/>

**Appliances: Refrigerator**

The type and usage of refrigerator.

- **Name:** ``appliance_refrigerator``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `1139 kWh/yr, 90% Usage`<br/>  - `1139 kWh/yr, 100% Usage`<br/>  - `1139 kWh/yr, 110% Usage`<br/>  - `748 kWh/yr, 90% Usage`<br/>  - `748 kWh/yr, 100% Usage`<br/>  - `748 kWh/yr, 110% Usage`<br/>  - `727 kWh/yr, 90% Usage`<br/>  - `727 kWh/yr, 100% Usage`<br/>  - `727 kWh/yr, 110% Usage`<br/>  - `650 kWh/yr, 90% Usage`<br/>  - `650 kWh/yr, 100% Usage`<br/>  - `650 kWh/yr, 110% Usage`<br/>  - `574 kWh/yr, 90% Usage`<br/>  - `574 kWh/yr, 100% Usage`<br/>  - `574 kWh/yr, 110% Usage`<br/>  - `547 kWh/yr, 90% Usage`<br/>  - `547 kWh/yr, 100% Usage`<br/>  - `547 kWh/yr, 110% Usage`<br/>  - `480 kWh/yr, 90% Usage`<br/>  - `480 kWh/yr, 100% Usage`<br/>  - `480 kWh/yr, 110% Usage`<br/>  - `458 kWh/yr, 90% Usage`<br/>  - `458 kWh/yr, 100% Usage`<br/>  - `458 kWh/yr, 110% Usage`<br/>  - `434 kWh/yr, 90% Usage`<br/>  - `434 kWh/yr, 100% Usage`<br/>  - `434 kWh/yr, 110% Usage`<br/>  - `384 kWh/yr, 90% Usage`<br/>  - `384 kWh/yr, 100% Usage`<br/>  - `384 kWh/yr, 110% Usage`<br/>  - `348 kWh/yr, 90% Usage`<br/>  - `348 kWh/yr, 100% Usage`<br/>  - `348 kWh/yr, 110% Usage`<br/>  - `Detailed Example: ERI Reference 2006, 2-Bedroom Home`<br/>  - `Detailed Example: ERI Reference 2006, 3-Bedroom Home`<br/>  - `Detailed Example: ERI Reference 2006, 4-Bedroom Home`<br/>  - `Detailed Example: 650 kWh/yr, Conditioned Basement`<br/>  - `Detailed Example: 650 kWh/yr, Unconditioned Basement`<br/>  - `Detailed Example: 650 kWh/yr, Garage`


- **Default:** `434 kWh/yr, 100% Usage`

<br/>

**Appliances: Extra Refrigerator**

The type and usage of extra refrigerator.

- **Name:** ``appliance_extra_refrigerator``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `1139 kWh/yr, 90% Usage`<br/>  - `1139 kWh/yr, 100% Usage`<br/>  - `1139 kWh/yr, 110% Usage`<br/>  - `748 kWh/yr, 90% Usage`<br/>  - `748 kWh/yr, 100% Usage`<br/>  - `748 kWh/yr, 110% Usage`<br/>  - `727 kWh/yr, 90% Usage`<br/>  - `727 kWh/yr, 100% Usage`<br/>  - `727 kWh/yr, 110% Usage`<br/>  - `650 kWh/yr, 90% Usage`<br/>  - `650 kWh/yr, 100% Usage`<br/>  - `650 kWh/yr, 110% Usage`<br/>  - `574 kWh/yr, 90% Usage`<br/>  - `574 kWh/yr, 100% Usage`<br/>  - `574 kWh/yr, 110% Usage`<br/>  - `547 kWh/yr, 90% Usage`<br/>  - `547 kWh/yr, 100% Usage`<br/>  - `547 kWh/yr, 110% Usage`<br/>  - `480 kWh/yr, 90% Usage`<br/>  - `480 kWh/yr, 100% Usage`<br/>  - `480 kWh/yr, 110% Usage`<br/>  - `458 kWh/yr, 90% Usage`<br/>  - `458 kWh/yr, 100% Usage`<br/>  - `458 kWh/yr, 110% Usage`<br/>  - `434 kWh/yr, 90% Usage`<br/>  - `434 kWh/yr, 100% Usage`<br/>  - `434 kWh/yr, 110% Usage`<br/>  - `384 kWh/yr, 90% Usage`<br/>  - `384 kWh/yr, 100% Usage`<br/>  - `384 kWh/yr, 110% Usage`<br/>  - `348 kWh/yr, 90% Usage`<br/>  - `348 kWh/yr, 100% Usage`<br/>  - `348 kWh/yr, 110% Usage`<br/>  - `Detailed Example: 748 kWh/yr, Conditioned Basement`<br/>  - `Detailed Example: 748 kWh/yr, Unconditioned Basement`<br/>  - `Detailed Example: 748 kWh/yr, Garage`


- **Default:** `None`

<br/>

**Appliances: Freezer**

The type and usage of freezer.

- **Name:** ``appliance_freezer``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `935 kWh/yr, 90% Usage`<br/>  - `935 kWh/yr, 100% Usage`<br/>  - `935 kWh/yr, 110% Usage`<br/>  - `712 kWh/yr, 90% Usage`<br/>  - `712 kWh/yr, 100% Usage`<br/>  - `712 kWh/yr, 110% Usage`<br/>  - `641 kWh/yr, 90% Usage`<br/>  - `641 kWh/yr, 100% Usage`<br/>  - `641 kWh/yr, 110% Usage`<br/>  - `568 kWh/yr, 90% Usage`<br/>  - `568 kWh/yr, 100% Usage`<br/>  - `568 kWh/yr, 110% Usage`<br/>  - `417 kWh/yr, 90% Usage`<br/>  - `417 kWh/yr, 100% Usage`<br/>  - `417 kWh/yr, 110% Usage`<br/>  - `375 kWh/yr, 90% Usage`<br/>  - `375 kWh/yr, 100% Usage`<br/>  - `375 kWh/yr, 110% Usage`<br/>  - `354 kWh/yr, 90% Usage`<br/>  - `354 kWh/yr, 100% Usage`<br/>  - `354 kWh/yr, 110% Usage`<br/>  - `Detailed Example: 712 kWh/yr, Conditioned Basement`<br/>  - `Detailed Example: 712 kWh/yr, Unconditioned Basement`<br/>  - `Detailed Example: 712 kWh/yr, Garage`


- **Default:** `None`

<br/>

**Appliances: Cooking Range/Oven**

The type and usage of cooking range/oven.

- **Name:** ``appliance_cooking_range_oven``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Electricity, Standard, Non-Convection, 50% Usage`<br/>  - `Electricity, Standard, Non-Convection, 75% Usage`<br/>  - `Electricity, Standard, Non-Convection, 100% Usage`<br/>  - `Electricity, Standard, Non-Convection, 150% Usage`<br/>  - `Electricity, Standard, Non-Convection, 200% Usage`<br/>  - `Electricity, Standard, Convection, 50% Usage`<br/>  - `Electricity, Standard, Convection, 75% Usage`<br/>  - `Electricity, Standard, Convection, 100% Usage`<br/>  - `Electricity, Standard, Convection, 150% Usage`<br/>  - `Electricity, Standard, Convection, 200% Usage`<br/>  - `Electricity, Induction, Non-Convection, 50% Usage`<br/>  - `Electricity, Induction, Non-Convection, 75% Usage`<br/>  - `Electricity, Induction, Non-Convection, 100% Usage`<br/>  - `Electricity, Induction, Non-Convection, 150% Usage`<br/>  - `Electricity, Induction, Non-Convection, 200% Usage`<br/>  - `Electricity, Induction, Convection, 50% Usage`<br/>  - `Electricity, Induction, Convection, 75% Usage`<br/>  - `Electricity, Induction, Convection, 100% Usage`<br/>  - `Electricity, Induction, Convection, 150% Usage`<br/>  - `Electricity, Induction, Convection, 200% Usage`<br/>  - `Natural Gas, Non-Convection, 50% Usage`<br/>  - `Natural Gas, Non-Convection, 75% Usage`<br/>  - `Natural Gas, Non-Convection, 100% Usage`<br/>  - `Natural Gas, Non-Convection, 150% Usage`<br/>  - `Natural Gas, Non-Convection, 200% Usage`<br/>  - `Natural Gas, Convection, 50% Usage`<br/>  - `Natural Gas, Convection, 75% Usage`<br/>  - `Natural Gas, Convection, 100% Usage`<br/>  - `Natural Gas, Convection, 150% Usage`<br/>  - `Natural Gas, Convection, 200% Usage`<br/>  - `Propane, Non-Convection, 50% Usage`<br/>  - `Propane, Non-Convection, 75% Usage`<br/>  - `Propane, Non-Convection, 100% Usage`<br/>  - `Propane, Non-Convection, 150% Usage`<br/>  - `Propane, Non-Convection, 200% Usage`<br/>  - `Propane, Convection, 50% Usage`<br/>  - `Propane, Convection, 75% Usage`<br/>  - `Propane, Convection, 100% Usage`<br/>  - `Propane, Convection, 150% Usage`<br/>  - `Propane, Convection, 200% Usage`<br/>  - `Detailed Example: Electricity, Standard, Non-Convection, Conditioned Basement`<br/>  - `Detailed Example: Electricity, Standard, Non-Convection, Unconditioned Basement`<br/>  - `Detailed Example: Electricity, Standard, Non-Convection, Garage`


- **Default:** `Electricity, Standard, Non-Convection, 100% Usage`

<br/>

**Appliances: Dehumidifier**

The type of dehumidifier.

- **Name:** ``appliance_dehumidifier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Portable, 15 pints/day`<br/>  - `Portable, 20 pints/day`<br/>  - `Portable, 30 pints/day`<br/>  - `Portable, 40 pints/day`<br/>  - `Whole-Home, 60 pints/day`<br/>  - `Whole-Home, 75 pints/day`<br/>  - `Whole-Home, 95 pints/day`<br/>  - `Whole-Home, 125 pints/day`<br/>  - `Detailed Example: Portable, 40 pints/day, EF 1.8`<br/>  - `Detailed Example: Whole-Home, 60 pints/day, EF 2.3`<br/>  - `Detailed Example: Portable, 40 pints/day, IEF 1.4`


- **Default:** `None`

<br/>

**Appliances: Dehumidifier Setpoint**

The dehumidifier's relative humidity (RH) setpoint.

- **Name:** ``appliance_dehumidifier_setpoint``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `40% RH`<br/>  - `45% RH`<br/>  - `50% RH`<br/>  - `55% RH`<br/>  - `60% RH`<br/>  - `65% RH`


- **Default:** `50% RH`

<br/>

**Lighting**

The type and usage of interior, exterior, and garage lighting.

- **Name:** ``lighting``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `100% Incandescent, 50% Usage`<br/>  - `100% Incandescent, 75% Usage`<br/>  - `100% Incandescent, 100% Usage`<br/>  - `100% Incandescent, 150% Usage`<br/>  - `100% Incandescent, 200% Usage`<br/>  - `25% LED, 50% Usage`<br/>  - `25% LED, 75% Usage`<br/>  - `25% LED, 100% Usage`<br/>  - `25% LED, 150% Usage`<br/>  - `25% LED, 200% Usage`<br/>  - `50% LED, 50% Usage`<br/>  - `50% LED, 75% Usage`<br/>  - `50% LED, 100% Usage`<br/>  - `50% LED, 150% Usage`<br/>  - `50% LED, 200% Usage`<br/>  - `75% LED, 50% Usage`<br/>  - `75% LED, 75% Usage`<br/>  - `75% LED, 100% Usage`<br/>  - `75% LED, 150% Usage`<br/>  - `75% LED, 200% Usage`<br/>  - `100% LED, 50% Usage`<br/>  - `100% LED, 75% Usage`<br/>  - `100% LED, 100% Usage`<br/>  - `100% LED, 150% Usage`<br/>  - `100% LED, 200% Usage`<br/>  - `25% CFL, 50% Usage`<br/>  - `25% CFL, 75% Usage`<br/>  - `25% CFL, 100% Usage`<br/>  - `25% CFL, 150% Usage`<br/>  - `25% CFL, 200% Usage`<br/>  - `50% CFL, 50% Usage`<br/>  - `50% CFL, 75% Usage`<br/>  - `50% CFL, 100% Usage`<br/>  - `50% CFL, 150% Usage`<br/>  - `50% CFL, 200% Usage`<br/>  - `75% CFL, 50% Usage`<br/>  - `75% CFL, 75% Usage`<br/>  - `75% CFL, 100% Usage`<br/>  - `75% CFL, 150% Usage`<br/>  - `75% CFL, 200% Usage`<br/>  - `100% CFL, 50% Usage`<br/>  - `100% CFL, 75% Usage`<br/>  - `100% CFL, 100% Usage`<br/>  - `100% CFL, 150% Usage`<br/>  - `100% CFL, 200% Usage`<br/>  - `Detailed Example: 10% CFL`<br/>  - `Detailed Example: 40% CFL, 10% LFL, 25% LED`


- **Default:** `50% LED, 100% Usage`

<br/>

**Ceiling Fans**

The type of ceiling fans.

- **Name:** ``ceiling_fans``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `NumBedrooms+1 Fans, 45.0 W`<br/>  - `NumBedrooms+1 Fans, 37.5 W`<br/>  - `NumBedrooms+1 Fans, 30.0 W`<br/>  - `NumBedrooms+1 Fans, 22.5 W`<br/>  - `NumBedrooms+1 Fans, 15.0 W`<br/>  - `1 Fan, 45.0 W`<br/>  - `1 Fan, 37.5 W`<br/>  - `1 Fan, 30.0 W`<br/>  - `1 Fan, 22.5 W`<br/>  - `1 Fan, 15.0 W`<br/>  - `2 Fans, 45.0 W`<br/>  - `2 Fans, 37.5 W`<br/>  - `2 Fans, 30.0 W`<br/>  - `2 Fans, 22.5 W`<br/>  - `2 Fans, 15.0 W`<br/>  - `3 Fans, 45.0 W`<br/>  - `3 Fans, 37.5 W`<br/>  - `3 Fans, 30.0 W`<br/>  - `3 Fans, 22.5 W`<br/>  - `3 Fans, 15.0 W`<br/>  - `4 Fans, 45.0 W`<br/>  - `4 Fans, 37.5 W`<br/>  - `4 Fans, 30.0 W`<br/>  - `4 Fans, 22.5 W`<br/>  - `4 Fans, 15.0 W`<br/>  - `5 Fans, 45.0 W`<br/>  - `5 Fans, 37.5 W`<br/>  - `5 Fans, 30.0 W`<br/>  - `5 Fans, 22.5 W`<br/>  - `5 Fans, 15.0 W`<br/>  - `Detailed Example: 4 Fans, 39 W, 0.5 deg-F Setpoint Offset`<br/>  - `Detailed Example: 4 Fans, 100 cfm/W, 0.5 deg-F Setpoint Offset`


- **Default:** `None`

<br/>

**Misc: Television**

The amount of television usage, relative to the national average.

- **Name:** ``misc_television``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `25% Usage`<br/>  - `33% Usage`<br/>  - `50% Usage`<br/>  - `75% Usage`<br/>  - `80% Usage`<br/>  - `90% Usage`<br/>  - `100% Usage`<br/>  - `110% Usage`<br/>  - `125% Usage`<br/>  - `150% Usage`<br/>  - `200% Usage`<br/>  - `300% Usage`<br/>  - `400% Usage`<br/>  - `Detailed Example: 620 kWh/yr`


- **Default:** `100% Usage`

<br/>

**Misc: Plug Loads**

The amount of additional plug load usage, relative to the national average.

- **Name:** ``misc_plug_loads``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `25% Usage`<br/>  - `33% Usage`<br/>  - `50% Usage`<br/>  - `75% Usage`<br/>  - `80% Usage`<br/>  - `90% Usage`<br/>  - `100% Usage`<br/>  - `110% Usage`<br/>  - `125% Usage`<br/>  - `150% Usage`<br/>  - `200% Usage`<br/>  - `300% Usage`<br/>  - `400% Usage`<br/>  - `Detailed Example: 2457 kWh/yr, 85.5% Sensible, 4.5% Latent`<br/>  - `Detailed Example: 7302 kWh/yr, 82.2% Sensible, 17.8% Latent`


- **Default:** `100% Usage`

<br/>

**Misc: Well Pump**

The amount of well pump usage, relative to the national average.

- **Name:** ``misc_well_pump``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Typical Efficiency`<br/>  - `High Efficiency`<br/>  - `Detailed Example: 475 kWh/yr`


- **Default:** `None`

<br/>

**Misc: Electric Vehicle Charging**

The amount of EV charging usage, relative to the national average. Only use this if a detailed EV & EV charger were not otherwise specified.

- **Name:** ``misc_electric_vehicle_charging``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `25% Usage`<br/>  - `33% Usage`<br/>  - `50% Usage`<br/>  - `75% Usage`<br/>  - `80% Usage`<br/>  - `90% Usage`<br/>  - `100% Usage`<br/>  - `110% Usage`<br/>  - `125% Usage`<br/>  - `150% Usage`<br/>  - `200% Usage`<br/>  - `300% Usage`<br/>  - `400% Usage`<br/>  - `Detailed Example: 1500 kWh/yr`<br/>  - `Detailed Example: 3000 kWh/yr`


- **Default:** `None`

<br/>

**Misc: Gas Grill**

The amount of outdoor gas grill usage, relative to the national average.

- **Name:** ``misc_grill``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Natural Gas, 25% Usage`<br/>  - `Natural Gas, 50% Usage`<br/>  - `Natural Gas, 75% Usage`<br/>  - `Natural Gas, 100% Usage`<br/>  - `Natural Gas, 150% Usage`<br/>  - `Natural Gas, 200% Usage`<br/>  - `Natural Gas, 400% Usage`<br/>  - `Propane, 25% Usage`<br/>  - `Propane, 50% Usage`<br/>  - `Propane, 75% Usage`<br/>  - `Propane, 100% Usage`<br/>  - `Propane, 150% Usage`<br/>  - `Propane, 200% Usage`<br/>  - `Propane, 400% Usage`<br/>  - `Detailed Example: Propane, 25 therm/yr`


- **Default:** `None`

<br/>

**Misc: Gas Lighting**

The amount of gas lighting usage, relative to the national average.

- **Name:** ``misc_gas_lighting``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Natural Gas, 25% Usage`<br/>  - `Natural Gas, 50% Usage`<br/>  - `Natural Gas, 75% Usage`<br/>  - `Natural Gas, 100% Usage`<br/>  - `Natural Gas, 150% Usage`<br/>  - `Natural Gas, 200% Usage`<br/>  - `Natural Gas, 400% Usage`<br/>  - `Detailed Example: Natural Gas, 28 therm/yr`


- **Default:** `None`

<br/>

**Misc: Fireplace**

The amount of fireplace usage, relative to the national average. Fireplaces can also be specified as heating systems that meet a portion of the heating load.

- **Name:** ``misc_fireplace``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Natural Gas, 25% Usage`<br/>  - `Natural Gas, 50% Usage`<br/>  - `Natural Gas, 75% Usage`<br/>  - `Natural Gas, 100% Usage`<br/>  - `Natural Gas, 150% Usage`<br/>  - `Natural Gas, 200% Usage`<br/>  - `Natural Gas, 400% Usage`<br/>  - `Propane, 25% Usage`<br/>  - `Propane, 50% Usage`<br/>  - `Propane, 75% Usage`<br/>  - `Propane, 100% Usage`<br/>  - `Propane, 150% Usage`<br/>  - `Propane, 200% Usage`<br/>  - `Propane, 400% Usage`<br/>  - `Wood, 25% Usage`<br/>  - `Wood, 50% Usage`<br/>  - `Wood, 75% Usage`<br/>  - `Wood, 100% Usage`<br/>  - `Wood, 150% Usage`<br/>  - `Wood, 200% Usage`<br/>  - `Wood, 400% Usage`<br/>  - `Electric, 25% Usage`<br/>  - `Electric, 50% Usage`<br/>  - `Electric, 75% Usage`<br/>  - `Electric, 100% Usage`<br/>  - `Electric, 150% Usage`<br/>  - `Electric, 200% Usage`<br/>  - `Electric, 400% Usage`<br/>  - `Detailed Example: Wood, 55 therm/yr`


- **Default:** `None`

<br/>

**Misc: Pool**

The type of pool (pump & heater).

- **Name:** ``misc_pool``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Unheated, 25% Usage`<br/>  - `Unheated, 50% Usage`<br/>  - `Unheated, 75% Usage`<br/>  - `Unheated, 100% Usage`<br/>  - `Unheated, 150% Usage`<br/>  - `Unheated, 200% Usage`<br/>  - `Unheated, 400% Usage`<br/>  - `Electric Resistance Heater, 25% Usage`<br/>  - `Electric Resistance Heater, 50% Usage`<br/>  - `Electric Resistance Heater, 75% Usage`<br/>  - `Electric Resistance Heater, 100% Usage`<br/>  - `Electric Resistance Heater, 150% Usage`<br/>  - `Electric Resistance Heater, 200% Usage`<br/>  - `Electric Resistance Heater, 400% Usage`<br/>  - `Heat Pump Heater, 25% Usage`<br/>  - `Heat Pump Heater, 50% Usage`<br/>  - `Heat Pump Heater, 75% Usage`<br/>  - `Heat Pump Heater, 100% Usage`<br/>  - `Heat Pump Heater, 150% Usage`<br/>  - `Heat Pump Heater, 200% Usage`<br/>  - `Heat Pump Heater, 400% Usage`<br/>  - `Natural Gas Heater, 25% Usage`<br/>  - `Natural Gas Heater, 50% Usage`<br/>  - `Natural Gas Heater, 75% Usage`<br/>  - `Natural Gas Heater, 100% Usage`<br/>  - `Natural Gas Heater, 150% Usage`<br/>  - `Natural Gas Heater, 200% Usage`<br/>  - `Natural Gas Heater, 400% Usage`<br/>  - `Detailed Example: 2700 kWh/yr Pump, Unheated`<br/>  - `Detailed Example: 2700 kWh/yr Pump, 500 therms/yr Natural Gas Heater`


- **Default:** `None`

<br/>

**Misc: Permanent Spa**

The type of permanent spa (pump & heater).

- **Name:** ``misc_permanent_spa``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Unheated, 25% Usage`<br/>  - `Unheated, 50% Usage`<br/>  - `Unheated, 75% Usage`<br/>  - `Unheated, 100% Usage`<br/>  - `Unheated, 150% Usage`<br/>  - `Unheated, 200% Usage`<br/>  - `Unheated, 400% Usage`<br/>  - `Electric Resistance Heater, 25% Usage`<br/>  - `Electric Resistance Heater, 50% Usage`<br/>  - `Electric Resistance Heater, 75% Usage`<br/>  - `Electric Resistance Heater, 100% Usage`<br/>  - `Electric Resistance Heater, 150% Usage`<br/>  - `Electric Resistance Heater, 200% Usage`<br/>  - `Electric Resistance Heater, 400% Usage`<br/>  - `Heat Pump Heater, 25% Usage`<br/>  - `Heat Pump Heater, 50% Usage`<br/>  - `Heat Pump Heater, 75% Usage`<br/>  - `Heat Pump Heater, 100% Usage`<br/>  - `Heat Pump Heater, 150% Usage`<br/>  - `Heat Pump Heater, 200% Usage`<br/>  - `Heat Pump Heater, 400% Usage`<br/>  - `Natural Gas Heater, 25% Usage`<br/>  - `Natural Gas Heater, 50% Usage`<br/>  - `Natural Gas Heater, 75% Usage`<br/>  - `Natural Gas Heater, 100% Usage`<br/>  - `Natural Gas Heater, 150% Usage`<br/>  - `Natural Gas Heater, 200% Usage`<br/>  - `Natural Gas Heater, 400% Usage`<br/>  - `Detailed Example: 1000 kWh/yr Pump, 1300 kWh/yr Electric Resistance Heater`<br/>  - `Detailed Example: 1000 kWh/yr Pump, 260 kWh/yr Heat Pump Heater`


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

- **Choices:** <br/>  - `None`<br/>  - `Temperature Capacitance Multiplier, 1`<br/>  - `Temperature Capacitance Multiplier, 4`<br/>  - `Temperature Capacitance Multiplier, 10`<br/>  - `Temperature Capacitance Multiplier, 15`<br/>  - `On/Off Thermostat Deadband, 1F`<br/>  - `On/Off Thermostat Deadband, 2F`<br/>  - `On/Off Thermostat Deadband, 3F`<br/>  - `Heat Pump Backup Staging, 5 kW`<br/>  - `Heat Pump Backup Staging, 10 kW`<br/>  - `Experimental Ground-to-Air Heat Pump Model`<br/>  - `HVAC Allow Increased Fixed Capacities`


- **Default:** `None`

<br/>

**Advanced Feature 2**

Select a second advanced research feature to use in the model, if desired.

- **Name:** ``advanced_feature_2``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Temperature Capacitance Multiplier, 1`<br/>  - `Temperature Capacitance Multiplier, 4`<br/>  - `Temperature Capacitance Multiplier, 10`<br/>  - `Temperature Capacitance Multiplier, 15`<br/>  - `On/Off Thermostat Deadband, 1F`<br/>  - `On/Off Thermostat Deadband, 2F`<br/>  - `On/Off Thermostat Deadband, 3F`<br/>  - `Heat Pump Backup Staging, 5 kW`<br/>  - `Heat Pump Backup Staging, 10 kW`<br/>  - `Experimental Ground-to-Air Heat Pump Model`<br/>  - `HVAC Allow Increased Fixed Capacities`


- **Default:** `None`

<br/>

**Utility Bill Scenario**

The type of utility bill calculations to perform.

- **Name:** ``utility_bill_scenario``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Default (EIA Average Rates)`<br/>  - `Detailed Example: $0.12/kWh, $1.1/therm, $12/month`<br/>  - `Detailed Example: Sample Tiered Rate`<br/>  - `Detailed Example: Sample Time-of-Use Rate`<br/>  - `Detailed Example: Sample Tiered and Time-of-Use Rate`<br/>  - `Detailed Example: Sample Real-Time Pricing`<br/>  - `Detailed Example: Net Metering w/ Wholesale Excess Rate`<br/>  - `Detailed Example: Net Metering w/ Retail Excess Rate`<br/>  - `Detailed Example: Feed-in Tariff`


- **Default:** `Default (EIA Average Rates)`

<br/>

**Utility Bill Scenario 2**

The second type of utility bill calculations to perform, if desired.

- **Name:** ``utility_bill_scenario_2``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Default (EIA Average Rates)`<br/>  - `Detailed Example: $0.12/kWh, $1.1/therm, $12/month`<br/>  - `Detailed Example: Sample Tiered Rate`<br/>  - `Detailed Example: Sample Time-of-Use Rate`<br/>  - `Detailed Example: Sample Tiered and Time-of-Use Rate`<br/>  - `Detailed Example: Sample Real-Time Pricing`<br/>  - `Detailed Example: Net Metering w/ Wholesale Excess Rate`<br/>  - `Detailed Example: Net Metering w/ Retail Excess Rate`<br/>  - `Detailed Example: Feed-in Tariff`


- **Default:** `None`

<br/>

**Utility Bill Scenario 3**

The third type of utility bill calculations to perform, if desired.

- **Name:** ``utility_bill_scenario_3``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** <br/>  - `None`<br/>  - `Default (EIA Average Rates)`<br/>  - `Detailed Example: $0.12/kWh, $1.1/therm, $12/month`<br/>  - `Detailed Example: Sample Tiered Rate`<br/>  - `Detailed Example: Sample Time-of-Use Rate`<br/>  - `Detailed Example: Sample Tiered and Time-of-Use Rate`<br/>  - `Detailed Example: Sample Real-Time Pricing`<br/>  - `Detailed Example: Net Metering w/ Wholesale Excess Rate`<br/>  - `Detailed Example: Net Metering w/ Retail Excess Rate`<br/>  - `Detailed Example: Feed-in Tariff`


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





