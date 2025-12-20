"""Generic monthly line chart plotter for creating scatter line charts with monthly data."""

import calendar
from typing import Any

import polars as pl
import plotly.graph_objects as go

from resstockpostproc.shared_utils.generic_plotters import theme


# Month name to index mapping for parsing month values
MONTH_NAME_TO_INDEX = {
    name.lower(): idx for idx, name in enumerate(calendar.month_name) if name
}
MONTH_NAME_TO_INDEX.update(
    {abbr.lower(): idx for idx, abbr in enumerate(calendar.month_abbr) if abbr}
)
MONTH_INDEX_TO_LABEL = {idx: calendar.month_abbr[idx] for idx in range(1, 13)}


def create_ts_plot(
    *,
    data: pl.DataFrame,
    timeseries_column: str,
    quantity_column: str,
    first_category_column: str,
    rse_column: str | None = None,
    first_category_title: str | None = None,
    quantity_title: str = "Value",
    title_text: str = "",
    fig: go.Figure | None = None,
    row: int | None = None,
    col: int | None = None,
    show_legends: bool = True,
    show_ticks: bool = True,
    x_tick_text: tuple = (),
    x_tick_vals: tuple = (),
    x_unit: str = "",
    fill_lower_bound: bool = False,
    custom_range: tuple[float, float] | None = None,
) -> go.Figure:
  
    categories = data[first_category_column].unique(maintain_order=True).to_list()
    category_colors = theme.build_color_palette(categories)
    if custom_range is None and rse_column is not None:
        y_max = data[f"{rse_column.replace('_rse', '_upper_bound')}"].max()
        y_min = data[ f"{rse_column.replace('_rse', '_lower_bound')}"].min()
        yrange = (min(0, y_min), y_max)
    elif custom_range is None:
        y_max = data[quantity_column].max()
        y_min = data[quantity_column].min()
        yrange = (min(0, y_min), y_max)
    else:
        yrange = custom_range
    fig = fig or go.Figure()
    for i, category in enumerate(categories):
        category_data = data.filter(pl.col(first_category_column) == category)
        if category_data.is_empty():
            continue
        
        color = category_colors[category]
        x_values = category_data[timeseries_column].to_list()
        y_values = category_data[quantity_column].to_list()
        rse_values = category_data[rse_column].to_list() if rse_column else []
        if rse_column is not None and any(rse is not None for rse in rse_values):
            upper_col = f"{rse_column.replace('_rse', '_upper_bound')}"
            lower_col = f"{rse_column.replace('_rse', '_lower_bound')}"
            upper_vals = category_data[upper_col].to_list()
            lower_vals = category_data[lower_col].to_list()
            
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
                legendgroup=f"confidence_band_{rse_column}",
                hoverinfo="skip",
                row=row,
                col=col,
            )
            
            # Add the lower bound filled area (from lower bound to 0) if requested
            if fill_lower_bound:
                fig.add_scatter(
                    x=x_values + x_values[::-1],
                    y=lower_vals + [0] * len(lower_vals),
                    fill="toself",
                    fillcolor=color,
                    opacity=0.8,
                    line={"color": "rgba(255,255,255,0)"},
                    showlegend=show_legends and i == 0,
                    name="95% CI Lower Bound",
                    legendgroup=f"confidence_lower_bound_{rse_column}",
                    hoverinfo="skip",
                    row=row,
                    col=col,
                )
        
        fig.add_scatter(
            x=x_values,
            y=y_values,
            mode="lines" + ("+markers" if len(x_values) <= 24 else ""),
            name=category,
            legendgroup=category,
            marker={"color": color, "size": 4},
            line={"color": color, "width": 2},
            hovertemplate="%{x}<br>" + f"{category}: " + "%{y:,.0f} " + quantity_title + "<extra></extra>",
            showlegend=show_legends,
            row=row,
            col=col,
        )
    
    # Configure x-axis to show all 12 months or just Jan and Dec
    all_ticks = data[timeseries_column].unique(maintain_order=True).to_list()
    default_tick_vals = all_ticks if len(all_ticks) <= 12 else [all_ticks[0], all_ticks[-1]]
    default_tick_text = [f"{val}{x_unit}" for val in default_tick_vals]
    default_tick_text[0] = " " * len(default_tick_text[0]) + default_tick_text[0]
    default_tick_text[-1] = default_tick_text[-1] + " " * len(default_tick_text[-1])
    tickvals = list(x_tick_vals) if x_tick_vals else default_tick_vals
    ticktext = list(x_tick_text) if x_tick_text else default_tick_text
    
    fig.update_xaxes(
        title_text="",
        tickmode="array",
        tickvals=tickvals,
        ticktext=ticktext,
        tickfont={"size": 10},
        range= (all_ticks[0], all_ticks[-1]),
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
