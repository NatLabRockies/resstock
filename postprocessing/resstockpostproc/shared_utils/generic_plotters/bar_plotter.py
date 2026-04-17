from . import theme
from .hover_formatting import (
    build_hover_customdata,
    format_compact_hover_value,
    format_confidence_interval,
    format_count_value,
)
from .range_utils import compute_axis_range
from resstockpostproc.shared_utils.timing import timed
import plotly.graph_objects as go
import polars as pl


from typing import Literal
from collections.abc import Callable, Sequence


def _hover_value_label(quantity_title: str) -> str:
    label = quantity_title.strip()
    return label if label else "Value"
def _build_hovertemplate(
    *,
    orientation: Literal["h", "v"],
    quantity_title: str,
    include_trace_name: bool = False,
    include_count: bool = False,
    include_ci: bool = False,
    use_custom_value: bool = False,
    hover_prefix: str = "",
) -> str:
    parts: list[str] = []
    if hover_prefix:
        parts.append(hover_prefix)
    if include_trace_name:
        parts.append("%{fullData.name}")

    # When hover_prefix is set, it already identifies the entity —
    # skip the redundant category axis label (%{x} or %{y}).
    if use_custom_value:
        if not hover_prefix:
            parts.append("%{y}" if orientation == "h" else "%{x}")
        parts.append("Value: %{customdata[0]}")
    else:
        value_label = _hover_value_label(quantity_title)
        if not hover_prefix:
            parts.append("%{y}" if orientation == "h" else "%{x}")
        parts.append(f"{value_label}: %{{x:,.2f}}" if orientation == "h" else f"{value_label}: %{{y:,.2f}}")

    custom_idx = 1 if use_custom_value else 0
    if include_count:
        parts.append(f"%{{customdata[{custom_idx}]}}")
        custom_idx += 1
    if include_ci:
        parts.append(f"%{{customdata[{custom_idx}]}}")

    return "<br>".join(parts) + "<extra></extra>"


def _calculate_error_bars(
    orientation: Literal["h", "v"],
    x_data: list,
    y_data: list,
    lower_bound_data: list,
    upper_bound_data: list,
) -> tuple[dict | None, dict | None]:
    """Calculate asymmetric error bars for bar plots from lower/upper bounds."""
    data = x_data if orientation == "h" else y_data
    def coallesce(val, default=0):
        return default if val is None else val

    errors_plus = [
        max(0.0, coallesce(upper, coallesce(val)) - coallesce(val))
        for val, upper in zip(data, upper_bound_data)
    ]
    errors_minus = [
        max(0.0, coallesce(val) - coallesce(lower, coallesce(val)))
        for val, lower in zip(data, lower_bound_data)
    ]
    if all(err_plus == 0 and err_minus == 0 for err_plus, err_minus in zip(errors_plus, errors_minus)):
        return None, None

    error_dict = {
        "type": "data",
        "array": errors_plus,
        "arrayminus": errors_minus,
        "symmetric": False,
        "visible": True,
        "color": "black",
        "thickness": 1.5,
        "width": 4,
    }
    
    return (error_dict, None) if orientation == "h" else (None, error_dict)


@timed
def create_bar_plot(
    *,
    data: pl.DataFrame,
    quantity_column: list[str] | str,
    lower_bound_column: list[str] | str | None = None,
    upper_bound_column: list[str] | str | None = None,
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
    count_label: str | None = "Number of models",
    count_label_resolver: Callable[[str], str | None] | None = None,
    compact_hover_values: bool = False,
    hover_prefix: str = "",
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
    lower_bound_cols = (
        [lower_bound_column]
        if isinstance(lower_bound_column, str)
        else (list(lower_bound_column) if lower_bound_column is not None else None)
    )
    upper_bound_cols = (
        [upper_bound_column]
        if isinstance(upper_bound_column, str)
        else (list(upper_bound_column) if upper_bound_column is not None else None)
    )
    
    # Calculate min and max values from the quantity columns (bound-aware)
    data_min, data_max = 0.0, 0.0
    for i, qcol in enumerate(quantity_cols):
        lower_col = lower_bound_cols[i] if lower_bound_cols and i < len(lower_bound_cols) else None
        upper_col = upper_bound_cols[i] if upper_bound_cols and i < len(upper_bound_cols) else None
        q_min, q_max = compute_axis_range(data, qcol, lower_col, upper_col)
        data_min, data_max = min(data_min, q_min), max(data_max, q_max)
    
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
            
            # Calculate error bars if bounds are provided
            error_x = None
            error_y = None
            if lower_bound_cols is not None and upper_bound_cols is not None:
                lower_col = lower_bound_cols[q_idx] if len(lower_bound_cols) > q_idx else lower_bound_cols[0]
                upper_col = upper_bound_cols[q_idx] if len(upper_bound_cols) > q_idx else upper_bound_cols[0]
                if lower_col in data.columns and upper_col in data.columns:
                    lower_data = list(reversed(data[lower_col].to_list()))
                    upper_data = list(reversed(data[upper_col].to_list()))
                    error_x, error_y = _calculate_error_bars(
                        orientation,
                        x_data,
                        y_data,
                        lower_data,
                        upper_data,
                    )
                    ci_strings = [
                        format_confidence_interval(lower, upper, quantity_title)
                        for lower, upper in zip(lower_data, upper_data)
                    ]
                    if not any(ci_strings):
                        ci_strings = None
                else:
                    ci_strings = None
            else:
                ci_strings = None

            value_strings = None
            if compact_hover_values:
                value_data = x_data if orientation == "h" else y_data
                value_strings = [format_compact_hover_value(v, quantity_title) for v in value_data]
            customdata = build_hover_customdata(value_strings, ci_strings)
            
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
                    hovertemplate=_build_hovertemplate(
                        orientation=orientation,
                        quantity_title=quantity_title,
                        include_trace_name=len(quantity_cols) > 1,
                        include_ci=ci_strings is not None,
                        use_custom_value=compact_hover_values,
                        hover_prefix=hover_prefix,
                    ),
                    customdata=customdata,
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
                else:
                    xvals = group_data[second_category_column].to_list()
                    yvals = group_data[qcol].to_list()

                resolved_count_label = (
                    count_label_resolver(group_name)
                    if count_label_resolver is not None
                    else count_label
                )
                count_strings = None
                if resolved_count_label and "model_count" in group_data.columns:
                    model_counts = (
                        list(reversed(group_data["model_count"]))
                        if orientation == "h"
                        else group_data["model_count"].to_list()
                    )
                    count_strings = [
                        f"{resolved_count_label}: {format_count_value(mc)}" if mc is not None else ""
                        for mc in model_counts
                    ]
                value_strings = None
                if compact_hover_values:
                    value_data = xvals if orientation == "h" else yvals
                    value_strings = [format_compact_hover_value(v, quantity_title) for v in value_data]

                text_vals = None
                if is_stacked and q_idx == 0:
                    text_vals = [""] * (len(xvals) - 1) + [group_name]
                
                # Calculate error bars if bounds are provided
                error_x = None
                error_y = None
                if lower_bound_cols is not None and upper_bound_cols is not None:
                    lower_col = lower_bound_cols[q_idx] if len(lower_bound_cols) > q_idx else lower_bound_cols[0]
                    upper_col = upper_bound_cols[q_idx] if len(upper_bound_cols) > q_idx else upper_bound_cols[0]
                    if lower_col in group_data.columns and upper_col in group_data.columns:
                        if orientation == "h":
                            lower_data = list(reversed(group_data[lower_col].to_list()))
                            upper_data = list(reversed(group_data[upper_col].to_list()))
                        else:
                            lower_data = group_data[lower_col].to_list()
                            upper_data = group_data[upper_col].to_list()
                        error_x, error_y = _calculate_error_bars(
                            orientation,
                            xvals,
                            yvals,
                            lower_data,
                            upper_data,
                        )
                        ci_strings = [
                            format_confidence_interval(lower, upper, quantity_title)
                            for lower, upper in zip(lower_data, upper_data)
                        ]
                        if not any(ci_strings):
                            ci_strings = None
                    else:
                        ci_strings = None
                else:
                    ci_strings = None

                customdata = build_hover_customdata(value_strings, count_strings, ci_strings)
                
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
                        hovertemplate=_build_hovertemplate(
                            orientation=orientation,
                            quantity_title=quantity_title,
                            include_trace_name=True,
                            include_count=count_strings is not None,
                            include_ci=ci_strings is not None,
                            use_custom_value=value_strings is not None,
                            hover_prefix=hover_prefix,
                        ),
                        customdata=customdata,
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
