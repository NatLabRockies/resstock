"""Shared weighted-statistics helpers for baseline validation loaders.

Extracted from get_recs_data.py / get_resstock_data.py in refactor plan V2
step 5.1. Consumers: annual aggregation in both loaders.
"""

from __future__ import annotations

import numpy as np


def weighted_quantiles(
    data: np.ndarray,
    weights: np.ndarray,
    quantiles: list[float],
) -> np.ndarray:
    """Calculate weighted quantiles.

    Args:
        data: Data values
        weights: Weights for each data value
        quantiles: List of quantiles to calculate (between 0 and 1)

    Returns:
        Array of quantile values
    """
    # Sort data and weights by data values
    sorted_indices = np.argsort(data)
    sorted_data = data[sorted_indices]
    sorted_weights = weights[sorted_indices]

    # Calculate cumulative weights
    cumsum_weights = np.cumsum(sorted_weights)
    total_weight = cumsum_weights[-1]

    # Normalize cumulative weights to [0, 1]
    cumsum_normalized = cumsum_weights / total_weight

    # Calculate quantiles
    result = np.zeros(len(quantiles))
    for i, q in enumerate(quantiles):
        if q == 0:
            result[i] = sorted_data[0]
        elif q == 1:
            result[i] = sorted_data[-1]
        else:
            # Find the index where cumulative weight exceeds quantile
            idx = np.searchsorted(cumsum_normalized, q)
            if idx == 0:
                result[i] = sorted_data[0]
            elif idx >= len(sorted_data):
                result[i] = sorted_data[-1]
            else:
                # Linear interpolation
                w0 = cumsum_normalized[idx - 1]
                w1 = cumsum_normalized[idx]
                v0 = sorted_data[idx - 1]
                v1 = sorted_data[idx]
                if w1 - w0 > 0:
                    result[i] = v0 + (v1 - v0) * (q - w0) / (w1 - w0)
                else:
                    result[i] = v0

    return result
