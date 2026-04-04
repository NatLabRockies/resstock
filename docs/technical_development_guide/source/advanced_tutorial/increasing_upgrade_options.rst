Increasing Upgrade Options
==========================

To allow more options per upgrade, increase the value returned by the following method defined in ``measures/ApplyUpgrade/resources/constants.rb``:

.. code::

  module Constants
    NumApplyUpgradeOptions = 100
    NumApplyUpgradesCostsPerOption = 2
  ...
  
Then run ``openstudio tasks.rb update_measures``. See :doc:`running_task_commands` for instructions on how to run tasks.
