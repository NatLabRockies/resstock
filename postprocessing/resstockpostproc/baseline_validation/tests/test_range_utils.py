"""Tests for shared axis range calculation."""

import polars as pl

from resstockpostproc.shared_utils.generic_plotters.range_utils import compute_axis_range


def test_compute_axis_range_uses_raw_value_when_bounds_are_null():
    data = pl.DataFrame(
        {
            "source": ["RECS 2020", "ResStock 2024", "ResStock 2025"],
            "propane_total_value": [23_000.0, 34_200.0, 33_900.0],
            "propane_total_value_lower_bound": [22_000.0, None, None],
            "propane_total_value_upper_bound": [24_000.0, None, None],
        }
    )

    min_val, max_val = compute_axis_range(
        data,
        quantity_column="propane_total_value",
        lower_bound_column="propane_total_value_lower_bound",
        upper_bound_column="propane_total_value_upper_bound",
    )

    assert min_val == 0.0
    assert max_val == 34_200.0


def test_compute_axis_range_keeps_bound_extremes_when_present():
    data = pl.DataFrame(
        {
            "electricity_total_value": [100.0, 120.0],
            "electricity_total_value_lower_bound": [90.0, 110.0],
            "electricity_total_value_upper_bound": [130.0, 125.0],
        }
    )

    min_val, max_val = compute_axis_range(
        data,
        quantity_column="electricity_total_value",
        lower_bound_column="electricity_total_value_lower_bound",
        upper_bound_column="electricity_total_value_upper_bound",
    )

    assert min_val == 0.0
    assert max_val == 130.0
