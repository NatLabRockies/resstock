Upgrade Scenario Configuration
==============================

There is quite a bit more flexibility and capability in defining an upgrade scenario than was discussed in the :ref:`basic tutorial <tutorial-apply-upgrade>`.
Here we will go through each field in the **Apply Upgrade** measure and discuss how it can be used to build more complicated real-life scenarios for upgrades.

Upgrade Name
------------

This is a human readable name for the upgrade scenario.
Something like, "Replace electric furnaces with Energy Star heat pumps" or "Insulate attics to R-49".

Option <#>
----------

In this field we enter the parameter and option combination to be applied.
In the upgrade scenario simulations, this option will replace the option for the corresponding parameter in the baseline run.
These can be found and referenced in the ``resources/options_lookup.tsv`` file in your local git repository.
You can see the most updated version `on github here <https://github.com/NREL/resstock/blob/develop/resources/options_lookup.tsv>`_, but it's recommended to use your local version as it will be synchronized with your project.
The file can be opened in a spreadsheet editor like Excel for viewing. 

The text to enter in the field will be the Parameter Name followed by the Option Name separated by a pipe character.

.. code::

   Insulation Wall|Wood Stud, R-36

.. _apply-logic:

Option <#> Apply Logic
----------------------

The apply logic field specifies the conditions under which the option will apply based on the baseline building's options.
To specify the condition(s) include one or more ``parameter|option`` pairs from ``options_lookup.tsv``.
Multiple option conditions can be joined using the following logical operators. Parentheses may be used as necessary as well.

====== ===========
``||`` logical OR
``&&`` logical AND
``!``  logical NOT
====== ===========

A few examples will illustrate.
First, lets say we want the apply the option ``Water Heater|Gas Tankless``, but only for water heaters that are worse and also use gas.
We would use the following apply logic:

.. code::
   
   Water Heater|Gas Standard||Water Heater|Gas Benchmark

Or say we want to apply the upgrade only to houses with 3 car garages that aren't in New England.

.. code::
   
   (!Location Census Division|New England)&&(Geometry Garage|3 Car)
   
Currently, you can enter up to 25 options per upgrade.
To allow additional options per upgrade you would need to update a method defined in a resource file, run a rake task, and update the outputs section for all PAT projects. See :doc:`../advanced_tutorial/increasing_upgrade_options` for more information.

Option <#> Cost <#>
-------------------

This is the cost of the upgrade.
Multiple costs can be entered and each is multiplied by a cost multiplier, described below.

Option <#> Cost <#> Multiplier
------------------------------

The cost above is multiplied by this value, which is a function of the building.
Since there can be multiple costs (currently 2), this permits both fixed and variable costs for upgrades that depend on the properties of the baseline house.

See the :ref:`upgrade-costs` workflow outputs for a list of all available multiplier types.

Package Apply Logic
-------------------

This is where to specifiy logic to determine whether the whole package of upgrades is applied (all of the options together).
It uses the same format as :ref:`apply-logic`.
