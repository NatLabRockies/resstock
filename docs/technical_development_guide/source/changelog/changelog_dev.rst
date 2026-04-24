=====================
Development Changelog
=====================

.. changelog::
    :version: pending
    :released: pending

    .. change::
        :tags: feature, software, postprocessing
        :pullreq: 1529

        **Date**: 2026-04-22

        Title:
        Add baseline_validation tool to resstockpostproc

        Description:
        Adds a baseline validation tool that compares a ResStock baseline run against public data sources
        (EIA 861, EIA 176, RECS 2020, LRD) and generates an interactive comparison dashboard. Supports annual and
        monthly resolutions across U.S. Total, state, census division, building type, vintage, climate zone, and
        heating-fuel aggregations. A baseline-validation CI job runs the tool under --test on every PR and
        uploads the generated dashboard as a CI artifact for review.

        Assignees: Rajendra Adhikari

    .. change::
        :tags: workflow, options, hpxml
        :pullreq: 1460

        **Date**: 2025-10-28

        Title:
        Move BuildResidentialHPXML measure to option-based arguments

        Description:
        Refactors ResStock to use the new BuildResidentialHPXML measure, which now has ~100 options instead of ~600 detailed
        properties as arguments. Also moves much of the ResStock special sauce around configuring the HPXML models into the
        ResStockArgumentsPostHPXML measure. The options_lookup.tsv file is now significantly simpler.

        Assignees: Scott Horowitz

    .. change::
        :tags: feature, hvac
        :pullreq: 1516

        **Date**: 2025-10-24

        Title:
        Clean up baseline HVAC options

        Description:
        Continuing from PR 1503, cleaned up baseline HVAC options by switching to use SEER2 for CAC and SEER2/HSPF2 for ASHP.
        Some HVAC option efficiencies were modified to better align with OS-HPXML default relationships.

        Assignees: Lixi Liu, Scott Horowitz

    .. change::
        :tags: feature, hvac
        :pullreq: 1503

        **Date**: 2025-10-07

        Title:
        Clean up SDR yaml; tweak a few HVAC option

        Description:
        Removes unused options/anchors from the SDR yaml.
        Removes unused HVAC options from options_lookup.tsv.
        Proposes a few changes to HVAC options to align with proposed OS-HPXML options.

        Assignees: Scott Horowitz

    .. change::
        :tags: documentation, technical reference guide
        :pullreq: 1493, 1466, 1460

        **Date**: 2025-09-24

        Title:
        Update the documentation

        Description:
        Create a new script for creating options/arguments table tex files corresponding to each Parameter.
        This will help to automate creating many of the tables in the ResStock Technical Reference Documentation.

        Assignees: Joe Robertson

    .. change::
        :tags: software, openstudio, feature
        :pullreq: 1466

        **Date**: 2025-09-19

        Title:
        Improved options/modeling

        Description:
        Updates dishwasher, clothes washer, and clothes dryer options per ANSI/RESNET/ICC 301-2019 Addendum A.
        Replaces interior shading coefficients with physical shading descriptions.
        Updates water heater options to be UEF-based and reflective of AHRI products.
        Updates window options to separate out storm windows from base window U/SHGC; uses OS-HPXML storm window models.
        Updates shielding for SFA/MF units to match OS-HPXML defaults (well-shielded).
        Updates plug load sensible/latent fractions to match OS-HPXML defaults (from ANSI/RESNET/ICC 301).
        Updates CMU assembly R-values to reflect average of hollow & concrete-filled.
        Disables daylight saving time for Hawaii counties to match OS-HPXML defaults.
        Updates duct leakage to be 50% supply/50% return to match OS-HPXML defaults (from ANSI/RESNET/ICC 301).
        Updates ceiling fan options from assuming 1 ceiling fan in a home to using the OS-HPXML default (NumberofBedrooms + 1; from ANSI/RESNET/ICC 301).
        Updates SDR HPWH options to be UEF=3.5 and UEF=4.0.
        HPWH sizing logic moved to OS-HPXML.

        Assignees: Scott Horowitz

    .. change::
        :tags: software, openstudio, feature, hvac
        :pullreq: 1406

        **Date**: 2025-09-05

        Title:
        Latest OS-HPXML

        Description:
        Update to OpenStudio-HPXML 1.10/OpenStudio 3.10/EnergyPlus 25.1.
        Replace use of energyPlusOutputRequests with modelOutputRequests in reporting measures.
        Update HVAC models per RESNET HVAC addendum, including allowing detailed performance data for 1 and 2 -speed models, as well as requiring nominal inputs for detailed performance data approach.
        Inform whether the clothes dryer appliance is vented or ventless using new optional drying method argument.

        OpenStudio-HPXML: `pull request 1879 <https://github.com/NREL/OpenStudio-HPXML/pull/1879>`_, `pull request 1939 <https://github.com/NREL/OpenStudio-HPXML/pull/1939>`_, `pull request 2028 <https://github.com/NREL/OpenStudio-HPXML/pull/2028>`_

        Assignees: Joe Robertson, Scott Horowitz

    .. change::
        :tags: software, postprocessing
        :pullreq: 1483

        **Date**: 2025-09-09

        Title:
        Ensure deterministic order in pub results by sorting

        Description:
        The order of rows in the published results CSV files are now always sorted by building_id.

        Assignees: Rajendra Adhikari
