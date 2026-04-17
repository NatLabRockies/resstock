"""Shared axis range calculation for all plotter types."""

import polars as pl


def compute_axis_range(
    data: pl.DataFrame,
    quantity_column: str,
    lower_bound_column: str | None = None,
    upper_bound_column: str | None = None,
) -> tuple[float, float]:
    """Compute a zero-anchored axis range, using explicit bounds if available.

    Falls back to raw quantity values if bounds are unavailable.

    Returns (min_val, max_val) where both are anchored to include zero.
    """
    if (
        lower_bound_column is not None
        and upper_bound_column is not None
        and lower_bound_column in data.columns
        and upper_bound_column in data.columns
    ):
        data_max = data.select(
            pl.coalesce(
                pl.col(upper_bound_column),
                pl.col(quantity_column),
                pl.lit(0.0),
            )
            .max()
            .alias("max_val")
        ).item(0, 0)
        data_min = data.select(
            pl.coalesce(
                pl.col(lower_bound_column),
                pl.col(quantity_column),
                pl.lit(0.0),
            )
            .min()
            .alias("min_val")
        ).item(0, 0)
        return (
            min(0, float(data_min or 0)),
            max(0, float(data_max or 0)),
        )

    data_max = data[quantity_column].fill_null(0).max()
    data_min = data[quantity_column].fill_null(0).min()
    return (
        min(0, float(data_min or 0)),
        max(0, float(data_max or 0)),
    )
