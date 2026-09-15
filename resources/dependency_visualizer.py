# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "dash>=2.0.0",
#     "dash-bootstrap-components>=1.0.0",
#     "dash-extensions>=0.1.0",
#     "networkx>=2.6.0",
#     "pyvis>=0.2.0",
#     "pandas>=1.3.0",
#     "numpy>=1.20.0"
# ]
# [tool.uv]
# exclude-newer = "2025-06-01T00:00:00Z"
# ///

# This is self-contained script to visualize the dependency graph of the TSVs.
# Run this script using uv with uv run dependency_visualizer.py
# See here: https://docs.astral.sh/uv/guides/scripts/

from pathlib import Path
import networkx as nx
from pyvis.network import Network
from dash_extensions.enrich import MultiplexerTransform, DashProxy
from dash import html, dcc
from dash.dependencies import Input, Output, State
from dash.exceptions import PreventUpdate
import dash_bootstrap_components as dbc
import pandas as pd
import numpy as np
from collections import defaultdict
import random
import json
import traceback


external_script = ["https://tailwindcss.com/", {"src": "https://cdn.tailwindcss.com"}]
transforms = [MultiplexerTransform()]

this_path = Path(__file__)
res_est_dir = this_path.parent.parent


def get_graph(hc_location):
    """Calculate the dependency levels of the base TSVs to provide the
    proper order for running tsv_dist. Tony's code.

    Args:
        hc_location (str) : location of the base TSVs (suggested form
            'housing_characteristics/hc1')
        return_adj_mat (bool) : Return the adjacency matrix and the graph

    Returns:
        tsv_graph (nx.DiGraph): Networkx DiGraph representing the TSV structures.
        adj_df (pandas.core.frame.DataFrame): the project adjacency matrix
    """

    # get list of HC files, ignore any hidden files (beginning with ".")
    # sorting to ensure they always appear in the same order
    HC_TSV_files = sorted(hc_location.glob("*.tsv"))
    HC_JSON_files = sorted(hc_location.glob("*.json"))
    HC_names = [f.stem for f in HC_TSV_files] + [
        f.stem for f in HC_JSON_files
    ]  # tsv names without extension

    # Initialize the adjacency matrix
    adj_mat = np.zeros((len(HC_names), len(HC_names)))
    hc2options = defaultdict(list)
    hc2deps = defaultdict(list)
    hc2createdby = defaultdict(str)
    hc2num_rows = defaultdict(int)
    # For each housing characteristic
    for i in range(len(HC_TSV_files)):

        # Read the first line of the housing characteristic file
        with open(HC_TSV_files[i]) as f:
            lines = f.readlines()
        header_str = lines[0]
        # For each column in the tsv file
        for column_name in header_str.split("\t"):

            # If there is a dependency
            if column_name.startswith("Dependency="):

                # Get the dependency name
                dependency_str = column_name.removeprefix("Dependency=")

                # Find in the housing characteristics names
                j = HC_names.index(dependency_str)

                # Include the depenancy in the adjacency matrix
                adj_mat[i, j] = 1

                hc2deps[HC_names[i]].append(dependency_str)

            if column_name.startswith("Option="):
                option_str = column_name.removeprefix("Option=")
                hc2options[HC_names[i]].append(option_str)
        for comment_count, line in enumerate(reversed(lines), start=1):
            if not line:
                continue
            if not line.startswith("#"):
                break
            if line.startswith("# Created by"):
                hc2createdby[HC_names[i]] = line.removeprefix("# Created by: ")
        hc2num_rows[HC_names[i]] = len(lines) - comment_count
    tsv_count = len(HC_TSV_files)

    for i in range(len(HC_JSON_files)):
        # Read the dependencies from the json file
        with open(HC_JSON_files[i]) as f:
            json_data = json.load(f)
        deps = json_data.get("dependencies", [])
        for dep in deps:
            j = HC_names.index(dep)
            adj_mat[i + tsv_count, j] = 1
            hc2deps[HC_names[i + tsv_count]].append(dep)
        # find options
        dist_dict = json_data["distribution"]
        # Navigate to innermost dictionary to find options
        inner_dict = dist_dict
        total_combinations = 1
        while isinstance(inner_dict, dict) and inner_dict:
            total_combinations *= len(inner_dict)
            sample_key = next(iter(inner_dict))
            if not isinstance(inner_dict[sample_key], dict):
                break
            inner_dict = inner_dict[sample_key]

        hc2options[HC_names[i + tsv_count]] = list(inner_dict.keys())
        hc2num_rows[HC_names[i + tsv_count]] = total_combinations

    # Convert to Pandas
    adj_df = pd.DataFrame(adj_mat, index=HC_names, columns=HC_names).T
    # Create Graph
    tsv_graph = nx.from_pandas_adjacency(adj_df, nx.DiGraph())
    for node in tsv_graph.nodes:
        tsv_graph.nodes[node]["title"] = (
            f"{node}\n"
            + f"Options: {', '.join(hc2options[node])}\n"
            + f"Dependencies: {', '.join(hc2deps[node])}\n"
            + f"Num Options: {len(hc2options[node])} \n"
            + f"Num Rows: {hc2num_rows[node]} \n"
            + f"Created by: {hc2createdby[node]}"
        )

    return tsv_graph, hc2createdby


def update_graph(sub_graph, name, hierarchical=False):
    g = Network(width=1920, height=1080, directed=True)
    g.from_nx(sub_graph)
    # g.show_buttons(filter_=["layout", "physics", "nodes"])
    # hirarchical layout with: UD, sortMethod: directed, and shakeTowards: roots
    if hierarchical:
        g.options.layout = {
            "hierarchical": {
                "direction": "UD",
                "sortMethod": "directed",
                "shakeTowards": "roots",
                "enabled": True,
                "edgeMinimization": False,
                "blockShifting": False,
                "treeSpacing": 100,
                "nodeSpacing": 140,
            }
        }
    g.options.edges.toggle_smoothness("discrete")
    g.options.canvas = {"width": 1920, "height": 1080}
    g.width = 1920
    g.options.interaction.navigationButtons = True
    if name == "ancestors":
        g.options.edges.inherit_colors("to")
    g.toggle_physics(False)
    return g


def get_ancestors(graph, tsv_names, merge_type="union"):
    all_anc = set()
    first_time = True
    for tsv_name in tsv_names:
        if merge_type.lower() == "union":
            all_anc |= nx.ancestors(graph, tsv_name)
        elif merge_type.lower() == "intersection":
            if first_time:
                all_anc = nx.ancestors(graph, tsv_name)
                first_time = False
            else:
                all_anc = all_anc.intersection(nx.ancestors(graph, tsv_name))

    all_anc |= set(tsv_names)
    return nx.subgraph(graph, all_anc)


def get_descendants(graph, tsv_names, merge_type="union"):
    all_dsc = set()
    first_time = True
    for tsv_name in tsv_names:
        if merge_type.lower() == "union":
            all_dsc |= nx.descendants(graph, tsv_name) | {tsv_name}
        elif merge_type.lower() == "intersection":
            if first_time:
                all_dsc = nx.descendants(graph, tsv_name)
                first_time = False
            else:
                all_dsc = all_dsc.intersection(nx.descendants(graph, tsv_name))
    all_dsc |= set(tsv_names)
    return nx.subgraph(graph, all_dsc)


def get_random_color(seed_string, salt):
    return "#" + hex(hash(seed_string + str(salt)) % 0xFFFFFF)[2:]


def create_scrollable_list(node_list, title, count):
    """Create a scrollable list component with a title.

    Args:
        node_list (list): List of nodes to display
        title (str): Title prefix ("In the graph" or "Not in the graph")
        count (int): Number of items in the list

    Returns:
        html.Div: A Dash component with a title and scrollable list
    """
    return html.Div(
        [
            html.H5(f"{title} ({count}):", className="mt-3 mb-2"),
            html.Div(
                html.Ul(
                    [html.Li(node) for node in node_list],
                    className="list-disc pl-5",
                ),
                style={
                    "maxHeight": "200px",
                    "overflowY": "auto",
                    "border": "1px solid #eee",
                    "padding": "10px",
                },
            ),
        ]
    )


def create_footer(in_graph_nodes, not_in_graph_nodes):
    """Create a footer component containing lists of nodes in and not in the graph.

    Args:
        in_graph_nodes (list): List of nodes in the graph
        not_in_graph_nodes (list): List of nodes not in the graph

    Returns:
        list: List of Dash components for the footer
    """
    return [
        create_scrollable_list(
            node_list=in_graph_nodes, title="In the graph", count=len(in_graph_nodes)
        ),
        create_scrollable_list(
            node_list=not_in_graph_nodes,
            title="Not in the graph",
            count=len(not_in_graph_nodes),
        ),
    ]


def create_tsv_input_row(default_tsv_path):
    """Create the input row for TSV folder path and controls.

    Args:
        default_tsv_path (str): Default path to TSV folder

    Returns:
        dbc.Row: Row containing TSV input, load button, characteristics dropdown, and update button
    """
    return dbc.Row(
        [
            dbc.Col(
                dcc.Input(
                    id="tsv_folder_path",
                    type="text",
                    placeholder="Enter path to TSV folder",
                    value=default_tsv_path,
                    style={"width": "100%"},
                ),
                width=4,
            ),
            dbc.Col(
                dbc.Button("Load TSVs", id="load_tsvs", color="primary"),
                width=1,
            ),
            dbc.Col(
                dcc.Dropdown(
                    id="Characteristics",
                    options={},
                    clearable=False,
                    multi=True,
                    placeholder="Load TSVs first ...",
                )
            ),
            dbc.Col(dbc.Button("Update", id="Update"), width=1),
        ]
    )


def create_merge_options():
    """Create the radio items for merge type selection.

    Returns:
        dbc.RadioItems: Radio items component for merge type selection
    """
    return dbc.RadioItems(
        id="radio_merge",
        value="Intersection",  # default selection
        inline=False,  # stack the two rows vertically
        labelClassName="d-flex gap-2",  # lay radio + text side-by-side
        inputClassName="mt-1",  # nudge radio down so it's centred
        options=[
            {
                "label": html.Div(
                    [
                        html.Span(
                            "Intersection",
                            className="fw-bold d-block",
                        ),
                        html.Small(
                            "Show only nodes that appear in all selected charecteristic's paths",
                            className="text-muted",
                        ),
                    ]
                ),
                "value": "Intersection",
            },
            {
                "label": html.Div(
                    [
                        html.Span(
                            "Union",
                            className="fw-bold d-block",
                        ),
                        html.Small(
                            "Show all nodes that appear in any selected characteristic's path",
                            className="text-muted",
                        ),
                    ]
                ),
                "value": "Union",
            },
        ],
    )


def create_color_code_options():
    """Create the color code options section.

    Returns:
        list: List of components for color coding options
    """
    return [
        dcc.Checklist(
            ["Color Code Sources"],
            ["Color Code Sources"],
            id="color_code",
            labelStyle={
                "display": "inline-block",
                "marginBottom": "10px",
            },
            className="mt-2",
        ),
        html.Div(
            "Color nodes based on 'Created by:' entry in the TSVs when available",
            style={
                "fontSize": "0.8em",
                "color": "#666",
                "marginLeft": "25px",
                "marginTop": "-5px",
                "marginBottom": "10px",
            },
        ),
        dcc.Checklist(
            ["Hierarchical Layout"],
            [],
            id="hierarchical_layout",
            labelStyle={
                "display": "inline-block",
                "marginBottom": "10px",
            },
            className="mt-2",
        ),
        html.Div(
            "Toggle hierarchical layout for better visualization of dependencies",
            style={
                "fontSize": "0.8em",
                "color": "#666",
                "marginLeft": "25px",
                "marginTop": "-5px",
            },
        ),
    ]


def create_controls_card():
    """Create the card containing graph control options.

    Returns:
        dbc.Card: Card component with merge and color code options
    """
    return dbc.Card(
        dbc.CardBody(
            [
                dbc.Row(
                    [
                        dbc.Col(
                            [create_merge_options()],
                            width=8,
                        ),
                        dbc.Col(
                            create_color_code_options(),
                            width=4,
                        ),
                    ]
                )
            ]
        )
    )


def create_graph_display():
    """Create the row containing the graph iframes.

    Returns:
        dbc.Row: Row containing iframes for graph visualization
    """
    return dbc.Row(
        id="iframes",
        children=[
            dbc.Col(
                [
                    html.H5("Ancestors", className="text-center mb-0"),
                    html.Iframe(
                        id="iframeleft",
                        style={"height": "710px", "width": "100%"},
                        width=800,
                    ),
                ],
                width=6,
            ),
            dbc.Col(
                [
                    html.H5("Descendants", className="text-center mb-0"),
                    html.Iframe(
                        id="iframeright",
                        style={"height": "710px", "width": "100%"},
                        width=800,
                        height=600,
                    ),
                ],
                width=6,
            ),
        ],
    )


def create_footer_display():
    """Create the row containing the footer displays.

    Returns:
        dbc.Row: Row containing left and right footers
    """
    return dbc.Row(
        children=[
            dbc.Col(html.Div(id="left_footer"), width=6),
            dbc.Col(html.Div(id="right_footer")),
        ]
    )


def update_graphs(
    tsv_graph,
    tsv_names,
    hc2createdby,
    merge_type="Union",
    color_code=False,
    hierarchical=False,
):
    print(f"Updating {tsv_names}")
    salt = random.randint(0, 1000)
    for node in tsv_graph.nodes:
        tsv_graph.nodes[node]["size"] = 10
        if hierarchical:
            tsv_graph.nodes[node]["shape"] = "box"
            tsv_graph.nodes[node]["widthConstraint"] = 100
        if color_code:
            tsv_graph.nodes[node]["color"] = get_random_color(hc2createdby[node], salt)
        else:
            tsv_graph.nodes[node]["color"] = "#add8e6"
    for tsv_name in tsv_names:
        tsv_graph.nodes[tsv_name]["size"] = 20
        if not color_code:
            tsv_graph.nodes[tsv_name]["color"] = "#dd4b39"
    all_ancestors = get_ancestors(tsv_graph, tsv_names, merge_type)
    all_descendants = get_descendants(tsv_graph, tsv_names, merge_type)
    anc_net = update_graph(all_ancestors, "ancestors", hierarchical)
    dec_net = update_graph(all_descendants, "descendants", hierarchical)
    return anc_net, dec_net


def create_app(default_tsv_path=None, run_tests=False):
    app = DashProxy(
        __name__,
        external_stylesheets=[dbc.themes.BOOTSTRAP],
        transforms=transforms,
        external_scripts=external_script,
    )
    app.layout = html.Div(
        id="Main",
        children=[
            dbc.Row(
                [
                    dbc.Col(
                        html.H1(
                            "Dependency Visualizer (beta)",
                            style={"font-size": "2.5rem"},
                        ),
                        width="auto",
                    )
                ]
            ),
            dbc.Row(style={"margin-top": "15px"}),
            # TSV input row (path, load button, characteristics dropdown, update button)
            create_tsv_input_row(default_tsv_path),
            # Controls row (merge options and color coding)
            dbc.Row(
                [
                    dbc.Col(
                        create_controls_card(),
                        width=12,
                    )
                ]
            ),
            # Graph display iframes
            create_graph_display(),
            # Footers with node lists
            create_footer_display(),
        ],
        style={"marginBottom": 50, "marginLeft": 25},
    )

    @app.callback(
        Output("Characteristics", "options"),
        Output("Characteristics", "value"),
        Output("Characteristics", "placeholder"),
        State("Characteristics", "value"),
        Input("load_tsvs", "n_clicks"),
        State("tsv_folder_path", "value"),
        prevent_initial_call=default_tsv_path is None,
    )
    def update_char_options(cur_value, n_clicks, tsv_folder_path):
        if not tsv_folder_path:
            raise PreventUpdate()

        try:
            tsv_path = Path(tsv_folder_path)
            if not tsv_path.exists() or not tsv_path.is_dir():
                return [], [], "Select..."

            print(f"Loading TSVs from: {tsv_path}")
            tsv_graph, hc2createdby = get_graph(tsv_path)
            node_list = list(tsv_graph.nodes)
            tsv_count = len(node_list)
            placeholder = f"{tsv_count} TSVs loaded. Please select 1 or more chars to visualize their dependencies"
            print(placeholder)
            return node_list, cur_value, placeholder
        except Exception as e:
            print(f"Error loading TSVs: {e}")
            print(traceback.format_exc())
            return [], [], "Select..."

    @app.callback(
        Output("iframeleft", "srcDoc"),
        Output("iframeright", "srcDoc"),
        Output("left_footer", "children"),
        Output("right_footer", "children"),
        State("tsv_folder_path", "value"),
        State("Characteristics", "value"),
        Input("Update", "n_clicks"),
        Input("radio_merge", "value"),
        Input("color_code", "value"),
        Input("hierarchical_layout", "value"),
    )
    def dash_update_graph(
        tsv_folder_path,
        tsv_names,
        n_clicks,
        merge_type,
        color_code,
        hierarchical_layout,
    ):
        if not tsv_names or not tsv_folder_path:
            raise PreventUpdate()
        tsv_path = Path(tsv_folder_path)
        tsv_graph, hc2createdby = get_graph(tsv_path)
        anc_net, dec_net = update_graphs(
            tsv_graph,
            tsv_names,
            hc2createdby=hc2createdby,
            merge_type=merge_type,
            color_code=bool(color_code),
            hierarchical=bool(hierarchical_layout),
        )
        extra = f'<input type="hidden" value="{n_clicks}"></input>'
        style = """
        <head>
        <style>
        canvas {
            width: 820px !important;
            height: 650px !important;
        }
        </style>
        """
        left_html = anc_net.generate_html().replace("<head>", style)
        right_html = dec_net.generate_html().replace("<head>", style)
        anc_net.write_html(
            "left.html", open_browser=False
        )  # To allow solo and larger view if desired
        dec_net.write_html("right.html", open_browser=False)

        # Get the list of all nodes and the nodes in each graph
        all_nodes = set(tsv_graph.nodes())
        anc_nodes = set(anc_net.node_ids)
        dec_nodes = set(dec_net.node_ids)

        # Create the lists for characteristics in and not in each graph
        anc_in_graph = sorted(list(anc_nodes))
        anc_not_in_graph = sorted(list(all_nodes - anc_nodes))
        dec_in_graph = sorted(list(dec_nodes))
        dec_not_in_graph = sorted(list(all_nodes - dec_nodes))

        # Create footers using the helper functions
        left_footer = create_footer(anc_in_graph, anc_not_in_graph)
        right_footer = create_footer(dec_in_graph, dec_not_in_graph)

        return left_html + extra, right_html + extra, left_footer, right_footer

    if run_tests:
        node_list, cur_value, placeholder = update_char_options(
            None, 1, default_tsv_path
        )
        for graph_type in ["Union", "Intersection"]:
            for color_code in [True, False]:
                for hierarchical_layout in [True, False]:
                    dash_update_graph(
                        default_tsv_path,
                        node_list[:10],
                        1,
                        graph_type,
                        color_code,
                        hierarchical_layout,
                    )
                    print(
                        f"Tested {graph_type} with color code {color_code} and hierarchical layout {hierarchical_layout}"
                    )

    return app


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="ResStock Dependency Visualizer")
    parser.add_argument(
        "--port",
        type=int,
        default=8053,
        help="Port to run the server on (default: 8053)",
    )
    parser.add_argument(
        "--tsv-dir",
        type=str,
        help="Path to the TSV directory",
    )
    parser.add_argument("--test", action="store_true", help="Run tests")

    args = parser.parse_args()
    default_tsv_path = Path(__file__).parent / "../project_national/housing_characteristics"
    args.tsv_dir = args.tsv_dir or str(default_tsv_path.resolve().absolute())
    if args.test:
        if not args.tsv_dir:
            raise ValueError("--tsv-dir is required for tests")
        create_app(default_tsv_path=args.tsv_dir, run_tests=args.test)
    else:
        app = create_app(default_tsv_path=args.tsv_dir)
        port = args.port
        retry_max = 200
        retry_count = 0
        while True:
            retry_count += 1
            if retry_count > retry_max:
                print(f"Failed to start server after {retry_max} retries")
                break
            try:
                app.run(port=port, use_reloader=False)
                print("Thanks for using the Dependency Visualizer! See you next time!")
                break
            except SystemExit as e:
                if e.code == 1:
                    print(f"Port {port} is in use, trying {port+1}")
                    port += 1
                else:
                    raise
