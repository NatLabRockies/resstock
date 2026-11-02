NUM2MONTH = {
    1: "JAN",
    2: "FEB",
    3: "MAR",
    4: "APR",
    5: "MAY",
    6: "JUN",
    7: "JUL",
    8: "AUG",
    9: "SEP",
    10: "OCT",
    11: "NOV",
    12: "DEC",
}
STATE2ABBR: dict[str, str] = {
    "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
    "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
    "Florida": "FL", "Georgia": "GA", "Hawaii": "HI", "Idaho": "ID",
    "Illinois": "IL", "Indiana": "IN", "Iowa": "IA", "Kansas": "KS",
    "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME", "Maryland": "MD",
    "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN", "Mississippi": "MS",
    "Missouri": "MO", "Montana": "MT", "Nebraska": "NE", "Nevada": "NV",
    "New Hampshire": "NH", "New Jersey": "NJ", "New Mexico": "NM", "New York": "NY",
    "North Carolina": "NC", "North Dakota": "ND", "Ohio": "OH", "Oklahoma": "OK",
    "Oregon": "OR", "Pennsylvania": "PA", "Rhode Island": "RI", "South Carolina": "SC",
    "South Dakota": "SD", "Tennessee": "TN", "Texas": "TX", "Utah": "UT",
    "Vermont": "VT", "Virginia": "VA", "Washington": "WA", "West Virginia": "WV",
    "Wisconsin": "WI", "Wyoming": "WY", "District of Columbia": "DC",
}
ABBR2STATE: dict[str, str] = {v: k for k, v in STATE2ABBR.items()}


# RECS census divisions are a fixed partition of the states -- the nine Census divisions with
# Mountain split into North (CO, ID, MT, UT, WY) and South (AZ, NM, NV). A dwelling unit's
# division therefore follows from its state with nothing lost, which is what lets a run that
# publishes allocated geography only down to the state still be compared at division grain.
# Extracted from the unallocated baseline publication, where the published division and the
# state agree by construction, and verified to be a function: 51 states, 10 divisions, no
# state carrying two divisions.
STATE2CENSUS_DIVISION_RECS: dict[str, str] = {
    "IL": "East North Central",
    "IN": "East North Central",
    "MI": "East North Central",
    "OH": "East North Central",
    "WI": "East North Central",
    "AL": "East South Central",
    "KY": "East South Central",
    "MS": "East South Central",
    "TN": "East South Central",
    "NJ": "Middle Atlantic",
    "NY": "Middle Atlantic",
    "PA": "Middle Atlantic",
    "CO": "Mountain North",
    "ID": "Mountain North",
    "MT": "Mountain North",
    "UT": "Mountain North",
    "WY": "Mountain North",
    "AZ": "Mountain South",
    "NM": "Mountain South",
    "NV": "Mountain South",
    "CT": "New England",
    "MA": "New England",
    "ME": "New England",
    "NH": "New England",
    "RI": "New England",
    "VT": "New England",
    "AK": "Pacific",
    "CA": "Pacific",
    "HI": "Pacific",
    "OR": "Pacific",
    "WA": "Pacific",
    "DC": "South Atlantic",
    "DE": "South Atlantic",
    "FL": "South Atlantic",
    "GA": "South Atlantic",
    "MD": "South Atlantic",
    "NC": "South Atlantic",
    "SC": "South Atlantic",
    "VA": "South Atlantic",
    "WV": "South Atlantic",
    "IA": "West North Central",
    "KS": "West North Central",
    "MN": "West North Central",
    "MO": "West North Central",
    "ND": "West North Central",
    "NE": "West North Central",
    "SD": "West North Central",
    "AR": "West South Central",
    "LA": "West South Central",
    "OK": "West South Central",
    "TX": "West South Central",
}

UtilityName2ID = {
    "AEP (OH)": 14006,  # using Ohio Power (OH)
    # "Ameren (MO)": 19436,  # = Union Electric (MO) - doesn't have full year data
    "Appalachian (VA)": 733,
    "BGE (MD)": 1167,
    "ComEd (IL)": 4110,
    # FirstEnergy OH: 6458,
    "OhioEd (OH)": 13998,
    "Cleveland (OH)": 3755,
    "ToledoEd (OH)": 18997,
    # FirstEnergy PA: 6458,
    "MetEd (PA)": 12390,
    "Penelec (PA)": 14711,
    "PP (PA)": 14716,
    "WPP (PA)": 20387,

    "PECO (PA)": 14940,
    "PG&E (CA)": 14328,
    "SCE (CA)": 17609,
    "ERCOT": -1,
}
ID2UtilityName: dict[int, str] = {v: k for k, v in UtilityName2ID.items()}