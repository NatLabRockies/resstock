import polars as pl

from resstockpostproc.shared_utils.generic_plotters.bar_plotter import create_bar_plot
from resstockpostproc.shared_utils.generic_plotters.hover_formatting import format_percent_difference
from resstockpostproc.shared_utils.generic_plotters.monthly_plotter import create_ts_plot


def test_bar_hover_uses_two_decimals_and_recs_sample_label():
    data = pl.DataFrame(
        {
            "source": ["RECS 2020", "ResStock 2025"],
            "state": ["CA", "CA"],
            "electricity_total_value": [1_223_232_232.22, 1_101_987_600.0],
            "electricity_total_value_lower_bound": [1_100_000_000.0, None],
            "electricity_total_value_upper_bound": [1_300_000_000.0, None],
            "model_count": [240.1234, 500.0],
        }
    )

    fig = create_bar_plot(
        data=data,
        quantity_column="electricity_total_value",
        lower_bound_column="electricity_total_value_lower_bound",
        upper_bound_column="electricity_total_value_upper_bound",
        first_category_column="source",
        second_category_column="state",
        quantity_title="kWh/unit",
        first_category_title="Data Source",
        second_category_title="State",
        orientation="v",
        count_label_resolver=lambda source: ("Number of Samples" if "recs" in source.lower() else "Number of Models"),
        compact_hover_values=True,
    )

    recs_trace = fig.data[0]
    resstock_trace = fig.data[1]
    assert "Value: %{customdata[0]}" in recs_trace.hovertemplate
    assert "%{customdata[1]}" in recs_trace.hovertemplate
    assert "%{customdata[2]}" in recs_trace.hovertemplate
    assert recs_trace.customdata[0][0] == "1.22B"
    # customdata tuple order: (value, count, ci). Use compact suffixes for CI.
    assert recs_trace.customdata[0][1] == "Number of Samples: 240"
    assert recs_trace.customdata[0][2] == "95% Confidence Interval: 1.10B to 1.30B"
    assert resstock_trace.customdata[0][1] == "Number of Models: 500"
    assert "Confidence Interval" not in resstock_trace.hovertemplate


def test_bar_hover_uses_resstock_models_only_for_eia_plot():
    data = pl.DataFrame(
        {
            "source": ["EIA 2018", "ResStock 2025"],
            "state": ["CA", "CA"],
            "electricity_total_value": [2_345_600.0, 2_789_000.0],
            "model_count": [None, 120.0],
        }
    )

    fig = create_bar_plot(
        data=data,
        quantity_column="electricity_total_value",
        first_category_column="source",
        second_category_column="state",
        quantity_title="kWh",
        first_category_title="Data Source",
        second_category_title="State",
        orientation="v",
        count_label_resolver=lambda source: "Number of Models" if "resstock" in source.lower() else None,
        compact_hover_values=True,
    )

    eia_trace = fig.data[0]
    resstock_trace = fig.data[1]
    assert eia_trace.customdata[0][0] == "2.35M"
    assert "%{customdata[1]}" not in eia_trace.hovertemplate
    assert resstock_trace.customdata[0][1] == "Number of Models: 120"


def test_bar_hover_retains_percent_suffix_for_percentage_titles():
    data = pl.DataFrame(
        {
            "source": ["RECS 2020"],
            "electricity_total_percent_difference": [12.3456],
        }
    )

    fig = create_bar_plot(
        data=data,
        quantity_column="electricity_total_percent_difference",
        first_category_column="source",
        quantity_title="Percent Difference",
        first_category_title="Data Source",
        orientation="v",
        compact_hover_values=True,
    )

    assert fig.data[0].customdata[0][0] == "12.35%"


def test_monthly_hover_uses_compact_values():
    data = pl.DataFrame(
        {
            "source": ["RECS 2020", "RECS 2020"],
            "month": ["JAN", "FEB"],
            "electricity_total_value": [1_223_232_232.22, 98_765_432.0],
            "electricity_total_value_lower_bound": [1_100_000_000.0, 90_000_000.0],
            "electricity_total_value_upper_bound": [1_300_000_000.0, 120_000_000.0],
        }
    )

    fig = create_ts_plot(
        data=data,
        timeseries_column="month",
        quantity_column="electricity_total_value",
        lower_bound_column="electricity_total_value_lower_bound",
        upper_bound_column="electricity_total_value_upper_bound",
        first_category_column="source",
        quantity_title="kWh",
        compact_hover_values=True,
    )

    assert "%{customdata[0]}" in fig.data[-1].hovertemplate
    assert "%{customdata[1]}" in fig.data[-1].hovertemplate
    assert fig.data[-1].customdata[0][0] == "1.22B"
    # customdata tuple order: (value, ci, label). CI uses compact suffixes.
    assert fig.data[-1].customdata[0][1] == "95% Confidence Interval: 1.10B to 1.30B"


def test_monthly_hover_can_include_source_specific_count_labels():
    data = pl.DataFrame(
        {
            "source": ["LRD 2018", "LRD 2018", "ResStock 2025", "ResStock 2025"],
            "month": ["JAN", "FEB", "JAN", "FEB"],
            "electricity_total_value": [1_223_232_232.22, 98_765_432.0, 1_101_987_600.0, 87_654_321.0],
            "model_count": [None, None, 500.0, 500.0],
        }
    )

    fig = create_ts_plot(
        data=data,
        timeseries_column="month",
        quantity_column="electricity_total_value",
        first_category_column="source",
        quantity_title="kWh",
        count_label_resolver=lambda source: "Number of Models" if "resstock" in source.lower() else None,
        compact_hover_values=True,
    )

    lrd_trace = next(trace for trace in fig.data if trace.name == "LRD 2018")
    resstock_trace = next(trace for trace in fig.data if trace.name == "ResStock 2025")
    # LRD trace has no count label/values → customdata = (value, label); ResStock has count → (value, count, label)
    assert len(lrd_trace.customdata[0]) == 2
    assert len(resstock_trace.customdata[0]) == 3
    assert resstock_trace.customdata[0][1] == "Number of Models: 500"


def test_format_percent_difference_formats_sign_and_none():
    assert format_percent_difference(12.345) == "Difference: +12.35%"
    assert format_percent_difference(-1.2) == "Difference: -1.20%"
    assert format_percent_difference(0) == "Difference: +0.00%"
    assert format_percent_difference(None) == ""


def test_bar_hover_includes_percent_difference_line():
    data = pl.DataFrame(
        {
            "source": ["RECS 2020", "ResStock 2025"],
            "state": ["CA", "CA"],
            "electricity_total_value": [1_000_000.0, 1_100_000.0],
            "electricity_total_value_percent_difference": [None, 10.0],
        }
    )

    fig = create_bar_plot(
        data=data,
        quantity_column="electricity_total_value",
        first_category_column="source",
        second_category_column="state",
        quantity_title="kWh",
        first_category_title="Data Source",
        second_category_title="State",
        orientation="v",
        compact_hover_values=True,
        percent_difference_column="electricity_total_value_percent_difference",
    )

    resstock_trace = next(trace for trace in fig.data if trace.name == "ResStock 2025")
    # customdata layout for grouped branch: [value, diff] (no count, no ci)
    assert "%{customdata[1]}" in resstock_trace.hovertemplate
    assert resstock_trace.customdata[0][1] == "Difference: +10.00%"


def test_bar_hover_skips_percent_difference_when_all_null():
    data = pl.DataFrame(
        {
            "source": ["RECS 2020"],
            "state": ["CA"],
            "electricity_total_value": [1_000_000.0],
            "electricity_total_value_percent_difference": [None],
        }
    )

    fig = create_bar_plot(
        data=data,
        quantity_column="electricity_total_value",
        first_category_column="source",
        second_category_column="state",
        quantity_title="kWh",
        first_category_title="Data Source",
        second_category_title="State",
        orientation="v",
        compact_hover_values=True,
        percent_difference_column="electricity_total_value_percent_difference",
    )

    recs_trace = fig.data[0]
    assert "Difference" not in recs_trace.hovertemplate
    assert "%{customdata[1]}" not in recs_trace.hovertemplate


def test_bar_hover_display_order_is_value_diff_ci_count():
    """Hover display order must be: value → diff → ci → count (count last)."""
    data = pl.DataFrame(
        {
            "source": ["RECS 2020", "ResStock 2025"],
            "state": ["CA", "CA"],
            "electricity_total_value": [1_000_000.0, 1_100_000.0],
            "electricity_total_value_lower_bound": [900_000.0, 1_000_000.0],
            "electricity_total_value_upper_bound": [1_100_000.0, 1_200_000.0],
            "electricity_total_value_percent_difference": [None, 10.0],
            "model_count": [240.0, 500.0],
        }
    )

    fig = create_bar_plot(
        data=data,
        quantity_column="electricity_total_value",
        lower_bound_column="electricity_total_value_lower_bound",
        upper_bound_column="electricity_total_value_upper_bound",
        first_category_column="source",
        second_category_column="state",
        quantity_title="kWh",
        first_category_title="Data Source",
        second_category_title="State",
        orientation="v",
        count_label_resolver=lambda _source: "Number of Models",
        compact_hover_values=True,
        percent_difference_column="electricity_total_value_percent_difference",
    )

    resstock_trace = next(trace for trace in fig.data if trace.name == "ResStock 2025")
    tpl = resstock_trace.hovertemplate
    # customdata zip order: (value=0, count=1, ci=2, diff=3)
    value_ref, count_ref, ci_ref, diff_ref = (
        "Value: %{customdata[0]}",
        "%{customdata[1]}",
        "%{customdata[2]}",
        "%{customdata[3]}",
    )
    assert all(ref in tpl for ref in (value_ref, count_ref, ci_ref, diff_ref))
    assert tpl.index(value_ref) < tpl.index(diff_ref) < tpl.index(ci_ref) < tpl.index(count_ref)


def test_monthly_hover_display_order_is_value_diff_ci_count():
    """Monthly hover display order must be: value → diff → ci → count."""
    data = pl.DataFrame(
        {
            "source": ["ResStock 2025", "ResStock 2025"],
            "month": ["JAN", "FEB"],
            "electricity_total_value": [1_100_000.0, 900_000.0],
            "electricity_total_value_lower_bound": [1_000_000.0, 800_000.0],
            "electricity_total_value_upper_bound": [1_200_000.0, 1_000_000.0],
            "electricity_total_value_percent_difference": [10.0, -5.0],
            "model_count": [500.0, 500.0],
        }
    )

    fig = create_ts_plot(
        data=data,
        timeseries_column="month",
        quantity_column="electricity_total_value",
        lower_bound_column="electricity_total_value_lower_bound",
        upper_bound_column="electricity_total_value_upper_bound",
        first_category_column="source",
        quantity_title="kWh",
        count_label_resolver=lambda _source: "Number of Models",
        compact_hover_values=True,
        percent_difference_column="electricity_total_value_percent_difference",
    )

    tpl = fig.data[-1].hovertemplate
    # customdata zip order: (value=0, count=1, ci=2, diff=3, label=4)
    value_ref, count_ref, ci_ref, diff_ref = (
        "%{customdata[0]}",
        "%{customdata[1]}",
        "%{customdata[2]}",
        "%{customdata[3]}",
    )
    assert all(ref in tpl for ref in (count_ref, ci_ref, diff_ref))
    value_pos = tpl.find(f"ResStock 2025: {value_ref}")
    assert value_pos >= 0
    assert value_pos < tpl.index(diff_ref) < tpl.index(ci_ref) < tpl.index(count_ref)


def test_monthly_hover_expands_abbreviated_month_labels():
    """Monthly hover must show the full month name ('January') not 'JAN' or '   Jan'."""
    data = pl.DataFrame(
        {
            "source": ["ResStock 2025", "ResStock 2025"],
            "month": ["JAN", "FEB"],
            "electricity_total_value": [1_100_000.0, 900_000.0],
        }
    )

    fig = create_ts_plot(
        data=data,
        timeseries_column="month",
        quantity_column="electricity_total_value",
        first_category_column="source",
        quantity_title="kWh",
        compact_hover_values=True,
        x_tick_vals=("JAN", "FEB"),
        x_tick_text=("   Jan", "Feb   "),
    )

    trace = fig.data[0]
    # The hovertemplate references the customdata-carried label, not %{x}.
    assert "%{x}" not in trace.hovertemplate
    # Label field is the last entry in customdata — expanded to the full month name.
    assert trace.customdata[0][-1] == "January"
    assert trace.customdata[1][-1] == "February"


def test_monthly_hover_passes_non_month_strings_through():
    """Non-month string x values (e.g. 'Hour 1') should pass through unchanged (stripped)."""
    data = pl.DataFrame(
        {
            "source": ["ResStock 2025", "ResStock 2025"],
            "x_label": ["  Hour 1  ", "Hour 24"],
            "electricity_total_value": [1_100_000.0, 900_000.0],
        }
    )

    fig = create_ts_plot(
        data=data,
        timeseries_column="x_label",
        quantity_column="electricity_total_value",
        first_category_column="source",
        quantity_title="kWh",
        compact_hover_values=True,
    )

    trace = fig.data[0]
    assert trace.customdata[0][-1] == "Hour 1"
    assert trace.customdata[1][-1] == "Hour 24"


def test_monthly_hover_includes_percent_difference_line():
    data = pl.DataFrame(
        {
            "source": ["RECS 2020", "RECS 2020", "ResStock 2025", "ResStock 2025"],
            "month": ["JAN", "FEB", "JAN", "FEB"],
            "electricity_total_value": [1_000_000_000.0, 90_000_000.0, 1_100_000_000.0, 80_000_000.0],
            "electricity_total_value_percent_difference": [None, None, 10.0, -11.11],
        }
    )

    fig = create_ts_plot(
        data=data,
        timeseries_column="month",
        quantity_column="electricity_total_value",
        first_category_column="source",
        quantity_title="kWh",
        compact_hover_values=True,
        percent_difference_column="electricity_total_value_percent_difference",
    )

    resstock_trace = next(trace for trace in fig.data if trace.name == "ResStock 2025")
    # customdata layout for timeseries: [value, diff] (no count, no ci)
    assert "%{customdata[1]}" in resstock_trace.hovertemplate
    assert resstock_trace.customdata[0][1] == "Difference: +10.00%"
    assert resstock_trace.customdata[1][1] == "Difference: -11.11%"

    recs_trace = next(trace for trace in fig.data if trace.name == "RECS 2020")
    assert "Difference" not in recs_trace.hovertemplate
