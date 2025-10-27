Updating Options Lookup
=======================

The ``options_lookup.tsv`` file, found in the ``resources`` folder, specifies mappings from sampled options into ResStockArguments measure arguments.
For example, if the distribution of cooling system types in ``HVAC Cooling Efficiency.tsv`` has ``Option=AC, SEER2 12.4`` and ``Option=AC, SEER2 14.3``, but you want to include a ``Option=AC, SEER2 16.2`` option, you would add that option as a column in ``HVAC Cooling Efficiency.tsv`` and then create a corresponding row in ``options_lookup.tsv``.
Updates to ``options_lookup.tsv`` will allow you to avoid hitting the following types of integrity check errors:

- :ref:`Could not find parameter and option <could-not-find-parameter-and-option>`
- :ref:`Required argument not provided <required-argument-not-provided>`

.. _integrity-check-errors:

Integrity Check Errors
----------------------

.. _could-not-find-parameter-and-option:

Could not find parameter and option
***********************************

You do not have a row in ``options_lookup.tsv`` for a particular option that is sampled.

An example of this error is given below:

.. code:: bash

  $ openstudio tasks.rb integrity_check_testing
  ...
  Error executing argv: ["integrity_check_testing"]
  Error: ERROR: Could not find parameter 'Insulation Wall' and option 'Wood Stud, Uninsulated' in C:/OpenStudio/resstock/test/../resources/options_lookup.tsv.

.. _required-argument-not-provided:

Required argument not provided
******************************

For the particular option that is sampled, your corresponding measure is missing an argument value assignment.

An example of this error is given below:

.. code:: bash

  $ openstudio tasks.rb integrity_check_testing
  ...
  Error executing argv: ["integrity_check_testing"]
  Error: ERROR: Required argument 'wall_assembly_r' not provided in C:/OpenStudio/resstock/test/../resources/options_lookup.tsv for measure 'ResStockArguments'.

.. _committing-changes:

Committing Changes to Options Lookup
------------------------------------

When committing changes to ``options_lookup.tsv``, sometimes the diff in the pull request will show that all the lines have changed. This is likely because all the endline characters have changed or that there are empty columns have been inserted. This behavior is common with editing in Microsoft Excel. Since it is convienient to modify the file in Excel, GitHub Actions automatically formats ``options_lookup.tsv``. If the tests pass, these changes will be committed.

In the ``.github/workflows/config.yml`` there is a `task <https://github.com/NREL/resstock/blob/733f7279569b43b105efea1dc1bf8cc700b12f44/.github/workflows/config.yml#L25-L36>`_ that formats ``options_lookup.tsv``.

.. code:: bash

  sed -i -e 's/[[:space:]]*$//' resources/options_lookup.tsv # Remove whitespace
  (sed -u 1q ; sort -k1 -k2) < resources/options_lookup.tsv > sorted_options_lookup.tsv
  mv sorted_options_lookup.tsv resources/options_lookup.tsv # Sort on first two columns

These lines removes any extra white space, and sorts the file on the parameter and option names. If the pull request diff is showing that all the lines are being updated. Run these three lines in the ``resstock`` directory, commit the changes, and push to the remote feature branch. At this point the diff should show only the changes made on the feature branch.
