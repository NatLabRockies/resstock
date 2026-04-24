"""Tests for bar chart error bar calculation from explicit bounds."""

import pytest

from resstockpostproc.shared_utils.generic_plotters.bar_plotter import _calculate_error_bars


class TestCalculateErrorBars:
    def test_horizontal_returns_error_x(self):
        error_x, error_y = _calculate_error_bars(
            orientation="h",
            x_data=[100.0, 200.0],
            y_data=["CA", "NY"],
            lower_bound_data=[90.0, 180.0],
            upper_bound_data=[120.0, 230.0],
        )
        assert error_x is not None
        assert error_y is None
        assert error_x["array"] == pytest.approx([20.0, 30.0])
        assert error_x["arrayminus"] == pytest.approx([10.0, 20.0])

    def test_vertical_returns_error_y(self):
        error_x, error_y = _calculate_error_bars(
            orientation="v",
            x_data=["CA", "NY"],
            y_data=[100.0, 200.0],
            lower_bound_data=[95.0, 150.0],
            upper_bound_data=[110.0, 240.0],
        )
        assert error_x is None
        assert error_y is not None
        assert error_y["array"] == pytest.approx([10.0, 40.0])
        assert error_y["arrayminus"] == pytest.approx([5.0, 50.0])

    def test_zero_width_bounds_return_none(self):
        error_x, error_y = _calculate_error_bars(
            orientation="h",
            x_data=[100.0, 200.0],
            y_data=["CA", "NY"],
            lower_bound_data=[100.0, 200.0],
            upper_bound_data=[100.0, 200.0],
        )
        assert error_x is None
        assert error_y is None

    def test_none_bounds_coalesce_to_point_value(self):
        error_x, error_y = _calculate_error_bars(
            orientation="h",
            x_data=[None, 200.0],
            y_data=["CA", "NY"],
            lower_bound_data=[None, None],
            upper_bound_data=[None, 250.0],
        )
        assert error_y is None
        assert error_x is not None
        assert error_x["array"][0] == pytest.approx(0.0)
        assert error_x["arrayminus"][0] == pytest.approx(0.0)
        assert error_x["array"][1] == pytest.approx(50.0)
        assert error_x["arrayminus"][1] == pytest.approx(0.0)

    def test_error_dict_structure(self):
        error_x, _ = _calculate_error_bars(
            orientation="h",
            x_data=[100.0],
            y_data=["CA"],
            lower_bound_data=[95.0],
            upper_bound_data=[110.0],
        )
        assert error_x["type"] == "data"
        assert error_x["visible"] is True
        assert error_x["color"] == "black"
        assert error_x["thickness"] == 1.5
        assert error_x["width"] == 4
        assert error_x["symmetric"] is False
