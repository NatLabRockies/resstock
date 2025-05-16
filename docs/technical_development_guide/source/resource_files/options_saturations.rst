.. _options_saturations:

Options Saturations
====================

The ``options_saturations.csv`` file contains information about the saturation (prevalence) of different options for each parameter in the ResStock housing stock.

File Location
-------------

The file is located at ``project_national/resources/options_saturations.csv`` in the ResStock repository.

File Structure
--------------

The file is structured as a CSV (comma-separated values) file with the following columns:

- **Level**: Indicates the hierarchy level of the parameter (0 for top-level parameters, 1 for dependent parameters)
- **Parameter**: The name of the housing characteristic parameter
- **Option**: The specific option value for the parameter
- **Saturation**: The prevalence of this option in the housing stock, expressed as a decimal (e.g., 0.25 = 25%)

Purpose
-------

The options_saturations.csv file summarizes the distribution of housing characteristics across the modeled building stock. This file is used to autogenerate the stock saturation table in :ref:`housing_characteristics` section. This file is also used by buildstock-query upgrades_analyzer to parse the apply logic in the project yaml file.

Example
-------

Here's an example of how the data appear in the file:

.. code-block:: text

   Level,Parameter,Option,Saturation
   0,ASHRAE IECC Climate Zone 2004,1A,0.0179403
   0,ASHRAE IECC Climate Zone 2004,2A,0.115935
   0,ASHRAE IECC Climate Zone 2004,2B,0.0197434
   ...
   0,Usage Level,Low,0.25
   0,Usage Level,Medium,0.5
   0,Usage Level,High,0.25
   ...
   1,County and PUMA,"G0100010, G01002100",0.000169438
   1,County and PUMA,"G0100030, G01002600",0.000802499
   ...

Creation
--------

The options_saturations.csv file is created by the sampling_probability script in resstock-estimation for each project. When a ResStock PR is created to update TSVs, the developer should copy the updated options_saturations.csv file to the project_national/resources directory and 
include it in the PR.
