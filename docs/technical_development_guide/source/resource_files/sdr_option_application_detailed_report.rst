.. _sdr_option_application_detailed_report:

SDR Option Application Detailed Report
======================================

The ``sdr_option_application_detailed_report.txt`` file is intentionally verbose and exposes the entire boolean-logic tree with highly detailed breakdown of how the apply logic defined in the SDR project YAML file (e.g., ``project_national/sdr_upgrades_tmy3.yml``) is parsed and applied to buildings in the housing stock sample (typically 550K). This report is invaluable for validating complex apply logic, debugging unexpected behavior, and understanding the precise interplay between different options within an upgrade package. It serves as a deeper dive compared to the summary provided in :ref:`sdr_option_application_report`.

File Location
-------------

The file is located at ``project_national/resources/sdr_option_application_detailed_report.txt`` within the ResStock repository.

File Structure
--------------

The file is a plain text report organized sequentially by upgrade scenario as defined in the project YAML file. For each upgrade scenario, the report is divided into two main sections:

1.  **Option-Specific Logic Parsing**: This section repeats for each option within the upgrade package and contains three subsections:
   
   * **Option Apply Logic Report**: Shows the detailed breakdown of the parsing of the option's ``apply_logic`` as defined in the YAML.
     
     It begins in the report with this kind of header:
  
     .. raw:: html
     
        <div class="small-font">
            ----------------------------------------------------------------------<br>
            Option Apply Report for - Upgrade1:'ENERGY STAR he...<br>
            ----------------------------------------------------------------------<br>
        </div>
    
    and follows with breakdown of the ``apply_logic``. We will explain in more details later how to ready this breakdown.

   * **Package Apply Logic Report**: Shows the breakdown of the upgrade's ``package_apply_logic`` that applies to all options.
     
    It begins in the report with this kind of header:
  
    .. raw:: html
    
      <div class="small-font">
          ----------------------------------------------------------------------<br>
          Package Apply Logic Report...<br>
          ----------------------------------------------------------------------<br>
      </div>

    and follows with the breakdown of the ``package_apply_logic``.

    * **Overall Applicability**: Shows the final count and percentage of buildings to which the option applies to considering both ``apply_logic`` and ``package_apply_logic``. This number corresponds to the ``applicabile_to`` and ``applicable percentage`` for corresponding option in the :ref:`sdr_option_application_report`.

    This section consists of a single line such as below:
  
    .. raw:: html
    
      <div class="small-font">
         Overall applied to => 408859 (74.3%)
      </div>

    

2.  **Upgrade Summary Information**: This section appears once per upgrade after detailing all options specific logic parsing. It provides information about application of combination of options within the upgrade. It has three sections:
   
   
   * **Overall Package Statistics**: Shows buildings receiving all options versus any option in the package. It consists of two lines as shown below:

    .. raw:: html
    
      <div class="small-font">
         All of the options (and-ing) were applied to: 0 (0.0%)<br>
         Any of the options (or-ing) were applied to: 530447 (96.4%)
      </div>
    
    The first line shows the number of samples (and percentage) to which all of the options were applied to. If the upgrade contains a set of options that should be mutually exclusive, this number should be 0.
    
    However, note that sometimes option apply logics are defined in progressive way. For example, one might assign a medium efficiency HPWH to all the buildings in option 1 (applicability=100%) and then assign a high efficiency HPWH to select buildings in option 2 (say, applicability=20%) of the same upgrade. Since no building can have both a medium efficiency and high efficiency HPWH, the options are mutually exlcusive. However, the apply logic doesn't necessarily have to be. ResStock automatically assigns the last option to the building when the same parameter (HPWH, in this example) is attempted to be assigned multiple options. In this example, since 20% of buildings will be attempted to be assigned medium efficiecny HPWH followed by high efficiency HPWH, ResStock will only apply the high efficiency HPWH to those buildings. We will have non-zero value in first line in such cases, however, it doesn't indicate any error.

    The second line shows the number of samples which got applied at least one option in the upgrade. If the set of options are designed to (almost) cover the whole building stock, this number should be 100% (or close to it). 

   * **Applicability Summary Table (by Parameter Type)**: This is the second section under upgrade summary information and it shows how combinations of *types* of parameters (e.g., 'hvac heating efficiency', 'cooling setpoint') are applied across the building stock. It is formated as a table with the following header:

    .. raw:: html
    
      <div class="small-font">
      -------------------------------------------------------------------------------<br>
         Report of how the 9 options were applied to the buildings.<br>
      -------------------------------------------------------------------------------<br>
      </div>

   * **Applicability Summary Table (by Option Number)**: This is the third secion under the upgrade summary information and it shows how combinations of *specific options* (corresponding to their order in the YAML) are applied. This is different from the table above because there are typically more options than parameter types because same parameter appears multiple times in an upgrade with different options. For example if ``upgrade1.option9 = HVAC Cooling Efficiency|Non-Ducted Heat Pump`` and ``upgrade1.option10 = HVAC Cooling Efficiency|Ducted Heat Pump`` then both `option 9` and `option 10` are grouped together into `hvac_cooling_efficiency` in the previous table but kept separate in this table. This table begins with the following header:

    .. raw:: html
    
      <div class="small-font">
        ----------------------------------------------------------------------------------<br>
         Detailed report of how the 11 options were applied to the buildings.<br>
        ----------------------------------------------------------------------------------<br>
      </div>


Reading the details
-------------------

Understanding the Apply Logic Breakdown
---------------------------------------

Both the Option and Package Apply Logic reports use an indented tree structure to represent the parsing of the logic:

* **Operators (`and`, `or`, `not`)**: These correspond directly to the logic defined in the YAML.
    * `and`: All conditions listed under it (at the next indentation level) must be true.
    * `or`: At least one of the conditions listed under it must be true.
    * `not`: The condition listed under it must be false.
* **Conditions**: These are the specific building characteristics being checked (e.g., `HVAC Has Ducts|Yes`, `Heating Fuel|Wood`).
* **Counts and Percentages**: Each line shows the number and percentage of samples (out of the total of 550,000) that satisfy the logic *up to that point* in the tree.


Let's compare the YAML logic with the report's parsed representation sequentially.

**Example Option Apply Logic Breakdown:**

* **YAML Definition (`sdr_upgrades_tmy3.yml`):**
    *(This logic is referenced in the YAML as `*ducted_ASHP_apply_logic`)*

    .. code-block:: yaml

       option: HVAC Heating Efficiency|ASHP, SEER 16, 9.2 HSPF
       apply_logic: &ducted_ASHP_apply_logic
         # Implicit 'and' for top-level list
         - HVAC Has Ducts|Yes
         - not:
           - or:
             - HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Electricity
             - HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Fuel
             - HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Electricity
             - HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Fuel
             - HVAC Shared Efficiencies|Fan Coil Cooling Only

* **Parsed Representation in Report (`sdr_option_application_detailed_report.txt`):**

    .. code-block:: text

       --------------------------------------------------------------------------------------------------------------------------------------
       Option Apply Report for - Upgrade1:'ENERGY STAR heat pump with elec backup', Option1:'HVAC Heating Efficiency|ASHP, SEER 16, 9.2 HSPF'
       --------------------------------------------------------------------------------------------------------------------------------------
       and => 413417 (75.2%)  # Result of the implicit 'and' between HVAC Has Ducts and 'not' block
         HVAC Has Ducts|Yes => 423608 (77.0%) # First condition
         not => 489600 (89.0%) # Start of the 'not' block (buildings NOT matching the 'or' below)
           or => 60400 (11.0%) # Start of the 'or' block (buildings matching ANY shared system)
             HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Electricity => 15757 (2.9%)
             HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Fuel => 23765 (4.3%)
             HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Electricity => 7468 (1.4%)
             HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Fuel => 5802 (1.1%)
             HVAC Shared Efficiencies|Fan Coil Cooling Only => 7608 (1.4%)
       -------------------------------------------------------------------

  Based on the parsed report, the logic applies to 413417 building samples, which is 75.2% of the total stock of 550,000 samples. This doesn't mean the option applies to that many buildings since the applicability can further be reduced by the package apply logic. The final applicability for an option is intersction of the option apply logic and package apply logic. This final number can be found on the `Overall applied to` line or the :ref:`sdr_option_application_report`. All percentages are based on the total stock sample of 550,000.

**Example Package Apply Logic Breakdown:**

* **YAML Definition (`sdr_upgrades_tmy3.yml`):**
    *(This logic is referenced in the YAML as `*remove_high_rise_shared`)*

    .. code-block:: yaml

       package_apply_logic: &remove_high_rise_shared
         # Implicit 'and' for top-level list
         - not: Heating Fuel|Wood
         - not: Heating Fuel|Other Fuel
         - not: Heating Fuel|None
         - not: # Applies to the OR block below
           - or:
             - HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Electricity
             - HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Fuel
             - HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Electricity
             - HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Fuel
             - HVAC Shared Efficiencies|Fan Coil Cooling Only
         - not: # Applies to the AND block below (Interpretation matching report structure)
           - and:
             - Geometry Building Type Height|Multi-Family with 5+ Units, 8+ Stories

* **Parsed Representation in Report (`sdr_option_application_detailed_report.txt`):**
    *(This appears identically for all options within the upgrade)*

    .. code-block:: text

       --------------------------
       Package Apply Logic Report
       --------------------------
       and => 530447 (96.4%) # Result of the top-level implicit 'and'
         not => 541444 (98.4%) # Buildings NOT Wood fuel
           Heating Fuel|Wood => 8556 (1.6%)  # Buildings with Wood fuel
         not => 548119 (99.7%) # Buildings NOT Other fuel
           Heating Fuel|Other Fuel => 1881 (0.3%)  # Buildings with Other fuel
         not => 545936 (99.3%) # Buildings NOT None fuel
           Heating Fuel|None => 4064 (0.7%)  # Buildings with None fuel
         not => 544870 (99.1%) # Buildings NOT matching the 'or' block below
           or => 60400 (11.0%) # Buildings matching ANY shared system
             HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Electricity => 15757 (2.9%)
             HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Fuel => 23765 (4.3%)
             HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Electricity => 7468 (1.4%)
             HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Fuel => 5802 (1.1%)
             HVAC Shared Efficiencies|Fan Coil Cooling Only => 7608 (1.4%)
         not => 538732 (98.0%) # Buildings NOT matching the 'and' block below
           and => 11268 (2.0%) # Buildings matching the High-Rise MF criteria
             Geometry Building Type Height|Multi-Family with 5+ Units, 8+ Stories => 11268 (2.0%)
       ------------------------------------------------------------------------------------------

    Based on the parsed report, the package apply logic applies to 530447 building samples, which is 96.4% of the total stock of 550,000 samples. This doesn't mean the option applies to that many buildings since the final applicability for an option is intersection of the option apply logic and package apply logic. This final number can be found on the `Overall applied to` line or the :ref:`sdr_option_application_report`. All percentages are based on the total stock sample of 550,000.


Understanding Upgrade Summary Tables
-------------------------------------

* **Applicability Summary Table (by Option Name)**:

 
  This table groups the applied options by their *type* (e.g., `hvac heating efficiency`, `cooling setpoint has offset`). It shows how many buildings receive specific *combinations of option types*.
  

  Let's look at an example:
  
      .. raw:: html

       <div class="small-font">
          ----------------------------------------------------------------------<br>
          Report of how the 9 options were applied to the buildings.<br>
          ----------------------------------------------------------------------<br>
       </div>

      .. list-table::
        :class: small-font
        :widths: 10 40 20 20 10
        :header-rows: 1

        * - Number of options
          - Applied options
          - Applied buildings
          - Cumulative sub
          - Cumulative all
        * - 3
          - hvac heating efficiency, hvac cooling efficiency, hvac cooling partial space conditioning
          - 408 859 (74.3%)
          - 408 859 (74.3%)
          - 408 859 (74.3%)
        * - 9
          - hvac heating efficiency, cooling setpoint has offset, ... hvac cooling partial space conditioning
          - 121 588 (22.1%)
          - 121 588 (22.1%)
          - 530 447 (96.4%)

  In the table, the first row shows number of samples receiving exactly 3 distinct type of options (namely hvac heating efficiency, hvac cooling efficiency and hvac cooling partial space conditioning). The "Applied buildings" column shows the count and percentage of buildings receiving exactly that combination of options. The "Cumulative sub" column shows the running total within the same number of options category, while "Cumulative all" shows the running total across all categories, reaching 96.4% in this example. For reference, the ``sdr_option_application_report.csv`` below shows how the 11 options defined in upgrade 1 applies. Since option 1 and option 2 both apply ``hvac heating efficiency`` option, in this table, they are grouped together.


.. list-table:: sdr_option_application_report.csv
    :header-rows: 1
    :widths: 5 45 8 35 12 10
    :class: small-font

    * - upgrade
      - upgrade_name
      - option_num
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
    * - 1
      - ENERGY STAR heat pump with elec backup
      - 4
      - Cooling Setpoint Offset Magnitude|0F
      - 121588
      - 22.1
    * - 1
      - ENERGY STAR heat pump with elec backup
      - 5
      - Cooling Setpoint Offset Period|None
      - 121588
      - 22.1
    * - 1
      - ENERGY STAR heat pump with elec backup
      - 6
      - Heating Setpoint Has Offset|No
      - 121588
      - 22.1
    * - 1
      - ENERGY STAR heat pump with elec backup
      - 7
      - Heating Setpoint Offset Magnitude|0F
      - 121588
      - 22.1
    * - 1
      - ENERGY STAR heat pump with elec backup
      - 8
      - Heating Setpoint Offset Period|None
      - 121588
      - 22.1
    * - 1
      - ENERGY STAR heat pump with elec backup
      - 9
      - HVAC Cooling Efficiency|Non-Ducted Heat Pump
      - 121588
      - 22.1
    * - 1
      - ENERGY STAR heat pump with elec backup
      - 10
      - HVAC Cooling Efficiency|Ducted Heat Pump
      - 408859
      - 74.3
    * - 1
      - ENERGY STAR heat pump with elec backup
      - 11
      - HVAC Cooling Partial Space Conditioning|100% Conditioned
      - 530447
      - 96.4
    * - 1
      - ENERGY STAR heat pump with elec backup
      - -1
      - All
      - 530447
      - 96.4

* **Applicability Summary Table (by Option Number)**:
  This is similar to the previous table but it treats all options as distinct and doesn't group options by the paramter name. In the example below, based on the ``sdr_option_application_report.csv`` both option 1 and option 2 apply ``hvac heating efficiency`` upgrade but they are kept separate in this table. It shows how many buildings receive specific *combinations of numbered options*. 

    .. raw:: html

       <div class="small-font">
          ---------------------------------------------------------------------------------<br>
          Detailed report of how the 11 options were applied to the buildings.<br>
          ---------------------------------------------------------------------------------<br>
       </div>
  
    .. table::
       :class: small-font
       
       ===================== =============================== ===================== ================== ==================
       Number of options     Applied options                 Applied buildings     Cumulative sub     Cumulative all    
       ===================== =============================== ===================== ================== ==================
       4                     1, 9, 10, 11                    408859 (74.3%)        408859 (74.3%)     408859 (74.3%)   
       10                    1, 2, 3, 4, 5, 6, 7, 8, 9, 11   121588 (22.1%)        121588 (22.1%)     530447 (96.4%)   
       ===================== =============================== ===================== ================== ==================

  In the table, the first row shows that exactly 4 options (numbered 1, 9, 10, and 11) applies to 74.3% of the buildings and the second row shows that exactly 10 options applies to 22.1% of the buildings.  The Cumulative all at the bottom right shows that 96.4% of the buildings get either of these two combination of options.



These summary tables are crucial for verifying that combinations of options are being applied as intended and identifying potential conflicts or unexpected overlaps. For example, ``Applicability Summary Table (by Option Number)`` above shows that the offset options (3 to 8) are never applied with otion 10 (ducted heat pump upgrade) but they are applied with option 9 (non-ducted heat pump upgrade). This may or may not be what is desired - the report only highlights the case and helps with debugging.

.. raw:: html

   <style>
   .small-font {
     font-size: 10pt;
   }
   </style>

Usage
-------

The ``sdr_option_application_detailed_report.txt`` helps with:

1.  **Logic Parsing Validation**: Allows developers to confirm that complex nested `apply_logic` and `package_apply_logic` from the YAML are being interpreted and combined as intented.
2.  **Debugging**: Helps identify errors or unexpected outcomes in applicability. For instance, if a specific logic branch applies to zero buildings when it shouldn't, or if mutually exclusive options are applied to the same buildings, this report makes it evident. This provides more insight than the ``sdr_option_application_report.csv``, which might show a reasonable overall percentage while masking underlying logic issues.
3.  **Option Interplay Analysis**: Unlike the CSV report, this file shows precisely which combinations of options are applied together (via the summary tables), allowing validation that packages are formed correctly (e.g., ensuring non-ducted systems get all associated non-ducted options and not ducted ones etc).
4.  **Reporting**: Provides detailed statistics (building counts and percentages at each logic step) that can be used for documentation or reporting on measure applicability.

Creation
--------
The ``sdr_option_application_detailed_report.txt`` file is automatically generated by a ResStock Continuous Integration (CI) job. This job utilizes the `upgrades_analyzer` tool within `buildstock-query`. The tool takes the project YAML file (e.g., ``project_national/sdr_upgrades_tmy3.yml``) and a representative housing stock sample (typically 550K buildings) as input. When changes are made to the upgrade YAML file (specifically the apply logic) or potentially if the underlying housing stock characteristics change significantly, the CI job reruns the analysis and commits the updated report to the ``project_national/resources/`` directory in the repository. This ensures the report stays synchronized with the current logic and stock representation.