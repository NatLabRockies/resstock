.. _resstock_architecture:

ResStock Architecture
=====================

The key ResStock workflow components are described below.

Projects
--------

At the top level of the ResStock repository you just downloaded, you will see two analysis project folders:

- ``project_national``
- ``project_testing``
 
The national project contains inputs describing the existing residential building stock.
The testing project contains inputs to test our OpenStudio workflows.
Within each project folder are sample "baseline" and "upgrades" input files that may serve as examples for how to set up different types of ResStock analyses.
The contents of the input file ultimately determines the set of workflow steps (i.e., OpenStudio measures) for each ResStock sample.
See :doc:`running_a_project` for more information about running ResStock analyses.

Sampling
--------
   
To run the sampling script yourself, from the command line execute, e.g. ``openstudio resources/run_sampling.rb -p project_national -n 10000 -o buildstock.csv``, and a ``buildstock.csv`` file will be created in the ``resources`` directory.

If a custom ``buildstock.csv`` file is referenced using the `precomputed sampler <https://buildstockbatch.readthedocs.io/en/stable/samplers/precomputed.html>`_ when you run the project, it will be used as the basis for generating simulation datapoints.
Alternatively by using other (non-precomputed) quota-based samplers, the sampling will be run automatically to create a ``buildstock.csv`` file.
For each simulation datapoint, the workflow will then look up its building description from the sampled ``buildstock.csv`` file.
 
You can use this manual sampling process to downselect which simulations you want to run.
For example, you can use the command above to generate a ``buildstock.csv`` for the entire U.S. and then open up this file in Excel and delete all of the rows that you don't want to simulate (e.g., all rows that aren't in New York).
Keep in mind that if you do this, you will need to re-enumerate the "Building" column as "1" through the number of rows.

Measures
--------

ResStock uses a mixture of both OpenStudio Model and Reporting measures in its workflow.
The following depicts the order in which workflow measure steps are applied:

  ===== ============================= ================== ========= ============= ==========================
  Index Measure                       Measure Type       Optional  Notes         Source
  ===== ============================= ================== ========= ============= ==========================
  1     BuildExistingModel            Model              No        Meta measure  ResStock
  2     ApplyUpgrade                  Model              Yes [#]_  Meta measure  ResStock
  3     HPXMLtoOpenStudio             Model              No                      OS-HPXML [#]_
  4     UpgradeCosts                  Model              No                      ResStock
  5     *Other Model Measures*        Model              Yes                     Any [#]_
  6     ReportSimulationOutput        Reporting          No                      OS-HPXML
  7     ReportUtilityBills            Reporting          No                      OS-HPXML
  8     *Other Reporting Measures*    Reporting          Yes                     Any [#]_
  9     ServerDirectoryCleanup        Reporting          No                      ResStock
  ===== ============================= ================== ========= ============= ==========================

 .. [#] Baseline models with no upgrades do not have the ApplyUpgrade measure applied.
 .. [#] OS-HPXML refers to the `OpenStudio-HPXML <https://github.com/NREL/OpenStudio-HPXML>`_ repository.
 .. [#] *Other Model Measures* do not need to originate from ResStock, but it is up to the user to ensure they work within the ResStock workflow.
 .. [#] *Other Reporting Measures* do not need to originate from ResStock, but it is up to the user to ensure they work within the ResStock workflow.

The BuildExistingModel and ApplyUpgrade meta measures call the following model measures:

  ===== ============================= ================== ========= ============= ==========================
  Index Measure                       Measure Type       Optional  Notes         Source
  ===== ============================= ================== ========= ============= ==========================
  1     ResStockArguments             Model              No                      ResStock
  2     BuildResidentialHPXML         Model              No                      OS-HPXML
  3     BuildResidentialScheduleFile  Model              No                      OS-HPXML
  4     ResStockArgumentsPostHPXML    Model              No                      ResStock
  ===== ============================= ================== ========= ============= ==========================

.. _model-measures:

Model Measures
**************

Model measures are applied *before* the simulation is run.
They contribute to the generation of the model.

**BuildExistingModel**

  BuildExistingModel is a meta measure; meaning, it incrementally applies other measures (i.e., ResStockArguments, BuildResidentialHPXML, and BuildResidentialScheduleFile) to create "baseline" residential models.

  .. include:: ../../../../measures/BuildExistingModel/measure.xml
     :start-after: <description>
     :end-before: <

  .. include:: ../../../../measures/BuildExistingModel/measure.xml
     :start-after: <modeler_description>
     :end-before: <

**ResStockArguments**

    .. include:: ../../../../measures/ResStockArguments/measure.xml
       :start-after: <description>
       :end-before: <

    .. include:: ../../../../measures/ResStockArguments/measure.xml
       :start-after: <modeler_description>
       :end-before: <

**BuildResidentialHPXML**

    .. include:: ../../../../resources/hpxml-measures/BuildResidentialHPXML/measure.xml
       :start-after: <description>
       :end-before: <

    .. include:: ../../../../resources/hpxml-measures/BuildResidentialHPXML/measure.xml
       :start-after: <modeler_description>
       :end-before: <

**BuildResidentialScheduleFile**

    .. include:: ../../../../resources/hpxml-measures/BuildResidentialScheduleFile/measure.xml
       :start-after: <description>
       :end-before: <

    .. include:: ../../../../resources/hpxml-measures/BuildResidentialScheduleFile/measure.xml
       :start-after: <modeler_description>
       :end-before: <

**ResStockArgumentsPostHPXML**

    .. include:: ../../../../measures/ResStockArgumentsPostHPXML/measure.xml
       :start-after: <description>
       :end-before: <

    .. include:: ../../../../measures/ResStockArgumentsPostHPXML/measure.xml
       :start-after: <modeler_description>
       :end-before: <

.. _tutorial-apply-upgrade:

**ApplyUpgrade**

  This measure can be optionally applied to the workflow.
  Like the BuildExistingModel measure, ApplyUpgrade is a meta measure; it, too, incrementally applies other measures (i.e., ResStockArguments, BuildResidentialHPXML, and BuildResidentialScheduleFile) to create "upgraded" residential models.

  .. include:: ../../../../measures/ApplyUpgrade/measure.xml
     :start-after: <description>
     :end-before: <

  .. include:: ../../../../measures/ApplyUpgrade/measure.xml
     :start-after: <modeler_description>
     :end-before: <

  Each instance of the ApplyUpgrade measure defines an upgrade scenario.
  An upgrade scenario is a collection of options exercised with some logic and costs applied.
  In the simplest case, we apply the new option to all housing units.
  The available upgrade options are in ``resources/options_lookup.tsv`` in your git repository.
  For this example, we will upgrade all windows by applying the ``Windows|Triple, Low-E, Non-metal, Air, L-Gain`` option to all houses across the country.
  We do this by entering that in the **Option 1** box on the Apply Upgrade measure.
  Also, we'll give the upgrade scenario a name: "Triple-Pane Windows" and a cost of $40/ft\ :superscript:`2` of window area by entering the number in **Option 1 Cost Value** and selecting "Window Area (ft^2)" for **Option 1 Cost Multiplier**.
  Like the **downselect logic**, excluded datapoints (i.e., datapoints for which the upgrade does not apply) will result in "completed invalid workflow".
  Note that using no downselect logic will apply the option to all housing units.
  For a full explanation of how to set up the options and logic surrounding them, see :doc:`../advanced_tutorial/upgrade_scenario_config`.

**HPXMLtoOpenStudio**

  .. include:: ../../../../resources/hpxml-measures/HPXMLtoOpenStudio/measure.xml
     :start-after: <description>
     :end-before: <

  See also `OpenStudio-HPXML Workflow Inputs <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html>`_ for documentation on workflow inputs.

**UpgradeCosts**

  .. include:: ../../../../measures/UpgradeCosts/measure.xml
     :start-after: <description>
     :end-before: <

  .. include:: ../../../../measures/UpgradeCosts/measure.xml
     :start-after: <modeler_description>
     :end-before: <

**Other Model Measures**

  Additional model measures can be optionally applied to the workflow.
  They are applied following generation of the model, but before any reporting measures.

Reporting Measures
******************

Reporting measures are applied *after* the simulation is run.
They process and report simulation output.

**ReportSimulationOutput**

  .. include:: ../../../../resources/hpxml-measures/ReportSimulationOutput/measure.xml
     :start-after: <description>
     :end-before: <

  .. include:: ../../../../resources/hpxml-measures/ReportSimulationOutput/measure.xml
     :start-after: <modeler_description>
     :end-before: <

**ReportUtilityBills**

  .. include:: ../../../../resources/hpxml-measures/ReportUtilityBills/measure.xml
     :start-after: <description>
     :end-before: <

  .. include:: ../../../../resources/hpxml-measures/ReportUtilityBills/measure.xml
     :start-after: <modeler_description>
     :end-before: <

**Other Reporting Measures**

  Additional reporting measures (e.g., QOIReport) can be optionally applied to the workflow.
  They are applied following all standard reporting measures, but before the ServerDirectoryCleanup measure.

**ServerDirectoryCleanup**

  .. include:: ../../../../measures/ServerDirectoryCleanup/measure.xml
     :start-after: <description>
     :end-before: <

  .. include:: ../../../../measures/ServerDirectoryCleanup/measure.xml
     :start-after: <modeler_description>
     :end-before: <
