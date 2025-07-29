Running Tasks Commands
======================

Run ``openstudio tasks.rb`` to see available task commands:

.. code:: bash

  $ openstudio tasks.rb 
  ERROR: Missing command.
  Usage: openstudio tasks.rb [COMMAND]
  Commands:
    update_measures
    update_resources
    integrity_check_national
    integrity_check_testing
    download_weather

.. _update-measures:

Update Measures
---------------

Use ``openstudio tasks.rb update_measures`` to apply rubocop auto-correct to measures, and to update measure.xml files:

.. code:: bash

  $ openstudio tasks.rb update_measures
  Applying rubocop auto-correct to measures...
  Running RuboCop...

  91 files inspected, no offenses detected
  Updating measure.xmls...
  Done.

.. _update-resources:

Update Resources
----------------

Use ``openstudio tasks.rb update_resources`` to update files in ``resources/hpxml-measures`` with the latest version of OpenStudio-HPXML.

.. code:: bash

  $ openstudio tasks.rb update_resources
  remote: Enumerating objects: 188817, done.
  remote: Counting objects: 100% (15305/15305), done.
  ...
  From https://github.com/NREL/OpenStudio-HPXML
   * branch                    master     -> FETCH_HEAD
  Merge made by the 'ort' strategy.
  ...

.. _integrity-checks:

Integrity Checks
----------------

Run ``openstudio tasks.rb integrity_check_<project_name>``, where ``<project_name>`` matches the project you are working with. If no task exists for the project you are working with, extend the list of integrity check tasks to accommodate your project by modifying the ``tasks.rb`` file. An example for running a project's integrity checks is given below:

.. code:: bash

  $ openstudio tasks.rb integrity_check_national
  Checking for issues with project_national/Location Region...
  Checking for issues with project_national/Location EPW...
  Checking for issues with project_national/Vintage...
  Checking for issues with project_national/Heating Fuel...
  Checking for issues with project_national/Usage Level...
  ...

If the integrity check for a given project fails, you will need to update either your tsv files and/or the ``resources/options_lookup.tsv`` file.
See :doc:`updating_options_lookup` for information about the ``options_lookup.tsv`` file.

.. download-weather:

Download Weather
----------------

Run ``openstudio tasks.rb download_weather`` to download available EPW weather files:

.. code:: bash

  $ openstudio tasks.rb download_weather
  Downloading /files/156/BuildStock_TMY3_FIPS.zip (  1%) 
  Downloading /files/156/BuildStock_TMY3_FIPS.zip (  2%) 
  Downloading /files/156/BuildStock_TMY3_FIPS.zip (  3%)
  ...
