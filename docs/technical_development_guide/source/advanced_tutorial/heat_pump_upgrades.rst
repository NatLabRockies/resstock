Heat Pump Upgrades
==================

The following information is relevant for when a heat pump -related upgrade is defined in a project definition file.

Types of Backup
---------------

The ResStock workflow allows modeling heat pumps with either "integrated" or "separate" backup heating.
Definitions for each are given below.
See `HPXML Heat Pumps <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#hpxml-heat-pumps>`_ for more information.

- :ref:`integrated_backup`
- :ref:`separate_backup` 

.. _integrated_backup:

Integrated
**********

The heat pump’s distribution system and blower fan power applies to the backup heating (e.g., built-in electric strip heat or an integrated backup furnace, i.e., a dual-fuel heat pump).

.. _separate_backup:

Separate
********

The backup system has its own distribution system (e.g., electric baseboard or a boiler).

Lockout Temperatures
--------------------

The ResStock workflow allows for controlling the compressor and/or backup heating lockout temperatures.
Definitions for each are given below.
See the `Backup <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#backup>`_ section of the OpenStudio-HPXML documentation for more information.

- :ref:`compressor_lockout` 
- :ref:`backup_heating_lockout`

For example, a heat pump upgrade option could be defined with a compressor lockout temperature of 5F and a backup heating lockout temperature of 40F (i.e., a 5F - 40F switchover band).
See the argument assignments below that would need to be added to the ``options_lookup.tsv`` file.
These values would override the OpenStudio-HPXML defaults.

.. code::

  heat_pump_compressor_lockout_temp=5
  heat_pump_backup_heating_lockout_temp=40

.. _compressor_lockout:

Compressor
**********

Minimum outdoor temperature for compressor operation.

.. _backup_heating_lockout:

Backup Heating
**************

Maximum outdoor temperature for backup operation.

Replacement Scenarios
---------------------

When defining a heat pump upgrade, the new heat pump can:

- :ref:`replace_the_existing_primary_heating_cooling_system`
- :ref:`retain_the_existing_primary_heating_system_as_backup`

.. _replace_the_existing_primary_heating_cooling_system:

Replace the Existing Primary Heating/Cooling System
***************************************************

Remove any existing heating or cooling systems, and replace with a heat pump.
Heat pump backup type, fuel type, efficiency, capacity, etc. may be specified using heat pump arguments named with the ``heat_pump_backup`` prefix.

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

Detailed Performance Data
-------------------------

Use the ``HVAC Detailed Performance Data`` option from the lookup to add specific performance data coefficients for a variable-speed heat pump.

Detailed performance data (i.e., capacity and COP coefficients) for minimum and maximum compressor speeds can be defined for a set of 5 outdoor temperatures.
See below the argument assignments that would need to be added to the ``options_lookup.tsv`` file.
These values would override the OpenStudio-HPXML defaults.
See `HPXML HVAC Detailed Perf. Data <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#hpxml-hvac-detailed-perf-data>`_ for more information.

.. code::

  hvac_perf_data_heating_outdoor_temperatures=67.0, 47.0, 17.0, 5.0, -15.0	
  hvac_perf_data_heating_min_speed_capacities=0.423, 0.308, 0.353, 0.371, 0.331	
  hvac_perf_data_heating_max_speed_capacities=1.387, 1.028, 0.766, 0.688, 0.507	
  hvac_perf_data_heating_min_speed_cops=5.150, 4.390, 2.550, 2.050, 1.660	
  hvac_perf_data_heating_max_speed_cops=3.684, 3.370, 2.330, 1.980, 1.490	
  hvac_perf_data_cooling_outdoor_temperatures=125.0, 95.0, 82.0, 70.0	
  hvac_perf_data_cooling_min_speed_capacities=0.267, 0.333, 0.368, 0.391	
  hvac_perf_data_cooling_max_speed_capacities=0.847, 1.017, 1.090, 1.148	
  hvac_perf_data_cooling_min_speed_cops=1.918, 3.870, 5.860, 7.126	
  hvac_perf_data_cooling_max_speed_cops=2.017, 3.220, 4.140, 4.900

This ``HVAC Detailed Performance Data`` option would be called in the yaml file along with an ``HVAC Heating Efficiency`` heat pump option.

For example, to include ``HVAC Detailed Performance Data`` with a cold climate heat pump, you could include the following:

.. code-block:: yaml

  - upgrade_name: Typical Cold Climate with Detailed Performance Data
    options:
      - option: HVAC Heating Efficiency|ASHP, SEER2 17.5, 8.5 HSPF2, Typical Cold Climate
        apply_logic:
          - HVAC Has Ducts|Yes
          - not:
            - or:
              - HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Electricity
              - HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Fuel
              - HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Electricity
              - HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Fuel
              - HVAC Shared Efficiencies|Fan Coil Cooling Only

      - option: HVAC Detailed Performance Data|Cold Climate Heat Pump Ducted
        apply_logic:
          - HVAC Has Ducts|Yes
          - not:
            - or:
              - HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Electricity
              - HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Fuel
              - HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Electricity
              - HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Fuel
              - HVAC Shared Efficiencies|Fan Coil Cooling Only

Sizing Methodologies
--------------------

When defining a heat pump upgrade, the new heat pump can be sized according to:

- :ref:`acca`
- :ref:`hers`
- :ref:`max_load`

See `HPXML HVAC Sizing Control <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#hpxml-hvac-sizing-control>`_ for more information.

ResStock currently assumes the existing home's duct system for HVAC equipment upgrades.
Without restricting the upgraded equipment's capacity to the maximum of the existing duct system's heating/cooling airflow rate divided by 400 cfm/ton, fan pressure rise increases and results in higher power use.
Based on the existing duct system, this duct restriction can be avoided by:

- Limiting the upgraded equipment's capacity 
- Adjusting the blower fan efficiency (W/cfm)

Set ``heat_pump_sizing_is_duct_limited=true`` for ``HVAC Heating Efficiency`` options in the lookup to use autosizing limits and maintain the existing duct system curve.

For example:

.. code-block:: yaml

  - upgrade_name: ASHP
    options:
      - option: HVAC Heating Efficiency|ASHP, SEER 16, 9.2 HSPF, Duct Limited
        apply_logic:
          - HVAC Has Ducts|Yes
        costs:
          - value: 50.0
            multiplier: Size, Heating System Primary (kBtu/h)
        lifetime: 30
      - option: HVAC Cooling Efficiency|Ducted Heat Pump

.. _acca:

ACCA Manual J/S
***************

Autosized heat pumps have their nominal capacity sized per ACCA Manual J/S based on cooling design loads, with some oversizing allowances for larger heating design loads.

Set ``heat_pump_sizing_methodology=ACCA`` for ``HVAC Heating Efficiency`` options in the lookup to size based on ACCA Manual J/S.

.. _hers:

HERS
****

Same as ACCA except autosized heat pumps have their nominal capacity sized equal to at least the larger of heating and sensible cooling design loads.

Set ``heat_pump_sizing_methodology=HERS`` (or ``heat_pump_sizing_methodology=auto``) for ``HVAC Heating Efficiency`` options in the lookup to size based on HERS.

.. _max_load:

Max Load
********

Autosized heat pumps have their nominal capacity sized based on the larger of heating/cooling design loads, while taking into account the heat pump’s reduced capacity at the design temperature, such that no backup heating should be necessary.

Set ``heat_pump_sizing_methodology=MaxLoad`` for ``HVAC Heating Efficiency`` options in the lookup to size based on Max Load.
