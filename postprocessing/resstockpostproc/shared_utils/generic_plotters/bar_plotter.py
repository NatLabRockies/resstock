from . import theme
import plotly.graph_objects as go
import polars as pl


from typing import Literal
from collections.abc import Callable, Sequence


def _calculate_error_bars(
    orientation: Literal["h", "v"],
    x_data: list,
    y_data: list,
    rse_data: list,
) -> tuple[dict | None, dict | None]:
    """Calculate error bars for bar plots based on RSE values (95% CI)."""
    if all(rse == 0 for rse in rse_data):  # no error bars if RSE is zero (typically means N/A)
        return None, None
    data = x_data if orientation == "h" else y_data
    def coallesce(val, default=0):
        return default if val is None else val
    errors = [abs(coallesce(val) * 1.96 * coallesce(rse) / 100) for val, rse in zip(data, rse_data)]
    
    error_dict = {
        "type": "data",
        "array": errors,
        "visible": True,
        "color": "black",
        "thickness": 1.5,
        "width": 4,
    }
    
    return (error_dict, None) if orientation == "h" else (None, error_dict)


def create_bar_plot(
    *,
    data: pl.DataFrame,
    quantity_column: list[str] | str,
    rse_column: list[str] | str | None = None,
    first_category_column: str,
    second_category_column: str | None = None,
    quantity_title: str,
    first_category_title: str,
    second_category_title: str | None = None,
    orientation: Literal["h", "v"] = "h",
    title_text: str = "",
    label_formatter: Callable | None = None,
    fig: go.Figure | None = None,  # to allow passing in an existing figure
    row: int | None = None,
    col: int | None = None,
    categories: Sequence[str] | None = None,
    show_legends: bool = True,
    show_ticks: bool = True,
    custom_range: tuple[float, float] | None = None,
    category_font_size: int | None = None,
) -> go.Figure:
    """
    Creates a simple, grouped or stacked bar plot depending on the inputs.
    """
    label_formatter = (lambda x: x) if label_formatter is None else label_formatter
    first_cat_pallete: dict[str, str] = {}
    unique_cats = data[first_category_column].unique(maintain_order=True).to_list()
    first_cat_pallete.update(theme.build_color_palette(unique_cats))
    
    is_stacked = not (isinstance(quantity_column, str) or second_category_column is None)
    quantity_cols = [quantity_column] if isinstance(quantity_column, str) else list(quantity_column)
    rse_cols = [rse_column] if isinstance(rse_column, str) else (list(rse_column) if rse_column is not None else None)
    
    # Calculate min and max values from the quantity columns
    all_values = []
    for qcol in quantity_cols:
        all_values.extend(data[qcol].fill_null(0).to_list())
    data_min, data_max = min(0, *all_values), max(0, *all_values)
    
    traces: list[go.Bar] = []
    xtitle: str | None = ""
    ytitle: str | None = ""
    ytickvals: list[str] | None = None

    if second_category_column is None:
        legend_title = None
        for q_idx, qcol in enumerate(quantity_cols[::-1]):
            if orientation == "h":
                x_data = list(reversed(data[qcol]))
                y_data = list(reversed(data[first_category_column]))
                xtitle, ytitle = quantity_title, first_category_title
                colors = [first_cat_pallete.get(y, "#626D72") for y in y_data]
            else:
                x_data = list(reversed(data[first_category_column]))
                y_data = list(reversed(data[qcol]))
                xtitle, ytitle = first_category_title, quantity_title
                colors = [first_cat_pallete.get(x, "#626D72") for x in x_data]

            if len(quantity_cols) > 1:
                marker_pattern_shape = theme.END_USE_TO_PATTERN.get(qcol, None)
                marker_color: list[str | None] | list[str] | str | None = theme.END_USE_TO_COLOR.get(qcol, None)
            else:
                marker_color = colors
                marker_pattern_shape = ""
            ytickvals = x_data if orientation == "v" else y_data
            
            # Calculate error bars if rse_column is provided
            error_x = None
            error_y = None
            if rse_cols is not None:
                rse_col = rse_cols[q_idx] if len(rse_cols) > q_idx else rse_cols[0]
                rse_data = list(reversed(data[rse_col].fill_null(0)))
                error_x, error_y = _calculate_error_bars(orientation, x_data, y_data, rse_data)
            
            traces.append(
                go.Bar(
                    name=label_formatter(qcol),
                    x=x_data,
                    y=y_data,
                    orientation=orientation,
                    marker_color=marker_color,
                    marker_pattern_shape=marker_pattern_shape,
                    marker_line_width=5,
                    showlegend=is_stacked and show_legends,
                    hovertemplate="%{x}<br>%{y}" if orientation == "h" else "%{y}<br>%{x}",
                    error_x=error_x,
                    error_y=error_y,
                )
            )
    else:
        unique_groups = data[first_category_column].unique(maintain_order=True).to_list()
        legend_title = first_category_title if not is_stacked else quantity_title

        for q_idx, qcol in enumerate(quantity_cols[::-1]):
            for idx, group_name in enumerate(unique_groups):
                group_data = data.filter(pl.col(first_category_column) == group_name)
                if len(quantity_cols) > 1:
                    marker_pattern_shape = theme.END_USE_TO_PATTERN.get(qcol, None)
                    marker_color = theme.END_USE_TO_COLOR.get(qcol, None)
                else:
                    marker_color = first_cat_pallete.get(group_name)
                    marker_pattern_shape = ""

                if orientation == "h":
                    xvals = list(reversed(group_data[qcol]))
                    yvals = list(reversed(group_data[second_category_column]))
                    model_counts = list(reversed(group_data["model_count"]))
                else:
                    xvals = group_data[second_category_column].to_list()
                    yvals = group_data[qcol].to_list()
                    model_counts = group_data["model_count"].to_list()

                text_vals = None
                if is_stacked and q_idx == 0:
                    text_vals = [""] * (len(xvals) - 1) + [group_name]
                
                # Calculate error bars if rse_column is provided
                error_x = None
                error_y = None
                if rse_cols is not None:
                    rse_col = rse_cols[q_idx] if len(rse_cols) > q_idx else rse_cols[0]
                    if orientation == "h":
                        rse_data = list(reversed(group_data[rse_col].fill_null(0)))
                    else:
                        rse_data = group_data[rse_col].fill_null(0).to_list()
                    error_x, error_y = _calculate_error_bars(orientation, xvals, yvals, rse_data)
                
                traces.append(
                    go.Bar(
                        name=label_formatter(qcol) if is_stacked else group_name,
                        legendgroup=label_formatter(qcol) if is_stacked else group_name,
                        offsetgroup=str(group_name),
                        x=xvals,
                        y=yvals,
                        orientation=orientation,
                        marker_color=marker_color,
                        marker_pattern_shape=marker_pattern_shape,
                        text=text_vals,
                        textposition="outside",
                        textfont={"color": "black"},
                        insidetextanchor="middle",
                        cliponaxis=False,
                        showlegend=((idx == 0) or (not is_stacked)) and show_legends,
                        hovertext=[f"Number of models: {mc}" for mc in model_counts],
                        hoverinfo="all",
                        customdata=model_counts,
                        error_x=error_x,
                        error_y=error_y,
                    )
                )
                ytickvals = yvals
        xtitle, ytitle = (
            (quantity_title, second_category_title) if orientation == "h" else (second_category_title, quantity_title)
        )

    fig = fig or go.Figure()
    fig.update_layout(
        title_text=title_text,
        barmode="relative" if is_stacked else "group",
        template=theme.DEFAULT_TEMPLATE
    )
    traces = traces[::-1] if orientation == "h" else traces
    for trace in traces:
        fig.add_trace(trace, row=row, col=col)

    theme.apply_layout(fig)
    categories = categories[::-1] if categories else ytickvals

    # Set axis range based on data min/max
    data_range = custom_range if custom_range else (data_min, data_max)
    if orientation == "h":
        fig.update_xaxes(range=data_range, row=row, col=col,
                         title_text=quantity_title, showticklabels=show_ticks
                         )
        yaxis_kwargs = dict(type="category", tickmode="array", tickvals=categories, showticklabels=True,
                            categoryorder="array", categoryarray=categories, row=row, col=col)
        if category_font_size is not None:
            yaxis_kwargs["tickfont"] = {"size": category_font_size}
        fig.update_yaxes(**yaxis_kwargs)
        fig.update_layout(legend_traceorder="reversed")
    else:
        fig.update_yaxes(range=data_range,
                         title_text=quantity_title, title_standoff=1, row=row, col=col, showticklabels=show_ticks)
        fig.update_xaxes(type="category", tickmode="array", tickvals=categories, showticklabels=True,
                          categoryorder="array", categoryarray=categories, row=row, col=col)
    
    if legend_title:
        fig.update_layout(legend_title_text=legend_title, legend={"xanchor": "left", "x": 1.12})

    return fig