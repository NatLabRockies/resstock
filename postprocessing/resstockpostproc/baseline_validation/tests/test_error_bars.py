"""Tests for bar chart error bar calculation from RSE."""

import pytest

from resstockpostproc.shared_utils.generic_plotters.bar_plotter import _calculate_error_bars


class TestCalculateErrorBars:
    def test_horizontal_returns_error_x(self):
        """Horizontal bars → error_x dict, error_y is None."""
        error_x, error_y = _calculate_error_bars(
            orientation="h",
            x_data=[100.0, 200.0],
            y_data=["CA", "NY"],
            rse_data=[10.0, 5.0],
        )
        assert error_x is not None
        assert error_y is None
        # error = |value * 1.96 * RSE / 100|
        assert error_x["array"][0] == pytest.approx(abs(100 * 1.96 * 10 / 100))
        assert error_x["array"][1] == pytest.approx(abs(200 * 1.96 * 5 / 100))

    def test_vertical_returns_error_y(self):
        """Vertical bars → error_y dict, error_x is None."""
        error_x, error_y = _calculate_error_bars(
            orientation="v",
            x_data=["CA", "NY"],
            y_data=[100.0, 200.0],
            rse_data=[10.0, 5.0],
        )
        assert error_x is None
        assert error_y is not None
        assert error_y["array"][0] == pytest.approx(abs(100 * 1.96 * 10 / 100))

    def test_all_zero_rse_returns_none(self):
        """All RSE values = 0 → no error bars."""
        error_x, error_y = _calculate_error_bars(
            orientation="h",
            x_data=[100.0, 200.0],
            y_data=["CA", "NY"],
            rse_data=[0, 0],
        )
        assert error_x is None
        assert error_y is None

    def test_none_values_coalesced(self):
        """None in values or RSE should be treated as 0."""
        error_x, error_y = _calculate_error_bars(
            orientation="h",
            x_data=[None, 200.0],
            y_data=["CA", "NY"],
            rse_data=[10.0, None],
        )
        assert error_x is not None
        # None value * anything = 0
        assert error_x["array"][0] == pytest.approx(0.0)
        # 200 * 1.96 * 0 / 100 = 0
        assert error_x["array"][1] == pytest.approx(0.0)

    def test_error_dict_structure(self):
        """Verify the error dict has all required Plotly keys."""
        error_x, _ = _calculate_error_bars(
            orientation="h",
            x_data=[100.0],
            y_data=["CA"],
            rse_data=[10.0],
        )
        assert error_x["type"] == "data"
        assert error_x["visible"] is True
        assert error_x["color"] == "black"
        assert error_x["thickness"] == 1.5
        assert error_x["width"] == 4
