from resstockpostproc.baseline_validation.create_html_viewer import METRIC_ORDER


def test_metric_order_includes_simplified_lrd_metrics():
    assert METRIC_ORDER == [
        "Total Annual Consumption",
        "Total Monthly Consumption",
        "Average Annual Consumption",
        "Average Monthly Consumption",
        "Average Daily Consumption",
        "Average Day Hourly Consumption",
        "Load Duration Plot",
        "Load Vs Outdoor Drybulb Temperature",
        "Distribution of Annual Consumption",
        "Enduse Penetration",
    ]
