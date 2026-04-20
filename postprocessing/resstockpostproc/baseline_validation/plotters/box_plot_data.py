"""Box-plot quartile helpers for the stacked plot family.

Builds the scalar q1/median/q3/whisker/min/max columns that ``box_plotter``
consumes from the list-valued ``_quartiles`` / ``_nonzero_quartiles``
column produced upstream, and prepares the dataframe shape
(``n_points``, ``mean``, ``outliers``) expected by the box-plot renderer.

Extracted from stacked_plotter.py in refactor plan V2 step 6.2.
"""

import polars as pl

from resstockpostproc.baseline_validation.plot_semantics import quartile_list_column
from resstockpostproc.baseline_validation.schema.plot_spec import CoverageType
from resstockpostproc.shared_utils.timing import timed


def add_quartile_cols(df: pl.DataFrame, quartile_column: str) -> pl.DataFrame:
    """Helper function to get the quartile column names for a given quantity column."""
    return df.with_columns(
        [
            pl.col(quartile_column).list.get(3).cast(pl.Float64).alias("q1"),
            pl.col(quartile_column).list.get(4).cast(pl.Float64).alias("median"),
            pl.col(quartile_column).list.get(5).cast(pl.Float64).alias("q3"),
            pl.col(quartile_column).list.get(0).cast(pl.Float64).alias("lower_whisker"),
            pl.col(quartile_column).list.get(0).cast(pl.Float64).alias("min"),
            pl.col(quartile_column).list.get(8).cast(pl.Float64).alias("upper_whisker"),
            pl.col(quartile_column).list.get(8).cast(pl.Float64).alias("max"),
        ]
    )

@timed
def prepare_box_plot_data(df: pl.DataFrame, quantity: str, coverage: CoverageType) -> pl.DataFrame:
    """Prepare the data for box plot by adding necessary columns.

    Args:
        df: Input DataFrame
        quantity: The quantity column name (without suffix)
        coverage: CoverageType.all_units uses _quartiles, CoverageType.users_only uses _nonzero_quartiles.
            For non-ALL users_only plots, model_count is already normalized upstream to the
            exact nonzero model/sample count for this quantity, so box-plot n_points should
            use it directly.
    """
    df = df.with_columns(pl.lit([]).alias("outliers"))
    df = df.with_columns(pl.lit([]).alias("outlier_buildings"))
    df = df.with_columns(pl.col(f"{quantity}_value").alias("mean"))

    if coverage == CoverageType.all_units:
        df = df.with_columns(pl.col("model_count").alias("n_points"))
    elif coverage == CoverageType.users_only:
        df = df.with_columns(
            pl.col("model_count").fill_null(0).fill_nan(0).cast(pl.Int32).alias("n_points")
        )
    else:
        raise ValueError(f"Unsupported coverage type for box plot: {coverage}")
    df = add_quartile_cols(df, quartile_list_column(quantity, coverage))
    return df
