"""
Electrical Panel Project: support controls simulation in OCHRE
Downselect 20 (occupied) SFD in VT from EUSS 1.0, using newly sampled buildstock for VT containing:

- 5 homes with electric heating fuel
- 15 homes with non-electric heating fuel

By: Lixi.Liu@nrel.gov
Date: 02/03/2023
"""
import pandas as pd
from pathlib import Path


def downselect_buildstock(bst_to_match, bst_to_search, HC_to_match, HC_to_search=None):
    """ downselect buildings in bst_to_search based on bst_to_match 
    by matching the list of HC_to_match as much as possible

    If multiple matches are possible, a random draw takes place

    Args :
        bst_to_match : pd.DataFrame
            builstock to match to
        bst_to_search : pd.DataFrame
            buildstock or simulated results to search from
        HC_to_match : list(str)
            list of housing characteristics to match to, order-dependent
            items in the list need to match columns in bst_to_match
        HC_to_search : list(str)
            list of housing characteristics corresponding to HC_to_match
            that would be available as columns in bst_to_search
            Optional, if None, HC_to_search = HC_to_match

    Returns : 
        DF : a subset of bst_to_search based on matching criteria
    """

    if HC_to_search is None:
        HC_to_search = HC_to_match

    # QC
    for hc, ehc in zip(HC_to_match, HC_to_search):
        assert hc in bst_to_match.columns
        assert ehc in bst_to_search.columns

    print(
        f"Sampling {len(bst_to_match)} rows from: {results_to_sample} \n"
        f"to match buildstock: {buildstock_to_match}..."
    )

    DF = []
    for i, row in bst_to_match.iterrows():
        df = bst_to_search.copy()
        bhc = "None"  # housing char before
        n = 0
        for hc, ehc in zip(HC_to_match, HC_to_search):
            cond = bst_to_search[ehc] == row[hc]

            if hc in ["Clothes Dryer", "Cooking Range"]:
                # match fuel type only
                val = row[hc].split(",")[0]
                cond = bst_to_search[ehc].str.startswith(val)

            df2 = df.loc[cond, :]
            if len(df2) < 1:
                hc = bhc
                break
            df = df2
            bhc = hc
            n += 1

        print(
            f"Row {i+1} in buildstock matches {len(df)} sample(s) in EUSS after matching {n} HC(s) up to: {hc}"
        )
        # randomly select 1
        sample = df.sample(1, random_state=9)
        DF.append(sample)
        bst_to_search.drop(index=sample.index, inplace=True)

    DF = pd.concat(DF, axis=0, ignore_index=True)
    return DF

# --- Main ---

# new buildstock
buildstock_to_match = Path("/Users/lliu2/Downloads/buildstock-vt-5-electric.csv")  # <---
vt_bst = pd.read_csv(buildstock_to_match)

# EUSS results, with in.<> and out.<> columns
results_to_sample = Path("/Users/lliu2/Downloads/euss_baseline-vt.csv")  # <---
euss_bl = pd.read_csv(results_to_sample)

# EUSS buildstock
buildstock_euss = Path("/Users/lliu2/Documents/Lab Call 5A - electrical panel constraints/FY23/Panels Estimation/euss1_buildstock.csv")
euss_bst = pd.read_csv(buildstock_euss, low_memory=False)

HC = [
    "State",
    "Geometry Building Type RECS",
    "Heating Fuel",
    "HVAC Heating Type",
    "Water Heater Fuel",
    "Clothes Dryer",  # has usage
    "Cooking Range",  # has usage
    "Misc Gas Fireplace",
    "Misc Gas Grill",
    "Misc Gas Lighting",
    "Geometry Floor Area",
    "Geometry Wall Type",
    "Vintage",
    "Insulation Wall",
    "Infiltration",
    "Occupants",
    "Windows",
    "Usage Level",
    "Plug Load Diversity",
    "HVAC Heating Efficiency",
    "Water Heater Efficiency",
    "HVAC Cooling Efficiency",
    "Hot Water Fixtures",
    "PUMA Metro Status",
    "Geometry Foundation Type",
    "Geometry Stories",
]

# 1. downselect EUSS results
euss_hc = [f"in.{x.lower().replace(' ', '_')}" for x in HC]
euss_results = downselect_buildstock(vt_bst, euss_bl, HC, euss_hc)

# save to file
output_file = results_to_sample.parent / (
    results_to_sample.stem + f"__{len(euss_results)}samples" + results_to_sample.suffix
)
euss_results.to_csv(output_file, index=False)
print(f"EUSS down-selected result output to: {output_file}\n")

# 2. downselect EUSS buildstock
euss_buildstock = euss_bst.loc[euss_bst["Building"].isin(euss_results["bldg_id"])]

output_file = results_to_sample.parent / (
    results_to_sample.stem + f"_buildstock__{len(euss_buildstock)}samples" + results_to_sample.suffix
)
euss_buildstock.to_csv(output_file, index=False)
print(f"EUSS down-selected buildstock output to: {output_file}\n")
