"""Shared helpers for weighted histogram binning with an overflow tail bin."""

from __future__ import annotations

import math
import numpy as np
import polars as pl


def _calculate_weighted_quantiles(
    data: np.ndarray,
    weights: np.ndarray,
    quantiles: list[float],
) -> np.ndarray:
    """Calculate weighted quantiles with linear interpolation on cumulative weight."""
    valid = np.isfinite(data) & np.isfinite(weights) & (weights > 0)
    if not np.any(valid):
        return np.zeros(len(quantiles))

    sorted_indices = np.argsort(data[valid])
    sorted_data = data[valid][sorted_indices]
    sorted_weights = weights[valid][sorted_indices]

    cumsum_weights = np.cumsum(sorted_weights)
    total_weight = cumsum_weights[-1]
    if not math.isfinite(float(total_weight)) or total_weight <= 0:
        return np.zeros(len(quantiles))
    cumsum_normalized = cumsum_weights / total_weight

    result = np.zeros(len(quantiles))
    for i, q in enumerate(quantiles):
        if q <= 0:
            result[i] = sorted_data[0]
        elif q >= 1:
            result[i] = sorted_data[-1]
        else:
            idx = np.searchsorted(cumsum_normalized, q)
            if idx == 0:
                result[i] = sorted_data[0]
            elif idx >= len(sorted_data):
                result[i] = sorted_data[-1]
            else:
                w0 = cumsum_normalized[idx - 1]
                w1 = cumsum_normalized[idx]
                v0 = sorted_data[idx - 1]
                v1 = sorted_data[idx]
                if w1 - w0 > 0:
                    result[i] = v0 + (v1 - v0) * (q - w0) / (w1 - w0)
                else:
                    result[i] = v0
    return result


def _weighted_quantile(data: np.ndarray, weights: np.ndarray, q: float) -> float:
    """Convenience wrapper for a single weighted quantile."""
    return float(_calculate_weighted_quantiles(data, weights, [q])[0])


def _weighted_step_quantile(data: np.ndarray, weights: np.ndarray, q: float) -> float:
    """Return the smallest observed value whose cumulative weight reaches ``q``."""
    valid = np.isfinite(data) & np.isfinite(weights) & (weights > 0)
    if not np.any(valid):
        return 0.0

    sorted_indices = np.argsort(data[valid])
    sorted_data = data[valid][sorted_indices]
    sorted_weights = weights[valid][sorted_indices]

    cumsum_weights = np.cumsum(sorted_weights)
    total_weight = cumsum_weights[-1]
    if not math.isfinite(float(total_weight)) or total_weight <= 0:
        return 0.0

    cumsum_normalized = cumsum_weights / total_weight
    idx = int(np.searchsorted(cumsum_normalized, q, side="left"))
    idx = max(0, min(idx, len(sorted_data) - 1))
    return float(sorted_data[idx])


def build_weighted_histogram_with_overflow(
    data: pl.DataFrame,
    *,
    source_col: str = "source",
    value_col: str = "value",
    weight_col: str = "weight",
    group_cols: list[str] | None = None,
    geometry_cols: list[str] | None = None,
    geometry_source: str | None = None,
    n_core_bins: int = 49,
) -> pl.DataFrame:
    """Build weighted histograms with fixed lower bound and one overflow bin.

    The core bins span ``[0, p98]`` using ``n_core_bins`` equal-width bins.
    A final overflow bin captures ``value > p98``.
    """
    group_cols = group_cols or []
    geometry_cols = list(group_cols if geometry_cols is None else geometry_cols)
    invalid_geometry = [col for col in geometry_cols if col not in group_cols]
    if invalid_geometry:
        raise ValueError(
            "geometry_cols must be a subset of group_cols: "
            f"{invalid_geometry}"
        )

    required = list(dict.fromkeys([source_col, value_col, weight_col, *group_cols, *geometry_cols]))
    missing = [c for c in required if c not in data.columns]
    if missing:
        raise ValueError(f"Histogram input missing required columns: {missing}")

    clean = data.select(required).drop_nulls([source_col, value_col, weight_col])
    if clean.is_empty():
        return _empty_histogram_frame(source_col, group_cols)

    geometry = _build_histogram_geometry_table(
        clean,
        source_col=source_col,
        geometry_cols=geometry_cols,
        value_col=value_col,
        weight_col=weight_col,
        geometry_source=geometry_source,
        n_core_bins=n_core_bins,
    )
    if geometry_cols:
        with_geometry = clean.join(geometry, on=geometry_cols, how="left", maintain_order="left")
    else:
        with_geometry = clean.join(geometry, how="cross")

    overflow_bin = n_core_bins
    binned = with_geometry.with_columns(
        pl.when(pl.col("_p98") > 0)
        .then(
            pl.when(pl.col(value_col) > pl.col("_p98"))
            .then(pl.lit(overflow_bin))
            .otherwise(
                (pl.col(value_col).clip(lower_bound=0.0) / pl.col("_core_width"))
                .floor()
                .clip(0, n_core_bins - 1)
            )
        )
        .otherwise(
            pl.when(pl.col(value_col) > pl.col("_p98"))
            .then(pl.lit(overflow_bin))
            .otherwise(pl.lit(0))
        )
        .cast(pl.Int32)
        .alias("bin")
    )

    count_group_cols = [*group_cols, source_col, "bin"]
    total_group_cols = [*group_cols, source_col]
    counts = binned.group_by(count_group_cols, maintain_order=True).agg(
        pl.col(weight_col).sum().cast(pl.Float64).alias("count")
    )
    group_stats = clean.group_by(total_group_cols, maintain_order=True).agg(
        pl.col(weight_col).sum().cast(pl.Float64).alias("_total_weight"),
        pl.col(value_col).max().cast(pl.Float64).alias("_group_max_val"),
        pl.len().cast(pl.Int64).alias("sample_count"),
    )

    sources = clean.select([*group_cols, source_col]).unique(maintain_order=True)
    bin_grid = pl.DataFrame({"bin": list(range(n_core_bins + 1))}, schema={"bin": pl.Int32})
    full_grid = sources.join(bin_grid, how="cross")
    if geometry_cols:
        full_grid = full_grid.join(geometry, on=geometry_cols, how="left", maintain_order="left")
    else:
        full_grid = full_grid.join(geometry, how="cross")

    hist = (
        full_grid.join(counts, on=count_group_cols, how="left", maintain_order="left")
        .with_columns(pl.col("count").fill_null(0.0).cast(pl.Float64))
        .join(group_stats, on=total_group_cols, how="left", maintain_order="left")
        .with_columns(
            pl.col("_total_weight").fill_null(0.0),
            pl.col("_group_max_val").fill_null(pl.col("_p98")),
            pl.col("sample_count").fill_null(0).cast(pl.Int64),
            pl.when(pl.col("_total_weight") > 0)
            .then(pl.col("count") / pl.col("_total_weight") * 100.0)
            .otherwise(0.0)
            .alias("count_pct"),
        )
        .with_columns(
            pl.when(pl.col("bin") == overflow_bin)
            .then(pl.col("_p98"))
            .otherwise(pl.col("bin") * pl.col("_core_width"))
            .alias("bin_left"),
            pl.when(pl.col("bin") == overflow_bin)
            .then(pl.max_horizontal(pl.col("_group_max_val"), pl.col("_p98")))
            .otherwise((pl.col("bin") + 1) * pl.col("_core_width"))
            .alias("bin_right"),
        )
        .with_columns(
            ((pl.col("bin_left") + pl.col("bin_right")) / 2.0).alias("bin_center")
        )
        .drop(["_total_weight", "_group_max_val", "_p98", "_core_width"])
    )
    select_cols = [*group_cols, source_col, "bin", "bin_left", "bin_right", "bin_center", "count", "count_pct", "sample_count"]
    return hist.select(select_cols)


def _empty_histogram_frame(source_col: str, group_cols: list[str]) -> pl.DataFrame:
    schema = {col: pl.String for col in [*group_cols, source_col]}
    schema.update(
        {
            "bin": pl.Int32,
            "bin_left": pl.Float64,
            "bin_right": pl.Float64,
            "bin_center": pl.Float64,
            "count": pl.Float64,
            "count_pct": pl.Float64,
            "sample_count": pl.Int64,
        }
    )
    return pl.DataFrame(schema=schema)


def _build_histogram_geometry_table(
    data: pl.DataFrame,
    *,
    source_col: str,
    geometry_cols: list[str],
    value_col: str,
    weight_col: str,
    geometry_source: str | None,
    n_core_bins: int,
) -> pl.DataFrame:
    if not geometry_cols:
        geometry_rows = _select_geometry_rows(
            data,
            source_col=source_col,
            geometry_source=geometry_source,
        )
        p98, core_width = _compute_histogram_geometry_params(
            geometry_rows[value_col].to_numpy(),
            geometry_rows[weight_col].to_numpy(),
            n_core_bins,
        )
        return pl.DataFrame(
            {"_p98": [p98], "_core_width": [core_width]}
        )

    rows: list[dict[str, object]] = []
    for geometry_vals in data.select(geometry_cols).unique(maintain_order=True).iter_rows(named=True):
        scope = data.filter(_build_match_filter(geometry_vals))
        geometry_rows = _select_geometry_rows(
            scope,
            source_col=source_col,
            geometry_source=geometry_source,
        )
        p98, core_width = _compute_histogram_geometry_params(
            geometry_rows[value_col].to_numpy(),
            geometry_rows[weight_col].to_numpy(),
            n_core_bins,
        )
        rows.append(
            {
                **geometry_vals,
                "_p98": p98,
                "_core_width": core_width,
            }
        )
    return pl.DataFrame(rows)


def _build_match_filter(match_vals: dict[str, object]) -> pl.Expr:
    expr = None
    for col, val in match_vals.items():
        clause = pl.col(col) == val
        expr = clause if expr is None else (expr & clause)
    if expr is None:
        raise ValueError("Expected at least one match column for histogram grouping.")
    return expr


def _select_geometry_rows(
    data: pl.DataFrame,
    *,
    source_col: str,
    geometry_source: str | None,
) -> pl.DataFrame:
    """Select the preferred rows for histogram geometry, with fallback to all rows."""
    if geometry_source is None:
        return data
    preferred = data.filter(pl.col(source_col) == geometry_source)
    return preferred if not preferred.is_empty() else data


def _compute_histogram_geometry_params(
    values: np.ndarray,
    weights: np.ndarray,
    n_core_bins: int,
) -> tuple[float, float]:
    p98 = _weighted_step_quantile(values, weights, 0.98)
    if not math.isfinite(p98):
        p98 = 0.0
    p98 = max(0.0, p98)

    core_width = p98 / n_core_bins if p98 > 0 else 1.0
    return p98, core_width
