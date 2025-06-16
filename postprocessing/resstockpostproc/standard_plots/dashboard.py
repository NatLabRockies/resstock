import os
import webbrowser
from itertools import zip_longest
from pathlib import Path

import dash
import dash_bootstrap_components as dbc  # type: ignore
from dash import ALL, dcc, html

# import PreventUpdate
from dash.exceptions import PreventUpdate
from dash_extensions.enrich import DashProxy, MultiplexerTransform  # type: ignore

external_script = ["https://tailwindcss.com/", {"src": "https://cdn.tailwindcss.com"}]
transforms = [MultiplexerTransform()]

app = DashProxy(
    __name__,
    external_stylesheets=[dbc.themes.BOOTSTRAP],
    transforms=transforms,
    external_scripts=external_script,
)

cur_dir = Path(__file__).parent
ROOT_FOLDER = cur_dir / "buildstock_viz_plots"
ROOT_FOLDER = Path("/Users/radhikar/Documents/buildstock2025/resstock_amy2018_release_2/plots")
root_path = str(ROOT_FOLDER)


def get_subdirectories(path):
    """
    Get a list of subdirectories for a given path.
    """
    return [name for name in os.listdir(path) if os.path.isdir(os.path.join(path, name))]


def get_files(path):
    """
    Get a list of files for a given path.
    """
    return [name for name in os.listdir(path) if os.path.isfile(os.path.join(path, name))]


def get_selection_row(entity_list, indx, initial_value):
    if "=" in entity_list[0]:
        name = entity_list[0].split("=")[0]
        labels = [f.split("=")[1] for f in entity_list]
    else:
        name = ""
        labels = entity_list
    labels = [label.removesuffix(".html") for label in labels]
    name_labels_text = name + ":" + "-".join(labels)
    row = dbc.Row(
        [
            dbc.Col(html.Label(name), width="auto", style={"text-align": "left"}),
            dbc.Col(
                dcc.RadioItems(
                    id={"type": "radio-selection", "index": indx, "name_labels_text": name_labels_text},
                    options=[{"label": lbl, "value": val} for val, lbl in zip(entity_list, labels)],
                    value=initial_value,
                    labelStyle={"display": "inline-block", "margin-right": "10px"},
                ),
                width=6,
            ),
        ],
        id={"type": "radio-row", "index": indx, "name_labels_text": name_labels_text},
        className="my-3 align-items-start",
        justify="start",
    )
    return row


def get_downstream_rows(path, current_values, index):
    """
    Get the rows of radio buttons for all the subdirectories below a given path.
    """
    rows = []
    while True:
        entities = sorted(get_subdirectories(path))
        if not entities:
            break
        if "html" in entities:
            path = path + "/html"
            files = get_files(path)
            entities = sorted([f for f in files if f.endswith(".html")])

        try:
            initial_value = current_values[index] if current_values[index] in entities else entities[0]
        except IndexError:
            initial_value = entities[0]

        rows.append(get_selection_row(entities, index, initial_value))
        if ".html" in entities[0]:
            break
        path = path + "/" + initial_value
        index += 1
    return rows


app.layout = dbc.Container(
    html.Div(
        [
            dcc.Location(id="url", refresh=False),
            dbc.Row([dbc.Col(html.H1("Plots Viewer (beta)"), width="2")]),
            # Dropdown menu to select the first-level plot subfolder
            # html.Label('Enter root path: '),
            dcc.Input(id="root-path", type="text", value=str(ROOT_FOLDER), size="100"),
            html.Br(),
            html.Br(),
            html.Div(id="dropdown-container"),
            html.Br(),
            html.Iframe(id="plot-display", width="100%", height="1000", sandbox="allow-scripts"),
        ]
    ),
    className="mx-5 my-1",
)


@app.callback(
    dash.dependencies.Output("dropdown-container", "children"), [dash.dependencies.Input("root-path", "value")]
)
def update_dropdowns(root_path):
    return get_downstream_rows(root_path, [], 0)


@app.callback(
    dash.dependencies.Output("plot-display", "srcDoc"),
    dash.dependencies.Output("dropdown-container", "children"),
    dash.dependencies.State("root-path", "value"),
    dash.dependencies.State("dropdown-container", "children"),
    [dash.dependencies.Input({"type": "radio-selection", "index": ALL, "name_labels_text": ALL}, "value")],
)
def update_dropdowns2(root_path, current_children, selection):
    if not selection or not selection[0]:
        raise PreventUpdate()
    trigger_index = next(val["index"] for val in dash.callback_context.triggered_prop_ids.values())
    trigger_inputs = list(dash.callback_context.inputs.values())
    trigger_path = "/".join(trigger_inputs[: trigger_index + 1])
    current_path = root_path + "/" + trigger_path

    def get_value(child):
        if isinstance(child, dict):
            return child["props"]["children"][1]["props"]["children"]["props"]["value"]
        elif isinstance(child, dbc.Row):
            return child.children[1].children.value

    current_values = [get_value(child) for child in current_children]

    if ".html" not in current_path:
        rows = get_downstream_rows(current_path, current_values, trigger_index + 1)
        new_children = current_children[: trigger_index + 1]
        extra_children = current_children[trigger_index + 1 :]
        for new_row, existing_child in zip_longest(rows, extra_children):
            if new_row is None:
                break
            if existing_child is None:
                new_children.append(new_row)
                continue
            if existing_child["props"]["id"]["name_labels_text"] == new_row.id["name_labels_text"]:
                new_children.append(existing_child)
            else:
                new_children.append(new_row)
        current_children = new_children
    new_values = [get_value(child) for child in current_children]
    if ".html" in trigger_inputs[-1]:
        full_path = root_path + "/" + "/".join(new_values[:-1]) + "/html/" + new_values[-1]
        try:
            with open(full_path) as f:
                html_contents = f.read()
        except Exception:  # noqa: BLE001
            html_contents = f"<p>Could not open {full_path}</p>"
    else:
        html_contents = ""
    return html_contents, current_children


if __name__ == "__main__":
    webbrowser.open("http://127.0.0.1:8050")
    app.run(debug=False, dev_tools_ui=True, dev_tools_props_check=True)
