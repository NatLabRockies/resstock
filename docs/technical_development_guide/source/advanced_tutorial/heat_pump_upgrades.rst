Heat Pump Upgrades
==================

The following information is relevant for when a heat pump -related upgrade is defined in a project definition file.

Types of Backup
---------------

The ResStock workflow allows modeling heat pumps with either "integrated" or "separate" backup heating.
Definitions for each are given below.
See `HPXML Heat Pumps <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#hpxml-heat-pumps>`_ for more information.

- *integrated*: the heat pump’s distribution system and blower fan power applies to the backup heating (e.g., built-in electric strip heat or an integrated backup furnace, i.e., a dual-fuel heat pump).
- *separate*: the backup system has its own distribution system (e.g., electric baseboard or a boiler).

Lockout Temperatures
--------------------

The ResStock workflow allows for controlling the compressor and/or backup heating lockout temperatures.
Definitions for each are given below.
See the `Backup <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#backup>`_ section of the OpenStudio-HPXML documentation for more information.

- *compressor*: minimum outdoor temperature for compressor operation.
- *backup heating*: maximum outdoor temperature for backup operation.

For example, a heat pump upgrade option could be defined with a compressor lockout temperature of 5F and a backup heating lockout temperature of 40F.
See below the argument assignments that would need to be added to the ``options_lookup.tsv`` file.
These values would override the OpenStudio-HPXML defaults.

.. code::

  heat_pump_compressor_lockout_temp=5
  heat_pump_backup_heating_lockout_temp=40

Replacement Scenarios
---------------------

When defining a heat pump upgrade, the new heat pump can either (a) replace the primary (existing) system, or (b) retain the primary (existing) system as its backup heating system.
In the latter case, all properties (e.g., capacity) of the primary (existing) system are retained as properties of the heat pump backup heating system.

Replace Primary System with New Heat Pump
*****************************************

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

Primary System becomes Backup to New Heat Pump
**********************************************

Set ``heat_pump_backup_use_existing_system=true`` for ``HVAC Heating Efficiency`` options in the lookup to retain the primary (existing) heating system as backup to the heat pump.
The following properties of the existing heating system are retained:

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

For this scenario, the type of the backup is (automatically) determined based on information in the table below:

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

- The primary (existing) system does not become backup to the heat pump when:

  - the primary system is a heat pump
  - the primary system is a shared system

- When a secondary (existing) system exists:

  - it remains secondary if the heat pump upgrade is integrated backup
  - it is removed if the heat pump upgrade is separate backup
