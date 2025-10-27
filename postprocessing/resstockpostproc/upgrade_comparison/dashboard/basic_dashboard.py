import base64
import io
import os
from functools import lru_cache
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
ROOT_FOLDER = os.environ["PLOTS_ROOT_FOLDER"] if "PLOTS_ROOT_FOLDER" in os.environ else str(cur_dir.parent / "sdr_plots/plots")
root_path = str(ROOT_FOLDER)


@lru_cache(maxsize=None)
def contains_html(path: str) -> bool:
    """
    Check whether the provided directory (recursively) contains at least one HTML file.
    """
    try:
        for _, _, files in os.walk(path):
            if any(file.endswith(".html") for file in files):
                return True
    except OSError:
        return False
    return False


def list_entries(path: str) -> list[tuple[str, str]]:
    """
    Return directories (that contain html files) and html files that live directly inside path.
    Directories are listed before html files to mimic typical file browsers.
    """
    try:
        entries = os.listdir(path)
    except OSError:
        return []
    directories: list[str] = []
    html_files: list[str] = []
    for name in entries:
        candidate = os.path.join(path, name)
        if os.path.isdir(candidate):
            if contains_html(candidate):
                directories.append(name)
        elif name.endswith(".html"):
            html_files.append(name)
    directories.sort()
    html_files.sort()
    ordered: list[tuple[str, str]] = [("dir", name) for name in directories]
    ordered.extend([("html", name) for name in html_files])
    return ordered


def resolve_related_parquet_path(html_path: str) -> str | None:
    """
    Infer the parquet path associated with an HTML plot by probing common sibling folders.
    """
    html_file = Path(html_path)
    if html_file.suffix != ".html":
        return None

    html_dir = html_file.parent
    file_stem = html_file.stem

    candidate_dirs: list[Path] = []
    siblings = [
        html_dir.parent / "data",
        html_dir.with_name(html_dir.name.replace("html", "data")),
        html_dir,
    ]

    for candidate in siblings:
        if candidate not in candidate_dirs:
            candidate_dirs.append(candidate)

    for candidate_dir in candidate_dirs:
        candidate_path = candidate_dir / f"{file_stem}.parquet"
        try:
            if candidate_path.is_file():
                return str(candidate_path)
        except OSError:
            continue
    return None


def get_selection_row(
    options: list[tuple[str, str]], index: int, initial_value: str, row_key: str
) -> dbc.Row:
    dash_options = []
    for value, label in options:
        display = label.removesuffix(".html")
        dash_options.append({"label": display, "value": value})
    row = dbc.Row(
        [
            dbc.Col(html.Label(""), width="auto", style={"textAlign": "left"}),
            dbc.Col(
                dcc.RadioItems(
                    id={"type": "radio-selection", "index": index, "row_key": row_key},
                    options=dash_options,
                    value=initial_value,
                    labelStyle={"display": "inline-block", "marginRight": "10px"},
                ),
                width=6,
            ),
        ],
        id={"type": "radio-row", "index": index, "row_key": row_key},
        className="my-3 align-items-start",
        justify="start",
    )
    return row


def build_selection_rows(root_path: str, selection_map: dict[str, str]) -> tuple[list[dbc.Row], list[str]]:
    """
    Construct the full set of selection rows rooted at `root_path`, reusing selections when possible.
    Returns both the rows and the values chosen for each row (directories followed by optional file).
    """
    rows: list[dbc.Row] = []
    selected_values: list[str] = []
    relative_path = ""
    index = 0

    selection_map = dict(selection_map)

    while True:
        current_path = os.path.join(root_path, relative_path) if relative_path else root_path
        entries = list_entries(current_path)
        if not entries:
            break

        options: list[tuple[str, str]] = []
        for entry_type, name in entries:
            rel_path = os.path.join(relative_path, name) if relative_path else name
            value = f"{entry_type}::{rel_path}"
            label = name
            options.append((value, label))

        option_values = [value for value, _ in options]
        row_key = f"path:{relative_path or '.'}"
        preferred = selection_map.get(row_key, "")
        initial_value = preferred if preferred in option_values else option_values[0]

        rows.append(get_selection_row(options, index, initial_value, row_key=row_key))
        selected_values.append(initial_value)
        selection_map[row_key] = initial_value

        selected_type, selected_rel = initial_value.split("::", 1)
        if selected_type == "html":
            break

        relative_path = selected_rel
        index += 1

    return rows, selected_values


def extract_selection_map(current_children: list[Any], selection: list[str]) -> dict[str, str]:
    """
    Build a mapping from row_key to the currently selected radio value, preserving the row order.
    """
    selection_map: dict[str, str] = {}
    row_keys: list[str] = []

    for child in current_children or []:
        row_id: dict[str, Any] | None = None
        if isinstance(child, dict):
            row_id = child.get("props", {}).get("id")
        else:
            row_id = getattr(child, "id", None)
        if isinstance(row_id, dict):
            row_key = row_id.get("row_key")
            if isinstance(row_key, str):
                row_keys.append(row_key)

    for row_key, value in zip(row_keys, selection):
        if isinstance(value, str):
            selection_map[row_key] = value

    return selection_map


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
    try:
        contains_html.cache_clear()
    except AttributeError:
        pass
    rows, _ = build_selection_rows(root_path, {})
    return rows


@app.callback(
    dash.dependencies.Output("plot-display", "srcDoc"),
    dash.dependencies.Output("dropdown-container", "children"),
    dash.dependencies.Output("current-html-path", "data"),
    dash.dependencies.State("root-path", "value"),
    dash.dependencies.State("dropdown-container", "children"),
    [dash.dependencies.Input({"type": "radio-selection", "index": ALL, "row_key": ALL}, "value")],
)
def update_dropdowns2(
    root_path: str, current_children: list[dbc.Row], selection: list[str]
) -> tuple[str, list[dbc.Row], str]:
    selection_map = extract_selection_map(current_children, selection)
    rows, selected_values = build_selection_rows(root_path, selection_map)

    html_contents = ""
    full_path = ""
    for value in reversed(selected_values):
        if value.startswith("html::"):
            rel_path = value.split("::", 1)[1]
            full_path = os.path.join(root_path, rel_path)
            try:
                with open(full_path, encoding="utf8") as f:
                    html_contents = f.read()
            except (FileNotFoundError, OSError, PermissionError):
                html_contents = f"<p>Could not open {full_path}</p>"
            break

    return html_contents, rows, full_path


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

    parquet_path = resolve_related_parquet_path(html_path)
    if parquet_path is None:
        raise PreventUpdate()

    file_stem = os.path.splitext(os.path.basename(parquet_path))[0]

    if triggered == "btn-parquet":
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
