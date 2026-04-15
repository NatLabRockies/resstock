"""Tests for Jackknife RSE calculation."""

import warnings

import numpy as np
import pandas as pd
import pytest

from resstockpostproc.baseline_validation.data_processing.recs_rse import (
    R,
    WEIGHT_COL,
    calculate_rse,
    calculate_rse_batch,
)


def _make_recs_df(values, base_weights, replicate_overrides=None):
    """Build a minimal RECS-like DataFrame with NWEIGHT + NWEIGHT1..NWEIGHT60.

    Args:
        values: list of variable values
        base_weights: list of base weights (NWEIGHT)
        replicate_overrides: dict of {replicate_index (1-based): list of weights}.
            All other replicates default to base_weights.
    """
    n = len(values)
    data = {"VAR": values, WEIGHT_COL: base_weights}
    overrides = replicate_overrides or {}
    for i in range(1, R + 1):
        data[f"{WEIGHT_COL}{i}"] = overrides.get(i, base_weights)
    return pd.DataFrame(data)


class TestCalculateRSETotal:
    def test_uniform_replicates_zero_rse(self):
        """When all replicate weights == base weight, RSE should be 0."""
        df = _make_recs_df(values=[10, 20, 30], base_weights=[1.0, 1.0, 1.0])
        rse = calculate_rse(df, "VAR", stat_type="total")
        assert rse == 0.0

    def test_known_perturbation(self):
        """Hand-verify RSE with one perturbed replicate.

        Base: values=[10, 20], weights=[1, 1] → estimate = 10*1 + 20*1 = 30
        Replicate 1: weights=[2, 1] → rep_est = 10*2 + 20*1 = 40
        Replicates 2-60: same as base → rep_est = 30

        diffs: [10, 0, 0, ..., 0] (60 values, only first is non-zero)
        sum_sq_diffs = 100
        variance = (59/60) * 100 = 98.333...
        std_error = sqrt(98.333...) = 9.9163...
        RSE = (9.9163 / 30) * 100 = 33.054...
        """
        df = _make_recs_df(
            values=[10.0, 20.0],
            base_weights=[1.0, 1.0],
            replicate_overrides={1: [2.0, 1.0]},
        )
        rse = calculate_rse(df, "VAR", stat_type="total")

        expected_variance = (59 / 60) * 100
        expected_std_error = np.sqrt(expected_variance)
        expected_rse = (expected_std_error / 30) * 100
        assert rse == pytest.approx(expected_rse)

    def test_zero_estimate_returns_zero(self):
        """When all variable values are 0, estimate=0, RSE should be 0."""
        df = _make_recs_df(values=[0, 0, 0], base_weights=[1.0, 2.0, 3.0])
        rse = calculate_rse(df, "VAR", stat_type="total")
        assert rse == 0


class TestCalculateRSEAvg:
    def test_uniform_replicates_zero_rse(self):
        df = _make_recs_df(values=[10, 20], base_weights=[1.0, 1.0])
        rse = calculate_rse(df, "VAR", stat_type="avg")
        assert rse == 0.0

    def test_known_perturbation(self):
        """Hand-verify weighted mean RSE.

        Base: values=[10, 20], weights=[1, 1]
        estimate = (10+20) / (1+1) = 15
        Replicate 1: weights=[2, 1]
        rep_est = (10*2 + 20*1) / (2+1) = 40/3 = 13.333...
        Replicates 2-60: same as base → 15

        diff_1 = 13.333... - 15 = -1.666...
        sum_sq_diffs = (-1.666...)^2 = 2.777...
        variance = (59/60) * 2.777... = 2.731...
        std_error = sqrt(2.731...) = 1.6527...
        RSE = (1.6527... / 15) * 100 = 11.018...
        """
        df = _make_recs_df(
            values=[10.0, 20.0],
            base_weights=[1.0, 1.0],
            replicate_overrides={1: [2.0, 1.0]},
        )
        rse = calculate_rse(df, "VAR", stat_type="avg")

        base_est = 15.0
        rep1_est = 40.0 / 3.0
        diff_sq = (rep1_est - base_est) ** 2
        expected_variance = (59 / 60) * diff_sq
        expected_rse = (np.sqrt(expected_variance) / base_est) * 100
        assert rse == pytest.approx(expected_rse)


class TestCalculateRSEPercent:
    def test_all_positive_values(self):
        """All values > 0 → percent indicator is all 1s → uniform replicates → RSE = 0."""
        df = _make_recs_df(values=[5, 10, 15], base_weights=[1.0, 1.0, 1.0])
        rse = calculate_rse(df, "VAR", stat_type="percent")
        assert rse == 0.0

    def test_mixed_values_with_perturbation(self):
        """One positive, one zero. Binary indicator = [1, 0].

        Base: weights=[1, 1], indicator=[1, 0]
        estimate = (1*1 + 0*1) / (1+1) = 0.5
        Replicate 1: weights=[3, 1], indicator=[1, 0]
        rep_est = (1*3 + 0*1) / (3+1) = 0.75
        """
        df = _make_recs_df(
            values=[10.0, 0.0],
            base_weights=[1.0, 1.0],
            replicate_overrides={1: [3.0, 1.0]},
        )
        rse = calculate_rse(df, "VAR", stat_type="percent")

        base_est = 0.5
        rep1_est = 0.75
        diff_sq = (rep1_est - base_est) ** 2
        expected_variance = (59 / 60) * diff_sq
        expected_rse = (np.sqrt(expected_variance) / base_est) * 100
        assert rse == pytest.approx(expected_rse)


class TestCalculateRSEQuantiles:
    def test_median_uniform_replicates(self):
        """With uniform replicates, median RSE should be 0."""
        df = _make_recs_df(values=[10, 20, 30], base_weights=[1.0, 1.0, 1.0])
        rse = calculate_rse(df, "VAR", stat_type="median")
        assert rse == 0.0

    def test_q1_and_q3_uniform(self):
        df = _make_recs_df(values=[10, 20, 30, 40], base_weights=[1.0, 1.0, 1.0, 1.0])
        rse_q1 = calculate_rse(df, "VAR", stat_type="q1")
        rse_q3 = calculate_rse(df, "VAR", stat_type="q3")
        assert rse_q1 == 0.0
        assert rse_q3 == 0.0


class TestCalculateRSEValidation:
    def test_invalid_stat_type_raises(self):
        df = _make_recs_df(values=[1], base_weights=[1.0])
        with pytest.raises(ValueError, match="stat_type must be one of"):
            calculate_rse(df, "VAR", stat_type="invalid")


class TestCalculateRSEBatch:
    def test_batch_matches_loop(self):
        """Batched results must match per-call calculate_rse across stat types."""
        df = _make_recs_df(
            values=[10, 20, 30, 0],
            base_weights=[1.0, 2.0, 1.5, 0.5],
            replicate_overrides={1: [0.5, 2.5, 2.0, 0.0], 7: [1.5, 1.5, 1.0, 1.0]},
        )
        df["VAR2"] = [5, 0, 15, 25]
        for i in range(1, R + 1):
            pass  # VAR2 already broadcasts; replicate columns stay as-is

        requests = [
            ("VAR", "total"),
            ("VAR", "avg"),
            ("VAR", "percent"),
            ("VAR2", "avg"),
            ("VAR2", "percent"),
        ]
        batch = calculate_rse_batch(df, requests)

        for var, stat in requests:
            expected = calculate_rse(df, var, stat_type=stat)
            actual = batch[(var, stat)]
            assert np.isclose(actual, expected, rtol=1e-10, atol=1e-12), (
                f"mismatch for {(var, stat)}: batch={actual}, loop={expected}"
            )

    def test_batch_empty_requests(self):
        df = _make_recs_df(values=[1, 2], base_weights=[1.0, 1.0])
        assert calculate_rse_batch(df, []) == {}

    def test_batch_zero_weight_returns_nan(self):
        df = _make_recs_df(values=[10, 20], base_weights=[0.0, 0.0])
        batch = calculate_rse_batch(df, [("VAR", "avg"), ("VAR", "percent")])
        assert np.isnan(batch[("VAR", "avg")])
        assert np.isnan(batch[("VAR", "percent")])


class TestCalculateRSEDegenerateWeights:
    def test_zero_base_weight_avg_returns_nan(self):
        df = _make_recs_df(values=[10, 20], base_weights=[0.0, 0.0])
        rse = calculate_rse(df, "VAR", stat_type="avg")
        assert np.isnan(rse)

    def test_zero_base_weight_percent_returns_nan(self):
        df = _make_recs_df(values=[10, 20], base_weights=[0.0, 0.0])
        rse = calculate_rse(df, "VAR", stat_type="percent")
        assert np.isnan(rse)

    def test_zero_replicate_weight_no_warning_and_finite(self):
        """A single collapsed replicate must not produce a RuntimeWarning or NaN RSE."""
        df = _make_recs_df(
            values=[10, 20],
            base_weights=[1.0, 1.0],
            replicate_overrides={1: [0.0, 0.0]},
        )
        with warnings.catch_warnings():
            warnings.simplefilter("error", RuntimeWarning)
            rse_avg = calculate_rse(df, "VAR", stat_type="avg")
            rse_pct = calculate_rse(df, "VAR", stat_type="percent")
        assert np.isfinite(rse_avg)
        assert np.isfinite(rse_pct)
