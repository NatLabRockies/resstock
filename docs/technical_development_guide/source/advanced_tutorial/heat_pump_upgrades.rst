Heat Pump Upgrades
==================

The following information is relevant for when a heat pump -related upgrade is defined in a project definition file.

Types of Backup
---------------

The ResStock workflow allows modeling heat pumps with either "integrated" or "separate" backup heating.
Definitions for each are given below.
See `HPXML Heat Pumps <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#hpxml-heat-pumps>`_ for more information.

- **integrated**: the heat pump’s distribution system and blower fan power applies to the backup heating (e.g., built-in electric strip heat or an integrated backup furnace, i.e., a dual-fuel heat pump).
- **separate**: the backup system has its own distribution system (e.g., electric baseboard or a boiler).

Lockout Temperatures
--------------------

The ResStock workflow allows for controlling the compressor and/or backup heating lockout temperatures.
Definitions for each are given below.
See the `Backup <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#backup>`_ section of the OpenStudio-HPXML documentation for more information.

- **compressor**: minimum outdoor temperature for compressor operation.
- **backup heating**: maximum outdoor temperature for backup operation.

For example, a heat pump upgrade option could be defined with a compressor lockout temperature of 5F and a backup heating lockout temperature of 40F.
See below the argument assignments that would need to be added to the ``options_lookup.tsv`` file.
These values would override the OpenStudio-HPXML defaults.

.. code::

  heat_pump_compressor_lockout_temp=5
  heat_pump_backup_heating_lockout_temp=40

Replacement Scenarios
---------------------

When defining a heat pump upgrade, the new heat pump can:

- :ref:`replace_the_existing_primary_heating_cooling_system`
- :ref:`retain_the_existing_primary_heating_system_as_backup`

.. _replace_the_existing_primary_heating_cooling_system:

Replace the Existing Primary Heating/Cooling System
***************************************************

TODO: intro, including something about backup?

For example:

.. code-block:: yaml

  - upgrade_name: ASHP
    options:
      - option: HVAC Heating Efficiency|ASHP, SEER 22, 10 HSPF
        apply_logic:
          - HVAC Has Ducts|Yes
        costs:
          - value: 50.0
            multiplier: Size, Heating System Primary (kBtu/h)
        lifetime: 30
      - option: HVAC Cooling Efficiency|Ducted Heat Pump

.. _retain_the_existing_primary_heating_system_as_backup:

Retain the Existing Primary Heating System as Backup
****************************************************

Use the ``Heat Pump Backup|Use Existing System`` option from the lookup to retain the existing primary heating system as backup.

In this case, all properties of the existing primary system are retained as properties of the heat pump backup heating system.
The following properties are retained:

- fuel type
- efficiency
- capacity
- autosizing factor

For example:

.. code-block:: yaml

  - upgrade_name: ASHP
    options:
      - option: HVAC Heating Efficiency|ASHP, SEER 22, 10 HSPF
        apply_logic:
          - HVAC Has Ducts|Yes
        costs:
          - value: 50.0
            multiplier: Size, Heating System Primary (kBtu/h)
        lifetime: 30
      - option: HVAC Cooling Efficiency|Ducted Heat Pump
      - option: Heat Pump Backup|Use Existing System

For this scenario, the type of the backup is automatically determined based on information in the table below:

  ============= ============= =========== =============================
  New Heat Pump Backup System Backup Type Example
  ============= ============= =========== =============================
  ducted        ducted        integrated  ASHP w/Furnace [#]_
  ducted        ductless      separate    ASHP w/Boiler
  ductless      ducted        separate    Ductless MSHP w/Furnace
  ductless      ductless      separate    Ductless MSHP w/Boiler
  ============= ============= =========== =============================

 .. [#] When furnace is fuel-fired (i.e., non-electric).
        When furnace is electric, it likely wouldn't be used as integrated backup.

Other situations and considerations:

- The existing primary system does not become backup to the heat pump when:

  - the primary system is a heat pump
  - the primary system is a shared system

- When an existing secondary system exists:

  - it remains secondary if the heat pump upgrade is integrated backup
  - it is removed if the heat pump upgrade is separate backup

Sizing Methodologies
--------------------

When defining a heat pump upgrade, the new heat pump can be sized according to:

- :ref:`acca`
- :ref:`hers`
- :ref:`max_load`
- :ref:`duct_restriction`

See `HPXML HVAC Sizing Control <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#hpxml-hvac-sizing-control>`_ for more information.

.. _acca:

ACCA Manual J/S
***************

Meet the cooling load with some oversizing allowances (e.g., 30% for VSHPs, otherwise 15%, in cold climates).

.. _hers:

HERS
****

This is the default sizing methodology.
TODO: same as ACCA, except...

.. _max_load:

Max Load
********

Uses the larger of the heating/cooling design loads.

.. _duct_restriction:

Duct Restriction
****************

Use the ``HVAC Distribution|Use Duct Restriction`` option from the lookup to use autosizing limits and maintain the existing duct system curve.

ResStock currently assumes the existing home's duct system for HVAC equipment upgrades.
Without restricting the upgraded equipment's capacity to the maximum of the existing duct system's heating/cooling airflow rate divided by 400 cfm/ton, fan pressure rise increases and results in higher power use.
This is avoided by limiting the upgraded equipment's capacity based on the existing duct system.

Additionally, the blower fan efficiency (W/cfm) is adjusted based on baseline model inputs to assume the duct system curve does not change pre- and post- heat pump installation.

For example:

.. code-block:: yaml

  - upgrade_name: ASHP
    options:
      - option: HVAC Heating Efficiency|ASHP, SEER 22, 10 HSPF
        apply_logic:
          - HVAC Has Ducts|Yes
        costs:
          - value: 50.0
            multiplier: Size, Heating System Primary (kBtu/h)
        lifetime: 30
      - option: HVAC Cooling Efficiency|Ducted Heat Pump
      - option: HVAC Distribution|Use Duct Restriction

.. include:: ../../../../project_national/sdr_upgrades_tmy3.yml
   :code: text
   :start-after: ### --- Duct Restricted ENERGY STAR heat pump with elec backup
   :end-before: ### --- High efficiency cold-climate heat pump with elec backup
