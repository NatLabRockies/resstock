from typing import Dict


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