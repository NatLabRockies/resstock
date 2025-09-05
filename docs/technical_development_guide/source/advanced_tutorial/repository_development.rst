Repository Development
======================

At this point in the tutorial, it is assumed that you have checked out a new branch that is up-to-date with either the ``develop`` or ``latest-os-hpxml`` branch of the `ResStock <https://github.com/NREL/resstock>`_ repository.
Note that a pull request review is required if your changes are intended to be merged into the ``develop`` branch of the `ResStock <https://github.com/NREL/resstock>`_ repository.

ResStock's ``develop`` branch generally points to the ``master`` branch of OpenStudio-HPXML.
A standing ``latest-os-hpxml`` branch in ResStock helps to ensure that ResStock stays up-to-date with OpenStudio-HPXML's development.
The ``latest-os-hpxml`` is periodically merged into ``develop`` using a "Latest OS-HPXML" pull request (`here <https://github.com/NREL/resstock/pull/1328>`_ is an example).

There is a ResStock maintenance task for keeping ``latest-os-hpxml`` up-to-date -- periodically merging its corresponding pull request (as well as creating a new one following the merge).
Other ResStock tasks are developmental in nature and include, e.g.:

- TSV file updates from `resstock-estimation <https://github.com/NREL/resstock-estimation>`_
- technical documentation/reference updates
- tests and/or CI config updates
- core ResStock measure updates
- use/test new OpenStudio-HPXML features

The ResStock branch from which to implement changes, and guidelines for implementing those changes, depend on the task.
In general, changes may be:

- unrelated to OpenStudio-HPXML
- related to the ``master`` branch of OpenStudio-HPXML
- related to some other branch of OpenStudio-HPXML

.. _branch-develop:

Branch from ``develop``
-----------------------

Branch from ``develop`` for:

- TSV file updates from `resstock-estimation <https://github.com/NREL/resstock-estimation>`_
- technical documentation/reference updates
- tests and/or CI config updates
- core ResStock measure updates

These types of changes do not involve OpenStudio-HPXML, and so it is unnecessary to ensure files in the ``resources/hpxml-measures`` folder point to the OpenStudio-HPXML ``master`` branch.

Also branch from ``develop`` for creating a new ``latest-os-hpxml`` branch following the merge of an old one.
For updating to the latest version of OpenStudio-HPXML's ``master`` branch enter the following command:

.. code:: bash

  $ openstudio tasks.rb update_resources

See :doc:`testing_infrastructure/running_task_commands` for more information and context about running tasks.
(Executing the ``update_resources`` task will issue the appropriate ``git subtree`` command for syncing ResStock with OpenStudio-HPXML's ``master`` branch; there is more on this below.)

Once ``resources/hpxml-measures`` has been updated, there are a few :ref:`remaining steps<post-git-subtree-steps>` for ensuring ResStock is properly connected to OpenStudio-HPXML.

If ``develop`` moves ahead of your branch, merge ``develop`` into your branch.

.. _branch-latest-os-hpxml:

Branch from ``latest-os-hpxml``
-------------------------------

Branch from ``latest-os-hpxml`` for:

- using the ``master`` branch of OpenStudio-HPXML
- using some other branch of OpenStudio-HPXML

If you want to ensure you are using the latest ``master`` branch of OpenStudio-HPXML, branch from the ``latest-os-hpxml`` ResStock branch.
This will allow you to use/test a new OpenStudio-HPXML feature or bugfix that was recently merged into its ``master`` branch.

For using an OpenStudio-HPXML feature or bugfix that has not yet been merged into ``master``, branch from the ``latest-os-hpxml`` ResStock branch and then follow the instructions below.

ResStock contains a **subtree** to the `OpenStudio-HPXML <https://github.com/NREL/OpenStudio-HPXML>`_ repository.
The subtree is located at ``resources/hpxml-measures``, and is basically a direct copy of all the folders and files contained in OpenStudio-HPXML for a particular commit.
See `this link <https://www.atlassian.com/git/tutorials/git-subtree>`__  or `this link <https://gist.github.com/SKempin/b7857a6ff6bddb05717cc17a44091202>`__ for more information about subtree and the ``git subtree`` command.

When using or testing a specific OpenStudio-HPXML branch, the subtree at ``resources/hpxml-measures`` can be updated using a set of simple commands.
Files located at ``resources/hpxml-measures`` should typically never be directly edited or modified manually.

For pulling in and using/testing a specific OpenStudio-HPXML branch, enter the following command:

.. code:: bash

  $ git subtree pull --prefix resources/hpxml-measures https://github.com/NREL/OpenStudio-HPXML.git <branch_name> --squash

where ``<branch_name>`` represents the OpenStudio-HPXML branch (from step 1 above) to be pulled in and tested.
Note that the previous command essentially mirrors what ``update_resources`` calls but with a user-specified branch name.

Once ``resources/hpxml-measures`` has been updated, there are a few :ref:`remaining steps<post-git-subtree-steps>` for ensuring ResStock is properly connected to OpenStudio-HPXML.

If ``latest-os-hpxml`` moves ahead of your branch, merge ``latest-os-hpxml`` into your branch.
Note that this can cause merge conflicts for files in the ``resources/hpxml-measures`` folder.
The best practice is to instead keep the OpenStudio-HPXML branch up-to-date with ``master``, and enter the ``git subtree`` command again to pull in the latest version of ``resources/hpxml-measures``.
Should a merge of ``latest-os-hpxml`` into your branch cause merge conflicts, choose the version of ``resources/hpxml-measures`` from the up-to-date OpenStudio-HPXML branch.

.. _post-git-subtree-steps:

Steps after ``git subtree``
---------------------------

After pulling a branch of OpenStudio-HPXML into ResStock, a few additional steps are involved:

1. Run ``openstudio tasks.rb update_measures``.
   
   This applies rubocop auto-correct to measures, updates measure.xml files, and ensures arguments of the ResStockArguments measure reflect BuildResidentialHPXML.
   
   Although ``update_measures`` has the same name as OpenStudio-HPXML's ``update_measures`` task, it is applied only to ResStock's core measures.
   
2. Run the ``openstudio measures/ResStockArguments/tests/resstock_arguments_test.rb`` unit test.

3. Based on the results of the previous test, update ``resources/options_lookup.tsv`` with any new ResStockArguments arguments introduced by BuildResidentialHPXML.

4. Based on any workflow inputs/outputs changes, update CSV files in the ``resources/data/dictionary`` folder.
   
   This addresses any input/output data dictionary changes introduced by OpenStudio-HPXML workflow updates.
