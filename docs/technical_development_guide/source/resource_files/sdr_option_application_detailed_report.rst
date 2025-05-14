.. _sdr_option_application_detailed_report:

SDR Option Application Detailed Report
======================================

The ``sdr_option_application_detailed_report.txt`` file is intentionally verbose and exposes the entire Boolean-logic tree with highly detailed breakdown of how the apply logic defined in the SDR project YAML file (e.g., ``project_national/sdr_upgrades_tmy3.yml``) is parsed and applied to buildings in the housing stock sample (typically 550K). This report is invaluable for validating complex apply logic, debugging unexpected behavior, and understanding the precise interplay between different options within an upgrade package. It serves as a deeper dive compared to the summary provided in :ref:`sdr_option_application_report`.

File Location
------------

The file is located at ``project_national/resources/sdr_option_application_detailed_report.txt`` within the ResStock repository.

File Structure
-------------

The file is a plain text report organized sequentially by upgrade scenario as defined in the project YAML file. For each upgrade scenario, the report is divided into two main sections:

1.  **Option-Specific Logic Parsing**: This section repeats for each option within the upgrade package and contains three subsections:
   
   * **Option Apply Report**: Shows the detailed breakdown of the option's specific ``apply_logic`` as defined in the YAML.
     
     It begins in the report with this kind of header:
  
     .. raw:: html
     
        <div class="small-font">
            ----------------------------------------------------------------------<br>
            Option Apply Report for - Upgrade1:'ENERGY STAR he...<br>
            ----------------------------------------------------------------------<br>
        </div>


   * **Package Apply Logic Report**: Shows the breakdown of the upgrade's ``package_apply_logic`` that applies to all options.
     
    It begins in the report with this kind of header:
  
    .. raw:: html
    
      <div class="small-font">
          ----------------------------------------------------------------------<br>
          Package Apply Logic Report...<br>
          ----------------------------------------------------------------------<br>
      </div>

   * **Overall Applicability**: Shows the final count and percentage of buildings to which the specific option applies (considering both option and package logic).

    This section consists of a single line such as below:
  
    .. raw:: html
    
      <div class="small-font">
         Overall applied to => 408859 (74.3%)
      </div>

    The numbers in here corresponds to the ``applicabile_to`` and ``applicable percentage`` for corresponding option in the :ref:`sdr_option_application_report`.

2.  **Upgrade Summary Information**: This section appears once per upgrade after detailing all options specific logic parsing. It provides information about application of combination of options within the upgrade. It has three sections as described below:
   
   * **Overall Package Statistics**: Shows buildings receiving all options versus any option in the package. It consists of two lines as shown below:
    .. raw:: html
    
      <div class="small-font">
         All of the options (and-ing) were applied to: 0 (0.0%)<br>
         Any of the options (or-ing) were applied to: 530447 (96.4%)
      </div>
    The first line shows the number of samples (and percentage) to which all of the options were applied to. If the upgrade contains a set of options that should be mutually exclusive, this number should be 0. Non-zero value here in such cases can indicate errors.

    The second line shows the number of samples which got applied at least one option in the upgrade. If the set of options are designed to cover the whole building stock, this number should be high. 

   * **Applicability Summary Table (by Parameter Type)**: Shows how combinations of *types* of parameters (e.g., 'hvac heating efficiency', 'cooling setpoint') are applied across the building stock.

   * **Applicability Summary Table (by Option Number)**: Shows how combinations of *specific options* (corresponding to their order in the YAML) are applied. There are typically more options than parameter types because same parameter appears multiple times in an upgrade with different options (for example, ``upgrade1.option9 = HVAC Cooling Efficiency|Non-Ducted Heat Pump`` and ``upgrade1.option10 = HVAC Cooling Efficiency|Ducted Heat Pump``)

Reading the file
----------------

The file composed of 4 sections for each upgrade.

**1. Option-Specific Logic Parsing**

For each option within an upgrade, the report presents three key parts:

* **`Option Apply Report`**: This section shows how the specific `apply_logic` for that *individual option* (as defined in the YAML) is parsed and evaluated against the building stock.
* **`Package Apply Logic Report`**: This section shows how the `package_apply_logic` for the *entire upgrade* (as defined in the YAML) is parsed and evaluated. This logic applies as a constraint to *all* options within the upgrade.
* **`Overall applied to`**: This line shows the final number and percentage of buildings that satisfy *both* the Option Apply Logic *and* the Package Apply Logic.

**Understanding the Logic Trees:**

Both the Option and Package Apply Logic reports use an indented tree structure to represent the logic:

* **Operators (`and`, `or`, `not`)**: These correspond directly to the logic defined in the YAML.
    * `and`: All conditions listed under it (at the next indentation level) must be true.
    * `or`: At least one of the conditions listed under it must be true.
    * `not`: The condition listed under it must be false.
* **Conditions**: These are the specific building characteristics being checked (e.g., `HVAC Has Ducts|Yes`, `Heating Fuel|Wood`).
* **Counts and Percentages**: Each line shows the number and percentage of buildings (out of the total stock, e.g., 550,000) that satisfy the logic *up to that point* in the tree.

**Example: Comparing YAML Logic and Report Parsing**

Let's compare the YAML logic with the report's parsed representation sequentially.

**A. Option 1 Apply Logic Comparison:**

* **YAML Definition (`sdr_upgrades_tmy3.yml`):**
    *(This logic is referenced in the YAML as `*ducted_ASHP_apply_logic`)*

    .. code-block:: yaml

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
       and => 413417 (75.2%)  # Result of the implicit 'and'
         HVAC Has Ducts|Yes => 423608 (77.0%) # First condition
         not => 489600 (89.0%) # Start of the 'not' block (buildings NOT matching the 'or' below)
           or => 60400 (11.0%) # Start of the 'or' block (buildings matching ANY shared system)
             HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Electricity => 15757 (2.9%)
             HVAC Shared Efficiencies|Boiler Baseboards Heating Only, Fuel => 23765 (4.3%)
             HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Electricity => 7468 (1.4%)
             HVAC Shared Efficiencies|Fan Coil Heating and Cooling, Fuel => 5802 (1.1%)
             HVAC Shared Efficiencies|Fan Coil Cooling Only => 7608 (1.4%)
       -------------------------------------------------------------------

**B. Package Apply Logic Comparison:**

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
    *(This appears identically for each option within the upgrade)*

    .. code-block:: text

       --------------------------
       Package Apply Logic Report
       --------------------------
       and => 530447 (96.4%) # Result of the top-level implicit 'and'
         not => 541444 (98.4%) # Buildings NOT Wood fuel
           Heating Fuel|Wood => 8556 (1.6%)
         not => 548119 (99.7%) # Buildings NOT Other fuel
           Heating Fuel|Other Fuel => 1881 (0.3%)
         not => 545936 (99.3%) # Buildings NOT None fuel
           Heating Fuel|None => 4064 (0.7%)
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

* **`Overall applied to`**: For Option 1, the report shows `Overall applied to => 408859 (74.3%)`. This means 74.3% of buildings satisfy *both* the Option 1 Apply Logic (resulting in `413417`) *and* the Package Apply Logic (resulting in `530447`). The final result is the intersection of these two sets.

**2. Upgrade Summary Information**

After the details for all options in an upgrade, summary statistics are provided:

* `All of the options (and-ing) were applied to: 0 (0.0%)`
    * Indicates how many buildings received *every single option* listed in this upgrade package (Options 1 through 11 in this case). This is often 0% if options are mutually exclusive (like ducted vs. non-ducted systems). If it is non-zero for mutually exclusive set of options, it signifies error in the apply logic.
* `Any of the options (or-ing) were applied to: 530447 (96.4%)`
    * Indicates how many buildings received *at least one* option from this upgrade package. This number should ideally match the number of buildings eligible under the `Package Apply Logic Report`, confirming that the options cover all intended eligible buildings.
* **Applicability Summary Table (by Option Name)**:
    * This table groups the applied options by their *type* (e.g., `hvac heating efficiency`, `cooling setpoint has offset`).
    * It shows how many buildings receive specific *combinations of option types*.
    * Example:
  
      .. raw:: html
      
       <div class="small-font">
          Report of how the 9 options were applied to the buildings.
       </div>

      .. table::
         :class: small-font
      
         =================== ==================================================== =================== ================ ================
         Number of options   Applied options                                      Applied buildings   Cumulative sub   Cumulative all
         =================== ==================================================== =================== ================ ================
         3                   hvac heating efficiency, hvac cooling efficiency,    408859 (74.3%)      408859 (74.3%)   408859 (74.3%)
                             hvac cooling partial space conditioning                                                   
         9                   hvac heating efficiency, cooling setpoint has        121588 (22.1%)      121588 (22.1%)   530447 (96.4%)
                             offset, cooling setpoint offset magnitude, cooling                                        
                             setpoint offset period, heating setpoint has                                              
                             offset, heating setpoint offset magnitude, heating                                        
                             setpoint offset period, hvac cooling efficiency,                                          
                             hvac cooling partial space conditioning                                                   
         =================== ==================================================== =================== ================ ================

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
    * This table groups applied options by their *specific number* (Option 1, Option 2, etc., based on the YAML order). Based on the ``sdr_option_application_report.csv`` both option 1 and option 2 apply ``hvac heating efficiency`` upgrade but they are kept separate in this table.
    * It shows how many buildings receive specific *combinations of numbered options*.

    .. raw:: html

       <div class="small-font">
          Detailed report of how the 11 options were applied to the buildings.
       </div>
  
    .. table::
       :class: small-font
       
       ===================== =============================== ===================== ================== ==================
       Number of options     Applied options                 Applied buildings     Cumulative sub     Cumulative all    
       ===================== =============================== ===================== ================== ==================
       4                     1, 9, 10, 11                    408859 (74.3%)        408859 (74.3%)     408859 (74.3%)   
       10                    1, 2, 3, 4, 5, 6, 7, 8, 9, 11   121588 (22.1%)        121588 (22.1%)     530447 (96.4%)   
       ===================== =============================== ===================== ================== ==================


    * Example: `4 | 1, 9, 10, 11 | 408859 (74.3%)`. As noted before, this specific combination seems contradictory (mixing ducted option 1 & 10 with non-ducted option 9) and highlights the report's utility for debugging potential logic flaws or unexpected interactions.
    * Example 2: `10 | 1, 2, 3, 4, 5, 6, 7, 8, 9, 11 | 121588 (22.1%)`. Similarly, this combination appears contradictory by including both Option 1 (ducted) and Option 2 (non-ducted). This definitely warrants investigation using the detailed logic trees provided earlier in the report.

These summary tables are crucial for verifying that combinations of options are being applied as intended and identifying potential conflicts or unexpected overlaps.

.. raw:: html

   <style>
   .small-font {
     font-size: 10pt;
   }
   </style>

Usage
-------

The ``sdr_option_application_detailed_report.txt`` file serves several important purposes:

1.  **Logic Parsing Validation**: Allows developers to confirm that complex nested `apply_logic` and `package_apply_logic` from the YAML are being interpreted and combined correctly by the buildstock-query tool.
2.  **Debugging**: Helps identify errors or unexpected outcomes in applicability. For instance, if a specific logic branch applies to zero buildings when it shouldn't, or if mutually exclusive options are applied to the same buildings (as potentially hinted in the example's summary table), this report makes it evident. This provides more insight than the ``sdr_option_application_report.csv``, which might show a reasonable overall percentage while masking underlying logic issues.
3.  **Option Interplay Analysis**: Unlike the CSV report, this file shows precisely which combinations of options are applied together (via the summary tables), allowing validation that packages are formed correctly (e.g., ensuring non-ducted systems get all associated non-ducted options and not ducted ones).
4.  **Reporting**: Provides detailed statistics (building counts and percentages at each logic step) that can be used for documentation or reporting on measure applicability.

Creation
--------
The ``sdr_option_application_detailed_report.txt`` file is automatically generated by a ResStock Continuous Integration (CI) job. This job utilizes the `upgrades_analyzer` tool within `buildstock-query`. The tool takes the project YAML file (e.g., ``project_national/sdr_upgrades_tmy3.yml``) and a representative housing stock sample (typically 550K buildings) as input. When changes are made to the upgrade YAML file (specifically the apply logic) or potentially if the underlying housing stock characteristics change significantly, the CI job reruns the analysis and commits the updated report to the ``project_national/resources/`` directory in the repository. This ensures the report stays synchronized with the current logic and stock representation.