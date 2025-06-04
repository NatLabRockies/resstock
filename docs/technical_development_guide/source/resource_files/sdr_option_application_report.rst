.. _sdr_option_application_report:

SDR Option Application Report
=============================

The ``sdr_option_application_report.csv`` file provides a summary of how many buildings each of the options and upgrades in the sdr project yaml file (``project_national/sdr_upgrades_tmy3.yml``) will apply to in a 550K building sample. This is used to validate the apply logic in the sdr project yaml file. A more detailed look into the parsing of the applicability logic is available in :ref:`sdr_option_application_detailed_report`.

File Location
-------------

The file is located at ``project_national/resources/sdr_option_application_report.csv`` in the ResStock repository.

File Structure
--------------

The file is structured as a CSV (comma-separated values) file with the following columns:

- **upgrade**: A numeric identifier for the upgrade scenario
- **upgrade_name**: A descriptive name for the upgrade scenario
- **option_num**: A numeric identifier for the specific option within the upgrade
- **option**: The specific parameter and value being modified (in the format "Parameter|Option")
- **applicable_to**: The number of buildings sample to which this option was applied
- **applicable_percent**: The percentage of the total building stock sample (550K) to which this option was applied

Reading the file
-----------------

Here's an example of how to read the information in the file:

.. list-table:: Example SDR Option Application Report Entries
   :header-rows: 1
   :widths: 15 25 15 30 15 10

   * - upgrade
     - upgrade_name
     - option num
     - option
     - applicable_to
     - applicable_percent
   * - 1
     - ENERGY STAR heat pump with elec backup
     - 1
     - HVAC Heating Efficiency|ASHP, SEER 16, 9.2 HSPF
     - 408859
     - 74.3
   * - 1
     - ENERGY STAR heat pump with elec backup
     - 2
     - HVAC Heating Efficiency|MSHP, SEER 16, 9.2 HSPF, Max Load
     - 121588
     - 22.1
   * - 1
     - ENERGY STAR heat pump with elec backup
     - 3
     - Cooling Setpoint Has Offset|No
     - 121588
     - 22.1
   * - ...
     - ...
     - ...
     - ...
     - ...
     - ...
   * - 1
     - ENERGY STAR heat pump with elec backup
     - -1
     - All
     - 530447
     - 96.4

In this example:

- Upgrade 1 is named "ENERGY STAR heat pump with elec backup"
- The first option within this upgrade changes "HVAC Heating Efficiency" to "ASHP, SEER 16, 9.2 HSPF"
- This option was applied to 408,859 buildings, representing 74.3% of the total stock of 550,000 buildings.
- The special option_num "-1" with option "All" shows the total applicability of the entire upgrade package. This is used to calculate the total applicability of the entire upgrade package and is not a real option in the project yaml file.

Usage
-------

The ``sdr_option_application_report.csv`` file can be used for:

1. **Error Detection**: It helps catch errors by flagging when options are applied to zero buildings, which indicates a problem in the upgrade specification. The CI job automatically checks for this and fails if there are any option with zero applicability.
2. **Upgrade Documentation**: It documents in tabular form which specific options were applied in each upgrade.
3. **Applicability Analysis**: It shows how widely each upgrade and options are applied across the building stock.
4. **Reporting**: It provides key applicability statistics for use in measure documentation.


Creation
--------
``sdr_option_application_report.csv`` file is automatically created by ResStock CI job. The CI uses the ``upgrades_analyzer`` tool in buildstock-query with the ``project_national/sdr_upgrades_tmy3.yml`` and a fresh 550K sample as input to generate this file. Whenever the yaml apply logic or the housing characteristics changes, the CI job will regenerate this file and commit to the repo.