=====================
Development Changelog
=====================

.. changelog::
    :version: v3.5.0
    :released: pending

    .. change::
        :tags: postprocessing
        :pullreq: 1439

        **Date**: 2025-07-08

        Title:
        Postprocessing output data type fix

        Description:
        Ensure postprocessing output data type for applicability is boolean. Previously, it was string
        for upgrades and boolean for the baseline.

        Assignees: Rajendra Adhikari

    .. change::
        :tags: standard data release
        :pullreq: 1429, 1197

        **Date**: 2025-06-18

        Title:
        Use HVAC Detailed Performance Option for a Ducted ASHP

        Description:
        Introduce an ASHP upgrade measure for SDR that is a typical cold climate ducted air source heat pump with detailed performance data. This pull request uses a couple detailed HVAC performance options to define the curves for a ducted version of a variable speed cold climate ASHP. Options are added to `options_lookup.tsv` and the cold climate ASHP upgrade is added to `sdr_upgrades_tmy3.yml`.

        Assignees: Philip White, Joe Robertson, Anthony Fontanini


    .. change::
        :tags: standard data release
        :pullreq: 1429

        **Date**: 2025-06-11

        Title:
        Clean up the SDR yaml file

        Description:
        Clean up the SDR yaml file by moving anchors to the reference section of the yaml. Remove non-SDR upgrades for the 9/30/2025 release.

        Assignees: Anthony Fontanini


    .. change::
        :tags: workflow, feature
        :pullreq: 1408
        :tickets: 1154

        **Date**: 2025-06-17

        Title:
        Use Autosizing Limits and Maintain Duct System Curve

        Description:
        For ducted heat pump upgrades, adds the ability to limit the autosized heating/cooling capacity based on the existing duct system, and adjust the blower fan efficiency to maintain the duct system curve.
        This feature is enabled by using setting a new ResStockArguments measure argument `heat_pump_sizing_is_duct_limited=true` for HVAC Heating Efficiency options.

        OpenStudio-HPXML: `pull request 1584 <https://github.com/NREL/OpenStudio-HPXML/pull/1584>`_

        Assignees: Joe Robertson


    .. change::
        :tags: feature, standard data release
        :pullreq: 1398, 1412

        **Date**: 2025-05-20

        Title:
        SDR Integration Tests

        Description:
        Add ResStock post processing code to create publication version of the annual results and commit them for the minimal buildstock test result.

        Assignees: Rajendra Adhikari, Anthony Fontanini, Joe Robertson


    .. change::
        :tags: workflow
        :pullreq: 1385

        **Date**: 2025-05-15

        Title:
        Update electrical panel open breaker prediction

        Description:
        Update electrical panel open breaker prediction to account for EV charger presence.

        Assignees: Lixi Liu


    .. change::
        :tags: standard data release
        :pullreq: 1372, 1420

        **Date**: 2025-05-28

        Title:
        Two Speed and Variable Speed Geothermal Heat Pumps

        Description:
        Add/modify upgrades defined in the SDR yml file for single-speed, dual-speed (with and without light touch envelope), and variable-speed geothermal heat pumps (GHPs).
        Use the same package apply logic as ASHP, but only for dwelling units with ducts.

        OpenStudio-HPXML: `pull request 1878 <https://github.com/NREL/OpenStudio-HPXML/pull/1878>`_

        Assignees: Joe Robertson


    .. change::
        :tags: workflow, feature, outputs
        :pullreq: 1368

        **Date**: 2025-04-30

        Title:
        Latest OS-HPXML

        Description:
        Make EV charging/discharging unavailable during vacancy periods.
        Introduce new argument for including detailed zone conditions timeseries outputs (i.e., temperatures, humidities).

        OpenStudio-HPXML: `pull request 1967 <https://github.com/NREL/OpenStudio-HPXML/pull/1967>`_, `pull request 1982 <https://github.com/NREL/OpenStudio-HPXML/pull/1982>`_

        Assignees: Joe Robertson


    .. change::
        :tags: feature, standard data release
        :pullreq: 1384

        **Date**: 2025-04-29

        Title:
        SDR Upgrade Analysis

        Description:
        Implemented CI workflow for validating option application in SDR yaml and added checks to ensure all upgrade options have non-zero applicability.

        Assignees: Rajendra Adhikari, Anthony Fontanini


    .. change::
        :tags: characteristics, documentation, technical reference guide
        :pullreq: 1385

        **Date**: 2025-04-22

        Title:
        Update Hawaii PV 2023

        Description:
        Update PV data from EIA Form 861 2018 to 2023 to have latest information.

        Assignees: Janet Reyna


    .. change::
        :tags: characteristics, documentation, technical reference guide
        :pullreq: 1380

        **Date**: 2025-04-15

        Title:
        Hawaii cooling saturation

        Description:
        Remove fallback rules from Hawaii and to match technology saturation from RECS2020.

        Assignees: Janet Reyna

 
    .. change::
        :tags: bug fix
        :pullreq: 1362

        **Date**: 2025-04-18

        Title:
        Prevent ducted secondary heating when primary heating is ducted

        Description:
        OS-HPXML disallows multiple heating systems on a single distribution system and ResStock is not set up to have multiple distribution systems.
        Disallowing ducted secondary heating when primary heating is ducted will prevent this error.

        Assignees: Yingli Lou, Lixi Liu, Anthony Fontanini


    .. change::
        :tags: standard data release
        :pullreq: 1369

        **Date**: 2025-04-18

        Title:
        Add Electric Vehicle Demand Flexibility Upgrades

        Description:
        Add Electric Vehicle load flexibility upgrade measures to the Standard Data Release project file.

        Assignees: Rajendra Adhikari, Andrew Speake, Anthony Fontanini


    .. change::
        :tags: standard data release
        :pullreq: 1362

        **Date**: 2025-04-17

        Title:
        EE + Adoption meaure upgrades for EV SDR

        Description:
        Add electric vehicle addoption and electric vehicle efficiency upgrade measures to the SDR project file.

        Assignees: Philip White, Andrew Speake


    .. change::
        :tags: characteristics, documentation, technical reference guide
        :pullreq: 1379

        **Date**: 2025-04-06

        Title:
        Refrigeration correction factors

        Description:
        Assign state level correction factors for freezer and secondary refrigeration to account for the fact that homes can have more than 1 freezer and 2 refrigerators.
        This also corrects the freezer usage, which was previously assigned to match the national saturation of freezers.

        resstock-estimation: `pull request 447 <https://github.com/NREL/resstock-estimation/pull/447>`_

        Assignees: Lixi Liu, Anthony Fontanini


    .. change::
        :tags: characteristics, documentation
        :pullreq: 1377

        **Date**: 2025-04-09

        Title:
        Update HVAC Cooling Partial Space Conditioning for Hawaii

        Description:
        Update of HVAC Cooling Partial Space Conditioning.tsv to separate Hawaii and Miami and to allow for more partial space conditioning in Hawaii.

        Assignees: Janet Reyna


    .. change::
        :tags: characteristics, documentation, feature, technical reference guide, outputs
        :pullreq: 1356

        **Date**: 2025-04-06

        Title:
        Solar Hot Water

        Description:
        Break out Solar Thermal from Other Fuel for Water Heater Fuel, consolidate Solar Hot Water with Water Heater Efficiency, assign all solar hot water systems as roof pitch installed 40ft solar collectors with some orientation diversity.

        Assignees: Lixi Liu, Anthony Fontanini, Jeff Maguire


    .. change::
        :tags: characteristics, documentation
        :pullreq: 1374

        **Date**: 2025-04-05

        Title:
        Differentiate Hawaii in IECC Climate Zone 1A

        Description:
        Split out Hawaii and Florida in Climate Zone 1A to support Hawaii differentiation.

        resstock-estimation 

        Assignees: Janet Reyna

        
    .. change::
        :tags: standard data release, documentation, outputs, feature
        :pullreq: 1259

        **Date**: 2025-04-04

        Title:
        HVAC Load Flexibility

        Description:
        Introduce HVAC load flexibility capability to ResStockArgumentsPostHPXML measure.
        The measure, when asked for, modifies the heating and cooling setpoint to reduce heating and cooling load during peak period to reduce HVAC energy use.

        Assignees: Rajendra Adhikari


    .. change::
        :tags: standard data release, outputs
        :pullreq: 1371

        **Date**: 2025-04-01

        Title:
        Remove end-use emissions from SDR YAML outputs

        Description:
        ResStock SDR currently do not publish end-use emissions. ResStock SDR only publish totals and totals by fuel.
        In an effort to reduce the number of outputs, end-use emissions outputs have been removed from the SDR raw outputs.
        The end-use emissions can still be called out for testing purposes using.

        Assignees: Anthony Fontanini


    .. change::
        :tags: documentation, technical reference guide
        :pullreq: 1361

        **Date**: 2025-03-12

        Title:
        Update Technical Reference Guide from 3.3.0 to develop

        Description:
        Update the Technical Reference Guide based on the PRs from the split-off point of ResStock Release 3.3.0 to current develop.

        Assignees: Anthony Fontanini


    .. change::
        :tags: workflow, feature
        :pullreq: 1353

        **Date**: 2025-03-11

        Title:
        Latest OS-HPXML

        Description:
        All OpenStudio-HPXML changes, no required ResStock changes.
        Updates to NEEP ASHP sample files, fix possible HVAC sizing error, HPXML class update for attic/foundation types, speed up weather processing, combi boiler error fix, smooth shcedule EV plugload, shift all schedules in sync and fix occupancy aggregation.

        Assignees: Joe Robertson


    .. change::
        :tags: characteristics, feature, documentation, technical reference guide, outputs
        :pullreq: 1299

        **Date**: 2025-02-28

        Title:
        Electric Vehicles

        Description:
        Introduce EVs, including vehicle and charging stock characterization and assignment of EV battery modeling arguments.

        Assignees: Andrew Speake, Anthony Fontanini, Rajendra Adhikari


    .. change::
        :tags: workflow, feature, outputs
        :pullreq: 1347

        **Date**: 2025-02-19

        Title:
        Latest OS-HPXML

        Description:
        Allows requesting timeseries EnergyPlus output meters (e.g., --hourly "MainsWater:Facility"), similar to requesting EnergyPlus output variables.
        Adds new *net* peak electricity outputs that include PV.

        OpenStudio-HPXML: `pull request 1918 <https://github.com/NREL/OpenStudio-HPXML/pull/1918>`_, `pull request 1930 <https://github.com/NREL/OpenStudio-HPXML/pull/1930>`_

        Assignees: Joe Robertson, Scott Horowitz


    .. change::
        :tags: workflow, feature
        :pullreq: 929
        :tickets: 927

        **Date**: 2025-02-04

        Title:
        New ResStockArgumentsPostHPXML measure

        Description:
        This measure is introduced to the workflow for postprocessing the output of the BuildResidentialHPXML and BuildResidentialScheduleFile measures.
        In short, we can use generated schedules (e.g., occupant schedule) to create other detailed schedules (e.g., setpoint schedules).
        Currently, this is just a stubbed version of the measure -- future versions will actually take advantage of the new functionality.        

        Assignees: Joe Robertson, Rajendra Adhikari


    .. change::
        :tags: characteristics
        :pullreq: 1339

        **Date**: 2025-01-30

        Title:
        Add Hawaii to TSVs

        Description:
        Add Hawaii in all TSVs - includes a change to PV System Size.tsv to give samples to Hawaii in anticipation of adding to Hawaii to Has PV.tsv.
        Update TRG to include Hawaii.

        resstock-estimation: `pull request 441 <https://github.com/NREL/resstock-estimation/pull/441>`_

        Assignees: Janet Reyna


    .. change::
        :tags: documentation, technical development guide
        :pullreq: 1330

        **Date**: 2025-01-29

        Title:
        TDG: repository development, including subtree

        Description:
        Add a new "Repository Development" section to the Advanced Tutorial for describing syncing and testing OpenStudio-HPXML branches.
        Also, remove "Installer Setup" -- not sure how relevant this page is anymore.

        Assignees: Joe Robertson


    .. change::
        :tags: workflow, standard data release
        :pullreq: 1329
        :tickets: 1261

        **Date**: 2024-01-23

        Title:
        Add Standard Data Release YAML to GitHub Actions

        Description:
        Add an initial Standard Data Release (SDR) YAML file. Add the SDR upgrade file into CI tests to continue progress towards end-to-end testing.

        Assignees: Anthony Fontanini


    .. change::
        :tags: ci, documentation, technical reference guide, technical development guide
        :pullreq: 1338
        :tickets: resstock-estimation 437

        **Date**: 2025-01-11

        Title:
        Add ResStock Technical Reference Guide

        Description:
        Add the ResStock Technical Reference Guide to the repository and compile it on github actions to keep the pdf up to date.

        Assignees: Anthony Fontanini


    .. change::
        :tags: feature, characteristics
        :pullreq: 1325
        :tickets: resstock-estimation 437

        **Date**: 2024-12-30

        Title:
        Well pump distribution using AHS

        Description:
        Use 2017-2019 AHS data to create Misc Well Pump distribution (~11% nationally) with respect to geography/urbanity, building type, and foundation type.
        Previously well pump was randomly assigned via a manually created distribution.

        resstock-estimation: `pull request 437 <https://github.com/NREL/resstock-estimation/pull/437>`_

        Assignees: Lixi Liu


    .. change::
        :tags: characteristics, feature
        :pullreq: 1324

        **Date**: 2024-12-03

        Title:
        Add heat pump pool heaters

        Description:
        Add heat pump pool heaters to baseline.

        resstock-estimation: `pull request 436 <https://github.com/NREL/resstock-estimation/pull/436>`_

        Assignees: Janet Reyna
