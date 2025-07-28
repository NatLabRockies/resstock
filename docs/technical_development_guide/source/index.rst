.. ResStock documentation main file, created by
   sphinx-quickstart on Fri Jul  7 11:12:22 2017.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

ResStock Technical Development Guide
====================================

.. note::
  Most people who use ResStock for analysis do so by using the datasets published to the `ResStock Data Viewer <https://resstock.nrel.gov>`_.
  These datasets are often the best choice because they are a verified run that can be referenced.
  Datasets with upgrade scenario results will be made available over time.
  
  For more complicated analyses including custom upgrade scenarios, the source code of ResStock and this documentation page are available to run your own simulations.
  However, running ResStock can be a complicated affair and can require a lot of computing resources.
  Running on Amazon Web Services requires some technical knowledge of cloud computing to deploy.
  Unfortunately, we don’t have the resources to provide technical support if you choose this route.

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   basic_tutorial/index
   advanced_tutorial/index
   workflow_inputs/index
   workflow_outputs/index
   continuous_integration/index
   testing/index
   resource_files/index

Updates & Changelog
===================

.. toctree::
   :maxdepth: 2
   :caption: Changes:

   changelog/index

Indices and tables
==================

* :ref:`genindex`
* :ref:`search`
