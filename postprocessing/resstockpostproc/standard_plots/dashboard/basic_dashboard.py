import base64
import io
import os
from itertools import zip_longest
from pathlib import Path
from typing import Any

import dash
import dash_bootstrap_components as dbc  # type: ignore[import-untyped]
import polars as pl
from dash import ALL, dcc, html
from dash.exceptions import PreventUpdate
from dash_extensions.enrich import DashProxy, MultiplexerTransform  # type: ignore[import-untyped]

external_script = ["https://tailwindcss.com/", {"src": "https://cdn.tailwindcss.com"}]
transforms = [MultiplexerTransform()]

app = DashProxy(
    __name__,
    external_stylesheets=[dbc.themes.BOOTSTRAP],
    transforms=transforms,
    external_scripts=external_script,
)

cur_dir = Path(__file__).parent
ROOT_FOLDER = os.environ["PLOTS_ROOT_FOLDER"] if "PLOTS_ROOT_FOLDER" in os.environ else str(cur_dir / "sdr_plots/plots")
root_path = str(ROOT_FOLDER)


def get_subdirectories(path: str) -> list[str]:
    """
    Get a list of subdirectories for a given path.
    """
    return [name for name in os.listdir(path) if os.path.isdir(os.path.join(path, name))]


def get_files(path: str) -> list[str]:
    """
    Get a list of files for a given path.
    """
    return [name for name in os.listdir(path) if os.path.isfile(os.path.join(path, name))]


def get_selection_row(entity_list: list[str], index: int, initial_value: str) -> dbc.Row:
    if "=" in entity_list[0]:
        name = entity_list[0].split("=")[0]
        labels = [f.split("=")[1].strip() for f in entity_list]
    else:
        name = ""
        labels = entity_list
    labels = [label.removesuffix(".html") for label in labels]
    name_labels_text = f"{name}:{'-'.join(labels)}"
    row = dbc.Row(
        [
            dbc.Col(html.Label(name), width="auto", style={"textAlign": "left"}),
            dbc.Col(
                dcc.RadioItems(
                    id={"type": "radio-selection", "index": index, "name_labels_text": name_labels_text},
                    options=dict(zip(entity_list, labels)),
                    value=initial_value,
                    labelStyle={"display": "inline-block", "marginRight": "10px"},
                ),
                width=6,
            ),
        ],
        id={"type": "radio-row", "index": index, "name_labels_text": name_labels_text},
        className="my-3 align-items-start",
        justify="start",
    )
    return row


def get_downstream_rows(path: str, current_values: list[str], index: int) -> list[dbc.Row]:
    """
    Get the rows of radio buttons for all the subdirectories below a given path.
    """
    rows: list[dbc.Row] = []
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
            dbc.Row([dbc.Col(html.H1("Plots Viewer (beta)", className="text-2xl"), width="2")]),
            dcc.Input(id="root-path", type="text", value=str(ROOT_FOLDER), size="100"),
            html.Br(),
            html.Br(),
            html.Div(id="dropdown-container"),
            html.Br(),
            dbc.Row(
                [
                    dbc.Col(
                        dbc.Button(
                            "⬇️ CSV",
                            id="btn-csv",
                            color="primary",
                            size="sm",
                            className="me-2",
                            outline=True,
                        ),
                        width="auto",
                    ),
                    dbc.Col(
                        dbc.Button(
                            "⬇️ Parquet",
                            id="btn-parquet",
                            color="secondary",
                            size="sm",
                            outline=True,
                        ),
                        width="auto",
                    ),
                    dcc.Download(id="download-data"),
                    dcc.Store(id="current-html-path"),
                ],
                className="my-2 align-items-center",
            ),
            html.Iframe(id="plot-display", width="100%", height="1000", sandbox="allow-scripts allow-downloads"),
        ]
    ),
    className="mx-5 my-1",
)


@app.callback(
    dash.dependencies.Output("dropdown-container", "children"), [dash.dependencies.Input("root-path", "value")]
)
def update_dropdowns(root_path: str) -> list[dbc.Row]:
    return get_downstream_rows(root_path, [], 0)


@app.callback(
    dash.dependencies.Output("plot-display", "srcDoc"),
    dash.dependencies.Output("dropdown-container", "children"),
    dash.dependencies.Output("current-html-path", "data"),
    dash.dependencies.State("root-path", "value"),
    dash.dependencies.State("dropdown-container", "children"),
    [dash.dependencies.Input({"type": "radio-selection", "index": ALL, "name_labels_text": ALL}, "value")],
)
def update_dropdowns2(
    root_path: str, current_children: list[dbc.Row], selection: list[str]
) -> tuple[str, list[dbc.Row], str]:
    if not selection or not selection[0]:
        raise PreventUpdate()
    trigger_index = next(val["index"] for val in dash.callback_context.triggered_prop_ids.values())
    trigger_inputs = list(dash.callback_context.inputs.values())
    trigger_path = "/".join(trigger_inputs[: trigger_index + 1])
    current_path = f"{root_path}/{trigger_path}"

    def get_value(child) -> str:
        if isinstance(child, dict):
            return child["props"]["children"][1]["props"]["children"]["props"]["value"]
        elif isinstance(child, dbc.Row) and child.children:
            return child.children[1].children.value
        return ""

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
    new_values: list[str] = [get_value(child) for child in current_children]
    html_contents = ""
    full_path = ""
    if ".html" in trigger_inputs[-1]:
        full_path = f"{root_path}/{'/'.join(new_values[:-1])}/html/{new_values[-1]}"
        try:
            with open(full_path, encoding="utf8") as f:
                html_contents = f.read()
        except (FileNotFoundError, OSError, PermissionError):
            html_contents = f"<p>Could not open {full_path}</p>"
    return html_contents, current_children, full_path


# --------------------------  DOWNLOAD CALLBACK  --------------------------- #


@app.callback(
    dash.dependencies.Output("download-data", "data"),
    [
        dash.dependencies.Input("btn-csv", "n_clicks"),
        dash.dependencies.Input("btn-parquet", "n_clicks"),
    ],
    dash.dependencies.State("current-html-path", "data"),
    prevent_initial_call=True,
)
def download_plot_data(n_csv: int | None, n_parquet: int | None, html_path: str | None) -> dict[str, Any] | None:
    """Provide parquet or csv download for the currently displayed plot.

    Parameters
    ----------
    n_csv, n_parquet : int | None
        Number of clicks on the respective buttons. Used with
        ``dash.callback_context.triggered_id`` to identify which button
        initiated the callback.
    html_path : str | None
        Full path to the currently displayed HTML file. Stored in the
        ``current-html-path`` ``dcc.Store`` from the selection callback.
    """
    if not html_path:
        raise PreventUpdate()

    if n_csv is None and n_parquet is None:
        raise PreventUpdate()

    # Identify which button was pressed
    # Dash >=2.12 provides ctx helper for callback context
    try:
        from dash import ctx  # noqa: PLC0415

        triggered = ctx.triggered_id  # newest API
    except ImportError:
        # Fallback for older versions
        triggered = dash.callback_context.triggered_id
    if triggered is None:
        raise PreventUpdate()

    # Derive the corresponding data file name
    base_dir, html_file = os.path.split(html_path)
    # Replace the html folder with data folder
    data_dir = base_dir.replace("/html", "/data")
    file_stem = os.path.splitext(html_file)[0]

    if triggered == "btn-parquet":
        parquet_path = os.path.join(data_dir, f"{file_stem}.parquet")
        try:
            with open(parquet_path, "rb") as f_parq:
                parquet_bytes = f_parq.read()
        except FileNotFoundError:
            raise PreventUpdate()

        parquet_b64 = base64.b64encode(parquet_bytes).decode()
        return {
            "content": parquet_b64,
            "filename": f"{file_stem}.parquet",
            "type": "application/octet-stream",
            "base64": True,
        }

    if triggered == "btn-csv":
        parquet_path = os.path.join(data_dir, f"{file_stem}.parquet")
        try:
            df = pl.read_parquet(parquet_path, glob=False)
        except FileNotFoundError:
            raise PreventUpdate()

        buffer = io.StringIO()
        df.write_csv(buffer)
        csv_str = buffer.getvalue()

        return {
            "content": csv_str,
            "filename": f"{file_stem}.csv",
            "type": "text/csv",
        }

    raise PreventUpdate()


if __name__ == "__main__":
    # webbrowser.open("http://127.0.0.1:8050")f
    app.run(
        host="0.0.0.0",  # noqa: S104
        debug=False,
        dev_tools_ui=False,
        dev_tools_props_check=False,
    )
