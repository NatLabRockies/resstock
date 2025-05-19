.. _source_report:

Source Report
=============

The ``source_report.csv`` file provides detailed metadata about each parameter used in ResStock, including information about its creation, sources, and assumptions.

File Location
-------------

The file is located at ``project_national/resources/source_report.csv`` in the ResStock repository.

File Structure
--------------

The file is structured as a CSV (comma-separated values) file with the following columns:

- **Parameter**: The name of the housing characteristic parameter
- **Number of options**: The count of distinct options available for this parameter
- **Number of dependencies**: The count of other parameters this parameter depends on
- **Created by**: The script or process that generated this parameter
- **Description**: A brief description of what the parameter represents
- **Source**: The data sources used to develop the parameter and its options
- **Assumption**: Any assumptions made during the development of this parameter

Purpose
-------

The source_report.csv file serves as a comprehensive metadata repository for sources used to create ResStock housing characteristics. This file is used to autogenerate the information in the :ref:`housing_characteristics` section. It serves the following purposes:

1. **Documentation**: It documents the origin and meaning of each parameter in the model
2. **Traceability**: It provides traceability back to original data sources
3. **Transparency**: It makes explicit any assumptions that went into the creation of parameters
4. **Quality Assurance**: It helps ensure that parameters are well-defined and properly sourced

Example
-------

Here's an example of how the data appear in the file:

.. code-block:: text

   Parameter,Number of options,Number of dependencies,Created by,Description,Source,Assumption
   AHS Region,24.0,1.0,sources\spatial\tsv_maker.py,The American Housing Survey region that the sample is located.,"Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.; Core Based Statistical Area (CBSA) data based on the Feb 2013 CBSA delineation file.",
   AIANNH Area,2.0,1.0,sources\spatial\tsv_maker.py,American Indian/Alaska Native/Native Hawaiian Area that the sample is located.,"2010 Census Tract to American Indian Area (AIA) Relationship File provides percent housing unit in tract that belongs to AIA.Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.","(2010) Tract is mapped to (2015) County and PUMA by adjusting for known geographic changes (e.g., renaming of Shannon County to Oglala Lakota County, SD) However, Tract=G3600530940103 (Oneida city, Madison County, NY) could not be mapped to County and PUMA and was removed. The tract contains only 11 units for AIA."

Creation
--------

The source_report.csv file is created by the source_report.py script in resstock-estimation for each project. When a ResStock PR is created to update TSVs, the developer should copy the updated source_report.csv file to the project_national/resources directory and include it in the PR.