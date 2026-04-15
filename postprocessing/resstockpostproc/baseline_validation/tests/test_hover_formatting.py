import polars as pl

from resstockpostproc.shared_utils.generic_plotters.bar_plotter import create_bar_plot
from resstockpostproc.shared_utils.generic_plotters.monthly_plotter import create_ts_plot


def test_bar_hover_uses_two_decimals_and_recs_sample_label():
    data = pl.DataFrame({
        "source": ["RECS 2020", "ResStock 2025"],
        "state": ["CA", "CA"],
        "electricity_total_value": [1_223_232_232.22, 1_101_987_600.0],
        "model_count": [240.1234, 500.0],
    })

    fig = create_bar_plot(
        data=data,
        quantity_column="electricity_total_value",
        first_category_column="source",
        second_category_column="state",
        quantity_title="kWh/unit",
        first_category_title="Data Source",
        second_category_title="State",
        orientation="v",
        count_label_resolver=lambda source: (
            "Number of Samples" if "recs" in source.lower() else "Number of Models"
        ),
        compact_hover_values=True,
    )

    recs_trace = fig.data[0]
    resstock_trace = fig.data[1]
    assert "Value: %{customdata[0]}" in recs_trace.hovertemplate
    assert "%{customdata[1]}" in recs_trace.hovertemplate
    assert recs_trace.customdata[0][0] == "1.22B kWh/unit"
    assert recs_trace.customdata[0][1] == "Number of Samples: 240"
    assert resstock_trace.customdata[0][1] == "Number of Models: 500"


def test_bar_hover_uses_resstock_models_only_for_eia_plot():
    data = pl.DataFrame({
        "source": ["EIA 2018", "ResStock 2025"],
        "state": ["CA", "CA"],
        "electricity_total_value": [2_345_600.0, 2_789_000.0],
        "model_count": [None, 120.0],
    })

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
    assert eia_trace.customdata[0][0] == "2.35M kWh"
    assert "%{customdata[1]}" not in eia_trace.hovertemplate
    assert resstock_trace.customdata[0][1] == "Number of Models: 120"


def test_monthly_hover_uses_compact_values():
    data = pl.DataFrame({
        "source": ["RECS 2020", "RECS 2020"],
        "month": ["JAN", "FEB"],
        "electricity_total_value": [1_223_232_232.22, 98_765_432.0],
    })

    fig = create_ts_plot(
        data=data,
        timeseries_column="month",
        quantity_column="electricity_total_value",
        first_category_column="source",
        quantity_title="kWh",
        compact_hover_values=True,
    )

    assert "%{customdata[0]}" in fig.data[-1].hovertemplate
    assert fig.data[-1].customdata[0][0] == "1.22B kWh"
