.. _default_outputs:

Default Outputs
===============

The default set of outputs include sampled housing characteristics, annual simulation outputs, electric panel breaker spaces and loads, and upgrade cost information.

Specifying any timeseries frequency other than "none" results in, by default, end use consumptions and total loads timeseries output requests.
See the `Residential HPXML Workflow Generator <https://buildstockbatch.readthedocs.io/en/latest/workflow_generators/residential_hpxml.html>`_ documentation page (i.e., ``simulation_output_report`` section) for more information on how to request various timeseries outputs (or override default requests).

Housing Characteristics
***********************

Default characteristics include sampled properties for each dwelling unit.

.. csv-table::
   :file: csv_tables/characteristics.csv
   :header-rows: 1

Simulation Outputs
******************

Default annual simulation outputs include energy consumptions (total, by fuel, and by end use), hot water uses, building loads, unmet hours, peak building electricity/loads, HVAC capacities, and HVAC design temperatures/loads.

See the OpenStudio-HPXML Workflow Outputs sections on `Annual Outputs <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_outputs.html#annual-outputs>`_ and `Timeseries Outputs <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_outputs.html#timeseries-outputs>`_ for more information about annual outputs.

.. csv-table::
   :file: csv_tables/simulation_outputs.csv
   :header-rows: 1

.. _panel-costs:

Electric Panel Outputs
**********************

Electric panel breaker space counts are available as listed below.
End use categories (e.g., Heating, Cooling, Hot Water) report occupied spaces for dedicated circuits except for Other which reports otherwise uncategorized or shared circuits.

Electric panel loads, as well as calculated total loads and capacities for each calculation type, are available as listed below.
In the table below, "<type>" refers to the calculation type (e.g., 2023 NEC 220.83).
Calculation types "2023 Existing Dwelling Load-Based" and "2023 Existing Dwelling Meter-Based" are shown as "2023_existing_dwelling_load_based" and "2023_existing_dwelling_meter_based", respectively.

.. note::

  Headroom is calculated as the panel's total rated breaker spaces (or maximum current rating) minus occupied breaker spaces (or calculated capacity).
  A positive value indicates panel availability whereas a negative value indicates panel constraint.

.. csv-table::
   :file: csv_tables/panel_outputs.csv
   :header-rows: 1

.. _upgrade-costs:

Upgrade Costs
*************

Cost multiplier types include:

.. csv-table::
   :file: csv_tables/cost_multipliers.csv
   :header-rows: 1

Note that "Fixed (1)" is also a valid cost multiplier type.

When upgrades are applied, additional outputs are reported. They are listed below.

=====================================  ========================  =====================================
Annual Name                            Annual Units              Notes
=====================================  ========================  =====================================
upgrade_costs.option_<#>_name                                    The Parameter|Option applied.
upgrade_costs.option_<#>_cost_usd      $                         The option cost (value * multiplier).
upgrade_costs.option_<#>_lifetime_yrs  years                     The option lifetime.
upgrade_costs.upgrade_cost_usd         $                         Total cost of the upgrade.
=====================================  ========================  =====================================

where <#> represents any of the defined option numbers.
See :doc:`../advanced_tutorial/upgrade_scenario_config` for more information.

.. note::
  Currently, you can enter up to 25 options per upgrade.
  See :doc:`../advanced_tutorial/increasing_upgrade_options` for more information on how to allow additional options per upgrade.

Note that the name, cost, and lifetime information will only be populated when applicable for a given upgrade option (i.e., when the apply logic evaluates as true).

Other Outputs
*************

.. csv-table::
   :file: csv_tables/other_outputs.csv
   :header-rows: 1
