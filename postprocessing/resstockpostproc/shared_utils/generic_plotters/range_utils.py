"""Shared axis range calculation for all plotter types."""

import polars as pl


def compute_axis_range(
    data: pl.DataFrame,
    quantity_column: str,
    rse_column: str | None = None,
) -> tuple[float, float]:
    """Compute a zero-anchored axis range, using RSE bounds if available.

    When an rse_column is provided, uses the corresponding _upper_bound/_lower_bound
    columns so that error bars are fully visible. Falls back to raw quantity values
    if bounds columns are missing or rse_column is None.

    Returns (min_val, max_val) where both are anchored to include zero.
    """
    if rse_column is not None:
        upper_col = rse_column.replace("_rse", "_upper_bound")
        lower_col = rse_column.replace("_rse", "_lower_bound")
        if upper_col in data.columns and lower_col in data.columns:
            data_max = data[upper_col].fill_null(0).max()
            data_min = data[lower_col].fill_null(0).min()
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
