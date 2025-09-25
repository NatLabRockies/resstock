=====================
Development Changelog
=====================

.. changelog::
    :version: pending
    :released: pending

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

        OpenStudio-HPXML: `pull request 1879 <https://github.com/NREL/OpenStudio-HPXML/pull/1879>`_, `pull request 1939 <https://github.com/NREL/OpenStudio-HPXML/pull/1939>`_, `pull request 2028 <https://github.com/NREL/OpenStudio-HPXML/pull/2028>`_

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
