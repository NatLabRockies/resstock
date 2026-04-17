"""Tests for RECS log-normal confidence-bound calculation."""

import numpy as np
import pandas as pd
import pytest

from resstockpostproc.baseline_validation.data_processing.recs_rse import (
    FAY_EPSILON,
    WEIGHT_COL,
    calculate_bounds_batch,
    calculate_log_ci_bounds,
    get_replicate_weight_columns,
)


def _make_recs_df(values, base_weights, replicate_overrides=None, n_replicates=60):
    """Build a minimal RECS-like DataFrame with NWEIGHT + replicate weights."""
    data = {"VAR": values, WEIGHT_COL: base_weights}
    overrides = replicate_overrides or {}
    for i in range(1, n_replicates + 1):
        data[f"{WEIGHT_COL}{i}"] = overrides.get(i, base_weights)
    return pd.DataFrame(data)


def _expected_bounds(base_estimate: float, replicate_estimate: float, n_replicates: int) -> tuple[float, float]:
    variance_log = ((np.log(replicate_estimate) - np.log(base_estimate)) ** 2) / (
        n_replicates * (1 - FAY_EPSILON) ** 2
    )
    se_log = np.sqrt(variance_log)
    lower = np.exp(np.log(base_estimate) - 1.96 * se_log)
    upper = np.exp(np.log(base_estimate) + 1.96 * se_log)
    return lower, upper


class TestReplicateColumnDetection:
    def test_detects_columns_dynamically(self):
        df = _make_recs_df(values=[10, 20], base_weights=[1.0, 1.0], n_replicates=3)
        assert get_replicate_weight_columns(df) == ["NWEIGHT1", "NWEIGHT2", "NWEIGHT3"]


class TestCalculateLogCIBounds:
    def test_uniform_replicates_collapse_to_point(self):
        df = _make_recs_df(values=[10, 20, 30], base_weights=[1.0, 1.0, 1.0])
        lower, upper = calculate_log_ci_bounds(df, "VAR", stat_type="total")
        assert lower == pytest.approx(60.0)
        assert upper == pytest.approx(60.0)

    def test_known_total_perturbation(self):
        df = _make_recs_df(
            values=[10.0, 20.0],
            base_weights=[1.0, 1.0],
            replicate_overrides={1: [2.0, 1.0]},
        )
        lower, upper = calculate_log_ci_bounds(df, "VAR", stat_type="total")
        expected_lower, expected_upper = _expected_bounds(30.0, 40.0, 60)
        assert lower == pytest.approx(expected_lower)
        assert upper == pytest.approx(expected_upper)

    def test_avg_nonzero_matches_users_only_estimator(self):
        df = _make_recs_df(
            values=[10.0, 20.0, 0.0],
            base_weights=[1.0, 1.0, 1.0],
            replicate_overrides={1: [2.0, 1.0, 1.0]},
        )
        lower, upper = calculate_log_ci_bounds(df, "VAR", stat_type="avg_nonzero")
        expected_lower, expected_upper = _expected_bounds(15.0, 40.0 / 3.0, 60)
        assert lower == pytest.approx(expected_lower)
        assert upper == pytest.approx(expected_upper)

    def test_percent_bounds_use_percentage_scale(self):
        df = _make_recs_df(
            values=[10.0, 0.0],
            base_weights=[1.0, 1.0],
            replicate_overrides={1: [3.0, 1.0]},
        )
        lower, upper = calculate_log_ci_bounds(df, "VAR", stat_type="percent")
        expected_lower, expected_upper = _expected_bounds(50.0, 75.0, 60)
        assert lower == pytest.approx(expected_lower)
        assert upper == pytest.approx(expected_upper)

    def test_non_positive_replicate_collapses_to_point_estimate(self):
        df = _make_recs_df(
            values=[10.0, 0.0],
            base_weights=[1.0, 1.0],
            replicate_overrides={1: [0.0, 1.0]},
        )
        lower, upper = calculate_log_ci_bounds(df, "VAR", stat_type="total")
        assert lower == pytest.approx(10.0)
        assert upper == pytest.approx(10.0)

    def test_invalid_stat_type_raises(self):
        df = _make_recs_df(values=[1.0], base_weights=[1.0])
        with pytest.raises(ValueError, match="stat_type"):
            calculate_log_ci_bounds(df, "VAR", stat_type="median")


class TestCalculateBoundsBatch:
    def test_batch_matches_single_call(self):
        df = _make_recs_df(
            values=[10, 20, 30, 0],
            base_weights=[1.0, 2.0, 1.5, 0.5],
            replicate_overrides={1: [0.5, 2.5, 2.0, 0.0], 7: [1.5, 1.5, 1.0, 1.0]},
        )
        df["VAR2"] = [5, 0, 15, 25]
        requests = [
            ("VAR", "total"),
            ("VAR", "avg"),
            ("VAR", "percent"),
            ("VAR2", "avg_nonzero"),
            ("VAR2", "percent"),
        ]
        batch = calculate_bounds_batch(df, requests)

        for variable_col, stat_type in requests:
            assert batch[(variable_col, stat_type)] == pytest.approx(
                calculate_log_ci_bounds(df, variable_col, stat_type)
            )

    def test_empty_requests(self):
        df = _make_recs_df(values=[1.0, 2.0], base_weights=[1.0, 1.0])
        assert calculate_bounds_batch(df, []) == {}
