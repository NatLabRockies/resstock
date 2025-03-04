.. _running_a_project:

Running a Project
=================

Both buildstockbatch and run_analysis.rb can used to run ResStock analyses.
They use a common project definition, the YAML file, to provide the details of the analysis.
See the `Residential HPXML Workflow Generator <https://buildstockbatch.readthedocs.io/en/latest/workflow_generators/residential_hpxml.html>`_ documentation page for more information.

.. _buildstockbatch:

Using buildstockbatch
---------------------

See the `BuildStock Batch documentation <https://buildstockbatch.readthedocs.io/en/latest/>`_ for information on running projects (large-scale).

.. _run_analysis:

Using run_analysis.rb
---------------------

You also have the option of running (small-scale) projects using the OpenStudio `Command Line Interface <http://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/>`_ (CLI) with buildstockbatch yml input files.
This method needs only the OpenStudio CLI.

The primary differences relative to buildstockbatch are:

#. ``Debugging``: Individual, or sets of (e.g., 1, 2, 4), building ID(s) from the entire sampled space can be run. (See the related ``--building_id`` argument below.)
#. ``Convenience``: Simulation input files (both OSW and HPXML) are collected and stored on-the-fly. (See the related ``--debug`` argument below.)
#. ``Size``: Folders containing intermediate files can be either preserved or successively overwritten. (See the related ``--keep_run_folders`` argument below.)
#. ``Accessibility``: Simulation input and output files are organized and stored differently, and are not tarred or compressed.

Call the OpenStudio CLI with the provided ``workflow/run_analysis.rb`` script.
For example:
``openstudio workflow/run_analysis.rb -y project_testing/testing_baseline.yml``
The previous command samples from ``project_testing`` and runs simulations using baseline workflows generated from the specified yml file.
An "output directory" (as specified in the yml file) is created with all input (OSW and HPXML) files and simulation results.

.. note::

  If the ``openstudio`` command is not found, it's because the executable is not in your PATH. Either add the executable to your PATH or point directly to the executable found in the openstudio-X.X.X/bin directory.

You can also request that only measures are applied (i.e., no simulations are run) using the ``--measures_only`` flag.
For example:
``openstudio workflow/run_analysis.rb -y project_testing/testing_baseline.yml -m``

Run ``openstudio workflow/run_analysis.rb -h`` to see all available commands/arguments:

.. code:: bash

  $ openstudio workflow/run_analysis.rb -h
  Usage: run_analysis.rb -y buildstockbatch.yml
   e.g., run_analysis.rb -y national_baseline.yml
      -y, --yml <FILE>                 YML file
      -n, --threads N                  Number of parallel simulations (defaults to processor count)
      -m, --measures_only              Only run the OpenStudio and EnergyPlus measures
      -i, --building_id ID             Only run this building ID; can be called multiple times
      -u, --upgrade_name NAME          Only run this upgrade; can be called multiple times
      -k, --keep_run_folders           Preserve run folder for all datapoints; also populates run folder in cli_output.log and results-xxx.csv files
      -s, --samplingonly               Run the sampling only
      -d, --debug                      Preserve xml/osw files for existing building
      -o, --overwrite                  Overwrite existing project directory
      -v, --version                    Display version
      -h, --help                       Display help

.. note::
  At this time the ``residential_quota_downselect`` sampler with ``resample`` is not supported.

.. note::
  EPW weather files must be contained in a ``weather`` folder at the same level as the ``workflow`` folder (i.e., at the top level of the repository).
  If no such folder is present, or if the ``weather`` folder does not contain any ``*.epw`` files, it will automatically be created/populated based on the ``weather_files_url`` (or ``weather_files_path``) present in the specified yml file.