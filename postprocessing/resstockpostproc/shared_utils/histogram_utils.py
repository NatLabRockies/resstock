"""Shared helpers for weighted histogram binning with an overflow tail bin."""

from __future__ import annotations

import math
import numpy as np
import polars as pl


def _midpoint_quantile(values: np.ndarray, q: float) -> float:
    """Numpy quantile wrapper that works across older/newer numpy versions."""
    if values.size == 0:
        return 0.0
    try:
        return float(np.quantile(values, q, method="midpoint"))
    except TypeError:
        return float(np.quantile(values, q, interpolation="midpoint"))


def build_weighted_histogram_with_overflow(
    data: pl.DataFrame,
    *,
    source_col: str = "source",
    value_col: str = "value",
    weight_col: str = "weight",
    group_cols: list[str] | None = None,
    n_core_bins: int = 49,
) -> pl.DataFrame:
    """Build weighted histograms with fixed lower bound and one overflow bin.

    The core bins span ``[0, p98]`` using ``n_core_bins`` equal-width bins.
    A final overflow bin captures ``value > p98``.
    """
    group_cols = group_cols or []
    required = [source_col, value_col, weight_col, *group_cols]
    missing = [c for c in required if c not in data.columns]
    if missing:
        raise ValueError(f"Histogram input missing required columns: {missing}")

    clean = data.select(required).drop_nulls([source_col, value_col, weight_col])
    if clean.is_empty():
        bins = list(range(n_core_bins + 1))
        return pl.DataFrame(
            {
                source_col: [],
                "bin": pl.Series([], dtype=pl.Int32),
                "bin_left": [],
                "bin_right": [],
                "bin_center": [],
                "count": [],
                "count_pct": [],
            }
        ).with_columns(pl.col("bin").cast(pl.Int32))

    if group_cols:
        group_values = clean.select(group_cols).unique(maintain_order=True).iter_rows(named=True)
        frames = []
        for group in group_values:
            group_filter = None
            for col, val in group.items():
                expr = pl.col(col) == val
                group_filter = expr if group_filter is None else (group_filter & expr)
            assert group_filter is not None
            sub = clean.filter(group_filter)
            frames.append(
                _build_one_group_histogram(
                    sub,
                    source_col=source_col,
                    value_col=value_col,
                    weight_col=weight_col,
                    group_vals=group,
                    n_core_bins=n_core_bins,
                )
            )
        return pl.concat(frames, how="diagonal_relaxed") if frames else pl.DataFrame()

    return _build_one_group_histogram(
        clean,
        source_col=source_col,
        value_col=value_col,
        weight_col=weight_col,
        group_vals={},
        n_core_bins=n_core_bins,
    )


def _build_one_group_histogram(
    data: pl.DataFrame,
    *,
    source_col: str,
    value_col: str,
    weight_col: str,
    group_vals: dict[str, object],
    n_core_bins: int,
) -> pl.DataFrame:
    """Build one group's weighted histogram table."""
    values = data[value_col].to_numpy()
    if values.size == 0:
        return pl.DataFrame()

    p98 = _midpoint_quantile(values, 0.98)
    if not math.isfinite(p98):
        p98 = 0.0
    p98 = max(0.0, p98)

    max_val = float(np.max(values)) if values.size else 0.0
    if not math.isfinite(max_val):
        max_val = p98
    max_val = max(max_val, p98)

    core_width = p98 / n_core_bins if p98 > 0 else 1.0
    overflow_bin = n_core_bins

    if p98 > 0:
        bin_expr = (
            pl.when(pl.col(value_col) > p98)
            .then(pl.lit(overflow_bin))
            .otherwise(
                (pl.col(value_col).clip(lower_bound=0.0) / core_width)
                .floor()
                .clip(0, n_core_bins - 1)
            )
            .cast(pl.Int32)
            .alias("bin")
        )
    else:
        bin_expr = (
            pl.when(pl.col(value_col) > p98)
            .then(pl.lit(overflow_bin))
            .otherwise(pl.lit(0))
            .cast(pl.Int32)
            .alias("bin")
        )

    binned = data.with_columns(bin_expr)
    counts = binned.group_by([source_col, "bin"], maintain_order=True).agg(
        pl.col(weight_col).sum().cast(pl.Float64).alias("count")
    )
    totals = binned.group_by(source_col, maintain_order=True).agg(
        pl.col(weight_col).sum().cast(pl.Float64).alias("_total_weight")
    )

    sources = data.select(source_col).unique(maintain_order=True)
    bin_grid = pl.DataFrame({"bin": list(range(n_core_bins + 1))}, schema={"bin": pl.Int32})
    full_grid = sources.join(bin_grid, how="cross")

    hist = (
        full_grid.join(counts, on=[source_col, "bin"], how="left", maintain_order="left")
        .with_columns(pl.col("count").fill_null(0.0).cast(pl.Float64))
        .join(totals, on=[source_col], how="left", maintain_order="left")
        .with_columns(
            pl.col("_total_weight").fill_null(0.0),
            pl.when(pl.col("_total_weight") > 0)
            .then(pl.col("count") / pl.col("_total_weight") * 100.0)
            .otherwise(0.0)
            .alias("count_pct"),
            pl.lit(p98).alias("_p98"),
            pl.lit(max_val).alias("_max_val"),
            pl.lit(core_width).alias("_core_width"),
        )
        .with_columns(
            pl.when(pl.col("bin") == overflow_bin)
            .then(pl.col("_p98"))
            .otherwise(pl.col("bin") * pl.col("_core_width"))
            .alias("bin_left"),
            pl.when(pl.col("bin") == overflow_bin)
            .then(pl.col("_max_val"))
            .otherwise((pl.col("bin") + 1) * pl.col("_core_width"))
            .alias("bin_right"),
        )
        .with_columns(
            ((pl.col("bin_left") + pl.col("bin_right")) / 2.0).alias("bin_center")
        )
        .drop(["_total_weight", "_p98", "_max_val", "_core_width"])
    )

    if group_vals:
        hist = hist.with_columns(pl.lit(v).alias(k) for k, v in group_vals.items())
        select_cols = list(group_vals.keys()) + [source_col, "bin", "bin_left", "bin_right", "bin_center", "count", "count_pct"]
        hist = hist.select(select_cols)
    return hist
