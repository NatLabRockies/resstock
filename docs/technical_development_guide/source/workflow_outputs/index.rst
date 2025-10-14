.. _workflow_outputs:

Workflow Outputs
================

ResStock, by default, generates a set of sampled housing characteristics, simulation output, and upgrade cost outputs.

ResStock optionally generates outputs related to component loads, emissions, utility bills, quantities of interest, zone temperatures/setpoints, airflow rates, weather file data, and user-requested EnergyPlus output variables.
See the `Residential HPXML Workflow Generator <https://buildstockbatch.readthedocs.io/en/latest/workflow_generators/residential_hpxml.html>`_ documentation page for more information on how to request optional outputs.

Tables in the :ref:`default_outputs` and :ref:`optional_outputs` sections are generated based on `data dictionary files for inputs and outputs <https://github.com/NREL/resstock/tree/data-dictionary/resources/data/dictionary/>`_.
The data dictionary files, along with their data columns, are shown below:

- ``postprocessing/resstockpostproc/resources/dictionary/inputs.csv``

  - Input Name
  - Input Description

- ``postprocessing/resstockpostproc/resources/dictionary/outputs.csv``:

  - Row Index
  - Sums To
  - Annual Name
  - Annual Units
  - Timeseries ResStock Name
  - Timeseries BuildStockBatch Name
  - Timeseries Units
  - Notes

.. note::
  Although not shown in the tables, the "Row Index" and "Sums To" columns can be used to understand how various outputs relate to other outputs (e.g., end use columns sum to fuel use, and fuel use columns sum to energy use).

.. toctree::
   :maxdepth: 2

   default_outputs
   optional_outputs
