"""Helpers for RECS replicate-weight confidence bounds."""

from __future__ import annotations

import re
from collections.abc import Iterable

import numpy as np


WEIGHT_COL = "NWEIGHT"
FAY_EPSILON = 0.5
CI_Z = 1.96
_VALID_STATS = {"total", "avg", "avg_nonzero", "percent"}
_REP_WEIGHT_RE = re.compile(rf"^{WEIGHT_COL}(\d+)$")


def get_replicate_weight_columns(df) -> list[str]:
    """Return RECS replicate weight columns sorted numerically."""
    replicate_cols: list[tuple[int, str]] = []
    for col in df.columns:
        match = _REP_WEIGHT_RE.match(str(col))
        if match:
            replicate_cols.append((int(match.group(1)), str(col)))
    replicate_cols.sort()
    return [col for _, col in replicate_cols]


def _weight_columns(df) -> list[str]:
    replicate_cols = get_replicate_weight_columns(df)
    if not replicate_cols:
        raise ValueError("No RECS replicate weight columns were found.")
    return [WEIGHT_COL] + replicate_cols


def _validate_stat_type(stat_type: str) -> None:
    if stat_type not in _VALID_STATS:
        raise ValueError(f"stat_type must be one of {sorted(_VALID_STATS)}")


def _collapse_bounds(estimate: float) -> tuple[float, float]:
    estimate = float(estimate)
    return estimate, estimate


def _log_bounds_from_estimates(estimates: np.ndarray) -> tuple[float, float]:
    """Convert base + replicate estimates into asymmetric log-normal bounds."""
    base_estimate = float(estimates[0])
    if not np.isfinite(base_estimate):
        return np.nan, np.nan
    if base_estimate <= 0:
        return _collapse_bounds(base_estimate)

    replicate_estimates = estimates[1:]
    if replicate_estimates.size == 0:
        return _collapse_bounds(base_estimate)
    if not np.all(np.isfinite(replicate_estimates)) or np.any(replicate_estimates <= 0):
        return _collapse_bounds(base_estimate)

    log_base = np.log(base_estimate)
    log_reps = np.log(replicate_estimates)
    variance_log = np.sum((log_reps - log_base) ** 2) / (replicate_estimates.size * (1 - FAY_EPSILON) ** 2)
    se_log = np.sqrt(variance_log)
    lower = float(np.exp(log_base - CI_Z * se_log))
    upper = float(np.exp(log_base + CI_Z * se_log))
    return lower, upper


def _compute_estimates(df, variable_col: str, stat_type: str) -> np.ndarray:
    """Compute the base estimate and all replicate estimates for one statistic."""
    _validate_stat_type(stat_type)

    weight_cols = _weight_columns(df)
    weight_matrix = df[weight_cols].to_numpy(dtype=float)
    weight_sums = weight_matrix.sum(axis=0)
    zero_weight_mask = weight_sums == 0
    values = df[variable_col].to_numpy(dtype=float)

    if stat_type == "percent":
        payload = (values > 0).astype(float)
        weighted_sums = payload @ weight_matrix
        with np.errstate(invalid="ignore", divide="ignore"):
            estimates = np.where(zero_weight_mask, np.nan, weighted_sums / weight_sums * 100.0)
        return estimates

    if stat_type == "avg_nonzero":
        nonzero_mask = (values > 0).astype(float)
        numerator = values @ weight_matrix
        denominator = nonzero_mask @ weight_matrix
        with np.errstate(invalid="ignore", divide="ignore"):
            estimates = np.where(denominator == 0, np.nan, numerator / denominator)
        return estimates

    weighted_sums = values @ weight_matrix
    if stat_type == "total":
        return weighted_sums

    with np.errstate(invalid="ignore", divide="ignore"):
        return np.where(zero_weight_mask, np.nan, weighted_sums / weight_sums)


def calculate_log_ci_bounds(df, variable_col: str, stat_type: str = "total") -> tuple[float, float]:
    """Calculate asymmetric 95% confidence bounds for one RECS statistic."""
    estimates = _compute_estimates(df, variable_col, stat_type)
    return _log_bounds_from_estimates(estimates)


def calculate_bounds_batch(df, requests: Iterable[tuple[str, str]]) -> dict[tuple[str, str], tuple[float, float]]:
    """Compute log-normal confidence bounds for many requests at once."""
    requests = list(requests)
    if not requests:
        return {}

    weight_cols = _weight_columns(df)
    weight_matrix = df[weight_cols].to_numpy(dtype=float)
    weight_sums = weight_matrix.sum(axis=0)
    zero_weight_mask = weight_sums == 0

    results: dict[tuple[str, str], tuple[float, float]] = {}
    numeric_cache: dict[str, np.ndarray] = {}
    indicator_cache: dict[str, np.ndarray] = {}

    for variable_col, stat_type in requests:
        _validate_stat_type(stat_type)
        values = numeric_cache.setdefault(variable_col, df[variable_col].to_numpy(dtype=float))

        if stat_type == "percent":
            indicator = indicator_cache.setdefault(variable_col, (values > 0).astype(float))
            weighted_sums = indicator @ weight_matrix
            with np.errstate(invalid="ignore", divide="ignore"):
                estimates = np.where(zero_weight_mask, np.nan, weighted_sums / weight_sums * 100.0)
        elif stat_type == "avg_nonzero":
            indicator = indicator_cache.setdefault(variable_col, (values > 0).astype(float))
            numerator = values @ weight_matrix
            denominator = indicator @ weight_matrix
            with np.errstate(invalid="ignore", divide="ignore"):
                estimates = np.where(denominator == 0, np.nan, numerator / denominator)
        else:
            weighted_sums = values @ weight_matrix
            if stat_type == "total":
                estimates = weighted_sums
            else:
                with np.errstate(invalid="ignore", divide="ignore"):
                    estimates = np.where(zero_weight_mask, np.nan, weighted_sums / weight_sums)

        results[(variable_col, stat_type)] = _log_bounds_from_estimates(estimates)

    return results
