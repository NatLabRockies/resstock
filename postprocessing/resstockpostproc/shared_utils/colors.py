QUALITATIVE_SERIES = [
    "#0079C2",
    "#7DA544",
    "#812E36",
    "#626D72",
    "#00A4E4",
    "#9ECE42",
    "#FFC423",
    "#B365D1",
    "#A32F1C",
]
REF_QUALITATIVE_SERIES = [
    "#A16911",
    "#5D1A70",
]
nrel_color_series = [
    ["#0B5E90", "#0079C2", "#00A3E4", "#5DD2FF"],
    ["#A16911", "#EE9521", "#FFC423", "#FFD200"],
    ["#3D6321", "#7DA544", "#9ECE42", "#C1EE86"],
    ["#000000", "#212121", "#282D30", "#3A4246"],
]
FUEL_COLORS = {
    "electricity": nrel_color_series[1][1],
    "natural gas": nrel_color_series[0][2],
    "propane": nrel_color_series[2][0],
    "fuel oil": nrel_color_series[3][0],
}