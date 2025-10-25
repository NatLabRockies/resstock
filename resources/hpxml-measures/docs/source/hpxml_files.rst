.. _hpxml_files:

HPXML Files
===========

OpenStudio-HPXML requires a building description in an `HPXML file <https://hpxml.nrel.gov/>`_ format.
HPXML is an open data standard for collecting and transferring home energy data.
Using HPXML files reduces the complexity and effort for software developers to leverage the EnergyPlus simulation engine.

About HPXML
-----------

HPXML is an flexible and extensible format, where nearly all elements in the schema are optional and custom elements can be included.
Because of this, a stricter set of requirements for the HPXML file have been developed for purposes of running EnergyPlus simulations.

HPXML files submitted to OpenStudio-HPXML undergo a two step validation process:

1. Validation against the HPXML Schema

  The HPXML XSD Schema can be found at ``HPXMLtoOpenStudio/resources/hpxml_schema/HPXML.xsd``.
  XSD Schemas are used to validate what elements/attributes/enumerations are available, data types for elements/attributes, the number/order of children elements, etc.

2. Validation using `Schematron <http://schematron.com/>`_

  The Schematron document for the EnergyPlus use case can be found at ``HPXMLtoOpenStudio/resources/hpxml_schematron/EPvalidator.sch``.
  Schematron is a rule-based validation language, expressed in XML using XPath expressions, for validating the presence or absence of inputs in XML files.
  As opposed to an XSD Schema, a Schematron document validates constraints and requirements based on conditionals and other logical statements.
  For example, if an element is specified with a particular value, the applicable enumerations of another element may change.

By default, OpenStudio-HPXML **automatically validates** the HPXML file against both the XSD and Schematron documents and reports any validation errors.

Creating HPXML Files
--------------------

OpenStudio-HPXML is primarily intended to be used by user interfaces or other automated software workflows that automatically produce the HPXML file.
There are several options available for creating HPXML files.

Existing Software
~~~~~~~~~~~~~~~~~

There are a number of software tools that can generate HPXML files (and potentially run them through OpenStudio-HPXML simulations).

.. note::

  Some software tools may generate older versions of HPXML or produce HPXML files that do not meet the input requirements.
  In these cases, the HPXML file `may need to be updated <https://github.com/NREL/hpxml_version_translator>`_ or manually adjusted.

BuildResidentialHPXML measure
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Another option to create an HPXML file is to use OpenStudio-HPXML's ``BuildResidentialHPXML`` measure.
The measure uses high-level geometry inputs and simple option-based inputs that are specified through an `OpenStudio Workflow (OSW) <https://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/#osw-structure>`_ file.
The OSW is a JSON file that will specify all the OpenStudio measures (and their arguments) to be run sequentially.

| Here's an example of creating an HPXML file (and not running the EnergyPlus model):
| ``openstudio run -m -w workflow/template-build-hpxml.osw``

| And here's an example of creating an HPXML file and also running the EnergyPlus model:
| ``openstudio run -w workflow/template-build-and-run-hpxml.osw``

Inputs and descriptions for the ``BuildResidentialHPXML`` measure can be found in the README.md found at ``BuildResidentialHPXML/README.md``.

Here is an example of some of the inputs used by the measure:

.. code-block:: json

   "location_zip_code": "80203",
   "geometry_attic_type": "Attic, Unvented, Gable",
   "geometry_foundation_type": "Basement, Conditioned",
   "geometry_unit_aspect_ratio": "1.5",
   "geometry_unit_conditioned_floor_area": "2700.0",
   "geometry_unit_num_bedrooms": "3",
   "geometry_unit_direction": "South",
   "geometry_unit_type": "Single-Family Detached, 1 Story",
   "geometry_window_areas_or_wwrs": "108, 108, 72, 72",
   "geometry_door_area": "40.0",
   "enclosure_air_leakage": "3 ACH50",
   "enclosure_ceiling": "R-38",
   "enclosure_foundation_wall": "Solid Concrete, Whole Wall, R-10",
   "enclosure_wall": "Wood Stud, R-21",
   "enclosure_window": "Double, Low-E, Insulated, Air, Med Gain",
   "hvac_ducts": "4 CFM25 per 100ft2, Uninsulated",
   "hvac_heating_system": "Central Furnace, 92% AFUE",
   "hvac_heating_system_fuel": "Natural Gas",
   "hvac_cooling_system": "Central AC, SEER2 13.4",
   "hvac_control_cooling_weekday_setpoint": "78",
   "hvac_control_cooling_weekend_setpoint": "78",
   "hvac_control_heating_weekday_setpoint": "68",
   "hvac_control_heating_weekend_setpoint": "68",
   "dhw_water_heater": "Electricity, Tank, UEF 0.94",

.. note::

  The measure only intends to cover more common building features, not every possible OpenStudio-HPXML input or building technology.
  This keeps the measure simpler to understand and to use.
  If features are needed that are not supported by the measure, further changes to the HPXML file can be applied downstream (or a custom solution may be warranted).

Custom Solution
~~~~~~~~~~~~~~~

Most developers of software tools have developed their own solution to translate their user interface inputs to HPXML files.
This provides full flexibility and control over how the translation occurs.

Sample Files
------------

Dozens of sample HPXML files are included in the ``workflow/sample_files`` and ``workflow/real_homes`` directories.
These files help to illustrate how different building components are described in HPXML.

Each sample file generally makes one isolated change relative to the base HPXML (``base.xml``) building.
For example, the ``base-dhw-dwhr.xml`` file adds a ``DrainWaterHeatRecovery`` element to the building.

You may find it useful to search through the files for certain HPXML elements or compare (diff) a sample file against the ``base.xml`` file.
