=====================
Development Changelog
=====================

.. changelog::
    :version: pending
    :released: pending

    .. change::
        :tags: software, openstudio, feature, hvac
        :pullreq: 1406

        **Date**: 2025-09-05

        Title:
        Latest OS-HPXML

        Description:
        Update to OpenStudio-HPXML 1.10/OpenStudio 3.10/EnergyPlus 25.1.
        Replace use of energyPlusOutputRequests with modelOutputRequests in reporting measures.
        Update HVAC models per RESNET HVAC addendum, including allowing detailed performance data for 1 and 2 -speed models, as well as requiring nominal iputs for detailed performance data approach.
        Inform whether the clothes dryer appliance is vented or ventless using new optional drying method argument.

        OpenStudio-HPXML: `pull request 1879 <https://github.com/NREL/OpenStudio-HPXML/pull/1879>`_, `pull request 1939 <https://github.com/NREL/OpenStudio-HPXML/pull/1939>`_, `pull request 2028 <https://github.com/NREL/OpenStudio-HPXML/pull/2028>`_

        Assignees: Joe Robertson, Scott Horowitz
