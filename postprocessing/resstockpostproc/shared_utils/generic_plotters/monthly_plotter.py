"""Generic monthly line chart plotter for creating scatter line charts with monthly data."""

import calendar
from collections.abc import Callable

import polars as pl
import plotly.graph_objects as go

from .hover_formatting import (
    build_hover_customdata,
    format_compact_hover_value,
    format_confidence_interval,
    format_count_value,
)
from .range_utils import compute_axis_range

from resstockpostproc.shared_utils.generic_plotters import theme
from resstockpostproc.shared_utils.timing import timed


# Month name to index mapping for parsing month values
MONTH_NAME_TO_INDEX = {name.lower(): idx for idx, name in enumerate(calendar.month_name) if name}
MONTH_NAME_TO_INDEX.update({abbr.lower(): idx for idx, abbr in enumerate(calendar.month_abbr) if abbr})
MONTH_INDEX_TO_LABEL = {idx: calendar.month_abbr[idx] for idx in range(1, 13)}


@timed
def create_ts_plot(
    *,
    data: pl.DataFrame,
    timeseries_column: str,
    quantity_column: str,
    first_category_column: str,
    lower_bound_column: str | None = None,
    upper_bound_column: str | None = None,
    first_category_title: str | None = None,
    quantity_title: str = "Value",
    title_text: str = "",
    fig: go.Figure | None = None,
    row: int | None = None,
    col: int | None = None,
    show_legends: bool = True,
    show_ticks: bool = True,
    x_tick_text: tuple | None = None,
    x_tick_vals: tuple | None = None,
    x_unit: str = "",
    x_range: tuple[float, float] | None = None,
    fill_lower_bound: bool = False,
    custom_range: tuple[float, float] | None = None,
    count_label: str | None = "Number of models",
    count_label_resolver: Callable[[str], str | None] | None = None,
    compact_hover_values: bool = False,
    hover_prefix: str = "",
) -> go.Figure:
    categories = data[first_category_column].unique(maintain_order=True).to_list()
    category_colors = theme.build_color_palette(categories)
    yrange = (
        compute_axis_range(data, quantity_column, lower_bound_column, upper_bound_column)
        if custom_range is None
        else custom_range
    )
    fig = fig or go.Figure()
    for i, category in enumerate(categories):
        category_data = data.filter(pl.col(first_category_column) == category)
        if category_data.is_empty():
            continue

        color = category_colors[category]
        x_values = category_data[timeseries_column].to_list()
        y_values = category_data[quantity_column].to_list()
        if (
            lower_bound_column is not None
            and upper_bound_column is not None
            and lower_bound_column in category_data.columns
            and upper_bound_column in category_data.columns
            and (
                category_data[lower_bound_column].null_count() < category_data.height
                or category_data[upper_bound_column].null_count() < category_data.height
            )
        ):
            upper_vals = category_data[upper_bound_column].fill_null(0).to_list()
            lower_vals = category_data[lower_bound_column].fill_null(0).to_list()
            ci_strings = [
                format_confidence_interval(lower, upper, quantity_title)
                for lower, upper in zip(lower_vals, upper_vals)
            ]
            if not any(ci_strings):
                ci_strings = None

            # Add the confidence band (upper to lower)
            fig.add_scatter(
                x=x_values + x_values[::-1],
                y=upper_vals + lower_vals[::-1],
                fill="toself",
                fillcolor=color,
                opacity=0.6,
                line={"color": "rgba(255,255,255,0)"},
                showlegend=show_legends and i == 0,
                name="95% CI Band",
                legendgroup=f"confidence_band_{quantity_column}",
                hoverinfo="skip",
                row=row,
                col=col,
            )
            lower_fill_name = "95% CI Lower Bound"
        else:
            lower_vals = y_values
            lower_fill_name = f"{category} filled area"
            ci_strings = None
        # Add the lower bound filled area (from lower bound to 0) if requested
        if fill_lower_bound:
            fig.add_scatter(
                x=x_values + x_values[::-1],
                y=lower_vals + [0] * len(lower_vals),
                fill="toself",
                fillcolor=color,
                opacity=0.8,
                line={"color": "rgba(255,255,255,0)"},
                showlegend=(show_legends and i == 0),
                name=lower_fill_name,
                legendgroup="Lower Bound",
                hoverinfo="skip",
                row=row,
                col=col,
            )
            fill_lower_bound = False  # Only ever fill the lower bound once for first category

        resolved_count_label = (
            count_label_resolver(category)
            if count_label_resolver is not None
            else count_label
        )
        count_strings = None
        if resolved_count_label and "model_count" in category_data.columns:
            count_strings = [
                f"{resolved_count_label}: {format_count_value(model_count)}" if model_count is not None else ""
                for model_count in category_data["model_count"].to_list()
            ]

        value_strings = (
            [format_compact_hover_value(v, quantity_title) for v in y_values]
            if compact_hover_values
            else None
        )
        customdata = build_hover_customdata(value_strings, count_strings, ci_strings)

        hover_start = f"{hover_prefix}<br>" if hover_prefix else ""
        if compact_hover_values:
            hovertemplate = hover_start + "%{x}<br>" + f"{category}: " + "%{customdata[0]}"
            custom_idx = 1
            if count_strings is not None:
                hovertemplate += f"<br>%{{customdata[{custom_idx}]}}"
                custom_idx += 1
            if ci_strings is not None:
                hovertemplate += f"<br>%{{customdata[{custom_idx}]}}"
            hovertemplate += "<extra></extra>"
        else:
            hovertemplate = hover_start + "%{x}<br>" + f"{category}: " + "%{y:,.2f}"
            if quantity_title:
                hovertemplate += f" {quantity_title}"
            custom_idx = 0
            if count_strings is not None:
                hovertemplate += f"<br>%{{customdata[{custom_idx}]}}"
                custom_idx += 1
            if ci_strings is not None:
                hovertemplate += f"<br>%{{customdata[{custom_idx}]}}"
            hovertemplate += "<extra></extra>"

        fig.add_scatter(
            x=x_values,
            y=y_values,
            mode="lines" + ("+markers" if len(x_values) <= 24 else ""),
            name=category,
            legendgroup=category,
            marker={"color": color, "size": 4},
            line={"color": color, "width": 2},
            customdata=customdata,
            hovertemplate=hovertemplate,
            showlegend=show_legends,
            row=row,
            col=col,
        )

    # Configure x-axis
    all_ticks = data[timeseries_column].unique(maintain_order=True).to_list()

    # If both tick vals and text are None, let Plotly auto-format (good for datetime axes)
    if x_tick_vals is None and x_tick_text is None:
        fig.update_xaxes(
            title_text="",
            tickfont={"size": 10},
            automargin=True,
            showticklabels=True,
            showgrid=False,
            range=x_range,
            row=row,
            col=col,
        )
    else:
        # Use explicit tick values/labels
        default_tick_vals = all_ticks if len(all_ticks) <= 12 else [all_ticks[0], all_ticks[-1]]
        tickvals = list(x_tick_vals) if x_tick_vals else default_tick_vals
        default_tick_text = [f"{val}{x_unit}" for val in tickvals]
        if len(default_tick_text) > 1:
            default_tick_text[0] = " " * len(default_tick_text[0]) + default_tick_text[0]
            default_tick_text[-1] = default_tick_text[-1] + " " * len(default_tick_text[-1])
        ticktext = list(x_tick_text) if x_tick_text else default_tick_text

        fig.update_xaxes(
            title_text="",
            tickmode="array",
            tickvals=tickvals,
            ticktext=ticktext,
            tickfont={"size": 10},
            range=x_range if x_range is not None else (all_ticks[0], all_ticks[-1]),
            automargin=True,
            showticklabels=True,
            showgrid=False,
            row=row,
            col=col,
        )

    # Configure y-axis
    y_axis_kwargs = {
        "title_text": quantity_title if show_ticks else "",
        "title_font": {"size": 12},
        "tickfont": {"size": 10},
        "automargin": True,
        "showticklabels": show_ticks,
        "showgrid": True,
        "showline": show_ticks,
        "range": yrange,
    }

    fig.update_yaxes(row=row, col=col, **y_axis_kwargs)
    if row is None and col is None:
        fig.update_layout(
            title_text=title_text,
            showlegend=show_legends,
            template=theme.DEFAULT_TEMPLATE,
        )
        theme.apply_layout(fig)

    if first_category_title and show_legends:
        fig.update_layout(legend_title_text=first_category_title)

    return fig
