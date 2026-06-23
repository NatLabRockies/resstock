Increasing Upgrade Options
==========================

To allow more options per upgrade or costs per option, increase the relevant constants assigned in ``measures/ApplyUpgrade/resources/constants.rb``:

.. code::

  module Constants
    NumApplyUpgradeOptions = 100
    NumApplyUpgradesCostsPerOption = 2
  ...
  
Then run ``openstudio tasks.rb update_measures``. See :doc:`testing_infrastructure/running_task_commands` for instructions on how to run tasks.
