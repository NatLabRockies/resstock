.. _housing_characteristics:

Housing Characteristics
=======================

Each parameter sampled by the national project is listed alphabetically as its own subsection below.
For each parameter, the following (if applicable) are reported based on the contents of the `source_report.csv <https://github.com/NREL/resstock/blob/develop/project_national/resources/source_report.csv>`_:

- **Description**
- **Created by**
- **Source**
- **Assumption**

For each parameter an **Options** table is populated based on the contents of the `options_lookup.tsv <https://github.com/NREL/resstock/blob/develop/resources/options_lookup.tsv>`_, `options_saturations.csv <https://github.com/NREL/resstock/blob/develop/project_national/resources/options_saturations.csv>`_, and `BuildResidentialHPXML/resources/options/*.tsv <https://github.com/NREL/resstock/blob/develop/resources/hpxml-measures/BuildResidentialHPXML/resources/options>`_ files.

For each parameter a **Properties** table is populated (if applicable) based on the contents of `BuildResidentialHPXML/resources/options/*.tsv <https://github.com/NREL/resstock/blob/develop/resources/hpxml-measures/BuildResidentialHPXML/resources/options>`_ files, each containing the following columns:

- **Name** [#]_
- **Units**
- **Description**

.. [#] Each **Name** entry is an argument that is assigned using defined options from the `options_lookup.tsv <https://github.com/NREL/resstock/blob/develop/resources/options_lookup.tsv>`_.

.. _ahs_region:

AHS Region
----------

Description
***********

The American Housing Survey region that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \Core Based Statistical Area (CBSA) data based on the Feb 2013 CBSA delineation file.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **AHS Region** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - CBSA Atlanta-Sandy Springs-Roswell, GA
     - CBSA Boston-Cambridge-Newton, MA-NH
     - CBSA Chicago-Naperville-Elgin, IL-IN-WI
     - CBSA Dallas-Fort Worth-Arlington, TX
     - CBSA Detroit-Warren-Dearborn, MI
     - CBSA Houston-The Woodlands-Sugar Land, TX
     - CBSA Los Angeles-Long Beach-Anaheim, CA
     - CBSA Miami-Fort Lauderdale-West Palm Beach, FL
     - CBSA New York-Newark-Jersey City, NY-NJ-PA
     - CBSA Philadelphia-Camden-Wilmington, PA-NJ-DE-MD
     - CBSA Phoenix-Mesa-Scottsdale, AZ
     - CBSA Riverside-San Bernardino-Ontario, CA
     - CBSA San Francisco-Oakland-Hayward, CA
     - CBSA Seattle-Tacoma-Bellevue, WA
     - CBSA Washington-Arlington-Alexandria, DC-VA-MD-WV
     - Non-CBSA East North Central
     - Non-CBSA East South Central
     - Non-CBSA Middle Atlantic
     - Non-CBSA Mountain
     - Non-CBSA New England
     - Non-CBSA Pacific
     - Non-CBSA South Atlantic
     - Non-CBSA West North Central
     - Non-CBSA West South Central
   * - Stock saturation
     - 1.7%
     - 1.4%
     - 2.8%
     - 2%
     - 1.4%
     - 1.8%
     - 3.4%
     - 1.9%
     - 5.9%
     - 1.8%
     - 1.4%
     - 1.1%
     - 1.3%
     - 1.1%
     - 1.7%
     - 11%
     - 6.2%
     - 5.5%
     - 5.9%
     - 3.4%
     - 7.5%
     - 15%
     - 6.9%
     - 7.8%

.. _aiannh_area:

AIANNH Area
-----------

Description
***********

American Indian/Alaska Native/Native Hawaiian Area that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \2010 Census Tract to American Indian Area (AIA) Relationship File provides percent housing unit in tract that belongs to AIA.Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


Assumption
**********

- \(2010) Tract is mapped to (2015) County and PUMA by adjusting for known geographic changes (e.g., renaming of Shannon County to Oglala Lakota County, SD) However, Tract=G3600530940103 (Oneida city, Madison County, NY) could not be mapped to County and PUMA and was removed. The tract contains only 11 units for AIA.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **AIANNH Area** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - No
     - Yes
   * - Stock saturation
     - 98%
     - 1.6%

.. _ashrae_iecc_climate_zone_2004:

ASHRAE IECC Climate Zone 2004
-----------------------------

Description
***********

Climate zone according to ASHRAE 169 in 2004 and IECC in 2012 that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \Climate zone data are from ASHRAE 169 2006, IECC 2012, and M.C. Baechler 2015.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **ASHRAE IECC Climate Zone 2004** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 1A
     - 2A
     - 2B
     - 3A
     - 3B
     - 3C
     - 4A
     - 4B
     - 4C
     - 5A
     - 5B
     - 6A
     - 6B
     - 7A
     - 7AK
     - 7B
     - 8AK
   * - Stock saturation
     - 1.8%
     - 12%
     - 2%
     - 13%
     - 9.3%
     - 2.3%
     - 22%
     - 0.77%
     - 2.9%
     - 23%
     - 3.8%
     - 6.1%
     - 0.92%
     - 0.79%
     - 0.18%
     - 0.11%
     - 0.052%
   * - ``site_iecc_zone``
     - 1A
     - 2A
     - 2B
     - 3A
     - 3B
     - 3C
     - 4A
     - 4B
     - 4C
     - 5A
     - 5B
     - 6A
     - 6B
     - 7
     - 7
     - 7
     - 8

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``site_iecc_zone``
     - 
     - IECC zone of the home address.
.. _ashrae_iecc_climate_zone_2004___sub_cz_split:

ASHRAE IECC Climate Zone 2004 - Sub-CZ Split
--------------------------------------------

Description
***********

Climate zone according to ASHRAE 169 in 2004 and IECC in 2012 that the sample is located. Climate zone where climate zone 2A is split between counties in TX, LA and FL, GA, AL, and MSClimate zone where climate zone 1A is split between counties in FL and HI

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \Climate zone data are from ASHRAE 169 2006, IECC 2012, and M.C. Baechler 2015.


Assumption
**********

- \This characteristic is used to better represent HVAC types in the 2A climate zone.This characteristic is used to better represent partial conditioning in the 1A climate zone.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **ASHRAE IECC Climate Zone 2004 - Sub-CZ Split** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 1A - FL
     - 1A - HI
     - 2A - FL, GA, AL, MS
     - 2A - TX, LA
     - 2B
     - 3A
     - 3B
     - 3C
     - 4A
     - 4B
     - 4C
     - 5A
     - 5B
     - 6A
     - 6B
     - 7A
     - 7AK
     - 7B
     - 8AK
   * - Stock saturation
     - 1.4%
     - 0.4%
     - 6.2%
     - 5.4%
     - 2%
     - 13%
     - 9.3%
     - 2.3%
     - 22%
     - 0.77%
     - 2.9%
     - 23%
     - 3.8%
     - 6.1%
     - 0.92%
     - 0.79%
     - 0.18%
     - 0.11%
     - 0.052%

.. _area_median_income:

Area Median Income
------------------

Description
***********

Area median income of the household occupying the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \% Area Median Income is calculated using annual household income in 2019USD (continuous, not binned) from 2019-5yrs PUMS data and 2019 Income Limits from HUD. These limits adjust for household size AND local housing costs (AKA Fair Market Rents). Income Limits reported at county subdivisions are consolidated to County using a crosswalk generated from Missouri Census Data Center's geocorr (2014), which has 2010 ACS housing unit count. For the 478 counties available in PUMS (60%), the county-level Income Limits are used. For all others (40%), PUMA-level Income Limits are used, which are converted from county-level using the spatial_tract_lookup file containing 2010 ACS housing unit count.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Area Median Income** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0-30%
     - 30-60%
     - 60-80%
     - 80-100%
     - 100-120%
     - 120-150%
     - 150%+
     - Not Available
   * - Stock saturation
     - 13%
     - 14%
     - 9.7%
     - 9.4%
     - 7.9%
     - 9.5%
     - 24%
     - 12%

.. _bathroom_spot_vent_hour:

Bathroom Spot Vent Hour
-----------------------

Description
***********

Bathroom spot ventilation daily start hour

Created by
**********

manually created

Source
******

- \Same as occupancy schedule from Wilson et al. 'Building America House Simulation Protocols' 2014


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Bathroom Spot Vent Hour** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Hour0
     - Hour1
     - Hour2
     - Hour3
     - Hour4
     - Hour5
     - Hour6
     - Hour7
     - Hour8
     - Hour9
     - Hour10
     - Hour11
     - Hour12
     - Hour13
     - Hour14
     - Hour15
     - Hour16
     - Hour17
     - Hour18
     - Hour19
     - Hour20
     - Hour21
     - Hour22
     - Hour23
   * - Stock saturation
     - 6.1%
     - 6.1%
     - 6.1%
     - 6.1%
     - 6.1%
     - 6.1%
     - 6.1%
     - 5.3%
     - 2.5%
     - 1.5%
     - 1.5%
     - 1.5%
     - 1.5%
     - 1.5%
     - 1.5%
     - 1.5%
     - 1.8%
     - 3.3%
     - 5.4%
     - 5.4%
     - 5.4%
     - 6.1%
     - 6.1%
     - 6.1%
   * - ``bathroom_fans_start_hour``
     - 0
     - 1
     - 2
     - 3
     - 4
     - 5
     - 6
     - 7
     - 8
     - 9
     - 10
     - 11
     - 12
     - 13
     - 14
     - 15
     - 16
     - 17
     - 18
     - 19
     - 20
     - 21
     - 22
     - 23

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``bathroom_fans_start_hour``
     - 
     - The hour of the day when the bathroom fans run.
.. _battery:

Battery
-------

Description
***********

The size of an onsite battery (not modeled in project_national).

Created by
**********

manually created

Source
******

- \n/a


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Battery** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - 10 kWh
     - 20 kWh
   * - Stock saturation
     - 100%
     - 0%
     - 0%
   * - ``battery_nominal_capacity``
     - 
     - 10.0
     - 20.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``battery_nominal_capacity``
     - kWh
     - The battery's nominal (total) capacity.
.. _bedrooms:

Bedrooms
--------

Description
***********

The number of bedrooms in the dwelling unit.

Created by
**********

``sources/ahs/ahs2017_2019/tsv_maker.py``

Source
******

- \2017 and 2019 American Housing Survey (AHS) microdata.

- \Building type categorization based on U.S. EIA 2009 Residential Energy Consumption Survey (RECS).


Assumption
**********

- \More than 5 bedrooms are labeled as 5 bedrooms and 0 bedrooms are labeled as 1 bedroom

- \Limit 0-499 sqft dwelling units to only 1 or 2 bedrooms. The geometry measure has a limit of (ffa-120)/70 >= bedrooms.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Bedrooms** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 1
     - 2
     - 3
     - 4
     - 5
   * - Stock saturation
     - 13%
     - 27%
     - 39%
     - 17%
     - 4.7%
   * - ``geometry_unit_num_bedrooms_number``
     - 1
     - 2
     - 3
     - 4
     - 5

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_unit_num_bedrooms_number``
     - 
     - Number of bedrooms.
.. _building_america_climate_zone:

Building America Climate Zone
-----------------------------

Description
***********

The Building America Climate Zone that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Unit counts are from the American Community Survey 5-yr 2016.

- \Spatial definitions are from U.S. Census 2010.

- \Climate zone data are from ASHRAE 169 2006, IECC 2012, and M.C. Baechler 2015.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Building America Climate Zone** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Cold
     - Hot-Dry
     - Hot-Humid
     - Marine
     - Mixed-Dry
     - Mixed-Humid
     - Subarctic
     - Very Cold
   * - Stock saturation
     - 33%
     - 11%
     - 18%
     - 5.2%
     - 0.76%
     - 30%
     - 0.052%
     - 1.1%

.. _cec_climate_zone:

CEC Climate Zone
----------------

Description
***********

The California Energy Commission Climate Zone that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Zip code definitions are from the end of Q2 2020

- \The climate zone to zip codes in California is from the California Energy Commission Website.


Assumption
**********

- \CEC Climate zones are defined by Zip Codes.

- \The dependency selected is County and PUMA as zip codes are not modeled in ResStock.

- \The mapping between Census Tracts and Zip Codes are approximate and some discrepancies may exist.

- \If the sample is outside California, the option is set to None.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **CEC Climate Zone** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 1
     - 2
     - 3
     - 4
     - 5
     - 6
     - 7
     - 8
     - 9
     - 10
     - 11
     - 12
     - 13
     - 14
     - 15
     - 16
     - None
   * - Stock saturation
     - 0.065%
     - 0.3%
     - 1.2%
     - 0.54%
     - 0.11%
     - 0.87%
     - 0.63%
     - 1.1%
     - 1.6%
     - 0.99%
     - 0.34%
     - 1.3%
     - 0.58%
     - 0.26%
     - 0.24%
     - 0.24%
     - 90%

.. _ceiling_fan:

Ceiling Fan
-----------

Description
***********

Presence and energy usage of ceiling fans at medium speed

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014, national average used as saturation


Assumption
**********

- \If the unit is vacant there is no ceiling fan energy


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Ceiling Fan** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - Standard Efficiency
     - Standard Efficiency, No usage
   * - Stock saturation
     - 28%
     - 63%
     - 8.7%
   * - ``ceiling_fans_label_energy_use``
     - 
     - 45.0
     - 
   * - ``ceiling_fans_count``
     - 0
     - 
     - 0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``ceiling_fans_label_energy_use``
     - W
     - The average energy use of the ceiling fan(s), as found on the label.
   * - ``ceiling_fans_count``
     - #
     - Total number of ceiling fans.
.. _census_division:

Census Division
---------------

Description
***********

The U.S. Census Division that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Census Division** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - East North Central
     - East South Central
     - Middle Atlantic
     - Mountain
     - New England
     - Pacific
     - South Atlantic
     - West North Central
     - West South Central
   * - Stock saturation
     - 15%
     - 6.2%
     - 13%
     - 7.3%
     - 4.8%
     - 14%
     - 20%
     - 6.9%
     - 12%

.. _census_division_recs:

Census Division RECS
--------------------

Description
***********

Census Division as used in RECS 2015 that the sample is located. RECS 2015 splits the Mountain Census Division into north (CO, ID, MT, UT, WY) and south (AZ, NM, NV).

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \U.S. EIA 2015 Residential Energy Consumption Survey (RECS) codebook.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Census Division RECS** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - East North Central
     - East South Central
     - Middle Atlantic
     - Mountain North
     - Mountain South
     - New England
     - Pacific
     - South Atlantic
     - West North Central
     - West South Central
   * - Stock saturation
     - 15%
     - 6.2%
     - 13%
     - 3.5%
     - 3.7%
     - 4.8%
     - 14%
     - 20%
     - 6.9%
     - 12%

.. _census_region:

Census Region
-------------

Description
***********

The U.S. Census Region that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Census Region** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Midwest
     - Northeast
     - South
     - West
   * - Stock saturation
     - 22%
     - 18%
     - 38%
     - 22%

.. _city:

City
----

Description
***********

The City that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Cities are defined by Census blocks by their Census Place in the 2010 Census.

- \Unit counts are from the American Community Survey 5-yr 2016.


Assumption
**********

- \2020 Decennial Redistricting data was used to map tract level unit counts to census blocks.

- \1,099 cities are tagged in ResStock, but there are over 29,000 Places in the Census data.

- \The threshold for including a Census Place in the City.tsv is 15,000 dwelling units.

- \The value 'In another census Place' designates the fraction of dwelling units in a Census Place with fewer total dwelling units than the threshold.

- \The value 'Not in a census Place' designates the fraction of dwelling units not in a Census Place according to the 2010 Census.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **City** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - AK, Anchorage
     - AL, Auburn
     - AL, Birmingham
     - AL, Decatur
     - AL, Dothan
     - AL, Florence
     - AL, Gadsden
     - AL, Hoover
     - AL, Huntsville
     - AL, Madison
     - AL, Mobile
     - AL, Montgomery
     - AL, Phenix City
     - AL, Tuscaloosa
     - AR, Bentonville
     - AR, Conway
     - AR, Fayetteville
     - AR, Fort Smith
     - AR, Hot Springs
     - AR, Jonesboro
     - AR, Little Rock
     - AR, North Little Rock
     - AR, Pine Bluff
     - AR, Rogers
     - AR, Springdale
     - AZ, Apache Junction
     - AZ, Avondale
     - AZ, Buckeye
     - AZ, Bullhead City
     - AZ, Casa Grande
     - AZ, Casas Adobes
     - AZ, Catalina Foothills
     - AZ, Chandler
     - AZ, Flagstaff
     - AZ, Fortuna Foothills
     - AZ, Gilbert
     - AZ, Glendale
     - AZ, Goodyear
     - AZ, Green Valley
     - AZ, Lake Havasu City
     - AZ, Marana
     - AZ, Maricopa
     - AZ, Mesa
     - AZ, Oro Valley
     - AZ, Peoria
     - AZ, Phoenix
     - AZ, Prescott
     - AZ, Prescott Valley
     - AZ, San Tan Valley
     - AZ, Scottsdale
     - AZ, Sierra Vista
     - AZ, Sun City
     - AZ, Sun City West
     - AZ, Surprise
     - AZ, Tempe
     - AZ, Tucson
     - AZ, Yuma
     - CA, Alameda
     - CA, Alhambra
     - CA, Aliso Viejo
     - CA, Altadena
     - CA, Anaheim
     - CA, Antioch
     - CA, Apple Valley
     - CA, Arcadia
     - CA, Arden-Arcade
     - CA, Bakersfield
     - CA, Baldwin Park
     - CA, Bellflower
     - CA, Berkeley
     - CA, Beverly Hills
     - CA, Brea
     - CA, Brentwood
     - CA, Buena Park
     - CA, Burbank
     - CA, Camarillo
     - CA, Campbell
     - CA, Carlsbad
     - CA, Carmichael
     - CA, Carson
     - CA, Castro Valley
     - CA, Cathedral City
     - CA, Cerritos
     - CA, Chico
     - CA, Chino
     - CA, Chino Hills
     - CA, Chula Vista
     - CA, Citrus Heights
     - CA, Clovis
     - CA, Colton
     - CA, Compton
     - CA, Concord
     - CA, Corona
     - CA, Costa Mesa
     - CA, Covina
     - CA, Culver City
     - CA, Cupertino
     - CA, Cypress
     - CA, Daly City
     - CA, Dana Point
     - CA, Danville
     - CA, Davis
     - CA, Diamond Bar
     - CA, Downey
     - CA, Dublin
     - CA, East Los Angeles
     - CA, El Cajon
     - CA, El Dorado Hills
     - CA, El Monte
     - CA, Elk Grove
     - CA, Encinitas
     - CA, Escondido
     - CA, Fairfield
     - CA, Florence-Graham
     - CA, Florin
     - CA, Folsom
     - CA, Fontana
     - CA, Fountain Valley
     - CA, Fremont
     - CA, Fresno
     - CA, Fullerton
     - CA, Garden Grove
     - CA, Gardena
     - CA, Gilroy
     - CA, Glendale
     - CA, Glendora
     - CA, Hacienda Heights
     - CA, Hanford
     - CA, Hawthorne
     - CA, Hayward
     - CA, Hemet
     - CA, Hesperia
     - CA, Highland
     - CA, Huntington Beach
     - CA, Huntington Park
     - CA, Indio
     - CA, Inglewood
     - CA, Irvine
     - CA, La Habra
     - CA, La Mesa
     - CA, La Quinta
     - CA, Laguna Niguel
     - CA, Lake Elsinore
     - CA, Lake Forest
     - CA, Lakewood
     - CA, Lancaster
     - CA, Lincoln
     - CA, Livermore
     - CA, Lodi
     - CA, Long Beach
     - CA, Los Angeles
     - CA, Lynwood
     - CA, Madera
     - CA, Manhattan Beach
     - CA, Manteca
     - CA, Martinez
     - CA, Menifee
     - CA, Merced
     - CA, Milpitas
     - CA, Mission Viejo
     - CA, Modesto
     - CA, Montebello
     - CA, Monterey Park
     - CA, Moreno Valley
     - CA, Mountain View
     - CA, Murrieta
     - CA, Napa
     - CA, National City
     - CA, Newport Beach
     - CA, North Highlands
     - CA, Norwalk
     - CA, Novato
     - CA, Oakland
     - CA, Oceanside
     - CA, Ontario
     - CA, Orange
     - CA, Oxnard
     - CA, Palm Desert
     - CA, Palm Springs
     - CA, Palmdale
     - CA, Palo Alto
     - CA, Pasadena
     - CA, Perris
     - CA, Petaluma
     - CA, Pico Rivera
     - CA, Pittsburg
     - CA, Placentia
     - CA, Pleasanton
     - CA, Pomona
     - CA, Porterville
     - CA, Poway
     - CA, Rancho Cordova
     - CA, Rancho Cucamonga
     - CA, Rancho Palos Verdes
     - CA, Rancho Santa Margarita
     - CA, Redding
     - CA, Redlands
     - CA, Redondo Beach
     - CA, Redwood City
     - CA, Rialto
     - CA, Richmond
     - CA, Riverside
     - CA, Rocklin
     - CA, Rohnert Park
     - CA, Rosemead
     - CA, Roseville
     - CA, Rowland Heights
     - CA, Sacramento
     - CA, Salinas
     - CA, San Bernardino
     - CA, San Bruno
     - CA, San Buenaventura Ventura
     - CA, San Clemente
     - CA, San Diego
     - CA, San Francisco
     - CA, San Jose
     - CA, San Leandro
     - CA, San Luis Obispo
     - CA, San Marcos
     - CA, San Mateo
     - CA, San Rafael
     - CA, San Ramon
     - CA, Santa Ana
     - CA, Santa Barbara
     - CA, Santa Clara
     - CA, Santa Clarita
     - CA, Santa Cruz
     - CA, Santa Maria
     - CA, Santa Monica
     - CA, Santa Rosa
     - CA, Santee
     - CA, Simi Valley
     - CA, South Gate
     - CA, South Lake Tahoe
     - CA, South San Francisco
     - CA, South Whittier
     - CA, Stockton
     - CA, Sunnyvale
     - CA, Temecula
     - CA, Thousand Oaks
     - CA, Torrance
     - CA, Tracy
     - CA, Tulare
     - CA, Turlock
     - CA, Tustin
     - CA, Union City
     - CA, Upland
     - CA, Vacaville
     - CA, Vallejo
     - CA, Victorville
     - CA, Visalia
     - CA, Vista
     - CA, Walnut Creek
     - CA, West Covina
     - CA, West Hollywood
     - CA, West Sacramento
     - CA, Westminster
     - CA, Whittier
     - CA, Woodland
     - CA, Yorba Linda
     - CA, Yuba City
     - CA, Yucaipa
     - CO, Arvada
     - CO, Aurora
     - CO, Boulder
     - CO, Broomfield
     - CO, Castle Rock
     - CO, Centennial
     - CO, Colorado Springs
     - CO, Commerce City
     - CO, Denver
     - CO, Englewood
     - CO, Fort Collins
     - CO, Grand Junction
     - CO, Greeley
     - CO, Highlands Ranch
     - CO, Lakewood
     - CO, Littleton
     - CO, Longmont
     - CO, Loveland
     - CO, Parker
     - CO, Pueblo
     - CO, Thornton
     - CO, Westminster
     - CT, Bridgeport
     - CT, Bristol
     - CT, Danbury
     - CT, East Hartford
     - CT, Hartford
     - CT, Meriden
     - CT, Middletown
     - CT, Milford City Balance
     - CT, New Britain
     - CT, New Haven
     - CT, Norwalk
     - CT, Norwich
     - CT, Shelton
     - CT, Stamford
     - CT, Stratford
     - CT, Torrington
     - CT, Waterbury
     - CT, West Hartford
     - CT, West Haven
     - DC, Washington
     - DE, Dover
     - DE, Wilmington
     - FL, Alafaya
     - FL, Altamonte Springs
     - FL, Apopka
     - FL, Aventura
     - FL, Boca Raton
     - FL, Bonita Springs
     - FL, Boynton Beach
     - FL, Bradenton
     - FL, Brandon
     - FL, Cape Coral
     - FL, Carrollwood
     - FL, Clearwater
     - FL, Coconut Creek
     - FL, Coral Gables
     - FL, Coral Springs
     - FL, Country Club
     - FL, Dania Beach
     - FL, Davie
     - FL, Daytona Beach
     - FL, Deerfield Beach
     - FL, Delray Beach
     - FL, Deltona
     - FL, Doral
     - FL, Dunedin
     - FL, East Lake
     - FL, Estero
     - FL, Fort Lauderdale
     - FL, Fort Myers
     - FL, Fort Pierce
     - FL, Fountainebleau
     - FL, Four Corners
     - FL, Gainesville
     - FL, Greenacres
     - FL, Hallandale Beach
     - FL, Hialeah
     - FL, Hollywood
     - FL, Homestead
     - FL, Jacksonville
     - FL, Jupiter
     - FL, Kendale Lakes
     - FL, Kendall
     - FL, Kissimmee
     - FL, Lake Worth
     - FL, Lakeland
     - FL, Largo
     - FL, Lauderhill
     - FL, Lehigh Acres
     - FL, Marco Island
     - FL, Margate
     - FL, Melbourne
     - FL, Merritt Island
     - FL, Miami
     - FL, Miami Beach
     - FL, Miami Gardens
     - FL, Miramar
     - FL, Naples
     - FL, New Smyrna Beach
     - FL, North Fort Myers
     - FL, North Miami
     - FL, North Miami Beach
     - FL, North Port
     - FL, Oakland Park
     - FL, Ocala
     - FL, Orlando
     - FL, Ormond Beach
     - FL, Palm Bay
     - FL, Palm Beach Gardens
     - FL, Palm Coast
     - FL, Palm Harbor
     - FL, Panama City
     - FL, Panama City Beach
     - FL, Pembroke Pines
     - FL, Pensacola
     - FL, Pine Hills
     - FL, Pinellas Park
     - FL, Plantation
     - FL, Poinciana
     - FL, Pompano Beach
     - FL, Port Charlotte
     - FL, Port Orange
     - FL, Port St Lucie
     - FL, Riverview
     - FL, Riviera Beach
     - FL, Sanford
     - FL, Sarasota
     - FL, Spring Hill
     - FL, St Cloud
     - FL, St Petersburg
     - FL, Sun City Center
     - FL, Sunny Isles Beach
     - FL, Sunrise
     - FL, Tallahassee
     - FL, Tamarac
     - FL, Tamiami
     - FL, Tampa
     - FL, The Hammocks
     - FL, The Villages
     - FL, Titusville
     - FL, Town N Country
     - FL, University
     - FL, Venice
     - FL, Wellington
     - FL, Wesley Chapel
     - FL, West Palm Beach
     - FL, Weston
     - FL, Winter Haven
     - GA, Albany
     - GA, Alpharetta
     - GA, Athens-Clarke County Unified Government Balance
     - GA, Atlanta
     - GA, Augusta-Richmond County Consolidated Government Balance
     - GA, Columbus
     - GA, Dunwoody
     - GA, East Point
     - GA, Hinesville
     - GA, Johns Creek
     - GA, Mableton
     - GA, Macon
     - GA, Marietta
     - GA, Newnan
     - GA, North Atlanta
     - GA, Rome
     - GA, Roswell
     - GA, Sandy Springs
     - GA, Savannah
     - GA, Smyrna
     - GA, Valdosta
     - GA, Warner Robins
     - HI, East Honolulu
     - HI, Hilo
     - HI, Kailua
     - HI, Urban Honolulu
     - IA, Ames
     - IA, Ankeny
     - IA, Cedar Falls
     - IA, Cedar Rapids
     - IA, Council Bluffs
     - IA, Davenport
     - IA, Des Moines
     - IA, Dubuque
     - IA, Iowa City
     - IA, Marion
     - IA, Sioux City
     - IA, Urbandale
     - IA, Waterloo
     - IA, West Des Moines
     - ID, Boise City
     - ID, Caldwell
     - ID, Coeur Dalene
     - ID, Idaho Falls
     - ID, Meridian
     - ID, Nampa
     - ID, Pocatello
     - ID, Twin Falls
     - IL, Arlington Heights
     - IL, Aurora
     - IL, Belleville
     - IL, Berwyn
     - IL, Bloomington
     - IL, Bolingbrook
     - IL, Buffalo Grove
     - IL, Calumet City
     - IL, Carol Stream
     - IL, Champaign
     - IL, Chicago
     - IL, Cicero
     - IL, Crystal Lake
     - IL, Decatur
     - IL, Dekalb
     - IL, Des Plaines
     - IL, Downers Grove
     - IL, Elgin
     - IL, Elmhurst
     - IL, Evanston
     - IL, Glenview
     - IL, Hoffman Estates
     - IL, Joliet
     - IL, Lombard
     - IL, Moline
     - IL, Mount Prospect
     - IL, Naperville
     - IL, Normal
     - IL, Oak Lawn
     - IL, Oak Park
     - IL, Orland Park
     - IL, Palatine
     - IL, Peoria
     - IL, Quincy
     - IL, Rock Island
     - IL, Rockford
     - IL, Schaumburg
     - IL, Skokie
     - IL, Springfield
     - IL, Tinley Park
     - IL, Urbana
     - IL, Waukegan
     - IL, Wheaton
     - IL, Wheeling
     - In another census Place
     - IN, Anderson
     - IN, Bloomington
     - IN, Carmel
     - IN, Columbus
     - IN, Elkhart
     - IN, Evansville
     - IN, Fishers
     - IN, Fort Wayne
     - IN, Gary
     - IN, Greenwood
     - IN, Hammond
     - IN, Indianapolis City Balance
     - IN, Jeffersonville
     - IN, Kokomo
     - IN, Lafayette
     - IN, Lawrence
     - IN, Mishawaka
     - IN, Muncie
     - IN, New Albany
     - IN, Noblesville
     - IN, Portage
     - IN, Richmond
     - IN, South Bend
     - IN, Terre Haute
     - KS, Hutchinson
     - KS, Kansas City
     - KS, Lawrence
     - KS, Lenexa
     - KS, Manhattan
     - KS, Olathe
     - KS, Overland Park
     - KS, Salina
     - KS, Shawnee
     - KS, Topeka
     - KS, Wichita
     - KY, Bowling Green
     - KY, Covington
     - KY, Lexington-Fayette
     - KY, Louisville Jefferson County Metro Government Balance
     - KY, Owensboro
     - LA, Alexandria
     - LA, Baton Rouge
     - LA, Bossier City
     - LA, Kenner
     - LA, Lafayette
     - LA, Lake Charles
     - LA, Metairie
     - LA, Monroe
     - LA, New Orleans
     - LA, Shreveport
     - MA, Arlington
     - MA, Attleboro
     - MA, Barnstable Town
     - MA, Beverly
     - MA, Boston
     - MA, Brockton
     - MA, Brookline
     - MA, Cambridge
     - MA, Chicopee
     - MA, Everett
     - MA, Fall River
     - MA, Fitchburg
     - MA, Framingham
     - MA, Haverhill
     - MA, Holyoke
     - MA, Lawrence
     - MA, Leominster
     - MA, Lowell
     - MA, Lynn
     - MA, Malden
     - MA, Marlborough
     - MA, Medford
     - MA, Methuen Town
     - MA, New Bedford
     - MA, Newton
     - MA, Peabody
     - MA, Pittsfield
     - MA, Quincy
     - MA, Revere
     - MA, Salem
     - MA, Somerville
     - MA, Springfield
     - MA, Taunton
     - MA, Waltham
     - MA, Watertown Town
     - MA, Westfield
     - MA, Weymouth Town
     - MA, Woburn
     - MA, Worcester
     - MD, Annapolis
     - MD, Aspen Hill
     - MD, Baltimore
     - MD, Bel Air South
     - MD, Bethesda
     - MD, Bowie
     - MD, Catonsville
     - MD, Columbia
     - MD, Dundalk
     - MD, Ellicott City
     - MD, Essex
     - MD, Frederick
     - MD, Gaithersburg
     - MD, Germantown
     - MD, Glen Burnie
     - MD, Hagerstown
     - MD, North Bethesda
     - MD, Ocean City
     - MD, Odenton
     - MD, Potomac
     - MD, Rockville
     - MD, Severn
     - MD, Silver Spring
     - MD, Towson
     - MD, Waldorf
     - MD, Wheaton
     - MD, Woodlawn
     - ME, Bangor
     - ME, Lewiston
     - ME, Portland
     - MI, Ann Arbor
     - MI, Battle Creek
     - MI, Bay City
     - MI, Dearborn
     - MI, Dearborn Heights
     - MI, Detroit
     - MI, Farmington Hills
     - MI, Flint
     - MI, Grand Rapids
     - MI, Jackson
     - MI, Kalamazoo
     - MI, Kentwood
     - MI, Lansing
     - MI, Lincoln Park
     - MI, Livonia
     - MI, Midland
     - MI, Muskegon
     - MI, Novi
     - MI, Pontiac
     - MI, Portage
     - MI, Rochester Hills
     - MI, Roseville
     - MI, Royal Oak
     - MI, Saginaw
     - MI, Southfield
     - MI, St Clair Shores
     - MI, Sterling Heights
     - MI, Taylor
     - MI, Troy
     - MI, Warren
     - MI, Westland
     - MI, Wyoming
     - MN, Apple Valley
     - MN, Blaine
     - MN, Bloomington
     - MN, Brooklyn Park
     - MN, Burnsville
     - MN, Coon Rapids
     - MN, Duluth
     - MN, Eagan
     - MN, Eden Prairie
     - MN, Edina
     - MN, Lakeville
     - MN, Mankato
     - MN, Maple Grove
     - MN, Maplewood
     - MN, Minneapolis
     - MN, Minnetonka
     - MN, Moorhead
     - MN, Plymouth
     - MN, Richfield
     - MN, Rochester
     - MN, Roseville
     - MN, St Cloud
     - MN, St Louis Park
     - MN, St Paul
     - MN, Woodbury
     - MO, Blue Springs
     - MO, Cape Girardeau
     - MO, Chesterfield
     - MO, Columbia
     - MO, Florissant
     - MO, Independence
     - MO, Jefferson City
     - MO, Joplin
     - MO, Kansas City
     - MO, Lees Summit
     - MO, Ofallon
     - MO, Springfield
     - MO, St Charles
     - MO, St Joseph
     - MO, St Louis
     - MO, St Peters
     - MO, University City
     - MS, Biloxi
     - MS, Gulfport
     - MS, Hattiesburg
     - MS, Jackson
     - MS, Meridian
     - MS, Southaven
     - MS, Tupelo
     - MT, Billings
     - MT, Bozeman
     - MT, Butte-Silver Bow Balance
     - MT, Great Falls
     - MT, Missoula
     - NC, Asheville
     - NC, Burlington
     - NC, Cary
     - NC, Chapel Hill
     - NC, Charlotte
     - NC, Concord
     - NC, Durham
     - NC, Fayetteville
     - NC, Gastonia
     - NC, Goldsboro
     - NC, Greensboro
     - NC, Greenville
     - NC, Hickory
     - NC, High Point
     - NC, Huntersville
     - NC, Jacksonville
     - NC, Kannapolis
     - NC, Raleigh
     - NC, Rocky Mount
     - NC, Wilmington
     - NC, Wilson
     - NC, Winston-Salem
     - ND, Bismarck
     - ND, Fargo
     - ND, Grand Forks
     - ND, Minot
     - NE, Bellevue
     - NE, Grand Island
     - NE, Lincoln
     - NE, Omaha
     - NH, Concord
     - NH, Manchester
     - NH, Nashua
     - NJ, Atlantic City
     - NJ, Bayonne
     - NJ, Camden
     - NJ, Clifton
     - NJ, East Orange
     - NJ, Elizabeth
     - NJ, Fort Lee
     - NJ, Hackensack
     - NJ, Hoboken
     - NJ, Jersey City
     - NJ, Linden
     - NJ, New Brunswick
     - NJ, Newark
     - NJ, Ocean City
     - NJ, Passaic
     - NJ, Paterson
     - NJ, Perth Amboy
     - NJ, Plainfield
     - NJ, Sayreville
     - NJ, Toms River
     - NJ, Trenton
     - NJ, Union City
     - NJ, Vineland
     - NJ, West New York
     - NM, Albuquerque
     - NM, Clovis
     - NM, Farmington
     - NM, Las Cruces
     - NM, Rio Rancho
     - NM, Roswell
     - NM, Santa Fe
     - NM, South Valley
     - Not in a census Place
     - NV, Carson City
     - NV, Enterprise
     - NV, Henderson
     - NV, Las Vegas
     - NV, North Las Vegas
     - NV, Pahrump
     - NV, Paradise
     - NV, Reno
     - NV, Sparks
     - NV, Spring Valley
     - NV, Sunrise Manor
     - NV, Whitney
     - NY, Albany
     - NY, Binghamton
     - NY, Brighton
     - NY, Buffalo
     - NY, Cheektowaga
     - NY, Coram
     - NY, Hempstead
     - NY, Irondequoit
     - NY, Levittown
     - NY, Long Beach
     - NY, Mount Vernon
     - NY, New Rochelle
     - NY, New York
     - NY, Niagara Falls
     - NY, Rochester
     - NY, Rome
     - NY, Schenectady
     - NY, Syracuse
     - NY, Tonawanda
     - NY, Troy
     - NY, Utica
     - NY, West Seneca
     - NY, White Plains
     - NY, Yonkers
     - OH, Akron
     - OH, Beavercreek
     - OH, Boardman
     - OH, Canton
     - OH, Cincinnati
     - OH, Cleveland
     - OH, Cleveland Heights
     - OH, Columbus
     - OH, Cuyahoga Falls
     - OH, Dayton
     - OH, Delaware
     - OH, Dublin
     - OH, Elyria
     - OH, Euclid
     - OH, Fairborn
     - OH, Fairfield
     - OH, Findlay
     - OH, Grove City
     - OH, Hamilton
     - OH, Huber Heights
     - OH, Kettering
     - OH, Lakewood
     - OH, Lancaster
     - OH, Lima
     - OH, Lorain
     - OH, Mansfield
     - OH, Marion
     - OH, Mentor
     - OH, Middletown
     - OH, Newark
     - OH, Parma
     - OH, Springfield
     - OH, Stow
     - OH, Strongsville
     - OH, Toledo
     - OH, Warren
     - OH, Youngstown
     - OK, Bartlesville
     - OK, Broken Arrow
     - OK, Edmond
     - OK, Enid
     - OK, Lawton
     - OK, Midwest City
     - OK, Moore
     - OK, Muskogee
     - OK, Norman
     - OK, Oklahoma City
     - OK, Stillwater
     - OK, Tulsa
     - OR, Albany
     - OR, Aloha
     - OR, Beaverton
     - OR, Bend
     - OR, Corvallis
     - OR, Eugene
     - OR, Grants Pass
     - OR, Gresham
     - OR, Hillsboro
     - OR, Lake Oswego
     - OR, Medford
     - OR, Portland
     - OR, Salem
     - OR, Springfield
     - OR, Tigard
     - PA, Allentown
     - PA, Altoona
     - PA, Bethlehem
     - PA, Erie
     - PA, Harrisburg
     - PA, Lancaster
     - PA, Levittown
     - PA, Philadelphia
     - PA, Pittsburgh
     - PA, Reading
     - PA, Scranton
     - PA, Wilkes-Barre
     - PA, York
     - RI, Cranston
     - RI, East Providence
     - RI, Pawtucket
     - RI, Providence
     - RI, Warwick
     - RI, Woonsocket
     - SC, Charleston
     - SC, Columbia
     - SC, Florence
     - SC, Goose Creek
     - SC, Greenville
     - SC, Hilton Head Island
     - SC, Mount Pleasant
     - SC, Myrtle Beach
     - SC, North Charleston
     - SC, North Myrtle Beach
     - SC, Rock Hill
     - SC, Spartanburg
     - SC, Summerville
     - SC, Sumter
     - SD, Rapid City
     - SD, Sioux Falls
     - TN, Bartlett
     - TN, Chattanooga
     - TN, Clarksville
     - TN, Cleveland
     - TN, Collierville
     - TN, Columbia
     - TN, Franklin
     - TN, Germantown
     - TN, Hendersonville
     - TN, Jackson
     - TN, Johnson City
     - TN, Kingsport
     - TN, Knoxville
     - TN, Memphis
     - TN, Murfreesboro
     - TN, Nashville-Davidson Metropolitan Government Balance
     - TN, Smyrna
     - TX, Abilene
     - TX, Allen
     - TX, Amarillo
     - TX, Arlington
     - TX, Atascocita
     - TX, Austin
     - TX, Baytown
     - TX, Beaumont
     - TX, Bedford
     - TX, Brownsville
     - TX, Bryan
     - TX, Burleson
     - TX, Carrollton
     - TX, Cedar Hill
     - TX, Cedar Park
     - TX, College Station
     - TX, Conroe
     - TX, Coppell
     - TX, Corpus Christi
     - TX, Dallas
     - TX, Denton
     - TX, Desoto
     - TX, Edinburg
     - TX, El Paso
     - TX, Euless
     - TX, Flower Mound
     - TX, Fort Worth
     - TX, Frisco
     - TX, Galveston
     - TX, Garland
     - TX, Georgetown
     - TX, Grand Prairie
     - TX, Grapevine
     - TX, Haltom City
     - TX, Harlingen
     - TX, Houston
     - TX, Hurst
     - TX, Irving
     - TX, Keller
     - TX, Killeen
     - TX, Laredo
     - TX, League City
     - TX, Lewisville
     - TX, Longview
     - TX, Lubbock
     - TX, Lufkin
     - TX, Mansfield
     - TX, Mcallen
     - TX, Mckinney
     - TX, Mesquite
     - TX, Midland
     - TX, Mission
     - TX, Missouri City
     - TX, New Braunfels
     - TX, North Richland Hills
     - TX, Odessa
     - TX, Pasadena
     - TX, Pearland
     - TX, Pflugerville
     - TX, Pharr
     - TX, Plano
     - TX, Port Arthur
     - TX, Richardson
     - TX, Round Rock
     - TX, Rowlett
     - TX, San Angelo
     - TX, San Antonio
     - TX, San Marcos
     - TX, Sherman
     - TX, Spring
     - TX, Sugar Land
     - TX, Temple
     - TX, Texarkana
     - TX, Texas City
     - TX, The Colony
     - TX, The Woodlands
     - TX, Tyler
     - TX, Victoria
     - TX, Waco
     - TX, Wichita Falls
     - TX, Wylie
     - UT, Layton
     - UT, Lehi
     - UT, Logan
     - UT, Millcreek
     - UT, Murray
     - UT, Ogden
     - UT, Orem
     - UT, Provo
     - UT, Salt Lake City
     - UT, Sandy
     - UT, South Jordan
     - UT, St George
     - UT, Taylorsville
     - UT, West Jordan
     - UT, West Valley City
     - VA, Alexandria
     - VA, Arlington
     - VA, Ashburn
     - VA, Blacksburg
     - VA, Centreville
     - VA, Charlottesville
     - VA, Chesapeake
     - VA, Dale City
     - VA, Danville
     - VA, Hampton
     - VA, Harrisonburg
     - VA, Lake Ridge
     - VA, Leesburg
     - VA, Lynchburg
     - VA, Mclean
     - VA, Mechanicsville
     - VA, Newport News
     - VA, Norfolk
     - VA, Petersburg
     - VA, Portsmouth
     - VA, Reston
     - VA, Richmond
     - VA, Roanoke
     - VA, Suffolk
     - VA, Tuckahoe
     - VA, Virginia Beach
     - VT, Burlington
     - WA, Auburn
     - WA, Bellevue
     - WA, Bellingham
     - WA, Bremerton
     - WA, Edmonds
     - WA, Everett
     - WA, Federal Way
     - WA, Kennewick
     - WA, Kent
     - WA, Kirkland
     - WA, Lacey
     - WA, Lakewood
     - WA, Longview
     - WA, Marysville
     - WA, Olympia
     - WA, Pasco
     - WA, Puyallup
     - WA, Redmond
     - WA, Renton
     - WA, Richland
     - WA, Sammamish
     - WA, Seattle
     - WA, Shoreline
     - WA, South Hill
     - WA, Spokane
     - WA, Spokane Valley
     - WA, Tacoma
     - WA, Vancouver
     - WA, Yakima
     - WI, Appleton
     - WI, Beloit
     - WI, Eau Claire
     - WI, Fond Du Lac
     - WI, Green Bay
     - WI, Greenfield
     - WI, Janesville
     - WI, Kenosha
     - WI, La Crosse
     - WI, Madison
     - WI, Manitowoc
     - WI, Menomonee Falls
     - WI, Milwaukee
     - WI, New Berlin
     - WI, Oshkosh
     - WI, Racine
     - WI, Sheboygan
     - WI, Waukesha
     - WI, Wausau
     - WI, Wauwatosa
     - WI, West Allis
     - WV, Charleston
     - WV, Huntington
     - WV, Parkersburg
     - WY, Casper
     - WY, Cheyenne
   * - Stock saturation
     - 0.085%
     - 0.019%
     - 0.085%
     - 0.018%
     - 0.023%
     - 0.015%
     - 0.013%
     - 0.027%
     - 0.068%
     - 0.014%
     - 0.068%
     - 0.069%
     - 0.013%
     - 0.034%
     - 0.013%
     - 0.02%
     - 0.028%
     - 0.03%
     - 0.014%
     - 0.023%
     - 0.071%
     - 0.024%
     - 0.016%
     - 0.017%
     - 0.02%
     - 0.017%
     - 0.02%
     - 0.015%
     - 0.018%
     - 0.016%
     - 0.023%
     - 0.02%
     - 0.069%
     - 0.02%
     - 0.015%
     - 0.058%
     - 0.068%
     - 0.021%
     - 0.013%
     - 0.025%
     - 0.012%
     - 0.013%
     - 0.15%
     - 0.016%
     - 0.048%
     - 0.45%
     - 0.017%
     - 0.014%
     - 0.024%
     - 0.098%
     - 0.015%
     - 0.021%
     - 0.014%
     - 0.042%
     - 0.056%
     - 0.17%
     - 0.03%
     - 0.024%
     - 0.023%
     - 0.015%
     - 0.012%
     - 0.078%
     - 0.027%
     - 0.019%
     - 0.015%
     - 0.033%
     - 0.091%
     - 0.014%
     - 0.019%
     - 0.037%
     - 0.012%
     - 0.012%
     - 0.014%
     - 0.018%
     - 0.034%
     - 0.019%
     - 0.013%
     - 0.035%
     - 0.021%
     - 0.019%
     - 0.017%
     - 0.017%
     - 0.012%
     - 0.03%
     - 0.015%
     - 0.019%
     - 0.063%
     - 0.026%
     - 0.027%
     - 0.013%
     - 0.019%
     - 0.036%
     - 0.039%
     - 0.032%
     - 0.012%
     - 0.013%
     - 0.016%
     - 0.012%
     - 0.024%
     - 0.013%
     - 0.012%
     - 0.019%
     - 0.014%
     - 0.026%
     - 0.014%
     - 0.025%
     - 0.026%
     - 0.011%
     - 0.024%
     - 0.039%
     - 0.019%
     - 0.035%
     - 0.028%
     - 0.011%
     - 0.012%
     - 0.02%
     - 0.04%
     - 0.014%
     - 0.057%
     - 0.13%
     - 0.036%
     - 0.036%
     - 0.016%
     - 0.012%
     - 0.057%
     - 0.013%
     - 0.013%
     - 0.014%
     - 0.022%
     - 0.036%
     - 0.025%
     - 0.021%
     - 0.013%
     - 0.059%
     - 0.011%
     - 0.024%
     - 0.029%
     - 0.073%
     - 0.015%
     - 0.019%
     - 0.018%
     - 0.02%
     - 0.012%
     - 0.02%
     - 0.021%
     - 0.039%
     - 0.013%
     - 0.024%
     - 0.018%
     - 0.13%
     - 1.1%
     - 0.012%
     - 0.014%
     - 0.012%
     - 0.018%
     - 0.011%
     - 0.023%
     - 0.02%
     - 0.017%
     - 0.026%
     - 0.056%
     - 0.016%
     - 0.016%
     - 0.041%
     - 0.026%
     - 0.025%
     - 0.023%
     - 0.013%
     - 0.033%
     - 0.012%
     - 0.021%
     - 0.017%
     - 0.13%
     - 0.049%
     - 0.039%
     - 0.033%
     - 0.041%
     - 0.029%
     - 0.027%
     - 0.035%
     - 0.021%
     - 0.044%
     - 0.013%
     - 0.017%
     - 0.013%
     - 0.016%
     - 0.013%
     - 0.021%
     - 0.03%
     - 0.013%
     - 0.012%
     - 0.019%
     - 0.044%
     - 0.012%
     - 0.013%
     - 0.029%
     - 0.019%
     - 0.022%
     - 0.023%
     - 0.02%
     - 0.029%
     - 0.073%
     - 0.017%
     - 0.013%
     - 0.012%
     - 0.037%
     - 0.012%
     - 0.14%
     - 0.032%
     - 0.046%
     - 0.011%
     - 0.032%
     - 0.02%
     - 0.39%
     - 0.29%
     - 0.24%
     - 0.025%
     - 0.015%
     - 0.022%
     - 0.03%
     - 0.018%
     - 0.019%
     - 0.058%
     - 0.029%
     - 0.035%
     - 0.046%
     - 0.018%
     - 0.022%
     - 0.038%
     - 0.051%
     - 0.015%
     - 0.032%
     - 0.018%
     - 0.013%
     - 0.016%
     - 0.012%
     - 0.076%
     - 0.043%
     - 0.026%
     - 0.035%
     - 0.044%
     - 0.019%
     - 0.015%
     - 0.019%
     - 0.019%
     - 0.016%
     - 0.021%
     - 0.025%
     - 0.034%
     - 0.027%
     - 0.034%
     - 0.024%
     - 0.024%
     - 0.024%
     - 0.018%
     - 0.014%
     - 0.021%
     - 0.022%
     - 0.016%
     - 0.017%
     - 0.017%
     - 0.015%
     - 0.034%
     - 0.099%
     - 0.034%
     - 0.019%
     - 0.015%
     - 0.029%
     - 0.14%
     - 0.012%
     - 0.22%
     - 0.012%
     - 0.046%
     - 0.02%
     - 0.027%
     - 0.029%
     - 0.049%
     - 0.016%
     - 0.027%
     - 0.023%
     - 0.013%
     - 0.036%
     - 0.034%
     - 0.033%
     - 0.043%
     - 0.02%
     - 0.024%
     - 0.016%
     - 0.04%
     - 0.022%
     - 0.016%
     - 0.017%
     - 0.024%
     - 0.042%
     - 0.026%
     - 0.014%
     - 0.013%
     - 0.039%
     - 0.016%
     - 0.013%
     - 0.035%
     - 0.019%
     - 0.017%
     - 0.23%
     - 0.011%
     - 0.025%
     - 0.024%
     - 0.017%
     - 0.014%
     - 0.024%
     - 0.036%
     - 0.025%
     - 0.027%
     - 0.02%
     - 0.033%
     - 0.06%
     - 0.011%
     - 0.044%
     - 0.02%
     - 0.016%
     - 0.033%
     - 0.013%
     - 0.012%
     - 0.028%
     - 0.027%
     - 0.032%
     - 0.026%
     - 0.025%
     - 0.015%
     - 0.015%
     - 0.011%
     - 0.015%
     - 0.071%
     - 0.028%
     - 0.016%
     - 0.017%
     - 0.021%
     - 0.044%
     - 0.012%
     - 0.022%
     - 0.056%
     - 0.053%
     - 0.017%
     - 0.28%
     - 0.023%
     - 0.014%
     - 0.023%
     - 0.02%
     - 0.012%
     - 0.036%
     - 0.034%
     - 0.021%
     - 0.028%
     - 0.014%
     - 0.019%
     - 0.03%
     - 0.013%
     - 0.14%
     - 0.052%
     - 0.026%
     - 0.032%
     - 0.014%
     - 0.013%
     - 0.019%
     - 0.016%
     - 0.012%
     - 0.022%
     - 0.014%
     - 0.019%
     - 0.093%
     - 0.014%
     - 0.033%
     - 0.021%
     - 0.026%
     - 0.023%
     - 0.013%
     - 0.013%
     - 0.048%
     - 0.019%
     - 0.017%
     - 0.018%
     - 0.03%
     - 0.017%
     - 0.041%
     - 0.022%
     - 0.021%
     - 0.053%
     - 0.023%
     - 0.012%
     - 0.019%
     - 0.022%
     - 0.034%
     - 0.012%
     - 0.096%
     - 0.011%
     - 0.016%
     - 0.028%
     - 0.064%
     - 0.024%
     - 0.013%
     - 0.12%
     - 0.013%
     - 0.035%
     - 0.018%
     - 0.025%
     - 0.022%
     - 0.014%
     - 0.018%
     - 0.014%
     - 0.041%
     - 0.019%
     - 0.014%
     - 0.025%
     - 0.018%
     - 0.038%
     - 0.17%
     - 0.064%
     - 0.063%
     - 0.017%
     - 0.014%
     - 0.011%
     - 0.021%
     - 0.011%
     - 0.032%
     - 0.02%
     - 0.011%
     - 0.014%
     - 0.012%
     - 0.027%
     - 0.036%
     - 0.047%
     - 0.019%
     - 0.018%
     - 0.023%
     - 0.014%
     - 0.014%
     - 0.014%
     - 0.11%
     - 0.019%
     - 0.016%
     - 0.012%
     - 0.044%
     - 0.02%
     - 0.033%
     - 0.067%
     - 0.019%
     - 0.023%
     - 0.012%
     - 0.025%
     - 0.012%
     - 0.023%
     - 0.021%
     - 0.068%
     - 0.013%
     - 0.016%
     - 0.017%
     - 0.023%
     - 0.023%
     - 0.017%
     - 0.014%
     - 0.024%
     - 0.049%
     - 0.016%
     - 0.015%
     - 0.025%
     - 0.018%
     - 0.012%
     - 0.012%
     - 0.011%
     - 0.028%
     - 0.89%
     - 0.018%
     - 0.011%
     - 0.027%
     - 0.012%
     - 0.017%
     - 0.015%
     - 0.029%
     - 0.012%
     - 0.024%
     - 0.013%
     - 0.014%
     - 0.038%
     - 0.014%
     - 0.015%
     - 0.016%
     - 0.04%
     - 0.016%
     - 0.017%
     - 0.017%
     - 0.017%
     - 0.021%
     - 0.04%
     - 0.014%
     - 0.013%
     - 0.05%
     - 0.024%
     - 0.018%
     - 0.042%
     - 0.017%
     - 0.013%
     - 0.024%
     - 0.015%
     - 0.012%
     - 31%
     - 0.021%
     - 0.025%
     - 0.026%
     - 0.015%
     - 0.016%
     - 0.043%
     - 0.023%
     - 0.085%
     - 0.032%
     - 0.017%
     - 0.024%
     - 0.28%
     - 0.015%
     - 0.017%
     - 0.024%
     - 0.015%
     - 0.018%
     - 0.024%
     - 0.013%
     - 0.017%
     - 0.011%
     - 0.013%
     - 0.035%
     - 0.019%
     - 0.014%
     - 0.047%
     - 0.029%
     - 0.016%
     - 0.017%
     - 0.036%
     - 0.06%
     - 0.016%
     - 0.019%
     - 0.045%
     - 0.13%
     - 0.02%
     - 0.015%
     - 0.1%
     - 0.21%
     - 0.02%
     - 0.016%
     - 0.075%
     - 0.021%
     - 0.021%
     - 0.041%
     - 0.026%
     - 0.048%
     - 0.015%
     - 0.14%
     - 0.067%
     - 0.015%
     - 0.013%
     - 0.02%
     - 0.013%
     - 0.21%
     - 0.026%
     - 0.02%
     - 0.036%
     - 0.018%
     - 0.012%
     - 0.032%
     - 0.013%
     - 0.021%
     - 0.019%
     - 0.012%
     - 0.02%
     - 0.013%
     - 0.031%
     - 0.026%
     - 0.018%
     - 0.012%
     - 0.017%
     - 0.014%
     - 0.032%
     - 0.024%
     - 0.017%
     - 0.016%
     - 0.032%
     - 0.016%
     - 0.014%
     - 0.025%
     - 0.046%
     - 0.018%
     - 0.019%
     - 0.012%
     - 0.012%
     - 0.018%
     - 0.012%
     - 0.057%
     - 0.013%
     - 0.013%
     - 0.22%
     - 0.014%
     - 0.02%
     - 0.015%
     - 0.012%
     - 0.031%
     - 0.019%
     - 0.019%
     - 0.012%
     - 0.022%
     - 0.019%
     - 0.024%
     - 0.022%
     - 0.014%
     - 0.016%
     - 0.022%
     - 0.012%
     - 0.013%
     - 0.019%
     - 0.014%
     - 0.024%
     - 0.017%
     - 0.021%
     - 0.012%
     - 0.013%
     - 0.012%
     - 0.013%
     - 0.025%
     - 0.037%
     - 0.018%
     - 0.012%
     - 0.026%
     - 0.016%
     - 0.27%
     - 0.028%
     - 0.04%
     - 0.06%
     - 0.011%
     - 0.024%
     - 0.016%
     - 0.041%
     - 0.012%
     - 0.029%
     - 0.014%
     - 0.012%
     - 0.018%
     - 0.02%
     - 0.015%
     - 0.022%
     - 0.016%
     - 0.023%
     - 0.018%
     - 0.027%
     - 0.021%
     - 0.039%
     - 0.019%
     - 0.024%
     - 0.044%
     - 0.027%
     - 0.022%
     - 0.015%
     - 0.017%
     - 0.028%
     - 0.022%
     - 0.019%
     - 0.018%
     - 0.029%
     - 0.02%
     - 0.019%
     - 0.017%
     - 0.016%
     - 0.013%
     - 0.019%
     - 0.012%
     - 0.14%
     - 0.018%
     - 0.012%
     - 0.024%
     - 0.012%
     - 0.036%
     - 0.012%
     - 0.02%
     - 0.018%
     - 0.089%
     - 0.019%
     - 0.015%
     - 0.013%
     - 0.015%
     - 0.038%
     - 0.017%
     - 0.04%
     - 0.014%
     - 0.018%
     - 0.17%
     - 0.027%
     - 0.024%
     - 0.06%
     - 0.022%
     - 0.025%
     - 0.13%
     - 0.017%
     - 0.013%
     - 0.016%
     - 0.025%
     - 0.016%
     - 0.056%
     - 0.014%
     - 0.015%
     - 0.012%
     - 0.036%
     - 0.014%
     - 0.012%
     - 0.02%
     - 0.024%
     - 0.031%
     - 0.017%
     - 0.045%
     - 0.016%
     - 0.25%
     - 0.025%
     - 0.082%
     - 0.069%
     - 0.024%
     - 0.012%
     - 0.096%
     - 0.031%
     - 0.014%
     - 0.035%
     - 0.015%
     - 0.018%
     - 0.015%
     - 0.14%
     - 0.02%
     - 0.042%
     - 0.016%
     - 0.079%
     - 0.023%
     - 0.041%
     - 0.019%
     - 0.016%
     - 0.015%
     - 0.015%
     - 0.085%
     - 0.13%
     - 0.014%
     - 0.037%
     - 0.027%
     - 0.015%
     - 0.021%
     - 0.023%
     - 0.024%
     - 0.022%
     - 0.033%
     - 0.014%
     - 0.015%
     - 0.02%
     - 0.083%
     - 0.012%
     - 0.012%
     - 0.083%
     - 0.015%
     - 0.016%
     - 0.037%
     - 0.012%
     - 0.012%
     - 0.013%
     - 0.027%
     - 0.026%
     - 0.02%
     - 0.017%
     - 0.015%
     - 0.18%
     - 0.012%
     - 0.013%
     - 0.034%
     - 0.026%
     - 0.015%
     - 0.028%
     - 0.011%
     - 27%
     - 0.017%
     - 0.04%
     - 0.09%
     - 0.19%
     - 0.058%
     - 0.013%
     - 0.084%
     - 0.077%
     - 0.029%
     - 0.063%
     - 0.053%
     - 0.012%
     - 0.035%
     - 0.018%
     - 0.012%
     - 0.098%
     - 0.027%
     - 0.012%
     - 0.013%
     - 0.018%
     - 0.012%
     - 0.012%
     - 0.02%
     - 0.022%
     - 2.6%
     - 0.019%
     - 0.073%
     - 0.011%
     - 0.024%
     - 0.049%
     - 0.026%
     - 0.017%
     - 0.02%
     - 0.015%
     - 0.017%
     - 0.061%
     - 0.073%
     - 0.014%
     - 0.012%
     - 0.027%
     - 0.12%
     - 0.16%
     - 0.016%
     - 0.29%
     - 0.018%
     - 0.055%
     - 0.011%
     - 0.012%
     - 0.019%
     - 0.02%
     - 0.012%
     - 0.014%
     - 0.014%
     - 0.012%
     - 0.021%
     - 0.012%
     - 0.02%
     - 0.02%
     - 0.013%
     - 0.012%
     - 0.022%
     - 0.016%
     - 0.011%
     - 0.015%
     - 0.017%
     - 0.016%
     - 0.027%
     - 0.021%
     - 0.011%
     - 0.014%
     - 0.1%
     - 0.015%
     - 0.025%
     - 0.013%
     - 0.03%
     - 0.026%
     - 0.016%
     - 0.03%
     - 0.019%
     - 0.017%
     - 0.013%
     - 0.038%
     - 0.2%
     - 0.016%
     - 0.14%
     - 0.016%
     - 0.013%
     - 0.03%
     - 0.028%
     - 0.018%
     - 0.053%
     - 0.011%
     - 0.031%
     - 0.029%
     - 0.013%
     - 0.025%
     - 0.2%
     - 0.047%
     - 0.019%
     - 0.015%
     - 0.034%
     - 0.015%
     - 0.023%
     - 0.034%
     - 0.018%
     - 0.017%
     - 0.014%
     - 0.5%
     - 0.11%
     - 0.025%
     - 0.025%
     - 0.014%
     - 0.014%
     - 0.024%
     - 0.016%
     - 0.023%
     - 0.053%
     - 0.028%
     - 0.015%
     - 0.047%
     - 0.04%
     - 0.013%
     - 0.011%
     - 0.023%
     - 0.025%
     - 0.024%
     - 0.019%
     - 0.034%
     - 0.021%
     - 0.022%
     - 0.013%
     - 0.015%
     - 0.014%
     - 0.023%
     - 0.053%
     - 0.015%
     - 0.06%
     - 0.044%
     - 0.014%
     - 0.012%
     - 0.012%
     - 0.022%
     - 0.012%
     - 0.016%
     - 0.022%
     - 0.024%
     - 0.018%
     - 0.067%
     - 0.22%
     - 0.037%
     - 0.21%
     - 0.013%
     - 0.036%
     - 0.023%
     - 0.062%
     - 0.11%
     - 0.018%
     - 0.28%
     - 0.022%
     - 0.039%
     - 0.017%
     - 0.042%
     - 0.024%
     - 0.012%
     - 0.036%
     - 0.012%
     - 0.015%
     - 0.032%
     - 0.019%
     - 0.012%
     - 0.096%
     - 0.41%
     - 0.035%
     - 0.015%
     - 0.02%
     - 0.18%
     - 0.017%
     - 0.018%
     - 0.23%
     - 0.037%
     - 0.024%
     - 0.06%
     - 0.016%
     - 0.048%
     - 0.015%
     - 0.012%
     - 0.019%
     - 0.69%
     - 0.012%
     - 0.067%
     - 0.011%
     - 0.044%
     - 0.055%
     - 0.027%
     - 0.031%
     - 0.025%
     - 0.077%
     - 0.011%
     - 0.017%
     - 0.036%
     - 0.041%
     - 0.038%
     - 0.035%
     - 0.022%
     - 0.018%
     - 0.02%
     - 0.02%
     - 0.032%
     - 0.04%
     - 0.028%
     - 0.014%
     - 0.018%
     - 0.081%
     - 0.018%
     - 0.032%
     - 0.027%
     - 0.015%
     - 0.03%
     - 0.4%
     - 0.018%
     - 0.012%
     - 0.015%
     - 0.021%
     - 0.023%
     - 0.012%
     - 0.015%
     - 0.012%
     - 0.031%
     - 0.032%
     - 0.02%
     - 0.04%
     - 0.032%
     - 0.011%
     - 0.018%
     - 0.011%
     - 0.013%
     - 0.02%
     - 0.014%
     - 0.024%
     - 0.02%
     - 0.026%
     - 0.061%
     - 0.023%
     - 0.015%
     - 0.025%
     - 0.015%
     - 0.025%
     - 0.029%
     - 0.056%
     - 0.083%
     - 0.013%
     - 0.011%
     - 0.019%
     - 0.015%
     - 0.066%
     - 0.016%
     - 0.017%
     - 0.045%
     - 0.013%
     - 0.012%
     - 0.013%
     - 0.024%
     - 0.013%
     - 0.011%
     - 0.058%
     - 0.072%
     - 0.012%
     - 0.031%
     - 0.02%
     - 0.075%
     - 0.035%
     - 0.026%
     - 0.014%
     - 0.14%
     - 0.012%
     - 0.022%
     - 0.042%
     - 0.028%
     - 0.013%
     - 0.014%
     - 0.034%
     - 0.027%
     - 0.022%
     - 0.027%
     - 0.018%
     - 0.015%
     - 0.02%
     - 0.012%
     - 0.018%
     - 0.017%
     - 0.015%
     - 0.012%
     - 0.019%
     - 0.03%
     - 0.016%
     - 0.012%
     - 0.24%
     - 0.017%
     - 0.015%
     - 0.072%
     - 0.03%
     - 0.065%
     - 0.052%
     - 0.027%
     - 0.022%
     - 0.011%
     - 0.022%
     - 0.014%
     - 0.034%
     - 0.013%
     - 0.021%
     - 0.03%
     - 0.017%
     - 0.083%
     - 0.012%
     - 0.011%
     - 0.19%
     - 0.013%
     - 0.021%
     - 0.025%
     - 0.017%
     - 0.023%
     - 0.014%
     - 0.016%
     - 0.022%
     - 0.019%
     - 0.019%
     - 0.012%
     - 0.019%
     - 0.021%

.. _clothes_dryer:

Clothes Dryer
-------------

Description
***********

The presence, rated efficiency, and fuel type of the clothes dryer in a dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Clothes dryer option is None if clothes washer not presentDue to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:

- \Dwelling unit sub-tsv :deps=['Geometry Building Type RECS', 'State', 'Heating Fuel', 'Clothes Washer Presence'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS without AK, HI

  - \[2] Heating Fuel coarsened to Other Fuel, Wood and Propane combined

  - \[3] Heating Fuel coarsened to Fuel Oil, Other Fuel, Wood and Propane combined

  - \[4] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[5] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[6] State coarsened to Census Division RECS

  - \[7] State coarsened to Census Region

  - \[8] State coarsened to National

- \Household sub-tsv : deps=['Geometry Building Type RECS', 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS without AK, HI

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] State coarsened to Census Division RECS

  - \[7] State coarsened to Census Region

  - \[8] State coarsened to National

- \In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across (['Heating Fuel','Clothes Washer Presence'], ['Tenure', 'Federal Poverty Level']).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Clothes Dryer** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Electric
     - Gas
     - None
     - Propane
     - Void
   * - Stock saturation
     - 67%
     - 14%
     - 18%
     - 1.1%
     - 0%
   * - ``appliance_clothes_dryer_efficiency_type``
     - CombinedEnergyFactor
     - CombinedEnergyFactor
     - 
     - CombinedEnergyFactor
     - 
   * - ``appliance_clothes_dryer_efficiency``
     - 3.73
     - 3.3
     - 
     - 3.3
     - 
   * - ``appliance_clothes_dryer_fuel_type``
     - electricity
     - natural gas
     - 
     - propane
     - 
   * - ``appliance_clothes_dryer_drying_method``
     - conventional
     - conventional
     - 
     - conventional
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``appliance_clothes_dryer_efficiency_type``
     - 
     - The efficiency type of the clothes dryer.
   * - ``appliance_clothes_dryer_efficiency``
     - lb/kWh
     - The efficiency from the EnergyGuide label.
   * - ``appliance_clothes_dryer_fuel_type``
     - 
     - Type of fuel used by the clothes dryer.
   * - ``appliance_clothes_dryer_drying_method``
     - 
     - The method of drying used by the clothes dryer.
.. _clothes_dryer_usage_level:

Clothes Dryer Usage Level
-------------------------

Description
***********

Clothes dryer energy usage level multiplier.

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \n/a


Assumption
**********

- \Engineering judgement


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Clothes Dryer Usage Level** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 80% Usage
     - 100% Usage
     - 120% Usage
   * - Stock saturation
     - 25%
     - 50%
     - 25%
   * - ``clothes_dryer_usage_multiplier``
     - 0.8
     - 1.0
     - 1.2

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``clothes_dryer_usage_multiplier``
     - 
     - Multiplier on the clothes dryer energy usage that can reflect, e.g., high/low usage occupants.
.. _clothes_washer:

Clothes Washer
--------------

Description
***********

Presence and rated efficiency of the clothes washer.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \The 2020 recs survey does not contain EnergyStar rating of clothes washers.Energystar efficiency distributions with [Geometry Building Type,Federal Poverty Level, Tenure] as dependencies are imported from RECS 2009Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:

- \Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State','Clothes Washer Presence', 'Vintage'] with the following fallback coarsening order

  - \[1] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[2] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[3] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently

  - \[4] Vintage homes built before 1960 coarsened to pre1960

  - \[5] Vintage homes built after 2000 coarsened to 2000-20

- \Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order

  - \[1] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[2] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[3] Federal Poverty Level coarsened every 100 percent

  - \[4] Federal Poverty Level coarsened every 200 percent

- \In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across (['Clothes Washer Presence', 'Vintage'], ['Tenure', 'Federal Poverty Level']).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Clothes Washer** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - EnergyStar
     - None
     - Standard
     - Void
   * - Stock saturation
     - 34%
     - 16%
     - 50%
     - 0%
   * - ``appliance_clothes_washer_efficiency_type``
     - IntegratedModifiedEnergyFactor
     - 
     - IntegratedModifiedEnergyFactor
     - 
   * - ``appliance_clothes_washer_efficiency``
     - 1.63
     - 
     - 1.21
     - 
   * - ``appliance_clothes_washer_rated_annual_consumption``
     - 260
     - 
     - 380
     - 
   * - ``appliance_clothes_washer_label_electric_rate``
     - 0.12
     - 
     - 0.12
     - 
   * - ``appliance_clothes_washer_label_gas_rate``
     - 1.09
     - 
     - 1.09
     - 
   * - ``appliance_clothes_washer_label_annual_gas_cost``
     - 18
     - 
     - 27
     - 
   * - ``appliance_clothes_washer_label_usage``
     - 6
     - 
     - 6
     - 
   * - ``appliance_clothes_washer_capacity``
     - 3.5
     - 
     - 3.2
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``appliance_clothes_washer_efficiency_type``
     - 
     - The efficiency type of the clothes washer.
   * - ``appliance_clothes_washer_efficiency``
     - ft3/kWh-cyc
     - The efficiency from the EnergyGuide label.
   * - ``appliance_clothes_washer_rated_annual_consumption``
     - kWh/yr
     - The annual energy consumed, as rated, from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.
   * - ``appliance_clothes_washer_label_electric_rate``
     - $/kWh
     - The electricity rate from the EnergyGuide label.
   * - ``appliance_clothes_washer_label_gas_rate``
     - $/therm
     - The natural gas rate from the EnergyGuide label.
   * - ``appliance_clothes_washer_label_annual_gas_cost``
     - $
     - The annual cost of using the system under test conditions with a natural gas water heater. Input is obtained from the EnergyGuide label.
   * - ``appliance_clothes_washer_label_usage``
     - cyc/wk
     - The clothes washer loads per week from the EnergyGuide label.
   * - ``appliance_clothes_washer_capacity``
     - ft3
     - Volume of the washer drum. Obtained from the EnergyStar website or the manufacturer's literature.
.. _clothes_washer_presence:

Clothes Washer Presence
-----------------------

Description
***********

The presence of a clothes washer in the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:

- \Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State', 'Heating Fuel', 'Vintage'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently

  - \[5] Vintage homes built before 1960 coarsened to pre1960

  - \[6] Vintage homes built after 2000 coarsened to 2000-20

  - \[7] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[8] Census Division RECS to Census Region

  - \[9] Census Region to National

- \Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[7] Census Division RECS to Census Region

  - \[8] Census Region to National

- \In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across (['Geometry Building Type RECS', 'Vintage'], ['Tenure', 'Federal Poverty Level']).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Clothes Washer Presence** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - Yes
     - Void
   * - Stock saturation
     - 16%
     - 84%
     - 0%

.. _clothes_washer_usage_level:

Clothes Washer Usage Level
--------------------------

Description
***********

Clothes washer energy usage level multiplier.

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \n/a


Assumption
**********

- \Engineering judgement


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Clothes Washer Usage Level** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 80% Usage
     - 100% Usage
     - 120% Usage
   * - Stock saturation
     - 25%
     - 50%
     - 25%
   * - ``clothes_washer_usage_multiplier``
     - 0.8
     - 1.0
     - 1.2

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``clothes_washer_usage_multiplier``
     - 
     - Multiplier on the clothes washer energy usage that can reflect, e.g., high/low usage occupants.
.. _cooking_range:

Cooking Range
-------------

Description
***********

Presence and fuel type of the cooking range.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For Dual Fuel Range the distribution is split equally between Electric and Natural GasDue to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:

- \Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State', 'Heating Fuel', 'Vintage'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Heating Fuel coarsened to Other Fuel, Wood and Propane combined

  - \[3] Heating Fuel coarsened to Fuel Oil, Other Fuel, Wood and Propane combined

  - \[4] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[5] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[6] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently

  - \[7] Vintage homes built before 1960 coarsened to pre1960

  - \[8] Vintage homes built after 2000 coarsened to 2000-20

  - \[9] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[10] Census Division RECS to Census Region

  - \[11] Census Region to National

- \Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[7] Census Division RECS to Census Region

  - \[8] Census Region to National

- \In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across (['Heating Fuel', 'Vintage'], ['Tenure', 'Federal Poverty Level']).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Cooking Range** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Electric Induction
     - Electric Resistance
     - Gas
     - None
     - Propane
     - Void
   * - Stock saturation
     - 2.8%
     - 60%
     - 33%
     - 0.096%
     - 4.9%
     - 0%
   * - ``appliance_cooking_range_oven_fuel_type``
     - electricity
     - electricity
     - natural gas
     - 
     - propane
     - 
   * - ``appliance_cooking_range_oven_is_induction``
     - true
     - false
     - 
     - 
     - 
     - 
   * - ``appliance_cooking_range_oven_is_convection``
     - false
     - false
     - false
     - 
     - false
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``appliance_cooking_range_oven_fuel_type``
     - 
     - Type of fuel used by the cooking range/oven
   * - ``appliance_cooking_range_oven_is_induction``
     - 
     - Whether the electric cooking range is induction.
   * - ``appliance_cooking_range_oven_is_convection``
     - 
     - Whether the oven is convection
.. _cooking_range_usage_level:

Cooking Range Usage Level
-------------------------

Description
***********

Cooking range energy usage level multiplier.

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \n/a


Assumption
**********

- \Engineering judgement


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Cooking Range Usage Level** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 80% Usage
     - 100% Usage
     - 120% Usage
   * - Stock saturation
     - 25%
     - 50%
     - 25%
   * - ``cooking_range_oven_usage_multiplier``
     - 0.8
     - 1.0
     - 1.2

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``cooking_range_oven_usage_multiplier``
     - 
     - Multiplier on the cooking range/oven energy usage that can reflect, e.g., high/low usage occupants.
.. _cooling_setpoint:

Cooling Setpoint
----------------

Description
***********

Baseline cooling setpoint with no offset applied.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only, 2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK, 4) Owner and Renter are is lumped together which at this point only modifies AK distributions.Vacant units (for which Tenure = 'Not Available') are assumed to follow the same distribution as occupied  units

- \Cooling setpoint arguments need to be assigned. A cooling setpoint of None corresponds to 95 F, but is not used by OpenStudio-HPXML. No cooling energy is expected.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Cooling Setpoint** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 60F
     - 62F
     - 65F
     - 67F
     - 68F
     - 70F
     - 72F
     - 75F
     - 76F
     - 78F
     - 80F
     - Void
   * - Stock saturation
     - 3.2%
     - 0.98%
     - 4.1%
     - 2%
     - 12%
     - 19%
     - 20%
     - 19%
     - 8%
     - 7.9%
     - 4.8%
     - 0%
   * - ``hvac_control_cooling_season_period``
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - 
   * - ``hvac_control_cooling_weekday_setpoint_temp``
     - 60
     - 62
     - 65
     - 67
     - 68
     - 70
     - 72
     - 75
     - 76
     - 78
     - 80
     - 
   * - ``hvac_control_cooling_weekend_setpoint_temp``
     - 60
     - 62
     - 65
     - 67
     - 68
     - 70
     - 72
     - 75
     - 76
     - 78
     - 80
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_control_cooling_season_period``
     - 
     - Enter a date range like 'Jun 1 - Oct 31'. Defaults to year-round cooling availability.
   * - ``hvac_control_cooling_weekday_setpoint_temp``
     - deg-F
     - Specify the weekday cooling setpoint temperature.
   * - ``hvac_control_cooling_weekend_setpoint_temp``
     - deg-F
     - Specify the weekend cooling setpoint temperature.
.. _cooling_setpoint_has_offset:

Cooling Setpoint Has Offset
---------------------------

Description
***********

Presence of a cooling setpoint offset.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Cooling Setpoint Has Offset** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - No
     - Yes
   * - Stock saturation
     - 64%
     - 36%

.. _cooling_setpoint_offset_magnitude:

Cooling Setpoint Offset Magnitude
---------------------------------

Description
***********

The magnitude of cooling setpoint offset.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B and separately 7AK and 8AK regions


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Cooling Setpoint Offset Magnitude** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0F
     - 2F
     - 5F
     - 9F
   * - Stock saturation
     - 64%
     - 21%
     - 10%
     - 5%
   * - ``hvac_control_cooling_weekday_setpoint_offset_magnitude``
     - 0
     - 2
     - 5
     - 9
   * - ``hvac_control_cooling_weekend_setpoint_offset_magnitude``
     - 0
     - 2
     - 5
     - 9

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_control_cooling_weekday_setpoint_offset_magnitude``
     - deg-F
     - Specify the weekday cooling offset magnitude.
   * - ``hvac_control_cooling_weekend_setpoint_offset_magnitude``
     - deg-F
     - Specify the weekend cooling offset magnitude.
.. _cooling_setpoint_offset_period:

Cooling Setpoint Offset Period
------------------------------

Description
***********

The period and offset for the dwelling unit's cooling setpoint. Default for the day is from 9am to 5pm and for the night is 10pm to 7am.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Cooling Setpoint Offset Period** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Day and Night Setup
     - Day and Night Setup -1h
     - Day and Night Setup -2h
     - Day and Night Setup -3h
     - Day and Night Setup -4h
     - Day and Night Setup -5h
     - Day and Night Setup +1h
     - Day and Night Setup +2h
     - Day and Night Setup +3h
     - Day and Night Setup +4h
     - Day and Night Setup +5h
     - Day Setup
     - Day Setup -1h
     - Day Setup -2h
     - Day Setup -3h
     - Day Setup -4h
     - Day Setup -5h
     - Day Setup +1h
     - Day Setup +2h
     - Day Setup +3h
     - Day Setup +4h
     - Day Setup +5h
     - Day Setup and Night Setback
     - Day Setup and Night Setback -1h
     - Day Setup and Night Setback -2h
     - Day Setup and Night Setback -3h
     - Day Setup and Night Setback -4h
     - Day Setup and Night Setback -5h
     - Day Setup and Night Setback +1h
     - Day Setup and Night Setback +2h
     - Day Setup and Night Setback +3h
     - Day Setup and Night Setback +4h
     - Day Setup and Night Setback +5h
     - Night Setback
     - Night Setback -1h
     - Night Setback -2h
     - Night Setback -3h
     - Night Setback -4h
     - Night Setback -5h
     - Night Setback +1h
     - Night Setback +2h
     - Night Setback +3h
     - Night Setback +4h
     - Night Setback +5h
     - Night Setup
     - Night Setup -1h
     - Night Setup -2h
     - Night Setup -3h
     - Night Setup -4h
     - Night Setup -5h
     - Night Setup +1h
     - Night Setup +2h
     - Night Setup +3h
     - Night Setup +4h
     - Night Setup +5h
     - None
   * - Stock saturation
     - 0.091%
     - 0.091%
     - 0.091%
     - 0.091%
     - 0.091%
     - 0.091%
     - 0.091%
     - 0.091%
     - 0.091%
     - 0.091%
     - 0.091%
     - 0.28%
     - 0.28%
     - 0.28%
     - 0.28%
     - 0.28%
     - 0.28%
     - 0.28%
     - 0.28%
     - 0.28%
     - 0.28%
     - 0.28%
     - 0.21%
     - 0.21%
     - 0.21%
     - 0.21%
     - 0.21%
     - 0.21%
     - 0.21%
     - 0.21%
     - 0.21%
     - 0.21%
     - 0.21%
     - 2%
     - 2%
     - 2%
     - 2%
     - 2%
     - 2%
     - 2%
     - 2%
     - 2%
     - 2%
     - 2%
     - 0.65%
     - 0.65%
     - 0.65%
     - 0.65%
     - 0.65%
     - 0.65%
     - 0.65%
     - 0.65%
     - 0.65%
     - 0.65%
     - 0.65%
     - 64%
   * - ``hvac_control_cooling_weekday_setpoint_schedule``
     - 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1
     - 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1
     - 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1
     - 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1
     - 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1
     - 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1
     - 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1
     - 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
     - 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0
     - 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0
     - 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0
     - -1, -1, -1, -1, -1, -1, -1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, -1, -1
     - -1, -1, -1, -1, -1, -1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, -1, -1, -1
     - -1, -1, -1, -1, -1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, -1, -1, -1, -1
     - -1, -1, -1, -1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1
     - -1, -1, -1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1
     - -1, -1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
     - 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0
     - 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0
     - 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0
     - -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1
     - -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1
     - -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1
     - -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1
     - -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1
     - -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1
     - 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1
     - 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1
     - 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1
     - 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1
     - 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1
     - 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
     - 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
   * - ``hvac_control_cooling_weekend_setpoint_schedule``
     - 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1
     - 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1
     - 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1
     - 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1
     - 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1
     - 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1
     - 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
     - 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1
     - -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1
     - -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1
     - -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1
     - -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1
     - -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1
     - -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1
     - -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1
     - -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1
     - -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1
     - -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1
     - 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1
     - 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1
     - 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1
     - 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1
     - 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1
     - 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
     - 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_control_cooling_weekday_setpoint_schedule``
     - 
     - Specify the 24-hour comma-separated weekday cooling schedule of 0s and 1s.
   * - ``hvac_control_cooling_weekend_setpoint_schedule``
     - 
     - Specify the 24-hour comma-separated weekend cooling schedule of 0s and 1s.
.. _cooling_unavailable_days:

Cooling Unavailable Days
------------------------

Description
***********

Number of days in a year the cooling system is unavailable.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Cooling Unavailable Days** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 1 day
     - 1 month
     - 1 week
     - 2 weeks
     - 3 days
     - 3 months
     - Never
     - Year round
     - Void
   * - Stock saturation
     - 0.64%
     - 0.95%
     - 0.87%
     - 0.74%
     - 1.1%
     - 0.61%
     - 95%
     - 0.23%
     - 0%
   * - ``schedules_space_cooling_unavailable_days``
     - 1
     - 30
     - 7
     - 14
     - 3
     - 90
     - 0
     - 365
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``schedules_space_cooling_unavailable_days``
     - 
     - Number of days space cooling equipment is unavailable.
.. _corridor:

Corridor
--------

Description
***********

Type of corridor attached to multi-family units.

Created by
**********

manually created

Source
******

- \Engineering Judgment


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Corridor** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Not Applicable
     - Double-Loaded Interior
     - None
     - Single Exterior Front
     - Double Exterior
   * - Stock saturation
     - 74%
     - 26%
     - 0%
     - 0%
     - 0%
   * - ``geometry_corridor_position``
     - None
     - Double-Loaded Interior
     - None
     - Single Exterior Front
     - Double Exterior

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_corridor_position``
     - 
     - The position of the corridor. Only applies to single-family attached and apartment units. Exterior corridors are shaded, but not enclosed. Interior corridors are enclosed and conditioned.
.. _county:

County
------

Description
***********

The U.S. County that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **County** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - AK, Aleutians East Borough
     - AK, Aleutians West Census Area
     - AK, Anchorage Municipality
     - AK, Bethel Census Area
     - AK, Bristol Bay Borough
     - AK, Denali Borough
     - AK, Dillingham Census Area
     - AK, Fairbanks North Star Borough
     - AK, Haines Borough
     - AK, Hoonah-Angoon Census Area
     - AK, Juneau City and Borough
     - AK, Kenai Peninsula Borough
     - AK, Ketchikan Gateway Borough
     - AK, Kodiak Island Borough
     - AK, Kusilvak Census Area
     - AK, Lake and Peninsula Borough
     - AK, Matanuska-Susitna Borough
     - AK, Nome Census Area
     - AK, North Slope Borough
     - AK, Northwest Arctic Borough
     - AK, Petersburg Borough
     - AK, Prince of Wales-Hyder Census Area
     - AK, Sitka City and Borough
     - AK, Skagway Municipality
     - AK, Southeast Fairbanks Census Area
     - AK, Valdez-Cordova Census Area
     - AK, Wrangell City and Borough
     - AK, Yakutat City and Borough
     - AK, Yukon-Koyukuk Census Area
     - AL, Autauga County
     - AL, Baldwin County
     - AL, Barbour County
     - AL, Bibb County
     - AL, Blount County
     - AL, Bullock County
     - AL, Butler County
     - AL, Calhoun County
     - AL, Chambers County
     - AL, Cherokee County
     - AL, Chilton County
     - AL, Choctaw County
     - AL, Clarke County
     - AL, Clay County
     - AL, Cleburne County
     - AL, Coffee County
     - AL, Colbert County
     - AL, Conecuh County
     - AL, Coosa County
     - AL, Covington County
     - AL, Crenshaw County
     - AL, Cullman County
     - AL, Dale County
     - AL, Dallas County
     - AL, DeKalb County
     - AL, Elmore County
     - AL, Escambia County
     - AL, Etowah County
     - AL, Fayette County
     - AL, Franklin County
     - AL, Geneva County
     - AL, Greene County
     - AL, Hale County
     - AL, Henry County
     - AL, Houston County
     - AL, Jackson County
     - AL, Jefferson County
     - AL, Lamar County
     - AL, Lauderdale County
     - AL, Lawrence County
     - AL, Lee County
     - AL, Limestone County
     - AL, Lowndes County
     - AL, Macon County
     - AL, Madison County
     - AL, Marengo County
     - AL, Marion County
     - AL, Marshall County
     - AL, Mobile County
     - AL, Monroe County
     - AL, Montgomery County
     - AL, Morgan County
     - AL, Perry County
     - AL, Pickens County
     - AL, Pike County
     - AL, Randolph County
     - AL, Russell County
     - AL, Shelby County
     - AL, St. Clair County
     - AL, Sumter County
     - AL, Talladega County
     - AL, Tallapoosa County
     - AL, Tuscaloosa County
     - AL, Walker County
     - AL, Washington County
     - AL, Wilcox County
     - AL, Winston County
     - AR, Arkansas County
     - AR, Ashley County
     - AR, Baxter County
     - AR, Benton County
     - AR, Boone County
     - AR, Bradley County
     - AR, Calhoun County
     - AR, Carroll County
     - AR, Chicot County
     - AR, Clark County
     - AR, Clay County
     - AR, Cleburne County
     - AR, Cleveland County
     - AR, Columbia County
     - AR, Conway County
     - AR, Craighead County
     - AR, Crawford County
     - AR, Crittenden County
     - AR, Cross County
     - AR, Dallas County
     - AR, Desha County
     - AR, Drew County
     - AR, Faulkner County
     - AR, Franklin County
     - AR, Fulton County
     - AR, Garland County
     - AR, Grant County
     - AR, Greene County
     - AR, Hempstead County
     - AR, Hot Spring County
     - AR, Howard County
     - AR, Independence County
     - AR, Izard County
     - AR, Jackson County
     - AR, Jefferson County
     - AR, Johnson County
     - AR, Lafayette County
     - AR, Lawrence County
     - AR, Lee County
     - AR, Lincoln County
     - AR, Little River County
     - AR, Logan County
     - AR, Lonoke County
     - AR, Madison County
     - AR, Marion County
     - AR, Miller County
     - AR, Mississippi County
     - AR, Monroe County
     - AR, Montgomery County
     - AR, Nevada County
     - AR, Newton County
     - AR, Ouachita County
     - AR, Perry County
     - AR, Phillips County
     - AR, Pike County
     - AR, Poinsett County
     - AR, Polk County
     - AR, Pope County
     - AR, Prairie County
     - AR, Pulaski County
     - AR, Randolph County
     - AR, Saline County
     - AR, Scott County
     - AR, Searcy County
     - AR, Sebastian County
     - AR, Sevier County
     - AR, Sharp County
     - AR, St. Francis County
     - AR, Stone County
     - AR, Union County
     - AR, Van Buren County
     - AR, Washington County
     - AR, White County
     - AR, Woodruff County
     - AR, Yell County
     - AZ, Apache County
     - AZ, Cochise County
     - AZ, Coconino County
     - AZ, Gila County
     - AZ, Graham County
     - AZ, Greenlee County
     - AZ, La Paz County
     - AZ, Maricopa County
     - AZ, Mohave County
     - AZ, Navajo County
     - AZ, Pima County
     - AZ, Pinal County
     - AZ, Santa Cruz County
     - AZ, Yavapai County
     - AZ, Yuma County
     - CA, Alameda County
     - CA, Alpine County
     - CA, Amador County
     - CA, Butte County
     - CA, Calaveras County
     - CA, Colusa County
     - CA, Contra Costa County
     - CA, Del Norte County
     - CA, El Dorado County
     - CA, Fresno County
     - CA, Glenn County
     - CA, Humboldt County
     - CA, Imperial County
     - CA, Inyo County
     - CA, Kern County
     - CA, Kings County
     - CA, Lake County
     - CA, Lassen County
     - CA, Los Angeles County
     - CA, Madera County
     - CA, Marin County
     - CA, Mariposa County
     - CA, Mendocino County
     - CA, Merced County
     - CA, Modoc County
     - CA, Mono County
     - CA, Monterey County
     - CA, Napa County
     - CA, Nevada County
     - CA, Orange County
     - CA, Placer County
     - CA, Plumas County
     - CA, Riverside County
     - CA, Sacramento County
     - CA, San Benito County
     - CA, San Bernardino County
     - CA, San Diego County
     - CA, San Francisco County
     - CA, San Joaquin County
     - CA, San Luis Obispo County
     - CA, San Mateo County
     - CA, Santa Barbara County
     - CA, Santa Clara County
     - CA, Santa Cruz County
     - CA, Shasta County
     - CA, Sierra County
     - CA, Siskiyou County
     - CA, Solano County
     - CA, Sonoma County
     - CA, Stanislaus County
     - CA, Sutter County
     - CA, Tehama County
     - CA, Trinity County
     - CA, Tulare County
     - CA, Tuolumne County
     - CA, Ventura County
     - CA, Yolo County
     - CA, Yuba County
     - CO, Adams County
     - CO, Alamosa County
     - CO, Arapahoe County
     - CO, Archuleta County
     - CO, Baca County
     - CO, Bent County
     - CO, Boulder County
     - CO, Broomfield County
     - CO, Chaffee County
     - CO, Cheyenne County
     - CO, Clear Creek County
     - CO, Conejos County
     - CO, Costilla County
     - CO, Crowley County
     - CO, Custer County
     - CO, Delta County
     - CO, Denver County
     - CO, Dolores County
     - CO, Douglas County
     - CO, Eagle County
     - CO, El Paso County
     - CO, Elbert County
     - CO, Fremont County
     - CO, Garfield County
     - CO, Gilpin County
     - CO, Grand County
     - CO, Gunnison County
     - CO, Hinsdale County
     - CO, Huerfano County
     - CO, Jackson County
     - CO, Jefferson County
     - CO, Kiowa County
     - CO, Kit Carson County
     - CO, La Plata County
     - CO, Lake County
     - CO, Larimer County
     - CO, Las Animas County
     - CO, Lincoln County
     - CO, Logan County
     - CO, Mesa County
     - CO, Mineral County
     - CO, Moffat County
     - CO, Montezuma County
     - CO, Montrose County
     - CO, Morgan County
     - CO, Otero County
     - CO, Ouray County
     - CO, Park County
     - CO, Phillips County
     - CO, Pitkin County
     - CO, Prowers County
     - CO, Pueblo County
     - CO, Rio Blanco County
     - CO, Rio Grande County
     - CO, Routt County
     - CO, Saguache County
     - CO, San Juan County
     - CO, San Miguel County
     - CO, Sedgwick County
     - CO, Summit County
     - CO, Teller County
     - CO, Washington County
     - CO, Weld County
     - CO, Yuma County
     - CT, Fairfield County
     - CT, Hartford County
     - CT, Litchfield County
     - CT, Middlesex County
     - CT, New Haven County
     - CT, New London County
     - CT, Tolland County
     - CT, Windham County
     - DC, District of Columbia
     - DE, Kent County
     - DE, New Castle County
     - DE, Sussex County
     - FL, Alachua County
     - FL, Baker County
     - FL, Bay County
     - FL, Bradford County
     - FL, Brevard County
     - FL, Broward County
     - FL, Calhoun County
     - FL, Charlotte County
     - FL, Citrus County
     - FL, Clay County
     - FL, Collier County
     - FL, Columbia County
     - FL, DeSoto County
     - FL, Dixie County
     - FL, Duval County
     - FL, Escambia County
     - FL, Flagler County
     - FL, Franklin County
     - FL, Gadsden County
     - FL, Gilchrist County
     - FL, Glades County
     - FL, Gulf County
     - FL, Hamilton County
     - FL, Hardee County
     - FL, Hendry County
     - FL, Hernando County
     - FL, Highlands County
     - FL, Hillsborough County
     - FL, Holmes County
     - FL, Indian River County
     - FL, Jackson County
     - FL, Jefferson County
     - FL, Lafayette County
     - FL, Lake County
     - FL, Lee County
     - FL, Leon County
     - FL, Levy County
     - FL, Liberty County
     - FL, Madison County
     - FL, Manatee County
     - FL, Marion County
     - FL, Martin County
     - FL, Miami-Dade County
     - FL, Monroe County
     - FL, Nassau County
     - FL, Okaloosa County
     - FL, Okeechobee County
     - FL, Orange County
     - FL, Osceola County
     - FL, Palm Beach County
     - FL, Pasco County
     - FL, Pinellas County
     - FL, Polk County
     - FL, Putnam County
     - FL, Santa Rosa County
     - FL, Sarasota County
     - FL, Seminole County
     - FL, St. Johns County
     - FL, St. Lucie County
     - FL, Sumter County
     - FL, Suwannee County
     - FL, Taylor County
     - FL, Union County
     - FL, Volusia County
     - FL, Wakulla County
     - FL, Walton County
     - FL, Washington County
     - GA, Appling County
     - GA, Atkinson County
     - GA, Bacon County
     - GA, Baker County
     - GA, Baldwin County
     - GA, Banks County
     - GA, Barrow County
     - GA, Bartow County
     - GA, Ben Hill County
     - GA, Berrien County
     - GA, Bibb County
     - GA, Bleckley County
     - GA, Brantley County
     - GA, Brooks County
     - GA, Bryan County
     - GA, Bulloch County
     - GA, Burke County
     - GA, Butts County
     - GA, Calhoun County
     - GA, Camden County
     - GA, Candler County
     - GA, Carroll County
     - GA, Catoosa County
     - GA, Charlton County
     - GA, Chatham County
     - GA, Chattahoochee County
     - GA, Chattooga County
     - GA, Cherokee County
     - GA, Clarke County
     - GA, Clay County
     - GA, Clayton County
     - GA, Clinch County
     - GA, Cobb County
     - GA, Coffee County
     - GA, Colquitt County
     - GA, Columbia County
     - GA, Cook County
     - GA, Coweta County
     - GA, Crawford County
     - GA, Crisp County
     - GA, Dade County
     - GA, Dawson County
     - GA, Decatur County
     - GA, DeKalb County
     - GA, Dodge County
     - GA, Dooly County
     - GA, Dougherty County
     - GA, Douglas County
     - GA, Early County
     - GA, Echols County
     - GA, Effingham County
     - GA, Elbert County
     - GA, Emanuel County
     - GA, Evans County
     - GA, Fannin County
     - GA, Fayette County
     - GA, Floyd County
     - GA, Forsyth County
     - GA, Franklin County
     - GA, Fulton County
     - GA, Gilmer County
     - GA, Glascock County
     - GA, Glynn County
     - GA, Gordon County
     - GA, Grady County
     - GA, Greene County
     - GA, Gwinnett County
     - GA, Habersham County
     - GA, Hall County
     - GA, Hancock County
     - GA, Haralson County
     - GA, Harris County
     - GA, Hart County
     - GA, Heard County
     - GA, Henry County
     - GA, Houston County
     - GA, Irwin County
     - GA, Jackson County
     - GA, Jasper County
     - GA, Jeff Davis County
     - GA, Jefferson County
     - GA, Jenkins County
     - GA, Johnson County
     - GA, Jones County
     - GA, Lamar County
     - GA, Lanier County
     - GA, Laurens County
     - GA, Lee County
     - GA, Liberty County
     - GA, Lincoln County
     - GA, Long County
     - GA, Lowndes County
     - GA, Lumpkin County
     - GA, Macon County
     - GA, Madison County
     - GA, Marion County
     - GA, McDuffie County
     - GA, McIntosh County
     - GA, Meriwether County
     - GA, Miller County
     - GA, Mitchell County
     - GA, Monroe County
     - GA, Montgomery County
     - GA, Morgan County
     - GA, Murray County
     - GA, Muscogee County
     - GA, Newton County
     - GA, Oconee County
     - GA, Oglethorpe County
     - GA, Paulding County
     - GA, Peach County
     - GA, Pickens County
     - GA, Pierce County
     - GA, Pike County
     - GA, Polk County
     - GA, Pulaski County
     - GA, Putnam County
     - GA, Quitman County
     - GA, Rabun County
     - GA, Randolph County
     - GA, Richmond County
     - GA, Rockdale County
     - GA, Schley County
     - GA, Screven County
     - GA, Seminole County
     - GA, Spalding County
     - GA, Stephens County
     - GA, Stewart County
     - GA, Sumter County
     - GA, Talbot County
     - GA, Taliaferro County
     - GA, Tattnall County
     - GA, Taylor County
     - GA, Telfair County
     - GA, Terrell County
     - GA, Thomas County
     - GA, Tift County
     - GA, Toombs County
     - GA, Towns County
     - GA, Treutlen County
     - GA, Troup County
     - GA, Turner County
     - GA, Twiggs County
     - GA, Union County
     - GA, Upson County
     - GA, Walker County
     - GA, Walton County
     - GA, Ware County
     - GA, Warren County
     - GA, Washington County
     - GA, Wayne County
     - GA, Webster County
     - GA, Wheeler County
     - GA, White County
     - GA, Whitfield County
     - GA, Wilcox County
     - GA, Wilkes County
     - GA, Wilkinson County
     - GA, Worth County
     - HI, Hawaii County
     - HI, Honolulu County
     - HI, Kalawao County
     - HI, Kauai County
     - HI, Maui County
     - IA, Adair County
     - IA, Adams County
     - IA, Allamakee County
     - IA, Appanoose County
     - IA, Audubon County
     - IA, Benton County
     - IA, Black Hawk County
     - IA, Boone County
     - IA, Bremer County
     - IA, Buchanan County
     - IA, Buena Vista County
     - IA, Butler County
     - IA, Calhoun County
     - IA, Carroll County
     - IA, Cass County
     - IA, Cedar County
     - IA, Cerro Gordo County
     - IA, Cherokee County
     - IA, Chickasaw County
     - IA, Clarke County
     - IA, Clay County
     - IA, Clayton County
     - IA, Clinton County
     - IA, Crawford County
     - IA, Dallas County
     - IA, Davis County
     - IA, Decatur County
     - IA, Delaware County
     - IA, Des Moines County
     - IA, Dickinson County
     - IA, Dubuque County
     - IA, Emmet County
     - IA, Fayette County
     - IA, Floyd County
     - IA, Franklin County
     - IA, Fremont County
     - IA, Greene County
     - IA, Grundy County
     - IA, Guthrie County
     - IA, Hamilton County
     - IA, Hancock County
     - IA, Hardin County
     - IA, Harrison County
     - IA, Henry County
     - IA, Howard County
     - IA, Humboldt County
     - IA, Ida County
     - IA, Iowa County
     - IA, Jackson County
     - IA, Jasper County
     - IA, Jefferson County
     - IA, Johnson County
     - IA, Jones County
     - IA, Keokuk County
     - IA, Kossuth County
     - IA, Lee County
     - IA, Linn County
     - IA, Louisa County
     - IA, Lucas County
     - IA, Lyon County
     - IA, Madison County
     - IA, Mahaska County
     - IA, Marion County
     - IA, Marshall County
     - IA, Mills County
     - IA, Mitchell County
     - IA, Monona County
     - IA, Monroe County
     - IA, Montgomery County
     - IA, Muscatine County
     - IA, O'Brien County
     - IA, Osceola County
     - IA, Page County
     - IA, Palo Alto County
     - IA, Plymouth County
     - IA, Pocahontas County
     - IA, Polk County
     - IA, Pottawattamie County
     - IA, Poweshiek County
     - IA, Ringgold County
     - IA, Sac County
     - IA, Scott County
     - IA, Shelby County
     - IA, Sioux County
     - IA, Story County
     - IA, Tama County
     - IA, Taylor County
     - IA, Union County
     - IA, Van Buren County
     - IA, Wapello County
     - IA, Warren County
     - IA, Washington County
     - IA, Wayne County
     - IA, Webster County
     - IA, Winnebago County
     - IA, Winneshiek County
     - IA, Woodbury County
     - IA, Worth County
     - IA, Wright County
     - ID, Ada County
     - ID, Adams County
     - ID, Bannock County
     - ID, Bear Lake County
     - ID, Benewah County
     - ID, Bingham County
     - ID, Blaine County
     - ID, Boise County
     - ID, Bonner County
     - ID, Bonneville County
     - ID, Boundary County
     - ID, Butte County
     - ID, Camas County
     - ID, Canyon County
     - ID, Caribou County
     - ID, Cassia County
     - ID, Clark County
     - ID, Clearwater County
     - ID, Custer County
     - ID, Elmore County
     - ID, Franklin County
     - ID, Fremont County
     - ID, Gem County
     - ID, Gooding County
     - ID, Idaho County
     - ID, Jefferson County
     - ID, Jerome County
     - ID, Kootenai County
     - ID, Latah County
     - ID, Lemhi County
     - ID, Lewis County
     - ID, Lincoln County
     - ID, Madison County
     - ID, Minidoka County
     - ID, Nez Perce County
     - ID, Oneida County
     - ID, Owyhee County
     - ID, Payette County
     - ID, Power County
     - ID, Shoshone County
     - ID, Teton County
     - ID, Twin Falls County
     - ID, Valley County
     - ID, Washington County
     - IL, Adams County
     - IL, Alexander County
     - IL, Bond County
     - IL, Boone County
     - IL, Brown County
     - IL, Bureau County
     - IL, Calhoun County
     - IL, Carroll County
     - IL, Cass County
     - IL, Champaign County
     - IL, Christian County
     - IL, Clark County
     - IL, Clay County
     - IL, Clinton County
     - IL, Coles County
     - IL, Cook County
     - IL, Crawford County
     - IL, Cumberland County
     - IL, De Witt County
     - IL, DeKalb County
     - IL, Douglas County
     - IL, DuPage County
     - IL, Edgar County
     - IL, Edwards County
     - IL, Effingham County
     - IL, Fayette County
     - IL, Ford County
     - IL, Franklin County
     - IL, Fulton County
     - IL, Gallatin County
     - IL, Greene County
     - IL, Grundy County
     - IL, Hamilton County
     - IL, Hancock County
     - IL, Hardin County
     - IL, Henderson County
     - IL, Henry County
     - IL, Iroquois County
     - IL, Jackson County
     - IL, Jasper County
     - IL, Jefferson County
     - IL, Jersey County
     - IL, Jo Daviess County
     - IL, Johnson County
     - IL, Kane County
     - IL, Kankakee County
     - IL, Kendall County
     - IL, Knox County
     - IL, Lake County
     - IL, LaSalle County
     - IL, Lawrence County
     - IL, Lee County
     - IL, Livingston County
     - IL, Logan County
     - IL, Macon County
     - IL, Macoupin County
     - IL, Madison County
     - IL, Marion County
     - IL, Marshall County
     - IL, Mason County
     - IL, Massac County
     - IL, McDonough County
     - IL, McHenry County
     - IL, McLean County
     - IL, Menard County
     - IL, Mercer County
     - IL, Monroe County
     - IL, Montgomery County
     - IL, Morgan County
     - IL, Moultrie County
     - IL, Ogle County
     - IL, Peoria County
     - IL, Perry County
     - IL, Piatt County
     - IL, Pike County
     - IL, Pope County
     - IL, Pulaski County
     - IL, Putnam County
     - IL, Randolph County
     - IL, Richland County
     - IL, Rock Island County
     - IL, Saline County
     - IL, Sangamon County
     - IL, Schuyler County
     - IL, Scott County
     - IL, Shelby County
     - IL, St. Clair County
     - IL, Stark County
     - IL, Stephenson County
     - IL, Tazewell County
     - IL, Union County
     - IL, Vermilion County
     - IL, Wabash County
     - IL, Warren County
     - IL, Washington County
     - IL, Wayne County
     - IL, White County
     - IL, Whiteside County
     - IL, Will County
     - IL, Williamson County
     - IL, Winnebago County
     - IL, Woodford County
     - IN, Adams County
     - IN, Allen County
     - IN, Bartholomew County
     - IN, Benton County
     - IN, Blackford County
     - IN, Boone County
     - IN, Brown County
     - IN, Carroll County
     - IN, Cass County
     - IN, Clark County
     - IN, Clay County
     - IN, Clinton County
     - IN, Crawford County
     - IN, Daviess County
     - IN, Dearborn County
     - IN, Decatur County
     - IN, DeKalb County
     - IN, Delaware County
     - IN, Dubois County
     - IN, Elkhart County
     - IN, Fayette County
     - IN, Floyd County
     - IN, Fountain County
     - IN, Franklin County
     - IN, Fulton County
     - IN, Gibson County
     - IN, Grant County
     - IN, Greene County
     - IN, Hamilton County
     - IN, Hancock County
     - IN, Harrison County
     - IN, Hendricks County
     - IN, Henry County
     - IN, Howard County
     - IN, Huntington County
     - IN, Jackson County
     - IN, Jasper County
     - IN, Jay County
     - IN, Jefferson County
     - IN, Jennings County
     - IN, Johnson County
     - IN, Knox County
     - IN, Kosciusko County
     - IN, LaGrange County
     - IN, Lake County
     - IN, LaPorte County
     - IN, Lawrence County
     - IN, Madison County
     - IN, Marion County
     - IN, Marshall County
     - IN, Martin County
     - IN, Miami County
     - IN, Monroe County
     - IN, Montgomery County
     - IN, Morgan County
     - IN, Newton County
     - IN, Noble County
     - IN, Ohio County
     - IN, Orange County
     - IN, Owen County
     - IN, Parke County
     - IN, Perry County
     - IN, Pike County
     - IN, Porter County
     - IN, Posey County
     - IN, Pulaski County
     - IN, Putnam County
     - IN, Randolph County
     - IN, Ripley County
     - IN, Rush County
     - IN, Scott County
     - IN, Shelby County
     - IN, Spencer County
     - IN, St. Joseph County
     - IN, Starke County
     - IN, Steuben County
     - IN, Sullivan County
     - IN, Switzerland County
     - IN, Tippecanoe County
     - IN, Tipton County
     - IN, Union County
     - IN, Vanderburgh County
     - IN, Vermillion County
     - IN, Vigo County
     - IN, Wabash County
     - IN, Warren County
     - IN, Warrick County
     - IN, Washington County
     - IN, Wayne County
     - IN, Wells County
     - IN, White County
     - IN, Whitley County
     - KS, Allen County
     - KS, Anderson County
     - KS, Atchison County
     - KS, Barber County
     - KS, Barton County
     - KS, Bourbon County
     - KS, Brown County
     - KS, Butler County
     - KS, Chase County
     - KS, Chautauqua County
     - KS, Cherokee County
     - KS, Cheyenne County
     - KS, Clark County
     - KS, Clay County
     - KS, Cloud County
     - KS, Coffey County
     - KS, Comanche County
     - KS, Cowley County
     - KS, Crawford County
     - KS, Decatur County
     - KS, Dickinson County
     - KS, Doniphan County
     - KS, Douglas County
     - KS, Edwards County
     - KS, Elk County
     - KS, Ellis County
     - KS, Ellsworth County
     - KS, Finney County
     - KS, Ford County
     - KS, Franklin County
     - KS, Geary County
     - KS, Gove County
     - KS, Graham County
     - KS, Grant County
     - KS, Gray County
     - KS, Greeley County
     - KS, Greenwood County
     - KS, Hamilton County
     - KS, Harper County
     - KS, Harvey County
     - KS, Haskell County
     - KS, Hodgeman County
     - KS, Jackson County
     - KS, Jefferson County
     - KS, Jewell County
     - KS, Johnson County
     - KS, Kearny County
     - KS, Kingman County
     - KS, Kiowa County
     - KS, Labette County
     - KS, Lane County
     - KS, Leavenworth County
     - KS, Lincoln County
     - KS, Linn County
     - KS, Logan County
     - KS, Lyon County
     - KS, Marion County
     - KS, Marshall County
     - KS, McPherson County
     - KS, Meade County
     - KS, Miami County
     - KS, Mitchell County
     - KS, Montgomery County
     - KS, Morris County
     - KS, Morton County
     - KS, Nemaha County
     - KS, Neosho County
     - KS, Ness County
     - KS, Norton County
     - KS, Osage County
     - KS, Osborne County
     - KS, Ottawa County
     - KS, Pawnee County
     - KS, Phillips County
     - KS, Pottawatomie County
     - KS, Pratt County
     - KS, Rawlins County
     - KS, Reno County
     - KS, Republic County
     - KS, Rice County
     - KS, Riley County
     - KS, Rooks County
     - KS, Rush County
     - KS, Russell County
     - KS, Saline County
     - KS, Scott County
     - KS, Sedgwick County
     - KS, Seward County
     - KS, Shawnee County
     - KS, Sheridan County
     - KS, Sherman County
     - KS, Smith County
     - KS, Stafford County
     - KS, Stanton County
     - KS, Stevens County
     - KS, Sumner County
     - KS, Thomas County
     - KS, Trego County
     - KS, Wabaunsee County
     - KS, Wallace County
     - KS, Washington County
     - KS, Wichita County
     - KS, Wilson County
     - KS, Woodson County
     - KS, Wyandotte County
     - KY, Adair County
     - KY, Allen County
     - KY, Anderson County
     - KY, Ballard County
     - KY, Barren County
     - KY, Bath County
     - KY, Bell County
     - KY, Boone County
     - KY, Bourbon County
     - KY, Boyd County
     - KY, Boyle County
     - KY, Bracken County
     - KY, Breathitt County
     - KY, Breckinridge County
     - KY, Bullitt County
     - KY, Butler County
     - KY, Caldwell County
     - KY, Calloway County
     - KY, Campbell County
     - KY, Carlisle County
     - KY, Carroll County
     - KY, Carter County
     - KY, Casey County
     - KY, Christian County
     - KY, Clark County
     - KY, Clay County
     - KY, Clinton County
     - KY, Crittenden County
     - KY, Cumberland County
     - KY, Daviess County
     - KY, Edmonson County
     - KY, Elliott County
     - KY, Estill County
     - KY, Fayette County
     - KY, Fleming County
     - KY, Floyd County
     - KY, Franklin County
     - KY, Fulton County
     - KY, Gallatin County
     - KY, Garrard County
     - KY, Grant County
     - KY, Graves County
     - KY, Grayson County
     - KY, Green County
     - KY, Greenup County
     - KY, Hancock County
     - KY, Hardin County
     - KY, Harlan County
     - KY, Harrison County
     - KY, Hart County
     - KY, Henderson County
     - KY, Henry County
     - KY, Hickman County
     - KY, Hopkins County
     - KY, Jackson County
     - KY, Jefferson County
     - KY, Jessamine County
     - KY, Johnson County
     - KY, Kenton County
     - KY, Knott County
     - KY, Knox County
     - KY, Larue County
     - KY, Laurel County
     - KY, Lawrence County
     - KY, Lee County
     - KY, Leslie County
     - KY, Letcher County
     - KY, Lewis County
     - KY, Lincoln County
     - KY, Livingston County
     - KY, Logan County
     - KY, Lyon County
     - KY, Madison County
     - KY, Magoffin County
     - KY, Marion County
     - KY, Marshall County
     - KY, Martin County
     - KY, Mason County
     - KY, McCracken County
     - KY, McCreary County
     - KY, McLean County
     - KY, Meade County
     - KY, Menifee County
     - KY, Mercer County
     - KY, Metcalfe County
     - KY, Monroe County
     - KY, Montgomery County
     - KY, Morgan County
     - KY, Muhlenberg County
     - KY, Nelson County
     - KY, Nicholas County
     - KY, Ohio County
     - KY, Oldham County
     - KY, Owen County
     - KY, Owsley County
     - KY, Pendleton County
     - KY, Perry County
     - KY, Pike County
     - KY, Powell County
     - KY, Pulaski County
     - KY, Robertson County
     - KY, Rockcastle County
     - KY, Rowan County
     - KY, Russell County
     - KY, Scott County
     - KY, Shelby County
     - KY, Simpson County
     - KY, Spencer County
     - KY, Taylor County
     - KY, Todd County
     - KY, Trigg County
     - KY, Trimble County
     - KY, Union County
     - KY, Warren County
     - KY, Washington County
     - KY, Wayne County
     - KY, Webster County
     - KY, Whitley County
     - KY, Wolfe County
     - KY, Woodford County
     - LA, Acadia Parish
     - LA, Allen Parish
     - LA, Ascension Parish
     - LA, Assumption Parish
     - LA, Avoyelles Parish
     - LA, Beauregard Parish
     - LA, Bienville Parish
     - LA, Bossier Parish
     - LA, Caddo Parish
     - LA, Calcasieu Parish
     - LA, Caldwell Parish
     - LA, Cameron Parish
     - LA, Catahoula Parish
     - LA, Claiborne Parish
     - LA, Concordia Parish
     - LA, De Soto Parish
     - LA, East Baton Rouge Parish
     - LA, East Carroll Parish
     - LA, East Feliciana Parish
     - LA, Evangeline Parish
     - LA, Franklin Parish
     - LA, Grant Parish
     - LA, Iberia Parish
     - LA, Iberville Parish
     - LA, Jackson Parish
     - LA, Jefferson Davis Parish
     - LA, Jefferson Parish
     - LA, La Salle Parish
     - LA, Lafayette Parish
     - LA, Lafourche Parish
     - LA, Lincoln Parish
     - LA, Livingston Parish
     - LA, Madison Parish
     - LA, Morehouse Parish
     - LA, Natchitoches Parish
     - LA, Orleans Parish
     - LA, Ouachita Parish
     - LA, Plaquemines Parish
     - LA, Pointe Coupee Parish
     - LA, Rapides Parish
     - LA, Red River Parish
     - LA, Richland Parish
     - LA, Sabine Parish
     - LA, St. Bernard Parish
     - LA, St. Charles Parish
     - LA, St. Helena Parish
     - LA, St. James Parish
     - LA, St. John the Baptist Parish
     - LA, St. Landry Parish
     - LA, St. Martin Parish
     - LA, St. Mary Parish
     - LA, St. Tammany Parish
     - LA, Tangipahoa Parish
     - LA, Tensas Parish
     - LA, Terrebonne Parish
     - LA, Union Parish
     - LA, Vermilion Parish
     - LA, Vernon Parish
     - LA, Washington Parish
     - LA, Webster Parish
     - LA, West Baton Rouge Parish
     - LA, West Carroll Parish
     - LA, West Feliciana Parish
     - LA, Winn Parish
     - MA, Barnstable County
     - MA, Berkshire County
     - MA, Bristol County
     - MA, Dukes County
     - MA, Essex County
     - MA, Franklin County
     - MA, Hampden County
     - MA, Hampshire County
     - MA, Middlesex County
     - MA, Nantucket County
     - MA, Norfolk County
     - MA, Plymouth County
     - MA, Suffolk County
     - MA, Worcester County
     - MD, Allegany County
     - MD, Anne Arundel County
     - MD, Baltimore city
     - MD, Baltimore County
     - MD, Calvert County
     - MD, Caroline County
     - MD, Carroll County
     - MD, Cecil County
     - MD, Charles County
     - MD, Dorchester County
     - MD, Frederick County
     - MD, Garrett County
     - MD, Harford County
     - MD, Howard County
     - MD, Kent County
     - MD, Montgomery County
     - MD, Prince George's County
     - MD, Queen Anne's County
     - MD, Somerset County
     - MD, St. Mary's County
     - MD, Talbot County
     - MD, Washington County
     - MD, Wicomico County
     - MD, Worcester County
     - ME, Androscoggin County
     - ME, Aroostook County
     - ME, Cumberland County
     - ME, Franklin County
     - ME, Hancock County
     - ME, Kennebec County
     - ME, Knox County
     - ME, Lincoln County
     - ME, Oxford County
     - ME, Penobscot County
     - ME, Piscataquis County
     - ME, Sagadahoc County
     - ME, Somerset County
     - ME, Waldo County
     - ME, Washington County
     - ME, York County
     - MI, Alcona County
     - MI, Alger County
     - MI, Allegan County
     - MI, Alpena County
     - MI, Antrim County
     - MI, Arenac County
     - MI, Baraga County
     - MI, Barry County
     - MI, Bay County
     - MI, Benzie County
     - MI, Berrien County
     - MI, Branch County
     - MI, Calhoun County
     - MI, Cass County
     - MI, Charlevoix County
     - MI, Cheboygan County
     - MI, Chippewa County
     - MI, Clare County
     - MI, Clinton County
     - MI, Crawford County
     - MI, Delta County
     - MI, Dickinson County
     - MI, Eaton County
     - MI, Emmet County
     - MI, Genesee County
     - MI, Gladwin County
     - MI, Gogebic County
     - MI, Grand Traverse County
     - MI, Gratiot County
     - MI, Hillsdale County
     - MI, Houghton County
     - MI, Huron County
     - MI, Ingham County
     - MI, Ionia County
     - MI, Iosco County
     - MI, Iron County
     - MI, Isabella County
     - MI, Jackson County
     - MI, Kalamazoo County
     - MI, Kalkaska County
     - MI, Kent County
     - MI, Keweenaw County
     - MI, Lake County
     - MI, Lapeer County
     - MI, Leelanau County
     - MI, Lenawee County
     - MI, Livingston County
     - MI, Luce County
     - MI, Mackinac County
     - MI, Macomb County
     - MI, Manistee County
     - MI, Marquette County
     - MI, Mason County
     - MI, Mecosta County
     - MI, Menominee County
     - MI, Midland County
     - MI, Missaukee County
     - MI, Monroe County
     - MI, Montcalm County
     - MI, Montmorency County
     - MI, Muskegon County
     - MI, Newaygo County
     - MI, Oakland County
     - MI, Oceana County
     - MI, Ogemaw County
     - MI, Ontonagon County
     - MI, Osceola County
     - MI, Oscoda County
     - MI, Otsego County
     - MI, Ottawa County
     - MI, Presque Isle County
     - MI, Roscommon County
     - MI, Saginaw County
     - MI, Sanilac County
     - MI, Schoolcraft County
     - MI, Shiawassee County
     - MI, St. Clair County
     - MI, St. Joseph County
     - MI, Tuscola County
     - MI, Van Buren County
     - MI, Washtenaw County
     - MI, Wayne County
     - MI, Wexford County
     - MN, Aitkin County
     - MN, Anoka County
     - MN, Becker County
     - MN, Beltrami County
     - MN, Benton County
     - MN, Big Stone County
     - MN, Blue Earth County
     - MN, Brown County
     - MN, Carlton County
     - MN, Carver County
     - MN, Cass County
     - MN, Chippewa County
     - MN, Chisago County
     - MN, Clay County
     - MN, Clearwater County
     - MN, Cook County
     - MN, Cottonwood County
     - MN, Crow Wing County
     - MN, Dakota County
     - MN, Dodge County
     - MN, Douglas County
     - MN, Faribault County
     - MN, Fillmore County
     - MN, Freeborn County
     - MN, Goodhue County
     - MN, Grant County
     - MN, Hennepin County
     - MN, Houston County
     - MN, Hubbard County
     - MN, Isanti County
     - MN, Itasca County
     - MN, Jackson County
     - MN, Kanabec County
     - MN, Kandiyohi County
     - MN, Kittson County
     - MN, Koochiching County
     - MN, Lac qui Parle County
     - MN, Lake County
     - MN, Lake of the Woods County
     - MN, Le Sueur County
     - MN, Lincoln County
     - MN, Lyon County
     - MN, Mahnomen County
     - MN, Marshall County
     - MN, Martin County
     - MN, McLeod County
     - MN, Meeker County
     - MN, Mille Lacs County
     - MN, Morrison County
     - MN, Mower County
     - MN, Murray County
     - MN, Nicollet County
     - MN, Nobles County
     - MN, Norman County
     - MN, Olmsted County
     - MN, Otter Tail County
     - MN, Pennington County
     - MN, Pine County
     - MN, Pipestone County
     - MN, Polk County
     - MN, Pope County
     - MN, Ramsey County
     - MN, Red Lake County
     - MN, Redwood County
     - MN, Renville County
     - MN, Rice County
     - MN, Rock County
     - MN, Roseau County
     - MN, Scott County
     - MN, Sherburne County
     - MN, Sibley County
     - MN, St. Louis County
     - MN, Stearns County
     - MN, Steele County
     - MN, Stevens County
     - MN, Swift County
     - MN, Todd County
     - MN, Traverse County
     - MN, Wabasha County
     - MN, Wadena County
     - MN, Waseca County
     - MN, Washington County
     - MN, Watonwan County
     - MN, Wilkin County
     - MN, Winona County
     - MN, Wright County
     - MN, Yellow Medicine County
     - MO, Adair County
     - MO, Andrew County
     - MO, Atchison County
     - MO, Audrain County
     - MO, Barry County
     - MO, Barton County
     - MO, Bates County
     - MO, Benton County
     - MO, Bollinger County
     - MO, Boone County
     - MO, Buchanan County
     - MO, Butler County
     - MO, Caldwell County
     - MO, Callaway County
     - MO, Camden County
     - MO, Cape Girardeau County
     - MO, Carroll County
     - MO, Carter County
     - MO, Cass County
     - MO, Cedar County
     - MO, Chariton County
     - MO, Christian County
     - MO, Clark County
     - MO, Clay County
     - MO, Clinton County
     - MO, Cole County
     - MO, Cooper County
     - MO, Crawford County
     - MO, Dade County
     - MO, Dallas County
     - MO, Daviess County
     - MO, DeKalb County
     - MO, Dent County
     - MO, Douglas County
     - MO, Dunklin County
     - MO, Franklin County
     - MO, Gasconade County
     - MO, Gentry County
     - MO, Greene County
     - MO, Grundy County
     - MO, Harrison County
     - MO, Henry County
     - MO, Hickory County
     - MO, Holt County
     - MO, Howard County
     - MO, Howell County
     - MO, Iron County
     - MO, Jackson County
     - MO, Jasper County
     - MO, Jefferson County
     - MO, Johnson County
     - MO, Knox County
     - MO, Laclede County
     - MO, Lafayette County
     - MO, Lawrence County
     - MO, Lewis County
     - MO, Lincoln County
     - MO, Linn County
     - MO, Livingston County
     - MO, Macon County
     - MO, Madison County
     - MO, Maries County
     - MO, Marion County
     - MO, McDonald County
     - MO, Mercer County
     - MO, Miller County
     - MO, Mississippi County
     - MO, Moniteau County
     - MO, Monroe County
     - MO, Montgomery County
     - MO, Morgan County
     - MO, New Madrid County
     - MO, Newton County
     - MO, Nodaway County
     - MO, Oregon County
     - MO, Osage County
     - MO, Ozark County
     - MO, Pemiscot County
     - MO, Perry County
     - MO, Pettis County
     - MO, Phelps County
     - MO, Pike County
     - MO, Platte County
     - MO, Polk County
     - MO, Pulaski County
     - MO, Putnam County
     - MO, Ralls County
     - MO, Randolph County
     - MO, Ray County
     - MO, Reynolds County
     - MO, Ripley County
     - MO, Saline County
     - MO, Schuyler County
     - MO, Scotland County
     - MO, Scott County
     - MO, Shannon County
     - MO, Shelby County
     - MO, St. Charles County
     - MO, St. Clair County
     - MO, St. Francois County
     - MO, St. Louis city
     - MO, St. Louis County
     - MO, Ste. Genevieve County
     - MO, Stoddard County
     - MO, Stone County
     - MO, Sullivan County
     - MO, Taney County
     - MO, Texas County
     - MO, Vernon County
     - MO, Warren County
     - MO, Washington County
     - MO, Wayne County
     - MO, Webster County
     - MO, Worth County
     - MO, Wright County
     - MS, Adams County
     - MS, Alcorn County
     - MS, Amite County
     - MS, Attala County
     - MS, Benton County
     - MS, Bolivar County
     - MS, Calhoun County
     - MS, Carroll County
     - MS, Chickasaw County
     - MS, Choctaw County
     - MS, Claiborne County
     - MS, Clarke County
     - MS, Clay County
     - MS, Coahoma County
     - MS, Copiah County
     - MS, Covington County
     - MS, DeSoto County
     - MS, Forrest County
     - MS, Franklin County
     - MS, George County
     - MS, Greene County
     - MS, Grenada County
     - MS, Hancock County
     - MS, Harrison County
     - MS, Hinds County
     - MS, Holmes County
     - MS, Humphreys County
     - MS, Issaquena County
     - MS, Itawamba County
     - MS, Jackson County
     - MS, Jasper County
     - MS, Jefferson County
     - MS, Jefferson Davis County
     - MS, Jones County
     - MS, Kemper County
     - MS, Lafayette County
     - MS, Lamar County
     - MS, Lauderdale County
     - MS, Lawrence County
     - MS, Leake County
     - MS, Lee County
     - MS, Leflore County
     - MS, Lincoln County
     - MS, Lowndes County
     - MS, Madison County
     - MS, Marion County
     - MS, Marshall County
     - MS, Monroe County
     - MS, Montgomery County
     - MS, Neshoba County
     - MS, Newton County
     - MS, Noxubee County
     - MS, Oktibbeha County
     - MS, Panola County
     - MS, Pearl River County
     - MS, Perry County
     - MS, Pike County
     - MS, Pontotoc County
     - MS, Prentiss County
     - MS, Quitman County
     - MS, Rankin County
     - MS, Scott County
     - MS, Sharkey County
     - MS, Simpson County
     - MS, Smith County
     - MS, Stone County
     - MS, Sunflower County
     - MS, Tallahatchie County
     - MS, Tate County
     - MS, Tippah County
     - MS, Tishomingo County
     - MS, Tunica County
     - MS, Union County
     - MS, Walthall County
     - MS, Warren County
     - MS, Washington County
     - MS, Wayne County
     - MS, Webster County
     - MS, Wilkinson County
     - MS, Winston County
     - MS, Yalobusha County
     - MS, Yazoo County
     - MT, Beaverhead County
     - MT, Big Horn County
     - MT, Blaine County
     - MT, Broadwater County
     - MT, Carbon County
     - MT, Carter County
     - MT, Cascade County
     - MT, Chouteau County
     - MT, Custer County
     - MT, Daniels County
     - MT, Dawson County
     - MT, Deer Lodge County
     - MT, Fallon County
     - MT, Fergus County
     - MT, Flathead County
     - MT, Gallatin County
     - MT, Garfield County
     - MT, Glacier County
     - MT, Golden Valley County
     - MT, Granite County
     - MT, Hill County
     - MT, Jefferson County
     - MT, Judith Basin County
     - MT, Lake County
     - MT, Lewis and Clark County
     - MT, Liberty County
     - MT, Lincoln County
     - MT, Madison County
     - MT, McCone County
     - MT, Meagher County
     - MT, Mineral County
     - MT, Missoula County
     - MT, Musselshell County
     - MT, Park County
     - MT, Petroleum County
     - MT, Phillips County
     - MT, Pondera County
     - MT, Powder River County
     - MT, Powell County
     - MT, Prairie County
     - MT, Ravalli County
     - MT, Richland County
     - MT, Roosevelt County
     - MT, Rosebud County
     - MT, Sanders County
     - MT, Sheridan County
     - MT, Silver Bow County
     - MT, Stillwater County
     - MT, Sweet Grass County
     - MT, Teton County
     - MT, Toole County
     - MT, Treasure County
     - MT, Valley County
     - MT, Wheatland County
     - MT, Wibaux County
     - MT, Yellowstone County
     - NC, Alamance County
     - NC, Alexander County
     - NC, Alleghany County
     - NC, Anson County
     - NC, Ashe County
     - NC, Avery County
     - NC, Beaufort County
     - NC, Bertie County
     - NC, Bladen County
     - NC, Brunswick County
     - NC, Buncombe County
     - NC, Burke County
     - NC, Cabarrus County
     - NC, Caldwell County
     - NC, Camden County
     - NC, Carteret County
     - NC, Caswell County
     - NC, Catawba County
     - NC, Chatham County
     - NC, Cherokee County
     - NC, Chowan County
     - NC, Clay County
     - NC, Cleveland County
     - NC, Columbus County
     - NC, Craven County
     - NC, Cumberland County
     - NC, Currituck County
     - NC, Dare County
     - NC, Davidson County
     - NC, Davie County
     - NC, Duplin County
     - NC, Durham County
     - NC, Edgecombe County
     - NC, Forsyth County
     - NC, Franklin County
     - NC, Gaston County
     - NC, Gates County
     - NC, Graham County
     - NC, Granville County
     - NC, Greene County
     - NC, Guilford County
     - NC, Halifax County
     - NC, Harnett County
     - NC, Haywood County
     - NC, Henderson County
     - NC, Hertford County
     - NC, Hoke County
     - NC, Hyde County
     - NC, Iredell County
     - NC, Jackson County
     - NC, Johnston County
     - NC, Jones County
     - NC, Lee County
     - NC, Lenoir County
     - NC, Lincoln County
     - NC, Macon County
     - NC, Madison County
     - NC, Martin County
     - NC, McDowell County
     - NC, Mecklenburg County
     - NC, Mitchell County
     - NC, Montgomery County
     - NC, Moore County
     - NC, Nash County
     - NC, New Hanover County
     - NC, Northampton County
     - NC, Onslow County
     - NC, Orange County
     - NC, Pamlico County
     - NC, Pasquotank County
     - NC, Pender County
     - NC, Perquimans County
     - NC, Person County
     - NC, Pitt County
     - NC, Polk County
     - NC, Randolph County
     - NC, Richmond County
     - NC, Robeson County
     - NC, Rockingham County
     - NC, Rowan County
     - NC, Rutherford County
     - NC, Sampson County
     - NC, Scotland County
     - NC, Stanly County
     - NC, Stokes County
     - NC, Surry County
     - NC, Swain County
     - NC, Transylvania County
     - NC, Tyrrell County
     - NC, Union County
     - NC, Vance County
     - NC, Wake County
     - NC, Warren County
     - NC, Washington County
     - NC, Watauga County
     - NC, Wayne County
     - NC, Wilkes County
     - NC, Wilson County
     - NC, Yadkin County
     - NC, Yancey County
     - ND, Adams County
     - ND, Barnes County
     - ND, Benson County
     - ND, Billings County
     - ND, Bottineau County
     - ND, Bowman County
     - ND, Burke County
     - ND, Burleigh County
     - ND, Cass County
     - ND, Cavalier County
     - ND, Dickey County
     - ND, Divide County
     - ND, Dunn County
     - ND, Eddy County
     - ND, Emmons County
     - ND, Foster County
     - ND, Golden Valley County
     - ND, Grand Forks County
     - ND, Grant County
     - ND, Griggs County
     - ND, Hettinger County
     - ND, Kidder County
     - ND, LaMoure County
     - ND, Logan County
     - ND, McHenry County
     - ND, McIntosh County
     - ND, McKenzie County
     - ND, McLean County
     - ND, Mercer County
     - ND, Morton County
     - ND, Mountrail County
     - ND, Nelson County
     - ND, Oliver County
     - ND, Pembina County
     - ND, Pierce County
     - ND, Ramsey County
     - ND, Ransom County
     - ND, Renville County
     - ND, Richland County
     - ND, Rolette County
     - ND, Sargent County
     - ND, Sheridan County
     - ND, Sioux County
     - ND, Slope County
     - ND, Stark County
     - ND, Steele County
     - ND, Stutsman County
     - ND, Towner County
     - ND, Traill County
     - ND, Walsh County
     - ND, Ward County
     - ND, Wells County
     - ND, Williams County
     - NE, Adams County
     - NE, Antelope County
     - NE, Arthur County
     - NE, Banner County
     - NE, Blaine County
     - NE, Boone County
     - NE, Box Butte County
     - NE, Boyd County
     - NE, Brown County
     - NE, Buffalo County
     - NE, Burt County
     - NE, Butler County
     - NE, Cass County
     - NE, Cedar County
     - NE, Chase County
     - NE, Cherry County
     - NE, Cheyenne County
     - NE, Clay County
     - NE, Colfax County
     - NE, Cuming County
     - NE, Custer County
     - NE, Dakota County
     - NE, Dawes County
     - NE, Dawson County
     - NE, Deuel County
     - NE, Dixon County
     - NE, Dodge County
     - NE, Douglas County
     - NE, Dundy County
     - NE, Fillmore County
     - NE, Franklin County
     - NE, Frontier County
     - NE, Furnas County
     - NE, Gage County
     - NE, Garden County
     - NE, Garfield County
     - NE, Gosper County
     - NE, Grant County
     - NE, Greeley County
     - NE, Hall County
     - NE, Hamilton County
     - NE, Harlan County
     - NE, Hayes County
     - NE, Hitchcock County
     - NE, Holt County
     - NE, Hooker County
     - NE, Howard County
     - NE, Jefferson County
     - NE, Johnson County
     - NE, Kearney County
     - NE, Keith County
     - NE, Keya Paha County
     - NE, Kimball County
     - NE, Knox County
     - NE, Lancaster County
     - NE, Lincoln County
     - NE, Logan County
     - NE, Loup County
     - NE, Madison County
     - NE, McPherson County
     - NE, Merrick County
     - NE, Morrill County
     - NE, Nance County
     - NE, Nemaha County
     - NE, Nuckolls County
     - NE, Otoe County
     - NE, Pawnee County
     - NE, Perkins County
     - NE, Phelps County
     - NE, Pierce County
     - NE, Platte County
     - NE, Polk County
     - NE, Red Willow County
     - NE, Richardson County
     - NE, Rock County
     - NE, Saline County
     - NE, Sarpy County
     - NE, Saunders County
     - NE, Scotts Bluff County
     - NE, Seward County
     - NE, Sheridan County
     - NE, Sherman County
     - NE, Sioux County
     - NE, Stanton County
     - NE, Thayer County
     - NE, Thomas County
     - NE, Thurston County
     - NE, Valley County
     - NE, Washington County
     - NE, Wayne County
     - NE, Webster County
     - NE, Wheeler County
     - NE, York County
     - NH, Belknap County
     - NH, Carroll County
     - NH, Cheshire County
     - NH, Coos County
     - NH, Grafton County
     - NH, Hillsborough County
     - NH, Merrimack County
     - NH, Rockingham County
     - NH, Strafford County
     - NH, Sullivan County
     - NJ, Atlantic County
     - NJ, Bergen County
     - NJ, Burlington County
     - NJ, Camden County
     - NJ, Cape May County
     - NJ, Cumberland County
     - NJ, Essex County
     - NJ, Gloucester County
     - NJ, Hudson County
     - NJ, Hunterdon County
     - NJ, Mercer County
     - NJ, Middlesex County
     - NJ, Monmouth County
     - NJ, Morris County
     - NJ, Ocean County
     - NJ, Passaic County
     - NJ, Salem County
     - NJ, Somerset County
     - NJ, Sussex County
     - NJ, Union County
     - NJ, Warren County
     - NM, Bernalillo County
     - NM, Catron County
     - NM, Chaves County
     - NM, Cibola County
     - NM, Colfax County
     - NM, Curry County
     - NM, De Baca County
     - NM, Dona Ana County
     - NM, Eddy County
     - NM, Grant County
     - NM, Guadalupe County
     - NM, Harding County
     - NM, Hidalgo County
     - NM, Lea County
     - NM, Lincoln County
     - NM, Los Alamos County
     - NM, Luna County
     - NM, McKinley County
     - NM, Mora County
     - NM, Otero County
     - NM, Quay County
     - NM, Rio Arriba County
     - NM, Roosevelt County
     - NM, San Juan County
     - NM, San Miguel County
     - NM, Sandoval County
     - NM, Santa Fe County
     - NM, Sierra County
     - NM, Socorro County
     - NM, Taos County
     - NM, Torrance County
     - NM, Union County
     - NM, Valencia County
     - NV, Carson City
     - NV, Churchill County
     - NV, Clark County
     - NV, Douglas County
     - NV, Elko County
     - NV, Esmeralda County
     - NV, Eureka County
     - NV, Humboldt County
     - NV, Lander County
     - NV, Lincoln County
     - NV, Lyon County
     - NV, Mineral County
     - NV, Nye County
     - NV, Pershing County
     - NV, Storey County
     - NV, Washoe County
     - NV, White Pine County
     - NY, Albany County
     - NY, Allegany County
     - NY, Bronx County
     - NY, Broome County
     - NY, Cattaraugus County
     - NY, Cayuga County
     - NY, Chautauqua County
     - NY, Chemung County
     - NY, Chenango County
     - NY, Clinton County
     - NY, Columbia County
     - NY, Cortland County
     - NY, Delaware County
     - NY, Dutchess County
     - NY, Erie County
     - NY, Essex County
     - NY, Franklin County
     - NY, Fulton County
     - NY, Genesee County
     - NY, Greene County
     - NY, Hamilton County
     - NY, Herkimer County
     - NY, Jefferson County
     - NY, Kings County
     - NY, Lewis County
     - NY, Livingston County
     - NY, Madison County
     - NY, Monroe County
     - NY, Montgomery County
     - NY, Nassau County
     - NY, New York County
     - NY, Niagara County
     - NY, Oneida County
     - NY, Onondaga County
     - NY, Ontario County
     - NY, Orange County
     - NY, Orleans County
     - NY, Oswego County
     - NY, Otsego County
     - NY, Putnam County
     - NY, Queens County
     - NY, Rensselaer County
     - NY, Richmond County
     - NY, Rockland County
     - NY, Saratoga County
     - NY, Schenectady County
     - NY, Schoharie County
     - NY, Schuyler County
     - NY, Seneca County
     - NY, St. Lawrence County
     - NY, Steuben County
     - NY, Suffolk County
     - NY, Sullivan County
     - NY, Tioga County
     - NY, Tompkins County
     - NY, Ulster County
     - NY, Warren County
     - NY, Washington County
     - NY, Wayne County
     - NY, Westchester County
     - NY, Wyoming County
     - NY, Yates County
     - OH, Adams County
     - OH, Allen County
     - OH, Ashland County
     - OH, Ashtabula County
     - OH, Athens County
     - OH, Auglaize County
     - OH, Belmont County
     - OH, Brown County
     - OH, Butler County
     - OH, Carroll County
     - OH, Champaign County
     - OH, Clark County
     - OH, Clermont County
     - OH, Clinton County
     - OH, Columbiana County
     - OH, Coshocton County
     - OH, Crawford County
     - OH, Cuyahoga County
     - OH, Darke County
     - OH, Defiance County
     - OH, Delaware County
     - OH, Erie County
     - OH, Fairfield County
     - OH, Fayette County
     - OH, Franklin County
     - OH, Fulton County
     - OH, Gallia County
     - OH, Geauga County
     - OH, Greene County
     - OH, Guernsey County
     - OH, Hamilton County
     - OH, Hancock County
     - OH, Hardin County
     - OH, Harrison County
     - OH, Henry County
     - OH, Highland County
     - OH, Hocking County
     - OH, Holmes County
     - OH, Huron County
     - OH, Jackson County
     - OH, Jefferson County
     - OH, Knox County
     - OH, Lake County
     - OH, Lawrence County
     - OH, Licking County
     - OH, Logan County
     - OH, Lorain County
     - OH, Lucas County
     - OH, Madison County
     - OH, Mahoning County
     - OH, Marion County
     - OH, Medina County
     - OH, Meigs County
     - OH, Mercer County
     - OH, Miami County
     - OH, Monroe County
     - OH, Montgomery County
     - OH, Morgan County
     - OH, Morrow County
     - OH, Muskingum County
     - OH, Noble County
     - OH, Ottawa County
     - OH, Paulding County
     - OH, Perry County
     - OH, Pickaway County
     - OH, Pike County
     - OH, Portage County
     - OH, Preble County
     - OH, Putnam County
     - OH, Richland County
     - OH, Ross County
     - OH, Sandusky County
     - OH, Scioto County
     - OH, Seneca County
     - OH, Shelby County
     - OH, Stark County
     - OH, Summit County
     - OH, Trumbull County
     - OH, Tuscarawas County
     - OH, Union County
     - OH, Van Wert County
     - OH, Vinton County
     - OH, Warren County
     - OH, Washington County
     - OH, Wayne County
     - OH, Williams County
     - OH, Wood County
     - OH, Wyandot County
     - OK, Adair County
     - OK, Alfalfa County
     - OK, Atoka County
     - OK, Beaver County
     - OK, Beckham County
     - OK, Blaine County
     - OK, Bryan County
     - OK, Caddo County
     - OK, Canadian County
     - OK, Carter County
     - OK, Cherokee County
     - OK, Choctaw County
     - OK, Cimarron County
     - OK, Cleveland County
     - OK, Coal County
     - OK, Comanche County
     - OK, Cotton County
     - OK, Craig County
     - OK, Creek County
     - OK, Custer County
     - OK, Delaware County
     - OK, Dewey County
     - OK, Ellis County
     - OK, Garfield County
     - OK, Garvin County
     - OK, Grady County
     - OK, Grant County
     - OK, Greer County
     - OK, Harmon County
     - OK, Harper County
     - OK, Haskell County
     - OK, Hughes County
     - OK, Jackson County
     - OK, Jefferson County
     - OK, Johnston County
     - OK, Kay County
     - OK, Kingfisher County
     - OK, Kiowa County
     - OK, Latimer County
     - OK, Le Flore County
     - OK, Lincoln County
     - OK, Logan County
     - OK, Love County
     - OK, Major County
     - OK, Marshall County
     - OK, Mayes County
     - OK, McClain County
     - OK, McCurtain County
     - OK, McIntosh County
     - OK, Murray County
     - OK, Muskogee County
     - OK, Noble County
     - OK, Nowata County
     - OK, Okfuskee County
     - OK, Oklahoma County
     - OK, Okmulgee County
     - OK, Osage County
     - OK, Ottawa County
     - OK, Pawnee County
     - OK, Payne County
     - OK, Pittsburg County
     - OK, Pontotoc County
     - OK, Pottawatomie County
     - OK, Pushmataha County
     - OK, Roger Mills County
     - OK, Rogers County
     - OK, Seminole County
     - OK, Sequoyah County
     - OK, Stephens County
     - OK, Texas County
     - OK, Tillman County
     - OK, Tulsa County
     - OK, Wagoner County
     - OK, Washington County
     - OK, Washita County
     - OK, Woods County
     - OK, Woodward County
     - OR, Baker County
     - OR, Benton County
     - OR, Clackamas County
     - OR, Clatsop County
     - OR, Columbia County
     - OR, Coos County
     - OR, Crook County
     - OR, Curry County
     - OR, Deschutes County
     - OR, Douglas County
     - OR, Gilliam County
     - OR, Grant County
     - OR, Harney County
     - OR, Hood River County
     - OR, Jackson County
     - OR, Jefferson County
     - OR, Josephine County
     - OR, Klamath County
     - OR, Lake County
     - OR, Lane County
     - OR, Lincoln County
     - OR, Linn County
     - OR, Malheur County
     - OR, Marion County
     - OR, Morrow County
     - OR, Multnomah County
     - OR, Polk County
     - OR, Sherman County
     - OR, Tillamook County
     - OR, Umatilla County
     - OR, Union County
     - OR, Wallowa County
     - OR, Wasco County
     - OR, Washington County
     - OR, Wheeler County
     - OR, Yamhill County
     - PA, Adams County
     - PA, Allegheny County
     - PA, Armstrong County
     - PA, Beaver County
     - PA, Bedford County
     - PA, Berks County
     - PA, Blair County
     - PA, Bradford County
     - PA, Bucks County
     - PA, Butler County
     - PA, Cambria County
     - PA, Cameron County
     - PA, Carbon County
     - PA, Centre County
     - PA, Chester County
     - PA, Clarion County
     - PA, Clearfield County
     - PA, Clinton County
     - PA, Columbia County
     - PA, Crawford County
     - PA, Cumberland County
     - PA, Dauphin County
     - PA, Delaware County
     - PA, Elk County
     - PA, Erie County
     - PA, Fayette County
     - PA, Forest County
     - PA, Franklin County
     - PA, Fulton County
     - PA, Greene County
     - PA, Huntingdon County
     - PA, Indiana County
     - PA, Jefferson County
     - PA, Juniata County
     - PA, Lackawanna County
     - PA, Lancaster County
     - PA, Lawrence County
     - PA, Lebanon County
     - PA, Lehigh County
     - PA, Luzerne County
     - PA, Lycoming County
     - PA, McKean County
     - PA, Mercer County
     - PA, Mifflin County
     - PA, Monroe County
     - PA, Montgomery County
     - PA, Montour County
     - PA, Northampton County
     - PA, Northumberland County
     - PA, Perry County
     - PA, Philadelphia County
     - PA, Pike County
     - PA, Potter County
     - PA, Schuylkill County
     - PA, Snyder County
     - PA, Somerset County
     - PA, Sullivan County
     - PA, Susquehanna County
     - PA, Tioga County
     - PA, Union County
     - PA, Venango County
     - PA, Warren County
     - PA, Washington County
     - PA, Wayne County
     - PA, Westmoreland County
     - PA, Wyoming County
     - PA, York County
     - RI, Bristol County
     - RI, Kent County
     - RI, Newport County
     - RI, Providence County
     - RI, Washington County
     - SC, Abbeville County
     - SC, Aiken County
     - SC, Allendale County
     - SC, Anderson County
     - SC, Bamberg County
     - SC, Barnwell County
     - SC, Beaufort County
     - SC, Berkeley County
     - SC, Calhoun County
     - SC, Charleston County
     - SC, Cherokee County
     - SC, Chester County
     - SC, Chesterfield County
     - SC, Clarendon County
     - SC, Colleton County
     - SC, Darlington County
     - SC, Dillon County
     - SC, Dorchester County
     - SC, Edgefield County
     - SC, Fairfield County
     - SC, Florence County
     - SC, Georgetown County
     - SC, Greenville County
     - SC, Greenwood County
     - SC, Hampton County
     - SC, Horry County
     - SC, Jasper County
     - SC, Kershaw County
     - SC, Lancaster County
     - SC, Laurens County
     - SC, Lee County
     - SC, Lexington County
     - SC, Marion County
     - SC, Marlboro County
     - SC, McCormick County
     - SC, Newberry County
     - SC, Oconee County
     - SC, Orangeburg County
     - SC, Pickens County
     - SC, Richland County
     - SC, Saluda County
     - SC, Spartanburg County
     - SC, Sumter County
     - SC, Union County
     - SC, Williamsburg County
     - SC, York County
     - SD, Aurora County
     - SD, Beadle County
     - SD, Bennett County
     - SD, Bon Homme County
     - SD, Brookings County
     - SD, Brown County
     - SD, Brule County
     - SD, Buffalo County
     - SD, Butte County
     - SD, Campbell County
     - SD, Charles Mix County
     - SD, Clark County
     - SD, Clay County
     - SD, Codington County
     - SD, Corson County
     - SD, Custer County
     - SD, Davison County
     - SD, Day County
     - SD, Deuel County
     - SD, Dewey County
     - SD, Douglas County
     - SD, Edmunds County
     - SD, Fall River County
     - SD, Faulk County
     - SD, Grant County
     - SD, Gregory County
     - SD, Haakon County
     - SD, Hamlin County
     - SD, Hand County
     - SD, Hanson County
     - SD, Harding County
     - SD, Hughes County
     - SD, Hutchinson County
     - SD, Hyde County
     - SD, Jackson County
     - SD, Jerauld County
     - SD, Jones County
     - SD, Kingsbury County
     - SD, Lake County
     - SD, Lawrence County
     - SD, Lincoln County
     - SD, Lyman County
     - SD, Marshall County
     - SD, McCook County
     - SD, McPherson County
     - SD, Meade County
     - SD, Mellette County
     - SD, Miner County
     - SD, Minnehaha County
     - SD, Moody County
     - SD, Oglala Lakota County
     - SD, Pennington County
     - SD, Perkins County
     - SD, Potter County
     - SD, Roberts County
     - SD, Sanborn County
     - SD, Spink County
     - SD, Stanley County
     - SD, Sully County
     - SD, Todd County
     - SD, Tripp County
     - SD, Turner County
     - SD, Union County
     - SD, Walworth County
     - SD, Yankton County
     - SD, Ziebach County
     - TN, Anderson County
     - TN, Bedford County
     - TN, Benton County
     - TN, Bledsoe County
     - TN, Blount County
     - TN, Bradley County
     - TN, Campbell County
     - TN, Cannon County
     - TN, Carroll County
     - TN, Carter County
     - TN, Cheatham County
     - TN, Chester County
     - TN, Claiborne County
     - TN, Clay County
     - TN, Cocke County
     - TN, Coffee County
     - TN, Crockett County
     - TN, Cumberland County
     - TN, Davidson County
     - TN, Decatur County
     - TN, DeKalb County
     - TN, Dickson County
     - TN, Dyer County
     - TN, Fayette County
     - TN, Fentress County
     - TN, Franklin County
     - TN, Gibson County
     - TN, Giles County
     - TN, Grainger County
     - TN, Greene County
     - TN, Grundy County
     - TN, Hamblen County
     - TN, Hamilton County
     - TN, Hancock County
     - TN, Hardeman County
     - TN, Hardin County
     - TN, Hawkins County
     - TN, Haywood County
     - TN, Henderson County
     - TN, Henry County
     - TN, Hickman County
     - TN, Houston County
     - TN, Humphreys County
     - TN, Jackson County
     - TN, Jefferson County
     - TN, Johnson County
     - TN, Knox County
     - TN, Lake County
     - TN, Lauderdale County
     - TN, Lawrence County
     - TN, Lewis County
     - TN, Lincoln County
     - TN, Loudon County
     - TN, Macon County
     - TN, Madison County
     - TN, Marion County
     - TN, Marshall County
     - TN, Maury County
     - TN, McMinn County
     - TN, McNairy County
     - TN, Meigs County
     - TN, Monroe County
     - TN, Montgomery County
     - TN, Moore County
     - TN, Morgan County
     - TN, Obion County
     - TN, Overton County
     - TN, Perry County
     - TN, Pickett County
     - TN, Polk County
     - TN, Putnam County
     - TN, Rhea County
     - TN, Roane County
     - TN, Robertson County
     - TN, Rutherford County
     - TN, Scott County
     - TN, Sequatchie County
     - TN, Sevier County
     - TN, Shelby County
     - TN, Smith County
     - TN, Stewart County
     - TN, Sullivan County
     - TN, Sumner County
     - TN, Tipton County
     - TN, Trousdale County
     - TN, Unicoi County
     - TN, Union County
     - TN, Van Buren County
     - TN, Warren County
     - TN, Washington County
     - TN, Wayne County
     - TN, Weakley County
     - TN, White County
     - TN, Williamson County
     - TN, Wilson County
     - TX, Anderson County
     - TX, Andrews County
     - TX, Angelina County
     - TX, Aransas County
     - TX, Archer County
     - TX, Armstrong County
     - TX, Atascosa County
     - TX, Austin County
     - TX, Bailey County
     - TX, Bandera County
     - TX, Bastrop County
     - TX, Baylor County
     - TX, Bee County
     - TX, Bell County
     - TX, Bexar County
     - TX, Blanco County
     - TX, Borden County
     - TX, Bosque County
     - TX, Bowie County
     - TX, Brazoria County
     - TX, Brazos County
     - TX, Brewster County
     - TX, Briscoe County
     - TX, Brooks County
     - TX, Brown County
     - TX, Burleson County
     - TX, Burnet County
     - TX, Caldwell County
     - TX, Calhoun County
     - TX, Callahan County
     - TX, Cameron County
     - TX, Camp County
     - TX, Carson County
     - TX, Cass County
     - TX, Castro County
     - TX, Chambers County
     - TX, Cherokee County
     - TX, Childress County
     - TX, Clay County
     - TX, Cochran County
     - TX, Coke County
     - TX, Coleman County
     - TX, Collin County
     - TX, Collingsworth County
     - TX, Colorado County
     - TX, Comal County
     - TX, Comanche County
     - TX, Concho County
     - TX, Cooke County
     - TX, Coryell County
     - TX, Cottle County
     - TX, Crane County
     - TX, Crockett County
     - TX, Crosby County
     - TX, Culberson County
     - TX, Dallam County
     - TX, Dallas County
     - TX, Dawson County
     - TX, Deaf Smith County
     - TX, Delta County
     - TX, Denton County
     - TX, DeWitt County
     - TX, Dickens County
     - TX, Dimmit County
     - TX, Donley County
     - TX, Duval County
     - TX, Eastland County
     - TX, Ector County
     - TX, Edwards County
     - TX, El Paso County
     - TX, Ellis County
     - TX, Erath County
     - TX, Falls County
     - TX, Fannin County
     - TX, Fayette County
     - TX, Fisher County
     - TX, Floyd County
     - TX, Foard County
     - TX, Fort Bend County
     - TX, Franklin County
     - TX, Freestone County
     - TX, Frio County
     - TX, Gaines County
     - TX, Galveston County
     - TX, Garza County
     - TX, Gillespie County
     - TX, Glasscock County
     - TX, Goliad County
     - TX, Gonzales County
     - TX, Gray County
     - TX, Grayson County
     - TX, Gregg County
     - TX, Grimes County
     - TX, Guadalupe County
     - TX, Hale County
     - TX, Hall County
     - TX, Hamilton County
     - TX, Hansford County
     - TX, Hardeman County
     - TX, Hardin County
     - TX, Harris County
     - TX, Harrison County
     - TX, Hartley County
     - TX, Haskell County
     - TX, Hays County
     - TX, Hemphill County
     - TX, Henderson County
     - TX, Hidalgo County
     - TX, Hill County
     - TX, Hockley County
     - TX, Hood County
     - TX, Hopkins County
     - TX, Houston County
     - TX, Howard County
     - TX, Hudspeth County
     - TX, Hunt County
     - TX, Hutchinson County
     - TX, Irion County
     - TX, Jack County
     - TX, Jackson County
     - TX, Jasper County
     - TX, Jeff Davis County
     - TX, Jefferson County
     - TX, Jim Hogg County
     - TX, Jim Wells County
     - TX, Johnson County
     - TX, Jones County
     - TX, Karnes County
     - TX, Kaufman County
     - TX, Kendall County
     - TX, Kenedy County
     - TX, Kent County
     - TX, Kerr County
     - TX, Kimble County
     - TX, King County
     - TX, Kinney County
     - TX, Kleberg County
     - TX, Knox County
     - TX, La Salle County
     - TX, Lamar County
     - TX, Lamb County
     - TX, Lampasas County
     - TX, Lavaca County
     - TX, Lee County
     - TX, Leon County
     - TX, Liberty County
     - TX, Limestone County
     - TX, Lipscomb County
     - TX, Live Oak County
     - TX, Llano County
     - TX, Loving County
     - TX, Lubbock County
     - TX, Lynn County
     - TX, Madison County
     - TX, Marion County
     - TX, Martin County
     - TX, Mason County
     - TX, Matagorda County
     - TX, Maverick County
     - TX, McCulloch County
     - TX, McLennan County
     - TX, McMullen County
     - TX, Medina County
     - TX, Menard County
     - TX, Midland County
     - TX, Milam County
     - TX, Mills County
     - TX, Mitchell County
     - TX, Montague County
     - TX, Montgomery County
     - TX, Moore County
     - TX, Morris County
     - TX, Motley County
     - TX, Nacogdoches County
     - TX, Navarro County
     - TX, Newton County
     - TX, Nolan County
     - TX, Nueces County
     - TX, Ochiltree County
     - TX, Oldham County
     - TX, Orange County
     - TX, Palo Pinto County
     - TX, Panola County
     - TX, Parker County
     - TX, Parmer County
     - TX, Pecos County
     - TX, Polk County
     - TX, Potter County
     - TX, Presidio County
     - TX, Rains County
     - TX, Randall County
     - TX, Reagan County
     - TX, Real County
     - TX, Red River County
     - TX, Reeves County
     - TX, Refugio County
     - TX, Roberts County
     - TX, Robertson County
     - TX, Rockwall County
     - TX, Runnels County
     - TX, Rusk County
     - TX, Sabine County
     - TX, San Augustine County
     - TX, San Jacinto County
     - TX, San Patricio County
     - TX, San Saba County
     - TX, Schleicher County
     - TX, Scurry County
     - TX, Shackelford County
     - TX, Shelby County
     - TX, Sherman County
     - TX, Smith County
     - TX, Somervell County
     - TX, Starr County
     - TX, Stephens County
     - TX, Sterling County
     - TX, Stonewall County
     - TX, Sutton County
     - TX, Swisher County
     - TX, Tarrant County
     - TX, Taylor County
     - TX, Terrell County
     - TX, Terry County
     - TX, Throckmorton County
     - TX, Titus County
     - TX, Tom Green County
     - TX, Travis County
     - TX, Trinity County
     - TX, Tyler County
     - TX, Upshur County
     - TX, Upton County
     - TX, Uvalde County
     - TX, Val Verde County
     - TX, Van Zandt County
     - TX, Victoria County
     - TX, Walker County
     - TX, Waller County
     - TX, Ward County
     - TX, Washington County
     - TX, Webb County
     - TX, Wharton County
     - TX, Wheeler County
     - TX, Wichita County
     - TX, Wilbarger County
     - TX, Willacy County
     - TX, Williamson County
     - TX, Wilson County
     - TX, Winkler County
     - TX, Wise County
     - TX, Wood County
     - TX, Yoakum County
     - TX, Young County
     - TX, Zapata County
     - TX, Zavala County
     - UT, Beaver County
     - UT, Box Elder County
     - UT, Cache County
     - UT, Carbon County
     - UT, Daggett County
     - UT, Davis County
     - UT, Duchesne County
     - UT, Emery County
     - UT, Garfield County
     - UT, Grand County
     - UT, Iron County
     - UT, Juab County
     - UT, Kane County
     - UT, Millard County
     - UT, Morgan County
     - UT, Piute County
     - UT, Rich County
     - UT, Salt Lake County
     - UT, San Juan County
     - UT, Sanpete County
     - UT, Sevier County
     - UT, Summit County
     - UT, Tooele County
     - UT, Uintah County
     - UT, Utah County
     - UT, Wasatch County
     - UT, Washington County
     - UT, Wayne County
     - UT, Weber County
     - VA, Accomack County
     - VA, Albemarle County
     - VA, Alexandria city
     - VA, Alleghany County
     - VA, Amelia County
     - VA, Amherst County
     - VA, Appomattox County
     - VA, Arlington County
     - VA, Augusta County
     - VA, Bath County
     - VA, Bedford County
     - VA, Bland County
     - VA, Botetourt County
     - VA, Bristol city
     - VA, Brunswick County
     - VA, Buchanan County
     - VA, Buckingham County
     - VA, Buena Vista city
     - VA, Campbell County
     - VA, Caroline County
     - VA, Carroll County
     - VA, Charles City County
     - VA, Charlotte County
     - VA, Charlottesville city
     - VA, Chesapeake city
     - VA, Chesterfield County
     - VA, Clarke County
     - VA, Colonial Heights city
     - VA, Covington city
     - VA, Craig County
     - VA, Culpeper County
     - VA, Cumberland County
     - VA, Danville city
     - VA, Dickenson County
     - VA, Dinwiddie County
     - VA, Emporia city
     - VA, Essex County
     - VA, Fairfax city
     - VA, Fairfax County
     - VA, Falls Church city
     - VA, Fauquier County
     - VA, Floyd County
     - VA, Fluvanna County
     - VA, Franklin city
     - VA, Franklin County
     - VA, Frederick County
     - VA, Fredericksburg city
     - VA, Galax city
     - VA, Giles County
     - VA, Gloucester County
     - VA, Goochland County
     - VA, Grayson County
     - VA, Greene County
     - VA, Greensville County
     - VA, Halifax County
     - VA, Hampton city
     - VA, Hanover County
     - VA, Harrisonburg city
     - VA, Henrico County
     - VA, Henry County
     - VA, Highland County
     - VA, Hopewell city
     - VA, Isle of Wight County
     - VA, James City County
     - VA, King and Queen County
     - VA, King George County
     - VA, King William County
     - VA, Lancaster County
     - VA, Lee County
     - VA, Lexington city
     - VA, Loudoun County
     - VA, Louisa County
     - VA, Lunenburg County
     - VA, Lynchburg city
     - VA, Madison County
     - VA, Manassas city
     - VA, Manassas Park city
     - VA, Martinsville city
     - VA, Mathews County
     - VA, Mecklenburg County
     - VA, Middlesex County
     - VA, Montgomery County
     - VA, Nelson County
     - VA, New Kent County
     - VA, Newport News city
     - VA, Norfolk city
     - VA, Northampton County
     - VA, Northumberland County
     - VA, Norton city
     - VA, Nottoway County
     - VA, Orange County
     - VA, Page County
     - VA, Patrick County
     - VA, Petersburg city
     - VA, Pittsylvania County
     - VA, Poquoson city
     - VA, Portsmouth city
     - VA, Powhatan County
     - VA, Prince Edward County
     - VA, Prince George County
     - VA, Prince William County
     - VA, Pulaski County
     - VA, Radford city
     - VA, Rappahannock County
     - VA, Richmond city
     - VA, Richmond County
     - VA, Roanoke city
     - VA, Roanoke County
     - VA, Rockbridge County
     - VA, Rockingham County
     - VA, Russell County
     - VA, Salem city
     - VA, Scott County
     - VA, Shenandoah County
     - VA, Smyth County
     - VA, Southampton County
     - VA, Spotsylvania County
     - VA, Stafford County
     - VA, Staunton city
     - VA, Suffolk city
     - VA, Surry County
     - VA, Sussex County
     - VA, Tazewell County
     - VA, Virginia Beach city
     - VA, Warren County
     - VA, Washington County
     - VA, Waynesboro city
     - VA, Westmoreland County
     - VA, Williamsburg city
     - VA, Winchester city
     - VA, Wise County
     - VA, Wythe County
     - VA, York County
     - VT, Addison County
     - VT, Bennington County
     - VT, Caledonia County
     - VT, Chittenden County
     - VT, Essex County
     - VT, Franklin County
     - VT, Grand Isle County
     - VT, Lamoille County
     - VT, Orange County
     - VT, Orleans County
     - VT, Rutland County
     - VT, Washington County
     - VT, Windham County
     - VT, Windsor County
     - WA, Adams County
     - WA, Asotin County
     - WA, Benton County
     - WA, Chelan County
     - WA, Clallam County
     - WA, Clark County
     - WA, Columbia County
     - WA, Cowlitz County
     - WA, Douglas County
     - WA, Ferry County
     - WA, Franklin County
     - WA, Garfield County
     - WA, Grant County
     - WA, Grays Harbor County
     - WA, Island County
     - WA, Jefferson County
     - WA, King County
     - WA, Kitsap County
     - WA, Kittitas County
     - WA, Klickitat County
     - WA, Lewis County
     - WA, Lincoln County
     - WA, Mason County
     - WA, Okanogan County
     - WA, Pacific County
     - WA, Pend Oreille County
     - WA, Pierce County
     - WA, San Juan County
     - WA, Skagit County
     - WA, Skamania County
     - WA, Snohomish County
     - WA, Spokane County
     - WA, Stevens County
     - WA, Thurston County
     - WA, Wahkiakum County
     - WA, Walla Walla County
     - WA, Whatcom County
     - WA, Whitman County
     - WA, Yakima County
     - WI, Adams County
     - WI, Ashland County
     - WI, Barron County
     - WI, Bayfield County
     - WI, Brown County
     - WI, Buffalo County
     - WI, Burnett County
     - WI, Calumet County
     - WI, Chippewa County
     - WI, Clark County
     - WI, Columbia County
     - WI, Crawford County
     - WI, Dane County
     - WI, Dodge County
     - WI, Door County
     - WI, Douglas County
     - WI, Dunn County
     - WI, Eau Claire County
     - WI, Florence County
     - WI, Fond du Lac County
     - WI, Forest County
     - WI, Grant County
     - WI, Green County
     - WI, Green Lake County
     - WI, Iowa County
     - WI, Iron County
     - WI, Jackson County
     - WI, Jefferson County
     - WI, Juneau County
     - WI, Kenosha County
     - WI, Kewaunee County
     - WI, La Crosse County
     - WI, Lafayette County
     - WI, Langlade County
     - WI, Lincoln County
     - WI, Manitowoc County
     - WI, Marathon County
     - WI, Marinette County
     - WI, Marquette County
     - WI, Menominee County
     - WI, Milwaukee County
     - WI, Monroe County
     - WI, Oconto County
     - WI, Oneida County
     - WI, Outagamie County
     - WI, Ozaukee County
     - WI, Pepin County
     - WI, Pierce County
     - WI, Polk County
     - WI, Portage County
     - WI, Price County
     - WI, Racine County
     - WI, Richland County
     - WI, Rock County
     - WI, Rusk County
     - WI, Sauk County
     - WI, Sawyer County
     - WI, Shawano County
     - WI, Sheboygan County
     - WI, St. Croix County
     - WI, Taylor County
     - WI, Trempealeau County
     - WI, Vernon County
     - WI, Vilas County
     - WI, Walworth County
     - WI, Washburn County
     - WI, Washington County
     - WI, Waukesha County
     - WI, Waupaca County
     - WI, Waushara County
     - WI, Winnebago County
     - WI, Wood County
     - WV, Barbour County
     - WV, Berkeley County
     - WV, Boone County
     - WV, Braxton County
     - WV, Brooke County
     - WV, Cabell County
     - WV, Calhoun County
     - WV, Clay County
     - WV, Doddridge County
     - WV, Fayette County
     - WV, Gilmer County
     - WV, Grant County
     - WV, Greenbrier County
     - WV, Hampshire County
     - WV, Hancock County
     - WV, Hardy County
     - WV, Harrison County
     - WV, Jackson County
     - WV, Jefferson County
     - WV, Kanawha County
     - WV, Lewis County
     - WV, Lincoln County
     - WV, Logan County
     - WV, Marion County
     - WV, Marshall County
     - WV, Mason County
     - WV, McDowell County
     - WV, Mercer County
     - WV, Mineral County
     - WV, Mingo County
     - WV, Monongalia County
     - WV, Monroe County
     - WV, Morgan County
     - WV, Nicholas County
     - WV, Ohio County
     - WV, Pendleton County
     - WV, Pleasants County
     - WV, Pocahontas County
     - WV, Preston County
     - WV, Putnam County
     - WV, Raleigh County
     - WV, Randolph County
     - WV, Ritchie County
     - WV, Roane County
     - WV, Summers County
     - WV, Taylor County
     - WV, Tucker County
     - WV, Tyler County
     - WV, Upshur County
     - WV, Wayne County
     - WV, Webster County
     - WV, Wetzel County
     - WV, Wirt County
     - WV, Wood County
     - WV, Wyoming County
     - WY, Albany County
     - WY, Big Horn County
     - WY, Campbell County
     - WY, Carbon County
     - WY, Converse County
     - WY, Crook County
     - WY, Fremont County
     - WY, Goshen County
     - WY, Hot Springs County
     - WY, Johnson County
     - WY, Laramie County
     - WY, Lincoln County
     - WY, Natrona County
     - WY, Niobrara County
     - WY, Park County
     - WY, Platte County
     - WY, Sheridan County
     - WY, Sublette County
     - WY, Sweetwater County
     - WY, Teton County
     - WY, Uinta County
     - WY, Washakie County
     - WY, Weston County
   * - Stock saturation
     - 0.00075%
     - 0.0015%
     - 0.085%
     - 0.0045%
     - 0.00068%
     - 0.0013%
     - 0.0018%
     - 0.031%
     - 0.0012%
     - 0.0012%
     - 0.0099%
     - 0.023%
     - 0.0047%
     - 0.004%
     - 0.0017%
     - 0.0011%
     - 0.031%
     - 0.003%
     - 0.0019%
     - 0.002%
     - 0.0013%
     - 0.0025%
     - 0.0031%
     - 0.00048%
     - 0.0029%
     - 0.0046%
     - 0.0011%
     - 0.00029%
     - 0.003%
     - 0.017%
     - 0.08%
     - 0.0088%
     - 0.0067%
     - 0.018%
     - 0.0033%
     - 0.0074%
     - 0.04%
     - 0.013%
     - 0.012%
     - 0.014%
     - 0.0054%
     - 0.0094%
     - 0.005%
     - 0.005%
     - 0.017%
     - 0.02%
     - 0.0053%
     - 0.0048%
     - 0.014%
     - 0.005%
     - 0.028%
     - 0.017%
     - 0.015%
     - 0.023%
     - 0.025%
     - 0.012%
     - 0.035%
     - 0.0063%
     - 0.01%
     - 0.0094%
     - 0.0037%
     - 0.0057%
     - 0.0067%
     - 0.035%
     - 0.018%
     - 0.23%
     - 0.0055%
     - 0.033%
     - 0.011%
     - 0.049%
     - 0.026%
     - 0.0038%
     - 0.0076%
     - 0.12%
     - 0.0076%
     - 0.011%
     - 0.03%
     - 0.14%
     - 0.0084%
     - 0.077%
     - 0.038%
     - 0.0035%
     - 0.007%
     - 0.012%
     - 0.0089%
     - 0.02%
     - 0.062%
     - 0.027%
     - 0.005%
     - 0.028%
     - 0.016%
     - 0.066%
     - 0.023%
     - 0.0062%
     - 0.0042%
     - 0.01%
     - 0.007%
     - 0.0075%
     - 0.017%
     - 0.073%
     - 0.013%
     - 0.0043%
     - 0.0022%
     - 0.01%
     - 0.004%
     - 0.0078%
     - 0.006%
     - 0.012%
     - 0.003%
     - 0.0086%
     - 0.0073%
     - 0.032%
     - 0.02%
     - 0.016%
     - 0.0059%
     - 0.0032%
     - 0.0047%
     - 0.0063%
     - 0.036%
     - 0.006%
     - 0.005%
     - 0.038%
     - 0.0058%
     - 0.014%
     - 0.0078%
     - 0.011%
     - 0.0046%
     - 0.012%
     - 0.0054%
     - 0.0057%
     - 0.025%
     - 0.0085%
     - 0.0032%
     - 0.0059%
     - 0.0033%
     - 0.0036%
     - 0.0048%
     - 0.0076%
     - 0.021%
     - 0.0056%
     - 0.007%
     - 0.014%
     - 0.015%
     - 0.0033%
     - 0.0043%
     - 0.0034%
     - 0.0035%
     - 0.0097%
     - 0.0037%
     - 0.0076%
     - 0.0042%
     - 0.0082%
     - 0.0075%
     - 0.019%
     - 0.0034%
     - 0.14%
     - 0.0064%
     - 0.035%
     - 0.0039%
     - 0.0037%
     - 0.042%
     - 0.0051%
     - 0.0073%
     - 0.0081%
     - 0.005%
     - 0.015%
     - 0.0077%
     - 0.067%
     - 0.025%
     - 0.0029%
     - 0.0073%
     - 0.024%
     - 0.045%
     - 0.048%
     - 0.025%
     - 0.0099%
     - 0.0033%
     - 0.012%
     - 1.3%
     - 0.084%
     - 0.043%
     - 0.34%
     - 0.12%
     - 0.014%
     - 0.084%
     - 0.067%
     - 0.44%
     - 0.0013%
     - 0.014%
     - 0.073%
     - 0.021%
     - 0.0059%
     - 0.3%
     - 0.0084%
     - 0.066%
     - 0.24%
     - 0.0081%
     - 0.047%
     - 0.042%
     - 0.0071%
     - 0.22%
     - 0.034%
     - 0.027%
     - 0.0095%
     - 2.6%
     - 0.037%
     - 0.084%
     - 0.0077%
     - 0.03%
     - 0.063%
     - 0.0039%
     - 0.01%
     - 0.1%
     - 0.041%
     - 0.04%
     - 0.8%
     - 0.12%
     - 0.012%
     - 0.61%
     - 0.42%
     - 0.014%
     - 0.53%
     - 0.89%
     - 0.29%
     - 0.18%
     - 0.089%
     - 0.2%
     - 0.12%
     - 0.49%
     - 0.079%
     - 0.058%
     - 0.0018%
     - 0.018%
     - 0.12%
     - 0.15%
     - 0.13%
     - 0.025%
     - 0.02%
     - 0.0066%
     - 0.11%
     - 0.023%
     - 0.21%
     - 0.057%
     - 0.021%
     - 0.12%
     - 0.005%
     - 0.18%
     - 0.0067%
     - 0.0017%
     - 0.0016%
     - 0.098%
     - 0.019%
     - 0.0077%
     - 0.00069%
     - 0.0042%
     - 0.0032%
     - 0.002%
     - 0.0012%
     - 0.0032%
     - 0.011%
     - 0.22%
     - 0.001%
     - 0.088%
     - 0.024%
     - 0.2%
     - 0.0068%
     - 0.014%
     - 0.017%
     - 0.0026%
     - 0.012%
     - 0.0086%
     - 0.0011%
     - 0.0038%
     - 0.00096%
     - 0.17%
     - 0.00061%
     - 0.0026%
     - 0.02%
     - 0.0034%
     - 0.1%
     - 0.0062%
     - 0.0015%
     - 0.0067%
     - 0.048%
     - 0.00096%
     - 0.0046%
     - 0.009%
     - 0.014%
     - 0.0086%
     - 0.0066%
     - 0.0024%
     - 0.011%
     - 0.0015%
     - 0.0097%
     - 0.0044%
     - 0.052%
     - 0.0025%
     - 0.0049%
     - 0.012%
     - 0.0029%
     - 0.00055%
     - 0.005%
     - 0.00097%
     - 0.023%
     - 0.0096%
     - 0.0018%
     - 0.075%
     - 0.0033%
     - 0.27%
     - 0.28%
     - 0.065%
     - 0.056%
     - 0.27%
     - 0.091%
     - 0.044%
     - 0.037%
     - 0.23%
     - 0.051%
     - 0.16%
     - 0.096%
     - 0.085%
     - 0.0072%
     - 0.075%
     - 0.0081%
     - 0.2%
     - 0.61%
     - 0.0044%
     - 0.076%
     - 0.058%
     - 0.058%
     - 0.15%
     - 0.021%
     - 0.011%
     - 0.0068%
     - 0.3%
     - 0.1%
     - 0.037%
     - 0.0064%
     - 0.014%
     - 0.0054%
     - 0.0051%
     - 0.0069%
     - 0.0043%
     - 0.0072%
     - 0.011%
     - 0.063%
     - 0.041%
     - 0.41%
     - 0.0064%
     - 0.058%
     - 0.016%
     - 0.0049%
     - 0.0024%
     - 0.11%
     - 0.28%
     - 0.094%
     - 0.015%
     - 0.0026%
     - 0.0063%
     - 0.13%
     - 0.12%
     - 0.059%
     - 0.75%
     - 0.04%
     - 0.027%
     - 0.071%
     - 0.014%
     - 0.38%
     - 0.1%
     - 0.5%
     - 0.17%
     - 0.38%
     - 0.21%
     - 0.027%
     - 0.05%
     - 0.17%
     - 0.14%
     - 0.072%
     - 0.1%
     - 0.048%
     - 0.014%
     - 0.0081%
     - 0.0033%
     - 0.19%
     - 0.0096%
     - 0.036%
     - 0.008%
     - 0.0063%
     - 0.0026%
     - 0.0035%
     - 0.0013%
     - 0.015%
     - 0.0056%
     - 0.02%
     - 0.03%
     - 0.0059%
     - 0.0064%
     - 0.052%
     - 0.0039%
     - 0.0059%
     - 0.0057%
     - 0.0097%
     - 0.022%
     - 0.0073%
     - 0.0069%
     - 0.0018%
     - 0.016%
     - 0.0035%
     - 0.033%
     - 0.02%
     - 0.0033%
     - 0.092%
     - 0.0025%
     - 0.0081%
     - 0.064%
     - 0.039%
     - 0.0014%
     - 0.078%
     - 0.0022%
     - 0.22%
     - 0.013%
     - 0.014%
     - 0.04%
     - 0.0054%
     - 0.039%
     - 0.0039%
     - 0.008%
     - 0.0054%
     - 0.0079%
     - 0.009%
     - 0.23%
     - 0.0073%
     - 0.0046%
     - 0.03%
     - 0.039%
     - 0.0037%
     - 0.0012%
     - 0.015%
     - 0.0071%
     - 0.0074%
     - 0.0035%
     - 0.012%
     - 0.031%
     - 0.03%
     - 0.053%
     - 0.0078%
     - 0.34%
     - 0.012%
     - 0.0011%
     - 0.031%
     - 0.017%
     - 0.008%
     - 0.0068%
     - 0.22%
     - 0.014%
     - 0.052%
     - 0.0039%
     - 0.0091%
     - 0.01%
     - 0.0097%
     - 0.0038%
     - 0.058%
     - 0.045%
     - 0.003%
     - 0.018%
     - 0.0047%
     - 0.0048%
     - 0.0054%
     - 0.0036%
     - 0.003%
     - 0.0086%
     - 0.0056%
     - 0.0032%
     - 0.016%
     - 0.008%
     - 0.02%
     - 0.0036%
     - 0.0047%
     - 0.034%
     - 0.0098%
     - 0.0045%
     - 0.0088%
     - 0.0031%
     - 0.0069%
     - 0.0069%
     - 0.0074%
     - 0.0021%
     - 0.0067%
     - 0.0082%
     - 0.0029%
     - 0.0056%
     - 0.012%
     - 0.063%
     - 0.029%
     - 0.0098%
     - 0.0048%
     - 0.04%
     - 0.0084%
     - 0.01%
     - 0.0059%
     - 0.0051%
     - 0.013%
     - 0.0035%
     - 0.0095%
     - 0.0015%
     - 0.0093%
     - 0.0027%
     - 0.065%
     - 0.025%
     - 0.0016%
     - 0.005%
     - 0.0036%
     - 0.02%
     - 0.0093%
     - 0.0017%
     - 0.01%
     - 0.0025%
     - 0.00081%
     - 0.0074%
     - 0.0034%
     - 0.0054%
     - 0.0031%
     - 0.015%
     - 0.012%
     - 0.009%
     - 0.0059%
     - 0.0024%
     - 0.021%
     - 0.0029%
     - 0.0031%
     - 0.011%
     - 0.009%
     - 0.022%
     - 0.024%
     - 0.012%
     - 0.0022%
     - 0.0068%
     - 0.009%
     - 0.001%
     - 0.0019%
     - 0.012%
     - 0.03%
     - 0.0026%
     - 0.0038%
     - 0.0033%
     - 0.0069%
     - 0.064%
     - 0.26%
     - 7.3e-05%
     - 0.023%
     - 0.053%
     - 0.0027%
     - 0.0015%
     - 0.0057%
     - 0.0049%
     - 0.0022%
     - 0.0083%
     - 0.042%
     - 0.0088%
     - 0.0076%
     - 0.0067%
     - 0.0062%
     - 0.005%
     - 0.0038%
     - 0.007%
     - 0.0049%
     - 0.006%
     - 0.017%
     - 0.0043%
     - 0.0042%
     - 0.0031%
     - 0.006%
     - 0.0067%
     - 0.016%
     - 0.0052%
     - 0.024%
     - 0.0027%
     - 0.0029%
     - 0.006%
     - 0.014%
     - 0.0099%
     - 0.03%
     - 0.0036%
     - 0.0071%
     - 0.0056%
     - 0.0036%
     - 0.0026%
     - 0.0034%
     - 0.0041%
     - 0.0043%
     - 0.0053%
     - 0.004%
     - 0.0061%
     - 0.005%
     - 0.0062%
     - 0.0032%
     - 0.0035%
     - 0.0026%
     - 0.0054%
     - 0.007%
     - 0.012%
     - 0.0056%
     - 0.044%
     - 0.0066%
     - 0.0036%
     - 0.0056%
     - 0.012%
     - 0.071%
     - 0.0037%
     - 0.0031%
     - 0.0037%
     - 0.005%
     - 0.0073%
     - 0.01%
     - 0.012%
     - 0.0045%
     - 0.0037%
     - 0.0035%
     - 0.0029%
     - 0.0039%
     - 0.013%
     - 0.005%
     - 0.0022%
     - 0.0054%
     - 0.0034%
     - 0.0079%
     - 0.0028%
     - 0.14%
     - 0.029%
     - 0.0067%
     - 0.0019%
     - 0.004%
     - 0.055%
     - 0.0041%
     - 0.0094%
     - 0.028%
     - 0.0058%
     - 0.0023%
     - 0.0044%
     - 0.0027%
     - 0.012%
     - 0.014%
     - 0.0071%
     - 0.0024%
     - 0.013%
     - 0.0039%
     - 0.0066%
     - 0.031%
     - 0.0026%
     - 0.0049%
     - 0.13%
     - 0.002%
     - 0.025%
     - 0.003%
     - 0.0034%
     - 0.012%
     - 0.011%
     - 0.004%
     - 0.018%
     - 0.03%
     - 0.0039%
     - 0.00096%
     - 0.00061%
     - 0.053%
     - 0.0024%
     - 0.0063%
     - 0.00041%
     - 0.0033%
     - 0.0024%
     - 0.0091%
     - 0.0035%
     - 0.0065%
     - 0.0053%
     - 0.0045%
     - 0.0065%
     - 0.0066%
     - 0.0061%
     - 0.049%
     - 0.012%
     - 0.0035%
     - 0.0014%
     - 0.0015%
     - 0.0095%
     - 0.0058%
     - 0.013%
     - 0.0015%
     - 0.0036%
     - 0.0068%
     - 0.0022%
     - 0.0052%
     - 0.0041%
     - 0.024%
     - 0.0089%
     - 0.0034%
     - 0.022%
     - 0.003%
     - 0.0053%
     - 0.015%
     - 0.0018%
     - 0.012%
     - 0.0021%
     - 0.0063%
     - 0.0043%
     - 0.067%
     - 0.012%
     - 0.0058%
     - 0.0047%
     - 0.012%
     - 0.017%
     - 1.6%
     - 0.0065%
     - 0.0036%
     - 0.0056%
     - 0.031%
     - 0.0063%
     - 0.27%
     - 0.0065%
     - 0.0024%
     - 0.011%
     - 0.0069%
     - 0.0047%
     - 0.014%
     - 0.012%
     - 0.002%
     - 0.0048%
     - 0.015%
     - 0.003%
     - 0.0069%
     - 0.0017%
     - 0.0029%
     - 0.016%
     - 0.01%
     - 0.021%
     - 0.0032%
     - 0.013%
     - 0.0075%
     - 0.01%
     - 0.0041%
     - 0.14%
     - 0.034%
     - 0.031%
     - 0.018%
     - 0.2%
     - 0.037%
     - 0.0048%
     - 0.011%
     - 0.012%
     - 0.0089%
     - 0.038%
     - 0.016%
     - 0.088%
     - 0.014%
     - 0.0044%
     - 0.0052%
     - 0.0053%
     - 0.011%
     - 0.087%
     - 0.053%
     - 0.0042%
     - 0.0055%
     - 0.01%
     - 0.0097%
     - 0.011%
     - 0.0047%
     - 0.017%
     - 0.062%
     - 0.0071%
     - 0.0055%
     - 0.0059%
     - 0.002%
     - 0.0023%
     - 0.0023%
     - 0.01%
     - 0.0056%
     - 0.049%
     - 0.0087%
     - 0.068%
     - 0.0026%
     - 0.0018%
     - 0.0078%
     - 0.088%
     - 0.002%
     - 0.016%
     - 0.043%
     - 0.0059%
     - 0.027%
     - 0.0041%
     - 0.0057%
     - 0.0049%
     - 0.0059%
     - 0.0053%
     - 0.019%
     - 0.18%
     - 0.023%
     - 0.094%
     - 0.011%
     - 0.0098%
     - 0.12%
     - 0.025%
     - 0.0029%
     - 0.0045%
     - 0.019%
     - 0.0063%
     - 0.0071%
     - 0.012%
     - 0.037%
     - 0.0087%
     - 0.0099%
     - 0.0041%
     - 0.0093%
     - 0.015%
     - 0.0084%
     - 0.013%
     - 0.039%
     - 0.013%
     - 0.058%
     - 0.0081%
     - 0.024%
     - 0.0058%
     - 0.0071%
     - 0.0072%
     - 0.011%
     - 0.023%
     - 0.011%
     - 0.087%
     - 0.022%
     - 0.012%
     - 0.044%
     - 0.016%
     - 0.029%
     - 0.012%
     - 0.014%
     - 0.01%
     - 0.0069%
     - 0.011%
     - 0.009%
     - 0.044%
     - 0.013%
     - 0.028%
     - 0.011%
     - 0.16%
     - 0.036%
     - 0.016%
     - 0.044%
     - 0.31%
     - 0.015%
     - 0.0035%
     - 0.011%
     - 0.045%
     - 0.012%
     - 0.021%
     - 0.0045%
     - 0.015%
     - 0.0021%
     - 0.0068%
     - 0.0075%
     - 0.006%
     - 0.0064%
     - 0.0043%
     - 0.05%
     - 0.0085%
     - 0.0045%
     - 0.011%
     - 0.0087%
     - 0.009%
     - 0.0056%
     - 0.0078%
     - 0.014%
     - 0.0067%
     - 0.086%
     - 0.0082%
     - 0.015%
     - 0.0066%
     - 0.0038%
     - 0.055%
     - 0.0052%
     - 0.0024%
     - 0.062%
     - 0.0056%
     - 0.035%
     - 0.011%
     - 0.0027%
     - 0.019%
     - 0.0091%
     - 0.023%
     - 0.0087%
     - 0.0097%
     - 0.011%
     - 0.0047%
     - 0.0028%
     - 0.0052%
     - 0.0021%
     - 0.0094%
     - 0.0053%
     - 0.0035%
     - 0.02%
     - 0.0011%
     - 0.0016%
     - 0.0073%
     - 0.0011%
     - 0.00086%
     - 0.003%
     - 0.0035%
     - 0.003%
     - 0.00075%
     - 0.012%
     - 0.013%
     - 0.0013%
     - 0.0068%
     - 0.0026%
     - 0.036%
     - 0.0012%
     - 0.0013%
     - 0.0097%
     - 0.0024%
     - 0.0099%
     - 0.009%
     - 0.0083%
     - 0.011%
     - 0.001%
     - 0.0011%
     - 0.0022%
     - 0.0018%
     - 0.00046%
     - 0.003%
     - 0.00082%
     - 0.0024%
     - 0.011%
     - 0.0012%
     - 0.00078%
     - 0.0043%
     - 0.0061%
     - 0.0015%
     - 0.17%
     - 0.0012%
     - 0.0028%
     - 0.00091%
     - 0.0075%
     - 0.00073%
     - 0.022%
     - 0.0014%
     - 0.0041%
     - 0.0011%
     - 0.011%
     - 0.0044%
     - 0.0037%
     - 0.0096%
     - 0.0015%
     - 0.0099%
     - 0.0025%
     - 0.012%
     - 0.0024%
     - 0.0011%
     - 0.0034%
     - 0.0057%
     - 0.0013%
     - 0.0019%
     - 0.0056%
     - 0.0016%
     - 0.0021%
     - 0.0023%
     - 0.0023%
     - 0.0068%
     - 0.0033%
     - 0.0011%
     - 0.021%
     - 0.0022%
     - 0.0034%
     - 0.022%
     - 0.0021%
     - 0.0013%
     - 0.0029%
     - 0.018%
     - 0.0017%
     - 0.16%
     - 0.0061%
     - 0.059%
     - 0.00094%
     - 0.0023%
     - 0.0017%
     - 0.0017%
     - 0.00082%
     - 0.0017%
     - 0.0081%
     - 0.0026%
     - 0.0013%
     - 0.0024%
     - 0.00059%
     - 0.0022%
     - 0.00072%
     - 0.0035%
     - 0.0015%
     - 0.05%
     - 0.0063%
     - 0.007%
     - 0.0069%
     - 0.0029%
     - 0.014%
     - 0.004%
     - 0.0098%
     - 0.036%
     - 0.0067%
     - 0.016%
     - 0.0092%
     - 0.0029%
     - 0.0046%
     - 0.0079%
     - 0.023%
     - 0.0044%
     - 0.0047%
     - 0.014%
     - 0.03%
     - 0.0018%
     - 0.0035%
     - 0.0092%
     - 0.0055%
     - 0.022%
     - 0.012%
     - 0.0066%
     - 0.0039%
     - 0.0034%
     - 0.0027%
     - 0.032%
     - 0.0048%
     - 0.0025%
     - 0.0051%
     - 0.1%
     - 0.0049%
     - 0.014%
     - 0.017%
     - 0.0025%
     - 0.0029%
     - 0.0056%
     - 0.0074%
     - 0.012%
     - 0.01%
     - 0.0039%
     - 0.012%
     - 0.0028%
     - 0.034%
     - 0.01%
     - 0.0061%
     - 0.0065%
     - 0.015%
     - 0.005%
     - 0.0017%
     - 0.016%
     - 0.0049%
     - 0.25%
     - 0.015%
     - 0.0079%
     - 0.052%
     - 0.0056%
     - 0.011%
     - 0.0047%
     - 0.019%
     - 0.0054%
     - 0.0026%
     - 0.0039%
     - 0.0086%
     - 0.0048%
     - 0.0081%
     - 0.0036%
     - 0.0092%
     - 0.0036%
     - 0.027%
     - 0.0044%
     - 0.0061%
     - 0.012%
     - 0.0038%
     - 0.0061%
     - 0.024%
     - 0.0055%
     - 0.0032%
     - 0.0091%
     - 0.0029%
     - 0.0075%
     - 0.0035%
     - 0.0039%
     - 0.0088%
     - 0.0044%
     - 0.01%
     - 0.014%
     - 0.0024%
     - 0.0076%
     - 0.016%
     - 0.0042%
     - 0.0016%
     - 0.0047%
     - 0.0095%
     - 0.023%
     - 0.0042%
     - 0.023%
     - 0.00086%
     - 0.0057%
     - 0.0076%
     - 0.0074%
     - 0.015%
     - 0.013%
     - 0.0056%
     - 0.0052%
     - 0.0082%
     - 0.0039%
     - 0.0058%
     - 0.0029%
     - 0.0046%
     - 0.037%
     - 0.0038%
     - 0.0081%
     - 0.0044%
     - 0.011%
     - 0.0027%
     - 0.0082%
     - 0.019%
     - 0.0073%
     - 0.033%
     - 0.0078%
     - 0.014%
     - 0.011%
     - 0.0058%
     - 0.04%
     - 0.084%
     - 0.064%
     - 0.0038%
     - 0.0027%
     - 0.0037%
     - 0.0058%
     - 0.007%
     - 0.0093%
     - 0.14%
     - 0.0023%
     - 0.0061%
     - 0.011%
     - 0.0068%
     - 0.0067%
     - 0.022%
     - 0.0097%
     - 0.0058%
     - 0.01%
     - 0.14%
     - 0.0049%
     - 0.073%
     - 0.03%
     - 0.015%
     - 0.04%
     - 0.0037%
     - 0.0093%
     - 0.014%
     - 0.14%
     - 0.049%
     - 0.0074%
     - 0.0084%
     - 0.043%
     - 0.0031%
     - 0.0066%
     - 0.011%
     - 0.013%
     - 0.015%
     - 0.0038%
     - 0.0065%
     - 0.013%
     - 0.027%
     - 0.017%
     - 0.017%
     - 0.074%
     - 0.039%
     - 0.0025%
     - 0.033%
     - 0.0085%
     - 0.019%
     - 0.016%
     - 0.016%
     - 0.014%
     - 0.0075%
     - 0.0038%
     - 0.0039%
     - 0.0054%
     - 0.12%
     - 0.051%
     - 0.17%
     - 0.013%
     - 0.23%
     - 0.025%
     - 0.14%
     - 0.047%
     - 0.46%
     - 0.0088%
     - 0.2%
     - 0.15%
     - 0.24%
     - 0.25%
     - 0.025%
     - 0.16%
     - 0.22%
     - 0.25%
     - 0.026%
     - 0.01%
     - 0.047%
     - 0.032%
     - 0.043%
     - 0.012%
     - 0.07%
     - 0.014%
     - 0.073%
     - 0.086%
     - 0.008%
     - 0.29%
     - 0.25%
     - 0.015%
     - 0.0084%
     - 0.032%
     - 0.015%
     - 0.046%
     - 0.031%
     - 0.042%
     - 0.037%
     - 0.029%
     - 0.1%
     - 0.016%
     - 0.03%
     - 0.046%
     - 0.018%
     - 0.018%
     - 0.027%
     - 0.055%
     - 0.011%
     - 0.014%
     - 0.023%
     - 0.016%
     - 0.017%
     - 0.08%
     - 0.0082%
     - 0.0049%
     - 0.037%
     - 0.012%
     - 0.013%
     - 0.0073%
     - 0.0039%
     - 0.02%
     - 0.036%
     - 0.0092%
     - 0.057%
     - 0.015%
     - 0.045%
     - 0.019%
     - 0.013%
     - 0.014%
     - 0.016%
     - 0.017%
     - 0.023%
     - 0.0083%
     - 0.015%
     - 0.01%
     - 0.035%
     - 0.016%
     - 0.14%
     - 0.013%
     - 0.008%
     - 0.032%
     - 0.012%
     - 0.016%
     - 0.014%
     - 0.016%
     - 0.091%
     - 0.018%
     - 0.015%
     - 0.0069%
     - 0.021%
     - 0.052%
     - 0.083%
     - 0.009%
     - 0.19%
     - 0.0018%
     - 0.011%
     - 0.027%
     - 0.011%
     - 0.032%
     - 0.056%
     - 0.0032%
     - 0.0082%
     - 0.27%
     - 0.012%
     - 0.026%
     - 0.013%
     - 0.016%
     - 0.011%
     - 0.027%
     - 0.0068%
     - 0.047%
     - 0.021%
     - 0.0071%
     - 0.055%
     - 0.019%
     - 0.4%
     - 0.012%
     - 0.012%
     - 0.0042%
     - 0.01%
     - 0.0068%
     - 0.011%
     - 0.078%
     - 0.0078%
     - 0.018%
     - 0.065%
     - 0.017%
     - 0.0047%
     - 0.022%
     - 0.054%
     - 0.021%
     - 0.018%
     - 0.027%
     - 0.11%
     - 0.61%
     - 0.012%
     - 0.012%
     - 0.096%
     - 0.014%
     - 0.016%
     - 0.012%
     - 0.0023%
     - 0.02%
     - 0.0086%
     - 0.012%
     - 0.027%
     - 0.019%
     - 0.0043%
     - 0.016%
     - 0.019%
     - 0.0036%
     - 0.0043%
     - 0.004%
     - 0.031%
     - 0.12%
     - 0.006%
     - 0.015%
     - 0.0052%
     - 0.0073%
     - 0.011%
     - 0.015%
     - 0.0025%
     - 0.39%
     - 0.0064%
     - 0.011%
     - 0.012%
     - 0.02%
     - 0.0037%
     - 0.0058%
     - 0.015%
     - 0.0019%
     - 0.0059%
     - 0.0027%
     - 0.0058%
     - 0.0027%
     - 0.0093%
     - 0.0023%
     - 0.0083%
     - 0.0021%
     - 0.0036%
     - 0.0074%
     - 0.012%
     - 0.008%
     - 0.0095%
     - 0.012%
     - 0.013%
     - 0.0034%
     - 0.0098%
     - 0.0064%
     - 0.0025%
     - 0.046%
     - 0.027%
     - 0.0047%
     - 0.013%
     - 0.0033%
     - 0.011%
     - 0.0049%
     - 0.16%
     - 0.0014%
     - 0.0054%
     - 0.0054%
     - 0.018%
     - 0.0032%
     - 0.0056%
     - 0.037%
     - 0.025%
     - 0.0049%
     - 0.077%
     - 0.047%
     - 0.011%
     - 0.0031%
     - 0.0036%
     - 0.0097%
     - 0.0015%
     - 0.0075%
     - 0.0052%
     - 0.0059%
     - 0.071%
     - 0.0038%
     - 0.0023%
     - 0.016%
     - 0.037%
     - 0.0035%
     - 0.0085%
     - 0.0054%
     - 0.0022%
     - 0.0081%
     - 0.013%
     - 0.0042%
     - 0.0058%
     - 0.01%
     - 0.0044%
     - 0.055%
     - 0.029%
     - 0.015%
     - 0.0034%
     - 0.014%
     - 0.031%
     - 0.025%
     - 0.0034%
     - 0.0024%
     - 0.03%
     - 0.0054%
     - 0.0031%
     - 0.024%
     - 0.0026%
     - 0.071%
     - 0.0066%
     - 0.024%
     - 0.0056%
     - 0.0089%
     - 0.0029%
     - 0.0057%
     - 0.0031%
     - 0.0032%
     - 0.0054%
     - 0.0048%
     - 0.011%
     - 0.033%
     - 0.0061%
     - 0.0024%
     - 0.096%
     - 0.0037%
     - 0.0033%
     - 0.0081%
     - 0.005%
     - 0.0021%
     - 0.0034%
     - 0.013%
     - 0.0039%
     - 0.24%
     - 0.038%
     - 0.066%
     - 0.016%
     - 0.0017%
     - 0.012%
     - 0.011%
     - 0.012%
     - 0.0034%
     - 0.016%
     - 0.0048%
     - 0.005%
     - 0.0057%
     - 0.0044%
     - 0.0034%
     - 0.0096%
     - 0.0073%
     - 0.0016%
     - 0.0095%
     - 0.0043%
     - 0.0046%
     - 0.0036%
     - 0.0046%
     - 0.011%
     - 0.0064%
     - 0.018%
     - 0.0072%
     - 0.0041%
     - 0.0049%
     - 0.0042%
     - 0.0061%
     - 0.0064%
     - 0.014%
     - 0.015%
     - 0.0058%
     - 0.03%
     - 0.01%
     - 0.014%
     - 0.0022%
     - 0.0038%
     - 0.008%
     - 0.0074%
     - 0.003%
     - 0.0049%
     - 0.0075%
     - 0.0016%
     - 0.0018%
     - 0.013%
     - 0.0031%
     - 0.0024%
     - 0.11%
     - 0.0042%
     - 0.022%
     - 0.13%
     - 0.33%
     - 0.0064%
     - 0.01%
     - 0.015%
     - 0.0025%
     - 0.022%
     - 0.0087%
     - 0.0071%
     - 0.011%
     - 0.0081%
     - 0.006%
     - 0.011%
     - 0.00095%
     - 0.0065%
     - 0.011%
     - 0.013%
     - 0.0049%
     - 0.0068%
     - 0.0031%
     - 0.011%
     - 0.0052%
     - 0.0038%
     - 0.0056%
     - 0.0031%
     - 0.0031%
     - 0.0059%
     - 0.0069%
     - 0.008%
     - 0.0091%
     - 0.0063%
     - 0.048%
     - 0.024%
     - 0.0031%
     - 0.007%
     - 0.0038%
     - 0.0076%
     - 0.018%
     - 0.067%
     - 0.078%
     - 0.0063%
     - 0.0029%
     - 0.00041%
     - 0.0076%
     - 0.046%
     - 0.0061%
     - 0.0027%
     - 0.0044%
     - 0.021%
     - 0.0035%
     - 0.018%
     - 0.018%
     - 0.026%
     - 0.0045%
     - 0.007%
     - 0.027%
     - 0.0098%
     - 0.011%
     - 0.02%
     - 0.031%
     - 0.0088%
     - 0.011%
     - 0.012%
     - 0.004%
     - 0.0092%
     - 0.007%
     - 0.0039%
     - 0.016%
     - 0.011%
     - 0.018%
     - 0.0041%
     - 0.013%
     - 0.0094%
     - 0.0083%
     - 0.0027%
     - 0.043%
     - 0.0086%
     - 0.0016%
     - 0.0089%
     - 0.0054%
     - 0.0054%
     - 0.0072%
     - 0.0041%
     - 0.0083%
     - 0.0073%
     - 0.0077%
     - 0.0036%
     - 0.0088%
     - 0.0053%
     - 0.016%
     - 0.016%
     - 0.0069%
     - 0.0036%
     - 0.0038%
     - 0.0065%
     - 0.0048%
     - 0.0075%
     - 0.0039%
     - 0.0035%
     - 0.0021%
     - 0.002%
     - 0.0048%
     - 0.00059%
     - 0.028%
     - 0.0021%
     - 0.0042%
     - 0.00085%
     - 0.0032%
     - 0.0038%
     - 0.0011%
     - 0.0043%
     - 0.035%
     - 0.034%
     - 0.00063%
     - 0.004%
     - 0.00034%
     - 0.0021%
     - 0.0054%
     - 0.0038%
     - 0.001%
     - 0.012%
     - 0.023%
     - 0.00081%
     - 0.0086%
     - 0.0052%
     - 0.00076%
     - 0.001%
     - 0.0018%
     - 0.038%
     - 0.002%
     - 0.007%
     - 0.00024%
     - 0.0017%
     - 0.002%
     - 0.00077%
     - 0.0023%
     - 0.0005%
     - 0.015%
     - 0.0038%
     - 0.003%
     - 0.0031%
     - 0.005%
     - 0.0016%
     - 0.013%
     - 0.0036%
     - 0.0015%
     - 0.0021%
     - 0.0018%
     - 0.00034%
     - 0.0036%
     - 0.00097%
     - 0.00042%
     - 0.05%
     - 0.051%
     - 0.012%
     - 0.006%
     - 0.0086%
     - 0.013%
     - 0.01%
     - 0.019%
     - 0.0073%
     - 0.013%
     - 0.061%
     - 0.087%
     - 0.03%
     - 0.056%
     - 0.028%
     - 0.0031%
     - 0.037%
     - 0.0079%
     - 0.051%
     - 0.022%
     - 0.013%
     - 0.0054%
     - 0.0054%
     - 0.032%
     - 0.019%
     - 0.034%
     - 0.11%
     - 0.011%
     - 0.025%
     - 0.054%
     - 0.014%
     - 0.019%
     - 0.096%
     - 0.018%
     - 0.12%
     - 0.02%
     - 0.067%
     - 0.0039%
     - 0.0044%
     - 0.017%
     - 0.0061%
     - 0.17%
     - 0.019%
     - 0.037%
     - 0.026%
     - 0.041%
     - 0.0079%
     - 0.015%
     - 0.0025%
     - 0.053%
     - 0.02%
     - 0.052%
     - 0.0036%
     - 0.018%
     - 0.02%
     - 0.025%
     - 0.019%
     - 0.008%
     - 0.0086%
     - 0.016%
     - 0.31%
     - 0.0065%
     - 0.012%
     - 0.034%
     - 0.032%
     - 0.079%
     - 0.0086%
     - 0.056%
     - 0.042%
     - 0.0057%
     - 0.013%
     - 0.02%
     - 0.0052%
     - 0.014%
     - 0.057%
     - 0.0086%
     - 0.046%
     - 0.016%
     - 0.039%
     - 0.033%
     - 0.045%
     - 0.025%
     - 0.02%
     - 0.011%
     - 0.02%
     - 0.016%
     - 0.025%
     - 0.0066%
     - 0.014%
     - 0.0015%
     - 0.057%
     - 0.015%
     - 0.3%
     - 0.0088%
     - 0.0048%
     - 0.025%
     - 0.04%
     - 0.025%
     - 0.027%
     - 0.013%
     - 0.0083%
     - 0.001%
     - 0.0043%
     - 0.0022%
     - 0.00039%
     - 0.0033%
     - 0.0013%
     - 0.001%
     - 0.03%
     - 0.056%
     - 0.0017%
     - 0.002%
     - 0.0011%
     - 0.0018%
     - 0.00098%
     - 0.0016%
     - 0.0013%
     - 0.00075%
     - 0.023%
     - 0.0013%
     - 0.0011%
     - 0.0011%
     - 0.0013%
     - 0.0017%
     - 0.00088%
     - 0.0023%
     - 0.0014%
     - 0.0034%
     - 0.0044%
     - 0.0035%
     - 0.01%
     - 0.0035%
     - 0.0014%
     - 0.00071%
     - 0.0029%
     - 0.0017%
     - 0.0043%
     - 0.002%
     - 0.00095%
     - 0.0057%
     - 0.0041%
     - 0.0015%
     - 0.00065%
     - 0.00099%
     - 0.00033%
     - 0.01%
     - 0.00093%
     - 0.0075%
     - 0.00099%
     - 0.0028%
     - 0.0042%
     - 0.023%
     - 0.0019%
     - 0.012%
     - 0.01%
     - 0.0024%
     - 0.00019%
     - 0.00029%
     - 0.00026%
     - 0.002%
     - 0.0041%
     - 0.001%
     - 0.0014%
     - 0.015%
     - 0.0026%
     - 0.003%
     - 0.0084%
     - 0.0031%
     - 0.0014%
     - 0.0023%
     - 0.0037%
     - 0.0022%
     - 0.0031%
     - 0.0031%
     - 0.0042%
     - 0.0058%
     - 0.0032%
     - 0.0076%
     - 0.00074%
     - 0.002%
     - 0.012%
     - 0.17%
     - 0.00082%
     - 0.0022%
     - 0.0013%
     - 0.0011%
     - 0.002%
     - 0.0078%
     - 0.001%
     - 0.0009%
     - 0.00093%
     - 0.00029%
     - 0.00097%
     - 0.018%
     - 0.003%
     - 0.0018%
     - 0.00039%
     - 0.0013%
     - 0.0039%
     - 0.00032%
     - 0.0022%
     - 0.0029%
     - 0.0016%
     - 0.0022%
     - 0.004%
     - 0.00038%
     - 0.0015%
     - 0.0036%
     - 0.093%
     - 0.012%
     - 0.00031%
     - 0.00031%
     - 0.011%
     - 0.00018%
     - 0.0028%
     - 0.0018%
     - 0.0014%
     - 0.0026%
     - 0.0018%
     - 0.0053%
     - 0.0012%
     - 0.0011%
     - 0.0031%
     - 0.0024%
     - 0.01%
     - 0.002%
     - 0.0039%
     - 0.0033%
     - 0.00065%
     - 0.0043%
     - 0.049%
     - 0.007%
     - 0.012%
     - 0.0052%
     - 0.0022%
     - 0.0014%
     - 0.00058%
     - 0.002%
     - 0.002%
     - 0.00029%
     - 0.0018%
     - 0.0017%
     - 0.0063%
     - 0.0029%
     - 0.0014%
     - 0.00041%
     - 0.0047%
     - 0.028%
     - 0.03%
     - 0.026%
     - 0.016%
     - 0.039%
     - 0.13%
     - 0.048%
     - 0.096%
     - 0.039%
     - 0.017%
     - 0.095%
     - 0.26%
     - 0.13%
     - 0.15%
     - 0.074%
     - 0.042%
     - 0.23%
     - 0.084%
     - 0.21%
     - 0.037%
     - 0.11%
     - 0.22%
     - 0.19%
     - 0.14%
     - 0.21%
     - 0.13%
     - 0.021%
     - 0.093%
     - 0.046%
     - 0.15%
     - 0.034%
     - 0.21%
     - 0.0029%
     - 0.02%
     - 0.0083%
     - 0.0075%
     - 0.015%
     - 0.00076%
     - 0.063%
     - 0.017%
     - 0.011%
     - 0.0017%
     - 0.00038%
     - 0.0018%
     - 0.019%
     - 0.013%
     - 0.0062%
     - 0.0082%
     - 0.019%
     - 0.0022%
     - 0.023%
     - 0.0041%
     - 0.015%
     - 0.0062%
     - 0.037%
     - 0.012%
     - 0.04%
     - 0.054%
     - 0.0062%
     - 0.006%
     - 0.015%
     - 0.0058%
     - 0.0017%
     - 0.023%
     - 0.017%
     - 0.008%
     - 0.64%
     - 0.018%
     - 0.015%
     - 0.00072%
     - 0.00085%
     - 0.0054%
     - 0.0019%
     - 0.0019%
     - 0.017%
     - 0.0021%
     - 0.016%
     - 0.0018%
     - 0.0015%
     - 0.14%
     - 0.0033%
     - 0.1%
     - 0.019%
     - 0.39%
     - 0.067%
     - 0.031%
     - 0.027%
     - 0.05%
     - 0.029%
     - 0.019%
     - 0.027%
     - 0.025%
     - 0.015%
     - 0.023%
     - 0.089%
     - 0.31%
     - 0.019%
     - 0.019%
     - 0.021%
     - 0.019%
     - 0.022%
     - 0.0065%
     - 0.025%
     - 0.044%
     - 0.76%
     - 0.011%
     - 0.02%
     - 0.024%
     - 0.24%
     - 0.017%
     - 0.35%
     - 0.65%
     - 0.074%
     - 0.078%
     - 0.15%
     - 0.037%
     - 0.1%
     - 0.014%
     - 0.04%
     - 0.023%
     - 0.029%
     - 0.63%
     - 0.054%
     - 0.13%
     - 0.078%
     - 0.076%
     - 0.051%
     - 0.013%
     - 0.0071%
     - 0.012%
     - 0.039%
     - 0.036%
     - 0.43%
     - 0.037%
     - 0.017%
     - 0.031%
     - 0.062%
     - 0.029%
     - 0.022%
     - 0.031%
     - 0.28%
     - 0.013%
     - 0.01%
     - 0.0095%
     - 0.033%
     - 0.016%
     - 0.034%
     - 0.02%
     - 0.015%
     - 0.024%
     - 0.015%
     - 0.11%
     - 0.01%
     - 0.012%
     - 0.046%
     - 0.061%
     - 0.013%
     - 0.035%
     - 0.012%
     - 0.015%
     - 0.46%
     - 0.017%
     - 0.012%
     - 0.052%
     - 0.028%
     - 0.044%
     - 0.0095%
     - 0.4%
     - 0.013%
     - 0.01%
     - 0.027%
     - 0.052%
     - 0.014%
     - 0.28%
     - 0.025%
     - 0.0098%
     - 0.006%
     - 0.0089%
     - 0.014%
     - 0.0099%
     - 0.01%
     - 0.019%
     - 0.011%
     - 0.024%
     - 0.019%
     - 0.076%
     - 0.02%
     - 0.052%
     - 0.017%
     - 0.096%
     - 0.15%
     - 0.012%
     - 0.083%
     - 0.021%
     - 0.053%
     - 0.0082%
     - 0.013%
     - 0.033%
     - 0.0056%
     - 0.19%
     - 0.0058%
     - 0.011%
     - 0.028%
     - 0.0045%
     - 0.021%
     - 0.0065%
     - 0.011%
     - 0.016%
     - 0.0093%
     - 0.051%
     - 0.013%
     - 0.01%
     - 0.04%
     - 0.024%
     - 0.02%
     - 0.025%
     - 0.018%
     - 0.015%
     - 0.12%
     - 0.18%
     - 0.071%
     - 0.03%
     - 0.015%
     - 0.0094%
     - 0.0046%
     - 0.062%
     - 0.021%
     - 0.034%
     - 0.012%
     - 0.04%
     - 0.0074%
     - 0.0069%
     - 0.002%
     - 0.0047%
     - 0.002%
     - 0.0074%
     - 0.0036%
     - 0.015%
     - 0.0099%
     - 0.035%
     - 0.016%
     - 0.016%
     - 0.0056%
     - 0.0012%
     - 0.082%
     - 0.0021%
     - 0.038%
     - 0.0022%
     - 0.005%
     - 0.022%
     - 0.0093%
     - 0.019%
     - 0.0018%
     - 0.0017%
     - 0.02%
     - 0.0096%
     - 0.017%
     - 0.0018%
     - 0.002%
     - 0.0011%
     - 0.0014%
     - 0.0045%
     - 0.0047%
     - 0.0091%
     - 0.0025%
     - 0.0038%
     - 0.016%
     - 0.0048%
     - 0.0039%
     - 0.0037%
     - 0.016%
     - 0.011%
     - 0.013%
     - 0.0034%
     - 0.0027%
     - 0.0075%
     - 0.014%
     - 0.011%
     - 0.012%
     - 0.01%
     - 0.0051%
     - 0.023%
     - 0.004%
     - 0.0036%
     - 0.004%
     - 0.25%
     - 0.013%
     - 0.016%
     - 0.01%
     - 0.0058%
     - 0.026%
     - 0.017%
     - 0.012%
     - 0.022%
     - 0.0046%
     - 0.0014%
     - 0.027%
     - 0.0087%
     - 0.014%
     - 0.015%
     - 0.0061%
     - 0.003%
     - 0.21%
     - 0.023%
     - 0.018%
     - 0.0041%
     - 0.0033%
     - 0.0067%
     - 0.0066%
     - 0.028%
     - 0.12%
     - 0.016%
     - 0.015%
     - 0.023%
     - 0.0077%
     - 0.0094%
     - 0.062%
     - 0.037%
     - 0.00078%
     - 0.0032%
     - 0.0028%
     - 0.0071%
     - 0.069%
     - 0.0073%
     - 0.028%
     - 0.024%
     - 0.0033%
     - 0.12%
     - 0.023%
     - 0.037%
     - 0.0087%
     - 0.092%
     - 0.0033%
     - 0.25%
     - 0.023%
     - 0.0007%
     - 0.014%
     - 0.022%
     - 0.0086%
     - 0.0031%
     - 0.0085%
     - 0.16%
     - 0.00073%
     - 0.028%
     - 0.031%
     - 0.44%
     - 0.024%
     - 0.058%
     - 0.018%
     - 0.12%
     - 0.042%
     - 0.022%
     - 0.18%
     - 0.06%
     - 0.049%
     - 0.0033%
     - 0.026%
     - 0.048%
     - 0.15%
     - 0.015%
     - 0.029%
     - 0.014%
     - 0.022%
     - 0.033%
     - 0.077%
     - 0.091%
     - 0.17%
     - 0.013%
     - 0.089%
     - 0.047%
     - 0.0063%
     - 0.048%
     - 0.0053%
     - 0.012%
     - 0.017%
     - 0.029%
     - 0.017%
     - 0.0082%
     - 0.073%
     - 0.15%
     - 0.03%
     - 0.042%
     - 0.11%
     - 0.11%
     - 0.039%
     - 0.016%
     - 0.038%
     - 0.016%
     - 0.06%
     - 0.24%
     - 0.006%
     - 0.09%
     - 0.034%
     - 0.015%
     - 0.5%
     - 0.029%
     - 0.0096%
     - 0.051%
     - 0.012%
     - 0.028%
     - 0.0047%
     - 0.017%
     - 0.016%
     - 0.013%
     - 0.02%
     - 0.017%
     - 0.07%
     - 0.024%
     - 0.13%
     - 0.0099%
     - 0.13%
     - 0.016%
     - 0.055%
     - 0.031%
     - 0.2%
     - 0.047%
     - 0.009%
     - 0.055%
     - 0.0033%
     - 0.064%
     - 0.0057%
     - 0.0077%
     - 0.071%
     - 0.058%
     - 0.0054%
     - 0.13%
     - 0.018%
     - 0.011%
     - 0.016%
     - 0.013%
     - 0.015%
     - 0.023%
     - 0.01%
     - 0.043%
     - 0.0079%
     - 0.0087%
     - 0.044%
     - 0.025%
     - 0.15%
     - 0.023%
     - 0.0067%
     - 0.14%
     - 0.0081%
     - 0.021%
     - 0.025%
     - 0.023%
     - 0.0057%
     - 0.089%
     - 0.011%
     - 0.0089%
     - 0.0041%
     - 0.013%
     - 0.029%
     - 0.031%
     - 0.039%
     - 0.12%
     - 0.0069%
     - 0.093%
     - 0.035%
     - 0.01%
     - 0.011%
     - 0.074%
     - 0.00099%
     - 0.0062%
     - 0.00086%
     - 0.0022%
     - 0.01%
     - 0.013%
     - 0.0018%
     - 0.00043%
     - 0.0035%
     - 0.00074%
     - 0.0029%
     - 0.0013%
     - 0.0043%
     - 0.0095%
     - 0.0011%
     - 0.0036%
     - 0.0068%
     - 0.0027%
     - 0.0016%
     - 0.0015%
     - 0.0011%
     - 0.0015%
     - 0.0031%
     - 0.00089%
     - 0.0026%
     - 0.0019%
     - 0.00078%
     - 0.0021%
     - 0.0014%
     - 0.00088%
     - 0.0005%
     - 0.0058%
     - 0.0025%
     - 0.00052%
     - 0.00096%
     - 0.00079%
     - 0.00039%
     - 0.002%
     - 0.0042%
     - 0.01%
     - 0.014%
     - 0.0013%
     - 0.0019%
     - 0.0019%
     - 0.001%
     - 0.0086%
     - 0.00064%
     - 0.00094%
     - 0.057%
     - 0.0021%
     - 0.0027%
     - 0.035%
     - 0.0013%
     - 0.0012%
     - 0.0037%
     - 0.00093%
     - 0.0024%
     - 0.0011%
     - 0.0006%
     - 0.0023%
     - 0.0023%
     - 0.003%
     - 0.005%
     - 0.0022%
     - 0.0073%
     - 0.00074%
     - 0.026%
     - 0.014%
     - 0.0067%
     - 0.0042%
     - 0.042%
     - 0.032%
     - 0.015%
     - 0.0045%
     - 0.0098%
     - 0.021%
     - 0.012%
     - 0.0052%
     - 0.011%
     - 0.0032%
     - 0.013%
     - 0.018%
     - 0.0048%
     - 0.021%
     - 0.22%
     - 0.0051%
     - 0.007%
     - 0.016%
     - 0.013%
     - 0.012%
     - 0.0067%
     - 0.014%
     - 0.017%
     - 0.01%
     - 0.0081%
     - 0.024%
     - 0.0048%
     - 0.02%
     - 0.12%
     - 0.0027%
     - 0.0081%
     - 0.01%
     - 0.02%
     - 0.0063%
     - 0.0096%
     - 0.013%
     - 0.0077%
     - 0.0031%
     - 0.0066%
     - 0.0043%
     - 0.018%
     - 0.0067%
     - 0.15%
     - 0.0019%
     - 0.0084%
     - 0.014%
     - 0.0041%
     - 0.011%
     - 0.017%
     - 0.0074%
     - 0.032%
     - 0.0097%
     - 0.0099%
     - 0.027%
     - 0.017%
     - 0.0089%
     - 0.0042%
     - 0.016%
     - 0.057%
     - 0.0022%
     - 0.0066%
     - 0.011%
     - 0.0077%
     - 0.0034%
     - 0.0026%
     - 0.0062%
     - 0.025%
     - 0.011%
     - 0.019%
     - 0.02%
     - 0.082%
     - 0.0074%
     - 0.0048%
     - 0.042%
     - 0.3%
     - 0.0064%
     - 0.005%
     - 0.055%
     - 0.051%
     - 0.017%
     - 0.0026%
     - 0.0066%
     - 0.0068%
     - 0.002%
     - 0.013%
     - 0.044%
     - 0.0054%
     - 0.012%
     - 0.0087%
     - 0.055%
     - 0.037%
     - 0.015%
     - 0.0045%
     - 0.027%
     - 0.012%
     - 0.0031%
     - 0.00069%
     - 0.013%
     - 0.0097%
     - 0.002%
     - 0.0087%
     - 0.022%
     - 0.002%
     - 0.0079%
     - 0.1%
     - 0.51%
     - 0.0042%
     - 0.0003%
     - 0.0072%
     - 0.029%
     - 0.095%
     - 0.062%
     - 0.0041%
     - 0.00075%
     - 0.0023%
     - 0.014%
     - 0.0066%
     - 0.016%
     - 0.01%
     - 0.0087%
     - 0.0049%
     - 0.11%
     - 0.0042%
     - 0.0021%
     - 0.011%
     - 0.0024%
     - 0.011%
     - 0.016%
     - 0.0022%
     - 0.0038%
     - 0.001%
     - 0.002%
     - 0.0041%
     - 0.25%
     - 0.0011%
     - 0.0079%
     - 0.039%
     - 0.0054%
     - 0.0012%
     - 0.012%
     - 0.019%
     - 0.00078%
     - 0.0012%
     - 0.0014%
     - 0.0022%
     - 0.00075%
     - 0.0022%
     - 0.73%
     - 0.0039%
     - 0.0053%
     - 0.0018%
     - 0.21%
     - 0.0068%
     - 0.001%
     - 0.0032%
     - 0.0016%
     - 0.0041%
     - 0.0076%
     - 0.042%
     - 0.0013%
     - 0.21%
     - 0.043%
     - 0.013%
     - 0.0058%
     - 0.011%
     - 0.01%
     - 0.0016%
     - 0.0022%
     - 0.00064%
     - 0.17%
     - 0.0043%
     - 0.0069%
     - 0.0044%
     - 0.0047%
     - 0.1%
     - 0.0016%
     - 0.0096%
     - 0.00041%
     - 0.0028%
     - 0.0066%
     - 0.0075%
     - 0.041%
     - 0.038%
     - 0.0082%
     - 0.04%
     - 0.01%
     - 0.0014%
     - 0.0034%
     - 0.0017%
     - 0.0018%
     - 0.018%
     - 1.3%
     - 0.021%
     - 0.0015%
     - 0.0026%
     - 0.052%
     - 0.0013%
     - 0.03%
     - 0.2%
     - 0.012%
     - 0.0069%
     - 0.019%
     - 0.011%
     - 0.0086%
     - 0.0098%
     - 0.0011%
     - 0.028%
     - 0.0079%
     - 0.00065%
     - 0.0031%
     - 0.0049%
     - 0.013%
     - 0.0012%
     - 0.08%
     - 0.0018%
     - 0.012%
     - 0.044%
     - 0.0055%
     - 0.0043%
     - 0.029%
     - 0.011%
     - 0.00021%
     - 0.00035%
     - 0.018%
     - 0.0026%
     - 0.00012%
     - 0.0013%
     - 0.0098%
     - 0.0015%
     - 0.0023%
     - 0.017%
     - 0.0046%
     - 0.0067%
     - 0.0077%
     - 0.0057%
     - 0.0071%
     - 0.022%
     - 0.0079%
     - 0.0011%
     - 0.0045%
     - 0.011%
     - 4.8e-05%
     - 0.09%
     - 0.002%
     - 0.0039%
     - 0.0047%
     - 0.0014%
     - 0.002%
     - 0.014%
     - 0.013%
     - 0.0032%
     - 0.073%
     - 0.00031%
     - 0.013%
     - 0.0012%
     - 0.043%
     - 0.0085%
     - 0.0021%
     - 0.003%
     - 0.0076%
     - 0.15%
     - 0.0059%
     - 0.0045%
     - 0.00059%
     - 0.021%
     - 0.015%
     - 0.0053%
     - 0.0053%
     - 0.11%
     - 0.003%
     - 0.0006%
     - 0.027%
     - 0.011%
     - 0.0082%
     - 0.036%
     - 0.0028%
     - 0.0042%
     - 0.018%
     - 0.037%
     - 0.003%
     - 0.0039%
     - 0.04%
     - 0.001%
     - 0.002%
     - 0.0051%
     - 0.0035%
     - 0.0028%
     - 0.00031%
     - 0.0064%
     - 0.023%
     - 0.0039%
     - 0.016%
     - 0.006%
     - 0.004%
     - 0.0098%
     - 0.02%
     - 0.0024%
     - 0.0011%
     - 0.0054%
     - 0.0013%
     - 0.0089%
     - 0.001%
     - 0.066%
     - 0.0028%
     - 0.015%
     - 0.0037%
     - 0.00044%
     - 0.00063%
     - 0.0015%
     - 0.0024%
     - 0.55%
     - 0.042%
     - 0.00057%
     - 0.0036%
     - 0.0008%
     - 0.009%
     - 0.036%
     - 0.35%
     - 0.0065%
     - 0.0079%
     - 0.012%
     - 0.0012%
     - 0.0082%
     - 0.014%
     - 0.017%
     - 0.027%
     - 0.019%
     - 0.012%
     - 0.0035%
     - 0.012%
     - 0.058%
     - 0.013%
     - 0.002%
     - 0.042%
     - 0.0047%
     - 0.0053%
     - 0.13%
     - 0.013%
     - 0.0022%
     - 0.018%
     - 0.016%
     - 0.0022%
     - 0.0065%
     - 0.0046%
     - 0.0032%
     - 0.0022%
     - 0.013%
     - 0.029%
     - 0.0072%
     - 0.00087%
     - 0.077%
     - 0.0073%
     - 0.0034%
     - 0.0028%
     - 0.0038%
     - 0.015%
     - 0.0027%
     - 0.0044%
     - 0.0037%
     - 0.0025%
     - 0.0007%
     - 0.0022%
     - 0.28%
     - 0.0043%
     - 0.0078%
     - 0.0064%
     - 0.02%
     - 0.015%
     - 0.0097%
     - 0.12%
     - 0.0087%
     - 0.047%
     - 0.0012%
     - 0.066%
     - 0.016%
     - 0.033%
     - 0.056%
     - 0.006%
     - 0.0041%
     - 0.01%
     - 0.0053%
     - 0.083%
     - 0.024%
     - 0.0026%
     - 0.027%
     - 0.0024%
     - 0.011%
     - 0.0066%
     - 0.0061%
     - 0.0085%
     - 0.0054%
     - 0.0022%
     - 0.019%
     - 0.0089%
     - 0.012%
     - 0.0025%
     - 0.0047%
     - 0.015%
     - 0.066%
     - 0.094%
     - 0.0047%
     - 0.0058%
     - 0.0023%
     - 0.0022%
     - 0.014%
     - 0.0035%
     - 0.017%
     - 0.0056%
     - 0.0086%
     - 0.0018%
     - 0.0043%
     - 0.0066%
     - 0.31%
     - 0.0043%
     - 0.02%
     - 0.0059%
     - 0.008%
     - 0.0029%
     - 0.022%
     - 0.024%
     - 0.0085%
     - 0.0025%
     - 0.0062%
     - 0.012%
     - 0.0066%
     - 0.0068%
     - 0.006%
     - 0.0031%
     - 0.013%
     - 0.045%
     - 0.03%
     - 0.013%
     - 0.1%
     - 0.019%
     - 0.0015%
     - 0.0077%
     - 0.011%
     - 0.024%
     - 0.0026%
     - 0.0073%
     - 0.005%
     - 0.0057%
     - 0.0087%
     - 0.0016%
     - 0.091%
     - 0.013%
     - 0.0044%
     - 0.024%
     - 0.0045%
     - 0.01%
     - 0.0036%
     - 0.0053%
     - 0.0043%
     - 0.014%
     - 0.0054%
     - 0.029%
     - 0.0075%
     - 0.0059%
     - 0.058%
     - 0.072%
     - 0.0055%
     - 0.0068%
     - 0.0015%
     - 0.005%
     - 0.011%
     - 0.0087%
     - 0.0075%
     - 0.012%
     - 0.023%
     - 0.0035%
     - 0.031%
     - 0.0078%
     - 0.0069%
     - 0.0091%
     - 0.11%
     - 0.013%
     - 0.0049%
     - 0.0029%
     - 0.075%
     - 0.0029%
     - 0.035%
     - 0.03%
     - 0.0084%
     - 0.026%
     - 0.01%
     - 0.0081%
     - 0.0089%
     - 0.016%
     - 0.011%
     - 0.0056%
     - 0.035%
     - 0.035%
     - 0.0088%
     - 0.026%
     - 0.0026%
     - 0.0034%
     - 0.015%
     - 0.14%
     - 0.012%
     - 0.019%
     - 0.0074%
     - 0.0081%
     - 0.0038%
     - 0.0089%
     - 0.013%
     - 0.011%
     - 0.02%
     - 0.013%
     - 0.016%
     - 0.012%
     - 0.05%
     - 0.0038%
     - 0.016%
     - 0.0038%
     - 0.0099%
     - 0.011%
     - 0.012%
     - 0.025%
     - 0.022%
     - 0.022%
     - 0.026%
     - 0.0047%
     - 0.0073%
     - 0.054%
     - 0.027%
     - 0.027%
     - 0.13%
     - 0.0016%
     - 0.032%
     - 0.012%
     - 0.0033%
     - 0.02%
     - 0.0009%
     - 0.027%
     - 0.026%
     - 0.03%
     - 0.013%
     - 0.66%
     - 0.081%
     - 0.017%
     - 0.0074%
     - 0.025%
     - 0.0044%
     - 0.024%
     - 0.017%
     - 0.012%
     - 0.006%
     - 0.25%
     - 0.01%
     - 0.039%
     - 0.0042%
     - 0.22%
     - 0.15%
     - 0.016%
     - 0.083%
     - 0.0016%
     - 0.018%
     - 0.069%
     - 0.015%
     - 0.064%
     - 0.013%
     - 0.0072%
     - 0.018%
     - 0.0098%
     - 0.08%
     - 0.005%
     - 0.011%
     - 0.015%
     - 0.021%
     - 0.011%
     - 0.02%
     - 0.0066%
     - 0.17%
     - 0.028%
     - 0.018%
     - 0.017%
     - 0.013%
     - 0.032%
     - 0.0036%
     - 0.033%
     - 0.0068%
     - 0.016%
     - 0.012%
     - 0.0079%
     - 0.008%
     - 0.0045%
     - 0.0073%
     - 0.026%
     - 0.011%
     - 0.052%
     - 0.007%
     - 0.037%
     - 0.0054%
     - 0.0092%
     - 0.013%
     - 0.028%
     - 0.044%
     - 0.023%
     - 0.0074%
     - 0.0017%
     - 0.31%
     - 0.015%
     - 0.018%
     - 0.023%
     - 0.056%
     - 0.027%
     - 0.0027%
     - 0.012%
     - 0.018%
     - 0.023%
     - 0.0082%
     - 0.061%
     - 0.0066%
     - 0.051%
     - 0.0067%
     - 0.022%
     - 0.012%
     - 0.015%
     - 0.038%
     - 0.026%
     - 0.0079%
     - 0.0096%
     - 0.01%
     - 0.019%
     - 0.039%
     - 0.0097%
     - 0.041%
     - 0.12%
     - 0.019%
     - 0.011%
     - 0.055%
     - 0.026%
     - 0.0059%
     - 0.035%
     - 0.0082%
     - 0.0055%
     - 0.0081%
     - 0.035%
     - 0.0029%
     - 0.0034%
     - 0.0029%
     - 0.016%
     - 0.0026%
     - 0.0048%
     - 0.014%
     - 0.01%
     - 0.011%
     - 0.0061%
     - 0.024%
     - 0.0099%
     - 0.017%
     - 0.069%
     - 0.0059%
     - 0.0073%
     - 0.012%
     - 0.02%
     - 0.012%
     - 0.0097%
     - 0.0083%
     - 0.022%
     - 0.0098%
     - 0.0094%
     - 0.033%
     - 0.0057%
     - 0.0073%
     - 0.0097%
     - 0.016%
     - 0.0039%
     - 0.0025%
     - 0.0066%
     - 0.011%
     - 0.018%
     - 0.027%
     - 0.011%
     - 0.0043%
     - 0.0055%
     - 0.0057%
     - 0.0056%
     - 0.004%
     - 0.0037%
     - 0.0084%
     - 0.014%
     - 0.004%
     - 0.0061%
     - 0.0024%
     - 0.03%
     - 0.0081%
     - 0.014%
     - 0.004%
     - 0.015%
     - 0.0064%
     - 0.0049%
     - 0.0027%
     - 0.013%
     - 0.0044%
     - 0.0019%
     - 0.0034%
     - 0.031%
     - 0.0067%
     - 0.027%
     - 0.00096%
     - 0.01%
     - 0.0035%
     - 0.011%
     - 0.0044%
     - 0.014%
     - 0.0099%
     - 0.0065%
     - 0.0028%
     - 0.0026%
   * - ``location_zip_code``
     - 99661
     - 99685
     - 99501
     - 99545
     - 99633
     - 99743
     - 99576
     - 99709
     - 99827
     - 99829
     - 99802
     - 99611
     - 99901
     - 99615
     - 99604
     - 99653
     - 99645
     - 99762
     - 99723
     - 99752
     - 99833
     - 99926
     - 99835
     - 99840
     - 99731
     - 99686
     - 99903
     - 99689
     - 99740
     - 36067
     - 36535
     - 36027
     - 35042
     - 35121
     - 36089
     - 36037
     - 36201
     - 36863
     - 35960
     - 35045
     - 36904
     - 36545
     - 36251
     - 36264
     - 36330
     - 35674
     - 36401
     - 35151
     - 36420
     - 36049
     - 35055
     - 36360
     - 36701
     - 35967
     - 36092
     - 36426
     - 35901
     - 35555
     - 35653
     - 36375
     - 35462
     - 36744
     - 36310
     - 36301
     - 35768
     - 35215
     - 35586
     - 35630
     - 35650
     - 36830
     - 35611
     - 36040
     - 36083
     - 35758
     - 36732
     - 35570
     - 35976
     - 36695
     - 36460
     - 36117
     - 35601
     - 36756
     - 35466
     - 36081
     - 36274
     - 36869
     - 35242
     - 35120
     - 36925
     - 35160
     - 35010
     - 35401
     - 35504
     - 36558
     - 36726
     - 35565
     - 72160
     - 71635
     - 72653
     - 72712
     - 72601
     - 71671
     - 71744
     - 72616
     - 71653
     - 71923
     - 72454
     - 72543
     - 71665
     - 71753
     - 72110
     - 72401
     - 72956
     - 72301
     - 72396
     - 71742
     - 71639
     - 71655
     - 72034
     - 72949
     - 72554
     - 71913
     - 72150
     - 72450
     - 71801
     - 72104
     - 71852
     - 72501
     - 72556
     - 72112
     - 71603
     - 72830
     - 71860
     - 72476
     - 72360
     - 71667
     - 71822
     - 72927
     - 72023
     - 72740
     - 72687
     - 71854
     - 72315
     - 72021
     - 71957
     - 71857
     - 72641
     - 71701
     - 72126
     - 72390
     - 71943
     - 72472
     - 71953
     - 72802
     - 72040
     - 72076
     - 72455
     - 72019
     - 72958
     - 72650
     - 72903
     - 71832
     - 72529
     - 72335
     - 72560
     - 71730
     - 72031
     - 72701
     - 72143
     - 72006
     - 72834
     - 85936
     - 85635
     - 86001
     - 85541
     - 85546
     - 85534
     - 85344
     - 85281
     - 86442
     - 85901
     - 85705
     - 85122
     - 85621
     - 86314
     - 85364
     - 94501
     - 96120
     - 95642
     - 95928
     - 95252
     - 95932
     - 94565
     - 95531
     - 95762
     - 93722
     - 95963
     - 95501
     - 92243
     - 93514
     - 93306
     - 93230
     - 95422
     - 96130
     - 90250
     - 93637
     - 94901
     - 95338
     - 95482
     - 93635
     - 96101
     - 93546
     - 93906
     - 94558
     - 95945
     - 92683
     - 95747
     - 96122
     - 92503
     - 95630
     - 95023
     - 92336
     - 92101
     - 94109
     - 95206
     - 93446
     - 94080
     - 93436
     - 95035
     - 95076
     - 96003
     - 95960
     - 96097
     - 94533
     - 95403
     - 95355
     - 95991
     - 96080
     - 96091
     - 93274
     - 95370
     - 93065
     - 95616
     - 95901
     - 80229
     - 81101
     - 80013
     - 81147
     - 81073
     - 81054
     - 80501
     - 80020
     - 81201
     - 80810
     - 80439
     - 81120
     - 81133
     - 81063
     - 81252
     - 81416
     - 80211
     - 81324
     - 80134
     - 81620
     - 80918
     - 80107
     - 81212
     - 81601
     - 80422
     - 80459
     - 81230
     - 81235
     - 81089
     - 80480
     - 80127
     - 81036
     - 80807
     - 81301
     - 80461
     - 80525
     - 81082
     - 80828
     - 80751
     - 81504
     - 81130
     - 81625
     - 81321
     - 81401
     - 80701
     - 81050
     - 81432
     - 80421
     - 80734
     - 81612
     - 81052
     - 81001
     - 81648
     - 81144
     - 80487
     - 81125
     - 81433
     - 81435
     - 80737
     - 80424
     - 80863
     - 80720
     - 80634
     - 80759
     - 06902
     - 06010
     - 06790
     - 06457
     - 06516
     - 06360
     - 06066
     - 06226
     - 20002
     - 19904
     - 19720
     - 19966
     - 32608
     - 32063
     - 32404
     - 32091
     - 32940
     - 33027
     - 32424
     - 33950
     - 34446
     - 32068
     - 34112
     - 32025
     - 34266
     - 32680
     - 32256
     - 32507
     - 32137
     - 32328
     - 32351
     - 32693
     - 33471
     - 32456
     - 32052
     - 33873
     - 33440
     - 34609
     - 33870
     - 33647
     - 32425
     - 32958
     - 32446
     - 32344
     - 32066
     - 34711
     - 34135
     - 32303
     - 32696
     - 32321
     - 32340
     - 34221
     - 34491
     - 34997
     - 33160
     - 33040
     - 32034
     - 32541
     - 34974
     - 34787
     - 34746
     - 33411
     - 34668
     - 34698
     - 33810
     - 32177
     - 32566
     - 34293
     - 32771
     - 32259
     - 34953
     - 32162
     - 32060
     - 32348
     - 32054
     - 32174
     - 32327
     - 32459
     - 32428
     - 31513
     - 31642
     - 31510
     - 39870
     - 31061
     - 30547
     - 30680
     - 30120
     - 31750
     - 31639
     - 31204
     - 31014
     - 31553
     - 31643
     - 31324
     - 30458
     - 30830
     - 30233
     - 39846
     - 31558
     - 30439
     - 30117
     - 30736
     - 31537
     - 31419
     - 31905
     - 30747
     - 30188
     - 30606
     - 39851
     - 30236
     - 31634
     - 30080
     - 31533
     - 31768
     - 30809
     - 31620
     - 30263
     - 31078
     - 31015
     - 30752
     - 30534
     - 39819
     - 30058
     - 31023
     - 31092
     - 31705
     - 30135
     - 39823
     - 31636
     - 31326
     - 30635
     - 30401
     - 30417
     - 30513
     - 30269
     - 30165
     - 30040
     - 30553
     - 30318
     - 30540
     - 30810
     - 31525
     - 30701
     - 39828
     - 30642
     - 30044
     - 30531
     - 30542
     - 31087
     - 30110
     - 31804
     - 30643
     - 30217
     - 30253
     - 31088
     - 31774
     - 30549
     - 31064
     - 31539
     - 30434
     - 30442
     - 31096
     - 31032
     - 30204
     - 31635
     - 31021
     - 31763
     - 31313
     - 30817
     - 31316
     - 31601
     - 30533
     - 31063
     - 30633
     - 31803
     - 30824
     - 31331
     - 31816
     - 39837
     - 31730
     - 31029
     - 30445
     - 30650
     - 30705
     - 31907
     - 30016
     - 30677
     - 30683
     - 30132
     - 31030
     - 30143
     - 31516
     - 30292
     - 30125
     - 31036
     - 31024
     - 39854
     - 30525
     - 39840
     - 30909
     - 30094
     - 31806
     - 30467
     - 39845
     - 30223
     - 30577
     - 31825
     - 31709
     - 31827
     - 30631
     - 30427
     - 31006
     - 31055
     - 39842
     - 31792
     - 31794
     - 30474
     - 30546
     - 30457
     - 30241
     - 31714
     - 31044
     - 30512
     - 30286
     - 30741
     - 30052
     - 31503
     - 30828
     - 31082
     - 31545
     - 31824
     - 30428
     - 30528
     - 30721
     - 31001
     - 30673
     - 31031
     - 31791
     - 96721
     - 96813
     - 96742
     - 96746
     - 96793
     - 50849
     - 50841
     - 52172
     - 52544
     - 50025
     - 52349
     - 50613
     - 50036
     - 50677
     - 50644
     - 50588
     - 50665
     - 50563
     - 51401
     - 50022
     - 52772
     - 50401
     - 51012
     - 50659
     - 50213
     - 51301
     - 52052
     - 52732
     - 51442
     - 50263
     - 52537
     - 50144
     - 52057
     - 52601
     - 51360
     - 52001
     - 51334
     - 50662
     - 50616
     - 50441
     - 51652
     - 50129
     - 50638
     - 50216
     - 50595
     - 50438
     - 50126
     - 51555
     - 52641
     - 52136
     - 50548
     - 51445
     - 52361
     - 52060
     - 50208
     - 52556
     - 52240
     - 52205
     - 52591
     - 50511
     - 52627
     - 52404
     - 52653
     - 50049
     - 51246
     - 50273
     - 52577
     - 50219
     - 50158
     - 51534
     - 50461
     - 51040
     - 52531
     - 51566
     - 52761
     - 51201
     - 51249
     - 51632
     - 50536
     - 51031
     - 50574
     - 50023
     - 51503
     - 50112
     - 50854
     - 50583
     - 52722
     - 51537
     - 51250
     - 50010
     - 52339
     - 50833
     - 50801
     - 52565
     - 52501
     - 50125
     - 52353
     - 50060
     - 50501
     - 50436
     - 52101
     - 51106
     - 50459
     - 50533
     - 83646
     - 83612
     - 83201
     - 83254
     - 83861
     - 83221
     - 83333
     - 83716
     - 83864
     - 83401
     - 83805
     - 83213
     - 83327
     - 83686
     - 83276
     - 83318
     - 83423
     - 83544
     - 83226
     - 83647
     - 83263
     - 83445
     - 83617
     - 83330
     - 83530
     - 83442
     - 83338
     - 83854
     - 83843
     - 83467
     - 83536
     - 83352
     - 83440
     - 83350
     - 83501
     - 83252
     - 83628
     - 83661
     - 83211
     - 83837
     - 83455
     - 83301
     - 83638
     - 83672
     - 62301
     - 62914
     - 62246
     - 61008
     - 62353
     - 61356
     - 62047
     - 61074
     - 62618
     - 61820
     - 62568
     - 62441
     - 62839
     - 62231
     - 61938
     - 60657
     - 62454
     - 62428
     - 61727
     - 60115
     - 61953
     - 60148
     - 61944
     - 62806
     - 62401
     - 62471
     - 60957
     - 62896
     - 61520
     - 62984
     - 62016
     - 60450
     - 62859
     - 62321
     - 62931
     - 61469
     - 61443
     - 60970
     - 62901
     - 62448
     - 62864
     - 62052
     - 61036
     - 62995
     - 60506
     - 60901
     - 60543
     - 61401
     - 60085
     - 61350
     - 62439
     - 61021
     - 61764
     - 62656
     - 62521
     - 62626
     - 62040
     - 62801
     - 61540
     - 62644
     - 62960
     - 61455
     - 60014
     - 61761
     - 62675
     - 61231
     - 62298
     - 62056
     - 62650
     - 61951
     - 61068
     - 61604
     - 62832
     - 61856
     - 62363
     - 62938
     - 62964
     - 61326
     - 62286
     - 62450
     - 61265
     - 62946
     - 62704
     - 62681
     - 62694
     - 62565
     - 62269
     - 61491
     - 61032
     - 61554
     - 62906
     - 61832
     - 62863
     - 61462
     - 62263
     - 62837
     - 62821
     - 61081
     - 60435
     - 62959
     - 61107
     - 61548
     - 46733
     - 46835
     - 47201
     - 47944
     - 47348
     - 46077
     - 47448
     - 46923
     - 46947
     - 47130
     - 47834
     - 46041
     - 47118
     - 47501
     - 47025
     - 47240
     - 46706
     - 47304
     - 47546
     - 46514
     - 47331
     - 47150
     - 47918
     - 47012
     - 46975
     - 47670
     - 46953
     - 47441
     - 46032
     - 46140
     - 47112
     - 46112
     - 47362
     - 46901
     - 46750
     - 47274
     - 47978
     - 47371
     - 47250
     - 47265
     - 46143
     - 47591
     - 46580
     - 46761
     - 46307
     - 46360
     - 47421
     - 46016
     - 46227
     - 46563
     - 47581
     - 46970
     - 47401
     - 47933
     - 46151
     - 46349
     - 46755
     - 47040
     - 47454
     - 47460
     - 47872
     - 47586
     - 47567
     - 46383
     - 47620
     - 46996
     - 46135
     - 47394
     - 47006
     - 46173
     - 47170
     - 46176
     - 47635
     - 46544
     - 46534
     - 46703
     - 47882
     - 47043
     - 47906
     - 46072
     - 47353
     - 47714
     - 47842
     - 47802
     - 46992
     - 47993
     - 47630
     - 47167
     - 47374
     - 46714
     - 47960
     - 46725
     - 66749
     - 66032
     - 66002
     - 67104
     - 67530
     - 66701
     - 66434
     - 67042
     - 66845
     - 67361
     - 66713
     - 67756
     - 67865
     - 67432
     - 66901
     - 66839
     - 67029
     - 67005
     - 66762
     - 67749
     - 67410
     - 66090
     - 66049
     - 67547
     - 67349
     - 67601
     - 67439
     - 67846
     - 67801
     - 66067
     - 66441
     - 67752
     - 67642
     - 67880
     - 67867
     - 67879
     - 67045
     - 67878
     - 67003
     - 67114
     - 67877
     - 67854
     - 66436
     - 66512
     - 66956
     - 66062
     - 67860
     - 67068
     - 67054
     - 67357
     - 67839
     - 66048
     - 67455
     - 66040
     - 67748
     - 66801
     - 67063
     - 66508
     - 67460
     - 67864
     - 66071
     - 67420
     - 67301
     - 66846
     - 67950
     - 66538
     - 66720
     - 67560
     - 67654
     - 66523
     - 67473
     - 67467
     - 67550
     - 67661
     - 66547
     - 67124
     - 67730
     - 67501
     - 66935
     - 67554
     - 66502
     - 67663
     - 67548
     - 67665
     - 67401
     - 67871
     - 67212
     - 67901
     - 66614
     - 67740
     - 67735
     - 66967
     - 67576
     - 67855
     - 67951
     - 67152
     - 67701
     - 67672
     - 66401
     - 67758
     - 66968
     - 67861
     - 66736
     - 66783
     - 66102
     - 42728
     - 42164
     - 40342
     - 42053
     - 42141
     - 40360
     - 40965
     - 41042
     - 40361
     - 41102
     - 40422
     - 41004
     - 41339
     - 40143
     - 40165
     - 42261
     - 42445
     - 42071
     - 41071
     - 42023
     - 41008
     - 41143
     - 42539
     - 42240
     - 40391
     - 40962
     - 42602
     - 42064
     - 42717
     - 42301
     - 42210
     - 41171
     - 40336
     - 40509
     - 41041
     - 41653
     - 40601
     - 42041
     - 41095
     - 40444
     - 41035
     - 42066
     - 42754
     - 42743
     - 41144
     - 42348
     - 42701
     - 40831
     - 41031
     - 42765
     - 42420
     - 40019
     - 42031
     - 42431
     - 40447
     - 40214
     - 40356
     - 41240
     - 41017
     - 41822
     - 40906
     - 42748
     - 40741
     - 41230
     - 41311
     - 41749
     - 41858
     - 41179
     - 40484
     - 42045
     - 42276
     - 42038
     - 40475
     - 41465
     - 40033
     - 42025
     - 41224
     - 41056
     - 42001
     - 42653
     - 42327
     - 40108
     - 40322
     - 40330
     - 42129
     - 42167
     - 40353
     - 41472
     - 42345
     - 40004
     - 40311
     - 42320
     - 40014
     - 40359
     - 41314
     - 41040
     - 41701
     - 41501
     - 40380
     - 42503
     - 41064
     - 40456
     - 40351
     - 42642
     - 40324
     - 40065
     - 42134
     - 40071
     - 42718
     - 42220
     - 42211
     - 40006
     - 42437
     - 42101
     - 40069
     - 42633
     - 42450
     - 40769
     - 41301
     - 40383
     - 70526
     - 71463
     - 70737
     - 70339
     - 71351
     - 70634
     - 71001
     - 71111
     - 71106
     - 70605
     - 71418
     - 70607
     - 71343
     - 71040
     - 71334
     - 71052
     - 70816
     - 71254
     - 70722
     - 70586
     - 71295
     - 71467
     - 70560
     - 70764
     - 71251
     - 70546
     - 70072
     - 71342
     - 70506
     - 70301
     - 71270
     - 70726
     - 71282
     - 71220
     - 71457
     - 70119
     - 71203
     - 70037
     - 70760
     - 71360
     - 71019
     - 71269
     - 71449
     - 70043
     - 70070
     - 70441
     - 70090
     - 70068
     - 70570
     - 70517
     - 70380
     - 70433
     - 70454
     - 71366
     - 70360
     - 71241
     - 70510
     - 71446
     - 70427
     - 71055
     - 70767
     - 71263
     - 70775
     - 71483
     - 02536
     - 01201
     - 02780
     - 02568
     - 01960
     - 01301
     - 01085
     - 01002
     - 02148
     - 02554
     - 02169
     - 02360
     - 02151
     - 01453
     - 21502
     - 21122
     - 21215
     - 21117
     - 20657
     - 21629
     - 21157
     - 21921
     - 20603
     - 21613
     - 21702
     - 21550
     - 21014
     - 21044
     - 21620
     - 20906
     - 20774
     - 21666
     - 21853
     - 20653
     - 21601
     - 21740
     - 21804
     - 21842
     - 04240
     - 04769
     - 04103
     - 04938
     - 04605
     - 04901
     - 04841
     - 04572
     - 04276
     - 04401
     - 04426
     - 04530
     - 04976
     - 04915
     - 04654
     - 04005
     - 48740
     - 49862
     - 49010
     - 49707
     - 49615
     - 48658
     - 49946
     - 49058
     - 48706
     - 49635
     - 49022
     - 49036
     - 49015
     - 49047
     - 49720
     - 49721
     - 49783
     - 48625
     - 48820
     - 49738
     - 49829
     - 49801
     - 48917
     - 49770
     - 48439
     - 48624
     - 49938
     - 49686
     - 48801
     - 49242
     - 49931
     - 48413
     - 48823
     - 48846
     - 48750
     - 49935
     - 48858
     - 49201
     - 49009
     - 49646
     - 49503
     - 49950
     - 49304
     - 48446
     - 49684
     - 49221
     - 48843
     - 49868
     - 49781
     - 48038
     - 49660
     - 49855
     - 49431
     - 49307
     - 49858
     - 48642
     - 49651
     - 48162
     - 48838
     - 49709
     - 49442
     - 49337
     - 48307
     - 49420
     - 48661
     - 49953
     - 49631
     - 48647
     - 49735
     - 49424
     - 49779
     - 48629
     - 48601
     - 48450
     - 49854
     - 48867
     - 48060
     - 49091
     - 48723
     - 49090
     - 48197
     - 48180
     - 49601
     - 56431
     - 55303
     - 56501
     - 56601
     - 56379
     - 56278
     - 56001
     - 56073
     - 55720
     - 55318
     - 56474
     - 56265
     - 55056
     - 56560
     - 56621
     - 55604
     - 56101
     - 56401
     - 55124
     - 55944
     - 56308
     - 56013
     - 55975
     - 56007
     - 55066
     - 56531
     - 55408
     - 55947
     - 56470
     - 55008
     - 55744
     - 56143
     - 55051
     - 56201
     - 56728
     - 56649
     - 56256
     - 55616
     - 56623
     - 56058
     - 56178
     - 56258
     - 56557
     - 56762
     - 56031
     - 55350
     - 55355
     - 56353
     - 56345
     - 55912
     - 56172
     - 56003
     - 56187
     - 56510
     - 55901
     - 56537
     - 56701
     - 55063
     - 56164
     - 56721
     - 56334
     - 55106
     - 56750
     - 56283
     - 56277
     - 55021
     - 56156
     - 56751
     - 55379
     - 55330
     - 55334
     - 55811
     - 56301
     - 55060
     - 56267
     - 56215
     - 56347
     - 56296
     - 55041
     - 56482
     - 56093
     - 55125
     - 56081
     - 56520
     - 55987
     - 55313
     - 56220
     - 63501
     - 64485
     - 64491
     - 65265
     - 65625
     - 64759
     - 64730
     - 65355
     - 63764
     - 65203
     - 64506
     - 63901
     - 64644
     - 65251
     - 65020
     - 63701
     - 64633
     - 63965
     - 64012
     - 64744
     - 65281
     - 65714
     - 63445
     - 64118
     - 64429
     - 65109
     - 65233
     - 65453
     - 65661
     - 65622
     - 64640
     - 64429
     - 65560
     - 65608
     - 63857
     - 63090
     - 65066
     - 64402
     - 65807
     - 64683
     - 64424
     - 64735
     - 65779
     - 64470
     - 65248
     - 65775
     - 63650
     - 64055
     - 64801
     - 63010
     - 64093
     - 63537
     - 65536
     - 64076
     - 65605
     - 63435
     - 63379
     - 64628
     - 64601
     - 63552
     - 63645
     - 65582
     - 63401
     - 64831
     - 64673
     - 65026
     - 63845
     - 65018
     - 65275
     - 63361
     - 65037
     - 63873
     - 64850
     - 64468
     - 65606
     - 65051
     - 65655
     - 63830
     - 63775
     - 65301
     - 65401
     - 63334
     - 64151
     - 65613
     - 65473
     - 63565
     - 63459
     - 65270
     - 64085
     - 63638
     - 63935
     - 65340
     - 63548
     - 63555
     - 63801
     - 65588
     - 63468
     - 63376
     - 64776
     - 63640
     - 63116
     - 63021
     - 63670
     - 63841
     - 65737
     - 63556
     - 65616
     - 65483
     - 64772
     - 63383
     - 63664
     - 63957
     - 65706
     - 64456
     - 65711
     - 39120
     - 38834
     - 39645
     - 39090
     - 38603
     - 38732
     - 38916
     - 38917
     - 38851
     - 39735
     - 39150
     - 39355
     - 39773
     - 38614
     - 39059
     - 39428
     - 38654
     - 39401
     - 39653
     - 39452
     - 39451
     - 38901
     - 39520
     - 39503
     - 39209
     - 39095
     - 39038
     - 39159
     - 38843
     - 39564
     - 39422
     - 39069
     - 39474
     - 39443
     - 39328
     - 38655
     - 39402
     - 39301
     - 39654
     - 39051
     - 38801
     - 38930
     - 39601
     - 39702
     - 39110
     - 39429
     - 38611
     - 38821
     - 38967
     - 39350
     - 39345
     - 39341
     - 39759
     - 38606
     - 39466
     - 39476
     - 39648
     - 38863
     - 38829
     - 38646
     - 39047
     - 39074
     - 39159
     - 39111
     - 39168
     - 39577
     - 38751
     - 38921
     - 38668
     - 38663
     - 38852
     - 38676
     - 38652
     - 39667
     - 39180
     - 38701
     - 39367
     - 39744
     - 39669
     - 39339
     - 38965
     - 39194
     - 59725
     - 59034
     - 59526
     - 59644
     - 59068
     - 59324
     - 59405
     - 59442
     - 59301
     - 59263
     - 59330
     - 59711
     - 59313
     - 59457
     - 59901
     - 59718
     - 59337
     - 59427
     - 59074
     - 59858
     - 59501
     - 59634
     - 59479
     - 59860
     - 59601
     - 59522
     - 59923
     - 59729
     - 59215
     - 59645
     - 59872
     - 59801
     - 59072
     - 59047
     - 59087
     - 59538
     - 59425
     - 59317
     - 59722
     - 59349
     - 59840
     - 59270
     - 59201
     - 59327
     - 59859
     - 59254
     - 59701
     - 59019
     - 59011
     - 59422
     - 59474
     - 59038
     - 59230
     - 59036
     - 59353
     - 59102
     - 27215
     - 28681
     - 28675
     - 28170
     - 28694
     - 28657
     - 27889
     - 27983
     - 28337
     - 28451
     - 28806
     - 28655
     - 28027
     - 28645
     - 27921
     - 28570
     - 27379
     - 28601
     - 27312
     - 28906
     - 27932
     - 28904
     - 28150
     - 28472
     - 28562
     - 28314
     - 27958
     - 27949
     - 27360
     - 27028
     - 28466
     - 27703
     - 27801
     - 27284
     - 27549
     - 28054
     - 27937
     - 28771
     - 27565
     - 28580
     - 27406
     - 27870
     - 27546
     - 28786
     - 28792
     - 27910
     - 28376
     - 27824
     - 28117
     - 28779
     - 27520
     - 28585
     - 27330
     - 28501
     - 28092
     - 28734
     - 28753
     - 27892
     - 28752
     - 28269
     - 28777
     - 27371
     - 28374
     - 27804
     - 28412
     - 27831
     - 28540
     - 27514
     - 28571
     - 27909
     - 28443
     - 27944
     - 27574
     - 27858
     - 28782
     - 27205
     - 28379
     - 28358
     - 27320
     - 28146
     - 28043
     - 28328
     - 28352
     - 28001
     - 27021
     - 27030
     - 28713
     - 28712
     - 27925
     - 28173
     - 27537
     - 27610
     - 27589
     - 27962
     - 28607
     - 27530
     - 28659
     - 27893
     - 27055
     - 28714
     - 58639
     - 58072
     - 58348
     - 58622
     - 58318
     - 58623
     - 58773
     - 58503
     - 58103
     - 58249
     - 58474
     - 58730
     - 58640
     - 58356
     - 58552
     - 58421
     - 58621
     - 58201
     - 58533
     - 58425
     - 58646
     - 58482
     - 58458
     - 58561
     - 58790
     - 58495
     - 58854
     - 58540
     - 58545
     - 58554
     - 58763
     - 58344
     - 58530
     - 58220
     - 58368
     - 58301
     - 58054
     - 58761
     - 58075
     - 58367
     - 58060
     - 58463
     - 58538
     - 58620
     - 58601
     - 58230
     - 58401
     - 58324
     - 58257
     - 58237
     - 58701
     - 58341
     - 58801
     - 68901
     - 68756
     - 69121
     - 69345
     - 68833
     - 68620
     - 69301
     - 68777
     - 69210
     - 68845
     - 68061
     - 68632
     - 68048
     - 68739
     - 69033
     - 69201
     - 69162
     - 68979
     - 68661
     - 68788
     - 68822
     - 68776
     - 69337
     - 68850
     - 69129
     - 68770
     - 68025
     - 68022
     - 69021
     - 68361
     - 68939
     - 69025
     - 69022
     - 68310
     - 69154
     - 68823
     - 68937
     - 69350
     - 68665
     - 68801
     - 68818
     - 68920
     - 69032
     - 69024
     - 68763
     - 69152
     - 68873
     - 68352
     - 68450
     - 68959
     - 69153
     - 68778
     - 69145
     - 68718
     - 68516
     - 69101
     - 69163
     - 68823
     - 68701
     - 69167
     - 68826
     - 69336
     - 68638
     - 68305
     - 68978
     - 68410
     - 68420
     - 69140
     - 68949
     - 68767
     - 68601
     - 68666
     - 69001
     - 68355
     - 68714
     - 68333
     - 68046
     - 68066
     - 69361
     - 68434
     - 69343
     - 68853
     - 69346
     - 68779
     - 68370
     - 69166
     - 68071
     - 68862
     - 68008
     - 68787
     - 68970
     - 68637
     - 68467
     - 03246
     - 03894
     - 03431
     - 03570
     - 03766
     - 03103
     - 03301
     - 03038
     - 03820
     - 03743
     - 08401
     - 07410
     - 08054
     - 08021
     - 08260
     - 08332
     - 07111
     - 08096
     - 07302
     - 08822
     - 08618
     - 08831
     - 07728
     - 07960
     - 08701
     - 07055
     - 08069
     - 08873
     - 07860
     - 07083
     - 08865
     - 87111
     - 87829
     - 88203
     - 87020
     - 87740
     - 88101
     - 88119
     - 88001
     - 88220
     - 88061
     - 88435
     - 87743
     - 88045
     - 88240
     - 88355
     - 87544
     - 88030
     - 87301
     - 87722
     - 88310
     - 88401
     - 87532
     - 88130
     - 87401
     - 87701
     - 87124
     - 87507
     - 87901
     - 87801
     - 87571
     - 87035
     - 88415
     - 87031
     - 89701
     - 89406
     - 89052
     - 89460
     - 89801
     - 89010
     - 89316
     - 89445
     - 89820
     - 89017
     - 89408
     - 89415
     - 89048
     - 89419
     - 89521
     - 89502
     - 89301
     - 12203
     - 14895
     - 10467
     - 13760
     - 14760
     - 13021
     - 14701
     - 14845
     - 13815
     - 12901
     - 12534
     - 13045
     - 13856
     - 12601
     - 14221
     - 12946
     - 12953
     - 12078
     - 14020
     - 12414
     - 12842
     - 13357
     - 13601
     - 11226
     - 13367
     - 14454
     - 13032
     - 14580
     - 12010
     - 11758
     - 10025
     - 14094
     - 13440
     - 13027
     - 14424
     - 12550
     - 14411
     - 13126
     - 13820
     - 10512
     - 11375
     - 12180
     - 10314
     - 10977
     - 12866
     - 12306
     - 12043
     - 14891
     - 13148
     - 13676
     - 14830
     - 11746
     - 12701
     - 13827
     - 14850
     - 12401
     - 12804
     - 12839
     - 14513
     - 10701
     - 14569
     - 14527
     - 45693
     - 45805
     - 44805
     - 44004
     - 45701
     - 45895
     - 43950
     - 45121
     - 45011
     - 44615
     - 43078
     - 45503
     - 45103
     - 45177
     - 43920
     - 43812
     - 44820
     - 44107
     - 45331
     - 43512
     - 43015
     - 44870
     - 43130
     - 43160
     - 43081
     - 43567
     - 45631
     - 44024
     - 45324
     - 43725
     - 45238
     - 45840
     - 43326
     - 43907
     - 43545
     - 45133
     - 43138
     - 44654
     - 44857
     - 45640
     - 43952
     - 43050
     - 44060
     - 45638
     - 43055
     - 43311
     - 44035
     - 43615
     - 43140
     - 44512
     - 43302
     - 44256
     - 45769
     - 45822
     - 45373
     - 43793
     - 45424
     - 43756
     - 43338
     - 43701
     - 43724
     - 43452
     - 45879
     - 43764
     - 43113
     - 45690
     - 44240
     - 45320
     - 45875
     - 44903
     - 45601
     - 43420
     - 45662
     - 44883
     - 45365
     - 44646
     - 44224
     - 44483
     - 44663
     - 43040
     - 45891
     - 45651
     - 45040
     - 45750
     - 44691
     - 43506
     - 43551
     - 43351
     - 74960
     - 73728
     - 74525
     - 73932
     - 73644
     - 73772
     - 74701
     - 73005
     - 73099
     - 73401
     - 74464
     - 74743
     - 73933
     - 73160
     - 74538
     - 73505
     - 73572
     - 74301
     - 74066
     - 73096
     - 74344
     - 73859
     - 73858
     - 73703
     - 73075
     - 73018
     - 73759
     - 73554
     - 73550
     - 73848
     - 74462
     - 74848
     - 73521
     - 73573
     - 73460
     - 74601
     - 73750
     - 73651
     - 74578
     - 74953
     - 74834
     - 73044
     - 73448
     - 73737
     - 73439
     - 74361
     - 73080
     - 74728
     - 74432
     - 73086
     - 74403
     - 73077
     - 74048
     - 74859
     - 73013
     - 74447
     - 74070
     - 74354
     - 74020
     - 74074
     - 74501
     - 74820
     - 74801
     - 74523
     - 73628
     - 74017
     - 74868
     - 74955
     - 73533
     - 73942
     - 73542
     - 74012
     - 74014
     - 74006
     - 73632
     - 73717
     - 73801
     - 97814
     - 97330
     - 97045
     - 97103
     - 97051
     - 97420
     - 97754
     - 97415
     - 97702
     - 97471
     - 97823
     - 97845
     - 97720
     - 97031
     - 97504
     - 97741
     - 97526
     - 97603
     - 97630
     - 97402
     - 97367
     - 97322
     - 97914
     - 97301
     - 97818
     - 97206
     - 97304
     - 97065
     - 97141
     - 97838
     - 97850
     - 97828
     - 97058
     - 97229
     - 97830
     - 97128
     - 17325
     - 15237
     - 16201
     - 15001
     - 15522
     - 19606
     - 16601
     - 18840
     - 19020
     - 16001
     - 15905
     - 15834
     - 18235
     - 16801
     - 19380
     - 16214
     - 15801
     - 17745
     - 17815
     - 16335
     - 17055
     - 17112
     - 19063
     - 15857
     - 16509
     - 15401
     - 16353
     - 17268
     - 17233
     - 15370
     - 16652
     - 15701
     - 15767
     - 17059
     - 18505
     - 17603
     - 16101
     - 17042
     - 18103
     - 18702
     - 17701
     - 16701
     - 16148
     - 17044
     - 18301
     - 19446
     - 17821
     - 18042
     - 17801
     - 17020
     - 19143
     - 18337
     - 16915
     - 17901
     - 17870
     - 15501
     - 18614
     - 18801
     - 16901
     - 17837
     - 16301
     - 16365
     - 15301
     - 18431
     - 15601
     - 18657
     - 17331
     - 02809
     - 02893
     - 02840
     - 02860
     - 02891
     - 29620
     - 29803
     - 29810
     - 29621
     - 29003
     - 29812
     - 29910
     - 29445
     - 29135
     - 29464
     - 29340
     - 29706
     - 29520
     - 29102
     - 29488
     - 29550
     - 29536
     - 29485
     - 29860
     - 29180
     - 29501
     - 29440
     - 29681
     - 29649
     - 29918
     - 29579
     - 29936
     - 29020
     - 29720
     - 29360
     - 29010
     - 29072
     - 29571
     - 29512
     - 29835
     - 29108
     - 29678
     - 29115
     - 29640
     - 29223
     - 29138
     - 29301
     - 29150
     - 29379
     - 29556
     - 29732
     - 57368
     - 57350
     - 57551
     - 57066
     - 57006
     - 57401
     - 57325
     - 57341
     - 57717
     - 57632
     - 57380
     - 57225
     - 57069
     - 57201
     - 57642
     - 57730
     - 57301
     - 57274
     - 57226
     - 57625
     - 57328
     - 57451
     - 57747
     - 57438
     - 57252
     - 57533
     - 57552
     - 57223
     - 57362
     - 57311
     - 57720
     - 57501
     - 57366
     - 57345
     - 57543
     - 57382
     - 57559
     - 57231
     - 57042
     - 57783
     - 57108
     - 57569
     - 57430
     - 57058
     - 57437
     - 57785
     - 57579
     - 57349
     - 57106
     - 57028
     - 57770
     - 57701
     - 57638
     - 57442
     - 57262
     - 57385
     - 57469
     - 57532
     - 57564
     - 57555
     - 57580
     - 57053
     - 57049
     - 57601
     - 57078
     - 57623
     - 37830
     - 37160
     - 38320
     - 37367
     - 37803
     - 37312
     - 37766
     - 37190
     - 38344
     - 37643
     - 37015
     - 38340
     - 37879
     - 38551
     - 37821
     - 37355
     - 38006
     - 38555
     - 37013
     - 38363
     - 37166
     - 37055
     - 38024
     - 38060
     - 38556
     - 37398
     - 38343
     - 38478
     - 37861
     - 37743
     - 37387
     - 37814
     - 37421
     - 37869
     - 38008
     - 38372
     - 37857
     - 38012
     - 38351
     - 38242
     - 37033
     - 37061
     - 37185
     - 38562
     - 37725
     - 37683
     - 37920
     - 38079
     - 38063
     - 38464
     - 38462
     - 37334
     - 37774
     - 37083
     - 38305
     - 37397
     - 37091
     - 38401
     - 37303
     - 38375
     - 37322
     - 37354
     - 37042
     - 37352
     - 37887
     - 38261
     - 38570
     - 37096
     - 38549
     - 37307
     - 38501
     - 37321
     - 37748
     - 37172
     - 37128
     - 37841
     - 37327
     - 37876
     - 38111
     - 37030
     - 37058
     - 37660
     - 37075
     - 38019
     - 37074
     - 37650
     - 37807
     - 38585
     - 37110
     - 37604
     - 38485
     - 38237
     - 38583
     - 37064
     - 37122
     - 75803
     - 79714
     - 75904
     - 78382
     - 76310
     - 79019
     - 78064
     - 77474
     - 79347
     - 78003
     - 78602
     - 76380
     - 78102
     - 76502
     - 78245
     - 78606
     - 79351
     - 76634
     - 75501
     - 77584
     - 77845
     - 79830
     - 79257
     - 78355
     - 76801
     - 77836
     - 78654
     - 78644
     - 77979
     - 79510
     - 78521
     - 75686
     - 79068
     - 75551
     - 79027
     - 77523
     - 75766
     - 79201
     - 76365
     - 79346
     - 76945
     - 76834
     - 75035
     - 79095
     - 78934
     - 78130
     - 76442
     - 76837
     - 76240
     - 76522
     - 79248
     - 79731
     - 76943
     - 79322
     - 79847
     - 79022
     - 75243
     - 79331
     - 79045
     - 75432
     - 75056
     - 77954
     - 79370
     - 78834
     - 79226
     - 78384
     - 76437
     - 79762
     - 78880
     - 79936
     - 75165
     - 76401
     - 76661
     - 75418
     - 78945
     - 79546
     - 79235
     - 79227
     - 77494
     - 75457
     - 75860
     - 78061
     - 79360
     - 77573
     - 79356
     - 78624
     - 79739
     - 77963
     - 78629
     - 79065
     - 75092
     - 75605
     - 77868
     - 78155
     - 79072
     - 79245
     - 76531
     - 79081
     - 79252
     - 77657
     - 77449
     - 75672
     - 79022
     - 79521
     - 78666
     - 79014
     - 75156
     - 78572
     - 76692
     - 79336
     - 76048
     - 75482
     - 75835
     - 79720
     - 79839
     - 75401
     - 79007
     - 76941
     - 76458
     - 77957
     - 75951
     - 79734
     - 77642
     - 78361
     - 78332
     - 76028
     - 79501
     - 78119
     - 75126
     - 78006
     - 78385
     - 79549
     - 78028
     - 76849
     - 79248
     - 78832
     - 78363
     - 76371
     - 78014
     - 75460
     - 79339
     - 76550
     - 77964
     - 78942
     - 75831
     - 77327
     - 76667
     - 79005
     - 78022
     - 78657
     - 79754
     - 79424
     - 79373
     - 77864
     - 75657
     - 79782
     - 76856
     - 77414
     - 78852
     - 76825
     - 76706
     - 78072
     - 78861
     - 76859
     - 79705
     - 76567
     - 76844
     - 79512
     - 76230
     - 77386
     - 79029
     - 75638
     - 79234
     - 75964
     - 75110
     - 75966
     - 79556
     - 78414
     - 79070
     - 79092
     - 77630
     - 76067
     - 75633
     - 76087
     - 79035
     - 79735
     - 77351
     - 79107
     - 79845
     - 75440
     - 79109
     - 76932
     - 78873
     - 75426
     - 79772
     - 78377
     - 79059
     - 77859
     - 75087
     - 76821
     - 75652
     - 75948
     - 75972
     - 77331
     - 78374
     - 76877
     - 76936
     - 79549
     - 76430
     - 75935
     - 79084
     - 75703
     - 76043
     - 78582
     - 76424
     - 76951
     - 79502
     - 76950
     - 79088
     - 76244
     - 79605
     - 78851
     - 79316
     - 76483
     - 75455
     - 76904
     - 78660
     - 75862
     - 75979
     - 75644
     - 79778
     - 78801
     - 78840
     - 75103
     - 77901
     - 77340
     - 77423
     - 79756
     - 77833
     - 78045
     - 77437
     - 79079
     - 76311
     - 76384
     - 78580
     - 78641
     - 78114
     - 79745
     - 76234
     - 75773
     - 79323
     - 76450
     - 78076
     - 78839
     - 84713
     - 84302
     - 84321
     - 84501
     - 84046
     - 84015
     - 84066
     - 84528
     - 84726
     - 84532
     - 84721
     - 84648
     - 84741
     - 84624
     - 84050
     - 84750
     - 84028
     - 84096
     - 84511
     - 84627
     - 84701
     - 84098
     - 84074
     - 84078
     - 84043
     - 84032
     - 84770
     - 84775
     - 84404
     - 23336
     - 22901
     - 22304
     - 24426
     - 23002
     - 24572
     - 24522
     - 22204
     - 24401
     - 24460
     - 24551
     - 24315
     - 24175
     - 24201
     - 23868
     - 24614
     - 23936
     - 24416
     - 24502
     - 22546
     - 24343
     - 23030
     - 23923
     - 22903
     - 23320
     - 23112
     - 22611
     - 23834
     - 24426
     - 24127
     - 22701
     - 23040
     - 24541
     - 24228
     - 23803
     - 23847
     - 22560
     - 22030
     - 20171
     - 22046
     - 20187
     - 24091
     - 22963
     - 23851
     - 24151
     - 22602
     - 22401
     - 24333
     - 24134
     - 23061
     - 23103
     - 24333
     - 22968
     - 23847
     - 24592
     - 23666
     - 23111
     - 22801
     - 23228
     - 24112
     - 24465
     - 23860
     - 23430
     - 23188
     - 23156
     - 22485
     - 23009
     - 22503
     - 24263
     - 24450
     - 20189
     - 23093
     - 23974
     - 24502
     - 22727
     - 20110
     - 20111
     - 24112
     - 23109
     - 23970
     - 23043
     - 24060
     - 22967
     - 23141
     - 23608
     - 23503
     - 23310
     - 22473
     - 24273
     - 23824
     - 22508
     - 22835
     - 24171
     - 23803
     - 24540
     - 23662
     - 23703
     - 23139
     - 23901
     - 23875
     - 22191
     - 24301
     - 24141
     - 20106
     - 23220
     - 22572
     - 24017
     - 24018
     - 24450
     - 22801
     - 24266
     - 24153
     - 24251
     - 22657
     - 24354
     - 23851
     - 22407
     - 22554
     - 24401
     - 23434
     - 23883
     - 23890
     - 24605
     - 23462
     - 22630
     - 24210
     - 22980
     - 22443
     - 23185
     - 22601
     - 24219
     - 24382
     - 23692
     - 05753
     - 05201
     - 05819
     - 05401
     - 05906
     - 05478
     - 05440
     - 05672
     - 05060
     - 05855
     - 05701
     - 05641
     - 05301
     - 05156
     - 99344
     - 99403
     - 99336
     - 98801
     - 98382
     - 98682
     - 99328
     - 98632
     - 98802
     - 99166
     - 99301
     - 99347
     - 98837
     - 98520
     - 98277
     - 98368
     - 98052
     - 98312
     - 98926
     - 98672
     - 98531
     - 99122
     - 98584
     - 98841
     - 98640
     - 99156
     - 98391
     - 98250
     - 98273
     - 98648
     - 98012
     - 99208
     - 99114
     - 98501
     - 98612
     - 99362
     - 98225
     - 99163
     - 98902
     - 53934
     - 54806
     - 54868
     - 54891
     - 54115
     - 54755
     - 54830
     - 54915
     - 54729
     - 54456
     - 53901
     - 53821
     - 53711
     - 53916
     - 54235
     - 54880
     - 54751
     - 54703
     - 54121
     - 54935
     - 54520
     - 53818
     - 53566
     - 54923
     - 53533
     - 54547
     - 54615
     - 53538
     - 53948
     - 53142
     - 54216
     - 54601
     - 53530
     - 54409
     - 54452
     - 54220
     - 54401
     - 54143
     - 53949
     - 54135
     - 53209
     - 54656
     - 54153
     - 54501
     - 54911
     - 53092
     - 54736
     - 54022
     - 54001
     - 54481
     - 54555
     - 53402
     - 53581
     - 53511
     - 54848
     - 53913
     - 54843
     - 54166
     - 53081
     - 54016
     - 54451
     - 54612
     - 54665
     - 54521
     - 53147
     - 54801
     - 53022
     - 53051
     - 54981
     - 54982
     - 54956
     - 54449
     - 26416
     - 25404
     - 25130
     - 26601
     - 26070
     - 25701
     - 26147
     - 25043
     - 26456
     - 25901
     - 26351
     - 26847
     - 24901
     - 26757
     - 26062
     - 26836
     - 26301
     - 25271
     - 25414
     - 25177
     - 26452
     - 25506
     - 25601
     - 26554
     - 26041
     - 25550
     - 24801
     - 24701
     - 26726
     - 25661
     - 26505
     - 24963
     - 25411
     - 26651
     - 26003
     - 26807
     - 26170
     - 24954
     - 26537
     - 25526
     - 25801
     - 26241
     - 26362
     - 25276
     - 25951
     - 26354
     - 26287
     - 26175
     - 26201
     - 25704
     - 26288
     - 26155
     - 26143
     - 26101
     - 25882
     - 82070
     - 82431
     - 82718
     - 82301
     - 82633
     - 82729
     - 82501
     - 82240
     - 82443
     - 82834
     - 82001
     - 83127
     - 82601
     - 82225
     - 82414
     - 82201
     - 82801
     - 82941
     - 82901
     - 83001
     - 82930
     - 82401
     - 82701
   * - ``location_epw_path``
     - ../../../weather/G0200130.epw
     - ../../../weather/G0200160.epw
     - ../../../weather/G0200200.epw
     - ../../../weather/G0200500.epw
     - ../../../weather/G0200600.epw
     - ../../../weather/G0200680.epw
     - ../../../weather/G0200700.epw
     - ../../../weather/G0200900.epw
     - ../../../weather/G0201000.epw
     - ../../../weather/G0201050.epw
     - ../../../weather/G0201100.epw
     - ../../../weather/G0201220.epw
     - ../../../weather/G0201300.epw
     - ../../../weather/G0201500.epw
     - ../../../weather/G0202700.epw
     - ../../../weather/G0201640.epw
     - ../../../weather/G0201700.epw
     - ../../../weather/G0201800.epw
     - ../../../weather/G0201850.epw
     - ../../../weather/G0201880.epw
     - ../../../weather/G0201950.epw
     - ../../../weather/G0201980.epw
     - ../../../weather/G0202200.epw
     - ../../../weather/G0202300.epw
     - ../../../weather/G0202400.epw
     - ../../../weather/G0202610.epw
     - ../../../weather/G0202750.epw
     - ../../../weather/G0202820.epw
     - ../../../weather/G0202900.epw
     - ../../../weather/G0100010.epw
     - ../../../weather/G0100030.epw
     - ../../../weather/G0100050.epw
     - ../../../weather/G0100070.epw
     - ../../../weather/G0100090.epw
     - ../../../weather/G0100110.epw
     - ../../../weather/G0100130.epw
     - ../../../weather/G0100150.epw
     - ../../../weather/G0100170.epw
     - ../../../weather/G0100190.epw
     - ../../../weather/G0100210.epw
     - ../../../weather/G0100230.epw
     - ../../../weather/G0100250.epw
     - ../../../weather/G0100270.epw
     - ../../../weather/G0100290.epw
     - ../../../weather/G0100310.epw
     - ../../../weather/G0100330.epw
     - ../../../weather/G0100350.epw
     - ../../../weather/G0100370.epw
     - ../../../weather/G0100390.epw
     - ../../../weather/G0100410.epw
     - ../../../weather/G0100430.epw
     - ../../../weather/G0100450.epw
     - ../../../weather/G0100470.epw
     - ../../../weather/G0100490.epw
     - ../../../weather/G0100510.epw
     - ../../../weather/G0100530.epw
     - ../../../weather/G0100550.epw
     - ../../../weather/G0100570.epw
     - ../../../weather/G0100590.epw
     - ../../../weather/G0100610.epw
     - ../../../weather/G0100630.epw
     - ../../../weather/G0100650.epw
     - ../../../weather/G0100670.epw
     - ../../../weather/G0100690.epw
     - ../../../weather/G0100710.epw
     - ../../../weather/G0100730.epw
     - ../../../weather/G0100750.epw
     - ../../../weather/G0100770.epw
     - ../../../weather/G0100790.epw
     - ../../../weather/G0100810.epw
     - ../../../weather/G0100830.epw
     - ../../../weather/G0100850.epw
     - ../../../weather/G0100870.epw
     - ../../../weather/G0100890.epw
     - ../../../weather/G0100910.epw
     - ../../../weather/G0100930.epw
     - ../../../weather/G0100950.epw
     - ../../../weather/G0100970.epw
     - ../../../weather/G0100990.epw
     - ../../../weather/G0101010.epw
     - ../../../weather/G0101030.epw
     - ../../../weather/G0101050.epw
     - ../../../weather/G0101070.epw
     - ../../../weather/G0101090.epw
     - ../../../weather/G0101110.epw
     - ../../../weather/G0101130.epw
     - ../../../weather/G0101170.epw
     - ../../../weather/G0101150.epw
     - ../../../weather/G0101190.epw
     - ../../../weather/G0101210.epw
     - ../../../weather/G0101230.epw
     - ../../../weather/G0101250.epw
     - ../../../weather/G0101270.epw
     - ../../../weather/G0101290.epw
     - ../../../weather/G0101310.epw
     - ../../../weather/G0101330.epw
     - ../../../weather/G0500010.epw
     - ../../../weather/G0500030.epw
     - ../../../weather/G0500050.epw
     - ../../../weather/G0500070.epw
     - ../../../weather/G0500090.epw
     - ../../../weather/G0500110.epw
     - ../../../weather/G0500130.epw
     - ../../../weather/G0500150.epw
     - ../../../weather/G0500170.epw
     - ../../../weather/G0500190.epw
     - ../../../weather/G0500210.epw
     - ../../../weather/G0500230.epw
     - ../../../weather/G0500250.epw
     - ../../../weather/G0500270.epw
     - ../../../weather/G0500290.epw
     - ../../../weather/G0500310.epw
     - ../../../weather/G0500330.epw
     - ../../../weather/G0500350.epw
     - ../../../weather/G0500370.epw
     - ../../../weather/G0500390.epw
     - ../../../weather/G0500410.epw
     - ../../../weather/G0500430.epw
     - ../../../weather/G0500450.epw
     - ../../../weather/G0500470.epw
     - ../../../weather/G0500490.epw
     - ../../../weather/G0500510.epw
     - ../../../weather/G0500530.epw
     - ../../../weather/G0500550.epw
     - ../../../weather/G0500570.epw
     - ../../../weather/G0500590.epw
     - ../../../weather/G0500610.epw
     - ../../../weather/G0500630.epw
     - ../../../weather/G0500650.epw
     - ../../../weather/G0500670.epw
     - ../../../weather/G0500690.epw
     - ../../../weather/G0500710.epw
     - ../../../weather/G0500730.epw
     - ../../../weather/G0500750.epw
     - ../../../weather/G0500770.epw
     - ../../../weather/G0500790.epw
     - ../../../weather/G0500810.epw
     - ../../../weather/G0500830.epw
     - ../../../weather/G0500850.epw
     - ../../../weather/G0500870.epw
     - ../../../weather/G0500890.epw
     - ../../../weather/G0500910.epw
     - ../../../weather/G0500930.epw
     - ../../../weather/G0500950.epw
     - ../../../weather/G0500970.epw
     - ../../../weather/G0500990.epw
     - ../../../weather/G0501010.epw
     - ../../../weather/G0501030.epw
     - ../../../weather/G0501050.epw
     - ../../../weather/G0501070.epw
     - ../../../weather/G0501090.epw
     - ../../../weather/G0501110.epw
     - ../../../weather/G0501130.epw
     - ../../../weather/G0501150.epw
     - ../../../weather/G0501170.epw
     - ../../../weather/G0501190.epw
     - ../../../weather/G0501210.epw
     - ../../../weather/G0501250.epw
     - ../../../weather/G0501270.epw
     - ../../../weather/G0501290.epw
     - ../../../weather/G0501310.epw
     - ../../../weather/G0501330.epw
     - ../../../weather/G0501350.epw
     - ../../../weather/G0501230.epw
     - ../../../weather/G0501370.epw
     - ../../../weather/G0501390.epw
     - ../../../weather/G0501410.epw
     - ../../../weather/G0501430.epw
     - ../../../weather/G0501450.epw
     - ../../../weather/G0501470.epw
     - ../../../weather/G0501490.epw
     - ../../../weather/G0400010.epw
     - ../../../weather/G0400030.epw
     - ../../../weather/G0400050.epw
     - ../../../weather/G0400070.epw
     - ../../../weather/G0400090.epw
     - ../../../weather/G0400110.epw
     - ../../../weather/G0400120.epw
     - ../../../weather/G0400130.epw
     - ../../../weather/G0400150.epw
     - ../../../weather/G0400170.epw
     - ../../../weather/G0400190.epw
     - ../../../weather/G0400210.epw
     - ../../../weather/G0400230.epw
     - ../../../weather/G0400250.epw
     - ../../../weather/G0400270.epw
     - ../../../weather/G0600010.epw
     - ../../../weather/G0600030.epw
     - ../../../weather/G0600050.epw
     - ../../../weather/G0600070.epw
     - ../../../weather/G0600090.epw
     - ../../../weather/G0600110.epw
     - ../../../weather/G0600130.epw
     - ../../../weather/G0600150.epw
     - ../../../weather/G0600170.epw
     - ../../../weather/G0600190.epw
     - ../../../weather/G0600210.epw
     - ../../../weather/G0600230.epw
     - ../../../weather/G0600250.epw
     - ../../../weather/G0600270.epw
     - ../../../weather/G0600290.epw
     - ../../../weather/G0600310.epw
     - ../../../weather/G0600330.epw
     - ../../../weather/G0600350.epw
     - ../../../weather/G0600370.epw
     - ../../../weather/G0600390.epw
     - ../../../weather/G0600410.epw
     - ../../../weather/G0600430.epw
     - ../../../weather/G0600450.epw
     - ../../../weather/G0600470.epw
     - ../../../weather/G0600490.epw
     - ../../../weather/G0600510.epw
     - ../../../weather/G0600530.epw
     - ../../../weather/G0600550.epw
     - ../../../weather/G0600570.epw
     - ../../../weather/G0600590.epw
     - ../../../weather/G0600610.epw
     - ../../../weather/G0600630.epw
     - ../../../weather/G0600650.epw
     - ../../../weather/G0600670.epw
     - ../../../weather/G0600690.epw
     - ../../../weather/G0600710.epw
     - ../../../weather/G0600730.epw
     - ../../../weather/G0600750.epw
     - ../../../weather/G0600770.epw
     - ../../../weather/G0600790.epw
     - ../../../weather/G0600810.epw
     - ../../../weather/G0600830.epw
     - ../../../weather/G0600850.epw
     - ../../../weather/G0600870.epw
     - ../../../weather/G0600890.epw
     - ../../../weather/G0600910.epw
     - ../../../weather/G0600930.epw
     - ../../../weather/G0600950.epw
     - ../../../weather/G0600970.epw
     - ../../../weather/G0600990.epw
     - ../../../weather/G0601010.epw
     - ../../../weather/G0601030.epw
     - ../../../weather/G0601050.epw
     - ../../../weather/G0601070.epw
     - ../../../weather/G0601090.epw
     - ../../../weather/G0601110.epw
     - ../../../weather/G0601130.epw
     - ../../../weather/G0601150.epw
     - ../../../weather/G0800010.epw
     - ../../../weather/G0800030.epw
     - ../../../weather/G0800050.epw
     - ../../../weather/G0800070.epw
     - ../../../weather/G0800090.epw
     - ../../../weather/G0800110.epw
     - ../../../weather/G0800130.epw
     - ../../../weather/G0800140.epw
     - ../../../weather/G0800150.epw
     - ../../../weather/G0800170.epw
     - ../../../weather/G0800190.epw
     - ../../../weather/G0800210.epw
     - ../../../weather/G0800230.epw
     - ../../../weather/G0800250.epw
     - ../../../weather/G0800270.epw
     - ../../../weather/G0800290.epw
     - ../../../weather/G0800310.epw
     - ../../../weather/G0800330.epw
     - ../../../weather/G0800350.epw
     - ../../../weather/G0800370.epw
     - ../../../weather/G0800410.epw
     - ../../../weather/G0800390.epw
     - ../../../weather/G0800430.epw
     - ../../../weather/G0800450.epw
     - ../../../weather/G0800470.epw
     - ../../../weather/G0800490.epw
     - ../../../weather/G0800510.epw
     - ../../../weather/G0800530.epw
     - ../../../weather/G0800550.epw
     - ../../../weather/G0800570.epw
     - ../../../weather/G0800590.epw
     - ../../../weather/G0800610.epw
     - ../../../weather/G0800630.epw
     - ../../../weather/G0800670.epw
     - ../../../weather/G0800650.epw
     - ../../../weather/G0800690.epw
     - ../../../weather/G0800710.epw
     - ../../../weather/G0800730.epw
     - ../../../weather/G0800750.epw
     - ../../../weather/G0800770.epw
     - ../../../weather/G0800790.epw
     - ../../../weather/G0800810.epw
     - ../../../weather/G0800830.epw
     - ../../../weather/G0800850.epw
     - ../../../weather/G0800870.epw
     - ../../../weather/G0800890.epw
     - ../../../weather/G0800910.epw
     - ../../../weather/G0800930.epw
     - ../../../weather/G0800950.epw
     - ../../../weather/G0800970.epw
     - ../../../weather/G0800990.epw
     - ../../../weather/G0801010.epw
     - ../../../weather/G0801030.epw
     - ../../../weather/G0801050.epw
     - ../../../weather/G0801070.epw
     - ../../../weather/G0801090.epw
     - ../../../weather/G0801110.epw
     - ../../../weather/G0801130.epw
     - ../../../weather/G0801150.epw
     - ../../../weather/G0801170.epw
     - ../../../weather/G0801190.epw
     - ../../../weather/G0801210.epw
     - ../../../weather/G0801230.epw
     - ../../../weather/G0801250.epw
     - ../../../weather/G0900010.epw
     - ../../../weather/G0900030.epw
     - ../../../weather/G0900050.epw
     - ../../../weather/G0900070.epw
     - ../../../weather/G0900090.epw
     - ../../../weather/G0900110.epw
     - ../../../weather/G0900130.epw
     - ../../../weather/G0900150.epw
     - ../../../weather/G1100010.epw
     - ../../../weather/G1000010.epw
     - ../../../weather/G1000030.epw
     - ../../../weather/G1000050.epw
     - ../../../weather/G1200010.epw
     - ../../../weather/G1200030.epw
     - ../../../weather/G1200050.epw
     - ../../../weather/G1200070.epw
     - ../../../weather/G1200090.epw
     - ../../../weather/G1200110.epw
     - ../../../weather/G1200130.epw
     - ../../../weather/G1200150.epw
     - ../../../weather/G1200170.epw
     - ../../../weather/G1200190.epw
     - ../../../weather/G1200210.epw
     - ../../../weather/G1200230.epw
     - ../../../weather/G1200270.epw
     - ../../../weather/G1200290.epw
     - ../../../weather/G1200310.epw
     - ../../../weather/G1200330.epw
     - ../../../weather/G1200350.epw
     - ../../../weather/G1200370.epw
     - ../../../weather/G1200390.epw
     - ../../../weather/G1200410.epw
     - ../../../weather/G1200430.epw
     - ../../../weather/G1200450.epw
     - ../../../weather/G1200470.epw
     - ../../../weather/G1200490.epw
     - ../../../weather/G1200510.epw
     - ../../../weather/G1200530.epw
     - ../../../weather/G1200550.epw
     - ../../../weather/G1200570.epw
     - ../../../weather/G1200590.epw
     - ../../../weather/G1200610.epw
     - ../../../weather/G1200630.epw
     - ../../../weather/G1200650.epw
     - ../../../weather/G1200670.epw
     - ../../../weather/G1200690.epw
     - ../../../weather/G1200710.epw
     - ../../../weather/G1200730.epw
     - ../../../weather/G1200750.epw
     - ../../../weather/G1200770.epw
     - ../../../weather/G1200790.epw
     - ../../../weather/G1200810.epw
     - ../../../weather/G1200830.epw
     - ../../../weather/G1200850.epw
     - ../../../weather/G1200860.epw
     - ../../../weather/G1200870.epw
     - ../../../weather/G1200890.epw
     - ../../../weather/G1200910.epw
     - ../../../weather/G1200930.epw
     - ../../../weather/G1200950.epw
     - ../../../weather/G1200970.epw
     - ../../../weather/G1200990.epw
     - ../../../weather/G1201010.epw
     - ../../../weather/G1201030.epw
     - ../../../weather/G1201050.epw
     - ../../../weather/G1201070.epw
     - ../../../weather/G1201130.epw
     - ../../../weather/G1201150.epw
     - ../../../weather/G1201170.epw
     - ../../../weather/G1201090.epw
     - ../../../weather/G1201110.epw
     - ../../../weather/G1201190.epw
     - ../../../weather/G1201210.epw
     - ../../../weather/G1201230.epw
     - ../../../weather/G1201250.epw
     - ../../../weather/G1201270.epw
     - ../../../weather/G1201290.epw
     - ../../../weather/G1201310.epw
     - ../../../weather/G1201330.epw
     - ../../../weather/G1300010.epw
     - ../../../weather/G1300030.epw
     - ../../../weather/G1300050.epw
     - ../../../weather/G1300070.epw
     - ../../../weather/G1300090.epw
     - ../../../weather/G1300110.epw
     - ../../../weather/G1300130.epw
     - ../../../weather/G1300150.epw
     - ../../../weather/G1300170.epw
     - ../../../weather/G1300190.epw
     - ../../../weather/G1300210.epw
     - ../../../weather/G1300230.epw
     - ../../../weather/G1300250.epw
     - ../../../weather/G1300270.epw
     - ../../../weather/G1300290.epw
     - ../../../weather/G1300310.epw
     - ../../../weather/G1300330.epw
     - ../../../weather/G1300350.epw
     - ../../../weather/G1300370.epw
     - ../../../weather/G1300390.epw
     - ../../../weather/G1300430.epw
     - ../../../weather/G1300450.epw
     - ../../../weather/G1300470.epw
     - ../../../weather/G1300490.epw
     - ../../../weather/G1300510.epw
     - ../../../weather/G1300530.epw
     - ../../../weather/G1300550.epw
     - ../../../weather/G1300570.epw
     - ../../../weather/G1300590.epw
     - ../../../weather/G1300610.epw
     - ../../../weather/G1300630.epw
     - ../../../weather/G1300650.epw
     - ../../../weather/G1300670.epw
     - ../../../weather/G1300690.epw
     - ../../../weather/G1300710.epw
     - ../../../weather/G1300730.epw
     - ../../../weather/G1300750.epw
     - ../../../weather/G1300770.epw
     - ../../../weather/G1300790.epw
     - ../../../weather/G1300810.epw
     - ../../../weather/G1300830.epw
     - ../../../weather/G1300850.epw
     - ../../../weather/G1300870.epw
     - ../../../weather/G1300890.epw
     - ../../../weather/G1300910.epw
     - ../../../weather/G1300930.epw
     - ../../../weather/G1300950.epw
     - ../../../weather/G1300970.epw
     - ../../../weather/G1300990.epw
     - ../../../weather/G1301010.epw
     - ../../../weather/G1301030.epw
     - ../../../weather/G1301050.epw
     - ../../../weather/G1301070.epw
     - ../../../weather/G1301090.epw
     - ../../../weather/G1301110.epw
     - ../../../weather/G1301130.epw
     - ../../../weather/G1301150.epw
     - ../../../weather/G1301170.epw
     - ../../../weather/G1301190.epw
     - ../../../weather/G1301210.epw
     - ../../../weather/G1301230.epw
     - ../../../weather/G1301250.epw
     - ../../../weather/G1301270.epw
     - ../../../weather/G1301290.epw
     - ../../../weather/G1301310.epw
     - ../../../weather/G1301330.epw
     - ../../../weather/G1301350.epw
     - ../../../weather/G1301370.epw
     - ../../../weather/G1301390.epw
     - ../../../weather/G1301410.epw
     - ../../../weather/G1301430.epw
     - ../../../weather/G1301450.epw
     - ../../../weather/G1301470.epw
     - ../../../weather/G1301490.epw
     - ../../../weather/G1301510.epw
     - ../../../weather/G1301530.epw
     - ../../../weather/G1301550.epw
     - ../../../weather/G1301570.epw
     - ../../../weather/G1301590.epw
     - ../../../weather/G1301610.epw
     - ../../../weather/G1301630.epw
     - ../../../weather/G1301650.epw
     - ../../../weather/G1301670.epw
     - ../../../weather/G1301690.epw
     - ../../../weather/G1301710.epw
     - ../../../weather/G1301730.epw
     - ../../../weather/G1301750.epw
     - ../../../weather/G1301770.epw
     - ../../../weather/G1301790.epw
     - ../../../weather/G1301810.epw
     - ../../../weather/G1301830.epw
     - ../../../weather/G1301850.epw
     - ../../../weather/G1301870.epw
     - ../../../weather/G1301930.epw
     - ../../../weather/G1301950.epw
     - ../../../weather/G1301970.epw
     - ../../../weather/G1301890.epw
     - ../../../weather/G1301910.epw
     - ../../../weather/G1301990.epw
     - ../../../weather/G1302010.epw
     - ../../../weather/G1302050.epw
     - ../../../weather/G1302070.epw
     - ../../../weather/G1302090.epw
     - ../../../weather/G1302110.epw
     - ../../../weather/G1302130.epw
     - ../../../weather/G1302150.epw
     - ../../../weather/G1302170.epw
     - ../../../weather/G1302190.epw
     - ../../../weather/G1302210.epw
     - ../../../weather/G1302230.epw
     - ../../../weather/G1302250.epw
     - ../../../weather/G1302270.epw
     - ../../../weather/G1302290.epw
     - ../../../weather/G1302310.epw
     - ../../../weather/G1302330.epw
     - ../../../weather/G1302350.epw
     - ../../../weather/G1302370.epw
     - ../../../weather/G1302390.epw
     - ../../../weather/G1302410.epw
     - ../../../weather/G1302430.epw
     - ../../../weather/G1302450.epw
     - ../../../weather/G1302470.epw
     - ../../../weather/G1302490.epw
     - ../../../weather/G1302510.epw
     - ../../../weather/G1302530.epw
     - ../../../weather/G1302550.epw
     - ../../../weather/G1302570.epw
     - ../../../weather/G1302590.epw
     - ../../../weather/G1302610.epw
     - ../../../weather/G1302630.epw
     - ../../../weather/G1302650.epw
     - ../../../weather/G1302670.epw
     - ../../../weather/G1302690.epw
     - ../../../weather/G1302710.epw
     - ../../../weather/G1302730.epw
     - ../../../weather/G1302750.epw
     - ../../../weather/G1302770.epw
     - ../../../weather/G1302790.epw
     - ../../../weather/G1302810.epw
     - ../../../weather/G1302830.epw
     - ../../../weather/G1302850.epw
     - ../../../weather/G1302870.epw
     - ../../../weather/G1302890.epw
     - ../../../weather/G1302910.epw
     - ../../../weather/G1302930.epw
     - ../../../weather/G1302950.epw
     - ../../../weather/G1302970.epw
     - ../../../weather/G1302990.epw
     - ../../../weather/G1303010.epw
     - ../../../weather/G1303030.epw
     - ../../../weather/G1303050.epw
     - ../../../weather/G1303070.epw
     - ../../../weather/G1303090.epw
     - ../../../weather/G1303110.epw
     - ../../../weather/G1303130.epw
     - ../../../weather/G1303150.epw
     - ../../../weather/G1303170.epw
     - ../../../weather/G1303190.epw
     - ../../../weather/G1303210.epw
     - ../../../weather/G1500010.epw
     - ../../../weather/G1500030.epw
     - ../../../weather/G1500050.epw
     - ../../../weather/G1500070.epw
     - ../../../weather/G1500090.epw
     - ../../../weather/G1900010.epw
     - ../../../weather/G1900030.epw
     - ../../../weather/G1900050.epw
     - ../../../weather/G1900070.epw
     - ../../../weather/G1900090.epw
     - ../../../weather/G1900110.epw
     - ../../../weather/G1900130.epw
     - ../../../weather/G1900150.epw
     - ../../../weather/G1900170.epw
     - ../../../weather/G1900190.epw
     - ../../../weather/G1900210.epw
     - ../../../weather/G1900230.epw
     - ../../../weather/G1900250.epw
     - ../../../weather/G1900270.epw
     - ../../../weather/G1900290.epw
     - ../../../weather/G1900310.epw
     - ../../../weather/G1900330.epw
     - ../../../weather/G1900350.epw
     - ../../../weather/G1900370.epw
     - ../../../weather/G1900390.epw
     - ../../../weather/G1900410.epw
     - ../../../weather/G1900430.epw
     - ../../../weather/G1900450.epw
     - ../../../weather/G1900470.epw
     - ../../../weather/G1900490.epw
     - ../../../weather/G1900510.epw
     - ../../../weather/G1900530.epw
     - ../../../weather/G1900550.epw
     - ../../../weather/G1900570.epw
     - ../../../weather/G1900590.epw
     - ../../../weather/G1900610.epw
     - ../../../weather/G1900630.epw
     - ../../../weather/G1900650.epw
     - ../../../weather/G1900670.epw
     - ../../../weather/G1900690.epw
     - ../../../weather/G1900710.epw
     - ../../../weather/G1900730.epw
     - ../../../weather/G1900750.epw
     - ../../../weather/G1900770.epw
     - ../../../weather/G1900790.epw
     - ../../../weather/G1900810.epw
     - ../../../weather/G1900830.epw
     - ../../../weather/G1900850.epw
     - ../../../weather/G1900870.epw
     - ../../../weather/G1900890.epw
     - ../../../weather/G1900910.epw
     - ../../../weather/G1900930.epw
     - ../../../weather/G1900950.epw
     - ../../../weather/G1900970.epw
     - ../../../weather/G1900990.epw
     - ../../../weather/G1901010.epw
     - ../../../weather/G1901030.epw
     - ../../../weather/G1901050.epw
     - ../../../weather/G1901070.epw
     - ../../../weather/G1901090.epw
     - ../../../weather/G1901110.epw
     - ../../../weather/G1901130.epw
     - ../../../weather/G1901150.epw
     - ../../../weather/G1901170.epw
     - ../../../weather/G1901190.epw
     - ../../../weather/G1901210.epw
     - ../../../weather/G1901230.epw
     - ../../../weather/G1901250.epw
     - ../../../weather/G1901270.epw
     - ../../../weather/G1901290.epw
     - ../../../weather/G1901310.epw
     - ../../../weather/G1901330.epw
     - ../../../weather/G1901350.epw
     - ../../../weather/G1901370.epw
     - ../../../weather/G1901390.epw
     - ../../../weather/G1901410.epw
     - ../../../weather/G1901430.epw
     - ../../../weather/G1901450.epw
     - ../../../weather/G1901470.epw
     - ../../../weather/G1901490.epw
     - ../../../weather/G1901510.epw
     - ../../../weather/G1901530.epw
     - ../../../weather/G1901550.epw
     - ../../../weather/G1901570.epw
     - ../../../weather/G1901590.epw
     - ../../../weather/G1901610.epw
     - ../../../weather/G1901630.epw
     - ../../../weather/G1901650.epw
     - ../../../weather/G1901670.epw
     - ../../../weather/G1901690.epw
     - ../../../weather/G1901710.epw
     - ../../../weather/G1901730.epw
     - ../../../weather/G1901750.epw
     - ../../../weather/G1901770.epw
     - ../../../weather/G1901790.epw
     - ../../../weather/G1901810.epw
     - ../../../weather/G1901830.epw
     - ../../../weather/G1901850.epw
     - ../../../weather/G1901870.epw
     - ../../../weather/G1901890.epw
     - ../../../weather/G1901910.epw
     - ../../../weather/G1901930.epw
     - ../../../weather/G1901950.epw
     - ../../../weather/G1901970.epw
     - ../../../weather/G1600010.epw
     - ../../../weather/G1600030.epw
     - ../../../weather/G1600050.epw
     - ../../../weather/G1600070.epw
     - ../../../weather/G1600090.epw
     - ../../../weather/G1600110.epw
     - ../../../weather/G1600130.epw
     - ../../../weather/G1600150.epw
     - ../../../weather/G1600170.epw
     - ../../../weather/G1600190.epw
     - ../../../weather/G1600210.epw
     - ../../../weather/G1600230.epw
     - ../../../weather/G1600250.epw
     - ../../../weather/G1600270.epw
     - ../../../weather/G1600290.epw
     - ../../../weather/G1600310.epw
     - ../../../weather/G1600330.epw
     - ../../../weather/G1600350.epw
     - ../../../weather/G1600370.epw
     - ../../../weather/G1600390.epw
     - ../../../weather/G1600410.epw
     - ../../../weather/G1600430.epw
     - ../../../weather/G1600450.epw
     - ../../../weather/G1600470.epw
     - ../../../weather/G1600490.epw
     - ../../../weather/G1600510.epw
     - ../../../weather/G1600530.epw
     - ../../../weather/G1600550.epw
     - ../../../weather/G1600570.epw
     - ../../../weather/G1600590.epw
     - ../../../weather/G1600610.epw
     - ../../../weather/G1600630.epw
     - ../../../weather/G1600650.epw
     - ../../../weather/G1600670.epw
     - ../../../weather/G1600690.epw
     - ../../../weather/G1600710.epw
     - ../../../weather/G1600730.epw
     - ../../../weather/G1600750.epw
     - ../../../weather/G1600770.epw
     - ../../../weather/G1600790.epw
     - ../../../weather/G1600810.epw
     - ../../../weather/G1600830.epw
     - ../../../weather/G1600850.epw
     - ../../../weather/G1600870.epw
     - ../../../weather/G1700010.epw
     - ../../../weather/G1700030.epw
     - ../../../weather/G1700050.epw
     - ../../../weather/G1700070.epw
     - ../../../weather/G1700090.epw
     - ../../../weather/G1700110.epw
     - ../../../weather/G1700130.epw
     - ../../../weather/G1700150.epw
     - ../../../weather/G1700170.epw
     - ../../../weather/G1700190.epw
     - ../../../weather/G1700210.epw
     - ../../../weather/G1700230.epw
     - ../../../weather/G1700250.epw
     - ../../../weather/G1700270.epw
     - ../../../weather/G1700290.epw
     - ../../../weather/G1700310.epw
     - ../../../weather/G1700330.epw
     - ../../../weather/G1700350.epw
     - ../../../weather/G1700390.epw
     - ../../../weather/G1700370.epw
     - ../../../weather/G1700410.epw
     - ../../../weather/G1700430.epw
     - ../../../weather/G1700450.epw
     - ../../../weather/G1700470.epw
     - ../../../weather/G1700490.epw
     - ../../../weather/G1700510.epw
     - ../../../weather/G1700530.epw
     - ../../../weather/G1700550.epw
     - ../../../weather/G1700570.epw
     - ../../../weather/G1700590.epw
     - ../../../weather/G1700610.epw
     - ../../../weather/G1700630.epw
     - ../../../weather/G1700650.epw
     - ../../../weather/G1700670.epw
     - ../../../weather/G1700690.epw
     - ../../../weather/G1700710.epw
     - ../../../weather/G1700730.epw
     - ../../../weather/G1700750.epw
     - ../../../weather/G1700770.epw
     - ../../../weather/G1700790.epw
     - ../../../weather/G1700810.epw
     - ../../../weather/G1700830.epw
     - ../../../weather/G1700850.epw
     - ../../../weather/G1700870.epw
     - ../../../weather/G1700890.epw
     - ../../../weather/G1700910.epw
     - ../../../weather/G1700930.epw
     - ../../../weather/G1700950.epw
     - ../../../weather/G1700970.epw
     - ../../../weather/G1700990.epw
     - ../../../weather/G1701010.epw
     - ../../../weather/G1701030.epw
     - ../../../weather/G1701050.epw
     - ../../../weather/G1701070.epw
     - ../../../weather/G1701150.epw
     - ../../../weather/G1701170.epw
     - ../../../weather/G1701190.epw
     - ../../../weather/G1701210.epw
     - ../../../weather/G1701230.epw
     - ../../../weather/G1701250.epw
     - ../../../weather/G1701270.epw
     - ../../../weather/G1701090.epw
     - ../../../weather/G1701110.epw
     - ../../../weather/G1701130.epw
     - ../../../weather/G1701290.epw
     - ../../../weather/G1701310.epw
     - ../../../weather/G1701330.epw
     - ../../../weather/G1701350.epw
     - ../../../weather/G1701370.epw
     - ../../../weather/G1701390.epw
     - ../../../weather/G1701410.epw
     - ../../../weather/G1701430.epw
     - ../../../weather/G1701450.epw
     - ../../../weather/G1701470.epw
     - ../../../weather/G1701490.epw
     - ../../../weather/G1701510.epw
     - ../../../weather/G1701530.epw
     - ../../../weather/G1701550.epw
     - ../../../weather/G1701570.epw
     - ../../../weather/G1701590.epw
     - ../../../weather/G1701610.epw
     - ../../../weather/G1701650.epw
     - ../../../weather/G1701670.epw
     - ../../../weather/G1701690.epw
     - ../../../weather/G1701710.epw
     - ../../../weather/G1701730.epw
     - ../../../weather/G1701630.epw
     - ../../../weather/G1701750.epw
     - ../../../weather/G1701770.epw
     - ../../../weather/G1701790.epw
     - ../../../weather/G1701810.epw
     - ../../../weather/G1701830.epw
     - ../../../weather/G1701850.epw
     - ../../../weather/G1701870.epw
     - ../../../weather/G1701890.epw
     - ../../../weather/G1701910.epw
     - ../../../weather/G1701930.epw
     - ../../../weather/G1701950.epw
     - ../../../weather/G1701970.epw
     - ../../../weather/G1701990.epw
     - ../../../weather/G1702010.epw
     - ../../../weather/G1702030.epw
     - ../../../weather/G1800010.epw
     - ../../../weather/G1800030.epw
     - ../../../weather/G1800050.epw
     - ../../../weather/G1800070.epw
     - ../../../weather/G1800090.epw
     - ../../../weather/G1800110.epw
     - ../../../weather/G1800130.epw
     - ../../../weather/G1800150.epw
     - ../../../weather/G1800170.epw
     - ../../../weather/G1800190.epw
     - ../../../weather/G1800210.epw
     - ../../../weather/G1800230.epw
     - ../../../weather/G1800250.epw
     - ../../../weather/G1800270.epw
     - ../../../weather/G1800290.epw
     - ../../../weather/G1800310.epw
     - ../../../weather/G1800330.epw
     - ../../../weather/G1800350.epw
     - ../../../weather/G1800370.epw
     - ../../../weather/G1800390.epw
     - ../../../weather/G1800410.epw
     - ../../../weather/G1800430.epw
     - ../../../weather/G1800450.epw
     - ../../../weather/G1800470.epw
     - ../../../weather/G1800490.epw
     - ../../../weather/G1800510.epw
     - ../../../weather/G1800530.epw
     - ../../../weather/G1800550.epw
     - ../../../weather/G1800570.epw
     - ../../../weather/G1800590.epw
     - ../../../weather/G1800610.epw
     - ../../../weather/G1800630.epw
     - ../../../weather/G1800650.epw
     - ../../../weather/G1800670.epw
     - ../../../weather/G1800690.epw
     - ../../../weather/G1800710.epw
     - ../../../weather/G1800730.epw
     - ../../../weather/G1800750.epw
     - ../../../weather/G1800770.epw
     - ../../../weather/G1800790.epw
     - ../../../weather/G1800810.epw
     - ../../../weather/G1800830.epw
     - ../../../weather/G1800850.epw
     - ../../../weather/G1800870.epw
     - ../../../weather/G1800890.epw
     - ../../../weather/G1800910.epw
     - ../../../weather/G1800930.epw
     - ../../../weather/G1800950.epw
     - ../../../weather/G1800970.epw
     - ../../../weather/G1800990.epw
     - ../../../weather/G1801010.epw
     - ../../../weather/G1801030.epw
     - ../../../weather/G1801050.epw
     - ../../../weather/G1801070.epw
     - ../../../weather/G1801090.epw
     - ../../../weather/G1801110.epw
     - ../../../weather/G1801130.epw
     - ../../../weather/G1801150.epw
     - ../../../weather/G1801170.epw
     - ../../../weather/G1801190.epw
     - ../../../weather/G1801210.epw
     - ../../../weather/G1801230.epw
     - ../../../weather/G1801250.epw
     - ../../../weather/G1801270.epw
     - ../../../weather/G1801290.epw
     - ../../../weather/G1801310.epw
     - ../../../weather/G1801330.epw
     - ../../../weather/G1801350.epw
     - ../../../weather/G1801370.epw
     - ../../../weather/G1801390.epw
     - ../../../weather/G1801430.epw
     - ../../../weather/G1801450.epw
     - ../../../weather/G1801470.epw
     - ../../../weather/G1801410.epw
     - ../../../weather/G1801490.epw
     - ../../../weather/G1801510.epw
     - ../../../weather/G1801530.epw
     - ../../../weather/G1801550.epw
     - ../../../weather/G1801570.epw
     - ../../../weather/G1801590.epw
     - ../../../weather/G1801610.epw
     - ../../../weather/G1801630.epw
     - ../../../weather/G1801650.epw
     - ../../../weather/G1801670.epw
     - ../../../weather/G1801690.epw
     - ../../../weather/G1801710.epw
     - ../../../weather/G1801730.epw
     - ../../../weather/G1801750.epw
     - ../../../weather/G1801770.epw
     - ../../../weather/G1801790.epw
     - ../../../weather/G1801810.epw
     - ../../../weather/G1801830.epw
     - ../../../weather/G2000010.epw
     - ../../../weather/G2000030.epw
     - ../../../weather/G2000050.epw
     - ../../../weather/G2000070.epw
     - ../../../weather/G2000090.epw
     - ../../../weather/G2000110.epw
     - ../../../weather/G2000130.epw
     - ../../../weather/G2000150.epw
     - ../../../weather/G2000170.epw
     - ../../../weather/G2000190.epw
     - ../../../weather/G2000210.epw
     - ../../../weather/G2000230.epw
     - ../../../weather/G2000250.epw
     - ../../../weather/G2000270.epw
     - ../../../weather/G2000290.epw
     - ../../../weather/G2000310.epw
     - ../../../weather/G2000330.epw
     - ../../../weather/G2000350.epw
     - ../../../weather/G2000370.epw
     - ../../../weather/G2000390.epw
     - ../../../weather/G2000410.epw
     - ../../../weather/G2000430.epw
     - ../../../weather/G2000450.epw
     - ../../../weather/G2000470.epw
     - ../../../weather/G2000490.epw
     - ../../../weather/G2000510.epw
     - ../../../weather/G2000530.epw
     - ../../../weather/G2000550.epw
     - ../../../weather/G2000570.epw
     - ../../../weather/G2000590.epw
     - ../../../weather/G2000610.epw
     - ../../../weather/G2000630.epw
     - ../../../weather/G2000650.epw
     - ../../../weather/G2000670.epw
     - ../../../weather/G2000690.epw
     - ../../../weather/G2000710.epw
     - ../../../weather/G2000730.epw
     - ../../../weather/G2000750.epw
     - ../../../weather/G2000770.epw
     - ../../../weather/G2000790.epw
     - ../../../weather/G2000810.epw
     - ../../../weather/G2000830.epw
     - ../../../weather/G2000850.epw
     - ../../../weather/G2000870.epw
     - ../../../weather/G2000890.epw
     - ../../../weather/G2000910.epw
     - ../../../weather/G2000930.epw
     - ../../../weather/G2000950.epw
     - ../../../weather/G2000970.epw
     - ../../../weather/G2000990.epw
     - ../../../weather/G2001010.epw
     - ../../../weather/G2001030.epw
     - ../../../weather/G2001050.epw
     - ../../../weather/G2001070.epw
     - ../../../weather/G2001090.epw
     - ../../../weather/G2001110.epw
     - ../../../weather/G2001150.epw
     - ../../../weather/G2001170.epw
     - ../../../weather/G2001130.epw
     - ../../../weather/G2001190.epw
     - ../../../weather/G2001210.epw
     - ../../../weather/G2001230.epw
     - ../../../weather/G2001250.epw
     - ../../../weather/G2001270.epw
     - ../../../weather/G2001290.epw
     - ../../../weather/G2001310.epw
     - ../../../weather/G2001330.epw
     - ../../../weather/G2001350.epw
     - ../../../weather/G2001370.epw
     - ../../../weather/G2001390.epw
     - ../../../weather/G2001410.epw
     - ../../../weather/G2001430.epw
     - ../../../weather/G2001450.epw
     - ../../../weather/G2001470.epw
     - ../../../weather/G2001490.epw
     - ../../../weather/G2001510.epw
     - ../../../weather/G2001530.epw
     - ../../../weather/G2001550.epw
     - ../../../weather/G2001570.epw
     - ../../../weather/G2001590.epw
     - ../../../weather/G2001610.epw
     - ../../../weather/G2001630.epw
     - ../../../weather/G2001650.epw
     - ../../../weather/G2001670.epw
     - ../../../weather/G2001690.epw
     - ../../../weather/G2001710.epw
     - ../../../weather/G2001730.epw
     - ../../../weather/G2001750.epw
     - ../../../weather/G2001770.epw
     - ../../../weather/G2001790.epw
     - ../../../weather/G2001810.epw
     - ../../../weather/G2001830.epw
     - ../../../weather/G2001850.epw
     - ../../../weather/G2001870.epw
     - ../../../weather/G2001890.epw
     - ../../../weather/G2001910.epw
     - ../../../weather/G2001930.epw
     - ../../../weather/G2001950.epw
     - ../../../weather/G2001970.epw
     - ../../../weather/G2001990.epw
     - ../../../weather/G2002010.epw
     - ../../../weather/G2002030.epw
     - ../../../weather/G2002050.epw
     - ../../../weather/G2002070.epw
     - ../../../weather/G2002090.epw
     - ../../../weather/G2100010.epw
     - ../../../weather/G2100030.epw
     - ../../../weather/G2100050.epw
     - ../../../weather/G2100070.epw
     - ../../../weather/G2100090.epw
     - ../../../weather/G2100110.epw
     - ../../../weather/G2100130.epw
     - ../../../weather/G2100150.epw
     - ../../../weather/G2100170.epw
     - ../../../weather/G2100190.epw
     - ../../../weather/G2100210.epw
     - ../../../weather/G2100230.epw
     - ../../../weather/G2100250.epw
     - ../../../weather/G2100270.epw
     - ../../../weather/G2100290.epw
     - ../../../weather/G2100310.epw
     - ../../../weather/G2100330.epw
     - ../../../weather/G2100350.epw
     - ../../../weather/G2100370.epw
     - ../../../weather/G2100390.epw
     - ../../../weather/G2100410.epw
     - ../../../weather/G2100430.epw
     - ../../../weather/G2100450.epw
     - ../../../weather/G2100470.epw
     - ../../../weather/G2100490.epw
     - ../../../weather/G2100510.epw
     - ../../../weather/G2100530.epw
     - ../../../weather/G2100550.epw
     - ../../../weather/G2100570.epw
     - ../../../weather/G2100590.epw
     - ../../../weather/G2100610.epw
     - ../../../weather/G2100630.epw
     - ../../../weather/G2100650.epw
     - ../../../weather/G2100670.epw
     - ../../../weather/G2100690.epw
     - ../../../weather/G2100710.epw
     - ../../../weather/G2100730.epw
     - ../../../weather/G2100750.epw
     - ../../../weather/G2100770.epw
     - ../../../weather/G2100790.epw
     - ../../../weather/G2100810.epw
     - ../../../weather/G2100830.epw
     - ../../../weather/G2100850.epw
     - ../../../weather/G2100870.epw
     - ../../../weather/G2100890.epw
     - ../../../weather/G2100910.epw
     - ../../../weather/G2100930.epw
     - ../../../weather/G2100950.epw
     - ../../../weather/G2100970.epw
     - ../../../weather/G2100990.epw
     - ../../../weather/G2101010.epw
     - ../../../weather/G2101030.epw
     - ../../../weather/G2101050.epw
     - ../../../weather/G2101070.epw
     - ../../../weather/G2101090.epw
     - ../../../weather/G2101110.epw
     - ../../../weather/G2101130.epw
     - ../../../weather/G2101150.epw
     - ../../../weather/G2101170.epw
     - ../../../weather/G2101190.epw
     - ../../../weather/G2101210.epw
     - ../../../weather/G2101230.epw
     - ../../../weather/G2101250.epw
     - ../../../weather/G2101270.epw
     - ../../../weather/G2101290.epw
     - ../../../weather/G2101310.epw
     - ../../../weather/G2101330.epw
     - ../../../weather/G2101350.epw
     - ../../../weather/G2101370.epw
     - ../../../weather/G2101390.epw
     - ../../../weather/G2101410.epw
     - ../../../weather/G2101430.epw
     - ../../../weather/G2101510.epw
     - ../../../weather/G2101530.epw
     - ../../../weather/G2101550.epw
     - ../../../weather/G2101570.epw
     - ../../../weather/G2101590.epw
     - ../../../weather/G2101610.epw
     - ../../../weather/G2101450.epw
     - ../../../weather/G2101470.epw
     - ../../../weather/G2101490.epw
     - ../../../weather/G2101630.epw
     - ../../../weather/G2101650.epw
     - ../../../weather/G2101670.epw
     - ../../../weather/G2101690.epw
     - ../../../weather/G2101710.epw
     - ../../../weather/G2101730.epw
     - ../../../weather/G2101750.epw
     - ../../../weather/G2101770.epw
     - ../../../weather/G2101790.epw
     - ../../../weather/G2101810.epw
     - ../../../weather/G2101830.epw
     - ../../../weather/G2101850.epw
     - ../../../weather/G2101870.epw
     - ../../../weather/G2101890.epw
     - ../../../weather/G2101910.epw
     - ../../../weather/G2101930.epw
     - ../../../weather/G2101950.epw
     - ../../../weather/G2101970.epw
     - ../../../weather/G2101990.epw
     - ../../../weather/G2102010.epw
     - ../../../weather/G2102030.epw
     - ../../../weather/G2102050.epw
     - ../../../weather/G2102070.epw
     - ../../../weather/G2102090.epw
     - ../../../weather/G2102110.epw
     - ../../../weather/G2102130.epw
     - ../../../weather/G2102150.epw
     - ../../../weather/G2102170.epw
     - ../../../weather/G2102190.epw
     - ../../../weather/G2102210.epw
     - ../../../weather/G2102230.epw
     - ../../../weather/G2102250.epw
     - ../../../weather/G2102270.epw
     - ../../../weather/G2102290.epw
     - ../../../weather/G2102310.epw
     - ../../../weather/G2102330.epw
     - ../../../weather/G2102350.epw
     - ../../../weather/G2102370.epw
     - ../../../weather/G2102390.epw
     - ../../../weather/G2200010.epw
     - ../../../weather/G2200030.epw
     - ../../../weather/G2200050.epw
     - ../../../weather/G2200070.epw
     - ../../../weather/G2200090.epw
     - ../../../weather/G2200110.epw
     - ../../../weather/G2200130.epw
     - ../../../weather/G2200150.epw
     - ../../../weather/G2200170.epw
     - ../../../weather/G2200190.epw
     - ../../../weather/G2200210.epw
     - ../../../weather/G2200230.epw
     - ../../../weather/G2200250.epw
     - ../../../weather/G2200270.epw
     - ../../../weather/G2200290.epw
     - ../../../weather/G2200310.epw
     - ../../../weather/G2200330.epw
     - ../../../weather/G2200350.epw
     - ../../../weather/G2200370.epw
     - ../../../weather/G2200390.epw
     - ../../../weather/G2200410.epw
     - ../../../weather/G2200430.epw
     - ../../../weather/G2200450.epw
     - ../../../weather/G2200470.epw
     - ../../../weather/G2200490.epw
     - ../../../weather/G2200530.epw
     - ../../../weather/G2200510.epw
     - ../../../weather/G2200590.epw
     - ../../../weather/G2200550.epw
     - ../../../weather/G2200570.epw
     - ../../../weather/G2200610.epw
     - ../../../weather/G2200630.epw
     - ../../../weather/G2200650.epw
     - ../../../weather/G2200670.epw
     - ../../../weather/G2200690.epw
     - ../../../weather/G2200710.epw
     - ../../../weather/G2200730.epw
     - ../../../weather/G2200750.epw
     - ../../../weather/G2200770.epw
     - ../../../weather/G2200790.epw
     - ../../../weather/G2200810.epw
     - ../../../weather/G2200830.epw
     - ../../../weather/G2200850.epw
     - ../../../weather/G2200870.epw
     - ../../../weather/G2200890.epw
     - ../../../weather/G2200910.epw
     - ../../../weather/G2200930.epw
     - ../../../weather/G2200950.epw
     - ../../../weather/G2200970.epw
     - ../../../weather/G2200990.epw
     - ../../../weather/G2201010.epw
     - ../../../weather/G2201030.epw
     - ../../../weather/G2201050.epw
     - ../../../weather/G2201070.epw
     - ../../../weather/G2201090.epw
     - ../../../weather/G2201110.epw
     - ../../../weather/G2201130.epw
     - ../../../weather/G2201150.epw
     - ../../../weather/G2201170.epw
     - ../../../weather/G2201190.epw
     - ../../../weather/G2201210.epw
     - ../../../weather/G2201230.epw
     - ../../../weather/G2201250.epw
     - ../../../weather/G2201270.epw
     - ../../../weather/G2500010.epw
     - ../../../weather/G2500030.epw
     - ../../../weather/G2500050.epw
     - ../../../weather/G2500070.epw
     - ../../../weather/G2500090.epw
     - ../../../weather/G2500110.epw
     - ../../../weather/G2500130.epw
     - ../../../weather/G2500150.epw
     - ../../../weather/G2500170.epw
     - ../../../weather/G2500190.epw
     - ../../../weather/G2500210.epw
     - ../../../weather/G2500230.epw
     - ../../../weather/G2500250.epw
     - ../../../weather/G2500270.epw
     - ../../../weather/G2400010.epw
     - ../../../weather/G2400030.epw
     - ../../../weather/G2405100.epw
     - ../../../weather/G2400050.epw
     - ../../../weather/G2400090.epw
     - ../../../weather/G2400110.epw
     - ../../../weather/G2400130.epw
     - ../../../weather/G2400150.epw
     - ../../../weather/G2400170.epw
     - ../../../weather/G2400190.epw
     - ../../../weather/G2400210.epw
     - ../../../weather/G2400230.epw
     - ../../../weather/G2400250.epw
     - ../../../weather/G2400270.epw
     - ../../../weather/G2400290.epw
     - ../../../weather/G2400310.epw
     - ../../../weather/G2400330.epw
     - ../../../weather/G2400350.epw
     - ../../../weather/G2400390.epw
     - ../../../weather/G2400370.epw
     - ../../../weather/G2400410.epw
     - ../../../weather/G2400430.epw
     - ../../../weather/G2400450.epw
     - ../../../weather/G2400470.epw
     - ../../../weather/G2300010.epw
     - ../../../weather/G2300030.epw
     - ../../../weather/G2300050.epw
     - ../../../weather/G2300070.epw
     - ../../../weather/G2300090.epw
     - ../../../weather/G2300110.epw
     - ../../../weather/G2300130.epw
     - ../../../weather/G2300150.epw
     - ../../../weather/G2300170.epw
     - ../../../weather/G2300190.epw
     - ../../../weather/G2300210.epw
     - ../../../weather/G2300230.epw
     - ../../../weather/G2300250.epw
     - ../../../weather/G2300270.epw
     - ../../../weather/G2300290.epw
     - ../../../weather/G2300310.epw
     - ../../../weather/G2600010.epw
     - ../../../weather/G2600030.epw
     - ../../../weather/G2600050.epw
     - ../../../weather/G2600070.epw
     - ../../../weather/G2600090.epw
     - ../../../weather/G2600110.epw
     - ../../../weather/G2600130.epw
     - ../../../weather/G2600150.epw
     - ../../../weather/G2600170.epw
     - ../../../weather/G2600190.epw
     - ../../../weather/G2600210.epw
     - ../../../weather/G2600230.epw
     - ../../../weather/G2600250.epw
     - ../../../weather/G2600270.epw
     - ../../../weather/G2600290.epw
     - ../../../weather/G2600310.epw
     - ../../../weather/G2600330.epw
     - ../../../weather/G2600350.epw
     - ../../../weather/G2600370.epw
     - ../../../weather/G2600390.epw
     - ../../../weather/G2600410.epw
     - ../../../weather/G2600430.epw
     - ../../../weather/G2600450.epw
     - ../../../weather/G2600470.epw
     - ../../../weather/G2600490.epw
     - ../../../weather/G2600510.epw
     - ../../../weather/G2600530.epw
     - ../../../weather/G2600550.epw
     - ../../../weather/G2600570.epw
     - ../../../weather/G2600590.epw
     - ../../../weather/G2600610.epw
     - ../../../weather/G2600630.epw
     - ../../../weather/G2600650.epw
     - ../../../weather/G2600670.epw
     - ../../../weather/G2600690.epw
     - ../../../weather/G2600710.epw
     - ../../../weather/G2600730.epw
     - ../../../weather/G2600750.epw
     - ../../../weather/G2600770.epw
     - ../../../weather/G2600790.epw
     - ../../../weather/G2600810.epw
     - ../../../weather/G2600830.epw
     - ../../../weather/G2600850.epw
     - ../../../weather/G2600870.epw
     - ../../../weather/G2600890.epw
     - ../../../weather/G2600910.epw
     - ../../../weather/G2600930.epw
     - ../../../weather/G2600950.epw
     - ../../../weather/G2600970.epw
     - ../../../weather/G2600990.epw
     - ../../../weather/G2601010.epw
     - ../../../weather/G2601030.epw
     - ../../../weather/G2601050.epw
     - ../../../weather/G2601070.epw
     - ../../../weather/G2601090.epw
     - ../../../weather/G2601110.epw
     - ../../../weather/G2601130.epw
     - ../../../weather/G2601150.epw
     - ../../../weather/G2601170.epw
     - ../../../weather/G2601190.epw
     - ../../../weather/G2601210.epw
     - ../../../weather/G2601230.epw
     - ../../../weather/G2601250.epw
     - ../../../weather/G2601270.epw
     - ../../../weather/G2601290.epw
     - ../../../weather/G2601310.epw
     - ../../../weather/G2601330.epw
     - ../../../weather/G2601350.epw
     - ../../../weather/G2601370.epw
     - ../../../weather/G2601390.epw
     - ../../../weather/G2601410.epw
     - ../../../weather/G2601430.epw
     - ../../../weather/G2601450.epw
     - ../../../weather/G2601510.epw
     - ../../../weather/G2601530.epw
     - ../../../weather/G2601550.epw
     - ../../../weather/G2601470.epw
     - ../../../weather/G2601490.epw
     - ../../../weather/G2601570.epw
     - ../../../weather/G2601590.epw
     - ../../../weather/G2601610.epw
     - ../../../weather/G2601630.epw
     - ../../../weather/G2601650.epw
     - ../../../weather/G2700010.epw
     - ../../../weather/G2700030.epw
     - ../../../weather/G2700050.epw
     - ../../../weather/G2700070.epw
     - ../../../weather/G2700090.epw
     - ../../../weather/G2700110.epw
     - ../../../weather/G2700130.epw
     - ../../../weather/G2700150.epw
     - ../../../weather/G2700170.epw
     - ../../../weather/G2700190.epw
     - ../../../weather/G2700210.epw
     - ../../../weather/G2700230.epw
     - ../../../weather/G2700250.epw
     - ../../../weather/G2700270.epw
     - ../../../weather/G2700290.epw
     - ../../../weather/G2700310.epw
     - ../../../weather/G2700330.epw
     - ../../../weather/G2700350.epw
     - ../../../weather/G2700370.epw
     - ../../../weather/G2700390.epw
     - ../../../weather/G2700410.epw
     - ../../../weather/G2700430.epw
     - ../../../weather/G2700450.epw
     - ../../../weather/G2700470.epw
     - ../../../weather/G2700490.epw
     - ../../../weather/G2700510.epw
     - ../../../weather/G2700530.epw
     - ../../../weather/G2700550.epw
     - ../../../weather/G2700570.epw
     - ../../../weather/G2700590.epw
     - ../../../weather/G2700610.epw
     - ../../../weather/G2700630.epw
     - ../../../weather/G2700650.epw
     - ../../../weather/G2700670.epw
     - ../../../weather/G2700690.epw
     - ../../../weather/G2700710.epw
     - ../../../weather/G2700730.epw
     - ../../../weather/G2700750.epw
     - ../../../weather/G2700770.epw
     - ../../../weather/G2700790.epw
     - ../../../weather/G2700810.epw
     - ../../../weather/G2700830.epw
     - ../../../weather/G2700870.epw
     - ../../../weather/G2700890.epw
     - ../../../weather/G2700910.epw
     - ../../../weather/G2700850.epw
     - ../../../weather/G2700930.epw
     - ../../../weather/G2700950.epw
     - ../../../weather/G2700970.epw
     - ../../../weather/G2700990.epw
     - ../../../weather/G2701010.epw
     - ../../../weather/G2701030.epw
     - ../../../weather/G2701050.epw
     - ../../../weather/G2701070.epw
     - ../../../weather/G2701090.epw
     - ../../../weather/G2701110.epw
     - ../../../weather/G2701130.epw
     - ../../../weather/G2701150.epw
     - ../../../weather/G2701170.epw
     - ../../../weather/G2701190.epw
     - ../../../weather/G2701210.epw
     - ../../../weather/G2701230.epw
     - ../../../weather/G2701250.epw
     - ../../../weather/G2701270.epw
     - ../../../weather/G2701290.epw
     - ../../../weather/G2701310.epw
     - ../../../weather/G2701330.epw
     - ../../../weather/G2701350.epw
     - ../../../weather/G2701390.epw
     - ../../../weather/G2701410.epw
     - ../../../weather/G2701430.epw
     - ../../../weather/G2701370.epw
     - ../../../weather/G2701450.epw
     - ../../../weather/G2701470.epw
     - ../../../weather/G2701490.epw
     - ../../../weather/G2701510.epw
     - ../../../weather/G2701530.epw
     - ../../../weather/G2701550.epw
     - ../../../weather/G2701570.epw
     - ../../../weather/G2701590.epw
     - ../../../weather/G2701610.epw
     - ../../../weather/G2701630.epw
     - ../../../weather/G2701650.epw
     - ../../../weather/G2701670.epw
     - ../../../weather/G2701690.epw
     - ../../../weather/G2701710.epw
     - ../../../weather/G2701730.epw
     - ../../../weather/G2900010.epw
     - ../../../weather/G2900030.epw
     - ../../../weather/G2900050.epw
     - ../../../weather/G2900070.epw
     - ../../../weather/G2900090.epw
     - ../../../weather/G2900110.epw
     - ../../../weather/G2900130.epw
     - ../../../weather/G2900150.epw
     - ../../../weather/G2900170.epw
     - ../../../weather/G2900190.epw
     - ../../../weather/G2900210.epw
     - ../../../weather/G2900230.epw
     - ../../../weather/G2900250.epw
     - ../../../weather/G2900270.epw
     - ../../../weather/G2900290.epw
     - ../../../weather/G2900310.epw
     - ../../../weather/G2900330.epw
     - ../../../weather/G2900350.epw
     - ../../../weather/G2900370.epw
     - ../../../weather/G2900390.epw
     - ../../../weather/G2900410.epw
     - ../../../weather/G2900430.epw
     - ../../../weather/G2900450.epw
     - ../../../weather/G2900470.epw
     - ../../../weather/G2900490.epw
     - ../../../weather/G2900510.epw
     - ../../../weather/G2900530.epw
     - ../../../weather/G2900550.epw
     - ../../../weather/G2900570.epw
     - ../../../weather/G2900590.epw
     - ../../../weather/G2900610.epw
     - ../../../weather/G2900630.epw
     - ../../../weather/G2900650.epw
     - ../../../weather/G2900670.epw
     - ../../../weather/G2900690.epw
     - ../../../weather/G2900710.epw
     - ../../../weather/G2900730.epw
     - ../../../weather/G2900750.epw
     - ../../../weather/G2900770.epw
     - ../../../weather/G2900790.epw
     - ../../../weather/G2900810.epw
     - ../../../weather/G2900830.epw
     - ../../../weather/G2900850.epw
     - ../../../weather/G2900870.epw
     - ../../../weather/G2900890.epw
     - ../../../weather/G2900910.epw
     - ../../../weather/G2900930.epw
     - ../../../weather/G2900950.epw
     - ../../../weather/G2900970.epw
     - ../../../weather/G2900990.epw
     - ../../../weather/G2901010.epw
     - ../../../weather/G2901030.epw
     - ../../../weather/G2901050.epw
     - ../../../weather/G2901070.epw
     - ../../../weather/G2901090.epw
     - ../../../weather/G2901110.epw
     - ../../../weather/G2901130.epw
     - ../../../weather/G2901150.epw
     - ../../../weather/G2901170.epw
     - ../../../weather/G2901210.epw
     - ../../../weather/G2901230.epw
     - ../../../weather/G2901250.epw
     - ../../../weather/G2901270.epw
     - ../../../weather/G2901190.epw
     - ../../../weather/G2901290.epw
     - ../../../weather/G2901310.epw
     - ../../../weather/G2901330.epw
     - ../../../weather/G2901350.epw
     - ../../../weather/G2901370.epw
     - ../../../weather/G2901390.epw
     - ../../../weather/G2901410.epw
     - ../../../weather/G2901430.epw
     - ../../../weather/G2901450.epw
     - ../../../weather/G2901470.epw
     - ../../../weather/G2901490.epw
     - ../../../weather/G2901510.epw
     - ../../../weather/G2901530.epw
     - ../../../weather/G2901550.epw
     - ../../../weather/G2901570.epw
     - ../../../weather/G2901590.epw
     - ../../../weather/G2901610.epw
     - ../../../weather/G2901630.epw
     - ../../../weather/G2901650.epw
     - ../../../weather/G2901670.epw
     - ../../../weather/G2901690.epw
     - ../../../weather/G2901710.epw
     - ../../../weather/G2901730.epw
     - ../../../weather/G2901750.epw
     - ../../../weather/G2901770.epw
     - ../../../weather/G2901790.epw
     - ../../../weather/G2901810.epw
     - ../../../weather/G2901950.epw
     - ../../../weather/G2901970.epw
     - ../../../weather/G2901990.epw
     - ../../../weather/G2902010.epw
     - ../../../weather/G2902030.epw
     - ../../../weather/G2902050.epw
     - ../../../weather/G2901830.epw
     - ../../../weather/G2901850.epw
     - ../../../weather/G2901870.epw
     - ../../../weather/G2905100.epw
     - ../../../weather/G2901890.epw
     - ../../../weather/G2901860.epw
     - ../../../weather/G2902070.epw
     - ../../../weather/G2902090.epw
     - ../../../weather/G2902110.epw
     - ../../../weather/G2902130.epw
     - ../../../weather/G2902150.epw
     - ../../../weather/G2902170.epw
     - ../../../weather/G2902190.epw
     - ../../../weather/G2902210.epw
     - ../../../weather/G2902230.epw
     - ../../../weather/G2902250.epw
     - ../../../weather/G2902270.epw
     - ../../../weather/G2902290.epw
     - ../../../weather/G2800010.epw
     - ../../../weather/G2800030.epw
     - ../../../weather/G2800050.epw
     - ../../../weather/G2800070.epw
     - ../../../weather/G2800090.epw
     - ../../../weather/G2800110.epw
     - ../../../weather/G2800130.epw
     - ../../../weather/G2800150.epw
     - ../../../weather/G2800170.epw
     - ../../../weather/G2800190.epw
     - ../../../weather/G2800210.epw
     - ../../../weather/G2800230.epw
     - ../../../weather/G2800250.epw
     - ../../../weather/G2800270.epw
     - ../../../weather/G2800290.epw
     - ../../../weather/G2800310.epw
     - ../../../weather/G2800330.epw
     - ../../../weather/G2800350.epw
     - ../../../weather/G2800370.epw
     - ../../../weather/G2800390.epw
     - ../../../weather/G2800410.epw
     - ../../../weather/G2800430.epw
     - ../../../weather/G2800450.epw
     - ../../../weather/G2800470.epw
     - ../../../weather/G2800490.epw
     - ../../../weather/G2800510.epw
     - ../../../weather/G2800530.epw
     - ../../../weather/G2800550.epw
     - ../../../weather/G2800570.epw
     - ../../../weather/G2800590.epw
     - ../../../weather/G2800610.epw
     - ../../../weather/G2800630.epw
     - ../../../weather/G2800650.epw
     - ../../../weather/G2800670.epw
     - ../../../weather/G2800690.epw
     - ../../../weather/G2800710.epw
     - ../../../weather/G2800730.epw
     - ../../../weather/G2800750.epw
     - ../../../weather/G2800770.epw
     - ../../../weather/G2800790.epw
     - ../../../weather/G2800810.epw
     - ../../../weather/G2800830.epw
     - ../../../weather/G2800850.epw
     - ../../../weather/G2800870.epw
     - ../../../weather/G2800890.epw
     - ../../../weather/G2800910.epw
     - ../../../weather/G2800930.epw
     - ../../../weather/G2800950.epw
     - ../../../weather/G2800970.epw
     - ../../../weather/G2800990.epw
     - ../../../weather/G2801010.epw
     - ../../../weather/G2801030.epw
     - ../../../weather/G2801050.epw
     - ../../../weather/G2801070.epw
     - ../../../weather/G2801090.epw
     - ../../../weather/G2801110.epw
     - ../../../weather/G2801130.epw
     - ../../../weather/G2801150.epw
     - ../../../weather/G2801170.epw
     - ../../../weather/G2801190.epw
     - ../../../weather/G2801210.epw
     - ../../../weather/G2801230.epw
     - ../../../weather/G2801250.epw
     - ../../../weather/G2801270.epw
     - ../../../weather/G2801290.epw
     - ../../../weather/G2801310.epw
     - ../../../weather/G2801330.epw
     - ../../../weather/G2801350.epw
     - ../../../weather/G2801370.epw
     - ../../../weather/G2801390.epw
     - ../../../weather/G2801410.epw
     - ../../../weather/G2801430.epw
     - ../../../weather/G2801450.epw
     - ../../../weather/G2801470.epw
     - ../../../weather/G2801490.epw
     - ../../../weather/G2801510.epw
     - ../../../weather/G2801530.epw
     - ../../../weather/G2801550.epw
     - ../../../weather/G2801570.epw
     - ../../../weather/G2801590.epw
     - ../../../weather/G2801610.epw
     - ../../../weather/G2801630.epw
     - ../../../weather/G3000010.epw
     - ../../../weather/G3000030.epw
     - ../../../weather/G3000050.epw
     - ../../../weather/G3000070.epw
     - ../../../weather/G3000090.epw
     - ../../../weather/G3000110.epw
     - ../../../weather/G3000130.epw
     - ../../../weather/G3000150.epw
     - ../../../weather/G3000170.epw
     - ../../../weather/G3000190.epw
     - ../../../weather/G3000210.epw
     - ../../../weather/G3000230.epw
     - ../../../weather/G3000250.epw
     - ../../../weather/G3000270.epw
     - ../../../weather/G3000290.epw
     - ../../../weather/G3000310.epw
     - ../../../weather/G3000330.epw
     - ../../../weather/G3000350.epw
     - ../../../weather/G3000370.epw
     - ../../../weather/G3000390.epw
     - ../../../weather/G3000410.epw
     - ../../../weather/G3000430.epw
     - ../../../weather/G3000450.epw
     - ../../../weather/G3000470.epw
     - ../../../weather/G3000490.epw
     - ../../../weather/G3000510.epw
     - ../../../weather/G3000530.epw
     - ../../../weather/G3000570.epw
     - ../../../weather/G3000550.epw
     - ../../../weather/G3000590.epw
     - ../../../weather/G3000610.epw
     - ../../../weather/G3000630.epw
     - ../../../weather/G3000650.epw
     - ../../../weather/G3000670.epw
     - ../../../weather/G3000690.epw
     - ../../../weather/G3000710.epw
     - ../../../weather/G3000730.epw
     - ../../../weather/G3000750.epw
     - ../../../weather/G3000770.epw
     - ../../../weather/G3000790.epw
     - ../../../weather/G3000810.epw
     - ../../../weather/G3000830.epw
     - ../../../weather/G3000850.epw
     - ../../../weather/G3000870.epw
     - ../../../weather/G3000890.epw
     - ../../../weather/G3000910.epw
     - ../../../weather/G3000930.epw
     - ../../../weather/G3000950.epw
     - ../../../weather/G3000970.epw
     - ../../../weather/G3000990.epw
     - ../../../weather/G3001010.epw
     - ../../../weather/G3001030.epw
     - ../../../weather/G3001050.epw
     - ../../../weather/G3001070.epw
     - ../../../weather/G3001090.epw
     - ../../../weather/G3001110.epw
     - ../../../weather/G3700010.epw
     - ../../../weather/G3700030.epw
     - ../../../weather/G3700050.epw
     - ../../../weather/G3700070.epw
     - ../../../weather/G3700090.epw
     - ../../../weather/G3700110.epw
     - ../../../weather/G3700130.epw
     - ../../../weather/G3700150.epw
     - ../../../weather/G3700170.epw
     - ../../../weather/G3700190.epw
     - ../../../weather/G3700210.epw
     - ../../../weather/G3700230.epw
     - ../../../weather/G3700250.epw
     - ../../../weather/G3700270.epw
     - ../../../weather/G3700290.epw
     - ../../../weather/G3700310.epw
     - ../../../weather/G3700330.epw
     - ../../../weather/G3700350.epw
     - ../../../weather/G3700370.epw
     - ../../../weather/G3700390.epw
     - ../../../weather/G3700410.epw
     - ../../../weather/G3700430.epw
     - ../../../weather/G3700450.epw
     - ../../../weather/G3700470.epw
     - ../../../weather/G3700490.epw
     - ../../../weather/G3700510.epw
     - ../../../weather/G3700530.epw
     - ../../../weather/G3700550.epw
     - ../../../weather/G3700570.epw
     - ../../../weather/G3700590.epw
     - ../../../weather/G3700610.epw
     - ../../../weather/G3700630.epw
     - ../../../weather/G3700650.epw
     - ../../../weather/G3700670.epw
     - ../../../weather/G3700690.epw
     - ../../../weather/G3700710.epw
     - ../../../weather/G3700730.epw
     - ../../../weather/G3700750.epw
     - ../../../weather/G3700770.epw
     - ../../../weather/G3700790.epw
     - ../../../weather/G3700810.epw
     - ../../../weather/G3700830.epw
     - ../../../weather/G3700850.epw
     - ../../../weather/G3700870.epw
     - ../../../weather/G3700890.epw
     - ../../../weather/G3700910.epw
     - ../../../weather/G3700930.epw
     - ../../../weather/G3700950.epw
     - ../../../weather/G3700970.epw
     - ../../../weather/G3700990.epw
     - ../../../weather/G3701010.epw
     - ../../../weather/G3701030.epw
     - ../../../weather/G3701050.epw
     - ../../../weather/G3701070.epw
     - ../../../weather/G3701090.epw
     - ../../../weather/G3701130.epw
     - ../../../weather/G3701150.epw
     - ../../../weather/G3701170.epw
     - ../../../weather/G3701110.epw
     - ../../../weather/G3701190.epw
     - ../../../weather/G3701210.epw
     - ../../../weather/G3701230.epw
     - ../../../weather/G3701250.epw
     - ../../../weather/G3701270.epw
     - ../../../weather/G3701290.epw
     - ../../../weather/G3701310.epw
     - ../../../weather/G3701330.epw
     - ../../../weather/G3701350.epw
     - ../../../weather/G3701370.epw
     - ../../../weather/G3701390.epw
     - ../../../weather/G3701410.epw
     - ../../../weather/G3701430.epw
     - ../../../weather/G3701450.epw
     - ../../../weather/G3701470.epw
     - ../../../weather/G3701490.epw
     - ../../../weather/G3701510.epw
     - ../../../weather/G3701530.epw
     - ../../../weather/G3701550.epw
     - ../../../weather/G3701570.epw
     - ../../../weather/G3701590.epw
     - ../../../weather/G3701610.epw
     - ../../../weather/G3701630.epw
     - ../../../weather/G3701650.epw
     - ../../../weather/G3701670.epw
     - ../../../weather/G3701690.epw
     - ../../../weather/G3701710.epw
     - ../../../weather/G3701730.epw
     - ../../../weather/G3701750.epw
     - ../../../weather/G3701770.epw
     - ../../../weather/G3701790.epw
     - ../../../weather/G3701810.epw
     - ../../../weather/G3701830.epw
     - ../../../weather/G3701850.epw
     - ../../../weather/G3701870.epw
     - ../../../weather/G3701890.epw
     - ../../../weather/G3701910.epw
     - ../../../weather/G3701930.epw
     - ../../../weather/G3701950.epw
     - ../../../weather/G3701970.epw
     - ../../../weather/G3701990.epw
     - ../../../weather/G3800010.epw
     - ../../../weather/G3800030.epw
     - ../../../weather/G3800050.epw
     - ../../../weather/G3800070.epw
     - ../../../weather/G3800090.epw
     - ../../../weather/G3800110.epw
     - ../../../weather/G3800130.epw
     - ../../../weather/G3800150.epw
     - ../../../weather/G3800170.epw
     - ../../../weather/G3800190.epw
     - ../../../weather/G3800210.epw
     - ../../../weather/G3800230.epw
     - ../../../weather/G3800250.epw
     - ../../../weather/G3800270.epw
     - ../../../weather/G3800290.epw
     - ../../../weather/G3800310.epw
     - ../../../weather/G3800330.epw
     - ../../../weather/G3800350.epw
     - ../../../weather/G3800370.epw
     - ../../../weather/G3800390.epw
     - ../../../weather/G3800410.epw
     - ../../../weather/G3800430.epw
     - ../../../weather/G3800450.epw
     - ../../../weather/G3800470.epw
     - ../../../weather/G3800490.epw
     - ../../../weather/G3800510.epw
     - ../../../weather/G3800530.epw
     - ../../../weather/G3800550.epw
     - ../../../weather/G3800570.epw
     - ../../../weather/G3800590.epw
     - ../../../weather/G3800610.epw
     - ../../../weather/G3800630.epw
     - ../../../weather/G3800650.epw
     - ../../../weather/G3800670.epw
     - ../../../weather/G3800690.epw
     - ../../../weather/G3800710.epw
     - ../../../weather/G3800730.epw
     - ../../../weather/G3800750.epw
     - ../../../weather/G3800770.epw
     - ../../../weather/G3800790.epw
     - ../../../weather/G3800810.epw
     - ../../../weather/G3800830.epw
     - ../../../weather/G3800850.epw
     - ../../../weather/G3800870.epw
     - ../../../weather/G3800890.epw
     - ../../../weather/G3800910.epw
     - ../../../weather/G3800930.epw
     - ../../../weather/G3800950.epw
     - ../../../weather/G3800970.epw
     - ../../../weather/G3800990.epw
     - ../../../weather/G3801010.epw
     - ../../../weather/G3801030.epw
     - ../../../weather/G3801050.epw
     - ../../../weather/G3100010.epw
     - ../../../weather/G3100030.epw
     - ../../../weather/G3100050.epw
     - ../../../weather/G3100070.epw
     - ../../../weather/G3100090.epw
     - ../../../weather/G3100110.epw
     - ../../../weather/G3100130.epw
     - ../../../weather/G3100150.epw
     - ../../../weather/G3100170.epw
     - ../../../weather/G3100190.epw
     - ../../../weather/G3100210.epw
     - ../../../weather/G3100230.epw
     - ../../../weather/G3100250.epw
     - ../../../weather/G3100270.epw
     - ../../../weather/G3100290.epw
     - ../../../weather/G3100310.epw
     - ../../../weather/G3100330.epw
     - ../../../weather/G3100350.epw
     - ../../../weather/G3100370.epw
     - ../../../weather/G3100390.epw
     - ../../../weather/G3100410.epw
     - ../../../weather/G3100430.epw
     - ../../../weather/G3100450.epw
     - ../../../weather/G3100470.epw
     - ../../../weather/G3100490.epw
     - ../../../weather/G3100510.epw
     - ../../../weather/G3100530.epw
     - ../../../weather/G3100550.epw
     - ../../../weather/G3100570.epw
     - ../../../weather/G3100590.epw
     - ../../../weather/G3100610.epw
     - ../../../weather/G3100630.epw
     - ../../../weather/G3100650.epw
     - ../../../weather/G3100670.epw
     - ../../../weather/G3100690.epw
     - ../../../weather/G3100710.epw
     - ../../../weather/G3100730.epw
     - ../../../weather/G3100750.epw
     - ../../../weather/G3100770.epw
     - ../../../weather/G3100790.epw
     - ../../../weather/G3100810.epw
     - ../../../weather/G3100830.epw
     - ../../../weather/G3100850.epw
     - ../../../weather/G3100870.epw
     - ../../../weather/G3100890.epw
     - ../../../weather/G3100910.epw
     - ../../../weather/G3100930.epw
     - ../../../weather/G3100950.epw
     - ../../../weather/G3100970.epw
     - ../../../weather/G3100990.epw
     - ../../../weather/G3101010.epw
     - ../../../weather/G3101030.epw
     - ../../../weather/G3101050.epw
     - ../../../weather/G3101070.epw
     - ../../../weather/G3101090.epw
     - ../../../weather/G3101110.epw
     - ../../../weather/G3101130.epw
     - ../../../weather/G3101150.epw
     - ../../../weather/G3101190.epw
     - ../../../weather/G3101170.epw
     - ../../../weather/G3101210.epw
     - ../../../weather/G3101230.epw
     - ../../../weather/G3101250.epw
     - ../../../weather/G3101270.epw
     - ../../../weather/G3101290.epw
     - ../../../weather/G3101310.epw
     - ../../../weather/G3101330.epw
     - ../../../weather/G3101350.epw
     - ../../../weather/G3101370.epw
     - ../../../weather/G3101390.epw
     - ../../../weather/G3101410.epw
     - ../../../weather/G3101430.epw
     - ../../../weather/G3101450.epw
     - ../../../weather/G3101470.epw
     - ../../../weather/G3101490.epw
     - ../../../weather/G3101510.epw
     - ../../../weather/G3101530.epw
     - ../../../weather/G3101550.epw
     - ../../../weather/G3101570.epw
     - ../../../weather/G3101590.epw
     - ../../../weather/G3101610.epw
     - ../../../weather/G3101630.epw
     - ../../../weather/G3101650.epw
     - ../../../weather/G3101670.epw
     - ../../../weather/G3101690.epw
     - ../../../weather/G3101710.epw
     - ../../../weather/G3101730.epw
     - ../../../weather/G3101750.epw
     - ../../../weather/G3101770.epw
     - ../../../weather/G3101790.epw
     - ../../../weather/G3101810.epw
     - ../../../weather/G3101830.epw
     - ../../../weather/G3101850.epw
     - ../../../weather/G3300010.epw
     - ../../../weather/G3300030.epw
     - ../../../weather/G3300050.epw
     - ../../../weather/G3300070.epw
     - ../../../weather/G3300090.epw
     - ../../../weather/G3300110.epw
     - ../../../weather/G3300130.epw
     - ../../../weather/G3300150.epw
     - ../../../weather/G3300170.epw
     - ../../../weather/G3300190.epw
     - ../../../weather/G3400010.epw
     - ../../../weather/G3400030.epw
     - ../../../weather/G3400050.epw
     - ../../../weather/G3400070.epw
     - ../../../weather/G3400090.epw
     - ../../../weather/G3400110.epw
     - ../../../weather/G3400130.epw
     - ../../../weather/G3400150.epw
     - ../../../weather/G3400170.epw
     - ../../../weather/G3400190.epw
     - ../../../weather/G3400210.epw
     - ../../../weather/G3400230.epw
     - ../../../weather/G3400250.epw
     - ../../../weather/G3400270.epw
     - ../../../weather/G3400290.epw
     - ../../../weather/G3400310.epw
     - ../../../weather/G3400330.epw
     - ../../../weather/G3400350.epw
     - ../../../weather/G3400370.epw
     - ../../../weather/G3400390.epw
     - ../../../weather/G3400410.epw
     - ../../../weather/G3500010.epw
     - ../../../weather/G3500030.epw
     - ../../../weather/G3500050.epw
     - ../../../weather/G3500060.epw
     - ../../../weather/G3500070.epw
     - ../../../weather/G3500090.epw
     - ../../../weather/G3500110.epw
     - ../../../weather/G3500130.epw
     - ../../../weather/G3500150.epw
     - ../../../weather/G3500170.epw
     - ../../../weather/G3500190.epw
     - ../../../weather/G3500210.epw
     - ../../../weather/G3500230.epw
     - ../../../weather/G3500250.epw
     - ../../../weather/G3500270.epw
     - ../../../weather/G3500280.epw
     - ../../../weather/G3500290.epw
     - ../../../weather/G3500310.epw
     - ../../../weather/G3500330.epw
     - ../../../weather/G3500350.epw
     - ../../../weather/G3500370.epw
     - ../../../weather/G3500390.epw
     - ../../../weather/G3500410.epw
     - ../../../weather/G3500450.epw
     - ../../../weather/G3500470.epw
     - ../../../weather/G3500430.epw
     - ../../../weather/G3500490.epw
     - ../../../weather/G3500510.epw
     - ../../../weather/G3500530.epw
     - ../../../weather/G3500550.epw
     - ../../../weather/G3500570.epw
     - ../../../weather/G3500590.epw
     - ../../../weather/G3500610.epw
     - ../../../weather/G3205100.epw
     - ../../../weather/G3200010.epw
     - ../../../weather/G3200030.epw
     - ../../../weather/G3200050.epw
     - ../../../weather/G3200070.epw
     - ../../../weather/G3200090.epw
     - ../../../weather/G3200110.epw
     - ../../../weather/G3200130.epw
     - ../../../weather/G3200150.epw
     - ../../../weather/G3200170.epw
     - ../../../weather/G3200190.epw
     - ../../../weather/G3200210.epw
     - ../../../weather/G3200230.epw
     - ../../../weather/G3200270.epw
     - ../../../weather/G3200290.epw
     - ../../../weather/G3200310.epw
     - ../../../weather/G3200330.epw
     - ../../../weather/G3600010.epw
     - ../../../weather/G3600030.epw
     - ../../../weather/G3600050.epw
     - ../../../weather/G3600070.epw
     - ../../../weather/G3600090.epw
     - ../../../weather/G3600110.epw
     - ../../../weather/G3600130.epw
     - ../../../weather/G3600150.epw
     - ../../../weather/G3600170.epw
     - ../../../weather/G3600190.epw
     - ../../../weather/G3600210.epw
     - ../../../weather/G3600230.epw
     - ../../../weather/G3600250.epw
     - ../../../weather/G3600270.epw
     - ../../../weather/G3600290.epw
     - ../../../weather/G3600310.epw
     - ../../../weather/G3600330.epw
     - ../../../weather/G3600350.epw
     - ../../../weather/G3600370.epw
     - ../../../weather/G3600390.epw
     - ../../../weather/G3600410.epw
     - ../../../weather/G3600430.epw
     - ../../../weather/G3600450.epw
     - ../../../weather/G3600470.epw
     - ../../../weather/G3600490.epw
     - ../../../weather/G3600510.epw
     - ../../../weather/G3600530.epw
     - ../../../weather/G3600550.epw
     - ../../../weather/G3600570.epw
     - ../../../weather/G3600590.epw
     - ../../../weather/G3600610.epw
     - ../../../weather/G3600630.epw
     - ../../../weather/G3600650.epw
     - ../../../weather/G3600670.epw
     - ../../../weather/G3600690.epw
     - ../../../weather/G3600710.epw
     - ../../../weather/G3600730.epw
     - ../../../weather/G3600750.epw
     - ../../../weather/G3600770.epw
     - ../../../weather/G3600790.epw
     - ../../../weather/G3600810.epw
     - ../../../weather/G3600830.epw
     - ../../../weather/G3600850.epw
     - ../../../weather/G3600870.epw
     - ../../../weather/G3600910.epw
     - ../../../weather/G3600930.epw
     - ../../../weather/G3600950.epw
     - ../../../weather/G3600970.epw
     - ../../../weather/G3600990.epw
     - ../../../weather/G3600890.epw
     - ../../../weather/G3601010.epw
     - ../../../weather/G3601030.epw
     - ../../../weather/G3601050.epw
     - ../../../weather/G3601070.epw
     - ../../../weather/G3601090.epw
     - ../../../weather/G3601110.epw
     - ../../../weather/G3601130.epw
     - ../../../weather/G3601150.epw
     - ../../../weather/G3601170.epw
     - ../../../weather/G3601190.epw
     - ../../../weather/G3601210.epw
     - ../../../weather/G3601230.epw
     - ../../../weather/G3900010.epw
     - ../../../weather/G3900030.epw
     - ../../../weather/G3900050.epw
     - ../../../weather/G3900070.epw
     - ../../../weather/G3900090.epw
     - ../../../weather/G3900110.epw
     - ../../../weather/G3900130.epw
     - ../../../weather/G3900150.epw
     - ../../../weather/G3900170.epw
     - ../../../weather/G3900190.epw
     - ../../../weather/G3900210.epw
     - ../../../weather/G3900230.epw
     - ../../../weather/G3900250.epw
     - ../../../weather/G3900270.epw
     - ../../../weather/G3900290.epw
     - ../../../weather/G3900310.epw
     - ../../../weather/G3900330.epw
     - ../../../weather/G3900350.epw
     - ../../../weather/G3900370.epw
     - ../../../weather/G3900390.epw
     - ../../../weather/G3900410.epw
     - ../../../weather/G3900430.epw
     - ../../../weather/G3900450.epw
     - ../../../weather/G3900470.epw
     - ../../../weather/G3900490.epw
     - ../../../weather/G3900510.epw
     - ../../../weather/G3900530.epw
     - ../../../weather/G3900550.epw
     - ../../../weather/G3900570.epw
     - ../../../weather/G3900590.epw
     - ../../../weather/G3900610.epw
     - ../../../weather/G3900630.epw
     - ../../../weather/G3900650.epw
     - ../../../weather/G3900670.epw
     - ../../../weather/G3900690.epw
     - ../../../weather/G3900710.epw
     - ../../../weather/G3900730.epw
     - ../../../weather/G3900750.epw
     - ../../../weather/G3900770.epw
     - ../../../weather/G3900790.epw
     - ../../../weather/G3900810.epw
     - ../../../weather/G3900830.epw
     - ../../../weather/G3900850.epw
     - ../../../weather/G3900870.epw
     - ../../../weather/G3900890.epw
     - ../../../weather/G3900910.epw
     - ../../../weather/G3900930.epw
     - ../../../weather/G3900950.epw
     - ../../../weather/G3900970.epw
     - ../../../weather/G3900990.epw
     - ../../../weather/G3901010.epw
     - ../../../weather/G3901030.epw
     - ../../../weather/G3901050.epw
     - ../../../weather/G3901070.epw
     - ../../../weather/G3901090.epw
     - ../../../weather/G3901110.epw
     - ../../../weather/G3901130.epw
     - ../../../weather/G3901150.epw
     - ../../../weather/G3901170.epw
     - ../../../weather/G3901190.epw
     - ../../../weather/G3901210.epw
     - ../../../weather/G3901230.epw
     - ../../../weather/G3901250.epw
     - ../../../weather/G3901270.epw
     - ../../../weather/G3901290.epw
     - ../../../weather/G3901310.epw
     - ../../../weather/G3901330.epw
     - ../../../weather/G3901350.epw
     - ../../../weather/G3901370.epw
     - ../../../weather/G3901390.epw
     - ../../../weather/G3901410.epw
     - ../../../weather/G3901430.epw
     - ../../../weather/G3901450.epw
     - ../../../weather/G3901470.epw
     - ../../../weather/G3901490.epw
     - ../../../weather/G3901510.epw
     - ../../../weather/G3901530.epw
     - ../../../weather/G3901550.epw
     - ../../../weather/G3901570.epw
     - ../../../weather/G3901590.epw
     - ../../../weather/G3901610.epw
     - ../../../weather/G3901630.epw
     - ../../../weather/G3901650.epw
     - ../../../weather/G3901670.epw
     - ../../../weather/G3901690.epw
     - ../../../weather/G3901710.epw
     - ../../../weather/G3901730.epw
     - ../../../weather/G3901750.epw
     - ../../../weather/G4000010.epw
     - ../../../weather/G4000030.epw
     - ../../../weather/G4000050.epw
     - ../../../weather/G4000070.epw
     - ../../../weather/G4000090.epw
     - ../../../weather/G4000110.epw
     - ../../../weather/G4000130.epw
     - ../../../weather/G4000150.epw
     - ../../../weather/G4000170.epw
     - ../../../weather/G4000190.epw
     - ../../../weather/G4000210.epw
     - ../../../weather/G4000230.epw
     - ../../../weather/G4000250.epw
     - ../../../weather/G4000270.epw
     - ../../../weather/G4000290.epw
     - ../../../weather/G4000310.epw
     - ../../../weather/G4000330.epw
     - ../../../weather/G4000350.epw
     - ../../../weather/G4000370.epw
     - ../../../weather/G4000390.epw
     - ../../../weather/G4000410.epw
     - ../../../weather/G4000430.epw
     - ../../../weather/G4000450.epw
     - ../../../weather/G4000470.epw
     - ../../../weather/G4000490.epw
     - ../../../weather/G4000510.epw
     - ../../../weather/G4000530.epw
     - ../../../weather/G4000550.epw
     - ../../../weather/G4000570.epw
     - ../../../weather/G4000590.epw
     - ../../../weather/G4000610.epw
     - ../../../weather/G4000630.epw
     - ../../../weather/G4000650.epw
     - ../../../weather/G4000670.epw
     - ../../../weather/G4000690.epw
     - ../../../weather/G4000710.epw
     - ../../../weather/G4000730.epw
     - ../../../weather/G4000750.epw
     - ../../../weather/G4000770.epw
     - ../../../weather/G4000790.epw
     - ../../../weather/G4000810.epw
     - ../../../weather/G4000830.epw
     - ../../../weather/G4000850.epw
     - ../../../weather/G4000930.epw
     - ../../../weather/G4000950.epw
     - ../../../weather/G4000970.epw
     - ../../../weather/G4000870.epw
     - ../../../weather/G4000890.epw
     - ../../../weather/G4000910.epw
     - ../../../weather/G4000990.epw
     - ../../../weather/G4001010.epw
     - ../../../weather/G4001030.epw
     - ../../../weather/G4001050.epw
     - ../../../weather/G4001070.epw
     - ../../../weather/G4001090.epw
     - ../../../weather/G4001110.epw
     - ../../../weather/G4001130.epw
     - ../../../weather/G4001150.epw
     - ../../../weather/G4001170.epw
     - ../../../weather/G4001190.epw
     - ../../../weather/G4001210.epw
     - ../../../weather/G4001230.epw
     - ../../../weather/G4001250.epw
     - ../../../weather/G4001270.epw
     - ../../../weather/G4001290.epw
     - ../../../weather/G4001310.epw
     - ../../../weather/G4001330.epw
     - ../../../weather/G4001350.epw
     - ../../../weather/G4001370.epw
     - ../../../weather/G4001390.epw
     - ../../../weather/G4001410.epw
     - ../../../weather/G4001430.epw
     - ../../../weather/G4001450.epw
     - ../../../weather/G4001470.epw
     - ../../../weather/G4001490.epw
     - ../../../weather/G4001510.epw
     - ../../../weather/G4001530.epw
     - ../../../weather/G4100010.epw
     - ../../../weather/G4100030.epw
     - ../../../weather/G4100050.epw
     - ../../../weather/G4100070.epw
     - ../../../weather/G4100090.epw
     - ../../../weather/G4100110.epw
     - ../../../weather/G4100130.epw
     - ../../../weather/G4100150.epw
     - ../../../weather/G4100170.epw
     - ../../../weather/G4100190.epw
     - ../../../weather/G4100210.epw
     - ../../../weather/G4100230.epw
     - ../../../weather/G4100250.epw
     - ../../../weather/G4100270.epw
     - ../../../weather/G4100290.epw
     - ../../../weather/G4100310.epw
     - ../../../weather/G4100330.epw
     - ../../../weather/G4100350.epw
     - ../../../weather/G4100370.epw
     - ../../../weather/G4100390.epw
     - ../../../weather/G4100410.epw
     - ../../../weather/G4100430.epw
     - ../../../weather/G4100450.epw
     - ../../../weather/G4100470.epw
     - ../../../weather/G4100490.epw
     - ../../../weather/G4100510.epw
     - ../../../weather/G4100530.epw
     - ../../../weather/G4100550.epw
     - ../../../weather/G4100570.epw
     - ../../../weather/G4100590.epw
     - ../../../weather/G4100610.epw
     - ../../../weather/G4100630.epw
     - ../../../weather/G4100650.epw
     - ../../../weather/G4100670.epw
     - ../../../weather/G4100690.epw
     - ../../../weather/G4100710.epw
     - ../../../weather/G4200010.epw
     - ../../../weather/G4200030.epw
     - ../../../weather/G4200050.epw
     - ../../../weather/G4200070.epw
     - ../../../weather/G4200090.epw
     - ../../../weather/G4200110.epw
     - ../../../weather/G4200130.epw
     - ../../../weather/G4200150.epw
     - ../../../weather/G4200170.epw
     - ../../../weather/G4200190.epw
     - ../../../weather/G4200210.epw
     - ../../../weather/G4200230.epw
     - ../../../weather/G4200250.epw
     - ../../../weather/G4200270.epw
     - ../../../weather/G4200290.epw
     - ../../../weather/G4200310.epw
     - ../../../weather/G4200330.epw
     - ../../../weather/G4200350.epw
     - ../../../weather/G4200370.epw
     - ../../../weather/G4200390.epw
     - ../../../weather/G4200410.epw
     - ../../../weather/G4200430.epw
     - ../../../weather/G4200450.epw
     - ../../../weather/G4200470.epw
     - ../../../weather/G4200490.epw
     - ../../../weather/G4200510.epw
     - ../../../weather/G4200530.epw
     - ../../../weather/G4200550.epw
     - ../../../weather/G4200570.epw
     - ../../../weather/G4200590.epw
     - ../../../weather/G4200610.epw
     - ../../../weather/G4200630.epw
     - ../../../weather/G4200650.epw
     - ../../../weather/G4200670.epw
     - ../../../weather/G4200690.epw
     - ../../../weather/G4200710.epw
     - ../../../weather/G4200730.epw
     - ../../../weather/G4200750.epw
     - ../../../weather/G4200770.epw
     - ../../../weather/G4200790.epw
     - ../../../weather/G4200810.epw
     - ../../../weather/G4200830.epw
     - ../../../weather/G4200850.epw
     - ../../../weather/G4200870.epw
     - ../../../weather/G4200890.epw
     - ../../../weather/G4200910.epw
     - ../../../weather/G4200930.epw
     - ../../../weather/G4200950.epw
     - ../../../weather/G4200970.epw
     - ../../../weather/G4200990.epw
     - ../../../weather/G4201010.epw
     - ../../../weather/G4201030.epw
     - ../../../weather/G4201050.epw
     - ../../../weather/G4201070.epw
     - ../../../weather/G4201090.epw
     - ../../../weather/G4201110.epw
     - ../../../weather/G4201130.epw
     - ../../../weather/G4201150.epw
     - ../../../weather/G4201170.epw
     - ../../../weather/G4201190.epw
     - ../../../weather/G4201210.epw
     - ../../../weather/G4201230.epw
     - ../../../weather/G4201250.epw
     - ../../../weather/G4201270.epw
     - ../../../weather/G4201290.epw
     - ../../../weather/G4201310.epw
     - ../../../weather/G4201330.epw
     - ../../../weather/G4400010.epw
     - ../../../weather/G4400030.epw
     - ../../../weather/G4400050.epw
     - ../../../weather/G4400070.epw
     - ../../../weather/G4400090.epw
     - ../../../weather/G4500010.epw
     - ../../../weather/G4500030.epw
     - ../../../weather/G4500050.epw
     - ../../../weather/G4500070.epw
     - ../../../weather/G4500090.epw
     - ../../../weather/G4500110.epw
     - ../../../weather/G4500130.epw
     - ../../../weather/G4500150.epw
     - ../../../weather/G4500170.epw
     - ../../../weather/G4500190.epw
     - ../../../weather/G4500210.epw
     - ../../../weather/G4500230.epw
     - ../../../weather/G4500250.epw
     - ../../../weather/G4500270.epw
     - ../../../weather/G4500290.epw
     - ../../../weather/G4500310.epw
     - ../../../weather/G4500330.epw
     - ../../../weather/G4500350.epw
     - ../../../weather/G4500370.epw
     - ../../../weather/G4500390.epw
     - ../../../weather/G4500410.epw
     - ../../../weather/G4500430.epw
     - ../../../weather/G4500450.epw
     - ../../../weather/G4500470.epw
     - ../../../weather/G4500490.epw
     - ../../../weather/G4500510.epw
     - ../../../weather/G4500530.epw
     - ../../../weather/G4500550.epw
     - ../../../weather/G4500570.epw
     - ../../../weather/G4500590.epw
     - ../../../weather/G4500610.epw
     - ../../../weather/G4500630.epw
     - ../../../weather/G4500670.epw
     - ../../../weather/G4500690.epw
     - ../../../weather/G4500650.epw
     - ../../../weather/G4500710.epw
     - ../../../weather/G4500730.epw
     - ../../../weather/G4500750.epw
     - ../../../weather/G4500770.epw
     - ../../../weather/G4500790.epw
     - ../../../weather/G4500810.epw
     - ../../../weather/G4500830.epw
     - ../../../weather/G4500850.epw
     - ../../../weather/G4500870.epw
     - ../../../weather/G4500890.epw
     - ../../../weather/G4500910.epw
     - ../../../weather/G4600030.epw
     - ../../../weather/G4600050.epw
     - ../../../weather/G4600070.epw
     - ../../../weather/G4600090.epw
     - ../../../weather/G4600110.epw
     - ../../../weather/G4600130.epw
     - ../../../weather/G4600150.epw
     - ../../../weather/G4600170.epw
     - ../../../weather/G4600190.epw
     - ../../../weather/G4600210.epw
     - ../../../weather/G4600230.epw
     - ../../../weather/G4600250.epw
     - ../../../weather/G4600270.epw
     - ../../../weather/G4600290.epw
     - ../../../weather/G4600310.epw
     - ../../../weather/G4600330.epw
     - ../../../weather/G4600350.epw
     - ../../../weather/G4600370.epw
     - ../../../weather/G4600390.epw
     - ../../../weather/G4600410.epw
     - ../../../weather/G4600430.epw
     - ../../../weather/G4600450.epw
     - ../../../weather/G4600470.epw
     - ../../../weather/G4600490.epw
     - ../../../weather/G4600510.epw
     - ../../../weather/G4600530.epw
     - ../../../weather/G4600550.epw
     - ../../../weather/G4600570.epw
     - ../../../weather/G4600590.epw
     - ../../../weather/G4600610.epw
     - ../../../weather/G4600630.epw
     - ../../../weather/G4600650.epw
     - ../../../weather/G4600670.epw
     - ../../../weather/G4600690.epw
     - ../../../weather/G4600710.epw
     - ../../../weather/G4600730.epw
     - ../../../weather/G4600750.epw
     - ../../../weather/G4600770.epw
     - ../../../weather/G4600790.epw
     - ../../../weather/G4600810.epw
     - ../../../weather/G4600830.epw
     - ../../../weather/G4600850.epw
     - ../../../weather/G4600910.epw
     - ../../../weather/G4600870.epw
     - ../../../weather/G4600890.epw
     - ../../../weather/G4600930.epw
     - ../../../weather/G4600950.epw
     - ../../../weather/G4600970.epw
     - ../../../weather/G4600990.epw
     - ../../../weather/G4601010.epw
     - ../../../weather/G4601020.epw
     - ../../../weather/G4601030.epw
     - ../../../weather/G4601050.epw
     - ../../../weather/G4601070.epw
     - ../../../weather/G4601090.epw
     - ../../../weather/G4601110.epw
     - ../../../weather/G4601150.epw
     - ../../../weather/G4601170.epw
     - ../../../weather/G4601190.epw
     - ../../../weather/G4601210.epw
     - ../../../weather/G4601230.epw
     - ../../../weather/G4601250.epw
     - ../../../weather/G4601270.epw
     - ../../../weather/G4601290.epw
     - ../../../weather/G4601350.epw
     - ../../../weather/G4601370.epw
     - ../../../weather/G4700010.epw
     - ../../../weather/G4700030.epw
     - ../../../weather/G4700050.epw
     - ../../../weather/G4700070.epw
     - ../../../weather/G4700090.epw
     - ../../../weather/G4700110.epw
     - ../../../weather/G4700130.epw
     - ../../../weather/G4700150.epw
     - ../../../weather/G4700170.epw
     - ../../../weather/G4700190.epw
     - ../../../weather/G4700210.epw
     - ../../../weather/G4700230.epw
     - ../../../weather/G4700250.epw
     - ../../../weather/G4700270.epw
     - ../../../weather/G4700290.epw
     - ../../../weather/G4700310.epw
     - ../../../weather/G4700330.epw
     - ../../../weather/G4700350.epw
     - ../../../weather/G4700370.epw
     - ../../../weather/G4700390.epw
     - ../../../weather/G4700410.epw
     - ../../../weather/G4700430.epw
     - ../../../weather/G4700450.epw
     - ../../../weather/G4700470.epw
     - ../../../weather/G4700490.epw
     - ../../../weather/G4700510.epw
     - ../../../weather/G4700530.epw
     - ../../../weather/G4700550.epw
     - ../../../weather/G4700570.epw
     - ../../../weather/G4700590.epw
     - ../../../weather/G4700610.epw
     - ../../../weather/G4700630.epw
     - ../../../weather/G4700650.epw
     - ../../../weather/G4700670.epw
     - ../../../weather/G4700690.epw
     - ../../../weather/G4700710.epw
     - ../../../weather/G4700730.epw
     - ../../../weather/G4700750.epw
     - ../../../weather/G4700770.epw
     - ../../../weather/G4700790.epw
     - ../../../weather/G4700810.epw
     - ../../../weather/G4700830.epw
     - ../../../weather/G4700850.epw
     - ../../../weather/G4700870.epw
     - ../../../weather/G4700890.epw
     - ../../../weather/G4700910.epw
     - ../../../weather/G4700930.epw
     - ../../../weather/G4700950.epw
     - ../../../weather/G4700970.epw
     - ../../../weather/G4700990.epw
     - ../../../weather/G4701010.epw
     - ../../../weather/G4701030.epw
     - ../../../weather/G4701050.epw
     - ../../../weather/G4701110.epw
     - ../../../weather/G4701130.epw
     - ../../../weather/G4701150.epw
     - ../../../weather/G4701170.epw
     - ../../../weather/G4701190.epw
     - ../../../weather/G4701070.epw
     - ../../../weather/G4701090.epw
     - ../../../weather/G4701210.epw
     - ../../../weather/G4701230.epw
     - ../../../weather/G4701250.epw
     - ../../../weather/G4701270.epw
     - ../../../weather/G4701290.epw
     - ../../../weather/G4701310.epw
     - ../../../weather/G4701330.epw
     - ../../../weather/G4701350.epw
     - ../../../weather/G4701370.epw
     - ../../../weather/G4701390.epw
     - ../../../weather/G4701410.epw
     - ../../../weather/G4701430.epw
     - ../../../weather/G4701450.epw
     - ../../../weather/G4701470.epw
     - ../../../weather/G4701490.epw
     - ../../../weather/G4701510.epw
     - ../../../weather/G4701530.epw
     - ../../../weather/G4701550.epw
     - ../../../weather/G4701570.epw
     - ../../../weather/G4701590.epw
     - ../../../weather/G4701610.epw
     - ../../../weather/G4701630.epw
     - ../../../weather/G4701650.epw
     - ../../../weather/G4701670.epw
     - ../../../weather/G4701690.epw
     - ../../../weather/G4701710.epw
     - ../../../weather/G4701730.epw
     - ../../../weather/G4701750.epw
     - ../../../weather/G4701770.epw
     - ../../../weather/G4701790.epw
     - ../../../weather/G4701810.epw
     - ../../../weather/G4701830.epw
     - ../../../weather/G4701850.epw
     - ../../../weather/G4701870.epw
     - ../../../weather/G4701890.epw
     - ../../../weather/G4800010.epw
     - ../../../weather/G4800030.epw
     - ../../../weather/G4800050.epw
     - ../../../weather/G4800070.epw
     - ../../../weather/G4800090.epw
     - ../../../weather/G4800110.epw
     - ../../../weather/G4800130.epw
     - ../../../weather/G4800150.epw
     - ../../../weather/G4800170.epw
     - ../../../weather/G4800190.epw
     - ../../../weather/G4800210.epw
     - ../../../weather/G4800230.epw
     - ../../../weather/G4800250.epw
     - ../../../weather/G4800270.epw
     - ../../../weather/G4800290.epw
     - ../../../weather/G4800310.epw
     - ../../../weather/G4800330.epw
     - ../../../weather/G4800350.epw
     - ../../../weather/G4800370.epw
     - ../../../weather/G4800390.epw
     - ../../../weather/G4800410.epw
     - ../../../weather/G4800430.epw
     - ../../../weather/G4800450.epw
     - ../../../weather/G4800470.epw
     - ../../../weather/G4800490.epw
     - ../../../weather/G4800510.epw
     - ../../../weather/G4800530.epw
     - ../../../weather/G4800550.epw
     - ../../../weather/G4800570.epw
     - ../../../weather/G4800590.epw
     - ../../../weather/G4800610.epw
     - ../../../weather/G4800630.epw
     - ../../../weather/G4800650.epw
     - ../../../weather/G4800670.epw
     - ../../../weather/G4800690.epw
     - ../../../weather/G4800710.epw
     - ../../../weather/G4800730.epw
     - ../../../weather/G4800750.epw
     - ../../../weather/G4800770.epw
     - ../../../weather/G4800790.epw
     - ../../../weather/G4800810.epw
     - ../../../weather/G4800830.epw
     - ../../../weather/G4800850.epw
     - ../../../weather/G4800870.epw
     - ../../../weather/G4800890.epw
     - ../../../weather/G4800910.epw
     - ../../../weather/G4800930.epw
     - ../../../weather/G4800950.epw
     - ../../../weather/G4800970.epw
     - ../../../weather/G4800990.epw
     - ../../../weather/G4801010.epw
     - ../../../weather/G4801030.epw
     - ../../../weather/G4801050.epw
     - ../../../weather/G4801070.epw
     - ../../../weather/G4801090.epw
     - ../../../weather/G4801110.epw
     - ../../../weather/G4801130.epw
     - ../../../weather/G4801150.epw
     - ../../../weather/G4801170.epw
     - ../../../weather/G4801190.epw
     - ../../../weather/G4801210.epw
     - ../../../weather/G4801230.epw
     - ../../../weather/G4801250.epw
     - ../../../weather/G4801270.epw
     - ../../../weather/G4801290.epw
     - ../../../weather/G4801310.epw
     - ../../../weather/G4801330.epw
     - ../../../weather/G4801350.epw
     - ../../../weather/G4801370.epw
     - ../../../weather/G4801410.epw
     - ../../../weather/G4801390.epw
     - ../../../weather/G4801430.epw
     - ../../../weather/G4801450.epw
     - ../../../weather/G4801470.epw
     - ../../../weather/G4801490.epw
     - ../../../weather/G4801510.epw
     - ../../../weather/G4801530.epw
     - ../../../weather/G4801550.epw
     - ../../../weather/G4801570.epw
     - ../../../weather/G4801590.epw
     - ../../../weather/G4801610.epw
     - ../../../weather/G4801630.epw
     - ../../../weather/G4801650.epw
     - ../../../weather/G4801670.epw
     - ../../../weather/G4801690.epw
     - ../../../weather/G4801710.epw
     - ../../../weather/G4801730.epw
     - ../../../weather/G4801750.epw
     - ../../../weather/G4801770.epw
     - ../../../weather/G4801790.epw
     - ../../../weather/G4801810.epw
     - ../../../weather/G4801830.epw
     - ../../../weather/G4801850.epw
     - ../../../weather/G4801870.epw
     - ../../../weather/G4801890.epw
     - ../../../weather/G4801910.epw
     - ../../../weather/G4801930.epw
     - ../../../weather/G4801950.epw
     - ../../../weather/G4801970.epw
     - ../../../weather/G4801990.epw
     - ../../../weather/G4802010.epw
     - ../../../weather/G4802030.epw
     - ../../../weather/G4802050.epw
     - ../../../weather/G4802070.epw
     - ../../../weather/G4802090.epw
     - ../../../weather/G4802110.epw
     - ../../../weather/G4802130.epw
     - ../../../weather/G4802150.epw
     - ../../../weather/G4802170.epw
     - ../../../weather/G4802190.epw
     - ../../../weather/G4802210.epw
     - ../../../weather/G4802230.epw
     - ../../../weather/G4802250.epw
     - ../../../weather/G4802270.epw
     - ../../../weather/G4802290.epw
     - ../../../weather/G4802310.epw
     - ../../../weather/G4802330.epw
     - ../../../weather/G4802350.epw
     - ../../../weather/G4802370.epw
     - ../../../weather/G4802390.epw
     - ../../../weather/G4802410.epw
     - ../../../weather/G4802430.epw
     - ../../../weather/G4802450.epw
     - ../../../weather/G4802470.epw
     - ../../../weather/G4802490.epw
     - ../../../weather/G4802510.epw
     - ../../../weather/G4802530.epw
     - ../../../weather/G4802550.epw
     - ../../../weather/G4802570.epw
     - ../../../weather/G4802590.epw
     - ../../../weather/G4802610.epw
     - ../../../weather/G4802630.epw
     - ../../../weather/G4802650.epw
     - ../../../weather/G4802670.epw
     - ../../../weather/G4802690.epw
     - ../../../weather/G4802710.epw
     - ../../../weather/G4802730.epw
     - ../../../weather/G4802750.epw
     - ../../../weather/G4802830.epw
     - ../../../weather/G4802770.epw
     - ../../../weather/G4802790.epw
     - ../../../weather/G4802810.epw
     - ../../../weather/G4802850.epw
     - ../../../weather/G4802870.epw
     - ../../../weather/G4802890.epw
     - ../../../weather/G4802910.epw
     - ../../../weather/G4802930.epw
     - ../../../weather/G4802950.epw
     - ../../../weather/G4802970.epw
     - ../../../weather/G4802990.epw
     - ../../../weather/G4803010.epw
     - ../../../weather/G4803030.epw
     - ../../../weather/G4803050.epw
     - ../../../weather/G4803130.epw
     - ../../../weather/G4803150.epw
     - ../../../weather/G4803170.epw
     - ../../../weather/G4803190.epw
     - ../../../weather/G4803210.epw
     - ../../../weather/G4803230.epw
     - ../../../weather/G4803070.epw
     - ../../../weather/G4803090.epw
     - ../../../weather/G4803110.epw
     - ../../../weather/G4803250.epw
     - ../../../weather/G4803270.epw
     - ../../../weather/G4803290.epw
     - ../../../weather/G4803310.epw
     - ../../../weather/G4803330.epw
     - ../../../weather/G4803350.epw
     - ../../../weather/G4803370.epw
     - ../../../weather/G4803390.epw
     - ../../../weather/G4803410.epw
     - ../../../weather/G4803430.epw
     - ../../../weather/G4803450.epw
     - ../../../weather/G4803470.epw
     - ../../../weather/G4803490.epw
     - ../../../weather/G4803510.epw
     - ../../../weather/G4803530.epw
     - ../../../weather/G4803550.epw
     - ../../../weather/G4803570.epw
     - ../../../weather/G4803590.epw
     - ../../../weather/G4803610.epw
     - ../../../weather/G4803630.epw
     - ../../../weather/G4803650.epw
     - ../../../weather/G4803670.epw
     - ../../../weather/G4803690.epw
     - ../../../weather/G4803710.epw
     - ../../../weather/G4803730.epw
     - ../../../weather/G4803750.epw
     - ../../../weather/G4803770.epw
     - ../../../weather/G4803790.epw
     - ../../../weather/G4803810.epw
     - ../../../weather/G4803830.epw
     - ../../../weather/G4803850.epw
     - ../../../weather/G4803870.epw
     - ../../../weather/G4803890.epw
     - ../../../weather/G4803910.epw
     - ../../../weather/G4803930.epw
     - ../../../weather/G4803950.epw
     - ../../../weather/G4803970.epw
     - ../../../weather/G4803990.epw
     - ../../../weather/G4804010.epw
     - ../../../weather/G4804030.epw
     - ../../../weather/G4804050.epw
     - ../../../weather/G4804070.epw
     - ../../../weather/G4804090.epw
     - ../../../weather/G4804110.epw
     - ../../../weather/G4804130.epw
     - ../../../weather/G4804150.epw
     - ../../../weather/G4804170.epw
     - ../../../weather/G4804190.epw
     - ../../../weather/G4804210.epw
     - ../../../weather/G4804230.epw
     - ../../../weather/G4804250.epw
     - ../../../weather/G4804270.epw
     - ../../../weather/G4804290.epw
     - ../../../weather/G4804310.epw
     - ../../../weather/G4804330.epw
     - ../../../weather/G4804350.epw
     - ../../../weather/G4804370.epw
     - ../../../weather/G4804390.epw
     - ../../../weather/G4804410.epw
     - ../../../weather/G4804430.epw
     - ../../../weather/G4804450.epw
     - ../../../weather/G4804470.epw
     - ../../../weather/G4804490.epw
     - ../../../weather/G4804510.epw
     - ../../../weather/G4804530.epw
     - ../../../weather/G4804550.epw
     - ../../../weather/G4804570.epw
     - ../../../weather/G4804590.epw
     - ../../../weather/G4804610.epw
     - ../../../weather/G4804630.epw
     - ../../../weather/G4804650.epw
     - ../../../weather/G4804670.epw
     - ../../../weather/G4804690.epw
     - ../../../weather/G4804710.epw
     - ../../../weather/G4804730.epw
     - ../../../weather/G4804750.epw
     - ../../../weather/G4804770.epw
     - ../../../weather/G4804790.epw
     - ../../../weather/G4804810.epw
     - ../../../weather/G4804830.epw
     - ../../../weather/G4804850.epw
     - ../../../weather/G4804870.epw
     - ../../../weather/G4804890.epw
     - ../../../weather/G4804910.epw
     - ../../../weather/G4804930.epw
     - ../../../weather/G4804950.epw
     - ../../../weather/G4804970.epw
     - ../../../weather/G4804990.epw
     - ../../../weather/G4805010.epw
     - ../../../weather/G4805030.epw
     - ../../../weather/G4805050.epw
     - ../../../weather/G4805070.epw
     - ../../../weather/G4900010.epw
     - ../../../weather/G4900030.epw
     - ../../../weather/G4900050.epw
     - ../../../weather/G4900070.epw
     - ../../../weather/G4900090.epw
     - ../../../weather/G4900110.epw
     - ../../../weather/G4900130.epw
     - ../../../weather/G4900150.epw
     - ../../../weather/G4900170.epw
     - ../../../weather/G4900190.epw
     - ../../../weather/G4900210.epw
     - ../../../weather/G4900230.epw
     - ../../../weather/G4900250.epw
     - ../../../weather/G4900270.epw
     - ../../../weather/G4900290.epw
     - ../../../weather/G4900310.epw
     - ../../../weather/G4900330.epw
     - ../../../weather/G4900350.epw
     - ../../../weather/G4900370.epw
     - ../../../weather/G4900390.epw
     - ../../../weather/G4900410.epw
     - ../../../weather/G4900430.epw
     - ../../../weather/G4900450.epw
     - ../../../weather/G4900470.epw
     - ../../../weather/G4900490.epw
     - ../../../weather/G4900510.epw
     - ../../../weather/G4900530.epw
     - ../../../weather/G4900550.epw
     - ../../../weather/G4900570.epw
     - ../../../weather/G5100010.epw
     - ../../../weather/G5100030.epw
     - ../../../weather/G5105100.epw
     - ../../../weather/G5100050.epw
     - ../../../weather/G5100070.epw
     - ../../../weather/G5100090.epw
     - ../../../weather/G5100110.epw
     - ../../../weather/G5100130.epw
     - ../../../weather/G5100150.epw
     - ../../../weather/G5100170.epw
     - ../../../weather/G5100190.epw
     - ../../../weather/G5100210.epw
     - ../../../weather/G5100230.epw
     - ../../../weather/G5105200.epw
     - ../../../weather/G5100250.epw
     - ../../../weather/G5100270.epw
     - ../../../weather/G5100290.epw
     - ../../../weather/G5105300.epw
     - ../../../weather/G5100310.epw
     - ../../../weather/G5100330.epw
     - ../../../weather/G5100350.epw
     - ../../../weather/G5100360.epw
     - ../../../weather/G5100370.epw
     - ../../../weather/G5105400.epw
     - ../../../weather/G5105500.epw
     - ../../../weather/G5100410.epw
     - ../../../weather/G5100430.epw
     - ../../../weather/G5105700.epw
     - ../../../weather/G5105800.epw
     - ../../../weather/G5100450.epw
     - ../../../weather/G5100470.epw
     - ../../../weather/G5100490.epw
     - ../../../weather/G5105900.epw
     - ../../../weather/G5100510.epw
     - ../../../weather/G5100530.epw
     - ../../../weather/G5105950.epw
     - ../../../weather/G5100570.epw
     - ../../../weather/G5106000.epw
     - ../../../weather/G5100590.epw
     - ../../../weather/G5106100.epw
     - ../../../weather/G5100610.epw
     - ../../../weather/G5100630.epw
     - ../../../weather/G5100650.epw
     - ../../../weather/G5106200.epw
     - ../../../weather/G5100670.epw
     - ../../../weather/G5100690.epw
     - ../../../weather/G5106300.epw
     - ../../../weather/G5106400.epw
     - ../../../weather/G5100710.epw
     - ../../../weather/G5100730.epw
     - ../../../weather/G5100750.epw
     - ../../../weather/G5100770.epw
     - ../../../weather/G5100790.epw
     - ../../../weather/G5100810.epw
     - ../../../weather/G5100830.epw
     - ../../../weather/G5106500.epw
     - ../../../weather/G5100850.epw
     - ../../../weather/G5106600.epw
     - ../../../weather/G5100870.epw
     - ../../../weather/G5100890.epw
     - ../../../weather/G5100910.epw
     - ../../../weather/G5106700.epw
     - ../../../weather/G5100930.epw
     - ../../../weather/G5100950.epw
     - ../../../weather/G5100970.epw
     - ../../../weather/G5100990.epw
     - ../../../weather/G5101010.epw
     - ../../../weather/G5101030.epw
     - ../../../weather/G5101050.epw
     - ../../../weather/G5106780.epw
     - ../../../weather/G5101070.epw
     - ../../../weather/G5101090.epw
     - ../../../weather/G5101110.epw
     - ../../../weather/G5106800.epw
     - ../../../weather/G5101130.epw
     - ../../../weather/G5106830.epw
     - ../../../weather/G5106850.epw
     - ../../../weather/G5106900.epw
     - ../../../weather/G5101150.epw
     - ../../../weather/G5101170.epw
     - ../../../weather/G5101190.epw
     - ../../../weather/G5101210.epw
     - ../../../weather/G5101250.epw
     - ../../../weather/G5101270.epw
     - ../../../weather/G5107000.epw
     - ../../../weather/G5107100.epw
     - ../../../weather/G5101310.epw
     - ../../../weather/G5101330.epw
     - ../../../weather/G5107200.epw
     - ../../../weather/G5101350.epw
     - ../../../weather/G5101370.epw
     - ../../../weather/G5101390.epw
     - ../../../weather/G5101410.epw
     - ../../../weather/G5107300.epw
     - ../../../weather/G5101430.epw
     - ../../../weather/G5107350.epw
     - ../../../weather/G5107400.epw
     - ../../../weather/G5101450.epw
     - ../../../weather/G5101470.epw
     - ../../../weather/G5101490.epw
     - ../../../weather/G5101530.epw
     - ../../../weather/G5101550.epw
     - ../../../weather/G5107500.epw
     - ../../../weather/G5101570.epw
     - ../../../weather/G5107600.epw
     - ../../../weather/G5101590.epw
     - ../../../weather/G5107700.epw
     - ../../../weather/G5101610.epw
     - ../../../weather/G5101630.epw
     - ../../../weather/G5101650.epw
     - ../../../weather/G5101670.epw
     - ../../../weather/G5107750.epw
     - ../../../weather/G5101690.epw
     - ../../../weather/G5101710.epw
     - ../../../weather/G5101730.epw
     - ../../../weather/G5101750.epw
     - ../../../weather/G5101770.epw
     - ../../../weather/G5101790.epw
     - ../../../weather/G5107900.epw
     - ../../../weather/G5108000.epw
     - ../../../weather/G5101810.epw
     - ../../../weather/G5101830.epw
     - ../../../weather/G5101850.epw
     - ../../../weather/G5108100.epw
     - ../../../weather/G5101870.epw
     - ../../../weather/G5101910.epw
     - ../../../weather/G5108200.epw
     - ../../../weather/G5101930.epw
     - ../../../weather/G5108300.epw
     - ../../../weather/G5108400.epw
     - ../../../weather/G5101950.epw
     - ../../../weather/G5101970.epw
     - ../../../weather/G5101990.epw
     - ../../../weather/G5000010.epw
     - ../../../weather/G5000030.epw
     - ../../../weather/G5000050.epw
     - ../../../weather/G5000070.epw
     - ../../../weather/G5000090.epw
     - ../../../weather/G5000110.epw
     - ../../../weather/G5000130.epw
     - ../../../weather/G5000150.epw
     - ../../../weather/G5000170.epw
     - ../../../weather/G5000190.epw
     - ../../../weather/G5000210.epw
     - ../../../weather/G5000230.epw
     - ../../../weather/G5000250.epw
     - ../../../weather/G5000270.epw
     - ../../../weather/G5300010.epw
     - ../../../weather/G5300030.epw
     - ../../../weather/G5300050.epw
     - ../../../weather/G5300070.epw
     - ../../../weather/G5300090.epw
     - ../../../weather/G5300110.epw
     - ../../../weather/G5300130.epw
     - ../../../weather/G5300150.epw
     - ../../../weather/G5300170.epw
     - ../../../weather/G5300190.epw
     - ../../../weather/G5300210.epw
     - ../../../weather/G5300230.epw
     - ../../../weather/G5300250.epw
     - ../../../weather/G5300270.epw
     - ../../../weather/G5300290.epw
     - ../../../weather/G5300310.epw
     - ../../../weather/G5300330.epw
     - ../../../weather/G5300350.epw
     - ../../../weather/G5300370.epw
     - ../../../weather/G5300390.epw
     - ../../../weather/G5300410.epw
     - ../../../weather/G5300430.epw
     - ../../../weather/G5300450.epw
     - ../../../weather/G5300470.epw
     - ../../../weather/G5300490.epw
     - ../../../weather/G5300510.epw
     - ../../../weather/G5300530.epw
     - ../../../weather/G5300550.epw
     - ../../../weather/G5300570.epw
     - ../../../weather/G5300590.epw
     - ../../../weather/G5300610.epw
     - ../../../weather/G5300630.epw
     - ../../../weather/G5300650.epw
     - ../../../weather/G5300670.epw
     - ../../../weather/G5300690.epw
     - ../../../weather/G5300710.epw
     - ../../../weather/G5300730.epw
     - ../../../weather/G5300750.epw
     - ../../../weather/G5300770.epw
     - ../../../weather/G5500010.epw
     - ../../../weather/G5500030.epw
     - ../../../weather/G5500050.epw
     - ../../../weather/G5500070.epw
     - ../../../weather/G5500090.epw
     - ../../../weather/G5500110.epw
     - ../../../weather/G5500130.epw
     - ../../../weather/G5500150.epw
     - ../../../weather/G5500170.epw
     - ../../../weather/G5500190.epw
     - ../../../weather/G5500210.epw
     - ../../../weather/G5500230.epw
     - ../../../weather/G5500250.epw
     - ../../../weather/G5500270.epw
     - ../../../weather/G5500290.epw
     - ../../../weather/G5500310.epw
     - ../../../weather/G5500330.epw
     - ../../../weather/G5500350.epw
     - ../../../weather/G5500370.epw
     - ../../../weather/G5500390.epw
     - ../../../weather/G5500410.epw
     - ../../../weather/G5500430.epw
     - ../../../weather/G5500450.epw
     - ../../../weather/G5500470.epw
     - ../../../weather/G5500490.epw
     - ../../../weather/G5500510.epw
     - ../../../weather/G5500530.epw
     - ../../../weather/G5500550.epw
     - ../../../weather/G5500570.epw
     - ../../../weather/G5500590.epw
     - ../../../weather/G5500610.epw
     - ../../../weather/G5500630.epw
     - ../../../weather/G5500650.epw
     - ../../../weather/G5500670.epw
     - ../../../weather/G5500690.epw
     - ../../../weather/G5500710.epw
     - ../../../weather/G5500730.epw
     - ../../../weather/G5500750.epw
     - ../../../weather/G5500770.epw
     - ../../../weather/G5500780.epw
     - ../../../weather/G5500790.epw
     - ../../../weather/G5500810.epw
     - ../../../weather/G5500830.epw
     - ../../../weather/G5500850.epw
     - ../../../weather/G5500870.epw
     - ../../../weather/G5500890.epw
     - ../../../weather/G5500910.epw
     - ../../../weather/G5500930.epw
     - ../../../weather/G5500950.epw
     - ../../../weather/G5500970.epw
     - ../../../weather/G5500990.epw
     - ../../../weather/G5501010.epw
     - ../../../weather/G5501030.epw
     - ../../../weather/G5501050.epw
     - ../../../weather/G5501070.epw
     - ../../../weather/G5501110.epw
     - ../../../weather/G5501130.epw
     - ../../../weather/G5501150.epw
     - ../../../weather/G5501170.epw
     - ../../../weather/G5501090.epw
     - ../../../weather/G5501190.epw
     - ../../../weather/G5501210.epw
     - ../../../weather/G5501230.epw
     - ../../../weather/G5501250.epw
     - ../../../weather/G5501270.epw
     - ../../../weather/G5501290.epw
     - ../../../weather/G5501310.epw
     - ../../../weather/G5501330.epw
     - ../../../weather/G5501350.epw
     - ../../../weather/G5501370.epw
     - ../../../weather/G5501390.epw
     - ../../../weather/G5501410.epw
     - ../../../weather/G5400010.epw
     - ../../../weather/G5400030.epw
     - ../../../weather/G5400050.epw
     - ../../../weather/G5400070.epw
     - ../../../weather/G5400090.epw
     - ../../../weather/G5400110.epw
     - ../../../weather/G5400130.epw
     - ../../../weather/G5400150.epw
     - ../../../weather/G5400170.epw
     - ../../../weather/G5400190.epw
     - ../../../weather/G5400210.epw
     - ../../../weather/G5400230.epw
     - ../../../weather/G5400250.epw
     - ../../../weather/G5400270.epw
     - ../../../weather/G5400290.epw
     - ../../../weather/G5400310.epw
     - ../../../weather/G5400330.epw
     - ../../../weather/G5400350.epw
     - ../../../weather/G5400370.epw
     - ../../../weather/G5400390.epw
     - ../../../weather/G5400410.epw
     - ../../../weather/G5400430.epw
     - ../../../weather/G5400450.epw
     - ../../../weather/G5400490.epw
     - ../../../weather/G5400510.epw
     - ../../../weather/G5400530.epw
     - ../../../weather/G5400470.epw
     - ../../../weather/G5400550.epw
     - ../../../weather/G5400570.epw
     - ../../../weather/G5400590.epw
     - ../../../weather/G5400610.epw
     - ../../../weather/G5400630.epw
     - ../../../weather/G5400650.epw
     - ../../../weather/G5400670.epw
     - ../../../weather/G5400690.epw
     - ../../../weather/G5400710.epw
     - ../../../weather/G5400730.epw
     - ../../../weather/G5400750.epw
     - ../../../weather/G5400770.epw
     - ../../../weather/G5400790.epw
     - ../../../weather/G5400810.epw
     - ../../../weather/G5400830.epw
     - ../../../weather/G5400850.epw
     - ../../../weather/G5400870.epw
     - ../../../weather/G5400890.epw
     - ../../../weather/G5400910.epw
     - ../../../weather/G5400930.epw
     - ../../../weather/G5400950.epw
     - ../../../weather/G5400970.epw
     - ../../../weather/G5400990.epw
     - ../../../weather/G5401010.epw
     - ../../../weather/G5401030.epw
     - ../../../weather/G5401050.epw
     - ../../../weather/G5401070.epw
     - ../../../weather/G5401090.epw
     - ../../../weather/G5600010.epw
     - ../../../weather/G5600030.epw
     - ../../../weather/G5600050.epw
     - ../../../weather/G5600070.epw
     - ../../../weather/G5600090.epw
     - ../../../weather/G5600110.epw
     - ../../../weather/G5600130.epw
     - ../../../weather/G5600150.epw
     - ../../../weather/G5600170.epw
     - ../../../weather/G5600190.epw
     - ../../../weather/G5600210.epw
     - ../../../weather/G5600230.epw
     - ../../../weather/G5600250.epw
     - ../../../weather/G5600270.epw
     - ../../../weather/G5600290.epw
     - ../../../weather/G5600310.epw
     - ../../../weather/G5600330.epw
     - ../../../weather/G5600350.epw
     - ../../../weather/G5600370.epw
     - ../../../weather/G5600390.epw
     - ../../../weather/G5600410.epw
     - ../../../weather/G5600430.epw
     - ../../../weather/G5600450.epw

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``location_zip_code``
     - 
     - Zip code of the home address. Either this or the EnergyPlus Weather (EPW) File Path input below must be provided.
   * - ``location_epw_path``
     - 
     - Path to the EPW file. Either this or the Zip Code input above must be provided.
.. _county_metro_status:

County Metro Status
-------------------

Description
***********

The Metro Status of the county that the sample is located, based on MSA and MicroSA.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \County-MSA crosswalk comes from the Quarterly Census of Employment and Wages NAICS-based data between 2013-2022 by the U.S. Bureau of Labor Statistics (https://www.bls.gov/cew/classifications/areas/county-msa-csa-crosswalk.htm)


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **County Metro Status** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Metropolitan
     - Non-Metropolitan
   * - Stock saturation
     - 83%
     - 17%

.. _county_and_puma:

County and PUMA
---------------

Description
***********

The GISJOIN identifier for the County and the Public Use Microdata Area that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **County and PUMA** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - G0100010, G01002100
     - G0100030, G01002600
     - G0100050, G01002400
     - G0100070, G01001700
     - G0100090, G01000800
     - G0100110, G01002400
     - G0100130, G01002300
     - G0100150, G01001100
     - G0100170, G01001800
     - G0100190, G01001000
     - G0100210, G01001800
     - G0100230, G01002200
     - G0100250, G01002200
     - G0100270, G01001000
     - G0100290, G01001000
     - G0100310, G01002300
     - G0100330, G01000100
     - G0100350, G01002200
     - G0100370, G01001800
     - G0100390, G01002300
     - G0100410, G01002300
     - G0100430, G01000700
     - G0100450, G01002500
     - G0100470, G01001700
     - G0100490, G01000400
     - G0100510, G01002100
     - G0100530, G01002200
     - G0100550, G01000900
     - G0100570, G01001400
     - G0100590, G01000100
     - G0100610, G01002500
     - G0100630, G01001700
     - G0100650, G01001700
     - G0100670, G01002500
     - G0100690, G01002500
     - G0100710, G01000400
     - G0100730, G01001301
     - G0100730, G01001302
     - G0100730, G01001303
     - G0100730, G01001304
     - G0100730, G01001305
     - G0100750, G01001400
     - G0100770, G01000100
     - G0100790, G01000600
     - G0100810, G01001900
     - G0100830, G01000200
     - G0100850, G01002100
     - G0100870, G01002400
     - G0100890, G01000200
     - G0100890, G01000301
     - G0100890, G01000302
     - G0100890, G01000500
     - G0100910, G01001700
     - G0100930, G01000100
     - G0100930, G01001400
     - G0100950, G01000500
     - G0100970, G01002701
     - G0100970, G01002702
     - G0100970, G01002703
     - G0100990, G01002200
     - G0101010, G01002000
     - G0101010, G01002100
     - G0101030, G01000600
     - G0101050, G01001700
     - G0101070, G01001500
     - G0101090, G01002400
     - G0101110, G01001000
     - G0101130, G01002400
     - G0101150, G01000800
     - G0101170, G01001200
     - G0101190, G01001700
     - G0101210, G01001000
     - G0101230, G01001800
     - G0101250, G01001500
     - G0101250, G01001600
     - G0101270, G01001400
     - G0101290, G01002200
     - G0101310, G01002200
     - G0101330, G01000700
     - G0200130, G02000400
     - G0200160, G02000400
     - G0200200, G02000101
     - G0200200, G02000102
     - G0200500, G02000400
     - G0200600, G02000400
     - G0200680, G02000300
     - G0200700, G02000400
     - G0200900, G02000300
     - G0201000, G02000300
     - G0201050, G02000400
     - G0201100, G02000300
     - G0201220, G02000200
     - G0201300, G02000300
     - G0201500, G02000400
     - G0201580, G02000400
     - G0201640, G02000400
     - G0201700, G02000200
     - G0201800, G02000400
     - G0201850, G02000400
     - G0201880, G02000400
     - G0201950, G02000400
     - G0201980, G02000400
     - G0202200, G02000400
     - G0202300, G02000300
     - G0202400, G02000300
     - G0202610, G02000300
     - G0202750, G02000400
     - G0202820, G02000400
     - G0202900, G02000400
     - G0400010, G04000300
     - G0400030, G04000900
     - G0400050, G04000400
     - G0400070, G04000800
     - G0400090, G04000800
     - G0400110, G04000800
     - G0400120, G04000600
     - G0400130, G04000100
     - G0400130, G04000101
     - G0400130, G04000102
     - G0400130, G04000103
     - G0400130, G04000104
     - G0400130, G04000105
     - G0400130, G04000106
     - G0400130, G04000107
     - G0400130, G04000108
     - G0400130, G04000109
     - G0400130, G04000110
     - G0400130, G04000111
     - G0400130, G04000112
     - G0400130, G04000113
     - G0400130, G04000114
     - G0400130, G04000115
     - G0400130, G04000116
     - G0400130, G04000117
     - G0400130, G04000118
     - G0400130, G04000119
     - G0400130, G04000120
     - G0400130, G04000121
     - G0400130, G04000122
     - G0400130, G04000123
     - G0400130, G04000124
     - G0400130, G04000125
     - G0400130, G04000126
     - G0400130, G04000127
     - G0400130, G04000128
     - G0400130, G04000129
     - G0400130, G04000130
     - G0400130, G04000131
     - G0400130, G04000132
     - G0400130, G04000133
     - G0400130, G04000134
     - G0400150, G04000600
     - G0400170, G04000300
     - G0400190, G04000201
     - G0400190, G04000202
     - G0400190, G04000203
     - G0400190, G04000204
     - G0400190, G04000205
     - G0400190, G04000206
     - G0400190, G04000207
     - G0400190, G04000208
     - G0400190, G04000209
     - G0400210, G04000800
     - G0400210, G04000803
     - G0400210, G04000805
     - G0400210, G04000807
     - G0400230, G04000900
     - G0400250, G04000500
     - G0400270, G04000700
     - G0500010, G05001700
     - G0500010, G05001800
     - G0500030, G05001800
     - G0500050, G05000300
     - G0500070, G05000100
     - G0500090, G05000300
     - G0500110, G05001800
     - G0500130, G05001900
     - G0500150, G05000300
     - G0500170, G05001800
     - G0500190, G05001600
     - G0500210, G05000500
     - G0500230, G05000400
     - G0500250, G05001800
     - G0500270, G05001900
     - G0500290, G05001300
     - G0500310, G05000500
     - G0500310, G05000600
     - G0500330, G05001400
     - G0500350, G05000600
     - G0500370, G05000700
     - G0500390, G05001900
     - G0500410, G05001800
     - G0500430, G05001800
     - G0500450, G05001100
     - G0500470, G05001500
     - G0500490, G05000400
     - G0500510, G05001600
     - G0500530, G05001700
     - G0500550, G05000500
     - G0500570, G05002000
     - G0500590, G05001600
     - G0500610, G05001500
     - G0500630, G05000400
     - G0500650, G05000400
     - G0500670, G05000800
     - G0500690, G05001700
     - G0500710, G05001300
     - G0500730, G05002000
     - G0500750, G05000500
     - G0500770, G05000700
     - G0500790, G05001800
     - G0500810, G05002000
     - G0500830, G05001500
     - G0500850, G05001100
     - G0500870, G05000300
     - G0500890, G05000300
     - G0500910, G05002000
     - G0500930, G05000600
     - G0500950, G05000700
     - G0500970, G05001600
     - G0500990, G05002000
     - G0501010, G05000300
     - G0501030, G05001900
     - G0501050, G05001300
     - G0501070, G05000700
     - G0501090, G05002000
     - G0501110, G05000700
     - G0501130, G05001500
     - G0501150, G05001300
     - G0501170, G05000800
     - G0501190, G05000900
     - G0501190, G05001000
     - G0501210, G05000500
     - G0501230, G05000700
     - G0501250, G05001200
     - G0501270, G05001500
     - G0501290, G05000300
     - G0501310, G05001400
     - G0501330, G05001500
     - G0501350, G05000400
     - G0501370, G05000400
     - G0501390, G05001900
     - G0501410, G05000400
     - G0501430, G05000200
     - G0501450, G05000800
     - G0501470, G05000800
     - G0501490, G05001300
     - G0600010, G06000101
     - G0600010, G06000102
     - G0600010, G06000103
     - G0600010, G06000104
     - G0600010, G06000105
     - G0600010, G06000106
     - G0600010, G06000107
     - G0600010, G06000108
     - G0600010, G06000109
     - G0600010, G06000110
     - G0600030, G06000300
     - G0600050, G06000300
     - G0600070, G06000701
     - G0600070, G06000702
     - G0600090, G06000300
     - G0600110, G06001100
     - G0600130, G06001301
     - G0600130, G06001302
     - G0600130, G06001303
     - G0600130, G06001304
     - G0600130, G06001305
     - G0600130, G06001306
     - G0600130, G06001307
     - G0600130, G06001308
     - G0600130, G06001309
     - G0600150, G06001500
     - G0600170, G06001700
     - G0600190, G06001901
     - G0600190, G06001902
     - G0600190, G06001903
     - G0600190, G06001904
     - G0600190, G06001905
     - G0600190, G06001906
     - G0600190, G06001907
     - G0600210, G06001100
     - G0600230, G06002300
     - G0600250, G06002500
     - G0600270, G06000300
     - G0600290, G06002901
     - G0600290, G06002902
     - G0600290, G06002903
     - G0600290, G06002904
     - G0600290, G06002905
     - G0600310, G06003100
     - G0600330, G06003300
     - G0600350, G06001500
     - G0600370, G06003701
     - G0600370, G06003702
     - G0600370, G06003703
     - G0600370, G06003704
     - G0600370, G06003705
     - G0600370, G06003706
     - G0600370, G06003707
     - G0600370, G06003708
     - G0600370, G06003709
     - G0600370, G06003710
     - G0600370, G06003711
     - G0600370, G06003712
     - G0600370, G06003713
     - G0600370, G06003714
     - G0600370, G06003715
     - G0600370, G06003716
     - G0600370, G06003717
     - G0600370, G06003718
     - G0600370, G06003719
     - G0600370, G06003720
     - G0600370, G06003721
     - G0600370, G06003722
     - G0600370, G06003723
     - G0600370, G06003724
     - G0600370, G06003725
     - G0600370, G06003726
     - G0600370, G06003727
     - G0600370, G06003728
     - G0600370, G06003729
     - G0600370, G06003730
     - G0600370, G06003731
     - G0600370, G06003732
     - G0600370, G06003733
     - G0600370, G06003734
     - G0600370, G06003735
     - G0600370, G06003736
     - G0600370, G06003737
     - G0600370, G06003738
     - G0600370, G06003739
     - G0600370, G06003740
     - G0600370, G06003741
     - G0600370, G06003742
     - G0600370, G06003743
     - G0600370, G06003744
     - G0600370, G06003745
     - G0600370, G06003746
     - G0600370, G06003747
     - G0600370, G06003748
     - G0600370, G06003749
     - G0600370, G06003750
     - G0600370, G06003751
     - G0600370, G06003752
     - G0600370, G06003753
     - G0600370, G06003754
     - G0600370, G06003755
     - G0600370, G06003756
     - G0600370, G06003757
     - G0600370, G06003758
     - G0600370, G06003759
     - G0600370, G06003760
     - G0600370, G06003761
     - G0600370, G06003762
     - G0600370, G06003763
     - G0600370, G06003764
     - G0600370, G06003765
     - G0600370, G06003766
     - G0600370, G06003767
     - G0600370, G06003768
     - G0600370, G06003769
     - G0600390, G06003900
     - G0600410, G06004101
     - G0600410, G06004102
     - G0600430, G06000300
     - G0600450, G06003300
     - G0600470, G06004701
     - G0600470, G06004702
     - G0600490, G06001500
     - G0600510, G06000300
     - G0600530, G06005301
     - G0600530, G06005302
     - G0600530, G06005303
     - G0600550, G06005500
     - G0600570, G06005700
     - G0600590, G06005901
     - G0600590, G06005902
     - G0600590, G06005903
     - G0600590, G06005904
     - G0600590, G06005905
     - G0600590, G06005906
     - G0600590, G06005907
     - G0600590, G06005908
     - G0600590, G06005909
     - G0600590, G06005910
     - G0600590, G06005911
     - G0600590, G06005912
     - G0600590, G06005913
     - G0600590, G06005914
     - G0600590, G06005915
     - G0600590, G06005916
     - G0600590, G06005917
     - G0600590, G06005918
     - G0600610, G06006101
     - G0600610, G06006102
     - G0600610, G06006103
     - G0600630, G06001500
     - G0600650, G06006501
     - G0600650, G06006502
     - G0600650, G06006503
     - G0600650, G06006504
     - G0600650, G06006505
     - G0600650, G06006506
     - G0600650, G06006507
     - G0600650, G06006508
     - G0600650, G06006509
     - G0600650, G06006510
     - G0600650, G06006511
     - G0600650, G06006512
     - G0600650, G06006513
     - G0600650, G06006514
     - G0600650, G06006515
     - G0600670, G06006701
     - G0600670, G06006702
     - G0600670, G06006703
     - G0600670, G06006704
     - G0600670, G06006705
     - G0600670, G06006706
     - G0600670, G06006707
     - G0600670, G06006708
     - G0600670, G06006709
     - G0600670, G06006710
     - G0600670, G06006711
     - G0600670, G06006712
     - G0600690, G06005303
     - G0600710, G06007101
     - G0600710, G06007102
     - G0600710, G06007103
     - G0600710, G06007104
     - G0600710, G06007105
     - G0600710, G06007106
     - G0600710, G06007107
     - G0600710, G06007108
     - G0600710, G06007109
     - G0600710, G06007110
     - G0600710, G06007111
     - G0600710, G06007112
     - G0600710, G06007113
     - G0600710, G06007114
     - G0600710, G06007115
     - G0600730, G06007301
     - G0600730, G06007302
     - G0600730, G06007303
     - G0600730, G06007304
     - G0600730, G06007305
     - G0600730, G06007306
     - G0600730, G06007307
     - G0600730, G06007308
     - G0600730, G06007309
     - G0600730, G06007310
     - G0600730, G06007311
     - G0600730, G06007312
     - G0600730, G06007313
     - G0600730, G06007314
     - G0600730, G06007315
     - G0600730, G06007316
     - G0600730, G06007317
     - G0600730, G06007318
     - G0600730, G06007319
     - G0600730, G06007320
     - G0600730, G06007321
     - G0600730, G06007322
     - G0600750, G06007501
     - G0600750, G06007502
     - G0600750, G06007503
     - G0600750, G06007504
     - G0600750, G06007505
     - G0600750, G06007506
     - G0600750, G06007507
     - G0600770, G06007701
     - G0600770, G06007702
     - G0600770, G06007703
     - G0600770, G06007704
     - G0600790, G06007901
     - G0600790, G06007902
     - G0600810, G06008101
     - G0600810, G06008102
     - G0600810, G06008103
     - G0600810, G06008104
     - G0600810, G06008105
     - G0600810, G06008106
     - G0600830, G06008301
     - G0600830, G06008302
     - G0600830, G06008303
     - G0600850, G06008501
     - G0600850, G06008502
     - G0600850, G06008503
     - G0600850, G06008504
     - G0600850, G06008505
     - G0600850, G06008506
     - G0600850, G06008507
     - G0600850, G06008508
     - G0600850, G06008509
     - G0600850, G06008510
     - G0600850, G06008511
     - G0600850, G06008512
     - G0600850, G06008513
     - G0600850, G06008514
     - G0600870, G06008701
     - G0600870, G06008702
     - G0600890, G06008900
     - G0600910, G06005700
     - G0600930, G06001500
     - G0600950, G06009501
     - G0600950, G06009502
     - G0600950, G06009503
     - G0600970, G06009701
     - G0600970, G06009702
     - G0600970, G06009703
     - G0600990, G06009901
     - G0600990, G06009902
     - G0600990, G06009903
     - G0600990, G06009904
     - G0601010, G06010100
     - G0601030, G06001100
     - G0601050, G06001100
     - G0601070, G06010701
     - G0601070, G06010702
     - G0601070, G06010703
     - G0601090, G06000300
     - G0601110, G06011101
     - G0601110, G06011102
     - G0601110, G06011103
     - G0601110, G06011104
     - G0601110, G06011105
     - G0601110, G06011106
     - G0601130, G06011300
     - G0601150, G06010100
     - G0800010, G08000804
     - G0800010, G08000805
     - G0800010, G08000806
     - G0800010, G08000807
     - G0800010, G08000809
     - G0800010, G08000810
     - G0800010, G08000817
     - G0800010, G08000824
     - G0800030, G08000800
     - G0800050, G08000808
     - G0800050, G08000809
     - G0800050, G08000810
     - G0800050, G08000811
     - G0800050, G08000815
     - G0800050, G08000820
     - G0800050, G08000824
     - G0800070, G08000900
     - G0800090, G08000800
     - G0800110, G08000100
     - G0800130, G08000801
     - G0800130, G08000802
     - G0800130, G08000803
     - G0800130, G08000804
     - G0800140, G08000804
     - G0800140, G08000805
     - G0800150, G08000600
     - G0800170, G08000100
     - G0800190, G08000801
     - G0800210, G08000800
     - G0800230, G08000800
     - G0800250, G08000100
     - G0800270, G08000600
     - G0800290, G08001002
     - G0800310, G08000812
     - G0800310, G08000813
     - G0800310, G08000814
     - G0800310, G08000815
     - G0800310, G08000816
     - G0800330, G08000900
     - G0800350, G08000821
     - G0800350, G08000822
     - G0800350, G08000823
     - G0800370, G08000400
     - G0800390, G08000100
     - G0800390, G08000823
     - G0800410, G08004101
     - G0800410, G08004102
     - G0800410, G08004103
     - G0800410, G08004104
     - G0800410, G08004105
     - G0800410, G08004106
     - G0800430, G08000600
     - G0800450, G08000200
     - G0800470, G08000801
     - G0800490, G08000400
     - G0800510, G08000900
     - G0800530, G08000900
     - G0800550, G08000600
     - G0800570, G08000400
     - G0800590, G08000801
     - G0800590, G08000804
     - G0800590, G08000805
     - G0800590, G08000817
     - G0800590, G08000818
     - G0800590, G08000819
     - G0800590, G08000820
     - G0800590, G08000821
     - G0800610, G08000100
     - G0800630, G08000100
     - G0800650, G08000600
     - G0800670, G08000900
     - G0800690, G08000102
     - G0800690, G08000103
     - G0800710, G08000800
     - G0800730, G08000100
     - G0800750, G08000100
     - G0800770, G08001001
     - G0800770, G08001002
     - G0800790, G08000800
     - G0800810, G08000200
     - G0800830, G08000900
     - G0800850, G08001002
     - G0800870, G08000100
     - G0800890, G08000800
     - G0800910, G08001002
     - G0800930, G08000600
     - G0800950, G08000100
     - G0800970, G08000400
     - G0800990, G08000800
     - G0801010, G08000600
     - G0801010, G08000700
     - G0801010, G08000800
     - G0801030, G08000200
     - G0801050, G08000800
     - G0801070, G08000200
     - G0801090, G08000800
     - G0801110, G08000900
     - G0801130, G08001002
     - G0801150, G08000100
     - G0801170, G08000400
     - G0801190, G08004101
     - G0801210, G08000100
     - G0801230, G08000100
     - G0801230, G08000300
     - G0801230, G08000802
     - G0801230, G08000824
     - G0801250, G08000100
     - G0900010, G09000100
     - G0900010, G09000101
     - G0900010, G09000102
     - G0900010, G09000103
     - G0900010, G09000104
     - G0900010, G09000105
     - G0900030, G09000300
     - G0900030, G09000301
     - G0900030, G09000302
     - G0900030, G09000303
     - G0900030, G09000304
     - G0900030, G09000305
     - G0900030, G09000306
     - G0900050, G09000500
     - G0900070, G09000700
     - G0900090, G09000900
     - G0900090, G09000901
     - G0900090, G09000902
     - G0900090, G09000903
     - G0900090, G09000904
     - G0900090, G09000905
     - G0900090, G09000906
     - G0900110, G09001100
     - G0900110, G09001101
     - G0900130, G09001300
     - G0900150, G09001500
     - G1000010, G10000200
     - G1000030, G10000101
     - G1000030, G10000102
     - G1000030, G10000103
     - G1000030, G10000104
     - G1000050, G10000300
     - G1100010, G11000101
     - G1100010, G11000102
     - G1100010, G11000103
     - G1100010, G11000104
     - G1100010, G11000105
     - G1200010, G12000101
     - G1200010, G12000102
     - G1200030, G12008900
     - G1200050, G12000500
     - G1200070, G12002300
     - G1200090, G12000901
     - G1200090, G12000902
     - G1200090, G12000903
     - G1200090, G12000904
     - G1200110, G12001101
     - G1200110, G12001102
     - G1200110, G12001103
     - G1200110, G12001104
     - G1200110, G12001105
     - G1200110, G12001106
     - G1200110, G12001107
     - G1200110, G12001108
     - G1200110, G12001109
     - G1200110, G12001110
     - G1200110, G12001111
     - G1200110, G12001112
     - G1200110, G12001113
     - G1200110, G12001114
     - G1200130, G12006300
     - G1200150, G12001500
     - G1200170, G12001701
     - G1200190, G12001900
     - G1200210, G12002101
     - G1200210, G12002102
     - G1200210, G12002103
     - G1200230, G12002300
     - G1200270, G12002700
     - G1200290, G12002300
     - G1200310, G12003101
     - G1200310, G12003102
     - G1200310, G12003103
     - G1200310, G12003104
     - G1200310, G12003105
     - G1200310, G12003106
     - G1200310, G12003107
     - G1200330, G12003301
     - G1200330, G12003302
     - G1200350, G12003500
     - G1200370, G12006300
     - G1200390, G12006300
     - G1200410, G12002300
     - G1200430, G12009300
     - G1200450, G12006300
     - G1200470, G12012100
     - G1200490, G12002700
     - G1200510, G12009300
     - G1200530, G12005301
     - G1200550, G12002700
     - G1200550, G12009300
     - G1200570, G12005701
     - G1200570, G12005702
     - G1200570, G12005703
     - G1200570, G12005704
     - G1200570, G12005705
     - G1200570, G12005706
     - G1200570, G12005707
     - G1200570, G12005708
     - G1200590, G12000500
     - G1200610, G12006100
     - G1200630, G12006300
     - G1200650, G12006300
     - G1200670, G12012100
     - G1200690, G12006901
     - G1200690, G12006902
     - G1200690, G12006903
     - G1200710, G12007101
     - G1200710, G12007102
     - G1200710, G12007103
     - G1200710, G12007104
     - G1200710, G12007105
     - G1200730, G12007300
     - G1200730, G12007301
     - G1200750, G12002300
     - G1200770, G12006300
     - G1200790, G12012100
     - G1200810, G12008101
     - G1200810, G12008102
     - G1200810, G12008103
     - G1200830, G12008301
     - G1200830, G12008302
     - G1200830, G12008303
     - G1200850, G12008500
     - G1200860, G12008601
     - G1200860, G12008602
     - G1200860, G12008603
     - G1200860, G12008604
     - G1200860, G12008605
     - G1200860, G12008606
     - G1200860, G12008607
     - G1200860, G12008608
     - G1200860, G12008609
     - G1200860, G12008610
     - G1200860, G12008611
     - G1200860, G12008612
     - G1200860, G12008613
     - G1200860, G12008614
     - G1200860, G12008615
     - G1200860, G12008616
     - G1200860, G12008617
     - G1200860, G12008618
     - G1200860, G12008619
     - G1200860, G12008620
     - G1200860, G12008621
     - G1200860, G12008622
     - G1200860, G12008623
     - G1200860, G12008624
     - G1200860, G12008700
     - G1200870, G12008700
     - G1200890, G12008900
     - G1200910, G12009100
     - G1200930, G12009300
     - G1200950, G12009501
     - G1200950, G12009502
     - G1200950, G12009503
     - G1200950, G12009504
     - G1200950, G12009505
     - G1200950, G12009506
     - G1200950, G12009507
     - G1200950, G12009508
     - G1200950, G12009509
     - G1200950, G12009510
     - G1200970, G12009701
     - G1200970, G12009702
     - G1200990, G12009901
     - G1200990, G12009902
     - G1200990, G12009903
     - G1200990, G12009904
     - G1200990, G12009905
     - G1200990, G12009906
     - G1200990, G12009907
     - G1200990, G12009908
     - G1200990, G12009909
     - G1200990, G12009910
     - G1200990, G12009911
     - G1201010, G12010101
     - G1201010, G12010102
     - G1201010, G12010103
     - G1201010, G12010104
     - G1201030, G12010301
     - G1201030, G12010302
     - G1201030, G12010303
     - G1201030, G12010304
     - G1201030, G12010305
     - G1201030, G12010306
     - G1201030, G12010307
     - G1201030, G12010308
     - G1201050, G12010501
     - G1201050, G12010502
     - G1201050, G12010503
     - G1201050, G12010504
     - G1201070, G12010700
     - G1201090, G12010700
     - G1201090, G12010900
     - G1201110, G12011101
     - G1201110, G12011102
     - G1201130, G12011300
     - G1201150, G12011501
     - G1201150, G12011502
     - G1201150, G12011503
     - G1201170, G12011701
     - G1201170, G12011702
     - G1201170, G12011703
     - G1201170, G12011704
     - G1201190, G12006902
     - G1201190, G12006903
     - G1201210, G12012100
     - G1201230, G12012100
     - G1201250, G12002300
     - G1201270, G12003500
     - G1201270, G12012701
     - G1201270, G12012702
     - G1201270, G12012703
     - G1201270, G12012704
     - G1201290, G12006300
     - G1201310, G12000500
     - G1201330, G12000500
     - G1300010, G13001200
     - G1300030, G13000500
     - G1300050, G13000500
     - G1300070, G13001100
     - G1300090, G13001600
     - G1300110, G13003500
     - G1300130, G13003800
     - G1300150, G13002900
     - G1300170, G13000700
     - G1300190, G13000700
     - G1300210, G13001400
     - G1300230, G13001300
     - G1300250, G13000500
     - G1300270, G13000700
     - G1300290, G13000200
     - G1300310, G13000300
     - G1300330, G13004200
     - G1300350, G13001900
     - G1300370, G13001100
     - G1300390, G13000100
     - G1300430, G13001300
     - G1300450, G13002300
     - G1300470, G13002600
     - G1300490, G13000500
     - G1300510, G13000401
     - G1300510, G13000402
     - G1300530, G13001700
     - G1300550, G13002600
     - G1300570, G13003101
     - G1300570, G13003102
     - G1300590, G13003600
     - G1300610, G13001800
     - G1300630, G13005001
     - G1300630, G13005002
     - G1300650, G13000500
     - G1300670, G13003001
     - G1300670, G13003002
     - G1300670, G13003003
     - G1300670, G13003004
     - G1300670, G13003005
     - G1300690, G13000500
     - G1300710, G13000800
     - G1300730, G13004100
     - G1300750, G13000700
     - G1300770, G13002100
     - G1300790, G13001600
     - G1300810, G13001800
     - G1300830, G13002600
     - G1300850, G13003200
     - G1300870, G13001100
     - G1300890, G13001007
     - G1300890, G13001008
     - G1300890, G13002001
     - G1300890, G13002002
     - G1300890, G13002003
     - G1300890, G13002004
     - G1300910, G13001300
     - G1300930, G13001800
     - G1300950, G13000900
     - G1300970, G13004400
     - G1300990, G13001100
     - G1301010, G13000500
     - G1301030, G13000300
     - G1301050, G13003700
     - G1301070, G13001300
     - G1301090, G13001200
     - G1301110, G13002800
     - G1301130, G13002400
     - G1301150, G13002500
     - G1301170, G13003300
     - G1301190, G13003500
     - G1301210, G13001001
     - G1301210, G13001002
     - G1301210, G13001003
     - G1301210, G13001004
     - G1301210, G13001005
     - G1301210, G13001006
     - G1301210, G13001007
     - G1301210, G13004600
     - G1301230, G13002800
     - G1301250, G13004200
     - G1301270, G13000100
     - G1301290, G13002800
     - G1301310, G13001100
     - G1301330, G13003700
     - G1301350, G13004001
     - G1301350, G13004002
     - G1301350, G13004003
     - G1301350, G13004004
     - G1301350, G13004005
     - G1301350, G13004006
     - G1301370, G13003500
     - G1301390, G13003400
     - G1301410, G13004200
     - G1301430, G13002500
     - G1301450, G13001800
     - G1301470, G13003500
     - G1301490, G13002200
     - G1301510, G13006001
     - G1301510, G13006002
     - G1301530, G13001500
     - G1301550, G13000700
     - G1301570, G13003800
     - G1301590, G13003900
     - G1301610, G13001200
     - G1301630, G13004200
     - G1301650, G13004200
     - G1301670, G13001300
     - G1301690, G13001600
     - G1301710, G13001900
     - G1301730, G13000500
     - G1301750, G13001300
     - G1301770, G13000900
     - G1301790, G13000200
     - G1301810, G13004200
     - G1301830, G13000200
     - G1301850, G13000600
     - G1301870, G13003200
     - G1301890, G13004200
     - G1301910, G13000100
     - G1301930, G13001800
     - G1301950, G13003700
     - G1301970, G13001800
     - G1301990, G13002200
     - G1302010, G13001100
     - G1302050, G13001100
     - G1302070, G13001600
     - G1302090, G13001200
     - G1302110, G13003900
     - G1302130, G13002800
     - G1302150, G13001700
     - G1302170, G13004300
     - G1302190, G13003700
     - G1302210, G13003700
     - G1302230, G13004500
     - G1302250, G13001600
     - G1302270, G13002800
     - G1302290, G13000500
     - G1302310, G13001900
     - G1302330, G13002500
     - G1302350, G13001500
     - G1302370, G13001600
     - G1302390, G13001800
     - G1302410, G13003200
     - G1302430, G13001800
     - G1302450, G13004000
     - G1302470, G13004300
     - G1302490, G13001800
     - G1302510, G13000300
     - G1302530, G13001100
     - G1302550, G13001900
     - G1302570, G13003500
     - G1302590, G13001800
     - G1302610, G13001800
     - G1302630, G13001800
     - G1302650, G13004200
     - G1302670, G13001200
     - G1302690, G13001800
     - G1302710, G13001200
     - G1302730, G13001100
     - G1302750, G13000800
     - G1302770, G13000700
     - G1302790, G13001200
     - G1302810, G13003200
     - G1302830, G13001300
     - G1302850, G13002200
     - G1302870, G13000700
     - G1302890, G13001600
     - G1302910, G13003200
     - G1302930, G13001900
     - G1302950, G13002600
     - G1302970, G13003900
     - G1302990, G13000500
     - G1303010, G13004200
     - G1303030, G13004200
     - G1303050, G13001200
     - G1303070, G13001800
     - G1303090, G13001200
     - G1303110, G13003200
     - G1303130, G13002700
     - G1303150, G13001300
     - G1303170, G13004200
     - G1303190, G13001600
     - G1303210, G13000800
     - G1500010, G15000200
     - G1500030, G15000301
     - G1500030, G15000302
     - G1500030, G15000303
     - G1500030, G15000304
     - G1500030, G15000305
     - G1500030, G15000306
     - G1500030, G15000307
     - G1500030, G15000308
     - G1500050, G15000100
     - G1500070, G15000100
     - G1500090, G15000100
     - G1600010, G16000400
     - G1600010, G16000600
     - G1600010, G16000701
     - G1600010, G16000702
     - G1600010, G16000800
     - G1600030, G16000300
     - G1600050, G16001300
     - G1600070, G16001300
     - G1600090, G16000100
     - G1600110, G16001100
     - G1600110, G16001300
     - G1600130, G16001000
     - G1600150, G16000300
     - G1600170, G16000100
     - G1600190, G16001200
     - G1600210, G16000100
     - G1600230, G16000300
     - G1600250, G16001000
     - G1600270, G16000400
     - G1600270, G16000500
     - G1600270, G16000600
     - G1600290, G16001300
     - G1600310, G16000900
     - G1600330, G16000300
     - G1600350, G16000300
     - G1600370, G16000300
     - G1600390, G16001000
     - G1600410, G16001300
     - G1600430, G16001100
     - G1600450, G16000400
     - G1600470, G16001000
     - G1600490, G16000300
     - G1600510, G16001100
     - G1600530, G16001000
     - G1600550, G16000100
     - G1600550, G16000200
     - G1600570, G16000100
     - G1600590, G16000300
     - G1600610, G16000300
     - G1600630, G16001000
     - G1600650, G16001100
     - G1600670, G16001000
     - G1600690, G16000300
     - G1600710, G16001300
     - G1600730, G16000500
     - G1600750, G16000400
     - G1600770, G16001300
     - G1600790, G16000100
     - G1600810, G16001100
     - G1600830, G16000900
     - G1600850, G16000300
     - G1600870, G16000400
     - G1700010, G17000300
     - G1700030, G17000800
     - G1700050, G17000501
     - G1700070, G17002901
     - G1700090, G17000300
     - G1700110, G17002501
     - G1700130, G17000401
     - G1700150, G17000104
     - G1700170, G17000401
     - G1700190, G17002100
     - G1700210, G17001602
     - G1700230, G17000700
     - G1700250, G17000700
     - G1700270, G17000501
     - G1700290, G17000600
     - G1700310, G17003401
     - G1700310, G17003407
     - G1700310, G17003408
     - G1700310, G17003409
     - G1700310, G17003410
     - G1700310, G17003411
     - G1700310, G17003412
     - G1700310, G17003413
     - G1700310, G17003414
     - G1700310, G17003415
     - G1700310, G17003416
     - G1700310, G17003417
     - G1700310, G17003418
     - G1700310, G17003419
     - G1700310, G17003420
     - G1700310, G17003421
     - G1700310, G17003422
     - G1700310, G17003501
     - G1700310, G17003502
     - G1700310, G17003503
     - G1700310, G17003504
     - G1700310, G17003520
     - G1700310, G17003521
     - G1700310, G17003522
     - G1700310, G17003523
     - G1700310, G17003524
     - G1700310, G17003525
     - G1700310, G17003526
     - G1700310, G17003527
     - G1700310, G17003528
     - G1700310, G17003529
     - G1700310, G17003530
     - G1700310, G17003531
     - G1700310, G17003532
     - G1700330, G17000700
     - G1700350, G17000600
     - G1700370, G17002601
     - G1700390, G17001602
     - G1700410, G17000600
     - G1700430, G17003202
     - G1700430, G17003203
     - G1700430, G17003204
     - G1700430, G17003205
     - G1700430, G17003207
     - G1700430, G17003208
     - G1700430, G17003209
     - G1700450, G17000600
     - G1700470, G17000800
     - G1700490, G17000501
     - G1700510, G17000501
     - G1700530, G17002200
     - G1700550, G17000900
     - G1700570, G17000202
     - G1700590, G17000800
     - G1700610, G17000401
     - G1700630, G17003700
     - G1700650, G17000800
     - G1700670, G17000202
     - G1700690, G17000800
     - G1700710, G17000202
     - G1700730, G17000202
     - G1700750, G17002200
     - G1700770, G17000900
     - G1700790, G17000700
     - G1700810, G17001001
     - G1700830, G17000401
     - G1700850, G17000104
     - G1700870, G17000800
     - G1700890, G17003005
     - G1700890, G17003007
     - G1700890, G17003008
     - G1700890, G17003009
     - G1700910, G17002300
     - G1700930, G17003700
     - G1700950, G17002501
     - G1700970, G17003306
     - G1700970, G17003307
     - G1700970, G17003308
     - G1700970, G17003309
     - G1700970, G17003310
     - G1700990, G17002400
     - G1701010, G17000700
     - G1701030, G17000104
     - G1701050, G17002200
     - G1701070, G17001602
     - G1701090, G17000202
     - G1701110, G17003601
     - G1701110, G17003602
     - G1701130, G17002000
     - G1701150, G17001500
     - G1701170, G17000401
     - G1701190, G17001204
     - G1701190, G17001205
     - G1701210, G17001001
     - G1701230, G17002501
     - G1701250, G17000300
     - G1701270, G17000800
     - G1701290, G17001602
     - G1701310, G17000202
     - G1701330, G17001001
     - G1701350, G17000501
     - G1701370, G17000401
     - G1701390, G17001602
     - G1701410, G17002700
     - G1701430, G17001701
     - G1701450, G17000900
     - G1701470, G17001602
     - G1701490, G17000300
     - G1701510, G17000800
     - G1701530, G17000800
     - G1701550, G17002501
     - G1701570, G17001001
     - G1701590, G17000700
     - G1701610, G17000105
     - G1701630, G17001104
     - G1701630, G17001105
     - G1701650, G17000800
     - G1701670, G17001300
     - G1701690, G17000300
     - G1701710, G17000401
     - G1701730, G17001602
     - G1701750, G17002501
     - G1701770, G17002700
     - G1701790, G17001900
     - G1701810, G17000800
     - G1701830, G17002200
     - G1701850, G17000800
     - G1701870, G17000202
     - G1701890, G17001001
     - G1701910, G17000700
     - G1701930, G17000800
     - G1701950, G17000104
     - G1701970, G17003102
     - G1701970, G17003105
     - G1701970, G17003106
     - G1701970, G17003107
     - G1701970, G17003108
     - G1701990, G17000900
     - G1702010, G17002801
     - G1702010, G17002901
     - G1702030, G17002501
     - G1800010, G18000900
     - G1800030, G18001001
     - G1800030, G18001002
     - G1800030, G18001003
     - G1800050, G18002900
     - G1800070, G18001100
     - G1800090, G18001500
     - G1800110, G18001801
     - G1800130, G18002100
     - G1800150, G18001100
     - G1800170, G18001300
     - G1800190, G18003600
     - G1800210, G18001600
     - G1800230, G18001100
     - G1800250, G18003400
     - G1800270, G18002700
     - G1800290, G18003100
     - G1800310, G18003000
     - G1800330, G18000600
     - G1800350, G18002000
     - G1800370, G18003400
     - G1800390, G18000500
     - G1800410, G18002600
     - G1800430, G18003500
     - G1800450, G18001600
     - G1800470, G18003100
     - G1800490, G18000700
     - G1800510, G18003200
     - G1800530, G18001400
     - G1800550, G18002700
     - G1800570, G18001801
     - G1800570, G18001802
     - G1800570, G18001803
     - G1800590, G18002500
     - G1800610, G18003500
     - G1800630, G18002200
     - G1800650, G18001500
     - G1800670, G18001300
     - G1800690, G18000900
     - G1800710, G18002900
     - G1800730, G18000700
     - G1800750, G18001500
     - G1800770, G18003000
     - G1800790, G18003000
     - G1800810, G18002400
     - G1800830, G18003400
     - G1800850, G18000800
     - G1800870, G18000600
     - G1800890, G18000101
     - G1800890, G18000102
     - G1800890, G18000103
     - G1800890, G18000104
     - G1800910, G18000300
     - G1800930, G18002700
     - G1800950, G18001900
     - G1800970, G18002301
     - G1800970, G18002302
     - G1800970, G18002303
     - G1800970, G18002304
     - G1800970, G18002305
     - G1800970, G18002306
     - G1800970, G18002307
     - G1800990, G18000800
     - G1801010, G18002700
     - G1801030, G18001400
     - G1801050, G18002800
     - G1801070, G18001100
     - G1801090, G18002100
     - G1801110, G18000700
     - G1801130, G18000600
     - G1801150, G18003100
     - G1801170, G18002700
     - G1801190, G18002700
     - G1801210, G18001600
     - G1801230, G18003400
     - G1801250, G18003400
     - G1801270, G18000200
     - G1801290, G18003200
     - G1801310, G18000700
     - G1801330, G18002100
     - G1801350, G18001500
     - G1801370, G18003100
     - G1801390, G18002600
     - G1801410, G18000401
     - G1801410, G18000402
     - G1801430, G18003000
     - G1801450, G18002500
     - G1801470, G18003400
     - G1801490, G18000700
     - G1801510, G18000600
     - G1801530, G18001600
     - G1801550, G18003100
     - G1801570, G18001200
     - G1801590, G18001300
     - G1801610, G18002600
     - G1801630, G18003300
     - G1801650, G18001600
     - G1801670, G18001700
     - G1801690, G18001400
     - G1801710, G18001600
     - G1801730, G18003200
     - G1801750, G18003500
     - G1801770, G18002600
     - G1801790, G18000900
     - G1801810, G18001100
     - G1801830, G18000900
     - G1900010, G19001800
     - G1900030, G19001800
     - G1900050, G19000400
     - G1900070, G19001800
     - G1900090, G19001800
     - G1900110, G19001200
     - G1900130, G19000500
     - G1900150, G19001300
     - G1900170, G19000400
     - G1900190, G19000700
     - G1900210, G19001900
     - G1900230, G19000600
     - G1900250, G19001900
     - G1900270, G19001900
     - G1900290, G19002100
     - G1900310, G19000800
     - G1900330, G19000200
     - G1900350, G19001900
     - G1900370, G19000400
     - G1900390, G19001800
     - G1900410, G19000100
     - G1900430, G19000400
     - G1900450, G19000800
     - G1900470, G19001900
     - G1900490, G19001400
     - G1900490, G19001500
     - G1900510, G19002200
     - G1900530, G19001800
     - G1900550, G19000700
     - G1900570, G19002300
     - G1900590, G19000100
     - G1900610, G19000700
     - G1900630, G19000100
     - G1900650, G19000400
     - G1900670, G19000200
     - G1900690, G19000600
     - G1900710, G19002100
     - G1900730, G19001900
     - G1900750, G19000600
     - G1900770, G19001800
     - G1900790, G19000600
     - G1900810, G19000200
     - G1900830, G19000600
     - G1900850, G19002100
     - G1900870, G19002300
     - G1900890, G19000400
     - G1900910, G19000600
     - G1900930, G19001900
     - G1900950, G19001200
     - G1900970, G19000700
     - G1900990, G19001400
     - G1901010, G19002200
     - G1901030, G19001100
     - G1901050, G19000800
     - G1901070, G19002200
     - G1901090, G19000200
     - G1901110, G19002300
     - G1901130, G19001000
     - G1901150, G19002300
     - G1901170, G19001800
     - G1901190, G19000100
     - G1901210, G19001400
     - G1901230, G19002200
     - G1901250, G19001400
     - G1901270, G19001200
     - G1901290, G19002100
     - G1901310, G19000200
     - G1901330, G19001900
     - G1901350, G19001800
     - G1901370, G19002100
     - G1901390, G19000800
     - G1901410, G19000100
     - G1901430, G19000100
     - G1901450, G19002100
     - G1901470, G19000100
     - G1901490, G19002000
     - G1901510, G19001900
     - G1901530, G19001500
     - G1901530, G19001600
     - G1901530, G19001700
     - G1901550, G19002100
     - G1901570, G19001200
     - G1901590, G19001800
     - G1901610, G19001900
     - G1901630, G19000900
     - G1901650, G19002100
     - G1901670, G19000100
     - G1901690, G19001300
     - G1901710, G19001200
     - G1901730, G19001800
     - G1901750, G19001800
     - G1901770, G19002200
     - G1901790, G19002200
     - G1901810, G19001400
     - G1901830, G19002200
     - G1901850, G19001800
     - G1901870, G19000600
     - G1901890, G19000200
     - G1901910, G19000400
     - G1901930, G19002000
     - G1901950, G19000200
     - G1901970, G19000600
     - G2000010, G20001400
     - G2000030, G20001400
     - G2000050, G20000400
     - G2000070, G20001100
     - G2000090, G20001100
     - G2000110, G20001400
     - G2000130, G20000802
     - G2000150, G20001302
     - G2000150, G20001304
     - G2000170, G20000900
     - G2000190, G20000900
     - G2000210, G20001500
     - G2000230, G20000100
     - G2000250, G20001200
     - G2000270, G20000200
     - G2000290, G20000200
     - G2000310, G20000900
     - G2000330, G20001100
     - G2000350, G20000900
     - G2000350, G20001100
     - G2000370, G20001500
     - G2000390, G20000100
     - G2000410, G20000200
     - G2000430, G20000400
     - G2000450, G20000700
     - G2000470, G20001100
     - G2000490, G20000900
     - G2000510, G20000100
     - G2000530, G20000200
     - G2000550, G20001200
     - G2000570, G20001200
     - G2000590, G20001400
     - G2000610, G20000300
     - G2000630, G20000100
     - G2000650, G20000100
     - G2000670, G20001200
     - G2000690, G20001200
     - G2000710, G20000100
     - G2000730, G20000900
     - G2000750, G20001200
     - G2000770, G20001100
     - G2000790, G20001301
     - G2000810, G20001200
     - G2000830, G20001200
     - G2000850, G20000802
     - G2000870, G20000400
     - G2000890, G20000200
     - G2000910, G20000601
     - G2000910, G20000602
     - G2000910, G20000603
     - G2000910, G20000604
     - G2000930, G20001200
     - G2000950, G20001100
     - G2000970, G20001100
     - G2000990, G20001500
     - G2001010, G20000100
     - G2001030, G20000400
     - G2001050, G20000200
     - G2001070, G20001400
     - G2001090, G20000100
     - G2001110, G20000900
     - G2001130, G20001000
     - G2001150, G20000900
     - G2001170, G20000200
     - G2001190, G20001200
     - G2001210, G20001400
     - G2001230, G20000200
     - G2001250, G20001500
     - G2001270, G20000900
     - G2001290, G20001200
     - G2001310, G20000200
     - G2001330, G20001500
     - G2001350, G20000100
     - G2001370, G20000100
     - G2001390, G20000802
     - G2001410, G20000100
     - G2001430, G20000200
     - G2001450, G20001100
     - G2001470, G20000100
     - G2001490, G20000300
     - G2001510, G20001100
     - G2001530, G20000100
     - G2001550, G20001000
     - G2001570, G20000200
     - G2001590, G20001000
     - G2001610, G20000300
     - G2001630, G20000100
     - G2001650, G20001100
     - G2001670, G20000100
     - G2001690, G20000200
     - G2001710, G20000100
     - G2001730, G20001301
     - G2001730, G20001302
     - G2001730, G20001303
     - G2001730, G20001304
     - G2001750, G20001200
     - G2001770, G20000801
     - G2001770, G20000802
     - G2001790, G20000100
     - G2001810, G20000100
     - G2001830, G20000100
     - G2001850, G20001100
     - G2001870, G20001200
     - G2001890, G20001200
     - G2001910, G20001100
     - G2001930, G20000100
     - G2001950, G20000100
     - G2001970, G20000802
     - G2001990, G20000100
     - G2002010, G20000200
     - G2002030, G20000100
     - G2002050, G20000900
     - G2002070, G20000900
     - G2002090, G20000500
     - G2100010, G21000600
     - G2100030, G21000400
     - G2100050, G21002000
     - G2100070, G21000100
     - G2100090, G21000400
     - G2100110, G21002700
     - G2100130, G21000900
     - G2100150, G21002500
     - G2100170, G21002300
     - G2100190, G21002800
     - G2100210, G21002100
     - G2100230, G21002700
     - G2100250, G21001000
     - G2100270, G21001300
     - G2100290, G21001600
     - G2100310, G21000400
     - G2100330, G21000200
     - G2100350, G21000100
     - G2100370, G21002600
     - G2100390, G21000100
     - G2100410, G21002600
     - G2100430, G21002800
     - G2100450, G21000600
     - G2100470, G21000300
     - G2100490, G21002300
     - G2100510, G21000800
     - G2100530, G21000600
     - G2100550, G21000200
     - G2100570, G21000600
     - G2100590, G21001500
     - G2100610, G21000400
     - G2100630, G21002800
     - G2100650, G21002200
     - G2100670, G21001901
     - G2100670, G21001902
     - G2100690, G21002700
     - G2100710, G21001100
     - G2100730, G21002000
     - G2100750, G21000100
     - G2100770, G21002600
     - G2100790, G21002100
     - G2100810, G21002600
     - G2100830, G21000100
     - G2100850, G21001300
     - G2100870, G21000600
     - G2100890, G21002800
     - G2100910, G21001500
     - G2100930, G21001200
     - G2100930, G21001300
     - G2100950, G21000900
     - G2100970, G21002300
     - G2100990, G21000400
     - G2101010, G21001400
     - G2101030, G21001800
     - G2101050, G21000100
     - G2101070, G21000200
     - G2101090, G21000800
     - G2101110, G21001701
     - G2101110, G21001702
     - G2101110, G21001703
     - G2101110, G21001704
     - G2101110, G21001705
     - G2101110, G21001706
     - G2101130, G21002100
     - G2101150, G21001100
     - G2101170, G21002400
     - G2101190, G21001000
     - G2101210, G21000900
     - G2101230, G21001200
     - G2101250, G21000800
     - G2101270, G21002800
     - G2101290, G21001000
     - G2101310, G21001000
     - G2101330, G21001000
     - G2101350, G21002700
     - G2101370, G21002100
     - G2101390, G21000200
     - G2101410, G21000400
     - G2101430, G21000300
     - G2101450, G21000100
     - G2101470, G21000700
     - G2101490, G21001400
     - G2101510, G21002200
     - G2101530, G21001100
     - G2101550, G21001200
     - G2101570, G21000100
     - G2101590, G21001100
     - G2101610, G21002700
     - G2101630, G21001300
     - G2101650, G21002700
     - G2101670, G21002000
     - G2101690, G21000400
     - G2101710, G21000400
     - G2101730, G21002700
     - G2101750, G21002700
     - G2101770, G21000200
     - G2101790, G21001200
     - G2101810, G21002300
     - G2101830, G21001400
     - G2101850, G21001800
     - G2101870, G21002600
     - G2101890, G21001000
     - G2101910, G21002600
     - G2101930, G21001000
     - G2101950, G21001100
     - G2101970, G21002200
     - G2101990, G21000700
     - G2102010, G21002700
     - G2102030, G21000800
     - G2102050, G21002700
     - G2102070, G21000600
     - G2102090, G21002300
     - G2102110, G21001600
     - G2102110, G21001800
     - G2102130, G21000400
     - G2102150, G21001600
     - G2102170, G21000600
     - G2102190, G21000300
     - G2102210, G21000300
     - G2102230, G21001800
     - G2102250, G21001400
     - G2102270, G21000500
     - G2102290, G21001200
     - G2102310, G21000700
     - G2102330, G21001400
     - G2102350, G21000900
     - G2102370, G21001000
     - G2102390, G21002000
     - G2200010, G22001100
     - G2200030, G22000800
     - G2200050, G22001600
     - G2200070, G22002000
     - G2200090, G22000600
     - G2200110, G22000800
     - G2200130, G22000300
     - G2200150, G22000200
     - G2200170, G22000100
     - G2200170, G22000101
     - G2200190, G22000800
     - G2200190, G22000900
     - G2200210, G22000500
     - G2200230, G22000900
     - G2200250, G22000600
     - G2200270, G22000300
     - G2200290, G22000600
     - G2200310, G22000300
     - G2200330, G22001500
     - G2200330, G22001501
     - G2200330, G22001502
     - G2200350, G22000500
     - G2200370, G22001400
     - G2200390, G22001000
     - G2200410, G22000500
     - G2200430, G22000600
     - G2200450, G22001300
     - G2200470, G22001400
     - G2200490, G22000500
     - G2200510, G22002300
     - G2200510, G22002301
     - G2200510, G22002302
     - G2200510, G22002500
     - G2200530, G22000900
     - G2200550, G22001200
     - G2200550, G22001201
     - G2200570, G22002000
     - G2200590, G22000600
     - G2200610, G22000300
     - G2200630, G22001700
     - G2200650, G22000500
     - G2200670, G22000500
     - G2200690, G22000300
     - G2200710, G22002400
     - G2200710, G22002401
     - G2200710, G22002402
     - G2200730, G22000400
     - G2200750, G22002500
     - G2200770, G22001400
     - G2200790, G22000700
     - G2200810, G22000300
     - G2200830, G22000500
     - G2200850, G22000300
     - G2200870, G22002500
     - G2200890, G22001900
     - G2200910, G22001700
     - G2200930, G22001900
     - G2200950, G22001900
     - G2200970, G22001000
     - G2200990, G22001300
     - G2201010, G22001300
     - G2201030, G22002200
     - G2201030, G22002201
     - G2201050, G22001800
     - G2201070, G22000500
     - G2201090, G22002100
     - G2201110, G22000500
     - G2201130, G22001100
     - G2201150, G22000700
     - G2201170, G22001800
     - G2201190, G22000200
     - G2201210, G22001400
     - G2201230, G22000500
     - G2201250, G22001400
     - G2201270, G22000600
     - G2300010, G23000600
     - G2300030, G23000100
     - G2300050, G23000700
     - G2300050, G23000800
     - G2300050, G23000900
     - G2300050, G23001000
     - G2300070, G23000200
     - G2300090, G23000500
     - G2300110, G23000400
     - G2300130, G23000500
     - G2300150, G23000500
     - G2300170, G23000200
     - G2300190, G23000300
     - G2300210, G23000200
     - G2300230, G23000700
     - G2300250, G23000200
     - G2300270, G23000500
     - G2300290, G23000100
     - G2300310, G23000800
     - G2300310, G23000900
     - G2400010, G24000100
     - G2400030, G24001201
     - G2400030, G24001202
     - G2400030, G24001203
     - G2400030, G24001204
     - G2400050, G24000501
     - G2400050, G24000502
     - G2400050, G24000503
     - G2400050, G24000504
     - G2400050, G24000505
     - G2400050, G24000506
     - G2400050, G24000507
     - G2400090, G24001500
     - G2400110, G24001300
     - G2400130, G24000400
     - G2400150, G24000700
     - G2400170, G24001600
     - G2400190, G24001300
     - G2400210, G24000301
     - G2400210, G24000302
     - G2400230, G24000100
     - G2400250, G24000601
     - G2400250, G24000602
     - G2400270, G24000901
     - G2400270, G24000902
     - G2400290, G24001300
     - G2400310, G24001001
     - G2400310, G24001002
     - G2400310, G24001003
     - G2400310, G24001004
     - G2400310, G24001005
     - G2400310, G24001006
     - G2400310, G24001007
     - G2400330, G24001101
     - G2400330, G24001102
     - G2400330, G24001103
     - G2400330, G24001104
     - G2400330, G24001105
     - G2400330, G24001106
     - G2400330, G24001107
     - G2400350, G24001300
     - G2400370, G24001500
     - G2400390, G24001400
     - G2400410, G24001300
     - G2400430, G24000200
     - G2400450, G24001400
     - G2400470, G24001400
     - G2405100, G24000801
     - G2405100, G24000802
     - G2405100, G24000803
     - G2405100, G24000804
     - G2405100, G24000805
     - G2500010, G25004700
     - G2500010, G25004800
     - G2500030, G25000100
     - G2500050, G25004200
     - G2500050, G25004301
     - G2500050, G25004302
     - G2500050, G25004303
     - G2500050, G25004500
     - G2500050, G25004901
     - G2500070, G25004800
     - G2500090, G25000701
     - G2500090, G25000702
     - G2500090, G25000703
     - G2500090, G25000704
     - G2500090, G25001000
     - G2500090, G25001300
     - G2500090, G25002800
     - G2500110, G25000200
     - G2500130, G25001600
     - G2500130, G25001900
     - G2500130, G25001901
     - G2500130, G25001902
     - G2500150, G25000200
     - G2500150, G25001600
     - G2500170, G25000400
     - G2500170, G25000501
     - G2500170, G25000502
     - G2500170, G25000503
     - G2500170, G25000504
     - G2500170, G25000505
     - G2500170, G25000506
     - G2500170, G25000507
     - G2500170, G25000508
     - G2500170, G25001000
     - G2500170, G25001300
     - G2500170, G25001400
     - G2500170, G25002400
     - G2500170, G25002800
     - G2500170, G25003400
     - G2500170, G25003500
     - G2500190, G25004800
     - G2500210, G25002400
     - G2500210, G25003400
     - G2500210, G25003500
     - G2500210, G25003601
     - G2500210, G25003602
     - G2500210, G25003603
     - G2500210, G25003900
     - G2500210, G25004000
     - G2500210, G25004200
     - G2500230, G25003900
     - G2500230, G25004000
     - G2500230, G25004301
     - G2500230, G25004901
     - G2500230, G25004902
     - G2500230, G25004903
     - G2500250, G25003301
     - G2500250, G25003302
     - G2500250, G25003303
     - G2500250, G25003304
     - G2500250, G25003305
     - G2500250, G25003306
     - G2500270, G25000300
     - G2500270, G25000301
     - G2500270, G25000302
     - G2500270, G25000303
     - G2500270, G25000304
     - G2500270, G25000400
     - G2500270, G25001400
     - G2500270, G25002400
     - G2600010, G26000300
     - G2600030, G26000200
     - G2600050, G26000900
     - G2600070, G26000300
     - G2600090, G26000400
     - G2600110, G26001300
     - G2600130, G26000100
     - G2600150, G26002000
     - G2600170, G26001400
     - G2600190, G26000500
     - G2600210, G26002400
     - G2600230, G26002200
     - G2600250, G26002000
     - G2600270, G26002300
     - G2600290, G26000400
     - G2600310, G26000300
     - G2600330, G26000200
     - G2600350, G26001200
     - G2600370, G26001900
     - G2600390, G26000300
     - G2600410, G26000200
     - G2600430, G26000100
     - G2600450, G26001900
     - G2600470, G26000400
     - G2600490, G26001701
     - G2600490, G26001702
     - G2600490, G26001703
     - G2600490, G26001704
     - G2600510, G26001300
     - G2600530, G26000100
     - G2600550, G26000500
     - G2600570, G26001200
     - G2600590, G26002500
     - G2600610, G26000100
     - G2600630, G26001600
     - G2600650, G26001801
     - G2600650, G26001802
     - G2600670, G26001100
     - G2600690, G26001300
     - G2600710, G26000100
     - G2600730, G26001200
     - G2600750, G26002600
     - G2600770, G26002101
     - G2600770, G26002102
     - G2600790, G26000400
     - G2600810, G26001001
     - G2600810, G26001002
     - G2600810, G26001003
     - G2600810, G26001004
     - G2600830, G26000100
     - G2600850, G26000600
     - G2600870, G26001701
     - G2600890, G26000500
     - G2600910, G26002500
     - G2600930, G26002800
     - G2600950, G26000200
     - G2600970, G26000200
     - G2600990, G26003001
     - G2600990, G26003002
     - G2600990, G26003003
     - G2600990, G26003004
     - G2600990, G26003005
     - G2600990, G26003006
     - G2601010, G26000500
     - G2601030, G26000100
     - G2601050, G26000600
     - G2601070, G26001100
     - G2601090, G26000200
     - G2601110, G26001400
     - G2601130, G26000400
     - G2601150, G26003300
     - G2601170, G26001100
     - G2601190, G26000300
     - G2601210, G26000700
     - G2601230, G26000600
     - G2601250, G26002901
     - G2601250, G26002902
     - G2601250, G26002903
     - G2601250, G26002904
     - G2601250, G26002905
     - G2601250, G26002906
     - G2601250, G26002907
     - G2601250, G26002908
     - G2601270, G26000600
     - G2601290, G26001300
     - G2601310, G26000100
     - G2601330, G26001100
     - G2601350, G26000300
     - G2601370, G26000300
     - G2601390, G26000801
     - G2601390, G26000802
     - G2601410, G26000300
     - G2601430, G26001300
     - G2601450, G26001500
     - G2601470, G26003100
     - G2601490, G26002200
     - G2601510, G26001600
     - G2601530, G26000200
     - G2601550, G26001704
     - G2601570, G26001600
     - G2601590, G26002300
     - G2601610, G26002701
     - G2601610, G26002702
     - G2601610, G26002703
     - G2601630, G26003201
     - G2601630, G26003202
     - G2601630, G26003203
     - G2601630, G26003204
     - G2601630, G26003205
     - G2601630, G26003206
     - G2601630, G26003207
     - G2601630, G26003208
     - G2601630, G26003209
     - G2601630, G26003210
     - G2601630, G26003211
     - G2601630, G26003212
     - G2601630, G26003213
     - G2601650, G26000400
     - G2700010, G27000300
     - G2700030, G27001101
     - G2700030, G27001102
     - G2700030, G27001103
     - G2700050, G27000200
     - G2700070, G27000200
     - G2700090, G27001000
     - G2700110, G27000800
     - G2700130, G27002200
     - G2700150, G27002000
     - G2700170, G27000300
     - G2700170, G27000400
     - G2700190, G27001700
     - G2700210, G27000300
     - G2700230, G27002000
     - G2700250, G27000600
     - G2700270, G27000100
     - G2700290, G27000200
     - G2700310, G27000400
     - G2700330, G27002100
     - G2700350, G27000700
     - G2700370, G27001501
     - G2700370, G27001502
     - G2700370, G27001503
     - G2700390, G27002400
     - G2700410, G27000800
     - G2700430, G27002100
     - G2700450, G27002600
     - G2700470, G27002400
     - G2700490, G27002300
     - G2700510, G27000800
     - G2700530, G27001401
     - G2700530, G27001402
     - G2700530, G27001403
     - G2700530, G27001404
     - G2700530, G27001405
     - G2700530, G27001406
     - G2700530, G27001407
     - G2700530, G27001408
     - G2700530, G27001409
     - G2700530, G27001410
     - G2700550, G27002600
     - G2700570, G27000200
     - G2700590, G27000600
     - G2700610, G27000300
     - G2700630, G27002100
     - G2700650, G27000600
     - G2700670, G27001900
     - G2700690, G27000100
     - G2700710, G27000400
     - G2700730, G27002000
     - G2700750, G27000400
     - G2700770, G27000200
     - G2700790, G27002300
     - G2700810, G27002000
     - G2700830, G27002000
     - G2700850, G27001900
     - G2700870, G27000200
     - G2700890, G27000100
     - G2700910, G27002100
     - G2700930, G27001900
     - G2700950, G27000600
     - G2700970, G27000700
     - G2700990, G27002400
     - G2701010, G27002100
     - G2701030, G27002200
     - G2701050, G27002100
     - G2701070, G27000100
     - G2701090, G27002500
     - G2701110, G27000800
     - G2701130, G27000100
     - G2701150, G27000600
     - G2701170, G27002100
     - G2701190, G27000100
     - G2701210, G27000800
     - G2701230, G27001301
     - G2701230, G27001302
     - G2701230, G27001303
     - G2701230, G27001304
     - G2701250, G27000100
     - G2701270, G27002000
     - G2701290, G27001900
     - G2701310, G27002300
     - G2701330, G27002100
     - G2701350, G27000100
     - G2701370, G27000400
     - G2701370, G27000500
     - G2701390, G27001600
     - G2701390, G27001700
     - G2701410, G27001000
     - G2701430, G27001900
     - G2701450, G27000900
     - G2701470, G27002400
     - G2701490, G27000800
     - G2701510, G27000800
     - G2701530, G27000700
     - G2701550, G27000800
     - G2701570, G27002600
     - G2701590, G27000700
     - G2701610, G27002200
     - G2701630, G27001201
     - G2701630, G27001202
     - G2701650, G27002100
     - G2701670, G27000800
     - G2701690, G27002600
     - G2701710, G27001800
     - G2701730, G27002000
     - G2800010, G28001600
     - G2800030, G28000200
     - G2800050, G28001600
     - G2800070, G28000700
     - G2800090, G28000200
     - G2800110, G28000800
     - G2800130, G28000400
     - G2800150, G28000700
     - G2800170, G28000400
     - G2800190, G28000600
     - G2800210, G28001600
     - G2800230, G28001500
     - G2800250, G28000600
     - G2800270, G28000300
     - G2800290, G28001200
     - G2800310, G28001700
     - G2800330, G28000100
     - G2800350, G28001800
     - G2800370, G28001600
     - G2800390, G28001900
     - G2800410, G28001700
     - G2800430, G28000700
     - G2800450, G28001900
     - G2800470, G28002000
     - G2800490, G28001000
     - G2800490, G28001100
     - G2800490, G28001200
     - G2800510, G28000700
     - G2800530, G28000800
     - G2800550, G28000800
     - G2800570, G28000400
     - G2800590, G28002100
     - G2800610, G28001400
     - G2800630, G28001600
     - G2800650, G28001700
     - G2800670, G28001700
     - G2800690, G28001400
     - G2800710, G28000400
     - G2800730, G28001800
     - G2800750, G28001500
     - G2800770, G28001600
     - G2800790, G28001400
     - G2800810, G28000500
     - G2800830, G28000700
     - G2800850, G28001600
     - G2800870, G28000600
     - G2800890, G28000900
     - G2800890, G28001000
     - G2800910, G28001800
     - G2800930, G28000200
     - G2800950, G28000400
     - G2800970, G28000700
     - G2800990, G28001400
     - G2801010, G28001500
     - G2801030, G28000600
     - G2801050, G28000600
     - G2801070, G28000300
     - G2801090, G28001900
     - G2801110, G28001800
     - G2801130, G28001600
     - G2801150, G28000500
     - G2801170, G28000200
     - G2801190, G28000300
     - G2801210, G28001300
     - G2801230, G28001400
     - G2801250, G28000800
     - G2801270, G28001300
     - G2801290, G28001400
     - G2801310, G28001900
     - G2801330, G28000800
     - G2801350, G28000300
     - G2801370, G28000300
     - G2801390, G28000200
     - G2801410, G28000200
     - G2801430, G28000300
     - G2801450, G28000500
     - G2801470, G28001600
     - G2801490, G28001200
     - G2801510, G28000800
     - G2801530, G28001700
     - G2801550, G28000600
     - G2801570, G28001600
     - G2801590, G28000600
     - G2801610, G28000700
     - G2801630, G28000900
     - G2900010, G29000300
     - G2900030, G29000200
     - G2900050, G29000100
     - G2900070, G29000400
     - G2900090, G29002700
     - G2900110, G29001200
     - G2900130, G29001100
     - G2900150, G29001300
     - G2900170, G29002200
     - G2900190, G29000600
     - G2900210, G29000200
     - G2900230, G29002400
     - G2900250, G29000800
     - G2900270, G29000500
     - G2900290, G29001400
     - G2900310, G29002200
     - G2900330, G29000700
     - G2900350, G29002400
     - G2900370, G29001100
     - G2900390, G29001200
     - G2900410, G29000700
     - G2900430, G29002601
     - G2900450, G29000300
     - G2900470, G29000901
     - G2900470, G29000902
     - G2900470, G29000903
     - G2900490, G29000800
     - G2900510, G29000500
     - G2900530, G29000700
     - G2900550, G29001500
     - G2900570, G29001200
     - G2900590, G29001300
     - G2900610, G29000100
     - G2900630, G29000200
     - G2900650, G29001500
     - G2900670, G29002500
     - G2900690, G29002300
     - G2900710, G29001600
     - G2900730, G29001500
     - G2900750, G29000100
     - G2900770, G29002601
     - G2900770, G29002602
     - G2900770, G29002603
     - G2900790, G29000100
     - G2900810, G29000100
     - G2900830, G29001200
     - G2900850, G29001300
     - G2900870, G29000100
     - G2900890, G29000700
     - G2900910, G29002500
     - G2900930, G29002400
     - G2900950, G29001001
     - G2900950, G29001002
     - G2900950, G29001003
     - G2900950, G29001004
     - G2900950, G29001005
     - G2900970, G29002800
     - G2900990, G29002001
     - G2900990, G29002002
     - G2901010, G29000800
     - G2901030, G29000300
     - G2901050, G29001300
     - G2901070, G29000800
     - G2901090, G29001200
     - G2901110, G29000300
     - G2901130, G29000400
     - G2901150, G29000100
     - G2901170, G29000100
     - G2901190, G29002700
     - G2901210, G29000300
     - G2901230, G29002400
     - G2901250, G29001500
     - G2901270, G29000300
     - G2901290, G29000100
     - G2901310, G29001400
     - G2901330, G29002300
     - G2901350, G29000500
     - G2901370, G29000300
     - G2901390, G29000400
     - G2901410, G29001400
     - G2901430, G29002300
     - G2901450, G29002800
     - G2901470, G29000100
     - G2901490, G29002500
     - G2901510, G29000500
     - G2901530, G29002500
     - G2901550, G29002300
     - G2901570, G29002100
     - G2901590, G29000700
     - G2901610, G29001500
     - G2901630, G29000400
     - G2901650, G29000903
     - G2901670, G29001300
     - G2901690, G29001400
     - G2901710, G29000100
     - G2901730, G29000300
     - G2901750, G29000700
     - G2901770, G29000800
     - G2901790, G29002400
     - G2901810, G29002400
     - G2901830, G29001701
     - G2901830, G29001702
     - G2901830, G29001703
     - G2901850, G29001200
     - G2901860, G29002100
     - G2901870, G29002100
     - G2901890, G29001801
     - G2901890, G29001802
     - G2901890, G29001803
     - G2901890, G29001804
     - G2901890, G29001805
     - G2901890, G29001806
     - G2901890, G29001807
     - G2901890, G29001808
     - G2901950, G29000700
     - G2901970, G29000300
     - G2901990, G29000300
     - G2902010, G29002200
     - G2902030, G29002500
     - G2902050, G29000300
     - G2902070, G29002300
     - G2902090, G29002700
     - G2902110, G29000100
     - G2902130, G29002700
     - G2902150, G29002500
     - G2902170, G29001200
     - G2902190, G29000400
     - G2902210, G29002100
     - G2902230, G29002400
     - G2902250, G29002601
     - G2902270, G29000100
     - G2902290, G29002500
     - G2905100, G29001901
     - G2905100, G29001902
     - G3000010, G30000300
     - G3000030, G30000600
     - G3000050, G30000400
     - G3000070, G30000300
     - G3000090, G30000500
     - G3000110, G30000600
     - G3000130, G30000400
     - G3000150, G30000400
     - G3000170, G30000600
     - G3000190, G30000600
     - G3000210, G30000600
     - G3000230, G30000300
     - G3000250, G30000600
     - G3000270, G30000400
     - G3000290, G30000100
     - G3000310, G30000500
     - G3000330, G30000600
     - G3000350, G30000100
     - G3000370, G30000600
     - G3000390, G30000300
     - G3000410, G30000400
     - G3000430, G30000300
     - G3000450, G30000400
     - G3000470, G30000200
     - G3000490, G30000300
     - G3000510, G30000400
     - G3000530, G30000100
     - G3000550, G30000600
     - G3000570, G30000300
     - G3000590, G30000400
     - G3000610, G30000200
     - G3000630, G30000200
     - G3000650, G30000600
     - G3000670, G30000500
     - G3000690, G30000400
     - G3000710, G30000600
     - G3000730, G30000400
     - G3000750, G30000600
     - G3000770, G30000300
     - G3000790, G30000600
     - G3000810, G30000200
     - G3000830, G30000600
     - G3000850, G30000600
     - G3000870, G30000600
     - G3000890, G30000200
     - G3000910, G30000600
     - G3000930, G30000300
     - G3000950, G30000500
     - G3000970, G30000500
     - G3000990, G30000400
     - G3001010, G30000400
     - G3001030, G30000600
     - G3001050, G30000600
     - G3001070, G30000400
     - G3001090, G30000600
     - G3001110, G30000600
     - G3001110, G30000700
     - G3100010, G31000500
     - G3100030, G31000200
     - G3100050, G31000400
     - G3100070, G31000100
     - G3100090, G31000300
     - G3100110, G31000200
     - G3100130, G31000100
     - G3100150, G31000100
     - G3100170, G31000100
     - G3100190, G31000500
     - G3100210, G31000200
     - G3100230, G31000600
     - G3100250, G31000701
     - G3100270, G31000200
     - G3100290, G31000400
     - G3100310, G31000100
     - G3100330, G31000100
     - G3100350, G31000500
     - G3100370, G31000200
     - G3100390, G31000200
     - G3100410, G31000300
     - G3100430, G31000200
     - G3100450, G31000100
     - G3100470, G31000400
     - G3100490, G31000100
     - G3100510, G31000200
     - G3100530, G31000701
     - G3100550, G31000901
     - G3100550, G31000902
     - G3100550, G31000903
     - G3100550, G31000904
     - G3100570, G31000400
     - G3100590, G31000600
     - G3100610, G31000500
     - G3100630, G31000400
     - G3100650, G31000400
     - G3100670, G31000600
     - G3100690, G31000100
     - G3100710, G31000300
     - G3100730, G31000400
     - G3100750, G31000400
     - G3100770, G31000300
     - G3100790, G31000300
     - G3100810, G31000300
     - G3100830, G31000500
     - G3100850, G31000400
     - G3100870, G31000400
     - G3100890, G31000100
     - G3100910, G31000400
     - G3100930, G31000300
     - G3100950, G31000600
     - G3100970, G31000600
     - G3100990, G31000500
     - G3101010, G31000400
     - G3101030, G31000100
     - G3101050, G31000100
     - G3101070, G31000200
     - G3101090, G31000801
     - G3101090, G31000802
     - G3101110, G31000400
     - G3101130, G31000400
     - G3101150, G31000300
     - G3101170, G31000400
     - G3101190, G31000200
     - G3101210, G31000300
     - G3101230, G31000100
     - G3101250, G31000200
     - G3101270, G31000600
     - G3101290, G31000500
     - G3101310, G31000600
     - G3101330, G31000600
     - G3101350, G31000400
     - G3101370, G31000500
     - G3101390, G31000200
     - G3101410, G31000200
     - G3101430, G31000600
     - G3101450, G31000400
     - G3101470, G31000600
     - G3101490, G31000100
     - G3101510, G31000600
     - G3101530, G31000702
     - G3101550, G31000701
     - G3101570, G31000100
     - G3101590, G31000600
     - G3101610, G31000100
     - G3101630, G31000300
     - G3101650, G31000100
     - G3101670, G31000200
     - G3101690, G31000600
     - G3101710, G31000400
     - G3101730, G31000200
     - G3101750, G31000300
     - G3101770, G31000701
     - G3101790, G31000200
     - G3101810, G31000500
     - G3101830, G31000300
     - G3101850, G31000600
     - G3200010, G32000300
     - G3200030, G32000401
     - G3200030, G32000402
     - G3200030, G32000403
     - G3200030, G32000404
     - G3200030, G32000405
     - G3200030, G32000406
     - G3200030, G32000407
     - G3200030, G32000408
     - G3200030, G32000409
     - G3200030, G32000410
     - G3200030, G32000411
     - G3200030, G32000412
     - G3200030, G32000413
     - G3200050, G32000200
     - G3200070, G32000300
     - G3200090, G32000300
     - G3200110, G32000300
     - G3200130, G32000300
     - G3200150, G32000300
     - G3200170, G32000300
     - G3200190, G32000200
     - G3200210, G32000300
     - G3200230, G32000300
     - G3200270, G32000300
     - G3200290, G32000200
     - G3200310, G32000101
     - G3200310, G32000102
     - G3200310, G32000103
     - G3200330, G32000300
     - G3205100, G32000200
     - G3300010, G33000200
     - G3300030, G33000200
     - G3300030, G33000300
     - G3300050, G33000500
     - G3300070, G33000100
     - G3300090, G33000100
     - G3300110, G33000600
     - G3300110, G33000700
     - G3300110, G33000800
     - G3300110, G33000900
     - G3300130, G33000200
     - G3300130, G33000400
     - G3300130, G33000700
     - G3300150, G33000300
     - G3300150, G33000700
     - G3300150, G33001000
     - G3300170, G33000300
     - G3300190, G33000500
     - G3400010, G34000101
     - G3400010, G34000102
     - G3400010, G34002600
     - G3400030, G34000301
     - G3400030, G34000302
     - G3400030, G34000303
     - G3400030, G34000304
     - G3400030, G34000305
     - G3400030, G34000306
     - G3400030, G34000307
     - G3400030, G34000308
     - G3400050, G34002001
     - G3400050, G34002002
     - G3400050, G34002003
     - G3400070, G34002101
     - G3400070, G34002102
     - G3400070, G34002103
     - G3400070, G34002104
     - G3400090, G34002600
     - G3400110, G34002400
     - G3400110, G34002500
     - G3400130, G34001301
     - G3400130, G34001302
     - G3400130, G34001401
     - G3400130, G34001402
     - G3400130, G34001403
     - G3400130, G34001404
     - G3400150, G34002201
     - G3400150, G34002202
     - G3400170, G34000601
     - G3400170, G34000602
     - G3400170, G34000701
     - G3400170, G34000702
     - G3400170, G34000703
     - G3400190, G34000800
     - G3400210, G34002301
     - G3400210, G34002302
     - G3400210, G34002303
     - G3400230, G34000901
     - G3400230, G34000902
     - G3400230, G34000903
     - G3400230, G34000904
     - G3400230, G34000905
     - G3400230, G34000906
     - G3400230, G34000907
     - G3400250, G34001101
     - G3400250, G34001102
     - G3400250, G34001103
     - G3400250, G34001104
     - G3400250, G34001105
     - G3400250, G34001106
     - G3400270, G34001501
     - G3400270, G34001502
     - G3400270, G34001503
     - G3400270, G34001504
     - G3400290, G34001201
     - G3400290, G34001202
     - G3400290, G34001203
     - G3400290, G34001204
     - G3400290, G34001205
     - G3400310, G34000400
     - G3400310, G34000501
     - G3400310, G34000502
     - G3400310, G34000503
     - G3400330, G34002500
     - G3400350, G34001001
     - G3400350, G34001002
     - G3400350, G34001003
     - G3400370, G34001600
     - G3400390, G34001800
     - G3400390, G34001901
     - G3400390, G34001902
     - G3400390, G34001903
     - G3400390, G34001904
     - G3400410, G34001700
     - G3500010, G35000700
     - G3500010, G35000801
     - G3500010, G35000802
     - G3500010, G35000803
     - G3500010, G35000804
     - G3500010, G35000805
     - G3500010, G35000806
     - G3500030, G35000900
     - G3500050, G35001100
     - G3500060, G35000100
     - G3500070, G35000400
     - G3500090, G35000400
     - G3500110, G35000400
     - G3500130, G35001001
     - G3500130, G35001002
     - G3500150, G35001200
     - G3500170, G35000900
     - G3500190, G35000400
     - G3500210, G35000400
     - G3500230, G35000900
     - G3500250, G35001200
     - G3500270, G35001100
     - G3500280, G35000300
     - G3500290, G35000900
     - G3500310, G35000100
     - G3500330, G35000300
     - G3500350, G35001100
     - G3500370, G35000400
     - G3500390, G35000300
     - G3500410, G35000400
     - G3500430, G35000600
     - G3500450, G35000100
     - G3500450, G35000200
     - G3500470, G35000300
     - G3500490, G35000500
     - G3500510, G35000900
     - G3500530, G35000900
     - G3500550, G35000300
     - G3500570, G35000900
     - G3500590, G35000400
     - G3500610, G35000700
     - G3600010, G36002001
     - G3600010, G36002002
     - G3600030, G36002500
     - G3600050, G36003701
     - G3600050, G36003702
     - G3600050, G36003703
     - G3600050, G36003704
     - G3600050, G36003705
     - G3600050, G36003706
     - G3600050, G36003707
     - G3600050, G36003708
     - G3600050, G36003709
     - G3600050, G36003710
     - G3600070, G36002201
     - G3600070, G36002202
     - G3600070, G36002203
     - G3600090, G36002500
     - G3600110, G36000704
     - G3600130, G36002600
     - G3600150, G36002401
     - G3600150, G36002402
     - G3600170, G36002203
     - G3600190, G36000200
     - G3600210, G36002100
     - G3600230, G36001500
     - G3600250, G36002203
     - G3600270, G36002801
     - G3600270, G36002802
     - G3600290, G36001201
     - G3600290, G36001202
     - G3600290, G36001203
     - G3600290, G36001204
     - G3600290, G36001205
     - G3600290, G36001206
     - G3600290, G36001207
     - G3600310, G36000200
     - G3600330, G36000200
     - G3600350, G36001600
     - G3600370, G36001000
     - G3600390, G36002100
     - G3600410, G36000200
     - G3600430, G36000401
     - G3600430, G36000403
     - G3600450, G36000500
     - G3600470, G36004001
     - G3600470, G36004002
     - G3600470, G36004003
     - G3600470, G36004004
     - G3600470, G36004005
     - G3600470, G36004006
     - G3600470, G36004007
     - G3600470, G36004008
     - G3600470, G36004009
     - G3600470, G36004010
     - G3600470, G36004011
     - G3600470, G36004012
     - G3600470, G36004013
     - G3600470, G36004014
     - G3600470, G36004015
     - G3600470, G36004016
     - G3600470, G36004017
     - G3600470, G36004018
     - G3600490, G36000500
     - G3600510, G36001300
     - G3600530, G36001500
     - G3600550, G36000901
     - G3600550, G36000902
     - G3600550, G36000903
     - G3600550, G36000904
     - G3600550, G36000905
     - G3600550, G36000906
     - G3600570, G36001600
     - G3600590, G36003201
     - G3600590, G36003202
     - G3600590, G36003203
     - G3600590, G36003204
     - G3600590, G36003205
     - G3600590, G36003206
     - G3600590, G36003207
     - G3600590, G36003208
     - G3600590, G36003209
     - G3600590, G36003210
     - G3600590, G36003211
     - G3600590, G36003212
     - G3600610, G36003801
     - G3600610, G36003802
     - G3600610, G36003803
     - G3600610, G36003804
     - G3600610, G36003805
     - G3600610, G36003806
     - G3600610, G36003807
     - G3600610, G36003808
     - G3600610, G36003809
     - G3600610, G36003810
     - G3600630, G36001101
     - G3600630, G36001102
     - G3600650, G36000401
     - G3600650, G36000402
     - G3600650, G36000403
     - G3600670, G36000701
     - G3600670, G36000702
     - G3600670, G36000703
     - G3600670, G36000704
     - G3600690, G36001400
     - G3600710, G36002901
     - G3600710, G36002902
     - G3600710, G36002903
     - G3600730, G36001000
     - G3600750, G36000600
     - G3600770, G36000403
     - G3600790, G36003101
     - G3600810, G36004101
     - G3600810, G36004102
     - G3600810, G36004103
     - G3600810, G36004104
     - G3600810, G36004105
     - G3600810, G36004106
     - G3600810, G36004107
     - G3600810, G36004108
     - G3600810, G36004109
     - G3600810, G36004110
     - G3600810, G36004111
     - G3600810, G36004112
     - G3600810, G36004113
     - G3600810, G36004114
     - G3600830, G36001900
     - G3600850, G36003901
     - G3600850, G36003902
     - G3600850, G36003903
     - G3600870, G36003001
     - G3600870, G36003002
     - G3600870, G36003003
     - G3600890, G36000100
     - G3600910, G36001801
     - G3600910, G36001802
     - G3600930, G36001700
     - G3600950, G36000403
     - G3600970, G36002402
     - G3600990, G36000800
     - G3601010, G36002401
     - G3601010, G36002402
     - G3601030, G36003301
     - G3601030, G36003302
     - G3601030, G36003303
     - G3601030, G36003304
     - G3601030, G36003305
     - G3601030, G36003306
     - G3601030, G36003307
     - G3601030, G36003308
     - G3601030, G36003309
     - G3601030, G36003310
     - G3601030, G36003311
     - G3601030, G36003312
     - G3601030, G36003313
     - G3601050, G36002701
     - G3601070, G36002202
     - G3601090, G36002300
     - G3601110, G36002701
     - G3601110, G36002702
     - G3601130, G36000300
     - G3601150, G36000300
     - G3601170, G36000800
     - G3601190, G36003101
     - G3601190, G36003102
     - G3601190, G36003103
     - G3601190, G36003104
     - G3601190, G36003105
     - G3601190, G36003106
     - G3601190, G36003107
     - G3601210, G36001300
     - G3601230, G36001400
     - G3700010, G37001600
     - G3700030, G37002000
     - G3700050, G37000200
     - G3700070, G37005300
     - G3700090, G37000100
     - G3700110, G37000100
     - G3700130, G37004400
     - G3700150, G37000800
     - G3700170, G37004900
     - G3700190, G37004800
     - G3700210, G37002201
     - G3700210, G37002202
     - G3700230, G37002100
     - G3700250, G37003200
     - G3700250, G37003300
     - G3700270, G37002000
     - G3700290, G37000700
     - G3700310, G37004400
     - G3700330, G37000400
     - G3700350, G37002800
     - G3700370, G37001500
     - G3700390, G37002400
     - G3700410, G37000700
     - G3700430, G37002400
     - G3700450, G37002600
     - G3700450, G37002700
     - G3700470, G37004900
     - G3700490, G37004300
     - G3700510, G37005001
     - G3700510, G37005002
     - G3700510, G37005003
     - G3700530, G37000700
     - G3700550, G37000800
     - G3700570, G37003500
     - G3700590, G37001900
     - G3700610, G37003900
     - G3700630, G37001301
     - G3700630, G37001302
     - G3700650, G37000900
     - G3700670, G37001801
     - G3700670, G37001802
     - G3700670, G37001803
     - G3700690, G37000500
     - G3700710, G37003001
     - G3700710, G37003002
     - G3700730, G37000700
     - G3700750, G37002300
     - G3700770, G37000400
     - G3700790, G37001000
     - G3700810, G37001701
     - G3700810, G37001702
     - G3700810, G37001703
     - G3700810, G37001704
     - G3700830, G37000600
     - G3700850, G37003800
     - G3700870, G37002300
     - G3700890, G37002500
     - G3700910, G37000600
     - G3700930, G37005200
     - G3700950, G37000800
     - G3700970, G37001900
     - G3700970, G37002900
     - G3700990, G37002300
     - G3700990, G37002400
     - G3701010, G37001100
     - G3701030, G37004100
     - G3701050, G37001500
     - G3701070, G37004100
     - G3701090, G37002700
     - G3701110, G37002100
     - G3701130, G37002400
     - G3701150, G37002300
     - G3701170, G37000800
     - G3701190, G37003101
     - G3701190, G37003102
     - G3701190, G37003103
     - G3701190, G37003104
     - G3701190, G37003105
     - G3701190, G37003106
     - G3701190, G37003107
     - G3701190, G37003108
     - G3701210, G37000100
     - G3701230, G37003700
     - G3701250, G37003700
     - G3701270, G37000900
     - G3701290, G37004600
     - G3701290, G37004700
     - G3701310, G37000600
     - G3701330, G37004100
     - G3701330, G37004500
     - G3701350, G37001400
     - G3701370, G37004400
     - G3701390, G37000700
     - G3701410, G37004600
     - G3701430, G37000700
     - G3701450, G37000400
     - G3701470, G37004200
     - G3701490, G37002600
     - G3701510, G37003600
     - G3701530, G37005200
     - G3701550, G37004900
     - G3701550, G37005100
     - G3701570, G37000300
     - G3701590, G37003400
     - G3701610, G37002600
     - G3701630, G37003900
     - G3701650, G37005200
     - G3701670, G37003300
     - G3701690, G37000300
     - G3701710, G37000200
     - G3701730, G37002300
     - G3701750, G37002500
     - G3701770, G37000800
     - G3701790, G37005300
     - G3701790, G37005400
     - G3701810, G37000500
     - G3701830, G37001201
     - G3701830, G37001202
     - G3701830, G37001203
     - G3701830, G37001204
     - G3701830, G37001205
     - G3701830, G37001206
     - G3701830, G37001207
     - G3701830, G37001208
     - G3701850, G37000500
     - G3701850, G37000600
     - G3701870, G37000800
     - G3701890, G37000100
     - G3701910, G37004000
     - G3701930, G37000200
     - G3701950, G37001000
     - G3701970, G37001900
     - G3701990, G37000100
     - G3800010, G38000100
     - G3800030, G38000200
     - G3800050, G38000200
     - G3800070, G38000100
     - G3800090, G38000200
     - G3800110, G38000100
     - G3800130, G38000100
     - G3800150, G38000300
     - G3800170, G38000500
     - G3800190, G38000400
     - G3800210, G38000200
     - G3800230, G38000100
     - G3800250, G38000100
     - G3800270, G38000200
     - G3800290, G38000300
     - G3800310, G38000200
     - G3800330, G38000100
     - G3800350, G38000400
     - G3800370, G38000100
     - G3800390, G38000400
     - G3800410, G38000100
     - G3800430, G38000300
     - G3800450, G38000200
     - G3800470, G38000300
     - G3800490, G38000100
     - G3800510, G38000300
     - G3800530, G38000100
     - G3800550, G38000100
     - G3800570, G38000100
     - G3800590, G38000300
     - G3800610, G38000100
     - G3800630, G38000200
     - G3800650, G38000100
     - G3800670, G38000400
     - G3800690, G38000200
     - G3800710, G38000200
     - G3800730, G38000200
     - G3800750, G38000100
     - G3800770, G38000200
     - G3800790, G38000200
     - G3800810, G38000200
     - G3800830, G38000200
     - G3800850, G38000100
     - G3800870, G38000100
     - G3800890, G38000100
     - G3800910, G38000400
     - G3800930, G38000200
     - G3800950, G38000400
     - G3800970, G38000400
     - G3800990, G38000400
     - G3801010, G38000100
     - G3801030, G38000200
     - G3801050, G38000100
     - G3900010, G39005200
     - G3900030, G39002500
     - G3900050, G39002100
     - G3900070, G39001300
     - G3900090, G39005000
     - G3900110, G39002600
     - G3900130, G39003500
     - G3900150, G39005700
     - G3900170, G39005401
     - G3900170, G39005402
     - G3900170, G39005403
     - G3900190, G39003300
     - G3900210, G39002700
     - G3900230, G39004300
     - G3900250, G39005600
     - G3900250, G39005700
     - G3900270, G39005200
     - G3900290, G39003400
     - G3900310, G39002900
     - G3900330, G39002300
     - G3900350, G39000901
     - G3900350, G39000902
     - G3900350, G39000903
     - G3900350, G39000904
     - G3900350, G39000905
     - G3900350, G39000906
     - G3900350, G39000907
     - G3900350, G39000908
     - G3900350, G39000909
     - G3900350, G39000910
     - G3900370, G39004500
     - G3900390, G39000100
     - G3900410, G39004000
     - G3900430, G39000700
     - G3900450, G39003900
     - G3900470, G39004800
     - G3900490, G39004101
     - G3900490, G39004102
     - G3900490, G39004103
     - G3900490, G39004104
     - G3900490, G39004105
     - G3900490, G39004106
     - G3900490, G39004107
     - G3900490, G39004108
     - G3900490, G39004109
     - G3900490, G39004110
     - G3900490, G39004111
     - G3900510, G39000200
     - G3900530, G39005000
     - G3900550, G39001200
     - G3900570, G39004700
     - G3900590, G39002900
     - G3900610, G39005501
     - G3900610, G39005502
     - G3900610, G39005503
     - G3900610, G39005504
     - G3900610, G39005505
     - G3900610, G39005506
     - G3900610, G39005507
     - G3900630, G39002400
     - G3900650, G39002700
     - G3900670, G39003000
     - G3900690, G39000100
     - G3900710, G39005200
     - G3900730, G39004900
     - G3900750, G39002900
     - G3900770, G39002100
     - G3900790, G39004900
     - G3900810, G39003500
     - G3900830, G39002800
     - G3900850, G39001000
     - G3900850, G39001100
     - G3900850, G39001200
     - G3900870, G39005100
     - G3900890, G39003800
     - G3900910, G39002700
     - G3900930, G39000801
     - G3900930, G39000802
     - G3900950, G39000200
     - G3900950, G39000300
     - G3900950, G39000400
     - G3900950, G39000500
     - G3900950, G39000600
     - G3900970, G39004200
     - G3900990, G39001400
     - G3900990, G39001500
     - G3901010, G39002800
     - G3901030, G39001900
     - G3901050, G39005000
     - G3901070, G39002600
     - G3901090, G39004400
     - G3901110, G39003600
     - G3901130, G39004601
     - G3901130, G39004602
     - G3901130, G39004603
     - G3901130, G39004604
     - G3901150, G39003600
     - G3901170, G39002800
     - G3901190, G39003700
     - G3901210, G39003600
     - G3901230, G39000600
     - G3901250, G39000100
     - G3901270, G39003700
     - G3901290, G39004200
     - G3901310, G39004900
     - G3901330, G39001700
     - G3901350, G39004500
     - G3901370, G39002400
     - G3901390, G39002200
     - G3901410, G39004800
     - G3901430, G39000700
     - G3901450, G39005100
     - G3901470, G39002300
     - G3901490, G39004500
     - G3901510, G39003100
     - G3901510, G39003200
     - G3901510, G39003300
     - G3901530, G39001801
     - G3901530, G39001802
     - G3901530, G39001803
     - G3901530, G39001804
     - G3901530, G39001805
     - G3901550, G39001400
     - G3901550, G39001600
     - G3901570, G39003000
     - G3901590, G39004200
     - G3901610, G39002600
     - G3901630, G39004900
     - G3901650, G39005301
     - G3901650, G39005302
     - G3901670, G39003600
     - G3901690, G39002000
     - G3901710, G39000100
     - G3901730, G39000200
     - G3901730, G39000300
     - G3901730, G39000600
     - G3901750, G39002300
     - G4000010, G40000200
     - G4000030, G40000500
     - G4000050, G40000702
     - G4000070, G40000500
     - G4000090, G40000400
     - G4000110, G40000500
     - G4000130, G40000702
     - G4000150, G40000602
     - G4000170, G40000800
     - G4000190, G40000701
     - G4000210, G40000200
     - G4000230, G40000300
     - G4000250, G40000500
     - G4000270, G40000900
     - G4000290, G40000702
     - G4000310, G40000601
     - G4000310, G40000602
     - G4000330, G40000602
     - G4000350, G40000100
     - G4000370, G40001204
     - G4000370, G40001501
     - G4000370, G40001601
     - G4000390, G40000400
     - G4000410, G40000100
     - G4000430, G40000500
     - G4000450, G40000500
     - G4000470, G40001400
     - G4000490, G40000701
     - G4000510, G40001101
     - G4000530, G40000500
     - G4000550, G40000400
     - G4000570, G40000400
     - G4000590, G40000500
     - G4000610, G40000300
     - G4000630, G40001501
     - G4000650, G40000400
     - G4000670, G40000602
     - G4000690, G40000702
     - G4000710, G40001400
     - G4000730, G40000500
     - G4000750, G40000400
     - G4000770, G40000300
     - G4000790, G40000300
     - G4000810, G40001102
     - G4000830, G40001102
     - G4000850, G40000701
     - G4000870, G40001101
     - G4000890, G40000300
     - G4000910, G40001302
     - G4000930, G40000500
     - G4000950, G40000702
     - G4000970, G40000100
     - G4000990, G40000701
     - G4001010, G40001302
     - G4001030, G40001400
     - G4001050, G40000100
     - G4001070, G40001501
     - G4001090, G40001001
     - G4001090, G40001002
     - G4001090, G40001003
     - G4001090, G40001004
     - G4001090, G40001005
     - G4001090, G40001006
     - G4001110, G40001302
     - G4001130, G40001204
     - G4001130, G40001601
     - G4001150, G40000100
     - G4001170, G40001601
     - G4001190, G40001501
     - G4001210, G40000300
     - G4001230, G40000701
     - G4001230, G40000702
     - G4001250, G40001101
     - G4001250, G40001102
     - G4001270, G40000300
     - G4001290, G40000400
     - G4001310, G40000100
     - G4001310, G40001301
     - G4001330, G40001501
     - G4001350, G40000200
     - G4001370, G40000602
     - G4001390, G40000500
     - G4001410, G40000602
     - G4001430, G40001201
     - G4001430, G40001202
     - G4001430, G40001203
     - G4001430, G40001204
     - G4001450, G40001301
     - G4001450, G40001302
     - G4001470, G40001601
     - G4001490, G40000400
     - G4001510, G40000500
     - G4001530, G40000500
     - G4100010, G41000100
     - G4100030, G41000600
     - G4100050, G41001317
     - G4100050, G41001318
     - G4100050, G41001319
     - G4100070, G41000500
     - G4100090, G41000500
     - G4100110, G41000800
     - G4100130, G41000200
     - G4100150, G41000800
     - G4100170, G41000400
     - G4100190, G41001000
     - G4100210, G41000200
     - G4100230, G41000200
     - G4100250, G41000300
     - G4100270, G41000200
     - G4100290, G41000901
     - G4100290, G41000902
     - G4100310, G41000200
     - G4100330, G41000800
     - G4100350, G41000300
     - G4100370, G41000300
     - G4100390, G41000703
     - G4100390, G41000704
     - G4100390, G41000705
     - G4100410, G41000500
     - G4100430, G41000600
     - G4100450, G41000300
     - G4100470, G41001103
     - G4100470, G41001104
     - G4100470, G41001105
     - G4100490, G41000200
     - G4100510, G41001301
     - G4100510, G41001302
     - G4100510, G41001303
     - G4100510, G41001305
     - G4100510, G41001314
     - G4100510, G41001316
     - G4100530, G41001200
     - G4100550, G41000200
     - G4100570, G41000500
     - G4100590, G41000100
     - G4100610, G41000100
     - G4100630, G41000100
     - G4100650, G41000200
     - G4100670, G41001320
     - G4100670, G41001321
     - G4100670, G41001322
     - G4100670, G41001323
     - G4100670, G41001324
     - G4100690, G41000200
     - G4100710, G41001200
     - G4200010, G42003701
     - G4200030, G42001701
     - G4200030, G42001702
     - G4200030, G42001801
     - G4200030, G42001802
     - G4200030, G42001803
     - G4200030, G42001804
     - G4200030, G42001805
     - G4200030, G42001806
     - G4200030, G42001807
     - G4200050, G42001900
     - G4200070, G42001501
     - G4200070, G42001502
     - G4200090, G42003800
     - G4200110, G42002701
     - G4200110, G42002702
     - G4200110, G42002703
     - G4200130, G42002200
     - G4200150, G42000400
     - G4200170, G42003001
     - G4200170, G42003002
     - G4200170, G42003003
     - G4200170, G42003004
     - G4200190, G42001600
     - G4200210, G42002100
     - G4200230, G42000300
     - G4200250, G42002801
     - G4200270, G42001200
     - G4200290, G42003401
     - G4200290, G42003402
     - G4200290, G42003403
     - G4200290, G42003404
     - G4200310, G42001300
     - G4200330, G42000300
     - G4200350, G42000900
     - G4200370, G42000803
     - G4200390, G42000200
     - G4200410, G42002301
     - G4200410, G42002302
     - G4200430, G42002401
     - G4200430, G42002402
     - G4200450, G42003301
     - G4200450, G42003302
     - G4200450, G42003303
     - G4200450, G42003304
     - G4200470, G42000300
     - G4200490, G42000101
     - G4200490, G42000102
     - G4200510, G42003900
     - G4200530, G42001300
     - G4200550, G42003701
     - G4200550, G42003702
     - G4200570, G42003800
     - G4200590, G42004002
     - G4200610, G42002200
     - G4200630, G42001900
     - G4200650, G42001300
     - G4200670, G42001100
     - G4200690, G42000701
     - G4200690, G42000702
     - G4200710, G42003501
     - G4200710, G42003502
     - G4200710, G42003503
     - G4200710, G42003504
     - G4200730, G42001501
     - G4200750, G42002500
     - G4200770, G42002801
     - G4200770, G42002802
     - G4200770, G42002803
     - G4200770, G42002901
     - G4200790, G42000801
     - G4200790, G42000802
     - G4200790, G42000803
     - G4200810, G42000900
     - G4200830, G42000300
     - G4200850, G42001400
     - G4200870, G42001100
     - G4200890, G42000600
     - G4200910, G42003101
     - G4200910, G42003102
     - G4200910, G42003103
     - G4200910, G42003104
     - G4200910, G42003105
     - G4200910, G42003106
     - G4200930, G42001000
     - G4200950, G42002901
     - G4200950, G42002902
     - G4200970, G42001000
     - G4200990, G42002301
     - G4201010, G42003201
     - G4201010, G42003202
     - G4201010, G42003203
     - G4201010, G42003204
     - G4201010, G42003205
     - G4201010, G42003206
     - G4201010, G42003207
     - G4201010, G42003208
     - G4201010, G42003209
     - G4201010, G42003210
     - G4201010, G42003211
     - G4201030, G42000500
     - G4201050, G42000300
     - G4201070, G42002600
     - G4201090, G42001100
     - G4201110, G42003800
     - G4201130, G42000400
     - G4201150, G42000500
     - G4201170, G42000400
     - G4201190, G42001100
     - G4201210, G42001300
     - G4201230, G42000200
     - G4201250, G42004001
     - G4201250, G42004002
     - G4201270, G42000500
     - G4201290, G42002001
     - G4201290, G42002002
     - G4201290, G42002003
     - G4201310, G42000702
     - G4201330, G42003601
     - G4201330, G42003602
     - G4201330, G42003603
     - G4400010, G44000300
     - G4400030, G44000201
     - G4400050, G44000300
     - G4400070, G44000101
     - G4400070, G44000102
     - G4400070, G44000103
     - G4400070, G44000104
     - G4400090, G44000400
     - G4500010, G45001600
     - G4500030, G45001500
     - G4500050, G45001300
     - G4500070, G45000200
     - G4500090, G45001300
     - G4500110, G45001300
     - G4500130, G45001400
     - G4500150, G45001201
     - G4500150, G45001202
     - G4500150, G45001203
     - G4500150, G45001204
     - G4500170, G45000605
     - G4500190, G45001201
     - G4500190, G45001202
     - G4500190, G45001203
     - G4500190, G45001204
     - G4500210, G45000400
     - G4500230, G45000400
     - G4500250, G45000700
     - G4500270, G45000800
     - G4500290, G45001300
     - G4500310, G45000900
     - G4500330, G45001000
     - G4500350, G45001201
     - G4500350, G45001204
     - G4500370, G45001500
     - G4500390, G45000603
     - G4500410, G45000900
     - G4500430, G45001000
     - G4500450, G45000102
     - G4500450, G45000103
     - G4500450, G45000104
     - G4500450, G45000105
     - G4500470, G45001600
     - G4500490, G45001300
     - G4500510, G45001101
     - G4500510, G45001102
     - G4500530, G45001400
     - G4500550, G45000605
     - G4500570, G45000700
     - G4500590, G45000105
     - G4500610, G45000800
     - G4500630, G45000601
     - G4500630, G45000602
     - G4500650, G45001600
     - G4500670, G45001000
     - G4500690, G45000700
     - G4500710, G45000400
     - G4500730, G45000101
     - G4500750, G45001300
     - G4500770, G45000101
     - G4500790, G45000603
     - G4500790, G45000604
     - G4500790, G45000605
     - G4500810, G45000601
     - G4500830, G45000301
     - G4500830, G45000302
     - G4500850, G45000800
     - G4500870, G45000400
     - G4500890, G45000800
     - G4500910, G45000501
     - G4500910, G45000502
     - G4600030, G46000400
     - G4600050, G46000400
     - G4600070, G46000200
     - G4600090, G46000400
     - G4600110, G46000400
     - G4600130, G46000300
     - G4600150, G46000400
     - G4600170, G46000200
     - G4600190, G46000100
     - G4600210, G46000300
     - G4600230, G46000200
     - G4600250, G46000300
     - G4600270, G46000500
     - G4600290, G46000300
     - G4600310, G46000200
     - G4600330, G46000100
     - G4600350, G46000400
     - G4600370, G46000300
     - G4600390, G46000300
     - G4600410, G46000200
     - G4600430, G46000400
     - G4600450, G46000300
     - G4600470, G46000200
     - G4600490, G46000300
     - G4600510, G46000300
     - G4600530, G46000200
     - G4600550, G46000200
     - G4600570, G46000300
     - G4600590, G46000400
     - G4600610, G46000400
     - G4600630, G46000100
     - G4600650, G46000200
     - G4600670, G46000400
     - G4600690, G46000200
     - G4600710, G46000200
     - G4600730, G46000400
     - G4600750, G46000200
     - G4600770, G46000400
     - G4600790, G46000400
     - G4600810, G46000100
     - G4600830, G46000500
     - G4600830, G46000600
     - G4600850, G46000200
     - G4600870, G46000500
     - G4600890, G46000300
     - G4600910, G46000300
     - G4600930, G46000100
     - G4600950, G46000200
     - G4600970, G46000400
     - G4600990, G46000500
     - G4600990, G46000600
     - G4601010, G46000400
     - G4601020, G46000200
     - G4601030, G46000100
     - G4601050, G46000100
     - G4601070, G46000300
     - G4601090, G46000300
     - G4601110, G46000400
     - G4601150, G46000300
     - G4601170, G46000200
     - G4601190, G46000200
     - G4601210, G46000200
     - G4601230, G46000200
     - G4601250, G46000500
     - G4601270, G46000500
     - G4601290, G46000300
     - G4601350, G46000500
     - G4601370, G46000200
     - G4700010, G47001601
     - G4700030, G47002700
     - G4700050, G47000200
     - G4700070, G47002100
     - G4700090, G47001700
     - G4700110, G47001900
     - G4700130, G47000900
     - G4700150, G47000600
     - G4700170, G47000200
     - G4700190, G47001200
     - G4700210, G47000400
     - G4700230, G47003000
     - G4700250, G47000900
     - G4700270, G47000700
     - G4700290, G47001400
     - G4700310, G47002200
     - G4700330, G47000100
     - G4700350, G47000800
     - G4700370, G47002501
     - G4700370, G47002502
     - G4700370, G47002503
     - G4700370, G47002504
     - G4700370, G47002505
     - G4700390, G47002900
     - G4700410, G47000600
     - G4700430, G47000400
     - G4700450, G47000100
     - G4700470, G47003100
     - G4700490, G47000800
     - G4700510, G47002200
     - G4700530, G47000100
     - G4700550, G47002800
     - G4700570, G47001400
     - G4700590, G47001200
     - G4700610, G47002100
     - G4700630, G47001400
     - G4700650, G47002001
     - G4700650, G47002002
     - G4700650, G47002003
     - G4700670, G47000900
     - G4700690, G47002900
     - G4700710, G47002900
     - G4700730, G47001000
     - G4700750, G47002900
     - G4700770, G47002900
     - G4700790, G47000200
     - G4700810, G47000400
     - G4700830, G47000200
     - G4700850, G47000200
     - G4700870, G47000700
     - G4700890, G47001500
     - G4700910, G47001200
     - G4700930, G47001601
     - G4700930, G47001602
     - G4700930, G47001603
     - G4700930, G47001604
     - G4700950, G47000100
     - G4700970, G47003100
     - G4700990, G47002800
     - G4701010, G47002800
     - G4701030, G47002200
     - G4701050, G47001800
     - G4701070, G47001900
     - G4701090, G47002900
     - G4701110, G47000600
     - G4701130, G47003000
     - G4701150, G47002100
     - G4701170, G47002700
     - G4701190, G47002700
     - G4701210, G47002100
     - G4701230, G47001800
     - G4701250, G47000300
     - G4701270, G47002200
     - G4701290, G47000900
     - G4701310, G47000100
     - G4701330, G47000700
     - G4701350, G47002800
     - G4701370, G47000700
     - G4701390, G47001900
     - G4701410, G47000700
     - G4701430, G47002100
     - G4701450, G47001800
     - G4701470, G47000400
     - G4701490, G47002401
     - G4701490, G47002402
     - G4701510, G47000900
     - G4701530, G47002100
     - G4701550, G47001500
     - G4701570, G47003201
     - G4701570, G47003202
     - G4701570, G47003203
     - G4701570, G47003204
     - G4701570, G47003205
     - G4701570, G47003206
     - G4701570, G47003207
     - G4701570, G47003208
     - G4701590, G47000600
     - G4701610, G47000300
     - G4701630, G47001000
     - G4701630, G47001100
     - G4701650, G47000500
     - G4701670, G47003100
     - G4701690, G47000600
     - G4701710, G47001200
     - G4701730, G47001601
     - G4701750, G47000800
     - G4701770, G47000600
     - G4701790, G47001300
     - G4701810, G47002800
     - G4701830, G47000200
     - G4701850, G47000800
     - G4701870, G47002600
     - G4701890, G47002300
     - G4800010, G48001800
     - G4800030, G48003200
     - G4800050, G48004000
     - G4800070, G48006500
     - G4800090, G48000600
     - G4800110, G48000100
     - G4800130, G48006100
     - G4800150, G48005000
     - G4800170, G48000400
     - G4800190, G48006100
     - G4800210, G48005100
     - G4800230, G48000600
     - G4800250, G48006500
     - G4800270, G48003501
     - G4800270, G48003502
     - G4800290, G48005901
     - G4800290, G48005902
     - G4800290, G48005903
     - G4800290, G48005904
     - G4800290, G48005905
     - G4800290, G48005906
     - G4800290, G48005907
     - G4800290, G48005908
     - G4800290, G48005909
     - G4800290, G48005910
     - G4800290, G48005911
     - G4800290, G48005912
     - G4800290, G48005913
     - G4800290, G48005914
     - G4800290, G48005915
     - G4800290, G48005916
     - G4800310, G48006000
     - G4800330, G48002800
     - G4800350, G48003700
     - G4800370, G48001100
     - G4800390, G48004801
     - G4800390, G48004802
     - G4800390, G48004803
     - G4800410, G48003602
     - G4800430, G48003200
     - G4800450, G48000100
     - G4800470, G48006900
     - G4800490, G48002600
     - G4800510, G48003601
     - G4800530, G48003400
     - G4800550, G48005100
     - G4800570, G48005600
     - G4800590, G48002600
     - G4800610, G48006701
     - G4800610, G48006702
     - G4800610, G48006703
     - G4800630, G48001300
     - G4800650, G48000100
     - G4800670, G48001100
     - G4800690, G48000100
     - G4800710, G48004400
     - G4800730, G48001700
     - G4800750, G48000100
     - G4800770, G48000600
     - G4800790, G48000400
     - G4800810, G48002800
     - G4800830, G48002600
     - G4800850, G48001901
     - G4800850, G48001902
     - G4800850, G48001903
     - G4800850, G48001904
     - G4800850, G48001905
     - G4800850, G48001906
     - G4800850, G48001907
     - G4800870, G48000100
     - G4800890, G48005000
     - G4800910, G48005800
     - G4800930, G48002600
     - G4800950, G48002800
     - G4800970, G48000800
     - G4800990, G48003400
     - G4801010, G48000600
     - G4801030, G48003200
     - G4801050, G48002800
     - G4801070, G48000400
     - G4801090, G48003200
     - G4801110, G48000100
     - G4801130, G48002301
     - G4801130, G48002302
     - G4801130, G48002303
     - G4801130, G48002304
     - G4801130, G48002305
     - G4801130, G48002306
     - G4801130, G48002307
     - G4801130, G48002308
     - G4801130, G48002309
     - G4801130, G48002310
     - G4801130, G48002311
     - G4801130, G48002312
     - G4801130, G48002313
     - G4801130, G48002314
     - G4801130, G48002315
     - G4801130, G48002316
     - G4801130, G48002317
     - G4801130, G48002318
     - G4801130, G48002319
     - G4801130, G48002320
     - G4801130, G48002321
     - G4801130, G48002322
     - G4801150, G48002800
     - G4801170, G48000100
     - G4801190, G48001000
     - G4801210, G48002001
     - G4801210, G48002002
     - G4801210, G48002003
     - G4801210, G48002004
     - G4801210, G48002005
     - G4801210, G48002006
     - G4801230, G48005500
     - G4801250, G48000400
     - G4801270, G48006200
     - G4801290, G48000100
     - G4801310, G48006400
     - G4801330, G48002600
     - G4801350, G48003100
     - G4801370, G48006200
     - G4801390, G48002101
     - G4801410, G48003301
     - G4801410, G48003302
     - G4801410, G48003303
     - G4801410, G48003304
     - G4801410, G48003305
     - G4801410, G48003306
     - G4801430, G48002200
     - G4801450, G48003700
     - G4801470, G48000800
     - G4801490, G48005100
     - G4801510, G48002600
     - G4801530, G48000400
     - G4801550, G48000600
     - G4801570, G48004901
     - G4801570, G48004902
     - G4801570, G48004903
     - G4801570, G48004904
     - G4801570, G48004905
     - G4801590, G48001000
     - G4801610, G48003700
     - G4801630, G48006100
     - G4801650, G48003200
     - G4801670, G48004701
     - G4801670, G48004702
     - G4801690, G48000400
     - G4801710, G48006000
     - G4801730, G48002800
     - G4801750, G48005500
     - G4801770, G48005500
     - G4801790, G48000100
     - G4801810, G48000800
     - G4801830, G48001600
     - G4801850, G48003601
     - G4801870, G48005700
     - G4801890, G48000400
     - G4801910, G48000100
     - G4801930, G48003400
     - G4801950, G48000100
     - G4801970, G48000600
     - G4801990, G48004200
     - G4802010, G48004601
     - G4802010, G48004602
     - G4802010, G48004603
     - G4802010, G48004604
     - G4802010, G48004605
     - G4802010, G48004606
     - G4802010, G48004607
     - G4802010, G48004608
     - G4802010, G48004609
     - G4802010, G48004610
     - G4802010, G48004611
     - G4802010, G48004612
     - G4802010, G48004613
     - G4802010, G48004614
     - G4802010, G48004615
     - G4802010, G48004616
     - G4802010, G48004617
     - G4802010, G48004618
     - G4802010, G48004619
     - G4802010, G48004620
     - G4802010, G48004621
     - G4802010, G48004622
     - G4802010, G48004623
     - G4802010, G48004624
     - G4802010, G48004625
     - G4802010, G48004626
     - G4802010, G48004627
     - G4802010, G48004628
     - G4802010, G48004629
     - G4802010, G48004630
     - G4802010, G48004631
     - G4802010, G48004632
     - G4802010, G48004633
     - G4802010, G48004634
     - G4802010, G48004635
     - G4802010, G48004636
     - G4802010, G48004637
     - G4802010, G48004638
     - G4802030, G48001200
     - G4802050, G48000100
     - G4802070, G48002600
     - G4802090, G48005400
     - G4802110, G48000100
     - G4802130, G48001800
     - G4802150, G48006801
     - G4802150, G48006802
     - G4802150, G48006803
     - G4802150, G48006804
     - G4802150, G48006805
     - G4802150, G48006806
     - G4802150, G48006807
     - G4802170, G48003700
     - G4802190, G48000400
     - G4802210, G48002200
     - G4802230, G48001000
     - G4802250, G48003900
     - G4802270, G48002800
     - G4802290, G48003200
     - G4802310, G48000900
     - G4802330, G48000100
     - G4802350, G48002800
     - G4802370, G48000600
     - G4802390, G48005500
     - G4802410, G48004100
     - G4802430, G48003200
     - G4802450, G48004301
     - G4802450, G48004302
     - G4802470, G48006400
     - G4802490, G48006900
     - G4802510, G48002102
     - G4802530, G48002600
     - G4802550, G48005500
     - G4802570, G48001400
     - G4802590, G48006000
     - G4802610, G48006900
     - G4802630, G48002600
     - G4802650, G48006000
     - G4802670, G48002800
     - G4802690, G48000400
     - G4802710, G48006200
     - G4802730, G48006900
     - G4802750, G48002600
     - G4802770, G48001000
     - G4802790, G48000400
     - G4802810, G48003400
     - G4802830, G48006200
     - G4802850, G48005500
     - G4802870, G48005100
     - G4802890, G48003601
     - G4802910, G48004400
     - G4802930, G48003700
     - G4802950, G48000100
     - G4802970, G48006400
     - G4802990, G48003400
     - G4803010, G48003200
     - G4803030, G48000501
     - G4803030, G48000502
     - G4803050, G48000400
     - G4803070, G48002800
     - G4803090, G48003801
     - G4803090, G48003802
     - G4803110, G48006400
     - G4803130, G48003601
     - G4803150, G48001200
     - G4803170, G48002800
     - G4803190, G48002800
     - G4803210, G48005000
     - G4803230, G48006200
     - G4803250, G48006100
     - G4803270, G48002800
     - G4803290, G48003000
     - G4803310, G48003601
     - G4803330, G48003400
     - G4803350, G48002600
     - G4803370, G48000600
     - G4803390, G48004501
     - G4803390, G48004502
     - G4803390, G48004503
     - G4803390, G48004504
     - G4803410, G48000100
     - G4803430, G48001000
     - G4803450, G48000400
     - G4803470, G48004000
     - G4803490, G48003700
     - G4803510, G48004100
     - G4803530, G48002600
     - G4803550, G48006601
     - G4803550, G48006602
     - G4803550, G48006603
     - G4803570, G48000100
     - G4803590, G48000100
     - G4803610, G48004200
     - G4803630, G48002200
     - G4803650, G48001700
     - G4803670, G48002400
     - G4803690, G48000100
     - G4803710, G48003200
     - G4803730, G48003900
     - G4803750, G48000200
     - G4803770, G48003200
     - G4803790, G48001300
     - G4803810, G48000300
     - G4803830, G48002800
     - G4803850, G48006200
     - G4803870, G48001000
     - G4803890, G48003200
     - G4803910, G48006500
     - G4803930, G48000100
     - G4803950, G48003601
     - G4803970, G48000900
     - G4803990, G48002600
     - G4804010, G48001700
     - G4804030, G48004100
     - G4804050, G48004100
     - G4804070, G48003900
     - G4804090, G48006500
     - G4804110, G48003400
     - G4804130, G48002800
     - G4804150, G48002600
     - G4804170, G48002600
     - G4804190, G48004100
     - G4804210, G48000100
     - G4804230, G48001501
     - G4804230, G48001502
     - G4804250, G48002200
     - G4804270, G48006400
     - G4804290, G48002600
     - G4804310, G48002800
     - G4804330, G48002600
     - G4804350, G48002800
     - G4804370, G48000100
     - G4804390, G48002501
     - G4804390, G48002502
     - G4804390, G48002503
     - G4804390, G48002504
     - G4804390, G48002505
     - G4804390, G48002506
     - G4804390, G48002507
     - G4804390, G48002508
     - G4804390, G48002509
     - G4804390, G48002510
     - G4804390, G48002511
     - G4804390, G48002512
     - G4804390, G48002513
     - G4804390, G48002514
     - G4804390, G48002515
     - G4804390, G48002516
     - G4804410, G48002700
     - G4804430, G48003200
     - G4804450, G48000400
     - G4804470, G48002600
     - G4804490, G48001000
     - G4804510, G48002900
     - G4804530, G48005301
     - G4804530, G48005302
     - G4804530, G48005303
     - G4804530, G48005304
     - G4804530, G48005305
     - G4804530, G48005306
     - G4804530, G48005307
     - G4804530, G48005308
     - G4804530, G48005309
     - G4804550, G48003900
     - G4804570, G48004100
     - G4804590, G48001200
     - G4804610, G48002800
     - G4804630, G48006200
     - G4804650, G48006200
     - G4804670, G48001300
     - G4804690, G48005600
     - G4804710, G48003900
     - G4804730, G48005000
     - G4804750, G48003200
     - G4804770, G48003601
     - G4804790, G48006301
     - G4804790, G48006302
     - G4804810, G48005000
     - G4804830, G48000100
     - G4804850, G48000700
     - G4804870, G48000600
     - G4804890, G48006900
     - G4804910, G48005201
     - G4804910, G48005202
     - G4804910, G48005203
     - G4804910, G48005204
     - G4804930, G48005500
     - G4804950, G48003200
     - G4804970, G48000600
     - G4804990, G48001300
     - G4805010, G48000400
     - G4805030, G48000600
     - G4805050, G48006400
     - G4805070, G48006200
     - G4900010, G49021001
     - G4900030, G49003001
     - G4900050, G49005001
     - G4900070, G49013001
     - G4900090, G49013001
     - G4900110, G49011001
     - G4900110, G49011002
     - G4900130, G49013001
     - G4900150, G49013001
     - G4900170, G49021001
     - G4900190, G49013001
     - G4900210, G49021001
     - G4900230, G49021001
     - G4900250, G49021001
     - G4900270, G49021001
     - G4900290, G49005001
     - G4900310, G49021001
     - G4900330, G49005001
     - G4900350, G49035001
     - G4900350, G49035002
     - G4900350, G49035003
     - G4900350, G49035004
     - G4900350, G49035005
     - G4900350, G49035006
     - G4900350, G49035007
     - G4900350, G49035008
     - G4900350, G49035009
     - G4900370, G49013001
     - G4900390, G49021001
     - G4900410, G49021001
     - G4900430, G49005001
     - G4900450, G49003001
     - G4900470, G49013001
     - G4900490, G49049001
     - G4900490, G49049002
     - G4900490, G49049003
     - G4900490, G49049004
     - G4900510, G49013001
     - G4900530, G49053001
     - G4900550, G49021001
     - G4900570, G49057001
     - G4900570, G49057002
     - G5000010, G50000400
     - G5000030, G50000400
     - G5000050, G50000200
     - G5000070, G50000100
     - G5000090, G50000200
     - G5000110, G50000100
     - G5000130, G50000100
     - G5000150, G50000200
     - G5000170, G50000300
     - G5000190, G50000200
     - G5000210, G50000400
     - G5000230, G50000200
     - G5000250, G50000300
     - G5000270, G50000300
     - G5100010, G51051125
     - G5100030, G51051089
     - G5100030, G51051090
     - G5100050, G51051045
     - G5100070, G51051105
     - G5100090, G51051095
     - G5100110, G51051095
     - G5100130, G51001301
     - G5100130, G51001302
     - G5100150, G51051080
     - G5100170, G51051080
     - G5100190, G51051095
     - G5100210, G51051020
     - G5100230, G51051045
     - G5100250, G51051105
     - G5100270, G51051010
     - G5100290, G51051105
     - G5100310, G51051096
     - G5100330, G51051120
     - G5100350, G51051020
     - G5100360, G51051215
     - G5100370, G51051105
     - G5100410, G51004101
     - G5100410, G51004102
     - G5100410, G51004103
     - G5100430, G51051084
     - G5100450, G51051045
     - G5100470, G51051087
     - G5100490, G51051105
     - G5100510, G51051010
     - G5100530, G51051135
     - G5100570, G51051125
     - G5100590, G51059301
     - G5100590, G51059302
     - G5100590, G51059303
     - G5100590, G51059304
     - G5100590, G51059305
     - G5100590, G51059306
     - G5100590, G51059307
     - G5100590, G51059308
     - G5100590, G51059309
     - G5100610, G51051087
     - G5100630, G51051040
     - G5100650, G51051089
     - G5100670, G51051045
     - G5100690, G51051084
     - G5100710, G51051040
     - G5100730, G51051125
     - G5100750, G51051215
     - G5100770, G51051020
     - G5100790, G51051090
     - G5100810, G51051135
     - G5100830, G51051105
     - G5100850, G51051215
     - G5100870, G51051224
     - G5100870, G51051225
     - G5100890, G51051097
     - G5100910, G51051080
     - G5100930, G51051145
     - G5100950, G51051206
     - G5100970, G51051125
     - G5100990, G51051120
     - G5101010, G51051215
     - G5101030, G51051125
     - G5101050, G51051010
     - G5101070, G51010701
     - G5101070, G51010702
     - G5101070, G51010703
     - G5101090, G51051089
     - G5101110, G51051105
     - G5101130, G51051087
     - G5101150, G51051125
     - G5101170, G51051105
     - G5101190, G51051125
     - G5101210, G51051040
     - G5101250, G51051089
     - G5101270, G51051215
     - G5101310, G51051125
     - G5101330, G51051125
     - G5101350, G51051105
     - G5101370, G51051087
     - G5101390, G51051085
     - G5101410, G51051097
     - G5101430, G51051097
     - G5101450, G51051215
     - G5101470, G51051105
     - G5101490, G51051135
     - G5101530, G51051244
     - G5101530, G51051245
     - G5101530, G51051246
     - G5101550, G51051040
     - G5101570, G51051087
     - G5101590, G51051125
     - G5101610, G51051044
     - G5101610, G51051045
     - G5101630, G51051080
     - G5101650, G51051110
     - G5101670, G51051010
     - G5101690, G51051010
     - G5101710, G51051085
     - G5101730, G51051020
     - G5101750, G51051145
     - G5101770, G51051120
     - G5101790, G51051115
     - G5101810, G51051135
     - G5101830, G51051135
     - G5101850, G51051010
     - G5101870, G51051085
     - G5101910, G51051020
     - G5101930, G51051125
     - G5101950, G51051010
     - G5101970, G51051020
     - G5101990, G51051206
     - G5105100, G51051255
     - G5105200, G51051020
     - G5105300, G51051080
     - G5105400, G51051090
     - G5105500, G51055001
     - G5105500, G51055002
     - G5105700, G51051135
     - G5105800, G51051045
     - G5105900, G51051097
     - G5105950, G51051135
     - G5106000, G51059303
     - G5106100, G51059308
     - G5106200, G51051145
     - G5106300, G51051115
     - G5106400, G51051020
     - G5106500, G51051186
     - G5106600, G51051110
     - G5106700, G51051135
     - G5106780, G51051080
     - G5106800, G51051096
     - G5106830, G51051245
     - G5106850, G51051245
     - G5106900, G51051097
     - G5107000, G51051175
     - G5107100, G51051154
     - G5107100, G51051155
     - G5107200, G51051010
     - G5107300, G51051135
     - G5107350, G51051206
     - G5107400, G51051155
     - G5107500, G51051040
     - G5107600, G51051235
     - G5107700, G51051044
     - G5107750, G51051044
     - G5107900, G51051080
     - G5108000, G51051145
     - G5108100, G51051164
     - G5108100, G51051165
     - G5108100, G51051167
     - G5108200, G51051080
     - G5108300, G51051206
     - G5108400, G51051084
     - G5300010, G53010600
     - G5300030, G53010600
     - G5300050, G53010701
     - G5300050, G53010702
     - G5300050, G53010703
     - G5300070, G53010300
     - G5300090, G53011900
     - G5300110, G53011101
     - G5300110, G53011102
     - G5300110, G53011103
     - G5300110, G53011104
     - G5300130, G53010600
     - G5300150, G53011200
     - G5300170, G53010300
     - G5300190, G53010400
     - G5300210, G53010701
     - G5300210, G53010703
     - G5300230, G53010600
     - G5300250, G53010800
     - G5300270, G53011300
     - G5300290, G53010200
     - G5300310, G53011900
     - G5300330, G53011601
     - G5300330, G53011602
     - G5300330, G53011603
     - G5300330, G53011604
     - G5300330, G53011605
     - G5300330, G53011606
     - G5300330, G53011607
     - G5300330, G53011608
     - G5300330, G53011609
     - G5300330, G53011610
     - G5300330, G53011611
     - G5300330, G53011612
     - G5300330, G53011613
     - G5300330, G53011614
     - G5300330, G53011615
     - G5300330, G53011616
     - G5300350, G53011801
     - G5300350, G53011802
     - G5300370, G53010800
     - G5300390, G53011000
     - G5300410, G53011000
     - G5300430, G53010600
     - G5300450, G53011300
     - G5300470, G53010400
     - G5300490, G53011200
     - G5300510, G53010400
     - G5300530, G53011501
     - G5300530, G53011502
     - G5300530, G53011503
     - G5300530, G53011504
     - G5300530, G53011505
     - G5300530, G53011506
     - G5300530, G53011507
     - G5300550, G53010200
     - G5300570, G53010200
     - G5300590, G53011000
     - G5300610, G53011701
     - G5300610, G53011702
     - G5300610, G53011703
     - G5300610, G53011704
     - G5300610, G53011705
     - G5300610, G53011706
     - G5300630, G53010501
     - G5300630, G53010502
     - G5300630, G53010503
     - G5300630, G53010504
     - G5300650, G53010400
     - G5300670, G53011401
     - G5300670, G53011402
     - G5300690, G53011200
     - G5300710, G53010703
     - G5300730, G53010100
     - G5300750, G53010600
     - G5300770, G53010901
     - G5300770, G53010902
     - G5400010, G54000500
     - G5400030, G54000400
     - G5400050, G54000900
     - G5400070, G54000600
     - G5400090, G54000100
     - G5400110, G54000800
     - G5400130, G54000600
     - G5400150, G54001000
     - G5400170, G54000200
     - G5400190, G54001200
     - G5400210, G54000600
     - G5400230, G54000500
     - G5400250, G54001100
     - G5400270, G54000400
     - G5400290, G54000100
     - G5400310, G54000500
     - G5400330, G54000200
     - G5400350, G54000600
     - G5400370, G54000400
     - G5400390, G54001000
     - G5400410, G54000500
     - G5400430, G54000900
     - G5400450, G54001300
     - G5400470, G54001300
     - G5400490, G54000200
     - G5400510, G54000100
     - G5400530, G54000800
     - G5400550, G54001200
     - G5400570, G54000400
     - G5400590, G54001300
     - G5400610, G54000300
     - G5400630, G54001100
     - G5400650, G54000400
     - G5400670, G54001100
     - G5400690, G54000100
     - G5400710, G54000500
     - G5400730, G54000700
     - G5400750, G54001100
     - G5400770, G54000300
     - G5400790, G54000900
     - G5400810, G54001200
     - G5400830, G54000500
     - G5400850, G54000600
     - G5400870, G54000600
     - G5400890, G54001100
     - G5400910, G54000200
     - G5400930, G54000500
     - G5400950, G54000600
     - G5400970, G54000500
     - G5400990, G54000800
     - G5401010, G54001100
     - G5401030, G54000600
     - G5401050, G54000700
     - G5401070, G54000700
     - G5401090, G54001300
     - G5500010, G55001601
     - G5500030, G55000100
     - G5500050, G55055101
     - G5500070, G55000100
     - G5500090, G55000200
     - G5500090, G55000300
     - G5500110, G55000700
     - G5500130, G55000100
     - G5500150, G55001401
     - G5500170, G55055101
     - G5500170, G55055103
     - G5500190, G55055101
     - G5500210, G55001000
     - G5500230, G55000700
     - G5500250, G55000101
     - G5500250, G55000102
     - G5500250, G55000103
     - G5500270, G55001001
     - G5500290, G55001300
     - G5500310, G55000100
     - G5500330, G55055102
     - G5500350, G55055103
     - G5500370, G55001300
     - G5500390, G55001401
     - G5500410, G55000600
     - G5500430, G55000800
     - G5500450, G55000800
     - G5500470, G55001400
     - G5500490, G55000800
     - G5500510, G55000100
     - G5500530, G55000700
     - G5500550, G55001001
     - G5500570, G55001601
     - G5500590, G55010000
     - G5500610, G55001301
     - G5500630, G55000900
     - G5500650, G55000800
     - G5500670, G55000600
     - G5500690, G55000600
     - G5500710, G55001301
     - G5500730, G55001600
     - G5500750, G55001300
     - G5500770, G55001400
     - G5500780, G55001400
     - G5500790, G55040101
     - G5500790, G55040301
     - G5500790, G55040701
     - G5500790, G55041001
     - G5500790, G55041002
     - G5500790, G55041003
     - G5500790, G55041004
     - G5500790, G55041005
     - G5500810, G55000700
     - G5500830, G55001300
     - G5500850, G55000600
     - G5500870, G55001500
     - G5500890, G55020000
     - G5500910, G55000700
     - G5500930, G55000700
     - G5500950, G55055101
     - G5500970, G55001601
     - G5500990, G55000100
     - G5501010, G55030000
     - G5501030, G55000800
     - G5501050, G55002400
     - G5501070, G55000100
     - G5501090, G55055102
     - G5501110, G55001000
     - G5501130, G55000100
     - G5501150, G55001400
     - G5501170, G55002500
     - G5501190, G55000100
     - G5501210, G55000700
     - G5501230, G55000700
     - G5501250, G55000600
     - G5501270, G55050000
     - G5501290, G55000100
     - G5501310, G55020000
     - G5501330, G55070101
     - G5501330, G55070201
     - G5501330, G55070301
     - G5501350, G55001400
     - G5501370, G55001400
     - G5501390, G55001501
     - G5501410, G55001601
     - G5600010, G56000300
     - G5600030, G56000100
     - G5600050, G56000200
     - G5600070, G56000400
     - G5600090, G56000400
     - G5600110, G56000200
     - G5600130, G56000500
     - G5600150, G56000200
     - G5600170, G56000500
     - G5600190, G56000200
     - G5600210, G56000300
     - G5600230, G56000100
     - G5600250, G56000400
     - G5600270, G56000200
     - G5600290, G56000100
     - G5600310, G56000200
     - G5600330, G56000100
     - G5600350, G56000500
     - G5600370, G56000500
     - G5600390, G56000100
     - G5600410, G56000500
     - G5600430, G56000200
     - G5600450, G56000200
   * - Stock saturation
     - 0.017%
     - 0.08%
     - 0.0088%
     - 0.0067%
     - 0.018%
     - 0.0033%
     - 0.0074%
     - 0.04%
     - 0.013%
     - 0.012%
     - 0.014%
     - 0.0054%
     - 0.0094%
     - 0.005%
     - 0.005%
     - 0.017%
     - 0.02%
     - 0.0053%
     - 0.0048%
     - 0.014%
     - 0.005%
     - 0.028%
     - 0.017%
     - 0.015%
     - 0.023%
     - 0.025%
     - 0.012%
     - 0.035%
     - 0.0063%
     - 0.01%
     - 0.0094%
     - 0.0037%
     - 0.0057%
     - 0.0067%
     - 0.035%
     - 0.018%
     - 0.038%
     - 0.041%
     - 0.057%
     - 0.056%
     - 0.036%
     - 0.0055%
     - 0.033%
     - 0.011%
     - 0.049%
     - 0.026%
     - 0.0038%
     - 0.0076%
     - 0.029%
     - 0.041%
     - 0.037%
     - 0.0085%
     - 0.0076%
     - 0.0025%
     - 0.0084%
     - 0.03%
     - 0.038%
     - 0.038%
     - 0.059%
     - 0.0084%
     - 0.067%
     - 0.011%
     - 0.038%
     - 0.0035%
     - 0.007%
     - 0.012%
     - 0.0089%
     - 0.02%
     - 0.027%
     - 0.062%
     - 0.005%
     - 0.028%
     - 0.016%
     - 0.025%
     - 0.041%
     - 0.023%
     - 0.0062%
     - 0.0042%
     - 0.01%
     - 0.00075%
     - 0.0015%
     - 0.038%
     - 0.048%
     - 0.0045%
     - 0.00068%
     - 0.0013%
     - 0.0018%
     - 0.031%
     - 0.0012%
     - 0.0012%
     - 0.0099%
     - 0.023%
     - 0.0047%
     - 0.004%
     - 0.0017%
     - 0.0011%
     - 0.031%
     - 0.003%
     - 0.0019%
     - 0.002%
     - 0.0013%
     - 0.0025%
     - 0.0031%
     - 0.00048%
     - 0.0029%
     - 0.0046%
     - 0.0011%
     - 0.00029%
     - 0.003%
     - 0.024%
     - 0.045%
     - 0.048%
     - 0.025%
     - 0.0099%
     - 0.0033%
     - 0.012%
     - 0.033%
     - 0.055%
     - 0.043%
     - 0.034%
     - 0.04%
     - 0.036%
     - 0.033%
     - 0.033%
     - 0.032%
     - 0.036%
     - 0.053%
     - 0.045%
     - 0.043%
     - 0.035%
     - 0.037%
     - 0.034%
     - 0.039%
     - 0.038%
     - 0.037%
     - 0.026%
     - 0.033%
     - 0.031%
     - 0.025%
     - 0.026%
     - 0.029%
     - 0.03%
     - 0.038%
     - 0.034%
     - 0.031%
     - 0.034%
     - 0.053%
     - 0.036%
     - 0.03%
     - 0.028%
     - 0.034%
     - 0.084%
     - 0.043%
     - 0.032%
     - 0.039%
     - 0.038%
     - 0.041%
     - 0.04%
     - 0.042%
     - 0.037%
     - 0.029%
     - 0.039%
     - 0.004%
     - 0.047%
     - 0.034%
     - 0.04%
     - 0.014%
     - 0.084%
     - 0.067%
     - 0.004%
     - 0.003%
     - 0.0075%
     - 0.017%
     - 0.073%
     - 0.013%
     - 0.0043%
     - 0.0022%
     - 0.01%
     - 0.004%
     - 0.0078%
     - 0.006%
     - 0.012%
     - 0.003%
     - 0.0086%
     - 0.0073%
     - 0.029%
     - 0.0032%
     - 0.02%
     - 0.016%
     - 0.0059%
     - 0.0032%
     - 0.0047%
     - 0.0063%
     - 0.036%
     - 0.006%
     - 0.005%
     - 0.038%
     - 0.0058%
     - 0.014%
     - 0.0078%
     - 0.011%
     - 0.0046%
     - 0.012%
     - 0.0054%
     - 0.0057%
     - 0.025%
     - 0.0085%
     - 0.0032%
     - 0.0059%
     - 0.0033%
     - 0.0036%
     - 0.0048%
     - 0.0076%
     - 0.021%
     - 0.0056%
     - 0.007%
     - 0.014%
     - 0.015%
     - 0.0033%
     - 0.0043%
     - 0.0034%
     - 0.0035%
     - 0.0097%
     - 0.0037%
     - 0.0076%
     - 0.0042%
     - 0.0082%
     - 0.0075%
     - 0.019%
     - 0.0034%
     - 0.068%
     - 0.067%
     - 0.0064%
     - 0.0081%
     - 0.035%
     - 0.0039%
     - 0.0037%
     - 0.042%
     - 0.0051%
     - 0.0073%
     - 0.005%
     - 0.015%
     - 0.0077%
     - 0.067%
     - 0.025%
     - 0.0029%
     - 0.0073%
     - 0.043%
     - 0.058%
     - 0.043%
     - 0.033%
     - 0.05%
     - 0.037%
     - 0.036%
     - 0.032%
     - 0.05%
     - 0.06%
     - 0.0013%
     - 0.014%
     - 0.038%
     - 0.035%
     - 0.021%
     - 0.0059%
     - 0.031%
     - 0.035%
     - 0.039%
     - 0.039%
     - 0.034%
     - 0.036%
     - 0.032%
     - 0.028%
     - 0.029%
     - 0.0084%
     - 0.066%
     - 0.031%
     - 0.053%
     - 0.026%
     - 0.043%
     - 0.024%
     - 0.03%
     - 0.034%
     - 0.0081%
     - 0.047%
     - 0.042%
     - 0.0071%
     - 0.041%
     - 0.054%
     - 0.04%
     - 0.024%
     - 0.059%
     - 0.034%
     - 0.027%
     - 0.0095%
     - 0.033%
     - 0.05%
     - 0.042%
     - 0.038%
     - 0.046%
     - 0.032%
     - 0.027%
     - 0.032%
     - 0.031%
     - 0.036%
     - 0.044%
     - 0.03%
     - 0.026%
     - 0.027%
     - 0.025%
     - 0.02%
     - 0.051%
     - 0.044%
     - 0.057%
     - 0.038%
     - 0.042%
     - 0.046%
     - 0.03%
     - 0.047%
     - 0.05%
     - 0.031%
     - 0.057%
     - 0.044%
     - 0.07%
     - 0.059%
     - 0.049%
     - 0.064%
     - 0.036%
     - 0.059%
     - 0.048%
     - 0.033%
     - 0.03%
     - 0.028%
     - 0.04%
     - 0.03%
     - 0.027%
     - 0.024%
     - 0.024%
     - 0.048%
     - 0.022%
     - 0.025%
     - 0.048%
     - 0.065%
     - 0.029%
     - 0.041%
     - 0.03%
     - 0.031%
     - 0.025%
     - 0.03%
     - 0.025%
     - 0.026%
     - 0.031%
     - 0.04%
     - 0.028%
     - 0.047%
     - 0.037%
     - 0.025%
     - 0.034%
     - 0.039%
     - 0.042%
     - 0.027%
     - 0.047%
     - 0.035%
     - 0.03%
     - 0.037%
     - 0.036%
     - 0.048%
     - 0.0077%
     - 0.03%
     - 0.025%
     - 0.038%
     - 0.0039%
     - 0.01%
     - 0.056%
     - 0.035%
     - 0.014%
     - 0.041%
     - 0.04%
     - 0.059%
     - 0.029%
     - 0.073%
     - 0.065%
     - 0.054%
     - 0.047%
     - 0.049%
     - 0.048%
     - 0.033%
     - 0.044%
     - 0.034%
     - 0.04%
     - 0.033%
     - 0.059%
     - 0.027%
     - 0.026%
     - 0.03%
     - 0.052%
     - 0.039%
     - 0.034%
     - 0.045%
     - 0.012%
     - 0.052%
     - 0.065%
     - 0.033%
     - 0.031%
     - 0.047%
     - 0.043%
     - 0.041%
     - 0.039%
     - 0.025%
     - 0.036%
     - 0.039%
     - 0.024%
     - 0.035%
     - 0.031%
     - 0.07%
     - 0.033%
     - 0.033%
     - 0.037%
     - 0.039%
     - 0.031%
     - 0.029%
     - 0.046%
     - 0.037%
     - 0.038%
     - 0.038%
     - 0.027%
     - 0.032%
     - 0.014%
     - 0.05%
     - 0.037%
     - 0.043%
     - 0.056%
     - 0.039%
     - 0.026%
     - 0.025%
     - 0.036%
     - 0.022%
     - 0.021%
     - 0.044%
     - 0.032%
     - 0.039%
     - 0.035%
     - 0.023%
     - 0.05%
     - 0.036%
     - 0.027%
     - 0.038%
     - 0.033%
     - 0.033%
     - 0.029%
     - 0.036%
     - 0.05%
     - 0.062%
     - 0.03%
     - 0.032%
     - 0.047%
     - 0.047%
     - 0.049%
     - 0.064%
     - 0.046%
     - 0.034%
     - 0.034%
     - 0.034%
     - 0.043%
     - 0.03%
     - 0.052%
     - 0.05%
     - 0.054%
     - 0.042%
     - 0.034%
     - 0.031%
     - 0.025%
     - 0.047%
     - 0.038%
     - 0.048%
     - 0.044%
     - 0.057%
     - 0.032%
     - 0.035%
     - 0.031%
     - 0.032%
     - 0.037%
     - 0.039%
     - 0.029%
     - 0.028%
     - 0.027%
     - 0.06%
     - 0.062%
     - 0.045%
     - 0.041%
     - 0.031%
     - 0.022%
     - 0.028%
     - 0.039%
     - 0.04%
     - 0.036%
     - 0.041%
     - 0.029%
     - 0.027%
     - 0.024%
     - 0.02%
     - 0.038%
     - 0.04%
     - 0.058%
     - 0.0018%
     - 0.018%
     - 0.043%
     - 0.036%
     - 0.036%
     - 0.065%
     - 0.035%
     - 0.054%
     - 0.026%
     - 0.03%
     - 0.047%
     - 0.031%
     - 0.025%
     - 0.02%
     - 0.0066%
     - 0.036%
     - 0.035%
     - 0.037%
     - 0.023%
     - 0.03%
     - 0.042%
     - 0.042%
     - 0.035%
     - 0.03%
     - 0.033%
     - 0.057%
     - 0.021%
     - 0.0017%
     - 0.03%
     - 0.038%
     - 0.04%
     - 0.0014%
     - 0.0065%
     - 0.00096%
     - 0.0051%
     - 0.005%
     - 0.029%
     - 0.033%
     - 0.027%
     - 0.036%
     - 0.011%
     - 0.029%
     - 0.016%
     - 0.0067%
     - 0.0017%
     - 0.0016%
     - 0.0088%
     - 0.033%
     - 0.039%
     - 0.017%
     - 0.018%
     - 0.0015%
     - 0.0077%
     - 0.00069%
     - 0.0042%
     - 0.0032%
     - 0.002%
     - 0.0012%
     - 0.0032%
     - 0.011%
     - 0.048%
     - 0.041%
     - 0.046%
     - 0.054%
     - 0.034%
     - 0.001%
     - 0.03%
     - 0.03%
     - 0.028%
     - 0.024%
     - 0.0013%
     - 0.0055%
     - 0.024%
     - 0.04%
     - 0.037%
     - 0.033%
     - 0.034%
     - 0.031%
     - 0.014%
     - 0.017%
     - 0.0026%
     - 0.012%
     - 0.0086%
     - 0.0011%
     - 0.0038%
     - 0.00096%
     - 0.021%
     - 0.01%
     - 0.005%
     - 0.036%
     - 0.04%
     - 0.045%
     - 0.008%
     - 0.0091%
     - 0.00061%
     - 0.0026%
     - 0.0034%
     - 0.02%
     - 0.042%
     - 0.061%
     - 0.0062%
     - 0.0015%
     - 0.0067%
     - 0.042%
     - 0.0062%
     - 0.00096%
     - 0.0046%
     - 0.009%
     - 0.014%
     - 0.0086%
     - 0.0066%
     - 0.0024%
     - 0.011%
     - 0.0015%
     - 0.0097%
     - 0.0044%
     - 0.0018%
     - 0.049%
     - 0.0011%
     - 0.0025%
     - 0.0049%
     - 0.012%
     - 0.0029%
     - 0.00055%
     - 0.005%
     - 0.00097%
     - 0.023%
     - 0.0096%
     - 0.0018%
     - 0.0015%
     - 0.051%
     - 0.014%
     - 0.0079%
     - 0.0033%
     - 0.05%
     - 0.031%
     - 0.057%
     - 0.039%
     - 0.043%
     - 0.052%
     - 0.047%
     - 0.035%
     - 0.04%
     - 0.05%
     - 0.036%
     - 0.036%
     - 0.037%
     - 0.065%
     - 0.056%
     - 0.039%
     - 0.035%
     - 0.043%
     - 0.037%
     - 0.038%
     - 0.042%
     - 0.037%
     - 0.044%
     - 0.047%
     - 0.044%
     - 0.037%
     - 0.051%
     - 0.037%
     - 0.046%
     - 0.043%
     - 0.04%
     - 0.096%
     - 0.039%
     - 0.038%
     - 0.038%
     - 0.051%
     - 0.064%
     - 0.049%
     - 0.036%
     - 0.0072%
     - 0.075%
     - 0.0081%
     - 0.066%
     - 0.051%
     - 0.042%
     - 0.044%
     - 0.04%
     - 0.039%
     - 0.042%
     - 0.056%
     - 0.058%
     - 0.055%
     - 0.032%
     - 0.055%
     - 0.037%
     - 0.035%
     - 0.036%
     - 0.04%
     - 0.042%
     - 0.042%
     - 0.0044%
     - 0.076%
     - 0.058%
     - 0.058%
     - 0.053%
     - 0.053%
     - 0.046%
     - 0.021%
     - 0.011%
     - 0.0068%
     - 0.036%
     - 0.041%
     - 0.036%
     - 0.044%
     - 0.046%
     - 0.04%
     - 0.053%
     - 0.037%
     - 0.067%
     - 0.037%
     - 0.0064%
     - 0.014%
     - 0.0054%
     - 0.0051%
     - 0.0069%
     - 0.0043%
     - 0.0072%
     - 0.011%
     - 0.063%
     - 0.036%
     - 0.0049%
     - 0.048%
     - 0.062%
     - 0.047%
     - 0.051%
     - 0.05%
     - 0.037%
     - 0.058%
     - 0.062%
     - 0.0064%
     - 0.058%
     - 0.016%
     - 0.0049%
     - 0.0024%
     - 0.038%
     - 0.024%
     - 0.047%
     - 0.075%
     - 0.063%
     - 0.049%
     - 0.043%
     - 0.051%
     - 0.045%
     - 0.049%
     - 0.015%
     - 0.0026%
     - 0.0063%
     - 0.04%
     - 0.05%
     - 0.044%
     - 0.039%
     - 0.035%
     - 0.048%
     - 0.059%
     - 0.029%
     - 0.023%
     - 0.034%
     - 0.057%
     - 0.026%
     - 0.026%
     - 0.024%
     - 0.032%
     - 0.024%
     - 0.027%
     - 0.037%
     - 0.055%
     - 0.036%
     - 0.045%
     - 0.031%
     - 0.03%
     - 0.028%
     - 0.024%
     - 0.025%
     - 0.029%
     - 0.024%
     - 0.025%
     - 0.027%
     - 0.025%
     - 0.0077%
     - 0.04%
     - 0.027%
     - 0.071%
     - 0.014%
     - 0.038%
     - 0.036%
     - 0.04%
     - 0.041%
     - 0.044%
     - 0.035%
     - 0.04%
     - 0.031%
     - 0.038%
     - 0.035%
     - 0.064%
     - 0.037%
     - 0.042%
     - 0.046%
     - 0.06%
     - 0.041%
     - 0.04%
     - 0.06%
     - 0.057%
     - 0.048%
     - 0.037%
     - 0.034%
     - 0.039%
     - 0.042%
     - 0.038%
     - 0.054%
     - 0.039%
     - 0.046%
     - 0.044%
     - 0.042%
     - 0.044%
     - 0.049%
     - 0.042%
     - 0.061%
     - 0.048%
     - 0.059%
     - 0.062%
     - 0.042%
     - 0.049%
     - 0.027%
     - 0.011%
     - 0.061%
     - 0.046%
     - 0.057%
     - 0.05%
     - 0.057%
     - 0.062%
     - 0.054%
     - 0.037%
     - 0.035%
     - 0.035%
     - 0.031%
     - 0.04%
     - 0.0072%
     - 0.014%
     - 0.0081%
     - 0.0033%
     - 0.0021%
     - 0.038%
     - 0.053%
     - 0.06%
     - 0.037%
     - 0.0096%
     - 0.036%
     - 0.008%
     - 0.0063%
     - 0.0026%
     - 0.0035%
     - 0.0013%
     - 0.015%
     - 0.0056%
     - 0.02%
     - 0.03%
     - 0.0059%
     - 0.0064%
     - 0.052%
     - 0.0039%
     - 0.0059%
     - 0.0057%
     - 0.0097%
     - 0.022%
     - 0.0073%
     - 0.0069%
     - 0.0018%
     - 0.016%
     - 0.0035%
     - 0.033%
     - 0.02%
     - 0.0033%
     - 0.055%
     - 0.037%
     - 0.0025%
     - 0.0081%
     - 0.031%
     - 0.033%
     - 0.039%
     - 0.0014%
     - 0.031%
     - 0.047%
     - 0.0022%
     - 0.049%
     - 0.037%
     - 0.035%
     - 0.056%
     - 0.041%
     - 0.013%
     - 0.014%
     - 0.04%
     - 0.0054%
     - 0.039%
     - 0.0039%
     - 0.008%
     - 0.0054%
     - 0.0079%
     - 0.009%
     - 0.011%
     - 0.037%
     - 0.039%
     - 0.044%
     - 0.052%
     - 0.046%
     - 0.0073%
     - 0.0046%
     - 0.03%
     - 0.039%
     - 0.0037%
     - 0.0012%
     - 0.015%
     - 0.0071%
     - 0.0074%
     - 0.0035%
     - 0.012%
     - 0.031%
     - 0.03%
     - 0.053%
     - 0.0078%
     - 0.043%
     - 0.03%
     - 0.042%
     - 0.036%
     - 0.046%
     - 0.049%
     - 0.043%
     - 0.046%
     - 0.012%
     - 0.0011%
     - 0.031%
     - 0.017%
     - 0.008%
     - 0.0068%
     - 0.042%
     - 0.029%
     - 0.038%
     - 0.028%
     - 0.032%
     - 0.054%
     - 0.014%
     - 0.052%
     - 0.0039%
     - 0.0091%
     - 0.01%
     - 0.0097%
     - 0.0038%
     - 0.028%
     - 0.03%
     - 0.045%
     - 0.003%
     - 0.018%
     - 0.0047%
     - 0.0048%
     - 0.0054%
     - 0.0036%
     - 0.003%
     - 0.0086%
     - 0.0056%
     - 0.0032%
     - 0.016%
     - 0.008%
     - 0.02%
     - 0.0036%
     - 0.0047%
     - 0.034%
     - 0.0098%
     - 0.0069%
     - 0.0069%
     - 0.0045%
     - 0.0088%
     - 0.0031%
     - 0.0074%
     - 0.0021%
     - 0.0067%
     - 0.0082%
     - 0.0029%
     - 0.0056%
     - 0.012%
     - 0.063%
     - 0.029%
     - 0.0098%
     - 0.0048%
     - 0.04%
     - 0.0084%
     - 0.01%
     - 0.0059%
     - 0.0051%
     - 0.013%
     - 0.0035%
     - 0.0095%
     - 0.0015%
     - 0.0093%
     - 0.0027%
     - 0.065%
     - 0.025%
     - 0.0016%
     - 0.005%
     - 0.0036%
     - 0.02%
     - 0.0093%
     - 0.0017%
     - 0.01%
     - 0.0025%
     - 0.00081%
     - 0.0074%
     - 0.0034%
     - 0.0054%
     - 0.0031%
     - 0.015%
     - 0.012%
     - 0.009%
     - 0.0059%
     - 0.0024%
     - 0.021%
     - 0.0029%
     - 0.0031%
     - 0.011%
     - 0.009%
     - 0.022%
     - 0.024%
     - 0.012%
     - 0.0022%
     - 0.0068%
     - 0.009%
     - 0.001%
     - 0.0019%
     - 0.012%
     - 0.03%
     - 0.0026%
     - 0.0038%
     - 0.0033%
     - 0.0069%
     - 0.064%
     - 0.023%
     - 0.027%
     - 0.031%
     - 0.052%
     - 0.029%
     - 0.036%
     - 0.033%
     - 0.026%
     - 7.3e-05%
     - 0.023%
     - 0.053%
     - 0.011%
     - 0.014%
     - 0.032%
     - 0.034%
     - 0.035%
     - 0.002%
     - 0.025%
     - 0.003%
     - 0.0034%
     - 0.011%
     - 0.00074%
     - 0.011%
     - 0.004%
     - 0.018%
     - 0.03%
     - 0.0039%
     - 0.00096%
     - 0.00061%
     - 0.0065%
     - 0.027%
     - 0.019%
     - 0.0024%
     - 0.0063%
     - 0.00041%
     - 0.0033%
     - 0.0024%
     - 0.0091%
     - 0.0035%
     - 0.0065%
     - 0.0053%
     - 0.0045%
     - 0.0065%
     - 0.0066%
     - 0.0061%
     - 0.0033%
     - 0.046%
     - 0.012%
     - 0.0035%
     - 0.0014%
     - 0.0015%
     - 0.0095%
     - 0.0058%
     - 0.013%
     - 0.0015%
     - 0.0036%
     - 0.0068%
     - 0.0022%
     - 0.0052%
     - 0.0041%
     - 0.024%
     - 0.0089%
     - 0.0034%
     - 0.022%
     - 0.003%
     - 0.0053%
     - 0.015%
     - 0.0018%
     - 0.012%
     - 0.0021%
     - 0.0063%
     - 0.0043%
     - 0.067%
     - 0.012%
     - 0.0058%
     - 0.0047%
     - 0.012%
     - 0.017%
     - 0.038%
     - 0.052%
     - 0.05%
     - 0.042%
     - 0.05%
     - 0.053%
     - 0.033%
     - 0.054%
     - 0.052%
     - 0.038%
     - 0.041%
     - 0.032%
     - 0.032%
     - 0.038%
     - 0.056%
     - 0.054%
     - 0.039%
     - 0.069%
     - 0.069%
     - 0.048%
     - 0.041%
     - 0.039%
     - 0.05%
     - 0.041%
     - 0.053%
     - 0.063%
     - 0.075%
     - 0.044%
     - 0.035%
     - 0.046%
     - 0.074%
     - 0.036%
     - 0.045%
     - 0.041%
     - 0.0065%
     - 0.0036%
     - 0.031%
     - 0.0056%
     - 0.0063%
     - 0.034%
     - 0.036%
     - 0.045%
     - 0.038%
     - 0.032%
     - 0.046%
     - 0.035%
     - 0.0065%
     - 0.0024%
     - 0.011%
     - 0.0069%
     - 0.0047%
     - 0.014%
     - 0.012%
     - 0.002%
     - 0.0048%
     - 0.015%
     - 0.003%
     - 0.0069%
     - 0.0017%
     - 0.0029%
     - 0.016%
     - 0.01%
     - 0.021%
     - 0.0032%
     - 0.013%
     - 0.0075%
     - 0.01%
     - 0.0041%
     - 0.036%
     - 0.033%
     - 0.036%
     - 0.032%
     - 0.034%
     - 0.031%
     - 0.018%
     - 0.045%
     - 0.038%
     - 0.032%
     - 0.041%
     - 0.039%
     - 0.037%
     - 0.0048%
     - 0.011%
     - 0.012%
     - 0.0089%
     - 0.011%
     - 0.037%
     - 0.05%
     - 0.053%
     - 0.038%
     - 0.016%
     - 0.037%
     - 0.051%
     - 0.014%
     - 0.0044%
     - 0.0052%
     - 0.0053%
     - 0.0042%
     - 0.0055%
     - 0.01%
     - 0.0097%
     - 0.011%
     - 0.0047%
     - 0.017%
     - 0.062%
     - 0.0071%
     - 0.0055%
     - 0.0059%
     - 0.002%
     - 0.0023%
     - 0.0023%
     - 0.01%
     - 0.0056%
     - 0.049%
     - 0.049%
     - 0.04%
     - 0.0087%
     - 0.068%
     - 0.0026%
     - 0.0018%
     - 0.0078%
     - 0.002%
     - 0.016%
     - 0.043%
     - 0.0059%
     - 0.027%
     - 0.0041%
     - 0.0057%
     - 0.0049%
     - 0.0059%
     - 0.0053%
     - 0.019%
     - 0.037%
     - 0.035%
     - 0.041%
     - 0.032%
     - 0.033%
     - 0.023%
     - 0.066%
     - 0.027%
     - 0.011%
     - 0.0098%
     - 0.045%
     - 0.04%
     - 0.03%
     - 0.025%
     - 0.0029%
     - 0.0045%
     - 0.019%
     - 0.0063%
     - 0.0071%
     - 0.012%
     - 0.037%
     - 0.0087%
     - 0.0099%
     - 0.0041%
     - 0.0093%
     - 0.015%
     - 0.0084%
     - 0.013%
     - 0.039%
     - 0.013%
     - 0.058%
     - 0.0081%
     - 0.024%
     - 0.0058%
     - 0.0071%
     - 0.0072%
     - 0.011%
     - 0.023%
     - 0.011%
     - 0.017%
     - 0.038%
     - 0.032%
     - 0.022%
     - 0.012%
     - 0.044%
     - 0.016%
     - 0.029%
     - 0.012%
     - 0.014%
     - 0.01%
     - 0.0069%
     - 0.011%
     - 0.009%
     - 0.044%
     - 0.013%
     - 0.028%
     - 0.011%
     - 0.036%
     - 0.047%
     - 0.036%
     - 0.038%
     - 0.036%
     - 0.016%
     - 0.044%
     - 0.034%
     - 0.04%
     - 0.041%
     - 0.046%
     - 0.059%
     - 0.049%
     - 0.044%
     - 0.015%
     - 0.0035%
     - 0.011%
     - 0.045%
     - 0.012%
     - 0.021%
     - 0.0045%
     - 0.015%
     - 0.0021%
     - 0.0068%
     - 0.0075%
     - 0.006%
     - 0.0064%
     - 0.0043%
     - 0.05%
     - 0.0085%
     - 0.0045%
     - 0.011%
     - 0.0087%
     - 0.009%
     - 0.0056%
     - 0.036%
     - 0.05%
     - 0.0078%
     - 0.014%
     - 0.0067%
     - 0.0082%
     - 0.015%
     - 0.0066%
     - 0.0038%
     - 0.055%
     - 0.0052%
     - 0.0024%
     - 0.062%
     - 0.0056%
     - 0.035%
     - 0.011%
     - 0.0027%
     - 0.019%
     - 0.0091%
     - 0.023%
     - 0.0087%
     - 0.0097%
     - 0.011%
     - 0.0027%
     - 0.0015%
     - 0.0057%
     - 0.0049%
     - 0.0022%
     - 0.0083%
     - 0.042%
     - 0.0088%
     - 0.0076%
     - 0.0067%
     - 0.0062%
     - 0.005%
     - 0.0038%
     - 0.007%
     - 0.0049%
     - 0.006%
     - 0.017%
     - 0.0043%
     - 0.0042%
     - 0.0031%
     - 0.006%
     - 0.0067%
     - 0.016%
     - 0.0052%
     - 0.0066%
     - 0.017%
     - 0.0027%
     - 0.0029%
     - 0.006%
     - 0.014%
     - 0.0099%
     - 0.03%
     - 0.0036%
     - 0.0071%
     - 0.0056%
     - 0.0036%
     - 0.0026%
     - 0.0034%
     - 0.0041%
     - 0.0043%
     - 0.0053%
     - 0.004%
     - 0.0061%
     - 0.005%
     - 0.0062%
     - 0.0032%
     - 0.0035%
     - 0.0026%
     - 0.0054%
     - 0.007%
     - 0.012%
     - 0.0056%
     - 0.044%
     - 0.0066%
     - 0.0036%
     - 0.0056%
     - 0.012%
     - 0.071%
     - 0.0037%
     - 0.0031%
     - 0.0037%
     - 0.005%
     - 0.0073%
     - 0.01%
     - 0.012%
     - 0.0045%
     - 0.0037%
     - 0.0035%
     - 0.0029%
     - 0.0039%
     - 0.013%
     - 0.005%
     - 0.0022%
     - 0.0054%
     - 0.0034%
     - 0.0079%
     - 0.0028%
     - 0.04%
     - 0.038%
     - 0.064%
     - 0.029%
     - 0.0067%
     - 0.0019%
     - 0.004%
     - 0.055%
     - 0.0041%
     - 0.0094%
     - 0.028%
     - 0.0058%
     - 0.0023%
     - 0.0044%
     - 0.0027%
     - 0.012%
     - 0.014%
     - 0.0071%
     - 0.0024%
     - 0.013%
     - 0.0039%
     - 0.0066%
     - 0.031%
     - 0.0026%
     - 0.0049%
     - 0.0047%
     - 0.0028%
     - 0.0052%
     - 0.0021%
     - 0.0094%
     - 0.0053%
     - 0.0035%
     - 0.016%
     - 0.0035%
     - 0.0011%
     - 0.0016%
     - 0.0073%
     - 0.0011%
     - 0.00086%
     - 0.003%
     - 0.0035%
     - 0.003%
     - 0.00075%
     - 0.0068%
     - 0.0051%
     - 0.013%
     - 0.0013%
     - 0.0068%
     - 0.0026%
     - 0.036%
     - 0.0012%
     - 0.0013%
     - 0.0097%
     - 0.0024%
     - 0.0099%
     - 0.009%
     - 0.0083%
     - 0.011%
     - 0.001%
     - 0.0011%
     - 0.0022%
     - 0.0018%
     - 0.00046%
     - 0.003%
     - 0.00082%
     - 0.0024%
     - 0.011%
     - 0.0012%
     - 0.00078%
     - 0.0043%
     - 0.0061%
     - 0.0015%
     - 0.035%
     - 0.053%
     - 0.043%
     - 0.043%
     - 0.0012%
     - 0.0028%
     - 0.00091%
     - 0.0075%
     - 0.00073%
     - 0.022%
     - 0.0014%
     - 0.0041%
     - 0.0011%
     - 0.011%
     - 0.0096%
     - 0.0044%
     - 0.0037%
     - 0.0015%
     - 0.0099%
     - 0.0025%
     - 0.012%
     - 0.0024%
     - 0.0011%
     - 0.0034%
     - 0.0057%
     - 0.0013%
     - 0.0019%
     - 0.0056%
     - 0.0016%
     - 0.0021%
     - 0.0023%
     - 0.0023%
     - 0.0068%
     - 0.0033%
     - 0.0011%
     - 0.021%
     - 0.0022%
     - 0.0034%
     - 0.022%
     - 0.0021%
     - 0.0013%
     - 0.0029%
     - 0.018%
     - 0.0017%
     - 0.036%
     - 0.034%
     - 0.043%
     - 0.048%
     - 0.0061%
     - 0.037%
     - 0.022%
     - 0.00094%
     - 0.0023%
     - 0.0017%
     - 0.0017%
     - 0.00082%
     - 0.0017%
     - 0.0081%
     - 0.0026%
     - 0.0013%
     - 0.0024%
     - 0.00059%
     - 0.0022%
     - 0.00072%
     - 0.0035%
     - 0.0015%
     - 0.05%
     - 0.0063%
     - 0.007%
     - 0.0069%
     - 0.0029%
     - 0.014%
     - 0.004%
     - 0.0098%
     - 0.036%
     - 0.0067%
     - 0.016%
     - 0.0092%
     - 0.0029%
     - 0.0046%
     - 0.0079%
     - 0.023%
     - 0.0044%
     - 0.0047%
     - 0.014%
     - 0.03%
     - 0.0018%
     - 0.0035%
     - 0.0092%
     - 0.0055%
     - 0.022%
     - 0.012%
     - 0.0066%
     - 0.0039%
     - 0.0034%
     - 0.0027%
     - 0.032%
     - 0.0048%
     - 0.0025%
     - 0.0051%
     - 0.04%
     - 0.063%
     - 0.0049%
     - 0.014%
     - 0.017%
     - 0.0025%
     - 0.0029%
     - 0.0056%
     - 0.0074%
     - 0.012%
     - 0.01%
     - 0.0039%
     - 0.012%
     - 0.0028%
     - 0.0053%
     - 0.029%
     - 0.01%
     - 0.0061%
     - 0.0065%
     - 0.015%
     - 0.005%
     - 0.0017%
     - 0.016%
     - 0.0049%
     - 0.046%
     - 0.044%
     - 0.036%
     - 0.043%
     - 0.04%
     - 0.046%
     - 0.015%
     - 0.0079%
     - 0.052%
     - 0.0056%
     - 0.011%
     - 0.0047%
     - 0.019%
     - 0.0054%
     - 0.0026%
     - 0.0039%
     - 0.0086%
     - 0.0048%
     - 0.0081%
     - 0.0036%
     - 0.0092%
     - 0.0036%
     - 0.024%
     - 0.0055%
     - 0.0032%
     - 0.027%
     - 0.0044%
     - 0.0061%
     - 0.012%
     - 0.0038%
     - 0.0061%
     - 0.0091%
     - 0.0029%
     - 0.0075%
     - 0.0035%
     - 0.0039%
     - 0.0088%
     - 0.0044%
     - 0.01%
     - 0.014%
     - 0.0024%
     - 0.0076%
     - 0.016%
     - 0.0042%
     - 0.0016%
     - 0.0047%
     - 0.0095%
     - 0.023%
     - 0.0042%
     - 0.023%
     - 0.00086%
     - 0.0057%
     - 0.0076%
     - 0.0074%
     - 0.015%
     - 0.0045%
     - 0.0082%
     - 0.0056%
     - 0.0052%
     - 0.0082%
     - 0.0039%
     - 0.0058%
     - 0.0029%
     - 0.0046%
     - 0.037%
     - 0.0038%
     - 0.0081%
     - 0.0044%
     - 0.011%
     - 0.0027%
     - 0.0082%
     - 0.019%
     - 0.0073%
     - 0.033%
     - 0.0078%
     - 0.014%
     - 0.011%
     - 0.0058%
     - 0.04%
     - 0.043%
     - 0.041%
     - 0.027%
     - 0.037%
     - 0.0038%
     - 0.0027%
     - 0.0037%
     - 0.0058%
     - 0.007%
     - 0.0093%
     - 0.043%
     - 0.062%
     - 0.038%
     - 0.0023%
     - 0.0061%
     - 0.011%
     - 0.0068%
     - 0.0067%
     - 0.022%
     - 0.0097%
     - 0.0058%
     - 0.037%
     - 0.048%
     - 0.041%
     - 0.016%
     - 0.01%
     - 0.037%
     - 0.036%
     - 0.03%
     - 0.0049%
     - 0.015%
     - 0.04%
     - 0.0037%
     - 0.0093%
     - 0.014%
     - 0.047%
     - 0.048%
     - 0.049%
     - 0.049%
     - 0.0074%
     - 0.0084%
     - 0.043%
     - 0.0031%
     - 0.0066%
     - 0.011%
     - 0.013%
     - 0.015%
     - 0.0038%
     - 0.0065%
     - 0.013%
     - 0.027%
     - 0.017%
     - 0.017%
     - 0.039%
     - 0.035%
     - 0.039%
     - 0.0025%
     - 0.033%
     - 0.0085%
     - 0.019%
     - 0.016%
     - 0.016%
     - 0.014%
     - 0.0075%
     - 0.0038%
     - 0.0039%
     - 0.0054%
     - 0.037%
     - 0.029%
     - 0.026%
     - 0.013%
     - 0.026%
     - 0.04%
     - 0.016%
     - 0.03%
     - 0.046%
     - 0.018%
     - 0.018%
     - 0.027%
     - 0.055%
     - 0.011%
     - 0.014%
     - 0.023%
     - 0.016%
     - 0.017%
     - 0.061%
     - 0.019%
     - 0.025%
     - 0.047%
     - 0.034%
     - 0.039%
     - 0.044%
     - 0.036%
     - 0.039%
     - 0.037%
     - 0.037%
     - 0.034%
     - 0.035%
     - 0.033%
     - 0.026%
     - 0.01%
     - 0.047%
     - 0.032%
     - 0.043%
     - 0.012%
     - 0.034%
     - 0.036%
     - 0.014%
     - 0.038%
     - 0.035%
     - 0.037%
     - 0.049%
     - 0.008%
     - 0.035%
     - 0.036%
     - 0.052%
     - 0.059%
     - 0.038%
     - 0.033%
     - 0.035%
     - 0.027%
     - 0.038%
     - 0.029%
     - 0.035%
     - 0.048%
     - 0.033%
     - 0.037%
     - 0.015%
     - 0.032%
     - 0.0084%
     - 0.015%
     - 0.046%
     - 0.031%
     - 0.042%
     - 0.05%
     - 0.041%
     - 0.039%
     - 0.049%
     - 0.043%
     - 0.059%
     - 0.061%
     - 0.051%
     - 0.034%
     - 0.02%
     - 0.038%
     - 0.037%
     - 0.038%
     - 0.006%
     - 0.013%
     - 0.053%
     - 0.031%
     - 0.069%
     - 0.031%
     - 0.029%
     - 0.0095%
     - 0.0079%
     - 0.025%
     - 0.012%
     - 0.046%
     - 0.045%
     - 0.039%
     - 0.012%
     - 0.035%
     - 0.011%
     - 0.033%
     - 0.031%
     - 0.041%
     - 0.045%
     - 0.04%
     - 0.036%
     - 0.037%
     - 0.036%
     - 0.012%
     - 0.026%
     - 0.034%
     - 0.013%
     - 0.035%
     - 0.024%
     - 0.0081%
     - 0.0088%
     - 0.0092%
     - 0.02%
     - 0.021%
     - 0.036%
     - 0.036%
     - 0.039%
     - 0.031%
     - 0.0098%
     - 0.0028%
     - 0.011%
     - 0.026%
     - 0.015%
     - 0.026%
     - 0.031%
     - 0.041%
     - 0.033%
     - 0.059%
     - 0.038%
     - 0.039%
     - 0.041%
     - 0.032%
     - 0.057%
     - 0.038%
     - 0.037%
     - 0.034%
     - 0.046%
     - 0.021%
     - 0.0013%
     - 0.011%
     - 0.0082%
     - 0.0049%
     - 0.037%
     - 0.012%
     - 0.013%
     - 0.0073%
     - 0.0039%
     - 0.02%
     - 0.036%
     - 0.0092%
     - 0.057%
     - 0.015%
     - 0.045%
     - 0.019%
     - 0.013%
     - 0.014%
     - 0.016%
     - 0.017%
     - 0.023%
     - 0.0083%
     - 0.015%
     - 0.01%
     - 0.035%
     - 0.016%
     - 0.031%
     - 0.036%
     - 0.04%
     - 0.036%
     - 0.013%
     - 0.008%
     - 0.032%
     - 0.012%
     - 0.016%
     - 0.014%
     - 0.016%
     - 0.05%
     - 0.041%
     - 0.018%
     - 0.015%
     - 0.0069%
     - 0.021%
     - 0.052%
     - 0.043%
     - 0.04%
     - 0.009%
     - 0.043%
     - 0.06%
     - 0.048%
     - 0.035%
     - 0.0018%
     - 0.011%
     - 0.027%
     - 0.011%
     - 0.032%
     - 0.056%
     - 0.0032%
     - 0.0082%
     - 0.036%
     - 0.047%
     - 0.039%
     - 0.054%
     - 0.047%
     - 0.047%
     - 0.012%
     - 0.026%
     - 0.013%
     - 0.016%
     - 0.011%
     - 0.027%
     - 0.0068%
     - 0.047%
     - 0.021%
     - 0.0071%
     - 0.055%
     - 0.019%
     - 0.04%
     - 0.039%
     - 0.051%
     - 0.052%
     - 0.039%
     - 0.048%
     - 0.059%
     - 0.07%
     - 0.012%
     - 0.012%
     - 0.0042%
     - 0.01%
     - 0.0068%
     - 0.011%
     - 0.044%
     - 0.034%
     - 0.0078%
     - 0.018%
     - 0.065%
     - 0.054%
     - 0.021%
     - 0.017%
     - 0.0047%
     - 0.022%
     - 0.018%
     - 0.027%
     - 0.032%
     - 0.038%
     - 0.041%
     - 0.057%
     - 0.044%
     - 0.042%
     - 0.05%
     - 0.034%
     - 0.042%
     - 0.039%
     - 0.059%
     - 0.048%
     - 0.047%
     - 0.059%
     - 0.051%
     - 0.038%
     - 0.012%
     - 0.012%
     - 0.029%
     - 0.035%
     - 0.032%
     - 0.014%
     - 0.016%
     - 0.012%
     - 0.0023%
     - 0.02%
     - 0.0086%
     - 0.011%
     - 0.001%
     - 0.027%
     - 0.019%
     - 0.0043%
     - 0.016%
     - 0.019%
     - 0.0036%
     - 0.0043%
     - 0.004%
     - 0.031%
     - 0.047%
     - 0.04%
     - 0.034%
     - 0.006%
     - 0.015%
     - 0.0052%
     - 0.0073%
     - 0.011%
     - 0.015%
     - 0.0025%
     - 0.034%
     - 0.034%
     - 0.032%
     - 0.034%
     - 0.042%
     - 0.04%
     - 0.054%
     - 0.041%
     - 0.037%
     - 0.04%
     - 0.0064%
     - 0.011%
     - 0.012%
     - 0.02%
     - 0.0037%
     - 0.0058%
     - 0.015%
     - 0.0019%
     - 0.0059%
     - 0.0027%
     - 0.0058%
     - 0.0027%
     - 0.0093%
     - 0.0023%
     - 0.0083%
     - 0.012%
     - 0.0021%
     - 0.0036%
     - 0.0074%
     - 0.008%
     - 0.0095%
     - 0.012%
     - 0.013%
     - 0.0034%
     - 0.0098%
     - 0.0064%
     - 0.0025%
     - 0.046%
     - 0.027%
     - 0.0047%
     - 0.013%
     - 0.0033%
     - 0.011%
     - 0.0049%
     - 0.04%
     - 0.033%
     - 0.039%
     - 0.05%
     - 0.0014%
     - 0.0054%
     - 0.0054%
     - 0.018%
     - 0.0032%
     - 0.0056%
     - 0.044%
     - 0.033%
     - 0.033%
     - 0.0042%
     - 0.025%
     - 0.0049%
     - 0.047%
     - 0.011%
     - 0.0031%
     - 0.0036%
     - 0.0097%
     - 0.0015%
     - 0.0075%
     - 0.0052%
     - 0.0059%
     - 0.038%
     - 0.033%
     - 0.0038%
     - 0.0023%
     - 0.016%
     - 0.037%
     - 0.0035%
     - 0.011%
     - 0.013%
     - 0.0049%
     - 0.0068%
     - 0.0031%
     - 0.011%
     - 0.0052%
     - 0.0038%
     - 0.0056%
     - 0.0031%
     - 0.0031%
     - 0.0059%
     - 0.0069%
     - 0.008%
     - 0.0091%
     - 0.0063%
     - 0.048%
     - 0.024%
     - 0.0031%
     - 0.007%
     - 0.0038%
     - 0.0076%
     - 0.018%
     - 0.067%
     - 0.027%
     - 0.044%
     - 0.0077%
     - 0.0063%
     - 0.0029%
     - 0.00041%
     - 0.0076%
     - 0.046%
     - 0.0061%
     - 0.0027%
     - 0.0044%
     - 0.021%
     - 0.0035%
     - 0.018%
     - 0.018%
     - 0.026%
     - 0.0045%
     - 0.007%
     - 0.027%
     - 0.0098%
     - 0.011%
     - 0.02%
     - 0.023%
     - 0.0073%
     - 0.0088%
     - 0.011%
     - 0.012%
     - 0.004%
     - 0.0092%
     - 0.007%
     - 0.0039%
     - 0.016%
     - 0.011%
     - 0.018%
     - 0.0041%
     - 0.013%
     - 0.0094%
     - 0.0083%
     - 0.0027%
     - 0.043%
     - 0.0086%
     - 0.0016%
     - 0.0089%
     - 0.0054%
     - 0.0054%
     - 0.0072%
     - 0.0041%
     - 0.0083%
     - 0.0073%
     - 0.0077%
     - 0.0036%
     - 0.0088%
     - 0.0053%
     - 0.016%
     - 0.016%
     - 0.0069%
     - 0.0036%
     - 0.0038%
     - 0.0065%
     - 0.0048%
     - 0.0075%
     - 0.0085%
     - 0.0054%
     - 0.0022%
     - 0.0081%
     - 0.013%
     - 0.0042%
     - 0.0058%
     - 0.01%
     - 0.0044%
     - 0.055%
     - 0.029%
     - 0.015%
     - 0.0034%
     - 0.014%
     - 0.031%
     - 0.025%
     - 0.0034%
     - 0.0024%
     - 0.03%
     - 0.0054%
     - 0.0031%
     - 0.024%
     - 0.0026%
     - 0.031%
     - 0.036%
     - 0.0037%
     - 0.0066%
     - 0.024%
     - 0.0056%
     - 0.0089%
     - 0.0029%
     - 0.0057%
     - 0.0031%
     - 0.0032%
     - 0.0054%
     - 0.0048%
     - 0.011%
     - 0.033%
     - 0.0061%
     - 0.0024%
     - 0.012%
     - 0.042%
     - 0.042%
     - 0.0037%
     - 0.0033%
     - 0.0081%
     - 0.005%
     - 0.0021%
     - 0.0034%
     - 0.013%
     - 0.0039%
     - 0.07%
     - 0.044%
     - 0.038%
     - 0.03%
     - 0.052%
     - 0.038%
     - 0.033%
     - 0.033%
     - 0.016%
     - 0.0017%
     - 0.012%
     - 0.011%
     - 0.012%
     - 0.0034%
     - 0.016%
     - 0.0048%
     - 0.005%
     - 0.0073%
     - 0.0057%
     - 0.0044%
     - 0.0034%
     - 0.0096%
     - 0.0016%
     - 0.0095%
     - 0.0043%
     - 0.0046%
     - 0.0036%
     - 0.0046%
     - 0.011%
     - 0.0064%
     - 0.018%
     - 0.0072%
     - 0.0041%
     - 0.0049%
     - 0.0042%
     - 0.0061%
     - 0.0064%
     - 0.014%
     - 0.015%
     - 0.0058%
     - 0.03%
     - 0.01%
     - 0.014%
     - 0.0022%
     - 0.0038%
     - 0.008%
     - 0.0074%
     - 0.003%
     - 0.0049%
     - 0.032%
     - 0.038%
     - 0.041%
     - 0.0042%
     - 0.0064%
     - 0.022%
     - 0.04%
     - 0.041%
     - 0.04%
     - 0.037%
     - 0.04%
     - 0.035%
     - 0.054%
     - 0.041%
     - 0.0075%
     - 0.0016%
     - 0.0018%
     - 0.013%
     - 0.0031%
     - 0.0024%
     - 0.01%
     - 0.015%
     - 0.0025%
     - 0.022%
     - 0.0087%
     - 0.0071%
     - 0.011%
     - 0.0081%
     - 0.006%
     - 0.011%
     - 0.00095%
     - 0.0065%
     - 0.057%
     - 0.074%
     - 0.0039%
     - 0.0035%
     - 0.0021%
     - 0.002%
     - 0.0048%
     - 0.00059%
     - 0.028%
     - 0.0021%
     - 0.0042%
     - 0.00085%
     - 0.0032%
     - 0.0038%
     - 0.0011%
     - 0.0043%
     - 0.035%
     - 0.034%
     - 0.00063%
     - 0.004%
     - 0.00034%
     - 0.0021%
     - 0.0054%
     - 0.0038%
     - 0.001%
     - 0.012%
     - 0.023%
     - 0.00081%
     - 0.0086%
     - 0.00076%
     - 0.0052%
     - 0.001%
     - 0.0018%
     - 0.038%
     - 0.002%
     - 0.007%
     - 0.00024%
     - 0.0017%
     - 0.002%
     - 0.00077%
     - 0.0023%
     - 0.0005%
     - 0.015%
     - 0.0038%
     - 0.003%
     - 0.0031%
     - 0.005%
     - 0.0016%
     - 0.013%
     - 0.0036%
     - 0.0015%
     - 0.0021%
     - 0.0018%
     - 0.00034%
     - 0.0036%
     - 0.00097%
     - 0.00042%
     - 0.015%
     - 0.035%
     - 0.01%
     - 0.0024%
     - 0.00019%
     - 0.00029%
     - 0.00026%
     - 0.002%
     - 0.0041%
     - 0.001%
     - 0.0014%
     - 0.015%
     - 0.0026%
     - 0.003%
     - 0.0084%
     - 0.0031%
     - 0.0014%
     - 0.0023%
     - 0.0037%
     - 0.0022%
     - 0.0031%
     - 0.0031%
     - 0.0042%
     - 0.0058%
     - 0.0032%
     - 0.0076%
     - 0.00074%
     - 0.002%
     - 0.012%
     - 0.054%
     - 0.046%
     - 0.034%
     - 0.035%
     - 0.00082%
     - 0.0022%
     - 0.0013%
     - 0.0011%
     - 0.002%
     - 0.0078%
     - 0.001%
     - 0.0009%
     - 0.00093%
     - 0.00029%
     - 0.00097%
     - 0.018%
     - 0.003%
     - 0.0018%
     - 0.00039%
     - 0.0013%
     - 0.0039%
     - 0.00032%
     - 0.0022%
     - 0.0029%
     - 0.0016%
     - 0.0022%
     - 0.004%
     - 0.00038%
     - 0.0015%
     - 0.0036%
     - 0.051%
     - 0.042%
     - 0.012%
     - 0.00031%
     - 0.00031%
     - 0.00018%
     - 0.011%
     - 0.0028%
     - 0.0018%
     - 0.0014%
     - 0.0026%
     - 0.0018%
     - 0.0053%
     - 0.0012%
     - 0.0011%
     - 0.0031%
     - 0.0024%
     - 0.01%
     - 0.002%
     - 0.0039%
     - 0.0033%
     - 0.00065%
     - 0.0043%
     - 0.049%
     - 0.007%
     - 0.012%
     - 0.0052%
     - 0.0022%
     - 0.0014%
     - 0.00058%
     - 0.002%
     - 0.002%
     - 0.00029%
     - 0.0018%
     - 0.0017%
     - 0.0063%
     - 0.0029%
     - 0.0014%
     - 0.00041%
     - 0.0047%
     - 0.008%
     - 0.042%
     - 0.037%
     - 0.047%
     - 0.042%
     - 0.038%
     - 0.042%
     - 0.052%
     - 0.068%
     - 0.066%
     - 0.044%
     - 0.07%
     - 0.05%
     - 0.049%
     - 0.018%
     - 0.015%
     - 0.00072%
     - 0.00085%
     - 0.0054%
     - 0.0019%
     - 0.0019%
     - 0.017%
     - 0.0021%
     - 0.016%
     - 0.0018%
     - 0.0015%
     - 0.062%
     - 0.037%
     - 0.042%
     - 0.0033%
     - 0.017%
     - 0.028%
     - 0.027%
     - 0.0031%
     - 0.026%
     - 0.016%
     - 0.039%
     - 0.034%
     - 0.015%
     - 0.037%
     - 0.04%
     - 0.0073%
     - 0.036%
     - 0.0039%
     - 0.0066%
     - 0.025%
     - 0.064%
     - 0.039%
     - 0.017%
     - 0.046%
     - 0.045%
     - 0.004%
     - 0.034%
     - 0.036%
     - 0.046%
     - 0.035%
     - 0.028%
     - 0.029%
     - 0.03%
     - 0.027%
     - 0.039%
     - 0.048%
     - 0.046%
     - 0.037%
     - 0.04%
     - 0.042%
     - 0.035%
     - 0.074%
     - 0.032%
     - 0.01%
     - 0.044%
     - 0.039%
     - 0.033%
     - 0.061%
     - 0.031%
     - 0.028%
     - 0.038%
     - 0.045%
     - 0.048%
     - 0.034%
     - 0.042%
     - 0.045%
     - 0.038%
     - 0.037%
     - 0.036%
     - 0.041%
     - 0.03%
     - 0.036%
     - 0.033%
     - 0.029%
     - 0.03%
     - 0.029%
     - 0.036%
     - 0.03%
     - 0.039%
     - 0.03%
     - 0.037%
     - 0.031%
     - 0.031%
     - 0.027%
     - 0.038%
     - 0.037%
     - 0.032%
     - 0.035%
     - 0.054%
     - 0.042%
     - 0.035%
     - 0.038%
     - 0.041%
     - 0.037%
     - 0.035%
     - 0.03%
     - 0.03%
     - 0.021%
     - 0.03%
     - 0.03%
     - 0.033%
     - 0.046%
     - 0.033%
     - 0.03%
     - 0.029%
     - 0.027%
     - 0.031%
     - 0.034%
     - 0.0087%
     - 0.035%
     - 0.036%
     - 0.035%
     - 0.036%
     - 0.036%
     - 0.029%
     - 0.0029%
     - 0.02%
     - 0.0083%
     - 0.0075%
     - 0.015%
     - 0.00076%
     - 0.028%
     - 0.035%
     - 0.017%
     - 0.011%
     - 0.0017%
     - 0.00038%
     - 0.0018%
     - 0.019%
     - 0.013%
     - 0.0062%
     - 0.0082%
     - 0.019%
     - 0.0022%
     - 0.023%
     - 0.0041%
     - 0.015%
     - 0.0062%
     - 0.04%
     - 0.0081%
     - 0.029%
     - 0.012%
     - 0.054%
     - 0.0062%
     - 0.006%
     - 0.015%
     - 0.0058%
     - 0.0017%
     - 0.023%
     - 0.039%
     - 0.065%
     - 0.019%
     - 0.034%
     - 0.038%
     - 0.037%
     - 0.035%
     - 0.045%
     - 0.035%
     - 0.036%
     - 0.038%
     - 0.051%
     - 0.04%
     - 0.043%
     - 0.018%
     - 0.0055%
     - 0.031%
     - 0.027%
     - 0.05%
     - 0.026%
     - 0.003%
     - 0.019%
     - 0.027%
     - 0.025%
     - 0.015%
     - 0.023%
     - 0.039%
     - 0.05%
     - 0.038%
     - 0.039%
     - 0.033%
     - 0.053%
     - 0.054%
     - 0.043%
     - 0.054%
     - 0.019%
     - 0.019%
     - 0.021%
     - 0.019%
     - 0.022%
     - 0.0065%
     - 0.023%
     - 0.0021%
     - 0.044%
     - 0.05%
     - 0.037%
     - 0.043%
     - 0.047%
     - 0.04%
     - 0.043%
     - 0.036%
     - 0.045%
     - 0.055%
     - 0.041%
     - 0.034%
     - 0.037%
     - 0.04%
     - 0.037%
     - 0.045%
     - 0.046%
     - 0.05%
     - 0.036%
     - 0.011%
     - 0.02%
     - 0.024%
     - 0.043%
     - 0.039%
     - 0.034%
     - 0.041%
     - 0.031%
     - 0.054%
     - 0.017%
     - 0.032%
     - 0.03%
     - 0.026%
     - 0.029%
     - 0.028%
     - 0.033%
     - 0.028%
     - 0.029%
     - 0.026%
     - 0.028%
     - 0.027%
     - 0.031%
     - 0.059%
     - 0.038%
     - 0.045%
     - 0.038%
     - 0.1%
     - 0.088%
     - 0.078%
     - 0.072%
     - 0.058%
     - 0.069%
     - 0.039%
     - 0.035%
     - 0.02%
     - 0.053%
     - 0.004%
     - 0.049%
     - 0.04%
     - 0.052%
     - 0.012%
     - 0.037%
     - 0.035%
     - 0.036%
     - 0.033%
     - 0.014%
     - 0.04%
     - 0.023%
     - 0.029%
     - 0.06%
     - 0.045%
     - 0.071%
     - 0.034%
     - 0.048%
     - 0.044%
     - 0.035%
     - 0.041%
     - 0.043%
     - 0.05%
     - 0.036%
     - 0.057%
     - 0.032%
     - 0.034%
     - 0.054%
     - 0.045%
     - 0.038%
     - 0.05%
     - 0.027%
     - 0.029%
     - 0.022%
     - 0.039%
     - 0.037%
     - 0.039%
     - 0.051%
     - 0.013%
     - 0.0071%
     - 0.012%
     - 0.0089%
     - 0.027%
     - 0.029%
     - 0.027%
     - 0.031%
     - 0.031%
     - 0.074%
     - 0.037%
     - 0.035%
     - 0.027%
     - 0.027%
     - 0.026%
     - 0.028%
     - 0.026%
     - 0.028%
     - 0.037%
     - 0.017%
     - 0.031%
     - 0.016%
     - 0.047%
     - 0.029%
     - 0.022%
     - 0.031%
     - 0.001%
     - 0.041%
     - 0.038%
     - 0.032%
     - 0.048%
     - 0.061%
     - 0.056%
     - 0.013%
     - 0.01%
     - 0.051%
     - 0.012%
     - 0.006%
     - 0.0086%
     - 0.013%
     - 0.01%
     - 0.019%
     - 0.0073%
     - 0.013%
     - 0.061%
     - 0.044%
     - 0.042%
     - 0.03%
     - 0.042%
     - 0.014%
     - 0.028%
     - 0.0031%
     - 0.037%
     - 0.0079%
     - 0.051%
     - 0.022%
     - 0.013%
     - 0.0054%
     - 0.0054%
     - 0.017%
     - 0.016%
     - 0.019%
     - 0.034%
     - 0.041%
     - 0.032%
     - 0.034%
     - 0.011%
     - 0.025%
     - 0.054%
     - 0.014%
     - 0.019%
     - 0.054%
     - 0.042%
     - 0.018%
     - 0.036%
     - 0.042%
     - 0.043%
     - 0.02%
     - 0.033%
     - 0.034%
     - 0.0039%
     - 0.0044%
     - 0.017%
     - 0.0061%
     - 0.047%
     - 0.039%
     - 0.036%
     - 0.044%
     - 0.019%
     - 0.037%
     - 0.026%
     - 0.041%
     - 0.0079%
     - 0.015%
     - 0.0025%
     - 0.0083%
     - 0.044%
     - 0.0025%
     - 0.017%
     - 0.052%
     - 0.0036%
     - 0.018%
     - 0.02%
     - 0.025%
     - 0.016%
     - 0.019%
     - 0.008%
     - 0.0086%
     - 0.04%
     - 0.037%
     - 0.035%
     - 0.049%
     - 0.037%
     - 0.045%
     - 0.036%
     - 0.035%
     - 0.0065%
     - 0.012%
     - 0.034%
     - 0.032%
     - 0.017%
     - 0.062%
     - 0.0086%
     - 0.013%
     - 0.044%
     - 0.042%
     - 0.0057%
     - 0.013%
     - 0.02%
     - 0.0052%
     - 0.014%
     - 0.057%
     - 0.0086%
     - 0.046%
     - 0.016%
     - 0.0041%
     - 0.035%
     - 0.033%
     - 0.045%
     - 0.025%
     - 0.02%
     - 0.011%
     - 0.02%
     - 0.016%
     - 0.025%
     - 0.0066%
     - 0.014%
     - 0.0015%
     - 0.026%
     - 0.031%
     - 0.015%
     - 0.043%
     - 0.048%
     - 0.033%
     - 0.034%
     - 0.033%
     - 0.037%
     - 0.041%
     - 0.031%
     - 0.005%
     - 0.0038%
     - 0.0048%
     - 0.025%
     - 0.04%
     - 0.025%
     - 0.027%
     - 0.013%
     - 0.0083%
     - 0.001%
     - 0.0043%
     - 0.0022%
     - 0.00039%
     - 0.0033%
     - 0.0013%
     - 0.001%
     - 0.03%
     - 0.056%
     - 0.0017%
     - 0.002%
     - 0.0011%
     - 0.0018%
     - 0.00098%
     - 0.0016%
     - 0.0013%
     - 0.00075%
     - 0.023%
     - 0.0013%
     - 0.0011%
     - 0.0011%
     - 0.0013%
     - 0.0017%
     - 0.00088%
     - 0.0023%
     - 0.0014%
     - 0.0034%
     - 0.0044%
     - 0.0035%
     - 0.01%
     - 0.0035%
     - 0.0014%
     - 0.00071%
     - 0.0029%
     - 0.0017%
     - 0.0043%
     - 0.002%
     - 0.00095%
     - 0.0057%
     - 0.0041%
     - 0.0015%
     - 0.00065%
     - 0.00099%
     - 0.00033%
     - 0.01%
     - 0.00093%
     - 0.0075%
     - 0.00099%
     - 0.0028%
     - 0.0042%
     - 0.023%
     - 0.0019%
     - 0.012%
     - 0.0095%
     - 0.033%
     - 0.016%
     - 0.034%
     - 0.02%
     - 0.015%
     - 0.024%
     - 0.015%
     - 0.031%
     - 0.043%
     - 0.038%
     - 0.01%
     - 0.012%
     - 0.046%
     - 0.04%
     - 0.021%
     - 0.013%
     - 0.035%
     - 0.012%
     - 0.015%
     - 0.033%
     - 0.05%
     - 0.036%
     - 0.042%
     - 0.039%
     - 0.048%
     - 0.038%
     - 0.072%
     - 0.057%
     - 0.047%
     - 0.017%
     - 0.012%
     - 0.052%
     - 0.028%
     - 0.044%
     - 0.0095%
     - 0.035%
     - 0.034%
     - 0.035%
     - 0.037%
     - 0.04%
     - 0.044%
     - 0.039%
     - 0.04%
     - 0.032%
     - 0.035%
     - 0.032%
     - 0.013%
     - 0.01%
     - 0.027%
     - 0.052%
     - 0.014%
     - 0.033%
     - 0.048%
     - 0.042%
     - 0.049%
     - 0.042%
     - 0.035%
     - 0.032%
     - 0.025%
     - 0.0098%
     - 0.006%
     - 0.0089%
     - 0.014%
     - 0.0099%
     - 0.01%
     - 0.019%
     - 0.011%
     - 0.024%
     - 0.019%
     - 0.035%
     - 0.034%
     - 0.0065%
     - 0.02%
     - 0.052%
     - 0.017%
     - 0.046%
     - 0.05%
     - 0.001%
     - 0.04%
     - 0.049%
     - 0.051%
     - 0.0098%
     - 0.012%
     - 0.013%
     - 0.07%
     - 0.021%
     - 0.053%
     - 0.0082%
     - 0.013%
     - 0.033%
     - 0.0056%
     - 0.037%
     - 0.044%
     - 0.066%
     - 0.043%
     - 0.0058%
     - 0.011%
     - 0.028%
     - 0.0045%
     - 0.021%
     - 0.0065%
     - 0.011%
     - 0.016%
     - 0.0093%
     - 0.051%
     - 0.013%
     - 0.01%
     - 0.04%
     - 0.024%
     - 0.02%
     - 0.025%
     - 0.018%
     - 0.015%
     - 0.045%
     - 0.049%
     - 0.03%
     - 0.035%
     - 0.036%
     - 0.037%
     - 0.041%
     - 0.034%
     - 0.03%
     - 0.041%
     - 0.03%
     - 0.015%
     - 0.0094%
     - 0.0046%
     - 0.03%
     - 0.032%
     - 0.021%
     - 0.034%
     - 0.012%
     - 0.021%
     - 0.0077%
     - 0.012%
     - 0.0074%
     - 0.0069%
     - 0.002%
     - 0.0047%
     - 0.002%
     - 0.0074%
     - 0.0036%
     - 0.015%
     - 0.0099%
     - 0.035%
     - 0.016%
     - 0.016%
     - 0.0056%
     - 0.0012%
     - 0.082%
     - 0.0021%
     - 0.033%
     - 0.0057%
     - 0.0022%
     - 0.005%
     - 0.013%
     - 0.0067%
     - 0.0032%
     - 0.0093%
     - 0.019%
     - 0.0018%
     - 0.0017%
     - 0.02%
     - 0.0096%
     - 0.017%
     - 0.0018%
     - 0.002%
     - 0.0011%
     - 0.0014%
     - 0.0045%
     - 0.0047%
     - 0.0091%
     - 0.0025%
     - 0.0038%
     - 0.016%
     - 0.0048%
     - 0.0039%
     - 0.0037%
     - 0.016%
     - 0.011%
     - 0.013%
     - 0.0034%
     - 0.011%
     - 0.012%
     - 0.01%
     - 0.0027%
     - 0.0075%
     - 0.014%
     - 0.0051%
     - 0.023%
     - 0.004%
     - 0.0036%
     - 0.004%
     - 0.034%
     - 0.053%
     - 0.044%
     - 0.038%
     - 0.035%
     - 0.042%
     - 0.013%
     - 0.0079%
     - 0.0081%
     - 0.01%
     - 0.0058%
     - 0.026%
     - 0.017%
     - 0.0021%
     - 0.01%
     - 0.006%
     - 0.016%
     - 0.0046%
     - 0.0014%
     - 0.0084%
     - 0.019%
     - 0.0087%
     - 0.014%
     - 0.015%
     - 0.0061%
     - 0.003%
     - 0.076%
     - 0.06%
     - 0.038%
     - 0.033%
     - 0.016%
     - 0.0073%
     - 0.018%
     - 0.0041%
     - 0.0033%
     - 0.0067%
     - 0.0066%
     - 0.028%
     - 0.032%
     - 0.052%
     - 0.036%
     - 0.016%
     - 0.015%
     - 0.023%
     - 0.0077%
     - 0.0094%
     - 0.062%
     - 0.037%
     - 0.00078%
     - 0.0032%
     - 0.0028%
     - 0.0071%
     - 0.034%
     - 0.035%
     - 0.0073%
     - 0.028%
     - 0.024%
     - 0.0033%
     - 0.047%
     - 0.035%
     - 0.037%
     - 0.023%
     - 0.037%
     - 0.0087%
     - 0.029%
     - 0.031%
     - 0.032%
     - 0.0033%
     - 0.036%
     - 0.036%
     - 0.036%
     - 0.041%
     - 0.054%
     - 0.045%
     - 0.023%
     - 0.0007%
     - 0.014%
     - 0.022%
     - 0.0086%
     - 0.0031%
     - 0.0085%
     - 0.035%
     - 0.029%
     - 0.033%
     - 0.032%
     - 0.036%
     - 0.00073%
     - 0.028%
     - 0.031%
     - 0.072%
     - 0.044%
     - 0.037%
     - 0.05%
     - 0.045%
     - 0.067%
     - 0.044%
     - 0.044%
     - 0.037%
     - 0.024%
     - 0.0053%
     - 0.053%
     - 0.018%
     - 0.037%
     - 0.042%
     - 0.044%
     - 0.042%
     - 0.022%
     - 0.04%
     - 0.041%
     - 0.05%
     - 0.052%
     - 0.06%
     - 0.049%
     - 0.0033%
     - 0.026%
     - 0.048%
     - 0.034%
     - 0.039%
     - 0.042%
     - 0.031%
     - 0.015%
     - 0.029%
     - 0.014%
     - 0.022%
     - 0.033%
     - 0.029%
     - 0.048%
     - 0.055%
     - 0.036%
     - 0.037%
     - 0.049%
     - 0.045%
     - 0.035%
     - 0.013%
     - 0.036%
     - 0.053%
     - 0.047%
     - 0.0063%
     - 0.0084%
     - 0.039%
     - 0.0053%
     - 0.012%
     - 0.017%
     - 0.029%
     - 0.017%
     - 0.0082%
     - 0.037%
     - 0.036%
     - 0.036%
     - 0.033%
     - 0.046%
     - 0.04%
     - 0.03%
     - 0.042%
     - 0.019%
     - 0.047%
     - 0.034%
     - 0.0068%
     - 0.045%
     - 0.043%
     - 0.022%
     - 0.039%
     - 0.016%
     - 0.038%
     - 0.016%
     - 0.06%
     - 0.041%
     - 0.036%
     - 0.041%
     - 0.038%
     - 0.038%
     - 0.051%
     - 0.006%
     - 0.046%
     - 0.045%
     - 0.034%
     - 0.015%
     - 0.047%
     - 0.039%
     - 0.039%
     - 0.049%
     - 0.048%
     - 0.049%
     - 0.039%
     - 0.043%
     - 0.058%
     - 0.047%
     - 0.042%
     - 0.029%
     - 0.0096%
     - 0.051%
     - 0.012%
     - 0.028%
     - 0.0047%
     - 0.017%
     - 0.016%
     - 0.013%
     - 0.02%
     - 0.017%
     - 0.047%
     - 0.023%
     - 0.024%
     - 0.035%
     - 0.053%
     - 0.038%
     - 0.0099%
     - 0.051%
     - 0.039%
     - 0.045%
     - 0.016%
     - 0.055%
     - 0.031%
     - 0.046%
     - 0.057%
     - 0.053%
     - 0.04%
     - 0.047%
     - 0.009%
     - 0.055%
     - 0.0033%
     - 0.064%
     - 0.0057%
     - 0.0077%
     - 0.071%
     - 0.012%
     - 0.0048%
     - 0.019%
     - 0.023%
     - 0.0054%
     - 0.0021%
     - 0.071%
     - 0.032%
     - 0.028%
     - 0.018%
     - 0.011%
     - 0.016%
     - 0.013%
     - 0.015%
     - 0.023%
     - 0.01%
     - 0.031%
     - 0.012%
     - 0.0079%
     - 0.0087%
     - 0.044%
     - 0.025%
     - 0.033%
     - 0.051%
     - 0.039%
     - 0.027%
     - 0.023%
     - 0.0067%
     - 0.047%
     - 0.097%
     - 0.0081%
     - 0.021%
     - 0.025%
     - 0.023%
     - 0.0057%
     - 0.047%
     - 0.042%
     - 0.0041%
     - 0.011%
     - 0.0089%
     - 0.013%
     - 0.029%
     - 0.031%
     - 0.039%
     - 0.05%
     - 0.066%
     - 0.0095%
     - 0.0069%
     - 0.039%
     - 0.054%
     - 0.035%
     - 0.01%
     - 0.011%
     - 0.035%
     - 0.039%
     - 0.00099%
     - 0.0062%
     - 0.00086%
     - 0.0022%
     - 0.01%
     - 0.013%
     - 0.0018%
     - 0.00043%
     - 0.0035%
     - 0.00074%
     - 0.0029%
     - 0.0013%
     - 0.0043%
     - 0.0095%
     - 0.0011%
     - 0.0036%
     - 0.0068%
     - 0.0027%
     - 0.0016%
     - 0.0015%
     - 0.0011%
     - 0.0015%
     - 0.0031%
     - 0.00089%
     - 0.0026%
     - 0.0019%
     - 0.00078%
     - 0.0021%
     - 0.0014%
     - 0.00088%
     - 0.0005%
     - 0.0058%
     - 0.0025%
     - 0.00052%
     - 0.00096%
     - 0.00079%
     - 0.00039%
     - 0.002%
     - 0.0042%
     - 0.01%
     - 0.0069%
     - 0.0073%
     - 0.0013%
     - 0.0019%
     - 0.001%
     - 0.0019%
     - 0.0086%
     - 0.00064%
     - 0.00094%
     - 0.011%
     - 0.046%
     - 0.0021%
     - 0.0027%
     - 0.035%
     - 0.0013%
     - 0.0012%
     - 0.0037%
     - 0.00093%
     - 0.0024%
     - 0.0011%
     - 0.0006%
     - 0.0023%
     - 0.0023%
     - 0.003%
     - 0.005%
     - 0.0022%
     - 0.0073%
     - 0.00074%
     - 0.026%
     - 0.014%
     - 0.0067%
     - 0.0042%
     - 0.042%
     - 0.032%
     - 0.015%
     - 0.0045%
     - 0.0098%
     - 0.021%
     - 0.012%
     - 0.0052%
     - 0.011%
     - 0.0032%
     - 0.013%
     - 0.018%
     - 0.0048%
     - 0.021%
     - 0.051%
     - 0.036%
     - 0.041%
     - 0.041%
     - 0.051%
     - 0.0051%
     - 0.007%
     - 0.016%
     - 0.013%
     - 0.012%
     - 0.0067%
     - 0.014%
     - 0.017%
     - 0.01%
     - 0.0081%
     - 0.024%
     - 0.0048%
     - 0.02%
     - 0.041%
     - 0.038%
     - 0.037%
     - 0.0027%
     - 0.0081%
     - 0.01%
     - 0.02%
     - 0.0063%
     - 0.0096%
     - 0.013%
     - 0.0077%
     - 0.0031%
     - 0.0066%
     - 0.0043%
     - 0.018%
     - 0.0067%
     - 0.0035%
     - 0.034%
     - 0.064%
     - 0.046%
     - 0.0019%
     - 0.0084%
     - 0.014%
     - 0.0041%
     - 0.011%
     - 0.017%
     - 0.017%
     - 0.0089%
     - 0.0074%
     - 0.032%
     - 0.0097%
     - 0.0099%
     - 0.027%
     - 0.0042%
     - 0.016%
     - 0.057%
     - 0.0022%
     - 0.0066%
     - 0.011%
     - 0.0077%
     - 0.0034%
     - 0.0026%
     - 0.0062%
     - 0.025%
     - 0.011%
     - 0.019%
     - 0.02%
     - 0.036%
     - 0.046%
     - 0.0074%
     - 0.0048%
     - 0.042%
     - 0.055%
     - 0.044%
     - 0.036%
     - 0.028%
     - 0.033%
     - 0.036%
     - 0.035%
     - 0.034%
     - 0.0064%
     - 0.005%
     - 0.019%
     - 0.037%
     - 0.051%
     - 0.017%
     - 0.0026%
     - 0.0066%
     - 0.0068%
     - 0.002%
     - 0.013%
     - 0.044%
     - 0.0054%
     - 0.012%
     - 0.0087%
     - 0.055%
     - 0.037%
     - 0.015%
     - 0.0045%
     - 0.027%
     - 0.012%
     - 0.0031%
     - 0.00069%
     - 0.013%
     - 0.0097%
     - 0.002%
     - 0.0087%
     - 0.022%
     - 0.002%
     - 0.0079%
     - 0.051%
     - 0.049%
     - 0.03%
     - 0.039%
     - 0.032%
     - 0.031%
     - 0.027%
     - 0.028%
     - 0.025%
     - 0.029%
     - 0.031%
     - 0.038%
     - 0.042%
     - 0.032%
     - 0.03%
     - 0.03%
     - 0.031%
     - 0.03%
     - 0.0042%
     - 0.0003%
     - 0.0072%
     - 0.029%
     - 0.031%
     - 0.031%
     - 0.033%
     - 0.062%
     - 0.0041%
     - 0.00075%
     - 0.0023%
     - 0.014%
     - 0.0066%
     - 0.016%
     - 0.01%
     - 0.0087%
     - 0.0049%
     - 0.035%
     - 0.039%
     - 0.035%
     - 0.0042%
     - 0.0021%
     - 0.011%
     - 0.0024%
     - 0.011%
     - 0.016%
     - 0.0022%
     - 0.0038%
     - 0.001%
     - 0.002%
     - 0.0041%
     - 0.041%
     - 0.035%
     - 0.031%
     - 0.032%
     - 0.037%
     - 0.036%
     - 0.035%
     - 0.0011%
     - 0.0079%
     - 0.039%
     - 0.0054%
     - 0.0012%
     - 0.012%
     - 0.019%
     - 0.00078%
     - 0.0012%
     - 0.0014%
     - 0.0022%
     - 0.00075%
     - 0.0022%
     - 0.026%
     - 0.027%
     - 0.031%
     - 0.026%
     - 0.031%
     - 0.04%
     - 0.043%
     - 0.029%
     - 0.036%
     - 0.041%
     - 0.034%
     - 0.037%
     - 0.052%
     - 0.034%
     - 0.029%
     - 0.028%
     - 0.029%
     - 0.03%
     - 0.028%
     - 0.026%
     - 0.035%
     - 0.034%
     - 0.0039%
     - 0.0053%
     - 0.0018%
     - 0.038%
     - 0.033%
     - 0.034%
     - 0.035%
     - 0.034%
     - 0.036%
     - 0.0068%
     - 0.001%
     - 0.0032%
     - 0.0016%
     - 0.0041%
     - 0.0076%
     - 0.042%
     - 0.0013%
     - 0.043%
     - 0.033%
     - 0.041%
     - 0.031%
     - 0.032%
     - 0.037%
     - 0.038%
     - 0.013%
     - 0.0058%
     - 0.011%
     - 0.01%
     - 0.0016%
     - 0.0022%
     - 0.00064%
     - 0.028%
     - 0.034%
     - 0.027%
     - 0.033%
     - 0.045%
     - 0.0043%
     - 0.0069%
     - 0.0044%
     - 0.0047%
     - 0.062%
     - 0.043%
     - 0.0016%
     - 0.0096%
     - 0.00041%
     - 0.0028%
     - 0.0066%
     - 0.0075%
     - 0.041%
     - 0.038%
     - 0.0082%
     - 0.04%
     - 0.01%
     - 0.0014%
     - 0.0034%
     - 0.0017%
     - 0.0018%
     - 0.018%
     - 0.04%
     - 0.031%
     - 0.046%
     - 0.057%
     - 0.031%
     - 0.028%
     - 0.031%
     - 0.024%
     - 0.036%
     - 0.027%
     - 0.031%
     - 0.031%
     - 0.046%
     - 0.037%
     - 0.031%
     - 0.035%
     - 0.032%
     - 0.027%
     - 0.028%
     - 0.031%
     - 0.033%
     - 0.028%
     - 0.031%
     - 0.033%
     - 0.03%
     - 0.036%
     - 0.032%
     - 0.031%
     - 0.037%
     - 0.032%
     - 0.034%
     - 0.033%
     - 0.027%
     - 0.027%
     - 0.03%
     - 0.036%
     - 0.042%
     - 0.028%
     - 0.021%
     - 0.0015%
     - 0.0026%
     - 0.052%
     - 0.0013%
     - 0.03%
     - 0.027%
     - 0.025%
     - 0.029%
     - 0.026%
     - 0.037%
     - 0.028%
     - 0.023%
     - 0.012%
     - 0.0069%
     - 0.019%
     - 0.011%
     - 0.0086%
     - 0.0098%
     - 0.0011%
     - 0.028%
     - 0.0079%
     - 0.00065%
     - 0.0031%
     - 0.0049%
     - 0.013%
     - 0.0012%
     - 0.039%
     - 0.041%
     - 0.0018%
     - 0.012%
     - 0.044%
     - 0.0055%
     - 0.0043%
     - 0.029%
     - 0.011%
     - 0.00021%
     - 0.00035%
     - 0.018%
     - 0.0026%
     - 0.00012%
     - 0.0013%
     - 0.0098%
     - 0.0015%
     - 0.017%
     - 0.0046%
     - 0.0067%
     - 0.0023%
     - 0.0077%
     - 0.0057%
     - 0.0071%
     - 0.022%
     - 0.0079%
     - 0.0011%
     - 0.0045%
     - 0.011%
     - 4.8e-05%
     - 0.036%
     - 0.054%
     - 0.002%
     - 0.0032%
     - 0.033%
     - 0.04%
     - 0.00031%
     - 0.0039%
     - 0.0047%
     - 0.0014%
     - 0.002%
     - 0.014%
     - 0.013%
     - 0.013%
     - 0.0012%
     - 0.043%
     - 0.0085%
     - 0.0021%
     - 0.003%
     - 0.0076%
     - 0.041%
     - 0.038%
     - 0.035%
     - 0.032%
     - 0.0059%
     - 0.0045%
     - 0.00059%
     - 0.021%
     - 0.015%
     - 0.0053%
     - 0.0053%
     - 0.039%
     - 0.035%
     - 0.035%
     - 0.003%
     - 0.0006%
     - 0.027%
     - 0.011%
     - 0.0082%
     - 0.036%
     - 0.0028%
     - 0.0042%
     - 0.018%
     - 0.037%
     - 0.003%
     - 0.0039%
     - 0.04%
     - 0.001%
     - 0.002%
     - 0.0051%
     - 0.0035%
     - 0.0028%
     - 0.00031%
     - 0.0064%
     - 0.023%
     - 0.0039%
     - 0.016%
     - 0.006%
     - 0.004%
     - 0.0098%
     - 0.02%
     - 0.0024%
     - 0.0011%
     - 0.0054%
     - 0.0013%
     - 0.0089%
     - 0.001%
     - 0.031%
     - 0.035%
     - 0.0028%
     - 0.015%
     - 0.0037%
     - 0.00044%
     - 0.00063%
     - 0.0015%
     - 0.0024%
     - 0.032%
     - 0.044%
     - 0.035%
     - 0.027%
     - 0.03%
     - 0.031%
     - 0.037%
     - 0.029%
     - 0.043%
     - 0.033%
     - 0.03%
     - 0.028%
     - 0.036%
     - 0.046%
     - 0.035%
     - 0.036%
     - 0.042%
     - 0.00057%
     - 0.0036%
     - 0.0008%
     - 0.009%
     - 0.036%
     - 0.034%
     - 0.037%
     - 0.04%
     - 0.039%
     - 0.036%
     - 0.052%
     - 0.043%
     - 0.037%
     - 0.036%
     - 0.0065%
     - 0.0079%
     - 0.012%
     - 0.0012%
     - 0.0082%
     - 0.014%
     - 0.017%
     - 0.027%
     - 0.019%
     - 0.012%
     - 0.0035%
     - 0.012%
     - 0.032%
     - 0.027%
     - 0.013%
     - 0.002%
     - 0.042%
     - 0.0047%
     - 0.0053%
     - 0.036%
     - 0.03%
     - 0.034%
     - 0.032%
     - 0.013%
     - 0.0022%
     - 0.018%
     - 0.016%
     - 0.0022%
     - 0.0065%
     - 0.0046%
     - 0.0032%
     - 0.0022%
     - 0.013%
     - 0.029%
     - 0.0072%
     - 0.00087%
     - 0.048%
     - 0.029%
     - 0.0073%
     - 0.0034%
     - 0.0028%
     - 0.0038%
     - 0.015%
     - 0.0027%
     - 0.0044%
     - 0.0037%
     - 0.0025%
     - 0.0007%
     - 0.0022%
     - 0.024%
     - 0.043%
     - 0.023%
     - 0.031%
     - 0.046%
     - 0.024%
     - 0.036%
     - 0.03%
     - 0.025%
     - 0.0043%
     - 0.0078%
     - 0.0064%
     - 0.02%
     - 0.015%
     - 0.0097%
     - 0.024%
     - 0.037%
     - 0.026%
     - 0.032%
     - 0.0087%
     - 0.047%
     - 0.0012%
     - 0.033%
     - 0.032%
     - 0.013%
     - 0.016%
     - 0.012%
     - 0.05%
     - 0.0038%
     - 0.016%
     - 0.0038%
     - 0.0099%
     - 0.011%
     - 0.012%
     - 0.025%
     - 0.022%
     - 0.022%
     - 0.026%
     - 0.016%
     - 0.013%
     - 0.02%
     - 0.006%
     - 0.0041%
     - 0.01%
     - 0.0053%
     - 0.04%
     - 0.042%
     - 0.024%
     - 0.0026%
     - 0.027%
     - 0.0024%
     - 0.011%
     - 0.0061%
     - 0.0085%
     - 0.0054%
     - 0.019%
     - 0.0089%
     - 0.012%
     - 0.0025%
     - 0.0047%
     - 0.033%
     - 0.033%
     - 0.028%
     - 0.0047%
     - 0.0022%
     - 0.014%
     - 0.0035%
     - 0.0056%
     - 0.0086%
     - 0.0043%
     - 0.04%
     - 0.037%
     - 0.033%
     - 0.027%
     - 0.034%
     - 0.029%
     - 0.047%
     - 0.029%
     - 0.031%
     - 0.02%
     - 0.0059%
     - 0.008%
     - 0.022%
     - 0.024%
     - 0.0062%
     - 0.012%
     - 0.0066%
     - 0.0068%
     - 0.006%
     - 0.0031%
     - 0.013%
     - 0.03%
     - 0.047%
     - 0.054%
     - 0.019%
     - 0.0015%
     - 0.011%
     - 0.024%
     - 0.0026%
     - 0.0073%
     - 0.005%
     - 0.0057%
     - 0.0087%
     - 0.029%
     - 0.032%
     - 0.031%
     - 0.013%
     - 0.0044%
     - 0.0045%
     - 0.0043%
     - 0.014%
     - 0.0054%
     - 0.029%
     - 0.0075%
     - 0.0059%
     - 0.0055%
     - 0.0068%
     - 0.005%
     - 0.011%
     - 0.0087%
     - 0.0075%
     - 0.023%
     - 0.0078%
     - 0.0069%
     - 0.0091%
     - 0.029%
     - 0.016%
     - 0.062%
     - 0.013%
     - 0.0029%
     - 0.0029%
     - 0.0028%
     - 0.027%
     - 0.0084%
     - 0.026%
     - 0.01%
     - 0.0089%
     - 0.016%
     - 0.011%
     - 0.0056%
     - 0.035%
     - 0.035%
     - 0.0026%
     - 0.0034%
     - 0.015%
     - 0.012%
     - 0.019%
     - 0.0081%
     - 0.013%
     - 0.011%
     - 0.02%
     - 0.056%
     - 0.0066%
     - 0.0022%
     - 0.015%
     - 0.036%
     - 0.029%
     - 0.0058%
     - 0.0023%
     - 0.017%
     - 0.0018%
     - 0.0066%
     - 0.0043%
     - 0.0029%
     - 0.0085%
     - 0.0025%
     - 0.045%
     - 0.013%
     - 0.0077%
     - 0.0016%
     - 0.024%
     - 0.01%
     - 0.0036%
     - 0.0053%
     - 0.058%
     - 0.066%
     - 0.0059%
     - 0.0015%
     - 0.012%
     - 0.0035%
     - 0.031%
     - 0.0049%
     - 0.075%
     - 0.035%
     - 0.0081%
     - 0.0088%
     - 0.026%
     - 0.047%
     - 0.051%
     - 0.038%
     - 0.0074%
     - 0.0038%
     - 0.0089%
     - 0.0047%
     - 0.0073%
     - 0.014%
     - 0.032%
     - 0.0077%
     - 0.027%
     - 0.027%
     - 0.035%
     - 0.033%
     - 0.03%
     - 0.031%
     - 0.0016%
     - 0.032%
     - 0.012%
     - 0.0033%
     - 0.015%
     - 0.0044%
     - 0.0009%
     - 0.027%
     - 0.026%
     - 0.03%
     - 0.013%
     - 0.055%
     - 0.04%
     - 0.061%
     - 0.04%
     - 0.045%
     - 0.036%
     - 0.045%
     - 0.045%
     - 0.041%
     - 0.041%
     - 0.038%
     - 0.039%
     - 0.034%
     - 0.032%
     - 0.034%
     - 0.033%
     - 0.04%
     - 0.042%
     - 0.017%
     - 0.0074%
     - 0.025%
     - 0.0044%
     - 0.024%
     - 0.017%
     - 0.012%
     - 0.006%
     - 0.041%
     - 0.038%
     - 0.034%
     - 0.037%
     - 0.033%
     - 0.036%
     - 0.03%
     - 0.01%
     - 0.039%
     - 0.0042%
     - 0.036%
     - 0.037%
     - 0.037%
     - 0.034%
     - 0.037%
     - 0.041%
     - 0.041%
     - 0.042%
     - 0.041%
     - 0.031%
     - 0.016%
     - 0.052%
     - 0.031%
     - 0.0016%
     - 0.018%
     - 0.069%
     - 0.015%
     - 0.035%
     - 0.029%
     - 0.0059%
     - 0.035%
     - 0.0082%
     - 0.0055%
     - 0.0081%
     - 0.035%
     - 0.0029%
     - 0.0034%
     - 0.0029%
     - 0.016%
     - 0.0026%
     - 0.0048%
     - 0.014%
     - 0.01%
     - 0.011%
     - 0.0061%
     - 0.024%
     - 0.0099%
     - 0.017%
     - 0.069%
     - 0.0059%
     - 0.0073%
     - 0.012%
     - 0.0083%
     - 0.02%
     - 0.012%
     - 0.0097%
     - 0.022%
     - 0.0098%
     - 0.0094%
     - 0.033%
     - 0.0057%
     - 0.0073%
     - 0.0097%
     - 0.016%
     - 0.0039%
     - 0.0025%
     - 0.0066%
     - 0.011%
     - 0.018%
     - 0.027%
     - 0.011%
     - 0.0043%
     - 0.0055%
     - 0.0057%
     - 0.0056%
     - 0.004%
     - 0.0037%
     - 0.0084%
     - 0.014%
     - 0.004%
     - 0.0061%
     - 0.0024%
     - 0.03%
     - 0.0081%
     - 0.013%
     - 0.0072%
     - 0.018%
     - 0.0098%
     - 0.034%
     - 0.046%
     - 0.005%
     - 0.011%
     - 0.015%
     - 0.0036%
     - 0.017%
     - 0.011%
     - 0.02%
     - 0.0066%
     - 0.04%
     - 0.059%
     - 0.067%
     - 0.028%
     - 0.018%
     - 0.017%
     - 0.013%
     - 0.032%
     - 0.0036%
     - 0.033%
     - 0.0068%
     - 0.016%
     - 0.012%
     - 0.0079%
     - 0.008%
     - 0.0045%
     - 0.0073%
     - 0.026%
     - 0.011%
     - 0.052%
     - 0.007%
     - 0.037%
     - 0.0054%
     - 0.0092%
     - 0.013%
     - 0.028%
     - 0.044%
     - 0.023%
     - 0.0074%
     - 0.0017%
     - 0.041%
     - 0.038%
     - 0.06%
     - 0.033%
     - 0.038%
     - 0.035%
     - 0.028%
     - 0.038%
     - 0.015%
     - 0.018%
     - 0.023%
     - 0.056%
     - 0.027%
     - 0.0027%
     - 0.012%
     - 0.018%
     - 0.023%
     - 0.0082%
     - 0.061%
     - 0.0066%
     - 0.051%
     - 0.0067%
     - 0.026%
     - 0.022%
     - 0.012%
     - 0.015%
     - 0.038%
     - 0.0079%
     - 0.0096%
     - 0.01%
     - 0.019%
     - 0.039%
     - 0.0097%
     - 0.041%
     - 0.035%
     - 0.048%
     - 0.039%
     - 0.019%
     - 0.011%
     - 0.055%
     - 0.026%
     - 0.014%
     - 0.004%
     - 0.015%
     - 0.0064%
     - 0.0049%
     - 0.0027%
     - 0.013%
     - 0.0044%
     - 0.0019%
     - 0.0034%
     - 0.031%
     - 0.0067%
     - 0.027%
     - 0.00096%
     - 0.01%
     - 0.0035%
     - 0.011%
     - 0.0044%
     - 0.014%
     - 0.0099%
     - 0.0065%
     - 0.0028%
     - 0.0026%

.. _custom_state:

Custom State
------------

Description
***********

A custom selection of states to be able to have more fine tuned probability distributionin states where we have more data

Created by
**********

``sources/aris/tsv_maker.py``

Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Custom State** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - AK
     - Others
   * - Stock saturation
     - 0.23%
     - 1e+02%

.. _dehumidifier:

Dehumidifier
------------

Description
***********

Presence, water removal rate, and humidity setpoint of the dehumidifier.

Created by
**********

manually created

Source
******

- \Not applicable (dehumidifiers are not explicitly modeled separate from plug loads)


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Dehumidifier** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
   * - Stock saturation
     - 100%
   * - ``appliance_dehumidifier_setpoint_relative_humidity``
     - 0.5

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``appliance_dehumidifier_setpoint_relative_humidity``
     - frac
     - The relative humidity setpoint.
.. _dishwasher:

Dishwasher
----------

Description
***********

The presence and rated efficiency of the dishwasher.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \The 2020 recs survey does not contain EnergyStar rating of dishwashers.Energystar efficiency distributions with [Geometry Building Type,Census Division RECS,Federal Poverty Level, Tenure] as dependencies are imported from RECS 2009Due to low sample count, the tsv is constructed with the followingfallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently

  - \[7] Vintage homes built before 1960 coarsened to pre1960

  - \[8] Vintage homes built after 2000 coarsened to 2000-20

  - \[9] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[10] Census Division RECS to Census Region


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Dishwasher** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - EnergyStar
     - None
     - Standard
     - Void
   * - Stock saturation
     - 30%
     - 28%
     - 42%
     - 0%
   * - ``appliance_dishwasher_efficiency_type``
     - RatedAnnualkWh
     - 
     - RatedAnnualkWh
     - 
   * - ``appliance_dishwasher_efficiency``
     - 270.0
     - 
     - 307.0
     - 
   * - ``appliance_dishwasher_label_electric_rate``
     - 0.12
     - 
     - 0.12
     - 
   * - ``appliance_dishwasher_label_gas_rate``
     - 1.09
     - 
     - 1.09
     - 
   * - ``appliance_dishwasher_label_annual_gas_cost``
     - 22.23
     - 
     - 22.32
     - 
   * - ``appliance_dishwasher_label_usage``
     - 4
     - 
     - 4
     - 
   * - ``appliance_dishwasher_place_setting_capacity``
     - 12
     - 
     - 12
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``appliance_dishwasher_efficiency_type``
     - 
     - The efficiency type of the dishwasher.
   * - ``appliance_dishwasher_efficiency``
     - kWh/yr or #
     - The efficiency from the EnergyGuide label.
   * - ``appliance_dishwasher_label_electric_rate``
     - $/kWh
     - The electricity rate from the EnergyGuide label.
   * - ``appliance_dishwasher_label_gas_rate``
     - $/therm
     - The natural gas rate from the EnergyGuide label.
   * - ``appliance_dishwasher_label_annual_gas_cost``
     - $
     - The annual cost of using the system under test conditions with a natural gas water heater. Input is obtained from the EnergyGuide label.
   * - ``appliance_dishwasher_label_usage``
     - cyc/wk
     - The dishwasher loads per week from the EnergyGuide label.
   * - ``appliance_dishwasher_place_setting_capacity``
     - #
     - The number of place settings for the unit. Data obtained from manufacturer's literature.
.. _dishwasher_usage_level:

Dishwasher Usage Level
----------------------

Description
***********

Dishwasher energy usage level multiplier.

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \n/a


Assumption
**********

- \Engineering judgement


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Dishwasher Usage Level** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 80% Usage
     - 100% Usage
     - 120% Usage
   * - Stock saturation
     - 25%
     - 50%
     - 25%
   * - ``dishwasher_usage_multiplier``
     - 0.8
     - 1.0
     - 1.2

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``dishwasher_usage_multiplier``
     - 
     - Multiplier on the dishwasher energy usage that can reflect, e.g., high/low usage occupants.
.. _door_area:

Door Area
---------

Description
***********

Area of exterior doors

Created by
**********

manually created

Source
******

- \Engineering Judgement


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Door Area** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 20 ft^2
   * - Stock saturation
     - 100%
   * - ``geometry_door_area``
     - 20

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_door_area``
     - ft2
     - The area of the opaque door(s). Any door glazing (e.g., sliding glass doors) should be captured as window area.
.. _doors:

Doors
-----

Description
***********

Exterior door material and properties.

Created by
**********

manually created

Source
******

- \Engineering Judgement


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Doors** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Fiberglass
   * - Stock saturation
     - 100%
   * - ``enclosure_door_r_value``
     - 5.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_door_r_value``
     - F-ft2-hr/Btu
     - R-value of the opaque door(s).
.. _duct_leakage_and_insulation:

Duct Leakage and Insulation
---------------------------

Description
***********

Duct insulation and leakage to outside from the portion of ducts in unconditioned spaces

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \Duct insulation as a function of location: IECC 2009

- \Leakage distribution: Lucas and Cole, 'Impacts of the 2009 IECC for Residential Buildings at State Level', 2009


Assumption
**********

- \Ducts entirely in conditioned spaces will not have any leakage to outside. Ducts with R-4/R-8 insulation were previously assigned to Geometry Foundation Type = Ambient or Slab. They now correspond to those with Duct Location = Garage, Unvented Attic, or Vented Attic.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Duct Leakage and Insulation** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0% Leakage to Outside, Uninsulated
     - 10% Leakage to Outside, R-4
     - 10% Leakage to Outside, R-6
     - 10% Leakage to Outside, R-8
     - 10% Leakage to Outside, Uninsulated
     - 20% Leakage to Outside, R-4
     - 20% Leakage to Outside, R-6
     - 20% Leakage to Outside, R-8
     - 20% Leakage to Outside, Uninsulated
     - 30% Leakage to Outside, R-4
     - 30% Leakage to Outside, R-6
     - 30% Leakage to Outside, R-8
     - 30% Leakage to Outside, Uninsulated
     - None
   * - Stock saturation
     - 30%
     - 3.9%
     - 0.89%
     - 1.8%
     - 5.5%
     - 7%
     - 1.6%
     - 3.2%
     - 9.9%
     - 4%
     - 0.93%
     - 1.8%
     - 5.7%
     - 24%
   * - ``hvac_ducts_leakage_units``
     - Percent
     - Percent
     - Percent
     - Percent
     - Percent
     - Percent
     - Percent
     - Percent
     - Percent
     - Percent
     - Percent
     - Percent
     - Percent
     - Percent
   * - ``hvac_ducts_leakage_to_outside_value``
     - 0.0
     - 0.1
     - 0.1
     - 0.1
     - 0.1
     - 0.2
     - 0.2
     - 0.2
     - 0.2
     - 0.3
     - 0.3
     - 0.3
     - 0.3
     - 0.0
   * - ``hvac_ducts_supply_insulation_r_value``
     - 0
     - 4
     - 6
     - 8
     - 0
     - 4
     - 6
     - 8
     - 0
     - 4
     - 6
     - 8
     - 0
     - 0
   * - ``hvac_ducts_return_insulation_r_value``
     - 0
     - 4
     - 6
     - 8
     - 0
     - 4
     - 6
     - 8
     - 0
     - 4
     - 6
     - 8
     - 0
     - 0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_ducts_leakage_units``
     - 
     - The units for the duct leakage.
   * - ``hvac_ducts_leakage_to_outside_value``
     - 
     - The leakage to outside value.
   * - ``hvac_ducts_supply_insulation_r_value``
     - F-ft2-hr/Btu
     - The nominal insulation r-value of the supply ducts excluding air films. Use 0 for uninsulated ducts.
   * - ``hvac_ducts_return_insulation_r_value``
     - F-ft2-hr/Btu
     - The nominal insulation r-value of the return ducts excluding air films. Use 0 for uninsulated ducts.
.. _duct_location:

Duct Location
-------------

Description
***********

Location of Duct System

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \OpenStudio-HPXML v1.6.0 and Wilson et al., 'Building America House Simulation Protocols', 2014


Assumption
**********

- \Based on default duct location assignment in OpenStudio-HPXML: the first present space type in the order of: basement - conditioned, basement - unconditioned, crawlspace - conditioned, crawlspace - vented, crawlspace - unvented, attic - vented, attic - unvented, garage, or living space


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Duct Location** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Attic
     - Crawlspace
     - Garage
     - Heated Basement
     - Living Space
     - None
     - Unheated Basement
   * - Stock saturation
     - 17%
     - 15%
     - 4.8%
     - 11%
     - 20%
     - 24%
     - 9%
   * - ``hvac_ducts_supply_location_location``
     - attic
     - crawlspace
     - garage
     - basement
     - conditioned space
     - conditioned space
     - basement
   * - ``hvac_ducts_return_location_location``
     - attic
     - crawlspace
     - garage
     - basement
     - conditioned space
     - conditioned space
     - basement

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_ducts_supply_location_location``
     - 
     - The primary location of the supply ducts.
   * - ``hvac_ducts_return_location_location``
     - 
     - The primary location of the return ducts.
.. _eaves:

Eaves
-----

Description
***********

Depth of roof eaves.

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Eaves** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 2 ft
   * - Stock saturation
     - 100%
   * - ``geometry_eaves_depth``
     - 2

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_eaves_depth``
     - ft
     - The depth of the eaves extending from the roof.
.. _electric_vehicle_battery:

Electric Vehicle Battery
------------------------

Description
***********

The type of electric vehicle and battery range in miles.

Created by
**********

``sources/tempo/tsv_maker.py``

Source
******

- \the 2023 Vehicle Stock Projection Data from NREL's TEMPO model.

- \EV Registration Data from Experian 2023.


Assumption
**********

- \Vehicle stock data starts with the Experian registration data and then is projected by TEMPO to 2023.

- \If the household does not have an Electric Vehicle, the options represent the household preference.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Electric Vehicle Battery** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Compact, Battery Electric Vehicle, 200 mile range
     - Compact, Battery Electric Vehicle, 300 mile range
     - Midsize, Battery Electric Vehicle, 200 mile range
     - Midsize, Battery Electric Vehicle, 300 mile range
     - Pickup, Battery Electric Vehicle, 200 mile range
     - Pickup, Battery Electric Vehicle, 300 mile range
     - SUV, Battery Electric Vehicle, 200 mile range
     - SUV, Battery Electric Vehicle, 300 mile range
   * - Stock saturation
     - 12%
     - 34%
     - 3%
     - 7.6%
     - 0.0055%
     - 0.77%
     - 12%
     - 31%
   * - ``electric_vehicle_type``
     - BatteryElectricVehicle
     - BatteryElectricVehicle
     - BatteryElectricVehicle
     - BatteryElectricVehicle
     - BatteryElectricVehicle
     - BatteryElectricVehicle
     - BatteryElectricVehicle
     - BatteryElectricVehicle
   * - ``electric_vehicle_usable_battery_capacity``
     - 40.168
     - 63.433
     - 41.978
     - 65.441
     - 67.738
     - 105.946
     - 53.503
     - 83.68
   * - ``electric_vehicle_fuel_economy_units``
     - kWh/mile
     - kWh/mile
     - kWh/mile
     - kWh/mile
     - kWh/mile
     - kWh/mile
     - kWh/mile
     - kWh/mile
   * - ``electric_vehicle_fuel_economy_combined``
     - 0.209901
     - 0.22002
     - 0.219174
     - 0.229449
     - 0.357648
     - 0.373794
     - 0.267513
     - 0.278934
   * - ``electric_vehicle_miles_driven_per_year``
     - 11000
     - 11000
     - 11000
     - 11000
     - 11000
     - 11000
     - 11000
     - 11000

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``electric_vehicle_type``
     - 
     - The type of vehicle.
   * - ``electric_vehicle_usable_battery_capacity``
     - kWh
     - The usable capacity of the electric vehicle battery.
   * - ``electric_vehicle_fuel_economy_units``
     - 
     - The combined fuel economy units of the vehicle.
   * - ``electric_vehicle_fuel_economy_combined``
     - 
     - The combined fuel economy of the vehicle.
   * - ``electric_vehicle_miles_driven_per_year``
     - miles/yr
     - Number of miles driven per year with the vehicle.
.. _electric_vehicle_charge_at_home:

Electric Vehicle Charge At Home
-------------------------------

Description
***********

The percentage a household would or do charge their electric vehicle at home.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The two sub-tsvs have the following dependencies: tsv1 dependency=['Geometry Building Type RECS'], tsv2 dependency=['Federal Poverty Level'], In combining tsv1 and tsv2, the conditional relationships are ignored across ('Geometry Building Type RECS' and 'Federal Poverty Level').


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Electric Vehicle Charge At Home** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0-19%
     - 20-39%
     - 40-59%
     - 60-79%
     - 80-99%
     - 100%
   * - Stock saturation
     - 13%
     - 1.4%
     - 1.9%
     - 7.3%
     - 34%
     - 42%
   * - ``ev_fraction_charged_home``
     - 0.10
     - 0.30
     - 0.50
     - 0.70
     - 0.90
     - 1.00

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``ev_fraction_charged_home``
     - 
     - The fraction of charging energy provided by the at-home charger to the electric vehicle.
.. _electric_vehicle_charger:

Electric Vehicle Charger
------------------------

Description
***********

Type of electric vehicle charger used at the dwelling unit

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Dwelling units with an electric vehicle need to have at least a Level 1 charger.Due to low sample sizes, fallback rules applied with lumping of:

  - \[1] Federal Poverty Level lumped every 100%

  - \[2] Federal Poverty Level lumped every 200%

  - \[3] Building type is consolidated into three bins 1) single-family detached and 2) multi-family with 5+ units, and 3) mobile homes, multi-family 2-4 units, and single-family attached

  - \[4] Building type is consolidated into two bins 1) single-family detached and all other building types

  - \[5] Federal Poverty Level is combined into 400%+ and <400% bins


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Electric Vehicle Charger** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Level 1 charger
     - Level 2 charger
     - None
     - Void
   * - Stock saturation
     - 0.86%
     - 0.59%
     - 99%
     - 0%
   * - ``electric_vehicle_charger_level``
     - 1
     - 2
     - 
     - 
   * - ``electric_vehicle_charger_power``
     - 1600
     - 5690
     - 
     - 
   * - ``electric_vehicle_charger_fraction_charged_at_home``
     - 1.0
     - 1.0
     - 
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``electric_vehicle_charger_level``
     - 
     - The charging level of the EV charger.
   * - ``electric_vehicle_charger_power``
     - W
     - The rated power output of the EV charger.
   * - ``electric_vehicle_charger_fraction_charged_at_home``
     - frac
     - The fraction of charging energy provided by the at-home charger to the vehicle.
.. _electric_vehicle_miles_traveled:

Electric Vehicle Miles Traveled
-------------------------------

Description
***********

The number of miles an electric vehicle is driven in a year if the unit owns an electric vehicle.; Because EVs drive less miles/year than ICE (https://www.sciencedirect.com/science/article/pii/S254243512300404X?via%3Dihub#abs0015), the max value is capped at 22,500 miles/yr and the distribution is shifted to reduce the mean.

Created by
**********

manually created

Source
******

- \the 2022 U.S. Federal Highway Administration National Household Travel Survey (NHTS) microdata.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Electric Vehicle Miles Traveled** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 1000
     - 3000
     - 5000
     - 7000
     - 9000
     - 11000
     - 13000
     - 15000
     - 17000
     - 19000
     - 22500
   * - Stock saturation
     - 11%
     - 11%
     - 13%
     - 13%
     - 12%
     - 11%
     - 9.3%
     - 7.5%
     - 5.9%
     - 4.6%
     - 1.6%
   * - ``vehicle_miles_driven_per_year``
     - 1000
     - 3000
     - 5000
     - 7000
     - 9000
     - 11000
     - 13000
     - 15000
     - 17000
     - 19000
     - 22500

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``vehicle_miles_driven_per_year``
     - miles
     - The annual miles the vehicle is driven.
.. _electric_vehicle_outlet_access:

Electric Vehicle Outlet Access
------------------------------

Description
***********

The unit has an outlet within 20 feet of vehicle parking.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \RECS 2020 has Multi-Family 5+ units marked as Not Applicable. These units are replaced by data from the No Place Like Home Study (https://www.nrel.gov/docs/fy22osti/81065.pdf) Table 1 Scenario 2. Multi-Family 5+ units owners is assumed for 12% units having electrical access. This fraction is based on the average of mid-capacity apt and high-capacity apt. Multi-Family 5+ units owners is assumed for 28% units having electrical access.

- \Units reported to have an L1 or L2 charger in the field EVCHRGTYPE are assumed to have outlet access.

- \L1 chargers without outlet access are units with EVs, but report no outlet access within 20 ft of vehicle parking.

- \Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:

- \Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'Vintage ACS', 'Electric Vehicle Charger'] with the following fallback coarsening order

  - \[1] Vintage ACS to the National distribution

  - \[2] Combining Geometry Building Type RECS together into SFD+MF+SFA and MF 2-4+MF 5+ bins

- \Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across (['Vintage ACS', 'Electric Vehicle Charger'], ['Tenure', 'Federal Poverty Level']).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Electric Vehicle Outlet Access** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - No
     - Yes
     - Void
   * - Stock saturation
     - 44%
     - 56%
     - 0%

.. _electric_vehicle_ownership:

Electric Vehicle Ownership
--------------------------

Description
***********

The dwelling unit owns an electric vehicle.

Created by
**********

``sources/experian/tsv_maker.py``

Source
******

- \EV Registration Data from Experian 2023.

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Due to low sample sizes, fallback rules applied with lumping of:

  - \[1] Federal Poverty Level lumped every 100%

  - \[2] Federal Poverty Level lumped every 200%

  - \[3] Building type is consolidated into three bins 1) single-family, 2) multi-family, and 3) mobile home bins

  - \[4] Building type is consolidated into two bins 1) single-family and 2) multi-family and mobile home bins

- \PUMA level battery electric vehicle saturation is calculated using a weighted average of the County level Experian data and ResStock unit counts for each County and PUMA.

- \The RECS 2020 saturations for each segment in a given PUMA are scaled to match the Experian PUMA weighted averaged battery electric vehicle saturation using the segment unit counts from PUMS 2019-5yrs survey.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Electric Vehicle Ownership** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - No
     - Yes
     - Void
   * - Stock saturation
     - 99%
     - 1.4%
     - 0%

.. _energystar_climate_zone_2023:

Energystar Climate Zone 2023
----------------------------

Description
***********

Climate zones for windows, doors, and skylights per EnergyStar guidelines as of 2023.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Area definition approximated based on published map retrieved May 2023 from: https://www.energystar.gov/products/residential_windows_doors_and_skylights/key_product_criteria.

- \by Brian Booher of D+R International, a support contractor for the ENERGY STAR windows, doors, and skylights program.


Assumption
**********

- \EnergyStar Climate Zones assigned based on CEC Climate Zone for CA and based on County everywhere else.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Energystar Climate Zone 2023** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - North-Central
     - Northern
     - South-Central
     - Southern
     - Void
   * - Stock saturation
     - 25%
     - 37%
     - 23%
     - 15%
     - 0%

.. _federal_poverty_level:

Federal Poverty Level
---------------------

Description
***********

Federal poverty level of the household occupying the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \% Federal Poverty Level is calculated using annual household income in 2019USD (continuous, not binned) from 2019-5yrs PUMS data and 2019 Federal Poverty Lines for contiguous US, where the FPL threshold for 1-occupant household is $12490 and $4420 for every additional person in the household.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Federal Poverty Level** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0-100%
     - 100-150%
     - 150-200%
     - 200-300%
     - 300-400%
     - 400%+
     - Not Available
   * - Stock saturation
     - 10%
     - 7.5%
     - 7.2%
     - 14%
     - 12%
     - 37%
     - 12%

.. _generation_and_emissions_assessment_region:

Generation And Emissions Assessment Region
------------------------------------------

Description
***********

The generation and carbon emissions assessment region that the sample is located in.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Gagnon, Pieter, Sanchez Perez, Pedro Andres, Obika, Kodi, et al., Cambium 2023 Scenario Descriptions and Documentation, (2024), https://doi.org/10.2172/2316014f


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Generation And Emissions Assessment Region** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - CAISO
     - ERCOT
     - FRCC
     - ISONE
     - MISO Central
     - MISO North
     - MISO South
     - None
     - Northern Grid East
     - Northern Grid South
     - Northern Grid West
     - NYISO
     - PJM East
     - PJM West
     - SERTP
     - SPP North
     - SPP South
     - West Connect North
     - West Connect South
   * - Stock saturation
     - 10%
     - 6.8%
     - 6.5%
     - 4.8%
     - 7.6%
     - 5%
     - 3.3%
     - 0.63%
     - 0.95%
     - 1.7%
     - 3.5%
     - 6.1%
     - 17%
     - 3%
     - 13%
     - 0.94%
     - 3.8%
     - 1.9%
     - 3%

.. _geometry_attic_type:

Geometry Attic Type
-------------------

Description
***********

The dwelling unit attic type.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Multi-Family building types and Mobile Homes have Flat Roof (None) only.

- \1-story Single-Family building types cannot have Finished Attic/Cathedral Ceiling because that attic type is modeled as a new story and 1-story does not a second story. 4+story Single-Family and mobile homes are an impossible combination.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Attic Type** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Finished Attic or Cathedral Ceilings
     - None
     - Unvented Attic
     - Vented Attic
   * - Stock saturation
     - 1.4%
     - 56%
     - 3.3%
     - 40%
   * - ``geometry_attic_type_attic_type``
     - ConditionedAttic
     - FlatRoof
     - UnventedAttic
     - VentedAttic
   * - ``geometry_attic_type_roof_type``
     - gable
     - 
     - gable
     - gable
   * - ``geometry_roof_pitch``
     - 6:12
     - 6:12
     - 6:12
     - 6:12

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_attic_type_attic_type``
     - 
     - The type of attic. Conditioned attics are not allowed for apartment units.
   * - ``geometry_attic_type_roof_type``
     - 
     - The type of roof.
   * - ``geometry_roof_pitch``
     - 
     - The roof pitch of the attic. Ignored if the building has a flat roof.
.. _geometry_building_horizontal_location_mf:

Geometry Building Horizontal Location MF
----------------------------------------

Description
***********

Location of the single-family attached unit horizontally within the building (left, middle, right).

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \Calculated directly from other distributions


Assumption
**********

- \All values are calculated assuming the building has double-loaded corridors (with some exceptions like 3 units in single-story building).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Building Horizontal Location MF** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Left
     - Middle
     - None
     - Not Applicable
     - Right
   * - Stock saturation
     - 7.1%
     - 8%
     - 74%
     - 4.2%
     - 7.1%
   * - ``geometry_unit_horizontal_location``
     - Left
     - Middle
     - 
     - None
     - Right

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_unit_horizontal_location``
     - 
     - The horizontal location of the unit when viewing the front of the building. This is required for single-family attached and apartment units.
.. _geometry_building_horizontal_location_sfa:

Geometry Building Horizontal Location SFA
-----------------------------------------

Description
***********

Location of the single-family attached unit horizontally within the building (left, middle, right).

Created by
**********

manually created

Source
******

- \Calculated directly from other distributions


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Building Horizontal Location SFA** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Left
     - Middle
     - Right
     - None
   * - Stock saturation
     - 0.63%
     - 4.6%
     - 0.63%
     - 94%
   * - ``geometry_unit_horizontal_location``
     - Left
     - Middle
     - Right
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_unit_horizontal_location``
     - 
     - The horizontal location of the unit when viewing the front of the building. This is required for single-family attached and apartment units.
.. _geometry_building_level_mf:

Geometry Building Level MF
--------------------------

Description
***********

Location of the multi-family unit vertically within the building (bottom, middle, top).

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \Calculated directly from other distributions


Assumption
**********

- \Calculated using the number of stories, where buildings >=2 stories have Top and Bottom probabilities = 1/Geometry Stories, and Middle probabilities = 1 - 2/Geometry stories


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Building Level MF** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Bottom
     - Middle
     - None
     - Top
   * - Stock saturation
     - 11%
     - 6.1%
     - 74%
     - 8.9%
   * - ``geometry_unit_level``
     - Bottom
     - Middle
     - 
     - Top

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_unit_level``
     - 
     - The level of the unit. This is required for apartment units.
.. _geometry_building_number_units_mf:

Geometry Building Number Units MF
---------------------------------

Description
***********

The number of dwelling units in the multi-family building.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Uses NUMAPTS field in RECS

- \RECS does not report NUMAPTS for Multifamily 2-4 units, so assumptions are made based on the number of stories

- \Data was sampled from the following bins of Geometry Stories: 1, 2, 3, 4-7, 8+


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Building Number Units MF** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 2
     - 3
     - 4
     - 5
     - 6
     - 7
     - 8
     - 9
     - 10
     - 11
     - 12
     - 13
     - 14
     - 15
     - 16
     - 17
     - 18
     - 19
     - 20
     - 24
     - 30
     - 36
     - 43
     - 67
     - 116
     - 183
     - 326
     - None
   * - Stock saturation
     - 3.6%
     - 1.4%
     - 3%
     - 0.54%
     - 1.5%
     - 0.26%
     - 2.3%
     - 0.15%
     - 0.95%
     - 0.098%
     - 1.9%
     - 0.15%
     - 0.18%
     - 0.27%
     - 0.61%
     - 0.023%
     - 0.22%
     - 0.016%
     - 0.75%
     - 0.96%
     - 0.81%
     - 0.48%
     - 0.67%
     - 2.7%
     - 1.2%
     - 0.62%
     - 1%
     - 74%
   * - ``geometry_building_num_units``
     - 2
     - 3
     - 4
     - 5
     - 6
     - 7
     - 8
     - 9
     - 10
     - 11
     - 12
     - 13
     - 14
     - 15
     - 16
     - 17
     - 18
     - 19
     - 20
     - 24
     - 30
     - 36
     - 43
     - 67
     - 116
     - 183
     - 326
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_building_num_units``
     - #
     - The number of units in the building.
.. _geometry_building_number_units_sfa:

Geometry Building Number Units SFA
----------------------------------

Description
***********

Number of units in the single-family attached building.

Created by
**********

manually created

Source
******

- \U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Building Number Units SFA** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - 2
     - 3
     - 4
     - 5
     - 6
     - 7
     - 8
     - 9
     - 10
     - 12
     - 15
     - 16
     - 20
     - 24
     - 30
     - 36
     - 50
     - 60
     - 90
     - 144
   * - Stock saturation
     - 94%
     - 0%
     - 0%
     - 0%
     - 0.72%
     - 0.78%
     - 0.36%
     - 1.1%
     - 0%
     - 0.38%
     - 0.57%
     - 0.14%
     - 0.33%
     - 0.27%
     - 0.27%
     - 0.27%
     - 0.27%
     - 0.13%
     - 0.1%
     - 0.086%
     - 0.11%
   * - ``geometry_building_num_units``
     - 
     - 2
     - 3
     - 4
     - 5
     - 6
     - 7
     - 8
     - 9
     - 10
     - 12
     - 15
     - 16
     - 20
     - 24
     - 30
     - 36
     - 50
     - 60
     - 90
     - 144

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_building_num_units``
     - #
     - The number of units in the building.
.. _geometry_building_type_acs:

Geometry Building Type ACS
--------------------------

Description
***********

The building type classification according to the U.S. Census American Community Survey.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Building Type ACS** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 2 Unit
     - 3 or 4 Unit
     - 5 to 9 Unit
     - 10 to 19 Unit
     - 20 to 49 Unit
     - 50 or more Unit
     - Mobile Home
     - Single-Family Attached
     - Single-Family Detached
   * - Stock saturation
     - 3.6%
     - 4.4%
     - 4.7%
     - 4.5%
     - 3.7%
     - 5.6%
     - 6.2%
     - 5.9%
     - 61%

.. _geometry_building_type_height:

Geometry Building Type Height
-----------------------------

Description
***********

The 2009 U.S. Energy Information Administration Residential Energy Consumption Survey  building type with multi-family buildings split out by low-rise, mid-rise, and high-rise.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \Calculated directly from other distributions


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Building Type Height** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Mobile Home
     - Multi-Family with 2 - 4 Units
     - Multi-Family with 5+ Units, 1-3 Stories
     - Multi-Family with 5+ Units, 4-7 Stories
     - Multi-Family with 5+ Units, 8+ Stories
     - Single-Family Attached
     - Single-Family Detached
   * - Stock saturation
     - 6.2%
     - 8%
     - 13%
     - 3.4%
     - 2.1%
     - 5.9%
     - 61%

.. _geometry_building_type_recs:

Geometry Building Type RECS
---------------------------

Description
***********

The building type classification according to the U.S. Energy Information Administration Residential Energy Consumption Survey.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Building Type RECS** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Mobile Home
     - Multi-Family with 2 - 4 Units
     - Multi-Family with 5+ Units
     - Single-Family Attached
     - Single-Family Detached
   * - Stock saturation
     - 6.2%
     - 8%
     - 18%
     - 5.9%
     - 61%
   * - ``geometry_unit_aspect_ratio``
     - 1.8
     - 0.5556
     - 0.5556
     - 0.5556
     - 1.8
   * - ``geometry_ceiling_height_height``
     - 8.0
     - 8.0
     - 8.0
     - 8.0
     - 8.0
   * - ``geometry_facility_type``
     - manufactured home
     - apartment unit
     - apartment unit
     - single-family attached
     - single-family detached

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_unit_aspect_ratio``
     - Frac
     - The ratio of front/back wall length to left/right wall length for the unit, excluding any protruding garage wall area.
   * - ``geometry_ceiling_height_height``
     - ft
     - Average distance from the floor to the ceiling.
   * - ``geometry_facility_type``
     - 
     - The facility type of the dwelling unit.
.. _geometry_floor_area:

Geometry Floor Area
-------------------

Description
***********

The finished floor area of the dwelling unit using bins from 2017-2019 AHS.

Created by
**********

``sources/ahs/ahs2017_2019/tsv_maker.py``

Source
******

- \2017 and 2019 American Housing Survey (AHS) microdata.


Assumption
**********

- \Due to low sample count, the tsv is constructed by downscaling a core sub-tsv with 3 sub-tsvs of different dependencies. The sub-tsvs have the following dependencies: tsv1 : 'Census Division', 'PUMA Metro Status', 'Geometry Building Type RECS', 'Income RECS2020'

- \tsv2 : 'Census Division', 'PUMA Metro Status', 'Geometry Building Type RECS', 'Tenure'

- \tsv3 : 'Census Division', 'PUMA Metro Status', 'Geometry Building Type RECS', 'Vintage ACS'

- \tsv4 : 'Census Division', 'PUMA Metro Status', 'Income RECS2020', 'Tenure'. For each sub-tsv, rows with <10 samples are replaced with coarsening dependency Census Region, followed by National.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Floor Area** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0-499
     - 500-749
     - 750-999
     - 1000-1499
     - 1500-1999
     - 2000-2499
     - 2500-2999
     - 3000-3999
     - 4000+
   * - Stock saturation
     - 3.2%
     - 8.5%
     - 15%
     - 26%
     - 19%
     - 12%
     - 6.5%
     - 6.1%
     - 3%
   * - ``geometry_unit_cfa_bin``
     - 0-499
     - 500-749
     - 750-999
     - 1000-1499
     - 1500-1999
     - 2000-2499
     - 2500-2999
     - 3000-3999
     - 4000+

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_unit_cfa_bin``
     - 
     - E.g., '2000-2499'.
.. _geometry_floor_area_bin:

Geometry Floor Area Bin
-----------------------

Description
***********

The finished floor area of the dwelling unit using bins from the U.S. Energy Information Administration Residential Energy Consumption Survey.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \Geometry Floor Area bins are from the UNITSIZE field of the 2017 American Housing Survey (AHS).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Floor Area Bin** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0-1499
     - 1500-2499
     - 2500-3999
     - 4000+
   * - Stock saturation
     - 53%
     - 32%
     - 13%
     - 3%

.. _geometry_foundation_type:

Geometry Foundation Type
------------------------

Description
***********

The type of foundation.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \The sample counts and sample weights are constructed using U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \All mobile homes have Ambient foundations.

- \Multi-family buildings cannot have Ambient and Heated Basements

- \Single-family attached buildings cannot have Ambient foundations

- \Foundation types are the same for each building type except mobile homes and the applicable options.

- \Because we need to assume a foundation type for ground-floor MF units, we use the lumped SFD+SFA distributions for MF2-4 and MF5+ building foundations. (RECS data for households in MF2-4 unit buildings are not useful since we do not know which floor the unitis on. RECS does not include foundation responses for households in MF5+ unit buildings.)

- \For Single-Family Detached, if no foundation type specified, then sample has Ambient foundation.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Foundation Type** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Ambient
     - Heated Basement
     - Slab
     - Unheated Basement
     - Unvented Crawlspace
     - Vented Crawlspace
   * - Stock saturation
     - 8.9%
     - 12%
     - 39%
     - 15%
     - 1.9%
     - 22%
   * - ``geometry_foundation_type_type``
     - Ambient
     - ConditionedBasement
     - SlabOnGrade
     - UnconditionedBasement
     - UnventedCrawlspace
     - VentedCrawlspace
   * - ``geometry_foundation_type_height``
     - 4.0
     - 8.0
     - 0.0
     - 8.0
     - 4.0
     - 4.0
   * - ``geometry_foundation_type_height_above_grade``
     - 1.0
     - 1.0
     - 0.0
     - 1.0
     - 1.0
     - 1.0
   * - ``geometry_foundation_type_rim_joist_height``
     - 0.0
     - 9.25
     - 0.0
     - 9.25
     - 9.25
     - 9.25

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_foundation_type_type``
     - 
     - The foundation type of the building. Garages are assumed to be over slab-on-grade.
   * - ``geometry_foundation_type_height``
     - ft
     - The height of the foundation.
   * - ``geometry_foundation_type_height_above_grade``
     - ft
     - The height of the foundation that is above-grade.
   * - ``geometry_foundation_type_rim_joist_height``
     - in
     - The height of the rim joists.
.. _geometry_garage:

Geometry Garage
---------------

Description
***********

The size of an attached garage.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Only Single-Family Detached homes are assigned a probability for attached garage.

- \No garage for ambient (i.e., pier & beam) foundation type.

- \Due to modeling constraints restricting that garage cannot be larger or deeper than livable space: Single-family detached units that are 0-1499 square feet can only have a maximum of a 1 car garage.

- \Single-family detached units that are 0-1499 square feet and 3+ stories cannot have a garage.

- \The geometry stories distributions are all the same except for 0-1499 square feet and 3 stories.

- \Single-family detached units that are 1500-2499 square feet can not have a 3 car garage.

- \Single-family detached units that are 2500-3999 square feet and a heated basement can not have a 3 car garage. Due to low sample sizes, 1. Crawl, basements, and slab are lumped.

- \2. Story levels are lumped together.

- \2. Census Division RECS is grouped into Census Region.

- \2. Vintage ACS is progressively grouped into: pre-1960, 1960-1999, and 2000+.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Garage** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 1 Car
     - 2 Car
     - 3 Car
     - None
   * - Stock saturation
     - 10%
     - 19%
     - 2.6%
     - 68%
   * - ``geometry_garage_type_width``
     - 12
     - 21
     - 30
     - 0
   * - ``geometry_garage_type_depth``
     - 20
     - 20
     - 20
     - 0
   * - ``geometry_garage_type_position``
     - Right
     - Right
     - Right
     - Left
   * - ``geometry_garage_type_protrusion``
     - 0.5
     - 0.5
     - 0.5
     - 0.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_garage_type_width``
     - ft
     - The width of the garage.
   * - ``geometry_garage_type_depth``
     - ft
     - The depth of the garage.
   * - ``geometry_garage_type_position``
     - 
     - The side of the home that that garage is attached to (when viewed from the front).
   * - ``geometry_garage_type_protrusion``
     - frac
     - The fraction of the garage depth that is protruding from the conditioned space.
.. _geometry_space_combination:

Geometry Space Combination
--------------------------

Description
***********

Valid combinations of building type, building level mf, attic, foundation, and garage

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For building level mf, only multi-family (MF) can have top, middle, or bottom units,

- \For foundation, mobile home (MH) has ambient only, MF cannot have ambient or heated basement, single-family attached cannot have ambient.

- \For attic, MH and MF have no attic.

- \For (attached) garage, only single-family detached without ambient foundation type can have garage.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Space Combination** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Mobile Home, Ambient, No Attic, No Garage
     - Multi-Family with 2 - 4 Units Bottom Unit, Slab, No Attic, No Garage
     - Multi-Family with 2 - 4 Units Bottom Unit, Unheated Basement, No Attic, No Garage
     - Multi-Family with 2 - 4 Units Bottom Unit, Unvented Crawlspace, No Attic, No Garage
     - Multi-Family with 2 - 4 Units Bottom Unit, Vented Crawlspace, No Attic, No Garage
     - Multi-Family with 2 - 4 Units Middle Unit, Slab, No Attic, No Garage
     - Multi-Family with 2 - 4 Units Middle Unit, Unheated Basement, No Attic, No Garage
     - Multi-Family with 2 - 4 Units Middle Unit, Unvented Crawlspace, No Attic, No Garage
     - Multi-Family with 2 - 4 Units Middle Unit, Vented Crawlspace, No Attic, No Garage
     - Multi-Family with 2 - 4 Units Top Unit, Slab, No Attic, No Garage
     - Multi-Family with 2 - 4 Units Top Unit, Unheated Basement, No Attic, No Garage
     - Multi-Family with 2 - 4 Units Top Unit, Unvented Crawlspace, No Attic, No Garage
     - Multi-Family with 2 - 4 Units Top Unit, Vented Crawlspace, No Attic, No Garage
     - Multi-Family with 5+ Units Bottom Unit, Slab, No Attic, No Garage
     - Multi-Family with 5+ Units Bottom Unit, Unheated Basement, No Attic, No Garage
     - Multi-Family with 5+ Units Bottom Unit, Unvented Crawlspace, No Attic, No Garage
     - Multi-Family with 5+ Units Bottom Unit, Vented Crawlspace, No Attic, No Garage
     - Multi-Family with 5+ Units Middle Unit, Slab, No Attic, No Garage
     - Multi-Family with 5+ Units Middle Unit, Unheated Basement, No Attic, No Garage
     - Multi-Family with 5+ Units Middle Unit, Unvented Crawlspace, No Attic, No Garage
     - Multi-Family with 5+ Units Middle Unit, Vented Crawlspace, No Attic, No Garage
     - Multi-Family with 5+ Units Top Unit, Slab, No Attic, No Garage
     - Multi-Family with 5+ Units Top Unit, Unheated Basement, No Attic, No Garage
     - Multi-Family with 5+ Units Top Unit, Unvented Crawlspace, No Attic, No Garage
     - Multi-Family with 5+ Units Top Unit, Vented Crawlspace, No Attic, No Garage
     - Single-Family Attached, Heated Basement, Finished Attic, No Garage
     - Single-Family Attached, Heated Basement, No Attic, No Garage
     - Single-Family Attached, Heated Basement, Unvented Attic, No Garage
     - Single-Family Attached, Heated Basement, Vented Attic, No Garage
     - Single-Family Attached, Slab, Finished Attic, No Garage
     - Single-Family Attached, Slab, No Attic, No Garage
     - Single-Family Attached, Slab, Unvented Attic, No Garage
     - Single-Family Attached, Slab, Vented Attic, No Garage
     - Single-Family Attached, Unheated Basement, Finished Attic, No Garage
     - Single-Family Attached, Unheated Basement, No Attic, No Garage
     - Single-Family Attached, Unheated Basement, Unvented Attic, No Garage
     - Single-Family Attached, Unheated Basement, Vented Attic, No Garage
     - Single-Family Attached, Unvented Crawlspace, Finished Attic, No Garage
     - Single-Family Attached, Unvented Crawlspace, No Attic, No Garage
     - Single-Family Attached, Unvented Crawlspace, Unvented Attic, No Garage
     - Single-Family Attached, Unvented Crawlspace, Vented Attic, No Garage
     - Single-Family Attached, Vented Crawlspace, Finished Attic, No Garage
     - Single-Family Attached, Vented Crawlspace, No Attic, No Garage
     - Single-Family Attached, Vented Crawlspace, Unvented Attic, No Garage
     - Single-Family Attached, Vented Crawlspace, Vented Attic, No Garage
     - Single-Family Detached, Ambient, Finished Attic, No Garage
     - Single-Family Detached, Ambient, No Attic, No Garage
     - Single-Family Detached, Ambient, Unvented Attic, No Garage
     - Single-Family Detached, Ambient, Vented Attic, No Garage
     - Single-Family Detached, Heated Basement, Finished Attic, 1 Car Garage
     - Single-Family Detached, Heated Basement, Finished Attic, 2 Car Garage
     - Single-Family Detached, Heated Basement, Finished Attic, 3 Car Garage
     - Single-Family Detached, Heated Basement, Finished Attic, No Garage
     - Single-Family Detached, Heated Basement, No Attic, 1 Car Garage
     - Single-Family Detached, Heated Basement, No Attic, 2 Car Garage
     - Single-Family Detached, Heated Basement, No Attic, 3 Car Garage
     - Single-Family Detached, Heated Basement, No Attic, No Garage
     - Single-Family Detached, Heated Basement, Unvented Attic, 1 Car Garage
     - Single-Family Detached, Heated Basement, Unvented Attic, 2 Car Garage
     - Single-Family Detached, Heated Basement, Unvented Attic, 3 Car Garage
     - Single-Family Detached, Heated Basement, Unvented Attic, No Garage
     - Single-Family Detached, Heated Basement, Vented Attic, 1 Car Garage
     - Single-Family Detached, Heated Basement, Vented Attic, 2 Car Garage
     - Single-Family Detached, Heated Basement, Vented Attic, 3 Car Garage
     - Single-Family Detached, Heated Basement, Vented Attic, No Garage
     - Single-Family Detached, Slab, Finished Attic, 1 Car Garage
     - Single-Family Detached, Slab, Finished Attic, 2 Car Garage
     - Single-Family Detached, Slab, Finished Attic, 3 Car Garage
     - Single-Family Detached, Slab, Finished Attic, No Garage
     - Single-Family Detached, Slab, No Attic, 1 Car Garage
     - Single-Family Detached, Slab, No Attic, 2 Car Garage
     - Single-Family Detached, Slab, No Attic, 3 Car Garage
     - Single-Family Detached, Slab, No Attic, No Garage
     - Single-Family Detached, Slab, Unvented Attic, 1 Car Garage
     - Single-Family Detached, Slab, Unvented Attic, 2 Car Garage
     - Single-Family Detached, Slab, Unvented Attic, 3 Car Garage
     - Single-Family Detached, Slab, Unvented Attic, No Garage
     - Single-Family Detached, Slab, Vented Attic, 1 Car Garage
     - Single-Family Detached, Slab, Vented Attic, 2 Car Garage
     - Single-Family Detached, Slab, Vented Attic, 3 Car Garage
     - Single-Family Detached, Slab, Vented Attic, No Garage
     - Single-Family Detached, Unheated Basement, Finished Attic, 1 Car Garage
     - Single-Family Detached, Unheated Basement, Finished Attic, 2 Car Garage
     - Single-Family Detached, Unheated Basement, Finished Attic, 3 Car Garage
     - Single-Family Detached, Unheated Basement, Finished Attic, No Garage
     - Single-Family Detached, Unheated Basement, No Attic, 1 Car Garage
     - Single-Family Detached, Unheated Basement, No Attic, 2 Car Garage
     - Single-Family Detached, Unheated Basement, No Attic, 3 Car Garage
     - Single-Family Detached, Unheated Basement, No Attic, No Garage
     - Single-Family Detached, Unheated Basement, Unvented Attic, 1 Car Garage
     - Single-Family Detached, Unheated Basement, Unvented Attic, 2 Car Garage
     - Single-Family Detached, Unheated Basement, Unvented Attic, 3 Car Garage
     - Single-Family Detached, Unheated Basement, Unvented Attic, No Garage
     - Single-Family Detached, Unheated Basement, Vented Attic, 1 Car Garage
     - Single-Family Detached, Unheated Basement, Vented Attic, 2 Car Garage
     - Single-Family Detached, Unheated Basement, Vented Attic, 3 Car Garage
     - Single-Family Detached, Unheated Basement, Vented Attic, No Garage
     - Single-Family Detached, Unvented Crawlspace, Finished Attic, 1 Car Garage
     - Single-Family Detached, Unvented Crawlspace, Finished Attic, 2 Car Garage
     - Single-Family Detached, Unvented Crawlspace, Finished Attic, 3 Car Garage
     - Single-Family Detached, Unvented Crawlspace, Finished Attic, No Garage
     - Single-Family Detached, Unvented Crawlspace, No Attic, 1 Car Garage
     - Single-Family Detached, Unvented Crawlspace, No Attic, 2 Car Garage
     - Single-Family Detached, Unvented Crawlspace, No Attic, 3 Car Garage
     - Single-Family Detached, Unvented Crawlspace, No Attic, No Garage
     - Single-Family Detached, Unvented Crawlspace, Unvented Attic, 1 Car Garage
     - Single-Family Detached, Unvented Crawlspace, Unvented Attic, 2 Car Garage
     - Single-Family Detached, Unvented Crawlspace, Unvented Attic, 3 Car Garage
     - Single-Family Detached, Unvented Crawlspace, Unvented Attic, No Garage
     - Single-Family Detached, Unvented Crawlspace, Vented Attic, 1 Car Garage
     - Single-Family Detached, Unvented Crawlspace, Vented Attic, 2 Car Garage
     - Single-Family Detached, Unvented Crawlspace, Vented Attic, 3 Car Garage
     - Single-Family Detached, Unvented Crawlspace, Vented Attic, No Garage
     - Single-Family Detached, Vented Crawlspace, Finished Attic, 1 Car Garage
     - Single-Family Detached, Vented Crawlspace, Finished Attic, 2 Car Garage
     - Single-Family Detached, Vented Crawlspace, Finished Attic, 3 Car Garage
     - Single-Family Detached, Vented Crawlspace, Finished Attic, No Garage
     - Single-Family Detached, Vented Crawlspace, No Attic, 1 Car Garage
     - Single-Family Detached, Vented Crawlspace, No Attic, 2 Car Garage
     - Single-Family Detached, Vented Crawlspace, No Attic, 3 Car Garage
     - Single-Family Detached, Vented Crawlspace, No Attic, No Garage
     - Single-Family Detached, Vented Crawlspace, Unvented Attic, 1 Car Garage
     - Single-Family Detached, Vented Crawlspace, Unvented Attic, 2 Car Garage
     - Single-Family Detached, Vented Crawlspace, Unvented Attic, 3 Car Garage
     - Single-Family Detached, Vented Crawlspace, Unvented Attic, No Garage
     - Single-Family Detached, Vented Crawlspace, Vented Attic, 1 Car Garage
     - Single-Family Detached, Vented Crawlspace, Vented Attic, 2 Car Garage
     - Single-Family Detached, Vented Crawlspace, Vented Attic, 3 Car Garage
     - Single-Family Detached, Vented Crawlspace, Vented Attic, No Garage
     - Void
   * - Stock saturation
     - 6.2%
     - 1.8%
     - 1.3%
     - 0.086%
     - 1.3%
     - 0.16%
     - 0.17%
     - 0.0049%
     - 0.15%
     - 1.3%
     - 0.82%
     - 0.068%
     - 0.88%
     - 3.8%
     - 1.2%
     - 0.21%
     - 1.8%
     - 2.8%
     - 1.2%
     - 0.13%
     - 1.5%
     - 3.1%
     - 1%
     - 0.18%
     - 1.5%
     - 0.04%
     - 0.63%
     - 0.046%
     - 0.46%
     - 0.057%
     - 1.2%
     - 0.11%
     - 0.94%
     - 0.049%
     - 0.51%
     - 0.036%
     - 0.35%
     - 0.0031%
     - 0.074%
     - 0.0063%
     - 0.063%
     - 0.04%
     - 0.69%
     - 0.052%
     - 0.47%
     - 0.053%
     - 0.82%
     - 0.14%
     - 1.6%
     - 0.026%
     - 0.071%
     - 0.0057%
     - 0.11%
     - 0.75%
     - 1.1%
     - 0.051%
     - 1.8%
     - 0.1%
     - 0.13%
     - 0.0059%
     - 0.26%
     - 1.3%
     - 2.1%
     - 0.1%
     - 3.3%
     - 0.052%
     - 0.23%
     - 0.059%
     - 0.12%
     - 1.5%
     - 3%
     - 0.5%
     - 2.6%
     - 0.22%
     - 0.51%
     - 0.076%
     - 0.41%
     - 2.7%
     - 6.3%
     - 1%
     - 4.8%
     - 0.026%
     - 0.045%
     - 0.0075%
     - 0.15%
     - 0.46%
     - 0.55%
     - 0.084%
     - 1.6%
     - 0.074%
     - 0.069%
     - 0.009%
     - 0.3%
     - 0.86%
     - 1.1%
     - 0.16%
     - 3.2%
     - 0.0013%
     - 0.0098%
     - 0.0026%
     - 0.003%
     - 0.043%
     - 0.16%
     - 0.034%
     - 0.1%
     - 0.0057%
     - 0.022%
     - 0.0035%
     - 0.013%
     - 0.08%
     - 0.33%
     - 0.062%
     - 0.19%
     - 0.041%
     - 0.085%
     - 0.014%
     - 0.14%
     - 0.8%
     - 1.2%
     - 0.14%
     - 2.5%
     - 0.11%
     - 0.17%
     - 0.019%
     - 0.41%
     - 1.3%
     - 2.2%
     - 0.27%
     - 4.4%
     - 0%

.. _geometry_stories:

Geometry Stories
----------------

Description
***********

The number of building stories.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \All mobile homes are 1 story.

- \Single-Family Detached and Single-Family Attached use the STORIES field in RECS, whereas Multifamily with 5+ units uses the NUMFLRS field.

- \Building types 2 Unit and 3 or 4 Unit use the stories distribution of Multifamily 5 to 9 Unit (capped at 4 stories) because RECS does not report stories or floors for multifamily with 2-4 units.

- \The dependency on floor area bins is removed for multifamily with 5+ units.

- \Vintage ACS rows for the 2010s are copied from the 2000-09 rows.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Stories** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 1
     - 2
     - 3
     - 4
     - 5
     - 6
     - 7
     - 8
     - 9
     - 10
     - 11
     - 12
     - 13
     - 14
     - 15
     - 20
     - 21
     - 35
   * - Stock saturation
     - 53%
     - 33%
     - 7.7%
     - 2%
     - 0.79%
     - 0.7%
     - 0.16%
     - 0.16%
     - 0.13%
     - 0.17%
     - 0.09%
     - 0.19%
     - 0.12%
     - 0.11%
     - 0.12%
     - 0.21%
     - 0.66%
     - 0.11%
   * - ``geometry_num_floors_above_grade``
     - 1
     - 2
     - 3
     - 4
     - 5
     - 6
     - 7
     - 8
     - 9
     - 10
     - 11
     - 12
     - 13
     - 14
     - 15
     - 20
     - 21
     - 35

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_num_floors_above_grade``
     - #
     - The number of floors above grade (in the unit if single-family detached or single-family attached, and in the building if apartment unit). Conditioned attics are included.
.. _geometry_stories_low_rise:

Geometry Stories Low Rise
-------------------------

Description
***********

Number of building stories for low-rise buildings.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \Calculated directly from other distributions


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Stories Low Rise** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 1
     - 2
     - 3
     - 4+
   * - Stock saturation
     - 53%
     - 33%
     - 7.7%
     - 5.7%

.. _geometry_story_bin:

Geometry Story Bin
------------------

Description
***********

The building has more than 8 or less than 8 stories.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Story Bin** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - <8
     - 8+
   * - Stock saturation
     - 98%
     - 2.1%

.. _geometry_wall_exterior_finish:

Geometry Wall Exterior Finish
-----------------------------

Description
***********

Wall siding material and color.

Created by
**********

``sources/lightbox/residential/tsv_maker.py``

Source
******

- \HIFLD Parcel data.


Assumption
**********

- \Rows where sample size < 10 are replaced with aggregated values down-scaled from dep='State' to dep='Census Division RECS'

- \Brick wall types are assumed to not have an additional brick exterior finish

- \Steel and wood frame walls must have an exterior finish


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Wall Exterior Finish** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Aluminum, Light
     - Brick, Light
     - Brick, Medium/Dark
     - Fiber-Cement, Light
     - None
     - Shingle, Asbestos, Medium
     - Shingle, Composition, Medium
     - Stucco, Light
     - Stucco, Medium/Dark
     - Vinyl, Light
     - Wood, Medium/Dark
   * - Stock saturation
     - 2.5%
     - 0.11%
     - 19%
     - 0.24%
     - 18%
     - 0.71%
     - 1.2%
     - 12%
     - 0.037%
     - 24%
     - 21%
   * - ``enclosure_wall_siding_type``
     - aluminum siding
     - brick veneer
     - brick veneer
     - fiber cement siding
     - not present
     - asbestos siding
     - composite shingle siding
     - stucco
     - stucco
     - vinyl siding
     - wood siding
   * - ``enclosure_wall_siding_color``
     - light
     - light
     - medium dark
     - light
     - medium
     - medium
     - medium
     - light
     - medium dark
     - light
     - medium dark
   * - ``enclosure_wall_siding_r_value``
     - 0.6
     - 0.7
     - 0.7
     - 0.2
     - 0.0
     - 0.6
     - 0.6
     - 0.2
     - 0.2
     - 0.6
     - 1.4

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_wall_siding_type``
     - 
     - The type of wall siding.
   * - ``enclosure_wall_siding_color``
     - 
     - The color of the walls.
   * - ``enclosure_wall_siding_r_value``
     - F-ft2-hr/Btu
     - The R-value of the siding.
.. _geometry_wall_type:

Geometry Wall Type
------------------

Description
***********

The wall material used for thermal mass calculations of exterior walls.

Created by
**********

``sources/lightbox/residential/tsv_maker.py``

Source
******

- \HIFLD Parcel data.


Assumption
**********

- \Rows where sample size < 10 are replaced with aggregated values down-scaled from dep='State' to dep='Census Division RECS'


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Geometry Wall Type** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Brick
     - Concrete
     - Steel Frame
     - Wood Frame
     - Void
   * - Stock saturation
     - 21%
     - 3.3%
     - 3.6%
     - 72%
     - 0%

.. _ground_thermal_conductivity:

Ground Thermal Conductivity
---------------------------

Description
***********

The thermal conductivity (in Btu/hr-ft-F) of the ground using in foundation and geothermal heat pump heat transfer calculations.

Created by
**********

``sources/smu/tsv_maker.py``

Source
******

- \data from the SMU Geothermal Laboratory. The data is from the Thermal Conductivity Observation in Content Model Format dataset. The data is available at http://geothermal.smu.edu/static/DownloadFilesButtonPage.htm.


Assumption
**********

- \The data obtained is from surveyed oil and gas well data.

- \The latitude and longitudes were assigned to counties and the data was joined to the ResStock spatial lookup tables. In this process, 1482 of 59332 samples did not have a FIPS match or did not have data and were dropped.

- \Due to limited data in climate zone 1A, data was pulled from samples in 1A plus Florida 2A.

- \Samples less than 0.5 Btu/hr-ft-F are assigned a value of 0.5 Btu/hr-ft-F. Samples greater than 2.6 Btu/hr-ft-F are assigned a value of 2.6 Btu/hr-ft-F.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Ground Thermal Conductivity** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0.5
     - 0.8
     - 1.1
     - 1.4
     - 1.7
     - 2.0
     - 2.3
     - 2.6
   * - Stock saturation
     - 0.59%
     - 7%
     - 46%
     - 36%
     - 7.8%
     - 2.3%
     - 0.23%
     - 0.16%
   * - ``location_soil_type_conductivity``
     - 0.5
     - 0.8
     - 1.1
     - 1.4
     - 1.7
     - 2.0
     - 2.3
     - 2.6

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``location_soil_type_conductivity``
     - Btu/hr-ft-F
     - The soil thermal conductivity.
.. _hvac_cooling_autosizing_factor:

HVAC Cooling Autosizing Factor
------------------------------

Description
***********

The cooling airflow and capacity scaling factor applied to the auto-sizing methodology (not used in project_national).

Created by
**********

manually created

Source
******

- \Engineering Judgment


Assumption
**********

- \HVAC sizing follows ACCA Manual J and Manual S. There is no additional oversizing or undersizing the airflow and capacity of the HVAC system.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Cooling Autosizing Factor** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - 40% Oversized
   * - Stock saturation
     - 100%
     - 0%
   * - ``cooling_system_cooling_autosizing_factor``
     - 
     - 1.4
   * - ``heat_pump_cooling_autosizing_factor``
     - 
     - 1.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``cooling_system_cooling_autosizing_factor``
     - 
     - The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.
   * - ``heat_pump_cooling_autosizing_factor``
     - 
     - The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.
.. _hvac_cooling_efficiency:

HVAC Cooling Efficiency
-----------------------

Description
***********

The presence and efficiency of primary cooling system in the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \Efficiency data based on CAC-ASHP-shipments-table.tsv, room_AC_efficiency_vs_age.tsv and expanded_HESC_HVAC_efficiencies.tsv combined with age of equipment data from RECS


Assumption
**********

- \Check the assumptions on the source tsv files.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Cooling Efficiency** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - AC, SEER2 7.6
     - AC, SEER2 9.5
     - AC, SEER2 12.4
     - AC, SEER2 14.3
     - Ducted Heat Pump
     - Non-Ducted Heat Pump
     - None
     - Room AC, CEER 8.4
     - Room AC, CEER 9.7
     - Room AC, CEER 10.6
     - Room AC, CEER 11.9
     - Shared Cooling
   * - Stock saturation
     - 0.9%
     - 6%
     - 30%
     - 12%
     - 15%
     - 0.97%
     - 11%
     - 0.43%
     - 2.6%
     - 9.6%
     - 7.4%
     - 3.8%
   * - ``hvac_cooling_system_type``
     - central air conditioner
     - central air conditioner
     - central air conditioner
     - central air conditioner
     - none
     - none
     - none
     - room air conditioner
     - room air conditioner
     - room air conditioner
     - room air conditioner
     - 
   * - ``hvac_cooling_system_cooling_efficiency_type``
     - SEER2
     - SEER2
     - SEER2
     - SEER2
     - 
     - 
     - 
     - CEER
     - CEER
     - CEER
     - CEER
     - 
   * - ``hvac_cooling_system_cooling_efficiency``
     - 7.6
     - 9.5
     - 12.4
     - 14.3
     - 
     - 
     - 
     - 8.4
     - 9.7
     - 10.6
     - 11.9
     - 
   * - ``hvac_cooling_system_cooling_compressor_type``
     - single stage
     - single stage
     - single stage
     - single stage
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_cooling_system_type``
     - 
     - The type of system.
   * - ``hvac_cooling_system_cooling_efficiency_type``
     - 
     - The cooling efficiency type. Central ACs and Mini-Split ACs use SEER2 or EER2; Room ACs and Packaged Terminal ACs use CEER or EER.
   * - ``hvac_cooling_system_cooling_efficiency``
     - 
     - The rated cooling efficiency.
   * - ``hvac_cooling_system_cooling_compressor_type``
     - 
     - The compressor type of the cooling system. Applies to Central ACs and Mini-Split ACs.
.. _hvac_cooling_partial_space_conditioning:

HVAC Cooling Partial Space Conditioning
---------------------------------------

Description
***********

The fraction of the finished floor area that the cooling system provides cooling.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.Hawaii constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Central AC systems need to serve at least 60 percent of the floor area.

- \Heat pumps serve 100 percent of the floor area because the system serves 100 percent of the heated floor area, except for in Hawaii

- \Due to low sample count, the tsv is constructed by downscaling a core sub-tsv with 3 sub-tsvs of different dependencies. The sub-tsvs have the following dependencies: tsv1 : 'HVAC Cooling Type', 'ASHRAE IECC Climate Zone 2004'

- \tsv2 : 'HVAC Cooling Type', 'Geometry Floor Area Bin'

- \tsv3 : 'HVAC Cooling Type', 'Geometry Building Type RECS'


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Cooling Partial Space Conditioning** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - <10% Conditioned
     - 20% Conditioned
     - 40% Conditioned
     - 60% Conditioned
     - 80% Conditioned
     - 100% Conditioned
     - None
     - Void
   * - Stock saturation
     - 0.47%
     - 6.4%
     - 5.9%
     - 6.6%
     - 3.6%
     - 67%
     - 11%
     - 0%
   * - ``hvac_cooling_system_cooling_load_served_fraction``
     - 0.1
     - 0.2
     - 0.4
     - 0.6
     - 0.8
     - 1.0
     - 0.0
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_cooling_system_cooling_load_served_fraction``
     - 
     - Fraction of load served by the HVAC system.
.. _hvac_cooling_type:

HVAC Cooling Type
-----------------

Description
***********

The presence and type of primary cooling system in the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py and sources/aris/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \Alaska specific distribution is based on Alaska Retrofit Information System (2008 to 2022) maintained by Alaska Housing Finance Corporation.


Assumption
**********

- \Due to low sample sizes, fallback rules applied with lumping of

- \1) HVAC Heating type: Non-ducted heating and None2) Geometry building SF: Mobile, Single family attached, Single family detached3) Geometry building MF: Multi-Family with 2 - 4 Units, Multi-Family with 5+ Units4) Vintage Lump: 20yrs binsHomes having ducted heat pump for heating and electricity fuel is assumed to haveducted heat pump for cooling (separating from central AC category)

- \Homes having non-ducted heat pump for heating is assumed to have non-ducted heat pumpfor cooling

- \For Hawaii, central air conditioning saturation is from RECS 2020 by heating type, ignoring allother dependencies

- \For Hawaii, Non-Ducted Heat Pump saturation is underestimated because ResStock does not currently allow cooling-only Non-Ducted Heat Pumps. These samples are modeled as Room ACs

- \For Alaska, we are using a field in ARIS that lumps multi-family 2-4 units and multi-family 5+ units buildings together. Data from the American Community Survey is used to distribute the between these two building types.

- \For Alaska, we are not modeling any central and room AC.

- \For Alaska, cooling systems are never shared.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Cooling Type** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Central AC
     - Ducted Heat Pump
     - Evaporative or Swamp Cooler
     - Non-Ducted Heat Pump
     - None
     - Room AC
   * - Stock saturation
     - 53%
     - 15%
     - 0%
     - 0.97%
     - 11%
     - 20%

.. _hvac_has_ducts:

HVAC Has Ducts
--------------

Description
***********

The presence of ducts in the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Ducted Heat Pump HVAC type assumed to have ducts

- \Non-Ducted Heat Pump HVAC type assumed to have no ducts

- \There are likely homes with non-ducted heat pump having ducts (Central AC with non-ducted HP) But due to structure of ResStock we are not accounting those homes

- \Evaporative or Swamp Cooler assigned Void option

- \None of the shared system options currently modeled (in HVAC Shared Efficiencies) are ducted, therefore where there are discrepancies between HVAC Heating Type, HVAC Cooling Type, and HVAC Has Shared System, HVAC Has Shared System takes precedence. (e.g., Central AC + Ducted Heating + Shared Heating and Cooling = No (Ducts)) (This is a temporary fix and will change when ducted shared system options are introduced.)


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Has Ducts** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - No
     - Yes
     - Void
   * - Stock saturation
     - 24%
     - 76%
     - 0%

.. _hvac_has_shared_system:

HVAC Has Shared System
----------------------

Description
***********

The presence of an HVAC system shared between multiple dwelling units.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Due to low sample sizes, the fallback rules are applied in following order

  - \[1] Vintage: Vintage ACS 20 year bin[2] HVAC Cooling Type: Lump 1) Central AC and Ducted Heat Pump and 2) Non-Ducted Heat Pump and None[3] HVAC Heating Type: Lump 1) Ducted Heating and Ducted Heat Pump and 2) Non-Ducted Heat Pump and None[4] HVAC Cooling Type: Lump 1) Central AC and Ducted Heat Pump and 2) Non-Ducted Heat Pump, Non-Ducted Heating, and None[5] HVAC Heating Type: Lump 1) Ducted Heating and Ducted Heat Pump and 2) Non-Ducted Heat Pump, None, and Room AC[6] Vintage: Vintage pre 1960s and post 2000[7] Vintage: All vintages

- \Evaporative or Swamp Cooler Cooling Type assigned Void option

- \Ducted Heat Pump assigned for both heating and cooling, other combinations assigned Void option

- \Non-Ducted Heat Pump assigned for both heating and cooling, other combinations assigned Void option


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Has Shared System** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Cooling Only
     - Heating and Cooling
     - Heating Only
     - None
     - Void
   * - Stock saturation
     - 1.4%
     - 2.4%
     - 7.2%
     - 89%
     - 0%

.. _hvac_has_zonal_electric_heating:

HVAC Has Zonal Electric Heating
-------------------------------

Description
***********

Presence of electric baseboard heating

Created by
**********

manually created

Source
******

- \n/a


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Has Zonal Electric Heating** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Yes
     - No
   * - Stock saturation
     - 6.3%
     - 94%

.. _hvac_heating_autosizing_factor:

HVAC Heating Autosizing Factor
------------------------------

Description
***********

The heating airflow and capacity scaling factor applied to the auto-sizing methodology (not used in project_national).

Created by
**********

manually created

Source
******

- \Engineering Judgment


Assumption
**********

- \HVAC sizing follows ACCA Manual J and Manual S. There is no additional oversizing or undersizing the airflow and capacity of the HVAC system.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Heating Autosizing Factor** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - 40% Oversized
   * - Stock saturation
     - 100%
     - 0%
   * - ``heating_system_heating_autosizing_factor``
     - 
     - 1.4
   * - ``heating_system_2_heating_autosizing_factor``
     - 
     - 1.0
   * - ``heat_pump_heating_autosizing_factor``
     - 
     - 1.0
   * - ``heat_pump_backup_heating_autosizing_factor``
     - 
     - 1.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``heating_system_heating_autosizing_factor``
     - 
     - The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.
   * - ``heating_system_2_heating_autosizing_factor``
     - 
     - The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.
   * - ``heat_pump_heating_autosizing_factor``
     - 
     - The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.
   * - ``heat_pump_backup_heating_autosizing_factor``
     - 
     - The capacity scaling factor applied to the auto-sizing methodology if Backup Type is integrated.
.. _hvac_heating_efficiency:

HVAC Heating Efficiency
-----------------------

Description
***********

The presence and efficiency of the primary heating system in the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py and sources/aris/tsv_maker.py``

Source
******

- \The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \Shipment data based on CAC-ASHP-shipments-table.tsv and furnace-shipments-table.tsv

- \Efficiency data based on expanded_HESC_HVAC_efficiencies.tsv combined with age of equipment data from RECS

- \Alaska specific distribution is based on Alaska Retrofit Information System (2008 to 2022) maintained by Alaska Housing Finance Corporation.


Assumption
**********

- \Check the assumptions on the source tsv files.

- \If a house has a wall furnace with fuel other than natural_gas, efficiency level based on natural_gas from expanded_HESC_HVAC_efficiencies.tsv is assigned.

- \If a house has a heat pump with fuel other than electricity (presumed dual-fuel heat pump), the heating type is assumed to be furnace and not heat pump.

- \The shipment volume for boiler was not available, so shipment volume for furnace in furnace-shipments-table.tsv was used instead.

- \Due to low sample size for some categories, the HVAC Has Shared System categories 'Cooling Only' and 'None' are combined for the purpose of querying Heating Efficiency distributions.

- \For 'other' heating system types, we assign them to Electric Baseboard if fuel is Electric, and assign them to Wall/Floor Furnace if fuel is natural_gas, fuel_oil or propane.

- \For Other Fuel and Wood, the lowest efficiency systems are assumed.

- \For Alaska, we are using a field in ARIS that lumps multi-family 2-4 units and multi-family 5+ units buildings together. Data from the American Community Survey is used to distribute the between these two building types.

- \For Alaska, electric space heaters are modeled as electric baseboards.

- \For Alaska, Toyo/monitor direct-vent devices and other fuel space heaters are not modeled.

- \For Alaska, fireplace and stoves are not modeled.

- \For Alaska, all heat pumps (including geothermal) are assumed to be non-ducted air source heat pumps.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Heating Efficiency** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - ASHP, SEER2 9.5, 5.8 HSPF2
     - ASHP, SEER2 12.4, 6.6 HSPF2
     - ASHP, SEER2 14.3, 7.4 HSPF2
     - Electric Baseboard, 100% Efficiency
     - Electric Boiler, 100% AFUE
     - Electric Furnace, 100% AFUE
     - Electric Wall Furnace, 100% AFUE
     - Fuel Boiler, 76% AFUE
     - Fuel Boiler, 80% AFUE
     - Fuel Boiler, 90% AFUE
     - Fuel Furnace, 60% AFUE
     - Fuel Furnace, 76% AFUE
     - Fuel Furnace, 80% AFUE
     - Fuel Furnace, 92.5% AFUE
     - Fuel Wall/Floor Furnace, 60% AFUE
     - Fuel Wall/Floor Furnace, 68% AFUE
     - MSHP, SEER2 13.7, 7.4 HSPF2
     - MSHP, SEER2 29, 12.3 HSPF2
     - None
     - Shared Heating
     - Void
   * - Stock saturation
     - 1.2%
     - 8.9%
     - 5.3%
     - 6.3%
     - 0.21%
     - 11%
     - 1.1%
     - 0.89%
     - 3.3%
     - 0.49%
     - 0.49%
     - 2.8%
     - 25%
     - 15%
     - 3.2%
     - 2.8%
     - 0.96%
     - 0.014%
     - 1.1%
     - 9.6%
     - 0%
   * - ``hvac_heating_system_type``
     - none
     - none
     - none
     - ElectricResistance
     - Boiler
     - Furnace
     - WallFurnace
     - Boiler
     - Boiler
     - Boiler
     - Furnace
     - Furnace
     - Furnace
     - Furnace
     - WallFurnace
     - WallFurnace
     - none
     - none
     - none
     - 
     - 
   * - ``hvac_heating_system_heating_efficiency``
     - 
     - 
     - 
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 0.76
     - 0.8
     - 0.9
     - 0.6
     - 0.76
     - 0.8
     - 0.925
     - 0.6
     - 0.68
     - 
     - 
     - 
     - 
     - 
   * - ``hvac_heating_system_heating_load_served_fraction``
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 
     - 
   * - ``hvac_heat_pump_type``
     - air-to-air
     - air-to-air
     - air-to-air
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - mini-split
     - mini-split
     - none
     - 
     - 
   * - ``hvac_heat_pump_cooling_efficiency_type``
     - SEER2
     - SEER2
     - SEER2
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - SEER2
     - SEER2
     - 
     - 
     - 
   * - ``hvac_heat_pump_cooling_efficiency``
     - 9.5
     - 12.4
     - 14.3
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 13.7
     - 29.0
     - 
     - 
     - 
   * - ``hvac_heat_pump_cooling_compressor_type``
     - single stage
     - single stage
     - single stage
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - variable speed
     - variable speed
     - 
     - 
     - 
   * - ``hvac_heat_pump_heating_efficiency_type``
     - HSPF2
     - HSPF2
     - HSPF2
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - HSPF2
     - HSPF2
     - 
     - 
     - 
   * - ``hvac_heat_pump_heating_efficiency``
     - 5.8
     - 6.6
     - 7.4
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 7.4
     - 12.3
     - 
     - 
     - 
   * - ``hvac_heat_pump_capacity_autosizing_methodology``
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - ACCA
     - 
     - 
   * - ``hvac_heat_pump_heating_load_served_fraction``
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 
     - 
   * - ``hvac_heat_pump_cooling_load_served_fraction``
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 1.0
     - 
     - 
   * - ``hvac_heat_pump_backup_type``
     - integrated
     - integrated
     - integrated
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - none
     - integrated
     - integrated
     - none
     - 
     - 
   * - ``hvac_heat_pump_backup_fuel``
     - electricity
     - electricity
     - electricity
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - electricity
     - electricity
     - 
     - 
     - 
   * - ``hvac_heat_pump_backup_heating_efficiency``
     - 1.0
     - 1.0
     - 1.0
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 1.0
     - 1.0
     - 
     - 
     - 
   * - ``hvac_heating_shared_system``
     - None
     - None
     - None
     - None
     - None
     - None
     - None
     - None
     - None
     - None
     - None
     - None
     - None
     - None
     - None
     - None
     - None
     - None
     - None
     - 
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_heating_system_type``
     - 
     - The type of system.
   * - ``hvac_heating_system_heating_efficiency``
     - Frac
     - The rated heating efficiency.
   * - ``hvac_heating_system_heating_load_served_fraction``
     - 
     - Fraction of load served by the HVAC system.
   * - ``hvac_heat_pump_type``
     - 
     - The type of system.
   * - ``hvac_heat_pump_cooling_efficiency_type``
     - 
     - The cooling efficiency type. Central HPs and Mini-Split HPs use SEER2 or SEER; Geothermal HPs, Packaged Terminal HPs, and Room HPs use EER.
   * - ``hvac_heat_pump_cooling_efficiency``
     - 
     - The rated cooling efficiency.
   * - ``hvac_heat_pump_cooling_compressor_type``
     - 
     - The compressor type of the cooling system. Applies to Central HPs, Mini-Split HPs, and Geothermal HPs.
   * - ``hvac_heat_pump_heating_efficiency_type``
     - 
     - The heating efficiency type. Central HPs and Mini-Split HPs use HSPF2 or HSPF; Goethermal HPs, Packaged Terminal HPs, and Room HPs use COP.
   * - ``hvac_heat_pump_heating_efficiency``
     - 
     - The rated heating efficiency.
   * - ``hvac_heat_pump_capacity_autosizing_methodology``
     - 
     - Logic for autosized heat pumps.
   * - ``hvac_heat_pump_heating_load_served_fraction``
     - 
     - Fraction of load served by the HVAC system.
   * - ``hvac_heat_pump_cooling_load_served_fraction``
     - 
     - Fraction of load served by the HVAC system.
   * - ``hvac_heat_pump_backup_type``
     - 
     - The backup type. Use 'integrated' to represent e.g. built-in electric strip heat or dual-fuel integrated furnace. Use 'separate' to represent e.g. electric baseboard or boiler (based on Heating System 2).
   * - ``hvac_heat_pump_backup_fuel``
     - 
     - The fuel type of the integrated backup.
   * - ``hvac_heat_pump_backup_heating_efficiency``
     - Frac
     - The rated heating efficiency of the integrated backup.
   * - ``hvac_heating_shared_system``
     - 
     - The type of shared system.
   * - ``hvac_heat_pump_backup_use_existing_system``
     - 
     - Whether the heat pump uses the existing heating system as backup. If true and backup type of the heat pump is 'integrated', heat_pump_backup_xxx arguments are assigned values based on the existing heating system. If true and backup type of the heat pump is 'separate', heating_system_2_xxx arguments are assigned values based on the existing heating system. This argument is only applicable for heat pump upgrades.
   * - ``hvac_heat_pump_sizing_is_duct_limited``
     - 
     - Whether the (ducted) heat pump has an upper limit for autosized heating/cooling capacity and an adjusted blower fan efficiency (W/CFM) value. This argument is only applicable for heat pump upgrades.
.. _hvac_heating_type:

HVAC Heating Type
-----------------

Description
***********

The presence and type of the primary heating system in the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py and sources/aris/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \Alaska specific distribution is based on Alaska Retrofit Information System (2008 to 2022) maintained by Alaska Housing Finance Corporation.


Assumption
**********

- \Due to low sample sizes, fallback rules applied with lumping of

- \1) Heating fuel lump: Fuel oil, Propane, Wood and Other Fuel2) Geometry building SF: Mobile, Single family attached, Single family detached3) Geometry building MF: Multi-Family with 2 - 4 Units, Multi-Family with 5+ Units4) Vintage Lump: 20yrs bins

- \For Alaska, we are using a field in ARIS that lumps multi-family 2-4 units and multi-family 5+ units buildings together. Data from the American Community Survey is used to distribute the between these two building types.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Heating Type** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Ducted Heat Pump
     - Ducted Heating
     - Non-Ducted Heat Pump
     - Non-Ducted Heating
     - None
   * - Stock saturation
     - 15%
     - 59%
     - 0.97%
     - 24%
     - 1.1%

.. _hvac_heating_type_and_fuel:

HVAC Heating Type And Fuel
--------------------------

Description
***********

The presence, type, and fuel of primary heating system.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \Calculated directly from other distributions


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Heating Type And Fuel** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Electricity ASHP
     - Electricity Baseboard
     - Electricity Electric Boiler
     - Electricity Electric Furnace
     - Electricity Electric Wall Furnace
     - Electricity MSHP
     - Electricity Shared Heating
     - Fuel Oil Fuel Boiler
     - Fuel Oil Fuel Furnace
     - Fuel Oil Fuel Wall/Floor Furnace
     - Fuel Oil Shared Heating
     - Natural Gas Fuel Boiler
     - Natural Gas Fuel Furnace
     - Natural Gas Fuel Wall/Floor Furnace
     - Natural Gas Shared Heating
     - None
     - Other Fuel Fuel Boiler
     - Other Fuel Fuel Furnace
     - Other Fuel Fuel Wall/Floor Furnace
     - Other Fuel Shared Heating
     - Propane Fuel Boiler
     - Propane Fuel Furnace
     - Propane Fuel Wall/Floor Furnace
     - Propane Shared Heating
     - Void
   * - Stock saturation
     - 15%
     - 6.3%
     - 0.21%
     - 11%
     - 1.1%
     - 0.97%
     - 4.1%
     - 1.2%
     - 2.8%
     - 0.29%
     - 0.51%
     - 2.5%
     - 37%
     - 3.1%
     - 4.7%
     - 1.1%
     - 0.46%
     - 0.24%
     - 1.9%
     - 0.11%
     - 0.4%
     - 3.7%
     - 0.75%
     - 0.16%
     - 0.00039%

.. _hvac_secondary_heating_efficiency:

HVAC Secondary Heating Efficiency
---------------------------------

Description
***********

The efficiency and type of the heating system.

Created by
**********

``sources/aris/tsv_maker.py``

Source
******

- \Alaska specific distribution is based on Alaska Retrofit Information System (2008 to 2022) maintained by Alaska Housing Finance Corporation.


Assumption
**********

- \For Alaska, we are using a field in ARIS that lumps multi-family 2-4 units and multi-family 5+ units buildings together. Data from the American Community Survey is used to distribute the between these two building types.

- \For Alaska, electricity cannot be a secondary heating fuel, therefore no secondary heating efficiency.

- \For Alaska, Toyo/monitor direct-vent devices and other fuel space heaters are not modeled.

- \For Alaska, fireplace and stoves are not modeled.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Secondary Heating Efficiency** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Fuel Boiler, 76% AFUE
     - Fuel Boiler, 80% AFUE
     - Fuel Boiler, 90% AFUE
     - Fuel Furnace, 60% AFUE
     - Fuel Furnace, 76% AFUE
     - Fuel Furnace, 80% AFUE
     - Fuel Furnace, 92.5% AFUE
     - None
     - Shared Heating
     - Void
   * - Stock saturation
     - 0.019%
     - 0.015%
     - 0.0028%
     - 2.5e-05%
     - 0.00036%
     - 0.0011%
     - 0.00049%
     - 1e+02%
     - 0%
     - 0%
   * - ``hvac_heating_system_2_type``
     - Boiler
     - Boiler
     - Boiler
     - Furnace
     - Furnace
     - Furnace
     - Furnace
     - none
     - none
     - 
   * - ``hvac_heating_system_2_heating_efficiency``
     - 0.76
     - 0.8
     - 0.9
     - 0.6
     - 0.76
     - 0.8
     - 0.925
     - 
     - 
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_heating_system_2_type``
     - 
     - The type of system.
   * - ``hvac_heating_system_2_heating_efficiency``
     - Frac
     - The rated heating efficiency.
.. _hvac_secondary_heating_fuel:

HVAC Secondary Heating Fuel
---------------------------

Description
***********

Secondary Heating Fuel for the dwelling unit

Created by
**********

``sources/aris/tsv_maker.py``

Source
******

- \Alaska specific distribution is based on Alaska Retrofit Information System (2008 to 2022) maintained by Alaska Housing Finance Corporation.


Assumption
**********

- \For Alaska, we are using a field in ARIS that lumps multi-family 2-4 units and multi-family 5+ units buildings together. Data from the American Community Survey is used to distribute the between these two building types.

- \For Alaska, all wood is modeled as cord wood.

- \For Alaska, when heating uses more than one fuels, the fuel with highest consumption is considered the primary (heating) fuel, and fuel with second highest usage (provided it is at least 10% of total energy use across all fuels) is considered secondary (heating) fuel - except in case of electric heating, which is always assumed as primary (i.e., secondary heating fuel cannot be electricity). Rest of the fuels are ignored.

- \A unit without a primary heating system (heating fuel is None) cannot have a secondary heating system (secondary heating fuel is None).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Secondary Heating Fuel** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Electricity
     - Fuel Oil
     - Natural Gas
     - None
     - Other Fuel
     - Propane
     - Wood
   * - Stock saturation
     - 0%
     - 0.01%
     - 0.0039%
     - 1e+02%
     - 0.00017%
     - 0.0013%
     - 0.023%
   * - ``hvac_heating_system_2_fuel_type``
     - electricity
     - fuel oil
     - natural gas
     - electricity
     - wood
     - propane
     - wood

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_heating_system_2_fuel_type``
     - 
     - The type of fuel.
.. _hvac_secondary_heating_partial_space_conditioning:

HVAC Secondary Heating Partial Space Conditioning
-------------------------------------------------

Description
***********

The fraction of heating load served by secondary heating system

Created by
**********

``sources/aris/tsv_maker.py``

Source
******

- \Alaska specific distribution is based on Alaska Retrofit Information System (2008 to 2022) maintained by Alaska Housing Finance Corporation.


Assumption
**********

- \For Alaska, we are using a field in ARIS that lumps multi-family 2-4 units and multi-family 5+ units buildings together. Data from the American Community Survey is used to distribute the between these two building types.

- \For Alaska, the fraction of the load served by the secondary heating system is calculated as the ratio of annual energy used by secondary fuel and annual energy used by secondary and primary fuel.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Secondary Heating Partial Space Conditioning** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0%
     - 10%
     - 20%
     - 30%
     - 40%
     - 50%
     - Void
   * - Stock saturation
     - 1e+02%
     - 0.0046%
     - 0.0082%
     - 0.014%
     - 0.0067%
     - 0.0055%
     - 0%
   * - ``hvac_heating_system_2_heating_load_served_fraction``
     - 0.0
     - 0.1
     - 0.2
     - 0.3
     - 0.4
     - 0.5
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_heating_system_2_heating_load_served_fraction``
     - 
     - Fraction of load served by the HVAC system.
.. _hvac_secondary_heating_type:

HVAC Secondary Heating Type
---------------------------

Description
***********

The efficiency and type of the heating system.

Created by
**********

``sources/aris/tsv_maker.py``

Source
******

- \Alaska specific distribution is based on Alaska Retrofit Information System (2008 to 2022) maintained by Alaska Housing Finance Corporation.


Assumption
**********

- \For Alaska, we are using a field in ARIS that lumps multi-family 2-4 units and multi-family 5+ units buildings together. Data from the American Community Survey is used to distribute the between these two building types.

- \Ducted heating or heat pump cannot have ducted secondary heating.

- \For Alaska, all heat pumps are assumed to be non-ducted mini-splits.

- \For Alaska, all heat pumps are assumed to be non-ducted mini-splits. For Alaska, electricity cannot be a secondary heating fuel, therefore no secondary heating type.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Secondary Heating Type** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Ducted Heating
     - Non-Ducted Heating
     - None
   * - Stock saturation
     - 0.002%
     - 0.037%
     - 1e+02%

.. _hvac_shared_efficiencies:

HVAC Shared Efficiencies
------------------------

Description
***********

The presence and efficiency of the shared HVAC system.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Assume that all Heating and Cooling shared systems are fan coils in each dwelling unit served by a central chiller and boiler.

- \Assume all Heating Only shared systems are hot water baseboards in each dwelling unit served by a central boiler.

- \Assume all Cooling Only shared systems are fan coils in each dwelling unit served by a central chiller.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC Shared Efficiencies** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Boiler Baseboards Heating Only, Electricity
     - Boiler Baseboards Heating Only, Fuel
     - Fan Coil Cooling Only
     - Fan Coil Heating and Cooling, Electricity
     - Fan Coil Heating and Cooling, Fuel
     - None
     - Void
   * - Stock saturation
     - 2.8%
     - 4.4%
     - 1.4%
     - 1.3%
     - 1.1%
     - 89%
     - 0%
   * - ``hvac_heating_system_type``
     - Boiler
     - Boiler
     - 
     - Boiler
     - Boiler
     - 
     - 
   * - ``hvac_heating_system_heating_efficiency``
     - 1.0
     - 0.78
     - 
     - 1.0
     - 0.78
     - 
     - 
   * - ``hvac_heating_system_heating_load_served_fraction``
     - 1.0
     - 1.0
     - 
     - 1.0
     - 1.0
     - 
     - 
   * - ``hvac_cooling_system_type``
     - 
     - 
     - mini-split
     - mini-split
     - mini-split
     - 
     - 
   * - ``hvac_cooling_system_cooling_efficiency_type``
     - 
     - 
     - SEER2
     - SEER2
     - SEER2
     - 
     - 
   * - ``hvac_cooling_system_cooling_efficiency``
     - 
     - 
     - 14.5
     - 14.5
     - 14.5
     - 
     - 
   * - ``hvac_cooling_system_cooling_compressor_type``
     - 
     - 
     - variable speed
     - variable speed
     - variable speed
     - 
     - 
   * - ``hvac_heat_pump_type``
     - none
     - none
     - 
     - none
     - none
     - 
     - 
   * - ``hvac_heat_pump_capacity_autosizing_methodology``
     - ACCA
     - ACCA
     - 
     - ACCA
     - ACCA
     - 
     - 
   * - ``hvac_heat_pump_heating_load_served_fraction``
     - 1.0
     - 1.0
     - 
     - 1.0
     - 1.0
     - 
     - 
   * - ``hvac_heat_pump_cooling_load_served_fraction``
     - 1.0
     - 1.0
     - 
     - 1.0
     - 1.0
     - 
     - 
   * - ``hvac_heat_pump_backup_type``
     - none
     - none
     - 
     - none
     - none
     - 
     - 
   * - ``hvac_heating_shared_system``
     - Baseboard
     - Baseboard
     - 
     - FanCoil
     - FanCoil
     - 
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_heating_system_type``
     - 
     - The type of system.
   * - ``hvac_heating_system_heating_efficiency``
     - Frac
     - The rated heating efficiency.
   * - ``hvac_heating_system_heating_load_served_fraction``
     - 
     - Fraction of load served by the HVAC system.
   * - ``hvac_cooling_system_type``
     - 
     - The type of system.
   * - ``hvac_cooling_system_cooling_efficiency_type``
     - 
     - The cooling efficiency type. Central ACs and Mini-Split ACs use SEER2 or EER2; Room ACs and Packaged Terminal ACs use CEER or EER.
   * - ``hvac_cooling_system_cooling_efficiency``
     - 
     - The rated cooling efficiency.
   * - ``hvac_cooling_system_cooling_compressor_type``
     - 
     - The compressor type of the cooling system. Applies to Central ACs and Mini-Split ACs.
   * - ``hvac_heat_pump_type``
     - 
     - The type of system.
   * - ``hvac_heat_pump_capacity_autosizing_methodology``
     - 
     - Logic for autosized heat pumps.
   * - ``hvac_heat_pump_heating_load_served_fraction``
     - 
     - Fraction of load served by the HVAC system.
   * - ``hvac_heat_pump_cooling_load_served_fraction``
     - 
     - Fraction of load served by the HVAC system.
   * - ``hvac_heat_pump_backup_type``
     - 
     - The backup type. Use 'integrated' to represent e.g. built-in electric strip heat or dual-fuel integrated furnace. Use 'separate' to represent e.g. electric baseboard or boiler (based on Heating System 2).
   * - ``hvac_heating_shared_system``
     - 
     - The type of shared system.
.. _hvac_system_is_faulted:

HVAC System Is Faulted
----------------------

Description
***********

The presence of the HVAC system having a fault (not used in project_national).

Created by
**********

manually created

Source
******

- \Assuming no faults until we have data necessary to characterize all types of ACs and heat pumps (https://github.com/NREL/resstock/issues/733).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC System Is Faulted** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - No
     - Yes
   * - Stock saturation
     - 100%
     - 0%

.. _hvac_system_is_scaled:

HVAC System Is Scaled
---------------------

Description
***********

Whether the HVAC system has been undersized or oversized (not used in project_national).

Created by
**********

manually created

Source
******

- \Assuming no oversizing or undersizing until we have data necessary to characterize all types of systems.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC System Is Scaled** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - No
     - Yes
   * - Stock saturation
     - 100%
     - 0%

.. _hvac_system_single_speed_ac_airflow:

HVAC System Single Speed AC Airflow
-----------------------------------

Description
***********

Single speed central and room air conditioner actual air flow rates.

Created by
**********

manually created

Source
******

- \Winkler et al. 'Impact of installation faults in air conditioners and heat pumps in single-family homes on US energy usage' 2020


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC System Single Speed AC Airflow** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 154.8 cfm/ton
     - 204.4 cfm/ton
     - 254.0 cfm/ton
     - 303.5 cfm/ton
     - 353.1 cfm/ton
     - 402.7 cfm/ton
     - 452.3 cfm/ton
     - 501.9 cfm/ton
     - 551.5 cfm/ton
     - 601.0 cfm/ton
     - 650.6 cfm/ton
     - 700.2 cfm/ton
     - None
   * - Stock saturation
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 100%
   * - ``cooling_system_rated_cfm_per_ton``
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 
   * - ``cooling_system_actual_cfm_per_ton``
     - 154.8
     - 204.4
     - 254.0
     - 303.5
     - 353.1
     - 402.7
     - 452.3
     - 501.9
     - 551.5
     - 601.0
     - 650.6
     - 700.2
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``cooling_system_rated_cfm_per_ton``
     - cfm/ton
     - The rated cfm per ton of the cooling system.
   * - ``cooling_system_actual_cfm_per_ton``
     - cfm/ton
     - The actual cfm per ton of the cooling system.
.. _hvac_system_single_speed_ac_charge:

HVAC System Single Speed AC Charge
----------------------------------

Description
***********

Central and room air conditioner deviation between design/installed charge.

Created by
**********

manually created

Source
******

- \Winkler et al. 'Impact of installation faults in air conditioners and heat pumps in single-family homes on US energy usage' 2020


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC System Single Speed AC Charge** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0.570 Charge Frac
     - 0.709 Charge Frac
     - 0.848 Charge Frac
     - 0.988 Charge Frac
     - 1.127 Charge Frac
     - 1.266 Charge Frac
     - 1.405 Charge Frac
     - None
   * - Stock saturation
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 100%
   * - ``cooling_system_frac_manufacturer_charge``
     - 0.570
     - 0.709
     - 0.848
     - 0.988
     - 1.127
     - 1.266
     - 1.405
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``cooling_system_frac_manufacturer_charge``
     - Frac
     - The fraction of manufacturer recommended charge of the cooling system.
.. _hvac_system_single_speed_ashp_airflow:

HVAC System Single Speed ASHP Airflow
-------------------------------------

Description
***********

Single speed air source heat pump actual air flow rates.

Created by
**********

manually created

Source
******

- \Winkler et al. 'Impact of installation faults in air conditioners and heat pumps in single-family homes on US energy usage' 2020


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC System Single Speed ASHP Airflow** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 154.8 cfm/ton
     - 204.4 cfm/ton
     - 254.0 cfm/ton
     - 303.5 cfm/ton
     - 353.1 cfm/ton
     - 402.7 cfm/ton
     - 452.3 cfm/ton
     - 501.9 cfm/ton
     - 551.5 cfm/ton
     - 601.0 cfm/ton
     - 650.6 cfm/ton
     - 700.2 cfm/ton
     - None
   * - Stock saturation
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 100%
   * - ``heat_pump_rated_cfm_per_ton``
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 400.0
     - 
   * - ``heat_pump_actual_cfm_per_ton``
     - 154.8
     - 204.4
     - 254.0
     - 303.5
     - 353.1
     - 402.7
     - 452.3
     - 501.9
     - 551.5
     - 601.0
     - 650.6
     - 700.2
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``heat_pump_rated_cfm_per_ton``
     - cfm/ton
     - The rated cfm per ton of the heat pump.
   * - ``heat_pump_actual_cfm_per_ton``
     - cfm/ton
     - The actual cfm per ton of the heat pump.
.. _hvac_system_single_speed_ashp_charge:

HVAC System Single Speed ASHP Charge
------------------------------------

Description
***********

Air source heat pump deviation between design/installed charge.

Created by
**********

manually created

Source
******

- \Winkler et al. 'Impact of installation faults in air conditioners and heat pumps in single-family homes on US energy usage' 2020


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **HVAC System Single Speed ASHP Charge** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0.570 Charge Frac
     - 0.709 Charge Frac
     - 0.848 Charge Frac
     - 0.988 Charge Frac
     - 1.127 Charge Frac
     - 1.266 Charge Frac
     - 1.405 Charge Frac
     - None
   * - Stock saturation
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 0%
     - 100%
   * - ``heat_pump_frac_manufacturer_charge``
     - 0.570
     - 0.709
     - 0.848
     - 0.988
     - 1.127
     - 1.266
     - 1.405
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``heat_pump_frac_manufacturer_charge``
     - Frac
     - The fraction of manufacturer recommended charge of the heat pump.
.. _has_pv:

Has PV
------

Description
***********

The dwelling unit has a rooftop photovoltaic system.

Created by
**********

``sources/dpv/tsv_maker.py``

Source
******

- \ACS population and RiDER data on PV installation that combines LBNL's 2020 Tracking the Sun and Wood Mackenzie's 2020 Q4 PV report (prepared by Nicholas.Willems@nrel.gov on Jun 22, 2021)


Assumption
**********

- \Imposed an upperbound of 14 kWDC, which contains 95pct of all installations. Counties with source_count<10 are backfilled with aggregates at the State level. Distribution based on all installations is applied only to occupied SFD, actual distribution for SFD may be higher.

- \PV is not modeled in AK and HI. No data has been identified.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Has PV** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - No
     - Yes
   * - Stock saturation
     - 99%
     - 1%

.. _heating_fuel:

Heating Fuel
------------

Description
***********

The primary fuel used for heating the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py and sources/aris/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

- \Alaska specific distribution is based on Alaska Retrofit Information System (2008 to 2022) maintained by Alaska Housing Finance Corporation.


Assumption
**********

- \In ACS, Heating Fuel is reported for occupied units only. By excluding Vacancy Status as a dependency, we assume vacant units share the same Heating Fuel distribution as occupied units. Where sample counts are less than 10, the State average distribution has been inserted. Prior to insertion, the following adjustments have been made to the state distribution so all rows have sample count > 10: 1. Where sample counts < 10 (which consists of Mobile Home and Single-Family Attached only), the Vintage ACS distribution is used instead of Vintage: [CT, DE, ID, MD, ME, MT, ND, NE, NH, NV, RI, SD, UT, VT, WY]

- \2. Remaining Mobile Homes < 10 are replaced by Single-Family Detached + Mobile Homes combined: [DE, RI, SD, VT, WY, and all DC].

- \For Alaska, we are using a field in ARIS that lumps multi-family 2-4 units and multi-family 5+ units buildings together. Data from the American Community Survey is used to distribute the between these two building types.

- \For Alaska, all wood is modeled as cord wood.

- \For Alaska, when heating uses more than one fuels, the fuel with highest consumption is considered the primary (heating) fuel, and fuel with second highest usage (provided it is at least 10% of total energy use across all fuels) is considered secondary (heating) fuel - except in case of electric heating, which is always assumed as primary. Rest of the fuels are ignored.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Heating Fuel** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Electricity
     - Fuel Oil
     - Natural Gas
     - None
     - Other Fuel
     - Propane
     - Wood
   * - Stock saturation
     - 39%
     - 4.9%
     - 47%
     - 1.1%
     - 0.74%
     - 5%
     - 2%
   * - ``hvac_heating_system_fuel_type``
     - electricity
     - fuel oil
     - natural gas
     - natural gas
     - wood
     - propane
     - wood

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_heating_system_fuel_type``
     - 
     - The type of fuel.
.. _heating_setpoint:

Heating Setpoint
----------------

Description
***********

Baseline heating setpoint with no offset applied.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK

- \Heating type dependency is always lumped into Heat pump / Non-heat pumps

- \For vacant units (for which Tenure = 'Not Available'), the heating setpoint is set to 55F


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Heating Setpoint** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 55F
     - 60F
     - 62F
     - 65F
     - 67F
     - 68F
     - 70F
     - 72F
     - 75F
     - 76F
     - 78F
     - 80F
   * - Stock saturation
     - 12%
     - 2.3%
     - 1.1%
     - 5.8%
     - 4.9%
     - 20%
     - 23%
     - 15%
     - 9.4%
     - 2.3%
     - 1.8%
     - 1%
   * - ``hvac_control_heating_season_period``
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
     - Jan 1 - Dec 31
   * - ``hvac_control_heating_weekday_setpoint_temp``
     - 55
     - 60
     - 62
     - 65
     - 67
     - 68
     - 70
     - 72
     - 75
     - 76
     - 78
     - 80
   * - ``hvac_control_heating_weekend_setpoint_temp``
     - 55
     - 60
     - 62
     - 65
     - 67
     - 68
     - 70
     - 72
     - 75
     - 76
     - 78
     - 80

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_control_heating_season_period``
     - 
     - Enter a date range like 'Nov 1 - Jun 30'. Defaults to year-round heating availability.
   * - ``hvac_control_heating_weekday_setpoint_temp``
     - deg-F
     - Specify the weekday heating setpoint temperature.
   * - ``hvac_control_heating_weekend_setpoint_temp``
     - deg-F
     - Specify the weekend heating setpoint temperature.
.. _heating_setpoint_has_offset:

Heating Setpoint Has Offset
---------------------------

Description
***********

Presence of a heating setpoint offset.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only, 2) lumping all building types together


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Heating Setpoint Has Offset** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - No
     - Yes
   * - Stock saturation
     - 56%
     - 44%

.. _heating_setpoint_offset_magnitude:

Heating Setpoint Offset Magnitude
---------------------------------

Description
***********

Magnitude of the heating setpoint offset.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Heating Setpoint Offset Magnitude** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0F
     - 3F
     - 6F
     - 12F
   * - Stock saturation
     - 56%
     - 27%
     - 12%
     - 4.9%
   * - ``hvac_control_heating_weekday_setpoint_offset_magnitude``
     - 0
     - 3
     - 6
     - 12
   * - ``hvac_control_heating_weekend_setpoint_offset_magnitude``
     - 0
     - 3
     - 6
     - 12

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_control_heating_weekday_setpoint_offset_magnitude``
     - deg-F
     - Specify the weekday heating offset magnitude.
   * - ``hvac_control_heating_weekend_setpoint_offset_magnitude``
     - deg-F
     - Specify the weekend heating offset magnitude.
.. _heating_setpoint_offset_period:

Heating Setpoint Offset Period
------------------------------

Description
***********

The period and offset for the dwelling unit's heating setpoint. Default for the day is from 9am to 5pm and for the night is 10pm to 7am.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Heating Setpoint Offset Period** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Day
     - Day -1h
     - Day -2h
     - Day -3h
     - Day -4h
     - Day -5h
     - Day +1h
     - Day +2h
     - Day +3h
     - Day +4h
     - Day +5h
     - Day and Night
     - Day and Night -1h
     - Day and Night -2h
     - Day and Night -3h
     - Day and Night -4h
     - Day and Night -5h
     - Day and Night +1h
     - Day and Night +2h
     - Day and Night +3h
     - Day and Night +4h
     - Day and Night +5h
     - Night
     - Night -1h
     - Night -2h
     - Night -3h
     - Night -4h
     - Night -5h
     - Night +1h
     - Night +2h
     - Night +3h
     - Night +4h
     - Night +5h
     - None
   * - Stock saturation
     - 0.3%
     - 0.3%
     - 0.3%
     - 0.3%
     - 0.3%
     - 0.3%
     - 0.3%
     - 0.3%
     - 0.3%
     - 0.3%
     - 0.3%
     - 0.44%
     - 0.44%
     - 0.44%
     - 0.44%
     - 0.44%
     - 0.44%
     - 0.44%
     - 0.44%
     - 0.44%
     - 0.44%
     - 0.44%
     - 3.2%
     - 3.2%
     - 3.2%
     - 3.2%
     - 3.2%
     - 3.2%
     - 3.2%
     - 3.2%
     - 3.2%
     - 3.2%
     - 3.2%
     - 56%
   * - ``hvac_control_heating_weekday_setpoint_schedule``
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0
     - -1, -1, -1, -1, -1, -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, -1, -1
     - -1, -1, -1, -1, -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, -1, -1, -1
     - -1, -1, -1, -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, -1, -1, -1, -1
     - -1, -1, -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1
     - -1, -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1
     - -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0,-1
     - -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0
     - 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0
     - 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0
     - 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0
     - -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1
     - -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1
     - -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1
     - -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1
     - -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1
     - -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
   * - ``hvac_control_heating_weekend_setpoint_schedule``
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1
     - -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1
     - -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1
     - -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1
     - -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1
     - -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1
     - -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1
     - -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1
     - -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1
     - -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1
     - -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1
     - -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
     - 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``hvac_control_heating_weekday_setpoint_schedule``
     - 
     - Specify the 24-hour comma-separated weekday heating schedule of 0s and 1s.
   * - ``hvac_control_heating_weekend_setpoint_schedule``
     - 
     - Specify the 24-hour comma-separated weekend heating schedule of 0s and 1s.
.. _heating_unavailable_days:

Heating Unavailable Days
------------------------

Description
***********

Number of days in a year the heating system is unavailable

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Where samples are less than 10, the data is aggregated in the following order until there are no rows with less than 10 samples:

- \1. The Federal Poverty Level dependency is aggregated every 100%

- \2. The Federal Poverty Level dependency is aggregated every 200%

- \3. The Geometry Building Type RECS dependency is aggregated into SF, MF, and MH bins.

- \4. The Cooling Unavailable Days dependency is aggregated into Days, Weeks, Month, and All Year bins.

- \5. The Cooling Unavailable Days dependency is removed.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Heating Unavailable Days** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 1 day
     - 1 month
     - 1 week
     - 2 weeks
     - 3 days
     - 3 months
     - Never
     - Year round
   * - Stock saturation
     - 0.82%
     - 0.35%
     - 0.62%
     - 0.43%
     - 1.1%
     - 0.36%
     - 96%
     - 0.24%
   * - ``schedules_space_heating_unavailable_days``
     - 1
     - 30
     - 7
     - 14
     - 3
     - 90
     - 0
     - 365

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``schedules_space_heating_unavailable_days``
     - 
     - Number of days space heating equipment is unavailable.
.. _holiday_lighting:

Holiday Lighting
----------------

Description
***********

Use of holiday lighting (not currently modeled separately from other exterior lighting).

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \n/a


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Holiday Lighting** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - No Exterior Use
   * - Stock saturation
     - 100%

.. _hot_water_distribution:

Hot Water Distribution
----------------------

Description
***********

Type of distribution system and presence of hot water piping insulation.

Created by
**********

manually created

Source
******

- \Engineering Judgement


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Hot Water Distribution** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Uninsulated
   * - Stock saturation
     - 100%
   * - ``dhw_distribution_pipe_insulation_nominal_r_value``
     - 0
   * - ``dhw_distribution_system_type``
     - Standard
   * - ``dhw_fixtures_low_flow_showers``
     - false
   * - ``dhw_fixtures_low_flow_sinks``
     - false

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``dhw_distribution_pipe_insulation_nominal_r_value``
     - F-ft2-hr/Btu
     - Nominal R-value of the pipe insulation.
   * - ``dhw_distribution_system_type``
     - 
     - The type of hot water distribution system.
   * - ``dhw_fixtures_low_flow_showers``
     - 
     - Whether the shower fixtures are low flow (<= 2.0 gpm).
   * - ``dhw_fixtures_low_flow_sinks``
     - 
     - Whether the sink fixtures are low flow (<= 2.0 gpm).
.. _hot_water_fixtures:

Hot Water Fixtures
------------------

Description
***********

Hot water fixture usage and flow levels.

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \Field data from a demand management program with 1700 residential electric resistance water heaters in the Northeast U.S., mean-shifted from 0.8 to 1 average usage.


Assumption
**********

- \Low, Medium, and High usage is assigned based on the lower 25th percent, middle 50th percent, and upper 25th percent.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Hot Water Fixtures** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 50% Usage
     - 60% Usage
     - 70% Usage
     - 80% Usage
     - 90% Usage
     - 100% Usage
     - 110% Usage
     - 120% Usage
     - 130% Usage
     - 140% Usage
     - 150% Usage
     - 160% Usage
     - 170% Usage
     - 180% Usage
     - 190% Usage
     - 200% Usage
   * - Stock saturation
     - 0.47%
     - 3.6%
     - 9.9%
     - 14%
     - 17%
     - 18%
     - 13%
     - 8.9%
     - 6.8%
     - 3.8%
     - 2.1%
     - 0.99%
     - 0.73%
     - 0.31%
     - 0%
     - 0.1%
   * - ``water_fixtures_usage_multiplier``
     - 0.5
     - 0.6
     - 0.7
     - 0.8
     - 0.9
     - 1.0
     - 1.1
     - 1.2
     - 1.3
     - 1.4
     - 1.5
     - 1.6
     - 1.7
     - 1.8
     - 1.9
     - 2.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``water_fixtures_usage_multiplier``
     - 
     - Multiplier on the hot water usage that can reflect, e.g., high/low usage occupants.
.. _household_has_tribal_persons:

Household Has Tribal Persons
----------------------------

Description
***********

The household occupying the dwelling unit has at least one tribal person in the household.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \2188 / 2336 PUMA has <10 samples and are falling back to state level aggregated values.DC Mobile Homes do not exist and are replaced with Single-Family Detached.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Household Has Tribal Persons** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - No
     - Not Available
     - Yes
   * - Stock saturation
     - 87%
     - 12%
     - 0.9%

.. _iso_rto_region:

ISO RTO Region
--------------

Description
***********

The independent system operator or regional transmission organization region that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \ISO and RTO regions are from EIA Form 861.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **ISO RTO Region** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - CAISO
     - ERCOT
     - MISO
     - NEISO
     - None
     - NYISO
     - PJM
     - SPP
   * - Stock saturation
     - 6.8%
     - 6.9%
     - 16%
     - 4.8%
     - 35%
     - 6.1%
     - 20%
     - 4.6%

.. _income:

Income
------

Description
***********

Income of the household occupying the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \In ACS, Income and Tenure are reported for occupied units only. Because we assume vacant units share the same Tenure distribution as occupied units, by extension, we assume this Income distribution applies to all units regardless of Vacancy Status. For reference, 57445 / 140160 rows have sampling_probability >= 1/550000. Of those rows, 2961 (5%) were replaced due to low samples in the following process: Where sample counts are less than 10 (79145 / 140160 relevant rows), the Census Division by PUMA Metro Status average distribution has been inserted first (76864), followed by Census Division by 'Metro'/'Non-metro' average distribution (1187), followed by Census Region by PUMA Metro Status average distribution (282), followed by Census Region by 'Metro'/'Non-metro' average distribution (112).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Income** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - <10000
     - 10000-14999
     - 15000-19999
     - 20000-24999
     - 25000-29999
     - 30000-34999
     - 35000-39999
     - 40000-44999
     - 45000-49999
     - 50000-59999
     - 60000-69999
     - 70000-79999
     - 80000-99999
     - 100000-119999
     - 120000-139999
     - 140000-159999
     - 160000-179999
     - 180000-199999
     - 200000+
     - Not Available
   * - Stock saturation
     - 5.4%
     - 3.8%
     - 3.9%
     - 4%
     - 3.8%
     - 4%
     - 3.7%
     - 3.7%
     - 3.4%
     - 6.6%
     - 5.9%
     - 5.2%
     - 8.5%
     - 6.6%
     - 4.7%
     - 3.4%
     - 2.5%
     - 1.8%
     - 6.9%
     - 12%

.. _income_recs2015:

Income RECS2015
---------------

Description
***********

Income of the household occupying the dwelling unit that are aligned with the 2015 U.S. Energy Information Administration Residential Energy Consumption Survey.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \Income bins aligned with RECS 2015


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Income RECS2015** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - <20000
     - 20000-39999
     - 40000-59999
     - 60000-79999
     - 80000-99999
     - 100000-119999
     - 120000-139999
     - 140000+
     - Not Available
   * - Stock saturation
     - 13%
     - 16%
     - 14%
     - 11%
     - 8.5%
     - 6.6%
     - 4.7%
     - 14%
     - 12%

.. _income_recs2020:

Income RECS2020
---------------

Description
***********

Income of the household occupying the dwelling unit that are aligned with the 2020 U.S. Energy Information Administration Residential Energy Consumption Survey.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \Consolidated income bins aligned with RECS 2020


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Income RECS2020** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - <20000
     - 20000-39999
     - 40000-59999
     - 60000-99999
     - 100000-149999
     - 150000+
     - Not Available
   * - Stock saturation
     - 13%
     - 16%
     - 14%
     - 20%
     - 13%
     - 13%
     - 12%

.. _infiltration:

Infiltration
------------

Description
***********

Total infiltration to the dwelling unit.

Created by
**********

``sources/resdb/tsv_maker.py and sources/aris/tsv_maker.py``

Source
******

- \Distributions are based on the cumulative distribution functions from the Residential Diagnostics Database (ResDB), http://resdb.lbl.gov/.

- \Alaska specific distribution is based on Alaska Retrofit Information System (2008 to 2022) maintained by Alaska Housing Finance Corporation.


Assumption
**********

- \All ACH50 are based on Single-Family Detached blower door tests.

- \Climate zones that are copied: 2A to 1A, 6A to 7A, and 6B to 7B.

- \Vintage bins that are copied: 2000s to 2010s, 1950s to 1940s, 1950s to <1940s.

- \Homes are assumed to not be Weatherization Assistance Program (WAP) qualified and not ENERGY STAR certified.

- \Climate zones 7AK and 8AK are averages of 6A and 6B.

- \ResStock models multi-family and SFA units with the unit total air leakage type. The unit total air leakage assume that some of the sampled ACH50 value goes to neighboring units. The model infiltration value to the exterior is a smaller infiltration value that what is sampled and is adjusted by the ratio of exterior envelope surface area to total envelope surface area. The modeled infiltration to the exterior is reported in the results.

- \For Alaska, we are using a field in ARIS that lumps multi-family 2-4 units and multi-family 5+ units buildings together. Data from the American Community Survey is used to distribute the between these two building types.

- \For Alaska, Infiltration ACH50 values are calculated based on CFM50 from blower door test and estimated volume of the home.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Infiltration** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 1 ACH50
     - 2 ACH50
     - 3 ACH50
     - 4 ACH50
     - 5 ACH50
     - 6 ACH50
     - 7 ACH50
     - 8 ACH50
     - 10 ACH50
     - 15 ACH50
     - 20 ACH50
     - 25 ACH50
     - 30 ACH50
     - 40 ACH50
     - 50 ACH50
   * - Stock saturation
     - 0.064%
     - 0.66%
     - 1.4%
     - 2.3%
     - 3.4%
     - 4.3%
     - 4.9%
     - 5.3%
     - 11%
     - 24%
     - 17%
     - 10%
     - 6.1%
     - 5.7%
     - 3.2%
   * - ``enclosure_air_leakage_units``
     - ACH
     - ACH
     - ACH
     - ACH
     - ACH
     - ACH
     - ACH
     - ACH
     - ACH
     - ACH
     - ACH
     - ACH
     - ACH
     - ACH
     - ACH
   * - ``enclosure_air_leakage_house_pressure``
     - 50
     - 50
     - 50
     - 50
     - 50
     - 50
     - 50
     - 50
     - 50
     - 50
     - 50
     - 50
     - 50
     - 50
     - 50
   * - ``enclosure_air_leakage_value``
     - 1.0
     - 2.0
     - 3.0
     - 4.0
     - 5.0
     - 6.0
     - 7.0
     - 8.0
     - 10.0
     - 15.0
     - 20.0
     - 25.0
     - 30.0
     - 40.0
     - 50.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_air_leakage_units``
     - 
     - The unit of measure for the air leakage if providing a numeric air leakage value.
   * - ``enclosure_air_leakage_house_pressure``
     - Pa
     - The house pressure relative to outside if providing a numeric air leakage value. Required when units are ACH or CFM.
   * - ``enclosure_air_leakage_value``
     - 
     - Numeric air leakage value. For EffectiveLeakageArea, the value is in sq. in.
.. _insulation_ceiling:

Insulation Ceiling
------------------

Source
******

- \NEEA Residential Building Stock Assessment, 2012

- \Nettleton, G.

- \Edwards, J. (2012). Data Collection-Data Characterization Summary, NorthernSTAR Building America Partnership, Building Technologies Program. Washington, D.C.: U.S. Department of Energy, as described in Roberts et al., 'Assessment of the U.S. Department of Energy's Home Energy Score Tool', 2012, and Merket 'Building America Field Data Repository', Webinar, 2014

- \Derived from Home Innovation Research Labs 1982-2007 Data


Assumption
**********

- \Vented Attic has the same distribution as Unvented Attic

- \CRHI is a copy of CR09

- \CRAK is a copy of CR02


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Insulation Ceiling** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - Uninsulated
     - R-7
     - R-13
     - R-19
     - R-30
     - R-38
     - R-49
   * - Stock saturation
     - 57%
     - 1.2%
     - 2.7%
     - 5.3%
     - 8.4%
     - 14%
     - 8.3%
     - 2.7%
   * - ``enclosure_ceiling_assembly_r_value``
     - 2.1
     - 2.1
     - 8.7
     - 14.6
     - 20.6
     - 31.6
     - 39.6
     - 50.6
   * - ``ceiling_insulation_r``
     - 0
     - 0
     - 7
     - 13
     - 19
     - 30
     - 38
     - 49

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_ceiling_assembly_r_value``
     - F-ft2-hr/Btu
     - Assembly R-value for the ceiling.
   * - ``ceiling_insulation_r``
     - h-ft^2-R/Btu
     - Nominal R-value for the ceiling (attic floor).
.. _insulation_floor:

Insulation Floor
----------------

Source
******

- \Derived from Home Innovation Research Labs 1982-2007 Data

- \(pre-1980) Engineering judgment


Assumption
**********

- \CRHI is a copy of CR09

- \CRAK is a copy of CR02


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Insulation Floor** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - Uninsulated
     - Ceiling R-13
     - Ceiling R-19
     - Ceiling R-30
   * - Stock saturation
     - 39%
     - 48%
     - 4.8%
     - 7.7%
     - 0.29%
   * - ``enclosure_floor_over_foundation_type``
     - WoodFrame
     - WoodFrame
     - WoodFrame
     - WoodFrame
     - WoodFrame
   * - ``enclosure_floor_over_foundation_assembly_r_value``
     - 3.7
     - 3.7
     - 16.2
     - 21.0
     - 28.7
   * - ``enclosure_floor_over_garage_type``
     - WoodFrame
     - WoodFrame
     - WoodFrame
     - WoodFrame
     - WoodFrame
   * - ``enclosure_floor_over_garage_assembly_r_value``
     - 3.7
     - 3.7
     - 16.2
     - 21.0
     - 28.7

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_floor_over_foundation_type``
     - 
     - The type of floor.
   * - ``enclosure_floor_over_foundation_assembly_r_value``
     - F-ft2-hr/Btu
     - Assembly R-value for the floor excluding any carpet.
   * - ``enclosure_floor_over_garage_type``
     - 
     - The type of floor.
   * - ``enclosure_floor_over_garage_assembly_r_value``
     - F-ft2-hr/Btu
     - Assembly R-value for the floor excluding any carpet.
.. _insulation_foundation_wall:

Insulation Foundation Wall
--------------------------

Source
******

- \Derived from Home Innovation Research Labs 1982-2007 Data

- \(pre-1980) Engineering judgment


Assumption
**********

- \CRHI is a copy of CR09

- \CRAK is a copy of CR02


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Insulation Foundation Wall** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - Uninsulated
     - Wall R-5, Exterior
     - Wall R-10, Exterior
     - Wall R-15, Exterior
   * - Stock saturation
     - 48%
     - 47%
     - 1.2%
     - 2.8%
     - 0.52%
   * - ``enclosure_foundation_wall_type``
     - solid concrete
     - solid concrete
     - solid concrete
     - solid concrete
     - solid concrete
   * - ``enclosure_foundation_wall_insulation_nominal_r_value``
     - 0.0
     - 0.0
     - 5.0
     - 10.0
     - 15.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_foundation_wall_type``
     - 
     - The material type of the foundation wall.
   * - ``enclosure_foundation_wall_insulation_nominal_r_value``
     - F-ft2-hr/Btu
     - Nominal R-value for the foundation wall insulation.
.. _insulation_rim_joist:

Insulation Rim Joist
--------------------

Description
***********

Insulation level for rim joists.

Created by
**********

manually created

Source
******

- \Engineering Judgement


Assumption
**********

- \Rim joist insulation is the same value as the foundation wall insulation.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Insulation Rim Joist** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - Uninsulated
     - R-5, Exterior
     - R-10, Exterior
     - R-15, Exterior
   * - Stock saturation
     - 48%
     - 47%
     - 1.2%
     - 2.8%
     - 0.52%
   * - ``enclosure_rim_joist_assembly_r_value``
     - 2.5
     - 2.5
     - 7.5
     - 12.5
     - 17.5

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_rim_joist_assembly_r_value``
     - F-ft2-hr/Btu
     - Assembly R-value for the rim joist excluding any siding.
.. _insulation_roof:

Insulation Roof
---------------

Description
***********

Finished roof insulation level.

Created by
**********

manually created

Source
******

- \Derived from Home Innovation Research Labs 1982-2007 Data

- \NEEA Residential Building Stock Assessment, 2012


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Insulation Roof** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Unfinished, Uninsulated
     - Finished, Uninsulated
     - Finished, R-7
     - Finished, R-13
     - Finished, R-19
     - Finished, R-30
     - Finished, R-38
     - Finished, R-49
   * - Stock saturation
     - 43%
     - 1.9%
     - 3.7%
     - 7.2%
     - 11%
     - 19%
     - 11%
     - 3.7%
   * - ``enclosure_roof_unconditioned_assembly_r_value``
     - 2.3
     - 2.3
     - 8.9
     - 13.9
     - 19.9
     - 29.4
     - 36.4
     - 45.6
   * - ``enclosure_roof_conditioned_assembly_r_value``
     - 3.7
     - 3.7
     - 10.2
     - 14.3
     - 21.2
     - 29.7
     - 36.5
     - 47.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_roof_unconditioned_assembly_r_value``
     - F-ft2-hr/Btu
     - Assembly R-value for the roof if above an unconditioned attic.
   * - ``enclosure_roof_conditioned_assembly_r_value``
     - F-ft2-hr/Btu
     - Assembly R-value for the roof if above conditioned space.
.. _insulation_slab:

Insulation Slab
---------------

Description
***********

Slab insulation level.

Created by
**********

manually created

Source
******

- \Derived from Home Innovation Research Labs 1982-2007 Data

- \(pre-1980) Engineering judgment


Assumption
**********

- \CRHI is a copy of CR09

- \CRAK is a copy of CR02


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Insulation Slab** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - Uninsulated
     - 2ft R5 Under, Horizontal
     - 2ft R10 Under, Horizontal
     - 4ft R5 Under, Horizontal
     - 2ft R5 Perimeter, Vertical
     - 2ft R10 Perimeter, Vertical
     - R10 Whole Slab, Horizontal
   * - Stock saturation
     - 61%
     - 30%
     - 2.6%
     - 2.3%
     - 0%
     - 1.8%
     - 2.8%
     - 0%
   * - ``enclosure_slab_under_slab_insulation_nominal_r_value``
     - 0
     - 0
     - 5
     - 10
     - 5
     - 0
     - 0
     - 10
   * - ``enclosure_slab_under_slab_insulation_width``
     - 0
     - 0
     - 2
     - 2
     - 4
     - 0
     - 0
     - 999
   * - ``enclosure_slab_perimeter_insulation_nominal_r_value``
     - 0
     - 0
     - 0
     - 0
     - 0
     - 5
     - 10
     - 0
   * - ``enclosure_slab_perimeter_insulation_depth``
     - 0
     - 0
     - 0
     - 0
     - 0
     - 2
     - 2
     - 0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_slab_under_slab_insulation_nominal_r_value``
     - F-ft2-hr/Btu
     - Nominal R-value of the horizontal under slab insulation.
   * - ``enclosure_slab_under_slab_insulation_width``
     - ft
     - Width from slab edge inward of horizontal under-slab insulation. Use 999 to specify that the under slab insulation spans the entire slab.
   * - ``enclosure_slab_perimeter_insulation_nominal_r_value``
     - F-ft2-hr/Btu
     - Nominal R-value of the vertical slab perimeter insulation.
   * - ``enclosure_slab_perimeter_insulation_depth``
     - ft
     - Depth from grade to bottom of vertical slab perimeter insulation.
.. _insulation_wall:

Insulation Wall
---------------

Description
***********

Wall construction type and insulation level.

Created by
**********

manually created

Source
******

- \Ritschard et al. Single-Family Heating and Cooling Requirements: Assumptions, Methods, and Summary Results 1992

- \Nettleton, G.

- \Edwards, J. (2012). Data Collection-Data Characterization Summary, NorthernSTAR Building America Partnership, Building Technologies Program. Washington, D.C.: U.S. Department of Energy, as described in Roberts et al., 'Assessment of the U.S. Department of Energy's Home Energy Score Tool', 2012, and Merket Building America Field Data Repository, Webinar, 2014


Assumption
**********

- \Updated per new wall type from Lightbox, all wall type-specific distributions follow that of `Wood Frame` (`WoodStud`)


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Insulation Wall** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Wood Stud, Uninsulated
     - Wood Stud, R-7
     - Wood Stud, R-11
     - Wood Stud, R-15
     - Wood Stud, R-19
     - CMU, 6-in, Uninsulated
     - CMU, 6-in, R-7
     - CMU, 6-in, R-11
     - CMU, 6-in, R-15
     - CMU, 6-in, R-19
     - Brick, 12-in, 3-wythe, Uninsulated
     - Brick, 12-in, 3-wythe, R-7
     - Brick, 12-in, 3-wythe, R-11
     - Brick, 12-in, 3-wythe, R-15
     - Brick, 12-in, 3-wythe, R-19
     - Void
   * - Stock saturation
     - 31%
     - 7.3%
     - 23%
     - 4.7%
     - 10%
     - 1.4%
     - 0.4%
     - 0.9%
     - 0.17%
     - 0.43%
     - 9.9%
     - 2.6%
     - 5.5%
     - 1.4%
     - 1.5%
     - 0%
   * - ``enclosure_wall_type``
     - WoodStud
     - WoodStud
     - WoodStud
     - WoodStud
     - WoodStud
     - ConcreteMasonryUnit
     - ConcreteMasonryUnit
     - ConcreteMasonryUnit
     - ConcreteMasonryUnit
     - ConcreteMasonryUnit
     - StructuralBrick
     - StructuralBrick
     - StructuralBrick
     - StructuralBrick
     - StructuralBrick
     - 
   * - ``enclosure_wall_assembly_r_value``
     - 3.4
     - 8.7
     - 10.3
     - 12.1
     - 15.4
     - 4.0
     - 9.7
     - 13.0
     - 15.9
     - 19.7
     - 4.9
     - 10.3
     - 13.3
     - 15.9
     - 18.3
     - 
   * - ``enclosure_wall_continuous_insulation_r_value``
     - 0.0
     - 0.0
     - 0.0
     - 0.0
     - 0.0
     - 0.0
     - 0.0
     - 0.0
     - 0.0
     - 0.0
     - 0.0
     - 0.0
     - 0.0
     - 0.0
     - 0.0
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_wall_type``
     - 
     - The type of wall.
   * - ``enclosure_wall_assembly_r_value``
     - F-ft2-hr/Btu
     - Assembly R-value for the wall excluding any siding and/or continuous insulation.
   * - ``enclosure_wall_continuous_insulation_r_value``
     - F-ft2-hr/Btu
     - The R-value for the wall continuous insulation.
.. _interior_shading:

Interior Shading
----------------

Description
***********

Type of window interior shading.

Created by
**********

manually created

Source
******

- \ANSI/RESNET/ICC 301 Standard


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Interior Shading** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Light Curtains
   * - Stock saturation
     - 100%
   * - ``enclosure_window_interior_shading_type``
     - light curtains

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_window_interior_shading_type``
     - 
     - The type of window interior shading.
.. _lighting:

Lighting
--------

Description
***********

Qualitative lamp type fractions in each household surveyed are distributed to three options representing 100% incandescent, 100% CFl, and 100% LED lamp type options.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Qualitative portion of inside light bulbs is mapped to quantitative percentage as: None: 0%

- \Some: 20%

- \About half: 50%

- \Most: 80%

- \All: 100%. Then the sum of three types of lighting options is normalized to 100%


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Lighting** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 100% CFL
     - 100% Incandescent
     - 100% LED
   * - Stock saturation
     - 23%
     - 25%
     - 52%
   * - ``lighting_interior_fraction_cfl``
     - 1.0
     - 0.0
     - 0.0
   * - ``lighting_interior_fraction_lfl``
     - 0.0
     - 0.0
     - 0.0
   * - ``lighting_interior_fraction_led``
     - 0.0
     - 0.0
     - 1.0
   * - ``lighting_exterior_fraction_cfl``
     - 1.0
     - 0.0
     - 0.0
   * - ``lighting_exterior_fraction_lfl``
     - 0.0
     - 0.0
     - 0.0
   * - ``lighting_exterior_fraction_led``
     - 0.0
     - 0.0
     - 1.0
   * - ``lighting_garage_fraction_cfl``
     - 1.0
     - 0.0
     - 0.0
   * - ``lighting_garage_fraction_lfl``
     - 0.0
     - 0.0
     - 0.0
   * - ``lighting_garage_fraction_led``
     - 0.0
     - 0.0
     - 1.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``lighting_interior_fraction_cfl``
     - frac
     - Fraction of all interior lamps that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_interior_fraction_lfl``
     - frac
     - Fraction of all interior lamps that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_interior_fraction_led``
     - frac
     - Fraction of all interior lamps that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_exterior_fraction_cfl``
     - frac
     - Fraction of all exterior lamps that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_exterior_fraction_lfl``
     - frac
     - Fraction of all exterior lamps that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_exterior_fraction_led``
     - frac
     - Fraction of all exterior lamps that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_garage_fraction_cfl``
     - frac
     - Fraction of all garage lamps that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_garage_fraction_lfl``
     - frac
     - Fraction of all garage lamps that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_garage_fraction_led``
     - frac
     - Fraction of all garage lamps that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
.. _lighting_interior_use:

Lighting Interior Use
---------------------

Description
***********

Interior lighting usage relative to the national average.

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \n/a


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Lighting Interior Use** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 100% Usage
   * - Stock saturation
     - 100%
   * - ``interior_lighting_usage_multiplier``
     - 1.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``interior_lighting_usage_multiplier``
     - 
     - Multiplier on the lighting energy usage (interior) that can reflect, e.g., high/low usage occupants.
.. _lighting_other_use:

Lighting Other Use
------------------

Description
***********

Exterior and garage lighting usage relative to the national average.

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \n/a


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Lighting Other Use** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 100% Usage
   * - Stock saturation
     - 100%
   * - ``exterior_lighting_usage_multiplier``
     - 1.0
   * - ``garage_lighting_usage_multiplier``
     - 1.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``exterior_lighting_usage_multiplier``
     - 
     - Multiplier on the lighting energy usage (exterior) that can reflect, e.g., high/low usage occupants.
   * - ``garage_lighting_usage_multiplier``
     - 
     - Multiplier on the lighting energy usage (garage) that can reflect, e.g., high/low usage occupants.
.. _location_region:

Location Region
---------------

Description
***********

A custom ResStock region constructed of RECS 2009 reportable domains that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \Custom region map located https://github.com/NREL/resstock/wiki/Custom-Region-(CR)-Map


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Location Region** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - CR02
     - CR03
     - CR04
     - CR05
     - CR06
     - CR07
     - CR08
     - CR09
     - CR10
     - CR11
     - CRAK
     - CRHI
   * - Stock saturation
     - 5.3%
     - 4.8%
     - 13%
     - 3.5%
     - 3.5%
     - 13%
     - 13%
     - 29%
     - 3.7%
     - 10%
     - 0.23%
     - 0.4%

.. _mechanical_ventilation:

Mechanical Ventilation
----------------------

Description
***********

Mechanical ventilation type and efficiency.

Created by
**********

manually created

Source
******

- \Engineering Judgement


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Mechanical Ventilation** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
   * - Stock saturation
     - 100%

.. _metropolitan_and_micropolitan_statistical_area:

Metropolitan and Micropolitan Statistical Area
----------------------------------------------

Description
***********

The U.S. Metropolitan Statistical Area (MSA) or Micropolitan Statistical Area (MicroSA) that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \County-MSA crosswalk comes from the Quarterly Census of Employment and Wages NAICS-based data between 2013-2022 by the U.S. Bureau of Labor Statistics (https://www.bls.gov/cew/classifications/areas/county-msa-csa-crosswalk.htm)

- \According to the U.S. Census, each metropolitan statistical area must have at least one urban area of 50,000 or more inhabitants

- \According to the U.S. Census, each micropolitan statistical area must have at least one urban area of at least 10,000 but less than 50,000 population.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Metropolitan and Micropolitan Statistical Area** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Aberdeen, SD MicroSA
     - Aberdeen, WA MicroSA
     - Abilene, TX MSA
     - Ada, OK MicroSA
     - Adrian, MI MicroSA
     - Akron, OH MSA
     - Alamogordo, NM MicroSA
     - Albany-Schenectady-Troy, NY MSA
     - Albany, GA MSA
     - Albany, OR MSA
     - Albemarle, NC MicroSA
     - Albert Lea, MN MicroSA
     - Albertville, AL MicroSA
     - Albuquerque, NM MSA
     - Alexandria, LA MSA
     - Alexandria, MN MicroSA
     - Alice, TX MicroSA
     - Allentown-Bethlehem-Easton, PA-NJ MSA
     - Alma, MI MicroSA
     - Alpena, MI MicroSA
     - Altoona, PA MSA
     - Altus, OK MicroSA
     - Amarillo, TX MSA
     - Americus, GA MicroSA
     - Ames, IA MSA
     - Amsterdam, NY MicroSA
     - Anchorage, AK MSA
     - Andrews, TX MicroSA
     - Angola, IN MicroSA
     - Ann Arbor, MI MSA
     - Anniston-Oxford-Jacksonville, AL MSA
     - Appleton, WI MSA
     - Arcadia, FL MicroSA
     - Ardmore, OK MicroSA
     - Arkadelphia, AR MicroSA
     - Arkansas City-Winfield, KS MicroSA
     - Asheville, NC MSA
     - Ashland, OH MicroSA
     - Ashtabula, OH MicroSA
     - Astoria, OR MicroSA
     - Atchison, KS MicroSA
     - Athens-Clarke County, GA MSA
     - Athens, OH MicroSA
     - Athens, TN MicroSA
     - Athens, TX MicroSA
     - Atlanta-Sandy Springs-Roswell, GA MSA
     - Atlantic City-Hammonton, NJ MSA
     - Auburn-Opelika, AL MSA
     - Auburn, IN MicroSA
     - Auburn, NY MicroSA
     - Augusta-Richmond County, GA-SC MSA
     - Augusta-Waterville, ME MicroSA
     - Austin-Round Rock, TX MSA
     - Austin, MN MicroSA
     - Bainbridge, GA MicroSA
     - Bakersfield, CA MSA
     - Baltimore-Columbia-Towson, MD MSA
     - Bangor, ME MSA
     - Baraboo, WI MicroSA
     - Bardstown, KY MicroSA
     - Barnstable Town, MA MSA
     - Barre, VT MicroSA
     - Bartlesville, OK MicroSA
     - Bastrop, LA MicroSA
     - Batavia, NY MicroSA
     - Batesville, AR MicroSA
     - Baton Rouge, LA MSA
     - Battle Creek, MI MSA
     - Bay City, MI MSA
     - Bay City, TX MicroSA
     - Beatrice, NE MicroSA
     - Beaumont-Port Arthur, TX MSA
     - Beaver Dam, WI MicroSA
     - Beckley, WV MSA
     - Bedford, IN MicroSA
     - Beeville, TX MicroSA
     - Bellefontaine, OH MicroSA
     - Bellingham, WA MSA
     - Bemidji, MN MicroSA
     - Bend-Redmond, OR MSA
     - Bennettsville, SC MicroSA
     - Bennington, VT MicroSA
     - Berlin, NH-VT MicroSA
     - Big Rapids, MI MicroSA
     - Big Spring, TX MicroSA
     - Big Stone Gap, VA MicroSA
     - Billings, MT MSA
     - Binghamton, NY MSA
     - Birmingham-Hoover, AL MSA
     - Bismarck, ND MSA
     - Blackfoot, ID MicroSA
     - Blacksburg-Christiansburg-Radford, VA MSA
     - Bloomington, IL MSA
     - Bloomington, IN MSA
     - Bloomsburg-Berwick, PA MSA
     - Bluefield, WV-VA MicroSA
     - Blytheville, AR MicroSA
     - Bogalusa, LA MicroSA
     - Boise City, ID MSA
     - Boone, IA MicroSA
     - Boone, NC MicroSA
     - Borger, TX MicroSA
     - Boston-Cambridge-Newton, MA-NH MSA
     - Boulder, CO MSA
     - Bowling Green, KY MSA
     - Bozeman, MT MicroSA
     - Bradford, PA MicroSA
     - Brainerd, MN MicroSA
     - Branson, MO MicroSA
     - Breckenridge, CO MicroSA
     - Bremerton-Silverdale, WA MSA
     - Brenham, TX MicroSA
     - Brevard, NC MicroSA
     - Bridgeport-Stamford-Norwalk, CT MSA
     - Brookhaven, MS MicroSA
     - Brookings, OR MicroSA
     - Brookings, SD MicroSA
     - Brownsville-Harlingen, TX MSA
     - Brownwood, TX MicroSA
     - Brunswick, GA MSA
     - Bucyrus, OH MicroSA
     - Buffalo-Cheektowaga-Niagara Falls, NY MSA
     - Burley, ID MicroSA
     - Burlington-South Burlington, VT MSA
     - Burlington, IA-IL MicroSA
     - Burlington, NC MSA
     - Butte-Silver Bow, MT MicroSA
     - Cadillac, MI MicroSA
     - Calhoun, GA MicroSA
     - California-Lexington Park, MD MSA
     - Cambridge, MD MicroSA
     - Cambridge, OH MicroSA
     - Camden, AR MicroSA
     - Campbellsville, KY MicroSA
     - Canon City, CO MicroSA
     - Canton-Massillon, OH MSA
     - Canton, IL MicroSA
     - Cape Coral-Fort Myers, FL MSA
     - Cape Girardeau, MO-IL MSA
     - Carbondale-Marion, IL MSA
     - Carlsbad-Artesia, NM MicroSA
     - Carson City, NV MSA
     - Casper, WY MSA
     - Cedar City, UT MicroSA
     - Cedar Rapids, IA MSA
     - Cedartown, GA MicroSA
     - Celina, OH MicroSA
     - Centralia, IL MicroSA
     - Centralia, WA MicroSA
     - Chambersburg-Waynesboro, PA MSA
     - Champaign-Urbana, IL MSA
     - Charleston-Mattoon, IL MicroSA
     - Charleston-North Charleston, SC MSA
     - Charleston, WV MSA
     - Charlotte-Concord-Gastonia, NC-SC MSA
     - Charlottesville, VA MSA
     - Chattanooga, TN-GA MSA
     - Cheyenne, WY MSA
     - Chicago-Naperville-Elgin, IL-IN-WI MSA
     - Chico, CA MSA
     - Chillicothe, OH MicroSA
     - Cincinnati, OH-KY-IN MSA
     - Claremont-Lebanon, NH-VT MicroSA
     - Clarksburg, WV MicroSA
     - Clarksdale, MS MicroSA
     - Clarksville, TN-KY MSA
     - Clearlake, CA MicroSA
     - Cleveland-Elyria, OH MSA
     - Cleveland, MS MicroSA
     - Cleveland, TN MSA
     - Clewiston, FL MicroSA
     - Clinton, IA MicroSA
     - Clovis, NM MicroSA
     - Coeur d'Alene, ID MSA
     - Coffeyville, KS MicroSA
     - Coldwater, MI MicroSA
     - College Station-Bryan, TX MSA
     - Colorado Springs, CO MSA
     - Columbia, MO MSA
     - Columbia, SC MSA
     - Columbus, GA-AL MSA
     - Columbus, IN MSA
     - Columbus, MS MicroSA
     - Columbus, NE MicroSA
     - Columbus, OH MSA
     - Concord, NH MicroSA
     - Connersville, IN MicroSA
     - Cookeville, TN MicroSA
     - Coos Bay, OR MicroSA
     - Cordele, GA MicroSA
     - Corinth, MS MicroSA
     - Cornelia, GA MicroSA
     - Corning, NY MicroSA
     - Corpus Christi, TX MSA
     - Corsicana, TX MicroSA
     - Cortland, NY MicroSA
     - Corvallis, OR MSA
     - Coshocton, OH MicroSA
     - Craig, CO MicroSA
     - Crawfordsville, IN MicroSA
     - Crescent City, CA MicroSA
     - Crestview-Fort Walton Beach-Destin, FL MSA
     - Crossville, TN MicroSA
     - Cullman, AL MicroSA
     - Cullowhee, NC MicroSA
     - Cumberland, MD-WV MSA
     - Dallas-Fort Worth-Arlington, TX MSA
     - Dalton, GA MSA
     - Danville, IL MSA
     - Danville, KY MicroSA
     - Danville, VA MicroSA
     - Daphne-Fairhope-Foley, AL MSA
     - Davenport-Moline-Rock Island, IA-IL MSA
     - Dayton, OH MSA
     - Dayton, TN MicroSA
     - Decatur, AL MSA
     - Decatur, IL MSA
     - Decatur, IN MicroSA
     - Defiance, OH MicroSA
     - Del Rio, TX MicroSA
     - Deltona-Daytona Beach-Ormond Beach, FL MSA
     - Deming, NM MicroSA
     - Denver-Aurora-Lakewood, CO MSA
     - DeRidder, LA MicroSA
     - Des Moines-West Des Moines, IA MSA
     - Detroit-Warren-Dearborn, MI MSA
     - Dickinson, ND MicroSA
     - Dixon, IL MicroSA
     - Dodge City, KS MicroSA
     - Dothan, AL MSA
     - Douglas, GA MicroSA
     - Dover, DE MSA
     - Dublin, GA MicroSA
     - DuBois, PA MicroSA
     - Dubuque, IA MSA
     - Duluth, MN-WI MSA
     - Dumas, TX MicroSA
     - Duncan, OK MicroSA
     - Dunn, NC MicroSA
     - Durango, CO MicroSA
     - Durant, OK MicroSA
     - Durham-Chapel Hill, NC MSA
     - Dyersburg, TN MicroSA
     - Eagle Pass, TX MicroSA
     - East Stroudsburg, PA MSA
     - Easton, MD MicroSA
     - Eau Claire, WI MSA
     - Edwards, CO MicroSA
     - Effingham, IL MicroSA
     - El Campo, TX MicroSA
     - El Centro, CA MSA
     - El Dorado, AR MicroSA
     - El Paso, TX MSA
     - Elizabeth City, NC MicroSA
     - Elizabethtown-Fort Knox, KY MSA
     - Elk City, OK MicroSA
     - Elkhart-Goshen, IN MSA
     - Elkins, WV MicroSA
     - Elko, NV MicroSA
     - Ellensburg, WA MicroSA
     - Elmira, NY MSA
     - Emporia, KS MicroSA
     - Enid, OK MicroSA
     - Enterprise, AL MicroSA
     - Erie, PA MSA
     - Escanaba, MI MicroSA
     - Espanola, NM MicroSA
     - Eugene, OR MSA
     - Eureka-Arcata-Fortuna, CA MicroSA
     - Evanston, WY MicroSA
     - Evansville, IN-KY MSA
     - Fairbanks, AK MSA
     - Fairfield, IA MicroSA
     - Fairmont, WV MicroSA
     - Fallon, NV MicroSA
     - Fargo, ND-MN MSA
     - Faribault-Northfield, MN MicroSA
     - Farmington, MO MicroSA
     - Farmington, NM MSA
     - Fayetteville-Springdale-Rogers, AR-MO MSA
     - Fayetteville, NC MSA
     - Fergus Falls, MN MicroSA
     - Fernley, NV MicroSA
     - Findlay, OH MicroSA
     - Fitzgerald, GA MicroSA
     - Flagstaff, AZ MSA
     - Flint, MI MSA
     - Florence-Muscle Shoals, AL MSA
     - Florence, SC MSA
     - Fond du Lac, WI MSA
     - Forest City, NC MicroSA
     - Forrest City, AR MicroSA
     - Fort Collins, CO MSA
     - Fort Dodge, IA MicroSA
     - Fort Leonard Wood, MO MicroSA
     - Fort Madison-Keokuk, IA-IL-MO MicroSA
     - Fort Morgan, CO MicroSA
     - Fort Polk South, LA MicroSA
     - Fort Smith, AR-OK MSA
     - Fort Wayne, IN MSA
     - Frankfort, IN MicroSA
     - Frankfort, KY MicroSA
     - Fredericksburg, TX MicroSA
     - Freeport, IL MicroSA
     - Fremont, NE MicroSA
     - Fremont, OH MicroSA
     - Fresno, CA MSA
     - Gadsden, AL MSA
     - Gaffney, SC MicroSA
     - Gainesville, FL MSA
     - Gainesville, GA MSA
     - Gainesville, TX MicroSA
     - Galesburg, IL MicroSA
     - Gallup, NM MicroSA
     - Garden City, KS MicroSA
     - Gardnerville Ranchos, NV MicroSA
     - Georgetown, SC MicroSA
     - Gettysburg, PA MSA
     - Gillette, WY MicroSA
     - Glasgow, KY MicroSA
     - Glens Falls, NY MSA
     - Glenwood Springs, CO MicroSA
     - Gloversville, NY MicroSA
     - Goldsboro, NC MSA
     - Grand Forks, ND-MN MSA
     - Grand Island, NE MSA
     - Grand Junction, CO MSA
     - Grand Rapids-Wyoming, MI MSA
     - Grants Pass, OR MSA
     - Grants, NM MicroSA
     - Great Bend, KS MicroSA
     - Great Falls, MT MSA
     - Greeley, CO MSA
     - Green Bay, WI MSA
     - Greeneville, TN MicroSA
     - Greenfield Town, MA MicroSA
     - Greensboro-High Point, NC MSA
     - Greensburg, IN MicroSA
     - Greenville-Anderson-Mauldin, SC MSA
     - Greenville, MS MicroSA
     - Greenville, NC MSA
     - Greenville, OH MicroSA
     - Greenwood, MS MicroSA
     - Greenwood, SC MicroSA
     - Grenada, MS MicroSA
     - Gulfport-Biloxi-Pascagoula, MS MSA
     - Guymon, OK MicroSA
     - Hagerstown-Martinsburg, MD-WV MSA
     - Hailey, ID MicroSA
     - Hammond, LA MSA
     - Hanford-Corcoran, CA MSA
     - Hannibal, MO MicroSA
     - Harrisburg-Carlisle, PA MSA
     - Harrison, AR MicroSA
     - Harrisonburg, VA MSA
     - Hartford-West Hartford-East Hartford, CT MSA
     - Hastings, NE MicroSA
     - Hattiesburg, MS MSA
     - Hays, KS MicroSA
     - Heber, UT MicroSA
     - Helena-West Helena, AR MicroSA
     - Helena, MT MicroSA
     - Henderson, NC MicroSA
     - Hereford, TX MicroSA
     - Hermiston-Pendleton, OR MicroSA
     - Hickory-Lenoir-Morganton, NC MSA
     - Hillsdale, MI MicroSA
     - Hilo, HI MicroSA
     - Hilton Head Island-Bluffton-Beaufort, SC MSA
     - Hinesville, GA MSA
     - Hobbs, NM MicroSA
     - Holland, MI MicroSA
     - Homosassa Springs, FL MSA
     - Hood River, OR MicroSA
     - Hot Springs, AR MSA
     - Houghton, MI MicroSA
     - Houma-Thibodaux, LA MSA
     - Houston-The Woodlands-Sugar Land, TX MSA
     - Hudson, NY MicroSA
     - Huntingdon, PA MicroSA
     - Huntington-Ashland, WV-KY-OH MSA
     - Huntington, IN MicroSA
     - Huntsville, AL MSA
     - Huntsville, TX MicroSA
     - Huron, SD MicroSA
     - Hutchinson, KS MicroSA
     - Hutchinson, MN MicroSA
     - Idaho Falls, ID MSA
     - Indiana, PA MicroSA
     - Indianapolis-Carmel-Anderson, IN MSA
     - Indianola, MS MicroSA
     - Ionia, MI MicroSA
     - Iowa City, IA MSA
     - Iron Mountain, MI-WI MicroSA
     - Ithaca, NY MSA
     - Jackson, MI MSA
     - Jackson, MS MSA
     - Jackson, OH MicroSA
     - Jackson, TN MSA
     - Jackson, WY-ID MicroSA
     - Jacksonville, FL MSA
     - Jacksonville, IL MicroSA
     - Jacksonville, NC MSA
     - Jacksonville, TX MicroSA
     - Jamestown-Dunkirk-Fredonia, NY MicroSA
     - Jamestown, ND MicroSA
     - Janesville-Beloit, WI MSA
     - Jasper, IN MicroSA
     - Jefferson City, MO MSA
     - Jefferson, GA MicroSA
     - Jesup, GA MicroSA
     - Johnson City, TN MSA
     - Johnstown, PA MSA
     - Jonesboro, AR MSA
     - Joplin, MO MSA
     - Junction City, KS MicroSA
     - Juneau, AK MicroSA
     - Kahului-Wailuku-Lahaina, HI MSA
     - Kalamazoo-Portage, MI MSA
     - Kalispell, MT MicroSA
     - Kankakee, IL MSA
     - Kansas City, MO-KS MSA
     - Kapaa, HI MicroSA
     - Kearney, NE MicroSA
     - Keene, NH MicroSA
     - Kendallville, IN MicroSA
     - Kennett, MO MicroSA
     - Kennewick-Richland, WA MSA
     - Kerrville, TX MicroSA
     - Ketchikan, AK MicroSA
     - Key West, FL MicroSA
     - Kill Devil Hills, NC MicroSA
     - Killeen-Temple, TX MSA
     - Kingsport-Bristol-Bristol, TN-VA MSA
     - Kingston, NY MSA
     - Kingsville, TX MicroSA
     - Kinston, NC MicroSA
     - Kirksville, MO MicroSA
     - Klamath Falls, OR MicroSA
     - Knoxville, TN MSA
     - Kokomo, IN MSA
     - La Crosse-Onalaska, WI-MN MSA
     - La Grande, OR MicroSA
     - Laconia, NH MicroSA
     - Lafayette-West Lafayette, IN MSA
     - Lafayette, LA MSA
     - LaGrange, GA MicroSA
     - Lake Charles, LA MSA
     - Lake City, FL MicroSA
     - Lake Havasu City-Kingman, AZ MSA
     - Lakeland-Winter Haven, FL MSA
     - Lamesa, TX MicroSA
     - Lancaster, PA MSA
     - Lansing-East Lansing, MI MSA
     - Laramie, WY MicroSA
     - Laredo, TX MSA
     - Las Cruces, NM MSA
     - Las Vegas-Henderson-Paradise, NV MSA
     - Las Vegas, NM MicroSA
     - Laurel, MS MicroSA
     - Laurinburg, NC MicroSA
     - Lawrence, KS MSA
     - Lawrenceburg, TN MicroSA
     - Lawton, OK MSA
     - Lebanon, MO MicroSA
     - Lebanon, PA MSA
     - Levelland, TX MicroSA
     - Lewisburg, PA MicroSA
     - Lewisburg, TN MicroSA
     - Lewiston-Auburn, ME MSA
     - Lewiston, ID-WA MSA
     - Lewistown, PA MicroSA
     - Lexington-Fayette, KY MSA
     - Lexington, NE MicroSA
     - Liberal, KS MicroSA
     - Lima, OH MSA
     - Lincoln, IL MicroSA
     - Lincoln, NE MSA
     - Little Rock-North Little Rock-Conway, AR MSA
     - Lock Haven, PA MicroSA
     - Logan, UT-ID MSA
     - Logan, WV MicroSA
     - Logansport, IN MicroSA
     - London, KY MicroSA
     - Longview, TX MSA
     - Longview, WA MSA
     - Los Alamos, NM MicroSA
     - Los Angeles-Long Beach-Anaheim, CA MSA
     - Louisville/Jefferson County, KY-IN MSA
     - Lubbock, TX MSA
     - Ludington, MI MicroSA
     - Lufkin, TX MicroSA
     - Lumberton, NC MicroSA
     - Lynchburg, VA MSA
     - Macomb, IL MicroSA
     - Macon, GA MSA
     - Madera, CA MSA
     - Madison, IN MicroSA
     - Madison, WI MSA
     - Madisonville, KY MicroSA
     - Magnolia, AR MicroSA
     - Malone, NY MicroSA
     - Malvern, AR MicroSA
     - Manchester-Nashua, NH MSA
     - Manhattan, KS MSA
     - Manitowoc, WI MicroSA
     - Mankato-North Mankato, MN MSA
     - Mansfield, OH MSA
     - Marietta, OH MicroSA
     - Marinette, WI-MI MicroSA
     - Marion, IN MicroSA
     - Marion, NC MicroSA
     - Marion, OH MicroSA
     - Marquette, MI MicroSA
     - Marshall, MN MicroSA
     - Marshall, MO MicroSA
     - Marshall, TX MicroSA
     - Marshalltown, IA MicroSA
     - Martin, TN MicroSA
     - Martinsville, VA MicroSA
     - Maryville, MO MicroSA
     - Mason City, IA MicroSA
     - Mayfield, KY MicroSA
     - Maysville, KY MicroSA
     - McAlester, OK MicroSA
     - McAllen-Edinburg-Mission, TX MSA
     - McComb, MS MicroSA
     - McMinnville, TN MicroSA
     - McPherson, KS MicroSA
     - Meadville, PA MicroSA
     - Medford, OR MSA
     - Memphis, TN-MS-AR MSA
     - Menomonie, WI MicroSA
     - Merced, CA MSA
     - Meridian, MS MicroSA
     - Merrill, WI MicroSA
     - Mexico, MO MicroSA
     - Miami-Fort Lauderdale-West Palm Beach, FL MSA
     - Miami, OK MicroSA
     - Michigan City-La Porte, IN MSA
     - Middlesborough, KY MicroSA
     - Midland, MI MSA
     - Midland, TX MSA
     - Milledgeville, GA MicroSA
     - Milwaukee-Waukesha-West Allis, WI MSA
     - Mineral Wells, TX MicroSA
     - Minneapolis-St. Paul-Bloomington, MN-WI MSA
     - Minot, ND MicroSA
     - Missoula, MT MSA
     - Mitchell, SD MicroSA
     - Moberly, MO MicroSA
     - Mobile, AL MSA
     - Modesto, CA MSA
     - Monroe, LA MSA
     - Monroe, MI MSA
     - Montgomery, AL MSA
     - Montrose, CO MicroSA
     - Morehead City, NC MicroSA
     - Morgan City, LA MicroSA
     - Morgantown, WV MSA
     - Morristown, TN MSA
     - Moscow, ID MicroSA
     - Moses Lake, WA MicroSA
     - Moultrie, GA MicroSA
     - Mount Airy, NC MicroSA
     - Mount Pleasant, MI MicroSA
     - Mount Pleasant, TX MicroSA
     - Mount Sterling, KY MicroSA
     - Mount Vernon-Anacortes, WA MSA
     - Mount Vernon, IL MicroSA
     - Mount Vernon, OH MicroSA
     - Mountain Home, AR MicroSA
     - Mountain Home, ID MicroSA
     - Muncie, IN MSA
     - Murray, KY MicroSA
     - Muscatine, IA MicroSA
     - Muskegon, MI MSA
     - Muskogee, OK MicroSA
     - Myrtle Beach-Conway-North Myrtle Beach, SC-NC MSA
     - Nacogdoches, TX MicroSA
     - Napa, CA MSA
     - Naples-Immokalee-Marco Island, FL MSA
     - Nashville-Davidson--Murfreesboro--Franklin, TN MSA
     - Natchez, MS-LA MicroSA
     - Natchitoches, LA MicroSA
     - New Bern, NC MSA
     - New Castle, IN MicroSA
     - New Castle, PA MicroSA
     - New Haven-Milford, CT MSA
     - New Orleans-Metairie, LA MSA
     - New Philadelphia-Dover, OH MicroSA
     - New Ulm, MN MicroSA
     - New York-Newark-Jersey City, NY-NJ-PA MSA
     - Newberry, SC MicroSA
     - Newport, OR MicroSA
     - Newport, TN MicroSA
     - Newton, IA MicroSA
     - Niles-Benton Harbor, MI MSA
     - Nogales, AZ MicroSA
     - None
     - Norfolk, NE MicroSA
     - North Platte, NE MicroSA
     - North Port-Sarasota-Bradenton, FL MSA
     - North Vernon, IN MicroSA
     - North Wilkesboro, NC MicroSA
     - Norwalk, OH MicroSA
     - Norwich-New London, CT MSA
     - Oak Harbor, WA MicroSA
     - Ocala, FL MSA
     - Ocean City, NJ MSA
     - Odessa, TX MSA
     - Ogden-Clearfield, UT MSA
     - Ogdensburg-Massena, NY MicroSA
     - Oil City, PA MicroSA
     - Okeechobee, FL MicroSA
     - Oklahoma City, OK MSA
     - Olean, NY MicroSA
     - Olympia-Tumwater, WA MSA
     - Omaha-Council Bluffs, NE-IA MSA
     - Oneonta, NY MicroSA
     - Ontario, OR-ID MicroSA
     - Opelousas, LA MicroSA
     - Orangeburg, SC MicroSA
     - Orlando-Kissimmee-Sanford, FL MSA
     - Oshkosh-Neenah, WI MSA
     - Oskaloosa, IA MicroSA
     - Othello, WA MicroSA
     - Ottawa-Peru, IL MicroSA
     - Ottawa, KS MicroSA
     - Ottumwa, IA MicroSA
     - Owatonna, MN MicroSA
     - Owensboro, KY MSA
     - Owosso, MI MicroSA
     - Oxford, MS MicroSA
     - Oxford, NC MicroSA
     - Oxnard-Thousand Oaks-Ventura, CA MSA
     - Ozark, AL MicroSA
     - Paducah, KY-IL MicroSA
     - Pahrump, NV MicroSA
     - Palatka, FL MicroSA
     - Palestine, TX MicroSA
     - Palm Bay-Melbourne-Titusville, FL MSA
     - Pampa, TX MicroSA
     - Panama City, FL MSA
     - Paragould, AR MicroSA
     - Paris, TN MicroSA
     - Paris, TX MicroSA
     - Parkersburg-Vienna, WV MSA
     - Parsons, KS MicroSA
     - Payson, AZ MicroSA
     - Pecos, TX MicroSA
     - Pensacola-Ferry Pass-Brent, FL MSA
     - Peoria, IL MSA
     - Peru, IN MicroSA
     - Philadelphia-Camden-Wilmington, PA-NJ-DE-MD MSA
     - Phoenix-Mesa-Scottsdale, AZ MSA
     - Picayune, MS MicroSA
     - Pierre, SD MicroSA
     - Pine Bluff, AR MSA
     - Pinehurst-Southern Pines, NC MicroSA
     - Pittsburg, KS MicroSA
     - Pittsburgh, PA MSA
     - Pittsfield, MA MSA
     - Plainview, TX MicroSA
     - Platteville, WI MicroSA
     - Plattsburgh, NY MicroSA
     - Plymouth, IN MicroSA
     - Pocatello, ID MSA
     - Point Pleasant, WV-OH MicroSA
     - Ponca City, OK MicroSA
     - Pontiac, IL MicroSA
     - Poplar Bluff, MO MicroSA
     - Port Angeles, WA MicroSA
     - Port Clinton, OH MicroSA
     - Port Lavaca, TX MicroSA
     - Port St. Lucie, FL MSA
     - Portales, NM MicroSA
     - Portland-South Portland, ME MSA
     - Portland-Vancouver-Hillsboro, OR-WA MSA
     - Portsmouth, OH MicroSA
     - Pottsville, PA MicroSA
     - Prescott, AZ MSA
     - Price, UT MicroSA
     - Prineville, OR MicroSA
     - Providence-Warwick, RI-MA MSA
     - Provo-Orem, UT MSA
     - Pueblo, CO MSA
     - Pullman, WA MicroSA
     - Punta Gorda, FL MSA
     - Quincy, IL-MO MicroSA
     - Racine, WI MSA
     - Raleigh, NC MSA
     - Rapid City, SD MSA
     - Raymondville, TX MicroSA
     - Reading, PA MSA
     - Red Bluff, CA MicroSA
     - Red Wing, MN MicroSA
     - Redding, CA MSA
     - Reno, NV MSA
     - Rexburg, ID MicroSA
     - Richmond-Berea, KY MicroSA
     - Richmond, IN MicroSA
     - Richmond, VA MSA
     - Rio Grande City, TX MicroSA
     - Riverside-San Bernardino-Ontario, CA MSA
     - Riverton, WY MicroSA
     - Roanoke Rapids, NC MicroSA
     - Roanoke, VA MSA
     - Rochelle, IL MicroSA
     - Rochester, MN MSA
     - Rochester, NY MSA
     - Rock Springs, WY MicroSA
     - Rockford, IL MSA
     - Rockingham, NC MicroSA
     - Rocky Mount, NC MSA
     - Rolla, MO MicroSA
     - Rome, GA MSA
     - Roseburg, OR MicroSA
     - Roswell, NM MicroSA
     - Russellville, AR MicroSA
     - Ruston, LA MicroSA
     - Rutland, VT MicroSA
     - Sacramento--Roseville--Arden-Arcade, CA MSA
     - Safford, AZ MicroSA
     - Saginaw, MI MSA
     - Salem, OH MicroSA
     - Salem, OR MSA
     - Salina, KS MicroSA
     - Salinas, CA MSA
     - Salisbury, MD-DE MSA
     - Salt Lake City, UT MSA
     - San Angelo, TX MSA
     - San Antonio-New Braunfels, TX MSA
     - San Diego-Carlsbad, CA MSA
     - San Francisco-Oakland-Hayward, CA MSA
     - San Jose-Sunnyvale-Santa Clara, CA MSA
     - San Luis Obispo-Paso Robles-Arroyo Grande, CA MSA
     - Sandpoint, ID MicroSA
     - Sandusky, OH MicroSA
     - Sanford, NC MicroSA
     - Santa Cruz-Watsonville, CA MSA
     - Santa Fe, NM MSA
     - Santa Maria-Santa Barbara, CA MSA
     - Santa Rosa, CA MSA
     - Sault Ste. Marie, MI MicroSA
     - Savannah, GA MSA
     - Sayre, PA MicroSA
     - Scottsbluff, NE MicroSA
     - Scottsboro, AL MicroSA
     - Scranton--Wilkes-Barre--Hazleton, PA MSA
     - Searcy, AR MicroSA
     - Seattle-Tacoma-Bellevue, WA MSA
     - Sebastian-Vero Beach, FL MSA
     - Sebring, FL MSA
     - Sedalia, MO MicroSA
     - Selinsgrove, PA MicroSA
     - Selma, AL MicroSA
     - Seneca Falls, NY MicroSA
     - Seneca, SC MicroSA
     - Sevierville, TN MicroSA
     - Seymour, IN MicroSA
     - Shawano, WI MicroSA
     - Shawnee, OK MicroSA
     - Sheboygan, WI MSA
     - Shelby, NC MicroSA
     - Shelbyville, TN MicroSA
     - Shelton, WA MicroSA
     - Sheridan, WY MicroSA
     - Sherman-Denison, TX MSA
     - Show Low, AZ MicroSA
     - Shreveport-Bossier City, LA MSA
     - Sidney, OH MicroSA
     - Sierra Vista-Douglas, AZ MSA
     - Sikeston, MO MicroSA
     - Silver City, NM MicroSA
     - Sioux City, IA-NE-SD MSA
     - Sioux Falls, SD MSA
     - Snyder, TX MicroSA
     - Somerset, KY MicroSA
     - Somerset, PA MicroSA
     - Sonora, CA MicroSA
     - South Bend-Mishawaka, IN-MI MSA
     - Spartanburg, SC MSA
     - Spearfish, SD MicroSA
     - Spencer, IA MicroSA
     - Spirit Lake, IA MicroSA
     - Spokane-Spokane Valley, WA MSA
     - Springfield, IL MSA
     - Springfield, MA MSA
     - Springfield, MO MSA
     - Springfield, OH MSA
     - St. Cloud, MN MSA
     - St. George, UT MSA
     - St. Joseph, MO-KS MSA
     - St. Louis, MO-IL MSA
     - St. Marys, GA MicroSA
     - Starkville, MS MicroSA
     - State College, PA MSA
     - Statesboro, GA MicroSA
     - Staunton-Waynesboro, VA MSA
     - Steamboat Springs, CO MicroSA
     - Stephenville, TX MicroSA
     - Sterling, CO MicroSA
     - Sterling, IL MicroSA
     - Stevens Point, WI MicroSA
     - Stillwater, OK MicroSA
     - Stockton-Lodi, CA MSA
     - Storm Lake, IA MicroSA
     - Sturgis, MI MicroSA
     - Sulphur Springs, TX MicroSA
     - Summerville, GA MicroSA
     - Summit Park, UT MicroSA
     - Sumter, SC MSA
     - Sunbury, PA MicroSA
     - Susanville, CA MicroSA
     - Sweetwater, TX MicroSA
     - Syracuse, NY MSA
     - Tahlequah, OK MicroSA
     - Talladega-Sylacauga, AL MicroSA
     - Tallahassee, FL MSA
     - Tampa-St. Petersburg-Clearwater, FL MSA
     - Taos, NM MicroSA
     - Taylorville, IL MicroSA
     - Terre Haute, IN MSA
     - Texarkana, TX-AR MSA
     - The Dalles, OR MicroSA
     - The Villages, FL MSA
     - Thomaston, GA MicroSA
     - Thomasville, GA MicroSA
     - Tiffin, OH MicroSA
     - Tifton, GA MicroSA
     - Toccoa, GA MicroSA
     - Toledo, OH MSA
     - Topeka, KS MSA
     - Torrington, CT MicroSA
     - Traverse City, MI MicroSA
     - Trenton, NJ MSA
     - Troy, AL MicroSA
     - Truckee-Grass Valley, CA MicroSA
     - Tucson, AZ MSA
     - Tullahoma-Manchester, TN MicroSA
     - Tulsa, OK MSA
     - Tupelo, MS MicroSA
     - Tuscaloosa, AL MSA
     - Twin Falls, ID MicroSA
     - Tyler, TX MSA
     - Ukiah, CA MicroSA
     - Union City, TN-KY MicroSA
     - Urban Honolulu, HI MSA
     - Urbana, OH MicroSA
     - Utica-Rome, NY MSA
     - Uvalde, TX MicroSA
     - Valdosta, GA MSA
     - Vallejo-Fairfield, CA MSA
     - Valley, AL MicroSA
     - Van Wert, OH MicroSA
     - Vermillion, SD MicroSA
     - Vernal, UT MicroSA
     - Vernon, TX MicroSA
     - Vicksburg, MS MicroSA
     - Victoria, TX MSA
     - Vidalia, GA MicroSA
     - Vincennes, IN MicroSA
     - Vineland-Bridgeton, NJ MSA
     - Vineyard Haven, MA MicroSA
     - Virginia Beach-Norfolk-Newport News, VA-NC MSA
     - Visalia-Porterville, CA MSA
     - Wabash, IN MicroSA
     - Waco, TX MSA
     - Wahpeton, ND-MN MicroSA
     - Walla Walla, WA MSA
     - Wapakoneta, OH MicroSA
     - Warner Robins, GA MSA
     - Warren, PA MicroSA
     - Warrensburg, MO MicroSA
     - Warsaw, IN MicroSA
     - Washington-Arlington-Alexandria, DC-VA-MD-WV MSA
     - Washington Court House, OH MicroSA
     - Washington, IN MicroSA
     - Washington, NC MicroSA
     - Waterloo-Cedar Falls, IA MSA
     - Watertown-Fort Atkinson, WI MicroSA
     - Watertown-Fort Drum, NY MSA
     - Watertown, SD MicroSA
     - Wauchula, FL MicroSA
     - Wausau, WI MSA
     - Waycross, GA MicroSA
     - Weatherford, OK MicroSA
     - Weirton-Steubenville, WV-OH MSA
     - Wenatchee, WA MSA
     - West Plains, MO MicroSA
     - Wheeling, WV-OH MSA
     - Whitewater-Elkhorn, WI MicroSA
     - Wichita Falls, TX MSA
     - Wichita, KS MSA
     - Williamsport, PA MSA
     - Williston, ND MicroSA
     - Willmar, MN MicroSA
     - Wilmington, NC MSA
     - Wilmington, OH MicroSA
     - Wilson, NC MicroSA
     - Winchester, VA-WV MSA
     - Winnemucca, NV MicroSA
     - Winona, MN MicroSA
     - Winston-Salem, NC MSA
     - Wisconsin Rapids-Marshfield, WI MicroSA
     - Woodward, OK MicroSA
     - Wooster, OH MicroSA
     - Worcester, MA-CT MSA
     - Worthington, MN MicroSA
     - Yakima, WA MSA
     - Yankton, SD MicroSA
     - York-Hanover, PA MSA
     - Youngstown-Warren-Boardman, OH-PA MSA
     - Yuba City, CA MSA
     - Yuma, AZ MSA
     - Zanesville, OH MicroSA
     - Zapata, TX MicroSA
   * - Stock saturation
     - 0.014%
     - 0.026%
     - 0.053%
     - 0.012%
     - 0.032%
     - 0.23%
     - 0.023%
     - 0.3%
     - 0.05%
     - 0.037%
     - 0.02%
     - 0.011%
     - 0.03%
     - 0.28%
     - 0.049%
     - 0.015%
     - 0.012%
     - 0.26%
     - 0.012%
     - 0.012%
     - 0.042%
     - 0.0091%
     - 0.08%
     - 0.012%
     - 0.028%
     - 0.017%
     - 0.12%
     - 0.0045%
     - 0.015%
     - 0.11%
     - 0.04%
     - 0.071%
     - 0.011%
     - 0.016%
     - 0.0078%
     - 0.012%
     - 0.16%
     - 0.016%
     - 0.034%
     - 0.016%
     - 0.0052%
     - 0.062%
     - 0.02%
     - 0.017%
     - 0.03%
     - 1.7%
     - 0.095%
     - 0.049%
     - 0.013%
     - 0.027%
     - 0.19%
     - 0.046%
     - 0.57%
     - 0.013%
     - 0.009%
     - 0.22%
     - 0.86%
     - 0.055%
     - 0.022%
     - 0.014%
     - 0.12%
     - 0.022%
     - 0.018%
     - 0.0093%
     - 0.019%
     - 0.012%
     - 0.26%
     - 0.045%
     - 0.036%
     - 0.014%
     - 0.0078%
     - 0.13%
     - 0.028%
     - 0.043%
     - 0.016%
     - 0.0079%
     - 0.017%
     - 0.069%
     - 0.016%
     - 0.062%
     - 0.0089%
     - 0.016%
     - 0.02%
     - 0.016%
     - 0.01%
     - 0.02%
     - 0.055%
     - 0.084%
     - 0.38%
     - 0.042%
     - 0.012%
     - 0.059%
     - 0.059%
     - 0.052%
     - 0.028%
     - 0.038%
     - 0.015%
     - 0.016%
     - 0.19%
     - 0.0088%
     - 0.025%
     - 0.0079%
     - 1.4%
     - 0.098%
     - 0.053%
     - 0.034%
     - 0.016%
     - 0.049%
     - 0.038%
     - 0.023%
     - 0.081%
     - 0.012%
     - 0.014%
     - 0.27%
     - 0.011%
     - 0.0094%
     - 0.01%
     - 0.11%
     - 0.014%
     - 0.044%
     - 0.015%
     - 0.39%
     - 0.012%
     - 0.071%
     - 0.017%
     - 0.051%
     - 0.013%
     - 0.019%
     - 0.017%
     - 0.032%
     - 0.012%
     - 0.014%
     - 0.012%
     - 0.0082%
     - 0.014%
     - 0.13%
     - 0.012%
     - 0.28%
     - 0.032%
     - 0.044%
     - 0.017%
     - 0.017%
     - 0.027%
     - 0.015%
     - 0.086%
     - 0.013%
     - 0.013%
     - 0.014%
     - 0.025%
     - 0.048%
     - 0.077%
     - 0.021%
     - 0.23%
     - 0.081%
     - 0.73%
     - 0.075%
     - 0.18%
     - 0.031%
     - 2.8%
     - 0.073%
     - 0.024%
     - 0.69%
     - 0.092%
     - 0.032%
     - 0.008%
     - 0.085%
     - 0.027%
     - 0.71%
     - 0.011%
     - 0.038%
     - 0.011%
     - 0.016%
     - 0.015%
     - 0.049%
     - 0.012%
     - 0.015%
     - 0.075%
     - 0.21%
     - 0.055%
     - 0.26%
     - 0.098%
     - 0.025%
     - 0.02%
     - 0.01%
     - 0.63%
     - 0.048%
     - 0.0081%
     - 0.037%
     - 0.023%
     - 0.008%
     - 0.013%
     - 0.014%
     - 0.036%
     - 0.14%
     - 0.015%
     - 0.015%
     - 0.028%
     - 0.012%
     - 0.0046%
     - 0.012%
     - 0.0084%
     - 0.11%
     - 0.021%
     - 0.028%
     - 0.02%
     - 0.035%
     - 2%
     - 0.041%
     - 0.027%
     - 0.017%
     - 0.04%
     - 0.08%
     - 0.13%
     - 0.27%
     - 0.011%
     - 0.05%
     - 0.038%
     - 0.0098%
     - 0.012%
     - 0.014%
     - 0.23%
     - 0.0082%
     - 0.83%
     - 0.011%
     - 0.19%
     - 1.4%
     - 0.01%
     - 0.011%
     - 0.009%
     - 0.051%
     - 0.013%
     - 0.051%
     - 0.019%
     - 0.029%
     - 0.03%
     - 0.11%
     - 0.0059%
     - 0.015%
     - 0.037%
     - 0.02%
     - 0.015%
     - 0.17%
     - 0.013%
     - 0.013%
     - 0.06%
     - 0.015%
     - 0.053%
     - 0.024%
     - 0.011%
     - 0.013%
     - 0.042%
     - 0.015%
     - 0.21%
     - 0.021%
     - 0.048%
     - 0.0074%
     - 0.058%
     - 0.011%
     - 0.016%
     - 0.017%
     - 0.029%
     - 0.011%
     - 0.02%
     - 0.017%
     - 0.089%
     - 0.015%
     - 0.015%
     - 0.12%
     - 0.047%
     - 0.0065%
     - 0.1%
     - 0.031%
     - 0.0056%
     - 0.02%
     - 0.008%
     - 0.075%
     - 0.018%
     - 0.022%
     - 0.037%
     - 0.15%
     - 0.12%
     - 0.027%
     - 0.017%
     - 0.025%
     - 0.0059%
     - 0.048%
     - 0.14%
     - 0.053%
     - 0.067%
     - 0.033%
     - 0.025%
     - 0.0081%
     - 0.1%
     - 0.013%
     - 0.014%
     - 0.022%
     - 0.0086%
     - 0.016%
     - 0.092%
     - 0.13%
     - 0.0099%
     - 0.024%
     - 0.0096%
     - 0.016%
     - 0.012%
     - 0.02%
     - 0.24%
     - 0.035%
     - 0.018%
     - 0.091%
     - 0.052%
     - 0.012%
     - 0.018%
     - 0.019%
     - 0.011%
     - 0.018%
     - 0.025%
     - 0.031%
     - 0.015%
     - 0.018%
     - 0.051%
     - 0.027%
     - 0.021%
     - 0.04%
     - 0.034%
     - 0.026%
     - 0.048%
     - 0.31%
     - 0.028%
     - 0.0083%
     - 0.0094%
     - 0.028%
     - 0.075%
     - 0.1%
     - 0.024%
     - 0.025%
     - 0.24%
     - 0.0084%
     - 0.28%
     - 0.016%
     - 0.057%
     - 0.017%
     - 0.014%
     - 0.032%
     - 0.0076%
     - 0.13%
     - 0.0061%
     - 0.08%
     - 0.013%
     - 0.039%
     - 0.034%
     - 0.013%
     - 0.18%
     - 0.016%
     - 0.039%
     - 0.38%
     - 0.01%
     - 0.047%
     - 0.0097%
     - 0.0087%
     - 0.0076%
     - 0.027%
     - 0.015%
     - 0.0053%
     - 0.026%
     - 0.12%
     - 0.016%
     - 0.064%
     - 0.079%
     - 0.025%
     - 0.019%
     - 0.037%
     - 0.058%
     - 0.0071%
     - 0.038%
     - 0.016%
     - 0.063%
     - 1.8%
     - 0.025%
     - 0.017%
     - 0.12%
     - 0.012%
     - 0.14%
     - 0.025%
     - 0.0062%
     - 0.021%
     - 0.012%
     - 0.038%
     - 0.029%
     - 0.62%
     - 0.0072%
     - 0.018%
     - 0.052%
     - 0.014%
     - 0.031%
     - 0.052%
     - 0.18%
     - 0.011%
     - 0.042%
     - 0.014%
     - 0.46%
     - 0.013%
     - 0.056%
     - 0.016%
     - 0.05%
     - 0.0075%
     - 0.051%
     - 0.017%
     - 0.048%
     - 0.018%
     - 0.009%
     - 0.071%
     - 0.049%
     - 0.04%
     - 0.056%
     - 0.011%
     - 0.0099%
     - 0.053%
     - 0.11%
     - 0.035%
     - 0.034%
     - 0.66%
     - 0.023%
     - 0.017%
     - 0.026%
     - 0.015%
     - 0.011%
     - 0.074%
     - 0.018%
     - 0.0047%
     - 0.04%
     - 0.027%
     - 0.13%
     - 0.11%
     - 0.062%
     - 0.01%
     - 0.02%
     - 0.01%
     - 0.024%
     - 0.29%
     - 0.029%
     - 0.043%
     - 0.0086%
     - 0.028%
     - 0.065%
     - 0.15%
     - 0.021%
     - 0.067%
     - 0.021%
     - 0.084%
     - 0.21%
     - 0.0039%
     - 0.15%
     - 0.15%
     - 0.014%
     - 0.058%
     - 0.063%
     - 0.64%
     - 0.012%
     - 0.027%
     - 0.011%
     - 0.036%
     - 0.014%
     - 0.041%
     - 0.012%
     - 0.042%
     - 0.0069%
     - 0.013%
     - 0.0099%
     - 0.037%
     - 0.02%
     - 0.016%
     - 0.16%
     - 0.0085%
     - 0.0061%
     - 0.033%
     - 0.0089%
     - 0.099%
     - 0.24%
     - 0.014%
     - 0.033%
     - 0.012%
     - 0.012%
     - 0.041%
     - 0.067%
     - 0.032%
     - 0.0062%
     - 3.4%
     - 0.41%
     - 0.095%
     - 0.013%
     - 0.027%
     - 0.039%
     - 0.085%
     - 0.011%
     - 0.076%
     - 0.037%
     - 0.011%
     - 0.21%
     - 0.016%
     - 0.0086%
     - 0.019%
     - 0.011%
     - 0.13%
     - 0.029%
     - 0.028%
     - 0.03%
     - 0.04%
     - 0.021%
     - 0.033%
     - 0.023%
     - 0.016%
     - 0.021%
     - 0.026%
     - 0.0083%
     - 0.0075%
     - 0.021%
     - 0.012%
     - 0.012%
     - 0.025%
     - 0.0072%
     - 0.019%
     - 0.012%
     - 0.0061%
     - 0.017%
     - 0.2%
     - 0.018%
     - 0.013%
     - 0.0096%
     - 0.033%
     - 0.069%
     - 0.42%
     - 0.013%
     - 0.063%
     - 0.035%
     - 0.013%
     - 0.0081%
     - 1.9%
     - 0.01%
     - 0.036%
     - 0.0098%
     - 0.027%
     - 0.045%
     - 0.019%
     - 0.5%
     - 0.011%
     - 1.1%
     - 0.027%
     - 0.038%
     - 0.0077%
     - 0.008%
     - 0.14%
     - 0.13%
     - 0.058%
     - 0.047%
     - 0.12%
     - 0.014%
     - 0.037%
     - 0.017%
     - 0.044%
     - 0.038%
     - 0.012%
     - 0.027%
     - 0.014%
     - 0.025%
     - 0.021%
     - 0.009%
     - 0.016%
     - 0.039%
     - 0.013%
     - 0.019%
     - 0.017%
     - 0.0091%
     - 0.039%
     - 0.014%
     - 0.013%
     - 0.055%
     - 0.023%
     - 0.21%
     - 0.021%
     - 0.041%
     - 0.15%
     - 0.55%
     - 0.018%
     - 0.014%
     - 0.044%
     - 0.016%
     - 0.03%
     - 0.27%
     - 0.41%
     - 0.03%
     - 0.0086%
     - 5.9%
     - 0.013%
     - 0.023%
     - 0.013%
     - 0.012%
     - 0.057%
     - 0.014%
     - 7.3%
     - 0.016%
     - 0.013%
     - 0.31%
     - 0.009%
     - 0.025%
     - 0.019%
     - 0.091%
     - 0.03%
     - 0.12%
     - 0.074%
     - 0.042%
     - 0.16%
     - 0.039%
     - 0.02%
     - 0.014%
     - 0.42%
     - 0.031%
     - 0.083%
     - 0.28%
     - 0.023%
     - 0.015%
     - 0.027%
     - 0.031%
     - 0.73%
     - 0.055%
     - 0.0073%
     - 0.0047%
     - 0.051%
     - 0.0083%
     - 0.015%
     - 0.011%
     - 0.038%
     - 0.022%
     - 0.018%
     - 0.017%
     - 0.21%
     - 0.017%
     - 0.035%
     - 0.016%
     - 0.027%
     - 0.015%
     - 0.2%
     - 0.0075%
     - 0.082%
     - 0.014%
     - 0.013%
     - 0.017%
     - 0.032%
     - 0.0075%
     - 0.025%
     - 0.0035%
     - 0.15%
     - 0.12%
     - 0.011%
     - 1.8%
     - 1.4%
     - 0.018%
     - 0.0076%
     - 0.031%
     - 0.034%
     - 0.013%
     - 0.83%
     - 0.051%
     - 0.01%
     - 0.016%
     - 0.027%
     - 0.015%
     - 0.025%
     - 0.02%
     - 0.016%
     - 0.012%
     - 0.015%
     - 0.027%
     - 0.021%
     - 0.0087%
     - 0.16%
     - 0.0062%
     - 0.2%
     - 0.71%
     - 0.025%
     - 0.051%
     - 0.084%
     - 0.0072%
     - 0.0077%
     - 0.52%
     - 0.12%
     - 0.052%
     - 0.015%
     - 0.076%
     - 0.026%
     - 0.061%
     - 0.37%
     - 0.047%
     - 0.0053%
     - 0.12%
     - 0.02%
     - 0.015%
     - 0.058%
     - 0.14%
     - 0.016%
     - 0.032%
     - 0.023%
     - 0.39%
     - 0.015%
     - 1.1%
     - 0.013%
     - 0.028%
     - 0.11%
     - 0.017%
     - 0.067%
     - 0.35%
     - 0.014%
     - 0.11%
     - 0.016%
     - 0.05%
     - 0.015%
     - 0.03%
     - 0.037%
     - 0.02%
     - 0.027%
     - 0.015%
     - 0.025%
     - 0.66%
     - 0.0099%
     - 0.065%
     - 0.035%
     - 0.11%
     - 0.02%
     - 0.1%
     - 0.18%
     - 0.3%
     - 0.036%
     - 0.64%
     - 0.89%
     - 1.3%
     - 0.5%
     - 0.089%
     - 0.018%
     - 0.028%
     - 0.018%
     - 0.079%
     - 0.054%
     - 0.12%
     - 0.15%
     - 0.016%
     - 0.12%
     - 0.022%
     - 0.013%
     - 0.018%
     - 0.19%
     - 0.025%
     - 1.1%
     - 0.058%
     - 0.041%
     - 0.014%
     - 0.012%
     - 0.015%
     - 0.012%
     - 0.029%
     - 0.042%
     - 0.014%
     - 0.017%
     - 0.022%
     - 0.038%
     - 0.032%
     - 0.014%
     - 0.024%
     - 0.011%
     - 0.041%
     - 0.043%
     - 0.15%
     - 0.015%
     - 0.045%
     - 0.013%
     - 0.011%
     - 0.052%
     - 0.076%
     - 0.0054%
     - 0.023%
     - 0.028%
     - 0.023%
     - 0.11%
     - 0.1%
     - 0.01%
     - 0.006%
     - 0.0099%
     - 0.18%
     - 0.072%
     - 0.19%
     - 0.15%
     - 0.046%
     - 0.059%
     - 0.047%
     - 0.04%
     - 0.92%
     - 0.016%
     - 0.016%
     - 0.048%
     - 0.022%
     - 0.04%
     - 0.012%
     - 0.013%
     - 0.0067%
     - 0.019%
     - 0.023%
     - 0.026%
     - 0.18%
     - 0.0062%
     - 0.021%
     - 0.011%
     - 0.0081%
     - 0.02%
     - 0.035%
     - 0.034%
     - 0.0095%
     - 0.0053%
     - 0.22%
     - 0.016%
     - 0.033%
     - 0.12%
     - 1%
     - 0.015%
     - 0.012%
     - 0.056%
     - 0.049%
     - 0.0085%
     - 0.048%
     - 0.009%
     - 0.015%
     - 0.018%
     - 0.012%
     - 0.0093%
     - 0.2%
     - 0.078%
     - 0.065%
     - 0.061%
     - 0.11%
     - 0.012%
     - 0.04%
     - 0.34%
     - 0.034%
     - 0.31%
     - 0.044%
     - 0.078%
     - 0.03%
     - 0.066%
     - 0.03%
     - 0.013%
     - 0.26%
     - 0.012%
     - 0.1%
     - 0.0082%
     - 0.044%
     - 0.12%
     - 0.013%
     - 0.0094%
     - 0.0043%
     - 0.0097%
     - 0.0047%
     - 0.019%
     - 0.03%
     - 0.012%
     - 0.013%
     - 0.042%
     - 0.013%
     - 0.53%
     - 0.11%
     - 0.011%
     - 0.079%
     - 0.008%
     - 0.019%
     - 0.015%
     - 0.057%
     - 0.017%
     - 0.016%
     - 0.028%
     - 1.7%
     - 0.0095%
     - 0.0093%
     - 0.019%
     - 0.054%
     - 0.026%
     - 0.044%
     - 0.0095%
     - 0.0072%
     - 0.044%
     - 0.018%
     - 0.0093%
     - 0.043%
     - 0.039%
     - 0.013%
     - 0.052%
     - 0.039%
     - 0.049%
     - 0.2%
     - 0.039%
     - 0.012%
     - 0.015%
     - 0.099%
     - 0.013%
     - 0.027%
     - 0.043%
     - 0.0054%
     - 0.016%
     - 0.22%
     - 0.026%
     - 0.0067%
     - 0.034%
     - 0.28%
     - 0.0064%
     - 0.064%
     - 0.0073%
     - 0.13%
     - 0.19%
     - 0.046%
     - 0.067%
     - 0.028%
     - 0.0046%

.. _misc_extra_refrigerator:

Misc Extra Refrigerator
-----------------------

Description
***********

The presence and rated efficiency of the secondary refrigerator.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \Age of refrigerator converted to efficiency levels using ENERGYSTAR shipment-weighted efficiencies by year data from Home Energy Score: http://hes-documentation.lbl.gov/. Check the comments in: HES-Refrigerator_Age_vs_Efficiency.tsv


Assumption
**********

- \The current year is assumed to be 2022

- \Previously, for each year, the EF values were rounded to the nearest EF level, and then the distribution of EF levels were calculated for the age bins. Currently, each year has its own distribution and then we average out the distributions to get the distribution for the age bins. EF for all years are weighted equally when calculating the average distribution for the age bins.

- \EnergyStar distributions from 2009 dependent on [Geometry Building Type RECS,Federal Poverty Level,Tenure] is used to calculate efficiency distribution in RECS2020.EnergyStar Refrigerators assumed to be 10% more efficient than standard.Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:

- \Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State', 'Vintage'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Vintage with Vintage ACS

  - \[5] Vintage with combined 1960s

  - \[6] Vintage with combined 1960s and post 200ss

  - \[7] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[8] Census Division RECS to Census Region

  - \[9] Census Region to National

- \Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[7] Census Division RECS to Census Region

  - \[8] Census Region to National

- \In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across ('Heating Fuel', ['Tenure', 'Federal Poverty Level']).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Misc Extra Refrigerator** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - EF 6.7
     - EF 10.2
     - EF 10.5
     - EF 15.9
     - EF 17.6
     - EF 19.9
     - EF 21.9
     - None
     - Void
   * - Stock saturation
     - 1.9%
     - 0.31%
     - 0.84%
     - 4.5%
     - 11%
     - 6.9%
     - 0.47%
     - 74%
     - 0%
   * - ``appliance_extra_refrigerator_rated_annual_consumption``
     - 1139
     - 748
     - 727
     - 480
     - 434
     - 384
     - 348
     - 
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``appliance_extra_refrigerator_rated_annual_consumption``
     - kWh/yr
     - The EnergyGuide rated annual energy consumption for the extra refrigerator.
.. _misc_freezer:

Misc Freezer
------------

Description
***********

The presence and rated efficiency of a standalone freezer.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \The national average EF is 12 based on the 2014 BA house simulation protocols

- \Due to low sample count, the tsv is constructed with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[7] Census Division RECS to Census Region

  - \[8] Census Region to National


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Misc Freezer** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - EF 12, National Average
     - None
     - Void
   * - Stock saturation
     - 33%
     - 67%
     - 0%
   * - ``appliance_freezer_rated_annual_consumption``
     - 935
     - 
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``appliance_freezer_rated_annual_consumption``
     - kWh/yr
     - The EnergyGuide rated annual energy consumption for the freezer.
.. _misc_gas_fireplace:

Misc Gas Fireplace
------------------

Description
***********

Presence of a gas fireplace.

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Misc Gas Fireplace** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Gas Fireplace
     - None
   * - Stock saturation
     - 3.2%
     - 97%
   * - ``misc_fireplace_fuel_type``
     - natural gas
     - 
   * - ``misc_fireplace_annual_energy_use``
     - 
     - 0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``misc_fireplace_fuel_type``
     - 
     - The fuel type of the grill.
   * - ``misc_fireplace_annual_energy_use``
     - therm/yr
     - The annual energy consumption of the grill.
.. _misc_gas_grill:

Misc Gas Grill
--------------

Description
***********

Presence of a gas grill.

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Misc Gas Grill** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Gas Grill
     - None
   * - Stock saturation
     - 2.9%
     - 97%
   * - ``misc_grill_fuel_type``
     - natural gas
     - 
   * - ``misc_grill_annual_energy_use``
     - 
     - 0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``misc_grill_fuel_type``
     - 
     - The fuel type of the grill.
   * - ``misc_grill_annual_energy_use``
     - therm/yr
     - The annual energy consumption of the grill.
.. _misc_gas_lighting:

Misc Gas Lighting
-----------------

Description
***********

Presence of exterior gas lighting.

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Misc Gas Lighting** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Gas Lighting
     - None
   * - Stock saturation
     - 1.2%
     - 99%
   * - ``misc_gas_lighting_fuel_type``
     - natural gas
     - 
   * - ``misc_gas_lighting_annual_energy_use``
     - 
     - 0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``misc_gas_lighting_fuel_type``
     - 
     - The fuel type of the misc lighting.
   * - ``misc_gas_lighting_annual_energy_use``
     - therm/yr
     - The annual energy consumption of the misc lighting.
.. _misc_hot_tub_spa:

Misc Hot Tub Spa
----------------

Description
***********

The presence and heating fuel of a hot tub/spa at the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:

- \Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State', 'Heating Fuel'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Heating Fuel coarsened to Other Fuel, Wood and Propane combined

  - \[3] Heating Fuel coarsened to Fuel Oil, Other Fuel, Wood and Propane combined

  - \[4] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[5] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[6] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[7] Census Division RECS to Census Region

  - \[8] Census Region to National

- \Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[7] Census Division RECS to Census Region

  - \[8] Census Region to National

- \In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across ('Heating Fuel', ['Tenure', 'Federal Poverty Level']).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Misc Hot Tub Spa** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Electricity
     - Natural Gas
     - None
     - Other Fuel
     - Void
   * - Stock saturation
     - 3.5%
     - 1.1%
     - 95%
     - 0.33%
     - 0%
   * - ``misc_permanent_spa_pump_annual_energy_use``
     - 
     - 
     - 0
     - 0
     - 
   * - ``misc_permanent_spa_heater_type``
     - electric resistance
     - gas fired
     - 
     - 
     - 
   * - ``misc_permanent_spa_heater_annual_electricity_use``
     - 
     - 
     - 0
     - 0
     - 
   * - ``misc_permanent_spa_heater_annual_natural_gas_use``
     - 
     - 
     - 0
     - 0
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``misc_permanent_spa_pump_annual_energy_use``
     - kWh/yr
     - The annual energy consumption of the spa.
   * - ``misc_permanent_spa_heater_type``
     - 
     - The type of spa heater.
   * - ``misc_permanent_spa_heater_annual_electricity_use``
     - kWh/yr
     - The annual electricity consumption of the spa heater.
   * - ``misc_permanent_spa_heater_annual_natural_gas_use``
     - kWh/yr
     - The annual natural gas consumption of the spa heater.
.. _misc_pool:

Misc Pool
---------

Description
***********

The presence of a pool at the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \The only valid option for multi-family homes is Nonesince the pool is most likely to be jointly ownedDue to low sample count, the tsv is constructed with the followingfallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently

  - \[7] Vintage homes built before 1960 coarsened to pre1960

  - \[8] Vintage homes built after 2000 coarsened to 2000-20

  - \[9] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[10] Census Division RECS to Census Region

  - \[11] Census Region to National


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Misc Pool** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Has Pool
     - None
     - Void
   * - Stock saturation
     - 7.1%
     - 93%
     - 0%
   * - ``misc_has_pool``
     - true
     - false
     - false

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``misc_has_pool``
     - 
     - Whether a pool is present.
.. _misc_pool_heater:

Misc Pool Heater
----------------

Description
***********

The heating fuel of the pool heater if there is a pool.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \the California Energy Commission 2019 Residential Appliance Saturation Study (RASS) microdata.


Assumption
**********

- \Within electric pool heaters, proportion of heat pump electric pool heating vs. non-heat pump electric pool heating was derived from RASS 2019.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Misc Pool Heater** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Electric Heat Pump
     - Electricity
     - Natural Gas
     - None
     - Other Fuel
   * - Stock saturation
     - 0.13%
     - 0.57%
     - 1%
     - 98%
     - 0.65%
   * - ``misc_pool_heater_type``
     - heat pump
     - electric resistance
     - gas fired
     - not present
     - not present

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``misc_pool_heater_type``
     - 
     - The type of pool heater.
.. _misc_pool_pump:

Misc Pool Pump
--------------

Description
***********

Presence and size of pool pump.

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Misc Pool Pump** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - 1.0 HP Pump
   * - Stock saturation
     - 93%
     - 7.1%
   * - ``pool_pump_usage_multiplier``
     - 
     - 1.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``pool_pump_usage_multiplier``
     - 
     - Multiplier on the pool pump energy usage that can reflect, e.g., high/low usage occupants.
.. _misc_well_pump:

Misc Well Pump
--------------

Description
***********

Presence of well pump according to the use of well for domestic water source.

Created by
**********

``sources/ahs/ahs2017_2019/tsv_maker.py``

Source
******

- \2017 and 2019 American Housing Survey (AHS) microdata.

- \Core Based Statistical Area (CBSA) data based on the Feb 2013 CBSA delineation file.


Assumption
**********

- \All well pumps are assumed to have typical efficiency.

- \Where the number of samples < 10, the Census Division is aggregated up to Census Region.

- \AHS has data for buildings up to 7 stories tall. Buildings with 8 or more stories are assumed not to have a well pump.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Misc Well Pump** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - Typical Efficiency
   * - Stock saturation
     - 87%
     - 13%
   * - ``misc_well_pump_annual_energy_use``
     - 0
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``misc_well_pump_annual_energy_use``
     - kWh/yr
     - The annual energy consumption of the well pump.
.. _natural_ventilation:

Natural Ventilation
-------------------

Description
***********

Schedule of natural ventilation from windows.

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Natural Ventilation** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Cooling Season, 7 days/wk
   * - Stock saturation
     - 100%
   * - ``enclosure_window_natural_ventilation_fraction_operable``
     - 0.67

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_window_natural_ventilation_fraction_operable``
     - frac
     - Total window area for operable windows divided by total window area. The total open window area for natural ventilation is calculated using A) the operable fraction, B) the assumption that only some of the area of operable windows can be open, and C) the assumption that only some of that openable area is actually opened by occupants whenever outdoor conditions are favorable.
.. _neighbors:

Neighbors
---------

Description
***********

Presence and distance between the dwelling unit and the nearest neighbors to the left and right.

Created by
**********

manually created

Source
******

- \OpenStreetMap data queried by Radiant Labs for Multi-Family and Single-Family Attached

- \Engineering Judgement for others


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Neighbors** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Left/Right at 15ft
     - 2
     - 4
     - 7
     - 12
     - 27
     - None
   * - Stock saturation
     - 68%
     - 0.19%
     - 3.4%
     - 5%
     - 9.2%
     - 13%
     - 1.3%
   * - ``geometry_neighbor_buildings_left_distance``
     - 15
     - 2
     - 4
     - 7
     - 12
     - 27
     - 
   * - ``geometry_neighbor_buildings_right_distance``
     - 15
     - 2
     - 4
     - 7
     - 12
     - 27
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_neighbor_buildings_left_distance``
     - ft
     - The distance between the unit and the neighboring building to the left (not including eaves).
   * - ``geometry_neighbor_buildings_right_distance``
     - ft
     - The distance between the unit and the neighboring building to the right (not including eaves).
.. _occupants:

Occupants
---------

Description
***********

The number of occupants living in the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \Option=10+ has a (weighted) representative value of 11. In ACS, Income, Tenure, and Occupants are reported for occupied units only. Because we assume vacant units share the same Income and Tenure distributions as occupied units, by extension, we assume this Occupants distribution applies to all units regardless of Vacancy Status. Where sample counts are less than 10 (6243 / 18000 rows), the Census Region average distribution has been inserted first (2593), followed by national average distribution (2678), followed by national + 'MF'/'SF' average distribution (252), followed by national + 'MF'/'SF' + 'Metro'/'Non-metro' average distribution (315)followed by national + 'MF'/'SF' + 'Metro'/'Non-metro' + Vacancy Status average distribution (657).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Occupants** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0
     - 1
     - 2
     - 3
     - 4
     - 5
     - 6
     - 7
     - 8
     - 9
     - 10+
   * - Stock saturation
     - 12%
     - 24%
     - 30%
     - 14%
     - 11%
     - 5.2%
     - 2.1%
     - 0.76%
     - 0.31%
     - 0.12%
     - 0.12%
   * - ``geometry_unit_num_occupants_number``
     - 0
     - 1
     - 2
     - 3
     - 4
     - 5
     - 6
     - 7
     - 8
     - 9
     - 11

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_unit_num_occupants_number``
     - 
     - Number of occupants.
.. _orientation:

Orientation
-----------

Description
***********

Orientation of the front of the dwelling unit as it faces the street.

Created by
**********

manually created

Source
******

- \OpenStreetMap data queried by Radiant Labs.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Orientation** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - East
     - West
     - Northeast
     - Southwest
     - North
     - South
     - Northwest
     - Southeast
   * - Stock saturation
     - 17%
     - 17%
     - 7.2%
     - 7.2%
     - 18%
     - 18%
     - 7.7%
     - 7.7%
   * - ``geometry_unit_direction_azimuth``
     - 90
     - 270
     - 45
     - 225
     - 0
     - 180
     - 315
     - 135

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_unit_direction_azimuth``
     - deg
     - The unit's front as measured clockwise from north (e.g., North=0, East=90, South=180, West=270).
.. _puma:

PUMA
----

Description
***********

The Public Use Microdata Area from 2010 U.S. Census that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **PUMA** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - AK, 00101
     - AK, 00102
     - AK, 00200
     - AK, 00300
     - AK, 00400
     - AL, 00100
     - AL, 00200
     - AL, 00301
     - AL, 00302
     - AL, 00400
     - AL, 00500
     - AL, 00600
     - AL, 00700
     - AL, 00800
     - AL, 00900
     - AL, 01000
     - AL, 01100
     - AL, 01200
     - AL, 01301
     - AL, 01302
     - AL, 01303
     - AL, 01304
     - AL, 01305
     - AL, 01400
     - AL, 01500
     - AL, 01600
     - AL, 01700
     - AL, 01800
     - AL, 01900
     - AL, 02000
     - AL, 02100
     - AL, 02200
     - AL, 02300
     - AL, 02400
     - AL, 02500
     - AL, 02600
     - AL, 02701
     - AL, 02702
     - AL, 02703
     - AR, 00100
     - AR, 00200
     - AR, 00300
     - AR, 00400
     - AR, 00500
     - AR, 00600
     - AR, 00700
     - AR, 00800
     - AR, 00900
     - AR, 01000
     - AR, 01100
     - AR, 01200
     - AR, 01300
     - AR, 01400
     - AR, 01500
     - AR, 01600
     - AR, 01700
     - AR, 01800
     - AR, 01900
     - AR, 02000
     - AZ, 00100
     - AZ, 00101
     - AZ, 00102
     - AZ, 00103
     - AZ, 00104
     - AZ, 00105
     - AZ, 00106
     - AZ, 00107
     - AZ, 00108
     - AZ, 00109
     - AZ, 00110
     - AZ, 00111
     - AZ, 00112
     - AZ, 00113
     - AZ, 00114
     - AZ, 00115
     - AZ, 00116
     - AZ, 00117
     - AZ, 00118
     - AZ, 00119
     - AZ, 00120
     - AZ, 00121
     - AZ, 00122
     - AZ, 00123
     - AZ, 00124
     - AZ, 00125
     - AZ, 00126
     - AZ, 00127
     - AZ, 00128
     - AZ, 00129
     - AZ, 00130
     - AZ, 00131
     - AZ, 00132
     - AZ, 00133
     - AZ, 00134
     - AZ, 00201
     - AZ, 00202
     - AZ, 00203
     - AZ, 00204
     - AZ, 00205
     - AZ, 00206
     - AZ, 00207
     - AZ, 00208
     - AZ, 00209
     - AZ, 00300
     - AZ, 00400
     - AZ, 00500
     - AZ, 00600
     - AZ, 00700
     - AZ, 00800
     - AZ, 00803
     - AZ, 00805
     - AZ, 00807
     - AZ, 00900
     - CA, 00101
     - CA, 00102
     - CA, 00103
     - CA, 00104
     - CA, 00105
     - CA, 00106
     - CA, 00107
     - CA, 00108
     - CA, 00109
     - CA, 00110
     - CA, 00300
     - CA, 00701
     - CA, 00702
     - CA, 01100
     - CA, 01301
     - CA, 01302
     - CA, 01303
     - CA, 01304
     - CA, 01305
     - CA, 01306
     - CA, 01307
     - CA, 01308
     - CA, 01309
     - CA, 01500
     - CA, 01700
     - CA, 01901
     - CA, 01902
     - CA, 01903
     - CA, 01904
     - CA, 01905
     - CA, 01906
     - CA, 01907
     - CA, 02300
     - CA, 02500
     - CA, 02901
     - CA, 02902
     - CA, 02903
     - CA, 02904
     - CA, 02905
     - CA, 03100
     - CA, 03300
     - CA, 03701
     - CA, 03702
     - CA, 03703
     - CA, 03704
     - CA, 03705
     - CA, 03706
     - CA, 03707
     - CA, 03708
     - CA, 03709
     - CA, 03710
     - CA, 03711
     - CA, 03712
     - CA, 03713
     - CA, 03714
     - CA, 03715
     - CA, 03716
     - CA, 03717
     - CA, 03718
     - CA, 03719
     - CA, 03720
     - CA, 03721
     - CA, 03722
     - CA, 03723
     - CA, 03724
     - CA, 03725
     - CA, 03726
     - CA, 03727
     - CA, 03728
     - CA, 03729
     - CA, 03730
     - CA, 03731
     - CA, 03732
     - CA, 03733
     - CA, 03734
     - CA, 03735
     - CA, 03736
     - CA, 03737
     - CA, 03738
     - CA, 03739
     - CA, 03740
     - CA, 03741
     - CA, 03742
     - CA, 03743
     - CA, 03744
     - CA, 03745
     - CA, 03746
     - CA, 03747
     - CA, 03748
     - CA, 03749
     - CA, 03750
     - CA, 03751
     - CA, 03752
     - CA, 03753
     - CA, 03754
     - CA, 03755
     - CA, 03756
     - CA, 03757
     - CA, 03758
     - CA, 03759
     - CA, 03760
     - CA, 03761
     - CA, 03762
     - CA, 03763
     - CA, 03764
     - CA, 03765
     - CA, 03766
     - CA, 03767
     - CA, 03768
     - CA, 03769
     - CA, 03900
     - CA, 04101
     - CA, 04102
     - CA, 04701
     - CA, 04702
     - CA, 05301
     - CA, 05302
     - CA, 05303
     - CA, 05500
     - CA, 05700
     - CA, 05901
     - CA, 05902
     - CA, 05903
     - CA, 05904
     - CA, 05905
     - CA, 05906
     - CA, 05907
     - CA, 05908
     - CA, 05909
     - CA, 05910
     - CA, 05911
     - CA, 05912
     - CA, 05913
     - CA, 05914
     - CA, 05915
     - CA, 05916
     - CA, 05917
     - CA, 05918
     - CA, 06101
     - CA, 06102
     - CA, 06103
     - CA, 06501
     - CA, 06502
     - CA, 06503
     - CA, 06504
     - CA, 06505
     - CA, 06506
     - CA, 06507
     - CA, 06508
     - CA, 06509
     - CA, 06510
     - CA, 06511
     - CA, 06512
     - CA, 06513
     - CA, 06514
     - CA, 06515
     - CA, 06701
     - CA, 06702
     - CA, 06703
     - CA, 06704
     - CA, 06705
     - CA, 06706
     - CA, 06707
     - CA, 06708
     - CA, 06709
     - CA, 06710
     - CA, 06711
     - CA, 06712
     - CA, 07101
     - CA, 07102
     - CA, 07103
     - CA, 07104
     - CA, 07105
     - CA, 07106
     - CA, 07107
     - CA, 07108
     - CA, 07109
     - CA, 07110
     - CA, 07111
     - CA, 07112
     - CA, 07113
     - CA, 07114
     - CA, 07115
     - CA, 07301
     - CA, 07302
     - CA, 07303
     - CA, 07304
     - CA, 07305
     - CA, 07306
     - CA, 07307
     - CA, 07308
     - CA, 07309
     - CA, 07310
     - CA, 07311
     - CA, 07312
     - CA, 07313
     - CA, 07314
     - CA, 07315
     - CA, 07316
     - CA, 07317
     - CA, 07318
     - CA, 07319
     - CA, 07320
     - CA, 07321
     - CA, 07322
     - CA, 07501
     - CA, 07502
     - CA, 07503
     - CA, 07504
     - CA, 07505
     - CA, 07506
     - CA, 07507
     - CA, 07701
     - CA, 07702
     - CA, 07703
     - CA, 07704
     - CA, 07901
     - CA, 07902
     - CA, 08101
     - CA, 08102
     - CA, 08103
     - CA, 08104
     - CA, 08105
     - CA, 08106
     - CA, 08301
     - CA, 08302
     - CA, 08303
     - CA, 08501
     - CA, 08502
     - CA, 08503
     - CA, 08504
     - CA, 08505
     - CA, 08506
     - CA, 08507
     - CA, 08508
     - CA, 08509
     - CA, 08510
     - CA, 08511
     - CA, 08512
     - CA, 08513
     - CA, 08514
     - CA, 08701
     - CA, 08702
     - CA, 08900
     - CA, 09501
     - CA, 09502
     - CA, 09503
     - CA, 09701
     - CA, 09702
     - CA, 09703
     - CA, 09901
     - CA, 09902
     - CA, 09903
     - CA, 09904
     - CA, 10100
     - CA, 10701
     - CA, 10702
     - CA, 10703
     - CA, 11101
     - CA, 11102
     - CA, 11103
     - CA, 11104
     - CA, 11105
     - CA, 11106
     - CA, 11300
     - CO, 00100
     - CO, 00102
     - CO, 00103
     - CO, 00200
     - CO, 00300
     - CO, 00400
     - CO, 00600
     - CO, 00700
     - CO, 00800
     - CO, 00801
     - CO, 00802
     - CO, 00803
     - CO, 00804
     - CO, 00805
     - CO, 00806
     - CO, 00807
     - CO, 00808
     - CO, 00809
     - CO, 00810
     - CO, 00811
     - CO, 00812
     - CO, 00813
     - CO, 00814
     - CO, 00815
     - CO, 00816
     - CO, 00817
     - CO, 00818
     - CO, 00819
     - CO, 00820
     - CO, 00821
     - CO, 00822
     - CO, 00823
     - CO, 00824
     - CO, 00900
     - CO, 01001
     - CO, 01002
     - CO, 04101
     - CO, 04102
     - CO, 04103
     - CO, 04104
     - CO, 04105
     - CO, 04106
     - CT, 00100
     - CT, 00101
     - CT, 00102
     - CT, 00103
     - CT, 00104
     - CT, 00105
     - CT, 00300
     - CT, 00301
     - CT, 00302
     - CT, 00303
     - CT, 00304
     - CT, 00305
     - CT, 00306
     - CT, 00500
     - CT, 00700
     - CT, 00900
     - CT, 00901
     - CT, 00902
     - CT, 00903
     - CT, 00904
     - CT, 00905
     - CT, 00906
     - CT, 01100
     - CT, 01101
     - CT, 01300
     - CT, 01500
     - DC, 00101
     - DC, 00102
     - DC, 00103
     - DC, 00104
     - DC, 00105
     - DE, 00101
     - DE, 00102
     - DE, 00103
     - DE, 00104
     - DE, 00200
     - DE, 00300
     - FL, 00101
     - FL, 00102
     - FL, 00500
     - FL, 00901
     - FL, 00902
     - FL, 00903
     - FL, 00904
     - FL, 01101
     - FL, 01102
     - FL, 01103
     - FL, 01104
     - FL, 01105
     - FL, 01106
     - FL, 01107
     - FL, 01108
     - FL, 01109
     - FL, 01110
     - FL, 01111
     - FL, 01112
     - FL, 01113
     - FL, 01114
     - FL, 01500
     - FL, 01701
     - FL, 01900
     - FL, 02101
     - FL, 02102
     - FL, 02103
     - FL, 02300
     - FL, 02700
     - FL, 03101
     - FL, 03102
     - FL, 03103
     - FL, 03104
     - FL, 03105
     - FL, 03106
     - FL, 03107
     - FL, 03301
     - FL, 03302
     - FL, 03500
     - FL, 05301
     - FL, 05701
     - FL, 05702
     - FL, 05703
     - FL, 05704
     - FL, 05705
     - FL, 05706
     - FL, 05707
     - FL, 05708
     - FL, 06100
     - FL, 06300
     - FL, 06901
     - FL, 06902
     - FL, 06903
     - FL, 07101
     - FL, 07102
     - FL, 07103
     - FL, 07104
     - FL, 07105
     - FL, 07300
     - FL, 07301
     - FL, 08101
     - FL, 08102
     - FL, 08103
     - FL, 08301
     - FL, 08302
     - FL, 08303
     - FL, 08500
     - FL, 08601
     - FL, 08602
     - FL, 08603
     - FL, 08604
     - FL, 08605
     - FL, 08606
     - FL, 08607
     - FL, 08608
     - FL, 08609
     - FL, 08610
     - FL, 08611
     - FL, 08612
     - FL, 08613
     - FL, 08614
     - FL, 08615
     - FL, 08616
     - FL, 08617
     - FL, 08618
     - FL, 08619
     - FL, 08620
     - FL, 08621
     - FL, 08622
     - FL, 08623
     - FL, 08624
     - FL, 08700
     - FL, 08900
     - FL, 09100
     - FL, 09300
     - FL, 09501
     - FL, 09502
     - FL, 09503
     - FL, 09504
     - FL, 09505
     - FL, 09506
     - FL, 09507
     - FL, 09508
     - FL, 09509
     - FL, 09510
     - FL, 09701
     - FL, 09702
     - FL, 09901
     - FL, 09902
     - FL, 09903
     - FL, 09904
     - FL, 09905
     - FL, 09906
     - FL, 09907
     - FL, 09908
     - FL, 09909
     - FL, 09910
     - FL, 09911
     - FL, 10101
     - FL, 10102
     - FL, 10103
     - FL, 10104
     - FL, 10301
     - FL, 10302
     - FL, 10303
     - FL, 10304
     - FL, 10305
     - FL, 10306
     - FL, 10307
     - FL, 10308
     - FL, 10501
     - FL, 10502
     - FL, 10503
     - FL, 10504
     - FL, 10700
     - FL, 10900
     - FL, 11101
     - FL, 11102
     - FL, 11300
     - FL, 11501
     - FL, 11502
     - FL, 11503
     - FL, 11701
     - FL, 11702
     - FL, 11703
     - FL, 11704
     - FL, 12100
     - FL, 12701
     - FL, 12702
     - FL, 12703
     - FL, 12704
     - GA, 00100
     - GA, 00200
     - GA, 00300
     - GA, 00401
     - GA, 00402
     - GA, 00500
     - GA, 00600
     - GA, 00700
     - GA, 00800
     - GA, 00900
     - GA, 01001
     - GA, 01002
     - GA, 01003
     - GA, 01004
     - GA, 01005
     - GA, 01006
     - GA, 01007
     - GA, 01008
     - GA, 01100
     - GA, 01200
     - GA, 01300
     - GA, 01400
     - GA, 01500
     - GA, 01600
     - GA, 01700
     - GA, 01800
     - GA, 01900
     - GA, 02001
     - GA, 02002
     - GA, 02003
     - GA, 02004
     - GA, 02100
     - GA, 02200
     - GA, 02300
     - GA, 02400
     - GA, 02500
     - GA, 02600
     - GA, 02700
     - GA, 02800
     - GA, 02900
     - GA, 03001
     - GA, 03002
     - GA, 03003
     - GA, 03004
     - GA, 03005
     - GA, 03101
     - GA, 03102
     - GA, 03200
     - GA, 03300
     - GA, 03400
     - GA, 03500
     - GA, 03600
     - GA, 03700
     - GA, 03800
     - GA, 03900
     - GA, 04000
     - GA, 04001
     - GA, 04002
     - GA, 04003
     - GA, 04004
     - GA, 04005
     - GA, 04006
     - GA, 04100
     - GA, 04200
     - GA, 04300
     - GA, 04400
     - GA, 04500
     - GA, 04600
     - GA, 05001
     - GA, 05002
     - GA, 06001
     - GA, 06002
     - HI, 00100
     - HI, 00200
     - HI, 00301
     - HI, 00302
     - HI, 00303
     - HI, 00304
     - HI, 00305
     - HI, 00306
     - HI, 00307
     - HI, 00308
     - IA, 00100
     - IA, 00200
     - IA, 00400
     - IA, 00500
     - IA, 00600
     - IA, 00700
     - IA, 00800
     - IA, 00900
     - IA, 01000
     - IA, 01100
     - IA, 01200
     - IA, 01300
     - IA, 01400
     - IA, 01500
     - IA, 01600
     - IA, 01700
     - IA, 01800
     - IA, 01900
     - IA, 02000
     - IA, 02100
     - IA, 02200
     - IA, 02300
     - ID, 00100
     - ID, 00200
     - ID, 00300
     - ID, 00400
     - ID, 00500
     - ID, 00600
     - ID, 00701
     - ID, 00702
     - ID, 00800
     - ID, 00900
     - ID, 01000
     - ID, 01100
     - ID, 01200
     - ID, 01300
     - IL, 00104
     - IL, 00105
     - IL, 00202
     - IL, 00300
     - IL, 00401
     - IL, 00501
     - IL, 00600
     - IL, 00700
     - IL, 00800
     - IL, 00900
     - IL, 01001
     - IL, 01104
     - IL, 01105
     - IL, 01204
     - IL, 01205
     - IL, 01300
     - IL, 01500
     - IL, 01602
     - IL, 01701
     - IL, 01900
     - IL, 02000
     - IL, 02100
     - IL, 02200
     - IL, 02300
     - IL, 02400
     - IL, 02501
     - IL, 02601
     - IL, 02700
     - IL, 02801
     - IL, 02901
     - IL, 03005
     - IL, 03007
     - IL, 03008
     - IL, 03009
     - IL, 03102
     - IL, 03105
     - IL, 03106
     - IL, 03107
     - IL, 03108
     - IL, 03202
     - IL, 03203
     - IL, 03204
     - IL, 03205
     - IL, 03207
     - IL, 03208
     - IL, 03209
     - IL, 03306
     - IL, 03307
     - IL, 03308
     - IL, 03309
     - IL, 03310
     - IL, 03401
     - IL, 03407
     - IL, 03408
     - IL, 03409
     - IL, 03410
     - IL, 03411
     - IL, 03412
     - IL, 03413
     - IL, 03414
     - IL, 03415
     - IL, 03416
     - IL, 03417
     - IL, 03418
     - IL, 03419
     - IL, 03420
     - IL, 03421
     - IL, 03422
     - IL, 03501
     - IL, 03502
     - IL, 03503
     - IL, 03504
     - IL, 03520
     - IL, 03521
     - IL, 03522
     - IL, 03523
     - IL, 03524
     - IL, 03525
     - IL, 03526
     - IL, 03527
     - IL, 03528
     - IL, 03529
     - IL, 03530
     - IL, 03531
     - IL, 03532
     - IL, 03601
     - IL, 03602
     - IL, 03700
     - IN, 00101
     - IN, 00102
     - IN, 00103
     - IN, 00104
     - IN, 00200
     - IN, 00300
     - IN, 00401
     - IN, 00402
     - IN, 00500
     - IN, 00600
     - IN, 00700
     - IN, 00800
     - IN, 00900
     - IN, 01001
     - IN, 01002
     - IN, 01003
     - IN, 01100
     - IN, 01200
     - IN, 01300
     - IN, 01400
     - IN, 01500
     - IN, 01600
     - IN, 01700
     - IN, 01801
     - IN, 01802
     - IN, 01803
     - IN, 01900
     - IN, 02000
     - IN, 02100
     - IN, 02200
     - IN, 02301
     - IN, 02302
     - IN, 02303
     - IN, 02304
     - IN, 02305
     - IN, 02306
     - IN, 02307
     - IN, 02400
     - IN, 02500
     - IN, 02600
     - IN, 02700
     - IN, 02800
     - IN, 02900
     - IN, 03000
     - IN, 03100
     - IN, 03200
     - IN, 03300
     - IN, 03400
     - IN, 03500
     - IN, 03600
     - KS, 00100
     - KS, 00200
     - KS, 00300
     - KS, 00400
     - KS, 00500
     - KS, 00601
     - KS, 00602
     - KS, 00603
     - KS, 00604
     - KS, 00700
     - KS, 00801
     - KS, 00802
     - KS, 00900
     - KS, 01000
     - KS, 01100
     - KS, 01200
     - KS, 01301
     - KS, 01302
     - KS, 01303
     - KS, 01304
     - KS, 01400
     - KS, 01500
     - KY, 00100
     - KY, 00200
     - KY, 00300
     - KY, 00400
     - KY, 00500
     - KY, 00600
     - KY, 00700
     - KY, 00800
     - KY, 00900
     - KY, 01000
     - KY, 01100
     - KY, 01200
     - KY, 01300
     - KY, 01400
     - KY, 01500
     - KY, 01600
     - KY, 01701
     - KY, 01702
     - KY, 01703
     - KY, 01704
     - KY, 01705
     - KY, 01706
     - KY, 01800
     - KY, 01901
     - KY, 01902
     - KY, 02000
     - KY, 02100
     - KY, 02200
     - KY, 02300
     - KY, 02400
     - KY, 02500
     - KY, 02600
     - KY, 02700
     - KY, 02800
     - LA, 00100
     - LA, 00101
     - LA, 00200
     - LA, 00300
     - LA, 00400
     - LA, 00500
     - LA, 00600
     - LA, 00700
     - LA, 00800
     - LA, 00900
     - LA, 01000
     - LA, 01100
     - LA, 01200
     - LA, 01201
     - LA, 01300
     - LA, 01400
     - LA, 01500
     - LA, 01501
     - LA, 01502
     - LA, 01600
     - LA, 01700
     - LA, 01800
     - LA, 01900
     - LA, 02000
     - LA, 02100
     - LA, 02200
     - LA, 02201
     - LA, 02300
     - LA, 02301
     - LA, 02302
     - LA, 02400
     - LA, 02401
     - LA, 02402
     - LA, 02500
     - MA, 00100
     - MA, 00200
     - MA, 00300
     - MA, 00301
     - MA, 00302
     - MA, 00303
     - MA, 00304
     - MA, 00400
     - MA, 00501
     - MA, 00502
     - MA, 00503
     - MA, 00504
     - MA, 00505
     - MA, 00506
     - MA, 00507
     - MA, 00508
     - MA, 00701
     - MA, 00702
     - MA, 00703
     - MA, 00704
     - MA, 01000
     - MA, 01300
     - MA, 01400
     - MA, 01600
     - MA, 01900
     - MA, 01901
     - MA, 01902
     - MA, 02400
     - MA, 02800
     - MA, 03301
     - MA, 03302
     - MA, 03303
     - MA, 03304
     - MA, 03305
     - MA, 03306
     - MA, 03400
     - MA, 03500
     - MA, 03601
     - MA, 03602
     - MA, 03603
     - MA, 03900
     - MA, 04000
     - MA, 04200
     - MA, 04301
     - MA, 04302
     - MA, 04303
     - MA, 04500
     - MA, 04700
     - MA, 04800
     - MA, 04901
     - MA, 04902
     - MA, 04903
     - MD, 00100
     - MD, 00200
     - MD, 00301
     - MD, 00302
     - MD, 00400
     - MD, 00501
     - MD, 00502
     - MD, 00503
     - MD, 00504
     - MD, 00505
     - MD, 00506
     - MD, 00507
     - MD, 00601
     - MD, 00602
     - MD, 00700
     - MD, 00801
     - MD, 00802
     - MD, 00803
     - MD, 00804
     - MD, 00805
     - MD, 00901
     - MD, 00902
     - MD, 01001
     - MD, 01002
     - MD, 01003
     - MD, 01004
     - MD, 01005
     - MD, 01006
     - MD, 01007
     - MD, 01101
     - MD, 01102
     - MD, 01103
     - MD, 01104
     - MD, 01105
     - MD, 01106
     - MD, 01107
     - MD, 01201
     - MD, 01202
     - MD, 01203
     - MD, 01204
     - MD, 01300
     - MD, 01400
     - MD, 01500
     - MD, 01600
     - ME, 00100
     - ME, 00200
     - ME, 00300
     - ME, 00400
     - ME, 00500
     - ME, 00600
     - ME, 00700
     - ME, 00800
     - ME, 00900
     - ME, 01000
     - MI, 00100
     - MI, 00200
     - MI, 00300
     - MI, 00400
     - MI, 00500
     - MI, 00600
     - MI, 00700
     - MI, 00801
     - MI, 00802
     - MI, 00900
     - MI, 01001
     - MI, 01002
     - MI, 01003
     - MI, 01004
     - MI, 01100
     - MI, 01200
     - MI, 01300
     - MI, 01400
     - MI, 01500
     - MI, 01600
     - MI, 01701
     - MI, 01702
     - MI, 01703
     - MI, 01704
     - MI, 01801
     - MI, 01802
     - MI, 01900
     - MI, 02000
     - MI, 02101
     - MI, 02102
     - MI, 02200
     - MI, 02300
     - MI, 02400
     - MI, 02500
     - MI, 02600
     - MI, 02701
     - MI, 02702
     - MI, 02703
     - MI, 02800
     - MI, 02901
     - MI, 02902
     - MI, 02903
     - MI, 02904
     - MI, 02905
     - MI, 02906
     - MI, 02907
     - MI, 02908
     - MI, 03001
     - MI, 03002
     - MI, 03003
     - MI, 03004
     - MI, 03005
     - MI, 03006
     - MI, 03100
     - MI, 03201
     - MI, 03202
     - MI, 03203
     - MI, 03204
     - MI, 03205
     - MI, 03206
     - MI, 03207
     - MI, 03208
     - MI, 03209
     - MI, 03210
     - MI, 03211
     - MI, 03212
     - MI, 03213
     - MI, 03300
     - MN, 00100
     - MN, 00200
     - MN, 00300
     - MN, 00400
     - MN, 00500
     - MN, 00600
     - MN, 00700
     - MN, 00800
     - MN, 00900
     - MN, 01000
     - MN, 01101
     - MN, 01102
     - MN, 01103
     - MN, 01201
     - MN, 01202
     - MN, 01301
     - MN, 01302
     - MN, 01303
     - MN, 01304
     - MN, 01401
     - MN, 01402
     - MN, 01403
     - MN, 01404
     - MN, 01405
     - MN, 01406
     - MN, 01407
     - MN, 01408
     - MN, 01409
     - MN, 01410
     - MN, 01501
     - MN, 01502
     - MN, 01503
     - MN, 01600
     - MN, 01700
     - MN, 01800
     - MN, 01900
     - MN, 02000
     - MN, 02100
     - MN, 02200
     - MN, 02300
     - MN, 02400
     - MN, 02500
     - MN, 02600
     - MO, 00100
     - MO, 00200
     - MO, 00300
     - MO, 00400
     - MO, 00500
     - MO, 00600
     - MO, 00700
     - MO, 00800
     - MO, 00901
     - MO, 00902
     - MO, 00903
     - MO, 01001
     - MO, 01002
     - MO, 01003
     - MO, 01004
     - MO, 01005
     - MO, 01100
     - MO, 01200
     - MO, 01300
     - MO, 01400
     - MO, 01500
     - MO, 01600
     - MO, 01701
     - MO, 01702
     - MO, 01703
     - MO, 01801
     - MO, 01802
     - MO, 01803
     - MO, 01804
     - MO, 01805
     - MO, 01806
     - MO, 01807
     - MO, 01808
     - MO, 01901
     - MO, 01902
     - MO, 02001
     - MO, 02002
     - MO, 02100
     - MO, 02200
     - MO, 02300
     - MO, 02400
     - MO, 02500
     - MO, 02601
     - MO, 02602
     - MO, 02603
     - MO, 02700
     - MO, 02800
     - MS, 00100
     - MS, 00200
     - MS, 00300
     - MS, 00400
     - MS, 00500
     - MS, 00600
     - MS, 00700
     - MS, 00800
     - MS, 00900
     - MS, 01000
     - MS, 01100
     - MS, 01200
     - MS, 01300
     - MS, 01400
     - MS, 01500
     - MS, 01600
     - MS, 01700
     - MS, 01800
     - MS, 01900
     - MS, 02000
     - MS, 02100
     - MT, 00100
     - MT, 00200
     - MT, 00300
     - MT, 00400
     - MT, 00500
     - MT, 00600
     - MT, 00700
     - NC, 00100
     - NC, 00200
     - NC, 00300
     - NC, 00400
     - NC, 00500
     - NC, 00600
     - NC, 00700
     - NC, 00800
     - NC, 00900
     - NC, 01000
     - NC, 01100
     - NC, 01201
     - NC, 01202
     - NC, 01203
     - NC, 01204
     - NC, 01205
     - NC, 01206
     - NC, 01207
     - NC, 01208
     - NC, 01301
     - NC, 01302
     - NC, 01400
     - NC, 01500
     - NC, 01600
     - NC, 01701
     - NC, 01702
     - NC, 01703
     - NC, 01704
     - NC, 01801
     - NC, 01802
     - NC, 01803
     - NC, 01900
     - NC, 02000
     - NC, 02100
     - NC, 02201
     - NC, 02202
     - NC, 02300
     - NC, 02400
     - NC, 02500
     - NC, 02600
     - NC, 02700
     - NC, 02800
     - NC, 02900
     - NC, 03001
     - NC, 03002
     - NC, 03101
     - NC, 03102
     - NC, 03103
     - NC, 03104
     - NC, 03105
     - NC, 03106
     - NC, 03107
     - NC, 03108
     - NC, 03200
     - NC, 03300
     - NC, 03400
     - NC, 03500
     - NC, 03600
     - NC, 03700
     - NC, 03800
     - NC, 03900
     - NC, 04000
     - NC, 04100
     - NC, 04200
     - NC, 04300
     - NC, 04400
     - NC, 04500
     - NC, 04600
     - NC, 04700
     - NC, 04800
     - NC, 04900
     - NC, 05001
     - NC, 05002
     - NC, 05003
     - NC, 05100
     - NC, 05200
     - NC, 05300
     - NC, 05400
     - ND, 00100
     - ND, 00200
     - ND, 00300
     - ND, 00400
     - ND, 00500
     - NE, 00100
     - NE, 00200
     - NE, 00300
     - NE, 00400
     - NE, 00500
     - NE, 00600
     - NE, 00701
     - NE, 00702
     - NE, 00801
     - NE, 00802
     - NE, 00901
     - NE, 00902
     - NE, 00903
     - NE, 00904
     - NH, 00100
     - NH, 00200
     - NH, 00300
     - NH, 00400
     - NH, 00500
     - NH, 00600
     - NH, 00700
     - NH, 00800
     - NH, 00900
     - NH, 01000
     - NJ, 00101
     - NJ, 00102
     - NJ, 00301
     - NJ, 00302
     - NJ, 00303
     - NJ, 00304
     - NJ, 00305
     - NJ, 00306
     - NJ, 00307
     - NJ, 00308
     - NJ, 00400
     - NJ, 00501
     - NJ, 00502
     - NJ, 00503
     - NJ, 00601
     - NJ, 00602
     - NJ, 00701
     - NJ, 00702
     - NJ, 00703
     - NJ, 00800
     - NJ, 00901
     - NJ, 00902
     - NJ, 00903
     - NJ, 00904
     - NJ, 00905
     - NJ, 00906
     - NJ, 00907
     - NJ, 01001
     - NJ, 01002
     - NJ, 01003
     - NJ, 01101
     - NJ, 01102
     - NJ, 01103
     - NJ, 01104
     - NJ, 01105
     - NJ, 01106
     - NJ, 01201
     - NJ, 01202
     - NJ, 01203
     - NJ, 01204
     - NJ, 01205
     - NJ, 01301
     - NJ, 01302
     - NJ, 01401
     - NJ, 01402
     - NJ, 01403
     - NJ, 01404
     - NJ, 01501
     - NJ, 01502
     - NJ, 01503
     - NJ, 01504
     - NJ, 01600
     - NJ, 01700
     - NJ, 01800
     - NJ, 01901
     - NJ, 01902
     - NJ, 01903
     - NJ, 01904
     - NJ, 02001
     - NJ, 02002
     - NJ, 02003
     - NJ, 02101
     - NJ, 02102
     - NJ, 02103
     - NJ, 02104
     - NJ, 02201
     - NJ, 02202
     - NJ, 02301
     - NJ, 02302
     - NJ, 02303
     - NJ, 02400
     - NJ, 02500
     - NJ, 02600
     - NM, 00100
     - NM, 00200
     - NM, 00300
     - NM, 00400
     - NM, 00500
     - NM, 00600
     - NM, 00700
     - NM, 00801
     - NM, 00802
     - NM, 00803
     - NM, 00804
     - NM, 00805
     - NM, 00806
     - NM, 00900
     - NM, 01001
     - NM, 01002
     - NM, 01100
     - NM, 01200
     - NV, 00101
     - NV, 00102
     - NV, 00103
     - NV, 00200
     - NV, 00300
     - NV, 00401
     - NV, 00402
     - NV, 00403
     - NV, 00404
     - NV, 00405
     - NV, 00406
     - NV, 00407
     - NV, 00408
     - NV, 00409
     - NV, 00410
     - NV, 00411
     - NV, 00412
     - NV, 00413
     - NY, 00100
     - NY, 00200
     - NY, 00300
     - NY, 00401
     - NY, 00402
     - NY, 00403
     - NY, 00500
     - NY, 00600
     - NY, 00701
     - NY, 00702
     - NY, 00703
     - NY, 00704
     - NY, 00800
     - NY, 00901
     - NY, 00902
     - NY, 00903
     - NY, 00904
     - NY, 00905
     - NY, 00906
     - NY, 01000
     - NY, 01101
     - NY, 01102
     - NY, 01201
     - NY, 01202
     - NY, 01203
     - NY, 01204
     - NY, 01205
     - NY, 01206
     - NY, 01207
     - NY, 01300
     - NY, 01400
     - NY, 01500
     - NY, 01600
     - NY, 01700
     - NY, 01801
     - NY, 01802
     - NY, 01900
     - NY, 02001
     - NY, 02002
     - NY, 02100
     - NY, 02201
     - NY, 02202
     - NY, 02203
     - NY, 02300
     - NY, 02401
     - NY, 02402
     - NY, 02500
     - NY, 02600
     - NY, 02701
     - NY, 02702
     - NY, 02801
     - NY, 02802
     - NY, 02901
     - NY, 02902
     - NY, 02903
     - NY, 03001
     - NY, 03002
     - NY, 03003
     - NY, 03101
     - NY, 03102
     - NY, 03103
     - NY, 03104
     - NY, 03105
     - NY, 03106
     - NY, 03107
     - NY, 03201
     - NY, 03202
     - NY, 03203
     - NY, 03204
     - NY, 03205
     - NY, 03206
     - NY, 03207
     - NY, 03208
     - NY, 03209
     - NY, 03210
     - NY, 03211
     - NY, 03212
     - NY, 03301
     - NY, 03302
     - NY, 03303
     - NY, 03304
     - NY, 03305
     - NY, 03306
     - NY, 03307
     - NY, 03308
     - NY, 03309
     - NY, 03310
     - NY, 03311
     - NY, 03312
     - NY, 03313
     - NY, 03701
     - NY, 03702
     - NY, 03703
     - NY, 03704
     - NY, 03705
     - NY, 03706
     - NY, 03707
     - NY, 03708
     - NY, 03709
     - NY, 03710
     - NY, 03801
     - NY, 03802
     - NY, 03803
     - NY, 03804
     - NY, 03805
     - NY, 03806
     - NY, 03807
     - NY, 03808
     - NY, 03809
     - NY, 03810
     - NY, 03901
     - NY, 03902
     - NY, 03903
     - NY, 04001
     - NY, 04002
     - NY, 04003
     - NY, 04004
     - NY, 04005
     - NY, 04006
     - NY, 04007
     - NY, 04008
     - NY, 04009
     - NY, 04010
     - NY, 04011
     - NY, 04012
     - NY, 04013
     - NY, 04014
     - NY, 04015
     - NY, 04016
     - NY, 04017
     - NY, 04018
     - NY, 04101
     - NY, 04102
     - NY, 04103
     - NY, 04104
     - NY, 04105
     - NY, 04106
     - NY, 04107
     - NY, 04108
     - NY, 04109
     - NY, 04110
     - NY, 04111
     - NY, 04112
     - NY, 04113
     - NY, 04114
     - OH, 00100
     - OH, 00200
     - OH, 00300
     - OH, 00400
     - OH, 00500
     - OH, 00600
     - OH, 00700
     - OH, 00801
     - OH, 00802
     - OH, 00901
     - OH, 00902
     - OH, 00903
     - OH, 00904
     - OH, 00905
     - OH, 00906
     - OH, 00907
     - OH, 00908
     - OH, 00909
     - OH, 00910
     - OH, 01000
     - OH, 01100
     - OH, 01200
     - OH, 01300
     - OH, 01400
     - OH, 01500
     - OH, 01600
     - OH, 01700
     - OH, 01801
     - OH, 01802
     - OH, 01803
     - OH, 01804
     - OH, 01805
     - OH, 01900
     - OH, 02000
     - OH, 02100
     - OH, 02200
     - OH, 02300
     - OH, 02400
     - OH, 02500
     - OH, 02600
     - OH, 02700
     - OH, 02800
     - OH, 02900
     - OH, 03000
     - OH, 03100
     - OH, 03200
     - OH, 03300
     - OH, 03400
     - OH, 03500
     - OH, 03600
     - OH, 03700
     - OH, 03800
     - OH, 03900
     - OH, 04000
     - OH, 04101
     - OH, 04102
     - OH, 04103
     - OH, 04104
     - OH, 04105
     - OH, 04106
     - OH, 04107
     - OH, 04108
     - OH, 04109
     - OH, 04110
     - OH, 04111
     - OH, 04200
     - OH, 04300
     - OH, 04400
     - OH, 04500
     - OH, 04601
     - OH, 04602
     - OH, 04603
     - OH, 04604
     - OH, 04700
     - OH, 04800
     - OH, 04900
     - OH, 05000
     - OH, 05100
     - OH, 05200
     - OH, 05301
     - OH, 05302
     - OH, 05401
     - OH, 05402
     - OH, 05403
     - OH, 05501
     - OH, 05502
     - OH, 05503
     - OH, 05504
     - OH, 05505
     - OH, 05506
     - OH, 05507
     - OH, 05600
     - OH, 05700
     - OK, 00100
     - OK, 00200
     - OK, 00300
     - OK, 00400
     - OK, 00500
     - OK, 00601
     - OK, 00602
     - OK, 00701
     - OK, 00702
     - OK, 00800
     - OK, 00900
     - OK, 01001
     - OK, 01002
     - OK, 01003
     - OK, 01004
     - OK, 01005
     - OK, 01006
     - OK, 01101
     - OK, 01102
     - OK, 01201
     - OK, 01202
     - OK, 01203
     - OK, 01204
     - OK, 01301
     - OK, 01302
     - OK, 01400
     - OK, 01501
     - OK, 01601
     - OR, 00100
     - OR, 00200
     - OR, 00300
     - OR, 00400
     - OR, 00500
     - OR, 00600
     - OR, 00703
     - OR, 00704
     - OR, 00705
     - OR, 00800
     - OR, 00901
     - OR, 00902
     - OR, 01000
     - OR, 01103
     - OR, 01104
     - OR, 01105
     - OR, 01200
     - OR, 01301
     - OR, 01302
     - OR, 01303
     - OR, 01305
     - OR, 01314
     - OR, 01316
     - OR, 01317
     - OR, 01318
     - OR, 01319
     - OR, 01320
     - OR, 01321
     - OR, 01322
     - OR, 01323
     - OR, 01324
     - PA, 00101
     - PA, 00102
     - PA, 00200
     - PA, 00300
     - PA, 00400
     - PA, 00500
     - PA, 00600
     - PA, 00701
     - PA, 00702
     - PA, 00801
     - PA, 00802
     - PA, 00803
     - PA, 00900
     - PA, 01000
     - PA, 01100
     - PA, 01200
     - PA, 01300
     - PA, 01400
     - PA, 01501
     - PA, 01502
     - PA, 01600
     - PA, 01701
     - PA, 01702
     - PA, 01801
     - PA, 01802
     - PA, 01803
     - PA, 01804
     - PA, 01805
     - PA, 01806
     - PA, 01807
     - PA, 01900
     - PA, 02001
     - PA, 02002
     - PA, 02003
     - PA, 02100
     - PA, 02200
     - PA, 02301
     - PA, 02302
     - PA, 02401
     - PA, 02402
     - PA, 02500
     - PA, 02600
     - PA, 02701
     - PA, 02702
     - PA, 02703
     - PA, 02801
     - PA, 02802
     - PA, 02803
     - PA, 02901
     - PA, 02902
     - PA, 03001
     - PA, 03002
     - PA, 03003
     - PA, 03004
     - PA, 03101
     - PA, 03102
     - PA, 03103
     - PA, 03104
     - PA, 03105
     - PA, 03106
     - PA, 03201
     - PA, 03202
     - PA, 03203
     - PA, 03204
     - PA, 03205
     - PA, 03206
     - PA, 03207
     - PA, 03208
     - PA, 03209
     - PA, 03210
     - PA, 03211
     - PA, 03301
     - PA, 03302
     - PA, 03303
     - PA, 03304
     - PA, 03401
     - PA, 03402
     - PA, 03403
     - PA, 03404
     - PA, 03501
     - PA, 03502
     - PA, 03503
     - PA, 03504
     - PA, 03601
     - PA, 03602
     - PA, 03603
     - PA, 03701
     - PA, 03702
     - PA, 03800
     - PA, 03900
     - PA, 04001
     - PA, 04002
     - RI, 00101
     - RI, 00102
     - RI, 00103
     - RI, 00104
     - RI, 00201
     - RI, 00300
     - RI, 00400
     - SC, 00101
     - SC, 00102
     - SC, 00103
     - SC, 00104
     - SC, 00105
     - SC, 00200
     - SC, 00301
     - SC, 00302
     - SC, 00400
     - SC, 00501
     - SC, 00502
     - SC, 00601
     - SC, 00602
     - SC, 00603
     - SC, 00604
     - SC, 00605
     - SC, 00700
     - SC, 00800
     - SC, 00900
     - SC, 01000
     - SC, 01101
     - SC, 01102
     - SC, 01201
     - SC, 01202
     - SC, 01203
     - SC, 01204
     - SC, 01300
     - SC, 01400
     - SC, 01500
     - SC, 01600
     - SD, 00100
     - SD, 00200
     - SD, 00300
     - SD, 00400
     - SD, 00500
     - SD, 00600
     - TN, 00100
     - TN, 00200
     - TN, 00300
     - TN, 00400
     - TN, 00500
     - TN, 00600
     - TN, 00700
     - TN, 00800
     - TN, 00900
     - TN, 01000
     - TN, 01100
     - TN, 01200
     - TN, 01300
     - TN, 01400
     - TN, 01500
     - TN, 01601
     - TN, 01602
     - TN, 01603
     - TN, 01604
     - TN, 01700
     - TN, 01800
     - TN, 01900
     - TN, 02001
     - TN, 02002
     - TN, 02003
     - TN, 02100
     - TN, 02200
     - TN, 02300
     - TN, 02401
     - TN, 02402
     - TN, 02501
     - TN, 02502
     - TN, 02503
     - TN, 02504
     - TN, 02505
     - TN, 02600
     - TN, 02700
     - TN, 02800
     - TN, 02900
     - TN, 03000
     - TN, 03100
     - TN, 03201
     - TN, 03202
     - TN, 03203
     - TN, 03204
     - TN, 03205
     - TN, 03206
     - TN, 03207
     - TN, 03208
     - TX, 00100
     - TX, 00200
     - TX, 00300
     - TX, 00400
     - TX, 00501
     - TX, 00502
     - TX, 00600
     - TX, 00700
     - TX, 00800
     - TX, 00900
     - TX, 01000
     - TX, 01100
     - TX, 01200
     - TX, 01300
     - TX, 01400
     - TX, 01501
     - TX, 01502
     - TX, 01600
     - TX, 01700
     - TX, 01800
     - TX, 01901
     - TX, 01902
     - TX, 01903
     - TX, 01904
     - TX, 01905
     - TX, 01906
     - TX, 01907
     - TX, 02001
     - TX, 02002
     - TX, 02003
     - TX, 02004
     - TX, 02005
     - TX, 02006
     - TX, 02101
     - TX, 02102
     - TX, 02200
     - TX, 02301
     - TX, 02302
     - TX, 02303
     - TX, 02304
     - TX, 02305
     - TX, 02306
     - TX, 02307
     - TX, 02308
     - TX, 02309
     - TX, 02310
     - TX, 02311
     - TX, 02312
     - TX, 02313
     - TX, 02314
     - TX, 02315
     - TX, 02316
     - TX, 02317
     - TX, 02318
     - TX, 02319
     - TX, 02320
     - TX, 02321
     - TX, 02322
     - TX, 02400
     - TX, 02501
     - TX, 02502
     - TX, 02503
     - TX, 02504
     - TX, 02505
     - TX, 02506
     - TX, 02507
     - TX, 02508
     - TX, 02509
     - TX, 02510
     - TX, 02511
     - TX, 02512
     - TX, 02513
     - TX, 02514
     - TX, 02515
     - TX, 02516
     - TX, 02600
     - TX, 02700
     - TX, 02800
     - TX, 02900
     - TX, 03000
     - TX, 03100
     - TX, 03200
     - TX, 03301
     - TX, 03302
     - TX, 03303
     - TX, 03304
     - TX, 03305
     - TX, 03306
     - TX, 03400
     - TX, 03501
     - TX, 03502
     - TX, 03601
     - TX, 03602
     - TX, 03700
     - TX, 03801
     - TX, 03802
     - TX, 03900
     - TX, 04000
     - TX, 04100
     - TX, 04200
     - TX, 04301
     - TX, 04302
     - TX, 04400
     - TX, 04501
     - TX, 04502
     - TX, 04503
     - TX, 04504
     - TX, 04601
     - TX, 04602
     - TX, 04603
     - TX, 04604
     - TX, 04605
     - TX, 04606
     - TX, 04607
     - TX, 04608
     - TX, 04609
     - TX, 04610
     - TX, 04611
     - TX, 04612
     - TX, 04613
     - TX, 04614
     - TX, 04615
     - TX, 04616
     - TX, 04617
     - TX, 04618
     - TX, 04619
     - TX, 04620
     - TX, 04621
     - TX, 04622
     - TX, 04623
     - TX, 04624
     - TX, 04625
     - TX, 04626
     - TX, 04627
     - TX, 04628
     - TX, 04629
     - TX, 04630
     - TX, 04631
     - TX, 04632
     - TX, 04633
     - TX, 04634
     - TX, 04635
     - TX, 04636
     - TX, 04637
     - TX, 04638
     - TX, 04701
     - TX, 04702
     - TX, 04801
     - TX, 04802
     - TX, 04803
     - TX, 04901
     - TX, 04902
     - TX, 04903
     - TX, 04904
     - TX, 04905
     - TX, 05000
     - TX, 05100
     - TX, 05201
     - TX, 05202
     - TX, 05203
     - TX, 05204
     - TX, 05301
     - TX, 05302
     - TX, 05303
     - TX, 05304
     - TX, 05305
     - TX, 05306
     - TX, 05307
     - TX, 05308
     - TX, 05309
     - TX, 05400
     - TX, 05500
     - TX, 05600
     - TX, 05700
     - TX, 05800
     - TX, 05901
     - TX, 05902
     - TX, 05903
     - TX, 05904
     - TX, 05905
     - TX, 05906
     - TX, 05907
     - TX, 05908
     - TX, 05909
     - TX, 05910
     - TX, 05911
     - TX, 05912
     - TX, 05913
     - TX, 05914
     - TX, 05915
     - TX, 05916
     - TX, 06000
     - TX, 06100
     - TX, 06200
     - TX, 06301
     - TX, 06302
     - TX, 06400
     - TX, 06500
     - TX, 06601
     - TX, 06602
     - TX, 06603
     - TX, 06701
     - TX, 06702
     - TX, 06703
     - TX, 06801
     - TX, 06802
     - TX, 06803
     - TX, 06804
     - TX, 06805
     - TX, 06806
     - TX, 06807
     - TX, 06900
     - UT, 03001
     - UT, 05001
     - UT, 11001
     - UT, 11002
     - UT, 13001
     - UT, 21001
     - UT, 35001
     - UT, 35002
     - UT, 35003
     - UT, 35004
     - UT, 35005
     - UT, 35006
     - UT, 35007
     - UT, 35008
     - UT, 35009
     - UT, 49001
     - UT, 49002
     - UT, 49003
     - UT, 49004
     - UT, 53001
     - UT, 57001
     - UT, 57002
     - VA, 01301
     - VA, 01302
     - VA, 04101
     - VA, 04102
     - VA, 04103
     - VA, 10701
     - VA, 10702
     - VA, 10703
     - VA, 51010
     - VA, 51020
     - VA, 51040
     - VA, 51044
     - VA, 51045
     - VA, 51080
     - VA, 51084
     - VA, 51085
     - VA, 51087
     - VA, 51089
     - VA, 51090
     - VA, 51095
     - VA, 51096
     - VA, 51097
     - VA, 51105
     - VA, 51110
     - VA, 51115
     - VA, 51120
     - VA, 51125
     - VA, 51135
     - VA, 51145
     - VA, 51154
     - VA, 51155
     - VA, 51164
     - VA, 51165
     - VA, 51167
     - VA, 51175
     - VA, 51186
     - VA, 51206
     - VA, 51215
     - VA, 51224
     - VA, 51225
     - VA, 51235
     - VA, 51244
     - VA, 51245
     - VA, 51246
     - VA, 51255
     - VA, 55001
     - VA, 55002
     - VA, 59301
     - VA, 59302
     - VA, 59303
     - VA, 59304
     - VA, 59305
     - VA, 59306
     - VA, 59307
     - VA, 59308
     - VA, 59309
     - VT, 00100
     - VT, 00200
     - VT, 00300
     - VT, 00400
     - WA, 10100
     - WA, 10200
     - WA, 10300
     - WA, 10400
     - WA, 10501
     - WA, 10502
     - WA, 10503
     - WA, 10504
     - WA, 10600
     - WA, 10701
     - WA, 10702
     - WA, 10703
     - WA, 10800
     - WA, 10901
     - WA, 10902
     - WA, 11000
     - WA, 11101
     - WA, 11102
     - WA, 11103
     - WA, 11104
     - WA, 11200
     - WA, 11300
     - WA, 11401
     - WA, 11402
     - WA, 11501
     - WA, 11502
     - WA, 11503
     - WA, 11504
     - WA, 11505
     - WA, 11506
     - WA, 11507
     - WA, 11601
     - WA, 11602
     - WA, 11603
     - WA, 11604
     - WA, 11605
     - WA, 11606
     - WA, 11607
     - WA, 11608
     - WA, 11609
     - WA, 11610
     - WA, 11611
     - WA, 11612
     - WA, 11613
     - WA, 11614
     - WA, 11615
     - WA, 11616
     - WA, 11701
     - WA, 11702
     - WA, 11703
     - WA, 11704
     - WA, 11705
     - WA, 11706
     - WA, 11801
     - WA, 11802
     - WA, 11900
     - WI, 00100
     - WI, 00101
     - WI, 00102
     - WI, 00103
     - WI, 00200
     - WI, 00300
     - WI, 00600
     - WI, 00700
     - WI, 00800
     - WI, 00900
     - WI, 01000
     - WI, 01001
     - WI, 01300
     - WI, 01301
     - WI, 01400
     - WI, 01401
     - WI, 01500
     - WI, 01501
     - WI, 01600
     - WI, 01601
     - WI, 02400
     - WI, 02500
     - WI, 10000
     - WI, 20000
     - WI, 30000
     - WI, 40101
     - WI, 40301
     - WI, 40701
     - WI, 41001
     - WI, 41002
     - WI, 41003
     - WI, 41004
     - WI, 41005
     - WI, 50000
     - WI, 55101
     - WI, 55102
     - WI, 55103
     - WI, 70101
     - WI, 70201
     - WI, 70301
     - WV, 00100
     - WV, 00200
     - WV, 00300
     - WV, 00400
     - WV, 00500
     - WV, 00600
     - WV, 00700
     - WV, 00800
     - WV, 00900
     - WV, 01000
     - WV, 01100
     - WV, 01200
     - WV, 01300
     - WY, 00100
     - WY, 00200
     - WY, 00300
     - WY, 00400
     - WY, 00500
   * - Stock saturation
     - 0.038%
     - 0.048%
     - 0.054%
     - 0.056%
     - 0.035%
     - 0.066%
     - 0.055%
     - 0.041%
     - 0.037%
     - 0.042%
     - 0.039%
     - 0.05%
     - 0.038%
     - 0.045%
     - 0.035%
     - 0.059%
     - 0.04%
     - 0.062%
     - 0.038%
     - 0.041%
     - 0.057%
     - 0.056%
     - 0.036%
     - 0.043%
     - 0.032%
     - 0.041%
     - 0.047%
     - 0.048%
     - 0.049%
     - 0.067%
     - 0.056%
     - 0.051%
     - 0.043%
     - 0.051%
     - 0.068%
     - 0.08%
     - 0.038%
     - 0.038%
     - 0.059%
     - 0.073%
     - 0.067%
     - 0.059%
     - 0.054%
     - 0.061%
     - 0.035%
     - 0.036%
     - 0.037%
     - 0.068%
     - 0.067%
     - 0.058%
     - 0.035%
     - 0.046%
     - 0.062%
     - 0.035%
     - 0.06%
     - 0.035%
     - 0.037%
     - 0.038%
     - 0.038%
     - 0.033%
     - 0.055%
     - 0.043%
     - 0.034%
     - 0.04%
     - 0.036%
     - 0.033%
     - 0.033%
     - 0.032%
     - 0.036%
     - 0.053%
     - 0.045%
     - 0.043%
     - 0.035%
     - 0.037%
     - 0.034%
     - 0.039%
     - 0.038%
     - 0.037%
     - 0.026%
     - 0.033%
     - 0.031%
     - 0.025%
     - 0.026%
     - 0.029%
     - 0.03%
     - 0.038%
     - 0.034%
     - 0.031%
     - 0.034%
     - 0.053%
     - 0.036%
     - 0.03%
     - 0.028%
     - 0.034%
     - 0.032%
     - 0.039%
     - 0.038%
     - 0.041%
     - 0.04%
     - 0.042%
     - 0.037%
     - 0.029%
     - 0.039%
     - 0.067%
     - 0.048%
     - 0.084%
     - 0.096%
     - 0.067%
     - 0.042%
     - 0.047%
     - 0.034%
     - 0.04%
     - 0.059%
     - 0.043%
     - 0.058%
     - 0.043%
     - 0.033%
     - 0.05%
     - 0.037%
     - 0.036%
     - 0.032%
     - 0.05%
     - 0.06%
     - 0.085%
     - 0.038%
     - 0.035%
     - 0.041%
     - 0.031%
     - 0.035%
     - 0.039%
     - 0.039%
     - 0.034%
     - 0.036%
     - 0.032%
     - 0.028%
     - 0.029%
     - 0.051%
     - 0.066%
     - 0.031%
     - 0.053%
     - 0.026%
     - 0.043%
     - 0.024%
     - 0.03%
     - 0.034%
     - 0.047%
     - 0.042%
     - 0.041%
     - 0.054%
     - 0.04%
     - 0.024%
     - 0.059%
     - 0.034%
     - 0.057%
     - 0.033%
     - 0.05%
     - 0.042%
     - 0.038%
     - 0.046%
     - 0.032%
     - 0.027%
     - 0.032%
     - 0.031%
     - 0.036%
     - 0.044%
     - 0.03%
     - 0.026%
     - 0.027%
     - 0.025%
     - 0.02%
     - 0.051%
     - 0.044%
     - 0.057%
     - 0.038%
     - 0.042%
     - 0.046%
     - 0.03%
     - 0.047%
     - 0.05%
     - 0.031%
     - 0.057%
     - 0.044%
     - 0.07%
     - 0.059%
     - 0.049%
     - 0.064%
     - 0.036%
     - 0.059%
     - 0.048%
     - 0.033%
     - 0.03%
     - 0.028%
     - 0.04%
     - 0.03%
     - 0.027%
     - 0.024%
     - 0.024%
     - 0.048%
     - 0.022%
     - 0.025%
     - 0.048%
     - 0.065%
     - 0.029%
     - 0.041%
     - 0.03%
     - 0.031%
     - 0.025%
     - 0.03%
     - 0.025%
     - 0.026%
     - 0.031%
     - 0.04%
     - 0.028%
     - 0.047%
     - 0.037%
     - 0.025%
     - 0.034%
     - 0.039%
     - 0.042%
     - 0.027%
     - 0.047%
     - 0.035%
     - 0.03%
     - 0.037%
     - 0.036%
     - 0.048%
     - 0.025%
     - 0.038%
     - 0.056%
     - 0.035%
     - 0.027%
     - 0.041%
     - 0.041%
     - 0.059%
     - 0.029%
     - 0.073%
     - 0.065%
     - 0.054%
     - 0.047%
     - 0.049%
     - 0.048%
     - 0.033%
     - 0.044%
     - 0.034%
     - 0.04%
     - 0.033%
     - 0.059%
     - 0.027%
     - 0.026%
     - 0.03%
     - 0.052%
     - 0.039%
     - 0.034%
     - 0.045%
     - 0.052%
     - 0.065%
     - 0.033%
     - 0.031%
     - 0.047%
     - 0.043%
     - 0.041%
     - 0.039%
     - 0.025%
     - 0.036%
     - 0.039%
     - 0.024%
     - 0.035%
     - 0.031%
     - 0.07%
     - 0.033%
     - 0.033%
     - 0.037%
     - 0.039%
     - 0.031%
     - 0.029%
     - 0.046%
     - 0.037%
     - 0.038%
     - 0.038%
     - 0.027%
     - 0.032%
     - 0.05%
     - 0.037%
     - 0.043%
     - 0.056%
     - 0.039%
     - 0.026%
     - 0.025%
     - 0.036%
     - 0.022%
     - 0.021%
     - 0.044%
     - 0.032%
     - 0.039%
     - 0.035%
     - 0.023%
     - 0.05%
     - 0.036%
     - 0.027%
     - 0.038%
     - 0.033%
     - 0.033%
     - 0.029%
     - 0.036%
     - 0.05%
     - 0.062%
     - 0.03%
     - 0.032%
     - 0.047%
     - 0.047%
     - 0.049%
     - 0.064%
     - 0.046%
     - 0.034%
     - 0.034%
     - 0.034%
     - 0.043%
     - 0.03%
     - 0.052%
     - 0.05%
     - 0.054%
     - 0.042%
     - 0.034%
     - 0.031%
     - 0.025%
     - 0.047%
     - 0.038%
     - 0.048%
     - 0.044%
     - 0.057%
     - 0.032%
     - 0.035%
     - 0.031%
     - 0.032%
     - 0.037%
     - 0.039%
     - 0.029%
     - 0.028%
     - 0.027%
     - 0.06%
     - 0.062%
     - 0.045%
     - 0.041%
     - 0.031%
     - 0.022%
     - 0.028%
     - 0.039%
     - 0.04%
     - 0.036%
     - 0.041%
     - 0.029%
     - 0.027%
     - 0.024%
     - 0.02%
     - 0.038%
     - 0.04%
     - 0.058%
     - 0.043%
     - 0.036%
     - 0.036%
     - 0.065%
     - 0.035%
     - 0.054%
     - 0.026%
     - 0.03%
     - 0.047%
     - 0.031%
     - 0.046%
     - 0.036%
     - 0.035%
     - 0.037%
     - 0.03%
     - 0.042%
     - 0.042%
     - 0.035%
     - 0.03%
     - 0.033%
     - 0.057%
     - 0.034%
     - 0.042%
     - 0.061%
     - 0.037%
     - 0.051%
     - 0.069%
     - 0.045%
     - 0.049%
     - 0.039%
     - 0.037%
     - 0.048%
     - 0.039%
     - 0.046%
     - 0.036%
     - 0.038%
     - 0.04%
     - 0.029%
     - 0.035%
     - 0.034%
     - 0.036%
     - 0.048%
     - 0.041%
     - 0.046%
     - 0.064%
     - 0.034%
     - 0.037%
     - 0.04%
     - 0.045%
     - 0.037%
     - 0.039%
     - 0.03%
     - 0.034%
     - 0.029%
     - 0.047%
     - 0.042%
     - 0.038%
     - 0.033%
     - 0.04%
     - 0.037%
     - 0.033%
     - 0.034%
     - 0.031%
     - 0.05%
     - 0.031%
     - 0.057%
     - 0.039%
     - 0.043%
     - 0.052%
     - 0.047%
     - 0.035%
     - 0.04%
     - 0.05%
     - 0.036%
     - 0.036%
     - 0.037%
     - 0.065%
     - 0.056%
     - 0.039%
     - 0.035%
     - 0.043%
     - 0.037%
     - 0.038%
     - 0.042%
     - 0.037%
     - 0.044%
     - 0.047%
     - 0.044%
     - 0.037%
     - 0.039%
     - 0.038%
     - 0.038%
     - 0.051%
     - 0.064%
     - 0.037%
     - 0.046%
     - 0.043%
     - 0.04%
     - 0.051%
     - 0.096%
     - 0.049%
     - 0.036%
     - 0.12%
     - 0.066%
     - 0.051%
     - 0.042%
     - 0.044%
     - 0.04%
     - 0.039%
     - 0.042%
     - 0.056%
     - 0.058%
     - 0.055%
     - 0.032%
     - 0.055%
     - 0.037%
     - 0.035%
     - 0.036%
     - 0.04%
     - 0.042%
     - 0.042%
     - 0.076%
     - 0.058%
     - 0.058%
     - 0.053%
     - 0.053%
     - 0.046%
     - 0.06%
     - 0.054%
     - 0.036%
     - 0.041%
     - 0.036%
     - 0.044%
     - 0.046%
     - 0.04%
     - 0.053%
     - 0.037%
     - 0.067%
     - 0.039%
     - 0.063%
     - 0.048%
     - 0.062%
     - 0.047%
     - 0.051%
     - 0.05%
     - 0.037%
     - 0.058%
     - 0.062%
     - 0.058%
     - 0.065%
     - 0.038%
     - 0.065%
     - 0.054%
     - 0.075%
     - 0.063%
     - 0.049%
     - 0.043%
     - 0.051%
     - 0.045%
     - 0.049%
     - 0.04%
     - 0.05%
     - 0.044%
     - 0.039%
     - 0.035%
     - 0.048%
     - 0.059%
     - 0.029%
     - 0.023%
     - 0.034%
     - 0.057%
     - 0.026%
     - 0.026%
     - 0.024%
     - 0.032%
     - 0.024%
     - 0.027%
     - 0.037%
     - 0.055%
     - 0.036%
     - 0.045%
     - 0.031%
     - 0.03%
     - 0.028%
     - 0.024%
     - 0.025%
     - 0.029%
     - 0.024%
     - 0.025%
     - 0.027%
     - 0.025%
     - 0.047%
     - 0.034%
     - 0.071%
     - 0.034%
     - 0.038%
     - 0.036%
     - 0.04%
     - 0.041%
     - 0.044%
     - 0.035%
     - 0.04%
     - 0.031%
     - 0.038%
     - 0.035%
     - 0.064%
     - 0.037%
     - 0.042%
     - 0.046%
     - 0.06%
     - 0.041%
     - 0.04%
     - 0.06%
     - 0.057%
     - 0.048%
     - 0.037%
     - 0.034%
     - 0.039%
     - 0.042%
     - 0.038%
     - 0.054%
     - 0.039%
     - 0.046%
     - 0.044%
     - 0.042%
     - 0.044%
     - 0.049%
     - 0.042%
     - 0.061%
     - 0.048%
     - 0.059%
     - 0.062%
     - 0.042%
     - 0.049%
     - 0.038%
     - 0.061%
     - 0.046%
     - 0.057%
     - 0.05%
     - 0.057%
     - 0.062%
     - 0.054%
     - 0.037%
     - 0.035%
     - 0.035%
     - 0.031%
     - 0.035%
     - 0.038%
     - 0.053%
     - 0.06%
     - 0.037%
     - 0.054%
     - 0.035%
     - 0.043%
     - 0.055%
     - 0.037%
     - 0.053%
     - 0.034%
     - 0.042%
     - 0.036%
     - 0.038%
     - 0.043%
     - 0.03%
     - 0.042%
     - 0.036%
     - 0.046%
     - 0.049%
     - 0.053%
     - 0.037%
     - 0.039%
     - 0.05%
     - 0.046%
     - 0.052%
     - 0.049%
     - 0.06%
     - 0.065%
     - 0.057%
     - 0.047%
     - 0.039%
     - 0.044%
     - 0.052%
     - 0.046%
     - 0.039%
     - 0.032%
     - 0.033%
     - 0.031%
     - 0.052%
     - 0.056%
     - 0.03%
     - 0.063%
     - 0.03%
     - 0.049%
     - 0.037%
     - 0.035%
     - 0.056%
     - 0.041%
     - 0.031%
     - 0.033%
     - 0.055%
     - 0.053%
     - 0.052%
     - 0.046%
     - 0.039%
     - 0.037%
     - 0.038%
     - 0.035%
     - 0.065%
     - 0.042%
     - 0.029%
     - 0.038%
     - 0.028%
     - 0.032%
     - 0.054%
     - 0.04%
     - 0.045%
     - 0.053%
     - 0.039%
     - 0.04%
     - 0.046%
     - 0.031%
     - 0.047%
     - 0.028%
     - 0.03%
     - 0.076%
     - 0.064%
     - 0.023%
     - 0.027%
     - 0.031%
     - 0.052%
     - 0.029%
     - 0.036%
     - 0.033%
     - 0.026%
     - 0.043%
     - 0.042%
     - 0.041%
     - 0.042%
     - 0.045%
     - 0.05%
     - 0.042%
     - 0.055%
     - 0.071%
     - 0.044%
     - 0.039%
     - 0.037%
     - 0.048%
     - 0.057%
     - 0.038%
     - 0.064%
     - 0.039%
     - 0.043%
     - 0.039%
     - 0.06%
     - 0.041%
     - 0.036%
     - 0.046%
     - 0.046%
     - 0.046%
     - 0.033%
     - 0.031%
     - 0.033%
     - 0.032%
     - 0.034%
     - 0.035%
     - 0.03%
     - 0.039%
     - 0.038%
     - 0.03%
     - 0.038%
     - 0.047%
     - 0.049%
     - 0.06%
     - 0.038%
     - 0.048%
     - 0.044%
     - 0.034%
     - 0.036%
     - 0.05%
     - 0.065%
     - 0.052%
     - 0.049%
     - 0.04%
     - 0.037%
     - 0.051%
     - 0.068%
     - 0.038%
     - 0.048%
     - 0.062%
     - 0.043%
     - 0.053%
     - 0.067%
     - 0.053%
     - 0.034%
     - 0.037%
     - 0.05%
     - 0.031%
     - 0.033%
     - 0.066%
     - 0.042%
     - 0.036%
     - 0.033%
     - 0.036%
     - 0.032%
     - 0.037%
     - 0.035%
     - 0.041%
     - 0.032%
     - 0.033%
     - 0.034%
     - 0.036%
     - 0.045%
     - 0.038%
     - 0.032%
     - 0.046%
     - 0.035%
     - 0.045%
     - 0.038%
     - 0.032%
     - 0.041%
     - 0.039%
     - 0.038%
     - 0.052%
     - 0.05%
     - 0.042%
     - 0.05%
     - 0.053%
     - 0.033%
     - 0.054%
     - 0.052%
     - 0.038%
     - 0.041%
     - 0.032%
     - 0.032%
     - 0.038%
     - 0.056%
     - 0.054%
     - 0.039%
     - 0.069%
     - 0.069%
     - 0.048%
     - 0.041%
     - 0.039%
     - 0.05%
     - 0.041%
     - 0.053%
     - 0.063%
     - 0.075%
     - 0.044%
     - 0.035%
     - 0.046%
     - 0.074%
     - 0.036%
     - 0.045%
     - 0.041%
     - 0.037%
     - 0.05%
     - 0.046%
     - 0.036%
     - 0.047%
     - 0.036%
     - 0.038%
     - 0.05%
     - 0.036%
     - 0.036%
     - 0.05%
     - 0.058%
     - 0.054%
     - 0.034%
     - 0.043%
     - 0.041%
     - 0.045%
     - 0.04%
     - 0.03%
     - 0.042%
     - 0.055%
     - 0.046%
     - 0.045%
     - 0.036%
     - 0.035%
     - 0.035%
     - 0.035%
     - 0.038%
     - 0.032%
     - 0.044%
     - 0.039%
     - 0.038%
     - 0.044%
     - 0.034%
     - 0.04%
     - 0.041%
     - 0.046%
     - 0.059%
     - 0.049%
     - 0.044%
     - 0.044%
     - 0.036%
     - 0.039%
     - 0.054%
     - 0.045%
     - 0.039%
     - 0.036%
     - 0.037%
     - 0.038%
     - 0.062%
     - 0.047%
     - 0.046%
     - 0.037%
     - 0.042%
     - 0.053%
     - 0.04%
     - 0.036%
     - 0.05%
     - 0.035%
     - 0.053%
     - 0.043%
     - 0.043%
     - 0.036%
     - 0.037%
     - 0.038%
     - 0.04%
     - 0.034%
     - 0.042%
     - 0.039%
     - 0.047%
     - 0.05%
     - 0.043%
     - 0.051%
     - 0.035%
     - 0.046%
     - 0.071%
     - 0.038%
     - 0.036%
     - 0.059%
     - 0.037%
     - 0.038%
     - 0.037%
     - 0.036%
     - 0.042%
     - 0.039%
     - 0.052%
     - 0.034%
     - 0.056%
     - 0.035%
     - 0.034%
     - 0.032%
     - 0.046%
     - 0.044%
     - 0.036%
     - 0.043%
     - 0.04%
     - 0.046%
     - 0.032%
     - 0.04%
     - 0.063%
     - 0.04%
     - 0.038%
     - 0.036%
     - 0.042%
     - 0.052%
     - 0.036%
     - 0.052%
     - 0.047%
     - 0.045%
     - 0.043%
     - 0.041%
     - 0.055%
     - 0.063%
     - 0.049%
     - 0.053%
     - 0.041%
     - 0.059%
     - 0.045%
     - 0.05%
     - 0.038%
     - 0.039%
     - 0.037%
     - 0.036%
     - 0.057%
     - 0.036%
     - 0.043%
     - 0.062%
     - 0.038%
     - 0.033%
     - 0.044%
     - 0.055%
     - 0.035%
     - 0.037%
     - 0.033%
     - 0.039%
     - 0.035%
     - 0.037%
     - 0.048%
     - 0.041%
     - 0.047%
     - 0.048%
     - 0.049%
     - 0.036%
     - 0.051%
     - 0.037%
     - 0.057%
     - 0.038%
     - 0.037%
     - 0.034%
     - 0.046%
     - 0.033%
     - 0.033%
     - 0.031%
     - 0.041%
     - 0.045%
     - 0.04%
     - 0.036%
     - 0.037%
     - 0.036%
     - 0.053%
     - 0.031%
     - 0.069%
     - 0.031%
     - 0.04%
     - 0.035%
     - 0.035%
     - 0.047%
     - 0.046%
     - 0.045%
     - 0.039%
     - 0.034%
     - 0.043%
     - 0.033%
     - 0.059%
     - 0.038%
     - 0.039%
     - 0.041%
     - 0.032%
     - 0.044%
     - 0.029%
     - 0.036%
     - 0.036%
     - 0.039%
     - 0.042%
     - 0.036%
     - 0.037%
     - 0.036%
     - 0.038%
     - 0.037%
     - 0.038%
     - 0.059%
     - 0.083%
     - 0.032%
     - 0.031%
     - 0.041%
     - 0.039%
     - 0.046%
     - 0.034%
     - 0.036%
     - 0.047%
     - 0.036%
     - 0.039%
     - 0.037%
     - 0.037%
     - 0.034%
     - 0.035%
     - 0.033%
     - 0.038%
     - 0.035%
     - 0.032%
     - 0.05%
     - 0.041%
     - 0.039%
     - 0.049%
     - 0.043%
     - 0.037%
     - 0.049%
     - 0.035%
     - 0.036%
     - 0.052%
     - 0.059%
     - 0.038%
     - 0.033%
     - 0.035%
     - 0.027%
     - 0.038%
     - 0.029%
     - 0.035%
     - 0.048%
     - 0.033%
     - 0.037%
     - 0.047%
     - 0.034%
     - 0.039%
     - 0.044%
     - 0.061%
     - 0.081%
     - 0.058%
     - 0.043%
     - 0.047%
     - 0.077%
     - 0.055%
     - 0.046%
     - 0.082%
     - 0.037%
     - 0.04%
     - 0.074%
     - 0.045%
     - 0.04%
     - 0.075%
     - 0.063%
     - 0.075%
     - 0.07%
     - 0.064%
     - 0.055%
     - 0.055%
     - 0.044%
     - 0.034%
     - 0.037%
     - 0.043%
     - 0.06%
     - 0.048%
     - 0.035%
     - 0.065%
     - 0.051%
     - 0.066%
     - 0.063%
     - 0.065%
     - 0.051%
     - 0.058%
     - 0.036%
     - 0.04%
     - 0.058%
     - 0.05%
     - 0.041%
     - 0.058%
     - 0.065%
     - 0.043%
     - 0.04%
     - 0.036%
     - 0.047%
     - 0.057%
     - 0.049%
     - 0.052%
     - 0.032%
     - 0.038%
     - 0.041%
     - 0.056%
     - 0.04%
     - 0.039%
     - 0.051%
     - 0.052%
     - 0.039%
     - 0.048%
     - 0.059%
     - 0.07%
     - 0.036%
     - 0.047%
     - 0.039%
     - 0.054%
     - 0.047%
     - 0.047%
     - 0.054%
     - 0.057%
     - 0.044%
     - 0.042%
     - 0.05%
     - 0.034%
     - 0.042%
     - 0.039%
     - 0.059%
     - 0.048%
     - 0.047%
     - 0.059%
     - 0.051%
     - 0.038%
     - 0.047%
     - 0.049%
     - 0.049%
     - 0.062%
     - 0.061%
     - 0.033%
     - 0.056%
     - 0.057%
     - 0.062%
     - 0.047%
     - 0.037%
     - 0.029%
     - 0.035%
     - 0.032%
     - 0.038%
     - 0.033%
     - 0.04%
     - 0.033%
     - 0.039%
     - 0.05%
     - 0.034%
     - 0.034%
     - 0.032%
     - 0.034%
     - 0.042%
     - 0.04%
     - 0.054%
     - 0.041%
     - 0.037%
     - 0.04%
     - 0.047%
     - 0.04%
     - 0.034%
     - 0.033%
     - 0.031%
     - 0.037%
     - 0.045%
     - 0.035%
     - 0.04%
     - 0.036%
     - 0.043%
     - 0.041%
     - 0.046%
     - 0.037%
     - 0.041%
     - 0.037%
     - 0.045%
     - 0.045%
     - 0.048%
     - 0.055%
     - 0.045%
     - 0.045%
     - 0.031%
     - 0.036%
     - 0.034%
     - 0.07%
     - 0.044%
     - 0.038%
     - 0.03%
     - 0.052%
     - 0.036%
     - 0.044%
     - 0.043%
     - 0.066%
     - 0.039%
     - 0.033%
     - 0.032%
     - 0.038%
     - 0.041%
     - 0.04%
     - 0.041%
     - 0.04%
     - 0.037%
     - 0.04%
     - 0.035%
     - 0.054%
     - 0.041%
     - 0.057%
     - 0.074%
     - 0.033%
     - 0.033%
     - 0.043%
     - 0.042%
     - 0.038%
     - 0.039%
     - 0.045%
     - 0.047%
     - 0.042%
     - 0.042%
     - 0.058%
     - 0.056%
     - 0.048%
     - 0.05%
     - 0.038%
     - 0.049%
     - 0.045%
     - 0.06%
     - 0.043%
     - 0.039%
     - 0.031%
     - 0.034%
     - 0.044%
     - 0.033%
     - 0.052%
     - 0.04%
     - 0.039%
     - 0.063%
     - 0.043%
     - 0.055%
     - 0.048%
     - 0.067%
     - 0.046%
     - 0.048%
     - 0.072%
     - 0.058%
     - 0.052%
     - 0.05%
     - 0.051%
     - 0.035%
     - 0.063%
     - 0.056%
     - 0.049%
     - 0.039%
     - 0.04%
     - 0.039%
     - 0.041%
     - 0.05%
     - 0.05%
     - 0.033%
     - 0.052%
     - 0.043%
     - 0.048%
     - 0.033%
     - 0.034%
     - 0.033%
     - 0.037%
     - 0.041%
     - 0.031%
     - 0.054%
     - 0.042%
     - 0.042%
     - 0.04%
     - 0.051%
     - 0.047%
     - 0.039%
     - 0.036%
     - 0.044%
     - 0.036%
     - 0.042%
     - 0.043%
     - 0.035%
     - 0.04%
     - 0.046%
     - 0.044%
     - 0.042%
     - 0.048%
     - 0.055%
     - 0.056%
     - 0.05%
     - 0.041%
     - 0.051%
     - 0.044%
     - 0.033%
     - 0.034%
     - 0.04%
     - 0.037%
     - 0.035%
     - 0.049%
     - 0.037%
     - 0.045%
     - 0.036%
     - 0.035%
     - 0.042%
     - 0.034%
     - 0.045%
     - 0.054%
     - 0.046%
     - 0.046%
     - 0.037%
     - 0.039%
     - 0.04%
     - 0.037%
     - 0.057%
     - 0.034%
     - 0.061%
     - 0.044%
     - 0.038%
     - 0.062%
     - 0.061%
     - 0.037%
     - 0.041%
     - 0.032%
     - 0.034%
     - 0.035%
     - 0.042%
     - 0.035%
     - 0.031%
     - 0.075%
     - 0.047%
     - 0.045%
     - 0.038%
     - 0.056%
     - 0.041%
     - 0.059%
     - 0.036%
     - 0.039%
     - 0.039%
     - 0.048%
     - 0.034%
     - 0.049%
     - 0.051%
     - 0.042%
     - 0.054%
     - 0.046%
     - 0.034%
     - 0.035%
     - 0.054%
     - 0.062%
     - 0.049%
     - 0.036%
     - 0.043%
     - 0.034%
     - 0.044%
     - 0.037%
     - 0.04%
     - 0.064%
     - 0.046%
     - 0.045%
     - 0.034%
     - 0.036%
     - 0.046%
     - 0.035%
     - 0.028%
     - 0.029%
     - 0.03%
     - 0.027%
     - 0.037%
     - 0.035%
     - 0.03%
     - 0.03%
     - 0.048%
     - 0.034%
     - 0.042%
     - 0.045%
     - 0.038%
     - 0.037%
     - 0.036%
     - 0.033%
     - 0.029%
     - 0.03%
     - 0.029%
     - 0.036%
     - 0.03%
     - 0.03%
     - 0.03%
     - 0.033%
     - 0.039%
     - 0.03%
     - 0.037%
     - 0.031%
     - 0.031%
     - 0.027%
     - 0.054%
     - 0.042%
     - 0.035%
     - 0.038%
     - 0.041%
     - 0.044%
     - 0.039%
     - 0.033%
     - 0.061%
     - 0.031%
     - 0.028%
     - 0.038%
     - 0.037%
     - 0.032%
     - 0.035%
     - 0.046%
     - 0.034%
     - 0.033%
     - 0.03%
     - 0.029%
     - 0.027%
     - 0.031%
     - 0.039%
     - 0.048%
     - 0.046%
     - 0.037%
     - 0.04%
     - 0.042%
     - 0.035%
     - 0.038%
     - 0.045%
     - 0.036%
     - 0.041%
     - 0.03%
     - 0.032%
     - 0.031%
     - 0.078%
     - 0.036%
     - 0.029%
     - 0.05%
     - 0.038%
     - 0.054%
     - 0.04%
     - 0.031%
     - 0.035%
     - 0.036%
     - 0.035%
     - 0.036%
     - 0.036%
     - 0.029%
     - 0.042%
     - 0.028%
     - 0.035%
     - 0.056%
     - 0.036%
     - 0.062%
     - 0.037%
     - 0.042%
     - 0.053%
     - 0.057%
     - 0.042%
     - 0.037%
     - 0.047%
     - 0.042%
     - 0.038%
     - 0.042%
     - 0.052%
     - 0.068%
     - 0.066%
     - 0.044%
     - 0.07%
     - 0.05%
     - 0.049%
     - 0.039%
     - 0.071%
     - 0.051%
     - 0.043%
     - 0.053%
     - 0.042%
     - 0.055%
     - 0.04%
     - 0.049%
     - 0.04%
     - 0.052%
     - 0.039%
     - 0.043%
     - 0.043%
     - 0.039%
     - 0.034%
     - 0.041%
     - 0.031%
     - 0.054%
     - 0.033%
     - 0.039%
     - 0.035%
     - 0.038%
     - 0.039%
     - 0.033%
     - 0.053%
     - 0.054%
     - 0.043%
     - 0.054%
     - 0.034%
     - 0.047%
     - 0.039%
     - 0.039%
     - 0.051%
     - 0.037%
     - 0.039%
     - 0.054%
     - 0.039%
     - 0.065%
     - 0.046%
     - 0.043%
     - 0.035%
     - 0.047%
     - 0.031%
     - 0.035%
     - 0.038%
     - 0.05%
     - 0.05%
     - 0.053%
     - 0.047%
     - 0.039%
     - 0.05%
     - 0.035%
     - 0.036%
     - 0.033%
     - 0.027%
     - 0.029%
     - 0.022%
     - 0.03%
     - 0.041%
     - 0.038%
     - 0.032%
     - 0.048%
     - 0.061%
     - 0.056%
     - 0.032%
     - 0.03%
     - 0.026%
     - 0.029%
     - 0.028%
     - 0.033%
     - 0.028%
     - 0.029%
     - 0.026%
     - 0.028%
     - 0.027%
     - 0.031%
     - 0.029%
     - 0.027%
     - 0.031%
     - 0.031%
     - 0.074%
     - 0.037%
     - 0.035%
     - 0.027%
     - 0.027%
     - 0.026%
     - 0.028%
     - 0.026%
     - 0.028%
     - 0.034%
     - 0.038%
     - 0.037%
     - 0.035%
     - 0.045%
     - 0.035%
     - 0.036%
     - 0.038%
     - 0.051%
     - 0.04%
     - 0.059%
     - 0.038%
     - 0.045%
     - 0.038%
     - 0.1%
     - 0.088%
     - 0.078%
     - 0.072%
     - 0.058%
     - 0.069%
     - 0.045%
     - 0.038%
     - 0.05%
     - 0.05%
     - 0.037%
     - 0.043%
     - 0.047%
     - 0.04%
     - 0.043%
     - 0.036%
     - 0.045%
     - 0.055%
     - 0.041%
     - 0.034%
     - 0.037%
     - 0.04%
     - 0.037%
     - 0.045%
     - 0.046%
     - 0.05%
     - 0.036%
     - 0.06%
     - 0.045%
     - 0.071%
     - 0.034%
     - 0.048%
     - 0.044%
     - 0.035%
     - 0.041%
     - 0.043%
     - 0.05%
     - 0.036%
     - 0.057%
     - 0.032%
     - 0.034%
     - 0.04%
     - 0.035%
     - 0.047%
     - 0.049%
     - 0.051%
     - 0.042%
     - 0.048%
     - 0.046%
     - 0.05%
     - 0.033%
     - 0.05%
     - 0.036%
     - 0.042%
     - 0.039%
     - 0.048%
     - 0.038%
     - 0.072%
     - 0.057%
     - 0.047%
     - 0.035%
     - 0.034%
     - 0.034%
     - 0.034%
     - 0.043%
     - 0.07%
     - 0.041%
     - 0.051%
     - 0.035%
     - 0.036%
     - 0.037%
     - 0.041%
     - 0.034%
     - 0.053%
     - 0.034%
     - 0.035%
     - 0.04%
     - 0.04%
     - 0.035%
     - 0.033%
     - 0.037%
     - 0.04%
     - 0.05%
     - 0.037%
     - 0.036%
     - 0.045%
     - 0.049%
     - 0.04%
     - 0.035%
     - 0.048%
     - 0.037%
     - 0.039%
     - 0.052%
     - 0.044%
     - 0.052%
     - 0.035%
     - 0.034%
     - 0.035%
     - 0.037%
     - 0.04%
     - 0.044%
     - 0.039%
     - 0.04%
     - 0.032%
     - 0.035%
     - 0.032%
     - 0.043%
     - 0.046%
     - 0.033%
     - 0.045%
     - 0.037%
     - 0.044%
     - 0.066%
     - 0.043%
     - 0.052%
     - 0.033%
     - 0.035%
     - 0.038%
     - 0.046%
     - 0.037%
     - 0.03%
     - 0.032%
     - 0.031%
     - 0.043%
     - 0.038%
     - 0.033%
     - 0.048%
     - 0.042%
     - 0.049%
     - 0.042%
     - 0.035%
     - 0.032%
     - 0.04%
     - 0.035%
     - 0.06%
     - 0.037%
     - 0.063%
     - 0.038%
     - 0.039%
     - 0.033%
     - 0.039%
     - 0.036%
     - 0.043%
     - 0.035%
     - 0.082%
     - 0.034%
     - 0.053%
     - 0.044%
     - 0.038%
     - 0.035%
     - 0.042%
     - 0.034%
     - 0.04%
     - 0.076%
     - 0.06%
     - 0.038%
     - 0.053%
     - 0.035%
     - 0.054%
     - 0.04%
     - 0.05%
     - 0.035%
     - 0.04%
     - 0.039%
     - 0.039%
     - 0.062%
     - 0.069%
     - 0.064%
     - 0.047%
     - 0.035%
     - 0.037%
     - 0.061%
     - 0.034%
     - 0.035%
     - 0.037%
     - 0.029%
     - 0.031%
     - 0.032%
     - 0.051%
     - 0.036%
     - 0.036%
     - 0.036%
     - 0.041%
     - 0.054%
     - 0.045%
     - 0.032%
     - 0.052%
     - 0.036%
     - 0.035%
     - 0.029%
     - 0.033%
     - 0.032%
     - 0.036%
     - 0.036%
     - 0.053%
     - 0.051%
     - 0.07%
     - 0.043%
     - 0.07%
     - 0.06%
     - 0.037%
     - 0.046%
     - 0.045%
     - 0.043%
     - 0.045%
     - 0.053%
     - 0.04%
     - 0.049%
     - 0.048%
     - 0.058%
     - 0.038%
     - 0.036%
     - 0.053%
     - 0.06%
     - 0.072%
     - 0.044%
     - 0.037%
     - 0.05%
     - 0.045%
     - 0.067%
     - 0.044%
     - 0.044%
     - 0.037%
     - 0.053%
     - 0.035%
     - 0.053%
     - 0.038%
     - 0.049%
     - 0.059%
     - 0.044%
     - 0.048%
     - 0.055%
     - 0.036%
     - 0.042%
     - 0.051%
     - 0.037%
     - 0.042%
     - 0.044%
     - 0.045%
     - 0.047%
     - 0.034%
     - 0.053%
     - 0.045%
     - 0.04%
     - 0.041%
     - 0.05%
     - 0.052%
     - 0.041%
     - 0.036%
     - 0.041%
     - 0.038%
     - 0.038%
     - 0.051%
     - 0.047%
     - 0.039%
     - 0.039%
     - 0.049%
     - 0.048%
     - 0.049%
     - 0.039%
     - 0.043%
     - 0.058%
     - 0.047%
     - 0.042%
     - 0.037%
     - 0.049%
     - 0.045%
     - 0.035%
     - 0.034%
     - 0.039%
     - 0.042%
     - 0.031%
     - 0.036%
     - 0.033%
     - 0.046%
     - 0.04%
     - 0.051%
     - 0.039%
     - 0.045%
     - 0.039%
     - 0.039%
     - 0.052%
     - 0.047%
     - 0.047%
     - 0.035%
     - 0.046%
     - 0.057%
     - 0.053%
     - 0.04%
     - 0.055%
     - 0.047%
     - 0.047%
     - 0.068%
     - 0.033%
     - 0.051%
     - 0.039%
     - 0.05%
     - 0.064%
     - 0.039%
     - 0.054%
     - 0.053%
     - 0.035%
     - 0.039%
     - 0.054%
     - 0.042%
     - 0.058%
     - 0.066%
     - 0.036%
     - 0.05%
     - 0.065%
     - 0.067%
     - 0.047%
     - 0.047%
     - 0.097%
     - 0.045%
     - 0.076%
     - 0.051%
     - 0.063%
     - 0.07%
     - 0.079%
     - 0.063%
     - 0.036%
     - 0.062%
     - 0.032%
     - 0.048%
     - 0.045%
     - 0.039%
     - 0.053%
     - 0.047%
     - 0.051%
     - 0.062%
     - 0.055%
     - 0.051%
     - 0.041%
     - 0.042%
     - 0.039%
     - 0.043%
     - 0.039%
     - 0.037%
     - 0.058%
     - 0.044%
     - 0.041%
     - 0.06%
     - 0.036%
     - 0.034%
     - 0.064%
     - 0.046%
     - 0.042%
     - 0.051%
     - 0.055%
     - 0.041%
     - 0.038%
     - 0.037%
     - 0.038%
     - 0.045%
     - 0.037%
     - 0.036%
     - 0.046%
     - 0.051%
     - 0.036%
     - 0.041%
     - 0.041%
     - 0.051%
     - 0.055%
     - 0.051%
     - 0.037%
     - 0.048%
     - 0.037%
     - 0.038%
     - 0.055%
     - 0.044%
     - 0.036%
     - 0.028%
     - 0.033%
     - 0.036%
     - 0.035%
     - 0.034%
     - 0.059%
     - 0.037%
     - 0.04%
     - 0.04%
     - 0.036%
     - 0.054%
     - 0.052%
     - 0.042%
     - 0.064%
     - 0.051%
     - 0.053%
     - 0.04%
     - 0.038%
     - 0.041%
     - 0.029%
     - 0.031%
     - 0.035%
     - 0.038%
     - 0.04%
     - 0.045%
     - 0.041%
     - 0.035%
     - 0.031%
     - 0.032%
     - 0.037%
     - 0.036%
     - 0.035%
     - 0.038%
     - 0.033%
     - 0.034%
     - 0.035%
     - 0.034%
     - 0.036%
     - 0.043%
     - 0.044%
     - 0.046%
     - 0.026%
     - 0.027%
     - 0.031%
     - 0.026%
     - 0.031%
     - 0.04%
     - 0.043%
     - 0.029%
     - 0.036%
     - 0.041%
     - 0.034%
     - 0.037%
     - 0.052%
     - 0.034%
     - 0.029%
     - 0.028%
     - 0.029%
     - 0.03%
     - 0.028%
     - 0.026%
     - 0.035%
     - 0.034%
     - 0.036%
     - 0.032%
     - 0.044%
     - 0.035%
     - 0.027%
     - 0.03%
     - 0.031%
     - 0.037%
     - 0.029%
     - 0.043%
     - 0.033%
     - 0.03%
     - 0.028%
     - 0.036%
     - 0.046%
     - 0.035%
     - 0.036%
     - 0.071%
     - 0.042%
     - 0.035%
     - 0.036%
     - 0.043%
     - 0.042%
     - 0.035%
     - 0.033%
     - 0.041%
     - 0.031%
     - 0.032%
     - 0.037%
     - 0.038%
     - 0.061%
     - 0.051%
     - 0.049%
     - 0.052%
     - 0.062%
     - 0.055%
     - 0.033%
     - 0.04%
     - 0.062%
     - 0.048%
     - 0.045%
     - 0.045%
     - 0.039%
     - 0.041%
     - 0.033%
     - 0.041%
     - 0.038%
     - 0.035%
     - 0.032%
     - 0.04%
     - 0.031%
     - 0.046%
     - 0.057%
     - 0.031%
     - 0.028%
     - 0.031%
     - 0.024%
     - 0.036%
     - 0.027%
     - 0.031%
     - 0.031%
     - 0.046%
     - 0.037%
     - 0.031%
     - 0.035%
     - 0.032%
     - 0.027%
     - 0.028%
     - 0.031%
     - 0.033%
     - 0.028%
     - 0.031%
     - 0.033%
     - 0.03%
     - 0.036%
     - 0.032%
     - 0.031%
     - 0.037%
     - 0.032%
     - 0.034%
     - 0.033%
     - 0.027%
     - 0.027%
     - 0.03%
     - 0.036%
     - 0.042%
     - 0.028%
     - 0.062%
     - 0.043%
     - 0.031%
     - 0.031%
     - 0.033%
     - 0.028%
     - 0.034%
     - 0.027%
     - 0.033%
     - 0.045%
     - 0.057%
     - 0.049%
     - 0.036%
     - 0.03%
     - 0.034%
     - 0.032%
     - 0.034%
     - 0.037%
     - 0.04%
     - 0.039%
     - 0.036%
     - 0.052%
     - 0.043%
     - 0.037%
     - 0.036%
     - 0.052%
     - 0.046%
     - 0.036%
     - 0.04%
     - 0.039%
     - 0.03%
     - 0.039%
     - 0.032%
     - 0.031%
     - 0.027%
     - 0.028%
     - 0.025%
     - 0.029%
     - 0.031%
     - 0.038%
     - 0.042%
     - 0.032%
     - 0.03%
     - 0.03%
     - 0.031%
     - 0.03%
     - 0.043%
     - 0.04%
     - 0.049%
     - 0.032%
     - 0.027%
     - 0.03%
     - 0.043%
     - 0.039%
     - 0.035%
     - 0.035%
     - 0.035%
     - 0.039%
     - 0.035%
     - 0.027%
     - 0.025%
     - 0.029%
     - 0.026%
     - 0.037%
     - 0.028%
     - 0.023%
     - 0.03%
     - 0.029%
     - 0.054%
     - 0.048%
     - 0.029%
     - 0.045%
     - 0.047%
     - 0.024%
     - 0.043%
     - 0.023%
     - 0.031%
     - 0.046%
     - 0.024%
     - 0.036%
     - 0.03%
     - 0.025%
     - 0.024%
     - 0.037%
     - 0.026%
     - 0.032%
     - 0.047%
     - 0.033%
     - 0.032%
     - 0.04%
     - 0.042%
     - 0.033%
     - 0.033%
     - 0.028%
     - 0.029%
     - 0.032%
     - 0.031%
     - 0.072%
     - 0.072%
     - 0.059%
     - 0.046%
     - 0.071%
     - 0.056%
     - 0.038%
     - 0.036%
     - 0.052%
     - 0.041%
     - 0.041%
     - 0.042%
     - 0.043%
     - 0.072%
     - 0.068%
     - 0.039%
     - 0.043%
     - 0.051%
     - 0.073%
     - 0.054%
     - 0.046%
     - 0.066%
     - 0.036%
     - 0.047%
     - 0.051%
     - 0.038%
     - 0.058%
     - 0.045%
     - 0.051%
     - 0.057%
     - 0.047%
     - 0.054%
     - 0.075%
     - 0.029%
     - 0.03%
     - 0.062%
     - 0.056%
     - 0.036%
     - 0.029%
     - 0.04%
     - 0.037%
     - 0.039%
     - 0.027%
     - 0.034%
     - 0.029%
     - 0.047%
     - 0.033%
     - 0.031%
     - 0.071%
     - 0.061%
     - 0.059%
     - 0.054%
     - 0.069%
     - 0.079%
     - 0.039%
     - 0.042%
     - 0.041%
     - 0.042%
     - 0.041%
     - 0.031%
     - 0.034%
     - 0.029%
     - 0.032%
     - 0.03%
     - 0.043%
     - 0.035%
     - 0.029%
     - 0.037%
     - 0.035%
     - 0.033%
     - 0.03%
     - 0.031%
     - 0.046%
     - 0.051%
     - 0.052%
     - 0.031%
     - 0.041%
     - 0.038%
     - 0.034%
     - 0.037%
     - 0.033%
     - 0.036%
     - 0.03%
     - 0.055%
     - 0.04%
     - 0.061%
     - 0.04%
     - 0.045%
     - 0.036%
     - 0.045%
     - 0.045%
     - 0.041%
     - 0.041%
     - 0.038%
     - 0.039%
     - 0.034%
     - 0.032%
     - 0.034%
     - 0.033%
     - 0.036%
     - 0.037%
     - 0.037%
     - 0.034%
     - 0.037%
     - 0.041%
     - 0.04%
     - 0.042%
     - 0.04%
     - 0.095%
     - 0.04%
     - 0.059%
     - 0.067%
     - 0.034%
     - 0.046%
     - 0.07%
     - 0.068%
     - 0.048%
     - 0.037%
     - 0.042%
     - 0.054%
     - 0.062%
     - 0.035%
     - 0.063%
     - 0.048%
     - 0.056%
     - 0.055%
     - 0.044%
     - 0.072%
     - 0.051%
     - 0.038%
     - 0.052%
     - 0.069%
     - 0.061%
     - 0.041%
     - 0.038%
     - 0.06%
     - 0.033%
     - 0.038%
     - 0.035%
     - 0.028%
     - 0.038%
     - 0.039%
     - 0.051%
     - 0.039%
     - 0.049%
     - 0.035%
     - 0.048%
     - 0.039%
     - 0.046%
     - 0.052%
     - 0.044%
     - 0.079%
     - 0.049%
     - 0.041%
     - 0.035%
     - 0.059%
     - 0.033%
     - 0.072%
     - 0.046%
     - 0.065%
     - 0.038%
     - 0.042%
     - 0.035%
     - 0.045%
     - 0.038%
     - 0.04%

.. _puma_metro_status:

PUMA Metro Status
-----------------

Description
***********

The public use microdata area metropolitan status that the dwelling unit is located.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \'PUMA Metro Status', derived from ACS IPUMS METRO codes, indicates whether the household resided within a metropolitan area and, for households in metropolitan areas, whether the household resided within or outside of a central/principal city. Each PUMA has a unique METRO status in ACS and therefore has a unique PUMA Metro Status. IPUMS derives METRO codes for samples not directly identified based on available geographic information and whether the associated county group or PUMA lies wholly or only partially within metropolitan areas or principal cities.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **PUMA Metro Status** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - In metro area, not/partially in principal city
     - In metro area, principal city
     - Not/partially in metro area
   * - Stock saturation
     - 64%
     - 13%
     - 23%

.. _pv_orientation:

PV Orientation
--------------

Description
***********

The orientation of the photovoltaic system.

Created by
**********

``sources/dpv/tsv_maker.py``

Source
******

- \LBNL's 2020 Tracking the Sun (TTS).


Assumption
**********

- \PV orientation mapped based on azimuth angle of primary array (180 deg is South-facing).


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **PV Orientation** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - East
     - None
     - North
     - Northeast
     - Northwest
     - South
     - Southeast
     - Southwest
     - West
   * - Stock saturation
     - 0.16%
     - 99%
     - 0.017%
     - 0.015%
     - 0.01%
     - 0.46%
     - 0.15%
     - 0.12%
     - 0.089%
   * - ``pv_system_direction_array_azimuth``
     - 90
     - 180
     - 0
     - 45
     - 315
     - 180
     - 135
     - 225
     - 270

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``pv_system_direction_array_azimuth``
     - deg
     - The azimuth of the PV system array. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).
.. _pv_system_size:

PV System Size
--------------

Description
***********

The size of the photovoltaic system.

Created by
**********

``sources/dpv/tsv_maker.py``

Source
******

- \LBNL's 2020 Tracking the Sun (TTS).


Assumption
**********

- \Installations of unknown mount type are assumed rooftop. States without data are backfilled with aggregates at the Census Region. 'East South Central' assumed the same distribution as 'West South Central'.

- \PV is not modeled in AK and HI. The Option=None is set so that an error is thrown if PV is modeled as an argument will be missing.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **PV System Size** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 1.0 kWDC
     - 3.0 kWDC
     - 5.0 kWDC
     - 7.0 kWDC
     - 9.0 kWDC
     - 11.0 kWDC
     - 13.0 kWDC
     - None
   * - Stock saturation
     - 0.028%
     - 0.2%
     - 0.31%
     - 0.23%
     - 0.15%
     - 0.078%
     - 0.032%
     - 99%
   * - ``pv_system_maximum_power_output``
     - 1000
     - 3000
     - 5000
     - 7000
     - 9000
     - 11000
     - 13000
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``pv_system_maximum_power_output``
     - W
     - Peak power for the PV system.
.. _plug_load_diversity:

Plug Load Diversity
-------------------

Description
***********

Plug load diversity multiplier intended to add variation in plug load profiles across all simulations.

Created by
**********

manually created

Source
******

- \Engineering Judgement, Calibration


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Plug Load Diversity** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 50%
     - 100%
     - 200%
   * - Stock saturation
     - 25%
     - 50%
     - 25%
   * - ``misc_television_usage_multiplier``
     - 0.5
     - 
     - 2.0
   * - ``misc_plug_loads_usage_multiplier``
     - 0.5
     - 
     - 2.0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``misc_television_usage_multiplier``
     - 
     - Multiplier on the energy usage that can reflect, e.g., high/low usage occupants.
   * - ``misc_plug_loads_usage_multiplier``
     - 
     - Multiplier on the energy usage that can reflect, e.g., high/low usage occupants.
.. _plug_loads:

Plug Loads
----------

Description
***********

Plug load usage level which is varied by Census Division RECS and Building Type RECS.

Created by
**********

``sources/recs/recs2015/tsv_maker.py``

Source
******

- \U.S. EIA 2015 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Multipliers are based on ratio of the ResStock MELS regression equations and the MELS modeled in RECS.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Plug Loads** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 78%
     - 79%
     - 82%
     - 84%
     - 85%
     - 86%
     - 89%
     - 91%
     - 94%
     - 95%
     - 96%
     - 97%
     - 99%
     - 100%
     - 101%
     - 102%
     - 103%
     - 104%
     - 105%
     - 106%
     - 108%
     - 110%
     - 113%
     - 119%
     - 121%
     - 123%
     - 134%
     - 137%
     - 140%
     - 144%
     - 166%
   * - Stock saturation
     - 0.21%
     - 0.21%
     - 1.1%
     - 2.9%
     - 10%
     - 1%
     - 5.5%
     - 5.6%
     - 10%
     - 5%
     - 4%
     - 0.74%
     - 2.8%
     - 0.28%
     - 7.6%
     - 0.66%
     - 0.17%
     - 2.7%
     - 0.57%
     - 17%
     - 1.3%
     - 6.1%
     - 8%
     - 1.8%
     - 0.84%
     - 1.4%
     - 0.74%
     - 0.12%
     - 0.37%
     - 1%
     - 0.4%
   * - ``misc_plug_loads_television_usage_multiplier``
     - 0.78
     - 0.79
     - 0.82
     - 0.84
     - 0.85
     - 0.86
     - 0.89
     - 0.91
     - 0.94
     - 0.95
     - 0.96
     - 0.97
     - 0.99
     - 1.0
     - 1.01
     - 1.02
     - 1.03
     - 1.04
     - 1.05
     - 1.06
     - 1.08
     - 1.1
     - 1.13
     - 1.19
     - 1.21
     - 1.23
     - 1.34
     - 1.37
     - 1.4
     - 1.44
     - 1.66
   * - ``misc_plug_loads_other_usage_multiplier``
     - 0.78
     - 0.79
     - 0.82
     - 0.84
     - 0.85
     - 0.86
     - 0.89
     - 0.91
     - 0.94
     - 0.95
     - 0.96
     - 0.97
     - 0.99
     - 1.0
     - 1.01
     - 1.02
     - 1.03
     - 1.04
     - 1.05
     - 1.06
     - 1.08
     - 1.1
     - 1.13
     - 1.19
     - 1.21
     - 1.23
     - 1.34
     - 1.37
     - 1.4
     - 1.44
     - 1.66

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``misc_plug_loads_television_usage_multiplier``
     - 
     - Multiplier on the television energy usage that can reflect, e.g., high/low usage occupants.
   * - ``misc_plug_loads_other_usage_multiplier``
     - 
     - Multiplier on the other energy usage that can reflect, e.g., high/low usage occupants.
.. _reeds_balancing_area:

REEDS Balancing Area
--------------------

Description
***********

The Regional Energy Deployment System Model (ReEDS) balancing area that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \Brown, Maxwell, Wesley Cole, Kelly Eurek, Jon Becker, David Bielen, Ilya Chernyakhovskiy, Stuart Cohen et al. 2020. Regional Energy Deployment System (ReEDS) Model Documentation: Version 2019. Golden, CO: National Renewable Energy Laboratory. NREL/TP-6A20-74111. https://www.nrel.gov/docs/fy20osti/74111.pdf.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **REEDS Balancing Area** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 1
     - 2
     - 3
     - 4
     - 5
     - 6
     - 7
     - 8
     - 9
     - 10
     - 11
     - 12
     - 13
     - 14
     - 15
     - 16
     - 17
     - 18
     - 19
     - 20
     - 21
     - 22
     - 23
     - 24
     - 25
     - 26
     - 27
     - 28
     - 29
     - 30
     - 31
     - 32
     - 33
     - 34
     - 35
     - 36
     - 37
     - 38
     - 39
     - 40
     - 41
     - 42
     - 43
     - 44
     - 45
     - 46
     - 47
     - 48
     - 49
     - 50
     - 51
     - 52
     - 53
     - 54
     - 55
     - 56
     - 57
     - 58
     - 59
     - 60
     - 61
     - 62
     - 63
     - 64
     - 65
     - 66
     - 67
     - 68
     - 69
     - 70
     - 71
     - 72
     - 73
     - 74
     - 75
     - 76
     - 77
     - 78
     - 79
     - 80
     - 81
     - 82
     - 83
     - 84
     - 85
     - 86
     - 87
     - 88
     - 89
     - 90
     - 91
     - 92
     - 93
     - 94
     - 95
     - 96
     - 97
     - 98
     - 99
     - 100
     - 101
     - 102
     - 103
     - 104
     - 105
     - 106
     - 107
     - 108
     - 109
     - 110
     - 111
     - 112
     - 113
     - 114
     - 115
     - 116
     - 117
     - 118
     - 119
     - 120
     - 121
     - 122
     - 123
     - 124
     - 125
     - 126
     - 127
     - 128
     - 129
     - 130
     - 131
     - 132
     - 133
     - 134
     - None
   * - Stock saturation
     - 1.5%
     - 0.45%
     - 0.24%
     - 0.039%
     - 1.1%
     - 0.19%
     - 0.021%
     - 0.031%
     - 4.3%
     - 5.1%
     - 0.89%
     - 0.25%
     - 0.64%
     - 0.1%
     - 0.27%
     - 0.14%
     - 0.15%
     - 0.13%
     - 0.0042%
     - 0.063%
     - 0.074%
     - 0.014%
     - 0.02%
     - 0.092%
     - 0.71%
     - 0.052%
     - 0.084%
     - 1.7%
     - 0.024%
     - 0.35%
     - 0.6%
     - 0.055%
     - 1.3%
     - 0.41%
     - 0.02%
     - 0.091%
     - 0.17%
     - 0.23%
     - 0.039%
     - 0.2%
     - 0.37%
     - 0.093%
     - 1.5%
     - 0.048%
     - 0.24%
     - 0.3%
     - 0.082%
     - 0.26%
     - 0.0093%
     - 0.83%
     - 0.42%
     - 0.038%
     - 0.89%
     - 0.52%
     - 0.33%
     - 0.31%
     - 0.14%
     - 1.4%
     - 0.21%
     - 0.058%
     - 0.13%
     - 0.1%
     - 2.7%
     - 0.91%
     - 1.2%
     - 0.4%
     - 1.6%
     - 0.11%
     - 0.11%
     - 0.67%
     - 0.045%
     - 0.94%
     - 0.061%
     - 0.11%
     - 0.31%
     - 0.32%
     - 0.097%
     - 0.23%
     - 0.72%
     - 2.8%
     - 0.61%
     - 0.2%
     - 0.32%
     - 0.15%
     - 0.69%
     - 0.11%
     - 0.74%
     - 0.22%
     - 0.81%
     - 0.83%
     - 0.38%
     - 2.1%
     - 0.23%
     - 3.1%
     - 0.57%
     - 1.1%
     - 1.7%
     - 1.6%
     - 2.1%
     - 0.072%
     - 4.2%
     - 2.3%
     - 3.1%
     - 0.21%
     - 1.1%
     - 0.4%
     - 0.6%
     - 0.12%
     - 1%
     - 0.1%
     - 1.6%
     - 1.4%
     - 0.37%
     - 0.53%
     - 0.84%
     - 0.4%
     - 0.26%
     - 0.41%
     - 0.089%
     - 0.053%
     - 0.15%
     - 3.2%
     - 1.9%
     - 0.021%
     - 0.31%
     - 2.7%
     - 5.3%
     - 0.77%
     - 0.24%
     - 0.46%
     - 2.1%
     - 1.1%
     - 0.35%
     - 0.54%
     - 0.63%

.. _radiant_barrier:

Radiant Barrier
---------------

Description
***********

Presence of radiant barrier in the attic (not modeled in project_national).

Created by
**********

manually created

Source
******

- \Not applicable

- \all homes are assumed to not have attic radiant barriers installed.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Radiant Barrier** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - None
     - Yes
     - No
   * - Stock saturation
     - 26%
     - 0%
     - 74%
   * - ``enclosure_radiant_barrier_location``
     - 
     - Attic roof only
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_radiant_barrier_location``
     - 
     - The location of the radiant barrier in the attic.
.. _range_spot_vent_hour:

Range Spot Vent Hour
--------------------

Description
***********

Range spot ventilation daily start hour.

Created by
**********

manually created

Source
******

- \derived from national average cooking range schedule in Wilson et al. 'Building America House Simulation Protocols' 2014


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Range Spot Vent Hour** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Hour0
     - Hour1
     - Hour2
     - Hour3
     - Hour4
     - Hour5
     - Hour6
     - Hour7
     - Hour8
     - Hour9
     - Hour10
     - Hour11
     - Hour12
     - Hour13
     - Hour14
     - Hour15
     - Hour16
     - Hour17
     - Hour18
     - Hour19
     - Hour20
     - Hour21
     - Hour22
     - Hour23
   * - Stock saturation
     - 0.7%
     - 0.7%
     - 0.4%
     - 0.4%
     - 0.7%
     - 1.1%
     - 2.5%
     - 4.2%
     - 4.6%
     - 4.8%
     - 4.2%
     - 5%
     - 5.7%
     - 4.6%
     - 5.7%
     - 4.4%
     - 9.2%
     - 15%
     - 12%
     - 6%
     - 3.5%
     - 2.5%
     - 1.6%
     - 1.1%
   * - ``kitchen_fans_start_hour``
     - 0
     - 1
     - 2
     - 3
     - 4
     - 5
     - 6
     - 7
     - 8
     - 9
     - 10
     - 11
     - 12
     - 13
     - 14
     - 15
     - 16
     - 17
     - 18
     - 19
     - 20
     - 21
     - 22
     - 23

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``kitchen_fans_start_hour``
     - 
     - The hour of the day when the kitchen fans run.
.. _refrigerator:

Refrigerator
------------

Description
***********

The presence and rated efficiency of the primary refrigerator.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \Age of refrigerator converted to efficiency levels using ENERGYSTAR shipment-weighted efficiencies by year data from Home Energy Score: http://hes-documentation.lbl.gov/. Check the comments in: HES-Refrigerator_Age_vs_Efficiency.tsv


Assumption
**********

- \The current year is assumed to be 2022 (previously, it was 2016)

- \Previously, for each year, the EF values were rounded to the nearest EF level, and then the distribution of EF levels were calculated for the age bins. Currently, each year has its own distribution and then we average out the distributions to get the distribution for the age bins. EF for all years are weighted equally when calculating the average distribution for the age bins.

- \EnergyStar distributions from 2009 dependent on [Geometry Building Type RECS,Federal Poverty Level,Tenure] is used to calculate efficiency distribution in RECS2020.EnergyStar Refrigerators assumed to be 10% more efficient than standard.Due to low sampling count, the following coarsening rules are incorporated[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Vintage with Vintage ACS

  - \[5] Vintage with combined 1960s

  - \[6] Vintage with combined 1960s and post 200ss

  - \[7] Federal Poverty Level coarsened every 100 percent

  - \[8] Federal Poverty Level coarsened every 200 percent

  - \[9] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[10] Census Division RECS to Census Region

  - \[11] Census Region to National


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Refrigerator** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - EF 6.7
     - EF 10.2
     - EF 10.5
     - EF 15.9
     - EF 17.6
     - EF 19.9
     - EF 21.9
     - None
     - Void
   * - Stock saturation
     - 2.6%
     - 0.4%
     - 1.2%
     - 8.8%
     - 40%
     - 41%
     - 4.7%
     - 1.3%
     - 0%
   * - ``appliance_refrigerator_rated_annual_consumption``
     - 1139
     - 748
     - 727
     - 480
     - 434
     - 384
     - 348
     - 
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``appliance_refrigerator_rated_annual_consumption``
     - kWh/yr
     - The EnergyGuide rated annual energy consumption for the refrigerator.
.. _refrigerator_usage_level:

Refrigerator Usage Level
------------------------

Description
***********

Refrigerator energy usage level multiplier.

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \n/a


Assumption
**********

- \Engineering judgement


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Refrigerator Usage Level** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 95% Usage
     - 100% Usage
     - 105% Usage
   * - Stock saturation
     - 25%
     - 50%
     - 25%
   * - ``refrigerator_usage_multiplier``
     - 0.95
     - 1.0
     - 1.05

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``refrigerator_usage_multiplier``
     - 
     - Multiplier on the refrigerator energy usage that can reflect, e.g., high/low usage occupants.
.. _roof_material:

Roof Material
-------------

Description
***********

Roof material and color.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Multi-Family with 5+ Units is assigned 'Asphalt Shingles, Medium' only.

- \Due to low samples, Vintage ACS is progressively grouped into: pre-1960, 1960-1999, and 2000+.

- \Geometry Building Type RECS is progressively grouped into: Single-Family (including Mobile Home), and Multi-Family.

- \Census Division RECS is coarsened to Census Region.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Roof Material** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Asphalt Shingles, Medium
     - Composition Shingles
     - Metal, Dark
     - Slate
     - Tile, Clay or Ceramic
     - Tile, Concrete
     - Wood Shingles
   * - Stock saturation
     - 45%
     - 36%
     - 8.4%
     - 1.2%
     - 3.8%
     - 1.7%
     - 4.2%
   * - ``enclosure_roof_material_type``
     - asphalt or fiberglass shingles
     - asphalt or fiberglass shingles
     - metal surfacing
     - slate or tile shingles
     - slate or tile shingles
     - slate or tile shingles
     - wood shingles or shakes
   * - ``enclosure_roof_material_color``
     - medium
     - medium
     - dark
     - medium
     - medium
     - medium
     - medium

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_roof_material_type``
     - 
     - The type of roof material.
   * - ``enclosure_roof_material_color``
     - 
     - The color of the roof.
.. _state:

State
-----

Description
***********

The U.S. State the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **State** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - AK
     - AL
     - AR
     - AZ
     - CA
     - CO
     - CT
     - DC
     - DE
     - FL
     - GA
     - HI
     - IA
     - ID
     - IL
     - IN
     - KS
     - KY
     - LA
     - MA
     - MD
     - ME
     - MI
     - MN
     - MO
     - MS
     - MT
     - NC
     - ND
     - NE
     - NH
     - NJ
     - NM
     - NV
     - NY
     - OH
     - OK
     - OR
     - PA
     - RI
     - SC
     - SD
     - TN
     - TX
     - UT
     - VA
     - VT
     - WA
     - WI
     - WV
     - WY
   * - Stock saturation
     - 0.23%
     - 1.6%
     - 1%
     - 2.2%
     - 10%
     - 1.7%
     - 1.1%
     - 0.23%
     - 0.31%
     - 6.8%
     - 3.1%
     - 0.4%
     - 1%
     - 0.51%
     - 4%
     - 2.1%
     - 0.93%
     - 1.5%
     - 1.5%
     - 2.1%
     - 1.8%
     - 0.54%
     - 3.4%
     - 1.8%
     - 2%
     - 0.97%
     - 0.37%
     - 3.3%
     - 0.26%
     - 0.61%
     - 0.46%
     - 2.7%
     - 0.68%
     - 0.9%
     - 6.1%
     - 3.8%
     - 1.3%
     - 1.3%
     - 4.2%
     - 0.35%
     - 1.6%
     - 0.28%
     - 2.1%
     - 7.8%
     - 0.76%
     - 2.6%
     - 0.24%
     - 2.2%
     - 2%
     - 0.66%
     - 0.2%
   * - ``extra_refrigerator_usage_multiplier``
     - 1.80
     - 1.76
     - 1.90
     - 1.74
     - 1.86
     - 1.85
     - 1.96
     - 2.15
     - 1.68
     - 1.87
     - 1.74
     - 1.94
     - 1.77
     - 1.62
     - 1.82
     - 1.78
     - 1.77
     - 1.80
     - 1.88
     - 2.00
     - 1.94
     - 1.88
     - 1.73
     - 1.72
     - 1.76
     - 1.85
     - 1.69
     - 1.80
     - 1.73
     - 1.85
     - 1.90
     - 1.81
     - 1.90
     - 1.87
     - 1.91
     - 1.81
     - 1.86
     - 1.84
     - 1.73
     - 1.91
     - 1.83
     - 1.83
     - 1.86
     - 1.84
     - 1.78
     - 1.80
     - 1.82
     - 1.76
     - 1.74
     - 1.68
     - 1.80
   * - ``freezer_usage_multiplier``
     - 1.27
     - 1.34
     - 1.25
     - 1.09
     - 1.06
     - 1.06
     - 1.08
     - 1.21
     - 1.12
     - 1.04
     - 1.26
     - 1.21
     - 1.13
     - 1.38
     - 1.07
     - 1.25
     - 1.04
     - 1.19
     - 1.32
     - 1.06
     - 1.20
     - 1.09
     - 1.22
     - 1.27
     - 1.07
     - 1.34
     - 1.33
     - 1.10
     - 1.29
     - 1.19
     - 1.23
     - 1.05
     - 1.17
     - 1.02
     - 1.06
     - 1.12
     - 1.26
     - 1.39
     - 1.18
     - 0.97
     - 1.13
     - 1.37
     - 1.25
     - 1.18
     - 1.20
     - 1.14
     - 1.25
     - 1.14
     - 1.20
     - 1.15
     - 1.32

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``extra_refrigerator_usage_multiplier``
     - 
     - Multiplier on the extra refrigerator energy usage that can reflect, e.g., high/low usage occupants.
   * - ``freezer_usage_multiplier``
     - 
     - Multiplier on the freezer energy usage that can reflect, e.g., high/low usage occupants.
.. _state_metro_median_income:

State Metro Median Income
-------------------------

Description
***********

State Metro median income of the household occupying the dwelling unit.             This is different from State Median Income in that the Income Limits are differentiated by Metro and             Nonmetro portions of the state.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \% State Metro Median Income is calculated using annual household income in 2019USD (continuous, not binned) from 2019-5yrs PUMS data and 2019 state median income (SMI) by metro/nonmetro area from HUD. A County Metro Status-differentiated Income Limits table is derived from the SMI by adjusting for household size only, which is consistent with how HUD's published State Income Limits table is generated.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **State Metro Median Income** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - 0-30%
     - 30-60%
     - 60-80%
     - 80-100%
     - 100-120%
     - 120-150%
     - 150%+
     - Not Available
   * - Stock saturation
     - 11%
     - 15%
     - 9.5%
     - 8.7%
     - 7.7%
     - 9.5%
     - 27%
     - 12%

.. _tenure:

Tenure
------

Description
***********

The tenancy (owner or renter) of the household occupying the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \In ACS, Tenure is reported for occupied units only. By excluding Vacancy Status as a dependency, we assume vacant units share the same Tenure distribution as occupied units. Where sample counts are less than 10 (464 / 11680 rows), the Census Division by PUMA Metro Status average distribution has been inserted. 'Mobile Home' does not exist in DC and is replaced by 'Single-Family Detached'.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Tenure** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Not Available
     - Owner
     - Renter
   * - Stock saturation
     - 12%
     - 56%
     - 32%

.. _usage_level:

Usage Level
-----------

Description
***********

Usage of major appliances relative to the national average.

Created by
**********

manually created

Source
******

- \Engineering Judgement, Calibration


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Usage Level** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Low
     - Medium
     - High
     - Average
   * - Stock saturation
     - 25%
     - 50%
     - 25%
     - 0%

.. _vacancy_status:

Vacancy Status
--------------

Description
***********

The vacancy status (occupied or vacant) of the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \Where sample counts are less than 10 (434 / 11680 rows), the State average distribution has been inserted. 'Mobile Home' does not exist in DC and is replaced by 'Single-Family Detached'.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Vacancy Status** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Occupied
     - Vacant
   * - Stock saturation
     - 88%
     - 12%
   * - ``schedules_vacancy_periods``
     - 
     - Jan 1 - Dec 31

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``schedules_vacancy_periods``
     - 
     - Specifies the vacancy periods. Enter a date like "Dec 15 - Jan 15". Optionally, can enter hour of the day like "Dec 15 2 - Jan 15 20" (start hour can be 0 through 23 and end hour can be 1 through 24). If multiple periods, use a comma-separated list.
.. _vintage:

Vintage
-------

Description
***********

Time period in which the building was constructed.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \Where sample counts are less than 10 (812 / 21024 rows), the State average distribution has been inserted. 'Mobile Home' does not exist in DC and is replaced by 'Single-Family Detached'.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Vintage** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - <1940
     - 1940s
     - 1950s
     - 1960s
     - 1970s
     - 1980s
     - 1990s
     - 2000s
     - 2010s
   * - Stock saturation
     - 13%
     - 4.9%
     - 10%
     - 11%
     - 15%
     - 13%
     - 14%
     - 14%
     - 5.1%
   * - ``vintage``
     - <1940
     - 1940s
     - 1950s
     - 1960s
     - 1970s
     - 1980s
     - 1990s
     - 2000s
     - 2010s

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``vintage``
     - 
     - The building vintage, used for informational purposes only.
.. _vintage_acs:

Vintage ACS
-----------

Description
***********

Time period in which the dwelling unit was constructed as defined by the U.S. Census American Community Survey.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Vintage ACS** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - <1940
     - 1940-59
     - 1960-79
     - 1980-99
     - 2000-09
     - 2010s
   * - Stock saturation
     - 13%
     - 15%
     - 26%
     - 27%
     - 14%
     - 5.1%

.. _water_heater_efficiency:

Water Heater Efficiency
-----------------------

Description
***********

The efficiency, type, and heating fuel of water heater.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \(Heat pump water heaters) 2016-17 RBSA II for WA and OR and Butzbaugh et al. 2017 US HPWH Market Transformation - Where We've Been and Where to Go Next for remainder of regions

- \Penetration of HPWH for Maine (6.71%) calculated based on total number of HPWH units (AWHI Stakeholder Meeting 12/08/2022) and total housing units https://www.census.gov/quickfacts/ME


Assumption
**********

- \Water heater blanket is used as a proxy for premium storage tank water heaters.

- \Heat Pump Water Heaters are added in manually as they are not in the survey.

- \Default solar thermal collector assumed: 40 sqft, Roof Pitch,

- \Solar thermal backup is informed by secondary water heater fuel type. Solar collector orientation is based on rooftop solar orientation for electric backup and assumed south-facing for fuel backup. If a solar thermal system has no secondary water heater or has a second solar thermal system, they are assumed to have electric backup.

- \Other Fuel water heater energy is modeled as coal

- \Due to low sample sizes, fallback rules applied with lumping of:

  - \[1] State: Census Division RECS

  - \[2] State: Census Region[3] State: National


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Water Heater Efficiency** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Electric Heat Pump, 3.5 UEF
     - Electric Premium
     - Electric Standard
     - Electric Tankless
     - FIXME Fuel Oil Indirect
     - Fuel Oil Premium
     - Fuel Oil Standard
     - Natural Gas Premium
     - Natural Gas Standard
     - Natural Gas Tankless
     - Other Fuel
     - Propane Premium
     - Propane Standard
     - Propane Tankless
     - Solar Thermal, 40 sqft, East, Roof Pitch, Electric Standard Backup
     - Solar Thermal, 40 sqft, North, Roof Pitch, Electric Standard Backup
     - Solar Thermal, 40 sqft, South, Roof Pitch, Electric Standard Backup
     - Solar Thermal, 40 sqft, South, Roof Pitch, Fuel Oil Standard Backup
     - Solar Thermal, 40 sqft, South, Roof Pitch, Natural Gas Standard Backup
     - Solar Thermal, 40 sqft, South, Roof Pitch, Propane Standard Backup
     - Solar Thermal, 40 sqft, West, Roof Pitch, Electric Standard Backup
     - Wood
   * - Stock saturation
     - 0.31%
     - 9.9%
     - 36%
     - 2%
     - 0.72%
     - 0.47%
     - 1.4%
     - 8.3%
     - 33%
     - 2.9%
     - 0.044%
     - 0.63%
     - 2.4%
     - 0.92%
     - 0.037%
     - 0.004%
     - 0.093%
     - 0.00032%
     - 0.002%
     - 0.0058%
     - 0.022%
     - 0.076%
   * - ``dhw_water_heater_type``
     - heat pump water heater
     - storage water heater
     - storage water heater
     - instantaneous water heater
     - storage water heater
     - storage water heater
     - storage water heater
     - storage water heater
     - storage water heater
     - instantaneous water heater
     - storage water heater
     - storage water heater
     - storage water heater
     - instantaneous water heater
     - storage water heater
     - storage water heater
     - storage water heater
     - storage water heater
     - storage water heater
     - storage water heater
     - storage water heater
     - storage water heater
   * - ``dhw_water_heater_fuel_type``
     - electricity
     - electricity
     - electricity
     - electricity
     - fuel oil
     - fuel oil
     - fuel oil
     - natural gas
     - natural gas
     - natural gas
     - coal
     - propane
     - propane
     - propane
     - electricity
     - electricity
     - electricity
     - fuel oil
     - natural gas
     - propane
     - electricity
     - wood
   * - ``dhw_water_heater_efficiency_type``
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
     - UniformEnergyFactor
   * - ``dhw_water_heater_efficiency``
     - 3.5
     - 0.94
     - 0.92
     - 0.94
     - 0.64
     - 0.67
     - 0.64
     - 0.7
     - 0.6
     - 0.82
     - 0.6
     - 0.67
     - 0.6
     - 0.82
     - 0.92
     - 0.92
     - 0.92
     - 0.64
     - 0.6
     - 0.6
     - 0.92
     - 0.6
   * - ``dhw_solar_thermal_collector_loop_type``
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - liquid indirect
     - liquid indirect
     - liquid indirect
     - liquid indirect
     - liquid indirect
     - liquid indirect
     - liquid indirect
     - 
   * - ``dhw_solar_thermal_collector_type``
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - single glazing black
     - single glazing black
     - single glazing black
     - single glazing black
     - single glazing black
     - single glazing black
     - single glazing black
     - 
   * - ``dhw_solar_thermal_collector_area``
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 40
     - 40
     - 40
     - 40
     - 40
     - 40
     - 40
     - 
   * - ``dhw_solar_thermal_collector_rated_optical_efficiency``
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 0.77
     - 0.77
     - 0.77
     - 0.77
     - 0.77
     - 0.77
     - 0.77
     - 
   * - ``dhw_solar_thermal_collector_rated_thermal_losses``
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 0.793
     - 0.793
     - 0.793
     - 0.793
     - 0.793
     - 0.793
     - 0.793
     - 
   * - ``dhw_solar_thermal_storage_volume``
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 
     - 60
     - 60
     - 60
     - 60
     - 60
     - 60
     - 60
     - 
   * - ``dhw_solar_thermal_direction_collector_azimuth``
     - 180
     - 180
     - 180
     - 180
     - 180
     - 180
     - 180
     - 180
     - 180
     - 180
     - 180
     - 180
     - 180
     - 180
     - 90
     - 0
     - 180
     - 180
     - 180
     - 180
     - 270
     - 180
   * - ``dhw_water_heater_jacket_rvalue``
     - 0
     - 0
     - 0
     - 0
     - 0
     - 0
     - 0
     - 0
     - 0
     - 0
     - 0
     - 0
     - 0
     - 0
     - 6.2
     - 6.2
     - 6.2
     - 0
     - 0
     - 0
     - 6.2
     - 0

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``dhw_water_heater_type``
     - 
     - The type of water heater.
   * - ``dhw_water_heater_fuel_type``
     - 
     - The fuel type of the water heater.
   * - ``dhw_water_heater_efficiency_type``
     - 
     - The efficiency type of the water heater. Does not apply to space-heating boilers.
   * - ``dhw_water_heater_efficiency``
     - frac
     - EnergyGuide Label rated Uniform Energy Factor (UEF) or Energy Factor (EF).
   * - ``dhw_solar_thermal_collector_loop_type``
     - 
     - The loop type of the solar thermal system.
   * - ``dhw_solar_thermal_collector_type``
     - 
     - The type of collector.
   * - ``dhw_solar_thermal_collector_area``
     - ft2
     - The surface area for the collector.
   * - ``dhw_solar_thermal_collector_rated_optical_efficiency``
     - frac
     - FRTA (y-intercept) from the Directory of SRCC OG-100 Certified Solar Collector Ratings.
   * - ``dhw_solar_thermal_collector_rated_thermal_losses``
     - Btu/hr-ft2-F
     - FRUL (slope) from the Directory of SRCC OG-100 Certified Solar Collector Ratings
   * - ``dhw_solar_thermal_storage_volume``
     - gal
     - Hot water storage volume.
   * - ``dhw_solar_thermal_direction_collector_azimuth``
     - deg
     - The azimuth of the solar thermal system collectors. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).
   * - ``dhw_water_heater_jacket_rvalue``
     - h-ft^2-R/Btu
     - The jacket R-value of the storage water heater.
.. _water_heater_fuel:

Water Heater Fuel
-----------------

Description
***********

The water heater fuel type.

Created by
**********

``sources/recs/recs2020/tsv_maker.py and sources/aris/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \Alaska specific distribution is based on Alaska Retrofit Information System (2008 to 2022) maintained by Alaska Housing Finance Corporation.


Assumption
**********

- \After conversations with EIA, other fuel is a combination of units with no-water heater, biomass, coal, or district steam systems.

- \Due to low sample sizes, fallback rules applied with lumping of:

  - \[1] Geometry building SF: Mobile, Single family attached, Single family detached

  - \[2] Geometry building MF: Multi-Family with 2 - 4 Units, Multi-Family with 5+ Units

  - \[3] State: Census Division RECS

  - \[4] State: Census Region

  - \[5] State: National

- \For Alaska, we are using a field in ARIS that lumps multi-family 2-4 units and multi-family 5+ units buildings together. Data from the American Community Survey is used to distribute the between these two building types.

- \For Alaska, wood and coal heating is modeled as other fuel.

- \For Alaska, when a building uses more than one fuel for water heating, the fuel with highest consumption is considered the water heater fuel. Rest of the fuels are ignored.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Water Heater Fuel** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Electricity
     - Fuel Oil
     - Natural Gas
     - Other Fuel
     - Propane
     - Solar Thermal
     - Wood
   * - Stock saturation
     - 48%
     - 2.6%
     - 45%
     - 0.044%
     - 3.9%
     - 0.16%
     - 0.076%

.. _water_heater_in_unit:

Water Heater In Unit
--------------------

Description
***********

Individual water heater present or not present in the dwelling unit that solely serves the specific dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Single-Family Detached and Mobile Homes have in unit water heaters.

- \As Not Applicable option for Single-Family Attached option is 100%

- \Assuming Single-Family Attached in-unit water heater distribution from RECS 2009

- \Due to low sample sizes, fallback rules applied with lumping of:

  - \[1] State: Census Division RECS

  - \[2] Vintage ACS: Combining Vintage pre 1960s and post 2000

  - \[3] State: Census Region


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Water Heater In Unit** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - No
     - Yes
   * - Stock saturation
     - 14%
     - 86%

.. _water_heater_location:

Water Heater Location
---------------------

Description
***********

location of water heater.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \H2OMAIN = other is equally distributed amongst attic and crawlspace.

- \H2OMAIN does not apply to multi-family, therefore Water heater location for multi-family with in-unit water heater is taken after the combined distribution of other building types.

- \out-of-unit water heater is assumed to be in Conditioned Mechanical Room. Per expert judgement, water heaters can not be outside or in vented spaces for IECC Climate Zones 4-8 due to pipe-freezing risk.

- \Where samples < 10, data is aggregated in the following order:

- \1. Building Type lumped into single-family, multi-family, and mobile home.

- \2. 1 + Foundation Type combined. 3. 2 + Attic Type combined

- \4. 3 + Garage combined.

- \5. Single-/Multi-Family + Foundation combined + Attic combined + Garage combined.

- \6. 5 + pre-1960 combined.

- \7. 5 + pre-1960 combined / post-2020 combined.

- \8. 7 + IECC Climate Zone lumped into: 1-2+3A, 3B-3C, 4, 5, 6, 7 except AK, 7AK-8AK.

- \9. 7 + IECC Climate Zone lumped into: 1-2-3, 4-8.


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Water Heater Location** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Attic
     - Conditioned Mechanical Room
     - Crawlspace
     - Garage
     - Heated Basement
     - Living Space
     - Outside
     - Unheated Basement
   * - Stock saturation
     - 0.87%
     - 14%
     - 0.18%
     - 15%
     - 11%
     - 43%
     - 7.1%
     - 8.7%
   * - ``dhw_water_heater_location_location``
     - attic
     - other heated space
     - crawlspace
     - garage
     - basement
     - conditioned space
     - other exterior
     - basement

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``dhw_water_heater_location_location``
     - 
     - The location of the water heater.
.. _window_areas:

Window Areas
------------

Description
***********

Window to wall ratios of the front, back, left, and right walls.

Created by
**********

``sources/rbsa_II/tsv_maker.py``

Source
******

- \2016-17 Residential Building Stock Assessment (RBSA) II microdata.


Assumption
**********

- \The window to wall ratios (WWR) are exponential weibull distributed.

- \Multi-Family with 2-4 Units distributions are independent of Geometry Stories

- \Multi-Family with 5+ Units distributions are grouped by 1-3 stories, 4-7 stories, and 8+ stories

- \High-rise Multi-family buildings (8+ stories) have a 30% window to wall ratio (WWR)

- \SFD, SFA, and Mobile Homes are represented by the SFD window area distribution


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Window Areas** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - F6 B6 L6 R6
     - F9 B9 L9 R9
     - F12 B12 L12 R12
     - F15 B15 L15 R15
     - F18 B18 L18 R18
     - F30 B30 L30 R30
   * - Stock saturation
     - 7.8%
     - 25%
     - 25%
     - 16%
     - 17%
     - 8.9%
   * - ``geometry_window_areas_or_wwrs``
     - 0.06, 0.06, 0.06, 0.06
     - 0.09, 0.09, 0.09, 0.09
     - 0.12, 0.12, 0.12, 0.12
     - 0.15, 0.15, 0.15, 0.15
     - 0.18, 0.18, 0.18, 0.18
     - 0.30, 0.30, 0.30, 0.30

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``geometry_window_areas_or_wwrs``
     - ft2 or frac
     - The amount of window area on the unit's front/back/left/right facades. Use a comma-separated list like '0.2, 0.2, 0.1, 0.1' to specify Window-to-Wall Ratios (WWR) or '108, 108, 72, 72' to specify absolute areas. If a facade is adiabatic, the value will be ignored.
.. _windows:

Windows
-------

Description
***********

Construction type and efficiency levels of windows.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Wood and Vinyl are considered same material

- \Triple Pane assumed to be 100% low-e

- \Only breaking out clear and low-e windows for the Double, Non-Metal frame type

- \Source of low-e distribution is based on engineering judgement, informed by high-levelsales trends observed in Ducker Worldwide studies of the U.S. Market for Windows, Doors and Skylights.

- \Due to low sample sizes, the following adjustments are made:

  - \[1] Vintage data are grouped into: 1) <1960, 2) 1960-79, 3) 1980-99, 4) 2000s, 5) 2010s.

  - \[2] Building Type data are grouped into: 1) Single-Family Detached, Single-Family Attached, and Mobile homes and 2) Multi-Family 2-4 units and Multi-Family 5+ units.

  - \[3] Climate zones are grouped into: 1) 1A, 2A, 2B

- \2) 3A, 3B, 3C, 4B

- \3) 4A, 4C

- \4) 5A, 5B

- \5) 6A, 6B

- \and 6) 7A, 7B 7AK, 8AK.

  - \[4] Federal Poverty Levels are progressively grouped together until all bins are combined.

  - \[5] Tenure options are progressively grouped together until all bins are combined.

- \Storm window saturations are based on D&R International, Ltd. 'Residential Windows and Window Coverings: A Detailed View of the Installed Base and User Behavior' 2013. https://www.energy.gov/sites/prod/files/2013/11/f5/residential_windows_coverings.pdf. Cut the % storm windows by factor of 55% because only 55% of storms are installed year round

- \Due to lack of performance data storm windows with triple-pane are modeled without the storm windows

- \Due to lack of performance data Double-pane, Low-E, Non-Metal, Air, M-gain, Exterior Clear Storm windows are modeled as Double-pane, Clear, Non-Metal, Air, Exterior Clear Storm windows


Options
*******

From ``project_national`` the list of options, option stock saturation, and option properties for the **Windows** characteristic.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: auto

   * - Option name
     - Double, Clear, Metal, Air
     - Double, Clear, Metal, Air, Exterior Clear Storm
     - Double, Clear, Non-metal, Air
     - Double, Clear, Non-metal, Air, Exterior Clear Storm
     - Double, Low-E, Non-metal, Air, M-Gain
     - Single, Clear, Metal
     - Single, Clear, Metal, Exterior Clear Storm
     - Single, Clear, Non-metal
     - Single, Clear, Non-metal, Exterior Clear Storm
     - Triple, Low-E, Non-metal, Air, L-Gain
     - Void
   * - Stock saturation
     - 19%
     - 1.5%
     - 19%
     - 3.5%
     - 22%
     - 14%
     - 0.99%
     - 17%
     - 1.5%
     - 1.8%
     - 0%
   * - ``enclosure_window_u_factor``
     - 0.76
     - 0.76
     - 0.49
     - 0.49
     - 0.38
     - 1.16
     - 1.16
     - 0.84
     - 0.84
     - 0.29
     - 
   * - ``enclosure_window_shgc``
     - 0.67
     - 0.67
     - 0.56
     - 0.56
     - 0.44
     - 0.76
     - 0.76
     - 0.63
     - 0.63
     - 0.26
     - 
   * - ``enclosure_window_exterior_shading_type``
     - not present
     - not present
     - not present
     - not present
     - not present
     - not present
     - not present
     - not present
     - not present
     - not present
     - 
   * - ``enclosure_window_storm_glass_type``
     - 
     - clear
     - 
     - clear
     - 
     - 
     - clear
     - 
     - clear
     - 
     - 

Properties
**********

.. list-table::
   :header-rows: 1
   :stub-columns: 1

   * - Name
     - Units
     - Description
   * - ``enclosure_window_u_factor``
     - Btu/hr-ft2-F
     - Full-assembly NFRC U-factor.
   * - ``enclosure_window_shgc``
     - 
     - Full-assembly NFRC solar heat gain coefficient.
   * - ``enclosure_window_exterior_shading_type``
     - 
     - The type of window exterior shading.
   * - ``enclosure_window_storm_glass_type``
     - 
     - Type of storm window glass.
