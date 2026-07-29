.. _usage_instructions:

Usage Instructions
==================

Setup
-----

To get started:

#. Download `OpenStudio 3.11.0 <https://github.com/NREL/OpenStudio/releases/tag/v3.11.0>`_ and install the Command Line Interface/EnergyPlus components, or use the `nrel/openstudio docker image <https://hub.docker.com/r/nrel/openstudio>`_.
#. Download the `latest release <https://github.com/NREL/OpenStudio-HPXML/releases>`_.

Running
-------

To programatically run simulations, it's recommended to use the OpenStudio `Command Line Interface <http://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/>`_.
Two general approaches (basic and advanced) for running via the CLI are described below.
The OpenStudio measures can also be run from user interfaces (e.g., the OpenStudio Application or OpenStudio Parametric Analysis Tool (PAT)).

.. note::

  If the ``openstudio`` command is not found, it's because the executable is not in your PATH. Either add the executable to your PATH or point directly to the executable found in the openstudio-X.X.X/bin directory.

.. _basic_run:

Basic Run
~~~~~~~~~

| The simplest and fastest method is to call the OpenStudio CLI with the provided run script. For example:
| ``openstudio workflow/run_simulation.rb -x workflow/sample_files/base.xml``
| By default, a "run" directory with all input/output files is created next to input HPXML file.

| To specify a different output directory:
| ``openstudio workflow/run_simulation.rb -x workflow/sample_files/base.xml -o my_output_directory``

| You can also request generation of various timeseries outputs by providing one or more timeseries flags. Some examples:
| ``openstudio workflow/run_simulation.rb -x workflow/sample_files/base.xml --hourly ALL``
| ``openstudio workflow/run_simulation.rb -x workflow/sample_files/base.xml --monthly fuels --monthly temperatures --output-format json``
| ``openstudio workflow/run_simulation.rb -x workflow/sample_files/base.xml --monthly fuels --hourly temperatures --hourly 'Zone People Occupant Count'``
| ``openstudio workflow/run_simulation.rb -x workflow/sample_files/base.xml --monthly fuels --hourly temperatures --hourly 'MainsWater:Facility'``
| ``openstudio workflow/run_simulation.rb -x workflow/sample_files/base.xml --hourly ALL --output-format csv_dview``
| The last command will create a timeseries CSV output file that can be visualized by `DView <https://github.com/NREL/wex/wiki/DView>`_ (available for download `here <https://beopt.nrel.gov>`_).

| You can also add stochastic occupancy schedules as part of the simulation:
| ``openstudio workflow/run_simulation.rb -x workflow/sample_files/base.xml --add-stochastic-schedules``
| This run includes the automatic generation of a CSV file with stochastic occupancy schedules that are used in the EnergyPlus simulation.

| If you have an HPXML with multiple ``Building`` elements that do not describe multiple dwelling units of :ref:`bldg_type_whole_mf_buildings` (e.g., two ``Building`` elements for pre- and post-retrofit configurations), you must specify which building ID to run:
| ``openstudio workflow/run_simulation.rb -x multiple_buildings.xml --building-id MyBuildingName``

Run ``openstudio workflow/run_simulation.rb -h`` to see all available commands/arguments.

.. _advanced_run:

Advanced Run
~~~~~~~~~~~~

If additional flexibility is desired (e.g., specifying individual measure arguments, including additional OpenStudio measures to run alongside this measure in a workflow, etc.), create an `OpenStudio Workflow (OSW) <https://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/#osw-structure>`_ file.
The OSW is a JSON file that will specify all the OpenStudio measures (and their arguments) to be run sequentially.
A template OSW that simply runs the HPXMLtoOpenStudio, ReportSimulationOutput, and ReportUtilityBills measures on the ``workflow/sample_files/base.xml`` file can be found at ``workflow/template-run-hpxml.osw``.

| For example:
| ``openstudio run -w workflow/template-run-hpxml.osw``
| This will create a "run" directory with all input/output files. By default it will be found at the same location as the OSW file.

| Another example:
| ``openstudio run -w workflow/template-run-hpxml-with-stochastic-occupancy.osw``
| This workflow automatically generates and uses a CSV file with stochastic occupancy schedules before running the EnergyPlus simulation.

| And another example:
| ``openstudio run -w workflow/template-build-and-run-hpxml-with-stochastic-occupancy.osw``
| This workflow builds an HPXML file on the fly from building description inputs in the OSW, then automatically generates and uses a CSV file with stochastic occupancy schedules, and finally runs the EnergyPlus simulation.

| And here's an example of just creating an HPXML file and not running the EnergyPlus model:
| ``openstudio run -m -w workflow/template-build-hpxml.osw``

Outputs
~~~~~~~

A variety of high-level annual outputs are conveniently reported in the resulting ``run/results_annual.csv`` (or ``.json`` or ``.msgpack``) file.

When timeseries outputs are requested, they will be found in the ``run/results_timeseries.csv`` (or ``.json`` or ``.msgpack``) file.
If multiple timeseries frequencies are requested (e.g., hourly and daily), the timeseries output filenames will include the frequency (e.g., ``run/results_timeseries_daily.csv``).

See :ref:`workflow_outputs` for a description of all available outputs.
