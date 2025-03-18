=====================
Development Changelog
=====================

.. changelog::
    :version: v3.5.0
    :released: pending


    .. change::
        :tags: workflow, feature
        :pullreq: 1359

        **Date**: 2025-03-18

        Title:
        Latest OS-HPXML

        Description:
        Pulls in the ability to do electric panel NEC calculations.
        Update AC/ASHP/MSHP options in lookup since CompressorType is now required for central and mini-split air conditioners and heat pumps.

        OpenStudio-HPXML: `pull request 1946 <https://github.com/NREL/OpenStudio-HPXML/pull/1946>`_, `pull request 1949 <https://github.com/NREL/OpenStudio-HPXML/pull/1949>`_

        Assignees: Joe Robertson, Scott Horowitz


    .. change::
        :tags: docs, technical reference guide
        :pullreq: 1361

        **Date**: 2025-03-12

        Title:
        Update Technical Reference Guide from 3.3.0 to develop

        Description:
        Update the Technical Reference Guide based on the PRs from the split-off point of ResStock Release 3.3.0 to current develop.

        Assignees: Anthony Fontanini


    .. change::
        :tags: workflow, bugfix
        :pullreq: 1353

        **Date**: 2025-03-11

        Title:
        Latest OS-HPXML

        Description:
        All OpenStudio-HPXML changes, no required ResStock changes.
        Updates to NEEP ASHP sample files, fix possible HVAC sizing error, HPXML class update for attic/foundation types, speed up weather processing, combi boiler error fix, smooth schedule EV plugload, shift all schedules in sync and fix occupancy aggregation.

        Assignees: Joe Robertson


    .. change::
        :tags: characteristics, feature, docs, technical reference guide, outputs
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
        Add Hawaii in all TSVs - includes a change to PV System Size.tsv to give samples to Hawaii in anticipation of adding to Hawaii to Has PV.tsv. Update TRG to include Hawaii.

        resstock-estimation: `pull request 441 <https://github.com/NREL/resstock-estimation/pull/441>`

        Assignees: Janet Reyna


    .. change::
        :tags: docs, technical development guide
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
        :tags: ci, docs, technical reference guide, technical development guide
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
        Use 2017-2019 AHS data to create Misc Well Pump distribution (~11% nationally) with respect to geography/urbanity, building type, and foundation type. Previously well pump was randomly assigned via a manually created distribution.

        resstock-estimation: `pull request 437 <https://github.com/NREL/resstock-estimation/pull/437>`_

        Assignees: Lixi Liu


    .. change::
        :tags: characteristics, pool heater
        :pullreq: 1324

        **Date**: 2024-12-03

        Title:
        Add heat pump pool heaters

        Description:
        Add heat pump pool heaters to baseline.

        resstock-estimation: `pull request 436 <https://github.com/NREL/resstock-estimation/pull/436>`_

        Assignees: Janet Reyna
