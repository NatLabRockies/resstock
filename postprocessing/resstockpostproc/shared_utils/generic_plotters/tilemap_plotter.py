import polars as pl
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from .bar_plotter import create_bar_plot
from .monthly_plotter import create_ts_plot
from .range_utils import compute_axis_range
from typing import Literal
from collections.abc import Sequence, Callable
from resstockpostproc.shared_utils.db_column_names import DataCol
from resstockpostproc.shared_utils.mapping import ABBR2STATE
from resstockpostproc.shared_utils.timing import timed


def filter_null_sources(data: pl.DataFrame, source_column: str, quantity_column: str) -> pl.DataFrame:
    """Remove sources where the quantity column is entirely null."""
    valid_sources = (
        data.group_by(source_column)
        .agg(pl.col(quantity_column).is_null().all().alias("all_null"))
        .filter(~pl.col("all_null"))
        .select(source_column)
    )
    return data.join(valid_sources, on=source_column, how="inner")


# LRDUtility2EIAID = {
#     "AEP (OH)": 14006,  # using Ohio Power (OH)
#     "Ameren (MO)": 19436,  # = Union Electric (MO)
#     "Appalachian (VA)": 733,
#     "BGE (MD)": 1167,
#     "ComEd (IL)": 4110,
#     # FirstEnergy OH: 6458,
#     "OhioEd (OH)": 13998,
#     "Cleveland (OH)": 3755,
#     "ToledoEd (OH)": 18997,
#     # FirstEnergy PA: 6458,
#     "MetEd (PA)": 12390,
#     "Penelec (PA)": 14711,
#     "PP (PA)": 14716,
#     "WPP (PA)": 20387,

#     "PECO (PA)": 14940,
#     "PG&E (CA)": 14328,
#     "SCE (CA)": 17609,
#     "ERCOT": -1,
# }

LAYOUTS = {
    DataCol.CENSUS_DIVISION: [
        ["Pacific", "Mountain North", "West North Central", "East North Central", "Middle Atlantic", "New England"],
        [None, "Mountain South", "West South Central", "East South Central", "South Atlantic", None],
        [None, None, "US Total", None, None, None],
        [None, None, None, None, None, None],
    ],
    DataCol.STATE: [
        ["WA", "ID", "MT", "ND", "MN", "WI", "MI", "NY", "VT", "NH", "ME"],
        ["OR", "NV", "WY", "SD", "IA", "IL", "IN", "OH", "PA", "NJ", "MA"],
        ["CA", "UT", "CO", "NE", "MO", "KY", "WV", "VA", "MD", "CT", "RI"],
        [None, "AZ", "NM", "KS", "AR", "TN", "NC", "SC", "DC", "DE", None],
        [None, None, None, "OK", "LA", "MS", "AL", "GA", None, None, None],
        ["AK", "HI", None, "TX", None, "US Total", None, "FL", None, None, None],
        [None, None, None, None, None, None, None, None, None, None, None],  # Extra row for US Total to grow downward
    ],
    DataCol.VINTAGE: [
        ["<1950", "1950s", "1960s", "1970s", "1980s", "1990s", "2000s", "2010s"],
        [None, None, None, "US Total", None, None, None, None],
        [None, None, None, None, None, None, None, None],
    ],
    DataCol.BUILDING_TYPE: [
        [
            "Single-Family Detached",
            "Single-Family Attached",
            "Multi-Family with 2 - 4 Units",
            "Multi-Family with 5+ Units",
            "Mobile Home",
        ],
        [None, "US Total", None],
        [None, None, None],
    ],
    DataCol.UTILITY: [
        ["ComEd (IL)", "OhioEd (OH)", "ToledoEd (OH)", "AEP (OH)", "Cleveland (OH)"],
        ["MetEd (PA)", "Penelec (PA)", "PP (PA)", "WPP (PA)", "PECO (PA)"],
        ["PG&E (CA)", "SCE (CA)", "ERCOT", "Appalachian (VA)", "BGE (MD)"],  # "Ameren (MO)" doesn't have full year data
        # [None, None, "ERCOT", None, None],
    ],
    # Layout for hour_of_day_matrix: 13 rows (months + All Year) x 3 columns (day types)
    "month_daytype": [
        ["JAN_All Days", "JAN_Weekday", "JAN_Weekend"],
        ["FEB_All Days", "FEB_Weekday", "FEB_Weekend"],
        ["MAR_All Days", "MAR_Weekday", "MAR_Weekend"],
        ["APR_All Days", "APR_Weekday", "APR_Weekend"],
        ["MAY_All Days", "MAY_Weekday", "MAY_Weekend"],
        ["JUN_All Days", "JUN_Weekday", "JUN_Weekend"],
        ["JUL_All Days", "JUL_Weekday", "JUL_Weekend"],
        ["AUG_All Days", "AUG_Weekday", "AUG_Weekend"],
        ["SEP_All Days", "SEP_Weekday", "SEP_Weekend"],
        ["OCT_All Days", "OCT_Weekday", "OCT_Weekend"],
        ["NOV_All Days", "NOV_Weekday", "NOV_Weekend"],
        ["DEC_All Days", "DEC_Weekday", "DEC_Weekend"],
        ["All Year_All Days", "All Year_Weekday", "All Year_Weekend"],
    ],
    # Layout for day_of_year: 15 utilities in single column (full width per row)
    "utility_vertical": [
        ["ComEd (IL)"],
        ["OhioEd (OH)"],
        ["ToledoEd (OH)"],
        ["AEP (OH)"],
        ["Cleveland (OH)"],
        ["MetEd (PA)"],
        ["Penelec (PA)"],
        ["PP (PA)"],
        ["WPP (PA)"],
        ["PECO (PA)"],
        ["PG&E (CA)"],
        ["SCE (CA)"],
        ["ERCOT"],
        ["Appalachian (VA)"],
        ["BGE (MD)"],
    ],
}


@timed
def plot_tilemap(
    data: pl.DataFrame,
    quantity_column: str,
    first_category_column: str,
    second_category_column: str,
    quantity_title: str,
    first_category_title: str,
    lower_bound_column: str | None = None,
    upper_bound_column: str | None = None,
    sidebar_column: str | None = None,
    sidebar_title: str = "",
    second_category_title: str | None = None,
    orientation: Literal["h", "v"] = "h",
    title_text: str = "",
    label_formatter: Callable | None = None,
    categories: Sequence[str] | None = None,
    show_legends: bool = True,
    timeseries_column: str | None = None,
    ts_xtick_text: tuple | None = None,
    ts_xtick_vals: tuple | None = None,
    x_range: tuple[float, float] | None = None,
    x_axis_title_bottom_row: str | None = None,
    x_unit: str = "",
    exclude_from_sidebar: list[str] | None = None,
    exclude_sources: list[str] | None = None,
    separate_us_total_scale: bool = True,
    count_label: str | None = "Number of models",
    count_label_resolver: Callable[[str], str | None] | None = None,
    compact_hover_values: bool = False,
    percent_difference_column: str | None = None,
) -> go.Figure:
    """
    Generic annual sales plotting function with geographic layout and size-proportional subplots.
    Uses bar charts with one value per state (or box plots for distributions), and error bars for RECS RSE.

    Args:
        data: DataFrame with all columns (both reference and resstock)
        by: Grouping column (e.g., 'state')
        quantity: Quantity to plot (e.g., 'electricity', 'natural_gas')
        title: Plot title
        y_label: Y-axis label
        use_shared_axis: Whether to use shared y-axis scaling
        suffix: Column suffix to use (e.g., '_value', '_percent_users', or '_quartiles')
        quantity_type: Type of quantity being plotted
    """
    scale_data = data
    if separate_us_total_scale:
        scale_data = data.filter(pl.col(second_category_column) != "US Total")
    global_min, global_max = compute_axis_range(scale_data, quantity_column, lower_bound_column, upper_bound_column)
    custom_range = (global_min, global_max * 1.01)

    layout = LAYOUTS[second_category_column]
    subplot_titles = []
    nrows = len(layout)
    ncols = len(layout[0])

    # Add extra column for sidebar if needed
    if sidebar_column:
        ncols += 2

    entity_position = {}
    for row in range(nrows):
        for col in range(ncols):
            if col == ncols - 1 and sidebar_column:
                if row == 0:
                    subplot_titles.append(sidebar_title)
                continue
            entity_name = layout[row][col] if col < len(layout[row]) else None
            # Tile labels are rendered below via x-axis titles; keep this slot blank.
            subplot_titles.append("")
            entity_position[entity_name] = (row + 1, col + 1)

    # Create column specs for sidebar spanning all rows
    specs: list[list[dict[str, str | int | bool | float] | None]] = [
        [{"type": "xy"} for _ in range(ncols)] for _ in range(nrows)
    ]
    if sidebar_column:
        for row in range(nrows):
            if row == 0:
                specs[row][-1] = {"type": "xy", "rowspan": nrows - 1}
            else:
                specs[row][-1] = None

    # Set column widths: sidebar is double width
    column_widths = None
    if sidebar_column:
        standard_width = 1.0 / (ncols + 1)  # +1 because sidebar takes double space
        column_widths = [standard_width] * (ncols - 1) + [standard_width * 2]

    # Calculate spacing dynamically to fit the number of rows/cols
    # Max spacing is 0.1, but must be less than 1/(n-1) for n rows/cols
    max_vertical_spacing = max(0.02, 0.3 / (nrows))
    max_horizontal_spacing = max(0.02, 0.3 / (ncols))

    fig = make_subplots(
        rows=nrows,
        cols=ncols,
        subplot_titles=subplot_titles,
        specs=specs,
        shared_yaxes=False,
        shared_xaxes=ncols == 1, # Share x-axes only if single column
        horizontal_spacing=max_horizontal_spacing,
        vertical_spacing=max_vertical_spacing,
        column_widths=column_widths,
    )

    # Add traces for each state
    entities = data[second_category_column].unique(maintain_order=True)
    for i, entity in enumerate(entities):
        row, col = entity_position[entity]
        entity_df = data.filter(pl.col(second_category_column) == entity)
        if entity_df.is_empty():
            continue
        if exclude_sources:
            entity_df = entity_df.filter(~pl.col(first_category_column).is_in(exclude_sources))

        is_us_total = entity == "US Total"
        show_yticks = is_us_total or col == 1 or (col > 1 and layout[row - 1][col - 2] is None)
        hover_label = ABBR2STATE.get(entity, entity)
        if timeseries_column is None:
            create_bar_plot(
                data=entity_df,
                quantity_column=quantity_column,
                lower_bound_column=lower_bound_column,
                upper_bound_column=upper_bound_column,
                first_category_column=first_category_column,
                second_category_column=second_category_column,
                quantity_title=quantity_title if show_yticks else "",
                first_category_title="",
                second_category_title="",
                orientation="v",
                title_text="",
                show_legends=show_legends and i == 0 and not exclude_sources,
                fig=fig,
                row=row,
                col=col,
                custom_range=custom_range if not (entity == "US Total" and separate_us_total_scale) else None,
                show_ticks=show_yticks,
                count_label=count_label,
                count_label_resolver=count_label_resolver,
                compact_hover_values=compact_hover_values,
                hover_prefix=hover_label,
                percent_difference_column=percent_difference_column,
            )
        else:
            create_ts_plot(
                data=entity_df,
                timeseries_column=timeseries_column,
                quantity_column=quantity_column,
                lower_bound_column=lower_bound_column,
                upper_bound_column=upper_bound_column,
                first_category_column=first_category_column,
                quantity_title=quantity_title if show_yticks else "",
                first_category_title="",
                title_text="",
                show_legends=show_legends and i == 0 and not exclude_sources,
                fig=fig,
                row=row,
                col=col,
                custom_range=custom_range if not (entity == "US Total" and separate_us_total_scale) else None,
                show_ticks=show_yticks,
                x_tick_vals=ts_xtick_vals,
                x_tick_text=ts_xtick_text,
                x_range=x_range,
                x_unit=x_unit,
                fill_lower_bound=True,
                count_label=count_label,
                count_label_resolver=count_label_resolver,
                compact_hover_values=compact_hover_values,
                hover_prefix=hover_label,
                percent_difference_column=percent_difference_column,
            )

        if entity == "US Total":
            _enlarge_us_total_box(nrows, ncols, row, col, specs, fig)

    # Use x-axis titles as subplot labels (positioned below each subplot)
    # instead of Plotly's built-in subplot_titles (which sit at the top).
    standoff = 0 if timeseries_column else 3
    for entity_name, (row, col) in entity_position.items():
        if entity_name:
            fig.update_xaxes(title_text=entity_name, title_standoff=standoff, row=row, col=col)

    # Add sidebar horizontal bar plot if specified
    if sidebar_column:
        sidebar_data = data
        if exclude_from_sidebar:
            sidebar_data = sidebar_data.filter(~pl.col(second_category_column).is_in(exclude_from_sidebar))
        sidebar_df = (
            filter_null_sources(sidebar_data, first_category_column, sidebar_column)
            .sort(sidebar_column, descending=True)
        )
        # print(categories)
        create_bar_plot(
            data=sidebar_df,
            quantity_column=sidebar_column,
            first_category_column=first_category_column,
            second_category_column=second_category_column,
            quantity_title="",
            first_category_title="",
            orientation="h",
            title_text=sidebar_title,
            show_legends=bool(exclude_sources),
            fig=fig,
            row=1,
            col=ncols,
            category_font_size=11,
            count_label=count_label,
            count_label_resolver=count_label_resolver,
            compact_hover_values=compact_hover_values,
        )

    # Remove grid and axis border lines from all subplots
    fig.update_xaxes(showgrid=False, showline=False)

    if x_axis_title_bottom_row:
        for col in range(1, ncols + 1):
            if sidebar_column and col == ncols:
                continue
            entity = layout[nrows - 1][col - 1] if col - 1 < len(layout[nrows - 1]) else None
            if entity is None:
                continue
            fig.update_xaxes(title_text=f"{entity}<br>{x_axis_title_bottom_row}", row=nrows, col=col)

    fig.update_yaxes(showgrid=False, showline=False, zeroline=True, zerolinewidth=2, zerolinecolor="darkgray")
    fig.update_layout(
        title_text=title_text,
    )

    return fig


def _enlarge_us_total_box(nrows, ncols, row, col, specs, fig):
    subplot_num = 0
    for r in range(1, nrows + 1):
        for c in range(1, ncols + 1):
            spec = specs[r - 1][c - 1]
            rowspan_val = spec.get("rowspan", 1) if spec is not None else 0
            if spec is not None and isinstance(rowspan_val, int) and rowspan_val > 0:
                subplot_num += 1
                if r == row and c == col:
                    break
        else:
            continue
        break

    # Get the axis keys
    xaxis_key = f"xaxis{subplot_num}" if subplot_num > 1 else "xaxis"
    yaxis_key = f"yaxis{subplot_num}" if subplot_num > 1 else "yaxis"

    # Get current domain
    x_domain = fig.layout[xaxis_key].domain
    y_domain = fig.layout[yaxis_key].domain

    # Calculate center and new width (1.5x)
    x_center = (x_domain[0] + x_domain[1]) / 2
    x_width = (x_domain[1] - x_domain[0]) * 1.5

    # For height, grow downward - keep top fixed, extend bottom
    y_top = y_domain[1]
    y_height = (y_domain[1] - y_domain[0]) * 1.8
    y_bottom = y_top - y_height

    # Set new domain (allow extending beyond current row)
    fig.update_xaxes(
        domain=[max(0, x_center - x_width / 2), min(1, x_center + x_width / 2)],
        row=row,
        col=col,
    )
    fig.update_yaxes(
        domain=[y_bottom, y_top],  # Don't constrain with max(0, ...) to allow full extension
        row=row,
        col=col,
    )

    # Add border around US Total subplot
    fig.add_shape(
        type="rect",
        xref="paper",
        yref="paper",
        x0=max(0, x_center - x_width / 2),
        y0=y_bottom,
        x1=min(1, x_center + x_width / 2),
        y1=y_top,
        line={"color": "black", "width": 2},
        layer="below",
        editable=False,
    )
